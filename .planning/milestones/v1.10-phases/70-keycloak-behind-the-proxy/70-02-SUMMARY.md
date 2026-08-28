---
phase: 70-keycloak-behind-the-proxy
plan: "02"
subsystem: demo-provisioning
tags: [keycloak, saml, ecto, metadata, certificate-rotation, integration-tests]
requires:
  - phase: 70-keycloak-behind-the-proxy
    plan: "01"
    provides: profile-scoped descriptor-derived Keycloak provisioner
provides:
  - Fail-closed audited Keycloak provisioning outcomes
  - Descriptor-fact idempotency and signing-key rotation reconciliation coverage
affects: [70-03, 70-04, 70-05, 71-launcher-dx, 72-docker-dx-docs]
tech-stack:
  added: []
  patterns: [descriptor-fact comparison, disable-before-trust-replacement, active-before-retire, resolver-state integration proof]
key-files:
  created:
    - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
decisions:
  - "An unchanged descriptor is recognized from issuer, SSO URL, active certificate fingerprints, enabled state, and Sarah's exact issuer/subject mapping before any trust mutation runs."
  - "For changed descriptor facts, the Keycloak connection is disabled before import, new signing trust is activated before older active trust is retired, and only then is login re-enabled."
metrics:
  duration: 18min
  completed: 2026-08-26
  tasks_completed: 2
  files: 2
status: complete
---

# Phase 70 Plan 02: Keycloak Provisioner Safety Summary

**Audited Keycloak descriptor reconciliation now fails closed, is mutation-free on identical input, and activates regenerated signing trust before returning login availability.**

## Accomplishments

- Added real-Repo coverage for one enabled Keycloak connection, Sarah's exact public issuer mapping, descriptor-derived active signing trust, and attributable connection/metadata/certificate audit evidence.
- Made provisioning return `{:ok, :unchanged}` without mutation commands when descriptor facts, active trust, and identity state already match.
- Made fetch, parse, apply, activation, and identity failures leave the Keycloak connection unavailable and create no LoginReceipt.
- Added a rotation proof that observes resolver rejection after disable, then verifies the new descriptor certificate in the resolver snapshot and a no-op retry.

## Task Commits

1. **Task 1 RED: Specify audited initial provisioning and unchanged-run idempotency** — `c464726` (test)
2. **Task 1 GREEN: Implement fail-closed idempotent provisioning** — `30625b1` (feat)
3. **Task 2 RED: Specify signing-key regeneration reconciliation** — `317b0ea` (test)
4. **Task 2 GREEN: Reconcile signing-key rotation before re-enable** — `23a7737` (feat)

## Verification

- `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` — passed (7 tests).
- Changed files across the task commits are limited to the demo-owned provisioner and its focused test; no `lib/relyra/**` or public API boundary changed.

## Decisions Made

- The provisioner parses descriptor facts before deciding whether to mutate, preserving audit-ledger stability for byte-identical retries.
- A changed descriptor always disables the persisted connection before metadata/certificate changes; resolver availability is restored only after active trust and Sarah mapping are complete.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture path] Corrected the focused test's certificate lookup and resolver snapshot assertion**
- **Found during:** Task 1 and Task 2
- **Issue:** The test initially resolved the demo certificate relative to the repository rather than its test directory, and treated resolver certificate PEMs as Ecto certificate structs.
- **Fix:** Resolved the fixture from `__DIR__` and compared resolver PEMs using the canonical DER SHA-256 fingerprint helper.
- **Files modified:** `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs`
- **Verification:** Focused seven-case suite passed.
- **Commits:** `30625b1`, `23a7737`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Test harness alignment only; production scope and trust boundaries remain unchanged.

## Known Stubs

None.

## Self-Check: PASSED

- Focused test and provisioner files exist.
- RED/GREEN commits `c464726`, `30625b1`, `317b0ea`, and `23a7737` exist.
- Plan-level focused verification passed.
