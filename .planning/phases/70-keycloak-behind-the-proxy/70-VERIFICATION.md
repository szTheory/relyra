---
phase: 70-keycloak-behind-the-proxy
verified: 2026-08-26T18:58:17Z
status: gaps_found
score: 8/15 must-haves verified
behavior_unverified: 4
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/11
  gaps_closed:
    - "The provisioner now parses the descriptor once and passes the canonical candidate to MetadataApply.apply_revision/4."
    - "Credential-bearing Keycloak Playwright runs now disable trace, video, and screenshots; only validated redacted text diagnostics can be retained."
  gaps_remaining: []
  regressions:
    - "CR-01: unauthenticated GET /login/admin establishes an admin scope that can mutate SAML trust."
gaps:
  - truth: "No unauthenticated public endpoint grants the administrative scope used for Relyra trust-management mutations."
    status: failed
    reason: "GET /login/admin has no authentication or authorization guard but writes the exact session values AdminScope accepts as an administrator. The mounted LiveAdmin routes expose connection, metadata, certificate, and mapping mutations under that scope."
    artifacts:
      - path: "demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex"
        issue: "admin_login/2 unconditionally writes demo_admin session keys."
      - path: "demo/ledger_loop/lib/ledger_loop_web/router.ex"
        issue: "Public router mounts /login/admin and the mutation-capable /relyra/admin scope."
      - path: "demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex"
        issue: "Any non-empty admin_actor session value resolves to an authenticated administrative scope."
    missing:
      - "Remove the public shortcut or require real host-admin authentication and authorization before setting the admin scope; do not use it in the Keycloak browser proof."
behavior_unverified_items:
  - truth: "Keycloak is reachable in a browser at http://keycloak.relyra.localhost and its effective realm issuer equals that public host."
    test: "Run the owned Keycloak proxy lifecycle and visit the public Keycloak origin through Traefik."
    expected: "The public endpoint serves the demo realm at keycloak.relyra.localhost; its issuer is http://keycloak.relyra.localhost/realms/demo-app and no direct host-port bypass is reachable."
    why_human: "Compose rendering and static harness checks prove intent but this verification did not start Docker services."
  - truth: "A browser Keycloak login returns a signed assertion to the scoped ACS, verifies it, and establishes the LedgerLoop receipt/session boundary."
    test: "From /login/test, use the optional Keycloak link and authenticate Sarah on a freshly provisioned owned stack."
    expected: "The scoped ACS POST returns 302 to the workspace, the exact receipt text is visible, and the successful correlation has Validate response, Verify signature, and Replay check marked ok."
    why_human: "The one Playwright test was enumerated but not executed against a live credential-bearing Keycloak stack."
  - truth: "Each owned E2E lifecycle destroys and recreates Keycloak realm state before assessing an import."
    test: "Run the lifecycle twice after changing an allowed realm URL fixture."
    expected: "Only harness-owned volumes are removed and the second run evaluates the current rendered realm contract rather than a stale imported realm."
    why_human: "The scoped down --volumes path is present, but Keycloak import behavior is runtime-only."
  - truth: "Touched UI preserves usable visible focus behavior and Canonical Lock Set presentation."
    test: "Use keyboard navigation on /login/test and inspect the receipt and optional-login link in a browser."
    expected: "The native links have visible focus and the receipt/link remain legible and truthful."
    why_human: "Template/controller tests prove names and conditions, not rendered focus or visual presentation."
---

# Phase 70: Keycloak Behind the Proxy Verification Report

**Phase Goal:** The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Verified:** 2026-08-26T18:58:17Z
**Status:** gaps_found
**Re-verification:** Yes — after closure of the previous one-parse and diagnostics gaps

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Keycloak is browser-reachable with public forwarded-host identity. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `KC_HOSTNAME=http://keycloak.${RELYRA_HOST}` and `KC_PROXY_HEADERS=xforwarded` render correctly; no live stack was started. |
| 2 | Realm client URLs/ACS/redirects use `relyra.localhost`; `keycloak:8080` is transport-only. | ✓ VERIFIED | Rendered Compose plus `KEYCLOAK_PROXY_STATIC_ONLY=1` passed for default and overridden hosts; realm client fields use `RELYRA_HOST` and Traefik alone targets 8080. |
| 3 | A real browser Keycloak login reaches scoped ACS, cryptographically verifies, and establishes the receipt boundary. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `keycloak.spec.ts` checks public origin, POST `/saml/<stable-id>/acs`, 302, exact receipt, and the three canonical trace steps, but was only enumerated. |
| 4 | Descriptor trust is parsed once into a canonical candidate and persisted through audited seams, with enable last. | ✓ VERIFIED | `KeycloakProvisioner` parses once at lines 69-77 and passes `Map.from_struct(candidate)` to `MetadataApply.apply_revision/4` at 149-166; focused test passed all 18 tests and asserts one parse on provision and unchanged retry. |
| 5 | Signing-key rotation has no stale enabled trust or duplicate churn. | ✓ VERIFIED | Focused rotation test proves unavailable state after disable, replacement active trust, stale removal, and unchanged retry counts. |
| 6 | Fetch/parse/apply/activation/identity failures leave Keycloak unavailable and create no receipt. | ✓ VERIFIED | Five injected failure cases pass; `fail_closed/2` disables the connection and each case asserts no receipt. |
| 7 | Only Sarah's exact public-realm identity is provisioned. | ✓ VERIFIED | Initial provisioning test asserts one `sarah@northstar.example.com` identity with the exact public issuer. |
| 8 | The owned E2E lifecycle recreates realm state before it evaluates an import. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The harness uses a reserved project name and `down --remove-orphans --volumes` before startup and on cleanup; import effect was not run. |
| 9 | Credential-bearing browser artifacts are never retained; diagnostics are redacted allowlisted text only. | ✓ VERIFIED | Playwright sets trace/screenshot/video to `off`; artifact-policy self-test passed and harness stages, validates, and promotes only three redacted `.log` files. |
| 10 | FakeIdP remains first/independent and Keycloak remains optional behind enabled trust. | ✓ VERIFIED | Focused route-affordance test passed: FakeIdP is unconditional and Keycloak is absent unless the stable connection is enabled. |
| 11 | The durable LoginReceipt uses exact truthful wording without a cookie/authorization claim. | ✓ VERIFIED | Focused page-controller test passed; persisted receipt query controls the exact sentence. |
| 12 | Touched UI preserves native semantic links, accessible names, visible focus behavior, and the intended visual presentation. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source and focused tests prove native links/names and conditional content; focus and visual behavior require a browser. |
| 13 | A failed Keycloak login cannot leave a false-success UI claim. | ⚠️ insufficient_spec | Plan 70-07 marks this `verification: backstop`; no explicit failed-login browser test exists. |
| 14 | Narrow viewport trace cards/table keep all evidence operable. | ⚠️ insufficient_spec | Backstop truth with no held-out narrow-viewport browser evidence. |
| 15 | Long trace values remain accessible without hiding security evidence. | ⚠️ insufficient_spec | Backstop truth with no held-out long-value visual evidence. |

**Score:** 8/15 truths verified (4 present, behavior-unverified; 3 insufficient-spec backstops)

### Security Gate: CR-01

**✗ FAILED / BLOCKER.** `GET /login/admin` is public in `router.ex`. Its handler writes `admin_actor`, `admin_actor_label`, and `admin_organization_id` with no identity check. `LedgerLoop.Relyra.AdminScope` accepts any non-empty `admin_actor`; the resulting `/relyra/admin` scope can save/enable/disable connections and manage metadata, certificates, and mappings. The Keycloak spec uses this route at lines 38-40 to read the trace.

This violates the project’s strict trust-boundary posture and makes the phase’s authenticated-looking browser proof unsafe. It is not deferred: Phase 71 explicitly excludes router changes and Phase 72 is documentation-only.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.proxy.yml` | Proxy-only Keycloak/provisioner graph | ✓ VERIFIED | Dual-network Keycloak, default-only provisioner, no Keycloak host port, `xforwarded`, and private 8080 backend rendered successfully. |
| `docker/keycloak/realm-demo-app.json` | Public Keycloak/SP SAML contract | ✓ VERIFIED | All client/browser fields derive from `RELYRA_HOST`; RSA-SHA256 and KeyInfo suppression are present. |
| `keycloak_provisioner.ex` | Canonical descriptor → audited trust orchestration | ✓ VERIFIED | Substantive one-parse candidate flow, audited MetadataApply and certificate reconciliation, fail-closed behavior. |
| `keycloak_provisioner_test.exs` | Provision/idempotency/rotation/failure coverage | ✓ VERIFIED | 18 focused tests passed. |
| `keycloak.spec.ts` | Public ACS/receipt/trace proof | ⚠️ NOT EXERCISED | Substantive and correctly wired, but requires live Docker/Keycloak. |
| `playwright.keycloak-proxy.config.mjs` | Attachment-free credential-bearing browser config | ✓ VERIFIED | Host mapping plus all trace/video/screenshot capture disabled. |
| `scripts/test_keycloak_proxy_e2e.sh` | Owned lifecycle and fail-closed diagnostics | ✓ VERIFIED | Syntax, static topology and offline artifact-policy checks passed. |
| Route/admin scope | Authenticated trace access | ✗ BLOCKER | Public admin shortcut grants mutation-capable scope without authentication. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Proxy Compose | Realm import | `RELYRA_HOST` and `KC_HOSTNAME` | ✓ WIRED | Static default/override render contract passed. |
| Provisioner | `MetadataApply` / audited transaction | canonical candidate | ✓ WIRED | Candidate is the same preflight object persisted through `apply_revision/4`; no `Import.import_xml/3` remains. |
| Provisioner | Certificate inventory | activate then retire stale | ✓ WIRED | Code and rotation test confirm the sequence. |
| Browser spec | Optional login / scoped ACS / trace | semantic link and stable ID | ✓ WIRED WITH BLOCKER | Proper proof wiring exists, but accesses trace via the unsafe public `/login/admin` route. |
| Harness | Playwright temp directory / diagnostics | `mktemp`, trap cleanup, validation | ✓ WIRED | Per-run output is removed before text-only diagnostics are captured. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Provisioner | canonical candidate/fingerprints | fetched Keycloak descriptor | Yes | ✓ FLOWING |
| Optional login UI | `keycloak_connection_id` | persisted enabled `Connection` lookup | Yes | ✓ FLOWING |
| Workspace receipt | `has_login_receipt?` | persisted `LoginReceipt` query | Yes | ✓ FLOWING |
| Browser trace | correlation-scoped trace DOM | live admin page | Requires live stack; unsafe admin shortcut | ⚠️ NOT EXERCISED / BLOCKED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Compose/realm host contract | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | Default and override assertions passed | ✓ PASS |
| Credential/artifact policy | `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | Passed | ✓ PASS |
| Browser proof availability | `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` | One selected Keycloak test | ? ENUMERATED |
| Provisioning/UI focused regression | `cd demo/ledger_loop && mix test ... --warnings-as-errors` | 18 tests, 0 failures | ✓ PASS |
| Full Keycloak lifecycle | Not run | Would start services and submit test credentials | ? SKIP |

### Probe Execution

Step 7c: SKIPPED — Phase 70 declares no `scripts/*/tests/probe-*.sh` probe. The owned E2E harness was independently syntax/static/policy checked; its live credential-bearing lifecycle was not substituted by SUMMARY claims.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| KC-01 | 70-01 through 70-07 | Optional proxy-hosted Keycloak with correct hostname/forwarded headers, public realm URLs, and a full verified SAML round trip. | ✗ BLOCKED | Core config/provisioning/diagnostics are implemented and focused checks pass, but the browser proof grants unauthenticated mutation-capable admin access and live journey remains unexercised. |

No Phase-70 requirement is orphaned: every Plan 70-01 through 70-07 declares `KC-01`, and `REQUIREMENTS.md` maps `KC-01` exclusively to Phase 70.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `route_affordance_controller.ex` | 23-28 | Public route writes trusted admin session fields | 🛑 BLOCKER | Any caller receives a mutation-capable admin scope. |
| `router.ex` | 53, 59-62 | Public admin-login shortcut adjacent to mounted LiveAdmin routes | 🛑 BLOCKER | Exposes trust-management UI without authentication. |
| `admin_scope.ex` | 8-20 | Non-empty session value is sufficient for admin authentication | 🛑 BLOCKER | Turns the public session write into privilege escalation. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase 70 implementation files. The prior one-parse and retained-Playwright-artifact blockers are closed in current code. No Phase 70 implementation change touches `lib/relyra/**`, `mix.exs`, or `mix.lock`.

### Prohibitions

| Must not | Status | Evidence |
| --- | --- | --- |
| Make Keycloak default or make FakeIdP depend on it | ✓ VERIFIED | FakeIdP remains unconditional; Keycloak requires enabled stable trust. |
| Leave partially provisioned/stale trust login-capable | ✓ VERIFIED | Focused failure and rotation tests pass. |
| Retain credentials, assertions, descriptor XML, PEM, or DB credentials in diagnostics | ✓ VERIFIED | Attachments disabled; policy test passes; only validated/redacted logs may promote. |
| Misdescribe LoginReceipt as a cookie/authorization proof | ✓ VERIFIED | Exact receipt text is durable-data-backed and avoids that claim. |
| Treat redirect/shape/color as crypto/replay/mapping/receipt proof | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Correct assertions are present but no live browser run occurred. |
| Leave a false-success UI after failed optional login | ⚠️ insufficient_spec | Tagged backstop lacks explicit evidence. |

### Human Verification Follow-up

These items remain queued after CR-01 is fixed; they do not lessen the blocker. Run the owned stack to prove public ingress, fresh import, signed ACS, receipt, and trace. Then exercise failed-login and narrow/long-value layouts to close the three explicitly tagged backstop truths.

### Gaps Summary

The previous two Phase 70 blockers are genuinely closed: current code uses one canonical descriptor candidate and leaves no browser artifacts to redact. However, CR-01 is a separate **BLOCKER**. The route used by the Keycloak proof upgrades any caller into the exact admin scope that can mutate cryptographic trust. This contradicts the project’s strict trust boundary, so the phase goal cannot be accepted and `KC-01` remains blocked.

_Verified: 2026-08-26T18:58:17Z_
_Verifier: the agent (gsd-verifier)_
