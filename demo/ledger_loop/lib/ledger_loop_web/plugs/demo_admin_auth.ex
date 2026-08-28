defmodule LedgerLoopWeb.Plugs.DemoAdminAuth do
  @moduledoc false

  import Plug.Conn

  @principal %{
    actor: "demo_admin",
    actor_label: "Demo Administrator",
    organization_id: "northstar"
  }

  def init(options), do: options

  def call(conn, _options) do
    case configured_credentials() do
      {:ok, username, password} ->
        conn = Plug.BasicAuth.basic_auth(conn, username: username, password: password)

        if conn.halted do
          conn
        else
          assign(conn, :demo_admin_principal, @principal)
        end

      :error ->
        conn
        |> Plug.BasicAuth.request_basic_auth()
        |> halt()
    end
  end

  defp configured_credentials do
    with config when is_list(config) <- Application.get_env(:ledger_loop, :demo_admin_auth, []),
         username when is_binary(username) and username != "" <- Keyword.get(config, :username),
         password when is_binary(password) and password != "" <- Keyword.get(config, :password) do
      {:ok, username, password}
    else
      _ -> :error
    end
  end
end
