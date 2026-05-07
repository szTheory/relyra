---
phase: 21
plan: 03
type: execute
wave: 1
depends_on: [21-01]
files_modified:
  - lib/relyra/metadata/trust_anchor.ex
  - lib/relyra/metadata/drift_detector.ex
  - lib/relyra/security/xml/corpus_gate.ex
  - priv/security_corpus.json
  - test/relyra/metadata/trust_anchor_test.exs
  - test/relyra/metadata/drift_detector_test.exs
  - test/relyra/security/xml/corpus_gate_test.exs
  - test/security/xml/corpus_security_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Trust anchor helper accepts only operator-pinned SHA-256 fingerprints (D-17 — no TOFU, no reuse-of-assertion-cert)"
    - "Drift detector compares MapSets of fingerprints, never PEM strings, so whitespace reformat does not produce false-positive drift (RESEARCH Pitfall 7)"
    - "Security-corpus runtime gate refuses every existing test fixture on the scheduled path (D-21)"
    - "The security corpus manifest moves from test/fixtures to priv/ so lib/ code can call it without crossing the test boundary; the existing test corpus reader continues to work against the new path"
    - "All three new modules are pure: no Repo, no telemetry, no Req"
  artifacts:
    - path: "lib/relyra/metadata/trust_anchor.ex"
      provides: "Operator-pinned fingerprint check (D-17): accepts a candidate cert PEM list + the source's pinned fingerprints; returns :ok | {:error, %Relyra.Error{type: :trust_anchor_mismatch}}"
      exports: ["check/2"]
    - path: "lib/relyra/metadata/drift_detector.ex"
      provides: "entityID + signing-cert fingerprint diff (D-18)"
      exports: ["diff/2"]
    - path: "lib/relyra/security/xml/corpus_gate.ex"
      provides: "Runtime corpus gate (D-21) returning :ok | {:error, %Relyra.Error{type: :corpus_violation}}"
      exports: ["check/2"]
    - path: "priv/security_corpus.json"
      provides: "Canonical security-corpus manifest readable from both lib/ runtime and test/ paths"
      contains: "expected_error_type"
  key_links:
    - from: "lib/relyra/metadata/trust_anchor.ex"
      to: "lib/relyra/metadata/import.ex sha256/1 (line 125-126)"
      via: "Reuse `:crypto.hash(:sha256, pem) |> Base.encode16(case: :lower)` — never re-implement (D-37 / Don't Hand-Roll row 5)"
      pattern: ":crypto.hash(:sha256"
    - from: "lib/relyra/metadata/drift_detector.ex"
      to: "MapSet.difference of fingerprint strings only"
      via: "Never compare PEMs (whitespace re-fires drift; Pitfall 7)"
      pattern: "MapSet.difference"
    - from: "lib/relyra/security/xml/corpus_gate.ex"
      to: "priv/security_corpus.json"
      via: "Application.app_dir(:relyra, \"priv/security_corpus.json\") at module load"
      pattern: "Application.app_dir"
---

<objective>
Land the three security-boundary helpers Phase 21's `AutoRefresh` wrapper will call between fetch and apply: trust-anchor fingerprint check (D-17), drift detector (D-18), and runtime security-corpus gate (D-21). Move the security corpus manifest from `test/fixtures/security/xml/manifest.json` to `priv/security_corpus.json` so `lib/` code can call it without crossing the test boundary, while keeping the existing `test/security/xml/corpus_security_test.exs` reader pointed at the new path so test coverage is preserved (RESEARCH Q3 recommendation: extract).

Purpose: Phase 21's asymmetric strictness (D-15..D-21) requires the scheduled path to refuse any metadata that fails fingerprint pinning, drift detection, or the corpus regression set BEFORE handing off to `MetadataApply`. These three modules encapsulate the three distinct refusal reasons, each producing one of the typed `auto_suspended_reason` atoms locked in Plan 01's enum (`:trust_anchor_mismatch`, `:entity_id_drift` / `:new_signing_cert`, `:corpus_violation`).

Output: Three new pure helper modules, the relocated security corpus manifest, updated test corpus reader pointed at the new path, and replacement tests for the three Wave 0 stubs from Plan 01.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/error.ex
@lib/relyra/metadata/import.ex
@test/security/xml/corpus_security_test.exs

<interfaces>
Existing SHA-256 fingerprint compute (`lib/relyra/metadata/import.ex:125-126`) — reuse, do NOT re-implement:

```elixir
defp sha256(value) do
  :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
```

`Relyra.Error.new/3` shape (`lib/relyra/error.ex:15-17`):

```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

Existing security corpus manifest (`test/fixtures/security/xml/manifest.json`) — current shape, per `test/security/xml/corpus_security_test.exs:62-66`:

```json
[
  {"id": "...", "class": "signature_wrapping|keyinfo_misuse|unsigned_or_partial_signature|parser_differential_and_c14n|...", "expected_error_type": "...", "xml": "...", ...},
  ...
]
```

Existing test reader at `test/security/xml/corpus_security_test.exs:7,62-66`:

```elixir
@manifest_path "test/fixtures/security/xml/manifest.json"
defp manifest do
  @manifest_path
  |> File.read!()
  |> :json.decode()
end
```

After this plan, the manifest physically lives at `priv/security_corpus.json`. The test reader updates `@manifest_path` to that new path so coverage continues. The runtime gate (`Relyra.Security.XML.CorpusGate`) reads the same file via `Application.app_dir(:relyra, "priv/security_corpus.json")`.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create TrustAnchor + DriftDetector pure helpers and their tests</name>
  <files>lib/relyra/metadata/trust_anchor.ex, lib/relyra/metadata/drift_detector.ex, test/relyra/metadata/trust_anchor_test.exs, test/relyra/metadata/drift_detector_test.exs</files>
  <read_first>
    - lib/relyra/metadata/import.ex (lines 85-94, 125-126: existing fingerprint compute — reuse via the documented SHA-256 + lowercase-hex shape)
    - lib/relyra/error.ex (the typed error shape every helper returns on failure)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pitfall 7" (NEVER compare PEMs — whitespace reformat re-fires drift)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/metadata/drift_detector.ex" section
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-17 trust anchor: operator-pinned only, reject TOFU, reject reuse-of-assertion-cert; D-18 drift: entityID compare + new-signing-cert detection)
    - test/relyra/metadata/trust_anchor_test.exs and test/relyra/metadata/drift_detector_test.exs (Wave 0 stubs — replace bodies)
  </read_first>
  <action>
    Create `lib/relyra/metadata/trust_anchor.ex`:

    ```elixir
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
    ```

    Create `lib/relyra/metadata/drift_detector.ex`:

    ```elixir
    defmodule Relyra.Metadata.DriftDetector do
      @moduledoc """
      Drift detection for Phase 21 scheduled metadata refresh per D-18.

      A "drift" is either:
        - the freshly-fetched `entityID` does not match the persisted
          `idp_entity_id` on the connection (`:entity_id_drift`), or
        - the freshly-fetched signing-cert fingerprint set contains an
          element NOT in the persisted `last_known_metadata_signing_certs`
          MapSet (`:new_signing_cert`).

      On drift, the wrapper auto-suspends the source and refuses to apply
      this revision. Per D-32, the new cert still stages as `:next` via the
      existing certificate-inventory path — drift detection ONLY pauses the
      scheduled apply pending operator review (Phase 10/12 D-08 unchanged).

      Why fingerprints, not PEMs: comparing PEM strings is whitespace-sensitive
      (RESEARCH Pitfall 7). A metadata reformat that re-emits the same cert
      with different line wrapping would re-fire `:new_signing_cert`. Compare
      MapSets of SHA-256 fingerprints only.

      Pure: no I/O, no Ecto. Caller passes already-fingerprint-extracted lists.
      """

      @type drift_result ::
              {:ok, :no_drift}
              | {:drift,
                 %{
                   entity_id_changed?: boolean(),
                   new_signing_certs: [String.t()],
                   reason: :entity_id_drift | :new_signing_cert
                 }}

      @doc """
      Compares a freshly-parsed metadata `candidate` against the stored
      connection + source state.

      `candidate`:
        - `:idp_entity_id` (string)
        - `:certificate_fingerprints` (list of SHA-256 hex strings)

      `source_state`:
        - `:idp_entity_id` (string — from the `Connection`, not the source row)
        - `:last_known_metadata_signing_certs` (list of SHA-256 hex strings — from `MetadataSource`)

      Returns `{:ok, :no_drift}` or `{:drift, %{reason: ...}}`.
      """
      @spec diff(map(), map()) :: drift_result()
      def diff(%{} = candidate, %{} = source_state) do
        candidate_fps = MapSet.new(Map.get(candidate, :certificate_fingerprints, []))
        known_fps = MapSet.new(Map.get(source_state, :last_known_metadata_signing_certs, []))
        new_fps = MapSet.difference(candidate_fps, known_fps)

        candidate_entity_id = Map.get(candidate, :idp_entity_id)
        stored_entity_id = Map.get(source_state, :idp_entity_id)

        entity_id_changed? = entity_id_drift?(stored_entity_id, candidate_entity_id)

        cond do
          entity_id_changed? ->
            {:drift,
             %{
               entity_id_changed?: true,
               new_signing_certs: MapSet.to_list(new_fps),
               reason: :entity_id_drift
             }}

          MapSet.size(known_fps) > 0 and MapSet.size(new_fps) > 0 ->
            # A `:new_signing_cert` is only a drift when there IS prior known
            # state to compare against. The first-ever fetch (known_fps empty)
            # is initialization, not drift.
            {:drift,
             %{
               entity_id_changed?: false,
               new_signing_certs: MapSet.to_list(new_fps),
               reason: :new_signing_cert
             }}

          true ->
            {:ok, :no_drift}
        end
      end

      defp entity_id_drift?(nil, _candidate), do: false
      defp entity_id_drift?(_stored, nil), do: false
      defp entity_id_drift?(stored, candidate), do: stored != candidate
    end
    ```

    Tests for `test/relyra/metadata/trust_anchor_test.exs` (replace Wave 0 stub):

    ```elixir
    defmodule Relyra.Metadata.TrustAnchorTest do
      use ExUnit.Case, async: true
      alias Relyra.Error
      alias Relyra.Metadata.TrustAnchor

      @pem_a "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----"
      @pem_b "-----BEGIN CERTIFICATE-----\nBBBB\n-----END CERTIFICATE-----"
      @pem_c "-----BEGIN CERTIFICATE-----\nCCCC\n-----END CERTIFICATE-----"

      describe "fingerprint/1" do
        test "produces a 64-char lowercase hex SHA-256 (no colons)" do
          fp = TrustAnchor.fingerprint(@pem_a)
          assert String.length(fp) == 64
          assert fp == String.downcase(fp)
          refute String.contains?(fp, ":")
        end
      end

      describe "check/2" do
        test "returns :ok when at least one candidate PEM matches a pinned fingerprint" do
          pinned = [TrustAnchor.fingerprint(@pem_a), TrustAnchor.fingerprint(@pem_b)]
          assert :ok = TrustAnchor.check([@pem_a, @pem_c], pinned)
        end

        test "supports multi-valued pinned fingerprints (rotation — D-17)" do
          # Pinning two fingerprints during a rotation window
          pinned = [TrustAnchor.fingerprint(@pem_a), TrustAnchor.fingerprint(@pem_b)]
          assert :ok = TrustAnchor.check([@pem_b], pinned)
        end

        test "rejects with :trust_anchor_mismatch when no candidate matches" do
          pinned = [TrustAnchor.fingerprint(@pem_a)]
          assert {:error, %Error{type: :trust_anchor_mismatch} = err} =
                   TrustAnchor.check([@pem_b, @pem_c], pinned)
          assert err.details.reason == :no_match
        end

        test "rejects with :no_pinned_fingerprints when pinned list is empty (defense-in-depth — schema gate from Plan 01 should prevent this)" do
          assert {:error, %Error{type: :trust_anchor_mismatch} = err} =
                   TrustAnchor.check([@pem_a], [])
          assert err.details.reason == :no_pinned_fingerprints
        end

        test "case-normalizes pinned fingerprints (handles operator pasting uppercase from openssl output)" do
          pinned = [String.upcase(TrustAnchor.fingerprint(@pem_a))]
          assert :ok = TrustAnchor.check([@pem_a], pinned)
        end
      end
    end
    ```

    Tests for `test/relyra/metadata/drift_detector_test.exs` (replace Wave 0 stub):

    ```elixir
    defmodule Relyra.Metadata.DriftDetectorTest do
      use ExUnit.Case, async: true
      alias Relyra.Metadata.DriftDetector

      describe "diff/2 — no drift" do
        test "returns {:ok, :no_drift} when entityID and fingerprint set match exactly" do
          candidate = %{idp_entity_id: "https://idp.example/", certificate_fingerprints: ["aaa", "bbb"]}
          state = %{idp_entity_id: "https://idp.example/", last_known_metadata_signing_certs: ["aaa", "bbb"]}
          assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
        end

        test "returns {:ok, :no_drift} when candidate fingerprints are a SUBSET of known (cert was retired upstream — not drift)" do
          candidate = %{idp_entity_id: "https://idp.example/", certificate_fingerprints: ["aaa"]}
          state = %{idp_entity_id: "https://idp.example/", last_known_metadata_signing_certs: ["aaa", "bbb"]}
          assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
        end

        test "returns {:ok, :no_drift} on first-ever fetch (known set empty — initialization, not drift)" do
          candidate = %{idp_entity_id: "https://idp.example/", certificate_fingerprints: ["aaa"]}
          state = %{idp_entity_id: "https://idp.example/", last_known_metadata_signing_certs: []}
          assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
        end
      end

      describe "diff/2 — entity_id drift" do
        test "returns {:drift, reason: :entity_id_drift} when entityID changes" do
          candidate = %{idp_entity_id: "https://NEW.example/", certificate_fingerprints: ["aaa"]}
          state = %{idp_entity_id: "https://OLD.example/", last_known_metadata_signing_certs: ["aaa"]}
          assert {:drift, %{reason: :entity_id_drift, entity_id_changed?: true}} =
                   DriftDetector.diff(candidate, state)
        end

        test "entity_id_drift takes precedence over new_signing_cert" do
          candidate = %{idp_entity_id: "https://NEW.example/", certificate_fingerprints: ["zzz"]}
          state = %{idp_entity_id: "https://OLD.example/", last_known_metadata_signing_certs: ["aaa"]}
          assert {:drift, %{reason: :entity_id_drift, new_signing_certs: ["zzz"]}} =
                   DriftDetector.diff(candidate, state)
        end
      end

      describe "diff/2 — new signing cert" do
        test "returns {:drift, reason: :new_signing_cert} when fingerprint set adds a NEW entry" do
          candidate = %{idp_entity_id: "https://idp.example/", certificate_fingerprints: ["aaa", "bbb", "ccc"]}
          state = %{idp_entity_id: "https://idp.example/", last_known_metadata_signing_certs: ["aaa", "bbb"]}
          assert {:drift, %{reason: :new_signing_cert, new_signing_certs: new}} =
                   DriftDetector.diff(candidate, state)
          assert "ccc" in new
        end
      end

      describe "diff/2 — fingerprint-only comparison (Pitfall 7)" do
        test "is order-insensitive (uses MapSet semantics)" do
          candidate = %{idp_entity_id: "https://idp/", certificate_fingerprints: ["bbb", "aaa"]}
          state = %{idp_entity_id: "https://idp/", last_known_metadata_signing_certs: ["aaa", "bbb"]}
          assert {:ok, :no_drift} = DriftDetector.diff(candidate, state)
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/metadata/trust_anchor_test.exs test/relyra/metadata/drift_detector_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/relyra/metadata/trust_anchor.ex` exists with `defmodule Relyra.Metadata.TrustAnchor`.
    - `grep -c "def check(" lib/relyra/metadata/trust_anchor.ex` returns at least `1`.
    - `grep -c ":crypto.hash(:sha256" lib/relyra/metadata/trust_anchor.ex` returns at least `1` (reuses canonical fingerprint compute).
    - `grep -c "trust_anchor_mismatch" lib/relyra/metadata/trust_anchor.ex` returns at least `1` (typed error code).
    - File `lib/relyra/metadata/drift_detector.ex` exists with `defmodule Relyra.Metadata.DriftDetector`.
    - `grep -c "def diff(" lib/relyra/metadata/drift_detector.ex` returns at least `1`.
    - `grep -c "MapSet.difference\\|MapSet.disjoint?" lib/relyra/metadata/drift_detector.ex` returns at least `1` (fingerprint MapSet diff, never PEM compare).
    - `grep -cE "(entity_id_drift|new_signing_cert)" lib/relyra/metadata/drift_detector.ex` returns at least `2`.
    - Neither file imports `Ecto`, `Repo`, `Req`, `Logger`, or `Telemetry`: `grep -cE "alias Relyra\\.(Ecto|Telemetry)|require Logger|use Ecto" lib/relyra/metadata/trust_anchor.ex lib/relyra/metadata/drift_detector.ex` returns `0`.
    - `mix test test/relyra/metadata/trust_anchor_test.exs test/relyra/metadata/drift_detector_test.exs --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>Both helpers exist, return typed `Relyra.Error` structs on rejection (`:trust_anchor_mismatch`, `:entity_id_drift`, `:new_signing_cert`), enforce the locked-rejection semantics (no TOFU; PEM-compare-forbidden), and have ≥ 13 tests covering match / multi-valued pin / rotation / case-normalization / first-fetch / drift-precedence / order-insensitivity.</done>
</task>

<task type="auto">
  <name>Task 2: Move security corpus manifest to priv/ and create the runtime CorpusGate</name>
  <files>priv/security_corpus.json, lib/relyra/security/xml/corpus_gate.ex, test/relyra/security/xml/corpus_gate_test.exs, test/security/xml/corpus_security_test.exs</files>
  <read_first>
    - test/security/xml/corpus_security_test.exs (the existing test reader — lines 1-15, 62-66; the manifest path constant moves to priv)
    - test/fixtures/security/xml/manifest.json (the source manifest — note its current shape: a JSON array of fixture maps with `id`, `class`, `expected_error_type`, `xml`)
    - lib/relyra/security/xml.ex (the existing XML behaviour module — analog for the gate's typed-error shape)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Open Questions" Q3 + "Pattern: Security-corpus runtime gate" + Pitfall 4
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-21: corpus gate is post-parse pre-apply on the scheduled path; refusal sets `auto_suspended_reason: :corpus_violation`)
    - test/relyra/security/xml/corpus_gate_test.exs (Wave 0 stub from Plan 01 — replace body)
  </read_first>
  <action>
    Step 1 — Move the manifest. `cp test/fixtures/security/xml/manifest.json priv/security_corpus.json`. DO NOT delete the test/fixtures version yet; some test fixtures in `test/fixtures/security/xml/{signature_wrapping,keyinfo_misuse,...}/` may still be referenced by relative path inside the manifest. Verify the manifest's xml-fixture references work from both locations: if the manifest contains relative path references like `"xml": "<...>"` (inline XML, no file refs), then `priv/` works fine. If the manifest contains `"xml_path": "..."` references that are relative paths to `test/fixtures/security/xml/...`, leave the test/fixtures hierarchy intact and rely on the manifest carrying inline XML strings only.

    Inspect the manifest first by reading the first 50 lines of `test/fixtures/security/xml/manifest.json` (already in `read_first`) and confirm it carries inline XML. If it carries file path references, the gate must resolve them via `Application.app_dir(:relyra, "priv/security_corpus.json")`'s parent directory; the manifest needs to be relocated as a directory tree, not a single file. The simpler shape (inline XML) is the recommended path.

    Step 2 — Create `lib/relyra/security/xml/corpus_gate.ex`:

    ```elixir
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

      Pure: no Repo, no Req, no telemetry. Reads `priv/security_corpus.json`
      once at module load (a `@manifest` module attribute).
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

      @doc """
      Checks freshly-fetched metadata XML against the LOCKED security-corpus
      regression fixtures. Returns `:ok` if no fixture's expected-failure
      signature matches; `{:error, %Relyra.Error{type: :corpus_violation}}`
      with `details: %{matched_fixture_id: id, class: class}` if it does.

      `xml` is the raw bytes; `opts` is forwarded to `PureBeam.parse_safely/2`
      so size limits and other parser settings are caller-controlled.
      """
      @spec check(binary(), keyword()) :: :ok | {:error, Error.t()}
      def check(xml, opts \\ []) when is_binary(xml) do
        # The gate reuses `PureBeam.parse_safely/2` (the same hardened parser
        # the test corpus uses) and walks every fixture's expected-error type.
        # If the fetched XML produces an error that matches a fixture's
        # expected error AND that fixture's class is in the refusal-trigger
        # set, refuse.
        case PureBeam.parse_safely(xml, opts) do
          {:error, %Error{type: type} = error} ->
            case match_against_corpus(type) do
              nil -> {:error, error}
              fixture ->
                {:error,
                 Error.new(
                   :corpus_violation,
                   "Fetched metadata matched a known-bad security-corpus shape",
                   %{
                     matched_fixture_id: Map.get(fixture, "id"),
                     class: Map.get(fixture, "class"),
                     parser_error_type: type
                   }
                 )}
            end

          {:ok, _parsed} ->
            :ok
        end
      end

      defp match_against_corpus(error_type) do
        Enum.find(@manifest, fn fixture ->
          expected = Map.get(fixture, "expected_error_type")
          expected != nil and String.to_atom(expected) == error_type
        end)
      end
    end
    ```

    Step 3 — Update the existing test corpus reader (`test/security/xml/corpus_security_test.exs`) to read from the new path. ONLY change the `@manifest_path` line:

    BEFORE:
    ```elixir
    @manifest_path "test/fixtures/security/xml/manifest.json"
    ```

    AFTER:
    ```elixir
    @manifest_path "priv/security_corpus.json"
    ```

    Do not change anything else in this file — its three test functions remain in place and continue to gate `parser_differential_and_c14n` regressions.

    Step 4 — Replace the Wave 0 stub at `test/relyra/security/xml/corpus_gate_test.exs`:

    ```elixir
    defmodule Relyra.Security.XML.CorpusGateTest do
      use ExUnit.Case, async: true
      alias Relyra.Error
      alias Relyra.Security.XML.CorpusGate

      describe "manifest/0 + manifest_path/0" do
        test "loads the priv/security_corpus.json manifest at compile time" do
          assert is_list(CorpusGate.manifest())
          assert String.ends_with?(CorpusGate.manifest_path(), "priv/security_corpus.json")
        end

        test "the manifest contains at least one fixture (proves the move from test/fixtures succeeded)" do
          # The test corpus is non-trivial; if this is empty, the move broke.
          assert length(CorpusGate.manifest()) > 0
        end
      end

      describe "check/2 against well-formed minimal XML" do
        test "returns :ok for a benign XML payload that does not trip any corpus fixture" do
          # A minimal benign EntityDescriptor (no signature wrapping, no namespace confusion)
          xml = ~s(<?xml version="1.0"?><EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://example.com"></EntityDescriptor>)
          # The hardened parser may reject this for OTHER reasons (missing required children),
          # which is fine — the gate either returns :ok OR returns the parser's own error.
          # A :corpus_violation MUST NOT fire for a benign sample.
          case CorpusGate.check(xml) do
            :ok -> :ok
            {:error, %Error{type: type}} -> refute type == :corpus_violation
          end
        end
      end

      describe "check/2 against fixture-known-bad XML" do
        @tag :security_corpus
        test "returns {:error, :corpus_violation} for at least one corpus fixture (canary)" do
          # Pick the first fixture that carries inline XML and verify the gate refuses it.
          fixture =
            Enum.find(CorpusGate.manifest(), fn f ->
              is_binary(Map.get(f, "xml")) and Map.get(f, "xml") != ""
            end)

          if fixture do
            assert {:error, %Error{type: :corpus_violation} = err} =
                     CorpusGate.check(Map.fetch!(fixture, "xml"))

            assert err.details.matched_fixture_id == Map.get(fixture, "id")
          else
            # If no fixture carries inline XML, the gate is misconfigured for runtime use.
            flunk("Corpus manifest has no inline-XML fixture; CorpusGate cannot canary-test runtime refusal.")
          end
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/security/xml/corpus_gate_test.exs test/security/xml/corpus_security_test.exs --warnings-as-errors --include security_corpus</automated>
  </verify>
  <acceptance_criteria>
    - File `priv/security_corpus.json` exists.
    - `cmp test/fixtures/security/xml/manifest.json priv/security_corpus.json` exits 0 (the two files are byte-identical — the manifest was copied, not transformed).
    - File `lib/relyra/security/xml/corpus_gate.ex` exists with `defmodule Relyra.Security.XML.CorpusGate`.
    - `grep -c "def check(" lib/relyra/security/xml/corpus_gate.ex` returns at least `1`.
    - `grep -c ":corpus_violation" lib/relyra/security/xml/corpus_gate.ex` returns at least `1` (typed error code).
    - `grep -c "@manifest_path" lib/relyra/security/xml/corpus_gate.ex` returns at least `1` (compile-time path).
    - `grep -c "priv/security_corpus.json" test/security/xml/corpus_security_test.exs` returns at least `1` (test reader updated).
    - `grep -c "test/fixtures/security/xml/manifest.json" test/security/xml/corpus_security_test.exs` returns `0` (old path no longer referenced in the test reader).
    - `mix test test/security/xml/corpus_security_test.exs --include security_corpus --warnings-as-errors` exits 0 (existing corpus regression test continues to pass against the new manifest path).
    - `mix test test/relyra/security/xml/corpus_gate_test.exs --include security_corpus --warnings-as-errors` exits 0 (the new gate test passes including the fixture canary).
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>Manifest is byte-identical at the new `priv/security_corpus.json` path. The runtime `CorpusGate.check/2` returns `{:error, %Relyra.Error{type: :corpus_violation, details: %{matched_fixture_id: id, class: class}}}` for at least one fixture. The pre-existing test corpus regression test continues to pass against the relocated manifest. The Wave 0 stub for the gate test is replaced with three real tests.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Fetched metadata bytes → `TrustAnchor.check/2` | Untrusted PEM list crosses into the trust check; the helper ALONE decides "is this signing cert one we have agreed to trust." |
| Fetched metadata candidate → `DriftDetector.diff/2` | Untrusted entityID + fingerprint set crosses into the drift comparison; the helper alone decides "should the unattended path proceed or pause for review." |
| Fetched metadata bytes → `CorpusGate.check/2` | Untrusted XML crosses into the security regression gate BEFORE parse-deeply; the helper alone decides "does this match a known-bad shape." |
| `priv/security_corpus.json` | Embedded canonical manifest the gate reads at compile time; physical file location matters for the lib/test boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-11 | Spoofing | `TrustAnchor.check/2` | mitigate | Rejects empty pinned-list (`:no_pinned_fingerprints`) AND no-match (`:no_match`) with the same typed `:trust_anchor_mismatch` error per D-17 — there is no TOFU code path. The schema-level `validate_fingerprints_when_enabled/1` from Plan 01 is the first defense; this is defense-in-depth. |
| T-21-12 | Tampering | `DriftDetector.diff/2` | mitigate | Uses `MapSet.difference` over fingerprints only per Pitfall 7 — a metadata reformat that re-emits the same cert with different whitespace will NOT produce a false `:new_signing_cert`. PEM string compare is forbidden in this code path. |
| T-21-13 | Spoofing | `DriftDetector.diff/2` first-fetch handling | mitigate | When `last_known_metadata_signing_certs` is empty (first fetch), the helper returns `{:ok, :no_drift}` — initialization is not drift. The trust-anchor check (T-21-11) is the gate that prevents an attacker-supplied first-fetch cert from being accepted, NOT this one. |
| T-21-14 | Information Disclosure | `CorpusGate.check/2` returning fixture details | accept | Error details include `matched_fixture_id` and `class`, both of which are public test-corpus identifiers (not secrets). Helps operator diagnose which class of attack was attempted. |
| T-21-15 | Tampering | `priv/security_corpus.json` | mitigate | Manifest is byte-identical to the test/fixtures source via `cmp` invariant; any future mutation of one path requires mutation of the other (detected via `cmp` or via the PATTERNS-mandated test reader pointing at the new path). |
| T-21-16 | Information Disclosure | `CorpusGate.check/2` parser_error_type passthrough | accept | If the corpus does not match but `PureBeam.parse_safely/2` still errored, the original error is returned — parsing diagnostics may include line numbers but no PEM/key material (already redacted by `Relyra.Log` posture before reaching logs). |
</threat_model>

<verification>
- `mix test test/relyra/metadata/trust_anchor_test.exs test/relyra/metadata/drift_detector_test.exs test/relyra/security/xml/corpus_gate_test.exs --warnings-as-errors --include security_corpus` is green.
- `mix test test/security/xml/corpus_security_test.exs --warnings-as-errors --include security_corpus` is green (existing corpus regression intact at the new manifest path).
- `mix test --warnings-as-errors --exclude pending` is green.
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green.
- `cmp test/fixtures/security/xml/manifest.json priv/security_corpus.json` exits 0 (manifest is byte-identical at both paths).
</verification>

<success_criteria>
- `Relyra.Metadata.TrustAnchor.check/2` exists, accepts only operator-pinned fingerprints, rejects empty pinned lists and no-match with `:trust_anchor_mismatch` (D-17).
- `Relyra.Metadata.DriftDetector.diff/2` exists, compares MapSets of fingerprints (never PEMs — Pitfall 7), returns `{:drift, %{reason: :entity_id_drift | :new_signing_cert}}` (D-18), and treats first-fetch as initialization not drift.
- `Relyra.Security.XML.CorpusGate.check/2` exists, refuses fetched XML matching any LOCKED corpus fixture with typed `:corpus_violation` (D-21), and reads its manifest from `priv/security_corpus.json` at compile time.
- `priv/security_corpus.json` is byte-identical to `test/fixtures/security/xml/manifest.json` (canonical source preserved at the runtime-readable path).
- Pre-existing `test/security/xml/corpus_security_test.exs` continues to pass against the new manifest path (no regression).
- Three Wave 0 stubs are replaced with real tests; `mix test --include security_corpus` is up by ≥ 12 passing tests.
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-03-SUMMARY.md` summarizing: three modules with their typed error codes, manifest relocation diff (`cmp` proof), test counts per file, and any deviations from the locked rejection semantics.
</output>