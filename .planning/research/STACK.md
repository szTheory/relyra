# Technology Stack

**Project:** Relyra v0.6
**Researched:** 2026-05

## Recommended Stack

### Core Framework & Libraries
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `:zip` (Erlang) | OTP 26+ | Diagnostic bundle creation | Standard library, no external dependency required for creating `.zip` archives of diagnostic JSONs. |
| `:telemetry` | ~> 1.0 | Certificate expiry alerting | Ecosystem standard for observability. Allows host apps to plug in Prometheus, standard logging, or custom alerts. |
| `Jason` | ~> 1.4 | Diagnostic serialization | Already in the Phoenix/Ecto ecosystem. Used to format internal state into readable JSON inside the debug bundle. |

### Supporting Tools
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Oban` / `Quantum` | N/A | Job Scheduling | *Host Application* responsibility. Relyra will not take a dependency on a scheduler; it will expose `Relyra.check_certificate_expirations/0` for the host app to call. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Job Scheduling | **Host-provided (None)** | Require `Oban` | Relyra is a library, not a framework. Forcing a specific database-backed job queue on adopters violates library design principles. |
| Archiving | **Erlang `:zip`** | `erlexec` / CLI `tar` | `:zip` is cross-platform, pure BEAM, and avoids shelling out to the OS which could introduce command-injection risks or missing dependencies. |
| Redaction | **Allow-list struct mapping** | Ecto `@derive {Inspect, only: [...]}` | Diagnostic bundles need structured JSON, not Elixir `Inspect` strings. A custom pure-function mapping ensures we never accidentally leak a newly added database column. |

## Sources

- Elixir / Erlang official documentation (`:zip`, `:telemetry`).
- `PROJECT.md` bounds: "Relyra is a library; customer data and control stay in host applications."