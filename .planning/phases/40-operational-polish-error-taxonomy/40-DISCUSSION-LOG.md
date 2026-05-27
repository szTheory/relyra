# Phase 40: Operational Polish & Error Taxonomy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `40-CONTEXT.md` — this log preserves the analysis path.

**Date:** 2026-05-27
**Phase:** 40-operational-polish-error-taxonomy
**Mode:** assumptions
**Areas analyzed:** Troubleshooting decoder shape · Drift-check test mechanism · Incident playbook structure · Document placement and CI wiring

## Assumptions Presented

### Troubleshooting decoder shape

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `guides/troubleshooting.md` at `guides/` root | Confident | `.planning/REQUIREMENTS.md:18` (DOCS-06 verbatim) |
| 8 domain-grouped sections (XML / Signature & Crypto / Replay & Request Intent / Metadata / Network/Fetch / Binding & Protocol / Configuration & Adapter / Session & Logout) | Confident | `CLAUDE.md` "Key Architecture Seams" taxonomy; trust-pipeline seam mirror |
| H3 heading form `### :atom_name`, no decoration | Confident | Drift-check regex deterministic parse requirement |
| Four-field micro-block per atom (Means / Likely root cause / Operator action / Source path) | Confident | Mirrors `%Relyra.Error{type, message, details}` (`lib/relyra/error.ex:1-9`) + minimum surface for drift-check |
| Canonical atom set is ~60, not 37 | Confident | Multi-line `Error.new(\n :atom,…)` + `%Relyra.Error{type: :atom}` struct literals (4 sites: `c14n.ex`, `corpus_gate.ex`, `trust_anchor.ex`, `connections_live.ex`) raise count well above single-line scout grep |

### Drift-check test mechanism

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `test/docs/troubleshooting_drift_test.exs` (new `test/docs/` dir) | Confident | Green-field test location; mirrors `test/security/` naming |
| No `@known_types` attribute on `Relyra.Error` — codebase remains single source of truth | Confident | `lib/relyra/error.ex` has no central registry; adding one would drift |
| Three regex patterns (single-line constructor, multi-line constructor, struct literal) | Confident | Constructor-only scan silently skips 4 struct-literal atoms |
| Doc enumeration via `~r/^### :([a-z_][a-z0-9_]*)\b/m` | Confident | Anchored regex prevents body-prose false matches |
| Bidirectional assertion with file-path-citing failure messages | Confident | Vocabulary mirrors `test/security/ci_gate_integrity_test.exs` |
| Wired into `ci.docs` alias, NOT `ci.security` | Confident | Adding to `ci.security` forces `@gated_suites` amendment for zero security benefit |

### Incident playbook structure

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `guides/operations/incident_playbook.md` — new `guides/operations/` directory | Confident | Scout confirmed dir does not exist; only `guides/recipes/` and `guides/case_studies/` |
| Spine: brand overview → "Relyra owns / Host owns" preamble → reference table → scenarios → closing | Confident | Established by `guides/recipes/logout.md:24-41`, `guides/recipes/generic_saml.md`, `guides/identity_mapping_and_provisioning.md` |
| Five-surface reference table (Telemetry / Audit / Admin / Mix tasks / Troubleshooting cross-link) | Confident | Every surface enumerated against real code anchors: `lib/relyra/telemetry.ex`, `lib/relyra/ecto/audit_event.ex`, `lib/relyra/live_admin/router.ex`, `lib/mix/tasks/relyra.*.ex` |
| Six scenario-anchored runbooks (cert expiry · metadata drift · replay storm · signature regression after key rotation · ACS misconfig · attribute mapping breakage) | Confident | Symptoms-first matches operator arrival; workflow-first would leave operators with no symptom anchor |
| Closing pointer: `mix relyra.diagnostic` as single first-resort | Confident | DIAG-01 unified bundle in `lib/relyra/diagnostic.ex` + `lib/mix/tasks/relyra.diagnostic.ex` (Phase 23) |

### Document placement, mix.exs wiring, and ci.docs registration

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Both files appended to `mix.exs` `extras:` list in deterministic order after `guides/recipes/logout.md` | Confident | `mix.exs:111-133`; ExDoc ordering stability |
| `cmd test -f` presence guards for both files in `ci.docs` alias | Confident | `mix.exs:150-156`; presence guard is the delete-protector (empty-vs-empty drift check is vacuously true) |
| Drift-check test as a separate `cmd mix test test/docs/...` line AFTER both presence guards | Confident | Ordering: missing-file surfaces as clear `test -f` error before drift test would otherwise emit confusing "no headings matched" failure |
| No changes to `ci.security` | Confident | `test/security/ci_gate_integrity_test.exs:21-26` `@gated_suites` invariant; drift is a docs concern |

## Corrections Made

None — user confirmed all four areas with "Yes, proceed" via single AskUserQuestion gate. No assumptions revised.

## External Research

None performed. Phase 40 is pure documentation + a single test module; the codebase contained complete evidence for every decision (canonical atom set via grep, telemetry catalog in `lib/relyra/telemetry.ex`, audit schema in `lib/relyra/ecto/audit_event.ex`, admin routes in `lib/relyra/live_admin/router.ex`, mix tasks under `lib/mix/tasks/`, established guide idiom in `guides/recipes/*`, CI alias structure in `mix.exs`, hollow-gate fix invariants in `test/security/ci_gate_integrity_test.exs`).

## Calibration

- Tier resolved: **minimal_decisive** (from `gsd-sdk query config-get preferences.vendor_philosophy` → `"opinionated"`).
- Analyzer produced 4 areas with single decisive recommendations each, no alternatives enumerated — consistent with the user's documented preference for "deeply-researched, coherent one-shot recommendations over back-and-forth" (`feedback_recommendation_first.md`).
