# Phase 27: Adopter Onboarding Polish and Case Studies - Research

**Researched:** 2026-05-08
**Requirement anchor:** `DOCS-01`
**Goal:** Deliver a frictionless Day-1 experience for adopters through refined documentation, verified provider-specific runbooks, repo-native case studies, and an executable proof of the shipped "batteries included" adoption surface.

## Executive Summary

Phase 27 should stay narrow and executable. The repo already has the core seams needed to prove adopter success: `mix relyra.install` for the blessed scaffold path, `Relyra.TestSupport.FakeIdP` for local-first protocol proof, three shipped provider presets (`:okta`, `:entra`, `:google_workspace`) with vendor-label and footgun metadata, and generated-evidence patterns from Phases 25 and 26. The phase should not add a broad docs catalog or imply provider support beyond those three presets. The right split is:

1. Re-architecture the docs entry points into one canonical Day-1 spine.
2. Turn the provider recipes into authoritative operator runbooks and add a small set of repo-native case studies.
3. Add one executable "batteries included" proof journey backed by focused tests and CI wiring.

## Verified Repo Seams To Reuse

### Canonical routing and narrow top-level pointers

- `README.md` already acts as a router, but its current Day-1 surface is too thin and then immediately competes with advanced operations content.
- `SECURITY_REVIEW.md` shows the repo's preferred pattern for a canonical entry point: concise, linked, and non-duplicative.

Implication: Phase 27 should make `README.md` an obvious router into one ordered onboarding flow instead of adding another peer guide.

### Local-first proof path

- `guides/getting_started.md` already places `Relyra.TestSupport.FakeIdP` first.
- `test/test_support_demo_test.exs` proves adopters can stand up a tiny host-side integration test with the shipped helper surface.
- `lib/relyra/test_support/fake_idp.ex` gives a deterministic, protocol-correct first receipt before a real IdP is involved.

Implication: the first success checkpoint in the Day-1 story should be local and deterministic, not "go configure Okta first."

### Blessed install path

- `lib/mix/tasks/relyra.install.ex` is the correct adoption entry seam.
- `test/mix/relyra_install_test.exs` already proves the generator creates the expected host-app surface.
- The installer intentionally avoids risky router mutation and falls back to explicit instructions where automation would be ambiguous.

Implication: the phase's proof artifact should prove the blessed scaffold path, not a hand-authored demo that bypasses the installer.

### Provider support contract

- `lib/relyra/provider.ex` explicitly limits shipped presets to `:okta`, `:entra`, and `:google_workspace`.
- The provider contract includes guide URLs, label translations, and footgun checks.
- Current recipe docs exist for exactly those three providers.

Implication: Phase 27 should tighten the support taxonomy around those three runbooks and move everything else under explicit custom/generic SAML language.

### Executable proof and drift-gate patterns

- `CONFORMANCE.md` and `SECURITY_REVIEW_EVIDENCE.md` show the preferred generated-artifact shape: claim -> seam -> proof command -> artifact.
- `lib/mix/tasks/relyra.conformance.ex` and `lib/mix/tasks/relyra.security_review.ex` show the established `--output` / `--check` pattern for deterministic markdown artifacts.
- `mix.exs` already carries narrowly scoped CI aliases for generated artifacts and focused proof lanes.

Implication: if Phase 27 claims "batteries included," it should back that claim with either a generated proof artifact or a tightly verified hand-authored guide plus focused proof tests and CI checks. A prose-only checklist is not strong enough.

## Recommended Phase Split

### Plan 27-01: Canonical Day-1 information architecture

Scope:
- Rework `README.md` into the canonical router.
- Expand `guides/getting_started.md` into the ordered Day-1 spine.
- Make the support taxonomy explicit: batteries included vs custom/generic SAML vs not yet shipped.

Why first:
- Everything else depends on having one clear path rather than competing entry points.

Likely files:
- `README.md`
- `guides/getting_started.md`
- possibly a new guide index or support-matrix page if needed, but only if it sharpens the canonical route rather than creating another peer entry point.

### Plan 27-02: Provider runbooks and repo-native case studies

Scope:
- Upgrade `guides/recipes/okta.md`, `guides/recipes/entra.md`, and `guides/recipes/google_workspace.md` from short recipes into authoritative operator runbooks.
- Add a small number of repo-native case studies built around real adopter scenarios and explicit ownership boundaries.

Why second:
- The canonical Day-1 spine should branch into one provider runbook; the branch surfaces must exist before the final proof story and support matrix are closed.

Likely files:
- `guides/recipes/okta.md`
- `guides/recipes/entra.md`
- `guides/recipes/google_workspace.md`
- one or more new `guides/case_studies/*.md` files

### Plan 27-03: Batteries-included proof and CI enforcement

Scope:
- Add one proof artifact and focused proof lane for the adoption journey.
- Reuse `mix relyra.install`, `Relyra.TestSupport.FakeIdP`, and shipped operational seams as receipts.
- Wire drift/check commands into `mix.exs`.

Why third:
- The proof artifact should point at the finalized onboarding IA and runbooks, not a moving target.

Likely files:
- `lib/mix/tasks/relyra.<proof_task>.ex` if a generated artifact is chosen
- `test/mix/relyra_install_test.exs` or a sibling proof test
- one focused end-to-end adopter proof test
- `mix.exs`
- one checked-in proof artifact or guide

## Strong Recommendation For The Proof Approach

Use a hybrid approach:

- A human-facing proof guide that walks the adopter journey in operator order.
- A generated or drift-checked evidence artifact that maps each major claim to an executable seam and command.
- Focused tests that prove the scaffold path and first successful SAML round trip.

Why this is the best fit:

- A guide alone is too soft for the "demonstrably achieved" success criterion.
- A generated artifact alone is too cold to serve as the canonical Day-1 narrative.
- The repo already has the exact generated-artifact and proof-lane patterns from Phases 25 and 26.

Recommended receipts in order:

1. `mix relyra.install` generated files exist and contain the expected scaffold contract.
2. `Relyra.TestSupport.FakeIdP` round trip succeeds in a tiny host-style integration flow.
3. One provider preset path is documented with exact field vocabulary and failure handling.
4. Optional admin, metadata/certificate lifecycle, telemetry/audit, scheduled refresh, and diagnostic seams are linked as day-2 follow-ons, each with a concrete command or artifact.

## Risks And Anti-Patterns

### Risk: accidental support-claim expansion

The project-level docs still mention more providers than the shipped preset registry actually supports. Phase 27 must tighten wording so the public support matrix matches code reality.

### Risk: too many peer entry points

If `README.md`, `guides/getting_started.md`, a proof guide, and the provider docs all read like independent starts, adopters will still not have a canonical path.

### Risk: case studies collapsing into marketing or throwaway demos

The phase context explicitly rejects testimonials and giant sample apps. Keep case studies repo-native, scenario-led, and operational.

### Risk: hand-maintained proof drift

Any "batteries included" claim that is not tied to focused tests or a drift-checked artifact will rot quickly.

### Risk: over-scoping provider coverage

Do not use Phase 27 to expand preset support. New providers would require preset modules, verified runbooks, and proof coverage, which is outside this phase.

## Recommended Verification Shape

- `rg` checks for README -> Getting Started -> provider runbook routing and explicit support taxonomy.
- `rg` checks for each runbook's required sections: exact field vocabulary, Relyra-owned vs IdP-owned vs host-owned boundaries, proof of success, common failures, day-2 notes.
- Focused Mix/install proof test(s) validating the blessed scaffold path.
- Focused TestSupport/FakeIdP proof test validating the first successful local journey.
- If a generated proof artifact is added: `mix relyra.<proof_task> --check`.

## Planning Guidance

- Keep the phase at three plans. The roadmap already expects a 3-plan shape, and the work splits cleanly into IA, runbooks/case studies, and proof/CI.
- Favor exact, grep-able acceptance criteria over subjective "docs feel polished" statements.
- Treat low-impact naming and file-layout choices as agent discretion, but escalate any change that broadens provider support claims or changes milestone scope.

## RESEARCH COMPLETE

Phase 27 should be planned as a documentation-and-proof phase, not a feature phase: one canonical onboarding spine, three authoritative provider runbooks plus a small case-study set, and one executable proof journey that makes the batteries-included claim falsifiable.
