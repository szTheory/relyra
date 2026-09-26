---
phase: 76-lifecycle-and-recovery-journeys
plan: 05
subsystem: testing
tags: [saml, playwright, github-actions, evidence-contract, canary]
requires:
  - phase: 76-lifecycle-and-recovery-journeys
    provides: LedgerLoop login, rejection, tenant isolation, trust lifecycle, and incident recovery journeys
provides:
  - Independently scheduled real-IdP canary with fail-closed setup and status-only artifacts
  - Mandatory automated contract for canary separation, safe evidence, and named ownership
  - Refreshed Phase 73 source-bound reconciliation proof for the completed Phase 76 lifecycle state
affects: [77-craftsmanship, ci.evidence, ci.phase73.reconciliation]
actuals:
  tokens: 8600
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - Exact HTTPS origin checks precede canary credential entry; only allowlisted status metadata persists
    - External health checks remain independent of deterministic merge acceptance
key-files:
  created: [.github/workflows/real-idp-canary.yml, demo/ledger_loop/test/browser/real_idp_canary.spec.ts, playwright.real-idp.config.mjs, scripts/test_real_idp_canary.sh, test/adoption/external_canary_contract_test.exs, .planning/phases/76-lifecycle-and-recovery-journeys/76-USER-SETUP.md]
  modified: [mix.exs, test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs, test/governance/milestone_scope_test.exs, .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json, .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md, .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md]
key-decisions:
  - "Keep provider availability on schedule or explicit dispatch, with no dependency edge into required PR/main acceptance."
  - "Treat missing owner-managed IdP setup as a visible configuration_incomplete service-health result; it does not block deterministic phase acceptance."
  - "Refresh the Phase 73 proof after the active governance test was extended to accept the ordered Phase 77 planning frontier."
patterns-established:
  - "Browser canary artifacts contain a fixed, bounded status schema and have recordings disabled."
  - "A no-network contract probe exercises missing configuration and simulated provider failure."
requirements-completed: [EVID-03]
coverage:
  - id: D1
    description: "The scheduled real-IdP browser canary requires exact HTTPS origins before credential entry and verifies the return to the configured SP."
    requirement: EVID-03
    verification:
      - kind: integration
        ref: "test/adoption/external_canary_contract_test.exs#origin, status, and artifact contract"
        status: pass
      - kind: integration
        ref: "bash -n scripts/test_real_idp_canary.sh && bash scripts/test_real_idp_canary.sh --contract-probe"
        status: pass
    human_judgment: false
  - id: D2
    description: "Provider availability is separate from mandatory deterministic CI and failures retain only allowlisted status metadata with named ownership and recovery information."
    requirement: EVID-03
    verification:
      - kind: integration
        ref: "mix ci.evidence (134 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix ci.phase73.reconciliation (1 test, 0 failures; 5 excluded)"
        status: pass
    human_judgment: false
duration: 73min
completed: 2026-09-26
status: complete
---

# Phase 76 Plan 05: Scheduled Provider Canary Summary

**The real-IdP canary now fails visibly when owner setup is absent and keeps provider health outside deterministic merge acceptance.**

## Performance

- **Duration:** 73 min
- **Started:** 2026-09-26T15:10:19Z
- **Completed:** 2026-09-26T16:23:16Z
- **Tasks:** 2
- **Files modified:** 20 across the canary, evidence contract, and reconciliation closeout

## Accomplishments

- Added a schedule/dispatch-only GitHub Actions workflow with read-only repository permission, a named environment, service and credential owners, responder, recovery reference, and seven-day status-only artifact retention.
- Added an origin-bound Playwright login that checks the exact configured IdP origin before entering credentials, then verifies the return to the approved LedgerLoop origin and authenticated workspace. Screenshots, video, and traces are disabled.
- Added fail-closed configuration checks and an isolated no-network probe for missing setup and simulated provider failure. The runner emits only allowlisted status fields; provider URLs, page data, credentials, SAML payloads, cookies, and browser recordings are not retained.
- Added the deterministic ci.evidence owner, ledger entry, and fixtures proving trigger separation, safe status output, ownership, and the absence of a dependency from mandatory merge checks.
- Refreshed the Phase 73 proof set phase73-a47d8b7a24e35bcf and appended its final security and validation records. The isolated replay passed all 21 focused owners, three evidence runs, and 13 security constituents.

## Task Commits

1. **Task 1: Run an origin-bound real-provider login on an independent schedule** — 3b3a464.
2. **Task 2: Enforce canary separation and safe failure ownership in mandatory evidence CI** — 494e33e.
3. **Task 2 follow-up: Accept the next milestone planning state in governance evidence** — c650d16.

The Phase 73 proof/report refresh was committed separately as 386b6a5.

## Files Created/Modified

- `.github/workflows/real-idp-canary.yml`, `demo/ledger_loop/test/browser/real_idp_canary.spec.ts`, `playwright.real-idp.config.mjs`, and `scripts/test_real_idp_canary.sh` — independent external health workflow, origin-bound login, and bounded status output.
- `test/adoption/external_canary_contract_test.exs`, `test/adoption/evidence_contract_test.exs`, `test/support/adoption_evidence.ex`, and `mix.exs` — mandatory deterministic policy ownership and evidence registration.
- `test/governance/milestone_scope_test.exs` — ordered Phase 76 completion and Phase 77 planning lifecycle acceptance.
- `.planning/phases/76-lifecycle-and-recovery-journeys/76-USER-SETUP.md` — owner-managed environment and staging IdP setup steps.
- `.planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json`, `73-SECURITY.md`, and `73-VALIDATION.md` — current proof and append-only final reconciliation records.

## Decisions Made

- External provider status is an operational signal only. Its scheduled job has no path into ci.evidence, ci.demo_app, or required PR/main checks.
- Missing endpoint, account, owner, responder, or runbook reports configuration_incomplete; no live provider success is claimed before the owner configures staging.
- The current proof refresh includes the Phase 77 planning frontier and preserves historical Phase 73 report entries.

## Deviations from Plan

### Automated governance closure

The Phase 73 replay initially rejected the newly ordered Phase 77 planning state. Plan scope was extended to update the lifecycle regression owner, then capture and replay a current Phase 73 proof. The owner and proof refresh passed and were committed in c650d16 and 386b6a5 respectively.

**Total deviations:** 1 automated governance compatibility repair.  
**Impact on plan:** The mandatory evidence and reconciliation contracts now accept the completed Phase 76 state and next Phase 77 planning state without relaxing phase ordering.

## Automated Results

- mix ci.evidence — 134 tests, 0 failures.
- mix ci.demo_app — 106 tests, 0 failures.
- npm run demo:trace-visual — 1 Playwright test passed.
- bash -n scripts/test_real_idp_canary.sh && bash scripts/test_real_idp_canary.sh --contract-probe — passed.
- mix ci.phase73.reconciliation — 1 test, 0 failures (5 excluded); all focused owners, evidence runs, and security constituents passed.
- mix test --warnings-as-errors — 935 tests, 0 failures (10 excluded).
- mix format --check-formatted — passed.

## User Setup Required

The live provider signal needs external configuration. See 76-USER-SETUP.md for the owner-managed staging connection, GitHub environment values, dedicated canary account, and dispatch verification. Until configured, the scheduled run truthfully reports configuration_incomplete; this is not a deterministic phase acceptance gate.

## Next Phase Readiness

All five Phase 76 plans and requirements are covered by automated evidence. Phase 77 is ready for discussion and planning. The live IdP connection remains an owner setup item, and the simultaneous two-admin certificate race remains recorded as an automation gap; stale-write rollback and retry are covered deterministically.

---
*Phase: 76-lifecycle-and-recovery-journeys*  
*Completed: 2026-09-26*

## Self-Check: PASSED

- All five Phase 76 plans have matching summaries; the phase-completeness check reports 5/5 complete.
- Task commits `3b3a464`, `494e33e`, and `c650d16`, plus proof refresh `386b6a5`, exist in Git history.
- `mix ci.evidence`, `mix ci.demo_app`, the Phase 73 reconciliation replay, the full warnings-as-errors suite, and the format check all passed.
