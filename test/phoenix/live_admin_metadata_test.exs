defmodule Relyra.LiveAdminMetadataTest do
  use ExUnit.Case, async: false

  alias Relyra.LiveAdmin.ConnectionMetadataLive
  alias Relyra.LiveAdmin.Scope

  @repo Relyra.TestSupport.EctoTestRepo

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(@repo, shared: true)
    Relyra.TestSupport.MigrationCase.reset_tables!()

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
    end)

    :ok
  end

  defp build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      private: %{lifecycle: %Phoenix.LiveView.Lifecycle{}, live_temp: %{}},
      assigns: Map.merge(%{
        __changed__: %{},
        flash: %{},
        admin_scope: %Scope{
          actor: "ops@example.com",
          actor_label: "Ops User",
          organization_id: "org_live"
        },
        relyra_admin_repo: @repo,
        relyra_admin_req: nil,
        relyra_admin_base_path: "/admin"
      }, assigns)
    }
  end

  test "mount/3 initializes assigns" do
    socket = build_socket()
    assert {:ok, new_socket} = ConnectionMetadataLive.mount(%{"connection_id" => "conn_meta_test"}, %{}, socket)
    
    assert new_socket.assigns.page_title == "Metadata Management"
    assert new_socket.assigns.connection_id == "conn_meta_test"
    assert new_socket.assigns.mode == "xml"
  end

  test "handle_params/3 updates mode to xml" do
    socket = build_socket(%{connection_id: "conn_meta_test", mode: "url"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_params(%{"mode" => "xml"}, "uri", socket)
    
    assert new_socket.assigns.mode == "xml"
    assert new_socket.assigns.connection_id == "conn_meta_test"
  end

  test "handle_params/3 updates mode to url" do
    socket = build_socket(%{connection_id: "conn_meta_test", mode: "xml"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_params(%{"mode" => "url"}, "uri", socket)
    
    assert new_socket.assigns.mode == "url"
    assert new_socket.assigns.connection_id == "conn_meta_test"
  end

  test "render/1 displays xml mode" do
    assigns = %{
      mode: "xml", 
      __changed__: %{}, 
      relyra_admin_base_path: "/admin", 
      connection_id: "conn_meta_test", 
      detail: %{metadata_source: nil}, 
      streams: %{metadata_revisions: %Phoenix.LiveView.LiveStream{name: :metadata_revisions, inserts: [], deletes: []}}
    }
    html = Phoenix.HTML.Safe.to_iodata(ConnectionMetadataLive.render(assigns)) |> IO.iodata_to_binary()
    assert html =~ "XML Import"
    assert html =~ "Metadata Management"
  end

  test "render/1 displays url mode" do
    assigns = %{
      mode: "url", 
      __changed__: %{}, 
      relyra_admin_base_path: "/admin", 
      connection_id: "conn_meta_test", 
      refresh_status: :idle,
      detail: %{metadata_source: nil}, 
      streams: %{metadata_revisions: %Phoenix.LiveView.LiveStream{name: :metadata_revisions, inserts: [], deletes: []}}
    }
    html = Phoenix.HTML.Safe.to_iodata(ConnectionMetadataLive.render(assigns)) |> IO.iodata_to_binary()
    assert html =~ "URL Sync"
    assert html =~ "Metadata Management"
  end

  test "handle_event refresh_metadata triggers start_async and sets loading state" do
    socket = build_socket(%{connection_id: "conn_meta_test"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_event("refresh_metadata", %{}, socket)
    
    assert new_socket.assigns.refresh_status == :loading
    # start_async actually puts a map in socket.private if we test with standard socket, but testing the assign is enough here
  end

  test "handle_async :metadata_refresh success updates status and flashes info" do
    socket = build_socket(%{connection_id: "conn_meta_test"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_async(:metadata_refresh, {:ok, {:ok, %{}}}, socket)
    
    assert new_socket.assigns.refresh_status == :idle
    assert new_socket.assigns.flash["info"] == "Metadata refresh completed."
  end

  test "handle_async :metadata_refresh error updates status and flashes error" do
    socket = build_socket(%{connection_id: "conn_meta_test"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_async(:metadata_refresh, {:ok, {:error, %Relyra.Error{type: :metadata_refresh_failed, message: "Refresh failed"}}}, socket)
    
    assert new_socket.assigns.refresh_status == :idle
    assert new_socket.assigns.flash["error"] == "Refresh failed"
  end

  test "handle_async :metadata_refresh exit updates status and flashes error" do
    socket = build_socket(%{connection_id: "conn_meta_test"})
    assert {:noreply, new_socket} = ConnectionMetadataLive.handle_async(:metadata_refresh, {:exit, :timeout}, socket)
    
    assert new_socket.assigns.refresh_status == :idle
    assert new_socket.assigns.flash["error"] == "Metadata refresh failed to complete."
  end
end
