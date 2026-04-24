defmodule Relyra.Security.RelayState do
  @moduledoc false

  alias Relyra.Error

  @relay_state_pattern ~r/^rs_[A-Za-z0-9_-]{16,}$/

  @spec issue(map(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def issue(relay_context, opts \\ [])

  def issue(relay_context, _opts) when is_map(relay_context) do
    relay_state = generate_relay_state()
    _ = relay_context
    {:ok, relay_state}
  end

  def issue(_relay_context, _opts) do
    rejected(:invalid_format, %{field: :relay_context, expected: :map})
  end

  @spec validate(binary(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def validate(relay_state, opts \\ [])

  def validate(relay_state, _opts) when is_binary(relay_state) do
    cond do
      String.starts_with?(relay_state, "http://") ->
        rejected(:raw_url, %{relay_state: relay_state})

      String.starts_with?(relay_state, "https://") ->
        rejected(:raw_url, %{relay_state: relay_state})

      String.starts_with?(relay_state, "//") ->
        rejected(:raw_url, %{relay_state: relay_state})

      Regex.match?(@relay_state_pattern, relay_state) ->
        {:ok, relay_state}

      String.starts_with?(relay_state, "rs_") ->
        rejected(:tampered, %{relay_state: relay_state})

      true ->
        rejected(:invalid_format, %{relay_state: relay_state})
    end
  end

  def validate(_relay_state, _opts) do
    rejected(:invalid_format, %{relay_state: :non_binary})
  end

  defp generate_relay_state do
    relay_state = "rs_" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

    if Regex.match?(@relay_state_pattern, relay_state) do
      relay_state
    else
      "rs_" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
    end
  end

  defp rejected(reason, details) do
    {:error,
     Error.new(
       :relay_state_rejected,
       "RelayState rejected by opaque handle policy",
       Map.put(details, :reason, reason)
     )}
  end
end
