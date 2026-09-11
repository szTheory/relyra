---
phase: "73"
slug: "twin-contract-and-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
revised: "2026-09-11"
---

# Phase 73 — Validation Strategy

> Final evidence map after Plans 73-01 through 73-23 and the post-merge working-directory isolation repair.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `config/test.exs` |
| **Mandatory owner** | `mix ci.evidence` runs both Phase 73 contract modules in one fresh process with `--only evidence_contract --warnings-as-errors`; the current canonical proof is three independent 116-test passes in 26590ms, 25486ms, and 28991ms |
| **Required workflow** | `.github/workflows/security-gates.yml`, `jobs.security` → `Evidence contract` → `mix ci.evidence` |
| **Focused ownership** | Plan/task tags through `plan_73_26_task_2`; the current repair proof captures `plan_73_24_task_1`, `plan_73_24_task_2`, `plan_73_24_task_3`, `plan_73_25_task_1`, and `plan_73_25_task_2`, plus mandatory reconciliation owners `plan_73_26_task_1` and `plan_73_26_task_2` |
| **Environment** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` prefixes Mix verification commands |
| **Workflow syntax** | `actionlint .github/workflows/security-gates.yml` |
| **Repository closeout context** | Exact full-suite seed `778220`: 864 tests; the sole failure is the explicitly deferred Phase 77 documentation-vocabulary assertion and is not a Phase 73 Nyquist gap |
| **Current coverage** | 26 plans and 56 acceptance-bearing tasks are mapped exactly once and green in the final reconciled proof set |

## Requirement Coverage

| Requirement | Observable contract | Behavioral owner | Mandatory command | Status |
|-------------|---------------------|------------------|-------------------|--------|
| EVID-01 | One literal ledger covers all 37 active requirements and six personas while preserving planned/canary visibility | `test/adoption/evidence_contract_test.exs` | `mix ci.evidence` | green |
| EVID-02 | Closure requires a valid existing row, one executable argv, a real alias, registered non-zero ExUnit selection, and an unconditional blocking workflow owner for every planning path | Both Phase 73 contract modules | `mix ci.evidence` | green — CR-01, CR-02, CR-03, and WR-01 repaired |
| QUAL-01 | The dated seven-category/five-severity inventory is fail-closed and every row has tracked non-symlink or executable provenance | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |
| PIPE-01 | The nine-surface CI baseline retains measured topology, sample duration, duplication, cache, ownership, drift, and redaction-safe failure evidence | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green |
| GOV-01 | Governed changes require exact plan-local prior approval, trusted commit provenance, and singular reversible state-bound remote batches | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green — CR-04, CR-05, and CR-06 repaired |
| GOV-02 | Trusted plan identity selects the full schema and rejects demand-gated or unrelated implementation scope | `test/governance/milestone_scope_test.exs` | `mix ci.evidence` | green — CR-04, CR-05, and CR-06 repaired |

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
| 73-14-01 | EVID-01, EVID-02 | Push event grammar preserves occurrences and rejects negation, extra branches, duplicate/unsupported keys, and `branches-ignore` | `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_1 --warnings-as-errors` | green (3) |
| 73-14-02 | EVID-01, EVID-02 | Pull-request event grammar rejects restrictive activity filters, duplicate/unsupported keys, and malformed event values | `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_2 --warnings-as-errors` | green (3) |
| 73-15-01 | QUAL-01, PIPE-01, GOV-01, GOV-02 | Remote authorization accepts only tracked declarative `gh api --input` operations whose complete normalized payload equals approved state | `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_1 --warnings-as-errors` | green (2) |
| 73-15-02 | QUAL-01, PIPE-01, GOV-01, GOV-02 | Exact full-HEAD review includes every reachable same-plan descendant after the SUMMARY boundary | `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_2 --warnings-as-errors` | green (3) |
| 73-16-01 | EVID-02 | CR-06 security disposition cites both non-zero event-grammar owners before closure | `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_1 --warnings-as-errors && mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_2 --warnings-as-errors` | green (3 + 3) |
| 73-16-02 | GOV-01, GOV-02 | CR-07/CR-08 dispositions require the mandatory lane, zero high-threshold open threats, preserved T-73-12, and verified report state | `mix ci.evidence && test "$(sed -n 's/^threats_open: //p' .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md)" = "0" && rg -n 'T-73-51.*closed|T-73-52.*closed|T-73-53.*closed|status: verified' .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` | warning — mandatory lane passed 1/3 audit attempts; two attempts timed out |
| 73-17-01 | EVID-01, EVID-02 | One registered owner is discovered once and normalized into an immutable validation snapshot | `mix test test/adoption/evidence_contract_test.exs --only plan_73_17_task_1 --warnings-as-errors` | green (3) |
| 73-17-02 | EVID-01, EVID-02 | Mutation coverage consumes pure snapshots and three unchanged mandatory runs stay within the 60-second bound | `mix test test/adoption/evidence_contract_test.exs --only plan_73_17_task_2 --warnings-as-errors` | green (1) |
| 73-18-01 | EVID-01, EVID-02 | Workflow paths reject unsupported metacharacters before governed-input comparison | `mix test test/adoption/evidence_contract_test.exs --only plan_73_18_task_1 --warnings-as-errors` | green (3) |
| 73-18-02 | EVID-01, EVID-02 | Owner provenance requires a tracked non-symlink lexical path with a regular leaf | `mix test test/adoption/evidence_contract_test.exs --only plan_73_18_task_2 --warnings-as-errors` | green (2) |
| 73-19-01 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Security state records the then-current review threats before closure | `mix ci.evidence` | green |
| 73-19-02 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Threats close only after repeated bounded mandatory evidence and the security lane | `mix ci.evidence && mix ci.security` | green |
| 73-20-01 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | The later Critical single-flight finding is traced into the open security verdict | `mix ci.evidence` | green |
| 73-20-02 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Snapshot integrity and the checked-in red final lifecycle lane are registered | `mix ci.evidence` | green |
| 73-21-01 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Checked-in `ready_for_verification` reaches the active Phase 73 plan frontier | `mix test test/governance/milestone_scope_test.exs --only plan_73_21_task_1 --warnings-as-errors` | green (1) |
| 73-21-02 | EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Expanded lifecycle values remain a closed exact enum | `mix test test/governance/milestone_scope_test.exs --only plan_73_21_task_2 --warnings-as-errors` | green (1) |
| 73-22-01 | EVID-01, EVID-02 | Simultaneous owner cache misses serialize through one caller-independent discovery | `mix test test/adoption/evidence_contract_test.exs --only plan_73_22_task_1 --warnings-as-errors` | green (1) |
| 73-22-02 | EVID-01, EVID-02 | Pure snapshots bind to the complete normalized governed-input inventory | `mix test test/adoption/evidence_contract_test.exs --only plan_73_22_task_2 --warnings-as-errors` | green (1) |
| 73-23-01 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Active-plan prerequisites are executable, ordered, and green before report mutation | `mix test test/governance/milestone_scope_test.exs --only plan_73_23_task_1 --warnings-as-errors` | green (1) |
| 73-23-02 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Four focused selectors, three independent bounded evidence runs, and the complete security lane establish one proof set | `mix ci.evidence && mix ci.security` | green |
| 73-23-03 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Security and Nyquist dispositions reduce only after the staged proof set is recorded | `mix ci.evidence` | green |
| 73-24-01 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Current blocker rows remain open before repair evidence | `mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors` | green (1) |
| 73-24-02 | EVID-01, EVID-02, PIPE-01, GOV-01 | Repository authority and dependency-free security ownership | `mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors` | green (2) |
| 73-24-03 | EVID-02, QUAL-01, GOV-02 | Closed Mix argv and ExUnit multiple-include semantics | `mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors` | green (3) |
| 73-25-01 | GOV-01, GOV-02 | Total task consumption and task-local acceptance ownership | `mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors` | green (3) |
| 73-25-02 | EVID-02, GOV-01 | Completion-boundary classification and explicit merge rejection | `mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors` | green (2) |
| 73-26-01 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Canonical proof capture, source freshness, report equality, chronology, and positive security constituent mapping | `mix test test/governance/milestone_scope_test.exs --only plan_73_26_task_1 --warnings-as-errors` | green (1) |
| 73-26-02 | EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02 | Final threat and Nyquist reduction from the exact 56-owner staged proof | `mix test test/governance/milestone_scope_test.exs --only plan_73_26_task_2 --warnings-as-errors` | green (1) |
| post-merge-cwd | EVID-02 | Fixture alias inspection never mutates VM-global cwd | `mix test test/adoption/evidence_contract_test.exs --only cwd_isolation --warnings-as-errors` | green (1) |

## Automation and Safety Boundaries

- `mix ci.evidence` is mandatory in `jobs.security` for pull requests, pushes to `main`, and planning-only changes; its owner is unconditional and non-fallible.
- External canaries remain visible but cannot close deterministic acceptance.
- Remote fixtures perform only local parsing, git/filesystem inspection, and tracked static-result validation; they never execute plan-selected mutation code or query or mutate GitHub.
- Approval checkpoints authorize mutations only and never count as completion evidence.
- No manual-only, watch-mode, network-dependent, or human-needed gate closes a Phase 73 criterion.

## Validation Sign-Off

- [x] All 6 Phase 73 requirements map to automated behavioral tests in the mandatory CI lane.
- [x] All 49 acceptance-bearing tasks across 23 plans map to executable commands.
- [x] Every dedicated selector through Plan 73-23 has a non-zero selected set, including the four current Plan 73-21/22 selectors.
- [x] Three independent unchanged `mix ci.evidence` runs each selected 103 tests and passed within the 60-second per-run bound (20s, 20s, and 21s).
- [x] The complete unchanged `mix ci.security` lane passed; this plan applies no timing ceiling to that lane.
- [x] The post-merge cwd-race regression passes independently.
- [x] Workflow syntax passes `actionlint`.
- [x] The sole exact-seed full-suite failure is owned by Phase 77 and is not a Phase 73 gap.

**Approval:** Nyquist-compliant across 23 plans and 49 acceptance-bearing tasks after `plan_73_21_task_1`, `plan_73_21_task_2`, `plan_73_22_task_1`, and `plan_73_22_task_2` each passed 1 test, three unchanged sub-60-second `mix ci.evidence` runs each passed 103 tests in 20s, 20s, and 21s, and the complete unchanged `mix ci.security` lane passed.

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

## Validation Audit 2026-09-10 — Final 16-Plan Refresh

| Metric | Count |
|--------|-------|
| Phase requirements mapped | 6/6 |
| Completed plans mapped | 16/16 |
| Acceptance-bearing tasks mapped | 34/34 |
| New focused selectors | 4/4 green |
| Mandatory evidence attempts | 1 passing, 2 timed out |
| Mandatory evidence tests on passing attempt | 91 passing |
| Escalated implementation bugs | 0 |
| Nyquist compliant | no — nondeterministic mandatory lane |

Audit commands executed on 2026-09-10 with Elixir 1.19.5 / OTP 28.4.1:

- `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_1 --warnings-as-errors` — 3 tests, 0 failures.
- `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_2 --warnings-as-errors` — 3 tests, 0 failures.
- `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_1 --warnings-as-errors` — 2 tests, 0 failures.
- `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_2 --warnings-as-errors` — 3 tests, 0 failures.
- `mix ci.evidence` — attempts 1 and 2: 91 tests, 1 failure from a 60-second timeout in `active v1.11 plans declare scope and stop before every risky mutation`; attempt 3: 91 tests, 0 failures in 220.0 seconds.
- The known repository-wide archival vocabulary-policy failure was not modified and remains owned by Phase 77.

## Validation Audit 2026-09-11 — Plan 73-23 Evidence Staging

| Metric | Count |
|--------|-------|
| Phase requirements mapped | 6/6 |
| Completed plans mapped | 23/23 |
| Acceptance-bearing tasks mapped | 49/49 |
| Current focused selectors | 4/4 passing |
| Mandatory evidence attempts | 3/3 passing |
| Mandatory evidence tests per attempt | 103 |
| Mandatory evidence durations | 20s, 20s, 21s |
| Complete security lane | passing; no timing ceiling |
| Nyquist compliant | no — final reconciliation pending |

Audit commands executed on 2026-09-11 with Elixir 1.19.5 / OTP 28.4.1:

- `mix test test/governance/milestone_scope_test.exs --only plan_73_21_task_1 --warnings-as-errors` — 1 test, 0 failures.
- `mix test test/governance/milestone_scope_test.exs --only plan_73_21_task_2 --warnings-as-errors` — 1 test, 0 failures.
- `mix test test/adoption/evidence_contract_test.exs --only plan_73_22_task_1 --warnings-as-errors` — 1 test, 0 failures.
- `mix test test/adoption/evidence_contract_test.exs --only plan_73_22_task_2 --warnings-as-errors` — 1 test, 0 failures.
- `mix ci.evidence` — three independent unchanged runs, each 103 tests and 0 failures, in 20s, 20s, and 21s.
- `mix ci.security` — the complete unchanged alias exited 0 in 126s; the observed duration is informational because this plan applies no timing ceiling to the security lane.

## Validation Audit 2026-09-11 — Plan 73-23 Final Reconciliation

| Metric | Count |
|--------|-------|
| Phase requirements green | 6/6 |
| Completed plans mapped | 23/23 |
| Acceptance-bearing tasks mapped | 49/49 |
| Current focused selectors | 4/4 passing |
| Mandatory evidence attempts | 3/3 passing |
| Mandatory evidence tests per attempt | 103 |
| Mandatory evidence durations | 20s, 20s, 21s |
| Complete security lane | passing; no timing ceiling |
| Nyquist compliant | yes |

Final reconciliation uses the staged 2026-09-11 proof set without reinterpreting historical audit samples: all four focused Plan 73-21/22 selectors passed with non-zero selection, all three unchanged `mix ci.evidence` processes passed below 60 seconds with identical counts, and the complete unchanged `mix ci.security` lane passed.

## Validation Audit 2026-09-11 — Execute-Phase Post-Hook

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Phase requirements green | 6/6 |
| Completed plans mapped | 23/23 |
| Acceptance-bearing tasks mapped | 49/49 |
| Nyquist compliant | yes |

The post-execution Nyquist capability rechecked the committed Plan 73-23 result set and found no validation gap requiring a new test or implementation change.

## Validation Audit 2026-09-11 — Current-Review Correction

| Metric | Count |
|--------|-------|
| Review timestamp | 2026-09-11T19:23:38Z |
| Current blocker findings | 6 — CR-01, CR-02, CR-03, CR-04, CR-05, CR-06 |
| Current warning findings | 1 — WR-01 |
| Blocked requirements | 3 — EVID-02, GOV-01, GOV-02 |
| Nyquist compliant | no |

The refreshed review supersedes the earlier green-only seal with seven uncovered counterexample families: CR-01 twin-field governed-inventory omission or substitution; CR-02 unmodeled Mix argv zero-test modes; CR-03 a skipped `jobs.security` prerequisite; CR-04 attribute-free or malformed task disappearance; CR-05 SUMMARY-add boundary omission; CR-06 merge-commit changed-surface omission; and WR-01 multiple-include plus include-overrides-exclude semantics. Historical audit rows remain unchanged, and later repair evidence must follow this correction before final disposition.

## Validation Audit 2026-09-11 — Plan 73-26 Current Proof Staging

PHASE73_STAGED_PROOF

The current source-bound proof is staged without changing `status: gaps_found` or
`nyquist_compliant: false`. Final validation remains pending the append-only closure step.

<!-- phase73-reconciliation-proof:start -->
```json
{
  "acceptance_task_ids": [
    "73-01-01",
    "73-01-02",
    "73-02-01",
    "73-02-02",
    "73-03-01",
    "73-03-02",
    "73-04-01",
    "73-04-02",
    "73-05-01",
    "73-05-02",
    "73-05-03",
    "73-06-01",
    "73-06-02",
    "73-07-01",
    "73-07-02",
    "73-08-01",
    "73-08-02",
    "73-09-01",
    "73-09-02",
    "73-10-01",
    "73-10-02",
    "73-11-01",
    "73-11-02",
    "73-12-01",
    "73-12-02",
    "73-13-01",
    "73-13-02",
    "73-13-03",
    "73-14-01",
    "73-14-02",
    "73-15-01",
    "73-15-02",
    "73-16-01",
    "73-16-02",
    "73-17-01",
    "73-17-02",
    "73-18-01",
    "73-18-02",
    "73-19-01",
    "73-19-02",
    "73-20-01",
    "73-20-02",
    "73-21-01",
    "73-21-02",
    "73-22-01",
    "73-22-02",
    "73-23-01",
    "73-23-02",
    "73-23-03",
    "73-24-01",
    "73-24-02",
    "73-24-03",
    "73-25-01",
    "73-25-02",
    "73-26-01",
    "73-26-02"
  ],
  "captured_at": "2026-09-11T22:20:30Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 26590,
      "exit_code": 0,
      "output_sha256": "63efcdfad52b5deebe31be118516c2879ebfa303e2d3b6c7639717145039ca85",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 25486,
      "exit_code": 0,
      "output_sha256": "310629c314a0d53c5c2a88c1c4afabe2c9b1b73e7b43bb44d5183944e477b1a3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 28991,
      "exit_code": 0,
      "output_sha256": "c396e57c47f0735471d6ac0e10a0c059fd407a9d7b5ec00986b801a18c9429d6",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1623,
      "exit_code": 0,
      "output_sha256": "9dc342a6f7fbf74826cb36a1d85171d35ed569fc8160025ad67c8f62b3ddcb10",
      "summaries": [
        {
          "excluded": 62,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1964,
      "exit_code": 0,
      "output_sha256": "d5e2363de002a72786f196f3fdf6375d9802601968045e9b98f389f66be66472",
      "summaries": [
        {
          "excluded": 51,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3065,
      "exit_code": 0,
      "output_sha256": "4ad17ff758077882ada07bc085ecd705bd56ec6de859941d1a4417639fcb489e",
      "summaries": [
        {
          "excluded": 50,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 3986,
      "exit_code": 0,
      "output_sha256": "2da7dd05ef3a1b09ecad612666a39b838449849a67085e40758523be517c267a",
      "summaries": [
        {
          "excluded": 60,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 3876,
      "exit_code": 0,
      "output_sha256": "d13cf11b516646ba7e911e58992167f43241f79cd0000f9810b7442bfd9bec29",
      "summaries": [
        {
          "excluded": 61,
          "failures": 0,
          "tests": 2
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "0ce52de9086df12894382683c0a41e8a82c3483593be0cc7090510faf796830d"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-24-PLAN.md",
      "sha256": "ed8c713aeb34af4a3538d2d11b3427e36264019095deefa8b582c3c0d2ad32f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-24-SUMMARY.md",
      "sha256": "fdc8e50d0bc425419aa3c669b5aaeccb6c05e7a1a0fc6a97ab75bbb5ddcbc257"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-25-PLAN.md",
      "sha256": "933f5e52a2988ea47132e28339d63ea39f2c2106fb87932c6ad02778f7ea865b"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-25-SUMMARY.md",
      "sha256": "572247fc6a5fcfe2f0411dc040a534286f5c1d2a7dfab0dd526f9b7b731f442f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-PLAN.md",
      "sha256": "5c8cb97358a0811d603e2fbc0e36290b0177c6ab96d53c497e07d6339a5af99e"
    },
    {
      "path": "mix.exs",
      "sha256": "b2afd5193ec1c54dec9777f989efa0f4524a2777a8c4ac3931b4d4af27ebe50d"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "107e178242014b7b2e84adddd25f2ce0a2e9e480109911eae9542caf7828d7f6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "28258bd1d8ad350f16607149d8f97ae29eb8caac7f8a71163e4829da50edfb3c"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "a1cc9cb0b69ade837a5169c615e7eb1e779eb298c27363b255e87b5f7f346f62"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "9b73b8cbe4f9ec126528836e10a1af2e0ad7f4fcdae50a2ea4fd81dcb5786b92"
    }
  ],
  "proof_set_id": "phase73-8f3da8af3cd49bac",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 143094,
    "exit_code": 0,
    "output_sha256": "288e9fa0fd2687cd82bed6d34fcc34c65d330a807144c3b2e69f1d06e399f8c2",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 4
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 1
      },
      {
        "excluded": 3,
        "failures": 0,
        "tests": 9
      },
      {
        "excluded": 4,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 7
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    ]
  },
  "security_constituents": [
    {
      "command": "test test/conformance/sp_conformance_test.exs test/mix/tasks/relyra_conformance_test.exs --only conformance --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      }
    },
    {
      "command": "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 4
      }
    },
    {
      "command": "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      }
    },
    {
      "command": "cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 1
      }
    },
    {
      "command": "cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
      "summary": {
        "excluded": 3,
        "failures": 0,
        "tests": 9
      }
    },
    {
      "command": "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
      "summary": {
        "excluded": 4,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 7
      }
    },
    {
      "command": "cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    },
    {
      "command": "cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    },
    {
      "command": "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 9
      }
    },
    {
      "command": "cmd mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/login_trace_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    }
  ],
  "source_digest": "sha256:52b09d8a9f43cdaeaafd5569888b3f11c8916f1f2feb1db367311d1bb95604e5",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

| Metric | Current staged result |
|--------|-----------------------|
| Proof set | `phase73-8f3da8af3cd49bac` |
| Focused owners | 5/5 positive |
| Mandatory evidence | 3/3 unchanged runs; 116 tests each; 26590ms, 25486ms, 28991ms |
| Security composition | unchanged `mix ci.security`; 13/13 positive constituent summaries; 143094ms |
| Nyquist compliant | no — staged proof precedes final reconciliation |

## Validation Audit 2026-09-11 — Plan 73-26 Final Reconciliation

PHASE73_FINAL_RECONCILIATION

| Metric | Final result |
|--------|--------------|
| Proof set | `phase73-8f3da8af3cd49bac` |
| Phase requirements green | 6/6 |
| Completed plans mapped | 26/26 |
| Acceptance-bearing tasks mapped | 56/56 unique owners through `73-26-02` |
| Focused repair selectors | 5/5 positive |
| Mandatory evidence | 3/3 unchanged runs; identical 116-test vectors; each below 60 seconds |
| Security composition | unchanged `mix ci.security`; 13/13 positive constituent summaries |
| Current blocker findings | 0 high/critical; CR-01 through CR-06 closed |
| Current warning finding | WR-01 implemented and closed |
| Nyquist compliant | yes |

The complete owner table above exactly equals the repository-derived task set stored in
canonical proof `phase73-8f3da8af3cd49bac`. Final validation follows the preserved open
correction and staged proof rows; it does not reinterpret or overwrite any historical audit.

**Approval:** validated from the same source-bound proof embedded in both reports. No
manual, absent, duplicate, extra, plan-inconsistent, or zero-test owner contributes to the
26-plan / 56-task result.
