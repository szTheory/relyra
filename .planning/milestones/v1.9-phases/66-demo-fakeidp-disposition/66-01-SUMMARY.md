---
phase: 66-demo-fakeidp-disposition
plan: 01
subsystem: demo-audit
tags: [ledger-loop, fake-idp, phoenix, saml, playwright, seed-003]

requires:
  - phase: 57-demo-fakeidp-browser-login-proof
    provides: Demo-local FakeIdP signer, routes, templates, and in-process flow proof for SEED-003
  - phase: 57.1-address-phase-57-tech-debt-tamper-guard-label-input-hardening
    provides: FakeIdP hardening for label correctness, bounded inflate, catch-all action handling, XML escaping, and keypair diagnostics
provides:
  - Current route/controller/view/support-module map for the LedgerLoop FakeIdP flow
  - Current test coverage and run status for ExUnit and Playwright FakeIdP checks
  - SEED-003 context from STATE, milestone, Phase 57, and Phase 57.1 planning artifacts
affects: [66-demo-fakeidp-disposition, demo-ledger-loop, seed-003]

tech-stack:
  added: []
  patterns:
    - Audit-only summary with no implementation changes
    - Demo app tests must be run from demo/ledger_loop, not the root Mix project

key-files:
  created:
    - .planning/phases/66-demo-fakeidp-disposition/66-01-SUMMARY.md
  modified: []

key-decisions: []

patterns-established:
  - FakeIdP disposition should separate passing in-process proof from current browser-lane operability
  - SEED-003 is historically satisfied by Phase 57/57.1, but v1.9 still needs an explicit retain/remove/document decision

requirements-completed: [DEMO-01]

duration: 9min
completed: 2026-06-18
status: complete
---

# Phase 66 Plan 01: Audit FakeIdP Current State & SEED-003 Summary

**LedgerLoop FakeIdP audit mapped the active Phoenix route surface, verified green in-process SAML success/tamper coverage, and found the dedicated browser lane currently blocked by local port-4000 coupling**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-18T20:10:40Z
- **Completed:** 2026-06-18T20:19:26Z
- **Tasks:** 3 completed
- **Files modified:** 1 planning summary only

## Accomplishments

- Mapped the active `/fake_idp/login` and `/fake_idp/sso` routes, controller actions, HEEx templates, signer, keypair, fixture cert/key material, and browser spec entry point.
- Verified the current ExUnit FakeIdP coverage from the demo app: controller suite, full in-process SP-initiated round trip, signer/keypair suites, and UAT coverage guard all pass.
- Investigated SEED-003 across current and archived planning artifacts: it began as the demo FakeIdP browser-login WIP, was satisfied by Phase 57, then hardened by Phase 57.1, and is back in v1.9 for an explicit retain/remove/document disposition.

## Task Commits

Audit tasks produced no implementation file changes, so there were no per-task commits.

- **Task 1: Map FakeIdP Routes, Controllers, and Views** - no file changes
- **Task 2: Identify and Verify FakeIdP Test Coverage** - no file changes
- **Task 3: Investigate SEED-003 Context** - no file changes

## Current FakeIdP Surface

### Routes

- `demo/ledger_loop/lib/ledger_loop_web/router.ex:47` starts the browser scope with `pipe_through :browser`.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex:56` registers `GET /fake_idp/login` to `LedgerLoopWeb.FakeIdPController.login/2`.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex:57` registers `POST /fake_idp/sso` to `LedgerLoopWeb.FakeIdPController.sso/2`.
- The Relyra ACS route remains mounted under `/saml` with the dedicated `:saml` pipeline at `router.ex:65`.

### Controller and Templates

- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`
  - `login/2` (`:50`) reads `RelayState` and `SAMLRequest`, extracts `InResponseTo`, and renders `:login`.
  - `sso/2` (`:72`) builds fields from `LedgerLoop.Demo.Fixtures`, targets `/saml/<enabled-connection>/acs`, and chooses `Signer.signed_response/1` for success or `Signer.tamper/1` for failure.
  - `extract_in_response_to/1` (`:122`) decodes and bounded-inflates the raw-deflate `SAMLRequest`, then captures only a root ID matching the NCName-like regex.
  - `inflate/1` (`:147`) uses `:zlib.safeInflate/2` with a 64 KiB ceiling and fails closed to nil through the caller.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex` embeds `fake_idp_html/*`.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex`
  - Shows the "Local Test Support / FakeIdP" warning.
  - Posts to `/fake_idp/sso` with CSRF token, optional `RelayState`, optional `in_response_to`, and radio choices for valid sarah login or tampered signature.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex`
  - Self-submits a `SAMLResponse` POST to `@acs_url`, preserving non-empty `RelayState`.

### Support Modules and Fixtures

- `demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex`
  - `private_key/0` loads and caches the committed demo RSA key from `priv/fake_idp/idp_key.pem`.
  - `cert_pem/0` returns the committed demo IdP certificate from `priv/fake_idp/idp_cert.pem`.
  - `decode_pem_key/1` raises a descriptive error unless the PEM is exactly one unencrypted RSA private key.
- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`
  - `signed_response/1` emits a real signed SAML Response, recomputing digest/signature through Relyra's `PureBeam.canonicalize/1` and `C14N.serialize/1` paths.
  - `tamper/1` mutates the signed Assertion `NameID` after signing, producing the expected `:digest_mismatch` rejection.
  - The module uses public prod-compiled Relyra XML modules and does not call private `Relyra.TestSupport` modules.
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex:61` still hard-codes the enabled connection `idp_sso_url` to `http://localhost:4000/fake_idp/login`.

## Test Coverage and Run Status

### Exact Plan Commands

- `mix test demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs` from repo root: failed. Root Mix does not load `LedgerLoopWeb.ConnCase`, so the demo controller test cannot compile from the root project.
- `mix test demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` from repo root: failed for the same `LedgerLoopWeb.ConnCase` compile reason.

### Demo App ExUnit Commands

- `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/fake_idp_controller_test.exs`: **PASS**, 12 tests, 0 failures.
- `cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs`: **PASS**, 2 tests, 0 failures.
- `cd demo/ledger_loop && mix test test/ledger_loop/fake_idp/signer_test.exs test/ledger_loop/fake_idp/keypair_test.exs test/uat_coverage_test.exs`: **PASS**, 19 tests, 0 failures.

Coverage found:

- `demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs` covers warning banner, RelayState passthrough, direct visit with no `in_response_to`, oversized/garbled/malformed `SAMLRequest` fail-closed behavior, self-submitting success/failure forms, unknown `idp_action` catch-all, and sarah label correctness.
- `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` covers full SP-initiated success from `/saml/<id>/login` through `/fake_idp/*` to ACS, then receipt insertion and redirect `/`; it also covers tampered response rejection with no receipt and a `digest_mismatch` login trace.
- `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs` covers real `Signature.verify/4` acceptance, unique assertion IDs, post-sign tamper rejection, XML escaping, and no functional `Relyra.TestSupport` dependency.
- `demo/ledger_loop/test/ledger_loop/fake_idp/keypair_test.exs` covers private-key decode/cache, cert PEM bytes, descriptive bad-PEM errors, and key/cert pairing.
- `demo/ledger_loop/test/uat_coverage_test.exs` guards the Phase 57.1 UAT coverage manifest so cited FakeIdP tests cannot be deleted silently.

### Browser Lane

- `demo/ledger_loop/test/browser/fake_idp.spec.ts` exists and is wired through the root `npm run demo:fake-idp` script with `playwright.fake-idp.config.mjs`.
- Initial `npm run demo:fake-idp` failed because port 4000 was already occupied by a Docker listener. The Playwright config reuses an existing server when `CI` is unset, so `/login/test` hit that listener and rendered `Not Found`.
- Fresh-port rerun `CI=1 PORT=4021 BASE_URL=http://127.0.0.1:4021 npm run demo:fake-idp` also failed. The app started on 4021, but clicking the route affordance goes through `/saml/<id>/login`, whose seeded `idp_sso_url` redirects to hard-coded `http://localhost:4000/fake_idp/login`; that port still rendered `Not Found`, so Playwright could not find `#action-success` or `#action-failure`.
- Current browser status: dedicated FakeIdP Playwright lane is present but not green in this local run unless the demo owns port 4000 or the seed/config becomes port-aware.

Generated Playwright `test-results/` artifacts are ignored by git.

## SEED-003 Context

- `.planning/STATE.md` currently mentions SEED-003 only as part of the v1.9 maintenance scope: "v1.9 rolls SEED-002, SEED-003, and narrow maintenance sync into a bounded adoption-honesty milestone."
- `.planning/MILESTONES.md` records SEED-003 as one of two dormant seeds opened at v1.7 close: "demo FakeIdP login WIP."
- `.planning/v1.7-MILESTONE-AUDIT.md` states that Phase 57 was a standalone post-v1.7 phase added to close SEED-003, and that SEED-003 was satisfied with the `/fake_idp/*` browser-login proof.
- `.planning/milestones/v1.7-phases/57-demo-fakeidp-browser-login-proof/57-VERIFICATION.md` verifies the intended behavior: browser bounce to built-in FakeIdP, InResponseTo correlation, real signed success through Relyra's crypto gate, and typed `:digest_mismatch` rejection on tamper.
- `.planning/milestones/v1.7-phases/57-demo-fakeidp-browser-login-proof/57-03-SUMMARY.md` explicitly says "SEED-003 is fully resolved (option b, demo-local signer)."
- `.planning/milestones/v1.7-phases/57.1-address-phase-57-tech-debt-tamper-guard-label-input-hardenin/57.1-VERIFICATION.md` verifies the later hardening items now visible in current code: sarah label correction, unknown `idp_action` catch-all, bounded `safeInflate`, NCName ID extraction, XML escaping, and descriptive PEM decode errors.

Current implication: SEED-003 is not an unimplemented proof anymore. It is a historically satisfied demo proof that v1.9 is revisiting for product/demo disposition: retain and document it as intentional local proof, or remove it to simplify the demo's login story. The decision should account for the green in-process evidence and the currently brittle browser run coupling to hard-coded port 4000.

## Decisions Made

None - this plan was audit-only and intentionally does not choose retain vs remove. Plan 66-02 owns that disposition decision.

## Deviations from Plan

None - plan executed exactly as written. Verification included additional demo-app-relative commands after the exact root-level commands failed because the LedgerLoop tests belong to the nested demo Mix project.

## Issues Encountered

- The root-level Mix test paths in the plan are not runnable from the root project because `LedgerLoopWeb.ConnCase` is not compiled there. Running from `demo/ledger_loop` is the accurate current test command.
- The browser lane could not be verified green locally. Port 4000 was occupied by a Docker listener, and the enabled FakeIdP seed redirects to hard-coded `http://localhost:4000/fake_idp/login`.

## Known Stubs

None found in files created or modified by this audit plan.

## Threat Flags

None - audit-only; no implementation code, network endpoint, auth path, file access pattern, or trust-boundary behavior changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 66-02. The next plan should decide whether the demo should retain and document FakeIdP, or remove it, using these facts:

- Current implementation exists and remains route-accessible.
- In-process ExUnit proof is green and covers both verified success and typed crypto rejection.
- Dedicated browser Playwright proof exists but is currently port-coupled to 4000.
- SEED-003 was already satisfied by Phase 57 and hardened by Phase 57.1; v1.9's remaining work is disposition and cleanup/documentation, not initial implementation.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/66-demo-fakeidp-disposition/66-01-SUMMARY.md`.
- Required route/controller/template/support files were found.
- Required plan verification commands were run and their outcomes are documented.
- Additional demo-app-relative test commands were run and their outcomes are documented.

---
*Phase: 66-demo-fakeidp-disposition*
*Completed: 2026-06-18*
