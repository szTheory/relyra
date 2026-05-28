defmodule Relyra.Adoption.Journey01InstallParityTest do
  use ExUnit.Case, async: false

  alias Relyra.TestSupport.AdoptionFixtures

  @tag :integration
  test "mix relyra.install output matches golden DemoHost scaffold" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-adoption-install-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(Path.join([tmp_dir, "lib", "demo_host_web"]))
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    router_path = Path.join([tmp_dir, "lib", "demo_host_web", "router.ex"])

    File.write!(
      router_path,
      """
      defmodule DemoHostWeb.Router do
        use Phoenix.Router
      end
      """
    )

    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Relyra.Install.run(["--module", "DemoHost", "--repo", "demo-host"])
    end)

    connections = Path.join([tmp_dir, "lib", "demo_host", "relyra", "connections.ex"])
    user_mapper = Path.join([tmp_dir, "lib", "demo_host", "relyra", "user_mapper.ex"])
    config = Path.join([tmp_dir, "config", "config.exs"])

    assert AdoptionFixtures.format_for_parity!(File.read!(connections)) ==
             AdoptionFixtures.format_for_parity!(
               AdoptionFixtures.read_golden!(["lib", "demo_host", "relyra", "connections.ex"])
             )

    assert AdoptionFixtures.format_for_parity!(File.read!(user_mapper)) ==
             AdoptionFixtures.format_for_parity!(
               AdoptionFixtures.read_golden!(["lib", "demo_host", "relyra", "user_mapper.ex"])
             )

    config_contents = File.read!(config)

    assert config_contents =~ "# --- Relyra START ---"
    assert config_contents =~ "Relyra.ConnectionResolver.Default"

    assert AdoptionFixtures.format_for_parity!(File.read!(router_path)) ==
             AdoptionFixtures.format_for_parity!(
               AdoptionFixtures.read_golden!(["lib", "demo_host_web", "router_injected.ex"])
             )
  end
end
