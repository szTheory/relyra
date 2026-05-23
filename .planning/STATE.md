---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Verify the Trust Path
status: planning
last_updated: "2026-05-23T14:12:17.309Z"
last_activity: 2026-05-23
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-23)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** v1.1 "Verify the Trust Path" — P0 fix for non-cryptographic signature verification (confirmed auth bypass in published hex `1.0.0`/`1.1.0`). Make the Core Value literally true: real exclusive-C14N + `:public_key.verify` + `DigestValue` recompute behind the `Relyra.Security.XML` seam.

## Current Position

Phase: 28 — Real C14N parser foundation (not started; roadmap drafted)
Plan: —
Status: Roadmap created; awaiting `/gsd:plan-phase 28`
Last activity: 2026-05-23 — v1.1 roadmap created (Phases 28-31)

Milestone progress: [----------] 0/4 phases complete

## Performance Metrics

- Phases planned this milestone: 4 (28-31)
- Plans complete: 0
- Coverage: 8/8 v1.1 requirements mapped

## Accumulated Context

### Roadmap Evolution

- v1.0 shipped 2026-05-08 (Phases 25-27). Highest shipped phase = 27.
- v1.1 starts at Phase 28 (continues numbering; does not reset).
- v1.1 is a focused, URGENT security milestone derived from the 2026-05-23 P0 audit.
- Phase sequence is dependency-ordered: foundation (28) → verification (29) → assurance (30) → disclosure (31). The verify math (SIGV-01/02) cannot land before correct canonicalization (SIGV-03), so Phase 28 must complete first.

### Decisions / Constraints carried into v1.1

- **ADR-0001 governs:** pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam. The hybrid+xmlsec NIF (GATE-03 matrix) is a **conditional rollback** only if pure-BEAM correctness gates can't be met — NOT a planned phase.
- **Brownfield, extend not rebuild:** work lands in `lib/relyra/security/signature.ex` (`do_verify`), `lib/relyra/security/xml/pure_beam.ex` (add `saxy` parse tree + real exclusive C14N), `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/test_support/fake_idp.ex`. Reuse the existing hardened parser boundary, single-signed-node selection, duplicate-ID + document-`KeyInfo` rejection — these stay; the new work is the actual crypto + correct C14N underneath them.
- **`saxy` is not yet in `mix.exs`** — the parser path ADR-0001 specified was never added. Phase 28 adds it.
- **Fix-first posture:** branch `security/xmldsig-real-verification`; GHSA/CVE/CHANGELOG advisory published at the fixed release, not before.

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table.

## Deferred Items

Items acknowledged and deferred at the v1.0 milestone close (2026-05-08):

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 15: 15-VERIFICATION.md | human_needed |

Deferred to the next milestone ("Advanced Federation"): encrypted assertions, complete Single Logout, signed outbound AuthnRequests, adoption-docs polish, runnable demo app.

## Session Continuity

Next action: `/gsd:plan-phase 28` to decompose the C14N parser foundation into executable plans.
