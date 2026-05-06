---
status: complete
mode: shift-left
phase: 11-mapping-persistence-audit-hardening
source:
  - 11-01-SUMMARY.md
  - 11-02-SUMMARY.md
  - 11-03-SUMMARY.md
  - 11-04-SUMMARY.md
started: 2026-05-06T00:38:00Z
updated: 2026-05-06T00:54:20Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Tests

### 1. Mapping persistence boundaries and runtime contract
expected: Runtime connections expose plain `mapping_config` data, parent connection writes reject hidden mapping mutations, and live mapping plus ledger schemas stay bounded and explicit.
result: pass
evidence:
  - "2026-05-05 summary verification commands for 11-01 passed."
  - "2026-05-06 local run: schema and runtime-focused smoke suite passed (14 tests, 0 failures)."

### 2. Mapping and audit persistence DDL
expected: Canonical tables, FK ownership, uniqueness, and append-only ledger constraints exist without pushing mapping blobs into `relyra_connections`.
result: pass
evidence:
  - "2026-05-05 summary verification commands for 11-02 passed."
  - "2026-05-06 local run: phase suite including migration constraints passed (59 tests, 0 failures)."

### 3. Audited trust mutations across connection, metadata, and certificate flows
expected: Successful trust mutations append durable attributable audit rows in the same transaction, and failed or conflicting writes leave no orphan audit rows.
result: pass
evidence:
  - "2026-05-05 summary verification commands for 11-03 passed."
  - "2026-05-06 local run: phase suite including audit hardening, connection record, metadata apply, and certificate transition coverage passed (59 tests, 0 failures)."

### 4. Dedicated mapping commands and runtime hydration
expected: Dedicated mapping commands replace live rules transactionally, append mapping revisions and audit events, and resolved runtime connections consume persisted normalized rules before fallback behavior.
result: pass
evidence:
  - "2026-05-05 summary verification commands for 11-04 passed."
  - "2026-05-06 local run: mapping command and runtime hydration smoke suite passed (14 tests, 0 failures)."
  - "2026-05-06 local run: full Phase 11 verification suite passed (59 tests, 0 failures)."

### 5. Audit timeline reviewability
expected: Reviewing representative audit rows across connection, metadata, certificate, and mapping mutations should answer who changed what, why, and what trust state changed without exposing raw XML, PEM, or private key material.
result: pass
evidence:
  - "2026-05-06 local run: extended `test/relyra/ecto/audit_hardening_test.exs` cross-domain verification passed."
  - "Representative connection, metadata, certificate, and mapping audit rows were asserted for actor/cause attribution, typed changed-field summaries, revision references, and redaction of XML/PEM payloads."

### 6. Runtime mapping_config ergonomics
expected: The final `%Relyra.Connection{}` runtime shape and mapper call path should expose coherent normalized field names and deterministic ordering while staying persistence-agnostic for host apps.
result: pass
evidence:
  - "2026-05-06 local run: `test/relyra/connection_snapshot_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs`, and `test/relyra/ecto/ecto_connection_resolver_test.exs` passed with explicit runtime contract assertions."
  - "`mapping_config` is verified as the only runtime mapping surface, with deterministic normalized ordering and persisted-rules-first mapper behavior."

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
