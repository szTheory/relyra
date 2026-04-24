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
end
