---
phase: 35-signed-authnrequests-adfs-preset
plan: 01
subsystem: security
tags: [security, redirect-binding, signing]
requires: []
provides:
  - outbound signing digest policy gate
  - raw-octet redirect signing primitive
  - deterministic signing-key fixture
affects: [security, protocol, fixtures]
key-files:
  created:
    - test/fixtures/security/authn_request_signing/golden_signing_key.pem
    - test/support/mint_signing_key.exs
  modified:
    - lib/relyra/security/algorithm_policy.ex
    - lib/relyra/security/signature.ex
    - test/relyra/security/algorithm_policy_test.exs
    - test/relyra/security/signature_test.exs
requirements-completed: [AUTHN-01]
completed: 2026-05-26
---

# Phase 35 Plan 01 Summary

Implemented the outbound signing primitives that every later Phase 35 plan depends on.

## Accomplishments

- Added `AlgorithmPolicy.signing_digest_atom/1` with fail-closed handling for unsupported and unknown outbound signing algorithms.
- Added `Signature.sign_redirect_query/3` as the single SP-side redirect-binding signing seam over raw query-string bytes.
- Committed the deterministic RSA signing key fixture and mint helper used by the AUTHN-01 golden corpus.

## Notes

- This plan closed the `signing_digest_atom/1` prerequisite gap called out by the stale v1.3 milestone audit.
- The implementation stayed inside the existing `AlgorithmPolicy` and `Signature` seams; no parallel signing module was introduced.

