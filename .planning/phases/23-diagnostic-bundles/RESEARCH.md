<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Format:** Multi-file JSON Zip Archive containing logically separated `.json` files (`connections.json`, `certificates.json`, `metadata_revisions.json`, `store_metrics.json`). Uses Erlang's `:zip.create/3`.
- **Redaction:** Explicit Allow-List Maps (Deny-by-Default). Uses a dedicated module (`Relyra.Diagnostic.AllowList` or similar) to map Ecto structs to pure Elixir maps. Will NOT rely on `@derive {Jason.Encoder}`.
- **Inclusion Scope:** Include Configuration & Metrics, No Transient Data. Includes active Connections, CertificateInventory summaries, MetadataRevision pointers, and point-in-time metrics/counts. Excludes transient store payloads (raw XML, session identifiers).
- **Trigger Surface:** API (`Relyra.Diagnostic.create_bundle`) + Mix Task (`mix relyra.diagnostic`).
- **Audit Logs:** Bounded Inclusion with Hashed Correlation. Include bounded slice (500-1000) of `Relyra.Ecto.AuditEvent`. Strip `actor` entirely, hash `correlation_id`.
- **Zip Generation:** In-Memory Compilation (`[:memory]`). Core API returns `{:ok, zip_binary}`.
- **LiveView Admin UI Scope:** Include Controller Route & UI Button. Requires standard GET route for download backing the LiveView button.

### the agent's Discretion
None identified in the provided CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
None identified in the provided CONTEXT.md.
</user_constraints>

# Phase 23: Diagnostic Bundles - Research

**Researched:** 2026-05-06
**Domain:** Elixir/Erlang Diagnostic Packaging, Redaction, and Web Integration
**Confidence:** HIGH

## Summary

The diagnostic bundles phase requires generating a redacted, multi-file `.zip` archive containing system configuration, certificates, metrics, and bounded audit logs. This archive is crucial for debugging SAML issues without risking PII or secret spillage. 

The strategy relies exclusively on Erlang's built-in `:zip` module for in-memory archive generation, Elixir explicit maps for fail-safe redaction, and standard Plug HTTP endpoints for LiveView integration. Dynamic serialization (e.g., `@derive Jason.Encoder`) is strictly prohibited to prevent future secrets from leaking via a "fail-open" pattern.

**Primary recommendation:** Centralize all explicit mapping in a dedicated module (`Relyra.Diagnostic.AllowList`) and execute ZIP generation purely in-memory returning `{:ok, zip_binary}` to satisfy both the CLI and web delivery requirements gracefully.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Diagnostic Map Extraction | API / Backend | Database / Storage | Explicitly queries Ecto schemas and translates them to bounded Maps via `AllowList` module. |
| Redaction & Structuring | API / Backend | — | Hashing correlation IDs, dropping sensitive fields, encoding via `Jason.encode!`. |
| ZIP Generation | API / Backend | — | Erlang `:zip` handles in-memory construction, returning a binary. |
| CLI Invocation | API / Backend | — | `mix relyra.diagnostic` task interacts with standard Elixir API and saves to disk. |
| LiveView Download | Frontend Server | Browser | Provides an HTTP GET endpoint (`Plug.Conn.send_download`) triggered by a LiveView UI button. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:zip` (Erlang) | native | Generating the multi-file `.zip` archive | Shipped with OTP; requires no third-party dependencies. Extremely fast for in-memory `<5MB` payloads. |
| `Jason` | ~> 1.4.4 | JSON payload generation | The standard JSON library in Phoenix applications. Already locked in `mix.lock`. |
| `Plug.Conn` | ~> 1.16 | File download integration | `Plug.Conn.send_download/3` is the idiomatic standard for pushing binaries to HTTP clients. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:crypto` (Erlang) | native | Hashing correlation IDs | Standard Erlang crypto library to one-way hash identifiers. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Erlang `:zip` | External CLI (`System.cmd("zip", ...)`) | Requires host OS binaries and disk I/O, which breaks containerized environments. |
| Explicit Allow-List Maps | `@derive {Jason.Encoder, only: [...]}` | Derive is "fail-open" if the macro is omitted or dynamically traversed. High risk of PII/secret leakage during future migrations. |

**Installation:**
```bash
# No new dependencies required. `:zip` and `:crypto` are native. `Jason` is present.
```

**Version verification:** 
Verified Elixir 1.19.5 (OTP 28) environment and `mix.lock` containing `Jason 1.4.4`. `Plug 1.16` is used natively by the application.

## Architecture Patterns

### Recommended Project Structure
```text
lib/relyra/
├── diagnostic/
│   ├── allow_list.ex    # Core mapping and redaction logic
│   └── bundle.ex        # Orchestrates DB fetches and ZIP compilation
├── live_admin/
│   ├── diagnostic_controller.ex  # Plug route for file download
│   └── ...
└── mix/tasks/
    └── relyra.diagnostic.ex      # CLI execution trigger
```

### Pattern 1: Explicit Redaction Allow-List
**What:** Mapping Ecto structs into raw Elixir maps containing only explicitly allowed fields.
**When to use:** Whenever sensitive or dynamic data schemas are serialized for external consumption.
**Example:**
```elixir
defmodule Relyra.Diagnostic.AllowList do
  @doc "Converts a Connection Ecto struct into a safe map for export."
  def export_connection(%Relyra.Ecto.Connection{} = conn) do
    %{
      "id" => conn.id,
      "state" => to_string(conn.state),
      "entity_id" => conn.entity_id,
      # Explicitly NOT including secrets, keys, or unverified embeds
    }
  end
end
```

### Pattern 2: In-Memory ZIP Generation
**What:** Using Erlang's `:zip` to generate a binary entirely in RAM.
**When to use:** Small (<10MB) payloads targeting both CLI and Web clients.
**Example:**
```elixir
files = [
  {~c"connections.json", Jason.encode!(connections_map, pretty: true)},
  {~c"metrics.json", Jason.encode!(metrics_map, pretty: true)}
]
{:ok, {_filename, zip_binary}} = :zip.create(~c"bundle.zip", files, [:memory])
```
*Note: Erlang's `:zip.create/3` requires charlists (`~c"..."`) for filenames.*

### Anti-Patterns to Avoid
- **Fail-Open Struct Serialization:** Using `Jason.encode!` directly on Ecto structs or relying on `@derive`. This approach leaks fields added in future DB migrations.
- **Disk-Backed Temp Files:** Writing the ZIP to `System.tmp_dir()` before sending. This forces the application to deal with permissions, container read-only filesystems, and crash cleanup.
- **PII Leakage in Stores:** Attempting to dump `RequestStore` or `ReplayStore` content. These hold SAML assertions, `name_id` values, and transient PII.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ZIP archives | Custom binary packers / OS commands | Erlang `:zip` module | Native performance, well-tested, supports `:memory` flag to avoid IO bottlenecks. |
| File downloading | Custom HTTP chunking for the ZIP | `Plug.Conn.send_download/3` | Handles all HTTP headers (Content-Disposition, Mime Types) securely and correctly out of the box. |

**Key insight:** Elixir/Erlang's standard library provides robust in-memory archive generation. Delegating this to native functions reduces error surface dramatically.

## Runtime State Inventory

*Step 2.5: SKIPPED (not a rename/refactor phase)*

## Common Pitfalls

### Pitfall 1: String vs Charlist for Erlang `:zip`
**What goes wrong:** Calling `:zip.create("name.zip", [{"file.txt", "data"}], [:memory])` crashes the process.
**Why it happens:** Erlang functions typically expect charlists (`~c"..."`), not Elixir Strings (binaries).
**How to avoid:** Always use the `~c"..."` sigil for both the archive name and inner file names passed to `:zip`.

### Pitfall 2: Audit Log Correlation ID Leakage
**What goes wrong:** Exporting `correlation_id` directly in the audit log JSON might expose a session identifier or PII embedded by an IdP.
**Why it happens:** SAML RelayStates and correlation IDs are frequently opaque and supplied externally.
**How to avoid:** One-way hash the ID using `:crypto.hash(:sha256, id) |> Base.encode16()`.

### Pitfall 3: LiveView Download Constraints
**What goes wrong:** Trying to download the ZIP entirely over the LiveView WebSocket.
**Why it happens:** LiveView cannot natively trigger a file download dialogue using WebSocket binary pushes easily without messy JS interop.
**How to avoid:** The LiveView button should act as a standard hyperlink or form pointing to a separate HTTP GET Controller route (e.g., `DiagnosticController`).

## Code Examples

### Generate Hashed Correlation ID
```elixir
# Source: Erlang :crypto
def hash_identifier(nil), do: nil
def hash_identifier(id) when is_binary(id) do
  :crypto.hash(:sha256, id) |> Base.encode16(case: :lower)
end
```

### Plug.Conn File Delivery
```elixir
# Source: Plug.Conn Official Docs
def download_bundle(conn, _params) do
  {:ok, zip_binary} = Relyra.Diagnostic.create_bundle()
  
  conn
  |> put_resp_content_type("application/zip")
  |> send_download({:binary, zip_binary}, filename: "relyra_diagnostic_bundle.zip")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OS-level CLI dumps | In-memory ZIP telemetry | Present | Containers remain ephemeral; exports are safe and instantaneous. |
| Monolithic JSON | Domain-separated JSON files | Present | Easier to parse via `jq` and diff across environments. |

## Assumptions Log

*(All critical assertions are derived from locked decisions, native Erlang documentation, or validated Elixir source code in the repository. No assumptions require user confirmation.)*

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP | `:zip`, `:crypto` | ✓ | 28 (erts-16.3) | — |
| Elixir | Core Application | ✓ | 1.19.5 | — |
| Jason | JSON Encoding | ✓ | ~> 1.4.4 | — |

**Missing dependencies with no fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` / `test/test_helper.exs` |
| Quick run command | `mix test --warnings-as-errors` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIAG-01 | Zip Creation returns `{:ok, bin}` | unit | `mix test test/relyra/diagnostic/bundle_test.exs` | ❌ Wave 0 |
| DIAG-01 | explicit allow-list strips secrets | unit | `mix test test/relyra/diagnostic/allow_list_test.exs` | ❌ Wave 0 |
| DIAG-01 | Controller serves binary | integration | `mix test test/relyra/live_admin/diagnostic_controller_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/relyra/diagnostic/`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/relyra/diagnostic/allow_list_test.exs` — asserts fail-safe redaction
- [ ] `test/relyra/diagnostic/bundle_test.exs` — checks zip archive compilation

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Must piggy-back off existing LiveAdmin authentication |
| V3 Session Management | no | — |
| V4 Access Control | yes | Endpoint must require Admin authorization |
| V5 Input Validation | yes | Strong typing for ID/Entity lookups in diagnostic limits |
| V6 Cryptography | yes | `:crypto.hash(:sha256, id)` for correlation hashing |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Inadvertent Secret Spillage | Information Disclosure | Explicit map translation; do not use `Jason.Encoder` on Ecto Structs. |
| Denial of Service (Memory Exhaustion) | Denial of Service | Bounding the maximum records included in the Zip (e.g., Audit logs limited to 1000). |
| Path Traversal in Zip Extraction | Tampering | Zip contents are flat, predefined charlists (`~c"connections.json"`); do not dynamically construct file paths inside the archive based on user input. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/23-diagnostic-bundles/23-CONTEXT.md` - Locked constraints and architecture.
- `mix.lock` and `elixir -v` - Verified native dependencies and versions.
- Erlang OTP Documentation - `:zip` and `:crypto` modules native behavior.

### Secondary (MEDIUM confidence)
- Phoenix Framework Plug Documentation - Standard for `Plug.Conn.send_download/3`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core standard library functions and existing project dependencies.
- Architecture: HIGH - Dictated strongly by architectural constraints.
- Pitfalls: HIGH - Documented issues with Erlang bindings and LiveView downloads in the ecosystem.

**Research date:** 2026-05-06
**Valid until:** 2026-06-06