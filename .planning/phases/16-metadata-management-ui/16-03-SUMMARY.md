---
phase: 16-metadata-management-ui
plan: 03
subsystem: live_admin
tags:
  - live_view
  - async
  - metadata
requires:
  - 16-02
provides:
  - async manual metadata refresh
affects:
  - metadata management view
tech_stack_added: []
tech_stack_patterns:
  - LiveView start_async
key_files_created: []
key_files_modified:
  - lib/relyra/live_admin/connection_metadata_live.ex
  - test/phoenix/live_admin_metadata_test.exs
key_decisions:
  - "Decided to use Phoenix LiveView `start_async` instead of a background job queue for manual metadata refreshing to keep the UI responsive and straightforward."
duration: "5m"
completed_date: "2024-10-31"
---

# Phase 16 Plan 03: Async Manual Refresh Summary

Implemented manual metadata refresh using Phoenix LiveView's `start_async` capability. This prevents the UI from freezing while polling remote metadata URLs. Operators are now presented with a loading indicator and receive a flash message outcome once the async process completes, along with a warning that retrieved trust material requires manual rollover on the main connection view.

## Self-Check: PASSED
- `lib/relyra/live_admin/connection_metadata_live.ex` modified.
- `test/phoenix/live_admin_metadata_test.exs` updated and passes.
- Commits exist.
