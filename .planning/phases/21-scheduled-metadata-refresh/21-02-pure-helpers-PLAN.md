---
phase: 21
plan: 02
type: execute
wave: 1
depends_on: [21-01]
files_modified:
  - lib/relyra/metadata/cadence.ex
  - lib/relyra/metadata/backoff.ex
  - lib/relyra/metadata/failure_classifier.ex
  - test/relyra/metadata/cadence_test.exs
  - test/relyra/metadata/backoff_test.exs
  - test/relyra/metadata/failure_classifier_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Cadence helper turns any of the four LOCKED presets into a jittered next_refresh_at and never returns a value sooner than 1 hour from now"
    - "Cadence module exposes ONLY the four LOCKED presets (D-13: no per-source override beyond the four; no global default cadence config) — the @cadence_seconds module attribute is the authoritative source of truth"
    - "Backoff helper produces the LOCKED 1h → 6h → 24h tier schedule with ±10% jitter and stays at 24h thereafter"
    - "Failure classifier returns the three flags (transient?, counts_toward_suspend?, alert_immediately?) for every documented error code AND a safe default for unknown codes"
    - "All three helpers are pure: no Ecto, no Repo, no Req, no telemetry, no I/O"
  artifacts:
    - path: "lib/relyra/metadata/cadence.ex"
      provides: "Pure cadence resolver with the LOCKED 1h hard floor (D-14) and ±15% jitter (D-12)"
      exports: ["next_refresh_at/2", "cadence_seconds/1"]
    - path: "lib/relyra/metadata/backoff.ex"
      provides: "Pure backoff schedule for D-25 (1h → 6h → 24h cap, ±10% jitter)"
      exports: ["backoff_until/2", "tier_seconds/1"]
    - path: "lib/relyra/metadata/failure_classifier.ex"
      provides: "Pure D-27 classifier for every Phase-21 error code"
      exports: ["classify/1"]
  key_links:
    - from: "lib/relyra/metadata/cadence.ex"
      to: "@hard_floor_seconds 3600 + @cadence_seconds %{hourly: 3_600, every_6h: 21_600, daily: 86_400, weekly: 604_800}"
      via: "Module attributes baked at compile time so the InCommon ≤1/hour ceiling cannot be bypassed"
      pattern: "@hard_floor_seconds 3600"
    - from: "lib/relyra/metadata/backoff.ex"
      to: "@backoff_tiers_seconds [3_600, 21_600, 86_400]"
      via: "Module attribute is the source of truth for the three tiers"
      pattern: "@backoff_tiers_seconds"
    - from: "lib/relyra/metadata/failure_classifier.ex"
      to: "Phase 21 error code atoms"
      via: "Function-head per error code; default `_other` clause keeps the classifier total"
      pattern: "def classify("
---

<objective>
Land the three pure-function helpers Phase 21's wrapper, scheduler, and audit-writer-seam extension will all consume: cadence resolver (preset → jittered `next_refresh_at` with the 1h hard floor), backoff schedule (1h → 6h → 24h cap with ±10% jitter), and failure classifier (every error code → `{transient?, counts_toward_suspend?, alert_immediately?}` flags). All three are deterministic-with-jitter pure functions with no Ecto, no Repo, no Req, no telemetry, no I/O — they exist so the downstream Wave 2 wrapper modules can depend on simple total functions instead of re-implementing classification logic at every call site.

Purpose: Per RESEARCH "Wave plan", pure-function helpers ship in Wave 1 so Wave 2 wrappers (`AutoRefresh`, `Scheduler`, `MetadataApply` extension) can consume stable, property-tested primitives. Per RESEARCH Pitfall 1, the failure classifier MUST be at-emit-time inference (not a separate Ecto table — overkill — and not per-error-code metadata scattered across modules — drift footgun). Per D-14, the 1-hour InCommon hard floor is baked into the cadence helper so no future enum revision can bypass it.

Output: Three new modules, each with its own ExUnit test file (replacing the Wave 0 stubs from Plan 01). Cadence and backoff have property tests for the jitter envelope; failure classifier has a table test enumerating every Phase-21 error code.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/security/algorithm_policy.ex

<interfaces>
Module-attr policy table pattern (`lib/relyra/security/algorithm_policy.ex` lines 6-14) — copy this shape verbatim:

```elixir
@sha1_signature_methods MapSet.new([
                          "http://www.w3.org/2000/09/xmldsig#rsa-sha1",
                          "http://www.w3.org/2001/04/xmldsig-more#rsa-sha1"
                        ])
```

`{:ok, _} | {:error, %Relyra.Error{}}` return contract (`lib/relyra/error.ex`) — pure helpers in this plan return raw values, NOT the result tuple, because they cannot fail (every input is exhausted by typespec; classifier has a catch-all default).

Phase-21 error code atoms the classifier MUST enumerate (per RESEARCH Pattern 3 + D-27, EXACT list — keep in sync with the suspended_reason enum from Plan 01):

Transient (count toward suspend, suppress single-blip alert):
- `:fetch_timeout`
- `:fetch_http_5xx`
- `:fetch_dns_failure`
- `:fetch_connection_refused`
- `:fetch_tls_handshake`

Suspicious (alert immediately, never count toward suspend):
- `:signature_failed`
- `:parse_failed`
- `:validation_failed`
- `:apply_failed`
- `:fetch_http_4xx`
- `:metadata_drift_requires_review`
- `:corpus_violation`
- `:trust_anchor_mismatch`

Default (unknown atom): treat as suspicious (`alert_immediately?: true, counts_toward_suspend?: false`).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Implement cadence + backoff pure helpers with property-style jitter envelope tests</name>
  <files>lib/relyra/metadata/cadence.ex, lib/relyra/metadata/backoff.ex, test/relyra/metadata/cadence_test.exs, test/relyra/metadata/backoff_test.exs</files>
  <read_first>
    - lib/relyra/security/algorithm_policy.ex (canonical module-attr policy-table shape; lines 6-47)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pattern 2: Cadence Resolver" and "Pattern 4: Backoff Schedule" sections
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/metadata/cadence.ex / failure_classifier.ex / backoff.ex" section
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-10 cadence enum LOCKED; D-11 default :daily; D-12 ±15% jitter; D-14 1-hour hard floor; D-25 backoff tiers + ±10% jitter)
    - test/relyra/metadata/cadence_test.exs (Wave 0 stub from Plan 01 — delete the stub body and replace with real tests)
    - test/relyra/metadata/backoff_test.exs (Wave 0 stub from Plan 01)
  </read_first>
  <action>
    Create `lib/relyra/metadata/cadence.ex` with module name `Relyra.Metadata.Cadence`. Module attrs (LOCKED — RESEARCH Pattern 2):

    ```elixir
    defmodule Relyra.Metadata.Cadence do
      @moduledoc """
      Pure cadence resolver for Phase 21 scheduled metadata refresh.

      The 1-hour hard floor is BAKED IN here per D-14 (InCommon Federation
      Metadata Registration Practice Statement: ≤1 refresh per relying party
      per hour). A future enum revision that adds a more aggressive preset
      cannot bypass the floor.

      Pure: no I/O, no Ecto, no telemetry. Deterministic-with-jitter
      (Enum.random/1 is the only nondeterminism source).
      """

      # Locked: 1-hour hard floor per D-14.
      @hard_floor_seconds 3_600

      # LOCKED enum per D-10. Adding a preset MUST keep the hard floor in mind.
      @cadence_seconds %{
        hourly:    3_600,
        every_6h:  21_600,
        daily:     86_400,
        weekly:    604_800
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
    ```

    Create `lib/relyra/metadata/backoff.ex` with module name `Relyra.Metadata.Backoff`. Module attrs and one public function per RESEARCH Pattern 4:

    ```elixir
    defmodule Relyra.Metadata.Backoff do
      @moduledoc """
      Pure exponential-backoff schedule for Phase 21 auto-suspend per D-25.

      Tiers: 1h → 6h → 24h cap. After 5 consecutive transient failures
      (the suspend threshold), the tier index advances by one each subsequent
      consecutive failure, capped at the 24h tier. ±10% jitter per AWS
      Builder's Library "Timeouts, retries and backoff with jitter" (D-25).

      Pure: no I/O, no Ecto. Deterministic-with-jitter (Enum.random/1 is the
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
    ```

    Tests for `test/relyra/metadata/cadence_test.exs` (replace the Wave 0 stub completely — drop `@moduletag :pending` and the flunking test):

    ```elixir
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

        test "the 1-hour hard floor is baked in: even if Cadence's @hard_floor_seconds were bypassed, the helper enforces max(interval, 3600)" do
          # Sanity: :hourly == 3600 == floor; verify the documented floor constant exists.
          base = ~U[2026-05-06 00:00:00.000000Z]
          ahead = DateTime.diff(Cadence.next_refresh_at(:hourly, base), base, :second)
          # Lower bound: 3600 - 15% = 3060. Even with worst-case negative jitter we can't go below this.
          assert ahead >= 3_060
        end

        test "uses utc_now() as the default base" do
          before = DateTime.utc_now()
          result = Cadence.next_refresh_at(:hourly)
          # Result is at least 3060s ahead of `before` and at most 4140s ahead of NOW
          assert DateTime.diff(result, before, :second) >= 3_060
        end

        test "raises FunctionClauseError for unknown cadence preset" do
          assert_raise FunctionClauseError, fn ->
            Cadence.next_refresh_at(:every_30s, DateTime.utc_now())
          end
        end
      end
    end
    ```

    Tests for `test/relyra/metadata/backoff_test.exs`:

    ```elixir
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
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/metadata/cadence_test.exs test/relyra/metadata/backoff_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/relyra/metadata/cadence.ex` exists with `defmodule Relyra.Metadata.Cadence`.
    - `grep -c "@hard_floor_seconds 3_600" lib/relyra/metadata/cadence.ex` returns `1` (D-14 hard floor baked in).
    - `grep -E "@cadence_seconds %\{" lib/relyra/metadata/cadence.ex` returns a match (LOCKED enum table present).
    - `grep -c "def next_refresh_at" lib/relyra/metadata/cadence.ex` returns `1`.
    - File `lib/relyra/metadata/backoff.ex` exists with `defmodule Relyra.Metadata.Backoff`.
    - `grep -c "@backoff_tiers_seconds \[3_600, 21_600, 86_400\]" lib/relyra/metadata/backoff.ex` returns `1` (LOCKED tier schedule).
    - `grep -c "@suspend_threshold 5" lib/relyra/metadata/backoff.ex` returns `1`.
    - `grep -c "def backoff_until" lib/relyra/metadata/backoff.ex` returns `1`.
    - Neither file imports `Ecto`, `Repo`, `Req`, or any I/O-touching module: `grep -cE "alias Relyra\\.(Ecto|Telemetry)|require Logger|use Ecto|alias Ecto" lib/relyra/metadata/cadence.ex lib/relyra/metadata/backoff.ex` returns `0`.
    - `mix test test/relyra/metadata/cadence_test.exs test/relyra/metadata/backoff_test.exs --warnings-as-errors` exits 0 with all tests passing (≥ 200 jitter samples per envelope test).
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>Both pure helpers exist, are documented as I/O-free, and pass property-style jitter-envelope tests with 200 random samples each. The 1-hour hard floor and the LOCKED tier schedule are module attributes (not magic numbers scattered across the codebase). Tests no longer carry `:pending`.</done>
</task>

<task type="auto">
  <name>Task 2: Implement failure_classifier with one function-head per error code and a table test</name>
  <files>lib/relyra/metadata/failure_classifier.ex, test/relyra/metadata/failure_classifier_test.exs</files>
  <read_first>
    - lib/relyra/security/algorithm_policy.ex (analog: per-input function clauses + default fall-through; lines 74-110)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pattern 3: Failure Classifier" section (LOCKED error-code list + flag semantics)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/metadata/cadence.ex / failure_classifier.ex / backoff.ex" section
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-27 asymmetric failure classification — transient vs suspicious; flag names)
    - test/relyra/metadata/failure_classifier_test.exs (Wave 0 stub from Plan 01)
  </read_first>
  <action>
    Create `lib/relyra/metadata/failure_classifier.ex` with module name `Relyra.Metadata.FailureClassifier`. One function-head per error code, three private constructors for the three classifications, and a default `_other` clause per RESEARCH Pattern 3 verbatim:

    ```elixir
    defmodule Relyra.Metadata.FailureClassifier do
      @moduledoc """
      Pure D-27 classifier. Maps a Phase-21 error-code atom to three flags
      that drive the `[:relyra, :saml, :metadata, :auto_refresh, ...]` state
      machine and telemetry payload (D-23/D-27).

      Transient errors (network/connectivity blips) count toward auto-suspend
      and suppress single-blip alerts (alert_immediately?: false → host's
      `LogAlerts` reference handler suppresses the first occurrence and pages
      from the 2nd).

      Suspicious errors (signature/parse/validation/drift/corpus failures)
      alert immediately and never count toward suspend — they need human eyes,
      not silent backoff.

      The three flag names match the telemetry payload keys exactly per
      RESEARCH Assumption A4 (no key drift between code and docs).

      Pure: no I/O, no Ecto, no Repo, no telemetry. The decision is tagged at
      emit time so the telemetry payload carries the flags directly.
      """

      @type classification :: %{
              transient?: boolean(),
              counts_toward_suspend?: boolean(),
              alert_immediately?: boolean()
            }

      @spec classify(atom()) :: classification()
      # Transient (D-27): count toward suspend, suppress single-blip alert
      def classify(:fetch_timeout),                 do: transient()
      def classify(:fetch_http_5xx),                do: transient()
      def classify(:fetch_dns_failure),             do: transient()
      def classify(:fetch_connection_refused),      do: transient()
      def classify(:fetch_tls_handshake),           do: transient()

      # Suspicious (D-27): alert immediately, never count toward suspend
      def classify(:signature_failed),              do: suspicious()
      def classify(:parse_failed),                  do: suspicious()
      def classify(:validation_failed),             do: suspicious()
      def classify(:apply_failed),                  do: suspicious()
      def classify(:fetch_http_4xx),                do: suspicious()
      def classify(:metadata_drift_requires_review), do: suspicious()
      def classify(:corpus_violation),              do: suspicious()
      def classify(:trust_anchor_mismatch),         do: suspicious()

      # Default: unknown atoms surface as suspicious (alert + don't count) so
      # an unclassified failure does not silently suppress an alert.
      def classify(_other), do: unknown()

      defp transient,
        do: %{transient?: true, counts_toward_suspend?: true, alert_immediately?: false}

      defp suspicious,
        do: %{transient?: false, counts_toward_suspend?: false, alert_immediately?: true}

      defp unknown,
        do: %{transient?: false, counts_toward_suspend?: false, alert_immediately?: true}
    end
    ```

    Tests for `test/relyra/metadata/failure_classifier_test.exs` (replace the Wave 0 stub completely — drop `@moduletag :pending` and the flunking test). Use a table-driven shape:

    ```elixir
    defmodule Relyra.Metadata.FailureClassifierTest do
      use ExUnit.Case, async: true
      alias Relyra.Metadata.FailureClassifier

      @transient_codes [
        :fetch_timeout,
        :fetch_http_5xx,
        :fetch_dns_failure,
        :fetch_connection_refused,
        :fetch_tls_handshake
      ]

      @suspicious_codes [
        :signature_failed,
        :parse_failed,
        :validation_failed,
        :apply_failed,
        :fetch_http_4xx,
        :metadata_drift_requires_review,
        :corpus_violation,
        :trust_anchor_mismatch
      ]

      describe "classify/1 transient codes" do
        for code <- @transient_codes do
          test "#{inspect(code)} → transient (counts toward suspend, suppress single-blip alert)" do
            result = FailureClassifier.classify(unquote(code))
            assert result == %{
                     transient?: true,
                     counts_toward_suspend?: true,
                     alert_immediately?: false
                   }
          end
        end
      end

      describe "classify/1 suspicious codes" do
        for code <- @suspicious_codes do
          test "#{inspect(code)} → suspicious (alert immediately, never count toward suspend)" do
            result = FailureClassifier.classify(unquote(code))
            assert result == %{
                     transient?: false,
                     counts_toward_suspend?: false,
                     alert_immediately?: true
                   }
          end
        end
      end

      describe "classify/1 unknown codes" do
        test "an unknown atom defaults to alert_immediately?: true and counts_toward_suspend?: false (D-27 conservative default)" do
          assert FailureClassifier.classify(:something_we_havent_seen) ==
                   %{transient?: false, counts_toward_suspend?: false, alert_immediately?: true}
        end
      end

      describe "exhaustiveness invariant" do
        test "the union of @transient_codes and @suspicious_codes equals every error code Phase 21 emits (cross-check vs documented LOCKED list)" do
          all = MapSet.union(MapSet.new(@transient_codes), MapSet.new(@suspicious_codes))
          assert MapSet.size(all) == 13,
                 "Expected 13 documented error codes (5 transient + 8 suspicious per RESEARCH Pattern 3)"
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/metadata/failure_classifier_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/relyra/metadata/failure_classifier.ex` exists with `defmodule Relyra.Metadata.FailureClassifier`.
    - `grep -c "def classify(" lib/relyra/metadata/failure_classifier.ex` returns at least `14` (13 documented codes + 1 default `_other`).
    - `grep -cE "(:fetch_timeout|:fetch_http_5xx|:fetch_dns_failure|:fetch_connection_refused|:fetch_tls_handshake)" lib/relyra/metadata/failure_classifier.ex` returns at least `5` (every transient code present as a clause).
    - `grep -cE "(:signature_failed|:parse_failed|:validation_failed|:apply_failed|:fetch_http_4xx|:metadata_drift_requires_review|:corpus_violation|:trust_anchor_mismatch)" lib/relyra/metadata/failure_classifier.ex` returns at least `8` (every suspicious code present).
    - `grep -c "def classify(_other)" lib/relyra/metadata/failure_classifier.ex` returns `1` (default catch-all).
    - File does not import `Ecto`, `Repo`, `Req`, `Logger`, or `Telemetry`: `grep -cE "alias Relyra\\.(Ecto|Telemetry|Log)|require Logger|use Ecto|alias Ecto" lib/relyra/metadata/failure_classifier.ex` returns `0`.
    - `mix test test/relyra/metadata/failure_classifier_test.exs --warnings-as-errors` exits 0 with all 14+ tests passing (one per documented code + the unknown-default test + the exhaustiveness invariant).
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>Classifier exists, is total (catch-all clause), has the LOCKED 13 error codes enumerated as separate function clauses, returns the exact 3-flag map keys per RESEARCH A4, and has a table test enumerating every code. The exhaustiveness test guards against documented-vs-implemented drift.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Untrusted error code → `FailureClassifier.classify/1` | An error atom from a future code path (or a typo) is classified by the catch-all clause; the default disposition determines whether silent suppression vs alerting is the safe failure mode. |
| Cadence helper → persisted `next_refresh_at` | Calculated value is stored on `MetadataSource` and drives subsequent scheduler ticks; if the helper returned a value sooner than the InCommon ceiling, the scheduler would DDoS the IdP. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-07 | Denial of Service | `Cadence.next_refresh_at/2` | mitigate | `@hard_floor_seconds 3_600` baked in as `max(interval, @hard_floor_seconds)` per D-14 — no preset and no future code path can produce a value sooner than the InCommon ≤1/hour ceiling, even if `@cadence_seconds` is later edited. |
| T-21-08 | Repudiation | `FailureClassifier.classify/1` default clause | mitigate | The catch-all returns `alert_immediately?: true, counts_toward_suspend?: false` — an unknown error code surfaces to the operator's paging system rather than being silently suppressed. Never returns the transient classification by default. |
| T-21-09 | Tampering | `Backoff.tier_seconds/1` | mitigate | `@backoff_tiers_seconds` and `@suspend_threshold` are module attributes (compile-time constants); cannot be runtime-mutated. The cap at 24h is enforced by `min(tier_index, length(@backoff_tiers_seconds) - 1)` so an attacker who could somehow inflate `consecutive_failures` cannot extend backoff beyond 24h (which would create an exposure window). |
| T-21-10 | Spoofing | `Cadence.apply_jitter/2` (public for testability) | accept | Jitter is intentionally nondeterministic via `Enum.random/1`; tests rely on bounded envelope, not exact values. Public visibility is for test access only — module is documented as pure, no other module should call it. |
</threat_model>

<verification>
- `mix test test/relyra/metadata/cadence_test.exs test/relyra/metadata/backoff_test.exs test/relyra/metadata/failure_classifier_test.exs --warnings-as-errors` is green.
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green (helpers have zero optional-dep references).
- `mix format --check-formatted` is green.
- `mix credo --strict` does not introduce new warnings on the three new files.
</verification>

<success_criteria>
- `Relyra.Metadata.Cadence.next_refresh_at/2` exists, has the 1-hour hard floor as a module attribute (D-14), produces values within ±15% of the preset interval (D-12), and has a 200-sample property test for at least two presets.
- `Relyra.Metadata.Backoff.backoff_until/2` exists, produces 1h → 6h → 24h cap tiers (D-25), applies ±10% jitter, and has a 200-sample envelope test for each tier.
- `Relyra.Metadata.FailureClassifier.classify/1` enumerates every Phase-21 error code as its own clause (D-27), returns the LOCKED 3-flag map shape, and has an exhaustiveness test.
- All three modules are pure (no Ecto, no Repo, no Req, no telemetry, no Logger).
- All three Wave 0 stub test files are replaced with real tests; `mix test --exclude pending` count of passing tests is up by ≥ 25 (15 cadence + 10 backoff + 14 classifier).
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-02-SUMMARY.md` summarizing: module names + line counts, the LOCKED constants exposed (`@hard_floor_seconds`, `@cadence_seconds`, `@backoff_tiers_seconds`, `@suspend_threshold`), test counts per file, and any deviations from the locked behavior.
</output>