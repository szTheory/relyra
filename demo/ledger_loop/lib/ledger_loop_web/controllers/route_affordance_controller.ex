defmodule LedgerLoopWeb.RouteAffordanceController do
  use LedgerLoopWeb, :controller

  alias LedgerLoop.Repo
  alias Relyra.Ecto.Connection

  def login(conn, _params) do
    conn_id = LedgerLoop.Demo.Fixtures.relyra_enabled_scenario_id()
    keycloak_connection_id = LedgerLoop.Demo.KeycloakProvisioner.connection_id()

    keycloak_connection_id =
      case Repo.get_by(Connection, connection_id: keycloak_connection_id) do
        %Connection{status: :enabled} -> keycloak_connection_id
        _connection -> nil
      end

    render(conn, :login,
      conn_id: conn_id,
      keycloak_connection_id: keycloak_connection_id
    )
  end

  def admin_login(conn, _params) do
    %{actor: actor, actor_label: actor_label, organization_id: organization_id} =
      conn.assigns.demo_admin_principal

    conn
    |> put_session(:admin_actor, actor)
    |> put_session(:admin_actor_label, actor_label)
    |> put_session(:admin_organization_id, organization_id)
    |> redirect(to: "/relyra/admin")
  end

  def support(conn, _params) do
    id = LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()
    redirect(conn, to: "/relyra/admin/connections/#{id}/trace")
  end
end
