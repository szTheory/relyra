# Phase 48: Operator completeness — incident playbook trace tools - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 48-operator-completeness-incident-playbook-trace-tools
**Mode:** assumptions
**Areas analyzed:** Playbook centerpiece tables, Scenario when-to-use wiring, Cross-doc sync, CLI contract & tool positioning, CI gates

## Assumptions Presented

### Playbook centerpiece tables
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add login trace as sixth Evidence surfaces row; extend LiveView routes and Mix tasks tables; fix "7 hand-tools" → 8; replace Scenario 3 stale v1.4 replay text | Confident | `guides/operations/incident_playbook.md`, `lib/relyra/live_admin/router.ex`, `lib/mix/tasks/relyra.trace.ex` |

### Scenario when-to-use wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Wire login trace into Diagnose steps for Scenarios 3, 4, 5, and 6 (≥2 required by ROADMAP) | Confident | `ConnectionTraceLive` step labels; Scenario 3 lines 201–206 contradict shipped trace |

### Cross-doc sync
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add Day-2 bullet in `guides/overview.md` and §5 link in `guides/getting_started.md` | Likely | ROADMAP SC#2; Phase 47 D-09/D-05 hub pattern |

### CLI contract & tool positioning
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Document full CLI with required `--repo`; default `--last` 20; distinguish LiveView vs CLI vs diagnostic bundle in "When in doubt" | Confident | `lib/mix/tasks/relyra.trace.ex`; incident_playbook "When in doubt" conflates diagnostic with trace |

### CI gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Presence guard only; no new drift test; login_trace_test stays in ci.security | Likely | Phase 47 D-11; `mix.exs` ci.docs alias |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## External Research

Not performed — codebase provided sufficient evidence for all assumptions.
