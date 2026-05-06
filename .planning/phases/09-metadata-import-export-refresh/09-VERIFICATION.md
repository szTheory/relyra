# Phase 09 Verification

## Scope

This artifact closes `CFG-03` milestone verification for Phase 09 by recording the repaired automated evidence packet required by Phase 12 Plan `12-03` and the completed manual approval gate.

## Requirement Traceability

Requirement: `CFG-03` - User can import and export metadata for a connection and trigger a controlled refresh with provenance.

| CFG-03 behavior | Proof source | Evidence |
| --- | --- | --- |
| Metadata import | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors` | Focused serial smoke run passed with `15 tests, 0 failures`. `test/relyra/metadata_test.exs` covers local XML import, deterministic endpoint normalization, typed invalid input rejection, and remote source registration. `test/relyra/ecto/metadata_apply_test.exs` covers transactional apply and rollback. |
| Metadata export | `test/phoenix/metadata_controller_test.exs`; `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` | Controller coverage confirms `GET /:connection_id/metadata` renders from the canonical resolver snapshot and preserves typed failures. Phase `09-04` summary records snapshot-only export regression coverage and confirms metadata export avoids live fetches and metadata-table reads. |
| Controlled refresh | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors`; `mix test --warnings-as-errors`; `test/relyra/metadata_refresh_test.exs`; `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` | Focused serial smoke run passed with `15 tests, 0 failures`; full serial suite passed with `168 tests, 0 failures`. Refresh coverage proves refresh is explicit, Req-backed, preserves last-known-good runtime state on failure, emits redacted observability, and stages new metadata certificates as `:next` rather than changing active runtime trust. |
| Provenance | `test/relyra/metadata_test.exs`; `test/relyra/ecto/metadata_revision_schema_test.exs`; `test/relyra/ecto/metadata_source_schema_test.exs`; `test/relyra/ecto/metadata_apply_test.exs`; `.planning/phases/09-metadata-import-export-refresh/09-03-SUMMARY.md`; `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` | Schema tests enforce required metadata source and revision provenance fields. Import and apply tests prove `source_kind`, `trigger`, revision persistence, source registration, audit events, and last-known-good pointers. Phase `09-03` and `09-04` summaries record metadata-specific parsing, source registration, explicit refresh, and redacted lifecycle observability. |

## Phase-Audit Gap Closed

Milestone audit gap being closed: `.planning/v0.2-MILESTONE-AUDIT.md` marked `CFG-03` as unsatisfied/orphaned because Phase 09 had no `09-VERIFICATION.md`, and the metadata refresh smoke path previously failed with `:invalid_certificate_pem` during metadata import/refresh apply.

Closure evidence:
- This file now exists as the missing Phase 09 verification artifact.
- The repaired focused Phase 09 smoke packet now passes serially.
- The repaired full test suite now passes serially.
- The required human sign-off on the two manual checks has been recorded below.

## Automated Evidence Packet

Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the audit warning about migration bootstrap race-driven false negatives.

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `2026-05-06T01:58:16Z` | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors` | passed | `15 tests, 0 failures` |
| 2 | `2026-05-06T01:58:24Z` | `mix test --warnings-as-errors` | passed | `168 tests, 0 failures` |

Serial execution note: order `1` completed successfully before order `2` started. No parallel Mix test runs were used for this verification packet.

## Evidence Map

### Import

- `test/relyra/metadata_test.exs` proves `Relyra.Metadata.import_xml/3` applies local XML through the metadata-specific pipeline, records durable typed failures, prefers `HTTP-Redirect` over `HTTP-POST` over remaining SSO endpoints, and rejects malformed certificate input with typed `:invalid_certificate_pem`.
- `test/relyra/ecto/metadata_apply_test.exs` proves the apply boundary persists imported metadata transactionally and rolls back revision and certificate changes on invalid certificate data.

### Export

- `test/phoenix/metadata_controller_test.exs` proves public metadata export renders from the canonical resolver snapshot and preserves typed resolver failures.
- `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` records the export invariant explicitly: snapshot-only export regression coverage and no live fetches on the metadata endpoint.

### Controlled Refresh

- `test/relyra/metadata_refresh_test.exs` proves refresh fetches only when explicitly invoked, requires configured `Req`, applies a new metadata revision through the same write path, preserves the applied runtime snapshot on failed refresh, and emits redacted observability.
- `test/relyra/ecto/metadata_apply_test.exs` proves the shared apply seam preserves active runtime trust while newly discovered metadata signing certificates remain staged as `:next`.
- `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` records that refresh remains operator-triggered only and does not shift runtime trust implicitly.

### Provenance

- `test/relyra/metadata_test.exs` proves source registration persists one HTTPS metadata source per connection without mutating runtime resolver state.
- `test/relyra/ecto/metadata_revision_schema_test.exs` proves metadata revisions require provenance fields including `source_kind`, `trigger`, `outcome`, and `trust_summary`.
- `test/relyra/ecto/metadata_source_schema_test.exs` proves metadata sources require provenance fields and reject non-HTTPS URLs.
- `test/relyra/ecto/metadata_apply_test.exs` proves failed attempts persist as metadata revisions without mutating the runtime aggregate and that audit events are emitted for staged certificate and metadata-apply operations.
- `.planning/phases/09-metadata-import-export-refresh/09-03-SUMMARY.md` and `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` record the intended provenance model across import, source registration, refresh, and observability.

## Manual Sign-Off

The automated packet is complete, and the manual-only approval gate is now signed off:

1. Confirm the chosen SSO endpoint selection still reads as the intended least-surprise behavior, with `HTTP-Redirect` preferred over `HTTP-POST` over remaining endpoints.
2. Confirm `Relyra.Metadata.import_xml/3`, `register_source/3`, and `refresh/2` still read as explicit write-side metadata management operations rather than runtime request-path behavior.

Human review result:
- Approved on `2026-05-05`.
- The endpoint-selection rule still reads as the intended least-surprise runtime behavior, with `HTTP-Redirect` preferred before `HTTP-POST` before remaining endpoints.
- `Relyra.Metadata.import_xml/3`, `register_source/3`, and `refresh/2` still read as explicit metadata-management entrypoints rather than implicit runtime-resolution behavior.

Manual approval status: approved.
