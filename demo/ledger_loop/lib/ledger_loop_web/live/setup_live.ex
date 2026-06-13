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
      |> assign(:metadata_saved, false)
      |> assign(:mappings, [
        %{saml: "urn:oid:0.9.2342.19200300.100.1.3", local: "email"},
        %{saml: "urn:oid:2.5.4.42", local: "first_name"},
        %{saml: "urn:oid:2.5.4.4", local: "last_name"}
      ])

    {:ok, socket}
  end

  def handle_event("test_login", _params, socket) do
    if socket.assigns.connection do
      {:noreply, redirect(socket, to: "/auth/saml/login?connection_id=#{socket.assigns.connection.connection_id}")}
    else
      {:noreply, redirect(socket, to: "/auth/saml/login")}
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
end
