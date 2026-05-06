<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. Routing & Information Architecture
**Decision**: The Metadata UI will live on a separate LiveView route (`/connections/:connection_id/metadata`) rather than as a tab within the main connection show view.
**Rationale**: Metadata import is an operator workflow surface with its own failure states, parsing lifecycle, and audit trail. Moving it to a dedicated route adheres to LiveView's "thin LiveViews" best practice, preventing the main `ConnectionsLive.Show` module from becoming bloated, while providing dedicated screen real estate for history tables and refresh logs.

2. Import UX Mode
**Decision**: Distinct panels for "Remote URL" and "Manual XML Import" driven by URL parameters (`?mode=xml` / `?mode=url`).
**Rationale**: Pasting XML and registering a URL represent fundamentally different mental models and server-side boundaries (in-memory parsing vs. ongoing trust relationship). URL-driven tabs keep failure domains isolated and align with the modern LiveView emphasis on putting view state in the URL.

3. Manual Refresh Behaviour
**Decision**: Use `assign_async` / `start_async` for in-band asynchronous network fetching.
**Rationale**: When triggering a manual URL refresh, we want to provide immediate, typed feedback without freezing the UI or the LiveView process. LiveView's `start_async` provides non-blocking operations while avoiding heavy external dependencies like Oban, aligning with the goal of being a lightweight library.

4. History Presentation (Audit Trail)
**Decision**: Render the 10 most recent metadata revisions using a LiveView Stream.
**Rationale**: Streams are the modern LiveView answer for lists. A 10-item stream provides the essential context (When did trust update? Was it successful?) with minimal server memory overhead. The active "last known good" state will be visually highlighted (using `Proof Teal`) to reinforce exactness and clarity.

### the agent's Discretion
None explicitly declared in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
None explicitly declared in CONTEXT.md.
</user_constraints>

# Phase 16: Metadata Management UI - Research

**Researched:** 2024-05
**Domain:** Phoenix LiveView, Metadata Ingestion, UI State
**Confidence:** HIGH

## Summary

This phase extracts the existing metadata operations (XML import, Source URL registration, and Manual Refresh) from `ConnectionsLive` into a dedicated LiveView component/route at `/connections/:connection_id/metadata`. The existing Relyra backend core (`Relyra.Metadata.Import`, `Relyra.Metadata.Refresh`, `Relyra.Ecto.MetadataSource`, and `Relyra.Ecto.MetadataApply`) is complete and tested; the UI work focuses on leveraging Phoenix LiveView 1.1+ conventions.

**Primary recommendation:** Implement a new `Relyra.LiveAdmin.MetadataLive` that handles `?mode=xml` and `?mode=url`, using `start_async/3` to manage non-blocking manual metadata refreshes, and rendering `MetadataRevision` history using LiveView streams.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| State & Routing | LiveView Router / Browser | — | `?mode=` controls UI panels without holding server state. |
| Non-blocking Refresh | LiveView | `Relyra.Metadata` | `start_async` allows the UI process to stay responsive while network fetch occurs. |
| Parsing & Auditing | `Relyra.Metadata` | Ecto | Trust changes and parsing failures are logged deeply in the core (already implemented). |
| History Rendering | LiveView | — | LiveView Streams handle the list of the 10 most recent metadata revisions. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 1.0 (implicitly loaded) | Server-driven UI | Core UI layer for Relyra Admin |
| Req | ~> 0.5 | HTTP fetching | Replaces hackney/HTTPoison; used in `Metadata.Refresh` |
| Ecto | ~> 3.10 | Database abstractions | Auditing and persistence of sources/revisions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `start_async` | Oban | Oban is heavy; `start_async` keeps the library dependency-light. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/relyra/live_admin/
├── metadata_live.ex      # New dedicated LiveView for Metadata management
├── components/           # Existing shared LiveView components
```

### Pattern 1: URL-driven View State
**What:** Use the `handle_params` callback to switch between XML and URL modes, maintaining state in the URL so it can be reloaded safely.
**When to use:** Managing tabs or distinct panels in a LiveView without bloated socket assigns.
**Example:**
```elixir
def handle_params(params, _uri, socket) do
  mode = Map.get(params, "mode", "xml")
  {:noreply, assign(socket, :mode, mode)}
end
```

### Pattern 2: Asynchronous Refresh with `start_async`
**What:** Performing network operations without blocking the LiveView process.
**When to use:** During the `?mode=url` metadata refresh.
**Example:**
```elixir
def handle_event("refresh_metadata", _params, socket) do
  opts = [repo: socket.assigns.relyra_admin_repo, req: socket.assigns.relyra_admin_req]
  socket =
    socket
    |> assign(:refresh_status, :loading)
    |> start_async(:metadata_refresh, fn -> 
         Relyra.Metadata.Refresh.refresh(socket.assigns.connection_id, opts)
       end)
  {:noreply, socket}
end

def handle_async(:metadata_refresh, {:ok, {:ok, _revision}}, socket) do
  {:noreply, 
   socket
   |> put_flash(:info, "Metadata refreshed successfully.")
   |> assign(:refresh_status, :success)}
end

def handle_async(:metadata_refresh, {:ok, {:error, error}}, socket) do
  {:noreply, 
   socket
   |> put_flash(:error, "Refresh failed: #{error.message}")
   |> assign(:refresh_status, :error)}
end
```

### Pattern 3: Rendering History via Stream
**What:** Limit history memory footprint by streaming Ecto rows.
**Example:**
```elixir
# in handle_params or mount after fetching revisions:
socket = stream(socket, :metadata_revisions, Enum.take(revisions, 10))
```

### Anti-Patterns to Avoid
- **Blocking `handle_event`:** Never call `Relyra.Metadata.Refresh.refresh` synchronously in `handle_event` because network delays will kill the UI connection and cause a crash/timeout in the LiveView.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Fetching | `gen_tcp` / `:httpc` | `Req` | Handles SSL, redirects, and retries natively. `Relyra.Metadata.Refresh` already uses `Req`. |
| State Management for Tabs | Explicit assigns for UI state | URL parameters (`?mode=`) | Keeps the back button working and the LiveView stateless where possible. |
| Background tasks | `Task.async` | `start_async/assign_async` | Native LiveView lifecycle integration (automatically handles crashes and cleanup). |

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified beyond the Elixir/Phoenix toolchain already assumed).

## Common Pitfalls

### Pitfall 1: Leaving Dead Code in `ConnectionsLive`
**What goes wrong:** The `import_metadata`, `register_metadata_source`, and `refresh_metadata` events exist in `ConnectionsLive`. If they aren't removed, they might be triggered by rogue forms or old components.
**Why it happens:** Partial refactoring.
**How to avoid:** Explicitly rip out those events from `lib/relyra/live_admin/connections_live.ex` when migrating functionality to `MetadataLive`.

### Pitfall 2: Async Crash Loop
**What goes wrong:** Network exceptions bubble up from `Req` unhandled in `start_async`.
**Why it happens:** LiveView monitors the async task. If it crashes, the LiveView crashes.
**How to avoid:** `Relyra.Metadata.Refresh` internally catches exceptions and normalizes them to `{:error, %Relyra.Error{}}`. Verify this is happening and handle the tuple match safely in `handle_async`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MDUI-01 | View routes to /connections/:id/metadata and toggles XML/URL | unit/integration | `mix test test/phoenix/live_admin_metadata_test.exs` | ❌ Wave 0 |
| MDUI-02 | Async refresh does not block UI and returns status | integration | `mix test test/phoenix/live_admin_metadata_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/phoenix/live_admin_metadata_test.exs` — covers the new LiveView route.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Relies on LiveAdmin pipeline controls |
| V4 Access Control | yes | LiveAdmin scope bindings |
| V5 Input Validation | yes | Ecto Changeset validations in `MetadataSource` and core parsing rules |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CSRF | Spoofing | Phoenix native CSRF protection for LiveView connections |
| SSRF (via Source URL) | Tampering | Ecto Changeset limits URLs to HTTPS. Network layer restricts local ranges (handled outside this phase, typically in Req config/Proxies) |

## Sources

### Primary (HIGH confidence)
- `16-CONTEXT.md` - Confirms tabs, URLs, `start_async`, routing path.
- Codebase inspection (`lib/relyra/live_admin/connections_live.ex`, `lib/relyra/metadata/import.ex`, `lib/relyra/metadata/refresh.ex`) - Proves backend mechanisms already exist and return specific tuples.
- `lib/relyra/live_admin/query.ex` - Demonstrates how metadata revisions are extracted efficiently via Ecto.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Phoenix/LiveView norms.
- Architecture: HIGH - Dictated strongly by CONTEXT.md and Elixir best practices.
- Pitfalls: HIGH - Known risk of leaving old `handle_event` clauses in the main Connections view.

**Research date:** 2024-05
**Valid until:** 2024-11
