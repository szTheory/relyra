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
| 79-04-T2 | 79-04 | 4 | REPO-01, REPO-02, REPO-03, EXIT-01 | T-79-22, T-79-24 | Reconcile the current governed-source proof and bind this map to the inventory, risk/closeout records, and exact batch evidence while preserving historical Phase 78 scope | provenance | Isolated Phase 75 lifecycle `Relyra.Phase73Reconciliation.capture!/2`, `mix ci.phase73.reconciliation`, and `mix ci.evidence` | Phase 73 canonical proof and dependent reports | ✅ passed: proof `phase73-4f82a31b5b86c7b5`; 3 evidence vectors under 60,000 ms; reconciliation 1 test, 0 failures; evidence 155 tests, 0 failures |

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

**Current inventory identity:** `szTheory/relyra@refs/heads/main`, SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`, observed `2026-10-01T01:51:05Z`. All nine mandatory lanes remain absent on this SHA. The parent protection response omits `required_pull_request_reviews` and `restrictions`; supplemental REST and same-ref GraphQL evidence conflict on the required approval count. The composite capture is incomplete and contains no resource.

**Phase 79 protection capture:** `6a66b5df7f1e7e9010aa2a095b15d376a625f2be14b456ad5b6617e0b70c48fa` file SHA-256; source digest `86cd985a122acd911db7aa13c10894ce1f9db50912af43b108c8d227ddfde777`. REST reports approval count `1`; GraphQL reports `requiredApprovingReviewCount=None` and `requiresApprovingReviews=false`. The desired and rollback records contain no payload. The no-action batch hash and record hashes are bound in `79-REMOTE-BATCH.md`; no approval or remote operation is prepared.

**Prior capture attempts (before the successful lower-load retry):** `mix ci.evidence` passed with 155 tests and 0 failures after the Task 1 source change (63.9 seconds); additional runs with alternate local scheduler settings also passed but were slower (80.5, 100.4, and 102.5 seconds). Earlier supported Phase 73 capture attempts in isolated Phase 75 snapshots reached proof validation but rejected a candidate at `evidence duration must remain below 60000ms`. The live checkout's `STATE.md` and `ROADMAP.md` were not changed. The successful snapshot had the existing root and LedgerLoop build/dependency caches linked. A prior snapshot attempt lacked LedgerLoop caches and failed its nested-project probe; that harness issue was corrected before the successful capture.

**Manual recovery record (2026-09-30):** GSD safe-resume found existing 79-04 commits without a `79-04-SUMMARY.md` or async-job manifest. The user selected continuation of Task 2 only. Task 1's committed source and passing evidence are preserved; Task 1 was not replayed. Task 2 resumed through its declared isolated capture and reconciliation path. The plan summary remains unwritten until the remaining plan closeout work is complete.

**Task 2 initial retry result (2026-09-30):** The user-directed retry used the supported `Relyra.Phase73Reconciliation.capture!/2` entry point in a disposable clone, with the Phase 75 planning lifecycle and linked root/LedgerLoop caches. The capture completed its focused selectors, three `mix ci.evidence` subprocesses, and pinned `mix ci.security` subprocess, then rejected the assembled proof at `validate_result!/3` with `evidence duration must remain below 60000ms`. The capture does not report which evidence vector exceeded the ceiling when proof validation rejects it; no run number is claimed for this retry. No candidate was written, and the live Phase 73 proof/reports and Phase 78 receipt remained unchanged at that point.

**Task 2 successful lower-load capture (2026-09-30):** A later retry started when host load was 4.65 (15-minute average 8.01), compared with about 10 during the rejected retry. The supported Phase 75 snapshot capture passed all 21 focused selectors, all 13 pinned security constituents, and all three `mix ci.evidence` vectors: 56,809 ms, 58,441 ms, and 54,252 ms; each vector had 155 tests and 0 failures. Proof `phase73-4f82a31b5b86c7b5` was captured at `2026-09-30T21:23:26Z`, source digest `sha256:63faf8fae6b694c1f0b535c7e9d0ca51c269e371a91cd5368c7b5e6770dac97f`, proof file SHA-256 `16672eddb7a128520c57b2764d1e4dc5511fb7e480b609bee2e576b79c81a9dc`. The candidate's security lane passed 71 tests, 0 failures. The fresh `mix ci.phase73.reconciliation` replay passed 1 test, 0 failures (5 excluded; 551.5 seconds), and standalone `mix ci.evidence` passed 155 tests, 0 failures in the isolated snapshot (51.2 seconds). After promoting the canonical proof, report blocks, and dependent Phase 78 proof identity fields, repository validation passed and the live `mix ci.evidence` lane passed 155 tests, 0 failures (33.4 seconds). Historical Phase 78 observations and receipt source scope remain unchanged.

**Duration diagnosis:** The original rejected capture did not preserve its candidate vector, so its exact offending run number is unavailable. A capture-order diagnostic replay then passed all 21 focused selectors and recorded the following `mix ci.evidence` results: run 1, 46,289 ms; run 2, 82,639 ms; run 3, 71,590 ms. Each run exited 0 with 155 tests and 0 failures; runs 2 and 3 exceeded the same strict 60,000 ms gate. Three evidence-only repetitions outside that focused preamble measured 49,167 ms, 53,612 ms, and 59,129 ms. This establishes runtime variability in the required evidence subprocess, not a failing assertion. No selector, security assertion, capture implementation, or duration threshold was changed; those code paths are outside this plan's declared outputs. The lower-load capture and both required fresh gates subsequently passed under the original limit.

**Current proof identity:** canonical Phase 73 proof `phase73-4f82a31b5b86c7b5`, captured at `2026-09-30T21:23:26Z`, source digest `sha256:63faf8fae6b694c1f0b535c7e9d0ca51c269e371a91cd5368c7b5e6770dac97f`, proof SHA-256 `16672eddb7a128520c57b2764d1e4dc5511fb7e480b609bee2e576b79c81a9dc`. Both Phase 73 reports embed the identical canonical proof, and the dependent current proof identity fields in the Phase 78 receipt match it. The old `phase73-a98cf8e53a4630fb` proof and Phase 78's OTP 27 cold-matrix observations remain historical; neither is evidence for protected-main CI.

**Prior proof verification (historical):** proof `phase73-a98cf8e53a4630fb` recorded 21 focused owners, three 155-test evidence vectors, and 13 security constituents. Its earlier `mix ci.phase73.reconciliation` pass (1 test, 0 failures, 5 excluded; 637.5 seconds), full test pass (999 tests, 0 failures, 11 excluded; 639.7 seconds), formatting check, inventory verifier, and repository proof validation predate the Task 1 source change above.

**Open evidence gaps:** the current main-SHA inventory has no passing evidence for its nine mandatory lanes; the protection resource and exact rollback remain incomplete; and two Phase 76 concurrency windows remain unautomated. Phase 79 local source proof is current, but it does not replace missing protected-main evidence. Release remains blocked. No human review substitutes for these deterministic or live postconditions.

**Approval:** not applicable; this is an automated validation map, not a human acceptance gate.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T00:24:54Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T00:35:33Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T01:06:52Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T01:38:15Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T01:43:45Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T01:51:05Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.
