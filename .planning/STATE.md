---
gsd_state_version: 1.0
milestone: v1.9
milestone_name: Loose Ends & Adoption Honesty
status: executing
last_updated: "2026-06-19T14:20:24.758Z"
last_activity: 2026-06-19 -- Phase 67 execution started
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 13
  completed_plans: 8
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-15)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 67 — maintenance-narrative-sync

## Current Position

Phase: 67 (maintenance-narrative-sync) — EXECUTING
Plan: 1 of 4
Status: Executing Phase 67
Last activity: 2026-06-19 -- Phase 67 execution started

## Performance Metrics

- Last shipped milestone: v1.8 Brand System & Identity (Phases 58-63, 16/16 requirements)
- Highest shipped phase: 63
- Previous milestone: v1.7 Adoption Evidence Demo (Phases 51-57.1)
- v1.8 phase progress: 6/6 phases complete
- v1.9 planned phase progress: 3/4 phases complete
- Phase 64 Plan 01 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 02 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 03 completed in 5min (2 tasks, 4 files)
- Phase 64 Plan 04 completed in 3min (2 tasks, 2 files)
- Phase 66 Plan 01 completed in 9min (3 tasks, 1 file)
- Phase 66 Plan 02 completed in 8min (1 task, 4 planning files; decision checkpoint)
- Phase 66 Plan 04 completed in 3min (2 tasks, 3 files; retained FakeIdP documentation; SEED-003 resolved)

## Accumulated Context

### Decisions

- v1.8 is brand/design only — zero changes to lib/ security seams, public API, or protocol surface.
- Brand book (`prompts/relyra-brand-book.md`) is decision-complete; this milestone renders the missing artifacts.
- Locked brand constraints: no rectangular logo cages, logotype tight to mark, primary lockup has no subtitle, at least one integrated typemark, title-case "Relyra" only, no lyre/shield/padlock/key/flame/bird imagery.
- Repo-safety budget: vector-first (SVG/HTML/CSS/JSON), no committed font binaries, ~1 MB total brandbook/, exactly one optimized PNG.
- Phase 59 has an interactive checkpoint: maintainer picks the winning logo direction before the full lockup set is developed.
- Phase 62 is the only phase that touches files outside brandbook/: mix.exs ex_doc config, README.md, demo/ledger_loop CSS.
- Demand-gated protocol scope is unchanged and still paused: AUTHN-POST-01, KMS-01, SIGNED-META-01.
- v1.9 rolls SEED-002, SEED-003, and narrow maintenance sync into a bounded adoption-honesty milestone.
- Maintainer explicitly approved planning a public `Relyra.Testing` direction; concrete API shape still needs phase-level design/review and must remain test-only.
- Relyra.Testing ships as plain Phoenix-free functions and explicit fixture structs, not macros.
- Signed success fixtures generate fresh test key material per fixture and return trust material explicitly.
- Public testing code reuses the verifier parser/C14N primitives and does not call Relyra.TestSupport.
- Representative public negative fixtures are limited to wrong audience, post-signing digest tamper, and wrong-key invalid signature.
- Public negative fixture tests pin exact `%Relyra.Error{type: ...}` results through `Relyra.consume_response/3`.
- The public testing fixture crypto suite is tracked in `ci.security` and the anti-hollow meta-gate as a dedicated `cmd mix test` process.
- Relyra.Testing.Phoenix is the only public testing layer that references Phoenix.ConnTest.
- Core public testing modules are guarded by an external Phoenix-absent compile/load subprocess, not source scanning alone.
- [Phase 64]: The artifact-level package proof intentionally builds and unpacks a local Hex package even though it is slower than unit-only checks.
- [Phase 64]: Package proof stays on the existing mix.exs package whitelist and ReleaseParity.filter_package_paths/1 model.
- [Phase 66]: SEED-003: RESOLVED by retaining the LedgerLoop FakeIdP browser flow as demo-local, test-only support and documenting purpose, access, success behavior, tamper behavior, limits, and the port-4000 browser-lane caveat in `guides/fake_idp_demo.md`; Plan 66-03 removal branch remains inactive after `retain_fakeidp`.
- [Phase 67]: MAINT-02 CVE backfill is assigned and recorded as `CVE-2026-49454` for `GHSA-jv46-xfwm-36j7`; CVE Services is `PUBLISHED` and NVD is `Received` with no configurations as of the 2026-06-19 live check.
- [Phase 67]: MAINT-02 CI/release guard status remains evidence-based: `mix ci.security` keeps dedicated `cmd mix test` suites, primary release-please publishing runs `mix qa`, `mix ci.release`, and `mix ci.security`, release-please PR and planning-only PR workflows attach the security matrix checks, and public `main` branch metadata requires `security (27, 1.19.5)` plus `security (28, 1.19.5)`.

### Blockers/Concerns

- Public `Relyra.Testing` is a public API/package-posture change. Phase planning must keep adversarial corpus internals private, use ephemeral key material, and avoid production trust-boundary changes.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand |
| maintenance | CVE ID backfill into `docs/advisories/2026-001-...` | assigned/backfilled as `CVE-2026-49454`; CVE Services `PUBLISHED`, NVD `Received` |
| verification | Phase 53 human-needed UI testing (demo Setup/Operator UX click-through) | deferred; run `/gsd:verify-work 53` |
| brand_future | BRAND-F01 — animated/motion brand assets | deferred to future milestone |
| brand_future | BRAND-F02 — full 19-icon icon library | deferred to future milestone |

## Session Continuity

Last session: 2026-06-18T23:31:14.217Z
Resume at: `$gsd-plan-phase 67`
