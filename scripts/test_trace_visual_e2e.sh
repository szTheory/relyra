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

cleanup() {
  local status="$1"

  trap - EXIT HUP INT TERM
  if trace_visual_output_is_safe "$PLAYWRIGHT_TMP_DIR"; then
    rm -rf -- "$PLAYWRIGHT_TMP_DIR"
  fi
  exit "$status"
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
