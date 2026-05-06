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

    unless no_config do
      ensure_config!()
    end

    maybe_update_router(Keyword.get(opts, :router), module_name, force)

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

  defp maybe_update_router(nil, _module_name, _force), do: :ok

  defp maybe_update_router(router_path, module_name, force) do
    if File.exists?(router_path) do
      contents = File.read!(router_path)

      if String.contains?(contents, "saml_routes()") do
        :ok
      else
        Mix.shell().info(
          "Router found at #{router_path}, but route injection is ambiguous. Add saml_routes() manually."
        )

        Mix.shell().info(
          "Generated for #{module_name}; use the router macro in the appropriate scope."
        )
      end
    else
      if force do
        Mix.shell().info("Router file #{router_path} missing; skipped due to --force.")
      else
        Mix.shell().info(
          "Router file #{router_path} missing; add saml_routes() manually if needed."
        )
      end
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
end
