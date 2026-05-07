---
phase: 23-diagnostic-bundles
plan: 02
subsystem: Admin & CLI
tags:
  - diagnostic
  - cli
  - live_admin
requires:
  - 23-01
provides:
  - CLI command `mix relyra.diagnostic`
  - Admin UI endpoint `/diagnostic/bundle`
affects:
  - lib/mix/tasks/relyra.diagnostic.ex
  - lib/relyra/phoenix/controllers/diagnostic_controller.ex
  - lib/relyra/live_admin/router.ex
  - lib/relyra/live_admin/connections_live.ex
tech-stack:
  - Phoenix.Controller
  - Mix.Task
  - Phoenix.LiveView
key-files:
  - created: lib/mix/tasks/relyra.diagnostic.ex
  - created: lib/relyra/phoenix/controllers/diagnostic_controller.ex
  - created: test/phoenix/diagnostic_controller_test.exs
  - modified: lib/relyra/live_admin/router.ex
  - modified: lib/relyra/live_admin/connections_live.ex
metrics:
  duration: 10
  completed_date: 2026-05-07
---

# Phase 23 Plan 02: Diagnostic Bundles Plan 02 Summary

Added CLI task and HTTP download endpoint for the diagnostic bundle generator.

## Key Actions
- Built `mix relyra.diagnostic` mix task that calls `create_bundle` and writes to `relyra_diagnostic_bundle.zip`.
- Added HTTP controller `DiagnosticController` that serves the diagnostic bundle zip file as a download.
- Extended the `relyra_admin_routes` macro in `LiveAdmin.Router` with the `GET /diagnostic/bundle` route.
- Embedded a "Download Diagnostic Bundle" link inside the `ConnectionsLive` header UI for quick access.

## Deviations from Plan
- **[Rule 1 - Bug]** Fixed `test/phoenix/diagnostic_controller_test.exs` failure by adding `Ecto.Adapters.SQL.Sandbox.checkout` block to setup as the bundle query fetches connections and audit logs which mandate an active Sandbox transaction.

## Self-Check: PASSED
