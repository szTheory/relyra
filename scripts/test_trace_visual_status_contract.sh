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
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/demo-app-e2e.yml"

assert_workflow_contract() {
  grep -Fq 'name: Trace visual and failed-state browser e2e' "$WORKFLOW_PATH"
  grep -Fq 'run: npm run demo:trace-visual' "$WORKFLOW_PATH"
  grep -Fq 'uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1' "$WORKFLOW_PATH"
  grep -Fq 'trace-visual-status' "$WORKFLOW_PATH"
  grep -Fq "name: demo-app-e2e-\${{ github.job }}-\${{ strategy.job-index || 0 }}-\${{ github.run_attempt }}-trace-visual-status" "$WORKFLOW_PATH"
  grep -Fq "path: \${{ runner.temp }}/relyra-trace-visual-status.json" "$WORKFLOW_PATH"
  grep -Fq 'if-no-files-found: error' "$WORKFLOW_PATH"
  grep -Fq 'retention-days: 3' "$WORKFLOW_PATH"
  grep -Fq 'steps.trace_status_guard.conclusion' "$WORKFLOW_PATH"
  grep -Fq 'trace_visual_status_missing' "$WORKFLOW_PATH"
  grep -Fq "\\\`demo-app-e2e\\\` maintainer" "$WORKFLOW_PATH"
  grep -Fq "\\\`npm run demo:trace-visual\\\`" "$WORKFLOW_PATH"
}

cat > "$FAKE_BIN/npx" <<'FAKE_NPX'
#!/usr/bin/env bash
printf '%s\n' "${TRACE_VISUAL_SENTINELS:-}" >&2

if [[ -n "${TRACE_VISUAL_BLOCK_MARKER:-}" ]]; then
  marker_tmp="$(mktemp "${TRACE_VISUAL_BLOCK_MARKER}.XXXXXX")"
  if ! printf '%s\n' "$$" >"$marker_tmp" ||
    ! mv -f -- "$marker_tmp" "$TRACE_VISUAL_BLOCK_MARKER"; then
    rm -f -- "$marker_tmp"
    exit 1
  fi
  while [[ ! -e "${TRACE_VISUAL_RELEASE:-}" ]]; do
    sleep 0.05
  done
fi

exit "${TRACE_VISUAL_CONTRACT_EXIT:-0}"
FAKE_NPX
chmod 700 "$FAKE_BIN/npx"

run_harness() {
  local fake_status="$1"
  local expected_status="$2"
  local expected_phase="$3"
  local expected_outcome="$4"
  local expected_category="$5"
  local actual_status

  rm -f -- "$STATUS_PATH"

  if env \
    PATH="$FAKE_BIN:$PATH" \
    GITHUB_ACTIONS=true \
    RUNNER_TEMP="$RUNNER_TEMP_DIR" \
    TRACE_VISUAL_STATUS_PATH="$STATUS_PATH" \
    TRACE_VISUAL_CONTRACT_EXIT="$fake_status" \
    TRACE_VISUAL_SENTINELS="ASSERTION_SENTINEL CERTIFICATE_SENTINEL BASIC_CREDENTIAL_SENTINEL COOKIE_SENTINEL" \
    bash "$ROOT_DIR/scripts/test_trace_visual_e2e.sh" >"$CONTRACT_TMP_DIR/run.log" 2>&1; then
    actual_status=0
  else
    actual_status="$?"
  fi

  [[ "$actual_status" -eq "$expected_status" ]] || {
    printf 'Expected harness exit %s, got %s.\n' "$expected_status" "$actual_status" >&2
    return 1
  }

  local actual_json
  actual_json="$(cat -- "$STATUS_PATH")"

  jq -e --arg phase "$expected_phase" --arg outcome "$expected_outcome" --arg category "$expected_category" '
    keys == ["checks_failed", "checks_passed", "failure_category", "outcome", "owner", "phase", "run_id", "schema_version"] and
    .schema_version == 1 and .owner == "demo-app-e2e" and
    (.run_id | test("^[a-f0-9]{16}$")) and
    .phase == $phase and .outcome == $outcome and .failure_category == $category and
    (.checks_passed | type == "number" and . >= 0 and . <= 1) and
    (.checks_failed | type == "number" and . >= 0 and . <= 1)
  ' "$STATUS_PATH" >/dev/null || {
    printf 'Trace visual status artifact did not match its bounded schema.\n' >&2
    return 1
  }

  local byte_count
  byte_count="$(wc -c <"$STATUS_PATH")"
  (( byte_count > 0 && byte_count <= 512 )) || {
    printf 'Trace visual status artifact exceeded its byte limit.\n' >&2
    return 1
  }

  for sentinel in ASSERTION_SENTINEL CERTIFICATE_SENTINEL BASIC_CREDENTIAL_SENTINEL COOKIE_SENTINEL; do
    if grep -Fq "$sentinel" "$STATUS_PATH"; then
      printf 'Trace visual status artifact included a sensitive fixture.\n' >&2
      return 1
    fi
  done

  [[ -n "$actual_json" ]] || {
    printf 'Trace visual status artifact is empty.\n' >&2
    return 1
  }
}

run_harness 0 0 complete passed none
run_harness 23 23 browser failed assertion

rm -f -- "$STATUS_PATH"
if env \
  PATH="$FAKE_BIN:$PATH" \
  GITHUB_ACTIONS=true \
  RUNNER_TEMP="$RUNNER_TEMP_DIR" \
  TRACE_VISUAL_STATUS_PATH="$STATUS_PATH" \
  TMPDIR="$CONTRACT_TMP_DIR/missing-parent" \
  bash "$ROOT_DIR/scripts/test_trace_visual_e2e.sh" >"$CONTRACT_TMP_DIR/setup.log" 2>&1; then
  setup_status=0
else
  setup_status="$?"
fi
[[ "$setup_status" -eq 1 ]]
jq -e '
  .phase == "setup" and .outcome == "failed" and .failure_category == "setup" and
  .checks_passed == 0 and .checks_failed == 1
' "$STATUS_PATH" >/dev/null

rm -f -- "$STATUS_PATH"
BLOCK_MARKER="$CONTRACT_TMP_DIR/trace-blocked"
RELEASE_MARKER="$CONTRACT_TMP_DIR/trace-release"
env \
  PATH="$FAKE_BIN:$PATH" \
  GITHUB_ACTIONS=true \
  RUNNER_TEMP="$RUNNER_TEMP_DIR" \
  TRACE_VISUAL_STATUS_PATH="$STATUS_PATH" \
  TRACE_VISUAL_BLOCK_MARKER="$BLOCK_MARKER" \
  TRACE_VISUAL_RELEASE="$RELEASE_MARKER" \
  bash "$ROOT_DIR/scripts/test_trace_visual_e2e.sh" >"$CONTRACT_TMP_DIR/cancel.log" 2>&1 &
trace_pid=$!
npx_pid=''
for _attempt in $(seq 1 100); do
  if [[ -s "$BLOCK_MARKER" ]]; then
    candidate_pid="$(cat -- "$BLOCK_MARKER")"
    if [[ "$candidate_pid" =~ ^[0-9]+$ ]]; then
      npx_pid="$candidate_pid"
      break
    fi
  fi
  sleep 0.05
done
[[ "$npx_pid" =~ ^[0-9]+$ ]]
kill -TERM "$trace_pid" "$npx_pid" 2>/dev/null || true
if wait "$trace_pid"; then
  cancel_status=0
else
  cancel_status="$?"
fi
[[ "$cancel_status" -eq 143 ]]
jq -e '
  .phase == "browser" and .outcome == "cancelled" and .failure_category == "cancelled" and
  .checks_passed == 0 and .checks_failed == 1
' "$STATUS_PATH" >/dev/null

assert_workflow_contract

printf '%s\n' "Trace visual status contract passed for success, failure, setup failure, cancellation, sentinel exclusion, and workflow ownership."
