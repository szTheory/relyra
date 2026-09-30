---
phase: "79"
slug: "adopter-ready-closeout"
status: gaps_found
nyquist_compliant: false
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
| 79-04-T1 | 79-04 | 4 | REPO-03 | T-79-21, T-79-23 | Bind the no-action record to the incomplete protection capture and exact desired/rollback record bytes; reject stale SHA, altered hashes, fabricated rollback payload, and executable write content | contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` | `test/governance/milestone_scope_test.exs` evidence-contract owner | ✅ passed, 155 tests, 0 failures; focused Phase 79 owner passed, 1 test, 0 failures |
| 79-04-T2 | 79-04 | 4 | REPO-01, REPO-02, REPO-03, EXIT-01 | T-79-22, T-79-24 | Reconcile the current governed-source proof and bind this map to the inventory, risk/closeout records, and exact batch evidence while preserving historical Phase 78 scope | provenance | Isolated Phase 75 lifecycle `Relyra.Phase73Reconciliation.capture!/2`, then `mix ci.phase73.reconciliation` | Phase 73 canonical proof and dependent reports | ⏸ blocked: capture-order timing replay measured `mix ci.evidence` vectors 2 and 3 at 82,639 ms and 71,590 ms; each passed 155 tests but exceeded the unchanged 60,000 ms ceiling. No replacement proof was written and the reconciliation replay was not run |

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
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency measured and below 30 seconds for focused checks
- [ ] nyquist_compliant: true set in frontmatter after validation

**Validation owner:** `test/governance/milestone_scope_test.exs`, selected by the mandatory fresh-process `mix ci.evidence` lane.

**Current inventory identity:** `szTheory/relyra@refs/heads/main`, SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`, observed `2026-09-30T16:51:05Z`. All nine mandatory lanes remain absent: `mix qa`, `mix ci.security`, `standalone defenses`, `mix ci.verify`, `mix ci.evidence`, `mix ci.phase73.reconciliation`, `mix ci.package`, `mix ci.ledger_loop`, and `browser defenses`. The readable protection GET is incomplete because it omitted `required_pull_request_reviews` and `restrictions`; the partial contexts do not prove the complete policy or the expected `fleet-proxy-e2e` protection context.

**Phase 79 exact evidence:** the no-action remote record SHA-256 is `1b139566df0d8f3dc336e44e415b032efd542fe08db75a0c9aaa395a785d544c`. The desired configuration reference SHA-256 is `4e2ae3133764813c1c9adf6a90b050561696f78dec7ffae920bd61306eb53f1e`; the rollback record SHA-256 is `3167344226ea9df5aab02fd300860815a4bd7056d78fa0fe1776919800a9355a` and explicitly has no rollback payload. No executable proposal or proposal hash exists. The risk ledger and closeout remain bound to the inventory identity above.

**Current task verification:** `mix ci.evidence` passed with 155 tests and 0 failures after the Task 1 source change (63.9 seconds); additional runs with alternate local scheduler settings also passed but were slower (80.5, 100.4, and 102.5 seconds). The production Phase 73 capture path was run from an isolated snapshot using the Phase 75 planning lifecycle; the live checkout's `STATE.md` and `ROADMAP.md` were not changed. The snapshot had the existing root and LedgerLoop build/dependency caches linked. Capture executed the focused owners, three evidence runs, and pinned security lane, then rejected the candidate at proof validation with `evidence duration must remain below 60000ms`. No candidate proof was atomically written. A prior snapshot attempt lacked LedgerLoop caches and failed its nested-project probe; that harness issue was corrected, and the later attempt reached the duration check.

**Manual recovery record (2026-09-30):** GSD safe-resume found existing 79-04 commits without a `79-04-SUMMARY.md` or async-job manifest. The user selected continuation of Task 2 only. Task 1's committed source and passing evidence are preserved; Task 1 will not be replayed. Task 2 resumes through its declared isolated capture and reconciliation path, and the plan summary remains unwritten until all declared task work and verification pass.

**Task 2 retry result (2026-09-30):** The user-directed retry used the supported `Relyra.Phase73Reconciliation.capture!/2` entry point in a disposable clone, with the Phase 75 planning lifecycle and linked root/LedgerLoop caches. The capture completed its focused selectors, three `mix ci.evidence` subprocesses, and pinned `mix ci.security` subprocess, then rejected the assembled proof at `validate_result!/3` with `evidence duration must remain below 60000ms`. The capture does not report which evidence vector exceeded the ceiling when proof validation rejects it; no run number is claimed for this retry. No candidate was written, and the live Phase 73 proof/reports and Phase 78 receipt remain unchanged. The retry confirms the previously diagnosed runtime-bound failure; Task 2 remains open pending a supported capture whose three evidence vectors all meet the existing limit.

**Duration diagnosis:** The original rejected capture did not preserve its candidate vector, so its exact offending run number is unavailable. A capture-order diagnostic replay then passed all 21 focused selectors and recorded the following `mix ci.evidence` results: run 1, 46,289 ms; run 2, 82,639 ms; run 3, 71,590 ms. Each run exited 0 with 155 tests and 0 failures; runs 2 and 3 exceeded the same strict 60,000 ms gate. Three evidence-only repetitions outside that focused preamble measured 49,167 ms, 53,612 ms, and 59,129 ms. This establishes runtime variability in the required evidence subprocess, not a failing assertion. No selector, security assertion, capture implementation, or duration threshold was changed; those code paths are outside this plan's declared outputs. Task 2 remains blocked until the supported isolated capture completes all three vectors below the existing ceiling and the reconciliation gate passes.

Task 1 is verified, but Task 2 remains open. The checked-in Phase 73 proof is still `phase73-a98cf8e53a4630fb`, captured at `2026-09-30T09:57:51Z` with source digest `sha256:81b5e39017eb02f384b813c5ca64492cc7d8fa8c2227014d32c9ca369f412df6`. Its governed-source entry for `test/governance/milestone_scope_test.exs` is `42702829065804c1aae0e63ddd6d556b39f96445420e646e29804cc940ee5676`; the current file is `80fc865ba82fc63da84076461f71f05ca3b07700f9685bc217f4af0ba7089b04`. Because no valid replacement proof was produced, `mix ci.phase73.reconciliation` was not run and the Phase 73 reports and historical Phase 78 receipt were left unchanged. Do not treat the old proof or Phase 78's OTP 27 cold-matrix receipt as evidence for the current governed source or protected main.

**Prior proof verification (historical):** proof `phase73-a98cf8e53a4630fb` recorded 21 focused owners, three 155-test evidence vectors, and 13 security constituents. Its earlier `mix ci.phase73.reconciliation` pass (1 test, 0 failures, 5 excluded; 637.5 seconds), full test pass (999 tests, 0 failures, 11 excluded; 639.7 seconds), formatting check, inventory verifier, and repository proof validation predate the Task 1 source change above.

**Open evidence gaps:** the current main-SHA inventory has no passing evidence for its nine mandatory lanes; the protection resource and exact rollback remain incomplete; two Phase 76 concurrency windows remain unautomated; and this plan's governed-source recapture is still open under the strict duration bound. Release remains blocked. No human review substitutes for these deterministic or live postconditions.

**Approval:** not applicable; this is an automated validation map, not a human acceptance gate.
