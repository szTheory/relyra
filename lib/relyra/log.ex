defmodule Relyra.Log do
  @moduledoc false
  require Logger

  @sensitive_keys [:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state, :private_key]

  def info(message, metadata \\ []) do
    Logger.info(message, redact_metadata(metadata))
  end

  def error(message, metadata \\ []) do
    Logger.error(message, redact_metadata(metadata))
  end

  def debug(message, metadata \\ []) do
    Logger.debug(message, redact_metadata(metadata))
  end

  defp redact_metadata(metadata) when is_list(metadata) do
    Enum.map(metadata, fn {k, v} -> {k, redact_value(k, v)} end)
  end

  defp redact_metadata(metadata), do: metadata

  defp redact_value(key, _value) when key in @sensitive_keys do
    "[REDACTED]"
  end

  defp redact_value(:sensitive, _value), do: "[REDACTED]"

  defp redact_value(_key, %Relyra.Error{} = error) do
    inspect(error)
  end

  defp redact_value(_key, value) when is_map(value) do
    value
    |> Map.drop(@sensitive_keys)
    |> Map.delete(:sensitive)
  end

  defp redact_value(_key, value), do: value
end
