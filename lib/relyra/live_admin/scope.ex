defmodule Relyra.LiveAdmin.Scope do
  @moduledoc """
  Resolved admin scope for the optional LiveView surface.
  """

  @enforce_keys [:actor]
  defstruct [:actor, :actor_label, :organization_id]

  @type t :: %__MODULE__{
          actor: String.t(),
          actor_label: String.t() | nil,
          organization_id: String.t() | nil
        }

  @spec scope_label(t()) :: String.t()
  def scope_label(%__MODULE__{organization_id: nil}), do: "Global scope"

  def scope_label(%__MODULE__{organization_id: organization_id}) do
    "Organization scope: #{organization_id}"
  end

  @spec actor_label(t()) :: String.t()
  def actor_label(%__MODULE__{actor_label: actor_label, actor: _actor})
      when is_binary(actor_label) and actor_label != "" do
    actor_label
  end

  def actor_label(%__MODULE__{actor: actor}), do: actor
end
