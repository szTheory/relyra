<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
(None explicitly specified in CONTEXT.md, relying on PATTERNS.md and phase description).

### the agent's Discretion
- Determine threshold default (e.g., 30 days) and how it can be overridden.
- Define specific telemetry measurements and metadata for the expiring event.
- Decide if `:next` lifecycle certificates should also be monitored (yes, they are staged but could expire before activation).

### Deferred Ideas (OUT OF SCOPE)
- Internal GenServer scheduling.
- Direct integrations with Slack/PagerDuty.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CERT-EXP-01 | Operators receive timely alerts before SAML certificates expire, allowing proactive rollover. | The `Relyra.Security.CertificateExpiry` module provides a `check_all/2` function for host schedulers to query approaching expirations and emit standard `:telemetry` events. |
</phase_requirements>

# Phase 22: Certificate Expiry Alerts - Research

**Researched:** 2024-05-18 (Updated via agent context)
**Domain:** Security, Database Querying, Observability
**Confidence:** HIGH

## Summary

Phase 22 implements proactive certificate expiry alerts (CERT-EXP-01) allowing operators to perform timely rollovers. The core capability is a library-provided backend function `Relyra.Security.CertificateExpiry.check_all/2` that queries tenant connections via Ecto, identifying certificates nearing their `not_after` threshold (defaulting to 30 days).

For matches, it emits `[:relyra, :saml, :certificate, :expiring]` telemetry events. Crucially, the system does not force a background worker on the host application, delegating the scheduling to the adopter (e.g., Oban, Quantum, or mix task) and the alert routing to telemetry handlers (like the provided `Relyra.Telemetry.Handlers.LogAlerts`).

**Primary recommendation:** Implement `Relyra.Security.CertificateExpiry` mirroring the `Relyra.Metadata.Scheduler` pattern (batch traversal, optional Ecto dependency) and emit `[:relyra, :saml, :certificate, :expiring]` via `Relyra.Telemetry.execute/3`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Certificate traversal & expiration check | API / Backend | Database | Scheduled checking of database rows (certificates) relies entirely on backend logic and Ecto querying against PostgreSQL. |
| Emit Expiry Alerts | API / Backend | — | Emitting Erlang/Elixir `:telemetry` events is synchronous server-side instrumentation logic driven by the scheduled traversal. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto.Query` | 3.x | Query `relyra_connection_certificates` | Filters rows nearing `not_after` efficiently. |
| `:telemetry` | 1.x | Emit `[:relyra, :saml, :certificate, :expiring]` | Project's established contract for observability and alerting. |

## Architecture Patterns

### System Architecture Diagram
```
[Host Scheduler (e.g., Oban)] 
       │
       ▼ (calls)
[Relyra.Security.CertificateExpiry.check_all/2] 
       │
       ▼ (queries via Ecto)
[PostgreSQL (relyra_connection_certificates)]
       │
       ▼ (returns expiring certificates)
[Relyra.Telemetry.execute/3]
       │
       ▼ (emits)
[:telemetry event: [:relyra, :saml, :certificate, :expiring]]
       │
       ▼ (handled by)
[Host App Handlers / Relyra.Telemetry.Handlers.LogAlerts]
```

### Pattern 1: Batch Traversal & Delegation
**What:** The library exposes a pure traversal function instead of a supervised ticker.
**When to use:** When background jobs must respect the host application's architecture (D-04).
**Example:**
```elixir
def check_all(repo, opts \\ []) when is_atom(repo) and is_list(opts) do
  # Delegate to a private fetch for expiring active/next certificates
  certificates = fetch_expiring_certificates(repo, DateTime.utc_now(), opts)

  case certificates do
    [] -> {:ok, %{}}
    certificates ->
      results =
        certificates
        |> Enum.map(fn cert -> {cert.id, evaluate_and_emit(cert, opts)} end)
        |> Map.new()

      {:ok, results}
  end
end
```

### Pattern 2: Optional Ecto Dependency Fallback
**What:** `check_all/2` must fail gracefully if Ecto is not compiled.
**Example:**
```elixir
else
  defmodule Relyra.Security.CertificateExpiry do
    alias Relyra.Error

    def check_all(_repo, _opts \\ []) do
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Ecto is required for certificate expiry alerting",
         %{operation: :check_all, missing_dependency: :ecto}
       )}
    end
  end
end
```

### Anti-Patterns to Avoid
- **Internal GenServer Scheduling:** Do not spawn a supervised process. The host app owns scheduling.
- **Reporting on Disabled Connections:** Emitting alerts for `status: :disabled` connections is noise.
- **Reporting on Retired Certificates:** Emitting alerts for `lifecycle_state: :retired` is noise.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scheduled polling | Internal GenServer/Cron | Host-app Scheduler (Oban) | Violates library boundaries (D-04). The library should only provide the pure traversal logic. |
| Alert routing | HTTP clients for Slack/PagerDuty | `:telemetry` + Host Handlers | Adopters have diverse, existing paging stacks. Telemetry decouples detection from delivery. |

## Common Pitfalls

### Pitfall 1: Over-alerting
**What goes wrong:** Alerts fire for certificates that are no longer used or connections that are disabled.
**Why it happens:** Broad Ecto queries without proper filtering.
**How to avoid:** The query MUST join `Relyra.Ecto.Connection` and ensure `conn.status == :enabled`. It MUST also filter `Certificate.lifecycle_state in [:active, :next]`.

### Pitfall 2: Missing Optional Dependency Lane
**What goes wrong:** Compilation fails for adopters not using `ecto_sql` or the database integration.
**Why it happens:** The module directly imports `Ecto.Query` without an `if Code.ensure_loaded?(Ecto.Query)` guard.
**How to avoid:** Replicate the fallback pattern from `Relyra.Metadata.Scheduler`.

### Pitfall 3: Stampeding Telemetry Loggers
**What goes wrong:** Too many log lines generated at once if many certificates expire.
**Why it happens:** Doing an unchecked loop over thousands of rows.
**How to avoid:** Process matching rows sequentially via `Enum.map` and emit discrete telemetry events, relying on the handler/host to handle rate-limiting if needed.

## Code Examples

### Querying Expiring Certificates
```elixir
import Ecto.Query, only: [from: 2]

defp fetch_expiring_certificates(repo, now, opts) do
  days_threshold = Keyword.get(opts, :days_to_expiry, 30)
  threshold_date = DateTime.add(now, days_threshold, :day)

  query =
    from cert in Relyra.Ecto.Certificate,
      join: conn in assoc(cert, :connection),
      where: conn.status == :enabled,
      where: cert.lifecycle_state in [:active, :next],
      where: cert.not_after <= ^threshold_date,
      select: %{
        id: cert.id,
        fingerprint_sha256: cert.fingerprint_sha256,
        not_after: cert.not_after,
        connection_id: conn.connection_id
      }

  repo.all(query)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Opaque GenServers | Pure functional traversal (`check_all/2`) | Phase 21 | Adopter retains control of scheduling resources |
| Hardcoded Log lines | `:telemetry` events | Project Start | Integrates cleanly with enterprise monitoring |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] The alert threshold should default to 30 days but be configurable via `opts`. | Summary / Code Examples | Hardcoding the threshold might annoy operators who want earlier or later alerts. |
| A2 | [ASSUMED] We should query certificates where `lifecycle_state in [:active, :next]`. | Common Pitfalls | Checking only `:active` would miss staged (`:next`) certificates that might expire before they are rolled over. |

## Open Questions

1. **Telemetry Event Measurements**
   - What we know: The event is `[:relyra, :saml, :certificate, :expiring]`.
   - What's unclear: Should it include a measurement like `days_until_expiry`?
   - Recommendation: Yes, calculate `DateTime.diff(not_after, now, :day)` and include it in measurements for easier handler logic.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Data layer | ✓ | N/A | — |
| Elixir / Erlang | Runtime | ✓ | N/A | — |

**Missing dependencies with fallback:**
None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/relyra/security/certificate_expiry_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CERT-EXP-01 | Traverses active/next certs and emits events | integration | `mix test test/relyra/security/certificate_expiry_test.exs` | ❌ Wave 0 |
| CERT-EXP-01 | Ignores disabled connections / retired certs | integration | `mix test test/relyra/security/certificate_expiry_test.exs` | ❌ Wave 0 |
| CERT-EXP-01 | Exposes check_all/2 fallback without Ecto | unit | `mix test test/relyra/security/certificate_expiry_test.exs` | ❌ Wave 0 |
| CERT-EXP-01 | LogAlerts handler formats new event | unit | `mix test test/relyra/telemetry/handlers/log_alerts_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/relyra/security/certificate_expiry_test.exs` — covers CERT-EXP-01 traversal and telemetry emissions.
- [ ] `test/relyra/telemetry/handlers/log_alerts_test.exs` — needs update for the new `:expiring` event.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Query bindings |
| V6 Cryptography | yes | Certificate `not_after` property validation |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Over-querying (Denial of Service) | Denial of Service | Batching / sequential processing. Limit scope via `conn.status == :enabled`. |

## Sources

### Primary (HIGH confidence)
- `lib/relyra/telemetry.ex` - Telemetry emission patterns
- `lib/relyra/metadata/scheduler.ex` - Batch traversal and optional dependency fallback patterns
- `.planning/phases/22-certificate-expiry-alerts/PATTERNS.md` - Phase architectural mandates

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto and `:telemetry` are standard in Elixir.
- Architecture: HIGH - Matches existing `Relyra.Metadata.Scheduler` logic exactly.
- Pitfalls: HIGH - Deduced from existing database schemas (`lifecycle_state`, `status`).

**Research date:** 2024-05-18
**Valid until:** 2024-06-18
