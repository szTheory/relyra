defmodule Relyra.Phoenix.Controllers.DiagnosticController do
  @moduledoc false
  use Phoenix.Controller

  alias Relyra.Error

  def download(conn, _params) do
    opts = controller_opts(conn)

    case Relyra.Diagnostic.create_bundle(opts) do
      {:ok, zip_binary} ->
        send_download(conn, {:binary, zip_binary}, filename: "relyra_diagnostic_bundle.zip")

      {:error, %Error{} = error} ->
        handle_error(conn, error, opts)
    end
  end

  defp handle_error(conn, error, opts) do
    case Keyword.get(opts, :on_error) do
      {module, function} when is_atom(module) and is_atom(function) ->
        apply(module, function, [conn, error])

      module when is_atom(module) ->
        if function_exported?(module, :call, 2) do
          module.call(conn, error)
        else
          default_error_response(conn, error)
        end

      _ ->
        default_error_response(conn, error)
    end
  end

  defp default_error_response(conn, error) do
    conn
    |> put_status(500)
    |> text("SAML Diagnostic Error: #{error.message} (#{error.type})")
    |> halt()
  end

  defp controller_opts(conn) do
    conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)
  end
end
