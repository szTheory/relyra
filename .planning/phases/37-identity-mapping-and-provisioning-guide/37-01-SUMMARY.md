---
phase: 37-identity-mapping-and-provisioning-guide
plan: 01
subsystem: docs
tags: [docs, saml, identity-mapping, jit, scim]
requires: []
provides:
  - authoritative identity mapping and provisioning guide
  - ExDoc-visible UserMapper seam documentation aligned to runtime
affects: [phase-37, docs, exdoc, onboarding]
tech-stack:
  added: []
  patterns: [operator-first guide writing, honest seam documentation]
key-files:
  created: [guides/identity_mapping_and_provisioning.md]
  modified: [guides/identity_mapping_and_provisioning.md, lib/relyra/user_mapper.ex]
key-decisions:
  - "Document identity mapping as a host-owned policy layered on top of verified login data, not as library-owned provisioning."
  - "Make anchor stability, JIT ownership, and SCIM non-goal warnings explicit in the guide before example code lands."
patterns-established:
  - "Separate verified identity facts from local account lifecycle decisions."
  - "Treat NameID and attribute anchor changes as migration events, not harmless IdP cleanup."
requirements-completed: [DOCS-03]
duration: 4min
completed: 2026-05-26
---

# Phase 37 Plan 01: Identity Mapping And Provisioning Guide Summary

**Operator-first identity mapping guide with anchor selection, JIT decision framing, and honest `UserMapper` seam documentation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-26T13:33:25Z
- **Completed:** 2026-05-26T13:37:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added the authoritative identity mapping guide covering NameID-as-local-id, attribute-as-local-id, and JIT create-or-update.
- Made anchor stability, transient/email risks, JIT decision framing, and SCIM simultaneous-writer hazards explicit for operators.
- Tightened `Relyra.UserMapper` ExDoc so the public docs match the real ACS seam and verified `%Relyra.LoginResult{}` payload.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the core guide with ownership boundaries and the three mapping patterns** - `0aa9ee1` (docs)
2. **Task 2: Add anchor-stability guidance and the JIT-plus-SCIM safety warning** - `f86833d` (docs)

## Files Created/Modified

- `guides/identity_mapping_and_provisioning.md` - New authoritative guide for anchor choice, lifecycle ownership boundaries, JIT decisions, and SCIM non-goal posture.
- `lib/relyra/user_mapper.ex` - Updated moduledoc to describe the verified login-result seam and later session handoff truthfully.

## Decisions Made

- Kept the guide operator-first and host-app-aware, matching the tone of the existing runbooks instead of turning it into API reference prose.
- Described the public mapper seam using the current ACS runtime path without changing callback types, arity, or behavior.
- Centered the guide on one narrow truth: verified SAML identity stops at host-owned lookup/link/create/update policy.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 37 now has the core guide and seam wording needed for publication/routing work in Plan 37-02.
The remaining gap is docs publication and cross-link routing, not runtime behavior.

## Self-Check: PASSED
