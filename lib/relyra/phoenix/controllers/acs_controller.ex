defmodule Relyra.Phoenix.Controllers.ACSController do
  @moduledoc false
  use Phoenix.Controller, formats: [:html]

  alias Relyra.Error

  def create(conn, params) do
    opts = controller_opts(conn)

    case Relyra.Protocol.Binding.decode_post(params, opts) do
      {:ok, %{response_xml: response_xml, relay_state: relay_state}} ->
        consume_opts = Keyword.put(opts, :relay_state, relay_state)

        case Relyra.consume_response(response_xml, consume_opts) do
          {:ok, login_result} ->
            handle_success(conn, login_result, opts)

          {:error, %Error{} = error} ->
            handle_error(conn, error, opts)
        end

      {:error, %Error{} = error} ->
        handle_error(conn, error, opts)
    end
  end

  defp handle_success(conn, login_result, opts) do
    # 1. Map User
    case Relyra.UserMapper.map_attributes(login_result, login_result.connection, opts) do
      {:ok, mapped_user} ->
        # 2. Establish Session
        case Relyra.SessionAdapter.establish_session(mapped_user, login_result, opts) do
          {:ok, updated_conn_or_result} ->
            # If it returned a Conn, use it. Otherwise, assume it worked and redirect.
            new_conn =
              if is_struct(updated_conn_or_result, Plug.Conn),
                do: updated_conn_or_result,
                else: conn

            return_to = Map.get(login_result, :return_to) || "/"

            new_conn
            |> redirect(to: return_to)
            |> halt()

          {:error, %Error{} = error} ->
            handle_error(conn, error, opts)
        end

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
    |> text("SAML Authentication Error: #{error.message} (#{error.type})")
    |> halt()
  end

  defp controller_opts(conn) do
    conn.assigns[:relyra_opts] || Application.get_all_env(:relyra)
  end
end
