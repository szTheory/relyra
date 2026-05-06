# Phase 09: Metadata import/export + refresh - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Make metadata onboarding and sync explicit and reversible for persisted SAML connections. This phase delivers local XML import, explicit remote-source registration for controlled refresh, SP metadata export, last-known-good preservation, and durable metadata provenance. It does not deliver scheduled refresh automation, public IdP metadata export endpoints, certificate rollover promotion semantics, or the full cross-domain audit system.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact module names and file layout for metadata import, source registration, refresh, apply, and provenance services.
- Exact revision/source schema split, provided the ledger stays append-only and the connection retains explicit active and last-known-good pointers.
- Exact typed error atoms and diff-summary representation, provided failures remain operator-friendly, stable, and redaction-safe.
- Whether local file import is exposed as raw XML bytes, file path convenience, or both at the API edge, provided local XML remains the primary onboarding contract.

</decisions>

<specifics>
## Specific Ideas

- User preference: use deep research and strong software architecture to make one-shot recommendations so future planning and execution phases require minimal follow-up decisions.
- Shift this preference left into GSD defaults where possible: recommendation-first, low-friction discussion and planning, with explicit escalation only for unusually high-impact choices.
- DX principle: least surprise for Phoenix host apps. Durable Ecto state is the source of truth; HTTP fetch is an optional adapter; runtime consumes only normalized snapshots.
- UX principle where applicable: calm operator flow. “Import metadata,” “Register refresh source,” and “Refresh metadata” should be distinct verbs with clear trust-state consequences.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and project constraints
- `.planning/ROADMAP.md` — Phase 09 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-03` scope anchor.
- `.planning/PROJECT.md` — strict defaults, explainable trust changes, host-app DB ownership, and milestone boundaries.

### Locked prior decisions
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` — aggregate shape, `connection_id` contract, certificate inventory foundation, and persistence vs runtime-readiness split.
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` — pure runtime snapshot boundary, canonical `idp_certificates` contract, and resolver diagnostics posture.

### Research and architecture guidance
- `.planning/research/ARCHITECTURE.md` — metadata/import-refresh service boundary, snapshot-first runtime model, and anti-pattern guidance.
- `.planning/research/PITFALLS.md` — blind refresh, replace-in-place certs, provenance gaps, and operator trust-surface pitfalls.
- `.planning/research/SUMMARY.md` — v0.2 sequencing rationale and explicit refresh posture.
- `.planning/research/FEATURES.md` — metadata import/export, controlled refresh, and auditability expectations.
- `.planning/research/STACK.md` — optional `Req` posture, `Ecto.Multi`, and host-app integration constraints.

### Existing runtime and persistence contracts
- `lib/relyra/protocol/metadata.ex` — current SP metadata rendering surface.
- `lib/relyra/phoenix/controllers/metadata_controller.ex` — current public metadata endpoint shape.
- `lib/relyra/connection.ex` — runtime snapshot contract consumed by metadata export and login flows.
- `lib/relyra/connection_resolver/ecto.ex` — persisted snapshot resolution boundary.
- `lib/relyra/ecto/connection.ex` — current connection aggregate and runtime-readiness gate.
- `lib/relyra/ecto/certificate.ex` — certificate inventory baseline that metadata import/refresh must extend.
- `lib/relyra/ecto/connection_loader.ex` — runtime-safe aggregate loading and typed failure taxonomy.
- `lib/relyra/ecto/connection_snapshot.ex` — aggregate-to-runtime normalization path.
- `lib/relyra/provider.ex` — provider preset defaults and metadata-url hint posture.
- `lib/relyra/log.ex` — redaction posture for operational logging.
- `lib/relyra/telemetry.ex` — telemetry shape and non-authoritative event boundary.

### Ecosystem and product references
- `prompts/elixir-saml-lib-deep-research.md` — ecosystem and security lessons for metadata, refresh, and rollover.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — optional dependency posture, DX principles, and phased metadata tooling guidance.
- `prompts/relyra-brand-book.md` — operator-facing language and metadata/certificate UX direction.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/relyra/protocol/metadata.ex`: existing SP metadata renderer that should remain the only default public export surface in this phase.
- `lib/relyra/phoenix/controllers/metadata_controller.ex`: already resolves one connection and serves one SP metadata document, which fits the locked export posture.
- `lib/relyra/ecto/connection.ex` and `lib/relyra/ecto/certificate.ex`: current aggregate and certificate inventory foundation that metadata apply must update transactionally.
- `lib/relyra/ecto/connection_loader.ex` and `lib/relyra/ecto/connection_snapshot.ex`: prove the runtime boundary is already snapshot-first and should stay isolated from refresh state.
- `lib/relyra/provider.ex`: already hints at metadata URL-driven presets, which Phase 09 can formalize under explicit source registration.

### Established Patterns
- Public APIs return typed tuples and avoid exception-driven runtime control flow.
- Runtime and protocol modules consume pure structs/maps, not Ecto schemas.
- Optional integration surfaces are additive, not hidden hard requirements.
- Security- and trust-bearing state changes are expected to be explicit, explainable, and fail closed.

### Integration Points
- Metadata import/apply must update persisted connection and certificate state without changing the Phase 08 resolver boundary.
- Provenance storage must support Phase 10 certificate rollover without forcing a redesign of certificate rows or public runtime contracts.
- Telemetry/log integration should report metadata lifecycle outcomes without becoming the authoritative audit record.

</code_context>

<deferred>
## Deferred Ideas

- Scheduled or background metadata refresh automation.
- Public or admin-facing export of raw imported IdP metadata or normalized effective IdP config.
- Diff preview and explicit approval UX for metadata changes.
- Opt-in encrypted raw XML retention for advanced diagnostics.
- Cross-domain audit hardening and export beyond metadata lifecycle supportability.

</deferred>

---

*Phase: 09-metadata-import-export-refresh*
*Context gathered: 2026-05-05*
