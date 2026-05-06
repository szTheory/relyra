---
phase: 15
plan: 03
subsystem: relyra_admin
tags: ["live_view", "lifecycle", "risk_panel"]
dependency_graph:
  requires: ["15-02"]
  provides: ["Event handlers for enable and disable", "Status badges", "Readiness blockers display", "RiskPanel on edit views"]
  affects: ["Relyra.LiveAdmin.ConnectionsLive", "Relyra.LiveAdmin.Components.ConnectionDetail", "Relyra.LiveAdmin.Components.ConnectionForm"]
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - lib/relyra/live_admin/connections_live.ex
    - lib/relyra/live_admin/components/connection_detail.ex
    - lib/relyra/live_admin/components/connection_form.ex
    - lib/relyra/ecto/connection.ex
key_decisions:
  - Added a virtual field `:readiness_errors` to `Relyra.Ecto.Connection` to temporarily hold enable validation errors so they can be easily displayed on the LiveView detail view.
metrics:
  duration_minutes: 10
  completed_date: "2026-05-06"
---

# Phase 15 Plan 03: Wire up lifecycle transitions and risk panel Summary

**Wire up the `Enable` and `Disable` lifecycle transitions to the Ecto command boundary, surfacing readiness blockers when enabling fails, adding explicit status badges, and ensuring the risk panel is visible across both detail and edit views.**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Functionality] Added virtual field for readiness errors**
- **Found during:** Task 1
- **Issue:** Ecto schemas do not allow arbitrary keys to be merged into struct fields. The readiness errors coming from changeset validation on the `Enable` lifecycle action needed to be carried over to the connection struct so they could be displayed in the template.
- **Fix:** Added `field :readiness_errors, :map, virtual: true, default: %{}` to `Relyra.Ecto.Connection`.
- **Files modified:** `lib/relyra/ecto/connection.ex`
- **Commit:** 0a16b0a

## Known Stubs

None. All rendering paths map correctly to their underlying state logic.

## Threat Flags

None found.
