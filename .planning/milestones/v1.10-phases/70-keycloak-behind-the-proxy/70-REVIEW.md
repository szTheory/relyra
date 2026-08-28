---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T22:32:57Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - scripts/test_keycloak_proxy_e2e.sh
  - .github/workflows/keycloak-proxy-e2e.yml
  - mix.lock
  - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
  - demo/ledger_loop/test/ledger_loop/demo/reset_test.exs
  - lib/relyra/live_admin/connection_trace_live.ex
  - test/relyra/live_admin/phase15_ui_contract_test.exs
  - scripts/test_trace_visual_e2e.sh
  - playwright.trace-visual.config.mjs
  - demo/ledger_loop/test/browser/trace_visual.spec.ts
  - package.json
  - .github/workflows/demo-app-e2e.yml
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T22:32:57Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The new trace-visual browser gate performs a real tampered FakeIdP POST, verifies the 400 rejection and resulting trace, and passed locally. The Keycloak static and diagnostics/artifact-policy self-tests also passed, as did the focused Elixir tests. Credential-bearing artifacts are disabled and the new trace harness removes its private output directory.

The advertised `RELYRA_HOST` override is only checked by rendered Compose/realm assertions. Its real browser flow remains bound to `relyra.localhost`, so an override can regress without failing the Keycloak E2E command.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Custom proxy host is not exercised by the purported public-host E2E

**File:** `scripts/test_keycloak_proxy_e2e.sh:615-621`, `playwright.keycloak-proxy.config.mjs:18-33`, `demo/ledger_loop/test/browser/keycloak.spec.ts:16-18,31,50`

**Issue:** The shell harness accepts `RELYRA_HOST` and derives `PUBLIC_HOST`, then sets `BASE_URL` to that host for Playwright. However, the browser's resolver rules map only `relyra.localhost` and `keycloak.relyra.localhost`, while the spec asserts those same literal origins and URLs. A run such as `RELYRA_HOST=phase70.example.local npm run demo:keycloak-proxy` therefore cannot reach the local proxy under the supplied host (and would fail its fixed-origin assertions even if external DNS happened to resolve it). The preceding loop at lines 524-528 proves only Compose and realm text substitution, not the public Keycloak/ACS round trip for the overridden host. This leaves the custom-host branch as a false-positive static proxy despite the harness presenting it as a runtime option.

**Fix:** Derive the public host and Keycloak host from `BASE_URL` in the Playwright config, pass both dynamically in `--host-resolver-rules`, and make `keycloak.spec.ts` compare against derived `baseURL`/Keycloak origins rather than literals. Add a focused CI or local invocation using a non-`.localhost` override (for example `phase70.example.local`) and configure `DEMO_CHECK_ORIGINS` for it so the authenticated LiveView trace transition is covered too.

---

_Reviewed: 2026-08-26T22:32:57Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
