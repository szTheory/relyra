# Phase 70: Keycloak behind the proxy - Research

**Researched:** 2026-08-26  
**Domain:** Keycloak 26 behind Traefik with a browser-driven SAML POST proof  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01..D-07 — provisioning and trust:** Create a separate stable Keycloak connection; never mutate the FakeIdP connection. Provision only in an optional, idempotent demo-owned profile after Keycloak and LedgerLoop are ready. Fetch the realm descriptor through container DNS, extract Keycloak's generated signing certificate, and persist it only through the existing audited Ecto/metadata seams. Never import a fixed Keycloak private key or pair a static certificate with a runtime-generated key. Create/update draft state, audit every trust mutation, create the matching `SAMLIdentity`, and enable only after complete state exists. Repeated runs produce one enabled connection, one identity, and intended active certificate state without duplicate/no-op audit churn. Use a non-admin Northstar persona, preferably `sarah@northstar.example.com`, and persist the browser-facing realm issuer.

**D-08..D-11 — exposure:** The supported Keycloak proof is proxy-only: remove the published `localhost:8080` contract. Keycloak joins both the default and external proxy networks, is explicitly enabled for Traefik with Relyra-prefixed names, and receives traffic only on its private HTTP port. Health/readiness stays on the internal management listener; never route it through Traefik. Do not retain a second legacy local overlay.

**D-12..D-16 — split-horizon URLs:** `${RELYRA_HOST:-relyra.localhost}` governs both public hosts, with Keycloak at `keycloak.${RELYRA_HOST:-relyra.localhost}`. Set the full fixed Keycloak public URL, `KC_PROXY_HEADERS=xforwarded`, and HTTP only for this dev profile; remove permissive/dynamic hostname settings. The imported realm uses environment placeholders from that input: client/entity ID, root/base/admin URLs, ACS, and redirects target the public Relyra host; the ACS is exactly `http://${RELYRA_HOST}/saml/<keycloak_connection_id>/acs`. Container-only `http://keycloak:8080` is bootstrap/readiness transport only and must never be persisted or emitted in public SAML fields. Since startup import skips an existing realm, reset/E2E must explicitly recreate realm state when the public contract changes.

**D-17..D-22 — proof:** Replace the obsolete `keycloak.spec.ts`. Host-side Playwright begins from a labelled Keycloak affordance, navigates to the public Keycloak host, authenticates the Northstar persona, observes the exact ACS POST and success redirect, then verifies the semantic workspace and the matching Login Trace path. Focused Phoenix/Ecto tests prove durable `LoginReceipt` plus provisioner trust/audit/idempotency invariants. Do not query Postgres from the browser test. Describe success as a verified sign-in / host session-establishment receipt, not a cookie session. Keep FakeIdP as the deterministic tamper lane; add real-IdP replay only if it reuses a genuine response without brittle or weakened testing.

**D-23..D-26 — UX and diagnostics:** `/login/test` exposes separate FakeIdP and conditional Keycloak jobs without backend-topology copy. Use the exact verified receipt message, reuse existing page/Login Trace UI, preserve native keyboard semantics/focus/accessibility, and make failures distinguish proxy/DNS, readiness/authentication, realm/client URL, metadata/certificate, ACS, mapping, and receipt causes without logging credentials, XML, PEMs, or assertions.

### the agent's Discretion

Exact stable ULID/UUID values, Mix task/service names, Traefik label suffixes, `data-testid` names, readiness retry timing, diagnostic artifact paths, transaction choreography through established audited seams, and whether a genuine-response replay assertion is clean enough to include.

### Deferred Ideas (OUT OF SCOPE)

Phase 71 owns launcher/Makefile/banner/URL UX. Phase 72 owns Docker guide and README routing. TLS/mkcert, hashed hosts, production Keycloak deployment hardening, and a conventional browser-cookie session are outside Phase 70.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KC-01 | Optional Keycloak runs behind `http://keycloak.relyra.localhost` with fixed hostname, x-forwarded proxy headers, public realm URLs, and an end-to-end SAML round trip. | Fixed-host Keycloak/Traefik overlay, placeholder realm contract, descriptor-derived audited trust provisioning, and browser + focused integration validation. |

## Project Constraints (from AGENTS.md)

- Keep the v1.10 demo + Docker + tests boundary: no changes to `lib/`, public APIs, behaviour callbacks, protocol surface, or Hex whitelist. [VERIFIED: AGENTS.md]
- Preserve all strict SAML invariants: configured IdP certificates only, one Saxy parse path, pre-parse guards, cryptographic digest/SignedInfo verification, audited trust mutations, and production replay protection. [VERIFIED: AGENTS.md]
- Route trust mutations through the existing audited Ecto/metadata/certificate seams; never introduce bare trust-state inserts. [VERIFIED: AGENTS.md]
- Keep `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` green; do not weaken the adversarial crypto corpus. [VERIFIED: AGENTS.md]

## Summary

Phase 70 is an integration proof, not a SAML-library change. The public browser contract must have exactly two origins: LedgerLoop at `http://${RELYRA_HOST:-relyra.localhost}` and Keycloak at `http://keycloak.${RELYRA_HOST:-relyra.localhost}`. Keycloak needs a fixed full `KC_HOSTNAME` plus `KC_PROXY_HEADERS=xforwarded`; this retains a stable issuer/SSO authority while allowing Keycloak origin checks to understand Traefik’s forwarded request metadata. [CITED: https://www.keycloak.org/server/hostname] [CITED: https://www.keycloak.org/server/reverseproxy]

The currently committed profile cannot prove KC-01: its Keycloak container publishes host port 8080, declares `KC_HOSTNAME=localhost` with non-strict hostname settings, probes `/health/ready` on port 8080, and imports a client whose entity ID and ACS are obsolete `localhost:4000` paths. [VERIFIED: codebase grep] The phase must move the Keycloak participation into the explicit proxy overlay, use the internal management port for health, and replace the stale browser spec with an actual public-origin, signed POST round trip. [CITED: https://www.keycloak.org/server/reverseproxy] [VERIFIED: codebase grep]

**Primary recommendation:** Implement a proxy-only optional Keycloak profile with a fixed public hostname, environment-substituted realm contract, descriptor-derived audited demo provisioning, and one hermetic host-side browser harness that checks topology, SAML POST, receipt, and Login Trace.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public host routing | CDN / Static | API / Backend | Traefik selects the Keycloak or LedgerLoop private backend from `Host()` labels. [CITED: https://doc.traefik.io/traefik/v3.0/routing/providers/docker/] |
| Keycloak public issuer and SSO URL | API / Backend | CDN / Static | Keycloak owns its emitted SAML identity; the proxy only forwards the browser request. [CITED: https://www.keycloak.org/server/hostname] |
| Realm client ACS/entity URL | API / Backend | Browser / Client | Keycloak validates/uses the configured SP client URL, while the browser performs the final POST. [VERIFIED: docker/keycloak/realm-demo-app.json] |
| Keycloak descriptor bootstrap | API / Backend | Database / Storage | Demo provisioning reads internal Keycloak metadata and persists trusted certificate/connection state through audited Ecto seams. [VERIFIED: 70-CONTEXT.md] |
| Assertion verification and replay check | API / Backend | Database / Storage | Existing Relyra crypto/replay seams remain the enforcement owner. [VERIFIED: AGENTS.md]
| Principal mapping and receipt | API / Backend | Database / Storage | LedgerLoop’s mapper finds `SAMLIdentity`; the session adapter persists `LoginReceipt`. [VERIFIED: demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex] [VERIFIED: demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex]
| Real-browser proof | Browser / Client | API / Backend | Host-side Playwright proves navigation, credentials form, ACS POST, and semantic return without relying on internal DNS. [VERIFIED: 70-CONTEXT.md]

## Standard Stack

### Core

| Component | Pinned Version | Purpose | Why Standard |
|-----------|----------------|---------|--------------|
| Keycloak container | `quay.io/keycloak/keycloak:26.0.7` | Real local SAML IdP | Already pinned in the optional profile; its current hostname, reverse-proxy, management, and import configuration cover this phase. [VERIFIED: docker-compose.yml] [CITED: https://www.keycloak.org/server/hostname] |
| Traefik | `v3.7.1` | Shared `Host()` reverse proxy | The Phase 69 proxy already uses explicit Docker discovery and Relyra namespaced labels. [VERIFIED: docker/traefik/compose.yml] [CITED: https://doc.traefik.io/traefik/v3.0/routing/providers/docker/] |
| Playwright | existing root dev dependency | Host-side browser proof | Existing Phase 69 proof uses a host-side Playwright configuration and `npm run demo:fleet-proxy`; extend this pattern rather than run browser traffic from the Compose `playwright` service. [VERIFIED: package.json] [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `curl --resolve` | Deterministically exercise proxy hosts from shell without wildcard-DNS dependency | Static/runtime readiness and route checks in the hermetic harness. [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |
| Existing Relyra Ecto metadata/certificate/audit seams | Durable, auditable IdP certificate and connection mutation | Only in the optional demo provisioner; never bypass via direct inserts. [VERIFIED: 70-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fixed full `KC_HOSTNAME` | Dynamic hostname (`KC_HOSTNAME_STRICT=false`) | Rejected: Keycloak documents the explicit hostname as a security measure, and the context locks the public URL to prevent mixed-origin issuer states. [CITED: https://www.keycloak.org/server/hostname] [VERIFIED: 70-CONTEXT.md] |
| Public Traefik route | Publish `8080` directly | Rejected: violates proxy-only proof and permits direct access that can bypass the forwarded-header boundary. [CITED: https://www.keycloak.org/server/reverseproxy] [VERIFIED: 70-CONTEXT.md] |
| Runtime-generated descriptor certificate | Fixed signing key/certificate in Git | Rejected: a static certificate mismatches a regenerated Keycloak key after volume reset/rotation. [VERIFIED: 70-CONTEXT.md] |

**Installation:** No new package installation is required. [VERIFIED: package.json]  
**Package Legitimacy Audit:** Not applicable — Phase 70 adds no external language package.

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  | GET http://relyra.localhost/login/test
  v
Traefik (external proxy network) -- Host(relyra...) --> LedgerLoop :4000
  | labelled Keycloak login -> GET /saml/<keycloak-id>/login
  v
Traefik -- Host(keycloak.relyra...) --> Keycloak :8080
  | Keycloak authenticates sarah; signs SAML Response
  | browser POST http://relyra.localhost/saml/<keycloak-id>/acs
  v
Traefik --> LedgerLoop --> Relyra crypto/replay gate --> UserMapper --> LoginReceipt
                                        |                         |
                                        v                         v
                           configured descriptor-derived cert   Login Trace

Provisioner (default Compose network only)
  LedgerLoop --> http://keycloak:8080/realms/demo-app/...descriptor
            --> audited metadata/certificate + identity mutations --> enable connection

Keycloak :9000 /health/ready remains internal; Traefik never routes it.
```

The management interface exposes health by default on port 9000 when enabled; Keycloak explicitly advises proxying only the application port and not the management port. [CITED: https://www.keycloak.org/server/management-interface] [CITED: https://www.keycloak.org/server/reverseproxy]

### Recommended Project Structure

```text
docker/
└── keycloak/realm-demo-app.json         # public-host placeholder client contract
docker-compose.proxy.yml                 # Keycloak proxy-only overlay and labels
demo/ledger_loop/
├── lib/ledger_loop/demo/                # optional provisioner, not Reset.reset!/0
├── lib/ledger_loop_web/controllers/     # conditional Keycloak affordance
├── test/ledger_loop/demo/               # provisioner/audit/idempotency tests
└── test/browser/keycloak.spec.ts         # public browser SAML journey
scripts/                                 # hermetic Keycloak proxy lifecycle/harness
```

### Pattern 1: Fixed public identity, private bootstrap transport

**What:** Persist and emit only public Keycloak URLs; use `keycloak:8080` strictly for container DNS bootstrap/readiness.  
**When to use:** Every descriptor fetch and Compose health dependency in this optional profile.  
**Why:** A full `hostname` fixes externally advertised URLs, while Keycloak allows separately reachable internal communication; internal transport must not leak into SAML issuer/destination/recipient settings. [CITED: https://www.keycloak.org/server/hostname] [VERIFIED: 70-CONTEXT.md]

```yaml
# docker-compose.proxy.yml — values shown as the required shape
keycloak:
  environment:
    KC_HOSTNAME: http://keycloak.${RELYRA_HOST:-relyra.localhost}
    KC_PROXY_HEADERS: xforwarded
    KC_HTTP_ENABLED: "true"
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=${DEMO_PROXY_NETWORK:-proxy}"
    - "traefik.http.routers.relyra-keycloak.rule=Host(`keycloak.${RELYRA_HOST:-relyra.localhost}`)"
    - "traefik.http.routers.relyra-keycloak.service=relyra-keycloak"
    - "traefik.http.services.relyra-keycloak.loadbalancer.server.port=8080"
```

Source: [Keycloak hostname](https://www.keycloak.org/server/hostname), [Keycloak reverse proxy](https://www.keycloak.org/server/reverseproxy), [Traefik Docker routing](https://doc.traefik.io/traefik/v3.0/routing/providers/docker/).

### Pattern 2: Realm JSON derives all browser-visible SP URLs from one input

**What:** Use Keycloak realm-import `${RELYRA_HOST}` placeholders for the SAML client/entity ID, root/base/admin URLs, POST ACS, and redirects.  
**When to use:** The seeded `realm-demo-app.json` client; do not retain literals from the old direct-port contract.  
**Why:** Keycloak resolves environment placeholders in realm configuration, and startup import skips an existing realm; lifecycle reset must therefore destroy/recreate the realm state before testing changed host input. [CITED: https://www.keycloak.org/server/importExport]

```json
{
  "clientId": "http://${RELYRA_HOST}/saml/<stable-keycloak-connection-id>/metadata",
  "rootUrl": "http://${RELYRA_HOST}",
  "baseUrl": "http://${RELYRA_HOST}",
  "adminUrl": "http://${RELYRA_HOST}/saml/<stable-keycloak-connection-id>/acs",
  "redirectUris": ["http://${RELYRA_HOST}/saml/<stable-keycloak-connection-id>/acs"],
  "attributes": {
    "saml.assertion.consumer.url.post": "http://${RELYRA_HOST}/saml/<stable-keycloak-connection-id>/acs"
  }
}
```

Source: [Keycloak realm import](https://www.keycloak.org/server/importExport). The placeholder key and stable connection ID are implementation inputs, not an invitation to create independent host overrides. [VERIFIED: 70-CONTEXT.md]

### Pattern 3: Provision fail-closed, then enable

**What:** The optional profile’s provisioner waits for Keycloak management readiness, reads the internal descriptor, creates/updates draft state through audited connection/metadata/certificate seams, creates the matching issuer+NameID identity, and enables the connection last.  
**When to use:** Only after both services are ready and only for the optional Keycloak profile.  
**Why:** It absorbs Keycloak’s runtime-generated signing key and guarantees the real assertion is verified against configured trust state rather than document `KeyInfo`. [VERIFIED: 70-CONTEXT.md] [VERIFIED: AGENTS.md]

### Anti-Patterns to Avoid

- **Direct Keycloak browser port:** Do not retain `ports: 8080` or document it as a supported browser URL. [VERIFIED: 70-CONTEXT.md]
- **Dynamic hostname settings:** Remove `KC_HOSTNAME=localhost`, `KC_HOSTNAME_STRICT=false`, `KC_HOSTNAME_STRICT_HTTPS=false`, and obsolete proxy modes. [VERIFIED: docker-compose.yml] [VERIFIED: 70-CONTEXT.md]
- **Main-port health check:** Do not test/route `/health` through the public application port; use internal management `:9000`. [CITED: https://www.keycloak.org/server/management-interface]
- **Browser test that only ends “not Keycloak”:** Assert public host, exact ACS POST, workspace semantics, receipt wording, and correlation-specific Login Trace steps. [VERIFIED: 70-CONTEXT.md]
- **Provisioning in ordinary reset/app boot:** The deterministic FakeIdP path must stay independent and usable without Keycloak. [VERIFIED: 70-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SAML signing certificate extraction/trust state | Ad hoc PEM parsing plus direct database writes | Existing descriptor/metadata, certificate inventory, metadata apply, and audit writer seams | Preserves certificate lifecycle and audit co-commit invariants. [VERIFIED: 70-CONTEXT.md] |
| Reverse-proxy host reconstruction | App-side parsing of forwarded headers | Keycloak fixed hostname plus `KC_PROXY_HEADERS=xforwarded`; Traefik’s normal forwarding | Keycloak owns origin checks; proxy headers must be overwritten at the proxy boundary. [CITED: https://www.keycloak.org/server/reverseproxy] |
| Browser DNS workaround | Custom hosts/DNS daemon | Existing host-side Playwright plus `curl --resolve` for shell probes | Phase 69 already has a hermetic pattern that avoids wildcard-DNS assumptions. [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |
| Assertion negative fixture | Browser-side XML mutation | Existing FakeIdP adversarial/tamper lane | Avoids manufacturing an invalid real-IdP scenario by weakening trust or parser rules. [VERIFIED: 70-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: Keycloak still emits `localhost` URLs
**What goes wrong:** Browser login is routed through Traefik but issuer, form action, or realm metadata refers to an internal/direct origin.  
**Why it happens:** The existing compose profile uses `KC_HOSTNAME=localhost` and dynamic hostname relaxation. [VERIFIED: docker-compose.yml]  
**How to avoid:** Set one full public `KC_HOSTNAME`, set `KC_PROXY_HEADERS=xforwarded`, and assert public issuer/SSO fields from the descriptor and browser navigation. [CITED: https://www.keycloak.org/server/hostname]  
**Warning signs:** A Keycloak redirect reaches `localhost:8080`, metadata shows the wrong issuer, or Recipient/Destination mismatch occurs. [VERIFIED: 70-CONTEXT.md]

### Pitfall 2: Startup import silently preserves stale client URLs
**What goes wrong:** Editing `realm-demo-app.json` appears ineffective after the first run.  
**Why it happens:** `--import-realm` skips a realm that already exists. [CITED: https://www.keycloak.org/server/importExport]  
**How to avoid:** Make E2E/reset explicitly recreate Keycloak state before validating an updated public-host contract. [VERIFIED: 70-CONTEXT.md]  
**Warning signs:** Rendered Compose env is correct but descriptor/client config retains old ACS or client ID.

### Pitfall 3: Trust state does not follow Keycloak key regeneration
**What goes wrong:** A `down -v` or realm recreation replaces Keycloak’s signing key but Relyra still trusts the former certificate.  
**Why it happens:** Static committed trust material cannot match a runtime-generated key. [VERIFIED: 70-CONTEXT.md]  
**How to avoid:** Fetch the descriptor after readiness and reconcile the active certificate using audited existing seams before enabling login. [VERIFIED: 70-CONTEXT.md]  
**Warning signs:** Valid Keycloak login fails signature verification after reset.

### Pitfall 4: Management health is accidentally public
**What goes wrong:** Traefik exposes `/health` or port 9000.  
**Why it happens:** Health was formerly checked on the Keycloak application listener. [VERIFIED: docker-compose.yml]  
**How to avoid:** Retain health only in the container/default network on port 9000 and define Traefik’s backend as 8080. [CITED: https://www.keycloak.org/server/reverseproxy]  
**Warning signs:** `curl -H 'Host: keycloak...' http://127.0.0.1/health/ready` returns 200.

### Pitfall 5: A passing browser test proves only a redirect
**What goes wrong:** The test reaches a non-Keycloak URL but never proves signature verification, mapping, or receipt.  
**Why it happens:** The current `keycloak.spec.ts` uses obsolete setup routes and only asserts it is not on a Keycloak URL. [VERIFIED: demo/ledger_loop/test/browser/keycloak.spec.ts]  
**How to avoid:** Wait for and assert the exact ACS POST, semantic workspace, verified-receipt text, then the correlation-specific Login Trace. [VERIFIED: 70-CONTEXT.md]

## Code Examples

### Browser assertion sequence

```typescript
// Source pattern: existing FakeIdP browser test + Phase 70 locked proof contract.
await page.goto("/login/test");
await page.getByRole("link", { name: "Test with Keycloak (optional real IdP)" }).click();
await expect(page).toHaveURL(/keycloak\.relyra\.localhost/);

await page.locator("#username").fill("sarah@northstar.example.com");
await page.locator("#password").fill("<test-only-secret>");
const acsPost = page.waitForResponse((response) =>
  response.url().includes("/saml/<stable-keycloak-connection-id>/acs") &&
  response.request().method() === "POST",
);
await page.locator("#kc-login").click();
expect((await acsPost).status()).toBe(302);
await expect(page.locator("#workspace-title")).toHaveText(/LedgerLoop Workspace/);
await expect(page.getByText("Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.")).toBeVisible();
```

The exact selector/receipt placement is discretionary; the test must use accessible semantics and keep credentials out of diagnostics. [VERIFIED: 70-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `KC_PROXY=edge` / dynamic hostname examples | `KC_PROXY_HEADERS=xforwarded` with explicit hostname | Use current proxy-header configuration; dynamic hostname is expressly not this fixed public-host contract. [CITED: https://www.keycloak.org/server/hostname] [VERIFIED: STATE.md] |
| Health on application listener | Management interface on port 9000 | Keep readiness internal and proxy only the application listener. [CITED: https://www.keycloak.org/server/management-interface] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The existing root Playwright package/configuration can host a new Keycloak proxy command without a new dependency. | Standard Stack / Validation | Low; planner must read `package.json` and existing fleet config before selecting the exact command. |

## Open Questions

1. **Exact optional-profile orchestration point**
   - What we know: It must run after Keycloak and LedgerLoop readiness, be idempotent, and leave normal reset independent. [VERIFIED: 70-CONTEXT.md]
   - What's unclear: Whether a Mix task is invoked by a dedicated one-shot Compose service or by the host E2E harness.
   - Recommendation: Prefer a dedicated profile-scoped one-shot service/task with a bounded retry loop; have the host harness invoke/await it and capture diagnostics.

2. **Genuine-response replay companion**
   - What we know: It is optional and must not mutate browser XML or weaken verification. [VERIFIED: 70-CONTEXT.md]
   - What's unclear: Whether the current harness can capture/replay the POST without brittleness.
   - Recommendation: Treat as a conditional enhancement; KC-01 is satisfied by the positive signed journey plus existing FakeIdP negative lane.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Docker Engine | Compose topology and Keycloak | ✓ | 29.5.2 | — |
| Docker Compose | profile/overlay rendering and lifecycle | ✓ | v5.1.3 | — |
| Node/npm | host-side Playwright command | ✓ | Node v24.19.0 / npm 11.17.0 | existing container browser lane only; not recommended for public-host proof |
| Elixir/Mix | focused demo provisioning tests and repo gates | ✓ | Mix 1.19.5 / OTP 28 | — |
| curl | readiness and `--resolve` probes | ✓ | `/usr/bin/curl` | — |

**Missing dependencies with no fallback:** None.  
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix plus existing root Playwright and Docker Compose [VERIFIED: mix.exs] [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |
| Config file | `playwright.fleet-proxy.config.mjs` is the existing host-side proxy model; introduce a dedicated Keycloak proxy config only if the existing config cannot select the Keycloak spec. [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |
| Quick run command | scoped demo ExUnit command for provisioner/controller tests, e.g. `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` |
| Full suite command | `npm run demo:keycloak-proxy && mix qa && mix ci.security` (add `demo:keycloak-proxy` as the hermetic lifecycle/browser command) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KC-01 | Rendered proxy overlay has no Keycloak host port, fixed full hostname, xforwarded mode, internal health, both networks, and Relyra-prefixed 8080 route. | integration/static | `npm run demo:keycloak-proxy` | ❌ Wave 0 |
| KC-01 | Realm JSON renders public Relyra entity/client/ACS/redirect URLs for default and overridden `RELYRA_HOST`; stale direct/internal URLs absent. | integration/static | `npm run demo:keycloak-proxy` | ❌ Wave 0 |
| KC-01 | Provisioner reconciles descriptor certificate, one draft→enabled connection, matching identity, audited mutations, and idempotency. | ExUnit integration | scoped `mix test` above | ❌ Wave 0 |
| KC-01 | Browser follows public Keycloak login, observes exact ACS POST, reaches workspace, receipt wording, and matching successful Login Trace steps. | Playwright E2E | `npm run demo:keycloak-proxy` | ❌ replace stale spec |
| KC-01 | Existing FakeIdP success/tamper proof remains independent of the Keycloak profile. | regression | `cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs --warnings-as-errors` | ✅ |

### Sampling Rate

- **Per task commit:** Compose render/static assertions plus the scoped ExUnit test for touched demo code.
- **Per wave merge:** `npm run demo:keycloak-proxy` and `mix test --warnings-as-errors`.
- **Phase gate:** `npm run demo:keycloak-proxy && mix qa && mix ci.security && mix format --check-formatted`.

### Wave 0 Gaps

- [ ] `scripts/test_keycloak_proxy_e2e.sh` (or equivalent root npm-script target) — hermetic proxy/network/realm-reset/provision/browser lifecycle with redacted diagnostics.
- [ ] `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — certificate, connection, identity, audit, rotation, and idempotency invariants.
- [ ] Replacement `demo/ledger_loop/test/browser/keycloak.spec.ts` — public host, exact ACS POST, receipt, and trace proof.
- [ ] Static Compose/realm assertions in the harness for default and `RELYRA_HOST` override rendering.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keycloak authenticates; Relyra verifies the returned signed assertion through existing crypto gate. [VERIFIED: AGENTS.md] |
| V3 Session Management | yes | LedgerLoop records a durable host-owned `LoginReceipt`; do not claim/create a cookie session in this phase. [VERIFIED: 70-CONTEXT.md] |
| V4 Access Control | no new control | This phase must not alter host authorization or the published behaviour contract. [VERIFIED: 70-CONTEXT.md] |
| V5 Input Validation | yes | Existing pre-parse guards and one Saxy parse path remain the only XML entry. [VERIFIED: AGENTS.md] |
| V6 Cryptography | yes | Descriptor-derived configured certificate plus existing digest and `SignedInfo` verification; never trust `KeyInfo`. [VERIFIED: AGENTS.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged forwarded host/proto headers | Spoofing | No direct Keycloak browser port; set proxy-header mode only with Traefik overwriting forwarded headers. [CITED: https://www.keycloak.org/server/reverseproxy] |
| Stale/incorrect Keycloak signing certificate | Tampering | Fetch descriptor after readiness and persist via audited certificate lifecycle before enable. [VERIFIED: 70-CONTEXT.md] |
| Assertion key substitution | Spoofing | Ignore document `KeyInfo`; configured IdP certificate only. [VERIFIED: AGENTS.md] |
| Partial trust mutation | Tampering / Repudiation | Draft-first, audited transaction seams, idempotency tests, enable-last. [VERIFIED: 70-CONTEXT.md] |
| SAML response replay | Repudiation | Existing replay gate remains mandatory; do not bypass it for E2E. [VERIFIED: AGENTS.md] |
| Health/metrics exposure | Information disclosure | Keep port 9000 internal and un-routed. [CITED: https://www.keycloak.org/server/reverseproxy] |

## Sources

### Primary (official documentation)
- [Keycloak hostname configuration](https://www.keycloak.org/server/hostname) — explicit full hostname, proxy headers, dynamic-versus-fixed modes.
- [Keycloak reverse proxy configuration](https://www.keycloak.org/server/reverseproxy) — x-forwarded headers, direct-access boundary, application versus management ports.
- [Keycloak management interface](https://www.keycloak.org/server/management-interface) — health on management port 9000.
- [Keycloak realm import/export](https://www.keycloak.org/server/importExport) — placeholders, startup import location, existing-realm skip behavior.
- [Traefik Docker routing](https://doc.traefik.io/traefik/v3.0/routing/providers/docker/) — labels, private backend port, named Docker network.

### Project evidence
- `70-CONTEXT.md`, `AGENTS.md`, `docker-compose.yml`, `docker-compose.proxy.yml`, `docker/keycloak/realm-demo-app.json`, `scripts/test_fleet_proxy_e2e.sh`, and existing demo mapper/session/browser test seams. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — current official Keycloak/Traefik documentation plus pinned project configuration.
- Architecture: HIGH — locked Phase 70 decisions and existing Phase 69/Demo seams directly determine the implementation boundary.
- Pitfalls: HIGH — each is confirmed by current committed stale configuration or official Keycloak behavior.

**Research date:** 2026-08-26  
**Valid until:** 2026-09-25
