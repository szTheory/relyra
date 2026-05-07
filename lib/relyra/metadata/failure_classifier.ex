defmodule Relyra.Metadata.FailureClassifier do
  @moduledoc """
  Pure D-27 classifier. Maps a Phase-21 error-code atom to three flags
  that drive the `[:relyra, :saml, :metadata, :auto_refresh, ...]` state
  machine and telemetry payload (D-23/D-27).

  Transient errors (network/connectivity blips) count toward auto-suspend
  and suppress single-blip alerts (`alert_immediately?: false` → host's
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
  def classify(:fetch_timeout), do: transient()
  def classify(:fetch_http_5xx), do: transient()
  def classify(:fetch_dns_failure), do: transient()
  def classify(:fetch_connection_refused), do: transient()
  def classify(:fetch_tls_handshake), do: transient()

  # Suspicious (D-27): alert immediately, never count toward suspend
  def classify(:signature_failed), do: suspicious()
  def classify(:parse_failed), do: suspicious()
  def classify(:validation_failed), do: suspicious()
  def classify(:apply_failed), do: suspicious()
  def classify(:fetch_http_4xx), do: suspicious()
  def classify(:metadata_drift_requires_review), do: suspicious()
  def classify(:corpus_violation), do: suspicious()
  def classify(:trust_anchor_mismatch), do: suspicious()

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
