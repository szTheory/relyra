defmodule Relyra.LiveAdmin.ScopeProvider do
  @moduledoc """
  Host callback contract for resolving admin actor and organization scope.
  """

  alias Relyra.LiveAdmin.Scope

  @callback resolve_admin_scope(session :: map(), params :: map(), opts :: keyword()) ::
              {:ok, Scope.t()} | {:error, :unauthenticated | :forbidden | :not_found}
end
