---
phase: 35-signed-authnrequests-adfs-preset
plan: 02
subsystem: protocol
tags: [protocol, redirect-binding, deflate]
requires:
  - phase: 35-01
    provides: redirect signing primitive
provides:
  - raw-DEFLATE redirect encoding
  - signed query assembly in spec order
  - ADFS lowercase percent-encoding variant
affects: [protocol, interoperability]
key-files:
  modified:
    - lib/relyra/protocol/binding.ex
    - test/relyra/protocol/binding_test.exs
    - test/conformance/sp_conformance_test.exs
requirements-completed: [AUTHN-01]
completed: 2026-05-26
---

# Phase 35 Plan 02 Summary

Reworked redirect binding to match the wire-level rules that Phase 35 depends on.

## Accomplishments

- Added raw-DEFLATE compression before base64 for HTTP-Redirect binding.
- Assembled signed query strings in spec order (`SAMLRequest`, optional `RelayState`, `SigAlg`) and appended the URL-encoded signature separately.
- Added the ADFS lowercase-hex encoding mode and regression coverage for the compressed/signed redirect path.

