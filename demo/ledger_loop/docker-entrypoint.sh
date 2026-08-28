#!/usr/bin/env bash
set -euo pipefail
# Source: CONTEXT D-08 + demo ecto.setup alias (mix.exs)
# Entrypoint flow: local.hex/rebar → lock-hash gate → ecto.create → relyra.migrate → ecto.migrate → seeds → exec "$@"

# (1) Ensure local Hex + rebar are available (idempotent, --if-missing skips when already installed)
mix local.hex --force --if-missing
mix local.rebar --force --if-missing

# (2) Lock-hash gate: re-resolve deps only when mix.lock has changed.
#     The stamp lives inside the relyra_build named volume (_build/.docker/mix.lock.sha)
#     so it survives down/up but is wiped by `docker volume rm relyra_build` (Pitfall 6, D-08).
STAMP="_build/.docker/mix.lock.sha"
CURRENT="$(sha256sum mix.lock | awk '{print $1}')"
mkdir -p "$(dirname "$STAMP")"
if [ ! -f "$STAMP" ] || [ "$(cat "$STAMP")" != "$CURRENT" ]; then
  echo "==> mix.lock changed or stamp absent — re-resolving dependencies..."
  mix deps.get
  mix deps.compile
  echo "$CURRENT" > "$STAMP"
  echo "==> Dependencies resolved and stamp written."
else
  echo "==> mix.lock unchanged — skipping deps.get/deps.compile."
fi
# The relyra path dep ({:relyra, path: "../.."}) compiles implicitly on the first
# mix task that touches it (not by deps.get — it is not in mix.lock).

# (3) Create the database (idempotent — || true because it errors if already exists)
mix ecto.create --quiet || true

# (4) Run Relyra's internal migrations BEFORE the demo's own ecto.migrate.
#     This creates relyra's audit/connection/replay tables. Skipping this step
#     causes 500 errors on every SAML/admin path (Pitfall 5, D-08).
mix ledger_loop.relyra.migrate

# (5) Run the demo app's own migrations.
mix ecto.migrate

# (6) Run idempotent seeds (LedgerLoop.Demo.Reset.reset!() — safe on every boot).
mix run priv/repo/seeds.exs

# (7) Hand off to the compose command (mix phx.server) as PID 1 for clean signal handling (D-09).
exec "$@"
