---
phase: 31-disclosure-and-docs-honesty
plan: 01
subsystem: docs
tags: [security, disclosure, reviewer-docs, findings-ledger]
key-files:
  created: []
  modified:
    - docs/security_boundary.md
    - SECURITY_REVIEW.md
    - docs/security_findings.md
requirements-completed: [DISC-01]
metrics:
  completed: 2026-05-24
---

# Phase 31 Plan 01: Reviewer-doc honesty and findings ledger Summary

Corrected the reviewer-facing security docs to describe the real post-fix XMLDSig primitive, replaced the placeholder findings ledger row with the resolved Critical `RELYRA-2026-001` record, and kept the generated evidence path untouched because its claims were already accurate.

## Accomplishments

- Rewrote `docs/security_boundary.md` and `SECURITY_REVIEW.md` so they now name `:public_key.verify` over exclusive-C14N canonicalized `SignedInfo`, the configured IdP certificate trust source, and the constant-time `DigestValue` recompute on both `verify/4` and `verify_metadata_root/4`.
- Removed the contradictory zero-findings language from `SECURITY_REVIEW.md` while preserving the `Findings Ledger` / `docs/security_findings.md` cross-reference required by `mix ci.security`.
- Replaced the `none yet` placeholder in `docs/security_findings.md` with a valid 8-column Critical `RELYRA-2026-001` ledger row citing `test/security/xml/adversarial_crypto_test.exs` and `test/security/ci_gate_integrity_test.exs`.
- Inspected `SECURITY_REVIEW_EVIDENCE.md` and `lib/mix/tasks/relyra.security_review.ex`; neither overstated verification, so both were left untouched.

## Task Commits

1. **Task 1: Correct the reviewer docs to the real primitive** - `57f083e` (`docs(31-01): correct reviewer trust-boundary language`)
2. **Task 2: Replace the placeholder ledger row with `RELYRA-2026-001`** - `c93b7ef` (`docs(31-01): record RELYRA-2026-001 in findings ledger`)
3. **Task 3: Inspect generated evidence and run the full `ci.security` lane** - no source diff required; verification-only step

## Verification

- `mix cmd test -f SECURITY_REVIEW.md`
- `mix cmd test -f docs/security_boundary.md`
- `mix cmd grep -nE "docs/security_findings.md|Findings Ledger" SECURITY_REVIEW.md`
- `mix compile --warnings-as-errors`
- `mix relyra.security_review --check`
- `mix ci.security`

## Inspect-Then-Decide Outcome

Left `SECURITY_REVIEW_EVIDENCE.md` and `lib/mix/tasks/relyra.security_review.ex` untouched. The evidence packet already described strict-default policy, `KeyInfo` trust rejection, RelayState, and audit/escape-hatch claims without overstating the cryptographic verification primitive.

## Deviations from Plan

None.

## Self-Check: PASSED

- FOUND: `docs/security_boundary.md`
- FOUND: `SECURITY_REVIEW.md`
- FOUND: `docs/security_findings.md`
- FOUND: `.planning/phases/31-disclosure-and-docs-honesty/31-01-SUMMARY.md`
- FOUND commit `57f083e`
- FOUND commit `c93b7ef`

---
*Phase: 31-disclosure-and-docs-honesty*
*Completed: 2026-05-24*
