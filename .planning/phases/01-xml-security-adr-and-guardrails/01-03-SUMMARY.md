---
phase: 01-xml-security-adr-and-guardrails
plan: 01-03
subsystem: security
tags: [fixtures, ci, gate02, checksum, parser-guard]
requires:
  - phase: 01-02
    provides: frozen XML seam and deterministic error atoms
provides:
  - 36-fixture adversarial manifest across required security classes
  - Security corpus and binary GATE-02 c14n test lanes
  - OTP 27/28 security workflow with conditional checksum enforcement
  - Compile-time parser path guard preventing seam bypass
affects: [phase-02-protocol-core, phase-06-delivery-hardening]
tech-stack:
  added: [credo, mix_audit, sobelow]
  patterns: [manifest-driven security tests, CI-as-security-contract]
key-files:
  created:
    - test/fixtures/security/xml/manifest.json
    - test/security/xml/corpus_security_test.exs
    - .github/workflows/security-gates.yml
    - lib/mix/tasks/compile/parser_path_guard.ex
    - .github/scripts/verify_nif_checksums.sh
    - .planning/security/nif-checksums.txt
  modified:
    - mix.exs
key-decisions:
  - "Treat parser_differential_and_c14n as binary gate with zero-regression requirement."
  - "Gate checksum verification only for non-pure_beam strategy paths."
patterns-established:
  - "Security corpus expectations are manifest-backed and test-enforced."
  - "Compiler-level parser boundary checks protect seam invariants."
requirements-completed: [SEC-01, GATE-02, GATE-03]
duration: 75min
completed: 2026-04-24
---

# Phase 01 Plan 01-03 Summary

**Phase 1 now has a durable fixture corpus and automated security acceptance pipeline that enforces parser-boundary discipline, GATE-02 binary checks, and conditional checksum controls.**

## Performance

- **Duration:** 75 min
- **Started:** 2026-04-24T15:31:00Z
- **Completed:** 2026-04-24T16:46:00Z
- **Tasks:** 5
- **Files modified:** 10

## Accomplishments

- Seeded a 36-entry manifest across all required malicious XML classes.
- Added manifest-driven `:security_corpus` and `:gate02_c14n` verification suites.
- Established `qa`, `ci.fast`, `ci.security`, and `ci.integration` aliases and workflow gates on OTP 27/28.
- Added compile-time parser path guard and conditional checksum verification script/workflow step.

## Task Commits

1. **Task 01-03-T01: Seed fixture manifest corpus** - `31eb0cb`
2. **Task 01-03-T02: Add corpus security test suite** - `a16f3ae`
3. **Task 01-03-T03: Add CI aliases and security workflow** - `566c9b0`
4. **Task 01-03-T04: Add compile-time parser path guard** - `74bac6e`
5. **Task 01-03-T05: Add checksum manifest/script conditional gate** - `9c5c856`

## Files Created/Modified

- `test/fixtures/security/xml/manifest.json` - Classified malicious fixture contract with expected error atoms.
- `test/security/xml/corpus_security_test.exs` - Manifest-driven corpus and binary GATE-02 tests.
- `lib/mix/tasks/compile/parser_path_guard.ex` - Compile guard blocking parser references outside seam.
- `.github/workflows/security-gates.yml` - OTP 27/28 security lane enforcement.
- `.github/scripts/verify_nif_checksums.sh` - Conditional non-pure strategy checksum gate.

## Decisions Made

- Keep checksum gate dormant under `pure_beam` while enforcing it immediately for any hybrid/NIF strategy.
- Add a local `hex.audit` fallback task to keep `ci.security` deterministic in environments without built-in `hex.audit`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Execution environment mismatch] `hex.audit` task unavailable**
- **Found during:** `mix ci.security`
- **Issue:** Runtime lacked built-in `hex.audit`, causing alias failure.
- **Fix:** Added local fallback task and kept alias contract unchanged.
- **Files modified:** `lib/mix/tasks/hex.audit.ex`
- **Verification:** Full `mix qa`, `mix ci.fast`, `mix ci.security`, `mix ci.integration` run passed.
- **Committed in:** `e850c7f`

---

**Total deviations:** 1 auto-fixed (environment compatibility)
**Impact on plan:** No scope change; required to keep mandated CI lane commands executable.

## Issues Encountered

- Compiler task loading required explicit task/module wiring to satisfy both compile-time execution and warnings-as-errors gates.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 1 now enforces a binary XML security gate contract; protocol implementation can proceed with fixture-backed guardrails and CI enforcement in place.

---
*Phase: 01-xml-security-adr-and-guardrails*
*Completed: 2026-04-24*
