# Phase 78: CI Efficiency and Reliability - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-09-27
**Phase:** 78-ci-efficiency-and-reliability
**Mode:** assumptions
**Areas analyzed:** Mandatory Lane Ownership, Measured Optimization, Workflow Policy and Failure Evidence, Gate Integrity and Clean-State Completion

## Assumptions Presented

### Mandatory Lane Ownership
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep focused named lanes and map every mandatory requirement to exactly one owning lane; preserve documented intentional independent defenses. | Likely | `.planning/ROADMAP.md`; `mix.exs`; `.github/workflows/security-gates.yml`; `test/adoption/package_consumer_ci_contract_test.exs`; `test/support/adoption_evidence.ex` |

### Measured Optimization
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Base optimization on multiple current runs, preserve clean-room consumer isolation, and change overlapping work or setup only when measurements justify it. | Likely | `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md`; `mix.exs`; `scripts/check_clean_room_consumer.sh` |

### Workflow Policy and Failure Evidence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Apply least-privilege permissions, non-colliding concurrency, clear names, current action pins, and bounded failure artifacts to mandatory workflows; keep remote required-check changes in Phase 79. | Likely | `.github/workflows/security-gates.yml`; `.github/workflows/demo-app-ci.yml`; `.github/workflows/demo-app-e2e.yml`; `.github/workflows/fleet-proxy-e2e.yml`; `.github/workflows/planning-pr-checks.yml`; `.planning/REQUIREMENTS.md` |

### Gate Integrity and Clean-State Completion
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve fresh-process security suites and standalone GATE-02; include the current lifecycle regression in clean-state completion; keep real-provider checks as scheduled canaries. | Confident | `mix.exs`; `test/security/ci_gate_integrity_test.exs`; `.github/workflows/security-gates.yml`; `.planning/STATE.md`; `.planning/phases/76-lifecycle-and-recovery-journeys/76-CONTEXT.md` |

## Corrections Made

No corrections — the user confirmed all assumptions with “Yes, proceed.”

## External Research

- Current official releases as of 2026-09-27: `actions/checkout@v7`, `actions/setup-node@v7`, `actions/cache@v6`, and `actions/upload-artifact@v7`; `erlef/setup-beam@v1` remains the current major. Verify exact releases and runner compatibility again before editing pins. Sources: [checkout releases](https://github.com/actions/checkout/releases/latest), [setup-node releases](https://github.com/actions/setup-node/releases/latest), [cache releases](https://github.com/actions/cache/releases/latest), [upload-artifact releases](https://github.com/actions/upload-artifact/releases/latest), [setup-beam releases](https://github.com/erlef/setup-beam/releases/latest).
- GitHub cache lookup supports partial restore keys and default-branch scope; treat restored caches as untrusted warm starts, include toolchain identity for compiled Mix outputs, and continue locked installs. Source: [GitHub dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching). The recommendation about including the Elixir/OTP tuple in compiled `_build` keys is a repo-specific reliability inference.
- GitHub concurrency groups can collide across workflows; a new pending run replaces the prior pending run, and `cancel-in-progress` cancels the active run. Use workflow-qualified groups and avoid canceling main runs due to PR activity. Source: [GitHub concurrency](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency).
