---
phase: "77"
slug: "code-and-documentation-craftsmanship"
status: draft
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-26"
---

# Phase 77 — Validation Strategy

> Feedback-sampling plan for code and documentation craftsmanship. Plan/task ownership is assigned in the PLAN.md files.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, bundled with Elixir (`~> 1.19`) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | Not measured during planning; use the focused owner lane per task |

---

## Sampling Rate

- **After each task commit:** Run the narrow command owned by that task from the requirement map below.
- **After each plan wave:** Run `mix ci.docs` and `mix ci.evidence`; run `mix ci.security` if the wave changes security-adjacent code or tests.
- **Before phase verification:** Run `mix qa`, `mix test --warnings-as-errors`, `mix format --check-formatted`, and `mix ci.security`.
- **Max feedback latency:** 30 seconds for the focused documentation test; broader lanes are wave/final checks.

---

## Requirement Verification Map

| Requirement | Behavior | Automated command | Evidence owner | Failure signal |
|-------------|----------|-------------------|----------------|----------------|
| QUAL-02 | Code/test changes compile cleanly and preserve the focused project quality checks. | `mix qa` and `mix format --check-formatted` | Root QA and formatter | Non-zero exit or formatter reports unformatted files. |
| QUAL-03 | Security-sensitive cleanup preserves the independent security suites and adversarial XMLDSig corpus. | `mix ci.security` | `test/security/xml/adversarial_crypto_test.exs` and fresh-process security lane | Non-zero exit or any security suite reports a failing test. |
| QUAL-04 | Current source and adopter documentation satisfy the timeless-prose and active-phase acceptance contracts. | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors`; `mix ci.docs` | `test/docs/demo_guide_drift_test.exs` and docs lane | Non-zero exit or a reported stale narration/policy violation. |
| QUAL-05 | Tracked artifacts satisfy the existing milestone-scope ownership contract. | `mix ci.evidence` | `test/governance/milestone_scope_test.exs` and evidence lane | Non-zero exit or an unexplained tracked path. |
| QUAL-06 | Baseline findings have current, evidence-backed dispositions; critical/high security proof remains intact. | `mix ci.evidence`; `mix ci.security` for security findings | Baseline disposition validator and security lane | Non-zero exit, unresolved critical/high finding, or missing evidence/disposition. |

Plan task IDs and focused commands should be added to this map when plans assign each requirement to its owning task. Avoid creating manual-only or human-needed completion gates.

---

## Wave 0 Requirements

Existing ExUnit infrastructure and the `ci.docs`, `ci.evidence`, and `ci.security` owners cover the phase. No new framework, package, or external service is required.

---

## Manual-Only Verifications

None. Acceptance evidence remains deterministic and automated; source review does not create a blocking human completion state.

---

## Validation Sign-Off

- [ ] All plan tasks have a focused automated verify command or a documented Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers the existing framework and lane references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within the focused-lane target.
- [ ] `nyquist_compliant: true` set after validation evidence passes.

**Approval:** pending automated evidence
