---
gsd_state_version: "1.0"
milestone: v1.11
milestone_name: Phases
current_phase: 73
current_phase_name: Twin Contract and Baseline
status: executing
stopped_at: Completed 73-24-PLAN.md
last_updated: "2026-09-11T21:09:29.048Z"
last_activity: 2026-09-11
last_activity_desc: Completed Plan 73-24 evidence authority and Mix argv closure
state_head: 51a7d05dc5d4acb0ca300ff7f3812cb38d18eec7
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 26
  completed_plans: 24
  percent: 92
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** Every SAML login ends in a verified trust path or a typed rejection —
never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Current focus:** Phase 73 — Twin Contract and Baseline

## Current Position

Phase: 73 (Twin Contract and Baseline) — EXECUTING

Plan: 25 of 26

Status: 24 plans complete; Plan 73-25 is next

Last activity: 2026-09-11 — Completed Plan 73-24 evidence authority and Mix argv closure

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
- Perform cleanup behind the twin's evidence and stop at diminishing returns rather than
  pursuing aesthetic purity.
- [Phase 73]: Use a closed, test-only Elixir ledger whose planned rows remain visible but cannot satisfy deterministic closure.
- [Phase 73]: Treat only existing non-canary rows with a real tagged test, fresh-process alias, and executable workflow command as closure evidence.
- [Phase 73]: Treat the quality/CI baseline as inventory only; one-run timings are samples and remediation stays routed to Phases 74, 77, 78, or 79.
- [Phase 73]: Keep live required-check repair behind remote_github approval in Phase 79 and preserve the exact desired/current context drift as a release blocker.
- [Phase 73]: Accept baseline rows only through anchored tables, closed enums, severity rules, ownership fields, and redaction-safe evidence.
- [Phase 73]: Require each risky mutation to have a matching plan-local blocking approval_class checkpoint before the first mutation task.
- [Phase 73]: Require remote GitHub approval to describe one exact reversible batch with preflight, rollback, read-back, and resume signal.
- [Phase 73]: Keep authorization separate from completion; only deterministic automated evidence can close acceptance criteria.
- [Phase 73]: Count evidence selectors only when parsed ExUnit source associates them with real test definitions.
- [Phase 73]: Recognize evidence workflow ownership only in the enabled blocking Evidence contract step under jobs.security.
- [Phase 73]: Require every acceptance-bearing non-checkpoint task to own executable non-zero proof independently.
- [Phase 73]: Task risk metadata is mandatory but governed files, entry points, and diffs independently determine approval. — Optimistic declarations cannot suppress a matching plan-local checkpoint.
- [Phase 73]: Remote approval is one parsed reversible batch bound to the same repository, branch, checks, and captured state. — Keyword prose cannot authorize an ambiguous or non-reversible remote mutation.
- [Phase 73]: Demand-gated identifiers are allowed only in the exact plan-level exclusion and fixture-data regions. — Task names, files, and actions have no negation or policy-prose exemption.
- [Phase 73]: Each baseline finding requires one complete allowed repository or executable verification reference. — Arbitrary non-empty provenance prose cannot satisfy the baseline contract.
- [Phase 73]: Model direct-test ownership as enabled include-tag intersection minus matching exclusions, rejecting an empty effective set.
- [Phase 73]: Treat the Evidence contract as mandatory only when jobs.security has one exact unconditional step with absent or literal-false fallibility.
- [Phase 73]: Validate task type before authorization, risk, verification, and feature-neutrality branches; only exact decision checkpoints are authorization-only.
- [Phase 73]: Treat completed-plan task commits or explicit before/after inputs as additive changed-surface evidence, never as a PLAN exemption.
- [Phase 73]: Retain deterministic legacy-schema checks for Plans 73-01 through 73-03 while applying the exact current contract to later plans.
- [Phase 73]: Authorize remote batches only after each field is fully consumed by one closed operation grammar and parsed targets agree.
- [Phase 73]: Accept baseline paths only when every root-relative component is non-symlink, the leaf is regular, and git tracks the lexical repository path.
- [Phase 73]: Delegate baseline command evidence to the same executable non-zero owner validator used by adoption evidence.
- [Phase 73]: Accept verification text only when one anchored ASCII grammar fully consumes uppercase environment assignments and one supported Mix argv.
- [Phase 73]: Treat actual Mix project configuration and fresh-process ExUnit registration, rather than source-shaped tuples or macros, as ownership authority.
- [Phase 73]: Evaluate workflow fallibility and ordered path filters independently for pull requests and main pushes across every acceptance-bearing planning artifact.
- [Phase 73]: Governance begins only after PROJECT, ROADMAP, REQUIREMENTS, and STATE establish one agreeing active v1.11 identity with a real current-phase directory and plan frontier.
- [Phase 73]: Only exact completed paths 73-01 through 73-03 use the legacy schema; every other plan receives the current contract regardless of removable document content.
- [Phase 73]: Completed-plan changes come from reachable exact-scope Git commits before the unique SUMMARY-add boundary; SUMMARY hashes are equality-checked but never authoritative.
- [Phase 73]: Remote authorization reduces fields only after exact scalar/list cardinality, closed syntax, non-empty values, and list uniqueness are established.
- [Phase 73]: File-backed and script-backed operations share repository provenance; scripts additionally require executable index mode, working-tree blob equality, and a fixed local print-mode result.
- [Phase 73]: Resolve each evidence lane once from actual Mix project configuration and require every command owner to retain a positive effective ExUnit selection.
- [Phase 73]: Reject positive paths on the mandatory Evidence contract workflow and allow ignore patterns only when disjoint from all fixed and tracked Phase 73 inputs.
- [Phase 73]: Normalize and retain every accepted branch-protection control, treating non-declared controls as exact safe invariants shared by mutation and rollback authorization.
- [Phase 73]: Authorize script batches from indexed executable identity plus a separately tracked static JSON result, never by launching plan-selected code.
- [Phase 73]: Always derive completed-plan commits from ordered exact-scope Git history; manifests and SUMMARY hashes may only audit that derived set for exact equality.
- [Phase 73]: Validate each required workflow event and every direct child-key occurrence before reducing branch or path semantics.
- [Phase 73]: Require push branches to equal the single literal main selector and forbid pull-request activity filters entirely.
- [Phase 73]: Authorize remote mutation and rollback only through tracked complete-state gh api --input payloads; scripts and static results have no authorization role.
- [Phase 73]: Resolve one full HEAD review endpoint and classify every reachable exact-scope commit before and after the SUMMARY-add boundary.
- [Phase 73]: Keep SUMMARY and manifest equality audits restricted to pre-boundary tasks so claims cannot omit or authorize descendants.
- [Phase 73]: Close CR-06 only after both Plan 73-14 focused selector owners and the mandatory evidence lane pass.
- [Phase 73]: Treat declarative payload authorization plus exact-HEAD descendant provenance as sufficient to close CR-07 and CR-08 while retaining T-73-12 as a visible medium follow-up.
- [Phase 73]: Capture each lexical evidence owner once through fresh ExUnit registration, then validate the immutable normalized snapshot without further discovery.
- [Phase 73]: Reuse registered tags only for the same absolute owner path and SHA-256 source identity within one test VM; source changes always force fresh registration.
- [Phase 73]: Reject workflow constructs outside the repository's literal, single-star, and whole-double-star subset instead of approximating GitHub matching.
- [Phase 73]: Require component-wise lstat and exact Git-index identity for the declared lexical owner before registered-test discovery.
- [Phase 73]: Record current review findings as open before closure evidence restores verified status.
- [Phase 73]: Close T-73-67, T-73-70, and T-73-71 only after all four focused selectors, three unchanged sub-60-second evidence runs, and the full security lane pass.
- [Phase 73]: A later Critical review and red mandatory lane invalidate the prior verified seal until current deterministic evidence closes the defects. — Current source and mandatory-lane output supersede earlier green evidence under D-07, D-08, and D-12.
- [Phase 73]: Keep threats_open threshold-aware: T-73-67 is the sole blocking threat while T-73-12 and T-73-76 remain visible lower-severity follow-ups. — The configured high threshold counts blockers without erasing medium risks.
- [Phase 73]: Treat executing, in_progress, and ready_for_verification as the only active governance lifecycle states.
- [Phase 73]: Preserve serialized live STATE while proving ready_for_verification through a checked-in identity fixture that changes only the lifecycle field.
- [Phase 73]: Restrict frontmatter whitespace after field colons to horizontal whitespace so empty status values cannot consume the next line.
- [Phase 73]: Keep the registration cache ResourceId caller-independent and content-addressed; self() appears only in OTP's LockRequesterId slot. — This serializes simultaneous misses without changing the default fresh-process ExUnit authority.
- [Phase 73]: Bind candidate governed inputs exactly to one sorted capture-time inventory before workflow reduction. — Pure snapshots cannot gain coverage by omission, substitution, escape, absolute paths, duplicates, or reordering.
- [Phase 73]: Keep the complete unchanged mix ci.security lane mandatory and passing with no timing ceiling, while retaining all three independent sub-60-second mix ci.evidence requirements.
- [Phase 73]: Stage the exact current proof set before changing security or Nyquist disposition, then reduce both reports from that same committed evidence.
- [Phase 73]: Count threats_open at the configured high threshold while preserving T-73-12 as a visible open medium follow-up.
- [Phase 73]: Use a repository root outside the mutable snapshot as independent authority for both governed-input fields.
- [Phase 73]: Require jobs.security to remain dependency-free so skipped prerequisites cannot suppress mandatory evidence.
- [Phase 73]: Accept only fully consumed Mix test argv and model includes as ExUnit alternatives that override exclusions.

### Baseline Findings

- Root adoption journeys execute inside Relyra and use private fixtures; they do not yet
  prove the Hex package as a clean-room consumer.
- LedgerLoop already has strong narrative and real-IdP foundations worth expanding.
- Standalone source/docs contain temporary phase, plan, decision-code, and UAT references.
- Root QA has one known incomplete-phase vocabulary-policy failure and reports Mix
  test-pattern warnings; both are inventoried for Phase 77.
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

**Last session:** 2026-09-11T21:09:29.011Z

**Stopped at:** Completed 73-24-PLAN.md

**Resume file:** None

## Operator Next Step

Execute Plan 73-25 to close task-syntax, completion-boundary, and merge-provenance gaps.

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

### Blockers

- Phoenix was upgraded from 1.8.7 to 1.8.13 in `ae1f0aa`, resolving GHSA-63mc-hw7g-86rr and high-severity GHSA-6983-jfq8-485w; `mix ci.security` now passes.
