defmodule LedgerLoop.FakeIdP.KeypairTest do
  use ExUnit.Case, async: true

  alias LedgerLoop.FakeIdP.Keypair

  describe "private_key/0" do
    test "returns an RSAPrivateKey tuple" do
      key = Keypair.private_key()
      assert is_tuple(key)
      assert elem(key, 0) == :RSAPrivateKey
    end

    test "returns the same key on repeated calls (cached)" do
      key1 = Keypair.private_key()
      key2 = Keypair.private_key()
      assert key1 == key2
    end
  end

  describe "cert_pem/0" do
    test "returns the literal PEM string from priv/fake_idp/idp_cert.pem" do
      pem = Keypair.cert_pem()
      assert is_binary(pem)
      assert String.contains?(pem, "BEGIN CERTIFICATE")
      assert String.contains?(pem, "END CERTIFICATE")
    end

    test "PEM decodes to a single Certificate entry" do
      pem = Keypair.cert_pem()
      entries = :public_key.pem_decode(pem)
      assert length(entries) == 1
      [{:Certificate, _der, :not_encrypted}] = entries
    end

    test "returns the exact bytes of the committed cert file" do
      pem = Keypair.cert_pem()
      cert_path = Application.app_dir(:ledger_loop, "priv/fake_idp/idp_cert.pem")
      assert pem == File.read!(cert_path)
    end
  end

  describe "key<->cert pairing" do
    test "private key corresponds to the cert's SubjectPublicKeyInfo (sign/verify round-trip)" do
      priv_key = Keypair.private_key()
      pem = Keypair.cert_pem()

      [{:Certificate, cert_der, :not_encrypted}] = :public_key.pem_decode(pem)

      # Decode cert and extract the public key (OTP tuple shape: {:OTPCertificate, tbs_cert, ...})
      {:OTPCertificate, tbs_cert, _sig_alg, _sig} =
        :public_key.pkix_decode_cert(cert_der, :otp)

      # tbs_cert: {:OTPTBSCertificate, ..., spki, ...} — spki is element at index 7
      {:OTPTBSCertificate, _v, _serial, _sig_alg2, _issuer, _validity, _subject, spki, _exts,
       _uids, _ext_list} = tbs_cert

      # spki: {:OTPSubjectPublicKeyInfo, alg, pub_key}
      {:OTPSubjectPublicKeyInfo, _alg, rsa_pub_key} = spki

      data = "round-trip test data for FakeIdP keypair"

      # Sign with the demo private key
      signature = :public_key.sign(data, :sha256, priv_key)

      # Verify with the cert's public key — proves key ↔ cert pairing
      assert :public_key.verify(data, :sha256, signature, rsa_pub_key)
    end
  end
end
