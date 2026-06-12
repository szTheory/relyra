# Phase 52: Ecto Stores And Deterministic Seed Story - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 24 new/modified files
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `demo/ledger_loop/mix.exs` | config | batch | `demo/ledger_loop/mix.exs` + `test/support/migration_case.ex` | role-match |
| `demo/ledger_loop/config/config.exs` | config | request-response | `test/support/adoption_fixtures.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/relyra/migrations.ex` | utility | batch | `test/support/migration_case.ex` | exact |
| `demo/ledger_loop/priv/repo/migrations/*_create_ledger_loop_demo_tables.exs` | migration | CRUD | `priv/repo/migrations/20260505120000_create_relyra_connections.exs` | role-match |
| `demo/ledger_loop/priv/repo/migrations/*_create_relyra_runtime_store_tables.exs` | migration | request-response | `lib/relyra/request_store/ecto.ex` + `lib/relyra/replay_store/ecto.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop/accounts/tenant.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/accounts/user.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/accounts/group.ex` | model | CRUD | `lib/relyra/ecto/group_mapping.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/accounts/membership.ex` | model | CRUD | `lib/relyra/ecto/group_mapping.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/accounts/saml_identity.ex` | model | CRUD | `lib/relyra/ecto/attribute_mapping.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/accounts/login_receipt.ex` | model | event-driven | `lib/relyra/ecto/audit_event.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` | utility | transform | `test/support/adoption_fixtures.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` | service | batch | `test/support/adoption_fixtures.ex` + `test/relyra/live_admin/phase15_ui_contract_test.exs` | role-match |
| `demo/ledger_loop/priv/repo/seeds.exs` | config | batch | `demo/ledger_loop/priv/repo/seeds.exs` | exact |
| `demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex` | service | request-response | `lib/relyra/request_store/ecto.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop/relyra/replay_store.ex` | service | request-response | `lib/relyra/replay_store/ecto.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex` | service | request-response | `test/fixtures/demo_host/lib/demo_host/relyra/user_mapper.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` | service | request-response | `test/fixtures/demo_host/lib/demo_host/relyra/session_adapter.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` | controller | request-response | `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` | component | request-response | `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` | exact |
| `demo/ledger_loop/test/support/data_case.ex` | test | CRUD | `demo/ledger_loop/test/support/data_case.ex` | exact |
| `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` | test | batch | `test/relyra/live_admin/phase15_ui_contract_test.exs` | role-match |
| `demo/ledger_loop/test/ledger_loop/relyra/store_wrapper_test.exs` | test | request-response | `test/security/stores/request_store_ecto_test.exs` + `test/security/stores/replay_store_ecto_test.exs` | exact |
| `demo/ledger_loop/test/ledger_loop/relyra/signed_ecto_login_test.exs` | test | request-response | `test/adoption/journey_04_ecto_production_path_test.exs` | role-match |

## Pattern Assignments

### Demo Migration Runner And Mix Aliases

**Apply to:** `demo/ledger_loop/mix.exs`, `demo/ledger_loop/lib/ledger_loop/relyra/migrations.ex`

**Analog:** `test/support/migration_case.ex`

**Imports and path pattern** (lines 6-10):
```elixir
alias Ecto.Adapters.SQL.Sandbox
alias Ecto.Migrator
alias Relyra.TestSupport.EctoTestRepo

@migrations_path Path.expand("../../priv/repo/migrations", __DIR__)
```

**Migration execution pattern** (lines 96-100):
```elixir
defp migrate! do
  Migrator.with_repo(EctoTestRepo, fn repo ->
    Migrator.run(repo, @migrations_path, :up, all: true)
  end)
end
```

**Demo alias pattern to modify** (`demo/ledger_loop/mix.exs` lines 67-73):
```elixir
defp aliases do
  [
    setup: ["deps.get", "ecto.setup"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end
```

Planner instruction: add a demo utility/Mix task that runs root Relyra migrations from `../../priv/repo/migrations` before `ecto.migrate`; do not copy root migrations into the demo.

---

### Demo-Owned Migrations And Schemas

**Apply to:** LedgerLoop tenant/user/group/membership/SAML identity/receipt schemas and demo migrations.

**Analogs:** `priv/repo/migrations/20260505120000_create_relyra_connections.exs`, `lib/relyra/ecto/connection.ex`, `lib/relyra/ecto/certificate.ex`, `lib/relyra/ecto/attribute_mapping.ex`, `lib/relyra/ecto/group_mapping.ex`

**Migration table/index pattern** (`priv/repo/migrations/20260505120000_create_relyra_connections.exs` lines 4-23):
```elixir
def change do
  create table(:relyra_connections, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :connection_id, :string, null: false
    add :display_name, :string
    add :organization_id, :string
    add :status, :string, null: false, default: "draft"

    timestamps(type: :utc_datetime_usec)
  end

  create unique_index(:relyra_connections, [:connection_id])
  create index(:relyra_connections, [:status])
end
```

**Schema imports/associations pattern** (`lib/relyra/ecto/connection.ex` lines 5-22, 28-70):
```elixir
use Ecto.Schema

import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "relyra_connections" do
  field :connection_id, :string
  field :display_name, :string
  field :organization_id, :string
  field :status, Ecto.Enum, values: [:draft, :enabled, :disabled], default: :draft

  has_many :certificates, Certificate, foreign_key: :connection_record_id, on_replace: :delete

  timestamps(type: :utc_datetime_usec)
end
```

**Changeset validation pattern** (`lib/relyra/ecto/attribute_mapping.ex` lines 31-48):
```elixir
def changeset(mapping, attrs) do
  mapping
  |> cast(attrs, [
    :connection_record_id,
    :source_attribute,
    :target_field,
    :multivalue_strategy
  ])
  |> validate_required([
    :connection_record_id,
    :source_attribute,
    :target_field,
    :multivalue_strategy
  ])
  |> validate_length(:source_attribute, min: 1)
  |> foreign_key_constraint(:connection_record_id)
end
```

**Group/membership mapping pattern** (`lib/relyra/ecto/group_mapping.ex` lines 15-26, 31-52):
```elixir
schema "relyra_group_mappings" do
  field :source_attribute, :string
  field :source_value, :string
  field :role_target, Ecto.Enum, values: @role_target_values
  field :role_value, :string

  belongs_to :connection, Connection,
    foreign_key: :connection_record_id,
    references: :id,
    type: :binary_id

  timestamps(type: :utc_datetime_usec)
end
```

Planner instruction: LedgerLoop tables should use binary IDs, stable natural keys/slugs, unique indexes, UTC usec timestamps, and normal Ecto changesets. Keep Relyra trust tables out of demo migrations.

---

### Runtime Store Table Migration

**Apply to:** `*_create_relyra_runtime_store_tables.exs`

**Analogs:** `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex`

**Request-store required columns** (`lib/relyra/request_store/ecto.ex` lines 82-85, 111-116, 163-167):
```elixir
INSERT INTO #{table} (relay_state, request_id, intent, consumed_at, expires_at)
VALUES ($1, $2, $3, NULL, $4)

SELECT request_id, intent, consumed_at, expires_at
FROM #{table}
WHERE relay_state = $1
LIMIT 1

UPDATE #{table}
SET consumed_at = $1
WHERE relay_state = $2 AND request_id = $3 AND consumed_at IS NULL
```

**Replay-store required columns** (`lib/relyra/replay_store/ecto.ex` lines 36-39):
```elixir
INSERT INTO #{table} (replay_key, inserted_at, metadata)
VALUES ($1, $2, $3)
```

Planner instruction: create fixed host-owned tables with columns exactly matching adapter SQL. Use unique indexes on request `relay_state`, request `{relay_state, request_id}`, and replay `replay_key`; add an `expires_at` index for request cleanup/readiness.

---

### Fixed Request And Replay Store Wrappers

**Apply to:** `demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex`, `demo/ledger_loop/lib/ledger_loop/relyra/replay_store.ex`

**Analogs:** `lib/relyra/request_store.ex`, `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store.ex`, `lib/relyra/replay_store/ecto.ex`

**Request behaviour contract** (`lib/relyra/request_store.ex` lines 8-18):
```elixir
@callback put_intent(relay_state :: binary(), intent :: map(), opts :: keyword()) ::
            :ok | {:error, Error.t()}

@callback fetch_intent(relay_state :: binary(), opts :: keyword()) ::
            {:ok, map()} | {:error, Error.t()}

@callback consume_intent(relay_state :: binary(), request_id :: binary(), opts :: keyword()) ::
            :ok | {:error, Error.t()}
```

**Ecto request adapter shape** (`lib/relyra/request_store/ecto.ex` lines 14-22, 60-67):
```elixir
def put_intent(relay_state, intent, opts)
    when is_binary(relay_state) and is_map(intent) and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts, :put_intent),
       {:ok, table} <- fetch_table(opts, :put_intent, repo),
       :ok <- ensure_optional_dependency!(:put_intent, repo, table),
       {:ok, request_id} <- request_id_from_intent(intent, repo, table, :put_intent),
       :ok <- insert_intent(repo, table, relay_state, request_id, intent) do
    :ok
  end
end

def consume_intent(relay_state, request_id, opts)
    when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts, :consume_intent),
       {:ok, table} <- fetch_table(opts, :consume_intent, repo),
       :ok <- ensure_optional_dependency!(:consume_intent, repo, table),
       :ok <- update_intent_consume(repo, table, relay_state, request_id) do
    :ok
  end
end
```

**Fixed options must win** (`lib/relyra/request_store/ecto.ex` lines 255-285; `lib/relyra/replay_store/ecto.ex` lines 64-95):
```elixir
case Keyword.fetch(opts, :repo) do
  {:ok, repo} when is_atom(repo) -> {:ok, repo}
  _ -> {:error, Error.new(:request_intent_not_found, "opts[:repo] is required ...")}
end

case Keyword.fetch(opts, :table) do
  {:ok, table} when is_binary(table) and table != "" -> {:ok, table}
  {:ok, table} when is_atom(table) -> {:ok, Atom.to_string(table)}
  _ -> {:error, Error.new(:request_intent_not_found, "opts[:table] is required ...")}
end
```

**Replay behaviour contract** (`lib/relyra/replay_store.ex` lines 8-10):
```elixir
@callback consume_replay_key(replay_key :: binary(), metadata :: map(), opts :: keyword()) ::
            :ok | {:error, Error.t()}
```

Planner instruction: wrapper modules should implement Relyra behaviours and delegate to Relyra Ecto adapters with `repo: LedgerLoop.Repo` and fixed table constants. Merge caller opts first, then fixed `repo`/`table`, so params/RelayState/connection IDs cannot override storage targets.

---

### Relyra Ecto Connection Resolver Configuration

**Apply to:** `demo/ledger_loop/config/config.exs`, runtime config/test setup.

**Analog:** `lib/relyra/connection_resolver/ecto.ex`, `test/support/adoption_fixtures.ex`

**Resolver contract** (`lib/relyra/connection_resolver/ecto.ex` lines 14-23, 50-65):
```elixir
def resolve_connection(%{connection_id: connection_id}, opts)
    when is_binary(connection_id) and connection_id != "" and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts),
       {:ok, aggregate} <-
         ConnectionLoader.fetch(repo, connection_id, operation: :resolve_connection),
       {:ok, snapshot} <- ConnectionSnapshot.hydrate(aggregate, operation: :resolve_connection) do
    {:ok, snapshot}
  end
end

defp fetch_repo(opts) do
  case Keyword.fetch(opts, :repo) do
    {:ok, repo} when is_atom(repo) -> {:ok, repo}
    _ -> {:error, Error.new(:resolver_misconfigured, "opts[:repo] is required ...")}
  end
end
```

**Existing runtime config pattern to replace** (`test/support/adoption_fixtures.ex` lines 57-67):
```elixir
Application.put_env(:relyra, :connection_resolver, DemoHost.Relyra.Connections)
Application.put_env(:relyra, :user_mapper, DemoHost.Relyra.UserMapper)
Application.put_env(:relyra, :session_adapter, DemoHost.Relyra.SessionAdapter)
Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)
Application.put_env(:relyra, :repo, Repo)
```

Planner instruction: demo app config should use `Relyra.ConnectionResolver.Ecto`, `LedgerLoop.Repo`, and LedgerLoop-owned store/mapper/session modules. Do not copy the ETS request/replay lines from the adoption fixture.

---

### Deterministic Reset And Seed Data

**Apply to:** `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`, `demo/ledger_loop/lib/ledger_loop/demo/reset.ex`, `demo/ledger_loop/priv/repo/seeds.exs`

**Analogs:** `test/support/adoption_fixtures.ex`, `test/relyra/live_admin/phase15_ui_contract_test.exs`, `demo/ledger_loop/priv/repo/seeds.exs`

**Existing seed entrypoint style** (`demo/ledger_loop/priv/repo/seeds.exs` lines 1-11):
```elixir
# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LedgerLoop.Repo.insert!(%LedgerLoop.SomeSchema{})
```

**Relyra connection seed pattern** (`test/support/adoption_fixtures.ex` lines 109-155):
```elixir
record =
  Repo.insert!(%ConnectionRecord{
    id: Ecto.UUID.generate(),
    connection_id: connection_id,
    organization_id: "org_adoption",
    display_name: "Adoption Journey Connection",
    status: :enabled,
    provider_preset: preset,
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_entity_id: "https://idp.example.com/metadata",
    idp_sso_url: "https://idp.example.com/sso",
    runtime_policy: %{
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
      algorithm_policy: %{signing: :rsa_sha256, digest: :sha256}
    },
    inserted_at: now,
    updated_at: now
  })

Repo.insert!(%Certificate{
  connection_record_id: record.id,
  pem: cert_pem,
  role: :signing,
  lifecycle_state: :active,
  activated_at: now
})
```

**Login trace seed pattern** (`test/relyra/live_admin/phase15_ui_contract_test.exs` lines 145-159, 200-203):
```elixir
AuditWriter.append_event(@repo, %{
  connection_record_id: connection.id,
  domain: :login,
  action: :succeeded,
  actor: "system:login_trace",
  cause: "sp_initiated",
  correlation_id: "corr-phase15-trace",
  before_summary: %{},
  after_summary: %{
    "steps" => login_trace_steps(),
    "overall_outcome" => "ok"
  },
  diff_summary: %{"kind" => "login_trace"}
})

defp login_trace_steps do
  Map.new(@trace_step_names, fn step_name ->
    {step_name, %{"outcome" => "ok", "duration_ms" => 5}}
  end)
end
```

Planner instruction: replace ad hoc seed script logic with `LedgerLoop.Demo.Reset.reset!()`. Use stable IDs/timestamps/constants for Northstar Health, four Relyra connection scenarios, LedgerLoop users/groups/identities, audit rows, and login trace rows. Use `AuditWriter.append_event/2` for audit rows; do not insert raw audit maps if writer can model the operation.

---

### Host-Owned User Mapping And Session Boundary

**Apply to:** `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex`, `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex`

**Analogs:** `lib/relyra/user_mapper.ex`, `lib/relyra/session_adapter.ex`, `test/fixtures/demo_host/lib/demo_host/relyra/user_mapper.ex`, `test/fixtures/demo_host/lib/demo_host/relyra/session_adapter.ex`

**Behaviour seam contract** (`lib/relyra/user_mapper.ex` lines 6-24, 29-31):
```elixir
# Relyra owns SAML validation before this seam.
# The mapper can read verified identity fields from `login_result.principal`.
@callback map_attributes(assertion :: map(), connection :: map(), opts :: keyword()) ::
            {:ok, map()} | {:error, Error.t()}
```

**Minimal mapper analog** (`test/fixtures/demo_host/lib/demo_host/relyra/user_mapper.ex` lines 1-13):
```elixir
defmodule DemoHost.Relyra.UserMapper do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(%{principal: principal}, _connection, _opts) do
    {:ok,
     %{
       id: principal.name_id,
       email: principal.name_id,
       name_id: principal.name_id
     }}
  end
end
```

**Session adapter analog** (`test/fixtures/demo_host/lib/demo_host/relyra/session_adapter.ex` lines 1-18):
```elixir
defmodule DemoHost.Relyra.SessionAdapter do
  @moduledoc false
  @behaviour Relyra.SessionAdapter

  @impl true
  def establish_session(user, _login_result, _opts) do
    {:ok, %{user_id: user.id, email: user.email}}
  end

  @impl true
  def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, :revoked}
end
```

Planner instruction: LedgerLoop mapper should lookup seeded `SamlIdentity`/`User` rows from verified principal attributes and return host user/account data. Session adapter should persist or return a LedgerLoop-owned receipt/session proof without changing Relyra behaviour signatures.

---

### Workspace Inspection Surface

**Apply to:** `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex`, `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex`, `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs`

**Analogs:** existing same files from Phase 51.

**Controller assign pattern** (`demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` lines 4-10):
```elixir
def home(conn, _params) do
  readiness = if LedgerLoop.Health.ready?(), do: "Ready", else: "Unavailable"

  render(conn, :home,
    health_status: "Booted",
    readiness_status: readiness
  )
end
```

**Template route/status pattern** (`demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` lines 13-24, 27-34):
```heex
<section class="workspace-panel" aria-labelledby="tenant-status-title">
  <h2 id="tenant-status-title">Northstar Health SSO status</h2>
  <p class="status-label">Needs setup</p>
  <h3>No tenant data loaded</h3>
  <p>
    Run the demo reset command, then refresh this workspace to load Northstar Health and its SSO status.
  </p>
</section>

<nav aria-label="LedgerLoop route affordances">
  <a href={~p"/setup/sso"}>Open SSO Setup</a>
  <a href={~p"/login/test"}>Start Test Login</a>
  <a href="/relyra/admin">Open Relyra Admin</a>
  <a href={~p"/support/scenario"}>Open Support Scenario</a>
</nav>
```

**Forbidden-token test pattern** (`demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` lines 34-43):
```elixir
for forbidden <- [
      "BEGIN CERTIFICATE",
      "SAMLResponse",
      "Assertion",
      "RelayState=",
      "FakeIdP",
      "Keycloak"
    ] do
  refute response =~ forbidden
end
```

Planner instruction: Phase 52 may show seeded Northstar/connection summaries, but must keep browser FakeIdP flow and full setup UX deferred. Preserve forbidden-token expectations.

---

### Non-Browser Signed Login Proof

**Apply to:** `demo/ledger_loop/test/ledger_loop/relyra/signed_ecto_login_test.exs`

**Analogs:** `test/adoption/journey_04_ecto_production_path_test.exs`, `test/support/adoption_fixtures.ex`, store tests.

**Signed ACS proof flow** (`test/adoption/journey_04_ecto_production_path_test.exs` lines 14-28):
```elixir
@tag :integration
test "seeded Ecto connection resolves and accepts a signed ACS post" do
  AdoptionFixtures.seed_ecto_connection!(:okta, "ecto_demo")

  post_params = AdoptionFixtures.build_signed_acs_post!("ecto_demo")

  conn =
    build_conn()
    |> post("/ecto_demo/acs", %{
      "SAMLResponse" => post_params.saml_response,
      "RelayState" => post_params.relay_state
    })

  assert redirected_to(conn) == "/welcome"
end
```

**Signed response fixture pattern** (`test/support/adoption_fixtures.ex` lines 181-209):
```elixir
builder =
  Relyra.TestSupport.FakeIdP.build_response(
    subject: subject,
    audience: "https://sp.example.com/metadata",
    destination: "https://sp.example.com/saml/acs",
    recipient: "https://sp.example.com/saml/acs",
    in_response_to: request_id,
    relay_state: relay_state,
    name_id: subject
  )

signed_b64 = Relyra.TestSupport.FakeIdP.sign(builder)
```

**Request Ecto semantics test** (`test/security/stores/request_store_ecto_test.exs` lines 16-44):
```elixir
assert :ok = Ecto.put_intent(relay_state, intent, repo: @repo, table: @table)

results =
  1..12
  |> Task.async_stream(fn _ ->
    Ecto.consume_intent(relay_state, request_id, repo: @repo, table: @table)
  end)
  |> Enum.map(fn {:ok, result} -> result end)

assert 1 == Enum.count(results, &(&1 == :ok))
assert Enum.all?(loser_types, &(&1 == :request_intent_consumed))
```

**Replay Ecto semantics test** (`test/security/stores/replay_store_ecto_test.exs` lines 16-23):
```elixir
assert :ok = Ecto.consume_replay_key(replay_key, metadata, repo: @repo, table: @table)

assert {:error, %Error{type: :replayed_assertion}} =
         Ecto.consume_replay_key(replay_key, metadata, repo: @repo, table: @table)
```

Planner instruction: new proof should use `LedgerLoop.DataCase`, real `LedgerLoop.Repo`, fixed wrappers, `Relyra.start_login/3` to insert request intent, real signed FakeIdP/Xmldsig response, `Relyra.consume_response/3` to consume the request, insert replay key, invoke LedgerLoop mapper, and produce session/receipt evidence.

## Shared Patterns

### Ecto Test Harness

**Source:** `demo/ledger_loop/test/support/data_case.ex`
**Apply to:** all demo database tests

```elixir
using do
  quote do
    alias LedgerLoop.Repo

    import Ecto
    import Ecto.Changeset
    import Ecto.Query
    import LedgerLoop.DataCase
  end
end

setup tags do
  LedgerLoop.DataCase.setup_sandbox(tags)
  :ok
end
```

### Audit Redaction And Required Fields

**Source:** `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/audit_event.ex`
**Apply to:** seeded trust audit and login trace rows

```elixir
@required_attrs [:connection_record_id, :domain, :action, :actor, :cause]

def append_event(repo, attrs) when is_atom(repo) and is_map(attrs) do
  with :ok <- ensure_optional_dependencies(repo),
       {:ok, normalized_attrs} <- normalize_attrs(attrs) do
    case %AuditEvent{} |> AuditEvent.changeset(normalized_attrs) |> repo.insert() do
      {:ok, event} -> {:ok, event}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, Error.new(...)}
    end
  end
end
```

```elixir
@domain_values [:connection, :metadata, :certificate, :mapping, :login]
@action_values [
  :created,
  :updated,
  :enabled,
  :disabled,
  :applied,
  :refreshed,
  :staged,
  :activated,
  :retired,
  :replaced,
  :deleted,
  :succeeded,
  :failed
]
```

### Login Trace Step Names

**Source:** `test/relyra/live_admin/phase15_ui_contract_test.exs`
**Apply to:** seeded support/login trace evidence

```elixir
@trace_step_names [
  "response.decode",
  "response.validate",
  "signature.verify",
  "replay.check",
  "user.map",
  "session.establish"
]
```

### Demo App Repo And Supervision

**Source:** `demo/ledger_loop/lib/ledger_loop/application.ex`, `demo/ledger_loop/lib/ledger_loop/repo.ex`
**Apply to:** config, wrappers, migration runner, tests

```elixir
children = [
  LedgerLoopWeb.Telemetry,
  LedgerLoop.Repo,
  {DNSCluster, query: Application.get_env(:ledger_loop, :dns_cluster_query) || :ignore},
  {Phoenix.PubSub, name: LedgerLoop.PubSub},
  LedgerLoopWeb.Endpoint
]
```

```elixir
defmodule LedgerLoop.Repo do
  use Ecto.Repo,
    otp_app: :ledger_loop,
    adapter: Ecto.Adapters.Postgres
end
```

## No Analog Found

All expected Phase 52 files have at least a role-match analog. The only partial analog is the prior adoption proof for request/replay, because it configures ETS for those stores; use it for signed ACS flow shape only, not final store posture.

## Metadata

**Analog search scope:** `demo/ledger_loop`, `lib/relyra`, `test`, `priv/repo/migrations`  
**Files scanned:** 60+ candidate files via `rg --files`/`rg`  
**Pattern extraction date:** 2026-06-12
