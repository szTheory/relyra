---
phase: 38-single-logout-slo-core-security
plan: 01
subsystem: session & security
tags:
  - slo
  - crypto
  - redirect-binding
requires: []
provides:
  - index_session/4
  - terminate_by_session_index/4
  - verify_redirect_signature/4
affects:
  - Relyra.SessionAdapter
  - Relyra.Security.Signature
tech-stack:
  - Elixir
  - :public_key
key-files:
  created: []
  modified:
    - lib/relyra/session_adapter.ex
    - lib/relyra/security/signature.ex
    - test/relyra/session_adapter_test.exs
    - test/relyra/security/signature_test.exs
    - test/security/xml/adversarial_crypto_test.exs
    - priv/security_corpus.json
decisions:
  - SessionAdapter extended with index_session and terminate_by_session_index APIs with telemetry.
  - Redirect signature validation is strictly against the raw octet sequence provided by the caller.
metrics:
  duration: 10m
  completed_date: 2026-05-27
---

# Phase 38 Plan 01: Single Logout Core Security Summary

Implemented foundational APIs for HTTP-Redirect signature verification and Session termination.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None
