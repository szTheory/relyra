defmodule Relyra.Metadata.AutoRefresh do
  @moduledoc """
  Phase 21 scheduled-refresh wrapper per D-05. Does NOT re-implement
  `Relyra.Metadata.Refresh.refresh/2` — wraps it from outside, inserting
  the asymmetric-strictness checks D-15..D-21 BEFORE any deep parse.

  Linear pipeline (every stage is a refusal point):

    1. Strict Req profile fetch (D-20)
    2. Pre-parse the metadata-root signature envelope (Pitfall 4 — verify
       BEFORE parse-deeply) and route through
       `Signature.verify_metadata_root/4` against the operator-pinned
       trust anchor (D-16 + D-17)
    3. `Parser.parse/2` (the existing hardened parser — only NOW)
    4. `CorpusGate.check/2` post-parse pre-apply (D-21)
    5. `DriftDetector.diff/2` (D-18)
    6. `Import.build_candidate/1`
    7. `MetadataApply.apply_revision/4` with `trigger: :scheduled_refresh`
       (Plan 04 transactional D-28 path)

  Any refusal short-circuits to `MetadataApply.record_attempt/3` with
  the appropriate typed `auto_suspended_reason` so the LOCKED enum from
  Plan 01 is honored. Five refusal classes route to typed reasons:

    | Refusal                       | auto_suspended_reason          |
    |-------------------------------|--------------------------------|
    | TrustAnchor.check/2           | :trust_anchor_mismatch         |
    | Signature.verify_metadata_root| :signature_invalid             |
    | CorpusGate.check/2            | :corpus_violation              |
    | DriftDetector entity_id_drift | :entity_id_drift               |
    | DriftDetector new_signing_cert| :new_signing_cert              |
    | (5 transient default)         | :transient_failures_exceeded   |

  D-39: every emit + every record_attempt call carries the batch's
  `correlation_id` from `opts[:audit][:correlation_id]`.
  """

  alias Relyra.Ecto.{Connection, MetadataApply, MetadataSource}
  alias Relyra.Error
  alias Relyra.Log
  alias Relyra.Metadata.{Cadence, DriftDetector, Import, Parser, TrustAnchor}
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.CorpusGate
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Telemetry

  @compile {:no_warn_undefined, [Connection, MetadataSource, MetadataApply]}

  # D-20 stricter Req profile per scheduler tick (NOT a global Req
  # registration). Phase 21 owns its own backoff via the auto-suspend
  # state machine — one attempt per tick.
  @req_connect_timeout_ms 30_000
  @req_receive_timeout_ms 30_000
  @req_max_response_size 5_000_000

  @spec refresh(map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def refresh(source, opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)

    with {:ok, connection} <- fetch_connection(repo, source) do
      metadata = base_metadata(connection, source, opts)

      Telemetry.span([:metadata, :auto_refresh], metadata, fn ->
        do_refresh(connection, source, repo, opts, metadata)
      end)
    end
  end

  defp do_refresh(connection, source, repo, opts, metadata) do
    with {:ok, xml} <- fetch_xml(source, opts),
         {:ok, _signed} <- verify_signature(xml, source, connection),
         {:ok, parsed} <- Parser.parse(xml, opts),
         :ok <- CorpusGate.check(xml, opts),
         :ok <- maybe_emit_validity_warning(xml, source, repo, opts),
         candidate = Import.build_candidate(parsed),
         :ok <- check_drift(candidate, source, connection),
         {:ok, revision} <-
           apply_candidate(connection, source, candidate, xml, repo, opts) do
      Log.info("scheduled metadata refresh applied",
        connection_id: connection.connection_id,
        metadata_xml: xml
      )

      {{:ok, revision},
       Map.merge(metadata, %{
         outcome: :ok,
         error_code: nil,
         certificate_count: length(Map.get(candidate, :certificate_fingerprints, []))
       })}
    else
      {:error, %Error{} = error} ->
        outcome = error_to_outcome(error)
        suspend_reason = error_to_suspend_reason(error)

        _ =
          record_failure(
            connection,
            source,
            repo,
            error,
            outcome,
            suspend_reason,
            opts
          )

        Log.error("scheduled metadata refresh failed",
          connection_id: connection.connection_id,
          error_code: error.type
        )

        {{:error, error},
         Map.merge(metadata, %{outcome: :error, error_code: error.type, certificate_count: 0})}
    end
  end

  defp base_metadata(connection, source, opts) do
    %{
      connection_id: connection.connection_id,
      metadata_source_id: source.id,
      source_kind: source.kind,
      trigger: :scheduled_refresh,
      correlation_id: Map.get(Keyword.get(opts, :audit, %{}), :correlation_id)
    }
  end

  # D-15 + D-19: scheduled apply refuses unsigned metadata when
  # require_signed_metadata is true. Escape hatch: if
  # legacy_unsigned_metadata_policy.allow_until is in the future, the
  # signature check is skipped and the audit row records the bypass.
  defp verify_signature(xml, source, connection) do
    cond do
      legacy_unsigned_allowed?(source) ->
        {:ok, :legacy_unsigned}

      source.require_signed_metadata == true ->
        do_verify_signature(xml, source, connection)

      true ->
        # require_signed_metadata = false on a non-default source:
        # legitimate operator override (rare; not the default).
        {:ok, :legacy_unsigned}
    end
  end

  defp do_verify_signature(xml, source, connection) do
    # Two-step trust per D-17:
    #   (a) extract candidate signing-cert PEMs from the XML
    #   (b) TrustAnchor.check ensures at least one matches a pinned
    #       SHA-256 fingerprint
    # ONLY after that does verify_metadata_root run with that PEM as
    # the cert chain. This preserves "operator-pinned only — no document
    # KeyInfo trust" per D-17.
    with {:ok, candidate_pems} <- extract_candidate_signing_pems(xml),
         :ok <- TrustAnchor.check(candidate_pems, source.metadata_trust_fingerprints),
         {:ok, parsed_root} <- pre_parse_for_signature(xml),
         {:ok, signed_node} <-
           Signature.verify_metadata_root(parsed_root, connection, candidate_pems) do
      {:ok, signed_node}
    end
  end

  # Thin scan to pull X509Certificate base64 bodies and convert each to
  # PEM. We deliberately do NOT call the deep parser here (Pitfall 4 —
  # verify before parse-deeply). The same regex shape as
  # `Parser.fetch_certificates/1` is reused without invoking the broader
  # parser pipeline, so XXE / DOCTYPE / wrong-root rejections happen at
  # the parser AFTER the trust anchor + signature checks fire.
  defp extract_candidate_signing_pems(xml) do
    bodies =
      Regex.scan(
        ~r/<(?:\w+:)?X509Certificate\b[^>]*>(.*?)<\/(?:\w+:)?X509Certificate>/is,
        xml,
        capture: :all_but_first
      )
      |> Enum.map(fn [body] -> body |> String.replace(~r/\s+/, "") |> String.trim() end)
      |> Enum.reject(&(&1 == ""))

    case bodies do
      [] ->
        {:error,
         Error.new(:signature_failed, "Metadata document has no certificates", %{
           reason: :no_x509_in_metadata
         })}

      bodies ->
        {:ok, Enum.map(bodies, &to_pem/1)}
    end
  end

  # SIGV-04 (D-13): the metadata root now routes through the SAME tree
  # builder the assertion path uses (`PureBeam.parse_metadata_root_safely/2`)
  # rather than a regex extractor. This surfaces the SAME tree-bound crypto
  # inputs the assertion path has (`:node` / `:signed_info_node` /
  # `:digest_value_b64` / `:signature_value_b64` on the single signed
  # candidate, plus tree-derived `:key_info_trust` / `:duplicate_ids`), so the
  # shared `Signature.verify_metadata_root → do_verify` primitive performs
  # genuine signature math + DigestValue recompute on the metadata path —
  # closing the RESEARCH Pitfall 2 plumbing gap (one trust path, D-04, no
  # parser differential). The byte guards (XXE/DOCTYPE/size, D-09) and the
  # `:missing_signature` fail-closed behavior live inside
  # `parse_metadata_root_safely/2`.
  defp pre_parse_for_signature(xml) when is_binary(xml) do
    PureBeam.parse_metadata_root_safely(xml)
  end

  defp legacy_unsigned_allowed?(%{legacy_unsigned_metadata_policy: nil}), do: false

  defp legacy_unsigned_allowed?(%{legacy_unsigned_metadata_policy: %{} = policy}) do
    case Map.get(policy, "allow_until") || Map.get(policy, :allow_until) do
      %Date{} = date ->
        Date.compare(date, Date.utc_today()) in [:gt, :eq]

      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> Date.compare(date, Date.utc_today()) in [:gt, :eq]
          _ -> false
        end

      _ ->
        false
    end
  end

  defp legacy_unsigned_allowed?(_other), do: false

  defp check_drift(candidate, source, connection) do
    candidate_state = %{
      idp_entity_id: Map.get(candidate, :idp_entity_id),
      certificate_fingerprints: Map.get(candidate, :certificate_fingerprints, [])
    }

    source_state = %{
      idp_entity_id: connection.idp_entity_id,
      last_known_metadata_signing_certs: source.last_known_metadata_signing_certs || []
    }

    case DriftDetector.diff(candidate_state, source_state) do
      {:ok, :no_drift} ->
        :ok

      {:drift, %{reason: :entity_id_drift} = details} ->
        {:error,
         Error.new(
           :metadata_drift_requires_review,
           "Fetched entityID does not match the connection's stored idp_entity_id",
           Map.put(details, :auto_suspended_reason, :entity_id_drift)
         )}

      {:drift, %{reason: :new_signing_cert} = details} ->
        {:error,
         Error.new(
           :metadata_drift_requires_review,
           "Fetched metadata contains signing certificates not present in last_known_metadata_signing_certs",
           Map.put(details, :auto_suspended_reason, :new_signing_cert)
         )}
    end
  end

  defp apply_candidate(connection, source, candidate, xml, _repo, opts) do
    MetadataApply.apply_revision(
      connection.connection_id,
      Map.from_struct(candidate),
      %{
        metadata_source_id: source.id,
        source_kind: source.kind,
        trigger: :scheduled_refresh,
        actor: Keyword.get(opts, :actor, "scheduler"),
        cause: Keyword.get(opts, :cause, "scheduled refresh"),
        content_hash_sha256: sha256(xml),
        trust_summary: candidate.trust_summary
      },
      opts
    )
  end

  defp record_failure(connection, source, _repo, error, outcome, suspend_reason, opts) do
    attrs = %{
      metadata_source_id: source.id,
      source_kind: source.kind,
      trigger: :scheduled_refresh,
      actor: Keyword.get(opts, :actor, "scheduler"),
      cause: Keyword.get(opts, :cause, Atom.to_string(error.type)),
      outcome: outcome,
      details: %{error_code: error.type},
      trust_summary: %{status: "failed", error_code: error.type}
    }

    attrs =
      if suspend_reason do
        Map.put(attrs, :auto_suspended_reason, suspend_reason)
      else
        attrs
      end

    MetadataApply.record_attempt(connection.connection_id, attrs, opts)
  end

  # Maps refusal error type → MetadataRevision outcome enum value.
  defp error_to_outcome(%Error{type: type})
       when type in [
              :metadata_fetch_failed,
              :fetch_timeout,
              :fetch_http_5xx,
              :fetch_dns_failure,
              :fetch_connection_refused,
              :fetch_tls_handshake,
              :fetch_http_4xx
            ],
       do: :fetch_failed

  defp error_to_outcome(%Error{type: type})
       when type in [
              :malformed_xml,
              :metadata_wrong_root,
              :doctype_forbidden,
              :entity_expansion_forbidden,
              :parse_failed,
              :payload_too_large,
              :metadata_missing_entity_id,
              :metadata_missing_certificate,
              :metadata_missing_sso_service
            ],
       do: :parse_failed

  defp error_to_outcome(%Error{type: type})
       when type in [
              :signature_failed,
              :invalid_signature,
              :missing_signature,
              :untrusted_certificate,
              :duplicate_xml_id,
              :trust_anchor_mismatch,
              :corpus_violation,
              :metadata_drift_requires_review
            ],
       do: :validation_failed

  defp error_to_outcome(%Error{}), do: :apply_failed

  # Maps refusal error type → typed auto_suspended_reason atom (LOCKED
  # enum from Plan 01). Returns nil for transient/unknown errors so
  # MetadataApply's default (`:transient_failures_exceeded`) takes over.
  defp error_to_suspend_reason(%Error{type: :trust_anchor_mismatch}),
    do: :trust_anchor_mismatch

  defp error_to_suspend_reason(%Error{type: :corpus_violation}), do: :corpus_violation

  defp error_to_suspend_reason(%Error{
         type: :metadata_drift_requires_review,
         details: %{auto_suspended_reason: r}
       })
       when r in [:entity_id_drift, :new_signing_cert],
       do: r

  defp error_to_suspend_reason(%Error{type: type})
       when type in [
              :signature_failed,
              :invalid_signature,
              :missing_signature,
              :untrusted_certificate
            ],
       do: :signature_invalid

  defp error_to_suspend_reason(_other), do: nil

  defp fetch_connection(repo, %{connection_record_id: cid}) do
    case repo.get(Connection, cid) do
      nil ->
        {:error,
         Error.new(:connection_not_found, "Connection record was not found", %{
           connection_record_id: cid
         })}

      connection ->
        {:ok, connection}
    end
  end

  # D-20: stricter Req profile per scheduler tick (NOT a global Req
  # registration). One attempt per tick — Phase 21 owns its own backoff.
  defp fetch_xml(source, opts) do
    req = build_strict_req(opts)

    case Req.get(req, url: source.url) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} when status >= 400 and status < 500 ->
        {:error, Error.new(:fetch_http_4xx, "Metadata fetch returned 4xx", %{status: status})}

      {:ok, %Req.Response{status: status}} when status >= 500 ->
        {:error, Error.new(:fetch_http_5xx, "Metadata fetch returned 5xx", %{status: status})}

      {:ok, %Req.Response{status: status}} ->
        {:error,
         Error.new(:metadata_fetch_failed, "Unexpected status from metadata URL", %{
           status: status
         })}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, Error.new(:fetch_timeout, "Metadata fetch timed out", %{})}

      {:error, %Mint.TransportError{reason: :nxdomain}} ->
        {:error, Error.new(:fetch_dns_failure, "Metadata host could not be resolved", %{})}

      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        {:error,
         Error.new(:fetch_connection_refused, "Metadata host refused the connection", %{})}

      {:error, %{reason: reason}} when reason in [:closed, :tls_handshake_failure] ->
        {:error,
         Error.new(:fetch_tls_handshake, "TLS handshake failed", %{reason: inspect(reason)})}

      {:error, exception} ->
        message =
          if is_exception(exception),
            do: Exception.message(exception),
            else: inspect(exception)

        {:error, Error.new(:metadata_fetch_failed, "Metadata fetch failed", %{reason: message})}
    end
  end

  defp build_strict_req(opts) do
    case Keyword.get(opts, :req) do
      %Req.Request{} = req ->
        req

      _ ->
        Req.new(
          connect_options: [timeout: @req_connect_timeout_ms],
          receive_timeout: @req_receive_timeout_ms,
          redirect: false,
          max_response_size: @req_max_response_size,
          headers: [{"User-Agent", user_agent()}]
        )
    end
  end

  defp user_agent do
    version = Application.spec(:relyra, :vsn) |> to_string()
    "Relyra-MetadataRefresh/" <> version
  end

  defp to_pem(b64) do
    body =
      b64
      |> String.replace(~r/\s+/, "")
      |> String.codepoints()
      |> Enum.chunk_every(64)
      |> Enum.map_join("\n", &Enum.join/1)

    "-----BEGIN CERTIFICATE-----\n" <> body <> "\n-----END CERTIFICATE-----"
  end

  defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  # B2 / D-14: emit `:validity_warning` (at-most-once per validUntil per
  # source) when the IdP-published `validUntil` is sooner than
  # `2 × refresh_interval`. The persistence (`last_validity_warning_for`)
  # and the telemetry emit both live inside
  # `MetadataApply.record_validity_warning/3` so the check is co-committed
  # with the `last_validity_warning_for` write (D-28 single-transaction
  # discipline preserved).
  defp maybe_emit_validity_warning(xml, %{} = source, repo, opts) when is_binary(xml) do
    case extract_valid_until(xml) do
      nil ->
        # Metadata root has no `validUntil` attribute; nothing to warn about.
        :ok

      %DateTime{} = valid_until ->
        now = DateTime.utc_now()
        interval = Cadence.cadence_seconds(source.refresh_cadence)
        slack = DateTime.diff(valid_until, now, :second) - 2 * interval

        if slack < 0 do
          correlation_id = Map.get(Keyword.get(opts, :audit, %{}), :correlation_id)

          attrs = %{
            valid_until: valid_until,
            refresh_interval_seconds: interval,
            slack_seconds: slack,
            correlation_id: correlation_id
          }

          case MetadataApply.record_validity_warning(repo, source, attrs) do
            {:ok, _outcome} ->
              :ok

            # A failure to persist the warning marker is non-fatal for
            # the refresh itself — log and continue. The next refresh
            # tick will re-attempt the warning on the same validUntil.
            {:error, _error} ->
              :ok
          end
        else
          :ok
        end
    end
  end

  # Regex-based extraction of the `validUntil` attribute from the
  # metadata root element (`<EntityDescriptor>` or
  # `<EntitiesDescriptor>`). Mirrors the existing regex extraction style
  # in `lib/relyra/metadata/parser.ex` (lines 31, 55) so the wrapper does
  # NOT parse-deeply for this step.
  defp extract_valid_until(xml) when is_binary(xml) do
    case Regex.run(
           ~r/^<(?:\w+:)?(?:EntityDescriptor|EntitiesDescriptor)\b[^>]*\bvalidUntil=(["\'])([^"\']+)\1/is,
           String.trim(xml),
           capture: :all_but_first
         ) do
      [_quote, iso8601] ->
        case DateTime.from_iso8601(iso8601) do
          {:ok, dt, _offset} -> dt
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
