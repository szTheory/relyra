defmodule Relyra.Security.XML.PureBeam do
  @moduledoc """
  Pure-BEAM baseline adapter for XML seam enforcement.
  """

  @behaviour Relyra.Security.XML

  alias Relyra.Error
  @default_opts [max_bytes: 1_048_576]

  @impl true
  def parse_safely(xml, opts \\ []) when is_binary(xml) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

    cond do
      byte_size(xml) > max_bytes ->
        {:error, Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{max_bytes: max_bytes})}

      String.contains?(xml, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(xml, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_xml(xml)
    end
  end

  @impl true
  def select_signed_node(_parsed_doc, _opts \\ []) do
    {:error, Error.new(:missing_signature, "Signed XML node selection is not implemented yet")}
  end

  @impl true
  def canonicalize(_signed_node_handle, _opts \\ []) do
    {:error, Error.new(:canonicalization_failed, "Canonicalization is not implemented yet")}
  end

  defp parse_xml(xml) do
    try do
      {parsed_doc, _rest} = :xmerl_scan.string(String.to_charlist(xml), quiet: true)
      {:ok, parsed_doc}
    catch
      _kind, _reason ->
        {:error, Error.new(:malformed_xml, "Malformed XML payload")}
    end
  end
end
