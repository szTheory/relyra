#!/usr/bin/env bash
# stress_keycloak_lane.sh — repeat the external IdP adoption lane to detect flakes.
#
# Usage:
#   export KEYCLOAK_BASE_URL=http://localhost:8080
#   ./scripts/stress_keycloak_lane.sh [iterations]
#
# Requires Keycloak running (see docker/keycloak/README.md).

set -euo pipefail

ITERATIONS="${1:-20}"

if [[ -z "${KEYCLOAK_BASE_URL:-}" ]]; then
  echo "KEYCLOAK_BASE_URL is required (e.g. http://localhost:8080)" >&2
  exit 1
fi

export MIX_ENV=test

echo "Stressing mix ci.external_idp ${ITERATIONS} times against ${KEYCLOAK_BASE_URL}..."

for i in $(seq 1 "$ITERATIONS"); do
  echo "==> iteration ${i}/${ITERATIONS}"
  mix run --no-start -e '
    base = System.fetch_env!("KEYCLOAK_BASE_URL")
    Relyra.TestSupport.KeycloakAdoption.wait_for_sso_login_surface!(base)
  '
  mix ci.external_idp
done

echo "OK: ${ITERATIONS}/${ITERATIONS} external IdP runs passed."
