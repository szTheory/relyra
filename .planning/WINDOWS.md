---
schema_version: 1
open_count: 4
waived_count: 0
fixed_count: 0
total_count: 4
last_updated: 2026-08-26T22:16:16.898Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 70 | lint-warning | demo/ledger_loop/lib/ledger_loop_web/live/setup_live.html.heex |  | Repository-wide mix format --check-formatted is blocked by pre-existing unrelated formatting drift. | open |  | 2026-08-26T17:06:05.568Z |  |
| 2 | 70 | unrun-verify | scripts/test_keycloak_proxy_e2e.sh |  | mix ci.security and final standalone format check were interrupted by the executor command window; rerun before release. | open |  | 2026-08-26T19:35:20.719Z |  |
| 3 | 70 | deviation | .github/workflows/keycloak-proxy-e2e.yml |  | Ruby and ci_monitor workflow validators unavailable; installed PyYAML plus existing workflow version comparison used. | open |  | 2026-08-26T22:08:47.457Z |  |
| 4 | 70 | unmet-truth | mix.lock |  | mix deps.audit remains non-zero for pre-existing Decimal 2.4.1 GHSA-rhv4-8758-jx7v outside Plan 70-12 Req/Finch/Mint scope | open |  | 2026-08-26T22:16:16.898Z |  |

````json
[
  {
    "id": 1,
    "kind": "lint-warning",
    "phase": "70",
    "file": "demo/ledger_loop/lib/ledger_loop_web/live/setup_live.html.heex",
    "line": null,
    "description": "Repository-wide mix format --check-formatted is blocked by pre-existing unrelated formatting drift.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T17:06:05.568Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "70",
    "file": "scripts/test_keycloak_proxy_e2e.sh",
    "line": null,
    "description": "mix ci.security and final standalone format check were interrupted by the executor command window; rerun before release.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T19:35:20.719Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "70",
    "file": ".github/workflows/keycloak-proxy-e2e.yml",
    "line": null,
    "description": "Ruby and ci_monitor workflow validators unavailable; installed PyYAML plus existing workflow version comparison used.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:08:47.457Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unmet-truth",
    "phase": "70",
    "file": "mix.lock",
    "line": null,
    "description": "mix deps.audit remains non-zero for pre-existing Decimal 2.4.1 GHSA-rhv4-8758-jx7v outside Plan 70-12 Req/Finch/Mint scope",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:16:16.898Z",
    "resolved_at": null
  }
]
````
