if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionTraceLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.LiveAdmin.Query

    @step_labels %{
      "response.decode" => "Decode response",
      "response.validate" => "Validate response",
      "signature.verify" => "Verify signature",
      "replay.check" => "Replay check",
      "user.map" => "Map user",
      "session.establish" => "Establish session"
    }

    @impl true
    def mount(params, session, socket) do
      socket = ensure_admin_assigns(socket, session)
      connection_id = params["connection_id"] || socket.assigns[:connection_id]

      {:ok,
       socket
       |> assign(:page_title, "Login Trace")
       |> assign(:connection_id, connection_id)
       |> assign(:traces, [])
       |> assign(:load_error, nil)}
    end

    @impl true
    def handle_params(params, _uri, socket) do
      connection_id = params["connection_id"] || socket.assigns.connection_id

      {:noreply,
       socket
       |> assign(:connection_id, connection_id)
       |> reload_traces()}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div
        id="login-trace"
        data-testid="login-trace-page"
        style="padding: 24px; font-family: Helvetica, Arial, sans-serif; max-width: 1000px; margin: 0 auto;"
      >
        <div style="margin-bottom: 24px;">
          <a
            href={"#{@relyra_admin_base_path}/connections/#{@connection_id}"}
            style="text-decoration: none; color: #0066cc;"
          >
            &larr; Back to connection
          </a>
        </div>

        <h1 style="font-size: 28px; margin-top: 0;">Login Trace</h1>
        <p style="color: #666; margin-top: 0;">
          Last {length(@traces)} login attempts for connection {@connection_id}.
        </p>

        <p
          :if={@load_error}
          style="padding: 12px 16px; background: #ffebee; color: #c62828; border-left: 3px solid #c62828;"
        >
          {@load_error}
        </p>

        <div :if={@traces == [] and is_nil(@load_error)} style="padding: 32px; text-align: center; color: #666; border: 1px dashed #ddd; border-radius: 4px; margin-top: 24px;">
          No login attempts recorded yet — traces appear after the first SAML response is consumed.
        </div>

        <div :if={@traces != []} style="display: grid; gap: 16px; margin-top: 24px;">
          <details
            :for={trace <- @traces}
            id={"login-trace-row-#{trace.id}"}
            data-testid={"login-trace-row-#{trace.id}"}
            open
            style="border: 1px solid #ddd; border-radius: 4px; padding: 16px; background: #fafafa;"
          >
            <summary style="cursor: pointer; list-style: none; display: flex; justify-content: space-between; align-items: center; gap: 16px;">
              <div>
                <div style="font-weight: bold; margin-bottom: 4px;">
                  {trace.inserted_at}
                  <span style={"margin-left: 12px; padding: 2px 8px; border-radius: 4px; font-size: 13px; " <> action_style(trace.action)}>
                    {trace.action}
                  </span>
                </div>
                <div style="font-size: 13px; color: #666;">
                  <span :if={trace.correlation_id}>correlation {trace.correlation_id}</span>
                  <span :if={trace.cause} style="margin-left: 12px;">{trace.cause}</span>
                </div>
              </div>
              <span style="color: #0066cc; font-size: 13px;">{length(trace.steps)} steps</span>
            </summary>

            <div
              role="region"
              aria-label="Login trace step evidence"
              tabindex="0"
              data-testid="login-trace-evidence-region"
              style="max-width: 100%; overflow-x: auto; margin-top: 16px;"
            >
              <table style="width: 100%; min-width: 640px; border-collapse: collapse; font-size: 14px;">
                <thead>
                  <tr style="border-bottom: 2px solid #eee; text-align: left;">
                    <th style="padding: 8px;">Step</th>
                    <th style="padding: 8px;">Outcome</th>
                    <th style="padding: 8px;">Error code</th>
                    <th style="padding: 8px;">Duration</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    :for={step <- trace.steps}
                    data-testid={"login-trace-step-#{step["step"]}"}
                    style="border-bottom: 1px solid #eee;"
                  >
                    <td style="padding: 8px;">{step_label(step["step"])}</td>
                    <td style="padding: 8px;">
                      <span style={"padding: 2px 8px; border-radius: 4px; " <> outcome_style(step["outcome"])}>
                        {step["outcome"] || "—"}
                      </span>
                    </td>
                    <td style="padding: 8px; font-family: monospace; font-size: 13px;">
                      {step["error_code"] || "—"}
                    </td>
                    <td style="padding: 8px; font-variant-numeric: tabular-nums;">
                      {format_duration(step["duration_ms"])}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </details>
        </div>
      </div>
      """
    end

    defp reload_traces(%{assigns: %{connection_id: nil}} = socket), do: socket

    defp reload_traces(socket) do
      case Query.get_login_traces(
             socket.assigns.relyra_admin_repo,
             socket.assigns.admin_scope,
             socket.assigns.connection_id,
             limit: 20
           ) do
        {:ok, traces} ->
          socket
          |> assign(:traces, traces)
          |> assign(:load_error, nil)

        {:error, error} ->
          socket
          |> assign(:traces, [])
          |> assign(:load_error, error.message)
      end
    end

    defp step_label(step_name), do: Map.get(@step_labels, step_name, step_name)

    defp format_duration(nil), do: "—"
    defp format_duration(ms) when is_integer(ms), do: "#{ms} ms"
    defp format_duration(ms), do: to_string(ms)

    defp action_style(:succeeded), do: "background: #e8f5e9; color: #2e7d32;"
    defp action_style(:failed), do: "background: #ffebee; color: #c62828;"
    defp action_style(_), do: "background: #f5f5f5; color: #616161;"

    defp outcome_style("ok"), do: "background: #e8f5e9; color: #2e7d32;"
    defp outcome_style("error"), do: "background: #ffebee; color: #c62828;"
    defp outcome_style(_), do: "background: #f5f5f5; color: #616161;"

    defp ensure_admin_assigns(socket, session) do
      socket = ensure_changed_assigns(socket)
      admin_scope = socket.assigns[:admin_scope] || session_value(session, "admin_scope")
      repo = socket.assigns[:relyra_admin_repo] || session_value(session, "relyra_admin_repo")
      req = socket.assigns[:relyra_admin_req] || session_value(session, "relyra_admin_req")

      base_path =
        socket.assigns[:relyra_admin_base_path] ||
          session_value(session, "relyra_admin_base_path") ||
          "/relyra/admin"

      cond do
        is_nil(admin_scope) ->
          raise ArgumentError, "Relyra admin requires :admin_scope to be assigned before mount"

        is_nil(repo) ->
          raise ArgumentError,
                "Relyra admin requires :relyra_admin_repo to be assigned before mount"

        true ->
          socket
          |> assign(:admin_scope, admin_scope)
          |> assign(:relyra_admin_repo, repo)
          |> assign(:relyra_admin_req, req)
          |> assign(:relyra_admin_base_path, base_path)
      end
    end

    defp ensure_changed_assigns(%Phoenix.LiveView.Socket{assigns: assigns} = socket) do
      if Map.has_key?(assigns, :__changed__) do
        socket
      else
        %{socket | assigns: Map.put(assigns, :__changed__, %{})}
      end
    end

    defp session_value(session, key) do
      Map.get(session, key) || Map.get(session, String.to_atom(key))
    end
  end
else
  defmodule Relyra.LiveAdmin.ConnectionTraceLive do
    @moduledoc false
  end
end
