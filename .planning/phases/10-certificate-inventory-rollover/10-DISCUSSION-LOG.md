# Phase 10: Certificate inventory + rollover - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `10-CONTEXT.md`; this log preserves the analysis path.

**Date:** 2026-05-05
**Phase:** 10-certificate-inventory-rollover
**Mode:** assumptions
**Areas analyzed:** Certificate lifecycle model, Apply and promotion semantics, Runtime trust window

## Assumptions Presented

### Certificate lifecycle model
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 10 should extend `Relyra.Ecto.Certificate` with explicit per-row lifecycle fields for certificate role/state and rollover timing, rather than introducing a separate rollover table or storing lifecycle only in revision metadata. | Confident | `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md`, `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md`, `lib/relyra/ecto/certificate.ex`, `lib/relyra/ecto/metadata_revision.ex` |

### Apply and promotion semantics
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Metadata apply in Phase 10 should stop replacing `certificates` wholesale and instead stage incoming certs into inventory as non-active rows, with promotion/rollback implemented as explicit state transitions on existing inventory rows. | Confident | `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/ecto/connection.ex`, `.planning/ROADMAP.md` |

### Runtime trust window
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Runtime hydration must continue exposing only the currently trusted active overlap set in `idp_certificates`, while promotion/rollback keeps `next` and `retired` rows persisted but excluded from runtime until their trust window explicitly changes. | Likely | `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md`, `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md`, `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/ecto/connection_loader.ex` |

## Corrections Made

No corrections. User approved the assumptions as presented.

## Outcome

- Assumptions accepted and promoted into `10-CONTEXT.md` as locked implementation decisions.
- Phase 10 is ready for research/planning.
