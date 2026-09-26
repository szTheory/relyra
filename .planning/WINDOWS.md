---
schema_version: 1
open_count: 3
waived_count: 1
fixed_count: 26
total_count: 30
last_updated: 2026-09-26T13:15:00.284Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 70 | lint-warning | demo/ledger_loop/lib/ledger_loop_web/live/setup_live.html.heex |  | Repository-wide mix format --check-formatted is blocked by pre-existing unrelated formatting drift. | fixed |  | 2026-08-26T17:06:05.568Z | 2026-08-28T02:33:27.780Z |
| 2 | 70 | unrun-verify | scripts/test_keycloak_proxy_e2e.sh |  | mix ci.security and final standalone format check were interrupted by the executor command window; rerun before release. | fixed |  | 2026-08-26T19:35:20.719Z | 2026-08-28T02:33:34.021Z |
| 3 | 70 | deviation | .github/workflows/keycloak-proxy-e2e.yml |  | Ruby and ci_monitor workflow validators unavailable; installed PyYAML plus existing workflow version comparison used. | fixed |  | 2026-08-26T22:08:47.457Z | 2026-08-28T02:33:34.093Z |
| 4 | 70 | unmet-truth | mix.lock |  | mix deps.audit remains non-zero for pre-existing Decimal 2.4.1 GHSA-rhv4-8758-jx7v outside Plan 70-12 Req/Finch/Mint scope | waived | Accepted transitive Decimal 2.4.1 advisory exception: Ecto/Postgrex constrain Decimal to ~> 2.0, Relyra has no direct Decimal.new/parse exposure, and mix ci.security explicitly audits with only GHSA-rhv4-8758-jx7v ignored until upstream permits Decimal 3.x. | 2026-08-26T22:16:16.898Z | 2026-08-28T02:33:34.161Z |
| 5 | 73 | deviation | test/docs/demo_guide_drift_test.exs | 901 | Incomplete-phase vocabulary scan rejects archival Phase 73 policy examples; routed to Phase 77 without weakening deterministic acceptance | open |  | 2026-09-09T18:04:18.120Z |  |
| 6 | 73 | unmet-truth | mix.lock |  | mix ci.security reports Phoenix 1.8.7 vulnerable to GHSA-63mc-hw7g-86rr and GHSA-6983-jfq8-485w; upgrade ownership is outside Plan 73-03 | fixed |  | 2026-09-09T18:31:28.476Z | 2026-09-09T19:02:10.197Z |
| 7 | 73 | deviation | .planning/STATE.md |  | Corrected stale Plan 2 and 0 percent SDK output to disk-backed Plan 4 of 5 and 80 percent progress | fixed |  | 2026-09-09T21:02:11.734Z | 2026-09-09T21:02:46.933Z |
| 8 | 73 | deviation | lib/relyra/connection_resolver.ex |  | Plan 73-05 mandatory read list used stale lib/relyra/behaviours/connection_resolver.ex path; executor resolved the real published behavior path read-only | fixed |  | 2026-09-09T21:29:21.133Z | 2026-09-09T21:30:40.463Z |
| 9 | 73 | deviation | .planning/STATE.md |  | Corrected state.update-progress reset from 5/5 to 0 percent and stale Plan 04 execution prose after Plan 73-05 closeout | fixed |  | 2026-09-09T21:30:40.548Z | 2026-09-09T21:30:40.645Z |
| 10 | 73 | deviation | test/governance/milestone_scope_test.exs |  | Existing target-mismatch controls required valid closed-grammar operations before target comparison | fixed |  | 2026-09-10T01:48:36.141Z | 2026-09-10T01:48:59.891Z |
| 11 | 73 | deviation | .planning/STATE.md |  | SDK closeout reset YAML progress and duplicated decision phase prefixes | fixed |  | 2026-09-10T01:48:36.283Z | 2026-09-10T01:49:00.025Z |
| 12 | 73 | deviation | test/governance/milestone_scope_test.exs |  | Kept the inherited appended-command regression on a script-backed fixture | fixed |  | 2026-09-10T19:12:23.779Z | 2026-09-10T19:13:17.107Z |
| 13 | 73 | deviation | .planning/STATE.md |  | Reconciled final-plan SDK progress reset and stale next-step prose | fixed |  | 2026-09-10T19:13:03.017Z | 2026-09-10T19:13:17.194Z |
| 14 | 73 | deviation | test/governance/milestone_scope_test.exs |  | Preserved legacy evidence selector ownership and migrated appended-command controls to declarative remote operations | fixed |  | 2026-09-11T00:25:28.034Z | 2026-09-11T00:25:45.691Z |
| 15 | 73 | deviation | test/adoption/evidence_contract_test.exs |  | Legacy path assertions now require grammar-first unsupported-pattern diagnostics | fixed |  | 2026-09-11T04:32:33.697Z | 2026-09-11T04:32:56.215Z |
| 16 | 73 | deviation | .planning/STATE.md |  | Generated progress required reconciliation to Plan 73-19 at 18/19 complete | fixed |  | 2026-09-11T04:32:33.790Z | 2026-09-11T04:33:01.909Z |
| 17 | 73 | deviation | .planning/STATE.md |  | State updater emitted zero percent and stale Plan 73-18 prose after all 19 summaries; reconciled in the final metadata changes | fixed |  | 2026-09-11T04:54:06.798Z | 2026-09-11T04:54:24.901Z |
| 18 | 73 | deviation | test/support/adoption_evidence.ex |  | Corrected normalized-tag argument order during Task 1 GREEN | fixed |  | 2026-09-11T15:48:32.979Z | 2026-09-11T15:49:06.508Z |
| 19 | 73 | deviation | .planning/STATE.md |  | Reconciled stale sequential tracking prose after Plan 73-22 | fixed |  | 2026-09-11T15:48:33.100Z | 2026-09-11T15:49:06.625Z |
| 20 | 73 | deviation | .planning/phases/73-twin-contract-and-baseline/73-23-PLAN.md |  | Removed only the mix ci.security timing ceiling after explicit human approval while preserving the complete mandatory lane and all mix ci.evidence bounds | fixed |  | 2026-09-11T18:56:30.193Z | 2026-09-11T18:56:35.322Z |
| 21 | 73 | deviation | .planning/STATE.md |  | Reconciled stale Plan 2 cursor and pending Plan 73-23 prose after all 23 summaries were present | fixed |  | 2026-09-11T18:56:30.312Z | 2026-09-11T18:56:35.412Z |
| 22 | 73 | deviation | .planning/phases/73-twin-contract-and-baseline/73-23-SUMMARY.md |  | Separated pre-execution plan revision 67b1fef from the Git-derived authoritative Task Commits set | fixed |  | 2026-09-11T19:00:01.441Z | 2026-09-11T19:00:01.555Z |
| 23 | 73 | deviation | test/adoption/evidence_contract_test.exs |  | Updated two historical hollow-selection fixtures to preserve genuine zero-selection coverage under ExUnit include override semantics | fixed |  | 2026-09-11T21:08:42.202Z | 2026-09-11T21:09:09.708Z |
| 24 | 73 | deviation | .planning/STATE.md |  | Reconciled SDK Plan 2 cursor and zero-percent progress to the disk-backed Plan 73-25 frontier after 24 completed summaries | fixed |  | 2026-09-11T21:10:27.306Z | 2026-09-11T21:10:27.457Z |
| 25 | 73 | deviation | test/support/adoption_evidence.ex |  | Batched governed-input Git tracking checks after post-boundary repetition exposed redundant per-file subprocess cost | fixed |  | 2026-09-11T21:17:23.507Z | 2026-09-11T21:17:23.594Z |
| 26 | 73 | deviation | test/support/phase_73_reconciliation.ex |  | Accepted valid ExUnit terminal summaries with parenthesized excluded counts | fixed |  | 2026-09-11T22:28:38.475Z | 2026-09-11T22:28:55.480Z |
| 27 | 73 | deviation | test/governance/milestone_scope_test.exs |  | Separated preserved historical open evidence from the final live report status | fixed |  | 2026-09-11T22:28:38.552Z | 2026-09-11T22:28:55.565Z |
| 28 | 73 | deviation | .planning/STATE.md |  | Corrected last-plan lifecycle and percentage fields after SDK reduction | fixed |  | 2026-09-11T22:28:38.628Z | 2026-09-11T22:28:55.649Z |
| 29 | 76 | unrun-verify | demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs |  | Concurrent duplicate ACS submissions remain unautomated because ConnCase does not expose its SQL Sandbox owner PID and Sandbox.allow returned :not_found. | open |  | 2026-09-26T12:57:07.799Z |  |
| 30 | 76 | deviation | demo/ledger_loop/test/ledger_loop/demo/trust_lifecycle_test.exs |  | The shared SQL Sandbox owner connection cannot coordinate two simultaneous certificate transitions; the one-winner race remains an automation gap, while the supported stale-write hook verifies conflict rollback and retry. | open |  | 2026-09-26T13:15:00.284Z |  |

````json
[
  {
    "id": 1,
    "kind": "lint-warning",
    "phase": "70",
    "file": "demo/ledger_loop/lib/ledger_loop_web/live/setup_live.html.heex",
    "line": null,
    "description": "Repository-wide mix format --check-formatted is blocked by pre-existing unrelated formatting drift.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-26T17:06:05.568Z",
    "resolved_at": "2026-08-28T02:33:27.780Z"
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "70",
    "file": "scripts/test_keycloak_proxy_e2e.sh",
    "line": null,
    "description": "mix ci.security and final standalone format check were interrupted by the executor command window; rerun before release.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-26T19:35:20.719Z",
    "resolved_at": "2026-08-28T02:33:34.021Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "70",
    "file": ".github/workflows/keycloak-proxy-e2e.yml",
    "line": null,
    "description": "Ruby and ci_monitor workflow validators unavailable; installed PyYAML plus existing workflow version comparison used.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-26T22:08:47.457Z",
    "resolved_at": "2026-08-28T02:33:34.093Z"
  },
  {
    "id": 4,
    "kind": "unmet-truth",
    "phase": "70",
    "file": "mix.lock",
    "line": null,
    "description": "mix deps.audit remains non-zero for pre-existing Decimal 2.4.1 GHSA-rhv4-8758-jx7v outside Plan 70-12 Req/Finch/Mint scope",
    "status": "waived",
    "reason": "Accepted transitive Decimal 2.4.1 advisory exception: Ecto/Postgrex constrain Decimal to ~> 2.0, Relyra has no direct Decimal.new/parse exposure, and mix ci.security explicitly audits with only GHSA-rhv4-8758-jx7v ignored until upstream permits Decimal 3.x.",
    "recorded_at": "2026-08-26T22:16:16.898Z",
    "resolved_at": "2026-08-28T02:33:34.161Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "73",
    "file": "test/docs/demo_guide_drift_test.exs",
    "line": 901,
    "description": "Incomplete-phase vocabulary scan rejects archival Phase 73 policy examples; routed to Phase 77 without weakening deterministic acceptance",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-09T18:04:18.120Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "unmet-truth",
    "phase": "73",
    "file": "mix.lock",
    "line": null,
    "description": "mix ci.security reports Phoenix 1.8.7 vulnerable to GHSA-63mc-hw7g-86rr and GHSA-6983-jfq8-485w; upgrade ownership is outside Plan 73-03",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-09T18:31:28.476Z",
    "resolved_at": "2026-09-09T19:02:10.197Z"
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Corrected stale Plan 2 and 0 percent SDK output to disk-backed Plan 4 of 5 and 80 percent progress",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-09T21:02:11.734Z",
    "resolved_at": "2026-09-09T21:02:46.933Z"
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "73",
    "file": "lib/relyra/connection_resolver.ex",
    "line": null,
    "description": "Plan 73-05 mandatory read list used stale lib/relyra/behaviours/connection_resolver.ex path; executor resolved the real published behavior path read-only",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-09T21:29:21.133Z",
    "resolved_at": "2026-09-09T21:30:40.463Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Corrected state.update-progress reset from 5/5 to 0 percent and stale Plan 04 execution prose after Plan 73-05 closeout",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-09T21:30:40.548Z",
    "resolved_at": "2026-09-09T21:30:40.645Z"
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "73",
    "file": "test/governance/milestone_scope_test.exs",
    "line": null,
    "description": "Existing target-mismatch controls required valid closed-grammar operations before target comparison",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T01:48:36.141Z",
    "resolved_at": "2026-09-10T01:48:59.891Z"
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "SDK closeout reset YAML progress and duplicated decision phase prefixes",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T01:48:36.283Z",
    "resolved_at": "2026-09-10T01:49:00.025Z"
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "73",
    "file": "test/governance/milestone_scope_test.exs",
    "line": null,
    "description": "Kept the inherited appended-command regression on a script-backed fixture",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T19:12:23.779Z",
    "resolved_at": "2026-09-10T19:13:17.107Z"
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled final-plan SDK progress reset and stale next-step prose",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T19:13:03.017Z",
    "resolved_at": "2026-09-10T19:13:17.194Z"
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "73",
    "file": "test/governance/milestone_scope_test.exs",
    "line": null,
    "description": "Preserved legacy evidence selector ownership and migrated appended-command controls to declarative remote operations",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T00:25:28.034Z",
    "resolved_at": "2026-09-11T00:25:45.691Z"
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "73",
    "file": "test/adoption/evidence_contract_test.exs",
    "line": null,
    "description": "Legacy path assertions now require grammar-first unsupported-pattern diagnostics",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T04:32:33.697Z",
    "resolved_at": "2026-09-11T04:32:56.215Z",
    "milestone": "v1.11"
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Generated progress required reconciliation to Plan 73-19 at 18/19 complete",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T04:32:33.790Z",
    "resolved_at": "2026-09-11T04:33:01.909Z",
    "milestone": "v1.11"
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "State updater emitted zero percent and stale Plan 73-18 prose after all 19 summaries; reconciled in the final metadata changes",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T04:54:06.798Z",
    "resolved_at": "2026-09-11T04:54:24.901Z",
    "milestone": "v1.11"
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "73",
    "file": "test/support/adoption_evidence.ex",
    "line": null,
    "description": "Corrected normalized-tag argument order during Task 1 GREEN",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T15:48:32.979Z",
    "resolved_at": "2026-09-11T15:49:06.508Z",
    "milestone": "v1.11"
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled stale sequential tracking prose after Plan 73-22",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T15:48:33.100Z",
    "resolved_at": "2026-09-11T15:49:06.625Z",
    "milestone": "v1.11"
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/phases/73-twin-contract-and-baseline/73-23-PLAN.md",
    "line": null,
    "description": "Removed only the mix ci.security timing ceiling after explicit human approval while preserving the complete mandatory lane and all mix ci.evidence bounds",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T18:56:30.193Z",
    "resolved_at": "2026-09-11T18:56:35.322Z",
    "milestone": "v1.11"
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled stale Plan 2 cursor and pending Plan 73-23 prose after all 23 summaries were present",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T18:56:30.312Z",
    "resolved_at": "2026-09-11T18:56:35.412Z",
    "milestone": "v1.11"
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/phases/73-twin-contract-and-baseline/73-23-SUMMARY.md",
    "line": null,
    "description": "Separated pre-execution plan revision 67b1fef from the Git-derived authoritative Task Commits set",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T19:00:01.441Z",
    "resolved_at": "2026-09-11T19:00:01.555Z",
    "milestone": "v1.11"
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "73",
    "file": "test/adoption/evidence_contract_test.exs",
    "line": null,
    "description": "Updated two historical hollow-selection fixtures to preserve genuine zero-selection coverage under ExUnit include override semantics",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T21:08:42.202Z",
    "resolved_at": "2026-09-11T21:09:09.708Z",
    "milestone": "v1.11"
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled SDK Plan 2 cursor and zero-percent progress to the disk-backed Plan 73-25 frontier after 24 completed summaries",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T21:10:27.306Z",
    "resolved_at": "2026-09-11T21:10:27.457Z",
    "milestone": "v1.11"
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "73",
    "file": "test/support/adoption_evidence.ex",
    "line": null,
    "description": "Batched governed-input Git tracking checks after post-boundary repetition exposed redundant per-file subprocess cost",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T21:17:23.507Z",
    "resolved_at": "2026-09-11T21:17:23.594Z",
    "milestone": "v1.11"
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "73",
    "file": "test/support/phase_73_reconciliation.ex",
    "line": null,
    "description": "Accepted valid ExUnit terminal summaries with parenthesized excluded counts",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T22:28:38.475Z",
    "resolved_at": "2026-09-11T22:28:55.480Z",
    "milestone": "v1.11"
  },
  {
    "id": 27,
    "kind": "deviation",
    "phase": "73",
    "file": "test/governance/milestone_scope_test.exs",
    "line": null,
    "description": "Separated preserved historical open evidence from the final live report status",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T22:28:38.552Z",
    "resolved_at": "2026-09-11T22:28:55.565Z",
    "milestone": "v1.11"
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "73",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Corrected last-plan lifecycle and percentage fields after SDK reduction",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T22:28:38.628Z",
    "resolved_at": "2026-09-11T22:28:55.649Z",
    "milestone": "v1.11"
  },
  {
    "id": 29,
    "kind": "unrun-verify",
    "phase": "76",
    "file": "demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs",
    "line": null,
    "description": "Concurrent duplicate ACS submissions remain unautomated because ConnCase does not expose its SQL Sandbox owner PID and Sandbox.allow returned :not_found.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-26T12:57:07.799Z",
    "resolved_at": null,
    "milestone": "v1.11"
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "76",
    "file": "demo/ledger_loop/test/ledger_loop/demo/trust_lifecycle_test.exs",
    "line": null,
    "description": "The shared SQL Sandbox owner connection cannot coordinate two simultaneous certificate transitions; the one-winner race remains an automation gap, while the supported stale-write hook verifies conflict rollback and retry.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-26T13:15:00.284Z",
    "resolved_at": null,
    "milestone": "v1.11"
  }
]
````
