defmodule Relyra.Security.SignatureCryptoTest do
  @moduledoc """
  Cryptographic XMLDSig acceptance and rejection through `Signature.verify/4`.

  The suite covers forged and malformed signature values, digest mismatches,
  unsupported verification methods, malformed configured certificates, and
  pre-crypto trust rejections. Genuine signed controls prove that valid input
  reaches `:public_key.verify` and passes Reference digest recomputation; wrong
  keys and post-signing changes remain rejected.

  Rejections use typed `Relyra.Error` values and return without raising.
  """
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree.Node
  alias Relyra.TestSupport.XmldsigSigner

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @rsa_sha256_digest "http://www.w3.org/2001/04/xmlenc#sha256"
  @ecdsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"

  describe "typed errors cover digest and verification-method rejection" do
    test "Relyra.Error accepts :digest_mismatch and :unsupported_signature_algorithm" do
      assert %Error{type: :digest_mismatch} = Error.new(:digest_mismatch, "x")

      assert %Error{type: :unsupported_signature_algorithm} =
               Error.new(:unsupported_signature_algorithm, "x")
    end
  end

  describe "public_key_from_cert_chain/1 fail-closed (via Signature.verify/4)" do
    test "a deliberately-corrupt cert PEM → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      corrupt_chain = ["-----BEGIN CERTIFICATE-----\nnot-base64-!!!\n-----END CERTIFICATE-----"]

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), corrupt_chain)
    end

    test "an empty-string cert PEM → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), [""])
    end

    test "a non-PEM garbage cert → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), ["not a pem at all"])
    end
  end

  describe "signature math rejects forged and malformed values" do
    test "forged (well-formed, valid-base64) SignatureValue → :invalid_signature" do
      signed = genuine_signed_doc()
      # Replace the genuine SignatureValue with valid base64 of the right byte
      # length but the wrong bytes (a forged signature).
      forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(signed.signature_bytes)))
      parsed_doc = put_candidate(signed.parsed_doc, :signature_value_b64, forged_b64)

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "non-base64 SignatureValue → :invalid_signature (Base.decode64 :error mapped)" do
      signed = genuine_signed_doc()
      parsed_doc = put_candidate(signed.parsed_doc, :signature_value_b64, "!!!not-base64!!!")

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "digest recomputation rejects malformed or mismatched values" do
    test "truncated DigestValue (wrong decoded length) → :digest_mismatch (no crash)" do
      signed = genuine_signed_doc()
      # A base64 that decodes to fewer than 32 bytes — must NOT crash
      # :crypto.hash_equals (length guard must run first).
      truncated_b64 = Base.encode64(<<1, 2, 3>>)
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, truncated_b64)

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "non-base64 DigestValue → :digest_mismatch (no crash)" do
      signed = genuine_signed_doc()
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, "!!!not-base64!!!")

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "right-length-but-wrong DigestValue → :digest_mismatch" do
      signed = genuine_signed_doc()
      wrong_b64 = Base.encode64(:crypto.strong_rand_bytes(32))
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, wrong_b64)

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "unsupported verification methods fail closed" do
    test "ECDSA signature method → :unsupported_signature_algorithm (before any verify)" do
      signed = genuine_signed_doc()
      # The allowlist permits ECDSA URIs (for SHA-2 strength); the digest-atom
      # gate is what rejects ECDSA before any crypto runs.
      parsed_doc = %{signed.parsed_doc | signature_method: @ecdsa_sha256}

      assert {:error, %Error{type: :unsupported_signature_algorithm}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "malformed configured certificates fail closed" do
    test "malformed cert with a genuine candidate → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(
                 signed.parsed_doc,
                 connection(),
                 ["-----BEGIN CERTIFICATE-----\ngarbage\n-----END CERTIFICATE-----"]
               )
    end
  end

  describe "configured-certificate and KeyInfo trust gates reject before crypto" do
    test "empty cert_chain rejects before crypto (:untrusted_certificate)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), [])
    end

    test "document KeyInfo trust rejects before crypto (:untrusted_certificate)" do
      signed = genuine_signed_doc()
      parsed_doc = Map.put(signed.parsed_doc, :key_info_trust, true)

      assert {:error,
              %Error{
                type: :untrusted_certificate,
                details: %{reason: :document_keyinfo_forbidden}
              }} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "genuine signature passes signature and digest verification" do
    test "a genuinely-signed candidate verifies {:ok, %SignedNode{}}" do
      signed = genuine_signed_doc()

      assert {:ok, %Relyra.Security.SignedNode{} = signed_node} =
               Signature.verify(signed.parsed_doc, connection(), signed.cert_chain)

      assert signed_node.signature_method == @rsa_sha256
      assert signed_node.digest_method == @rsa_sha256_digest
    end
  end

  describe "signed responses verify only with the trusted key and unchanged content" do
    test "POSITIVE control: a genuinely-signed Response verifies {:ok, %SignedNode{}}" do
      signed = XmldsigSigner.signed_response()
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      assert {:ok, %Relyra.Security.SignedNode{} = signed_node} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)

      assert signed_node.signature_method == @rsa_sha256
      assert signed_node.digest_method == @rsa_sha256_digest
      assert signed_node.xml_id == "assertion-1"
    end

    test "wrong-key negative: genuine Response against a DIFFERENT cert → :invalid_signature" do
      signed = XmldsigSigner.signed_response()
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      # A self-signed cert from a SECOND, throwaway keypair — NOT FakeIdP's.
      wrong_cert_chain = [throwaway_cert_pem()]

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), wrong_cert_chain)
    end

    test "tampered-NameID negative: NameID rewritten after signing → :digest_mismatch" do
      tampered = XmldsigSigner.signed_response(tamper_name_id: "attacker@evil.example.com")
      {:ok, parsed_doc} = PureBeam.parse_safely(tampered.response_xml, [])

      # The SignatureValue is still well-formed (verifies against SignedInfo);
      # only the referenced Assertion's content changed, so the digest recompute
      # is what catches the tamper.
      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), tampered.cert_chain)
    end

    test "a newline-wrapped SignatureValue still verifies {:ok}" do
      # Real IdPs (ADFS, Shibboleth, OpenSAML) line-wrap base64 at 64/76 columns.
      # The SignatureValue is a sibling of SignedInfo (NOT canonicalized for the
      # signature math), so wrapping it post-signing exercises decode_b64 alone:
      # without `ignore: :whitespace` this fails closed with :invalid_signature.
      # (DigestValue decodes through the SAME decode_b64 path; it can't be wrapped
      # post-signing because it lives inside the signed SignedInfo.)
      signed = XmldsigSigner.signed_response()
      wrapped_xml = wrap_b64_element(signed.response_xml, "SignatureValue")

      # The wrap actually introduced internal whitespace in the element body.
      assert wrapped_xml =~ ~r/<SignatureValue>[^<]*\n[^<]*<\/SignatureValue>/

      {:ok, parsed_doc} = PureBeam.parse_safely(wrapped_xml, [])

      assert {:ok, %Relyra.Security.SignedNode{}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  # A self-signed cert from a throwaway RSA keypair distinct from FakeIdP's, for
  # the wrong-key negative. Generated locally here (NOT in the signer module —
  # the signer reuses FakeIdP's key only).
  defp throwaway_cert_pem do
    priv = :public_key.generate_key({:rsa, 2048, 65_537})
    %{cert: der} = :public_key.pkix_test_root_cert(~c"CN=relyra-wrong-key", key: priv)
    :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
  end

  # Rewrite the base64 body of <element>…</element> wrapped at 64 columns with
  # embedded newlines, mirroring how real IdPs emit <ds:SignatureValue>.
  defp wrap_b64_element(xml, element) do
    Regex.replace(~r/(<#{element}>)(.*?)(<\/#{element}>)/s, xml, fn _full, open, body, close ->
      wrapped =
        body
        |> String.replace(~r/\s+/, "")
        |> String.codepoints()
        |> Enum.chunk_every(64)
        |> Enum.map_join("\n", &Enum.join/1)

      open <> "\n" <> wrapped <> "\n" <> close
    end)
  end

  # Build a genuine XMLDSig candidate with a local keypair and certificate.
  # The test signs canonical SignedInfo and computes the Reference digest with
  # the same canonicalization paths used by verification.

  defp genuine_signed_doc do
    {priv, cert_pem} = keypair_and_cert()

    assertion_id = "assertion-smoke-1"

    # The referenced Assertion (whitespace-free to keep the smoke independent of
    # pretty-print mixed-content concerns; the C14N walk is exercised either way).
    assertion_xml =
      "<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"#{assertion_id}\">" <>
        "<Issuer>https://idp.example.com</Issuer>" <>
        "<Subject><NameID>user@example.com</NameID></Subject>" <>
        "</Assertion>"

    assertion_node = parse_node(assertion_xml)

    # Compute the genuine DigestValue over the canonicalized referenced element,
    # using the SAME canonicalize path the verifier uses (no ds:Transforms → plain
    # exclusive-C14N over the bound node).
    {:ok, %{canonical_xml: ref_bytes}} =
      PureBeam.canonicalize(%{node: assertion_node})

    digest = :crypto.hash(:sha256, ref_bytes)
    digest_value_b64 = Base.encode64(digest)

    # Build a SignedInfo embedding that DigestValue, then canonicalize it bare
    # (C14N.serialize; SignedInfo has no enveloped-signature transform).
    signed_info_xml =
      "<SignedInfo xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
        "<CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
        "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
        "<Reference URI=\"##{assertion_id}\">" <>
        "<DigestMethod Algorithm=\"#{@rsa_sha256_digest}\"/>" <>
        "<DigestValue>#{digest_value_b64}</DigestValue>" <>
        "</Reference>" <>
        "</SignedInfo>"

    signed_info_node = parse_node(signed_info_xml)

    {:ok, c14n_signed_info} = C14N.serialize(signed_info_node)
    signature_bytes = :public_key.sign(c14n_signed_info, :sha256, priv)
    signature_value_b64 = Base.encode64(signature_bytes)

    candidate = %{
      xml_id: assertion_id,
      xpath: "/Response/Assertion[1]",
      signed_xml: assertion_xml,
      node: assertion_node,
      signature_node: nil,
      transforms_node: nil,
      signed_info_node: signed_info_node,
      digest_value_b64: digest_value_b64,
      signature_value_b64: signature_value_b64
    }

    parsed_doc = %{
      key_info_trust: false,
      duplicate_ids: [],
      signature_method: @rsa_sha256,
      digest_method: @rsa_sha256_digest,
      signed_candidates: [candidate]
    }

    %{
      parsed_doc: parsed_doc,
      cert_chain: [cert_pem],
      signature_bytes: signature_bytes
    }
  end

  defp keypair_and_cert do
    priv = :public_key.generate_key({:rsa, 2048, 65_537})
    %{cert: cert_der} = :public_key.pkix_test_root_cert(~c"CN=relyra-crypto-test", [{:key, priv}])
    pem = :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
    {priv, pem}
  end

  defp parse_node(xml) do
    {:ok, %Node{} = node} = Relyra.Security.XML.SaxyTree.parse(xml)
    node
  end

  defp put_candidate(parsed_doc, key, value) do
    [candidate] = parsed_doc.signed_candidates
    %{parsed_doc | signed_candidates: [Map.put(candidate, key, value)]}
  end

  defp connection, do: %{connection_id: "conn-crypto"}
end
