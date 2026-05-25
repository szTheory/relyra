defmodule Relyra.Protocol.DecryptAssertionTest do
  @moduledoc """
  Phase 34 Plan 03 (ENC-01) — unit-level guards for the `:decrypt_assertion`
  pre-stage inserted into `ValidationPipeline.do_run/4` (D-01).

  These cover the branch logic that needs NO real encrypted fixture (the full
  7-fixture encrypted corpus is Plan 04):

    * NO-OP (D-02) — proven dependency-free via a raise-if-invoked `:key_resolver`
      module: running an unencrypted, genuinely-signed Response through the
      pipeline must NOT raise (the absence of the raise proves the `:none` branch
      never reached `XMLEnc.decrypt/3`, which dispatches the resolver via `apply`).
    * AMBIGUITY-BEFORE-CRYPTO (D-03 / SC#2) — a Response carrying BOTH a sibling
      cleartext `<Assertion>` and an `<EncryptedAssertion>` returns
      `:ambiguous_assertion` even when the ciphertext WOULD `:decryption_failed`,
      proving the ambiguity reject fires before any decrypt call.
    * >1 EncryptedAssertion → `:ambiguous_assertion` (same exactly-one invariant).
    * PREFIX-AWARE SPLICE (RESEARCH A1) — a single `<saml:EncryptedAssertion>` (a
      namespace-prefixed tag the FakeIdP fixtures never emit) travels the
      splice/re-parse path, proving the locator matched the prefixed substring.
    * EXACTLY-ONE-MATCH GUARD (RESEARCH A1) — two `<EncryptedAssertion>`
      substrings → `:ambiguous_assertion`, never silently splicing the first.

  Every error assertion pins the EXACT `%Error{type:}` (never bare `{:error, _}`),
  mirroring `test/security/xml/adversarial_crypto_test.exs:90-125`.
  """
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.TestSupport.FakeIdP

  @fixed_now ~U[2026-04-24 16:00:00Z]
  @idp_entity_id "https://idp.example.com/metadata"

  # A key resolver whose resolve/1 RAISES if it is ever invoked. `XMLEnc.decrypt/3`
  # dispatches the resolver via `apply(module, :resolve, [connection])`, so reaching
  # the decrypt path would call this and blow up. The no-op test asserts it does NOT.
  defmodule RaiseIfInvoked do
    def resolve(_connection), do: raise("decrypt path reached — :none branch leaked into XMLEnc")
  end

  defp connection(overrides \\ []) do
    Map.merge(
      %{
        connection_id: "conn-123",
        idp_entity_id: @idp_entity_id,
        issuer: @idp_entity_id,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_certificates: [FakeIdP.self_signed_cert_pem()],
        cert_chain: [FakeIdP.self_signed_cert_pem()],
        allow_idp_initiated: true
      },
      Enum.into(overrides, %{})
    )
  end

  # A complete Response carrying an EncryptedAssertion substring whose tag may be
  # prefixed and whose ciphertext is garbage that WOULD :decryption_failed. Used to
  # drive the detector/splice without a real encrypted fixture.
  defp response_with(encrypted_assertion_blocks, opts \\ []) do
    cleartext = Keyword.get(opts, :cleartext_assertion, "")
    signature = Keyword.get(opts, :signature, "")

    """
    <Response Destination="https://sp.example.com/saml/acs" InResponseTo="id_request_123" ConnectionId="valid">
      <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">#{@idp_entity_id}</Issuer>
      <Status><StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></Status>
      #{cleartext}#{encrypted_assertion_blocks}#{signature}
    </Response>
    """
    |> String.trim()
  end

  # A structurally-complete <Signature> block (no real crypto) so a cleartext
  # Assertion satisfies parse_safely/2's signature gate, letting the pre-stage reach
  # the ambiguity detection. The signature never verifies — the point is reaching the
  # ambiguity reject, which fires before any verification.
  defp signature_block do
    """
    <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
      <SignedInfo>
        <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
        <Reference URI="#a1"><DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/></Reference>
      </SignedInfo>
    </Signature>
    """
    |> String.trim()
  end

  # A garbage <EncryptedAssertion> (optionally prefixed) whose ciphertext fails to
  # decrypt — structurally complete so XMLEnc.parse_enc_fields/1 can walk it but the
  # AES-GCM / RSA-OAEP step fails -> :decryption_failed.
  defp garbage_encrypted_assertion(prefix \\ "") do
    {open, close} =
      if prefix == "" do
        {"<EncryptedAssertion xmlns:xenc=\"http://www.w3.org/2001/04/xmlenc#\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">",
         "</EncryptedAssertion>"}
      else
        {"<#{prefix}:EncryptedAssertion xmlns:#{prefix}=\"urn:oasis:names:tc:SAML:2.0:assertion\" xmlns:xenc=\"http://www.w3.org/2001/04/xmlenc#\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">",
         "</#{prefix}:EncryptedAssertion>"}
      end

    open <>
      "<xenc:EncryptedData><xenc:EncryptionMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#aes256-gcm\"/><ds:KeyInfo><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p\"/><xenc:CipherData><xenc:CipherValue>#{Base.encode64(:crypto.strong_rand_bytes(256))}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></ds:KeyInfo><xenc:CipherData><xenc:CipherValue>#{Base.encode64(:crypto.strong_rand_bytes(64))}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedData>" <>
      close
  end

  # A cleartext <Assertion> complete enough to satisfy parse_safely/2's field gates.
  defp cleartext_assertion do
    """
    <Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="a1">
      <Issuer>#{@idp_entity_id}</Issuer>
      <Subject>
        <NameID>user@example.com</NameID>
        <SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
          <SubjectConfirmationData Recipient="https://sp.example.com/saml/acs" NotOnOrAfter="2099-01-01T00:00:00Z"/>
        </SubjectConfirmation>
      </Subject>
      <Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="2099-01-01T00:00:00Z">
        <AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction>
      </Conditions>
    </Assertion>
    """
    |> String.trim()
  end

  setup do
    keypair = FakeIdP.keypair()

    pem =
      :public_key.pem_encode([
        {:RSAPrivateKey, :public_key.der_encode(:RSAPrivateKey, keypair), :not_encrypted}
      ])

    Application.put_env(:relyra, :sp_private_key_pem, pem)
    on_exit(fn -> Application.delete_env(:relyra, :sp_private_key_pem) end)
    :ok
  end

  describe "no-op path (D-02 / SC#3) — proven without a mock" do
    test "an unencrypted, genuinely-signed Response does NOT reach XMLEnc.decrypt/3" do
      b64 = FakeIdP.sign(FakeIdP.build_response())
      {:ok, xml} = Base.decode64(b64, padding: false)

      request_intent = %{request_id: "id_request_123"}

      # The raise-if-invoked resolver blows up IF the :none branch ever reached
      # XMLEnc.decrypt/3. The absence of a raise proves the no-op path.
      result =
        ValidationPipeline.run(xml, request_intent, connection(),
          now: @fixed_now,
          key_resolver: RaiseIfInvoked
        )

      # It must validate exactly as before — a successful login on a genuine signature.
      assert {:ok, login_result} = result
      assert login_result.name_id == "user@example.com"
    end
  end

  describe "ambiguity is rejected BEFORE any crypto (D-03 / SC#2)" do
    test "cleartext <Assertion> + <EncryptedAssertion> -> :ambiguous_assertion" do
      # The cleartext Assertion is COMPLETE enough to pass parse_safely/2's field
      # gates, so the pre-stage reaches the ambiguity check (rather than the outer
      # parse rejecting on missing assertion fields). This is the cleartext-injection
      # attack shape (CVE-2026-2092 class).
      cleartext = cleartext_assertion()

      xml =
        response_with(garbage_encrypted_assertion(),
          cleartext_assertion: cleartext,
          signature: signature_block()
        )

      # The ciphertext WOULD :decryption_failed; seeing :ambiguous_assertion proves
      # the ambiguity check fired FIRST (Pitfall 2 / SC#2).
      assert {:error, %Error{type: :ambiguous_assertion}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end

    test ">1 <EncryptedAssertion> -> :ambiguous_assertion" do
      xml = response_with(garbage_encrypted_assertion() <> garbage_encrypted_assertion())

      assert {:error, %Error{type: :ambiguous_assertion}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end
  end

  describe "prefix-aware splice locator (RESEARCH A1)" do
    test "a single UNPREFIXED <EncryptedAssertion> travels the splice/re-parse path" do
      # Baseline: the unprefixed tag the FakeIdP fixtures emit reaches decrypt. A
      # garbage ciphertext fails -> :decryption_failed, proving the locator matched
      # and drove the single EncryptedAssertion into XMLEnc.decrypt/3.
      xml = response_with(garbage_encrypted_assertion())

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end

    test "a single <saml:EncryptedAssertion> travels the splice/re-parse path" do
      # The FakeIdP fixtures only ever emit the UNPREFIXED tag, so a prefixed tag
      # exercises a path that would otherwise be unverified. A garbage ciphertext is
      # fine — the point is the prefix-aware locator FOUND the prefixed substring and
      # drove it into decrypt (-> :decryption_failed), not that it decrypted. Seeing
      # :decryption_failed (not :missing_protocol_field) proves the prefixed tag was
      # detected as {:single, node} and the prefixed locator matched its substring.
      xml = response_with(garbage_encrypted_assertion("saml"))

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end
  end

  describe "exactly-one-match guard on the splice locator (RESEARCH A1)" do
    test "two EncryptedAssertion substrings -> :ambiguous_assertion, never silent-splice-first" do
      # Two encrypted blocks are rejected at the detector (>1 branch); even if the
      # detector were bypassed, the splice locator's exactly-one-match guard would
      # also reject rather than splicing the first.
      xml = response_with(garbage_encrypted_assertion() <> garbage_encrypted_assertion("saml"))

      assert {:error, %Error{type: :ambiguous_assertion}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end
  end
end
