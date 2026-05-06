---
phase: 17-certificate-inventory-staged-rollover-ui
plan: 02
subsystem: live_admin
tags:
  - ui
  - verification
  - certificates
  - safety
dependency_graph:
  requires:
    - 17-01
  provides:
    - Typed verification modal using native HTML dialog
    - Event handler for modal confirmation submission
  affects:
    - admin_ui
    - certificate_inventory
tech_stack:
  added: []
  patterns:
    - Native HTML `<dialog>` toggled with JS
    - Pattern-based input validation
key_files:
  modified:
    - lib/relyra/live_admin/components/connection_detail.ex
    - lib/relyra/live_admin/connections_live.ex
key_decisions:
  - Use native HTML `<dialog>` toggled by inline `onclick` instead of complex LiveView state to keep the component stateless and fast.
  - Utilize the HTML5 `pattern` attribute on the verification input for immediate client-side validation, ensuring operators cannot submit unless the first 6 characters match.
  - Retain server-side validation in `confirm_activate_certificate` for comprehensive security coverage against bypassing the client.
---

# Phase 17 Plan 02: Implement 3-Step Staged Rollover with Typed Verification Summary

Implemented a typed verification modal for promoting certificates to prevent unintended trust state changes, and added standard confirmations for retiring certificates.

## Completed Tasks

1.  **Build Typed Verification Modal:** Replaced the direct "Promote next" button action with a native HTML `<dialog>` modal. The modal forces operators to type the first 6 characters of the certificate fingerprint to confirm promotion. Utilized the HTML `pattern` attribute to block submission until the typed input correctly matches the expected characters. Standard `data-confirm` prompts were added for both "Retire active" and "Restore and retire current active" actions.
2.  **Wire Modal Event Verification:** Created a new `confirm_activate_certificate` event handler replacing the previous `activate_certificate`. The new handler securely verifies that the user-provided string matches the start of the fingerprint before proceeding. The `Ecto.StaleEntryError` optimistic locking conflict rescue logic was preserved. 

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check
- [x] All tasks executed and committed individually
- [x] Typed verification modal presents for activate_certificate
- [x] Promotion is only performed when the first 6 chars of fingerprint match 

## Threat Flags
None. The UI appropriately mitigates T-17-02 via typed verification.