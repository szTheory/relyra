# Phase 10: Certificate inventory + rollover - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/relyra/ecto/certificate.ex` | model | CRUD | `lib/relyra/ecto/certificate.ex` | exact-self |
| `lib/relyra/ecto/certificate_inventory.ex` | service | CRUD | `lib/relyra/ecto/certificate_inventory.ex` | exact-self |
| `lib/relyra/ecto/connection.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | exact-self |
| `lib/relyra/ecto/metadata_apply.ex` | service | CRUD | `lib/relyra/ecto/metadata_apply.ex` | exact-self |
| `lib/relyra/ecto/connection_loader.ex` | service | request-response | `lib/relyra/ecto/connection_loader.ex` | exact-self |
| `lib/relyra/ecto/connection_snapshot.ex` | service | transform | `lib/relyra/ecto/connection_snapshot.ex` | exact-self |
| `priv/repo/migrations/*_certificate_rollover_*.exs` | migration | CRUD | `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs` | exact |
| `test/relyra/ecto/certificate_schema_test.exs` | test | CRUD | `test/relyra/ecto/certificate_schema_test.exs` | exact-self |
| `test/relyra/ecto/metadata_apply_test.exs` | test | CRUD | `test/relyra/ecto/metadata_apply_test.exs` | exact-self |
| `test/relyra/connection_snapshot_test.exs` | test | transform | `test/relyra/connection_snapshot_test.exs` | exact-self |
| `test/relyra/ecto/ecto_connection_resolver_test.exs` | test | request-response | `test/relyra/ecto/ecto_connection_resolver_test.exs` | exact-self |
| `test/relyra/ecto/migration_constraints_test.exs` | test | CRUD | `test/relyra/ecto/migration_constraints_test.exs` | exact-self |

## Existing Primitive Coverage

Phase 10 is not starting from zero. The repo already contains the main rollover primitives:

- `lib/relyra/ecto/certificate.ex:21-27` already persists `role`, `lifecycle_state`, `staged_at`, `activated_at`, and `retired_at`.
- `lib/relyra/ecto/certificate_inventory.ex:9-43`, `70-117`, `235-247` already stages metadata certificates and exposes activate, retire, and rollback operations.
- `lib/relyra/ecto/metadata_apply.ex:74-89` already stages metadata-derived certificates instead of replacing the association wholesale.
- `lib/relyra/ecto/connection_snapshot.ex:94-111` already filters runtime trust material down to active signing certificates only.
- `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs:5-17` already adds the first lifecycle columns.

Planner note: scope follow-on work as refinement of lifecycle semantics, trust-window rules, and coverage gaps. Do not plan a greenfield rollover subsystem unless Phase 10 explicitly chooses to replace these primitives.

## Pattern Assignments

### `lib/relyra/ecto/certificate.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/certificate.ex`

**Schema pattern** (`lib/relyra/ecto/certificate.ex:17-30`):
```elixir
schema "relyra_connection_certificates" do
  field :fingerprint_sha256, :string
  field :pem, :string
  field :source, :string
  field :role, Ecto.Enum, values: @roles, default: :signing
  field :lifecycle_state, Ecto.Enum, values: @lifecycle_states, default: :active
  field :not_before, :utc_datetime_usec
  field :not_after, :utc_datetime_usec
  field :staged_at, :utc_datetime_usec
  field :activated_at, :utc_datetime_usec
  field :retired_at, :utc_datetime_usec
```

**Changeset/defaulting pattern** (`lib/relyra/ecto/certificate.ex:41-60`):
```elixir
certificate
|> cast(attrs, [..., :role, :lifecycle_state, :not_before, :not_after, :staged_at, :activated_at, :retired_at, :metadata])
|> validate_required([:fingerprint_sha256, :pem, :source])
|> put_defaults()
|> validate_timestamp_consistency()
|> unique_constraint(:fingerprint_sha256, name: ...)
|> foreign_key_constraint(:connection_record_id)
```

**Lifecycle timestamp pattern** (`lib/relyra/ecto/certificate.ex:66-77`):
```elixir
changeset
|> put_change_unless_present(:role, :signing)
|> put_change_unless_present(:lifecycle_state, :active)
|> put_default_timestamp(:activated_at, :lifecycle_state, :active)
|> put_default_timestamp(:staged_at, :lifecycle_state, :next)
|> clear_timestamp_when_not_state(:staged_at, :lifecycle_state, :next)
|> clear_timestamp_when_not_state(:activated_at, :lifecycle_state, :active)
|> clear_timestamp_when_not_state(:retired_at, :lifecycle_state, :retired)
```

Planner note: extend this file only if Phase 10 needs tighter timestamp/window invariants or new bounded lifecycle enums. The current shape already covers the basic active/next/retired model.

---

### `lib/relyra/ecto/certificate_inventory.ex` (service, CRUD)

**Analog:** `lib/relyra/ecto/certificate_inventory.ex`

**Public API and typed tuple posture** (`lib/relyra/ecto/certificate_inventory.ex:9-31`, `34-49`, `70-117`):
```elixir
@spec stage_metadata_certificates(module(), struct(), struct(), map()) ::
        :ok | {:error, Error.t()}

@spec activate_signing_certificate(module(), binary(), binary(), keyword()) ::
        {:ok, Certificate.t()} | {:error, Error.t()}

@spec rollback_signing_certificate(module(), binary(), binary(), binary(), keyword()) ::
        {:ok, [Certificate.t()]} | {:error, Error.t()}
```

**Transition orchestration pattern** (`lib/relyra/ecto/certificate_inventory.ex:132-174`):
```elixir
with :ok <- ensure_optional_dependencies(repo, operation),
     {:ok, connection} <- fetch_connection(repo, connection_id, operation) do
  transact(repo, fn ->
    do_transition(repo, connection, fingerprint, target_state, operation, opts)
  end)
  |> normalize_transaction_result(operation)
end
```

**Staging pattern** (`lib/relyra/ecto/certificate_inventory.ex:214-247`):
```elixir
existing =
  Enum.find(
    connection.certificates,
    &(&1.fingerprint_sha256 == attrs.fingerprint_sha256 and &1.role == :signing)
  )

candidate
|> Map.get(:certificate_pems, [])
|> Enum.zip(Map.get(candidate, :certificate_fingerprints, []))
|> Enum.map(fn {pem, fingerprint} ->
  %{
    fingerprint_sha256: fingerprint,
    pem: pem,
    source: "metadata_revision:#{revision.id}",
    role: :signing,
    lifecycle_state: :next,
    staged_at: DateTime.utc_now(),
    metadata: %{metadata_revision_id: revision.id}
  }
end)
```

**Guardrail pattern** (`lib/relyra/ecto/certificate_inventory.ex:192-210`):
```elixir
if certificate.lifecycle_state == :active and length(active_signing_certs) == 1 do
  {:error,
   Error.new(
     :invalid_connection_record,
     "Cannot retire the last active signing certificate",
     %{reason: :last_active_certificate, ...}
   )}
else
  :ok
end
```

Planner note: this file is the current home for promotion/retirement/rollback semantics. Prefer evolving these helpers over introducing a parallel rollover service unless Phase 10 deliberately splits responsibilities.

---

### `lib/relyra/ecto/connection.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/connection.ex`

**Association pattern to preserve** (`lib/relyra/ecto/connection.ex:35-43`):
```elixir
embeds_one :runtime_policy, RuntimePolicy, on_replace: :update
has_many :certificates, Certificate, foreign_key: :connection_record_id, on_replace: :delete
```

**Runtime readiness pattern** (`lib/relyra/ecto/connection.ex:120-163`):
```elixir
cond do
  connection.status != :enabled -> {:error, Error.new(...)}
  missing_fields != [] -> {:error, Error.new(...)}
  active_signing_certificates(connection) == [] -> {:error, Error.new(...)}
  Enum.any?(active_signing_certificates(connection), &invalid_certificate?/1) ->
    {:error, Error.new(...)}
  true -> :ok
end
```

**Active trust-set filter** (`lib/relyra/ecto/connection.ex:58`, `228-234`):
```elixir
@active_signing_cert_filters [role: :signing, lifecycle_state: :active]

connection
|> Map.get(:certificates, [])
|> Enum.filter(fn certificate ->
  Enum.all?(@active_signing_cert_filters, fn {field, value} ->
    Map.get(certificate, field, value) == value
  end)
end)
```

Planner note: `on_replace: :delete` is still present on the association, but runtime readiness already assumes explicit active-signing semantics. If Phase 10 needs to fully eliminate replace-in-place trust updates, this file is one of the places to harden.

---

### `lib/relyra/ecto/metadata_apply.ex` (service, CRUD)

**Analog:** `lib/relyra/ecto/metadata_apply.ex`

**Transactional apply pattern** (`lib/relyra/ecto/metadata_apply.ex:13-33`):
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

**Apply-with-staging pattern** (`lib/relyra/ecto/metadata_apply.ex:74-89`):
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

**Revision provenance pattern** (`lib/relyra/ecto/metadata_apply.ex:115-137`):
```elixir
revision_attrs
|> Map.put(:connection_record_id, connection.id)
|> Map.put_new(:outcome, :applied)
|> Map.put_new(:effective_idp_entity_id, Map.get(candidate, :idp_entity_id))
|> Map.put_new(:effective_idp_sso_url, Map.get(candidate, :idp_sso_url))
|> Map.put_new(:certificate_fingerprints, Map.get(candidate, :certificate_fingerprints, []))
|> Map.put_new(:trust_summary, default_trust_summary(candidate))
```

Planner note: keep metadata revisions as provenance only. Phase 10 changes here should continue to update aggregate pointers and staged inventory rows without turning revisions into live rollover state.

---

### `lib/relyra/ecto/connection_loader.ex` (service, request-response)

**Analog:** `lib/relyra/ecto/connection_loader.ex`

**Repo gating and preload pattern** (`lib/relyra/ecto/connection_loader.ex:10-16`, `36-70`):
```elixir
with :ok <- ensure_optional_dependencies(repo, operation),
     {:ok, connection} <- load_connection(repo, connection_id, operation),
     :ok <- ensure_runtime_ready(connection, operation) do
  {:ok, connection}
end

...

{:ok, repo.preload(connection, :certificates)}
```

**Readiness reclassification pattern** (`lib/relyra/ecto/connection_loader.ex:88-145`):
```elixir
case Connection.runtime_ready(connection) do
  :ok -> :ok
  {:error, %Error{} = error} ->
    {:error, classify_runtime_readiness(error, connection, operation)}
end
```

Planner note: use this file for persistence-side fail-closed behavior and error typing. If rollover adds new invalid states, classify them here rather than leaking raw changeset or repo failures outward.

---

### `lib/relyra/ecto/connection_snapshot.ex` (service, transform)

**Analog:** `lib/relyra/ecto/connection_snapshot.ex`

**Hydration seam pattern** (`lib/relyra/ecto/connection_snapshot.ex:9-31`):
```elixir
certificates = certificate_pems(connection)

if certificates == [] do
  {:error, Error.new(:connection_invalid, "Persisted connection has no trusted certificates to hydrate", ...)}
else
  runtime_attrs =
    connection
    |> base_runtime_attrs()
    |> apply_provider_defaults(connection.provider_preset)
    |> Map.put(:idp_certificates, certificates)
    |> Map.put(:cert_chain, certificates)
```

**Trust-set selection pattern** (`lib/relyra/ecto/connection_snapshot.ex:94-111`):
```elixir
connection
|> Map.get(:certificates, [])
|> Enum.filter(&active_signing_certificate?/1)
|> Enum.sort_by(fn certificate ->
  {
    datetime_sort_value(Map.get(certificate, :activated_at) || Map.get(certificate, :inserted_at)),
    datetime_sort_value(Map.get(certificate, :inserted_at))
  }
end)
|> Enum.map(&Map.get(&1, :pem))
|> Enum.reject(&(&1 in [nil, ""]))
```

Planner note: this is the canonical persistence-to-runtime seam for D-07 through D-09. Prefer tightening the explicit trust-window rule here instead of teaching runtime modules to inspect Ecto rows directly.

---

### `priv/repo/migrations/*_certificate_rollover_*.exs` (migration, CRUD)

**Analog:** `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`

**Lifecycle column pattern** (`priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs:5-10`):
```elixir
alter table(:relyra_connection_certificates) do
  add :role, :string, null: false, default: "signing"
  add :lifecycle_state, :string, null: false, default: "active"
  add :staged_at, :utc_datetime_usec
  add :activated_at, :utc_datetime_usec
  add :retired_at, :utc_datetime_usec
end
```

**Backfill pattern** (`priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs:12-17`):
```elixir
execute("""
UPDATE relyra_connection_certificates
SET activated_at = COALESCE(activated_at, inserted_at)
WHERE lifecycle_state = 'active'
""")
```

Planner note: add another migration only if Phase 10 decides it needs extra window columns, constraints, or backfills beyond the current lifecycle fields. The base inventory table and first lifecycle migration already exist.

---

### `test/relyra/ecto/certificate_schema_test.exs` (test, CRUD)

**Analog:** `test/relyra/ecto/certificate_schema_test.exs`

**Schema default assertion pattern** (`test/relyra/ecto/certificate_schema_test.exs:18-29`):
```elixir
changeset =
  Certificate.changeset(%Certificate{}, %{
    fingerprint_sha256: "abc123",
    pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
    source: "manual"
  })

certificate = Ecto.Changeset.apply_changes(changeset)
assert certificate.role == :signing
assert certificate.lifecycle_state == :active
```

Planner note: extend this test if Phase 10 adds stricter timestamp/window validation or additional lifecycle states.

---

### `test/relyra/ecto/metadata_apply_test.exs` (test, CRUD)

**Analog:** `test/relyra/ecto/metadata_apply_test.exs`

**Stage-without-runtime-cutover pattern** (`test/relyra/ecto/metadata_apply_test.exs:16-63`):
```elixir
assert Enum.any?(
         updated.certificates,
         &(&1.fingerprint_sha256 == "fp-old" and &1.lifecycle_state == :active)
       )

assert Enum.all?(
         Enum.filter(updated.certificates, &(&1.fingerprint_sha256 in ["fp-new-1", "fp-new-2"])),
         fn cert ->
           cert.lifecycle_state == :next and
             String.starts_with?(cert.source, "metadata_revision:")
         end
       )

assert resolved.idp_certificates == [
         "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
       ]
```

**Explicit overlap/retirement pattern** (`test/relyra/ecto/metadata_apply_test.exs:141-184`):
```elixir
assert {:ok, _cert} =
         CertificateInventory.activate_signing_certificate(@repo, connection.connection_id, "fp-new-1")

assert resolved_with_overlap.idp_certificates == [
         "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
         "-----BEGIN CERTIFICATE-----\nNEW1\n-----END CERTIFICATE-----"
       ]
```

Planner note: this is the strongest end-to-end analog for Phase 10 acceptance tests. Keep the assertions operator-visible: persisted row states plus runtime trust material.

---

### `test/relyra/connection_snapshot_test.exs` (test, transform)

**Analog:** `test/relyra/connection_snapshot_test.exs`

**Runtime filter assertion pattern** (`test/relyra/connection_snapshot_test.exs:46-82`):
```elixir
assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)

assert snapshot.idp_certificates == [
         "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----"
       ]
```

**Fail-closed pattern** (`test/relyra/connection_snapshot_test.exs:87-102`):
```elixir
assert {:error, %Relyra.Error{type: :connection_invalid, details: details}} =
         ConnectionSnapshot.hydrate(aggregate)

assert details.reason == :missing_certificates
```

Planner note: extend here for any more explicit overlap-window ordering or trust-set selection semantics.

---

### `test/relyra/ecto/ecto_connection_resolver_test.exs` (test, request-response)

**Analog:** `test/relyra/ecto/ecto_connection_resolver_test.exs`

**Resolver/runtime seam pattern** (`test/relyra/ecto/ecto_connection_resolver_test.exs:40-58`):
```elixir
insert_certificate!(connection.id, %{fingerprint_sha256: "active"})
insert_certificate!(connection.id, %{fingerprint_sha256: "next", lifecycle_state: :next})

assert {:ok, resolved} =
         EctoResolver.resolve_connection(%{connection_id: connection.connection_id}, repo: @repo)

assert resolved.idp_certificates == [
         "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
       ]
```

**Rollback coverage pattern** (`test/relyra/ecto/ecto_connection_resolver_test.exs:159-214`):
```elixir
assert {:ok, _} =
         CertificateInventory.rollback_signing_certificate(
           @repo,
           connection.connection_id,
           "active-a",
           "next-b"
         )

assert resolved_after_rollback.idp_certificates == [
         "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
       ]
```

Planner note: use this file when Phase 10 needs resolver-level confirmation that persistence changes still yield the same pure runtime contract.

---

### `test/relyra/ecto/migration_constraints_test.exs` (test, CRUD)

**Analog:** `test/relyra/ecto/migration_constraints_test.exs`

**Constraint and default assertion pattern** (`test/relyra/ecto/migration_constraints_test.exs:23-60`):
```elixir
assert Enum.all?(
         connection.certificates,
         &(&1.role == :signing and &1.lifecycle_state == :active)
       )

assert {:ok, _deleted} = Repo.delete(connection)
assert Repo.aggregate(Certificate, :count, :id) == 0
```

Planner note: add new migration assertions here if Phase 10 introduces DB-level lifecycle constraints or backfill expectations.

## Shared Patterns

### Typed Repo/Dependency Guards
**Sources:** `lib/relyra/ecto/metadata_apply.ex:149-178`, `lib/relyra/ecto/connection_loader.ex:36-52`, `lib/relyra/connection_resolver/ecto.ex:51-64`
**Apply to:** All new or modified persistence-facing services
```elixir
case Keyword.fetch(opts, :repo) do
  {:ok, repo} when is_atom(repo) -> {:ok, repo}
  _ -> {:error, Error.new(...)}
end

cond do
  not Code.ensure_loaded?(Ecto.Repo) -> {:error, ...}
  true -> :ok
end
```

### Transaction + Rollback Normalization
**Sources:** `lib/relyra/ecto/metadata_apply.ex:13-33`, `226-257`; `lib/relyra/ecto/certificate_inventory.ex:132-174`, `335-357`
**Apply to:** All rollover promotion, retirement, rollback, or metadata-apply writes
```elixir
transact(repo, fn ->
  ...
end)
|> normalize_transaction_result(operation)
```

### Active Trust Set Only
**Sources:** `lib/relyra/ecto/connection.ex:58`, `228-234`; `lib/relyra/ecto/connection_snapshot.ex:94-111`
**Apply to:** Connection readiness checks and runtime hydration
```elixir
@active_signing_cert_filters [role: :signing, lifecycle_state: :active]

|> Enum.filter(&active_signing_certificate?/1)
```

### Provenance Stays In Revisions, Live State Stays In Inventory
**Sources:** `lib/relyra/ecto/metadata_apply.ex:115-137`; `lib/relyra/ecto/certificate_inventory.ex:235-247`
**Apply to:** Any Phase 10 updates that connect metadata refreshes to rollover state
```elixir
source: "metadata_revision:#{revision.id}",
metadata: %{metadata_revision_id: revision.id}
```

## No Analog Found

None. Every likely Phase 10 target already has a close in-repo analog, and several of the main rollover primitives already exist in the exact files Phase 10 is likely to modify.

## Metadata

**Analog search scope:** `.planning/phases/10-certificate-inventory-rollover`, `lib/relyra`, `test/relyra`, `priv/repo/migrations`
**Files scanned:** 17
**Pattern extraction date:** 2026-05-05
