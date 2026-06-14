defmodule Relyra.TestSupport.PollTest do
  use ExUnit.Case, async: true

  alias Relyra.TestSupport.Poll

  describe "retry_until!/4" do
    test "success-immediate: fun returning :ok on first attempt returns :ok" do
      result = Poll.retry_until!("immediate", 3, 0, fn -> :ok end)
      assert result == :ok
    end

    test "success-after-retry: fun returning {:error, _} then :ok returns :ok" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      result =
        Poll.retry_until!("transient", 3, 0, fn ->
          n = Agent.get_and_update(counter, &{&1, &1 + 1})
          if n == 0, do: {:error, "transient failure"}, else: :ok
        end)

      assert result == :ok
      assert Agent.get(counter, & &1) == 2
    end

    test "exhausted: raises RuntimeError containing label and 'failed after 2 attempts'" do
      assert_raise RuntimeError, ~r/exhausted-label/, fn ->
        Poll.retry_until!("exhausted-label", 2, 0, fn -> {:error, "boom"} end)
      end

      assert_raise RuntimeError, ~r/failed after 2 attempts/, fn ->
        Poll.retry_until!("exhausted-label", 2, 0, fn -> {:error, "boom"} end)
      end
    end
  end
end
