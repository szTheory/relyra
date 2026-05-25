defmodule Relyra.Protocol.MetadataTest do
  use ExUnit.Case, async: false

  alias Relyra.Protocol.Metadata

  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"

  # SC#4: configure two DISTINCT real PEM certs as the SP public signing + encryption
  # certs. The certs MAY differ (the requirement is distinct KeyDescriptor ELEMENTS,
  # not distinct cert bytes) — generating two fresh self-signed certs gives both.
  setup do
    signing_pem = real_cert_pem(~c"CN=relyra-sp-signing")
    encryption_pem = real_cert_pem(~c"CN=relyra-sp-encryption")

    Application.put_env(:relyra, :sp_signing_cert_pem, signing_pem)
    Application.put_env(:relyra, :sp_encryption_cert_pem, encryption_pem)

    on_exit(fn ->
      Application.delete_env(:relyra, :sp_signing_cert_pem)
      Application.delete_env(:relyra, :sp_encryption_cert_pem)
    end)

    {:ok, signing_pem: signing_pem, encryption_pem: encryption_pem}
  end

  describe "build_sp_metadata/2 KeyDescriptors (SC#4)" do
    test "emits both a signing and an encryption KeyDescriptor" do
      xml = Metadata.build_sp_metadata(connection())

      assert String.contains?(xml, ~s(use="signing"))
      assert String.contains?(xml, ~s(use="encryption"))
    end

    test "signing descriptor precedes encryption descriptor, both precede ACS" do
      xml = Metadata.build_sp_metadata(connection())

      signing_at = index_of!(xml, ~s(use="signing"))
      encryption_at = index_of!(xml, ~s(use="encryption"))
      acs_at = index_of!(xml, "<md:AssertionConsumerService")

      # T-34-02: schema-valid SPSSODescriptor child order — KeyDescriptor [0..*]
      # before AssertionConsumerService [1..*]; signing before encryption.
      assert signing_at < encryption_at
      assert encryption_at < acs_at
    end

    test "each KeyDescriptor carries a KeyInfo/X509Data/X509Certificate chain" do
      xml = Metadata.build_sp_metadata(connection())

      assert String.contains?(xml, "<ds:KeyInfo")
      assert String.contains?(xml, "<ds:X509Data>")
      assert String.contains?(xml, "<ds:X509Certificate>")
    end

    test "X509Certificate body is base64-of-DER: no PEM armor, no embedded newline" do
      xml = Metadata.build_sp_metadata(connection())

      for body <- x509_cert_bodies(xml) do
        assert body != ""
        refute String.contains?(body, "-----BEGIN")
        refute String.contains?(body, "-----END")
        refute String.contains?(body, "\n")
        # Round-trips as base64-of-DER (a parseable certificate).
        assert {:ok, der} = Base.decode64(body)
        assert is_binary(der) and byte_size(der) > 0
      end
    end

    test "KeyInfo precedes EncryptionMethod inside the encryption descriptor" do
      xml = Metadata.build_sp_metadata(connection())

      enc_block = encryption_descriptor_block(xml)
      keyinfo_at = index_of!(enc_block, "<ds:KeyInfo")
      enc_method_at = index_of!(enc_block, "<md:EncryptionMethod")

      assert keyinfo_at < enc_method_at
    end

    test "encryption descriptor advertises the xmlenc# aes256-gcm accept-list URI" do
      xml = Metadata.build_sp_metadata(connection())

      assert String.contains?(xml, @aes256_gcm_uri)
      # The decryptor accept-list, not the later-spec OAEP menu.
      refute String.contains?(xml, "xmlenc11#")
    end
  end

  describe "build_sp_metadata/2 with absent cert config" do
    test "does not raise and returns well-formed XML when both cert keys are absent" do
      Application.delete_env(:relyra, :sp_signing_cert_pem)
      Application.delete_env(:relyra, :sp_encryption_cert_pem)

      xml = Metadata.build_sp_metadata(connection())

      assert is_binary(xml)
      # Descriptors are still emitted (D-05 unconditional signing), just with empty bodies.
      assert String.contains?(xml, ~s(use="signing"))
      assert String.contains?(xml, ~s(use="encryption"))
      assert String.contains?(xml, "<ds:X509Certificate></ds:X509Certificate>")
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp connection do
    %{sp_entity_id: "https://sp.example.com/saml", acs_url: "https://sp.example.com/saml/acs"}
  end

  # Two DISTINCT real self-signed cert PEMs (fresh keypair per call).
  defp real_cert_pem(common_name) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    %{cert: der} = :public_key.pkix_test_root_cert(common_name, key: key)
    :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
  end

  defp index_of!(haystack, needle) do
    case :binary.match(haystack, needle) do
      {start, _len} -> start
      :nomatch -> flunk("expected to find #{inspect(needle)} in metadata XML")
    end
  end

  # Extract the text between every <ds:X509Certificate> and </ds:X509Certificate>.
  defp x509_cert_bodies(xml) do
    ~r|<ds:X509Certificate>(.*?)</ds:X509Certificate>|s
    |> Regex.scan(xml, capture: :all_but_first)
    |> Enum.map(fn [body] -> body end)
  end

  # The <md:KeyDescriptor use="encryption"> ... </md:KeyDescriptor> slice.
  defp encryption_descriptor_block(xml) do
    [_before, rest] = String.split(xml, ~s(use="encryption"), parts: 2)
    [block, _after] = String.split(rest, "</md:KeyDescriptor>", parts: 2)
    block
  end
end
