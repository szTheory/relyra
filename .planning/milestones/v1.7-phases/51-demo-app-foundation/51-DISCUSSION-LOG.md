# Phase 51: demo-app-foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-12
**Phase:** 51-demo-app-foundation
**Mode:** assumptions
**Areas analyzed:** Demo App Boundary, UX And Route Shape, Existing Assets To Reuse, Packaging And Repo Integration, Store And Login Proof Sequencing

## Assumptions Presented

### Demo App Boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 51 should create only the conventional Phoenix app foundation at `demo/ledger_loop`, with Relyra as a local path dependency, visible first screen, route mounts, and health/readiness. It should not seed the full Northstar story or wire the durable SAML happy path yet. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md` |

### UX And Route Shape
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The first screen should be the actual LedgerLoop workspace shell, not a landing page, with placeholder or early route destinations for setup/login/admin/support as needed. `/saml` is the host-owned SAML scope and `/relyra/admin` is the operator route scope. | Confident | `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md`, `lib/relyra/phoenix/router.ex`, `lib/relyra/live_admin/router.ex` |

### Existing Assets To Reuse
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 51 should reuse patterns from existing adoption fixtures and LiveAdmin mounting, but should not copy test-only modules wholesale into the demo. Test-only assets are references, not production demo code. | Likely | `test/fixtures/demo_host/`, `test/adoption/journey_01_install_parity_test.exs`, `test/support/live_admin_test_support.ex`, `examples/quickstart.exs`, `lib/relyra/test_support.ex` |

### Packaging And Repo Integration
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The demo app should stay repo-local and excluded from Hex by package whitelist, not by fragile ignore files. Phase 51 should make exclusion inspectable through `mix.exs` package files and avoid adding `demo/` to package output. | Confident | `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/milestones/v1.5-phases/41-pre-publish-hygiene-tech-debt-sweep-security-hardening/41-CONTEXT.md` |

### Store And Login Proof Sequencing
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 51 should expose the integration points for later Ecto/FakeIdP proof, but leave actual Ecto request/replay store wiring and browser SAML login to later phases. | Confident | `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex`, `lib/relyra/connection_resolver/ecto.ex`, `test/adoption/journey_04_ecto_production_path_test.exs`, `test/support/adoption_fixtures.ex`, `.planning/ROADMAP.md` |

## Corrections Made

No corrections - all assumptions confirmed.
