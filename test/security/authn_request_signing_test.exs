defmodule Relyra.Security.AuthnRequestSigningTest do
  @moduledoc """
  Phase 35 (AUTHN-01) — adversarial corpus for HTTP-Redirect-binding AuthnRequest signing.
  """
  use ExUnit.Case, async: true

  @moduletag :authn_request_signing

  alias Relyra.Security.Signature
  alias Relyra.Protocol.Binding

  @golden_xml_path "test/fixtures/security/authn_request_signing/golden_authnrequest.xml"
  @golden_redirect_path "test/fixtures/security/authn_request_signing/golden_redirect.txt"
  @golden_redirect_adfs_path "test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt"
  @golden_key_path "test/fixtures/security/authn_request_signing/golden_signing_key.pem"
  @golden_relay_state "rs_relyra_phase35_golden"
  @signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"

  setup do
    pem = File.read!(@golden_key_path)
    Application.put_env(:relyra, :sp_signing_key_pem, pem)
    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)
    Relyra.RequestStore.ETS.ensure_table!()
    :ok
  end

  describe "row 1 - golden positive control (:rfc3986_upper)" do
    @tag :row_golden
    test "Binding.encode_redirect/3 produces the committed golden bytes" do
      expected = File.read!(@golden_redirect_path)

      assert {:ok, %{redirect_query: actual}} = binding_signed_query(:rfc3986_upper)
      assert actual == expected
    end
  end

  describe "row 2 - adfs lowercase variant" do
    @tag :row_adfs_lower
    test "Binding.encode_redirect/3 produces the committed ADFS-lower golden bytes" do
      expected = File.read!(@golden_redirect_adfs_path)

      assert {:ok, %{redirect_query: actual}} = binding_signed_query(:adfs_lower)
      assert actual == expected
    end
  end

  describe "row 3 - reserialization regression" do
    @tag :row_reserialization_regression
    test "URI.encode_query/1 mutation changes the signature" do
      {:ok, %{redirect_query: golden_query}} = binding_signed_query(:rfc3986_upper)
      {octets, golden_signature} = split_signed_query(golden_query)
      mutated_octets = URI.encode_query(URI.decode_query(octets))

      assert {:ok, mutated_signature} =
               Signature.sign_redirect_query(mutated_octets, @signature_method,
                 signing_key_pem: File.read!(@golden_key_path)
               )

      refute mutated_octets == octets
      refute mutated_signature == golden_signature
    end
  end

  describe "row 4 - round-trip verify" do
    @tag :row_roundtrip_verify
    test "public_key.verify/4 succeeds on the committed golden bytes" do
      {:ok, %{redirect_query: golden_query}} = binding_signed_query(:rfc3986_upper)
      {octets, signature_url_encoded} = split_signed_query(golden_query)
      signature = signature_url_encoded |> URI.decode_www_form() |> Base.decode64!()

      assert :public_key.verify(octets, :sha256, signature, public_key_from_pem()) == true
    end
  end

  describe "row 5 - toggle-off no-op (sign_authn_requests: false)" do
    @tag :row_toggle_off_noop
    test "start_login emits no SigAlg / Signature keys" do
      assert {:ok, %{redirect_params: params, authn_request: _, request_id: _, relay_state: _}} =
               Relyra.start_login(connection_unsigned(), %{return_to: "/"}, unsigned_opts())

      refute Map.has_key?(params, "SigAlg")
      refute Map.has_key?(params, "Signature")
      refute Map.has_key?(params, :redirect_query)
    end
  end

  defp binding_signed_query(encoding) do
    Binding.encode_redirect(File.read!(@golden_xml_path), @golden_relay_state,
      sign: true,
      signature_method: @signature_method,
      encoding: encoding,
      signing_key_pem: File.read!(@golden_key_path),
      connection_id: "golden-fixture"
    )
  end

  defp split_signed_query(query) do
    [octets, signature] = String.split(query, "&Signature=", parts: 2)
    {octets, signature}
  end

  defp public_key_from_pem do
    pem = File.read!(@golden_key_path)
    [entry] = :public_key.pem_decode(pem)
    private_key = :public_key.pem_entry_decode(entry)
    {:RSAPrivateKey, _, modulus, public_exponent, _, _, _, _, _, _, _} = private_key
    {:RSAPublicKey, modulus, public_exponent}
  end

  defp connection_unsigned do
    %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      sign_authn_requests: false
    }
  end

  defp unsigned_opts do
    [request_store: Relyra.RequestStore.ETS, now: ~U[2026-05-26 00:00:00Z]]
  end
end
