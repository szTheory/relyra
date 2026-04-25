# Phase 3: Behaviour Contracts and Stores - Pattern Mapping

Derived from:
- `.planning/phases/03-behaviour-contracts-and-stores/03-CONTEXT.md`
- `.planning/phases/03-behaviour-contracts-and-stores/03-RESEARCH.md`

This artifact maps likely Phase 3 implementation targets to repository-local analogs and preserves existing Elixir contracts already in use.

## Target Files

| Target path | Role | Likely action | Why this file is in Phase 3 scope |
|---|---|---|---|
| `lib/relyra/connection_resolver.ex` | interface/behaviour | Create | `EXT-01`, `EXT-04`: stable resolver seam returning plain maps for protocol core use. |
| `lib/relyra/session_adapter.ex` | interface/behaviour | Create | `EXT-01`: stable session extension contract before Phase 4 runtime wiring. |
| `lib/relyra/user_mapper.ex` | interface/behaviour | Create | `EXT-01`: stable user mapping extension contract before runtime integration. |
| `lib/relyra/request_store.ex` | interface/behaviour | Create | `EXT-01`, `PROT-04`: request intent put/fetch/consume contract. |
| `lib/relyra/replay_store.ex` | interface/behaviour | Create | `EXT-01`, `SEC-06`: atomic replay consume contract. |
| `lib/relyra/request_store/ets.ex` | adapter implementation | Create | `EXT-02`: development-safe default request intent persistence adapter. |
| `lib/relyra/replay_store/ets.ex` | adapter implementation | Create | `EXT-02`: development-safe replay consume adapter. |
| `lib/relyra/request_store/ecto.ex` | adapter implementation | Create | `EXT-03`: production-safe atomic request consume via DB semantics. |
| `lib/relyra/replay_store/ecto.ex` | adapter implementation | Create | `EXT-03`: production-safe replay idempotency and uniqueness semantics. |
| `lib/relyra.ex` | orchestration integration | Modify | Integrate resolver/store hooks in `start_login/3` and `consume_response/3` while preserving tuple contract. |
| `lib/relyra/security/relay_state.ex` | orchestration integration | Modify | Replace ad hoc metadata callback seam with explicit request-store intent persistence linkage. |
| `lib/relyra/protocol/validation_pipeline.ex` | orchestration integration | Minimal modify (if needed) | Keep strict correlation ordering; ensure store-backed intent map remains compatible. |
| `lib/relyra/application.ex` | orchestration integration | Modify (optional) | Supervise ETS owner/process components if runtime store ownership is introduced. |
| `mix.exs` | orchestration integration | Modify | Add optional Ecto dependency boundary and preserve base compile behavior. |
| `test/relyra_test.exs` | tests | Modify | Preserve public API tuple compatibility with store-backed consume path. |
| `test/protocol/consume_response_pipeline_test.exs` | tests | Modify | Add request-store/replay consume semantics without regressing typed correlation failures. |
| `test/security/extensions/seam_contract_test.exs` | tests | Create (likely) | Mirror seam contract testing style for new Phase 3 behaviours (`EXT-01`). |
| `test/security/stores/request_store_ets_test.exs` | tests | Create (likely) | Validate one-time consume and race handling for request store ETS adapter. |
| `test/security/stores/replay_store_ets_test.exs` | tests | Create (likely) | Validate atomic replay rejection semantics for ETS adapter (`SEC-06`). |
| `test/security/stores/request_store_ecto_test.exs` | tests | Create (likely) | Validate transactional consume semantics for Ecto request store adapter. |
| `test/security/stores/replay_store_ecto_test.exs` | tests | Create (likely) | Validate unique/atomic replay consume semantics for Ecto replay adapter. |
| `test/fixtures/security/protocol/manifest.json` | fixtures | Modify | Add replay-related and request-store correlation fixture classes with expected typed errors. |

## Existing Analogs

| Target(s) | Closest analog path(s) | Pattern to copy |
|---|---|---|
| `lib/relyra/*_store.ex`, `lib/relyra/connection_resolver.ex`, `lib/relyra/session_adapter.ex`, `lib/relyra/user_mapper.ex` | `lib/relyra/security/xml.ex`, `lib/relyra/error.ex` | Public behaviour contract with typed callbacks and `%Relyra.Error{}` tuple outputs. |
| `lib/relyra/request_store/ets.ex`, `lib/relyra/replay_store/ets.ex` | `lib/relyra/security/signature.ex`, `lib/relyra/protocol/binding.ex` | Internal module style (`@moduledoc false`), strict guard clauses, typed `Error.new/3` failures. |
| `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex` | `lib/relyra/security/signature.ex`, `lib/relyra/protocol/authn_request.ex` | Input normalization, deterministic error atoms, and option-driven policy enforcement with no API shape drift. |
| `lib/relyra.ex` | `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex` | `with` orchestration, fail-closed tuple normalization, explicit rescue/catch wrapping to `:internal_protocol_error`. |
| `lib/relyra/security/relay_state.ex` | `lib/relyra/security/relay_state.ex` | Opaque relay handle generation and persistence seam handoff; keep strict reject-by-default semantics. |
| `lib/relyra/protocol/validation_pipeline.ex` | `lib/relyra/protocol/validation_pipeline.ex` | Preserve strict stage ordering and existing request-correlation checks/atoms. |
| `test/security/extensions/seam_contract_test.exs` | `test/security/xml/seam_contract_test.exs` | `behaviour_info(:callbacks)` assertions and typed tuple contract checks. |
| Store adapter tests under `test/security/stores/*.exs` | `test/security/xml/error_atoms_test.exs`, `test/security/xml/corpus_security_test.exs` | Determinism checks and repeat-run assertions for stable typed failures. |
| `test/protocol/consume_response_pipeline_test.exs` + fixture manifests | `test/protocol/consume_response_pipeline_test.exs`, `test/fixtures/security/protocol/manifest.json` | Manifest-driven expected-error mapping and strict tuple-shape assertions via real consume flow. |

## Code Excerpts

### 1) Behaviour callback shape and typed return contract
Source: `lib/relyra/security/xml.ex`

```elixir
@callback parse_safely(binary(), keyword()) ::
            {:ok, term()} | {:error, %Error{}}
@callback select_signed_node(parsed_doc :: term(), keyword()) ::
            {:ok, term()} | {:error, %Error{}}
@callback canonicalize(signed_node_handle :: term(), keyword()) ::
            {:ok, binary()} | {:error, %Error{}}
```

Phase 3 reuse: `lib/relyra/request_store.ex` and `lib/relyra/replay_store.ex` should follow this exact callback + tuple style.

### 2) Canonical typed error constructor
Source: `lib/relyra/error.ex`

```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

Phase 3 reuse: all behaviour adapters in `lib/relyra/request_store/*` and `lib/relyra/replay_store/*` should construct failures via `Relyra.Error.new/3`.

### 3) Orchestration style in public entrypoints
Source: `lib/relyra.ex`

```elixir
with :ok <- validate_request_intent(request_intent),
     :ok <- validate_relay_state_opt(opts, request_intent),
     connection <- connection_context(request_intent, opts),
     result <- ValidationPipeline.run(response_payload, request_intent, connection, opts) do
  normalize_consume_result(result)
else
  {:error, %Error{} = error} ->
    {:error, error}
end
```

Phase 3 reuse: keep this staged `with` pattern in `lib/relyra.ex` when inserting request-store fetch/consume and replay consume hooks.

### 4) Fail-closed request-correlation checks to preserve
Source: `lib/relyra/protocol/validation_pipeline.ex`

```elixir
cond do
  not present?(posted_relay_state) ->
    {:error, Error.new(:relay_state_missing, "RelayState option is required for consume_response validation", %{...})}

  normalize(posted_relay_state) != normalize(expected_relay_state) ->
    {:error, Error.new(:relay_state_mismatch, "Posted RelayState does not match request intent", %{...})}

  normalize(actual_in_response_to) != normalize(expected_in_response_to) ->
    {:error, Error.new(:in_response_to_mismatch, "Response InResponseTo does not match request intent", %{...})}

  true ->
    :ok
end
```

Phase 3 reuse: store-backed request intent in `lib/relyra.ex` must preserve these exact fail-closed semantics and error atoms in `lib/relyra/protocol/validation_pipeline.ex`.

### 5) Existing relay metadata seam to evolve
Source: `lib/relyra/security/relay_state.ex`

```elixir
defp persist_metadata(relay_state, metadata, opts) do
  case Keyword.get(opts, :store_metadata) do
    store_metadata when is_function(store_metadata, 2) ->
      _ = store_metadata.(relay_state, metadata)
      :ok

    _ ->
      :ok
  end
end
```

Phase 3 reuse: this callback seam is the natural migration point for explicit `RequestStore.put_intent/2` orchestration from `lib/relyra.ex`.

### 6) Internal adapter style + deterministic error atoms
Source: `lib/relyra/security/signature.ex`

```elixir
defmodule Relyra.Security.Signature do
  @moduledoc false

  @spec verify(map(), map(), [binary()], keyword()) :: {:ok, SignedNode.t()} | {:error, Error.t()}
  def verify(parsed_doc, connection, cert_chain, opts \\ [])

  def verify(parsed_doc, connection, cert_chain, opts)
      when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
    ...
  end
end
```

Phase 3 reuse: mark default adapters (`lib/relyra/request_store/ets.ex`, `lib/relyra/replay_store/ets.ex`, `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex`) as internal with explicit specs and guard clauses (`EXT-05`).

### 7) Behaviour seam contract testing pattern
Source: `test/security/xml/seam_contract_test.exs`

```elixir
callbacks =
  XML.behaviour_info(:callbacks)
  |> Enum.map(&elem(&1, 0))

assert :parse_safely in callbacks
assert :select_signed_node in callbacks
assert :canonicalize in callbacks
```

Phase 3 reuse: `test/security/extensions/seam_contract_test.exs` should assert callback presence for all five new behaviours.

### 8) Manifest-driven deterministic failure testing
Source: `test/protocol/consume_response_pipeline_test.exs`

```elixir
manifest()
|> Enum.each(fn fixture ->
  assert {:error, %Relyra.Error{type: expected_type}} =
           Relyra.consume_response(
             fixture["payload"],
             request_intent(),
             consume_opts(now: @fixed_now, relay_state: relay_state_for_fixture(fixture))
           )

  assert expected_type == String.to_atom(fixture["expected_error_type"])
end)
```

Phase 3 reuse: extend `test/fixtures/security/protocol/manifest.json` and keep this exact expected-error mapping pattern for replay/request-store outcomes.

## Data Flow

### Request intent + replay control flow through consume path

1. `lib/relyra.ex` - `start_login/3`
   - builds request fields, generates request ID, issues relay state.
   - Phase 3 insertion: call configured `Relyra.RequestStore` adapter to persist `{relay_state, request_intent}` metadata.

2. `lib/relyra/security/relay_state.ex` - `issue/2`
   - currently exposes persistence seam via `opts[:store_metadata]`.
   - Phase 3: preserve opaque relay-state policy while routing metadata through explicit request-store contract.

3. `lib/relyra.ex` - `consume_response/3`
   - validates input contract and `opts[:relay_state]`.
   - Phase 3 insertion: resolve request intent source as:
     - explicit caller map (compat path), or
     - `RequestStore.fetch_intent/2` using `opts[:relay_state]`.

4. `lib/relyra/protocol/validation_pipeline.ex` - `run/4`
   - performs strict correlation checks (`:relay_state_missing`, `:relay_state_mismatch`, `:in_response_to_mismatch`) and trust/protocol validation order.
   - Phase 3 rule: do not weaken or reorder current validation stages.

5. `lib/relyra.ex` post-validation success path
   - derive deterministic replay key from validated response context (`connection_id`, issuer, signed XML ID).
   - call `ReplayStore.consume_replay_key/2` atomically:
     - first consume succeeds,
     - duplicate consume returns typed replay error.

6. `lib/relyra.ex` final commit step
   - call `RequestStore.consume_intent/2` atomically to mark one-time request use.
   - only return `{:ok, login_result}` after both replay consume and request consume succeed.

### Consume-order guidance (for planner/executor)

- Keep mismatch-safe behavior: failed correlation in `lib/relyra/protocol/validation_pipeline.ex` must not consume request intent.
- Prefer replay consume before request consume in `lib/relyra.ex` so replay rejection cannot burn valid request intent.
- Ensure both store failures return `%Relyra.Error{type: atom()}` and preserve `consume_response/3` tuple shape.

## Implementation Guardrails

- In `lib/relyra/protocol/validation_pipeline.ex`, preserve `@ordered_stages` and the existing correlation atoms (`:relay_state_missing`, `:relay_state_mismatch`, `:in_response_to_mismatch`).
- In `lib/relyra.ex`, preserve public return contract `{:ok, map()} | {:error, %Relyra.Error{}}`; keep `normalize_consume_result/1`-style tuple hardening.
- In `lib/relyra/request_store.ex`, `lib/relyra/replay_store.ex`, `lib/relyra/connection_resolver.ex`, `lib/relyra/session_adapter.ex`, and `lib/relyra/user_mapper.ex`, follow the behaviour callback style used in `lib/relyra/security/xml.ex`.
- In `lib/relyra/request_store/ets.ex` and `lib/relyra/replay_store/ets.ex`, keep `@moduledoc false` and emit loud production warnings (`EXT-02`, `EXT-05`).
- In `lib/relyra/request_store/ecto.ex` and `lib/relyra/replay_store/ecto.ex`, isolate optional dependency boundaries so base compilation remains clean when Ecto deps are absent (`mix.exs`).
- In `lib/relyra/security/relay_state.ex`, do not relax opaque relay-state validation (`raw_url` and tamper rejection paths stay fail-closed).
- In `test/security/extensions/seam_contract_test.exs`, mirror `behaviour_info(:callbacks)` assertions from `test/security/xml/seam_contract_test.exs`.
- In `test/protocol/consume_response_pipeline_test.exs`, extend manifest-driven assertions and keep deterministic typed error checks.
- In `test/fixtures/security/protocol/manifest.json`, add replay/request-store classes without removing existing Phase 2 classes or expected atoms.
- In `test/relyra_test.exs`, keep compatibility coverage for explicit caller-provided request intent map while adding store-backed path checks.

## PATTERN MAPPING COMPLETE
- Output: `.planning/phases/03-behaviour-contracts-and-stores/03-PATTERNS.md`
