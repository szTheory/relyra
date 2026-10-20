---
gsd_state_version: "1.0"
milestone: v1.12
milestone_name: Adversarial Twin
status: planning
last_updated: "2026-10-20T00:08:42.942Z"
last_activity: 2026-10-19
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-10-19)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection —
never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Current focus:** v1.12 Adversarial Twin — defining requirements

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-10-19 — Milestone v1.12 started

## Milestone Metrics

- Last shipped milestone: v1.11 First-Adopter Twin (Phases 73–79, 78 plans, 37/37 requirements, archived 2026-10-19)
- Highest shipped phase: 79
- Current milestone: v1.12 Adversarial Twin (Phases 80+)
- Previous milestone: v1.10 Docker DX & Fleet Proxy (Phases 68–72.1)
- Final v1.11 `mix qa`: 1045 tests, 0 failures. Main `ed2d2cf1` was green on every mandatory lane before the archive.

## v1.11 Archive Layout

- The frozen planning record is `.planning/milestones/v1.11-{PROJECT,ROADMAP,REQUIREMENTS,STATE}.md`.
  The final active-milestone STATE, with its decisions, baseline findings, and per-plan
  metrics, is preserved verbatim in `v1.11-STATE.md`.
- The phase directories `73-*` through `79-*` stay in `.planning/phases/`, because the
  governance and evidence contracts in `mix qa` and `mix ci.evidence` read them in place.
  Those contracts validate the frozen record, not this file.

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Acknowledged | Milestone |
|---|---|---|---|---|
| uat_gaps | 73/73-UAT.md | completed (0 open scenarios) | 2026-10-19 | v1.11 |
| verification_gaps | 53/53-VERIFICATION.md (archived v1.7) | human_needed | 2026-10-19 | v1.11 |
| deferred_items | 70/deferred-items.md (archived v1.10): LedgerLoop `mix format --check-formatted` drift in pre-existing unrelated demo files | acknowledged | 2026-10-19 | v1.11 |

Demand-gated or deferred scope:

| Item | Status |
|---|---|
| AUTHN-POST-01 | Demand-gated |
| KMS-01 | Demand-gated |
| SIGNED-META-01 | Demand-gated |
| Hosted external twin | Deferred until the local package twin proves insufficient |
| Exhaustive compatibility matrix | Deferred until adopter evidence justifies its cost |
| QUAL-73-004 | Deferred (see `79-RISKS.json`) |
| WINDOW-29, WINDOW-30 | Phase 76 concurrency automation gaps; costlier to maintain than the risk they retire (`.planning/WINDOWS.md`) |

## Guardrails

- Never trust XML `KeyInfo`; use configured IdP certificates only.
- Keep the single Saxy parse path and raw-binary pre-parse guards.
- Require digest recomputation and genuine `:public_key.verify` signature verification.
- Co-commit every trust mutation and audit row in one transaction.
- Preserve production replay protection and the fresh-process `mix ci.security` suites.
- Do not manually publish Hex or hand-edit `CHANGELOG.md`.

## Blockers

None.

## Session Continuity

**Last session:** 2026-10-19

**Stopped at:** Milestone v1.11 archived

**Resume file:** None

## Operator Next Steps

- v1.12 Adversarial Twin: research, then requirements and roadmap (`/gsd-new-milestone` in progress). Phase numbering continues at 80.
