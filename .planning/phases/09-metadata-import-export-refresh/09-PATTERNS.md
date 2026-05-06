# Phase 09: Metadata import/export + refresh - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/relyra/metadata.ex` | service | request-response | `lib/relyra/ecto/connections.ex` | exact |
| `lib/relyra/metadata/parser.ex` | utility | transform | `lib/relyra/security/xml/pure_beam.ex` | role-match |
| `lib/relyra/metadata/candidate.ex` | model | transform | `lib/relyra/connection.ex` | role-match |
| `lib/relyra/metadata/import.ex` | service | request-response | `lib/relyra/ecto/connections.ex` | exact |
| `lib/relyra/metadata/refresh.ex` | service | file-I/O | `lib/relyra/request_store/ecto.ex` | partial |
| `lib/relyra/metadata/source_registry.ex` | service | CRUD | `lib/relyra/ecto/connections.ex` | exact |
| `lib/relyra/ecto/metadata_revision.ex` | model | CRUD | `lib/relyra/ecto/certificate.ex` | exact |
| `lib/relyra/ecto/metadata_source.ex` | model | CRUD | `lib/relyra/ecto/certificate.ex` | exact |
| `lib/relyra/ecto/metadata_apply.ex` | service | CRUD | `lib/relyra/ecto/connections.ex` | exact |
| `mix.exs` | dependency manifest | build-time | `mix.exs` | exact |
| `lib/relyra/ecto/connection.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | exact |
| `lib/relyra/log.ex` | utility | event-driven | `lib/relyra/log.ex` | exact |
| `lib/relyra/telemetry.ex` | utility | event-driven | `lib/relyra/telemetry.ex` | exact |
| `priv/repo/migrations/*_add_metadata_pointers_to_relyra_connections.exs` | migration | CRUD | `priv/repo/migrations/20260505120000_create_relyra_connections.exs` | exact |
| `priv/repo/migrations/*_create_relyra_metadata_sources.exs` | migration | CRUD | `priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs` | exact |
| `priv/repo/migrations/*_create_relyra_metadata_revisions.exs` | migration | CRUD | `priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs` | exact |
| `test/relyra/metadata_test.exs` | test | request-response | `test/relyra/ecto/connection_record_test.exs` | exact |
| `test/relyra/ecto/metadata_apply_test.exs` | test | CRUD | `test/relyra/ecto/ecto_connection_resolver_test.exs` | partial |
| `test/relyra/metadata_refresh_test.exs` | test | file-I/O | `test/relyra/ecto/ecto_connection_resolver_test.exs` | partial |
| `test/relyra/ecto/metadata_revision_schema_test.exs` | test | CRUD | `test/relyra/ecto/certificate_schema_test.exs` | exact |
| `test/relyra/ecto/metadata_source_schema_test.exs` | test | CRUD | `test/relyra/ecto/certificate_schema_test.exs` | exact |
| `test/relyra/ecto/migration_constraints_test.exs` | test | CRUD | `test/relyra/ecto/migration_constraints_test.exs` | exact |
| `test/relyra/telemetry_test.exs` | test | event-driven | `test/relyra/telemetry_test.exs` | exact |
| `test/phoenix/metadata_controller_test.exs` | test | request-response | `test/phoenix/metadata_controller_test.exs` | exact |

## Pattern Assignments

### `lib/relyra/metadata.ex` (service, request-response)

**Analog:** `lib/relyra/ecto/connections.ex`

**Imports and alias posture** (`lib/relyra/ecto/connections.ex:1-7`):
```elixir
defmodule Relyra.Ecto.Connections do
  @moduledoc false

  alias Relyra.Error

  @ecto_repo Ecto.Repo
  @connection_schema Relyra.Ecto.Connection
```

**Public API with typed tuples and `with` flow** (`lib/relyra/ecto/connections.ex:9-17`):
```elixir
@spec create(map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
def create(attrs, opts \\ [])

def create(attrs, opts) when is_map(attrs) and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts, :create),
       :ok <- ensure_optional_dependency!(:create, repo) do
    changeset = @connection_schema.draft_changeset(struct(@connection_schema), attrs)
    persist_changeset(repo, changeset, :insert, :create)
  end
end
```

**Invalid input error pattern** (`lib/relyra/ecto/connections.ex:20-27`):
```elixir
{:error,
 Error.new(
   :invalid_connection_record,
   "Connection attrs must be a map",
   error_details(opts, :create, :invalid_input)
 )}
```

Planner note: keep `import_xml/3`, `register_source/3`, and `refresh/2` in this tuple-first style. Do not raise for operator-facing failures.

### `lib/relyra/metadata/parser.ex` (utility, transform)

**Analog:** `lib/relyra/security/xml/pure_beam.ex`

**Guarded parser entrypoint** (`lib/relyra/security/xml/pure_beam.ex:11-35`):
```elixir
@impl true
def parse_safely(xml, opts \\ [])

def parse_safely(xml, opts) when is_binary(xml) do
  max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

  cond do
    byte_size(xml) > max_bytes -> {:error, Error.new(:payload_too_large, ...)}
    String.contains?(xml, "<!DOCTYPE") -> {:error, Error.new(:doctype_forbidden, ...)}
    String.contains?(xml, "<!ENTITY") -> {:error, Error.new(:entity_expansion_forbidden, ...)}
    true -> parse_xml(xml)
  end
end
```

**Structured field extraction and typed error return** (`lib/relyra/security/xml/pure_beam.ex:84-99`, `175-190`):
```elixir
fields = %{
  issuer: first_tag_text(xml, "Issuer"),
  status: first_attribute(xml, "StatusCode", "Value"),
  destination: first_attribute(xml, "Response", "Destination"),
  in_response_to: first_attribute(xml, "Response", "InResponseTo")
}

require_present_fields(fields, [:issuer, :status, :destination, :in_response_to], ...)
```

Planner note: do not reuse the response-root check from `:57-58`; Phase 09 needs a metadata-specific parser with the same fail-closed shape but different root expectations.

### `lib/relyra/metadata/candidate.ex` (model, transform)

**Analog:** `lib/relyra/connection.ex`

**Value-struct pattern** (`lib/relyra/connection.ex:1-25`):
```elixir
defmodule Relyra.Connection do
  @moduledoc """
  Value struct representing the resolved trust relationship for a SAML connection.
  """
  defstruct [:id, :connection_id, :idp_entity_id, :sp_entity_id, :acs_url, ...]
```

**Typed struct contract** (`lib/relyra/connection.ex:25-43`):
```elixir
@type t :: %__MODULE__{
        id: binary(),
        connection_id: binary(),
        idp_entity_id: binary(),
        sp_entity_id: binary(),
        ...
      }
```

Planner note: make the metadata candidate a pure struct with normalized fields and certificate summaries. Keep Ecto concerns out of it.

### `lib/relyra/metadata/refresh.ex` (service, file-I/O)

**Analog:** `lib/relyra/request_store/ecto.ex`

**Optional-dependency gate** (`lib/relyra/request_store/ecto.ex:288-299`):
```elixir
defp ensure_optional_dependency!(operation, repo, table) do
  if Code.ensure_loaded?(@ecto_repo) do
    :ok
  else
    {:error,
     Error.new(
       :optional_dependency_missing,
       "Ecto.Repo is unavailable; add optional Ecto dependencies before using this adapter",
       repo_details(repo, table, operation, :ecto_repo_unavailable)
     )}
  end
end
```

**Fetch required option pattern** (`lib/relyra/request_store/ecto.ex:255-267`):
```elixir
case Keyword.fetch(opts, :repo) do
  {:ok, repo} when is_atom(repo) -> {:ok, repo}
  _ -> {:error, Error.new(...)}
end
```

**Typed repo/access failure reporting** (`lib/relyra/ecto/connection_loader.ex:72-85`):
```elixir
rescue
  exception ->
    {:error,
     Error.new(
       :resolver_misconfigured,
       "Persisted connection repo access failed",
       %{failure: Exception.message(exception)}
     )}
```

Planner note: mirror this explicit option validation for `Req` config and remote source lookup. There is no in-repo HTTP analog yet; use the same tuple/error discipline around fetch failures.

### `lib/relyra/metadata/import.ex` and `lib/relyra/metadata/source_registry.ex` (service, CRUD/request-response)

**Analog:** `lib/relyra/ecto/connections.ex`

**Write-path orchestration** (`lib/relyra/ecto/connections.ex:29-39`):
```elixir
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

**Changeset error normalization** (`lib/relyra/ecto/connections.ex:137-167`):
```elixir
{:error, %Ecto.Changeset{} = invalid_changeset} ->
  {:error,
   Error.new(
     :invalid_connection_record,
     "Connection record failed validation",
     %{operation: operation, errors: format_changeset_errors(invalid_changeset)}
   )}
```

Planner note: `import.ex` and `source_registry.ex` should preserve this tuple-first public shape even when they delegate to parser or persistence helpers; use the same repo-option validation and changeset-error normalization posture.

### `lib/relyra/ecto/metadata_revision.ex` and `lib/relyra/ecto/metadata_source.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/certificate.ex`

**Schema and association pattern** (`lib/relyra/ecto/certificate.ex:14-28`):
```elixir
schema "relyra_connection_certificates" do
  field :fingerprint_sha256, :string
  field :pem, :string
  field :source, :string
  field :not_before, :utc_datetime_usec
  field :not_after, :utc_datetime_usec
  field :metadata, :map, default: %{}

  belongs_to :connection, Connection,
    foreign_key: :connection_record_id,
    references: :id,
    type: :binary_id

  timestamps(type: :utc_datetime_usec)
end
```

**Changeset validation pattern** (`lib/relyra/ecto/certificate.ex:32-49`):
```elixir
def changeset(certificate, attrs) do
  certificate
  |> cast(attrs, [:connection_record_id, :fingerprint_sha256, :pem, :source, ...])
  |> validate_required([:fingerprint_sha256, :pem, :source])
  |> unique_constraint(:fingerprint_sha256, name: ...)
  |> foreign_key_constraint(:connection_record_id)
end
```

Planner note: `metadata_revision` should stay append-only via changeset/API choices; `metadata_source` should use the same association and constraint patterns for `connection_record_id`.

### `lib/relyra/ecto/metadata_apply.ex` (service, CRUD)

**Analog:** `lib/relyra/ecto/connections.ex`

**Repo/module guards** (`lib/relyra/ecto/connections.ex:93-119`):
```elixir
defp fetch_repo(opts, operation) when is_list(opts) do
  case Keyword.fetch(opts, :repo) do
    {:ok, repo} when is_atom(repo) -> {:ok, repo}
    _ -> {:error, Error.new(:adapter_not_configured, ...)}
  end
end
```

**Record fetch with preload** (`lib/relyra/ecto/connections.ex:121-135`):
```elixir
case repo.get_by(@connection_schema, connection_id: connection_id)
     |> repo.preload(:certificates) do
  nil -> {:error, Error.new(:connection_not_found, ...)}
  connection -> {:ok, connection}
end
```

Planner note: if `metadata_apply` owns transaction helpers, keep them below a thin public API and preload the live aggregate before computing certificate deltas.

### `mix.exs` (dependency manifest, build-time)

**Analog:** `mix.exs`

**Optional dependency declaration pattern** (`mix.exs`):
```elixir
defp deps do
  [
    {:ecto, "~> 3.13", optional: true},
    {:ecto_sql, "~> 3.13", optional: true}
  ]
end
```

Planner note: when `Req` is added for Phase 09 refresh work, follow the repo's existing dependency-manifest posture directly in `mix.exs`: explicit tuple entry, minimal scope, and optional-by-default so local XML import remains usable without HTTP support.

### `lib/relyra/log.ex` and `lib/relyra/telemetry.ex` (utility, event-driven)

**Analogs:** `lib/relyra/log.ex`, `lib/relyra/telemetry.ex`

Planner note: keep Phase 09 observability on the repo's existing exact-analog posture: summary-only structured metadata, sensitive-key redaction, and event emission through the current `[:relyra, :saml, ...]` namespace helpers.

### `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/metadata_refresh_test.exs`, and `test/relyra/telemetry_test.exs`

**Analogs:** `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/telemetry_test.exs`

Planner note: use the persisted-resolver test style for transactional state-change assertions and the existing telemetry test style for emitted event shape and redaction coverage. Keep refresh tests deterministic with stubs, never live HTTP.

### `lib/relyra/ecto/connection.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/connection.ex`

**Field and embed layout** (`lib/relyra/ecto/connection.ex:20-36`):
```elixir
schema "relyra_connections" do
  field :connection_id, :string
  field :display_name, :string
  field :organization_id, :string
  field :status, Ecto.Enum, values: [:draft, :enabled, :disabled], default: :draft
  ...
  embeds_one :runtime_policy, RuntimePolicy, on_replace: :update
  has_many :certificates, Certificate, foreign_key: :connection_record_id, on_replace: :delete
  timestamps(type: :utc_datetime_usec)
end
```

**Draft vs update changeset split** (`lib/relyra/ecto/connection.ex:48-89`):
```elixir
def draft_changeset(connection, attrs) do
  connection
  |> cast(attrs, [...])
  |> cast_embed(:runtime_policy, with: &RuntimePolicy.changeset/2)
  |> cast_assoc(:certificates, with: &Certificate.changeset/2)
  |> put_generated_connection_id()
  |> put_default_status()
  |> validate_format(:connection_id, @ulid_pattern)
end
```

Planner note: add `active_metadata_revision_id` and `last_known_good_metadata_revision_id` in the same schema/changeset style. Keep runtime-readiness focused on live trust state, not revision history.

### `lib/relyra/telemetry.ex` (utility, event-driven)

**Analog:** `lib/relyra/telemetry.ex`

**Namespace and execute helper** (`lib/relyra/telemetry.ex:1-7`, `60-63`):
```elixir
Relyra emits events using the `[:relyra, :saml, event_name, stage]` namespace.

def execute(event, measurements, metadata \\ %{}) do
  :telemetry.execute([:relyra, :saml | List.wrap(event)], measurements, metadata)
end
```

**Span wrapper pattern** (`lib/relyra/telemetry.ex:66-121`):
```elixir
def span(event, metadata, span_fun) do
  event_name = [:relyra, :saml | List.wrap(event)]
  ...
  emit(event_name ++ [:start], %{system_time: System.system_time()}, start_metadata)
  ...
  emit(event_name ++ [:stop], %{duration_ms: duration_ms(start_time)}, ...)
```

Planner note: add metadata lifecycle events here rather than inventing a second telemetry helper. Keep metadata redacted and summary-only.

### Migration files (migration, CRUD)

**Analogs:** current connection and certificate migrations

**Create-table style** (`priv/repo/migrations/20260505120000_create_relyra_connections.exs:1-24`):
```elixir
defmodule Relyra.Repo.Migrations.CreateRelyraConnections do
  use Ecto.Migration

  def change do
    create table(:relyra_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      ...
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:relyra_connections, [:connection_id])
  end
end
```

**Foreign key plus unique index style** (`priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs:5-27`):
```elixir
create table(:relyra_connection_certificates, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
    null: false
  ...
end

create index(:relyra_connection_certificates, [:connection_record_id])
create unique_index(:relyra_connection_certificates, [:connection_record_id, :fingerprint_sha256])
```

Planner note: use one migration to alter `relyra_connections` pointer columns and separate create-table migrations for `relyra_metadata_sources` and `relyra_metadata_revisions`.

### Test files

**Service API test pattern** for `test/relyra/metadata_test.exs` (`test/relyra/ecto/connection_record_test.exs:1-54`):
```elixir
defmodule Relyra.Ecto.ConnectionRecordTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.Connections
  @repo Relyra.TestSupport.EctoTestRepo

  test "create, update, enable, and disable records through the persistence API" do
    assert {:ok, created} = Connections.create(%{...}, repo: @repo)
    ...
  end
end
```

**Parser unit test pattern** for `test/relyra/metadata/parser_test.exs` (`test/security/xml/error_atoms_test.exs:1-18`):
```elixir
defmodule Relyra.Security.XML.ErrorAtomsTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam

  test "malformed XML consistently maps to :malformed_xml" do
    assert {:error, %Error{type: type}} = PureBeam.parse_safely("<root>")
  end
end
```

**Resolver-style integration test pattern** for `test/relyra/metadata/refresh_test.exs` (`test/relyra/ecto/ecto_connection_resolver_test.exs:11-45`):
```elixir
test "resolver returns a pure runtime snapshot for enabled persisted connections" do
  connection = insert_connection!(%{...})
  insert_certificate!(connection.id)

  assert {:ok, %Connection{} = resolved} =
           EctoResolver.resolve_connection(%{connection_id: connection.connection_id}, repo: @repo)
end
```

**Schema test pattern** for `test/relyra/ecto/metadata_revision_schema_test.exs` and `test/relyra/ecto/metadata_source_schema_test.exs` (`test/relyra/ecto/certificate_schema_test.exs:1-17`):
```elixir
defmodule Relyra.Ecto.CertificateSchemaTest do
  use ExUnit.Case, async: true

  test "certificate changeset requires fingerprint, pem, and source" do
    changeset = Certificate.changeset(%Certificate{}, %{})
    refute changeset.valid?
  end
end
```

**Migration constraint test pattern** for `test/relyra/ecto/migration_constraints_test.exs` (`test/relyra/ecto/migration_constraints_test.exs:7-57`):
```elixir
test "certificate rows enforce foreign keys and cascade on parent delete" do
  {:ok, connection} = ... |> Repo.insert()
  assert {:error, changeset} = ... |> Repo.insert()
  assert {:ok, _deleted} = Repo.delete(connection)
end
```

**Controller regression test pattern** for `test/phoenix/metadata_controller_test.exs` (`test/phoenix/metadata_controller_test.exs:19-41`):
```elixir
test "GET /:connection_id/metadata renders metadata from the canonical resolver snapshot" do
  conn = Phoenix.ConnTest.build_conn() |> get("/valid/metadata")
  assert conn.status == 200
end
```

## Shared Patterns

### Stable typed errors
**Source:** `lib/relyra/error.ex`
**Apply to:** All metadata services, parser modules, and tests
```elixir
@enforce_keys [:type, :message]
defstruct [:type, :message, details: %{}]

@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

### Redacted logging
**Source:** `lib/relyra/log.ex`
**Apply to:** Import, register-source, and refresh telemetry/logging
```elixir
@sensitive_keys [:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state, :private_key]

defp redact_value(key, _value) when key in @sensitive_keys do
  "[REDACTED]"
end
```

### Runtime boundary must stay snapshot-only
**Source:** `lib/relyra/phoenix/controllers/metadata_controller.ex`, `lib/relyra/connection_resolver/ecto.ex`, `lib/relyra/ecto/connection_snapshot.ex`
**Apply to:** Export regression checks and any metadata apply code
```elixir
case Relyra.ConnectionResolver.resolve_connection(request_context, opts) do
  {:ok, connection} ->
    xml = Relyra.Protocol.Metadata.build_sp_metadata(connection, opts)
```

```elixir
with {:ok, aggregate} <- ConnectionLoader.fetch(repo, connection_id, operation: :resolve_connection),
     {:ok, snapshot} <- ConnectionSnapshot.hydrate(aggregate, operation: :resolve_connection) do
  {:ok, snapshot}
end
```

### Provider defaults after normalization
**Source:** `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/provider.ex`
**Apply to:** Candidate normalization and apply-time runtime-field shaping
```elixir
runtime_attrs
|> apply_provider_defaults(connection.provider_preset)
|> Map.put(:idp_certificates, certificates)
|> Map.put(:cert_chain, certificates)
```

```elixir
Keyword.merge(defaults, user_config, fn _key, default_value, user_value ->
  merge_value(default_value, user_value)
end)
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | The repo has usable role-match analogs for every planned file, but `lib/relyra/metadata/refresh.ex` still needs HTTP-specific implementation details from `09-RESEARCH.md` because no existing module uses `Req` yet. |

## Metadata

**Analog search scope:** `lib/relyra`, `test/relyra`, `test/phoenix`, `test/security/xml`, `priv/repo/migrations`
**Files scanned:** 22
**Pattern extraction date:** 2026-05-05
