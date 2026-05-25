---
phase: 33-key-resolver-behaviour-xmlenc-crypto-core
plan: "01"
subsystem: key-resolver
tags: [behaviour, key-resolver, xmlenc, encryption, security]
dependency_graph:
  requires: []
  provides:
    - Relyra.KeyResolver behaviour contract (resolve/2 dispatch)
    - Relyra.KeyResolver.Default (PEM-from-config implementation)
    - ENC-04a/b/c unit corpus (key_resolver_test.exs)
  affects:
    - Phase 34 XMLEnc pipeline wiring (XMLEnc.decrypt/3 calls KeyResolver.resolve/2)
tech_stack:
  added: []
  patterns:
    - RequestStore dispatch pattern (Code.ensure_loaded? + function_exported? + try/rescue/catch)
    - Application.get_env(:relyra, :sp_private_key_pem) config read
key_files:
  created:
    - lib/relyra/key_resolver.ex
    - lib/relyra/key_resolver/default.ex
    - test/relyra/key_resolver_test.exs
  modified: []
decisions:
  - "D-01: KeyResolver uses RequestStore dispatch pattern exactly — Code.ensure_loaded?/1 + function_exported?/3 guard, try/rescue/catch wrapper, three error builders (adapter_not_configured, invalid_adapter_result, adapter_dispatch_error)"
  - "D-02: Result normalisation is {:ok, pem} when is_binary(pem) — never is_map — distinct from RequestStore which matches {:ok, result} when is_map(result)"
  - "D-03: PEM binary stays in local variable scope only; never appears in any Error.new/3 details map, Logger call, or telemetry metadata"
metrics:
  duration: "~3m"
  completed_date: "2026-05-25"
  tasks: 2
  files: 3
---

# Phase 33 Plan 01: KeyResolver Behaviour + Default Implementation Summary

**One-liner:** `Relyra.KeyResolver` behaviour with `resolve/2` dispatch and `KeyResolver.Default` reading SP private key PEM from `Application.get_env(:relyra, :sp_private_key_pem)` — RequestStore pattern cloned exactly.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | KeyResolver behaviour module with dispatch function | d52b461 | lib/relyra/key_resolver.ex |
| 2 | KeyResolver.Default implementation + key_resolver_test.exs unit corpus | 515570b | lib/relyra/key_resolver/default.ex, test/relyra/key_resolver_test.exs |

## What Was Built

### `lib/relyra/key_resolver.ex`

`Relyra.KeyResolver` declares `@callback resolve(connection :: map()) :: {:ok, pem_binary :: binary()} | {:error, Error.t()}` and exposes a public `resolve/2` (connection, opts) dispatch function. The dispatch reads `Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)` and guards with `Code.ensure_loaded?/1 + function_exported?(adapter, :resolve, 1)`, wrapping `apply/3` in `try/rescue/catch`. Result normalisation passes `{:ok, pem} when is_binary(pem)` through; any other return routes to `invalid_adapter_result/3`. Three private error builders mirror the RequestStore shape (`:adapter_not_configured` type for all three).

### `lib/relyra/key_resolver/default.ex`

`Relyra.KeyResolver.Default` implements `@behaviour Relyra.KeyResolver` with `@impl true`. Main clause matches `is_map(connection)`, reads `Application.get_env(:relyra, :sp_private_key_pem)`, returns `{:ok, pem}` on binary or `{:error, %Error{type: :key_not_configured}}` on nil. Catch-all clause returns the same `:key_not_configured` shape for non-map inputs. No connection field is used (future adapters may scope keys per tenant).

### `test/relyra/key_resolver_test.exs`

7-test unit corpus covering ENC-04a/b/c:
- Default dispatch with nil config → `{:error, %Error{type: :key_not_configured}}`
- Default dispatch with binary config → `{:ok, pem}`
- Custom adapter in `:key_resolver` opt → dispatches correctly
- Unknown module → `{:error, %Error{type: :adapter_not_configured}}`
- Adapter returning `{:ok, non-binary}` → `{:error, %Error{type: :adapter_not_configured}}`
- Adapter raising exception → `{:error, %Error{type: :adapter_not_configured}}`
- Non-map connection → `{:error, %Error{}}`

## Success Criteria Verification

1. `Relyra.KeyResolver` at `lib/relyra/key_resolver.ex` — declares `@callback resolve(connection :: map())` and `resolve/2` dispatch following RequestStore pattern. **DONE**
2. `Relyra.KeyResolver.Default` at `lib/relyra/key_resolver/default.ex` — reads `Application.get_env(:relyra, :sp_private_key_pem)`, returns `{:ok, pem}` when binary, `{:error, %Error{type: :key_not_configured}}` when nil. **DONE**
3. `test/relyra/key_resolver_test.exs` covers ENC-04a (dispatch), ENC-04b (nil config), ENC-04c (binary config). **DONE**
4. `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` exits 0 — 7 tests, 0 failures. **DONE**
5. `mix test --warnings-as-errors` exits 0 — 582 tests, 0 failures. **DONE**

## Deviations from Plan

None — plan executed exactly as written.

The plan's TDD structure requires both `key_resolver.ex` and `key_resolver/default.ex` to exist before the test corpus passes (because the dispatch function references `Relyra.KeyResolver.Default` by default). Both modules were created in a single implementation pass during the GREEN phase, with the test file created first in the RED phase. Both artifacts were committed atomically per their task.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes introduced. SP private key PEM stays in application config only; never in Ecto, Logger, telemetry, or `Error.new/3` details maps. The `@sensitive_keys` in `audit_writer.ex`, `log_alerts.ex`, and `log.ex` provide defense-in-depth if a future caller accidentally leaks the PEM under a covered key name.

## Known Stubs

None. Both modules are fully wired: `KeyResolver.Default` reads a real config value, `KeyResolver.resolve/2` dispatches to real adapters. No hardcoded empty values or placeholder data.

## Self-Check: PASSED

- `lib/relyra/key_resolver.ex` — exists, contains `@callback resolve(connection :: map())`
- `lib/relyra/key_resolver/default.ex` — exists, contains `@behaviour Relyra.KeyResolver` and `@impl true`
- `test/relyra/key_resolver_test.exs` — exists, 7 tests
- Commit d52b461 — exists (Task 1)
- Commit 515570b — exists (Task 2)
- `mix test --warnings-as-errors` — 582 tests, 0 failures
- `mix format --check-formatted` — exits 0
