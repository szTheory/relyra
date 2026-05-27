defmodule Relyra.Security.SignatureTest do
  @moduledoc """
  Phase 21 (W2 / Plan 21-04) — `verify_metadata_root/4` shim coverage.

  The shim reuses `do_verify/4` verbatim and differs from `verify/4` ONLY
  in the `:flow` telemetry tag (`:metadata_refresh` vs `:sp_initiated`).
  These tests confirm:

  1. Document-KeyInfo / empty-cert-chain / duplicate-XML-ID rejections all
     apply to the metadata-root path because they live in the shared
     `do_verify/4` (D-16).
  2. The telemetry namespace is `[:relyra, :saml, :signature, :verify, ...]`
     for both paths, but the `metadata.flow` tag is the discriminator.

  Existing assertion-signature coverage lives in
  `test/security/signature_policy_test.exs` and
  `test/security/signed_node_binding_test.exs` — those continue to gate the
  `flow: :sp_initiated` path. This file is the Phase-21-specific home for
  the metadata-root path.
  """
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.Signature

  describe "verify_metadata_root/4 trust rejections (shared with verify/4 via do_verify/4)" do
    test "rejects when cert_chain is empty (D-17 — no pinned fingerprints == reject)" do
      parsed_doc = %{signed_candidates: []}
      connection = %{connection_id: "conn-1"}

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify_metadata_root(parsed_doc, connection, [])
    end

    test "rejects document-provided KeyInfo (mirrors verify/4 behavior)" do
      parsed_doc = %{key_info_trust: true, signed_candidates: []}
      connection = %{connection_id: "conn-2"}

      assert {:error,
              %Error{
                type: :untrusted_certificate,
                details: %{reason: :document_keyinfo_forbidden}
              }} =
               Signature.verify_metadata_root(parsed_doc, connection, [
                 "-----BEGIN CERTIFICATE-----\nA\n-----END CERTIFICATE-----"
               ])
    end

    test "rejects duplicate XML IDs" do
      parsed_doc = %{duplicate_ids: ["foo", "bar"], signed_candidates: []}
      connection = %{connection_id: "conn-3"}

      assert {:error, %Error{type: :duplicate_xml_id}} =
               Signature.verify_metadata_root(parsed_doc, connection, [
                 "-----BEGIN CERTIFICATE-----\nB\n-----END CERTIFICATE-----"
               ])
    end
  end

  describe "verify_metadata_root/4 telemetry flow tag" do
    setup [:attach_signature_telemetry]

    test "emits telemetry under [:relyra, :saml, :signature, :verify, ...] with flow: :metadata_refresh" do
      parsed_doc = %{signed_candidates: []}
      connection = %{connection_id: "conn-mr"}

      Signature.verify_metadata_root(parsed_doc, connection, [])

      assert_receive {:signature_telemetry, [:relyra, :saml, :signature, :verify, :start],
                      _measurements, %{flow: :metadata_refresh, connection_id: "conn-mr"}}

      assert_receive {:signature_telemetry, [:relyra, :saml, :signature, :verify, :stop],
                      _measurements, %{flow: :metadata_refresh, outcome: :error}}
    end

    test "verify/4 telemetry still emits flow: :sp_initiated (no regression)" do
      parsed_doc = %{signed_candidates: []}
      connection = %{connection_id: "conn-sp"}

      Signature.verify(parsed_doc, connection, [])

      assert_receive {:signature_telemetry, [:relyra, :saml, :signature, :verify, :start],
                      _measurements, %{flow: :sp_initiated, connection_id: "conn-sp"}}

      refute_received {:signature_telemetry, [:relyra, :saml, :signature, :verify, :start],
                       _measurements, %{flow: :metadata_refresh}}
    end
  end

  describe "sign_redirect_query/3 (Phase 35 AUTHN-01)" do
    test "signs raw octets verbatim and returns URL-encoded base64 signature" do
      Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
      on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

      octets =
        "SAMLRequest=abc%2B123&RelayState=return%2Fto&SigAlg=http%3A%2F%2Fwww.w3.org%2F2001%2F04%2Fxmldsig-more%23rsa-sha256"

      assert {:ok, sig} =
               Signature.sign_redirect_query(
                 octets,
                 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
               )

      assert is_binary(sig)
      refute String.contains?(sig, "+")
      assert URI.decode_www_form(sig) |> Base.decode64!() |> is_binary()
    end

    test "returns :key_not_configured when :sp_signing_key_pem is unset" do
      Application.delete_env(:relyra, :sp_signing_key_pem)

      assert {:error, %Error{type: :key_not_configured}} =
               Signature.sign_redirect_query(
                 "SAMLRequest=x",
                 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
               )
    end

    test "returns :unsupported_signing_algorithm for ECDSA URI" do
      Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
      on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

      assert {:error, %Error{type: :unsupported_signing_algorithm}} =
               Signature.sign_redirect_query(
                 "SAMLRequest=x",
                 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"
               )
    end

    test "returns :unknown_signing_algorithm for unknown URI" do
      Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
      on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

      assert {:error, %Error{type: :unknown_signing_algorithm}} =
               Signature.sign_redirect_query("SAMLRequest=x", "urn:bogus")
    end

    test "signs different octets differently even when they decode to the same logical params" do
      pem = fixture_pem()
      signature_method = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      octets_a = "SAMLRequest=abc%2B123&SigAlg=http%3A%2F%2Fexample.com%2Frsa-sha256"
      octets_b = "SAMLRequest=abc+123&SigAlg=http%3A%2F%2Fexample.com%2Frsa-sha256"

      assert {:ok, sig_a} =
               Signature.sign_redirect_query(octets_a, signature_method, signing_key_pem: pem)

      assert {:ok, sig_b} =
               Signature.sign_redirect_query(octets_b, signature_method, signing_key_pem: pem)

      refute sig_a == sig_b
    end
  end

  defp attach_signature_telemetry(_context) do
    test_pid = self()
    handler_id = "phase21-signature-test-#{System.unique_integer([:positive])}"

    events = [
      [:relyra, :saml, :signature, :verify, :start],
      [:relyra, :saml, :signature, :verify, :stop],
      [:relyra, :saml, :signature, :verify, :exception]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:signature_telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  defp fixture_pem do
    File.read!(
      Path.join([__DIR__, "../../fixtures/security/authn_request_signing/golden_signing_key.pem"])
    )
  end
end
