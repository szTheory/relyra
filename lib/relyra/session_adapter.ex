defmodule Relyra.SessionAdapter do
  @moduledoc """
  Public extension contract for handing off authenticated subjects to host sessions.
  """

  alias Relyra.Error

  # Verification anchor: @callback establish_session(subject, context, opts  [])
  @callback establish_session(subject :: map(), context :: map(), opts :: keyword()) ::
              {:ok, map() | Plug.Conn.t()} | {:error, Error.t()}

  @callback revoke_session(
              subject :: map(),
              session_index :: binary() | nil,
              context :: map(),
              opts :: keyword()
            ) :: {:ok, term()} | {:error, Error.t()}

  @callback index_session(
              session_index :: binary(),
              issuer :: binary(),
              context :: map(),
              opts :: keyword()
            ) :: {:ok, term()} | {:error, Error.t()}

  @callback terminate_by_session_index(
              session_index :: binary(),
              issuer :: binary(),
              context :: map(),
              opts :: keyword()
            ) :: {:ok, term()} | {:error, Error.t()}

  @spec establish_session(map(), map(), keyword()) ::
          {:ok, map() | Plug.Conn.t()} | {:error, Error.t()}
  def establish_session(subject, context, opts \\ []) do
    metadata = %{
      connection_id: read_field(context, :connection_id),
      flow: :sp_initiated
    }

    Relyra.Telemetry.span([:session, :establish], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter)

      result =
        cond do
          is_nil(adapter) ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}

          Code.ensure_loaded?(adapter) and function_exported?(adapter, :establish_session, 3) ->
            adapter.establish_session(subject, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  @spec revoke_session(map(), binary() | nil, map(), keyword()) ::
          {:ok, term()} | {:error, Error.t()}
  def revoke_session(subject, session_index, context, opts \\ []) do
    metadata = %{
      connection_id: read_field(context, :connection_id),
      flow: :idp_initiated
    }

    Relyra.Telemetry.span([:session, :revoke], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter, Relyra.SessionAdapter.Default)

      result =
        cond do
          Code.ensure_loaded?(adapter) and function_exported?(adapter, :revoke_session, 4) ->
            adapter.revoke_session(subject, session_index, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  @spec index_session(binary(), binary(), map(), keyword()) ::
          {:ok, term()} | {:error, Error.t()}
  def index_session(session_index, issuer, context, opts \\ []) do
    metadata = %{
      connection_id: read_field(context, :connection_id)
    }

    Relyra.Telemetry.span([:session, :index], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter)

      result =
        cond do
          is_nil(adapter) ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}

          Code.ensure_loaded?(adapter) and function_exported?(adapter, :index_session, 4) ->
            adapter.index_session(session_index, issuer, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  @spec terminate_by_session_index(binary(), binary(), map(), keyword()) ::
          {:ok, term()} | {:error, Error.t()}
  def terminate_by_session_index(session_index, issuer, context, opts \\ []) do
    metadata = %{
      connection_id: read_field(context, :connection_id)
    }

    Relyra.Telemetry.span([:session, :terminate], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter)

      result =
        cond do
          is_nil(adapter) ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}

          Code.ensure_loaded?(adapter) and function_exported?(adapter, :terminate_by_session_index, 4) ->
            adapter.terminate_by_session_index(session_index, issuer, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
