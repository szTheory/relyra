# Phase 47: Onboarding truth — Getting Started & production Ecto path - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 47-onboarding-truth-getting-started-production-ecto-path
**Mode:** assumptions
**Areas analyzed:** TestSupport macro path, Production Ecto linked guide, Cross-doc sync & CI gates

## Assumptions Presented

### TestSupport macro as §3 primary path (ADOPT-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Rewrite §3 around `use Relyra.TestSupport` + `setup_saml_connection/2` + `post_saml_response/2`, citing `test/test_support_demo_test.exs` | Likely | `test/test_support_demo_test.exs`, `lib/relyra/test_support.ex` |
| Demote low-level builder/sign snippet to appendix | Likely | ROADMAP SC#1; current §3 gap |
| Document minimal demo router/controller pattern in §3 | Likely | `post_saml_response/3` requires endpoint (`lib/relyra/test_support.ex:67-76`) |

### Production Ecto path as linked guide (ADOPT-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Create `guides/production_ecto_path.md`; link from §5 and overview Day-2 | Confident | ROADMAP SC#2; Phase 46 overview hub |
| Migrations via `Ecto.Migrator.run/4` from deps `priv/repo/migrations/` | Likely | `test/support/migration_case.ex`; install does not copy migrations |
| Document config upgrade Default/ETS → Ecto adapters | Confident | `lib/mix/tasks/relyra.install.ex:81-84` |
| Replay warning via `prod_runtime_ets_warning: true`, not `Mix.env()` | Likely | `lib/relyra/replay_store/ets.ex:99-100`; `test/security/stores/replay_store_ets_test.exs` |

### Cross-doc sync & CI gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Update overview Day-1 step 2 + Day-2 Ecto link | Likely | `guides/overview.md:13`; ROADMAP SC#2 |
| Add `cmd test -f guides/production_ecto_path.md` to ci.docs; no new drift test | Likely | Phase 46 ci.docs pattern; ROADMAP SC#3 |
| Defer case study/runbook FakeIdP reference updates | Unclear | Not in Phase 47 success criteria |

## Corrections Made

No corrections — all assumptions confirmed. User selected "Yes, proceed."

## External Research

None required — codebase evidence sufficient.
