defmodule Relyra.Metadata.TrustAnchor do
  @moduledoc """
  Operator-pinned trust-anchor check for Phase 21 scheduled metadata
  refresh per D-17.

  The trust anchor is a list of SHA-256 hex fingerprints (lowercase) the
  operator pinned out-of-band before enabling scheduled refresh on a
  `MetadataSource`. This module checks that AT LEAST ONE candidate
  certificate (PEM) presented in the freshly-fetched metadata matches one
  of those pinned fingerprints.

  Why no TOFU: the first fetch is the moment of maximum MITM exposure;
  institutionalizing "trust on first fetch" hands an attacker a one-shot
  window. (ruby-saml CVE-2024-45409 lesson — locked rejection per D-17.)

  Why no reuse-of-assertion-cert: the SAML metadata signing key and the
  assertion signing key are spec-separate roles; conflating them breaks
  any IdP that follows the spec. The metadata trust anchor MUST be its
  own pinned set, populated via the admin LiveView pinning UX (D-22) or
  the `mix relyra.metadata.pin` task.

  Pure: no I/O, no Ecto, no Repo. Reuses the existing fingerprint compute
  from `lib/relyra/metadata/import.ex` (Don't Hand-Roll row 5).
  """

  alias Relyra.Error

  @doc """
  Returns `:ok` if at least one PEM in `candidate_pems` produces a SHA-256
  fingerprint (lowercase hex, no colons) present in `pinned_fingerprints`.

  Returns `{:error, %Relyra.Error{type: :trust_anchor_mismatch}}` otherwise,
  including the empty-pinned-list case (the schema-level great-error from
  `auto_refresh_changeset/2` should prevent this from ever happening, but
  the helper is still defensive).
  """
  @spec check([String.t()], [String.t()]) :: :ok | {:error, Error.t()}
  def check(candidate_pems, pinned_fingerprints)
      when is_list(candidate_pems) and is_list(pinned_fingerprints) do
    candidate_fps = MapSet.new(candidate_pems, &fingerprint/1)
    pinned = MapSet.new(pinned_fingerprints, &normalize/1)

    cond do
      MapSet.size(pinned) == 0 ->
        {:error,
         Error.new(
           :trust_anchor_mismatch,
           "No metadata trust fingerprints are pinned for this source",
           %{reason: :no_pinned_fingerprints, candidate_count: length(candidate_pems)}
         )}

      MapSet.disjoint?(candidate_fps, pinned) ->
        {:error,
         Error.new(
           :trust_anchor_mismatch,
           "None of the candidate metadata signing certificates match a pinned fingerprint",
           %{
             reason: :no_match,
             candidate_count: MapSet.size(candidate_fps),
             pinned_count: MapSet.size(pinned)
           }
         )}

      true ->
        :ok
    end
  end

  @doc """
  Computes the canonical Phase-21 fingerprint for a PEM (SHA-256, lowercase
  hex, no colons). Mirrors `Relyra.Metadata.Import.sha256/1` (line 125-126).
  """
  @spec fingerprint(String.t()) :: String.t()
  def fingerprint(pem) when is_binary(pem) do
    :crypto.hash(:sha256, pem) |> Base.encode16(case: :lower)
  end

  defp normalize(fp) when is_binary(fp), do: String.downcase(fp)
end
