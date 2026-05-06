# Phase 18: Mapping editor + audit timeline hardening - Context

**Date:** 2026-05-06
**Phase:** 18-mapping-editor-audit-timeline-hardening
**Status:** Discussion Complete, Ready for Planning

## Goal
Operators can manage mapping rules and inspect the trust-change timeline while admin-triggered mutations remain audit-atomic.

## Decisions

### 1. Mapping UI Editor Approach
**Decision:** Build a strictly typed, dynamic LiveView form (`inputs_for`) for mapping rules instead of JSON textareas.
**Rationale:**
- Eliminates syntax errors entirely and aligns explicitly with schemas.
- Allows bounded dropdowns for known `@attribute_targets` and enforces validation per row, feeling safe and professional.
- Idiomatic for LiveView (`Phoenix.Component.inputs_for/1`) and prevents the classic SAML "eval in mapping" vulnerabilities seen in other identity tools.
- Aligns perfectly with "Enterprise SAML, calmly verified" by preventing operator typos that cause SSO outages.

### 2. Mapping Revision History
**Decision:** Explicitly badge the active mapping revision with a prominent "Active" or "Current" pill.
**Rationale:**
- Provides immediate, unambiguous clarity, significantly reducing cognitive load during incident response.
- Fails the principle of least surprise if missing, as operators need explicit confirmation of the exact state executing at runtime.
- Idiomatic Phoenix declarative UI handles this easily (`is_active={index == 0}`).
- Transparent audit trails require zero ambiguity.

### 3. Audit Ledger Detail Expansion
**Decision:** Implement expandable rows using `Phoenix.LiveView.JS` for the audit ledger details.
**Rationale:**
- Preserves timeline context, allowing operators to open multiple consecutive rows and visually diff the sequence of events.
- Modals are an anti-pattern for incident forensics because they disrupt spatial memory.
- Uses lightweight `JS.toggle` interaction to expand a hidden row directly beneath the audit event, rendering the `diff_summary` inside a `<pre><code>` block.
- Viewing the exact trust-state mutation inline with the overarching timeline is the pinnacle of operator-friendly DX.

### 4. Backend Tech Debt Status
**Decision:** The v0.2 tech debt regarding `MappingCommands.append_audit/8` is already resolved at the backend boundary.
**Rationale:**
- The source in `lib/relyra/ecto/mapping_commands.ex` already includes the explicit `rollback(repo, Error.new(...))` pattern inside its `with` statement.
- `lib/relyra/live_admin/connections_live.ex` captures this via `handle_reload_result` and renders it as a flash error.
- Only UI wiring/verification is required in this phase.

## Next Steps
Proceed to the Planning Phase (`/gsd-plan-phase 18`).