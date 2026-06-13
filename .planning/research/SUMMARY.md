# Project Research Summary

**Project:** Relyra v1.7 — Adoption Evidence Demo
**Domain:** Phoenix SaaS demo app proving a strict SAML SP library's adopter journey
**Researched:** 2026-06-12
**Confidence:** HIGH

## Executive Summary

v1.7 should build `demo/ledger_loop`: a realistic, runnable Phoenix SaaS app that makes Relyra's existing adoption story visible and verifiable. The highest-leverage gap is not a missing protocol feature. It is the lack of a launched, seeded, browser-clickable host app that proves setup, strict login, Ecto production stores, operator diagnostics, and support receipts.

The demo should be evidence infrastructure and adopter/evaluator aid. It should not become a hosted SSO broker, a production IdP, or a new Relyra core customer portal. Customer/admin setup pages belong to the host demo app in v1.7; Relyra LiveAdmin remains the mounted operator trust cockpit.

## Key Findings

### Stack

- Conventional Phoenix app at `demo/ledger_loop`.
- Relyra path dependency, excluded from Hex packaging.
- Ecto/PostgreSQL for host data and production-like request/replay stores.
- LiveView for setup/admin/status surfaces.
- Docker Compose with env-driven ports, project-name isolation, and profiles.
- Playwright for browser receipts.
- Optional Keycloak external IdP proof after deterministic core proof is stable.

### Feature Table Stakes

- Runnable LedgerLoop workspace.
- Deterministic Northstar Health seed story.
- Host-owned SSO setup checklist and receipt.
- Mounted Relyra LiveAdmin.
- Ecto connection/request/replay proof.
- Local FakeIdP in-browser proof.
- Optional Keycloak in-browser proof.
- `scripts/demo` for `doctor`, `up`, `reset`, `test`, `urls`, `down`.
- Focused CI lanes.
- Docs entrypoints from README/Getting Started or guides.

### Architecture

Use clear Phoenix contexts:

- `Organizations` for tenants/memberships.
- `Accounts` for demo users and current identity.
- `SSO` for setup, Relyra wrappers, session/linkage.
- `DemoData` for deterministic seeds/reset.

Use Relyra Ecto APIs for trust data where possible. Run Relyra migrations from the dependency path; do not copy them. Host owns request/replay/session tables and wrapper modules.

### UI/UX

First screen should be the usable demo workspace, not a marketing hero. Recommended IA:

- `/` workspace: tenant selector, SSO status, quick links.
- `/tenants/:tenant_id/sso` setup task list.
- `/tenants/:tenant_id/sso/receipt` copyable SP/settings receipt.
- `/relyra/admin` mounted LiveAdmin.
- `/support/scenarios/:id` seeded support/failure story linking to trace.

Use calm, exact operator copy. Use text statuses, accessible forms, task lists, summary/receipt boxes, data tables, and light/dark/system support. Avoid color-only status and dark cybersecurity styling.

### Cross-Ecosystem Lessons

Successful SSO onboarding products such as WorkOS Admin Portal and SSOReady self-service setup reduce setup friction by making settings exchange explicit, provider-aware, and receipt-driven. Relyra should learn the UX pattern without adopting the broker architecture.

Framework-native SAML libraries and integrations such as Spring Security, Sustainsys, passport-saml/node-saml, python3-saml, omniauth-saml, and crewjam/saml reinforce the same lessons: sample apps matter, request/replay stores matter, per-tenant configuration objects matter, and security posture must be visible.

## Recommended Milestone Shape

1. **Phase 51 — Demo App Foundation**
   Scaffold `demo/ledger_loop`, package boundary, routing, Relyra path dependency, health endpoints, basic workspace.

2. **Phase 52 — Ecto Stores And Deterministic Seed Story**
   Add host schemas, Relyra migrations, Ecto request/replay wrappers, connection resolver, user mapper, session adapter, deterministic Northstar data.

3. **Phase 53 — Setup And Operator UX**
   Add host-owned setup checklist/receipt, mapping preview, mounted LiveAdmin, support scenario links, accessible operational UI posture.

4. **Phase 54 — Local Browser Login Proof**
   Add dev/test FakeIdP route, in-browser SAML login, receipt, trace handoff, Playwright happy-path proof.

5. **Phase 55 — Docker, CI, And Optional Keycloak Proof**
   Add Compose profiles, `scripts/demo`, doctor/reset/urls, `mix ci.demo_app`, browser lane, optional Keycloak browser proof.

6. **Phase 56 — Documentation And Evidence Polish**
   Add docs entrypoints, evaluator guide, proof map, CI instructions, screenshots/receipts if appropriate, and final verification.

## Critical Pitfalls

- No security relaxation for demo.
- No ETS request/replay stores in happy path.
- No document `KeyInfo` trust.
- No second XML parse path for response consumption.
- No customer portal promoted into core yet.
- No fixed Docker container names/ports.
- No Keycloak required check until burn-in.
- No raw XML/PEM/secrets in UI/logs.

## Sources

Repo-local:

- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`
- `.planning/seeds/SEED-001-adoption-evidence-demo.md`
- `guides/jtbd_user_flows.md`
- `guides/production_ecto_path.md`
- `guides/case_studies/phoenix_saas_tenant_onboarding.md`
- `prompts/relyra-brand-book.md`
- `prompts/elixir-saml-lib-deep-research.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
- `prompts/ecto-best-practices-deep-research.md`
- Relyra source/test surfaces under `lib/relyra`, `test/adoption`, `test/support`, `docker/keycloak`

External/current references checked:

- Phoenix contexts and LiveView docs: https://hexdocs.pm/phoenix/contexts.html, https://hexdocs.pm/phoenix_live_view/
- Docker Compose project names/profiles/services: https://docs.docker.com/compose/how-tos/project-name/, https://docs.docker.com/compose/how-tos/profiles/
- Keycloak health/container docs: https://www.keycloak.org/observability/health, https://www.keycloak.org/server/containers
- Playwright Docker/CI docs: https://playwright.dev/docs/docker, https://playwright.dev/docs/ci-intro
- WorkOS Admin Portal docs: https://workos.com/docs/admin-portal
- SSOReady SAML/self-service docs: https://ssoready.com/docs/saml/saml-quickstart, https://ssoready.com/docs/idp-configuration/enabling-self-service-configuration-for-your-customers

---
*Research completed: 2026-06-12*
*Ready for requirements and roadmap: yes*
