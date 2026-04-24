---
phase: "03"
plan: "03-02"
title: "Implement ETS and Ecto request/replay adapters with atomic guardrails"
summary_type: "execution"
requirements_completed:
  - SEC-06
  - EXT-02
  - EXT-03
commit_hashes:
  - 223cb72
  - 4a801f9
  - ff6d220
---

# Phase 03 Plan 03-02 Summary

Relyra now ships concrete ETS and optional Ecto request/replay adapters that enforce one-time semantics with typed `%Relyra.Error{}` failures, plus supervised ETS startup and targeted race-condition tests.

## Task Outcomes

### 03-02-T01 - ETS adapters with fail-closed semantics

- Added `Relyra.RequestStore.ETS` with named table `:relyra_request_intents`.
- Added `Relyra.ReplayStore.ETS` with named table `:relyra_replay_keys`.
- Implemented atomic operations using `:ets.insert_new/2` and `:ets.take/2`:
  - replay key consume rejects duplicates with `%Relyra.Error{type: :replayed_assertion}`.
  - request consume allows exactly one success and maps subsequent consumes to `%Relyra.Error{type: :request_intent_consumed}`.
- Added runtime-only production warning path using `opts[:prod_runtime?]` and `Application.get_env(:relyra, :prod_runtime_ets_warning, false)` (no `Mix.env/0` usage).
- Warning copy explicitly includes both required phrases: `"single-node only"` and `"non-durable replay protection"`.
- Commit: `223cb72`

### 03-02-T02 - Optional Ecto adapters and dependency guards

- Added optional deps in `mix.exs`: `:ecto`, `:ecto_sql`, `:postgrex` with `optional: true`.
- Added `Relyra.RequestStore.Ecto`:
  - requires `opts[:repo]` and `opts[:table]`.
  - checks `Code.ensure_loaded?(Ecto.Repo)` and returns `%Relyra.Error{type: :optional_dependency_missing}` when unavailable.
  - uses SQL update semantics to consume only rows matching `relay_state`, `request_id`, and `consumed_at IS NULL`.
  - maps consumed-row conflicts to `%Relyra.Error{type: :request_intent_consumed}`.
- Added `Relyra.ReplayStore.Ecto`:
  - requires `opts[:repo]` and `opts[:table]`.
  - checks `Code.ensure_loaded?(Ecto.Repo)` and returns `%Relyra.Error{type: :optional_dependency_missing}` when unavailable.
  - uses insert semantics and maps unique conflicts to `%Relyra.Error{type: :replayed_assertion}`.
- Error details include required keys: `repo`, `table`, `operation`, `reason`.
- Commit: `4a801f9`

### 03-02-T03 - Supervised startup integration and adapter tests

- Updated `Relyra.Application` to start `Relyra.Application.StoreTables` under supervision.
- Startup bootstrap calls:
  - `Relyra.RequestStore.ETS.ensure_table!/0`
  - `Relyra.ReplayStore.ETS.ensure_table!/0`
- Added targeted tests:
  - `test/security/stores/request_store_ets_test.exs`
  - `test/security/stores/replay_store_ets_test.exs`
  - `test/security/stores/request_store_ecto_test.exs`
  - `test/security/stores/replay_store_ecto_test.exs`
- Coverage includes:
  - concurrent consume races (`Task.async_stream`) with one winner + deterministic typed loser errors.
  - ETS production warning assertions via both runtime opts and runtime app env (no Mix checks).
  - Ecto duplicate replay and consumed-row conflict mappings to required atoms.
- Commit: `ff6d220`

## Verification

All task-level acceptance checks and plan verification commands passed:

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix compile --no-optional-deps --warnings-as-errors`
- `rg -n "insert_new|:ets\.take|:replayed_assertion|Logger\.warning" lib/relyra/request_store/ets.ex lib/relyra/replay_store/ets.ex`
- `rg -n "prod_runtime\?|prod_runtime_ets_warning|Application\.get_env" lib/relyra/request_store/ets.ex lib/relyra/replay_store/ets.ex`
- `rg -n "Mix\.env\(" lib/relyra/request_store/ets.ex lib/relyra/replay_store/ets.ex` (no matches)
- `rg -n "defmodule Relyra\.(RequestStore|ReplayStore)\.Ecto|Code\.ensure_loaded\?|Ecto\.Repo|:request_intent_consumed" lib/relyra/request_store/ecto.ex lib/relyra/replay_store/ecto.ex`
- `rg -n "optional: true|\{\:ecto|\{\:ecto_sql|\{\:postgrex" mix.exs`
- `mix test test/security/stores/request_store_ets_test.exs --warnings-as-errors`
- `mix test test/security/stores/replay_store_ets_test.exs --warnings-as-errors`
- `mix test test/security/stores/request_store_ets_test.exs --warnings-as-errors --only prod_runtime_warning`
- `mix test test/security/stores/replay_store_ets_test.exs --warnings-as-errors --only prod_runtime_warning`
- `mix test test/security/stores/request_store_ecto_test.exs --warnings-as-errors`
- `mix test test/security/stores/replay_store_ecto_test.exs --warnings-as-errors`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- New optional dependencies were initially unresolved during test runs.
- Resolved by running `mix deps.get` before final compile/test verification.

## Next Phase Readiness

Ready for `03-03` integration work to route `consume_response/3` through these adapters and enforce request/replay semantics end-to-end.
