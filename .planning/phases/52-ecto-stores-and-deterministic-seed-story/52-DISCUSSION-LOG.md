# Phase 52: Ecto Stores And Deterministic Seed Story - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-12
**Phase:** 52-ecto-stores-and-deterministic-seed-story
**Mode:** assumptions
**Areas analyzed:** Demo Data Model, Migration Strategy, Store Wiring, Seeded Relyra States, Login Proof Boundary

## Assumptions Presented

### Demo Data Model

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add LedgerLoop-owned schemas and a deterministic reset module for tenant/user/group/membership/SAML-identity demo data; seed stable IDs, timestamps, and slugs instead of random fixtures. | Likely | `demo/ledger_loop/priv/repo/seeds.exs`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/51-demo-app-foundation/51-CONTEXT.md` |

### Migration Strategy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Run Relyra's shipped migrations from `../../priv/repo/migrations` before demo-owned migrations; do not copy dependency migrations into `demo/ledger_loop`. | Confident | `priv/repo/migrations/`, `test/support/migration_case.ex`, `demo/ledger_loop/priv/repo/migrations/.formatter.exs` |

### Store Wiring

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use `Relyra.ConnectionResolver.Ecto` with `LedgerLoop.Repo`, but add LedgerLoop wrapper modules for request and replay stores so each adapter receives a fixed, separate host-owned table name. | Confident | `lib/relyra/phoenix/controllers/*_controller.ex`, `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex`, `.planning/REQUIREMENTS.md` |

### Seeded Relyra States

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Seed four visible connection states: enabled happy path, draft/missing-metadata, staged-certificate, and failure/support. Use Relyra Ecto schemas/commands plus `AuditWriter` where practical, and represent support traces as `domain: :login` audit rows rather than trust-mutation rows. | Likely | `.planning/ROADMAP.md`, `lib/relyra/live_admin/query.ex`, `lib/relyra/ecto/audit_writer.ex`, `test/relyra/live_admin/phase15_ui_contract_test.exs` |

### Login Proof Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 52 should prove Ecto request/replay behavior with a non-browser integration test using real signed test support, but leave browser FakeIdP UX and receipts to Phases 54/53. | Likely | `.planning/ROADMAP.md`, `test/adoption/journey_04_ecto_production_path_test.exs`, `test/support/adoption_fixtures.ex`, `lib/relyra/test_support/fake_idp.ex` |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

No external research was performed. The codebase and planning artifacts provided enough evidence.
