---
phase: 72
slug: documentation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-27
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project-managed) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | Quick docs gate under 5 seconds; full suite measured during execution |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs/demo_guide_drift_test.exs test/docs/markdown_link_smoke_test.exs test/docs/adopter_voice_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix qa`, `mix ci.security`, `mix format --check-formatted`, and `mix test --warnings-as-errors` must be green
- **Max feedback latency:** 5 seconds for the focused docs gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | DOC-01 | T-72-01 | Guide preserves assertion-verification and host-owned session-receipt boundaries | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing file | ⬜ pending |
| 72-01-02 | 01 | 1 | DOC-01 | T-72-02 | Public browser origins remain distinct from Docker service DNS | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing file | ⬜ pending |
| 72-02-01 | 02 | 2 | DOC-02 | Router docs preserve the canonical Make-first path and Local Mix alternative | static contract | `mix test test/docs/demo_guide_drift_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ extend existing files | ⬜ pending |
| 72-02-02 | 02 | 2 | DOC-01, DOC-02 | Documentation retains house voice and valid local links | static contract | `mix test test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ existing files scan `guides/**/*.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/docs/demo_guide_drift_test.exs` with static assertions for the new guide's existence and content, canonical commands and origins, optional-path ordering, recovery vocabulary, receipt ownership, and all three router links.
- [ ] Keep `mix.exs` unchanged unless the plan establishes that ExDoc extras are documentation metadata rather than the explicitly excluded new Hex package surface; if included, update the published-extra link contract in `test/docs/markdown_link_smoke_test.exs` in the same task.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Live Docker/browser behavior is covered by the owned launcher and E2E harnesses from Phases 68–71; Phase 72 adds deterministic documentation contracts rather than a blocking manual gate.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Focused feedback latency remains under 5 seconds
- [ ] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
