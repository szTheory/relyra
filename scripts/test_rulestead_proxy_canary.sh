#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
RULESTEAD_DIR="${RULESTEAD_DIR:-$ROOT_DIR/rulestead}"
PROXY_NETWORK="proxy"
RUN_SUFFIX="${GITHUB_RUN_ID:-local}-a${GITHUB_RUN_ATTEMPT:-1}-p$$"
RULESTEAD_PROJECT="relyra-rulestead-canary-$RUN_SUFFIX"
FLEET_PROJECT="relyra-rulestead-fleet-$RUN_SUFFIX"
PROXY_PROJECT="relyra-rulestead-proxy-$RUN_SUFFIX"
PROXY_OWNED=true
STATUS_PATH="${RULESTEAD_CANARY_STATUS_PATH:-}"
STATUS_PHASE="setup"
STATUS_CHECKS_PASSED=0
NETWORK_CREATED=false

cd "$ROOT_DIR"

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

status_path_is_safe() {
  local runner_temp="${RUNNER_TEMP:-}"
  local canonical_runner_temp

  [[ -n "$STATUS_PATH" && -n "$runner_temp" ]] || return 1
  [[ -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  canonical_runner_temp="$(CDPATH='' cd -P -- "$runner_temp" && pwd)" || return 1
  [[ "$STATUS_PATH" == "$canonical_runner_temp/relyra-rulestead-canary-status.json" ]]
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
  [[ "$STATUS_PHASE" =~ ^(setup|proxy|relyra|rulestead|complete)$ ]] || return 1
  [[ "$STATUS_CHECKS_PASSED" =~ ^[0-9]{1,2}$ ]] || return 1
  (( STATUS_CHECKS_PASSED <= 12 )) || return 1

  run_id="$(od -An -N8 -tx1 /dev/urandom | tr -d '[:space:]')" || return 1
  [[ "$run_id" =~ ^[a-f0-9]{16}$ ]] || return 1
  temporary_file="$(umask 077; mktemp "$RUNNER_TEMP/.relyra-rulestead-canary-status.XXXXXX")" || return 1

  if ! printf '{"schema_version":1,"owner":"rulestead-main-canary","run_id":"%s","phase":"%s","outcome":"%s","failure_category":"%s","checks_passed":%s,"checks_failed":%s}\n' \
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

cleanup() {
  local status="$1"
  local final_status="$status"

  trap - EXIT HUP INT TERM

  rulestead_compose down --remove-orphans --volumes >/dev/null 2>&1 || true
  fleet_compose down --remove-orphans >/dev/null 2>&1 || true

  if [[ "$PROXY_OWNED" == "true" ]]; then
    proxy_compose down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_CREATED" == "true" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  if [[ "$status" -eq 0 ]]; then
    STATUS_PHASE="complete"
  fi

  if ! write_status "$status"; then
    printf '%s\n' "rulestead_canary_status_receipt_write_failed: bounded status receipt could not be written." >&2
    [[ "$final_status" -ne 0 ]] || final_status=1
  fi

  if [[ "$status" -eq 0 ]]; then
    log "Relyra and Rulestead main coexistence assertions passed"
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
    printf '%s\n' "rulestead_canary_status_path_invalid: required status path is outside RUNNER_TEMP." >&2
    exit 1
  fi
  rm -f -- "$STATUS_PATH"
fi

if [[ ! -x "$RULESTEAD_DIR/scripts/demo/proxy-up.sh" ]]; then
  log "Rulestead checkout not found at $RULESTEAD_DIR"
  exit 1
fi

if COMPOSE_PROJECT_NAME=dev_proxy docker compose -f docker/traefik/compose.yml ps -q traefik 2>/dev/null | grep -q .; then
  PROXY_PROJECT="dev_proxy"
  PROXY_OWNED=false
fi

if ! docker network inspect "$PROXY_NETWORK" >/dev/null 2>&1; then
  docker network create "$PROXY_NETWORK" >/dev/null
  NETWORK_CREATED=true
fi

log "starting Relyra with the shared proxy"
STATUS_PHASE="proxy"
proxy_compose up -d
proxy_id="$(proxy_compose ps -q traefik)"
[[ -n "$proxy_id" ]]
STATUS_PHASE="relyra"
fleet_compose up -d --build --wait

log "starting the checked-out Rulestead main demo against the same proxy"
(
  cd "$RULESTEAD_DIR"
  COMPOSE_PROJECT_NAME="$RULESTEAD_PROJECT" \
  DEMO_PROXY_NETWORK="$PROXY_NETWORK" \
  DEMO_PROXY_PROJECT_NAME="$PROXY_PROJECT" \
  DEMO_PROXY_HTTP_PORT=80 \
  DEMO_HOST_SLUG=local \
    scripts/demo/proxy-up.sh
)

wait_for_health backend
wait_for_health frontend
wait_for_route relyra.localhost /setup/sso "SSO Setup"
STATUS_CHECKS_PASSED=4
STATUS_PHASE="rulestead"
wait_for_route rulestead.localhost / "Rulestead"
wait_for_route fleetdesk.rulestead.localhost / "FleetDesk"

log "stopping only Relyra and proving Rulestead remains routed"
fleet_compose down --remove-orphans --volumes
wait_for_route rulestead.localhost / "Rulestead"
wait_for_route fleetdesk.rulestead.localhost / "FleetDesk"
[[ "$(docker inspect --format '{{.State.Running}}' "$proxy_id")" == "true" ]]
docker network inspect "$PROXY_NETWORK" >/dev/null

STATUS_CHECKS_PASSED=8
