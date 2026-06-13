defmodule LedgerLoop.Relyra.AdminScope do
  @moduledoc false
  @behaviour Relyra.LiveAdmin.ScopeProvider

  alias Relyra.LiveAdmin.Scope

  @impl true
  def resolve_admin_scope(session, _params, _opts) when is_map(session) do
    case Map.get(session, "admin_actor") do
      actor when is_binary(actor) and actor != "" ->
        {:ok,
         %Scope{
           actor: actor,
           actor_label: Map.get(session, "admin_actor_label"),
           organization_id: Map.get(session, "admin_organization_id")
         }}

      _other ->
        {:error, :unauthenticated}
    end
  end

  def resolve_admin_scope(_session, _params, _opts), do: {:error, :unauthenticated}
end
