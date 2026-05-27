---
phase: 43
slug: hex-publish-prep-version-bump-changelog-backfill
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/release/release_hardening_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~2–5 min full suite; <1s release hardening |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/release/release_hardening_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | PUB-01 | — | Version sources agree at 1.4.0 | grep + unit | `grep '@version "1.4.0"' mix.exs && grep '"1.4.0"' .release-please-manifest.json` | ✅ | ⬜ pending |
| 43-01-02 | 01 | 1 | PUB-01 | — | Install pin updated to ~> 1.4 | grep | `grep '~> 1.4' guides/getting_started.md` | ✅ | ⬜ pending |
| 43-01-03 | 01 | 1 | PUB-02 | — | CHANGELOG sections present with Keep-a-Changelog headings | grep + release | `grep '## \[1.3.0\]' CHANGELOG.md && grep '## \[1.4.0\]' CHANGELOG.md && mix ci.release` | ✅ | ⬜ pending |
| 43-01-04 | 01 | 1 | PUB-01/PUB-02 | — | Unreleased section preserved | unit | `mix test test/release/release_hardening_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 43-01-05 | 01 | 1 | PUB-01/PUB-02 | — | Full suite green after bump | integration | `mix test --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs needed.

- [x] `test/release/release_hardening_test.exs` — `[Unreleased]` and release artifact guards
- [x] `mix ci.release` — release discipline lane
- [x] ExUnit via Mix — full test suite

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CHANGELOG prose quality | PUB-02 | Milestone narrative bullets require human review | Verify [1.3.0] covers ENC-01, AUTHN-01, DOCS-02/03; [1.4.0] covers SLO-01, DOCS-04/05/06, trace UI, hygiene; jump rationale at top of [1.4.0] |
| Single-jump rationale clarity | PUB-01 | Prose acceptance | Read [1.4.0] opening paragraph — explains no intermediate 1.3.0 Hex release |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
