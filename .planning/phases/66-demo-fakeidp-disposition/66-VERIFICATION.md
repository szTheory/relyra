---
phase: 66-demo-fakeidp-disposition
verified: 2026-06-18T20:49:07Z
status: passed
score: "8/8 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 66: Demo FakeIdP Disposition Verification Report

**Phase Goal:** Verify, finish, document, or remove the LedgerLoop FakeIdP browser flow so the demo has one intentional login story.
**Verified:** 2026-06-18T20:49:07Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Current `/fake_idp/login` and `/fake_idp/sso` routes, controller tests, and browser/demo lane status are verified. | VERIFIED | `router.ex:56-57` registers both routes. `fake_idp_controller_test.exs` covers login and SSO controller behavior. `fake_idp_flow_test.exs` covers success and tamper in-process end-to-end. `fake_idp.spec.ts` and `playwright.fake-idp.config.mjs` define the real browser lane. Focused ExUnit command passed: 14 tests, 0 failures. |
| 2 | The milestone makes an explicit retain-vs-remove decision for the demo FakeIdP browser flow. | VERIFIED | `.planning/STATE.md:28` records Plan 66-03 inactive after `retain_fakeidp`; `.planning/ROADMAP.md:107-109` records the retain branch and inactive removal branch. |
| 3 | If retained, the flow is documented as the canonical or clearly labeled local FakeIdP browser proof. | VERIFIED | `guides/fake_idp_demo.md:3-13` labels FakeIdP as demo-local test support, not production IdP or hosted broker. `guides/fake_idp_demo.md:20-31` documents the route-affordance path. `guides/fake_idp_demo.md:33-54` documents success and tamper behavior. |
| 4 | If removed, stale routes/controllers/templates/tests are deleted and route-affordance login remains canonical. | VERIFIED | Removal condition is false. `.planning/ROADMAP.md:103-109` and `.planning/STATE.md:28` record 66-03 as inactive after `retain_fakeidp`. `66-03-SUMMARY.md:25-36` records the unselected branch as skipped; the retained route-affordance login remains wired in `route_affordance_html/login.html.heex:12-14`. |
| 5 | SEED-003 is resolved or reclassified with evidence. | VERIFIED | `.planning/STATE.md:30` points SEED-003 resolution at `guides/fake_idp_demo.md`; `.planning/STATE.md:70` gives the retained-branch rationale. `grep -c "SEED-003: RESOLVED" .planning/STATE.md` returned `2`. |
| 6 | The current status and behavior of the FakeIdP flow is clearly understood. | VERIFIED | Code inspection confirmed route/controller/template/signer/keypair/browser-spec wiring. The docs also preserve the current browser-lane caveat at `guides/fake_idp_demo.md:56-69`. |
| 7 | A clear directive for SEED-003 resolution is recorded. | VERIFIED | `.planning/STATE.md:70` records SEED-003 resolved by retaining FakeIdP as demo-local support and documenting purpose, access, success behavior, tamper behavior, limits, and the port-4000 caveat. |
| 8 | Documentation explains how to access and use the FakeIdP. | VERIFIED | `guides/fake_idp_demo.md:15-31` gives the access path; `guides/fake_idp_demo.md:33-54` gives expected success and tamper outcomes; `guides/fake_idp_demo.md:71-78` records limits. |

**Score:** 8/8 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/fake_idp_demo.md` | Retained FakeIdP guide | VERIFIED | Exists, 78 lines, covers purpose, access, success, tamper, automated check, limits, and port-4000 caveat. |
| `.planning/STATE.md` | SEED-003 resolution evidence | VERIFIED | Contains `SEED-003: RESOLVED` twice with rationale and guide reference. |
| `demo/ledger_loop/lib/ledger_loop_web/router.ex` | Retained FakeIdP routes | VERIFIED | `GET /fake_idp/login` and `POST /fake_idp/sso` are present under browser pipeline. |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` | FakeIdP request handling | VERIFIED | `login/2` extracts RelayState/SAMLRequest; `sso/2` emits success or tampered SAMLResponse through `LedgerLoop.FakeIdP.Signer`. |
| `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` | Real signed and tampered SAML responses | VERIFIED | Uses Relyra XML C14N/parser paths, computes digest/signature, and mutates signed NameID for `digest_mismatch`. |
| `demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs` | Controller coverage | VERIFIED | Covers warning banner, RelayState, SAMLRequest fail-closed handling, success SSO form, tamper form, unknown action, and label correctness. |
| `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` | In-process flow proof | VERIFIED | Covers SP-initiated success through ACS and tamper rejection with no receipt plus `digest_mismatch` trace evidence. |
| `demo/ledger_loop/test/browser/fake_idp.spec.ts` | Browser-lane proof definition | VERIFIED | Exists and is wired by `package.json` `demo:fake-idp` and `playwright.fake-idp.config.mjs`. Execution intentionally not used as close-out proof because current port-4000 coupling is documented. |
| `.planning/phases/66-demo-fakeidp-disposition/66-03-SUMMARY.md` | Inactive removal branch record | VERIFIED | Frontmatter `status: skipped`; records that Plan 66-03 was not executed because `retain_fakeidp` was selected. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `/login/test` page | `/saml/<connection-id>/login` | `route_affordance_html/login.html.heex:12-14` | WIRED | The visible "Simulate Login via FakeIdP" link starts the SP-initiated login. |
| `router.ex` | `LedgerLoopWeb.FakeIdPController` | `get "/fake_idp/login"` and `post "/fake_idp/sso"` | WIRED | Both FakeIdP endpoints are mounted under the browser pipeline. |
| `FakeIdPController.sso/2` | `LedgerLoop.FakeIdP.Signer` | `Signer.signed_response/1` and `Signer.tamper/1` | WIRED | Success action emits signed response; failure action tampers post-signing. |
| `FakeIdPController.sso/2` | Relyra ACS | `acs_url = "/saml/#{conn_ulid}/acs"` and `sso.html.heex` form action | WIRED | SSO response renders a self-submitting POST to the connection-scoped ACS route. |
| `package.json` | `demo/ledger_loop/test/browser/fake_idp.spec.ts` | `npm run demo:fake-idp` -> `playwright.fake-idp.config.mjs` | WIRED | Browser spec is selected by `testMatch: /fake_idp\.spec\.ts/`; docs disclose current port-4000 coupling. |
| `.planning/STATE.md` | `guides/fake_idp_demo.md` | Resolution text references guide path | WIRED | SEED-003 resolution points at the retained-flow documentation evidence. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `FakeIdPController.login/2` | `relay_state`, `in_response_to` | Request params plus bounded raw-deflate SAMLRequest extraction | Yes | FLOWING - controller tests verify RelayState passthrough and fail-closed SAMLRequest handling. |
| `FakeIdPController.sso/2` | `saml_response`, `acs_url` | `Signer.signed_response/1` or `Signer.tamper/1`, fixture connection id | Yes | FLOWING - flow test posts generated response to ACS and verifies success or `digest_mismatch` rejection. |
| `LedgerLoop.FakeIdP.Signer` | signed XML digest/signature | Relyra `PureBeam.canonicalize/1`, `C14N.serialize/1`, demo RSA keypair | Yes | FLOWING - signer computes real digest/signature, not static placeholder acceptance. |
| `guides/fake_idp_demo.md` | Documentation content | Static guide | N/A | VERIFIED - static documentation artifact; no dynamic data flow required. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase inventory has all summaries | `node /Users/jon/.npm/_npx/a78857a30883db8e/node_modules/@opengsd/gsd-core/gsd-core/bin/gsd-tools.cjs query phase-plan-index 66` | `incomplete: []`; four plans have summaries | PASS |
| Phase contract is Phase 66 with expected success criteria | `node /Users/jon/.npm/_npx/a78857a30883db8e/node_modules/@opengsd/gsd-core/gsd-core/bin/gsd-tools.cjs query roadmap.get-phase 66 --raw` | Returned Phase 66 goal, DEMO-01/02/03, and five success criteria | PASS |
| Retention documentation artifact and state marker satisfy Plan 66-04 artifacts | `node .../gsd-tools.cjs query verify.artifacts .planning/phases/66-demo-fakeidp-disposition/66-04-PLAN.md` | `all_passed: true`, 2/2 artifacts passed | PASS |
| FakeIdP controller and in-process flow work | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/fake_idp_controller_test.exs test/ledger_loop_web/fake_idp_flow_test.exs` | 14 tests, 0 failures | PASS |
| SEED-003 has resolved marker | `grep -c "SEED-003: RESOLVED" .planning/STATE.md` | `2` | PASS |
| Guide documents retained flow and browser-lane caveat | `grep -nE "fake_idp|FakeIdP|demo:fake-idp|port-4000|digest_mismatch" guides/fake_idp_demo.md` | Found route, command, caveat, and typed rejection text | PASS |
| Real Playwright browser lane | `npm run demo:fake-idp` | Not run; command starts a server and the current accepted disposition documents the port-4000 coupling instead of using this as close-out proof | SKIPPED |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| None declared | N/A | Phase does not declare probe scripts and is not a migration/tooling phase | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEMO-01 | 66-01 | LedgerLoop FakeIdP browser flow current state is verified through route/controller/browser or demo-lane tests. | SATISFIED | Router/controller/signer/tests/browser spec inspected; focused ExUnit flow passed; browser-lane caveat documented. |
| DEMO-02 | 66-02 | The demo has one intentional documented browser-login path: either retain and document `/fake_idp/*`, or remove it and keep route-affordance login canonical. | SATISFIED | `retain_fakeidp` is recorded in roadmap/state; guide documents the retained local proof path. |
| DEMO-03 | 66-04 | SEED-003 is resolved with evidence, not left dormant with stale route assumptions. | SATISFIED | State marks `SEED-003: RESOLVED` and points at `guides/fake_idp_demo.md`; guide documents the evidence and limitations. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.planning/REQUIREMENTS.md` | 31 | Pending `MAINT-01` contains "stale" | Info | Not a Phase 66 artifact or gap; belongs to Phase 67 maintenance sync. |

No Phase 66 blocker markers (`TBD`, `FIXME`, `XXX`) or user-visible placeholders were found in the modified Phase 66 artifacts. `placeholder` occurrences in `signer.ex` refer to internal placeholder XML used before computing real digest/signature and are not stubs.

### Human Verification Required

None.

### Disconfirmation Pass

- Partial requirement considered: the real browser lane is not proven green on arbitrary ports. This is not a Phase 66 gap because the selected disposition explicitly documents the port-4000 coupling and keeps ExUnit as close-out proof.
- Potentially misleading test considered: `fake_idp_flow_test.exs` is in-process ConnCase coverage, not a real Chromium run. The separate Playwright spec exists and the guide names its current limitation.
- Uncovered path considered: `npm run demo:fake-idp` can fail when the demo does not own port 4000. The retained-flow guide discloses that limit instead of claiming a green portable browser lane.

### Gaps Summary

No blocking gaps found. Phase 66 achieved the selected retain-and-document path: the FakeIdP remains intentionally available, the one browser-login story is documented, the unselected removal branch is closed as inactive, and SEED-003 is resolved with evidence.

---

_Verified: 2026-06-18T20:49:07Z_
_Verifier: the agent (gsd-verifier)_
