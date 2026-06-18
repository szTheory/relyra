# Phase 67: Maintenance Narrative Sync - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-18
**Phase:** 67-maintenance-narrative-sync
**Mode:** assumptions
**Areas analyzed:** Narrative Sync, CVE/CI/Phase 29 Status, Seed Disposition

## Assumptions Presented

### Narrative Sync

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 67 should do a narrow narrative cleanup, not redesign adopter docs: keep `guides/jtbd_user_flows.md` Scene 3 aligned around `Relyra.Testing` and the four first-class providers, then fix adjacent stale mentions such as `FakeIdP` / `TestSupport` where they contradict that story. | Confident | `guides/jtbd_user_flows.md`; `README.md`; `docs/jtbd_gap_map.md`; `.planning/RETROSPECTIVE.md` |

### CVE, CI, And Phase 29 Status

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 67 should record status and reconcile planning notes, but avoid changing CI/release workflows unless a stale note is clearly found; current repo files already show the intended guards are present. | Likely before external research; Confident after external research | `docs/advisories/2026-001-xmldsig-signature-not-verified.md`; `scripts/check_cve_assignment.sh`; `.github/workflows/cve-advisory-check.yml`; `mix.exs`; `.github/workflows/security-gates.yml`; `.github/workflows/release-please.yml`; `.github/workflows/release-please-pr-checks.yml`; `.github/workflows/planning-pr-checks.yml`; `scripts/setup_branch_protection.sh`; `.planning/todos/completed/29-code-review-followups.md`; `.planning/v1.1-MILESTONE-AUDIT.md`; `.planning/PROJECT.md`; `.planning/RETROSPECTIVE.md` |

### Seed Disposition

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 67 should reclassify/close seed metadata rather than reopen implementation: SEED-001 is shipped by v1.7, SEED-002 is addressed by the public `Relyra.Testing` package/docs path, and SEED-003 is resolved by retained FakeIdP documentation. | Confident | `.planning/seeds/SEED-001-adoption-evidence-demo.md`; `.planning/seeds/SEED-002-testsupport-vs-hex-package.md`; `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md`; `.planning/MILESTONES.md`; `.planning/phases/64-public-testing-api-package-boundary/64-04-SUMMARY.md`; `.planning/STATE.md`; `.planning/phases/66-demo-fakeidp-disposition/66-04-SUMMARY.md` |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

- Advisory CVE status: `GHSA-jv46-xfwm-36j7` now has public CVE `CVE-2026-49454`; it is no longer pending. Sources: GitHub advisory, CVE AWG API, NVD API.
- Branch protection / checks: public GitHub branch metadata confirms `main` is protected and requires `security (27, 1.19.5)` and `security (28, 1.19.5)`. Full branch protection settings require authenticated GitHub API access; do not claim unauthenticated public verification for settings beyond the public branch metadata.
