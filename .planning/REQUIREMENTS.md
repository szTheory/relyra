# Requirements: Relyra v1.4 — Full SLO + Ops Polish

**Defined:** 2026-05-27
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.

## v1.4 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Single Logout (SLO)

- [x] **SLO-01**: Full SLO (Single Logout) round-trip (SP-initiated + IdP-initiated) with `SessionIndex` correlation. This involves extending the `Relyra.SessionAdapter` behavior (`index_session/4` + `terminate_by_session_index/4`), handling strict signature verification of `LogoutRequest`/`LogoutResponse`, and replay protection.

### Documentation & Operations

- [ ] **DOCS-04**: Publish `guides/recipes/logout.md` detailing when to enable SLO, session-model implications, 3rd-party cookie caveats, and absolute-timeout fallbacks.
- [ ] **DOCS-05**: Publish `guides/operations/incident_playbook.md` providing a narrative playbook that stitches together telemetry, audit events, the LiveView admin, and Mix tasks.
- [ ] **DOCS-06**: Publish `guides/troubleshooting.md` acting as a SAML error atom decoder, paired with an automated drift-check test to ensure the documentation matches the code's error taxonomy.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SLO-01      | Phase 38 | Complete |
| DOCS-04     | Phase 39 | Pending |
| DOCS-05     | Phase 40 | Pending |
| DOCS-06     | Phase 40 | Pending |

**Coverage:**

- v1.4 requirements: 4 total
- Mapped to phases: 4/4 ✓
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
