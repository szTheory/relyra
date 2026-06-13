# Feature Research: v1.7 Adoption Evidence Demo

**Project:** Relyra v1.7 — Adoption Evidence Demo
**Researched:** 2026-06-12
**Confidence:** HIGH

## Executive Recommendation

The milestone should make Relyra's adopter story clickable. Phase 50 proved a lot in tests, but not in a launched host app. v1.7 should close that last adoption gap with a runnable SaaS demo that shows setup, login, operator diagnosis, and durable stores in one deterministic loop.

## Table Stakes

### Runnable Phoenix SaaS Demo

- Phoenix app at `demo/ledger_loop`.
- Relyra path dependency.
- Excluded from Hex packaging.
- Boots locally through `mix phx.server` and Docker Compose.
- First screen is the working LedgerLoop workspace, not a landing page.

### Realistic Demo Domain

Use the existing LedgerLoop / Northstar Health story:

- LedgerLoop: B2B finance/operations SaaS.
- Northstar Health: enterprise customer tenant.
- Personas: platform engineer, customer IT admin, support/operator, end user, security reviewer.

Seed enough data for real workflows: organizations, users, groups, memberships, SAML identities, connections, mappings, active/staged certificates, audit rows, trace/failure scenarios.

### Host-Owned Customer Setup Flow

The demo host app owns customer/admin setup pages:

- Tenant selector and SSO status.
- Copyable SP ACS URL and Entity ID.
- Provider-specific setup checklist.
- IdP metadata/manual field intake.
- Attribute/group mapping preview.
- Test-login receipt.
- Enable/go-live receipt.

This should borrow from successful SSO onboarding products such as WorkOS Admin Portal and SSOReady setup links: make the settings exchange explicit, copyable, provider-aware, and receipt-driven. The difference is architectural: Relyra is not a hosted broker, so the host app owns the customer workflow.

### Mounted Relyra LiveAdmin

Relyra LiveAdmin remains the operator trust cockpit:

- Connection list/detail.
- Metadata import/refresh.
- Certificate lifecycle and staged rollover.
- Mappings.
- Risk panels.
- Audit timeline.
- Diagnostic bundle.
- Login trace.

Do not make LiveAdmin a branded customer portal in v1.7. Use the demo to discover reusable boundaries before promoting anything to Relyra core.

### Production-Like Store Proof

The happy path must use Ecto-backed stores:

- `Relyra.ConnectionResolver.Ecto`.
- Host wrapper for `Relyra.RequestStore.Ecto`.
- Host wrapper for `Relyra.ReplayStore.Ecto`.
- Host-owned session/user mapping.

The current adoption fixture gap is that Ecto connection resolution is proven while request/replay stores can still use ETS. v1.7 should close that.

### Local FakeIdP Proof

Default proof should be deterministic and offline:

- Demo-only `/dev/idp/:connection_id/sso` route in dev/test.
- Genuine Relyra test XMLDSig signer.
- Auto-submitted browser POST to ACS.
- Receipt that states assertion verified, mapped, request matched, replay checked, and session established.

Never describe this as a production IdP.

### Optional Keycloak Proof

Optional profile proves external IdP interop through a launched Phoenix app:

- Keycloak realm import.
- Browser-visible ACS URL using `localhost:${DEMO_WEB_PORT}`.
- Readiness probes.
- Browser E2E through the Keycloak form.

Keep this optional until burn-in because Keycloak adds startup and browser-form flake risk.

### Browser And CI Receipts

Browser E2E should cover:

- Customer/admin setup checklist or receipt.
- Operator sees the seeded connection in mounted LiveAdmin.
- End user completes SAML login and sees receipt.
- Support/operator opens a login trace.

## Differentiators

- Demo is evaluator-grade: one command, seeded, resettable, browser-visible.
- Demo proves strictness and explainability, not just a green login.
- Demo shows where Relyra ends and the host app begins.
- Demo turns docs/JTBD into a living artifact future adopters can inspect.

## Explicit Non-Features

- No hosted broker.
- No production IdP.
- No SCIM.
- No new providers.
- No AUTHN-POST, KMS, or signed SP metadata.
- No public API shape changes.
- No default-tightening or security posture change.

## Cross-Ecosystem Lessons

- WorkOS and SSOReady win onboarding by reducing the settings-exchange burden with guided setup, copyable values, provider-aware instructions, and short feedback loops.
- Spring Security/Sustainsys show the value of framework-native registration/config objects, not raw XML toolkit ergonomics.
- passport-saml/node-saml show that multi-tenant cache/request correlation is a footgun; the demo must visibly prove per-tenant request/replay isolation.
- crewjam/saml and similar libraries gain adoption trust from real sample apps, but Relyra's sample must preserve strict SAML invariants.

## Footguns

- Do not disable signatures or replay checks to make the demo smoother.
- Do not trust document `KeyInfo`.
- Do not use ETS in the demo happy path.
- Do not imply metadata refresh auto-promotes trust.
- Do not leak raw XML, PEM, secrets, or unredacted identifiers in demo logs/screens.
- Do not let the optional Keycloak path block the core deterministic proof.
