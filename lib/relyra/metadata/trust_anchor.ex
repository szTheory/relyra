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

  Pure: no I/O, no Ecto, no Repo. `fingerprint/1` is the canonical
  trust-fingerprint compute for the metadata subsystem (DER SHA-256); the
  certificate-fingerprint compute in `lib/relyra/metadata/import.ex` and the
  drift detector route through it so the pin, the admin-displayed fingerprint,
  the drift detector, and `openssl x509 -outform DER | openssl dgst -sha256`
  all agree (CR-02).
  """

  alias Relyra.Error

  # Sentinel returned for input that cannot be decoded to a certificate. It is
  # deliberately NOT 64-char hex, so a malformed candidate can never collide with
  # an operator-pinned (or openssl-derived) fingerprint (fail-closed).
  @uncomputable_fingerprint "uncomputable-certificate-fingerprint"

  @doc """
  Returns `{:ok, matched_pems}` — the subset of `candidate_pems` whose DER
  fingerprint is present in `pinned_fingerprints` — or
  `{:error, %Relyra.Error{type: :trust_anchor_mismatch}}` when none match (or no
  fingerprints are pinned).

  CR-01: the caller MUST verify the metadata signature against ONLY these matched
  (operator-pinned) PEMs — NEVER the full document-supplied set. The candidate
  certificate that satisfies the pin and the certificate whose key actually
  verifies the signature must be the SAME cert. Verifying against an unpinned,
  attacker-supplied cert (e.g. one prepended ahead of the legitimate, public
  cert) while the pin is satisfied by a different cert is an auth-bypass.
  """
  @spec matching_pems([String.t()], [String.t()]) :: {:ok, [String.t()]} | {:error, Error.t()}
  def matching_pems(candidate_pems, pinned_fingerprints)
      when is_list(candidate_pems) and is_list(pinned_fingerprints) do
    pinned = MapSet.new(pinned_fingerprints, &normalize/1)

    cond do
      MapSet.size(pinned) == 0 ->
        {:error,
         Error.new(
           :trust_anchor_mismatch,
           "No metadata trust fingerprints are pinned for this source",
           %{reason: :no_pinned_fingerprints, candidate_count: length(candidate_pems)}
         )}

      true ->
        matched = Enum.filter(candidate_pems, &MapSet.member?(pinned, fingerprint(&1)))

        case matched do
          [] ->
            {:error,
             Error.new(
               :trust_anchor_mismatch,
               "None of the candidate metadata signing certificates match a pinned fingerprint",
               %{
                 reason: :no_match,
                 candidate_count: length(candidate_pems),
                 pinned_count: MapSet.size(pinned)
               }
             )}

          pems ->
            {:ok, pems}
        end
    end
  end

  @doc """
  Returns `:ok` if at least one PEM in `candidate_pems` matches a pinned
  fingerprint, `{:error, %Relyra.Error{type: :trust_anchor_mismatch}}` otherwise
  (including the empty-pinned-list case).

  Thin boolean view of `matching_pems/2`. Prefer `matching_pems/2` on the
  verification path so the signature is checked against ONLY the pinned cert(s)
  (CR-01).
  """
  @spec check([String.t()], [String.t()]) :: :ok | {:error, Error.t()}
  def check(candidate_pems, pinned_fingerprints)
      when is_list(candidate_pems) and is_list(pinned_fingerprints) do
    case matching_pems(candidate_pems, pinned_fingerprints) do
      {:ok, _matched} -> :ok
      {:error, _} = error -> error
    end
  end

  @doc """
  Computes the canonical trust fingerprint for a PEM: the SHA-256 of the
  certificate's **DER** bytes (lowercase hex, no colons). This matches the
  operator-facing `mix relyra.metadata.pin` task and the standard
  `openssl x509 -outform DER | openssl dgst -sha256` recipe (CR-02). Hashing the
  PEM *text* (the prior behavior) could never match an operator-supplied DER
  fingerprint, so the pin either never matched (fail-closed DoS) or, once
  "fixed" to the PEM-text hash, decoupled the pin from the verified cert.

  Returns the `@uncomputable_fingerprint` sentinel for input that cannot be
  decoded to a certificate (fail-closed: junk never matches a pin).
  """
  @spec fingerprint(String.t()) :: String.t()
  def fingerprint(pem) when is_binary(pem) do
    case der_from_pem(pem) do
      {:ok, der} -> :crypto.hash(:sha256, der) |> Base.encode16(case: :lower)
      :error -> @uncomputable_fingerprint
    end
  end

  def fingerprint(_pem), do: @uncomputable_fingerprint

  # Decode the first PEM entry to its DER bytes. NEVER raises (pem_decode /
  # element access can fail on malformed input — fail closed to :error).
  defp der_from_pem(pem) do
    with [entry | _] <- :public_key.pem_decode(pem),
         der when is_binary(der) <- elem(entry, 1) do
      {:ok, der}
    else
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp normalize(fp) when is_binary(fp), do: String.downcase(fp)
end
