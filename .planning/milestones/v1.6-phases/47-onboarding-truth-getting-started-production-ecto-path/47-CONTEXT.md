# Phase 47: Onboarding truth — Getting Started & production Ecto path - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the adoption-truth gap between "scaffold compiles" and "first verified browser login" by promoting the `TestSupport` macro pattern in Getting Started, and give adopters a single authoritative production Ecto deployment path without reading source. Doc-only — ADOPT-01 and ADOPT-02. No new SAML protocol surface, no public API changes, no new Mix tasks beyond doc/CI wiring.
</domain>

<decisions>
## Implementation Decisions

### TestSupport macro as §3 primary path (ADOPT-01)
- **D-01:** Rewrite `guides/getting_started.md` §3 around `use Relyra.TestSupport, endpoint: MyRouter` + `setup_saml_connection/2` + `post_saml_response/2`, citing `test/test_support_demo_test.exs` as the canonical copy-paste reference.
- **D-02:** Demote the current low-level `build_saml_response/0` + `sign_saml_response/0` snippet to an appendix section ("Advanced: manual response construction") — do not delete; power users and deep-research docs still reference the builder chain.
- **D-03:** Document the minimal demo router/controller pattern from `test/test_support_demo_test.exs` (ACS `post("/:connection_id/acs", ...)` route + controller that assigns `:current_user`) as part of §3 — `post_saml_response/2` requires an `endpoint` and raises without `:path` or prior `setup_saml_connection/2` with `:connection_id`.
- **D-04:** §3 receipt stays "host-side test succeeds with a concrete login assertion" — use `assert_saml_login/2` or `saml_login/1` from the demo test as the documented success signal.

### Production Ecto path as linked guide (ADOPT-02)
- **D-05:** Create `guides/production_ecto_path.md` as a dedicated guide; link from Getting Started §5 and `guides/overview.md` Day-2 — do not inline the full Ecto path into Getting Started (keeps Day-1 lean; Phase 46 established overview as the Day-2 hub).
- **D-06:** Migration instructions: run Relyra's shipped migrations from `:relyra`'s `priv/repo/migrations/` via `Ecto.Migrator.run/4` (same pattern as `test/support/migration_case.ex`), with a one-time host-app Mix alias example — `mix relyra.install` does not copy migrations.
- **D-07:** Document the config upgrade from install defaults to production Ecto adapters:
  ```elixir
  config :relyra,
    connection_resolver: Relyra.ConnectionResolver.Ecto,
    request_store: Relyra.RequestStore.Ecto,
    replay_store: Relyra.ReplayStore.Ecto
  ```
  Include wiring the host `Connections` module to delegate to `ConnectionResolver.Ecto` with `opts[:repo]`.
- **D-08:** Replay-store warning docs the **actual** mechanism: set `config :relyra, prod_runtime_ets_warning: true` in production to trigger `Logger.warning` when ETS stores are used — **not** automatic on `Mix.env() == :prod`. Explain why install scaffolds ETS defaults (dev/single-node) and why Ecto adapters are required for cluster-safe production.

### Cross-doc sync & CI gates
- **D-09:** Update `guides/overview.md` Day-1 step 2 from "FakeIdP" to the TestSupport macro path; add Production Ecto path link under Day-2.
- **D-10:** Add `cmd test -f guides/production_ecto_path.md` to `mix ci.docs` alias in `mix.exs`.
- **D-11:** No new drift test for this phase unless research finds a concrete rot vector (copy-paste code block with behaviour callbacks). Presence guard per D-10 is sufficient per ROADMAP SC#3.
- **D-12:** `test/test_support_demo_test.exs` already runs in `ci.docs` — keep it green; doc changes must not break the demo test contract.

### Claude's Discretion
- Exact appendix title and placement in Getting Started (appendix vs subsection at end of §3).
- Host-app Mix alias naming and exact `Ecto.Migrator.run/4` snippet shape for migration instructions.
- Production Ecto guide section ordering (migrations → resolver → stores → replay warning vs stores-first).
- Whether Getting Started §3 includes a trimmed inline code block or primarily links to `test_support_demo_test.exs` with commentary.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 47 goal, success criteria, ADOPT-01/02 requirements.
- `.planning/REQUIREMENTS.md` — ADOPT-01, ADOPT-02 definitions.
- `.planning/PROJECT.md` — v1.6 Adoption Truth milestone goal; doc-only boundary; production replay-store invariant.
- `.planning/STATE.md` — ci.docs gates; Phase 46 overview hub pattern.
- `.planning/threads/v1-6-milestone-assessment-2026-05-27.md` — Original adoption-truth wedge assessment (TestSupport macro + Ecto path gap).

### Prior Phase Context
- `.planning/milestones/v1.5-phases/46-adopter-dx-ergonomics/46-CONTEXT.md` — overview.md hub, ci.docs presence-gate pattern, Getting Started stays ExDoc main.

### Implementation Touchpoints
- `guides/getting_started.md` — §3 rewrite target (ADOPT-01); §5 link to production Ecto guide.
- `guides/overview.md` — Day-1/Day-2 cross-link updates (D-09).
- `guides/production_ecto_path.md` — **new file** (ADOPT-02).
- `test/test_support_demo_test.exs` — Canonical macro-pattern reference for §3.
- `lib/relyra/test_support.ex` — Macro API (`setup_saml_connection/2`, `post_saml_response/2`, assertions).
- `lib/mix/tasks/relyra.install.ex` — Install defaults (Default resolver + ETS stores) that production guide upgrades from.
- `lib/relyra/connection_resolver/ecto.ex` — Ecto resolver adapter contract.
- `lib/relyra/request_store/ecto.ex` — Ecto request store adapter.
- `lib/relyra/replay_store/ecto.ex` — Ecto replay store adapter.
- `lib/relyra/replay_store/ets.ex` — `prod_runtime_ets_warning` mechanism and warning text.
- `lib/relyra/request_store/ets.ex` — ETS warning text for request store.
- `priv/repo/migrations/` — Shipped migration corpus (13 files).
- `test/support/migration_case.ex` — Authoritative `Ecto.Migrator.run/4` pattern.
- `mix.exs` — `ci.docs` alias; ExDoc extras list (add production guide if appropriate).
- `test/docs/logout_recipe_drift_test.exs` — Reference for when drift tests are warranted (behaviour callback copy-paste blocks).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.TestSupport` macro — complete SSO round-trip helpers with Phoenix.ConnTest integration (`lib/relyra/test_support.ex`).
- `Relyra.TestSupportDemoTest` — minimal router + controller + two tests demonstrating the adopter path (`test/test_support_demo_test.exs`).
- `Relyra.TestSupport.MigrationCase` — `Ecto.Migrator.run(repo, migrations_path, :up, all: true)` against `priv/repo/migrations/` (`test/support/migration_case.ex`).
- Ecto adapters — `ConnectionResolver.Ecto`, `RequestStore.Ecto`, `ReplayStore.Ecto` all require `opts[:repo]`.

### Established Patterns
- `mix relyra.install` scaffolds `connection_resolver: Default`, `request_store: ETS`, `replay_store: ETS` — production guide documents the upgrade path.
- Phase 46 `ci.docs` uses `cmd test -f` presence gates + dedicated `cmd mix test` drift lanes (Phase 30 hollow-gate invariant).
- Getting Started is ExDoc `main`; overview.md is the job-shaped navigation hub.
- ETS prod warning is opt-in via `Application.get_env(:relyra, :prod_runtime_ets_warning, false)` — not tied to `Mix.env()`.

### Integration Points
- Getting Started §3 → demo test reference → host app test suite.
- Getting Started §5 + overview Day-2 → `guides/production_ecto_path.md`.
- `mix ci.docs` → presence guard for new guide + existing `test_support_demo_test.exs` gate.
</code_context>

<specifics>
## Specific Ideas

- v1.6 assessment flagged the exact gap: adopters stuck between "scaffold compiles" and "browser login works" because Getting Started shows builder/sign primitives without router dispatch.
- Linked guide preferred over bloating Getting Started §5 — user confirmed assumptions without correction.
</specifics>

<deferred>
## Deferred Ideas

- Update `guides/case_studies/phoenix_saas_tenant_onboarding.md` and provider runbooks' "FakeIdP proof" references — not in Phase 47 success criteria; coordinate with Phase 49 preset/taxonomy alignment if needed.
- Phase 48: login-trace route + `mix relyra.trace` in incident playbook tool table (ADOPT-03).
- Phase 49: CONFORMANCE honesty, jtbd_gap_map refresh, preset taxonomy alignment (ADOPT-04/05/06).
</deferred>

---

*Phase: 47-onboarding-truth-getting-started-production-ecto-path*
*Context gathered: 2026-05-27*
