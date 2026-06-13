# Pitfalls Research: v1.7 Adoption Evidence Demo

**Project:** Relyra v1.7 — Adoption Evidence Demo
**Researched:** 2026-06-12
**Confidence:** HIGH

## Critical Security Pitfalls

### Disabling Strictness For Demo Smoothness

The demo must never disable signatures, replay checks, configured-certificate trust, or XML guards to make the flow easier. A smooth insecure demo would undercut Relyra's core value.

Prevention: prove the same strict path as production and make any failure state visible through typed errors/trace.

### Trusting Document `KeyInfo`

Keycloak and other IdPs may emit `KeyInfo` inside XMLDSig. Relyra may parse it structurally, but verification trust must continue to use configured IdP certs only.

Prevention: seed configured certs and assert the proof path ignores document-provided trust anchors.

### Second XML Parse Path

Do not introduce a demo parser that extracts identities directly from SAML XML. The demo may parse AuthnRequest enough for FakeIdP mirroring, but response/assertion consumption must go through Relyra's hardened path.

Prevention: all ACS response handling uses mounted Relyra routes and public APIs.

### ETS In The Happy Path

The current adoption fixture gap is ETS request/replay usage in otherwise production-shaped tests. v1.7 must close this.

Prevention: demo happy path uses Ecto request/replay wrappers, with tests verifying rows are written/consumed.

## Product And Architecture Pitfalls

### Accidentally Building A Broker

Relyra is a library, not WorkOS/SSOReady/Auth0. The demo can learn from their setup UX, but the host app owns tenant workflow and customer setup.

Prevention: put setup pages under `LedgerLoopWeb`, not `Relyra.LiveAdmin`; document the boundary.

### Premature Core UI API

A customer-admin portal sounds reusable, but v1.7 has not yet proven the right abstraction.

Prevention: keep host setup screens demo-local. Extract later only if repeated evidence shows stable cross-app semantics.

### Copying Relyra Migrations

Copying dependency migrations creates drift.

Prevention: run Relyra's shipped migrations from dependency path and keep host-owned request/replay/session tables separate.

### Confusing Login Trace With Audit Ledger

Trust mutations are audit rows; login traces are runtime evidence. Replays and failed attempts should not be presented as trust-mutation audit events.

Prevention: label surfaces precisely and link to troubleshooting semantics.

## DevOps / CI Pitfalls

### Fixed Container Names And Ports

Fixed names/ports break when multiple demos or CI jobs run on the same host.

Prevention: no `container_name`; env-driven ports; `COMPOSE_PROJECT_NAME`; `scripts/demo doctor` prints override commands.

### Keycloak Readiness Flakes

Keycloak can expose ports/descriptors before the login surface is usable.

Prevention: health endpoint plus SSO-login-form readiness probe; optional lane until stable.

### Realm Import Drift

Keycloak import skips existing state when volumes persist.

Prevention: `reset` removes volumes or performs explicit import; docs say reset is destructive for demo data.

### Branch Protection Drift

Adding required CI checks without updating branch protection/release scripts breaks hands-off release.

Prevention: keep demo lanes initially optional unless deliberately promoted; if promoted, update branch-protection scripts with exact check names.

### Playwright Weight And Flake

Browser E2E is valuable but expensive.

Prevention: one worker in CI, deterministic seeds, trace retained on failure, split core smoke from optional Keycloak browser proof.

## UI / UX Pitfalls

### Hero Page Instead Of Usable Demo

Evaluators need to inspect the product workflow immediately.

Prevention: first screen is LedgerLoop workspace with tenant status and task links.

### Wizard For A Nonlinear Workflow

SAML setup crosses two systems and often multiple people. A forced wizard can misrepresent the job.

Prevention: use task-list/checklist for setup; use a linear mini-flow only for deterministic test-login proof.

### Color-Only Status Or Dark Cyber Aesthetic

Relyra's brand is calm, exact, operator-friendly, not alarmist.

Prevention: text labels, accessible contrast, light/dark/system support, no decorative security theater.

### Vague Security Copy

"Invalid SAML" does not help operators.

Prevention: copy states what failed, why it matters, and what to do next.

## Scope Pitfalls

Keep these out of v1.7:

- AUTHN-POST.
- KMS/HSM decryption.
- Signed SP metadata.
- New provider presets.
- SCIM.
- Public API shape changes.
- Default-tightening.
- Hosted broker runtime.
