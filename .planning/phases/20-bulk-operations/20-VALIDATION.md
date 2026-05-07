---
phase: 20
slug: bulk-operations
status: draft
nyquist_compliant: true
wave_2_complete: true
created: 2026-05-07
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir/OTP) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test --warnings-as-errors` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --warnings-as-errors`
- **After every plan wave:** Run `mix qa`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | CFG-07 | n/a | BulkActions coordinator shares correlation ID and returns map of results | unit | `mix test test/relyra/ecto/bulk_actions_test.exs` | ✅ W1 | ✅ green |
| 20-02-01 | 02 | 2 | CFG-07 | n/a | LiveAdmin connections list supports multi-select UI | integration | `mix test test/phoenix/live_admin_bulk_test.exs` | ✅ W2 | ✅ green |
| 20-02-02 | 02 | 2 | CFG-07 | n/a | LiveAdmin bulk action triggers coordination with shared feedback | integration | `mix test test/phoenix/live_admin_bulk_test.exs` | ✅ W2 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave Requirements

- [x] `test/relyra/ecto/bulk_actions_test.exs`
- [x] `test/phoenix/live_admin_bulk_test.exs`

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved