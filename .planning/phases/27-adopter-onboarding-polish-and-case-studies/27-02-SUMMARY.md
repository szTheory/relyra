---
phase: 27-adopter-onboarding-polish-and-case-studies
plan: 02
subsystem: docs
tags: [docs, provider-runbooks, case-studies, onboarding]
requires:
  - phase: 27-adopter-onboarding-polish-and-case-studies
    provides: canonical Day-1 onboarding spine and exact provider support taxonomy
provides:
  - authoritative Okta, Microsoft Entra ID, and Google Workspace runbooks
  - repo-native adopter case studies with explicit ownership boundaries
  - provider-to-case-study linkage aligned with the supported-provider contract
affects: [guides, provider-runbooks, case-studies, onboarding]
tech-stack:
  added: []
  patterns: [authoritative-runbook, ownership-boundary-docs, repo-native-case-study]
key-files:
  created:
    - guides/case_studies/phoenix_saas_tenant_onboarding.md
    - guides/case_studies/operator_managed_rollout.md
  modified:
    - guides/recipes/okta.md
    - guides/recipes/entra.md
    - guides/recipes/google_workspace.md
key-decisions:
  - "Provider runbooks use exact vendor vocabulary derived from preset labels and footgun posture."
  - "Case studies stay repo-native and operational instead of becoming marketing collateral."
  - "Only Okta, Microsoft Entra ID, and Google Workspace are treated as first-class provider paths."
patterns-established:
  - "Runbooks explicitly separate Relyra-owned, IdP-owned, and host-owned seams."
  - "Case studies encode scenario, wiring, failure/recovery, and evidence in a small high-signal format."
requirements-completed: [DOCS-01]
duration: 29min
completed: 2026-05-08
---

# Phase 27 Plan 02: Provider Runbooks And Case Studies Summary

**Authoritative provider runbooks and two repo-native case studies that extend the new Day-1 onboarding spine without broadening support claims.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-05-08T14:42:00Z
- **Completed:** 2026-05-08T15:11:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Rewrote the Okta, Microsoft Entra ID, and Google Workspace guides into operator-facing runbooks with exact field vocabulary, ownership boundaries, proof receipts, common failures, and day-2 notes.
- Added two small repo-native case studies covering Phoenix SaaS tenant onboarding and operator-managed production rollout.
- Linked the provider runbooks back to the new case-study set while keeping first-class support limited to the three shipped presets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade the three provider recipes into operator runbooks** - `61f882f` (docs)
2. **Task 2: Add the small repo-native case-study set** - `32328b2` (docs)

## Files Created/Modified

- `guides/recipes/okta.md` - Okta runbook with exact Okta field names, boundaries, proof, failures, and day-2 notes.
- `guides/recipes/entra.md` - Microsoft Entra ID runbook with persistent NameID guidance and explicit operator receipts.
- `guides/recipes/google_workspace.md` - Google Workspace runbook with email-style NameID posture and follow-on guidance.
- `guides/case_studies/phoenix_saas_tenant_onboarding.md` - Phoenix SaaS tenant onboarding scenario from scaffold to one supported provider.
- `guides/case_studies/operator_managed_rollout.md` - Day-2 operator rollout scenario for metadata, certificate, diagnostics, and auditability.

## Decisions Made

- The runbooks speak the exact vendor vocabulary encoded by the shipped presets instead of generic SAML-only language.
- Ownership is explicit in every runbook and case study so adopters can distinguish library seams from host-app responsibilities.
- The case-study catalog stays intentionally small: one Day-1 onboarding scenario and one operator/day-2 rollout scenario.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The acceptance gate required literal `guides/case_studies/` path text in the provider docs, so the related-case-study section includes both working links and repo-root path references.

## User Setup Required

None - these are documentation-only updates.

## Next Phase Readiness

- The provider branch now has authoritative runbooks and scenario docs to support the final batteries-included proof lane.
- Wave 3 can map proof claims directly to the new runbooks, `mix relyra.install`, `FakeIdP`, and the day-2 operational seams already described here.

## Self-Check: PASSED

- Found task commit `61f882f`
- Found task commit `32328b2`
- Found case-study files under `guides/case_studies/`

---
*Phase: 27-adopter-onboarding-polish-and-case-studies*
*Completed: 2026-05-08*
