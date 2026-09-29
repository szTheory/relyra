---
gsd_state_version: "1.0"
milestone: v1.11
milestone_name: First-Adopter Twin
current_phase: 79
current_phase_name: Adopter-Ready Closeout
current_plan: Not started
status: planning
stopped_at: Phase 79 context gathered (research-augmented assumptions mode)
last_updated: "2026-09-29T21:04:35.052Z"
last_activity: 2026-09-29
last_activity_desc: Phase 78 complete, transitioned to Phase 79
state_head: 2c6d697c7d36013972281bd55883655b0cc41360
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 63
  completed_plans: 63
  percent: 86
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** Every SAML login ends in a verified trust path or a typed rejection —
never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Last updated:** 2026-09-28

**Current focus:** Phase 79 — Adopter-Ready Closeout

## Current Position

Phase: 79 — Adopter-Ready Closeout

Current Plan: Not started
Total Plans in Phase: Not planned
Next gate: Plan Phase 79 — Adopter-Ready Closeout.

Status: Ready to plan

Last activity: 2026-09-29 — Phase 78 complete, transitioned to Phase 79

## Milestone Metrics

- Last shipped milestone: v1.10 Docker DX & Fleet Proxy (Phases 68–72.1, shipped 2026-08-27)
- Current milestone: v1.11 First-Adopter Twin
- Requirements: 37 total, 37 mapped, 0 unmapped
- Planned phases: 7
- Highest shipped phase: 72.1
- Baseline `mix qa`: 794 tests, 0 failures on Elixir 1.19.5/OTP 28 (2026-09-09)

## Accumulated Context

### Decisions

- Use two cooperating twins: LedgerLoop for adopter/product realism and a clean-room
  Phoenix consumer for the publishable package boundary.
- The clean-room consumer builds and unpacks the local Hex artifact and cannot see root
  test support or checkout-only files.
- Deepen LedgerLoop/Northstar instead of creating a new demo theme or external repository.
- Fix adopter-significant findings in this milestone, stopping for public API, default,
  security-posture, SemVer-major, and remote GitHub changes.
- Keep scope feature-neutral. `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` remain
  demand-gated.
- New acceptance criteria require deterministic automated evidence in mandatory CI;
  external services remain scheduled canaries.
- Default to shift-left verification: add integration, E2E, smoke, seam, or browser
  automation to a mandatory CI lane whenever it provides recurring value. Avoid manual
  UAT and human completion gates; hand off only checks that cannot yet be automated, and
  track those as explicit automation gaps.
- Perform cleanup behind the twin's evidence and stop at diminishing returns rather than
  pursuing aesthetic purity.
- [Phase 76]: Bind replay keys to the trusted persisted request or resolved connection; ignore the response document ConnectionId for replay scope.
- [Phase 76]: Recover consumed request context only from the configured request-store adapter, then let the existing replay-store uniqueness constraint reject duplicates without changing behaviour callback signatures.
- [Phase 76]: Test the supported organization-scoped LiveAdmin path, including staged-key activation required before the draft connection can be enabled.
- [Phase 76]: Use the CertificateInventory after_fetch optimistic-lock hook to prove conflict rollback and successful retry; two simultaneous Sandbox transactions remain an automation gap.
- [Phase 76]: LedgerLoop receipt scenario keys use the verified principal connection ID because LoginResult carries that ID under principal; behaviour signatures remain unchanged.
- [Phase 76]: Incident recovery ties attempts to the seeded timeline by owning connection and explicit remediation cause; each ACS attempt keeps its own hashed correlation.
- [Phase 76]: Keep real-provider health on an independent schedule/dispatch workflow; require exact HTTPS origins before entering credentials and persist only allowlisted status metadata.
- [Phase 77]: Ignore quoted Markdown examples while retaining active prose and UAT rejection.
- [Phase 77]: Keep the JTBD map current and maintainer-owned; leave adopter narratives in user-flow guides.
- [Phase 77]: Bound signature rationale checks to source comments and @doc text, excluding executable code and policy strings.
- [Phase 77]: Only homogeneous same-character runs of sufficient length close a Markdown fence.
- [Phase 77]: Quoted fence contents are removed before inline-code and blockquote filtering.
- [Phase 77]: Backtick fence openers reject backticks in info strings while tilde info strings remain permissive.
- [Phase 77]: Phase 77 Plan 07: check active policy directives in PLAN and CONTEXT inputs; retain UAT artifact rejection as an independent check.
- [Phase 77]: Use Git-derived commit history and list every task hash on its own line for mechanical provenance checks.
- [Phase 77]: Treat generated verification reports as audit evidence while enforcing policy on PLAN and CONTEXT inputs and rejecting required UAT artifacts.
- [Phase 78]: Derive lifecycle membership from the active roadmap and validate all tracked Phase 78 plans.
- [Phase 78]: Enforce primary ownership uniqueness by requirement and criterion; keep independent defenses separately labeled.
- [Phase 78]: Remove the duplicate Fast lane from security-gates after QA and ci.fast both selected the same 960 default tests on each supported OTP version. — Three full baseline and three full candidate matrix runs passed. Candidate warm medians reduced matrix wall time by 4.83% and runner cost by 8.30%; QA, every consumer and security gate, browser smoke, and standalone GATE-02 remained enabled. Local ACT could not measure GitHub cache-service overhead, so no compiled cache was introduced.
- [Phase 78]: Run docs and verification suites with cmd mix test so every selected suite gets a fresh process. — Mix deduplicates bare test tasks inside aliases and can carry earlier selectors forward.
- [Phase 78]: Keep exact security suite selectors and standalone GATE-02 as blocking independent defenses. — AST and workflow fixtures reject collapsed, omitted, disabled, or zero-test gates.
- [Phase 78]: Use event- and workflow-qualified concurrency with PR-only cancellation — Evaluated fixtures prove a superseded PR only cancels within its own workflow while main and cross-workflow runs remain isolated.
- [Phase 78]: Keep deterministic browser journeys as required merge evidence and isolate real-provider checks in a scheduled/manual canary. — Owned local harnesses provide repeatable acceptance; provider availability is external and must not gate pull requests or main acceptance.
- [Phase 78]: Use exact bounded receipts for browser and canary artifacts. — Exact paths, closed fields, workflow validation, and owned cleanup prevent diagnostics or shared resources from leaking into merge artifacts.

### Baseline Findings

- Root adoption journeys execute inside Relyra and use private fixtures; they do not yet
  prove the Hex package as a clean-room consumer.
- LedgerLoop already has strong narrative and real-IdP foundations worth expanding.
- Standalone source/docs contain temporary phase, plan, decision-code, and UAT references.
- Root QA has one known incomplete-phase vocabulary-policy failure, inventoried for
  Phase 77. Phase 74 added a Mix test-ignore rule for fixture scripts, clearing the
  recurring test-pattern warning.
- Recent main and recurring Fleet/Keycloak canaries are green; CI topology still needs
  measured duration and ownership analysis.
- Live GitHub inventory currently shows no open issues or pull requests and several old
  branches; refresh before proposing any action.
- The untracked user-owned `.tool-versions` selects Node only. Use explicit installed
  Elixir/Erlang versions for local validation unless the owner changes that file.

### Guardrails

- Never trust XML `KeyInfo`; use configured IdP certificates only.
- Keep the single Saxy parse path and raw-binary pre-parse guards.
- Require digest recomputation and genuine `:public_key.verify` signature verification.
- Co-commit every trust mutation and audit row in one transaction.
- Preserve production replay protection and the fresh-process `mix ci.security` suites.
- Do not manually publish Hex or hand-edit `CHANGELOG.md`.

## Deferred Items

| Item | Status |
|---|---|
| AUTHN-POST-01 | Demand-gated |
| KMS-01 | Demand-gated |
| SIGNED-META-01 | Demand-gated |
| Hosted external twin | Deferred until the local package twin proves insufficient |
| Exhaustive compatibility matrix | Deferred until adopter evidence justifies its cost |

## Session Continuity

**Last session:** 2026-09-29T21:04:34.933Z

**Stopped at:** Phase 79 context gathered (research-augmented assumptions mode)

**Resume file:** .planning/phases/79-adopter-ready-closeout/79-CONTEXT.md

## Operator Next Step

Phase 78 and its Plan 09 gap closure are complete. Next, plan Phase 79 Adopter-Ready
Closeout with `$gsd-plan-phase 79`; do not implement Phase 79 work until its plan is
active.

Routing note: the GSD roadmap scan still reports Phases 73–76 as stale and may route
generic progress back to Phase 73. All 54 existing plans have matching summaries;
these earlier verification warnings remain visible, but do not indicate unexecuted
plans. Use the explicit Phase 78 planning command to continue the current STATE position.

Carryover records: `.planning/WINDOWS.md` retains two Phase 76 concurrency automation
gaps and the documented advisory waiver. The archival verification audit reports five
items across v1.7/v1.10 and zero current-milestone items. The Phase 73 documentation
policy window is reconciled to the completed Phase 77 fix and its passed verification.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 73 P01 | 9min | 2 tasks | 4 files |
| Phase 73 P02 | 20min | 2 tasks | 5 files |
| Phase 73 P03 | 17min | 2 tasks | 4 files |
| Phase 73 P04 | 12min | 2 tasks | 3 files |
| Phase 73 P05 | 24min | 3 tasks | 1 files |
| Phase 73 P06 | 9min | 2 tasks | 2 files |
| Phase 73 P07 | 11min | 2 tasks | 1 files |
| Phase 73 P08 | 15min | 2 tasks | 2 files |
| Phase 73 P09 | 39min | 2 tasks | 2 files |
| Phase 73 P10 | 18min | 2 tasks | 1 files |
| Phase 73 P11 | 18min | 2 tasks | 1 files |
| Phase 73 P12 | 16min | 2 tasks | 2 files |
| Phase 73 P13 | 19min | 3 tasks | 1 files |
| Phase 73 P14 | 10min | 2 tasks | 2 files |
| Phase 73 P15 | 26min | 2 tasks | 1 files |
| Phase 73 P16 | 21min | 2 tasks | 3 files |
| Phase 73 P17 | 60min | 2 tasks | 2 files |
| Phase 73 P18 | 12min | 2 tasks | 2 files |
| Phase 73 P19 | 14min | 2 tasks | 2 files |
| Phase 73 P20 | 3 min | 2 tasks | 2 files |
| Phase 73 P21 | 10min | 2 tasks | 1 files |
| Phase 73 P22 | 14 min | 2 tasks | 3 files |
| Phase 73 P23 | 17min | 3 tasks | 8 files |
| Phase 73 P24 | 37min | 3 tasks | 6 files |
| Phase 73 P25 | 16min | 2 tasks | 1 files |
| Phase 73 P26 | 38m 9s | 2 tasks | 5 files |
| Phase 74 P01 | 160 min | 2 tasks | 5 files |
| Phase 74 P02 | 20 | 2 tasks | 4 files |
| Phase 74 P03 | 17 | 3 tasks | 8 files |
| Phase 74 P04 | 75 min | 2 tasks | 35 files |
| Phase 73 P34 | 53min | 2 tasks | 6 files |
| Phase 75 P01 | 8 min | 2 tasks | 5 files |
| Phase 75 P02 | 5 min | 2 tasks | 4 files |
| Phase 75 P03 | 7 min | 2 tasks | 5 files |
| Phase 76 P01 | 29 min | 2 tasks | 7 files |
| Phase 76 P03 | 11min | 2 tasks | 2 files |
| Phase 76 P2 | 11 min | 2 tasks | 5 files |
| Phase 76 P4 | 13 min | 2 tasks | 5 files |
| Phase 76 P5 | 42 min | 2 tasks | 17 files |
| Phase 77 P1 | 11min | 2 tasks | 3 files |
| Phase 77 P02 | 13 min | 2 tasks | 3 files |
| Phase 77 P03 | 27min | 3 tasks | 2 files |
| Phase 77 P05 | 9min | 2 tasks | 1 files |
| Phase 77 P06 | 8min | 2 tasks | 1 files |
| Phase 77 P07 | 2min | 2 tasks | 1 files |
| Phase 77 P08 | 1h 4m | 2 tasks | 12 files |
| Phase 78 P01 | 38min | 3 tasks | 3 files |
| Phase 78 P2 | 8h | 3 tasks | 8 files |
| Phase 78 P3 | 21m | 2 tasks | 2 files |
| Phase 78 P4 | 15m | 3 tasks | 7 files |
| Phase 78 P5 | 26m | 2 tasks | 7 files |
| Phase 78 P6 | 43m | 3 tasks | 9 files |

### Resolved Issues

- Phoenix was upgraded from 1.8.7 to 1.8.13 in `ae1f0aa`, resolving GHSA-63mc-hw7g-86rr and GHSA-6983-jfq8-485w; `mix ci.security` passes.

## Blockers

None
