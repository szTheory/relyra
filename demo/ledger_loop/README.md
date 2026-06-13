# LedgerLoop — Relyra Demo App

> This is adoption evidence: a fictional Phoenix B2B SaaS showing Relyra embedded in a real
> host application. It demonstrates the verified trust path, the typed-rejection path, and the
> operator visibility you get on Day 1. It is **not** the library, **not** new capability,
> **not** a production hardening guide, and **not** a hosted service. Its purpose is to show
> exactly what Relyra does in context — and exactly where your app takes over.

LedgerLoop is a fictional multi-tenant SaaS for healthcare billing. It is a
**runnable reference app, not part of the Hex package** — the kind of host application
Relyra is designed to live inside. It uses Relyra as a path dependency and exercises the
full Ecto-backed stores: connection resolver, request store, replay protection, session
adapter, and user mapper. Every login through the demo ends in a cryptographically verified
assertion receipt or a typed rejection — never a silent compromise.

---

## At a Glance

| Demonstrates | Does Not Demonstrate |
|---|---|
| SAML SP happy path: login → verified assertion → audit receipt | OIDC / OAuth flows |
| Typed rejection: tampered signature → named error atom | A hosted broker runtime |
| Ecto-backed stores: request, replay, session, audit | SCIM lifecycle ownership |
| Multi-tenant connection resolver (Northstar Health) | Production IdP behavior |
| Four connection lifecycle scenarios (enabled, draft, rollover, failure) | Security relaxation of any kind |
| Host-app boundary: Relyra verifies; LedgerLoop owns mapping/session/authz | New protocol surface |

See [Scope & Honesty](#scope--honesty) for the full accounting.

---

## Quick Start

### Option A — Docker (Recommended)

Requires Docker with Compose v2.

```bash
scripts/demo doctor
```

```bash
scripts/demo up
```

```bash
scripts/demo urls
```

Visit the URLs printed by `urls`. The demo app loads at `http://localhost:4000`.

### Option B — Local Mix

Requires Elixir 1.15+ and PostgreSQL.

```bash
mix setup
```

```bash
mix phx.server
```

Visit `http://localhost:4000`.

`mix setup` chains `deps.get`, `ecto.create`, `ledger_loop.relyra.migrate`, `ecto.migrate`,
and `priv/repo/seeds.exs` — the seeded Northstar Health tenant, users, connections,
and SAML identity anchors are all inserted on first run.

---

## What You'll See

Navigate to `http://localhost:4000` and click **Login Test** (or visit `/login/test`
directly). You'll see the four Northstar Health connection scenarios. Select the
**Enabled** scenario and click **Simulate Login via FakeIdP**.

**Success path:** The local FakeIdP renders a login form. The default radio button submits
a valid SAML response signed with the FakeIdP's RSA-2048 key. The subject is
`evaluator@example.com` — this is the evaluator test user, separate from the seeded
Northstar Health users. Relyra verifies the assertion signature, audience, recipient,
expiry, and replay guard, then calls LedgerLoop's `UserMapper` and `SessionAdapter`.
The session is established and a `LoginReceipt` row is written.

**Rejection path:** Select **Invalid Login (Tampered Signature)** on the FakeIdP form.
Relyra rejects with a typed error atom (`{:error, :invalid_signature}` or similar).
The host app receives the rejection and renders the error — no silent acceptance,
no half-authenticated state.

**Audit trail:** Visit `/relyra/admin` to see the connection list and inspect the
assertion events and audit rows left by both paths.

> The seeded Northstar Health users (`sarah@northstar.example.com`,
> `chen@northstar.example.com`) have SAML identity anchors that do not match the
> FakeIdP's `evaluator@example.com` subject. The walkthrough correctly documents the
> real default outcome. Reconciling the FakeIdP subject to a seeded identity is a
> future exercise — see [Scope & Honesty](#scope--honesty).

---

## Seeded Data

### Credentials

No passwords. Authentication is identity-keyed through SAML assertions, which is
exactly the point. The host app maps the verified subject to a local user after Relyra
does its job.

| User | Email | Role |
|---|---|---|
| Dr. Sarah | `sarah@northstar.example.com` | Admin |
| Nurse Chen | `chen@northstar.example.com` | Clinical Staff |

Tenant slug: `northstar` (Northstar Health)

### Four Connection Scenarios

| Scenario | Status | What it shows |
|---|---|---|
| Northstar Health (Enabled) | `:enabled` | Happy path — fully configured, active cert |
| Northstar Health (Draft/Missing Metadata) | `:draft` | Incomplete setup — no IdP entity or SSO URL |
| Northstar Health (Staged Rollover) | `:enabled` | Two certs active + next — rollover-in-progress |
| Northstar Health (Support Failure) | `:enabled` | Operator investigation scenario |

Visit `/support/scenario` to trigger the support failure scenario directly.

---

## Key Routes

### LedgerLoop (Host App)

| Route | What it does |
|---|---|
| `GET /` | Home page |
| `GET /login/test` | FakeIdP login affordance — select a connection scenario |
| `GET /login/admin` | Admin login affordance |
| `GET /support/scenario` | Trigger support failure scenario |
| `GET /setup/sso` | SSO connection setup LiveView (operator-facing) |

### Relyra (Library Routes)

| Route | What it does |
|---|---|
| `GET /saml/metadata` | SP metadata XML for this app |
| `POST /saml/acs` | Assertion Consumer Service — receives SAML responses |
| `GET /relyra/admin` | LiveAdmin — connection list, cert lifecycle, audit log |

### Health Probes

| Route | What it does |
|---|---|
| `GET /healthz` | Liveness probe |
| `GET /readyz` | Readiness probe |

---

## Reset & Test

### Docker

Reset the database (drops, recreates, reseeds):

```bash
scripts/demo reset
```

Run the Playwright browser tests (requires keycloak and browser profiles; optional):

```bash
scripts/demo test
```

Tear down all containers and volumes:

```bash
scripts/demo down
```

### Local Mix

```bash
mix ecto.reset
```

This runs `ecto.drop` + `ecto.setup` (which chains create, migrate, and seed).

---

## Optional Keycloak Profile

The Docker Compose file includes a `keycloak` profile for testing against a real IdP:

```bash
docker compose --profile keycloak up -d
```

Keycloak starts at `http://localhost:8080` (override with `KC_PORT`). It imports the
`docker/keycloak/realm-demo-app.json` realm on startup. This profile is **optional** — the
core demo works entirely with the local FakeIdP. Keycloak adds proof that Relyra's
SAML flow works against a real protocol implementation, not just a test fixture.

### Environment Overrides

| Variable | Default | Controls |
|---|---|---|
| `PORT` | `4000` | Demo app port |
| `PGPORT` | `5432` | PostgreSQL port |
| `KC_PORT` | `8080` | Keycloak port |

---

## Who Owns What

> Relyra gets you to "this assertion is valid for this connection." LedgerLoop gets you to
> "this person may now do these things in our product."

| Concern | Owner | Where you see it in this demo |
|---|---|---|
| Parse XML and verify signature | Relyra | `Relyra.Security.Signature` / `do_verify/4` seam |
| Audience / recipient / replay / typed rejection | Relyra | Typed error atoms returned from `consume_response/3` |
| Tenant identity & connection resolution | LedgerLoop | `LedgerLoop.Relyra.ConnectionResolver` |
| Principal → local-user mapping | LedgerLoop | `LedgerLoop.Relyra.UserMapper` (SAMLIdentity lookup) |
| Session establishment | LedgerLoop | `LedgerLoop.Relyra.SessionAdapter` (LoginReceipt row) |
| Downstream authorization | LedgerLoop | Group memberships, role checks — entirely host-owned |

The boundary is sharp by design. Relyra cannot authorize. LedgerLoop cannot weaken
verification. The demo makes that boundary visible at every seam.

---

## Scope & Honesty

This demo exists as **adoption evidence** — proof that Relyra embeds cleanly into a
real Phoenix host app, not that it solves every SSO problem.

### What this demo proves

- SAML SP assertion verification with strict defaults (RSA signature, audience, recipient, replay, expiry)
- Multi-tenant connection management with Ecto-backed stores
- The typed-rejection path and what it looks like on the host side
- A workable host-app boundary pattern (connection resolver, user mapper, session adapter)
- Operator visibility: LiveAdmin, audit rows, certificate lifecycle

### What this demo does not cover

- **No protocol expansion** — SAML 2.0 POST binding only; no Redirect binding, no artifact binding, no encryption round-trip in this demo
- **No production IdP behavior** — FakeIdP is a local test harness; Keycloak is optional and dev-only
- **No hosted-broker behavior** — this is a library embedded in a host app, not a multi-tenant SaaS broker
- **No security relaxation** — the same strict defaults that gate every production Relyra integration gate
  this demo; the FakeIdP signs with a real RSA-2048 key and Relyra verifies it — nothing weakens validation

The strict defaults are not a demo artifact. They are the invariant the library ships with.
Evaluating this demo is evaluating exactly what ships.

---

## Where to Go Next

| Resource | What it covers |
|---|---|
| [`hexdocs.pm/relyra`](https://hexdocs.pm/relyra) | Full library API and guides |
| [Getting Started](https://hexdocs.pm/relyra/getting_started.html) | Day-1 path: `mix relyra.install`, first provider |
| [Identity Mapping And Provisioning](https://hexdocs.pm/relyra/identity_mapping_and_provisioning.html) | UserMapper, JIT, local account anchors |
| [Production Ecto Path](https://hexdocs.pm/relyra/production_ecto_path.html) | Cluster-safe stores, migrations |
| [Jobs To Be Done And User Flows](https://hexdocs.pm/relyra/jtbd_user_flows.html) | Implementation journey by persona |
| [Troubleshooting](https://hexdocs.pm/relyra/troubleshooting.html) | SAML error atom decoder |

To embed Relyra in your own app, start with `mix relyra.install` — not by cloning this
demo. Cloning gives you a fictional billing app. Installing gives you the library.

---

[![Hex version](https://img.shields.io/hexpm/v/relyra.svg)](https://hex.pm/packages/relyra)
[![Hex docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/relyra)
