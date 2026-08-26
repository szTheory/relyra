---
phase: 70-keycloak-behind-the-proxy
verified: 2026-08-26T19:47:32Z
status: gaps_found
score: 7/16 must-haves verified
behavior_unverified: 5
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/15
  gaps_closed:
    - "Unauthenticated /login/admin and mounted /relyra/admin routes no longer establish the mutation-capable demo scope."
  gaps_remaining: []
  regressions:
    - "Keycloak identity mapping is inserted outside an audit co-commit and can remain after later enablement failure."
gaps:
  - truth: "Descriptor-derived Keycloak trust, including the Sarah issuer/subject mapping, is persisted through audited co-commit seams and enable remains last."
    status: failed
    reason: "ensure_sarah_identity/1 directly Repo.insert/1s the durable SAMLIdentity without AuditWriter or Repo.transaction, then enable_connection/1 runs afterward. A failed enable can leave the new mapping committed without an append-only mapping audit row."
    artifacts:
      - path: "demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex"
        issue: "Lines 50-51 order identity creation before enablement; lines 230-247 use Repo.insert/1 with neither an audit write nor transaction."
      - path: "demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs"
        issue: "Tests assert only connection/metadata/certificate audit domains and do not force identity-audit or enable failure to prove identity rollback."
    missing:
      - "Create/update the mapping inside an explicit transaction with an AuditWriter mapping event using the existing actor/cause/correlation context."
      - "Make enablement part of that transaction, or roll back/delete a newly created mapping when enablement fails."
      - "Add regression tests for identity-audit failure and enable failure asserting no mapping remains and successful mapping has its matching audit row."
behavior_unverified_items:
  - truth: "Keycloak is reachable in a browser at http://keycloak.relyra.localhost and its effective issuer equals that public host."
    test: "Run the owned Keycloak proxy lifecycle and visit the public Keycloak origin through Traefik."
    expected: "The public endpoint serves demo-app with issuer http://keycloak.relyra.localhost/realms/demo-app; direct host-port access is unavailable."
    why_human: "Compose/static checks prove intent, but this verification did not start Docker services."
  - truth: "A browser Keycloak login posts a signed assertion to the scoped ACS, verifies it, and establishes the LedgerLoop receipt boundary."
    test: "From /login/test, select the optional Keycloak link and authenticate Sarah on a freshly provisioned owned stack."
    expected: "The scoped ACS POST redirects to the workspace; the exact receipt and the same correlation's Validate response, Verify signature, and Replay check rows are visible."
    why_human: "The one Playwright test was enumerated but not run against a live Keycloak stack."
  - truth: "Each owned E2E lifecycle recreates Keycloak realm state before assessing an import."
    test: "Run the lifecycle twice after changing an allowed realm URL fixture."
    expected: "Only harness-owned volumes are removed and the second run evaluates the current imported realm rather than a stale realm."
    why_human: "The scoped down --volumes choreography is present, but Keycloak import behavior is runtime-only."
  - truth: "Touched UI preserves usable visible focus behavior and Canonical Lock Set presentation."
    test: "Navigate /login/test and the workspace receipt with a keyboard in a browser."
    expected: "Native links visibly focus and the receipt/link remain legible and truthful."
    why_human: "Controller/template tests cannot prove rendered focus or visual presentation."
  - truth: "Missing or incomplete runtime host-admin credentials deny all admin access."
    test: "Start LedgerLoop with DEMO_ADMIN_USERNAME/DEMO_ADMIN_PASSWORD absent, then with either value empty; request /login/admin and /relyra/admin/connections/new."
    expected: "Each request is 401 with the Basic challenge and no admin session keys."
    why_human: "The Plug's code is fail-closed, but every current route test installs valid configuration, so the runtime-configuration branch is not behaviorally exercised."
---

# Phase 70: Keycloak Behind the Proxy Verification Report

**Phase Goal:** The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Verified:** 2026-08-26T19:47:32Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 70-08 closed the prior public admin-scope escalation.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Keycloak is browser-reachable with public forwarded-host identity. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Static harness passed default/override proxy graph; no live Docker stack was run. |
| 2 | Realm client URLs/ACS/redirects use `relyra.localhost`; `keycloak:8080` is transport-only. | ✓ VERIFIED | Static harness passed both host renderings; realm client fields derive from `RELYRA_HOST`, and Traefik targets only private port 8080. |
| 3 | A real browser Keycloak login reaches scoped ACS, cryptographically verifies, and establishes the receipt boundary. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `keycloak.spec.ts` asserts the public origin, exact POST ACS, 302, receipt, and three trace steps, but was only enumerated. |
| 4 | Descriptor trust and Sarah mapping persist through audited co-commit seams, with enable last. | ✗ FAILED / BLOCKER | `ensure_sarah_identity/1` uses bare `Repo.insert/1`, with no mapping audit event or transaction; it runs before enablement. |
| 5 | Signing-key rotation has no stale enabled trust or duplicate churn. | ✓ VERIFIED | Focused provisioner test passed its disable/resolver/activation/retry assertions. |
| 6 | Fetch/parse/apply/activation/identity failures leave Keycloak unavailable and create no receipt. | ✓ VERIFIED | Focused injected-failure tests passed (17 focused tests total); each asserts no enabled connection and no receipt. |
| 7 | Only Sarah's exact public-realm identity is provisioned. | ✓ VERIFIED | Focused test queries one `sarah@northstar.example.com` identity with the exact public issuer. |
| 8 | The owned E2E lifecycle recreates realm state before evaluating an import. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Harness owns a Compose project and uses `down --remove-orphans --volumes`; live import behavior was not exercised. |
| 9 | Credential-bearing browser artifacts are never retained; diagnostics are redacted allowlisted text only. | ✓ VERIFIED | Attachment modes are off and the artifact-policy self-test passed. |
| 10 | FakeIdP remains first/independent and Keycloak remains optional behind enabled trust. | ✓ VERIFIED | Route-affordance and FakeIdP regression tests passed; UI checks an enabled stable connection before rendering the optional link. |
| 11 | The durable LoginReceipt uses exact truthful wording without a cookie/authorization claim. | ✓ VERIFIED | Controller/template query durable `LoginReceipt` presence and render the locked receipt wording. |
| 12 | Touched UI preserves native semantic links, accessible names, visible focus behavior, and intended presentation. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source and controller tests prove native links/names and conditional content; focus/visual behavior needs a browser. |
| 13 | A failed Keycloak destination cannot leave a false-success UI claim. | ⚠️ insufficient_spec | Backstop truth; no failed-login browser evidence exists. |
| 14 | Narrow trace cards/table keep all evidence operable. | ⚠️ insufficient_spec | Backstop truth; no narrow-viewport evidence exists. |
| 15 | Long trace values remain accessible without hiding security evidence. | ⚠️ insufficient_spec | Backstop truth; no long-value visual evidence exists. |
| 16 | Only runtime-configured host-admin credentials establish the fixed demo scope; missing configuration denies access. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Valid, absent-header, and invalid-credential routes are tested; absent/incomplete runtime configuration is not. |

**Score:** 7/16 truths verified (5 present, behavior-unverified; 3 insufficient-spec backstops).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.proxy.yml` | Proxy-only Keycloak/provisioner graph | ✓ VERIFIED | Static contract passed; dual networks, xforwarded identity, and no Keycloak host port. |
| `docker/keycloak/realm-demo-app.json` | Public Keycloak/SP SAML contract | ✓ VERIFIED | Public URL fields derive from `RELYRA_HOST`; RSA-SHA256 and KeyInfo suppression are configured. |
| `keycloak_provisioner.ex` | Canonical descriptor to audited trust orchestration | ✗ BLOCKER | One parse/candidate and audited metadata/certificate seams exist, but the durable identity mapping bypasses audit co-commit. |
| `keycloak_provisioner_test.exs` | Provision/idempotency/rotation/failure coverage | ⚠️ PARTIAL | Substantive and passing, but omits mapping-audit and post-mapping enable-failure rollback coverage. |
| `demo_admin_auth.ex` and router | Runtime-only host-admin boundary | ✓ VERIFIED / ⚠️ behavior unverified | All mutation routes are in the Basic-auth pipeline; missing-config path lacks a regression test. |
| `keycloak.spec.ts` | Public ACS/receipt/trace proof | ⚠️ NOT EXERCISED | Correctly enumerated but requires a live owned stack. |
| `playwright.keycloak-proxy.config.mjs` | Attachment-free credential-bearing browser config | ✓ VERIFIED | List reporter; trace, video, and screenshot are off. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Proxy Compose | Realm import | `RELYRA_HOST` / `KC_HOSTNAME` | ✓ WIRED | Static default and override render checks pass. |
| Provisioner | Parser → `MetadataApply` / certificate inventory | one canonical candidate | ✓ WIRED | One `Parser.parse`, `Map.from_struct(candidate)`, MetadataApply, then certificate activation/retirement are present. |
| Provisioner | Host identity mapping / audit ledger | identity creation before enable | ✗ NOT WIRED / BLOCKER | Mapping goes directly to `Repo.insert/1`; no `AuditWriter` call or transaction joins it to audit/enablement. |
| Admin router | Controller / LiveAdmin mount | `:demo_admin` pipeline | ✓ WIRED | Both `/login/admin` and the whole `relyra_admin_routes` mount pass through Basic auth. |
| Harness | Playwright temporary output / diagnostics | mktemp, trap cleanup, validation | ✓ WIRED | Policy self-test passes; output is removed before validated diagnostics are promoted. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Provisioner | canonical candidate/fingerprints | fetched Keycloak descriptor | Yes | ✓ FLOWING |
| Optional login UI | `keycloak_connection_id` | persisted enabled `Connection` lookup | Yes | ✓ FLOWING |
| Workspace receipt | `has_login_receipt?` | latest persisted `LoginReceipt` query | Yes | ✓ FLOWING |
| Identity mapping | `SAMLIdentity` row | seeded Sarah user plus public issuer | Yes, but unaudited | ✗ BLOCKER |
| Browser trace | correlation-scoped trace DOM | live admin page | Live stack not run | ⚠️ NOT EXERCISED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Compose/realm host contract | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | Default and override assertions passed | ✓ PASS |
| Credential/artifact policy | `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | Passed | ✓ PASS |
| Provisioner/admin/FakeIdP regressions | `cd demo/ledger_loop && mix test ... --warnings-as-errors` | 17 tests, 0 failures | ✓ PASS |
| Browser proof availability | `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` | One selected Keycloak test | ? ENUMERATED |
| Formatting | `mix format --check-formatted` | Passed | ✓ PASS |
| Full Keycloak lifecycle | Not run | Would start Docker services and submit test credentials | ? SKIP |

`mix ci.security` is not green: its isolated suites completed before the command exited 1 on the pre-existing `mint 1.8.0` / `req 0.5.18` dependency advisories recorded in `STATE.md`.

### Probe Execution

Step 7c: SKIPPED — Phase 70 declares no `scripts/*/tests/probe-*.sh` probe. The E2E harness was checked in its static/policy modes; that does not substitute for the live credential-bearing lifecycle.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| KC-01 | 70-01 through 70-08 | Optional proxy-hosted Keycloak with correct hostname/forwarded headers, public realm URLs, and full verified SAML round trip. | ✗ BLOCKED | Proxy/realm/static proof, focused regression, and authenticated-admin wiring exist; the unaudited mapping mutation violates the project audit co-commit invariant. The live browser round trip is also not newly exercised. |

Every Plan 70-01 through 70-08 declares `KC-01`; `REQUIREMENTS.md` maps it exclusively to Phase 70. No orphaned Phase 70 requirements exist.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `keycloak_provisioner.ex` | 50-51, 230-247 | Bare durable mapping insert before enablement, outside audit transaction | 🛑 BLOCKER | Violates AGENTS.md invariant 5 and can retain a latent authorization mapping after enablement failure. |
| `route_affordance_controller_test.exs` | 8-27 | Setup always supplies valid runtime admin credentials | ⚠️ WARNING | Missing-config deny-by-default behavior has no executable regression. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase 70 implementation files. No Phase 70 implementation change touches `lib/relyra/**`, `mix.exs`, or `mix.lock`.

### Prohibitions

| Must not | Status | Evidence |
| --- | --- | --- |
| Make Keycloak default or make FakeIdP depend on it | ✓ VERIFIED | FakeIdP remains unconditional; Keycloak requires the enabled stable connection. |
| Leave partially provisioned/stale trust login-capable | ✓ VERIFIED | Focused failure and rotation regressions pass. |
| Retain credentials, assertions, descriptor XML, PEM, or DB credentials in diagnostics | ✓ VERIFIED | Attachment policy and offline redaction self-test pass. |
| Commit a default host-admin secret or expose public admin scope | ✓ VERIFIED | Runtime-only credentials plus router pipeline replace the former public shortcut; route tests cover absent header/invalid/valid credentials. |
| Write mapping/trust state without audit co-commit | ✗ FAILED / BLOCKER | `ensure_sarah_identity/1` is a direct unaudited `Repo.insert/1`. |

### Gaps Summary

The former public `/login/admin` privilege escalation is closed: the full LiveAdmin mount is behind `DemoAdminAuth`, and focused denial/authorized tests pass. The phase still cannot pass. The Keycloak provisioner creates a durable issuer/subject mapping outside an audit co-commit and before a separately committed enable operation. This directly violates the project’s non-negotiable audit invariant, so `KC-01` remains blocked. Phase 71 (launcher) and Phase 72 (documentation) do not cover provisioning/audit behavior; this is not deferred work.

_Verified: 2026-08-26T19:47:32Z_
_Verifier: the agent (gsd-verifier)_
