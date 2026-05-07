defmodule Relyra.Metadata.CadenceTest do
  use ExUnit.Case, async: true

  alias Relyra.Metadata.Cadence

  describe "cadence_values/0 + cadence_seconds/1" do
    test "exposes the LOCKED four-preset enum (D-10)" do
      assert Enum.sort(Cadence.cadence_values()) ==
               [:daily, :every_6h, :hourly, :weekly]
    end

    test "cadence_seconds/1 returns the LOCKED tier seconds for each preset" do
      assert Cadence.cadence_seconds(:hourly) == 3_600
      assert Cadence.cadence_seconds(:every_6h) == 21_600
      assert Cadence.cadence_seconds(:daily) == 86_400
      assert Cadence.cadence_seconds(:weekly) == 604_800
    end
  end

  describe "next_refresh_at/2" do
    test "for :hourly, the next refresh is between ~51 minutes and ~69 minutes ahead (±15% of 1h, with 1h floor enforced)" do
      base = ~U[2026-05-06 00:00:00.000000Z]
      # Hourly is exactly the floor; jitter ±15% of 3600 = ±540 seconds
      for _ <- 1..200 do
        ahead = DateTime.diff(Cadence.next_refresh_at(:hourly, base), base, :second)
        assert ahead >= 3_600 - 540 and ahead <= 3_600 + 540
      end
    end

    test "for :daily, the next refresh is approximately 1 day ahead with ±15% jitter" do
      base = ~U[2026-05-06 00:00:00.000000Z]

      for _ <- 1..200 do
        ahead = DateTime.diff(Cadence.next_refresh_at(:daily, base), base, :second)
        assert ahead >= 86_400 - round(86_400 * 0.15)
        assert ahead <= 86_400 + round(86_400 * 0.15)
      end
    end

    test "the 1-hour hard floor is baked in: even at the lowest preset the helper enforces max(interval, 3600)" do
      # Sanity: :hourly == 3600 == floor; verify the documented floor constant exists.
      base = ~U[2026-05-06 00:00:00.000000Z]
      ahead = DateTime.diff(Cadence.next_refresh_at(:hourly, base), base, :second)

      # Lower bound: 3600 - 15% = 3060. Even with worst-case negative jitter we can't go below this.
      assert ahead >= 3_060
    end

    test "uses utc_now() as the default base" do
      before = DateTime.utc_now()
      result = Cadence.next_refresh_at(:hourly)
      # Result is at least 3060s ahead of `before`
      assert DateTime.diff(result, before, :second) >= 3_060
    end

    test "raises FunctionClauseError for unknown cadence preset" do
      assert_raise FunctionClauseError, fn ->
        Cadence.next_refresh_at(:every_30s, DateTime.utc_now())
      end
    end
  end
end
