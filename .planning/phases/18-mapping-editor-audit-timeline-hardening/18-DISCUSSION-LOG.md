# Phase 18: Mapping editor + audit timeline hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-06
**Phase:** 18-mapping-editor-audit-timeline-hardening
**Mode:** assumptions
**Areas analyzed:** Mapping UI Editor Approach, Mapping Revision History, Audit Ledger Detail Expansion, Backend Tech Debt Status

## Assumptions Presented

### Mapping UI Editor Approach
- **Assumption:** We will build a structured graphical mapping editor instead of retaining the current raw JSON text areas.
  - **Why this way:** `lib/relyra/live_admin/components/connection_detail.ex` currently exposes `<textarea name="mapping[json]">` which requires operators to manually write list-of-maps JSON. Success criteria 1 demands the operator can "edit attribute and group mapping rules", which in a standard admin UI implies form fields with proper constraints, not raw JSON blobs.
  - **Alternatives:** 
    1. Keep the JSON `<textarea>` but add client-side JSON validation before submission.
    2. Build a fully dynamic LiveView form with "Add/Remove Rule" buttons and bounded dropdowns matching `@attribute_targets` from `lib/relyra/ecto/mapping_commands.ex`.
  - **If wrong:** Operators will continue to edit raw JSON strings, making syntax errors highly likely and violating the "manage mapping rules" UX expectation for an enterprise dashboard.
  - **Confidence:** Likely

### Mapping Revision History
- **Assumption:** The revision history table needs to visually distinguish the latest active mapping from historical logs, likely by tagging the most recent entry.
  - **Why this way:** `lib/relyra/live_admin/components/connection_detail.ex` currently lists `@detail.mapping_revisions` in a simple table without indicating which is active. Because `lib/relyra/ecto/mapping_commands.ex` overwrites rules in place and pushes a new `MappingRevision`, the most recent revision (returned first by `Query.get_connection_detail`) is the active one. Success criteria 2 specifically requires operators to "distinguish the current live mapping from historical entries".
  - **If wrong:** Operators will see a list of timestamps but won't clearly know which mapping configuration is actively executing at runtime.
  - **Confidence:** Confident

### Audit Ledger Detail Expansion
- **Assumption:** The audit timeline needs an interactive detail view (like an expandable row or modal) to display the redacted payload summaries.
  - **Why this way:** `lib/relyra/live_admin/components/connection_detail.ex` currently renders an audit table with only top-level metadata (`When`, `Domain`, `Action`, `Actor`, `Cause`). Success criteria 3 states the operator "sees only redaction-safe event details". `lib/relyra/ecto/audit_writer.ex` already enforces strict redaction via `@sensitive_keys` and generates `before_summary`, `after_summary`, and `diff_summary` fields, which simply need to be rendered into the LiveView.
  - **If wrong:** The audit ledger remains a shallow event log that doesn't actually show operators the trust-state data that changed.
  - **Confidence:** Confident

### Backend Tech Debt Status
- **Assumption:** The v0.2 tech debt regarding `MappingCommands.append_audit/8` is already resolved at the backend boundary and only needs its UI wiring verified.
  - **Why this way:** The source in `lib/relyra/ecto/mapping_commands.ex` already includes the explicit `rollback(repo, Error.new(...))` pattern inside its `with` statement (added via a Phase 16 ride-along commit). Furthermore, `lib/relyra/live_admin/connections_live.ex` captures this via `handle_reload_result` and renders it as a flash error. The core requirement is already complete.
  - **If wrong:** We might mistakenly attempt to re-implement a backend rollback mechanism that already works perfectly, expanding phase scope unnecessarily.
  - **Confidence:** Confident

## Corrections Made

No corrections yet.

## Deep Architectural Research & Recommendations

### 1. Mapping UI Editor Approach (Structured UI vs JSON textareas)

**Context:** The current mapping editor prototype exposes `<textarea>` fields where operators must type raw JSON arrays of objects.

**Pros/Cons/Tradeoffs:**
*   **Raw JSON Textarea:**
    *   *Pros:* Trivial to implement; allows rapid copy-pasting of whole configurations from dev to prod.
    *   *Cons:* Extremely high footgun potential. A misplaced comma or misspelled target attribute (`email` vs `mail`) breaks SSO for all users on that connection. Terrible developer ergonomics (DX) for the operator; fails the "enterprise-grade" expectation.
*   **Structured Graphical UI (Dynamic LiveView Form):**
    *   *Pros:* Eliminates syntax errors entirely; explicit schema alignment; allows bounded dropdowns for known `@attribute_targets`; enforces validation per row; feels safe and professional.
    *   *Cons:* Requires more complex LiveView state management (handling nested `inputs_for` for a list of rules) and slightly more effort to copy-paste configurations.

**Idiomatic Elixir/LiveView & Ecosystem Lessons:**
*   *Idiomatic LiveView:* The standard for dynamic lists of sub-forms in LiveView 1.1.x is `Phoenix.Component.inputs_for/1` coupled with Ecto schemaless changesets or embedded schemas. This allows adding/removing mapping rules smoothly without requiring custom JS.
*   *Ecosystem Lessons:* Enterprise identity tools like Okta, Auth0, and Keycloak provide highly structured, visual mapping builders. They *do not* ask administrators to write raw JSON because identity mapping is inherently risky. However, they sometimes offer an "Advanced/Expression" toggle. For Relyra, adhering to strict, typed UI dropdowns prevents the classic SAML "eval in mapping" vulnerabilities.

**Recommendation: Build a strictly typed, dynamic LiveView form.**
*   Implement a dynamic list of rules using `inputs_for`. Each row gets an "Add Rule" / "Remove" button.
*   Use a bounded `<select>` dropdown for the target attribute (populated directly from `lib/relyra/ecto/mapping_commands.ex`'s allowed targets) and a text input for the IdP source claim name.
*   Do *not* expose the JSON. The overarching `CFG-03` Metadata Import/Export feature already handles bulk config portability.
*   *Vision Alignment:* "Enterprise SAML, calmly verified" means the system protects the operator from making a typo that causes a 3 AM incident. Strict UI forms enforce strict schemas before they hit the database.

---

### 2. Mapping Revision History (Visual tagging of active vs historical)

**Context:** The current revision history lists timestamps of mapping changes, but does not clearly distinguish which configuration is executing at runtime.

**Pros/Cons/Tradeoffs:**
*   **Implicit Active (Status Quo):**
    *   *Pros:* Zero extra UI logic; relies on the implicit knowledge that the most recent row is active.
    *   *Cons:* Fails the principle of least surprise. During a live SSO outage, operators panic and need explicit confirmation of the system's exact state.
*   **Visual Tagging (e.g., "Active" badge):**
    *   *Pros:* Immediate, unambiguous clarity; drastically reduces cognitive load during incident response; aligns with modern deployment UIs.
    *   *Cons:* Requires a minimal amount of presentation logic (e.g., checking if the row is the first in the sorted list).

**Idiomatic Elixir/LiveView & Ecosystem Lessons:**
*   *Idiomatic LiveView:* Standard Phoenix declarative UI involves passing an `is_active={index == 0}` prop into a `<.revision_row>` functional component to toggle styling.
*   *Ecosystem Lessons:* Platforms like Vercel (Deployments), GitHub Actions, and Auth0 (Rules/Actions history) heavily rely on clear, green visual badges (e.g., "Current" or "Active") to separate the live state from history. Missing this context routinely leads operators to rollback to the wrong historical state.

**Recommendation: Explicitly badge the active mapping revision.**
*   Render a prominent "Active" or "Current" pill/badge next to the mapping revision that is actively resolving at runtime (the first record).
*   For historical revisions, provide a clear "View" action to inspect the mapping state at that specific time.
*   *Vision Alignment:* Transparent audit trails require zero ambiguity. An operator must be able to glance at the dashboard and know exactly what is running.

---

### 3. Audit Ledger Detail Expansion (Expandable rows/modals for redacted payloads)

**Context:** The audit table shows high-level event metadata (`Action`, `Actor`), but operators cannot currently see the diffs (`before_summary`, `after_summary`, `diff_summary`) generated by `Relyra.Ecto.AuditWriter` without raw SQL queries.

**Pros/Cons/Tradeoffs:**
*   **Modals:**
    *   *Pros:* Provides a large, focused canvas for rendering complex JSON diffs.
    *   *Cons:* Breaks timeline context. Incident response often involves comparing 3 or 4 sequential events; modals force operators to open, close, remember, and open the next one.
*   **Expandable Rows (Accordions):**
    *   *Pros:* Preserves timeline context; operators can open multiple consecutive rows and visually diff the sequence of events; feels lighter and more "native" to a log-centric view.
    *   *Cons:* Can make the table tall or visually noisy if many are expanded at once.

**Idiomatic Elixir/LiveView & Ecosystem Lessons:**
*   *Idiomatic LiveView:* Because the redacted summaries are already loaded in the connection detail query, this does not require a server roundtrip. The most idiomatic approach is using pure `Phoenix.LiveView.JS` (e.g., `phx-click={JS.toggle(to: "#details-#{audit.id}")}`) to toggle the visibility of a nested `<tr>` or `<div>` immediately below the row.
*   *Ecosystem Lessons:* Stripe's Developer Dashboard and GitHub's Organization Audit Log use expandable rows. Modals in audit logs are widely considered an anti-pattern for incident forensics because they disrupt spatial memory of the event sequence.

**Recommendation: Implement Expandable Rows using `Phoenix.LiveView.JS`.**
*   Use a lightweight `JS.toggle` interaction to expand a hidden row directly beneath the audit event.
*   Render the `diff_summary` (and `before`/`after` states if relevant) inside this expanded area using a `<pre><code>` block for readable, monospaced JSON formatting.
*   Avoid modals entirely for timeline forensics.
*   *Vision Alignment:* "Calmly verified" implies that tracing an issue is straightforward and context-rich. Viewing the exact trust-state mutation inline with the overarching timeline is the pinnacle of operator-friendly DX.