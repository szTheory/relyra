# Phase 11: Mapping persistence + audit hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `11-CONTEXT.md`; this log preserves the assumptions and research that produced them.

**Date:** 2026-05-05
**Phase:** 11-mapping-persistence-audit-hardening
**Mode:** assumptions + subagent research
**Areas analyzed:** mapping persistence model, durable audit boundary, audit capture architecture

## Assumptions Presented

### Mapping Persistence Model
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Per-connection attribute/group mappings should persist as dedicated child records keyed by the internal connection PK and be exposed to runtime as plain values, not as connection JSON/blob or code-only adapter state. | Confident | `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md`, `lib/relyra/user_mapper.ex`, `lib/relyra/user_mapper/default_attribute.ex`, `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/connection.ex` |

### Durable Audit Boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 11 should add a separate durable cross-domain audit ledger for mapping and trust changes instead of stretching metadata revisions or telemetry into the final audit system. | Confident | `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md`, `lib/relyra/ecto/metadata_revision.ex`, `lib/relyra/telemetry.ex`, `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` |

### Audit Capture Point
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Audit records should be written at explicit transactional persistence orchestration boundaries for trust-changing commands, capturing actor and before/after context in the same DB transaction. | Likely | `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/ecto/certificate_inventory.ex`, `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` |

## Research Applied

### Mapping persistence model
- Recommendation: use first-class child mapping records plus an append-only mapping revision ledger, then hydrate runtime with normalized plain values only.
- Ecosystem support: Spring Security treats SAML config as a first-class registration object; Keycloak uses explicit mapper objects; PingOne/Okta show that richer expression systems exist but add major support complexity.
- Rejected alternatives:
  - connection-row JSON/embed for primary mapping state;
  - code-only per-tenant mapper branches;
  - expression/DSL mapping in the v0.2 base path.
- Key defaults pulled into context:
  - separate live mapping tables and append-only revisions;
  - explicit target enums and multivalue semantics;
  - no regex/scripts/expression language in v0.2.

### Durable audit boundary
- Recommendation: keep `relyra_metadata_revisions` metadata-specific and add a separate append-only cross-domain audit ledger for connection/certificate/mapping/metadata trust changes.
- Ecosystem support: Keycloak separates durable admin events from listener/log surfaces; Spring keeps current registration state separate from repository/history concerns; Ecto favors explicit transactional composition over generic history magic.
- Rejected alternatives:
  - stretching metadata revisions into a global ledger;
  - using telemetry/logs as the audit trail;
  - domain-only history with no coherent cross-domain review surface.
- Key defaults pulled into context:
  - append-only `audit_events`;
  - bounded redacted before/after summaries;
  - action/domain/outcome taxonomy suitable for operator review.

### Audit capture architecture
- Recommendation: write audit rows in the same transaction as explicit trust-changing command modules, then emit telemetry/log/export signals only after commit.
- Ecosystem support: Ecto docs favor `Repo.transact/1` and `Ecto.Multi`; Rails and Django both document callback/signal footguns for hidden side effects; Auth0/Keycloak event streaming patterns reinforce “async events are not the canonical audit ledger.”
- Rejected alternatives:
  - schema callbacks / `prepare_changes/2` as the primary audit mechanism;
  - controller-edge capture as authoritative history;
  - DB triggers as the main audit path for a host-Repo Elixir library;
  - async event reconstruction as authoritative history.
- Key defaults pulled into context:
  - one authoritative audit insert per trust-changing command;
  - explicit `actor`, `cause`, `correlation_id`;
  - normalized trust-view diffs rather than raw param diffs.

## Auto-Resolution Notes

- User preference applied: recommendation-first, one-shot research, low decision burden, auto-resolve unless a choice appears genuinely high-impact to product direction.
- No blocking ambiguity remained after research, so assumptions were promoted directly into `11-CONTEXT.md` without a correction round.

## Deferred / Out-of-Scope Ideas Captured

- Expression-language or script-based mapping transforms.
- Full admin UI review and rollback flows.
- Structured audit export / SIEM pipelines as a first-class surface.
- GSD-wide preference tuning to make recommendation-first auto-resolution the default except for very impactful decisions.

## Sources Consulted

### Local project sources
- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/PITFALLS.md`
- `.planning/research/FEATURES.md`
- `.planning/research/STACK.md`
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md`
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md`
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md`
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md`
- `lib/relyra/user_mapper.ex`
- `lib/relyra/user_mapper/default_attribute.ex`
- `lib/relyra/ecto/connection.ex`
- `lib/relyra/ecto/connections.ex`
- `lib/relyra/ecto/connection_loader.ex`
- `lib/relyra/ecto/connection_snapshot.ex`
- `lib/relyra/ecto/metadata_revision.ex`
- `lib/relyra/ecto/metadata_apply.ex`
- `lib/relyra/ecto/certificate_inventory.ex`
- `lib/relyra/telemetry.ex`
- `lib/relyra/log.ex`

### External references surfaced by subagents
- Ecto docs: `Ecto.Schema`, `Ecto.Changeset`, `Ecto.Multi`, `Ecto.Repo`
- Spring Security SAML `RelyingPartyRegistration`
- Keycloak SAML mapper and admin-event docs
- PingOne mapping docs
- Okta Expression Language docs
- Auth0 event/log docs
- Rails callbacks guide
- Django signals docs
- Microsoft Entra federation certificate guidance

