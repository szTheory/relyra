#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -P -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_PARENT="${TMPDIR:-/tmp}"
TMP_PARENT="${TMP_PARENT%/}"
TMP_PARENT_CANONICAL=""
PLAYWRIGHT_TMP_DIR=""
TRACE_VISUAL_STATUS_PATH="${TRACE_VISUAL_STATUS_PATH:-}"
TRACE_VISUAL_PHASE="setup"
TRACE_VISUAL_CHECKS_PASSED=0

trace_visual_output_is_safe() {
  local candidate="$1"
  local parent
  local name
  local canonical_parent

  [[ -d "$candidate" && ! -L "$candidate" ]] || return 1
  parent="$(dirname "$candidate")"
  name="$(basename "$candidate")"
  [[ "$name" =~ ^relyra-trace-visual-playwright\.[A-Za-z0-9]+$ ]] || return 1
  [[ "$parent" == "$TMP_PARENT_CANONICAL" ]] || return 1
  canonical_parent="$(CDPATH='' cd -P -- "$parent" && pwd)" || return 1
  [[ "$canonical_parent" == "$TMP_PARENT_CANONICAL" ]]
}

trace_visual_status_path_is_safe() {
  local candidate="${TRACE_VISUAL_STATUS_PATH:-}"
  local runner_temp="${RUNNER_TEMP:-}"
  local canonical_runner_temp

  [[ -n "$candidate" && -n "$runner_temp" ]] || return 1
  [[ -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  canonical_runner_temp="$(CDPATH='' cd -P -- "$runner_temp" && pwd)" || return 1
  [[ "$candidate" == "$canonical_runner_temp/relyra-trace-visual-status.json" ]]
}

write_trace_visual_status() {
  local test_status="$1"
  local outcome="passed"
  local failure_category="none"
  local checks_failed=0
  local run_id
  local runner_temp="${RUNNER_TEMP:-}"
  local temporary_file
  local byte_count

  [[ "$test_status" -eq 0 ]] || checks_failed=1

  case "$test_status" in
    0)
      TRACE_VISUAL_PHASE="complete"
      TRACE_VISUAL_CHECKS_PASSED=1
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
      if [[ "$TRACE_VISUAL_PHASE" == "setup" ]]; then
        failure_category="setup"
      else
        failure_category="assertion"
      fi
      ;;
  esac

  [[ -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  temporary_file="$(umask 077; mktemp "$runner_temp/.relyra-trace-visual-status.XXXXXX")" || return 1
  run_id="$(od -An -N8 -tx1 /dev/urandom | tr -d '[:space:]')" || {
    rm -f -- "$temporary_file"
    return 1
  }
  [[ "$run_id" =~ ^[a-f0-9]{16}$ ]] || {
    rm -f -- "$temporary_file"
    return 1
  }

  if ! printf '{"schema_version":1,"owner":"demo-app-e2e","run_id":"%s","phase":"%s","outcome":"%s","failure_category":"%s","checks_passed":%s,"checks_failed":%s}\n' \
    "$run_id" "$TRACE_VISUAL_PHASE" "$outcome" "$failure_category" \
    "$TRACE_VISUAL_CHECKS_PASSED" "$checks_failed" >"$temporary_file"; then
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

  if ! mv -f -- "$temporary_file" "$TRACE_VISUAL_STATUS_PATH"; then
    rm -f -- "$temporary_file"
    return 1
  fi
}

cleanup() {
  local original_status="$1"
  local final_status="$original_status"

  trap - EXIT HUP INT TERM

  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    if trace_visual_status_path_is_safe; then
      if ! write_trace_visual_status "$original_status"; then
        printf '%s\n' "trace_visual_status_receipt_write_failed: bounded status receipt could not be written." >&2
        [[ "$final_status" -ne 0 ]] || final_status=1
      fi
    else
      printf '%s\n' "Trace visual status artifact path is missing or outside RUNNER_TEMP." >&2
      [[ "$final_status" -ne 0 ]] || final_status=1
    fi
  fi

  if trace_visual_output_is_safe "$PLAYWRIGHT_TMP_DIR"; then
    rm -rf -- "$PLAYWRIGHT_TMP_DIR"
  fi
  exit "$final_status"
}

trap 'cleanup $?' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  if ! trace_visual_status_path_is_safe; then
    printf '%s\n' "trace_visual_status_path_invalid: required status path is outside RUNNER_TEMP." >&2
    exit 1
  fi
  rm -f -- "$TRACE_VISUAL_STATUS_PATH"
fi

TMP_PARENT_CANONICAL="$(CDPATH='' cd -P -- "$TMP_PARENT" && pwd)"
PLAYWRIGHT_TMP_DIR="$(umask 077; mktemp -d "$TMP_PARENT_CANONICAL/relyra-trace-visual-playwright.XXXXXX")"
[[ -n "$PLAYWRIGHT_TMP_DIR" && ! -L "$PLAYWRIGHT_TMP_DIR" ]]

DEMO_ADMIN_USERNAME="trace-visual-admin"
DEMO_ADMIN_PASSWORD="$(openssl rand -hex 32)"
DEMO_TRACE_VISUAL_FIXTURE=1
TRACE_VISUAL_PLAYWRIGHT_TMP_DIR="$PLAYWRIGHT_TMP_DIR"

export DEMO_ADMIN_USERNAME DEMO_ADMIN_PASSWORD DEMO_TRACE_VISUAL_FIXTURE
export TRACE_VISUAL_PLAYWRIGHT_TMP_DIR

TRACE_VISUAL_PHASE="browser"
npx playwright test --config playwright.trace-visual.config.mjs "$@"
TRACE_VISUAL_CHECKS_PASSED=1
