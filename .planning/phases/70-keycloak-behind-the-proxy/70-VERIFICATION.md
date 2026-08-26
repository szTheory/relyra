---
phase: 70-keycloak-behind-the-proxy
verified: 2026-08-26T20:35:00Z
status: gaps_found
score: 7/16 must-haves verified
behavior_unverified: 5
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 7/16
  gaps_closed:
    - "Sarah's Keycloak SAMLIdentity, matching mapping audit event, and final enablement now commit atomically."
  gaps_remaining: []
  regressions:
    - "Namespaced multiline SAML XML can bypass diagnostic redaction and validation, retaining assertion contents."
gaps:
  - truth: "D-26: failed diagnostics contain no raw SAML assertion, descriptor XML, PEM, credential, cookie, authorization value, or database credential."
    status: failed
    reason: "The redactor and promotion validator recognize only unprefixed Response, Assertion, and EntityDescriptor tags. Namespace-prefixed multiline SAML XML retains inner values and is accepted by validation."
    artifacts:
      - path: "scripts/test_keycloak_proxy_e2e.sh"
        issue: "redact_diagnostics/0 and validate_diagnostic_tree/1 omit optional XML namespace prefixes, while diagnostics_policy_self_test/0 covers only unprefixed single-line XML."
    missing:
      - "Make XML start/end detection namespace-aware and stateful for every protected XML document."
      - "Add a policy self-test with multiline <samlp:Response> and nested <saml:Assertion>/<saml:AttributeValue> sentinels; prove neither tags nor values reach a promoted artifact."
behavior_unverified_items:
  - truth: "Keycloak is reachable in a browser at http://keycloak.relyra.localhost and its effective issuer equals that public host."
    test: "Run the owned Keycloak proxy lifecycle and visit the public Keycloak origin through Traefik."
    expected: "The public endpoint serves demo-app with issuer http://keycloak.relyra.localhost/realms/demo-app; direct host-port access is unavailable."
    why_human: "Static Compose checks prove configuration but this verification did not start Docker services."
  - truth: "A browser Keycloak login posts a signed assertion to the scoped ACS, verifies it, and establishes the LedgerLoop receipt boundary."
    test: "From /login/test, select Keycloak and authenticate Sarah on a freshly provisioned owned stack."
    expected: "The scoped ACS POST redirects to the workspace; the exact receipt and its Validate response, Verify signature, and Replay check rows are visible."
    why_human: "The Playwright spec is substantive and listed, but was not run against a live Keycloak stack."
  - truth: "Each owned E2E lifecycle recreates Keycloak realm state before assessing an import."
    test: "Run the lifecycle twice after changing an allowed realm URL fixture."
    expected: "Only harness-owned volumes are removed and the second run evaluates the current realm rather than a stale import."
    why_human: "The down --volumes choreography is present, but import behavior is runtime-only."
  - truth: "Touched UI preserves usable visible focus behavior and truthful receipt/login presentation."
    test: "Navigate /login/test and the workspace receipt with a keyboard in a browser."
    expected: "Native links visibly focus and optional Keycloak/receipt content remains legible and truthful."
    why_human: "Controller/template tests cannot prove rendered focus or visual presentation."
  - truth: "Missing or incomplete runtime host-admin credentials deny all admin access."
    test: "Run with DEMO_ADMIN_USERNAME/DEMO_ADMIN_PASSWORD absent, then with either value empty; request /login/admin and /relyra/admin/connections/new."
    expected: "Every request is 401 with a Basic challenge and no admin scope session keys."
    why_human: "DemoAdminAuth is source-level fail-closed, but the route suite always installs valid runtime configuration."
---

# Phase 70: Keycloak Behind the Proxy Verification Report

**Phase Goal:** The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Verified:** 2026-08-26T20:35:00Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 70-09 closed the prior mapping/audit atomicity gap.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Keycloak is browser-reachable with public forwarded-host identity. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Static default/override Compose checks pass; no live Docker run was performed. |
| 2 | Realm client URLs, ACS, redirect URIs, and container transport use the required split horizon. | ✓ VERIFIED | `realm-demo-app.json` derives public fields from `RELYRA_HOST`; Compose uses `keycloak:8080` only for the provisioner and exposes no Keycloak host port. |
| 3 | A real browser Keycloak login reaches scoped ACS, cryptographically verifies, and establishes the receipt boundary. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The Playwright spec asserts public Keycloak origin, ACS POST 302, workspace, receipt, and three verifier steps, but was not live-run. |
| 4 | Descriptor trust and Sarah mapping persist through audited co-commit seams, with enable last. | ✓ VERIFIED | `finalize_identity_and_enable/3` wraps identity insert, `AuditWriter.append_event/2`, and `Connections.enable/2` in one transaction; forced-audit and forced-enable rollback tests passed. |
| 5 | Signing-key rotation has no stale enabled trust or duplicate churn. | ✓ VERIFIED | Focused provisioner test passed its disable/resolver/activation/retry assertions. |
| 6 | Fetch, parse, apply, activation, and identity failures leave Keycloak unavailable and create no receipt. | ✓ VERIFIED | Focused injected-failure tests passed. |
| 7 | Only Sarah's exact public-realm identity is provisioned. | ✓ VERIFIED | Focused test queries exactly one `sarah@northstar.example.com` identity with the public issuer. |
| 8 | The owned E2E lifecycle recreates realm state before evaluating an import. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Harness owns a Compose project and uses `down --remove-orphans --volumes`; runtime import behavior was not exercised. |
| 9 | Credential-bearing browser artifacts are never retained and diagnostics retain no protected content. | ✗ FAILED / BLOCKER | Namespace-prefixed multiline SAML XML leaks its inner `AttributeValue` through both redaction and validation. |
| 10 | FakeIdP remains first/independent and Keycloak remains optional behind enabled trust. | ✓ VERIFIED | Login controller renders Keycloak only for its enabled stable connection; focused route tests pass. |
| 11 | The LoginReceipt uses exact truthful wording without cookie/authorization claims. | ✓ VERIFIED | Browser spec checks exact receipt text after workspace return; source query remains durable-receipt based. |
| 12 | Touched UI preserves semantic links and intended presentation. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source/controller coverage proves conditional native links; focus and visual behavior require a browser. |
| 13 | A failed Keycloak destination cannot leave a false-success claim. | ⚠️ insufficient_spec | Backstop truth; no failed-login browser evidence exists. |
| 14 | Narrow trace cards/table keep all evidence operable. | ⚠️ insufficient_spec | Backstop truth; no narrow-viewport evidence exists. |
| 15 | Long trace values remain accessible without hiding security evidence. | ⚠️ insufficient_spec | Backstop truth; no long-value visual evidence exists. |
| 16 | Only runtime-configured host-admin credentials establish demo scope; missing configuration denies access. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `DemoAdminAuth` rejects missing/empty config, but every route test installs valid config. |

**Score:** 7/16 truths verified (5 present, behavior-unverified; 3 insufficient-spec backstops).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.proxy.yml` | Proxy-only Keycloak/provisioner graph | ✓ VERIFIED | Dual networks, xforwarded hostname, private 8080 backend, and no host port are static-checked. |
| `docker/keycloak/realm-demo-app.json` | Public Keycloak/SP SAML contract | ✓ VERIFIED | Public client fields derive from `RELYRA_HOST`; KeyInfo extension is disabled. |
| `keycloak_provisioner.ex` | Canonical descriptor to audited trust orchestration | ✓ VERIFIED | One parser candidate feeds `MetadataApply`; mapping audit and enablement share a final transaction. |
| `keycloak_provisioner_test.exs` | Provision/idempotency/rotation/failure coverage | ✓ VERIFIED | Substantive focused cases include parser count, rotation, audit rollback, and enable rollback. |
| `scripts/test_keycloak_proxy_e2e.sh` | Safe lifecycle and redacted diagnostics | ✗ BLOCKER | The artifact is wired and substantial, but its XML safety policy is bypassable. |
| `demo_admin_auth.ex` and router | Runtime-only host-admin boundary | ⚠️ PARTIAL | Router guards bootstrap and mounted LiveAdmin routes; missing-runtime-config branch lacks regression coverage. |
| `keycloak.spec.ts` | Public ACS/receipt/trace proof | ⚠️ NOT EXERCISED | Concrete assertions exist; live stack was not run. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Proxy Compose | Realm import | `RELYRA_HOST` / `KC_HOSTNAME` | ✓ WIRED | `KEYCLOAK_PROXY_STATIC_ONLY=1` passes default and override render contracts. |
| Provisioner | Parser → `MetadataApply` / certificate inventory | canonical candidate | ✓ WIRED | `Parser.parse`, `Map.from_struct(candidate)`, `MetadataApply.apply_revision`, activation, and retirement are connected. |
| Provisioner | Identity mapping / audit ledger | final transaction | ✓ WIRED | Identity, mapping audit, and enable execute in the enclosing Repo transaction; rollback regressions pass. |
| Admin router | Controller / LiveAdmin mount | `:demo_admin` pipeline | ✓ WIRED | Both `/login/admin` and mounted admin routes pass through `DemoAdminAuth`. |
| Harness | Retained diagnostics | redact → validate → promote | ✗ NOT SAFE / BLOCKER | Optional XML prefixes are absent from both enforcement stages. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Provisioner | candidate/fingerprints | fetched Keycloak descriptor | Yes | ✓ FLOWING |
| Optional login UI | `keycloak_connection_id` | persisted enabled connection lookup | Yes | ✓ FLOWING |
| Workspace receipt | receipt flag | persisted latest `LoginReceipt` query | Yes | ✓ FLOWING |
| Identity mapping | `SAMLIdentity` / mapping audit | seeded Sarah user and public issuer | Yes | ✓ FLOWING |
| Diagnostics | sanitized retained logs | Docker output → redactor → validator | No | ✗ LEAKABLE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Compose/realm host contract | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | Default and override assertions passed | ✓ PASS |
| Current redaction self-test | `KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | Passed, but only unprefixed/single-line XML is tested | ⚠️ INSUFFICIENT |
| Artifact policy | `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | Passed | ✓ PASS |
| Namespace-prefixed multiline redaction | Equivalent `awk | sed` pipeline with nested `samlp:Response`/`saml:Assertion` | Inner `phase70-xml-leak-sentinel` retained | ✗ FAIL |
| Provisioner/admin regressions | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` | 17 tests, 0 failures | ✓ PASS |
| Browser proof availability | `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` | One selected Keycloak test | ? ENUMERATED |
| Full Keycloak lifecycle | Not run | Would start Docker services and use test credentials | ? SKIP |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| KC-01 | 70-01 through 70-09 | Optional proxy-hosted Keycloak with correct forwarded hostname, public realm URLs, and a verified SAML round trip. | ✗ BLOCKED | Topology, trust, mapping audit atomicity, and focused tests are present, but D-26's required diagnostic confidentiality is bypassable; the live round trip was also not re-exercised. |

All nine Phase 70 plans declare `KC-01`; `REQUIREMENTS.md` maps `KC-01` exclusively to Phase 70. No Phase 70 requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/test_keycloak_proxy_e2e.sh` | 37-46, 92-98, 204-218 | Unprefixed XML-only redaction/validation and a self-test that misses namespace-qualified multiline SAML | 🛑 BLOCKER | Can retain assertion content in supposedly safe failure diagnostics. |
| `route_affordance_controller_test.exs` | 8-27 | Setup always supplies configured host-admin credentials | ⚠️ WARNING | Missing/partial runtime configuration has no regression proof, despite source-level fail-closed behavior. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the Phase 70 implementation files. No Phase 70 change touches `lib/relyra/**`, `mix.exs`, or `mix.lock`.

### Gaps Summary

Plan 70-09 correctly closes the prior audit co-commit blocker: the identity mapping, its mapping event, and final connection enablement are now transactional and covered by rollback tests. However, the diagnostic-retention guarantee is still false. A normal namespaced, multiline SAML response leaves nested assertion content in a promoted log because the matcher only recognizes unprefixed tags; the validator repeats the same blind spot. This violates KC-01's D-26 safety contract and must be fixed before Phase 70 can pass.

The missing-runtime-admin-config test is a warning, not the blocker: source behavior is fail-closed, but it needs direct regression coverage.

_Verified: 2026-08-26T20:35:00Z_
_Verifier: the agent (gsd-verifier)_
