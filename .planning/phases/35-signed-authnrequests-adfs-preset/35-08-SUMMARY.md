---
phase: 35-signed-authnrequests-adfs-preset
plan: 08
subsystem: ci
tags: [ci, security, gating]
requires:
  - phase: 35-07
    provides: AUTHN-01 security corpus
provides:
  - ci.security wiring for AUTHN-01
  - hollow-gate meta-check registration
affects: [ci, security]
key-files:
  modified:
    - mix.exs
    - test/security/ci_gate_integrity_test.exs
requirements-completed: [AUTHN-01]
completed: 2026-05-26
---

# Phase 35 Plan 08 Summary

Promoted the new redirect-signing corpus into the permanent security gate.

## Accomplishments

- Added `test/security/authn_request_signing_test.exs` to `mix ci.security` as its own `cmd mix test` line.
- Registered the `:authn_request_signing` suite in the hollow-gate integrity test so it cannot silently fall out of CI.
- Verified the new corpus runs green inside the security lane.

