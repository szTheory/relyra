---
phase: 36-generic-saml-runbook
plan: 01
subsystem: docs
tags: [docs, saml, generic-saml, runbook]
requires: []
provides:
  - canonical generic/custom-SAML routing from README and Getting Started
  - operator-first generic SAML runbook grounded in real Relyra seams
affects: [docs, onboarding, operators]
tech-stack:
  added: []
  patterns: [operator-runbook routing, seam-grounded field reference]
key-files:
  created: [guides/recipes/generic_saml.md]
  modified: [README.md, guides/getting_started.md]
key-decisions:
  - "Made guides/recipes/generic_saml.md the one authoritative fallback path for non-preset IdPs."
  - "Kept batteries-included support claims limited to shipped presets and treated ADFS as a specialized generic-path exception."
patterns-established:
  - "Generic docs must map vendor/admin vocabulary back to concrete Relyra fields instead of abstract SAML prose."
  - "README and Getting Started act as routers into one canonical operator guide per adoption path."
requirements-completed: [DOCS-02]
duration: 16 min
completed: 2026-05-26
---

# Phase 36: Generic SAML Runbook Summary

**Canonical generic/custom-SAML routing plus a seam-grounded operator runbook for non-preset IdPs**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-26T12:45:00Z
- **Completed:** 2026-05-26T13:00:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Routed README and Getting Started directly to the new generic/custom-SAML runbook.
- Created `guides/recipes/generic_saml.md` with the required core sections for SP metadata, IdP metadata import, NameID decisions, and signing/encryption triggers.
- Kept the support taxonomy explicit: shipped presets remain Okta, Entra, and Google Workspace only; ADFS stays specialized.

## Task Commits

No task commits were created in this run. The worktree already contained unrelated uncommitted Phase 35 and planning changes, including `mix.exs`, so I left commit boundaries to the user rather than risk bundling foreign work into Phase 36.

## Files Created/Modified

- `guides/recipes/generic_saml.md` - Authoritative generic/custom-SAML operator runbook.
- `README.md` - Top-level route into the generic runbook and explicit ADFS special-case link.
- `guides/getting_started.md` - Day-1 fallback route into the generic runbook.

## Decisions Made

- Grounded the field-reference and import sections in `Relyra.Connection`, `Relyra.Protocol.Metadata`, `Relyra.Protocol.AuthnRequest`, `Relyra.start_login/3`, and metadata import/apply seams.
- Added the Phase 36-02 sections early in the same guide file so the document spine stayed coherent across both plans.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository already had unrelated uncommitted work, including files that Phase 36-02 also needs. I avoided task commits to keep from staging unrelated changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `guides/recipes/generic_saml.md` already contains the vendor/safety section spine needed for Plan 02.
- Remaining Phase 36 work is to gate the guide in `mix.exs`, verify `mix ci.docs`, and confirm the full test suite still passes.

---
*Phase: 36-generic-saml-runbook*
*Completed: 2026-05-26*
