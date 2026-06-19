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
| 67-01-01 | 01 | 1 | MAINT-01 | T-67-01, T-67-03 | Public docs route Hex adopters through public `Relyra.Testing` proof and keep provider taxonomy exact. | docs drift | Task verify: targeted stale narrative `rg`; `mix test test/docs/testing_api_drift_test.exs --warnings-as-errors`. | existing | pending |
| 67-01-02 | 01 | 1 | MAINT-01 | T-67-02 | `BATTERIES_INCLUDED.md` is regenerated from the Mix task and cannot drift from source wording. | generated docs | Task verify: generator stale-term `rg`; `mix relyra.batteries_included --check`; `mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors`. | existing | pending |
| 67-02-01 | 02 | 1 | MAINT-02 | T-67-04, T-67-05 | Advisory and polling surfaces assert `CVE-2026-49454` without manual publish/retire actions or invented NVD enrichment. | docs/script drift | Task verify: CVE Services curl with `--max-time 30`; NVD curl with `--max-time 30`; `scripts/check_cve_assignment.sh`; stale pending-wording `rg`. | existing | pending |
| 67-02-02 | 02 | 1 | MAINT-02 | T-67-06 | Planning status preserves dedicated security suites and release automation boundaries. | security/release tests | Task verify: guard evidence `rg`; stale planning-wording `rg`; `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors`; `mix test test/release/release_hardening_test.exs --warnings-as-errors`. | existing | pending |
| 67-03-01 | 03 | 2 | MAINT-02 | T-67-07, T-67-09 | Phase 29 warning follow-ups are explicit dispositions, not implied code fixes. | planning drift | Task verify: WR/IN disposition `rg`; `git diff --exit-code -- lib/relyra/security/signature.ex lib/relyra/security/xml/pure_beam.ex lib/relyra/metadata/auto_refresh.ex lib/relyra/security/algorithm_policy.ex`. | existing | pending |
| 67-03-02 | 03 | 2 | MAINT-02 | T-67-08, T-67-09 | v1.1 audit and project carry-forward wording point to the disposition source and keep crypto gates intact. | planning/security tests | Task verify: audit/project disposition `rg`; `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors`. | existing | pending |
| 67-04-01 | 04 | 3 | MAINT-03 | T-67-10, T-67-11, T-67-12 | SEED-001, SEED-002, and SEED-003 have non-dormant resolved/completed metadata with dated evidence. | planning drift | Task verify: non-dormant seed `rg`; seed evidence `rg` for v1.7, `Relyra.Testing`, `retain_fakeidp`, and `guides/fake_idp_demo.md`. | existing | pending |
| 67-04-02 | 04 | 3 | MAINT-03 | T-67-13 | Planning status agrees with seed metadata and preserves demand-gated protocol candidates as future work. | planning drift | Task verify: planning status `rg` for resolved seeds, `CVE-2026-49454`, `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01`; MAINT coverage `rg`. | existing | pending |

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
| Current external CVE state | MAINT-02 | NVD enrichment can change after planning and should be checked against live official records at execution time | Re-run the GitHub advisory, CVE Services, and NVD curl commands from `67-RESEARCH.md` using `curl --max-time 30 --retry 2 --retry-delay 2`; confirm GitHub/CVE Services still show `CVE-2026-49454` and record NVD status without inventing configuration details. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or manual external-status checks.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 180s for targeted checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
