---
phase: "73"
slug: "twin-contract-and-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
revised: "2026-09-09"
---

# Phase 73 — Validation Strategy

> Deterministic sampling contract for the Phase 73 gap-closure execution. This document maps evidence; it does not claim the pending implementation is green.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `config/test.exs` |
| **Wave 6 feedback** | Four independent non-zero plan/task selectors; no complete governance or phase suite before both parallel plans merge |
| **Wave 7 integration** | `mix ci.evidence`, expected to select all 52 committed Phase 73 contract tests after Plan 73-08 Task 2 |
| **Repository closeout** | `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, `mix format --check-formatted`, and `actionlint .github/workflows/*.yml` |
| **Environment** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` prefixes every Mix command; the user-owned `.tool-versions` remains untouched |

---

## Sampling Rate and Dependency Contract

- **After Plan 73-06 Task 1:** run only `--only plan_73_06_task_1`; fail on non-zero exit, zero selected tests, or selection outside its four named CR-01/CR-02 cases.
- **After Plan 73-06 Task 2:** run only `--only plan_73_06_task_2`; fail on non-zero exit, zero selected tests, or selection outside its named CR-03 case.
- **After Plan 73-07 Task 1:** run only `--only plan_73_07_task_1`; fail on non-zero exit, zero selected tests, or selection outside its three named CR-04/CR-05 cases.
- **After Plan 73-07 Task 2:** run only `--only plan_73_07_task_2`; fail on non-zero exit, zero selected tests, or selection of a CR-08/CR-09 case.
- **Wave 6 merge:** the four commands above are the merge evidence. Do not run the complete governance selection or `mix ci.evidence` as a Wave 6 completion condition because Plan 73-08 still owns CR-08 and CR-09.
- **After Plan 73-08 Task 1:** run only `--only plan_73_08_task_1`; fail on non-zero exit, zero selected tests, or selection of a CR-09 provenance case.
- **After Plan 73-08 Task 2:** first run `--only plan_73_08_task_2`; then run the full `mix ci.evidence` integration gate. The first command fails on non-zero exit, zero selected tests, omission of the isolated CR-09 control that replaces a tracked intermediate directory with a symlink to an external regular-file tree, or selection of a CR-08 case. The control extends an existing tagged test so the integration command still fails on non-zero exit, a count other than 52 committed contract tests, or any remaining CR-01 through CR-09 failure.
- **Before phase re-verification:** run the repository closeout commands. Any non-zero exit or invalid workflow syntax is reported truthfully; the already inventoried Phase 77 archival-vocabulary issue is not represented as closed by this planning strategy.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Automated Command | Immediate Failure Direction | Evidence State |
|---------|------|------|-------------|------------|-----------------|-------------------|-----------------------------|----------------|
| 73-01-01 | 01 | 1 | EVID-01 | T-73-01 | Ledger rows cannot claim incomplete or ambiguous ownership | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | Non-zero exit, missing persona/requirement, or hollow tracer owner | Historical execution complete; later adversarial gaps do not erase the artifact |
| 73-01-02 | 01 | 1 | EVID-02 | T-73-02 | Canary-only or planned owners cannot close acceptance | `mix ci.evidence` | Non-zero exit or either owner contract omitted | Historical execution complete; contract is under gap repair |
| 73-02-01 | 02 | 2 | QUAL-01 | T-73-05 | Findings retain closed severity, evidence, disposition, and ownership fields | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | Non-zero exit or malformed baseline accepted | Historical execution complete; CR-09 provenance gap remains assigned |
| 73-02-02 | 02 | 2 | PIPE-01 | T-73-06 | CI inventory retains topology, sampled duration, duplication, cache, ownership, and failure evidence | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | Non-zero exit or required CI inventory surface absent | Historical execution complete; inventory remains a sample |
| 73-03-01 | 03 | 3 | GOV-01 | T-73-09 | Governed mutation requires a prior matching plan-local checkpoint | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | Non-zero exit or risky fixture accepted without prior authorization | Historical execution complete; CR-04 through CR-08 gaps remain assigned |
| 73-03-02 | 03 | 3 | GOV-02 | T-73-11 | Implementation tasks remain feature-neutral | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | Non-zero exit or excluded capability fixture accepted | Historical execution complete; CR-07 gap remains assigned |
| 73-04-01 | 04 | 4 | EVID-02 | T-73-13..15 | Closure uses closed rows, executable selectors, and mandatory workflow ownership | `mix test test/adoption/evidence_contract_test.exs --only evidence_contract --warnings-as-errors` | Non-zero exit, zero selected tests, or hollow owner accepted | Historical gap plan complete; CR-01 through CR-03 implementation remains red |
| 73-04-02 | 04 | 4 | EVID-02 | T-73-16 | Each acceptance-bearing task owns executable non-zero evidence | `mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors` | Non-zero exit, zero selected tests, or sibling task borrows ownership | Historical gap plan complete; successor repairs are pending |
| 73-05-01 | 05 | 5 | GOV-01/GOV-02 | T-73-18..21 | Task risk, governed surfaces, and exclusions fail closed | `mix test test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors` | Non-zero exit, zero selected tests, or optimistic declaration suppresses risk | Historical gap plan complete; CR-04 through CR-07 remain assigned |
| 73-05-02 | 05 | 5 | GOV-01 | T-73-20 | Remote approval is one reversible same-target batch | `mix test test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors` | Non-zero exit, zero selected tests, or malformed batch accepted | Historical gap plan complete; CR-08 remains assigned |
| 73-05-03 | 05 | 5 | QUAL-01/GOV-02 | T-73-21..22 | Task exclusions and row-local provenance are structural | `mix test test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors` | Non-zero exit, zero selected tests, or unsupported reference accepted | Historical gap plan complete; CR-07/CR-09 remain assigned |
| 73-06-01 | 06 | 6 | EVID-01/EVID-02 | T-73-24..25 | Raw commands and effective module-scoped selectors prove real owners | `mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_1 --warnings-as-errors` | Non-zero exit, zero selected tests, selection outside four owned CR-01/CR-02 cases, or any owned bypass remains accepted | Pending; starts from committed RED cases |
| 73-06-02 | 06 | 6 | EVID-02 | T-73-26 | Required workflow ownership is unconditional and blocking | `mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_2 --warnings-as-errors` | Non-zero exit, zero selected tests, selection outside the owned CR-03 case, or conditional/fallible ownership accepted | Pending; starts from committed RED case |
| 73-07-01 | 07 | 6 | GOV-01/GOV-02 | T-73-28..29 | Closed task, scope, and decision vocabulary governs prior authorization | `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_1 --warnings-as-errors` | Non-zero exit, zero selected tests, selection outside three owned CR-04/CR-05 cases, or an owned bypass remains accepted | Pending; parallel with Plan 73-06 |
| 73-07-02 | 07 | 6 | GOV-01/GOV-02 | T-73-30..31 | Completed-plan diffs and all implementation tasks remain governed | `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_2 --warnings-as-errors` | Non-zero exit, zero selected tests, any CR-08/CR-09 selection, or summary/diff/exclusion bypass accepted | Pending; parallel with Plan 73-06 |
| 73-08-01 | 08 | 7 | GOV-01 | T-73-32 | CR-08 remote commands are exactly one parsed operation | `mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_1 --warnings-as-errors` | Non-zero exit, zero selected tests, any CR-09 selection, or appended/composed operation accepted | Pending; depends on both Wave 6 plans |
| 73-08-02 | 08 | 7 | QUAL-01/PIPE-01/GOV-01 | T-73-33..35 | CR-09 provenance walks every root-relative component and rejects final or intermediate symlinks before regular-file/index checks, including an indexed directory replaced by a symlink to an external regular-file tree, while sharing executable ownership semantics | `mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_2 --warnings-as-errors` | Non-zero exit, zero selected tests, omission of the isolated intermediate-symlink control, any CR-08 selection, or nonexistent/final-symlink/intermediate-symlink provenance accepted | Pending focused proof |
| 73-08-02-integration | 08 | 7 | EVID-01/EVID-02/QUAL-01/PIPE-01/GOV-01/GOV-02 | T-73-24..35 | All gap repairs compose in the mandatory owner lane | `mix ci.evidence` | Non-zero exit, a count other than 52 committed contract tests, or any CR-01 through CR-09 case remains red | Pending final integration proof after Task 2 |

Every Mix command in this table is executed with the explicit ASDF environment shown under Test Infrastructure.

---

## Wave 0 Requirements

- [x] `test/support/adoption_evidence.ex` — literal evidence ledger and repository-owner helpers
- [x] `test/adoption/evidence_contract_test.exs` — committed CR-01 through CR-03 adversarial cases
- [x] `test/governance/milestone_scope_test.exs` — committed CR-04 through CR-09 adversarial cases
- [x] `mix.exs` — fresh-process `ci.evidence` alias
- [x] `.github/workflows/security-gates.yml` — uniquely named Evidence contract step
- [x] All CR-01 through CR-09 behavior tests are committed; Plans 73-06 through 73-08 assign the six plan/task tags as the first test-local implementation action before running each selector

---

## Automation Policy

No human action, visual review, required UAT artifact, or approval state can satisfy these gap-closure criteria. The remote-operation fixtures are inert local strings; Phase 73 executes no remote command. Deterministic ExUnit selections and the mandatory `ci.evidence` lane are the only completion evidence.

---

## Validation Sign-Off

- [x] Every Plan 73-06 through 73-08 task has a dedicated non-zero automated selector and an immediate observable failure direction.
- [x] Wave 6 uses four independent selectors and contains no premature complete governance or `ci.evidence` condition.
- [x] Wave 7 Task 1 uses only the CR-08 selector; Task 2 owns CR-09, including the isolated tracked-intermediate-directory-to-external-symlink control within an existing tagged test, plus the complete 52-test `mix ci.evidence` gate.
- [x] Plans 73-06 through 73-08 appear in the per-task verification map.
- [x] Sampling continuity has no three consecutive tasks without deterministic automated feedback.
- [x] No watch-mode, network-dependent, manual, or human-needed completion gate exists.
- [x] `nyquist_compliant: true` records complete deterministic coverage, not current implementation success.

**Approval:** validation strategy complete. Gap implementation is still pending and begins from the 11 committed RED failures documented in `73-VERIFICATION.md`; no green implementation claim is made here.

## Validation Audit 2026-09-09 — Adjusted Gap Closure

| Metric | Count |
|--------|-------|
| Verification gaps mapped | 9 (CR-01 through CR-09) |
| Gap-plan tasks mapped | 6 |
| Independent Wave 6 selectors | 4 |
| Wave 7 focused selectors | 2 |
| Mandatory final contract tests | 52 |
| Gaps claimed implemented by this strategy | 0 |
