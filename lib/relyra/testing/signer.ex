defmodule Relyra.Testing.Signer do
  @moduledoc """
  Builds signed test responses for `Relyra.Testing`.

  This module is production-compiled so Hex adopters can use the public testing
  fixture helpers from their own test suites. It creates a fresh RSA key for
  each signed test response, returns the matching test certificate, and
  canonicalizes through Relyra's real verifier path (`SaxyTree`, `PureBeam`, and
  `C14N`). It is test-only fixture machinery, not an IdP, broker, or production
  trust source.
  """

  alias Relyra.Security.XML.AttributeEscape
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  @typedoc """
  A signed test response and the matching test certificate chain.
  """
  @type signed_response :: %{
          response_xml: binary(),
          cert_chain: [binary()]
        }

  @doc """
  Builds a signed test response with real digest and signature values.

  The returned XML contains no `KeyInfo`; callers must thread the returned
  `cert_chain` into `Relyra.consume_response/3` through explicit fixture data.
  """
  @spec signed_response(keyword()) :: signed_response()
  def signed_response(opts \\ []) when is_list(opts) do
    fields = response_fields(opts)
    private_key = :public_key.generate_key({:rsa, 2048, 65_537})
    cert_pem = self_signed_cert_pem(private_key)

    placeholder_xml = response_xml(fields, "", "")
    placeholder_tree = parse_tree!(placeholder_xml)
    assertion_node = find_by_local_and_id(placeholder_tree, "Assertion", fields.assertion_id)
    digest_value_b64 = digest_for(assertion_node)

    digest_xml = response_xml(fields, digest_value_b64, "")
    digest_tree = parse_tree!(digest_xml)
    signed_info_node = find_first_by_local(digest_tree, "SignedInfo")
    signature_value_b64 = sign_signed_info(signed_info_node, private_key)

    %{
      response_xml: response_xml(fields, digest_value_b64, signature_value_b64),
      cert_chain: [cert_pem]
    }
  end

  defp response_fields(opts) do
    %{
      connection_id: Keyword.fetch!(opts, :connection_id),
      issuer: Keyword.fetch!(opts, :issuer),
      destination: Keyword.fetch!(opts, :destination),
      recipient: Keyword.fetch!(opts, :recipient),
      audience: Keyword.fetch!(opts, :audience),
      name_id: Keyword.fetch!(opts, :name_id),
      in_response_to: Keyword.fetch!(opts, :in_response_to),
      assertion_id: Keyword.fetch!(opts, :assertion_id),
      not_before: Keyword.fetch!(opts, :not_before),
      not_on_or_after: Keyword.fetch!(opts, :not_on_or_after),
      subject_confirmation_not_on_or_after:
        Keyword.fetch!(opts, :subject_confirmation_not_on_or_after),
      status: Keyword.get(opts, :status, @success_status)
    }
  end

  defp response_xml(fields, digest_value_b64, signature_value_b64) do
    in_response_to_attr =
      case fields.in_response_to do
        nil -> ""
        "" -> ""
        value -> ~s( InResponseTo="#{AttributeEscape.escape_attribute(value)}")
      end

    "<Response Destination=\"#{AttributeEscape.escape_attribute(fields.destination)}\"#{in_response_to_attr} ConnectionId=\"#{AttributeEscape.escape_attribute(fields.connection_id)}\">" <>
      "<Issuer>#{xml_text(fields.issuer)}</Issuer>" <>
      "<Status><StatusCode Value=\"#{AttributeEscape.escape_attribute(fields.status)}\"/></Status>" <>
      "<Assertion ID=\"#{AttributeEscape.escape_attribute(fields.assertion_id)}\">" <>
      "<Issuer>#{xml_text(fields.issuer)}</Issuer>" <>
      "<Subject>" <>
      "<NameID>#{xml_text(fields.name_id)}</NameID>" <>
      "<SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\">" <>
      "<SubjectConfirmationData Recipient=\"#{AttributeEscape.escape_attribute(fields.recipient)}\" NotOnOrAfter=\"#{AttributeEscape.escape_attribute(fields.subject_confirmation_not_on_or_after)}\"/>" <>
      "</SubjectConfirmation>" <>
      "</Subject>" <>
      "<Conditions NotBefore=\"#{AttributeEscape.escape_attribute(fields.not_before)}\" NotOnOrAfter=\"#{AttributeEscape.escape_attribute(fields.not_on_or_after)}\">" <>
      "<AudienceRestriction><Audience>#{xml_text(fields.audience)}</Audience></AudienceRestriction>" <>
      "</Conditions>" <>
      "</Assertion>" <>
      "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
      "<SignedInfo>" <>
      "<CanonicalizationMethod Algorithm=\"#{@exc_c14n}\"/>" <>
      "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
      "<Reference URI=\"##{AttributeEscape.escape_attribute(fields.assertion_id)}\">" <>
      "<DigestMethod Algorithm=\"#{@sha256}\"/>" <>
      "<DigestValue>#{xml_text(digest_value_b64)}</DigestValue>" <>
      "</Reference>" <>
      "</SignedInfo>" <>
      "<SignatureValue>#{xml_text(signature_value_b64)}</SignatureValue>" <>
      "</Signature>" <>
      "</Response>"
  end

  defp self_signed_cert_pem(private_key) do
    %{cert: cert_der} =
      :public_key.pkix_test_root_cert(~c"CN=relyra-testing-fixture", key: private_key)

    :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
  end

  defp digest_for(%Node{} = assertion_node) do
    {:ok, %{canonical_xml: ref_bytes}} = PureBeam.canonicalize(%{node: assertion_node})
    :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
  end

  defp sign_signed_info(%Node{} = signed_info_node, private_key) do
    {:ok, c14n_signed_info} = C14N.serialize(signed_info_node)
    c14n_signed_info |> then(&:public_key.sign(&1, :sha256, private_key)) |> Base.encode64()
  end

  defp parse_tree!(xml) do
    {:ok, %Node{} = tree} = SaxyTree.parse(xml)
    tree
  end

  defp find_first_by_local(%Node{local: local} = node, local), do: node

  defp find_first_by_local(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first_by_local(child, local) end)
  end

  defp find_first_by_local(_other, _local), do: nil

  defp find_by_local_and_id(%Node{local: local, attrs: attrs} = node, local, id) do
    if attr_value(attrs, "ID") == id do
      node
    else
      search_children(node, local, id)
    end
  end

  defp find_by_local_and_id(%Node{} = node, local, id), do: search_children(node, local, id)
  defp find_by_local_and_id(_other, _local, _id), do: nil

  defp search_children(%Node{children: children}, local, id) do
    Enum.find_value(children, fn child -> find_by_local_and_id(child, local, id) end)
  end

  defp attr_value(attrs, name) do
    Enum.find_value(attrs, fn
      {^name, value} -> value
      _ -> nil
    end)
  end

  defp xml_text(value) when is_binary(value) do
    value
    |> :binary.replace("&", "&amp;", [:global])
    |> :binary.replace("<", "&lt;", [:global])
    |> :binary.replace(">", "&gt;", [:global])
  end

  defp xml_text(_value), do: ""
end
