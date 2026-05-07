defmodule Relyra.Metadata.Parser do
  @moduledoc false

  alias Relyra.Error

  @default_opts [max_bytes: 1_048_576]

  @spec parse(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def parse(xml, opts \\ [])

  def parse(xml, opts) when is_binary(xml) and is_list(opts) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)
    trimmed = String.trim(xml)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      trimmed == "" ->
        malformed_xml_error()

      String.contains?(trimmed, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(trimmed, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      not Regex.match?(~r/^<([A-Za-z_][\w\-\.:]*)(?:\s[^>]*)?>.*<\/\1>$/s, trimmed) ->
        malformed_xml_error()

      not Regex.match?(~r/^<(?:\w+:)?EntityDescriptor\b/is, trimmed) ->
        {:error, Error.new(:metadata_wrong_root, "Metadata XML must start with EntityDescriptor")}

      true ->
        extract_metadata(trimmed)
    end
  end

  def parse(_xml, _opts), do: malformed_xml_error()

  defp extract_metadata(xml) do
    with {:ok, entity_id} <- fetch_entity_id(xml),
         {:ok, sso_services} <- fetch_sso_services(xml),
         {:ok, certificates} <- fetch_certificates(xml) do
      {:ok,
       %{
         entity_id: entity_id,
         sso_services: sso_services,
         certificates: certificates
       }}
    end
  end

  defp fetch_entity_id(xml) do
    case Regex.run(~r/^<(?:\w+:)?EntityDescriptor\b[^>]*\bentityID=(["'])(.*?)\1/is, xml,
           capture: :all_but_first
         ) do
      [_, entity_id] when entity_id != "" -> {:ok, String.trim(entity_id)}
      _ -> {:error, Error.new(:metadata_missing_entity_id, "Metadata entity ID is required")}
    end
  end

  defp fetch_sso_services(xml) do
    services =
      Regex.scan(
        ~r/<(?:\w+:)?SingleSignOnService\b[^>]*\bBinding=(["'])(.*?)\1[^>]*\bLocation=(["'])(.*?)\3/is,
        xml,
        capture: :all_but_first
      )
      |> Enum.map(fn [_, binding, _, location] ->
        %{binding: String.trim(binding), location: String.trim(location)}
      end)
      |> Enum.reject(&blank?(&1.location))

    if services == [] do
      {:error,
       Error.new(:metadata_missing_sso_service, "Metadata XML must include a SingleSignOnService")}
    else
      {:ok, services}
    end
  end

  defp fetch_certificates(xml) do
    certs =
      Regex.scan(~r/<(?:\w+:)?X509Certificate\b[^>]*>(.*?)<\/(?:\w+:)?X509Certificate>/is, xml,
        capture: :all_but_first
      )
      |> Enum.map(fn [value] -> value |> String.replace(~r/\s+/, "") |> String.trim() end)
      |> Enum.reject(&blank?/1)

    if certs == [] do
      {:error,
       Error.new(
         :metadata_missing_certificate,
         "Metadata XML must include at least one certificate"
       )}
    else
      {:ok, certs}
    end
  end

  defp malformed_xml_error do
    {:error, Error.new(:malformed_xml, "Metadata XML is malformed")}
  end

  defp blank?(value), do: is_nil(value) or value == ""
end
