defmodule LedgerLoopWeb.SetupLive do
  use LedgerLoopWeb, :live_view

  alias LedgerLoop.Repo
  alias Relyra.Ecto.Connection
  import Ecto.Query

  @steps [:sp_settings, :idp_metadata, :mapping_preview, :test_enable]

  def mount(_params, _session, socket) do
    connection =
      Connection
      |> where([c], c.status == :enabled)
      |> limit(1)
      |> Repo.one()

    socket =
      socket
      |> assign(:active_step, :sp_settings)
      |> assign(:connection, connection)
      |> assign(:saml_urls, saml_urls(connection))
      |> assign(:metadata_saved, false)
      |> assign(:mappings, [
        %{saml: "urn:oid:0.9.2342.19200300.100.1.3", local: "email"},
        %{saml: "urn:oid:2.5.4.42", local: "first_name"},
        %{saml: "urn:oid:2.5.4.4", local: "last_name"}
      ])

    {:ok, socket}
  end

  def handle_event("test_login", _params, socket) do
    case socket.assigns.saml_urls do
      %{login_path: login_path} ->
        {:noreply, redirect(socket, to: login_path)}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("save_metadata", %{"metadata" => _metadata}, socket) do
    {:noreply, assign(socket, :metadata_saved, true)}
  end

  def handle_event("set_step", %{"step" => step_str}, socket) do
    step = String.to_existing_atom(step_str)
    {:noreply, assign(socket, :active_step, step)}
  end

  def handle_event("next_step", _params, socket) do
    current_index = Enum.find_index(@steps, &(&1 == socket.assigns.active_step))
    next_index = min(current_index + 1, length(@steps) - 1)
    next_step = Enum.at(@steps, next_index)
    {:noreply, assign(socket, :active_step, next_step)}
  end

  defp saml_urls(nil), do: nil

  defp saml_urls(%Connection{connection_id: connection_id}) do
    metadata_path = ~p"/saml/#{connection_id}/metadata"
    login_path = ~p"/saml/#{connection_id}/login"
    acs_path = ~p"/saml/#{connection_id}/acs"
    endpoint_url = LedgerLoopWeb.Endpoint.url()

    %{
      metadata: endpoint_url <> metadata_path,
      login: endpoint_url <> login_path,
      acs: endpoint_url <> acs_path,
      login_path: login_path
    }
  end
end
