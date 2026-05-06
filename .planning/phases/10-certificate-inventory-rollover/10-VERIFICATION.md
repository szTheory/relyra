# Phase 10 Verification

## Scope

This artifact closes `CFG-04` milestone verification for Phase 10 by recording the compact serial evidence packet defined in Phase 13 and preserving the blocking manual approval gate for the two remaining rollover semantics checks.

## Requirement Traceability

Requirement: `CFG-04` - User can manage certificate inventory for a connection with expiry tracking and staged rollover.

| CFG-04 behavior | Proof source | Evidence |
| --- | --- | --- |
| Expiry tracking | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`; `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` | Focused serial rollover packet passed with `23 tests, 0 failures`. `test/relyra/ecto/certificate_inventory_expiry_test.exs` proves imported and staged certificates persist real `not_before` and `not_after` facts before lifecycle decisions consume them. |
| Staged promotion and rollback | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`; `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` | Focused serial rollover packet passed with `23 tests, 0 failures`. `test/relyra/ecto/certificate_inventory_transition_test.exs` and the Phase 10 implementation summary prove legal lifecycle edges, staged promotion, and atomic rollback behavior. |
| Concurrency conflict handling | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`; `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` | Focused serial rollover packet passed with `23 tests, 0 failures`. `test/relyra/ecto/certificate_inventory_concurrency_test.exs` proves stale writes normalize to typed `:conflict` errors and preserve one explicit active trust set. |
| Active-only runtime trust hydration | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`; `mix test --warnings-as-errors`; `test/relyra/ecto/ecto_connection_resolver_test.exs`; `test/relyra/connection_snapshot_test.exs` | Focused serial rollover packet passed with `23 tests, 0 failures`; full serial suite passed with `168 tests, 0 failures`. Resolver and snapshot coverage prove runtime trust hydrates only active signing certs while staged and retired rows remain durable inventory facts only. |

## Phase-Audit Gap Closed

Milestone audit gap being closed: `.planning/v0.2-MILESTONE-AUDIT.md` left `CFG-04` orphaned because Phase 10 had no `10-VERIFICATION.md`, and `10-VALIDATION.md` still described missing Wave 0 rollover proof even though the repo already carried the required serial coverage.

Closure evidence:
- This file now exists as the missing Phase 10 verification artifact.
- The focused serial rollover packet now passes against the current repo state.
- The full serial suite now passes after the focused rollover packet.
- The remaining human approval gate is isolated to the two semantics judgments defined in Phase 13.

## Automated Evidence Packet

Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the rollover validation contract and the milestone-audit warning that parallel Mix evidence is invalid for this phase.

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `2026-05-06T07:04:03Z` | `mix compile --warnings-as-errors` | passed | `compile succeeded with no warnings` |
| 2 | `2026-05-06T07:04:04Z` | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` | passed | `23 tests, 0 failures` |
| 3 | `2026-05-06T07:04:05Z` | `mix test --warnings-as-errors` | passed | `168 tests, 0 failures` |

Serial execution note: order `1` completed successfully before order `2` started, and order `2` completed successfully before order `3` started. No parallel Mix commands were used for this verification packet.

## Evidence Map

### Expiry tracking

- `test/relyra/ecto/certificate_inventory_expiry_test.exs` proves metadata-driven certificate staging persists X.509 `not_before` and `not_after` facts for later rollover decisions instead of relying on inferred operator timelines.

### Staged promotion and rollback

- `test/relyra/ecto/certificate_inventory_transition_test.exs` proves only legal lifecycle transitions succeed and that rollback restores one intended active signing certificate set.
- `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` records the locked lifecycle contract: promotion, retirement, rollback, and typed invalid-transition failures are already implemented and are what this artifact verifies rather than redesigns.

### Concurrency conflict handling

- `test/relyra/ecto/certificate_inventory_concurrency_test.exs` proves stale concurrent promotion attempts fail closed with typed `:conflict` errors and preserve one explicit active trust set.
- `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` records the connection-level conflict contract and deterministic stale-write coverage.

### Active-only runtime trust hydration

- `test/relyra/ecto/ecto_connection_resolver_test.exs` proves the resolver excludes staged certificates from the runtime trust set.
- `test/relyra/connection_snapshot_test.exs` proves `Relyra.Ecto.ConnectionSnapshot` hydrates only active signing certificates and excludes `:next` and `:retired` rows from runtime trust.
- `mix test --warnings-as-errors` confirms the focused rollover guarantees remain compatible with the broader runtime and Phoenix coverage.

## Manual Sign-Off

The automated packet is complete. The remaining approval gate is limited to the two semantics checks Phase 13 locked:

1. Confirm the rollover API and typed conflict errors make the caller action obvious.
2. Confirm runtime trust still consumes only active certs while staged and retired rows remain inventory facts only.

Human review instructions:
- Review `lib/relyra/ecto/certificate_inventory.ex`, `test/relyra/ecto/certificate_inventory_transition_test.exs`, and `test/relyra/ecto/certificate_inventory_concurrency_test.exs` for caller-guidance clarity around promote, retire, rollback, and typed conflict handling.
- Review `lib/relyra/ecto/connection_snapshot.ex`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/connection_snapshot_test.exs` for the active-only runtime trust rule.
- If approved, record concise approval prose below without expanding the scope beyond these semantics checks.

Human review result:
- Approved on `2026-05-06`.
- The rollover API and typed conflict errors still make the caller action obvious: promotion and rollback paths are explicit, and stale or invalid lifecycle edges fail with typed outcomes that clearly imply retry, refresh, or abort rather than silent mutation.
- Runtime trust still consumes only active signing certificates while staged and retired rows remain durable inventory facts only; the resolver and snapshot hydration paths keep those non-active rows out of the runtime trust set until promotion.

Manual approval status: approved.
