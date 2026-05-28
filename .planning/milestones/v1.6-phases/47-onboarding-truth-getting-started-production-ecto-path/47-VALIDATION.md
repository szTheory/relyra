---
phase: 47
slug: onboarding-truth-getting-started-production-ecto-path
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
retroactive: true
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Retroactively backfilled from `47-VERIFICATION.md` and plan verify blocks (Phase 49.2).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` (`ci.docs`, test_support_demo_test.exs) |
| **Quick run command** | Per-task grep from plan verify blocks |
| **Full suite command** | `mix ci.docs && mix test test/test_support_demo_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `<verify>` grep commands
- **After every plan wave:** Run `mix ci.docs`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | ADOPT-01 | grep | `grep -n "setup_saml_connection\|post_saml_response\|test_support_demo_test" guides/getting_started.md` | ✅ | ✅ green |
| 47-01-02 | 01 | 1 | ADOPT-01 | grep | `grep -n "Appendix: Advanced manual response construction" guides/getting_started.md && grep -c "build_saml_response" guides/getting_started.md` | ✅ | ✅ green |
| 47-01-03 | 01 | 1 | ADOPT-01 | grep | `grep "setup_saml_connection" guides/overview.md && grep "Getting Started §3\|getting_started.md#3" guides/overview.md` | ✅ | ✅ green |
| 47-02-01 | 02 | 1 | ADOPT-02 | file | `test -f guides/production_ecto_path.md && head -5 guides/production_ecto_path.md` | ✅ | ✅ green |
| 47-02-02 | 02 | 1 | ADOPT-02 | grep | `grep "Application.app_dir(:relyra" guides/production_ecto_path.md && grep "Ecto.Migrator.run" guides/production_ecto_path.md` | ✅ | ✅ green |
| 47-02-03 | 02 | 1 | ADOPT-02 | grep | `grep "relay_state\|replay_key\|opts\\[:table\\]" guides/production_ecto_path.md` | ✅ | ✅ green |
| 47-02-04 | 02 | 1 | ADOPT-02 | grep | `grep "prod_runtime_ets_warning\|ConnectionResolver.Ecto\|single-node only" guides/production_ecto_path.md` | ✅ | ✅ green |
| 47-03-01 | 03 | 1 | ADOPT-01/02 | grep | `grep "production_ecto_path.md" guides/getting_started.md` | ✅ | ✅ green |
| 47-03-02 | 03 | 1 | ADOPT-02 | grep | `grep "production_ecto_path.md" guides/overview.md` | ✅ | ✅ green |
| 47-03-03 | 03 | 1 | ADOPT-02 | integration | `mix ci.docs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 test stubs needed.

- [x] `mix ci.docs` presence gate on guide files
- [x] `test/test_support_demo_test.exs` — TestSupport macro round-trip demo
- [x] ExDoc extras gate in `mix ci.docs`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-27 (retroactive backfill per Phase 49.2)
