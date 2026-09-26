#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -P -- "$(dirname "$0")/.." && pwd)"
CONTRACT_TMP_DIR="$(umask 077; mktemp -d "${TMPDIR:-/tmp}/relyra-trace-status-contract.XXXXXX")"
FAKE_BIN="$CONTRACT_TMP_DIR/bin"
RUNNER_TEMP_DIR="$CONTRACT_TMP_DIR/runner-temp"
STATUS_PATH="$RUNNER_TEMP_DIR/relyra-trace-visual-status.json"

cleanup() {
  rm -rf -- "$CONTRACT_TMP_DIR"
}

trap cleanup EXIT
mkdir -m 700 -- "$FAKE_BIN" "$RUNNER_TEMP_DIR"
RUNNER_TEMP_DIR="$(CDPATH='' cd -P -- "$RUNNER_TEMP_DIR" && pwd)"
STATUS_PATH="$RUNNER_TEMP_DIR/relyra-trace-visual-status.json"

cat > "$FAKE_BIN/npx" <<'FAKE_NPX'
#!/usr/bin/env bash
exit "${TRACE_VISUAL_CONTRACT_EXIT:-0}"
FAKE_NPX
chmod 700 "$FAKE_BIN/npx"

run_harness() {
  local fake_status="$1"
  local expected_status="$2"
  local actual_status

  rm -f -- "$STATUS_PATH"

  if env \
    PATH="$FAKE_BIN:$PATH" \
    GITHUB_ACTIONS=true \
    RUNNER_TEMP="$RUNNER_TEMP_DIR" \
    TRACE_VISUAL_STATUS_PATH="$STATUS_PATH" \
    TRACE_VISUAL_CONTRACT_EXIT="$fake_status" \
    bash "$ROOT_DIR/scripts/test_trace_visual_e2e.sh"; then
    actual_status=0
  else
    actual_status="$?"
  fi

  [[ "$actual_status" -eq "$expected_status" ]] || {
    printf 'Expected harness exit %s, got %s.\n' "$expected_status" "$actual_status" >&2
    return 1
  }

  local expected_run_status="passed"
  [[ "$fake_status" -eq 0 ]] || expected_run_status="failed"
  local expected_json
  expected_json="{\"schema_version\":1,\"owner\":\"demo-app-e2e\",\"status\":\"$expected_run_status\",\"recovery_command\":\"npm run demo:trace-visual\"}"
  local actual_json
  actual_json="$(cat -- "$STATUS_PATH")"

  [[ "$actual_json" == "$expected_json" ]] || {
    printf 'Trace visual status artifact did not match its fixed schema.\n' >&2
    return 1
  }
}

run_harness 0 0
run_harness 23 23

printf '%s\n' "Trace visual status contract passed for successful and failed browser commands."
