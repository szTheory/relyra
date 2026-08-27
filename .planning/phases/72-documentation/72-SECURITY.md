---
phase: 72
slug: documentation
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-08-27
---

# Phase 72 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Documentation → adopter trust decision | Readers may treat guide claims as authoritative descriptions of cryptographic verification and session ownership. | Trust-source, verification, mapping, session, and authorization claims |
| Browser origin → container network | Public `*.localhost` names and internal service-DNS names have different consumers. | Public origins, service hostnames, and descriptor URLs |
| Recovery prose → local persistent data | Reset, reseed, and nuke instructions can destroy database or build/dependency volume state. | Local database and named-volume state |
| HexDocs page → source repository | Published documentation must use durable absolute links for repository-only evaluator material. | Documentation routes and package-boundary claims |
| Library onboarding → demo evaluation | Canonical library integration must remain separate from optional demo and Fleet evaluation. | Day-1 instructions and evaluator commands |
| Router summary → trust/session ownership | Concise entry points can accidentally overstate what Relyra proves or owns. | Security and responsibility claims |
| Make CLI → host shell/Docker daemon | Environment-derived host/network values and launcher failures cross into Docker and curl commands. | Hostnames, ports, network names, and command exit status |
| Docker profile → one-shot provisioner | Container readiness is not proof that trust provisioning succeeded. | Compose profile selection and provisioner exit status |
| Loopback curl → browser-facing Traefik host | A reachable port is insufficient; the public descriptor must bind to the requested entityID. | Public metadata XML and expected entityID |
| Documentation → executable FakeIdP flow | Identity and receipt claims must derive from the exercised controller and database-backed flow. | NameID, mapped user identity, and receipt evidence |
| Documentation → Make/Compose launcher | Optional Keycloak instructions must activate and validate the actual public topology. | Launcher commands and success claims |
| Relyra verification → LedgerLoop responsibilities | Prose must not transfer mapping, session establishment, or authorization ownership into the library. | Verified principal and host-owned application decisions |
| Environment → Make shell recipe | User-controlled `PORT` crosses into host probes and diagnostic output. | Port value and shell arguments |
| Diagnostic output → operator recovery | Operators use listener classification and remediation text to choose a listener and browser origin. | Listener state, process detail, and recovery commands |
| Guide → executable launcher | Documentation must carry the same configured port consumed by Make and Compose. | Port override and emitted loopback origin |
| Test fixture → host process state | Owned stubs must prevent ambient Docker or listener state from determining acceptance. | Simulated command output, status, and call logs |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-72-01 | Spoofing / Elevation of privilege | Solo and Keycloak proof language | high | mitigate | `guides/docker_dev_dx.md` names configured IdP certificates as the sole trust source and assigns mapping, session receipt, and authorization to LedgerLoop; `test/docs/demo_guide_drift_test.exs` locks the receipt and ownership wording. | closed |
| T-72-02 | Tampering / Denial of service | URL map and split-horizon guidance | medium | mitigate | The guide lists exact loopback, Fleet, Keycloak, and dashboard origins and separates browser-facing `*.localhost` from Docker service DNS; the focused documentation test asserts those terms. | closed |
| T-72-03 | Denial of service | Troubleshooting and destructive recovery | medium | mitigate | The guide orders doctor, normal relaunch, destructive reset/reseed, then confirmed nuke; the focused test asserts order and explicit database/volume deletion language. | closed |
| T-72-04 | Spoofing / Elevation of privilege | Demo README and router proof summaries | high | mitigate | `demo/ledger_loop/README.md` preserves the exact receipt boundary and explicitly assigns session establishment and downstream authorization to LedgerLoop; focused router tests enforce it. | closed |
| T-72-05 | Tampering / Repudiation | HexDocs-to-repository links | medium | mitigate | `guides/demo.md` uses exact absolute GitHub URLs for the repository-only Docker guide and LedgerLoop README; `test/docs/markdown_link_smoke_test.exs` enforces published link and package boundaries. | closed |
| T-72-06 | Information disclosure / Spoofing | Package and onboarding claims | medium | mitigate | The routers state that the demo is not part of the Hex package, preserve Day-1 Getting Started ordering, and are covered by package-boundary and router tests; Phase 72 verification confirms package inventory remained unchanged. | closed |
| T-72-07 | Tampering / Elevation of privilege | `make keycloak` profile selection | high | mitigate | `KEYCLOAK_COMPOSE` is the literal base-plus-proxy graph with `--profile keycloak`; the launcher fixture asserts both files, the profile, and command order. | closed |
| T-72-08 | Spoofing / Repudiation | Provisioning and public-route success claim | high | mitigate | `make keycloak` waits for `keycloak_provisioner`, fetches the descriptor through loopback `--resolve`, matches the exact public entityID, and prints routes only afterward; failure fixtures prove nonzero exit and banner suppression. | closed |
| T-72-09 | Denial of service | Public readiness retry | medium | mitigate | The Make target bounds readiness to `KEYCLOAK_ROUTE_ATTEMPTS` with `KEYCLOAK_ROUTE_SLEEP`, exits nonzero on exhaustion, and has a deterministic one-attempt failure fixture. | closed |
| T-72-10 | Information disclosure | Launcher output | medium | mitigate | The new launcher fetches only the public SAML descriptor and emits route or bounded error text; it does not print credentials, assertions, cookies, headers, or key material. | closed |
| T-72-11 | Spoofing / Repudiation | FakeIdP evaluator narrative | high | mitigate | The documentation test cross-reads the FakeIdP controller's Sarah NameID, seeded identity, and exercised database-backed `LoginReceipt` assertion before accepting the README narrative. | closed |
| T-72-12 | Tampering / Denial of service | Keycloak guide commands | high | mitigate | Both detailed documents invoke only `make keycloak`; a focused test binds that prose to the Make target's proxy/profile, provisioning, descriptor-validation, and fail-closed behavior. | closed |
| T-72-13 | Elevation of privilege | Session/authorization ownership prose | high | mitigate | Both guides preserve the exact host-owned receipt language and state that LedgerLoop owns mapping, session establishment, and authorization; focused tests enforce those boundaries. | closed |
| T-72-14 | Information disclosure | Demo credentials and proof prose | medium | mitigate | Phase 72 documentation adds no passwords, assertion payloads, cookies, authorization headers, or raw diagnostics; proof prose is limited to the public subject, validation outcome, and persisted receipt. | closed |
| T-72-15 | Tampering / Denial of service | `doctor` PORT probe and role classification | high | mitigate | `doctor` passes quoted `$${PORT}` plus explicit `demo`, `postgres`, and `proxy` roles to `check_port`; owned fixtures assert actual probe arguments and role-specific outcomes. | closed |
| T-72-16 | Spoofing / Repudiation | Doctor and guide success/recovery claims | high | mitigate | Occupied configured ports make `doctor` fail, remediation carries the same `PORT` through doctor/url/launch, and `make url` emits the matching loopback origin before guide navigation; fixtures assert all steps. | closed |
| T-72-17 | Denial of service | 5432/8080 diagnostic boundaries | medium | mitigate | PostgreSQL remains diagnostic-only and Traefik remains blocking through explicit roles; default, `nc` fallback, unavailable-probe, and configured-port fixtures cover the boundary. | closed |
| T-72-18 | Information disclosure | Host listener diagnostics | medium | mitigate | Diagnostic output is limited to configured port, probe owner detail, listener role, and remediation; no credential, SAML, cookie, header, or key-material output was added. | closed |
| T-72-19 | Tampering | Ordering-test evidence | medium | mitigate | `assert_in_order/2` searches only the unconsumed binary suffix, advances past the full match, and has a repeated-token regression that prevents earlier occurrences from satisfying later steps. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-27 | 19 | 19 | 0 | Codex artifact audit (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-27
