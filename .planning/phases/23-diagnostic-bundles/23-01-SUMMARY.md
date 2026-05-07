---
phase: 23-diagnostic-bundles
plan: 01
subsystem: Diagnostic
tags: [diagnostic, zip, export, telemetry]
dependency_graph:
  requires: [relyra_ecto, relyra_error]
  provides: [Relyra.Diagnostic, Relyra.Diagnostic.AllowList]
  affects: [mix_tasks]
tech_stack:
  added: [:zip]
  patterns: [Explicit Map Allowlist, In-memory Archive]
key_files:
  created:
    - lib/relyra/diagnostic/allow_list.ex
    - lib/relyra/diagnostic.ex
    - test/relyra/diagnostic/allow_list_test.exs
    - test/relyra/diagnostic_test.exs
  modified: []
decisions:
  - "Decided to manually catch `:ets.info/2` via `try/rescue` to dynamically read default ETS store counts without imposing new behavior callbacks."
metrics:
  duration: "10m"
  completed_date: "2026-05-07"
---

# Phase 23 Plan 01: Core Diagnostic Export Service Summary

Implemented an explicitly allow-listed diagnostic bundle generation service that compiles SAML connection state, certificate inventory, and system metrics into a secure, in-memory ZIP archive.

## Execution Details

- Developed `Relyra.Diagnostic.AllowList` to enforce a deny-by-default redaction boundary, explicitly transforming Ecto structs into maps with zero sensitive data (e.g., stripping `:private_key` and PEM data).
- Bounded Audit Event exports to the latest 1,000 records to prevent memory exhaustion and hashed `correlation_id` values dynamically to obfuscate PII.
- Created `Relyra.Diagnostic` service to fetch required data sets through `Repo`, apply redactions, format into logical JSON files, and compile them into a zip binary via Erlang's `:zip.create/3`.
- Adopted a fallback for dynamic RequestStore and ReplayStore metrics checking for ETS `size` without forcing schema/behavior modifications.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test failure on AllowList map assertion**
- **Found during:** Task 1
- **Issue:** Attempting to assert `result.correlation_id == nil` raised a `KeyError` in `test/relyra/diagnostic/allow_list_test.exs` since the struct map rejected the `nil` key entirely.
- **Fix:** Switched assertions to use `Map.get(result, :correlation_id)` rather than dot-notation on dynamic maps.
- **Files modified:** `test/relyra/diagnostic/allow_list_test.exs`
- **Commit:** 74a6efb

**2. [Rule 1 - Bug] Test failure missing MigrationCase**
- **Found during:** Task 2
- **Issue:** Used `Relyra.Ecto.MigrationCase` but actual test support is nested at `Relyra.TestSupport.MigrationCase`. 
- **Fix:** Modified `test/relyra/diagnostic_test.exs` to use the correct `TestSupport` module and Ecto alias.
- **Files modified:** `test/relyra/diagnostic_test.exs`
- **Commit:** 9b4250c
## Self-Check: PASSED
