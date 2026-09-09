# Deferred Items

## 73-01 execution

- `mix qa` fails `Relyra.Docs.DemoGuideDriftTest` because pre-existing Phase 73 planning artifacts contain vocabulary prohibited for incomplete phases (`<human-check>`, `Manual-Only Verifications`, and `status: human_needed`). This is outside Plan 73-01's evidence-ledger scope and should be resolved by the owning planning/governance work.
- The same full-suite run intermittently lost the `Relyra.TestSupport.LiveAdminEndpoint` ETS table in `Relyra.Security.LoginTraceTest`. The isolated file immediately passed (3 tests, 0 failures), so this remains a pre-existing concurrent-suite stability item rather than a Plan 73-01 change.
