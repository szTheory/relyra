---
phase: 51
slug: demo-app-foundation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-12
---

# Phase 51 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Demo app dependency boundary | `demo/ledger_loop` consumes Relyra as a local path dependency. | Build metadata and library APIs |
| Browser to LedgerLoop workspace | Untrusted evaluator/browser receives host-owned workspace, status, and route affordances. | HTML, static CSS, cookies |
| LedgerLoop host routes to Relyra route macros | Host router mounts Relyra SAML and LiveAdmin routes without custom protocol handlers. | Phoenix conn, session, params |
| Workspace to health/readiness probes | Browser and automation read low-sensitivity probe responses. | Text probe status |
| Package boundary | Root Hex package must not include the demo app. | Hex build contents |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-51-01 | Spoofing | `demo/ledger_loop/mix.exs` | mitigate | Uses `{:relyra, path: "../.."}`; app source/config scan has no `Relyra.TestSupport`, `FakeIdP`, or `Keycloak` boot dependency. | closed |
| T-51-02 | Tampering | Phoenix scaffold | mitigate | Generated with `--no-assets`; Phase 51 changes preserve normal Phoenix app/repo/endpoint conventions and isolate UI to static app CSS. | closed |
| T-51-03 | Information Disclosure | generated config | mitigate | Config/source scan found no PEM, XML, assertion, SAML response, RelayState, FakeIdP, or Keycloak material. | closed |
| T-51-04 | Tampering | router | mitigate | Router mounts Relyra via `saml_routes()` and `relyra_admin_routes/2`; no custom metadata/login/ACS controllers were added. | closed |
| T-51-05 | Elevation of Privilege | `LedgerLoop.Relyra.AdminScope` | mitigate | Implements `Relyra.LiveAdmin.ScopeProvider` and returns `{:error, :unauthenticated}` for missing, blank, or non-map session input. | closed |
| T-51-06 | Spoofing | route affordance seams | mitigate | Affordance pages state host ownership and future phase ownership without presenting FakeIdP, Keycloak, seeded data, or durable store proof as complete. | closed |
| T-51-07 | Information Disclosure | `/readyz` | mitigate | `HealthController.ready/2` returns only `ready` or `unavailable`; tests cover both states. | closed |
| T-51-08 | Denial of Service | readiness query | mitigate | `LedgerLoop.Health.ready?/0` uses `SELECT 1` with `timeout: 1000` and no seed-data dependency. | closed |
| T-51-09 | Tampering | health routes | mitigate | `/healthz` and `/readyz` are under dedicated `:health` pipeline; router tests refute browser-pipeline placement. | closed |
| T-51-10 | Repudiation | route/readiness tests | mitigate | Route and controller tests assert route mounts and deterministic readiness override states. | closed |
| T-51-11 | Information Disclosure | workspace template | mitigate | `page_controller_test.exs` refutes `BEGIN CERTIFICATE`, `SAMLResponse`, `Assertion`, `RelayState=`, `FakeIdP`, and `Keycloak` in rendered `/`. | closed |
| T-51-12 | Spoofing | `/login/test` affordance | mitigate | Login page states browser login proof is Phase 54 and external identity-provider proof is Phase 55; it starts no IdP flow. | closed |
| T-51-13 | Repudiation | workspace boundary copy | mitigate | Rendered workspace includes `host-owned` and `Relyra verifies SAML trust`. | closed |
| T-51-14 | Information Disclosure | route affordance pages | mitigate | Route affordance templates contain no raw protocol content, PEM blocks, assertions, request params, FakeIdP, or Keycloak copy. | closed |
| T-51-15 | Tampering | CSS/layout assets | mitigate | Root layout loads `/assets/css/app.css`; generated `default.css` was deleted; app/static scan has no Tailwind, daisyUI, shadcn, React, gradients, or blob tokens. | closed |
| T-51-16 | Information Disclosure | workspace test coverage | mitigate | GET `/` test covers required labels, hrefs, and forbidden token refutations. | closed |
| T-51-17 | Denial of Service | first-screen navigation | accept | Static workspace and placeholder links are low-cost Phoenix responses; active setup/login/support load belongs to Phases 52-55. | closed |
| T-51-18 | Information Disclosure | Hex package contents | mitigate | `scripts/check_demo_package_exclusion.sh` builds and unpacks the package and fails on any `*/demo/*` path. | closed |
| T-51-19 | Tampering | root package whitelist | mitigate | Root `mix.exs` keeps explicit package `files:` whitelist and no demo wildcard inclusion. | closed |
| T-51-20 | Repudiation | package proof evidence | mitigate | Package script prints `demo package exclusion: ok` only after checking local path dependency and unpacked contents. | closed |
| T-51-21 | Elevation of Privilege | release commands | mitigate | Package proof script runs `mix hex.build --unpack` only and contains no publish/retire/API-key command path. | closed |
| T-51-SC | Tampering | Phase 51 dependencies and tooling | mitigate | Approved Phoenix host-app deps only, no npm/pip/cargo installs, no third-party UI registry, and no new Hex dependency beyond approved host/demo needs. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-51-01 | T-51-17 | Phase 51 serves static workspace and placeholder route affordance pages only; deeper setup/login/support flow load is intentionally deferred to later phases. | Plan 51-05 | 2026-06-12 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-12 | 22 | 22 | 0 | OpenAI Codex inline |

Evidence:

- `cd demo/ledger_loop && mix test --warnings-as-errors` -> `10 tests, 0 failures`
- `scripts/check_demo_package_exclusion.sh` -> `demo package exclusion: ok`
- App source/static forbidden-token scan found no PEM/protocol/test-IdP/UI-registry exposure tokens.
- Route/admin/probe source assertions verified Relyra router macros, unauthenticated LiveAdmin scope fallback, health pipeline placement, and bounded readiness query.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-12
