---
phase: 49
slug: adoption-honesty-conformance-jtbd-map-preset-taxonomy
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | mix.exs aliases `ci.conformance`, `ci.docs` |
| **Quick run command** | `mix test test/conformance/sp_conformance_test.exs --only conformance --warnings-as-errors` |
| **Full suite command** | `mix ci.conformance && mix ci.docs && mix test --warnings-as-errors` |
| **Estimated runtime** | ~60–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run task-level grep/`mix test` from plan verify steps
- **After every plan wave:** Run `mix ci.conformance` (plan 01) or `mix ci.docs` (plans 02–03)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | ADOPT-04 | T-49-01 | CONFORMANCE generated not hand-edited | unit | `mix relyra.conformance --check` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | ADOPT-04 | T-49-02 | ENC row executes positive control only | integration | `mix test test/conformance/sp_conformance_test.exs --only conformance` | ✅ | ⬜ pending |
| 49-01-03 | 01 | 1 | ADOPT-04 | — | Manifest summary counts pass 9 deferred 0 | grep | `grep "sp-encrypted-assertions-pass" priv/conformance/sp_manifest.json` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 1 | ADOPT-05 | — | jtbd_gap_map reflects v1.5 shipped state | grep | `grep "2026-05-27" docs/jtbd_gap_map.md` | ✅ | ⬜ pending |
| 49-03-01 | 03 | 1 | ADOPT-06 | — | Keycloak/OneLogin in decoder table | grep | `grep -i keycloak guides/recipes/generic_saml.md` | ✅ | ⬜ pending |
| 49-03-02 | 03 | 1 | ADOPT-06 | — | Getting Started lists 4 batteries-included | grep | `grep "ADFS" guides/getting_started.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs needed.

- [x] `test/conformance/sp_conformance_test.exs` — conformance manifest executor
- [x] `test/mix/tasks/relyra_conformance_test.exs` — generator drift gate
- [x] `mix ci.docs` presence guards for guide files

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
