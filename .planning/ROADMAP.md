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

### Phase Details

**Phase 07: Schema + connection aggregate**
- Goal: establish the host-DB trust record and schema constraints first.
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
- Success criteria:
  1. Metadata can be imported from file or URL source.
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
- Success criteria:
  1. Attribute/group mappings persist per connection.
  2. Mapping changes are versioned or otherwise attributable.
  3. Audit records capture actor, action, and before/after context.
