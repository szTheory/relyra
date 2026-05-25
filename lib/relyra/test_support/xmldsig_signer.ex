defmodule Relyra.TestSupport.XmldsigSigner do
  @moduledoc """
  Phase 29 (D-11) — a **minimal, genuine** XMLDSig signer for tests.

  This module produces a SAML `<Response>` carrying a real `ds:DigestValue` and a
  real `ds:SignatureValue` over the contained `<Assertion>`. It exists so the
  suite can assert the ONE input that must remain `{:ok}` after Phase 29 wires
  cryptographic verification into `Relyra.Security.Signature`: a legitimately
  signed Response (the positive control, ROADMAP success #3). Every
  structure-only "signature" the verifier now rejects has a genuine counterpart
  here.

  ## Anti-divergent-signer guarantee (D-12)

  The signer canonicalizes with the **SAME** C14N engine the verifier uses — it
  parses the final Response with `Relyra.Security.XML.SaxyTree`, locates the
  exact `<Assertion>` / `<SignedInfo>` tree nodes the verifier will bind, and
  canonicalizes THEM via `Relyra.Security.XML.PureBeam.canonicalize/1`
  (referenced element → `DigestValue`) and `Relyra.Security.XML.C14N.serialize/1`
  (`SignedInfo` → signed bytes). Because the digest and the signature are
  computed over the bytes produced by parsing the *emitted* XML, the signer can
  never canonicalize differently from the verifier — a divergent second signer
  would make the positive control pass for the wrong reason (T-29-15).

  ## Keypair reuse (D-11)

  The RSA-2048 key is `Relyra.TestSupport.FakeIdP.keypair()` — there is NO second
  `:public_key.generate_key` call in this module. The self-signed cert PEM the
  verifier trusts is derived from that same key. Phase 30 PROMOTES this module
  into `FakeIdP` (it fills the empty `SignedInfo` that `FakeIdP.response_xml`
  emits today); keeping the byte-alignment guarantee above is the whole point of
  the promotion.

  ## Prod guard (T-29-18)

  Mirrors `FakeIdP`'s `@prod_build` + `ensure_not_prod!/0` discipline so the
  signing code never compiles/runs in `:prod`.
  """

  @prod_build Mix.env() == :prod

  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node
  alias Relyra.TestSupport.FakeIdP

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"

  @default_issuer "https://idp.example.com/metadata"
  @default_destination "https://sp.example.com/saml/acs"
  @default_recipient "https://sp.example.com/saml/acs"
  @default_audience "https://sp.example.com/metadata"
  @default_in_response_to "id_request_123"
  @default_name_id "user@example.com"
  @default_assertion_id "assertion-1"
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  @typedoc """
  Result of `signed_response/1`: the genuinely-signed Response XML plus the
  cert chain (one self-signed PEM) the verifier must be configured with to
  accept it.
  """
  @type signed :: %{
          response_xml: String.t(),
          cert_chain: [String.t()]
        }

  @doc """
  Build a genuinely-signed SAML `<Response>` and the matching cert chain.

  Returns `%{response_xml: binary(), cert_chain: [pem]}`. Feed `response_xml`
  through `Relyra.consume_response/3` (or `ValidationPipeline.run/4`) with
  `cert_chain` threaded onto the connection (`:idp_certificates` / `:cert_chain`)
  or the `:cert_chain` opt, and the login verifies `{:ok}` for the RIGHT reason
  (a real RSA signature + a real digest over the canonicalized assertion).

  ## Options

    * `:issuer`, `:destination`, `:recipient`, `:audience`, `:in_response_to`,
      `:name_id`, `:assertion_id`, `:status`, `:not_before`, `:not_on_or_after`,
      `:subject_confirmation_not_on_or_after` — protocol field overrides so the
      same genuine signer can stand in for the fixed-shape structure-only
      Responses the triaged tests previously fed.
    * `:tamper_name_id` — when set to a string, the emitted XML's `<NameID>` text
      is rewritten to that value AFTER signing (the signature/digest are NOT
      recomputed). The result is a Response whose `SignatureValue` is well-formed
      but whose Reference digest no longer matches the (tampered) content — the
      `:digest_mismatch` negative control (T-29-17). Defaults to `nil` (no
      tamper).
  """
  @spec signed_response(keyword()) :: signed()
  def signed_response(opts \\ []) when is_list(opts) do
    ensure_not_prod!()

    fields = response_fields(opts)
    cert_pem = self_signed_cert_pem()

    # 1. Build the Response with placeholder digest/signature so the tree shape
    #    (and therefore the in-scope namespaces the C14N engine sees for the
    #    Assertion + SignedInfo) is EXACTLY the emitted shape.
    placeholder_xml = response_xml(fields, "", "")

    # 2. Parse with the verifier's parser; locate the bound <Assertion> node and
    #    compute the genuine DigestValue over its canonicalized bytes (the SAME
    #    PureBeam.canonicalize path the verifier uses — no ds:Transforms here, so
    #    plain exclusive-C14N over the bound node).
    placeholder_tree = parse_tree!(placeholder_xml)
    assertion_node = find_by_local_and_id(placeholder_tree, "Assertion", fields.assertion_id)
    digest_value_b64 = digest_for(assertion_node)

    # 3. Re-emit with the real DigestValue embedded, re-parse, locate the
    #    SignedInfo node, canonicalize it with the SAME engine (C14N.serialize),
    #    and sign those exact bytes with FakeIdP's key.
    digest_xml = response_xml(fields, digest_value_b64, "")
    digest_tree = parse_tree!(digest_xml)
    signed_info_node = find_first_by_local(digest_tree, "SignedInfo")
    signature_value_b64 = sign_signed_info(signed_info_node)

    # 4. Emit the final, genuinely-signed Response.
    signed_xml = response_xml(fields, digest_value_b64, signature_value_b64)

    # 5. Optional post-signing NameID tamper for the :digest_mismatch negative —
    #    the SignatureValue stays valid; only the referenced content changes.
    final_xml = maybe_tamper_name_id(signed_xml, fields.name_id, opts[:tamper_name_id])

    %{response_xml: final_xml, cert_chain: [cert_pem]}
  end

  @doc """
  Genuinely sign an EXISTING SAML `<Response>` XML in place, preserving its
  exact element shape.

  The input `response_xml` must contain an `<Assertion ID="...">` (the referenced
  element) and a `<Signature>` whose `<SignedInfo>` carries a
  `<Reference URI="#assertion_id">` with a `<DigestMethod>` but no
  `<DigestValue>`/`<SignatureValue>` yet (the structure-only shape the suite
  already builds). This function:

    1. parses the input with the verifier's parser,
    2. computes the genuine `DigestValue` over the canonicalized referenced
       `<Assertion>` (the SAME engine the verifier uses),
    3. injects `<DigestValue>…</DigestValue>` into the Reference,
    4. re-parses, canonicalizes the `<SignedInfo>` (SAME engine), signs it with
       `FakeIdP.keypair()`, and
    5. injects `<SignatureValue>…</SignatureValue>` after `</SignedInfo>`.

  Returns `%{response_xml: signed_xml, cert_chain: [pem]}`.

  Use this to re-point structure-only fixtures (whose declared outcome fires AT
  or AFTER the crypto step — time conditions, replay, success) at a genuine
  signature WITHOUT changing the fixture's assertion shape (so the downstream
  stage still sees exactly the fields it asserts on).

  Requires the referenced `<Assertion>` to carry the `ID` matching the
  Reference's `URI`. Raises if the structure cannot be located (a malformed test
  fixture should fail loudly, not sign silently).
  """
  @spec sign_response(String.t()) :: signed()
  def sign_response(response_xml) when is_binary(response_xml) do
    ensure_not_prod!()

    cert_pem = self_signed_cert_pem()

    assertion_id = reference_assertion_id!(response_xml)

    # 1. Genuine DigestValue over the bound <Assertion> (canonicalized via the
    #    verifier's path), computed from the EMITTED structure-only tree.
    tree = parse_tree!(response_xml)
    assertion_node = find_by_local_and_id(tree, "Assertion", assertion_id)

    unless is_struct(assertion_node, Node) do
      raise ArgumentError,
            "XmldsigSigner.sign_response/1: no <Assertion ID=\"#{assertion_id}\"> found"
    end

    digest_value_b64 = digest_for(assertion_node)

    # 2. Inject the DigestValue into the Reference (before </Reference>).
    with_digest = inject_digest_value(response_xml, digest_value_b64)

    # 3. Genuine SignatureValue over the canonicalized <SignedInfo> of the
    #    digest-bearing tree (SAME engine), signed with FakeIdP's key.
    digest_tree = parse_tree!(with_digest)
    signed_info_node = find_first_by_local(digest_tree, "SignedInfo")
    signature_value_b64 = sign_signed_info(signed_info_node)

    # 4. Inject the SignatureValue after </SignedInfo>.
    signed_xml = inject_signature_value(with_digest, signature_value_b64)

    %{response_xml: signed_xml, cert_chain: [cert_pem]}
  end

  @doc """
  The self-signed certificate PEM (a single-element cert chain) the verifier must
  trust to accept this signer's Responses. Derived from `FakeIdP.keypair()`.

  Exposed so a test can assert against the cert directly, or pass a DIFFERENT
  cert (a throwaway keypair) to drive the wrong-key `:invalid_signature`
  negative.
  """
  @spec self_signed_cert_pem() :: String.t()
  def self_signed_cert_pem do
    ensure_not_prod!()

    priv = FakeIdP.keypair()
    %{cert: cert_der} = :public_key.pkix_test_root_cert(~c"CN=relyra-fake-idp", key: priv)
    :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
  end

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp response_fields(opts) do
    %{
      issuer: Keyword.get(opts, :issuer, @default_issuer),
      destination: Keyword.get(opts, :destination, @default_destination),
      recipient: Keyword.get(opts, :recipient, @default_recipient),
      audience: Keyword.get(opts, :audience, @default_audience),
      in_response_to: Keyword.get(opts, :in_response_to, @default_in_response_to),
      name_id: Keyword.get(opts, :name_id, @default_name_id),
      assertion_id: Keyword.get(opts, :assertion_id, @default_assertion_id),
      status: Keyword.get(opts, :status, @success_status),
      not_before: Keyword.get(opts, :not_before, "2000-01-01T00:00:00Z"),
      not_on_or_after: Keyword.get(opts, :not_on_or_after, "2099-01-01T00:00:00Z"),
      subject_confirmation_not_on_or_after:
        Keyword.get(opts, :subject_confirmation_not_on_or_after, "2099-01-01T00:00:00Z")
    }
  end

  # The Response carries the genuine ds:Signature (SignedInfo + Reference to the
  # Assertion ID, with the real DigestValue and SignatureValue substituted in).
  defp response_xml(fields, digest_value_b64, signature_value_b64) do
    "<Response Destination=\"#{fields.destination}\" InResponseTo=\"#{fields.in_response_to}\" ConnectionId=\"valid\">" <>
      "<Issuer>#{fields.issuer}</Issuer>" <>
      "<Status><StatusCode Value=\"#{fields.status}\"/></Status>" <>
      "<Assertion ID=\"#{fields.assertion_id}\">" <>
      "<Issuer>#{fields.issuer}</Issuer>" <>
      "<Subject>" <>
      "<NameID>#{fields.name_id}</NameID>" <>
      "<SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\">" <>
      "<SubjectConfirmationData Recipient=\"#{fields.recipient}\" NotOnOrAfter=\"#{fields.subject_confirmation_not_on_or_after}\"/>" <>
      "</SubjectConfirmation>" <>
      "</Subject>" <>
      "<Conditions NotBefore=\"#{fields.not_before}\" NotOnOrAfter=\"#{fields.not_on_or_after}\">" <>
      "<AudienceRestriction><Audience>#{fields.audience}</Audience></AudienceRestriction>" <>
      "</Conditions>" <>
      "</Assertion>" <>
      "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
      "<SignedInfo>" <>
      "<CanonicalizationMethod Algorithm=\"#{@exc_c14n}\"/>" <>
      "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
      "<Reference URI=\"##{fields.assertion_id}\">" <>
      "<DigestMethod Algorithm=\"#{@sha256}\"/>" <>
      "<DigestValue>#{digest_value_b64}</DigestValue>" <>
      "</Reference>" <>
      "</SignedInfo>" <>
      "<SignatureValue>#{signature_value_b64}</SignatureValue>" <>
      "</Signature>" <>
      "</Response>"
  end

  # Digest the referenced element via the verifier's canonicalize path so the
  # signer's DigestValue is byte-identical to what the verifier recomputes.
  defp digest_for(%Node{} = assertion_node) do
    {:ok, %{canonical_xml: ref_bytes}} = PureBeam.canonicalize(%{node: assertion_node})
    :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
  end

  # Sign the canonicalized SignedInfo (C14N.serialize — the SAME engine the
  # verifier feeds :public_key.verify) with FakeIdP's RSA key.
  defp sign_signed_info(%Node{} = signed_info_node) do
    {:ok, c14n_signed_info} = C14N.serialize(signed_info_node)

    c14n_signed_info
    |> then(&:public_key.sign(&1, :sha256, FakeIdP.keypair()))
    |> Base.encode64()
  end

  # Read the Reference's URI (#assertion_id) from the SignedInfo so sign_response/1
  # can locate the referenced <Assertion> in any fixture shape.
  defp reference_assertion_id!(xml) do
    case Regex.run(~r/<Reference\s+URI="#([^"]+)"/, xml) do
      [_, id] ->
        id

      _ ->
        raise ArgumentError,
              "XmldsigSigner.sign_response/1: no <Reference URI=\"#...\"> in payload"
    end
  end

  # Insert <DigestValue>…</DigestValue> immediately before the first </Reference>.
  defp inject_digest_value(xml, digest_value_b64) do
    String.replace(
      xml,
      "</Reference>",
      "<DigestValue>#{digest_value_b64}</DigestValue></Reference>",
      global: false
    )
  end

  # Insert <SignatureValue>…</SignatureValue> immediately after the first
  # </SignedInfo>.
  defp inject_signature_value(xml, signature_value_b64) do
    String.replace(
      xml,
      "</SignedInfo>",
      "</SignedInfo><SignatureValue>#{signature_value_b64}</SignatureValue>",
      global: false
    )
  end

  defp maybe_tamper_name_id(xml, _original, nil), do: xml

  defp maybe_tamper_name_id(xml, original, tampered) when is_binary(tampered) do
    # Rewrite the NameID text AFTER signing. The SignatureValue still verifies
    # against the SignedInfo bytes, but the referenced Assertion's digest no
    # longer matches its (now-tampered) content → :digest_mismatch.
    String.replace(
      xml,
      "<NameID>#{original}</NameID>",
      "<NameID>#{tampered}</NameID>"
    )
  end

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

  defp ensure_not_prod! do
    if @prod_build do
      raise "Relyra.TestSupport.XmldsigSigner is test-only"
    end
  end
end
