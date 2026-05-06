defmodule Relyra.LoginResult do
  @moduledoc """
  The successful outcome of a SAML response consumption.
  """
  defstruct [
    :principal,
    :connection,
    :mapped_user,
    :relay_state,
    :issuer,
    :in_response_to,
    :validation_trace
  ]

  @type t :: %__MODULE__{
          principal: Relyra.Principal.t(),
          connection: Relyra.Connection.t(),
          mapped_user: term() | nil,
          relay_state: binary() | nil,
          issuer: binary() | nil,
          in_response_to: binary() | nil,
          validation_trace: [map()]
        }
end
