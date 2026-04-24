defmodule Relyra.RequestStore do
  @moduledoc """
  Public extension contract for request-intent persistence and one-time consumption.
  """

  alias Relyra.Error

  # Verification anchor: put_intent(relay_state, intent, opts  [])
  @callback put_intent(relay_state :: binary(), intent :: map(), opts :: keyword()) ::
              :ok | {:error, Error.t()}

  # Verification anchor: fetch_intent(relay_state, opts  [])
  @callback fetch_intent(relay_state :: binary(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}

  # Verification anchor: consume_intent(relay_state, request_id, opts  [])
  @callback consume_intent(relay_state :: binary(), request_id :: binary(), opts :: keyword()) ::
              :ok | {:error, Error.t()}

  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, opts \\ [])

  def put_intent(relay_state, intent, opts)
      when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    request_store(opts).put_intent(relay_state, intent, opts)
  end

  @spec fetch_intent(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_intent(relay_state, opts \\ [])

  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    request_store(opts).fetch_intent(relay_state, opts)
  end

  @spec consume_intent(binary(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def consume_intent(relay_state, request_id, opts \\ [])

  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    request_store(opts).consume_intent(relay_state, request_id, opts)
  end

  defp request_store(opts) do
    Keyword.get(opts, :request_store, Relyra.RequestStore.Default)
  end
end
