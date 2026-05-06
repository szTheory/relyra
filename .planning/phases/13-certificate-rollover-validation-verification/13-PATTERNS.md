# Phase 13: Certificate rollover validation + verification - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md` | test | transform | `.planning/phases/13-certificate-rollover-validation-verification/13-VALIDATION.md` | exact |
| `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` | test | batch | `.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |
| `.planning/phases/13-certificate-rollover-validation-verification/13-01-PLAN.md` | config | batch | `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md` | role-match |
| `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md` | config | batch | `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md` | exact |
| `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md` | config | batch | `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md` | role-match |

## Pattern Assignments

### `.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md` (test, transform)

**Analog:** `.planning/phases/13-certificate-rollover-validation-verification/13-VALIDATION.md`

**Frontmatter + validation posture** (lines 1-8):
```md
---
phase: 13
slug: certificate-rollover-validation-verification
status: ready_for_verify
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---
```

**Test infrastructure + compact command style** (lines 16-24):
```md
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs`, `test/test_helper.exs`, and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
```

**Per-task verification matrix** (lines 37-45):
```md
## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-T01 | 13-01 | 1 | CFG-04 | TM-13-01-TRACEABILITY-DRIFT | ... | documentation + verification | `mix test ... --warnings-as-errors` | ✅ | ⬜ pending |
| 13-02-T01 | 13-02 | 2 | CFG-04 | TM-13-02-EVIDENCE-GAP | ... | integration | `mix compile --warnings-as-errors && mix test ... && mix test --warnings-as-errors` | ✅ | ⬜ pending |
| 13-03-T01 | 13-03 | 3 | CFG-04 | TM-13-03-ORPHANED-TRUTH | ... | documentation + traceability | `rg -n "CFG-04|Phase 13|ready_for_verify|verified|complete" ...` | ✅ | ⬜ pending |
```

**Wave 0 completion language** (lines 49-56):
```md
## Wave 0 Requirements

- [x] `test/relyra/ecto/certificate_inventory_expiry_test.exs` ...
- [x] `test/relyra/ecto/certificate_inventory_transition_test.exs` ...
- [x] `test/relyra/ecto/certificate_inventory_concurrency_test.exs` ...
- [x] `test/relyra/ecto/ecto_connection_resolver_test.exs` and `test/relyra/connection_snapshot_test.exs` ...

Wave 0 is already complete in the current repo state. Phase 13 consumes that proof surface and closes the stale verification metadata around it.
```

**Manual-only checks shape** (lines 60-65):
```md
## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The rollover API and typed conflict errors read as clear caller guidance ... | CFG-04 | Automated tests prove correctness, but a human still needs to judge ... | Review `lib/relyra/ecto/certificate_inventory.ex` ... |
| Runtime trust still consumes only active signing certs while staged and retired rows remain durable inventory facts only | CFG-04 | The tests prove filtering, but the product semantics still need explicit human confirmation | Review `lib/relyra/ecto/connection_snapshot.ex` ... |
```

**Apply to Phase 10 update:** Replace stale `wave_0_complete: false`, unchecked Wave 0 items, and `❌ W0` markers in [10-VALIDATION.md](/Users/jon/projects/relyra/.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md:1) using the checked/completed language from [13-VALIDATION.md](/Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-VALIDATION.md:1).

---

### `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` (test, batch)

**Analog:** `.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md`

**Compact artifact opening** (lines 1-10):
```md
# Phase 09 Verification

## Scope

This artifact closes `CFG-03` milestone verification ... by recording the repaired automated evidence packet ... and the completed manual approval gate.

## Requirement Traceability

Requirement: `CFG-03` - User can import and export metadata ...
```

**Requirement-to-evidence table** (lines 11-16):
```md
| CFG-03 behavior | Proof source | Evidence |
| --- | --- | --- |
| Metadata import | `mix test ... --warnings-as-errors` | Focused serial smoke run passed with `15 tests, 0 failures`. ... |
| Metadata export | `test/phoenix/metadata_controller_test.exs`; `.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md` | Controller coverage confirms ... |
| Controlled refresh | `mix test ...`; `mix test --warnings-as-errors`; ... | Focused serial smoke run passed ... full serial suite passed ... |
| Provenance | `test/relyra/metadata_test.exs`; `test/relyra/ecto/metadata_revision_schema_test.exs`; ... | Schema tests enforce ... |
```

**Audit-gap closure section** (lines 18-26):
```md
## Phase-Audit Gap Closed

Milestone audit gap being closed: `.planning/v0.2-MILESTONE-AUDIT.md` marked `CFG-03` as unsatisfied/orphaned because Phase 09 had no `09-VERIFICATION.md` ...

Closure evidence:
- This file now exists as the missing Phase 09 verification artifact.
- The repaired focused Phase 09 smoke packet now passes serially.
- The repaired full test suite now passes serially.
- The required human sign-off on the two manual checks has been recorded below.
```

**Serial command packet table** (lines 28-37):
```md
## Automated Evidence Packet

Execution mode: serial only. These commands were run one after the other and were not parallelized ...

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `2026-05-06T01:58:16Z` | `mix test ... --warnings-as-errors` | passed | `15 tests, 0 failures` |
| 2 | `2026-05-06T01:58:24Z` | `mix test --warnings-as-errors` | passed | `168 tests, 0 failures` |
```

**Evidence map headings** (lines 39-63):
```md
## Evidence Map

### Import
### Export
### Controlled Refresh
### Provenance
```

**Manual sign-off closeout** (lines 65-77):
```md
## Manual Sign-Off

The automated packet is complete, and the manual-only approval gate is now signed off:

1. Confirm ...
2. Confirm ...

Manual approval status: approved.
```

**Apply to Phase 10 artifact:** Keep the same section order and compactness, but swap the requirement label, evidence behaviors, and command counts for `CFG-04` rollover coverage. The Phase 13 context explicitly says this Phase 09 artifact is the strongest local precedent.

---

### `.planning/phases/13-certificate-rollover-validation-verification/13-01-PLAN.md` (config, batch)

**Analog:** `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md`

**Execution-plan frontmatter** (lines 1-28):
```md
---
phase: 12-metadata-refresh-trust-state-repair
plan: 12-03
type: execute
wave: 3
depends_on: ["12-02"]
files_modified:
  - .planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md
autonomous: false
requirements: [CFG-03]
must_haves:
  truths:
    - "Phase 09 has a verification artifact ..."
  artifacts:
    - path: ".planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md"
      provides: "CFG-03 verification evidence packet ..."
  key_links:
    - from: ".planning/phases/09-metadata-import-export-refresh/09-VALIDATION.md"
      to: ".planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md"
      via: "exact validation packet and manual checks from D-12"
      pattern: "CFG-03|manual"
---
```

**Objective block style** (lines 30-35):
```md
<objective>
Close `CFG-03` with serial verification evidence and an explicit human sign-off ...

Purpose: implement D-11 through D-13 ...
Output: `09-VERIFICATION.md` with focused smoke results, full-suite results, manual sign-off prose, and explicit traceability ...
</objective>
```

**Task structure** (lines 61-91):
```md
<tasks>

<task type="auto">
  <name>Task 1: Produce the serial CFG-03 verification artifact</name>
  <files>.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md</files>
  <read_first>...</read_first>
  <action>Run the locked Phase 12 verification packet serially ...</action>
  <verify>
    <automated>mix test ... && mix test --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>...</acceptance_criteria>
</task>
```

**Apply to `13-01-PLAN.md`:** Copy this exact envelope, but target `.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md`, set `requirements: [CFG-04]`, and make the must-have truth about syncing stale Wave 0 and per-task validation truth rather than producing a verification artifact.

---

### `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md` (config, batch)

**Analog:** `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md`

**Best-match reason:** This is the Phase 13 slice that directly mirrors Phase 12’s “produce the serial verification artifact” plan.

**Context block pattern** (lines 42-59):
```md
<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/v0.2-MILESTONE-AUDIT.md
@.planning/phases/09-metadata-import-export-refresh/09-VALIDATION.md
@.planning/phases/09-metadata-import-export-refresh/09-03-SUMMARY.md
@.planning/phases/09-metadata-import-export-refresh/09-04-SUMMARY.md
...
</context>
```

**Human-checkpoint pattern** (lines 94-117):
```md
<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Obtain human sign-off for the two manual Phase 09 validation checks</name>
  <read_first>...</read_first>
  <action>Present the two manual-only checks ... Ask the user to review ... After approval, add prose sign-off ...</action>
  <verify>
    <automated>rg -n "CFG-03|manual|HTTP-Redirect|write-side|runtime" ...</automated>
  </verify>
  <resume-signal>Type `approved` to continue ...</resume-signal>
</task>
```

**Threat model + verification close** (lines 122-149):
```md
<threat_model>
## Trust Boundaries
...
## STRIDE Threat Register
...
</threat_model>

<verification>
Execute the locked automated packet serially, then block on human approval ...
</verification>
```

**Apply to `13-02-PLAN.md`:** Keep the same two-task structure: `1)` serial evidence packet into `10-VERIFICATION.md`, `2)` blocking human check for the two narrow `CFG-04` semantics reviews already defined in [13-VALIDATION.md](/Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-VALIDATION.md:60).

---

### `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md` (config, batch)

**Analog:** `.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md`

**Must-have truth wiring** (lines 11-27):
```md
must_haves:
  truths:
    - "Phase 09 has a verification artifact ..."
    - "Focused Phase 09 smoke coverage and the full serial test suite are recorded as passing evidence."
    - "The two manual Phase 09 validation checks are explicitly signed off in prose."
  artifacts:
    - path: ".planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md"
      provides: "CFG-03 verification evidence packet ..."
  key_links:
    - from: ".planning/v0.2-MILESTONE-AUDIT.md"
      to: ".planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md"
      via: "closes the missing verification artifact ..."
```

**Apply to `13-03-PLAN.md`:** Reuse this must-have/key-link style, but point links at `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md`. The plan should frame root-doc updates as live-truth closure, not general cleanup.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**Requirement checkbox pattern** (lines 12-16):
```md
- [x] **CFG-01**: ...
- [x] **CFG-02**: ...
- [x] **CFG-03**: ...
- [ ] **CFG-04**: ...
- [ ] **CFG-05**: ...
```

**Traceability table pattern** (lines 44-54):
```md
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-01 | Phase 07 | Complete |
| CFG-02 | Phase 08 | Complete |
| CFG-03 | Phase 12 | Complete |
| CFG-04 | Phase 13 | Pending |
| CFG-05 | Phase 14 | Pending |
```

**Footer update stamp** (lines 61-63):
```md
---
*Requirements defined: 2026-04-26*
*Last updated: 2026-05-05 after Phase 12 execution*
```

**Apply in-place:** Flip only `CFG-04` and its traceability row once `10-VERIFICATION.md` exists; preserve the terse one-line requirement style and the “Last updated” footer format.

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md`

**Phase row pattern** (lines 12-21):
```md
| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 12 | Metadata refresh trust-state repair | Repair the failing refresh/apply path and re-verify metadata lifecycle behavior. | CFG-03 |
| 13 | Certificate rollover validation + verification | Close rollover validation gaps and produce milestone verification evidence. | CFG-04 |
| 14 | Mapping/audit milestone verification | Produce the missing mapping/audit milestone verification artifacts and close traceability. | CFG-05 |
```

**Phase detail block pattern** (lines 74-94):
```md
**Phase 12: Metadata refresh trust-state repair**
- Goal: ...
- Status: execution complete on 2026-05-05; awaiting `$gsd-verify-work`.
- Plans: 3 plans.
- Plan list:
- [x] `12-01-PLAN.md` ...
- [x] `12-02-PLAN.md` ...
- [x] `12-03-PLAN.md` ...
- Gap closure: ...
- Success criteria:
  1. ...
```

**Apply in-place:** Update only the Phase 13 detail block and, if closure is complete, use the same concise status language Phase 12 already uses. Do not broaden edits beyond the Phase 13 section.

---

### `.planning/STATE.md` (config, transform)

**Analog:** `.planning/STATE.md`

**YAML frontmatter status block** (lines 1-13):
```yaml
---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Phases
status: ready_for_verify
last_updated: "2026-05-06T02:00:00Z"
last_activity: 2026-05-05 -- Phase 12 execution completed; ready for verify-work
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 20
  completed_plans: 20
  percent: 100
---
```

**Current focus block** (lines 22-32):
```md
**Core value:** Every SAML login ends in a verified trust path or a typed rejection, never a silent compromise.  
**Current focus:** Phase 12 — metadata-refresh-trust-state-repair (ready for verify-work)

## Current Position

Phase: 12 (metadata-refresh-trust-state-repair) — READY FOR VERIFY
Plan: 3 of 3
Status: Execution complete; verification pending
Last activity: 2026-05-05 -- Phase 12 execution completed; phase smoke tests and verification packet passed
```

**Apply in-place:** Keep the same two-layer pattern: frontmatter summary plus human-readable current-position block. Only advance focus/status/last-activity/progress values needed for Phase 13 closure.

## Shared Patterns

### Compact Verification Artifact
**Sources:** [09-VERIFICATION.md](/Users/jon/projects/relyra/.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md:1), [13-CONTEXT.md](/Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md:35)
**Apply to:** `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md`
```md
## Scope
## Requirement Traceability
## Phase-Audit Gap Closed
## Automated Evidence Packet
## Evidence Map
## Manual Sign-Off
```

This is the exact shape the Phase 13 context calls out as the strongest local precedent.

### Serial-Only Evidence Recording
**Sources:** [09-VERIFICATION.md](/Users/jon/projects/relyra/.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md:28), [13-CONTEXT.md](/Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md:14)
**Apply to:** `10-VERIFICATION.md`, `13-02-PLAN.md`
```md
Execution mode: serial only. These commands were run one after the other and were not parallelized ...

| Order | Executed at (UTC) | Exact command | Status | Result |
```

### Closure-Plan Envelope
**Source:** [12-03-PLAN.md](/Users/jon/projects/relyra/.planning/phases/12-metadata-refresh-trust-state-repair/12-03-PLAN.md:1)
**Apply to:** `13-01-PLAN.md`, `13-02-PLAN.md`, `13-03-PLAN.md`
```md
---
phase: ...
plan: ...
type: execute
wave: ...
depends_on: [...]
files_modified:
  - ...
autonomous: false
requirements: [...]
must_haves:
  truths:
```

### Live-Truth Minimalism
**Sources:** [REQUIREMENTS.md](/Users/jon/projects/relyra/.planning/REQUIREMENTS.md:44), [ROADMAP.md](/Users/jon/projects/relyra/.planning/ROADMAP.md:88), [STATE.md](/Users/jon/projects/relyra/.planning/STATE.md:1)
**Apply to:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`
```md
Update only the requirement row, phase detail block, and current-state summary needed to remove the orphaned `CFG-04` status.
```

Do not mutate historical audit docs. Phase 13 context explicitly limits closure to current truth surfaces only.

## No Analog Found

None. Every Phase 13 target has a usable repo-local analog.

## Metadata

**Analog search scope:** `.planning/phases/**`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`
**Files scanned:** 9 required context files + 6 analog files + 3 root truth files
**Pattern extraction date:** 2026-05-05
