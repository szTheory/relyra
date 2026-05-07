---
phase: 21-scheduled-metadata-refresh
plan: 03
subsystem: security
tags: [elixir, ecto-adjacent, security, sha256, mapset, json-corpus, exunit]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: Wave-0 stub test files at test/relyra/metadata/{trust_anchor,drift_detector}_test.exs and test/relyra/security/xml/corpus_gate_test.exs (replaced with green tests in this plan); Phase-21 typed error vocabulary (:trust_anchor_mismatch, :corpus_violation) reachable through MetadataSource.auto_refresh_changeset/2 + health_state_changeset/2
provides:
  - Relyra.Metadata.TrustAnchor.check/2 — operator-pinned SHA-256 fingerprint trust check (D-17, no TOFU); reuses :crypto.hash(:sha256, _) |> Base.encode16(case: :lower) verbatim from Relyra.Metadata.Import.sha256/1 (Don't Hand-Roll row 5)
  - Relyra.Metadata.TrustAnchor.fingerprint/1 — public mirror of the canonical fingerprint compute so callers (Mix task, Plan 21-07) do not need to re-derive
  - Relyra.Metadata.DriftDetector.diff/2 — entityID + signing-cert fingerprint diff (D-18); MapSet-only comparison so whitespace reformat does NOT re-fire :new_signing_cert (Pitfall 7)
  - Relyra.Security.XML.CorpusGate.check/2 — runtime security-corpus refusal gate (D-21); compiles priv/security_corpus.json into @manifest at module load so callers pay zero runtime file-read cost
  - priv/security_corpus.json — canonical security-corpus manifest at the lib/-readable path; byte-identical to test/fixtures/security/xml/manifest.json (cmp invariant) so the test corpus regression continues to gate against the same source of truth
  - 17 green tests across 3 test files (5 TrustAnchor + 8 DriftDetector + 4 CorpusGate) replacing all three Wave-0 :pending stubs
affects: [21-04-audit-seam-extension, 21-05-scheduler-wrapper-worker]

tech-stack:
  added: []  # no new dependencies; uses existing :crypto, :json (OTP 28 stdlib), MapSet, Path
  patterns:
    - "Phase-21 byte-level metadata gate: derive runtime refusal triggers from PureBeam.parse_safely/2's own early-rejection logic so the corpus gate and the hardened parser share one shape (DOCTYPE / ENTITY / payload size). Other corpus classes (signature_wrapping, parser_differential_and_c14n, keyinfo_misuse, unsigned_or_partial_signature, duplicate_ids) intentionally fall through to upstream verifier/parser refusal because their fixture XML is <Response>-shaped and not realistic metadata bait."
    - "Compile-time manifest embedding via @external_resource + @manifest_path + Path.expand: callers get a zero-runtime-IO gate, and Mix's incremental compiler picks up manifest edits automatically."
    - "MapSet-only fingerprint diff (Pitfall 7): comparing PEM strings is whitespace-sensitive; comparing fingerprints over MapSet.difference/2 is order-insensitive AND whitespace-immune in one shape."

key-files:
  created:
    - lib/relyra/metadata/trust_anchor.ex
    - lib/relyra/metadata/drift_detector.ex
    - lib/relyra/security/xml/corpus_gate.ex
    - priv/security_corpus.json
  modified:
    - test/relyra/metadata/trust_anchor_test.exs
    - test/relyra/metadata/drift_detector_test.exs
    - test/relyra/security/xml/corpus_gate_test.exs
    - test/security/xml/corpus_security_test.exs

key-decisions:
  - "Replaced PLAN's literal CorpusGate implementation with byte-level refusal triggers (Rule 1 deviation). The planned code routed all candidate XML through PureBeam.parse_safely/2 and matched any returned error type against fixtures' expected_error_type. parse_safely/2 requires <Response>-shaped XML and returns :malformed_xml for benign <EntityDescriptor> metadata; :malformed_xml is itself a fixture expected_error_type, which would falsely fire :corpus_violation for every benign scheduled refresh. The new implementation matches manifest fixtures by their refusal class (doctype_forbidden / entity_expansion_forbidden / payload_too_large) against byte-level patterns that mirror parse_safely/2's own pre-parse refusal logic."
  - "payload_too_large gate cap is the Phase-21 D-20 5 MB metadata-fetch ceiling, not the per-fixture toy max_bytes (8/10/12). Treating fixture thresholds as the gate cap would refuse every benign metadata XML > 12 bytes."
  - "Used @external_resource @manifest_path so manifest edits trigger a recompile of CorpusGate, keeping the runtime gate in lockstep with the test corpus reader."

requirements-completed: []  # CFG-08 is multi-plan; this plan delivers three of the security-boundary helpers but does NOT close CFG-08 — that ships in Phase 21 W5 (Plan 21-05/21-07).

duration: ~7min
completed: 2026-05-06
---

# Phase 21 Plan 03: Trust-Boundary Helpers Summary

**Three pure security-boundary helpers (TrustAnchor + DriftDetector + CorpusGate) plus the canonical security-corpus relocation to priv/, all wired against Plan-01's typed-error vocabulary and the existing Wave-0 stub files.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-07T02:14:34Z (UTC) — Task 1 commit `1c02e38`
- **Completed:** 2026-05-07T02:21:55Z (UTC) — Task 2 commit `9400a0d`
- **Tasks:** 2 / 2
- **Files created:** 4 (TrustAnchor module, DriftDetector module, CorpusGate module, priv/security_corpus.json)
- **Files modified:** 4 (3 Wave-0 stub test files replaced; 1 existing corpus regression test pointed at the new manifest path)

## Accomplishments

- `Relyra.Metadata.TrustAnchor.check/2` enforces D-17 operator-pinned trust without TOFU. Returns `{:error, %Relyra.Error{type: :trust_anchor_mismatch}}` with `details.reason: :no_pinned_fingerprints | :no_match` so the wrapper (21-05) can disambiguate empty-pin from no-match. Reuses `:crypto.hash(:sha256, pem) |> Base.encode16(case: :lower)` verbatim — no re-implementation.
- `Relyra.Metadata.DriftDetector.diff/2` produces `{:ok, :no_drift} | {:drift, %{reason: :entity_id_drift | :new_signing_cert, ...}}`. Compares MapSets of fingerprints (Pitfall 7 — never PEMs). Empty `last_known_metadata_signing_certs` is initialization, not drift. `entity_id_drift` takes precedence over `new_signing_cert` when both fire.
- `Relyra.Security.XML.CorpusGate.check/2` reads `priv/security_corpus.json` at compile time (`@manifest` module attribute, `@external_resource` for incremental rebuilds). Refuses candidate XML matching DOCTYPE / ENTITY / oversized payload byte-level shapes with typed `:corpus_violation` error including `matched_fixture_id`, `class`, and `expected_error_type` in details.
- Manifest relocation is byte-identical (`cmp test/fixtures/security/xml/manifest.json priv/security_corpus.json` exits 0). Both the runtime gate and the existing test corpus reader at `test/security/xml/corpus_security_test.exs` now read from `priv/security_corpus.json` so the lib/test boundary is preserved.
- All three Wave-0 `:pending` stubs are replaced with 17 green tests total (5 TrustAnchor + 8 DriftDetector + 4 CorpusGate including the security-corpus canary).

## Task Commits

1. **Task 1: Create TrustAnchor + DriftDetector pure helpers and their tests** — `1c02e38` (feat)
2. **Task 2: Move security corpus manifest to priv/ and create the runtime CorpusGate** — `9400a0d` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol).

## Files Created/Modified

### Created

- `lib/relyra/metadata/trust_anchor.ex` — `check/2` + `fingerprint/1`; pure (no Ecto, Repo, Req, Logger, Telemetry); reuses `:crypto.hash(:sha256, _)` from `Relyra.Metadata.Import.sha256/1`.
- `lib/relyra/metadata/drift_detector.ex` — `diff/2`; pure; `MapSet.difference/2` over fingerprint hex strings; first-fetch is `{:ok, :no_drift}`.
- `lib/relyra/security/xml/corpus_gate.ex` — `check/2` + `manifest/0` + `manifest_path/0`; compile-time `@manifest` via `:json.decode/1`; `@external_resource` so manifest edits trigger recompile.
- `priv/security_corpus.json` — byte-identical copy of `test/fixtures/security/xml/manifest.json` (36 fixtures, 7 classes, 6 expected_error_type values).

### Modified

- `test/relyra/metadata/trust_anchor_test.exs` — Wave-0 stub replaced with 5 tests (fingerprint shape, match path, multi-valued pin rotation, empty-pin rejection with `:no_pinned_fingerprints`, no-match rejection with `:no_match`, case-normalization).
- `test/relyra/metadata/drift_detector_test.exs` — Wave-0 stub replaced with 8 tests across 4 describe blocks (no-drift exact match, no-drift subset, no-drift first-fetch, entity_id drift, drift precedence, new_signing_cert drift, fingerprint-only order-insensitivity).
- `test/relyra/security/xml/corpus_gate_test.exs` — Wave-0 stub replaced with 4 tests (manifest load + path, manifest non-empty, benign-XML pass, fixture canary refusal with `matched_fixture_id` assertion).
- `test/security/xml/corpus_security_test.exs` — `@manifest_path` swapped from `"test/fixtures/security/xml/manifest.json"` to `"priv/security_corpus.json"`; everything else preserved verbatim so the existing parser_differential_and_c14n GATE-02 binary gate, the manifest-class evaluation test, and the deterministic 3x re-run test all continue to pass against the new path.

## Decisions Made

- **CorpusGate detection model: byte-level refusal triggers, not parse-and-classify.** The PLAN's literal code (`PureBeam.parse_safely/2` + match returned error type to fixture's expected type) works for `<Response>`-shaped XML but breaks for metadata XML — `parse_safely/2` returns `:malformed_xml` for any non-Response root, and `:malformed_xml` is itself a fixture-expected error type. The corrected design matches fixtures by `expected_error_type` against byte-level patterns that mirror `parse_safely/2`'s own pre-parse refusal logic (DOCTYPE / ENTITY / payload size). This preserves D-21 intent (every fixture refuses on the scheduled path) for the realistic metadata-bait classes (xxe_entity_abuse, size_and_inflate_bounds) while leaving the `<Response>`-shaped classes (signature_wrapping, parser_differential_and_c14n, keyinfo_misuse, unsigned_or_partial_signature, duplicate_ids) to be caught upstream by the signature verifier / parser. The other classes' fixture XML is not realistic metadata input, so allowing them to fall through to upstream refusal is correctness-preserving.
- **payload_too_large cap = D-20's 5 MB metadata-fetch ceiling.** Fixture `max_bytes` values (8 / 10 / 12 / 9) are toy thresholds that drive the parser's pre-parse refusal in the test corpus — they are NOT the gate's runtime cap. Using them as the gate cap would refuse every benign metadata XML > 12 bytes. The gate accepts `opts[:max_bytes]` for caller-controlled overrides.
- **Manifest move uses `@external_resource` so Mix's incremental compiler picks up edits.** Without it, editing `priv/security_corpus.json` would not invalidate `Relyra.Security.XML.CorpusGate`'s `@manifest`, leading to a stale gate at compile-time. With it, future fixture additions automatically rebuild the gate.
- **Both helpers expose `Relyra.Error.t()` returns; no exceptions for control flow.** Matches the project's stable typed-error contract from `lib/relyra/error.ex` (PROJECT.md product principle 4).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] PLAN's literal CorpusGate implementation falsely fires `:corpus_violation` for benign metadata XML**

- **Found during:** Task 2 verify gate (`mix test test/relyra/security/xml/corpus_gate_test.exs --include security_corpus`)
- **Issue:** The PLAN code `case PureBeam.parse_safely(xml, opts) do {:error, %Error{type: type}} -> match_against_corpus(type) ...` matches benign EntityDescriptor XML against `:malformed_xml` (because `parse_safely/2` requires Response-root) and `:malformed_xml` IS a fixture `expected_error_type`. The "benign EntityDescriptor returns :ok or non-:corpus_violation error" test failed with `Refute with == failed: left: :corpus_violation`.
- **Fix:** Replaced parse-and-classify with byte-level pattern matchers keyed by fixture `expected_error_type`: `:doctype_forbidden` → `String.contains?(xml, "<!DOCTYPE")`, `:entity_expansion_forbidden` → `String.contains?(xml, "<!ENTITY")`, `:payload_too_large` → `byte_size(xml) > opts[:max_bytes] || 5_000_000`. Other classes return `false` (caught upstream by signature verifier / parser).
- **Files modified:** `lib/relyra/security/xml/corpus_gate.ex`
- **Verification:** `mix test test/relyra/security/xml/corpus_gate_test.exs test/security/xml/corpus_security_test.exs --warnings-as-errors --include security_corpus` exits 0, all 7 tests pass (4 corpus_gate + 3 corpus_security).
- **Committed in:** `9400a0d` (Task 2 commit)

**2. [Rule 1 — Bug] First-pass payload_too_large matcher used the fixture's toy `max_bytes` threshold**

- **Found during:** Task 2 verify gate (initial pre-deviation-1 attempt)
- **Issue:** The first byte-level matcher attempt used the fixture's stored `max_bytes` (8 / 10 / 12) as the gate cap, refusing every benign metadata XML > 12 bytes including the 134-byte benign EntityDescriptor.
- **Fix:** Use the Phase-21 D-20 metadata-fetch ceiling (5 MB) as the default cap, with `opts[:max_bytes]` per-call override. Documented inline why fixture `max_bytes` values are toy thresholds.
- **Files modified:** `lib/relyra/security/xml/corpus_gate.ex`
- **Committed in:** `9400a0d` (Task 2 commit — squashed with Deviation 1 since both surfaced and were fixed in the same task verify cycle)

---

**Total deviations:** 2 auto-fixed Rule-1 bugs (both inside the CorpusGate detection design; both required to land working code).

**Impact on plan:** The deviations preserve the spirit of D-21 (every locked corpus fixture acts as a refusal trigger on the scheduled path) for the realistic metadata-bait classes (xxe_entity_abuse, size_and_inflate_bounds — DOCTYPE/ENTITY/size). The non-bait classes (`signature_wrapping`, `parser_differential_and_c14n`, `keyinfo_misuse`, `unsigned_or_partial_signature`, `duplicate_ids`) are caught upstream by the signature verifier / parser on the metadata path; D-21's "every fixture refuses" intent is preserved across the wrapper boundary (Plan 21-05 will route untrusted XML through `Relyra.Security.Signature.verify_metadata_root/4` BEFORE handing off to `CorpusGate.check/2`, so signature-wrapping shapes are refused at the verifier before the gate sees them).

## Issues Encountered

- **Pre-existing test failure (out-of-scope per SCOPE BOUNDARY):** `test/phoenix/acs_controller_test.exs:48 — POST /:connection_id/acs success` trips a `KeyError` on `:name_id` inside `FakeUserMapper.map_attributes/3`. Already documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` as pre-existing on commit `0842687` (the parent of Phase 21 execution). Not caused by Plan 21-03; not in scope for Plan 21-03. Full suite: 230 tests, 1 failure (the pre-existing one), 13 excluded — all 17 Plan-21-03 tests are green.
- **Pre-existing format drift in `lib/relyra/live_admin/connections_live.ex`:** Already documented in `deferred-items.md` (Phase 20 commit `6e75525`). No Plan 21-03 file is touched here, so this remains untouched. Plan 21-03 files all pass `mix format --check-formatted`.

## Pre-existing Out-of-Scope Issues (Deferred)

Both items in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` remain pre-existing and unchanged by this plan. No new entries added.

## User Setup Required

None — no external service configuration required. The runtime corpus gate is compile-time embedded (`@manifest`); no runtime file-system permissions needed.

## Next Phase Readiness

- **Wave 2 (21-04 audit-seam-extension) can proceed.** Both `MetadataSource` schema fields (Plan 01) and the three trust-boundary helpers (this plan) are in place. The audit-seam plan will call `TrustAnchor.check/2` and `CorpusGate.check/2` results into `MetadataApply.record_attempt/3`'s health-state attrs.
- **Wave 3 (21-05 scheduler-wrapper-worker) can proceed in parallel with Wave 2.** The wrapper module (`Relyra.Metadata.AutoRefresh`) will compose:
  1. `Relyra.Metadata.TrustAnchor.check/2` (this plan) for D-17.
  2. `Relyra.Security.Signature.verify_metadata_root/4` (Plan 21-04) for D-16.
  3. `Relyra.Security.XML.CorpusGate.check/2` (this plan) for D-21.
  4. `Relyra.Metadata.DriftDetector.diff/2` (this plan) for D-18.
- **Test infrastructure is ready.** The Wave-0 `:pending` tags are removed from all three Plan-21-03 test files (`@moduletag :pending` deleted; replaced with real test bodies). The `test/test_helper.exs` `exclude: [:pending]` setting is unchanged from Plan 01 — other Wave-0 stubs still skip.
- **No blockers.** Both compile lanes (`mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`) are green.

## Threat Flags

None — no new security surface introduced beyond the locked threat register entries (T-21-11 through T-21-16) which are all `mitigate` / `accept` per the plan's threat model and implemented as documented.

## Self-Check: PASSED

Plan-21-03 file existence + commit-hash verification (run before SUMMARY commit):

- `lib/relyra/metadata/trust_anchor.ex` — FOUND
- `lib/relyra/metadata/drift_detector.ex` — FOUND
- `lib/relyra/security/xml/corpus_gate.ex` — FOUND
- `priv/security_corpus.json` — FOUND (byte-identical to `test/fixtures/security/xml/manifest.json` per `cmp`)
- `test/relyra/metadata/trust_anchor_test.exs` — FOUND (5 tests, no `:pending` tag)
- `test/relyra/metadata/drift_detector_test.exs` — FOUND (8 tests, no `:pending` tag)
- `test/relyra/security/xml/corpus_gate_test.exs` — FOUND (4 tests, no `:pending` tag at module level; one `@tag :security_corpus` on the canary)
- `test/security/xml/corpus_security_test.exs` — FOUND (`@manifest_path "priv/security_corpus.json"` swap applied)
- Commit `1c02e38` (Task 1: TrustAnchor + DriftDetector) — FOUND
- Commit `9400a0d` (Task 2: corpus relocation + CorpusGate) — FOUND

Acceptance-criteria evidence (grep counts from the live tree):

- `grep -c "def check(" lib/relyra/metadata/trust_anchor.ex` → 1 ✓
- `grep -c ":crypto.hash(:sha256" lib/relyra/metadata/trust_anchor.ex` → 1 ✓
- `grep -c "trust_anchor_mismatch" lib/relyra/metadata/trust_anchor.ex` → 3 ✓
- `grep -c "def diff(" lib/relyra/metadata/drift_detector.ex` → 1 ✓
- `grep -c "MapSet.difference\|MapSet.disjoint?" lib/relyra/metadata/drift_detector.ex` → 1 ✓
- `grep -cE "(entity_id_drift|new_signing_cert)" lib/relyra/metadata/drift_detector.ex` → 14 ✓
- `grep -cE "alias Relyra\.(Ecto|Telemetry)|require Logger|use Ecto" lib/relyra/metadata/{trust_anchor,drift_detector}.ex` → 0 / 0 ✓ (purity invariant holds)
- `grep -c "def check(" lib/relyra/security/xml/corpus_gate.ex` → 1 ✓
- `grep -c ":corpus_violation" lib/relyra/security/xml/corpus_gate.ex` → 5 ✓
- `grep -c "@manifest_path" lib/relyra/security/xml/corpus_gate.ex` → 4 ✓
- `grep -c "priv/security_corpus.json" test/security/xml/corpus_security_test.exs` → 1 ✓
- `grep -c "test/fixtures/security/xml/manifest.json" test/security/xml/corpus_security_test.exs` → 0 ✓
- `cmp test/fixtures/security/xml/manifest.json priv/security_corpus.json` → exit 0 ✓
- `mix test test/relyra/metadata/trust_anchor_test.exs test/relyra/metadata/drift_detector_test.exs test/relyra/security/xml/corpus_gate_test.exs --warnings-as-errors --include security_corpus` → 17 tests / 0 failures ✓
- `mix test test/security/xml/corpus_security_test.exs --include security_corpus --warnings-as-errors` → all 3 corpus regression tests pass against the new manifest path ✓
- `mix compile --warnings-as-errors` → exit 0 ✓
- `mix compile --no-optional-deps --warnings-as-errors` → exit 0 ✓

---

*Phase: 21-scheduled-metadata-refresh*
*Plan: 03 trust-boundary-helpers*
*Completed: 2026-05-06*
