---
id: SEED-003
status: dormant
planted: 2026-06-13
planted_during: v1.7 closeout (after PR #31 merge)
trigger_when: next demo/adoption milestone, or before the next demo release
scope: small
---

# SEED-003: Finish-or-remove the demo FakeIdP login WIP

## Why This Matters

The v1.7 demo (`demo/ledger_loop`) carries uncommitted WIP for an in-app FakeIdP
login that was never wired up:

- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/{login,sso}.html.heex`
- `demo/ledger_loop/test/ledger_loop_web/controllers/fake_idp_controller_test.exs`
- `test/support/poll.ex` (`Relyra.TestSupport.Poll`, currently unreferenced)

The `/fake_idp/login` and `/fake_idp/sso` routes the controller/test assume are
**not registered in** `demo/ledger_loop/lib/ledger_loop_web/router.ex`. The test
404s. These files are deliberately left **untracked** at v1.7 closeout so they
don't break the `demo-app` CI lane.

The demo's documented login currently works via `RouteAffordanceController`
(`/login/test`, `/login/admin`) — so this FakeIdP controller is an unwired
*alternative*, not a regression.

## When to Surface

**Trigger:** next demo/adoption milestone, or before the next demo release if the
in-app FakeIdP login is wanted as the documented browser flow.

## Decision Needed

Either:
1. **Wire it** — add `/fake_idp/login` + `/fake_idp/sso` routes to the demo router,
   confirm the controller/templates work, make the test green, then commit the
   whole feature together (don't commit the test before the routes exist).
2. **Remove it** — delete the WIP if `RouteAffordanceController` is the intended
   login path. Also decide whether `test/support/poll.ex` is needed (nothing
   references it today).

## Scope Estimate

**Small** — a few routes + a controller/template pass, or a deletion.

## Breadcrumbs

- `demo/ledger_loop/lib/ledger_loop_web/router.ex` (routes; no `/fake_idp/*` today)
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` (current login)
- The untracked files listed above
- `demo/ledger_loop/README.md` §4 "What you'll see" (the documented login walkthrough)
