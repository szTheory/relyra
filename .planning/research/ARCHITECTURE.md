# Architecture Patterns

**Domain:** Enterprise SAML 2.0 Library for Elixir (v0.6 Milestone)
**Researched:** 2026-05

## Recommended Architecture

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Relyra.Protocol.Logout` | Generates and validates `<LogoutRequest>` / `<LogoutResponse>` XML. | `Relyra.Security.XML` |
| `Relyra.SessionAdapter` | Host app integration point. Must now support `revoke_by_session_index/2`. | Host application session store. |
| `Relyra.Diagnostics.Bundle` | Gathers system state, redacts it via allow-list, zips it. | `Relyra.ConnectionResolver`, `Relyra.Metadata` |
| `Relyra.Telemetry.Certificates`| Traverses all connections to emit telemetry for expiring certificates. | `Relyra.ConnectionResolver` |

## Patterns to Follow

### Pattern 1: Allow-list Data Serialization for Bundles
**What:** When generating the diagnostic JSON, explicitly construct a map of allowed fields rather than dropping known bad fields from an Ecto struct.
**When:** Exporting system state in the `DiagnosticBundle` module.
**Example:**
```elixir
def redact_connection(%Relyra.Connection{} = conn) do
  %{
    id: conn.id,
    entity_id: conn.entity_id,
    state: conn.state,
    certificate_count: length(conn.idp_certificates),
    # explicitly NOT including potentially sensitive configuration details
  }
end
```

### Pattern 2: Pure-Function Telemetry Emitters
**What:** Exposing a simple Elixir function to trigger telemetry rather than starting a `GenServer` ticker.
**When:** Certificate expiration alerting.
**Example:**
```elixir
def check_certificate_expirations do
  :telemetry.span([:relyra, :job, :certificate_check], %{}, fn ->
    results = check_all_connections()
    {results, %{checked_count: length(results)}}
  end)
end
```

### Pattern 3: InResponseTo Validation for SLO
**What:** Validating that an incoming `<LogoutResponse>` corresponds to a `<LogoutRequest>` initiated by the SP.
**When:** Handling SP-Initiated SLO responses.
**Why:** Prevents attackers from injecting unsolicited logout responses. Relies on the existing Replay/Request store in Relyra.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Deny-list Redaction
**What:** `Map.drop(connection_struct, [:private_key, :client_secret])`
**Why bad:** When a new sensitive field is added to the database in a future release, it will automatically leak in the diagnostic bundle because it wasn't added to the deny-list.
**Instead:** Always map explicitly (Pattern 1).

### Anti-Pattern 2: Forcing a Scheduler
**What:** Starting a `GenServer` with `Process.send_after` to run the certificate checks daily.
**Why bad:** In a multi-node Phoenix cluster, this means *every* node runs the check, leading to duplicate telemetry.
**Instead:** Rely on the host application's singleton scheduler (like Oban's Cron plugin) to invoke `Relyra.check_certificate_expirations/0`.

## Scalability Considerations

| Concern | At 100 connections | At 10K connections |
|---------|--------------------|--------------------|
| Cert Expiry Check | Load everything into memory. | Stream from DB using `Ecto.Repo.stream/2` to avoid OOM when checking certs. |
| Diagnostic Bundle | Export all configurations. | May need to paginate or scope the export to a specific connection ID. |

## Sources

- Elixir Telemetry / Oban Best Practices (Span Pattern).
- Secure SAML implementation guidelines (OWASP, NIST 800-63-4).