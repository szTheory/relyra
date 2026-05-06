# Phase 14: Mapping/audit milestone verification - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 7 (1 verification artifact + 2 plans + 1 summary + 3 live-truth files)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` | test | batch | `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` | exact |
| `.planning/phases/14-mapping-audit-milestone-verification/14-01-PLAN.md` | config | batch | `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md` | exact |
| `.planning/phases/14-mapping-audit-milestone-verification/14-02-PLAN.md` | config | batch | `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md` | exact |
| `.planning/phases/14-mapping-audit-milestone-verification/14-01-SUMMARY.md` | doc | transform | `.planning/phases/13-certificate-rollover-validation-verification/13-02-SUMMARY.md` | exact |
| `.planning/phases/14-mapping-audit-milestone-verification/14-02-SUMMARY.md` | doc | transform | `.planning/phases/13-certificate-rollover-validation-verification/13-03-SUMMARY.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` (current state, lines 12-16, 48-54, 61-63) | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` (current state, Phase 13 detail block lines 88-100) | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` (current state, all anchors verified) | exact |

---

## Pattern Assignments

### `11-VERIFICATION.md` (test, batch)

**Analog:** `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` (byte-for-byte structural template per CONTEXT.md D-08).

**Section order pattern** (lines 1-79 — locked, fixed):

```md
# Phase 10 Verification

## Scope
## Requirement Traceability
## Phase-Audit Gap Closed
## Automated Evidence Packet
## Evidence Map
## Manual Sign-Off
```

**Apply to Phase 11:** Title becomes `# Phase 11 Verification`. Section order MUST match exactly. Each section's content shape is excerpted below.

---

**`## Scope` pattern** (lines 4-5):

```md
This artifact closes `CFG-04` milestone verification for Phase 10 by recording the compact serial evidence packet defined in Phase 13 and preserving the blocking manual approval gate for the two remaining rollover semantics checks.
```

**Apply to Phase 11:** One paragraph. Rebind `CFG-04 -> CFG-05`, `Phase 10 -> Phase 11`, `Phase 13 -> Phase 14`, `rollover semantics -> mapping/audit semantics`.

---

**`## Requirement Traceability` opening + table header pattern** (lines 7-11):

```md
## Requirement Traceability

Requirement: `CFG-04` - User can manage certificate inventory for a connection with expiry tracking and staged rollover.

| CFG-04 behavior | Proof source | Evidence |
| --- | --- | --- |
```

**Apply to Phase 11:** Opens with `Requirement: \`CFG-05\` - User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` Column headers MUST stay literal `| <CFG-NN> behavior | Proof source | Evidence |` per CONTEXT.md D-07 + RESEARCH.md `## Requirement Traceability` spec. Then 4 data rows from RESEARCH.md "CFG-05 Behavior-to-Test/Evidence Map" table.

---

**`## Requirement Traceability` row body pattern** (lines 12-16, one row example):

```md
| Expiry tracking | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`; `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` | Focused serial rollover packet passed with `23 tests, 0 failures`. `test/relyra/ecto/certificate_inventory_expiry_test.exs` proves imported and staged certificates persist real `not_before` and `not_after` facts before lifecycle decisions consume them. |
```

**Apply to Phase 11:** Each row's "Proof source" cell names the focused command **plus** the relevant cross-reference summary file(s) per CONTEXT.md D-07. Each row's "Evidence" cell records `nn tests, 0 failures` (real count from execution time, NOT pre-filled — see Landmine 5 in RESEARCH.md) plus a one-sentence narrative tying to the behavior. Four rows verbatim per RESEARCH.md table:
- `| Mapping persistence (live rows + revision ledger) | ... |`
- `| Cross-domain audit hardening (same-transaction capture) | ... |`
- `| Audited mapping mutation surface | ... |`
- `| Runtime mapping_config hydration | ... |`

---

**`## Phase-Audit Gap Closed` pattern** (lines 18-26):

```md
## Phase-Audit Gap Closed

Milestone audit gap being closed: `.planning/v0.2-MILESTONE-AUDIT.md` left `CFG-04` orphaned because Phase 10 had no `10-VERIFICATION.md`, and `10-VALIDATION.md` still described missing Wave 0 rollover proof even though the repo already carried the required serial coverage.

Closure evidence:
- This file now exists as the missing Phase 10 verification artifact.
- The focused serial rollover packet now passes against the current repo state.
- The full serial suite now passes after the focused rollover packet.
- The remaining human approval gate is isolated to the two semantics judgments defined in Phase 13.
```

**Apply to Phase 11:** Same shape. Rebind to: Phase 11 had no `11-VERIFICATION.md`; focused mapping/audit suite passed `19 tests, 0 failures` per audit time but milestone audit treated `CFG-05` as orphaned. Closure evidence bullets mirror lines 22-26 with mapping/audit phrasing. Note: `11-VALIDATION.md` is already `wave_0_complete: true` (D-02), so omit the validation-still-described-gaps clause from the analog — the gap is purely the missing `11-VERIFICATION.md` artifact.

---

**`## Automated Evidence Packet` pattern** (lines 28-38):

```md
## Automated Evidence Packet

Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the rollover validation contract and the milestone-audit warning that parallel Mix evidence is invalid for this phase.

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `2026-05-06T07:04:03Z` | `mix compile --warnings-as-errors` | passed | `compile succeeded with no warnings` |
| 2 | `2026-05-06T07:04:04Z` | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs ... --warnings-as-errors` | passed | `23 tests, 0 failures` |
| 3 | `2026-05-06T07:04:05Z` | `mix test --warnings-as-errors` | passed | `168 tests, 0 failures` |

Serial execution note: order `1` completed successfully before order `2` started, and order `2` completed successfully before order `3` started. No parallel Mix commands were used for this verification packet.
```

**Apply to Phase 11:**
- Opening sentence: rebind `rollover validation contract -> mapping/audit validation contract`. Keep `Execution mode: serial only.` verbatim per RESEARCH.md spec.
- 3 rows for the 3 D-06 commands. Order, status, and result columns match the analog exactly.
- Order 2 command lists all 13 D-06 test files (per RESEARCH.md Validation Architecture). The result count is whatever the actual run produces — DO NOT pre-fill (Landmine 5).
- Closing serial-execution note kept verbatim ("No parallel Mix commands were used for this verification packet.").

**Timestamp format:** ISO-8601 UTC, `Z` suffix, backtick-wrapped (e.g., `` `2026-05-06T07:04:03Z` ``). Captured at execution time.

**Compile result string:** Literal `compile succeeded with no warnings` (verbatim from line 34).

---

**`## Evidence Map` heading pattern** (lines 40-60):

```md
## Evidence Map

### Expiry tracking

- `test/relyra/ecto/certificate_inventory_expiry_test.exs` proves ...

### Staged promotion and rollback

- `test/relyra/ecto/certificate_inventory_transition_test.exs` proves ...
- `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` records ...

### Concurrency conflict handling

- `test/relyra/ecto/certificate_inventory_concurrency_test.exs` proves ...

### Active-only runtime trust hydration

- `test/relyra/ecto/ecto_connection_resolver_test.exs` proves ...
- `test/relyra/connection_snapshot_test.exs` proves ...
- `mix test --warnings-as-errors` confirms the focused rollover guarantees remain compatible with the broader runtime and Phoenix coverage.
```

**Apply to Phase 11:** Four `### <behavior>` subsections matching D-07 row labels exactly:
- `### Mapping persistence (live rows + revision ledger)`
- `### Cross-domain audit hardening (same-transaction capture)`
- `### Audited mapping mutation surface`
- `### Runtime mapping_config hydration`

Each subsection: 1-3 bullets pointing at proof tests + relevant `lib/relyra/ecto/*.ex` source(s) + cross-reference summary file from D-07. The fourth subsection MUST also cite the full `mix test --warnings-as-errors` confirmation step (per the Phase 10 analog's "Active-only runtime trust hydration" pattern at line 60).

---

**`## Manual Sign-Off` pattern** (lines 62-79):

```md
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
- The rollover API and typed conflict errors still make the caller action obvious: ...
- Runtime trust still consumes only active signing certificates ...

Manual approval status: approved.
```

**Apply to Phase 11:**
- Opening sentence: `The automated packet is complete. The remaining approval gate is limited to the two semantics checks Phase 14 locked:`
- Two numbered prompts from RESEARCH.md "Manual Sign-Off Coverage Gap" table verbatim:
  1. `Confirm cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material.`
  2. `Confirm the runtime mapping_config contract stays persistence-agnostic — plain attribute_rules / group_rules, deterministic ordering, persisted-rules-first with fallback — so host-app Relyra.UserMapper consumers see stable values.`
- `Human review instructions:` bullets pointing at:
  - `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/audit_event.ex`, `test/relyra/ecto/audit_hardening_test.exs`, `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs` (for prompt 1)
  - `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper/default_attribute.ex`, `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs` (for prompt 2)
- Approval-date format: backtick-wrapped ISO date (`` `2026-05-06` ``).
- Closing line `Manual approval status: approved.` (single literal line, exact verbatim — this is the grep-verifier target in `14-01-PLAN.md` Task 2).

**D-11 guard:** Both prompts MUST stay product-semantics. Pattern is `Confirm <X> reads like / stays like <product invariant>` — never `Confirm <X> works correctly` (Landmine 3).

---

### `14-01-PLAN.md` (config, batch)

**Analog:** `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md`

**Plan envelope frontmatter pattern** (lines 1-28):

```md
---
phase: 13-certificate-rollover-validation-verification
plan: 13-02
type: execute
wave: 2
depends_on: ["13-01"]
files_modified:
  - .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md
autonomous: false
requirements: [CFG-04]
must_haves:
  truths:
    - "Phase 10 has a verification artifact that proves expiry tracking, staged promotion, rollback/conflict handling, and active-only runtime trust for CFG-04."
    - "The exact compact serial verification packet is recorded with results and counts."
    - "The two manual semantics checks are approved in prose before CFG-04 is considered closed."
  artifacts:
    - path: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      provides: "Authoritative CFG-04 verification packet with serial command results and manual sign-off"
  key_links:
    - from: ".planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md"
      to: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      via: "exact serial packet and manual checks carried forward per D-05 and D-09"
      pattern: "CFG-04|serial only|Manual Sign-Off"
    - from: ".planning/v0.2-MILESTONE-AUDIT.md"
      to: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      via: "closes the orphaned CFG-04 verification gap without mutating historical audit evidence per D-07"
      pattern: "10-VERIFICATION.md|CFG-04"
---
```

**Apply to `14-01-PLAN.md`:**
- `phase: 14-mapping-audit-milestone-verification`
- `plan: 14-01`
- `type: execute`
- `wave: 1` (per RESEARCH.md Wave Structure: Wave 1 = `14-01-PLAN.md`)
- `depends_on: []` (per RESEARCH.md Execution Ordering: 14-01 has no upstream sync plan because D-02 forbids one)
- `files_modified: - .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md`
- `autonomous: false` (has blocking human gate, mirrors 13-02 exactly per RESEARCH.md)
- `requirements: [CFG-05]`
- `must_haves.truths`: rebind 3 bullets — Phase 11 verification artifact, the 3-command serial packet, the two CFG-05 manual semantics checks
- `must_haves.artifacts.path`: `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md`
- `key_links`: from `11-VALIDATION.md` (already `wave_0_complete: true`) and `v0.2-MILESTONE-AUDIT.md` to `11-VERIFICATION.md`. Patterns: `CFG-05|serial only|Manual Sign-Off` and `11-VERIFICATION.md|CFG-05`.

---

**`<execution_context>` and `<context>` block pattern** (lines 37-61):

```md
<execution_context>
@/Users/jon/.codex/get-shit-done/workflows/execute-plan.md
@/Users/jon/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/v0.2-MILESTONE-AUDIT.md
@.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md
@.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md
@.planning/phases/10-certificate-inventory-rollover/10-RESEARCH.md
@.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md
@.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md
@.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md
@.planning/phases/13-certificate-rollover-validation-verification/13-PATTERNS.md
@lib/relyra/ecto/certificate_inventory.ex
@lib/relyra/ecto/connection_snapshot.ex
@test/relyra/ecto/certificate_inventory_expiry_test.exs
@test/relyra/ecto/certificate_inventory_transition_test.exs
@test/relyra/ecto/certificate_inventory_concurrency_test.exs
@test/relyra/ecto/ecto_connection_resolver_test.exs
@test/relyra/connection_snapshot_test.exs
</context>
```

**Apply to `14-01-PLAN.md`:** Same `<execution_context>` block verbatim. `<context>` block rebound to:
- Live truth: `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `v0.2-MILESTONE-AUDIT.md`
- Phase 10 verification artifact analog: `10-VERIFICATION.md`
- Phase 11 inputs: `11-CONTEXT.md`, `11-VALIDATION.md`, `11-UAT.md`, `11-01-SUMMARY.md`, `11-02-SUMMARY.md`, `11-03-SUMMARY.md`, `11-04-SUMMARY.md`
- Phase 14 inputs: `14-CONTEXT.md`, `14-RESEARCH.md`, `14-PATTERNS.md`
- Code under verification: `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/audit_event.ex`, `lib/relyra/ecto/attribute_mapping.ex`, `lib/relyra/ecto/group_mapping.ex`, `lib/relyra/ecto/mapping_revision.ex`, `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper.ex`, `lib/relyra/user_mapper/default_attribute.ex`
- All 13 D-06 test files

---

**Task 1 (auto) pattern** (lines 65-73):

```md
<task type="auto">
  <name>Task 1: Produce the compact serial CFG-04 verification artifact</name>
  <files>.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md</files>
  <action>Run the locked verification packet serially per D-02 through D-04: `mix compile --warnings-as-errors`, one focused serial rollover command covering the five named proof files, then `mix test --warnings-as-errors`. Do not parallelize any Mix commands, and record serial execution explicitly because parallel evidence is invalid for this phase. Write `10-VERIFICATION.md` using the compact Phase 09 artifact structure: scope, requirement traceability, the audit gap being closed, automated evidence packet, evidence map, and manual sign-off. The traceability map must cover expiry tracking, staged promotion, rollback/conflict handling, resolver behavior, and active-only runtime hydration, citing the focused command, full-suite confirmation, and the existing Phase 10 implementation summary as needed. Keep the narrative recommendation-first and concise per D-03 and D-08, and do not reopen lifecycle semantics or broaden into milestone cleanup.</action>
  <verify>
    <automated>mix compile --warnings-as-errors && mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors && mix test --warnings-as-errors && rg -nF 'CFG-04' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '## Requirement Traceability' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '## Phase-Audit Gap Closed' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '## Automated Evidence Packet' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF 'mix compile --warnings-as-errors' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF 'mix test test/relyra/ecto/certificate_inventory_expiry_test.exs ... --warnings-as-errors' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nE '[0-9]+ tests, 0 failures' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '| Expiry tracking |' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '| Staged promotion and rollback |' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '| Concurrency conflict handling |' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF '| Active-only runtime trust hydration |' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md</automated>
  </verify>
  <done>`10-VERIFICATION.md` exists, names CFG-04 explicitly, records the exact serial packet with results and counts, and maps each required rollover behavior to concrete evidence.</done>
</task>
```

**Apply to `14-01-PLAN.md` Task 1:**
- `<name>`: `Task 1: Produce the compact serial CFG-05 verification artifact`
- `<files>`: `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md`
- `<action>`: Same shape — locked 3-command D-06 packet, serial only, write artifact in compact Phase 10 structure (scope, requirement traceability, audit gap closed, automated evidence packet, evidence map, manual sign-off). Traceability map must cover the 4 D-07 behaviors (mapping persistence, cross-domain audit hardening, audited mutation surface, runtime mapping_config hydration). Keep recommendation-first and concise per D-04, D-08, D-12. Do not reopen mapping/audit semantics or broaden milestone cleanup (D-03, D-12).
- `<verify><automated>`: same `rg -nF` chain rebound to:
  - `'CFG-05'`
  - `'## Requirement Traceability'`, `'## Phase-Audit Gap Closed'`, `'## Automated Evidence Packet'`, `'## Evidence Map'`, `'## Manual Sign-Off'`
  - `'mix compile --warnings-as-errors'`
  - the full 13-file `mix test ...` literal command (the canonical D-06 step 2 command)
  - `'mix test --warnings-as-errors'`
  - count regex `[0-9]+ tests, 0 failures`
  - 4 row-label literals from D-07: `'| Mapping persistence (live rows + revision ledger) |'`, `'| Cross-domain audit hardening (same-transaction capture) |'`, `'| Audited mapping mutation surface |'`, `'| Runtime mapping_config hydration |'`
- `<done>`: `\`11-VERIFICATION.md\` exists, names CFG-05 explicitly, records the exact serial packet with results and counts, and maps each required mapping/audit behavior to concrete evidence.`

---

**Task 2 (checkpoint:human-verify) pattern** (lines 75-88):

```md
<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Obtain blocking sign-off for the two manual CFG-04 semantics checks</name>
  <action>Present the two narrow manual checks from D-10 as the only human approval gate for this phase: (1) confirm the rollover API and typed conflict errors make the caller action obvious; (2) confirm runtime trust still consumes only active certs while staged and retired rows remain inventory facts only. Ask the user to review `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connection_snapshot.ex`, the updated focused proof tests, and the draft `10-VERIFICATION.md`. If the user approves, write concise prose sign-off into `10-VERIFICATION.md`; if the user reports an issue, record the blocking issue and stop closure rather than softening the semantics or claiming completion. Do not use the manual gate to re-prove functional correctness that the automated packet already covers, per D-11.</action>
  <verify>
    <automated>rg -nF '## Manual Sign-Off' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF 'Manual approval status: approved.' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF 'Confirm the rollover API and typed conflict errors make the caller action obvious.' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md && rg -nF 'Confirm runtime trust still consumes only active certs while staged and retired rows remain inventory facts only.' .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md</automated>
  </verify>
  <how-to-verify>
    1. Review the transition and conflict behavior in `lib/relyra/ecto/certificate_inventory.ex` and the focused rollover tests; confirm the caller action implied by typed conflict and invalid-transition failures is obvious.
    2. Review `lib/relyra/ecto/connection_snapshot.ex`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/connection_snapshot_test.exs`; confirm active certs alone define runtime trust while staged and retired rows remain inventory-only.
    3. Confirm the approval prose is written into `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md`.
  </how-to-verify>
  <resume-signal>Type `approved` to continue, or describe the blocking issue in one message.</resume-signal>
  <done>CFG-04 verification includes explicit human-approved prose for the two locked semantics checks, or the phase remains blocked with the issue recorded.</done>
</task>
```

**Apply to `14-01-PLAN.md` Task 2:**
- `<name>`: `Task 2: Obtain blocking sign-off for the two manual CFG-05 semantics checks`
- `<action>`: Same shape — present the two D-10 checks per RESEARCH.md exact wording:
  1. `Confirm cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material.`
  2. `Confirm the runtime mapping_config contract stays persistence-agnostic — plain attribute_rules / group_rules, deterministic ordering, persisted-rules-first with fallback — so host-app Relyra.UserMapper consumers see stable values.`
  Ask user to review `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/audit_event.ex`, `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper/default_attribute.ex`, the proof tests, and the draft `11-VERIFICATION.md`. On approval, write prose; on rejection, record blocking issue and stop. Per D-11, do not use the gate to re-prove functional correctness.
- `<verify><automated>`: 4 `rg -nF` checks:
  - `'## Manual Sign-Off'`
  - `'Manual approval status: approved.'`
  - The two literal D-10 prompt sentences verbatim (these are now the grep-verifier targets — wording must match exactly across plan, artifact, and verifier)
- `<how-to-verify>`: 3 numbered review steps rebound to mapping/audit (audit_writer + audit_event + cross-domain audit tests for prompt 1; connection_snapshot + default_attribute + their tests for prompt 2; confirm approval prose lands in `11-VERIFICATION.md`).
- `<resume-signal>`: `Type \`approved\` to continue, or describe the blocking issue in one message.` (verbatim).
- `<done>`: `CFG-05 verification includes explicit human-approved prose for the two locked semantics checks, or the phase remains blocked with the issue recorded.`

---

**`<threat_model>`, `<verification>`, `<success_criteria>`, `<output>` pattern** (lines 92-119):

```md
<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| automated Mix results -> milestone verification artifact | Serial test evidence must be captured without omission or distortion |
| human semantics review -> requirement closure | Manual sign-off decides whether the remaining product-semantics judgments are acceptable |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-02-01 | R | `10-VERIFICATION.md` evidence chain | mitigate | Record exact serial commands, execution order, timestamps, and result counts so CFG-04 proof is reproducible and auditable per D-08 and D-09. |
| T-13-02-02 | D | migration-backed test evidence | mitigate | Forbid parallel Mix execution and state in the artifact that parallel proof is invalid per D-04 and the milestone-audit serial-only warning. |
| T-13-02-03 | T | manual approval gate | mitigate | Make the human sign-off a blocking checkpoint and write the approved or blocking outcome directly into `10-VERIFICATION.md`. |
</threat_model>

<verification>
Run the locked serial packet in order, capture the artifact, then block until the user approves or rejects the two manual semantics checks.
</verification>

<success_criteria>
Phase 10 has an authoritative compact verification artifact for CFG-04, automated serial proof is recorded with counts, and the manual semantics gate is explicitly approved before traceability is updated.
</success_criteria>

<output>
After completion, create `.planning/phases/13-certificate-rollover-validation-verification/13-02-SUMMARY.md`
</output>
```

**Apply to `14-01-PLAN.md`:** Threat IDs become `T-14-01-01`, `T-14-01-02`, `T-14-01-03`. Components and mitigations rebound to mapping/audit (`11-VERIFICATION.md` evidence chain; migration-backed mapping/audit test evidence; manual approval gate). `<verification>` and `<success_criteria>` rebound CFG-04 -> CFG-05 and Phase 10 -> Phase 11. `<output>` references `14-01-SUMMARY.md`.

---

### `14-02-PLAN.md` (config, batch)

**Analog:** `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md`

**Plan envelope frontmatter pattern** (lines 1-38):

```md
---
phase: 13-certificate-rollover-validation-verification
plan: 13-03
type: execute
wave: 3
depends_on: ["13-02"]
files_modified:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
autonomous: true
requirements: [CFG-04]
must_haves:
  truths:
    - "CFG-04 is no longer orphaned in live milestone truth once Phase 10 verification exists."
    - "Roadmap, requirements, and state all agree that certificate rollover closure is verified without mutating historical audit artifacts."
    - "Phase 13 closes only CFG-04 traceability and does not expand into broader milestone cleanup."
  artifacts:
    - path: ".planning/REQUIREMENTS.md"
      provides: "CFG-04 marked complete in milestone requirement truth"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 13 plan closure and verified status for CFG-04 milestone traceability"
    - path: ".planning/STATE.md"
      provides: "Current milestone state advanced past pending Phase 12 verification focus"
  key_links:
    - from: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      to: ".planning/REQUIREMENTS.md"
      via: "verification artifact closes CFG-04 orphan status per D-05 and D-06"
      pattern: "CFG-04|approved"
    - from: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      to: ".planning/ROADMAP.md"
      via: "Phase 13 success criteria become achieved after verification closure"
      pattern: "verified|complete"
    - from: ".planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md"
      to: ".planning/STATE.md"
      via: "state moves from Phase 12 verify focus to current CFG-04 closure truth"
      pattern: "Phase 13|verified"
---
```

**Apply to `14-02-PLAN.md`:**
- `phase: 14-mapping-audit-milestone-verification`
- `plan: 14-02`
- `wave: 2` (per RESEARCH.md Wave Structure)
- `depends_on: ["14-01"]` (HARD per RESEARCH.md Execution Ordering — truth dependency: live-truth flip is invalid until artifact exists)
- `files_modified:` exactly the same 3 files: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` (Landmine 2: only these three files; D-03)
- `autonomous: true` (pure file edits, deterministic, fully `rg -nF` verifiable; mirrors 13-03)
- `requirements: [CFG-05]`
- `must_haves.truths`: rebind 3 bullets — CFG-05 no longer orphaned once `11-VERIFICATION.md` exists; roadmap+requirements+state agree mapping/audit closure is verified without mutating historical artifacts; Phase 14 closes only CFG-05 and does not expand into broader cleanup
- `must_haves.artifacts`: 3 entries for REQUIREMENTS.md, ROADMAP.md, STATE.md, rebind from CFG-04+Phase 13 to CFG-05+Phase 14
- `key_links`: 3 from `11-VERIFICATION.md` to each live-truth file, patterns `CFG-05|approved`, `verified|complete`, `Phase 14|verified`

---

**Task 1 (auto) pattern** (lines 65-73):

```md
<task type="auto">
  <name>Task 1: Refresh live milestone truth to reflect verified CFG-04 closure</name>
  <files>.planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md</files>
  <action>After `10-VERIFICATION.md` exists with approved manual sign-off, update only the live truth files named in D-06. Follow the live-truth minimalism analogs captured in `13-PATTERNS.md`: make narrow in-place edits to `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, and leave historical audit artifacts untouched. In `REQUIREMENTS.md`, mark `CFG-04` complete and update traceability status so Phase 13 is no longer pending. In `ROADMAP.md`, add the Phase 13 plan count/list if needed, mark the phase status/closure against CFG-04, and rewrite the Phase 13 section so it contains the exact closure line `- Status: complete (verified after Phase 13 execution).` instead of future-work phrasing. In `STATE.md`, move the current focus away from Phase 12 ready-for-verify state to the new post-Phase-13 reality, using the exact focus/status strings `**Current focus:** Phase 13 — certificate-rollover-validation-verification (complete)` and `Phase: 13 (certificate-rollover-validation-verification) — COMPLETE`. Do not touch `.planning/v0.2-MILESTONE-AUDIT.md` or any other historical artifact per D-07, and do not broaden this into cleanup for CFG-05 or unrelated milestone files.</action>
  <verify>
    <automated>rg -nF -- '- [x] **CFG-04**: User can manage certificate inventory for a connection with expiry tracking and staged rollover.' .planning/REQUIREMENTS.md && rg -nF -- '| CFG-04 | Phase 13 | Complete |' .planning/REQUIREMENTS.md && rg -nF -- '**Phase 13: Certificate rollover validation + verification**' .planning/ROADMAP.md && rg -nF -- '- Status: complete (verified after Phase 13 execution).' .planning/ROADMAP.md && rg -nF -- '- [x] `13-01-PLAN.md` — sync `10-VALIDATION.md` to the current serial rollover proof surface and completed Wave 0 truth.' .planning/ROADMAP.md && rg -nF -- '- [x] `13-02-PLAN.md` — create `10-VERIFICATION.md` from the locked serial packet and blocking manual sign-off gate.' .planning/ROADMAP.md && rg -nF -- '- [x] `13-03-PLAN.md` — update live milestone truth in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` after CFG-04 verification closure.' .planning/ROADMAP.md && rg -nF -- 'status: complete' .planning/STATE.md && rg -nF -- '**Current focus:** Phase 13 — certificate-rollover-validation-verification (complete)' .planning/STATE.md && rg -nF -- 'Phase: 13 (certificate-rollover-validation-verification) — COMPLETE' .planning/STATE.md</automated>
  </verify>
  <done>`REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` all reflect CFG-04 as verified/complete, and no historical audit artifacts were edited.</done>
</task>
```

**Apply to `14-02-PLAN.md` Task 1:**
- `<name>`: `Task 1: Refresh live milestone truth to reflect verified CFG-05 closure`
- `<files>`: `.planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md`
- `<action>`: Same shape — after `11-VERIFICATION.md` exists with approved sign-off, update only the live-truth files. Edits per RESEARCH.md "Live-Truth Refresh Map":
  - `REQUIREMENTS.md`: flip `CFG-05` to `[x]`; flip traceability row `| CFG-05 | Phase 14 | Pending |` -> `| CFG-05 | Phase 14 | Complete |`; bump footer stamp to `*Last updated: 2026-05-06 after Phase 14 execution*`
  - `ROADMAP.md`: rewrite Phase 14 detail block to add `- Status: complete (verified after Phase 14 execution).`, `- Plans: 2 plans.`, `- Plan list:` with two `[x]` entries (`14-01-PLAN.md — create \`11-VERIFICATION.md\` from the locked serial packet and blocking manual sign-off gate.` and `14-02-PLAN.md — update live milestone truth in \`REQUIREMENTS.md\`, \`ROADMAP.md\`, and \`STATE.md\` after CFG-05 verification closure.`)
  - `STATE.md`: bump frontmatter `last_updated` (new ISO-8601 UTC), `last_activity` (2026-05-06 -- Phase 14 execution completed; CFG-05 verified and closed), `progress.completed_phases: 6 -> 7`, `progress.total_plans: 23 -> 25`, `progress.completed_plans: 23 -> 25`; flip Current focus + Current Position lines to literals `**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)` and `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE`; bump `Plan: 0 of 0 (planning pending) -> Plan: 2 of 2`; repoint `Resume file:` to `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` (Landmine 6)
  - Do NOT touch `.planning/v0.2-MILESTONE-AUDIT.md` (D-03, Landmine 2) or any other historical artifact. Do not broaden into cleanup for CFG-06 or `PROJECT.md` drift (RESEARCH.md side-note + Deferred Ideas).
- `<verify><automated>`: same `rg -nF` chain rebound to:
  - `'- [x] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.'`
  - `'| CFG-05 | Phase 14 | Complete |'`
  - `'**Phase 14: Mapping/audit milestone verification**'`
  - `'- Status: complete (verified after Phase 14 execution).'`
  - `'- [x] \`14-01-PLAN.md\` — create \`11-VERIFICATION.md\` from the locked serial packet and blocking manual sign-off gate.'`
  - `'- [x] \`14-02-PLAN.md\` — update live milestone truth in \`REQUIREMENTS.md\`, \`ROADMAP.md\`, and \`STATE.md\` after CFG-05 verification closure.'`
  - `'status: complete'` (frontmatter; already true, leaves as-is)
  - `'**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)'`
  - `'Phase: 14 (mapping-audit-milestone-verification) — COMPLETE'`
- `<done>`: `\`REQUIREMENTS.md\`, \`ROADMAP.md\`, and \`STATE.md\` all reflect CFG-05 as verified/complete, and no historical audit artifacts were edited.`

---

**`<threat_model>`, `<verification>`, `<success_criteria>`, `<output>` pattern** (lines 77-104):

```md
<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| verification artifact -> live milestone truth | Current planning truth must derive from approved CFG-04 evidence |
| live milestone truth -> future audits | Updated roadmap/requirements/state will be consumed as the canonical current state |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-03-01 | T | live truth files | mitigate | Update `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` only after `10-VERIFICATION.md` exists with approved manual sign-off, and keep all changes traceable to D-06. |
| T-13-03-02 | R | milestone closure state | mitigate | Use `rg` verification to confirm all three live-truth files now agree on CFG-04 and Phase 13 status before marking the plan complete. |
| T-13-03-03 | T | historical audit evidence | mitigate | Leave `.planning/v0.2-MILESTONE-AUDIT.md` untouched per D-07 and treat re-audit as a later workflow step rather than rewriting history. |
</threat_model>

<verification>
Confirm the approved Phase 10 verification artifact exists, then update and grep-check the three live-truth files so CFG-04 is visibly closed everywhere current state is carried.
</verification>

<success_criteria>
Current milestone truth surfaces agree that CFG-04 is verified and complete, Phase 13 is closed, and historical audit artifacts remain intact.
</success_criteria>

<output>
After completion, create `.planning/phases/13-certificate-rollover-validation-verification/13-03-SUMMARY.md`
</output>
```

**Apply to `14-02-PLAN.md`:** Threat IDs `T-14-02-01..03`. Mitigations rebound from `10-VERIFICATION.md` -> `11-VERIFICATION.md`, CFG-04 -> CFG-05, Phase 13 -> Phase 14, D-06/D-07 -> D-01/D-03. `<output>` references `14-02-SUMMARY.md`.

---

### `14-01-SUMMARY.md` and `14-02-SUMMARY.md` (doc, transform)

**Analogs:** `13-02-SUMMARY.md` and `13-03-SUMMARY.md` respectively.

**Summary frontmatter + body pattern (`13-02-SUMMARY.md` lines 1-36):**

```md
---
phase: 13-certificate-rollover-validation-verification
plan: 13-02
status: completed
requirement: CFG-04
commits: []
---

# Phase 13 Plan 13-02 Summary

Outcome: `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` now records the authoritative `CFG-04` serial verification packet, the exact command/results chain, and the completed manual approval gate for the two locked rollover semantics checks.

Files changed:
- `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md`

Verification commands:

\`\`\`sh
mix compile --warnings-as-errors
mix test test/relyra/ecto/certificate_inventory_expiry_test.exs ... --warnings-as-errors
mix test --warnings-as-errors
\`\`\`

Verification results:
- `mix compile --warnings-as-errors` passed on `2026-05-06T07:04:03Z`.
- Focused serial rollover packet passed on `2026-05-06T07:04:04Z` with `23 tests, 0 failures`.
- Full serial suite passed on `2026-05-06T07:04:05Z` with `168 tests, 0 failures`.
- Human sign-off approved on `2026-05-06` for caller-guidance semantics and active-only runtime trust semantics.

Notes:
- The verification artifact keeps the serial-only posture explicit because parallel Mix evidence remains invalid for this phase.
- The human gate stayed constrained to the two semantics checks locked in Phase 13 and did not broaden into re-testing functional correctness by hand.

Deviations:
- None.
```

**Apply to `14-01-SUMMARY.md`:** Same shape. `phase: 14-mapping-audit-milestone-verification`, `plan: 14-01`, `requirement: CFG-05`. Outcome rebound to `11-VERIFICATION.md` and CFG-05 mapping/audit semantics. Verification commands: the 3 D-06 commands (full 13-test list). Verification results: real timestamps and counts captured at execution. Notes: serial-only posture for mapping/audit; manual gate constrained to the two D-10 semantics judgments.

**Apply to `14-02-SUMMARY.md`:** Mirror `13-03-SUMMARY.md` shape — `requirement: CFG-05`, files changed = REQUIREMENTS.md/ROADMAP.md/STATE.md, verification commands = the `rg -nF` chain rebound to CFG-05/Phase 14, results = three files now agree on CFG-05 closure with historical artifacts untouched.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md` (in-place edit; current state lines 12-16, 48-54, 61-63 are the anchors).

**Requirement checkbox pattern** (lines 12-16, current state):

```md
- [x] **CFG-01**: ...
- [x] **CFG-02**: ...
- [x] **CFG-03**: ...
- [x] **CFG-04**: ...
- [ ] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.
```

**Traceability table pattern** (lines 48-54, current state):

```md
| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-01 | Phase 07 | Complete |
| CFG-02 | Phase 08 | Complete |
| CFG-03 | Phase 12 | Complete |
| CFG-04 | Phase 13 | Complete |
| CFG-05 | Phase 14 | Pending |
```

**Footer stamp pattern** (lines 61-63, current state):

```md
---
*Requirements defined: 2026-04-26*
*Last updated: 2026-05-06 after Phase 13 execution*
```

**Apply in-place (3 narrow edits):**

| Anchor | Before | After |
|--------|--------|-------|
| Line 16 | `- [ ] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` | `- [x] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.` |
| Line 54 | `\| CFG-05 \| Phase 14 \| Pending \|` | `\| CFG-05 \| Phase 14 \| Complete \|` |
| Line 63 | `*Last updated: 2026-05-06 after Phase 13 execution*` | `*Last updated: 2026-05-06 after Phase 14 execution*` |

**Do NOT touch:** Coverage block lines 56-59 (already correct); CFG-01..CFG-04 rows; v1 Requirements; Out of Scope.

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md` Phase 13 detail block lines 88-100 (the byte-aligned post-closure shape Phase 14 must converge to).

**Phase 13 detail block — post-closure shape** (lines 88-100):

```md
**Phase 13: Certificate rollover validation + verification**
- Goal: sync Phase 10 validation truth and produce verification evidence that closes `CFG-04`.
- Status: complete (verified after Phase 13 execution).
- Plans: 3 plans.
- Plan list:
- [x] `13-01-PLAN.md` — sync `10-VALIDATION.md` to the current serial rollover proof surface and completed Wave 0 truth.
- [x] `13-02-PLAN.md` — create `10-VERIFICATION.md` from the locked serial packet and blocking manual sign-off gate.
- [x] `13-03-PLAN.md` — update live milestone truth in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` after CFG-04 verification closure.
- Gap closure: closes the audit orphan state for certificate lifecycle coverage and resolves the partial Nyquist status in `10-VALIDATION.md`.
- Success criteria:
  1. `10-VALIDATION.md` reflects the current Wave 0 proof surface and serial-only verification posture.
  2. Phase 10 verification evidence exists for staged promotion, rollback, and expiry tracking behavior.
  3. `CFG-04` can be marked satisfied in milestone traceability after verification.
```

**Phase 14 detail block — current state** (lines 102-108):

```md
**Phase 14: Mapping/audit milestone verification**
- Goal: close the remaining verification gap for Phase 11 without reopening already-green implementation work.
- Gap closure: resolves the audit orphan state for `CFG-05` by producing the missing phase verification artifact.
- Success criteria:
  1. Phase 11 verification evidence exists for mapping persistence and audit hardening behavior.
  2. Milestone traceability can mark `CFG-05` complete from verification evidence rather than plan completion alone.
  3. v0.2 re-audit sees no remaining mapping/audit verification gap.
```

**Apply in-place (insert 4 lines into Phase 14 block, after Goal and before Gap closure):**

The Phase 14 block must become (per RESEARCH.md Live-Truth Refresh Map File 2):

```md
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

**Status line is byte-aligned** with `13-03-PLAN.md` Task 1's grep verifier pattern (`- Status: complete (verified after Phase 13 execution).` -> `- Status: complete (verified after Phase 14 execution).`). `14-02-PLAN.md` MUST use this exact language so the `rg -nF` verifier proves the edit landed.

**Do NOT touch:** Phase 07-13 detail blocks; v0.2 Phases summary table; v0.1 archive line; any other section.

---

### `.planning/STATE.md` (config, transform)

**Analog:** `.planning/STATE.md` current state (frontmatter lines 1-14 + Current Position block lines 22-31).

**Frontmatter pattern** (lines 1-14, current state):

```yaml
---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Phases
status: complete
last_updated: "2026-05-06T15:00:00Z"
last_activity: 2026-05-06 -- Phase 14 context gathered (assumptions mode); ready for plan-phase
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 23
  completed_plans: 23
  percent: 100
---
```

**Current focus + Current Position pattern** (lines 22-31, current state):

```md
**Core value:** Every SAML login ends in a verified trust path or a typed rejection, never a silent compromise.  
**Current focus:** Phase 14 — mapping-audit-milestone-verification (context gathered, ready for plan-phase)

## Current Position

Phase: 14 (mapping-audit-milestone-verification) — CONTEXT GATHERED
Plan: 0 of 0 (planning pending)
Status: 14-CONTEXT.md written (assumptions mode); ready for /gsd-plan-phase 14
Last activity: 2026-05-06 -- Phase 14 context locked: two plans (11-VERIFICATION.md + live-truth refresh), three-command serial packet, four-row CFG-05 traceability map, two manual sign-off checks
Resume file: .planning/phases/14-mapping-audit-milestone-verification/14-CONTEXT.md
```

**Apply in-place (per RESEARCH.md Live-Truth Refresh Map File 3):**

| Anchor | Before | After |
|--------|--------|-------|
| `status:` (line 5) | `status: complete` | `status: complete` (no change — already complete per Phase 13 closure) |
| `last_updated:` (line 6) | `"2026-05-06T15:00:00Z"` | new ISO-8601 UTC at moment of `14-02` execution |
| `last_activity:` (line 7) | `2026-05-06 -- Phase 14 context gathered (assumptions mode); ready for plan-phase` | `2026-05-06 -- Phase 14 execution completed; CFG-05 verified and closed` (agent discretion under D-08) |
| `progress.total_phases` (line 9) | `total_phases: 7` | `total_phases: 7` (no change) |
| `progress.completed_phases` (line 10) | `completed_phases: 6` | `completed_phases: 7` |
| `progress.total_plans` (line 11) | `total_plans: 23` | `total_plans: 25` (Phase 14 adds 14-01 + 14-02) |
| `progress.completed_plans` (line 12) | `completed_plans: 23` | `completed_plans: 25` |
| Current focus (line 23) | `**Current focus:** Phase 14 — mapping-audit-milestone-verification (context gathered, ready for plan-phase)` | `**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)` |
| Phase line (line 27) | `Phase: 14 (mapping-audit-milestone-verification) — CONTEXT GATHERED` | `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE` |
| Plan line (line 28) | `Plan: 0 of 0 (planning pending)` | `Plan: 2 of 2` |
| Status line (line 29) | `Status: 14-CONTEXT.md written (assumptions mode); ready for /gsd-plan-phase 14` | `Status: Execution complete; CFG-05 closed` (agent discretion within locked focus/phase strings above) |
| Last activity (line 30) | match frontmatter | match new frontmatter `last_activity` |
| Resume file (line 31) | `.planning/phases/14-mapping-audit-milestone-verification/14-CONTEXT.md` | `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` (Landmine 6) |

**Two grep-verifiable closure strings (literal targets for `14-02-PLAN.md` `rg -nF` chain):**

- `**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)`
- `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE`

**Do NOT touch:** Performance Metrics table; Project Reference link; Progress bar art (already 100%); Core value line.

---

## Shared Patterns

### Compact Verification Artifact (6-section locked shape)

**Source:** `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` (per CONTEXT.md D-08, RESEARCH.md `## 11-VERIFICATION.md Artifact Spec`).

**Apply to:** `.planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md`

```md
# Phase NN Verification

## Scope
## Requirement Traceability
## Phase-Audit Gap Closed
## Automated Evidence Packet
## Evidence Map
## Manual Sign-Off
```

Section order is **fixed** per RESEARCH.md spec. Inside `## Manual Sign-Off`, the literal terminator line `Manual approval status: approved.` is the canonical closure marker.

---

### Serial-Only Evidence Recording

**Sources:** `10-VERIFICATION.md` lines 28-38, `13-02-PLAN.md` Task 1 verifier (line 70), `13-PATTERNS.md` "Serial-Only Evidence Recording", CONTEXT.md D-05, RESEARCH.md Landmine 1.

**Apply to:** `11-VERIFICATION.md`, `14-01-PLAN.md` Task 1.

```md
Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the mapping/audit validation contract and the milestone-audit warning that parallel Mix evidence is invalid for this phase.

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `<UTC ISO-8601>` | `mix compile --warnings-as-errors` | passed | `compile succeeded with no warnings` |
| 2 | `<UTC ISO-8601>` | `mix test <13 D-06 test files> --warnings-as-errors` | passed | `nn tests, 0 failures` |
| 3 | `<UTC ISO-8601>` | `mix test --warnings-as-errors` | passed | `nn tests, 0 failures` |

Serial execution note: order `1` completed successfully before order `2` started, and order `2` completed successfully before order `3` started. No parallel Mix commands were used for this verification packet.
```

**Critical:** Do NOT pre-fill counts (Landmine 5) — capture at execution time.

---

### Closure-Plan Envelope (frontmatter shape)

**Source:** `13-02-PLAN.md` lines 1-28 (and `13-03-PLAN.md` lines 1-38 for autonomous live-truth variant).

**Apply to:** `14-01-PLAN.md`, `14-02-PLAN.md`.

```md
---
phase: <phase-slug>
plan: <NN-NN>
type: execute
wave: <N>
depends_on: [<upstream plan ids or empty>]
files_modified:
  - <path>
autonomous: <bool — false if has human-verify gate, true if pure file edits>
requirements: [<CFG-NN>]
must_haves:
  truths:
    - "<truth claim 1>"
    - "<truth claim 2>"
    - "<truth claim 3>"
  artifacts:
    - path: "<artifact path>"
      provides: "<what this artifact carries>"
  key_links:
    - from: "<source>"
      to: "<target>"
      via: "<closure justification>"
      pattern: "<grep-friendly OR pattern>"
---
```

---

### Two-Task Closure Plan (Task 1 auto + Task 2 blocking human-verify)

**Source:** `13-02-PLAN.md` lines 65-88. Pattern is exactly: serial-evidence Task 1 (`type="auto"`) followed by manual-gate Task 2 (`type="checkpoint:human-verify" gate="blocking"`).

**Apply to:** `14-01-PLAN.md` ONLY (because it produces `11-VERIFICATION.md` + manual gate). `14-02-PLAN.md` has only one auto task (live-truth file edits, no manual gate).

```md
<task type="auto">
  <name>Task 1: Produce the compact serial CFG-NN verification artifact</name>
  <files><artifact path></files>
  <action><run packet, write artifact></action>
  <verify>
    <automated><mix commands && rg -nF chain on artifact></automated>
  </verify>
  <done><observable artifact state></done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Obtain blocking sign-off for the two manual CFG-NN semantics checks</name>
  <action><present 2 D-10 prompts; on approve write prose, on reject record blocking issue></action>
  <verify>
    <automated>rg -nF '## Manual Sign-Off' && rg -nF 'Manual approval status: approved.' && rg -nF '<prompt 1 verbatim>' && rg -nF '<prompt 2 verbatim>'</automated>
  </verify>
  <how-to-verify>
    1. <review file paths and what to confirm for prompt 1>
    2. <review file paths and what to confirm for prompt 2>
    3. Confirm the approval prose is written into <artifact path>.
  </how-to-verify>
  <resume-signal>Type `approved` to continue, or describe the blocking issue in one message.</resume-signal>
  <done><artifact contains approved prose OR phase remains blocked with issue recorded></done>
</task>
```

---

### Live-Truth Minimalism

**Sources:** `13-PATTERNS.md` "Live-Truth Minimalism" (line 448), `13-03-PLAN.md` (lines 1-104), CONTEXT.md D-03, RESEARCH.md Landmine 2.

**Apply to:** `14-02-PLAN.md` and the three live-truth files it edits.

Three rules:

1. **Only three files:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`. The plan's `files_modified:` MUST list exactly these three (D-03; Landmine 2 is BLOCKING).
2. **Narrow in-place edits:** Each file is touched only at the specific anchors RESEARCH.md "Live-Truth Refresh Map" names. No reordering, no broad rewrites, no expansion into adjacent CFG-* rows or unrelated sections.
3. **No historical mutation:** `.planning/v0.2-MILESTONE-AUDIT.md`, all prior `*-SUMMARY.md` / `*-VERIFICATION.md` / `*-VALIDATION.md` / `*-CONTEXT.md` files outside Phase 14, and `.planning/PROJECT.md` are read-only. Re-audit is `/gsd-audit-milestone` territory.

---

### `rg -nF` Grep-Verifier Discipline

**Source:** `13-02-PLAN.md` line 70 + `13-03-PLAN.md` line 70.

**Apply to:** Both `14-01-PLAN.md` and `14-02-PLAN.md` `<verify><automated>` blocks.

Three rules:

1. **Use `rg -nF` for literal strings, `rg -nE` for regexes** (e.g., `rg -nE '[0-9]+ tests, 0 failures'`).
2. **The grep target must match the artifact byte-for-byte.** If the planner picks specific D-10 prompt wording for `11-VERIFICATION.md`, that exact wording must appear in the `rg -nF` command in `14-01-PLAN.md` Task 2. No paraphrase between artifact and verifier.
3. **Chain with `&&`** so the whole verify block fails closed if any literal is missing.

---

### Summary File Shape (post-execution artifact)

**Sources:** `13-02-SUMMARY.md`, `13-03-SUMMARY.md`.

**Apply to:** `14-01-SUMMARY.md`, `14-02-SUMMARY.md`.

```md
---
phase: <phase-slug>
plan: <NN-NN>
status: completed
requirement: <CFG-NN>
commits: []
---

# Phase NN Plan NN-NN Summary

Outcome: <what now exists / what changed in one sentence>.

Files changed:
- <path>

Verification commands:

\`\`\`sh
<commands>
\`\`\`

Verification results:
- <real timestamps + counts>

Notes:
- <serial-only / scope-discipline reminders>

Deviations:
- None.
```

---

## No Analog Found

None. Every Phase 14 target has a strong repo-local analog. The byte-for-byte structural templates are:

| Phase 14 file | Byte-for-byte template |
|---------------|-----------------------|
| `11-VERIFICATION.md` | `10-VERIFICATION.md` |
| `14-01-PLAN.md` | `13-02-PLAN.md` |
| `14-02-PLAN.md` | `13-03-PLAN.md` |
| `14-01-SUMMARY.md` | `13-02-SUMMARY.md` |
| `14-02-SUMMARY.md` | `13-03-SUMMARY.md` |
| Live-truth edits | `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` / `.planning/STATE.md` current state, with Phase 13 detail block as the post-closure shape model for the Phase 14 detail block |

---

## Metadata

**Analog search scope:** `.planning/phases/10-*`, `.planning/phases/13-*`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`. Search was scoped tightly because RESEARCH.md and CONTEXT.md both name the exact analogs and direct line anchors.

**Files scanned:** 7 analog files + 3 live-truth current-state files + 3 phase-14 input files (CONTEXT, RESEARCH, dir listing) = 13 files total. Stopped early per "no benefit beyond strong matches" rule — every required Phase 14 output has a verbatim repo-local template.

**Pattern extraction date:** 2026-05-06
