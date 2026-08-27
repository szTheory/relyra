---
phase: 72-documentation
plan: "02"
subsystem: documentation
tags: [docker, make, hexdocs, ledgerloop, documentation]
requires:
  - phase: 72-01
    provides: Canonical Make-first Docker developer guide
provides:
  - Detailed LedgerLoop evaluator route for Solo, Fleet, and optional Keycloak
  - HexDocs-safe absolute routes to repository-only evaluator material
  - Root README Docker/Fleet routing that preserves Day-1 onboarding
affects: [demo documentation, HexDocs routing, operator guides]
tech-stack:
  added: []
  patterns: [static documentation router contracts, Make-first evaluator routing]
key-files:
  created: []
  modified:
    - demo/ledger_loop/README.md
    - guides/demo.md
    - README.md
    - test/docs/demo_guide_drift_test.exs
key-decisions:
  - "Solo/FakeIdP remains the complete first evaluator proof; Fleet and Keycloak are optional follow-ons."
  - "Published demo documentation uses absolute GitHub links for repository-only operational material."
  - "Root README retains its library Day-1 sequence and routes Docker evaluation separately."
metrics:
  duration: 14m
  completed_date: 2026-08-27
  tasks_completed: 2
  files_modified: 4
status: complete
coverage:
  - id: D1
    description: "LedgerLoop detailed evaluator route uses Make-first Solo/FakeIdP, retains Local Mix, and preserves ownership wording."
    requirement: DOC-02
    verification:
      - kind: unit
        ref: "test/docs/demo_guide_drift_test.exs#detailed evaluator README follows the Make-first Docker route and retains Local Mix"
        status: pass
    human_judgment: false
  - id: D2
    description: "Published and root documentation routers converge on the canonical Docker guide without displacing Day-1 onboarding."
    requirement: DOC-02
    verification:
      - kind: unit
        ref: "test/docs/demo_guide_drift_test.exs#demo and repository routers converge on the Make-first guide"
        status: pass
      - kind: unit
        ref: "test/docs/markdown_link_smoke_test.exs"
        status: pass
    human_judgment: false
---

# Phase 72 Plan 02: Documentation Router Convergence Summary

**Make-first Solo/FakeIdP, Fleet, and optional Keycloak routing across the detailed demo README, HexDocs router, and root README.**

## Performance

- **Duration:** 14m
- **Started:** 2026-08-27T16:53:14Z
- **Completed:** 2026-08-27T17:07:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Reworked LedgerLoop's Docker entry point around `make doctor` and `make up-build`, retaining Local Mix and exact host-owned receipt wording.
- Replaced stale direct Keycloak and launcher instructions with Fleet-first proxy routing and the public Keycloak origin.
- Added absolute GitHub routes from the published demo guide to both source-only operational documents.
- Added root README evaluator and Day-2 routes without changing the library Getting Started sequence.
- Added deterministic router coherence coverage and kept the package/ExDoc inventory unchanged.

## Files Created/Modified

- `demo/ledger_loop/README.md` — Make-first evaluator Quick Start, Fleet/Keycloak follow-ons, recovery routing, and receipt boundary.
- `guides/demo.md` — concise published-doc-safe absolute routes to the canonical Docker guide and detailed README.
- `README.md` — Docker/Fleet evaluator and Day-2 routing outside the Day-1 library path.
- `test/docs/demo_guide_drift_test.exs` — static contracts for detailed and published/repository router coherence.

## Decisions Made

- Solo/FakeIdP is the complete first proof; Fleet and Keycloak remain optional follow-ons.
- HexDocs-facing documentation links source-only evaluator material through absolute GitHub URLs.
- Docker evaluation remains distinct from, and follows, the library's canonical Day-1 Getting Started sequence.

## Verification

- `mix test test/docs/demo_guide_drift_test.exs test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` — passed (24 tests).
- `mix qa` — passed (786 tests, 10 excluded).
- `mix ci.security` — passed.
- `mix format --check-formatted` — passed.
- `mix test --warnings-as-errors` — passed.
- `git diff --exit-code -- mix.exs test/docs/markdown_link_smoke_test.exs` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected ordered router assertions for repeated README phrases**
- **Found during:** Tasks 1 and 2
- **Issue:** The new static assertions initially matched an earlier repeated `Solo` / Getting Started phrase instead of the intended route sequence.
- **Fix:** Scoped assertions to stable headings and unique list text while preserving the planned router behavior checks.
- **Files modified:** `test/docs/demo_guide_drift_test.exs`
- **Verification:** Focused docs suite passed.
- **Committed in:** `3b550c8`, `2d499d5`

## Known Stubs

None.

## Self-Check: PASSED

- Verified all four modified files exist.
- Verified task commits `3710385`, `3b550c8`, `75065da`, and `2d499d5` exist.
