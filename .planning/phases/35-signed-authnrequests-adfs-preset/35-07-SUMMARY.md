---
phase: 35-signed-authnrequests-adfs-preset
plan: 07
subsystem: security-corpus
tags: [security, corpus, fixtures]
requires:
  - phase: 35-05
    provides: signed runtime path
  - phase: 35-06
    provides: metadata gating
provides:
  - AUTHN-01 golden corpus
  - committed redirect-signing fixtures
affects: [security, fixtures, regressions]
key-files:
  created:
    - test/security/authn_request_signing_test.exs
    - test/fixtures/security/authn_request_signing/golden_authnrequest.xml
    - test/fixtures/security/authn_request_signing/golden_redirect.txt
    - test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt
    - test/fixtures/security/authn_request_signing/PROVENANCE.md
  modified:
    - test/relyra/protocol/binding_test.exs
requirements-completed: [AUTHN-01]
completed: 2026-05-26
---

# Phase 35 Plan 07 Summary

Committed the redirect-signing golden corpus and the fixtures that make it durable.

## Accomplishments

- Added the five-row AUTHN-01 security corpus: golden positive control, ADFS variant, re-serialization regression, round-trip verify, and unsigned no-op.
- Committed the golden XML, query-string fixtures, signing key, and provenance manifest.
- Added additional binding-level regression tests around the signed query path.

