defmodule Relyra.Mix.InstallTest do
  use ExUnit.Case, async: false

  test "mix relyra.install scaffolds the integration surface" do
    tmp_dir = Path.join(System.tmp_dir!(), "relyra-install-#{System.unique_integer([:positive])}")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
    end)

    connections = Path.join([tmp_dir, "lib", "demo_app", "relyra", "connections.ex"])
    user_mapper = Path.join([tmp_dir, "lib", "demo_app", "relyra", "user_mapper.ex"])
    config = Path.join([tmp_dir, "config", "config.exs"])

    assert File.exists?(connections)
    assert File.exists?(user_mapper)
    assert File.exists?(config)

    assert File.read!(connections) =~ "defmodule DemoApp.Relyra.Connections"
    assert File.read!(user_mapper) =~ "defmodule DemoApp.Relyra.UserMapper"
    assert File.read!(config) =~ "# --- Relyra START ---"
    assert File.read!(config) =~ "Relyra.ConnectionResolver.Default"
  end

  test "mix relyra.install --live-admin scaffolds the admin scope contract" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "relyra-install-admin-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Relyra.Install.run([
        "--module",
        "DemoApp",
        "--live-admin",
        "--admin-path",
        "/sso/admin"
      ])
    end)

    admin_scope = Path.join([tmp_dir, "lib", "demo_app", "relyra", "admin_scope.ex"])

    assert File.exists?(admin_scope)
    assert File.read!(admin_scope) =~ "defmodule DemoApp.Relyra.AdminScope"
    assert File.read!(admin_scope) =~ "@behaviour Relyra.LiveAdmin.ScopeProvider"
    assert File.read!(admin_scope) =~ "admin_actor"
  end

  test "mix relyra.install prints a concrete scaffold receipt" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "relyra-install-output-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        File.cd!(tmp_dir, fn ->
          Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
        end)
      end)

    assert output =~ "Relyra install scaffolded for DemoApp in demo-app."
  end

  test "mix relyra.install auto-injects saml_routes into a single detected router" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-install-router-inject-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(Path.join([tmp_dir, "lib", "demo_app_web"]))
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    router_path = Path.join([tmp_dir, "lib", "demo_app_web", "router.ex"])

    File.write!(
      router_path,
      """
      defmodule DemoAppWeb.Router do
        use Phoenix.Router
      end
      """
    )

    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
    end)

    contents = File.read!(router_path)
    assert contents =~ "# --- Relyra SAML routes ---"
    assert contents =~ "saml_routes()"

    first_pass = contents

    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
    end)

    assert File.read!(router_path) == first_pass
  end

  test "mix relyra.install does not inject when multiple routers are detected" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-install-router-ambiguous-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(Path.join([tmp_dir, "lib", "demo_app_web"]))
    File.mkdir_p!(Path.join([tmp_dir, "lib", "demo_app"]))
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    web_router = Path.join([tmp_dir, "lib", "demo_app_web", "router.ex"])
    admin_router = Path.join([tmp_dir, "lib", "demo_app", "admin_router.ex"])

    router_body = """
    defmodule DemoApp.Router do
      use Phoenix.Router
    end
    """

    File.write!(web_router, router_body)

    File.write!(
      admin_router,
      String.replace(router_body, "DemoApp.Router", "DemoApp.AdminRouter")
    )

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        File.cd!(tmp_dir, fn ->
          Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
        end)
      end)

    refute File.read!(web_router) =~ "saml_routes()"
    refute File.read!(admin_router) =~ "saml_routes()"
    assert output =~ "Multiple routers detected" or output =~ "manually"
  end
end
