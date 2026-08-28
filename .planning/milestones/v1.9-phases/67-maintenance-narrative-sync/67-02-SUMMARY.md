---
phase: 67-maintenance-narrative-sync
plan: "02"
subsystem: maintenance
tags: [cve, advisory, ci, release, planning]

requires:
  - phase: 67-maintenance-narrative-sync
    provides: "MAINT-02 research and validation contract"
provides:
  - "CVE-2026-49454 advisory backfill for RELYRA-2026-001"
  - "Expected-CVE assertion helper and scheduled workflow semantics"
  - "Planning status reconciled to current CI/release guard evidence"
affects: [maintenance, advisory, ci-release, planning]

tech-stack:
  added: []
  patterns:
    - "Post-assignment advisory checks assert the expected CVE instead of signaling unresolved backfill."
    - "Planning guard notes cite observed release, security, PR-check, and branch-protection evidence without changing automation."

key-files:
  created:
    - .planning/phases/67-maintenance-narrative-sync/67-02-SUMMARY.md
  modified:
    - docs/advisories/2026-001-xmldsig-signature-not-verified.md
    - scripts/check_cve_assignment.sh
    - .github/workflows/cve-advisory-check.yml
    - .planning/STATE.md
    - .planning/PROJECT.md

key-decisions:
  - "GHSA-jv46-xfwm-36j7 is now recorded locally as CVE-2026-49454."
  - "NVD status is recorded only as the live observed Received state, with no invented configurations."
  - "The manual publish-hex workflow remains a recovery path guarded by mix ci.release and mix ci.security; it was not redesigned."

patterns-established:
  - "CVE assignment helpers fail on missing or unexpected CVE IDs and pass only on the expected assigned CVE."
  - "CI/release planning notes preserve dedicated security suites and release-please ownership."

requirements-completed: [MAINT-02]

duration: 10min
completed: 2026-06-19
status: complete
---

# Phase 67 Plan 02: CVE Backfill and CI Guard Status Summary

**CVE-2026-49454 is now the local advisory truth for RELYRA-2026-001, with CI/release guard status reconciled to live evidence.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-19T14:22:31Z
- **Completed:** 2026-06-19T14:32:18Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Backfilled the advisory for `GHSA-jv46-xfwm-36j7` with `CVE-2026-49454`, CVE Services `PUBLISHED`, and NVD `Received` status.
- Converted the local helper and weekly workflow from pending-backfill signaling to expected-CVE assertions.
- Updated planning status text for MAINT-02 without changing release automation, security aliases, branch-protection scripts, crypto, parser, replay, audit, or public APIs.

## Task Commits

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 67-02-01 | Backfill CVE-2026-49454 and close polling semantics | `fe9437f` | `docs/advisories/2026-001-xmldsig-signature-not-verified.md`, `scripts/check_cve_assignment.sh`, `.github/workflows/cve-advisory-check.yml` |
| 67-02-02 | Reconcile CI and release guard planning notes | `4f00b05` | `.planning/STATE.md`, `.planning/PROJECT.md` |

## Files Created/Modified

- `docs/advisories/2026-001-xmldsig-signature-not-verified.md` - Records `CVE-2026-49454`, CVE Services `PUBLISHED`, and NVD `Received` status.
- `scripts/check_cve_assignment.sh` - Asserts `GHSA-jv46-xfwm-36j7` has the expected CVE ID.
- `.github/workflows/cve-advisory-check.yml` - Scheduled/manual workflow now fails only when the observed CVE is missing or not `CVE-2026-49454`.
- `.planning/STATE.md` - MAINT-02 status now records the assigned/backfilled CVE and current guard evidence.
- `.planning/PROJECT.md` - Carry-forward maintenance rows now reflect current CVE, CI, release, PR-check, branch-protection, and manual-publish recovery truth.
- `.planning/phases/67-maintenance-narrative-sync/67-02-SUMMARY.md` - This execution summary.

## Decisions Made

- Treated NVD as current external status only: `Received` with no configurations as of the live 2026-06-19 check.
- Preserved release-please as the normal publish owner and documented `publish-hex.yml` only as a manual recovery workflow.
- Left workflows, Mix aliases, branch-protection scripts, and security tests unchanged except for the scoped CVE assertion workflow.

## Verification

- `curl --max-time 30 --retry 2 --retry-delay 2 -sS -L https://cveawg.mitre.org/api/cve/CVE-2026-49454 | jq -e ...` -> PASS (`true`)
- `curl --max-time 30 --retry 2 --retry-delay 2 -sS -L 'https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-49454' | jq -e ...` -> PASS (`true` after curl retry; NVD intermittently timed out/non-JSON before succeeding)
- `scripts/check_cve_assignment.sh` -> PASS (`GHSA-jv46-xfwm-36j7 has expected CVE ID CVE-2026-49454`)
- Stale pending-wording grep across advisory/helper/workflow -> PASS
- Guard evidence grep across planning/workflow/script files -> PASS
- Stale planning-wording grep across `.planning/STATE.md` and `.planning/PROJECT.md` -> PASS
- Live branch metadata check for protected `main` and required `security (27, 1.19.5)` plus `security (28, 1.19.5)` -> PASS
- `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` -> PASS (4 tests, 0 failures)
- `mix test test/release/release_hardening_test.exs --warnings-as-errors` -> PASS (4 tests, 0 failures)
- `mix format --check-formatted` -> PASS
- `mix qa` -> PASS (765 tests, 0 failures, 10 excluded)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed stale failure exit from the converted CVE workflow**
- **Found during:** Task 67-02-01
- **Issue:** The workflow was converted to assert the expected CVE, but the old signal-backfill `exit 1` remained after the success message.
- **Fix:** Removed the leftover unconditional failure so the workflow passes when `CVE-2026-49454` is observed.
- **Files modified:** `.github/workflows/cve-advisory-check.yml`
- **Verification:** Re-ran helper, stale-wording grep, diff check, and live CVE/NVD verification.
- **Committed in:** `fe9437f`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug).
**Impact on plan:** The fix was required for the planned expected-CVE assertion semantics. No scope expansion.

## Issues Encountered

- NVD intermittently returned timeout/non-JSON responses to the exact jq assertion. A raw HTTP 200 JSON response confirmed `vulnStatus: Received`, and the exact planned command later passed with `true` after curl retry.
- The worktree already contained unrelated `.planning/config.json` formatting and Phase 65 planning artifacts; they were left unstaged and unmodified by this plan.

## Known Stubs

None.

## Threat Flags

None - no new network endpoint, auth path, file-access trust boundary, schema, crypto, parser, replay, audit, or release-publishing surface was introduced beyond the plan's documented advisory-status checks.

## User Setup Required

None.

## Next Phase Readiness

MAINT-02 CVE assignment and CI/release guard status are reconciled. Plan 67-03 can handle Phase 29 warning-level follow-up disposition without reopening the auth-bypass fix or changing security gates.

## Self-Check

PASSED

- `67-02-SUMMARY.md` exists on disk.
- Task commit `fe9437f` exists in git history.
- Task commit `4f00b05` exists in git history.
- Summary frontmatter includes `status: complete` and `requirements-completed: [MAINT-02]`.
- Summary contains the required deviations section.

---
*Phase: 67-maintenance-narrative-sync*
*Completed: 2026-06-19*
