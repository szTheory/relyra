# Requirements: Relyra v0.5

**Defined:** 2026-05-06
**Milestone:** v0.5 — Operational maturity
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.

## v0.5 Requirements

Committed scope for v0.5 (re-scoped 2026-05-07 by Phase 21.2): bulk operations across connections and scheduled metadata refresh automation. Debug bundles (DIAG-01) and Expiry alerts (CERT-EXP-01) re-targeted to v0.6 per the v0.5 milestone audit.

### Adoption And Operations

- [x] **CFG-07**: User can run bulk operations across multiple connections. **Complete** — Phase 20 shipped 2026-05-06; Phase 21.1 closed audit BLOCKER INT-01 by forwarding bulk correlation_id through `Refresh.refresh/2`.
- [x] **CFG-08**: User can enable scheduled metadata refresh automation with guardrails. **Complete** — Phase 21 shipped 2026-05-07.

## Deferred To Later Milestones

### Operational Maturity (v0.6)

- **DIAG-01**: Operator can generate a redacted debug bundle for troubleshooting. Re-scoped from v0.5 to v0.6 by Phase 21.2 per the v0.5 milestone audit.
- **CERT-EXP-01**: User can receive operator-facing alerts (events + log entries) for upcoming SAML signing certificate expirations, configurable per connection, with thresholds aligned to the staged-rollover cadence. New REQ-ID assigned by Phase 21.2 (formerly orphaned "Expiry alerts" feature).

### Protocol Surface (v0.6)

- **SLO-01**: User can complete standards-compliant Single Logout flows. Deferred to v0.6.

## Out Of Scope

| Feature | Reason |
|---------|--------|
| Login UI or branded sign-in experience | Host-app territory; Relyra remains a library, not the app's user-facing auth product. |
| Hosted admin service or broker runtime | Customer data and trust control stay inside the host application. |
| Single Logout | Explicitly deferred to v0.6 per the active milestone arc. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-07 | Phase 20 (+ Phase 21.1 closure) | Complete |
| CFG-08 | Phase 21 | Complete (Phase 21 shipped 2026-05-07: schema + pure helpers + trust-boundary helpers + audit seam + telemetry + scheduler + wrapper + worker + live-admin-surface + mix-tasks-telemetry-docs) |
| DIAG-01 | (deferred — v0.6) | Deferred |
| CERT-EXP-01 | (deferred — v0.6) | Deferred |
| SLO-01 | (deferred — v0.6) | Deferred |

**Coverage:**
- v0.5 requirements: 2 total
- Mapped to phases: 2
- Unmapped: 0
- Deferred to v0.6: 3

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-07 by Phase 21.2 — refreshed in place from v0.4 to v0.5 with re-scoped deferred items*
