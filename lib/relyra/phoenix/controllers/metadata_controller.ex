defmodule Relyra.Phoenix.Controllers.MetadataController do
  @moduledoc false
  use Phoenix.Controller, formats: [:xml]

  alias Relyra.Error

  def show(conn, %{"connection_id" => connection_id} = _params) do
    opts = controller_opts(conn)
    
    request_context = %{connection_id: connection_id, plug_conn: conn}
    
    case Relyra.ConnectionResolver.resolve_connection(request_context, opts) do
      {:ok, connection} ->
        xml = Relyra.Protocol.Metadata.build_sp_metadata(connection, opts)
        
        conn
        |> put_resp_content_type("application/xml")
        |> send_resp(200, xml)

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
    |> put_status(400)
    |> text("SAML Metadata Error: #{error.message} (#{error.type})")
    |> halt()
  end

  defp controller_opts(conn) do
    conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)
  end
end
