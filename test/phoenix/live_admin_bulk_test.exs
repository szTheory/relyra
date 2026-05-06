defmodule Relyra.LiveAdmin.BulkTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Relyra.LiveAdmin.ConnectionsLive
  alias Relyra.LiveAdmin.Scope

  @repo Relyra.TestSupport.EctoTestRepo

  setup do
    owner = Sandbox.start_owner!(@repo, shared: true)
    Relyra.TestSupport.MigrationCase.reset_tables!()

    on_exit(fn ->
      Sandbox.stop_owner(owner)
    end)

    :ok
  end

  defp mount_socket(scope \\ nil) do
    scope = scope || %Scope{
      actor: "ops@example.com",
      actor_label: "Ops User",
      organization_id: "org_bulk"
    }

    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        admin_scope: scope,
        relyra_admin_repo: @repo,
        relyra_admin_base_path: "/admin"
      }
    }
    |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
  end

  test "Task 1: ConnectionsLive tracks selected_ids MapSet" do
    socket = mount_socket()
    assert %MapSet{} = socket.assigns.selected_ids
    assert MapSet.size(socket.assigns.selected_ids) == 0
  end

  test "Task 1: handle_event toggle_selection updates selected_ids" do
    socket = mount_socket()
    
    # Toggle on
    assert {:noreply, socket} = ConnectionsLive.handle_event("toggle_selection", %{"connection-id" => "conn1"}, socket)
    assert MapSet.member?(socket.assigns.selected_ids, "conn1")

    # Toggle off
    assert {:noreply, socket} = ConnectionsLive.handle_event("toggle_selection", %{"connection-id" => "conn1"}, socket)
    refute MapSet.member?(socket.assigns.selected_ids, "conn1")
  end

  test "Task 1: connection_list renders checkboxes" do
    # This requires Phoenix.LiveViewTest.render_component or similar if we want to test HTML.
    # But since we are testing LiveView logic here, we can focus on assigns for now.
    # Actually, the behavior says "connections list renders a checkbox for each connection".
    # I'll use Phoenix.LiveViewTest to verify rendering if possible, but I need a running LV for that usually.
    # For unit testing components, I can use render_component.
    
    import Phoenix.LiveViewTest
    
    connections = [
      %{connection_id: "c1", display_name: "Conn 1", organization_id: "org", status: :active, provider_label: "Okta"},
      %{connection_id: "c2", display_name: "Conn 2", organization_id: "org", status: :active, provider_label: "Okta"}
    ]
    
    html = render_component(&Relyra.LiveAdmin.Components.ConnectionList.connection_list/1, %{
      connections: connections,
      base_path: "/admin",
      selected_ids: MapSet.new(["c1"])
    })
    
    assert html =~ ~s(type="checkbox")
    assert html =~ ~s(phx-click="toggle_selection")
    assert html =~ ~s(phx-value-connection-id="c1")
    assert html =~ ~s(phx-value-connection-id="c2")
    
    # Verify checked state
    assert html =~ ~s(checked)
  end
end
