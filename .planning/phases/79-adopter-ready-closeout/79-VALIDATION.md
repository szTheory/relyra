---
phase: "79"
slug: "adopter-ready-closeout"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-29"
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | mix.exs; .github/workflows/security-gates.yml |
| **Quick run command** | `mix ci.evidence` |
| **Full suite command** | mix qa; mix test --warnings-as-errors; mix ci.security; mix format --check-formatted |
| **Estimated runtime** | Re-measure in the active Phase 79 CI run; not established by current Phase 78 evidence |

---

## Sampling Rate

- **After every task commit:** Run mix ci.evidence when changing governance, inventory, or evidence contracts.
- **After every plan wave:** Run mix ci.evidence and the wave's focused checks.
- **Before $gsd-verify-work:** Required CI on current main must be inspected against its live SHA; run the full required local suite for any source changes that the active plan sends toward main.
- **Max feedback latency:** Use the current CI measurement; no Phase 79 duration baseline exists yet.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-02-T1 | 79-02 | 2 | REPO-01, EXIT-01 | T-79-08, T-79-09 | Bind closeout risks to inventory; require every Phase 73 finding, STATE deferred item, and open WINDOWS item with owner, evidence, severity, disposition, and revisit | contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | `test/governance/milestone_scope_test.exs` risk-ledger owner | ✅ passed, 87 tests, 0 failures |
| 79-02-T2 | 79-02 | 2 | REPO-03, EXIT-01 | T-79-06, T-79-07, T-79-08 | Keep no-action records inert; bind proposed payload, approval, rollback, immediate preflight, and automated read-back to one target | contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` | `test/governance/milestone_scope_test.exs` risk/remote contract owner | ✅ passed, 155 tests, 0 failures |
| 79-02-T3 | 79-02 | 2 | REPO-02, REPO-03, EXIT-01 | T-79-06, T-79-07, T-79-09 | Bind all five closeout outputs to the refreshed inventory identity; classify scoped tracked edits as Phase 79-owned with no cleanup authority; preserve unknown paths and keep incomplete main evidence blocked | contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` | Inventory collector and governance assertions for artifact identity and tracked-edit ownership | ✅ passed, 155 tests, 0 failures |

---

## Wave 0 Requirements

- [x] Inspect current REPO-01/02/03 and EXIT-01 coverage in test/governance/milestone_scope_test.exs; add deterministic fixtures only for gaps in the chosen Phase 79 report contract.
- [x] Keep new contract checks in the existing mandatory `mix ci.evidence` lane.
- [x] Do not probe shared GitHub credentials or current state as part of local fixtures; refresh live state only through the active plan's read-only inventory task.

---

## External Evidence Boundaries

All acceptance behavior is checked by deterministic automation. The inventory collector records live GitHub observations as timestamped source evidence; they are not substituted by manual review or used as acceptance. A future explicit approval could authorize one separately planned write, while same-target preflight and automated read-back would prove its postcondition. No write is performed by this phase.

---

## Validation Sign-Off

- [x] All tasks have automated verification or an explicit Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency measured and below 30 seconds for focused checks
- [x] nyquist_compliant: true set in frontmatter after validation

**Validation owner:** `test/governance/milestone_scope_test.exs`, selected by the mandatory fresh-process `mix ci.evidence` lane.

**Open evidence gaps:** the current main-SHA inventory has no passing evidence for its nine mandatory lanes, and two Phase 76 concurrency windows remain unautomated. Both remain explicit closeout risks; neither is accepted through manual review or converted into a green release claim.

**Sampling observation:** the focused collector fixture completed in 2.7 seconds. Three current `mix ci.evidence` vectors completed 155 tests each in 44.451, 44.117, and 46.072 seconds; this broader lane exceeds the 30-second target, while focused checks remain below it.

**Final review verification:** proof `phase73-a98cf8e53a4630fb` was captured at `2026-09-30T09:57:51Z` with source digest `sha256:81b5e39017eb02f384b813c5ca64492cc7d8fa8c2227014d32c9ca369f412df6`. It records 21 focused owners, three 155-test evidence vectors, and 13 security constituents. `mix ci.phase73.reconciliation` passed (1 test, 0 failures, 5 excluded; 637.5 seconds), and `mix test --warnings-as-errors` passed (999 tests, 0 failures, 11 excluded; 639.7 seconds). `mix format --check-formatted`, `git diff --check`, the Phase 79 inventory verifier, and the Phase 73 repository proof validator passed. Each lifecycle wrapper restored the exact original `STATE.md` bytes.

**Approval:** not applicable; this is an automated validation map, not a human acceptance gate.
