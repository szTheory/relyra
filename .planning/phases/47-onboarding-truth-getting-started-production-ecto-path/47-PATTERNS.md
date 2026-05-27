# Phase 47 — Pattern Map

**Mapped:** 2026-05-27  
**Phase:** 47 — Onboarding truth — Getting Started & production Ecto path  
**Requirements:** ADOPT-01, ADOPT-02

---

## File Inventory

| File | Action | Role | Data Flow |
|------|--------|------|-----------|
| `guides/getting_started.md` | Modify | Day-1 canonical onboarding (ExDoc `main`) | Adopter → TestSupport macro → stub ACS router → `assert_saml_login/2` receipt |
| `guides/production_ecto_path.md` | **Create** | Day-2 operator guide (linked, not inlined) | Install ETS defaults → dep-path migrations → host store DDL → wrapper modules → prod config |
| `guides/overview.md` | Modify | Job-shaped doc hub | Day-1 step 2 → Getting Started §3; Day-2 → production Ecto guide |
| `mix.exs` | Modify | CI presence gate + ExDoc discoverability | `ci.docs` file-exists check; `docs/0` extras entry |
| `test/test_support_demo_test.exs` | Keep green (no structural change) | Canonical copy-paste contract for §3 | Demo router/controller → macro round-trip → CI gate in `ci.docs` |

**Reference-only (cite, do not modify in Phase 47):**

| File | Role in Phase 47 |
|------|------------------|
| `lib/relyra/test_support.ex` | Macro API surface §3 documents |
| `lib/mix/tasks/relyra.install.ex` | Install defaults the production guide upgrades from |
| `test/support/migration_case.ex` | Authoritative `Ecto.Migrator.run/4` pattern |
| `lib/relyra/connection_resolver/ecto.ex` | Resolver adapter + `:repo` contract |
| `lib/relyra/request_store/ecto.ex`, `lib/relyra/replay_store/ecto.ex` | Store adapters + `:repo`/`:table` contract |
| `lib/relyra/replay_store/ets.ex`, `lib/relyra/request_store/ets.ex` | `prod_runtime_ets_warning` mechanism |
| `priv/repo/migrations/*.exs` (13 files) | Shipped migration corpus |
| `test/docs/logout_recipe_drift_test.exs` | Negative pattern — drift test **not** warranted for Phase 47 |

---

## File Classification & Closest Analogs

### 1. `guides/getting_started.md` — §3 rewrite + appendix + §5 link

| Aspect | Value |
|--------|-------|
| **Role** | Primary adopter onboarding doc; ExDoc entry point |
| **Closest analog** | Current `guides/getting_started.md` section structure (numbered steps, Receipt blocks) + `guides/identity_mapping_and_provisioning.md` (operator voice, explicit Relyra-owns / host-owns boundaries) |
| **Pattern to replicate** | Numbered sections with **Receipt:** lines; relative markdown links; code blocks mirror runnable source |

**Current §3 (demote to appendix):**

```67:95:guides/getting_started.md
## 3. Prove local login with FakeIdP

Before touching a real IdP, prove the local trust path with
`Relyra.TestSupport.FakeIdP`. This is the default first proof because it signs
real SAML responses with deterministic local fixtures.

Use `Relyra.TestSupport` helpers in a host-side test so you can verify the core
flow without provider admin work:

```elixir
metadata = Relyra.TestSupport.fake_idp_metadata()

response =
  []
  |> Relyra.TestSupport.build_saml_response()
  |> Relyra.TestSupport.sign_saml_response()
```
// ...
Receipt: a host-side test or local smoke path succeeds with `FakeIdP`, and you
can point to the passing test or successful login result as your first SAML proof.
```

**Target §3 shape (from canonical demo test):**

```1:36:test/test_support_demo_test.exs
defmodule Relyra.TestSupportDemoRouter do
  use Phoenix.Router

  post("/:connection_id/acs", Relyra.TestSupportDemoController, :acs)
end

defmodule Relyra.TestSupportDemoController do
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

  def acs(conn, _params) do
    conn
    |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
    |> Phoenix.Controller.text("ok")
  end
end

defmodule Relyra.TestSupportDemoTest do
  use ExUnit.Case, async: false
  use Relyra.TestSupport, endpoint: Relyra.TestSupportDemoRouter

  test "adopters can write a tiny integration test" do
    conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")

    response = build_saml_response() |> sign_saml_response()
    conn = post_saml_response(conn, Base.decode64!(response, padding: false))

    assert_saml_login(conn, %{email: "alice@example.com"})
    assert saml_login(conn) == {:ok, %{email: "alice@example.com"}}
  end
end
```

**Macro prerequisites to document (raises without router path):**

```62:88:lib/relyra/test_support.ex
  def post_saml_response(conn, response_xml, opts \\ []) when is_binary(response_xml) do
    ensure_not_prod!()
    endpoint = Keyword.fetch!(opts, :endpoint)

    path =
      Keyword.get(opts, :path) ||
        case conn.assigns[:relyra_connection_id] do
          nil ->
            raise ArgumentError,
                  "post_saml_response/3 requires :path or a prior setup_saml_connection/2 with :connection_id"

          connection_id ->
            "/#{connection_id}/acs"
        end
    // ...
    Phoenix.ConnTest.dispatch(conn, endpoint, :post, path, params)
  end
```

**Production router contrast (§3 stub vs real integration — clarify in prose):**

```18:22:lib/relyra/phoenix/router.ex
        # ACS - inbound assertion
        post("/:connection_id/acs", ACSController, :create,
          as: :saml_acs,
          private: %{relyra_skip_csrf: true}
        )
```

**§5 link target pattern (follow existing follow-on references block):**

```148:155:guides/getting_started.md
Useful follow-on references:

- [guides/identity_mapping_and_provisioning.md](identity_mapping_and_provisioning.md)
  for the host-owned anchor, lookup, and JIT decisions that come after a
  working provider path.
- [Jobs To Be Done And User Flows](jtbd_user_flows.md)
- [`SECURITY.md`](../SECURITY.md)
- [`SECURITY_REVIEW.md`](../SECURITY_REVIEW.md)
```

Add: `[Production Ecto path](production_ecto_path.md)` in the same list.

---

### 2. `guides/production_ecto_path.md` — new Day-2 guide

| Aspect | Value |
|--------|-------|
| **Role** | Authoritative production Ecto deployment path (ADOPT-02) |
| **Closest analog** | `guides/identity_mapping_and_provisioning.md` — operator-facing, post-login, host-owned seams, sectioned checklist |
| **Secondary analog** | `guides/troubleshooting.md:1104–1106` — only existing Ecto resolver mention (too thin; expand into full guide) |
| **Pattern to replicate** | Overview → numbered upgrade checklist → code/config snippets → Receipt block |

**Install defaults (document as starting point):**

```80:85:lib/mix/tasks/relyra.install.ex
    #{sentinel_start}
    config :relyra,
      connection_resolver: Relyra.ConnectionResolver.Default,
      request_store: Relyra.RequestStore.ETS,
      replay_store: Relyra.ReplayStore.ETS
    #{sentinel_end}
```

**Install Connections stub (production guide replaces with delegator):**

```205:216:lib/mix/tasks/relyra.install.ex
  defp connection_template(module_name) do
    """
    defmodule #{module_name}.Relyra.Connections do
      @moduledoc false
      @behaviour Relyra.ConnectionResolver

      @impl true
      def resolve_connection(_request_context, _opts) do
        {:error, Relyra.Error.new(:adapter_not_configured, "Configure #{module_name}.Relyra.Connections", %{})}
      end
    end
    """
  end
```

**Migration runner (host Mix alias source of truth):**

```96:99:test/support/migration_case.ex
  defp migrate! do
    Migrator.with_repo(EctoTestRepo, fn repo ->
      Migrator.run(repo, @migrations_path, :up, all: true)
    end)
  end
```

Host-app variant uses `Application.app_dir(:relyra, "priv/repo/migrations")` instead of `@migrations_path`.

**Resolver delegator pattern (matches install scaffold naming):**

```elixir
# Document shape — from RESEARCH §4; no existing host-app file in repo
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

Verified resolver call shape in tests:

```27:30:test/relyra/ecto/ecto_connection_resolver_test.exs
    assert {:ok, %Connection{} = resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )
```

**Store wrapper pattern (required — shared `:table` config key gotcha):**

Both adapters fetch `opts[:table]` independently:

```270:285:lib/relyra/request_store/ecto.ex
  defp fetch_table(opts, operation, repo) when is_list(opts) do
    case Keyword.fetch(opts, :table) do
      {:ok, table} when is_binary(table) and table != "" ->
        {:ok, table}
      // ...
      _ ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "opts[:table] is required for Ecto request-store operations",
           repo_details(repo, nil, operation, :missing_table)
         )}
    end
  end
```

Test table names for DDL reference:

```5:8:test/security/stores/request_store_ecto_test.exs
  alias Relyra.RequestStore.Ecto
  // ...
  @table "request_intents"
```

```5:8:test/security/stores/replay_store_ecto_test.exs
  alias Relyra.ReplayStore.Ecto
  // ...
  @table "replay_keys"
```

**Opts propagation (flat `config :relyra` keys become runtime opts):**

```79:81:lib/relyra/phoenix/controllers/acs_controller.ex
  defp controller_opts(conn) do
    conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)
  end
```

**Recommended section order (from RESEARCH §4):**

1. Why upgrade (ETS = dev/single-node)
2. Run Relyra migrations from dep path (13 files)
3. Create host store tables (DDL — not shipped)
4. Implement store wrappers (`repo` + per-store `table`)
5. Wire Connections delegator
6. Update config + `prod_runtime_ets_warning`
7. Receipt checklist

---

### 3. `guides/overview.md` — Day-1/Day-2 cross-links

| Aspect | Value |
|--------|-------|
| **Role** | Job-shaped navigation hub (Phase 46 established pattern) |
| **Closest analog** | Self — Phase 46 `46-PATTERNS.md` integration flow |
| **Pattern to replicate** | Relative links; proof journey numbered list; Day-2 bullet list |

**Day-1 step 2 (replace FakeIdP-primary framing):**

```10:16:guides/overview.md
**Proof journey (in order):**

1. Run `mix relyra.install --module MyApp --repo MyApp.Repo` and confirm scaffold files land in the host app.
2. Prove local sign-in with `Relyra.TestSupport.FakeIdP` before touching a real IdP (see Getting Started §3).
3. Pick exactly one first-class provider runbook (Okta, Entra, Google Workspace, or ADFS) and finish it end-to-end.

Receipt: local FakeIdP proof passes, then one hosted IdP login works with a concrete operator receipt.
```

Target: step 2 references TestSupport macro path + Getting Started §3; receipt mentions `assert_saml_login/2`.

**Day-2 list (add production Ecto link alongside existing operator guides):**

```18:29:guides/overview.md
## Day-2 — Operate in production

- [Okta runbook](recipes/okta.md)
- [Microsoft Entra ID runbook](recipes/entra.md)
// ...
- [Phoenix SaaS tenant onboarding](case_studies/phoenix_saas_tenant_onboarding.md)
```

Add near top of Day-2 cluster: `[Production Ecto path](production_ecto_path.md)`.

---

### 4. `mix.exs` — CI gate + ExDoc extras

| Aspect | Value |
|--------|-------|
| **Role** | Build-time doc presence + discoverability |
| **Closest analog** | Phase 46 `ci.docs` presence gates + overview extras entry |
| **Pattern to replicate** | `cmd test -f guides/<file>.md`; extras list relative path |

**ci.docs presence gate (add after existing `-f` lines, before drift tests):**

```167:181:mix.exs
      "ci.docs": [
        "cmd test -f guides/overview.md",
        "cmd test -f guides/batteries_included.md",
        "cmd test -f BATTERIES_INCLUDED.md",
        "cmd test -f guides/identity_mapping_and_provisioning.md",
        // ... add: "cmd test -f guides/production_ecto_path.md",
        "cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors",
        "cmd mix test test/docs/logout_recipe_drift_test.exs --warnings-as-errors",
        "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
        "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
        "relyra.batteries_included --check"
      ],
```

**ExDoc extras (add in Day-2 cluster, after `identity_mapping_and_provisioning.md`):**

```126:141:mix.exs
      extras: [
        "README.md",
        "guides/overview.md",
        // ...
        "guides/getting_started.md",
        "guides/identity_mapping_and_provisioning.md",
        // ... add: "guides/production_ecto_path.md",
        "guides/jtbd_user_flows.md",
```

**Do not add drift test** — Phase 47 content is narrative + config snippets, not behaviour-callback paste blocks:

```1:14:test/docs/logout_recipe_drift_test.exs
defmodule Relyra.Docs.LogoutRecipeDriftTest do
  @moduledoc """
  Bidirectional drift gate for `guides/recipes/logout.md`'s
  `Relyra.SessionAdapter` code example.
  // ...
  A host copy-pasting a stale example fails `@behaviour
  Relyra.SessionAdapter` at compile time
```

---

### 5. `test/test_support_demo_test.exs` — canonical contract (reference)

| Aspect | Value |
|--------|-------|
| **Role** | CI-gated copy-paste reference; §3 points here |
| **Closest analog** | Self — already in `ci.docs` |
| **Constraint** | Doc changes must not break demo test contract (D-12) |

Runs under:

```180:180:mix.exs
        "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
```

---

## Cross-Cutting Patterns

### ETS prod warning (document accurately — opt-in, not `Mix.env()`)

```92:101:lib/relyra/replay_store/ets.ex
  defp prod_runtime?(opts) do
    case Keyword.fetch(opts, :prod_runtime?) do
      {:ok, value} -> value == true
      :error -> prod_runtime_ets_warning()
    end
  end

  defp prod_runtime_ets_warning do
    Application.get_env(:relyra, :prod_runtime_ets_warning, false) == true
  end
```

Warning strings to quote verbatim in production guide:

```84:86:lib/relyra/replay_store/ets.ex
      Logger.warning(
        "Relyra.ReplayStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe replay guarantees."
      )
```

```153:155:lib/relyra/request_store/ets.ex
      Logger.warning(
        "Relyra.RequestStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe request intent semantics."
      )
```

Verified by security tests:

```65:78:test/security/stores/replay_store_ets_test.exs
  @tag :prod_runtime_warning
  test "warn_prod_ets!/1 emits loud warning when app env enables runtime warning" do
    // ...
    Application.put_env(:relyra, :prod_runtime_ets_warning, true)
    // ...
    assert log =~ "single-node only"
  end
```

### Link style

Relative markdown paths for ExDoc compatibility (Phase 46 precedent): `(production_ecto_path.md)`, `(getting_started.md#3-prove-local-login...)`.

### ExDoc `main` unchanged

```122:122:mix.exs
      main: "getting_started",
```

---

## Integration Flow

```
ADOPT-01 (Wave 1)
─────────────────
guides/overview.md Day-1 step 2
    ↓
guides/getting_started.md §3 (TestSupport macro + stub router)
    ↓ points to
test/test_support_demo_test.exs (canonical copy-paste)
    ↓
lib/relyra/test_support.ex (macro API)
    ↓ receipt
assert_saml_login/2  |  saml_login/1

Appendix: manual build_saml_response/sign_saml_response (demoted, not deleted)

ADOPT-02 (Wave 2)
─────────────────
mix relyra.install defaults (ETS + Default resolver)
    ↓ upgrade path documented in
guides/production_ecto_path.md (new)
    ├── Ecto.Migrator.run/4 from :relyra priv/repo/migrations (13 files)
    ├── Host store DDL (request_intents, replay_keys — not shipped)
    ├── Wrapper modules (repo + table per store)
    ├── Connections delegator → ConnectionResolver.Ecto
    └── prod_runtime_ets_warning: true (opt-in safety net)

Cross-doc links
───────────────
getting_started.md §5 ──→ production_ecto_path.md
overview.md Day-2 ──────→ production_ecto_path.md

CI / ExDoc
──────────
mix.exs ci.docs: cmd test -f guides/production_ecto_path.md
mix.exs extras:  guides/production_ecto_path.md
Existing gate:   test/test_support_demo_test.exs (no new drift test)
```

---

## Planner Checklist (from pattern map)

- [ ] §3 states stub ACS ≠ `saml_routes()` / `ACSController` — §3 = TestSupport receipt; §2 scaffold = real integration
- [ ] Document `Base.decode64!` before `post_saml_response/2` (demo line 32)
- [ ] Production guide warns against flat `config :relyra, table: ...` for both stores
- [ ] Store tables explicitly host-owned (13 shipped migrations do not include them)
- [ ] `prod_runtime_ets_warning` documented as opt-in in `config/runtime.exs`, not automatic in prod
- [ ] No scope creep: no install task changes, no new Mix tasks, no adapter API changes

## PATTERN MAPPING COMPLETE
