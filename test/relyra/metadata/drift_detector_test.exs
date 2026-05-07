defmodule Relyra.Metadata.DriftDetectorTest do
  use ExUnit.Case, async: true
  alias Relyra.Metadata.DriftDetector

  describe "diff/2 — no drift" do
    test "returns {:ok, :no_drift} when entityID and fingerprint set match exactly" do
      candidate = %{
        idp_entity_id: "https://idp.example/",
        certificate_fingerprints: ["aaa", "bbb"]
      }

      state = %{
        idp_entity_id: "https://idp.example/",
        last_known_metadata_signing_certs: ["aaa", "bbb"]
      }

      assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
    end

    test "returns {:ok, :no_drift} when candidate fingerprints are a SUBSET of known (cert was retired upstream — not drift)" do
      candidate = %{
        idp_entity_id: "https://idp.example/",
        certificate_fingerprints: ["aaa"]
      }

      state = %{
        idp_entity_id: "https://idp.example/",
        last_known_metadata_signing_certs: ["aaa", "bbb"]
      }

      assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
    end

    test "returns {:ok, :no_drift} on first-ever fetch (known set empty — initialization, not drift)" do
      candidate = %{
        idp_entity_id: "https://idp.example/",
        certificate_fingerprints: ["aaa"]
      }

      state = %{
        idp_entity_id: "https://idp.example/",
        last_known_metadata_signing_certs: []
      }

      assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
    end
  end

  describe "diff/2 — entity_id drift" do
    test "returns {:drift, reason: :entity_id_drift} when entityID changes" do
      candidate = %{
        idp_entity_id: "https://NEW.example/",
        certificate_fingerprints: ["aaa"]
      }

      state = %{
        idp_entity_id: "https://OLD.example/",
        last_known_metadata_signing_certs: ["aaa"]
      }

      assert {:drift, %{reason: :entity_id_drift, entity_id_changed?: true}} =
               DriftDetector.diff(candidate, state)
    end

    test "entity_id_drift takes precedence over new_signing_cert" do
      candidate = %{
        idp_entity_id: "https://NEW.example/",
        certificate_fingerprints: ["zzz"]
      }

      state = %{
        idp_entity_id: "https://OLD.example/",
        last_known_metadata_signing_certs: ["aaa"]
      }

      assert {:drift, %{reason: :entity_id_drift, new_signing_certs: ["zzz"]}} =
               DriftDetector.diff(candidate, state)
    end
  end

  describe "diff/2 — new signing cert" do
    test "returns {:drift, reason: :new_signing_cert} when fingerprint set adds a NEW entry" do
      candidate = %{
        idp_entity_id: "https://idp.example/",
        certificate_fingerprints: ["aaa", "bbb", "ccc"]
      }

      state = %{
        idp_entity_id: "https://idp.example/",
        last_known_metadata_signing_certs: ["aaa", "bbb"]
      }

      assert {:drift, %{reason: :new_signing_cert, new_signing_certs: new}} =
               DriftDetector.diff(candidate, state)

      assert "ccc" in new
    end
  end

  describe "diff/2 — fingerprint-only comparison (Pitfall 7)" do
    test "is order-insensitive (uses MapSet semantics)" do
      candidate = %{idp_entity_id: "https://idp/", certificate_fingerprints: ["bbb", "aaa"]}

      state = %{
        idp_entity_id: "https://idp/",
        last_known_metadata_signing_certs: ["aaa", "bbb"]
      }

      assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
    end
  end
end
