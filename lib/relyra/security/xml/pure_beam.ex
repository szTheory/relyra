defmodule Relyra.Security.XML.PureBeam do
  @moduledoc """
  Pure-BEAM baseline adapter for XML seam enforcement.
  """

  @behaviour Relyra.Security.XML

  alias Relyra.Error
  @default_opts [max_bytes: 1_048_576]

  @impl true
  def parse_safely(xml, opts \\ [])

  def parse_safely(xml, opts) when is_binary(xml) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      String.contains?(xml, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(xml, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_xml(xml)
    end
  end

  def parse_safely(_xml, _opts), do: malformed_xml_error()

  @impl true
  def select_signed_node(parsed_doc, opts \\ [])

  def select_signed_node(parsed_doc, _opts) when is_map(parsed_doc) do
    duplicate_xml_ids = Map.get(parsed_doc, :duplicate_ids, [])

    cond do
      Map.get(parsed_doc, :key_info_trust) == true ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Document-provided KeyInfo cannot be used as a trust source",
           %{reason: :document_keyinfo_forbidden}
         )}

      duplicate_xml_ids != [] ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           %{
             duplicate_ids: duplicate_xml_ids,
             duplicate_count: length(duplicate_xml_ids)
           }
         )}

      true ->
        select_candidate(parsed_doc)
    end
  end

  def select_signed_node(_parsed_doc, _opts) do
    {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}
  end

  @impl true
  def canonicalize(signed_node_handle, opts \\ [])

  def canonicalize(
        %{
          xml_id: xml_id,
          xpath: xpath,
          signed_xml: signed_xml,
          signature_method: signature_method,
          digest_method: digest_method
        },
        _opts
      )
      when is_binary(xml_id) and is_binary(xpath) and is_binary(signed_xml) and
             is_binary(signature_method) and is_binary(digest_method) do
    {:ok,
     %{
       canonical_xml: normalize_signed_xml(signed_xml),
       xml_id: xml_id,
       xpath: xpath
     }}
  end

  def canonicalize(_signed_node_handle, _opts) do
    {:error,
     Error.new(
       :canonicalization_failed,
       "Signed node handle could not be canonicalized",
       %{reason: :invalid_signed_node_handle}
     )}
  end

  defp parse_xml(xml) do
    trimmed = String.trim(xml)

    cond do
      trimmed == "" ->
        malformed_xml_error()

      not Regex.match?(~r/^<([A-Za-z_][\w\-\.:]*)(?:\s[^>]*)?>.*<\/\1>$/s, trimmed) ->
        malformed_xml_error()

      not Regex.match?(~r/^<(?:\w+:)?response\b/is, trimmed) ->
        malformed_xml_error()

      true ->
        with {:ok, signature_fields} <- extract_signature_fields(trimmed),
             {:ok, response_fields} <- extract_response_fields(trimmed),
             {:ok, assertion_fields} <- extract_assertion_fields(trimmed) do
          assertion_times = %{
            not_before: Map.fetch!(assertion_fields, :not_before),
            not_on_or_after: Map.fetch!(assertion_fields, :not_on_or_after),
            subject_confirmation_not_on_or_after:
              Map.fetch!(assertion_fields, :subject_confirmation_not_on_or_after)
          }

          {:ok,
           %{
             type: :parsed_xml,
             bytes: byte_size(trimmed),
             assertion_times: assertion_times
           }
           |> Map.merge(response_fields)
           |> Map.merge(assertion_fields)
           |> Map.merge(signature_fields)}
        end
    end
  end

  defp extract_response_fields(xml) do
    fields = %{
      issuer: first_tag_text(xml, "Issuer"),
      status: first_attribute(xml, "StatusCode", "Value"),
      destination: first_attribute(xml, "Response", "Destination"),
      in_response_to: first_attribute(xml, "Response", "InResponseTo"),
      connection_id: first_attribute(xml, "Response", "ConnectionId")
    }

    require_present_fields(
      fields,
      [:issuer, :status, :destination],
      :missing_protocol_field,
      "Required protocol fields are missing from response payload"
    )
  end

  defp extract_assertion_fields(xml) do
    fields = %{
      audiences: all_tag_texts(xml, "Audience"),
      recipient: first_attribute(xml, "SubjectConfirmationData", "Recipient"),
      not_before: first_attribute(xml, "Conditions", "NotBefore"),
      not_on_or_after: first_attribute(xml, "Conditions", "NotOnOrAfter"),
      subject_confirmation_not_on_or_after:
        first_attribute(xml, "SubjectConfirmationData", "NotOnOrAfter"),
      consumed_xml_id: first_attribute(xml, "Assertion", "ID"),
      name_id: first_tag_text(xml, "NameID"),
      name_id_format: first_attribute(xml, "NameID", "Format"),
      session_index: first_attribute(xml, "AuthnStatement", "SessionIndex"),
      attributes: extract_attributes(xml)
    }

    require_present_fields(
      fields,
      [
        :audiences,
        :recipient,
        :not_before,
        :not_on_or_after,
        :subject_confirmation_not_on_or_after,
        :consumed_xml_id
      ],
      :missing_protocol_field,
      "Required assertion fields are missing from response payload"
    )
  end

  defp extract_attributes(xml) do
    # This is a very basic regex-based attribute extractor.
    # It assumes <saml:Attribute Name="..."><saml:AttributeValue>...</saml:AttributeValue></saml:Attribute>
    Regex.scan(
      ~r/<(?:\w+:)?Attribute\b[^>]*\bName=(["'])(.*?)\1[^>]*>(.*?)<\/(?:\w+:)?Attribute>/is,
      xml
    )
    |> Enum.map(fn [_, _, name, values_xml] ->
      values =
        Regex.scan(
          ~r/<(?:\w+:)?AttributeValue\b[^>]*>(.*?)<\/(?:\w+:)?AttributeValue>/is,
          values_xml
        )
        |> Enum.map(fn [_, value] -> String.trim(value) end)

      {name, values}
    end)
    |> Enum.into(%{})
  end

  defp extract_signature_fields(xml) do
    signature_method = first_attribute(xml, "SignatureMethod", "Algorithm")
    digest_method = first_attribute(xml, "DigestMethod", "Algorithm")

    fields = %{
      signature_method: signature_method,
      digest_method: digest_method,
      signed_candidates:
        extract_signed_candidates(xml)
        |> Enum.map(fn c ->
          Map.merge(c, %{signature_method: signature_method, digest_method: digest_method})
        end),
      duplicate_ids: extract_duplicate_ids(xml),
      key_info_trust: Regex.match?(~r/<(?:\w+:)?KeyInfo\b/is, xml)
    }

    require_present_fields(
      fields,
      [:signature_method, :digest_method, :signed_candidates],
      :missing_signature,
      "Signed XML material is missing required signature fields"
    )
  end

  defp require_present_fields(fields, required_keys, error_type, message) do
    missing =
      Enum.reject(required_keys, fn key ->
        present?(Map.get(fields, key))
      end)

    if missing == [] do
      {:ok, fields}
    else
      {:error,
       Error.new(error_type, message, %{
         expected: required_keys,
         actual: required_keys -- missing,
         missing: missing
       })}
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value), do: not is_nil(value)

  defp extract_signed_candidates(xml) do
    Regex.scan(~r/<(?:\w+:)?Assertion\b([^>]*)>(.*?)<\/(?:\w+:)?Assertion>/s, xml)
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {[_, attrs, inner], index}, acc ->
      case attribute_from_fragment(attrs, "ID") do
        nil ->
          acc

        assertion_id ->
          [
            %{
              xml_id: assertion_id,
              xpath: "/Response/Assertion[#{index}]",
              signed_xml: "<Assertion#{attrs}>#{inner}</Assertion>"
            }
            | acc
          ]
      end
    end)
    |> Enum.reverse()
  end

  defp extract_duplicate_ids(xml) do
    ids =
      Regex.scan(~r/\bID=(["'])(.*?)\1/s, xml, capture: :all_but_first)
      |> Enum.map(fn [_, id] -> id end)

    frequencies = Enum.frequencies(ids)

    Enum.filter(ids, fn id ->
      Map.get(frequencies, id, 0) > 1
    end)
  end

  defp first_tag_text(xml, tag_name) do
    pattern = ~r/<(?:\w+:)?#{tag_name}\b[^>]*>(.*?)<\/(?:\w+:)?#{tag_name}>/is

    case Regex.run(pattern, xml, capture: :all_but_first) do
      [value] -> String.trim(value)
      _ -> nil
    end
  end

  defp all_tag_texts(xml, tag_name) do
    pattern = ~r/<(?:\w+:)?#{tag_name}\b[^>]*>(.*?)<\/(?:\w+:)?#{tag_name}>/is

    Regex.scan(pattern, xml, capture: :all_but_first)
    |> Enum.map(fn [value] -> String.trim(value) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp first_attribute(xml, tag_name, attribute_name) do
    pattern = ~r/<(?:\w+:)?#{tag_name}\b[^>]*\b#{attribute_name}=(["'])(.*?)\1/is

    case Regex.run(pattern, xml, capture: :all_but_first) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  defp attribute_from_fragment(fragment, attribute_name) do
    pattern = ~r/\b#{attribute_name}=(["'])(.*?)\1/is

    case Regex.run(pattern, fragment, capture: :all_but_first) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  defp select_candidate(parsed_doc) do
    signed_candidates = Map.get(parsed_doc, :signed_candidates, [])
    signature_method = Map.get(parsed_doc, :signature_method)
    digest_method = Map.get(parsed_doc, :digest_method)

    case signed_candidates do
      [] ->
        {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}

      [candidate] when is_map(candidate) ->
        {:ok,
         %{
           xml_id: Map.get(candidate, :xml_id),
           xpath: Map.get(candidate, :xpath),
           signed_xml: Map.get(candidate, :signed_xml),
           signature_method: Map.get(candidate, :signature_method, signature_method),
           digest_method: Map.get(candidate, :digest_method, digest_method)
         }}

      candidates ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one verified signed node is required",
           %{candidate_count: length(candidates)}
         )}
    end
  end

  defp normalize_signed_xml(signed_xml) do
    signed_xml
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.trim()
  end

  defp malformed_xml_error do
    {:error, Error.new(:malformed_xml, "Malformed XML payload", %{})}
  end
end
