---
phase: 30-adversarial-crypto-assurance
plan: 03
subsystem: testing
tags: [xmldsig, security-corpus, conformance, canonicalization, saml]

# Dependency graph
requires:
  - phase: 28-saxy-c14n-foundation
    provides: pure-BEAM exclusive-C14N seam whose canonicalize-only branch fails closed with :canonicalization_failed on an incomplete handle
  - phase: 29-cryptographic-xmldsig-verification
    provides: the :digest_mismatch crypto proof path (Signature.verify/4) that the complementary adversarial_crypto suite (Plan 02) exercises
provides:
  - c14n-differential REJECTION row (c14n-differential-rejection-002) wired into priv/security_corpus.json + the conformance manifest
  - regenerated CONFORMANCE.md keeping the ci.conformance drift gate green (CVE-REG-01 fixtures pinned 7 -> 8)
affects: [30-02, 31-disclosure, ci.security, conformance-drift-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fixture-as-source-of-truth: every corpus row carries provenance/requirement_ids/family/source_ref; CONFORMANCE.md is generated from the manifest and byte-for-byte drift-checked"
    - "Corpus routing discipline: a parser_differential_and_c14n row asserts :canonicalization_failed (canonicalize-only branch), NOT :digest_mismatch (which the JSON evaluator never reaches)"

key-files:
  created: []
  modified:
    - priv/security_corpus.json
    - CONFORMANCE.md

key-decisions:
  - "The JSON corpus row asserts :canonicalization_failed (mirrors c14n-differential-001) — Pitfall 1: the evaluate_fixture/1 parser_differential_and_c14n branch runs parse_safely -> canonicalize only and never reaches Signature.verify/4, so a :digest_mismatch row would fail the manifest-to-error-type test. The :digest_mismatch crypto proof lives in the adversarial_crypto suite (Plan 02, ASSUR-01)."
  - "Distinct assertion ID assertion-c14n-diff used to avoid duplicate-ID collisions with other corpus rows."
  - "requirement_ids carries both CVE-REG-01 and ASSUR-01 to trace the row to this phase."

patterns-established:
  - "Pattern 1: c14n-differential REJECTION row mirrors the existing c14n-differential-001 analog (same class, same expected_error_type, same fail-closed mechanism)"
  - "Pattern 2: regenerate-then-drift-check (mix relyra.conformance, then mix relyra.conformance --check) after any security_corpus row change"

requirements-completed: [ASSUR-01]

# Metrics
duration: 8min
completed: 2026-05-24
---

# Phase 30 Plan 03: c14n-differential corpus rejection + conformance regen Summary

**Added the c14n-differential REJECTION row (`c14n-differential-rejection-002`, `:canonicalization_failed`) to the static security corpus and regenerated CONFORMANCE.md so the conformance drift gate stays green — the corpus_gate + conformance-manifest leg of ASSUR-01.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-24T18:24Z
- **Completed:** 2026-05-24T18:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- New `c14n-differential-rejection-002` row appended to `priv/security_corpus.json` asserting `:canonicalization_failed` (NOT `:digest_mismatch` — Pitfall 1), with full provenance / requirement_ids / family / source_ref.
- The row routes through the `parser_differential_and_c14n` canonicalize-only evaluator branch and fails closed exactly like the existing `c14n-differential-001` analog; the corpus security suite stays green (7 tests, 0 failures).
- `CONFORMANCE.md` regenerated via `mix relyra.conformance`: CVE-REG-01 fixtures pinned 7 -> 8, the new row appears in the CVE-REG-01 Regression Coverage table, and `mix relyra.conformance --check` reports "matches generated manifest state" (no drift).

## Task Commits

Each task was committed atomically:

1. **Task 1: Append the c14n-differential REJECTION row to priv/security_corpus.json (D-09)** - `c7ec6a2` (feat)
2. **Task 2: Regenerate CONFORMANCE.md and verify the drift gate (D-09)** - `2ed41c1` (docs)

## Files Created/Modified
- `priv/security_corpus.json` - added the `c14n-differential-rejection-002` element (8th row) under class `parser_differential_and_c14n`, `expected_error_type: canonicalization_failed`, requirement_ids `[CVE-REG-01, ASSUR-01]`, distinct assertion ID `assertion-c14n-diff`.
- `CONFORMANCE.md` - regenerated (generator-driven, not hand-edited): `fixtures pinned: 8` and a new CVE-REG-01 Regression Coverage table row.

## Decisions Made
- **Asserted `:canonicalization_failed`, not `:digest_mismatch`** (Pitfall 1 / T-30-11, HIGHEST RISK). The JSON `evaluate_fixture/1` branch for `parser_differential_and_c14n` (`corpus_security_test.exs:186-189`) runs `parse_safely -> canonicalize` and never calls `Signature.verify/4`, so a `:digest_mismatch` row would fail the manifest-to-error-type test. The complementary `:digest_mismatch` crypto proof belongs to the adversarial_crypto suite (Plan 02).
- **Distinct assertion ID `assertion-c14n-diff`** to avoid duplicate-ID collisions with other corpus rows.
- **`requirement_ids: [CVE-REG-01, ASSUR-01]`** — multiple IDs allowed; ASSUR-01 traces the row to this phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched locked dependencies in the fresh worktree**
- **Found during:** Task 1 (running the corpus security suite verification)
- **Issue:** The freshly-spawned worktree had no materialized `deps/` (saxy, ecto, etc.), so `mix test` aborted with "Unchecked dependencies for environment test ... run mix deps.get".
- **Fix:** Ran `mix deps.get`, which fetches exactly the versions pinned in the committed `mix.lock` (restoring vendored/locked deps — NOT installing a new or alternatively-named package, so the package-legitimacy checkpoint exclusion does not apply). The deps set and `mix.lock` are unchanged.
- **Files modified:** None committed (`deps/` is gitignored; `mix.lock` unchanged).
- **Verification:** `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` then ran green.
- **Committed in:** N/A (no source change; dependency materialization only).

---

**Total deviations:** 1 auto-fixed (1 blocking — dependency materialization, no source change).
**Impact on plan:** Necessary to run the verification gates in a fresh worktree. No scope creep; no new packages introduced; `mix.lock` untouched.

## Issues Encountered
None beyond the worktree dependency materialization noted above.

## Verification
- `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` -> 7 tests, 0 failures (manifest-to-error-type, provenance enforcement, and the parser_differential_and_c14n binary gate all green with the new row).
- `mix relyra.conformance --check` -> exit 0, "matches generated manifest state" (no drift; this is the FIRST step of `ci.security` via `ci.conformance`).
- JSON decode confirms the row: `expected_error_type: "canonicalization_failed"`, `class: "parser_differential_and_c14n"`, non-empty `family`/`provenance`/`source_ref`, `requirement_ids` includes `ASSUR-01`.

## Known Stubs
None.

## Threat Flags
None — no new security-relevant surface. The row exercises an existing fail-closed seam; the threat register entries T-30-11/12/13 are all mitigated (correct error type, drift gate green, full provenance present).

## Next Phase Readiness
- The corpus_gate + conformance-manifest leg of ASSUR-01 is satisfied and gated. The complementary `:digest_mismatch` crypto proof + `ci.security` alias wiring are owned by Plan 02 (adversarial_crypto suite + FakeIdP real signing).
- No blockers introduced. The orchestrator owns STATE.md / ROADMAP.md / REQUIREMENTS.md updates after the wave completes.

---
*Phase: 30-adversarial-crypto-assurance*
*Completed: 2026-05-24*
