---
phase: "79"
slug: "adopter-ready-closeout"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | mix.exs; .github/workflows/security-gates.yml |
| **Quick run command** | mix ci.evidence |
| **Full suite command** | mix qa; mix test --warnings-as-errors; mix ci.security; mix format --check-formatted |
| **Estimated runtime** | Re-measure in the active Phase 79 CI run; not established by current Phase 78 evidence |

---

## Sampling Rate

- **After every task commit:** Run mix ci.evidence when changing governance, inventory, or evidence contracts.
- **After every plan wave:** Run mix ci.evidence and the wave's focused checks.
- **Before $gsd-verify-work:** Required CI on current main must be inspected against its live SHA; run the full required local suite for any source changes that the active plan sends toward main.
- **Max feedback latency:** Use the current CI measurement; no Phase 79 duration baseline exists yet.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | REPO-01 | — | Preserve user-owned paths; reject unexplained cleanup or clean-state claims | contract | mix ci.evidence | Existing owner: test/governance/milestone_scope_test.exs; inspect coverage | ⬜ pending |
| TBD | TBD | TBD | REPO-02 | — | Reject incomplete, stale, mismatched-SHA, or unredacted inventory evidence | contract | mix ci.evidence | Add only missing deterministic fixtures | ⬜ pending |
| TBD | TBD | TBD | REPO-03 | T-79-01 | Prevent mutation without one exact plan-local approval and matching read-back | governance contract | mix ci.evidence | Existing exact-batch owner: test/governance/milestone_scope_test.exs | ⬜ pending |
| TBD | TBD | TBD | EXIT-01 | — | Require evidence, owner, disposition, and revisit point for every residual risk | contract | mix ci.evidence | Inspect existing baseline validator and add only missing coverage | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Inspect current REPO-01/02/03 and EXIT-01 coverage in test/governance/milestone_scope_test.exs; add deterministic fixtures only for gaps in the chosen Phase 79 report contract.
- [ ] Keep new contract checks in the existing mandatory mix ci.evidence lane.
- [ ] Do not probe shared GitHub credentials or current state as part of local fixtures; refresh live state only through the active plan's read-only inventory task.

---

## Manual-Only Verifications

All phase acceptance behavior must have deterministic automated evidence. Live GitHub state is collected as timestamped external evidence during execution, not a manual-only acceptance test. The explicit approval checkpoint authorizes a proposed write; automated preflight and read-back establish mutation postconditions.

---

## Validation Sign-Off

- [ ] All tasks have automated verification or an explicit Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and below 30 seconds for focused checks
- [ ] nyquist_compliant: true set in frontmatter after validation

**Approval:** pending
