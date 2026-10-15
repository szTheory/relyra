---
phase: 79-adopter-ready-closeout
fixed_at: 2026-09-30T09:37:36Z
review_path: .planning/phases/79-adopter-ready-closeout/79-REVIEW.md
iteration: 4
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
followup_findings: 5
followup_fixed: 5
final_review_status: clean
final_fix_commit: 36c71c6
---

# Phase 79: Code Review Fix Report

**Fixed at:** 2026-09-30T05:41:29Z  
**Source review:** `.planning/phases/79-adopter-ready-closeout/79-REVIEW.md`  
**Iteration:** 3

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Shared check-suite identity does not prove the check came from its owner workflow

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `e63bab5`  
**Applied fix:** The collector now reads jobs from each selected owner run through `actions/runs/{run_id}/jobs?filter=latest`, extracts each check-run ID from `check_run_url`, and binds evidence to the exact workflow run and job. Suite ID alone is no longer an ownership link. Added a fixture where a foreign workflow emits the same check name under the owner's shared suite while the owner job itself fails.  
**Verification:** Focused governance tests passed (2 tests, 0 failures); the shared-suite collision remains failed.

### CR-02: Receipt verification accepts failed checks as passing evidence

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `e63bab5`  
**Applied fix:** `--verify` now checks each referenced job/check/run link, requires referenced checks to be completed with a passing conclusion for any claimed pass, and requires the evidence count and rows to match the required job names. Added a mutation fixture that changes a referenced passing check to failure and asserts verification rejects the receipt.  
**Verification:** The focused verifier mutation case passed.

### CR-03: Any successful historical suite can override a later failed run

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `e63bab5`  
**Applied fix:** The collector selects the latest owner run for the observed SHA using `run_started_at` and `run_attempt`, fetches jobs for that latest attempt, and treats missing or tied selection data as unknown. Added an earlier-pass/later-failed run fixture and asserted the lane stays failed.  
**Verification:** The focused latest-run fixture passed; the later failure overrides the earlier successful run.

## Verification Environment

Focused checks ran in the main checkout with `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.4.1`. Python AST parsing, `git diff --check`, and the GSD commit's `mix format --check-formatted` hook passed. No full evidence lanes were run. The three findings share one atomic commit because the owner-job relation is used by collection, classification, and receipt verification together.

## Final Re-review Follow-up

The final re-review at `2026-09-30T06:19:07Z` found two blockers and one warning in the live GitHub API edge cases. All three were fixed in `dff2f76`.

### CR-01: Workflow path suffix prevents selecting real owner runs

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `dff2f76`  
**Applied fix:** Added one workflow-path normalizer that strips a documented `@ref` suffix for owner matching and receipt validation while preserving the original path in evidence. The positive collector fixture uses `@refs/heads/main` paths and still produces passing lane/context evidence.

### CR-02: Credential-bearing GitHub URLs pass the remote-field filter

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `dff2f76`  
**Applied fix:** `safe_github_url` now omits URLs with userinfo, query strings, fragments, invalid hosts/ports, or an unapproved scheme/host. Fixtures prove external status targets cannot persist userinfo or query credentials in the receipt.

### WR-01: Malformed GitHub origin URLs can escape as an uncaught traceback

**Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`  
**Commit:** `dff2f76`  
**Applied fix:** URL parsing and port errors now become the collector's controlled `CollectionError`. Malformed-port and malformed-host origin fixtures confirm the CLI exits without publishing a receipt.

**Verification:** The two focused Phase 79 collector tests passed (2 tests, 0 failures; 85 excluded). Python AST parsing, `git diff --check`, and the pinned `mix format --check-formatted` commit hook passed. The independent final re-review recorded `status: clean` for both scoped files.

---

_Fixed: 2026-09-30T05:41:29Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 3_  
_Final follow-up: `dff2f76`; independent re-review clean_

## Post-review inventory ownership contract correction

The final Phase 79 evidence replay exposed an ownership-classification gap after the clean review above: the collector labeled all modified tracked files `unknown`, while the closeout contract requires the six explicitly scoped Phase 79 outputs to be identified as phase-owned.

- **Commit:** `ec38d1b`
- **Applied fix:** Added an exact six-path allowlist for Phase 79 outputs. Other paths remain `unknown`, and `.tool-versions` remains `maintainer`-owned. Extended the fixture to assert both classifications.
- **Verification:** Focused collector fixture passed (1 test, 0 failures); the Phase 73 proof was recaptured and replayed; `mix test --warnings-as-errors` passed (999 tests, 0 failures, 11 excluded).
- **Scope:** This is a deterministic contract correction discovered during final execution, separate from the three review findings above.

## Final re-review follow-up

The final review at `2026-09-30T09:33:46Z` found two warnings in the Phase 79 ownership classifier. Both were fixed and independently re-reviewed clean at `2026-09-30T09:37:36Z`.

### WR-01: Phase 79 disposition becomes stale after Task 3

- **Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`
- **Applied fix:** Replaced the task-stage-specific disposition with `preserve; no cleanup authority` for the exact Phase 79 path allowlist.
- **Verification:** The focused fixture passed; the Phase 79 inventory fixture now asserts the state-neutral disposition.

### WR-02: Fixture only exercises one of the six allowlisted paths

- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Applied fix:** Added all six allowlisted paths to the fixture's porcelain and tracked-path inputs, asserted every path is classified as `phase-79`, retained the `.tool-versions` maintainer check, and added a dirty `README.md` unknown-owner check.
- **Verification:** The focused fixture passed; the independent final review confirmed all six paths and both ownership controls.
