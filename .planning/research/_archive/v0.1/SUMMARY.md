# Project Research Summary

**Project:** Relyra
**Domain:** enterprise SAML configuration for an Elixir/Phoenix SP
**Researched:** 2026-04-25
**Confidence:** MEDIUM-HIGH

## Executive Summary

v0.2 is not an admin UI milestone; it is the trust-data milestone. Enterprise SAML lives or dies on durable connection records, metadata handling, certificate lifecycle, mapping persistence, and auditable config changes. Experts build this as a host-app-backed Ecto domain with explicit state transitions, not as a blob of JSON or a live schema fed directly into runtime.

The recommended approach is: keep Phoenix as-is, add Ecto-backed config persistence in the host DB, and preserve a strict boundary between persisted config and runtime value objects. Metadata should be imported/exported and refreshed explicitly, certs must support overlap windows, and every trust mutation must produce a durable audit event. The main risk is silent trust drift from blob storage, blind refreshes, or replace-in-place cert rotation; mitigate it with transactions, versioned records, staged promotion, and last-known-good snapshots.

## Key Findings

### Recommended Stack

Add a small, conservative persistence stack: Ecto for schemas/changesets/embedded config, Ecto SQL for migrations and constraints, Postgrex pinned to the compatible 0.19 line, and Jason for JSONB/embed encoding. Req is optional and only belongs in v0.2 if URL-based metadata refresh ships; LiveView stays out until the admin surface milestone.

**Core technologies:**
- **Ecto ~> 3.13.5**: typed config state, embeds, transactions — best fit for durable enterprise config
- **Ecto SQL ~> 3.13.5**: migrations, indexes, constraint enforcement — needed for safe schema evolution
- **Postgrex ~> 0.19.3**: compatible adapter pin — 0.22.0 is too new for current Ecto SQL constraints
- **Jason ~> 1.4.4**: JSON codec for map/embed storage — explicit and conservative for Postgres
- **Req ~> 0.5.17**: optional metadata fetch client — only if refresh-from-URL is in scope

### Expected Features

The launch bar is clear: connection records, metadata import/export, certificate inventory with staged rollover, persisted mapping config, and audit logging for all trust mutations. The differentiators (diff preview, cert usage graph, mapping history, structured audit export) are useful later, but they should not delay the core trust model.

**Must have (table stakes):**
- Connection records per tenant/IdP
- Metadata import/export
- Certificate inventory + expiry tracking
- Staged certificate rollover
- Persisted attribute/group mapping
- Audit trail for config changes

**Should have (competitive):**
- Metadata refresh with diff preview
- Certificate usage graph
- Versioned mapping history
- Structured audit export

**Defer (v2+):**
- Bulk operations across connections
- Policy templates / connection cloning

### Architecture Approach

Model enterprise config as a separate domain under the runtime boundary: Ecto schemas in the host DB, adapter-based hydration into `%Relyra.Connection{}`, and pure runtime consumers for login/metadata/mapping flows. The key pattern is snapshot-first: load config rows, normalize them, then hand only plain values to protocol code. Writes should be transactional, with audit/telemetry emitted on commit, and certs should be staged rather than swapped.

**Major components:**
1. **Connection aggregate** — tenant-scoped trust/config snapshot
2. **Certificate inventory** — roles, expiry, active/next/retired states
3. **Mapping persistence** — per-connection claim/group rules
4. **Audit events** — durable history of trust changes
5. **Metadata import/refresh** — fetch, diff, stage, promote
6. **Resolver adapter** — hydrate runtime snapshots from persisted config

### Critical Pitfalls

1. **Config as one blob** — avoid JSON-all-the-things; use separate tables/embeds, transactions, and versioning.
2. **Blind metadata refresh** — support URL/file import, preserve provenance, keep last-known-good, and never refresh on the login path.
3. **Replace-in-place cert rotation** — model active/next/retired certs and require overlap windows.
4. **Log-only audit trail** — persist append-only audit records with actor, before/after, and correlation IDs.
5. **Free-form mapping drift** — keep mappings explicit, validated, and versioned per connection.

## Implications for Roadmap

### Phase 1: Schema + connection aggregate
**Rationale:** everything else depends on a durable trust record and host-DB persistence.
**Delivers:** Ecto schemas, migrations, constraints, connection records, audit skeleton.
**Addresses:** connection records, audit trail.
**Avoids:** config-as-blob pitfall.

### Phase 2: Resolver adapter + runtime snapshotting
**Rationale:** runtime must consume persisted config before higher-risk automation lands.
**Delivers:** Ecto-backed resolver, snapshot normalization, pure runtime handoff.
**Uses:** Ecto + host Repo + `Repo.transact/2` patterns.
**Implements:** adapter boundary between config and protocol core.

### Phase 3: Metadata import/export + controlled refresh
**Rationale:** onboarding and trust syncing need stable artifacts before cert rollover can be safe.
**Delivers:** XML/file import, SP export, optional URL refresh, diff/provenance storage.
**Addresses:** metadata import/export, metadata refresh.
**Avoids:** blind refresh and stale provenance.

### Phase 4: Certificate inventory + staged rollover
**Rationale:** highest-risk trust operation should sit on top of stable config and metadata flows.
**Delivers:** certificate roles, expiry tracking, overlap windows, staged promotion.
**Addresses:** cert inventory, staged rollover.
**Avoids:** replace-in-place cert outages.

### Phase 5: Mapping persistence + audit hardening
**Rationale:** authorization drift is the last major trust surface to lock down.
**Delivers:** persisted mapping config, validation, versioned change history, structured audit events.
**Addresses:** persisted mapping, audit trail.
**Avoids:** silent auth drift and log-only audit.

### Phase Ordering Rationale

- Build the trust record first, then the runtime adapter, then import/refresh, then cert rollover, then mapping/audit depth.
- Keep all write paths transactional so partial trust state never leaks into runtime.
- Defer admin UI and bulk operations; they depend on stable storage semantics, not the other way around.

### Research Flags

Needs research during planning:
- **Phase 3:** metadata refresh semantics and provenance storage (URL/file edge cases)
- **Phase 4:** cert role modeling and rollover verification details
- **Phase 5:** mapping validation rules and rollback UX

Standard patterns / likely skip research:
- **Phase 1:** Ecto schemas + migrations + constraints
- **Phase 2:** adapter/snapshot boundary

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Dependency pins and compatibility are concrete and conservative |
| Features | HIGH | v0.2 scope is clear; table stakes are well supported |
| Architecture | MEDIUM-HIGH | Strong boundary pattern, but implementation details still need phase-level design |
| Pitfalls | HIGH | Risks are specific and repeatedly validated across sources |

**Overall confidence:** HIGH

### Gaps to Address

- Exact migration shape for connection/cert/mapping tables — settle during phase planning.
- Metadata refresh policy — decide whether v0.2 includes URL refresh or file-only import first.
- Audit payload schema — define minimal durable fields without leaking sensitive XML/cert material.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — stack pins, compatibility, and exclusions
- `.planning/research/FEATURES.md` — table stakes, differentiators, and MVP scope
- `.planning/research/ARCHITECTURE.md` — runtime/persistence boundary and build order
- `.planning/research/PITFALLS.md` — trust-lifecycle failure modes and mitigations

### Secondary (MEDIUM confidence)
- `.planning/PROJECT.md` — milestone scope, constraints, and product direction

---
*Research completed: 2026-04-25*
*Ready for roadmap: yes*
