defmodule Relyra.Security.XML do
  @moduledoc """
  Hardened XML seam contract for trust-sensitive SAML handling.
  """

  alias Relyra.Error

  @type xml_error_type ::
          :doctype_forbidden
          | :entity_expansion_forbidden
          | :external_reference_forbidden
          | :payload_too_large
          | :malformed_xml
          | :missing_protocol_field
          | :duplicate_xml_id
          | :missing_signature
          | :invalid_signature
          | :signature_wrapping_suspected
          | :canonicalization_failed
          | :untrusted_certificate
          | :unsigned_or_partial_signature

  @callback parse_safely(binary(), keyword()) ::
              {:ok, term()} | {:error, %Error{}}
  @callback select_signed_node(parsed_doc :: term(), keyword()) ::
              {:ok, term()} | {:error, %Error{}}
  @callback canonicalize(signed_node_handle :: term(), keyword()) ::
              {:ok, binary()} | {:error, %Error{}}
end
