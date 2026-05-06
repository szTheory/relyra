# Phase 13: Certificate rollover validation + verification - Research

**Researched:** 2026-05-05 [VERIFIED: system date]  
**Domain:** Verification closure, validation sync, and milestone traceability for certificate rollover evidence (`CFG-04`) [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md]  
**Confidence:** HIGH [VERIFIED: current codebase inspection, current test execution, project planning artifacts, Hex registry, official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Verification packet strictness
- **D-01:** Use a balanced verification packet, not a minimal proof and not a belt-and-suspenders dossier.
- **D-02:** The verification packet should be serial and compact:
  - `mix compile --warnings-as-errors`
  - one focused serial rollover command covering `test/relyra/ecto/certificate_inventory_expiry_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs`, `test/relyra/ecto/certificate_inventory_concurrency_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/connection_snapshot_test.exs`
  - one `mix test --warnings-as-errors` full-suite confirmation
- **D-03:** Keep the packet intentionally non-duplicative. The goal is crisp `CFG-04` proof, not artifact volume.
- **D-04:** Preserve the serial-only posture already learned in earlier verification work; do not parallelize the verification commands for this phase.

### Traceability and artifact scope
- **D-05:** Phase 13 should create `10-VERIFICATION.md` as the authoritative verification artifact for `CFG-04`.
- **D-06:** Phase 13 should also update the minimum live-truth planning artifacts needed so `CFG-04` is no longer orphaned:
  - `.planning/REQUIREMENTS.md`
  - `.planning/ROADMAP.md`
  - `.planning/STATE.md`
- **D-07:** Do not broaden this phase into general milestone cleanup or historical artifact rewriting. Historical audit artifacts such as `.planning/v0.2-MILESTONE-AUDIT.md` should remain point-in-time evidence; milestone truth is refreshed by subsequent audit passes, not by mutating old audit findings.

### Evidence style and manual sign-off posture
- **D-08:** Use a hybrid verification artifact: executable proof first, brief narrative second.
- **D-09:** `10-VERIFICATION.md` should contain:
  - exact serial commands,
  - observed pass/fail results and counts,
  - a short `CFG-04` behavior-to-test/evidence map,
  - and only the minimum manual sign-off needed for semantics humans actually judge.
- **D-10:** Manual checks should stay capped at two narrow semantics reviews:
  - confirm the rollover API and typed conflict errors make the caller action obvious,
  - confirm runtime trust still consumes only active certs while staged and retired rows remain inventory facts only.
- **D-11:** Manual sign-off should not be used to prove functional correctness that the automated packet already proves.

### Decision-handling posture
- **D-12:** Planning and execution for this phase should be recommendation-first and low-friction: low-risk verification-shape choices should be decided by the workflow/agent by default.
- **D-13:** Escalate only decisions that materially change product semantics, trust guarantees, or milestone truth beyond `CFG-04` closure.

### the agent's Discretion
- Exact grouping of the focused rollover test command, as long as it covers expiry persistence, invalid transition handling, concurrency conflicts, resolver behavior, and active-only runtime hydration.
- Exact section names and prose layout inside `10-VERIFICATION.md`, as long as the artifact stays compact, reproducible, and easy to audit.
- Exact wording of the two manual checks, as long as they remain semantics-focused rather than re-testing functionality by hand.

### Deferred Ideas (OUT OF SCOPE)
- Broader milestone-state cleanup beyond the files Phase 13 directly settles.
- Any redesign of rollover APIs, lifecycle states, metadata staging semantics, or audit architecture.
- GSD-wide default tuning so recommendation-first, agent-resolved discussion becomes the standard path except for genuinely high-impact decisions.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-04 | User can manage certificate inventory for a connection with expiry tracking and staged rollover. [VERIFIED: .planning/REQUIREMENTS.md] | The code and tests already prove expiry persistence, staged promotion, rollback, conflict handling, resolver behavior, and active-only runtime hydration; Phase 13 should therefore plan only verification closure and traceability sync, not new lifecycle semantics. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex; lib/relyra/ecto/certificate_facts.ex; lib/relyra/ecto/connection_snapshot.ex; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs] |
</phase_requirements>

## Summary

Phase 13 is a closure phase, not an implementation phase. The missing Phase 10 Wave 0 tests named in `10-VALIDATION.md` now exist in the repo, and the locked serial evidence packet is green in the current workspace: `mix compile --warnings-as-errors` passed on 2026-05-06 UTC, the focused rollover command passed with `23 tests, 0 failures`, and the full suite passed with `168 tests, 0 failures`. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs; local command runs 2026-05-06 UTC]

The planning problem is therefore narrower than the audit text suggests. The product semantics are already shipped and green: metadata-derived certificates persist `not_before` and `not_after` from decoded X.509 facts, generic connection updates reject certificate replacement-by-omission, transition APIs enforce typed invalid-edge and conflict errors, resolver/runtime hydration excludes staged and retired rows, and rollback restores the prior active trust set explicitly. [VERIFIED: lib/relyra/ecto/certificate_facts.ex; lib/relyra/ecto/certificate_inventory.ex; lib/relyra/ecto/metadata_apply.ex; lib/relyra/ecto/connection.ex; lib/relyra/ecto/connection_snapshot.ex; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/connection_certificate_boundary_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs]

What remains stale is the proof metadata around that shipped behavior. `10-VALIDATION.md` still says `wave_0_complete: false`, `REQUIREMENTS.md` still marks `CFG-04` pending, `ROADMAP.md` still describes Phase 13 as future gap closure, and `STATE.md` still points at Phase 12 verification state. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md] The minimal plan should therefore consist of three slices only: sync Phase 10 validation truth, write the compact `10-VERIFICATION.md` packet, and update live milestone traceability so future audits stop treating `CFG-04` as orphaned. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md]

**Primary recommendation:** Plan three slices: `1)` update `10-VALIDATION.md` to reflect completed Wave 0 and the exact current proof surface, `2)` create `10-VERIFICATION.md` using the locked serial packet and two narrow manual sign-offs, and `3)` update `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` so `CFG-04` is visibly closed without rewriting historical audit artifacts. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verification packet execution | API / Backend [ASSUMED] | Database / Storage [ASSUMED] | Mix/ExUnit and Ecto-backed tests execute in the Elixir backend tier and need the test database for persistence-backed proof. [VERIFIED: mix.exs; test/test_helper.exs; config/test.exs] |
| Expiry persistence proof | Database / Storage [ASSUMED] | API / Backend [ASSUMED] | The behavior being proved is persisted certificate validity facts derived by backend code and stored on certificate rows. [VERIFIED: lib/relyra/ecto/certificate_facts.ex; lib/relyra/ecto/certificate_inventory.ex; test/relyra/ecto/certificate_inventory_expiry_test.exs] |
| Promotion / rollback / conflict proof | API / Backend [ASSUMED] | Database / Storage [ASSUMED] | Transition orchestration and optimistic-lock conflict normalization live in inventory services and are exercised through DB-backed tests. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs] |
| Runtime trust hydration proof | API / Backend [ASSUMED] | Database / Storage [ASSUMED] | Resolver and snapshot code define the runtime rule that only active signing certs become `idp_certificates`. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs] |
| Milestone traceability closure | Frontend Server (SSR) [ASSUMED] | API / Backend [ASSUMED] | This is documentation-state ownership inside the planning system rather than runtime product behavior. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/STATE.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `1.19.5` local runtime [VERIFIED: `elixir --version`; `mix --version`] | Compile and execute the verification packet. [VERIFIED: mix.exs] | This repo’s validation and verification workflow is Mix-first. [VERIFIED: mix.exs; .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md] |
| ExUnit | bundled with Elixir `1.19.5` [VERIFIED: `elixir --version`; test/test_helper.exs] | Focused and full automated evidence runs. [VERIFIED: test/test_helper.exs] | All current proof files are ExUnit tests. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs] |
| Ecto | locked `3.13.5`; latest `3.13.6` published 2026-05-05 [VERIFIED: mix.exs; `mix hex.info ecto`] | Repo transactions, optimistic locking, and DB-backed test harness. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex; config/test.exs] | Current rollover behavior and conflict contract are built on Ecto transactions and changesets. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Ecto SQL | locked `3.13.5`; latest `3.13.5` published 2026-03-03 [VERIFIED: mix.exs; `mix hex.info ecto_sql`] | Migration bootstrap and SQL sandbox support in tests. [VERIFIED: test/support/migration_case.ex; config/test.exs] | The verification packet depends on schema bootstrap and migration-backed integration tests. [VERIFIED: test/test_helper.exs; config/test.exs] |
| Postgrex | locked `0.22.0`; latest `0.22.1` published 2026-05-05 [VERIFIED: `mix hex.info postgrex`] | PostgreSQL adapter used by Ecto-backed verification tests. [VERIFIED: mix.exs; config/test.exs] | Current Phase 10 proof is persistence-backed, not pure unit-only. [VERIFIED: test/relyra/ecto/certificate_inventory_concurrency_test.exs; test/relyra/ecto/certificate_inventory_expiry_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | locked `1.8.5`; latest `1.8.6` published 2026-05-05 [VERIFIED: mix.exs; `mix hex.info phoenix`] | Indirect consumer of resolver/runtime trust state. [VERIFIED: mix.exs] | Only use as background context that resolver behavior must stay runtime-compatible. [VERIFIED: .planning/PROJECT.md; test/relyra/ecto/ecto_connection_resolver_test.exs] |
| telemetry | locked `1.4.1`; latest `1.4.1` published 2026-03-09 [VERIFIED: mix.exs; `mix hex.info telemetry`] | Existing observability baseline. [VERIFIED: mix.exs] | Not needed for Phase 13 proof beyond preserving existing project conventions. [VERIFIED: .planning/PROJECT.md] |
| OTP `:public_key` | `public_key v1.20.3` in OTP 28 docs [VERIFIED: `elixir --version`; official docs] | Certificate PEM and validity decoding used by expiry proof. [VERIFIED: lib/relyra/ecto/certificate_facts.ex] | Relevant because expiry persistence tests rely on decoded X.509 validity facts. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs] [CITED: https://www.erlang.org/doc/apps/public_key/public_key.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Serial Mix verification | Parallel Mix test invocations [VERIFIED: local failed parallel attempt 2026-05-06 UTC] | The repo’s migration bootstrap can race under parallel runs and produce invalid evidence; a parallel attempt in this session failed with duplicate `schema_migrations` creation while serial runs passed. [VERIFIED: local command runs 2026-05-06 UTC; .planning/v0.2-MILESTONE-AUDIT.md] |
| One focused rollover command plus one full-suite confirmation | Many redundant focused commands [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | The locked context explicitly prefers a compact, non-duplicative packet. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |
| `10-VERIFICATION.md` as authoritative proof | Reopening Phase 10 implementation docs or mutating the old milestone audit [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | Historical audit artifacts are point-in-time evidence and should remain unchanged. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```
[VERIFIED: mix.exs]

**Version verification:** [VERIFIED: local Hex registry queries on 2026-05-06 UTC]
```bash
mix hex.info ecto
mix hex.info ecto_sql
mix hex.info postgrex
mix hex.info phoenix
mix hex.info telemetry
```

## Architecture Patterns

### System Architecture Diagram

```text
serial verification packet
  |
  +--> mix compile --warnings-as-errors
  |
  +--> focused rollover proof command
  |      |
  |      +--> expiry persistence tests
  |      +--> transition + rollback tests
  |      +--> concurrency conflict tests
  |      +--> resolver hydration tests
  |      +--> runtime active-only snapshot tests
  |
  +--> mix test --warnings-as-errors
  |
  v
10-VERIFICATION.md
  |
  +--> exact commands + timestamps + counts
  +--> CFG-04 behavior-to-evidence map
  +--> two manual semantics sign-offs
  |
  v
traceability sync
  |
  +--> 10-VALIDATION.md wave_0_complete + evidence map
  +--> REQUIREMENTS.md CFG-04 complete
  +--> ROADMAP.md Phase 13 complete / gap closed
  +--> STATE.md current phase + verification status
```
[VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md]

### Recommended Project Structure
```text
.planning/
├── phases/
│   ├── 10-certificate-inventory-rollover/
│   │   ├── 10-VALIDATION.md
│   │   └── 10-VERIFICATION.md
│   └── 13-certificate-rollover-validation-verification/
│       └── 13-RESEARCH.md
├── REQUIREMENTS.md
├── ROADMAP.md
└── STATE.md
```
[VERIFIED: current repo tree and required output path]

### Pattern 1: Serial Evidence First
**What:** Run the exact compact packet in a fixed order and treat any parallelized run as invalid evidence. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; local command runs 2026-05-06 UTC]  
**When to use:** All Phase 13 verification capture and any later milestone re-audit replays. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md]  
**Example:**
```bash
# Source: /Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md
mix compile --warnings-as-errors
mix test test/relyra/ecto/certificate_inventory_expiry_test.exs \
  test/relyra/ecto/certificate_inventory_transition_test.exs \
  test/relyra/ecto/certificate_inventory_concurrency_test.exs \
  test/relyra/ecto/ecto_connection_resolver_test.exs \
  test/relyra/connection_snapshot_test.exs \
  --warnings-as-errors
mix test --warnings-as-errors
```

### Pattern 2: Behavior Map, Not Changelog
**What:** `10-VERIFICATION.md` should map each `CFG-04` behavior to the smallest authoritative proof source instead of restating implementation history. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md]  
**When to use:** Writing the verification artifact and any later audit refresh. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**Example:**
```markdown
| CFG-04 behavior | Proof source | Evidence |
| --- | --- | --- |
| Expiry persistence | `test/relyra/ecto/certificate_inventory_expiry_test.exs` | Focused serial rollover run passed with `23 tests, 0 failures`. |
```
[VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md; test/relyra/ecto/certificate_inventory_expiry_test.exs]

### Pattern 3: Live Truth Sync After Proof
**What:** Update the small set of live planning files immediately after producing the verification artifact so the requirement is no longer orphaned. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**When to use:** Same change set as `10-VERIFICATION.md`. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**Example:**
```markdown
REQUIREMENTS.md: mark CFG-04 complete
ROADMAP.md: mark Phase 13 complete and note verification closure
STATE.md: advance current focus from Phase 12 verify state
```
[VERIFIED: .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md]

### Anti-Patterns to Avoid
- **Treating `10-VALIDATION.md` as current truth without updating it:** it still says `wave_0_complete: false` even though the named Wave 0 files now exist and pass. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; local command runs 2026-05-06 UTC]
- **Using a parallel test run as evidence:** a parallel attempt in this session produced a duplicate `schema_migrations` failure while isolated serial runs passed. [VERIFIED: local command runs 2026-05-06 UTC]
- **Reopening lifecycle semantics:** the current green proof surface already covers the requirement’s behavior; Phase 13 is not the place to redesign active/next/retired meaning. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/connection_snapshot_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification artifact structure | A bespoke longform report format [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | Reuse the compact precedent from `09-VERIFICATION.md`. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md] | The repo already has an accepted shape for serial commands, evidence tables, and narrow manual sign-off. [VERIFIED: .planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md] |
| Proof of expiry semantics | Handwritten prose only [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | `certificate_inventory_expiry_test.exs` plus current focused command results. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; local command runs 2026-05-06 UTC] | The test already proves persisted timestamps come from certificate facts, not rollout timestamps. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs] |
| Proof of conflict handling | Manual retry/refresh explanation only [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md] | Existing transition and concurrency tests plus one narrow manual DX check. [VERIFIED: test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs] | Functional correctness is automated already; manual review should judge caller clarity only. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |
| Milestone truth | Editing the historical audit file [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | Update live truth in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, then rerun audit later. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md] | The audit file is point-in-time evidence, not the canonical current state. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |

**Key insight:** Phase 13 should close a documentation-truth gap, not search for a code gap. [VERIFIED: current green proof packet and stale planning artifacts on 2026-05-06 UTC]

## Common Pitfalls

### Pitfall 1: Using stale validation metadata as if coverage were still missing
**What goes wrong:** The planner wastes slices re-adding tests that already exist. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs]  
**Why it happens:** `10-VALIDATION.md` still reflects the earlier Wave 0 gap state. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md]  
**How to avoid:** Start by syncing `10-VALIDATION.md` to the current files and results before planning any “missing coverage” work. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; local command runs 2026-05-06 UTC]  
**Warning signs:** The plan includes creating files that already exist or describes expiry/concurrency tests as absent. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs]

### Pitfall 2: Collecting invalid evidence from parallel test execution
**What goes wrong:** Migration bootstrap races produce false failures and contaminate the verification packet. [VERIFIED: local failed parallel attempt 2026-05-06 UTC; .planning/v0.2-MILESTONE-AUDIT.md]  
**Why it happens:** Multiple Mix test invocations compete during schema bootstrap. [VERIFIED: local failed parallel attempt 2026-05-06 UTC]  
**How to avoid:** Run the packet strictly serially and record that serial-only posture in `10-VERIFICATION.md`. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**Warning signs:** Duplicate `schema_migrations` creation, build-directory lock waits, or proof commands launched together. [VERIFIED: local failed parallel attempt 2026-05-06 UTC]

### Pitfall 3: Producing `10-VERIFICATION.md` without updating live traceability
**What goes wrong:** The requirement still reads pending/orphaned even though the verification file exists. [VERIFIED: .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md; .planning/v0.2-MILESTONE-AUDIT.md]  
**Why it happens:** The milestone system uses multiple live truth surfaces, not the verification file alone. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**How to avoid:** Update `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` in the same slice as `10-VERIFICATION.md`. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]  
**Warning signs:** `CFG-04` remains unchecked or Phase 13 still reads as future work after the verification artifact is added. [VERIFIED: .planning/REQUIREMENTS.md; .planning/ROADMAP.md]

### Pitfall 4: Letting milestone truth remain partially stale after closure
**What goes wrong:** Readers see conflicting statements across current state, audit history, and project overview. [VERIFIED: .planning/STATE.md; .planning/v0.2-MILESTONE-AUDIT.md; .planning/PROJECT.md]  
**Why it happens:** The project intentionally preserves historical audit snapshots, and `PROJECT.md` still lists active milestone requirements generically. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/PROJECT.md]  
**How to avoid:** Update only the locked live-truth files now, then rerun milestone audit afterward; treat `PROJECT.md` staleness as a known non-blocking residual unless separately requested. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/PROJECT.md]  
**Warning signs:** `10-VERIFICATION.md` exists, but `v0.2-MILESTONE-AUDIT.md` still shows `CFG-04` orphaned and `PROJECT.md` still presents all CFG requirements as active. [VERIFIED: .planning/v0.2-MILESTONE-AUDIT.md; .planning/PROJECT.md]

## Code Examples

Verified patterns from official and repo-local sources:

### Current Focused Proof Packet
```bash
# Source: /Users/jon/projects/relyra/.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md
mix test test/relyra/ecto/certificate_inventory_expiry_test.exs \
  test/relyra/ecto/certificate_inventory_transition_test.exs \
  test/relyra/ecto/certificate_inventory_concurrency_test.exs \
  test/relyra/ecto/ecto_connection_resolver_test.exs \
  test/relyra/connection_snapshot_test.exs \
  --warnings-as-errors
```

### Atomic Transition Pattern Already In Use
```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex
transact(repo, fn ->
  with {:ok, connection} <- fetch_connection(repo, connection_id, operation),
       :ok <- bump_connection_lock(repo, connection, operation),
       {:ok, refreshed_connection} <- fetch_connection(repo, connection_id, operation),
       {:ok, updated_certificate} <-
         do_transition(repo, refreshed_connection, fingerprint, target_state, operation, opts) do
    {:ok, updated_certificate}
  end
end)
```
[VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Optimistic Lock Contract Backing Conflict Tests
```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex
connection
|> Ecto.Changeset.change(updated_at: DateTime.utc_now())
|> Ecto.Changeset.optimistic_lock(:lock_version)
```
[VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Audit says Phase 10 coverage is partial and Wave 0 incomplete. [VERIFIED: .planning/v0.2-MILESTONE-AUDIT.md; .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md] | Current codebase has the named Wave 0 tests and they pass in serial execution. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; local command runs 2026-05-06 UTC] | By 2026-05-06 UTC in the current repo state. [VERIFIED: local command runs 2026-05-06 UTC] | Phase 13 should plan verification closure, not new test implementation. [VERIFIED: current codebase inspection and command runs] |
| `Repo.transaction/2` was the older Ecto API. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | `Repo.transact/2` is the current API and `transaction/2` is documented as deprecated. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Present in current Ecto v3.13.6 docs. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | The current repo’s inventory service already follows the newer transaction API shape. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] |

**Deprecated/outdated:**
- Treating `10-VALIDATION.md` Wave 0 gaps as current implementation gaps is outdated for the present repo state. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs]

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this
> section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Verification packet execution is best classified under the API / Backend tier. | Architectural Responsibility Map | Low; affects planner labeling, not implementation. |
| A2 | Expiry persistence proof is primarily a Database / Storage responsibility. | Architectural Responsibility Map | Low; affects task grouping only. |
| A3 | Promotion / rollback / conflict proof is primarily an API / Backend responsibility. | Architectural Responsibility Map | Low; affects task grouping only. |
| A4 | Runtime trust hydration proof is primarily an API / Backend responsibility. | Architectural Responsibility Map | Low; affects task grouping only. |
| A5 | Milestone traceability closure is best classified as Frontend Server / planning-surface ownership. | Architectural Responsibility Map | Low; affects task grouping only. |

## Open Questions (RESOLVED)

1. **Should Phase 13 also update `PROJECT.md` after closing `CFG-04`?**
   - What we know: locked scope requires only `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` for live-truth sync, and explicitly rejects broad cleanup. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]
   - Resolution: no. Per D-06 and D-07, Phase 13 updates only `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`; `PROJECT.md` remains out of scope for this closure slice even if it stays cosmetically stale until a later milestone-surface refresh. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/PROJECT.md]

2. **Should rerunning the milestone audit be part of Phase 13 execution or a later verification pass?**
   - What we know: the old audit file must remain unchanged, and a fresh audit is the mechanism that refreshes historical milestone truth. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md]
   - Resolution: later verification pass. Per D-07, Phase 13 closes `CFG-04` by adding `10-VERIFICATION.md` and refreshing the three live-truth files only; rerunning the milestone audit is a subsequent workflow step and must not be folded into this phase's scope. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix compile`, `mix test` verification packet [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | ✓ [VERIFIED: `command -v elixir`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | verification packet execution [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] | ✓ [VERIFIED: `command -v mix`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI / local test DB tooling | Ecto migration bootstrap and persistence-backed tests [VERIFIED: config/test.exs; test/test_helper.exs] | ✓ [VERIFIED: `command -v psql`; `command -v postgres`] | `psql 14.17` [VERIFIED: `psql --version`] | No practical fallback for the current integration-heavy proof packet. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs] |
| Docker | optional for local DB fallback or developer setup [ASSUMED] | ✓ [VERIFIED: `command -v docker`] | `29.4.1` [VERIFIED: `docker --version`] | Not required if local Postgres is already available. [VERIFIED: current successful test runs 2026-05-06 UTC] |

**Missing dependencies with no fallback:**
- None found for the current machine. [VERIFIED: local command runs and tool availability checks on 2026-05-06 UTC]

**Missing dependencies with fallback:**
- None found for the current machine. [VERIFIED: local command runs and tool availability checks on 2026-05-06 UTC]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix on Elixir `1.19.5` [VERIFIED: test/test_helper.exs; `elixir --version`; `mix --version`] |
| Config file | `mix.exs`, `test/test_helper.exs`, `config/test.exs` [VERIFIED: files] |
| Quick run command | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; local command run 2026-05-06 UTC] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; local command run 2026-05-06 UTC] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-04 | Imported and staged certificates persist X.509 `not_before` / `not_after` facts. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs] | integration [VERIFIED: test file] | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs --warnings-as-errors` [VERIFIED: test file] | ✅ [VERIFIED: file exists] |
| CFG-04 | Invalid lifecycle edges fail with typed `:invalid_lifecycle_transition` errors. [VERIFIED: test/relyra/ecto/certificate_inventory_transition_test.exs] | unit/integration [VERIFIED: test file] | `mix test test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` [VERIFIED: test file] | ✅ [VERIFIED: file exists] |
| CFG-04 | Concurrent promotion conflicts fail closed with typed `:conflict` behavior. [VERIFIED: test/relyra/ecto/certificate_inventory_concurrency_test.exs] | integration [VERIFIED: test file] | `mix test test/relyra/ecto/certificate_inventory_concurrency_test.exs --warnings-as-errors` [VERIFIED: test file] | ✅ [VERIFIED: file exists] |
| CFG-04 | Resolver exposes only active runtime trust while staged rows stay inventory-only. [VERIFIED: test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs] | integration + unit [VERIFIED: test files] | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` [VERIFIED: test files] | ✅ [VERIFIED: files exist] |
| CFG-04 | Boundary rejects generic connection certificate replacement by omission. [VERIFIED: test/relyra/ecto/connection_certificate_boundary_test.exs; test/relyra/ecto/connection_schema_test.exs] | integration + unit [VERIFIED: test files] | `mix test test/relyra/ecto/connection_certificate_boundary_test.exs test/relyra/ecto/connection_schema_test.exs --warnings-as-errors` [VERIFIED: test files] | ✅ [VERIFIED: files exist] |

### Sampling Rate
- **Per task commit:** `mix compile --warnings-as-errors` plus the focused rollover command above. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]
- **Per wave merge:** `mix test --warnings-as-errors`. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]
- **Phase gate:** serial packet must be green before `10-VERIFICATION.md` is finalized. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md]

### Wave 0 Gaps
- None — the previously missing rollover-specific Wave 0 files now exist and the focused packet passed with `23 tests, 0 failures` on 2026-05-06 UTC. [VERIFIED: test/relyra/ecto/certificate_inventory_expiry_test.exs; test/relyra/ecto/certificate_inventory_transition_test.exs; test/relyra/ecto/certificate_inventory_concurrency_test.exs; local command run 2026-05-06 UTC]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [ASSUMED] | `CFG-04` affects the certificate trust material that authentication consumes, even though Phase 13 itself is verification-only. [VERIFIED: .planning/PROJECT.md; lib/relyra/ecto/connection_snapshot.ex] |
| V3 Session Management | no [ASSUMED] | No session-state behavior is in scope for this phase. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |
| V4 Access Control | no [ASSUMED] | No authorization-surface change is in scope for this phase. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md] |
| V5 Input Validation | yes [ASSUMED] | Ecto changesets and typed error normalization protect certificate transition and boundary validation. [VERIFIED: lib/relyra/ecto/connection.ex; lib/relyra/ecto/certificate_inventory.ex] |
| V6 Cryptography | yes [ASSUMED] | OTP `:public_key` decodes X.509 certificate validity facts; runtime trust hydration remains certificate-driven. [VERIFIED: lib/relyra/ecto/certificate_facts.ex; lib/relyra/ecto/connection_snapshot.ex] [CITED: https://www.erlang.org/doc/apps/public_key/public_key.html] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False verification evidence from parallel DB bootstrap | Tampering [ASSUMED] | Serial-only packet and explicit note that parallel evidence is invalid. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; local failed parallel attempt 2026-05-06 UTC] |
| Runtime trust contamination by staged/retired certs | Elevation of Privilege [ASSUMED] | `ConnectionSnapshot` and resolver tests prove only active signing certs hydrate runtime trust. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex; test/relyra/ecto/ecto_connection_resolver_test.exs; test/relyra/connection_snapshot_test.exs] |
| Silent overwrite during concurrent rollover | Tampering [ASSUMED] | Optimistic lock on `lock_version` plus typed `:conflict` tests. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex; test/relyra/ecto/certificate_inventory_concurrency_test.exs] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Stale milestone truth after proof capture | Repudiation [ASSUMED] | Update live truth files in the same slice as the verification artifact and rerun audit later. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; .planning/v0.2-MILESTONE-AUDIT.md] |

## Sources

### Primary (HIGH confidence)
- `lib/relyra/ecto/certificate_inventory.ex` - current transition, conflict, and staging behavior. [VERIFIED: code inspection]
- `lib/relyra/ecto/certificate_facts.ex` - current PEM/X.509 validity extraction behavior. [VERIFIED: code inspection]
- `lib/relyra/ecto/connection.ex` - current certificate write-boundary protection. [VERIFIED: code inspection]
- `lib/relyra/ecto/connection_snapshot.ex` - active-only runtime trust hydration rule. [VERIFIED: code inspection]
- `test/relyra/ecto/certificate_inventory_expiry_test.exs` - expiry persistence proof. [VERIFIED: code inspection]
- `test/relyra/ecto/certificate_inventory_transition_test.exs` - invalid transition and rollback proof. [VERIFIED: code inspection]
- `test/relyra/ecto/certificate_inventory_concurrency_test.exs` - concurrency conflict proof. [VERIFIED: code inspection]
- `test/relyra/ecto/ecto_connection_resolver_test.exs` - resolver/runtime rollover proof. [VERIFIED: code inspection]
- `test/relyra/connection_snapshot_test.exs` - active-only runtime trust proof. [VERIFIED: code inspection]
- `.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md` - locked scope and artifact decisions. [VERIFIED: file inspection]
- `.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md` - stale Wave 0 state that Phase 13 must refresh. [VERIFIED: file inspection]
- `.planning/v0.2-MILESTONE-AUDIT.md` - orphaned `CFG-04` audit evidence and serial-run warning. [VERIFIED: file inspection]
- Local command runs on 2026-05-06 UTC:
  - `mix compile --warnings-as-errors` -> passed. [VERIFIED: local execution]
  - focused rollover command -> `23 tests, 0 failures`. [VERIFIED: local execution]
  - `mix test --warnings-as-errors` -> `168 tests, 0 failures`. [VERIFIED: local execution]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/ecto/Ecto.Repo.html - transaction and deprecation guidance for `transact/2` vs `transaction/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- https://hexdocs.pm/ecto/Ecto.Changeset.html - optimistic locking behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
- https://hexdocs.pm/ecto/Ecto.Multi.html - guidance on when `Ecto.Multi` is most useful. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- https://www.erlang.org/doc/apps/public_key/public_key.html - OTP certificate decoding APIs. [CITED: https://www.erlang.org/doc/apps/public_key/public_key.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: all non-local claims in this document were verified via official docs or local execution]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified locally against the current repo and Hex registry. [VERIFIED: mix.exs; `mix hex.info ...`; `elixir --version`; `mix --version`]
- Architecture: HIGH - this phase is tightly constrained by locked context and current green proof surface. [VERIFIED: .planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md; code/test inspection; local command runs]
- Pitfalls: HIGH - each listed pitfall is grounded in either stale local artifacts or observed execution behavior from this session. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md; .planning/v0.2-MILESTONE-AUDIT.md; local command runs]

**Research date:** 2026-05-05 [VERIFIED: system date]  
**Valid until:** 2026-06-04 for planning shape; rerun evidence commands if the repo changes before execution. [ASSUMED]
