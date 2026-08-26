---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-08-26T17:06:05.568Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 70 | lint-warning | demo/ledger_loop/lib/ledger_loop_web/live/setup_live.html.heex |  | Repository-wide mix format --check-formatted is blocked by pre-existing unrelated formatting drift. | open |  | 2026-08-26T17:06:05.568Z |  |

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
  }
]
````
