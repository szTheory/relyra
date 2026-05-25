defmodule Relyra.Security.XmlEncAdversarialTest do
  @moduledoc """
  Phase 34 Plan 04 (ENC-01 / SC#1 + SC#5) — the PERMANENT, pipeline-level
  encrypted-assertion adversarial corpus.

  This suite drives end-to-end through `ValidationPipeline.run/4` (the entry the
  `Relyra.consume_response/3` flow funnels into) using the Plan-02
  `FakeIdP.encrypt`/`encrypted_response` single canonical generator and the
  Plan-03 `:decrypt_assertion` pre-stage. It proves the WHOLE
  decrypt -> re-parse -> verify path:

    * POSITIVE CONTROL (SC#1) — a genuine `FakeIdP.encrypted_response` logs in
      `{:ok, login_result}` carrying the inner Assertion's NameID/attributes,
      proving the plaintext was decrypted, re-parsed via `parse_safely/2`, AND
      verified via `Signature.do_verify/4` BEFORE any identity field was read.

  Then the 7 NAMED ENC-01 fixtures (do NOT renumber / replace / fold any of
  them), each pinning the EXACT `%Error{type:}` (never bare `{:error, _}`):

      1 wrong-key            -> %Error{type: :decryption_failed}
      2 truncated GCM tag     -> %Error{type: :decryption_failed}
      3 PKCS1v1.5 transport   -> %Error{type: :decryption_failed}
      4 AES-CBC content       -> %Error{type: :decryption_failed}
      5 cleartext-injection   -> %Error{type: :ambiguous_assertion}  (BEFORE decrypt)
      6 malformed ciphertext  -> %Error{type: :decryption_failed}
      7 read-before-verify    -> verification-stage typed error AND no identity field

  Fixtures 1,2,3,4,6 all collapse to the SINGLE opaque `:decryption_failed` — the
  no-oracle property (T-34-13); a future distinct-atom regression flips a fixture
  red. Fixture 5 uses would-fail-decrypt ciphertext so `:ambiguous_assertion`
  proves the pre-crypto reject fired FIRST (SC#2 ordering, CVE-2026-2092 class).
  Fixture 7 (the STRONGEST guard) tampers the NameID AFTER signing then encrypts:
  the verification-stage error AND the absence of any identity field prove the
  decrypt-then-verify ordering (CVE-2025-54419 class).

  BONUS (8th, SUPPLEMENTAL — NOT one of the 7 named): a Response carrying TWO
  `<EncryptedAssertion>` elements -> `%Error{type: :ambiguous_assertion}` BEFORE
  any decrypt (defense-in-depth — the >1-encrypted branch is covered at the unit
  level in Plan 03; this exercises it end-to-end at the pipeline level).

  Every fixture wraps its plaintext through the SINGLE canonical
  `FakeIdP.encrypt`/`encrypted_response` generator (Plan 02) — no hand-rolled
  second encryption recipe (Pitfall 1, anti-masking).

  Gated into `ci.security` as its own `cmd mix test` line (Plan 04 Task 2,
  Phase-30 hollow-gate rule); the meta-gate `ci_gate_integrity_test.exs` confirms
  the line is non-hollow.
  """
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.TestSupport.FakeIdP

  @fixed_now ~U[2026-04-24 16:00:00Z]
  @idp_entity_id "https://idp.example.com/metadata"
  @request_intent %{request_id: "id_request_123"}

  # The XML-Enc URIs the blocked-variant fixtures read from the single canonical
  # generator (no re-typing — Plan 02 `enc_algorithm_uris/0`).
  @uris FakeIdP.enc_algorithm_uris()

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

  # The connection the pipeline validates against. `idp_certificates` / `cert_chain`
  # carry `FakeIdP.self_signed_cert_pem()` so `Signature.verify/4` accepts the
  # genuine inner signature; issuer/audience/recipient line up with the fixture
  # shape so a genuine decrypt+verify reaches a successful login.
  defp connection(overrides \\ []) do
    Map.merge(
      %{
        connection_id: "conn-enc",
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

  # ===========================================================================
  # POSITIVE CONTROL (SC#1) — genuine EncryptedAssertion -> {:ok, login}.
  #
  # Proves the decrypt -> re-parse -> verify -> identity-read ordering: the inner
  # Assertion is genuinely signed THEN encrypted by the canonical generator; the
  # pipeline decrypts it, re-parses through `parse_safely/2`, verifies the real
  # signature, and only THEN surfaces the NameID into the login result.
  # ===========================================================================

  describe "positive control (SC#1 — genuine EncryptedAssertion end-to-end)" do
    test "a valid FakeIdP.encrypted_response logs in {:ok, ...} with identity present POST-verify" do
      xml = FakeIdP.encrypted_response()

      assert {:ok, login_result} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)

      # Identity is readable ONLY because decrypt -> re-parse -> verify all passed
      # first (the inner signed Assertion's NameID).
      assert login_result.name_id == "user@example.com"
      assert login_result.issuer == @idp_entity_id
    end
  end

  # ===========================================================================
  # 7 NAMED ENC-01 FIXTURES — each pins its EXACT typed error.
  # ===========================================================================

  describe "fixture 1 — wrong key (T-34-13, opaque)" do
    test "CEK encrypted against a THROWAWAY pubkey -> :decryption_failed" do
      # Wrap a well-formed EncryptedAssertion (canonical generator, valid OAEP+GCM
      # recipe) but encrypt the CEK against a THROWAWAY pubkey (not the SP key), so
      # the SP private key cannot unwrap it. The RSA-OAEP unwrap fails before the
      # content is examined -> opaque :decryption_failed. The plaintext content is
      # irrelevant (unwrap fails first).
      wrong_pub = throwaway_pub_key()
      enc = FakeIdP.encrypt("genuinely-shaped-but-unreadable plaintext", wrong_pub)
      xml = response_envelope(enc)

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)
    end
  end

  describe "fixture 2 — truncated GCM auth tag (T-34-13, opaque)" do
    test "a 15-byte (< 16) GCM tag -> :decryption_failed" do
      # tag_length: 15 trips the exactly-16-byte auth-tag guard
      # (algorithm_policy.ex:158) BEFORE the AEAD call.
      xml = FakeIdP.encrypted_response([], tag_length: 15)

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)
    end
  end

  describe "fixture 3 — PKCS1v1.5 key transport (T-34-13, hard-reject)" do
    test "EncryptionMethod xmlenc#rsa-1_5 -> :decryption_failed" do
      # The blocked rsa-1_5 transport URI is hard-rejected at AlgorithmPolicy with
      # NO escape hatch (Bleichenbacher class). The CEK is actually wrapped with
      # PKCS1v1.5 so the fixture is internally consistent, but the policy gate
      # fires before any RSA unwrap is attempted.
      xml =
        FakeIdP.encrypted_response([],
          key_transport_uri: @uris.rsa_pkcs1,
          key_padding: :rsa_pkcs1_padding
        )

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)
    end
  end

  describe "fixture 4 — AES-CBC content (T-34-13, policy reject)" do
    test "content EncryptionMethod xmlenc#aes256-cbc -> :decryption_failed" do
      # The default policy has no CBC escape hatch; the content URI is rejected
      # before any decryption. The CipherValue is the GCM layout but the algorithm
      # gate fires first.
      xml = FakeIdP.encrypted_response([], content_uri: @uris.aes256_cbc)

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)
    end
  end

  describe "fixture 5 — cleartext-injection (T-34-14, ambiguity BEFORE crypto)" do
    test "sibling cleartext <Assertion> + <EncryptedAssertion> -> :ambiguous_assertion" do
      # The encrypted half carries garbage ciphertext that WOULD :decryption_failed.
      # Seeing :ambiguous_assertion proves the ambiguity reject fired BEFORE any
      # decrypt call (SC#2 ordering, CVE-2026-2092 class).
      garbage = garbage_encrypted_assertion()

      xml =
        response_envelope(cleartext_assertion() <> garbage <> signature_block())

      assert {:error, %Error{type: :ambiguous_assertion}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end
  end

  describe "fixture 6 — malformed ciphertext (T-34-13, opaque)" do
    test "invalid-base64 / sub-28-byte CipherValue -> :decryption_failed" do
      # Override the content CipherValue with non-base64 garbage via the canonical
      # generator's :cipher_value_b64 opt — the split/decode fails -> opaque
      # :decryption_failed.
      xml = FakeIdP.encrypted_response([], cipher_value_b64: "not!valid!base64!!!!")

      assert {:error, %Error{type: :decryption_failed}} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)
    end
  end

  describe "fixture 7 — read-before-verify (STRONGEST GUARD, T-34-12, CVE-2025-54419)" do
    test "genuinely-signed-then-TAMPERED assertion -> verification error AND no identity leaked" do
      # The inner Assertion is genuinely signed, the NameID is rewritten AFTER
      # signing, THEN the whole thing is encrypted. The pipeline must decrypt,
      # re-parse, and FAIL at the verification stage (digest no longer matches the
      # tampered NameID) — and crucially surface NO identity field. If any
      # name_id/attributes leaked, an attacker who corrupts a signed assertion
      # post-signing could still log in (the auth-bypass class).
      xml =
        FakeIdP.encrypted_response(tamper_name_id: "attacker@evil.example.com")

      assert {:error, %Error{type: t} = error} =
               ValidationPipeline.run(xml, @request_intent, connection(), now: @fixed_now)

      assert t in [:invalid_signature, :digest_mismatch],
             "expected a verification-stage typed error, got #{inspect(t)}"

      # The error must carry NO identity field — neither the genuine NameID nor the
      # attacker-substituted one ever reaches the caller before verification.
      refute_identity_leak(error)
    end
  end

  # ===========================================================================
  # BONUS (SUPPLEMENTAL — NOT one of the 7 named) — multi-EncryptedAssertion.
  #
  # Two <EncryptedAssertion> elements -> :ambiguous_assertion BEFORE any decrypt
  # (defense-in-depth for the >1-encrypted branch end-to-end at the pipeline
  # level; Plan 03 covers it at the unit level only). Both encrypted halves carry
  # garbage ciphertext that WOULD :decryption_failed, so :ambiguous_assertion
  # proves the multi-encrypted reject fired before crypto.
  # ===========================================================================

  describe "BONUS (supplemental, defense-in-depth) — >1 EncryptedAssertion" do
    test "two <EncryptedAssertion> -> :ambiguous_assertion BEFORE any decrypt" do
      xml =
        response_envelope(garbage_encrypted_assertion() <> garbage_encrypted_assertion())

      assert {:error, %Error{type: :ambiguous_assertion}} =
               ValidationPipeline.run(xml, nil, connection(), now: @fixed_now)
    end
  end

  # ===========================================================================
  # Local helpers.
  # ===========================================================================

  # A throwaway RSA public key distinct from the SP key, for the wrong-key fixture.
  defp throwaway_pub_key do
    {:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} =
      :public_key.generate_key({:rsa, 2048, 65_537})

    {:RSAPublicKey, n, e}
  end

  # The full <Response> envelope carrying arbitrary inner body bytes (cleartext
  # assertion, encrypted assertion(s), signature). Mirrors the FakeIdP /
  # decrypt_assertion_test envelope so the OUTER parse is realistic.
  defp response_envelope(inner_body) do
    """
    <Response Destination="https://sp.example.com/saml/acs" InResponseTo="id_request_123" ConnectionId="valid">
      <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">#{@idp_entity_id}</Issuer>
      <Status><StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></Status>
      #{inner_body}
    </Response>
    """
    |> String.trim()
  end

  # A structurally-complete <EncryptedAssertion> whose ciphertext WOULD fail to
  # decrypt — used by the ambiguity fixtures so :ambiguous_assertion proves the
  # pre-crypto reject fired first. Built via the canonical generator's
  # cipher_value_b64 override so there is no divergent recipe.
  defp garbage_encrypted_assertion do
    FakeIdP.encrypt("ignored", sp_public_key(),
      cipher_value_b64: Base.encode64(:crypto.strong_rand_bytes(64))
    )
  end

  defp sp_public_key do
    {:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = FakeIdP.keypair()
    {:RSAPublicKey, n, e}
  end

  # A cleartext <Assertion> complete enough to satisfy parse_safely/2's field
  # gates so the pre-stage reaches the ambiguity detection (the injection shape).
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

  # A structurally-complete <Signature> (no real crypto) so the cleartext
  # Assertion satisfies parse_safely/2's signature gate, letting the pre-stage
  # reach the ambiguity reject (which fires before any verification).
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

  # Assert NO identity field is reachable from the error returned before
  # verification. The pipeline returns %Error{} (not a login map) on rejection, so
  # neither the genuine nor the attacker NameID should appear anywhere in it.
  defp refute_identity_leak(%Error{} = error) do
    blob = inspect(error)
    refute blob =~ "user@example.com", "genuine NameID leaked into the pre-verify error"
    refute blob =~ "attacker@evil.example.com", "tampered NameID leaked into the pre-verify error"

    refute Map.has_key?(error, :name_id)
    refute Map.has_key?(error, :attributes)
  end
end
