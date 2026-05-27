---
phase: 39
slug: logout-strategy-and-operational-guidance
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a documentation-only phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `rg`, Mix aliases, ExDoc config checks |
| **Quick run command** | `rg -n 'ITP|ETP|Privacy Sandbox' guides/recipes/logout.md` |
| **Full suite command** | `mix ci.docs && mix test --warnings-as-errors` |
| **Estimated runtime** | quick < 5s; full suite depends on test lane runtime |

---

## Sampling Rate

- **After every task commit:** run the task-local `rg` checks from the owning plan.
- **After every plan wave:** run the relevant docs publication/gate checks plus the quick guide-content grep.
- **Before `/gsd:verify-work`:** `mix ci.docs && mix test --warnings-as-errors` must be green.
- **Max feedback latency:** quick content and config checks should stay under a few seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-T1 | 01 | 1 | DOCS-04 | T-39-01 / T-39-02 | Core guide exists with required sections on ITP/ETP, Stateful Sessions, Session Index, and Absolute Timeouts. | docs grep | `rg -n 'ITP|ETP|SessionAdapter' guides/recipes/logout.md` | ⬜ new | ⬜ pending |
| 39-T2 | 01 | 1 | DOCS-04 | T-39-01 | Guide is published in ExDoc extras and fail-closed in `ci.docs` | config | `rg -n 'guides/recipes/logout\\.md' mix.exs && mix ci.docs` | ✅ extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide prose matches operational reality | DOCS-04 | Automated checks verify keywords, not the assertive tone regarding SLO failures. | Read the guide and confirm it assertively demotes front-channel SLO and mandates absolute timeouts and stateful sessions. |

---

## Validation Sign-Off

- [x] All planned tasks have automated verification steps
- [x] Sampling continuity: no plan wave is left without automated feedback
- [x] No watch-mode or interactive-only verification
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] Execution evidence still pending
