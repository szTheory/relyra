defmodule Relyra.Docs.TestingApiDriftTest do
  @moduledoc """
  Doc drift protection for the public testing narrative in `getting_started.md`.

  Asserts that the code blocks in Getting Started match the expected `Relyra.Testing` API exactly.
  """
  use ExUnit.Case, async: true

  @doc_path "guides/getting_started.md"

  @expected_controller_code """
  defmodule MyAppWeb.TestRouter do
    use Phoenix.Router

    post("/:connection_id/acs", MyAppWeb.TestAcsController, :acs)
  end

  defmodule MyAppWeb.TestAcsController do
    use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

    def acs(conn, _params) do
      conn
      |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
      |> Phoenix.Controller.text("ok")
    end
  end
  """

  @expected_test_code """
  defmodule MyAppWeb.SamlLoginTest do
    use ExUnit.Case, async: false

    @endpoint MyAppWeb.TestRouter

    test "adopters can write a tiny integration test" do
      conn = Phoenix.ConnTest.build_conn()
      fixture = Relyra.Testing.signed_success(name_id: "alice@example.com")

      assert {:ok, login_result} =
               Relyra.consume_response(
                 fixture.response_xml,
                 fixture.request_intent,
                 Relyra.Testing.consume_opts(fixture)
               )

      assert login_result.principal.name_id == "alice@example.com"

      conn =
        Relyra.Testing.Phoenix.post_response(
          conn,
          @endpoint,
          "/\#{fixture.connection.id}/acs",
          fixture
        )

      assert %Plug.Conn{assigns: %{current_user: %{email: "alice@example.com"}}} = conn
    end
  end
  """

  test "getting_started.md contains the exact stub router and controller code blocks" do
    body = File.read!(@doc_path)

    assert String.contains?(body, String.trim(@expected_controller_code)),
           "Stale stub router code in getting_started.md"
  end

  test "getting_started.md contains the exact integration test code block using Relyra.Testing" do
    body = File.read!(@doc_path)

    assert String.contains?(body, String.trim(@expected_test_code)),
           "Stale integration test code in getting_started.md"
  end
end
