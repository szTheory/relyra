---
phase: 16
slug: metadata-management-ui
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | MDUI-01 | T-16-01, T-16-02 | LiveView route handles auth and parameters correctly | unit | `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 16-02-01 | 02 | 2 | MDUI-01 | T-16-03 | Core Ecto validations handle input while routing updates | integration | `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 16-02-02 | 02 | 2 | MDUI-02 | none | History stream displays 10 recent revisions and identifies active state | integration | `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 16-03-01 | 03 | 3 | MDUI-02 | T-16-04 | Async task completes non-blocking refresh with explicit UI indicator for manual promotion | integration | `mix test test/phoenix/live_admin_metadata_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clear text indicator explaining manual promotion requirement | MDUI-02 | Visual confirmation needed for explanatory text | Navigate to `/connections/:connection_id/metadata`, verify the text "newly fetched trust material is not implicitly promoted" exists next to the "Refresh Metadata" button |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending