---
phase: 46
slug: adopter-dx-ergonomics
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` aliases |
| **Quick run command** | `mix test test/relyra/install/router_injector_test.exs --warnings-as-errors` |
| **Full suite command** | `mix ci.docs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run task-level `mix test` from plan verify step
- **After every plan wave:** Run `mix ci.docs`
- **Before `/gsd-verify-work`:** `mix test --warnings-as-errors` + `mix ci.docs` green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | DX-01 | — | N/A | grep | `grep apply_defaults README.md` | ✅ | ⬜ pending |
| 46-02-01 | 02 | 1 | DX-02 | — | No router corruption on ambiguous detect | unit | `mix test test/relyra/install/router_injector_test.exs` | ❌ W0 | ⬜ pending |
| 46-02-02 | 02 | 1 | DX-02 | — | Install injects on single router | integration | `mix test test/mix/relyra_install_test.exs` | ✅ | ⬜ pending |
| 46-03-01 | 03 | 1 | DX-03 | — | overview.md + ci.docs gate | file | `mix ci.docs` | ❌ W0 | ⬜ pending |
| 46-03-02 | 03 | 1 | DX-03 | — | batteries drift + ADFS scope | drift | `mix relyra.batteries_included --check` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs needed.

- [x] `test/mix/relyra_install_test.exs` — install integration baseline
- [x] `test/mix/tasks/relyra_batteries_included_test.exs` — generator drift gate
- [x] `mix ci.docs` — doc presence alias

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc extras navigation | DX-03 | Visual layout | Run `mix docs`, open index, confirm overview link works |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
