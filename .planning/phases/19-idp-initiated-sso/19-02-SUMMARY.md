---
phase: 19
plan: 02
subsystem: security
tags: [security, utility]
dependency_graph:
  requires: []
  provides: [IDP-INIT-01]
  affects: [Relyra.Security.Redirect]
tech_stack:
  added: []
  patterns: [TDD, Security Utility]
key_files:
  created: [lib/relyra/security/redirect.ex, test/security/redirect_test.exs]
  modified: []
decisions:
  - Implemented a safe local redirect utility to prevent Open Redirect vulnerabilities when handling RelayState.
metrics:
  duration: 15m
  completed_date: "2026-05-06"
---

# Phase 19 Plan 02: Safe Redirect Utility Summary

## One-liner
Implemented `Relyra.Security.Redirect` utility for safe local path validation.

## Implementation Details
- Created `Relyra.Security.Redirect` with `safe_local_redirect/2`.
- Validates that paths are local (start with `/`), not protocol-relative (not `//`), and not absolute URLs.
- Returns `{:ok, path}` or `{:error, %Relyra.Error{}}`.

## Deviations from Plan
None.

## Self-Check: PASSED
- [x] `lib/relyra/security/redirect.ex` exists.
- [x] `test/security/redirect_test.exs` exists and passes.
