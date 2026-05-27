---
phase: 35-signed-authnrequests-adfs-preset
plan: 05
subsystem: runtime
tags: [runtime, phoenix, redirect]
requires:
  - phase: 35-01
    provides: redirect signing primitive
  - phase: 35-02
    provides: signed redirect query assembly
  - phase: 35-03
    provides: persisted encoding choice
provides:
  - signed start_login flow
  - verbatim signed redirect controller path
affects: [runtime, phoenix]
key-files:
  modified:
    - lib/relyra.ex
    - lib/relyra/phoenix/controllers/login_controller.ex
    - test/relyra_test.exs
    - test/phoenix/login_controller_test.exs
requirements-completed: [AUTHN-01, AUTHN-02]
completed: 2026-05-26
---

# Phase 35 Plan 05 Summary

Connected the signing machinery to the public login path.

## Accomplishments

- Extended `Relyra.start_login/3` to emit `redirect_query` for signed connections while preserving the existing unsigned map shape.
- Added the Phoenix controller path that appends the signed query bytes verbatim to the IdP SSO URL.
- Added regression coverage for signed and unsigned runtime behavior, including collision-avoidance around pre-existing query strings.

