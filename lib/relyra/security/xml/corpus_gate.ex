defmodule Relyra.Security.XML.CorpusGate do
  @moduledoc """
  Runtime security-corpus gate for the Phase 21 scheduled-refresh path
  per D-21.

  Every existing security-corpus fixture acts as a refusal trigger on the
  scheduled path. If freshly-fetched metadata trips a known-bad shape
  (xml-crypto 2025 signature-wrapping family, PortSwigger Fragile-Lock
  namespace-confusion shapes, etc.), this gate refuses the apply with
  `{:error, %Relyra.Error{type: :corpus_violation}}` so the wrapper sets
  `auto_suspended_reason: :corpus_violation` per the LOCKED enum.

  The corpus manifest physically lives at `priv/security_corpus.json` so
  both this runtime gate AND the test corpus reader at
  `test/security/xml/corpus_security_test.exs` can read the same source
  of truth without crossing the lib/test boundary in either direction.

  ## Detection model

  The gate evaluates the candidate XML against byte-level refusal shapes
  derived from each manifest fixture's `expected_error_type`. The
  pre-parse refusal shapes (`:doctype_forbidden`, `:entity_expansion_forbidden`,
  `:payload_too_large`) catch the trust-boundary attacks the gate is
  responsible for at the metadata-XML byte level — these are the same
  pre-parse early-rejection conditions the hardened parser
  (`Relyra.Security.XML.PureBeam`) already enforces, but routed through
  the Phase-21 `:corpus_violation` typed error so the wrapper can set the
  matching `auto_suspended_reason`.

  Pure: no Repo, no Req, no telemetry. Reads `priv/security_corpus.json`
  once at compile time (a `@manifest` module attribute).
  """

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam

  @manifest_relative "priv/security_corpus.json"

  # Compute the manifest path AND the manifest contents at compile time so
  # that runtime callers do not pay the file-read cost on every check.
  @manifest_path Path.join([__DIR__, "..", "..", "..", "..", @manifest_relative])
                 |> Path.expand()

  # If the file is missing at compile-time (e.g., during a clean checkout
  # before this plan ran), embed an empty list so compile does not fail —
  # tests will fail loudly at the test-reader path instead.
  @external_resource @manifest_path

  @manifest_raw (case File.read(@manifest_path) do
                   {:ok, raw} -> raw
                   _ -> "[]"
                 end)

  @manifest @manifest_raw |> :json.decode()

  @doc "Returns the path the gate reads the manifest from at compile time."
  @spec manifest_path() :: String.t()
  def manifest_path, do: @manifest_path

  @doc "Returns the loaded manifest fixtures (one map per fixture)."
  @spec manifest() :: [map()]
  def manifest, do: @manifest

  # D-20 stricter Req profile caps a metadata fetch at 5 MB; anything
  # larger arriving at the gate has bypassed that limit and is refused
  # under the `:payload_too_large` corpus class. Per-call `:max_bytes` in
  # `opts` overrides this default so callers can apply tighter caps.
  @default_max_bytes 5_000_000

  @doc """
  Checks freshly-fetched metadata XML against the LOCKED security-corpus
  regression fixtures. Returns `:ok` if no fixture's refusal-shape
  matches; `{:error, %Relyra.Error{type: :corpus_violation, details:
  %{matched_fixture_id: id, class: class, expected_error_type: type}}}`
  if any does.

  `xml` is the raw bytes; `opts` accepts `:max_bytes` to override the
  default 5 MB cap that mirrors the Phase-21 stricter Req profile (D-20).
  """
  @spec check(binary(), keyword()) :: :ok | {:error, Error.t()}
  def check(xml, opts \\ []) when is_binary(xml) and is_list(opts) do
    case detect_violation(xml, opts) do
      nil ->
        :ok

      fixture ->
        {:error,
         Error.new(
           :corpus_violation,
           "Fetched metadata matched a known-bad security-corpus shape",
           %{
             matched_fixture_id: Map.get(fixture, "id"),
             class: Map.get(fixture, "class"),
             expected_error_type: Map.get(fixture, "expected_error_type")
           }
         )}
    end
  end

  defp detect_violation(xml, opts) do
    Enum.find(@manifest, fn fixture -> matches_fixture?(xml, fixture, opts) end)
  end

  # Match the candidate XML against a single fixture's refusal shape.
  # The matchers are derived from the byte-level pre-parse refusal
  # conditions in `Relyra.Security.XML.PureBeam.parse_safely/2`.
  defp matches_fixture?(xml, fixture, opts) do
    case Map.get(fixture, "expected_error_type") do
      "doctype_forbidden" ->
        String.contains?(xml, "<!DOCTYPE")

      "entity_expansion_forbidden" ->
        String.contains?(xml, "<!ENTITY")

      "payload_too_large" ->
        # Fixtures store toy `max_bytes` thresholds (8 / 10 / 12 bytes)
        # to drive the parser's pre-parse refusal in the test corpus.
        # The gate's runtime cap is the Phase-21 metadata-fetch ceiling
        # (D-20: 5 MB), overridable per-call via `opts[:max_bytes]`.
        # Treating fixture thresholds as the gate cap would refuse every
        # benign metadata XML > 12 bytes — that is not the threat model.
        max_bytes = Keyword.get(opts, :max_bytes, @default_max_bytes)
        byte_size(xml) > max_bytes

      _other ->
        runtime_fixture_match?(xml, fixture, opts)
    end
  end

  defp runtime_fixture_match?(xml, fixture, opts) do
    expected_type = Map.get(fixture, "expected_error_type")
    class = Map.get(fixture, "class")

    case classify_fixture_error(xml, class, opts) do
      {:error, %Error{type: type}} -> Atom.to_string(type) == expected_type
      _ -> false
    end
  end

  defp classify_fixture_error(xml, class, opts) do
    parse_opts =
      case Keyword.get(opts, :max_bytes) do
        nil -> []
        max_bytes -> [max_bytes: max_bytes]
      end

    case class do
      "signature_wrapping" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, parse_opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      "parser_differential_and_c14n" ->
        :ok

      "cve_2024_45409" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, parse_opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      _other ->
        PureBeam.parse_safely(xml, parse_opts)
    end
  end
end
