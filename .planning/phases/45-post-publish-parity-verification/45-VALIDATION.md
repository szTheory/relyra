---
phase: 45
slug: post-publish-parity-verification
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) + Hex CLI + git + curl |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Live parity command** | `mix verify.release_parity 1.4.0` |
| **Milestone gate** | `.planning/phases/45-post-publish-parity-verification/verify-parity.sh` |
| **Estimated runtime** | Unit ~2s; live gate ~30–90s |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors`
- **After Plan 45-01:** Full unit suite for new test file
- **After Plan 45-02:** Run `verify-parity.sh` (network); confirm `PARITY-RESULT.md` **PASS**
- **Before `/gsd-verify-work`:** `PARITY-RESULT.md` contains `**PASS**`; script exit 0
- **Max feedback latency:** 120 seconds (unit); 300 seconds (live Hex fetch)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | PUB-04 | TM-01 | Version arg validated before subprocess | unit | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 45-01-02 | 01 | 1 | PUB-04 | TM-02 | `compute/2` pure path-set diff | unit | same | ❌ W0 | ⬜ pending |
| 45-01-03 | 01 | 1 | PUB-04 | TM-03 | test_support scan halts with exit 2 | unit | same | ❌ W0 | ⬜ pending |
| 45-01-04 | 01 | 1 | PUB-04 | — | Task module + shortdoc present | grep | `rg 'defmodule Mix.Tasks.Verify.ReleaseParity' lib/mix/tasks/verify.release_parity.ex` | ❌ W0 | ⬜ pending |
| 45-02-01 | 02 | 2 | PUB-04 | — | `verify-parity.sh` executable | file | `test -x .planning/phases/45-post-publish-parity-verification/verify-parity.sh` | ❌ W0 | ⬜ pending |
| 45-02-02 | 02 | 2 | PUB-04 | — | Live parity exit 0 | integration | `mix verify.release_parity 1.4.0; echo $?` → 0 | ❌ W0 | ⬜ pending |
| 45-02-03 | 02 | 2 | PUB-04 | PUB-04 SC#2 | PARITY-RESULT PASS line | file+rg | `rg '\*\*PASS\*\*' .planning/phases/45-post-publish-parity-verification/PARITY-RESULT.md` | ❌ W0 | ⬜ pending |
| 45-02-04 | 02 | 2 | PUB-04 | PUB-04 SC#4 | hex.audit + ci.release documented | grep | sections in PARITY-RESULT.md | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mix hex.package` available (Hex CLI)
- [x] Tag `v1.4.0` exists (Phase 44)
- [x] Hex lists `relyra 1.4.0` (Phase 44)
- [ ] `lib/mix/tasks/verify.release_parity.ex` — Plan 45-01
- [ ] `test/mix/tasks/verify_release_parity_test.exs` — Plan 45-01
- [ ] `verify-parity.sh` — Plan 45-02
- [ ] `PARITY-RESULT.md` — Plan 45-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone close | PUB-04 | Human runs GSD complete-milestone | Run only after PARITY-RESULT **PASS** |

*All technical gates have automated commands.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s for live gate
- [ ] `nyquist_compliant: true` set in frontmatter after Plan 45-02

**Approval:** pending
