defmodule Relyra.Metadata.Backoff do
  @moduledoc """
  Pure exponential-backoff schedule for Phase 21 auto-suspend per D-25.

  Tiers: 1h → 6h → 24h cap. After 5 consecutive transient failures
  (the suspend threshold), the tier index advances by one each subsequent
  consecutive failure, capped at the 24h tier. ±10% jitter per AWS
  Builder's Library "Timeouts, retries and backoff with jitter" (D-25).

  Pure: no I/O, no Ecto. Deterministic-with-jitter (`Enum.random/1` is the
  only nondeterminism source).
  """

  # LOCKED tier schedule per D-25 (1h → 6h → 24h cap).
  @backoff_tiers_seconds [3_600, 21_600, 86_400]

  # LOCKED suspend threshold per D-25 (5 consecutive transient failures).
  @suspend_threshold 5

  @spec suspend_threshold() :: pos_integer()
  def suspend_threshold, do: @suspend_threshold

  @spec tier_seconds(non_neg_integer()) :: pos_integer()
  def tier_seconds(consecutive_failures) when is_integer(consecutive_failures) do
    tier_index = max(consecutive_failures - @suspend_threshold, 0)
    capped_index = min(tier_index, length(@backoff_tiers_seconds) - 1)
    Enum.at(@backoff_tiers_seconds, capped_index)
  end

  @doc """
  Returns the absolute DateTime at which the source becomes eligible for a
  half-open probe (D-25 soft-backoff semantics — scheduler skips the source
  until this passes, then runs ONE probe). ±10% jitter (D-25).
  """
  @spec backoff_until(non_neg_integer(), DateTime.t()) :: DateTime.t()
  def backoff_until(consecutive_failures, base \\ DateTime.utc_now())

  def backoff_until(consecutive_failures, %DateTime{} = base)
      when is_integer(consecutive_failures) do
    tier = tier_seconds(consecutive_failures)
    jittered = apply_jitter(tier, 0.10)
    DateTime.add(base, jittered, :second)
  end

  defp apply_jitter(seconds, ratio) do
    span = round(seconds * ratio)
    seconds + Enum.random(-span..span)
  end
end
