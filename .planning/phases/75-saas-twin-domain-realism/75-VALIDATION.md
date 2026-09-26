---
phase: "75"
slug: "saas-twin-domain-realism"
status: complete
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox |
| **Config file** | `demo/ledger_loop/config/test.exs`; `demo/ledger_loop/test/support/data_case.ex` |
| **Quick run command** | `mix cmd --cd demo/ledger_loop mix test test/twin/reset_test.exs` |
| **Full suite command** | `mix ci.demo_app` |
| **Estimated runtime** | Under 30 seconds for focused tests; full alias includes dependency/setup steps |

---

## Sampling Rate

- **After every task commit:** Run the focused test selector for the changed scenario file
- **After every plan wave:** Run `mix ci.demo_app`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for focused tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-01-01 | TBD | 1 | TWIN-01 | — | Tenant, user, group, membership, identity, and authorization facts remain tenant-consistent | integration | `mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 75-01-02 | TBD | 1 | TWIN-02 | T-75-01 | Provider and connection scenario data cannot cross tenants | integration | `mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 75-01-03 | TBD | 1 | TWIN-03 | — | Trust health remains distinct from certificate lifecycle and history stays ordered | integration | `mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 75-01-04 | TBD | 1 | TWIN-04 | T-75-02 | Incident evidence is ordered, correlated, and redacted | integration | `mix ci.demo_app` | ❌ W0 | ⬜ pending |
| 75-01-05 | TBD | 1 | TWIN-05 | T-75-02 | Reset preserves non-fixture sentinel rows and recreates deterministic redaction-safe scenarios | integration | `mix ci.demo_app` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `demo/ledger_loop/test/twin/organization_test.exs` — TWIN-01 tenant identity and authorization contracts
- [ ] `demo/ledger_loop/test/twin/provider_test.exs` — TWIN-02 tenant-linked provider and connection scenarios
- [ ] `demo/ledger_loop/test/twin/certificate_history_test.exs` — TWIN-03 trust chronology contract
- [ ] `demo/ledger_loop/test/twin/incident_timeline_test.exs` — TWIN-04 trace/audit incident evidence
- [ ] `demo/ledger_loop/test/twin/reset_test.exs` — TWIN-05 deterministic reset, isolation, and redaction contracts

---

## Automated Acceptance

All five phase requirements have deterministic ExUnit evidence in the `mix ci.demo_app` lane. No manual-only verification is required.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused tests
- [x] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** automated evidence recorded
