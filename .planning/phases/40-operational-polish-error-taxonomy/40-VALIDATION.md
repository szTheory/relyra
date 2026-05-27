---
phase: 40
slug: operational-polish-error-taxonomy
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Authoritative inputs from `40-RESEARCH.md` "Validation Architecture" section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (OTP-bundled with Elixir 1.19) |
| **Config file** | `test/test_helper.exs` (already present) |
| **Quick run command** | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` |
| **Full suite command** | `mix qa` (alias: `format --check-formatted` + `compile --warnings-as-errors` + `test --warnings-as-errors`) |
| **Docs lane command** | `mix ci.docs` (presence guards + drift test + existing docs gates) |
| **Estimated runtime** | <5 seconds for drift test; ~60-90s for `mix qa` full suite |

---

## Sampling Rate

- **After every task commit:** `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` (the canonical guard whenever a task adds/renames an atom under `lib/` or edits `guides/troubleshooting.md`)
- **After every plan wave:** `mix ci.docs` (presence guards + drift test + existing docs gates)
- **Before `/gsd:verify-work`:** `mix qa && mix ci.docs && mix ci.security` all green (ci.security must remain green per Phase 30 invariant even though Phase 40 does not touch it)
- **Max feedback latency:** <5s for the drift test (single ExUnit module, regex scan of `lib/` + one file read)

---

## Per-Task Verification Map

> The planner fills this table from the PLAN.md tasks it authors. Each row maps a plan task to its automated verifier.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated by planner_ | | | | | | | | | |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The drift-check test is the central gate for DOCS-06. Wave 0 deliverables (referenced by later waves):

- [ ] `test/docs/` directory — create (green-field).
- [ ] `test/docs/troubleshooting_drift_test.exs` — written first as a **failing** test, then `guides/troubleshooting.md` is authored until the test goes green (assertion-by-test pattern mirroring `test/security/strict_default_proof_test.exs`).
- [ ] `guides/operations/` directory — create when adding `incident_playbook.md`.
- [ ] No framework install needed; ExUnit is OTP-bundled.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Narrative correctness of the five-surface reference table (telemetry, audit, LiveAdmin routes, Mix tasks, troubleshooting cross-link) and the six scenario runbooks (cert expiry, metadata drift, replay storm, signature regression, ACS misconfig, attribute mapping) | DOCS-05 | Narrative quality is reviewer-judged, not assertion-checkable | Operator review during `/gsd:verify-work`: confirm each surface in the table cites the exact file/route/event from canonical sources (`lib/relyra/telemetry.ex`, `lib/relyra/ecto/audit_event.ex`, `lib/relyra/live_admin/router.ex`, `lib/mix/tasks/relyra.*.ex`) and that the six scenarios follow Triage → Diagnose → Recover with cross-refs back to the reference table |
| Trust-boundary preamble + brand-voice closing in both new guides match the Phase 36/39 idiom | DOCS-05, DOCS-06 | Style adherence is reviewer-judged | Manual diff against `guides/recipes/generic_saml.md` and `guides/recipes/logout.md` preambles + closings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (drift test file + guide files + new dirs)
- [ ] No watch-mode flags in any command
- [ ] Feedback latency <5s for drift test, <90s for full `mix qa`
- [ ] `nyquist_compliant: true` set in frontmatter after planner populates the per-task map

**Approval:** pending
