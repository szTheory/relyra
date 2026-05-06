# Phase 07: Schema + connection aggregate - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the durable host-database trust/config foundation for tenant-scoped SAML connections: schemas, migrations, constraints, aggregate validation, and the persisted shape that later phases will hydrate into runtime snapshots. This phase defines the connection record and its immediate child trust material, but does not deliver the resolver adapter, metadata refresh workflows, certificate rollover state machine, mapping persistence, or admin UI.

</domain>

<decisions>
## Implementation Decisions

### Connection identity and lookup
- **D-01:** Use both an internal Ecto `:binary_id` primary key and an immutable public `connection_id`.
- **D-02:** `connection_id` is the operator-facing and runtime-facing identifier for Phoenix routes, resolver lookup, telemetry metadata, replay keys, and runtime snapshots.
- **D-03:** `connection_id` should be globally unique in v0.2. Do not make lookup depend on an org-scoped slug until every unauthenticated SAML route has guaranteed organization context.
- **D-04:** `display_name` remains mutable and human-friendly; it is not part of the identity contract.

### Lifecycle and validation gates
- **D-05:** Support draft and disabled connection rows in Phase 07.
- **D-06:** Separate persistence validity from runtime eligibility. Incomplete config may be saved as `draft`, but only explicitly enabled rows that pass strict runtime-readiness validation may resolve into `%Relyra.Connection{}`.
- **D-07:** Model lifecycle state explicitly with an enum-backed field and separate changesets or validation paths for draft-save vs enable/publish.
- **D-08:** Resolver and runtime code must fail closed on non-runnable rows with typed errors; drafts must never resolve silently.

### Trust material storage
- **D-09:** Do not store the IdP trust anchor as a single replace-in-place field on the connection record.
- **D-10:** Add a minimal child certificate inventory table in Phase 07, associated to each connection.
- **D-11:** Seed immutable certificate rows and provenance/basic metadata now so later metadata import and rollover phases can extend the model additively instead of rewriting it.
- **D-12:** Defer lifecycle promotion semantics such as `active` / `next` / `retired` and rollback workflows to Phase 10.

### Schema shape and extensibility
- **D-13:** Use a hybrid aggregate shape: one normalized `connections` table for core trust-routing and runtime fields, plus minimal bounded JSONB/embeds for small policy/config objects.
- **D-14:** Keep certificates, mappings, and audit history out of JSON blobs; these are lifecycle-heavy concerns that should live in separate tables as their phases land.
- **D-15:** Avoid both extremes: no wide nullable mega-table and no JSON-first config blob as the authoritative aggregate.
- **D-16:** The schema should optimize for Phase 08 snapshot hydration: runtime consumers get a pure `%Relyra.Connection{}` plus plain values, never raw Ecto structs.

### the agent's Discretion
- Exact table/module names and field naming conventions, as long as internal-vs-public identity is explicit and consistent.
- Exact enum atom names for lifecycle state, provided the model clearly distinguishes draft persistence from runtime eligibility.
- Exact JSONB/embed boundaries for compact policy objects, provided they remain bounded and do not absorb certificates, mappings, or audit history.
- Exact DB constraint and index layout beyond the locked uniqueness and runtime-safety invariants above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and product constraints
- `.planning/ROADMAP.md` — Phase 07 goal, milestone order, and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-01` scope anchor.
- `.planning/PROJECT.md` — strict-by-default trust posture, multi-tenant constraints, and milestone boundaries.

### Enterprise configuration architecture
- `.planning/research/ARCHITECTURE.md` — runtime/persistence boundary, aggregate model, and phased build order.
- `.planning/research/SUMMARY.md` — synthesized v0.2 architecture recommendation and pitfalls to avoid.
- `.planning/research/STACK.md` — idiomatic Ecto/Ecto SQL stack posture for the host-app-backed config domain.

### Existing runtime contracts that the schema must serve
- `lib/relyra/connection.ex` — current runtime snapshot shape the aggregate must hydrate into.
- `lib/relyra/connection_resolver.ex` — resolver contract and required connection fields consumed by runtime.
- `lib/relyra.ex` — login/consume orchestration and current runtime metadata assumptions.
- `lib/relyra/security/signature.ex` — certificate-driven trust verification expectations.
- `lib/relyra/protocol/metadata.ex` — SP metadata rendering inputs tied to the resolved connection.
- `lib/relyra/provider.ex` — provider preset defaults and strict-config hints that should remain compatible with the aggregate.
- `lib/relyra/phoenix/router.ex` — current `/:connection_id/*` route surface that drives public identifier decisions.
- `lib/relyra/phoenix/controllers/login_controller.ex` — request-time connection lookup shape.
- `lib/relyra/phoenix/controllers/metadata_controller.ex` — metadata endpoint lookup shape.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/relyra/connection.ex`: existing runtime value object with the core fields the persisted aggregate must hydrate.
- `lib/relyra/connection_resolver.ex`: stable adapter boundary for request-time lookup and future Ecto-backed resolution.
- `lib/relyra/provider.ex`: preset registry and safe-default logic that can populate or validate persisted connection config.
- `lib/relyra/request_store/ecto.ex` and `lib/relyra/replay_store/ecto.ex`: existing examples of optional Ecto-backed adapters and host-app Repo integration.

### Established Patterns
- Runtime stays pure and consumes plain values, not Ecto structs.
- Public APIs and adapters fail closed with typed `%Relyra.Error{}` results.
- Operator-facing flows already key off `connection_id`, not a surrogate DB id.
- The project consistently prefers additive, explicit trust state over replace-in-place shortcuts.

### Integration Points
- Phase 08 will need to resolve the persisted aggregate into `%Relyra.Connection{}` without leaking schema structs upward.
- Phase 09 metadata import/export should attach provenance and imported trust material to the same aggregate.
- Phase 10 certificate rollover should extend the certificate child table instead of replacing the Phase 07 trust model.
- Phase 11 mappings and audit hardening should hang off the internal primary key while preserving `connection_id` as the public/runtime handle.

</code_context>

<specifics>
## Specific Ideas

- Favor one-shot, research-backed recommendations with low user decision burden by default; escalate only scope-changing or unusually high-impact architecture choices.
- Optimize for principle of least surprise for both Elixir developers integrating the library and operators configuring enterprise SAML connections.
- Learn from mature systems that separate runtime-ready registrations from editable config state, preserve trust provenance, and avoid blob-first persistence.

</specifics>

<deferred>
## Deferred Ideas

- Project-level GSD preference tuning to make recommendation-first, research-heavy, low-friction decision handling the default across future phases except for very high-impact choices.

</deferred>

---

*Phase: 07-schema-connection-aggregate*
*Context gathered: 2026-05-05*
