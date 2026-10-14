defmodule Relyra.Governance.Phase79PlanHandoffTest do
  # Depends on a local GSD install, so it lives outside the evidence_contract
  # module: the Phase 73 proof replays ci.evidence summaries byte-for-byte, and
  # a host-dependent skip would make that lane differ between machines.
  use ExUnit.Case, async: true

  @tag :phase79_plan_handoff
  @tag Relyra.TestGsdTools.test_tags()
  test "Phase 79 filtered-history plan handoff keeps the reviewed wave order" do
    script = Path.expand("../../scripts/verify_phase79_plan_contract.py", __DIR__)

    assert {output, 0} = System.cmd("python3", [script, "--handoff"], stderr_to_stdout: true)
    assert output =~ "handoff"
  end
end
