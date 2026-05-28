---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Adoption Truth
status: between-milestones
last_updated: "2026-05-28T20:00:00.000Z"
last_activity: 2026-05-28 — Hex 1.5.1 published (maintenance patch + CI hardening)
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-28)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Between milestones — **pause default** for protocol work. Doc UX pass shipped in-repo (Reader Experience); formal `/gsd-new-milestone` optional. Assessment: `.planning/threads/v1-7-milestone-assessment-2026-05-28.md`

## Current Position

Phase: Milestone v1.6 complete — post-assessment pause
Plan: —
Status: Between milestones (pause default; ~93% done for stated scope)
Last activity: 2026-05-28 — Post-v1.6 maintenance complete (Hex 1.5.1, CI hardening)

## Performance Metrics

- Last shipped milestone: v1.6 (Phases 47-49.2)
- Prior shipped milestone: v1.5 (Phases 41-46)

## Accumulated Context

### Roadmap Evolution

- v1.5 shipped 2026-05-27 (Phases 41-46). Highest shipped phase = 46.
- v1.6 starts at Phase 47 (continues numbering; does not reset).
- v1.6 is doc-only: onboarding truth, ops trace docs, CONFORMANCE honesty, jtbd_gap_map refresh, preset taxonomy. No new SAML protocol surface area.
- After v1.6: pause until external demand signal (AUTHN-POST-01, KMS-01, SIGNED-META-01 remain save-for-demand).
- Post-v1.6 assessment (2026-05-28): ~93% done-enough; **do not** open v1.7 feature milestone without trigger. Next phase when work resumes: **50** (continue numbering).
- Hex **1.5.1** live (release-please + CI publish 2026-05-28); README and Getting Started pin `~> 1.5`.
- Post-1.5.0 maintenance (2026-05-28): **security-gates** green; branch protection + `enforce_admins`; publish path runs `mix qa`; `BRANCH_PROTECTION_PAT` configured; release-please automerge; pre-commit hook; patch deps `ex_doc`/`req`.

### Decisions / Constraints carried into v1.6

- **Doc-only boundary is load-bearing:** no new protocol bindings, presets, crypto modules, or public API shape changes. Escalation triggers in CLAUDE.md still apply if scope creeps.
- **Adoption Truth != feature milestone:** closes asymmetry between shipped code and adopter-facing story; reusable pattern at the done-enough line (~92–95%).
- **CONFORMANCE manifest must track shipped features:** ENC-01 shipped Phase 34; `sp-encrypted-assertions-deferred` row is stale and must flip to pass.
- **ci.docs gates apply:** doc drift tests (troubleshooting, logout recipe pattern) stay on `cmd mix test` per Phase 30 hollow-gate invariant when adding new drift tests.

### Decisions from Phase 48-02

- **Day-2 hub pattern:** overview Day-2 links `operations/incident_playbook.md#evidence-surfaces` immediately after Production Ecto path.
- **Getting Started §5:** incident playbook + `mix relyra.trace` + LiveView trace route; optional intro bookmarks playbook after first login.
- **No new ci.docs drift test:** D-15 presence guard sufficient; `login_trace_test.exs` stays in `mix ci.security` only.

### Decisions from Phase 48-01

- **Login trace vs audit ledger callout** under Evidence surfaces — `domain: :login` trace rows are not trust-mutation audit vocabulary; replays appear in trace/telemetry only.
- **Diagnostic bundle ≠ login trace** in When in doubt — `mix relyra.diagnostic` for external handoff; LiveView/`mix relyra.trace` for active step-timeline triage.

### Decisions carried from v1.5

- TRACE LiveView reuses telemetry + audit ledger only (no parallel trace store).
- `mix ci.security` hollow-gate invariant is permanent — each security suite is its own `cmd mix test` process.
- Demand-gated protocol work (AUTHN-POST-01, KMS-01, SIGNED-META-01) stays out of v1.6 unless a real GitHub issue materializes.

### Decisions from Phase 49-03

- **Decoder table expansion:** Keycloak and OneLogin rows added — README 7-family claim honored without narrowing 4 first-class presets.
- **Four-preset taxonomy:** Getting Started §4 and generic_saml intro list Okta, Entra, Google Workspace, and ADFS as batteries-included.
- **Ping/Shibboleth cross-refs:** PingFederate footgun notes README "Ping" naming; Shibboleth cross-link after vendor table (no decoder row).
- **No new ci.docs drift test:** D-15 precedent holds for preset taxonomy doc-only alignment.

### Decisions from Phase 49-02

- **jtbd_gap_map v1.5+ refresh:** What changed section + persona reclassification; generic SAML and Operator personas **Strong** with honest caveats.
- **Gap demotion pattern:** Biggest gaps #1–#4 marked Shipped (v1.3–v1.6); milestones reordered to demand-gated AUTHN-POST/KMS/SIGNED-META.
- **No new ci.docs drift test:** D-15 precedent holds for jtbd_gap_map doc-only refresh.

### Decisions from Phase 49-01

- **CONFORMANCE scope boundary in generator:** `scope_boundary_section/0` appended after CVE-REG-01 table — never hand-edit CONFORMANCE.md.
- **ENC manifest honesty:** `sp-encrypted-assertions-pass` with `FakeIdP.encrypted_response/2` evaluate_row; requirement summary 9 pass / 0 deferred.
- **SPConformanceTest async: false:** SP private key via `Application.put_env` requires serial execution.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand (investigation stub only) |
| maintenance | CVE ID backfill into `docs/advisories/2026-001-...` | pending async (checked 2026-05-28 — GHSA-jv46-xfwm-36j7 `cve_id` still null) |

## Session Continuity

**2026-05-28 — Post-v1.6 maintenance complete.** CI red root cause: unformatted tests + publish path skipped `mix qa` + no branch protection. Fixed: format commit, `mix qa` on Hex publish, security-gates `fetch-depth: 0`, LiveAdmin endpoint health-check, `enforce_admins`, automerge + `BRANCH_PROTECTION_PAT`. PR #9 deps + planning; PR #10 `fix(ci)` release-please trigger; PR #11 → **Hex 1.5.1** ([v1.5.1](https://github.com/szTheory/relyra/releases/tag/v1.5.1)). Release-please bot PRs need a human push to run `security-gates` (GITHUB_TOKEN skip). Pause verdict unchanged.

**2026-05-28 — Phase 49.2 complete.** Nyquist retro (47-VALIDATION.md), editorial polish (playbook/jtbd/SiteMinder), `49.2-VERIFICATION.md` passed. v1.6 Adoption Truth milestone ready for audit.

**2026-05-27 — Phase 49.2 context gathered (assumptions mode).** All assumptions confirmed without correction. Resume: `.planning/phases/49.2-v1.6-nyquist-retro-editorial-polish/49.2-CONTEXT.md` → `/gsd-plan-phase 49.2`

**2026-05-27 — Completed 49-03-PLAN.md.** ADOPT-06: preset taxonomy aligned across generic_saml, Getting Started §4, README verify-only. `mix ci.docs` green. Phase 49 complete — v1.6 Adoption Truth ready for milestone audit.

**2026-05-27 — Completed 49-02-PLAN.md.** ADOPT-05: jtbd_gap_map refreshed to v1.5+ shipped reality. `mix ci.docs` green. Resume: 49-03-PLAN (ADOPT-06 preset taxonomy).

**2026-05-27 — Completed 49-01-PLAN.md.** ADOPT-04: scope boundary section, ENC manifest pass row, CONFORMANCE.md regen. `mix ci.conformance` green. Resume: 49-02-PLAN (ADOPT-05 jtbd_gap_map).

**2026-05-27 — Phase 49 context gathered (assumptions mode).** All assumptions confirmed without correction. Resume: `.planning/phases/49-adoption-honesty-conformance-jtbd-map-preset-taxonomy/49-CONTEXT.md` → `/gsd-plan-phase 49`.

**2026-05-27 — Phase 48 complete (48-01 + 48-02).** Playbook trace tables/scenarios + Day-2 cross-links. Resume: Phase 49 (ADOPT-04/05/06).

**2026-05-27 — Completed 48-01-PLAN.md.** Playbook tables/scenarios/When in doubt updated for login trace.

**2026-05-27 — Phase 48 context gathered.** Assumptions mode; all assumptions confirmed without correction.

**2026-05-27 — Phase 47 context gathered.** Assumptions mode; all assumptions confirmed without correction.

### Post-v1.6 assessment (2026-05-28)

- **Done-%:** ~93% (90–95% band). v1.6 Adoption Truth criteria MET (`docs/jtbd_gap_map.md`).
- **Single pick:** Pause — no `/gsd-new-milestone` until demand signal or maintenance release.
- **Thread:** `.planning/threads/v1-7-milestone-assessment-2026-05-28.md`
- **First protocol wedge when triggered:** AUTHN-POST-01 (~1 week).

## Operator Next Steps

- **Default:** Wait for GitHub issue / adopter request; maintenance only (CVE backfill, deps).
- **When triggered:** `/gsd-new-milestone` with one protocol wedge (not a bundle); continue from Phase 50.
