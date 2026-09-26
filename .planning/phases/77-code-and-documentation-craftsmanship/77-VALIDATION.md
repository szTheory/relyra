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
| QUAL-02 | Bounded source/test comments retain contracts and remove temporary narration. | `mix test test/relyra/security/signature_crypto_test.exs --warnings-as-errors`; `mix ci.docs` | 77-01 T2, 77-02 T1–T2; docs and security tests | Non-zero exit, formatting drift, or a stale signature comment. |
| QUAL-03 | Security-sensitive cleanup preserves the independent security suites and adversarial XMLDSig corpus. | `mix ci.security` | 77-02 T1–T2 and 77-03 T3; `test/security/xml/adversarial_crypto_test.exs` and fresh-process security lane | Non-zero exit, changed crypto behavior, or any security suite failure. |
| QUAL-04 | Current source and adopter documentation satisfy timeless prose and active-phase acceptance contracts. | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors`; `mix ci.docs` | 77-01 T1–T2 and 77-02 T1; docs lane | Non-zero exit or a reported stale narration/policy violation. |
| QUAL-05 | Tracked artifacts satisfy the existing milestone-scope ownership contract. | `mix ci.evidence` | 77-03 T1 and T3; `test/governance/milestone_scope_test.exs` and evidence lane | Non-zero exit or an unexplained tracked path. |
| QUAL-06 | Baseline findings have current, evidence-backed dispositions; critical/high security proof remains intact. | `mix qa`; `mix ci.evidence`; `mix ci.security` | 77-03 T2–T3; baseline disposition validator and security lane | Non-zero exit, unresolved critical/high finding, or missing evidence/disposition. |

Each task's PLAN.md names its focused command; the map above assigns the requirement owner. Acceptance remains deterministic and automated.

---

## Wave 0 Requirements

Existing ExUnit infrastructure and the `ci.docs`, `ci.evidence`, and `ci.security` owners cover the phase. No new framework, package, or external service is required.

---

## Automated Acceptance Boundary

None. Acceptance evidence remains deterministic and automated; source review does not create a blocking human completion state.

---

## Validation Sign-Off

- [x] All plan tasks have a focused automated verify command or a documented Wave 0 dependency.
- [x] Sampling continuity: every task names an automated verification command.
- [x] Wave 0 covers the existing framework and lane references.
- [x] No watch-mode flags.
- [ ] Feedback latency stays within the focused-lane target.
- [ ] `nyquist_compliant: true` set after validation evidence passes.

**Approval:** pending automated evidence
