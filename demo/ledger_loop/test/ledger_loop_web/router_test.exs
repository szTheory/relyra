defmodule LedgerLoopWeb.RouterTest do
  use ExUnit.Case, async: true

  alias LedgerLoopWeb.Router

  test "Relyra SAML and LiveAdmin routes are mounted under host-owned paths" do
    paths = Enum.map(Router.__routes__(), & &1.path)

    assert "/saml/:connection_id/metadata" in paths
    assert "/saml/:connection_id/login" in paths
    assert "/saml/:connection_id/acs" in paths

    assert "/relyra/admin" in paths
    assert "/relyra/admin/connections/new" in paths
    assert "/relyra/admin/connections/:connection_id" in paths
    assert "/relyra/admin/connections/:connection_id/edit" in paths
  end

  test "health probes use the lightweight health pipeline" do
    paths = Enum.map(Router.__routes__(), & &1.path)

    assert "/healthz" in paths
    assert "/readyz" in paths

    source = File.read!("lib/ledger_loop_web/router.ex")

    assert source =~ "pipeline :health do\n    plug(:accepts, [\"json\"])\n  end"
    assert source =~ "pipe_through(:health)\n\n    get(\"/healthz\""
    assert source =~ "get(\"/readyz\""
    refute source =~ ~r/pipe_through\s*:browser[\s\S]*get\("\/healthz"/
    refute source =~ ~r/pipe_through\s*:browser[\s\S]*get\("\/readyz"/
  end
end
