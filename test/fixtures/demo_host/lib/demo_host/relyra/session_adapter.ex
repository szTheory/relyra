defmodule DemoHost.Relyra.SessionAdapter do
  @moduledoc false
  @behaviour Relyra.SessionAdapter

  @impl true
  def establish_session(user, _login_result, _opts) do
    {:ok, %{user_id: user.id, email: user.email}}
  end

  @impl true
  def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, :revoked}

  @impl true
  def index_session(_connection, _session_index, _user_id, _opts), do: :ok

  @impl true
  def terminate_by_session_index(_connection, _session_index, _issuer, _opts), do: :ok
end
