# Phase 11: Mapping persistence + audit hardening - Research

**Researched:** 2026-05-05 [VERIFIED: current date]  
**Domain:** Durable authorization mapping persistence and append-only audit history for trust-bearing configuration changes [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: based on codebase inspection, current Hex package metadata, current official Ecto docs, and local environment checks]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all content in this block: `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

### Locked Decisions

## Implementation Decisions

### Mapping persistence model
- **D-01:** Persist mapping as first-class child records keyed by the internal `connection_record_id`, not as JSON/blob fields on `relyra_connections` and not as code-only adapter logic.
- **D-02:** Use separate live persistence surfaces for attribute mappings and group mappings so validation, diffing, and operator review stay explicit.
- **D-03:** Add an append-only mapping revision ledger that records actor, action, cause, and before/after mapping snapshots for every applied mapping change.
- **D-04:** Runtime must continue to consume normalized plain values only. The Ecto resolver/snapshot boundary hydrates mapping config into runtime-safe maps/structs; Ecto rows must not leak into `Relyra.UserMapper` consumers.
- **D-05:** Keep `Relyra.UserMapper` as the extension seam, but make persisted normalized mapping config the default input path rather than hardcoded per-tenant code branches.

### Mapping scope and semantics
- **D-06:** Phase 11 mapping scope is bounded and explicit: exact attribute-name mapping, exact group/role extraction, and explicit multivalue handling only.
- **D-07:** Do not introduce regex, scripts, or expression-language mapping in v0.2. Advanced transform power is deferred unless real adopter demand proves the extra support burden is worth it.
- **D-08:** Mapping targets and behaviors should be constrained by enums and validated fields, not arbitrary free-form destinations.
- **D-09:** Multivalue behavior must be explicit and deterministic. Planning should choose bounded strategies such as `first`, `all`, or a similarly explicit equivalent rather than implicit ad hoc behavior.
- **D-10:** Mapping updates should avoid generic replace-all association writes from parent connection changesets. Use dedicated command/service flows so concurrency, attribution, and diff capture remain intentional.

### Durable audit boundary
- **D-11:** Introduce a separate append-only cross-domain audit ledger for trust-bearing config changes. Do not stretch `relyra_metadata_revisions` into the final global audit system.
- **D-12:** Keep `relyra_metadata_revisions` as metadata-specific provenance only. It remains authoritative for metadata lifecycle history, while the new audit ledger becomes the review surface across domains.
- **D-13:** The audit ledger must cover at least connection lifecycle changes, metadata apply/refresh outcomes that mutate live trust state, certificate lifecycle transitions, and mapping mutations.
- **D-14:** Telemetry and logs remain supplemental observability only. They are not authoritative audit history.
- **D-15:** Audit payloads must be redaction-safe and bounded by default: hashes, fingerprints, counts, selected changed fields, and normalized summaries rather than raw XML, PEMs, private keys, or unbounded schema dumps.

### Audit capture architecture
- **D-16:** Capture audit at the centralized persistence orchestration boundary around trust-changing transactional writes, not in schema callbacks, controller edges, DB triggers, or async reconstruction.
- **D-17:** Each authoritative trust mutation path should insert its audit row in the same transaction as the write so audit history and committed state cannot drift.
- **D-18:** Restrict authoritative trust mutations to explicit command/orchestration modules such as `Relyra.Ecto.Connections`, `Relyra.Ecto.MetadataApply`, `Relyra.Ecto.CertificateInventory`, and the future mapping persistence command surface.
- **D-19:** Audit rows must capture `actor`, `cause`, and optional `correlation_id` explicitly; never rely on ambient process state or request-only context.
- **D-20:** Audit should capture normalized `before` and `after` trust views plus a bounded diff. Do not diff raw params and do not require replaying audit history to rebuild runtime state.
- **D-21:** Use `Repo.transact/1` by default for straight-line audited commands; use `Ecto.Multi` where named steps or dynamic operation sets materially improve clarity.

### the agent's Discretion
- Exact module names and file layout for mapping schemas, mapping revision writers, audit event writers, and snapshot hydration helpers.
- Exact split between attribute-mapping and group-mapping tables, provided mapping state remains explicit, normalized, and operator-reviewable.
- Exact runtime field name for normalized mapping data on the resolved snapshot, provided runtime consumers stay persistence-agnostic.
- Exact audit event taxonomy and diff representation, provided actions stay typed, bounded, and coherent across connection, metadata, certificate, and mapping domains.

### Deferred Ideas (OUT OF SCOPE)
- Expression-language, regex, or script-based mapping transforms.
- Full admin UI workflows, previews, and rollback UX beyond the persistence/audit foundations needed now.
- Structured audit export / SIEM pipelines as a first-class product surface.
- GSD-wide default tuning so recommendation-first, auto-resolve discussion becomes the standard path except for genuinely high-impact decisions.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement text copied from `.planning/REQUIREMENTS.md`. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-05 | User can persist attribute/group mapping configuration and review a durable audit history of trust changes. [VERIFIED: .planning/REQUIREMENTS.md] | This research defines the standard persistence model, transactional audit capture boundary, runtime snapshot seam, validation/test expectations, and security constraints needed to implement Phase 11 without breaking the existing resolver and trust lifecycle model. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/user_mapper.ex] |
</phase_requirements>

## Summary

Phase 11 should be planned as an extension of the repo's current persistence architecture, not as a new subsystem. The existing code already centralizes trust-bearing writes in explicit Ecto command modules, resolves runtime state through `ConnectionLoader` plus `ConnectionSnapshot`, and keeps runtime consumers on pure values rather than Ecto structs. Phase 11 should preserve that shape: add relational mapping tables, append-only mapping revisions, and a separate append-only audit ledger inserted from the same transaction boundary as the trust mutation. [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: lib/relyra/ecto/metadata_apply.ex] [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [VERIFIED: lib/relyra/ecto/connection_loader.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

The most important planning constraint is write-boundary discipline. Mapping rows must not be written through generic parent `cast_assoc` flows, and audit rows must not be reconstructed later from logs or callbacks. This repo already rejected generic certificate mutation through parent connection writes, and Ecto’s current docs recommend `Repo.transact/2` for straightforward transactional flows while reserving `Ecto.Multi` for clearer named or dynamic steps. Phase 11 should follow that exact pattern for mapping mutations and audit insertion. [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

The current runtime seam also means mapping persistence is not just a schema phase. `%Relyra.Connection{}` currently has no mapping field, `Relyra.ConnectionResolver.Ecto` returns only a pure runtime struct, and `Relyra.UserMapper.DefaultAttribute` still hardcodes claim fallbacks. Planning therefore needs at least one slice for storage, one for snapshot normalization plus mapper integration, and one for cross-domain audit hardening across connection, metadata, certificate, and mapping command surfaces. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/connection_resolver/ecto.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: .planning/ROADMAP.md]

**Primary recommendation:** Use four new persistence surfaces and no new framework: `attribute_mappings`, `group_mappings`, `mapping_revisions`, and `audit_events`, all written through explicit Ecto command modules and hydrated into normalized plain mapping config at the snapshot boundary before `Relyra.UserMapper` runs. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/user_mapper.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist per-connection attribute mapping rows | Database / Storage | API / Backend | Mapping state is durable trust configuration keyed by `connection_record_id`, so relational rows with FK and uniqueness rules are the authoritative source. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Persist per-connection group mapping rows | Database / Storage | API / Backend | Group-to-role extraction is also durable trust config and must stay explicit and reviewable rather than embedded in opaque blobs. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Apply mapping mutation commands and write revisions | API / Backend | Database / Storage | Attribution, diff capture, concurrency policy, and write ordering belong in explicit Ecto command/orchestration modules. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: lib/relyra/ecto/metadata_apply.ex] |
| Hydrate normalized mapping config into runtime-safe values | API / Backend | Database / Storage | The repo already enforces a persistence-to-runtime snapshot seam, so mapping normalization belongs alongside `ConnectionSnapshot`, not in runtime protocol or Phoenix code. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/connection_resolver/ecto.ex] |
| Record cross-domain trust audit history | Database / Storage | API / Backend | Audit rows are durable review history and must commit in the same transaction as state changes, but event shape and orchestration live in backend modules. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Enforce mapping validation and bounded semantics | API / Backend | Database / Storage | Ecto changesets and enums should reject invalid mapping targets or multivalue strategies before rows commit, while DB constraints backstop uniqueness and FK integrity. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | Repo constraint `~> 3.13`; locked `3.13.5`; latest `3.13.6` published `2026-05-05`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] | Schemas, changesets, `Ecto.Enum`, optimistic locking, and transaction orchestration for mapping rows, revision rows, and audit rows. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | The repo already uses Ecto for connection, metadata, and certificate trust state, so Phase 11 should stay on the same persistence contract. [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: lib/relyra/ecto/metadata_revision.ex] [VERIFIED: lib/relyra/ecto/certificate.ex] |
| Ecto SQL | Repo constraint `~> 3.13`; locked `3.13.5`; latest `3.13.5` published `2026-03-03`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] | Migrations, indexes, FK constraints, and partial indexes for mapping and audit tables. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | Phase 11 is primarily schema and transaction-boundary work inside the current Postgres-backed Ecto model. [VERIFIED: priv/repo/migrations/20260505120000_create_relyra_connections.exs] [VERIFIED: priv/repo/migrations/20260505130200_create_relyra_metadata_revisions.exs] |
| Postgrex | Locked `0.22.0`; latest `0.22.1` published `2026-05-05`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex] | Postgres adapter for migration and integration-test coverage of audited trust mutations. | The test harness already boots a Postgres sandbox repo and runs migrations against it. [VERIFIED: test/support/ecto_test_repo.ex] [VERIFIED: test/support/migration_case.ex] |
| Telemetry | Declared `~> 1.3`; locked `1.4.1`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Supplemental operational events around mapping and audit writes. [VERIFIED: lib/relyra/telemetry.ex] | Telemetry already exists for runtime flows, but Phase 11 should keep it supplemental and not confuse it with the durable audit ledger. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | Locked `1.4.4`. [VERIFIED: mix.lock] | Optional storage of bounded diff payloads and normalized summaries in `:map` columns. | Use only for compact redaction-safe summaries or diffs, not for raw XML, PEM, or full unbounded snapshots. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Phoenix | Locked `1.8.5`. [VERIFIED: mix.lock] | Existing runtime consumers of resolved connection snapshots. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex] | Phase 11 should not introduce Phoenix-specific storage logic; only verify downstream compatibility. [VERIFIED: .planning/ROADMAP.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Child mapping tables | JSON or embed fields on `relyra_connections` | Locked decisions explicitly reject blob-style mapping persistence because review, diffing, and validation need first-class explicit records. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Dedicated command modules with `Repo.transact/2` | Schema callbacks, DB triggers, or controller-edge audit writes | Locked decisions require centralized orchestration boundaries, and current Ecto docs deprecate `Repo.transaction/2` in favor of `Repo.transact/2`. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Separate `audit_events` ledger | Reusing `relyra_metadata_revisions` for every trust change | Locked decisions keep metadata provenance and cross-domain audit as separate concerns. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Bounded enums for target and multivalue policy | Free-form transform DSL | Locked Phase 11 scope excludes regex, expressions, and scripts to avoid support and review complexity in v0.2. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |

**Installation:** no new library is required for the recommended Phase 11 design; use the existing optional persistence stack already declared in [`mix.exs`](/Users/jon/projects/relyra/mix.exs:1). [VERIFIED: mix.exs]

```bash
mix deps.get
```

**Version verification:** current package metadata was verified on 2026-05-05 with `mix hex.info ecto`, `mix hex.info ecto_sql`, and `mix hex.info postgrex`. [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info postgrex]

## Architecture Patterns

### System Architecture Diagram

```text
connection / metadata / certificate / mapping command
                    |
                    v
       explicit Ecto orchestration boundary
  - validate input
  - load current aggregate
  - compute normalized before view
  - apply targeted trust mutation
  - insert mapping revision or audit event
                    |
                    v
          Repo.transact / Ecto.Multi
                    |
    +---------------+-----------------------------+
    |               |                             |
    v               v                             v
mapping tables   mapping revisions         audit_events ledger
    |               |                             |
    +---------------+-----------------------------+
                    |
                    v
     ConnectionLoader preload + snapshot hydrate
                    |
                    v
 normalized runtime connection + normalized mapping config
                    |
                    v
           Relyra.UserMapper consumers
```

The core dataflow above is already consistent with the repo’s Phase 08 snapshot seam and the locked Phase 11 decision that runtime must remain plain-data only. [VERIFIED: lib/relyra/ecto/connection_loader.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

### Recommended Project Structure

```text
lib/relyra/
├── ecto/
│   ├── attribute_mapping.ex          # live attribute mapping rows
│   ├── group_mapping.ex              # live group mapping rows
│   ├── mapping_revision.ex           # append-only mapping change history
│   ├── audit_event.ex                # append-only cross-domain trust audit
│   ├── mapping_commands.ex           # explicit mapping write boundary
│   ├── audit_writer.ex               # shared audit insertion helpers
│   ├── connection_loader.ex          # preload live mappings for snapshot hydration
│   └── connection_snapshot.ex        # normalize mapping rows into runtime-safe values
└── user_mapper/
    └── default_attribute.ex          # consume normalized mapping config by default
test/relyra/ecto/
├── mapping_commands_test.exs
├── mapping_revision_schema_test.exs
├── audit_event_schema_test.exs
├── audit_hardening_test.exs
└── mapping_snapshot_test.exs
```

The names above are recommendations, not locked names, but the responsibility split is required by the Phase 11 decisions and by the repo’s existing command-plus-snapshot architecture. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: lib/relyra/ecto/metadata_apply.ex] [VERIFIED: lib/relyra/ecto/certificate_inventory.ex]

### Pattern 1: Explicit live mapping rows plus append-only mapping revisions

**What:** Keep current live mapping state in dedicated child tables keyed by `connection_record_id`, and write every applied mapping mutation to a separate append-only revision ledger containing actor, cause, action, and bounded before/after snapshots. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

**When to use:** Any create, replace, or targeted update of connection-scoped attribute or group mappings. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
repo.transact(fn ->
  # load current mapping rows
  # write targeted live-row changes
  # insert append-only mapping revision
  {:ok, result}
end)
```

### Pattern 2: Snapshot hydration owns persistence-to-runtime mapping normalization

**What:** Preload live mapping rows with the connection aggregate, then normalize them into plain runtime-safe config before `Relyra.UserMapper` sees them. Runtime consumers should never receive Ecto structs or associations. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

**When to use:** Resolver hydration, login-time mapping, metadata export compatibility checks, and any future admin preview flow that needs effective runtime config. [VERIFIED: lib/relyra/connection_resolver/ecto.ex] [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex]

**Example:**

```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex
runtime_attrs =
  connection
  |> base_runtime_attrs()
  |> apply_provider_defaults(connection.provider_preset)
```

Phase 11 should extend this existing normalization seam with mapping config rather than adding a second runtime reconstruction path. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex]

### Pattern 3: Cross-domain audit insertion from the authoritative write boundary

**What:** Insert `audit_events` rows from the same command transaction that commits the trust mutation, capturing normalized before/after summaries and a bounded diff. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

**When to use:** Connection lifecycle changes, metadata apply/refresh outcomes that alter live trust, certificate lifecycle transitions, and mapping mutations. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.run(:before_view, fn _repo, _changes -> {:ok, before_view} end)
|> Ecto.Multi.update(:mutation, changeset)
|> Ecto.Multi.insert(:audit_event, audit_changeset)
```

Use `Ecto.Multi` only when the named-step structure materially improves clarity over straight-line `repo.transact(fn -> ... end)`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Anti-Patterns to Avoid

- **Generic parent association replacement for mappings:** The repo already had to block generic certificate updates from parent connection writes, and Phase 11 locks the same posture for mappings. [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]
- **Audit-from-logs reconstruction:** Logs and telemetry are supplemental only and cannot be the authoritative trust history. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/log.ex] [VERIFIED: lib/relyra/telemetry.ex]
- **Leaking Ecto rows into `Relyra.UserMapper`:** The current repo keeps runtime connection resolution pure; mapping config should follow the same rule. [VERIFIED: lib/relyra/connection_resolver/ecto.ex] [VERIFIED: lib/relyra/user_mapper.ex]
- **Free-form mapping semantics in v0.2:** Regex, expressions, and scripts are explicitly deferred. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction coordination for trust-bearing writes | Manual “do X, then if Y fails undo X” control flow | `Repo.transact/2` and selective `Ecto.Multi` composition [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Audit and state rows must commit or roll back together. [VERIFIED: lib/relyra/ecto/metadata_apply.ex] |
| Enum-style mapping validation | Stringly typed free-form targets and behaviors | `Ecto.Enum` and bounded changesets [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] | Phase 11 locks explicit targets and multivalue semantics. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Global audit via callbacks or DB triggers | Hidden write hooks | Explicit audit insertion at command-module boundaries | The planner needs traceable and testable trust mutation flows, not hidden side effects. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Full-state raw payload storage in audit | XML/PEM/private-key dumps | Redaction-safe summaries, hashes, fingerprints, counts, and selected changed fields | Locked decisions require bounded, reviewable, safe payloads. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/log.ex] |

**Key insight:** The risky engineering in Phase 11 is not schema creation by itself; it is preserving one authoritative trust mutation path per domain while making the resulting state human-reviewable without leaking sensitive material. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Replace-all mapping writes erase attribution and create concurrency footguns
**What goes wrong:** A parent connection update treats mapping associations as canonical and silently deletes omitted rows or rewrites them without targeted attribution. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Why it happens:** `cast_assoc` flows optimize for aggregate replacement, not for trust-reviewed partial mutations with revision history. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]  
**How to avoid:** Use dedicated mapping command functions that load current rows, compute a normalized before view, apply intended row changes, and insert revision plus audit records in the same transaction. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Warning signs:** Plans mention “submit the full mapping list with the connection update” or omit any mapping-specific service boundary. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

### Pitfall 2: Treating metadata revisions as the global audit system
**What goes wrong:** Cross-domain review becomes fragmented or misleading because metadata provenance rows are overloaded to represent unrelated certificate, connection, or mapping mutations. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Why it happens:** `relyra_metadata_revisions` already exists and looks audit-like, so it is tempting to reuse it. [VERIFIED: lib/relyra/ecto/metadata_revision.ex]  
**How to avoid:** Keep metadata provenance authoritative for metadata only and add a separate `audit_events` ledger for cross-domain trust review. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Warning signs:** Plans propose adding certificate or mapping actions to `MetadataRevision.outcome` or reusing its schema directly. [VERIFIED: lib/relyra/ecto/metadata_revision.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

### Pitfall 3: Raw payload audit storage leaks sensitive trust material
**What goes wrong:** Audit history becomes a second sensitive-data store containing XML, PEM, or key-like material that operators did not need to review. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/log.ex]  
**Why it happens:** Raw params are easy to persist and diff, especially when command handlers already receive them. [VERIFIED: lib/relyra/ecto/metadata_apply.ex]  
**How to avoid:** Capture normalized before/after trust views, bounded diffs, and references such as revision IDs or fingerprints instead of raw request payloads. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Warning signs:** Proposed audit schema includes `xml`, `pem`, `metadata_xml`, or unconstrained `params` blobs. [VERIFIED: lib/relyra/log.ex]

### Pitfall 4: Snapshot drift between stored mappings and mapper consumers
**What goes wrong:** Live mapping rows exist, but `Relyra.UserMapper` still uses hardcoded defaults or receives persistence-shaped data that bypasses normalization. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]  
**Why it happens:** Storage work ships first and runtime integration is deferred or split incorrectly. [VERIFIED: lib/relyra/connection.ex]  
**How to avoid:** Plan a distinct snapshot-plus-mapper slice that makes persisted normalized mapping config the default input path while keeping the existing extension seam. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/user_mapper.ex]  
**Warning signs:** The plan creates tables and tests them, but no resolver, snapshot, or `UserMapper` tests change. [VERIFIED: lib/relyra/connection_resolver/ecto.ex] [VERIFIED: test/relyra/telemetry_test.exs]

## Code Examples

Verified patterns from official or existing sources:

### Straight-line authoritative trust mutation with `Repo.transact/2`

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
repo.transact(fn ->
  {:ok, result}
end)
```

Current Ecto docs mark `Repo.transaction/2` as deprecated and recommend `Repo.transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Named-step transaction when audit insertion benefits from explicit step identities

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:mapping_revision, mapping_revision_changeset)
|> Ecto.Multi.insert(:audit_event, audit_event_changeset)
```

Current Ecto docs say `Ecto.Multi` is most useful when operation sets are dynamic or named-step clarity matters. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Existing repo pattern for pure runtime snapshot construction

```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex
runtime_attrs =
  connection
  |> base_runtime_attrs()
  |> apply_provider_defaults(connection.provider_preset)
```

Phase 11 should extend this pattern with normalized mapping config rather than bypassing it. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` as the default transaction API | `Repo.transact/2` is the current Ecto-recommended transaction API, and `transaction/2` is documented as deprecated. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Ecto docs current as of 2026-05-05. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Phase 11 plans should default to `Repo.transact/2` for audited command flows. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Runtime mappers hardcoded in code branches | Persisted per-connection mapping config feeding a stable mapper seam. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | Phase 11 target state. [VERIFIED: .planning/ROADMAP.md] | Trust-bearing authz config becomes reviewable, testable, and operator-managed. [VERIFIED: .planning/PROJECT.md] |
| Domain-specific ledgers only | Separate domain provenance plus a cross-domain audit ledger. [VERIFIED: lib/relyra/ecto/metadata_revision.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | Phase 11 target state. [VERIFIED: .planning/ROADMAP.md] | Operators get one durable review surface for trust mutations without losing metadata-specific history. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |

**Deprecated/outdated:**
- `Repo.transaction/2` as the default style for new code: current Ecto docs deprecate it in favor of `Repo.transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Hardcoded default-only mapping behavior as the main path: current repo still has it, but Phase 11 decisions replace it with persisted normalized mapping config as the default input path. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]

## Assumptions Log

All material claims in this research were verified against the local codebase, local environment, or official current docs during this session. [VERIFIED: file reads, command output, and official docs lookup]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The research remains planning-valid until 2026-06-04 if package versions and docs are not re-checked sooner. [ASSUMED] | Metadata | Low; the planner may rely on slightly stale package/doc timing guidance if Phase 11 is delayed. |

## Open Questions (RESOLVED)

1. **What is the exact runtime field that carries normalized mapping config?**
   - Resolution: extend `%Relyra.Connection{}` with a plain `:mapping_config` field populated only by `Relyra.Ecto.ConnectionSnapshot`. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-01-PLAN.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-03-PLAN.md]
   - Why this path: it preserves the existing pure runtime contract, keeps resolver output as a single normalized runtime struct, and lets `Relyra.UserMapper` consume persisted config without any Ecto-row leakage. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/user_mapper.ex]
   - Planning consequence: Phase 11 should update `%Relyra.Connection{}` and the snapshot/loader seam, not introduce a sibling runtime snapshot object or a separate mapper-only side channel. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-03-PLAN.md]

2. **How granular should the audit taxonomy be in v0.2?**
   - Resolution: keep a small typed taxonomy split across `domain` plus `action`, with domains at least `:connection`, `:metadata`, `:certificate`, and `:mapping`, and actions such as `:create`, `:update`, `:enable`, `:disable`, `:apply`, `:stage`, `:promote`, `:retire`, `:rollback`, `:replace_attribute_mappings`, and `:replace_group_mappings`. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-02-PLAN.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-03-PLAN.md]
   - Why this path: it satisfies D-13 and D-20 with explicit reviewable event types while avoiding free-form string taxonomies or domain-specific one-off schemas. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md]
   - Planning consequence: use stable enums or equivalently bounded values for `domain` and `action`, and capture normalized before/after trust views plus bounded diffs in the same transaction as the authoritative write. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix compile/test and Ecto command modules | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Test and migration commands | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI (`psql`) | Local DB-backed migration and integration tests | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Local PostgreSQL server | `Relyra.TestSupport.EctoTestRepo` bootstrap and sandbox-backed tests | ✓ [VERIFIED: `pg_isready`] | accepting on `/tmp:5432` [VERIFIED: `pg_isready`] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment checks above]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment checks above]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs] [VERIFIED: `elixir --version`] |
| Config file | [`test/test_helper.exs`](/Users/jon/projects/relyra/test/test_helper.exs:1) plus [`config/test.exs`](/Users/jon/projects/relyra/config/test.exs:1). [VERIFIED: file reads] |
| Quick run command | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs` [VERIFIED: repo uses `mix test` and file-specific ExUnit patterns in existing suite] |
| Full suite command | `mix test` [VERIFIED: mix project conventions and existing test layout] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-05 | Persist attribute mappings per connection with bounded validation and deterministic multivalue behavior. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | integration | `mix test test/relyra/ecto/mapping_commands_test.exs -x` | ❌ Wave 0 |
| CFG-05 | Persist group mappings per connection without leaking Ecto rows into runtime/mapper consumers. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | integration | `mix test test/relyra/ecto/mapping_snapshot_test.exs -x` | ❌ Wave 0 |
| CFG-05 | Record append-only mapping revisions with actor, cause, action, and bounded before/after snapshots. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | integration | `mix test test/relyra/ecto/mapping_revision_schema_test.exs -x` | ❌ Wave 0 |
| CFG-05 | Record durable audit events for trust-bearing connection, metadata, certificate, and mapping mutations in the same transaction as the mutation. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | integration | `mix test test/relyra/ecto/audit_hardening_test.exs -x` | ❌ Wave 0 |
| CFG-05 | Keep metadata provenance and cross-domain audit separate. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] | unit/integration | `mix test test/relyra/ecto/audit_event_schema_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/mapping_snapshot_test.exs`
- **Per wave merge:** `mix test test/relyra/ecto`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/relyra/ecto/mapping_commands_test.exs` — live row persistence, targeted updates, and multivalue validation for CFG-05. [VERIFIED: file absent from `rg --files test/relyra/ecto`]
- [ ] `test/relyra/ecto/mapping_snapshot_test.exs` — snapshot hydration and `UserMapper` default-path integration for CFG-05. [VERIFIED: file absent from `rg --files test/relyra/ecto`]
- [ ] `test/relyra/ecto/mapping_revision_schema_test.exs` — append-only mapping revision schema and bounded payload validation for CFG-05. [VERIFIED: file absent from `rg --files test/relyra/ecto`]
- [ ] `test/relyra/ecto/audit_event_schema_test.exs` — cross-domain audit schema validation and redaction boundaries for CFG-05. [VERIFIED: file absent from `rg --files test/relyra/ecto`]
- [ ] `test/relyra/ecto/audit_hardening_test.exs` — same-transaction audit insertion for connection, metadata, certificate, and mapping trust mutations. [VERIFIED: file absent from `rg --files test/relyra/ecto`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: host app owns generic auth domain per project scope] | Host application authentication is out of scope for Relyra; Phase 11 only requires explicit actor attribution passed into trust mutation commands. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: Phase 11 does not alter session establishment semantics] | Existing session work stays outside this phase. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | yes [VERIFIED: mapping and trust changes are multi-tenant admin actions] | Restrict trust-bearing writes to explicit command surfaces and always record actor identity, cause, and connection scope. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: mapping targets, enums, and multivalue policies require bounded validation] | Ecto changesets plus `Ecto.Enum` and FK/unique constraints. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |
| V6 Cryptography | yes [VERIFIED: audit payloads include hashes/fingerprints and must avoid raw key material] | Reuse existing fingerprint/hash material and redaction rules; never hand-roll crypto or store raw secrets in audit rows. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/log.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mapping row update grants overbroad local roles | Elevation of Privilege | Constrain mapping targets and multivalue strategies with enums and changesets, and version every applied change. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Trust mutation path bypasses audit insertion | Repudiation / Tampering | Only allow authoritative trust changes through explicit Ecto command modules that insert audit rows in the same transaction. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |
| Audit payload stores XML, PEM, or private key material | Information Disclosure | Store bounded summaries, fingerprints, and references only, aligned with existing redaction posture. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/log.ex] |
| Replace-all mapping writes delete rows silently under concurrency | Tampering / Denial of Service | Use targeted command flows plus optimistic locking or explicit reload-and-compare discipline at the command boundary. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Cross-tenant mapping change written against the wrong connection scope | Elevation of Privilege | Key every live row and revision to `connection_record_id`, resolve by connection first, and include connection identity in audit metadata. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` - locked Phase 11 scope, decisions, and audit boundary. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - `CFG-05` requirement text. [VERIFIED: local file]
- `.planning/PROJECT.md` - product constraints, audit expectations, and multi-tenant scope. [VERIFIED: local file]
- [`lib/relyra/ecto/connections.ex`](/Users/jon/projects/relyra/lib/relyra/ecto/connections.ex:1) - current explicit connection command surface. [VERIFIED: local file]
- [`lib/relyra/ecto/metadata_apply.ex`](/Users/jon/projects/relyra/lib/relyra/ecto/metadata_apply.ex:1) - current transactional metadata write surface. [VERIFIED: local file]
- [`lib/relyra/ecto/certificate_inventory.ex`](/Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex:1) - current transactional certificate lifecycle surface. [VERIFIED: local file]
- [`lib/relyra/ecto/connection_loader.ex`](/Users/jon/projects/relyra/lib/relyra/ecto/connection_loader.ex:1) and [`lib/relyra/ecto/connection_snapshot.ex`](/Users/jon/projects/relyra/lib/relyra/ecto/connection_snapshot.ex:1) - current aggregate preload and runtime hydration seam. [VERIFIED: local files]
- [`lib/relyra/user_mapper.ex`](/Users/jon/projects/relyra/lib/relyra/user_mapper.ex:1) and [`lib/relyra/user_mapper/default_attribute.ex`](/Users/jon/projects/relyra/lib/relyra/user_mapper/default_attribute.ex:1) - current mapping seam and hardcoded default behavior. [VERIFIED: local files]
- https://hexdocs.pm/ecto/Ecto.Repo.html - current `Repo.transact/2` guidance and `transaction/2` deprecation. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Multi.html - current named-step transaction guidance. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Changeset.html - validation and optimistic locking guidance. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Schema.html - schema and `Ecto.Enum` support. [CITED: official docs]
- https://hexdocs.pm/ecto_sql/Ecto.Migration.html - migration and index guidance. [CITED: official docs]

### Secondary (MEDIUM confidence)
- `mix hex.info ecto` - current locked and latest Ecto package versions as of 2026-05-05. [VERIFIED: local command]
- `mix hex.info ecto_sql` - current locked and latest Ecto SQL package versions as of 2026-05-05. [VERIFIED: local command]
- `mix hex.info postgrex` - current locked and latest Postgrex package versions as of 2026-05-05. [VERIFIED: local command]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research used local code, local environment, and official docs only]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing repo dependencies and current official docs agree, and local `mix hex.info` verified current versions. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info postgrex]
- Architecture: HIGH - the current repo already implements the same command-boundary and snapshot seams this phase must extend. [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: lib/relyra/ecto/metadata_apply.ex] [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex]
- Pitfalls: HIGH - the main failure modes are directly implied by locked decisions and current code shape, especially replace-all writes, log-only audit, and runtime leakage. [VERIFIED: .planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md] [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: lib/relyra/log.ex]

**Research date:** 2026-05-05 [VERIFIED: current date]  
**Valid until:** 2026-06-04 for repo-specific architecture; re-verify package versions and official docs sooner if Phase 11 planning is delayed. [VERIFIED: current date] [ASSUMED]
