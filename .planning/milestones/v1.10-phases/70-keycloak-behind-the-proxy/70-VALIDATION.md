---
phase: 70
slug: keycloak-behind-the-proxy
status: validated
nyquist_compliant: true
wave_0_complete: true
updated: 2026-08-26
---

# Phase 70 — Validation Strategy

All fourteen plans now have an executable behavioral check. The formerly manual UAT backstops are covered by the deterministic `demo:trace-visual` Chromium lane; no phase-success criterion requires human verification.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit/Mix, host-side Playwright, Docker Compose, GitHub Actions |
| Focused real-IdP command | `npm run demo:keycloak-proxy` |
| Focused failure/visual command | `npm run demo:trace-visual` |
| Repository security owner | `mix ci.security` via `security-gates.yml` |
| Recurring CI | `keycloak-proxy-e2e.yml` and `demo-app-e2e.yml` |

## Per-Plan Verification Map

| Plan | Requirement / behavior | Test type | Executable command | Evidence | Status |
|---|---|---|---|---|---|
| 70-01 | Proxy-only Keycloak, audited descriptor trust, signed scoped ACS, receipt, canonical trace | Docker/Chromium E2E | `npm run demo:keycloak-proxy` | `scripts/test_keycloak_proxy_e2e.sh`, `keycloak.spec.ts` | green |
| 70-02 | Initial provision, unchanged retry, rotation, fail-closed behavior, audit co-commit | ExUnit integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` | `keycloak_provisioner_test.exs` | green |
| 70-03 | Default/override proxy topology, fresh realm, diagnostic layer/redaction | integration/static | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | `test_keycloak_proxy_e2e.sh` | green |
| 70-04 | Conditional Keycloak affordance and durable receipt copy | Phoenix integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/controllers/page_controller_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` | controller tests | green |
| 70-05 | Public-host browser journey and FakeIdP success/tamper regression | Chromium E2E | `npm run demo:keycloak-proxy && npm run demo:fake-idp` | `keycloak.spec.ts`, `fake_idp.spec.ts` | green |
| 70-06 | One guarded metadata parse, audited persistence, rotation and failure closure | ExUnit/security | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors && mix ci.security` | provisioner tests, security suites | green |
| 70-07 | Attachment-free Keycloak evidence and fail-closed diagnostics retention | smoke/static | `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` | artifact-policy self-test | green |
| 70-08 | Runtime-only host-admin boundary and authenticated trace transition | Phoenix integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/controllers/route_affordance_controller_test.exs test/ledger_loop_web/router_test.exs --warnings-as-errors` | route/controller tests | green |
| 70-09 | Identity/mapping audit transaction and retry without residue | ExUnit integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` | provisioner tests | green |
| 70-10 | Qualified XML diagnostic redaction and incomplete admin-config denial | smoke/integration | `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh && mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/router_test.exs --warnings-as-errors` | self-test, router tests | green |
| 70-11 / G-70-1 | Focused Keycloak command and recurring artifact-free CI | Docker/Chromium E2E + CI | `npm run demo:keycloak-proxy` | `keycloak-proxy-e2e.yml` | green |
| 70-12 / G-70-1 | Patched Req/Finch/Mint graph and repository security/quality gates | dependency/regression | `mix test --warnings-as-errors && mix qa && mix ci.security && mix format --check-formatted` | `mix.lock`, security workflow | green |
| 70-13 / G-70-2 | Safe opt-in long fixture and labelled focusable evidence region | ExUnit integration/render | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/reset_test.exs --warnings-as-errors && mix test test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors` | reset and render-contract tests | green |
| 70-14 / G-70-2 | Tampered ACS, receipt absence, Back recovery, keyboard, narrow evidence, long values, output cleanup and CI | Chromium E2E + CI | `npm run demo:trace-visual` | `trace_visual.spec.ts`, `demo-app-e2e.yml` | green |

## Fresh Nyquist Run — 2026-08-26

- Keycloak artifact-policy and static topology self-tests passed.
- Focused demo integration suite: 31 tests, 0 failures.
- LiveAdmin render contract: 6 tests, 0 failures; admin router boundary: 2 tests, 0 failures.
- `npm run demo:fake-idp`: 2 Chromium tests passed.
- `npm run demo:trace-visual -- --list`: exactly one owned Chromium test discovered.
- `npm run demo:trace-visual`: 1 Chromium test passed and its private output directory was removed on exit.
- `npm run demo:keycloak-proxy`: the owned public Keycloak Docker/Chromium/ACS/receipt/canonical-trace behavior ran without a behavioral failure.
- `mix format --check-formatted`: passed.

## Recurring Automation

- Keycloak’s 30-minute Docker/Chromium proof runs on pull requests, `main`, a daily schedule, and manual dispatch in `keycloak-proxy-e2e.yml`.
- The deterministic failure/visual proof runs after FakeIdP in `demo-app-e2e.yml` on pull requests and `main`.
- Repository-wide dependency and crypto gates remain separate under `security-gates.yml`; the focused scenario command does not hide their status.

## Validation Sign-Off

- [x] All 14 plans have runnable automated verification.
- [x] G-70-1 has a focused behavior gate and separate recurring security ownership.
- [x] G-70-2 has automated failed-state, recovery, keyboard, narrow-viewport, long-value, and credential-output lifecycle coverage.
- [x] No manual-only success criterion remains.
- [x] No implementation file was modified by this audit.
