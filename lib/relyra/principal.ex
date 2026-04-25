defmodule Relyra.Principal do
  @moduledoc """
  Represents the verified subject identity and attributes from a SAML assertion.
  """
  defstruct [
    :name_id,
    :name_id_format,
    :session_index,
    :attributes,
    :authn_instant,
    :authn_context_class_ref,
    :connection_id
  ]

  @type t :: %__MODULE__{
          name_id: binary(),
          name_id_format: binary() | nil,
          session_index: binary() | nil,
          attributes: map(),
          authn_instant: DateTime.t() | nil,
          authn_context_class_ref: binary() | nil,
          connection_id: binary()
        }
end
