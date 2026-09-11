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
| **Mandatory owner** | `mix ci.evidence` runs both Phase 73 contract modules in one fresh process with `--only evidence_contract --warnings-as-errors`; the current staged proof is three independent 103-test passes in 20s, 20s, and 21s |
| **Required workflow** | `.github/workflows/security-gates.yml`, `jobs.security` → `Evidence contract` → `mix ci.evidence` |
| **Focused ownership** | Plan/task tags through `plan_73_23_task_1`, including current non-zero selectors `plan_73_21_task_1`, `plan_73_21_task_2`, `plan_73_22_task_1`, and `plan_73_22_task_2`, plus `cwd_isolation` for the post-merge race regression |
| **Environment** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` prefixes Mix verification commands |
| **Workflow syntax** | `actionlint .github/workflows/security-gates.yml` |
| **Repository closeout context** | Exact full-suite seed `778220`: 864 tests; the sole failure is the explicitly deferred Phase 77 documentation-vocabulary assertion and is not a Phase 73 Nyquist gap |
| **Current coverage** | 23 plans and 49 acceptance-bearing tasks are mapped and green in the final reconciled proof set |

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
