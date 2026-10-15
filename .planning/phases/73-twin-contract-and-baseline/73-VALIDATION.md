---
phase: "73"
slug: "twin-contract-and-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
revised: "2026-09-26"
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

## Validation Audit 2026-09-24 — Current-Review Correction

The later review reopened CR-01 through CR-07. The prior validated record is retained as
history, while live validation remains `gaps_found` until each repair is staged and the
non-recursive mandatory replay passes.

| Finding | Current state | Closure evidence |
|---------|---------------|------------------|
| CR-01 through CR-07 | blocked | Plans 73-27 through 73-30 and current mandatory replay |

Nyquist status is false while any high-severity finding remains open. Historical 73-26
closure rows remain archival evidence only.

**Approval:** validated from the same source-bound proof embedded in both reports. No
manual, absent, duplicate, extra, plan-inconsistent, or zero-test owner contributes to the
26-plan / 56-task result.

## Plan 73-30 — Current Proof Staging

PHASE73_STAGED_PROOF

The newly captured canonical proof is staged after the current-review correction. Live
security and validation state remains open until the mandatory reconciliation replay passes.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02"
  ],
  "captured_at": "2026-09-24T04:30:46Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 38977,
      "exit_code": 0,
      "output_sha256": "f940e52413e19d66d24d8b74cbff68f139d7cc7d7fdf5e90e94af45f02eb74a7",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39661,
      "exit_code": 0,
      "output_sha256": "7a242848a213fcfa5477f7de454e0bf70b8161b37eaf538bd4717a0ef017c07b",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 41466,
      "exit_code": 0,
      "output_sha256": "66391cafe80bace5b20516f8814bb80f365b123743a78f394a0bd93d6b97e0d9",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1406,
      "exit_code": 0,
      "output_sha256": "a672e8ec3deaed18c1392e07aaab7dd13ea7b4cef17c17d19fa914d0a2514b52",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1564,
      "exit_code": 0,
      "output_sha256": "5574a8de06fbc83ea8bc6bda02c53400ec1526fdde16b5ae49166b946a630de5",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2726,
      "exit_code": 0,
      "output_sha256": "d12d7c41907e2a3b3112ab254e4ebe500f27fc28d42b64ac2c7e3ade03c6bc6d",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4840,
      "exit_code": 0,
      "output_sha256": "5ec665a3f653c1ba8e2e69b59f14444dd8042f972bc7a9f0eb6aecf958303be7",
      "summaries": [
        {
          "excluded": 64,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4559,
      "exit_code": 0,
      "output_sha256": "382fe994724881fa4c1494043a1bbdb4a916a97b3112f2b0dda22663092cc7ac",
      "summaries": [
        {
          "excluded": 65,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 955,
      "exit_code": 0,
      "output_sha256": "2214842ed0286b42e16d61e9bceb3322ca4ad74bacb4e438371d1679c2f42c93",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 819,
      "exit_code": 0,
      "output_sha256": "8cc3d07385a412b229f3eb90efdc207e1c043a2bc3696b0419cfc08af131ad6b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1288,
      "exit_code": 0,
      "output_sha256": "ff3d8ee37eb9724d5a3862a4725701922f4e08dca3efeefa540348f376de33f6",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1460,
      "exit_code": 0,
      "output_sha256": "706003ea54f02f6e8f8b0d66bdbe027ab5512eaec95cb8aeeff9c90d4f6897ec",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 3790,
      "exit_code": 0,
      "output_sha256": "503a17b3faafc0e62319c5e38d517ed6d43058ecd8e5f0a867ae7f5c3e226f0c",
      "summaries": [
        {
          "excluded": 64,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 3836,
      "exit_code": 0,
      "output_sha256": "9cafbe55750e95243523ad2675d1170f6394d390e3b09547c335da7fbab4d5d6",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1045,
      "exit_code": 0,
      "output_sha256": "9ba07832bb4917e4d50e4d7dfcd4489aac7514d3027043619121de71585ad80a",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1351,
      "exit_code": 0,
      "output_sha256": "dea93f27d048c948a27e314895f8161d30b6eeaa2dbfbb623ff49bf914cf40bf",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "e96ed1b4baf41f3dac929e35b423686deb3f90bc150bb5611f60518c2a81b340"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "8ee29befe29b02b8d28b8628d303c30e6a3ce587ba773bc56544ff98e2a127f6"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "7a6713a0da819da2405711cc23e379d7e0d3a790ccaa0bb5e5ed99ade784f181"
    }
  ],
  "proof_set_id": "phase73-ee03f81466f07b09",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 143778,
    "exit_code": 0,
    "output_sha256": "3a5c308fa8e4ce49ad612cb7ea019d2d90a006c66b2fc7fc6f883b41769de170",
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
  "source_digest": "sha256:04d52027714bf48aea66382540480802c9ed81f91526ce4f09d71c29e8950a99",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

| Metric | Current staged result |
|--------|-----------------------|
| Proof set | `phase73-ee03f81466f07b09` |
| Focused owners | 13/13 positive |
| Mandatory evidence | 3/3 unchanged runs; 122 tests each; 38977ms, 39661ms, 41466ms |
| Security composition | `mix ci.security`; 13/13 positive constituent summaries; 143778ms |
| Nyquist compliant | no — staged proof precedes final reconciliation |

## Validation Audit 2026-09-24 — Final Reconciliation

PHASE73_FINAL_RECONCILIATION

| Metric | Final result |
|--------|--------------|
| Proof set | `phase73-ee03f81466f07b09` |
| Phase plans mapped | 30/30 |
| Acceptance-bearing tasks mapped | 64/64 unique automated owners through `73-30-02` |
| Focused repair owners | 13/13 positive |
| Mandatory evidence | 3/3 unchanged runs; 122 tests each; 38977ms, 39661ms, 41466ms |
| Security composition | 13/13 positive constituent summaries |
| High and critical blockers | 0 |
| Nyquist compliant | yes |

| Acceptance task | Owner |
|-----------------|-------|
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |

All seven current findings were closed against proof `phase73-ee03f81466f07b09` after the real
`mix ci.phase73.reconciliation` replay validated the checked-in record and reran the focused,
evidence, and security inventories. Historical audit rows and the single visible medium threat
T-73-12 remain unchanged.


## Validation Audit 2026-09-24 — Plan 73-31 Current Reconciliation

Refresh chronology: the tracked inventory covers every current acceptance task through Plan 73-31. The canonical proof below passed validation and mandatory fresh-process replay.

## Validation Audit 2026-09-24 — Current-Review Correction

Plan 73-31 current refresh; earlier September 24 audit records remain preserved.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02"
  ],
  "captured_at": "2026-09-24T13:17:19Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 53816,
      "exit_code": 0,
      "output_sha256": "68d1c26c3320b67edcb6f9a68f79a1dcbcb65972ba4168c832eee5aed88bf871",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 53930,
      "exit_code": 0,
      "output_sha256": "b64a9cfd86a7e970a1f462661093535d711afac2e532d99d0b60fe08dfab8b6e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 53488,
      "exit_code": 0,
      "output_sha256": "4ca1673a118e9c33e033255ea8f9973f2ed57d146961c9762ce9a0f86c58b261",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1681,
      "exit_code": 0,
      "output_sha256": "f9091efdbef76a5f9dcd3844e49c43108f44abe4d34844c29aae56e26e52c440",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2016,
      "exit_code": 0,
      "output_sha256": "f3accce6f80c4b80d24493bb8a8838408321337fc2f9953efec74208c73ba977",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3285,
      "exit_code": 0,
      "output_sha256": "60e5e9cdffea6a277bb002df7d801a8eb442c9e3a575ebac90c6c36ac6b4168f",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 5300,
      "exit_code": 0,
      "output_sha256": "2843b62ba4db479540d6cbb98a5b0dab284a2b02e04cd6c094553ad404ae64fd",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4558,
      "exit_code": 0,
      "output_sha256": "fbef545ed305222055570bacb4b6148cf682f7349ad5401d13b3c900d9b98689",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1301,
      "exit_code": 0,
      "output_sha256": "d4bfcc6e9b2316c7e125d13af7d3ebdb6395ac80f42a80216ac8eeb67c825fab",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1306,
      "exit_code": 0,
      "output_sha256": "1f182d74cb0ef4af9202a64036024719516b79c72b8b1880bf3544d56262832e",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1418,
      "exit_code": 0,
      "output_sha256": "9f3bec9ed6305539fd15bd281012eb89ba124db9230e352dd466b62436474e6d",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1464,
      "exit_code": 0,
      "output_sha256": "b392f838409944be4bb8f418e3fc507bf5f4f2ebc74bcf95e16879b4c5f0d6fd",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 3354,
      "exit_code": 0,
      "output_sha256": "50b3dcf17edad3d262d529d5ad16368e771b2f505f824acb9c2bb06b8391a50f",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 3590,
      "exit_code": 0,
      "output_sha256": "6d0f41328f0416af007fd50df44b72612332e64b30580e83160d5e0ef7c8c582",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1295,
      "exit_code": 0,
      "output_sha256": "b2634a5ba776b1236fda1632444b76455a939a436f5d5e99c90f533c50658a76",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1367,
      "exit_code": 0,
      "output_sha256": "0356f18c12802f6805e63013077958e20ade46769ac614d0132128cf54f0d9d0",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 1684,
      "exit_code": 0,
      "output_sha256": "0c2d2cdec0a4e9a3ef1c2565d6bd024e6598e93276188547d0e4942b2a9f3800",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 4639,
      "exit_code": 0,
      "output_sha256": "87f4d667d4c069ca0abe026001fb5fcba61da9b6d216211ebe6cb39ba32202e7",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "9dc6f2286916246d0d005d371b327e73fac37dc79d4c22b475a1c7c5c5eeb657"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "a5709822901f688b4b48ff8522349685c90b4e25968e4fd46b2724269fd435a1"
    }
  ],
  "proof_set_id": "phase73-2fc3c2eaf9548744",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104348,
    "exit_code": 0,
    "output_sha256": "b52913e34c6ace2f902d23ec5c63b19f6af761a606b523617f3492bafdcf6f54",
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
  "source_digest": "sha256:71750cf9d7e6ee9d541645682cb2a39c1309119395ba76e3ce4f28f3fc10ecdf",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

## Validation Audit 2026-09-24 — Plan 73-31 Final Reconciliation

PHASE73_FINAL_RECONCILIATION

| Metric | Final result |
|--------|--------------|
| Proof set | `phase73-2fc3c2eaf9548744` |
| Phase plans mapped | 31/31 |
| Acceptance-bearing tasks mapped | 66/66 unique automated owners through `73-31-02` |
| Focused repair owners | 15/15 positive |
| Mandatory evidence | 3/3 matching runs; 124 tests each; 53816ms, 53930ms, 53488ms |
| Security composition | 13/13 positive constituents |
| High and critical blockers | 0 |
| Nyquist compliant | yes |

| Acceptance task | Owner |
|-----------------|-------|
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |

All seven closure references use current proof `phase73-2fc3c2eaf9548744` after `mix ci.phase73.reconciliation` validated and replayed the checked-in artifacts and command inventories.


## Validation Audit 2026-09-24 — Plan 73-32 Current Reconciliation

Refresh chronology: current source-bound evidence covers all 32 tracked plans, 68 unique automated owners, 17 positive focused selectors, three matching successful evidence vectors, and all 13 pinned security constituents.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02"
  ],
  "captured_at": "2026-09-24T15:29:58Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 50986,
      "exit_code": 0,
      "output_sha256": "8e575f5117b76c18fa8bb3a1f27a35d9cb2ad8e5f9b7ccfc49fea8b8c102b4fe",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 52467,
      "exit_code": 0,
      "output_sha256": "e693bf469e1f9870184b0815c829a6d90afbe6f6391ada5e6cf425b60103628a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 58389,
      "exit_code": 0,
      "output_sha256": "141bdb514ead80476e321329cff3bf66ca114a9b3d38824e1f393fb68d07888a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2067,
      "exit_code": 0,
      "output_sha256": "4887fc8614d019ab45c16bb78dd0effb246a5dffda68f8ec6286a6a0935fa3c6",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2596,
      "exit_code": 0,
      "output_sha256": "9787bd2f3bfb6c9ce918fe730ab7fecf6468b571f64c3c89eb5027f219265595",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4191,
      "exit_code": 0,
      "output_sha256": "5e309dd87dc6e79506c7ead9e8950c295296d94d61449bd80975b45f65d4b4ae",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7510,
      "exit_code": 0,
      "output_sha256": "06ca2776e73a8a3adb90892ac1c49ffbe1bb230eb6368dbf5496530baa2f6206",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6536,
      "exit_code": 0,
      "output_sha256": "e0a485cc39443dd725d1a54a4932c3878c30705931b9ed81290266330d8d5ad3",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1662,
      "exit_code": 0,
      "output_sha256": "eae6f19f5b42aa7f63386ec126d4cba2096e7b5a010825219a37faa9203d668b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1512,
      "exit_code": 0,
      "output_sha256": "81d9d8532fbc4a12e17ddba5c3b45f71d336503dbd49a0ca01c40c6779dceb5b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1758,
      "exit_code": 0,
      "output_sha256": "d1057beb03f2a519b236dc622390847d9d1fccf811e43d2d12714a9bab4394f3",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1926,
      "exit_code": 0,
      "output_sha256": "122f482336b2846a3e20ac05010073ee59356bd0aea3b493774d6d8d5b28f0b9",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5157,
      "exit_code": 0,
      "output_sha256": "596cef6ee28bdadfef7aaf229d86aa3fbf9f2da6deaf8cb0a92a935154768b2a",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4624,
      "exit_code": 0,
      "output_sha256": "2f9651449ef71e38c76fc892e862250cda0eb2643f4393cb1ee0bba702c3fd56",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1644,
      "exit_code": 0,
      "output_sha256": "3e3f05105a7549473ab1c13fdf8844abb967beed3bcfdc71969127d48c3e57ad",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1631,
      "exit_code": 0,
      "output_sha256": "3f527a436dd79fed887d81465f0dd610d50c744984359ead464ac5b0c5cb414a",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2218,
      "exit_code": 0,
      "output_sha256": "d3c37f0fcd2e9ac6b1ef4cbb9c42f463ab0047705fb300ceb6781da09f27e495",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6793,
      "exit_code": 0,
      "output_sha256": "c5c46613a94c3edb135d05a16c0d2e27e96055ec157105f0102efeabc8db5cdd",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 25686,
      "exit_code": 0,
      "output_sha256": "652c43d97d7550213a85971f1671dd5c2565742f8ac7d66908bf1b0aa7f1a6bb",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2105,
      "exit_code": 0,
      "output_sha256": "b414f581fb4c9a24a8edff81b9725c301e418479ecd6ed115acfd29544c709e8",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "34d8d4b99756413b190a06e5c2c2ebbe1125f9f3156023a0bb58f02158ccdfe4"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "048d96d9ab0694a38a176de6122af29a7f0bc26e0a3654272d8984df1aea83b8"
    }
  ],
  "proof_set_id": "phase73-e76f4d404296add9",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 105696,
    "exit_code": 0,
    "output_sha256": "566c2ba5846b6d7a1562a695e1044ce3de13dff94d0eb2d4809f4a94bbe48861",
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
  "source_digest": "sha256:f3d5d9905300267690652c266472b1b5e88b621989940283d4149dec414cfdf3",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION

| Metric | Final result |
|--------|--------------|
| Proof set | `phase73-e76f4d404296add9` |
| Phase plans mapped | 32/32 |
| Acceptance-bearing tasks mapped | 68/68 unique automated owners through `73-32-02` |
| Focused repair owners | 17/17 positive |
| Mandatory evidence | 3/3 matching runs; 125 tests each; 50986ms, 52467ms, 58389ms |
| Security composition | 13/13 positive constituents |
| High and critical blockers | 0 |
| Nyquist compliant | yes |

| Acceptance task | Owner |
|-----------------|-------|
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |

Current proof `phase73-e76f4d404296add9` is the source-bound basis for the latest report record.

## Validation Audit 2026-09-24 — Plan 73-33 Current Reconciliation

The actual Phase 74 planning lifecycle and isolated Phase 73 active and ready-for-verification fixtures pass the mandatory owner.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-24T18:13:09Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 41203,
      "exit_code": 0,
      "output_sha256": "68c65187fe6eff0161d8519cac4e13bd634e84d3a58ea070e6122189357f9deb",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38631,
      "exit_code": 0,
      "output_sha256": "75b7416f25884e0e77e1c8b1df6b4a39482c252ff9b0d60d79deb3ace333740e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 32368,
      "exit_code": 0,
      "output_sha256": "27a20581e9f02954d1b556a70049cae31f267f481b665b77d8ed124ad0e9953e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2270,
      "exit_code": 0,
      "output_sha256": "49e4755a89c6407c417b38be3282ecbd16948bce819b2af88416b7508cd63ed1",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2696,
      "exit_code": 0,
      "output_sha256": "625047f7e671904c5f30406a94441165387bbeccd34b4f4a0574a6f7f9c2cd23",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4212,
      "exit_code": 0,
      "output_sha256": "50a0451bf672960ff9e5ecb0136b4519875312389a3e421c47834984e4b26aff",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7344,
      "exit_code": 0,
      "output_sha256": "5bc8fe936e468bb9d6c69a66c5ea010e7b572f278925ebccd02016c5e196541b",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5992,
      "exit_code": 0,
      "output_sha256": "6e664dc23717e0d1d8705b921012ede29fd280810af89860752efa0f782a7f96",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2331,
      "exit_code": 0,
      "output_sha256": "c4b46661f277c9dbcad2cd8c26887e9d2d3565f16126c9b864acfcb6f52837dd",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2233,
      "exit_code": 0,
      "output_sha256": "8acb078befe74c14833ab9876c204d78e0a24dc9f9f3116b0999d5ac018dbd80",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2004,
      "exit_code": 0,
      "output_sha256": "7152ad7e722578e46a82cfedace2101986354fefc0104d123b114790811d3192",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1927,
      "exit_code": 0,
      "output_sha256": "f7267f178f5ff954a5f77a6e256757b933dbb2b449dd26e4335379e21c9c969d",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5032,
      "exit_code": 0,
      "output_sha256": "eb71e6676b05d028c55199fda269b2953943a6ae495ab2a8199e7d2e03ed1b58",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6629,
      "exit_code": 0,
      "output_sha256": "1120e85a16778052c2da74f30bef815e3bbced89507a82b472841b257d579223",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1845,
      "exit_code": 0,
      "output_sha256": "e0e453b43bd57daa54ab81f2a645ccc05afc32ffb060364b9e3eb0198d06dacf",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2799,
      "exit_code": 0,
      "output_sha256": "298432ad4c10dcd49ec76f839435ad7ccc27ef1cfb97fa2e793cf3ea581a33e0",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2515,
      "exit_code": 0,
      "output_sha256": "ba8d2b5980cf4187170ff8ddcad275abb603beabaa6778abffa6c81302191c6c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7141,
      "exit_code": 0,
      "output_sha256": "eb989547756d15dec12b2efc66eb438366b77e10272cd13f23bf8b0dd4d4d5df",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 2571,
      "exit_code": 0,
      "output_sha256": "b27bf6e9ede38491d3ea4ff7f4dd76451bab12ff3031f75915bf521245cee2ad",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2550,
      "exit_code": 0,
      "output_sha256": "057d217438e466476d56d812f3d36f2a71eba380289b636c9f8908592e9e3f7d",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2659,
      "exit_code": 0,
      "output_sha256": "97058a06ad01d128284634adf528beea90baa4aa03af31bf71783e1e98d8136f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2641,
      "exit_code": 0,
      "output_sha256": "3e3acac7df724b0d89090cff24a7eb57fae27c9fbf92325556894c6d0598be60",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "f8807ee4598c0948f4629c55347c82fb903b2b855104ecc8b9d6a66df324f93f"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "08a246b4b8816f503aa7a6189df1421dd57ae9230987b5aeea41283050cb9969"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-75f9745703c89de4",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 144696,
    "exit_code": 0,
    "output_sha256": "64e9816e10ac8a37086c5b938217d4068f436e3e868a412649429f88df4096db",
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
  "source_digest": "sha256:8574e598fc7b225b258a6c33ba27abf0e126a1a60adae0704d3c3958cf987201",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION

| Metric | Final result |
|--------|--------------|
| Proof set | `phase73-75f9745703c89de4` |
| Phase plans mapped | 33/33 |
| Acceptance-bearing tasks mapped | 70/70 unique automated owners through `73-33-02` |
| Focused repair owners | 19/19 positive |
| Mandatory evidence | 3/3 matching runs; 127 tests each; 41203ms, 38631ms, 32368ms |
| Security composition | 13/13 positive constituents |
| High and critical blockers | 0 |
| Nyquist compliant | yes |

| Acceptance task | Owner |
|-----------------|-------|
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |

Current proof `phase73-75f9745703c89de4` is the source-bound basis for this report record.

## Validation Audit 2026-09-24 — Active Main Reconciliation

The merged main checkout passed the mandatory evidence lane with Phase 73 active. The completed-73/current-74 planning relation also passes in an isolated authoritative fixture.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-24T19:27:01Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 52208,
      "exit_code": 0,
      "output_sha256": "8b199d556f8ec6f50e7305a7a4859199cadf68f4ddf0743aa1d0c37d62a008f1",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 51104,
      "exit_code": 0,
      "output_sha256": "95e31a2c38a9f21d93a6fb442a0d09d760a32ee508a58c66539c72ce98424e22",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 50273,
      "exit_code": 0,
      "output_sha256": "fb092c37c29c8a010eee987d8465340fa7f8e625f406978b5ba5f7a25ad7db68",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2203,
      "exit_code": 0,
      "output_sha256": "0a2c638d77f56f1ce75df1d5fe47e0f1f461a3325931e1cf39ef59c0f96832e1",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2584,
      "exit_code": 0,
      "output_sha256": "c1b82cf46d7c8a0b90e4bf3545c6799f55b5068af1b23fe1a24631e1e88009b5",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4441,
      "exit_code": 0,
      "output_sha256": "bec16212c929594ce9ec3ab08ce940f9eba8b207daca6fe9ee9ce09a350d2030",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 6876,
      "exit_code": 0,
      "output_sha256": "549a5beef30a75fb51eabb50a6cb35d2e9902ec7ad71abee9e4562ae4b3fbc20",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6267,
      "exit_code": 0,
      "output_sha256": "4ffd8dea22ae56a1ec09317ce30cac9d454d1f5fcf8587473b13a914c196ebbd",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1692,
      "exit_code": 0,
      "output_sha256": "23fb792e30ffc28affbd32799a13565c2e7ba094ddeae510ba7d9bae12824123",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1514,
      "exit_code": 0,
      "output_sha256": "2723cab3ecb6005e6da05f0b4de631af73726069bed6166073ecd9bbc1d50bda",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1764,
      "exit_code": 0,
      "output_sha256": "aa1ce67b1ff48750eca08822db802437a2a6a897437e384568f139ca55af8400",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1794,
      "exit_code": 0,
      "output_sha256": "0b3d09ede733371f43456f1ef64304575ff1be3cb9572114514d66c403869759",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4243,
      "exit_code": 0,
      "output_sha256": "bfcfed8b7a06b38663096fb451b6e07e499b122ca8999930f3db6ad037fdbd09",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4791,
      "exit_code": 0,
      "output_sha256": "c326055f6353074219f5b6bf2b1f1dc01cbb091f5550b4161bdd6dccf58264ce",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1728,
      "exit_code": 0,
      "output_sha256": "f8d8dabae272e44286c5fc2720f121cc60606e34a74590babbe5ccfdd7883d2d",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1666,
      "exit_code": 0,
      "output_sha256": "4f820c6c144d2447f31e473d509f3509549ae40d66d88b88b8d0691fa22e0a46",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2289,
      "exit_code": 0,
      "output_sha256": "e9e9c8cb40fe4f9ca7ef4c2fc7a1e97e4c35609906aa701f8dcc5556c5a95c3e",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5971,
      "exit_code": 0,
      "output_sha256": "3147669a936403f8965b56ea627ff7892ae7c7f2d197e6491f709ea88fa93399",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 19610,
      "exit_code": 0,
      "output_sha256": "2f5d39128d315efef2a25ad572759a7ff39de0fef647c22e32c3038a5ed88524",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2194,
      "exit_code": 0,
      "output_sha256": "900abf5ed11057260fc2b3e2364d1f34924566790331b384f0d9f5b6b0e303cc",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2178,
      "exit_code": 0,
      "output_sha256": "7a373169e286dce944520fc813f47c54b998b718f0ff479d0fc35790e9fa0a7f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2223,
      "exit_code": 0,
      "output_sha256": "a64fe34ac4beda59edf6b56995c8cc6ba4a6d411acc86c9eb77279a85f296bae",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "551964c6d8667154f06db632e479e9f449ce7597b87b3e4e4adcfb725764fff1"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-c5d6c300740e329c",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 141726,
    "exit_code": 0,
    "output_sha256": "53ecbd409cef22f04ddfab32d33f7d758d716e89a9aee356d552022c9a06c93e",
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
  "source_digest": "sha256:c3032c796563369580aa50cb2196503588a933ee400332c6e543637307e7e8dd",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION

| Acceptance owner | Type |
|------------------|------|
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |

Current proof `phase73-c5d6c300740e329c` is the source-bound basis for this complete 70-owner automated map.

## Validation Audit 2026-09-24 — Post-Transition Automation Replay

| Metric | Count |
|--------|-------|
| Phase requirements mapped | 6/6 |
| Completed plans mapped | 33/33 |
| Acceptance-bearing task owners | 70/70 automated |
| Current UAT checkpoints | 84/84 automated |
| Focused lifecycle selector | 1 passing |
| Mandatory reconciliation replay | 1 test, 0 failures |
| Nested evidence and security constituents | all required owners passed |
| Phase 73 Nyquist gaps | 0 |
| Escalated/manual-only checks | 0 |

The fresh post-transition `mix ci.phase73.reconciliation` replay passed after restoring the
exact Phase 74 planning lifecycle in STATE. The replay validates focused owners, three
independent evidence runs, and the unchanged mandatory security inventory. All validation
remains deterministic and suitable for the required CI lane; no human-only completion gate
was added.


## Validation staged source refresh — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-25T02:32:59Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 27726,
      "exit_code": 0,
      "output_sha256": "53a01eef3b9d3d478809e602bd1260cb47e9128c866a28106cf51a17a57a499c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39358,
      "exit_code": 0,
      "output_sha256": "3be234570c4a252b8573e611a8b93aefc50fc452dc2277e716ec79e77a24fc39",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 42992,
      "exit_code": 0,
      "output_sha256": "af21f8e7a107700799da79d98da9d40151e98a720510933aa49cf979908dab5c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2304,
      "exit_code": 0,
      "output_sha256": "701a56808efa1d56a92481d59e60f03667233fe171d22b17f74364d5c2c393e6",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2299,
      "exit_code": 0,
      "output_sha256": "adb07c7f5dd95d3b86af7dfaa24fd6b48153e222741a6190eff13a8b53076623",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3617,
      "exit_code": 0,
      "output_sha256": "28cd475100fb89a13c86626daae1a994ccc725a8a3c5d420655e911ffffe72b6",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4545,
      "exit_code": 0,
      "output_sha256": "54fbebf7901897d62b1e95e8c7621affa8ee3f04cff0e27a000c6d9da74a3e22",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6336,
      "exit_code": 0,
      "output_sha256": "ee59552ec19ad9b33e1e9d629f61c54f4c5ee2118cbd2fe99d3215e9c1f0e206",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2235,
      "exit_code": 0,
      "output_sha256": "dd8b73ef6d9d9d6726706e2124a3d951fd259cab0a29855adddfa69adfe0165f",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2020,
      "exit_code": 0,
      "output_sha256": "c2ef8fbda7129d58832007e6c4094c2f4af791cd81be93847ba2529f2dafa49d",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2286,
      "exit_code": 0,
      "output_sha256": "d260e3b9023f650c47625ca3cbae3541df2845a08fbb4cdf60c49bbccbf23f28",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1854,
      "exit_code": 0,
      "output_sha256": "b04108cd32bb9d8fd1fa81eb9b2ac7f905b160af1830e2b36a9bb7a1c4b3662b",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4914,
      "exit_code": 0,
      "output_sha256": "01ef72e32ad15328214dcd729c7930081ffa78ef0560bb99948cdb81ad542659",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6056,
      "exit_code": 0,
      "output_sha256": "ad7f742b18d38e9b14cb0dab145622b479df6c5bb98bb51de4e50f378bda5c0f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2911,
      "exit_code": 0,
      "output_sha256": "0f57d91701a4d24666bdd3ff322a25c9fe9a6ecca99131ae7944b6c5bb117416",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2228,
      "exit_code": 0,
      "output_sha256": "87d3ad5e9fd7bae5f35758433fea904378f84a1d134881c85720b44b85519b32",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2739,
      "exit_code": 0,
      "output_sha256": "81175654031fa2e297814ac0a3f0f3ee583086603591d083a4b90a904c9266c0",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 8321,
      "exit_code": 0,
      "output_sha256": "5f5d98de0ac948c5bd16520b610137d598fff3d74f4c182743c5c3969f630eb7",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3539,
      "exit_code": 0,
      "output_sha256": "ea9088a98b112b05d23662749d46ba1ac53de489ae100078dbeb979e3bacfd01",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 1745,
      "exit_code": 0,
      "output_sha256": "d8c0620454cf7dd5bfc7d8e41d16eeab3a4a6cca93b910b9fa1441125e988c1c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 1789,
      "exit_code": 0,
      "output_sha256": "9ce934e6f29c8b5bd74e833e74da6b2185a8723fa095d42f41906e2dcb4194d0",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 1967,
      "exit_code": 0,
      "output_sha256": "a5e8e9f6a176700a0e5ac79061779e4dbacf8a3372f6f68a078c5f30b48a5f34",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dc1def34352f26ec42e0e1cfbe4089de068d3b64879a2e8af1820bfd4d965f48"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-4c6282e831f7ae0c",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 115743,
    "exit_code": 0,
    "output_sha256": "182b975c737648a65e24a10b348f4e266939a1f7ce41dee7600f0c9ae68c99f4",
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
  "source_digest": "sha256:e863094268dfe934b9e6aecd4c46f144e7a21a60adaac5c7657fee50c3db0925",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->


## Validation final reconciliation refresh — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-25T02:40:58Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 45120,
      "exit_code": 0,
      "output_sha256": "3f06d7ddf285cbaa98aaedb2d916920011851b54884c3ac65235d32b03aa3530",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39455,
      "exit_code": 0,
      "output_sha256": "ad0a7b4e9e51a34a70438d6dc531e4ccec428de9ce2a0cb710a291056e652469",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 36102,
      "exit_code": 0,
      "output_sha256": "15257952118b14d0819bc2a41293c96936be6ac017c3283bc028bb5e02629972",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1888,
      "exit_code": 0,
      "output_sha256": "16286f93028cf14d6306a0a7135748c3ffaed2fd871687544309a9cab07f726b",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2146,
      "exit_code": 0,
      "output_sha256": "84a4623eace4e8df62e5a9dfa4d56c09910057a54b66ddba1ed605422742ba80",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3375,
      "exit_code": 0,
      "output_sha256": "6b09cb569cbb38f47d52a39d44e759b7e7b787194c90daf16a1e23b60cf421d7",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4258,
      "exit_code": 0,
      "output_sha256": "81239a7af6e019970639f918d35ec65ccb285d8902dc2dee38b7af10af343b72",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4765,
      "exit_code": 0,
      "output_sha256": "6871a83ad2c5bf3af7c9a2b289901a4565c858ad520dff6205ce72b01b3310d3",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1677,
      "exit_code": 0,
      "output_sha256": "d0bd00b224df1c5b3e3c5f7547c3d3f8ff09d7f698d95d21c91ffc4f319f114f",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2279,
      "exit_code": 0,
      "output_sha256": "17fdf4f802a3d89638cd8449df51f8d6801e559d4b9bf12ac4727c0353877524",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2779,
      "exit_code": 0,
      "output_sha256": "f3cdc17f0f70044781a6b2d8cea7b797ba4620bcda0d3ed9ac2b59856b351a02",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1898,
      "exit_code": 0,
      "output_sha256": "f654bfb60ba139f5cdf6b69d46150e1e9d4ebe943ccb64473556f309c114cf80",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4267,
      "exit_code": 0,
      "output_sha256": "9fc3f21c44d46d6cdd0c70e4bd0e3749efc4a6c91bfb058dbc6fdcb5ce08a85b",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4708,
      "exit_code": 0,
      "output_sha256": "00e44e4763c53aa4512c39bc83d17bb5932ef72c775d501553457e387098967e",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1659,
      "exit_code": 0,
      "output_sha256": "a4130fd56d9c623b1216e76eebf4d820f9e73c0bf7d625cc472652d597ffee7e",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1690,
      "exit_code": 0,
      "output_sha256": "1946fe6546d815bdbbecfccf3761604781c06ec39e0692ca4fc55040e48c4758",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2022,
      "exit_code": 0,
      "output_sha256": "1a2992ada52600dc623c2499f47505682889fa3820373576bed9c82f5e42fa91",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5496,
      "exit_code": 0,
      "output_sha256": "104360930c38786d535d1cc14a3d9428189cfb1fac076ddb85c143e9b39196d4",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3862,
      "exit_code": 0,
      "output_sha256": "d7f371c6b7e009da5b2efebbb0554b8376949509634d2169fc24321dda8c0d96",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2641,
      "exit_code": 0,
      "output_sha256": "c6d42f9d0ce2f98bc58805d8811d65d88a2173cc756000953cc4f01de618fa51",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2831,
      "exit_code": 0,
      "output_sha256": "2abf197cb3b003d007bb1caf9d8fcb9fb27e39900595bf0e8fdd243a2e4b2ad5",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2845,
      "exit_code": 0,
      "output_sha256": "3ecb56c72d0b5ec9a2fdeb09181dd32f98db2e42b43aa7ed3cf6fbdc51944e33",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dc1def34352f26ec42e0e1cfbe4089de068d3b64879a2e8af1820bfd4d965f48"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e9702593930ddd264bc5f7e4aa639de1c7ed28919128aa92a95d61333e3625e3"
    }
  ],
  "proof_set_id": "phase73-97ec1aec53d80f53",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 108335,
    "exit_code": 0,
    "output_sha256": "305b9e41a93a69856d53354719e550632451b5a037eb6b82a44375c1512d6d9a",
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
  "source_digest": "sha256:d8da0a9bc3b8a12d2ded7968eb1399bff18dc1bf2f5d41e681e934705466685d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |


## Plan 73-34 current proof staging — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-25T16:34:17Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 38671,
      "exit_code": 0,
      "output_sha256": "5a06dab95041c2fe7eda37f56b413514f9b462b422c4d962bd644ca756765102",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34650,
      "exit_code": 0,
      "output_sha256": "3e4f13bbb38393710884e41989f1f7b3e648806b4f0cc61e7e8e47d754beff88",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38339,
      "exit_code": 0,
      "output_sha256": "c513e66833547e54691c43abaf00a620b61ce2743f76dd4e2656f8c878019b86",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4293,
      "exit_code": 0,
      "output_sha256": "6ac920a2e457e1f82ee6d634c556dd0c30bd609f0d9f9082c5aed284fcd26d6b",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2619,
      "exit_code": 0,
      "output_sha256": "3c4340722b8e30050196878781786efcbfb2e5318318dbb8b547bb91215e09ec",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4132,
      "exit_code": 0,
      "output_sha256": "04931b397dac3b235da2c12b4fdd14b283807f8e3fc8a57352910ff04fca085f",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9625,
      "exit_code": 0,
      "output_sha256": "ed22d84cd28e1dc0cb4483fde7fe1626c5299a27a303869c1e0caeb8bfc353dc",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 7827,
      "exit_code": 0,
      "output_sha256": "8405c8c520ab04ec5d7b4c3c8e76396dbbfbeead5021ef4604c4f49e7336b517",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1682,
      "exit_code": 0,
      "output_sha256": "e00198a5654c1a0ee7ce14da0db142a34a39ad1424065f71d435bd39d30538c4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1643,
      "exit_code": 0,
      "output_sha256": "942caca0ad10c2d09718334e6ba5fb17ee6f665bb7816df696c2e56ee247d166",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1853,
      "exit_code": 0,
      "output_sha256": "70318eb823e377ba6ad6b69264021f3bd023d83cfa5210e3d9c61f62c3bff5b7",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1957,
      "exit_code": 0,
      "output_sha256": "508ec4e95c204d49945f9d1f114749e041f4ff13529b735f6311a43bc0c33060",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 6195,
      "exit_code": 0,
      "output_sha256": "0ec480793be01eae25e934b99889130070c347e42aafcf6bb7414a0607f45e44",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7882,
      "exit_code": 0,
      "output_sha256": "7514d00a0528448c9ced093ed3f079b568589082156ea14e0ed815ccb717e1ee",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2915,
      "exit_code": 0,
      "output_sha256": "a0f5698c46ebff4dbeffe6e0c1f3ca715aba43e81e62dce93018c114a4c9cc09",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2416,
      "exit_code": 0,
      "output_sha256": "34c3de2d551a29955b11a396141141be93c0faf17fb19d57aa26b032f766b63a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5053,
      "exit_code": 0,
      "output_sha256": "8d4f085f4e0d4fbd90406506ec6c78008f5e078a3743a676a6ed879a1dbbba47",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 8514,
      "exit_code": 0,
      "output_sha256": "1310b200f41783a26e822fa4e50c6ab58cc6cd552010e1e223ebfca8052ab59c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4403,
      "exit_code": 0,
      "output_sha256": "a7509a5fb9879c0699b8d6074214fa25af91fe0443920ef1fce8ef9becdffeb7",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4538,
      "exit_code": 0,
      "output_sha256": "9e88a045973bae5c16b9795af1a4da45025657f716bda8d7012f45abd9192669",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4079,
      "exit_code": 0,
      "output_sha256": "61801e189ab3097157c13497b97da5b5357a7032eec393eb95f70ec763607452",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4151,
      "exit_code": 0,
      "output_sha256": "853719c46097a901c8116fb40d936251683bda34c4dc9e32dc25df3e14d73420",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4283,
      "exit_code": 0,
      "output_sha256": "fad943c445db882e81dcf3e294c72e95c25c57b4e34843f5a480f457f34aad2a",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1749,
      "exit_code": 0,
      "output_sha256": "b5e9e2b61214ebf2f4c93b5c811f9fb7b2db075c2ca2baa056ac3d6134b7c8a8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "ce595740cf8391aeb0c4b2331e847b3cf336ca75026148dc2777dc6ea189a8c4"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-617a876eb05a67c6",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 110713,
    "exit_code": 0,
    "output_sha256": "b2f20f46ad73a63c770975fa18a4f000488fa3638654e1ec1b84e88855a272aa",
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
  "source_digest": "sha256:f4f8af09339a52469d2c2f86ede436aee261cb419d4677f06e58856908681c2d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->


## Plan 73-34 final automated owner map — 2026-09-25

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Validation Audit 2026-09-25

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Plan 73-34 adds deterministic lifecycle and source-bound proof owners. The current proof maps all 72 acceptance-bearing tasks across 34 plans, and the mandatory reconciliation replay passed with three identical evidence runs and the full security inventory. No manual-only verification remains.


## Validation Audit 2026-09-26 — current-source proof refresh

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T01:50:50Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 25773,
      "exit_code": 0,
      "output_sha256": "d5dda485896d7860a91f7897a1dd2febb41a020cd06cd861e8e13b7723096294",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27066,
      "exit_code": 0,
      "output_sha256": "6c8df25efdfcc92e2906984a95a01c134d72e7475b7e10fa6588d08b6b8698b8",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 23892,
      "exit_code": 0,
      "output_sha256": "e22ec7fa124f62ffbdc2a6f003848b1b2733f552ee8459b29336cb718ccd2605",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2744,
      "exit_code": 0,
      "output_sha256": "ac9ced213f7fae2cfbacc7e4212d102eb6a548dd70ef7a19164dd19413f45c20",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1824,
      "exit_code": 0,
      "output_sha256": "b270714ab92b527b572dea95a41b6da9e2b4c29b876e6a47a805f92321206697",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2948,
      "exit_code": 0,
      "output_sha256": "d32b88d30a49aece2c0f3bdbb6acd8d221d994b817c3e39b2d8060b16b0ead96",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4813,
      "exit_code": 0,
      "output_sha256": "40130e7538a7df970f4df5e481353442f87d9db6d1b8d562d13d81c01d7ff731",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5039,
      "exit_code": 0,
      "output_sha256": "b818f0cda88b9aa3c7f4f53bae0a9230bdc55c3ef90e425a4e1def3de460cf03",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1233,
      "exit_code": 0,
      "output_sha256": "cedaf9dfaa61265539943c506d4d65e2fc13fe8082af7b548d8a0b41cba1678b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1086,
      "exit_code": 0,
      "output_sha256": "8e9443e8cfe7515fe6404db4d92da3352fa8b39c3e28686ca64399b32d4c4324",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1308,
      "exit_code": 0,
      "output_sha256": "f622ac8d3366ae709aafa24cc42cab40a3c859119eff301f5fac18e1d2348bf7",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1312,
      "exit_code": 0,
      "output_sha256": "bf307e6fdfaee82e45aefb048bb9e8dabce2bc9a566f2e24c6d7ebcee9e64a62",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4235,
      "exit_code": 0,
      "output_sha256": "4038fc0bb6f78f2d8459ddea2b01237ddb612d965686bce410833bf32bb203f2",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4901,
      "exit_code": 0,
      "output_sha256": "6313d38cab820191adaaf13e629b62a01bb6a4ab6f280ca19000f1a4b879bbd5",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1279,
      "exit_code": 0,
      "output_sha256": "16f165c434f0f82333bdaa9099efacc18df48c5736e64025ecd509965607ceb6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1407,
      "exit_code": 0,
      "output_sha256": "2a904e62e99864b7d043cd922a14dbe4efb12a6537874a930471ebfce4fade79",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2892,
      "exit_code": 0,
      "output_sha256": "fa1a2826dd4d965e362a3e6365ebdd7548e204e5c4f52d24a4e8d7f5fd5e5c17",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5237,
      "exit_code": 0,
      "output_sha256": "783922da7350d47789fb868f1f9c98f76ef5662427002ed9c78dac47744bc789",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4733,
      "exit_code": 0,
      "output_sha256": "0ddb0f15ec1669c770c31d1efc94ef5d8b47faafcfe36224c0a69c839c77df9c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2895,
      "exit_code": 0,
      "output_sha256": "13033f478927f2ca4f73a0e57b01c4e7e4f0abe23e4ef90574d5123e082ca7bd",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2831,
      "exit_code": 0,
      "output_sha256": "5af38ed3fea44ecbfbf4ff4accfb9dfad878f1c748a8f2eb9bde436b285c8fd5",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2937,
      "exit_code": 0,
      "output_sha256": "f6d8fda846f23fea042344382fd6cfaa5fd82dce4cc2b9126a06e2b51fe58b0a",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3064,
      "exit_code": 0,
      "output_sha256": "f128e2b4bb1591cb1bf3f1bcc1cd6a583f05620e4da9ed3e5c0161656b34604c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1281,
      "exit_code": 0,
      "output_sha256": "20c806d29019023af199ebf28ba904eed60188c635c8dba30a35f80d5d8209d4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "57c6f54b96ae7d3e8275ae2a423b67d16bfb43bf6ddfd11a1e1f8c18229d2b13"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a262324179815839",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 103972,
    "exit_code": 0,
    "output_sha256": "083c020c42297fb8223fa9b4918b82b8fd29f62a0426b6fc7e5a2fca52a31ea1",
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
  "source_digest": "sha256:553eb055dc08af8f2213e08b3870a3b0edace0a95aa8568850e484691d7b9f69",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Current-source refresh — 2026-09-26

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T13:50:15Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 40393,
      "exit_code": 0,
      "output_sha256": "75b203c8123749abd96fc1b49910948a243a872024257573f0b6c6468ca22667",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34173,
      "exit_code": 0,
      "output_sha256": "1abd7c67f09bb27d083e4efa2807ee3179f26dae55fd9d6270e6c212a4be08c3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 37214,
      "exit_code": 0,
      "output_sha256": "da5e73355daad8c4da5dee18492567c392e14bdc71eec2a824ffe5c01900b652",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4488,
      "exit_code": 0,
      "output_sha256": "fac7edeb0e53a27494bdc7eee012a88dcd0a695aa289e8255fcc324a83793805",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3373,
      "exit_code": 0,
      "output_sha256": "b2f4464dbae7e421bd03469e5045aea906d70cb5d0de7fb4db32feb9cc10744a",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5469,
      "exit_code": 0,
      "output_sha256": "bb7f93e55a00f09ee8115d5b31b7d1e179cbf1f66e652e396eea48aac9a1a034",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9711,
      "exit_code": 0,
      "output_sha256": "609e827bd04e9d7d037623d61bc0a657e592d21e9f4cb1d3d8882de7f6b8582c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8566,
      "exit_code": 0,
      "output_sha256": "5dded42f3e0801b3162eb7435b1ee02f026211f0d5dc5db798b887f7fc9a7a26",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2088,
      "exit_code": 0,
      "output_sha256": "1838ca0fdbd5fc0ecee960687af58462db932d7e35a2c5c16710ba1c2c5f72c8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1901,
      "exit_code": 0,
      "output_sha256": "05a0757701a674e1590c32a136970142a0cd5857decd2845cacb44941631841f",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2226,
      "exit_code": 0,
      "output_sha256": "e1ccd3685951c0346aa165cf352791554f2182a8ec0e3defb90e22f38c39aece",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2294,
      "exit_code": 0,
      "output_sha256": "2fe92c75d737f724d8ef8d59deaa7e79d717f239e11c4a3b1fb9d6f338a2490e",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7382,
      "exit_code": 0,
      "output_sha256": "910352519159e2d7a71f074bb2e41b89416ba917bd3cf13f007ccd88102a7a8d",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7030,
      "exit_code": 0,
      "output_sha256": "8b89cf28fcd816bac34984ff2209746c80441d32484fc081bb46aa85991627ac",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2135,
      "exit_code": 0,
      "output_sha256": "d0fca9b2fb891dc31990f634fb03d674aa495266d7ac6774b0b8184fe1d624ec",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2044,
      "exit_code": 0,
      "output_sha256": "a533dcc7e17b51a3fd386166712fa8b0c4d1dee845be311753439d356c835ce4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3559,
      "exit_code": 0,
      "output_sha256": "6276e9ec61a74a3c687797f9da9847a21df7f3d623c8fd61e4e21a5256bf4a01",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7988,
      "exit_code": 0,
      "output_sha256": "d4ff67d9a127fe1a40b48f3fb08f712b7803780cc6d672305bf192b89df00af1",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 5981,
      "exit_code": 0,
      "output_sha256": "d987aadd38135505759314713a8387ba80f3da5d53bdf40e74057753c72b1202",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4034,
      "exit_code": 0,
      "output_sha256": "4292935239a582bce846be76d86d92a64efccd1cf949706a8433f088721da5d8",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3945,
      "exit_code": 0,
      "output_sha256": "2bba8cee8dd6fe2a97cc47264e03a75325703b2374e1c6dfc62a1d80941915d0",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4272,
      "exit_code": 0,
      "output_sha256": "32b49188e6f7acc97b7f084d7047d3cc53ec50fd89ece024ae2676204662c35e",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4252,
      "exit_code": 0,
      "output_sha256": "aeb6c06772823225a2163f9474585730d39ff028e939365d040cbf64e411beac",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 2056,
      "exit_code": 0,
      "output_sha256": "b160dd5c6b0835bc512267f36ed2cf557d060a30cdee3cd556ede58f2836be49",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "9ca79825ec77335284be61d9a4a12027114ddc6ce4b64100c0d937171cd791ee"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "28a2d37b8b824a9d38863a40cc3c0805f2e7801008464eba0344b0966f8f8eea"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a3162f0b909873a3",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104233,
    "exit_code": 0,
    "output_sha256": "d9bab50870b0dd686d3c04b8a9ecbca1ceba232bb8d44a90f4bd27a93fbf51fa",
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
  "source_digest": "sha256:bdda7021aec660dbf1a6ba1e0ec1aedadee10af022659d2eac653abc4694b2c5",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

Phase 76 current-source replay validated all 72 historical automated owners, three identical evidence vectors, and the unchanged 13-suite security lane.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T15:26:44Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 29879,
      "exit_code": 0,
      "output_sha256": "9808333b99a37aeb09929cdd68d0ecd20e450146f8cca1efa0e0374826631115",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 26907,
      "exit_code": 0,
      "output_sha256": "6078e9ce42354ee776a8d9b6feaa1efd5f6e2e7a450d91f801eeab7c17cb4a10",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31445,
      "exit_code": 0,
      "output_sha256": "3e61a2af3809ccbbcca5b42031c78d3375b8e7d6af5f543ade527b8738cd4339",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3331,
      "exit_code": 0,
      "output_sha256": "fd8d93dd88f0a776c3d3d38af21a1aa7688e28ee58af0c2544c6517504ac4ecb",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2216,
      "exit_code": 0,
      "output_sha256": "6a6ab1f19787e7803faef6e1d3bfb6b28f19462c9bf62c670ee24497f277cedf",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3227,
      "exit_code": 0,
      "output_sha256": "235456bb6c6ab792f4e89bdc8e44ee1e19696d9984de27322e85be00f161f3bb",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8179,
      "exit_code": 0,
      "output_sha256": "45e63efdd39611ee68bf601d4c091956b3b4cc66a24fd5d20f41030204ce5ac4",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 7148,
      "exit_code": 0,
      "output_sha256": "5a1d5d2d376d0f6c81a7de9bf855703c26f8315c8a0150dd64aec1bfcc66dee3",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1469,
      "exit_code": 0,
      "output_sha256": "191a1c0f28c56db0c35a7ae68d98954d103b383092d070cf299921582f301dd6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1307,
      "exit_code": 0,
      "output_sha256": "ea288be40dbfe0d95a6c18abea3a37ee3536c84f7f51d63f0bf7241edc6badd6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1449,
      "exit_code": 0,
      "output_sha256": "4ccef9e9bfba00efd7c0bc643cca758a34f5732977d38002fb6cc593060541e5",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1553,
      "exit_code": 0,
      "output_sha256": "35839e2b3f0896e0a47302071b884c8c47604fe60ca507822978b23486e9a12a",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5654,
      "exit_code": 0,
      "output_sha256": "0e8fa576aed9c40d55301c02d9fc56773c1843bb675dc0c22a1a416e8a3d4375",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5433,
      "exit_code": 0,
      "output_sha256": "8236e356b3eafc30c3d9a46ef98aada50fc5535e8568ee52fd479a3201a52666",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1256,
      "exit_code": 0,
      "output_sha256": "1f0f287cc43e88775d39837714f5e5fa171e3e78facee887ac7197d84706c1b4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1235,
      "exit_code": 0,
      "output_sha256": "84a34489b2a6fb71199298703d880147d70f3a91900876ed1c17452064ec087c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3360,
      "exit_code": 0,
      "output_sha256": "a9fcb5111359ec57cada4aac332f14f5e2b5fa6e4daca1bc0d5de6f50815dea3",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6883,
      "exit_code": 0,
      "output_sha256": "a4b28418b8005192b50e5326a5dfe1a863abf7841d2364dfed05409afe259c07",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3351,
      "exit_code": 0,
      "output_sha256": "864f0f4f1b6ef120eb4ccf88cd0b55e595fb068ab35ac9f76ef7fdd1ab4a7822",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3229,
      "exit_code": 0,
      "output_sha256": "02eb7d617b5cef21f517cef814b30bde954dc61ef87787cb547437acfcbffa0b",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3246,
      "exit_code": 0,
      "output_sha256": "8247fd4b88224a772c3657912acd37151d50cb9e55ad2d51acb80c4e84b363ee",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3409,
      "exit_code": 0,
      "output_sha256": "bacc6d2c3031bd0d68b8d9f6aab8ff6386724b2277ec3ae94721809cd52ad33f",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3286,
      "exit_code": 0,
      "output_sha256": "e8b4b2d3cfa2b5b8873785a845f3717ec08010ce2888d5e2928d232798ec119b",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1288,
      "exit_code": 0,
      "output_sha256": "56cf8e85e311ce32bd0ca44b1de45d40eaf02f09bb4a1c702b464fcf8dd1efa2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "47effba90918219fb6b2943c066523d39ff99213d7da97d5a6b5ab22d48ea4e4"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "f1f0bcdc008c3bfc58946b5507464aef0993ea87e53448699ef588fef62080ef"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "e666f75e8c2e9a3f3dcb6b54875844ec91f288ba9d368afce1459c2339ab1b9d"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a47d8b7a24e35bcf",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 138348,
    "exit_code": 0,
    "output_sha256": "8e6998e33417758163155a31dc5490025612327c2d9c40e191464e4440a0c092",
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
  "source_digest": "sha256:5e58f96124d2637cbd0de48e75bc699d873f8e06bad111ed1e542eb6da1ceac6",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T21:41:34Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 36922,
      "exit_code": 0,
      "output_sha256": "cbef495911a3ec7bba82e9c0bbb73eb66f147e1ad1c247b0a6776d702053dc7c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 37606,
      "exit_code": 0,
      "output_sha256": "f698892dae23841b22492cfadc7f1953df33d378b6f8073b32c95a315e7163de",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 30048,
      "exit_code": 0,
      "output_sha256": "3016d8a0376b0aa0416b4cf75be0d7b758f65dad2658638a64414789c67e2022",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4078,
      "exit_code": 0,
      "output_sha256": "86d2452405418f73e90cbed53d5cd30c0a7fba406d204f2afdd7566c859a6d87",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3071,
      "exit_code": 0,
      "output_sha256": "300b6df4ebd297ff0507c46602d34c7cec26aaefe725649d998b97d7d527d5e8",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5953,
      "exit_code": 0,
      "output_sha256": "d2ea9179d8ae18e9f9ec57f0e73828b113f77a7fd8ea4fac02498b9e99f15d5d",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 11249,
      "exit_code": 0,
      "output_sha256": "142ebb0f82c2432aa6c15d47c44212f3e9f489e899537169b0bfba3e5fa941d5",
      "summaries": [
        {
          "excluded": 78,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10588,
      "exit_code": 0,
      "output_sha256": "34d8a030dc3ee6bdde90beb3e8caba3b48231130980c1a37e237ad42987137a3",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 4927,
      "exit_code": 0,
      "output_sha256": "daf36406f2794384ff6c167cbf9f15cd1713d4e05bfe88a08161205041e1a5b0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 3555,
      "exit_code": 0,
      "output_sha256": "821ef4fa1515ecec46d093b4ba8ee94bc19c90cf206cccd875b511e5cf880434",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 4004,
      "exit_code": 0,
      "output_sha256": "a6e7f12d0ba281981e9c3866c646d1006f655d2a98be65c873c2057a2453f419",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 4213,
      "exit_code": 0,
      "output_sha256": "25d55b2056c5afcfe004f9d1ff69fdd9edca2ca71b321cb58ef5997fea9fabc6",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9246,
      "exit_code": 0,
      "output_sha256": "11f24f66ae76546bcd06385207a7794b6321ef4dc78cfab6fd40befbb783d09e",
      "summaries": [
        {
          "excluded": 78,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 9391,
      "exit_code": 0,
      "output_sha256": "3b257261ac3b4167df560fbb05cc8e44e8603fda0eca474ff9b4012a76677be0",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 3008,
      "exit_code": 0,
      "output_sha256": "5683a0b89b524d089753279958a74f8be4009c318a02b834f74e2ca07fa9d4d6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2932,
      "exit_code": 0,
      "output_sha256": "e9a3078c14983b396ff71263e8ce55806b53492f2b16677e888836be09c1014c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 7829,
      "exit_code": 0,
      "output_sha256": "b326e72779919a6e696039169f9ed6311b7526fde4aaaa8d3cc185503228a3fb",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 15692,
      "exit_code": 0,
      "output_sha256": "6625fd9df74a39f6b8a7fc5ddb29b101781c2a1bcff30434ad3195ffb415c063",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 9467,
      "exit_code": 0,
      "output_sha256": "ce8c5a8e5b05133a19dd388eaf255ea76121d389525e39bdf251ece2ab030e8b",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 5018,
      "exit_code": 0,
      "output_sha256": "c8172e45c947abaf22adb467563b40037414cf7a09f45a553a845775369019e0",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4585,
      "exit_code": 0,
      "output_sha256": "0337ea1db862b4299d6f1ecb9b37b7cc56fa28f78b729cf3f56c44ccf264db51",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4632,
      "exit_code": 0,
      "output_sha256": "f1b3741461984a2458558fc1ea954fc7295d99e9e0188db4d826722ac70a4f82",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4400,
      "exit_code": 0,
      "output_sha256": "bec0927aa801ebe7723a6afc8672ffe7ffb77cef2601ece02e4a7ad7125d891d",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1945,
      "exit_code": 0,
      "output_sha256": "30577b1ff95f700c9e9cef5f6dc3cf112bd466da1a4adc8c1d99ab9fb3173368",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "47effba90918219fb6b2943c066523d39ff99213d7da97d5a6b5ab22d48ea4e4"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "75df61974487848c27f7e4cbc79adbc6df5292319ecd09ba7cc8c51587081481"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "e666f75e8c2e9a3f3dcb6b54875844ec91f288ba9d368afce1459c2339ab1b9d"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-12b1f9140df4bcbf",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 146798,
    "exit_code": 0,
    "output_sha256": "8b8642ebc23b9ce8c440cdaee4f67969d9cd7b1b821d0c2ddefa4d38e381d9f8",
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
  "source_digest": "sha256:bd270c73dbd259bde11526ebaf13e2c36df34db308c82ca8d20a5b0c4695fce3",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T22:40:16Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 30637,
      "exit_code": 0,
      "output_sha256": "62f7a7c5b073e32a5bc7199df223f7aed64a6e7af12cd2d282855e60aec715cf",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31215,
      "exit_code": 0,
      "output_sha256": "e60db55cbcf91a476fb980461b1f4ae94a5c3fd44cc9c84e91d75d54d1e8e8c7",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31431,
      "exit_code": 0,
      "output_sha256": "d7586771371ffb3b429926220b40b65b5749e4f578133a44ed0e26ae60ec52af",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 141
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 7715,
      "exit_code": 0,
      "output_sha256": "593b8b3d1de8a40fe02c4c2f8542271e64cd1fdd81bc25aab0ea08f41d589bad",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2172,
      "exit_code": 0,
      "output_sha256": "021ec3ef2a397f74582f02a981eb94beca1113c6521a018d6d22b98ce745d3af",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3502,
      "exit_code": 0,
      "output_sha256": "4d9a0f1f0c2ce0e768bfbbc04bb4504ffe5de32588b7ba5692de8073647232d1",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7483,
      "exit_code": 0,
      "output_sha256": "e5b3bd161574be56af0d98678a210a0c0b64a55f0e4b3a87df873149642c75fe",
      "summaries": [
        {
          "excluded": 78,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6608,
      "exit_code": 0,
      "output_sha256": "69a796b002ea55ae338a4f5f5cdfee6f56b68adfc534b1bd5be740b2fd05e5b6",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1442,
      "exit_code": 0,
      "output_sha256": "779b2680a80ceecf34857137e112f8845393df23b2f24091c8dcd44d6db07ff3",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1272,
      "exit_code": 0,
      "output_sha256": "1b4309ba61e6c3fe6565907ecd8abee2fde1e5f0336c68c35687eb8e63d02773",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1582,
      "exit_code": 0,
      "output_sha256": "8052ad3411410ca16dc23c9d97f386446d85b861565d3002a4bcf6edef6b0d1b",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1616,
      "exit_code": 0,
      "output_sha256": "428eae816874a6405422b3e3216ddc870eb7db095ee8ffa2ad34db16f4a6c673",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5537,
      "exit_code": 0,
      "output_sha256": "c6ba985a1193f0355e880c37b9d4bb12055da118d5294484f629524bd957110d",
      "summaries": [
        {
          "excluded": 78,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6677,
      "exit_code": 0,
      "output_sha256": "c6e87b12c9f5f6dbc7b03903ecc9dd6be35cc7e681074fdb7fb562945f81b330",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1353,
      "exit_code": 0,
      "output_sha256": "8bfb6a73773e52a37defa6c7b24656a35abe4248debd6d155cc78e417227745a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1502,
      "exit_code": 0,
      "output_sha256": "16cf68e432c15a1a12132f4727d1c07bfc4d6f17b5985c0f9a3b43e81e86c293",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3593,
      "exit_code": 0,
      "output_sha256": "5c73629e974fa5e7c464b38e2383cb0ffc1dd2483546e554d09499088289874a",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7183,
      "exit_code": 0,
      "output_sha256": "9658723a7e577ae1d5555fa48a8c7a026f649796193c3b80027f111e8e9633a6",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 7357,
      "exit_code": 0,
      "output_sha256": "7d2da8dc55a0aa4f265be7bb83793bc324dbdc0dc3016e1ea0caff14b28fd551",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3519,
      "exit_code": 0,
      "output_sha256": "aae5777d08292c62586c845104431051cb14256a388a5926d7201fa3bb9d49eb",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3682,
      "exit_code": 0,
      "output_sha256": "0df0d066552b2b8e4b99c815ca553fe1e76209ad28040f94e524f7d9f7226900",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3748,
      "exit_code": 0,
      "output_sha256": "e35939ae85d9b42fa4ce51a0c9dd6c9f4a70bdf997d95d4679882c7aab6dbac4",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3609,
      "exit_code": 0,
      "output_sha256": "57c58b45a7cd7eacb232ef378b8cea96d97f048123b9c3cdc6761a699261a643",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1314,
      "exit_code": 0,
      "output_sha256": "eb11958a22d3da737dd8981bee360af2677d1a636a1d22a1a59d2f06b301ff78",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "47effba90918219fb6b2943c066523d39ff99213d7da97d5a6b5ab22d48ea4e4"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "75df61974487848c27f7e4cbc79adbc6df5292319ecd09ba7cc8c51587081481"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "e666f75e8c2e9a3f3dcb6b54875844ec91f288ba9d368afce1459c2339ab1b9d"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-12b1f9140df4bcbf",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 100489,
    "exit_code": 0,
    "output_sha256": "e32b7557d7558f63efcbf067bf5e7933b0c9620bbe443a9f3ec468f81a3ef22d",
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
  "source_digest": "sha256:bd270c73dbd259bde11526ebaf13e2c36df34db308c82ca8d20a5b0c4695fce3",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Phase 78 baseline source refresh — 2026-09-27

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-27T16:40:23Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 44966,
      "exit_code": 0,
      "output_sha256": "eb794f0aafaa6e2ab84397e18b28e2be87c8cccb70a6403a9facfb8df954fe79",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 43847,
      "exit_code": 0,
      "output_sha256": "814907090a4bd948eeb87013d8c71df259b9ca237e148bdf06dcb50a8d73c4e7",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 47608,
      "exit_code": 0,
      "output_sha256": "97e490af38f3b5c5058556b694369a820cb57c8c0e5cc40a31cb73db4fc86412",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4181,
      "exit_code": 0,
      "output_sha256": "deb79e227b88627f19950b09916cb146cff742dbeb0c3da37c1c6b1d2e21b15b",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2661,
      "exit_code": 0,
      "output_sha256": "bca9ce65e3b846fba2c6586b238eb8b30797ae9576bfdbd0b2f27872e8d9fe70",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4417,
      "exit_code": 0,
      "output_sha256": "b7b4d301134d0463edd2682b1167f669872bea545f25d4ed13ab59a530f1945b",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 11137,
      "exit_code": 0,
      "output_sha256": "941dc1cfb60b009ffb0275aac21568ea5e3f24a3d31b5d2c09a4bb44071f7fa9",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8456,
      "exit_code": 0,
      "output_sha256": "9171c49da3f8f3bda80e33f5acdb11e330fb88eb8dfbd0e417c2d4be9e51985f",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1761,
      "exit_code": 0,
      "output_sha256": "a6d8e4482cb53c1b8461155928ed0b065d5d0443573fbd18df5febb7054fe185",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1584,
      "exit_code": 0,
      "output_sha256": "18c244e231e5023451f912fcf6dd436456c401873db103047f3a67a99c226a6b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1754,
      "exit_code": 0,
      "output_sha256": "62558951926c8eff50d31b5645aee68f98c5514618892844041d9ff746fa4adc",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2012,
      "exit_code": 0,
      "output_sha256": "62de06a9deee2d7b995173a75ca6858565dae442d9257e5234c30b98fbe5504f",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7125,
      "exit_code": 0,
      "output_sha256": "c9ffc78cf0d1becb346a29f05565bd482efcfd940903767e489853416722a713",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7681,
      "exit_code": 0,
      "output_sha256": "4a65a8da86590349c5a6ec7c4bf144272be3b89fa045bbd4d6c09d7982f559e9",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1704,
      "exit_code": 0,
      "output_sha256": "ba6f14d3f204c3999ce546f258176fa9bab3fd15c3a15b61e22aa1bdbfddafe7",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1662,
      "exit_code": 0,
      "output_sha256": "af314f47c5719eafa707a2181a52ab95830e66365f37c285bf8565f03c11bfe2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4326,
      "exit_code": 0,
      "output_sha256": "094b6b44af2ec541b34a4bcfbc8c619d8ed16c17e627be70eeccb8631e3b97b9",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9560,
      "exit_code": 0,
      "output_sha256": "2d192fe20134c751a6966597a22a8645ca9b83755fae30bb06f474ebc0d9e954",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 9068,
      "exit_code": 0,
      "output_sha256": "79eff8e9bb4dc865af53a1b9a7be7d969e037ee203579cda7cdc58353eacb3f0",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4327,
      "exit_code": 0,
      "output_sha256": "c5486f4b81d7317a507f8f853d650896f3cd5f16939117fd60098b3306d2d915",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4293,
      "exit_code": 0,
      "output_sha256": "cea263cd169de8080e3254866a05e7cd2c983ce1147b77f280f6fae0d4040339",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5978,
      "exit_code": 0,
      "output_sha256": "b557dd96e727bf2bb4c0c9218ff1d2ab4e2fbac075a777f34f139b76347d4383",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4827,
      "exit_code": 0,
      "output_sha256": "25b0a90cca7caf6cd60104e82b47e4a69fbed5e46e108c0a692611603dd58f95",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1907,
      "exit_code": 0,
      "output_sha256": "248eebc877f9edcb459b3b750fce4ab3936a0a1791efd6d5a075b6fec88b77b7",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8058caab6d48ede2a04d7f369c8a367180e06470f3b7ac12cf99186748fda8cd"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-352529cbf3eafa39",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104576,
    "exit_code": 0,
    "output_sha256": "3076db0261a6c1ebb13c223c9d59f08b58285f03cba0ed0e2904e1dac2845f3f",
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
  "source_digest": "sha256:590174a171fb3713bc9e08ed2319bc5872893bf317fa7f5dbc6a348c3283c914",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Phase 78 intermediate source refresh — 2026-09-27

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-27T18:56:44Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 41581,
      "exit_code": 0,
      "output_sha256": "04f937826d290a6db076ade1c8764ee6fff7f4ec10b0a0ee58f2724c2b45d42d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 30190,
      "exit_code": 0,
      "output_sha256": "68e29a4602d70d27b4466939afab7f5fc6e6c05b41c20dcd72a5ca6f54db8f59",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38796,
      "exit_code": 0,
      "output_sha256": "89e864549463ba11aaaac8178eb09269887e6ad3faf484d19a875b8afc560c2d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3450,
      "exit_code": 0,
      "output_sha256": "1504ab3c5f6d5dce60c5398bf058b17d6e1f02a0cb72cbcb7e30b7318e59ba64",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2100,
      "exit_code": 0,
      "output_sha256": "a7f2d0c916bdace09c1f73410cd430d919efff4d88682ca00f56f7b397f903f4",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3321,
      "exit_code": 0,
      "output_sha256": "f43b9c996ad7183974a0fcce6368933a2b07b9c1aee666b9b7ba962a2b267ef0",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8425,
      "exit_code": 0,
      "output_sha256": "a33807f8d331e27f86e6ae68a2e1a41eb2326b441b2c848d41b32e9799598ba1",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6738,
      "exit_code": 0,
      "output_sha256": "0d81a99964c69a2e835b9cfe118e3912ab726807008d9ac9537a41000ebed5f6",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1300,
      "exit_code": 0,
      "output_sha256": "aca624a870fa23e3da78cbbd6c30a701e9d01ad5b2bf16ab7a1124e109054b9b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1239,
      "exit_code": 0,
      "output_sha256": "c837b5782b236328ada04388afdb03ee53b4cda6e99013ba1f0d37c412efb2cd",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1394,
      "exit_code": 0,
      "output_sha256": "064845724ac1a2e53900254d79b9557700d813b94b74c98bd2bcf7660d612a13",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1485,
      "exit_code": 0,
      "output_sha256": "c10f7aeb9b2e6dbdfbcda9fec3976345af977de3b7ec9c74134b199c9b548af1",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5543,
      "exit_code": 0,
      "output_sha256": "e5ab67651b89841e821f6e590deae27523764ff5ad79b84f53a22efb96460409",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7177,
      "exit_code": 0,
      "output_sha256": "10111975f13cd16957d2b8131ca61bf73dedae8672635661a41b7d9d24e53f7f",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1862,
      "exit_code": 0,
      "output_sha256": "a181ea6437e6193ff1c11418b80d3db5c600e3f1503e68bff7bedf0802e490f2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1836,
      "exit_code": 0,
      "output_sha256": "3d55600798ac9403b29b392f8be0da05cc8ee46adf1ac9a9566451b331bb2bc2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3992,
      "exit_code": 0,
      "output_sha256": "64de694fd0fa6698aebf1872c5191bcfd85ba568fd7bc702354d7cc046be2a61",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9484,
      "exit_code": 0,
      "output_sha256": "887a7e0bf238aaeb16996e89c7142c1a6513ed0b4ffdbda76fc6e372d0816538",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 8668,
      "exit_code": 0,
      "output_sha256": "c8f816330a45d412f8b264f52c498b7ec2f4a7b1f467e9ee5498115bd8c08af7",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3870,
      "exit_code": 0,
      "output_sha256": "e838d5a238d8da1a9fc3f5e50423708576a3482d2060e13ecd209f3021c0e53e",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3489,
      "exit_code": 0,
      "output_sha256": "d6a430c41bc48262df189d91afb9ead1794466ebfba3765ab73ecdccd5d2bf0a",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3923,
      "exit_code": 0,
      "output_sha256": "cd21a1de154e5f7cd410dc3dfa398b9bb7318efcd2fd4655c6bc11e0b9046092",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4036,
      "exit_code": 0,
      "output_sha256": "263c338901b1749ff8ffb6f7cad575304423000cba56eaf55ab9486e2a5e22d9",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1957,
      "exit_code": 0,
      "output_sha256": "ec9291dfa66dec2c7c4e9efc3bbedd6e2fd2514bc6a4a2340463f21eb8130603",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "8551c760b6b536c59eaee2263e10b57fe3f8e5616476cd475d6280daf97206b9"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-dd11175a6d2aa196",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 105761,
    "exit_code": 0,
    "output_sha256": "0310f72b35fb02cbd6bd7dd61488d652f5faa73d30f9d132d4688680f546ec06",
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
  "source_digest": "sha256:7ecd8d7fe6fa03b2fa94d8155448243678a90c0963fce83923d8fc5a1327a9d0",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T00:31:46Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 56351,
      "exit_code": 0,
      "output_sha256": "22db65d69b37942fb95ae42cac8bb8328461ae68222027afe6b78e81be986f18",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 48976,
      "exit_code": 0,
      "output_sha256": "f35faf8b2c375a3bcf9a06b6d9f32712ae823090fbb65dbc668d2a03eb6482fd",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 44241,
      "exit_code": 0,
      "output_sha256": "02ec433c61e3345add16c89989a90bdcc9eaa7946f57166a28ca1a6b8af2b4ea",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 146
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 5270,
      "exit_code": 0,
      "output_sha256": "64b1b2a8c846251d31d40ddc77abd08fd8593719d26aadd438e91177552762d6",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3722,
      "exit_code": 0,
      "output_sha256": "aec49fa2d7c2622ae3a60d12567ef51b2a1d2b560557286c97b82b899b2d2632",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5326,
      "exit_code": 0,
      "output_sha256": "2530840ed136f7900fef8b628d56be558660d6d8578eebef684dcd061b93c059",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 15290,
      "exit_code": 0,
      "output_sha256": "90ba3c5dbb61f1164f5c1cc95077147843cbce8364c6fa9b6e4fe3ff6d59b5c0",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 11019,
      "exit_code": 0,
      "output_sha256": "48751d318ff59e4c58145b01b8d41d500ae4c8c78d0672941fb732ee91c82797",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2709,
      "exit_code": 0,
      "output_sha256": "3c6672785bb6a62c5de4335f445bbdbc3aa5e81af89164a2cff03ad0502bf595",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1966,
      "exit_code": 0,
      "output_sha256": "27f94f67a55575eeb81d9e3cc1620874156c8486884ff4a63e167644e9638d77",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2368,
      "exit_code": 0,
      "output_sha256": "ceb32c01cd441d726b15555b3b75fd051b9cf37dc56055dbb1c410aa9a739d56",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2531,
      "exit_code": 0,
      "output_sha256": "d716612be83046ac7077fa7d01a834fdb3c31448f1f01637a35680c0e7b1ada3",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 8373,
      "exit_code": 0,
      "output_sha256": "ff1192ea9d4f638f52b950b5117b2fb982a4f43b0716651472a44d6843015570",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 8848,
      "exit_code": 0,
      "output_sha256": "15dc61d2bb30b7896bd4ec86ee34638a86347ebc34d381419566f754090afd7d",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1999,
      "exit_code": 0,
      "output_sha256": "999b0799a6bf65784ec809a0f3c861a33b607da784260e3dd8f6f428db61a21d",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1879,
      "exit_code": 0,
      "output_sha256": "a08d2c4255037d9e8a157a5cde9ddb2b19bc72a9df933574a43eb48ecfa9832b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4449,
      "exit_code": 0,
      "output_sha256": "a5f895433bae71e663ed6bdc8052659e0a1945abc7a9982b41efc0ddcbbb7778",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 10984,
      "exit_code": 0,
      "output_sha256": "784f2102afafc71d3d2aaa3fc13a66f13759cca6f3bc83ee4a1ca24ace19e331",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 10485,
      "exit_code": 0,
      "output_sha256": "a9f13002b497d4b5481a24def23b67fb8c89ee5eb34630848efa1f6fa2b28f97",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4807,
      "exit_code": 0,
      "output_sha256": "70e5926a1bb57bf00ca3634426ad2c16c6a125b1904bb05076657911ae153778",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4712,
      "exit_code": 0,
      "output_sha256": "cd5d7373dfa533dcc560b271c61c786fbb620b117d44ad8985c02f912a800762",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4748,
      "exit_code": 0,
      "output_sha256": "dad38037dbc595fceea390483913f44bd0a75eac15583fe9c0e6528361fde8dd",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4159,
      "exit_code": 0,
      "output_sha256": "bdd5238971440372165d1c76857cc905e7d0785bdbe0a42e132e46c136b47d50",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1787,
      "exit_code": 0,
      "output_sha256": "9aac7be54a4e5d02724fed5f81aa8be598563455c878bd07e630a419523886e6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "52af5137279843f1babd7a10f846455bef429ab740ac72e4b75c4ed7a5aacf96"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-0ee0b9963cb5af5f",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 108324,
    "exit_code": 0,
    "output_sha256": "cce398f794448950353295110e9178a1475bb8df82b37cd79eee6152093b542e",
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
  "source_digest": "sha256:d1f6a6c41fc71f26cd5a63961521773e3759be4a23d28dff377b7dea4e68e0a9",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T08:17:56Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 39917,
      "exit_code": 0,
      "output_sha256": "faa6d557ca2cb7789080154c21d2928326ac534e82c4d1a990e19bc5ae3e4128",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31920,
      "exit_code": 0,
      "output_sha256": "4033f0661f8344fde7f04fd608685b8f9e2b14b1f050268bc6d3db3ab7451792",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 32647,
      "exit_code": 0,
      "output_sha256": "06daf605b12a1bb77b4b5fc991702bc26fcba466be5bea9db8062005a60f773c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3039,
      "exit_code": 0,
      "output_sha256": "d4a5f8bb74847446b6e8387aaa7acd130faa6f96b269699f933a21ec89d6ad78",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2027,
      "exit_code": 0,
      "output_sha256": "b5a739a9d6bfe3e6f2a1786512ec710cd76a40446be5646d0e22ee28b43e44ce",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3224,
      "exit_code": 0,
      "output_sha256": "47b5aa4e764a109c316c8d37c5724ef662002746bfa85d7a99de8bc35fb38187",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9885,
      "exit_code": 0,
      "output_sha256": "4736b3925b68818ce90348826b9bdbfbd4286d73a5b7fd9193e4b62bec68c06a",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6116,
      "exit_code": 0,
      "output_sha256": "6fb555249fdd89c3d52e3a78538d991f1601a33cf737a237066eee63bb2f8945",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1289,
      "exit_code": 0,
      "output_sha256": "59a6aa0a9eab59b26324853e7fb81fc3469da1e91dde36178d222ac54aa76b73",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1205,
      "exit_code": 0,
      "output_sha256": "becb31a0c39db2673cd052e56080bb084f97f711570d9a13e4de441fd64666e6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1393,
      "exit_code": 0,
      "output_sha256": "f85ef7378a0290b5f87824b75cc805662adfbcb31b1944d0d0e1403397a0b425",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1476,
      "exit_code": 0,
      "output_sha256": "2919196dd2fff8d3c1380d188d8913fe061bbb5d4f063f08c1d33fb09c6c02ed",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5161,
      "exit_code": 0,
      "output_sha256": "7735978e0260fbc603b5fd02e5776d51316867ec2ed05f729702c8791247d505",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5828,
      "exit_code": 0,
      "output_sha256": "4ff6bbf0f40627b4731d4b182b3644be037fb5804eba8803e4c639ebb4259407",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1246,
      "exit_code": 0,
      "output_sha256": "82b6ee5167e2d5722183d71049cde94430f607080e65508a9698d2d521ab5426",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1310,
      "exit_code": 0,
      "output_sha256": "95f431cb7179aca478b72af61632bfb417b3333edafda57ee4f41a0b207cd0d7",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3126,
      "exit_code": 0,
      "output_sha256": "695d94b5b971395f3746f60ec08069dbe4b77e92cd8c7f3c7c9418a98092ea16",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6969,
      "exit_code": 0,
      "output_sha256": "255e7e009544c1c91557e74cba7b51c81c2751183ac8b4c0e18e180da0feedd9",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 6917,
      "exit_code": 0,
      "output_sha256": "a1da7161d04a084fdf5e2d2d97e74133fdc8034fdc27867e7620f94ae55a6627",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2945,
      "exit_code": 0,
      "output_sha256": "d8cf65f9ae4a0745559e3c9457be0261e6166963d5eca0f415039d70451eb39e",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4400,
      "exit_code": 0,
      "output_sha256": "740c7c377c037871cc45cbe364f03d6a66a78419ac4a689b2a17481af67622ca",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4158,
      "exit_code": 0,
      "output_sha256": "946277edecb320b21fb68da4d0e575cfe8985a584759280492e6a7908fe74c7a",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4329,
      "exit_code": 0,
      "output_sha256": "6c016658e56de77682f99e665f56f60e62027565ab0ae2d2296024d5480fc7c1",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 2138,
      "exit_code": 0,
      "output_sha256": "89bfed4eb1133cdfc8076a6f6dcccbc5bf25286c7c5e615fcbe154e9165dc8c7",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "31de9bb844de3a74c9f5783dbd9c6dded422312cfdba42b62c0bccb32b74b72e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-f78fad02942c7d85",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 73781,
    "exit_code": 0,
    "output_sha256": "b9f88e8a7018752a6b12bb32b6826c58d96588818c813a758b2b8c75e57ebc61",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:753fa7e02b0b3fe5b3fb9f7f6f99b83b1afa79dcdc3291564527f4079cb4063d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T10:10:12Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 59158,
      "exit_code": 0,
      "output_sha256": "2f5db8e42291529db289a857e8e8451575035e8b52eb1b6cd484ee0423525035",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38351,
      "exit_code": 0,
      "output_sha256": "de2f0793cf4023f191e47b72c95ceb23602d86f15ffe9f4a6f1907f202577c72",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 28367,
      "exit_code": 0,
      "output_sha256": "6601ffa601d50ca4ac815d9922d4a88e14059bff156ad007dee04d3b9710dcd1",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 5832,
      "exit_code": 0,
      "output_sha256": "76bad70d063e12b73047806e4bc3690482070a3ca86da738a2f61bbb5f01f645",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3218,
      "exit_code": 0,
      "output_sha256": "92e3b91fbbdb3badb53d4d2f65d397b719bdb78ddf16844897c4b0b041d28175",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5790,
      "exit_code": 0,
      "output_sha256": "c3a2c22b40cd26ab24313f2f74a8c442f169fd8e203072e1a5289ad2e9c24178",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 16972,
      "exit_code": 0,
      "output_sha256": "bf4ae44811630d52e46db57076ff23e37c825a289a42ae4f37621cb39b8a1b84",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10561,
      "exit_code": 0,
      "output_sha256": "98c42f49815a2741fc10ccccd18dfe77be88eebffda714e16c3e367a6fa38698",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2404,
      "exit_code": 0,
      "output_sha256": "920a8abe0eba87da4fd3dea19e7a986bfb4240228e5aad030137be6327f797c1",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2107,
      "exit_code": 0,
      "output_sha256": "fa41c462dc9991378119478c8bdaecba0527e861cb3d001832826025b93e352f",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2544,
      "exit_code": 0,
      "output_sha256": "be723efa5f8e1dfad528494d8e783946f04b097606da5991e290a63063053ae8",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2622,
      "exit_code": 0,
      "output_sha256": "75ccd921dcc0701658def344817d09c0d941d5eaa29465e6a016778dfd9d0269",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 10794,
      "exit_code": 0,
      "output_sha256": "145fa8b0f2e202fa2c4442c8a0dbede50b5ecaa56accf78d4de89d96ba262c6d",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 9398,
      "exit_code": 0,
      "output_sha256": "fb7f2e27eeff7707ecfc03d6f1be12a5b8f117b4b1223c574c9944d3e02fddbe",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2476,
      "exit_code": 0,
      "output_sha256": "689567f929d5ec8efeb0e54fb5d2e6dd80aeecc57670e0138cdb86ec0a29923d",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2381,
      "exit_code": 0,
      "output_sha256": "7790984cf66b4e6e06b6dd49e60915b3be9ee7bb3515890b5ece0840cb6ebbaf",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5795,
      "exit_code": 0,
      "output_sha256": "0eeb582e4355b4efad2d8e4aaf8839d2cd2130d0574dac283628997876600975",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 12802,
      "exit_code": 0,
      "output_sha256": "6e3dfdbd05b47b961c227426b86d071c46a3bef41dca12f1bb1df164e80b6633",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 12621,
      "exit_code": 0,
      "output_sha256": "90ad898b92ea8cc72ae63432922b237dff83ea6a296b2550fff99ee246c4ccd7",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 5081,
      "exit_code": 0,
      "output_sha256": "08563357d45cffee8bc5f36970d1c8303b61f244a3579f919d9de9de48155d2f",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 5358,
      "exit_code": 0,
      "output_sha256": "6cca98284edff9193effd8771c5137dc9e033f96c4d59e9f263f61cca9b2efcf",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5291,
      "exit_code": 0,
      "output_sha256": "d1224f2dd17310790ae15d3fd163a913de8c24e9c47f48c14e12a944472bd429",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 5218,
      "exit_code": 0,
      "output_sha256": "e9816f730d0ce24041602057e7bdbf2bd067d16b7782fadb04ca8c17e1104f38",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 2254,
      "exit_code": 0,
      "output_sha256": "cfbf0aa7cef9c2fe374d3db086e3e5451b300f623e7c024b433f069c2b494242",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "31de9bb844de3a74c9f5783dbd9c6dded422312cfdba42b62c0bccb32b74b72e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-f78fad02942c7d85",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 71116,
    "exit_code": 0,
    "output_sha256": "667b869d0771aad92681d5631c3ee03fa52d268e86ed23f49a5ccf13d7b8c10d",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:753fa7e02b0b3fe5b3fb9f7f6f99b83b1afa79dcdc3291564527f4079cb4063d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T11:57:16Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 36430,
      "exit_code": 0,
      "output_sha256": "18735eb2f194ea98068daed022bfa98d0f6162bf5eb1e0099121f83262132d9e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 40109,
      "exit_code": 0,
      "output_sha256": "4ceb20b55024dd14fe9682343df59f4ff4b4267583ea1d8070759ad00216c297",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 35282,
      "exit_code": 0,
      "output_sha256": "e8f62ea16720671dc3f1849ccc823a63496b56958c79acc97d80dcc0d03eeefa",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3050,
      "exit_code": 0,
      "output_sha256": "f685dfbde9f7e95f8210da9e0278cc76d8be1d35f3899ca898d5026ba24e970e",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2447,
      "exit_code": 0,
      "output_sha256": "515db100d83b0cc92809145e207464fd8d8b02315c1c82d5d03eaa0cc62ecc81",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3605,
      "exit_code": 0,
      "output_sha256": "f50ca1fdf0dc5e10b39748b63b6299870d80dff892b341452e4c3cb5b6d9b6e3",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9593,
      "exit_code": 0,
      "output_sha256": "ad63a1377b8ad233b1f6a015871cc813d36eaf3021ab51c79edfe1d66d791ae4",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6779,
      "exit_code": 0,
      "output_sha256": "58e4dbbfbbc18c09904c8c19a114f5728422ee015ec8a90fa4b505f435eda02a",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1291,
      "exit_code": 0,
      "output_sha256": "1819cf10dc940aeef6c1ecea85d3111346249196e4bea0a1f0a0c7c4fc66b4e0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1185,
      "exit_code": 0,
      "output_sha256": "45a74f94532e578625f1c3acd21c672d609e42d4879999e072e5d62054af5de4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1359,
      "exit_code": 0,
      "output_sha256": "59aad7d30a7f17ff311b03d78f9abef55d95d131faeebe83b1d44648f1bd9b92",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1378,
      "exit_code": 0,
      "output_sha256": "d0c0252679cf40f16ecffa8d9737de2c80d0258699ff02760bf123c07efeb5d6",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4959,
      "exit_code": 0,
      "output_sha256": "550098d266897a14d33bb93045e4b0c0b55001a33a784341ed48122bc4f03f81",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5060,
      "exit_code": 0,
      "output_sha256": "da6e8a4566bda54f3bffc3d05ec0c0240a6d33bcb5009d028f8f8072df1f9d98",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1193,
      "exit_code": 0,
      "output_sha256": "8c265c52897ac147ac7f3e0a58daa9288edda355daf24541a0b4215fab810c72",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1399,
      "exit_code": 0,
      "output_sha256": "c185b0f39b97afdbe5680cde12d51331c46688a7c175a316d9c38f85403e0748",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3044,
      "exit_code": 0,
      "output_sha256": "657acd85008404d21b0097b451a8d0bfba0e92ea75d68e1f10fe290fbdee2ff1",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6777,
      "exit_code": 0,
      "output_sha256": "6de2371b1661fb945ac5479e543bfb7282e9c5b8a3a087eb459cd5c3ecfe1a51",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 6671,
      "exit_code": 0,
      "output_sha256": "e8c03c7f4e71ad05484dc5aeb1a7924eb74128e4cb6f52e17349bc309308aeeb",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3018,
      "exit_code": 0,
      "output_sha256": "ba9d13dc629de1e60f49bda2c47264617032f705fe9232d815fb41f0bdfc3bc8",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3028,
      "exit_code": 0,
      "output_sha256": "582b36245e3e9201d5edbbfd67fdd52b27bc604912ee49ad117abf24a7f82c3e",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2929,
      "exit_code": 0,
      "output_sha256": "ecfef52b64e7aff044d33bb6b61c82a3607307a28fb97edcadedc752865b8f75",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 2854,
      "exit_code": 0,
      "output_sha256": "12696d982bdd07a18dce78623fdcf28031f9312f69ae35bee96e19430ebe8f6d",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1218,
      "exit_code": 0,
      "output_sha256": "5aa0d7ed8f95cebae629df3e7d95b20659cec63a10d5e3954785649fd3bcbe39",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "31de9bb844de3a74c9f5783dbd9c6dded422312cfdba42b62c0bccb32b74b72e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-f78fad02942c7d85",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 73677,
    "exit_code": 0,
    "output_sha256": "02687b06604842df810f4cf9890c093f923e4cf33504b85013336da378a7b262",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:753fa7e02b0b3fe5b3fb9f7f6f99b83b1afa79dcdc3291564527f4079cb4063d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T12:22:10Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 34145,
      "exit_code": 0,
      "output_sha256": "75879287a258dec8f16ff183751f42ba145b078b740639692caadc80d42b3a56",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34955,
      "exit_code": 0,
      "output_sha256": "6844d71a3c4628a9dc2b7079dd134d8a4d9dc22bdd76b2f243ea25c942078287",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 33043,
      "exit_code": 0,
      "output_sha256": "26f1ff6b63d239f253922878d3441910d018d9f3772fc705c23ed4dc3d580376",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3306,
      "exit_code": 0,
      "output_sha256": "d49a5b3713484a000bca16d775780aa541518e264c63606a57e77ba537255b8d",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2120,
      "exit_code": 0,
      "output_sha256": "3c2cf09578fd05a512b39fd8d9f248c17bec4951e3adf62d659e168e904ea22d",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3301,
      "exit_code": 0,
      "output_sha256": "331aa87ee5283416011eb51c028c54c405d6b8aeb8390fdc12a40bc9cb4ab095",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9734,
      "exit_code": 0,
      "output_sha256": "76494f60b227ab3591b5240606a9eeecf915b75085529184da19e91596b0c071",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6574,
      "exit_code": 0,
      "output_sha256": "5b420cb8cf3eb14bd2d7f0743ffd479c7b1d270d2988ca072ba738988976c572",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1325,
      "exit_code": 0,
      "output_sha256": "e2f25a2efe3c53f927b079d8afb9fb7674ed28a5e46774a5172a5d91aa628edc",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1245,
      "exit_code": 0,
      "output_sha256": "e0cf6f4b4b757f8911f1b3aaa230809ffab7fb17ccf7f065ed1b49b88dd454f0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1433,
      "exit_code": 0,
      "output_sha256": "18c5f862d8477f04541ce604b8d0ee93f1c61770a9f41f5affb9ce3e55e883ce",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1533,
      "exit_code": 0,
      "output_sha256": "bdb91878c0fa9090c53a9efd9dc3921e039eedda0398bcb07471c4ccad88b0ec",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5207,
      "exit_code": 0,
      "output_sha256": "6b2a670d99b8d73a025c546498213edb0513a90dfb60c1b1127dc7280504cabe",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6272,
      "exit_code": 0,
      "output_sha256": "39285cf035d419ee5362b28282b9a7efa5f271730f0e87e1a985d4c63aa464c9",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1319,
      "exit_code": 0,
      "output_sha256": "2607317be20e44edd224adeafff47af7395e2d1a910dbad812176040a6723947",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1338,
      "exit_code": 0,
      "output_sha256": "1b142d4c9789dd3b198ec6eab82f64d4e076c9ba9cc25503088426dbf462156a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3250,
      "exit_code": 0,
      "output_sha256": "c59dba58bda2a2cbef74ab36b6802fcc6025a7d35943aca80c6017e2e0ce78d5",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7246,
      "exit_code": 0,
      "output_sha256": "eac11a5a1358fc2dbe55e5343fe76d4f29faba2af28b63d5c5c3bea669949f78",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 7081,
      "exit_code": 0,
      "output_sha256": "918464ab24cf398c8bdef970ce7bfba72acc96cf3e932f10dace63e847011597",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3243,
      "exit_code": 0,
      "output_sha256": "119fa0427ebd7cfea4a100b33a9231a266d3295901d2f5843e62a649148febeb",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2996,
      "exit_code": 0,
      "output_sha256": "7061f070eb352a983dc9a1677cd225c41ce9e15e0f3548e9c830cb3880f632d5",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3301,
      "exit_code": 0,
      "output_sha256": "d46756598143df51376bf2854f6b05918f739871fbc56bd975e5bbbe6662c1f4",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3164,
      "exit_code": 0,
      "output_sha256": "17f8b4c12a2c809048250a2dd4be2b8843b44d21e2777a1d4002a1be479acfa7",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1429,
      "exit_code": 0,
      "output_sha256": "0bd518e5b98561825c3afe03c287dde7ec467a1230b6c0d1aea2f781a3b115a0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "31de9bb844de3a74c9f5783dbd9c6dded422312cfdba42b62c0bccb32b74b72e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-f78fad02942c7d85",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 72992,
    "exit_code": 0,
    "output_sha256": "9c51c0d2b27a00dc2a79ebf6e19c0513eec039c4ec30693defd985e13cb0a13e",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:753fa7e02b0b3fe5b3fb9f7f6f99b83b1afa79dcdc3291564527f4079cb4063d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T12:44:36Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 29232,
      "exit_code": 0,
      "output_sha256": "f8c77184d5456383398a36d40fb18b53c669dd4ecb6d19fcef051ce1a2373335",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 33328,
      "exit_code": 0,
      "output_sha256": "a333aa5dbc06b01dc00213a1deb37afadca9806ce4e4c6120f4b7c6bcfc4a740",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39934,
      "exit_code": 0,
      "output_sha256": "0877c1073bcc5fd0bbd254e9beafaa4831d538d325681183761b0588991d5b18",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2803,
      "exit_code": 0,
      "output_sha256": "ffa35816548af14c4be46c4e906cc63a98b6ccf2add0287e9a7dacbc7e14d4cb",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2444,
      "exit_code": 0,
      "output_sha256": "009c453824ad74a8d552d1dda46fce1639b87c399c0bcbd081f47a0b22626602",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3304,
      "exit_code": 0,
      "output_sha256": "435216c70ba91d88853541d60531f763d962fef476b507a880779f48107236c4",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9534,
      "exit_code": 0,
      "output_sha256": "b7bba8d4a6169eb29161970f7a41bb03bbcb2b55e9f2ccf094f5a15da40ca719",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5934,
      "exit_code": 0,
      "output_sha256": "11191b612266353a30c3299a4478713369b3250b821f609824ca693acdbc6cc5",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1388,
      "exit_code": 0,
      "output_sha256": "3d1884af1e1c6ef6c91e58e4f05a438805e7d562bd1c2a2a3c40e24f7f6e1928",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1137,
      "exit_code": 0,
      "output_sha256": "7bcc27dfaaa93dfa46b78b40e23bee1f1fb03a04a0db3766a127ba51194fe691",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1375,
      "exit_code": 0,
      "output_sha256": "24ade9a524580cc4e608cc93a055687ec5465e78f4f45d57477c14c04a832b42",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1445,
      "exit_code": 0,
      "output_sha256": "33e594d06d1d3aa624726f37f8f1d504887da830c5d1ccee722a5f2a3c0e935e",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5266,
      "exit_code": 0,
      "output_sha256": "ba30a22b73c18115cb22875e726080e5d19d6ae081d322e21c09f0ba7788e0b9",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6113,
      "exit_code": 0,
      "output_sha256": "063606e8e8b990b426ffe1dd55a986e582ee32a96264b8f3aa32e14980f72add",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1324,
      "exit_code": 0,
      "output_sha256": "f85afcb1404972d97ef3f449ccb13896ffb2f215fb2920711dadf70a2f0daede",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1261,
      "exit_code": 0,
      "output_sha256": "45458391199b57f2801a9d6f93ecbf6895f8cff050bb9df09e35bbe13058c3f4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2860,
      "exit_code": 0,
      "output_sha256": "fe4be5810dfcf4f373c77e8dc36fb7e169e3e8b7a474920698dc4a8c349a55e8",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7267,
      "exit_code": 0,
      "output_sha256": "78fa5fea31c9593bee18e433122c0aae7421f27a2c908c21a579c244f2644890",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 7154,
      "exit_code": 0,
      "output_sha256": "958a53f1790db0c112ba333a6745c56a2e974a0a4fa949feeb4f09ef85b1cae1",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3281,
      "exit_code": 0,
      "output_sha256": "476032322492e8d4562f34fa5d1bfbddff8ccb00d413cab65c5eba29b1a5512b",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3255,
      "exit_code": 0,
      "output_sha256": "1d64bb7404b2bd71181c9692a3a2383ea196612c2069d2e4b520b3a931b28606",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3989,
      "exit_code": 0,
      "output_sha256": "f2bce158b07caae098b3aff2b433bc1196846c1d8009a09aa001789a669ae1ce",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 2994,
      "exit_code": 0,
      "output_sha256": "0d0e201bbf7c210ec721dd45be98d163a16921878583d50c725fadb9a3a6b496",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1267,
      "exit_code": 0,
      "output_sha256": "47a732aaba5430522c209e4e5873090361604b951081b6a8283549ed6f0774f1",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "31de9bb844de3a74c9f5783dbd9c6dded422312cfdba42b62c0bccb32b74b72e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "773d90d88c16944772970cb76fa86e4cf0b03717eade08285f2051ddf3be6e45"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "0ce048964a9dc7177ec77bf195fa7493655b3eb097276928f13e5cbb7d5fdbc5"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-f78fad02942c7d85",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 75921,
    "exit_code": 0,
    "output_sha256": "bc440a71b2c0d54e7bf47bb194cb746b7928282e2ec1697610d494ba23c7b80f",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:753fa7e02b0b3fe5b3fb9f7f6f99b83b1afa79dcdc3291564527f4079cb4063d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-28T20:47:20Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 27747,
      "exit_code": 0,
      "output_sha256": "0f011025fc2d9798db0131368667b7038ce10e530a9bddb0f221171946322d9d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27258,
      "exit_code": 0,
      "output_sha256": "64eff80f4c83ee654b29857f9e681ff27ff19811dd25723c33ef212fc59fae09",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27291,
      "exit_code": 0,
      "output_sha256": "d16f22441b909a59580faea7c8526a310da3b5092026b29feea688b760b3d90c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2952,
      "exit_code": 0,
      "output_sha256": "8c9920b009778c2a02c094a6cc056e92dabdcb3a3686df4ec9207f5ae616b36b",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1812,
      "exit_code": 0,
      "output_sha256": "f8366354d7b7f9ecbce8ee4406579642257671c6b7038eeb8f7701af3cd3ec00",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2647,
      "exit_code": 0,
      "output_sha256": "95bd5cd5eda721e0d248ae4c7e7921555b43b2b4dfaad5dfb074c0a406773777",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8817,
      "exit_code": 0,
      "output_sha256": "7b7bface6ac44777d96ee9de1728c56b2f671f25a375137c6e5cafc63995961d",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5915,
      "exit_code": 0,
      "output_sha256": "f34b3e7ac9514f8ed0f6253da243101366de4afd54b8334804759f48456c2602",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1183,
      "exit_code": 0,
      "output_sha256": "4b50dd4a6ad73a47582d54b978d7eac473b08a43a59e3c09f83a71a879a2fe5e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1063,
      "exit_code": 0,
      "output_sha256": "c18ab146c1efca61c0b7d91d1190a603405c340bdf25b3172375c983d216b908",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1355,
      "exit_code": 0,
      "output_sha256": "ec3010cff0c9862a7a6722a4321caef6facd3ef15eb48aebbfc453d9520806df",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1236,
      "exit_code": 0,
      "output_sha256": "c2f952284d06747728afc85215167cfb290076f49393e7c64c3daa2518860c01",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5080,
      "exit_code": 0,
      "output_sha256": "8a45669dd9ab3362f6ba8ccb94cfbbba476a7e69be2cab9927aa33cb1c78c97d",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5342,
      "exit_code": 0,
      "output_sha256": "201598d50e3280b412279db0348d95b00d7bef6d52be6d742fd52d9cee5f2a41",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1156,
      "exit_code": 0,
      "output_sha256": "6d0add8355aaa8892e6656baaafdde8d32eb898b1fe9171643034618595bfd00",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1136,
      "exit_code": 0,
      "output_sha256": "6bbbf972b9f42bf85f04f3b7bb0385fabc41691af520c28300b14aadd18b7d6c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2963,
      "exit_code": 0,
      "output_sha256": "b46990d1083ad0df99e65940713db5931f88dd9a77a7a185744166b64922fff6",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6697,
      "exit_code": 0,
      "output_sha256": "21314b11a53ec20e7417b730b9bde87b28535b391eeb5c0326a0d5b6e21be1ae",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 6246,
      "exit_code": 0,
      "output_sha256": "07d855b524bca6bf208b1369c83f2b93788d0fd61334c2205ed8b6f57132b52d",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2835,
      "exit_code": 0,
      "output_sha256": "9d2905265a4514e6d7505821334538c0fbc2dacb981be750be8935d4799725f8",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2937,
      "exit_code": 0,
      "output_sha256": "38f9e37b385aecd6af17312cc06a501666e80407d2b8b17046ea7f3e10221a8b",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3117,
      "exit_code": 0,
      "output_sha256": "55890bafaa86f60608614e1a4b7e69c25d72f754053f5d6d16e5d9438259aa8d",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3097,
      "exit_code": 0,
      "output_sha256": "51901894b29095169249330a27caa21b520b30386db9c51bddca3e0512c0c639",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1074,
      "exit_code": 0,
      "output_sha256": "f127c9c2dcb10008b9b75a2952f00f14e7a64eab02f1150a524dc3b2d034b34d",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "7f65ef374b35996ed0a5f176c24df150d880cd79b18db95eb0e28d100f52025c"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-b634149892e68a9e",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 70850,
    "exit_code": 0,
    "output_sha256": "5477a3a4963ebb5227acf8e92124513d060cdafe31af4ed4cc903a1a988b7544",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:565a5c07b4002ee0c054a9d586e798279dd637e1f687b9afc4f35ad33326f76d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-29T00:08:39Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 34882,
      "exit_code": 0,
      "output_sha256": "c81261be13f10393e051b6e539193a925fcf72b386c10235c6a990dce1a00f87",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 28556,
      "exit_code": 0,
      "output_sha256": "58182dd94a3946b6633fb9d62ca38786ada8a1e93a5d22bca2c7b870c5cf885e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 30322,
      "exit_code": 0,
      "output_sha256": "4e13f380a2421be5d0c0382569e6e6f66f6e677abefdac20a1a1d28ce6676d12",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 150
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4648,
      "exit_code": 0,
      "output_sha256": "dcea4b6e59dd77fe176364dd748a17775b2a4f39c2d6703c158296b42380473f",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3504,
      "exit_code": 0,
      "output_sha256": "8d19bb19f06618becd3105fd0a3d3186d481b2aed8b7520227cef5fdcdc16427",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5299,
      "exit_code": 0,
      "output_sha256": "d6930bc0e132efbcbbdf315aab7a850d0deca5a8f2c5e7d9dece81a0098449cb",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 15789,
      "exit_code": 0,
      "output_sha256": "b4731c4bc3c71905685532fbf3e304604cc511b1eee6ccb8c8ec86c9b0955fe9",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10727,
      "exit_code": 0,
      "output_sha256": "f74d28cb2f9831dabb2e84733211e33ab229e2a38c68cb546f9fc4d573caa947",
      "summaries": [
        {
          "excluded": 80,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2060,
      "exit_code": 0,
      "output_sha256": "4e5748b730ac83ad53447482bd1ecc93b2b0107708b45d114f07454992c38777",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1647,
      "exit_code": 0,
      "output_sha256": "95767b76d8c0e976590198723dd2bfdc4ef759f66373853a1bef3257b97cf059",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1986,
      "exit_code": 0,
      "output_sha256": "f3823f1cbce03b44a396ee41bb63dc6ac07f6859bdf3ce3dd25fbd9cb924fad0",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1825,
      "exit_code": 0,
      "output_sha256": "afe958be8681add1985afa4d2274d2ec42fa0d67727c1e0fad94cc19cd83033d",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 6922,
      "exit_code": 0,
      "output_sha256": "7a8d2c06d92e96f1b7a8e6af4d4b200e13151a2f67eea4e0ab3168f86bd5ff6e",
      "summaries": [
        {
          "excluded": 79,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 8715,
      "exit_code": 0,
      "output_sha256": "6c82e0bc0b4980dede37d7126fa28244efeae0fc1f4a123ef14552f3d1f99dcd",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1557,
      "exit_code": 0,
      "output_sha256": "ac433c181218483ce7431070fe88f02dd039b157d5c4e9228aeb5544b289f873",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1593,
      "exit_code": 0,
      "output_sha256": "fa65f05f2bef3c1702af5ab476ffd3304606d6e82b0ded1717862ae636a400c4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3956,
      "exit_code": 0,
      "output_sha256": "85cd598d62be3b096bbd3351f0d1d649583403600e988c683750bd18aedcf847",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 10425,
      "exit_code": 0,
      "output_sha256": "1fb368901a1558d8090bf11e3656410c63ba903ab9c2e0455013ea154d68cb8c",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 9988,
      "exit_code": 0,
      "output_sha256": "04b0cca631a94329923b6d6058a0a4b7853fb5135d60638ccab66fede316f454",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4032,
      "exit_code": 0,
      "output_sha256": "955e3482be538729b1d61b3a3eefe7461593ce8675d74b9a6a1e7420ed4d4c42",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3760,
      "exit_code": 0,
      "output_sha256": "f3b1076cd061e9ff093962842909c269de4bd2f672bf18c130aa5f96c5b1f7b7",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4593,
      "exit_code": 0,
      "output_sha256": "7afbef077beaabc40391a707a277d29eac9363f9aacda9393389c6bd8595d353",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4426,
      "exit_code": 0,
      "output_sha256": "5002fd23001740ae7de91d7a3e9db57ea4082f6d8a2c969c7c09828a98eaea88",
      "summaries": [
        {
          "excluded": 81,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1904,
      "exit_code": 0,
      "output_sha256": "e7f88bc423f7d2d3122ea103cd46d544634636696424fb2a06d98313393e1a4b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dd6be1d4fbb8c21175cc47ecae8be57fb6317d68788735a0ecdc68c50a7fc850"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-b0522b1b3ca40f35",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 105877,
    "exit_code": 0,
    "output_sha256": "b27e41a144177abd7a30dc5c3caa48167300d393fc67c3a834082cb3e569ab77",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:3c646362b072c3c5f613858c64fe8ab0f2b550da9a8296ecf4855bd36ba47821",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-30T02:09:30Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 37086,
      "exit_code": 0,
      "output_sha256": "9e70d6ec488603d7badf942af6fbba8e0af448c6e3847c9d14bb39a3142a7df2",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 30838,
      "exit_code": 0,
      "output_sha256": "4b1e3823e64b6728227671cc05e445f28620fc63ef3e72e408a36458d7a00426",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 35328,
      "exit_code": 0,
      "output_sha256": "8575b6fbe8f17a849a17c6e8c131129a58c8ddabe7f4df70dc521b2774400476",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3013,
      "exit_code": 0,
      "output_sha256": "1d53d02df64432d294c28b89741b54d3a7d70d303946188d2cf1f5081952dd6b",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2107,
      "exit_code": 0,
      "output_sha256": "c12018287c62589f200b8030e33e0375cb0595d447bf54aa19a01afe46728c3e",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3390,
      "exit_code": 0,
      "output_sha256": "065d2d30c1977a989566e3fd70d29398ebf2a94e20bbe13156c6ad3fa0dce995",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7041,
      "exit_code": 0,
      "output_sha256": "4479cab51829d002d446dc9010732a895f58d7d014d2ed8271f2b2327d785874",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6691,
      "exit_code": 0,
      "output_sha256": "dea7bdffe1f477324a46198b0449da68f9a100d9bac9527118a7f7fa1ed347b3",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1328,
      "exit_code": 0,
      "output_sha256": "61395a7b9d144e755715e2c0bcc89c06a91f3c0ddbe03e22478a40e79c5aba5e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1183,
      "exit_code": 0,
      "output_sha256": "e3f1d95eb5b1416c931e4f4b478acae8843e7c3b3f0fab959a1f3d2c52ce015b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1463,
      "exit_code": 0,
      "output_sha256": "d29a025aea05f3d247cbc6cb028c33d523f5341c99fb44ec5565ab6348e7378d",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1461,
      "exit_code": 0,
      "output_sha256": "8995e3c91df944d964d9d20a7d68c77ba97fa22050ec9f3e33b5441fe1159c42",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5734,
      "exit_code": 0,
      "output_sha256": "5ac202eeabc7b91707ae530494ef5351519e0423df90accccd708cf2a3e9a874",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6499,
      "exit_code": 0,
      "output_sha256": "ade91f2be4c062783cd2acaf75be14c615fe946aeb82af44a2ed621e27b80f10",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1427,
      "exit_code": 0,
      "output_sha256": "c00f0f644fbdbcfcfe19d7246f1fa1ef1e17983d8625d52de3b23d4f087cf427",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1365,
      "exit_code": 0,
      "output_sha256": "143036ad057cd6d6fe4f4ad11fe46c0b6b90c669c1a62bc76c0c7d58ebc6a913",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3072,
      "exit_code": 0,
      "output_sha256": "ddb44208c8f399d59eb113558c0251217fda0e7ecad1e71e051fc63dda65a3d9",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7365,
      "exit_code": 0,
      "output_sha256": "01709975a51b2935270295117aedfcd7f007edb655cbd4908ca2a8db21f032e1",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 6992,
      "exit_code": 0,
      "output_sha256": "74a18ea59a02e379b1e41ca420a2968f6f621de70da3c22b41973ac92bc18168",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2919,
      "exit_code": 0,
      "output_sha256": "d2ac822b5cca20b47387a0ea65bc1f61c013a6e88e50c4550647cdd01268b058",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3105,
      "exit_code": 0,
      "output_sha256": "cb1428767fcab855aa3f972ce2ee3f5d932f749ce3c6eef89c8ef8b1300a7a5f",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3218,
      "exit_code": 0,
      "output_sha256": "2a9fc60ce81a381eb592da9c60e372a94c5f8c27c845fa0b60f906eb2eae25b8",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3052,
      "exit_code": 0,
      "output_sha256": "35750e8b17f705de8972694cd18167f759989cc7b91fc0023e6bc8587525d49a",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1277,
      "exit_code": 0,
      "output_sha256": "abe9f4aa6e7e7312a489a4d8c874c3a32ae64c347478816f0303b07c5ef8ccc4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "b354b8b9ccee9b9342dd6f4d79fab232b967b90fd7cb1529339fc239f73db356"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-4f5a26c8e6511f32",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 101789,
    "exit_code": 0,
    "output_sha256": "5dd446391022173313bd3e6058ce5c22b81ddb6b95c5a23c7d03ef91219c52e8",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:4073d39caa519e184daac004612e66e12d7a44bfd4b2da38541a75afa764cd37",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Source-bound proof refresh — 2026-09-30

Recaptured proof `phase73-c074af70aabb1425` from the current governed source manifest; prior findings and owner history are retained.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-30T07:26:36Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 28255,
      "exit_code": 0,
      "output_sha256": "ee8218c6ba37b9853773eb41eb7a3bca9acc57d555c41863ef074f01d336a026",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27228,
      "exit_code": 0,
      "output_sha256": "80c2c1f6550b42e12cfa1b34266613e7f1d4f7f858995f6688f70b1a85a0afc1",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 30714,
      "exit_code": 0,
      "output_sha256": "1068e89e18b3953f7a75abe229a25cd94b749b049a17584502582127285e15cf",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2987,
      "exit_code": 0,
      "output_sha256": "42faad909139b26808d3d8b6b503f14b4c1a8201cdfdac7512a01b9099ce85d2",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1842,
      "exit_code": 0,
      "output_sha256": "d4e804facee39f7b87eac1f495c97b8d88cb745bf9743641cd8a2284f4e5ec14",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2692,
      "exit_code": 0,
      "output_sha256": "1f23746b0b4dbf415c2bcec567d7bd154ed53ccfa796921e243ff617909bf896",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9251,
      "exit_code": 0,
      "output_sha256": "d6b268eaba2eb6f6ec3dd8933646faaace44cdc655beb142f1fe0a60a0640755",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6469,
      "exit_code": 0,
      "output_sha256": "d4d9ecab3c83bf0ba9161a9557f8a8b383cc1bc6e349903a153cc3250db26ba4",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1176,
      "exit_code": 0,
      "output_sha256": "d2790b7cd2e9fca6e153a8036640994643c48b7a6fc86e8c387a49f5273478c0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1090,
      "exit_code": 0,
      "output_sha256": "143c9799771e4cf27d97804de83b2c6128dc611b1d0c38e37b6bfda8ad253d4c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1230,
      "exit_code": 0,
      "output_sha256": "0d12861fb50f738e52765028ea4cddf99f8c319029ef434c157303a06c1dcbdb",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1249,
      "exit_code": 0,
      "output_sha256": "90a1994bcbf8e10d1e4d1cc6671f07e4339a910f6caf92b3bd3969167dc30d84",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5392,
      "exit_code": 0,
      "output_sha256": "4932e7cf84ece46e21bc932ae6db3920946f44d82242045ee1ea529efb5f4564",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5827,
      "exit_code": 0,
      "output_sha256": "984b6653b185e58870a4ab4d343f9a4e52bc6fd823e6c04e20a312b81d9bf408",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1261,
      "exit_code": 0,
      "output_sha256": "84889ae57259559a3b6b58f1bfbe7729f8a98fbcde072538527e0865ad4b455d",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1155,
      "exit_code": 0,
      "output_sha256": "c88688a5a0119fd26faa16015683f755b7f5195785096d2fa666fa175554a292",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3017,
      "exit_code": 0,
      "output_sha256": "d2a1d0d935da5ff30b48d278295651fc6f5700109fcec2443234514f3f6373cd",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7127,
      "exit_code": 0,
      "output_sha256": "5279ac207a5bd0274d73ecfb8c6acc2e5bf5b9883cc49fd83d74cf8bcf8b3ab3",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 7478,
      "exit_code": 0,
      "output_sha256": "6a3feeb250a920af84f9698cb38aa44928053ce76d63002c8cb0cf062f2228ba",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3608,
      "exit_code": 0,
      "output_sha256": "f95a486e3672de43e210f9665986a7981abd2b2a3824b19c8838e4935ed81ba8",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3179,
      "exit_code": 0,
      "output_sha256": "46e747bffe862f6c2d58c48de7464ffc389147b81303758b1d8a3f992e3785bd",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3306,
      "exit_code": 0,
      "output_sha256": "d0816d4b656da290437cd9d8819fcaad00baa26a68c9e23610e5bb5637b119d2",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3306,
      "exit_code": 0,
      "output_sha256": "2efa1e5aa310b8d69e71c718a8e8888356847c24c9a87b42b4921fc3bd98f282",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1145,
      "exit_code": 0,
      "output_sha256": "4832baedafba194c6361dfaa48d98de0ae6301859d1e79cffc865030ddda67dc",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "10e4422b83a7590678d91fadb847dce0788cc1a7504a9f28bb05e482c54a5177"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-c074af70aabb1425",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 149938,
    "exit_code": 0,
    "output_sha256": "7103caa2180b606400244ea6d758e51d1bec18e852b7e8a8727432e6070d3b77",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:5aae8e0d058579458b5f4da587af4b2c98c1db9708019d9519185dec66326c13",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-30T09:00:43Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 26713,
      "exit_code": 0,
      "output_sha256": "f06125ec77b3d68300bd476e6238d250cbff13da711c21b4c8d51e69ba1f36ed",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 29508,
      "exit_code": 0,
      "output_sha256": "284c8136ebb286be8a797262cef5a2024c8706779b4edd9f33651cfee0efedd6",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27412,
      "exit_code": 0,
      "output_sha256": "88248f48a2cece1046fd37a21dd59b95fed817ba34e933bc1460e559dabf6be7",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2299,
      "exit_code": 0,
      "output_sha256": "2395b5a389f53c7652240301cf5c0c88171e38a69a635b7278ee2effe2f66ed2",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1775,
      "exit_code": 0,
      "output_sha256": "145f4e736111705edb09026a2d8e6c68685ff41b68f21a245c9d5500b44e55f3",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2807,
      "exit_code": 0,
      "output_sha256": "07e116f6b5d521d98368f0585ee9b57612d62705142b99a8560d08f719165002",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8425,
      "exit_code": 0,
      "output_sha256": "f4883c39e6628b547d4a7c365daaab03f16c0c3e6d88a447e5959967f6f8540a",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5156,
      "exit_code": 0,
      "output_sha256": "23900d69261b9aaead57065ed4328bed0cf5e81b7f0cf5fcbadd3f01b4686ed8",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1128,
      "exit_code": 0,
      "output_sha256": "9ae4c750540ba81771112a482d6caff3d9fb0eae8a3312d4287b9e214733f5a0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1052,
      "exit_code": 0,
      "output_sha256": "f0a95f6e1625fd530577a4567220db271c376e3ee976c4cdc594babce75b31ca",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1232,
      "exit_code": 0,
      "output_sha256": "2be66ca8816dbf33d297348cc01c61125e2eb19366a952cfd7eb8aab9ce9de86",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1320,
      "exit_code": 0,
      "output_sha256": "247058cc4ce7eeb84a2826d815a06e296f958e44aa45f348aab561ab3e5869a5",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4352,
      "exit_code": 0,
      "output_sha256": "d11ce3f7f9520e6c8ae448b3875827b062a5ae1f09446ea2532167b8cca0c4d5",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4588,
      "exit_code": 0,
      "output_sha256": "f1f201f1f42212a4490ea82a20b8c52d41c01182dec6a88f05e05275114a682d",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1140,
      "exit_code": 0,
      "output_sha256": "dafa5cef8d3a63d77527104c1ee76e2bb6f99822b51e82531a5a1909c829fa68",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1126,
      "exit_code": 0,
      "output_sha256": "3fc10bcc2ca2a6a980aaf263cf0fe4fd7d3ca7d025d1a7f8295aa86dab77e792",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2408,
      "exit_code": 0,
      "output_sha256": "82e437a48f7215083d0729e4d0c61255b8ff9746035e2101cebcdec71f003286",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5976,
      "exit_code": 0,
      "output_sha256": "d8e1098187a9614e1ee8b754998bd32178682d20a13883b489984fa200ecad3b",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 6507,
      "exit_code": 0,
      "output_sha256": "8a690054d2169f35f6cf4b05f2d1a9d1098acf066918481d06029a3e57cc71d8",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2356,
      "exit_code": 0,
      "output_sha256": "ac3d58f1715e30e878c748d37ea90000356d9eada8427ee101557147e82ac0fe",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2428,
      "exit_code": 0,
      "output_sha256": "7fba801338f1602c82c7342ee9217c7e19733f31696b2e064f558f301944027b",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2416,
      "exit_code": 0,
      "output_sha256": "9b4a70ba4ceaca983bcba82f4a5801bd557a5c6ff01a0472c5b208672347e341",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 2463,
      "exit_code": 0,
      "output_sha256": "69891c1d3c29ca5792035c1d7e116e0ae7f24664286eff4bb89eb8959065ef94",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1095,
      "exit_code": 0,
      "output_sha256": "4b253e0749125d438596ddedfab4230f979734afd5f4d52b6a062c6414c77cfa",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "cb3192644592cd43a03c5844931887a6726ad23bb5ff0d3bc75421c968cf8c8e"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-61008885a6735b8d",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 149543,
    "exit_code": 0,
    "output_sha256": "20352bac2b54e69deb165536fc19065a245f3051a97136e3b70891190b3f556e",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:6af5a3441562ebc7a28e0ce1e087050b5c8bec4d492f61d020a0949ab0153fbd",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

Proof refresh 2026-09-30T09:57:51Z: Phase 79 updated a governed classifier fixture; this new proof preserves the prior audit chronology.
PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-30T09:57:51Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 44451,
      "exit_code": 0,
      "output_sha256": "dcd8f050fedee8cbaac4d46042e6c9f339b70e401d71dadc1a2fe2973803a22d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 44117,
      "exit_code": 0,
      "output_sha256": "7edb3438b64ac8319e54493671540c5ec2ee5a90fa4f4d81ebd63d90a611ccba",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 46072,
      "exit_code": 0,
      "output_sha256": "328f56cfd8df70b62dff63f1b7f372ebf515a1e598a7e9f809558adee21e6a9d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2750,
      "exit_code": 0,
      "output_sha256": "308c87688b2ffee77c20e46662e506433670a67c7f9ddd8fb6e0b1781f918295",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1780,
      "exit_code": 0,
      "output_sha256": "47ee32c8e14b5f6f0130b6808174c0d366cb97e71a224232f675ead205413de9",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2716,
      "exit_code": 0,
      "output_sha256": "d16b938333c68d689ff9053af4d37dcb43d6a773eb56a583967bea53a85f7d12",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 13132,
      "exit_code": 0,
      "output_sha256": "51079c7be26d53559af73d5be95979214023fc8717e23c90ea0ebb023557a79a",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8289,
      "exit_code": 0,
      "output_sha256": "06df42af928f395970e17417a2c4e8a51197f476ed5e6f9b41f5451e9119c224",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1589,
      "exit_code": 0,
      "output_sha256": "24c5536cac20c2443260e6c0bd608f58bb6ff5abdae3ee8aca7bbf9beae706dc",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1493,
      "exit_code": 0,
      "output_sha256": "8cd493c5f155761f9512c95e134bb1245aa6aba5f5135cc5d1450a0761f959c2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1859,
      "exit_code": 0,
      "output_sha256": "d565523bccd0bfc0c4b5d723d87d65a7a4d928bf2478ef7c07db17205514a8e7",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1855,
      "exit_code": 0,
      "output_sha256": "4e80ba664c92161fe7dfac8aff730b7c19f373648c446f54fc5f0dcbd5bbaeb4",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 8333,
      "exit_code": 0,
      "output_sha256": "f4d0602e21188b60aee3dd87cb4de2db12ac191338cfc975a5aff68ce06ab586",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7989,
      "exit_code": 0,
      "output_sha256": "0ea8764676550141096b4acd7a77554df9d9b9c30ccfab7277f4499e9c079183",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1606,
      "exit_code": 0,
      "output_sha256": "3953bcdf3ab26ac768f3d67fe0bdbd9a0d67806106a835af9168fed6f61b6f9e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1652,
      "exit_code": 0,
      "output_sha256": "04e0d6f91296828c3a6f2495fac345ac2b439338e1b0446666ba0b4fb6dc9c55",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3979,
      "exit_code": 0,
      "output_sha256": "65cc1ae385e2054a2987de84500279029520d2e7513024d8fc19a5239bcab14f",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 10826,
      "exit_code": 0,
      "output_sha256": "bb0c18b04efc38eaa08090bf695ef4be2fad2dc9fefc4356788c1ff6ff44aabd",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 14165,
      "exit_code": 0,
      "output_sha256": "d0269a1c43db3815d36723cda81e3a8fb545e5bf69299482722639701dfc5f3c",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3038,
      "exit_code": 0,
      "output_sha256": "75219f7f3fdf85ab1bff2dea3a6a22f379c9fd77df117826cc5c0f7368f50691",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 5024,
      "exit_code": 0,
      "output_sha256": "a51fd9c786398c33d63b6eabdc2152c13879b178800868f3a1a441f7d873bc73",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4405,
      "exit_code": 0,
      "output_sha256": "9ac57cdf034f8c24ab0aa8ebe5b349f8ea524fa3f7dd1be45a1cce2b0c64a10c",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4131,
      "exit_code": 0,
      "output_sha256": "7f72c404ccdf3e1e2f2ff35d7322ada2bffc410a0214aa9925b4fdd68e28bc39",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1554,
      "exit_code": 0,
      "output_sha256": "7afacc81bce79de259fd33df46ab711288d34ee2b9a39261cb024d3f8117f784",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "42702829065804c1aae0e63ddd6d556b39f96445420e646e29804cc940ee5676"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a98cf8e53a4630fb",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 150294,
    "exit_code": 0,
    "output_sha256": "792295cb0f038abd619a88758fe9b3dac1e49a1e0c0517cf99d8f5abe5dc02aa",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:81b5e39017eb02f384b813c5ca64492cc7d8fa8c2227014d32c9ca369f412df6",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-30T21:23:26Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 56809,
      "exit_code": 0,
      "output_sha256": "1d82d80160f453c24830c9b761696206270e9078f60d485b17c7b41608c4bd5c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 58441,
      "exit_code": 0,
      "output_sha256": "5b66fa07efeed3e5a2c3c32a644ffceeab0e45ed33ab25ff657c43446f8e7094",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 54252,
      "exit_code": 0,
      "output_sha256": "3a80e2358e84ea6056630837e04a94ae1bb69404e7bbe937686fe6207e805135",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 155
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3809,
      "exit_code": 0,
      "output_sha256": "aa834eded64e97db6ce1541c56a926540249e2a1da297084607874a2ccf4bf05",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2542,
      "exit_code": 0,
      "output_sha256": "f9ab1da03c562fbd8cc1cfe0367310f4a1275756a0586a90453b6975497e77e5",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3392,
      "exit_code": 0,
      "output_sha256": "f55a3e2ca7a2d458e32b199c6b3f93bba06ea9f8311153e7abf1b2fe070afaa0",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10933,
      "exit_code": 0,
      "output_sha256": "6cd4dbdfb8202d0dceab3e49138e89f7d896ae100f59e92e668ec3f7c9427b24",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 9144,
      "exit_code": 0,
      "output_sha256": "8ba6a102bac2f3d00427d47134ce3a8662f46ac3b811a9758e328d7f07969c42",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1370,
      "exit_code": 0,
      "output_sha256": "cdaa955581852228473d13a59036608b20222b3100c657b5a220254c6eb05942",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1285,
      "exit_code": 0,
      "output_sha256": "0af4128cd22c2d2d635f28a03fea8241888338b94e112fc0392f666c432f1e78",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1649,
      "exit_code": 0,
      "output_sha256": "dd460ae03cb1c7ee7f5173717ce489204c730756f45a2541708c7dafa65dfdd9",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1759,
      "exit_code": 0,
      "output_sha256": "8a4b9ebdde49ef3cd3ea17e582bcd4f35147a04da0cf83ecc9200006e5e4ce27",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7961,
      "exit_code": 0,
      "output_sha256": "23317a8d975d8bfe4e86f408cd825d026b4abb9868c8b8a7e997f5fc1aead167",
      "summaries": [
        {
          "excluded": 84,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 10107,
      "exit_code": 0,
      "output_sha256": "9c22c7f77a960b741a9eca1c0fd7336f2fd0b8166f7ffa3928d62be627a17ad2",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1383,
      "exit_code": 0,
      "output_sha256": "c249ef7da17ea0643968ab3dac5f2541e477dc70e5b7664f7dc5576a387cfb3d",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1342,
      "exit_code": 0,
      "output_sha256": "a70bae7af546a102dd1ebca110e15589688a1468c4e67fc9d3bab10a3e4c9292",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3915,
      "exit_code": 0,
      "output_sha256": "b84161b7b205abd6d3df1c029319be63567327856f2e552d76c361196653316d",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9345,
      "exit_code": 0,
      "output_sha256": "f1f68f9593bdc2c122362007c9cdb977b604e1e0e96f80e6bd334b4d7d816ff6",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3804,
      "exit_code": 0,
      "output_sha256": "a47f1e629fb68654a17deedf79a8ac1b27b062d4504ef0746c87a5989a24acc7",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4288,
      "exit_code": 0,
      "output_sha256": "d5a1999df6c3632cbb4ec2dc82bd53244d844cbab8d66216368fc79ee33784ac",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3801,
      "exit_code": 0,
      "output_sha256": "b81e930de356e91df3b31a918e3bdec052a7b3d242ff16461a22c172986ee774",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3857,
      "exit_code": 0,
      "output_sha256": "dfffc57c2e169c4879d70e9237e3537ab0c50f55aff385c30e4954583a7be749",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3789,
      "exit_code": 0,
      "output_sha256": "19f51f59bdc20b74801d2b962e35b3a3104552a2753cd1d253a187bbc1bca1e7",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 2605,
      "exit_code": 0,
      "output_sha256": "9012e0b4f317a350b385cbdfef5ba64a6779f8d1c46339a84bc3d4530a1fa0a0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "80fc865ba82fc63da84076461f71f05ca3b07700f9685bc217f4af0ba7089b04"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-4f82a31b5b86c7b5",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104351,
    "exit_code": 0,
    "output_sha256": "265f1e2b7d24bb9e1d1608a55d4be21a95d6fd445b62a214f7671325ae9bbca0",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:63faf8fae6b694c1f0b535c7e9d0ca51c269e371a91cd5368c7b5e6770dac97f",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Phase 73 source-bound evidence refresh — 2026-10-01

This append-only refresh records current governed sources and the repeated focused, mandatory evidence, and security results under proof `phase73-0e2474a0fd58f14f`. Earlier proof blocks, findings, and run histories are retained.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-01T01:17:01Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 48598,
      "exit_code": 0,
      "output_sha256": "3f80d7cdf23f1665435cfe305cc3b7d9a9434d08e2ef9a97aa6f596364ed22e3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 156
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 52820,
      "exit_code": 0,
      "output_sha256": "20db87fa471a01368561a8418851a9fd4e9474df1d19e95b7267638be515fac4",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 156
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 50582,
      "exit_code": 0,
      "output_sha256": "f4af95b793bd0e94d741718e312b831eff292ed0eced0d1bbb27bf8c6a2e7d8b",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 156
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4099,
      "exit_code": 0,
      "output_sha256": "b1606a412cee0123fea938ef07fedab9fd6c60213d523c50b422caab4a51f099",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2572,
      "exit_code": 0,
      "output_sha256": "c87543ec2e7f029a4507894bb210c2c7c9d02b11cbde09f2c8bf39206c0abf6b",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4048,
      "exit_code": 0,
      "output_sha256": "d407d3538cc063be49c582128bba2a41b3786cd56f987176104000e020eb19f0",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10630,
      "exit_code": 0,
      "output_sha256": "53664ede6db25912e09606628207d3e90bfd6a60b2687facc2dd43d922badc07",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10087,
      "exit_code": 0,
      "output_sha256": "b22d59ff6d0ec77a487834b555bfc84ebbd1896a82ed91a3b65c3651c88562ea",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1686,
      "exit_code": 0,
      "output_sha256": "ad7192dd6f59d6014a4ac8bc20e0c49563f7b60fad80885ba02fa6da5a6577fb",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1755,
      "exit_code": 0,
      "output_sha256": "d857c153848c223a8d336c14120000b14b0da211dd43a483ebda7f2083322208",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1986,
      "exit_code": 0,
      "output_sha256": "5d4e0b91e5b74a4b82eab5283875c57df3ea826a028a8c8c47f31c83d9b7c58d",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2087,
      "exit_code": 0,
      "output_sha256": "e1040f5d80bfc0c774371e0c4daa33361d4b04421d2022592e868fed0d469647",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9431,
      "exit_code": 0,
      "output_sha256": "43e25ca618ffe34b65ec0e349825612f4ccfb3a782a74129e8329a137a6401ba",
      "summaries": [
        {
          "excluded": 85,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 8572,
      "exit_code": 0,
      "output_sha256": "034deb1252864bcd64213fb36fb3b1bd559e907fa455c0a09897f2c10360d557",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1767,
      "exit_code": 0,
      "output_sha256": "dcaf1555728e546d80573516135976bd54f7afa3beac28836e8d990b0a3b09ee",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1917,
      "exit_code": 0,
      "output_sha256": "f7c0b69c50a753c3fdb19fab1fc41b95d835d799b2788767b2913e8d6744f259",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4613,
      "exit_code": 0,
      "output_sha256": "901d789bbaaf16c153822589ba186e454a08a51641325448aef27a69a1a23ab7",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 11820,
      "exit_code": 0,
      "output_sha256": "8890a3a93832c5677f546fa6a58afcdc48e973c6286fc928d14be8d6bb0c8153",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 17263,
      "exit_code": 0,
      "output_sha256": "0e576e7adb1bdd1043ee1fbb059a781cee6759631d8a5c730097857efe57a1cb",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3699,
      "exit_code": 0,
      "output_sha256": "5bacd181371365c19d9bd1ff67511807ce535c688332de42139b4bc95d5b6615",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4252,
      "exit_code": 0,
      "output_sha256": "aeac8cf7a8218c449e9930afac429ccf1eb0b2701e0b48bdbfbc6f2d3ec8fd7b",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4897,
      "exit_code": 0,
      "output_sha256": "7cb64c7eb4c1845300de7575022ab2f7ee883227da16be70decb63b37f61f5d4",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4464,
      "exit_code": 0,
      "output_sha256": "2815c79cb91c0340c1527468040c879fcafc79d35985334f9ab14d743ba3cbf6",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1608,
      "exit_code": 0,
      "output_sha256": "217f09f9dd892aa8a62d8571f01067f4404e032a5ea61b057d27cf9bc40a0a75",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "9cba3785f19bc33352dbc3478da73c0d7b56b01c96cc5ef53489eb8470c41624"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-0e2474a0fd58f14f",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 144212,
    "exit_code": 0,
    "output_sha256": "fa90ab6bf117ae71904c97b9c80e0c3ee57512081b834c240f05a1d96d2625fc",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:2d90d850203fedcf2cb6b44d64a37eb09b9439e778bdaac8181fecca15721543",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Phase 73 source-bound evidence refresh — 2026-10-01

This append-only refresh records the current governed-source tree and passing focused, evidence, and security lanes under proof `phase73-0b6dfc7bc9eb56fc`. The three mandatory evidence runs each passed 157 tests with 0 failures and stayed below the existing 60-second guard.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-01T15:38:18Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 41607,
      "exit_code": 0,
      "output_sha256": "0772138d4329ba01be22bf42763b8179fa8df93c6be80f5856a279b618566214",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 157
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 47543,
      "exit_code": 0,
      "output_sha256": "edfd2458ba772d95f88cb8a86000ea5e028e6894da512a4c7993c83cdc53a802",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 157
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 43868,
      "exit_code": 0,
      "output_sha256": "fb993b8891da17ceaf87177c7981ae2612bb65e03d908aaa452d5a7813729b84",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 157
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 9492,
      "exit_code": 0,
      "output_sha256": "a65e6da319a968cf132869d05632dc31e2ffd22cb50410a5f3364f7ae8d523c2",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 4819,
      "exit_code": 0,
      "output_sha256": "c369ab88c922a74dcb1ff398258fcf6990d855e41de7a2925c9c927f0bb1a258",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 8187,
      "exit_code": 0,
      "output_sha256": "247bd88225ac97747291457eb9b661d84107098ea06f2a566ea359415ef788e8",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 14176,
      "exit_code": 0,
      "output_sha256": "bb041934a7dbfcfe682271891d0f65c64fccba1c388d628354be2183c68d9d28",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 9857,
      "exit_code": 0,
      "output_sha256": "5d46180b1a7c171c2558f521031963137e3024285901afe348d71288d855448f",
      "summaries": [
        {
          "excluded": 87,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1769,
      "exit_code": 0,
      "output_sha256": "7610e416bff7f77db1c46b36b1f85f3bf2d32d1cc3a73445c86a41ef995ecb07",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1388,
      "exit_code": 0,
      "output_sha256": "db70389d4d0ce0a021eced107a11a784f283f644510bd69ea9682f2328bfd20a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1740,
      "exit_code": 0,
      "output_sha256": "92e91e16afeddf0872b609b0c4a164b0bab437c1063fbd189861f207c832d958",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1649,
      "exit_code": 0,
      "output_sha256": "1f20596ddb4eeb013ec54fd91b6f0915e0537545f3ef705f3b78d9aa19dcdbd1",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 8831,
      "exit_code": 0,
      "output_sha256": "a9ed954330c0852ddb4ca2672c28f03873d43716b0adfaa33919fe0e04eae9d4",
      "summaries": [
        {
          "excluded": 86,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 8392,
      "exit_code": 0,
      "output_sha256": "0394d671aee223f71a47de9c19f2fe37ac940cd8f0a6998a43619717ff386cff",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1543,
      "exit_code": 0,
      "output_sha256": "39b087d30995b3d278d708cabbf74644ff54d3e25cfeb25a05f3c678ae501cbf",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1568,
      "exit_code": 0,
      "output_sha256": "d6e67c59e723bb335d4913710b7f766a5be687bc9aabf6e51e7983e54ac40f0e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4763,
      "exit_code": 0,
      "output_sha256": "8732d5fbcdabbacd7eb4cb2515a114b3ecbd543f192a6854c6be94918d0bc0f7",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 11915,
      "exit_code": 0,
      "output_sha256": "027512ae67bc6f1aa28298a43428db6fd20e06c3ab873223e8a02ef50545ac82",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 14144,
      "exit_code": 0,
      "output_sha256": "a02fb9009fcf6a9e75ad17a0d1d1087d54765760bb7d0d9b4bd1cf2a11540015",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 5241,
      "exit_code": 0,
      "output_sha256": "501795df7f16ac3fe1d74bf847dfb513f01bbef375498ec74e28972d922337c7",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4840,
      "exit_code": 0,
      "output_sha256": "c7569c99298da809d420cca5572256f699b6bdfa1878f42d59ff34fea4a919eb",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5131,
      "exit_code": 0,
      "output_sha256": "d17a46a0ccfe641e58423a0272804dd546a47c38e30b154ae044a54ba0e90af3",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 5289,
      "exit_code": 0,
      "output_sha256": "c9f7d6b2c44a9e80770fe6a2bde6513f0c08c0fd8c6b65170f611097370f6150",
      "summaries": [
        {
          "excluded": 88,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1631,
      "exit_code": 0,
      "output_sha256": "2f83ccde06c6c1cfc8e74f38e0029bf9b4567f708207d0e4ba59832791df3abb",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "113394b09400529ed295e99792afa61d56f8d9ef22d84842804d25cf98a64165"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-0b6dfc7bc9eb56fc",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 103488,
    "exit_code": 0,
    "output_sha256": "cae94fc998c530fcda95de8809c763b784c28ac2ef7390545b50d7c67a9be670",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:bde2503f1305644b97afd0b0fec0d9fc4efe7098de6ec43766a321d1b61190c5",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Reconciliation refresh captured at 2026-10-01T19:47:49Z
PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-01T19:47:49Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 41014,
      "exit_code": 0,
      "output_sha256": "9bef610a41b27517e7bcc252d556187936664eeddfc91a0718847ea426eb7669",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 37999,
      "exit_code": 0,
      "output_sha256": "ee17d467e277e5cb7019d359c5e27a682248c2bb9d69a0f27c344d40492fd4cb",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38546,
      "exit_code": 0,
      "output_sha256": "16bb450d7f6a8aab14b2bf0d40e8ad5b5d53382aa87f49c71fa605a0b57bc9b1",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4519,
      "exit_code": 0,
      "output_sha256": "51c40a8702a1150047554790b74333eaa4482c770099aa646965f57e6713ed34",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2062,
      "exit_code": 0,
      "output_sha256": "75a00834547b3bff0136d2e8db1b3b388ac41674fadf018958b3fe5c8003d6a8",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3063,
      "exit_code": 0,
      "output_sha256": "cb5f7f853afbf28d3612f301ad566a3042ac55e44d6c0b19560055a83df3b89d",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10069,
      "exit_code": 0,
      "output_sha256": "6446e5e1e206a68e012c8cf8fea62fc7397891120adc0dd34151fee427ad8856",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8054,
      "exit_code": 0,
      "output_sha256": "b8f6aa4e88c0a91779be75aaaa3d6bf1769528f4286c928d9358f747a9a4cfae",
      "summaries": [
        {
          "excluded": 91,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1325,
      "exit_code": 0,
      "output_sha256": "df8939a22335d52f497373920e8c20f675c5ced51a95ce781e22f37270e7a094",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1176,
      "exit_code": 0,
      "output_sha256": "a38de5ef8ef51609ae38bf8f9c156825207606eb8bec4b26dadc69fce0917a88",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1345,
      "exit_code": 0,
      "output_sha256": "0aad421e4e5860b78640b69dee05fb729894d576300b152a8faf16f191c01cc5",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1329,
      "exit_code": 0,
      "output_sha256": "507038b8c429ddd89a106d31dcab7174b89814f3a0504dc208ba5149d7afb6ec",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9604,
      "exit_code": 0,
      "output_sha256": "aae0ef055c61d47e8542e13ce2f59e757d3dddda20fdede6f52cdc0af03dfa8a",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 12990,
      "exit_code": 0,
      "output_sha256": "34e1f6d57b531231dba082ccbf56b3619f89f3ed259e85ef2ef943c0ffbfdac8",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1990,
      "exit_code": 0,
      "output_sha256": "6f0e52393a4902be08449298afd348a34c54272c264313ce79458d3cb4960a22",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1730,
      "exit_code": 0,
      "output_sha256": "5200129244596a8d8c399e8aa557d01ddb1ea96dace712603ee76df40d1bc370",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5357,
      "exit_code": 0,
      "output_sha256": "71fbba8de2c5c08f4356f5b45c6b71fd4cb442e06f9e1b96045a48d4ce2fe45f",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 10971,
      "exit_code": 0,
      "output_sha256": "137d02649ed95af5e6aff36a420472878f72d4fb9d4819cb882fb05093107858",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 13836,
      "exit_code": 0,
      "output_sha256": "0526a2dab470bc8d2234cfa18be6dc34730bae600d29dfe6bcd0eb77414fb70f",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 5592,
      "exit_code": 0,
      "output_sha256": "9fa4f684ab18544a848173ff327467c1751af2a59170fe2bda21d0ddbbeaf096",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4576,
      "exit_code": 0,
      "output_sha256": "aadad087847d5e3d7df5a3b28d255080ff8e21a7e999a9791f80d5f202dbb322",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5317,
      "exit_code": 0,
      "output_sha256": "662cf54eba026c6ccbcc6e221e67e13dd1ca52d12aca7c143384e96739e18ea0",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 5208,
      "exit_code": 0,
      "output_sha256": "3ccc7ebbdc770a75aaf359d3f8567f4e7a7b2287ac41fc3d0fb5b501f938c22d",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1465,
      "exit_code": 0,
      "output_sha256": "bebd4247d2190ab2098402f33f47a95a257c74893ccb122b418b906931eb97d4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "886bb5208774a403c0bc0af68a34d5eb91f79794f9d811e5d632b1e2f387f8ab"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-1b688ac38ba3a617",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 102130,
    "exit_code": 0,
    "output_sha256": "6576d587d9d33fe6f573fac745b64bcd228513d1c8681d3c2513cf384338eab2",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:5c81dfd0055926061fb70ca8f031fe267c7b031ca92afb8afa9afdd020c73500",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

### Phase 79-07 source-bound refresh — 2026-10-01T20:47:24Z

Proof `phase73-d03a824ec5129062`; source digest `sha256:8bf6d5c81d14b1e18110ecda354bb13a0e9ad4c67adfe41723f454bb5ba46470`; proof SHA-256 `da585ff3539f102edbaa9d9325a0ace9ac18615c4081f4817aebe6910da90c6f`.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-01T20:47:24Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 35616,
      "exit_code": 0,
      "output_sha256": "59de0964d4fbe667fcf8d9b58faecbb00ebe200fdab9a1f28a45f78b50f2593a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34847,
      "exit_code": 0,
      "output_sha256": "189815514bfa9034fe5524a00da1f787dda6e02934c0a068ed1da726581ca0fc",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 35641,
      "exit_code": 0,
      "output_sha256": "ee89cfafc4e0b939b50f983034f9a0aea53bfe68c0033143925c3ff393121f02",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3909,
      "exit_code": 0,
      "output_sha256": "ad95d9f4d66ba2a2f183050666dd7131ce606816bc7b20a64ebbab11b1140c5b",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1948,
      "exit_code": 0,
      "output_sha256": "112d6cfd796ad6a4002312b8f2e2371594bbcd765cfdf9355862a2d47bd05ee9",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2925,
      "exit_code": 0,
      "output_sha256": "e6d330e1b792189b85486bb01a04f9711e66a7979d12da41a4ab4a124a4b7267",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8997,
      "exit_code": 0,
      "output_sha256": "8f8cfe26647964d030d0b8b7066d1aba8699c6aecf63766626692e93b0f4ca2a",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 7574,
      "exit_code": 0,
      "output_sha256": "7efa5e6eb82f70bda2e59fa8e9d3974b456e11a522f2b5e184e3ad5aa00d7b85",
      "summaries": [
        {
          "excluded": 91,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1196,
      "exit_code": 0,
      "output_sha256": "7372db3312bf35d468aa2edaf6f0af2dbaa5281c464cf6691e1287aed3c28542",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1105,
      "exit_code": 0,
      "output_sha256": "5ad292c37d5e50f9009c8ac161afcad00e26f2ea51960d8e4a9aec6b5a82905c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1313,
      "exit_code": 0,
      "output_sha256": "93fd524ae2a6654a3083ac92f87a7282dbc102d0ae13b361e00d85ab12ebcf0f",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1383,
      "exit_code": 0,
      "output_sha256": "655320801caf97aa5a529d67b22d22cecc1398df9e2fe891610a480b1d731147",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 6786,
      "exit_code": 0,
      "output_sha256": "9171278209613f9fd1e15898d3819e294a7a53f274ded2fd6119e9aab78682ac",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6667,
      "exit_code": 0,
      "output_sha256": "99a5724dab18142aade66741f01182b756f26a8369fa815b9a4ca3f0c2c53f31",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1240,
      "exit_code": 0,
      "output_sha256": "56636471df59f5ff9a7bbeb38cb5181cae420af85fd48fe98398c19dbddb62d3",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1214,
      "exit_code": 0,
      "output_sha256": "f114a816ad5b5d7b26a253e4091a696af9d7a41947f3a8ab7b6c3cb689c13cf5",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3769,
      "exit_code": 0,
      "output_sha256": "567b17b39157c5ecc553191a1add46f9444b54e1becfcb393ee7ba7d884bcb0c",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 8710,
      "exit_code": 0,
      "output_sha256": "9e7472d04139d7a36c321025eb5d48536250a723bfbe61a99b962c499fb94d16",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4101,
      "exit_code": 0,
      "output_sha256": "40751a6d6212e5b5734116b088b6e5987984cb77682fe7bf591edd3c47336fb0",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3935,
      "exit_code": 0,
      "output_sha256": "28c1a131985191c2fda2db550d851ed8d0d5d16cb7374405cb0fab415808c83d",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3918,
      "exit_code": 0,
      "output_sha256": "9fc3bae2e4c58f76d8482da0488ae742fa4665bf195be5a6333c821a92facb49",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4141,
      "exit_code": 0,
      "output_sha256": "3f74af87ae6894e64217954cae5c72ce065cb68a5a256604c88278222b499715",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3984,
      "exit_code": 0,
      "output_sha256": "f8c5ddbc2083f3ea125779d08dbef35a2b9c75c0f1d81e7f3d112ded43f3ce92",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1235,
      "exit_code": 0,
      "output_sha256": "3e443360f44276b739dc9df6043c66f3c44804ad0fdd90e33d63432a48c75884",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dd7552e2eb0d3f8bdb96cef141dfed643c564a0be348fc6c8ffce5b1268086d4"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-d03a824ec5129062",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 102036,
    "exit_code": 0,
    "output_sha256": "0667d6a1e7046ccb164654f1703f5e1ed149685551c30b65a193ebdc952fccc3",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:8bf6d5c81d14b1e18110ecda354bb13a0e9ad4c67adfe41723f454bb5ba46470",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

### Phase 79-07 source-bound refresh — 2026-10-01T21:21:24Z

Proof `phase73-fb68c4263dbaf28c`; source digest `sha256:87fd0a795ab3d21d3de7114e2ca4fff1c2d9c96d9f1572f314aa057532b22086`; proof SHA-256 `8799715760696443d62ed2d66bcfdd442208eb992007963ae5da29a21a3b5d80`.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-01T21:21:24Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 43731,
      "exit_code": 0,
      "output_sha256": "e94ff449f7f87599371cd4eb0046a6240b83d7dd46629bb46940be6a7ab5b4e5",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39528,
      "exit_code": 0,
      "output_sha256": "70bf51cb25b92b2219b9c54cc1575cd9a66543612000af7b0a2b5d120d77f9d8",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 36429,
      "exit_code": 0,
      "output_sha256": "578a10efcaf249b095758509bc0148734cb084a676f0767e422250ea23dc6823",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 161
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4874,
      "exit_code": 0,
      "output_sha256": "cacb291deb22ecd3dfff522ce76d1b04f0ebdb2873c6c3a2a6c15c1359b6627c",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2110,
      "exit_code": 0,
      "output_sha256": "d04cc6fb93a64799d1cdc2a065281c8c5067268d7a8a9d34a2f06067d9fe33c4",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3607,
      "exit_code": 0,
      "output_sha256": "22c2a45a5fe04f4e5b3827510ba18630017f154e9a31dceaa296cba5e3039419",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9753,
      "exit_code": 0,
      "output_sha256": "b75a2e426470f1bc35171f564585c8e4f99b05867ed0e2aec10f0adb5a92c9fb",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8697,
      "exit_code": 0,
      "output_sha256": "cd3d7568f185581fd66b10863fc8bdea6d70a639c71c9c2fcc5aa27d55c5971d",
      "summaries": [
        {
          "excluded": 91,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1339,
      "exit_code": 0,
      "output_sha256": "5a6e07ec618b54fad84b37aafac3e28701e8c4ffa7b2b50a23e79f95218fcaeb",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1168,
      "exit_code": 0,
      "output_sha256": "109b9742541b9f48375389acbb4045a0cb4a2d978561f80ae320f478862461f8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1451,
      "exit_code": 0,
      "output_sha256": "5e05b80d5fb40b77a2828a869143c907051df2180eac679955440ca6b7ec62d2",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1484,
      "exit_code": 0,
      "output_sha256": "4995a6af16122faa2265945db062966fb2cb1b0e26a258ebbb521dcf3fbc411f",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7356,
      "exit_code": 0,
      "output_sha256": "cfb1eac85a47e0b5806fea43cc747cab115a467f6436f9b766e08bc19fef46a6",
      "summaries": [
        {
          "excluded": 90,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7248,
      "exit_code": 0,
      "output_sha256": "e97099606bdfb1cf039679339dc87b6f0d77c94873c909d2c717fe4cf2dd7ff6",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1350,
      "exit_code": 0,
      "output_sha256": "0712682538ada51fc8d18c8b9f2762fb44fc3062ffea9a34a3fefe3dd335499a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1316,
      "exit_code": 0,
      "output_sha256": "fa222a520a009ae5db31f51850a209f54889eb58822b59399ba337650d1b2e68",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4391,
      "exit_code": 0,
      "output_sha256": "cb7a82e0f92b20b911f9afceaa7b1d1edb5b29d4f187eaf1531d0ab39156c8d3",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9784,
      "exit_code": 0,
      "output_sha256": "59a7ea6939bfda2c002ac850d104f68fcaccffd4f4254599bc9213fe3a6f54e4",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4096,
      "exit_code": 0,
      "output_sha256": "9baf83bf920c0d47bd55a049c4e58afbc7cd3e64e05b378d1882eff204fad2f7",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4381,
      "exit_code": 0,
      "output_sha256": "6a45c408a81c194ac020bff5e6795f82d31d4d07b3fc06a02cacc7cdfeb843de",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4202,
      "exit_code": 0,
      "output_sha256": "c586631988a4be328dc050326e5a0e28121a1d16f76eb36ef9fbec500b6de681",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4759,
      "exit_code": 0,
      "output_sha256": "50c29f9dee5788dee36d1288fc6da9dbda0ed4067dff41efebf4070f2ce101cf",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4065,
      "exit_code": 0,
      "output_sha256": "99bf84279f7d3a3880a488907fc40b7784950ed9a360cff9711ae2d66d07b407",
      "summaries": [
        {
          "excluded": 92,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1444,
      "exit_code": 0,
      "output_sha256": "7f2083c3748b1e920fa1bb9bcf70fa733820cc539e6780fa90780d9b88e55281",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "d0250b4806672bfc8c5380bbc66ffb3cf9fca1743636e0588570a1ee7244d320"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-fb68c4263dbaf28c",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104088,
    "exit_code": 0,
    "output_sha256": "0f47915b6c2b9440597e4a0a884b9889ea1d708022d0bc3c865decad032da3e3",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:87fd0a795ab3d21d3de7114e2ca4fff1c2d9c96d9f1572f314aa057532b22086",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


### Phase 79-14 source-bound refresh — 2026-10-02T18:58:48Z

Proof `phase73-52aa2013b75cca32`; source digest `sha256:bbec59c21bbbcbc68f70e89c06943fa67d3c0f2f9a13da91e363b9615c18b3d1`; proof SHA-256 `f47227b3cf19eea93ebca71b1e71fc8593abec599c1f02eea77ffd9fdfc9229b`.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-02T18:58:48Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 48835,
      "exit_code": 0,
      "output_sha256": "17866a47054c2448fdc7d666039176efe50c14337c5b0eb979ef56a163e63390",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 56884,
      "exit_code": 0,
      "output_sha256": "bec61207b45b60d2f80d8ea7364aefcfeb8ade66bcc2a4714c5029d4259f5df2",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 56371,
      "exit_code": 0,
      "output_sha256": "47cf18330f30eef6cb79a0f872313bc1bbcfdb9beee76655b50426a69465ffa6",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 5897,
      "exit_code": 0,
      "output_sha256": "6d4c108555159e27fb9f9e5f8ea76fe2fc867dec7f5d2456e49f72b3a56de336",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2454,
      "exit_code": 0,
      "output_sha256": "8558f3e6d8308599222f13c3765cc1bc944b3bc2924a73abead6756bd22a38e7",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3882,
      "exit_code": 0,
      "output_sha256": "84096d4940d2b755eaeb9b060b742f42192bf782fa2be8c3fad350a16f59860a",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 12134,
      "exit_code": 0,
      "output_sha256": "e18f8345aa5d8bcb64f6d6f4fc26275e4adc9b88923b74bd4e0db8cce6ebc72c",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 11205,
      "exit_code": 0,
      "output_sha256": "52e130ad0f8d79d50b041fb36f0b984bc0ef65f6c1523ca66ec63da4d900a9af",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1708,
      "exit_code": 0,
      "output_sha256": "f92b4a5b4b7726a1849c7fa4947348790a8c4e1dc42f041a0074f9e92be03c18",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1570,
      "exit_code": 0,
      "output_sha256": "5a533951e180cdf45cab82e64d98f7b83100cf91619f108bd8bc77dea30fa110",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1756,
      "exit_code": 0,
      "output_sha256": "0415a6895036d756dbe87022719dabcccc3e2b57b7b74a066138969de156a6d2",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1894,
      "exit_code": 0,
      "output_sha256": "82766096bbbde6cc7edd12752dd2c3fa0e07718b134ca498f017cd57363b9a15",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9568,
      "exit_code": 0,
      "output_sha256": "ad1af9d901b40a72d58e87073345dfb9aee91d3f2d6d84fdabf471667ee4a1f0",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 10649,
      "exit_code": 0,
      "output_sha256": "2a0ab9c9da53bdec8c9d6faaa307192f609a40554b20d11b1ade1651fb694581",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1893,
      "exit_code": 0,
      "output_sha256": "29a8e57719e09c42d638686e871e0d800dba0aeaa471b11a3711b1f8d757e9a8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1539,
      "exit_code": 0,
      "output_sha256": "b45fb48a79313852e2e1b0ba67aba3100a9a8171f612fc0bc561ec3d1b170f67",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 6850,
      "exit_code": 0,
      "output_sha256": "d1aa32712d3f4ea543f7056147cbb63cdf021d0ff2ae692820b353f5f5af59b5",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 16823,
      "exit_code": 0,
      "output_sha256": "807d56f03716d5b1978f2acc5fd8b1eae87840c1722b746fdde69389f5dbb726",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 18519,
      "exit_code": 0,
      "output_sha256": "fa000aac92b6bc584724bb1c1484948514c1f86dc1f1e9436b9a80efbedcae4a",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 6900,
      "exit_code": 0,
      "output_sha256": "5969785a68253018ccae3163dcf2166ce0c607d7caa8e20fdcfdf970e8b6add9",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 12047,
      "exit_code": 0,
      "output_sha256": "b630c3cfb492c18fd41c7722fdfe37a636d972bdd3ffa53178c3335ca025946b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 14771,
      "exit_code": 0,
      "output_sha256": "34841e948e63ac70d6050b5e585725da88fc5f16b7865caffe1bef8fcaa16d1d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 7064,
      "exit_code": 0,
      "output_sha256": "5bab6d6b6a0fb2b1d0c01806d1f24575a287168336553cc91673ad13e4701224",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1870,
      "exit_code": 0,
      "output_sha256": "b60c19688f0ab164653a47b0061bf0c808eddeee77693041c56e8e70de207b59",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "93ae3d8955f043471f6632c170331300a61f45a3c63b932c7d2efd2ba6652685"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-52aa2013b75cca32",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 100858,
    "exit_code": 0,
    "output_sha256": "d2bedfb4ff480f47eaff92c85255ea00f032292b41f8e047c8fb0c51a20c7fd3",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:bbec59c21bbbcbc68f70e89c06943fa67d3c0f2f9a13da91e363b9615c18b3d1",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Plan 79-15 Candidate Replay Refresh — 2026-10-02

Plan 79-15 updates the completed-plan governance contract to validate rewritten filtered-history provenance. This changes a Phase 73 governed source, so the proof below was recaptured from the isolated candidate with the pinned focused, evidence, and security command inventories. Earlier proof blocks and report entries remain unchanged.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-02T22:23:02Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 50264,
      "exit_code": 0,
      "output_sha256": "693521602afa5d9a9f6c4dc8e2b9672c1e484cc4e4f9712e5f89a99e86d9cd7c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 48784,
      "exit_code": 0,
      "output_sha256": "d04d161d1d30ff935815cd3567c2a4a29ee31a137ca32c15be3f00d1db474ab3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 48494,
      "exit_code": 0,
      "output_sha256": "e00b12197e381ba38f0d678838fa5a47e9fb0f54e211acd7228d69dfec69c3e8",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4833,
      "exit_code": 0,
      "output_sha256": "d3d30ed0de6a5396114a3d33d84218b4005c5a152efe5e89a3c71b8bb43aa2d3",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2556,
      "exit_code": 0,
      "output_sha256": "f2e186a62697439ef1448bea8084a3093cb6c88dc4beb440118b6f2053071fb5",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3679,
      "exit_code": 0,
      "output_sha256": "06ca2386a9caacf8445ffd59074708cf2436d5ceff936400c93e4fd0d5a41f6b",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10342,
      "exit_code": 0,
      "output_sha256": "74ac3b4ecb431a18b1ffa8206eb3a2590e78174e6127ae7f7ef837591d656b70",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10035,
      "exit_code": 0,
      "output_sha256": "424a6f198707fd5da0de51624cc9fa53c1a7a9b411101546510d374627ab147d",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1427,
      "exit_code": 0,
      "output_sha256": "a45d92f3c20237b82a142da68392fa4d58a35eef46683cf4fbc5f0dc6969b631",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1253,
      "exit_code": 0,
      "output_sha256": "bd3faa29a3eea4be8bb63a5545b31ae1224a2621bb4368fc4271daaaba7d91a8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1545,
      "exit_code": 0,
      "output_sha256": "8f34f75d33216eee8fbdf0ee0d5c2bb8c5d184e5d540ac6d05e12f5b806cd5a8",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1698,
      "exit_code": 0,
      "output_sha256": "5ca6c32b94cd1bc5e2976054c317279578ce9bbe488a89d3c42314caa8059155",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7540,
      "exit_code": 0,
      "output_sha256": "a491ae6104993c702e97c391bcb4ae80c4b42b790100c511e54bbf9864352662",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7708,
      "exit_code": 0,
      "output_sha256": "313f1b0a273f33450ffb73a924dd30c4220d43d65dc53b78a9d87af014c050bd",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1314,
      "exit_code": 0,
      "output_sha256": "2e0d0370bd8dd71dacca9676499b201948d91177c9ad621aaf51af8eee0d0430",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1324,
      "exit_code": 0,
      "output_sha256": "ea794d73f2b1b799cd1f7f687f8dc13469b6381a689aa5644a978b80544d2125",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4594,
      "exit_code": 0,
      "output_sha256": "71952cd122a59da14aa23e00bf6dc469ae8862adafb810c3228c632b4dfd6f96",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9881,
      "exit_code": 0,
      "output_sha256": "11c68d8182c8342bd511c3372aeae1cffd99b6dc166429a5f0cf37b2b4666ade",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 16246,
      "exit_code": 0,
      "output_sha256": "246e8be3e868821b947effc923811e4fb64e911a687bca70313ae0b14235f7cf",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4294,
      "exit_code": 0,
      "output_sha256": "acacb341238e16daea1c13275e77a1537d1b87c5ae71a83d1322f1c578264edf",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4441,
      "exit_code": 0,
      "output_sha256": "2dbe3629ec941f2aad0e0d1165f225bbcb17caddc9f5fca3238344f8c7ba8109",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4390,
      "exit_code": 0,
      "output_sha256": "daa668d02183a2fe2fc0be86ccf96a124ec972af93e62e03608de6d875cdd19d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4247,
      "exit_code": 0,
      "output_sha256": "7350e76a502a89d272c46451513e8d8f5467a08dabe2d9ebe370892be1eeef75",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1184,
      "exit_code": 0,
      "output_sha256": "8b0aa391a8db337c04d2ad1b81ab8124564db32f51cb3e7c9a1f93ed2da7a892",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "0efa189acd56c7d202e9e2d87da78b6a1c193fba9239ea81fd326536974191be"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-2925b386e727e475",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 143408,
    "exit_code": 0,
    "output_sha256": "1030e02b87b368338006cf933257cd97853eb2ebc7b5ccd77ab8ce128dc53cd0",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:3e40cb8e7b6096273c92632d22664b706906c108c7a2a2893144e37a74e620aa",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Plan 79-15 Merge-Ancestor Replay Refresh — 2026-10-02

The publication simulator showed that a normal two-parent merge makes the proof-only commit a reachable ancestor rather than HEAD. The filtered-history governance check now finds the unique reachable proof-only ancestor, with a merge-descendant regression test. This canonical capture binds the updated governed test bytes; earlier proof blocks and report entries remain unchanged.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-03T00:36:11Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 51489,
      "exit_code": 0,
      "output_sha256": "9c62526978aed26e94979f431c1d27e7af16427d730cfb0fa0f143e325ed7eeb",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 51693,
      "exit_code": 0,
      "output_sha256": "3890b6477f6c86484a7bad9fbb74bc3c3b6db45ec44f63872db1e87a49abd284",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 53262,
      "exit_code": 0,
      "output_sha256": "5f7f44b2c199f56ae55633882f20c18dd05096ed24e1e12387bac07be9c256da",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4619,
      "exit_code": 0,
      "output_sha256": "31012977bc0d7b3c50817f304bc9f98124886dd7f1658fe15fecb82be9eeff9d",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2024,
      "exit_code": 0,
      "output_sha256": "fa07e47b51235a8636301d7e5f3e7a24f6f52320d992bbce33f9dbde36262e5a",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2772,
      "exit_code": 0,
      "output_sha256": "d836246db43907cfc5dc7a6727dfe4c8e2def8a06dcc86776c4c8b97be809ed7",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10404,
      "exit_code": 0,
      "output_sha256": "abf9766d9180690bd2fface122fb94cd0b727416f3e79f7aab05ca56d9245ef7",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10340,
      "exit_code": 0,
      "output_sha256": "acfb166ea345d7bb09c1b47d494be6ca8c190eb5d2c7a19225ff47d4f7e334de",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1167,
      "exit_code": 0,
      "output_sha256": "dbaca83abaa9df525810a3f50fc11e75b2c707d7f1915fe7ebc3c747fe76c3e7",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1013,
      "exit_code": 0,
      "output_sha256": "c2128f839e39b790768cf4563ac58bf151acea8921e36515771cc5ad6613cd6e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1402,
      "exit_code": 0,
      "output_sha256": "40c38d83d660897a0d4070b57b75ec9906af4da54fe3ca62ae0bdf6859998a2b",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1614,
      "exit_code": 0,
      "output_sha256": "3b22054743d880ba68227f6898b6c271740d0733cedecdf6ba98b095b6e35c63",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9824,
      "exit_code": 0,
      "output_sha256": "8a050fa816e85376d951aa050e60174597bad1792bae0f5752a8a4fe596fe8c4",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 9193,
      "exit_code": 0,
      "output_sha256": "a02eb7ed7af03c6c5aef4f80e59468810e10beb022161f3799c11c5864cff454",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1422,
      "exit_code": 0,
      "output_sha256": "69557f12c2621653d7e0a2847d3859a7b5ddcf97509d48985e237479c4d5d271",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1399,
      "exit_code": 0,
      "output_sha256": "2af162cdaaa2491ad489cf726ddef700a7c1be1031bf3b68340ad7895057db25",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5336,
      "exit_code": 0,
      "output_sha256": "6ce2fd750aa1a33cb12eaf9a99bd761a683a217d3e17f1be2ef943fb7544b13c",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 64983,
      "exit_code": 0,
      "output_sha256": "0fbecb6beeb288311a632ae6464cc3f7f04ed160fea95d3bdb957bfdfa0d482a",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 41412,
      "exit_code": 0,
      "output_sha256": "991a3b255672e8ac0ad287c7fff75bc33cd4ef75f83308bfadf1d0130c3461c5",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4732,
      "exit_code": 0,
      "output_sha256": "ee97bb789da2afa732d8566832374bd48c04083a36eed0ea4f8b67914a9f2247",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4477,
      "exit_code": 0,
      "output_sha256": "46da4ea9b99ec12011e24bdcd2948719f2425bb5421fc3045a96df63ac6a5365",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4743,
      "exit_code": 0,
      "output_sha256": "b17d99032e81716b5470d20120ac6f062287d456d42cc8adc7e46d6459d3841e",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4820,
      "exit_code": 0,
      "output_sha256": "0f1fdd313afa4c23f21bfcfb0202d60ce81a8025647e1c57a365da2817d3f3b0",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1101,
      "exit_code": 0,
      "output_sha256": "e7961460559bbbeda1ab6a2de28df97d5d4832db1e0f96b1ac8d46eaf0335164",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "584d26b77b9f4772e5fbe7f7234c672989597aed8126667cb4a7f83ec6ce2c5b"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a43109133cc52384",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 102560,
    "exit_code": 0,
    "output_sha256": "dbebaf7be56419fad6a75ffde62de02e8a100f4d7d7435fe772cfeac26f900b7",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:2d341016940c74e865746e04e3e257c0bd69025bf994451cb1da302b1a132e06",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |


## Plan 79-15 Scope Ownership Replay Refresh — 2026-10-02

Plan 79-15 now preserves the accepted 30/25 scope review separately from the generated publication packet and binds publication ownership to accepted paths and proof-mapped history. This capture includes the committed regression test and plan contract; the filtered candidate replay remains the final source-bound check.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-03T01:27:01Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 33724,
      "exit_code": 0,
      "output_sha256": "06e21a18443e9ca50d32fcb806d55f8020870b82ec76910edb673e8a2048e25b",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 33608,
      "exit_code": 0,
      "output_sha256": "db76d974dcbc6f8934a55789d00ce3f743be11ca449eebf87ee2060ccceb3d43",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 32976,
      "exit_code": 0,
      "output_sha256": "ab881a4059bcf9da0512dbbf66d022e737c783a7faa7a58d72743eeda0d87ad6",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 170
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4028,
      "exit_code": 0,
      "output_sha256": "91e4d577a6f71c879f52ae1c2440e349f8afe4fe8d548dfe8c3081dc285c3961",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2101,
      "exit_code": 0,
      "output_sha256": "75a0b69871329cef0d925394aafb171fdfb15a6ccdb41a514c30d297b784cc85",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3298,
      "exit_code": 0,
      "output_sha256": "68ea45528822e0ed1e2a8a9117e440ea629af952cdd90331fb605c58dea4b81d",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9708,
      "exit_code": 0,
      "output_sha256": "35e2b3460114c0733745f7599e9daabfdef3c441030605ecedee4dd696cc4b58",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8403,
      "exit_code": 0,
      "output_sha256": "b78dfa9dc330ba83c3132929ed68deefc56e16b7d7123e3f7a09c3b89ecfd13b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1277,
      "exit_code": 0,
      "output_sha256": "d9b74614f2fcfe341d73dcd7ac1c23bc3c616c5dd75fed4a94b1f27ad9b228d8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1096,
      "exit_code": 0,
      "output_sha256": "84cc45a3e238d4edbdc66ad8036ee65fa7f03f0e5e1ca7db9589274054839837",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1318,
      "exit_code": 0,
      "output_sha256": "fa22063d6109b6970c7de8a19cd6d2142b721d3367ddbd3e13122f71932ba3e4",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1423,
      "exit_code": 0,
      "output_sha256": "347ddb104fa84ffa16553e2651d678ac8c0e784b90e34dcd9c25d4621d25ab69",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 8220,
      "exit_code": 0,
      "output_sha256": "aa1c51c4387dd35e29f3301288bc8c68ea69ef57b62e1ebb618b54b031f97d64",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6014,
      "exit_code": 0,
      "output_sha256": "61807e848d3d254b0dc633384ce0e115ae2464e1e7cbbb650b98afa42de613a4",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1190,
      "exit_code": 0,
      "output_sha256": "6320e05efc952b673815e48c4f5a917fc0dd06249c4eeb65be6fd68b245b7e8f",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1202,
      "exit_code": 0,
      "output_sha256": "b81ae1f605ce4f1a88f51ae81638cace40a6841e819de272b04c2c6ebc1521b0",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3751,
      "exit_code": 0,
      "output_sha256": "c5bab69b0fd956dbdfbc0d33d55816abfd16617d756de936e990054c6cc36336",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9066,
      "exit_code": 0,
      "output_sha256": "d97c6b622e8354b5fa1f24dbbe1bcc6c9ca3fc1a116a7feb9c6929076dcfd047",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 15693,
      "exit_code": 0,
      "output_sha256": "8294844b8495e9b7d9a4f1fcf595e0b761d7dd5a092cb9ce5a8e4b4b6d121648",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3725,
      "exit_code": 0,
      "output_sha256": "c2a0b479fb6eab205483c30e1f464439d5a4ec3231fa0490e711ff202e34730d",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4153,
      "exit_code": 0,
      "output_sha256": "953d287668122b7564de2fc7ab8b2745e5c091a47dad1bb8c3a562fb164dbf20",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4348,
      "exit_code": 0,
      "output_sha256": "027c98aa4b2a80fb58ddfee6444b15acd7203aa46202c044465555878dce8fed",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4288,
      "exit_code": 0,
      "output_sha256": "f53ddab7994de388d6d7b7f5e3db839c5a10cc48de550ff05d329dcbb0ef97e8",
      "summaries": [
        {
          "excluded": 101,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1204,
      "exit_code": 0,
      "output_sha256": "a901c0eadcade68be92d99d56ff2a44a405c457385875eff96b53c7faac8770e",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "9a88c219817020a8d69f9fbf293a4d63dd37324830c86edcab07683809b5c3b4"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "0584b8635fd3885590ad93009a15004814631f5497cc05de91093714e2c2ea8e"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "5353fec24f7a2ad20e2a93e3716f85c8b546363a666c7120266ba6f3f394ce79"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-af508f243a9aad6d",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 140991,
    "exit_code": 0,
    "output_sha256": "e79568be652c9880113435c7dbb4fbddd0eb1aff4091b58cbc8e461660027257",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
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
        "tests": 9
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
  "source_digest": "sha256:5eca9a545819e69cac87bee50f880289749b981bcd45c1623c54f6675b5416fd",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Phase 79 Governed Source Refresh — 2026-10-14

PR 44 changes three governed sources without weakening any gate: `security-gates.yml` adds the Phase 78 owned-diagnostics validation and RUNNER_TEMP receipt paths, `mix.exs` runs deps.audit, hex.audit, and sobelow as separate `cmd mix` steps with the existing Decimal advisory ignore mirrored for hex.audit plus a temporary, exactly pinned exception for the test-only bandit advisory GHSA-69m6-wcv4-rwcf (no patched release yet), and `milestone_scope_test.exs` moves the gsd-tools-dependent Phase 79 handoff check into its own module so `mix ci.evidence` prints the same ExUnit summary on hosts with and without a local GSD install. This capture replays every focused owner, three equal evidence runs, and the pinned security lane against those sources with gsd-tools unavailable, matching CI.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-14T18:36:39Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 33871,
      "exit_code": 0,
      "output_sha256": "e7bd82b063e266837692d0aaf941263670b843f43cb0f38d52b75accb33df252",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 35648,
      "exit_code": 0,
      "output_sha256": "04ab0c152246baecd78e56960a7619696559ee7a63eeed9b09d557a5bbd6d197",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 33958,
      "exit_code": 0,
      "output_sha256": "1361d9dc79e76ce99d3f655584ec532d2cf9c2eee14d0dfcded51fe89b394474",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 6592,
      "exit_code": 0,
      "output_sha256": "c6554feb91d709617206700a7c7a6663d009b634b67294f8553a4b69ad5faea1",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 6802,
      "exit_code": 0,
      "output_sha256": "46001a4758aef53782a78969565c0297d7c95fe7bafe0f7d09080098e0ec1e7d",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4078,
      "exit_code": 0,
      "output_sha256": "6c08d40358264935c5bdf594d1904ad44c2a3da0026c0efe729d3fe643f798ab",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 15630,
      "exit_code": 0,
      "output_sha256": "0a6828ba76b107f2e8c94162196e9d645c1a3d09cd818b54adabc0828b8b57dc",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 11292,
      "exit_code": 0,
      "output_sha256": "36c3b9c670e187bd009cbb86d205bde0162f03cf7cc640bbd79fa29cb31f7e5b",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1545,
      "exit_code": 0,
      "output_sha256": "07aa67353b5b66a26d184b7dcc9ef12a76c50e85477f572e98196b91b68c1dc8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1221,
      "exit_code": 0,
      "output_sha256": "c3bd0c2860ed12637919248ff9953ff06e291eb38adf968e815ce3dcdd6806ae",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1631,
      "exit_code": 0,
      "output_sha256": "3dea95f83a9723a4c55767127fb55ffd153890212a6709bf68b24d69739d84e8",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1768,
      "exit_code": 0,
      "output_sha256": "87d443d7c33946bb14e16cfad4a3a802a124f79d56d7f3c49bda32a43ad9413e",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 9293,
      "exit_code": 0,
      "output_sha256": "1d11b9eabc83b843eeff05add3208af976567eb66fdc8f6123cd46d4b9e8d213",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 11312,
      "exit_code": 0,
      "output_sha256": "77223d792081889051578329f6728fd8a343853f153c439b7e2ec650a403e808",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 3453,
      "exit_code": 0,
      "output_sha256": "4a001b3070f2dda847069cc09fc8999a8c01d2e649035ddfad3ab3a518526dc9",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2787,
      "exit_code": 0,
      "output_sha256": "2536b361fd8c8a8920e787d111959bbef04c77280a11a7395706359bebeee9a4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 6108,
      "exit_code": 0,
      "output_sha256": "3e02bdb620a081efff63f585c9a952a28a61697f8c893c3247104583fcd65483",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 12626,
      "exit_code": 0,
      "output_sha256": "1cc2a199eec6d6575b28dbcfb16a0f06bf0d5b37a9d5df3e0382537d2c9870a8",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 11474,
      "exit_code": 0,
      "output_sha256": "68a4ad058c4a666f19a290777d7e53581b84fe4a3c0e4eb7968ae55651ed488b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4829,
      "exit_code": 0,
      "output_sha256": "ceafda409269051828e2f3a736c9074afc4dc82653420852c8b7e1c726fc3b63",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4312,
      "exit_code": 0,
      "output_sha256": "eebdcce8641dfc9dc180af4c417d88342a93a0ed906026147421944c6e28d025",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4315,
      "exit_code": 0,
      "output_sha256": "add8e325b7964b5b5bdc21d926032122f8163bdae52a1bfdd914c2f457ac642c",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4687,
      "exit_code": 0,
      "output_sha256": "69ab70c9feb8f38f35cde08dd624444999216232d29ff84612064e28804f0974",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1022,
      "exit_code": 0,
      "output_sha256": "12d5efd5bc1bdee8034241c051272ac46a82ca4cbff7e590e539eb8508b25522",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "4dbba5ad7b0fbcb70a8a8533b20de14a3d4f2682acd5328d07f04c4375349bf8"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "053cc4a7bf42480c4553429ae5c0d5404ccec22ff07488738455a041a9a95816"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "b3b6e2d5190b5146a6231cdbc29832f433ab2412725127d1a94761b6a0c6ef65"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-1d08996aaba4216e",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 118505,
    "exit_code": 0,
    "output_sha256": "2d42cffc42d9562cb2c6e432ff074c9a51c5433458bcaded7dab41a2bd9eca54",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 15
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
        "tests": 15
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
  "source_digest": "sha256:68f787c3814ad52d3a589f5a39d7bac767ec1fede337a865cb0cb77bd1aa9433",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Release Version Pin Refresh — 2026-10-15

Release Please rewrites the `@version` literal in `mix.exs` on every release PR, which changed the pinned `mix.exs` digest and failed this replay on release PR 46. The governed manifest now hashes `mix.exs` with exactly one `@version` literal normalized; every other byte (aliases, deps, audit ignores) stays pinned, and a missing, duplicated, or non-literal `@version` is rejected. `phase_73_reconciliation_test.exs` proves a version-only change keeps the manifest while any other edit changes it. This capture replays every focused owner, three equal evidence runs, and the pinned security lane against those sources with gsd-tools unavailable, matching CI.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-15T15:20:33Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 30016,
      "exit_code": 0,
      "output_sha256": "d28c67b3813fd1cc6bd372483500c684c4bc50af5b20f1f76a8c0bda87f51d7c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 28891,
      "exit_code": 0,
      "output_sha256": "e3bbac31e86d25a6a5e77e516cbb0e9ddb0dde418e0735910cfc2b9b4dfc729a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 29644,
      "exit_code": 0,
      "output_sha256": "f07cb81e8e7ff4f234f14b1d3c1280442e6d880c8b6434403677c546ae53f01d",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4487,
      "exit_code": 0,
      "output_sha256": "70769eabdfbcc58a945ba7e98086b876b97ae019244bb20e2b7ca128f3e9214a",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1974,
      "exit_code": 0,
      "output_sha256": "ffb8e95d4615112d56f9f468e6c7a481d2bf1bdb6912842f9ea5f54286e91a3a",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2816,
      "exit_code": 0,
      "output_sha256": "0debef6e8bae5d09bde7350b0d934545ed2b30391246efefd4c5fb00c3202a23",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 10102,
      "exit_code": 0,
      "output_sha256": "ce8fffd4659c734d609fb6f244f3122c76729e67cbf2287f91ad102692047f1e",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 9795,
      "exit_code": 0,
      "output_sha256": "e51b33c17f6b480a2f32ab5a1213e334825e5e76b787cf8867fb473c01cdf04d",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1265,
      "exit_code": 0,
      "output_sha256": "e5cf943072dba508d52a8b4efdf0463421de79e0bbee21809862b5677e3fcbc6",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1174,
      "exit_code": 0,
      "output_sha256": "006b5f618257ee403eb26f002c7638f334500cfef8b4eacc76395c9d35c57c0c",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1676,
      "exit_code": 0,
      "output_sha256": "26a3204eccf0f09a5b94d3b40f82b2e962cd251be5a66e03141b2c19052b9520",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1496,
      "exit_code": 0,
      "output_sha256": "2fc27662aac9ccd2fe15244468d2db47e6092c9153f239b0530d62dffe701652",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7849,
      "exit_code": 0,
      "output_sha256": "2b57a350e30f22cfe79c0e5e93536a22cf00f77b8786ee126247f488748c85fb",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6084,
      "exit_code": 0,
      "output_sha256": "7b6e0e50c04bcbebd65af6b810c29e3bfb2b5718c1022e4e2b74e5873c22ad4d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1041,
      "exit_code": 0,
      "output_sha256": "5ada22908cef639a2447b0b13bfb9447bbec054d82a259406df3f1d007bf1b3e",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1071,
      "exit_code": 0,
      "output_sha256": "a1758371b7a78f41ced88a3eb0fe4468860709b8a46fcdb77925816030be3924",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4318,
      "exit_code": 0,
      "output_sha256": "63ce287f8dd0a33ca5b70a1415c1041ded548be6c9de218e0262aa27e544bdbd",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9294,
      "exit_code": 0,
      "output_sha256": "ddec4730693e0612cfca8575ecf95c16547d3e7f2bbd80ddc34a00caee238e7e",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 12122,
      "exit_code": 0,
      "output_sha256": "f4f0c59b8232583b2b05a295b20432a1e06e46f3e8c0c9b390d21c10a880e4c2",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4481,
      "exit_code": 0,
      "output_sha256": "d7d2fdd48f13432606ff68c94af733aab29bd90dff93d2d16bd89877f53ff49b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4891,
      "exit_code": 0,
      "output_sha256": "d264eab0a66f568f567d3a11eaf9bc3cfa00ef7728e804e41dc435eecf1910f3",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5281,
      "exit_code": 0,
      "output_sha256": "a9638a82156a6b4ac7903669653ed976fa5e17ad40a3c73a0fb0802fe1844134",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4954,
      "exit_code": 0,
      "output_sha256": "09345ce0c9e658a36698faf522f730d2e272670fa52f4a3ed0b8f4a0e8b21be2",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1426,
      "exit_code": 0,
      "output_sha256": "e6b02f38af61c8fa7acdc322caf954d53a089267ac671322f706d1874b475916",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 2
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "4dbba5ad7b0fbcb70a8a8533b20de14a3d4f2682acd5328d07f04c4375349bf8"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "501fbac728a0716b8b07fc370e9a820045cef77ed3451bc784e587a60696f5c2"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "b3b6e2d5190b5146a6231cdbc29832f433ab2412725127d1a94761b6a0c6ef65"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "747702d7e8cf38124c79990a6a937aa88410c7ae33ca4375d71c8b2b6586ccde"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "a80f532943c070165659727bae9962a1be65cc5d0ade017308558b153d19558e"
    }
  ],
  "proof_set_id": "phase73-c1abea3778ad615e",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 113939,
    "exit_code": 0,
    "output_sha256": "ec2bf3a921d6baa56a648d918e1a6149c2ff450397c1cb6a14f43dd3c3efebec",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 15
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
        "tests": 15
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
  "source_digest": "sha256:1de1e436a8e2d991298a70d505632980a0c962b394f6eb31e4a04b1629c13780",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Security Gates Wall-Clock Refresh — 2026-10-15

`security-gates.yml` drops `needs: security` from the Phase 78 cold-state receipt job. That job already ran under `if: always()`, so the dependency only serialized it behind the security matrix (about 26 minutes) without gating anything; it builds its own cold checkouts. No step, command, condition, or required check changed. This capture replays every focused owner, three equal evidence runs, and the pinned security lane against those sources with gsd-tools unavailable, matching CI.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-15T18:02:09Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 33281,
      "exit_code": 0,
      "output_sha256": "e5f3da9296814eab6bf9392fe2d61536dcddfcfa13bc8c91f05d7680e80cb25c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39060,
      "exit_code": 0,
      "output_sha256": "7276d4ababd3e0b974c164b83a7a3eeb1dc237fb8eddfceb2abd5e5d1cd9dbb9",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 36272,
      "exit_code": 0,
      "output_sha256": "d1c4c4443bef819db866a7b3bf061150c2a24e4324d8f15980b4c36ad11f41bc",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 8838,
      "exit_code": 0,
      "output_sha256": "0e91f299be613439baecfde098aada5611024347309b4e134adea0792f1fd170",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 4107,
      "exit_code": 0,
      "output_sha256": "efd10f3746529c33c83a27b1971fa37597bbde2ba405893b6d27b77b251b8555",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5281,
      "exit_code": 0,
      "output_sha256": "3d0f5fc28b5cc92bb4d30b2b6b1fbf04f3105bb96b12f2f3717dd1d3a9ecef2d",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 11764,
      "exit_code": 0,
      "output_sha256": "3bd72f85810c1dee88754c29ecebb56c7fb98ff7926d88fad5235e606a523883",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 9622,
      "exit_code": 0,
      "output_sha256": "18ac4040866e150f5723710b4b33ed8c3d4c2a5a93153a1f998b3bc767f9e1c2",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1673,
      "exit_code": 0,
      "output_sha256": "20c2f9e623620825fb5b96dd953110d5579a97a774d148b26a9527e9147fa9b3",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1392,
      "exit_code": 0,
      "output_sha256": "4ea5b1744979057cfc347badadac16b350124b70959680df1588fbed7746b5a2",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1968,
      "exit_code": 0,
      "output_sha256": "09d5f133716e2714ebd3a779d1b14c67df9132b0af7a67df41c03c1c218dd76f",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1990,
      "exit_code": 0,
      "output_sha256": "9a4170862d7d766f8d1ea234b2e7cde21276b5865da11f4b8e2c848a0aea5a5a",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 10392,
      "exit_code": 0,
      "output_sha256": "490de9937ac91e591e72e1f5f3b45690fe0d9e2a4b1fe876371a1db73cb9660f",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 8634,
      "exit_code": 0,
      "output_sha256": "41e4c6a88e8db4e462f541367d30ca4f84699ebea8dc78358591a7686110b834",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1646,
      "exit_code": 0,
      "output_sha256": "9269b40ed14a7f8faf73b4a8e1e02cc0d989755526fa300d73f985ab2b9fa4ae",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1675,
      "exit_code": 0,
      "output_sha256": "29b2ebd3e23697c362cb4b739ab8e894b5db7ed58e9ec95a72ec865e5d7c7fb7",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5965,
      "exit_code": 0,
      "output_sha256": "6431ecb65b3be484a7b789932bba56ca119cd0ddc5e26d72765510a43a4ea184",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 11897,
      "exit_code": 0,
      "output_sha256": "a59243afd481b59f98a89276b13799ee621bcc62dcde7d9f5ebf8ccca5082ce1",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 16515,
      "exit_code": 0,
      "output_sha256": "92f76a82434295c4238d106ad3018f7eab312703e50838cc7e379983d66323c7",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4319,
      "exit_code": 0,
      "output_sha256": "1123237c60943fac733ffc5354545b0becc0f7fc6b6ab2c54461664517a18f2d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 5139,
      "exit_code": 0,
      "output_sha256": "ccc639bd7154cb69ea77bb041c4ea62d9dc476f4e569b26ba1c56068716d52a9",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5201,
      "exit_code": 0,
      "output_sha256": "d7fd7e3efb63ea8bc9b932924b792c9de8fad13b2d00749f5b5a0213c7bdb29d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4857,
      "exit_code": 0,
      "output_sha256": "95aec98cf00c90dfa3472d0b078d4aea88797d0512067282d89a2d6fafa9db2e",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1297,
      "exit_code": 0,
      "output_sha256": "3fcc36695a1eabe80fa5149334ef984fff8522c5d4cb08bde9f0ef7676833eb3",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 2
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "2a0d3c70bbb414d8432271276ed2d7d642601785bc99b448f9f2f024f4abf618"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "501fbac728a0716b8b07fc370e9a820045cef77ed3451bc784e587a60696f5c2"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "b3b6e2d5190b5146a6231cdbc29832f433ab2412725127d1a94761b6a0c6ef65"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "747702d7e8cf38124c79990a6a937aa88410c7ae33ca4375d71c8b2b6586ccde"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "a80f532943c070165659727bae9962a1be65cc5d0ade017308558b153d19558e"
    }
  ],
  "proof_set_id": "phase73-2764095eec95eab1",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 137728,
    "exit_code": 0,
    "output_sha256": "3d870d6d4dbe56420dacd66982b0f4a1c5f8e43bdd9cd5f3bf66afd4930686d4",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 15
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
        "tests": 15
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
  "source_digest": "sha256:d3a0ea4c132b6f05af2da1555c3fa4732973b35af75c869132c8455c3eb34229",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |

## Bandit 1.13.0 Refresh — 2026-10-15

bandit 1.13.0 fixes EEF-CVE-2026-105659 and EEF-CVE-2026-105660, so `mix.exs` drops the temporary GHSA-69m6-wcv4-rwcf exception from both the `hex:` ignore list and the deps.audit flag, and `ci_gate_integrity_test.exs` pins the single remaining Decimal exception. bandit stays `only: :test, runtime: false`. This capture replays every focused owner, three equal evidence runs, and the pinned security lane against those sources with gsd-tools unavailable, matching CI.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-10-15T21:34:09Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 31693,
      "exit_code": 0,
      "output_sha256": "8f3a6b31423dca595f514e12412abf9c38b8968bbe1a9c5f3f88811693d1b175",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31976,
      "exit_code": 0,
      "output_sha256": "fb451e7d2282ea3b27cea94957f35bc74c3572d6fcb12b074dd3c19306910da5",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31902,
      "exit_code": 0,
      "output_sha256": "be66eec44afe4d54bbf7ffd8892c0322f51101425509194a6f69fc1058177f68",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 169
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4931,
      "exit_code": 0,
      "output_sha256": "366fc63fdb495d6de9d0d3efe1a9db8e98d1253278a4facec6c6b5956570685b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2067,
      "exit_code": 0,
      "output_sha256": "c70d6d0aa6fa7639728e2fd1eaa9ab52bbc830d8b6bd1fd64ae42a83d5e134ab",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3697,
      "exit_code": 0,
      "output_sha256": "e530b8f136f6279e2884177bf6306c488feb643014dbf8d14cde374c5693c622",
      "summaries": [
        {
          "excluded": 56,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 11053,
      "exit_code": 0,
      "output_sha256": "284dff8991b60c304cf5192e21db0f6a4dfea4924390a08b5ecf223feacb8e44",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 10662,
      "exit_code": 0,
      "output_sha256": "7f0f4dd14ec6d662740195e98926695cc6e07f84fb17fe5f5c34d797cdac8eed",
      "summaries": [
        {
          "excluded": 99,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1064,
      "exit_code": 0,
      "output_sha256": "809412d0ac944e521fa0face11703846ab69a40e3b93d706ab943ffac584b1a7",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 950,
      "exit_code": 0,
      "output_sha256": "f3e0b2b0e8fa056107294ffe3ffdf7b01b22b6b8a4f3e22ba29b7731ca5921a2",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1361,
      "exit_code": 0,
      "output_sha256": "cf7ade714d0882a71e858638e9c2f4ae1895a6e6d11c783373b91d03f23288b9",
      "summaries": [
        {
          "excluded": 58,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1524,
      "exit_code": 0,
      "output_sha256": "e0b66df093e0f4534a69151cfa4cfbadd6ece8a98a8bd437fabb067393e27a2c",
      "summaries": [
        {
          "excluded": 57,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7779,
      "exit_code": 0,
      "output_sha256": "91874545fa4a1f389a38864aa7d342605aeb662be68c358b4c75fe9887b61f39",
      "summaries": [
        {
          "excluded": 98,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6310,
      "exit_code": 0,
      "output_sha256": "53f98951ceee9c1c6e59cb0a9dd23ef82983e59e4ed6b73dd36bf4ed0a45c872",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1007,
      "exit_code": 0,
      "output_sha256": "87cc4ee3b40395722550e5808e45010747ae935c943e724c31764fbc283ef818",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1065,
      "exit_code": 0,
      "output_sha256": "841193740b92b82e5c509fa04a907d047a3e10b4b46933285d70ccb3e5b25538",
      "summaries": [
        {
          "excluded": 6,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 4376,
      "exit_code": 0,
      "output_sha256": "ecf32564b9587a27edf479e3b4fb21e16d24dfbf746b22b782c7c5fc20a45707",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 9444,
      "exit_code": 0,
      "output_sha256": "c43c833e74e1781663159a56d7d2d99fa5b848b4d865ba29acac28a57e041bd6",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 15707,
      "exit_code": 0,
      "output_sha256": "34d6bd3410a067165764cf59999199ab5b8f03b62e4d223e798d65b7b24d69e4",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 5044,
      "exit_code": 0,
      "output_sha256": "70b2d33de3700b281bdd4e962aeaa40fd6bb9263bd0dcbe3216c4a83f638870b",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4203,
      "exit_code": 0,
      "output_sha256": "4da1419db03399ae734e45ab726e80517e12fa56708a66a46ea8f1ff0398496d",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 5196,
      "exit_code": 0,
      "output_sha256": "04a4563b07803d688ec9945ce03bb7c742f82b1c211b9f5f448d2a1483d03a0f",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4308,
      "exit_code": 0,
      "output_sha256": "63848a51155659aa16251f4c3975576148732da0daceb7897e338c484fa87cfa",
      "summaries": [
        {
          "excluded": 100,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1181,
      "exit_code": 0,
      "output_sha256": "738bda10326b6a31366fd8dbf33741cb2ca30135e00e378874cc086e3e2cf1d4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 2
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "2a0d3c70bbb414d8432271276ed2d7d642601785bc99b448f9f2f024f4abf618"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "86f5916bfcfb5e575a7640deab7b02bd020ddeade6a07d7cc66415eec1ff72f5"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "43727a669a8513b683516555d5deee2ec543652b27f5b372bab232aa4b36a794"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "b3b6e2d5190b5146a6231cdbc29832f433ab2412725127d1a94761b6a0c6ef65"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "747702d7e8cf38124c79990a6a937aa88410c7ae33ca4375d71c8b2b6586ccde"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "5e6651cf1e9fe0fb441e03d7a0c4a17a519736a955cb2798b8015c30d45bf549"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "a80f532943c070165659727bae9962a1be65cc5d0ade017308558b153d19558e"
    }
  ],
  "proof_set_id": "phase73-e2cce6c6ad3b9294",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 119828,
    "exit_code": 0,
    "output_sha256": "f2415834a7ee43eb08cd92ab2d18fabd3cd1e2f037961c203959964525d1bcbc",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 15
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
        "tests": 15
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
  "source_digest": "sha256:666bd39445747875b23a1d7a67cbdb3af55e20452141312bdef46a3c73e8594a",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| 73-01-01 | automated |
| 73-01-02 | automated |
| 73-02-01 | automated |
| 73-02-02 | automated |
| 73-03-01 | automated |
| 73-03-02 | automated |
| 73-04-01 | automated |
| 73-04-02 | automated |
| 73-05-01 | automated |
| 73-05-02 | automated |
| 73-05-03 | automated |
| 73-06-01 | automated |
| 73-06-02 | automated |
| 73-07-01 | automated |
| 73-07-02 | automated |
| 73-08-01 | automated |
| 73-08-02 | automated |
| 73-09-01 | automated |
| 73-09-02 | automated |
| 73-10-01 | automated |
| 73-10-02 | automated |
| 73-11-01 | automated |
| 73-11-02 | automated |
| 73-12-01 | automated |
| 73-12-02 | automated |
| 73-13-01 | automated |
| 73-13-02 | automated |
| 73-13-03 | automated |
| 73-14-01 | automated |
| 73-14-02 | automated |
| 73-15-01 | automated |
| 73-15-02 | automated |
| 73-16-01 | automated |
| 73-16-02 | automated |
| 73-17-01 | automated |
| 73-17-02 | automated |
| 73-18-01 | automated |
| 73-18-02 | automated |
| 73-19-01 | automated |
| 73-19-02 | automated |
| 73-20-01 | automated |
| 73-20-02 | automated |
| 73-21-01 | automated |
| 73-21-02 | automated |
| 73-22-01 | automated |
| 73-22-02 | automated |
| 73-23-01 | automated |
| 73-23-02 | automated |
| 73-23-03 | automated |
| 73-24-01 | automated |
| 73-24-02 | automated |
| 73-24-03 | automated |
| 73-25-01 | automated |
| 73-25-02 | automated |
| 73-26-01 | automated |
| 73-26-02 | automated |
| 73-27-01 | automated |
| 73-27-02 | automated |
| 73-28-01 | automated |
| 73-28-02 | automated |
| 73-29-01 | automated |
| 73-29-02 | automated |
| 73-30-01 | automated |
| 73-30-02 | automated |
| 73-31-01 | automated |
| 73-31-02 | automated |
| 73-32-01 | automated |
| 73-32-02 | automated |
| 73-33-01 | automated |
| 73-33-02 | automated |
| 73-34-01 | automated |
| 73-34-02 | automated |
