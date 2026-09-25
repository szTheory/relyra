# Phase 75: SaaS Twin Domain Realism - Context

**Gathered:** 2026-09-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand LedgerLoop into a small, comprehensible multi-tenant SaaS adopter whose
people, organizations, providers, trust states, and operational history support
realistic journeys. Fixtures must be deterministic, isolated, resettable, and
safe for logs, screenshots, and CI. This phase establishes realistic scenarios
and evidence; the full login, rejection, isolation, diagnosis, and recovery
journeys remain owned by Phase 76.

</domain>

<decisions>
## Implementation Decisions

### Fixture Ownership and Reset
- **D-01:** Expand LedgerLoop's existing fixture and reset system as the canonical source for named Phase 75 scenarios. Keep reset and scenario data coherent rather than splitting fixture ownership.

### Tenant, Identity, and Authorization Shape
- **D-02:** Represent each organization with tenant-linked people, groups, memberships, and SAML identities, and associate its Relyra connections through the tenant's organization identifier. Preserve a clear mapping from verified identity to tenant and authorization outcome.

### Trust History
- **D-03:** Present trust history as a chronological scenario that relates connection readiness, certificate lifecycle and validity, metadata revisions, and audit evidence. Represent degraded and recovered health accurately rather than treating them as certificate lifecycle values.

### Synthetic Incident Evidence
- **D-04:** Extend the existing support scenario with a symptom-to-recovery timeline connected to trace and audit evidence. Keep execution of the full recovery journey in Phase 76.

### the agent's Discretion
- Choose the exact scenario names, fixture records, and presentation that make the approved multi-tenant story understandable.
- Keep all fixture and incident evidence deterministic, isolated, redaction-safe, and tied to named scenarios.
- Do not introduce public API, protocol, default, or security-posture changes, or a human verification gate.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and project guardrails
- `.planning/ROADMAP.md` — Phase 75 goal, success criteria, and boundary with Phase 76.
- `.planning/REQUIREMENTS.md` — TWIN-01 through TWIN-05 acceptance criteria.
- `.planning/PROJECT.md` — v1.11 twin architecture, security invariants, and approval policy.
- `.planning/STATE.md` — Current phase position and accumulated milestone decisions.
- `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md` — Locked twin architecture, deterministic evidence, and feature-neutral scope.
- `.planning/phases/74-clean-room-package-consumer/74-CONTEXT.md` — Clean-room consumer boundary and the explicit ownership of lifecycle journeys by Phase 76.

### Existing LedgerLoop and trust evidence
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — Stable fixture identity and scenario data.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — Transactional deterministic reset and existing support trace events.
- `demo/ledger_loop/priv/repo/seeds.exs` — Seed entry point.
- `demo/ledger_loop/lib/ledger_loop/accounts/tenant.ex` — Tenant model.
- `demo/ledger_loop/lib/ledger_loop/accounts/user.ex` — Tenant-linked user model.
- `demo/ledger_loop/lib/ledger_loop/accounts/group.ex` — Tenant-linked groups.
- `demo/ledger_loop/lib/ledger_loop/accounts/membership.ex` — User/group membership model.
- `demo/ledger_loop/lib/ledger_loop/accounts/saml_identity.ex` — Issuer/subject identity model.
- `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex` — Verified principal mapping to tenant and groups.
- `lib/relyra/ecto/connection.ex` — Connection status, organization identifier, and metadata associations.
- `lib/relyra/ecto/certificate.ex` — Certificate lifecycle and validity data.
- `lib/relyra/ecto/metadata_revision.ex` — Metadata import history and trust summaries.
- `lib/relyra/ecto/audit_event.ex` — Audit event domains and bounded summaries.
- `lib/relyra/login_trace/export.ex` — Trace export redaction and correlation handling.
- `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` — Existing deterministic reset proof.
- `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` — Existing connection scenario proof.

No external specification is required; the roadmap and requirements define this phase.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LedgerLoop.Demo.Fixtures` already centralizes stable IDs and a fixed timestamp.
- `LedgerLoop.Demo.Reset.reset!/0` rebuilds fixture rows transactionally, and `priv/repo/seeds.exs` delegates to it.
- LedgerLoop already has tenant, user, group, membership, and SAML identity models, plus a mapper that returns tenant and groups for a verified principal.
- Existing Relyra schemas represent connection state, certificate lifecycle/expiry, metadata revisions, audit events, and redacted trace exports.
- The current demo has four connection scenarios and a support trace; the existing Keycloak setup provides a real-provider integration point where relevant.

### Established Patterns
- Tenant ownership belongs to the host app; Relyra connections use an `organization_id` string rather than a direct tenant association.
- Reset and seed data are deterministic and should remain aligned with named scenario tests.
- Trust mutations and their audit records follow the library's transactional audit seam. Trace exports apply correlation hashing and redaction.
- Acceptance must be supported by deterministic automated evidence in mandatory CI, with no new manual UAT gate.

### Integration Points
- Extend LedgerLoop fixture/reset code and its existing demo scenario tests.
- Connect tenant-owned identity and authorization fixtures to Relyra connection organization identifiers and the host user mapper.
- Use connection, certificate, metadata revision, audit, and trace records to make the historical state and synthetic incident understandable.
- Leave complete lifecycle and recovery execution to Phase 76.
</code_context>

<specifics>
## Specific Ideas

Use the existing LedgerLoop/Northstar adopter rather than creating a new demo theme or external repository. Every fixture row should serve a named scenario, and the incident's symptom, diagnosis, remediation, retry, and recovery should be correlatable through trace and audit evidence.
</specifics>

<deferred>
## Deferred Ideas

- Full login, rejection, tenant-isolation, diagnosis, and recovery journeys — Phase 76.
- No pending todos matched Phase 75.
</deferred>

---

*Phase: 75-saas-twin-domain-realism*
*Context gathered: 2026-09-25*
