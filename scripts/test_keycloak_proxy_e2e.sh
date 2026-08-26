#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROXY_NETWORK="${DEMO_PROXY_NETWORK:-proxy}"
COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.proxy.yml --profile keycloak)
PROXY_COMPOSE=(docker compose -f docker/traefik/compose.yml)
PROXY_WAS_RUNNING=false
NETWORK_WAS_PRESENT=false

log() {
  printf '[keycloak-proxy-e2e] %s\n' "$*"
}

log "validating the proxy-only Keycloak graph"
rendered="$(${COMPOSE[@]} config --format json)"

# The realm must use the same public host for browser origins as it uses for
# entity ID, metadata, and ACS endpoints.  This assertion intentionally lands
# before the realm contract is corrected below (TDD RED).
jq -e '
  .clients[0].webOrigins == ["http://${RELYRA_HOST}"]
' docker/keycloak/realm-demo-app.json >/dev/null

jq -e '
  .services.keycloak.ports == null and
  (.services.keycloak.networks | keys | sort) == ["default", "proxy"] and
  .services.keycloak.environment.KC_HOSTNAME == "http://keycloak.relyra.localhost" and
  .services.keycloak.environment.KC_PROXY_HEADERS == "xforwarded" and
  (.services.keycloak.healthcheck.test | join(" ") | contains("/dev/tcp/localhost/9000")) and
  any(.services.keycloak.labels | keys[]; contains("relyra-keycloak")) and
  (.services.keycloak_provisioner.networks | has("default")) and
  (.services.keycloak_provisioner.networks | has("proxy") | not)
' <<<"$rendered" >/dev/null

if [[ "${KEYCLOAK_PROXY_STATIC_ONLY:-0}" == "1" ]]; then
  log "static proxy graph assertions passed"
  exit 0
fi

cleanup() {
  local result_code=$?
  trap - EXIT INT TERM
  "${COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true

  if [[ "$PROXY_WAS_RUNNING" == "false" ]]; then
    "${PROXY_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  exit "$result_code"
}
trap cleanup EXIT INT TERM

if [[ -n "$("${COMPOSE[@]}" ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse an active relyra-demo project; stop it before running this test"
  exit 1
fi

if [[ -n "$("${PROXY_COMPOSE[@]}" ps -q traefik 2>/dev/null)" ]]; then
  PROXY_WAS_RUNNING=true
fi

if docker network inspect "$PROXY_NETWORK" >/dev/null 2>&1; then
  NETWORK_WAS_PRESENT=true
else
  docker network create "$PROXY_NETWORK" >/dev/null
fi

"${PROXY_COMPOSE[@]}" up -d
"${COMPOSE[@]}" up -d --build

ready=false
for _attempt in $(seq 1 60); do
  if curl --noproxy "*" -fsS --resolve "relyra.localhost:80:127.0.0.1" http://relyra.localhost/readyz >/dev/null; then
    ready=true
    break
  fi
  sleep 1
done

if [[ "$ready" != "true" ]]; then
  log "LedgerLoop public readiness did not succeed"
  exit 1
fi

"${COMPOSE[@]}" wait keycloak_provisioner

BASE_URL=http://relyra.localhost \
KEYCLOAK_SARAH_PASSWORD="${KEYCLOAK_SARAH_PASSWORD:-sarah-password}" \
  npx playwright test --config playwright.keycloak-proxy.config.mjs

"${COMPOSE[@]}" exec -T demo_app mix run -e '
  import Ecto.Query
  alias LedgerLoop.{Repo, Accounts.LoginReceipt}
  alias Relyra.Ecto.{AuditEvent, Connection}
  connection = Repo.get_by!(Connection, connection_id: "01H0B4Y1A2B3C4D5E6F7G8H9J4")
  receipts = Repo.aggregate(LoginReceipt, :count, :id)
  latest = Repo.one(from event in AuditEvent, where: event.connection_record_id == ^connection.id and event.domain == :login and event.action == :succeeded, order_by: [desc: event.inserted_at], limit: 1)
  steps = latest && latest.after_summary["steps"] || %{}
  expected_steps = MapSet.new(["response.validate", "signature.verify", "replay.check"])
  canonical_steps = MapSet.new(Map.keys(steps))
  IO.puts("receipt_count=#{receipts} canonical_trace_steps=#{inspect(MapSet.to_list(canonical_steps) |> Enum.sort())} trace_found=#{not is_nil(latest)}")
  unless receipts == 1 and canonical_steps == expected_steps, do: System.halt(1)
'

log "verified signed ACS, workspace return, durable receipt, and canonical validation/signature/replay trace"
