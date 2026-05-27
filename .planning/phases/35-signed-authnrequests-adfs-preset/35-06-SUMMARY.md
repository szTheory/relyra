---
phase: 35-signed-authnrequests-adfs-preset
plan: 06
subsystem: metadata
tags: [metadata, authnrequest, signing]
requires:
  - phase: 35-05
    provides: signed connection runtime behavior
provides:
  - metadata-level AuthnRequestsSigned gating
  - signing KeyDescriptor gating
affects: [metadata, federation]
key-files:
  modified:
    - lib/relyra/protocol/metadata.ex
    - test/relyra/protocol/metadata_test.exs
requirements-completed: [AUTHN-03]
completed: 2026-05-26
---

# Phase 35 Plan 06 Summary

Aligned SP metadata with the runtime signing toggle.

## Accomplishments

- Added `AuthnRequestsSigned="true"` only when the connection enables signed AuthnRequests.
- Gated the signing `KeyDescriptor` on the same toggle without disturbing the encryption metadata introduced in Phase 34.
- Added tests for both toggle-on and toggle-off metadata behavior.

