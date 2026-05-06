# Phase 11: Mapping persistence + audit hardening - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/relyra/ecto/attribute_mapping.ex` | model | CRUD | `lib/relyra/ecto/metadata_revision.ex` | role-match |
| `lib/relyra/ecto/group_mapping.ex` | model | CRUD | `lib/relyra/ecto/metadata_revision.ex` | role-match |
| `lib/relyra/ecto/mapping_revision.ex` | model | event-driven | `lib/relyra/ecto/metadata_revision.ex` | exact |
| `lib/relyra/ecto/audit_event.ex` | model | event-driven | `lib/relyra/ecto/metadata_revision.ex` | role-match |
| `lib/relyra/ecto/mapping_commands.ex` | service | request-response | `lib/relyra/ecto/metadata_apply.ex` | exact |
| `lib/relyra/ecto/audit_writer.ex` | service | event-driven | `lib/relyra/ecto/metadata_apply.ex` | partial |
| `lib/relyra/ecto/connection.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | exact |
| `lib/relyra/ecto/connections.ex` | service | request-response | `lib/relyra/ecto/connections.ex` | exact |
| `lib/relyra/ecto/metadata_apply.ex` | service | request-response | `lib/relyra/ecto/metadata_apply.ex` | exact |
| `lib/relyra/ecto/certificate_inventory.ex` | service | request-response | `lib/relyra/ecto/certificate_inventory.ex` | exact |
| `lib/relyra/ecto/connection_loader.ex` | service | request-response | `lib/relyra/ecto/connection_loader.ex` | exact |
| `lib/relyra/ecto/connection_snapshot.ex` | service | transform | `lib/relyra/ecto/connection_snapshot.ex` | exact |
| `lib/relyra/connection.ex` | model | transform | `lib/relyra/connection.ex` | exact |
| `lib/relyra/user_mapper/default_attribute.ex` | utility | transform | `lib/relyra/user_mapper/default_attribute.ex` | exact |
| `priv/repo/migrations/*_create_relyra_attribute_mappings.exs` | migration | CRUD | `priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs` | role-match |
| `priv/repo/migrations/*_create_relyra_group_mappings.exs` | migration | CRUD | `priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs` | role-match |
| `priv/repo/migrations/*_create_relyra_mapping_revisions.exs` | migration | event-driven | `priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs` | exact |
| `priv/repo/migrations/*_create_relyra_audit_events.exs` | migration | event-driven | `priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs` | role-match |
| `test/relyra/ecto/mapping_commands_test.exs` | test | request-response | `test/relyra/ecto/metadata_apply_test.exs` | exact |
| `test/relyra/ecto/mapping_revision_schema_test.exs` | test | CRUD | `test/relyra/ecto/metadata_revision_schema_test.exs` | exact |
| `test/relyra/ecto/audit_event_schema_test.exs` | test | CRUD | `test/relyra/ecto/metadata_revision_schema_test.exs` | role-match |
| `test/relyra/ecto/audit_hardening_test.exs` | test | request-response | `test/relyra/ecto/certificate_inventory_concurrency_test.exs` | role-match |
| `test/relyra/connection_snapshot_test.exs` | test | transform | `test/relyra/connection_snapshot_test.exs` | exact |
| `test/relyra/ecto/migration_constraints_test.exs` | test | CRUD | `test/relyra/ecto/migration_constraints_test.exs` | exact |

## Pattern Assignments

### `lib/relyra/ecto/attribute_mapping.ex` and `lib/relyra/ecto/group_mapping.ex`

**Analog:** `lib/relyra/ecto/metadata_revision.ex`

**Imports/schema pattern** ([lib/relyra/ecto/metadata_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_revision.ex:1)):
```elixir
if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataRevision do
    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.{Connection, MetadataSource}
```

**Enum + belongs_to + append-only timestamps pattern** ([lib/relyra/ecto/metadata_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_revision.ex:17)):
```elixir
schema "relyra_metadata_revisions" do
  field :source_kind, Ecto.Enum, values: @source_kind_values
  field :trigger, Ecto.Enum, values: @trigger_values
  field :outcome, Ecto.Enum, values: @outcome_values

  belongs_to :connection, Connection,
    foreign_key: :connection_record_id,
    references: :id,
    type: :binary_id

  timestamps(type: :utc_datetime_usec, updated_at: false)
end
```

**Changeset validation pattern** ([lib/relyra/ecto/metadata_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_revision.ex:45)):
```elixir
revision
|> cast(attrs, [...])
|> validate_required([
  :connection_record_id,
  :source_kind,
  :trigger,
  :outcome,
  :trust_summary
])
|> validate_non_empty_map(:trust_summary)
|> foreign_key_constraint(:connection_record_id)
```

Use this shape for mapping child rows: `belongs_to :connection`, bounded `Ecto.Enum` fields, explicit required fields, FK constraints, and no hidden callbacks.

---

### `lib/relyra/ecto/mapping_revision.ex`

**Analog:** `lib/relyra/ecto/metadata_revision.ex`

Copy the full module shape from [lib/relyra/ecto/metadata_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_revision.ex:1), but swap domain fields to mapping-specific bounded summaries:

```elixir
field :actor, :string
field :cause, :string
field :details, :map, default: %{}

belongs_to :connection, Connection,
  foreign_key: :connection_record_id,
  references: :id,
  type: :binary_id

timestamps(type: :utc_datetime_usec, updated_at: false)
```

The key pattern to preserve is append-only provenance with `updated_at: false` and a non-empty normalized summary map rather than mutable live-state fields.

---

### `lib/relyra/ecto/audit_event.ex`

**Analog:** `lib/relyra/ecto/metadata_revision.ex`

Use the same Ecto schema framing as [lib/relyra/ecto/metadata_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_revision.ex:11), but model a cross-domain ledger:

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "relyra_metadata_revisions" do
  field :source_kind, Ecto.Enum, values: @source_kind_values
  field :trigger, Ecto.Enum, values: @trigger_values
  field :outcome, Ecto.Enum, values: @outcome_values
  field :trust_summary, :map, default: %{}
  field :actor, :string
  field :cause, :string
  field :details, :map, default: %{}
```

Planner should adapt this to audit fields like `domain`, `action`, `before`, `after`, `diff`, `correlation_id`, while keeping the same bounded-map, explicit-enum, append-only posture.

---

### `lib/relyra/ecto/mapping_commands.ex`

**Analog:** `lib/relyra/ecto/metadata_apply.ex`

**Transactional command boundary** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:13)):
```elixir
with {:ok, repo} <- fetch_repo(opts, :apply_revision),
     :ok <- ensure_optional_dependency!(:apply_revision, repo),
     {:ok, _connection} <- fetch_connection(repo, connection_id, :apply_revision) do
  transact(repo, fn ->
    connection = load_connection!(repo, connection_id)
    revision_attrs = revision_attrs_for_apply(connection, candidate, revision_attrs)

    with {:ok, revision} <- insert_revision(repo, revision_attrs) do
      case apply_outcome(revision) do
        :applied -> apply_candidate(repo, connection, candidate, revision)
        _other -> {:ok, revision}
      end
    end
  end)
  |> normalize_transaction_result(:apply_revision)
end
```

**Normalization/redaction pattern** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:115)):
```elixir
revision_attrs
|> Map.put(:connection_record_id, connection.id)
|> Map.put_new(:outcome, :applied)
|> Map.put_new(:trust_summary, default_trust_summary(candidate))
|> Map.update(:details, %{}, &redact_large_binaries/1)
```

**Typed transaction result handling** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:226)):
```elixir
defp normalize_transaction_result({:ok, {:ok, revision}}, _operation), do: {:ok, revision}
defp normalize_transaction_result({:error, %Error{} = error}, _operation), do: {:error, error}
defp normalize_transaction_result({:error, _step, %Error{} = error, _changes}, _operation),
  do: {:error, error}
```

This is the closest pattern for dedicated mapping writes: explicit repo lookup, fetch current aggregate, compute normalized before/after views, write live rows and revision row inside one transaction, return typed `Relyra.Error`.

---

### `lib/relyra/ecto/audit_writer.ex`

**Analog:** `lib/relyra/ecto/metadata_apply.ex`

No exact analog exists yet, so copy helper structure rather than domain naming. The most reusable pieces are:

**Repo/dependency guard pattern** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:149)):
```elixir
defp fetch_repo(opts, operation) when is_list(opts) do
  case Keyword.fetch(opts, :repo) do
    {:ok, repo} when is_atom(repo) -> {:ok, repo}
    _ -> {:error, Error.new(:adapter_not_configured, "...", error_details(opts, operation, :missing_repo))}
  end
end
```

**Bounded-redaction helper** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:290)):
```elixir
defp redact_large_binaries(map) when is_map(map) do
  map
  |> Enum.map(fn
    {key, value} when is_binary(value) and byte_size(value) > 256 -> {key, "[REDACTED]"}
    {key, value} -> {key, value}
  end)
  |> Enum.into(%{})
end
```

Use this module as a shared insert helper called from `Connections`, `MetadataApply`, `CertificateInventory`, and `MappingCommands`, not as a callback or trigger.

---

### `lib/relyra/ecto/connection.ex`

**Analog:** `lib/relyra/ecto/connection.ex`

**Association declaration pattern** ([lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:20)):
```elixir
schema "relyra_connections" do
  ...
  belongs_to :active_metadata_revision, MetadataRevision, ...
  belongs_to :last_known_good_metadata_revision, MetadataRevision, ...
  embeds_one :runtime_policy, RuntimePolicy, on_replace: :update
  has_many :certificates, Certificate, foreign_key: :connection_record_id, on_replace: :delete
```

**Boundary-protection pattern** ([lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:183)):
```elixir
defp reject_certificate_updates(changeset, attrs) do
  if Map.has_key?(attrs, :certificates) or Map.has_key?(attrs, "certificates") do
    add_error(changeset, :certificates, "are managed through metadata apply or Relyra.Ecto.CertificateInventory")
  else
    changeset
  end
end
```

Phase 11 should add mapping associations here and apply the same protection against generic parent updates for mappings.

---

### `lib/relyra/ecto/connections.ex`

**Analog:** `lib/relyra/ecto/connections.ex`

**Service entrypoint pattern** ([lib/relyra/ecto/connections.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connections.ex:9)):
```elixir
@spec update(binary(), map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
def update(connection_id, attrs, opts \\ [])

def update(connection_id, attrs, opts)
    when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts, :update),
       :ok <- ensure_optional_dependency!(:update, repo),
       {:ok, connection} <- fetch_connection(repo, connection_id, :update) do
    changeset = @connection_schema.update_changeset(connection, attrs)
    persist_changeset(repo, changeset, :update, :update)
  end
end
```

**Uniform changeset error formatting** ([lib/relyra/ecto/connections.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connections.ex:137)):
```elixir
case result do
  {:ok, record} -> {:ok, repo.preload(record, :certificates)}
  {:error, %Ecto.Changeset{} = invalid_changeset} ->
    {:error, Error.new(:invalid_connection_record, "Connection record failed validation", %{
      operation: operation,
      errors: format_changeset_errors(invalid_changeset)
    })}
end
```

Use this module’s error shape when adding audit writes around create/update/enable/disable.

---

### `lib/relyra/ecto/metadata_apply.ex`

**Analog:** `lib/relyra/ecto/metadata_apply.ex`

Keep the current straight-line transaction shape and insert audit rows inside the same `transact/2` closure. The command already demonstrates the exact insertion point: before fetch normalized current state, after live mutation insert durable ledger row, then normalize transaction return.

**Live aggregate mutation pattern** ([lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:74)):
```elixir
case connection |> Connection.update_changeset(attrs) |> repo.update() do
  {:ok, updated_connection} ->
    case CertificateInventory.stage_metadata_certificates(
           repo,
           repo.preload(updated_connection, :certificates),
           revision,
           candidate
         ) do
      :ok -> {:ok, revision}
      {:error, %Error{} = error} -> rollback(repo, error)
    end
```

This is the audit hardening seam for metadata outcomes.

---

### `lib/relyra/ecto/certificate_inventory.ex`

**Analog:** `lib/relyra/ecto/certificate_inventory.ex`

**Concurrency-safe transition pattern** ([lib/relyra/ecto/certificate_inventory.ex](/Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex:137)):
```elixir
with :ok <- ensure_optional_dependencies(repo, operation) do
  transact(repo, fn ->
    with {:ok, connection} <- fetch_connection(repo, connection_id, operation),
         :ok <- bump_connection_lock(repo, connection, operation),
         {:ok, refreshed_connection} <- fetch_connection(repo, connection_id, operation) do
      do_transition(repo, refreshed_connection, fingerprint, target_state, operation, opts)
    end
  end)
  |> normalize_transaction_result(operation)
end
```

**Optimistic lock pattern** ([lib/relyra/ecto/certificate_inventory.ex](/Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex:243)):
```elixir
changeset =
  connection
  |> Ecto.Changeset.change(updated_at: DateTime.utc_now())
  |> Ecto.Changeset.optimistic_lock(:lock_version)
```

**Conflict typing pattern** ([lib/relyra/ecto/certificate_inventory.ex](/Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex:271)):
```elixir
Error.new(
  :invalid_connection_record,
  "Concurrent certificate transition conflict",
  %{operation: operation, connection_id: connection.connection_id, reason: :conflict}
)
```

Use these patterns if mapping writes need explicit concurrency control beyond plain transaction isolation.

---

### `lib/relyra/ecto/connection_loader.ex`

**Analog:** `lib/relyra/ecto/connection_loader.ex`

**Preload boundary pattern** ([lib/relyra/ecto/connection_loader.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection_loader.ex:55)):
```elixir
case repo.get_by(Connection, connection_id: connection_id) do
  nil -> {:error, Error.new(...)}
  connection -> {:ok, repo.preload(connection, :certificates)}
end
```

Extend this exact preload site to include mappings. Keep runtime-readiness checks here, not in Phoenix/controller edges.

---

### `lib/relyra/ecto/connection_snapshot.ex`

**Analog:** `lib/relyra/ecto/connection_snapshot.ex`

**Single hydration seam pattern** ([lib/relyra/ecto/connection_snapshot.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex:25)):
```elixir
runtime_attrs =
  connection
  |> base_runtime_attrs()
  |> apply_provider_defaults(connection.provider_preset)
  |> Map.put(:idp_certificates, certificates)
  |> Map.put(:cert_chain, certificates)

{:ok, struct(Connection, runtime_attrs)}
```

**Pure runtime attrs pattern** ([lib/relyra/ecto/connection_snapshot.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex:62)):
```elixir
%{
  id: connection.id,
  connection_id: connection.connection_id,
  idp_entity_id: connection.idp_entity_id,
  ...
  provider_preset: connection.provider_preset,
  display_name: connection.display_name,
  organization_id: connection.organization_id
}
```

This is the exact place to normalize attribute/group mappings into plain runtime-safe values before `UserMapper` sees them.

---

### `lib/relyra/connection.ex`

**Analog:** `lib/relyra/connection.ex`

**Runtime value struct pattern** ([lib/relyra/connection.ex](/Users/jon/projects/relyra/lib/relyra/connection.ex:5)):
```elixir
defstruct [
  :id,
  :connection_id,
  :idp_entity_id,
  :sp_entity_id,
  :acs_url,
  :idp_sso_url,
  :idp_certificates,
  :cert_chain,
  ...
]
```

If Phase 11 adds normalized mapping config to runtime state, add it here as plain values only. Do not expose Ecto structs or associations.

---

### `lib/relyra/user_mapper/default_attribute.ex`

**Analog:** `lib/relyra/user_mapper/default_attribute.ex`

**Current default mapping shape** ([lib/relyra/user_mapper/default_attribute.ex](/Users/jon/projects/relyra/lib/relyra/user_mapper/default_attribute.ex:6)):
```elixir
attributes = Map.get(assertion, :attributes) || %{}

user_map = %{
  name_id: Map.get(assertion, :name_id),
  email: get_attribute(attributes, ["email", "mail", "EmailAddress"]),
  first_name: get_attribute(attributes, ["given_name", "givenname", "FirstName"]),
  last_name: get_attribute(attributes, ["family_name", "sn", "LastName"]),
  roles: get_attribute(attributes, ["groups", "roles", "memberOf"]) || []
}
```

Keep the callback contract identical, but replace hardcoded candidate lists with normalized persisted mapping config from the hydrated runtime connection.

---

### Migration files

**Attribute/group live tables analog:** [priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs](/Users/jon/projects/relyra/priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs:4)
```elixir
create table(:relyra_connection_certificates, primary_key: false) do
  add :id, :binary_id, primary_key: true

  add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
    null: false

  ...
  timestamps(type: :utc_datetime_usec)
end

create index(:relyra_connection_certificates, [:connection_record_id])
create unique_index(:relyra_connection_certificates, [:connection_record_id, :fingerprint_sha256])
```

**Append-only ledger analog:** [priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs](/Users/jon/projects/relyra/priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs:4)
```elixir
create table(:relyra_metadata_revisions, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
    null: false
  ...
  timestamps(type: :utc_datetime_usec, updated_at: false)
end

create index(:relyra_metadata_revisions, [:connection_record_id, :inserted_at])
```

Use the certificate table migration for live mapping rows and the metadata revision migration for `mapping_revisions` and `audit_events`.

---

### `test/relyra/ecto/mapping_commands_test.exs`

**Analog:** `test/relyra/ecto/metadata_apply_test.exs`

**Transactional success + runtime assertion pattern** ([test/relyra/ecto/metadata_apply_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/metadata_apply_test.exs:17)):
```elixir
assert {:ok, revision} =
         MetadataApply.apply_revision(connection.connection_id, candidate(), applied_revision_attrs(), repo: @repo)

updated =
  @repo.get_by!(Connection, connection_id: connection.connection_id)
  |> @repo.preload(:certificates)

assert {:ok, resolved} =
         EctoResolver.resolve_connection(%{connection_id: connection.connection_id}, repo: @repo)
```

**Rollback test pattern** ([test/relyra/ecto/metadata_apply_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/metadata_apply_test.exs:64)):
```elixir
assert {:error, %Relyra.Error{type: :invalid_connection_record}} = ...
refute @repo.get_by(MetadataRevision, effective_idp_entity_id: candidate().idp_entity_id)
assert persisted.idp_entity_id == original.idp_entity_id
```

Use the same structure for mapping apply/revision/audit coverage: successful mutation, failed mutation rollback, and resolved runtime snapshot assertions.

---

### `test/relyra/ecto/mapping_revision_schema_test.exs` and `test/relyra/ecto/audit_event_schema_test.exs`

**Analog:** `test/relyra/ecto/metadata_revision_schema_test.exs`

```elixir
changeset = MetadataRevision.changeset(%MetadataRevision{}, %{})
refute changeset.valid?
errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
assert "can't be blank" in errors.connection_record_id
```

Keep these tests minimal and schema-focused.

---

### `test/relyra/ecto/audit_hardening_test.exs`

**Analog:** `test/relyra/ecto/certificate_inventory_concurrency_test.exs`

**Conflict-preservation pattern** ([test/relyra/ecto/certificate_inventory_concurrency_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/certificate_inventory_concurrency_test.exs:23)):
```elixir
conflicting_task = Task.async(fn -> ... end)
assert_receive :stale_fetch_complete, 1_000
assert {:ok, promoted} = ...
send(conflicting_task.pid, :continue_after_fetch)
assert {:error, %Relyra.Error{details: details}} = Task.await(conflicting_task, 1_000)
assert details.reason == :conflict
```

Use this style if audit insertion and mapping writes need concurrency assertions. Also add same-transaction assertions modeled after metadata rollback tests.

---

### `test/relyra/connection_snapshot_test.exs`

**Analog:** `test/relyra/connection_snapshot_test.exs`

**Hydration assertion pattern** ([test/relyra/connection_snapshot_test.exs](/Users/jon/projects/relyra/test/relyra/connection_snapshot_test.exs:7)):
```elixir
aggregate = %Connection{..., certificates: [...]}
assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)
assert snapshot.idp_certificates == snapshot.cert_chain
```

**Fail-closed pattern** ([test/relyra/connection_snapshot_test.exs](/Users/jon/projects/relyra/test/relyra/connection_snapshot_test.exs:87)):
```elixir
assert {:error, %Relyra.Error{type: :connection_invalid, details: details}} =
         ConnectionSnapshot.hydrate(aggregate)

assert details.reason == :missing_certificates
```

Extend this file or mirror it for mapping normalization and fail-closed behavior when persisted mapping rows are malformed.

---

### `test/relyra/ecto/migration_constraints_test.exs`

**Analog:** `test/relyra/ecto/migration_constraints_test.exs`

**Constraint verification pattern** ([test/relyra/ecto/migration_constraints_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/migration_constraints_test.exs:63)):
```elixir
assert {:ok, source} = ...
assert {:error, duplicate_source_changeset} = ...
assert %{connection_record_id: ["has already been taken"]} =
         Ecto.Changeset.traverse_errors(duplicate_source_changeset, fn {message, _opts} -> message end)
```

Use this to assert:
- unique mapping keys per connection
- FK enforcement to `relyra_connections`
- append-only revision/audit ledgers accept inserts and preserve parent references

## Shared Patterns

### Dedicated Child Rows, Not Parent Blob Writes
**Source:** [lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:86)
**Apply to:** `attribute_mapping.ex`, `group_mapping.ex`, `connection.ex`, `mapping_commands.ex`
```elixir
def update_changeset(connection, attrs) do
  connection
  |> cast(attrs, [...])
  |> cast_embed(:runtime_policy, with: &RuntimePolicy.changeset/2)
  |> reject_certificate_updates(attrs)
```

Mirror this pattern for mapping data: add explicit associations on the schema, but reject generic parent updates for mapping rows.

### Same-Transaction Durable Ledger Writes
**Source:** [lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:19)
**Apply to:** `mapping_commands.ex`, `metadata_apply.ex`, `certificate_inventory.ex`, `connections.ex`, `audit_writer.ex`
```elixir
transact(repo, fn ->
  connection = load_connection!(repo, connection_id)
  revision_attrs = revision_attrs_for_apply(connection, candidate, revision_attrs)

  with {:ok, revision} <- insert_revision(repo, revision_attrs) do
    ...
  end
end)
```

### Runtime Snapshot Purity
**Source:** [lib/relyra/ecto/connection_snapshot.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex:25)
**Apply to:** `connection_loader.ex`, `connection_snapshot.ex`, `connection.ex`, `user_mapper/default_attribute.ex`
```elixir
runtime_attrs =
  connection
  |> base_runtime_attrs()
  |> apply_provider_defaults(connection.provider_preset)
  |> Map.put(:idp_certificates, certificates)
  |> Map.put(:cert_chain, certificates)
```

All persisted mapping rows must be collapsed to plain values here before runtime use.

### Bounded Redaction-Safe Payloads
**Source:** [lib/relyra/ecto/metadata_apply.ex](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:290), [lib/relyra/log.ex](/Users/jon/projects/relyra/lib/relyra/log.ex:5)
**Apply to:** `mapping_revision.ex`, `audit_event.ex`, `audit_writer.ex`, audit tests
```elixir
{key, value} when is_binary(value) and byte_size(value) > 256 -> {key, "[REDACTED]"}
```

```elixir
@sensitive_keys [:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state, :private_key, :metadata_xml, :certificate_pem, :pem]
```

### Concurrency Conflict Typing
**Source:** [lib/relyra/ecto/certificate_inventory.ex](/Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex:243)
**Apply to:** `mapping_commands.ex`, `audit_hardening_test.exs`
```elixir
|> Ecto.Changeset.optimistic_lock(:lock_version)
...
Error.new(:invalid_connection_record, "Concurrent certificate transition conflict", %{reason: :conflict})
```

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/relyra/ecto/audit_writer.ex` | service | event-driven | No existing shared cross-domain writer module exists; closest reusable patterns live inside `MetadataApply`. |

## Metadata

**Analog search scope:** `lib/relyra`, `priv/repo/migrations`, `test/relyra`
**Files scanned:** 18
**Pattern extraction date:** 2026-05-05

## PATTERN MAPPING COMPLETE

**Phase:** 11 - Mapping persistence + audit hardening
**Files classified:** 24
**Analogs found:** 19 / 19

### Coverage
- Files with exact analog: 11
- Files with role-match analog: 11
- Files with partial analog: 2

### Key Patterns Identified
- All trust-bearing writes route through explicit Ecto command modules with typed `Relyra.Error` returns.
- Append-only provenance uses dedicated ledgers with `updated_at: false`, bounded maps, and explicit enums.
- Runtime consumers stay persistence-agnostic by hydrating plain values in `ConnectionSnapshot`.
- Redaction and audit payload bounds are enforced in module helpers, not deferred to logs.

### File Created
`/Users/jon/projects/relyra/.planning/phases/11-mapping-persistence-audit-hardening/11-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference concrete analogs and excerpts for schema, migration, command, snapshot, and audit work.
