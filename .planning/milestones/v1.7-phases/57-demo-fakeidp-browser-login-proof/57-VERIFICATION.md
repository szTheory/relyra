---
phase: 57-demo-fakeidp-browser-login-proof
verified: 2026-06-13T00:00:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
mode: mvp
---

# Phase 57: Demo FakeIdP Browser-Login Proof Verification Report

**Phase Goal (MVP User Story):** As a LedgerLoop demo evaluator, I want to click the Log in with SSO button and complete a real browser round-trip through a built-in fake IdP, so that I see Relyra cryptographically verify a signed SAML assertion end-to-end and surface a typed rejection on the tampered variant without configuring an external IdP.

**Verified:** 2026-06-13
**Status:** passed
**Re-verification:** No — initial verification

## MVP Mode — User Flow Coverage

The success condition is the `so that` clause: the evaluator sees Relyra cryptographically verify a signed assertion end-to-end, and sees a typed rejection on the tampered variant — all without an external IdP. Per 57-VALIDATION.md this is an explicit zero-human-UAT, in-process proof; the `fake_idp_flow_test.exs` round-trip IS the verification surface.

| Step | Expected | Evidence in codebase | Status |
|------|----------|----------------------|--------|
| Evaluator clicks "Log in with SSO" | Affordance enters SP-initiated `/saml/<…J0>/login` (mints AuthnRequest + intent) | `route_affordance_html/login.html.heex:12` href=`/saml/#{@conn_id}/login`; `route_affordance_controller_test.exs:9` asserts it (green) | ✓ VERIFIED |
| Browser bounces to built-in fake IdP | 302 → `/fake_idp/login?SAMLRequest=…&RelayState=…`; harness page labelled "Local Test Support / FakeIdP" | `idp_sso_url` = `http://localhost:4000/fake_idp/login` (fixtures.ex:61); `login.html.heex:3-4` banner + "local testing harness"; flow test asserts 302 + query params | ✓ VERIFIED |
| InResponseTo correlation | FakeIdP inflates the AuthnRequest, echoes its ID as InResponseTo | `fake_idp_controller.ex:114-132` `:zlib.inflateInit(-15)` + ID regex; flow test asserts non-empty `in_response_to` hidden field | ✓ VERIFIED |
| Relyra verifies a real signed assertion end-to-end (success) | POST scoped `/saml/<…J0>/acs` → `do_verify/4` `{:ok}` → LoginReceipt → redirect "/" | `fake_idp_flow_test.exs:43-102` asserts 302 to "/" + `LoginReceipt` row inserted for sarah; signer_test.exs:44-53 proves `Signature.verify/4` `{:ok}` against demo cert | ✓ VERIFIED |
| Typed rejection on tampered variant | Tampered NameID → `:digest_mismatch` → no session (400), `domain: :login` error AuditEvent rendered in trace UI | `fake_idp_flow_test.exs:110-204` asserts 400, no receipt, AuditEvent `error_code=="digest_mismatch"`, ConnectionTraceLive renders rejection; signer_test.exs:83-92 proves `{:error, %Error{type: :digest_mismatch}}` | ✓ VERIFIED |
| No external IdP required | Signing is fully demo-local via committed keypair + relyra public C14N | `signer.ex` calls `PureBeam.canonicalize` + `C14N.serialize` + `Keypair.private_key`; no `Relyra.TestSupport` runtime ref; committed PEMs under `priv/fake_idp/` | ✓ VERIFIED |

The complete user flow is reachable and proven in-process. Both variants of the `so that` clause (acceptance + typed rejection) are observably true.

## Goal Achievement

### Observable Truths

| # | Truth (source plan) | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | Demo RSA-2048 keypair + self-signed cert committed under `priv/fake_idp/` (57-01) | ✓ VERIFIED | `idp_key.pem` ("RSA PRIVATE KEY"), `idp_cert.pem` ("BEGIN CERTIFICATE") both `git ls-files` tracked |
| 2 | Enabled …J0 fixture trusts the real demo cert, not MOCK_PEM_NOT_REAL (57-01) | ✓ VERIFIED | fixtures.ex:116 `pem: @demo_idp_cert_pem` = `Keypair.cert_pem()` (line 8); MOCK_PEM rows (130/144) are unrelated staged/next rows per plan |
| 3 | idp_sso_url points local; idp_entity_id stays in sync with saml_identities issuer (57-01) | ✓ VERIFIED | fixtures.ex:61 idp_sso_url=`…/fake_idp/login`; idp_entity_id (60) = saml_identities issuer (282,290) = `https://idp.northstar.example.com` |
| 4 | LoginTrace telemetry handler attached in Application (57-01) | ✓ VERIFIED | application.ex:31 `Relyra.Telemetry.Handlers.LoginTrace.attach(repo: LedgerLoop.Repo)` after Supervisor start |
| 5 | Signer output verifies `{:ok}` under strict `do_verify/4` against demo cert — real pass (57-02) | ✓ VERIFIED | signer_test.exs:44-53 `Signature.verify/4` → `{:ok, _}`; test green |
| 6 | Canonicalization is 100% relyra's engine — no hand-rolled C14N (57-02) | ✓ VERIFIED | signer.ex:176 `PureBeam.canonicalize`, :184 `C14N.serialize`; `grep defp? canonicaliz` → NONE |
| 7 | Tamper → `{:error, %Relyra.Error{type: :digest_mismatch}}` (57-02) | ✓ VERIFIED | signer_test.exs:83-92 asserts exact type; test green |
| 8 | No `Relyra.TestSupport` runtime ref in signer/keypair/controller (57-02/03) | ✓ VERIFIED | grep across fake_idp/* + controller → NONE (only descriptive moduledoc, no alias/call) |
| 9 | /fake_idp/{login,sso} routes wired under :browser; controller uses Signer + scoped ACS + InResponseTo (57-03) | ✓ VERIFIED | router.ex:40-41; controller uses `Signer.signed_response/tamper`, acs_url `/saml/<ulid>/acs` (72), inflate (114-132) |
| 10 | Success round-trip → LoginReceipt + redirect "/" (57-03) | ✓ VERIFIED | fake_idp_flow_test.exs:43-102 green (302→"/", receipt inserted) |
| 11 | Tampered → no session + domain: :login error AuditEvent rendered in trace UI (57-03) | ✓ VERIFIED | fake_idp_flow_test.exs:110-204 green (400, no receipt, digest_mismatch AuditEvent, ConnectionTraceLive render) |
| 12 | Affordance repointed to SP-initiated `/saml/<…J0>/login` (57-03) | ✓ VERIFIED | route_affordance_html/login.html.heex:12; controller test:9 green |
| 13 | Full demo suite green; zero relyra lib/ or mix.exs security-alias changes (57-03) | ✓ VERIFIED | `mix test` → 57 tests / 0 failures; `git diff e8893f6 HEAD -- lib/ mix.exs` empty |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/fake_idp/idp_key.pem` | RSA private key, committed | ✓ VERIFIED | tracked; "RSA PRIVATE KEY" header |
| `priv/fake_idp/idp_cert.pem` | self-signed cert | ✓ VERIFIED | tracked; "BEGIN CERTIFICATE" |
| `lib/ledger_loop/fake_idp/keypair.ex` | private_key/0 + cert_pem/0 | ✓ VERIFIED | 61 lines; persistent_term cache; no TestSupport |
| `lib/ledger_loop/demo/fixtures.ex` | real cert :pem + local sso_url | ✓ VERIFIED | @demo_idp_cert_pem sourced from Keypair.cert_pem() |
| `lib/ledger_loop/fake_idp/signer.ex` | signed_response/1 + tamper/1 via relyra C14N | ✓ VERIFIED | 230 lines; PureBeam.canonicalize + C14N.serialize |
| `lib/ledger_loop_web/controllers/fake_idp_controller.ex` | login/2 + sso/2 | ✓ VERIFIED | InResponseTo capture + Signer + scoped ACS |
| `lib/ledger_loop_web/router.ex` | GET login + POST sso in :browser | ✓ VERIFIED | router.ex:40-41 |
| `test/ledger_loop_web/fake_idp_flow_test.exs` | success + tampered + trace | ✓ VERIFIED | 224 lines; 2 tests green, non-hollow assertions |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| fixtures.ex | idp_cert.pem | :pem = cert PEM | ✓ WIRED | @demo_idp_cert_pem = Keypair.cert_pem() at compile time |
| application.ex | LoginTrace | attach(repo:) | ✓ WIRED | application.ex:31 |
| signer.ex | PureBeam.canonicalize | digest assertion | ✓ WIRED | signer.ex:176 |
| signer.ex | C14N.serialize | canonicalize SignedInfo | ✓ WIRED | signer.ex:184 |
| signer.ex | Keypair.private_key | sign SignedInfo | ✓ WIRED | signer.ex:61 |
| sso.html.heex | /saml/<…J0>/acs | self-submit POST | ✓ WIRED | action={@acs_url}, acs_url scoped (controller:72) |
| router.ex | FakeIdPController | get/post routes | ✓ WIRED | router.ex:40-41 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| In-process flow + signer | `mix test fake_idp_flow_test.exs signer_test.exs` | 9 tests, 0 failures | ✓ PASS |
| Full demo suite regression | `mix test` (demo) | 57 tests, 0 failures | ✓ PASS |
| Zero relyra source change | `git diff e8893f6 HEAD -- lib/ mix.exs` | empty | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SEED-003 | 57-01/02/03 | Demo FakeIdP browser-login proof (demo-local signer, option b) | ✓ SATISFIED | All 13 truths verified; in-process success + tampered round-trip green |

Note: There is no `.planning/REQUIREMENTS.md` file in this repo. SEED-003 is a tracked seed in the ROADMAP phase header (`**Requirements**: SEED-003`) and MEMORY. The ROADMAP section for Phase 57 maps SEED-003 to this phase and all three plans declare `requirements: [SEED-003]`. No orphaned requirements: SEED-003 is claimed by every plan in the phase.

### Anti-Patterns Found

None. No TBD/FIXME/XXX debt markers in any phase-modified demo file. No stubs (committed PEMs are real, signer produces real signed XML, flow test exercises real crypto/DB/telemetry/LiveView).

### Human Verification Required

None. Per 57-VALIDATION.md the explicit goal of this phase is a zero-human-UAT in-process proof (no Wallaby): both the success round-trip and the tampered→:digest_mismatch-in-trace variant are fully reachable and asserted via `Phoenix.ConnTest`/`LiveViewTest`. The VALIDATION strategy intentionally covers all phase behaviors in-process; the passing `fake_idp_flow_test.exs` is the verification surface.

### Gaps Summary

No gaps. The MVP user story is observably achieved in the codebase. The success path (SP-initiated login → built-in fake IdP → scoped ACS → strict relyra verification `{:ok}` → LoginReceipt → redirect "/") and the tampered path (NameID mutation → `:digest_mismatch` → 400, no session → `domain: :login` error AuditEvent rendered in ConnectionTraceLive) are both proven in-process. Cert-trust alignment (the declared crux) is correct: the enabled …J0 connection trusts the committed demo cert sourced single-source from `Keypair.cert_pem()`, preventing fixture/signer drift. Canonicalization reuses relyra's public engine (no auth-bypass-class divergence). No `Relyra.TestSupport` runtime reference, and zero changes to relyra `lib/` or `mix.exs` security aliases. Full demo suite: 57 tests / 0 failures.

---

_Verified: 2026-06-13_
_Verifier: Claude (gsd-verifier)_
