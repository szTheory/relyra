# Phase 70: Keycloak behind the proxy - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 70 makes the optional real-Keycloak profile complete one truthful, browser-driven SAML round trip through the shared Traefik edge: LedgerLoop is public at `http://relyra.localhost`, Keycloak is public at `http://keycloak.relyra.localhost`, Keycloak posts a signed assertion to the exact mounted connection-scoped ACS, Relyra verifies it against a configured IdP certificate, and LedgerLoop maps the principal and records its host-owned session-establishment receipt.

This is **demo + Docker + tests only**. It may add the minimal demo-owned provisioning, identity fixture, login affordance, and browser/integration proof needed to satisfy KC-01; the Phase 70 roadmap file list is illustrative rather than exhaustive because the current realm and stale browser spec cannot satisfy success criterion 3 on their own. It must not change `lib/`, Relyra's public API or behaviour callbacks, parser/crypto/replay/audit/security posture, protocol surface, or the Hex package whitelist.

The zero-setup solo/FakeIdP path remains unchanged and remains the daily deterministic positive/tamper proof. Phase 71 owns the Makefile, launcher/banner, and command UX. Phase 72 owns the Docker guide and README routing.

</domain>

<decisions>
## Implementation Decisions

### Keycloak connection provisioning
- **D-01:** Provision a **separate, clearly named, stable Keycloak connection** (for example, “Northstar Health — Keycloak real IdP”) with its own stable valid ULID. Never repoint, mutate, or replace the existing FakeIdP-enabled connection.
- **D-02:** Use a profile-scoped, idempotent **demo-owned one-shot provisioner** that runs only after Keycloak and LedgerLoop are ready. The normal `LedgerLoop.Demo.Reset.reset!/0` and ordinary app boot must remain independent of Keycloak; selecting the optional Keycloak profile is the only path that triggers provisioning.
- **D-03:** The provisioner fetches the local realm SAML descriptor over container DNS, extracts Keycloak's generated signing certificate, and persists it as the connection's configured active IdP signing certificate through the existing audited Relyra Ecto/metadata seams. The descriptor fetch is bounded local-demo bootstrap, not a new production trust policy. Assertion-time document `KeyInfo` remains ignored and disabled.
- **D-04:** Do not commit or import a fixed Keycloak private signing key. A static certificate paired with a runtime-generated Keycloak key is also forbidden because it silently breaks after `down -v` or key rotation.
- **D-05:** Provisioning is fail-closed and retryable: create/update the connection as draft, apply metadata/certificate state with actor/cause/correlation audit context, add the matching host-owned `SAMLIdentity`, and enable only after all required state is present. Every Relyra trust mutation must co-commit its audit row through the existing command seams; no new trust state via bare `Repo.insert_all/3`.
- **D-06:** Repeated provisioning produces exactly one enabled Keycloak connection, one matching host identity, and the intended active IdP signing certificate(s), with no duplicate certificate, identity, or no-op trust-mutation audit churn. A fresh Keycloak key must safely replace/stage the configured local-demo trust state before login is enabled.
- **D-07:** Use a dedicated non-admin Northstar persona whose NameID matches a seeded local user (prefer `sarah@northstar.example.com`). The host identity's issuer must equal Keycloak's browser-facing realm issuer; `admin@example.com` is not a valid proof persona because the current mapper cannot resolve it.

### Solo versus proxy exposure
- **D-08:** The supported Keycloak proof is **proxy-only**. Remove the published `localhost:8080` browser path and do not maintain two public identities for the same IdP. The no-proxy solo experience continues to use FakeIdP.
- **D-09:** The Keycloak service joins the Compose default network for service-DNS bootstrap and the external proxy network for Traefik. Its Traefik router/service names are Relyra-prefixed, `traefik.enable=true` is explicit, and the load-balancer target is Keycloak's private HTTP port.
- **D-10:** Keycloak's health/readiness endpoint is internal only (the management listener in the current Keycloak line, normally port `9000`). Do not publish or route health/metrics through Traefik. The provisioner and E2E harness wait on readiness and report which layer failed.
- **D-11:** There is no second “legacy-but-equivalent” local Keycloak overlay. If a maintainer needs low-level container inspection, use Docker/service-DNS tooling; do not turn an internal debugging address into another supported browser contract.

### Split-horizon URL contract
- **D-12:** One public-host input governs the pair: `${RELYRA_HOST:-relyra.localhost}` for LedgerLoop and `keycloak.${RELYRA_HOST:-relyra.localhost}` for Keycloak. Do not expose independent issuer/SSO/ACS/Keycloak-host overrides that can create mixed-origin states. `DEMO_PROXY_NETWORK` remains the separate narrow network-name hook established in Phase 69.
- **D-13:** Set Keycloak's hostname to the **full fixed public URL** (`http://keycloak.${RELYRA_HOST:-relyra.localhost}`), enable `KC_PROXY_HEADERS=xforwarded`, and retain HTTP only for this approved dev profile. Remove the permissive/dynamic hostname posture (`KC_HOSTNAME=localhost`, `KC_HOSTNAME_STRICT=false`, and obsolete proxy modes). Traefik must overwrite forwarded headers; direct host access to Keycloak is unavailable.
- **D-14:** The imported realm uses environment placeholders sourced from the same public-host input. Its SAML client ID equals the SP entity ID, preferably `http://${RELYRA_HOST}/saml/<keycloak_connection_id>/metadata`; root/base/admin URLs use the public app origin; and the POST ACS/redirect URI is exactly `http://${RELYRA_HOST}/saml/<keycloak_connection_id>/acs`. The stale `/saml/sso/acs`, `/auth/saml/*`, `demo_app:4000`, and `localhost:4000` values must not remain in the Keycloak client contract.
- **D-15:** Browser-visible realm issuer and SSO URL are `http://keycloak.${RELYRA_HOST}/realms/demo-app` and its public SAML endpoint. Container-only `http://keycloak:8080` is used solely for readiness/bootstrap and is never persisted as issuer/SSO URL, emitted in AuthnRequest/metadata, placed in Recipient/Destination, or shown as an operator-facing SAML setting.
- **D-16:** Realm startup import is idempotent but does not overwrite an existing realm. The E2E/reset lifecycle must explicitly recreate Keycloak state when the public hostname/client contract changes, preventing a stale imported realm from masquerading as current configuration.

### End-to-end proof receipt
- **D-17:** Replace the existing `keycloak.spec.ts`; do not incrementally preserve its obsolete `/setup`, `/auth/saml/login`, `admin/admin`, ambiguous-selector, or “not on a Keycloak URL” assertions.
- **D-18:** Host-side Playwright drives the actual public proxy topology. It starts from a dedicated, clearly labelled Keycloak login affordance, asserts navigation to `keycloak.relyra.localhost`, authenticates the Northstar persona, observes the exact `POST /saml/<keycloak_connection_id>/acs` and its success redirect, then lands on the semantic LedgerLoop workspace at `relyra.localhost`.
- **D-19:** The browser journey continues through the existing demo admin-login affordance to the Keycloak connection's Login Trace. It asserts the newest/correlation-specific successful path includes the three canonical verifier steps persisted by the existing telemetry lifecycle: protocol validation, signature verification, and replay check. Host user mapping and session establishment are proved separately by the successful workspace return and durable `LoginReceipt`; response decoding occurs before the consume trace starts and is not synthesized into the canonical audit row. It must not accidentally assert against the pre-seeded support-failure trace.
- **D-20:** Focused Phoenix/Ecto tests, separate from Playwright, prove the durable `LoginReceipt` and the provisioner's connection/certificate/identity/audit/idempotency invariants. The browser test must not query Postgres directly or expose database credentials/schema as browser-test concerns.
- **D-21:** Use truthful product language: this demo proves a **verified sign-in / host session-establishment receipt**. The current adapter records a durable `LoginReceipt` but does not create a conventional browser authorization cookie; Phase 70 must not claim an authenticated cookie session or redesign the public `SessionAdapter` contract.
- **D-22:** Keep FakeIdP as the deterministic tamper/adversarial lane. A real-Keycloak replay-negative companion is welcome only if it can reuse the captured genuine response and prove a typed replay rejection plus no second receipt; never mutate XML in browser code, trust `KeyInfo`, or relax signature policy to manufacture a negative case.

### JTBD, affordance, and operator experience
- **D-23:** `/login/test` presents two distinct jobs without exposing backend topology: the existing “Simulate Login via FakeIdP” path and, only when provisioned, a semantic link such as “Test with Keycloak (optional real IdP).” Do not disguise Keycloak as the default login or leave a broken control when the optional profile is absent.
- **D-24:** The evaluator's receipt is visible and specific: “Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.” Avoid generic “Success!” copy and avoid implying that color alone proves trust.
- **D-25:** Reuse the existing page and Login Trace UI rather than introducing a new component system in this infrastructure phase. Any touched affordance must remain keyboard-operable, use native link/button semantics, preserve visible focus and accessible names, and follow the Canonical Lock Set's calm, exact, operator-friendly voice. No broad light/dark redesign belongs here.
- **D-26:** Failure output from provisioning/E2E distinguishes proxy/DNS, Keycloak readiness/authentication, realm/client URL mismatch, metadata/certificate, ACS validation, user mapping, and session receipt failures. Diagnostics must be actionable without logging credentials, raw assertions, descriptor XML, PEMs, or other sensitive material.

### the agent's Discretion
- Exact stable ULID/UUID values, Mix task/service names, Traefik label suffixes, `data-testid` names, readiness retry timing, and diagnostic artifact paths.
- Exact transaction choreography through existing `Relyra.Ecto.Connections`, `Relyra.Metadata.Import` / `MetadataApply`, certificate inventory, and `AuditWriter` seams, provided each trust mutation co-commits its audit row and the connection cannot become enabled in partial state.
- Whether the genuine-response replay assertion fits cleanly in the Phase 70 E2E harness; omit it rather than create a brittle or security-weakened browser test.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and upstream decisions
- `.planning/PROJECT.md` — v1.10 goal, hard constraints, approved host/proxy choices, and product/security posture.
- `.planning/REQUIREMENTS.md` — KC-01 acceptance contract and explicit demo/docker/docs-only boundary.
- `.planning/ROADMAP.md` — Phase 70 goal, success criteria, dependency on Phase 69, and Phase 71/72 handoff.
- `.planning/STATE.md` — current milestone state and accumulated v1.10 decisions/risks.
- `.planning/phases/69-compose-split-fleet-proxy/69-CONTEXT.md` — solo/fleet Compose split, proxy network/naming, public endpoint config, override hooks, and Phase 70 boundary.

### Project research, ecosystem posture, and brand
- `prompts/elixir-saml-lib-deep-research.md` — personas, domain language, framework-native SAML lessons, Keycloak/FakeIdP proof strategy, trust-path evidence, and cross-ecosystem footguns.
- `prompts/ecto-best-practices-deep-research.md` — transactional invariants, idempotency/upserts, auth data, and integration testing with the real database.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Plug/Phoenix/Ecto boundary design and consumer-oriented host integration.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — four-layer testing, CI-as-specification, telemetry, error tuples, documentation-first DX, and Relyra-specific security gotchas.
- `brandbook/notes/decision-log.md` — **Canonical Lock Set** and current voice/accessibility decisions; supersedes conflicting values in the older narrative brand prompt.
- `brandbook/README.md` — current design-system artifact routing and light/dark/system behavior.

### Compose, Keycloak, and public-host proof
- `docker-compose.yml` — current optional Keycloak and browser services, stale direct port, hostname settings, profiles, and readiness wiring.
- `docker-compose.proxy.yml` — Phase 69 public-host environment and Traefik pattern to extend for Keycloak.
- `docker/traefik/compose.yml` — shared proxy provider/network/entrypoint contract.
- `docker/keycloak/realm-demo-app.json` — realm user/client/signature configuration and stale URL contract to replace.
- `scripts/test_fleet_proxy_e2e.sh` — established hermetic proxy lifecycle, diagnostics, and host-side browser-proof pattern.
- `test/browser/fleet_proxy.spec.mjs` — public-origin and LiveView proof style.
- `demo/ledger_loop/test/browser/keycloak.spec.ts` — stale redirect-only Keycloak test to replace.
- `demo/ledger_loop/test/browser/fake_idp.spec.ts` — truthful current SP→IdP→ACS→workspace browser journey to mirror without merging the two proof lanes.

### Demo provisioning, mapping, and receipt seams
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — deterministic FakeIdP connections/users/identities that must remain stable.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — ordinary deterministic reset path; must not acquire an optional Keycloak dependency.
- `demo/ledger_loop/docker-entrypoint.sh` — current boot/migration/seed ordering the optional provisioner must not destabilize.
- `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex` — NameID + issuer mapping contract for the Keycloak persona.
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` — durable host-owned `LoginReceipt` proof and current non-cookie return semantics.
- `demo/ledger_loop/lib/ledger_loop/accounts/login_receipt.ex` — durable receipt schema for focused integration assertions.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` — canonical `/saml/:connection_id/{metadata,login,acs}` mount shape.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` — existing `/login/test` entry point to extend minimally.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` — existing FakeIdP affordance and obsolete Phase-55 copy.
- `lib/relyra/live_admin/connection_trace_live.ex` — existing operator-visible Login Trace receipt to reuse.

### Audited trust mutation seams
- `lib/relyra/ecto/connections.ex` — audited connection create/update/enable/disable transaction seam.
- `lib/relyra/metadata/import.ex` — metadata parsing/candidate path for installing Keycloak's local descriptor-derived trust state.
- `lib/relyra/ecto/metadata_apply.ex` — audited metadata/certificate revision application and failure recording.
- `lib/relyra/ecto/certificate_inventory.ex` — certificate lifecycle/inventory seam; do not bypass with runtime trust inserts.
- `lib/relyra/ecto/audit_writer.ex` — append-only co-commit invariant for every trust mutation.
- `lib/relyra/telemetry/handlers/login_trace.ex` — successful/rejected runtime step persistence consumed by Login Trace.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 69 already provides the explicit base-plus-proxy Compose topology, external `proxy` network, env-driven Phoenix public URL/check-origin configuration, namespaced Traefik labels, and a hermetic lifecycle/browser harness.
- `Relyra.Ecto.Connections` and `Relyra.Metadata.Import` / `MetadataApply` already encode audited connection and certificate mutation; the demo provisioner should orchestrate these instead of inventing another trust writer.
- LedgerLoop already has deterministic Northstar users, issuer/subject-based mapping, a durable `LoginReceipt`, a Login Trace UI, and an operator admin-login affordance.
- The FakeIdP browser test already demonstrates the correct public proof shape: start at a labelled route, follow SP initiation, submit to the connection-scoped ACS, and assert a semantic workspace result.

### Established Patterns
- Optional external systems remain profile-scoped; the ordinary demo stays deterministic and self-contained.
- Public browser origins and container service DNS are separate contracts. Browser-facing SAML fields always use the public origin; internal addresses are transport-only.
- Host application owns user mapping/session/authorization. Relyra owns protocol and trust verification; evidence and copy must preserve that boundary.
- Trust state is durable, auditable, and fail-closed. The project does not accept runtime-only configuration, document-provided keys, or structure-only browser smoke tests as proof.
- UI changes are minimal, semantic, and user-job focused; backend topology belongs in diagnostics/docs, not primary labels.

### Integration Points
- Move/extend the optional Keycloak service into the explicit proxy proof graph, remove its host port, add Relyra-prefixed Traefik routing, fixed public hostname, internal readiness, and realm env input.
- Add a demo-local provisioner and E2E ordering point after `demo_app` + Keycloak readiness and before browser proof.
- Add the Keycloak connection/identity without changing the four existing FakeIdP/support scenarios or their tests.
- Extend `/login/test` with a conditional real-IdP affordance and replace the stale Keycloak Playwright journey.
- Reuse Login Trace plus focused demo integration tests for the crypto→mapping→receipt proof chain.

</code_context>

<specifics>
## Specific Ideas

- Default browser route map: LedgerLoop `http://relyra.localhost`; Keycloak `http://keycloak.relyra.localhost`; Keycloak admin under that same IdP origin; ACS `http://relyra.localhost/saml/<keycloak_ulid>/acs`.
- Default container-only map: Keycloak application traffic/metadata bootstrap `http://keycloak:8080`; readiness on Keycloak's internal management listener; LedgerLoop service DNS remains transport-only.
- User-facing nouns: SAML connection, IdP, SP/relying party, Entity ID/issuer, SSO URL, ACS URL, signing certificate, assertion, validation trace, verified sign-in receipt.
- Proof event chain: AuthnRequest started → IdP authenticated → SAMLResponse posted → Relyra decoded/validated/verified/replay-checked → LedgerLoop mapped user → LedgerLoop recorded session-establishment receipt.
- Research-backed topology: fixed full Keycloak hostname plus `xforwarded`, no dynamic hostname, no direct browser bypass, and no routed management port. Primary references: Keycloak's current hostname, reverse-proxy, management-interface, container, and realm-import documentation; Traefik's Docker-provider/network/explicit-enable documentation.
- The approved north-star path recorded in project planning (`/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md`) is not present on this machine. Its locked Phase 70 decisions are already carried forward in `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and Phase 69 context; planning must not block on the missing file or invent contrary decisions.

</specifics>

<deferred>
## Deferred Ideas

- Phase 71: Makefile/launcher commands, URL banner, `make fleet`, `doctor`, and `scripts/demo` delegation consume the finalized Keycloak profile and derived host pair.
- Phase 72: Docker DX guide and README routing explain solo FakeIdP versus optional real-Keycloak proof, public versus internal URLs, reset semantics, and layered receipts/failure diagnosis.
- TLS/mkcert, hashed per-checkout hostnames, production Keycloak hardening/deployment, and a conventional browser-cookie host session remain outside v1.10/Phase 70.

</deferred>

---

*Phase: 70-keycloak-behind-the-proxy*
*Context gathered: 2026-08-26*
