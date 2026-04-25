defmodule Relyra.ConnectionResolver do
  @moduledoc """
  Public extension contract for resolving the SAML connection context.

  The returned connection map is consumed by protocol core and must include:

  - `:connection_id`
  - `:idp_entity_id`
  - `:sp_entity_id`
  - `:acs_url`
  - `:idp_sso_url`
  - `:cert_chain`
  """

  alias Relyra.Error

  # Verification anchor: @callback resolve_connection(request_context, opts  [])
  @callback resolve_connection(request_context :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}

  @spec resolve_connection(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def resolve_connection(request_context, opts \\ [])

  def resolve_connection(request_context, opts)
      when is_map(request_context) and is_list(opts) do
    adapter = connection_resolver(opts)

    if is_atom(adapter) and Code.ensure_loaded?(adapter) and
         function_exported?(adapter, :resolve_connection, 2) do
      try do
        case adapter.resolve_connection(request_context, opts) do
          {:ok, connection} when is_map(connection) -> {:ok, connection}
          {:error, %Error{} = error} -> {:error, error}
          other -> {:error, invalid_adapter_result(adapter, :resolve_connection, other)}
        end
      rescue
        exception ->
          {:error,
           adapter_dispatch_error(adapter, :resolve_connection, Exception.message(exception))}
      catch
        kind, reason ->
          {:error,
           adapter_dispatch_error(adapter, :resolve_connection, "#{kind}:#{inspect(reason)}")}
      end
    else
      {:error, adapter_not_configured(adapter, :resolve_connection)}
    end
  end

  defp connection_resolver(opts) do
    Keyword.get(opts, :connection_resolver, Relyra.ConnectionResolver.Default)
  end

  defp adapter_not_configured(adapter, operation) do
    Error.new(
      :adapter_not_configured,
      "Connection resolver adapter is unavailable",
      %{
        adapter: inspect(adapter),
        operation: operation,
        hint:
          "Configure :connection_resolver with a module implementing Relyra.ConnectionResolver"
      }
    )
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(
      :adapter_not_configured,
      "Connection resolver returned an invalid tuple",
      %{adapter: inspect(adapter), operation: operation, actual: inspect(actual)}
    )
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(
      :adapter_not_configured,
      "Connection resolver adapter raised during dispatch",
      %{adapter: inspect(adapter), operation: operation, reason: reason}
    )
  end
end
