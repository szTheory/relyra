#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROXY_NETWORK="${DEMO_PROXY_NETWORK:-proxy}"
COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.proxy.yml --profile keycloak)

log() {
  printf '[keycloak-proxy-e2e] %s\n' "$*"
}

log "validating the proxy-only Keycloak graph"
rendered="$(${COMPOSE[@]} config --format json)"

jq -e '
  .services.keycloak.ports == null and
  (.services.keycloak.networks | keys | sort) == ["default", "proxy"] and
  .services.keycloak.environment.KC_HOSTNAME == "http://keycloak.relyra.localhost" and
  .services.keycloak.environment.KC_PROXY_HEADERS == "xforwarded" and
  (.services.keycloak.healthcheck.test | join(" ") | contains(":9000/health/ready")) and
  any(.services.keycloak.labels[]; contains("relyra-keycloak"))
' <<<"$rendered" >/dev/null

if [[ "${KEYCLOAK_PROXY_STATIC_ONLY:-0}" == "1" ]]; then
  log "static proxy graph assertions passed"
  exit 0
fi

log "the Keycloak proxy lifecycle is not implemented"
exit 1
