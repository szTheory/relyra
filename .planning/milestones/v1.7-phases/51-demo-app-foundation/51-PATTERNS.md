# Phase 51: Demo App Foundation - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 18 new/modified file groups
**Analogs found:** 17 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `demo/ledger_loop/mix.exs` | config | batch | `mix.exs` | partial |
| `demo/ledger_loop/config/*.exs` | config | request-response | generated Phoenix config; `test/support/live_admin_test_support.ex` endpoint config | role-match |
| `demo/ledger_loop/lib/ledger_loop/application.ex` | config | event-driven | generated Phoenix application | no local analog |
| `demo/ledger_loop/lib/ledger_loop/repo.ex` | model | CRUD | `test/support/live_admin_test_support.ex` repo usage | partial |
| `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex` | service | request-response | `lib/mix/tasks/relyra.install.ex` admin scope template | exact |
| `demo/ledger_loop/lib/ledger_loop_web/endpoint.ex` | config | request-response | `test/support/live_admin_test_support.ex` endpoint | role-match |
| `demo/ledger_loop/lib/ledger_loop_web/router.ex` | route | request-response | `test/support/live_admin_test_support.ex` router + `lib/relyra/phoenix/router.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` | controller | request-response | `lib/relyra/phoenix/controllers/metadata_controller.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/health_controller.ex` | controller | request-response | `lib/relyra/phoenix/controllers/diagnostic_controller.ex` | role-match |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/placeholder_controller.ex` | controller | request-response | `lib/relyra/phoenix/controllers/login_controller.ex` | partial |
| `demo/ledger_loop/lib/ledger_loop_web/components/*.ex` | component | request-response | `lib/relyra/live_admin/components/connection_list.ex` | role-match |
| `demo/ledger_loop/priv/static/assets/css/app.css` | config | transform | `lib/relyra/live_admin/components/connection_list.ex` inline style precedent | partial |
| `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` | test | request-response | `test/phoenix/metadata_controller_test.exs` | role-match |
| `demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs` | test | request-response | `test/phoenix/metadata_controller_test.exs` | role-match |
| `demo/ledger_loop/test/ledger_loop_web/router_test.exs` | test | request-response | `test/phoenix/router_test.exs` and `test/phoenix/live_admin_test.exs` | exact |
| `demo/ledger_loop/test/support/conn_case.ex` | test | request-response | generated Phoenix ConnCase; local Phoenix.ConnTest usage | partial |
| `mix.exs` | config | batch | existing package whitelist in `mix.exs` | exact |
| package exclusion verification command/test | test | batch | `lib/mix/tasks/verify.release_parity.ex` | role-match |

## Pattern Assignments

### `demo/ledger_loop/mix.exs` (config, batch)

**Analog:** `mix.exs`

**Dependency posture pattern** (lines 73-92):
```elixir
defp deps do
  [
    {:saxy, "~> 1.6"},
    {:telemetry, "~> 1.3"},
    {:plug, "~> 1.16"},
    {:phoenix, "~> 1.8", optional: true},
    {:phoenix_ecto, "~> 4.6", optional: true},
    {:phoenix_live_view, "~> 1.1", optional: true},
    {:bandit, "~> 1.5", only: :test, runtime: false},
    {:lazy_html, ">= 0.1.0", only: :test, runtime: false}
  ]
end
```

**Apply:** Demo app should invert optionality because it is a Phoenix host app: Phoenix, Phoenix Ecto, LiveView, Bandit, Postgrex are normal app deps; Relyra is `{:relyra, path: "../.."}`. Do not add Tailwind, shadcn, React, daisyUI, or asset builder deps in Phase 51.

---

### `demo/ledger_loop/lib/ledger_loop_web/router.ex` (route, request-response)

**Analogs:** `test/support/live_admin_test_support.ex`, `lib/relyra/phoenix/router.ex`, `lib/relyra/live_admin/router.ex`

**Browser pipeline and mounted admin pattern** (`test/support/live_admin_test_support.ex` lines 177-211):
```elixir
defmodule Relyra.TestSupport.LiveAdminRouter do
  use Phoenix.Router

  import Relyra.LiveAdmin.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)

    get("/", Relyra.TestSupport.LiveAdminSessionController, :root)

    relyra_admin_routes("/admin",
      repo: Relyra.TestSupport.EctoTestRepo,
      scope_provider: Relyra.TestSupport.LiveAdminScopeProvider
    )
  end
end
```

**Host-owned SAML scope pattern** (`lib/relyra/phoenix/router.ex` lines 8-12):
```elixir
import Relyra.Phoenix.Router

scope "/saml", MyAppWeb do
  saml_routes()
end
```

**Relyra SAML macro internals to rely on, not duplicate** (`lib/relyra/phoenix/router.ex` lines 19-35):
```elixir
defmacro saml_routes(opts \\ []) do
  quote bind_quoted: [opts: opts] do
    scope "/", Relyra.Phoenix.Controllers do
      pipe_through(Relyra.Phoenix.Pipeline.SkipCSRF)

      get("/:connection_id/metadata", MetadataController, :show, as: :saml_metadata)
      get("/:connection_id/login", LoginController, :new, as: :saml_login)
      post("/:connection_id/login", LoginController, :create)
      post("/:connection_id/acs", ACSController, :create,
        as: :saml_acs,
        private: %{relyra_skip_csrf: true}
      )
    end
  end
end
```

**LiveAdmin macro internals to rely on, not duplicate** (`lib/relyra/live_admin/router.ex` lines 7-36):
```elixir
defmacro relyra_admin_routes(path \\ "/relyra/admin", opts \\ []) do
  quote bind_quoted: [path: path, opts: opts] do
    import Phoenix.LiveView.Router

    scope path, as: :relyra_admin do
      get("/diagnostic/bundle", Relyra.Phoenix.Controllers.DiagnosticController, :download,
        as: :diagnostic
      )

      live_session :relyra_admin,
        on_mount: [
          {Relyra.LiveAdmin.OnMount, Keyword.put(opts, :base_path, path)}
        ] do
        live("/", Relyra.LiveAdmin.ConnectionsLive, :index)
        live("/connections/new", Relyra.LiveAdmin.ConnectionsLive, :new)
        live("/connections/:connection_id", Relyra.LiveAdmin.ConnectionsLive, :show)
        live("/connections/:connection_id/edit", Relyra.LiveAdmin.ConnectionsLive, :edit)
      end
    end
  end
end
```

**Apply:** In the demo router, define host pages under `/`, mount SAML inside `scope "/saml", LedgerLoopWeb`, and mount admin with `relyra_admin_routes("/relyra/admin", repo: LedgerLoop.Repo, scope_provider: LedgerLoop.Relyra.AdminScope)`. Keep setup/login/support as host-owned placeholders; do not implement Phase 52-56 behavior.

---

### `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex` (service, request-response)

**Analog:** `lib/mix/tasks/relyra.install.ex`

**Generated scope-provider pattern** (lines 233-258):
```elixir
defmodule #{module_name}.Relyra.AdminScope do
  @moduledoc false
  @behaviour Relyra.LiveAdmin.ScopeProvider

  alias Relyra.LiveAdmin.Scope

  @impl true
  def resolve_admin_scope(session, _params, _opts) when is_map(session) do
    case Map.get(session, "admin_actor") do
      actor when is_binary(actor) and actor != "" ->
        {:ok,
         %Scope{
           actor: actor,
           actor_label: Map.get(session, "admin_actor_label"),
           organization_id: Map.get(session, "admin_organization_id")
         }}

      _other ->
        {:error, :unauthenticated}
    end
  end

  def resolve_admin_scope(_session, _params, _opts), do: {:error, :unauthenticated}
end
```

**Session key contract** (lines 179-195):
```elixir
relyra_admin_routes("#{admin_path}",
  repo: #{module_name}.Repo,
  scope_provider: #{module_name}.Relyra.AdminScope
)

The generated `#{module_name}.Relyra.AdminScope` reads:
- `session["admin_actor"]`
- `session["admin_actor_label"]`
- `session["admin_organization_id"]`
```

**Apply:** Create `LedgerLoop.Relyra.AdminScope` as demo-owned host code. Phase 51 may provide a minimal route/session affordance only to make `/relyra/admin` reachable; seeded org/user story remains Phase 52-53.

---

### `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` (controller, request-response)

**Analogs:** Relyra Phoenix controllers and LiveAdmin component style.

**Controller import/response pattern** (`lib/relyra/phoenix/controllers/metadata_controller.ex` lines 1-7):
```elixir
defmodule Relyra.Phoenix.Controllers.MetadataController do
  @moduledoc false
  use Phoenix.Controller, formats: [:xml]

  alias Relyra.Error

  def show(conn, %{"connection_id" => connection_id} = _params) do
```

**Template/component style precedent** (`lib/relyra/live_admin/components/connection_list.ex` lines 4-21):
```elixir
use Phoenix.Component

def connection_list(assigns) do
  ~H"""
  <aside data-testid="connection-list-region">
    <div
      data-testid="connection-list-header"
      style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;"
    >
      <h2 style="font-size: 18px; margin: 0;">Connections</h2>
      <a data-testid="new-connection-link" href={new_path(@base_path)}>New</a>
    </div>
```

**Apply:** Prefer normal generated Phoenix controller/template conventions for the page, with app-local CSS or function components. Include the UI-SPEC text exactly where required: `LedgerLoop Workspace`, `Northstar Health SSO status`, `Open SSO Setup`, `Start Test Login`, `Open Relyra Admin`, `Open Support Scenario`, `Mounted SAML routes: /saml`, `Mounted operator routes: /relyra/admin`, `Demo health`, `Demo readiness`. Do not show FakeIdP, Keycloak, raw XML, PEM, secrets, assertions, or request params.

---

### `demo/ledger_loop/lib/ledger_loop_web/controllers/health_controller.ex` (controller, request-response)

**Analog:** `lib/relyra/phoenix/controllers/diagnostic_controller.ex`

**Text response and typed error pattern** (lines 7-16, 36-40):
```elixir
def download(conn, _params) do
  opts = controller_opts(conn)

  case Relyra.Diagnostic.create_bundle(opts) do
    {:ok, zip_binary} ->
      send_download(conn, {:binary, zip_binary}, filename: "relyra_diagnostic_bundle.zip")

    {:error, %Error{} = error} ->
      handle_error(conn, error, opts)
  end
end

defp default_error_response(conn, error) do
  conn
  |> put_status(500)
  |> text("SAML Diagnostic Error: #{error.message} (#{error.type})")
  |> halt()
end
```

**Apply:** `/healthz` should be a simple host-owned text response such as `booted`. `/readyz` should return text-distinguishable `ready` or `unavailable`; if it checks the generated `LedgerLoop.Repo`, do not require Phase 52 seed data.

---

### `demo/ledger_loop/lib/ledger_loop_web/controllers/placeholder_controller.ex` (controller, request-response)

**Analog:** `lib/relyra/phoenix/controllers/login_controller.ex`

**Redirect/text error shape** (lines 52-63, 83-87):
```elixir
conn
|> redirect(external: target)
|> halt()

defp default_error_response(conn, error) do
  conn
  |> put_status(400)
  |> text("SAML Login Error: #{error.message} (#{error.type})")
  |> halt()
end
```

**Apply:** Use host-owned placeholder pages or redirects for `/setup/sso`, `/login/test`, and `/support/scenario`. Keep routes stable for later phases, but the content should explicitly indicate later behavior is not implemented in Phase 51.

---

### `demo/ledger_loop/lib/ledger_loop_web/components/*.ex` and CSS (component/config, request-response)

**Analog:** `lib/relyra/live_admin/components/connection_list.ex`

**Operational panel pattern** (lines 25-75):
```elixir
<ul
  :if={@connections != []}
  data-testid="connection-list"
  style="list-style: none; margin: 0; padding: 0; border: 1px solid #ddd;"
>
  <li
    :for={connection <- @connections}
    data-testid={"connection-list-item-#{connection.connection_id}"}
    style="border-bottom: 1px solid #eee; padding: 12px; display: flex; align-items: flex-start; gap: 12px;"
  >
    <div style="flex: 1;">
      <a
        data-testid={"connection-link-#{connection.connection_id}"}
        href={show_path(@base_path, connection.connection_id)}
      >
        <strong>{connection.display_name || connection.connection_id}</strong>
      </a>
      <div
        data-testid={"connection-summary-#{connection.connection_id}"}
        style="font-size: 12px; color: #666; margin-top: 4px;"
      >
        {connection.organization_id} · {connection.status} · {connection.provider_label}
      </div>
    </div>
  </li>
</ul>
```

**Apply:** Translate UI-SPEC values into app-local CSS variables/classes. Keep direct workspace panels, no nested cards, no gradients, no Tailwind/shadcn/React, no icon dependency in Phase 51. Use explicit text status labels; color cannot be the only signal.

---

### `demo/ledger_loop/test/ledger_loop_web/router_test.exs` (test, request-response)

**Analogs:** `test/phoenix/router_test.exs`, `test/phoenix/live_admin_test.exs`

**SAML route assertion pattern** (`test/phoenix/router_test.exs` lines 23-31):
```elixir
test "saml_routes/0 registers expected routes" do
  routes = TestRouter.__routes__()

  paths = Enum.map(routes, fn r -> r.path end)

  assert "/:connection_id/metadata" in paths
  assert "/:connection_id/login" in paths
  assert "/:connection_id/acs" in paths
end
```

**LiveAdmin route assertion pattern** (`test/phoenix/live_admin_test.exs` lines 23-30):
```elixir
test "relyra_admin_routes registers the admin paths" do
  paths = Enum.map(Relyra.TestSupport.LiveAdminRouter.__routes__(), & &1.path)

  assert "/admin" in paths
  assert "/admin/connections/new" in paths
  assert "/admin/connections/:connection_id" in paths
  assert "/admin/connections/:connection_id/edit" in paths
end
```

**Apply:** In demo router tests, assert prefixed paths such as `/saml/:connection_id/metadata`, `/saml/:connection_id/login`, `/saml/:connection_id/acs`, `/relyra/admin`, and `/relyra/admin/connections/new`.

---

### `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` (test, request-response)

**Analog:** `test/phoenix/metadata_controller_test.exs`

**ConnTest pattern** (lines 10-18, 22-31):
```elixir
defmodule Relyra.Phoenix.MetadataControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.Phoenix.MetadataTestRouter
  alias Relyra.TestSupport.FakeConnectionResolver

  @endpoint MetadataTestRouter

  conn =
    Phoenix.ConnTest.build_conn()
    |> get("/valid/metadata")

  assert conn.status == 200
  assert conn.resp_body =~ ~s(entityID="https://sp.example.com")
end
```

**Apply:** Assert first screen response includes required UI-SPEC copy and links. Do not assert seeded Northstar data beyond Phase 51 placeholder/status text.

---

### `demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs` (test, request-response)

**Analog:** `test/phoenix/metadata_controller_test.exs`

**Typed failure assertion pattern** (lines 33-43):
```elixir
conn =
  Phoenix.ConnTest.build_conn()
  |> get("/invalid/metadata")

assert conn.status == 400
assert conn.resp_body =~ "SAML Metadata Error"
assert conn.resp_body =~ "connection_unavailable"
```

**Apply:** Assert `/healthz` status/body and `/readyz` ready or unavailable status/body. If readiness depends on repo availability, make the unavailable state deterministic in test without requiring Phase 52 seed data.

---

### `mix.exs` and package exclusion verification (config/test, batch)

**Analog:** root `mix.exs`

**Package whitelist pattern** (lines 95-119):
```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{
      "Documentation" => "https://hexdocs.pm/relyra",
      "GitHub" => @source_url,
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
    },
    files:
      [
        "priv",
        "docs",
        "guides",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "CONFORMANCE.md",
        "CHANGELOG.md",
        "LICENSE",
        "SECURITY.md",
        "SECURITY_REVIEW.md",
        "SECURITY_REVIEW_EVIDENCE.md",
        "BATTERIES_INCLUDED.md"
      ] ++ package_lib_files()
  ]
end
```

**Package path filter analog** (`lib/mix/tasks/verify.release_parity.ex` lines 299-307):
```elixir
defp drop_hex_metadata(paths) do
  paths
  |> Enum.reject(&(&1 == @hex_metadata_file))
  |> MapSet.new()
end

defp package_path?(path) do
  Enum.any?(@dir_prefixes, &String.starts_with?(path, &1)) or path in @root_files
end
```

**Apply:** Do not add `"demo"` or wildcard paths to root `package.files`. Prove exclusion with `mix hex.build --unpack --output /tmp/relyra-package-check` and a `find` assertion that no unpacked path contains `/demo/`.

## Shared Patterns

### Host-Owned Relyra Route Mounting

**Source:** `lib/relyra/phoenix/router.ex`, `test/support/live_admin_test_support.ex`
**Apply to:** `demo/ledger_loop/lib/ledger_loop_web/router.ex`, router tests, workspace route labels.

```elixir
import Relyra.Phoenix.Router
import Relyra.LiveAdmin.Router

scope "/saml", LedgerLoopWeb do
  pipe_through(:browser)
  saml_routes()
end

relyra_admin_routes("/relyra/admin",
  repo: LedgerLoop.Repo,
  scope_provider: LedgerLoop.Relyra.AdminScope
)
```

### LiveAdmin Authentication Boundary

**Source:** `test/support/live_admin_test_support.ex` lines 7-23 and `lib/mix/tasks/relyra.install.ex` lines 233-258
**Apply to:** `LedgerLoop.Relyra.AdminScope`, any demo-only admin session helper.

```elixir
def resolve_admin_scope(session, _params, _opts) when is_map(session) do
  actor = Map.get(session, "admin_actor") || Map.get(session, :admin_actor)

  if is_binary(actor) and actor != "" do
    {:ok,
     %Scope{
       actor: actor,
       actor_label:
         Map.get(session, "admin_actor_label") || Map.get(session, :admin_actor_label),
       organization_id:
         Map.get(session, "admin_organization_id") || Map.get(session, :admin_organization_id)
     }}
  else
    {:error, :unauthenticated}
  end
end
```

### Controller Error/Status Responses

**Source:** `lib/relyra/phoenix/controllers/metadata_controller.ex` lines 42-47 and `lib/relyra/phoenix/controllers/diagnostic_controller.ex` lines 36-40
**Apply to:** Health/readiness and placeholder controllers.

```elixir
conn
|> put_status(400)
|> text("SAML Metadata Error: #{error.message} (#{error.type})")
|> halt()
```

### ExUnit Route and Conn Assertions

**Source:** `test/phoenix/router_test.exs`, `test/phoenix/metadata_controller_test.exs`
**Apply to:** Demo router, page, health tests.

```elixir
paths = Enum.map(Router.__routes__(), & &1.path)
assert "/saml/:connection_id/metadata" in paths

conn =
  Phoenix.ConnTest.build_conn()
  |> get("/")

assert conn.status == 200
assert conn.resp_body =~ "LedgerLoop Workspace"
```

### Phase Boundary Placeholders

**Source:** `51-CONTEXT.md`, `51-UI-SPEC.md`
**Apply to:** Setup, login, support routes and first screen.

Phase 51 may expose stable routes and visible affordances for Phase 52-56 work, but it must not implement deterministic seeds, Ecto request/replay happy path, full setup UX, FakeIdP browser proof, Docker orchestration, Keycloak, or public docs polish.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `demo/ledger_loop/lib/ledger_loop/application.ex` | config | event-driven | No committed conventional Phoenix application module exists in the repo; use Phoenix 1.8 generator output. |

## Metadata

**Analog search scope:** `mix.exs`, `lib/relyra/phoenix`, `lib/relyra/live_admin`, `lib/mix/tasks`, `test/fixtures/demo_host`, `test/support`, `test/phoenix`, `test/adoption`
**Files scanned:** 30+ files via `rg --files`/`rg -n`; 16 analog files read with line numbers
**Pattern extraction date:** 2026-06-12
