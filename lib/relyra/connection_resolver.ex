defmodule Relyra.ConnectionResolver do
  @moduledoc """
  Public extension contract for resolving the SAML connection context.

  Resolvers must return a fully normalized `%Relyra.Connection{}` runtime
  snapshot. Persistence details stay behind the adapter boundary; runtime
  consumers receive one canonical shape:

  - `:connection_id`
  - `:idp_entity_id`
  - `:sp_entity_id`
  - `:acs_url`
  - `:idp_sso_url`
  - `:idp_certificates`

  `:cert_chain` remains compatibility-only glue during the certificate
  contract migration window. Callers should treat `:idp_certificates` as the
  canonical trust field.
  """

  alias Relyra.{Connection, Error}

  # Verification anchor: @callback resolve_connection(request_context, opts  [])
  @callback resolve_connection(request_context :: map(), opts :: keyword()) ::
              {:ok, Connection.t()} | {:error, Error.t()}

  @spec resolve_connection(map(), keyword()) :: {:ok, Connection.t()} | {:error, Error.t()}
  def resolve_connection(request_context, opts \\ [])

  def resolve_connection(request_context, opts)
      when is_map(request_context) and is_list(opts) do
    adapter = connection_resolver(opts)

    if is_atom(adapter) and Code.ensure_loaded?(adapter) and
         function_exported?(adapter, :resolve_connection, 2) do
      try do
        case adapter.resolve_connection(request_context, opts) do
          {:ok, %Connection{} = connection} ->
            {:ok, connection}

          {:ok, connection} when is_map(connection) ->
            {:ok, normalize_connection(connection)}

          {:error, %Error{} = error} ->
            {:error, normalize_resolver_error(error, adapter, :resolve_connection)}

          other ->
            {:error, invalid_adapter_result(adapter, :resolve_connection, other)}
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
      :resolver_misconfigured,
      "Connection resolver adapter is unavailable",
      %{
        adapter: inspect(adapter),
        operation: operation,
        reason: :adapter_unavailable,
        hint:
          "Configure :connection_resolver with a module implementing Relyra.ConnectionResolver"
      }
    )
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(
      :resolver_failed,
      "Connection resolver returned an invalid tuple",
      %{
        adapter: inspect(adapter),
        operation: operation,
        reason: :invalid_adapter_result,
        actual: inspect(actual)
      }
    )
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(
      :resolver_failed,
      "Connection resolver adapter raised during dispatch",
      %{
        adapter: inspect(adapter),
        operation: operation,
        reason: :adapter_dispatch_failed,
        failure: reason
      }
    )
  end

  defp normalize_connection(connection) do
    idp_certificates =
      Map.get(connection, :idp_certificates) || Map.get(connection, "idp_certificates")

    cert_chain = Map.get(connection, :cert_chain) || Map.get(connection, "cert_chain")
    canonical_certificates = idp_certificates || cert_chain || []

    connection
    |> Map.new(fn {key, value} ->
      normalized_key = if is_binary(key), do: String.to_existing_atom(key), else: key
      {normalized_key, value}
    end)
    |> Map.put(:idp_certificates, canonical_certificates)
    |> Map.put(:cert_chain, cert_chain || canonical_certificates)
    |> then(&struct(Connection, &1))
  end

  defp normalize_resolver_error(
         %Error{type: :adapter_not_configured, details: details} = error,
         adapter,
         operation
       ) do
    %{
      error
      | type: :resolver_misconfigured,
        details:
          details
          |> Map.put_new(:adapter, inspect(adapter))
          |> Map.put_new(:operation, operation)
          |> Map.put_new(:reason, :adapter_unavailable)
    }
  end

  defp normalize_resolver_error(%Error{details: details} = error, adapter, operation) do
    %{
      error
      | details:
          details |> Map.put_new(:adapter, inspect(adapter)) |> Map.put_new(:operation, operation)
    }
  end
end
