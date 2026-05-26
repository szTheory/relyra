defmodule Relyra.KeyResolverTest do
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.KeyResolver

  defp with_sp_private_key_pem(value, fun) do
    previous = Application.get_env(:relyra, :sp_private_key_pem)

    if is_nil(value) do
      Application.delete_env(:relyra, :sp_private_key_pem)
    else
      Application.put_env(:relyra, :sp_private_key_pem, value)
    end

    try do
      fun.()
    after
      if is_nil(previous) do
        Application.delete_env(:relyra, :sp_private_key_pem)
      else
        Application.put_env(:relyra, :sp_private_key_pem, previous)
      end
    end
  end

  # A fake adapter that correctly returns {:ok, "pem"}
  defmodule FakeAdapter do
    @behaviour Relyra.KeyResolver

    @impl true
    def resolve(connection) when is_map(connection), do: {:ok, "fake_pem_binary"}
  end

  # A fake adapter that returns an invalid result (non-binary in :ok)
  defmodule FakeAdapterBadResult do
    @behaviour Relyra.KeyResolver

    @impl true
    def resolve(connection) when is_map(connection), do: {:ok, 123}
  end

  # A fake adapter that raises an exception
  defmodule FakeAdapterRaises do
    @behaviour Relyra.KeyResolver

    @impl true
    def resolve(_connection), do: raise("boom")
  end

  describe "KeyResolver.resolve/2 dispatch" do
    test "dispatches to KeyResolver.Default when no opts given" do
      with_sp_private_key_pem(nil, fn ->
        assert {:error, %Error{type: :key_not_configured}} = KeyResolver.resolve(%{}, [])
      end)
    end

    test "dispatches to KeyResolver.Default by default with binary pem config" do
      with_sp_private_key_pem("-----BEGIN RSA PRIVATE KEY-----", fn ->
        assert {:ok, "-----BEGIN RSA PRIVATE KEY-----"} = KeyResolver.resolve(%{}, [])
      end)
    end

    test "dispatches to custom adapter module in :key_resolver opt" do
      assert {:ok, "fake_pem_binary"} = KeyResolver.resolve(%{}, key_resolver: FakeAdapter)
    end

    test "unknown module returns {:error, %Error{type: :adapter_not_configured}}" do
      assert {:error, %Error{type: :adapter_not_configured}} =
               KeyResolver.resolve(%{}, key_resolver: Relyra.DoesNotExist.Module)
    end

    test "adapter returning {:ok, non-binary} returns {:error, %Error{type: :adapter_not_configured}}" do
      assert {:error, %Error{type: :adapter_not_configured}} =
               KeyResolver.resolve(%{}, key_resolver: FakeAdapterBadResult)
    end

    test "adapter that raises returns {:error, %Error{type: :adapter_not_configured}}" do
      assert {:error, %Error{type: :adapter_not_configured}} =
               KeyResolver.resolve(%{}, key_resolver: FakeAdapterRaises)
    end

    test "non-map connection returns {:error, %Error{}}" do
      assert {:error, %Error{}} = KeyResolver.resolve("not_a_map", [])
    end
  end
end
