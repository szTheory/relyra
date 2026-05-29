defmodule DemoHostWeb.TestRouter do
  @moduledoc false
  use Phoenix.Router

  post("/:connection_id/acs", DemoHostWeb.TestAcsController, :acs)
end

defmodule DemoHostWeb.TestAcsController do
  @moduledoc false
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

  def acs(conn, _params) do
    conn
    |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
    |> Phoenix.Controller.text("ok")
  end
end
