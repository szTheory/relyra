---
phase: 03-behaviour-contracts-and-stores
plan: 03
subsystem: protocol-core-orchestration
tags: [request-intent, replay-protection, resolver-integration, tuple-contracts]
requires:
  - phase: 03-01
    provides: behaviour contracts and default adapter scaffolding
  - phase: 03-02
    provides: ETS/Ecto request and replay adapter semantics
provides:
  - store-backed request intent resolution in consume_response/3 with explicit-map compatibility
  - replay consume then request consume gating before any success tuple
  - typed conflict and missing-intent failures without protocol-core framework coupling
affects: [phase-03-completion, requirement-tracking]
tech-stack:
  added: []
  patterns:
    - behaviour-dispatch wrappers for resolver/request/replay adapters
    - consume success gating with typed error fallbacks
key-files:
  created:
    - .planning/phases/03-behaviour-contracts-and-stores/03-03-SUMMARY.md
  modified:
    - lib/relyra.ex
    - lib/relyra/security/relay_state.ex
    - lib/relyra/connection_resolver.ex
    - lib/relyra/request_store.ex
    - lib/relyra/replay_store.ex
    - test/protocol/consume_response_pipeline_test.exs
    - test/fixtures/security/protocol/manifest.json
    - test/relyra_test.exs
key-decisions:
  - "Consume success is now blocked on replay consume first, then request-intent consume, and both failures map to typed atoms."
  - "Request intent persistence moved to explicit RequestStore orchestration in start_login/3; RelayState no longer owns metadata callback persistence."
  - "ConnectionResolver, RequestStore, and ReplayStore gained module-level dispatch helpers so protocol orchestration stays map-based and framework-agnostic."
requirements-completed: [SEC-06, PROT-04, EXT-04]
duration: 12min
completed: 2026-04-24
---

# Phase 03 Plan 03: Integrate resolver, request intent, and replay semantics into consume flow Summary

**Phase 3 consume orchestration now enforces store-backed request intent and replay gates while preserving strict typed validation failures and explicit request_intent compatibility.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-24T17:53:00Z
- **Completed:** 2026-04-24T18:05:07Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Updated `start_login/3` to persist request intent immediately after relay issuance via `RequestStore.put_intent/3`, with typed `:request_store_failure` fallback and persisted intent fields (`request_id`, `relay_state`, `connection_id`, `issuer`, `sp_entity_id`, `acs_url`, `issued_at`, `expires_at`).
- Refactored `consume_response/3` to support explicit-map compatibility and store-backed intent resolution (`RequestStore.fetch_intent(opts[:relay_state], opts)`), resolver fallback (`ConnectionResolver.resolve_connection/2`), and post-validation replay/request consume gates.
- Enforced replay-first ordering and request-intent consume second; consume gate failures now return typed `:replayed_assertion` or `:request_intent_consumed` and never return `{:ok, _}`.
- Preserved `ValidationPipeline` mismatch/missing atoms (`:relay_state_missing`, `:relay_state_mismatch`, `:in_response_to_mismatch`) and kept protocol-core free of Plug/Phoenix/Ecto coupling.
- Extended protocol fixtures and tests for new classes (`request_intent_missing`, store-backed `in_response_to_mismatch`, `replayed_assertion`, explicit compatibility success) and added required acceptance tags.

## Verification Results

All required plan verification commands passed:

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `rg -n "Plug\\.|Phoenix\\.|Ecto\\." lib/relyra/protocol/**/*.ex lib/relyra.ex` (0 matches)
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors --only replay_consume_failure_blocks_success`
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors --only request_consume_failure_blocks_success`
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors --only consume_ordering_gate`
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors`
- `mix test test/relyra_test.exs --warnings-as-errors`
- `mix test test/protocol --warnings-as-errors`

## Task Commits

1. **Task 03-03-T01 + 03-03-T02:** `a6cf9aa` - Persist request intent from `start_login/3`, add adapter dispatch helpers, and enforce consume replay/request gating in `consume_response/3`.
2. **Task 03-03-T03:** `6937807` - Expand fixtures and consume tests for missing-intent, replay conflict, ordering gate, and explicit compatibility path coverage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix format --check-formatted` initially failed on `lib/relyra.ex` and `test/protocol/consume_response_pipeline_test.exs`; fixed by running `mix format` and re-running verification.

## User Setup Required

None.

## Next Phase Readiness

- Phase 03 plan 03 acceptance checks are green and summary artifacts are complete.
- Next step is Phase 03 closure/transition workflow (`03-03` summary committed, then phase-level state/roadmap updates as directed by the orchestrator flow).

