#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ARTIFACT_DIR="${FLEET_PROXY_ARTIFACT_DIR:-playwright-report/fleet-proxy-diagnostics}"
PROXY_NETWORK="${DEMO_PROXY_NETWORK:-proxy}"
SIBLING_COMPOSE="test/integration/fleet-proxy-sibling.compose.yml"
SOLO_COMPOSE=(docker compose)
FLEET_COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.proxy.yml)
PROXY_COMPOSE=(docker compose -f docker/traefik/compose.yml)
SIBLING_STACK=(docker compose -f "$SIBLING_COMPOSE")
PROXY_WAS_RUNNING=false
NETWORK_WAS_PRESENT=false

mkdir -p "$ARTIFACT_DIR"

log() {
  printf '[fleet-proxy-e2e] %s\n' "$*"
}

wait_for_http() {
  local url="$1"
  shift

  for _attempt in $(seq 1 60); do
    if curl --noproxy "*" -fsS "$@" "$url" >/dev/null; then
      return 0
    fi
    sleep 1
  done

  return 1
}

capture_diagnostics() {
  {
    docker ps -a
    docker network inspect "$PROXY_NETWORK" 2>&1 || true
  } >"$ARTIFACT_DIR/docker-state.log" 2>&1 || true

  "${SOLO_COMPOSE[@]}" ps -a >"$ARTIFACT_DIR/relyra-ps.log" 2>&1 || true
  "${SOLO_COMPOSE[@]}" logs --no-color >"$ARTIFACT_DIR/relyra.log" 2>&1 || true
  "${PROXY_COMPOSE[@]}" logs --no-color >"$ARTIFACT_DIR/traefik.log" 2>&1 || true
  "${SIBLING_STACK[@]}" logs --no-color >"$ARTIFACT_DIR/sibling.log" 2>&1 || true
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM

  if [[ "$status" -ne 0 ]]; then
    capture_diagnostics
  fi

  "${SIBLING_STACK[@]}" down --remove-orphans >/dev/null 2>&1 || true
  "${FLEET_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  "${SOLO_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true

  if [[ "$PROXY_WAS_RUNNING" == "false" ]]; then
    "${PROXY_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  if [[ "$status" -eq 0 ]]; then
    log "all hermetic lifecycle and browser assertions passed"
  else
    log "failed; diagnostics saved under $ARTIFACT_DIR"
  fi

  exit "$status"
}
trap cleanup EXIT INT TERM

if [[ -n "$(docker compose ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse an active relyra-demo project; stop it before running this test"
  exit 1
fi

if [[ -n "$("${SIBLING_STACK[@]}" ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse an active relyra-e2e-sibling project"
  exit 1
fi

if [[ -n "$("${PROXY_COMPOSE[@]}" ps -q traefik 2>/dev/null)" ]]; then
  PROXY_WAS_RUNNING=true
fi

if docker network inspect "$PROXY_NETWORK" >/dev/null 2>&1; then
  NETWORK_WAS_PRESENT=true
fi

log "validating rendered solo and fleet graphs"
solo_json="$(docker compose config --format json)"
jq -e '
  .services.db.ports == null and
  (.services.demo_app.ports | length == 1) and
  .services.demo_app.ports[0].host_ip == "127.0.0.1" and
  .services.demo_app.ports[0].target == 4000
' <<<"$solo_json" >/dev/null

fleet_json="$("${FLEET_COMPOSE[@]}" config --format json)"
jq -e '
  .services.db.ports == null and
  .services.demo_app.ports == null and
  (.services.demo_app.networks | keys | sort) == ["default", "proxy"]
' <<<"$fleet_json" >/dev/null

alternate_json="$({
  RELYRA_HOST=alternate.localhost \
  DEMO_CHECK_ORIGINS='//localhost,//alternate.localhost,//*.alternate.localhost' \
    "${FLEET_COMPOSE[@]}" config --format json
})"
jq -e '
  .services.demo_app.environment.PHX_HOST == "alternate.localhost" and
  .services.demo_app.environment.DEMO_CHECK_ORIGINS == "//localhost,//alternate.localhost,//*.alternate.localhost"
' <<<"$alternate_json" >/dev/null

log "starting the solo stack"
"${SOLO_COMPOSE[@]}" up -d --build --wait
wait_for_http "http://127.0.0.1:4000/setup/sso"

db_id="$(docker compose ps -q db)"
app_id="$(docker compose ps -q demo_app)"
[[ -n "$db_id" && -n "$app_id" ]]
[[ -z "$(docker port "$db_id")" ]]
[[ "$(docker port "$app_id" 4000/tcp)" == "127.0.0.1:4000" ]]

mix_volume="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/root/.mix"}}{{.Name}}{{end}}{{end}}' "$app_id")"
[[ -n "$mix_volume" ]]
docker exec "$app_id" sh -c 'printf phase-69-e2e > /root/.mix/.phase69-fleet-e2e'

log "proving the solo LiveView and public endpoint URLs in Chromium"
BASE_URL="http://localhost:4000" \
EXPECTED_PUBLIC_ORIGIN="http://localhost:4000" \
FLEET_PROXY_REPORT_DIR="playwright-report/fleet-proxy-solo" \
  npx playwright test --config playwright.fleet-proxy.config.mjs

"${SOLO_COMPOSE[@]}" down --remove-orphans
docker volume inspect "$mix_volume" >/dev/null

log "restarting solo mode to prove named-volume persistence"
"${SOLO_COMPOSE[@]}" up -d --wait
app_id="$(docker compose ps -q demo_app)"
docker exec "$app_id" test -f /root/.mix/.phase69-fleet-e2e
"${SOLO_COMPOSE[@]}" down --remove-orphans

if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
  docker network create "$PROXY_NETWORK" >/dev/null
fi

log "starting the shared proxy twice to prove idempotency"
"${PROXY_COMPOSE[@]}" up -d
proxy_id_first="$("${PROXY_COMPOSE[@]}" ps -q traefik)"
[[ -n "$proxy_id_first" ]]
wait_for_http "http://127.0.0.1:8080/dashboard/"
"${PROXY_COMPOSE[@]}" up -d
proxy_id_second="$("${PROXY_COMPOSE[@]}" ps -q traefik)"
[[ "$proxy_id_first" == "$proxy_id_second" ]]

log "starting Relyra and a hermetic sibling behind the shared proxy"
"${FLEET_COMPOSE[@]}" up -d --wait
"${SIBLING_STACK[@]}" up -d --wait
wait_for_http "http://relyra.localhost/setup/sso" --resolve "relyra.localhost:80:127.0.0.1"
wait_for_http "http://sibling.localhost/" --resolve "sibling.localhost:80:127.0.0.1"

log "proving the fleet LiveView and public endpoint URLs in Chromium"
BASE_URL="http://relyra.localhost" \
EXPECTED_PUBLIC_ORIGIN="http://relyra.localhost" \
FLEET_PROXY_REPORT_DIR="playwright-report/fleet-proxy-fleet" \
  npx playwright test --config playwright.fleet-proxy.config.mjs

log "stopping only Relyra and proving shared resources survive"
"${FLEET_COMPOSE[@]}" down --remove-orphans
wait_for_http "http://sibling.localhost/" --resolve "sibling.localhost:80:127.0.0.1"
[[ "$(docker inspect --format '{{.State.Running}}' "$proxy_id_second")" == "true" ]]
docker network inspect "$PROXY_NETWORK" >/dev/null

capture_diagnostics
