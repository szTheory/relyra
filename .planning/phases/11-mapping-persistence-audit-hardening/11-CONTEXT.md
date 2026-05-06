# Phase 11: Mapping persistence + audit hardening - Context

**Gathered:** 2026-05-05 (assumptions mode + subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Persist authorization mapping as durable per-connection trust data and make trust-bearing config changes reviewable through a durable audit history. This phase delivers persisted attribute/group mapping state, attributable mapping revisions, and a cross-domain audit ledger for connection, metadata, certificate, and mapping mutations. It does not add admin UI workflows, expression-language mapping, scheduled automation, SIEM/export pipelines, or require runtime to reconstruct state from history.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and product constraints
- `.planning/ROADMAP.md` — Phase 11 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-05` scope anchor.
- `.planning/PROJECT.md` — strict trust posture, explainability requirement, host-app DB ownership, and multi-tenant operator goals.

### Locked prior decisions
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` — mappings/audit kept out of JSON blobs, internal PK plus immutable public `connection_id`, and additive child-table architecture.
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` — pure runtime snapshot boundary and rule that persistence must not leak into runtime/protocol consumers.
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` — metadata revisions as metadata provenance only, not the final global audit system.
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` — certificate lifecycle stays on durable rows and future audit hardening must attribute promotion/retirement/rollback.

### Research and architecture guidance
- `.planning/research/ARCHITECTURE.md` — snapshot-first runtime model, explicit mapping persistence, and transactional audit side effects.
- `.planning/research/SUMMARY.md` — mapping persistence + audit hardening rationale and anti-pattern summary.
- `.planning/research/PITFALLS.md` — mapping drift, log-only audit, blob-config, and large-payload audit footguns.
- `.planning/research/FEATURES.md` — persisted mapping config, versioned history, and typed audit expectations.
- `.planning/research/STACK.md` — Ecto/Ecto SQL posture and host-Repo constraints for durable audited config state.

### Existing code seams this phase must extend
- `lib/relyra/user_mapper.ex` — user-mapping extension seam that should consume normalized persisted config rather than raw schema rows.
- `lib/relyra/user_mapper/default_attribute.ex` — current hardcoded default mapping behavior that Phase 11 should make data-driven without breaking the callback contract.
- `lib/relyra/ecto/connection.ex` — current aggregate owner and update-path constraints that already reject certificate updates through generic parent writes.
- `lib/relyra/ecto/connections.ex` — centralized connection command surface for create/update/enable/disable mutations.
- `lib/relyra/ecto/connection_loader.ex` — persisted aggregate loading and runtime-readiness gate.
- `lib/relyra/ecto/connection_snapshot.ex` — runtime snapshot hydrator that should remain the only path from persistence to runtime values.
- `lib/relyra/ecto/metadata_revision.ex` — metadata-specific append-only provenance ledger whose scope should remain bounded.
- `lib/relyra/ecto/metadata_apply.ex` — existing transactional metadata write path that Phase 11 audit hardening must extend rather than bypass.
- `lib/relyra/ecto/certificate_inventory.ex` — explicit certificate lifecycle command surface with optimistic locking and staged transitions.
- `lib/relyra/telemetry.ex` — non-authoritative observability surface that should remain supplemental to durable audit.
- `lib/relyra/log.ex` — redaction posture that Phase 11 audit payload design must respect.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.UserMapper`: stable public seam for mapping verified assertion data that should stay plain-data oriented.
- `Relyra.Ecto.ConnectionLoader` + `Relyra.Ecto.ConnectionSnapshot`: already prove the aggregate-to-runtime snapshot pattern Phase 11 should extend for mappings.
- `Relyra.Ecto.MetadataRevision`: existing append-only domain ledger pattern for metadata provenance.
- `Relyra.Ecto.MetadataApply`, `Relyra.Ecto.Connections`, and `Relyra.Ecto.CertificateInventory`: explicit transactional command surfaces where audit capture can be inserted coherently.
- `Relyra.Log`: existing redaction rules for XML, PEM, and sensitive fields that should inform audit payload boundaries.

### Established Patterns
- Runtime and protocol modules consume pure values, not Ecto structs.
- Trust-bearing writes are moving toward explicit, typed, fail-closed command flows instead of hidden convenience mutations.
- Child tables plus additive lifecycle models are preferred over replace-in-place blobs.
- Telemetry/logging are operational signals, not the source of truth for durable trust history.

### Integration Points
- The Ecto resolver/snapshot seam must grow to include normalized mapping data without breaking the existing `%Relyra.Connection{}` purity contract.
- Mapping mutation commands and audit writers must compose cleanly with existing connection, metadata, and certificate command modules.
- The cross-domain audit ledger should reference domain-specific artifacts such as metadata revision ids, certificate fingerprints, and mapping revision ids rather than duplicating large payloads.

</code_context>

<specifics>
## Specific Ideas

- Preference locked for downstream work: recommendation-first, low-friction decision handling. Use deep research and coherent one-shot defaults by default; escalate only if a decision is unusually high-impact to product semantics or project direction.
- DX principle: least surprise for host apps. Persisted enterprise config lives in Ecto child tables and ledgers; runtime gets normalized plain values; escape hatches remain explicit, not silent.
- UX principle where applicable: operator review surfaces should read like a calm trust timeline, not raw row diffs. “Who changed what, why, and what trust state changed?” is the bar.
- Cross-ecosystem lesson to copy: use first-class mapping objects/records and typed admin/audit events, but do not import expression-language complexity into the v0.2 base path.

</specifics>

<deferred>
## Deferred Ideas

- Expression-language, regex, or script-based mapping transforms.
- Full admin UI workflows, previews, and rollback UX beyond the persistence/audit foundations needed now.
- Structured audit export / SIEM pipelines as a first-class product surface.
- GSD-wide default tuning so recommendation-first, auto-resolve discussion becomes the standard path except for genuinely high-impact decisions.

</deferred>

---

*Phase: 11-mapping-persistence-audit-hardening*
*Context gathered: 2026-05-05*
