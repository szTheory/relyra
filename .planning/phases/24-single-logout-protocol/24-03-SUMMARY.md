---
phase: 24
plan: 03
subsystem: relyra/protocol
tags:
  - logout
  - saml
  - binding
  - redirect
requires:
  - relyra/protocol/logout_request
provides:
  - relyra/protocol/binding
affects:
  - lib/relyra/protocol/binding.ex
tech_stack_added: []
tech_stack_patterns:
  - base64
  - query param parsing
key_files_created:
  - test/relyra/protocol/binding_test.exs
key_files_modified:
  - lib/relyra/protocol/binding.ex
key_decisions:
  - "Decided to mirror POST telemetry logic for consistency in redirect decoding."
duration: "00:05:00"
completed_at: "2026-05-08T00:30:49Z"
---
# Phase 24 Plan 03: Logout Bindings Parser Summary

Updated `Relyra.Protocol.Binding` to support parsing both HTTP-Redirect and HTTP-POST bindings for incoming SAML Logout messages, and updating `encode_redirect` to correctly output SAMLRequest vs SAMLResponse params.

## Completed Tasks

1. **Task 1: Logout Bindings Parser** - Updated `encode_redirect` to accept options for SAMLRequest/SAMLResponse. Implemented `decode_redirect` to correctly extract the payload from either parameter and decode it, adding telemetry tracking for consistency with HTTP-POST.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
FOUND: lib/relyra/protocol/binding.ex
FOUND: d4654ee
