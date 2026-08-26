---
phase: 70
slug: keycloak-behind-the-proxy
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-26
---

# Phase 70 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix, Playwright, and Docker Compose |
| **Config file** | `playwright.fleet-proxy.config.mjs` as the existing host-side proxy pattern; add a Keycloak-specific config only if spec selection cannot reuse it |
| **Quick run command** | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` |
| **Full suite command** | `npm run demo:keycloak-proxy && mix qa && mix ci.security && mix format --check-formatted` |
| **Estimated runtime** | ~600 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrowest automated command listed for that task; for demo application changes, run the scoped ExUnit command above.
- **After every plan wave:** Run `npm run demo:keycloak-proxy && mix test --warnings-as-errors`.
- **Before `$gsd-verify-work`:** Run `npm run demo:keycloak-proxy && mix qa && mix ci.security && mix format --check-formatted`; all commands must be green.
- **Max feedback latency:** 120 seconds for scoped checks; the full Docker/browser gate may take up to 600 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01-01 | 01 | 1 | KC-01 | T-70-01..05 | Tracer proves proxy-only topology, descriptor-derived audited trust, genuine signed ACS, receipt, and six-step Login Trace. | integration/E2E | `npm run demo:keycloak-proxy` | ❌ W0 | ⬜ pending |
| 70-02-01 | 02 | 2 | KC-01 | T-70-06..09 | Initial provisioning, unchanged-run idempotency, attribution, and fail-closed stages use the real Repo and audited seams. | ExUnit integration | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 70-02-02 | 02 | 2 | KC-01 | T-70-06..09 | Generated signing-key rotation replaces configured trust before re-enable and is idempotent afterward. | ExUnit integration | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 70-03-01 | 03 | 2 | KC-01 | T-70-10..14 | Default/override render checks prove one host input, no direct/management exposure, and no stale browser URLs. | integration/static | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | ❌ W0 | ⬜ pending |
| 70-03-02 | 03 | 2 | KC-01 | T-70-10..14 | Fresh realm lifecycle and diagnostic self-tests prove stale imports and sensitive artifacts cannot hide failures. | integration/static | `KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | ❌ W0 | ⬜ pending |
| 70-04-01 | 04 | 3 | KC-01 | T-70-15..18 | Conditional native Keycloak link appears only for the enabled stable connection and FakeIdP remains present. | Phoenix controller | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 70-04-02 | 04 | 3 | KC-01 | T-70-15..18 | Exact verified session-establishment receipt copy is derived from a durable LoginReceipt. | Phoenix controller | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 70-05-01 | 05 | 4 | KC-01 | T-70-19..23 | Browser begins at the semantic link, observes exact ACS POST, exact receipt, and correlation-specific successful trace. | Playwright E2E | `npm run demo:keycloak-proxy` | ❌ W0 | ⬜ pending |
| 70-05-02 | 05 | 4 | KC-01 | T-70-19..23 | FakeIdP success/tamper and permanent warnings/security/format gates remain independent. | regression | `cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — descriptor trust, audit co-commit, enable-last, identity, and idempotency coverage for KC-01.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` — conditional accessible Keycloak login affordance and exact verified-receipt copy.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` — durable receipt absent/present visibility and exact proof wording.
- [ ] `demo/ledger_loop/test/browser/keycloak.spec.ts` — replace the stale redirect-only spec with the public-host ACS/receipt/Login Trace journey.
- [ ] `scripts/test_keycloak_proxy_e2e.sh` and `package.json` command `demo:keycloak-proxy` — hermetic reset, Compose rendering, readiness, provisioning, browser run, diagnostics, and cleanup.

---

## Manual-Only Verifications

All phase behaviors have automated verification. A human may inspect captured Playwright artifacts after failure, but no success criterion depends on manual judgment.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 600s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** plan coverage approved; Wave 0 artifacts pending execution
