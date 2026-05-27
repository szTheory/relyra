# Production Ecto Path

This guide is the authoritative Day-2 upgrade path from `mix relyra.install`
defaults to cluster-safe Ecto adapters. Follow the numbered sections in order.

## Overview

`mix relyra.install` scaffolds ETS-backed stores and a placeholder connection
resolver so you can prove login on a single node. Production deployments need
durable connection resolution and replay protection across nodes — this guide
walks through the Ecto upgrade without reading Relyra source.

**Upgrade checklist:**

1. Run Relyra migrations from the dependency path
2. Create host store tables (not shipped by Relyra)
3. Implement store wrapper modules
4. Wire `ConnectionResolver.Ecto`
5. Update production config
6. Enable the opt-in ETS warning safety net during migration

## Why upgrade from install defaults

The installer writes these defaults into `config/dev.exs`:

```elixir
config :relyra,
  connection_resolver: Relyra.ConnectionResolver.Default,
  request_store: Relyra.RequestStore.ETS,
  replay_store: Relyra.ReplayStore.ETS
```

These are dev/single-node conveniences:

- `ConnectionResolver.Default` does not resolve real connections from your database.
- `RequestStore.ETS` and `ReplayStore.ETS` are in-memory, single-node stores.
- Replay protection and request intent semantics are not durable across restarts or cluster nodes.

Production needs Ecto-backed adapters and a host-owned `Connections` delegator.

### Relyra owns / Host owns

**Relyra owns:** 13 shipped migrations covering connections, metadata sources,
metadata revisions, connection certificates, attribute mappings, and audit tables.

**Host owns:** Store table DDL (`request_intents`, `replay_keys`), thin wrapper
modules that inject per-store `repo` and `table`, and the `Connections` delegator
that replaces the install stub.

## 1. Run Relyra migrations from the dependency path

`mix relyra.install` does **not** copy migrations into your host app. Run them
from the `:relyra` dependency path:

```elixir
migrations_path = Application.app_dir(:relyra, "priv/repo/migrations")

Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
  Ecto.Migrator.run(repo, migrations_path, :up, all: true)
end)
```

Add a host Mix alias for operator repeatability:

```elixir
"relyra.migrate": ["run priv/scripts/relyra_migrate.exs"]
```

The script should invoke the `Ecto.Migrator.run/4` snippet above. Re-runs are
idempotent via `schema_migrations`.

The 13 shipped migrations cover connections, metadata, certificates, mappings,
and audit — **not** request/replay store tables. Those are host-owned (next section).

## 2. Create host store tables (not shipped by Relyra)

Create two host-owned tables. Column names match the Ecto adapter SQL contracts.

**`request_intents`**

| Column | Type | Notes |
|--------|------|-------|
| `relay_state` | text | unique index |
| `request_id` | text | |
| `intent` | jsonb/map | serialized intent |
| `consumed_at` | utc_datetime | nullable |
| `expires_at` | utc_datetime | |

**`replay_keys`**

| Column | Type | Notes |
|--------|------|-------|
| `replay_key` | text | unique index |
| `inserted_at` | utc_datetime | |
| `metadata` | jsonb/map | |

Example host migration skeleton:

```elixir
defmodule MyApp.Repo.Migrations.CreateRelyraStoreTables do
  use Ecto.Migration

  def change do
    create table(:request_intents) do
      add :relay_state, :text, null: false
      add :request_id, :text, null: false
      add :intent, :map, null: false
      add :consumed_at, :utc_datetime
      add :expires_at, :utc_datetime
    end

    create unique_index(:request_intents, [:relay_state])

    create table(:replay_keys) do
      add :replay_key, :text, null: false
      add :inserted_at, :utc_datetime, null: false
      add :metadata, :map, null: false
    end

    create unique_index(:replay_keys, [:replay_key])
  end
end
```

Table names are host-owned — use prefixes like `relyra_request_intents` if your
naming convention requires it. Wrapper modules must pass the same table name via
`opts[:table]`.

## 3. Implement store wrapper modules

Both `Relyra.RequestStore.Ecto` and `Relyra.ReplayStore.Ecto` require
`opts[:repo]` **and** `opts[:table]` on every call.

**Critical gotcha:** A single `config :relyra, table: "request_intents"` cannot
serve both stores — both adapters read `opts[:table]`. Implement thin host wrapper
modules that inject the correct repo and table per store.

**Request store wrapper:**

```elixir
defmodule MyApp.Relyra.RequestStore do
  @behaviour Relyra.RequestStore

  @repo MyApp.Repo
  @table "request_intents"

  @impl true
  def put_intent(relay_state, intent, opts \\ []) do
    Relyra.RequestStore.Ecto.put_intent(relay_state, intent, store_opts(opts))
  end

  @impl true
  def fetch_intent(relay_state, opts \\ []) do
    Relyra.RequestStore.Ecto.fetch_intent(relay_state, store_opts(opts))
  end

  @impl true
  def consume_intent(relay_state, request_id, opts \\ []) do
    Relyra.RequestStore.Ecto.consume_intent(relay_state, request_id, store_opts(opts))
  end

  defp store_opts(opts), do: Keyword.merge([repo: @repo, table: @table], opts)
end
```

**Replay store wrapper** — symmetric pattern with `@table "replay_keys"` delegating
to `Relyra.ReplayStore.Ecto.consume_replay_key/3`.

Optional dependencies when enabling Ecto adapters: `{:ecto, …}`, `{:ecto_sql, …}`,
`{:postgrex, …}`.

## 4. Wire ConnectionResolver.Ecto

Replace the install-generated `Connections` stub (which returns
`:adapter_not_configured`) with a delegator:

```elixir
defmodule MyApp.Relyra.Connections do
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(request_context, opts) do
    Relyra.ConnectionResolver.Ecto.resolve_connection(
      request_context,
      Keyword.put_new(opts, :repo, MyApp.Repo)
    )
  end
end
```

## 5. Update production config

Point `:relyra` at your wrapper modules:

```elixir
config :relyra,
  connection_resolver: MyApp.Relyra.Connections,
  request_store: MyApp.Relyra.RequestStore,
  replay_store: MyApp.Relyra.ReplayStore,
  repo: MyApp.Repo
```

`:relyra` config keys propagate to runtime opts via the ACS controller.

## 6. Production ETS warning (opt-in safety net)

During migration, you may still have ETS adapters configured in some environments.
Relyra provides an **opt-in** warning — it is **not** automatic when
`Mix.env() == :prod`. The default after install is `false`:

```elixir
Application.get_env(:relyra, :prod_runtime_ets_warning, false)
```

Enable in `config/runtime.exs` for production while you finish the Ecto swap:

```elixir
config :relyra, prod_runtime_ets_warning: true
```

If ETS adapters are still hit at runtime, Relyra logs these verbatim warnings:

- `Relyra.ReplayStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe replay guarantees.`
- `Relyra.RequestStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe request intent semantics.`

Warnings stop once both stores use Ecto wrappers.

## Receipt

- [ ] Relyra's 13 migrations applied via dep-path runner
- [ ] Host `request_intents` and `replay_keys` tables exist with unique indexes
- [ ] Wrapper modules configured with distinct `opts[:table]` per store
- [ ] `MyApp.Relyra.Connections` resolves connections via Ecto
- [ ] Production config points at Ecto wrappers, not ETS defaults
- [ ] Login succeeds with Ecto stores; no ETS warning after swap

## Related Day-2 guides

After completing the Ecto upgrade, continue with production operations:

- [Incident playbook — login trace & evidence surfaces](operations/incident_playbook.md#evidence-surfaces) — per-login step timeline (`mix relyra.trace` / LiveView) for Diagnose steps in SAML incidents
- [Troubleshooting](troubleshooting.md) — `Relyra.Error` atom decoder for symptom → operator action
- [Documentation overview](overview.md) — Day-2 hub for production operators (Ecto path, runbooks, identity mapping)
