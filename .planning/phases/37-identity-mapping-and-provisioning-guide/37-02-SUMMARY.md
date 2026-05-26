---
phase: 37-identity-mapping-and-provisioning-guide
plan: 02
subsystem: docs
tags: [docs, user-mapper, exdoc, ci, identity-mapping]
requires:
  - phase: 37-01
    provides: identity mapping guide skeleton, scope boundary, and host-ownership framing
provides:
  - complete UserMapper seam documentation with host-owned examples
  - production-follow-on routing to the identity mapping guide
  - ExDoc and ci.docs publication/presence gates for the new guide
affects: [docs, onboarding, exdoc, ci]
tech-stack:
  added: []
  patterns: [host-owned seam examples, docs presence gating, production follow-on routing]
key-files:
  created: []
  modified:
    - guides/identity_mapping_and_provisioning.md
    - README.md
    - guides/getting_started.md
    - guides/recipes/generic_saml.md
    - mix.exs
key-decisions:
  - "Grounded every UserMapper example in the real Phoenix ACS callback seam: `%Relyra.LoginResult{principal: %Relyra.Principal{...}}` plus the resolved connection."
  - "Routed the guide only from Day-2 and production follow-on surfaces so identity mapping stays a host-owned post-onboarding decision."
  - "Published the guide in ExDoc extras and added a ci.docs file-presence gate so deletion fails closed."
patterns-established:
  - "Guide examples must read verified identity from `login_result.principal`, not invented top-level login-result fields."
  - "Public docs added under guides/ should be routed from adjacent operator docs and represented in both ExDoc extras and ci.docs."
requirements-completed: [DOCS-03]
duration: 9min
completed: 2026-05-26
---

# Phase 37 Plan 02: Identity Mapping And Provisioning Guide Summary

**Behaviour-backed identity mapping guide with real `UserMapper` examples, production-follow-on routing, and fail-closed docs publication gates**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-26T13:34:00Z
- **Completed:** 2026-05-26T13:43:12Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added the required `UserMapper` behaviour section plus three complete host-owned mapper examples for NameID, attribute-anchor, and JIT create-or-update patterns.
- Routed operators to the guide from README, Getting Started, and the generic SAML runbook without turning it into a Day-1 prerequisite or expanding support claims.
- Wired the guide into ExDoc extras and `ci.docs` so published docs and file presence now fail closed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Document the `UserMapper` behaviour and add three complete host-owned examples** - `bbc6710` (docs)
2. **Task 2: Route adjacent docs to the new guide and gate it in `ci.docs`** - `b725c5f` (docs)

## Files Created/Modified

- `guides/identity_mapping_and_provisioning.md` - Added the callback contract section and complete host-owned mapper modules tied to `%Relyra.LoginResult{principal: %Relyra.Principal{...}}`.
- `README.md` - Added Day-2 routing into the identity mapping guide.
- `guides/getting_started.md` - Added production follow-on routing into the guide after a working provider path.
- `guides/recipes/generic_saml.md` - Added a cross-link from NameID/attribute decisions into the dedicated identity mapping guide.
- `mix.exs` - Added the guide to ExDoc extras and `ci.docs` file-presence checks.

## Decisions Made

- Kept the guide examples host-owned and account-policy-focused instead of implying that Relyra ships local account storage, provisioning orchestration, or SCIM lifecycle control.
- Used the real Phoenix ACS seam as the documentation source of truth even though some fallback mapper code still accepts map-shaped inputs.
- Routed the guide only from adjacent operator surfaces that naturally precede identity decisions after first-login success.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository was already dirty on entry. To keep Task 2 atomic, only the 37-02 hunks were staged in tracked files, while the required `guides/recipes/generic_saml.md` cross-link landed via the full file because that guide was still untracked in the main working tree.
- A first verification attempt launched `mix ci.docs` and `mix test --warnings-as-errors` in parallel and hit the known test-database bootstrap collision. Re-running them sequentially succeeded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DOCS-03` is now closed end-to-end: the guide is complete, discoverable from adjacent docs, published in ExDoc, and presence-gated in `ci.docs`.
- The remaining worktree dirt is outside this plan and was left untouched.

## Self-Check: PASSED
