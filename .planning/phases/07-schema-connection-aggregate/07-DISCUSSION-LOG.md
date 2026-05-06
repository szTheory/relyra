# Phase 07: Schema + connection aggregate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 07-schema-connection-aggregate
**Areas discussed:** Connection identity and lookup, lifecycle for incomplete config, trust material storage, schema shape and extensibility

---

## Connection identity and lookup

| Option | Description | Selected |
|--------|-------------|----------|
| Internal DB id only | Surrogate key only, no stable public identifier | |
| Public `connection_id` only | One immutable identifier used for both storage and runtime | |
| Internal PK + public `connection_id` | Internal `:binary_id` for associations, public immutable `connection_id` for routes/runtime | ✓ |
| Org-scoped public slug | Composite org + slug identity | |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it fits the existing `/:connection_id/*` surface, keeps runtime snapshots stable, and avoids coupling persistence associations to a public string key.

---

## Lifecycle for incomplete config

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime-ready only | Persist only fully valid/runnable rows | |
| Draft + disabled states | Save-as-you-go plus explicit non-runnable states | |
| Disabled only | One switch, no draft concept | |
| Separate persistence validity from runtime eligibility | Draft/edit flow plus strict runtime gate | ✓ |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Implement as draft/disabled user-visible lifecycle on top of strict runtime-readiness validation. Drafts may persist; they may not resolve.

---

## Trust material storage

| Option | Description | Selected |
|--------|-------------|----------|
| Single cert field on connection | Replace-in-place active trust anchor | |
| Full certificate table now | Child rows from Phase 07 onward | |
| Minimal certificate inventory now | Child cert rows with provenance now, rollover semantics later | ✓ |
| Seed lifecycle companion fields | Helpful companion to the minimal inventory approach | ✓ |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Store trust material in child certificate rows now, but defer active/next/retired promotion workflow to Phase 10. Preserve provenance from the start.

---

## Schema shape and extensibility

| Option | Description | Selected |
|--------|-------------|----------|
| Normalized core columns + bounded JSONB/embeds | Hybrid aggregate with clear relational core | ✓ |
| Highly normalized many-table design | Full decomposition from day one | |
| Wide nullable table | One flat table with many optional columns | |
| JSON-first config blob | Flexible payload as primary source of truth | |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it matches idiomatic Ecto usage for this kind of domain while preserving runtime purity and a clean path into certificates, mappings, and audit later.

---

## the agent's Discretion

- Exact field names, table names, and enum atoms.
- Exact bounded JSONB/embed structure for compact policy objects.
- Exact index layout beyond the locked invariants.

## Deferred Ideas

- Shift the recommendation-first, deep-research, low-friction decision preference further left into project-level GSD defaults, except for unusually high-impact choices.
