defmodule Relyra.Metadata.BackoffTest do
  use ExUnit.Case, async: true

  alias Relyra.Metadata.Backoff

  describe "suspend_threshold/0" do
    test "is the LOCKED 5-consecutive-failure threshold (D-25)" do
      assert Backoff.suspend_threshold() == 5
    end
  end

  describe "tier_seconds/1" do
    test "returns 1h for the first suspend (consecutive_failures == 5)" do
      assert Backoff.tier_seconds(5) == 3_600
    end

    test "returns 6h for the second tier (consecutive_failures == 6)" do
      assert Backoff.tier_seconds(6) == 21_600
    end

    test "returns 24h cap for the third tier and beyond (consecutive_failures >= 7)" do
      assert Backoff.tier_seconds(7) == 86_400
      assert Backoff.tier_seconds(20) == 86_400
      assert Backoff.tier_seconds(1_000) == 86_400
    end

    test "returns 1h floor for any consecutive_failures < threshold (defensive — should never be called below threshold but must not crash)" do
      assert Backoff.tier_seconds(0) == 3_600
      assert Backoff.tier_seconds(4) == 3_600
    end
  end

  describe "backoff_until/2 jitter envelope" do
    test "for tier 1 (1h), envelope is 1h ± 10% (D-25)" do
      base = ~U[2026-05-06 00:00:00.000000Z]

      for _ <- 1..200 do
        ahead = DateTime.diff(Backoff.backoff_until(5, base), base, :second)
        assert ahead >= 3_600 - 360 and ahead <= 3_600 + 360
      end
    end

    test "for tier 2 (6h), envelope is 6h ± 10%" do
      base = ~U[2026-05-06 00:00:00.000000Z]

      for _ <- 1..200 do
        ahead = DateTime.diff(Backoff.backoff_until(6, base), base, :second)
        assert ahead >= 21_600 - 2_160 and ahead <= 21_600 + 2_160
      end
    end

    test "for tier 3 cap (24h), envelope is 24h ± 10%" do
      base = ~U[2026-05-06 00:00:00.000000Z]

      for _ <- 1..200 do
        ahead = DateTime.diff(Backoff.backoff_until(7, base), base, :second)
        assert ahead >= 86_400 - 8_640 and ahead <= 86_400 + 8_640
      end
    end
  end
end
