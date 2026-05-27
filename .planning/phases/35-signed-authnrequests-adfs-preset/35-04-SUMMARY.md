---
phase: 35-signed-authnrequests-adfs-preset
plan: 04
subsystem: provider
tags: [provider, preset, adfs]
requires:
  - phase: 35-03
    provides: persisted signed_request_encoding field
provides:
  - ADFS provider preset
  - ADFS-specific default signing posture
affects: [provider, onboarding]
key-files:
  created:
    - lib/relyra/provider/adfs.ex
  modified:
    - lib/relyra/provider.ex
    - test/provider/provider_test.exs
    - test/support/fake_connection_resolver.ex
requirements-completed: [AUTHN-04]
completed: 2026-05-26
---

# Phase 35 Plan 04 Summary

Registered the ADFS preset and made its redirect-signing defaults explicit.

## Accomplishments

- Added `Relyra.Provider.ADFS`.
- Registered the preset in the provider registry and test fixtures.
- Defaulted the preset to signed AuthnRequests and `:adfs_lower` encoding so ADFS-specific interop lives in one place.

