---
phase: 19
plan: 01
subsystem: data-model
tags: [schema, migration]
dependency_graph:
  requires: []
  provides: [IDP-INIT-01]
  affects: [Relyra.Connection]
tech_stack:
  added: []
  patterns: [Ecto Migration]
key_files:
  created: [priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs]
  modified: [lib/relyra/connection.ex]
decisions:
  - Added allow_idp_initiated boolean column to relyra_connections, defaulting to false.
metrics:
  duration: 15m
  completed_date: "2026-05-06"
---

# Phase 19 Plan 01: Data Model Update Summary

## One-liner
Added `allow_idp_initiated` flag to the connection schema and database.

## Implementation Details
- Created migration `20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`.
- Updated `Relyra.Connection` schema to include `allow_idp_initiated`.
- Added validation for the new field.

## Deviations from Plan
None.

## Self-Check: PASSED
- [x] Migration exists and runs.
- [x] Schema is updated.
- [x] Tests for the flag pass.
