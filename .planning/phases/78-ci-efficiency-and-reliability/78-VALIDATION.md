---
phase: "78"
slug: "ci-efficiency-and-reliability"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 78 — Validation Strategy

This is an execution contract, not evidence that Phase 78 has passed. All acceptance is automated in mandatory CI. Plans 78-01 through 78-07 assign the exact focused owners below.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit/Mix, shell contracts, Playwright, actionlint |
| Configuration | `mix.exs`, `test/test_helper.exs`, workflow and Playwright configuration |
| Local toolchain | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` |
| Quick command | `mix test test/security/ci_gate_integrity_test.exs test/adoption/package_consumer_ci_contract_test.exs test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` |
| Full lanes | `mix qa`, `mix ci.security`, `mix ci.evidence`, generated reconciliation replay, consumer, LedgerLoop, and deterministic browser lanes |
| Measured baseline | Quick command: 8 tests, 0 failures; lifecycle: 81 tests, 4 failures after the transition to Phase 78 |

Use the explicit local toolchain assignments above when invoking Mix locally; preserve the user-owned `.tool-versions`. Hosted runs use their declared toolchain matrix.

## Sampling Rate

- Every acceptance-bearing task owns a deterministic focused ExUnit or dedicated Mix command and a mandatory lane; browser/shell criteria resolve through enumerated owned harness commands with positive run evidence.
- Run focused evidence after each task; run affected named lanes after each wave.
- Target under 30 seconds for new focused fixtures; record actual timing. Existing governance took 27.3 seconds during research. Full security, reconciliation, consumer, and browser lanes have no invented short timeout.
- Run all clean-state completion checks from the research manifest before phase verification. Preserve individual exit codes and positive execution evidence.
- Capture source-bound reconciliation after 78-01 and 78-02's measurement-harness edits so baseline runs can pass; recapture after final governed edits. Never transcribe proof hashes or count stale proof as current success.

## Requirement Verification Map

| Requirement | Automated owner | Controls required | Baseline |
|---|---|---|---|
| PIPE-02 | `mix test test/adoption/evidence_contract_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors` | One primary Mix or enumerated browser/shell harness owner, positive execution and exact blocking step; explicit independent defenses; disabled/duplicate/forged/zero-selection/hollow failures | Existing owners; new cases pending |
| PIPE-03 | `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors` | Comparable multi-run records, cache toolchain/lock identity, locked installs, clean consumer roots, fresh-process aliases | Existing owner; new cases pending |
| PIPE-04 | `mix test test/adoption/workflow_hygiene_test.exs test/release/fleet_proxy_ci_integrity_test.exs test/adoption/external_canary_contract_test.exs --warnings-as-errors` | Least privilege and concurrency including adoption-external-idp, exact action pins, bounded artifact allowlists and sensitive sentinels | Existing owners; new cases pending |
| PIPE-05 | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` plus complete clean-state manifest and dedicated `mix ci.phase78.receipt` | Valid Phase 78 lifecycle and rejection fixtures, final source-bound proof, producer run and mandatory post-producer real receipt validation | 4 known lifecycle failures |

## Exact Task Owners

All commands below run from the repository root with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` prepended. Each must exit zero and report a positive selected-test count. The commands are direct focused Mix tests or the exact named Mix owner; operational lanes run separately as each task action requires.

| Plan/task | Direct automated command | Requirement |
|---|---|---|
| 78-01/1 | `mix test test/governance/milestone_scope_test.exs test/adoption/evidence_contract_test.exs --warnings-as-errors` | PIPE-02, PIPE-05 |
| 78-01/2 | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | PIPE-02 |
| 78-01/3 | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | PIPE-02 |
| 78-02/1 | `mix ci.phase73.reconciliation` after canonical capture and report refresh; independently run `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors` | PIPE-03, PIPE-05 |
| 78-02/2–3 | `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors` | PIPE-03, PIPE-05 |
| 78-03/1–2 | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | PIPE-02, PIPE-03 |
| 78-04/1–3 | `mix test test/adoption/workflow_hygiene_test.exs --warnings-as-errors` | PIPE-04 |
| 78-05/1 | `mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` | PIPE-04, PIPE-05 |
| 78-05/2 | `mix test test/adoption/external_canary_contract_test.exs --warnings-as-errors` | PIPE-04 |
| 78-06/1 | `mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` | PIPE-04 |
| 78-06/2 | `mix test test/adoption/external_canary_contract_test.exs --warnings-as-errors` | PIPE-04 |
| 78-06/3 | `mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` | PIPE-04 |
| 78-07/1 | `mix test test/adoption/phase78_clean_state_contract_test.exs --only phase78_clean_state_schema --warnings-as-errors` | PIPE-05 |
| 78-07/2 | `mix test test/governance/phase_73_reconciliation_test.exs --only phase_73_reconciliation_replay --warnings-as-errors` | PIPE-05 |
| 78-07/3 | `mix ci.phase78.receipt` after full producer execution | PIPE-05 |

The new workflow-hygiene and clean-state test files are created by Tasks 78-04/1 and 78-07/1 before their first invocation. Plan 78-01 validates their static creation order but does not claim future files or receipts have executed. The cost report and clean-state receipt are generated by Tasks 78-02/2 and 78-07/3. The 78-07 fixture/schema selector runs in default mandatory QA; the real receipt selector is explicitly excluded in test_helper during the producer manifest, then required by the dedicated unconditional PR/main security-gates step. Absence, partial output, zero-count entries, failed exits and stale source/proof all fail that post-producer owner.

## Wave 0 Requirements

- Repair the Phase 78 lifecycle regression without weakening malformed-state rejection.
- Extend existing ownership contracts and create focused deterministic cases for measurement, alias execution, cache, concurrency, and redaction policies.
- Update the trace-status contract when action pins change.
- Validate new plans against the current governance task grammar, with complete risk metadata and individual executable acceptance owners.
- Define a bounded clean-state result schema with real process exits and positive test counts; consumer and browser prerequisites are automated by owned harnesses. The default producer never depends on the real receipt selector, and the dedicated mandatory owner runs only after production.
- No new test framework is required.

## Automated Completion

The research clean-state manifest covers formatting, warnings-as-errors compilation/tests, QA, security, evidence, reconciliation, verification, integration, all consumer profiles, LedgerLoop, deterministic browser journeys, trace-status contracts, and full actionlint. Each has to execute successfully on the final governed source. A separate mandatory `mix ci.phase78.receipt` invocation validates the real generated file against the complete tracked operational-source snapshot and final Phase 73 proof. Caches and scheduled real-provider canaries cannot substitute for mandatory proof.

Missing automation remains an open gap. There are no manual completion checks or required UAT artifacts.

## Validation Status

- [x] Final plan task map names every automated owner.
- [ ] Every task has automated verification or an explicit earlier fixture dependency.
- [ ] No three consecutive tasks lack focused automated feedback.
- [ ] Every new test reference is created before it is invoked.
- [ ] No watch-mode commands or success inferred from cache hits.
- [ ] Source-bound proof and full clean-state runs pass.
- [ ] Compliance is set from execution evidence, not planning intent.
