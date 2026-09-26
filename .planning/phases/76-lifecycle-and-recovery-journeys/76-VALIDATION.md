---
phase: "76"
slug: "lifecycle-and-recovery-journeys"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-26"
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.ConnTest / LiveViewTest; Playwright Test where browser behavior is acceptance-relevant |
| **Config file** | `demo/ledger_loop/mix.exs`; `playwright.fake-idp.config.mjs`; `playwright.trace-visual.config.mjs` |
| **Quick run command** | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/lifecycle_journeys_test.exs` |
| **Full suite commands** | `mix ci.demo_app`; `mix ci.evidence`; `npm run demo:trace-visual` |
| **Estimated runtime** | Measure during execution; no stable phase-specific baseline is available |

## Sampling Rate

- **After every task commit:** Run the focused LedgerLoop test for the changed journey.
- **After every plan wave:** Run `mix ci.demo_app` and any browser lane owned by that wave.
- **Before `$gsd-verify-work`:** Run `mix qa`, `mix ci.security`, `mix format --check-formatted`, `mix ci.demo_app`, and required deterministic browser checks.
- **Max feedback latency:** Keep focused test commands under 30 seconds where practical; report measured duration if exceeded.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-01 Task 1 | 76-01 | 1 | JOUR-01 | T-76-01 | Verified SP response establishes the mapped Northstar receipt, tenant, role and configured adapter effects together | endpoint integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/lifecycle_journeys_test.exs` | ❌ W0 | ⬜ pending |
| 76-01 Task 2 | 76-01 | 1 | JOUR-03 | T-76-02 | Reposting the accepted assertion yields typed replay rejection without a second host session effect | endpoint/replay integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/lifecycle_journeys_test.exs` | ❌ W0 | ⬜ pending |
| 76-02 Task 1 | 76-02 | 2 | JOUR-02 | T-76-03 | Seven invalid response classes yield exact typed rejections and no adopter-owned success state | endpoint/security integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/rejection_journeys_test.exs` | ❌ W0 | ⬜ pending |
| 76-02 Task 2 | 76-02 | 2 | JOUR-04 | T-76-04, T-76-05 | Paired tenant routes preserve resolver, mapping, replay, receipt, trace, audit and authorization isolation | endpoint/database integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/tenant_journeys_test.exs`<br>`mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 76-03 Task 1 | 76-03 | 1 | JOUR-05 | T-76-06, T-76-07 | Owning admin LiveView import and enablement persist scoped trust and redacted audit; invalid/foreign attempts preserve state | LiveView/domain integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/trust_lifecycle_live_test.exs` | ❌ W0 | ⬜ pending |
| 76-03 Task 2 | 76-03 | 1 | JOUR-05 | T-76-07, T-76-08 | Staging, activation and recovery co-commit audit; injected failure rolls back both trust and audit | domain/database integration | `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/trust_lifecycle_test.exs`<br>`mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 76-04 Task 1 | 76-04 | 2 | JOUR-06 | T-76-09, T-76-10 | Seeded failed login, redacted diagnosis, audited repair and verified retry share scoped evidence | endpoint/database integration | `mix cmd --cd demo/ledger_loop mix test test/twin/incident_recovery_test.exs`<br>`mix cmd --cd demo/ledger_loop mix test test/twin/incident_timeline_test.exs` | ❌ W0; existing timeline analog | ⬜ pending |
| 76-04 Task 2 | 76-04 | 2 | JOUR-06 | T-76-11 | Supported browser trace journey retains only safe status with owner and recovery command | browser/workflow integration | `npm run demo:trace-visual` | ✅ existing files; new evidence pending | ⬜ pending |
| 76-05 Task 1 | 76-05 | 3 | EVID-03 | T-76-12, T-76-13 | Independent scheduled canary fails visibly on missing configuration or provider failure with allowlisted status | shell/browser contract | `bash -n scripts/test_real_idp_canary.sh`<br>`bash scripts/test_real_idp_canary.sh --contract-probe` | ❌ W0 | ⬜ pending |
| 76-05 Task 2 | 76-05 | 3 | EVID-03 | T-76-13, T-76-14 | Mandatory evidence contract rejects merge coupling, unsafe artifacts and false green configuration status | evidence contract | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors`<br>`mix ci.evidence` | ❌ W0; existing owner files | ⬜ pending |

## Wave 0 Requirements

- [ ] Add LedgerLoop route-level typed rejection and no-session coverage for the representative invalid response matrix.
- [ ] Prove accepted-response replay through the configured ACS route and replay adapter.
- [ ] Add paired tenant outcomes spanning configured behavior seams and authorization.
- [ ] Connect organization-scoped admin trust lifecycle operations to audit co-commit and rollback evidence.
- [ ] Prove incident retry/recovery using correlated redacted trace and audit exports.
- [ ] Define the provider-agnostic scheduled canary contract: require eventual named provider and operational owner configuration, safe artifact allowlist/retention, and recovery action; fail visibly while configuration is absent and keep it separate from merge gates.
- [ ] Wire deterministic acceptance into its existing mandatory CI owner.

## Manual-Only Verifications

All phase acceptance behaviors must have deterministic automated evidence. Live-provider availability is a scheduled canary signal with safe failure ownership; it is not a human completion gate.

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and reported
- [ ] `nyquist_compliant: true` set in frontmatter after evidence is green

**Approval:** pending
