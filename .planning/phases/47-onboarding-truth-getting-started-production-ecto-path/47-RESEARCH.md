# Phase 47 Research: Onboarding truth — Getting Started & production Ecto path

**Researched:** 2026-05-27  
**Phase:** 47 — Onboarding truth — Getting Started & production Ecto path  
**Requirements:** ADOPT-01, ADOPT-02  
**Status:** Ready for planning

---

## 1. Executive Summary

Phase 47 closes a doc-only adoption-truth gap: adopters currently stall between “scaffold compiles” and “login works” because Getting Started §3 shows low-level `build_saml_response/0` + `sign_saml_response/0` without the router dispatch path, and there is no authoritative production Ecto deployment guide anywhere in `guides/`.

**ADOPT-01** rewrites §3 around the existing `Relyra.TestSupport` macro pattern already proven in `test/test_support_demo_test.exs` (in `mix ci.docs` today). The demo test is the canonical copy-paste reference; manual builder/sign moves to an appendix.

**ADOPT-02** creates `guides/production_ecto_path.md` as a linked Day-2 guide (not inlined into Getting Started §5). It must document: running Relyra’s 13 shipped connection/mapping/audit migrations from the dep path, upgrading install defaults to Ecto adapters, host-owned store table DDL (not shipped), the `:repo` wiring contract, and the opt-in `prod_runtime_ets_warning` mechanism.

**Critical research findings for planners:**

1. **§3 gap is real and precise:** current docs stop at signed XML construction; the demo test adds `use Relyra.TestSupport, endpoint: …`, `setup_saml_connection/2`, `post_saml_response/2`, and `assert_saml_login/2` with a minimal ACS router/controller stub.
2. **Ecto store adapters require both `:repo` and `:table` per call**, but both `RequestStore.Ecto` and `ReplayStore.Ecto` read the same `opts[:table]` key. A flat `config :relyra, table: …` cannot serve both stores — the production guide must recommend thin host wrapper modules (same pattern as install’s `Connections` behaviour stub).
3. **Store tables are host-owned.** Shipped migrations under `priv/repo/migrations/` create connection/metadata/mapping/audit tables only — no `request_intents` or `replay_keys` migrations ship with Relyra.
4. **ETS prod warning is opt-in**, not `Mix.env() == :prod`. Docs must say `config :relyra, prod_runtime_ets_warning: true` in `config/runtime.exs` (or prod config).
5. **No drift test warranted (D-11).** New content is narrative + config snippets, not behaviour-callback copy-paste blocks. Presence guard + existing `test_support_demo_test.exs` gate suffice.

**Recommended plan split:** two waves — (1) ADOPT-01 Getting Started + overview Day-1, (2) ADOPT-02 production guide + cross-doc/CI wiring.

---

## 2. Current State Analysis

### Getting Started §3 today (`guides/getting_started.md:67–95`)

| Aspect | Current doc | Canonical demo (`test/test_support_demo_test.exs`) |
|--------|-------------|-----------------------------------------------------|
| Title/framing | “Prove local login with FakeIdP” | Same intent, but macro-driven round-trip |
| Entry point | `Relyra.TestSupport.fake_idp_metadata()` + manual pipeline | `use Relyra.TestSupport, endpoint: MyRouter` |
| Response construction | `build_saml_response()` → `sign_saml_response()` only | Same builders, then **dispatch** via `post_saml_response/2` |
| Router/controller | **Not mentioned** | Minimal `post("/:connection_id/acs", …)` + controller assigning `:current_user` |
| Connection setup | **Not mentioned** | `setup_saml_connection(conn, connection_id: "demo")` |
| Success receipt | “passing test or successful login result” (vague) | `assert_saml_login(conn, %{email: …})` or `saml_login(conn) == {:ok, …}` |
| FakeIdP role | Named as primary path | Underlying signer for `build_saml_response/sign_saml_response`; macro hides PEM details |

**What §3 omits that blocks adopters:**

- `post_saml_response/3` **requires** `:endpoint` (from macro) and either `:path` or a prior `setup_saml_connection/2` with `:connection_id` — otherwise it raises `ArgumentError` (`lib/relyra/test_support.ex:67–76`).
- Without a test router + ACS route, signed XML has nowhere to go; adopters cannot complete a round-trip test.
- The demo uses a **stub controller** that assigns `:current_user` directly — it does not exercise `Relyra.Phoenix.Controllers.ACSController` / `consume_response/3`. §3 should state this clearly: §3 proves TestSupport + host ACS wiring; §4 provider runbooks prove real IdP + `saml_routes()`.

### overview.md Day-1 (`guides/overview.md:10–16`)

Step 2 still says “Prove local sign-in with `Relyra.TestSupport.FakeIdP`” — must align with macro path per D-09. Day-2 has no Production Ecto link yet.

### Production Ecto path

**No dedicated guide exists.** Only a troubleshooting atom entry mentions `ConnectionResolver.Ecto` requires a started repo and applied migrations (`guides/troubleshooting.md:1104–1106`). Install scaffolds ETS defaults (`lib/mix/tasks/relyra.install.ex:81–84`) and does not copy migrations.

### Assessment thread origin

`.planning/threads/v1-6-milestone-assessment-2026-05-27.md` flagged docs/onboarding at ~85% with this exact wedge — matches Phase 47 scope.

---

## 3. TestSupport Macro API

Source: `lib/relyra/test_support.ex`, `test/test_support_demo_test.exs`.

### Macro invocation

```elixir
use Relyra.TestSupport, endpoint: MyAppWeb.TestRouter
# optional: connection_resolver: SomeModule  (default: Relyra.ConnectionResolver.Default)
```

**Required:** `endpoint:` — a `Phoenix.Router` module for `Phoenix.ConnTest.dispatch/5`.

### Functions imported by macro

| Function | Signature | Notes |
|----------|-----------|-------|
| `setup_saml_connection/2` | `(conn, opts \\ []) :: conn` | Sets `:relyra_opts`, `:relyra_connection_id`, `:relyra_resolver`. Merges default `connection_resolver: Default`. |
| `post_saml_response/3` | `(conn, response_xml, opts \\ []) :: conn` | Base64-encodes XML into POST params; dispatches to `@endpoint`. Path = `"/#{connection_id}/acs"` when `connection_id` set. |
| `fake_idp_metadata/0` | `() :: String.t()` | Delegates to `FakeIdP.metadata/0` |
| `build_saml_response/1` | `(opts \\ [])` | Delegates to `FakeIdP.build_response/1` |
| `sign_saml_response/2` | `(builder, opts \\ [])` | Delegates to `FakeIdP.sign/2` |
| `saml_login/1` | `(conn) :: {:ok, term()} \| {:error, :no_saml_login}` | Reads `:current_user` assign |

### Assertion macros (`Relyra.TestSupport.Assertions`)

| Macro | Purpose |
|-------|---------|
| `assert_saml_login(conn, pattern)` | Asserts `conn.assigns.current_user` matches `pattern` (compile-time pattern required — no `_`) |
| `assert_saml_error(conn, pattern)` | Asserts status 400, body contains `"SAML Authentication Error"` and `inspect(pattern)` |

### Prerequisites and constraints

1. **Test-only:** `@prod_build` guard raises `"Relyra.TestSupport is test-only"` in prod (`lib/relyra/test_support.ex:103–107`).
2. **Phoenix.ConnTest:** macro imports `Phoenix.ConnTest`, `Plug.Conn` — host test needs Phoenix test deps.
3. **Minimal router pattern** (from demo):

```elixir
defmodule MyAppWeb.TestRouter do
  use Phoenix.Router
  post("/:connection_id/acs", MyAppWeb.TestAcsController, :acs)
end

defmodule MyAppWeb.TestAcsController do
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]
  def acs(conn, _params) do
    conn |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"}) |> Phoenix.Controller.text("ok")
  end
end
```

4. **Production router difference:** real apps use `import Relyra.Phoenix.Router; saml_routes()` which mounts `Relyra.Phoenix.Controllers.ACSController` at the same `POST /:connection_id/acs` path (`lib/relyra/phoenix/router.ex:18–22`). §3 stub is intentional simplification for first receipt.
5. **Demo test in CI:** `mix ci.docs` runs `test/test_support_demo_test.exs` — doc changes must not break this contract (D-12).

### Canonical test flow (copy-paste skeleton)

```elixir
defmodule MyApp.SamlLoginTest do
  use ExUnit.Case, async: false
  use Relyra.TestSupport, endpoint: MyAppWeb.TestRouter

  test "local SAML round-trip" do
    conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")
    response = build_saml_response() |> sign_saml_response()
    conn = post_saml_response(conn, Base.decode64!(response, padding: false))
    assert_saml_login(conn, %{email: "alice@example.com"})
  end
end
```

Reference file: `test/test_support_demo_test.exs:17–36`.

---

## 4. Production Ecto Path

### Install defaults vs production target

**Install scaffolds** (`lib/mix/tasks/relyra.install.ex:81–84`, `205–216`):

```elixir
config :relyra,
  connection_resolver: Relyra.ConnectionResolver.Default,
  request_store: Relyra.RequestStore.ETS,
  replay_store: Relyra.ReplayStore.ETS
```

Plus stub `MyApp.Relyra.Connections` implementing `@behaviour Relyra.ConnectionResolver` returning `:adapter_not_configured`.

**Production target** (D-07):

```elixir
config :relyra,
  connection_resolver: Relyra.ConnectionResolver.Ecto,  # or host Connections delegator
  request_store: MyApp.Relyra.RequestStore,            # wrapper recommended — see below
  replay_store: MyApp.Relyra.ReplayStore,              # wrapper recommended
  repo: MyApp.Repo,
  prod_runtime_ets_warning: true                        # prod config only — see §5
```

**Opts propagation:** Phoenix controllers read `conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)` (`lib/relyra/phoenix/controllers/acs_controller.ex:79–81`). All `:relyra` config keys become runtime opts — including `:repo`.

### Shipped migrations (13 files)

Path: `:relyra` dep → `priv/repo/migrations/` (authoritative runner: `test/support/migration_case.ex:10,96–99`).

| Migration | Purpose |
|-----------|---------|
| `20260505120000_create_relyra_connections.exs` | Core connection records |
| `20260505120100_create_relyra_connection_certificates.exs` | IdP cert inventory |
| `20260505130000_add_metadata_revision_pointers_to_relyra_connections.exs` | Metadata revision FKs |
| `20260505130100_create_relyra_metadata_sources.exs` | Metadata source registry |
| `20260505130200_create_relyra_metadata_revisions.exs` | Metadata revision history |
| `20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs` | Cert lifecycle columns |
| `20260505183000_harden_relyra_certificate_lifecycle_invariants.exs` | Cert invariants |
| `20260505190000_create_relyra_mapping_and_audit_tables.exs` | Attribute/group mappings + audit |
| `20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` | IdP-initiated flag |
| `20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` | Auto-refresh metadata |
| `20260525100000_add_party_and_use_to_relyra_connection_certificates.exs` | Cert party/use |
| `20260525100001_add_sign_authn_requests_to_relyra_connections.exs` | Signed AuthnRequest flag |
| `20260526120943_add_signed_request_encoding_to_relyra_connections.exs` | Encoding enum |

**`mix relyra.install` does not copy these** — host must run them from the dependency path.

### Migration runner pattern (from `migration_case.ex`)

```elixir
migrations_path = Application.app_dir(:relyra, "priv/repo/migrations")

Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
  Ecto.Migrator.run(repo, migrations_path, :up, all: true)
end)
```

**Host Mix alias example** (planner discretion on naming):

```elixir
# mix.exs
defp aliases do
  [
    "ecto.setup.relyra": [
      "ecto.create",
      "ecto.migrate",
      "relyra.migrate"  # custom alias invoking Migrator.run/4 above
    ]
  ]
end
```

Idempotent re-runs: Ecto tracks versions in `schema_migrations`; safe to call on deploy.

### ConnectionResolver.Ecto

- Behaviour: `Relyra.ConnectionResolver` (`lib/relyra/connection_resolver/ecto.ex`)
- Requires `opts[:repo]` — returns normalized `%Relyra.Connection{}` snapshot
- Request context: `%{connection_id: "…"}` (binary, non-empty)
- Verified in `test/relyra/ecto/ecto_connection_resolver_test.exs`

**Host `Connections` delegator pattern** (D-07 — keeps install-generated module useful):

```elixir
defmodule MyApp.Relyra.Connections do
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(request_context, opts) do
    Relyra.ConnectionResolver.Ecto.resolve_connection(
      request_context,
      Keyword.put_new(opts, :repo, MyApp.Repo)
    )
  end
end
```

Then set `connection_resolver: MyApp.Relyra.Connections` in config. Either direct Ecto adapter or delegator works; delegator matches install scaffold naming.

### RequestStore.Ecto / ReplayStore.Ecto

Both require **`opts[:repo]` and `opts[:table]`** on every call (`lib/relyra/request_store/ecto.ex:255–286`, `lib/relyra/replay_store/ecto.ex:64–95`).

**SQL contracts (for host DDL):**

**Request intents table** — columns used by adapter:
- `relay_state` (text, unique lookup key)
- `request_id` (text)
- `intent` (map/jsonb)
- `consumed_at` (utc datetime, nullable)
- `expires_at` (utc datetime)

**Replay keys table** — columns:
- `replay_key` (text, unique)
- `inserted_at` (utc datetime)
- `metadata` (map/jsonb)

Tests use table names `"request_intents"` and `"replay_keys"` (`test/security/stores/*_ecto_test.exs`).

### Critical gotcha: shared `:table` config key

Both Ecto store adapters fetch `Keyword.fetch(opts, :table)`. A single flat config:

```elixir
config :relyra, table: "request_intents"  # breaks replay store
```

**Cannot work for both stores simultaneously.** Production guide must document **thin host wrapper modules** that merge the correct table:

```elixir
defmodule MyApp.Relyra.RequestStore do
  @behaviour Relyra.RequestStore
  @repo MyApp.Repo
  @table "relyra_request_intents"

  def put_intent(rs, intent, opts), do: Relyra.RequestStore.Ecto.put_intent(rs, intent, store_opts(opts))
  def fetch_intent(rs, opts), do: Relyra.RequestStore.Ecto.fetch_intent(rs, store_opts(opts))
  def consume_intent(rs, rid, opts), do: Relyra.RequestStore.Ecto.consume_intent(rs, rid, store_opts(opts))

  defp store_opts(opts), do: Keyword.merge(opts, repo: @repo, table: @table)
end
```

(Symmetric wrapper for `ReplayStore` with `"relyra_replay_keys"`.)

This is **doc-only phase scope** — do not change adapter API; document the wrapper pattern as the production path.

### Optional dependencies

Ecto adapters check `Code.ensure_loaded?(Ecto.Repo)` — host must declare `{:ecto, …}`, `{:ecto_sql, …}`, `{:postgrex, …}` (already optional in Relyra `mix.exs:85–87`).

### Upgrade checklist (guide section order recommendation)

1. **Why:** install ETS defaults are dev/single-node; production needs durable cluster-safe stores.
2. **Run Relyra migrations** from dep path (13 files above).
3. **Create host store tables** (DDL + unique indexes on `relay_state` / `replay_key`).
4. **Implement store wrappers** (table + repo injection).
5. **Wire Connections** delegator (or point config at `ConnectionResolver.Ecto` + `repo:`).
6. **Update config** — swap adapters, add `repo:`, enable `prod_runtime_ets_warning` in prod.
7. **Receipt:** persisted connection resolves via Ecto; login succeeds with Ecto stores; ETS warning absent after swap.

---

## 5. Replay Store Warning

### Mechanism

Both `Relyra.ReplayStore.ETS` and `Relyra.RequestStore.ETS` call `warn_prod_ets!/1` on table access.

**Trigger conditions** (`lib/relyra/replay_store/ets.ex:92–101`, mirrored in request store):

1. Explicit opt: `opts[:prod_runtime?] == true` on the adapter call, **or**
2. App config: `Application.get_env(:relyra, :prod_runtime_ets_warning, false) == true`

**Not tied to `Mix.env() == :prod`.** Install leaves `prod_runtime_ets_warning` unset (defaults false).

### Exact warning text

**ReplayStore.ETS** (`lib/relyra/replay_store/ets.ex:84–86`):

> Relyra.ReplayStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe replay guarantees.

**RequestStore.ETS** (`lib/relyra/request_store/ets.ex:153–155`):

> Relyra.RequestStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe request intent semantics.

### Production doc guidance

```elixir
# config/runtime.exs (prod)
config :relyra, prod_runtime_ets_warning: true
```

Explain: this logs a loud warning if ETS stores are still hit at runtime — a safety net during migration, not a substitute for Ecto adapters. After ETS→Ecto swap, warnings should stop (adapters no longer call `warn_prod_ets!/1`).

Security tests verify both opt and env paths (`test/security/stores/replay_store_ets_test.exs:51–79`, `request_store_ets_test.exs:67–93`).

---

## 6. Cross-doc Sync Points

| Touchpoint | Change | Requirement |
|------------|--------|-------------|
| `guides/getting_started.md` §3 | Rewrite around TestSupport macro; appendix for manual builder | ADOPT-01, D-01–D-04 |
| `guides/getting_started.md` §5 | Link to `production_ecto_path.md` in follow-on references | ADOPT-02, D-05 |
| `guides/overview.md` Day-1 step 2 | FakeIdP → TestSupport macro path | D-09 |
| `guides/overview.md` Day-2 | Add Production Ecto path link | D-05, D-09 |
| `guides/production_ecto_path.md` | **New file** | ADOPT-02 |
| `mix.exs` `ci.docs` | Add `"cmd test -f guides/production_ecto_path.md"` | D-10 |
| `mix.exs` `docs/0` extras | Add `"guides/production_ecto_path.md"` (after identity mapping or in Day-2 cluster) | Phase 46 pattern (overview added to extras in 46-03) |
| `test/test_support_demo_test.exs` | Keep green — no structural changes expected | D-12 |

**Explicitly deferred (not Phase 47 SC):** `guides/case_studies/phoenix_saas_tenant_onboarding.md`, provider runbooks, `guides/jtbd_user_flows.md` FakeIdP references — still say FakeIdP; coordinate with Phase 49 if needed (`47-CONTEXT.md:111`).

**ExDoc main stays** `"getting_started"` — do not change (`46-CONTEXT.md` D-09 precedent).

**Link style:** relative markdown paths for ExDoc compatibility (`46-PATTERNS.md`).

---

## 7. Drift Test Assessment (D-11)

### When drift tests exist in this repo

| Test | Drift target | Why drift test |
|------|--------------|----------------|
| `test/docs/logout_recipe_drift_test.exs` | `SessionAdapter` callback heads in `guides/recipes/logout.md` | Copy-paste behaviour implementation — arity drift breaks host compile |
| `test/docs/troubleshooting_drift_test.exs` | Error atom taxonomy vs `lib/` | Bidirectional atom parity |

### Phase 47 content profile

- Getting Started §3: references demo test file; may include trimmed inline blocks mirroring **TestSupport API** (stable macro surface).
- Production Ecto guide: config snippets, DDL examples, delegator/wrapper modules — **not** `@behaviour` callback heads adopters paste for compile-time enforcement.

### Verdict: presence guard sufficient

Per D-11 and ROADMAP SC#3:

1. Add `cmd test -f guides/production_ecto_path.md` to `ci.docs`.
2. Existing `test/test_support_demo_test.exs` in `ci.docs` gates the canonical §3 reference — if TestSupport API changes, demo test fails first.
3. **No new drift test** unless planning introduces behaviour-callback copy-paste blocks (e.g., full `SessionAdapter`-style store wrapper templates with `@impl` heads) — if so, reconsider arity gate; current recommendation is wrapper examples without `@behaviour` enforcement blocks to avoid false precision.

**Hollow-gate invariant:** any future drift test must be its own `cmd mix test test/docs/...` line in `ci.docs`, never bundled with bare `test` steps (Phase 30).

---

## 8. Validation Architecture (Nyquist)

| Deliverable | Verification command / test | Layer |
|-------------|----------------------------|-------|
| §3 rewrite promotes macro path | Manual: read `guides/getting_started.md`; grep for `setup_saml_connection`, `post_saml_response`, `test_support_demo_test` | UAT |
| Appendix retains manual builder | grep `build_saml_response` still present (appendix) | UAT |
| `production_ecto_path.md` exists | `cmd test -f guides/production_ecto_path.md` in `ci.docs` | CI presence |
| Guide covers migrations, resolver, stores, warning | Manual checklist against ADOPT-02 + §4 above | UAT |
| overview Day-1/Day-2 links | grep overview.md; `mix ci.docs` passes | CI + UAT |
| ExDoc discoverability | `grep production_ecto_path mix.exs` in extras; optional `mix docs` visual | CI + visual |
| Demo test contract intact | `mix test test/test_support_demo_test.exs --warnings-as-errors` (in `ci.docs`) | CI |
| No doc regressions | `mix ci.docs` full alias green | CI |
| Formatting | `mix format --check-formatted` | CI (via `mix qa`) |
| Full verify lane | `mix ci.verify` includes `ci.docs` | CI |

**Nyquist sampling rates:**

- **High frequency (every PR):** `mix ci.docs`
- **Medium:** `mix ci.verify` on doc-heavy changes
- **UAT (phase complete):** human follows Getting Started §1–3 in a scratch host app using only docs; human follows production guide checklist against a dev DB

**No new security corpus rows** — doc-only phase.

---

## 9. Risks & Gotchas

| Risk | Severity | Mitigation in docs |
|------|----------|-------------------|
| Shared `:table` opt key for both Ecto stores | **High** | Document host wrapper modules; do not show single `table:` in flat config |
| Store tables not in shipped migrations | **High** | Explicit DDL section with column list from adapter SQL |
| §3 stub controller vs real ACSController | **Medium** | Clarify §3 = TestSupport receipt; `saml_routes()` = real integration (§2 scaffold) |
| Adopter expects `Mix.env()` prod warning | **Medium** | Explicit `prod_runtime_ets_warning: true` + “not automatic in prod” |
| Demo test uses `Base.decode64!` on signed response | **Low** | Note: `sign_saml_response` returns base64; decode before `post_saml_response` (matches demo line 32) |
| Connections stub left unimplemented | **Medium** | Production guide must show delegator replacing install stub |
| Optional Ecto deps missing in host | **Medium** | List required deps when enabling Ecto adapters |
| Over-scoping into runbook FakeIdP updates | **Low** | Defer per `47-CONTEXT.md` deferred list |
| ExDoc extras omission | **Low** | Add to `mix.exs` extras alongside other Day-2 guides |
| REQUIREMENTS.md says “ETS warns in prod” | **Low** | ADOPT-02 acceptance = document actual opt-in mechanism (research clarifies for planner) |

**Scope creep guard:** no new Mix tasks, no API changes, no install task changes — docs + `mix.exs` CI/ExDoc wiring only.

---

## 10. Recommended Plan Structure

### Wave 1 — ADOPT-01 (Getting Started truth)

**Plan 47-01: Rewrite Getting Started §3 + appendix**

- Rewrite §3 title/body around TestSupport macro pattern
- Include minimal router/controller snippet (from demo test)
- Point to `test/test_support_demo_test.exs` as canonical reference
- Move manual `build_saml_response/sign_saml_response` to appendix (“Advanced: manual response construction”)
- Define receipt: `assert_saml_login/2` or `saml_login/1`
- Update `guides/overview.md` Day-1 step 2 (D-09)

**Verify:** `mix test test/test_support_demo_test.exs --warnings-as-errors`; manual §3 read-through.

### Wave 2 — ADOPT-02 (Production Ecto path + CI)

**Plan 47-02: Create `guides/production_ecto_path.md`**

- Sections: why upgrade → migrations → store DDL → wrappers → Connections delegator → config → prod warning → receipt
- Host Mix alias for `Ecto.Migrator.run/4`
- Accurate `prod_runtime_ets_warning` docs (both store warning strings)

**Plan 47-03: Cross-doc sync + CI gates**

- Getting Started §5 link to production guide
- overview.md Day-2 link
- `mix.exs`: `ci.docs` presence gate + ExDoc extras entry
- Run full `mix ci.docs`

**Verify:** `mix ci.docs`; grep links; UAT checklist §8.

### Dependency graph

```
47-01 (§3 + overview Day-1)
    ↓
47-02 (production guide content)
    ↓
47-03 (§5 link, overview Day-2, mix.exs gates)
```

Plans 47-02 and 47-03 could merge if preferred single atomic doc commit; split keeps review focused.

### Out of scope (confirm in PLAN.md)

- Phase 48 trace tools (ADOPT-03)
- Phase 49 preset taxonomy / CONFORMANCE (ADOPT-04–06)
- Case study / runbook FakeIdP reference updates
- New drift tests (unless planner adds behaviour paste blocks)
- Code changes to Ecto adapters or install task

---

## RESEARCH COMPLETE
