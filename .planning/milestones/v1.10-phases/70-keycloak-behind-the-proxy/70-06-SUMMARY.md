---
phase: 70-keycloak-behind-the-proxy
plan: "06"
subsystem: demo-keycloak-provisioning
tags: [keycloak, saml, metadata, audited-trust, tdd]
requires:
  - phase: 70-keycloak-behind-the-proxy
    plan: "05"
    provides: Keycloak proxy proof and regression gates
provides:
  - Single guarded descriptor parse and canonical metadata candidate for Keycloak provisioning
  - Candidate-derived audited metadata persistence and certificate lifecycle reconciliation
affects: [70-07, 71-launcher-dx, 72-docker-dx-docs]
tech-stack:
  added: []
  patterns: [single-candidate metadata preflight, audited metadata apply, parser-count regression]
key-files:
  created: []
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
    - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
decisions:
  - "A fetched Keycloak descriptor crosses the guarded parser seam once; its canonical candidate supplies preflight comparisons, metadata persistence, and certificate fingerprints."
  - "The demo provisioner keeps the existing disable-before-change and enable-last choreography while applying trust through MetadataApply and CertificateInventory."
metrics:
  duration: 6min
  completed: 2026-08-26
  tasks_completed: 1
  files: 2
status: complete
---

# Phase 70 Plan 06: Canonical Keycloak Descriptor Trust Summary

**Keycloak descriptor bootstrap now parses once into a canonical metadata candidate that drives issuer validation, idempotency checks, audited persistence, and certificate activation.**

## Accomplishments

- Added a descriptor-parser injection seam and count assertions for both a successful provision and an unchanged retry.
- Replaced the post-preflight raw-XML import with `MetadataApply.apply_revision/4`, using `Map.from_struct(candidate)`, descriptor-derived content hash, trust summary, and the existing audit context.
- Kept candidate-derived fingerprints for activation and stale-certificate retirement, plus existing disable-before-change and enable-last behavior.
- Added regressions for wrong public issuer rejection and for preventing reintroduction of `Import.import_xml/3` into the provisioner.

## Task Commits

1. **Task 1 RED: Prove canonical descriptor candidate path** — `affe2a9` (test)
2. **Task 1 GREEN: Apply the Keycloak descriptor candidate once** — `d933cba` (feat)

## Verification

- `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` — passed (9 tests).
- `mix ci.security` — passed.
- `mix format --check-formatted` — passed.

## Decisions Made

- The parser injection is demo-private and defaults to `Relyra.Metadata.Parser.parse/1`; it gives executable proof that each `provision!/1` invocation performs exactly one guarded parse.
- Metadata persistence receives the already-built candidate rather than reparsing descriptor XML, so persisted issuer, SSO URL, and certificate inventory cannot diverge from preflight facts.

## Deviations from Plan

### Commit Scope Incident

**1. [Process deviation] Pre-existing staged files were unintentionally included in the RED commit**
- **Found during:** Task 1 RED commit
- **Issue:** `demo/ledger_loop/Dockerfile.dev` and `demo/ledger_loop/config/dev.exs` were already staged by concurrent work and were included in `affe2a9` despite file-specific staging of the test.
- **Resolution:** Preserved the shared history unchanged; did not amend, revert, or modify either unrelated file. All remaining commits were explicitly staged and inspected for plan-owned paths only.
- **Commit:** `affe2a9`

**Total deviations:** 1 process deviation. The production trust-path implementation remains limited to the plan-owned provisioner and test files.

## Known Stubs

None.

## Self-Check: PASSED

- Plan-owned provisioner and focused test files exist.
- RED/GREEN commits `affe2a9` and `d933cba` exist in git history.
- Focused tests, security suite, and formatting verification passed.
