---
phase: 48-operator-completeness-incident-playbook-trace-tools
plan: 01
subsystem: docs
tags: [incident-playbook, login-trace, mix-relyra-trace, operator-docs]

requires:
  - phase: 42
    provides: ConnectionTraceLive, mix relyra.trace, Query.get_login_traces/4
provides:
  - Six evidence surfaces with login trace row and audit-ledger callout
  - LiveView trace route and mix relyra.trace in operator tables
  - Scenarios 3–6 Diagnose steps wired to pipeline step labels
  - When in doubt split between diagnostic bundle and login trace
affects:
  - 48-02 cross-doc links to playbook trace section

tech-stack:
  added: []
  patterns:
    - "Evidence surfaces centerpiece table extended, not replaced"
    - "Diagnostic bundle vs login trace vocabulary kept distinct in When in doubt"

key-files:
  created: []
  modified:
    - guides/operations/incident_playbook.md

key-decisions:
  - "Added Login trace vs audit ledger subsection under Evidence surfaces (planner discretion)"
  - "Scenarios 1–2 unchanged; trace wiring limited to replay/signature/validate/map failures per plan"

patterns-established:
  - "Eight mix relyra.* hand-tools count synchronized across intro, Evidence surfaces, and Mix tasks header"

requirements-completed: [ADOPT-03]

duration: 12min
completed: 2026-05-27
---

# Phase 48 Plan 01: Incident playbook trace tables & scenarios Summary

**Incident playbook documents login-trace LiveView and `mix relyra.trace` across six evidence surfaces, operator tables, scenarios 3–6, and a diagnostic-vs-trace When in doubt split**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T22:14:00Z
- **Completed:** 2026-05-27T22:26:00Z
- **Tasks:** 4
- **Files modified:** 1

## Accomplishments

- Expanded evidence surfaces from five to six with login trace row, 8 hand-tool count, and login-trace vs audit-ledger callout
- Documented `/relyra/admin/connections/:connection_id/trace`, `mix relyra.trace` flags, CLI examples, and LiveView vs headless when-to-use
- Removed stale Scenario 3 v1.4 denial; wired `replay.check`, `signature.verify`, `response.validate`, and `user.map` into Diagnose steps
- Rewrote When in doubt so `mix relyra.diagnostic` is the handoff bundle and login trace is the per-attempt step timeline

## Task Commits

1. **Task 1: Update intro counts and Evidence surfaces sixth row** — `aa307c8`
2. **Task 2: Extend LiveView routes and Mix tasks tables** — `e14cd87`
3. **Task 3: Wire login trace into Scenarios 3–6 Diagnose steps** — `2402495`
4. **Task 4: Rewrite When in doubt — diagnostic vs login trace** — `76f298b`

**Plan metadata:** `98695cb` (docs: complete plan)

## Files Created/Modified

- `guides/operations/incident_playbook.md` — centerpiece tables, scenarios 3–6, When in doubt

## Decisions Made

- Added optional **Login trace vs audit ledger** subsection (D-16 discretion) to prevent replay/audit confusion
- Left Scenarios 1–2 without trace steps — cert expiry and metadata drift already have dedicated surfaces

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None

## Next Phase Readiness

Ready for **48-02**: cross-links from `guides/overview.md` Day-2 and Getting Started §5 to the updated playbook; `mix ci.docs` verification.

Phase 48 ROADMAP success criterion #2 (cross-doc links) remains for 48-02.

## Self-Check: PASSED

Plan-level verification (2026-05-27):

```bash
grep -E "six evidence|Login trace|connections/:connection_id/trace|mix relyra.trace|8 .mix relyra" guides/operations/incident_playbook.md  # multiple matches
! grep "v1.4" guides/operations/incident_playbook.md  # exit 1 — no stale text
! grep "diagnostic bundle is the trace" guides/operations/incident_playbook.md  # exit 1 — removed
```

Per-task acceptance criteria: all PASS (six evidence surfaces, Login trace row, session.establish, 8 hand-tools, trace route, ConnectionTraceLive, mix relyra.trace, --repo MyApp.Repo, default **20**, replay.check/signature.verify/response.validate/user.map, login trace count ≥ 6, When in doubt split).

---
*Phase: 48-operator-completeness-incident-playbook-trace-tools*
*Completed: 2026-05-27*
