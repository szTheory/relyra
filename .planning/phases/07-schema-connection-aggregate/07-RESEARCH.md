# Phase 07: Schema + connection aggregate - Research

**Researched:** 2026-05-05
**Domain:** Ecto-backed connection aggregate and schema constraints for enterprise SAML configuration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md`. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]

### Locked Decisions

#### Connection identity and lookup
- **D-01:** Use both an internal Ecto `:binary_id` primary key and an immutable public `connection_id`.
- **D-02:** `connection_id` is the operator-facing and runtime-facing identifier for Phoenix routes, resolver lookup, telemetry metadata, replay keys, and runtime snapshots.
- **D-03:** `connection_id` should be globally unique in v0.2. Do not make lookup depend on an org-scoped slug until every unauthenticated SAML route has guaranteed organization context.
- **D-04:** `display_name` remains mutable and human-friendly; it is not part of the identity contract.

#### Lifecycle and validation gates
- **D-05:** Support draft and disabled connection rows in Phase 07.
- **D-06:** Separate persistence validity from runtime eligibility. Incomplete config may be saved as `draft`, but only explicitly enabled rows that pass strict runtime-readiness validation may resolve into `%Relyra.Connection{}`.
- **D-07:** Model lifecycle state explicitly with an enum-backed field and separate changesets or validation paths for draft-save vs enable/publish.
- **D-08:** Resolver and runtime code must fail closed on non-runnable rows with typed errors; drafts must never resolve silently.

#### Trust material storage
- **D-09:** Do not store the IdP trust anchor as a single replace-in-place field on the connection record.
- **D-10:** Add a minimal child certificate inventory table in Phase 07, associated to each connection.
- **D-11:** Seed immutable certificate rows and provenance/basic metadata now so later metadata import and rollover phases can extend the model additively instead of rewriting it.
- **D-12:** Defer lifecycle promotion semantics such as `active` / `next` / `retired` and rollback workflows to Phase 10.

#### Schema shape and extensibility
- **D-13:** Use a hybrid aggregate shape: one normalized `connections` table for core trust-routing and runtime fields, plus minimal bounded JSONB/embeds for small policy/config objects.
- **D-14:** Keep certificates, mappings, and audit history out of JSON blobs; these are lifecycle-heavy concerns that should live in separate tables as their phases land.
- **D-15:** Avoid both extremes: no wide nullable mega-table and no JSON-first config blob as the authoritative aggregate.
- **D-16:** The schema should optimize for Phase 08 snapshot hydration: runtime consumers get a pure `%Relyra.Connection{}` plus plain values, never raw Ecto structs.

### Claude's Discretion
- Exact table/module names and field naming conventions, as long as internal-vs-public identity is explicit and consistent.
- Exact enum atom names for lifecycle state, provided the model clearly distinguishes draft persistence from runtime eligibility.
- Exact JSONB/embed boundaries for compact policy objects, provided they remain bounded and do not absorb certificates, mappings, or audit history.
- Exact DB constraint and index layout beyond the locked uniqueness and runtime-safety invariants above.

### Deferred Ideas (OUT OF SCOPE)
- Project-level GSD preference tuning to make recommendation-first, research-heavy, low-friction decision handling the default across future phases except for very high-impact choices.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement text copied from `.planning/REQUIREMENTS.md`. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-01 | User can create and maintain tenant-scoped SAML connection records backed by Ecto schemas and migrations. [VERIFIED: .planning/REQUIREMENTS.md] | This research defines the aggregate shape, migration constraints, draft-vs-enable validation split, child certificate table, runtime-readiness gate, and missing test scaffolding required to implement Phase 07 safely. [VERIFIED: .planning/ROADMAP.md] |
</phase_requirements>

## Summary

Phase 07 should establish one durable connection aggregate with two layers: a normalized `connections` table for routing and runtime-critical fields, and a minimal `connection_certificates` child table for trust anchors. That shape matches the Phase 07 lock on internal `:binary_id` plus public `connection_id`, preserves the existing `/:connection_id/*` route surface, and avoids leaking JSON blobs or Ecto structs into runtime code. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/phoenix/router.ex] [VERIFIED: lib/relyra/connection.ex]

The most important implementation split is not table shape but validation shape: draft persistence and runtime eligibility are different concerns. The aggregate should support a permissive draft/update changeset for persistence, a strict enable/publish path that requires all runtime fields and at least one valid certificate row, and a pure runtime-readiness validator reused later by the Ecto resolver in Phase 08. That recommendation follows the locked lifecycle decisions and fits Ecto’s separation between in-memory validation and database-backed constraints. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

The codebase already proves three constraints the planner should honor. First, runtime consumers expect plain maps and `%Relyra.Connection{}` rather than schema structs. Second, connection lookup, telemetry, and Phoenix routing already speak `connection_id`. Third, the repo has optional Ecto dependencies and fake-Repo tests but no real Repo or migration test infrastructure yet, so Phase 07 must budget Wave 0 work for a test Repo and migration harness. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/telemetry.ex] [VERIFIED: mix.exs] [VERIFIED: test/security/stores/request_store_ecto_test.exs] [VERIFIED: test/security/stores/replay_store_ecto_test.exs]

**Primary recommendation:** Build `connections` + `connection_certificates` first, keep policy state in bounded embeds, implement separate draft and enable validation paths, and treat runtime readiness as a computed gate rather than a casually edited flag. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist durable connection aggregate | Database / Storage | API / Backend | Tables, indexes, foreign keys, and check constraints are owned by the host DB; application code shapes writes around them. [VERIFIED: .planning/PROJECT.md] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |
| Draft/update/enable validation | API / Backend | Database / Storage | Ecto changesets handle user-input validation before insert/update, while DB constraints enforce non-bypassable uniqueness and FK rules. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |
| Runtime readiness gate | API / Backend | Database / Storage | Readiness is a pure domain rule over persisted values and child certs; it should be computed in Elixir and rechecked before runtime resolution. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/connection.ex] |
| Public connection lookup by `connection_id` | API / Backend | Database / Storage | Phoenix endpoints already route by `connection_id`, so resolver-facing lookup must start there while DB uniqueness makes it safe. [VERIFIED: lib/relyra/phoenix/router.ex] [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] |
| Child certificate inventory storage | Database / Storage | API / Backend | Certificate rows are relational lifecycle data and need FK, uniqueness, and provenance fields now even before rollover semantics land. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] |
| Runtime snapshot hydration | API / Backend | Database / Storage | Phase 08 will load rows but must return pure `%Relyra.Connection{}` values upward. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/connection_resolver.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | Repo locked `3.13.5`; latest `3.13.6` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] | Schemas, changesets, embeds, enum fields, and runtime-readiness validation inputs. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] | Already declared in `mix.exs`, already locked in `mix.lock`, and directly supports `Ecto.Enum`, `embedded_schema`, `embeds_one`, and `cast_embed`, which fit the locked hybrid aggregate. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |
| Ecto SQL | Repo locked `3.13.5`; latest `3.13.5` published 2026-03-03. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] | Migrations, indexes, unique constraints, FK constraints, and partial indexes. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | Already declared and locked; needed for Phase 07’s tables, indexes, and constraints. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Postgrex | Repo locked `0.22.0`; latest `0.22.1` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex] | Postgres adapter for migration tests and host-DB integration. | The repo already resolves `ecto_sql 3.13.5` with `postgrex 0.22.0`, so planner work should target the current lock rather than older 0.19-only guidance. [VERIFIED: mix.lock] |
| Jason | Repo locked `1.4.4`; latest `1.4.5` published 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info jason] | JSON codec for bounded embed fields stored in Postgres `:map` / JSONB columns. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] | Already locked and required for map-backed embeds if Phase 07 stores compact policy objects in JSONB. [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | Repo locked `1.8.5`. [VERIFIED: mix.lock] | Existing route and controller surface that resolves by `connection_id`. [VERIFIED: lib/relyra/phoenix/router.ex] | Keep as-is; Phase 07 should not spend scope on Phoenix changes beyond later resolver integration. [VERIFIED: .planning/ROADMAP.md] |
| OTP `:public_key` | Present in current runtime because the repo already uses `:public_key.generate_key/1` in test support. [VERIFIED: lib/relyra/test_support/fake_idp.ex] | Certificate parsing and metadata extraction if Phase 07 validates PEM/X.509 material during save. | Prefer existing OTP primitives over introducing a new certificate dependency unless implementation spikes prove a gap. [VERIFIED: lib/relyra/test_support/fake_idp.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Ecto.Enum` backed by strings | Raw strings plus custom validation | `Ecto.Enum` keeps lifecycle atoms explicit in code and exposes `values/2`, `dump_values/2`, and `mappings/2`, which is cleaner for readiness and changeset logic. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] |
| JSONB-first connection blob | Separate scalar columns for every field | A blob fights Phase 08 runtime hydration and DB constraints; a fully wide table fights extensibility. The locked Phase 07 decision is the hybrid middle ground. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] |
| App-only uniqueness checks | DB unique indexes only | Ecto recommends pairing database uniqueness with `unique_constraint/3`; app-only prechecks race, DB-only errors degrade UX. Use both where needed. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |

**Installation:** existing optional deps are already declared in [`mix.exs`](/Users/jon/projects/relyra/mix.exs:1), so Phase 07 should not add new persistence packages unless implementation discovers a concrete certificate-parsing gap. [VERIFIED: mix.exs]

```elixir
{:ecto, "~> 3.13", optional: true},
{:ecto_sql, "~> 3.13", optional: true},
{:postgrex, ">= 0.0.0", optional: true}
```

**Version verification:** current package metadata was verified with `mix hex.info ecto`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, and `mix hex.info jason` on 2026-05-05. [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info postgrex] [VERIFIED: mix hex.info jason]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix route /:connection_id/*
        |
        v
Connection command/query boundary
  - draft save
  - update
  - disable
  - enable/publish
        |
        +--> draft/update changeset
        |
        +--> runtime-readiness validator
        |
        v
Ecto.Multi transaction
  - connections row
  - connection_certificates rows
  - constraint handling
        |
        v
Host app Repo / Postgres
        |
        v
Phase 08 resolver adapter
        |
        v
Pure %Relyra.Connection{} + plain certificate values
```

The flow above keeps writes transactional and keeps runtime consumers isolated from Ecto structs, which matches both the locked context and the current runtime API surface. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/connection_resolver.ex]

### Recommended Project Structure

```text
lib/relyra/
├── connection.ex                         # existing runtime snapshot
├── connection_resolver.ex                # existing public behaviour
├── ecto/
│   ├── connection_record.ex              # persisted parent schema
│   ├── connection_certificate.ex         # persisted child certificate schema
│   ├── embedded/
│   │   └── runtime_policy.ex             # bounded embed for small policy config
│   └── runtime_readiness.ex              # pure validator shared by enable + resolver
test/
├── relyra/ecto/
│   ├── connection_record_test.exs
│   ├── runtime_readiness_test.exs
│   └── migration_constraints_test.exs
└── support/
    ├── ecto_test_repo.ex
    └── migration_case.ex
```

This structure keeps persistence code separated from `Relyra.Connection`, matches the existing optional-Ecto adapter style under `lib/relyra/*/ecto.ex`, and creates an obvious Phase 08 seam for `Relyra.ConnectionResolver.Ecto`. [VERIFIED: lib/relyra/request_store/ecto.ex] [VERIFIED: lib/relyra/replay_store/ecto.ex] [VERIFIED: lib/relyra/connection.ex]

### Pattern 1: Separate persistence validity from runtime eligibility

**What:** implement at least three explicit validation paths: `draft_changeset/2`, `update_changeset/2`, and `enable_changeset/2`, with `enable_changeset/2` delegating to a pure runtime-readiness validator that requires all runtime fields and at least one valid certificate row. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**When to use:** every save path in Phase 07; drafts and disabled rows use relaxed persistence rules, while enabling/publishing uses strict runtime rules. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
def draft_changeset(record, attrs) do
  record
  |> cast(attrs, [:connection_id, :display_name, :organization_id, :state, :provider_preset,
                  :sp_entity_id, :acs_url, :idp_entity_id, :idp_sso_url])
  |> cast_embed(:runtime_policy, with: &runtime_policy_changeset/2)
  |> validate_required([:connection_id, :state])
  |> unique_constraint(:connection_id)
end

def enable_changeset(record, attrs) do
  record
  |> draft_changeset(attrs)
  |> validate_change(:state, fn :state, state ->
    if state == :enabled and not RuntimeReadiness.ready?(apply_changes(record)) do
      [state: "connection is not runtime-ready"]
    else
      []
    end
  end)
end
```

### Pattern 2: Hybrid aggregate with scalar core plus bounded embeds

**What:** keep identifiers, URLs, entity IDs, lifecycle state, and provider preset as scalar columns on `connections`; keep small policy objects such as signature requirements, `allow_idp_initiated?`, `clock_skew_seconds`, `name_id_format`, and algorithm policy in one bounded embed stored as `:map`. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/provider/okta.ex] [VERIFIED: lib/relyra/provider/entra.ex] [VERIFIED: lib/relyra/provider/google_workspace.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html]

**When to use:** whenever a field set is small, cohesive, and not independently queried across rows. Certificates, mappings, and audit history do not qualify and stay relational. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Schema.html
schema "connections" do
  field :connection_id, :string
  field :display_name, :string
  field :organization_id, :string
  field :state, Ecto.Enum, values: [:draft, :enabled, :disabled]
  field :provider_preset, Ecto.Enum, values: [:okta, :entra, :google_workspace]
  field :sp_entity_id, :string
  field :acs_url, :string
  field :idp_entity_id, :string
  field :idp_sso_url, :string

  embeds_one :runtime_policy, RuntimePolicy, on_replace: :update

  has_many :certificates, ConnectionCertificate
  timestamps(type: :utc_datetime_usec)
end
```

### Pattern 3: Transactional parent + child writes with immutable certificate rows

**What:** write connection updates and certificate inventory changes through one `Ecto.Multi`, inserting new child rows with parsed metadata and rejecting invalid cert material before the connection can be enabled. If draft edits replace the active inventory, make replacement explicit in the command layer rather than mutating PEM fields on existing rows. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**When to use:** create, update, disable, and enable flows that touch both parent config and trust anchors. [VERIFIED: .planning/ROADMAP.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
changeset
|> foreign_key_constraint(:connection_id)
|> unique_constraint([:connection_id, :fingerprint_sha256])
```

### Anti-Patterns to Avoid

- **Using `Relyra.Connection` as the persistence schema:** that would blur the runtime/persistence boundary the codebase already maintains. Use a separate Ecto namespace and map into `%Relyra.Connection{}` later. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]
- **Storing readiness as a free-form boolean:** a manually edited `runtime_ready` flag will drift from actual config state. Compute readiness from fields plus child cert presence instead. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]
- **Making certificates an embed or JSON array on `connections`:** Phase 07 explicitly locks certificates into a child table because rollover and provenance are lifecycle-heavy. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]
- **Letting schema structs cross the resolver boundary:** current runtime contracts and future Phase 08 expectations both reject that. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: lib/relyra/connection.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Enum lifecycle validation | Free-form string state machine | `Ecto.Enum` with explicit atoms and DB-backed dump values. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] | It keeps state transitions explicit in code and compatible with DB constraints. |
| Nested policy casting | Manual `Map.get/put` trees | `embeds_one` plus `cast_embed/3`. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] | Ecto already handles bounded nested validation and replacement semantics. |
| Uniqueness prechecks | `Repo.exists?` before insert as the only guard | Unique indexes plus `unique_constraint/3`. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | App-only checks race under concurrency; DB constraints do not. |
| FK error handling | Raw DB exceptions surfaced to callers | `foreign_key_constraint/2` and typed changeset errors. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] | Matches the repo’s typed-error discipline. [VERIFIED: lib/relyra/error.ex] |
| Runtime snapshot access | Passing schema structs to protocol code | A pure mapper from persisted rows to `%Relyra.Connection{}` and plain cert values. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/connection_resolver.ex] | Keeps runtime pure and testable. |

**Key insight:** Phase 07 should spend effort on clear domain boundaries and DB constraints, not on bespoke casting, ad hoc readiness flags, or a blob serializer. The repo already has the right adapter pattern; it now needs a real aggregate under it. [VERIFIED: lib/relyra/request_store/ecto.ex] [VERIFIED: lib/relyra/replay_store/ecto.ex] [VERIFIED: .planning/research/ARCHITECTURE.md]

## Common Pitfalls

### Pitfall 1: Colliding internal PK and public runtime ID

**What goes wrong:** the persistence layer stores an internal binary primary key in `:id`, but runtime code still derives public behavior from `connection.id` in some places. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: lib/relyra.ex]

**Why it happens:** `Relyra.Connection` currently uses `:id`, while Phoenix routing and telemetry already use `connection_id`; the two concepts have not been split yet. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/phoenix/router.ex] [VERIFIED: lib/relyra/telemetry.ex]

**How to avoid:** in Phase 07, keep persistence schema `id` as the internal `:binary_id`, but plan Phase 08 mapper work so the runtime snapshot’s `id` remains the public `connection_id` unless the runtime contract is intentionally migrated everywhere. Do not let resolver code pass the DB PK into `Relyra.Connection.id`. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]

**Warning signs:** replay keys, telemetry metadata, or ACS validation start showing opaque UUIDs where current tests and routes expect public `connection_id` values. [VERIFIED: lib/relyra.ex] [VERIFIED: test/relyra/telemetry_test.exs]

### Pitfall 2: Treating “draft-valid” as “runtime-ready”

**What goes wrong:** incomplete rows get saved and later treated as runnable because the same changeset is reused for draft and enable flows. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]

**Why it happens:** Ecto changesets make it easy to collapse validation into one function unless the phase intentionally splits paths. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**How to avoid:** create separate draft and enable paths and a pure readiness module that checks the exact fields Phase 08 needs to build `%Relyra.Connection{}` and verify signatures. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/security/signature.ex]

**Warning signs:** an enabled row exists with no `idp_sso_url`, no `sp_entity_id`, or no certificates. [VERIFIED: lib/relyra/connection.ex]

### Pitfall 3: Shipping schema work without a real migration test harness

**What goes wrong:** unit tests pass against fake repos, but migrations, constraints, and FK behavior are never exercised against a real Ecto SQL Repo. [VERIFIED: test/security/stores/request_store_ecto_test.exs] [VERIFIED: test/security/stores/replay_store_ecto_test.exs]

**Why it happens:** the repo currently has no `config/`, no test Repo module, and no `priv/repo/migrations/` tree. [VERIFIED: repo file scan] 

**How to avoid:** allocate explicit Wave 0 work for a minimal test Repo, sandbox setup, and migration case before implementing aggregate code. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]

**Warning signs:** planner tasks mention tables and constraints but no Repo module, no migration runner, and no integration tests. [VERIFIED: repo file scan]

### Pitfall 4: Following stale dependency guidance

**What goes wrong:** planner time is wasted “fixing” a `postgrex` incompatibility that no longer exists in this repo. [VERIFIED: mix.lock]

**Why it happens:** earlier research suggested `postgrex 0.22.x` was too new for `ecto_sql 3.13.5`, but the current repo lock proves `ecto_sql 3.13.5` is already resolved with `postgrex 0.22.0`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex]

**How to avoid:** treat current repo locks as the baseline for Phase 07 and keep dependency churn out of scope unless tests prove a real break. [VERIFIED: mix.lock]

**Warning signs:** tasks to downgrade `postgrex`, rewrite dependency ranges, or revisit stack selection without a failing build. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

## Code Examples

Verified patterns from official sources:

### Bounded embed plus child table

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Schema.html
schema "connections" do
  field :state, Ecto.Enum, values: [:draft, :enabled, :disabled]
  embeds_one :runtime_policy, RuntimePolicy, on_replace: :update
  has_many :certificates, ConnectionCertificate
end
```

This fits the locked hybrid aggregate and avoids putting certificate lifecycle data in JSON. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]

### DB uniqueness paired with changeset constraint

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
changeset
|> unique_constraint(:connection_id)
|> foreign_key_constraint(:connection_id)
```

This is the right pattern for public `connection_id` uniqueness and child-row FK surfacing. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

### Partial unique index for optional future invariants

```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Migration.html
create unique_index(:connections, [:connection_id])
create index(:connection_certificates, [:connection_id, :inserted_at])
create index(:connection_certificates, [:connection_id], where: "revoked_at IS NULL")
```

Phase 07 only requires the first two invariants now; the `where:` example is relevant if planner chooses a soft-delete or revocation column for child cert rows. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Earlier v0.2 stack research recommended `postgrex 0.19.x` because `0.22.x` looked incompatible. [VERIFIED: .planning/research/STACK.md] | The current repo already locks `postgrex 0.22.0` with `ecto_sql 3.13.5`, and `0.22.1` was published on 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex] | By 2026-01-10 in the repo lock, with `0.22.1` released 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex] | Phase 07 should not burn scope on a driver downgrade. |
| Single mutable trust-anchor field on the parent row. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] | Minimal child certificate inventory table with provenance/basic metadata now; staged rollover semantics later. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] | Locked in Phase 07 context on 2026-05-05. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] | The planner should model cert rows now so Phase 10 stays additive. |

**Deprecated/outdated:**
- “Blob-first config record” is outdated for this repo because it conflicts with the locked hybrid aggregate and Phase 08’s pure runtime snapshot boundary. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: .planning/research/ARCHITECTURE.md]

## Assumptions Log

All material claims in this document were verified against repo files, package metadata, Context7, or official docs in this session. No planner-confirmation assumptions are currently open. [VERIFIED: research session sources]

## Open Questions (RESOLVED)

1. **Where should reusable migration artifacts live in a library repo?**
   - Final decision: Phase 07 will ship canonical in-repo Ecto migration
     files under `priv/repo/migrations/` so the repo can run real
     migration and constraint tests now. Those files are the canonical
     artifacts for future host-app copy/adaptation as well; installer or
     template automation can layer on later without redefining the schema
     contract.

2. **What exact public `connection_id` format should be accepted?**
   - Final decision: Phase 07 will use a route-safe immutable ULID via
     `Ecto.ULID` for the public `connection_id`.
   - Rationale: it is globally unique, URL-safe for the existing
     `/:connection_id/*` surface, distinct from the internal `:binary_id`
     PK, and avoids ambiguous caller-supplied opaque strings.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile schemas, changesets, tests | ✓ [VERIFIED: `elixir --version`] | 1.19.5 | — |
| Erlang/OTP | Compile and run current repo | ✓ [VERIFIED: `elixir --version`] | 28 / erts-16.3 | — |
| Mix | Run tests and migrations | ✓ [VERIFIED: `mix --version`] | 1.19.5 | — |
| PostgreSQL client | Real migration/integration verification | ✓ [VERIFIED: `psql --version`] | 14.17 | Use fake Repo unit tests only for narrower logic, not for constraints. |
| Docker | Disposable DB for migration tests if preferred | ✓ [VERIFIED: `docker --version`] | 29.4.0 | Use local Postgres if already available. |

**Missing dependencies with no fallback:**
- None detected for planning. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- None detected for planning. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with repo-level aliases such as `mix qa` and `mix test`. [VERIFIED: mix.exs] [VERIFIED: test/test_helper.exs] |
| Config file | None today; there is no `config/` tree yet. [VERIFIED: repo file scan] |
| Quick run command | `mix test test/relyra/ecto/connection_record_test.exs test/relyra/ecto/runtime_readiness_test.exs` after Wave 0 adds those files. [VERIFIED: mix.exs] |
| Full suite command | `mix qa` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-01 | Create/update/disable connection records with separate draft and enable validation paths. [VERIFIED: .planning/ROADMAP.md] | unit | `mix test test/relyra/ecto/connection_record_test.exs` | ❌ Wave 0 |
| CFG-01 | Migrations create tables, indexes, unique constraints, and FK constraints. [VERIFIED: .planning/ROADMAP.md] | integration | `mix test test/relyra/ecto/migration_constraints_test.exs` | ❌ Wave 0 |
| CFG-01 | Invalid or incomplete config is rejected before runtime use. [VERIFIED: .planning/ROADMAP.md] | unit/integration | `mix test test/relyra/ecto/runtime_readiness_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** run the Phase 07-focused ecto tests plus `mix format --check-formatted`. [VERIFIED: mix.exs]
- **Per wave merge:** run `mix test --warnings-as-errors`. [VERIFIED: mix.exs]
- **Phase gate:** run `mix qa` before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/support/ecto_test_repo.ex` — minimal Repo for migration and schema integration tests. [VERIFIED: repo file scan]
- [ ] `config/test.exs` or equivalent test-only repo configuration — currently absent. [VERIFIED: repo file scan]
- [ ] `test/support/migration_case.ex` — helper to create/drop schema objects or run migrations deterministically. [VERIFIED: repo file scan]
- [ ] `test/relyra/ecto/connection_record_test.exs` — changeset and enum validation coverage for CFG-01.
- [ ] `test/relyra/ecto/runtime_readiness_test.exs` — draft-vs-enabled gating coverage for CFG-01.
- [ ] `test/relyra/ecto/migration_constraints_test.exs` — uniqueness/FK/index verification against a real Repo.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 07 stores trust config but does not authenticate end users directly. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Session establishment remains outside this phase. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Connection writes must remain tenant-scoped and should never infer tenant from user-controlled XML. [VERIFIED: CONVENTIONS.md] |
| V5 Input Validation | yes | Use Ecto changesets, `validate_required`, enum casting, embed casting, and strict enable-path validation. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] |
| V6 Cryptography | yes | Cert material must be validated against configured trust inputs; do not accept raw PEM blobs blindly for runtime use. [VERIFIED: SECURITY.md] [VERIFIED: lib/relyra/security/signature.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public `connection_id` collision or reassignment | Spoofing | Global unique index on `connection_id`; immutable-once-set changeset rule. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Draft row accidentally used at runtime | Elevation of privilege | Separate enable validation path plus resolver fail-closed readiness check. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] |
| Cross-tenant child row insertion | Tampering | Binary-id FK plus `foreign_key_constraint/2` and tenant-scoped command paths. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Certificate blob drift without provenance | Repudiation | Immutable child cert rows with fingerprint/basic metadata and source/provenance fields. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] |
| Logging raw trust material during validation errors | Information disclosure | Keep typed errors and avoid logging raw certs/XML; the project already treats trust inputs as sensitive. [VERIFIED: SECURITY.md] [VERIFIED: lib/relyra/error.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` - locked decisions, canonical refs, and phase boundary. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md]
- `.planning/ROADMAP.md` - Phase 07 success criteria and milestone ordering. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `CFG-01` scope anchor. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` - host-DB ownership, runtime boundary, and milestone constraints. [VERIFIED: .planning/PROJECT.md]
- `lib/relyra/connection.ex`, `lib/relyra/connection_resolver.ex`, `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/security/signature.ex`, `lib/relyra/phoenix/router.ex`, `lib/relyra/phoenix/controllers/login_controller.ex`, `lib/relyra/phoenix/controllers/metadata_controller.ex`, `lib/relyra/provider*.ex` - current runtime contract and lookup assumptions. [VERIFIED: repo source files]
- `mix.exs`, `mix.lock`, `mix hex.info ecto`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, `mix hex.info jason` - actual dependency declarations, lock state, and release dates. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info postgrex] [VERIFIED: mix hex.info jason]
- Context7 `/websites/hexdocs_pm_ecto` - `Ecto.Schema`, `Ecto.Changeset`, `Ecto.Enum`, embedded schemas, `cast_embed`, and constraint APIs. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html]
- Official `Ecto.Migration` docs - indexes, references, and `where:` partial-index support. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]

### Secondary (MEDIUM confidence)

- `.planning/research/ARCHITECTURE.md`, `.planning/research/STACK.md`, `.planning/research/SUMMARY.md` - earlier v0.2 design direction, cross-checked against the current repo and updated where stale. [VERIFIED: .planning/research/ARCHITECTURE.md] [VERIFIED: .planning/research/STACK.md] [VERIFIED: .planning/research/SUMMARY.md]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified against current `mix.lock` and live Hex package metadata, not memory. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info postgrex] [VERIFIED: mix hex.info jason]
- Architecture: HIGH - driven by locked Phase 07 decisions plus current runtime code paths. [VERIFIED: .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md] [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/connection_resolver.ex]
- Pitfalls: HIGH - each pitfall ties back to concrete repo code or current missing infrastructure. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: mix.exs] [VERIFIED: repo file scan]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04 for architecture and 2026-05-12 for package-version currency.
