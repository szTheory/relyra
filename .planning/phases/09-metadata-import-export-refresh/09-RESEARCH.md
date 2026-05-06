# Phase 09: Metadata import/export + refresh - Research

**Researched:** 2026-05-05 [VERIFIED: system date]
**Domain:** Elixir/Phoenix SAML metadata import, provenance, and controlled refresh [VERIFIED: .planning/ROADMAP.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: source mix of locked phase decisions, current codebase inspection, Hex registry, and official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Refresh Safety Model
- **D-01:** Metadata refresh in v0.2 is operator-triggered only. Do not fetch or refresh IdP metadata on the login path, ACS path, metadata endpoint path, or any implicit runtime cache-miss path.
- **D-02:** Refresh is a two-boundary operation: fetch/parse/normalize/validate first, apply second. Validation may produce a candidate result, but only apply may mutate the live connection aggregate or certificate inventory.
- **D-03:** Live runtime resolution always uses the currently applied connection state only. Failed, pending, or rejected refresh attempts must never affect `%Relyra.Connection{}` hydration.
- **D-04:** Relyra preserves last-known-good semantics. If fetch, parse, signature validation, normalization, or apply fails, the previously applied connection and trusted certificates remain unchanged.
- **D-05:** v0.2 does not require diff-preview UI or approval queues, but the persistence and service model must leave room for those later additions without redesigning the trust boundary.

### Import Source Contract
- **D-06:** Phase 09 source contract is intentionally asymmetric: local XML/file import is the primary onboarding path, while remote metadata URLs are explicit refresh-capable sources rather than equal implicit import modes.
- **D-07:** `Relyra.Metadata.import_xml/3` is the baseline import API and requires no HTTP dependency.
- **D-08:** Remote metadata support is additive and gated behind optional `Req` availability. `Relyra.Metadata.register_source/3` records a remote HTTPS metadata URL plus provenance, and `Relyra.Metadata.refresh/2` may fetch that source only under explicit operator control.
- **D-09:** Runtime trust never depends on a live metadata fetch. Login, ACS, and SP metadata export consume only the persisted last-known-good snapshot resolved through the existing connection resolver boundary.
- **D-10:** Source semantics remain distinct: XML import means “apply this reviewed snapshot now”; URL registration means “remember where refresh may fetch from later under controlled execution.”

### Export Contract
- **D-11:** The only built-in public metadata export in Phase 09 is SP metadata for a single resolved connection.
- **D-12:** The public metadata response is rendered from the effective runtime snapshot, not from raw Ecto rows, metadata revision rows, or imported IdP XML blobs.
- **D-13:** Imported IdP metadata is a provenance artifact and refresh input, not part of the public runtime export contract.
- **D-14:** Phase 09 may persist a normalized effective IdP view for diffing, hydration, and certificate extraction, but that view remains internal to metadata and persistence services.
- **D-15:** Relyra does not ship default public endpoints for raw IdP metadata or normalized IdP config in v0.2. Any authenticated operator inspection/export of metadata provenance is deferred to a later admin/API surface.

### Provenance Model
- **D-16:** Phase 09 provenance is a domain-specific metadata revision ledger, not log-only source stamps and not full event sourcing.
- **D-17:** Relyra persists current runtime trust state and append-only metadata revisions separately. Runtime resolves only the current aggregate; it never replays history on the request path.
- **D-18:** Every metadata import or refresh attempt creates a durable revision row, including failed fetch, parse, and validation attempts, with source, trigger, outcome, and trust-summary fields.
- **D-19:** Each connection stores explicit `active_metadata_revision_id` and `last_known_good_metadata_revision_id` pointers so refresh is reversible without reconstructing state from logs.
- **D-20:** Durable provenance stores hashes and parsed trust facts by default, not raw XML. Raw metadata retention is deferred unless later introduced as explicit opt-in diagnostic storage with retention controls.
- **D-21:** Certificate material extracted from metadata lands in the certificate inventory model. Metadata revisions store certificate fingerprints and summary facts, not duplicate long-lived PEM blobs except where the certificate table requires them.
- **D-22:** Phase 09 provenance is not the final global audit system. It carries actor and cause fields for metadata lifecycle supportability, while Phase 11 owns cross-domain audit hardening and export.
- **D-23:** Telemetry and logs remain redacted and non-authoritative: identifiers, outcomes, timings, and counts only. Durable provenance lives in the database ledger.

### Claude's Discretion
- Exact module names and file layout for metadata import, source registration, refresh, apply, and provenance services.
- Exact revision/source schema split, provided the ledger stays append-only and the connection retains explicit active and last-known-good pointers.
- Exact typed error atoms and diff-summary representation, provided failures remain operator-friendly, stable, and redaction-safe.
- Whether local file import is exposed as raw XML bytes, file path convenience, or both at the API edge, provided local XML remains the primary onboarding contract.

### Deferred Ideas (OUT OF SCOPE)
- Scheduled or background metadata refresh automation.
- Public or admin-facing export of raw imported IdP metadata or normalized effective IdP config.
- Diff preview and explicit approval UX for metadata changes.
- Opt-in encrypted raw XML retention for advanced diagnostics.
- Cross-domain audit hardening and export beyond metadata lifecycle supportability.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-03 | User can import and export metadata for a connection and trigger a controlled refresh with provenance. [VERIFIED: .planning/REQUIREMENTS.md] | Existing SP export already resolves from the runtime snapshot, while import, source registration, refresh, and provenance need new metadata services plus new persistence tables and pointer fields. [VERIFIED: lib/relyra/protocol/metadata.ex, lib/relyra/phoenix/controllers/metadata_controller.ex, lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection.ex, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 09 should be planned as a write-side metadata domain layered on top of the Phase 07/08 aggregate and resolver work, not as a change to runtime resolution. The current codebase already exports SP metadata from a resolved `%Relyra.Connection{}` snapshot and already resolves runtime state from persisted connection and certificate rows, but it has no metadata import API, no provenance ledger, no source registration model, and no pointer fields for active or last-known-good metadata revisions. [VERIFIED: lib/relyra/protocol/metadata.ex, lib/relyra/phoenix/controllers/metadata_controller.ex, lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate.ex, priv/repo/migrations/20260505120000_create_relyra_connections.exs, priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs]

The key planning constraint is that runtime reads must stay snapshot-first and must never observe refresh candidates, failed attempts, or live network fetches. The write path therefore needs four explicit stages: source input, parse/normalize/validate, revision ledger insert, and transactional apply to the live connection aggregate plus certificate inventory. `Repo.transact/2` is the right default for the fixed apply path, while `Ecto.Multi` is useful only where the operation set is dynamic. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

The biggest implementation trap is parser reuse. The existing XML seam is hardened for SAML response handling and currently rejects non-`<Response>` roots, so Phase 09 needs a dedicated metadata parsing path or a carefully scoped seam extension for metadata documents. Reusing the current response parser directly for `<EntityDescriptor>` metadata would fail before any provenance or apply logic runs. [VERIFIED: lib/relyra/security/xml.ex, lib/relyra/security/xml/pure_beam.ex]

**Primary recommendation:** Build Phase 09 around a new `Relyra.Metadata` write-side API plus append-only metadata revisions, explicit source registration, and an atomic apply transaction that updates connection rows, certificate inventory, and revision pointers without touching the Phase 08 resolver boundary. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection_snapshot.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Local XML import | API / Backend | Database / Storage | Import is a trust-bearing write workflow that parses operator-supplied XML and persists the result; it does not belong in Phoenix controllers or runtime resolution. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/ecto/connections.ex] |
| Remote source registration | API / Backend | Database / Storage | URL registration is explicit operator intent that stores provenance and future refresh configuration. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| Manual refresh fetch/validate/apply | API / Backend | Database / Storage | Refresh is a controlled state transition with network I/O, validation, and DB mutation; runtime reads must remain isolated from it. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/ecto/connection_loader.ex] |
| Metadata provenance ledger | Database / Storage | API / Backend | The revision log is durable state first; services write to it and later phases may inspect it. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| SP metadata export | Frontend Server (SSR) | API / Backend | The public export path already lives in the Phoenix controller and should keep rendering from the resolved runtime snapshot only. [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex, lib/relyra/protocol/metadata.ex] |
| Runtime trust hydration | API / Backend | Database / Storage | The existing resolver remains the sole boundary from persisted state into `%Relyra.Connection{}`. [VERIFIED: lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection_snapshot.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | `~> 3.13` in repo; locked `3.13.5`; latest `3.13.6` published `2026-05-05` [VERIFIED: hex registry] | Changesets, schemas, and transaction orchestration for metadata writes. [CITED: https://hexdocs.pm/ecto/Ecto.html] | Phase 09 needs typed persistence and transactional trust updates on top of the existing Ecto aggregate. [VERIFIED: mix.exs, lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate.ex] |
| Ecto SQL | `~> 3.13` in repo; locked `3.13.5`; latest `3.13.5` published `2026-03-03` [VERIFIED: hex registry] | Migrations for revision/source tables and connection pointer columns. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | The current project already uses Ecto-backed migrations for connection and certificate tables, so Phase 09 should extend that shape rather than introduce a new persistence layer. [VERIFIED: mix.exs, priv/repo/migrations/20260505120000_create_relyra_connections.exs, priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs] |
| Postgrex | repo lock `0.22.0`; latest `0.22.1` published `2026-05-05` [VERIFIED: hex registry] | Postgres adapter used by the current Ecto test harness. [VERIFIED: test/support/ecto_test_repo.ex] | Migration and integration tests already run against Postgres, and the local server is available. [VERIFIED: test/support/migration_case.ex, pg_isready] |
| Req | optional; latest `0.5.17` published `2026-01-05` [VERIFIED: hex registry] | Remote HTTPS metadata fetch for `register_source/3` + `refresh/2` flows only. [CITED: https://hexdocs.pm/req/Req.html] | Phase decisions explicitly gate remote refresh behind optional `Req` availability rather than making HTTP mandatory for local XML import. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | repo lock `1.8.5`; latest `1.8.6` published `2026-05-05` [VERIFIED: hex registry] | Existing public metadata export controller. [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex] | Use only to preserve the existing SP metadata route; do not move write-side import or refresh logic into public controllers in this phase. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| telemetry | repo lock `1.4.1`; latest `1.4.1` published `2026-03-09` [VERIFIED: hex registry] | Non-authoritative spans for metadata lifecycle attempts. [VERIFIED: lib/relyra/telemetry.ex] | Use for timings and outcomes only; authoritative provenance belongs in DB revisions. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/log.ex, lib/relyra/telemetry.ex] |
| Req.Test | bundled with Req `0.5.17` [CITED: https://hexdocs.pm/req/Req.Test.html] | Concurrency-safe refresh stubs and retry-path tests. [CITED: https://hexdocs.pm/req/Req.Test.html] | Use when remote refresh is enabled; do not hit live IdP endpoints in unit tests. [CITED: https://hexdocs.pm/req/Req.Test.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Repo.transact/2` for fixed apply paths | `Ecto.Multi` everywhere | Official Ecto docs say `Ecto.Multi` is particularly useful when the operation set is dynamic; fixed import/apply flows are simpler with regular control flow inside `Repo.transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Optional `Req` for remote refresh | No HTTP dependency at all | XML-only import is smaller, but it would intentionally omit locked Phase 09 URL registration and operator-triggered refresh support. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| Existing SP metadata route | New raw-IdP export endpoints | The phase explicitly forbids default public raw IdP or normalized IdP export surfaces. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
# Add Req only if the plan includes remote refresh in this phase.
```

**Version verification:** [VERIFIED: hex registry]
```bash
mix hex.info ecto
mix hex.info ecto_sql
mix hex.info postgrex
mix hex.info req
mix hex.info phoenix
mix hex.info telemetry
```

## Architecture Patterns

### System Architecture Diagram

```text
Operator XML bytes / file path / refresh command
        |
        v
Relyra.Metadata public API
  import_xml/3 | register_source/3 | refresh/2
        |
        v
Parse -> normalize -> validate candidate
        |
        +--> insert append-only metadata revision (attempt record)
        |        |
        |        +--> failed fetch/parse/validation stays ledger-only
        |
        +--> apply approved candidate inside Repo.transact/2
                 |
                 +--> update relyra_connections fields
                 +--> upsert/delete certificate inventory rows
                 +--> update active_metadata_revision_id
                 +--> update last_known_good_metadata_revision_id
                 |
                 v
        Phase 08 resolver reads only applied connection + cert rows
                 |
                 v
        Runtime snapshot -> SP metadata export / login / ACS
```

The diagram matches the locked two-boundary model: candidate evaluation is separate from live-state mutation, and runtime reads only the already-applied aggregate. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex]

### Recommended Project Structure
```text
lib/relyra/
├── metadata.ex                     # public API: import_xml/3, register_source/3, refresh/2
├── metadata/
│   ├── parser.ex                   # metadata-specific XML parsing/normalization
│   ├── candidate.ex                # validated normalized metadata candidate
│   ├── refresh.ex                  # fetch + validate orchestration
│   └── applier.ex                  # atomic live-state mutation
└── ecto/
    ├── metadata_revision.ex        # append-only provenance ledger
    ├── metadata_source.ex          # explicit remote source registration
    └── metadata_apply.ex           # repo-facing transaction helpers
```

This keeps the Phase 08 resolver untouched and locates all write-side metadata concerns in a dedicated service boundary. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]

### Pattern 1: Explicit Candidate Then Apply
**What:** Parse, normalize, and validate imported metadata into an internal candidate struct before any connection or certificate row mutates. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**When to use:** Every `import_xml/3` and `refresh/2` path. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
Repo.transact(fn repo ->
  # validate candidate first
  # insert revision row
  # apply connection + certificate changes
  {:ok, :applied}
end)
```

### Pattern 2: Append-Only Revisions With Live Pointers
**What:** Store each import/refresh attempt in a revision ledger and move `active_metadata_revision_id` plus `last_known_good_metadata_revision_id` only during successful apply. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**When to use:** Every metadata onboarding or refresh attempt. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:revision, revision_changeset)
|> Ecto.Multi.update(:connection, connection_changeset)
|> Repo.transact()
```

### Pattern 3: Snapshot-Only Public Export
**What:** Keep SP metadata export rendering from the resolved runtime snapshot, not from provenance rows or raw imported XML. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/protocol/metadata.ex, lib/relyra/phoenix/controllers/metadata_controller.ex]
**When to use:** `GET /:connection_id/metadata` and any future library-level SP metadata rendering call. [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex]
**Example:**
```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/phoenix/controllers/metadata_controller.ex
case Relyra.ConnectionResolver.resolve_connection(request_context, opts) do
  {:ok, connection} -> Relyra.Protocol.Metadata.build_sp_metadata(connection, opts)
end
```

### Anti-Patterns to Avoid
- **Login-path refresh:** The phase explicitly forbids metadata fetch or refresh on login, ACS, metadata endpoint, or cache-miss paths. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
- **Response-parser reuse:** `Relyra.Security.XML.PureBeam.parse_safely/2` currently expects a `<Response>` root, so direct reuse for metadata import would reject IdP metadata documents. [VERIFIED: lib/relyra/security/xml/pure_beam.ex]
- **Apply-before-ledger:** Updating connection rows or certificate rows before inserting the revision attempt loses provenance for failed or partial writes. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
- **Raw XML as public contract:** Raw IdP XML is provenance input, not a public export surface in v0.2. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction orchestration | Ad hoc nested inserts/updates with manual rollback flags | `Repo.transact/2` and `Ecto.Multi` [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | The apply path must update multiple tables and pointer fields atomically. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| Remote refresh retries and redirects | Custom retry/backoff and redirect-follow code | Req built-in request, redirect, and retry steps. [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://hexdocs.pm/req/Req.Steps.html] | Req already defines timeout, retry, redirect, and transport error handling for HTTP fetches. [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| Remote refresh test server | Homegrown HTTP stub process | `Req.Test` stubs/expectations. [CITED: https://hexdocs.pm/req/Req.Test.html] | `Req.Test` is concurrency-safe and already covers transport errors, redirects, and response shaping. [CITED: https://hexdocs.pm/req/Req.Test.html] |
| Public export shape | New raw-DB or raw-XML export path | Existing resolver snapshot + `Relyra.Protocol.Metadata.build_sp_metadata/2`. [VERIFIED: lib/relyra/phoenix/controllers/metadata_controller.ex, lib/relyra/protocol/metadata.ex] | The phase only allows SP metadata export from the effective runtime snapshot. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

**Key insight:** The hard part of Phase 09 is controlled state transition and provenance, not XML transport plumbing; use library primitives for HTTP and DB transactions so planning can focus on candidate normalization, certificate extraction, and last-known-good semantics. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/req/Req.html]

## Common Pitfalls

### Pitfall 1: Reusing the SAML response XML seam for metadata documents
**What goes wrong:** Metadata import fails before normalization because the current parser treats anything that is not a response payload as malformed. [VERIFIED: lib/relyra/security/xml/pure_beam.ex]
**Why it happens:** The existing XML seam was built for trust-sensitive SAML response verification, not for `<EntityDescriptor>` parsing. [VERIFIED: lib/relyra/security/xml.ex, lib/relyra/security/xml/pure_beam.ex]
**How to avoid:** Plan a metadata-specific parser/normalizer module and test it independently from the response validation seam. [VERIFIED: lib/relyra/security/xml/pure_beam.ex, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Warning signs:** Tests only exercise fake response XML, or metadata import fixtures are missing entirely. [VERIFIED: lib/relyra/test_support/fake_idp.ex, rg codebase search]

### Pitfall 2: Mutating live connection state before the revision row is durable
**What goes wrong:** A failed certificate update or connection write leaves no authoritative provenance row for the attempt, or leaves connection data and revision pointers out of sync. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Why it happens:** Trust changes are split across multiple writes without one transaction boundary. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**How to avoid:** Insert the revision attempt and apply connection/certificate/pointer changes inside one `Repo.transact/2` boundary. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**Warning signs:** Separate repo calls with no shared transaction or no test proving rollback preserves the previous live snapshot. [VERIFIED: lib/relyra/ecto/connections.ex, existing absence of metadata apply tests]

### Pitfall 3: Letting refresh semantics leak into runtime resolution
**What goes wrong:** Login or metadata export sees pending or failed refresh state instead of only the applied aggregate. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**Why it happens:** Refresh writes are coupled directly to resolver reads or cache invalidation. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
**How to avoid:** Keep the resolver reading only connection rows and certificate inventory that represent the active applied state. [VERIFIED: lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex]
**Warning signs:** Resolver code starts reading revision tables or source registration rows. [VERIFIED: lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection_loader.ex]

### Pitfall 4: Logging raw XML or PEMs during import/refresh
**What goes wrong:** Durable logs become the accidental store of sensitive or oversized metadata artifacts. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/log.ex]
**Why it happens:** Debugging shortcuts bypass the existing redaction posture. [VERIFIED: lib/relyra/log.ex]
**How to avoid:** Persist hashes and trust facts in the revision ledger and emit only identifiers, counts, outcomes, and timings through logs/telemetry. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/log.ex, lib/relyra/telemetry.ex]
**Warning signs:** Telemetry metadata grows to include XML bodies, PEM blobs, or raw metadata payloads. [VERIFIED: lib/relyra/log.ex, lib/relyra/telemetry.ex]

## Code Examples

Verified patterns from official sources:

### Atomic Apply Transaction
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
Repo.transact(fn repo ->
  revision = repo.insert!(revision_changeset)
  connection = repo.update!(connection_changeset)
  {:ok, %{revision: revision, connection: connection}}
end)
```

### Dynamic Multi When Later Steps Depend On Earlier Results
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:revision, revision_changeset)
|> Ecto.Multi.run(:certificates, fn _repo, %{revision: revision} ->
  {:ok, build_certificate_rows(revision)}
end)
```

### Stubbed Refresh Fetch
```elixir
# Source: https://hexdocs.pm/req/Req.Test.html
Req.Test.stub(:metadata_source, fn conn ->
  Plug.Conn.send_resp(conn, 200, metadata_xml)
end)

Req.get!(plug: {Req.Test, :metadata_source})
```

### Existing Export Contract
```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/protocol/metadata.ex
xml = Relyra.Protocol.Metadata.build_sp_metadata(connection, opts)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` | `Repo.transact/2` [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Ecto `3.13.5` docs mark `transaction/2` deprecated. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | New Phase 09 transaction code should use `transact/2` in examples and implementation. |
| Dual runtime certificate naming | Canonical `idp_certificates` with `cert_chain` as compatibility glue. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md, lib/relyra/connection.ex, lib/relyra/ecto/connection_snapshot.ex] | Locked in Phase 08 decisions on `2026-05-05`. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] | Phase 09 apply logic should update certificate inventory for the canonical runtime trust set, not introduce a second certificate concept. |

**Deprecated/outdated:**
- `Repo.transaction/2`: deprecated in favor of `Repo.transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Using the current response-only XML seam as a generic metadata parser: outdated for this phase because it only recognizes response-shaped XML. [VERIFIED: lib/relyra/security/xml/pure_beam.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All material implementation claims in this document are either verified in the repo/context or cited from current official docs/registries. [VERIFIED: this file] | — | — |

## Open Questions (RESOLVED)

1. **Which IdP SSO binding wins when metadata exposes more than one endpoint?**
   - What we know: the runtime snapshot and connection schema currently have a single `idp_sso_url` field, so Phase 09 must collapse imported metadata to one effective SSO URL. [VERIFIED: lib/relyra/connection.ex, lib/relyra/ecto/connection.ex]
   - Resolved in plans: `09-03-PLAN.md` locks the deterministic v0.2 selection rule to prefer `HTTP-Redirect`, else `HTTP-POST`, else the first remaining `SingleSignOnService` in XML document order, because the runtime login path redirects through one `connection.idp_sso_url`. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-03-PLAN.md]
   - Binding priority outcome: no further research or user decision is needed for Phase 09; import and refresh must share this same rule and keep alternative endpoints out of the runtime contract. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-03-PLAN.md]

2. **What is the minimum operator provenance payload for public APIs?**
   - What we know: Phase 09 requires actor and cause fields in durable provenance, while Phase 11 owns broader audit hardening. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
   - Resolved in plans: `09-03-PLAN.md` and `09-04-PLAN.md` require the public metadata APIs to accept explicit actor/cause input, use fixed `source_kind` and `trigger` values per verb, and keep any optional metadata labels redaction-safe. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-03-PLAN.md, .planning/phases/09-metadata-import-export-refresh/09-04-PLAN.md]
   - Provenance payload outcome: the minimum Phase 09 contract is actor + cause at the API edge, with verb-owned trigger/source_kind values and no raw XML or PEM material in telemetry/log metadata. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-03-PLAN.md, .planning/phases/09-metadata-import-export-refresh/09-04-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Build, deps, tests | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL server | Migration-backed metadata persistence tests | ✓ [VERIFIED: `pg_isready`] | server reachable at `/tmp:5432` [VERIFIED: `pg_isready`] | — |
| `psql` CLI | Manual DB inspection during execution | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Req dependency | Remote refresh fetch path only | ✗ in current project deps [VERIFIED: mix.exs, rg codebase search] | latest `0.5.17` available [VERIFIED: hex registry] | Keep Phase 09 limited to local XML import if Req is not added. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- `Req` is not currently declared in `mix.exs`; the fallback is to plan and ship the local `import_xml/3` path first and gate remote refresh behind the optional dependency exactly as the phase decisions allow. [VERIFIED: mix.exs, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL sandbox-backed migration harness. [VERIFIED: test/test_helper.exs, test/support/migration_case.ex] |
| Config file | `test/test_helper.exs` (no separate `pytest.ini`/`jest.config` equivalent). [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/phoenix/metadata_controller_test.exs test/relyra/metadata --warnings-as-errors` [ASSUMED] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-03 | Import local XML and apply normalized IdP state to the live connection aggregate. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] | integration | `mix test test/relyra/metadata/import_xml_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: `rg --files test`] |
| CFG-03 | Register a remote source without mutating live runtime trust. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] | unit/integration | `mix test test/relyra/metadata/register_source_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: `rg --files test`] |
| CFG-03 | Refresh from a registered source with ledgered provenance and last-known-good preservation. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] | integration | `mix test test/relyra/metadata/refresh_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: `rg --files test`] |
| CFG-03 | Public SP metadata export remains snapshot-based and unaffected by failed refresh attempts. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] | controller | `mix test test/phoenix/metadata_controller_test.exs --warnings-as-errors` | ✅ [VERIFIED: test/phoenix/metadata_controller_test.exs] |
| CFG-03 | Apply transaction rolls back partial connection/certificate/pointer writes on failure. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] | integration | `mix test test/relyra/metadata/apply_transaction_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: `rg --files test`] |

### Sampling Rate
- **Per task commit:** `mix test test/phoenix/metadata_controller_test.exs test/relyra/metadata --warnings-as-errors` [ASSUMED]
- **Per wave merge:** `mix test --warnings-as-errors` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: workflow requirement + `.planning/config.json` with `nyquist_validation: true`]

### Wave 0 Gaps
- [ ] `test/relyra/metadata/import_xml_test.exs` — covers local XML import, normalization, and revision creation. [VERIFIED: `rg --files test`]
- [ ] `test/relyra/metadata/register_source_test.exs` — covers HTTPS-only source registration and provenance defaults. [ASSUMED]
- [ ] `test/relyra/metadata/refresh_test.exs` — covers Req-backed fetch, failed-refresh ledger rows, and last-known-good preservation. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] [CITED: https://hexdocs.pm/req/Req.Test.html]
- [ ] `test/relyra/metadata/apply_transaction_test.exs` — covers rollback semantics across connection rows, certificates, and revision pointers. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
- [ ] `test/fixtures/metadata/` XML fixtures — covers single-signing-cert, multi-cert, stale/invalid, and malformed metadata cases. [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Phase 09 changes configuration state, not end-user authentication flows directly. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no [VERIFIED: phase scope] | No session storage or session-establishment changes are introduced here. [VERIFIED: .planning/ROADMAP.md, lib/relyra.ex] |
| V4 Access Control | yes [VERIFIED: operator-triggered-only requirement] | Keep write APIs host-invoked only, with no new default public mutation endpoints; record actor/cause metadata for each attempt. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: phase scope] | Validate XML size/shape, source URL scheme, normalized fields, and certificate facts before apply. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/security/xml/pure_beam.ex, lib/relyra/ecto/certificate.ex] |
| V6 Cryptography | yes [VERIFIED: trust domain] | Reuse existing certificate inventory and transport TLS; never trust document-provided key material for runtime without explicit validation and persistence. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/security/signature.ex, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

### Known Threat Patterns for this Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Remote metadata URL abuse / SSRF | Information Disclosure | Require explicit operator registration, restrict to HTTPS, keep refresh off the runtime path, and consider disabling redirects for refresh fetches because Req follows redirects by default. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| Malicious or stale metadata replacing good trust state | Tampering | Parse and validate into a candidate first, insert a revision row for every attempt, and only update live connection/certificate state inside one successful apply transaction. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| XML entity expansion or malformed metadata payloads | Denial of Service | Use a metadata parser that rejects oversized or unsafe XML input and test malformed fixtures directly. [VERIFIED: lib/relyra/security/xml/pure_beam.ex] [ASSUMED] |
| Raw XML or PEM leakage in logs/telemetry | Information Disclosure | Keep logs and telemetry redacted and make the DB revision ledger the only authoritative provenance surface. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/log.ex, lib/relyra/telemetry.ex] |
| Partial apply across rows and revision pointers | Tampering | Use `Repo.transact/2` and fail the entire apply if any connection, certificate, or pointer write fails. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` - locked Phase 09 decisions, scope, provenance model, and deferred items. [VERIFIED: local file]
- `.planning/ROADMAP.md` - phase goal and success criteria. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - `CFG-03` requirement anchor. [VERIFIED: local file]
- `.planning/PROJECT.md` - bounded-context and product constraints. [VERIFIED: local file]
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` - aggregate and certificate baseline. [VERIFIED: local file]
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` - snapshot/resolver boundary and runtime contract. [VERIFIED: local file]
- `lib/relyra/protocol/metadata.ex` - current SP metadata renderer. [VERIFIED: local file]
- `lib/relyra/phoenix/controllers/metadata_controller.ex` - current export endpoint behavior. [VERIFIED: local file]
- `lib/relyra/connection.ex` - runtime snapshot fields. [VERIFIED: local file]
- `lib/relyra/connection_resolver/ecto.ex` - current resolver boundary. [VERIFIED: local file]
- `lib/relyra/ecto/connection.ex` - current connection schema and missing metadata pointer fields. [VERIFIED: local file]
- `lib/relyra/ecto/certificate.ex` - current certificate inventory baseline. [VERIFIED: local file]
- `lib/relyra/ecto/connection_loader.ex` - runtime-read path and fail-closed semantics. [VERIFIED: local file]
- `lib/relyra/ecto/connection_snapshot.ex` - aggregate-to-snapshot normalization contract. [VERIFIED: local file]
- `lib/relyra/provider.ex` - metadata URL hint posture and preset defaults. [VERIFIED: local file]
- `lib/relyra/log.ex` - redaction posture. [VERIFIED: local file]
- `lib/relyra/telemetry.ex` - telemetry event boundary. [VERIFIED: local file]
- `lib/relyra/security/xml.ex` and `lib/relyra/security/xml/pure_beam.ex` - current XML seam limits. [VERIFIED: local file]
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - `Repo.transact/2` and deprecation of `transaction/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - when `Ecto.Multi` is appropriate. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- `https://hexdocs.pm/ecto/Ecto.html` - Ecto component roles. [CITED: https://hexdocs.pm/ecto/Ecto.html]
- `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` - migration patterns for SQL-backed schemas. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]
- `https://hexdocs.pm/req/Req.html` - request API and default options. [CITED: https://hexdocs.pm/req/Req.html]
- `https://hexdocs.pm/req/Req.Steps.html` - redirect and retry defaults. [CITED: https://hexdocs.pm/req/Req.Steps.html]
- `https://hexdocs.pm/req/Req.Test.html` - test stubs and transport error simulation. [CITED: https://hexdocs.pm/req/Req.Test.html]
- Hex registry via `mix hex.info ecto`, `ecto_sql`, `postgrex`, `req`, `phoenix`, `telemetry` - current package versions and publish dates. [VERIFIED: hex registry]

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` - prior architecture guidance for metadata and snapshot boundaries. [VERIFIED: local file]
- `.planning/research/STACK.md` - prior stack guidance, updated here against current Hex registry. [VERIFIED: local file]
- `.planning/research/PITFALLS.md` - prior trust-surface pitfalls, refined here against current code. [VERIFIED: local file]
- `.planning/research/SUMMARY.md` - sequencing rationale for v0.2. [VERIFIED: local file]
- `.planning/research/FEATURES.md` - metadata/import/refresh product expectations. [VERIFIED: local file]

### Tertiary (LOW confidence)
- None. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions were rechecked against the current Hex registry and matched to the existing repo dependency shape. [VERIFIED: mix.exs, hex registry]
- Architecture: HIGH - the key trust-boundary decisions are locked in Phase 09 context and align with the current Phase 08 resolver code. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md, lib/relyra/connection_resolver/ecto.ex, lib/relyra/ecto/connection_snapshot.ex]
- Pitfalls: HIGH - they are grounded in current code gaps plus locked phase constraints, especially the response-only XML seam and missing provenance tables. [VERIFIED: lib/relyra/security/xml/pure_beam.ex, lib/relyra/ecto/connection.ex, priv/repo/migrations/*.exs]

**Research date:** 2026-05-05 [VERIFIED: system date]
**Valid until:** 2026-06-04 for planning guidance, unless Phase 08/09 context or dependency lines change first. [ASSUMED]
