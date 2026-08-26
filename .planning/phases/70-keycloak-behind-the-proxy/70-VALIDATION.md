---
phase: 70
slug: keycloak-behind-the-proxy
status: draft
nyquist_compliant: false
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
| 70-01-01 | 01 | 1 | KC-01 | T-70-01 | Keycloak is proxy-only, advertises the fixed public hostname, trusts forwarded headers, and keeps management health private. | integration/static | `npm run demo:keycloak-proxy` | ❌ W0 | ⬜ pending |
| 70-01-02 | 01 | 1 | KC-01 | Realm client/entity, ACS, and redirect URLs contain only the browser-facing Relyra host for default and overridden `RELYRA_HOST`. | integration/static | `npm run demo:keycloak-proxy` | ❌ W0 | ⬜ pending |
| 70-01-03 | 01 | 1 | KC-01 | Descriptor-derived signing trust is persisted only through audited seams, the connection is enabled last, and repeated provisioning is idempotent. | ExUnit integration | `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 70-02-01 | 02 | 2 | KC-01 | The browser submits the genuine signed response to the exact public ACS; Relyra verifies it and records the mapped receipt and Login Trace. | Playwright E2E | `npm run demo:keycloak-proxy` | ❌ W0 | ⬜ pending |
| 70-02-02 | 02 | 2 | KC-01 | The FakeIdP success and tamper lane remains independent of the optional Keycloak profile. | regression | `cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — descriptor trust, audit co-commit, enable-last, identity, and idempotency coverage for KC-01.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` — conditional accessible Keycloak login affordance and exact verified-receipt copy.
- [ ] `demo/ledger_loop/test/browser/keycloak.spec.ts` — replace the stale redirect-only spec with the public-host ACS/receipt/Login Trace journey.
- [ ] `scripts/test_keycloak_proxy_e2e.sh` and `package.json` command `demo:keycloak-proxy` — hermetic reset, Compose rendering, readiness, provisioning, browser run, diagnostics, and cleanup.

---

## Manual-Only Verifications

All phase behaviors have automated verification. A human may inspect captured Playwright artifacts after failure, but no success criterion depends on manual judgment.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
