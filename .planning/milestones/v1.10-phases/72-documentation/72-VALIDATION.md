---
phase: 72
slug: documentation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-27
validated: 2026-08-27
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
| 72-01-01 | 01 | 1 | DOC-01 | T-72-01 | Guide preserves assertion-verification and host-owned session-receipt boundaries | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |
| 72-01-02 | 01 | 1 | DOC-01 | T-72-02, T-72-03 | Public origins, Docker service DNS, cache behavior, and destructive recovery remain exact | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |
| 72-02-01 | 02 | 2 | DOC-02 | T-72-04 | Evaluator docs preserve the Make-first path, Local Mix, and host-owned receipt boundary | static contract | `mix test test/docs/demo_guide_drift_test.exs test/docs/adopter_voice_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |
| 72-02-02 | 02 | 2 | DOC-02 | T-72-05, T-72-06 | Published and repository routers retain valid links, Day-1 order, and package boundaries | static contract | `mix test test/docs/demo_guide_drift_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ docs contract files | ✅ green |
| 72-03-01 | 03 | 3 | DOC-01 | T-72-07..T-72-10 | Public Keycloak launcher uses the Fleet graph, waits for provisioning, validates the descriptor, and fails closed | owned CLI fixture | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |
| 72-04-01 | 04 | 4 | DOC-01, DOC-02 | T-72-11, T-72-13 | Evaluator narrative matches Sarah's real signed FakeIdP flow and persisted LoginReceipt | static + integration | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors && (cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs:63 --warnings-as-errors)` | ✅ root and demo tests | ✅ green |
| 72-04-02 | 04 | 4 | DOC-01, DOC-02 | T-72-12, T-72-14 | Both Keycloak follow-ons use the executable public target without leaking proof material | static contract | `mix test test/docs/demo_guide_drift_test.exs test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ docs contract files | ✅ green |
| 72-05-01 | 05 | 5 | DOC-01, DOC-02 | T-72-15..T-72-18 | Configured Solo port flows through doctor, URL output, launch guidance, and browser navigation | owned CLI fixture | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |
| 72-05-02 | 05 | 5 | DOC-01, DOC-02 | T-72-19 | Ordered documentation assertions advance monotonically across repeated tokens | unit regression | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ `test/docs/demo_guide_drift_test.exs` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Extended `test/docs/demo_guide_drift_test.exs` with static assertions for the guide's existence and content, canonical commands and origins, optional-path ordering, recovery vocabulary, receipt ownership, all three router links, launcher behavior, configured ports, and ordered-token behavior.
- [x] Asserted deterministically that `mix.exs` and its ExDoc extras remain unchanged, and that the published `guides/demo.md` router uses and tests the absolute canonical repository URL `https://github.com/szTheory/relyra/blob/main/guides/docker_dev_dx.md`.

---

## Automated Verification Coverage

All phase behaviors have automated verification. Live Docker/browser behavior is covered by the owned launcher and E2E harnesses from Phases 68–71; Phase 72 adds deterministic documentation contracts with no blocking human acceptance state.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Focused feedback latency remains under 5 seconds
- [x] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** validated 2026-08-27 — DOC-01 and DOC-02 have deterministic automated coverage; no manual-only items.

## Validation Audit 2026-08-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Focused evidence rerun during audit:

- `mix test test/docs/demo_guide_drift_test.exs test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` — 30 tests, 0 failures.
- `cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs:63 --warnings-as-errors` — 1 test, 0 failures.
