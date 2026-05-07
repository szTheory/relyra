---
phase: "22"
plan: "01"
status: completed
---

# Phase 22 Plan 01 Summary

## Work Completed
- **Task 1 (Telemetry setup for expiry alerts):** Added `[:relyra, :saml, :certificate, :expiring]` to the known events in `lib/relyra/telemetry.ex`. Updated `LogAlerts` handler to log `Logger.warning` for these events with correctly redacted metadata. Verified via `test/relyra/telemetry/handlers/log_alerts_test.exs`.
- **Task 2 (Certificate Expiry traversal engine):** Implemented `Relyra.Security.CertificateExpiry` with the `check_all/2` function. It safely performs batch queries of active/next certificates on enabled connections, sequentially processes them via `Enum.map`, and emits the required `:telemetry` events. Fallback behavior without `Ecto.Query` handles optional dependency requirements appropriately. Verified via `test/relyra/security/certificate_expiry_test.exs`.

## Verification Status
All automated tests for `LogAlerts` and `CertificateExpiry` completed successfully and pass. The Ecto constraints and telemetry redaction behaviors are fully verified.