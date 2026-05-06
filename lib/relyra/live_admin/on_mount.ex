if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.OnMount do
    @moduledoc false

    alias Relyra.LiveAdmin.Scope

    import Phoenix.Component, only: [assign: 3]
    import Phoenix.LiveView, only: [redirect: 2]

    @spec on_mount(keyword(), map(), map(), Phoenix.LiveView.Socket.t()) ::
            {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
    def on_mount(opts, params, session, socket) when is_list(opts) do
      with :ok <- ensure_repo(opts),
           {:ok, scope} <- resolve_scope(session, params, opts) do
        {:cont,
         socket
         |> assign(:admin_scope, scope)
         |> assign(:relyra_admin_repo, Keyword.fetch!(opts, :repo))
         |> assign(:relyra_admin_req, Keyword.get(opts, :req))
         |> assign(:relyra_admin_base_path, Keyword.get(opts, :base_path, "/relyra/admin"))}
      else
        {:error, :unauthenticated} ->
          {:halt, redirect(socket, to: Keyword.get(opts, :login_path, "/"))}

        {:error, :forbidden} ->
          {:halt, redirect(socket, to: Keyword.get(opts, :forbidden_path, "/"))}

        {:error, :not_found} ->
          {:halt, redirect(socket, to: Keyword.get(opts, :not_found_path, "/"))}

        {:error, message} when is_binary(message) ->
          _ = message
          {:halt, redirect(socket, to: Keyword.get(opts, :forbidden_path, "/"))}
      end
    end

    defp ensure_repo(opts) do
      case Keyword.fetch(opts, :repo) do
        {:ok, repo} when is_atom(repo) -> :ok
        _other -> {:error, "Relyra admin requires a :repo option when mounted."}
      end
    end

    defp resolve_scope(session, params, opts) do
      provider = Keyword.fetch!(opts, :scope_provider)

      case provider.resolve_admin_scope(session, params, opts) do
        {:ok, %Scope{} = scope} ->
          {:ok, scope}

        {:error, reason} when reason in [:unauthenticated, :forbidden, :not_found] ->
          {:error, reason}

        _other ->
          {:error, "Relyra admin scope provider returned an invalid result."}
      end
    end
  end
else
  defmodule Relyra.LiveAdmin.OnMount do
    @moduledoc false
  end
end
