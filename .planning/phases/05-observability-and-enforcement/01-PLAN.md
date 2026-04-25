# Phase 5: Observability and Enforcement

**Goal**: Make validation outcomes explainable and guardrail violations impossible to miss.

## Plans

### 05-01: Telemetry Catalog and Events
- Implement `Relyra.Telemetry` catalog module with `@moduledoc` documenting all events.
- Namespace: `[:relyra, :saml, ...]`
- Emit `:start`/`:stop`/`:exception` triplets for:
  - `login`
  - `authn_request`
  - `response.decode`
  - `response.validate`
  - `signature.verify`
  - `replay.check`
  - `user.map`
  - `session.establish`
- Measurements: `duration_ms`, `xml_bytes`, `base64_bytes`, `assertion_count`, `attribute_count`, `request_store_latency_ms`, `replay_store_latency_ms`.
- Metadata: `connection_id`, `organization_id`, `provider_preset`, `flow` (`:sp_initiated`), `binding` (`:redirect`/`:post`), `outcome` (`:ok`/`:error`), `error_code`, `signature_algorithm`, `digest_algorithm`.

### 05-02: Redacted Logging and Enforcement
- Implement `Relyra.Log` private helper for redacted structured logs.
- Redaction policy: NEVER log raw XML, full NameID, or private keys. Log hashes or prefixes instead.
- Implement `Inspect` and `String.Chars` protocols for `Relyra.Error` to automatically redact sensitive details.
- Add custom Credo check `Relyra.Credo.Check.NoRawAssertionInLog` to prevent `Logger` calls with raw XML in scope.
- Enforce boundaries using the `boundary` compiler to isolate Protocol Core from Phoenix/Ecto.

## Success Criteria
1. `Relyra.Telemetry` exists and documents all emitted events.
2. Every critical path (login -> ACS -> session) emits telemetry.
3. `Logger` output never contains raw SAML XML or PII.
4. Custom Credo check fails if raw assertion logging is attempted.
5. `boundary` config prevents illegal cross-context dependencies.

## Routing
- Start with 05-01 execution.
