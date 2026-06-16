defmodule Relyra.Testing.Phoenix do
  @moduledoc """
  Optional Phoenix convenience helpers for public Relyra testing fixtures.

  This module is intentionally a thin wrapper around `Relyra.Testing.post_params/2`.
  It dispatches fixture POST parameters through the caller's real Phoenix endpoint
  and route so the ACS controller remains responsible for verifier and session
  seams.
  """

  alias Relyra.Testing.Fixture

  @doc """
  Posts a public testing fixture through a Phoenix ACS route.

  Raises `ArgumentError` when `Phoenix.ConnTest` is unavailable. Core
  `Relyra.Testing` fixture generation does not depend on Phoenix.
  """
  @spec post_response(Plug.Conn.t(), module(), binary(), Fixture.t(), keyword()) :: Plug.Conn.t()
  def post_response(conn, endpoint, path, %Fixture{} = fixture, opts \\ []) when is_list(opts) do
    unless Code.ensure_loaded?(Phoenix.ConnTest) do
      raise ArgumentError, "Relyra.Testing.Phoenix requires Phoenix.ConnTest"
    end

    params = Relyra.Testing.post_params(fixture, opts)
    Phoenix.ConnTest.dispatch(conn, endpoint, :post, path, params)
  end
end
