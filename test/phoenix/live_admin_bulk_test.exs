defmodule Relyra.LiveAdmin.BulkTest do
  use ExUnit.Case, async: false

  import Phoenix.Component
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
    scope =
      scope ||
        %Scope{
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
    |> assign(:live_action, :index)
  end

  test "Task 1: ConnectionsLive tracks selected_ids MapSet" do
    socket = mount_socket()
    assert %MapSet{} = socket.assigns.selected_ids
    assert MapSet.size(socket.assigns.selected_ids) == 0
  end

  test "Task 1: handle_event toggle_selection updates selected_ids" do
    socket = mount_socket()

    # Toggle on
    assert {:noreply, socket} =
             ConnectionsLive.handle_event(
               "toggle_selection",
               %{"connection-id" => "conn1"},
               socket
             )

    assert MapSet.member?(socket.assigns.selected_ids, "conn1")

    # Toggle off
    assert {:noreply, socket} =
             ConnectionsLive.handle_event(
               "toggle_selection",
               %{"connection-id" => "conn1"},
               socket
             )

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
      %{
        connection_id: "c1",
        display_name: "Conn 1",
        organization_id: "org",
        status: :active,
        provider_label: "Okta"
      },
      %{
        connection_id: "c2",
        display_name: "Conn 2",
        organization_id: "org",
        status: :active,
        provider_label: "Okta"
      }
    ]

    html =
      render_component(&Relyra.LiveAdmin.Components.ConnectionList.connection_list/1, %{
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

  test "Task 2: Bulk Actions menu appears only when IDs are selected" do
    import Phoenix.LiveViewTest
    socket = mount_socket()

    # Empty selection
    html = render_component(ConnectionsLive, Map.put(socket.assigns, :live_action, :index))
    refute html =~ "Bulk Actions"

    # With selection
    socket = assign(socket, :selected_ids, MapSet.new(["conn1"]))
    html = render_component(ConnectionsLive, Map.put(socket.assigns, :live_action, :index))
    assert html =~ "Bulk Actions"
  end

  test "Task 2: handle_event bulk_action calls BulkActions.run" do
    # We need to insert some connections to test the real run
    # Valid ULID format
    c1_id = "01JKP9G6D2Q7X6Z0X4M7X6Z0X1"
    # Valid ULID format
    c2_id = "01JKP9G6D2Q7X6Z0X4M7X6Z0X2"

    c1 =
      @repo.insert!(%Relyra.Ecto.Connection{
        connection_id: c1_id,
        display_name: "C1",
        organization_id: "org_bulk",
        status: :disabled,
        sp_entity_id: "sp1",
        idp_entity_id: "idp1",
        acs_url: "https://sp1/acs",
        idp_sso_url: "https://idp1/sso"
      })

    c2 =
      @repo.insert!(%Relyra.Ecto.Connection{
        connection_id: c2_id,
        display_name: "C2",
        organization_id: "org_bulk",
        status: :disabled,
        sp_entity_id: "sp2",
        idp_entity_id: "idp2",
        acs_url: "https://sp2/acs",
        idp_sso_url: "https://idp2/sso"
      })

    # Insert active certificates
    @repo.insert!(%Relyra.Ecto.Certificate{
      connection_record_id: c1.id,
      fingerprint_sha256: "f1",
      lifecycle_state: :active,
      role: :signing,
      pem: "PEM1",
      source: "manual"
    })

    @repo.insert!(%Relyra.Ecto.Certificate{
      connection_record_id: c2.id,
      fingerprint_sha256: "f2",
      lifecycle_state: :active,
      role: :signing,
      pem: "PEM2",
      source: "manual"
    })

    socket = mount_socket()
    socket = assign(socket, :selected_ids, MapSet.new([c1_id, c2_id]))

    assert {:noreply, socket} =
             ConnectionsLive.handle_event("bulk_action", %{"action" => "enable"}, socket)

    assert %{"info" => info} = socket.assigns.flash
    assert info =~ "Processed 2 connections"
    assert info =~ "2 succeeded"
    assert MapSet.size(socket.assigns.selected_ids) == 0

    # Verify state in DB
    assert @repo.get_by(Relyra.Ecto.Connection, connection_id: c1_id).status == :enabled
    assert @repo.get_by(Relyra.Ecto.Connection, connection_id: c2_id).status == :enabled
  end
end
