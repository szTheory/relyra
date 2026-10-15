# Phase 76: Lifecycle and Recovery Journeys - Context

**Gathered:** 2026-09-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

End users, tenant administrators, security reviewers, and operators can complete or
diagnose representative high-risk adopter workflows: verified SP-initiated login,
typed rejection and replay, tenant isolation, audited trust changes, and incident
diagnosis and recovery. Keep lifecycle execution in LedgerLoop, with deterministic
automated evidence and explicit safe ownership for browser and scheduled real-IdP
canaries. Do not expand into demand-gated protocol capabilities.
</domain>

<decisions>
## Implementation Decisions

### Twin and Login Boundary
- **D-01:** Exercise lifecycle journeys in LedgerLoop through its real Phoenix routes and configured behavior adapters. Keep Phase 74's clean-room consumer as a bounded package-boundary success proof.

### Rejection and Tenant-Isolation Evidence
- **D-02:** Assert representative invalid responses produce stable typed rejections and no adopter-owned session. Verify tenant isolation through the existing seeded organizations and the configured resolver, mapper, replay, session, trace, audit, and authorization outcomes.
- **D-03:** Check session establishment and role together at the scenario outcome level, while covering any other host-owned session side effects that participate in the real flow.

### Admin Trust Lifecycle and Audit
- **D-04:** Run metadata review, connection enablement, staged rollover, and recovery through LedgerLoop's existing organization-scoped admin integration and Relyra trust-mutation seams. Preserve transactionally co-committed, redaction-safe audit evidence for every mutation.
- **D-05:** Exercise the audited domain operations and admin scope in deterministic automation; use UI flows where they are already part of the supported journey and necessary to prove the acceptance boundary.

### Diagnosis, Recovery, and Canary Ownership
- **D-06:** Use the seeded support incident with real correlated trace and audit evidence as the operator diagnosis and recovery source; verify the recovery outcome and redaction through the existing export path.
- **D-07:** Keep external-provider canaries separate from deterministic merge gates. Give browser and scheduled real-IdP canary failures explicit safe evidence, ownership, and recovery actions without creating human CI gates.

### the Agent's Discretion
- Select focused journey boundaries and assertions that cover all named success criteria without duplicating Phase 74's clean-room proof.
- Resolve exact test organization and browser/canary wiring within current mandatory CI ownership, preserving stable typed errors and all existing security invariants.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project guardrails
- `.planning/ROADMAP.md` — Phase 76 goal, requirements, success criteria, and phase ownership.
- `.planning/REQUIREMENTS.md` — EVID-03 and JOUR-01 through JOUR-06 acceptance boundaries.
- `.planning/PROJECT.md` — v1.11 twin model, immutable security invariants, approval policy, and deterministic-evidence requirements.
- `.planning/STATE.md` — Current phase position and accumulated milestone decisions.
- `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md` — Evidence ownership, deterministic closure, and feature-neutral scope.
- `.planning/phases/74-clean-room-package-consumer/74-CONTEXT.md` — Clean-room boundary and lifecycle journey ownership.
- `.planning/phases/75-saas-twin-domain-realism/75-CONTEXT.md` — LedgerLoop tenants, fixtures, trust history, and incident scenario.

### Existing adopter journeys and trust evidence
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` — Real SAML and admin routes.
- `demo/ledger_loop/config/config.exs` — Configured resolver, replay store, mapper, and session adapter.
- `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex` — Issuer/subject mapping to tenant and groups.
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` — Adopter-owned login receipt/session outcome.
- `demo/ledger_loop/lib/ledger_loop/relyra/replay_store.ex` — Configured Ecto replay boundary.
- `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex` — Organization-scoped admin actor and operations.
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` and `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — Deterministic tenant and seeded incident evidence.
- `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` — Existing scenario and audit evidence patterns.
- `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — Failure-injection and rollback precedent.
- `lib/relyra/login_trace/export.ex` — Correlation handling and redaction for trace export.
- `demo/ledger_loop/test/browser/trace_visual.spec.ts` — Existing browser trace journey.

No external specification is required; the roadmap and requirements define this phase.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- LedgerLoop already mounts `saml_routes()` and configures the Ecto resolver, LedgerLoop replay store, user mapper, and adopter-owned session adapter.
- The session adapter records successful login as a `LoginReceipt`; the mapper resolves issuer and subject into tenant and groups.
- Phase 75's deterministic fixtures/reset, organization scenarios, staged certificate history, and seeded support incident provide reusable journey setup.
- Existing connection scenario tests and Keycloak provisioner tests provide audit assertions and rollback/failure-injection patterns.
- Relyra's trace export provides correlation handling and redaction for operator evidence.

### Established Patterns
- Keep tenant ownership in the host app; Relyra connections use the tenant's organization identifier.
- Preserve trust-mutation/audit co-commit and configured replay protection through their existing seams.
- Acceptance evidence must be deterministic and mandatory in CI; browser and external-provider canaries have separate safe failure ownership.
- The clean-room consumer already proves one valid signed response; full rejection, replay, isolation, diagnosis, and recovery belong here.

### Integration Points
- Exercise the real LedgerLoop Phoenix router and configured adapters for end-user login and rejection.
- Connect the seeded organizations to resolver, mapping, replay, session, trace, audit, and authorization outcomes.
- Drive tenant-admin changes through the existing admin scope and Relyra mutation/audit paths.
- Link the support incident to actual trace/audit exports and a verified recovery result; retain explicit ownership for browser and scheduled canaries.
</code_context>

<specifics>
## Specific Ideas

Keep lifecycle journeys in the existing LedgerLoop/Northstar adopter, use its real router
and behavior adapters, and prove end-to-end outcomes without re-running the clean-room
package-boundary proof.
</specifics>

<deferred>
## Deferred Ideas

- `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` remain demand-gated future capabilities.
- No todos matched Phase 76 for folding into scope.
</deferred>

---

*Phase: 76-lifecycle-and-recovery-journeys*
*Context gathered: 2026-09-25*
