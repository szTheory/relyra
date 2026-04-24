defmodule Relyra.RequestStore.Default do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @impl true
  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, _opts \\ [])
      when is_binary(relay_state) and is_map(intent) do
    {:error,
     Error.new(
       :unsupported_default_adapter,
       "Default request store does not persist request intent",
       %{
         adapter: __MODULE__,
         operation: :put_intent,
         hint: "Configure :request_store with an ETS or Ecto adapter before enabling login initiation."
       }
     )}
  end

  def put_intent(_relay_state, _intent, _opts) do
    {:error,
     Error.new(
       :adapter_not_configured,
       "Request store adapter is not configured",
       %{
         adapter: __MODULE__,
         operation: :put_intent,
         hint: "Set :request_store in Relyra options to a module implementing Relyra.RequestStore."
       }
     )}
  end

  @impl true
  @spec fetch_intent(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_intent(relay_state, _opts \\ []) when is_binary(relay_state) do
    {:error,
     Error.new(
       :adapter_not_configured,
       "Request store adapter is not configured",
       %{
         adapter: __MODULE__,
         operation: :fetch_intent,
         hint: "Set :request_store in Relyra options to a module implementing Relyra.RequestStore."
       }
     )}
  end

  def fetch_intent(_relay_state, _opts) do
    {:error,
     Error.new(
       :unsupported_default_adapter,
       "Default request store cannot fetch request intent with invalid relay state input",
       %{
         adapter: __MODULE__,
         operation: :fetch_intent,
         hint: "Pass a binary relay_state and configure a concrete request store adapter."
       }
     )}
  end

  @impl true
  @spec consume_intent(binary(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def consume_intent(relay_state, request_id, _opts \\ [])
      when is_binary(relay_state) and is_binary(request_id) do
    {:error,
     Error.new(
       :unsupported_default_adapter,
       "Default request store cannot consume request intent",
       %{
         adapter: __MODULE__,
         operation: :consume_intent,
         hint: "Configure :request_store with an adapter that supports one-time consume semantics."
       }
     )}
  end

  def consume_intent(_relay_state, _request_id, _opts) do
    {:error,
     Error.new(
       :adapter_not_configured,
       "Request store adapter is not configured",
       %{
         adapter: __MODULE__,
         operation: :consume_intent,
         hint: "Set :request_store in Relyra options to a module implementing Relyra.RequestStore."
       }
     )}
  end
end
