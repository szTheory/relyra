# Roadmap: Relyra

## Milestones

- ✅ **v0.1** - SP-initiated SSO, verified end-to-end. Archived at `.planning/milestones/v0.1-ROADMAP.md` (shipped 2026-04-25)
- 🚧 **v0.2** - Enterprise configuration: durable trust-data for connection records, runtime snapshot hydration, metadata lifecycle, certificate rollover, and persisted mappings/auditability.

## v0.2 Phases

Phase numbering continues from v0.1, so v0.2 starts at Phase 07.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 07 | Schema + connection aggregate | Add durable trust/config records and constraints. | CFG-01 |
| 08 | Resolver adapter + snapshotting | Hydrate runtime snapshots from persisted config. | CFG-02 |
| 09 | Metadata import/export + refresh | Support explicit metadata onboarding and controlled refresh. | CFG-03 |
| 10 | Certificate inventory + rollover | Manage staged cert lifecycle with overlap windows. | CFG-04 |
| 11 | Mapping persistence + audit hardening | Persist mappings and emit durable audit history. | CFG-05 |
| 12 | Metadata refresh trust-state repair | Repair the failing refresh/apply path and re-verify metadata lifecycle behavior. | CFG-03 |
| 13 | Certificate rollover validation + verification | Close rollover validation gaps and produce milestone verification evidence. | CFG-04 |
| 14 | Mapping/audit milestone verification | Produce the missing mapping/audit milestone verification artifacts and close traceability. | CFG-05 |

### Phase Details

**Phase 07: Schema + connection aggregate**
- Goal: establish the host-DB trust record and schema constraints first.
- Status: complete (verified 2026-05-05).
- Success criteria:
  1. Connection records can be created, updated, disabled, and validated.
  2. Migrations create the required tables, indexes, and constraints.
  3. Invalid or incomplete config is rejected before runtime use.

**Phase 08: Resolver adapter + snapshotting**
- Goal: keep runtime pure while loading persisted config through an adapter boundary.
- Success criteria:
  1. A persisted connection resolves into a plain runtime snapshot.
  2. Protocol code does not read storage rows directly.
  3. Resolver failures return typed errors and preserve clear diagnostics.

**Phase 09: Metadata import/export + refresh**
- Goal: make metadata onboarding and sync explicit and reversible.
- Plans: 4 plans.
- Plan list:
- [ ] `09-01-PLAN.md` — add metadata revision/source persistence and connection revision pointers.
- [ ] `09-02-PLAN.md` — add atomic metadata apply with rollback and last-known-good preservation.
- [ ] `09-03-PLAN.md` — add metadata import parsing, deterministic candidate normalization, and source registration APIs.
- [ ] `09-04-PLAN.md` — add explicit remote refresh, optional Req wiring, redacted observability, and snapshot-only export regressions.
- Success criteria:
  1. Metadata can be imported from local XML, and a remote HTTPS source can be registered for controlled refresh.
  2. Metadata can be exported for the configured connection.
  3. Refresh runs with provenance and last-known-good preservation.

**Phase 10: Certificate inventory + rollover**
- Goal: avoid replace-in-place cert outages by modeling overlap and promotion.
- Success criteria:
  1. Certificate roles and expiry are stored per connection.
  2. Active/next/retired states support staged rollover.
  3. Promotion and rollback keep trust windows explicit.

**Phase 11: Mapping persistence + audit hardening**
- Goal: make authorization mapping and trust changes reviewable.
- Status: execution complete on 2026-05-05; awaiting `$gsd-verify-work`.
- Plans: 4 plans.
- Plan list:
- [x] `11-01-PLAN.md` — add runtime mapping contract, aggregate ownership boundaries, and explicit live-row plus ledger schemas.
- [x] `11-02-PLAN.md` — add the canonical mapping/audit migration and real-Repo schema plus constraint coverage.
- [x] `11-03-PLAN.md` — add a shared audit writer and same-transaction audit capture for connection, metadata, and certificate trust mutations.
- [x] `11-04-PLAN.md` — add dedicated mapping commands, mapping snapshot hydration, and persisted-config-driven default mapping.
- Success criteria:
  1. Attribute/group mappings persist per connection.
  2. Mapping changes are versioned or otherwise attributable.
  3. Audit records capture actor, action, and before/after context.

**Phase 12: Metadata refresh trust-state repair**
- Goal: close the blocking metadata refresh regression and restore verification coverage for `CFG-03`.
- Status: execution complete on 2026-05-05; awaiting `$gsd-verify-work`.
- Plans: 3 plans.
- Plan list:
- [x] `12-01-PLAN.md` — repair the canonical metadata certificate normalization contract and valid/invalid fixture coverage.
- [x] `12-02-PLAN.md` — re-verify the shared import/refresh apply seam while preserving staged runtime trust semantics.
- [x] `12-03-PLAN.md` — produce serial `CFG-03` verification evidence and capture manual sign-off in `09-VERIFICATION.md`.
- Gap closure: fixes the Phase 09 `:invalid_certificate_pem` refresh/apply failure called out in `v0.2-MILESTONE-AUDIT.md`.
- Success criteria:
  1. Operator-triggered metadata refresh completes without certificate PEM decode failures on valid inputs.
  2. Focused Phase 09 smoke coverage passes for import, apply, and refresh paths.
  3. Phase 09 has a verification artifact proving `CFG-03` is satisfied.

**Phase 13: Certificate rollover validation + verification**
- Goal: sync Phase 10 validation truth and produce verification evidence that closes `CFG-04`.
- Status: complete (verified after Phase 13 execution).
- Plans: 3 plans.
- Plan list:
- [x] `13-01-PLAN.md` — sync `10-VALIDATION.md` to the current serial rollover proof surface and completed Wave 0 truth.
- [x] `13-02-PLAN.md` — create `10-VERIFICATION.md` from the locked serial packet and blocking manual sign-off gate.
- [x] `13-03-PLAN.md` — update live milestone truth in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` after CFG-04 verification closure.
- Gap closure: closes the audit orphan state for certificate lifecycle coverage and resolves the partial Nyquist status in `10-VALIDATION.md`.
- Success criteria:
  1. `10-VALIDATION.md` reflects the current Wave 0 proof surface and serial-only verification posture.
  2. Phase 10 verification evidence exists for staged promotion, rollback, and expiry tracking behavior.
  3. `CFG-04` can be marked satisfied in milestone traceability after verification.

**Phase 14: Mapping/audit milestone verification**
- Goal: close the remaining verification gap for Phase 11 without reopening already-green implementation work.
- Status: complete (verified after Phase 14 execution).
- Plans: 2 plans.
- Plan list:
- [x] `14-01-PLAN.md` — create `11-VERIFICATION.md` from the locked serial packet and blocking manual sign-off gate.
- [x] `14-02-PLAN.md` — update live milestone truth in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` after CFG-05 verification closure.
- Gap closure: resolves the audit orphan state for `CFG-05` by producing the missing phase verification artifact.
- Success criteria:
  1. Phase 11 verification evidence exists for mapping persistence and audit hardening behavior.
  2. Milestone traceability can mark `CFG-05` complete from verification evidence rather than plan completion alone.
  3. v0.2 re-audit sees no remaining mapping/audit verification gap.
