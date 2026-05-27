# Phase 46: Adopter DX & ergonomics - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 46-adopter-dx-ergonomics
**Mode:** assumptions
**Areas analyzed:** README snippet, Router auto-injection, Doc navigation, BATTERIES_INCLUDED dedupe, Test coverage

## Assumptions Presented

### README above-the-fold snippet (DX-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Insert `apply_defaults(:okta, [...])` block after tagline, before "## Start Here" | Confident | `README.md:6-17`, `guides/recipes/okta.md:57-63`, `lib/relyra/provider.ex:119-127` |
| Snippet uses 4-key okta.md shape with placeholder values | Confident | `guides/recipes/okta.md:57-63` |
| Preserve Phase 41 4-first-class + generic runbook framing | Confident | `41-CONTEXT.md` D-09, `README.md:25-59` |

### Router auto-injection (DX-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Auto-detect single `lib/**/*router.ex` with `use Phoenix.Router` when `--router` omitted | Likely | `relyra.install.ex:97-129` (currently always ambiguous) |
| Inject import + `saml_routes()` with `# --- Relyra SAML routes ---` marker | Likely | `test/phoenix/router_test.exs:1-12`, sigra `injector.ex` |
| Ambiguous cases: print only, no file modification | Confident | ROADMAP SC#2, `relyra.install.ex:108-114` |

### Doc navigation — `guides/overview.md` (DX-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Create job-shaped index: Day-1 / Day-2 / Reference | Likely | ROADMAP SC#3, assessment thread item (h) |
| Keep `main: "getting_started"`; add overview to extras near top | Likely | `mix.exs:122-151` |
| Link README Start Here to overview as nav hub | Likely | README footer-chase pattern `README.md:81-97` |

### BATTERIES_INCLUDED dedupe (DX-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Root `BATTERIES_INCLUDED.md` stays primary drift-tested artifact | Confident | `mix.exs` ci.docs, `relyra.batteries_included.ex` |
| `guides/batteries_included.md` becomes stub linking to root | Confident | ROADMAP SC#4, duplicate content in both files |
| Update generator: root artifact refs + include ADFS in scope | Confident | Generator line 20 lists 3 presets; README lists 4 |

### Test coverage
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `relyra_install_test.exs` with inject + ambiguous fallback cases | Confident | ROADMAP SC#2, current tests lack router coverage |
| Add overview.md to `ci.docs` | Confident | ROADMAP SC#3 manual verify + ci.docs pattern |

## Corrections Made

No corrections — all assumptions confirmed by user (option 1: "Yes, proceed").

## External Research

Not performed — codebase provided sufficient evidence for all areas.
