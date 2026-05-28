# Phase 48 Research — Operator completeness: incident playbook trace tools

**Researched:** 2026-05-27  
**Phase:** 48-operator-completeness-incident-playbook-trace-tools  
**Requirement:** ADOPT-03

## Summary

Phase 48 is doc-only: wire shipped login-trace surfaces (Phase 42) into operator documentation. No code changes. Primary edit target is `guides/operations/incident_playbook.md`; secondary edits are Day-2 cross-links in `guides/overview.md` and `guides/getting_started.md`.

## Current State (Gap Analysis)

### incident_playbook.md

| Location | Current | Required |
|----------|---------|----------|
| Intro L8 | "five evidence surfaces" | Six surfaces; login trace discoverable |
| Host owns L24 | "7 `mix relyra.*` operator hand-tools" | **8** hand-tools |
| Evidence surfaces table | 5 rows (no login trace) | 6th row: LiveView + CLI login trace |
| LiveView routes table | 6 routes (no trace) | Add `/connections/:connection_id/trace` → `ConnectionTraceLive` `:trace` |
| Mix tasks table | 7 tasks (no `relyra.trace`) | Add 8th task with `--repo`, `--connection`, `--last` |
| Mix tasks intro L124 | "7 Relyra operator hand-tools" | **8** |
| Scenario 3 Diagnose L201–206 | "no admin LiveView surface for replay activity in v1.4" | **Stale** — contradicts shipped trace |
| Scenario 4 Diagnose | cert inventory + diagnostic only | Add login trace for `signature.verify` step |
| Scenario 5 Diagnose | connection edit fields only | Add login trace for `response.validate` failures |
| Scenario 6 Diagnose | mapping section + audit | Add login trace for `user.map` step |
| When in doubt L302–304 | "diagnostic bundle is the trace" | Split: diagnostic = bundle; login trace = per-attempt timeline |

### Cross-doc navigation

| File | Current | Required |
|------|---------|----------|
| `guides/overview.md` Day-2 | No login-trace bullet | Bullet → incident playbook evidence/trace section |
| `guides/getting_started.md` §5 | No incident playbook link | Follow-on reference → incident playbook (Phase 47 pattern) |

### Shipped code anchors (read-only verification)

**LiveView route** (`lib/relyra/live_admin/router.ex`):
```
"/connections/:connection_id/trace" → Relyra.LiveAdmin.ConnectionTraceLive, :trace
```

**Step labels** (`lib/relyra/live_admin/connection_trace_live.ex` @step_labels):
- `response.decode`, `response.validate`, `signature.verify`, `replay.check`, `user.map`, `session.establish`

**CLI** (`lib/mix/tasks/relyra.trace.ex`):
```bash
mix relyra.trace --repo MyApp.Repo --connection CONNECTION_ID [--last N]
```
- Required: `--repo`, `--connection`
- Default `--last`: 20
- Aliases: `-r`, `-c`, `-n`

**Shared data path:** `Relyra.LiveAdmin.Query.get_login_traces/4` + `Relyra.LoginTrace.Export` redaction (TRACE-03).

**Navigation:** Connection detail `View Login Trace` link at `{base_path}/connections/{id}/trace` (`connection_detail.ex`).

### CI gates

- `mix ci.docs` already includes `cmd test -f guides/operations/incident_playbook.md` (presence guard).
- No new drift test warranted (Phase 47 D-11 / Phase 48 D-15 precedent).
- `test/security/login_trace_test.exs` stays in `mix ci.security` only.

## Recommended Plan Split

| Plan | Wave | Scope |
|------|------|-------|
| 48-01 | 1 | `incident_playbook.md` — tables, scenarios 3–6, When in doubt, count updates |
| 48-02 | 1 | `overview.md` + `getting_started.md` cross-links; `mix ci.docs` verification |

Plans are parallel (wave 1) — cross-links use stable `#evidence-surfaces` anchor.

## Validation Architecture

Doc-only phase: verification is grep-based content checks + `mix ci.docs` green run.

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix |
| Quick run | `grep` checks on edited markdown |
| Full suite | `mix ci.docs --warnings-as-errors` |
| Estimated runtime | ~30–60s |

### Per-change verification map

| Change | Verify command | Expected |
|--------|----------------|----------|
| 6th evidence row | `grep -i "login trace\|relyra.trace" guides/operations/incident_playbook.md` | match |
| Trace route in LiveView table | `grep "connections/:connection_id/trace" guides/operations/incident_playbook.md` | match |
| Mix task row | `grep "mix relyra.trace" guides/operations/incident_playbook.md` | match |
| Count 8 | `grep "8 \`mix relyra" guides/operations/incident_playbook.md` | ≥2 matches |
| Scenario 3 fix | `grep "v1.4" guides/operations/incident_playbook.md` | no match (stale text removed) |
| Scenario trace wiring | `grep -c "login trace\|Login trace" guides/operations/incident_playbook.md` | ≥4 (scenarios + table) |
| overview Day-2 | `grep "incident_playbook" guides/overview.md` | match in Day-2 section |
| getting_started §5 | `grep "incident_playbook" guides/getting_started.md` | match |
| CI | `mix ci.docs` | exit 0 |

## Risks

| Risk | Mitigation |
|------|------------|
| ROADMAP shorthand omits `--repo` | Document full CLI per D-10 |
| Conflating diagnostic bundle with login trace | Explicit When in doubt split (D-12) |
| Intro still says "five surfaces" after table grows | Update intro copy to six |
| Audit ledger confusion for replays | Retain Scenario 3 invariant: replays write no audit rows |

## RESEARCH COMPLETE
