# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- 📋 **v0.6 — Operational maturity carryover + SLO** (planning started 2026-05-07).

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

- [x] Phase 07: Schema + connection aggregate (3/3 plans) — verified 2026-05-05 — CFG-01
- [x] Phase 08: Resolver adapter + snapshotting (3/3 plans) — verified 2026-05-05 — CFG-02
- [x] Phase 09: Metadata import/export + refresh (4/4 plans) — verified via Phase 12 (2026-05-06) — CFG-03
- [x] Phase 10: Certificate inventory + rollover (3/3 plans) — verified via Phase 13 (2026-05-06) — CFG-04
- [x] Phase 11: Mapping persistence + audit hardening (4/4 plans) — verified via Phase 14 (2026-05-06) — CFG-05
- [x] Phase 12: Metadata refresh trust-state repair (3/3 plans, closure) — produced 09-VERIFICATION.md — 2026-05-06
- [x] Phase 13: Certificate rollover validation + verification (3/3 plans, closure) — produced 10-VERIFICATION.md — 2026-05-06
- [x] Phase 14: Mapping/audit milestone verification (2/2 plans, closure) — produced 11-VERIFICATION.md — 2026-05-06

See `.planning/milestones/v0.2-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

- [x] Phase 15: Admin shell + connection lifecycle (3/3 plans) — verified 2026-05-06
- [x] Phase 16: Metadata management UI (3/3 plans) — verified 2026-05-06
- [x] Phase 17: Certificate inventory + staged rollover UI (2/2 plans) — verified 2026-05-06
- [x] Phase 18: Mapping editor + audit timeline hardening (2/2 plans) — verified 2026-05-06

See `.planning/milestones/v0.3-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

<details>
<summary>✅ v0.4 — IdP-initiated SSO (Phase 19) — SHIPPED 2026-05-06</summary>

- [x] Phase 19: IdP-initiated SSO (3/3 plans) — verified 2026-05-06

See `.planning/milestones/v0.4-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

<details>
<summary>✅ v0.5 — Operational maturity (Phases 20-21.2) — SHIPPED 2026-05-07</summary>


- [x] **Phase 20: Bulk operations across connections** - Add multi-select UI to the connections list and implement transactional bulk actions for metadata refresh and lifecycle toggling. Verified 2026-05-06.
- [x] **Phase 21: Scheduled metadata refresh** - Implement background refresh orchestration with security guardrails and operator alerts. Verified 2026-05-07.

## Phase Details

### Phase 20: Bulk operations across connections
**Goal**: Operators can perform lifecycle and metadata actions across many connections at once, reducing operational toil for large-scale deployments.
**Depends on**: Phase 19
**Requirements**: CFG-07
**Success Criteria** (what must be TRUE):
1. Connections list in the admin UI supports multi-selection of connections.
2. Operator can trigger "Enable", "Disable", or "Refresh Metadata" for all selected connections.
3. Bulk actions provide clear feedback on success or failure for each individual connection in the batch.
4. Bulk mutations remain audit-atomic; each connection's trust change co-commits its own audit row.
**Plans**: 2 plans
- [x] 20-01-PLAN.md — BulkActions coordinator
- [x] 20-02-PLAN.md — UI integration
**UI hint**: yes

### Phase 21: Scheduled metadata refresh
**Goal**: Automate trust maintenance by periodically refreshing metadata from remote sources while maintaining safety invariants.
**Depends on**: Phase 20
**Requirements**: CFG-08
**Success Criteria** (what must be TRUE):
1. Adopters can enable "Auto-refresh" on a per-connection basis.
2. System implements a background worker to fetch and apply metadata updates.
3. Automatic updates only apply if the new metadata is valid and signed.
4. Failures trigger alerts/logs without breaking the existing trust state.
**Plans**: 7 plans
- [x] 21-01-schema-extension-PLAN.md — MetadataSource schema extension (14 fields + partial index) + Wave 0 test stubs (completed 2026-05-06; SUMMARY: 21-01-schema-extension-SUMMARY.md)
- [x] 21-02-pure-helpers-PLAN.md — Cadence + Backoff + FailureClassifier pure-function helpers
- [x] 21-03-trust-boundary-helpers-PLAN.md — TrustAnchor + DriftDetector + runtime CorpusGate (manifest moved to priv/)
- [x] 21-04-audit-seam-extension-PLAN.md — D-28 health-state co-commit inside MetadataApply transactions + Signature.verify_metadata_root/4 shim + record_validity_warning/3 + resume_auto_refresh/3 + D-24 state-transition telemetry events (completed 2026-05-07; SUMMARY: 21-04-audit-seam-extension-SUMMARY.md)
- [x] 21-05-scheduler-wrapper-worker-PLAN.md — OptionalDeps.Oban gateway + AutoRefresh wrapper + Scheduler.run_due/2 + Workers.MetadataRefresh (completed 2026-05-07; SUMMARY: 21-05-scheduler-wrapper-worker-SUMMARY.md)
- [x] 21-06-live-admin-surface-PLAN.md — Connection list micro-badge + Auto-refresh health card + Resume now button (completed 2026-05-07; SUMMARY: 21-06-live-admin-surface-SUMMARY.md)
- [x] 21-07-mix-tasks-telemetry-docs-PLAN.md — Mix tasks (relyra.refresh_due + relyra.metadata.pin) + telemetry catalog + LogAlerts handler + README recipes + ci.oban_smoke alias (completed 2026-05-07; SUMMARY: 21-07-mix-tasks-telemetry-docs-SUMMARY.md)
**UI hint**: yes


### Phase 21.1: Close gap: CFG-07 — bulk-refresh audit correlation_id forwarding (INSERTED)

**Goal:** Restore Phase 20 D-39 batch-cohesion invariant for bulk `:refresh_metadata` by forwarding `opts[:audit]` (actor + cause + BulkActions-generated `correlation_id`) from `Relyra.Metadata.Refresh.refresh/2` into `MetadataApply.apply_revision/4` (success path) and `MetadataApply.record_attempt/3` (failure path), closing v0.5 milestone audit BLOCKER INT-01.
**Requirements**: CFG-07
**Depends on:** Phase 21
**Plans:** 1/1 plans complete

Plans:
- [x] 21.1-01-PLAN.md — Forward `opts[:audit]` into `apply_revision/4` + `record_attempt/3` via `resolve_audit/1` helper; 3 net-new RED→GREEN tests (bulk audit-cohesion + single-connection regression + failure-path no-audit invariant); dual-compile-lane gate

### Phase 21.2: Close v0.5 milestone-audit gaps and re-scope deferred features to v0.6 (INSERTED)

**Goal:** Close v0.5 milestone-audit gaps and re-scope deferred features to v0.6
**Requirements**: Documentation / scope re-alignment (closes audit gaps; no new functional REQ-ID. CFG-07 + CFG-08 already complete; DIAG-01 + CERT-EXP-01 + SLO-01 deferred to v0.6.)
**Depends on:** Phase 21
**Plans:** 5 plans

Plans:
- [ ] 21.2-01-PLAN.md — PROJECT.md re-scope (move DIAG-01 + Expiry alerts → v0.6 Deferred; promote CFG-07 to Validated; refresh footer)
- [ ] 21.2-02-PLAN.md — REQUIREMENTS.md in-place v0.4 → v0.5 refresh (do NOT create v0.5 archive — that's `/gsd-complete-milestone v0.5`'s job)
- [ ] 21.2-03-PLAN.md — MILESTONE-ARC.md v0.6 row update + Evolution annotation (first application of the doc's annotation rule)
- [ ] 21.2-04-PLAN.md — README.md INT-02 fix (Operations: Bulk actions subsection placed before scheduled-refresh section)
- [x] 21.2-05-PLAN.md — `/gsd-validate-phase 20` ride-along (produces 20-VALIDATION.md; closes Nyquist PARTIAL → compliant)

See `.planning/milestones/v0.5-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

### 📋 v0.6 — Operational maturity carryover + SLO (Planning)

### Phase 22: Certificate Expiry Alerts
**Goal**: Operators receive timely alerts before SAML certificates expire, allowing proactive rollover.
**Requirements**: CERT-EXP-01
**Success Criteria** (what must be TRUE):
1. The library exposes a callable function to traverse tenant connections and check certificate expiration.
2. For any certificate near expiration, standard `:telemetry` events are emitted.
3. The system does not force a background worker on the host app, delegating scheduling to the adopter.
**Plans**: 1 plan
- [x] 22-01-PLAN.md — Core Alerting Engine (TDD)

### Phase 23: Diagnostic Bundles
**Goal**: Operators can securely export a troubleshooting bundle without leaking secrets or PII.
**Requirements**: DIAG-01
**Success Criteria** (what must be TRUE):
1. Operator can trigger the creation of a `.zip` bundle containing relevant system state.
2. The generated bundle redacts all sensitive fields (PII, private keys, secrets) using a strict allow-list schema.
3. The bundle can be generated using Erlang's standard `:zip` library without adding new dependencies.
**Plans**: 2 plans
- [ ] 23-01-PLAN.md — Core API and explicit redaction maps
- [ ] 23-02-PLAN.md — Delivery via Mix task and LiveAdmin download button

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete (closure 12) | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete (closure 13) | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete (closure 14) | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete (closure phase) | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |
| 19. IdP-initiated SSO | v0.4 | 3/3 | Complete | 2026-05-06 |
| 20. Bulk operations across connections | v0.5 | 2/2 | Complete | 2026-05-06 |
| 21. Scheduled metadata refresh | v0.5 | 7/7 | Complete    | 2026-05-07 |
| 22. Certificate expiry alerts | v0.6 | 0/1 | Planned |           | |
| 23. Diagnostic bundles | v0.6 | 0/2 | Planned |           | |