# Phase 08: Resolver adapter + snapshotting - Research

**Researched:** 2026-05-05 [VERIFIED: current date]
**Domain:** Ecto-backed runtime snapshot hydration for persisted SAML connections [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: based on codebase inspection, current official docs, current Hex metadata, and passing local baseline tests]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all content in this block: `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]

### Locked Decisions
## Implementation Decisions

### Adapter shape and internal architecture
- **D-01:** Ship a built-in `Relyra.ConnectionResolver.Ecto` adapter as the Phase 08 path for persisted connections.
- **D-02:** Keep `Relyra.ConnectionResolver.Ecto` thin. It should own request-context orchestration and typed error return shape, not inline aggregate query + normalization logic.
- **D-03:** Delegate aggregate loading and snapshot construction to an internal persistence-side service/hydrator module. One module owns preload/query rules and one authoritative normalization path from Ecto aggregate to runtime snapshot.
- **D-04:** Do not leak Ecto schemas or associations above this internal seam. Runtime and protocol code receive only pure values.

### Snapshot normalization depth
- **D-05:** The resolver boundary returns a fully normalized runtime snapshot, not a partially filled `%Relyra.Connection{}` that later callers must finish normalizing.
- **D-06:** Provider preset defaults and other strict runtime defaults should be applied before the snapshot leaves the resolver boundary so login, ACS, metadata, telemetry, and future consumers all see the same effective config.
- **D-07:** Snapshot construction is the single authority for derived runtime fields and default expansion. Do not duplicate defaulting logic across controllers, metadata rendering, or protocol modules.
- **D-08:** The runtime snapshot should optimize for principle of least surprise: persisted aggregate in, effective `%Relyra.Connection{}` out.

### Runtime certificate contract
- **D-09:** Canonicalize the runtime snapshot on `idp_certificates` as the long-term field representing trusted IdP signing certificates.
- **D-10:** Keep `cert_chain` accepted only as temporary compatibility glue at the resolver/input boundary during migration. It should not remain a co-equal first-class runtime contract indefinitely.
- **D-11:** Update resolver docs, examples, tests, and built-in adapters toward the canonical `idp_certificates` field so future phases build on one certificate concept, not two names for the same thing.
- **D-12:** This naming decision should stay compatible with later certificate inventory and rollover work: the runtime snapshot consumes the active trust set, while persistence can keep richer lifecycle metadata in Phase 10.

### Failure taxonomy and diagnostics
- **D-13:** Use a layered resolver error model: a bounded set of public `%Relyra.Error{type, message, details}` classes with structured subreasons in `details`.
- **D-14:** Prefer a small stable top-level taxonomy such as `:connection_unavailable`, `:connection_invalid`, `:resolver_misconfigured`, and `:resolver_failed` rather than a flat long list of top-level atoms.
- **D-15:** Put precise machine-readable causes in `details.reason` and related structured fields, including cases such as `:not_found`, `:draft`, `:disabled`, `:missing_runtime_fields`, `:missing_certificates`, `:invalid_certificates`, `:repo_misconfigured`, and `:hydration_failed`.
- **D-16:** Resolver diagnostics must remain explainable and operator-friendly: include stable structured context like `connection_id`, `missing`, `operation`, and other redaction-safe metadata needed for telemetry and troubleshooting.

### Scope discipline and DX posture
- **D-17:** Phase 08 should not introduce caching, background refresh, rollover promotion semantics, or admin-facing workflow abstractions. Keep the seam clean and composable for later phases.
- **D-18:** Favor a one-shot, recommendation-first architecture with low decision burden: thin public adapter, internal hydrator, fully normalized snapshot, canonical runtime certificate field, and layered typed diagnostics as one cohesive system.

### the agent's Discretion
- Exact internal module names for the loader/hydrator/snapshot builder, as long as the public adapter stays thin and the normalization authority is singular.
- Exact split between query/preload helpers and snapshot-mapping helpers, provided persistence concerns do not leak into runtime modules.
- Exact top-level error atom names, provided the taxonomy stays intentionally small and subreasons remain structured and documented.
- Exact deprecation mechanics for `cert_chain`, provided the canonical runtime contract clearly shifts to `idp_certificates`.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Shift GSD defaults further toward recommendation-first, research-heavy, low-question workflows for non-critical architectural choices, while still surfacing genuinely high-impact decisions explicitly.
- Resolver-side caching of normalized snapshots — useful later, but out of scope until the base read/hydration contract is stable.
- Admin-facing trust-state presentation and richer UX around resolver diagnostics — belongs with the later admin surface milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-02 | Relyra can resolve a persisted connection into a runtime snapshot for login and metadata flows. [VERIFIED: .planning/REQUIREMENTS.md] | Thin `Relyra.ConnectionResolver.Ecto` adapter, internal aggregate loader + snapshot hydrator, pure `%Relyra.Connection{}` output, shared login/metadata resolver path, typed `%Relyra.Error{}` diagnostics, and dedicated resolver tests. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex] |
</phase_requirements>

## Project Constraints

`AGENTS.md` is not present in the repo root, `CLAUDE.md` is not present, and no project-specific skill directories were found under `.claude/skills` or `.agents/skills`. [VERIFIED: repo root listing and directory checks on 2026-05-05]

## Summary

Phase 08 should be planned as a boundary-tightening phase, not a persistence phase. The persistence aggregate and runtime-readiness gate already exist in `Relyra.Ecto.Connection` and `Relyra.Ecto.Connections`; the missing work is a request-time adapter that loads one connection aggregate, converts it once into a pure `%Relyra.Connection{}`, and returns bounded typed diagnostics to login and metadata callers. [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex]

The biggest planning risk is allowing normalization logic to spread. The current runtime accepts both `cert_chain` and `idp_certificates`, current resolver docs still describe a generic map contract, and provider defaults live separately in `Relyra.Provider.apply_defaults/2`; if the phase only adds DB lookup without central normalization, later phases will inherit duplicate defaulting rules and a split certificate contract. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/provider.ex]

Local baseline tests that cover connection records, runtime readiness, and Phoenix login resolution passed on 2026-05-05, which means the current Ecto aggregate and controller seams are stable enough for the planner to build directly on them. [VERIFIED: `mix test test/relyra/connection_test.exs test/relyra/ecto/runtime_readiness_test.exs test/relyra/ecto/connection_record_test.exs test/phoenix/login_controller_test.exs` exited 0 on 2026-05-05]

**Primary recommendation:** Implement `Relyra.ConnectionResolver.Ecto` as a thin adapter over two internal units: one aggregate loader using `Repo.get_by/3` + `Repo.preload/3`, and one snapshot hydrator that returns a fully normalized `%Relyra.Connection{}` plus layered `%Relyra.Error{}` failures. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Request-time connection lookup by `connection_id` | API / Backend [VERIFIED: Phoenix controllers call `Relyra.ConnectionResolver` on request] | Database / Storage [VERIFIED: persisted aggregate is stored in Ecto schemas] | Login and metadata requests already enter through Phoenix controllers and call the resolver on the server side. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex] |
| Aggregate fetch + certificate preload | Database / Storage [CITED: `Repo.get_by/3` and `Repo.preload/3` are the Ecto data-access primitives] | API / Backend [VERIFIED: adapter orchestrates the fetch] | The load step is a repo concern and already matches the existing `Relyra.Ecto.Connections.fetch_connection` pattern. [VERIFIED: lib/relyra/ecto/connections.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Runtime snapshot normalization | API / Backend [VERIFIED: runtime modules consume pure maps/structs, not schemas] | — | The snapshot builder must translate persistence data and defaults into `%Relyra.Connection{}` before protocol code touches it. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] |
| Provider default expansion | API / Backend [VERIFIED: `Relyra.Provider.apply_defaults/2` is pure runtime logic] | — | Defaults should be applied once during hydration so all downstream consumers see the same effective config. [VERIFIED: lib/relyra/provider.ex] [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| Resolver diagnostics and telemetry metadata | API / Backend [VERIFIED: `%Relyra.Error{}` and request telemetry live in runtime/server code] | — | Error typing and safe details belong at the adapter boundary, not in Ecto schemas. [VERIFIED: lib/relyra/error.ex] [VERIFIED: lib/relyra/connection_resolver.ex] |
| Signature trust input (`idp_certificates`) | API / Backend [VERIFIED: validation pipeline reads certs from resolved connection] | Database / Storage [VERIFIED: cert PEMs originate from child certificate rows] | Storage owns persistence; runtime owns the canonical trusted list it hands to signature verification. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: lib/relyra/ecto/certificate.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | `~> 3.13` in repo; current Hex release `3.13.5` published 2025-11-09. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/ecto] | Schema structs, changesets, `Ecto.Enum`, and `Ecto.Repo` callbacks used by the persistence boundary. [VERIFIED: lib/relyra/ecto/connection.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] | The existing aggregate already depends on Ecto primitives, so Phase 08 should extend that pattern instead of introducing a second persistence abstraction. [VERIFIED: lib/relyra/ecto/connection.ex] |
| Ecto SQL | `~> 3.13` in repo; current Hex release `3.13.5` published 2026-03-03. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/ecto_sql] | Test repo, migrations, and SQL-backed host-app integration. [VERIFIED: config/test.exs] [VERIFIED: test/support/ecto_test_repo.ex] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | The phase depends on the existing SQL aggregate and migration-backed test setup, not on custom storage code. [VERIFIED: test/support/migration_case.ex] |
| Postgrex | repo range `>= 0.0.0`; current Hex release `0.22.0` published 2026-01-10. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/postgrex] | Postgres adapter used by the existing test repo and expected host-app Repo wiring. [VERIFIED: test/support/ecto_test_repo.ex] | Phase 08 should keep its adapter Repo-agnostic at the `Ecto.Repo` boundary, but the verified local harness is Postgres-backed. [VERIFIED: test/support/ecto_test_repo.ex] |
| Phoenix | `~> 1.8` in repo; current Hex release `1.8.5` published 2026-03-05. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/phoenix] | Request entry points for login and metadata flows. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex] | Controllers already call the resolver and redirect with `Phoenix.Controller.redirect/2`, so Phase 08 should preserve that request path. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Controller.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Telemetry | `~> 1.3` in repo; current Hex release `1.4.1` published 2026-03-09. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/telemetry] | Attach resolver outcome metadata without leaking sensitive payloads. [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/error.ex] | Use when adding adapter-level spans or outcome tags for resolver success/failure. [VERIFIED: lib/relyra.ex] |
| ExUnit + Ecto SQL Sandbox | built into current repo test harness. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] | Unit, schema, and DB-backed adapter tests. [VERIFIED: test/support/migration_case.ex] | Use for all Phase 08 regression coverage, especially typed error and snapshot normalization cases. [VERIFIED: current test layout under `test/relyra/ecto` and `test/phoenix`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin public adapter over internal loader/hydrator [VERIFIED: locked decision D-02/D-03] | Put repo queries and normalization directly inside `Relyra.ConnectionResolver.Ecto` | Faster to write, but it hard-couples query rules, normalization, and public error mapping into one module and violates the locked thin-adapter decision. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| `%Relyra.Connection{}` as the resolved runtime value [VERIFIED: locked decision D-05/D-08] | Generic map contract forever | Generic maps preserve backward compatibility, but they keep the runtime contract vague and make later defaulting/certificate cleanup harder. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/connection_resolver.ex] |
| Canonical `idp_certificates` runtime field [VERIFIED: locked decision D-09] | Continue treating `cert_chain` and `idp_certificates` as peers | Keeping both names as first-class runtime API increases drift and broadens future test/doc surface. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] |

**Installation:** Existing dependencies already cover Phase 08; no new library is required for the core adapter path. [VERIFIED: mix.exs]
```bash
mix deps.get
```

**Version verification:** Current package metadata was verified against Hex on 2026-05-05 for `ecto`, `ecto_sql`, `postgrex`, `phoenix`, and `telemetry`. [VERIFIED: https://hex.pm/packages/ecto] [VERIFIED: https://hex.pm/packages/ecto_sql] [VERIFIED: https://hex.pm/packages/postgrex] [VERIFIED: https://hex.pm/packages/phoenix] [VERIFIED: https://hex.pm/packages/telemetry]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix Login/Metadata Request
        |
        v
Relyra.ConnectionResolver.resolve_connection/2
        |
        v
Relyra.ConnectionResolver.Ecto
  - validate request_context
  - choose repo / operation metadata
        |
        v
Internal Aggregate Loader
  - Repo.get_by(connection_id)
  - Repo.preload(:certificates)
  - runtime_ready gate
        |
        +---- not found / disabled / invalid ----> Typed %Relyra.Error{type, details.reason, context}
        |
        v
Internal Snapshot Hydrator
  - map Ecto aggregate -> %Relyra.Connection{}
  - apply provider defaults
  - derive canonical idp_certificates
  - keep temporary cert_chain compatibility only at boundary
        |
        v
Pure Runtime Snapshot (%Relyra.Connection{})
        |
        +----> start_login/3
        +----> ValidationPipeline.run/4
        +----> Protocol.Metadata.build_sp_metadata/2
```

The planner should treat the loader and hydrator as separate implementation responsibilities even if they live under one namespace. [VERIFIED: locked decision D-03 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]

### Recommended Project Structure
```text
lib/
├── relyra/connection_resolver.ex            # public behaviour + dispatch contract
├── relyra/connection_resolver/ecto.ex       # thin public Ecto adapter
├── relyra/ecto/connections.ex               # existing persistence boundary to reuse or extend
├── relyra/ecto/connection_snapshot.ex       # authoritative aggregate -> runtime hydrator
└── relyra/connection.ex                     # pure runtime snapshot struct
```
The exact internal module names are discretionary, but one module should own loading rules and one module should own snapshot normalization. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]

### Pattern 1: Thin Adapter, Fat Internal Boundary
**What:** The public resolver module should translate request context into one internal call and then map only final success/error tuples. [VERIFIED: locked decision D-02/D-03 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**When to use:** Always for persisted connection resolution in login and metadata flows. [VERIFIED: .planning/ROADMAP.md]
**Example:**
```elixir
# Source: lib/relyra/connection_resolver.ex + official Ecto Repo docs
def resolve_connection(%{connection_id: connection_id} = request_context, opts) do
  with {:ok, repo} <- fetch_repo(opts, request_context),
       {:ok, aggregate} <- Loader.fetch_connection(repo, connection_id, opts),
       {:ok, snapshot} <- SnapshotHydrator.hydrate(aggregate, opts) do
    {:ok, snapshot}
  else
    {:error, %Relyra.Error{} = error} -> {:error, error}
  end
end
```
Source rationale: the repo already dispatches resolver adapters through one public function, and Ecto officially supports one-row lookup with `get_by/3` plus post-fetch association loading with `preload/3`. [VERIFIED: lib/relyra/connection_resolver.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Pattern 2: One Authoritative Snapshot Builder
**What:** Convert the Ecto aggregate into `%Relyra.Connection{}` exactly once and apply provider defaults there. [VERIFIED: locked decision D-05/D-07 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**When to use:** Before login, metadata rendering, or validation code receives the connection. [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/protocol/metadata.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]
**Example:**
```elixir
# Source: lib/relyra/connection.ex + lib/relyra/provider.ex
attrs =
  connection
  |> persisted_attrs()
  |> apply_provider_defaults()
  |> Map.put(:idp_certificates, active_certificate_pems(connection.certificates))
  |> Map.put_new(:cert_chain, active_certificate_pems(connection.certificates))

{:ok, struct(Relyra.Connection, attrs)}
```
The compatibility `cert_chain` fill should be treated as temporary boundary glue, not as a second canonical field. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]

### Pattern 3: Layered Resolver Diagnostics
**What:** Return a small set of public error types with precise machine-readable reasons inside `details`. [VERIFIED: locked decision D-13/D-16 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**When to use:** For not found, draft/disabled, invalid aggregate, missing repo, dependency issues, or unexpected hydration failures. [VERIFIED: lib/relyra/ecto/connection.ex] [VERIFIED: lib/relyra/ecto/connections.ex]
**Example:**
```elixir
# Source: lib/relyra/error.ex + Phase 08 locked decisions
Relyra.Error.new(
  :connection_invalid,
  "Persisted connection cannot be used at runtime",
  %{connection_id: connection_id, reason: :missing_certificates, operation: :resolve_connection}
)
```
`Relyra.Error.redact_details/1` already drops sensitive keys such as XML payloads and `:relay_state`, so resolver diagnostics should stay inside redaction-safe metadata. [VERIFIED: lib/relyra/error.ex]

### Anti-Patterns to Avoid
- **Hydrating in controllers:** Login and metadata controllers already call the resolver seam, so moving Ecto queries or normalization into controllers would duplicate request logic and leak persistence details. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex] [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex]
- **Returning raw `%Relyra.Ecto.Connection{}` structs:** Protocol code expects pure maps/structs and should remain storage-agnostic. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: Phase 03 decision D-08 in .planning/phases/03-behaviour-contracts-and-stores/03-CONTEXT.md]
- **Normalizing certificates in multiple places:** The validation pipeline currently falls back across `opts[:cert_chain]`, `connection.cert_chain`, and `connection.idp_certificates`; Phase 08 should reduce that ambiguity by canonicalizing at hydration time. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]
- **Expanding the public error taxonomy atom-by-atom:** Existing code already uses typed envelopes, and the locked decision is to keep top-level atoms intentionally small. [VERIFIED: lib/relyra/error.ex] [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| One-row aggregate lookup | Custom SQL string builder or ad hoc schema traversal | `Repo.get_by/3` plus `Repo.preload/3` [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Official Ecto APIs already express the exact fetch pattern this phase needs and match the existing `Relyra.Ecto.Connections` code. [VERIFIED: lib/relyra/ecto/connections.ex] |
| Enum lifecycle parsing | Manual string-to-atom conversion for connection status or provider preset | `Ecto.Enum` in the schema [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] | The aggregate already stores `status` and `provider_preset` as `Ecto.Enum`, which keeps casting bounded and safe. [VERIFIED: lib/relyra/ecto/connection.ex] |
| Snapshot output contract | Free-form maps assembled piecemeal at each call site | `%Relyra.Connection{}` [VERIFIED: lib/relyra/connection.ex] | A dedicated struct makes required runtime fields explicit and aligns with the phase decision to return a fully normalized runtime snapshot. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| Resolver diagnostics | Raw exceptions, strings, or DB errors leaking upward | `%Relyra.Error{type, message, details}` [VERIFIED: lib/relyra/error.ex] | The project’s public API already standardizes on typed tuples and redacted error metadata. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: lib/relyra.ex] |

**Key insight:** Phase 08 is mostly an orchestration and contract phase; the planner should spend effort on boundary clarity and test coverage, not on inventing new persistence primitives. [VERIFIED: existing persistence primitives already exist in `Relyra.Ecto.Connection` and `Relyra.Ecto.Connections`]

## Common Pitfalls

### Pitfall 1: Treating runtime-readiness and runtime snapshotting as the same concern
**What goes wrong:** The adapter may return a record that passed `runtime_ready/1` but still lacks provider-expanded defaults or canonical runtime fields. [VERIFIED: `runtime_ready/1` checks presence and certificate validity, not provider defaults, in lib/relyra/ecto/connection.ex]
**Why it happens:** `runtime_ready/1` is a gate, not a hydrator. [VERIFIED: lib/relyra/ecto/connection.ex]
**How to avoid:** Run `runtime_ready/1` after loading the aggregate, then always pass the aggregate through a separate snapshot hydrator before returning success. [VERIFIED: locked decision D-03/D-07 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**Warning signs:** Tests pass for enabled rows but fail when login/metadata consumers expect fields that only provider defaults would fill. [VERIFIED: `Relyra.Provider.apply_defaults/2` exists separately from the Ecto schema in lib/relyra/provider.ex]

### Pitfall 2: Preserving `cert_chain` as a permanent public runtime field
**What goes wrong:** Future phases inherit two equally canonical certificate field names, which widens compatibility burden and confuses test expectations. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]
**Why it happens:** Current code still supports both names for backward compatibility. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]
**How to avoid:** Hydrate `idp_certificates` as canonical output, optionally mirror into `cert_chain` only as temporary compatibility glue, and update tests/docs toward the canonical field now. [VERIFIED: locked decision D-09/D-11 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**Warning signs:** New tests or examples still create resolver outputs with only `cert_chain`. [VERIFIED: test/support/fake_connection_resolver.ex] [VERIFIED: test/phoenix/login_controller_test.exs]

### Pitfall 3: Letting Ecto errors leak through the public resolver seam
**What goes wrong:** Consumers receive adapter-specific failure shapes instead of stable resolver diagnostics. [VERIFIED: current public resolver contract only accepts `{:ok, map}` or `{:error, %Error{}}` in lib/relyra/connection_resolver.ex]
**Why it happens:** The persistence layer already emits errors such as `:connection_not_found` and `:invalid_connection_record`, which are useful internally but too storage-specific for the public taxonomy. [VERIFIED: lib/relyra/ecto/connections.ex]
**How to avoid:** Map internal persistence failures to the small Phase 08 public taxonomy and preserve precise machine-readable causes in `details.reason`. [VERIFIED: locked decision D-13/D-16 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
**Warning signs:** Controller tests assert on raw Ecto or repo-specific failure atoms. [VERIFIED: current controller tests only assert generic error handling in test/phoenix/login_controller_test.exs]

### Pitfall 4: Duplicating aggregate fetch logic instead of reusing the existing persistence seam
**What goes wrong:** Phase 08 re-implements fetch/preload logic independently from `Relyra.Ecto.Connections`, causing drift with later phases. [VERIFIED: aggregate lookup and preload logic already exist in lib/relyra/ecto/connections.ex]
**Why it happens:** The new adapter may appear small enough to write inline. [VERIFIED: thin-adapter temptation implied by current simple controllers and resolver dispatch]
**How to avoid:** Reuse or extract the existing `fetch_connection` pattern so one place owns `connection_id` lookup and certificate preload rules. [VERIFIED: lib/relyra/ecto/connections.ex]
**Warning signs:** Two separate modules call `Repo.get_by(..., connection_id: ...) |> Repo.preload(:certificates)` with subtly different error mapping. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [VERIFIED: current existing pattern in lib/relyra/ecto/connections.ex]

## Code Examples

Verified patterns from official sources and the current codebase:

### Aggregate lookup with Ecto preload
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
case repo.get_by(Relyra.Ecto.Connection, connection_id: connection_id)
     |> repo.preload(:certificates) do
  nil -> {:error, :not_found}
  connection -> {:ok, connection}
end
```
This is the same lookup pattern already used by `Relyra.Ecto.Connections.fetch_connection/3`. [VERIFIED: lib/relyra/ecto/connections.ex]

### Runtime-readiness gate before hydration
```elixir
# Source: lib/relyra/ecto/connection.ex
with {:ok, aggregate} <- Loader.fetch_connection(repo, connection_id, opts),
     :ok <- Relyra.Ecto.Connection.runtime_ready(aggregate),
     {:ok, snapshot} <- SnapshotHydrator.hydrate(aggregate, opts) do
  {:ok, snapshot}
end
```
`runtime_ready/1` currently rejects non-enabled rows, missing required runtime fields, missing certificates, and invalid certificate rows. [VERIFIED: lib/relyra/ecto/connection.ex]

### Safe external redirect in Phoenix controller flow
```elixir
# Source: https://hexdocs.pm/phoenix/Phoenix.Controller.html
redirect(conn, external: target_url)
```
The current login controller already uses the `:external` redirect path after resolver success. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Resolver returns a generic map documented around `:cert_chain`. [VERIFIED: lib/relyra/connection_resolver.ex] | Phase 08 should return a fully normalized `%Relyra.Connection{}` with canonical `idp_certificates` and compatibility-only `cert_chain`. [VERIFIED: locked decisions D-05 and D-09 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] | Decision locked in Phase 08 context on 2026-05-05. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] | Shrinks downstream ambiguity and gives later phases one runtime contract to target. [VERIFIED: Phase 08 context] |
| Controller/runtime code can rely on caller-supplied resolved maps in tests. [VERIFIED: test/support/fake_connection_resolver.ex] | Persisted config should resolve through the built-in Ecto adapter for login and metadata flows. [VERIFIED: .planning/ROADMAP.md] | Phase 08 milestone target. [VERIFIED: .planning/ROADMAP.md] | Brings persisted enterprise config into the runtime path without leaking Ecto structs. [VERIFIED: Phase 08 context + current controller seam] |
| Internal persistence errors are storage-facing atoms like `:connection_not_found` or `:invalid_connection_record`. [VERIFIED: lib/relyra/ecto/connections.ex] | Public resolver failures should collapse into a small stable taxonomy with subreasons in `details`. [VERIFIED: locked decisions D-13 through D-16 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] | Decision locked in Phase 08 context on 2026-05-05. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] | Keeps API stability while preserving operator-grade detail. [VERIFIED: Phase 08 context + lib/relyra/error.ex] |

**Deprecated/outdated:**
- Treating `cert_chain` as the long-term canonical runtime certificate field is outdated for this milestone. [VERIFIED: locked decision D-09/D-10 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
- Planning the phase as “just load an Ecto row in the controller” is outdated because the public seam and prior phases already locked a pure runtime boundary. [VERIFIED: Phase 03 decision D-08 in .planning/phases/03-behaviour-contracts-and-stores/03-CONTEXT.md] [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The planning relevance window is approximately 30 days if the Phase 08 context and dependency lines do not change first. [ASSUMED] | Metadata | Low; it only affects when to refresh this research, not the implementation guidance itself. [ASSUMED] |

## Open Questions (RESOLVED)

1. **How aggressively should Phase 08 update the public resolver contract docs from “map” to `%Relyra.Connection{}`?**
   - Resolution: Phase 08 should tighten docs, typespec intent, and test expectations around a fully normalized `%Relyra.Connection{}` immediately, while keeping the runtime dispatch guard permissive enough to avoid breaking existing custom adapters in one step. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
   - Planning effect: `08-01-PLAN.md` owns the contract/doc/test tightening, but does not require a breaking dispatcher rewrite. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-01-PLAN.md]

2. **Should the adapter reuse `Relyra.Ecto.Connections` directly or extract a narrower internal fetch function?**
   - Resolution: Phase 08 should use a distinct read-side loader module so query/preload and runtime-readiness concerns stay separate from the existing write-oriented `Relyra.Ecto.Connections` API. Reuse of internal helpers is acceptable, but the public execution plan should treat the loader as its own boundary. [VERIFIED: lib/relyra/ecto/connections.ex] [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md]
   - Planning effect: `08-02-PLAN.md` explicitly assigns this responsibility to `Relyra.Ecto.ConnectionLoader`, preserving the thin-adapter decision and the separate normalization authority. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | compiling and running the Phase 08 adapter/tests [VERIFIED: mix.exs] | ✓ [VERIFIED: command check on 2026-05-05] | Erlang/OTP 28 runtime reported by `elixir --version`. [VERIFIED: local command output on 2026-05-05] | — |
| Mix | dependency resolution and test execution [VERIFIED: mix.exs] | ✓ [VERIFIED: command check on 2026-05-05] | Erlang/OTP 28 runtime reported by `mix --version`. [VERIFIED: local command output on 2026-05-05] | — |
| PostgreSQL-backed Ecto test harness | DB-backed resolver and aggregate tests [VERIFIED: config/test.exs] [VERIFIED: test/support/migration_case.ex] | ✓ [VERIFIED: Phase 08-adjacent tests and migrations passed locally on 2026-05-05] | `psql 14.17` client detected locally. [VERIFIED: local command output on 2026-05-05] | — |
| Phoenix | controller request path for login/metadata [VERIFIED: mix.exs] | ✓ [VERIFIED: Phase 08-adjacent controller tests passed locally on 2026-05-05] | repo declares `~> 1.8`; current Hex release is `1.8.5`. [VERIFIED: mix.exs] [VERIFIED: https://hex.pm/packages/phoenix] | Adapter itself can still be unit-tested without controller coverage. [VERIFIED: existing ExUnit layout] |
| Node/npm | Context7 CLI fallback used during research, not required for implementation. [VERIFIED: this session] | ✓ [VERIFIED: command check on 2026-05-05] | Node `v22.14.0`, npm `11.1.0`. [VERIFIED: local command output on 2026-05-05] | Not needed for Phase 08 implementation. [VERIFIED: mix-based project] |

**Missing dependencies with no fallback:**
- None found for planning or implementing Phase 08 in the current environment. [VERIFIED: local command checks and passing baseline tests on 2026-05-05]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command checks on 2026-05-05]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with optional Ecto SQL Sandbox-backed integration tests. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] |
| Config file | `test/test_helper.exs` and `config/test.exs`. [VERIFIED: repo files] |
| Quick run command | `mix test test/relyra/ecto/runtime_readiness_test.exs test/relyra/connection_test.exs test/phoenix/login_controller_test.exs` [VERIFIED: current test files exist] |
| Full suite command | `mix test` [VERIFIED: Mix/ExUnit project structure] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-02 | Persisted connection resolves into a pure runtime snapshot for login. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs -x` | ❌ Wave 0 [VERIFIED: file absent in current repo] |
| CFG-02 | Persisted connection resolves into a pure runtime snapshot for metadata rendering. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/phoenix/metadata_controller_test.exs -x` | ❌ Wave 0 [VERIFIED: file absent in current repo] |
| CFG-02 | Draft/disabled/incomplete rows fail closed with typed resolver diagnostics. [VERIFIED: Phase 08 success criteria + locked taxonomy decisions] | unit/integration | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs --only resolver_errors` | ❌ Wave 0 [VERIFIED: file absent in current repo] |
| CFG-02 | Runtime snapshot canonicalizes `idp_certificates` and preserves temporary compatibility where required. [VERIFIED: locked decisions D-09/D-11] | unit | `mix test test/relyra/connection_snapshot_test.exs -x` | ❌ Wave 0 [VERIFIED: file absent in current repo] |
| CFG-02 | Resolver path does not leak Ecto structs above the boundary. [VERIFIED: locked decision D-04] | unit | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs --only boundary` | ❌ Wave 0 [VERIFIED: file absent in current repo] |

### Sampling Rate
- **Per task commit:** `mix test test/relyra/ecto/runtime_readiness_test.exs test/relyra/connection_test.exs`
- **Per wave merge:** `mix test test/relyra/ecto/connection_record_test.exs test/phoenix/login_controller_test.exs`
- **Phase gate:** `mix test`

### Wave 0 Gaps
- [ ] `test/relyra/ecto/ecto_connection_resolver_test.exs` — covers persisted lookup, failure mapping, and boundary purity for CFG-02. [VERIFIED: file absent]
- [ ] `test/relyra/connection_snapshot_test.exs` — covers provider default expansion, `idp_certificates` canonicalization, and compatibility glue. [VERIFIED: file absent]
- [ ] `test/phoenix/metadata_controller_test.exs` — covers persisted metadata flow through resolver path. [VERIFIED: file absent]
- [ ] Add targeted assertions that resolver diagnostics include redaction-safe context only. [VERIFIED: lib/relyra/error.ex defines redaction rules; no resolver-specific tests exist yet]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 08 does not introduce user auth/session establishment logic] | Existing protocol and session adapter phases remain the owner. [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | no [VERIFIED: Phase 08 is resolver + snapshotting only] | Session handling remains outside this phase. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no [VERIFIED: no authorization/admin UI work is in scope for Phase 08] | Admin/authz concerns are deferred to later phases. [VERIFIED: .planning/PROJECT.md] |
| V5 Input Validation | yes [VERIFIED: request-time `connection_id` and persisted aggregate data are validated before runtime use] | `Ecto.Changeset`, `Ecto.Enum`, `runtime_ready/1`, and typed resolver checks. [VERIFIED: lib/relyra/ecto/connection.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] |
| V6 Cryptography | yes [VERIFIED: snapshot output feeds certificate-based signature verification] | Canonical `idp_certificates` snapshot field and fail-closed signature path. [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: lib/relyra/security/signature.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Resolving a draft or disabled row into runtime use | Elevation of privilege / Tampering | Call `runtime_ready/1` before hydration and map failure to typed rejection. [VERIFIED: lib/relyra/ecto/connection.ex] |
| Missing or invalid certificate inventory accepted as trusted runtime config | Spoofing | Require at least one valid PEM-bearing certificate before resolver success. [VERIFIED: lib/relyra/ecto/connection.ex] |
| Ecto structs or repo errors leaking into protocol/runtime consumers | Information disclosure / Tampering | Keep public adapter output to `%Relyra.Connection{}` or `%Relyra.Error{}` only. [VERIFIED: locked decisions D-04 and D-13 in .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| Unsafe diagnostic details exposing secrets or payloads | Information disclosure | Keep resolver details within `Relyra.Error.redact_details/1` safe keys and avoid raw XML/cert dumps. [VERIFIED: lib/relyra/error.ex] |
| Metadata/login code normalizing fields differently | Tampering | Centralize normalization in one snapshot hydrator and use the same resolved connection for login and metadata paths. [VERIFIED: locked decisions D-05 through D-07] [VERIFIED: controllers already share the resolver seam] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` - locked Phase 08 architecture, certificate, and diagnostics decisions.
- `.planning/REQUIREMENTS.md` - CFG-02 requirement anchor.
- `.planning/ROADMAP.md` - Phase 08 goal and success criteria.
- `lib/relyra/connection.ex` - current runtime snapshot struct shape.
- `lib/relyra/connection_resolver.ex` - current public resolver behaviour and dispatch contract.
- `lib/relyra/ecto/connection.ex` - runtime-readiness gate and persisted aggregate shape.
- `lib/relyra/ecto/connections.ex` - current repo fetch/preload and persistence error patterns.
- `lib/relyra/provider.ex` - provider default application surface.
- `lib/relyra/error.ex` - stable typed error envelope and redaction behavior.
- `lib/relyra/phoenix/controllers/login_controller.ex` - login request path through resolver.
- `lib/relyra/phoenix/controllers/metadata_controller.ex` - metadata request path through resolver.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - `get_by/3` and `preload/3` behavior. [CITED]
- `https://hexdocs.pm/ecto/Ecto.Schema.html` - `embeds_one/3` and embed storage semantics. [CITED]
- `https://hexdocs.pm/ecto/Ecto.Enum.html` - current enum behavior and persistence semantics. [CITED]
- `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` - current migration/index guidance. [CITED]
- `https://hexdocs.pm/phoenix/Phoenix.Controller.html` - secure redirect API used by the current login flow. [CITED]
- `https://hex.pm/packages/ecto` - current Ecto version metadata. [VERIFIED]
- `https://hex.pm/packages/ecto_sql` - current Ecto SQL version metadata. [VERIFIED]
- `https://hex.pm/packages/postgrex` - current Postgrex version metadata. [VERIFIED]
- `https://hex.pm/packages/phoenix` - current Phoenix version metadata. [VERIFIED]
- `https://hex.pm/packages/telemetry` - current Telemetry version metadata. [VERIFIED]

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` - prior milestone architecture recommendation consistent with snapshot-first runtime boundaries. [VERIFIED: repo file]
- `.planning/research/STACK.md` - prior stack recommendation; used only after re-verifying package metadata and official docs. [VERIFIED: repo file]
- `.planning/research/PITFALLS.md` - earlier enterprise-config pitfalls, cross-checked against current Phase 08 scope. [VERIFIED: repo file]

### Tertiary (LOW confidence)
- None. [VERIFIED: all substantive claims above were verified against codebase or official sources]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were re-verified against current Hex package metadata and match the repo’s declared dependencies. [VERIFIED: mix.exs] [VERIFIED: Hex package pages listed above]
- Architecture: HIGH - the Phase 08 context is unusually specific, and the current codebase already exposes the exact seams it describes. [VERIFIED: 08-CONTEXT.md + inspected source files]
- Pitfalls: HIGH - the main risks are directly observable in current code (`map` resolver contract, dual certificate fields, separate provider defaults) rather than inferred from generic ecosystem advice. [VERIFIED: lib/relyra/connection_resolver.ex] [VERIFIED: lib/relyra/protocol/validation_pipeline.ex] [VERIFIED: lib/relyra/provider.ex]

**Research date:** 2026-05-05 [VERIFIED: current date]
**Valid until:** 2026-06-04 for planning purposes, unless the Phase 08 context or dependency versions change first. [ASSUMED]
