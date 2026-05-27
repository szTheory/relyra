---
phase: 40
plan: 02
subsystem: docs
tags: [docs, incident-playbook, operator-experience, ci.docs]
requires:
  - lib/relyra/telemetry.ex (frozen — events cited verbatim)
  - lib/relyra/ecto/audit_event.ex (frozen — @domain_values / @action_values cited verbatim)
  - lib/relyra/live_admin/router.ex (frozen — routes cited verbatim with :connection_id)
  - lib/mix/tasks/relyra.*.ex (frozen — @shortdoc lines cited verbatim, 7 tasks)
  - lib/relyra/diagnostic.ex (frozen — Phase 23 DIAG-01 bundle anchor)
  - lib/relyra/replay_store/{ecto,ets}.ex (frozen — no-AuditWriter property load-bearing for Scenario 3)
  - guides/troubleshooting.md (Plan 01 — H3 anchors cross-linked)
provides:
  - DOCS-05 playbook: guides/operations/incident_playbook.md
affects:
  - .planning/phases/40-operational-polish-error-taxonomy/40-02-SUMMARY.md (this file)
tech-stack:
  added: []
  patterns:
    - Doubled-H2 `Relyra owns / Host owns` two-party preamble (PATTERNS Shared 3; inherited from recipes/logout.md:24-41)
    - Reference-table-as-centerpiece, scenarios-point-into-table (PATTERNS File 2; inherited from recipes/generic_saml.md:62-70)
    - Ordered-list Triage → Diagnose → Recover scenario template (PATTERNS File 2)
    - Brand-voice closing receipt mirroring CLAUDE.md "verified trust path or a typed rejection" metaphor (D-16)
key-files:
  created:
    - guides/operations/incident_playbook.md
    - .planning/phases/40-operational-polish-error-taxonomy/40-02-SUMMARY.md
  modified: []
decisions:
  - LiveAdmin route citations use `:connection_id` everywhere — verified against `lib/relyra/live_admin/router.ex:22-29` (RESEARCH.md Step 5 correction over CONTEXT.md D-14's `:id`).
  - Mix-task surface lists exactly 7 Relyra tasks (NOT 8). `hex.audit` is a third-party Hex task and is explicitly excluded from the surface table.
  - Replay-storm scenario carries the explicit no-audit-signal callout: `replay_store/ecto.ex` and `replay_store/ets.ex` both contain zero `AuditWriter.append_event` calls (re-verified at execution time via grep). Operators must rely on `[:relyra, :saml, :replay, :check]` telemetry alone.
  - Closing receipt phrases the brand metaphor as "Every login resolves to a verified trust path or a typed rejection — and when in doubt, the diagnostic bundle is the trace" — keeps both halves of the CLAUDE.md metaphor intact per D-16.
  - mix.exs was NOT modified by Plan 02 — Plan 01 took the default path and registered BOTH extras entries (line 134/135) and BOTH ci.docs presence guards (line 158/159). Task 2 is verify-only.
metrics:
  duration: ~12m
  completed: 2026-05-27
---

# Phase 40 Plan 02: Incident Response Playbook (DOCS-05) Summary

DOCS-05 closed: `guides/operations/incident_playbook.md` stitches Relyra's
five evidence surfaces — telemetry events, audit ledger, LiveView admin
routes, Mix tasks, and the troubleshooting decoder — into Triage →
Diagnose → Recover runbooks for the six common SAML incident scenarios.
The DOCS-05 + DOCS-06 combined acceptance gate `mix ci.docs` exits 0
end-to-end. `ci.security`, `@gated_suites`, `package/files:`, `deps/0`,
and every non-`ci.docs` alias remain byte-identical to the Plan 02 base
commit `d0911d8` (Phase 30 invariant preserved).

## Tasks Completed

| Task | Name                                                                       | Commit    | Files                                          |
| ---- | -------------------------------------------------------------------------- | --------- | ---------------------------------------------- |
| 1    | Author `guides/operations/incident_playbook.md` (310 lines)                | `671f864` | `guides/operations/incident_playbook.md`       |
| 2    | Verify mix.exs wiring; confirm `mix ci.docs` exits 0 end-to-end             | (no edit) | `mix.exs` (verify-only — Plan 01 pre-wired)    |

## Five-Surface Table Contents

The centerpiece reference table (single placement at the top of the
playbook; every scenario cross-references back into it) carries five
rows, with each anchor cited verbatim against the live codebase:

| Surface                  | Anchor                                       | What is cited verbatim                                                                                                                                                                              |
| ------------------------ | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Telemetry events         | `lib/relyra/telemetry.ex`                    | 11 span events + 5 auto-refresh transition events + 1 `:certificate, :expiring` event — all quoted as `[:relyra, :saml, ...]` atom-list literals                                                     |
| Audit ledger             | `lib/relyra/ecto/audit_event.ex:13-26`       | `@domain_values = [:connection, :metadata, :certificate, :mapping]` and the 11-atom `@action_values` list — both rendered as Elixir atom-list literals                                                |
| LiveView admin routes    | `lib/relyra/live_admin/router.ex`            | 6 routes including the `:show`, `:edit`, and `/metadata` routes that use the `:connection_id` path parameter (NOT `:id`)                                                                              |
| Mix tasks                | `lib/mix/tasks/relyra.*.ex`                  | 7 tasks (NOT 8) with `@shortdoc` quoted verbatim: `batteries_included`, `conformance`, `diagnostic`, `install`, `metadata.pin`, `refresh_due`, `security_review`. `hex.audit` is explicitly excluded   |
| Troubleshooting decoder  | `../troubleshooting.md`                      | Cross-link via relative path; every scenario atom also has a per-atom anchor link into the decoder (e.g. `../troubleshooting.md#digest_mismatch`)                                                     |

## Six Scenarios

Each scenario is an H2 section with a `Symptom:` line followed by a
1-2-3 ordered list of `Triage` → `Diagnose` → `Recover` steps. Every
scenario cross-references the surface table by name rather than
restating the evidence sources inline.

| #  | Title                                                | Symptom atoms (markdown-linked into ../troubleshooting.md)                                       | Load-bearing detail                                                                                                                  |
| -- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Certificate expiry imminent                          | (none — telemetry warning, no atom)                                                              | `[:relyra, :saml, :certificate, :expiring]` is the first signal; recovery is staged-cert rollover                                      |
| 2  | Metadata drift after IdP change                      | `:metadata_drift_requires_review`                                                                | Auto-refresh `:degraded` / `:suspended` are the leading indicators; recovery is `mix relyra.refresh_due` + optional `metadata.pin`     |
| 3  | Replay storm                                         | `:replayed_assertion`                                                                            | Explicit no-audit-signal callout — `replay_store/{ecto,ets}.ex` contain zero AuditWriter calls; telemetry is the only signal           |
| 4  | Signature regression after IdP key rotation          | `:digest_mismatch`, `:invalid_signature`, `:trust_anchor_mismatch`                               | Configured IdP certs only — Relyra never trusts document KeyInfo (CLAUDE.md invariant 1)                                              |
| 5  | ACS misconfiguration at provisioning                 | `:destination_mismatch`, `:recipient_mismatch`, `:in_response_to_mismatch`                       | Atom names the exact field that mismatched; recovery is connection-field edit via admin UI                                            |
| 6  | Attribute mapping breakage                           | `:invalid_audience` plus host-app `UserMapper` rejections                                        | Distinguishes between connection-mapping edits (admin UI) and host-app UserMapper changes (host code change)                          |

## CLAUDE.md Compliance

- **Conventional commit with `Co-Authored-By:` footer:** Task 1 commit
  is `docs(40-02): publish operator incident playbook (DOCS-05)` with the
  required trailer.
- **Non-negotiable security invariants:** none touched. Phase 40 is
  documentation only; the trust pipeline, parse path, crypto gate, audit
  writer, replay protection, and behaviour seams are all frozen.
- **`mix ci.security` stays green:** verified exit 0 after a Postgres
  connection-settle wait (see "Environmental Notes" below).
- **`mix format --check-formatted`** on Phase-40-touched files
  (`mix.exs` and `guides/operations/incident_playbook.md`): exit 0.
  Pre-existing format drift in 14 unrelated files is documented in
  Plan 01's `deferred-items.md` and is byte-identical to the Plan 02
  base commit `d0911d8` — out of scope per the parallel-execution
  boundary.
- **Brand voice:** the playbook overview opens with "Every login
  resolves to a verified trust path or a typed rejection" and the
  closing receipt re-uses the metaphor (D-16 mirror).
- **Hex Publishing rule:** untouched — no `mix hex.publish` or
  `mix hex.retire` invocations.

## Byte-Equality Confirmations

All D-11 invariants preserved relative to the Plan 02 base commit
`d0911d8`:

```
$ git diff d0911d8 -- mix.exs
(empty)

$ git diff d0911d8 -- test/security/ci_gate_integrity_test.exs
(empty)

$ git diff d0911d8 -- guides/troubleshooting.md
(empty)

$ git diff d0911d8 -- test/docs/troubleshooting_drift_test.exs
(empty)
```

`mix.exs` is unchanged because Plan 01 pre-wired both Phase 40 docs in
`extras:` (line 134 → 135) and in `ci.docs` (presence guard 158 → 159,
drift-test step at 160). Task 2's verify-only check confirmed the D-17
extras ordering and the D-18 + D-19 alias ordering both hold.

## Verification

| Gate                                                 | Command                                                                                                       | Result                                                                                |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Format on Phase 40 files                             | `mix format --check-formatted mix.exs guides/operations/incident_playbook.md`                                  | exit 0                                                                                 |
| Compile                                              | `mix compile --warnings-as-errors`                                                                              | exit 0                                                                                 |
| Drift test (Plan 01 contract preserved)              | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`                                       | exit 0 — 1 test, 0 failures                                                            |
| Playbook file exists                                 | `test -f guides/operations/incident_playbook.md`                                                                | exit 0 (310 lines)                                                                     |
| DOCS-05 + DOCS-06 combined gate                      | `mix ci.docs`                                                                                                   | exit 0 end-to-end (all presence guards pass; drift test green; batteries_included + install + test_support_demo tests green) |
| Phase 30 invariant                                   | `mix ci.security`                                                                                               | exit 0 (after Postgres connection-pool settle — see Environmental Notes)               |
| D-17 ordering (extras: troubleshooting → playbook)   | `grep -nF 'guides/operations/incident_playbook.md' mix.exs`                                                    | line 135 (extras) + 159 (ci.docs presence guard) — both after troubleshooting.md (134 / 158) |
| D-18 + D-19 ordering (guards before drift test)      | `grep -nE '(cmd test -f guides/.*\.md\|cmd mix test test/docs/troubleshooting_drift_test\.exs)' mix.exs`        | drift-test step at line 160, after both presence guards (158 / 159)                    |
| `:connection_id` correctness (D-14 / RESEARCH.md S5) | `grep -F '/relyra/admin/connections/:id' guides/operations/incident_playbook.md`                                | 0 matches (wrong route param absent)                                                   |
| `:connection_id` presence                            | `grep -cF ':connection_id' guides/operations/incident_playbook.md`                                              | 13 matches                                                                             |
| Telemetry verbatim citations                         | `grep -cF '[:relyra, :saml,' guides/operations/incident_playbook.md`                                            | 25 matches                                                                             |
| Audit @domain_values / @action_values verbatim       | `grep -cF '@domain_values' guides/operations/incident_playbook.md`                                              | 1 match (followed by the literal atom list); same for `@action_values`                 |
| Closing receipt brand voice                          | `grep -cF 'verified trust path or a typed rejection' guides/operations/incident_playbook.md`                    | 1 match (D-16 mirror)                                                                  |
| Diagnostic-bundle anchor                             | `grep -cF 'mix relyra.diagnostic' guides/operations/incident_playbook.md`                                       | 4 matches (closing receipt + 3 scenario invocations)                                   |
| Cross-link into Plan 01 deliverable                  | `grep -cF 'troubleshooting.md' guides/operations/incident_playbook.md`                                          | 16 matches (surface row + per-scenario atom anchors)                                   |
| Replay scenario no-audit-signal callout              | `grep -F 'zero \`AuditWriter.append_event\`' guides/operations/incident_playbook.md`                            | 1 match (Scenario 3, load-bearing)                                                     |

## Narrative Discretion (Planner-Discretion Zones)

Per CONTEXT.md `<decisions>`, certain phrasings are planner-discretion.
Choices made:

1. **Surface table layout** — used a primary three-column markdown
   table (`Surface | What it tells you | Exact code anchor`) followed
   by structured sub-sections (telemetry catalog, audit vocabulary,
   route table, Mix-task table) immediately below the main table.
   Rationale: keeps the centerpiece scannable while preserving the
   verbatim citations the surface contract requires.
2. **Closing-receipt heading** — chose "When in doubt" over "Receipt."
   Rationale: matches the brand-voice mirror in the body sentence
   ("when in doubt, the diagnostic bundle is the trace") and reads as
   plain operator language rather than as a doc-engineering term.
3. **Per-scenario atom links** — every scenario lists its symptom
   atoms as markdown reference-link form pointing into
   `../troubleshooting.md#{atom}` (ExDoc slug-from-H3). Rationale: an
   operator scanning the playbook gets a one-click jump into the
   per-atom decoder without leaving the page.
4. **Scenario 3 phrasing** — phrased the no-audit-signal callout in
   two beats (the load-bearing fact, then the operator implication):
   "Replays do not mutate trust state, so no audit row is written —
   `lib/relyra/replay_store/ecto.ex` and `lib/relyra/replay_store/ets.ex`
   contain zero `AuditWriter.append_event` calls. Operators rely on
   `[:relyra, :saml, :replay, :check]` telemetry alone for
   replay-storm detection; the audit ledger will not corroborate."
   Rationale: leaves no ambiguity for an operator who arrived
   expecting an audit row and would otherwise dig fruitlessly.

## Environmental Notes

`mix ci.security` was attempted twice during execution. Both initial
runs hit `Postgrex.Error FATAL 53300 (too_many_connections)` — the
shared local Postgres instance was at 104 / 100 active connections due
to other parallel worktree agents in this wave running their own test
suites against the same database. This is NOT a Phase 40 regression:

- The first 4-5 security sub-suites that ran completed cleanly
  (`6 tests, 0 failures`, `4 tests, 0 failures`, etc.) before
  subsequent suites failed at `Repo.create_storage`.
- Plan 02 modifies only documentation; the security lane (`ci.security`
  alias, `@gated_suites`, ci_gate_integrity_test.exs, every security
  test file) is byte-identical to the Plan 02 base commit `d0911d8`.

After waiting for the Postgres connection pool to settle (active
connections dropped from 104 to 27), a third invocation of
`mix ci.security` exited 0 with every security suite passing. The
Phase 30 hollow-gate invariant is preserved.

## Deviations from Plan

### Auto-fixed Issues

None. Plan 02 executed exactly as written.

### Out-of-Scope Discoveries (logged, not fixed)

**1. [SCOPE BOUNDARY] Pre-existing `mix format --check-formatted` drift
   in 14 source/test files**

   * **Found during:** Task 2 (running the verify gates).
   * **What:** `lib/relyra.ex`, `lib/relyra/security/signature.ex`,
     `lib/relyra/security/logout_validator.ex`,
     `lib/relyra/protocol/logout_response.ex`,
     `lib/relyra/protocol/logout_request.ex`,
     `lib/relyra/session_adapter.ex`, plus 8 test files (including the
     adversarial_crypto_test.exs entry that Plan 01 already logged) all
     show formatter drift.
   * **Scope check:** every one of those 14 files is byte-identical
     to the Plan 02 base commit `d0911d8` — confirmed via
     `git diff d0911d8 -- <file>` returning zero changes for each.
     The drift pre-existed Phase 40.
   * **Action:** logged here for transparency; NOT fixed (per the
     SCOPE BOUNDARY rule from the parallel-executor instructions —
     only fix issues directly caused by the current task's changes).
   * **Impact on this plan's gates:** the DOCS-05 + DOCS-06 combined
     gate `mix ci.docs` and the Phase 30 invariant `mix ci.security`
     both exit 0. `mix qa` (which would fail on the pre-existing
     drift) is not in this plan's verification path. Plan 01's
     `deferred-items.md` already tracks the adversarial_crypto_test
     entry; the other 13 files should be batched into a future
     formatter-sweep phase.

## Known Stubs

None. Every cross-link in the playbook resolves to a file that exists
at this commit:

- `../troubleshooting.md` — Plan 01 deliverable, 1,202 lines.
- `../identity_mapping_and_provisioning.md` — pre-Phase-40 guide.
- Every `lib/relyra/...` and `lib/mix/tasks/relyra.*.ex` anchor — all
  present in the codebase.

The Plan 01 cross-link FROM `guides/troubleshooting.md` TO
`guides/operations/incident_playbook.md` (which was a "forward link"
during Plan 01 execution) is now a fully resolved link as of this
plan's Task 1 commit.

## Threat Flags

None. Phase 40 introduces no new threat surface (matches the plan's
`<threat_model>` verbatim: "No new threat surface introduced... Phase
40 is documentation + one drift-check test. ... Severity: none.").
The playbook is operator-facing documentation; it does not change any
trust boundary, algorithm policy, signature path, replay window, or
audit invariant.

## Self-Check

1. **Files exist:**
   - `guides/operations/incident_playbook.md`: FOUND (310 lines)
   - `.planning/phases/40-operational-polish-error-taxonomy/40-02-SUMMARY.md`: this file

2. **Commits exist:**
   - `671f864` (Task 1, incident_playbook.md): FOUND

3. **Acceptance criteria from PLAN.md:**
   - [x] Task 1 acceptance: 11 H2 sections (1 framing + 2 sub-frame +
         1 surface table + 6 scenarios + 1 closing), doubled-H2 preamble
         (2× `## Relyra owns` + 1× `## Host owns`), telemetry events
         cited verbatim (25 `[:relyra, :saml,` occurrences),
         `:connection_id` correct (13 matches; 0 matches for the wrong
         `:id` form), `@domain_values` + `@action_values` verbatim,
         Mix tasks present (16 `mix relyra.` matches; 7 distinct
         tasks), troubleshooting cross-links (16 matches),
         no-audit-signal callout in Scenario 3 (load-bearing prose),
         brand-voice closing receipt (1 verbatim "verified trust path
         or a typed rejection" + 3 "diagnostic bundle" references).
         Drift test exits 0 (1 test, 0 failures).
   - [x] Task 2 acceptance: `mix.exs` byte-identical to Plan 02 base
         (Plan 01 pre-wired both extras + both presence guards in
         D-17 / D-18 / D-19 order). `mix ci.docs` exits 0 end-to-end.
         `mix ci.security` exits 0 (after Postgres settle).
         `ci_gate_integrity_test.exs` byte-unchanged.

## Self-Check: PASSED
