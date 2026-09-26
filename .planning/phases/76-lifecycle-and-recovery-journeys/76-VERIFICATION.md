---
phase: 76-lifecycle-and-recovery-journeys
verified: 2026-09-26T16:36:06Z
status: passed
score: 5/5
covered_files:
  - .github/workflows/demo-app-e2e.yml
  - .github/workflows/real-idp-canary.yml
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
  - .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md
  - .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-01-PLAN.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-01-SUMMARY.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-02-PLAN.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-02-SUMMARY.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-03-PLAN.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-03-SUMMARY.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-04-PLAN.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-04-SUMMARY.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-05-PLAN.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-05-SUMMARY.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-CONTEXT.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-PATTERNS.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-RESEARCH.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-USER-SETUP.md
  - .planning/phases/76-lifecycle-and-recovery-journeys/76-VALIDATION.md
  - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
  - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
  - demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex
  - demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex
  - demo/ledger_loop/test/browser/real_idp_canary.spec.ts
  - demo/ledger_loop/test/browser/trace_visual.spec.ts
  - demo/ledger_loop/test/ledger_loop/demo/trust_lifecycle_test.exs
  - demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs
  - demo/ledger_loop/test/ledger_loop_web/rejection_journeys_test.exs
  - demo/ledger_loop/test/ledger_loop_web/tenant_journeys_test.exs
  - demo/ledger_loop/test/ledger_loop_web/trust_lifecycle_live_test.exs
  - demo/ledger_loop/test/support/lifecycle_flow.ex
  - demo/ledger_loop/test/twin/incident_recovery_test.exs
  - demo/ledger_loop/test/twin/incident_timeline_test.exs
  - lib/relyra.ex
  - lib/relyra/protocol/validation_pipeline.ex
  - lib/relyra/request_store.ex
  - lib/relyra/request_store/ecto.ex
  - mix.exs
  - playwright.real-idp.config.mjs
  - scripts/test_real_idp_canary.sh
  - scripts/test_trace_visual_e2e.sh
  - scripts/test_trace_visual_status_contract.sh
  - test/adoption/evidence_contract_test.exs
  - test/adoption/external_canary_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
covered_digest: "v1:sha256:728aebea481944c3010e343f7916a7464256b7a719fdd8ec8f7b69ea7ed36950"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 7
  total: 7
  not_honored: []
---

# Phase 76: Lifecycle and Recovery Journeys Verification Report

**Phase Goal:** End users, tenant admins, security reviewers, and operators can complete or diagnose the high-risk workflows a real adopter will depend on.

**Verified:** 2026-09-26T16:36:06Z  
**Status:** PASSED

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A verified SP-initiated login crosses the LedgerLoop router and configured behavior seams, maps the Northstar identity and role, and creates the adopter receipt. | ✓ VERIFIED | The lifecycle route owner signs through the test IdP, posts through the configured ACS, and checks mapped principal, tenant, role, request intent, replay state, trace, and exactly one receipt. |
| 2 | Representative digest, signature, issuer, audience, destination, time, correlation, and replay failures produce stable typed rejections without establishing adopter session state. | ✓ VERIFIED | The rejection matrix checks each typed result and no new receipt or session cookie; a valid signed control succeeds. The replay owner rejects a byte-identical accepted response while a fresh login remains accepted. |
| 3 | Northstar and Harborline remain isolated across resolver, mapping, replay, session receipt, trace, audit, and admin authorization outcomes. | ✓ VERIFIED | Paired real-route journeys assert tenant-owned principals, receipts, replay records, traces, and admin query scope, including wrong-tenant rejection. |
| 4 | Tenant admins review metadata, enable connections, stage rollover, and recover trust with co-committed redaction-safe audit evidence. | ✓ VERIFIED | Mounted LiveAdmin and domain tests exercise owner and foreign-tenant scope, metadata import, enablement, certificate activation/recovery, audit state, injected stale-write rollback, and retry. |
| 5 | Operators diagnose and recover the seeded incident from correlated redacted evidence, and browser/scheduled canaries expose safe failure ownership. | ✓ VERIFIED | The incident route moves from a real failed ACS attempt through scoped diagnosis, audited trust repair, and a verified retry. Browser and scheduled canary contracts enforce fixed safe status, named ownership, recovery references, and independent failure reporting. |

**Score:** 5/5 roadmap success criteria verified; 0 behavior-unverified.

### Plan-Specific Must-Haves

| Plan | Result | Evidence |
|---|---|---|
| 76-01 | ✓ VERIFIED | Signed SP login produces the mapped receipt; exact accepted-response replay is rejected without a second receipt. |
| 76-02 | ✓ VERIFIED | Typed rejection/no-session matrix and paired tenant route, receipt, replay, trace, and authorization isolation pass. |
| 76-03 | ✓ VERIFIED | LiveAdmin trust changes and domain recovery prove tenant scoping, audit co-commit, rollback, and retry. |
| 76-04 | ✓ VERIFIED | Seeded support incident has correlated diagnosis, redacted export, audited remediation, successful retry, and a passing status-only browser lane. |
| 76-05 | ✓ VERIFIED | The scheduled IdP workflow is independent of merge gates; deterministic tests prove origin checks, fail-closed setup, safe artifacts, and named response ownership. |

### Required Artifacts

| Artifact | Status | Details |
|---|---|---|
| LedgerLoop lifecycle route and fixture owners | ✓ VERIFIED | Login, replay, typed rejection, tenant isolation, and trust lifecycle owners are wired into the demo evidence lane. |
| Incident recovery and browser status owners | ✓ VERIFIED | Recovery and timeline tests cover the seeded incident; the browser workflow retains a fixed status artifact with owner and recovery information. |
| Real IdP canary workflow and runner | ✓ VERIFIED | Schedule/dispatch-only trigger, exact origin checks before credential entry, disabled recordings, fail-closed configuration, and status-only artifact. |
| Mandatory external-canary evidence owner | ✓ VERIFIED | The fresh-process ci.evidence alias includes the contract suite and checks workflow separation, artifact schema, failure behavior, and ownership. |
| Phase 73 proof refresh | ✓ VERIFIED | Proof set phase73-a47d8b7a24e35bcf is captured and its final security/validation records match; the reconciliation replay passes. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| SP login route | Verified adopter receipt | Configured request store, ACS validation, mapper, and session adapter | ✓ WIRED | The route test follows signed response verification through mapping and exact receipt creation. |
| Accepted response | Replay rejection | Trusted request/connection identity and configured replay adapter | ✓ WIRED | The exact retry is rejected without another receipt; response document connection data cannot choose replay scope. |
| Tenant fixtures | Scoped route/admin outcomes | Organization-owned resolver, mapper, trace, audit, and admin query | ✓ WIRED | Paired Northstar and Harborline journeys verify owner scope and reject cross-tenant access. |
| Trust transition | Audit evidence | Existing mutation and audit transaction seams | ✓ WIRED | Successful changes co-commit redacted audit; injected stale write rolls back and succeeds on retry. |
| Scheduled workflow | Browser runner and safe evidence | Owner environment → origin-bound Playwright → fixed status JSON | ✓ WIRED | Missing setup and simulated provider failure remain visible; the artifact contains only allowlisted status metadata. |
| Mandatory evidence lane | External-canary policy owner | ci.evidence alias → external_canary_contract_test.exs | ✓ WIRED | Contract coverage runs without contacting a provider and the scheduled workflow has no required-check dependency. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| LedgerLoop lifecycle, tenant, trust, and incident journeys | mix ci.demo_app | 106 tests, 0 failures | ✓ PASS |
| Deterministic acceptance ownership and canary contract | mix ci.evidence | 134 tests, 0 failures | ✓ PASS |
| Browser trace status lane | npm run demo:trace-visual | 1 Playwright test passed | ✓ PASS |
| Canary runner failure boundary | bash -n scripts/test_real_idp_canary.sh; bash scripts/test_real_idp_canary.sh --contract-probe | Passed without network or credentials | ✓ PASS |
| Phase 73 proof, owners, evidence runs, and security constituents | mix ci.phase73.reconciliation | 1 test, 0 failures; 5 excluded; 612.3 s | ✓ PASS |
| Full repository warnings gate | mix test --warnings-as-errors | 935 tests, 0 failures; 10 excluded; 574.7 s | ✓ PASS |
| Formatting | mix format --check-formatted | Passed | ✓ PASS |

The reconciliation replay includes each security constituent as a separate fresh Mix test process, preserving the project security gate contract.

### Requirements Coverage

| Requirement | Source plan | Status | Evidence |
|---|---|---|---|
| JOUR-01 | 76-01 | ✓ SATISFIED | Verified Northstar principal and role produce exactly one adopter-owned receipt through the configured ACS. |
| JOUR-02 | 76-02 | ✓ SATISFIED | Digest, signature, issuer, audience, destination, time, and correlation failures are typed and sessionless. |
| JOUR-03 | 76-01 | ✓ SATISFIED | An accepted assertion replay is rejected without creating another receipt. |
| JOUR-04 | 76-02 | ✓ SATISFIED | Paired organizations remain isolated across route outcomes, replay, receipts, traces, and admin scope. |
| JOUR-05 | 76-03 | ✓ SATISFIED | Tenant-scoped metadata, enablement, rollover, and recovery produce co-committed redaction-safe audit evidence. |
| JOUR-06 | 76-04 | ✓ SATISFIED | The seeded incident is diagnosed and recovered through correlated trace/audit evidence and a verified retry. |
| EVID-03 | 76-05 | ✓ SATISFIED | Scheduled provider health stays outside deterministic merge gates; owner, responder, recovery reference, and safe failure artifact are contract-tested. |

No orphaned requirements are mapped to Phase 76.

### Decision Coverage

All seven decisions in 76-CONTEXT.md are reflected in the route, tenant, trust, incident, and canary evidence. No decision overrides were applied.

### Human Verification Required

None. All Phase 76 acceptance criteria have deterministic automated evidence. The live IdP workflow has not been run against a real provider because the owner-managed staging endpoint and credentials are not present; until setup is complete it reports configuration_incomplete. This does not block deterministic phase acceptance.

### Gaps Summary

No requirement or roadmap success criterion remains unverified. A simultaneous two-admin certificate transition remains an automation gap because the current SQL Sandbox fixture cannot coordinate independent transaction owners; the deterministic stale-write rollback and retry path is covered and the limitation is recorded in WINDOWS.md. Real IdP availability remains an owner-managed setup item described in 76-USER-SETUP.md.

---

_Verified: 2026-09-26T16:36:06Z_  
_Verifier: GSD phase execution
