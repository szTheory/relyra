# Phase 52: Ecto Stores And Deterministic Seed Story - Research

**Researched:** 2026-06-12
**Domain:** Phoenix/Ecto demo data reset, Relyra Ecto adapters, deterministic SAML proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Phase 52 makes the existing `demo/ledger_loop` Phoenix app resettable and data-backed: deterministic LedgerLoop / Northstar Health host data, seeded Relyra trust-state rows, dependency-run Relyra Ecto migrations, Ecto-backed connection/request/replay store proof, and a host-owned mapping/session boundary. It does not build the full customer/admin setup UX, browser FakeIdP flow, Docker orchestration, optional Keycloak proof, browser E2E, or public demo documentation; those remain Phases 53-56.

- **D-01:** Add LedgerLoop-owned schemas and a deterministic reset path for the demo domain: tenant, user, group, membership, SAML identity/linkage, and any minimal receipt/read-model rows needed to prove the host boundary.
- **D-02:** Use stable IDs, slugs, email addresses, timestamps, and scenario keys. Demo reset must replace seeded demo data predictably so repeated resets produce the same Northstar Health story.
- **D-03:** Seed the product story around LedgerLoop as the SaaS host and Northstar Health as the customer tenant. Relyra rows are evidence for SAML trust; LedgerLoop rows are evidence for product authorization and host-owned workflow.
- **D-04:** Demo setup/reset must run Relyra's shipped migrations from the dependency path (`../../priv/repo/migrations` relative to `demo/ledger_loop`) before demo-owned migrations.
- **D-05:** Do not copy Relyra migration files into `demo/ledger_loop/priv/repo/migrations`. If an alias or Mix task is needed, it should call `Ecto.Migrator` against the dependency migration path.
- **D-06:** Add demo-owned migrations only for LedgerLoop tables and host-owned request/replay tables. Relyra trust tables stay owned by Relyra's shipped migrations.
- **D-07:** Configure the demo runtime to use `Relyra.ConnectionResolver.Ecto` with `LedgerLoop.Repo`.
- **D-08:** Add LedgerLoop-owned wrapper modules for request and replay stores. Each wrapper delegates to `Relyra.RequestStore.Ecto` or `Relyra.ReplayStore.Ecto` with `repo: LedgerLoop.Repo` and a fixed, distinct table name.
- **D-09:** Request/replay storage targets must never come from request params, RelayState, connection IDs, or user-controlled config. Exact table names are the planner's discretion, but they must be fixed in host code and covered by tests.
- **D-10:** The Phase 52 happy path must prove request intents are inserted, fetched, and consumed through the Ecto request store, and replay keys are inserted through the Ecto replay store. Existing adoption fixtures that use ETS for request/replay are references only, not acceptable final demo behavior.
- **D-11:** Seed at least four inspectable connection scenarios: enabled happy path, draft/missing-metadata, staged-certificate rollover, and failure/support.
- **D-12:** Use Relyra Ecto schemas and command modules where they match the operation being modeled. Use `Relyra.Ecto.AuditWriter.append_event/2` for seeded audit history and keep audit payloads redaction-safe.
- **D-13:** Seed support/login trace evidence as `domain: :login` audit rows using the existing six-step login trace shape. Do not blur login traces with trust-mutation audit rows; LiveAdmin intentionally queries them through separate surfaces.
- **D-14:** Add LedgerLoop-owned `UserMapper` and `SessionAdapter` modules for the demo. They should map a verified principal to seeded LedgerLoop users/SAML identities and demonstrate session or receipt establishment as host-owned work.
- **D-15:** Relyra verifies SAML trust and returns a verified principal. LedgerLoop owns account lookup/linking, group/role interpretation, product authorization, and any session/receipt persistence.
- **D-16:** Do not change `Relyra.start_login/3`, `Relyra.consume_response/3`, published behaviour callback signatures, or Phoenix route macro APIs to satisfy the demo. If planning discovers that a public API change is required, escalate before implementation.
- **D-17:** Phase 52 should include a non-browser integration proof using real signed Relyra test support to exercise Ecto connection, request, and replay stores.
- **D-18:** Browser FakeIdP flow, browser receipts, and setup/operator UX remain later phases. Phase 52 may update existing placeholder pages or workspace status only enough to make seeded data inspectable without taking over Phase 53 or Phase 54.

### the agent's Discretion
- Planner may choose the exact LedgerLoop schema/module names, table names, seed module structure, and reset command shape as long as reset is deterministic and route/API/security boundaries above hold.
- Planner may choose whether seeded inspection is primarily through database assertions, the existing workspace shell, or mounted LiveAdmin, provided full setup UX and browser proof stay deferred.
- Planner may choose exact fixture values for Northstar users/groups and connection IDs, provided they are stable, readable, and safe to show in demo UI/tests.

### Deferred Ideas (OUT OF SCOPE)
- Customer/admin setup checklist, mapping preview UX, enablement receipt, and support handoff pages remain Phase 53.
- Browser-visible FakeIdP login proof remains Phase 54.
- Docker scripts, Compose profiles, focused `mix ci.demo_app`, browser E2E, and optional Keycloak proof remain Phase 55.
- README/demo guide evidence polish remains Phase 56.
- Promoting reusable customer setup components into Relyra core remains a future productization candidate after demo evidence proves stable boundaries.
</user_constraints>

## Summary

Phase 52 should be planned as a demo-app data and adapter integration phase, not a Relyra core API phase. The current demo app already has `LedgerLoop.Repo`, Relyra as `{:relyra, path: "../.."}`, `/saml` and `/relyra/admin` route mounts, and sandbox-backed tests. [VERIFIED: codebase grep] Relyra already ships the required trust tables under root `priv/repo/migrations/`, and Ecto's migrator supports running migrations from an explicit directory path or list of paths. [VERIFIED: codebase grep] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html]

The plan should create a deterministic `LedgerLoop.Demo.Reset` / seed module, demo-owned migrations and schemas for host data, and fixed-table request/replay store wrappers that delegate to Relyra's shipped Ecto adapters with `repo: LedgerLoop.Repo`. [VERIFIED: codebase grep] The integration proof must exercise the real `Relyra.start_login/3` request intent path and `Relyra.consume_response/3` replay/session path using real signed test support, while keeping browser FakeIdP proof for Phase 54. [VERIFIED: codebase grep]

**Primary recommendation:** Build one resettable data slice: run Relyra migrations from `../../priv/repo/migrations`, run demo migrations, reset deterministic LedgerLoop + Relyra rows, wire fixed Ecto request/replay wrappers, and prove a signed non-browser login writes request, consumes request, writes replay, maps user, and persists a host receipt. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Run Relyra shipped migrations | Demo Mix task / Backend | Database | Migration orchestration belongs to host setup code; Relyra migration files remain dependency-owned. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html] |
| Deterministic demo reset | Backend | Database | Reset is repo-owned data orchestration and must replace seeded rows predictably. [VERIFIED: codebase grep] |
| Relyra connection resolution | Relyra Ecto adapter | Database | `Relyra.ConnectionResolver.Ecto` hydrates runtime connections from Relyra tables when passed `repo`. [VERIFIED: codebase grep] |
| Request intent storage | LedgerLoop wrapper | Relyra Ecto adapter | Host owns fixed table choice; Relyra owns adapter semantics. [VERIFIED: codebase grep] |
| Replay protection | LedgerLoop wrapper | Relyra Ecto adapter | Host owns fixed table choice; unique `replay_key` is the replay gate. [VERIFIED: codebase grep] |
| User mapping/session/authorization | LedgerLoop host modules | Relyra behaviour dispatch | Relyra invokes host `UserMapper` and `SessionAdapter`; host owns account/link/session semantics. [VERIFIED: codebase grep] |
| Login trace/support evidence | Relyra audit table | LiveAdmin query/export | `domain: :login` rows are queried separately from trust-mutation audit rows. [VERIFIED: codebase grep] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Deterministic LedgerLoop/Northstar tenants, users, groups, identities, mappings, cert states, audits, traces. | Seed through stable module constants, fixed IDs/timestamps, Relyra schemas, and audit writer. [VERIFIED: codebase grep] |
| DATA-02 | Seed enabled, draft/missing-metadata, staged-certificate, and failure/support scenarios. | Relyra `Connection` supports `:draft`, `:enabled`, `:disabled`; `Certificate` supports `:active`, `:next`, `:retired`; login traces use `domain: :login`. [VERIFIED: codebase grep] |
| ECTO-01 | Run Relyra migrations from dependency path, not copied files. | Use `Ecto.Migrator.with_repo/3` + `Ecto.Migrator.run(repo, path, :up, all: true)`. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html] |
| ECTO-02 | Happy path uses Ecto connection, request store, replay store. | Configure connection resolver plus fixed wrappers; integration test should assert database rows and consumed state. [VERIFIED: codebase grep] |
| ECTO-03 | Host-owned wrappers with fixed table names. | `Relyra.RequestStore.Ecto` and `Relyra.ReplayStore.Ecto` require `opts[:repo]` and `opts[:table]`; wrappers hide table choice. [VERIFIED: codebase grep] |
| ECTO-04 | User mapping/session are host-owned. | Implement LedgerLoop modules for `Relyra.UserMapper` and `Relyra.SessionAdapter`; no behaviour signature changes. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Do not implement outside the active PLAN.md scope; Phase 52 has no PLAN.md yet, so research only. [VERIFIED: AGENTS.md]
- Escalate before public API changes to `Relyra.start_login/3`, `consume_response/3`, published behaviour callbacks, default-tightening, security posture changes, or real SemVer major bumps. [VERIFIED: AGENTS.md]
- Preserve non-negotiable security invariants: configured IdP certs only, one XML parse path, pre-parse guards, required crypto verification, audit co-commit for trust mutations, production replay protection. [VERIFIED: AGENTS.md]
- Do not bypass architecture seams: signature gate, saxy XML parse, C14N, algorithm policy, audit writer, and behaviour seams. [VERIFIED: AGENTS.md]
- Keep `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` green; new security-relevant code needs adversarial/security coverage. [VERIFIED: AGENTS.md]
- Do not run `mix hex.publish`; release automation owns publishing. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | demo locked 1.8.8 | Demo host app and controller/router surface. | Already installed by Phase 51; Phoenix docs define conventional Ecto migration flow. [VERIFIED: Hex registry] [CITED: https://phoenix.hexdocs.pm/ecto.html] |
| Ecto SQL | demo locked 3.14.0 | Migrations, SQL repo, `Ecto.Migrator`, schema DSL. | Official migrator API supports explicit migration directories and `with_repo/3`. [VERIFIED: Hex registry] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html] |
| Phoenix Ecto | demo locked 4.7.0 | Phoenix/Ecto integration and sandbox conventions. | Already installed by Phase 51 demo app. [VERIFIED: Hex registry] |
| Postgrex | demo locked 0.22.2 | PostgreSQL driver for `LedgerLoop.Repo`. | Already installed by Phase 51 demo app. [VERIFIED: Hex registry] |
| Relyra | path `../..` | SAML verification, Ecto trust schemas, LiveAdmin, store behaviours. | Phase scope explicitly requires local dependency and shipped migrations. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Relyra.TestSupport.FakeIdP` / `XmldsigSigner` | local test support | Real signed SAML response generation. | Use in non-browser integration proof only; dev/test support is not a production IdP. [VERIFIED: codebase grep] |
| `Ecto.Adapters.SQL.Sandbox` | from Ecto SQL | Demo database test isolation. | Existing `LedgerLoop.DataCase` and `ConnCase` already use sandbox owner setup. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Ecto.Migrator.run(repo, path, :up, all: true)` | `mix ecto.migrate --migrations-path ../../priv/repo/migrations` | CLI option is official, but a Mix task/module gives one deterministic setup/reset path and easier tests. [CITED: https://ecto-sql.hexdocs.pm/3.13.2/Mix.Tasks.Ecto.Migrate.html] |
| Fixed wrapper modules | Passing `table:` through application config | Config can drift or be user-controlled; Phase 52 explicitly requires fixed host-owned table names. [VERIFIED: codebase grep] |

**Installation:** No new package install is recommended. Use existing demo dependencies. [VERIFIED: codebase grep]

**Version verification:** `cd demo/ledger_loop && mix deps` showed Phoenix 1.8.8, Ecto/Ecto SQL 3.14.0, Phoenix Ecto 4.7.0, Postgrex 0.22.2, and Relyra path `../..`. [VERIFIED: Hex registry]

## Package Legitimacy Audit

No external packages should be installed for Phase 52. [VERIFIED: codebase grep] `slopcheck` 0.6.1 was available but only checks npm; it is not authoritative for Hex packages and falsely classified Elixir package names when run against npm. [VERIFIED: local command] Package legitimacy should rely on existing `mix.lock` plus `mix hex.info` for Hex packages in this phase. [VERIFIED: Hex registry]

**Packages removed due to slopcheck [SLOP] verdict:** none recommended for install.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```text
mix setup/reset
  -> LedgerLoop demo migration task
     -> Ecto.Migrator.run(LedgerLoop.Repo, "../../priv/repo/migrations", :up, all: true)
     -> Ecto.Migrator.run(LedgerLoop.Repo, demo priv/repo/migrations, :up, all: true)
  -> LedgerLoop.Demo.Reset.reset!()
     -> delete seeded demo rows by stable scenario keys
     -> insert LedgerLoop tenant/users/groups/memberships/saml identities
     -> insert Relyra connections/certs/mappings/audit/login-trace rows

non-browser happy path proof
  -> Relyra.ConnectionResolver.Ecto(repo: LedgerLoop.Repo)
  -> Relyra.start_login(connection, relay_context, request_store: LedgerLoop.Relyra.RequestStore)
     -> LedgerLoop.Relyra.RequestStore delegates fixed table to Relyra.RequestStore.Ecto
  -> signed FakeIdP response
  -> Relyra.consume_response(response, opts)
     -> fetch/consume request intent in fixed request table
     -> verify signature/digest using configured cert from Relyra Ecto connection
     -> insert replay key in fixed replay table
     -> LedgerLoop.Relyra.UserMapper maps verified principal to host user
     -> LedgerLoop.Relyra.SessionAdapter persists or returns host receipt
```

### Recommended Project Structure

```text
demo/ledger_loop/lib/ledger_loop/
├── demo/
│   ├── reset.ex          # deterministic reset/seed orchestration
│   └── fixtures.ex       # stable IDs, timestamps, story constants
├── accounts/             # tenant/user/group/SAML identity schemas/context
└── relyra/
    ├── migrations.ex     # dependency-path Relyra migration runner
    ├── request_store.ex  # fixed table wrapper
    ├── replay_store.ex   # fixed table wrapper
    ├── user_mapper.ex    # host-owned mapping
    └── session_adapter.ex# host-owned session/receipt

demo/ledger_loop/priv/repo/migrations/
├── *_create_ledger_loop_demo_tables.exs
└── *_create_relyra_runtime_store_tables.exs
```

### Pattern 1: Dependency-Path Relyra Migrations

**What:** Run Relyra migrations from the root dependency path before demo migrations. [VERIFIED: codebase grep]  
**When to use:** `mix setup`, `mix ecto.setup`, reset task, and test bootstrap needing a fresh demo database. [VERIFIED: codebase grep]

```elixir
# Source: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html
def run_relyra_migrations! do
  path = Path.expand("../../priv/repo/migrations", File.cwd!())

  {:ok, _versions, _apps} =
    Ecto.Migrator.with_repo(LedgerLoop.Repo, fn repo ->
      Ecto.Migrator.run(repo, path, :up, all: true)
    end)
end
```

### Pattern 2: Fixed Store Wrappers

**What:** Host modules implement the Relyra behaviour and inject immutable `repo`/`table` options. [VERIFIED: codebase grep]  
**When to use:** All demo runtime config and tests. [VERIFIED: codebase grep]

```elixir
# Source: lib/relyra/request_store/ecto.ex and lib/relyra/replay_store/ecto.ex
defmodule LedgerLoop.Relyra.RequestStore do
  @behaviour Relyra.RequestStore
  @table "ledger_loop_relyra_request_intents"

  def put_intent(relay_state, intent, opts \\ []),
    do: Relyra.RequestStore.Ecto.put_intent(relay_state, intent, store_opts(opts))

  def fetch_intent(relay_state, opts \\ []),
    do: Relyra.RequestStore.Ecto.fetch_intent(relay_state, store_opts(opts))

  def consume_intent(relay_state, request_id, opts \\ []),
    do: Relyra.RequestStore.Ecto.consume_intent(relay_state, request_id, store_opts(opts))

  defp store_opts(opts), do: Keyword.merge(opts, repo: LedgerLoop.Repo, table: @table)
end
```

### Pattern 3: Deterministic Reset

**What:** Reset deletes by stable demo scope and reinserts constants with fixed IDs/timestamps. [VERIFIED: codebase grep]  
**When to use:** `priv/repo/seeds.exs`, test setup helpers, future `scripts/demo reset`. [VERIFIED: codebase grep]

```elixir
# Source: existing Phoenix seed convention in demo/ledger_loop/priv/repo/seeds.exs
def reset! do
  LedgerLoop.Repo.transaction(fn ->
    delete_seeded_rows!()
    seed_ledger_loop_rows!()
    seed_relyra_rows!()
    seed_audit_trace_rows!()
  end)
end
```

### Anti-Patterns to Avoid

- **Copying root Relyra migrations into demo:** violates D-04/D-05 and risks drift from shipped dependency migrations. [VERIFIED: codebase grep]
- **Configurable request/replay table names from request context:** violates D-09 and makes storage target user-influenced. [VERIFIED: codebase grep]
- **Using ETS in the final happy path:** existing adoption fixtures still use ETS for request/replay and are explicitly reference-only for this phase. [VERIFIED: codebase grep]
- **Mixing trust audit and login traces in one UI/query path:** LiveAdmin filters `domain != :login` for trust audit and queries login traces separately. [VERIFIED: codebase grep]
- **Changing Relyra public APIs:** not needed; behaviour seams already support mapper/session/store injection. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration orchestration | Custom file loader/evaluator for migration `.exs` files | `Ecto.Migrator.with_repo/3` and `run/4` | Official API loads migration directories and coordinates migration locking. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html] |
| Request intent persistence | Bespoke GenServer/ETS demo store | `Relyra.RequestStore.Ecto` via fixed wrapper | Adapter already implements insert/fetch/consume error semantics. [VERIFIED: codebase grep] |
| Replay protection | Custom duplicate checker | `Relyra.ReplayStore.Ecto` via fixed wrapper plus unique index | Adapter maps duplicate inserts to `:replayed_assertion`. [VERIFIED: codebase grep] |
| Audit redaction | Manual JSON scrubbing in seeds | `Relyra.Ecto.AuditWriter.append_event/2` | Audit writer redacts sensitive keys and enforces bounded payloads. [VERIFIED: codebase grep] |
| SAML signing fixture | Hand-assembled base64 XML | `Relyra.TestSupport.FakeIdP` / `XmldsigSigner` | Test support creates genuine signed responses with matching configured cert. [VERIFIED: codebase grep] |

**Key insight:** The hard parts are already implemented in Relyra; Phase 52's risk is wiring them through the host app with deterministic data and fixed boundaries. [VERIFIED: codebase grep]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Demo databases `ledger_loop_dev` / `ledger_loop_test*` may exist; Phase 52 seeds new deterministic rows and request/replay tables. [VERIFIED: codebase grep] | Add idempotent reset that deletes/replaces seeded rows by stable demo scope; avoid assuming empty DB except in `ecto.reset`. |
| Live service config | None found for Phase 52; no external IdP/browser/Docker service is in scope. [VERIFIED: ROADMAP.md] | None. |
| OS-registered state | None found; no launchd/systemd/pm2 registrations are involved. [VERIFIED: codebase grep] | None. |
| Secrets/env vars | Demo DB config uses local Postgres credentials in config files; no renamed or new secret keys are required. [VERIFIED: codebase grep] | None for Phase 52. |
| Build artifacts | Demo `deps/`, `_build/`, and existing DB migration state can cache old compiled code/schema. [VERIFIED: codebase grep] | Planner should include compile/migrate/test verification after adding schemas and migrations. |

## Common Pitfalls

### Pitfall 1: Relyra Migrations Run After Demo Migrations

**What goes wrong:** Demo migrations or seeds reference Relyra tables before they exist. [VERIFIED: codebase grep]  
**Why it happens:** Generated Phoenix alias currently runs only `ecto.migrate`, which defaults to the app repo migration path. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/ecto.html]  
**How to avoid:** Add a dedicated migration runner and make setup/reset call Relyra path first, then demo migrations. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html]  
**Warning signs:** `undefined_table` errors for `relyra_connections`, `relyra_audit_events`, or mapping tables. [ASSUMED]

### Pitfall 2: Store Wrapper Still Lets Table Override Leak In

**What goes wrong:** Tests pass while request-specific config can alter storage tables. [ASSUMED]  
**Why it happens:** Relyra Ecto adapters intentionally require `opts[:table]`; a thin wrapper can accidentally merge caller opts after fixed options. [VERIFIED: codebase grep]  
**How to avoid:** Build wrapper opts so fixed `repo` and `table` win, and add source/tests proving RelayState/params/connection IDs never appear in table selection. [VERIFIED: codebase grep]  
**Warning signs:** `Keyword.merge([repo: ..., table: ...], opts)` or passing raw opts directly to Relyra Ecto adapters. [ASSUMED]

### Pitfall 3: Deterministic Reset Uses Wall Clock

**What goes wrong:** Repeated reset produces drifting timestamps, ordering, and audit rows. [ASSUMED]  
**Why it happens:** Existing examples use `DateTime.utc_now()` in test helpers and schema defaults. [VERIFIED: codebase grep]  
**How to avoid:** Use fixed seed timestamps for seeded story rows; reserve live `DateTime.utc_now()` for runtime login proof rows. [ASSUMED]  
**Warning signs:** tests compare only counts, not exact IDs/slugs/timestamps/scenario keys. [ASSUMED]

### Pitfall 4: Login Trace Rows Are Seeded Like Trust Mutations

**What goes wrong:** LiveAdmin connection detail audit shows login evidence in the trust mutation surface or trace page lacks rows. [VERIFIED: codebase grep]  
**Why it happens:** All rows live in `relyra_audit_events`, but LiveAdmin separates `domain: :login` from other audit domains. [VERIFIED: codebase grep]  
**How to avoid:** Use `domain: :login`, `action: :succeeded | :failed`, `actor: "system:login_trace"`, `diff_summary: %{"kind" => "login_trace"}`, and six step names. [VERIFIED: codebase grep]  
**Warning signs:** seeded trace rows with `domain: :connection` or missing `after_summary["steps"]`. [VERIFIED: codebase grep]

## Code Examples

### Request Store Table Shape

```elixir
# Source: lib/relyra/request_store/ecto.ex
create table(:ledger_loop_relyra_request_intents, primary_key: false) do
  add :relay_state, :string, null: false
  add :request_id, :string, null: false
  add :intent, :map, null: false
  add :consumed_at, :utc_datetime_usec
  add :expires_at, :utc_datetime_usec
end

create unique_index(:ledger_loop_relyra_request_intents, [:relay_state])
create unique_index(:ledger_loop_relyra_request_intents, [:relay_state, :request_id])
create index(:ledger_loop_relyra_request_intents, [:expires_at])
```

### Replay Store Table Shape

```elixir
# Source: lib/relyra/replay_store/ecto.ex
create table(:ledger_loop_relyra_replay_keys, primary_key: false) do
  add :replay_key, :string, null: false
  add :inserted_at, :utc_datetime_usec, null: false
  add :metadata, :map, null: false, default: %{}
end

create unique_index(:ledger_loop_relyra_replay_keys, [:replay_key])
```

### Relyra Runtime Config

```elixir
# Source: lib/relyra/request_store.ex, lib/relyra/replay_store.ex, lib/relyra/connection_resolver.ex
config :relyra,
  repo: LedgerLoop.Repo,
  connection_resolver: Relyra.ConnectionResolver.Ecto,
  request_store: LedgerLoop.Relyra.RequestStore,
  replay_store: LedgerLoop.Relyra.ReplayStore,
  user_mapper: LedgerLoop.Relyra.UserMapper,
  session_adapter: LedgerLoop.Relyra.SessionAdapter
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Adoption fixture used Ecto connection resolver but ETS request/replay stores. | Phase 52 must use Ecto connection, request, and replay stores. | v1.7 Phase 52 scope, 2026-06-12. | Demo becomes production-like for durable login path. [VERIFIED: codebase grep] |
| Host apps copy library migrations. | Host demo runs dependency migrations from source path. | Locked by Phase 52 D-04/D-05. | Avoids migration drift and proves shipped migration ownership. [VERIFIED: CONTEXT.md] |
| Trust audit and login traces treated as generic audit rows. | LiveAdmin separates trust audit (`domain != :login`) and login trace (`domain == :login`). | Shipped before Phase 52. | Seed trace evidence must use trace shape. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- ETS request/replay stores for demo happy path: useful for tests but not acceptable final Phase 52 posture. [VERIFIED: CONTEXT.md]
- Copied Relyra migrations in demo app: explicitly forbidden by D-05. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Store wrapper override bugs are likely if caller opts win over fixed options. | Common Pitfalls | Security/storage target tests may miss request-influenced table choice. |
| A2 | Fixed seed timestamps should be used for story rows, with live time only for runtime proof rows. | Common Pitfalls | Determinism tests may need adjusted expectations. |
| A3 | `undefined_table` is the likely failure signature when migration order is wrong. | Common Pitfalls | Planner may need to inspect actual Postgres errors during implementation. |

## Open Questions (RESOLVED)

1. **Should reset be exposed as `mix ledger_loop.reset` or folded into `mix ecto.setup` only?**
   - What we know: current generated aliases call `ecto.setup` and `priv/repo/seeds.exs`; Phase 55 owns root `scripts/demo reset`. [VERIFIED: codebase grep]
   - What's unclear: preferred operator command name for Phase 52 before Phase 55 scripts exist. [ASSUMED]
   - Resolution: Phase 52 uses the deterministic seed/reset module path: `priv/repo/seeds.exs` delegates to `LedgerLoop.Demo.Reset.reset!/0`, and setup/reset aliases run the Relyra migration task before demo migrations/seeds. Phase 55 can wrap this existing reset entrypoint from root scripts. [ASSUMED]

2. **Should host receipts be persisted in a dedicated table or returned-only from `SessionAdapter`?**
   - What we know: ECTO-04 requires demonstrating host-owned mapping/session boundary; Phase 53/54 own browser receipt UX. [VERIFIED: REQUIREMENTS.md]
   - What's unclear: whether durable receipt rows are needed before browser receipt pages. [ASSUMED]
   - Resolution: persist minimal `LedgerLoop.Accounts.LoginReceipt` rows in `ledger_loop_login_receipts` because they provide database-level proof of the host-owned boundary without taking Phase 53/54 browser receipt scope. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Compile, migrations, tests | yes | Elixir 1.19.5 / Mix 1.19.5, OTP 28 | none |
| PostgreSQL local server | Demo repo create/migrate/test | yes | `pg_isready`: accepting connections on `/tmp:5432` | Docker later in Phase 55 |
| Docker | Future demo orchestration, not Phase 52 core | yes | 29.5.2 client | Not needed in Phase 52 |
| Context7 CLI | Docs lookup | no | unavailable | Official HexDocs via web |
| slopcheck | Package legitimacy | yes | 0.6.1 | Not authoritative for Hex packages |

**Missing dependencies with no fallback:** none for Phase 52. [VERIFIED: local command]

**Missing dependencies with fallback:** Context7 CLI unavailable; official HexDocs were used. [VERIFIED: local command] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Phoenix generated test setup. [VERIFIED: codebase grep] |
| Config file | `demo/ledger_loop/test/test_helper.exs`; app config in `demo/ledger_loop/config/test.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd demo/ledger_loop && mix test test/ledger_loop --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `cd demo/ledger_loop && mix test --warnings-as-errors` plus root `mix test --warnings-as-errors` if Relyra support changes. [VERIFIED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DATA-01 | Reset creates exact deterministic tenant/user/group/identity/mapping/cert/audit/trace story. | integration | `cd demo/ledger_loop && mix test test/ledger_loop/demo/reset_test.exs --warnings-as-errors` | no - Wave 0 |
| DATA-02 | Four connection scenarios are seeded and inspectable. | integration/query | `cd demo/ledger_loop && mix test test/ledger_loop/demo/connection_scenarios_test.exs --warnings-as-errors` | no - Wave 0 |
| ECTO-01 | Relyra migrations run from dependency path and are not copied. | integration/source | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/migrations_test.exs --warnings-as-errors` | no - Wave 0 |
| ECTO-02 | Happy path uses Ecto connection/request/replay stores. | integration | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/ecto_happy_path_test.exs --warnings-as-errors` | no - Wave 0 |
| ECTO-03 | Request/replay wrappers use fixed table names. | unit/source | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/store_wrapper_test.exs --warnings-as-errors` | no - Wave 0 |
| ECTO-04 | Mapping/session are host-owned and produce host proof. | integration | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/host_boundary_test.exs --warnings-as-errors` | no - Wave 0 |

### Sampling Rate

- **Per task commit:** `cd demo/ledger_loop && mix test --warnings-as-errors` for demo-only changes. [VERIFIED: codebase grep]
- **Per wave merge:** Add root `mix test --warnings-as-errors` if any root Relyra files changed. [VERIFIED: AGENTS.md]
- **Phase gate:** `cd demo/ledger_loop && mix format --check-formatted && mix test --warnings-as-errors`, plus root `mix format --check-formatted`, `mix test --warnings-as-errors`, and `mix ci.security` if security-relevant root code changes. [VERIFIED: AGENTS.md]

### Wave 0 Gaps

- [ ] `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` - covers DATA-01.
- [ ] `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` - covers DATA-02.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/migrations_test.exs` - covers ECTO-01.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/ecto_happy_path_test.exs` - covers ECTO-02.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/store_wrapper_test.exs` - covers ECTO-03.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/host_boundary_test.exs` - covers ECTO-04.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Keep SAML verification inside Relyra; host mapper/session only runs after verified principal. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Host `SessionAdapter` owns session/receipt creation; no session logic in Relyra core. [VERIFIED: codebase grep] |
| V4 Access Control | yes | LedgerLoop owns group/role interpretation and authorization from seeded mappings. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Use Ecto changesets/schemas and Relyra store behaviour contracts; no request-derived table names. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Use existing `FakeIdP`/`XmldsigSigner` for proof and configured IdP cert in Relyra connection; never trust document `KeyInfo`. [VERIFIED: AGENTS.md] |

### Known Threat Patterns for Phoenix/Ecto SAML Demo

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Request-derived table selection | Tampering / Elevation of privilege | Fixed wrapper module constants; tests scanning for table override leaks. [VERIFIED: CONTEXT.md] |
| Replay acceptance | Spoofing / Replay | Ecto replay table unique index and `Relyra.ReplayStore.Ecto`. [VERIFIED: codebase grep] |
| Trust-source confusion | Spoofing | Seed configured certs in Relyra tables; verification uses configured certs only. [VERIFIED: AGENTS.md] |
| Audit/trace leakage | Information disclosure | Use `AuditWriter` and `LoginTrace.Export` redaction; do not seed raw XML/PEM in audit payloads. [VERIFIED: codebase grep] |
| Parser differential | Tampering | Do not add XML parsing in LedgerLoop; use Relyra test support and Relyra consume path. [VERIFIED: AGENTS.md] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - project security invariants, testing requirements, public API escalation rules. [VERIFIED: codebase grep]
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-CONTEXT.md` - locked decisions and phase boundary. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - requirement IDs, phase success criteria, current milestone state. [VERIFIED: codebase grep]
- `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex`, `lib/relyra/connection_resolver/ecto.ex`, `lib/relyra/ecto/*`, `lib/relyra.ex` - existing adapter and protocol contracts. [VERIFIED: codebase grep]
- `demo/ledger_loop/*` - current Phase 51 demo app foundation. [VERIFIED: codebase grep]
- Ecto Migrator official docs - explicit migration directory, `with_repo/3`, execution model. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html]
- Phoenix Ecto official docs - conventional migrations and schema migration tracking. [CITED: https://phoenix.hexdocs.pm/ecto.html]

### Secondary (MEDIUM confidence)
- Hex registry output from `mix hex.info` for package versions/downloads/source links. [VERIFIED: Hex registry]
- Existing adoption tests and fixtures for proof patterns. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None used as authority. Assumptions are isolated in the Assumptions Log. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing locked dependencies and Hex registry verified. [VERIFIED: Hex registry]
- Architecture: HIGH - phase decisions map directly to existing Relyra seams and demo app files. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - most are verified from code; some failure signatures and reset-shape details are assumptions needing implementation feedback. [ASSUMED]

**Research date:** 2026-06-12  
**Valid until:** 2026-07-12 for codebase-specific findings; 2026-06-19 for fast-moving dependency version freshness.
