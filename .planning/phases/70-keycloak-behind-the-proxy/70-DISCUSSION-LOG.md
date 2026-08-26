# Phase 70: Keycloak behind the proxy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 70-keycloak-behind-the-proxy
**Areas discussed:** Keycloak connection provisioning, Solo versus proxy exposure, Split-horizon URL contract, End-to-end proof receipt

---

## Keycloak connection provisioning

| Option | Description | Selected |
|--------|-------------|----------|
| Replace the FakeIdP connection | Repoint the existing deterministic enabled connection at Keycloak. Smallest record count, but destroys the zero-dependency proof and couples ordinary reset/boot to an optional IdP. | |
| Commit a fixed Keycloak signing key | Seed a static certificate and private IdP key so provisioning needs no network step. Hermetic, but teaches unsafe key handling and is brittle across Keycloak versions/key lifecycle. | |
| Profile-scoped audited provisioner | Keep a separate Keycloak connection; after readiness, fetch local metadata, install Keycloak's generated cert through audited seams, add the matching identity, and enable idempotently. | ✓ |

**User's choice:** The user asked for a one-shot, deeply researched recommendation and delegated the final choice. Selected the profile-scoped audited provisioner.
**Notes:** Preserve FakeIdP unchanged. No response `KeyInfo`, static private key, direct trust inserts, or ordinary-boot dependency. Use a Northstar persona/NameID the existing host mapper resolves.

---

## Solo versus proxy exposure

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `localhost:8080` plus proxy | Preserves a familiar curl/admin path, but creates two public IdP identities, retains fleet port collisions, and permits bypass of the forwarded-header proof boundary. | |
| Proxy-only Keycloak | One browser origin at `keycloak.relyra.localhost`, no host port, no split-brain issuer/redirect/cookie behavior, and direct alignment with KC-01. | ✓ |
| Separate local/proxy overlays | Supports both workflows explicitly, but doubles realm/client/test/doc combinations and makes an internal transport path appear product-equivalent. | |

**User's choice:** Delegated one-shot recommendation. Selected proxy-only Keycloak.
**Notes:** Solo/no-proxy continues to use FakeIdP. Container/service-DNS access remains available for readiness and provisioning but is not a browser contract.

---

## Split-horizon URL contract

| Option | Description | Selected |
|--------|-------------|----------|
| Hard-code all public URLs | Easy to inspect but silently breaks the retained hostname override and drifts across app/realm/test configuration. | |
| One Compose-owned host contract | Derive LedgerLoop and Keycloak public hosts from one `RELYRA_HOST`, use realm placeholders, persist only public SAML URLs, and keep service DNS internal. | ✓ |
| Dynamic Keycloak hostname | Let incoming forwarded/Host headers determine generated URLs. Less initial config, but weakens Keycloak's hostname security control and makes issuer behavior caller-dependent. | |

**User's choice:** Delegated one-shot recommendation. Selected one Compose-owned public-host contract.
**Notes:** Full fixed `KC_HOSTNAME`, `KC_PROXY_HEADERS=xforwarded`, HTTP dev profile, exact connection-scoped metadata/ACS paths, internal management readiness, and no independent per-field URL knobs.

---

## End-to-end proof receipt

| Option | Description | Selected |
|--------|-------------|----------|
| Redirect-only browser smoke | Assert only that the browser leaves Keycloak. Cheap, but proves neither ACS validation, mapping, nor host receipt and repeats the current hollow test. | |
| Browser test queries Postgres | Can assert the durable row directly, but couples Playwright to backend schema/credentials and exposes implementation guts to the wrong test layer. | |
| Layered browser + trace + Ecto proof | Public-host Playwright proves the IdP/ACS/workspace path and operator trace; focused integration tests prove `LoginReceipt` and provisioning/audit invariants. | ✓ |
| Add a cookie session implementation | Creates conventional browser auth semantics, but changes the host/public integration boundary and is outside Phase 70. | |

**User's choice:** Delegated one-shot recommendation. Selected layered browser, trace, and focused Ecto proof.
**Notes:** Replace the stale Keycloak spec. Use truthful “verified sign-in/session-establishment receipt” language because the current demo adapter persists a receipt but does not create a browser authorization cookie.

---

## the agent's Discretion

- Stable identifier values, names for the one-shot Mix task/service, Relyra-prefixed Traefik label suffixes, readiness retry timing, test selectors, and diagnostic artifact locations.
- Exact audited transaction choreography through existing trust seams, while keeping partial state disabled and retries idempotent.
- Add a genuine-response replay-negative assertion only if it remains stable and does not weaken or duplicate the existing adversarial corpus.

## Deferred Ideas

- Phase 71 launcher/banner/doctor/fleet UX consumes the finalized topology.
- Phase 72 docs teach FakeIdP versus Keycloak proof lanes and public versus internal URLs.
- TLS/mkcert, multi-checkout hostnames, production Keycloak deployment, and cookie-backed host authentication remain out of scope.

---

## Execution checkpoint: Login Trace lifecycle boundary

During Plan 70-01 execution, the genuine signed Keycloak login succeeded and produced a durable `LoginReceipt`, but the canonical successful Login Trace contained the three steps emitted inside `consume_response/3`: validation, signature verification, and replay checking. Response decoding occurs before the consume trace starts; user mapping and session establishment occur after the trace is flushed.

| Option | Description | Selected |
|--------|-------------|----------|
| Expand Phase 70 into `lib/relyra/**` | Change the library telemetry lifecycle so one audit row spans pre-consume decoding through post-consume host mapping/session work. | |
| Preserve the demo/Docker/docs boundary | Assert the canonical three verifier steps and prove host mapping/session establishment separately through workspace return and the durable receipt. | ✓ |

**User's choice:** Preserve the locked v1.10 boundary. D-19 and Plans 70-01/70-05 were corrected to match the existing telemetry contract; no synthetic trace steps or library changes are authorized.
