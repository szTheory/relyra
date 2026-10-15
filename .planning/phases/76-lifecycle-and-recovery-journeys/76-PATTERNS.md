# Phase 76: Lifecycle and Recovery Journeys - Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 7 likely new/modified files  
**Analogs found:** 6 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs` (or extend current flow suite) | test | request-response | `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` | exact |
| `demo/ledger_loop/test/twin/organization_journeys_test.exs` (or extend current organization suite) | test | request-response | `demo/ledger_loop/test/twin/organization_test.exs` | role-match |
| `demo/ledger_loop/test/ledger_loop/demo/trust_lifecycle_test.exs` (or extend scenario/provisioner suites) | test | CRUD | `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs`; `test/relyra/ecto/metadata_apply_test.exs` | exact |
| `demo/ledger_loop/test/twin/incident_recovery_test.exs` (or extend incident timeline suite) | test | request-response | `demo/ledger_loop/test/twin/incident_timeline_test.exs` | exact |
| `demo/ledger_loop/test/browser/lifecycle_journeys.spec.ts` (only where browser semantics are needed) | test | request-response | `demo/ledger_loop/test/browser/trace_visual.spec.ts` | role-match |
| `.github/workflows/demo-app-e2e.yml` (possible edit for deterministic browser ownership) | config | event-driven | `.github/workflows/demo-app-e2e.yml` | exact |
| `.github/workflows/real-idp-canary.yml` (if a separate scheduled canary is introduced) | config | event-driven | `.github/workflows/fleet-proxy-e2e.yml` | partial; no real-IdP canary exists |

These names are focused recommendations inferred from the phase requirements, not explicit locked paths. Prefer extending the existing focused test files when doing so preserves a readable boundary; avoid creating duplicate journey suites. The phase concerns evidence composition, so no new runtime module is implied.

## Pattern Assignments

### LedgerLoop ACS lifecycle journey tests (test, request-response)

**Analog:** `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs`

**Imports, setup, configured endpoint** (lines 16-36):

```elixir
use LedgerLoopWeb.ConnCase, async: false

import Phoenix.LiveViewTest
import Ecto.Query

alias LedgerLoop.Accounts.LoginReceipt
alias LedgerLoop.Demo.Fixtures
alias LedgerLoop.Demo.Reset
alias LedgerLoop.Repo
alias Relyra.Ecto.AuditEvent

@endpoint LedgerLoopWeb.Endpoint
@conn_ulid Fixtures.relyra_enabled_scenario_id()

setup do
  Reset.reset!()
  :ok
end
```

**Core SP flow** (lines 60-124): use `/saml/:connection/login`, extract the redirect's `SAMLRequest` and `RelayState`, submit through the FakeIdP routes, then POST its signed `SAMLResponse` to the same connection's ACS. Existing test asserts status/redirect and receipt presence; JOUR-01 should strengthen the final database assertions to include tenant, mapped user, groups/role, and receipt together. Do not duplicate the clean-room package-consumer proof.

**Typed rejection and no successful host state** (lines 132-210): the test tampers the signed response, posts it to ACS, asserts HTTP 400 and no LoginReceipt, then reads the `:login` audit event and checks `signature.verify` has `outcome == "error"` and `error_code == "digest_mismatch"`. Generalize this exact endpoint pattern for the required invalid-input cases; take before/after counts for host-owned successful session artifacts while allowing diagnostic traces/audits to persist.

**Session adapter side effect** is also concrete in `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex:18-39`; inspect that existing adapter when defining which host state the negative cases count. Runtime adapter selection comes from `demo/ledger_loop/config/config.exs:33-39`, where resolver, request store, replay store, mapper, session adapter, and repo are set together.

### Cross-tenant scenario tests (test, request-response)

**Analog:** `demo/ledger_loop/test/twin/organization_test.exs`

**Fixture reset and organization mapping** (lines 1-45):

```elixir
use LedgerLoop.DataCase, async: false

alias LedgerLoop.Demo.{Fixtures, Reset}
alias LedgerLoop.Repo
alias LedgerLoop.Relyra.UserMapper
alias Relyra.Ecto.Connection

setup do
  Reset.reset!()
  :ok
end

for {subject, issuer, slug, group_key, outcome} <- expected do
  connection = Repo.one!(from connection in Connection, where: ...)
  assert {:ok, mapped} = UserMapper.map_attributes(%{principal: %{name_id: subject}}, connection, [])
  assert mapped.tenant.slug == slug
  assert Enum.map(mapped.groups, & &1.key) == [group_key]
  assert group_key == "admins" == (outcome == :allow)
end
```

This is a mapper-level precedent only. JOUR-04 needs paired end-to-end ACS scenarios to prove resolver, replay, receipt/session, trace/audit visibility, and authorization isolation. Reuse the seeded Northstar and Harborline IDs and assert scoped read denial across organizations. Admin scope is a session-derived typed boundary in `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex:7-23`.

### Trust lifecycle and audit tests (test, CRUD)

**Analogs:** `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` and `test/relyra/ecto/metadata_apply_test.exs`

**Failure injection and coupled rollback** (`keycloak_provisioner_test.exs:86-123`): inject errors through supported function options such as `mapping_audit_writer` or `connection_enabler`, then assert trust/identity state and audit are absent together; retry and assert one successful state. Reuse this shape only where the supported lifecycle operation exposes an injection seam.

**Metadata staging, resolver-visible state, and audit** (`metadata_apply_test.exs:19-79`): call `MetadataApply.apply_revision(..., repo: @repo)`, reload connection and certificates, assert new certs are `:next` while the old active cert remains resolver-visible, then assert ordered `{:certificate, :staged}` and `{:metadata, :applied}` audit rows. For invalid candidate state, lines 81-110 assert typed error and unchanged persisted connection/certificate state.

**Imports and actor/cause metadata:** `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs:1-17` shows the app's schema aliases, `Reset.reset!()`, and per-test fixtures. Its lines 19-61 assert actor, cause, correlation ID, trust records, and audit events. `test/relyra/ecto/connection_record_test.exs:72-85` is the compact pattern for invalid audited writes leaving neither mutation nor orphan event.

Drive UI-required acceptance only through the existing organization-scoped LiveAdmin routes; do not use the setup checklist as proof of persisted trust changes (the research identifies that handler as display-only). Keep Relyra's `MetadataApply`, connection/certificate operations, and `Relyra.Ecto.AuditWriter` as the mutation path.

### Incident diagnosis, recovery, and export tests (test, request-response)

**Analog:** `demo/ledger_loop/test/twin/incident_timeline_test.exs`

**Scope, correlation, and redaction** (lines 26-90):

```elixir
assert {:ok, exports} =
  Query.get_login_traces(
    Repo,
    %Scope{actor: "support-test", organization_id: "northstar"},
    connection_id
  )

expected_hash = AllowList.hash_correlation_id(raw_correlation)
assert Enum.all?(exports, &(&1.correlation_id == expected_hash))
refute Enum.any?(exports, &(inspect(&1) =~ raw_correlation))

for exported <- exports, step <- exported.steps do
  assert Map.keys(step) |> Enum.all?(&(&1 in ["outcome", "error_code", "duration_ms", "attributes", "roles", "step"]))
end
```

The setup resets fixtures and restores `DEMO_TRACE_VISUAL_FIXTURE` on exit (lines 11-24). The test ties support route, ordered incident stages, trace-step events, and export to one seeded incident. Extend with an actual recovery transition and post-recovery outcome, while retaining export-level checks for hashed correlation and forbidden assertion/certificate/credential/cookie material. Export redaction source is `lib/relyra/login_trace/export.ex`.

### Browser journey tests (test, request-response)

**Analog:** `demo/ledger_loop/test/browser/trace_visual.spec.ts`

**Browser assertion pattern** (lines 9-60): use Playwright `test`/`expect`, perform the supported FakeIdP flow, wait for the ACS POST response, assert rejection status and absence of the adopter's verified receipt, then authenticate as the test admin and inspect the correlated trace. It also exercises keyboard interaction and responsive layout at lines 47-90. Keep browser coverage focused on actual UI semantics; the rejection matrix and adapter integration belong in deterministic ConnTest.

## Shared Patterns

### Deterministic fixture ownership

**Sources:** `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs:21-53`, `demo/ledger_loop/test/twin/incident_timeline_test.exs:11-24`  
Reset with `LedgerLoop.Demo.Reset.reset!()`; use fixture-owned identifiers. Restore modified application/environment configuration in `on_exit/1`. Keep tests `async: false` where shared configuration or database state requires it.

### Tenant and adapter boundaries

**Sources:** `demo/ledger_loop/config/config.exs:33-39`, `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex:7-23`  
Exercise the configured behavior modules and LedgerLoop-owned tenant IDs. Do not add a parallel test resolver or bypass replay/session seams. Admin operations derive actor and organization from `Scope`.

### Trust mutation audit atomicity

**Sources:** `test/relyra/ecto/metadata_apply_test.exs:67-79`, `test/relyra/ecto/connection_record_test.exs:72-85`  
Assert both persisted trust state and its audit event on success; on failure assert both are absent or unchanged. Keep writes routed through the existing audited domain operation.

### Safe evidence and canary separation

**Sources:** `demo/ledger_loop/test/twin/incident_timeline_test.exs:64-90`, `.github/workflows/demo-app-e2e.yml:75-83`, `.github/workflows/fleet-proxy-e2e.yml:57-88`  
Validate redaction before artifact upload. Deterministic FakeIdP CI runs on pull requests and pushes. The fleet workflow's scheduled canary has an always-uploaded, seven-day artifact, but it is not an external IdP example; no tracked real-provider canary analog was found. Any real-IdP scheduled job should remain outside required deterministic merge jobs and document its owner, safe artifact contents/retention, and recovery procedure.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.github/workflows/real-idp-canary.yml` (if added) | config | event-driven | Existing scheduled fleet canary is a partial CI/artifact pattern, but no real external IdP canary workflow or ownership/recovery contract exists in tracked source. |

## Metadata

**Analog search scope:** LedgerLoop endpoint/demo/twin/browser tests; Relyra Ecto metadata and connection tests; GitHub Actions demo and scheduled canary workflows.  
**Tracked analog files scanned:** 11  
**Pattern extraction date:** 2026-09-25
