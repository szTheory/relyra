---
phase: 27-adopter-onboarding-polish-and-case-studies
plan: 01
subsystem: docs
tags: [docs, onboarding, readme, getting-started, saml]
requires:
  - phase: 26-security-audit-preparation-and-remediation
    provides: exact-claims documentation posture and reviewer-grade support language
provides:
  - canonical README router for the Day-1 onboarding path
  - ordered Getting Started spine with receipts and one provider branch
  - support-positioning language limited to Okta, Microsoft Entra ID, and Google Workspace
affects: [README, guides, adopter-onboarding, provider-runbooks]
tech-stack:
  added: []
  patterns: [canonical-doc-router, receipt-based-onboarding, exact-support-taxonomy]
key-files:
  created: []
  modified: [README.md, guides/getting_started.md]
key-decisions:
  - "README is a router into Getting Started, not a competing onboarding guide."
  - "First-class batteries-included support is limited to Okta, Microsoft Entra ID, and Google Workspace."
  - "Each Day-1 stage ends with a literal receipt before the next stage begins."
patterns-established:
  - "Canonical Day-1 path: README -> Getting Started -> FakeIdP proof -> one provider runbook -> production follow-ons"
  - "Optional admin and day-2 operations are positioned after first-provider success"
requirements-completed: [DOCS-01]
duration: 12min
completed: 2026-05-08
---

# Phase 27 Plan 01: Canonical Day-1 Onboarding Summary

**Canonical README routing plus a receipt-driven Getting Started spine for Okta, Microsoft Entra ID, and Google Workspace.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-08T14:29:33Z
- **Completed:** 2026-05-08T14:41:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Reworked `README.md` into a narrow Day-1 router instead of a second onboarding guide.
- Rewrote `guides/getting_started.md` into one ordered onboarding narrative with five explicit receipts.
- Tightened public support claims so first-class batteries-included language only covers Okta, Microsoft Entra ID, and Google Workspace.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rework README into the canonical router** - `f748c0b` (docs)
2. **Task 2: Expand Getting Started into the ordered Day-1 spine** - `72230f7` (docs)

## Files Created/Modified
- `README.md` - Canonical routing entry point, support taxonomy, and Day-2 pointer surface.
- `guides/getting_started.md` - Ordered Day-1 guide with install, scaffold, FakeIdP proof, provider branch, and production follow-ons.

## Decisions Made
- README now defers detailed onboarding to `guides/getting_started.md` so adopters see one obvious starting path.
- Support-positioning language is explicit: first-class batteries-included support is limited to Okta, Microsoft Entra ID, and Google Workspace; everything else is custom SAML or not yet shipped.
- LiveAdmin and other operational seams are framed as optional later-stage surfaces, not mandatory Day-1 work.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 2's acceptance gate required the repo-root `guides/recipes/...` paths to appear literally. The provider branch bullets were adjusted to keep working links while also exposing the repo-root paths the verifier expected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Day-1 information architecture is now stable enough for provider runbook expansion and case-study work in Plan 27-02.
- The support taxonomy is explicit, so later plans can build proof and case studies without broadening provider claims.

## Self-Check: PASSED

- Found summary file: `.planning/phases/27-adopter-onboarding-polish-and-case-studies/27-01-SUMMARY.md`
- Found task commit `f748c0b`
- Found task commit `72230f7`

---
*Phase: 27-adopter-onboarding-polish-and-case-studies*
*Completed: 2026-05-08*
