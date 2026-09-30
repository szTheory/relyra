---
phase: "79"
slug: "adopter-ready-closeout"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 79-02-T3 | 79-02 | 2 | REPO-02, REPO-03, EXIT-01 | T-79-06, T-79-07, T-79-09 | Refresh source identity after local commits; keep incomplete main evidence and any changed proposal visibly blocked | contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` | Inventory collector and risk/closeout governance owner | ⬜ pending |

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

- [ ] All tasks have automated verification or an explicit Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and below 30 seconds for focused checks
- [ ] nyquist_compliant: true set in frontmatter after validation

**Validation owner:** `test/governance/milestone_scope_test.exs`, selected by the mandatory fresh-process `mix ci.evidence` lane.

**Open evidence gaps:** the current main-SHA inventory has no passing evidence for its nine mandatory lanes, and two Phase 76 concurrency windows remain unautomated. Both remain explicit closeout risks; neither is accepted through manual review or converted into a green release claim.

**Approval:** not applicable; this is an automated validation map, not a human acceptance gate.
