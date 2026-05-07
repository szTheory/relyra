# Phase 21 — Deferred / Out-of-Scope Items

Out-of-scope discoveries surfaced during Phase 21 execution. Per the executor
SCOPE BOUNDARY rule, these are pre-existing issues unrelated to the current
plan's task changes.

## Pre-existing failures

### `lib/relyra/live_admin/connections_live.ex` — pre-existing format drift

- **Discovered during:** Plan 21-01 execution (Wave 0).
- **Status:** Pre-existing on `main` BEFORE Phase 21 work started. Not modified
  by Plan 21-01.
- **Last touch:** Phase 20 commit `6e75525` (feat(20): implement bulk operations
  for connections and UI multi-selection).
- **Symptom:** `mix format --check-formatted` (no args) flags multi-line alias
  block + several `assign/2` calls as needing reflow.
- **Why deferred:** Out of scope for Plan 21-01. Auto-fixing pre-existing format
  drift in unrelated files would make this commit confusing and would also fail
  the SCOPE BOUNDARY rule. Plan 21-01's own files all pass
  `mix format --check-formatted`.
- **Recommended owner:** Whichever phase next touches `connections_live.ex`
  (Phase 21 W4 / `21-06-live-admin-surface` is the natural candidate).

### `Relyra.Phoenix.ACSControllerTest` — `POST /:connection_id/acs success`

- **Discovered during:** Plan 21-01 execution (Wave 0).
- **Status:** Pre-existing failure on `main` BEFORE Phase 21 work started.
  Reproduced on commit `0842687` (the parent of Phase 21 execution).
- **File:** `test/phoenix/acs_controller_test.exs:48`
- **Error:**
  ```
  ** (KeyError) key :name_id not found in:
      %Relyra.LoginResult{principal: %Relyra.Principal{name_id: ...}, ...}
  ```
  The test's `FakeUserMapper.map_attributes/3` reads `result.name_id`, but the
  field has moved to `result.principal.name_id` somewhere in the v0.4 line.
- **Why deferred:** Out of scope for Plan 21-01 (schema extension only). Not
  caused by the migration / schema changes / stub creation in this plan.
- **Recommended owner:** A separate fix-up commit unrelated to Phase 21, or
  rolled into the next phase touching `ACSControllerTest`'s test fixtures.
