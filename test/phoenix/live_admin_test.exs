defmodule Relyra.LiveAdmin.TestScopeProvider do
  @behaviour Relyra.LiveAdmin.ScopeProvider

  alias Relyra.LiveAdmin.Scope

  @impl true
  def resolve_admin_scope(session, _params, _opts) when is_map(session) do
    actor = Map.get(session, "admin_actor") || Map.get(session, :admin_actor)

    if is_binary(actor) and actor != "" do
      {:ok,
       %Scope{
         actor: actor,
         actor_label: Map.get(session, "admin_actor_label") || Map.get(session, :admin_actor_label),
         organization_id:
           Map.get(session, "admin_organization_id") || Map.get(session, :admin_organization_id)
       }}
    else
      {:error, :unauthenticated}
    end
  end
end

defmodule Relyra.LiveAdmin.TestRouter do
  use Phoenix.Router

  import Relyra.LiveAdmin.Router

  pipeline :browser do
    plug Plug.Session, store: :cookie, key: "_relyra_admin_test", signing_salt: "router-salt"
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser

    relyra_admin_routes("/admin",
      repo: Relyra.TestSupport.EctoTestRepo,
      scope_provider: Relyra.LiveAdmin.TestScopeProvider
    )
  end
end

defmodule Relyra.LiveAdminTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox

  alias Relyra.Ecto.Connection
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

  test "relyra_admin_routes registers the admin paths" do
    paths = Enum.map(Relyra.LiveAdmin.TestRouter.__routes__(), & &1.path)

    assert "/admin" in paths
    assert "/admin/connections/new" in paths
    assert "/admin/connections/:connection_id" in paths
    assert "/admin/connections/:connection_id/edit" in paths
  end

  test "on_mount halts and redirects unauthenticated callers" do
    assert {:halt, %Phoenix.LiveView.Socket{redirected: {:redirect, %{to: "/"}}}} =
             Relyra.LiveAdmin.OnMount.on_mount(
               [repo: @repo, scope_provider: Relyra.LiveAdmin.TestScopeProvider],
               %{},
               %{},
               %Phoenix.LiveView.Socket{}
             )
  end

  test "save_connection event creates a scoped connection through the live admin" do
    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          admin_scope: %Scope{
            actor: "ops@example.com",
            actor_label: "Ops User",
            organization_id: "org_live"
          },
          relyra_admin_repo: @repo,
          relyra_admin_base_path: "/admin"
        }
      }
      |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
      |> put_in([Access.key!(:assigns), :live_action], :new)

    assert {:noreply, _socket} =
             ConnectionsLive.handle_event("save_connection", %{
               "connection" => %{
                 "display_name" => "Acme SSO",
                 "organization_id" => "org_live",
                 "provider_preset" => "okta",
                 "sp_entity_id" => "https://sp.example.com/metadata",
                 "acs_url" => "https://sp.example.com/acs",
                 "idp_entity_id" => "https://idp.example.com/metadata",
                 "idp_sso_url" => "https://idp.example.com/sso",
                 "allow_idp_initiated?" => "false",
                 "require_signed_assertions?" => "true",
                 "require_signed_response?" => "true",
                 "clock_skew_seconds" => "60",
                 "name_id_format" => "persistent",
                 "algorithm_policy_json" => "{}"
               }
             }, socket)

    assert [%Connection{display_name: "Acme SSO", organization_id: "org_live"}] = @repo.all(Connection)
  end

  test "Query.get_connection_detail/4 normalizes the legacy_sha1 risk flag" do
    connection =
      @repo.insert!(%Connection{
        connection_id: "conn_risk",
        organization_id: "org_risk",
        display_name: "Risk SSO",
        sp_entity_id: "sp",
        idp_entity_id: "idp",
        runtime_policy: %{
          algorithm_policy: %{"legacy_sha1" => true}
        }
      })

    scope = %Scope{actor: "ops@example.com", organization_id: "org_risk"}

    assert {:ok, detail} = Relyra.LiveAdmin.Query.get_connection_detail(@repo, scope, connection.connection_id)

    assert [%{label: "Legacy SHA-1 support enabled (compatibility override)"}] = detail.risk_flags
  end

  test "add_attribute_mapping and save_attribute_mappings update the connection's attribute mappings" do
    connection =
      @repo.insert!(%Connection{
        connection_id: "conn_attr",
        organization_id: "org_attr",
        display_name: "Attr SSO",
        sp_entity_id: "sp",
        idp_entity_id: "idp"
      })

    scope = %Scope{actor: "ops@example.com", organization_id: "org_attr"}

    {:ok, detail} = Relyra.LiveAdmin.Query.get_connection_detail(@repo, scope, connection.connection_id)

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          admin_scope: scope,
          relyra_admin_repo: @repo,
          relyra_admin_base_path: "/admin",
          connection_id: connection.connection_id,
          detail: detail
        }
      }
      |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
      |> put_in([Access.key!(:assigns), :live_action], :edit)
      |> then(fn socket -> ConnectionsLive.handle_params(%{"connection_id" => connection.connection_id}, "http://localhost", socket) end)
      |> elem(1)

    assert {:noreply, socket} = ConnectionsLive.handle_event("add_attribute_mapping", %{}, socket)
    
    assert %Ecto.Changeset{} = socket.assigns.attribute_mappings_changeset
    
    # Save mapping
    assert {:noreply, _socket} = ConnectionsLive.handle_event("save_attribute_mappings", %{
      "attribute_mappings_form" => %{
        "mappings" => %{
          "0" => %{
            "source_attribute" => "email",
            "target_field" => "email",
            "multivalue_strategy" => "first"
          }
        }
      }
    }, socket)

    # Verify DB state
    assert [%Relyra.Ecto.AttributeMapping{source_attribute: "email", target_field: :email, multivalue_strategy: :first}] = 
      @repo.all(Relyra.Ecto.AttributeMapping)
  end

  test "add_group_mapping and save_group_mappings update the connection's group mappings" do
    connection =
      @repo.insert!(%Connection{
        connection_id: "conn_grp",
        organization_id: "org_grp",
        display_name: "Grp SSO",
        sp_entity_id: "sp",
        idp_entity_id: "idp"
      })

    scope = %Scope{actor: "ops@example.com", organization_id: "org_grp"}

    {:ok, detail} = Relyra.LiveAdmin.Query.get_connection_detail(@repo, scope, connection.connection_id)

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          admin_scope: scope,
          relyra_admin_repo: @repo,
          relyra_admin_base_path: "/admin",
          connection_id: connection.connection_id,
          detail: detail
        }
      }
      |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
      |> put_in([Access.key!(:assigns), :live_action], :edit)
      |> then(fn socket -> ConnectionsLive.handle_params(%{"connection_id" => connection.connection_id}, "http://localhost", socket) end)
      |> elem(1)

    assert {:noreply, socket} = ConnectionsLive.handle_event("add_group_mapping", %{}, socket)
    
    assert %Ecto.Changeset{} = socket.assigns.group_mappings_changeset
    
    # Save mapping
    assert {:noreply, _socket} = ConnectionsLive.handle_event("save_group_mappings", %{
      "group_mappings_form" => %{
        "mappings" => %{
          "0" => %{
            "source_attribute" => "groups",
            "source_value" => "admins",
            "role_target" => "role",
            "role_value" => "admin"
          }
        }
      }
    }, socket)

    # Verify DB state
    assert [%Relyra.Ecto.GroupMapping{source_attribute: "groups", source_value: "admins", role_target: :role, role_value: "admin"}] = 
      @repo.all(Relyra.Ecto.GroupMapping)
  end

  test "failed mapping updates trigger atomic rollback" do
    connection =
      @repo.insert!(%Connection{
        connection_id: "conn_fail",
        organization_id: "org",
        display_name: "Fail SSO",
        sp_entity_id: "sp",
        idp_entity_id: "idp"
      })

    scope = %Scope{actor: "ops@example.com", organization_id: "org"}

    {:ok, detail} = Relyra.LiveAdmin.Query.get_connection_detail(@repo, scope, connection.connection_id)

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          admin_scope: scope,
          relyra_admin_repo: @repo,
          relyra_admin_base_path: "/admin",
          connection_id: connection.connection_id,
          detail: detail
        }
      }
      |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
      |> put_in([Access.key!(:assigns), :live_action], :edit)
      |> then(fn socket -> ConnectionsLive.handle_params(%{"connection_id" => connection.connection_id}, "http://localhost", socket) end)
      |> elem(1)

    # Corrupt the actor in the scope to force an audit validation failure during transaction
    socket = Phoenix.Component.assign(socket, :admin_scope, %Scope{actor: "", organization_id: "org"})

    assert {:noreply, socket} = ConnectionsLive.handle_event("add_attribute_mapping", %{}, socket)
    
    assert {:noreply, socket} = ConnectionsLive.handle_event("save_attribute_mappings", %{
      "attribute_mappings_form" => %{
        "mappings" => %{
          "0" => %{
            "source_attribute" => "email",
            "target_field" => "email",
            "multivalue_strategy" => "first"
          }
        }
      }
    }, socket)

    assert %{"error" => error_msg} = socket.assigns.flash
    assert String.contains?(error_msg, "validation")

    # Assert rollback: no mappings were saved
    assert [] = @repo.all(Relyra.Ecto.AttributeMapping)
  end

  test "filter_audits event scopes audit list" do
    connection =
      @repo.insert!(%Connection{
        connection_id: "conn_filter",
        organization_id: "org",
        display_name: "Filter SSO",
        sp_entity_id: "sp",
        idp_entity_id: "idp"
      })

    scope = %Scope{actor: "ops@example.com", organization_id: "org"}
    {:ok, detail} = Relyra.LiveAdmin.Query.get_connection_detail(@repo, scope, connection.connection_id)

    socket =
      %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          flash: %{},
          admin_scope: scope,
          relyra_admin_repo: @repo,
          relyra_admin_base_path: "/admin",
          connection_id: connection.connection_id,
          detail: detail
        }
      }
      |> then(fn socket -> elem(ConnectionsLive.mount(%{}, %{}, socket), 1) end)
      |> put_in([Access.key!(:assigns), :live_action], :show)
      |> then(fn socket -> ConnectionsLive.handle_params(%{"connection_id" => connection.connection_id}, "http://localhost", socket) end)
      |> elem(1)

    assert {:noreply, socket} = ConnectionsLive.handle_event("filter_audits", %{"filters" => %{"actor" => "audit@example.com", "domain" => "", "action" => ""}}, socket)
    
    assert socket.assigns.audit_filters == %{"actor" => "audit@example.com", "domain" => "", "action" => ""}
  end
end
