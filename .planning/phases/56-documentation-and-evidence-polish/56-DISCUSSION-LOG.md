# Phase 56: Documentation And Evidence Polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-13
**Phase:** 56-documentation-and-evidence-polish
**Mode:** assumptions + per-area deep research (user-directed)
**Areas analyzed:** Demo guide placement, linking strategy, README content/structure, evidence framing, host-app boundary, doc-drift test

## Assumptions Presented (initial — gsd-assumptions-analyzer)

### Demo Guide Placement And Authority
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Full guide = rewrite of `demo/ledger_loop/README.md`; thin `guides/demo.md` pointer (ships to hexdocs) links out to GitHub | Confident | `mix.exs:104` ships `guides/` but excludes `demo/`; `markdown_link_smoke_test.exs`; demo README still the `phx.new` scaffold |
| README documents subcommands `doctor\|up\|reset\|test\|urls\|down`, URLs `:4000`/`:8080`, profiles `core/keycloak/browser`, mix `setup`/`ecto.reset`, seeded Northstar + sarah@/chen@, four connection states | Confident | `scripts/demo`, `docker-compose.yml`, `fixtures.ex`, `router.ex` |

### Linking Strategy Preserving The Hex Install Path
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| README + getting_started link demo as evaluator side-channel AFTER the install/TestSupport narrative, never in/above the `{:relyra, "~> 1.5"}` block | Confident | `README.md:13-17`, `:35-44`; DOCS-01 / SC1 |

### Scope-Honesty Notes And The Drift-Test Decision
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| "Adoption proof only" note in two places (top callout + bottom section), mirroring README "What Does Not Ship" voice | Likely | `README.md:103-109`; `adopter_voice_test.exs` |
| Add lightweight demo drift test wired into `ci.demo_app` (initial rec) | Likely | drift-test culture; `ci.docs` package-focused; demo excluded from package |

## External Research Performed (user-directed, 3 parallel agents)

The user directed a per-area deep research pass (pros/cons/tradeoffs, ecosystem-idiomatic patterns,
lessons from comparable libs/demos, DX emphasis, coherence, weighting the `prompts/` research corpus).
Three general-purpose agents ran in parallel.

### Agent 1 — Doc placement & linking architecture
- **Confirmed Option A** (full guide in demo README + thin `guides/demo.md` pointer). Universal Elixir
  convention (Phoenix/LiveView/Oban/Ash) and cross-ecosystem SDK convention (Stripe/Auth0/Okta/Devise):
  the demo is a destination you link to, never inlined into published reference docs.
- **New decisive finding:** links from `guides/demo.md` into `demo/` must be **absolute GitHub URLs pinned
  to `main`** — relative links pass `markdown_link_smoke_test.exs` on disk but 404 on hexdocs because
  `demo/` is excluded from `package.files`. Recommended optionally hardening the smoke test to flag
  relative links resolving outside `package.files`.
- Linking: keep install path primary; demo as secondary "see it running" reference; getting_started §5
  follow-ons only; label "runnable reference app, not part of the Hex package."

### Agent 2 — Doc-drift test investment
- **Confirmed: add a drift test, but tightly scoped to the `scripts/demo` subcommand set only** (routes/creds
  are prose not contract → brittleness). Model on `troubleshooting_drift_test` + `logout_recipe_drift_test`;
  runtime-extract subcommands; scope doc scan to fenced bash blocks; bidirectional set-diff.
- **CORRECTION (flips the initial assumption):** lane must be **`ci.docs`, NOT `ci.demo_app`**. `ci.demo_app`
  runs every step with `--cd demo/ledger_loop`, so a test there physically cannot read repo-root
  `scripts/demo`. `ci.docs` runs at repo root, already hosts the other drift gates, and the dedicated
  `cmd mix test` line satisfies the hollow-gate invariant.

### Agent 3 — Evidence framing, README structure, voice
- Recommended an 11-section evaluator-first outline; evidence note in BOTH places (asymmetric: 1-line
  positive top callout + fuller bottom "Scope & honesty" mirroring "What Does Not Ship"); host boundary as
  a two-column "Who owns what" table with the JTBD canonical caption. Provided ready-to-use brand-voice
  microcopy. Cited Stripe Samples, Phoenix RealWorld, Auth0 quickstarts, Supabase examples, Cal.com.
- **New content-accuracy finding:** FakeIdP signs `evaluator@example.com`
  (`fake_idp_controller.ex:17,28`), but seeded users are `sarah@`/`chen@northstar.example.com` — the
  walkthrough must reconcile this before claiming "land as Dr. Sarah."

## Corrections Made (research-driven, not user-rejected)

The user did not reject assumptions; they directed research that refined them:

### Drift-Test Lane
- **Original assumption:** wire the demo drift test into `ci.demo_app`.
- **Corrected to:** `ci.docs` (forced — `ci.demo_app`'s `--cd demo/ledger_loop` cannot read repo-root
  `scripts/demo`; `ci.docs` runs at repo root and honors the hollow-gate invariant).
- **Reason:** mechanical cwd constraint surfaced by research Agent 2.

### Drift-Test Scope
- **Original assumption:** assert subcommands + routes + seeded creds.
- **Corrected to:** subcommands ONLY (routes/creds are prose, not contracts → brittleness on a low-stakes,
  out-of-package, end-of-milestone guide).

### Placement footgun
- **Added:** absolute-GitHub-URL-pinned-to-`main` rule for all `guides/demo.md → demo/` links (D-02b),
  plus optional smoke-test hardening (D-02c). Not in the original assumption set.

### Content accuracy
- **Added (D-12):** FakeIdP `evaluator@example.com` vs seeded `sarah@`/`chen@` mismatch — walkthrough must
  match actual login outcome.

## External Research Sources

- prompts/elixir-opensource-libs-best-practices-deep-research.md, prompts/relyra-brand-book.md,
  prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md, prompts/phoenix-best-practices-deep-research.md
- Stripe Samples (accept-a-payment, issuing-treasury); gothinkster elixir-phoenix-realworld-example-app;
  Auth0 SDK quickstart samples; Supabase examples/user-management; Cal.com / cal.diy READMEs.
