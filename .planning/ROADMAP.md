# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for Elixir/Phoenix. The v1.x arc is shipped through **v1.7 — Adoption Evidence Demo**. There is **no active milestone**: future protocol work is demand-gated (a real GitHub issue is required to start), and dormant follow-ups in `.planning/seeds/` surface at the next `/gsd:new-milestone`.

## Milestones

- Complete: **v0.1 - SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 - Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 - LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 - IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 - Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 - Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 - External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 - Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 - Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 - Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 - Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 - Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 - Adoption Evidence Demo** (shipped 2026-06-13, Phases 51-56, 23 plans, 30/30 requirements). See `.planning/milestones/v1.7-ROADMAP.md`.

## Active Milestone

**None — paused.** Future protocol scope is demand-gated; do not run `/gsd:new-milestone` for coverage-gated features. Save-for-demand: AUTHN-POST-01, KMS-01, SIGNED-META-01.

Dormant follow-ups (in `.planning/seeds/`, surface at next `/gsd:new-milestone`):
- **SEED-002** — resolve the `Relyra.TestSupport` vs Hex-package contradiction (document the exclusion, or ship an escalation-gated public `Relyra.Testing`).
- **SEED-003** — finish-or-remove the demo FakeIdP login WIP (`/fake_idp/*` routes unwired).

## Phases

No active milestone phases. v1.7 phase detail (goals, success criteria, plans, coverage, progress) is archived at `.planning/milestones/v1.7-ROADMAP.md`.

**Phase Numbering:** integer phases are planned milestone work; decimal phases are urgent insertions executing between their surrounding integers. The next milestone continues after the highest shipped phase, **Phase 56**.
