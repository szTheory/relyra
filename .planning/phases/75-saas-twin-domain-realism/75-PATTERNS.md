# Phase 75: SaaS Twin Domain Realism - Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 7 planned files (2 implementation, 5 tests)  
**Analogs found:** 7 / 7 (no exact twin-domain test analogs; existing reset/scenario tests are close matches)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` | utility / fixture catalog | batch, transform | `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` | exact |
| `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` | service / reset orchestrator | batch, CRUD | `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` | exact |
| `demo/ledger_loop/test/twin/organization_test.exs` | test | request-response / assertions | `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` | role-match |
| `demo/ledger_loop/test/twin/provider_test.exs` | test | batch / assertions | `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` | role-match |
| `demo/ledger_loop/test/twin/certificate_history_test.exs` | test | batch / assertions | `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` | role-match |
| `demo/ledger_loop/test/twin/incident_timeline_test.exs` | test | event-driven / assertions | `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` | role-match |
| `demo/ledger_loop/test/twin/reset_test.exs` | test | batch / assertions | `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` | role-match |

The five test paths are named as TWIN acceptance evidence in `test/support/adoption_evidence.ex:159-168`. They are planned files, not existing analogs. The seed entry point already delegates to the reset (`demo/ledger_loop/priv/repo/seeds.exs:1-5`); no seed-script change is implied.

## Pattern Assignments

### `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` (utility / fixture catalog, batch)

**Analog:** `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`

Stable IDs and the fixed clock are module attributes (`:16-47`). Scenario records are grouped into named functions (`relyra_connections/0`, `relyra_certificates/0`, `tenant/0`, `users/0`, `groups/0`, `memberships/0`, `saml_identities/0`; `:49-108`, `:110-155`, `:205-295`). Preserve that catalog as the single fixture owner. New records should have deterministic IDs, explicit timestamps, scenario-specific provider/identity values, and tenant-consistent ownership. Existing fixture timestamps are reused directly in bulk inserts; certificate changesets can fall back to wall-clock timestamps (`lib/relyra/ecto/certificate.ex:99-104`), so supply explicit lifecycle times.

**Fixed identity and scenario ID pattern** (`:16-47`):

```elixir
@northstar_tenant_id "11111111-1111-1111-1111-111111111111"
@dr_sarah_id "22222222-2222-2222-2222-222222222222"
@enabled_conn_id "aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa"
@enabled_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J0"
@fixed_timestamp ~U[2026-06-12 12:00:00.000000Z]
```

**Tenant-linked rows** (`:205-295`):

```elixir
def users do
  [
    %{
      id: @dr_sarah_id,
      tenant_id: @northstar_tenant_id,
      name: "Dr. Sarah",
      email: "sarah@northstar.example.com",
      inserted_at: @fixed_timestamp,
      updated_at: @fixed_timestamp
    }
  ]
end
```

Group rows use the same tenant ID; memberships connect explicit user/group IDs; SAML identities bind issuer and subject. For multi-tenant cases keep those links internally consistent and use a connection `organization_id` equal to the tenant slug. `LedgerLoop.Relyra.UserMapper` resolves the verified `(subject, issuer)` pair and returns the user's tenant and groups (`demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex:13-56`).

### `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` (service / reset orchestrator, batch + CRUD)

**Analog:** `demo/ledger_loop/lib/ledger_loop/demo/reset.ex`

Use one `Repo.transaction/1` around the owned fixture rebuild (`:16-45`). Delete only fixture-owned tenants/connections and dependent audit/trust rows before inserting tenants, people, memberships, identities, then Relyra rows. The existing connection scope is `organization_id == "northstar"` (`:21-30`); extend it with a closed set of fixture-owned organization IDs rather than a global delete, which could erase local Keycloak data.

**Reset and insert order** (`:16-45`):

```elixir
def reset! do
  Repo.transaction(fn ->
    Repo.delete_all(from t in Tenant, where: t.id == ^Fixtures.tenant().id)
    # Delete dependent Relyra rows for fixture-owned connection IDs first.
    Repo.insert_all(Tenant, [Fixtures.tenant()])
    Repo.insert_all(User, Fixtures.users())
    Repo.insert_all(Group, Fixtures.groups())
    Repo.insert_all(Membership, Fixtures.memberships())
    Repo.insert_all(SAMLIdentity, Fixtures.saml_identities())
    Repo.insert_all(Connection, Fixtures.relyra_connections())
    Repo.insert_all(Certificate, Fixtures.relyra_certificates())
  end)

  :ok
end
```

The current support audit events are appended through `AuditWriter.append_event/2` and reference the connection's internal UUID (`:46-80`). Continue using that seam for synthetic audit evidence, with deterministic distinct timestamps/order and bounded, safe summaries. For chronology use `MetadataRevision` outcomes and `Certificate` lifecycle/validity fields; degraded/recovered health belongs to metadata-source health and audit evidence, not certificate lifecycle. Relevant schema fields: `lib/relyra/ecto/metadata_revision.ex:24-47`, `lib/relyra/ecto/certificate.ex:17-37`, `lib/relyra/ecto/metadata_source.ex:42-63`.

### `demo/ledger_loop/test/twin/organization_test.exs` (test, request-response/assertions)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs`

Start from a `LedgerLoop.DataCase` test, reset fixtures in `setup`, then query exact scenario-owned records. The identity mapping analog is `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex:13-56`: it matches issuer and subject, joins user→tenant, and fetches memberships/groups. Assert tenant IDs agree across user, group, membership, identity, and connection organization; make mapped group/role and expected authorization outcome explicit. Membership schema validation checks the two IDs separately (`demo/ledger_loop/lib/ledger_loop/accounts/membership.ex:15-20`), so the test must assert same-tenant semantics itself.

**Scenario test setup** (`connection_scenarios_test.exs:1-11`):

```elixir
use LedgerLoop.DataCase, async: false

alias LedgerLoop.Demo.Reset

setup do
  Reset.reset!()
  :ok
end
```

### `demo/ledger_loop/test/twin/provider_test.exs` (test, batch/assertions)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs`

Use the existing scenario assertions (`:13-39`) to check provider-specific connection state and its associated trust facts through Ecto associations. `Connection` enumerates the supported provider presets and the persisted status values (`lib/relyra/ecto/connection.ex:21-55`). Query by stable scenario IDs or scoped tenant organization, not display-name coincidence alone. Assert that each connection belongs to the expected tenant and that provider, issuer, and identity facts differ where the scenario says they should.

### `demo/ledger_loop/test/twin/certificate_history_test.exs` (test, batch/assertions)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs`

Follow its association queries for certificates (`:27-47`), then assert the explicit event chronology across connection readiness, certificate `lifecycle_state`/validity timestamps, metadata revision outcomes, metadata-source health, and audit rows. The existing test only checks active and next rows; extend the contract to assert ordered tuples with timestamps/sequence, not database return order. Schema fields and lifecycle values are at `lib/relyra/ecto/certificate.ex:11-37`; revision source/outcome/trust snapshot fields at `lib/relyra/ecto/metadata_revision.ex:13-47`.

### `demo/ledger_loop/test/twin/incident_timeline_test.exs` (test, event-driven/assertions)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs`; redaction analog `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs`

Filter login audit rows by the support connection's internal ID and order by explicit event time/order. Existing support tests enumerate trace step names and reject forbidden XML, PEM, and secret markers (`connection_scenarios_test.exs:49-98`). For the complete synthetic narrative, assert symptom→diagnosis→remediation→retry→recovery and shared correlation lineage. Test export with `Relyra.LoginTrace.Export.export_login/1`, which hashes correlation IDs and allow-lists/redacts exported steps (`lib/relyra/login_trace/export.ex:34-50,70-102`). Audit summaries are bounded by `AuditEvent` (`lib/relyra/ecto/audit_event.ex:29-48,53-83`).

**Stored evidence safety check** (`connection_scenarios_test.exs:79-97`):

```elixir
for event <- audit_events do
  summary_json = Jason.encode!(event.diff_summary)

  for token <- ["<?xml", "BEGIN CERTIFICATE", "PRIVATE KEY", "SAMLResponse"] do
    refute String.contains?(summary_json, token)
  end
end
```

### `demo/ledger_loop/test/twin/reset_test.exs` (test, batch/assertions)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs`

Reuse the double-reset equality assertion over fixture-owned rows (`:73-102`). Add checks that repeated reset produces the same named scenarios and chronology, tenant-owned records remain isolated, and a sentinel row outside the fixture survives. The existing test also demonstrates exact opt-in handling and asserting exported redaction (`:104-149`); use it for artifact-safety coverage where appropriate.

**Determinism pattern** (`:73-102`):

```elixir
Reset.reset!()
first = Repo.all(Tenant)
Reset.reset!()
second = Repo.all(Tenant)
assert first == second
```

## Shared Patterns

### Fixture and reset ownership

**Sources:** `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex:16-47,49-108,205-295`; `demo/ledger_loop/lib/ledger_loop/demo/reset.ex:16-45`  
**Apply to:** both implementation files and every test that verifies fixture output. Keep scenario definitions centralized, timestamps explicit, and reset atomic and scoped to a closed set of fixture-owned rows.

### Tenant mapping

**Sources:** `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex:13-56`; `demo/ledger_loop/lib/ledger_loop/accounts/{user,group,membership,saml_identity}.ex`  
**Apply to:** organization/provider tests. Tenant is host-owned; Relyra connection linkage is its `organization_id` string. Verify same-tenant membership as a semantic invariant.

### Trust history dimensions

**Sources:** `lib/relyra/ecto/connection.ex:28-55`; `lib/relyra/ecto/certificate.ex:17-37`; `lib/relyra/ecto/metadata_revision.ex:24-47`; `lib/relyra/ecto/metadata_source.ex:42-63`  
**Apply to:** fixture catalog, reset, and certificate-history tests. Keep readiness, certificate lifecycle/validity, revision outcome, and operational health distinct; use explicitly ordered fixed-time records.

### Synthetic evidence and redaction

**Sources:** `demo/ledger_loop/lib/ledger_loop/demo/reset.ex:46-80`; `lib/relyra/ecto/audit_event.ex:33-83`; `lib/relyra/login_trace/export.ex:70-103`; `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs:126-149`  
**Apply to:** incident fixtures and incident/reset tests. Seed synthetic safe summaries, append through `AuditWriter`, verify both stored content and the shared exporter, and assert correlation hashing.

## No Exact Analog Found

There are no existing multi-tenant twin contract tests for the organization, provider, full trust-history, or complete incident timeline cases. Use the closest tracked `connection_scenarios_test.exs` and `reset_test.exs` structures above; all five intended test paths are registered under `ci.demo_app` in `test/support/adoption_evidence.ex:159-168`.

## Metadata

**Analog search scope:** `demo/ledger_loop/lib/ledger_loop/demo/`, `demo/ledger_loop/lib/ledger_loop/accounts/`, `demo/ledger_loop/lib/ledger_loop/relyra/`, `demo/ledger_loop/test/ledger_loop/demo/`, `lib/relyra/ecto/`, `lib/relyra/login_trace/`, and `test/support/`  
**Files scanned:** 18 relevant tracked source/test files  
**Tracked-source verification:** every analog path above was checked with `git ls-files`; all are tracked.  
**Pattern extraction date:** 2026-09-25
