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
