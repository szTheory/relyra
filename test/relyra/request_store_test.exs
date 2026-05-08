defmodule Relyra.RequestStoreTest do
  use ExUnit.Case, async: true

  alias Relyra.RequestStore

  defmodule TestAdapter do
    @behaviour Relyra.RequestStore

    def put_intent(_relay_state, intent, _opts) do
      send(self(), {:put_intent, intent})
      :ok
    end

    def fetch_intent(_relay_state, _opts), do: {:ok, %{}}
    def consume_intent(_relay_state, _request_id, _opts), do: :ok
  end

  describe "put_intent/3" do
    test "injects type: :authn when intent does not have a type" do
      assert :ok = RequestStore.put_intent("relay", %{foo: "bar"}, request_store: TestAdapter)
      assert_received {:put_intent, intent}
      assert intent.type == :authn
      assert intent.foo == "bar"
    end

    test "preserves type when intent already has a type" do
      assert :ok = RequestStore.put_intent("relay", %{type: :logout, foo: "bar"}, request_store: TestAdapter)
      assert_received {:put_intent, intent}
      assert intent.type == :logout
      assert intent.foo == "bar"
    end
  end
end
