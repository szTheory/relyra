# Phase 19: IdP-Initiated SSO - Pattern Map

**Mapped:** 2024-05-19
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/ecto/connection.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | exact |
| `priv/repo/migrations/*_add_allow_idp_initiated.exs` | migration | batch | `priv/repo/migrations/20260505130000_add_metadata_revision_pointers_to_relyra_connections.exs` | exact |
| `lib/relyra.ex` | facade | request-response | `lib/relyra.ex` | exact |
| `lib/relyra/protocol/validation_pipeline.ex` | service | request-response | `lib/relyra/protocol/validation_pipeline.ex` | exact |
| `lib/relyra/login_result.ex` | model | request-response | `lib/relyra/login_result.ex` | exact |
| `lib/relyra/security/redirect.ex` | utility | validation | `lib/relyra/security/relay_state.ex` | exact |

## Pattern Assignments

### `lib/relyra/ecto/connection.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/connection.ex`

**Schema pattern** (lines 22-50):
```elixir
    schema "relyra_connections" do
      # ... existing fields
      field :idp_sso_url, :string
      field :lock_version, :integer, default: 1
      # Insert allow_idp_initiated here:
      # field :allow_idp_initiated, :boolean, default: false
```

**Changeset pattern** (lines 60-84):
```elixir
    def draft_changeset(connection, attrs) do
      connection
      |> cast(attrs, [
        :connection_id,
        # ...
        :idp_sso_url,
        :active_metadata_revision_id,
        :last_known_good_metadata_revision_id
        # Add :allow_idp_initiated to cast
      ])
```

---

### `priv/repo/migrations/*_add_allow_idp_initiated.exs` (migration, batch)

**Analog:** `priv/repo/migrations/20260505130000_add_metadata_revision_pointers_to_relyra_connections.exs`

**Migration pattern** (lines 1-11):
```elixir
defmodule Relyra.Repo.Migrations.AddMetadataRevisionPointersToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :active_metadata_revision_id, :binary_id
      # Pattern for new boolean field:
      # add :allow_idp_initiated, :boolean, default: false, null: false
    end
  end
end
```

---

### `lib/relyra.ex` (facade, request-response)

**Analog:** `lib/relyra.ex`

**Core request intent resolution pattern** (lines 169-181):
```elixir
  defp resolve_request_intent(opts, []) when is_list(opts) do
    relay_state = Keyword.get(opts, :relay_state)

    if relay_state do
      case RequestStore.fetch_intent(relay_state, opts) do
        {:ok, intent} ->
          {:ok, intent, opts}
          # ...
```
*(Pattern needs to be adapted to allow returning `{:ok, nil, opts}` if `request_intent_or_opts` is explicitly `nil` or lacks intent, so the pipeline can proceed and evaluate `allow_idp_initiated` based on the connection context.)*

---

### `lib/relyra/protocol/validation_pipeline.ex` (service, request-response)

**Analog:** `lib/relyra/protocol/validation_pipeline.ex`

**Validation pattern** (lines 81-98):
```elixir
  defp validate_request_correlation(parsed_doc, request_intent, _opts) do
    expected_id = Map.get(request_intent, :request_id) || Map.get(request_intent, :in_response_to)
    actual_id = Map.get(parsed_doc, :in_response_to)

    if expected_id == actual_id do
      :ok
    else
      {:error,
       Error.new(
         :in_response_to_mismatch,
         "SAML Response InResponseTo does not match request ID",
         # ...
```
*(Pattern needs modification: check `connection.allow_idp_initiated?` if `request_intent` is `nil` and `actual_id` is missing).*

---

### `lib/relyra/security/redirect.ex` (utility, validation)

**Analog:** `lib/relyra/security/relay_state.ex`

**Validation pattern** (lines 20-38):
```elixir
  def validate(relay_state, _opts) when is_binary(relay_state) do
    cond do
      String.starts_with?(relay_state, "http://") ->
        rejected(:raw_url, %{relay_state: relay_state})

      String.starts_with?(relay_state, "https://") ->
        rejected(:raw_url, %{relay_state: relay_state})

      String.starts_with?(relay_state, "//") ->
        rejected(:raw_url, %{relay_state: relay_state})
        # ...
```
*(Pattern is ideal for `safe_local_redirect/2` to ensure a redirect path strictly starts with `/` and not `//` to avoid open redirects.)*

---

## Shared Patterns

### Error Handling
**Source:** `lib/relyra/security/relay_state.ex`
**Apply to:** Validation utilities
```elixir
  defp rejected(reason, details) do
    {:error,
     Error.new(
       :relay_state_rejected,
       "RelayState rejected by opaque handle policy",
       Map.put(details, :reason, reason)
     )}
  end
```

## Metadata

**Analog search scope:** `lib/relyra/**/*.ex`, `priv/repo/migrations/*.exs`
**Files scanned:** 6
**Pattern extraction date:** 2024-05-19
