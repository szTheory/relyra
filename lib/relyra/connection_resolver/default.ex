defmodule Relyra.ConnectionResolver.Default do
  @moduledoc false

  @behaviour Relyra.ConnectionResolver

  alias Relyra.Error

  @impl true
  @spec resolve_connection(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def resolve_connection(_request_context, _opts \\ []) do
    {:error,
     Error.new(
       :resolver_misconfigured,
       "Connection resolver adapter is not configured",
       %{
         reason: :adapter_unavailable,
         adapter: __MODULE__,
         operation: :resolve_connection,
         hint:
           "Set :connection_resolver in Relyra options to a module implementing Relyra.ConnectionResolver."
       }
     )}
  end
end
