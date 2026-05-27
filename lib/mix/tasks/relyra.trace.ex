defmodule Mix.Tasks.Relyra.Trace do
  @moduledoc """
  Prints redacted login traces for a connection (headless operator inspection).

  Required flags: `--repo` and `--connection`. Optional `--last` (default 20).

      mix relyra.trace --repo MyApp.Repo --connection CONNECTION_ID
      mix relyra.trace --repo MyApp.Repo --connection CONNECTION_ID --last 5
  """
  @shortdoc "Print redacted login traces for a connection."

  use Mix.Task

  alias Relyra.LiveAdmin.Query
  alias Relyra.LiveAdmin.Scope

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [repo: :string, connection: :string, last: :integer],
        aliases: [r: :repo, c: :connection, n: :last]
      )

    repo_string =
      Keyword.get(opts, :repo) ||
        Mix.raise("--repo is required")

    connection_id =
      Keyword.get(opts, :connection) ||
        Mix.raise("--connection is required")

    limit = Keyword.get(opts, :last, 20)

    repo =
      try do
        String.to_existing_atom(repo_string)
      rescue
        ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
      end

    scope = %Scope{actor: "system:relyra.trace", organization_id: nil}

    case Query.get_login_traces(repo, scope, connection_id, limit: limit) do
      {:ok, traces} ->
        print_traces(traces, connection_id, limit)
        :ok

      {:error, error} ->
        Mix.raise("relyra.trace failed: #{error.message}")
    end
  end

  defp print_traces(traces, connection_id, limit) do
    Mix.shell().info(
      "relyra.trace: last #{length(traces)} login attempt(s) for connection #{connection_id} (limit #{limit})"
    )

    if traces == [] do
      Mix.shell().info(
        "No login attempts recorded yet — traces appear after the first SAML response is consumed."
      )
    else
      Enum.each(traces, &print_trace/1)
    end
  end

  defp print_trace(trace) do
    Mix.shell().info("")

    Mix.shell().info(
      "[#{trace.inserted_at}] action=#{trace.action} correlation=#{trace.correlation_id || "—"}"
    )

    if trace.cause do
      Mix.shell().info("  cause: #{trace.cause}")
    end

    Enum.each(trace.steps, fn step ->
      step_name = step["step"] || "unknown"
      outcome = step["outcome"] || "—"
      error_code = step["error_code"]
      duration = format_duration(step["duration_ms"])

      line =
        if error_code do
          "  #{step_name}: #{outcome} (#{duration}) error_code=#{error_code}"
        else
          "  #{step_name}: #{outcome} (#{duration})"
        end

      Mix.shell().info(line)
    end)
  end

  defp format_duration(nil), do: "—"
  defp format_duration(ms) when is_integer(ms), do: "#{ms} ms"
  defp format_duration(ms), do: to_string(ms)
end
