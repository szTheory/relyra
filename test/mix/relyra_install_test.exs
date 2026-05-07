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
end
