---
phase: 3
slug: behaviour-contracts-and-stores
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | EXT-01, EXT-05 | T-03-API-STABILITY | Five public behaviour modules remain stable while default adapters stay internal | unit | `mix test test/relyra_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 1 | EXT-02, EXT-03 | T-03-ATOMIC-STORES | Request/replay stores enforce one-time semantics with production-safe defaults | integration | `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 03-03-01 | 03 | 2 | PROT-04, SEC-06, EXT-04 | T-03-CORRELATION-REPLAY | InResponseTo and replay checks are enforced through consume flow without protocol-core coupling | integration | `mix test test/protocol --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Production warning messaging for ETS adapters | EXT-02 | Needs explicit `MIX_ENV=prod` runtime path assertion and operator-readable warning validation | Run adapter path in `MIX_ENV=prod`, assert warning text includes single-node and durability limitations |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
