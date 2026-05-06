# Phase 14: Mapping/audit milestone verification - Research

**Researched:** 2026-05-06
**Domain:** Verification-and-traceability closure for already-shipped mapping/audit behavior (`CFG-05`)
**Confidence:** HIGH (every locked decision in 14-CONTEXT.md maps to a concrete repo-local precedent; every test file in the D-06 packet is verified to exist on disk)

## Summary

Phase 14 is a pure verification-and-traceability closure phase. Phase 11 implementation already shipped, all four plans are complete and committed, `11-VALIDATION.md` is `nyquist_compliant: true` and `wave_0_complete: true`, and the focused mapping/audit suite already passes (`19 tests, 0 failures` per `v0.2-MILESTONE-AUDIT.md`). The only remaining gap is the missing `11-VERIFICATION.md` artifact and the live-truth files that still treat `CFG-05` as orphaned/pending. Phase 13 just executed the same closure pattern for `CFG-04` and produced two reusable templates: `10-VERIFICATION.md` (artifact shape) and `13-03-PLAN.md` + `13-03-SUMMARY.md` (live-truth refresh shape). Phase 14 ports those templates verbatim, rebinding `CFG-04 -> CFG-05`, certificate-rollover behaviors -> mapping/audit behaviors, and Phase 13 status strings -> Phase 14 status strings.

**Primary recommendation:** Treat `10-VERIFICATION.md` as the byte-for-byte structural template for `11-VERIFICATION.md` (Scope -> Requirement Traceability -> Phase-Audit Gap Closed -> Automated Evidence Packet -> Evidence Map -> Manual Sign-Off), and treat `13-03-PLAN.md` as the byte-for-byte structural template for `14-02-PLAN.md`. Do not invent new artifact shapes; rebind labels and proof surfaces only. The four-row CFG-05 evidence map (D-07) and two manual sign-off prompts (D-10) are the only places where new prose composition is required.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Produce `11-VERIFICATION.md` artifact | Planning / `.planning/` documentation tier | — | Verification artifacts live next to the phase they verify; `10-VERIFICATION.md` set the precedent. |
| Run the 3-command serial proof packet | Mix test runner (Elixir test tier) | — | The packet exercises Ecto persistence, runtime hydration, and cross-domain audit code paths already implemented in Phase 11. |
| Refresh live-truth files | Planning / `.planning/` root truth tier | — | `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` are the canonical current-state carriers per `13-PATTERNS.md`. |
| Manual semantics sign-off | Human reviewer tier (operator semantics judgment) | — | D-10 caps human review at exactly two narrow semantics judgments; functional correctness is automated per D-11. |
| Preserve historical audit evidence | None — read-only | — | `v0.2-MILESTONE-AUDIT.md` is point-in-time; D-03 forbids mutation. |

## Phase Boundary

Phase 14 closes `CFG-05` by producing the missing `11-VERIFICATION.md` from a balanced, serial, three-command proof packet plus exactly two narrow manual semantics judgments, then refreshing the minimum live-truth files (`REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`) so milestone traceability marks `CFG-05` complete from verification evidence rather than plan completion alone. It does **not** reopen Phase 11 implementation, redesign mapping semantics or audit architecture, mutate any historical audit artifact, add a `11-VALIDATION.md` sync plan (already `complete` and `nyquist_compliant: true`), parallelize the verification packet, or use the manual gate to re-prove functional correctness the automated packet already covers.

## Validation Architecture

> Nyquist enabled: `workflow.nyquist_validation: true` in `.planning/config.json`. Phase 14 will produce `14-VALIDATION.md` from this section.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix on Elixir `1.19.5` [VERIFIED: `11-VALIDATION.md` test infrastructure block] |
| Config file | `mix.exs`, `test/test_helper.exs`, `config/test.exs` [VERIFIED: same] |
| Quick run command | The single focused mapping/audit command from D-06 step 2 |
| Full suite command | `mix test --warnings-as-errors` |
| Estimated runtime | < 60s for the focused phase smoke; < 2 min for full suite (extrapolated from Phase 13's `168 tests` baseline) |

### CFG-05 Proof Surface — Three-Command Serial Packet

Per D-04 / D-05 / D-06, the verification packet is exactly three commands, executed serially in this order. Parallelization is forbidden because parallel Mix migration bootstraps race the `schema_migrations` create (called out in `v0.2-MILESTONE-AUDIT.md` audit notes and again in `11-01-SUMMARY.md` "Deviations from Plan" — a parallel rerun of the schema suite already collided in this exact codebase).

```
1. mix compile --warnings-as-errors
2. mix test test/relyra/ecto/mapping_commands_test.exs \
            test/relyra/ecto/audit_hardening_test.exs \
            test/relyra/ecto/attribute_mapping_schema_test.exs \
            test/relyra/ecto/group_mapping_schema_test.exs \
            test/relyra/ecto/mapping_revision_schema_test.exs \
            test/relyra/ecto/audit_event_schema_test.exs \
            test/relyra/ecto/migration_constraints_test.exs \
            test/relyra/connection_snapshot_test.exs \
            test/relyra/user_mapper/default_attribute_test.exs \
            test/relyra/ecto/ecto_connection_resolver_test.exs \
            test/relyra/ecto/connection_record_test.exs \
            test/relyra/ecto/metadata_apply_test.exs \
            test/relyra/ecto/certificate_inventory_transition_test.exs \
            --warnings-as-errors
3. mix test --warnings-as-errors
```

All 13 test files in step 2 are verified present on disk as of 2026-05-06 [VERIFIED: `ls test/relyra/ecto/*_test.exs test/relyra/{connection_snapshot,user_mapper/default_attribute}_test.exs`]. Nothing in Wave 0 needs to be created.

### CFG-05 Behavior-to-Test/Evidence Map (4 rows per D-07)

This is the exact table the planner must put in `11-VERIFICATION.md`'s `## Requirement Traceability` section. Test paths come straight from D-06; cross-references come straight from D-07.

| # | CFG-05 behavior | Proof tests | Cross-reference summaries |
|---|-----------------|-------------|---------------------------|
| 1 | **Mapping persistence (live rows + revision ledger)** — attribute and group mappings persist on bounded child tables; mapping revisions append-only with actor/cause/before/after; DDL constraints (FK, ownership, uniqueness) enforced; no JSON/blob config on `relyra_connections`. | `test/relyra/ecto/mapping_commands_test.exs`, `test/relyra/ecto/attribute_mapping_schema_test.exs`, `test/relyra/ecto/group_mapping_schema_test.exs`, `test/relyra/ecto/mapping_revision_schema_test.exs`, `test/relyra/ecto/migration_constraints_test.exs` | `11-01-SUMMARY.md` (live-row + ledger schemas), `11-02-SUMMARY.md` (canonical migration), `11-04-SUMMARY.md` (transactional row replacement + revision write) |
| 2 | **Cross-domain audit hardening (same-transaction capture)** — connection, metadata, certificate, and mapping mutations append durable attributable audit rows in the same `Repo.transact` boundary; failed/conflicting writes leave zero orphan audit rows; payloads stay redaction-safe. | `test/relyra/ecto/audit_hardening_test.exs`, `test/relyra/ecto/audit_event_schema_test.exs`, `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs` | `11-03-SUMMARY.md` (shared `AuditWriter`, audited connection/metadata/certificate boundaries, rollback safety) |
| 3 | **Audited mapping mutation surface (typed commands, no parent-write back-channel)** — mapping mutations flow only through `Relyra.Ecto.MappingCommands` typed actions with deterministic multivalue handling; parent connection draft/update changesets reject `attribute_mappings` / `group_mappings`; mapping writes always emit a mapping revision and a `domain: :mapping` audit row. | `test/relyra/ecto/mapping_commands_test.exs`, `test/relyra/ecto/connection_record_test.exs` | `11-01-SUMMARY.md` (parent-write rejection), `11-04-SUMMARY.md` (dedicated command surface) |
| 4 | **Runtime `mapping_config` hydration (persistence-agnostic plain values)** — `Relyra.Ecto.ConnectionSnapshot` emits plain `mapping_config` maps with normalized `attribute_rules` / `group_rules` and deterministic ordering; `Relyra.UserMapper.DefaultAttribute` consumes persisted rules first and falls back to legacy behavior when absent; Ecto rows never reach `%Relyra.Connection{}` consumers. | `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs` | `11-04-SUMMARY.md` (snapshot hydration + persisted-config-first mapper) |

### Sampling Rate

- **Per task commit (14-01):** the focused mapping/audit command from packet step 2.
- **Per wave merge (14-01 wave):** all three packet commands serially (this IS the verification artifact's evidence).
- **Phase gate:** `mix test --warnings-as-errors` green before live-truth refresh in 14-02.

### Wave 0 Gaps

- **None.** Every test file in the D-06 packet exists today [VERIFIED: filesystem check]. `11-VALIDATION.md` is already `wave_0_complete: true`. No new fixtures, framework installs, or test files are needed.

### Manual Sign-Off Coverage Gap (the 2 D-10 prompts)

Manual sign-off plugs **only** these two semantics gaps the automated packet cannot fully judge. Per D-11 they MUST NOT be used to re-prove functional correctness.

| Manual prompt # | Semantics judgment | What human reviews | Why this is not automatable |
|-----------------|--------------------|--------------------|------------------------------|
| 1 | Cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material. | Representative audit rows produced by `audit_hardening_test.exs`, `connection_record_test.exs`, `metadata_apply_test.exs`, `certificate_inventory_transition_test.exs`, plus `lib/relyra/ecto/audit_writer.ex` and `lib/relyra/ecto/audit_event.ex`. | Tests assert structural redaction and required fields, but the qualitative judgment "this is reviewable trust narrative, not a row dump" is product-semantic per `11-CONTEXT.md` UX principle. |
| 2 | Runtime `mapping_config` contract stays persistence-agnostic — plain `attribute_rules` / `group_rules`, deterministic ordering, persisted-rules-first with fallback — so host-app `Relyra.UserMapper` consumers see stable values. | `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper/default_attribute.ex`, plus `connection_snapshot_test.exs`, `ecto_connection_resolver_test.exs`, `user_mapper/default_attribute_test.exs`. | Tests prove ordering and field shape, but the API-stability judgment "host apps will not be surprised here" is product-contract semantic per `11-CONTEXT.md` D-04 / D-05. |

## 11-VERIFICATION.md Artifact Spec

**Target path:** `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md`

**Authoring template:** `10-VERIFICATION.md` (1-to-1 structural mirror per D-08). Section order is **fixed**.

### Required sections (in order)

1. **Title:** `# Phase 11 Verification`
2. **`## Scope`** — one paragraph stating this artifact closes `CFG-05` milestone verification for Phase 11 by recording the compact serial evidence packet defined in Phase 14 and the blocking manual approval gate for the two remaining mapping/audit semantics checks.
3. **`## Requirement Traceability`** — opens with: `Requirement: \`CFG-05\` - User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` Followed by the **4-row table** above (D-07). Column headers MUST match `10-VERIFICATION.md`: `| CFG-05 behavior | Proof source | Evidence |`. Each row's "Proof source" cell names the focused command **plus** the relevant cross-reference summary file(s); each row's "Evidence" cell records the observed result (`nn tests, 0 failures`) plus a one-sentence narrative tying it back to the behavior.
4. **`## Phase-Audit Gap Closed`** — names the gap from `v0.2-MILESTONE-AUDIT.md` (Phase 11 had no `11-VERIFICATION.md`; focused mapping/audit suite passed `19 tests, 0 failures` but milestone audit treated `CFG-05` as orphaned), then a Closure evidence bullet list mirroring `10-VERIFICATION.md` lines 22-26: this file now exists; the focused serial packet now passes; the full serial suite now passes; remaining human approval is isolated to the two D-10 semantics judgments.
5. **`## Automated Evidence Packet`** — opens with the explicit serial-only declaration (verbatim from `10-VERIFICATION.md` line 30: "Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the rollover validation contract..." rebound to **mapping/audit** validation contract). Then a 3-row execution table with columns `| Order | Executed at (UTC) | Exact command | Status | Result |`. The three rows correspond to the three D-06 commands in order. Each row records `Executed at` as an ISO-8601 UTC timestamp captured at execution time; `Status` is `passed` or `failed`; `Result` is `compile succeeded with no warnings` for command 1, `nn tests, 0 failures` for commands 2 and 3. Closes with the serial-execution note: order 1 completed before order 2 started, order 2 before order 3, no parallel Mix.
6. **`## Evidence Map`** — four `### <behavior>` subsections matching the D-07 row labels exactly: `### Mapping persistence (live rows + revision ledger)`, `### Cross-domain audit hardening (same-transaction capture)`, `### Audited mapping mutation surface`, `### Runtime mapping_config hydration`. Each subsection: 1-3 bullets pointing at the proof tests + relevant `lib/relyra/ecto/*.ex` source(s) + the cross-reference summary file from D-07. The fourth subsection MUST also cite the full `mix test --warnings-as-errors` confirmation step.
7. **`## Manual Sign-Off`** — opens: "The automated packet is complete. The remaining approval gate is limited to the two semantics checks Phase 14 locked:" followed by a numbered list of the two D-10 prompts (verbatim wording is the agent's discretion per the CONTEXT.md "Claude's Discretion" line, but they MUST stay semantics-only and stay narrow). Then `Human review instructions:` bullets pointing at the exact files/tests the human should read for each check. Then `Human review result:` block recording approval date and concise prose for each of the two checks. Closes with `Manual approval status: approved.` (single line) once approved.

### Timestamp / observed-result format

- **Timestamps:** ISO-8601 UTC with `Z` suffix, backtick-wrapped, captured at command execution time. Format: `` `2026-05-06T07:04:03Z` `` (verbatim style from `10-VERIFICATION.md` line 34).
- **Test result strings:** literal Mix output line `nn tests, 0 failures`, backtick-wrapped (e.g., `` `19 tests, 0 failures` ``). The Phase 11 audit recorded `19 tests, 0 failures` for the *previous* focused suite; the Phase 14 packet adds the cross-domain audit + connection_record + metadata_apply + certificate_inventory_transition files, so the new count will be larger. The number is whatever the actual packet produces — do not pre-fill.
- **Compile result:** literal string `compile succeeded with no warnings` per `10-VERIFICATION.md` precedent.
- **Approval date:** ISO date (`2026-05-06`), backtick-wrapped per `10-VERIFICATION.md` line 75.

### What 11-VERIFICATION.md MUST NOT contain

- No mention of historical audit-artifact mutation [D-03].
- No `11-VALIDATION.md` sync narrative — `11-VALIDATION.md` is already complete; this artifact only consumes it [D-02].
- No parallel-execution evidence [D-05].
- No manual sign-off statements that re-prove functional correctness [D-11].
- No expansion into general milestone cleanup or `CFG-06`+ scope [D-12 + Deferred Ideas].

## Live-Truth Refresh Map

**Plan target:** `14-02-PLAN.md`. Authoring template: `13-03-PLAN.md` (verbatim envelope, rebound from `CFG-04 -> CFG-05` and `Phase 13 -> Phase 14`). Files modified: exactly three.

### File 1: `.planning/REQUIREMENTS.md`

**Current state landmarks (verified 2026-05-06):**

- Line 16: `- [ ] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.`
- Line 54: `| CFG-05 | Phase 14 | Pending |`
- Line 63: `*Last updated: 2026-05-06 after Phase 13 execution*`

**Target edits:**

| Anchor | Before | After |
|--------|--------|-------|
| Requirement checkbox (line ~16) | `- [ ] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` | `- [x] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` |
| Traceability table (line ~54) | `\| CFG-05 \| Phase 14 \| Pending \|` | `\| CFG-05 \| Phase 14 \| Complete \|` |
| Footer stamp (line ~63) | `*Last updated: 2026-05-06 after Phase 13 execution*` | `*Last updated: 2026-05-06 after Phase 14 execution*` |

**Do NOT touch:** the Coverage block (lines 56-59) is already correct; CFG-01..CFG-04 rows; v1 Requirements; Out of Scope.

### File 2: `.planning/ROADMAP.md`

**Current state landmarks (verified 2026-05-06):**

- Phase 14 row in summary table (line 21): `| 14 | Mapping/audit milestone verification | Produce the missing mapping/audit milestone verification artifacts and close traceability. | CFG-05 |` — content is correct, no edit needed.
- Phase 14 detail block (lines 102-108): currently goal + gap-closure + 3 success criteria, **no Plans/Plan list/Status line**. This is the same shape Phase 13 was in before its own closure plan ran.

**Target edits — Phase 14 detail block only (D-07 forbids touching anything else):**

The Phase 13 detail block (lines 88-100 in current ROADMAP.md) is the exact post-closure shape Phase 14 must end up in. Specifically, the Phase 14 block must become:

```
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
```

The `- Status: complete (verified after Phase 14 execution).` line is **byte-aligned** with `13-03-PLAN.md` Task 1's grep verifier (`rg -nF -- '- Status: complete (verified after Phase 13 execution).' .planning/ROADMAP.md`). The `14-02-PLAN.md` plan should use this exact language so its own `rg -nF` verifier can prove the edit landed.

**Do NOT touch:** Phase 07-13 detail blocks; the v0.2 Phases summary table; v0.1 archive line; any other section.

### File 3: `.planning/STATE.md`

**Current state landmarks (verified 2026-05-06):**

- Frontmatter `last_activity` (line 7): `last_activity: 2026-05-06 -- Phase 14 context gathered (assumptions mode); ready for plan-phase`
- Frontmatter `progress.total_phases` (line 10): `total_phases: 7`
- Frontmatter `progress.completed_phases` (line 11): `completed_phases: 6`
- Frontmatter `progress.total_plans` (line 12): `total_plans: 23`
- Frontmatter `progress.completed_plans` (line 13): `completed_plans: 23`
- Current focus line (line 23): `**Current focus:** Phase 14 — mapping-audit-milestone-verification (context gathered, ready for plan-phase)`
- Current Position block (lines 27-31): `Phase: 14 (mapping-audit-milestone-verification) — CONTEXT GATHERED` + plan/status/last-activity lines.

**Target edits — frontmatter + Current Position block only:**

| Anchor | Before | After |
|--------|--------|-------|
| `status:` (line 6) | `status: complete` (already says `complete`; **leave as-is** — milestone status is already `complete` per Phase 13 closure) | `status: complete` (no change) |
| `last_updated:` (line 6) | `"2026-05-06T15:00:00Z"` | new ISO-8601 UTC timestamp at the moment of `14-02` execution |
| `last_activity:` (line 7) | `2026-05-06 -- Phase 14 context gathered (assumptions mode); ready for plan-phase` | `2026-05-06 -- Phase 14 execution completed; CFG-05 verified and closed` (or equivalent — exact prose is agent discretion per D-08) |
| `progress.total_plans` (line 12) | `total_plans: 23` | `total_plans: 25` (Phase 14 adds 14-01 and 14-02) |
| `progress.completed_plans` (line 13) | `completed_plans: 23` | `completed_plans: 25` |
| `progress.completed_phases` (line 11) | `completed_phases: 6` | `completed_phases: 7` |
| `**Current focus:**` (line 23) | `Phase 14 — mapping-audit-milestone-verification (context gathered, ready for plan-phase)` | `Phase 14 — mapping-audit-milestone-verification (complete)` |
| Current Position phase line (line 27) | `Phase: 14 (mapping-audit-milestone-verification) — CONTEXT GATHERED` | `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE` |
| Plan count (line 28) | `Plan: 0 of 0 (planning pending)` | `Plan: 2 of 2` |
| Status line (line 29) | `Status: 14-CONTEXT.md written (assumptions mode); ready for /gsd-plan-phase 14` | `Status: Execution complete; CFG-05 closed` (agent discretion within the locked focus/phase strings above) |
| Last activity (line 30) | matches frontmatter `last_activity` | match the new frontmatter `last_activity` |
| Resume file (line 31) | `.planning/phases/14-mapping-audit-milestone-verification/14-CONTEXT.md` | `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` (the new authoritative artifact) |

**Status / focus strings the planner should make grep-verifiable in `14-02-PLAN.md`** (mirroring the `13-03-PLAN.md` Task 1 verify block):

- `**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)`
- `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE`

These two strings are the canonical Phase-13-style closure markers. `14-02-PLAN.md` should grep them with `rg -nF` to prove the edit landed.

**Do NOT touch:** Performance Metrics table; Project Reference link; Progress bar art (it's already 100% and stays 100%); Core value line.

### What Phase 14 Live-Truth Refresh MUST NOT Touch

Per D-03 and the Deferred Ideas list:

- `.planning/v0.2-MILESTONE-AUDIT.md` — historical audit, point-in-time evidence. Re-audit is a separate workflow.
- Any `.planning/phases/<NN>-*/...` summary, plan, validation, verification, or context file outside Phase 14 (including `11-VALIDATION.md`, which D-02 explicitly excludes).
- `.planning/PROJECT.md` (currently still says CFG-01..CFG-05 are Active/unchecked; the Coverage column on REQUIREMENTS.md is the authoritative live-truth surface and is what milestone re-audit reads).

> **Side note for the planner (not a Phase 14 action):** `PROJECT.md` lines 50-54 still show all five CFG-* requirements as `[ ]` Active even though CFG-01..CFG-04 are verified complete. This is pre-existing drift that long predates Phase 14. The Phase 14 deferred-ideas list explicitly excludes "broader milestone-state cleanup beyond the files Phase 14 directly settles," and CONTEXT.md only names REQUIREMENTS.md / ROADMAP.md / STATE.md as the live-truth surfaces. Leave PROJECT.md alone in Phase 14; it is `/gsd-complete-milestone` territory.

## Execution Ordering & Dependencies

### Hard ordering: 14-01 must precede 14-02

CONTEXT.md "Claude's Discretion" allows ordering flexibility *as long as* `11-VERIFICATION.md` exists before live-truth refresh declares CFG-05 closed. The planner should encode this as a hard `depends_on: ["14-01"]` on `14-02-PLAN.md`. Reasons:

1. **Truth dependency.** REQUIREMENTS.md flipping `CFG-05` to `[x]` is a claim that verification evidence exists. If the artifact does not exist when the flip lands, milestone truth is briefly false.
2. **Grep-verifier dependency.** `14-02-PLAN.md`'s `rg` checks for the Phase 14 closure strings. Those checks are meaningful only after `11-VERIFICATION.md` has been signed off — otherwise an automatic `14-02` run could land prematurely on a blocked manual gate.
3. **Phase 13 precedent.** `13-03-PLAN.md` declared `depends_on: ["13-02"]` for the same reason.

### Sequencing within 14-01

`14-01-PLAN.md` itself has internal ordering inherited verbatim from `13-02-PLAN.md`:

1. **Task 1 (auto):** Run the three serial commands in order, capture timestamps + results, write `11-VERIFICATION.md` with the locked section list above. Verifier: the same `rg -nF` chain `13-02-PLAN.md` uses, rebound to CFG-05 + the four D-07 row labels (`| Mapping persistence (live rows + revision ledger) |`, `| Cross-domain audit hardening (same-transaction capture) |`, `| Audited mapping mutation surface |`, `| Runtime mapping_config hydration |`).
2. **Task 2 (checkpoint:human-verify, gate=blocking):** Present the two D-10 manual checks. On approval, write the prose into `## Manual Sign-Off`. On rejection, record the blocking issue and stop closure rather than softening semantics. Verifier: `rg -nF` for `## Manual Sign-Off`, `Manual approval status: approved.`, and the two narrow check sentences (planner picks the exact wording per CONTEXT.md "Claude's Discretion" but the wording must then match the verifier's literal grep target).

### Other dependencies the planner must encode

- **`14-01-PLAN.md` `depends_on`:** None (it's the first plan in Phase 14, and `11-VALIDATION.md` is already complete per D-02 so there is no upstream sync plan).
- **`14-02-PLAN.md` `depends_on`:** `["14-01"]` (hard).
- **`autonomous` flag:** `false` for `14-01-PLAN.md` (has a blocking human gate), `true` for `14-02-PLAN.md` (pure file edits, deterministic, fully verifiable by `rg -nF`). This matches `13-02`/`13-03` exactly.

### Wave structure (per `13-VALIDATION.md` analog)

- Wave 1: `14-01-PLAN.md` (verification artifact production + manual gate).
- Wave 2: `14-02-PLAN.md` (live-truth refresh).

## Landmines & Pitfalls

### Landmine 1: Parallel Mix bootstrap race [HIGH severity]

**Source:** `v0.2-MILESTONE-AUDIT.md` (audit notes line: "Phase smoke commands that bootstrap the Ecto migration harness race if run in parallel. Serial execution avoids false failures.") + `11-01-SUMMARY.md` "Deviations from Plan" (a parallel rerun of the schema suite already collided on `schema_migrations` creation in this exact codebase) + `13-CONTEXT.md` D-04 + `14-CONTEXT.md` D-05.

**What goes wrong:** Parallel `mix test` invocations against the test database race the `schema_migrations` table create, producing false-failure verification runs that *look* like bugs but are pure harness contention.

**Avoid by:** Running the three D-06 commands strictly sequentially in `14-01` Task 1. The artifact must record `Execution mode: serial only.` verbatim and explicitly state "no parallel Mix commands were used" — same as `10-VERIFICATION.md` lines 30 and 38.

**Detection signal in 14-01:** If `mix test` reports unexpected failures around `schema_migrations` or migration locks, *first* suspect the harness, not the code. `.planning/config.json` has `parallelization: true` at the workflow level, but that flag controls planner / agent parallelism, not Mix command parallelism. The verification packet itself stays serial regardless of that config flag.

### Landmine 2: Mutating historical audit artifacts [BLOCKING — invalidates phase scope]

**Source:** D-03, `13-CONTEXT.md` D-07, `13-PATTERNS.md` "Live-Truth Minimalism", `13-03-SUMMARY.md` notes.

**What goes wrong:** Editing `.planning/v0.2-MILESTONE-AUDIT.md` (or any prior summary, prior verification, or prior validation file) to make it "agree" with the new closure state collapses the point-in-time audit role into the live-truth role. Future re-audits then cannot reconstruct what was true at audit time.

**Avoid by:** Limiting `14-02` to **exactly** `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`. The plan's `files_modified` frontmatter must list those three files only. Re-audit is a separate workflow (`/gsd-audit-milestone`).

### Landmine 3: Routing functional correctness through the manual gate [D-11 violation]

**Source:** D-11, `13-CONTEXT.md` D-11.

**What goes wrong:** Phrasing a manual sign-off prompt as "confirm the audit writer redacts PEM material" is a functional check, not a semantics check — the automated packet (`audit_hardening_test.exs`) already proves redaction structurally. Routing it through human review duplicates work and softens the discipline of "automated proof first."

**Avoid by:** Keeping both D-10 prompts at the qualitative product-semantics level. The pattern from D-10 is `Confirm <X> reads like / stays like <product invariant>` — never `Confirm <X> works correctly`. The two prompts in this RESEARCH.md's Validation Architecture section are already in that shape.

### Landmine 4: Adding a `11-VALIDATION.md` sync plan [D-02 violation]

**Source:** D-02, `11-VALIDATION.md` frontmatter (`status: complete`, `nyquist_compliant: true`, `wave_0_complete: true`).

**What goes wrong:** The Phase 13 analog had three plans because Phase 10's `10-VALIDATION.md` was `wave_0_complete: false` and needed `13-01` to sync it. Phase 11's validation file is already complete on every axis, so adding an analogous `14-00` or `14-01-sync` plan would do nothing useful and would inflate Phase 14 beyond its locked two-plan shape.

**Avoid by:** Hard-coding exactly two plans in the planner output (`14-01-PLAN.md`, `14-02-PLAN.md`). If the plan-checker flags "Phase 14 has fewer plans than Phase 13," the correct response is to confirm it's intentional per D-01 / D-02, not to add a third plan.

### Landmine 5: Stale-but-passing test count drift

**Source:** `11-UAT.md` Test 4 evidence ("full Phase 11 verification suite passed (59 tests, 0 failures)") vs. `v0.2-MILESTONE-AUDIT.md` (`19 tests, 0 failures` for the focused suite at audit time).

**What goes wrong:** The audit recorded a 19-test count for a *narrower* focused suite. The Phase 14 packet (D-06 step 2) is wider — it includes `connection_record_test.exs`, `metadata_apply_test.exs`, `certificate_inventory_transition_test.exs` for the cross-domain audit hardening axis. The actual count when executed will be higher. The planner / executor must not pre-fill `19 tests, 0 failures` from the audit doc; capture the *actual* count when the command runs.

**Avoid by:** `14-01` Task 1's action explicitly says "record observed result" — leave the count to be filled at execution time, same way `10-VERIFICATION.md` recorded `23 tests, 0 failures` (not the older Phase-10-audit-time count of `8 tests, 0 failures`).

### Landmine 6: Resume-file pointer staleness in STATE.md

**Source:** `STATE.md` line 31 currently points at `14-CONTEXT.md`. After Phase 14 closes, the most useful resume-file pointer for an inbound reader is the new authoritative artifact, not the obsolete context file. Phase 13 set this precedent loosely — the planner should choose either `11-VERIFICATION.md` (artifact) or omit/repoint as appropriate. Either way, leaving the resume-file pointer aimed at a `*-CONTEXT.md` after the phase is `COMPLETE` is misleading.

**Avoid by:** Repoint the `Resume file:` line in STATE.md to `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` as part of the `14-02` edits.

## Project Constraints (from CLAUDE.md)

> **No `CLAUDE.md` exists at `/Users/jon/projects/relyra/CLAUDE.md`** [VERIFIED: filesystem check]. There are therefore no project-level directives to enforce beyond what `.planning/PROJECT.md` already encodes (strict trust posture, brand discipline, redaction posture, recommendation-first decision-handling). All Phase 14 constraints come from `14-CONTEXT.md` decisions D-01..D-12 and the locked precedents in Phases 10 / 11 / 13.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Phase 14 D-06 packet's "test count" will exceed `11-UAT.md`'s `59 tests` figure because it includes more files than UAT Test 4's command. | Validation Architecture / Landmine 5 | Low — count is captured at execution time; assumption only matters if executor pre-fills a number. |
| A2 | `STATE.md`'s `progress.total_plans: 23` should become `25` after Phase 14 (adds 2 plans). The `23` figure assumes Phase 13's three plans are already counted. | Live-Truth Refresh Map (File 3) | Low — verifiable by counting `*-PLAN.md` files in `.planning/phases/<NN>-*/`; planner can re-derive at execution time. |
| A3 | Repointing the `Resume file:` in STATE.md to `11-VERIFICATION.md` is the right post-closure target. | Landmine 6 | Low — Phase 13 did not set strict precedent here; planner's discretion under D-08 / D-12. |

**All other claims in this research are VERIFIED against repo state or CITED from the locked CONTEXT.md / 13-PATTERNS.md / 10-VERIFICATION.md precedents.**

## Open Questions

> Per CONTEXT.md, D-01..D-12 are locked and the discussion was assumptions-mode. The questions below are narrow, planner-actionable, and **none of them block planning**.

1. **Resume-file pointer choice** (low-impact, agent discretion under D-08).
   - What we know: STATE.md needs repointing away from `14-CONTEXT.md`.
   - What's unclear: aim at `11-VERIFICATION.md` (new authoritative artifact, my recommendation) vs. omit (Phase 13 left it pointing at the context file even after closure).
   - Recommendation: Repoint to `11-VERIFICATION.md`. Cleaner mental model for the next inbound agent.

2. **Phase 14 progress accounting on STATE.md** (low-impact, mechanical).
   - What we know: STATE.md frontmatter `progress` block currently shows `total_phases: 7, completed_phases: 6`.
   - What's unclear: whether to bump `completed_phases: 6 -> 7` *and* leave `total_phases: 7` (my recommendation) or whether the GSD convention treats verification phases as not counting separately. Phase 13's closure of itself already used this exact pattern — Phase 14 should mirror it.
   - Recommendation: Bump `completed_phases: 6 -> 7`, leave `total_phases: 7`, bump `total_plans: 23 -> 25` and `completed_plans: 23 -> 25`.

3. **Exact wording of the two D-10 manual prompts** (agent discretion per CONTEXT.md "Claude's Discretion").
   - What we know: D-10 supplies the semantic content; the planner picks exact prose.
   - What's unclear: nothing of substance — the recommended prose in Validation Architecture above already matches the D-10 source language closely.
   - Recommendation: Use the prose in this RESEARCH.md's Manual Sign-Off Coverage Gap table verbatim. The planner's `rg -nF` verifier will then have a stable literal grep target.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/14-mapping-audit-milestone-verification/14-CONTEXT.md` — locked decisions D-01..D-12, canonical refs, deferred ideas.
- `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md` — direct precedent for the "produce VERIFICATION.md from serial packet + blocking manual gate" plan envelope.
- `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md` — direct precedent for the "live-truth refresh in REQUIREMENTS.md, ROADMAP.md, STATE.md" plan envelope.
- `.planning/phases/13-certificate-rollover-validation-verification/13-PATTERNS.md` — Live-Truth Minimalism, Compact Verification Artifact, Serial-Only Evidence Recording, Closure-Plan Envelope shared patterns.
- `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` — byte-for-byte structural template (Scope -> Requirement Traceability -> Phase-Audit Gap Closed -> Automated Evidence Packet -> Evidence Map -> Manual Sign-Off).
- `.planning/phases/11-mapping-persistence-audit-hardening/11-VALIDATION.md` — `nyquist_compliant: true`, `wave_0_complete: true`, full task-to-test map.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-UAT.md` — six-axis evidence shape (Phase 14's 4-row map mirrors axes 1-4 + 6 collapsed).
- `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md`, `11-02-SUMMARY.md`, `11-03-SUMMARY.md`, `11-04-SUMMARY.md` — D-07 cross-reference targets.
- `.planning/v0.2-MILESTONE-AUDIT.md` — orphaned `CFG-05` evidence ("Phase 11 has no 11-VERIFICATION.md. Focused mapping/audit suite passed `19 tests, 0 failures`, but the requirement is still orphaned from milestone verification.") + serial-only audit note.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — current live-truth state, all line-anchor-verified.
- `.planning/config.json` — `workflow.nyquist_validation: true`.
- Filesystem check: all 13 D-06 test files exist on disk as of 2026-05-06.

### Secondary (MEDIUM confidence)

- `.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md` — locked verification-packet posture inherited.
- `.planning/phases/13-certificate-rollover-validation-verification/13-03-SUMMARY.md` — execution outcome confirming the live-truth-refresh pattern works as designed.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` — mapping persistence and audit boundary domain definitions.

### Tertiary (LOW confidence)

- None. Every claim in this research is anchored in repo-local primary sources.

## Metadata

**Confidence breakdown:**

- **Verification packet shape (D-06):** HIGH — every command and every test file is named in CONTEXT.md, and every test file is verified present on disk.
- **Artifact shape (D-08, D-09):** HIGH — `10-VERIFICATION.md` is the byte-for-byte template per D-08 and exists in repo.
- **4-row CFG-05 evidence map (D-07):** HIGH — rows are spelled out verbatim in CONTEXT.md D-07 and cross-references are verified summary files.
- **Manual sign-off prompts (D-10):** HIGH — semantic content is locked in CONTEXT.md D-10; only exact wording is agent discretion.
- **Live-truth refresh plan (D-12):** HIGH — `13-03-PLAN.md` is the direct line-by-line template; current-state landmarks in REQUIREMENTS.md / ROADMAP.md / STATE.md were grep-verified at research time.
- **Execution ordering:** HIGH — `13-02 -> 13-03` ordering is the documented precedent; CONTEXT.md "Claude's Discretion" explicitly allows order flexibility but constrains it to `11-VERIFICATION.md exists before live-truth declares CFG-05 closed`, which forces `14-01 -> 14-02`.
- **Pitfalls:** HIGH — every landmine is sourced directly from a locked decision (D-03, D-05, D-11, D-02) or from a documented prior incident (`11-01-SUMMARY.md` parallel collision; `v0.2-MILESTONE-AUDIT.md` serial-only warning).

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (30 days for stable repo-local closure-phase research; the underlying Phase 11 implementation is frozen and the precedents are byte-stable)
