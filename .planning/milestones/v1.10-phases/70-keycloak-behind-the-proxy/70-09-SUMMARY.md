---
phase: 70-keycloak-behind-the-proxy
plan: "09"
subsystem: demo-provisioning
tags: [keycloak, ecto, transactions, audit, saml-identity]
dependency_graph:
  requires: [70-08]
  provides: [atomic Keycloak identity-map audit and enablement]
  affects: [keycloak-provisioning, KC-01, audit-invariant]
tech_stack:
  added: []
  patterns: [outer host-owned Ecto transaction, correlation-scoped mapping audit, injectable failure seams]
key_files:
  created: []
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
    - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
decisions:
  - "Sarah's host-owned identity, its attributed mapping audit, and connection enablement commit as one final transaction."
metrics:
  duration: "~10 minutes"
  completed: "2026-08-26"
status: complete
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: "Keycloak provisioning co-commits Sarah's exact public-issuer identity and attributed mapping audit before enablement."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs#initial provisioning is audited and a byte-identical descriptor is unchanged"
        status: pass
    human_judgment: false
  - id: D2
    description: "Audit and enablement failures leave no Keycloak mapping residue and retries remain exact."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
---

# Phase 70 Plan 09: Atomic Keycloak identity finalization Summary

Sarah's durable Keycloak identity, matching attributed mapping audit event, and final connection enablement now share one fail-closed LedgerLoop transaction.

## Completed Tasks

1. Added RED regressions for attributed mapping evidence, forced audit failure, forced enablement failure, rollback, retry, and unchanged reprovisioning.
2. Replaced the standalone Sarah identity insert and later enable call with a locked, outer Repo transaction that writes the identity and mapping audit before enabling the connection.

## Verification

- `cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs --warnings-as-errors` — passed (11 tests).
- Commit hooks ran `mix format --check-formatted` successfully for both task commits.
- Standalone `mix format --check-formatted` remains non-green because pre-existing unrelated demo templates are unformatted; no unrelated files were changed.

## TDD Gate Compliance

- RED: `641d9fc` added the regression coverage; it failed on the absent mapping audit and missing injection seams.
- GREEN: `5d33934` implemented transactional finalization and made all focused regressions pass.

## Task Commits

1. `641d9fc` — `test(70-09): add atomic Keycloak finalization regressions`
2. `5d33934` — `feat(70-09): atomically finalize Keycloak identity mapping`

## Files Modified

- `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` — performs a locked outer transaction, appends the mapping event through `AuditWriter`, and invokes final enablement before commit.
- `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — proves success attribution, both rollback branches, retry, and no-op idempotency.

## Decisions Made

- The mapping event contains bounded issuer, subject, and host user references only; no descriptor XML, assertion XML, PEM, credentials, or key material enter the audit summary.
- Injectable audit-writer and enablement functions are demo-private test seams whose production defaults remain `AuditWriter.append_event/2` and `Connections.enable/2`.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed both planned implementation and test files exist.
- Confirmed task commits `641d9fc` and `5d33934` exist.
