---
phase: 17-certificate-inventory-staged-rollover-ui
plan: 01
subsystem: live_admin
tags:
  - ui
  - components
  - optimistic_locking
  - certificates
dependency_graph:
  requires:
    - 16-03 (Metadata management UI)
  provides:
    - Semantic slot-based timeline for certificates
    - Conflict-safe trust state mutations
  affects:
    - admin_ui
    - certificate_inventory
tech_stack:
  added: []
  patterns:
    - Optimistic Locking rescue
    - Semantic UI slots
key_files:
  modified:
    - lib/relyra/live_admin/components/connection_detail.ex
    - lib/relyra/live_admin/connections_live.ex
key_decisions:
  - Use visual indicators (Warning amber color, clock icon) for certificates expiring in less than 30 days.
  - Implement Ecto.StaleEntryError rescue in LiveView handlers to catch race conditions gracefully without crashing the process.
---

# Phase 17 Plan 01: Implement Semantic Slot-Based Timeline UI Summary

Implemented a semantic slot-based timeline UI for certificates and handled optimistic locking conflicts gracefully.

## Completed Tasks

1.  **Implement Semantic Slot-Based Timeline UI:** Replaced the generic certificate list with fixed-layout semantic slots for Next (Staged), Active, and Retired states. Added tabular numerals for fingerprints and dates. Implemented `expires_soon?/1` helper to apply "Warning" amber color (`#B45309`) and a clock icon to certificates expiring in less than 30 days. Ensured a dashed placeholder for the Next slot if empty and explicitly preserved the `rollback_certificate` functionality.
2.  **Handle Optimistic Locking Conflicts:** Updated event handlers (`activate_certificate`, `retire_certificate`, and `rollback_certificate` - per Rule 2 to ensure complete protection) to rescue `Ecto.StaleEntryError`. When an optimistic locking conflict occurs, the UI flashes a clear error message, preventing LiveView crashes, and immediately reloads the true state to allow operators to review the changes.

## Deviations from Plan

### Auto-added Missing Critical Functionality
**1. [Rule 2 - Security/Resilience] Applied StaleEntryError rescue to rollback_certificate**
- **Found during:** Task 2 implementation
- **Issue:** The instructions specifically listed `activate_certificate` and `retire_certificate`, but `rollback_certificate` also mutates certificate states and operates under the same optimistic locking constraints. Leaving it unhandled could still result in ungraceful crashes on conflict.
- **Fix:** Added the `Ecto.StaleEntryError` rescue block to the `rollback_certificate` event handler alongside the other two handlers.
- **Files modified:** `lib/relyra/live_admin/connections_live.ex`
- **Commit:** `8400944`

## Self-Check
- [x] All tasks executed and committed individually
- [x] Semantic slot-based timeline UI displays Active, Next, and Retired properly
- [x] Missing Next slot prompts replacement placeholder
- [x] OptimisticLocking conflicts handled via StaleEntryError rescue without crashing LiveView process

## Threat Flags
None. All mutations are protected against race conditions via StaleEntryError handling per the threat model.