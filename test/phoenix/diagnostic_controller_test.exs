defmodule Relyra.Phoenix.DiagnosticTestRouter do
  use Phoenix.Router
  import Relyra.LiveAdmin.Router

  scope "/" do
    relyra_admin_routes()
  end
end

defmodule Relyra.Phoenix.DiagnosticControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.Phoenix.DiagnosticTestRouter

  @endpoint DiagnosticTestRouter

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Relyra.TestSupport.EctoTestRepo)
    :ok
  end

  test "GET /relyra/admin/diagnostic/bundle returns 200 with zip binary" do
    Application.put_env(:relyra, :repo, Relyra.TestSupport.EctoTestRepo)

    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/relyra/admin/diagnostic/bundle")

    assert conn.status == 200
    assert {"content-type", "application/zip"} in conn.resp_headers
    assert {"content-disposition", ~s(attachment; filename="relyra_diagnostic_bundle.zip")} in conn.resp_headers
    assert is_binary(conn.resp_body)
  end

  test "GET /relyra/admin/diagnostic/bundle returns 500 on internal failure" do
    # Trigger an error by passing a non-existent repo or invalid opts if possible.
    # We can temporarily alter the environment so the diagnostic controller fails.
    Application.put_env(:relyra, :repo, :invalid_repo)

    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/relyra/admin/diagnostic/bundle")

    assert conn.status == 500
    assert conn.resp_body =~ "SAML Diagnostic Error"
  end
end
