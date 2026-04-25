defmodule Relyra.Error do
  @moduledoc """
  Stable typed error contract for Relyra security and protocol paths.
  """

  @enforce_keys [:type, :message]
  defstruct [:type, :message, details: %{}]

  @type t :: %__MODULE__{
          type: atom(),
          message: String.t(),
          details: map()
        }

  @spec new(atom(), String.t(), map()) :: t()
  def new(type, message, details \\ %{}) do
    %__MODULE__{type: type, message: message, details: details}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(error, opts) do
      redacted_details = Relyra.Error.redact_details(error.details)

      concat([
        "#Relyra.Error<",
        to_doc(error.type, opts),
        ": ",
        to_doc(error.message, opts),
        " details: ",
        to_doc(redacted_details, opts),
        ">"
      ])
    end
  end

  @doc false
  def redact_details(details) when is_map(details) do
    # Remove known sensitive keys and anything under :sensitive
    details
    |> Map.drop([:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state])
    |> Map.delete(:sensitive)
    |> Enum.map(fn {k, v} -> {k, redact_value(k, v)} end)
    |> Enum.into(%{})
  end

  def redact_details(details), do: details

  defp redact_value(_key, value) when is_binary(value) do
    if String.length(value) > 100 do
      "#{String.slice(value, 0, 10)}... (redacted, #{byte_size(value)} bytes)"
    else
      value
    end
  end

  defp redact_value(_key, value), do: value
end
