defmodule Mix.Tasks.Relyra.Install do
  @moduledoc false
  use Mix.Task

  @shortdoc "Scaffold the minimal Relyra integration surface"

  @impl true
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        switches: [
          module: :string,
          router: :string,
          repo: :string,
          live_admin: :boolean,
          admin_path: :string,
          no_config: :boolean,
          force: :boolean
        ],
        aliases: [m: :module]
      )

    module_name = Keyword.get(opts, :module, "MyApp")
    force = Keyword.get(opts, :force, false)
    no_config = Keyword.get(opts, :no_config, false)

    root_module_path = module_path(module_name)

    ensure_generated_file!(
      Path.join(["lib", root_module_path, "relyra", "connections.ex"]),
      connection_template(module_name),
      force
    )

    ensure_generated_file!(
      Path.join(["lib", root_module_path, "relyra", "user_mapper.ex"]),
      user_mapper_template(module_name),
      force
    )

    if Keyword.get(opts, :live_admin, false) do
      ensure_generated_file!(
        Path.join(["lib", root_module_path, "relyra", "admin_scope.ex"]),
        admin_scope_template(module_name),
        force
      )
    end

    unless no_config do
      ensure_config!()
    end

    maybe_update_router(Keyword.get(opts, :router), module_name, force, opts)

    repo_label = Keyword.get(opts, :repo, "the host app")
    Mix.shell().info("Relyra install scaffolded for #{module_name} in #{repo_label}.")
  end

  defp ensure_generated_file!(path, contents, force) do
    File.mkdir_p!(Path.dirname(path))

    cond do
      force or not File.exists?(path) ->
        File.write!(path, contents)

      true ->
        Mix.shell().info("Skipped existing #{path} (pass --force to overwrite)")
    end
  end

  defp ensure_config! do
    File.mkdir_p!("config")

    path = "config/config.exs"
    sentinel_start = "# --- Relyra START ---"
    sentinel_end = "# --- Relyra END ---"

    snippet = """

    #{sentinel_start}
    config :relyra,
      connection_resolver: Relyra.ConnectionResolver.Default,
      request_store: Relyra.RequestStore.ETS,
      replay_store: Relyra.ReplayStore.ETS
    #{sentinel_end}
    """

    existing = if File.exists?(path), do: File.read!(path), else: "import Config\n"

    if String.contains?(existing, sentinel_start) do
      :ok
    else
      File.write!(path, existing <> snippet)
    end
  end

  defp maybe_update_router(nil, module_name, _force, opts) do
    case Relyra.Install.RouterInjector.detect_routers() do
      [single] ->
        inject_router_file(single, module_name, opts)

      [] ->
        print_manual_router_instructions(
          module_name,
          "No Phoenix router detected under lib/. Add saml_routes() manually."
        )

        maybe_print_live_admin_instructions(module_name, opts)

      _multiple ->
        print_manual_router_instructions(
          module_name,
          "Multiple routers detected under lib/. Add saml_routes() manually."
        )

        maybe_print_live_admin_instructions(module_name, opts)
    end
  end

  defp maybe_update_router(router_path, module_name, force, opts) do
    if File.exists?(router_path) do
      inject_router_file(router_path, module_name, opts)
    else
      if force do
        Mix.shell().info("Router file #{router_path} missing; skipped due to --force.")
      else
        Mix.shell().info(
          "Router file #{router_path} missing; add saml_routes() manually if needed."
        )
      end

      maybe_print_live_admin_instructions(module_name, opts)
    end
  end

  defp inject_router_file(router_path, module_name, opts) do
    contents = File.read!(router_path)

    case Relyra.Install.RouterInjector.inject(contents) do
      {:ok, new_contents} ->
        File.write!(router_path, new_contents)

        Mix.shell().info("Injected Relyra SAML routes into #{router_path}")

        maybe_print_live_admin_instructions(module_name, opts)

      {:already_injected, _} ->
        Mix.shell().info("Relyra SAML routes already present in #{router_path}")

        maybe_print_live_admin_instructions(module_name, opts)

      :ambiguous ->
        print_manual_router_instructions(
          module_name,
          "Router found at #{router_path}, but route injection is ambiguous. Add saml_routes() manually."
        )

        maybe_print_live_admin_instructions(module_name, opts)
    end
  end

  defp print_manual_router_instructions(module_name, message) do
    Mix.shell().info(message)

    Mix.shell().info(
      "Generated for #{module_name}; use the router macro in the appropriate scope:"
    )

    Mix.shell().info("""
        import Relyra.Phoenix.Router
        saml_routes()
    """)
  end

  defp maybe_print_live_admin_instructions(module_name, opts) do
    if Keyword.get(opts, :live_admin, false) do
      admin_path = Keyword.get(opts, :admin_path, "/relyra/admin")

      Mix.shell().info("""

      Live admin scaffolded. Mount it in a LiveView-enabled router scope:

          import Relyra.LiveAdmin.Router

          relyra_admin_routes("#{admin_path}",
            repo: #{module_name}.Repo,
            scope_provider: #{module_name}.Relyra.AdminScope
          )

      The generated `#{module_name}.Relyra.AdminScope` reads:
      - `session[\"admin_actor\"]`
      - `session[\"admin_actor_label\"]`
      - `session[\"admin_organization_id\"]`

      Update that module to match your host app's authenticated session shape.
      """)
    end
  end

  defp module_path(module_name) do
    module_name
    |> Macro.underscore()
  end

  defp connection_template(module_name) do
    """
    defmodule #{module_name}.Relyra.Connections do
      @moduledoc false
      @behaviour Relyra.ConnectionResolver

      @impl true
      def resolve_connection(_request_context, _opts) do
        {:error, Relyra.Error.new(:adapter_not_configured, "Configure #{module_name}.Relyra.Connections", %{})}
      end
    end
    """
  end

  defp user_mapper_template(module_name) do
    """
    defmodule #{module_name}.Relyra.UserMapper do
      @moduledoc false
      @behaviour Relyra.UserMapper

      @impl true
      def map_attributes(_assertion, _connection, _opts) do
        {:error, Relyra.Error.new(:adapter_not_configured, "Configure #{module_name}.Relyra.UserMapper", %{})}
      end
    end
    """
  end

  defp admin_scope_template(module_name) do
    """
    defmodule #{module_name}.Relyra.AdminScope do
      @moduledoc false
      @behaviour Relyra.LiveAdmin.ScopeProvider

      alias Relyra.LiveAdmin.Scope

      @impl true
      def resolve_admin_scope(session, _params, _opts) when is_map(session) do
        case Map.get(session, "admin_actor") do
          actor when is_binary(actor) and actor != "" ->
            {:ok,
             %Scope{
               actor: actor,
               actor_label: Map.get(session, "admin_actor_label"),
               organization_id: Map.get(session, "admin_organization_id")
             }}

          _other ->
            {:error, :unauthenticated}
        end
      end

      def resolve_admin_scope(_session, _params, _opts), do: {:error, :unauthenticated}
    end
    """
  end
end
