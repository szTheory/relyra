---
phase: 9
slug: metadata-import-export-refresh
status: ready_for_verify
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with optional Ecto SQL Sandbox-backed integration tests and optional `Req.Test` refresh stubs |
| **Config file** | `test/test_helper.exs` and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 45 seconds for the phase-focused smoke commands |

---

## Sampling Rate

- **After every task commit:** Run the task-focused metadata/import/apply test plus `mix format --check-formatted`
- **After every plan wave:** Run `mix compile --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green
- **Max feedback latency:** < 45 seconds for the phase-focused smoke commands

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-T01 | 09-01 | 1 | CFG-03 | TM-09-01-PROVENANCE-GAP | Metadata source and revision persistence are append-only and preserve explicit active/last-known-good pointers | integration | `mix test test/relyra/ecto/metadata_revision_schema_test.exs test/relyra/ecto/metadata_source_schema_test.exs test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |
| 09-02-T01 | 09-02 | 2 | CFG-03 | TM-09-02-ATOMIC-APPLY | Connection/certificate apply writes stay atomic and rollback preserves the previous live snapshot | integration | `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |
| 09-03-T01 | 09-03 | 3 | CFG-03 | TM-09-03-PARSER-MISMATCH | Local XML import parses metadata documents through a metadata-specific seam, not the response-only parser | unit | `mix test test/relyra/metadata_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |
| 09-03-T02 | 09-03 | 3 | CFG-03 | TM-09-03-PARSER-MISMATCH | Imported metadata normalizes to one deterministic candidate and source registration records provenance without HTTP fetches | unit/integration | `mix test test/relyra/metadata_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |
| 09-04-T01 | 09-04 | 4 | CFG-03 | TM-09-04-LIVE-FETCH-LEAK | Manual refresh fetches under explicit operator control only and never changes runtime trust on candidate failure | integration | `mix test test/relyra/metadata_refresh_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |
| 09-04-T02 | 09-04 | 4 | CFG-03 | TM-09-04-REDACTION-DRIFT | Public SP metadata export stays snapshot-only and logs/telemetry emit identifiers, timings, counts, and outcomes only | unit/integration | `mix test test/relyra/metadata_refresh_test.exs test/relyra/telemetry_test.exs test/phoenix/metadata_controller_test.exs --warnings-as-errors` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/relyra/metadata_test.exs` — local XML import, candidate normalization, and typed failure coverage
- [x] `test/relyra/metadata_refresh_test.exs` — optional Req-backed refresh, last-known-good preservation, and observability redaction coverage
- [x] `test/relyra/ecto/metadata_apply_test.exs` — revision ledger, pointer updates, certificate apply, and rollback coverage
- [x] Refresh-path fixtures proving telemetry/log payloads exclude raw XML and PEM blobs

Wave 0 is complete only when the missing metadata-specific tests exist and the new phase-focused smoke commands run green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Imported metadata collapses multiple published SSO endpoints into one predictable v0.2 runtime value | CFG-03 | Automated tests can prove the parser rule, but a human should still confirm the chosen runtime semantics are the intended least-surprise operator behavior | Review the fixed priority rule in `09-03-PLAN.md` and resulting docs/tests to confirm the same endpoint wins across import and refresh |
| Operator-facing refresh semantics stay distinct from runtime resolution semantics | CFG-03 | Automated tests can prove isolation, but the wording of APIs and docs still needs a human pass for least-surprise DX | Review `Relyra.Metadata.import_xml/3`, `register_source/3`, and `refresh/2` docs/error text to confirm they read as explicit write-side verbs rather than request-path runtime behavior |

---

## Validation Sign-Off

- [x] All planned tasks have an automated verification target
- [x] Wave 0 explicitly calls out the missing metadata-specific test files
- [x] Sampling continuity is preserved across persistence, parser, refresh, export, and observability work
- [x] Manual checks are limited to product-rule and DX-review items that are hard to prove mechanically
- [x] `nyquist_compliant: true` set in frontmatter once Wave 0 and task verification are complete

**Approval:** pending
