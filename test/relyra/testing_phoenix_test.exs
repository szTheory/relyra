defmodule Relyra.TestingPhoenixTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.TestingPhoenixTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias Relyra.Testing
  alias Relyra.TestingPhoenixTestRouter

  defmodule FixtureResolver do
    @behaviour Relyra.ConnectionResolver

    def resolve_connection(%{connection_id: "conn-123"}, opts) do
      {:ok, Keyword.fetch!(opts, :testing_connection)}
    end

    def resolve_connection(_request_context, _opts) do
      {:error,
       Relyra.Error.new(:connection_unavailable, "Unknown connection", %{
         reason: :not_found,
         operation: :resolve_connection
       })}
    end
  end

  defmodule Mapper do
    @behaviour Relyra.UserMapper

    def map_attributes(login_result, _connection, _opts) do
      {:ok, %{id: 1, email: login_result.principal.name_id}}
    end
  end

  defmodule SessionAdapter do
    @behaviour Relyra.SessionAdapter

    def establish_session(user, _login_result, _opts), do: {:ok, %{user_id: user.id}}
    def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, :revoked}
    def index_session(_session_index, _issuer, _context, _opts), do: {:ok, :indexed}

    def terminate_by_session_index(_session_index, _issuer, _context, _opts),
      do: {:ok, :terminated}
  end

  @endpoint TestingPhoenixTestRouter

  setup do
    previous_env = Application.get_all_env(:relyra)

    on_exit(fn ->
      Application.delete_env(:relyra, :connection_resolver)
      Application.delete_env(:relyra, :request_store)
      Application.delete_env(:relyra, :replay_store)
      Application.delete_env(:relyra, :user_mapper)
      Application.delete_env(:relyra, :session_adapter)
      Application.delete_env(:relyra, :testing_connection)

      for {key, value} <- previous_env do
        Application.put_env(:relyra, key, value)
      end
    end)

    Application.put_env(:relyra, :connection_resolver, FixtureResolver)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
    Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)
    Application.put_env(:relyra, :user_mapper, Mapper)
    Application.put_env(:relyra, :session_adapter, SessionAdapter)

    Relyra.RequestStore.ETS.ensure_table!()
    Relyra.ReplayStore.ETS.ensure_table!()

    :ok
  end

  test "post_response/5 posts a public signed fixture through the real ACS route" do
    fixture = Testing.signed_success(name_id: "alice@example.com")
    Application.put_env(:relyra, :testing_connection, fixture.connection)

    request_intent =
      fixture.request_intent
      |> Map.put(:return_to, "/welcome")
      |> Map.put(:expires_at, DateTime.utc_now() |> DateTime.add(3600, :second))

    assert :ok = Relyra.RequestStore.ETS.put_intent(fixture.relay_state, request_intent)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Relyra.Testing.Phoenix.post_response(@endpoint, "/conn-123/acs", fixture)

    assert redirected_to(conn) == "/welcome"
  end
end
