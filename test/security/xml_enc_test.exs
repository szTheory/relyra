defmodule Relyra.Security.XMLEncTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.XMLEnc
  alias Relyra.TestSupport.FakeIdP

  @rsa_oaep_uri "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
  @rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"
  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
  @aes256_cbc_uri "http://www.w3.org/2001/04/xmlenc#aes256-cbc"

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

  defp build_encrypted_assertion(key_transport_uri, content_uri, enc_key_b64, cipher_value_b64) do
    """
    <EncryptedAssertion xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedData><xenc:EncryptionMethod Algorithm="#{content_uri}"/><ds:KeyInfo><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm="#{key_transport_uri}"/><xenc:CipherData><xenc:CipherValue>#{enc_key_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></ds:KeyInfo><xenc:CipherData><xenc:CipherValue>#{cipher_value_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedData></EncryptedAssertion>
    """
    |> String.trim()
  end

  describe "happy path" do
    test "valid RSA-OAEP + AES-256-GCM returns {:ok, plaintext}", %{pub_key: pub_key} do
      plaintext = "Hello, XMLEnc roundtrip!"

      # Generate random CEK and encrypt it with RSA-OAEP using the SP public key
      cek = :crypto.strong_rand_bytes(32)

      enc_key_bytes =
        :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])

      enc_key_b64 = Base.encode64(enc_key_bytes)

      # Encrypt plaintext with AES-256-GCM; produce IV(12) || CT || Tag(16)
      iv = :crypto.strong_rand_bytes(12)

      {ciphertext, auth_tag} =
        :crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, <<>>, 16, true)

      cipher_value_b64 = Base.encode64(iv <> ciphertext <> auth_tag)

      bytes =
        build_encrypted_assertion(@rsa_oaep_uri, @aes256_gcm_uri, enc_key_b64, cipher_value_b64)

      assert XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, []) == {:ok, plaintext}
    end
  end

  describe "failure paths all return :decryption_failed" do
    test "RSA-PKCS1v1.5 key transport returns :decryption_failed", %{pub_key: pub_key} do
      # Any CEK — AlgorithmPolicy gate fires before RSA is attempted
      cek = :crypto.strong_rand_bytes(32)

      enc_key_bytes =
        :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_padding}])

      enc_key_b64 = Base.encode64(enc_key_bytes)

      # Valid AES-256-GCM CipherValue (28+ bytes: IV(12) || CT || Tag(16))
      iv = :crypto.strong_rand_bytes(12)
      tag = :crypto.strong_rand_bytes(16)
      cipher_value_b64 = Base.encode64(iv <> <<0>> <> tag)

      bytes =
        build_encrypted_assertion(@rsa_pkcs1_uri, @aes256_gcm_uri, enc_key_b64, cipher_value_b64)

      assert XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, []) == :decryption_failed
    end

    test "AES-CBC content encryption returns :decryption_failed", %{pub_key: pub_key} do
      cek = :crypto.strong_rand_bytes(32)

      enc_key_bytes =
        :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])

      enc_key_b64 = Base.encode64(enc_key_bytes)

      # 28+ bytes for the CipherValue (content size doesn't matter; gate fires at algorithm check)
      cipher_value_b64 = Base.encode64(:crypto.strong_rand_bytes(32))

      bytes =
        build_encrypted_assertion(@rsa_oaep_uri, @aes256_cbc_uri, enc_key_b64, cipher_value_b64)

      assert XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, []) == :decryption_failed
    end

    test "truncated GCM auth tag (< 16 bytes) returns :decryption_failed", %{pub_key: pub_key} do
      cek = :crypto.strong_rand_bytes(32)

      enc_key_bytes =
        :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])

      enc_key_b64 = Base.encode64(enc_key_bytes)

      # IV(12) || CT(1 byte) || Tag(15 bytes) = 28 bytes total — tag is 1 byte short
      iv = :crypto.strong_rand_bytes(12)
      truncated = iv <> :crypto.strong_rand_bytes(15)
      cipher_value_b64 = Base.encode64(truncated)

      bytes =
        build_encrypted_assertion(
          @rsa_oaep_uri,
          @aes256_gcm_uri,
          enc_key_b64,
          cipher_value_b64
        )

      assert XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, []) == :decryption_failed
    end

    test "malformed ciphertext base64 returns :decryption_failed", %{pub_key: pub_key} do
      cek = :crypto.strong_rand_bytes(32)

      enc_key_bytes =
        :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])

      enc_key_b64 = Base.encode64(enc_key_bytes)

      # Invalid base64 — contains characters outside base64 alphabet
      malformed_cipher_b64 = "not!valid!base64!!!!"

      bytes =
        build_encrypted_assertion(
          @rsa_oaep_uri,
          @aes256_gcm_uri,
          enc_key_b64,
          malformed_cipher_b64
        )

      assert XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, []) == :decryption_failed
    end
  end
end
