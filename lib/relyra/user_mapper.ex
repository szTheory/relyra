defmodule Relyra.UserMapper do
  @moduledoc """
  Public extension contract for mapping validated assertion data into user attributes.
  """

  alias Relyra.Error

  # Verification anchor: @callback map_attributes(assertion, connection, opts  [])
  @callback map_attributes(assertion :: map(), connection :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}
end
