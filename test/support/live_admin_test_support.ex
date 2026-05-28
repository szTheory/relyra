if Code.ensure_loaded?(Phoenix.Endpoint) and Code.ensure_loaded?(Phoenix.LiveView.Socket) do
  defmodule Relyra.TestSupport.LiveAdminScopeProvider do
    @behaviour Relyra.LiveAdmin.ScopeProvider

    alias Relyra.LiveAdmin.Scope

    @impl true
    def resolve_admin_scope(session, _params, _opts) when is_map(session) do
      actor = Map.get(session, "admin_actor") || Map.get(session, :admin_actor)

      if is_binary(actor) and actor != "" do
        {:ok,
         %Scope{
           actor: actor,
           actor_label:
             Map.get(session, "admin_actor_label") || Map.get(session, :admin_actor_label),
           organization_id:
             Map.get(session, "admin_organization_id") || Map.get(session, :admin_organization_id)
         }}
      else
        {:error, :unauthenticated}
      end
    end
  end

  defmodule Relyra.TestSupport.LiveAdminBrowserFixtures do
    @moduledoc false

    alias Relyra.Ecto.{Certificate, Connection}
    alias Relyra.TestSupport.EctoTestRepo, as: Repo
    alias Relyra.TestSupport.MigrationCase

    @seed_connection_id "seed_shell"
    @risk_connection_id "seed_risk"
    @seed_org_id "org_browser"

    def reset! do
      MigrationCase.reset_tables!()
      seed!()
    end

    def seed! do
      now = DateTime.utc_now()

      shell_connection =
        Repo.insert!(%Connection{
          id: Ecto.UUID.generate(),
          connection_id: @seed_connection_id,
          organization_id: @seed_org_id,
          display_name: "Seed Shell Connection",
          status: :enabled,
          provider_preset: :okta,
          sp_entity_id: "https://sp.example.com/metadata",
          acs_url: "https://sp.example.com/saml/acs",
          idp_entity_id: "https://idp.example.com/entity",
          idp_sso_url: "https://idp.example.com/sso",
          runtime_policy: %{
            allow_idp_initiated?: false,
            require_signed_assertions?: true,
            require_signed_response?: true,
            name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
            algorithm_policy: %{
              signing: :rsa_sha256,
              digest: :sha256
            }
          },
          inserted_at: now,
          updated_at: now
        })

      Repo.insert!(%Connection{
        id: Ecto.UUID.generate(),
        connection_id: @risk_connection_id,
        organization_id: @seed_org_id,
        display_name: "Seed Risk Connection",
        status: :enabled,
        provider_preset: :okta,
        sp_entity_id: "https://sp.example.com/risk/metadata",
        acs_url: "https://sp.example.com/risk/acs",
        idp_entity_id: "https://idp.example.com/risk/entity",
        idp_sso_url: "https://idp.example.com/risk/sso",
        runtime_policy: %{
          allow_idp_initiated?: false,
          require_signed_assertions?: true,
          require_signed_response?: true,
          name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
          algorithm_policy: %{
            "legacy_sha1" => %{
              "allow_until" => "2030-01-01",
              "reason" => "phase15-browser-fixture"
            }
          }
        },
        inserted_at: now,
        updated_at: now
      })

      Repo.insert!(%Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: shell_connection.id,
        fingerprint_sha256: "sha256:#{@seed_connection_id}",
        pem: "-----BEGIN CERTIFICATE-----\nTEST\n-----END CERTIFICATE-----",
        source: "phase15-browser-fixture",
        role: :signing,
        lifecycle_state: :active,
        party: :idp,
        use: :signing,
        activated_at: now
      })

      prepare_runtime!(@risk_connection_id)
    end

    def prepare_runtime!(connection_id) when is_binary(connection_id) do
      connection = Repo.get_by!(Connection, connection_id: connection_id)

      Repo.insert!(%Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: connection.id,
        fingerprint_sha256: "sha256:#{connection.connection_id}",
        pem: "-----BEGIN CERTIFICATE-----\nTEST\n-----END CERTIFICATE-----",
        source: "phase15-browser-fixture",
        role: :signing,
        lifecycle_state: :active,
        party: :idp,
        use: :signing,
        activated_at: DateTime.utc_now()
      })
    end

    def seed_connection_id, do: @seed_connection_id
    def risk_connection_id, do: @risk_connection_id
    def seed_org_id, do: @seed_org_id
  end

  defmodule Relyra.TestSupport.LiveAdminSessionController do
    use Phoenix.Controller, formats: [html: "Phoenix.HTML", json: "Phoenix.HTML"]

    def root(conn, _params) do
      Phoenix.Controller.text(conn, "guest")
    end

    def authenticate(conn, params) do
      return_to = Map.get(params, "return_to", "/admin")
      organization_id = Map.get(params, "organization_id", "org_browser")

      conn
      |> Plug.Conn.put_session("admin_actor", "ops@example.com")
      |> Plug.Conn.put_session("admin_actor_label", "Ops User")
      |> Plug.Conn.put_session("admin_organization_id", organization_id)
      |> Phoenix.Controller.redirect(to: return_to)
    end

    def logout(conn, _params) do
      conn
      |> Plug.Conn.configure_session(drop: true)
      |> Phoenix.Controller.redirect(to: "/")
    end

    def reset(conn, _params) do
      Relyra.TestSupport.LiveAdminBrowserFixtures.reset!()
      Phoenix.Controller.text(conn, "ok")
    end

    def prepare_runtime(conn, %{"connection_id" => connection_id}) do
      Relyra.TestSupport.LiveAdminBrowserFixtures.prepare_runtime!(connection_id)
      Phoenix.Controller.text(conn, "ok")
    end
  end

  defmodule Relyra.TestSupport.LiveAdminErrorHTML do
    @moduledoc false

    def render(_template, _assigns), do: "error"
  end

  defmodule Relyra.TestSupport.LiveAdminRouter do
    use Phoenix.Router

    import Relyra.LiveAdmin.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)

      get("/", Relyra.TestSupport.LiveAdminSessionController, :root)

      get(
        "/test/session/authenticated",
        Relyra.TestSupport.LiveAdminSessionController,
        :authenticate
      )

      get("/test/session/logout", Relyra.TestSupport.LiveAdminSessionController, :logout)
      get("/test/reset", Relyra.TestSupport.LiveAdminSessionController, :reset)

      post(
        "/test/runtime-ready/:connection_id",
        Relyra.TestSupport.LiveAdminSessionController,
        :prepare_runtime
      )

      relyra_admin_routes("/admin",
        repo: Relyra.TestSupport.EctoTestRepo,
        scope_provider: Relyra.TestSupport.LiveAdminScopeProvider
      )
    end
  end

  defmodule Relyra.TestSupport.LiveAdminEndpoint do
    use Phoenix.Endpoint, otp_app: :relyra

    @session_options [store: :cookie, key: "_relyra_admin_test", signing_salt: "router-salt"]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.Session, @session_options)
    plug(Relyra.TestSupport.LiveAdminRouter)
  end

  defmodule Relyra.TestSupport.LiveAdminEndpointSupport do
    @moduledoc false

    @pubsub_supervisor Relyra.TestSupport.LiveAdminPubSubSupervisor

    def ensure_started! do
      start_pubsub()
      start_endpoint()
    end

    defp start_pubsub do
      case Process.whereis(@pubsub_supervisor) do
        nil ->
          case Supervisor.start_link(
                 [{Phoenix.PubSub, name: Relyra.TestSupport.LiveAdminPubSub}],
                 strategy: :one_for_one,
                 name: @pubsub_supervisor
               ) do
            {:ok, _pid} -> :ok
            {:error, {:already_started, _pid}} -> :ok
          end

        _pid ->
          :ok
      end
    end

    defp start_endpoint do
      case Process.whereis(Relyra.TestSupport.LiveAdminEndpoint) do
        nil ->
          do_start_endpoint()

        pid when is_pid(pid) ->
          if endpoint_healthy?(), do: :ok, else: restart_endpoint(pid)
      end
    end

    defp restart_endpoint(pid) do
      if Process.alive?(pid) do
        try do
          :gen_server.stop(pid, :normal, 5_000)
        catch
          :exit, _ -> :ok
        end
      end

      do_start_endpoint()
    end

    defp do_start_endpoint do
      case Relyra.TestSupport.LiveAdminEndpoint.start_link() do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
      end
    end

    defp endpoint_healthy? do
      :ets.info(Relyra.TestSupport.LiveAdminEndpoint) != :undefined
    rescue
      ArgumentError -> false
    end
  end

  defmodule Relyra.TestSupport.LiveAdminBrowserServer do
    @moduledoc false

    alias Ecto.Adapters.SQL.Sandbox
    alias Relyra.TestSupport.LiveAdminBrowserFixtures
    alias Relyra.TestSupport.LiveAdminEndpoint
    alias Relyra.TestSupport.LiveAdminEndpointSupport
    alias Relyra.TestSupport.EctoTestRepo
    alias Relyra.TestSupport.MigrationCase

    def start! do
      MigrationCase.bootstrap!()
      owner = Sandbox.start_owner!(EctoTestRepo, shared: true)
      LiveAdminBrowserFixtures.reset!()

      port = String.to_integer(System.get_env("RELYRA_ADMIN_UI_PORT") || "4101")
      endpoint_config = Application.get_env(:relyra, LiveAdminEndpoint, [])

      Application.put_env(
        :relyra,
        LiveAdminEndpoint,
        Keyword.merge(endpoint_config, http: [ip: {127, 0, 0, 1}, port: port], server: true)
      )

      LiveAdminEndpointSupport.ensure_started!()

      IO.puts("relyra admin ui smoke server listening on http://127.0.0.1:#{port}")

      try do
        Process.sleep(:infinity)
      after
        Sandbox.stop_owner(owner)
      end
    end
  end
end
