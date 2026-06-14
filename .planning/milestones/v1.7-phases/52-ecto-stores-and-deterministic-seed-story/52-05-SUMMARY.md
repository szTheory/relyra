---
phase: 52-ecto-stores-and-deterministic-seed-story
plan: 05
subsystem: demo_app
tags:
  - demo
  - mapper
  - session
  - receipt
dependency_graph:
  requires:
    - 52-03
    - 52-04
  provides:
    - Host-owned user mapping
    - Host-owned session receipt
  affects:
    - LedgerLoop config
    - LedgerLoop test boundary
tech_stack:
  added:
    - LedgerLoop.Relyra.UserMapper
    - LedgerLoop.Relyra.SessionAdapter
  patterns:
    - Ecto behaviour implementations
key_files:
  created:
    - demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex
  modified:
    - demo/ledger_loop/config/config.exs
    - demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex
    - demo/ledger_loop/test/ledger_loop/relyra/host_boundary_test.exs
decisions_made:
  - LedgerLoop.Relyra.UserMapper uses SAMLIdentity to find a deterministic user and fetches LedgerLoop tenant/groups.
  - LedgerLoop.Relyra.SessionAdapter establishes a host session by writing a deterministic LoginReceipt row and verifying explicitly what Relyra verified vs what LedgerLoop owns.
metrics:
  duration: 10m
  completed_date: 2026-06-12
---

# Phase 52 Plan 05: Host Boundary Demo Data Summary

LedgerLoop maps verified Relyra principals to seeded host users and SAML identities, and establishes host-owned session/receipt proof.

## Accomplishments
- Implemented `LedgerLoop.Relyra.UserMapper` to prove host-owned user lookups using verified principal data from Relyra.
- Implemented `LedgerLoop.Relyra.SessionAdapter` to insert a deterministic `LoginReceipt` for the verified user.
- Updated `config/config.exs` to wire both adapter implementations into Relyra.
- Verified test cases ensure that the host boundary explicitly acknowledges Relyra's SAML validation while preserving zero leakage of SAML internals in receipt payloads.

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- FOUND: demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex
- FOUND: 4d4ac93
- FOUND: 405fffb