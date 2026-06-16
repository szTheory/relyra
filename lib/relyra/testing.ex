defmodule Relyra.Testing do
  @moduledoc """
  Public Phoenix-free testing fixtures for Relyra adopters.

  The helpers in this namespace produce explicit testing fixture data for the
  real verifier path. They do not mutate application environment, persistent
  terms, ETS tables, or production resolver state.
  """

  alias Relyra.Testing.Fixture

  @type consume_opt :: {atom(), term()}

  @doc """
  Builds POST parameters for a testing fixture.

  By default this returns `%{"SAMLResponse" => fixture.encoded_response}` and
  includes `"RelayState"` only when the fixture has a non-empty relay state.
  """
  @spec post_params(Fixture.t(), keyword()) :: map()
  def post_params(%Fixture{} = fixture, opts \\ []) when is_list(opts) do
    saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
    relay_state_key = Keyword.get(opts, :relay_state_key, "RelayState")

    %{saml_response_key => fixture.encoded_response}
    |> maybe_put_relay_state(relay_state_key, fixture.relay_state)
  end

  @doc """
  Builds `Relyra.consume_response/3` options for a testing fixture.

  The returned options use public `Relyra.Testing.Adapters.*` modules and thread
  all trust/correlation inputs through explicit fixture data.
  """
  @spec consume_opts(Fixture.t(), keyword()) :: [consume_opt()]
  def consume_opts(%Fixture{} = fixture, opts \\ []) when is_list(opts) do
    [
      connection: fixture.connection,
      resolved_connection: fixture.connection,
      relay_state: fixture.relay_state,
      request_store: Relyra.Testing.Adapters.RequestStore,
      replay_store: Relyra.Testing.Adapters.ReplayStore,
      connection_resolver: Relyra.Testing.Adapters.ConnectionResolver,
      request_intent: fixture.request_intent
    ]
    |> Keyword.merge(opts)
  end

  defp maybe_put_relay_state(params, _key, nil), do: params
  defp maybe_put_relay_state(params, _key, ""), do: params
  defp maybe_put_relay_state(params, key, relay_state), do: Map.put(params, key, relay_state)
end
