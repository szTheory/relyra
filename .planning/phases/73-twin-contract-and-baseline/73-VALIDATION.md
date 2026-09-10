---
phase: "73"
slug: "twin-contract-and-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
revised: "2026-09-10"
---

# Phase 73 — Validation Strategy

> Final deterministic evidence map after Plans 73-01 through 73-13 and the post-merge working-directory isolation repair.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `config/test.exs` |
| **Mandatory owner** | `mix ci.evidence` runs both Phase 73 contract modules in one fresh process with `--only evidence_contract --warnings-as-errors` |
| **Required workflow** | `.github/workflows/security-gates.yml`, `jobs.security` → `Evidence contract` → `mix ci.evidence` |
| **Focused ownership** | Plan/task tags from `plan_73_06_task_1` through `plan_73_13_task_3`, plus `cwd_isolation` for the post-merge race regression |
| **Environment** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1` prefixes Mix verification commands |
| **Workflow syntax** | `actionlint .github/workflows/security-gates.yml` |
| **Repository closeout context** | Exact full-suite seed `778220`: 864 tests; the sole failure is the explicitly deferred Phase 77 documentation-vocabulary assertion and is not a Phase 73 Nyquist gap |

## Requirement Coverage

| Requirement | Observable contract | Behavioral owner | Mandatory command | Status |
|-------------|---------------------|------------------|-------------------|--------|
| EVID-01 | One literal ledger covers all 37 active requirements and six personas while preserving planned/canary visibility | `test/adoption/evidence_contract_test.exs` | `mix ci.evidence` | green |
| EVID-02 | Closure requires a valid existing row, one executable argv, a real alias, registered non-zero ExUnit selection, and an unconditional blocking workflow owner for every planning path | Both Phase 73 contract modules | `mix ci.evidence` | green |
| QUAL-01 | The dated seven-category/five-severity inventory is fail-closed and every row has tracked non-symlink or executable provenance | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |
| PIPE-01 | The nine-surface CI baseline retains measured topology, sample duration, duplication, cache, ownership, drift, and redaction-safe failure evidence | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |
| GOV-01 | Governed changes require exact plan-local prior approval, trusted commit provenance, and singular reversible state-bound remote batches | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |
| GOV-02 | Trusted plan identity selects the full schema and rejects demand-gated or unrelated implementation scope | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |

## Per-Task Verification Map

Every command is deterministic, non-watch, network-independent, and selected by the mandatory `ci.evidence` lane. Earlier task contracts use the complete behavioral owner; later gap plans retain focused non-zero selectors.

| Task ID | Requirement | Behavioral evidence | Automated command | Status |
|---------|-------------|---------------------|-------------------|--------|
| 73-01-01 | EVID-01 | Literal ledger schema, exact requirements/personas, and ledger-to-lane tracer | `mix ci.evidence` | green |
| 73-01-02 | EVID-02 | Empty/duplicate/order, canary, owner, selector, alias, and workflow adversaries | `mix ci.evidence` | green |
| 73-02-01 | QUAL-01 | Anchored findings schema, enums, dispositions, row evidence, and redaction controls | `mix ci.evidence` | green |
| 73-02-02 | PIPE-01 | Nine CI surfaces, sample language, ownership, drift, cache, and failure evidence | `mix ci.evidence` | green |
| 73-03-01 | GOV-01 | Missing/late/wrong/cross-plan approval and completion separation | `mix ci.evidence` | green |
| 73-03-02 | GOV-02 | Requirement ownership, manual-gate rejection, and feature-neutral controls | `mix ci.evidence` | green |
| 73-04-01 | EVID-02 | Closed rows, semantic selection, and exact blocking security-step controls | `mix ci.evidence` | green |
| 73-04-02 | EVID-02 | Per-task ownership rejects generic commands, zero selectors, and uncovered siblings | `mix ci.evidence` | green |
| 73-05-01 | GOV-01, GOV-02 | Closed risk metadata and independent governed surface/diff inference | `mix ci.evidence` | green |
| 73-05-02 | GOV-01 | Structured batch rejects placeholders and target mismatches | `mix ci.evidence` | green |
| 73-05-03 | QUAL-01, GOV-02 | Exact exclusions and one allowed marker per finding | `mix ci.evidence` | green |
| 73-06-01 | EVID-01, EVID-02 | Shell rejection, effective filters, module isolation, and tag-key semantics | `mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_1 --warnings-as-errors` | green (4) |
| 73-06-02 | EVID-02 | Conditional/fallible event owners fail | `mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_2 --warnings-as-errors` | green (1) |
| 73-07-01 | GOV-01, GOV-02 | Closed task type, decision grammar, and scope vocabulary | `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_1 --warnings-as-errors` | green (3) |
| 73-07-02 | GOV-01, GOV-02 | SUMMARY, changed-surface, and all-task exclusion controls | `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_2 --warnings-as-errors` | green (3) |
| 73-08-01 | GOV-01 | Single-operation grammar rejects appended remote commands | `mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_1 --warnings-as-errors` | green (1) |
| 73-08-02 | QUAL-01, PIPE-01, GOV-01 | Containment, cumulative `lstat`, regular leaf, index, symlink, and command provenance | `mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_2 --warnings-as-errors` | green (1) |
| 73-09-01 | EVID-01, EVID-02 | Anchored argv, actual aliases, registered ExUnit, and shadow-macro rejection | `mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_1 --warnings-as-errors` | green (3) |
| 73-09-02 | EVID-02 | Job/step fallibility and ordered GitHub path filters | `mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_2 --warnings-as-errors` | green (4) |
| 73-10-01 | GOV-01, GOV-02 | Cross-source identity and immutable path-based schema dispatch | `mix test test/governance/milestone_scope_test.exs --only plan_73_10_task_1 --warnings-as-errors` | green (2) |
| 73-10-02 | GOV-01 | Git-derived ancestry, completion boundary, diffs, and SUMMARY cross-check | `mix test test/governance/milestone_scope_test.exs --only plan_73_10_task_2 --warnings-as-errors` | green (3) |
| 73-11-01 | GOV-01 | Singular fields and tracked JSON normalized to desired/current state | `mix test test/governance/milestone_scope_test.exs --only plan_73_11_task_1 --warnings-as-errors` | green (2) |
| 73-11-02 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Indexed script provenance and complete integration | `mix test test/governance/milestone_scope_test.exs --only plan_73_11_task_2 --warnings-as-errors && mix ci.evidence` | green (2 focused; 82 integration) |
| 73-12-01 | EVID-01, EVID-02 | Actual `ci.evidence` alias parsing and positive effective selection for every owner after include/exclude filters | `mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_1 --warnings-as-errors` | green (3) |
| 73-12-02 | EVID-02 | Pull-request and main-push triggers reject positive paths and cannot ignore any tracked governed input | `mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_2 --warnings-as-errors` | green (3) |
| 73-13-01 | QUAL-01, PIPE-01, GOV-01 | Complete branch-protection state retains and validates every accepted control | `mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_1 --warnings-as-errors` | green (2) |
| 73-13-02 | GOV-01 | Indexed script identity binds to tracked static result evidence without executing plan-selected code | `mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_2 --warnings-as-errors` | green (2) |
| 73-13-03 | GOV-01, GOV-02 | Git derives the complete ordered exact-scope commit set; manifest and SUMMARY are equality audits only | `mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_3 --warnings-as-errors` | green (2) |
| post-merge-cwd | EVID-02 | Fixture alias inspection never mutates VM-global cwd | `mix test test/adoption/evidence_contract_test.exs --only cwd_isolation --warnings-as-errors` | green (1) |

## Automation and Safety Boundaries

- `mix ci.evidence` is mandatory in `jobs.security` for pull requests, pushes to `main`, and planning-only changes; its owner is unconditional and non-fallible.
- External canaries remain visible but cannot close deterministic acceptance.
- Remote fixtures perform only local parsing, git/filesystem inspection, and tracked static-result validation; they never execute plan-selected mutation code or query or mutate GitHub.
- Approval checkpoints authorize mutations only and never count as completion evidence.
- No manual-only, watch-mode, network-dependent, or human-needed gate closes a Phase 73 criterion.

## Validation Sign-Off

- [x] All 6 Phase 73 requirements map to complete deterministic behavioral tests in a mandatory CI lane.
- [x] All 28 acceptance-bearing tasks across 13 completed plans map to executable commands.
- [x] Every dedicated Plan 73-06 through 73-13 selector has a non-zero selected set.
- [x] The complete owner lane passes 82 tests across both contract modules.
- [x] The post-merge cwd-race regression passes independently.
- [x] Workflow syntax passes `actionlint`.
- [x] The sole exact-seed full-suite failure is owned by Phase 77 and is not a Phase 73 gap.

**Approval:** Phase 73 is Nyquist-compliant. Plans 73-12 and 73-13 close the five previously confirmed fail-open behaviors with focused adversarial tests, and the complete 82-test mandatory owner lane passes.

## Validation Audit 2026-09-10 — Final 11-Plan Coverage

| Metric | Count |
|--------|-------|
| Phase requirements mapped | 6/6 |
| Completed plans mapped | 11/11 |
| Acceptance-bearing tasks mapped | 23/23 |
| Mandatory evidence tests | 70 passing |
| Post-merge cwd-isolation tests | 1 passing |
| Workflow syntax errors | 0 |
| Phase 73 gaps found | 0 |
| Escalated | 0 |

Audit commands executed on 2026-09-10:

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` — 70 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/adoption/evidence_contract_test.exs --only cwd_isolation --warnings-as-errors` — 1 test, 0 failures.
- `actionlint .github/workflows/security-gates.yml` — exit 0.

## Validation Audit 2026-09-10 — Post-Review Correction

| Metric | Count |
|--------|-------|
| Planned tasks with executable commands | 23/23 |
| Critical behavioral gaps confirmed | 5 |
| Requirements blocked | 3 |
| Nyquist compliant | no |

The green 70-test lane does not cover empty-effective alias selection, complete governed workflow paths, complete branch-protection state comparison, non-executing script validation, or equality between manifest and Git-derived commit provenance. See `73-REVIEW.md` and `73-VERIFICATION.md`.

## Validation Audit 2026-09-10 — Gap Closure Refresh

| Metric | Count |
|--------|-------|
| Phase requirements mapped | 6/6 |
| Completed plans mapped | 13/13 |
| Acceptance-bearing tasks mapped | 28/28 |
| Previously confirmed behavioral gaps | 5 |
| Gaps resolved | 5 |
| Escalated | 0 |
| Mandatory evidence tests | 82 passing |
| Workflow syntax errors | 0 |
| Nyquist compliant | yes |

Audit commands executed on 2026-09-10 with Elixir 1.19.5 / OTP 28.1:

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_1 --warnings-as-errors` — 3 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_2 --warnings-as-errors` — 3 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_1 --warnings-as-errors` — 2 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_2 --warnings-as-errors` — 2 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_3 --warnings-as-errors` — 2 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix ci.evidence` — 82 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix format --check-formatted` — exit 0.
- `actionlint .github/workflows/security-gates.yml` — exit 0.
- `git diff --check` — exit 0.
