defmodule LedgerLoop.UATCoverageTest do
  @moduledoc """
  Machine-readable traceability guard for the Phase 57.1 UAT.

  Phase 57.1's manual UAT (`.planning/phases/57.1-.../57.1-UAT.md`) has six
  checkpoints. Every one is already covered by a named automated test that runs
  in CI via `mix ci.demo_app` (`.github/workflows/demo-app-ci.yml`, OTP 27/28).
  This module is the source of truth binding each UAT checkpoint to its covering
  test, so the "0 human verification" claim cannot silently rot: if a covering
  test is deleted or renamed, this guard fails CI and forces a conscious
  re-verify (restore the test, or update both this manifest and the UAT.md).

  Checkpoint 1 ("demo builds green") has no single covering test — it is the demo
  suite itself. This module executing inside that suite *is* its evidence, so it
  carries no file citations.
  """
  use ExUnit.Case, async: true

  # checkpoint => {label, [{relative_path, exact_test_name}, ...]}
  @uat_coverage [
    {1, "Demo app builds green", []},
    {2, "WR-02 corrected login label",
     [
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "WR-02 renders sarah@northstar.example.com label for valid login"}
     ]},
    {3, "Valid login round-trip succeeds",
     [
       {"test/ledger_loop_web/fake_idp_flow_test.exs",
        "login → fake IdP → ACS verifies → LoginReceipt inserted + redirect /"}
     ]},
    {4, "Tamper path yields typed rejection (WR-05)",
     [
       {"test/ledger_loop_web/fake_idp_flow_test.exs",
        "tampered assertion → no session, digest_mismatch AuditEvent in trace"},
       {"test/ledger_loop/fake_idp/signer_test.exs",
        "tampered response causes Signature.verify/4 to return {:error, %Error{type: :digest_mismatch}}"},
       {"test/ledger_loop/fake_idp/signer_test.exs",
        "WR-05: raises with descriptive message when XML has no matching <NameID>"}
     ]},
    {5, "Hostile input does not crash the FakeIdP (WR-03/WR-04/WR-01/IN-03)",
     [
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "WR-04 oversized SAMLRequest inflating >64 KiB yields nil in_response_to (no crash)"},
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "WR-04 garbled SAMLRequest bytes yield nil in_response_to (fail-closed contract)"},
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "IN-03 SAMLRequest with ID containing '<' (non-NCName) yields nil in_response_to"},
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "IN-03 SAMLRequest with ID containing a space (non-NCName) yields nil in_response_to"},
       {"test/ledger_loop_web/controllers/fake_idp_controller_test.exs",
        "WR-03 unknown idp_action resolves to success path (HTTP 200, SAMLResponse rendered)"},
       {"test/ledger_loop/fake_idp/signer_test.exs",
        "WR-01: signed_response/1 with metacharacter in_response_to returns a binary without crashing"}
     ]},
    {6, "Descriptive PEM decode error (IN-02)",
     [
       {"test/ledger_loop/fake_idp/keypair_test.exs",
        "IN-02: raises a descriptive error on a multi-entry / wrong-shape PEM"}
     ]}
  ]

  @required_checkpoints Enum.to_list(1..6)

  describe "Phase 57.1 UAT coverage" do
    test "every cited covering test still exists in its file" do
      missing =
        for {id, label, citations} <- @uat_coverage,
            {rel_path, test_name} <- citations,
            not test_present?(rel_path, test_name),
            do: {id, label, rel_path, test_name}

      assert missing == [],
             "UAT coverage drift — these checkpoints cite tests that no longer exist:\n" <>
               Enum.map_join(missing, "\n", fn {id, label, path, name} ->
                 "  - checkpoint #{id} (#{label}): #{path} :: test \"#{name}\""
               end) <>
               "\n\nA covering test was deleted or renamed. Restore it, or update both " <>
               "test/uat_coverage_test.exs and the phase 57.1 UAT.md, then re-verify."
    end

    test "all six UAT checkpoints are represented in the manifest" do
      present = @uat_coverage |> Enum.map(fn {id, _label, _citations} -> id end) |> Enum.sort()

      assert present == @required_checkpoints,
             "UAT manifest is missing checkpoints. Expected #{inspect(@required_checkpoints)}, " <>
               "got #{inspect(present)}. A whole checkpoint must not be dropped without re-verify."
    end
  end

  # The demo suite runs with cwd = demo/ledger_loop, so citations are relative
  # to that root. Match the exact `test "<name>"` declaration as a substring;
  # all cited names are free of embedded double quotes (verified at authoring).
  defp test_present?(rel_path, test_name) do
    case File.read(rel_path) do
      {:ok, contents} -> String.contains?(contents, "test \"#{test_name}\"")
      {:error, _} -> false
    end
  end
end
