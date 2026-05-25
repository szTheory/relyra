defmodule Relyra.KeyResolver do
  @moduledoc """
  Public extension contract for SP decryption private key material.

  Implement this behaviour to provide a custom source for the SP RSA private key
  used to unwrap encrypted content-encryption keys in XML-Enc assertions.
  Configure the adapter via the `:key_resolver` option.
  """

  alias Relyra.Error

  @callback resolve(connection :: map()) :: {:ok, pem_binary :: binary()} | {:error, Error.t()}

  @spec resolve(map(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def resolve(connection, opts \\ [])

  def resolve(connection, opts) when is_map(connection) and is_list(opts) do
    dispatch_key_resolver(key_resolver(opts), connection)
  end

  def resolve(_connection, _opts) do
    {:error, adapter_not_configured(nil, :resolve)}
  end

  defp key_resolver(opts) do
    Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)
  end

  defp dispatch_key_resolver(adapter, connection)
       when is_atom(adapter) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, :resolve, 1) do
      try do
        case apply(adapter, :resolve, [connection]) do
          {:ok, pem} when is_binary(pem) -> {:ok, pem}
          {:error, %Error{} = error} -> {:error, error}
          other -> {:error, invalid_adapter_result(adapter, :resolve, other)}
        end
      rescue
        exception ->
          {:error, adapter_dispatch_error(adapter, :resolve, Exception.message(exception))}
      catch
        kind, reason ->
          {:error, adapter_dispatch_error(adapter, :resolve, "#{kind}:#{inspect(reason)}")}
      end
    else
      {:error, adapter_not_configured(adapter, :resolve)}
    end
  end

  defp dispatch_key_resolver(adapter, _connection) do
    {:error, adapter_not_configured(adapter, :resolve)}
  end

  defp adapter_not_configured(adapter, operation) do
    Error.new(
      :adapter_not_configured,
      "Key resolver adapter is unavailable",
      %{
        adapter: inspect(adapter),
        operation: operation,
        hint: "Configure :key_resolver with a module implementing Relyra.KeyResolver"
      }
    )
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(
      :adapter_not_configured,
      "Key resolver adapter returned an invalid result",
      %{adapter: inspect(adapter), operation: operation, actual: inspect(actual)}
    )
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(
      :adapter_not_configured,
      "Key resolver adapter raised during dispatch",
      %{adapter: inspect(adapter), operation: operation, reason: reason}
    )
  end
end
