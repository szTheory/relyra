---
phase: 74-clean-room-package-consumer
plan: 02
subsystem: testing
tags: [ecto, postgres, package-consumer, migration, replay]
requires: [74-01]
provides:
  - Artifact-owned Relyra migration proof and consumer-owned persistent-store schema.
  - Configured Ecto request and replay adapter behavior, including typed duplicate rejection.
  - Deterministic concurrent uniqueness and migration-idempotency checks in the full profile.
affects: [74-03, 74-04]
requirements-completed: [PKG-02, PKG-04]
completed: 2026-09-25
status: complete
---

# Phase 74 Plan 02: Persistent Store Contract Summary

The clean-room consumer now applies Relyra migrations from the unpacked artifact and its request/replay tables from its own migration directory. The shipped Ecto adapters perform persisted request reads and consumes, replay consumes, and typed duplicate rejection. A simultaneous two-task barrier proves uniqueness for both adapters; rerunning both migration sources applies no versions and preserves the expected rows.

## Task Commits

1. **Task 1: Migrate both owners and exercise persistent store adapters** — `ca17dff`
2. **Task 2: Prove rerun and concurrent uniqueness behavior** — `fd2d2e0`

## Files Created or Modified

- `test/fixtures/package_consumer/consumer/priv/repo/migrations/20260924000100_create_runtime_stores.exs` — consumer-owned request and replay schema with unique indexes.
- `test/fixtures/package_consumer/consumer/lib/package_consumer/stores.ex` — fixed-repo, fixed-table wrappers over the shipped adapters.
- `test/fixtures/package_consumer/consumer/smoke/store_contract.exs` — migration ownership, adapter behavior, race and rerun assertions.
- `scripts/check_clean_room_consumer.sh` — discovers all sorted consumer smoke scripts and forwards only their safe PASS marker lines.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 scripts/check_clean_room_consumer.sh --profile full` — passed. Signed ACS, package provenance, private-support exclusion, both migration owners, persistent adapter operations, concurrent uniqueness, and migration reruns all passed.
- `git diff --check` — passed before Task 2 commit.

## Deviations

Plan 74-02 assumed Plan 74-01's harness already ran every `smoke/*.exs`; inspection showed it ran only `signed_acs.exs`. The harness was corrected to execute all smoke scripts in lexical order and print only PASS marker lines, allowing the planned store smoke to run without exposing full debug logs. This was necessary to satisfy the plan's automatic smoke-discovery assumption.

## Next Plan

Proceed to Plan 74-03 after reviewing its dependencies and scope.

## Self-Check: PASSED

- All declared Plan 74-02 artifacts exist.
- Task commits `ca17dff` and `fd2d2e0` are reachable in Git history.
- The full clean-room consumer profile passed with both smoke scripts and all migration/store markers.
