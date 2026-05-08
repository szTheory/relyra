defmodule Relyra.SessionAdapter.Default do
  @moduledoc false
  @behaviour Relyra.SessionAdapter

  alias Relyra.Error

  @impl Relyra.SessionAdapter
  def establish_session(_subject, _context, _opts) do
    {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}
  end

  @impl Relyra.SessionAdapter
  def revoke_session(_subject, _session_index, _context, _opts) do
    {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}
  end
end
