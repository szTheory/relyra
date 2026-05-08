---
phase: 24
plan: 01
subsystem: session_management
tags:
  - slo
  - session
  - request_store
requires: []
provides:
  - session_revocation_behavior
affects:
  - lib/relyra/session_adapter.ex
  - lib/relyra/session_adapter/default.ex
  - lib/relyra/request_store.ex
tech-stack:
  added: []
  patterns:
    - telemetry_span
    - behaviour_callbacks
key-files:
  created:
    - lib/relyra/session_adapter/default.ex
    - test/relyra/session_adapter_test.exs
    - test/relyra/request_store_test.exs
  modified:
    - lib/relyra/session_adapter.ex
    - lib/relyra/request_store.ex
decisions:
  - Default intent type for RequestStore is `:authn` to maintain backward compatibility.
metrics:
  duration: 2m
  completed_date: "2026-05-08T00:00:00Z"
---
# Phase 24 Plan 01: Single Logout Protocol Core Behaviors Summary

Extended `SessionAdapter` for session revocation and isolated RequestStore intents with `:type` identifiers.

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- Created files verified.
- Commits recorded successfully.
