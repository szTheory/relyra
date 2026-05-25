defmodule Relyra.TestSupport.FakeIdPEncryptTest do
  @moduledoc """
  Round-trip smoke test for the single canonical encrypted-assertion generator
  (`FakeIdP.encrypt/2` + `encrypted_response/2`, Plan 34-02 / D-08).

  The load-bearing assertion is byte-identity: `FakeIdP.encrypt` output, fed to
  the UNCHANGED Phase-33 `XMLEnc.decrypt/3` with the matching SP private-key
  resolver, returns exactly the plaintext that went in. That proves the
  `IV(12) || CT || Tag(16)` CipherValue layout `split_cipher_value/1` round-trips
  (Pitfall 4 / T-34-05) and the self-contained-namespace splice survives
  (Pitfall 1 / T-34-04) — the prerequisite for the ENC-01 adversarial corpus
  (Plan 04).
  """
  use ExUnit.Case, async: true

  alias Relyra.Security.XMLEnc
  alias Relyra.TestSupport.FakeIdP

  setup do
    keypair = FakeIdP.keypair()
    {:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = keypair
    pub_key = {:RSAPublicKey, n, e}

    pem =
      :public_key.pem_encode([
        {:RSAPrivateKey, :public_key.der_encode(:RSAPrivateKey, keypair), :not_encrypted}
      ])

    Application.put_env(:relyra, :sp_private_key_pem, pem)
    on_exit(fn -> Application.delete_env(:relyra, :sp_private_key_pem) end)

    {:ok, keypair: keypair, pub_key: pub_key, pem: pem}
  end

  # A genuinely-signed, self-contained <Assertion> (its own SAML assertion xmlns)
  # accompanied by its sibling <Signature> — the exact fragment shape
  # encrypted_response/2 encrypts. Built here from the canonical signer so the
  # round-trip exercises real signed bytes, not a placeholder string.
  defp signed_assertion_plaintext do
    %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.signed_response([])

    [assertion] = Regex.run(~r/<Assertion\b.*?<\/Assertion>/s, signed_xml)
    [signature] = Regex.run(~r/<Signature\b.*?<\/Signature>/s, signed_xml)

    namespaced =
      String.replace(
        assertion,
        ~r/^<Assertion\b/,
        ~s(<Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion"),
        global: false
      )

    namespaced <> signature
  end

  describe "encrypt/2 round-trip" do
    test "FakeIdP.encrypt -> XMLEnc.decrypt returns the original signed bytes", %{
      pub_key: pub_key
    } do
      signed_xml = signed_assertion_plaintext()

      encrypted = FakeIdP.encrypt(signed_xml, pub_key)

      assert XMLEnc.decrypt(encrypted, Relyra.KeyResolver.Default, connection: %{}) ==
               {:ok, signed_xml}
    end
  end

  describe "encrypt/2 envelope shape" do
    test "output advertises the accepted RSA-OAEP + AES-256-GCM URIs", %{pub_key: pub_key} do
      encrypted =
        FakeIdP.encrypt(
          ~s(<Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="a1">x</Assertion>),
          pub_key
        )

      assert encrypted =~ "<EncryptedAssertion"
      assert encrypted =~ "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
      assert encrypted =~ "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
    end
  end

  describe "encrypted_response/2 full Response" do
    test "produces a Response binary carrying the EncryptedAssertion and a Status" do
      response = FakeIdP.encrypted_response()

      assert is_binary(response)
      assert response =~ "<Response"
      assert response =~ "<EncryptedAssertion"
      assert response =~ "<Status"
    end

    test "the EncryptedAssertion inside the Response round-trips to the signed inner bytes" do
      response = FakeIdP.encrypted_response()

      [encrypted_assertion] =
        Regex.run(~r/<EncryptedAssertion\b.*<\/EncryptedAssertion>/s, response)

      assert {:ok, decrypted} =
               XMLEnc.decrypt(encrypted_assertion, Relyra.KeyResolver.Default, connection: %{})

      # The decrypted plaintext is the self-contained signed Assertion fragment.
      assert decrypted =~ ~s(xmlns="urn:oasis:names:tc:SAML:2.0:assertion")
      assert decrypted =~ "<SignatureValue>"
      assert decrypted =~ "<DigestValue>"
    end
  end
end
