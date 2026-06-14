---
phase: 57-demo-fakeidp-browser-login-proof
plan: "03"
subsystem: auth
tags: [saml, elixir, phoenix, demo, fakeidp, sp-initiated, telemetry, liveview]

requires:
  - phase: 57-01
    provides: Keypair PEMs, fixture cert-trust, idp_sso_url pointing at local FakeIdP, LoginTrace attached
  - phase: 57-02
    provides: LedgerLoop.FakeIdP.Signer with signed_response/1 + tamper/1 (genuine SAML signing via relyra C14N)

provides:
  - GET /fake_idp/login + POST /fake_idp/sso routes wired in :browser pipeline
  - FakeIdPController: login/2 inflates SAMLRequest to capture InResponseTo; sso/2 calls Signer, posts to scoped ACS
  - End-to-end SP-initiated success round-trip (login → ACS → verified → LoginReceipt → /)
  - Tampered variant: :digest_mismatch typed rejection surfaced in domain: :login AuditEvent and ConnectionTraceLive
  - Affordance repointed to /saml/<…J0>/login (SP-initiated; mints AuthnRequest + intent)
  - SessionAdapter bug fix: Map.get instead of Access.[] on Relyra.LoginResult struct

affects:
  - Phase 57 completion (SEED-003 demo FakeIdP proof closed)

tech-stack:
  added: []
  patterns:
    - "InResponseTo capture: inflate deflated base64 SAMLRequest via :zlib inflateInit(-15) + regex on ID attribute"
    - "Scoped ACS form action: self-submitting POST to /saml/<conn_ulid>/acs (not bare /saml/acs)"
    - "Flow test seeding: Reset.reset!/0 + async: false (shared sandbox) so LoginTrace telemetry writes are visible"
    - "Trace assertion: after_summary[steps][signature.verify] for digest_mismatch proof"

key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex
    - demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs
    - demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop_web/router.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
    - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
    - demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex

key-decisions:
  - "InResponseTo captured by inflating the deflated base64 SAMLRequest via :zlib raw inflate (-15 window), matching Binding.deflate_xml/1 exactly"
  - "FakeIdP controller drives all SAML fields (issuer/destination/recipient/audience) from Fixtures at runtime — no hardcoded URLs"
  - "Scoped ACS URL /saml/<…J0>/acs built from Fixtures.relyra_enabled_scenario_id/0 at runtime in sso/2"
  - "Flow test uses async: false + Reset.reset! (shared sandbox); LoginTrace writes are synchronous/in-process"
  - "Trace assertion reads after_summary[steps] (map keyed by step_name), not diff_summary"
  - "SessionAdapter.establish_session/3 fix: Map.get/2 replaces Access.[] on Relyra.LoginResult struct"
  - "Task 3 (full demo suite) verified green at 57 tests; no commit needed (verification-only task)"

patterns-established:
  - "Pattern: inflate SAMLRequest with :zlib inflateInit(-15) to extract ID for InResponseTo"
  - "Pattern: flow test seeds via Reset.reset! + async: false for telemetry handler process safety"

requirements-completed: [SEED-003]

duration: 30min
completed: "2026-06-14"
---

# Phase 57, Plan 03: FakeIdP Controller + Browser Flow Proof Summary

**SP-initiated full round-trip wired in-process: /saml/J0/login → /fake_idp/* → /saml/J0/acs → verified → LoginReceipt → /; tampered variant lands :digest_mismatch typed rejection in the ConnectionTraceLive trace UI**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-06-14T01:00:00Z
- **Completed:** 2026-06-14T01:30:00Z
- **Tasks:** 3 (T1: routes/controller, T2: flow test + affordance, T3: full-suite gate)
- **Files modified:** 10

## Accomplishments

- Recovered WIP from `wip/demo-fake-idp` branch and corrected all four WIP defects: replaced `Relyra.TestSupport.FakeIdP.sign` with `LedgerLoop.FakeIdP.Signer`, drove fields from the …J0 fixture, scoped the ACS form action to `/saml/<…J0>/acs`, and captured `InResponseTo` from the inflated SAMLRequest
- Wired `GET /fake_idp/login` + `POST /fake_idp/sso` in the `:browser` pipeline (CSRF + session plugs apply); controller test updated to assert the scoped ACS path
- Created `fake_idp_flow_test.exs` with success round-trip (302 redirect to "/" + LoginReceipt inserted) and tampered round-trip (400, no receipt, `digest_mismatch` AuditEvent rendered in ConnectionTraceLive trace UI)
- Repointed route affordance from `/fake_idp/login?RelayState=` to `/saml/<…J0>/login` so the button mints an AuthnRequest + intent (T-57-09 SP-initiated; T-57-10 scoped ACS)
- Fixed pre-existing bug in `SessionAdapter.establish_session/3`: `context[:connection_id]` used Access behaviour on a `%Relyra.LoginResult{}` struct (which doesn't implement Access) — replaced with `Map.get/2`
- Full demo suite: 57 tests, 0 failures (above ≥37 target); zero relyra `lib/` or `mix.exs` changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Recover + correct FakeIdP controller/templates, wire routes** - `aa8879e` (feat)
2. **Task 2: End-to-end flow test, affordance repoint, SessionAdapter fix** - `be558e9` (feat)
3. **Task 3: Full demo-suite regression gate** - verified green (57/0); no code changes → no commit

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` — login/2 (inflate SAMLRequest, extract InResponseTo) + sso/2 (drive fields from fixture, Signer.signed_response/tamper, scoped acs_url)
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex` — embed_templates "fake_idp_html/*"
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex` — "Local Test Support / FakeIdP" banner + RelayState + in_response_to hidden fields
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex` — self-submitting POST form with `action={@acs_url}`, SAMLResponse, RelayState hidden fields
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` — added GET /fake_idp/login + POST /fake_idp/sso in :browser scope
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` — link repointed from /fake_idp/login?RelayState= to /saml/<…J0>/login
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` — Map.get(context, :connection_id) fix
- `demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs` — 5 tests: banner, RelayState passthrough, no-in_response_to-on-direct, scoped ACS action (success + failure)
- `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` — 2 tests: SUCCESS full round-trip + TAMPERED → trace UI
- `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` — updated affordance link assertion to /saml/<…J0>/login

## Decisions Made

- **InResponseTo inflate approach:** Used `:zlib.inflateInit(z, -15)` (raw inflate, -15 window) to mirror `Binding.deflate_xml/1`'s deflateInit window exactly. Regex `~r/\bID="([^"]+)"/` on the inflated XML to extract the AuthnRequest ID. Tolerates absent/garbled SAMLRequest (returns nil, renders form anyway — T-57-13).
- **Runtime field derivation:** `conn_fields/0` calls `Fixtures.relyra_connections()` at runtime (not compile time) so the controller always uses the current fixture values — consistent with signer's in_response_to threading.
- **Flow test async: false + shared sandbox:** LoginTrace telemetry handler writes happen synchronously in the dispatching process (ConnTest runs in the test process). `async: false` enables shared sandbox mode so all DB writes from the request are visible to the test process.
- **Trace assertion via after_summary:** `LoginTrace` stores steps as a map in `after_summary["steps"]`, not `diff_summary`. The `signature.verify` step carries `outcome: "error"` and `error_code: "digest_mismatch"` when the tampered assertion fails `do_verify/4`.
- **SessionAdapter Map.get fix:** `%Relyra.LoginResult{}` does not implement `Access`, so `context[:connection_id]` raises `UndefinedFunctionError`. Fixed to `Map.get(context, :connection_id)` which works on any map/struct. This is a Rule 1 bug that was blocking the success path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SessionAdapter.establish_session/3 crashed with UndefinedFunctionError on Relyra.LoginResult**
- **Found during:** Task 2 (flow test success round-trip)
- **Issue:** `context[:connection_id]` used `Access.get/3` on `%Relyra.LoginResult{}` which does not implement the Access behaviour; raised `Relyra.LoginResult.fetch/2 is undefined`
- **Fix:** Replaced `context[:connection_id]` with `Map.get(context, :connection_id)` — correct for any map or struct
- **Files modified:** `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex`
- **Verification:** Success round-trip LoginReceipt inserted; flow test passes
- **Committed in:** `be558e9` (Task 2 commit)

**2. [Rule 1 - Bug] Flow test read steps from wrong AuditEvent field**
- **Found during:** Task 2 (tampered trace assertion)
- **Issue:** Test asserted `latest.diff_summary["steps"]` but `LoginTrace` stores steps in `after_summary["steps"]` (the `:stop` handler writes `after_summary: %{"steps" => ..., "overall_outcome" => ...}`)
- **Fix:** Updated test to read `after_summary["steps"]["signature.verify"]` for the `digest_mismatch` proof; assert `after_summary["overall_outcome"] == "error"` for the overall outcome
- **Files modified:** `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs`
- **Verification:** Tampered test passes; trace rendered in LiveView
- **Committed in:** `be558e9` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both bugs were blocking the primary acceptance criteria. Both are correctness-only fixes in the demo layer. No scope creep; no relyra source changed.

## Issues Encountered

None beyond the two auto-fixed bugs above.

## Known Stubs

None. The full round-trip uses real crypto, real DB, real telemetry, and real ConnectionTraceLive. No placeholder values.

## Threat Flags

None. All new surface is inside `demo/` scope:
- `GET /fake_idp/login` + `POST /fake_idp/sso` are CSRF-protected via `:browser` pipeline (T-57-09)
- Self-submitting form posts to connection-scoped `/saml/<…J0>/acs` (T-57-10)
- "Local Test Support / FakeIdP" banner copy present in both controller test and login template (T-57-12)
- `extract_in_response_to/1` tolerates absent/garbled SAMLRequest with `nil` fallback (T-57-13)
- `LoginTrace` writes `domain: :login` AuditEvent on tampered attempt — T-57-11 mitigated
- Zero new dependencies (T-57-SC)

## Next Phase Readiness

- Phase 57 objective complete: evaluator can click "Simulate Login via FakeIdP" → SP-initiated chain → verified login → "/" OR see typed `:digest_mismatch` rejection in the trace UI
- SEED-003 is fully resolved (option b, demo-local signer)
- No blockers; no open items from this phase

## Self-Check: PASSED

- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` — FOUND
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex` — FOUND
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex` — FOUND
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex` — FOUND
- `demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs` — FOUND
- `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` — FOUND
- Commit `aa8879e` (Task 1: routes + controller) — FOUND
- Commit `be558e9` (Task 2: flow test + affordance + SessionAdapter fix) — FOUND
- `grep -c "Relyra.TestSupport" demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` = 0 — VERIFIED
- Full demo suite: 57 tests, 0 failures — VERIFIED
- No relyra `lib/` changes — VERIFIED

---
*Phase: 57-demo-fakeidp-browser-login-proof*
*Completed: 2026-06-14*
