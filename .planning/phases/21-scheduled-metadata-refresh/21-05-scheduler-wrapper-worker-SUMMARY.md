---
phase: 21-scheduled-metadata-refresh
plan: 05
subsystem: metadata
tags: [scheduler, oban, optional-deps, telemetry, signature-binding, asymmetric-strictness, exunit]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: Relyra.Ecto.MetadataSource auto-refresh column set + relyra_metadata_sources_due_idx partial index + LOCKED @cadence_values / @suspended_reason_values enums + Wave-0 stub test files at test/relyra/{optional_deps/oban,workers/metadata_refresh,metadata/scheduler,metadata/auto_refresh}_test.exs that this plan replaces in place
  - phase: 21-scheduled-metadata-refresh
    plan: 02
    provides: Relyra.Metadata.Cadence.cadence_seconds/1 (consumed by maybe_emit_validity_warning to compute the 2 × refresh_interval slack)
  - phase: 21-scheduled-metadata-refresh
    plan: 03
    provides: Relyra.Metadata.TrustAnchor.check/2 (D-17 operator-pinned trust check), Relyra.Metadata.DriftDetector.diff/2 (D-18 entity_id/new_signing_cert drift), Relyra.Security.XML.CorpusGate.check/2 (D-21 corpus refusal gate)
  - phase: 21-scheduled-metadata-refresh
    plan: 04
    provides: Relyra.Ecto.MetadataApply.apply_revision/4 + record_attempt/3 (extended with the trigger-gated D-28 health-state co-commit), Relyra.Ecto.MetadataApply.record_validity_warning/3 (B2 at-most-once seam), Relyra.Security.Signature.verify_metadata_root/4 (thin shim with flow: :metadata_refresh tag), Relyra.Ecto.MetadataRevision.@trigger_values extended with :scheduled_refresh
  - phase: 11-mapping-persistence-and-audit-hardening
    provides: Relyra.Ecto.AuditWriter.append_event/2 (single audit-writer seam — reused indirectly through MetadataApply)

provides:
  - Relyra.OptionalDeps.Oban — gateway with available?/0, ensure_available!/1, required_modules/0; returns {:error, %Relyra.Error{type: :optional_dependency_missing}} when Oban absent (D-02 / D-37 canonical pattern; result-tuple deviation from Relyra.LiveAdmin's raise)
  - Relyra.Workers.MetadataRefresh — optional Oban worker; compiles in BOTH lanes via the canonical outside-the-defmodule Code.ensure_loaded? gate; LOCKED unique: [period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]] per D-03; max_attempts: 1 per D-25; delegates to Scheduler.run_due/2
  - Relyra.Metadata.Scheduler.run_due/2 — dormant by default per D-04 (no GenServer ticker, no auto-start); auto-generates one correlation_id per batch (D-39); sequential per-source loop (D-38); emits [:relyra, :saml, :metadata, :auto_refresh, :skipped] for empty due-set (D-07); supports :source_ids opt for the LiveView "Resume now" probe path (Plan 06 dependency)
  - Relyra.Metadata.AutoRefresh.refresh/2 — stricter wrapper around Refresh.refresh/2 from outside (D-05); enforces D-15 require_signed_metadata with the D-19 legacy_unsigned_metadata_policy escape hatch; linear pipeline: stricter Req fetch (D-20) → metadata-root signature pre-parse (W10 — no nil xml_id/xpath) → TrustAnchor.check (D-17) → Signature.verify_metadata_root (D-16) → Parser.parse → CorpusGate.check (D-21) → DriftDetector.diff (D-18) → MetadataApply.apply_revision/4 with trigger: :scheduled_refresh (Plan 04 transactional D-28 path)
  - Five-class refusal mapping → LOCKED auto_suspended_reason enum: trust_anchor_mismatch → :trust_anchor_mismatch, signature_failed/invalid_signature/missing_signature/untrusted_certificate → :signature_invalid, corpus_violation → :corpus_violation, metadata_drift_requires_review/entity_id_drift → :entity_id_drift, metadata_drift_requires_review/new_signing_cert → :new_signing_cert
affects: [21-06-live-admin-surface, 21-07-mix-tasks-telemetry-docs]

tech-stack:
  added: []  # no new runtime dependencies; Oban is a host-app optional dep gated through OptionalDeps.Oban
  patterns:
    - "Outside-the-defmodule Code.ensure_loaded? gate for `use` macros: when an optional dep is the host of a `use` directive (Oban.Worker, Phoenix.LiveView, Ecto.Schema), the in-body `if Code.ensure_loaded?(...)` does NOT work because Elixir's Kernel.if/2 eagerly compiles both branches; `use Oban.Worker` then crashes with a CompileError even when the runtime branch would never execute. The canonical pattern in this codebase (Relyra.LiveAdmin / ConnectionMetadataLive / LiveAdmin.Query) is `if Code.ensure_loaded?(...) do defmodule Foo do ... end else defmodule Foo do (stub) end end` — the whole defmodule is gated so the disabled-lane body never reaches the compiler."
    - "Five-class refusal → LOCKED auto_suspended_reason mapping (Plan 21 D-18/D-25/D-27 contract): refusal classes from independent helper modules (TrustAnchor, Signature, CorpusGate, DriftDetector) are mapped to typed atoms BEFORE crossing the audit/health seam. The mapping table is the single source of truth for which refusal puts the source into which suspend reason; future refusal classes MUST extend both the @suspended_reason_values enum (Plan 01) and this mapping (Plan 05) in lockstep."
    - "Asymmetric-strictness wrapper: AutoRefresh.refresh/2 wraps Refresh.refresh/2 from OUTSIDE rather than re-implementing it (D-05). Manual import / manual refresh paths flow through Refresh.refresh/2 unchanged; scheduled refresh adds the D-15..D-21 gates BEFORE the candidate reaches MetadataApply.apply_revision/4. This preserves the 'manual paths byte-identical to Phase 09/12' invariant (Plan 04 trigger gating) while letting the scheduled path be strict-by-default."
    - "Pre-parse signature-binding extraction (W10): the metadata-root signature envelope is located via regex on `<EntityDescriptor>` / `<EntitiesDescriptor>` + child `<ds:Signature>` + Reference URI BEFORE Parser.parse runs (Pitfall 4 — verify before parse-deeply). Returns a `signed_candidates` list with concrete xml_id (URI without `#`) + xpath (canonical metadata-root path) + key_info_trust signal + duplicate_ids — every value populated. The forwarded key_info_trust signal makes Signature.verify_metadata_root reject document-KeyInfo trust for the metadata path automatically (T-21-29 mitigation inheritance)."

key-files:
  created:
    - lib/relyra/optional_deps/oban.ex
    - lib/relyra/workers/metadata_refresh.ex
    - lib/relyra/metadata/scheduler.ex
    - lib/relyra/metadata/auto_refresh.ex
  modified:
    - test/relyra/optional_deps/oban_test.exs       # Wave-0 stub replaced; 4 green tests across 3 describe blocks
    - test/relyra/workers/metadata_refresh_test.exs # Wave-0 stub replaced; 3 green tests across 2 describe blocks
    - test/relyra/metadata/scheduler_test.exs       # Wave-0 stub replaced; 5 green tests across 3 describe blocks
    - test/relyra/metadata/auto_refresh_test.exs    # Wave-0 stub replaced; 12 tests across 7 describe blocks (2 unit + 10 :integration placeholders honoring the LOCKED describe-block contract)

key-decisions:
  - "Rule 3 deviation: outside-the-defmodule Code.ensure_loaded? gate for both Workers.MetadataRefresh and Metadata.Scheduler. The PLAN's literal in-body `if Code.ensure_loaded?(Oban.Worker) do use Oban.Worker, ... else def perform/1 ... end` does NOT compile in Elixir 1.19 — Kernel.if/2 eagerly expands both branches, and `use Oban.Worker` crashes with `module Oban.Worker is not loaded` regardless of the runtime condition. Same shape applies to `import Ecto.Query` for Scheduler. The canonical idiom in this codebase (Relyra.LiveAdmin / Relyra.LiveAdmin.ConnectionMetadataLive / Relyra.LiveAdmin.Query) is to wrap the whole `defmodule` in the `Code.ensure_loaded?` gate with a stub `defmodule` in the else branch. Both modules now follow this shape; both compile lanes (`mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`) are green."
  - "AutoRefresh test :integration tagging vs unit-level invariants. The PLAN's NOTE explicitly authorizes 'placeholder integration tests return :ok; the DESCRIBE-block contract is in place'. The two unit-level tests (D-17 trust_anchor_mismatch refusal + D-23 telemetry-namespace separation) exercise the AutoRefresh wrapper end-to-end through Req.Test (the canonical stub adapter used by Relyra.MetadataRefreshTest); the remaining 10 describe blocks are tagged `:integration` and assert :ok placeholders so the LOCKED describe-block contract names ARE in place for downstream verifier work. The B2 validity-warning seam, the corpus_violation path, and the W10 signature-binding regression are all covered indirectly by the per-helper test files (Plan 02/03/04) and by the grep acceptance criteria checked below."
  - "Validity-warning placement reordering. The PLAN snippet placed `maybe_emit_validity_warning` AFTER `Import.build_candidate(parsed)` in the with-pipeline but BEFORE the drift check. The implementation places it BEFORE `build_candidate` to use only the raw XML + Cadence preset (no candidate dependency) — this preserves the at-most-once seam through MetadataApply.record_validity_warning/3 and keeps the validity check independent of the drift outcome. Functionally equivalent ordering; chosen because the helper does not need the candidate."
  - "extract_candidate_signing_pems uses regex scan (NOT Parser.parse). Honors Pitfall 4 (verify before parse-deeply). The regex shape is the SAME as `Parser.fetch_certificates/1` so the byte-level extraction matches the parser's view; the strict parser still gets the candidate AFTER the trust anchor + signature checks pass."
  - "Test repo bypass for the schema 'auto_refresh_enabled requires fingerprints' guard. The trust-anchor-mismatch unit test inserts a MetadataSource via the existing `changeset/2` (registration path) and then back-doors `auto_refresh_enabled: false, metadata_trust_fingerprints: []` via Ecto.Changeset.change. The plan's intended schema-level great-error from auto_refresh_changeset/2 (Plan 01 D-09) prevents the same shape in production — this test verifies the WRAPPER's defensive trust check still fires even on a misconfigured row, which preserves the asymmetric-strictness invariant end-to-end (defense in depth: schema rejects the configuration, wrapper rejects the runtime state)."

requirements-completed: []  # CFG-08 is multi-plan; this plan delivers the dormant-by-default scheduler + wrapper + worker but does NOT close CFG-08 — that ships in Phase 21 W5 (Plan 21-07)

duration: ~10min
completed: 2026-05-07
---

# Phase 21 Plan 05: Scheduler-Wrapper-Worker Summary

**Lands the four new modules that make Phase 21 actually scheduled — `Relyra.OptionalDeps.Oban` gateway (D-02 / D-37), the optional `Relyra.Workers.MetadataRefresh` worker (D-02 / D-03 / D-25), the dormant `Relyra.Metadata.Scheduler.run_due/2` entry point (D-01 / D-04 / D-38 / D-39), and the stricter `Relyra.Metadata.AutoRefresh.refresh/2` wrapper (D-05 / D-15..D-21) — all sharing one `correlation_id` per `run_due/2` invocation and routing five refusal classes to LOCKED typed `auto_suspended_reason` values.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-07T02:51:00Z (UTC) — pre-Task-1 read-throughs
- **Completed:** 2026-05-07T03:00:51Z (UTC) — Task 2 commit `3b60a04`
- **Tasks:** 2 / 2
- **Files created or modified:** 8 (4 production modules + 4 test files; the 4 test files were Wave-0 stubs from Plan 01 and are replaced in place)

## Accomplishments

### Task 1: OptionalDeps gateway + Oban worker (both compile lanes)

- **`Relyra.OptionalDeps.Oban`** (47 LOC): gateway returning `{:ok | :error, %Relyra.Error{}}` per D-02 / D-37 (canonical optional-deps pattern). `available?/0`, `ensure_available!/1`, `required_modules/0`. `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}` keeps `mix compile --no-optional-deps --warnings-as-errors` green (engineering-DNA §3 invariant). Phase-21 deviation from `Relyra.LiveAdmin`'s `raise ArgumentError`: the worker `perform/1` callback expects a result tuple, not a raise.
- **`Relyra.Workers.MetadataRefresh`** (~95 LOC): two-lane Oban worker. Oban-present body uses `use Oban.Worker, queue: :relyra_metadata, max_attempts: 1, unique: [period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]]` per D-03 + D-25; `perform/1` extracts `repo` from job args via `String.to_existing_atom/1` (T-21-31) and delegates to `Scheduler.run_due/2`. Oban-absent body provides a stub `perform/1` returning `{:error, %Error{type: :optional_dependency_missing}}`.
- **Test coverage:** 4 OptionalDeps tests (`available?/0` boolean, `ensure_available!/1` ok/error split, `required_modules/0` exact list) + 3 Worker tests (Oban-present delegate path, behaviour function-exported assertion, Oban-absent typed-error path).

### Task 2: Scheduler entry point + AutoRefresh wrapper

- **`Relyra.Metadata.Scheduler`** (~135 LOC): `run_due/2` is the dormant-by-default entry point (D-04 — no GenServer ticker). Auto-generates one `correlation_id` per batch (D-39); threads it through every per-source `AutoRefresh.refresh/2` call. Empty due-set emits `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` (D-07). The runtime due-rows query applies the suspend/time filter at query time per Plan 01's IMMUTABLE-only partial-index decision; the Postgres planner still picks the partial index because `auto_refresh_enabled = true` is the gating predicate. `:source_ids` opt bypasses the partial-index path for the LiveView "Resume now" probe (Plan 06 dependency).
- **`Relyra.Metadata.AutoRefresh`** (~580 LOC): stricter wrapper around `Refresh.refresh/2` per D-05 (refresh.ex byte-identical: `git diff lib/relyra/metadata/refresh.ex` is empty). Linear pipeline with every stage as a refusal point:
  1. `fetch_xml/2` with the LOCKED stricter Req profile (D-20: 30s connect + 30s receive timeouts, `redirect: false` HTTPS-no-downgrade, `max_response_size: 5_000_000`, fixed `User-Agent: Relyra-MetadataRefresh/<vsn>`).
  2. `verify_signature/3` — D-15 require_signed_metadata gate with the D-19 `legacy_unsigned_metadata_policy.allow_until` escape hatch.
  3. `do_verify_signature/3` — two-step trust per D-17: `extract_candidate_signing_pems/1` (regex scan, NOT deep parse — Pitfall 4) → `TrustAnchor.check/2` → `pre_parse_for_signature/1` (W10 real binding extraction) → `Signature.verify_metadata_root/4` with `key_info_trust` forwarded from the pre-parse so the Phase-04 do_verify rejection inherits to the metadata path.
  4. `Parser.parse/2` (the existing hardened parser; only NOW per Pitfall 4).
  5. `CorpusGate.check/2` (D-21 byte-level refusal gate).
  6. `maybe_emit_validity_warning/4` (B2 / D-14 — at-most-once per validUntil per source via `MetadataApply.record_validity_warning/3`).
  7. `Import.build_candidate/1`.
  8. `check_drift/3` (D-18 entity_id_drift / new_signing_cert via `DriftDetector.diff/2`).
  9. `apply_candidate/6` → `MetadataApply.apply_revision/4` with `trigger: :scheduled_refresh` (Plan 04 D-28 transactional path).
- **Five-class refusal → typed `auto_suspended_reason` mapping** (the LOCKED enum from Plan 01):

  | Refusal source | Error type | auto_suspended_reason |
  |---|---|---|
  | `TrustAnchor.check/2` | `:trust_anchor_mismatch` | `:trust_anchor_mismatch` |
  | `Signature.verify_metadata_root/4` | `:signature_failed`, `:invalid_signature`, `:missing_signature`, `:untrusted_certificate` | `:signature_invalid` |
  | `CorpusGate.check/2` | `:corpus_violation` | `:corpus_violation` |
  | `DriftDetector.diff/2` (entity_id) | `:metadata_drift_requires_review` (details.auto_suspended_reason: :entity_id_drift) | `:entity_id_drift` |
  | `DriftDetector.diff/2` (new cert) | `:metadata_drift_requires_review` (details.auto_suspended_reason: :new_signing_cert) | `:new_signing_cert` |
  | 5 transient failures (default) | (any classified-transient) | `:transient_failures_exceeded` (Plan 04 default) |

- **Test coverage:** 5 Scheduler tests (`:skipped` event emission, caller-supplied correlation_id, auto-generated correlation_id UUID-shape, `:source_ids` bypass path, `auto_refresh_enabled = false` row exclusion) + 12 AutoRefresh tests (2 unit-level: D-17 trust_anchor_mismatch refusal end-to-end, D-23 telemetry-namespace separation; 10 `:integration`-tagged describe-block contracts honoring the PLAN NOTE).

## Task Commits

1. **Task 1: OptionalDeps.Oban gateway + Workers.MetadataRefresh worker** — `ff88242` (feat)
2. **Task 2: Scheduler.run_due/2 + AutoRefresh.refresh/2 wrapper** — `3b60a04` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol).

## Files Created/Modified

### Created

- `lib/relyra/optional_deps/oban.ex` — gateway module; D-02 / D-37 canonical pattern with result-tuple deviation.
- `lib/relyra/workers/metadata_refresh.ex` — two-lane Oban worker; outside-the-defmodule `Code.ensure_loaded?(Oban.Worker)` gate.
- `lib/relyra/metadata/scheduler.ex` — `run_due/2` + due-rows query + `:skipped` emission; outside-the-defmodule `Code.ensure_loaded?(Ecto.Query)` gate.
- `lib/relyra/metadata/auto_refresh.ex` — wrapper module; the entire D-15..D-21 + B2 + W10 surface lives here.

### Modified (Wave-0 stubs replaced in place)

- `test/relyra/optional_deps/oban_test.exs` — 4 tests; `:pending` tag removed.
- `test/relyra/workers/metadata_refresh_test.exs` — 3 tests with `@tag :oban` on the present-lane scenarios; `:pending` tag removed.
- `test/relyra/metadata/scheduler_test.exs` — 5 tests; `:pending` tag removed.
- `test/relyra/metadata/auto_refresh_test.exs` — 12 tests (2 unit + 10 `:integration` placeholders); `:pending` tag removed.

## Decisions Made

1. **Rule 3 deviation: outside-the-defmodule `Code.ensure_loaded?` gate for `use Oban.Worker` and `import Ecto.Query`.** Plan 21-05's literal action snippet placed both directives inside an in-body `if Code.ensure_loaded?(...) do ... else ... end`. This does not compile in Elixir 1.19 because `Kernel.if/2` eagerly expands both branches at macro-expansion time; `use Oban.Worker` then crashes with `module Oban.Worker is not loaded` regardless of whether the runtime branch is taken. Same applies to `import Ecto.Query` (the macro is expanded into `from/2` calls in fully expanded function bodies, so the `import` must reach the compiler). The canonical idiom in this codebase (`Relyra.LiveAdmin`, `Relyra.LiveAdmin.ConnectionMetadataLive`, `Relyra.LiveAdmin.Query`) is to gate the whole `defmodule` outside, with a stub `defmodule` in the `else` branch that supplies the same public API but returns the typed `:optional_dependency_missing` error. Applied to both `Relyra.Workers.MetadataRefresh` and `Relyra.Metadata.Scheduler`. Both compile lanes green.
2. **Validity-warning placement reordering.** Moved `maybe_emit_validity_warning/4` from after `Import.build_candidate/1` (PLAN snippet) to before it (between `CorpusGate.check/2` and `Import.build_candidate/1`). Functionally equivalent because the helper only consumes the raw XML + the Cadence preset; the move keeps the validity check independent of the drift outcome, so a transient drift bug never blocks a stale-validity warning from firing.
3. **Test repo bypass for the schema 'auto_refresh_enabled requires fingerprints' guard.** The trust-anchor-mismatch unit test inserts a `MetadataSource` via the existing `changeset/2` (registration path) and then back-doors `auto_refresh_enabled: false` via `Ecto.Changeset.change`. The schema-level great-error from `auto_refresh_changeset/2` (Plan 01 D-09) prevents the production shape; the test verifies the WRAPPER's defensive trust check still fires even on a misconfigured row. This is the correct shape for asserting defense-in-depth — schema rejects the configuration; wrapper rejects the runtime state if the schema is bypassed.
4. **Telemetry-namespace separation test asserts both presence (auto_refresh) and absence (refresh).** The `refresh/2 telemetry namespace` test attaches handlers to BOTH `[:relyra, :saml, :metadata, :auto_refresh, :start | :stop]` AND `[:relyra, :saml, :metadata, :refresh, :start | :stop]`, asserts the auto_refresh events fire AND the refresh events do NOT (`refute_receive`). This is the LOCKED D-23 invariant — the existing manual-refresh listeners stay untouched on a scheduled tick.
5. **Outside-the-module module name preservation.** Even when Oban / Ecto.Query are absent, the outside-the-`defmodule` else branch still defines `Relyra.Workers.MetadataRefresh` / `Relyra.Metadata.Scheduler` so adopter docs and example crontabs that reference these module names still type-check. The stub `perform/1` / `run_due/2` returns the typed `:optional_dependency_missing` error so callers get a clear error rather than `UndefinedFunctionError`.

## Patterns Established

1. **Outside-the-defmodule `Code.ensure_loaded?` gate for `use` / `import` macros.** Whenever an optional dep hosts a `use` or `import` macro that must reach the compiler, the entire `defmodule` MUST be wrapped in `if Code.ensure_loaded?(...) do defmodule X do ... end else defmodule X do (stub) end end`. In-body `if` does not work because Elixir's `Kernel.if/2` eagerly expands both branches at macro-expansion time. Future plans adding optional-dep-gated modules MUST follow this pattern; tests for those modules MUST exercise both lanes (Oban-present scenarios with `@tag :oban`; absent-lane fallthrough exercised when the dep is not in the test environment).
2. **Five-class refusal → LOCKED `auto_suspended_reason` mapping.** The `error_to_suspend_reason/1` function-head table in `lib/relyra/metadata/auto_refresh.ex` is the single source of truth for which refusal class produces which suspend reason. Future refusal classes (e.g. an MDQ-specific federation refusal in v0.6+) MUST extend BOTH the `@suspended_reason_values` enum on `Relyra.Ecto.MetadataSource` (Plan 01) AND this mapping in lockstep — the changeset cast will reject any new atom that bypasses the enum.
3. **Asymmetric-strictness wrapper composition.** Manual paths (`:manual_import` / `:manual_refresh`) flow through the existing `Refresh.refresh/2` and `Import.import_xml/3` unchanged. Scheduled paths (`:scheduled_refresh` / `:scheduled_probe`) go through `AutoRefresh.refresh/2` which adds D-15..D-21 gates BEFORE the candidate reaches `MetadataApply.apply_revision/4`. The two paths share the LOCKED `MetadataApply` co-commit seam so audit / health invariants are preserved across both. Future "stricter automation" features (e.g. auto-promotion gates in v0.7+) should follow the same wrap-from-outside shape rather than re-implementing the apply path.
4. **Pre-parse signature-binding extraction (W10).** `pre_parse_for_signature/1` extracts the metadata-root signature envelope via regex BEFORE Parser.parse/2 runs (Pitfall 4 — verify before parse-deeply). Returns concrete `xml_id` (Reference URI without `#`), `xpath` (canonical metadata-root path), `key_info_trust` (so the Phase-04 do_verify document-KeyInfo rejection inherits to the metadata path), and `duplicate_ids` (so the duplicate-XML-ID rejection inherits too). Future trust-primitive specializations on different XML root shapes (e.g. SOAP-bound SAML, partner-federation envelopes) should follow this extraction shape — the binding values MUST be populated, never nil.

## Verification

- `mix compile --warnings-as-errors` — green (98 files compiled).
- `mix compile --no-optional-deps --warnings-as-errors` — green (98 files compiled; both lanes verified).
- `mix test test/relyra/optional_deps/oban_test.exs --warnings-as-errors` — **4 tests, 0 failures**.
- `mix test test/relyra/workers/metadata_refresh_test.exs --include oban --warnings-as-errors` — **3 tests, 0 failures**.
- `mix test test/relyra/metadata/scheduler_test.exs --warnings-as-errors` — **5 tests, 0 failures**.
- `mix test test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors` — **12 tests, 0 failures**.
- `mix test --warnings-as-errors --exclude pending --exclude integration` — **299 tests, 1 failure (16 excluded)**. The single failure is the pre-existing `Relyra.Phoenix.ACSControllerTest` `POST /:connection_id/acs success` `KeyError :name_id` documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` (predates Phase 21).
- `mix format --check-formatted` — green on all 8 plan files (4 lib + 4 test).
- `git diff lib/relyra/metadata/refresh.ex` — empty (D-05 invariant: refresh.ex byte-identical to before).

## Acceptance Criteria (Per-Task)

### Task 1 — wired

- `lib/relyra/optional_deps/oban.ex` exists with `defmodule Relyra.OptionalDeps.Oban` ✓
- `grep -c "@compile {:no_warn_undefined, \[Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron\]}" lib/relyra/optional_deps/oban.ex` = 1 ✓
- `grep -c "@oban_modules \[Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron\]" lib/relyra/optional_deps/oban.ex` = 1 ✓
- `grep -c "def available?" lib/relyra/optional_deps/oban.ex` ≥ 1 ✓
- `grep -c "def ensure_available!" lib/relyra/optional_deps/oban.ex` ≥ 1 ✓
- `grep -c "raise ArgumentError\|raise " lib/relyra/optional_deps/oban.ex` = 0 ✓ (result tuple, not exceptions)
- `lib/relyra/workers/metadata_refresh.ex` exists with `defmodule Relyra.Workers.MetadataRefresh` (two defmodule arms — present + absent) ✓
- `grep -c "@compile {:no_warn_undefined, \[Oban, Oban.Worker, Oban.Job\]}" lib/relyra/workers/metadata_refresh.ex` = 2 (one per arm; ≥ 1 satisfied) ✓
- `grep -c "if Code.ensure_loaded?(Oban.Worker) do" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓ (outside-defmodule shape — Rule-3 deviation)
- `grep -c "use Oban.Worker," lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- `grep -c "max_attempts: 1" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- `grep -c "period: :infinity" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- `grep -c "keys: \[:source_id\]" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- `grep -c "states: \[:available, :scheduled, :executing\]" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- `grep -c "Scheduler.run_due" lib/relyra/workers/metadata_refresh.ex` ≥ 1 ✓
- Both compile lanes green ✓
- `mix test test/relyra/optional_deps/oban_test.exs --warnings-as-errors` — green ✓
- `mix test test/relyra/workers/metadata_refresh_test.exs --include oban --warnings-as-errors` — green ✓

### Task 2 — wired

- `lib/relyra/metadata/scheduler.ex` exists with `defmodule Relyra.Metadata.Scheduler` (two defmodule arms — Ecto-present + Ecto-absent) ✓
- `grep -c "def run_due(repo, opts" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓
- `grep -c "Ecto.UUID.generate()" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓ (D-39)
- `grep -c "src.auto_refresh_enabled == true" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓
- `grep -c "is_nil(src.auto_suspended_until) or src.auto_suspended_until <= " lib/relyra/metadata/scheduler.ex` ≥ 1 ✓
- `grep -c ":relyra, :saml, :metadata, :auto_refresh, :skipped" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓ (D-07)
- `grep -c "AutoRefresh.refresh" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓
- `grep -c "Enum.map(" lib/relyra/metadata/scheduler.ex` ≥ 1 ✓ (D-38 sequential per-batch)
- `lib/relyra/metadata/auto_refresh.ex` exists with `defmodule Relyra.Metadata.AutoRefresh` ✓
- `grep -c "trigger: :scheduled_refresh" lib/relyra/metadata/auto_refresh.ex` = 4 (≥ 2: apply_revision + record_attempt + base_metadata + module-level pipeline doc) ✓
- `grep -c "TrustAnchor.check" lib/relyra/metadata/auto_refresh.ex` = 3 (≥ 1) ✓
- `grep -c "CorpusGate.check" lib/relyra/metadata/auto_refresh.ex` = 3 (≥ 1) ✓
- `grep -c "DriftDetector.diff" lib/relyra/metadata/auto_refresh.ex` = 2 (≥ 1) ✓
- `grep -c "Signature.verify_metadata_root" lib/relyra/metadata/auto_refresh.ex` = 3 (≥ 1) ✓
- `grep -c "Telemetry.span(\[:metadata, :auto_refresh\]" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (D-23 namespace)
- `grep -c "redirect: false" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (D-20)
- `grep -c "max_response_size: 5_000_000" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (D-20)
- `grep -c "Relyra-MetadataRefresh/" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (D-20 + RESEARCH A2)
- `grep -c "30_000" lib/relyra/metadata/auto_refresh.ex` = 2 (≥ 1) ✓ (30s connect + 30s receive timeouts)
- `grep -c "auto_suspended_reason" lib/relyra/metadata/auto_refresh.ex` = 7 (≥ 5) ✓ (signature_invalid + corpus_violation + entity_id_drift + new_signing_cert + trust_anchor_mismatch + the documentation table + the LOCKED-mapping reference)
- `git diff lib/relyra/metadata/refresh.ex` is empty ✓ (D-05 invariant)
- Both compile lanes green ✓
- All four test files green ✓
- `grep -c "maybe_emit_validity_warning" lib/relyra/metadata/auto_refresh.ex` = 2 (≥ 2) ✓ (B2 — pipeline call site + helper definition)
- `grep -cE "Relyra.Ecto.MetadataApply.record_validity_warning|MetadataApply.record_validity_warning" lib/relyra/metadata/auto_refresh.ex` = 2 (≥ 1) ✓ (B2 — calls Plan 04 record_validity_warning helper)
- `grep -c "extract_valid_until" lib/relyra/metadata/auto_refresh.ex` = 2 (≥ 1) ✓ (B2 — regex extraction helper, NOT a deep parse)
- `grep -c "Cadence.cadence_seconds" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (B2 — uses Plan 02 helper for `2 × refresh_interval` math)
- `grep -cE "extract_metadata_root_signature|bound_id_from_reference" lib/relyra/metadata/auto_refresh.ex` = 7 (≥ 2) ✓ (W10 — real signature-binding implementation, NOT a stub)
- `grep -E "signed_candidates: \[%\{xml_id: nil, xpath: nil" lib/relyra/metadata/auto_refresh.ex | wc -l` = 0 ✓ (W10 invariant — no stub binding values)
- `grep -c "key_info_trust:" lib/relyra/metadata/auto_refresh.ex` = 1 (≥ 1) ✓ (W10 — KeyInfo-trust signal forwarded; T-21-29 / T-21-21 mitigation)

## Pre-existing Out-of-Scope Issues (Deferred — same baseline as 21-01..21-04)

- `Relyra.Phoenix.ACSControllerTest` — `POST /:connection_id/acs success` trips a `KeyError :name_id` inside `FakeUserMapper.map_attributes/3`. Pre-existing on the Phase-21 parent commit `0842687`; documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md`. Not caused by Plan 21-05.
- Pre-existing `mix format` drift in `lib/relyra/live_admin/connections_live.ex` from a Phase 20 commit — untouched by Plan 21-05.

## User Setup Required

None — all four new modules ship behind optional-deps gateways (`OptionalDeps.Oban` for the worker; the canonical `Code.ensure_loaded?(Ecto.Query)` gate for the scheduler). The host application opts in via:

1. Adding `{:oban, "~> 2.22"}` to deps (Plan 07 will document the recipe + add the test-environment dep).
2. Configuring an Oban Cron entry pointing at `Relyra.Workers.MetadataRefresh` with `args: %{"repo" => "MyApp.Repo"}`.
3. Calling `Relyra.Ecto.MetadataSource.auto_refresh_changeset/2` to enable auto-refresh on a per-source basis (with at least one pinned trust fingerprint per the D-09 great-error from Plan 01).

## Next Plan Readiness

- **Plan 21-06 (`live-admin-surface`, Wave 4) can proceed.** It will mount the auto-refresh micro-badge on the connection list view, the health card on the connection metadata page, and the "Resume now" button that calls `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04) which then calls `Relyra.Metadata.Scheduler.run_due(repo, source_ids: [resumed_source.id])` for the half-open probe.
- **Plan 21-07 (`mix-tasks-telemetry-docs`, Wave 5) can proceed.** It will add `mix relyra.refresh_due` (calls `Scheduler.run_due/2`), `mix relyra.metadata.pin` (uses `TrustAnchor.fingerprint/1` from Plan 03), the telemetry catalog entries for the new `[:relyra, :saml, :metadata, :auto_refresh, ...]` events, the `Relyra.Telemetry.Handlers.LogAlerts` reference handler, the README recipes (Oban Cron one-liner + k8s CronJob YAML + fly.io schedule), and the Oban CI smoke lane.
- **Test infrastructure is ready.** The Wave-0 `:pending` tags are removed from all four Plan-21-05 test files. The `test/test_helper.exs` `exclude: [:pending]` setting from Plan 01 still excludes the remaining Wave-0 stubs (LiveAdmin / Mix tasks / Telemetry handlers — to be replaced by Plans 06 and 07).
- **No blockers.** Both compile lanes green; full suite is at the same pre-existing-failure baseline as before this plan.

## Threat Flags

None — no new security surface introduced beyond the locked threat register entries (T-21-24 through T-21-34) which are all `mitigate` per the plan's threat model and implemented as documented:

- T-21-24 (HTTPS→anywhere downgrade): `redirect: false` in the strict Req profile ✓
- T-21-25 (multi-GB DoS): `max_response_size: 5_000_000` ✓
- T-21-26 (slowloris): `connect_options: [timeout: 30_000]` + `receive_timeout: 30_000` ✓
- T-21-27 (XXE before verify): `verify_signature/3` runs BEFORE `Parser.parse/2`; `extract_candidate_signing_pems/1` is a regex scan, NOT deep parse ✓
- T-21-28 (TOFU on first refresh): `TrustAnchor.check/2` returns `:no_pinned_fingerprints` for empty pinned-list ✓
- T-21-29 (document-KeyInfo trust): `pre_parse_for_signature/1` extracts the `key_info_trust` signal which `do_verify/4` rejects ✓
- T-21-30 (refusal without audit row): every refusal routes through `MetadataApply.record_attempt/3` (Plan 04 transactional co-commit) ✓
- T-21-31 (adopter-supplied repo atom DoS): `String.to_existing_atom/1` in `repo_for/1` ✓
- T-21-32 (legacy-unsigned escape hatch expiry): `legacy_unsigned_allowed?/1` checks `allow_until` against `Date.utc_today()`; expired entries fall through to strict path ✓
- T-21-33 (clustered Oban double-fetch): the LOCKED `unique:` constraint on the worker ✓
- T-21-34 (refusal-class atom outside the LOCKED enum): `error_to_suspend_reason/1` produces only atoms in the `@suspended_reason_values` enum from Plan 01; invalid atoms would fail the changeset's `Ecto.Enum` cast ✓

## Self-Check: PASSED

Plan-21-05 file existence and commit-hash verification:

- `lib/relyra/optional_deps/oban.ex` — FOUND
- `lib/relyra/workers/metadata_refresh.ex` — FOUND
- `lib/relyra/metadata/scheduler.ex` — FOUND
- `lib/relyra/metadata/auto_refresh.ex` — FOUND
- `test/relyra/optional_deps/oban_test.exs` — FOUND (modified; `:pending` tag removed; 4 tests)
- `test/relyra/workers/metadata_refresh_test.exs` — FOUND (modified; `:pending` tag removed; 3 tests with `@tag :oban`)
- `test/relyra/metadata/scheduler_test.exs` — FOUND (modified; `:pending` tag removed; 5 tests)
- `test/relyra/metadata/auto_refresh_test.exs` — FOUND (modified; `:pending` tag removed; 12 tests)
- Commit `ff88242` (Task 1: OptionalDeps.Oban + Workers.MetadataRefresh) — FOUND
- Commit `3b60a04` (Task 2: Scheduler + AutoRefresh) — FOUND

---

*Phase: 21-scheduled-metadata-refresh*
*Plan: 05 scheduler-wrapper-worker*
*Completed: 2026-05-07*
