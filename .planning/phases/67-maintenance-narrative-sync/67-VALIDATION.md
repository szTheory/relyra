---
phase: 67
slug: maintenance-narrative-sync
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 67 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit plus project shell drift checks |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/docs/testing_api_drift_test.exs --warnings-as-errors && mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` |
| **Full suite command** | `mix ci.docs && mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors && mix test test/release/release_hardening_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds for targeted checks; full `mix qa` remains final safety gate if Elixir/workflow files change |

---

## Sampling Rate

- **After every task commit:** Run the task-specific grep or targeted ExUnit command named in its `<verify>` block.
- **After every plan wave:** Run `mix ci.docs` plus any targeted release/security tests for files touched in that wave.
- **Before `/gsd-verify-work`:** Run `mix format --check-formatted`; run `mix qa` if any Elixir, workflow, script, or generated proof file changed.
- **Max feedback latency:** 180 seconds for targeted sampling; full suite may run longer at phase close.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-01-01 | TBD | 1 | MAINT-01 | T-67-01 | Public docs do not route Hex adopters through stale private TestSupport/FakeIdP wording | docs drift | ``! rg -n 'local TestSupport proof|test-support seam|prove the path locally with `FakeIdP`|Case study FakeIdP reference cleanup|README lists seven SAML families' README.md BATTERIES_INCLUDED.md docs/jtbd_gap_map.md guides/**/*.md lib/mix/tasks/relyra.batteries_included.ex`` | existing | pending |
| 67-01-02 | TBD | 1 | MAINT-01 | T-67-01 | Generated Batteries proof is source-generated, not hand-edited drift | generated docs | `mix relyra.batteries_included --check && mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` | existing | pending |
| 67-02-01 | TBD | 2 | MAINT-02 | T-67-02 | Advisory and planning state record `CVE-2026-49454` without manual publish/retire actions | docs/script drift | `scripts/check_cve_assignment.sh && ! rg -n 'pending assignment|CVE still pending|cve_id still null|pending async' docs/advisories/2026-001-xmldsig-signature-not-verified.md .planning/STATE.md .planning/PROJECT.md .github/workflows/cve-advisory-check.yml scripts/check_cve_assignment.sh` | existing | pending |
| 67-02-02 | TBD | 2 | MAINT-02 | T-67-03 | Security/release guard documentation preserves dedicated security suites and release automation boundaries | security/release tests | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors && mix test test/release/release_hardening_test.exs --warnings-as-errors` | existing | pending |
| 67-03-01 | TBD | 3 | MAINT-02, MAINT-03 | T-67-04 | Phase 29 warning follow-ups and seed statuses are explicit close/defer/reclassify records, not hidden reopen work | planning drift | `! rg -n '^status: dormant' .planning/seeds/SEED-001-adoption-evidence-demo.md .planning/seeds/SEED-002-testsupport-vs-hex-package.md .planning/seeds/SEED-003-demo-fakeidp-login-wip.md` | existing | pending |
| 67-03-02 | TBD | 3 | MAINT-03 | T-67-04 | Demand-gated protocol candidates remain future work and are not folded into Phase 67 | planning drift | `rg -n 'AUTHN-POST-01|KMS-01|SIGNED-META-01|SEED-001|SEED-002|SEED-003|WR-02|WR-03|WR-04|WR-05|IN-01|IN-02|IN-03' .planning/STATE.md .planning/PROJECT.md .planning/MILESTONES.md .planning/todos/completed/29-code-review-followups.md .planning/v1.1-MILESTONE-AUDIT.md` | existing | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `mix ci.docs` already includes docs drift checks and Batteries proof validation.
- `test/docs/testing_api_drift_test.exs` already pins the public `Relyra.Testing` Getting Started example.
- `test/mix/tasks/relyra_batteries_included_test.exs` already checks generated proof content and drift behavior.
- `test/security/ci_gate_integrity_test.exs` and `test/release/release_hardening_test.exs` already cover CI/release guard invariants relevant to Phase 67.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Current external CVE state | MAINT-02 | NVD enrichment can change after planning and should be checked against live official records at execution time | Re-run the GitHub advisory, CVE Services, and NVD curl commands from `67-RESEARCH.md`; confirm GitHub/CVE Services still show `CVE-2026-49454` and record NVD status without inventing configuration details. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or manual external-status checks.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 180s for targeted checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
