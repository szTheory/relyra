---
phase: "73"
slug: "twin-contract-and-baseline"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-09"
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --warnings-as-errors` |
| **Full suite command** | `mix qa && mix ci.security` |
| **Estimated runtime** | ~30 seconds for focused checks; current `mix qa` baseline is 14.18 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused test file or `mix ci.evidence` once available
- **After every plan wave:** Run `mix ci.evidence && mix qa`
- **Before `$gsd-verify-work`:** Run `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, `mix format --check-formatted`, and `actionlint .github/workflows/*.yml`
- **Max feedback latency:** 30 seconds for focused checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 73-01-01 | 01 | 1 | EVID-01 | T-73-01 | Ledger rows cannot claim incomplete or ambiguous evidence ownership | unit/contract | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 73-01-02 | 01 | 1 | EVID-02 | Canary-only or hollow owners cannot close acceptance criteria | structural integration | `mix ci.evidence` | ✅ | ✅ green |
| 73-02-01 | 02 | 2 | QUAL-01 | Baseline findings retain severity, evidence, disposition, and target ownership | document contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 73-02-02 | 02 | 2 | PIPE-01 | CI baseline records ownership, timing, duplication, cache, and failure evidence | document contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 73-03-01 | 03 | 3 | GOV-01 | Risky changes require a named blocking checkpoint before mutation | plan policy contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 73-03-02 | 03 | 3 | GOV-02 | Plans cannot introduce `AUTHN-POST-01`, `KMS-01`, or `SIGNED-META-01` | plan scope contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 73-04-01 | 04 | 4 | EVID-02 | Commands, selectors, and required workflow steps fail closed under adversarial syntax and scope | structural integration | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | ✅ | ❌ red — 5 failures |
| 73-04-02 | 04 | 4 | EVID-02 | Every acceptance-bearing task has an executable non-zero owner | plan policy contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ❌ red — implementation gaps |
| 73-05-01 | 05 | 5 | GOV-01/GOV-02 | Closed task types, positive decisions, and actual governed surfaces cannot be bypassed | plan policy contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ❌ red |
| 73-05-02 | 05 | 5 | GOV-01 | Remote approval accepts only one exact reversible command batch | plan policy contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ❌ red |
| 73-05-03 | 05 | 5 | QUAL-01/GOV-02 | Provenance paths exist and demand-gated implementation regions remain excluded | document contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ✅ | ❌ red |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/adoption_evidence.ex` — literal evidence ledger and query helpers
- [x] `test/adoption/evidence_contract_test.exs` — schema, coverage, closure, owner, alias, and workflow wiring tests
- [x] `test/governance/milestone_scope_test.exs` — baseline, checkpoint, manual-gate, and deferred-scope policy tests
- [x] `mix.exs` — `ci.evidence` alias and preferred test environment
- [x] `.github/workflows/security-gates.yml` — uniquely named Evidence contract step
- [x] Negative fixtures for missing owner, canary-only owner, zero-match selector, unwired alias, missing checkpoint, and forbidden deferred ID

---

## Manual-Only Verifications

No manual-only substitution is permitted. The nine escalated gaps have deterministic RED tests and require implementation fixes before Phase 73 can close.

---

## Validation Sign-Off

- [ ] All tasks have passing `<automated>` verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30 seconds for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** blocked — Nyquist adversarial probes added on 2026-09-09 expose nine
implementation gaps across EVID-02, QUAL-01, GOV-01, and GOV-02. Focused results are
18 adoption-evidence tests with 5 failures and 34 governance tests with 6 failures.
The separate repository-wide documentation vocabulary failure remains owned by Phase 77.

## Validation Audit 2026-09-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Audit 2026-09-09 — Gap Closure Recheck

| Metric | Count |
|--------|-------|
| Gaps found | 9 |
| Resolved | 0 |
| Escalated | 9 |

The RED coverage is committed in `69aa4dd`. See `73-REVIEW.md` for CR-01 through
CR-09 and the exact implementation fixes required before re-running validation.
