# Phase 52: Ecto Stores And Deterministic Seed Story - Context

**Gathered:** 2026-06-12 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 52 makes the existing `demo/ledger_loop` Phoenix app resettable and data-backed: deterministic LedgerLoop / Northstar Health host data, seeded Relyra trust-state rows, dependency-run Relyra Ecto migrations, Ecto-backed connection/request/replay store proof, and a host-owned mapping/session boundary. It does not build the full customer/admin setup UX, browser FakeIdP flow, Docker orchestration, optional Keycloak proof, browser E2E, or public demo documentation; those remain Phases 53-56.
</domain>

<decisions>
## Implementation Decisions

### Deterministic Demo Data
- **D-01:** Add LedgerLoop-owned schemas and a deterministic reset path for the demo domain: tenant, user, group, membership, SAML identity/linkage, and any minimal receipt/read-model rows needed to prove the host boundary.
- **D-02:** Use stable IDs, slugs, email addresses, timestamps, and scenario keys. Demo reset must replace seeded demo data predictably so repeated resets produce the same Northstar Health story.
- **D-03:** Seed the product story around LedgerLoop as the SaaS host and Northstar Health as the customer tenant. Relyra rows are evidence for SAML trust; LedgerLoop rows are evidence for product authorization and host-owned workflow.

### Migration Strategy
- **D-04:** Demo setup/reset must run Relyra's shipped migrations from the dependency path (`../../priv/repo/migrations` relative to `demo/ledger_loop`) before demo-owned migrations.
- **D-05:** Do not copy Relyra migration files into `demo/ledger_loop/priv/repo/migrations`. If an alias or Mix task is needed, it should call `Ecto.Migrator` against the dependency migration path.
- **D-06:** Add demo-owned migrations only for LedgerLoop tables and host-owned request/replay tables. Relyra trust tables stay owned by Relyra's shipped migrations.

### Ecto Store Wiring
- **D-07:** Configure the demo runtime to use `Relyra.ConnectionResolver.Ecto` with `LedgerLoop.Repo`.
- **D-08:** Add LedgerLoop-owned wrapper modules for request and replay stores. Each wrapper delegates to `Relyra.RequestStore.Ecto` or `Relyra.ReplayStore.Ecto` with `repo: LedgerLoop.Repo` and a fixed, distinct table name.
- **D-09:** Request/replay storage targets must never come from request params, RelayState, connection IDs, or user-controlled config. Exact table names are the planner's discretion, but they must be fixed in host code and covered by tests.
- **D-10:** The Phase 52 happy path must prove request intents are inserted, fetched, and consumed through the Ecto request store, and replay keys are inserted through the Ecto replay store. Existing adoption fixtures that use ETS for request/replay are references only, not acceptable final demo behavior.

### Seeded Relyra States
- **D-11:** Seed at least four inspectable connection scenarios: enabled happy path, draft/missing-metadata, staged-certificate rollover, and failure/support.
- **D-12:** Use Relyra Ecto schemas and command modules where they match the operation being modeled. Use `Relyra.Ecto.AuditWriter.append_event/2` for seeded audit history and keep audit payloads redaction-safe.
- **D-13:** Seed support/login trace evidence as `domain: :login` audit rows using the existing six-step login trace shape. Do not blur login traces with trust-mutation audit rows; LiveAdmin intentionally queries them through separate surfaces.

### Host-Owned Mapping And Session Boundary
- **D-14:** Add LedgerLoop-owned `UserMapper` and `SessionAdapter` modules for the demo. They should map a verified principal to seeded LedgerLoop users/SAML identities and demonstrate session or receipt establishment as host-owned work.
- **D-15:** Relyra verifies SAML trust and returns a verified principal. LedgerLoop owns account lookup/linking, group/role interpretation, product authorization, and any session/receipt persistence.
- **D-16:** Do not change `Relyra.start_login/3`, `Relyra.consume_response/3`, published behaviour callback signatures, or Phoenix route macro APIs to satisfy the demo. If planning discovers that a public API change is required, escalate before implementation.

### Proof Boundary
- **D-17:** Phase 52 should include a non-browser integration proof using real signed Relyra test support to exercise Ecto connection, request, and replay stores.
- **D-18:** Browser FakeIdP flow, browser receipts, and setup/operator UX remain later phases. Phase 52 may update existing placeholder pages or workspace status only enough to make seeded data inspectable without taking over Phase 53 or Phase 54.

### the agent's Discretion
- Planner may choose the exact LedgerLoop schema/module names, table names, seed module structure, and reset command shape as long as reset is deterministic and route/API/security boundaries above hold.
- Planner may choose whether seeded inspection is primarily through database assertions, the existing workspace shell, or mounted LiveAdmin, provided full setup UX and browser proof stay deferred.
- Planner may choose exact fixture values for Northstar users/groups and connection IDs, provided they are stable, readable, and safe to show in demo UI/tests.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Milestone Scope
- `.planning/ROADMAP.md` - Phase 52 goal, requirements, success criteria, and later-phase boundaries.
- `.planning/REQUIREMENTS.md` - DATA-01, DATA-02, ECTO-01, ECTO-02, ECTO-03, and ECTO-04.
- `.planning/PROJECT.md` - v1.7 milestone posture, non-goals, security invariants, and public API escalation rules.
- `.planning/STATE.md` - Current position and v1.7 accumulated decisions.
- `.planning/phases/51-demo-app-foundation/51-CONTEXT.md` - Demo app boundary, route shape, and Phase 52 handoff decisions.
- `.planning/phases/51-demo-app-foundation/51-01-SUMMARY.md` - Phoenix app scaffold and path dependency details.
- `.planning/phases/51-demo-app-foundation/51-02-SUMMARY.md` - Relyra route mount and LiveAdmin scope-provider details.
- `.planning/phases/51-demo-app-foundation/51-03-SUMMARY.md` - Health/readiness behavior and test overrides.
- `.planning/phases/51-demo-app-foundation/51-04-SUMMARY.md` - Workspace and placeholder route content.
- `.planning/phases/51-demo-app-foundation/51-05-SUMMARY.md` - Workspace styling and first-screen forbidden-token tests.
- `.planning/phases/51-demo-app-foundation/51-06-SUMMARY.md` - Demo package exclusion and repo-local runnability proof.
- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md` - v1.7 demo research and proof obligations.
- `.planning/seeds/SEED-001-adoption-evidence-demo.md` - Original adoption-evidence demo seed.

### Demo App
- `demo/ledger_loop/mix.exs` - Demo aliases, local Relyra path dependency, and app dependencies.
- `demo/ledger_loop/config/config.exs` - Application configuration entry point for Relyra runtime adapter settings.
- `demo/ledger_loop/config/dev.exs` - Local database config and server config.
- `demo/ledger_loop/config/test.exs` - Sandbox-backed test database config.
- `demo/ledger_loop/lib/ledger_loop/application.ex` - Demo supervision tree.
- `demo/ledger_loop/lib/ledger_loop/repo.ex` - Host Ecto repo.
- `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex` - Host-owned LiveAdmin scope provider.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - Mounted `/saml` and `/relyra/admin` routes.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` - Current workspace shell that Phase 52 can populate from seeded data.
- `demo/ledger_loop/priv/repo/seeds.exs` - Empty current seed script to replace or delegate from.
- `demo/ledger_loop/test/support/data_case.ex` - Demo app database test harness.

### Relyra Ecto And Store Seams
- `priv/repo/migrations/` - Shipped Relyra migration source; run from dependency path.
- `lib/relyra/connection_resolver/ecto.ex` - Persisted connection resolver adapter.
- `lib/relyra/ecto/connection_loader.ex` - Runtime readiness checks and mapping row loading.
- `lib/relyra/ecto/connection_snapshot.ex` - Persisted aggregate to runtime connection hydration.
- `lib/relyra/ecto/connection.ex` - Relyra connection schema and runtime readiness contract.
- `lib/relyra/ecto/certificate.ex` - Certificate lifecycle schema.
- `lib/relyra/ecto/attribute_mapping.ex` - Persisted attribute mapping schema.
- `lib/relyra/ecto/group_mapping.ex` - Persisted group mapping schema.
- `lib/relyra/ecto/mapping_commands.ex` - Mapping replacement plus co-committed audit pattern.
- `lib/relyra/ecto/audit_writer.ex` - Redaction-safe audit append seam.
- `lib/relyra/ecto/audit_event.ex` - Audit domain/action schema including `:login`.
- `lib/relyra/request_store/ecto.ex` - Raw-SQL Ecto request store adapter and required table shape.
- `lib/relyra/replay_store/ecto.ex` - Raw-SQL Ecto replay store adapter and required table shape.
- `lib/relyra/request_store.ex` - Request store dispatch contract.
- `lib/relyra/replay_store.ex` - Replay store dispatch contract.
- `lib/relyra/user_mapper.ex` - Host-owned mapping behaviour.
- `lib/relyra/session_adapter.ex` - Host-owned session behaviour.
- `lib/relyra.ex` - `start_login/3`, `consume_response/3`, request intent, replay, and session handoff flow.

### Existing Proof And Fixtures
- `test/support/adoption_fixtures.ex` - Existing adoption fixtures; useful patterns, but request/replay still use ETS and must not be copied as final posture.
- `test/adoption/journey_04_ecto_production_path_test.exs` - Ecto connection resolver proof that Phase 52 must extend to Ecto request/replay stores.
- `test/security/stores/request_store_ecto_test.exs` - Ecto request store concurrency semantics and expected adapter behavior.
- `test/security/stores/replay_store_ecto_test.exs` - Ecto replay store duplicate/concurrency semantics and expected adapter behavior.
- `test/support/migration_case.ex` - Existing pattern for running Relyra migrations from `priv/repo/migrations`.
- `test/relyra/live_admin/phase15_ui_contract_test.exs` - Canonical seeded login trace audit row shape.
- `lib/relyra/telemetry/handlers/login_trace.ex` - Real login trace persistence shape.
- `lib/relyra/login_trace/export.ex` - Redacted trace export shape used by LiveAdmin and CLI.
- `lib/relyra/live_admin/query.ex` - LiveAdmin connection and login trace query separation.
- `lib/relyra/live_admin/connection_trace_live.ex` - Existing trace UI consumer of seeded `domain: :login` rows.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `demo/ledger_loop` is already a normal Phoenix app with `LedgerLoop.Repo`, path dependency on Relyra, `/saml` route mounts, `/relyra/admin` LiveAdmin mount, and health/readiness probes.
- `Relyra.ConnectionResolver.Ecto` can hydrate runtime `%Relyra.Connection{}` snapshots from Relyra tables when the repo is provided.
- `Relyra.RequestStore.Ecto` expects a table with `relay_state`, `request_id`, `intent`, `consumed_at`, and `expires_at`; it inserts, fetches, and consumes rows by raw SQL.
- `Relyra.ReplayStore.Ecto` expects a table with `replay_key`, `inserted_at`, and `metadata`; uniqueness on `replay_key` is the replay gate.
- `Relyra.Ecto.AuditWriter.append_event/2` redacts sensitive keys and validates bounded audit payloads.
- `Relyra.LiveAdmin.Query.get_login_traces/4` already reads `domain: :login` audit rows and exports them safely for UI/CLI.
- `Relyra.TestSupport.FakeIdP` / `XmldsigSigner` can create real signed responses for non-browser integration proof.

### Established Patterns
- Relyra trust mutations co-commit audit rows through `AuditWriter`; login traces are append-only audit rows outside trust-mutation transactions and are queried separately.
- Runtime controllers read Relyra options from `conn.assigns[:relyra_opts]` or `Application.get_all_env(:relyra)`, so the demo can configure adapter modules and repo/table wrapper behavior without public API changes.
- Existing adoption fixtures prove Ecto connection resolution but intentionally configure ETS request/replay stores; Phase 52 is the closure point for that known adoption-evidence gap.
- Phase 51 kept setup/login/support pages as stable host-owned placeholders. Phase 52 can enrich them lightly with seeded state but should not implement full setup UX or browser SAML proof.

### Integration Points
- `demo/ledger_loop/config/config.exs` or environment-specific config should set Relyra runtime adapters for the demo app.
- `demo/ledger_loop/priv/repo/migrations/` should gain host-owned migrations for LedgerLoop data and Ecto request/replay store tables.
- `demo/ledger_loop/priv/repo/seeds.exs` should call a deterministic reset/seed module rather than hold large ad hoc script logic.
- `demo/ledger_loop/test/support/data_case.ex` should support database proofs for deterministic reset and store behavior.
- Mounted LiveAdmin can inspect seeded Relyra connections once admin session setup is available; Phase 52 may verify query-level visibility without building the Phase 53 UX.
</code_context>

<specifics>
## Specific Ideas

- Seed user/group examples should be realistic and safe to display, such as `maya.chen@northstar.example`, `samir.patel@northstar.example`, `finance-approvers`, and `support-readonly`.
- Seed connection scenario labels should make status obvious: enabled happy path, draft/missing metadata, staged certificate rollover, and support failure.
- Seed login trace rows should use the six existing step names: `response.decode`, `response.validate`, `signature.verify`, `replay.check`, `user.map`, and `session.establish`.
- Receipts or row summaries must say Relyra verified the principal and LedgerLoop owns mapping/session/authorization, but full receipt UX belongs to Phase 53/54.
</specifics>

<deferred>
## Deferred Ideas

- Customer/admin setup checklist, mapping preview UX, enablement receipt, and support handoff pages remain Phase 53.
- Browser-visible FakeIdP login proof remains Phase 54.
- Docker scripts, Compose profiles, focused `mix ci.demo_app`, browser E2E, and optional Keycloak proof remain Phase 55.
- README/demo guide evidence polish remains Phase 56.
- Promoting reusable customer setup components into Relyra core remains a future productization candidate after demo evidence proves stable boundaries.

### Reviewed Todos (not folded)
None - no matching pending todos were found for Phase 52.
</deferred>

---

*Phase: 52-ecto-stores-and-deterministic-seed-story*
*Context gathered: 2026-06-12*
