#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -P -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_PARENT="${TMPDIR:-/tmp}"
TMP_PARENT="${TMP_PARENT%/}"
TMP_PARENT_CANONICAL="$(CDPATH='' cd -P -- "$TMP_PARENT" && pwd)"
PLAYWRIGHT_TMP_DIR="$(umask 077; mktemp -d "$TMP_PARENT_CANONICAL/relyra-trace-visual-playwright.XXXXXX")"

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
  local status="passed"
  local runner_temp="${RUNNER_TEMP:-}"
  local temporary_file

  [[ "$test_status" -eq 0 ]] || status="failed"
  [[ -d "$runner_temp" && ! -L "$runner_temp" ]] || return 1
  temporary_file="$(umask 077; mktemp "$runner_temp/.relyra-trace-visual-status.XXXXXX")" || return 1

  if ! printf '{"schema_version":1,"owner":"demo-app-e2e","status":"%s","recovery_command":"npm run demo:trace-visual"}\n' "$status" > "$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi

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
        printf '%s\n' "Trace visual status artifact could not be written to its safe workflow path." >&2
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

DEMO_ADMIN_USERNAME="trace-visual-admin"
DEMO_ADMIN_PASSWORD="$(openssl rand -hex 32)"
DEMO_TRACE_VISUAL_FIXTURE=1
TRACE_VISUAL_PLAYWRIGHT_TMP_DIR="$PLAYWRIGHT_TMP_DIR"

export DEMO_ADMIN_USERNAME DEMO_ADMIN_PASSWORD DEMO_TRACE_VISUAL_FIXTURE
export TRACE_VISUAL_PLAYWRIGHT_TMP_DIR

npx playwright test --config playwright.trace-visual.config.mjs "$@"
