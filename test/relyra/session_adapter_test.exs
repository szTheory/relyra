defmodule Relyra.SessionAdapterTest do
  use ExUnit.Case, async: true

  alias Relyra.SessionAdapter
  alias Relyra.Error

  defmodule TestAdapter do
    @behaviour Relyra.SessionAdapter

    def establish_session(_subject, _context, _opts) do
      {:ok, %{established: true}}
    end

    def revoke_session(_subject, session_index, _context, _opts) do
      {:ok, %{revoked: session_index}}
    end
  end

  describe "revoke_session/4" do
    test "returns error when no adapter is configured" do
      assert {:error, %Error{type: :adapter_not_configured}} =
               SessionAdapter.revoke_session(%{}, "session_123", %{})
    end

    test "dispatches to configured adapter" do
      assert {:ok, %{revoked: "session_123"}} =
               SessionAdapter.revoke_session(%{}, "session_123", %{},
                 session_adapter: TestAdapter
               )
    end
  end
end
