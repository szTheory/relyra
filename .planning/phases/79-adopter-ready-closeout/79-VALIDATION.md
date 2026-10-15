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

**Current inventory identity:** szTheory/relyra@refs/heads/main, SHA c786a9890f2f99f0dd98f89a1d9713db7c486837, observed 2026-10-01T12:07:59Z. All nine mandatory lanes are absent on this SHA. The parent protection response omits required_pull_request_reviews and restrictions; REST reports approval count 1 while same-ref GraphQL reports count None and requiresApprovingReviews=False. The composite capture is incomplete and has no resource.

**Phase 79 protection capture:** 933243f5dc3d01b9a0673e9270c7abdc6d6185ee2512190c7b7854014580e908 file SHA-256; source digest abbfcd7bb34aed797d9ecb91414e2075f193ce929d4eb6eb50849440370e296a. REST reports approval count 1; GraphQL reports requiredApprovingReviewCount=None and requiresApprovingReviews=False. The capture is incomplete and its resource is null. Desired SHA-256 5c53f5ecd0d8b65baf87c4c0476bf1700e6e504218a69260f3bf20f77394379d, rollback SHA-256 1ebc4cebf0cf807f6fca98c6b33d992e84af7fac835ef57cccc9660dc4bc3433, and no-action batch SHA-256 ac64a6845b996ef5b0e93188447a165af2dfe06dda2cc96a46b3dfdef8521605; no approval or remote operation was prepared.

**Prior capture attempts (before the successful lower-load retry):** `mix ci.evidence` passed with 155 tests and 0 failures after the Task 1 source change (63.9 seconds); additional runs with alternate local scheduler settings also passed but were slower (80.5, 100.4, and 102.5 seconds). Earlier supported Phase 73 capture attempts in isolated Phase 75 snapshots reached proof validation but rejected a candidate at `evidence duration must remain below 60000ms`. The live checkout's `STATE.md` and `ROADMAP.md` were not changed. The successful snapshot had the existing root and LedgerLoop build/dependency caches linked. A prior snapshot attempt lacked LedgerLoop caches and failed its nested-project probe; that harness issue was corrected before the successful capture.

**Manual recovery record (2026-09-30):** GSD safe-resume found existing 79-04 commits without a `79-04-SUMMARY.md` or async-job manifest. The user selected continuation of Task 2 only. Task 1's committed source and passing evidence are preserved; Task 1 was not replayed. Task 2 resumed through its declared isolated capture and reconciliation path. The plan summary remains unwritten until the remaining plan closeout work is complete.

**Task 2 initial retry result (2026-09-30):** The user-directed retry used the supported `Relyra.Phase73Reconciliation.capture!/2` entry point in a disposable clone, with the Phase 75 planning lifecycle and linked root/LedgerLoop caches. The capture completed its focused selectors, three `mix ci.evidence` subprocesses, and pinned `mix ci.security` subprocess, then rejected the assembled proof at `validate_result!/3` with `evidence duration must remain below 60000ms`. The capture does not report which evidence vector exceeded the ceiling when proof validation rejects it; no run number is claimed for this retry. No candidate was written, and the live Phase 73 proof/reports and Phase 78 receipt remained unchanged at that point.

**Task 2 successful lower-load capture (2026-09-30):** A later retry started when host load was 4.65 (15-minute average 8.01), compared with about 10 during the rejected retry. The supported Phase 75 snapshot capture passed all 21 focused selectors, all 13 pinned security constituents, and all three `mix ci.evidence` vectors: 56,809 ms, 58,441 ms, and 54,252 ms; each vector had 155 tests and 0 failures. Proof `phase73-4f82a31b5b86c7b5` was captured at `2026-09-30T21:23:26Z`, source digest `sha256:63faf8fae6b694c1f0b535c7e9d0ca51c269e371a91cd5368c7b5e6770dac97f`, proof file SHA-256 `16672eddb7a128520c57b2764d1e4dc5511fb7e480b609bee2e576b79c81a9dc`. The candidate's security lane passed 71 tests, 0 failures. The fresh `mix ci.phase73.reconciliation` replay passed 1 test, 0 failures (5 excluded; 551.5 seconds), and standalone `mix ci.evidence` passed 155 tests, 0 failures in the isolated snapshot (51.2 seconds). After promoting the canonical proof, report blocks, and dependent Phase 78 proof identity fields, repository validation passed and the live `mix ci.evidence` lane passed 155 tests, 0 failures (33.4 seconds). Historical Phase 78 observations and receipt source scope remain unchanged.

**Duration diagnosis:** The original rejected capture did not preserve its candidate vector, so its exact offending run number is unavailable. A capture-order diagnostic replay then passed all 21 focused selectors and recorded the following `mix ci.evidence` results: run 1, 46,289 ms; run 2, 82,639 ms; run 3, 71,590 ms. Each run exited 0 with 155 tests and 0 failures; runs 2 and 3 exceeded the same strict 60,000 ms gate. Three evidence-only repetitions outside that focused preamble measured 49,167 ms, 53,612 ms, and 59,129 ms. This establishes runtime variability in the required evidence subprocess, not a failing assertion. No selector, security assertion, capture implementation, or duration threshold was changed; those code paths are outside this plan's declared outputs. The lower-load capture and both required fresh gates subsequently passed under the original limit.

**Current proof identity:** canonical Phase 73 proof `phase73-4f82a31b5b86c7b5`, captured at `2026-09-30T21:23:26Z`, source digest `sha256:63faf8fae6b694c1f0b535c7e9d0ca51c269e371a91cd5368c7b5e6770dac97f`, proof SHA-256 `16672eddb7a128520c57b2764d1e4dc5511fb7e480b609bee2e576b79c81a9dc`. Both Phase 73 reports embed the identical canonical proof, and the dependent current proof identity fields in the Phase 78 receipt match it. The old `phase73-a98cf8e53a4630fb` proof and Phase 78's OTP 27 cold-matrix observations remain historical; neither is evidence for protected-main CI.

**Prior proof verification (historical):** proof `phase73-a98cf8e53a4630fb` recorded 21 focused owners, three 155-test evidence vectors, and 13 security constituents. Its earlier `mix ci.phase73.reconciliation` pass (1 test, 0 failures, 5 excluded; 637.5 seconds), full test pass (999 tests, 0 failures, 11 excluded; 639.7 seconds), formatting check, inventory verifier, and repository proof validation predate the Task 1 source change above.

**Open evidence gaps:** the current main-SHA inventory has no passing evidence for its nine mandatory lanes; the protection resource and exact rollback remain incomplete; and two Phase 76 concurrency windows remain unautomated. Phase 79 local source proof is current, but it does not replace missing protected-main evidence. Release remains blocked. No human review substitutes for these deterministic or live postconditions.

**Approval:** not applicable; this is an automated validation map, not a human acceptance gate.

## Pending gap-plan evidence map (79-07–79-12)

These entries are pending execution. Approval checkpoints authorize exact remote actions; they do not verify behavior. The Phase 79 actual-artifact governance owner must accept both legitimate blocked and complete closeout states from deterministic fixtures before the publication source freezes, while rejecting conflicting or fabricated evidence. A failed or missing live result remains an open automation/external-state gap.

| Task | Plan | Requirement | Automated evidence | Immediate nonzero / missing-output signal | Status |
|---|---|---|---|---|---|
| 79-07-T1/T2 | 79-07 | REPO-01/03, EXIT-01 | `mix ci.evidence` fixtures for original commit ancestry, simulated normal-merge topology, transaction identities, and actual-artifact blocked/ready states; `mix ci.phase73.reconciliation` after governed test edit | Unclassified commit/path, lost summary/task ancestry, forged ready state, REST/GraphQL conflict, stale proof, or missing receipt | pending |
| 79-07-T3, 79-08-T1/T3 | 79-07/08 | REPO-01/03 | Publication verifier plus `verify_phase79_transaction.py --stage publication|pr-preflight|pr-result` live read-back; mandatory CI fixtures for target/head/base/tree, approval digest and partial writes | Changed source/base/tree, stale approval, extra operation, absent PR or partial push/PR state | pending |
| 79-09-T1/T3 | 79-09 | REPO-03, EXIT-01 | `verify_phase79_transaction.py --stage merge-preflight|merge-result`, local QA/security/format gates, isolated main-topology provenance proof | Missing/failed PR check, moved head/base, unavailable normal merge, wrong main parents/tree, lost completed-plan provenance | pending |
| 79-10-T1/T3 | 79-10 | REPO-02/03, EXIT-01 | Existing inventory verifier plus `verify_phase79_transaction.py --stage ci-preflight|ci-result` on all nine lanes and fleet; 79-07 mandatory CI fixtures prove absent-current-main-run preflight passes only with exact enabled canonical workflow/ref/SHA/action pending packet, absent final result fails, and matching post-dispatch owner run/job/check result passes | Missing-run preparation rejected despite valid packet; missing/failed lane or fleet result accepted as final; ambiguous or mismatched identity, wrong dispatch approval/ref/SHA, or mismatched publication/merge/CI receipt | pending |
| 79-11-T1/T3 | 79-11 | REPO-02/03, EXIT-01 | Existing builder `--verify` against immutable approved capture/inventory/desired/rollback/batch before and after mutation; separate post-state read via `verify_phase79_transaction.py --stage protection-result` | REST/GraphQL conflict, changed approved snapshot bytes, null rollback, non-fleet delta, wrong post-state, or partial write called complete | pending; external policy-owner/provider prerequisite |
| 79-12-T1/T2 | 79-12 | REPO-01/02/03, EXIT-01 | `verify_phase79_transaction.py --stage closeout` joins publication/PR/merge/CI/protection receipts and post-state, plus `mix ci.evidence`, Phase 73 reconciliation, full test/security/format/QA and final live main SHA read | Stale proof, incomplete risk, moved main, changed pre-state, receipt identity mismatch, nonzero gate or missing final evidence | pending |


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


## Plan 79-05 evidence update

The composite capture and verifier passed with status `incomplete` and a null resource because REST/GraphQL review values conflict. The current inventory identity is `c786a9890f2f99f0dd98f89a1d9713db7c486837` at `2026-10-01T01:43:45Z`; readiness remains unknown and all nine mandatory lanes are absent. Exact payload generation and remote approval are deferred to Wave 6, which must first establish automated source agreement. No remote calls beyond read-only GET/query operations were made.

## Plan 79-06 evidence update

Both read-only observations bind refs/heads/main at c786a9890f2f99f0dd98f89a1d9713db7c486837. The fresh composite capture at 2026-10-01T12:07:52Z and inventory at 2026-10-01T12:07:59Z verify; readiness remains unknown. REST required approval count is 1; GraphQL requiredApprovingReviewCount is None and requiresApprovingReviews is False. All nine mandatory lanes are absent. The builder verifier passes with blocked desired/rollback records and an inert no-action batch.

Artifact SHA-256 values: capture 933243f5dc3d01b9a0673e9270c7abdc6d6185ee2512190c7b7854014580e908; inventory f6633e69eadf3b80d707372bb7347f50a25bec1b47c5ec8ba78d8cfbccaa3d12; desired 5c53f5ecd0d8b65baf87c4c0476bf1700e6e504218a69260f3bf20f77394379d; rollback 1ebc4cebf0cf807f6fca98c6b33d992e84af7fac835ef57cccc9660dc4bc3433; no-action batch ac64a6845b996ef5b0e93188447a165af2dfe06dda2cc96a46b3dfdef8521605. Capture source digest: abbfcd7bb34aed797d9ecb91414e2075f193ce929d4eb6eb50849440370e296a. The exact conflict is preserved; no source was preferred and no approval or remote operation was inferred.

Exact next action: wait for the GitHub policy source discrepancy to be resolved by its owner, then repeat bounded same-SHA reads and current-main inventory. Continue only when sources agree and all nine mandatory lanes have passing evidence; any mutation requires a separate exact-batch approval plan.
