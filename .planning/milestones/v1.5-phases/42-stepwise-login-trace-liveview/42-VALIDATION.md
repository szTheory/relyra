---
phase: 42
slug: stepwise-login-trace-liveview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/relyra/telemetry/handlers/login_trace_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Security lane** | `mix ci.security` (includes dedicated `login_trace_test.exs` cmd) |
| **Estimated runtime** | ~30–90 seconds per focused file |

---

## Sampling Rate

- **After every task commit:** Run the plan's `<verify>` command
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** `mix ci.security` exit 0
- **Max feedback latency:** 120 seconds (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| T-42-01-a | 01 | 1 | TRACE-01 (data) | TM-01 | Login audit rows append-only, no sensitive keys in `after_summary` | unit | `mix test test/relyra/telemetry/handlers/login_trace_test.exs` | planned | pending |
| T-42-02-a | 02 | 2 | TRACE-03 | TM-02 | Export hashes correlation_id; strips XML/PEM | unit | `mix test test/relyra/login_trace/export_test.exs` | planned | pending |
| T-42-03-a | 03 | 3 | TRACE-01 | TM-03 | LiveView renders steps, no forbidden substrings | liveview | `mix test test/relyra/live_admin/phase15_ui_contract_test.exs` | yes | pending |
| T-42-04-a | 04 | 3 | TRACE-02 | TM-01..03 | Security corpus gates LiveView + CLI | security | `mix test test/security/login_trace_test.exs` | planned | pending |
| T-42-04-b | 04 | 3 | TRACE-02 | TM-04 | `ci.security` hollow-gate lists suite | meta | `mix test test/security/ci_gate_integrity_test.exs` | yes | pending |

---

## Wave Gates

| Wave | Gate command | Must pass before |
|------|--------------|------------------|
| 1 | `mix test test/relyra/telemetry/handlers/login_trace_test.exs --warnings-as-errors` | Wave 2 |
| 2 | `mix test test/relyra/login_trace/ --warnings-as-errors` | Wave 3 |
| 3 | `mix ci.security` | Phase verify |

---

## Nyquist Notes

Dimension 8 (validation requirements in plans) satisfied via explicit `acceptance_criteria` on each task referencing grep-able strings and test file paths.
