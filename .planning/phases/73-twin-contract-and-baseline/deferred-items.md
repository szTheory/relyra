# Deferred Items

## 73-01 execution

- `mix qa` fails `Relyra.Docs.DemoGuideDriftTest` because pre-existing Phase 73 planning artifacts contain vocabulary prohibited for incomplete phases (`<human-check>`, `Manual-Only Verifications`, and `status: human_needed`). This is outside Plan 73-01's evidence-ledger scope and should be resolved by the owning planning/governance work.
- The same full-suite run intermittently lost the `Relyra.TestSupport.LiveAdminEndpoint` ETS table in `Relyra.Security.LoginTraceTest`. The isolated file immediately passed (3 tests, 0 failures), so this remains a pre-existing concurrent-suite stability item rather than a Plan 73-01 change.

## 73-03 execution

- `mix qa` still has the inventoried `Relyra.Docs.DemoGuideDriftTest` failure because its older incomplete-phase scanner treats archival planning-policy examples as executable markers. Plan 73-03's focused governance owner scans active `*-PLAN.md` files and required `*-UAT.md` artifacts correctly; the older docs owner remains routed to Phase 77 per finding `QUAL-73-006`.
- `mix ci.security` ran every dedicated fresh-process security test successfully, then failed `deps.audit` because Phoenix `1.8.7` is now covered by `GHSA-63mc-hw7g-86rr` and high-severity `GHSA-6983-jfq8-485w`; the first patched `1.8.x` is `1.8.9`. A dependency upgrade is outside Plan 73-03's test-only, security-posture-unchanged scope and needs ownership before mutation.
