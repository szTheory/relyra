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
end
