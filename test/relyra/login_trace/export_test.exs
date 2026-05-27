defmodule Relyra.LoginTrace.ExportTest do
  use ExUnit.Case, async: true

  alias Relyra.Diagnostic.AllowList
  alias Relyra.LoginTrace.Export

  describe "export_step/1" do
    test "keeps safe fields and drops sensitive keys" do
      step = %{
        "outcome" => "ok",
        "error_code" => nil,
        "duration_ms" => 12,
        "response_xml" => "<samlp:Response>...</samlp:Response>"
      }

      assert Export.export_step(step) == %{
               "outcome" => "ok",
               "duration_ms" => 12
             }
    end

    test "redacts PEM material in values" do
      step = %{
        "outcome" => "error",
        "error_code" => "invalid_signature",
        "details" => "-----BEGIN CERTIFICATE-----\nMIIB..."
      }

      assert Export.export_step(step) == %{
               "outcome" => "error",
               "error_code" => "invalid_signature"
             }
    end

    test "redacts forbidden SAML/XML substrings in allowed attribute summaries" do
      step = %{
        "outcome" => "ok",
        "attributes" => %{"email" => "user@example.com", "note" => "<saml:Assertion>secret</saml:Assertion>"}
      }

      exported = Export.export_step(step)

      assert exported["attributes"]["email"] == "user@example.com"
      assert exported["attributes"]["note"] == "[REDACTED]"
    end
  end

  describe "export_login/1" do
    test "hashes correlation_id and exports ordered steps" do
      raw_correlation = "corr-user-session-abc123"

      event = %{
        id: "evt-1",
        domain: :login,
        action: :succeeded,
        actor: "system:login_trace",
        cause: "sp_initiated",
        correlation_id: raw_correlation,
        inserted_at: ~U[2026-05-27 12:00:00Z],
        after_summary: %{
          "steps" => %{
            "response.decode" => %{"outcome" => "ok", "duration_ms" => 5},
            "signature.verify" => %{"outcome" => "ok", "duration_ms" => 8}
          },
          "overall_outcome" => "ok"
        }
      }

      exported = Export.export_login(event)

      assert exported.id == "evt-1"
      assert exported.action == :succeeded
      assert exported.cause == "sp_initiated"
      refute Map.has_key?(exported, :actor)
      refute Map.has_key?(exported, "actor")
      assert exported.correlation_id == AllowList.hash_correlation_id(raw_correlation)
      assert exported.correlation_id != raw_correlation

      assert exported.steps == [
               %{"step" => "response.decode", "outcome" => "ok", "duration_ms" => 5},
               %{"step" => "signature.verify", "outcome" => "ok", "duration_ms" => 8}
             ]
    end

    test "scrubs response_xml from nested step maps" do
      event = %{
        id: "evt-2",
        domain: :login,
        action: :failed,
        cause: "sp_initiated",
        correlation_id: "corr-2",
        inserted_at: ~U[2026-05-27 12:01:00Z],
        after_summary: %{
          "steps" => %{
            "response.validate" => %{
              "outcome" => "error",
              "error_code" => "invalid_signature",
              "response_xml" => "<samlp:Response>raw</samlp:Response>"
            }
          }
        }
      }

      exported = Export.export_login(event)

      step = Enum.find(exported.steps, &(&1["step"] == "response.validate"))
      refute Map.has_key?(step, "response_xml")
      assert step["outcome"] == "error"
      assert step["error_code"] == "invalid_signature"
    end
  end
end
