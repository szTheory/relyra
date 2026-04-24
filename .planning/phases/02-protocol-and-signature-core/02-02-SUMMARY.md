---
phase: 02-protocol-and-signature-core
plan: 02-02
subsystem: security
tags: [xmldsig, signature, trust-path, xml, elixir]
requires:
  - phase: 02-protocol-and-signature-core
    provides: AuthnRequest/binding primitives and opaque RelayState contract from 02-01
provides:
  - Strict algorithm policy with SHA-256+ defaults and typed SHA-1 override expiry failures
  - Signed-node trust binding that only succeeds with exactly one verified candidate
  - KeyInfo trust-elevation, duplicate XML ID, and ambiguity rejection paths with typed errors
affects: [02-03, phase-03-behaviour-contracts-and-stores]
tech-stack:
  added: []
  patterns:
    - Signature verification trusts configured certificates only
    - Signed node consumption is bound to a single verified candidate
    - SHA-1 support requires explicit reasoned and non-expired override
key-files:
  created:
    - lib/relyra/security/algorithm_policy.ex
    - lib/relyra/security/signature.ex
    - lib/relyra/security/signed_node.ex
    - test/fixtures/security/signature/manifest.json
    - test/security/signature_policy_test.exs
    - test/security/signed_node_binding_test.exs
  modified:
    - lib/relyra/security/algorithm_policy.ex
    - lib/relyra/security/signature.ex
    - test/security/signed_node_binding_test.exs
key-decisions:
  - "Relyra.Security.Signature.verify/4 rejects document KeyInfo trust elevation with :untrusted_certificate and reason :document_keyinfo_forbidden."
  - "Verification now hard-fails duplicate IDs and requires exactly one signed candidate before returning success."
  - "Algorithm policy errors are typed as :deprecated_algorithm or :legacy_algorithm_override_expired, preserving deterministic trust behavior."
patterns-established:
  - "Signature trust failures include connection_id metadata and omit raw XML payloads."
  - "Threat classes for signature policy and node binding are tracked via manifest fixtures."
requirements-completed: [SEC-02, SEC-03, SEC-04, SEC-05]
duration: 3 min
completed: 2026-04-24
---

# Phase 2 Plan 02: Implement signature verification, signed-node binding, and algorithm policy Summary

**Shipped strict signature trust-core enforcement with configured-cert trust roots, single-node binding guarantees, duplicate ID rejection, and SHA-256+ algorithm policy controls.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-24T15:52:08Z
- **Completed:** 2026-04-24T15:55:11Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added `Relyra.Security.AlgorithmPolicy` with SHA-256/384/512 allowlists for signature and digest methods.
- Added `Relyra.Security.Signature.verify/4` that rejects empty trust roots, KeyInfo trust promotion, duplicate IDs, and signed-node ambiguity.
- Added `%Relyra.Security.SignedNode{}` as the consumed verified-node contract.
- Added signature threat manifest and focused tests covering SHA-1 override semantics plus signed-node trust behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Algorithm policy module** - `88d43db` (feat)
2. **Task 2: Signature verification + signed-node binding** - `2aeba97` (feat)
3. **Task 3: Signature fixtures and tests** - `0a8afb4` (test)
4. **Verification deviation fix** - `ff0b471` (fix)

**Plan metadata:** `(pending in docs commit)`

## Files Created/Modified
- `lib/relyra/security/algorithm_policy.ex` - strict SHA-256+ policy defaults and SHA-1 override expiry enforcement.
- `lib/relyra/security/signature.ex` - ordered signature trust evaluation with typed failures and single-node success path.
- `lib/relyra/security/signed_node.ex` - verified signed-node struct contract used by protocol consumers.
- `test/fixtures/security/signature/manifest.json` - SEC-02/03/04/05 threat classes and expected errors.
- `test/security/signature_policy_test.exs` - SHA-1 default rejection and override window behavior tests.
- `test/security/signed_node_binding_test.exs` - KeyInfo/duplicate/ambiguity rejections and exact-node success assertion.

## Decisions Made
- Kept signature trust source restricted to configured cert input and treated document `KeyInfo` as untrusted metadata only.
- Encoded duplicate XML ID and candidate-count checks before any signed-node success return.
- Preserved deterministic `%Relyra.Error{}` atom behavior for all new trust rejections.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification Blocker] Formatter gate failure during plan verification**
- **Found during:** Plan-level verification
- **Issue:** `mix format --check-formatted` failed for new signature policy/binding files.
- **Fix:** Ran formatter and re-validated full plan verification suite.
- **Files modified:** `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/security/signature.ex`, `test/security/signed_node_binding_test.exs`
- **Verification:** `mix format --check-formatted`, `mix compile --warnings-as-errors`, targeted tests, `mix ci.security`
- **Committed in:** `ff0b471`

---

**Total deviations:** 1 auto-fixed (1 rule-1 verification blocker)
**Impact on plan:** Formatting-only correction required for verification gates; no behavioral scope change.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Signature trust core requirements (`SEC-02` to `SEC-05`) are covered by code and tests.
- Ready for `02-03` response/assertion validation pipeline implementation.

---
*Phase: 02-protocol-and-signature-core*  
*Completed: 2026-04-24*
