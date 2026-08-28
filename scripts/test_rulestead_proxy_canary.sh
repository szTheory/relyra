#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
RULESTEAD_DIR="${RULESTEAD_DIR:-$ROOT_DIR/rulestead}"
ARTIFACT_DIR="${RULESTEAD_CANARY_ARTIFACT_DIR:-playwright-report/rulestead-canary}"
PROXY_NETWORK="proxy"
RULESTEAD_PROJECT="relyra-rulestead-canary"
FLEET_COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.proxy.yml)
PROXY_COMPOSE=(docker compose -f docker/traefik/compose.yml)
PROXY_WAS_RUNNING=false
NETWORK_WAS_PRESENT=false

cd "$ROOT_DIR"
mkdir -p "$ARTIFACT_DIR"

log() {
  printf '[rulestead-canary] %s\n' "$*"
}

rulestead_compose() {
  (
    cd "$RULESTEAD_DIR"
    COMPOSE_PROJECT_NAME="$RULESTEAD_PROJECT" \
      docker compose -f docker-compose.yml -f docker-compose.proxy.yml "$@"
  )
}

wait_for_health() {
  local service="$1"

  for _attempt in $(seq 1 90); do
    local container_id
    container_id="$(rulestead_compose ps -q "$service")"

    if [[ -n "$container_id" ]]; then
      local status
      status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id")"
      if [[ "$status" == "healthy" || "$status" == "running" ]]; then
        return 0
      fi
    fi

    sleep 2
  done

  return 1
}

wait_for_route() {
  local host="$1"
  local path="$2"
  local expected="$3"

  for _attempt in $(seq 1 60); do
    if curl --noproxy "*" --resolve "$host:80:127.0.0.1" -fsS "http://$host$path" | grep -q "$expected"; then
      return 0
    fi
    sleep 2
  done

  return 1
}

capture_diagnostics() {
  docker ps -a >"$ARTIFACT_DIR/docker-ps.log" 2>&1 || true
  docker network inspect "$PROXY_NETWORK" >"$ARTIFACT_DIR/proxy-network.log" 2>&1 || true
  "${FLEET_COMPOSE[@]}" logs --no-color >"$ARTIFACT_DIR/relyra.log" 2>&1 || true
  "${PROXY_COMPOSE[@]}" logs --no-color >"$ARTIFACT_DIR/traefik.log" 2>&1 || true
  rulestead_compose logs --no-color >"$ARTIFACT_DIR/rulestead.log" 2>&1 || true
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM

  if [[ "$status" -ne 0 ]]; then
    capture_diagnostics
  fi

  rulestead_compose down --remove-orphans --volumes >/dev/null 2>&1 || true
  "${FLEET_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true

  if [[ "$PROXY_WAS_RUNNING" == "false" ]]; then
    "${PROXY_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  if [[ "$status" -eq 0 ]]; then
    log "Relyra and Rulestead main coexistence assertions passed"
  else
    log "failed; diagnostics saved under $ARTIFACT_DIR"
  fi

  exit "$status"
}
trap cleanup EXIT INT TERM

if [[ ! -x "$RULESTEAD_DIR/scripts/demo/proxy-up.sh" ]]; then
  log "Rulestead checkout not found at $RULESTEAD_DIR"
  exit 1
fi

if [[ -n "$(docker compose ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse an active relyra-demo project"
  exit 1
fi

if [[ -n "$(rulestead_compose ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse the Rulestead canary project"
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

log "starting Relyra with the shared proxy"
"${PROXY_COMPOSE[@]}" up -d
proxy_id="$("${PROXY_COMPOSE[@]}" ps -q traefik)"
[[ -n "$proxy_id" ]]
"${FLEET_COMPOSE[@]}" up -d --build --wait

log "starting the checked-out Rulestead main demo against the same proxy"
(
  cd "$RULESTEAD_DIR"
  COMPOSE_PROJECT_NAME="$RULESTEAD_PROJECT" \
  DEMO_PROXY_NETWORK="$PROXY_NETWORK" \
  DEMO_PROXY_PROJECT_NAME=dev_proxy \
  DEMO_PROXY_HTTP_PORT=80 \
  DEMO_HOST_SLUG=local \
    scripts/demo/proxy-up.sh
)

wait_for_health backend
wait_for_health frontend
wait_for_route relyra.localhost /setup/sso "SSO Setup"
wait_for_route rulestead.localhost / "Rulestead"
wait_for_route fleetdesk.rulestead.localhost / "FleetDesk"

log "stopping only Relyra and proving Rulestead remains routed"
"${FLEET_COMPOSE[@]}" down --remove-orphans
wait_for_route rulestead.localhost / "Rulestead"
wait_for_route fleetdesk.rulestead.localhost / "FleetDesk"
[[ "$(docker inspect --format '{{.State.Running}}' "$proxy_id")" == "true" ]]
docker network inspect "$PROXY_NETWORK" >/dev/null

capture_diagnostics
