---
phase: 70-keycloak-behind-the-proxy
verified: 2026-08-26T17:23:47Z
status: gaps_found
score: 6/11 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "The optional one-shot provisioner imports descriptor-derived trust through the audited seams without violating the one-parse XML invariant."
    status: failed
    reason: "The fetched descriptor is parsed in KeycloakProvisioner.descriptor_facts/2 and the identical bytes are then given to Import.import_xml/3, which parses them again before persistence. This violates the project's non-negotiable one-parse/no-parser-differential invariant on the trust-install path."
    artifacts:
      - path: "demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex"
        issue: "Parser.parse/1 at line 68 precedes Import.import_xml/3 at line 144."
      - path: "lib/relyra/metadata/import.ex"
        issue: "Import.import_xml/3 calls Parser.parse/2 at line 17."
    missing:
      - "Use one parsed/canonical metadata candidate for both preflight issuer/fingerprint checks and audited persistence; do not independently parse the same descriptor bytes."
  - truth: "Failed E2E evidence is actionable and redacted; no test credential or raw SAML assertion is retained in diagnostics."
    status: failed
    reason: "The harness puts Playwright failure artifacts under its retained diagnostic directory, while the config retains trace ZIPs and videos on failure. This login fills the password field and receives a POST SAMLResponse, and the shell-only redact_diagnostics function never sanitizes those browser artifacts."
    artifacts:
      - path: "playwright.keycloak-proxy.config.mjs"
        issue: "trace: retain-on-failure and video: retain-on-failure preserve credential-bearing browser evidence."
      - path: "scripts/test_keycloak_proxy_e2e.sh"
        issue: "Lines 247-251 direct Playwright output to ARTIFACT_DIR/playwright; capture_diagnostics only redacts text logs."
    missing:
      - "Disable retained Playwright trace/video (and any sensitive screenshot retention) for this flow, or prove a reliable sanitizer removes request bodies, form data, snapshots, and SAMLResponse before retention."
behavior_unverified_items:
  - truth: "Keycloak is reachable in a browser at http://keycloak.relyra.localhost and its effective realm issuer equals that public host."
    test: "Run the owned proxy lifecycle and visit the public Keycloak origin through Traefik."
    expected: "The public endpoint responds with the realm issuer http://keycloak.relyra.localhost/realms/demo-app and has no direct host-port bypass."
    why_human: "Static Compose rendering proves the intended configuration, but this verification did not start Docker services or execute the credential-bearing browser flow."
  - truth: "A real browser Keycloak login returns a signed assertion to the scoped ACS and establishes the LedgerLoop receipt/session boundary."
    test: "From /login/test, use the optional Keycloak link, authenticate Sarah, then inspect the scoped ACS response, workspace receipt, and trace route."
    expected: "The ACS POST redirects to the workspace; the receipt text is visible; one successful correlation has exactly Validate response, Verify signature, and Replay check marked ok."
    why_human: "The code and a listed Playwright spec are wired, but the runnable assertion requires starting the proxy/Keycloak stack and submits a credential-bearing real assertion."
  - truth: "Each E2E run destroys/recreates its Keycloak realm state before evaluating changed realm imports."
    test: "Run the owned lifecycle twice after changing an allowed realm URL fixture and inspect the resulting realm import."
    expected: "Only the harness-owned volumes are removed and the changed public realm contract, rather than a stale imported realm, is evaluated."
    why_human: "The script contains the scoped down --volumes path, but lifecycle cleanup and Keycloak import behavior are runtime effects not exercised here."
---

# Phase 70: Keycloak Behind the Proxy Verification Report

**Phase Goal:** The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Verified:** 2026-08-26T17:23:47Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Keycloak is browser-reachable at the public hostname with the correct forwarded-host identity. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `docker-compose.proxy.yml` supplies `KC_HOSTNAME=http://keycloak.${RELYRA_HOST}` and `KC_PROXY_HEADERS=xforwarded`; the static dual-render check passed. No live browser/server run was performed. |
| 2 | Realm client URLs, ACS, and redirects use `relyra.localhost`; internal `keycloak:8080` remains transport-only. | ✓ VERIFIED | `realm-demo-app.json` derives all client URLs from `RELYRA_HOST`; `scripts/test_keycloak_proxy_e2e.sh` static check passed for default and override renders and rejects stale direct/internal public URLs. The split-horizon contract is documented in the phase context/research. |
| 3 | A browser Keycloak login returns a signed assertion to scoped ACS, verifies it, and establishes the host-owned receipt/session boundary. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `keycloak.spec.ts` checks optional link → public origin → scoped POST → 302 → exact receipt; it asserts exactly validation/signature/replay on the successful trace correlation. It was enumerated but not executed against a started stack. |
| 4 | The optional provisioner installs descriptor-derived trust through audited seams and enables last without violating security invariants. | ✗ FAILED | The code invokes `Parser.parse/1` at provisioner line 68, then gives the same bytes to `Import.import_xml/3`, which parses again. This contradicts the project's binding one-parse invariant. |
| 5 | Generated signing-key rotation reconciles trust without stale active trust or duplicate mutations. | ✓ VERIFIED | Focused rotation test (`keycloak_provisioner_test.exs:66`) passed: 1 test, 0 failures; code disables before mutation, activates replacement, then retires stale active signing certificates. |
| 6 | Fetch/parse/apply/activation/identity failures leave the Keycloak connection unavailable and produce no receipt. | ✓ VERIFIED | Focused injected-failure test path (`keycloak_provisioner_test.exs:65`) passed: 5 tests, 0 failures; `fail_closed/2` disables the connection on error. |
| 7 | Only Sarah's exact public-realm issuer identity is provisioned for the real-IdP proof. | ✓ VERIFIED | Focused initial provisioner test (`keycloak_provisioner_test.exs:19`) passed; it asserts Sarah's exact issuer/subject, active signing certificate, and audited connection/metadata/certificate events. |
| 8 | Every owned E2E lifecycle recreates realm state before it assesses imports. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The harness calls its reserved Compose project `down --remove-orphans --volumes` before startup, but the runtime Keycloak import effect was not executed here. |
| 9 | Failure diagnostics retain no credentials, raw assertion, descriptor XML, PEM, or database credentials. | ✗ FAILED | Text logs pass the self-test, but retained Playwright trace/video artifacts can contain Sarah's password and the POST `SAMLResponse`; no artifact sanitization exists. |
| 10 | FakeIdP remains always available and the optional Keycloak affordance appears only for the stable enabled connection. | ✓ VERIFIED | `route_affordance_controller_test.exs:32` passed; the controller looks up the stable Keycloak connection and the template conditionally renders its native link. |
| 11 | The workspace shows the exact durable LoginReceipt wording, without claiming a conventional browser cookie/session. | ✓ VERIFIED | `page_controller_test.exs:50` passed; the page renders the exact receipt text only when a `LoginReceipt` exists. |

**Score:** 6/11 truths verified (3 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.proxy.yml` | Proxy-only Keycloak/provisioner graph | ✓ VERIFIED | Dual-network Keycloak, default-only provisioner, public hostname and private 8080 Traefik route are present; static rendered-config check passed. |
| `docker/keycloak/realm-demo-app.json` | Public realm/SP SAML contract | ✓ VERIFIED | Single `RELYRA_HOST` source configures entity ID, root/base/admin URLs, ACS, redirects, web origin, RSA-SHA256, and KeyInfo suppression. |
| `demo/.../keycloak_provisioner.ex` | Descriptor-to-audited-trust orchestration | ✗ FAILED | Substantive and wired, but unsafe: it parses descriptor bytes twice on the actual trust path. |
| `demo/.../keycloak_provisioner_test.exs` | Idempotency, rotation, and fail-closed coverage | ✓ VERIFIED | Initial provision and rotation/failure focused checks passed. |
| `demo/.../keycloak.spec.ts` | Public ACS/receipt/correlation trace proof | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Substantive, scoped to the optional link and canonical three-step D-19 contract; requires a live stack. |
| `playwright.keycloak-proxy.config.mjs` | Host resolver and safe browser artifacts | ✗ FAILED | Correct host mappings and one worker, but raw failure traces/videos are retained. |
| `scripts/test_keycloak_proxy_e2e.sh` | Owned lifecycle and redacted diagnostics | ✗ FAILED | Static contracts and text redaction work, but it retains unsafe browser artifacts under `ARTIFACT_DIR`. |
| UI controllers/templates | Optional affordance and durable receipt | ✓ VERIFIED | Tested enabled-state gate and exact receipt rendering; no cookie/authorization claim found. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Proxy Compose | Realm import | `RELYRA_HOST`, `KC_HOSTNAME`, static config checks | ✓ WIRED | Manual inspection and static check confirm one host input ties the public contract together. |
| Provisioner | `Relyra.Metadata.Import` | `Import.import_xml/3` with Repo/audit context | ⚠️ WIRED WITH BLOCKER | Call and audit context exist, but it follows a separate `Parser.parse/1` of identical bytes. |
| Provisioner | Certificate inventory | activate replacement before retire stale trust | ✓ WIRED | `activate_signing_certificate` then `retire_signing_certificate`; focused rotation test passed. |
| Browser spec | Optional UI / stable trace route | semantic link, scoped ACS, trace correlation | ✓ WIRED | The exact accessible link, stable ID, and three canonical verifier steps are used. |
| Harness | Compose/realm/FakeIdP gates | config assertions and focused lane commands | ✓ WIRED | Static checks passed; live lifecycle remains unexecuted. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Keycloak provisioner | Descriptor facts/fingerprints | `Req.get` from container DNS descriptor | Yes, but parsed twice | ✗ UNSAFE FLOW |
| Optional-login UI | `keycloak_connection_id` | `Repo.get_by(Connection, connection_id:)` | Enabled connection controls render | ✓ FLOWING |
| Workspace receipt | `has_login_receipt?` | Latest `LoginReceipt` query | Durable persisted receipt controls render | ✓ FLOWING |
| Browser trace | Successful trace-row DOM | Live Admin route after real login | Requires live browser stack | ⚠️ NOT EXERCISED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Static proxy/realm contract | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | Default + override render assertions passed | ✓ PASS |
| Text diagnostic redaction | `KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | Self-test passed | ✓ PASS (insufficient for binary Playwright artifacts) |
| Provision rotation | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs:66 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Provision injected failures | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs:65 --warnings-as-errors` | 5 tests, 0 failures | ✓ PASS |
| Initial audited provisioning/idempotency | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs:19 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Optional link gate | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/route_affordance_controller_test.exs:32 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Durable receipt wording | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs:50 --warnings-as-errors` | 1 test, 0 failures | ✓ PASS |
| Browser proof availability | `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` | 1 selected Keycloak test | ? ENUMERATED; live run skipped |

### Probe Execution

Step 7c: SKIPPED — no `scripts/*/tests/probe-*.sh` files or phase-declared probe paths exist. The E2E harness was checked through its static and diagnostic modes above; its credential-bearing live lifecycle was not substituted for a probe result.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| KC-01 | 70-01 through 70-05 | Optional proxy-hosted Keycloak with correct hostname/forwarded headers and a full verified SAML round trip. | ✗ BLOCKED | All five plans declare KC-01. Static topology/realm/UI/provisioning portions are present, but the trust path violates the one-parse invariant and failure artifacts can expose credentials/assertions; live E2E behavior was not independently exercised. |

No phase-70 requirement is orphaned: every plan declares `KC-01`, and `REQUIREMENTS.md` maps `KC-01` to Phase 70.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` | 68, 144 | Same descriptor bytes parsed by `Parser.parse/1` then parsed again inside `Import.import_xml/3` | 🛑 BLOCKER | Violates the project’s one-parse security invariant at descriptor-to-trust installation. |
| `playwright.keycloak-proxy.config.mjs` | 18-20 | `retain-on-failure` trace/video for credential-bearing flow | 🛑 BLOCKER | Retained ZIP/video can expose Keycloak password and raw SAMLResponse. |
| `scripts/test_keycloak_proxy_e2e.sh` | 247-251 | Browser artifacts stored under diagnostics; no binary-artifact sanitizer | 🛑 BLOCKER | Shell redaction cannot sanitize retained Playwright data. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the phase-owned implementation files. No Phase 70 change touched `lib/relyra/**`, `mix.exs`, or `mix.lock`.

### Prohibitions

| Must not | Status | Evidence |
| --- | --- | --- |
| Make Keycloak the default lane or make FakeIdP depend on it | ✓ VERIFIED | FakeIdP link is unconditional; Keycloak link requires enabled stable connection; focused UI test passed. |
| Leave partially provisioned/stale trust available after failure | ✓ VERIFIED | Focused injected-failure/rotation tests passed, showing disabled/unavailable state until replacement trust is active. |
| Retain credentials, raw SAML assertions, descriptor XML, PEM, or DB credentials in diagnostics | ✗ FAILED | Playwright trace/video retention defeats the text-log redaction path. |
| Describe LoginReceipt as a cookie session or use generic/color-only proof | ✓ VERIFIED | Exact durable-receipt text is data-backed and makes no cookie/authorization claim. |
| Treat redirect/shape/color as proof instead of validation, signature, replay, mapping, receipt | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The code asserts the corrected three-step D-19 contract and separate receipt/workspace evidence, but the live assertion was not run here. |

### Gaps Summary

Phase 70 is blocked by two security defects, not by missing files or a stale summary. The descriptor-to-trust route violates Relyra’s non-negotiable single-parse invariant, so preflight facts and persisted trust do not come from one canonical parsed candidate. Separately, failed browser runs preserve sensitive raw evidence despite text diagnostics being redacted.

The D-19 correction in commit `cfe2a31` is correctly reflected in the browser spec and harness: the successful Login Trace has only `response.validate`, `signature.verify`, and `replay.check`; workspace return and `LoginReceipt` are separate mapping/session evidence. That contract is present, but its live execution remains a human/runtime check after the blockers are fixed.

---

_Verified: 2026-08-26T17:23:47Z_
_Verifier: the agent (gsd-verifier)_
