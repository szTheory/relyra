---
phase: 40-operational-polish-error-taxonomy
verified: 2026-05-27T11:35:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 40: Operational Polish & Error Taxonomy Verification Report

**Phase Goal:** Operators can instantly decode cryptic SAML failures and have a clear playbook for incident response.
**Verified:** 2026-05-27T11:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                                                                                                                                          | Status     | Evidence                                                                                                                                                                                                                                  |
|----|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | ROADMAP SC1: `guides/troubleshooting.md` is published as an Error Atom Decoder.                                                                                                                                                | ✓ VERIFIED | File exists (1202 lines); 78 `### :atom_name` H3 entries; bucketed into 7 trust-pipeline-seam H2 sections (Session & Logout merged into Binding & Protocol Shape per RESEARCH.md Step 2 to preserve drift parity) + SLO subset callout. |
| 2  | ROADMAP SC2: An automated drift-check test enforces every `:error_type` in `Relyra.Error` has a corresponding documented entry.                                                                                                | ✓ VERIFIED | `test/docs/troubleshooting_drift_test.exs` exists (159 lines); bidirectional `MapSet.difference` assertions (code_atoms ⊆ doc_atoms AND doc_atoms ⊆ code_atoms) at lines 91-95. `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` exits 0. |
| 3  | ROADMAP SC3: `guides/operations/incident_playbook.md` is published with end-to-end response workflows stitching telemetry, audit, LiveView admin, and Mix tasks.                                                              | ✓ VERIFIED | File exists (310 lines). 11 H2 sections, 6 scenarios, five-surface table at top, doubled-H2 preamble. All five surfaces cited verbatim.                                                                                                  |
| 4  | PLAN 40-01: Drift test uses D-08 three-regex code-atom enumeration + D-09 H3 doc-atom regex.                                                                                                                                   | ✓ VERIFIED | All four module attributes present at lines 79-82: `@code_pattern_singleline`, `@code_pattern_multiline`, `@code_pattern_structlit`, `@doc_pattern`. Variadic-helper rule documented in moduledoc lines 48-67.                              |
| 5  | PLAN 40-01: Failure-message vocabulary follows D-10 ("Missing doc entry for: :atom — add ### :atom section to guides/troubleshooting.md (sources: ...)" and stale-doc form).                                                  | ✓ VERIFIED | `format_missing/2` at lines 140-149 and `format_stale/1` at lines 151-158 emit the D-10 em-dash vocabulary verbatim. Plan 01 SUMMARY confirms manual remove-restore check.                                                                |
| 6  | PLAN 40-01: Every `### :atom_name` H3 in guides/troubleshooting.md is followed by the four-field micro-block (Means / Likely root cause / Operator action / Source).                                                          | ✓ VERIFIED | `grep -cE '\*\*Means:\*\*'` = 78; same count for `**Likely root cause:**`, `**Operator action:**`, `**Source:**`. Zero decorated H3 lines (`grep -cE '^### :[a-z_][a-z0-9_]*[^a-z0-9_].*$'` = 0).                                          |
| 7  | PLAN 40-01: `mix.exs` registers the guide in `extras:` (D-17) and `ci.docs` presence guard + drift-test step (D-18, D-19).                                                                                                     | ✓ VERIFIED | mix.exs:134 (extras), :158 (ci.docs presence guard), :160 (drift-test cmd line). D-18 ordering: troubleshooting guard (158) before drift test (160). D-17 ordering: troubleshooting (134) before playbook (135).                          |
| 8  | PLAN 40-02: Playbook five-surface table cites telemetry events verbatim, audit `@domain_values`/`@action_values` verbatim, LiveAdmin routes with `:connection_id`, 7 Mix tasks (NOT 8), and cross-link to troubleshooting.md. | ✓ VERIFIED | `[:relyra, :saml,` appears 25 times; `@domain_values`/`@action_values` cited verbatim at line 95-98; 13 `:connection_id` references, 0 `/relyra/admin/connections/:id` (wrong form absent); 7 Mix tasks in table; troubleshooting cross-link present 16 times. |
| 9  | PLAN 40-02: Six scenarios (cert expiry, metadata drift, replay storm, signature regression, ACS misconfig, attribute mapping), each Triage → Diagnose → Recover.                                                              | ✓ VERIFIED | `grep -cE '^## Scenario [0-9]+:'` = 6. Scenarios 1-6 each contain `1. Triage`, `2. Diagnose`, `3. Recover` ordered list (verified by inspection of lines 138-298).                                                                          |
| 10 | PLAN 40-02: Replay-storm scenario explicitly states replays produce NO audit row; operators rely on `[:relyra, :saml, :replay, :check]` telemetry alone.                                                                       | ✓ VERIFIED | Scenario 3 (lines 187-215) carries the explicit callout at lines 195-200: "Replays do not mutate trust state, so no audit row is written — `lib/relyra/replay_store/ecto.ex` and `lib/relyra/replay_store/ets.ex` contain zero `AuditWriter.append_event` calls." |
| 11 | PLAN 40-02: Closing receipt references `mix relyra.diagnostic` and mirrors CLAUDE.md brand voice.                                                                                                                              | ✓ VERIFIED | Closing receipt at lines 300-311 contains "Every login resolves to a verified trust path or a typed rejection — and when in doubt, the diagnostic bundle is the trace" + `mix relyra.diagnostic` invocation.                              |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact                                       | Expected                                                                                            | Status        | Details                                                                                                          |
|------------------------------------------------|-----------------------------------------------------------------------------------------------------|---------------|------------------------------------------------------------------------------------------------------------------|
| `guides/troubleshooting.md`                    | Error Atom Decoder grouped by trust-pipeline seam (DOCS-06 surface)                                | ✓ VERIFIED    | 1202 lines, 78 H3 atom entries, 7 bucket H2s + framing/sub-frame H2s + closing H2 (12 total), four-field micro-block × 78. |
| `test/docs/troubleshooting_drift_test.exs`     | Bidirectional drift test enforcing code/doc atom parity (DOCS-06 gate)                              | ✓ VERIFIED    | 159 lines, module `Relyra.Docs.TroubleshootingDriftTest`, `use ExUnit.Case, async: true`, 4 regex attributes, 2 assertions. |
| `guides/operations/incident_playbook.md`       | Operator incident playbook stitching telemetry/audit/admin-UI/Mix tasks (DOCS-05 surface)          | ✓ VERIFIED    | 310 lines, 11 H2 sections, 6 scenarios, 5-surface table, doubled-H2 preamble, brand-voice closing receipt.        |
| `mix.exs`                                      | ExDoc extras + ci.docs presence guard + drift-test step + playbook presence guard                  | ✓ VERIFIED    | Extras at 134-135 (troubleshooting, playbook); ci.docs at 158-160 (both presence guards, drift-test cmd line).    |

### Key Link Verification

| From                                            | To                                              | Via                                                                  | Status      | Details                                                                                                                |
|-------------------------------------------------|-------------------------------------------------|----------------------------------------------------------------------|-------------|------------------------------------------------------------------------------------------------------------------------|
| `test/docs/troubleshooting_drift_test.exs`      | `lib/**/*.ex`                                   | `Path.wildcard("lib/**/*.ex")` + three D-08 regex scans              | ✓ WIRED     | `scan_code_atoms/0` at lines 102-119 calls `Path.wildcard("lib/**/*.ex")` and applies all three D-08 regexes per file. |
| `test/docs/troubleshooting_drift_test.exs`      | `guides/troubleshooting.md`                     | `File.read!` + D-09 H3 regex scan                                    | ✓ WIRED     | `scan_doc_atoms/0` at lines 121-138 reads the file via `File.read` and applies `@doc_pattern` regex.                   |
| `mix.exs` `extras:`                             | `guides/troubleshooting.md`                     | Append in `docs/0` extras (D-17)                                     | ✓ WIRED     | mix.exs:134 — appears after `guides/recipes/logout.md` (D-17 order verified).                                          |
| `mix.exs` `extras:`                             | `guides/operations/incident_playbook.md`        | Append in `docs/0` extras (D-17)                                     | ✓ WIRED     | mix.exs:135 — appears immediately after troubleshooting.md (D-17 order verified).                                       |
| `mix.exs` `ci.docs`                             | `guides/troubleshooting.md`                     | `cmd test -f` presence guard (D-18)                                  | ✓ WIRED     | mix.exs:158 — after logout.md guard, before playbook guard.                                                            |
| `mix.exs` `ci.docs`                             | `guides/operations/incident_playbook.md`        | `cmd test -f` presence guard (D-18)                                  | ✓ WIRED     | mix.exs:159 — between troubleshooting guard and drift-test cmd line.                                                   |
| `mix.exs` `ci.docs`                             | `test/docs/troubleshooting_drift_test.exs`      | `cmd mix test ... --warnings-as-errors` (D-19)                       | ✓ WIRED     | mix.exs:160 — single match; placed after both presence guards (D-19 order verified).                                    |
| `guides/operations/incident_playbook.md`        | `guides/troubleshooting.md`                     | Five-surface table cross-link + per-scenario atom anchor links       | ✓ WIRED     | 16 references to `troubleshooting.md` in the playbook.                                                                  |
| `guides/operations/incident_playbook.md`        | `lib/relyra/telemetry.ex`                       | Verbatim event citations in surface row 1 + scenario triage steps    | ✓ WIRED     | 25 verbatim `[:relyra, :saml,` citations across the document.                                                          |
| `guides/operations/incident_playbook.md`        | `lib/mix/tasks/relyra.diagnostic.ex`            | Closing receipt + scenario diagnose steps                            | ✓ WIRED     | 4 `mix relyra.diagnostic` invocations (closing receipt + 3 scenarios).                                                  |

### Data-Flow Trace (Level 4)

| Artifact                                       | Data Variable                            | Source                                                                | Produces Real Data | Status     |
|------------------------------------------------|------------------------------------------|-----------------------------------------------------------------------|--------------------|------------|
| `test/docs/troubleshooting_drift_test.exs`     | `code_atoms` (MapSet of emitted atoms)   | `Path.wildcard("lib/**/*.ex")` + Regex.scan against actual lib files  | Yes — produces 78  | ✓ FLOWING  |
| `test/docs/troubleshooting_drift_test.exs`     | `doc_atoms` (MapSet of documented atoms) | `File.read!("guides/troubleshooting.md")` + Regex.scan H3 pattern    | Yes — produces 78  | ✓ FLOWING  |
| `guides/troubleshooting.md`                    | N/A (static documentation)               | Static markdown                                                       | N/A (doc artifact) | ✓ FLOWING  |
| `guides/operations/incident_playbook.md`       | N/A (static documentation)               | Static markdown                                                       | N/A (doc artifact) | ✓ FLOWING  |

### Behavioral Spot-Checks

| Behavior                                                                                       | Command                                                                                  | Result                                              | Status |
|------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|-----------------------------------------------------|--------|
| Drift test passes with current code/doc parity                                                 | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`                 | `1 test, 0 failures`; exit 0                        | ✓ PASS |
| Full `ci.docs` end-to-end (DOCS-05 + DOCS-06 combined gate)                                    | `mix ci.docs`                                                                            | exit 0; all presence guards pass; all tests green   | ✓ PASS |
| Troubleshooting decoder file exists                                                            | `test -f guides/troubleshooting.md`                                                      | exit 0                                              | ✓ PASS |
| Incident playbook file exists                                                                  | `test -f guides/operations/incident_playbook.md`                                         | exit 0                                              | ✓ PASS |
| Atom count parity (D-08 union vs D-09 H3 count)                                                | `grep -cE '^### :[a-z_][a-z0-9_]*$' guides/troubleshooting.md`                           | 78 (matches locked count from Plan 01 SUMMARY)      | ✓ PASS |
| `:connection_id` is the correct route param (NOT `:id`)                                        | `! grep -F '/relyra/admin/connections/:id' guides/operations/incident_playbook.md`       | 0 matches of wrong form; 13 of correct form         | ✓ PASS |
| Brand-voice closing in playbook                                                                | `grep -F 'verified trust path or a typed rejection' guides/operations/incident_playbook.md` | 1 match                                          | ✓ PASS |
| Phase 30 invariant: `ci.security` alias byte-identical to base                                  | `diff <(awk ci.security mix.exs) <(git show c80742c:mix.exs ...)`                        | empty diff                                          | ✓ PASS |
| Phase 30 invariant: `ci_gate_integrity_test.exs` byte-identical to base                         | `git diff c80742c -- test/security/ci_gate_integrity_test.exs`                           | empty diff                                          | ✓ PASS |

### Probe Execution

No probe-based verification declared by the phase plan or `ci.security`-style PASS-marker conventions. The phase's primary gate is the `mix ci.docs` Mix alias chain (executed above) which functions as the equivalent end-to-end runnable check.

| Probe                                                                       | Command                                                                  | Result                | Status |
|-----------------------------------------------------------------------------|--------------------------------------------------------------------------|-----------------------|--------|
| `mix ci.docs` (the DOCS-05 + DOCS-06 combined acceptance gate)              | `mix ci.docs`                                                            | exit 0                | ✓ PASS |
| `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`    | `mix test ... --warnings-as-errors`                                      | exit 0; 1 test, 0 fails | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description                                                                                                                                                                              | Status      | Evidence                                                                                                                                       |
|-------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| DOCS-05     | 40-02-PLAN  | Publish `guides/operations/incident_playbook.md` providing a narrative playbook that stitches together telemetry, audit events, the LiveView admin, and Mix tasks.                       | ✓ SATISFIED | Playbook exists (310 lines); 5-surface table cites all 4 evidence surfaces + decoder cross-link verbatim; 6 Triage→Diagnose→Recover scenarios. |
| DOCS-06     | 40-01-PLAN  | Publish `guides/troubleshooting.md` acting as a SAML error atom decoder, paired with an automated drift-check test to ensure documentation matches the code's error taxonomy.            | ✓ SATISFIED | Decoder exists (78 H3 atoms, four-field micro-block); bidirectional drift test exists and exits 0; wired into `ci.docs` (presence guard + cmd line). |

No orphaned requirements. REQUIREMENTS.md maps exactly DOCS-05 and DOCS-06 to Phase 40, and both are claimed by Plan 01 (DOCS-06) and Plan 02 (DOCS-05) frontmatter respectively.

### Anti-Patterns Found

No anti-patterns introduced by Phase 40. Targeted scans on the three files modified by this phase:

| File                                          | Line | Pattern                                  | Severity | Impact                                                                                       |
|-----------------------------------------------|------|------------------------------------------|----------|----------------------------------------------------------------------------------------------|
| `test/docs/troubleshooting_drift_test.exs`    | —    | No TODO/FIXME/HACK/placeholder/stub      | —        | Clean.                                                                                       |
| `guides/troubleshooting.md`                   | —    | No TODO/FIXME/HACK/placeholder/stub      | —        | Clean.                                                                                       |
| `guides/operations/incident_playbook.md`      | —    | No TODO/FIXME/HACK/placeholder/stub      | —        | Clean.                                                                                       |
| `mix.exs`                                     | —    | Append-only extras + ci.docs edits       | —        | No debt markers; `ci.security` byte-identical to base commit c80742c.                          |

**Note on pre-existing `mix format` drift:** A pre-existing format drift in `test/security/xml/adversarial_crypto_test.exs` (carried over from Phase 38) is documented in `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md`. Verified byte-identical to Phase 40 base commit `c80742c` — NOT introduced by Phase 40. Out of scope per the SCOPE BOUNDARY rule.

### Code Review Findings (40-REVIEW.md)

Phase 40 has a standard-depth code review on file (`40-REVIEW.md`):
- 0 critical, 2 warning (WR-01 redundant multi-line regex; WR-02 cwd-relative path could create hollow-gate), 3 info findings.
- None block the goal; both warnings are correctness-style observations on the drift test itself (the test still functions correctly because `\s` already matches `\n`, and `mix test` always runs from project root in CI). Tracked in the review report; not gating for goal achievement.

### Human Verification Required

None. The phase deliverables are documentation + a deterministic drift-check test. All verification steps are programmatically checkable:

- File existence: verified via `test -f`.
- Structural contracts (H3 count, micro-block field count, H2 buckets): verified via `grep -c`.
- Drift parity: verified via the bidirectional test itself, which the developer can re-run any time `lib/` changes.
- mix.exs wiring: verified via line-numbered `grep -n` against D-17/D-18/D-19 anchors.
- ci.docs end-to-end: verified via `mix ci.docs` exit 0.
- Phase 30 invariant: verified via `diff` against base commit `c80742c`.

The 40-REVIEW.md IN-02 finding suggests a manual `mix docs` render-and-click sanity check on intra-doc anchor resolution (`../troubleshooting.md#atom_name` style links), but this is a "post-publish polish" item, not a goal-achievement gate. It is appropriately classified as Info, not blocking.

### Gaps Summary

No gaps found. Every must-have for the phase goal — operators can decode atoms (decoder published, gated against drift) and have a clear incident response playbook (5-surface table, 6 scenarios, brand-voice closing) — is verified in the codebase with direct evidence. The DOCS-05 + DOCS-06 combined `mix ci.docs` gate exits 0 end-to-end. The Phase 30 hollow-gate invariant for `ci.security` is preserved (byte-identical to base).

The pre-existing `mix format` drift in `test/security/xml/adversarial_crypto_test.exs` is correctly classified as out-of-scope (verified byte-identical to base commit c80742c) and tracked in `deferred-items.md` for future cleanup.

---

_Verified: 2026-05-27T11:35:00Z_
_Verifier: Claude (gsd-verifier)_
