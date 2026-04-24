defmodule Relyra.SessionAdapter do
  @moduledoc """
  Public extension contract for handing off authenticated subjects to host sessions.
  """

  alias Relyra.Error

  # Verification anchor: @callback establish_session(subject, context, opts  [])
  @callback establish_session(subject :: map(), context :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}
end
