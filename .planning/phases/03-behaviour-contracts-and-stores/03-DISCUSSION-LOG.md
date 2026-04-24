# Phase 3: Behaviour Contracts and Stores - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-04-24
**Phase:** 03-behaviour-contracts-and-stores
**Mode:** assumptions
**Areas analyzed:** Public Behaviour Surface, Request Intent and Correlation Contract, Request/Replay Store Semantics, Multi-Tenant Resolver Decoupling, Phase 3 Delivery Sequence

## Assumptions Presented

### Public Behaviour Surface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 3 introduces five public behaviours as stable extension API while default adapters remain internal. | Confident | `lib/relyra/security/xml.ex`, `test/security/xml/seam_contract_test.exs`, `.planning/REQUIREMENTS.md`, `.planning/phases/02-protocol-and-signature-core/02-CONTEXT.md` |

### Request Intent and Correlation Contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Correlation remains strict/fail-closed, shifting source of truth to RequestStore-backed reads/consumes. | Confident | `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `test/protocol/consume_response_pipeline_test.exs`, `test/relyra_test.exs` |

### Request/Replay Store Semantics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Request/replay contracts require atomic consume semantics with ETS dev defaults and optional Ecto production adapters. | Likely | `.planning/REQUIREMENTS.md` (`SEC-06`, `EXT-02`, `EXT-03`), `lib/relyra/security/relay_state.ex`, absence of store modules under `lib/relyra/` |

### Multi-Tenant Resolver Decoupling
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| ConnectionResolver should supply plain map context to protocol core, preserving no framework/storage coupling. | Confident | `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra.ex`, `mix.exs`, `.planning/phases/02-protocol-and-signature-core/02-CONTEXT.md` |

### Phase 3 Delivery Sequence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep roadmap order contracts -> adapters -> consume integration to avoid contract churn. | Likely | `.planning/ROADMAP.md`, `test/security/xml/seam_contract_test.exs`, `test/protocol/consume_response_pipeline_test.exs` |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

- Atomic DB consume/upsert semantics for Ecto adapters: [PostgreSQL `INSERT ... ON CONFLICT`](https://www.postgresql.org/docs/current/sql-insert.html), [Ecto constraints and upserts](https://hexdocs.pm/ecto/constraints-and-upserts.html), [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html).
- ETS limitations for cluster-wide replay safety and owner/process lifecycle: [Erlang ETS manual](https://erlang.org/doc/man/ets.html).
