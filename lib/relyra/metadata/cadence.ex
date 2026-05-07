defmodule Relyra.Metadata.Cadence do
  @moduledoc """
  Pure cadence resolver for Phase 21 scheduled metadata refresh.

  The 1-hour hard floor is BAKED IN here per D-14 (InCommon Federation
  Metadata Registration Practice Statement: ≤1 refresh per relying party
  per hour). A future enum revision that adds a more aggressive preset
  cannot bypass the floor.

  Pure: no I/O, no Ecto, no telemetry. Deterministic-with-jitter
  (`Enum.random/1` is the only nondeterminism source).
  """

  # Locked: 1-hour hard floor per D-14.
  @hard_floor_seconds 3_600

  # LOCKED enum per D-10. Adding a preset MUST keep the hard floor in mind.
  @cadence_seconds %{
    hourly: 3_600,
    every_6h: 21_600,
    daily: 86_400,
    weekly: 604_800
  }

  @cadence_values Map.keys(@cadence_seconds)

  @spec cadence_values() :: [atom()]
  def cadence_values, do: @cadence_values

  @spec cadence_seconds(atom()) :: non_neg_integer()
  def cadence_seconds(cadence) when is_map_key(@cadence_seconds, cadence) do
    Map.fetch!(@cadence_seconds, cadence)
  end

  @doc """
  Computes the next refresh time given a cadence preset and a base time.

  - Applies ±15% jitter ONCE per scheduling decision (D-12: persisted, not
    recomputed on tick — callers MUST persist the returned timestamp on
    `MetadataSource.next_refresh_at` rather than recomputing each tick).
  - Enforces the 1-hour InCommon hard floor (D-14).
  """
  @spec next_refresh_at(atom(), DateTime.t()) :: DateTime.t()
  def next_refresh_at(cadence, base \\ DateTime.utc_now())

  def next_refresh_at(cadence, %DateTime{} = base)
      when is_map_key(@cadence_seconds, cadence) do
    interval = Map.fetch!(@cadence_seconds, cadence)
    floored = max(interval, @hard_floor_seconds)
    jittered = apply_jitter(floored, 0.15)
    DateTime.add(base, jittered, :second)
  end

  @doc false
  @spec apply_jitter(pos_integer(), float()) :: pos_integer()
  def apply_jitter(seconds, ratio) when is_integer(seconds) and is_float(ratio) do
    span = round(seconds * ratio)
    seconds + Enum.random(-span..span)
  end
end
