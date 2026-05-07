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
end
