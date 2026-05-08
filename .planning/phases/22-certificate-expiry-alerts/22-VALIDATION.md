---
phase: 22
slug: certificate-expiry-alerts
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-07
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.x / OTP 27) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | CERT-EXP-01 | - | LogAlerts handler routes `[:relyra, :saml, :certificate, :expiring]` events correctly and applies redaction | unit | `mix test test/relyra/telemetry/handlers/log_alerts_test.exs` | ✅ | ⬜ pending |
| 22-01-02 | 01 | 1 | CERT-EXP-01 | T-22-01 | `check_all/2` queries active/next certs, emits telemetry, has Ecto optional-dep fallback | integration | `mix test test/relyra/security/certificate_expiry_test.exs` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `test/relyra/security/certificate_expiry_test.exs` — stub for `check_all/2` integration and fallback tests

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for `mix test --stale`
- [x] `nyquist_compliant: true` set in frontmatter
