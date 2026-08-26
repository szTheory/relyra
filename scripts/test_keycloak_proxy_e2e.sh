#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROXY_NETWORK="${DEMO_PROXY_NETWORK:-proxy}"
PROJECT_NAME="${KEYCLOAK_PROXY_PROJECT_NAME:-relyra-keycloak-e2e-${RANDOM}}"
ARTIFACT_DIR="${KEYCLOAK_PROXY_ARTIFACT_DIR:-playwright-report/keycloak-proxy-diagnostics-${PROJECT_NAME}}"
PUBLIC_HOST="${RELYRA_HOST:-relyra.localhost}"
KEYCLOAK_PUBLIC_HOST="keycloak.${PUBLIC_HOST}"
COMPOSE=(docker compose --project-name "$PROJECT_NAME" -f docker-compose.yml -f docker-compose.proxy.yml --profile keycloak)
ACTIVE_RELYRA_COMPOSE=(docker compose --project-name relyra-demo -f docker-compose.yml -f docker-compose.proxy.yml --profile keycloak)
PROXY_COMPOSE=(docker compose -f docker/traefik/compose.yml)
REALM_PATH="docker/keycloak/realm-demo-app.json"
PROXY_WAS_RUNNING=false
NETWORK_WAS_PRESENT=false
CURRENT_LAYER="setup"
PLAYWRIGHT_TMP_DIR=""

log() {
  printf '[keycloak-proxy-e2e] %s\n' "$*"
}

redact_diagnostics() {
  sed -E \
    -e 's/(KEYCLOAK_SARAH_PASSWORD|KEYCLOAK_ADMIN_PASSWORD|PGPASSWORD|POSTGRES_PASSWORD|password)=([^[:space:]&]+)/\1=[REDACTED]/Ig' \
    -e 's/(SAMLResponse=)[^&[:space:]]+/\1[REDACTED]/Ig' \
    -e 's/(Authorization:|Cookie:).*/\1 [REDACTED]/Ig' \
    -e 's#postgres(ql)?://[^[:space:]]+#postgres://[REDACTED]#Ig' \
    -e 's#.*(<\?xml|<[^>]*(Response|Assertion|EntityDescriptor)|-----BEGIN |-----END ).*#[REDACTED_XML_OR_PEM]#'
}

diagnostics_self_test() {
  local output
  output="$(printf '%s\n' \
    'KEYCLOAK_SARAH_PASSWORD=sarah-password' \
    'SAMLResponse=encoded-assertion' \
    'Authorization: Bearer secret' \
    'Cookie: session=secret' \
    'postgres://postgres:postgres@db/relyra' \
    '<Response>raw assertion</Response>' \
    '-----BEGIN CERTIFICATE-----' | redact_diagnostics)"

  [[ "$output" == *'KEYCLOAK_SARAH_PASSWORD=[REDACTED]'* ]] &&
    [[ "$output" == *'SAMLResponse=[REDACTED]'* ]] &&
    [[ "$output" == *'Authorization: [REDACTED]'* ]] &&
    [[ "$output" == *'Cookie: [REDACTED]'* ]] &&
    [[ "$output" == *'postgres://[REDACTED]'* ]] &&
    [[ "$output" == *'[REDACTED_XML_OR_PEM]'* ]] &&
    ! grep -Eq 'sarah-password|encoded-assertion|Bearer secret|session=secret|postgres:postgres|<Response|BEGIN CERTIFICATE' <<<"$output"

  log "diagnostic redaction self-test passed"
}

artifact_policy_self_test() {
  local playwright_tmp
  local self_test_artifacts

  node --input-type=module <<'NODE'
import config from "./playwright.keycloak-proxy.config.mjs";

const reporterNames = config.reporter.map((reporter) =>
  Array.isArray(reporter) ? reporter[0] : reporter,
);

if (
  config.use.trace !== "off" ||
    config.use.video !== "off" ||
    config.use.screenshot !== "off" ||
    reporterNames.length !== 1 ||
    reporterNames[0] !== "list"
) {
  process.exit(1);
}
NODE

  self_test_artifacts="$(mktemp -d "${TMPDIR:-/tmp}/relyra-keycloak-artifact-self-test.XXXXXX")"
  playwright_tmp="$(mktemp -d "${TMPDIR:-/tmp}/relyra-keycloak-playwright.XXXXXX")"
  mkdir -p "$playwright_tmp/test-results"
  touch "$playwright_tmp/test-results/trace.zip" \
    "$playwright_tmp/test-results/video.webm" \
    "$playwright_tmp/test-results/screenshot.png" \
    "$playwright_tmp/test-results/snapshot.html" \
    "$playwright_tmp/test-results/network.har"

  cleanup_playwright_tmp "$playwright_tmp"
  [[ ! -e "$playwright_tmp" ]]
  [[ -z "$(find "$self_test_artifacts" -mindepth 1 -print -quit)" ]]
  rmdir "$self_test_artifacts"

  log "browser artifact policy self-test passed"
}

cleanup_playwright_tmp() {
  local candidate="${1:-$PLAYWRIGHT_TMP_DIR}"
  local tmp_root="${TMPDIR:-/tmp}"

  [[ -n "$candidate" ]] || return 0
  [[ "$candidate" == "$tmp_root"/relyra-keycloak-playwright.* ]] || {
    log "refusing to remove unexpected Playwright temporary directory"
    return 1
  }
  [[ -d "$candidate" ]] || return 0

  rm -rf -- "$candidate"
  PLAYWRIGHT_TMP_DIR=""
}

capture_diagnostics() {
  mkdir -p "$ARTIFACT_DIR"

  {
    printf 'layer=%s\n' "$CURRENT_LAYER"
    "${COMPOSE[@]}" ps -a
    "${PROXY_COMPOSE[@]}" ps traefik
  } | redact_diagnostics >"$ARTIFACT_DIR/container-state.log" 2>&1 || true

  "${COMPOSE[@]}" logs --no-color | redact_diagnostics >"$ARTIFACT_DIR/relyra.log" 2>&1 || true

  "${COMPOSE[@]}" exec -T demo_app mix run -e '
    import Ecto.Query
    alias LedgerLoop.Repo
    alias Relyra.Ecto.AuditEvent
    actions = Repo.all(from event in AuditEvent, select: {event.domain, event.action}, limit: 20)
    Enum.each(actions, fn {domain, action} -> IO.puts("audit=#{domain}:#{action}") end)
  ' 2>&1 | redact_diagnostics >"$ARTIFACT_DIR/audit-actions.log" || true
}

fail_layer() {
  local layer="$1"
  local detail="$2"
  CURRENT_LAYER="$layer"
  printf '[keycloak-proxy-e2e] layer=%s status=failed detail=%s\n' "$layer" "$detail" >&2
  exit 1
}

run_step() {
  local layer="$1"
  shift
  CURRENT_LAYER="$layer"

  if [[ "${KEYCLOAK_PROXY_FORCE_FAILURE:-}" == "$layer" ]]; then
    fail_layer "$layer" "forced failure"
  fi

  "$@" || fail_layer "$layer" "step failed"
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

render_stack() {
  local host="$1"

  if [[ "$host" == "relyra.localhost" ]]; then
    env -u RELYRA_HOST "${COMPOSE[@]}" config --format json
  else
    RELYRA_HOST="$host" "${COMPOSE[@]}" config --format json
  fi
}

assert_rendered_stack() {
  local host="$1"
  local rendered
  rendered="$(render_stack "$host")"

  jq -e --arg host "$host" '
    .services.keycloak.ports == null and
    (.services.keycloak.networks | keys | sort) == ["default", "proxy"] and
    .services.keycloak.environment.KC_HOSTNAME == ("http://keycloak." + $host) and
    .services.keycloak.environment.KC_PROXY_HEADERS == "xforwarded" and
    (.services.keycloak.environment | has("KC_HOSTNAME_STRICT") | not) and
    (.services.keycloak.healthcheck.test | join(" ") | contains("/dev/tcp/localhost/9000")) and
    .services.keycloak.labels["traefik.http.routers.relyra-keycloak.rule"] == ("Host(`keycloak." + $host + "`)") and
    .services.keycloak.labels["traefik.http.routers.relyra-keycloak.service"] == "relyra-keycloak" and
    .services.keycloak.labels["traefik.http.services.relyra-keycloak.loadbalancer.server.port"] == "8080" and
    ([.services.keycloak.labels | to_entries[] | (.key + "=" + (.value | tostring))] | join("\\n") | contains("9000") | not) and
    ([.services.keycloak.environment | to_entries[] | (.key + "=" + (.value | tostring))] | join("\\n") | test("KC_PROXY=(edge|reencrypt|passthrough)"; "i") | not) and
    ([.services.keycloak.environment | to_entries[] | (.key + "=" + (.value | tostring))] | join("\\n") | contains("localhost:8080") | not) and
    (.services.keycloak_provisioner.networks | keys | sort) == ["default"]
  ' <<<"$rendered" >/dev/null
}

assert_realm_contract() {
  local host="$1"
  local acs="http://${host}/saml/01H0B4Y1A2B3C4D5E6F7G8H9J4/acs"
  local metadata="http://${host}/saml/01H0B4Y1A2B3C4D5E6F7G8H9J4/metadata"

  jq -e --arg host "$host" --arg acs "$acs" --arg metadata "$metadata" '
    .clients[0] as $client |
    ($client | tojson | gsub("\\$\\{RELYRA_HOST\\}"; $host)) as $rendered_client |
    ($client.clientId | gsub("\\$\\{RELYRA_HOST\\}"; $host)) == $metadata and
    ($client.rootUrl | gsub("\\$\\{RELYRA_HOST\\}"; $host)) == ("http://" + $host) and
    ($client.baseUrl | gsub("\\$\\{RELYRA_HOST\\}"; $host)) == ("http://" + $host) and
    ($client.adminUrl | gsub("\\$\\{RELYRA_HOST\\}"; $host)) == $acs and
    ($client.redirectUris | map(gsub("\\$\\{RELYRA_HOST\\}"; $host))) == [$acs] and
    ($client.webOrigins | map(gsub("\\$\\{RELYRA_HOST\\}"; $host))) == [("http://" + $host)] and
    ($client.attributes["saml.assertion.consumer.url.post"] | gsub("\\$\\{RELYRA_HOST\\}"; $host)) == $acs and
    ($rendered_client | test("localhost:8080|localhost:4000|demo_app:4000|/saml/sso/acs|/auth/saml") | not)
  ' "$REALM_PATH" >/dev/null
}

log "validating default and RELYRA_HOST-overridden proxy contracts"
for host in relyra.localhost phase70.example.local; do
  assert_rendered_stack "$host"
  assert_realm_contract "$host"
done

if [[ "${KEYCLOAK_PROXY_STATIC_ONLY:-0}" == "1" ]]; then
  log "static proxy graph assertions passed"
  exit 0
fi

if [[ "${KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST:-0}" == "1" ]]; then
  diagnostics_self_test
  exit 0
fi

if [[ "${KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST:-0}" == "1" ]]; then
  artifact_policy_self_test
  exit 0
fi

# This deterministic path exercises a layer classification without acquiring
# Docker resources, which keeps the diagnostics proof hermetic and fast.
if [[ -n "${KEYCLOAK_PROXY_FORCE_FAILURE:-}" ]]; then
  run_step "$KEYCLOAK_PROXY_FORCE_FAILURE" true
fi

run_step fake_idp_regression bash -c \
  'cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs --warnings-as-errors'

[[ "$PROJECT_NAME" == relyra-keycloak-e2e-* ]] || {
  log "refusing non-owned Compose project name: $PROJECT_NAME"
  exit 1
}

cleanup() {
  local result_code=$?
  trap - EXIT INT TERM

  cleanup_playwright_tmp || result_code=1

  if [[ "$result_code" -ne 0 ]]; then
    capture_diagnostics
  fi

  # This project name is generated per run.  Removing its volumes forces a
  # fresh Keycloak realm import without touching a shared proxy or another
  # Relyra stack.
  "${COMPOSE[@]}" down --remove-orphans --volumes >/dev/null 2>&1 || true

  if [[ "$PROXY_WAS_RUNNING" == "false" ]]; then
    "${PROXY_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  fi

  if [[ "$NETWORK_WAS_PRESENT" == "false" ]]; then
    docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  fi

  exit "$result_code"
}
trap cleanup EXIT INT TERM

if [[ -n "$("${ACTIVE_RELYRA_COMPOSE[@]}" ps -aq 2>/dev/null)" ]]; then
  log "refusing to reuse an active relyra-demo project; stop it before running this test"
  exit 1
fi

# Remove only a prior run under this harness's reserved project namespace.
# This forces --import-realm to create the current realm contract rather than
# accepting stale Keycloak state from an older proof run.
"${COMPOSE[@]}" down --remove-orphans --volumes >/dev/null 2>&1 || true

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

run_step proxy_dns wait_for_http "http://${PUBLIC_HOST}/readyz" --resolve "${PUBLIC_HOST}:80:127.0.0.1"
run_step keycloak_readiness "${COMPOSE[@]}" exec -T keycloak bash -c \
  "{ printf 'HEAD /health/ready HTTP/1.0\\r\\n\\r\\n' >&0; grep -q 'HTTP/1.0 200'; } 0<>/dev/tcp/localhost/9000"
run_step realm_contract "${COMPOSE[@]}" exec -T demo_app sh -c \
  "curl -fsS http://keycloak:8080/realms/demo-app/protocol/saml/descriptor | grep -F 'entityID=\"http://${KEYCLOAK_PUBLIC_HOST}/realms/demo-app\"' >/dev/null"
run_step descriptor_trust "${COMPOSE[@]}" wait keycloak_provisioner

PLAYWRIGHT_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/relyra-keycloak-playwright.XXXXXX")"

run_step browser_authentication env \
  BASE_URL="http://${PUBLIC_HOST}" \
  KEYCLOAK_SARAH_PASSWORD="${KEYCLOAK_SARAH_PASSWORD:-sarah-password}" \
  KEYCLOAK_PROXY_PLAYWRIGHT_TMP_DIR="$PLAYWRIGHT_TMP_DIR" \
  npx playwright test --config playwright.keycloak-proxy.config.mjs

cleanup_playwright_tmp

run_step acs_validation "${COMPOSE[@]}" exec -T demo_app mix run -e '
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

run_step user_mapping "${COMPOSE[@]}" exec -T demo_app mix run -e '
  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.LoginReceipt
  count = Repo.aggregate(LoginReceipt, :count, :id)
  IO.puts("mapped_receipt_count=#{count}")
  unless count == 1, do: System.halt(1)
'

run_step session_receipt "${COMPOSE[@]}" exec -T demo_app mix run -e '
  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.LoginReceipt
  case Repo.one(LoginReceipt) do
    nil -> System.halt(1)
    _receipt -> IO.puts("session_receipt=present")
  end
'

run_step focused_demo_tests bash -c \
  'cd demo/ledger_loop && mix test test/ledger_loop/demo/keycloak_provisioner_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs test/ledger_loop_web/controllers/page_controller_test.exs --warnings-as-errors'
run_step root_warnings_as_errors mix test --warnings-as-errors
run_step root_qa mix qa
run_step root_security mix ci.security
run_step root_format mix format --check-formatted

log "verified signed ACS, workspace return, durable receipt, and canonical validation/signature/replay trace"
