# Phase 42: Stepwise login-trace LiveView - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 42-Stepwise login-trace LiveView
**Mode:** assumptions
**Areas analyzed:** LiveView routing & scaffold, Trace persistence, Step catalog & display, Redaction & shared export, Headless CLI, Empty state & bounds, Security test wiring

## Assumptions Presented

### LiveView routing & scaffold
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add trace route mirroring ConnectionMetadataLive in router.ex; link from connection_detail.ex | Confident | `router.ex`, `connection_metadata_live.ex`, `connection_detail.ex`, `phase15_ui_contract_test.exs` |

### Trace persistence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No persistence exists today; add LoginTrace telemetry handler → audit ledger with domain :login, bounded after_summary | Unclear → confirmed as recommended | `login_result.ex` (validation_trace unused), `telemetry.ex`, `audit_event.ex`, `audit_writer.ex`, `relyra.ex` normalize_consume_result |

### Step catalog & display
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Six consume-path rows (decode, validate, signature, replay, user_map, session_establish); not login/authn_request spans | Likely | Span sites in binding.ex, validation_pipeline.ex, signature.ex, replay_store.ex, user_mapper.ex, session_adapter.ex |

### Redaction & shared export
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend AllowList (or sibling Export module); same path for LiveView and CLI | Confident | `allow_list.ex`, `audit_writer.ex` @sensitive_keys, assessment thread precedent |

### Headless CLI
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| mix relyra.trace following relyra.diagnostic pattern; --last default 20 | Confident / Likely | `relyra.diagnostic.ex`, TRACE-03 |

### Empty state & bounds
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Default last 20; no pagination; friendly empty state | Likely | Requirements silent on N; assessment LOC estimate |

### Security test wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| login_trace_test.exs + ci_gate_integrity @gated_suites + cmd mix test line | Confident | Phase 30 hollow-gate, `ci_gate_integrity_test.exs` |

## Corrections Made

### Persistence model (post-discussion refinement)
- **Original assumption:** `:login` audit domain (confirmed at discuss-phase).
- **Refinement:** Rejected `cause: "login_trace"` on existing domains after deep research (audit timeline pollution, LiveAdmin filter mismatch, lifecycle action misuse).
- **Locked additions:** `:succeeded`/`:failed` actions; `cause` for flow context only; default-on LoginTrace handler; exclude `:login` from connection-detail audit preload.

## Initial confirmation

All baseline assumptions confirmed via "Yes, proceed" before persistence refinement.

## Auto-Resolved

Not applicable — interactive assumptions mode, user confirmed all assumptions.

## External Research

None performed — codebase provided sufficient evidence.
