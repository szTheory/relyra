# Phase 10: Certificate inventory + rollover - Context

**Gathered:** 2026-05-05 (assumptions mode)
**Status:** Ready for planning

> Note: this context was captured before the latest Phase 09/10 groundwork landed. Where it conflicts with the current code, treat `10-RESEARCH.md`, `10-PATTERNS.md`, and the implementation itself as authoritative for already-shipped lifecycle staging and active-only runtime filtering.

<domain>
## Phase Boundary

Add explicit certificate lifecycle management to the persisted connection trust inventory so Relyra can support staged rollover without replace-in-place outages. This phase stores certificate roles, expiry, and rollover state per connection; defines active/next/retired promotion and rollback semantics; and keeps runtime trust windows explicit. It does not add scheduled automation, admin UI flows, or broader audit-history features beyond what the rollover model itself requires.
</domain>

<decisions>
## Implementation Decisions

### Certificate lifecycle model
- **D-01:** Extend `Relyra.Ecto.Certificate` with explicit per-row lifecycle fields for certificate role/state and rollover timing.
- **D-02:** Keep certificate lifecycle state on the durable certificate inventory rows themselves rather than introducing a separate rollover table.
- **D-03:** Metadata revisions remain provenance records and trust-fact history, not the authoritative source for live rollover state.

### Apply and promotion semantics
- **D-04:** Stop replacing the full certificate association wholesale during metadata apply or refresh-driven trust changes.
- **D-05:** New certificates discovered through metadata or manual trust updates should enter inventory as staged non-active rows first.
- **D-06:** Promotion, overlap, retirement, and rollback should be modeled as explicit state transitions on existing certificate rows.

### Runtime trust window
- **D-07:** Runtime hydration continues to expose only the currently trusted active overlap set through canonical `idp_certificates`.
- **D-08:** Persisted `next` and `retired` certificate rows remain available for rollout bookkeeping but are excluded from runtime trust material until their trust window explicitly changes.
- **D-09:** Phase 10 must add an explicit trust-set selection rule at the persistence-to-runtime seam so rollover windows are deliberate and observable instead of implied by “all rows currently preload.”

### the agent's Discretion
- Exact enum atoms, field names, and date/window columns for lifecycle timing, as long as active/next/retired intent is explicit and queryable.
- Whether certificate role and lifecycle state live as separate fields or one bounded enum, provided promotion and rollback remain unambiguous.
- Exact service/module split for staging, promotion, and rollback operations, provided replace-in-place deletion stops being the trust update mechanism.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirement anchors
- `.planning/ROADMAP.md` — Phase 10 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-04` scope anchor.
- `.planning/PROJECT.md` — strict trust posture, explainable trust changes, and v0.2 boundary.

### Locked prior decisions
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` — certificate inventory foundation and explicit deferral of lifecycle semantics to Phase 10.
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` — canonical runtime `idp_certificates` contract and active-trust-set runtime posture.
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` — last-known-good metadata semantics, provenance boundaries, and the rule that runtime resolves only applied aggregate state.

### Existing trust and metadata implementation
- `lib/relyra/ecto/certificate.ex` — current certificate inventory schema with provenance, expiry, and lifecycle-state fields; Phase 10 still needs to populate and harden the remaining expiry/invariant gaps.
- `lib/relyra/ecto/connection.ex` — aggregate ownership of certificates, `on_replace: :delete`, and runtime-readiness requirements.
- `lib/relyra/ecto/metadata_apply.ex` — current staged certificate apply behavior plus connection-pointer updates; Phase 10 should harden and complete this path rather than replace it wholesale.
- `lib/relyra/ecto/metadata_revision.ex` — metadata revision ledger that should remain provenance, not live rollover state.
- `lib/relyra/ecto/connection_loader.ex` — persisted aggregate loading and runtime-readiness gate.
- `lib/relyra/ecto/connection_snapshot.ex` — runtime hydration seam that already filters to active signing certificates and must keep that active-only trust window explicit.
- `lib/relyra/connection_resolver.ex` — canonical runtime certificate contract and compatibility posture.

### Tests and research guidance
- `test/relyra/ecto/metadata_apply_test.exs` — current transactional replace-in-place certificate behavior and last-known-good expectations.
- `test/relyra/connection_snapshot_test.exs` — runtime hydration expectations for trusted certificate material.
- `test/relyra/ecto/certificate_schema_test.exs` — current certificate schema validation baseline.
- `prompts/elixir-saml-lib-deep-research.md` — rollover, expiry, and operator trust-surface expectations.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — certificate rollover as a first-class operator flow and overlap-window guidance.
- `prompts/relyra-brand-book.md` — operator-facing language for certificate expiry and rollover.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Ecto.Certificate`: existing durable certificate inventory table already stores PEMs, fingerprints, source, lifecycle fields, and expiry timestamps.
- `Relyra.Ecto.Connection`: existing aggregate owner for certificate rows and the place where runtime readiness currently requires at least one valid certificate.
- `Relyra.Ecto.MetadataApply`: existing transactional trust-update path already stages new metadata-derived certificates as `:next` and can be further hardened without redesigning the write path.
- `Relyra.Ecto.ConnectionLoader` and `Relyra.Ecto.ConnectionSnapshot`: the existing resolver seam already enforces active-only runtime trust selection and remains the place to preserve that rule.

### Established Patterns
- Durable trust state belongs in the connection aggregate and child inventory tables, while metadata revisions capture provenance and history.
- Runtime and protocol modules consume pure runtime snapshots and must not infer trust state by reading persistence details directly.
- Typed errors, explicit state transitions, and fail-closed trust behavior are already the dominant patterns across the codebase.
- Current generic connection updates still expose an `on_replace: :delete` footgun, while explicit inventory helpers already model the safer staged transition path this phase needs to finish hardening.

### Integration Points
- Metadata import/refresh flows from Phase 09 must feed staged certificate inventory updates without destabilizing the live runtime snapshot.
- Resolver hydration from Phase 08 must filter certificate inventory into the active runtime trust set rather than consuming every persisted row.
- Future audit hardening in Phase 11 should be able to attribute promotion, retirement, and rollback operations without redefining the inventory model.
</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the locked assumptions above — proceed with the recommendation-first rollover model.
</specifics>

<deferred>
## Deferred Ideas

- Scheduled or background certificate rollover automation.
- Admin-facing rollover timeline and approval UX.
- Broader cross-domain audit export/reporting beyond the rollover model itself.
</deferred>

---

*Phase: 10-certificate-inventory-rollover*
*Context gathered: 2026-05-05*
