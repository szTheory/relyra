---
phase: 26
slug: security-audit-preparation-and-remediation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for audit-packet preparation, executable evidence, and remediation gating.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.19.5 with Mix aliases and generated-doc drift checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix relyra.security_review --check` |
| **Full phase gate** | `mix ci.security` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local command named in the map below.
- **After every plan wave:** Run `mix ci.security`
- **Before `$gsd-verify-work`:** Full suite must be green via `mix qa`
- **Max feedback latency:** 120 seconds
- **Serialization note:** Migration-backed proof commands stay serialized; do not run repo-backed security proof files in parallel.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | SEC-REVIEW-01 | T-26-01, T-26-02 | Canonical reviewer packet and trust-boundary doc exist, scope the audit correctly, and link to evidence instead of duplicating truth | docs | `test -f SECURITY_REVIEW.md && test -f docs/security_boundary.md && rg -n "^# Security Review Packet|## Scope|## Rerun|docs/security_boundary.md|CONFORMANCE.md|SECURITY_REVIEW_EVIDENCE.md" SECURITY_REVIEW.md && rg -n "## In Scope|## Out of Scope|## Trust Seams|## Reviewer Assumptions" docs/security_boundary.md` | ❌ W0 | ⬜ pending |
| 26-01-02 | 01 | 1 | SEC-REVIEW-01 | T-26-03 | README points reviewers to the packet without turning into broad Phase 27 docs polish | docs | `rg -n "SECURITY_REVIEW.md|Security Review Packet" README.md` | ⚠️ partial | ⬜ pending |
| 26-02-01 | 02 | 2 | SEC-REVIEW-01 | T-26-04, T-26-07 | `mix relyra.security_review` generates drift-checkable evidence from executable state | build + docs | `mix test test/mix/tasks/relyra_security_review_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 26-02-02 | 02 | 2 | SEC-REVIEW-01 | T-26-05, T-26-06 | Focused proof lane shows fail-closed defaults including one mandatory signed-content trust rejection and one mandatory `AutoRefresh` metadata-bypass proof path without waiting for external findings | unit + integration | `mix test test/security/strict_default_proof_test.exs test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 26-03-01 | 03 | 3 | SEC-REVIEW-01 | T-26-08, T-26-10 | Findings ledger works in a zero-findings state, encodes blocker/disposition policy, and is linked from the canonical reviewer packet | docs | `test -f docs/security_findings.md && rg -n "docs/security_findings.md|Findings Ledger|no external findings recorded yet" SECURITY_REVIEW.md && rg -n "no external findings recorded yet|High|Critical|Medium|Low|Informational|regression" docs/security_findings.md && rg -n "Security review packet|docs/security_findings.md|remediation" SECURITY.md` | ❌ W0 | ⬜ pending |
| 26-03-02 | 03 | 3 | SEC-REVIEW-01 | T-26-09, T-26-10 | CI enforces reviewer-packet shell checks, packet-to-findings wiring, evidence drift, and serialized proof lanes | build | `test -f SECURITY_REVIEW.md && test -f docs/security_boundary.md && rg -n "docs/security_findings.md|Findings Ledger" SECURITY_REVIEW.md && mix relyra.security_review --check && mix test test/security/strict_default_proof_test.exs --warnings-as-errors && mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SECURITY_REVIEW.md` — canonical reviewer packet entry point
- [ ] `docs/security_boundary.md` — trust-boundary and scope map
- [ ] `lib/mix/tasks/relyra.security_review.ex` — generated evidence task with `--check`
- [ ] `test/mix/tasks/relyra_security_review_test.exs` — generator and drift-check coverage
- [ ] `test/security/strict_default_proof_test.exs` — strict-default proof lane
- [ ] `test/relyra/ecto/escape_hatch_audit_test.exs` — serialized escape-hatch audit proof
- [ ] `SECURITY_REVIEW_EVIDENCE.md` — generated security evidence artifact
- [ ] `docs/security_findings.md` — zero-findings-ready ledger and disposition workflow

*Wave 0 is satisfied entirely by the planned files above. No extra unplanned scaffolding is required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Packet wording stays honest about scope and current finding count | SEC-REVIEW-01 | Requires judgment about overstatement, exclusions, and whether the docs imply findings that do not exist yet | Read `SECURITY_REVIEW.md`, `docs/security_boundary.md`, and `docs/security_findings.md`; confirm one canonical entry point, explicit host-app exclusions, and a zero-findings state until real findings are recorded |

---

## Multi-Source Coverage Audit

### GOAL Coverage

| Source Item | Covered By |
|-------------|------------|
| Ready the codebase and documentation for a third-party security review | Plans 26-01, 26-02 |
| Address findings with repo-native remediation workflow | Plan 26-03 |

### REQ Coverage

| Requirement | Covered By |
|-------------|------------|
| `SEC-REVIEW-01` | Plans 26-01, 26-02, 26-03 |

### RESEARCH Coverage

| Research Item | Covered By |
|---------------|------------|
| One repo-native audit packet with one reviewer entry point | Plan 26-01 Task 1 |
| Generated evidence derived from executable state with drift check | Plan 26-02 Task 1 |
| Strict-default proof from existing seams/tests, including mandatory signed-content trust rejection | Plan 26-02 Task 2 |
| Redaction-safe evidence export and audit attribution | Plan 26-02 Task 2 |
| Findings ledger, reviewer-packet wiring, and CI alias reuse | Plan 26-03 Tasks 1-2 |

### CONTEXT Decision Coverage

| Decision(s) | Covered By |
|-------------|------------|
| D-01, D-02, D-03, D-04 | 26-01-01, 26-01-02 |
| D-05, D-06, D-07, D-08, D-09 | 26-03-01, 26-03-02 |
| D-10, D-11, D-12, D-13, D-14 | 26-02-01, 26-02-02 |
| D-15, D-16, D-17, D-18 | 26-01-01, 26-02-02 |
| D-19, D-20 | 26-01-01, 26-03-02 |

### Deferred-Idea Check

- No task introduces a docs site, broad onboarding polish, adopter-security guidance beyond Relyra-owned seams, or generic UX cleanup.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification commands
- [x] Sampling continuity preserved across all plans
- [x] Wave 0 requirements are fully named
- [x] No watch-mode flags
- [x] Repo-backed proof steps are explicitly serialized
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
