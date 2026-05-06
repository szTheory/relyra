# Phase 08: Resolver adapter + snapshotting - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Hydrate a persisted SAML connection aggregate into a pure runtime snapshot through an Ecto-backed resolver adapter. This phase delivers the adapter boundary, aggregate loading, snapshot normalization, and typed resolver diagnostics for login and metadata flows. It does not deliver metadata import/refresh orchestration, certificate rollover lifecycle semantics, mapping persistence, caching, or admin UI.

</domain>

<decisions>
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

</decisions>

<specifics>
## Specific Ideas

- Optimize for the same developer experience mature auth/config libraries provide: host app supplies a Repo and resolver adapter, while Relyra handles aggregate hydration, strict defaults, and actionable typed failures.
- Follow the least-surprise shape used by strong ecosystem examples: thin resolver/repository edge, immutable effective runtime registration/snapshot, and clear separation between persistence records and request-time runtime objects.
- Successful lessons to copy:
- Spring Security SAML-style registration/snapshot thinking: build one effective per-tenant runtime object, not a half-normalized persistence row.
- Assent/Pow-style Elixir ergonomics: keep Ecto-backed integration behind a narrow boundary and expose clean runtime contracts.
- Successful footguns to avoid:
- do not spread defaulting logic across runtime call sites;
- do not let two certificate field names remain equally canonical;
- do not flatten every failure into a vague resolver error or explode the public error taxonomy into atom soup;
- do not let the protocol core know or care about Ecto.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone constraints
- `.planning/ROADMAP.md` — Phase 08 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-02` scope anchor.
- `.planning/PROJECT.md` — strict defaults, explainable failures, host-app DB ownership, and multi-tenant runtime posture.

### Locked prior decisions
- `.planning/phases/03-behaviour-contracts-and-stores/03-CONTEXT.md` — public resolver behaviour contract, pure runtime boundary, and typed adapter results.
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` — aggregate shape, `connection_id` contract, runtime-readiness semantics, and the explicit requirement that Phase 08 hydrate a pure runtime snapshot.

### Architecture and research guidance
- `.planning/research/ARCHITECTURE.md` — snapshot-first architecture and resolver boundary.
- `.planning/research/SUMMARY.md` — v0.2 sequencing rationale and runtime adapter posture.
- `.planning/research/STACK.md` — Ecto/Ecto SQL posture and host-app Repo guidance.
- `.planning/research/PITFALLS.md` — blob config drift, replace-in-place trust shortcuts, and operator trust-surface footguns.

### Existing runtime and persistence contracts
- `lib/relyra/connection.ex` — runtime snapshot shape to normalize into.
- `lib/relyra/connection_resolver.ex` — public resolver behaviour and current adapter dispatch contract.
- `lib/relyra/connection_resolver/default.ex` — default resolver failure contract baseline.
- `lib/relyra.ex` — request-time connection resolution entrypoints for login and consume flows.
- `lib/relyra/protocol/metadata.ex` — metadata rendering inputs that should consume the same normalized snapshot shape.
- `lib/relyra/protocol/validation_pipeline.ex` — current runtime fields consumed by validation, especially connection and certificate expectations.
- `lib/relyra/security/signature.ex` — certificate list expectations and telemetry shape.
- `lib/relyra/provider.ex` — provider preset defaults and DX posture to preserve through snapshot normalization.
- `lib/relyra/error.ex` — stable error envelope and redaction constraints.
- `lib/relyra/phoenix/controllers/login_controller.ex` — current login resolver call path.
- `lib/relyra/phoenix/controllers/metadata_controller.ex` — current metadata resolver call path.
- `lib/relyra/ecto/connection.ex` — persisted aggregate fields and runtime-readiness checks.
- `lib/relyra/ecto/connections.ex` — existing Ecto persistence boundary patterns.
- `lib/relyra/ecto/certificate.ex` — persisted certificate model feeding snapshot trust material.

### Tests and compatibility signals
- `test/relyra/connection_test.exs` — internal/public connection identity expectation.
- `test/relyra/ecto/runtime_readiness_test.exs` — enabled/runtime-ready contract baseline.
- `test/support/fake_connection_resolver.ex` — current compatibility shape for resolver-returned connection maps.
- `test/phoenix/login_controller_test.exs` — request-time resolver/controller expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.ConnectionResolver`: existing stable behaviour seam for request-time connection lookup.
- `Relyra.Ecto.Connection` and `Relyra.Ecto.Certificate`: persisted aggregate foundation already shaped for runtime hydration.
- `Relyra.Provider`: existing preset/default registry that should feed snapshot normalization centrally, not piecemeal.
- `Relyra.Error`: stable typed envelope for resolver diagnostics, already redaction-aware.

### Established Patterns
- Public APIs return typed tuples and avoid exception-driven control flow.
- Runtime/protocol modules consume plain maps/structs and should stay persistence-agnostic.
- `connection_id` is already the public/runtime identifier and should remain the lookup handle.
- The codebase already prefers explicit adapter boundaries and fail-closed contracts over magical convenience.

### Integration Points
- Login and metadata controllers already go through `Relyra.ConnectionResolver`; Phase 08 should preserve that seam while swapping in an Ecto-backed adapter.
- `Relyra.start_login/3`, `consume_response/3`, and metadata rendering should all consume the same normalized runtime snapshot.
- Future metadata import/refresh, certificate rollover, and mapping persistence phases should extend the persisted aggregate, not redefine the snapshot boundary.

</code_context>

<deferred>
## Deferred Ideas

- Shift GSD defaults further toward recommendation-first, research-heavy, low-question workflows for non-critical architectural choices, while still surfacing genuinely high-impact decisions explicitly.
- Resolver-side caching of normalized snapshots — useful later, but out of scope until the base read/hydration contract is stable.
- Admin-facing trust-state presentation and richer UX around resolver diagnostics — belongs with the later admin surface milestone.

</deferred>

---

*Phase: 08-resolver-adapter-snapshotting*
*Context gathered: 2026-05-05*
