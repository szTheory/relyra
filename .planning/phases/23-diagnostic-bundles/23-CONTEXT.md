# Phase 23 Context: Diagnostic Bundles

## Goals
Operator can export a redacted diagnostic bundle for troubleshooting SAML connections using an allow-list schema without leaking secrets or PII (DIAG-01).

## Gray Area Decisions & Locked Architecture

Based on deep ecosystem research (Elixir/Ecto/Plug/Phoenix) and lessons learned from tools like Phoenix LiveDashboard and Oban, the following architecture is locked for Phase 23.

### 1. Format: Multi-file JSON Zip Archive
**Decision:** The bundle will be a standard `.zip` file containing multiple logically separated `.json` files (`connections.json`, `certificates.json`, `metadata_revisions.json`, `store_metrics.json`), rather than a single monolithic JSON file or Erlang state dump.
**Rationale (Pros/Tradeoffs):**
- **Developer Ergonomics:** Operators can easily pipe individual files into `jq` or diff them across environments. A monolithic file is hostile to standard CLI text tools.
- **Ecosystem Idiom:** Phoenix LiveDashboard and Oban favor separated, domain-specific telemetry/metrics over massive single-payload dumps.
- **Tradeoff:** Requires Erlang's `:zip.create/3` to bundle the files, adding marginal memory overhead during creation compared to streaming a single JSON, but the UX tradeoff is overwhelmingly positive.

### 2. Redaction: Explicit Allow-List Maps (Deny-by-Default)
**Decision:** We will use a dedicated module (`Relyra.Diagnostic.AllowList` or similar) that explicitly maps Ecto structs to pure Elixir maps for serialization. We will **not** rely on `@derive {Jason.Encoder, only: [...]}` or dynamic Ecto `__schema__(:fields)` traversal.
**Rationale (Pros/Tradeoffs):**
- **Security (Fail-Safe):** If a developer adds a new sensitive column (e.g., a new secret key) to an Ecto schema in a future migration, it will *not* be exported in the diagnostic bundle unless explicitly added to the allow-list map. `@derive {Jason.Encoder}` or reflection is "fail-open" or easily forgotten, leading to catastrophic leaks (a known footgun in Rails/Django and Ecto apps).
- **Principle of Least Surprise:** Redaction logic lives in exactly one place (the diagnostic module), rather than being scattered across `@derive` attributes on schemas.
- **Tradeoff:** Marginal increase in boilerplate. The explicit map builder must be updated when new non-sensitive diagnostic fields are added to schemas.

### 3. Inclusion Scope: Configuration & Metrics, No Transient Data
**Decision:** The bundle will include:
1. Active `Connection` configurations (redacted).
2. `CertificateInventory` summaries (fingerprints, not_before, not_after, issuer).
3. Active/recent `MetadataRevision` pointers.
4. Point-in-time metrics/counts for `RequestStore` and `ReplayStore`.
It will **not** include transient store payloads (e.g., raw XML requests, `name_id` values, or session identifiers).
**Rationale:**
- **Compliance:** Transient stores contain PII and active assertion data. Exporting them risks turning a diagnostic tool into a compliance violation.
- **Utility:** 99% of SAML debugging involves misconfigured certificates, mismatched Entity IDs, or stale metadata. Store counts (e.g., "ReplayStore size: 400") are sufficient to debug memory leaks without exposing the data.

### 4. Trigger Surface: API + Mix Task
**Decision:** The core functionality will live in `Relyra.Diagnostic.create_bundle(dir_path)` and be exposed immediately via `mix relyra.diagnostic`. A LiveView admin UI integration is supported by this API but strictly decoupled from it.
**Rationale:**
- Operators typically debug SAML issues from a production shell or remote observer session when the UI might be inaccessible.

### Synthesized Architectural Recommendations (Phase 23)

Based on Elixir ecosystem best practices (e.g., Phoenix LiveDashboard, Oban) and the principle of prioritizing developer ergonomics (DX) and system safety, the following architectural decisions resolve the remaining gray areas:

#### 1. Audit Logs: Bounded Inclusion with Hashed Correlation
**Decision:** Include a bounded slice (e.g., the last 500-1000 entries) of `Relyra.Audit` events in the bundle (`audit_logs.json`).
**Redaction Strategy:**
- Strip highly-sensitive fields entirely (e.g., `actor`, `ip_address`).
- **Anonymize** the `correlation_id` by hashing it (e.g., `:crypto.hash(:sha256, id) |> Base.encode16()`).
**Rationale:** SAML debugging is heavily reliant on audit trails (e.g., "Why did this signature fail validation?"). Without audit logs, the diagnostic bundle lacks the actual failure context. Hashing the `correlation_id` maintains the structural integrity of the request lifecycle (allowing operators to group related events) without leaking the original identifier, which often contains PII or session IDs.

#### 2. Zip Generation: In-Memory Compilation (`:memory`)
**Decision:** Generate the ZIP archive entirely in memory using Erlang's `:zip.create('bundle.zip', files, [:memory])`. The core API should return `{:ok, zip_binary}`.
**Rationale:**
- **Deterministic Size:** The included data (Configurations, Certificates, Metrics, bounded Audit Logs) is structurally small (typically < 5MB). In-memory generation is extremely fast and well within safe limits for BEAM processes.
- **Fail-Safe & Ergonomic:** Writing to disk requires managing temporary directories (`System.tmp_dir()`), handling cross-platform permissions, and ensuring cleanup in `try/after` blocks if the process crashes. In ephemeral containerized environments (Fly.io, Heroku, Docker), temp directories can be restrictive.
- **Integration:** Returning a binary makes downstream consumption trivial. The Mix task can simply `File.write!/2` to the current working directory, and the Phoenix integration can use `Plug.Conn.send_download(conn, {:binary, zip_binary})` without complex file streaming.

#### 3. LiveView Admin UI Scope: Include Controller Route & UI Button
**Decision:** Do not defer the UI. Phase 23 must include a "Download Diagnostic Bundle" button in the Relyra LiveView Admin, backed by a simple Phoenix Controller route (or Plug).
**Rationale:**
- **Operator Reality:** Support engineers and operators debugging SAML connections frequently do not have SSH access to production containers to run `mix` tasks. A CLI-only tool severely limits its real-world utility.
- **Technical Implementation:** LiveView cannot natively trigger file downloads directly to the browser without a corresponding HTTP endpoint. We will provide a standard GET route secured by the same authentication as the LiveView, which the LiveView button will point to. This provides a complete, polished DX directly out of the box.

