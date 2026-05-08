# Phase 22: Certificate Expiry Alerts - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** ~100
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/security/certificate_expiry.ex` | service | batch | `lib/relyra/metadata/scheduler.ex` | exact |
| `lib/relyra/telemetry.ex` | config | event-driven | `lib/relyra/telemetry.ex` | exact |
| `lib/relyra/telemetry/handlers/log_alerts.ex` | utility | event-driven | `lib/relyra/telemetry/handlers/log_alerts.ex` | exact |

## Pattern Assignments

### `lib/relyra/security/certificate_expiry.ex` (service, batch)

**Analog:** `lib/relyra/metadata/scheduler.ex`

**Imports and Gateway pattern** (lines 1-19):
```elixir
if Code.ensure_loaded?(Ecto.Query) do
  defmodule Relyra.Security.CertificateExpiry do
    import Ecto.Query, only: [from: 2]

    alias Relyra.Ecto.Certificate
    alias Relyra.Ecto.Connection
    alias Relyra.Error
```

**Core batch traversal pattern** (lines 40-60):
```elixir
    def check_all(repo, opts \\ []) when is_atom(repo) and is_list(opts) do
      # Querying pattern delegating to a private fetch
      certificates = fetch_expiring_certificates(repo, DateTime.utc_now(), opts)

      case certificates do
        [] ->
          emit_skipped()
          {:ok, %{}}

        certificates ->
          # Sequential per-item loop to avoid stampeding
          results =
            certificates
            |> Enum.map(fn cert ->
               {cert.id, evaluate_and_emit(cert, opts)}
            end)
            |> Map.new()

          {:ok, results}
      end
    end
```

**Optional dependency fallback pattern** (lines 92-108):
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

---

### `lib/relyra/telemetry.ex` (config, event-driven)

**Analog:** `lib/relyra/telemetry.ex`

**Telemetry execute pattern** (lines 80-87):
```elixir
  ### certificate.expiring
  # Emitted when a certificate is nearing expiration
  
  @doc false
  def execute(event, measurements, metadata \\ %{}) do
    :telemetry.execute([:relyra, :saml | List.wrap(event)], measurements, metadata)
  end
```

---

### `lib/relyra/telemetry/handlers/log_alerts.ex` (utility, event-driven)

**Analog:** `lib/relyra/telemetry/handlers/log_alerts.ex`

**Handler event pattern** (lines 20-41):
```elixir
  @events [
    # Add new event to the list
    [:relyra, :saml, :certificate, :expiring],
    [:relyra, :saml, :metadata, :auto_refresh, :start],
    # ...
  ]

  def handle_event([:relyra, :saml, :certificate, :expiring], measurements, metadata, _config) do
    Logger.warning("certificate expiring " <> inspect(redact(metadata)))
  end
```

## Shared Patterns

### Database Traversal & Delegation
**Source:** `lib/relyra/metadata/scheduler.ex`
**Apply to:** `lib/relyra/security/certificate_expiry.ex`
Do not spawn supervised processes or use internal scheduling (GenServer). The library should expose a `check_all(repo, opts)` function that adopters call from their own scheduled job (e.g., Oban, Quantum). It queries the repo using Ecto, processes each matching row sequentially, and returns an `{:ok, results_map}` tuple. The database query should leverage Ecto querying against `Relyra.Ecto.Certificate` where `not_after` is approaching.

### Telemetry Emit
**Source:** `lib/relyra/telemetry.ex`
**Apply to:** `lib/relyra/security/certificate_expiry.ex`
Instead of performing arbitrary side-effects, the traversal logic strictly executes `:telemetry.execute` for matching certificates, adhering to the project's observability contracts. Handlers handle alerting.

## No Analog Found

Files with no close match in the codebase: none.

## Metadata

**Analog search scope:** `lib/relyra/`
**Files scanned:** ~100
**Pattern extraction date:** 2024-05-18
