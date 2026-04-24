defmodule Relyra.Security.SignedNode do
  @moduledoc false

  defstruct [:xml_id, :xpath, :signed_xml, :signature_method, :digest_method]

  @type t :: %__MODULE__{
          xml_id: String.t() | nil,
          xpath: String.t() | nil,
          signed_xml: String.t(),
          signature_method: String.t(),
          digest_method: String.t()
        }
end
