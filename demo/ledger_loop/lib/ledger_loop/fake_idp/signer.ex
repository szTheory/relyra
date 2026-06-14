defmodule LedgerLoop.FakeIdP.Signer do
  @moduledoc """
  Demo-local SAML `<Response>` signer for `LedgerLoop.FakeIdP`.

  Produces a genuinely-signed SAML Response whose `DigestValue` and
  `SignatureValue` pass Relyra's strict `do_verify/4` gate against the demo
  IdP certificate — a REAL cryptographic pass, not structure-only acceptance.

  ## Anti-divergence guarantee

  This signer canonicalizes with the **same** C14N engine the Relyra verifier
  uses (`Relyra.Security.XML.PureBeam.canonicalize/1` for the referenced
  `<Assertion>` and `Relyra.Security.XML.C14N.serialize/1` for `<SignedInfo>`).
  Because the digest and signature are computed over the bytes produced by
  parsing the *emitted* XML through Relyra's own engine, the signer can never
  canonicalize differently from the verifier (T-57-05).

  ## Security boundary

  This module uses only Relyra's public, prod-compiled XML modules
  (`Relyra.Security.XML.*`) and `LedgerLoop.FakeIdP.Keypair`. It does not
  reference any module under the `test_support/` elixirc path — those are
  stripped from the `:prod` path-dep build (T-57-08).
  """

  alias LedgerLoop.FakeIdP.Keypair
  alias Relyra.Security.XML.AttributeEscape
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  @doc """
  Build a genuinely-signed SAML `<Response>` and return it as a base64 string.

  Options drive all protocol fields from the caller (typically from the …J0
  connection fixture) so the emitted XML matches what the Relyra validation
  pipeline expects:

    * `:issuer` — IdP entity ID (must match connection `idp_entity_id`)
    * `:destination` — ACS URL (must match connection `acs_url`)
    * `:recipient` — SubjectConfirmationData Recipient (must match `acs_url`)
    * `:audience` — Audience restriction (must match connection `sp_entity_id`)
    * `:name_id` — NameID subject (must be a seeded SAMLIdentity subject)
    * `:in_response_to` — InResponseTo (must match the correlated AuthnRequest ID)
    * `:not_before` — Conditions NotBefore (default: far past)
    * `:not_on_or_after` — Conditions NotOnOrAfter (default: far future)

  The `assertion_id` is generated uniquely per call via `System.unique_integer/1`
  to prevent replay store collisions across repeated test calls (Pitfall 6).

  Returns a base64-encoded `SAMLResponse` string (padding-free encoding).
  """
  @spec signed_response(keyword()) :: binary()
  def signed_response(opts \\ []) when is_list(opts) do
    fields = build_fields(opts)
    priv_key = Keypair.private_key()

    # 1. Build placeholder XML with empty digest/signature placeholders so the
    #    tree shape and in-scope namespaces are exactly the emitted shape.
    placeholder_xml = response_xml(fields, "", "")

    # 2. Parse with the verifier's parser; locate the bound <Assertion> node and
    #    compute the genuine DigestValue over its canonicalized bytes.
    #    Use the SAME PureBeam.canonicalize path the verifier uses.
    placeholder_tree = parse_tree!(placeholder_xml)
    assertion_node = find_by_local_and_id(placeholder_tree, "Assertion", fields.assertion_id)
    digest_value_b64 = digest_for(assertion_node)

    # 3. Re-emit with the real DigestValue embedded, re-parse, locate the
    #    SignedInfo node, canonicalize it with the SAME engine (C14N.serialize),
    #    and sign those exact bytes with the demo private key.
    digest_xml = response_xml(fields, digest_value_b64, "")
    digest_tree = parse_tree!(digest_xml)
    signed_info_node = find_first_by_local(digest_tree, "SignedInfo")
    signature_value_b64 = sign_signed_info(signed_info_node, priv_key)

    # 4. Emit the final, genuinely-signed Response and base64-encode it.
    signed_xml = response_xml(fields, digest_value_b64, signature_value_b64)
    Base.encode64(signed_xml)
  end

  @doc """
  Tamper the signed Assertion's `<NameID>` text post-sign.

  Takes a base64 `SAMLResponse` (from `signed_response/1`), decodes it,
  replaces the `<NameID>` content inside the signed `<Assertion>` with a
  `"TAMPERED"` marker, and re-encodes to base64. The `SignatureValue` remains
  valid for the original `SignedInfo` bytes, but the referenced Assertion's
  digest no longer matches its mutated content — Relyra rejects this with
  `{:error, %Relyra.Error{type: :digest_mismatch}}`.

  Targeting the Assertion's `<NameID>` (not the Response-level `<Issuer>`)
  ensures the rejection fires at the crypto gate (`do_verify/4`), not at an
  earlier protocol-validation step such as `:issuer_mismatch`.
  """
  @spec tamper(binary()) :: binary()
  def tamper(b64) when is_binary(b64) do
    xml = Base.decode64!(b64)
    # Broadened regex: matches <NameID> with optional attributes (e.g. Format="…").
    # Preserve the original open and close tags (back-references \\1/\\2) so only
    # the text node is mutated — keeps any Format attribute intact so the rejection
    # stays at the crypto gate rather than shifting to an earlier protocol step
    # (WR-02/WR-05).
    tampered = String.replace(xml, ~r/(<NameID[^>]*>)[^<]+(<\/NameID>)/, "\\1TAMPERED\\2")

    # WR-05 detectable-no-op guard: a tamper helper must never silently fail to tamper.
    if tampered == xml do
      raise "tamper/1 failed to locate <NameID>; template drifted"
    end

    Base.encode64(tampered)
  end

  # ---------------------------------------------------------------------------
  # Internal — XML template
  # ---------------------------------------------------------------------------

  defp build_fields(opts) do
    %{
      issuer: Keyword.fetch!(opts, :issuer),
      destination: Keyword.fetch!(opts, :destination),
      recipient: Keyword.fetch!(opts, :recipient),
      audience: Keyword.fetch!(opts, :audience),
      name_id: Keyword.fetch!(opts, :name_id),
      in_response_to: Keyword.fetch!(opts, :in_response_to),
      not_before: Keyword.get(opts, :not_before, "2000-01-01T00:00:00Z"),
      not_on_or_after: Keyword.get(opts, :not_on_or_after, "2099-01-01T00:00:00Z"),
      subject_confirmation_not_on_or_after:
        Keyword.get(opts, :subject_confirmation_not_on_or_after, "2099-01-01T00:00:00Z"),
      status: Keyword.get(opts, :status, @success_status),
      # Unique assertion ID per call to prevent replay store collisions.
      assertion_id:
        Keyword.get(
          opts,
          :assertion_id,
          "demo-assertion-#{System.unique_integer([:positive])}"
        )
    }
  end

  # The Response XML carries the genuine ds:Signature as a sibling of
  # <Assertion> (NOT enveloped — no enveloped-signature transform needed; the
  # digest is plain exc-C14N over the referenced <Assertion>).
  #
  # WR-01: All interpolated values are escaped at the point of interpolation,
  # inside this single function. Because signed_response/1 calls response_xml/3
  # three times (placeholder, digest, signed — lines 65/77/83), escaping here
  # is digest-stable: all three passes escape identically (RESEARCH Pitfall 1).
  # Attribute values: AttributeEscape.escape_attribute/1 (prod-compiled, C14N-aligned).
  # Element text: xml_text/1 (local helper — &, <, > only; correct for text nodes).
  # digest_value_b64 / signature_value_b64 are base64 (no XML metacharacters);
  # applying xml_text/1 to them is harmless and uniform.
  defp response_xml(fields, digest_value_b64, signature_value_b64) do
    # Omit InResponseTo entirely when absent (direct, non-SP-initiated visit):
    # an empty InResponseTo="" is not equivalent to an absent attribute, and a
    # strict SP (including Relyra on the real ACS path) may reject "" as a
    # malformed correlation, masking the missing-correlation condition (WR-03).
    in_response_to_attr =
      case fields.in_response_to do
        nil -> ""
        "" -> ""
        v -> ~s( InResponseTo="#{AttributeEscape.escape_attribute(v)}")
      end

    "<Response Destination=\"#{AttributeEscape.escape_attribute(fields.destination)}\"#{in_response_to_attr} ConnectionId=\"valid\">" <>
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

  # WR-01: Escape XML element text (& → &amp;, < → &lt;, > → &gt;).
  # Used for element-text interpolations where attribute-specific escaping
  # (tabs, newlines, quotes) is not needed and would be wrong.
  defp xml_text(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp xml_text(nil), do: ""

  # ---------------------------------------------------------------------------
  # Internal — crypto (vendored technique from XmldsigSigner, re-homed here)
  # ---------------------------------------------------------------------------

  # Digest the referenced <Assertion> via the verifier's canonicalize path
  # so the DigestValue is byte-identical to what do_verify/4 recomputes.
  # Source technique: lib/relyra/test_support/xmldsig_signer.ex:284-287
  defp digest_for(%Node{} = assertion_node) do
    {:ok, %{canonical_xml: ref_bytes}} = PureBeam.canonicalize(%{node: assertion_node})
    :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
  end

  # Sign the canonicalized SignedInfo (C14N.serialize — the SAME engine the
  # verifier feeds :public_key.verify) with the demo IdP RSA private key.
  # Source technique: lib/relyra/test_support/xmldsig_signer.ex:291-297
  defp sign_signed_info(%Node{} = signed_info_node, priv_key) do
    {:ok, c14n} = C14N.serialize(signed_info_node)
    c14n |> then(&:public_key.sign(&1, :sha256, priv_key)) |> Base.encode64()
  end

  # ---------------------------------------------------------------------------
  # Internal — tree-walk helpers (re-homed from XmldsigSigner)
  # ---------------------------------------------------------------------------

  defp parse_tree!(xml) do
    {:ok, %Node{} = tree} = SaxyTree.parse(xml)
    tree
  end

  # Depth-first search for the first element with the given local name.
  defp find_first_by_local(%Node{local: local} = node, local), do: node

  defp find_first_by_local(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first_by_local(child, local) end)
  end

  defp find_first_by_local(_other, _local), do: nil

  # Depth-first search for the first element with the given local name AND an
  # `ID` attribute equal to `id`.
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
end
