# Relyra

Relyra is a strict-by-default **SAML 2.0 Service Provider library for Elixir/Phoenix**.
It is for teams that need enterprise SSO without becoming SAML experts.

## What v0.1 includes

- SP-initiated login + ACS validation.
- Hardened XML / signature / protocol checks.
- Provider presets for Okta, Microsoft Entra ID, and Google Workspace.
- `Relyra.TestSupport` and `Relyra.TestSupport.FakeIdP` for local tests.
- `mix relyra.install` for minimal host-app scaffolding.

## What v0.1 does not include

- OIDC/OAuth.
- Hosted broker runtime.
- SCIM ownership.
- Ecto schemas / metadata import-export / rollover (v0.2+).

## Install

```elixir
def deps do
  [
    {:relyra, "~> 0.1.0"}
  ]
end
```

Then scaffold the host app:

```bash
mix relyra.install --module MyApp --repo my-app
```

## Quick start

1. Pick a provider preset with `Relyra.Provider.apply_defaults/2`.
2. Wire the Phoenix router and ACS endpoint.
3. Use `Relyra.TestSupport` in tests.

## Guides

- [Getting Started](guides/getting_started.md)
- [Okta recipe](guides/recipes/okta.md)
- [Microsoft Entra ID recipe](guides/recipes/entra.md)
- [Google Workspace recipe](guides/recipes/google_workspace.md)
- [Security policy](SECURITY.md)

## Operations: Bulk actions

Phase 20 ships a multi-select bulk-actions surface in the LiveView admin so operators can run lifecycle and metadata actions across many connections in one operator action. Each bulk run produces one shared audit `correlation_id` so the resulting per-connection ledger rows can be reconstructed as a single batch — Phase 21.1 closed the audit forwarding gap so this guarantee holds for every supported action.

From the connections list, select one or more connections via the row checkboxes. The Bulk Actions menu appears once at least one row is selected and exposes three actions:

- **Enable** — Move every selected connection to the `enabled` lifecycle state. Each connection's trust change co-commits its own audit row inside its own transaction.
- **Disable** — Move every selected connection to the `disabled` lifecycle state. Existing application sessions are not revoked.
- **Refresh Metadata** — Re-fetch metadata for every selected connection from its registered remote source. The bulk path uses the same operator-triggered manual refresh seam as a single-connection refresh; new signing certificates stage as `:next` rather than promoting implicitly.

Bulk actions execute sequentially (one connection at a time) to keep database pressure bounded and audit ordering explicit. The aggregate flash message reports per-connection success and failure counts; partial failures do not abort the batch.

Audit trail: every per-connection row in a bulk run shares the bulk `correlation_id` and the operator-attributed `actor` / `cause`, so an operator reviewing the audit ledger can reconstruct "who ran which bulk action across which connections" from a single shared identifier.

The seam is `Relyra.Ecto.BulkActions.run/4`. Hosts that want to drive bulk actions from a Mix task, a script, or a custom admin UI can call it directly with a list of `connection_id` values and one of the three action functions:

```elixir
Relyra.Ecto.BulkActions.run(
  MyApp.Repo,
  ["01JT...", "01JT...", "01JT..."],
  &Relyra.Metadata.refresh/2,
  audit: %{actor: "ops@example.com", cause: "scripted_bulk_refresh"}
)
```

Returns `{:ok, %{connection_id => {:ok, _} | {:error, %Relyra.Error{}}}}`. The `correlation_id` is auto-generated if not supplied in the audit map.

## Operations: Scheduled metadata refresh

Phase 21 ships a dormant scheduler entry point any host scheduler can drive. Auto-refresh is opt-in per connection and requires an operator-pinned SHA-256 metadata trust fingerprint before it can be enabled. Pick the recipe that matches your deployment.

### Option 1: Oban Cron (recommended)

Add one Cron line. Oban's `unique:` constraint deduplicates across a clustered Oban; the per-source schedule (cadence preset + jitter) is enforced by Relyra.

```elixir
# In your host application's config/config.exs:
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [relyra_metadata: 1],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Wake every 15 minutes; per-source cadence is enforced by Relyra.
       {"*/15 * * * *", Relyra.Workers.MetadataRefresh,
        args: %{"repo" => "MyApp.Repo"}}
     ]}
  ]
```

Add `{:oban, "~> 2.22"}` to your host's `mix.exs` (Relyra declares Oban as `optional: true`).

### Option 2: Mix task (system-cron-friendly)

For hosts without Oban — drives the same `Scheduler.run_due/2` entry point.

```bash
# Once a minute via system cron:
* * * * * cd /path/to/host && MIX_ENV=prod mix relyra.refresh_due --repo MyApp.Repo
```

### Option 3: Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: relyra-refresh-due
spec:
  schedule: "*/15 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: relyra
              image: my-app:latest
              command: ["mix", "relyra.refresh_due", "--repo", "MyApp.Repo"]
          restartPolicy: OnFailure
```

### Option 4: fly.io scheduled machines

```toml
# fly.toml
[[machines.schedule]]
  schedule = "*/15 * * * *"
  command = ["mix", "relyra.refresh_due", "--repo", "MyApp.Repo"]
```

### Pinning a metadata trust fingerprint

Phase 21 requires operator-pinned SHA-256 fingerprints — there is no TOFU. Compute and verify the fingerprint out-of-band:

```bash
# Compute the SHA-256 fingerprint of the IdP's metadata-signing certificate:
openssl x509 -in metadata-signing.pem -outform DER \
  | openssl dgst -sha256 \
  | tr 'A-F' 'a-f'
```

Then pin it:

```bash
mix relyra.metadata.pin <connection_id> \
  --fingerprint <sha256_hex> \
  --repo MyApp.Repo
```

The mix task and the (forthcoming v0.6) admin LiveView fingerprint form share the same underlying changeset, so either path produces the same audit trail. Supply every currently-pinned fingerprint plus the new one to extend the rotation window — the pin REPLACES the source's fingerprint array.

### Telemetry events

Scheduled refresh emits under the `[:relyra, :saml, :metadata, :auto_refresh, ...]` namespace (separate from the manual `[:relyra, :saml, :metadata, :refresh]` namespace). See `Relyra.Telemetry`'s moduledoc for the full event catalog. An opt-in reference handler logs each event with redaction:

```elixir
# In your host's Application.start/2:
def start(_type, _args) do
  :ok = Relyra.Telemetry.Handlers.LogAlerts.attach()
  ...
end
```

Adopters who want vendor paging (Slack / PagerDuty / Sentry) attach their own handlers — telemetry events are the contract.

## Security

Relyra follows a fail-closed trust path. See [`SECURITY.md`](SECURITY.md) for
supported algorithms, threat model, and private disclosure workflow.
