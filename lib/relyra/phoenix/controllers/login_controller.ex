defmodule Relyra.Phoenix.Controllers.LoginController do
  @moduledoc false
  use Phoenix.Controller, formats: [:html]

  alias Relyra.Error

  def new(conn, %{"connection_id" => _connection_id} = params) do
    # For GET requests, we can either automatically start login or show a button
    # Defaulting to start login for now as is common for SSO links
    create(conn, params)
  end

  def create(conn, %{"connection_id" => connection_id} = params) do
    opts = controller_opts(conn)

    relay_context = %{
      connection_id: connection_id,
      return_to: params["return_to"] || "/"
    }

    # First we need to resolve the connection because start_login/3 expects it
    case resolve_connection(connection_id, conn, opts) do
      {:ok, connection} ->
        case Relyra.start_login(connection, relay_context, opts) do
          {:ok, %{redirect_params: redirect_params}} ->
            # Assuming HTTP-Redirect binding for now as it's common for start_login
            # Binding.encode_redirect returns a query string or map of params
            redirect_to_idp(conn, connection.idp_sso_url, redirect_params)

          {:error, %Error{} = error} ->
            handle_error(conn, error, opts)
        end

      {:error, %Error{} = error} ->
        handle_error(conn, error, opts)
    end
  end

  defp resolve_connection(connection_id, conn, opts) do
    # We pass the connection_id in the request_context
    request_context = %{connection_id: connection_id, plug_conn: conn}
    Relyra.ConnectionResolver.resolve_connection(request_context, opts)
  end

  defp redirect_to_idp(conn, sso_url, redirect_params) do
    uri = URI.parse(sso_url)
    existing_query = URI.decode_query(uri.query || "")
    new_query = Map.merge(existing_query, redirect_params)
    target = %{uri | query: URI.encode_query(new_query)} |> URI.to_string()

    conn
    |> redirect(external: target)
    |> halt()
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
    |> text("SAML Login Error: #{error.message} (#{error.type})")
    |> halt()
  end

  defp controller_opts(conn) do
    # Config can be passed via assigns or application env
    conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)
  end
end
