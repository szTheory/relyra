# Phase 18: Mapping Editor & Audit Timeline Hardening - Validation Plan

## 1. Scope
This validation plan covers the hardening of the Relyra live admin mapping editor (transitioning from a raw JSON editor to a typed form) and the audit timeline (adding contextual inline expansion, robust filtering by connection/actor/event-type, and strict rollback verifications).

## 2. Test Boundaries
*   **LiveView Forms (`ConnectionsLive`, `ConnectionDetail`):** Validating the strictly typed `Ecto.Changeset` integration for attribute and group mapping modifications.
*   **UI Components:** Assuring "Active" badges, dynamic mapping rows (`inputs_for`), hidden diff summary row expansion, and audit filter forms render correctly.
*   **Transactions (`MappingCommands` & Audit Integrations):** Ensuring database rollbacks happen if the `AuditWriter.append_event` fails during a trust-state mutation.

## 3. Validation Objectives

### Objective 1: Mapping Form Hardening (MAP-01)
*   **Requirement:** Operator can edit mapping rules using a dynamic, strictly typed form and cannot submit arbitrary/invalid JSON.
*   **Strategy:** Provide invalid structural inputs to the new mapping form handlers and assert the changeset appropriately rejects the payloads. Add and remove rows dynamically, and submit a valid structure to verify persistence. Check that the UI correctly badges the active mapping revision.

### Objective 2: Audit Timeline Filtering (AUD-01)
*   **Requirement:** Operator can browse the audit ledger and filter by connection, actor, and event-type.
*   **Strategy:** Seed multiple audit records spanning different actors, event types, and connections. Interact with the LiveView filters, asserting the socket state correctly filters the displayed rows based on the filter combination without requiring a full page reload.

### Objective 3: Audit Rollback Safety (SAFE-01)
*   **Requirement:** Failed admin mutations result in a typed flash error, with trust-state cleanly rolled back.
*   **Strategy:** Introduce a mock or intentional database constraint failure at the `append_audit` step of a mapping edit transaction. Assert that the LiveView catches the error, renders the appropriate flash message, and critically, that the targeted database table (e.g., connection mappings) has not changed.

## 4. Test Strategy
*   **Unit Tests:** Will cover the newly introduced embedded schemas/changesets for the mapping forms to verify the casting rules are correct.
*   **Integration Tests (LiveView):** Will simulate browser interactions (mounting, form `phx-change`/`phx-submit`, row expansion via `JS.toggle`, and filter updates) ensuring the user experience matches the requirements.
*   **Failure Simulation:** Rely heavily on Ecto Sandbox capabilities and intentional failure injections (e.g., mocks or invalid inputs that bypass initial validation but fail in the DB) to test the strict transactional boundaries.

## 5. Success Criteria
*   [ ] LiveAdmin tests pass and demonstrate mapping updates no longer accept raw JSON text.
*   [ ] LiveAdmin tests demonstrate that audit filtering by connection, actor, and event-type successfully scopes the results.
*   [ ] LiveAdmin tests prove that simulating an audit write failure explicitly prevents the corresponding mapping mutation from committing to the database.
*   [ ] Code coverage for the new `ConnectionsLive` and `connection_detail` additions remains > 90%.