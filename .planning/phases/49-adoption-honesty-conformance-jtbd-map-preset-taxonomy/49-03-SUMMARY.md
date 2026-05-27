---
phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy
plan: 03
subsystem: docs
tags: [adoption-truth, preset-taxonomy, generic-saml, adopt-06]

requires:
  - phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy
    provides: CONFORMANCE honesty (49-01) and jtbd_gap_map refresh (49-02)
provides:
  - Keycloak and OneLogin decoder table rows in generic SAML runbook
  - Four-preset batteries-included taxonomy aligned across Getting Started §4 and generic_saml intro
  - Ping/Shibboleth naming cross-references resolving README vs table drift
affects:
  - v1.6 Adoption Truth milestone completion

tech-stack:
  added: []
  patterns:
    - "Add decoder rows to honor README 7-family claim without narrowing first-class preset count"
    - "ADFS promoted from special-case bullet to batteries-included list with dedicated ADFS note"

key-files:
  created: []
  modified:
    - guides/recipes/generic_saml.md
    - guides/getting_started.md

key-decisions:
  - "Shibboleth cross-link after vendor table (not full row) — metadata-exchange-first deployments vary widely"
  - "PingFederate row footgun carries README Ping cross-reference — same IdP class, different admin label"
  - "README unchanged — verify-only; taxonomy alignment via runbook and Getting Started edits only"

patterns-established:
  - "Preset taxonomy alignment: add decoder rows + intro cross-refs, never narrow README 4+7 framing"

requirements-completed: [ADOPT-06]

duration: 6min
completed: 2026-05-27
---

# Phase 49 Plan 03: Preset Taxonomy Alignment Summary

**ADOPT-06 delivered: generic SAML decoder table extended with Keycloak and OneLogin, Getting Started §4 lists four batteries-included presets including ADFS, and Ping/Shibboleth cross-references resolve README vs runbook naming drift without editing README.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-27T22:26:00Z
- **Completed:** 2026-05-27T22:32:01Z
- **Tasks:** 4 completed
- **Files modified:** 2

## Accomplishments

- Added Keycloak and OneLogin decoder rows with seven-family intro sentence matching README
- Appended Ping README cross-reference to PingFederate footgun; Shibboleth findability link after vendor table
- Replaced stale three-preset intro in generic_saml.md; Getting Started §4 batteries-included now lists Okta, Entra, Google Workspace, and ADFS
- README verify-only (4 first-class + 7 families unchanged); `mix ci.docs` green

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Keycloak and OneLogin decoder table rows** - `4c559fa` (docs)
2. **Task 2: Resolve Ping naming and Shibboleth findability** - `678f280` (docs)
3. **Task 3: Align generic_saml intro and Getting Started §4 taxonomy** - `8a056bf` (docs)
4. **Task 4: Verify README alignment and ci.docs** - `0281845` (chore)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified

- `guides/recipes/generic_saml.md` — decoder table rows, intro taxonomy, Ping/Shibboleth cross-refs
- `guides/getting_started.md` — §4 support taxonomy with four batteries-included presets

## Decisions Made

- Shibboleth uses cross-link to existing notes section rather than a decoder row (D-14)
- ADFS demoted from standalone special-case bullet to batteries-included with ADFS note for signed AuthnRequests
- No jtbd_user_flows cross-link added — gap map link already present at line 467

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 49 complete (3/3 plans). v1.6 Adoption Truth milestone ready for milestone audit / ship.

## Self-Check: PASSED

| Criterion | Command | Result |
|-----------|---------|--------|
| Keycloak row | `grep -i "\| Keycloak \|" guides/recipes/generic_saml.md` | PASS |
| OneLogin row | `grep -i "\| OneLogin \|" guides/recipes/generic_saml.md` | PASS |
| Getting Started 4 presets | `grep "Google Workspace, and ADFS" guides/getting_started.md` | PASS |
| README unchanged | `grep "4 first-class presets" README.md` | PASS |
| ci.docs green | `mix ci.docs` | PASS (exit 0) |

---
*Phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy*
*Completed: 2026-05-27*
