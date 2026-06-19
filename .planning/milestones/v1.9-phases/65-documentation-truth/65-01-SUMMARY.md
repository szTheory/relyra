---
phase: 65-documentation-truth
plan: 01
subsystem: docs-testing
tags:
  - docs
  - testing
  - phoenix
  - package-truth

requires:
  - phase: 64-public-testing-api-package-boundary
    provides: public Relyra.Testing and Relyra.Testing.Phoenix APIs
provides:
  - Adopter-facing docs that point to Relyra.Testing instead of private Relyra.TestSupport
  - Public Phoenix testing demo using Relyra.Testing.signed_success/1 and Relyra.Testing.Phoenix.post_response/5
  - Doc drift coverage for the Getting Started public testing code blocks
  - Batteries-included proof output aligned with the public testing API
affects:
  - docs
  - public-testing-api
  - adoption-honesty

tech-stack:
  added: []
  patterns:
    - Data-first public testing fixtures for adopter docs
    - Documentation drift tests mirror copy-paste guide snippets

key-files:
  created:
    - test/testing_demo_test.exs
    - test/docs/testing_api_drift_test.exs
  modified:
    - README.md
    - guides/getting_started.md
    - guides/overview.md
    - guides/jtbd_user_flows.md
    - guides/recipes/generic_saml.md
    - guides/recipes/okta.md
    - guides/recipes/entra.md
    - guides/recipes/google_workspace.md
    - guides/recipes/adfs.md
    - guides/case_studies/phoenix_saas_tenant_onboarding.md
    - guides/batteries_included.md
    - mix.exs
    - lib/mix/tasks/relyra.batteries_included.ex
    - BATTERIES_INCLUDED.md
    - test/mix/tasks/relyra_batteries_included_test.exs

key-decisions:
  - "Forked a public `test/testing_demo_test.exs` while leaving `test/test_support_demo_test.exs` as internal CI coverage."
  - "Made `Relyra.Testing` and `Relyra.Testing.Phoenix` the adopter-facing local proof APIs."
  - "Left LedgerLoop FakeIdP demo references for Phase 66 disposition instead of changing demo-local internals in Phase 65."

patterns-established:
  - "Adopter docs use explicit fixture data instead of private test macros."
  - "Getting Started snippets are protected by doc drift tests."

requirements-completed:
  - DOCS-01
  - DOCS-02
  - DOCS-03

duration: 22min
completed: 2026-06-18
status: complete
---

# Phase 65: Documentation Truth Summary

**Adopter-facing docs and proof artifacts now use the public Relyra.Testing API while private TestSupport and demo FakeIdP internals remain repo-only.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-06-18T14:39:44-04:00
- **Completed:** 2026-06-18T15:01:01-04:00
- **Tasks:** 5
- **Files modified:** 15

## Accomplishments

- Added a public `test/testing_demo_test.exs` integration proof based on `Relyra.Testing.signed_success/1` and `Relyra.Testing.Phoenix.post_response/5`.
- Rewrote README, Getting Started, overview, recipes, JTBD flows, and the SaaS onboarding case study around the public testing API.
- Added `test/docs/testing_api_drift_test.exs` so Getting Started code blocks stay synchronized with the public demo pattern.
- Updated batteries-included generation and proof docs to reference `test/testing_demo_test.exs` and `Relyra.Testing`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Isolate test_support_demo_test.exs and create testing_demo_test.exs** - `6bd558f` (`test`)
2. **Task 2: Rewrite Getting Started, README, and Overview** - `e2cde95` (`docs`)
3. **Task 3: Add test/docs/testing_api_drift_test.exs** - `2de1c32` (`test`)
4. **Task 4: Update Recipes, Case Studies, and JTBD Flows** - `705a1bd` (`docs`)
5. **Task 5: Update BATTERIES_INCLUDED.md and Installer Tooling** - `adfb6ec` (`test`)
6. **Post-review closure: Close docs testing review gaps** - `5a00ba0` (`test`)

## Files Created/Modified

- `test/testing_demo_test.exs` - Public copy-pasteable Phoenix testing proof using `Relyra.Testing`.
- `test/docs/testing_api_drift_test.exs` - Drift guard for the Getting Started public testing snippets.
- `README.md` - Local proof path points to `Relyra.Testing`.
- `guides/getting_started.md` - Section 3 uses explicit fixture data and documents ephemeral test key provenance.
- `guides/overview.md` - Onboarding flow points to public data-first testing helpers.
- `guides/jtbd_user_flows.md` - Local proof references use `Relyra.Testing`.
- `guides/recipes/*.md` - Provider recipes direct adopters through `Relyra.Testing` before real IdP setup.
- `guides/case_studies/phoenix_saas_tenant_onboarding.md` - Case study proof language updated to the public API.
- `guides/batteries_included.md` and `BATTERIES_INCLUDED.md` - Generated proof docs reference `test/testing_demo_test.exs`.
- `lib/mix/tasks/relyra.batteries_included.ex` - Generator points to the public testing demo.
- `test/mix/tasks/relyra_batteries_included_test.exs` - Generator test expectations updated.
- `mix.exs` - `ci.docs` now runs the public testing drift test and public demo proof.

## Decisions Made

- Preserved `test/test_support_demo_test.exs` as internal coverage rather than deleting or renaming it, because Phase 65 only removes private testing APIs from adopter-facing docs.
- Kept `demo/ledger_loop` FakeIdP references untouched for Phase 66, matching the plan boundary.
- Used drift tests to pin the exact documented code blocks instead of relying on narrative review alone.

## Deviations from Plan

The original task commits completed the planned scope but left four advisory review gaps:
`mix ci.docs` did not run the new public demo/drift tests, the public demo did not
explicitly verify the signed fixture, the batteries-included task test underasserted the
public proof path, and Getting Started used a nonexistent backticked `Relyra.security`
identifier. Commit `5a00ba0` resolved these within the Phase 65 documentation/testing
surface.

## Issues Encountered

- The task commits existed without the normal GSD `65-01-SUMMARY.md` artifact. This summary was reconstructed from the existing atomic commits as a safe-resume recovery, avoiding duplicate execution.

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

- Existing task commits for all five planned tasks are present in git history.
- `test/testing_demo_test.exs` contains `Relyra.Testing.signed_success`.
- Targeted adopter-facing docs and proof files contain no `Relyra.TestSupport` or `FakeIdP` references.
- `guides/getting_started.md` contains an ExDoc admonition describing ephemeral RSA keys for local testing fixtures.
- `mix test test/testing_demo_test.exs test/test_support_demo_test.exs test/docs/testing_api_drift_test.exs test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` passed with 9 tests, 0 failures.
- `mix relyra.batteries_included --check` passed.
- `mix ci.docs` passed.
- Advisory code review was re-run after `5a00ba0`; `.planning/phases/65-documentation-truth/65-REVIEW.md` is `status: clean` with 0 findings.

## Next Phase Readiness

Phase 66 can reason about LedgerLoop FakeIdP disposition without Phase 65 leaking demo-local FakeIdP language back into adopter-facing package docs.

---
*Phase: 65-documentation-truth*
*Completed: 2026-06-18*
