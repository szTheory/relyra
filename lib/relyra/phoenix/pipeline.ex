defmodule Relyra.Phoenix.Pipeline do
  @moduledoc false

  defmodule SkipCSRF do
    @moduledoc """
    Plug to skip CSRF protection for SAML ACS routes.
    """
    @behaviour Plug

    @impl true
    def init(opts), do: opts

    @impl true
    def call(conn, _opts) do
      if conn.private[:relyra_skip_csrf] do
        Plug.Conn.put_private(conn, :plug_skip_csrf_protection, true)
      else
        conn
      end
    end
  end
end
