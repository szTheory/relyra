defmodule Relyra.Security.SignatureTest do
  @moduledoc """
  Wave 0 stub for `Relyra.Security.Signature` metadata-root extension
  (Phase 21 W2 — `21-04-audit-seam-extension`).

  This file exists so PLAN files can reference an `<automated>` verify command
  pointing at this path from day one. The corresponding production extension
  (a `verify_metadata_root/4` shim or equivalent) will be added in Wave 2
  (`21-04`); see
  `.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md` Per-Task
  Verification Map for the wave assignment.

  Note: existing assertion-signature coverage lives in
  `test/security/signature_policy_test.exs` and `test/security/signed_node_binding_test.exs`;
  this file is the Phase-21-specific test home for the metadata-root path.
  """
  use ExUnit.Case, async: true

  @moduletag :pending

  @tag :pending
  test "Wave 0 stub: replaced by Wave 2 task in Phase 21" do
    flunk("Wave 0 stub — implement in the wave that introduces the metadata-root verifier")
  end
end
