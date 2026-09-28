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
  "captured_at": "2026-09-28T17:47:53Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 50740,
      "exit_code": 0,
      "output_sha256": "25736bb1a7d9d7f02a9394b521691e5112e7f2ce06bdf20cb2993b1b58770a0f",
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
      "duration_ms": 50520,
      "exit_code": 0,
      "output_sha256": "777e3506b81c9f08da6e85fe2b9d008c1bbcef2812de2955faa7ad46236e80e3",
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
      "duration_ms": 44890,
      "exit_code": 0,
      "output_sha256": "34d57ebd129887802998f33beb8662c40d42305fbcff5cd2d6c871874504dbda",
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
      "duration_ms": 7045,
      "exit_code": 0,
      "output_sha256": "110677b7a32109c8bff99c88ca71004af667f143717f5382e0664f2f2234a9b1",
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
      "duration_ms": 4468,
      "exit_code": 0,
      "output_sha256": "aac26d5d0c5e6825577d16c2081db4e9cbb5011baf56bbe7560d1aa6e889b27b",
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
      "duration_ms": 7848,
      "exit_code": 0,
      "output_sha256": "619e4e21e1370f542e6f6c3b8b790b5df406560916f25a51bcf4a1241778f177",
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
      "duration_ms": 23051,
      "exit_code": 0,
      "output_sha256": "1b33b5a09825701089d7f9e493ea7c69ba6c3e89e3ff4bc3011220e2840ddcd6",
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
      "duration_ms": 16287,
      "exit_code": 0,
      "output_sha256": "9ac6b2186a57ee6e39a7bf75f2b53bd9dff058821980c7327456d2e1a2e7a246",
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
      "duration_ms": 2824,
      "exit_code": 0,
      "output_sha256": "29aa5219295682f0cf1fa786b0d68c38b2b6d39de5daaa0079ddc581e2b9f701",
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
      "duration_ms": 2458,
      "exit_code": 0,
      "output_sha256": "9c65afe225df88dd41541ed9c2ee71eab0ed6e15a7d3e557e9008cefa00aa997",
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
      "duration_ms": 3522,
      "exit_code": 0,
      "output_sha256": "e34863419493da333d535b1e32e6b570723ba6657193ac0099b161395565bc01",
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
      "duration_ms": 3570,
      "exit_code": 0,
      "output_sha256": "37d156f8f607216edebc2d1da89cff683e08fcbbbc569ffa304f3f7acc44fec8",
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
      "duration_ms": 11767,
      "exit_code": 0,
      "output_sha256": "12bfe59883ef41f1d970484f6b2e3b6690aad2c9f521a09b0d8b373687d39409",
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
      "duration_ms": 12948,
      "exit_code": 0,
      "output_sha256": "b4339ffb4edbae18fa4675e6ad844dc55a989c9c59a94dec3d3adf81c59f3b28",
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
      "duration_ms": 2822,
      "exit_code": 0,
      "output_sha256": "66b320ccce46291000cdd1488f14ae9699cf3e1ad95ca6f43b3699f1b6c527f6",
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
      "duration_ms": 2454,
      "exit_code": 0,
      "output_sha256": "5d880b1a3a56330db0b20a152cfc149168bb413079147faccce96e3cf43fd8d4",
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
      "duration_ms": 7451,
      "exit_code": 0,
      "output_sha256": "99bf1ad709d49652f79ac86509b2e8631008fea10c82c82b10db831ef7bb8982",
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
      "duration_ms": 16281,
      "exit_code": 0,
      "output_sha256": "677d1499e381edd0a5337576ddc795ffbd6a70df620293b8e064db6333e2474a",
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
      "duration_ms": 15065,
      "exit_code": 0,
      "output_sha256": "4d3b444bb358a5f6fd08c85d32c835510eec994b13ccec9263abc6c4b8bb4794",
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
      "duration_ms": 6401,
      "exit_code": 0,
      "output_sha256": "ae709661b042fb7ceda816f113980e9b6a710de2c3386215a781f291be578746",
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
      "duration_ms": 6143,
      "exit_code": 0,
      "output_sha256": "4e819cf6a20ea229fbb7e305d6167ea305e838fca7826782f0d08f27968bf3c3",
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
      "duration_ms": 6872,
      "exit_code": 0,
      "output_sha256": "1454ea77e84f82fc0bf1ebf427d0b699becb65c5a36a93cab311a252ec7951b7",
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
      "duration_ms": 8014,
      "exit_code": 0,
      "output_sha256": "bcc9b6748dc2ae627e4b162384e3782a17ac700585ea5ea5fe6bf9ae793ab92d",
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
      "duration_ms": 2059,
      "exit_code": 0,
      "output_sha256": "a69eef30a3939815113cf267819284f7feaa16321540563b3b720da0eec006e3",
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
    "duration_ms": 79562,
    "exit_code": 0,
    "output_sha256": "710da5fec7669c597e7bf0a477126388ea1299ac524f98ce95bc152208ce90dd",
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
