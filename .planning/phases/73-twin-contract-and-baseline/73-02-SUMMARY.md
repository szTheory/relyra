---
phase: 73-twin-contract-and-baseline
plan: 02
subsystem: governance
tags: [elixir, exunit, quality-baseline, ci-inventory, fail-closed-validation]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: deterministic adoption evidence registry and mandatory ci.evidence lane from Plan 01
provides:
  - Dated repository-wide quality findings ledger with stable ownership and disposition fields
  - CI before-snapshot covering topology, sampled duration, duplication, cache, ownership, drift, and failure evidence
  - Fail-closed Markdown parser contract executed alongside adoption evidence in ci.evidence
affects: [74-packaged-consumer, 77-craftsmanship, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 8913
  tasks: 2
  commits: 7
tech-stack:
  added: []
  patterns: [anchored Markdown table parsing, inline malformed controls, severity-specific disposition validation]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md, test/governance/milestone_scope_test.exs]
  modified: [mix.exs, test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs, .planning/WINDOWS.md]
key-decisions:
  - "Treat the baseline as inventory only: one-run CI timings are samples, while remediation remains routed to Phases 74, 77, 78, or 79."
  - "Keep live required-check repair behind remote_github approval in Phase 79 and record the exact desired/current context drift as a release blocker."
  - "Accept baseline rows only through exact anchored tables, closed enums, severity rules, ownership fields, and redaction-safe evidence."
patterns-established:
  - "Baseline row contract: stable ID plus evidence, disposition, owner, target phase, approval class, blocker state, and revisit date."
  - "CI evidence contract: safe summaries and provenance identify failure ownership without retaining authentication payloads or secrets."
requirements-completed: [QUAL-01, PIPE-01]
coverage:
  - id: D1
    description: "Maintainers can inspect a dated seven-category, five-severity repository findings inventory with explicit ownership and disposition."
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#dated baseline publishes the complete severity-ranked findings contract"
        status: pass
    human_judgment: false
  - id: D2
    description: "Maintainers can inspect a dated CI before-snapshot without mistaking a single sample for an optimization trend."
    requirement: PIPE-01
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 02: Quality and CI Baseline Summary

**Dated severity-ranked repository findings and CI before-state with anchored, fail-closed validation in the mandatory evidence lane**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-09T17:51:53Z
- **Completed:** 2026-09-09T18:11:25Z
- **Tasks:** 2
- **Files modified:** 5 implementation files plus the broken-windows ledger

## Accomplishments

- Published ten stable findings spanning correctness, security, integration, readability, documentation, artifacts, and CI, with every row carrying reproducible evidence and lifecycle ownership.
- Captured nine CI surfaces with the current 14-workflow topology, one-run duration samples, duplication classification, cache declarations, lane ownership, required-check drift, and redaction-safe failure behavior.
- Added anchored parsers and malformed-document controls for duplicate headings and IDs, empty cells, invalid enums, missing ownership, severity-policy violations, and sensitive CI payloads.
- Expanded `ci.evidence` so the adoption and governance contracts execute together in one fresh process with warnings treated as errors.
- Promoted QUAL-01 and PIPE-01 from planned metadata to existing deterministic evidence after proving their owner, selector, alias, and workflow chain.

## Task Commits

1. **Task 1 RED: Define failing quality baseline contract** — `3392919` (test)
2. **Task 1 GREEN: Publish repository quality baseline** — `47694f0` (feat)
3. **Task 2 RED: Characterize malformed baseline records** — `cacfac7` (test)
4. **Task 2 GREEN: Enforce fail-closed baseline parsing** — `46bed16` (feat)
5. **Deviation: Capture measured governance gate failure** — `6437b0e` (fix)
6. **Deviation RED: Require completed baseline evidence owners** — `0ed41d7` (test)
7. **Deviation GREEN: Promote baseline evidence owners** — `4e33ca1` (feat)

## Files Created/Modified

- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — Dated quality ledger, CI snapshot, remote boundary, and security/compliance breadcrumbs.
- `test/governance/milestone_scope_test.exs` — Structural contract, pure parsing/validation helpers, and isolated malformed controls.
- `mix.exs` — Fresh-process `ci.evidence` ownership for both Phase 73 contract files.
- `test/support/adoption_evidence.ex` — Existing QUAL-01 and PIPE-01 evidence rows on the proven governance chain.
- `test/adoption/evidence_contract_test.exs` — Synthetic repository fixture carrying both existing contract owners.
- `.planning/WINDOWS.md` — Open cross-phase record for the measured incomplete-phase vocabulary policy false positive.

## Decisions Made

- Kept all baseline findings inventory-only except Phase 73's own evidence wiring; routed work remains owned by the target phase named in each row.
- Classified missing live `fleet-proxy-e2e` protection as HIGH while documenting the exact owner-approved Phase 79 repair and read-back sequence without mutating GitHub.
- Preserved intentional security duplication, including fresh suite processes and standalone GATE-02, until Phase 78 has multiple-run measurements.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Captured the measured governance gate failure**

- **Found during:** Overall verification after Task 2
- **Issue:** The wave context and fresh repository test run showed one known incomplete-phase vocabulary-policy failure across four archival Phase 73 planning artifacts. Omitting that adverse state would violate the baseline's truthful-inventory contract.
- **Fix:** Added stable finding `QUAL-73-006`, made its presence executable in the governance contract, routed refinement to Phase 77, and recorded broken-windows entry 5. The existing documentation gate and planning artifacts were not changed.
- **Files modified:** `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md`, `test/governance/milestone_scope_test.exs`, `.planning/WINDOWS.md`
- **Commit:** `6437b0e`

**2. [Rule 2 - Missing Critical Functionality] Promoted completed requirements to existing deterministic evidence**

- **Found during:** Post-state verification after requirements completion
- **Issue:** QUAL-01 and PIPE-01 were checked complete but their Plan 01 evidence rows remained planned, contradicting the deterministic mandatory ownership success criterion.
- **Fix:** Added failing owner-chain coverage, promoted exactly those two rows to existing `ci.evidence` owners, and retained every later requirement as planned.
- **Files modified:** `test/governance/milestone_scope_test.exs`, `test/support/adoption_evidence.ex`
- **Commits:** `0ed41d7`, `4e33ca1`

**3. [Rule 3 - Blocking Issue] Extended the synthetic repository with the new governance owner**

- **Found during:** Verification of the ownership promotion
- **Issue:** The Plan 01 repository fixture copied only the adoption contract, so repository-chain validation correctly rejected the newly existing governance owner as missing.
- **Fix:** Copied the governance contract into the fixture's isolated `test/governance` path.
- **Files modified:** `test/adoption/evidence_contract_test.exs`
- **Commit:** `4e33ca1`

## Issues Encountered

- `mix ci.evidence` passes with 17 tests and 0 failures, and `mix format --check-formatted` exits 0.
- The repository-wide test run and focused reproduction retain one out-of-scope failure in `Relyra.Docs.DemoGuideDriftTest`: the incomplete-phase vocabulary policy treats quoted or archival examples in four Phase 73 planning artifacts as executable acceptance markers. This is finding `QUAL-73-006`, routed to Phase 77 and recorded in `.planning/WINDOWS.md`.
- Root test discovery still reports the four golden-fixture pattern warnings inventoried as `QUAL-73-004`; those remain Phase 77 work.

## Known Stubs

None. Empty and malformed values appear only inside negative contract controls and cannot pass baseline validation.

## Threat Review

No runtime trust surface changed. The contract rejects copied assertion XML, certificates, credential headers, cookies, and secret assignments from CI evidence. Existing configured-certificate trust, single-parser, raw-input guard, cryptographic verification, audit co-commit, replay protection, and fresh security-suite invariants remain unchanged.

## User Setup Required

None. Live GitHub state was not mutated, and automated acceptance is network-independent.

## Next Phase Readiness

Plan 73-03 can consume the stable finding IDs and governance vocabulary. Phase 74 owns the package-boundary blocker; Phases 77 and 78 own craftsmanship and CI measurement; Phase 79 owns the exact remote protection repair behind explicit approval.

## Self-Check: PASSED

All implementation files, this summary, and all seven task/deviation commits were found.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
