---
phase: 58
slug: brand-foundation-pressure-test-decision-lock
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-14
---

# Phase 58 — Validation Strategy

> Per-phase validation contract. This is a decision/doc phase; its "tests" are the WCAG contrast computations, which are committable and re-runnable.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Plain Elixir script (`elixir brandbook/notes/contrast.exs`) — stdlib only, no ExUnit for a doc phase |
| **Config file** | none — single self-contained `.exs` |
| **Quick run command** | `elixir brandbook/notes/contrast.exs` |
| **Full suite command** | `elixir brandbook/notes/contrast.exs` (prints every pair + pass/fail; exits non-zero if any must-pass pair is below its required ratio) |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `elixir brandbook/notes/contrast.exs`; confirm zero unremediated FAIL rows for intended uses.
- **After every plan wave:** Regenerate `accessibility-checks.md` from script output (no hand edits).
- **Before `/gsd:verify-work`:** Script exits 0 and every confirmed-failure pair is either remediated (new hex passes) or explicitly downgraded to a passing use, recorded in `decision-log.md`.
- **Max feedback latency:** ~1 second.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 0 | BRAND-02 | — | Every realistic pair (light+dark, text+non-text) computes a ratio + verdict | unit (math) | `elixir brandbook/notes/contrast.exs` | ❌ W0 (create `contrast.exs`) | ⬜ pending |
| 58-01-02 | 01 | 1 | BRAND-02 | — | Failing pairs have a remediation hex that passes its target use | unit (math) | `elixir brandbook/notes/contrast.exs` | ❌ W0 | ⬜ pending |
| 58-01-03 | 01 | 1 | BRAND-03 | — | Canonical lock set contains exactly one hex per role (no dupes) | manual review vs `decision-log.md` | n/a | ✅ doc review | ⬜ pending |
| 58-01-04 | 01 | 1 | BRAND-01 | — | Every finding has a disposition + confidence | manual review | n/a | ✅ doc review | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `brandbook/notes/contrast.exs` — implements WCAG 2.2 relative-luminance + contrast ratio, drives the pair list, and emits the `accessibility-checks.md` table (covers BRAND-02). Exit 1 if any must-pass pair is below its required ratio.
- [ ] No ExUnit/framework install needed — Elixir stdlib only.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Canonical lock set has exactly one definition per role | BRAND-03 | Token-sprawl resolution is editorial | Inspect `decision-log.md` "Canonical Lock Set" section — one hex per role, no competing alternatives |
| Every pressure-test finding has ship/reject/defer + confidence | BRAND-01 | Disposition is editorial judgment | Inspect `decision-log.md` — every finding block has a Disposition line |
| Red-team: no forbidden over-claims leak into any sample copy | BRAND-01 | Brand-as-security-discipline | Grep sample copy for "unhackable/bulletproof/military-grade/zero-risk/SAML is easy" — must be absent |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (doc-review tasks bracketed by script runs)
- [ ] Wave 0 covers the contrast script
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
