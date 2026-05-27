# Phase 38: Single Logout (SLO) Core & Security - Pattern Map

**Mapped:** 2024-05-26
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/session_adapter.ex` | behaviour/component | CRUD/event-driven | `lib/relyra/session_adapter.ex` | exact |
| `lib/relyra/protocol/logout_request.ex` | model/parser | data transform | `lib/relyra/protocol/authn_request.ex` | exact |
| `lib/relyra/protocol/logout_response.ex` | model/parser | data transform | `lib/relyra/protocol/response.ex` | exact |
| `lib/relyra/security/logout_validator.ex` | service/validator | validation | `lib/relyra/protocol/validation_pipeline.ex` | role-match |
| `lib/relyra.ex` | facade | request-response | `lib/relyra.ex` (login flow) | exact |

## Pattern Assignments

### `lib/relyra/session_adapter.ex` (behaviour, CRUD)

**Analog:** `lib/relyra/session_adapter.ex`

**Behaviour callback and wrapper pattern** (lines 14-47):
```elixir
  @callback revoke_session(
              subject :: map(),
              session_index :: binary() | nil,
              context :: map(),
              opts :: keyword()
            ) :: {:ok, term()} | {:error, Error.t()}

  @spec revoke_session(map(), binary() | nil, map(), keyword()) ::
          {:ok, term()} | {:error, Error.t()}
  def revoke_session(subject, session_index, context, opts \\ []) do
    metadata = %{
      connection_id: read_field(context, :connection_id),
      flow: :idp_initiated
    }

    Relyra.Telemetry.span([:session, :revoke], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter, Relyra.SessionAdapter.Default)

      result =
        cond do
          Code.ensure_loaded?(adapter) and function_exported?(adapter, :revoke_session, 4) ->
            adapter.revoke_session(subject, session_index, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end
```

### `lib/relyra/protocol/logout_response.ex` (model, data transform)

**Analog:** `lib/relyra/protocol/response.ex`

**Validation and Error pattern** (lines 8-20):
```elixir
  @spec validate_issuer(term(), term()) :: :ok | {:error, Error.t()}
  def validate_issuer(actual_issuer, expected_issuer) do
    if normalize(actual_issuer) == normalize(expected_issuer) do
      :ok
    else
      {:error,
       Error.new(
         :issuer_mismatch,
         "Response issuer does not match configured issuer",
         expected_actual_details(expected_issuer, actual_issuer)
       )}
    end
  end
```

### `lib/relyra.ex` (facade, request-response)

**Analog:** `lib/relyra.ex` `start_login/3` and `consume_response/3`

**Telemetry wrapped facade pattern** (lines 15-46):
```elixir
  @spec start_login(map(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_login(connection, relay_context, opts \\ []) do
    metadata = %{
      connection_id: read_field(connection, :connection_id),
      organization_id: read_field(connection, :organization_id),
      provider_preset: read_field(connection, :provider_preset),
      flow: :sp_initiated,
      binding: :redirect
    }

    Relyra.Telemetry.span([:login], metadata, fn ->
      result = do_start_login(connection, relay_context, opts)

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end
```

## Shared Patterns

### Strict XMLDSig Signature Verification
**Source:** `lib/relyra/security/signature.ex`
**Apply to:** Logout Request/Response validation
```elixir
    Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
      result = do_verify(parsed_doc, connection, cert_chain, opts)
      # ...
```
The signature verify fails CLOSED to a typed `%Relyra.Error{}` and operates on the `parsed_doc` map exposing `:signed_candidates`. Never re-parses XML.

### Strict Replay Protection
**Source:** `lib/relyra/replay_store.ex`
**Apply to:** Consuming LogoutRequests and LogoutResponses
```elixir
    Relyra.Telemetry.span([:replay, :check], telemetry_metadata, fn ->
      start_time = System.monotonic_time()

      result =
        case Keyword.get(opts, :replay_store_consume) do
          fun when is_function(fun, 3) ->
            fun.(replay_key, metadata, opts)

          _ ->
            dispatch_replay_store(replay_store(opts), :consume_replay_key, [
              replay_key,
              metadata,
              opts
            ])
        end
        # ...
```

## No Analog Found

None. All files have direct structural analogs.

## Metadata

**Analog search scope:** `lib/relyra/**/*.ex`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-26
