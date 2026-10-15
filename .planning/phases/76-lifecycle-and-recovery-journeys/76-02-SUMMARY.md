---
phase: 76-lifecycle-and-recovery-journeys
plan: 02
subsystem: auth
tags: [phoenix, ecto, tenant-isolation, saml, testing]
requires:
  - phase: 76-lifecycle-and-recovery-journeys
    provides: Reusable signed SP login driver and Northstar ACS lifecycle proof
provides:
  - Seven typed, sessionless ACS rejection cases plus a valid signed control
  - Paired Northstar and Harborline route journeys with scoped trace and replay evidence
  - Connection-specific LedgerLoop session receipt scenario keys
affects: [76-lifecycle-and-recovery-journeys]
actuals:
  tokens: 4676
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Independent signed response variants reach the same real ACS and assert exact typed failures without host receipts
    - Tenant-scoped LiveAdmin queries resolve only the owning organization's login audit traces
key-files:
  created:
    - demo/ledger_loop/test/ledger_loop_web/rejection_journeys_test.exs
    - demo/ledger_loop/test/ledger_loop_web/tenant_journeys_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex
key-decisions:
  - Harborline's active signing trust is fixture-owned and uses the existing local FakeIdP key; production trust policy is unchanged.
  - Receipt scenario keys use the verified principal's connection ID exposed by LoginResult, preserving the published callback signature.
requirements-completed: [JOUR-02, JOUR-04]
coverage:
  - id: D1
    description: Seven representative invalid SAML response classes are rejected at the configured ACS with their exact error types and no receipt or session cookie; a valid signed response remains accepted.
    requirement: JOUR-02
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/ledger_loop_web/rejection_journeys_test.exs#the ACS returns typed, sessionless rejections for each representative invalid response"
        status: pass
      - kind: integration
        ref: "demo/ledger_loop/test/ledger_loop_web/rejection_journeys_test.exs#the same configured ACS still accepts a valid signed response"
        status: pass
    human_judgment: false
  - id: D2
    description: Northstar and Harborline retain separate verified receipts, request intents, replay keys, login audit traces, and administrator query scopes; foreign connection access is denied.
    requirement: JOUR-04
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/ledger_loop_web/tenant_journeys_test.exs#paired signed ACS journeys preserve tenant-owned identity, role, replay, trace and admin scope"
        status: pass
      - kind: integration
        ref: "mix cmd --cd demo/ledger_loop mix test test/twin/organization_test.exs test/twin/reset_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 11 min
completed: 2026-09-26
status: complete
---

# Phase 76 Plan 02: Typed Rejection and Tenant Isolation Summary

**LedgerLoop now proves typed ACS failures and connection-scoped Northstar and Harborline login outcomes through real Phoenix routes.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-26T14:01:30Z
- **Completed:** 2026-09-26T14:12:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added route-level checks for digest, signature, issuer, audience, destination, time, and request-correlation failures. Each checks the source-defined error type, leaves the receipt count unchanged, and emits no session cookie; a valid signed control still succeeds.
- Added Harborline's fixture-owned active signing certificate and paired Northstar/Harborline journeys that verify tenant, group, receipt, consumed request intent, replay row, login audit, hashed trace, and scoped admin-query ownership.
- Proved wrong-tenant issuer and subject attempts fail at the ACS without creating another receipt. Scenario role assertions retain the seeded administrator allow and end-user deny expectations.

## Task Commits

The original implementation predates plan-scoped commit subjects. Its hash and the scoped route regression are preserved below.

## Historical Execution Commit

- `b0177f2` — rejection matrix, paired tenant journeys, and receipt ownership implementation.

## Plan-Scoped Follow-Up

- `1ac2b3f` — assert the accepted ACS control receipt belongs to its verified connection.

## Files Created/Modified

- `demo/ledger_loop/test/ledger_loop_web/rejection_journeys_test.exs` — typed invalid-input matrix and valid signed control.
- `demo/ledger_loop/test/ledger_loop_web/tenant_journeys_test.exs` — paired login, replay, trace, query-scope, and cross-tenant rejection coverage.
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — Harborline-only active demo signing certificate.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — documents rebuilding the catalog-owned Harborline trust row through the fixture-scoped reset.
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` — connection-specific receipt scenario key from verified principal context.

## Decisions Made

- Keep Harborline trust isolated to its local test fixture and reuse the existing demo signer key.
- Read connection ownership from the verified principal when building a LedgerLoop receipt; do not change any Relyra behaviour callback or public API.
- Treat a wrong subject as a typed ACS rejection without asserting a consume-path trace: the host mapper runs after the consume telemetry span.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve verified connection ownership in host receipts**

- **Found during:** Task 2 (paired tenant route journey)
- **Issue:** LedgerLoop's session adapter read `connection_id` directly from `%Relyra.LoginResult{}`, where the value is absent; all receipts used `session_unknown_*`.
- **Fix:** Read `connection_id` from the verified `LoginResult.principal` and use it in the receipt scenario key. The plan's declared source scope was extended to include the demo-owned adapter; the callback signature and Relyra public API are unchanged.
- **Files modified:** `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex`, `.planning/phases/76-lifecycle-and-recovery-journeys/76-02-PLAN.md`
- **Verification:** The tenant journey asserts both receipt keys contain their owning connection ID; focused tenant and regression suites pass.
- **Committed in:** `b0177f2` (implementation); plan scope is included in the metadata completion commit.

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The correction closes the planned connection-to-receipt ownership link without changing a published behaviour or production trust policy.

## Issues Encountered

- Host mapping errors such as `:user_not_found` occur after `Relyra.consume_response/3` finishes, so the consume-path trace handler does not persist that rejection. The ACS response is asserted for the exact type and absence of a new receipt; trace assertions cover failures within the consume path.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 76-02 is complete. Plan 76-04 can reuse the route driver and scoped trace patterns for incident recovery.

---
*Phase: 76-lifecycle-and-recovery-journeys*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Summary artifact contains passing automated coverage for both requirements.
- Implementation commit `b0177f2` exists and contains only the five implementation files listed above.
- Plan-scoped route regression commit `1ac2b3f` exists and passes its focused owner.
- The requirement evidence uses stable test owners; no manual completion check is required.
