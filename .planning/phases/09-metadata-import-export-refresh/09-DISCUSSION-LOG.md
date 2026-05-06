# Phase 09: Metadata import/export + refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 09-metadata-import-export-refresh
**Areas discussed:** Refresh safety model, import source contract, export contract, provenance depth

---

## Refresh safety model

| Option | Description | Selected |
|--------|-------------|----------|
| Manual import only, replace current config | Parse and write live state immediately | |
| Manual refresh with staged validation and explicit apply | Fetch/parse/validate first, then apply with last-known-good preservation | ✓ |
| Manual refresh with auto-apply | Off-login-path fetch that writes live state immediately on successful validation | |
| Scheduled or lazy runtime refresh | Automatic background or request-path refresh | |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it keeps trust changes explicit and reversible, preserves runtime purity, and sets up Phase 10 rollover cleanly.

---

## Import source contract

| Option | Description | Selected |
|--------|-------------|----------|
| File/XML only | Primary onboarding path with no remote source support | |
| URL only | All onboarding and refresh driven from remote metadata URLs | |
| Both with equal footing | File and URL treated as identical import modes | |
| Asymmetric contract | XML/file as primary import, URL as explicit refresh-capable source registration | ✓ |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it keeps local onboarding simple, preserves optional HTTP dependencies, and prevents live-fetch semantics from leaking into runtime trust.

---

## Export contract

| Option | Description | Selected |
|--------|-------------|----------|
| SP metadata only | Public export remains one SP metadata document per resolved connection | ✓ |
| SP metadata + raw IdP metadata | Also expose stored imported XML publicly | |
| SP metadata + normalized IdP view | Also expose effective IdP state publicly | |
| Dual public/internal exports | Public SP metadata plus broader built-in admin-style export APIs | |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it matches the existing Phoenix/runtime boundary and avoids inventing an admin API before the admin milestone.

---

## Provenance depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal source stamps | Only current-row source fields and last status | |
| Moderate operational ledger | Append-only metadata revisions plus active and last-known-good pointers | ✓ |
| Full raw snapshot history | Store raw XML blob history durably by default | |
| Full versioning / event sourcing | Build metadata trust as a replayed event stream | |

**User's choice:** Delegated to agent after parallel advisor research.
**Notes:** Chosen because it is strong enough for reversibility and supportability without overbuilding storage, privacy, or replay complexity into v0.2.

---

## the agent's Discretion

- Exact schema/module naming for metadata sources, revisions, and apply services.
- Exact error atom taxonomy and diff-summary representation.
- Exact local XML import API ergonomics.

## Deferred Ideas

- Scheduled refresh automation.
- Public export of IdP provenance artifacts.
- Diff preview / approval workflow.
- Opt-in raw XML archival.
- Shift recommendation-first GSD defaults further left at project level, except for unusually high-impact choices.

