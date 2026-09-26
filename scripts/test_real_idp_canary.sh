#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -P -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CANARY_STATUS="configuration_incomplete"
PLAYWRIGHT_TMP_DIR=""
PLAYWRIGHT_RESULT_PATH=""
CANARY_STATUS_PATH=""
CONTRACT_TMP_DIR=""

canary_runner_temp() {
  local runner_temp="${RUNNER_TEMP:-}"
  local canonical

  [[ -n "$runner_temp" && -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  canonical="$(CDPATH='' cd -P -- "$runner_temp" && pwd)" || return 1
  [[ "$runner_temp" == "$canonical" ]] || return 1
  CANARY_STATUS_PATH="$canonical/relyra-real-idp-canary-status.json"
}

safe_label() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._@/-]{0,119}$ ]]
}

safe_person_name() {
  local pattern='^[A-Za-z0-9][A-Za-z0-9 ._@/-]{0,79}$'
  [[ "$1" =~ $pattern ]]
}

artifact_value() {
  local value="$1"
  local kind="$2"

  if [[ "$kind" == "person" ]]; then
    if safe_person_name "$value"; then
      printf '%s' "$value"
    else
      printf '%s' "unconfigured"
    fi
  else
    if safe_label "$value"; then
      printf '%s' "$value"
    else
      printf '%s' "unconfigured"
    fi
  fi
}

write_canary_status() {
  local requested_status="$1"
  local temporary_file
  local run_id
  local provider_alias
  local owner
  local credential_owner
  local responder
  local recovery_reference
  local timestamp

  case "$requested_status" in
    configuration_incomplete|unexpected_origin|idp_rejected|callback_failure|provider_failure|passed) ;;
    *) requested_status="provider_failure" ;;
  esac

  canary_runner_temp || return 1
  if [[ -e "$CANARY_STATUS_PATH" || -L "$CANARY_STATUS_PATH" ]]; then
    [[ -f "$CANARY_STATUS_PATH" && ! -L "$CANARY_STATUS_PATH" ]] || return 1
  fi

  run_id="${GITHUB_RUN_ID:-local}"
  [[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || run_id="local"
  provider_alias="$(artifact_value "${REAL_IDP_CANARY_PROVIDER_ALIAS:-}" label)"
  owner="$(artifact_value "${REAL_IDP_CANARY_OWNER:-}" person)"
  credential_owner="$(artifact_value "${REAL_IDP_CANARY_CREDENTIAL_OWNER:-}" person)"
  responder="$(artifact_value "${REAL_IDP_CANARY_RESPONDER:-}" person)"
  recovery_reference="$(artifact_value "${REAL_IDP_CANARY_RUNBOOK:-}" label)"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  temporary_file="$(umask 077; mktemp "$RUNNER_TEMP/.relyra-real-idp-canary-status.XXXXXX")" || return 1

  if ! printf '{"schema_version":1,"status":"%s","timestamp":"%s","run_id":"%s","provider_alias":"%s","owner":"%s","credential_owner":"%s","responder":"%s","recovery_reference":"%s"}\n' \
    "$requested_status" "$timestamp" "$run_id" "$provider_alias" "$owner" \
    "$credential_owner" "$responder" "$recovery_reference" > "$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi

  if ! mv -f -- "$temporary_file" "$CANARY_STATUS_PATH"; then
    rm -f -- "$temporary_file"
    return 1
  fi
}

cleanup() {
  local original_exit="$1"
  local final_exit="$original_exit"

  trap - EXIT HUP INT TERM

  if ! write_canary_status "$CANARY_STATUS"; then
    printf '%s\n' "real IdP canary status artifact could not be written safely." >&2
    [[ "$final_exit" -ne 0 ]] || final_exit=1
  fi

  if [[ -n "$PLAYWRIGHT_TMP_DIR" && -d "$PLAYWRIGHT_TMP_DIR" && ! -L "$PLAYWRIGHT_TMP_DIR" ]]; then
    rm -rf -- "$PLAYWRIGHT_TMP_DIR"
  fi

  printf 'real IdP canary status: %s\n' "$CANARY_STATUS"
  exit "$final_exit"
}

assert_probe_artifact() {
  local path="$1"
  local expected_status="$2"
  local expected_run_id="$3"

  node - "$path" "$expected_status" "$expected_run_id" <<'NODE'
const fs = require("node:fs");
const path = process.argv[2];
const expectedStatus = process.argv[3];
const expectedRunId = process.argv[4];
const raw = fs.readFileSync(path, "utf8");
const value = JSON.parse(raw);
const expectedKeys = [
  "schema_version",
  "status",
  "timestamp",
  "run_id",
  "provider_alias",
  "owner",
  "credential_owner",
  "responder",
  "recovery_reference",
].sort();
if (JSON.stringify(Object.keys(value).sort()) !== JSON.stringify(expectedKeys)) process.exit(1);
if (value.schema_version !== 1 || value.status !== expectedStatus || value.run_id !== expectedRunId) process.exit(1);
if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(value.timestamp)) process.exit(1);
if (Object.entries(value).some(([key, item]) => key !== "schema_version" && typeof item !== "string")) process.exit(1);
if (/https?:\/\/|[?&]/i.test(raw)) process.exit(1);
NODE
}

run_contract_probe() {
  local missing_temp
  local provider_temp
  local missing_status
  local provider_status
  local missing_exit
  local provider_exit

  local tmp_parent="${TMPDIR:-/tmp}"
  tmp_parent="$(CDPATH='' cd -P -- "$tmp_parent" && pwd)"
  CONTRACT_TMP_DIR="$(umask 077; mktemp -d "$tmp_parent/relyra-real-idp-contract.XXXXXX")"
  trap 'rm -rf -- "$CONTRACT_TMP_DIR"' EXIT HUP INT TERM
  missing_temp="$CONTRACT_TMP_DIR/missing"
  provider_temp="$CONTRACT_TMP_DIR/provider"
  mkdir -m 700 -- "$missing_temp" "$provider_temp"
  missing_status="$missing_temp/relyra-real-idp-canary-status.json"
  provider_status="$provider_temp/relyra-real-idp-canary-status.json"

  set +e
  env -i "PATH=$PATH" "RUNNER_TEMP=$missing_temp" "GITHUB_RUN_ID=contract-missing" \
    bash "$0" --contract-case missing > "$CONTRACT_TMP_DIR/missing.log" 2>&1
  missing_exit=$?
  env -i "PATH=$PATH" "RUNNER_TEMP=$provider_temp" "GITHUB_RUN_ID=contract-provider" \
    "REAL_IDP_CANARY_PROVIDER_ALIAS=contract-probe" \
    "REAL_IDP_CANARY_OWNER=Contract Owner" \
    "REAL_IDP_CANARY_CREDENTIAL_OWNER=Rotation Owner" \
    "REAL_IDP_CANARY_RESPONDER=Canary Responder" \
    "REAL_IDP_CANARY_RUNBOOK=docs/runbooks/real-idp-canary" \
    bash "$0" --contract-case provider-failure > "$CONTRACT_TMP_DIR/provider.log" 2>&1
  provider_exit=$?
  set -e

  [[ "$missing_exit" -eq 2 && "$provider_exit" -eq 23 ]] || return 1
  assert_probe_artifact "$missing_status" "configuration_incomplete" "contract-missing" || return 1
  assert_probe_artifact "$provider_status" "provider_failure" "contract-provider" || return 1
  grep -Fq 'real IdP canary status: configuration_incomplete' "$CONTRACT_TMP_DIR/missing.log" || return 1
  grep -Fq 'real IdP canary status: provider_failure' "$CONTRACT_TMP_DIR/provider.log" || return 1
  printf '%s\n' "real IdP canary contract probe passed (missing configuration and simulated provider failure)."
}

if [[ "${1:-}" == "--contract-probe" ]]; then
  run_contract_probe
  exit $?
fi

if [[ "${1:-}" == "--contract-case" ]]; then
  case "${2:-}" in
    missing)
      CANARY_STATUS="configuration_incomplete"
      trap 'cleanup 2' EXIT
      exit 2
      ;;
    provider-failure)
      CANARY_STATUS="provider_failure"
      trap 'cleanup 23' EXIT
      exit 23
      ;;
    *)
      printf '%s\n' "unsupported canary contract case." >&2
      exit 64
      ;;
  esac
fi

trap 'cleanup $?' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

required_vars=(
  REAL_IDP_CANARY_SP_LOGIN_URL
  REAL_IDP_CANARY_SP_ORIGIN
  REAL_IDP_CANARY_IDP_ORIGIN
  REAL_IDP_CANARY_PROVIDER_ALIAS
  REAL_IDP_CANARY_USERNAME
  REAL_IDP_CANARY_PASSWORD
  REAL_IDP_CANARY_OWNER
  REAL_IDP_CANARY_CREDENTIAL_OWNER
  REAL_IDP_CANARY_RESPONDER
  REAL_IDP_CANARY_RUNBOOK
  REAL_IDP_CANARY_USER_SELECTOR
  REAL_IDP_CANARY_PASSWORD_SELECTOR
  REAL_IDP_CANARY_SUBMIT_SELECTOR
)
missing_configuration=0
for name in "${required_vars[@]}"; do
  [[ -n "${!name:-}" ]] || missing_configuration=1
done

if [[ "$missing_configuration" -ne 0 ]]; then
  CANARY_STATUS="configuration_incomplete"
  printf '%s\n' "real IdP canary configuration is incomplete; the scheduled provider-health check did not run." >&2
  exit 2
fi

if ! safe_label "$REAL_IDP_CANARY_PROVIDER_ALIAS" ||
  ! safe_person_name "$REAL_IDP_CANARY_OWNER" ||
  ! safe_person_name "$REAL_IDP_CANARY_CREDENTIAL_OWNER" ||
  ! safe_person_name "$REAL_IDP_CANARY_RESPONDER" ||
  ! safe_label "$REAL_IDP_CANARY_RUNBOOK" ||
  ! [[ "${GITHUB_RUN_ID:-local}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] ||
  ! [[ "$REAL_IDP_CANARY_USER_SELECTOR" =~ ^([#.]?[A-Za-z][A-Za-z0-9_-]*|\[name=[A-Za-z][A-Za-z0-9_-]*\])$ ]] ||
  ! [[ "$REAL_IDP_CANARY_PASSWORD_SELECTOR" =~ ^([#.]?[A-Za-z][A-Za-z0-9_-]*|\[name=[A-Za-z][A-Za-z0-9_-]*\])$ ]] ||
  ! [[ "$REAL_IDP_CANARY_SUBMIT_SELECTOR" =~ ^([#.]?[A-Za-z][A-Za-z0-9_-]*|\[name=[A-Za-z][A-Za-z0-9_-]*\])$ ]]; then
  CANARY_STATUS="configuration_incomplete"
  printf '%s\n' "real IdP canary configuration contains an invalid allowlisted value." >&2
  exit 2
fi

set +e
node <<'NODE'
const invalid = () => process.exit(10);
const unexpectedOrigin = () => process.exit(20);
let login;
let sp;
let idp;
try {
  login = new URL(process.env.REAL_IDP_CANARY_SP_LOGIN_URL);
  sp = new URL(process.env.REAL_IDP_CANARY_SP_ORIGIN);
  idp = new URL(process.env.REAL_IDP_CANARY_IDP_ORIGIN);
} catch {
  invalid();
}
if ([login, sp, idp].some((url) => url.protocol !== "https:" || url.username || url.password || url.hash)) invalid();
if (sp.origin !== process.env.REAL_IDP_CANARY_SP_ORIGIN || sp.pathname !== "/" || sp.search) invalid();
if (idp.origin !== process.env.REAL_IDP_CANARY_IDP_ORIGIN || idp.pathname !== "/" || idp.search) invalid();
if (login.origin !== sp.origin) unexpectedOrigin();
NODE
url_status=$?
set -e
if [[ "$url_status" -eq 10 ]]; then
  CANARY_STATUS="configuration_incomplete"
  printf '%s\n' "real IdP canary origin configuration is invalid." >&2
  exit 2
elif [[ "$url_status" -eq 20 ]]; then
  CANARY_STATUS="unexpected_origin"
  printf '%s\n' "real IdP canary login URL is outside the approved SP origin." >&2
  exit 3
elif [[ "$url_status" -ne 0 ]]; then
  CANARY_STATUS="configuration_incomplete"
  printf '%s\n' "real IdP canary URL preflight failed safely." >&2
  exit 2
fi

if ! canary_runner_temp; then
  CANARY_STATUS="configuration_incomplete"
  printf '%s\n' "real IdP canary requires a real, non-symlink RUNNER_TEMP directory." >&2
  exit 2
fi

tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="$(CDPATH='' cd -P -- "$tmp_parent" && pwd)"
PLAYWRIGHT_TMP_DIR="$(umask 077; mktemp -d "$tmp_parent/relyra-real-idp-playwright.XXXXXX")"
PLAYWRIGHT_RESULT_PATH="$PLAYWRIGHT_TMP_DIR/status.code"
playwright_log="$PLAYWRIGHT_TMP_DIR/playwright.log"
export REAL_IDP_CANARY_RESULT_PATH="$PLAYWRIGHT_RESULT_PATH"
export REAL_IDP_CANARY_PLAYWRIGHT_TMP_DIR="$PLAYWRIGHT_TMP_DIR"

set +e
npx playwright test --config playwright.real-idp.config.mjs > "$playwright_log" 2>&1
playwright_exit=$?
set -e

case "$(cat "$PLAYWRIGHT_RESULT_PATH" 2>/dev/null || true)" in
  passed|unexpected_origin|idp_rejected|callback_failure|provider_failure)
    CANARY_STATUS="$(cat "$PLAYWRIGHT_RESULT_PATH")"
    ;;
  *)
    CANARY_STATUS="provider_failure"
    ;;
esac

if [[ "$playwright_exit" -ne 0 ]]; then
  exit "$playwright_exit"
fi

if [[ "$CANARY_STATUS" != "passed" ]]; then
  exit 1
fi
