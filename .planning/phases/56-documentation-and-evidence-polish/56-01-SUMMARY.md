---
phase: 56-documentation-and-evidence-polish
plan: 01
subsystem: docs
tags: [demo, readme, evaluator-ux, scope-honesty, host-app-boundary]
dependency_graph:
  requires: []
  provides: [demo/ledger_loop/README.md]
  affects: [demo/ledger_loop/README.md]
tech_stack:
  added: []
  patterns: [evaluator-first 11-section guide, JTBD boundary table, scope-honesty two-list]
key_files:
  created: []
  modified:
    - demo/ledger_loop/README.md
decisions:
  - "FakeIdP default subject is evaluator@example.com — not mapped to a seeded Northstar Health user; framed as 'evaluator test user' in §4, no false Dr. Sarah claim"
  - "FakeIdP routes /fake_idp/login and /fake_idp/sso are referenced in templates/tests but NOT registered in router.ex; omitted from §6 key routes table, documented inline in §4 walkthrough prose"
  - "11-section structure follows D-06 exactly; D-08 top blockquote + bottom scope section both present"
metrics:
  duration: "12 min"
  completed: "2026-06-13"
  tasks: 2
  files: 1
---

# Phase 56 Plan 01: Demo README Rewrite Summary

Full rewrite of `demo/ledger_loop/README.md` from the 18-line `mix phx.new` scaffold
to a 276-line evaluator-first 11-section guide satisfying DOCS-02, DOCS-03, SC2, SC3,
and SC4.

---

## Verified Surface (Task 1 — D-12 Blocking Gate)

These facts were read from source and drove the README content:

### FakeIdP Default Login Outcome

- **File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`
- **Confirmed subject:** `evaluator@example.com` (both the `success` and `failure` action paths sign this subject, lines 17 and 27)
- **Subject in fixtures.ex:** `evaluator@example.com` does NOT appear. Seeded SAML identities are `sarah@northstar.example.com` and `chen@northstar.example.com` only.
- **§4 framing chosen:** "the evaluator test user (evaluator@example.com)" — the walkthrough does NOT claim "you land as Dr. Sarah"

### Live Registered Route Set (from router.ex)

Routes actually registered in `demo/ledger_loop/lib/ledger_loop_web/router.ex`:

| Route | Handler |
|---|---|
| `GET /healthz` | `LedgerLoopWeb.HealthController :health` |
| `GET /readyz` | `LedgerLoopWeb.HealthController :ready` |
| `GET /` | `LedgerLoopWeb.PageController :home` |
| `LIVE /setup/sso` | `LedgerLoopWeb.SetupLive :index` |
| `GET /login/test` | `LedgerLoopWeb.RouteAffordanceController :login` |
| `GET /login/admin` | `LedgerLoopWeb.RouteAffordanceController :admin_login` |
| `GET /support/scenario` | `LedgerLoopWeb.RouteAffordanceController :support` |
| `/relyra/admin` | `relyra_admin_routes/2` |
| `/saml/*` | `saml_routes/0` |

### FakeIdP Routes Gap (documented observation)

`/fake_idp/login` and `/fake_idp/sso` are referenced in:
- `route_affordance_html/login.html.heex` (links to `/fake_idp/login`)
- `fake_idp_html/login.html.heex` (form posts to `/fake_idp/sso`)
- `fake_idp_controller_test.exs` (tests both routes)

But these routes are **NOT registered in router.ex**. There is no `dev_routes` block or other
registration mechanism found. This means the `/login/test` affordance link to FakeIdP would 404
in the current router state. This gap is not fixed by this plan (docs-only scope); it is
documented inline in the README's §4 walkthrough and omitted from the §6 key routes table.
This discrepancy is noted here for follow-up in a future phase.

---

## Tasks Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Verify real default login outcome and live route set | (no artifact — facts captured in SUMMARY) | — |
| 2 | Write the full evaluator-first demo README | d3650fc | demo/ledger_loop/README.md |

---

## Verification Results

All automated plan checks pass:

```
grep -c '' demo/ledger_loop/README.md  →  276  (≥120 ✓)
grep -q "not part of the Hex package"  →  PASS ✓
grep -q "this person may now do these things in our product"  →  PASS ✓
grep -Eq 'scripts/demo (doctor|up|reset|test|urls|down)'  →  PASS ✓
! grep -qiE 'quickstart|starter|scaffold'  →  PASS ✓
```

All 6 subcommands in fenced bash blocks: doctor ✓ up ✓ reset ✓ test ✓ urls ✓ down ✓

Seeded credentials: sarah@northstar.example.com ✓ chen@northstar.example.com ✓

Four connection scenarios: Enabled ✓ Draft/Missing Metadata ✓ Staged Rollover ✓ Support Failure ✓

No PEM blocks, no raw `<saml:` XML, no real secrets: ✓

§10 names all four ROADMAP scope items: protocol ✓ production IdP ✓ hosted broker ✓ security relaxation ✓

---

## Deviations from Plan

### Auto-documented Gap (not a deviation — factual discovery)

**FakeIdP route registration gap**
- **Found during:** Task 1 (content-accuracy gate)
- **Issue:** The plan's D-12 note mentioned `/fake_idp/login` and `/fake_idp/sso` routes were "referenced in templates and tests but were NOT found in the committed router.ex at plan time." Verification confirmed this: these routes are still not registered. The controller, HTML module, templates, and tests all exist, but no router entry.
- **Action taken:** Omitted FakeIdP routes from §6 key routes table (only documenting registered routes per D-07). Added an inline note in §4 walkthrough. Logged here for follow-up.
- **Files modified:** None — docs-only plan; no router change.

---

## Known Stubs

None. The README documents the real verified surface. No placeholder text flows to production rendering.

---

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced.
This plan is documentation-only. T-56-01 / T-56-02 / T-56-03 mitigations applied:
- No PEM, raw XML, or real secrets in the file
- No instruction to disable validation or skip signature checks
- §4 walkthrough matches the real default FakeIdP login outcome (D-12 gate satisfied)
