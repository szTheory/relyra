---
phase: 70-keycloak-behind-the-proxy
plan: "12"
subsystem: dependencies
tags: [hex, req, finch, mint, security-audit]
requires:
  - phase: 70-10
    provides: "Keycloak proxy proof and its repository-gate context"
provides:
  - "Solver-generated patched Req, Finch, and Mint lock resolution"
affects: [security-gates, dependency-audit, keycloak-proxy]
tech-stack:
  added: []
  patterns:
    - "Resolve dependency advisories through Hex's solver without editing declared constraints or checksums."
key-files:
  created:
    - .planning/phases/70-keycloak-behind-the-proxy/70-12-SUMMARY.md
  modified:
    - mix.lock
key-decisions:
  - "Kept the remediation to the root lockfile and accepted Hex's compatible Req transport graph."
  - "Did not modify mix.exs or suppress the unrelated pre-existing Decimal advisory."
patterns-established:
  - "Dependency-security remediations remain isolated from scenario acceptance work."
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: "Root Req transport graph resolves to Req 0.7.4, Finch 0.23.0, and Mint 1.9.3."
    requirement: KC-01
    verification:
      - kind: other
        ref: "mix ci.security"
        status: pass
      - kind: other
        ref: "mix deps.audit"
        status: fail
    human_judgment: false
duration: 6min
completed: 2026-08-26
status: complete
---

# Phase 70 Plan 12: Req Transport Dependency Remediation Summary

**Hex-solved Req 0.7.4, Finch 0.23.0, and Mint 1.9.3 lock resolution removes the Req/Mint advisories without changing dependency declarations or SAML code.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-26T22:10:00Z
- **Completed:** 2026-08-26T22:15:37Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Updated only the root solver-generated `mix.lock`: Req `0.5.18 → 0.7.4`, Finch `0.22.0 → 0.23.0`, and Mint `1.8.0 → 1.9.3`.
- Retained the existing `mix.exs` dependency declarations, package whitelist, public APIs, and all `lib/relyra/**` source untouched.
- Passed `mix test --warnings-as-errors` (768 tests), `mix qa`, `mix ci.security`, and `mix format --check-formatted` against the new graph.

## Task Commits

1. **Task 1: Update the advisory-vulnerable Req transport graph and prove repository gates** - `291396b` (`fix`)

## Files Created/Modified

- `mix.lock` - Hex-solved Req/Finch/Mint graph and required HPAX/Plug transitive updates.
- `.planning/phases/70-keycloak-behind-the-proxy/70-12-SUMMARY.md` - execution evidence and residual-audit handoff.

## Decisions Made

- Used `mix deps.update req` as planned and committed the resulting solver output; no checksums or constraints were hand-edited.
- Kept the scope limited to the Req transport graph. The remaining Decimal audit advisory is a pre-existing Ecto-constrained issue and requires a separate, broader dependency decision.

## Deviations from Plan

None - the lockfile update executed exactly as planned.

## Issues Encountered

- `mix deps.audit` without ignore flags now reports only `decimal 2.4.1` / `GHSA-rhv4-8758-jx7v`; Req and Mint are absent from the report. This pre-existing advisory cannot be cleared within the plan's root Req/Finch/Mint-only scope because the locked Ecto dependency requires Decimal `~> 2.0`. No advisory was suppressed or ignored by this plan.
- The first standalone `mix ci.security` run encountered an Ecto test-database pool checkout timeout while concurrent shared-worktree tests were active. The retry completed successfully, including its audit stage (`No vulnerabilities found`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Keycloak proxy work now has a patched Req/Mint transport graph and a green repository security lane. A future dedicated Ecto/Decimal upgrade is needed before direct unsuppressed `mix deps.audit` can exit zero for the entire repository.

## Self-Check: PASSED

- `mix.lock` exists and task commit `291396b` exists in git history.

---
*Phase: 70-keycloak-behind-the-proxy*
*Completed: 2026-08-26*
