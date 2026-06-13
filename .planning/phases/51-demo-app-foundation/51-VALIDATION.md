---
phase: 51
slug: demo-app-foundation
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-12
---

# Phase 51 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; generated Phoenix app test support |
| Config file | `demo/ledger_loop/config/test.exs` |
| Quick run command | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs test/ledger_loop_web/controllers/health_controller_test.exs test/ledger_loop_web/router_test.exs --warnings-as-errors` |
| Full suite command | `cd demo/ledger_loop && mix test --warnings-as-errors` |
| Root regression command | `mix test --warnings-as-errors` |
| Package exclusion command | `rm -rf /tmp/relyra-package-check && mix hex.build --unpack --output /tmp/relyra-package-check && test -z "$(find /tmp/relyra-package-check -path '*/demo/*' -print -quit)"` |
| Estimated runtime | ~60 seconds after dependencies are fetched |

## Sampling Rate

- **After every task commit touching `demo/ledger_loop`:** Run `cd demo/ledger_loop && mix test --warnings-as-errors`.
- **After route, dependency, or packaging edits:** Run the relevant targeted command from the per-task map below.
- **After every plan wave:** Run root `mix test --warnings-as-errors`, demo `mix test --warnings-as-errors`, and the package exclusion command.
- **Before `$gsd-verify-work`:** Root tests, demo tests, formatting check, and package exclusion must all be green.
- **Max feedback latency:** 90 seconds after dependencies are present.

## Per-Requirement Verification Map

| Requirement | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|------------|-----------------|-----------|-------------------|-------------|--------|
| DEMO-01 | Demo app compiles and boots with Relyra as a local path dependency | T-51-01 | Dependency uses `{:relyra, path: "../.."}` without publishing or vendoring Relyra | compile/integration | `cd demo/ledger_loop && mix deps.get && mix compile --warnings-as-errors` | no, Wave 0 | pending |
| DEMO-02 | Root Hex package excludes `demo/` while repo-local demo commands work | T-51-02 | Demo evidence cannot leak into the published Hex payload | package/integration | `rm -rf /tmp/relyra-package-check && mix hex.build --unpack --output /tmp/relyra-package-check && test -z "$(find /tmp/relyra-package-check -path '*/demo/*' -print -quit)"` | no, Wave 0 | pending |
| DEMO-03 | First screen shows LedgerLoop workspace status and setup, login, admin, support affordances | T-51-03 | UI shows status/affordances without raw XML, PEM, secrets, assertions, or request params | controller/HTML | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs --warnings-as-errors` | no, Wave 0 | pending |
| DEMO-04 | Relyra SAML routes mount under `/saml` and LiveAdmin mounts under `/relyra/admin` | T-51-04 | Host-owned route scope uses Relyra router/admin macros rather than custom SAML parsing routes | router/unit | `cd demo/ledger_loop && mix test test/ledger_loop_web/router_test.exs --warnings-as-errors` | no, Wave 0 | pending |
| DEMO-05 | `/healthz` and `/readyz` distinguish booted from unavailable demo state | T-51-05 | Readiness checks app/database availability only; it does not require Phase 52 seed data | controller | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/health_controller_test.exs --warnings-as-errors` | no, Wave 0 | pending |

## Wave 0 Requirements

- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` covers DEMO-03.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs` covers DEMO-05.
- [ ] `demo/ledger_loop/test/ledger_loop_web/router_test.exs` covers DEMO-04.
- [ ] A package exclusion verification path covers DEMO-02.
- [ ] The generated demo app compiles with local path dependency `{:relyra, path: "../.."}` for DEMO-01.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First screen feels like a usable LedgerLoop workspace, not a protocol fixture | DEMO-03 | Visual quality and information hierarchy require human review against `51-UI-SPEC.md` | Boot `demo/ledger_loop`, open `/`, and compare visible nav, status, and panels against the UI-SPEC sections for first-screen expectations and forbidden raw protocol content. |

## Validation Sign-Off

- [x] All phase requirements have automated verification commands or Wave 0 dependencies.
- [x] Sampling continuity prevents three consecutive demo-edit tasks without automated verification.
- [x] Wave 0 lists every missing test/support artifact required for DEMO-01 through DEMO-05.
- [x] No watch-mode flags are used in verification commands.
- [x] Feedback latency target is under 90 seconds after dependencies are present.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** approved 2026-06-12
