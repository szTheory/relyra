#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROXY_NETWORK="${DEMO_PROXY_NETWORK:-proxy}"
SIBLING_COMPOSE="test/integration/fleet-proxy-sibling.compose.yml"
RUN_SUFFIX="${GITHUB_RUN_ID:-local}-a${GITHUB_RUN_ATTEMPT:-1}-p$$"
SOLO_PROJECT="relyra-fleet-solo-$RUN_SUFFIX"
FLEET_PROJECT="relyra-fleet-app-$RUN_SUFFIX"
PROXY_PROJECT="relyra-fleet-proxy-$RUN_SUFFIX"
SIBLING_PROJECT="relyra-fleet-sibling-$RUN_SUFFIX"
PROXY_OWNED=true
STATUS_PATH="${FLEET_PROXY_STATUS_PATH:-}"
STATUS_PHASE="setup"
STATUS_CHECKS_PASSED=0
PLAYWRIGHT_TMP_DIR=""
NETWORK_WAS_PRESENT=false
NETWORK_CREATED=false

log() {
  printf '[fleet-proxy-e2e] %s\n' "$*"
}

solo_compose() {
  COMPOSE_PROJECT_NAME="$SOLO_PROJECT" docker compose "$@"
}

fleet_compose() {
  COMPOSE_PROJECT_NAME="$FLEET_PROJECT" \
    DEMO_PROXY_NETWORK="$PROXY_NETWORK" \
    docker compose -f docker-compose.yml -f docker-compose.proxy.yml "$@"
}

proxy_compose() {
  COMPOSE_PROJECT_NAME="$PROXY_PROJECT" \
    DEMO_PROXY_NETWORK="$PROXY_NETWORK" \
    docker compose -f docker/traefik/compose.yml "$@"
}

sibling_compose() {
  COMPOSE_PROJECT_NAME="$SIBLING_PROJECT" \
    DEMO_PROXY_NETWORK="$PROXY_NETWORK" \
    docker compose -f "$SIBLING_COMPOSE" "$@"
}

status_path_is_safe() {
  local runner_temp="${RUNNER_TEMP:-}"
  local canonical_runner_temp

  [[ -n "$STATUS_PATH" && -n "$runner_temp" ]] || return 1
  [[ -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  canonical_runner_temp="$(CDPATH='' cd -P -- "$runner_temp" && pwd)" || return 1
  [[ "$STATUS_PATH" == "$canonical_runner_temp/relyra-fleet-proxy-status.json" ]]
}

write_status() {
  local original_status="$1"
  local outcome="passed"
  local failure_category="none"
  local checks_failed=0
  local run_id
  local temporary_file
  local byte_count

  [[ "$original_status" -eq 0 ]] || checks_failed=1

  case "$original_status" in
    0)
      ;;
    130|143)
      outcome="cancelled"
      failure_category="cancelled"
      ;;
    124)
      outcome="failed"
      failure_category="timeout"
      ;;
    *)
      outcome="failed"
      if [[ "$STATUS_PHASE" == "setup" ]]; then
        failure_category="setup"
      else
        failure_category="assertion"
      fi
      ;;
  esac

  [[ "${GITHUB_ACTIONS:-}" == "true" ]] || return 0
  status_path_is_safe || return 1
  [[ "$STATUS_PHASE" =~ ^(setup|solo|proxy|fleet|complete)$ ]] || return 1
  [[ "$STATUS_CHECKS_PASSED" =~ ^[0-9]{1,2}$ ]] || return 1
  (( STATUS_CHECKS_PASSED <= 12 )) || return 1

  run_id="$(od -An -N8 -tx1 /dev/urandom | tr -d '[:space:]')" || return 1
  [[ "$run_id" =~ ^[a-f0-9]{16}$ ]] || return 1
  temporary_file="$(umask 077; mktemp "$RUNNER_TEMP/.relyra-fleet-proxy-status.XXXXXX")" || return 1

  if ! printf '{"schema_version":1,"owner":"fleet-proxy-e2e","run_id":"%s","phase":"%s","outcome":"%s","failure_category":"%s","checks_passed":%s,"checks_failed":%s}\n' \
    "$run_id" "$STATUS_PHASE" "$outcome" "$failure_category" \
    "$STATUS_CHECKS_PASSED" "$checks_failed" >"$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi

  byte_count="$(wc -c <"$temporary_file")" || {
    rm -f -- "$temporary_file"
    return 1
  }
  (( byte_count > 0 && byte_count <= 512 )) || {
    rm -f -- "$temporary_file"
    return 1
  }
  if ! mv -f -- "$temporary_file" "$STATUS_PATH"; then
    rm -f -- "$temporary_file"
    return 1
  fi
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

cleanup() {
  local status="$1"
  local final_status="$status"

  trap - EXIT HUP INT TERM

  sibling_compose down --remove-orphans --volumes >/dev/null 2>&1 || true
  fleet_compose down --remove-orphans --volumes >/dev/null 2>&1 || true
  solo_compose down --remove-orphans --volumes >/dev/null 2>&1 || true
  if [[ "$PROXY_OWNED" == "true" ]]; then
    proxy_compose down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_CREATED" == "true" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  if [[ -n "$PLAYWRIGHT_TMP_DIR" && -d "$PLAYWRIGHT_TMP_DIR" && ! -L "$PLAYWRIGHT_TMP_DIR" ]]; then
    rm -rf -- "$PLAYWRIGHT_TMP_DIR"
  fi

  if [[ "$status" -eq 0 ]]; then
    STATUS_PHASE="complete"
  fi

  if ! write_status "$status"; then
    printf '%s\n' "fleet_proxy_status_receipt_write_failed: bounded status receipt could not be written." >&2
    [[ "$final_status" -ne 0 ]] || final_status=1
  fi

  if [[ "$status" -eq 0 ]]; then
    log "all hermetic lifecycle and browser assertions passed"
  else
    log "failed; bounded status receipt records phase $STATUS_PHASE"
  fi

  exit "$final_status"
}
trap 'cleanup $?' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  if ! status_path_is_safe; then
    printf '%s\n' "fleet_proxy_status_path_invalid: required status path is outside RUNNER_TEMP." >&2
    exit 1
  fi
  rm -f -- "$STATUS_PATH"
fi

TMP_PARENT="${TMPDIR:-/tmp}"
TMP_PARENT="${TMP_PARENT%/}"
TMP_PARENT_CANONICAL="$(CDPATH='' cd -P -- "$TMP_PARENT" && pwd)"
PLAYWRIGHT_TMP_DIR="$(umask 077; mktemp -d "$TMP_PARENT_CANONICAL/relyra-fleet-proxy.XXXXXX")"
[[ -n "$PLAYWRIGHT_TMP_DIR" && ! -L "$PLAYWRIGHT_TMP_DIR" ]]

if COMPOSE_PROJECT_NAME=dev_proxy docker compose -f docker/traefik/compose.yml ps -q traefik 2>/dev/null | grep -q .; then
  PROXY_PROJECT="dev_proxy"
  PROXY_OWNED=false
fi

if docker network inspect "$PROXY_NETWORK" >/dev/null 2>&1; then
  NETWORK_WAS_PRESENT=true
fi

log "validating rendered solo and fleet graphs"
solo_json="$(solo_compose config --format json)"
jq -e '
  .services.db.ports == null and
  (.services.demo_app.ports | length == 1) and
  .services.demo_app.ports[0].host_ip == "127.0.0.1" and
  .services.demo_app.ports[0].target == 4000
' <<<"$solo_json" >/dev/null

fleet_json="$(fleet_compose config --format json)"
jq -e '
  .services.db.ports == null and
  .services.demo_app.ports == null and
  (.services.demo_app.networks | keys | sort) == ["default", "proxy"]
' <<<"$fleet_json" >/dev/null

alternate_json="$({
  RELYRA_HOST=alternate.localhost \
  DEMO_CHECK_ORIGINS='//localhost,//alternate.localhost,//*.alternate.localhost' \
    fleet_compose config --format json
})"
jq -e '
  .services.demo_app.environment.PHX_HOST == "alternate.localhost" and
  .services.demo_app.environment.DEMO_CHECK_ORIGINS == "//localhost,//alternate.localhost,//*.alternate.localhost"
' <<<"$alternate_json" >/dev/null
STATUS_CHECKS_PASSED=1
STATUS_PHASE="solo"

log "starting the solo stack"
solo_compose up -d --build --wait
wait_for_http "http://127.0.0.1:4000/setup/sso"

db_id="$(solo_compose ps -q db)"
app_id="$(solo_compose ps -q demo_app)"
[[ -n "$db_id" && -n "$app_id" ]]
[[ -z "$(docker port "$db_id")" ]]
[[ "$(docker port "$app_id" 4000/tcp)" == "127.0.0.1:4000" ]]

mix_volume="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/root/.mix"}}{{.Name}}{{end}}{{end}}' "$app_id")"
[[ -n "$mix_volume" ]]
docker exec "$app_id" sh -c 'printf phase-69-e2e > /root/.mix/.phase69-fleet-e2e'

log "proving the solo LiveView and public endpoint URLs in Chromium"
BASE_URL="http://localhost:4000" \
EXPECTED_PUBLIC_ORIGIN="http://localhost:4000" \
FLEET_PROXY_OUTPUT_DIR="$PLAYWRIGHT_TMP_DIR/output-solo" \
  npx playwright test --config playwright.fleet-proxy.config.mjs

solo_compose down --remove-orphans
docker volume inspect "$mix_volume" >/dev/null

log "restarting solo mode to prove named-volume persistence"
solo_compose up -d --wait
app_id="$(solo_compose ps -q demo_app)"
docker exec "$app_id" test -f /root/.mix/.phase69-fleet-e2e
solo_compose down --remove-orphans
STATUS_CHECKS_PASSED=4
STATUS_PHASE="proxy"

if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
  docker network create "$PROXY_NETWORK" >/dev/null
  NETWORK_CREATED=true
fi

log "starting the shared proxy twice to prove idempotency"
proxy_compose up -d
proxy_id_first="$(proxy_compose ps -q traefik)"
[[ -n "$proxy_id_first" ]]
wait_for_http "http://127.0.0.1:8080/dashboard/"
proxy_compose up -d
proxy_id_second="$(proxy_compose ps -q traefik)"
[[ "$proxy_id_first" == "$proxy_id_second" ]]
STATUS_CHECKS_PASSED=6
STATUS_PHASE="fleet"

log "starting Relyra and a hermetic sibling behind the shared proxy"
fleet_compose up -d --wait
sibling_compose up -d --wait
wait_for_http "http://relyra.localhost/setup/sso" --resolve "relyra.localhost:80:127.0.0.1"
wait_for_http "http://sibling.localhost/" --resolve "sibling.localhost:80:127.0.0.1"

log "proving the fleet LiveView and public endpoint URLs in Chromium"
BASE_URL="http://relyra.localhost" \
EXPECTED_PUBLIC_ORIGIN="http://relyra.localhost" \
FLEET_PROXY_OUTPUT_DIR="$PLAYWRIGHT_TMP_DIR/output-fleet" \
  npx playwright test --config playwright.fleet-proxy.config.mjs

log "stopping only Relyra and proving shared resources survive"
fleet_compose down --remove-orphans
wait_for_http "http://sibling.localhost/" --resolve "sibling.localhost:80:127.0.0.1"
[[ "$(docker inspect --format '{{.State.Running}}' "$proxy_id_second")" == "true" ]]
docker network inspect "$PROXY_NETWORK" >/dev/null

STATUS_CHECKS_PASSED=8
