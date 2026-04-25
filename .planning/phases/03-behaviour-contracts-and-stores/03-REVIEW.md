---
status: issues_found
phase: "03-behaviour-contracts-and-stores"
updated: 2026-04-24
---

# Phase 03 Focused Code Review

## Scope

- Reviewed phase 03 plan commits matched by message grep: `03-01`, `03-02`, `03-03`.
- Commit set reviewed: `9841e09`, `f4acf93`, `29cc55a`, `7066eda`, `2bd56ae`, `223cb72`, `4a801f9`, `ff6d220`, `ce6fd68`, `a6cf9aa`, `6937807`, `700f04c`.
- Focus applied in requested order:
  1. behavior bugs/regressions
  2. replay/request-intent security flow
  3. contract drift and typed error guarantees
  4. missing/flaky tests
- Relevant suite run during review (all green): `mix test test/security/extensions/seam_contract_test.exs test/security/stores/request_store_ets_test.exs test/security/stores/replay_store_ets_test.exs test/security/stores/request_store_ecto_test.exs test/security/stores/replay_store_ecto_test.exs test/protocol/consume_response_pipeline_test.exs test/relyra_test.exs`.

## Findings

### [high] Request-intent TTL is persisted but never enforced before consume success

- **Files:** `lib/relyra.ex`, `lib/relyra/request_store/ets.ex`, `lib/relyra/request_store/ecto.ex`, `test/protocol/consume_response_pipeline_test.exs`
- **Impact:** `start_login/3` records `expires_at` in persisted request intent, but `consume_response/3` never rejects expired intent. This allows stale request intents to remain valid until consumed, weakening request-intent freshness guarantees in the replay/request-correlation path.
- **Evidence:** A direct runtime check using `Relyra.RequestStore.ETS` with an already expired intent (`expires_at: ~U[2020-01-01 00:00:00Z]`) still returned `{:ok, login_result}` from `Relyra.consume_response/2`.
- **Why this matters:** Assertion time checks and request-intent TTL are separate controls. Without TTL enforcement, the intent store does not bound request validity as phase 03 design implies.
- **Remediation:** Add explicit intent-expiry validation in `consume_response/3` (before `ValidationPipeline.run/4`) and return a typed error (for example `:request_intent_expired`) when `expires_at < now`. Optionally harden adapters to treat expired records as non-consumable. Add fixture + test coverage for expired store-backed intent rejection.

### [medium] Misconfigured adapter module can raise and violate tuple contract in `start_login/3`

- **Files:** `lib/relyra/request_store.ex`, `lib/relyra/replay_store.ex`, `lib/relyra/connection_resolver.ex`, `lib/relyra.ex`, `test/relyra_test.exs`
- **Impact:** Adapter dispatch wrappers call module functions directly without checking function export. In `start_login/3`, a bad `:request_store` value raises `UndefinedFunctionError` instead of returning typed `{:error, %Relyra.Error{}}`, breaking the advertised public tuple contract.
- **Evidence:** Runtime reproduction with `Relyra.start_login(connection, relay_context, request_store: :not_a_module)` raised `UndefinedFunctionError` (`:not_a_module.put_intent/3` undefined).
- **Why this matters:** Phase 03 explicitly freezes typed extension seams; hard crashes from config drift are contract regressions and can create avoidable availability failures.
- **Remediation:** Harden adapter dispatch at seam boundaries with `function_exported?/3` checks and typed fallback errors (`:adapter_not_configured` or `:unsupported_default_adapter`) instead of direct unsafe invocation. Add regression tests asserting `start_login/3` and `consume_response/3` never raise for invalid adapter module options.

## Missing Test Coverage Gaps

- No test currently asserts expired request intent rejection in store-backed consume flow.
- No test asserts misconfigured adapter modules return typed error tuples (and do not raise) at public API entry points.

## Review Status

Focused review completed with **2 issues found** (`1 high`, `1 medium`). Blocking concern is request-intent TTL non-enforcement in consume flow.
