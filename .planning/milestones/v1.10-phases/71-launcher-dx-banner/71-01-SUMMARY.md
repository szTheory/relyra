---
phase: 71-launcher-dx-banner
plan: "01"
subsystem: developer-experience
tags: [make, bash, docker-compose, exunit, ci]
requires:
  - phase: 69-compose-split-fleet-proxy
    provides: solo and fleet Compose topology
  - phase: 70-keycloak-behind-the-proxy
    provides: final public route inventory
provides:
  - canonical Make launcher and complete route banner
  - thin six-verb scripts/demo compatibility adapter
  - fail-closed reset, reseed, nuke, and optional environment surface
affects: [phase-72-documentation, docker-dx, launcher]
tech-stack:
  added: []
  patterns: [runtime Make contract tests, shell-safe exported environment values]
key-files:
  created: [.env.example]
  modified: [Makefile, scripts/demo, test/docs/demo_guide_drift_test.exs]
key-decisions:
  - "Environment-derived launcher values are exported and expanded by the shell inside quotes, never interpolated into recipe syntax by Make."
  - "Passing runtime tests replace the tracer human checkpoint and permanently gate incomplete phases against required UAT."
patterns-established:
  - "Launcher commands are behavior-tested through GNU Make with PATH-isolated external-command fixtures."
  - "Destructive Docker volume removal exists only behind nuke confirmation or NUKE=1."
requirements-completed: [DX-01, DX-02]
coverage:
  - id: D1
    description: "Detached solo launch reaches one complete banner and suppresses it on Docker failure."
    requirement: DX-01
    verification:
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#Make CLI renders help, detached launch, and overridden browser origins"
        status: pass
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#failed detached startup preserves the Docker error and suppresses the banner"
        status: pass
    human_judgment: false
  - id: D2
    description: "Compatibility verbs, data refresh, nuke safety, and optional configuration share one launcher implementation."
    requirement: DX-02
    verification:
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#legacy demo verbs delegate exclusively to canonical Make targets"
        status: pass
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#reset, nuke, and optional environment configuration stay fail-closed"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-08-27
status: complete
---

# Phase 71 Plan 01: Canonical Launcher Summary

**One Make surface now owns detached startup, the route banner, legacy compatibility, safe data refresh, and explicitly confirmed destructive cleanup.**

## Accomplishments

- Added the canonical target inventory and fixed-order browser/route/walkthrough/topology banner.
- Replaced direct Docker logic in `scripts/demo` with six literal `exec make` mappings.
- Added fully optional commented environment examples and a fail-closed nuke contract.
- Migrated tracer review into recurring runtime tests and established the project-wide no-required-UAT policy.
- Hardened all environment-derived launcher values against shell-fragment interpretation.

## Task Commits

1. **Task 1 RED: launcher contract** — `09ae906`
2. **Task 1 GREEN: canonical launcher** — `b768408`
3. **Task 2 + automated checkpoint migration** — `80dc15d`

## Deviations from Plan

### Auto-fixed Issues

1. **Shell-syntax injection through Make expansion**
   - Runtime mutation testing proved a quote/semicolon-bearing `RELYRA_HOST` could escape an `echo` recipe.
   - Exported configuration now expands as quoted shell data; the regression test proves no command executes.

2. **Human tracer gate conflicted with the approved automation policy**
   - Replaced the checkpoint and host review with deterministic runtime fixtures in mandatory CI.

## Verification

- Focused launcher contract: 15 tests, 0 failures.
- `mix qa`: 782 tests, 0 failures.
- `mix ci.security`: all isolated suites and audits passed.

## Self-Check: PASSED

All scoped files exist; commits `09ae906`, `b768408`, and `80dc15d` are present; no human verification or UAT coverage entry remains.
