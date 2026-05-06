# Phase 16: Metadata management UI - Context

## Goal
Operators can onboard and maintain metadata sources through the admin UI without causing implicit trust changes.

## Depends on
Phase 15

## Requirements
- MDUI-01
- MDUI-02

## Success Criteria (what must be TRUE)
1. Operator can import metadata for a connection by pasting XML and gets typed success or failure feedback without leaving the page.
2. Operator can register or update a metadata source URL for a connection through the admin UI.
3. Operator can review metadata import history, including the current last-known-good state for the connection.
4. Operator can trigger a manual metadata refresh and the UI makes it clear that newly fetched trust material is not implicitly promoted.

## Architectural Decisions & Alignment

During the discussion phase, the following design decisions were explicitly locked in to ensure alignment with Phoenix LiveView 1.1+ best practices and the Relyra brand ("Enterprise SAML, calmly verified"):

### 1. Routing & Information Architecture
**Decision**: The Metadata UI will live on a separate LiveView route (`/connections/:connection_id/metadata`) rather than as a tab within the main connection show view.
**Rationale**: Metadata import is an operator workflow surface with its own failure states, parsing lifecycle, and audit trail. Moving it to a dedicated route adheres to LiveView's "thin LiveViews" best practice, preventing the main `ConnectionsLive.Show` module from becoming bloated, while providing dedicated screen real estate for history tables and refresh logs.

### 2. Import UX Mode
**Decision**: Distinct panels for "Remote URL" and "Manual XML Import" driven by URL parameters (`?mode=xml` / `?mode=url`).
**Rationale**: Pasting XML and registering a URL represent fundamentally different mental models and server-side boundaries (in-memory parsing vs. ongoing trust relationship). URL-driven tabs keep failure domains isolated and align with the modern LiveView emphasis on putting view state in the URL.

### 3. Manual Refresh Behaviour
**Decision**: Use `assign_async` / `start_async` for in-band asynchronous network fetching.
**Rationale**: When triggering a manual URL refresh, we want to provide immediate, typed feedback without freezing the UI or the LiveView process. LiveView's `start_async` provides non-blocking operations while avoiding heavy external dependencies like Oban, aligning with the goal of being a lightweight library.

### 4. History Presentation (Audit Trail)
**Decision**: Render the 10 most recent metadata revisions using a LiveView Stream.
**Rationale**: Streams are the modern LiveView answer for lists. A 10-item stream provides the essential context (When did trust update? Was it successful?) with minimal server memory overhead. The active "last known good" state will be visually highlighted (using `Proof Teal`) to reinforce exactness and clarity.