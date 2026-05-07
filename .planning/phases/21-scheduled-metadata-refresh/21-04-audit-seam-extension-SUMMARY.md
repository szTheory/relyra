---
phase: 21-scheduled-metadata-refresh
plan: 04
subsystem: persistence
tags: [ecto, transact, telemetry, signature, audit, exunit]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: MetadataSource.health_state_changeset/2 (the LOCKED 9-field cast surface that EVERY Phase-21 health write goes through) + the auto_refresh / health-state column set extended on relyra_metadata_sources
  - phase: 21-scheduled-metadata-refresh
    plan: 02
    provides: Relyra.Metadata.Cadence.next_refresh_at/2, Relyra.Metadata.Backoff.backoff_until/2 + suspend_threshold/0, Relyra.Metadata.FailureClassifier.classify/1 — the three pure helpers consumed inside the transact block
  - phase: 11-mapping-persistence-and-audit-hardening
    provides: Relyra.Ecto.AuditWriter.append_event/2 (single audit-writer seam, D-35) — Plan 21-04 reuses it twice, both inside transact blocks
provides:
  - Relyra.Ecto.MetadataApply.record_attempt/3 — now wrapped in transact/2 with co-committed health-state side-effect for scheduled triggers (D-28)
  - Relyra.Ecto.MetadataApply.apply_revision/4 — :applied branch resets the full health state on scheduled apply per Pitfall 6 + unions cert fingerprints into last_known_metadata_signing_certs (D-18)
  - Relyra.Ecto.MetadataApply.record_validity_warning/3 — at-most-once-per-validUntil seam (D-14): co-commits last_validity_warning_for + the :validity_warning telemetry event in ONE transact block
  - Relyra.Ecto.MetadataApply.resume_auto_refresh/3 — single-transaction "Resume now" seam (D-28 + A3): co-commits suspend-clear health write + audit row with cause "live_admin_auto_refresh_resume"
  - Relyra.Security.Signature.verify_metadata_root/4 — thin shim over the existing do_verify/4 trust primitive; reuses every rejection (empty cert chain, document-KeyInfo, duplicate XML IDs, algorithm policy) and only differs in the telemetry payload's :flow tag (:metadata_refresh vs :sp_initiated)
  - Three D-24 state-transition telemetry events emitted INSIDE the same transact block as the health-state write: [:relyra, :saml, :metadata, :auto_refresh, :degraded] / :suspended / :recovered with the LOCKED payload shape (correlation_id, source_id, connection_record_id, error_code, consecutive_failure_count, auto_suspended_reason, transient?, counts_toward_suspend?)
  - Extended Relyra.Ecto.MetadataRevision.@trigger_values with :scheduled_refresh + :scheduled_probe (Rule 3 deviation — Plan 21-01 did not enumerate these, blocking scheduled-refresh revision inserts)
affects: [21-05-scheduler-wrapper-worker, 21-06-live-admin-surface, 21-07-mix-tasks-telemetry-docs]

tech-stack:
  added: []  # no new dependencies; reuses existing Ecto, :telemetry, AuditWriter
  patterns:
    - "Phase-21 D-28 single-transaction discipline: every health-state mutation co-commits inside the same Repo.transact/1 block as the MetadataRevision row + audit row. Health-state writes that drift outside the transact block would let consecutive_failure_count increment without an audit row, breaking the auditability invariant."
    - "Trigger-gated side-effect (manual-path invariance): Phase-21 health writes only fire when trigger ∈ {:scheduled_refresh, :scheduled_probe}. The manual paths (:manual_import / :manual_refresh) flow through the SAME record_attempt/3 / apply_revision/4 entry points but skip the side-effect — Phase 9/12 behavior is byte-identical."
    - "Telemetry-from-inside-transaction with classification stash: emit_state_transitions/3 fires :degraded / :suspended / :recovered events INSIDE the transact block. The classification (transient? / counts_toward_suspend?) is stashed under private keys (:_phase21_classification, :_phase21_correlation_id) on the attrs map and stripped before MetadataSource.health_state_changeset/2 cast — keeps the LOCKED 9-field cast surface intact while still threading the classification through to the telemetry payload."
    - "Thin-shim trust-primitive reuse (Signature.verify_metadata_root/4): the metadata-root verifier reuses the SAME do_verify/4 private path verify/4 uses; only the telemetry :flow tag differs (:metadata_refresh vs :sp_initiated). Document-KeyInfo / empty-cert-chain / duplicate-XML-ID / algorithm-policy rejections are inherited automatically — no parser differential possible."

key-files:
  created: []
  modified:
    - lib/relyra/ecto/metadata_apply.ex   # 419 → 974 LOC; +555 LOC adding transact wrap, health-state side-effects, validity warning seam, resume seam, state-transition telemetry, format hardening
    - lib/relyra/ecto/metadata_revision.ex   # @trigger_values extended with :scheduled_refresh + :scheduled_probe (Rule 3 deviation)
    - lib/relyra/security/signature.ex   # 148 → 205 LOC; +57 LOC adding verify_metadata_root/4 shim
    - test/relyra/ecto/metadata_apply_test.exs   # 386 → 973 LOC; +587 LOC; 5 → 25 tests (20 new Phase-21 tests across 4 describe blocks)
    - test/relyra/security/signature_test.exs   # Wave-0 :pending stub (26 LOC) → 113 LOC of green tests; 0 → 5 tests

key-decisions:
  - "Rule 3 deviation: extended Relyra.Ecto.MetadataRevision.@trigger_values with :scheduled_refresh and :scheduled_probe. Plan 21-01 introduced the source-side cadence/health columns but DID NOT extend the trigger enum on the revision schema, leaving scheduled-refresh attempts uninsertable. Caught when the first scheduled-refresh test failed at MetadataRevision.changeset/2 cast time. Single-line edit; surfaces in this plan's commit so the Plan 05 wrapper has the trigger atoms it needs."
  - "Rule 1 deviation: hardened format_changeset_errors/1 in MetadataApply against parameterized Ecto types. When Ecto.Enum rejects a cast (e.g. an invalid auto_suspended_reason atom), the changeset error opts include a :type tuple ({:parameterized, {Ecto.Enum, %{...}}}) which String.Chars does not implement. The original to_string/1 in the error formatter crashes with Protocol.UndefinedError. Added safe_to_string/1 that falls back to inspect/1 on Protocol.UndefinedError — keeps the formatter total. Caught by the single-transaction-rollback test injecting an invalid Enum atom."
  - "Trade-off accepted: emit_state_transitions/3 fires telemetry events INSIDE the transact block (vs after-commit). This means a downstream listener that triggers a side-effect on :suspended could see the event even if the surrounding transaction rolls back due to a later step. Mitigation: every event payload carries `correlation_id` so the host listener (e.g. Plan 07's LogAlerts handler) can dedupe against an audit row that never landed. The alternative (after-commit emission) would require Ecto.Multi rewiring — out of scope for this plan and structurally inconsistent with the existing telemetry pattern around apply_revision/4. Pattern documented in the telemetry catalog comment block in metadata_apply.ex."
  - "AuditWriter.append_event/3 → /2 contract correction. The plan referenced `AuditWriter.append_event(repo, :metadata_auto_refresh_resume, audit_context)` (3-arity with an event-type atom). The actual existing seam from Plan 11 is `append_event(repo, attrs)` (2-arity, with `domain: ..., action: ...` inside attrs). Plus, the AuditEvent schema's @action_values doesn't include :metadata_auto_refresh_resume — the closest schema-allowed action for 'schedule resumed' is :refreshed. Adapted the call to `domain: :metadata, action: :refreshed, cause: 'live_admin_auto_refresh_resume'` per the existing contract. The single-audit-writer-seam invariant (D-35) is preserved — exactly two append_event call sites in the file, both inside transact blocks."
  - "format_datetime/1 helper added for the resume-audit before_view. AuditWriter.normalize_summary/1 walks every value as Enumerable; %DateTime{} is a struct not an Enumerable, so passing source.auto_suspended_until raw into the audit attrs crashes the normalization walk. Format to ISO8601 string before handoff. (Caught by the resume-co-commit test on first run.)"

requirements-completed: []  # CFG-08 is multi-plan; this plan delivers the audit-seam extensions Plan 05 will consume but does NOT close CFG-08 — that ships in Phase 21 W5 (Plan 21-07).

duration: ~10min
completed: 2026-05-07
---

# Phase 21 Plan 04: Audit Seam Extension Summary

**Extends the single audit-writer seam (`MetadataApply.record_attempt/3` + `apply_revision/4`) so EVERY scheduled-refresh attempt's health-state mutation co-commits inside the same `Repo.transact/1` block as the `MetadataRevision` row + audit row (D-28), adds three D-24 state-transition telemetry events fired from inside that same block, the `record_validity_warning/3` at-most-once seam (D-14), the single-transaction `resume_auto_refresh/3` Resume-now seam (A3), and the thin `Signature.verify_metadata_root/4` shim that reuses `do_verify/4` verbatim but tags telemetry with `flow: :metadata_refresh` (D-16).**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-07T02:31:14Z (UTC) — pre-Task-1 read-throughs
- **Completed:** 2026-05-07T02:40:53Z (UTC) — Task 3 commit `b94ce16`
- **Tasks:** 3 / 3
- **Files modified:** 5 (3 production modules + 2 test files)

## Accomplishments

### Task 1: `record_attempt/3` transact wrap + health-state co-commit

- `record_attempt/3` is now wrapped in `transact/2` and routes scheduled triggers (`:scheduled_refresh`, `:scheduled_probe`) through `maybe_update_health_state_on_attempt/2`. Manual triggers (`:manual_import`, `:manual_refresh`) skip the side-effect entirely — Phase 9/12 behavior is byte-identical.
- Failure path: `compute_failure_health_state/3` consults `FailureClassifier.classify/1`. Transient codes (e.g. `:fetch_timeout`) increment `consecutive_failure_count` and set `last_failure_error_code`; at the suspend threshold of 5, `maybe_put_suspend/4` sets `auto_suspended_until` via `Backoff.backoff_until/2` and `auto_suspended_reason` (default `:transient_failures_exceeded`, overridable by callers via `attrs[:auto_suspended_reason]` for drift / signature / corpus paths). Suspicious codes (e.g. `:signature_failed`) update `last_failure_error_code` only — no counter increment per D-27.
- Success path: `maybe_reset_health_state_on_apply/3` resets every counter, clears suspend, sets `last_success_at`, advances `next_refresh_at` via `Cadence.next_refresh_at/2`, AND unions the candidate's certificate fingerprints into `last_known_metadata_signing_certs` (Pitfall 6 + D-18).
- D-24 state-transition telemetry events fire INSIDE the transact block via `emit_state_transitions/3`:
  - `:degraded` on first transient failure (count 0 → 1)
  - `:suspended` on the attempt that sets `auto_suspended_until` from nil to a value
  - `:recovered` on a successful apply that clears a previously-set `auto_suspended_until`
  - All payloads carry the LOCKED shape: `correlation_id`, `source_id`, `connection_record_id`, `error_code`, `consecutive_failure_count`, `auto_suspended_reason`, `transient?`, `counts_toward_suspend?`.
- `record_validity_warning/3` (B2): at-most-once-per-`validUntil` seam (D-14). Suppresses re-fire when stored window ≥ candidate window; re-fires when IdP publishes a NEW (later) `validUntil`. Co-commits the `last_validity_warning_for` write + the `:validity_warning` telemetry event in ONE transact block.

### Task 2: `Signature.verify_metadata_root/4` shim

- Thin shim over existing `do_verify/4` private path. The shim only differs from `verify/4` in the telemetry payload's `:flow` tag (`:metadata_refresh` vs `:sp_initiated`).
- Inherits every trust rejection from `do_verify/4`: empty `cert_chain` (D-17), document-`KeyInfo` (CVE-2024-45409), duplicate XML IDs, algorithm-policy enforcement.
- 5 dedicated tests in `test/relyra/security/signature_test.exs` (replacing the Wave-0 `:pending` stub) covering the rejection inheritance + the telemetry flow-tag discriminator (both `:metadata_refresh` and `:sp_initiated` paths covered).

### Task 3: `MetadataApply.resume_auto_refresh/3` single-transaction Resume seam

- `resume_auto_refresh(repo, %MetadataSource{}, %{actor: _})` co-commits the suspend-clear health write (`auto_suspended_until: nil, auto_suspended_reason: nil`) AND the operator-intent audit row inside ONE `transact/2` block.
- Audit row uses the LOCKED `cause: "live_admin_auto_refresh_resume"` per A3, `domain: :metadata, action: :refreshed` (closest schema-allowed action), and propagates `:correlation_id` when supplied.
- Single-audit-writer-seam invariant (D-35) preserved: the file now has exactly 2 `AuditWriter.append_event` call sites — `apply_revision/4` and `resume_auto_refresh/3`. Both inside `transact/2` blocks.
- 2 tests cover the happy-path co-commit AND the rollback-proof case (empty-actor audit failure leaves both source row + audit ledger unchanged).

## Task Commits

1. **Task 1: Wrap record_attempt/3 in transact and co-commit health state** — `2de8899` (feat)
2. **Task 2: Add Signature.verify_metadata_root/4 metadata-root shim** — `35a3da4` (feat)
3. **Task 3: Add MetadataApply.resume_auto_refresh/3 single-tx Resume seam** — `b94ce16` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol).

## Files Created/Modified

### Modified
- `lib/relyra/ecto/metadata_apply.ex` — 419 → 974 LOC. Adds `record_attempt/3` transact wrap + health-state co-commit; `record_validity_warning/3`; `resume_auto_refresh/3`; `apply_revision/4` success-path reset + cert-fingerprint union; `emit_state_transitions/3` (D-24); `format_changeset_errors/1` parameterized-type hardening.
- `lib/relyra/ecto/metadata_revision.ex` — single-line: `@trigger_values` extended with `:scheduled_refresh` + `:scheduled_probe` (Rule 3 deviation).
- `lib/relyra/security/signature.ex` — 148 → 205 LOC. Adds `verify_metadata_root/4` shim (2-clause public function) reusing `do_verify/4` verbatim.
- `test/relyra/ecto/metadata_apply_test.exs` — 386 → 973 LOC; 5 → 25 tests. New describe blocks: "Phase 21: scheduled trigger health-state side-effect" (9 tests), "Phase 21: D-24 state-transition telemetry events (B1)" (6 tests), "Phase 21: resume_auto_refresh/3 (D-28 single-transaction Resume-now seam)" (2 tests), "Phase 21: record_validity_warning/3 (B2)" (3 tests).
- `test/relyra/security/signature_test.exs` — Wave-0 `:pending` stub (26 LOC, 1 flunking test) → 113 LOC, 5 green tests across 2 describe blocks.

## Decisions Made

1. **Rule 3 deviation: extend `MetadataRevision.@trigger_values` with `:scheduled_refresh` + `:scheduled_probe`.** Plan 21-01 added the source-side cadence/health columns but did NOT extend the trigger enum on the revision schema. The first scheduled-refresh test failed at `MetadataRevision.changeset/2` cast time. Single-line fix, surfaced in this plan's commit so Plan 05's wrapper has the trigger atoms it needs.
2. **Rule 1 deviation: harden `format_changeset_errors/1` against parameterized Ecto types.** When `Ecto.Enum` rejects a cast, the changeset error opts include a `:type` tuple (`{:parameterized, {Ecto.Enum, %{...}}}`) which `String.Chars` does not implement. Added `safe_to_string/1` that falls back to `inspect/1` on `Protocol.UndefinedError`. Caught by the single-transaction-rollback test.
3. **Telemetry-from-inside-transaction trade-off.** `emit_state_transitions/3` and the `:validity_warning` emit fire INSIDE the `transact/2` block, not after commit. A downstream listener that side-effects on `:suspended` could see the event even if the surrounding transaction rolls back. Mitigation: every payload carries `correlation_id` so the host can dedupe against an audit row that never landed. The alternative (after-commit emission) would require `Ecto.Multi` rewiring — out of scope and structurally inconsistent with the existing `Telemetry.span` pattern around `apply_revision/4`.
4. **`AuditWriter.append_event/3` → `/2` contract correction.** Plan referred to a 3-arity call with an event-type atom; the actual existing seam from Plan 11 is `append_event(repo, attrs)` (2-arity). Plus, the `AuditEvent` schema's `@action_values` doesn't include `:metadata_auto_refresh_resume` — the closest schema-allowed action is `:refreshed`. Adapted to `domain: :metadata, action: :refreshed, cause: "live_admin_auto_refresh_resume"`. Single-audit-writer-seam invariant (D-35) preserved.
5. **Format `DateTime` values to ISO8601 before audit summary normalization.** `AuditWriter.normalize_summary/1` walks every value as Enumerable; `%DateTime{}` is a struct, not Enumerable. Added `format_datetime/1` helper.

## Patterns Established

1. **Phase-21 D-28 single-transaction discipline.** Every health-state mutation co-commits inside the same `Repo.transact/1` block as the MetadataRevision row + audit row. Reference call sites: `record_attempt/3`, `apply_revision/4`'s `:applied` branch, `record_validity_warning/3`, `resume_auto_refresh/3`. Future plans MUST keep new health-state writes inside one of these existing seams or add a new `transact/2`-wrapped public function — never a `repo.update` from outside.
2. **Trigger-gated side-effect for manual-path invariance.** `scheduled_trigger?/1` (predicate on `:scheduled_refresh` / `:scheduled_probe`) gates EVERY new Phase-21 side-effect inside `record_attempt/3` / `apply_revision/4`. Manual paths flow through the same entry points but skip the side-effect — guaranteeing manual import / manual refresh behavior is byte-identical to Phase 9/12.
3. **Classification stash via private attrs keys.** When a side-effect needs metadata that isn't in the LOCKED cast surface, stash it under a private key (`:_phase21_classification`, `:_phase21_correlation_id`) and `Map.drop` it before the `cast` call. Keeps the cast whitelist intact while still threading values through to telemetry / downstream emit code. Pattern reusable for future LiveView+Mix-task pairs that need to thread context through the audit-writer seam.
4. **Thin-shim trust-primitive reuse.** `Signature.verify_metadata_root/4` reuses `do_verify/4` verbatim — only the telemetry `:flow` tag differs. Future "specialized verify path" needs (e.g. an SP-metadata signing path, a partner-federation signing path) should follow the same shape: don't fork the trust primitive, just add a thin span-and-delegate shim that tags the telemetry payload differently.

## Verification

- `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` — **25 tests, 0 failures** (5 pre-existing + 20 new Phase-21 tests across 4 describe blocks).
- `mix test test/relyra/security/signature_test.exs --warnings-as-errors` — **5 tests, 0 failures** (Wave-0 stub fully replaced; both `:metadata_refresh` and `:sp_initiated` flow tags covered).
- `mix test --warnings-as-errors --exclude pending` — **285 tests, 1 failure (9 excluded)**. The single failure is the pre-existing `Relyra.Phoenix.ACSControllerTest` `:name_id` KeyError documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` (predates Phase 21).
- `mix compile --warnings-as-errors` — green.
- `mix compile --no-optional-deps --warnings-as-errors` — green.
- `mix format --check-formatted` — green on all 5 modified files.

## Acceptance Criteria (Per-Task)

### Task 1 — wired

- `grep -c "alias Relyra.Metadata.{Backoff, Cadence, FailureClassifier}" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "transact(repo, fn ->" lib/relyra/ecto/metadata_apply.ex` = 4 (≥ 2) ✓ (record_attempt + apply_revision + record_validity_warning + resume_auto_refresh)
- `grep -c "defp maybe_update_health_state_on_attempt" lib/relyra/ecto/metadata_apply.ex` = 2 (≥ 1) ✓
- `grep -c "defp maybe_reset_health_state_on_apply" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "scheduled_trigger?(:scheduled_refresh)" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "scheduled_trigger?(:scheduled_probe)" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "FailureClassifier.classify" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "Backoff.backoff_until" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "Cadence.next_refresh_at" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "MetadataSource.health_state_changeset" lib/relyra/ecto/metadata_apply.ex` = 2 (≥ 1) ✓
- `grep -c "def record_validity_warning" lib/relyra/ecto/metadata_apply.ex` = 3 (≥ 1) ✓
- `grep -c ":validity_warning" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c "already_warned_for?" lib/relyra/ecto/metadata_apply.ex` = 3 (≥ 1) ✓
- `grep -c "defp emit_state_transitions" lib/relyra/ecto/metadata_apply.ex` = 1 ✓
- `grep -c ":degraded" / ":suspended" / ":recovered"` each ≥ 1 ✓ (1, 1, 1)
- `grep -c "transient?:\|counts_toward_suspend?:" lib/relyra/ecto/metadata_apply.ex` = 5 (≥ 2) ✓

### Task 2 — wired

- `grep -c "def verify_metadata_root" lib/relyra/security/signature.ex` = 3 (head + 2 clauses) ✓
- `grep -c "flow: :metadata_refresh" lib/relyra/security/signature.ex` = 1 ✓
- `grep -c "flow: :sp_initiated" lib/relyra/security/signature.ex` = 1 ✓
- `grep -c "do_verify(parsed_doc, connection, cert_chain, opts)" lib/relyra/security/signature.ex` = 3 (≥ 2 — verify/4 + verify_metadata_root/4 + the private head) ✓
- `grep -c "key_info_trust" lib/relyra/security/signature.ex` = 1 ✓
- `grep -c "def verify(" lib/relyra/security/signature.ex` = 3 (head + 2 clauses) ✓

### Task 3 — wired

- `grep -c "def resume_auto_refresh" lib/relyra/ecto/metadata_apply.ex` = 3 (head + 2 clauses) ✓
- `grep -c "live_admin_auto_refresh_resume" lib/relyra/ecto/metadata_apply.ex` = 2 (≥ 1; default + doc reference) ✓
- `grep -c "AuditWriter.append_event" lib/relyra/ecto/metadata_apply.ex` = **2 (exactly)** — single-audit-writer-seam invariant preserved ✓
- `grep -c "auto_suspended_until: nil" lib/relyra/ecto/metadata_apply.ex` = 3 (≥ 1) ✓
- `grep -c "auto_suspended_reason: nil" lib/relyra/ecto/metadata_apply.ex` = 3 (≥ 1) ✓

## Self-Check: PASSED

Files (verified to exist):
- `lib/relyra/ecto/metadata_apply.ex` — FOUND
- `lib/relyra/ecto/metadata_revision.ex` — FOUND
- `lib/relyra/security/signature.ex` — FOUND
- `test/relyra/ecto/metadata_apply_test.exs` — FOUND
- `test/relyra/security/signature_test.exs` — FOUND

Commits (verified in git log):
- `2de8899` — Task 1 — FOUND
- `35a3da4` — Task 2 — FOUND
- `b94ce16` — Task 3 — FOUND
