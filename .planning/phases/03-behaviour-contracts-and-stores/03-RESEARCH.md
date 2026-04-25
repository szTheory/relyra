# Phase 3 Research - Behaviour Contracts and Stores

## 1) Goal restatement and boundary

Phase 3 must ship stable extension behaviour contracts and safe defaults for request-intent and replay controls, without weakening the strict typed-failure posture implemented in Phase 2.

Required IDs in scope for this phase:
- `SEC-06` (atomic replay protection)
- `PROT-04` (`InResponseTo` request-intent enforcement)
- `EXT-01`, `EXT-02`, `EXT-03`, `EXT-04`, `EXT-05` (behaviour surface + adapters + internal defaults + resolver decoupling)

Out of scope here:
- Phoenix route/controller ergonomics (`PHX-*`, Phase 4)
- telemetry catalog and redaction (`OBS-*`, Phase 5)
- release hardening and provider docs (Phase 6)

## 2) Current codebase baseline and gaps

The current implementation is close to the target semantics but has no extension-store abstraction yet:

- `lib/relyra.ex`
  - `start_login/3` generates request XML + relay state.
  - `consume_response/3` currently requires caller-supplied `request_intent` map and only validates tuple shape + relay-state presence.
- `lib/relyra/protocol/validation_pipeline.ex`
  - already enforces strict correlation checks (`relay_state` and `in_response_to`) against provided `request_intent`.
  - no request/replay persistence or atomic consume checks.
- `lib/relyra/security/relay_state.ex`
  - already has opaque `rs_` generation and rejection semantics.
  - current persistence seam is an ad hoc `opts[:store_metadata]` callback, not a stable behaviour.
- `lib/relyra/security/xml.ex` + `test/security/xml/seam_contract_test.exs`
  - provide precedent for public behaviour contract + internal default adapter pattern.
- `lib/relyra/application.ex`
  - no supervised runtime components yet (relevant for ETS ownership and cleanup).
- `mix.exs`
  - no optional Ecto deps yet (required for `EXT-03`).

Main gap: strict correlation logic exists, but the source of truth is still caller-provided maps rather than store-backed one-time semantics.

## 3) Recommended architecture

### 3.1 Public behaviour contracts (`EXT-01`, `EXT-05`)

Publish five behaviour modules as the stable extension API:

1. `Relyra.ConnectionResolver`
2. `Relyra.SessionAdapter`
3. `Relyra.UserMapper`
4. `Relyra.RequestStore`
5. `Relyra.ReplayStore`

Recommendation: keep these modules documented and public, but keep default adapter implementations as `@moduledoc false` (`EXT-05`), matching the existing seam style.

### 3.2 Callback-shape recommendations (implementation-specific)

Use `%Relyra.Error{}` for all adapter failures to preserve public tuple consistency.

Recommended stable callback intent:

- `Relyra.ConnectionResolver`
  - resolve connection context from plain maps only (no `Plug.Conn`, no Ecto structs required in protocol core path).
  - return a normalized connection map containing keys already used by Phase 2:
    - `:connection_id`
    - `:idp_entity_id` or `:issuer`
    - `:sp_entity_id`
    - `:acs_url`
    - `:cert_chain`
    - `:idp_sso_url` (for `start_login/3`)

- `Relyra.RequestStore`
  - `put_intent/3` at login initiation.
  - `fetch_intent/2` by relay-state handle (non-consuming).
  - `consume_intent/3` with atomic one-time semantics once validation succeeds.

  This split (`fetch` then `consume`) avoids consuming the intent on mismatched `InResponseTo` attempts, preserving fail-closed behavior without creating a one-shot DoS.

- `Relyra.ReplayStore`
  - `consume_replay_key/3` (atomic insert-or-reject semantics).
  - key should be deterministic and derived from validated response material (`connection_id`, `issuer`, signed assertion/response id).

- `Relyra.SessionAdapter` and `Relyra.UserMapper`
  - freeze behaviour names and minimal callback contracts now, even if full runtime wiring lands in Phase 4.
  - this prevents Phase 4 from reopening extension API shape.

### 3.3 Store adapter layering and defaults (`EXT-02`, `EXT-03`)

Recommended adapter modules:

- `Relyra.RequestStore.ETS` (`@moduledoc false`)
- `Relyra.ReplayStore.ETS` (`@moduledoc false`)
- `Relyra.RequestStore.Ecto` (`@moduledoc false`, optional dependency boundary)
- `Relyra.ReplayStore.Ecto` (`@moduledoc false`, optional dependency boundary)

Safe-default policy:
- default to ETS in dev/test for zero-friction local usage.
- emit loud warnings when ETS adapters are used in production mode (single-node constraints, owner lifecycle, no cluster-wide guarantees).
- provide Ecto adapters for production-safe atomic semantics behind optional dependencies.

### 3.4 Integration flow through current entrypoints (`PROT-04`, `SEC-06`, `EXT-04`)

Recommended consume path using existing code:

1. Validate `opts[:relay_state]` is present (existing behavior).
2. Resolve `request_intent`:
   - if explicit full map is passed, keep compatibility path.
   - otherwise fetch via configured `RequestStore.fetch_intent/2` using relay state.
3. Resolve connection context:
   - explicit `opts[:connection]` still allowed.
   - fallback to `ConnectionResolver` map-only callback.
4. Run `ValidationPipeline.run/4` unchanged for trust/protocol checks.
5. Run replay consume (`ReplayStore.consume_replay_key/3`) atomically.
6. Run request-intent consume (`RequestStore.consume_intent/3`) atomically.
7. Return `{:ok, login_result}` only if both consume operations succeed.

This preserves Phase 2 validation ordering while adding one-time semantics at the orchestration layer, not in protocol-core validators.

## 4) Requirement-by-requirement implementation guidance

### `SEC-06` - replay protection with atomic consume semantics

Implementation recommendations:
- Add `ReplayStore` behaviour with atomic consume callback.
- Replay key should include tenant/connection scope to avoid cross-tenant collisions.
- Ecto adapter should enforce uniqueness at database layer (unique index + upsert/insert conflict handling).
- ETS adapter should use `:ets.insert_new/2` on a deterministic key for single-node atomicity.

Typed failures:
- prefer a stable atom like `:replayed_assertion` (or `:replayed_response` if both classes are tracked).

### `PROT-04` - enforce `InResponseTo` request intent

Implementation recommendations:
- Keep existing strict mismatch/missing checks in `ValidationPipeline.validate_request_correlation/3`.
- Move source of request intent from ad hoc caller map to `RequestStore.fetch_intent/2` default path.
- Keep explicit-map compatibility path for advanced callers/tests.

Important behavior:
- do not consume/delete request intent before correlation passes.

### `EXT-01` - expose five public behaviours

Implementation recommendations:
- create behaviour modules under `lib/relyra/` with typed callback contracts and examples.
- add seam-contract tests equivalent to `test/security/xml/seam_contract_test.exs` for all five behaviours.
- lock callback names/arity during 03-01 to avoid churn in 03-02/03-03.

### `EXT-02` - ETS dev adapters with loud production warnings

Implementation recommendations:
- implement ETS adapters with deterministic table naming and startup/ownership strategy.
- warn loudly (at runtime) when ETS adapters execute in `:prod`.
- include clear warning text: single-node-only, no cross-node replay guarantees, owner-process lifecycle risk.

### `EXT-03` - optional Ecto production adapters

Implementation recommendations:
- add optional deps in `mix.exs` (`ecto`, `ecto_sql`, `postgrex` where needed).
- isolate Ecto-dependent code so base library compiles cleanly without optional deps.
- use transactional consume semantics in Ecto adapters:
  - request consume: conditional update (`consumed_at IS NULL`) or lock-and-update.
  - replay consume: unique key insert.

### `EXT-04` - multi-tenant resolver decoupling

Implementation recommendations:
- resolve connection context through `ConnectionResolver` plain-map callback.
- keep protocol core (`ValidationPipeline`, `Response`, `Assertion`) free of Phoenix/Ecto dependencies.
- pass resolved map to existing pipeline fields (`issuer`, `cert_chain`, `acs_url`, `sp_entity_id`).

### `EXT-05` - default adapters internal, behaviour contracts public

Implementation recommendations:
- set `@moduledoc false` on default adapter implementations.
- keep behaviour modules fully documented and stable.
- document extension points in user-facing docs without exposing adapter internals as part of compatibility contract.

## 5) Likely files/modules to touch

High-confidence targets in this codebase:

- `lib/relyra.ex`
  - integrate resolver/store loading in `start_login/3` and `consume_response/3`.
  - preserve tuple contract and existing error wrapping.
- `lib/relyra/protocol/validation_pipeline.ex`
  - minimal changes only if request-intent ingestion shape changes; preserve strict stage order semantics.
- `lib/relyra/security/relay_state.ex`
  - replace/augment ad hoc `store_metadata` callback with `RequestStore.put_intent/3` integration seam.
- `lib/relyra/application.ex`
  - add supervision children if ETS owners/cleanup workers are introduced.
- `mix.exs`
  - optional Ecto deps and any compile-no-optional-deps guard refinements.
- new behaviour modules:
  - `lib/relyra/connection_resolver.ex`
  - `lib/relyra/session_adapter.ex`
  - `lib/relyra/user_mapper.ex`
  - `lib/relyra/request_store.ex`
  - `lib/relyra/replay_store.ex`
- new default adapters:
  - `lib/relyra/request_store/ets.ex`
  - `lib/relyra/replay_store/ets.ex`
  - `lib/relyra/request_store/ecto.ex`
  - `lib/relyra/replay_store/ecto.ex`
- tests:
  - `test/relyra_test.exs` (public contract compatibility)
  - `test/protocol/consume_response_pipeline_test.exs` (correlation/replay flow)
  - new behaviour seam tests + adapter tests + concurrency tests
  - fixture manifests under `test/fixtures/security/protocol/` for replay and request-intent classes

## 6) Migration and compatibility concerns

Primary compatibility goal: do not break existing consumers of `start_login/3` and `consume_response/3`.

Recommendations:

- Keep `consume_response/3` accepting explicit `request_intent` maps (legacy path).
- Add store-backed path as safe default when callers do not provide full intent.
- Maintain existing typed errors (`:relay_state_missing`, `:relay_state_mismatch`, `:in_response_to_mismatch`) to avoid downstream alerting regressions.
- Introduce new replay-specific typed error atom(s) carefully and document them as additive.
- If Ecto optional deps are absent, ensure Ecto adapter modules fail with clear typed runtime errors rather than compile failures.

Operational migration notes:
- ETS tables are process-owned; crashes/restarts can drop data unless ownership strategy is explicit.
- Ecto migrations/schemas may be deferred to later phase, but adapter API should already anticipate table shape and unique constraints.

## 7) Test strategy and verification

### 7.1 Test layers

1. Behaviour contract tests
- assert callback presence/arity for all five behaviours.
- assert tuple and error-shape contracts.

2. Adapter unit tests
- ETS request consume is one-time under concurrent calls.
- ETS replay consume rejects second insert for same replay key.
- Ecto adapters enforce one-time semantics with transactional/constraint-backed behavior.

3. Integration tests through `Relyra.consume_response/3`
- request-intent fetched from store path.
- `InResponseTo` mismatch rejection still typed and deterministic.
- replayed payload rejected on second consume attempt.

4. Compatibility tests
- existing explicit request-intent map path remains valid.
- existing tests in `test/relyra_test.exs` and protocol manifest tests continue to pass with expected atoms.

### 7.2 Verification commands

Use existing project conventions plus phase-specific runs:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix test test/protocol --warnings-as-errors
mix test test/security --warnings-as-errors
mix qa
mix ci.fast
mix ci.security
```

If Ecto adapters are introduced in this phase:

```bash
mix compile --no-optional-deps --warnings-as-errors
```

This check is required to prevent accidental hard coupling to optional deps.

## 8) Security and reliability considerations

- Fail closed if request intent cannot be loaded from configured store path.
- Do not consume request intent before correlation checks pass.
- Replay key derivation must include tenant/connection scope.
- Avoid storing raw assertion XML in request/replay stores; store only identifiers and minimal correlation metadata.
- Guard against clock/ttl drift by storing explicit expiry and rejecting stale entries.
- Ensure store operation failures produce typed `%Relyra.Error{}` and never implicit success.
- Keep protocol-core modules storage-agnostic; all persistence remains in adapter/orchestration layers.

## Validation Architecture

Dimension A - Behaviour Contract Stability (`EXT-01`, `EXT-05`)
- Check A1: all five behaviour modules exist with documented callback contracts.
- Check A2: default adapters are `@moduledoc false`; behaviours remain public surface.
- Evidence: seam contract tests + docs build.

Dimension B - Request Intent Correctness (`PROT-04`)
- Check B1: request intent can be loaded from store by relay-state.
- Check B2: missing/mismatched `InResponseTo` stays fail-closed with typed errors.
- Check B3: explicit legacy request-intent map path remains supported.
- Evidence: consume integration tests covering success/missing/mismatch/legacy modes.

Dimension C - Atomic Request Consume
- Check C1: request intent is consumed exactly once under concurrency.
- Check C2: mismatch attempts do not consume valid intents.
- Evidence: concurrency tests (multiple tasks against same relay-state/request id).

Dimension D - Replay Protection (`SEC-06`)
- Check D1: replay key consume is atomic.
- Check D2: second use of same replay material returns typed replay error.
- Check D3: replay keys are tenant/connection scoped.
- Evidence: adapter race tests + end-to-end replay fixture class.

Dimension E - Adapter Safety Defaults (`EXT-02`, `EXT-03`)
- Check E1: ETS adapters work in dev/test and emit loud production warnings.
- Check E2: Ecto adapters compile/run only when optional deps are present.
- Check E3: no-optional-deps compilation still passes.
- Evidence: targeted adapter tests + compile checks.

Dimension F - Architecture Boundary Integrity (`EXT-04`)
- Check F1: protocol-core modules do not import Phoenix/Ecto APIs.
- Check F2: connection context passed to pipeline is plain-map contract.
- Evidence: static grep/boundary checks + module compile graph review.

Dimension G - Typed Error Determinism
- Check G1: store and replay failures map to stable `%Relyra.Error{type: atom()}`.
- Check G2: no non-typed return path in `start_login/3` and `consume_response/3`.
- Evidence: tuple-contract tests + fixture manifest assertions.

## 9) Planner decisions now locked by Phase 3 plans

The following items are resolved and should be treated as plan-locked implementation constraints:

1. Callback signatures are fixed
- `ConnectionResolver.resolve_connection/2`
- `SessionAdapter.establish_session/3`
- `UserMapper.map_attributes/3`
- `RequestStore.put_intent/3`
- `RequestStore.fetch_intent/2`
- `RequestStore.consume_intent/3`
- `ReplayStore.consume_replay_key/3`

2. Consume ordering is fixed
- `consume_response/3` must call replay consume first, then request-intent consume, and only return success after both operations succeed.

3. Replay key schema baseline is fixed
- Use combined key format `"#{connection_id}:#{issuer}:#{signed_xml_id}"` to avoid cross-tenant/cross-issuer collisions.

4. No-store/default behavior is fixed
- Default adapters remain internal and return typed `%Relyra.Error{}` failures (`:adapter_not_configured` / `:unsupported_default_adapter`) rather than silent success.

Remaining implementation details (still open to execution-level choice):
- ETS ownership strategy (named table vs owner process shape).
- Whether Ecto migrations land in this phase or remain adapter-contract-only with follow-up schema work.

---

Overall confidence: high on seam architecture and integration points (they align with existing `Relyra` + pipeline design), medium on consume-order edge cases that depend on planner prioritization of replay vs request-consume failure precedence.
