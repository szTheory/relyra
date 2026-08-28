#!/usr/bin/env bash
# Deterministic, owned Compose proof for Phase 68's four runtime requirements.
# It runs against a disposable copy of the checkout and its own Compose project,
# so the developer's active demo, volumes, and source tree are never reused.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
RUN_ID="phase68_nyquist_${RANDOM}_$$"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/relyra-phase68.XXXXXX")"
PORT="${PHASE68_PORT:-41868}"
COMPOSE=(docker compose -p "$RUN_ID" -f "$WORK_DIR/docker-compose.yml" -f "$WORK_DIR/docker-compose.override.yml")

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  docker image rm "${RUN_ID}-demo_app" >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
  exit "$status"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'phase-68 validation failed: %s\n' "$*" >&2
  "${COMPOSE[@]}" logs --no-color >&2 || true
  exit 1
}

require_log() {
  local needle="$1"
  local container_id

  for _attempt in $(seq 1 60); do
    container_id="$("${COMPOSE[@]}" ps -q demo_app 2>/dev/null || true)"
    if [[ -n "$container_id" ]] && docker logs "$container_id" 2>&1 | grep -F "$needle" >/dev/null; then
      return 0
    fi
    sleep 1
  done

  fail "missing log: $needle"
}

refute_log() {
  local needle="$1"
  local container_id
  container_id="$("${COMPOSE[@]}" ps -q demo_app)"
  if docker logs "$container_id" 2>&1 | grep -Ei "$needle" >/dev/null; then
    fail "unexpected log matching: $needle"
  fi
}

printf '[phase-68] creating isolated workspace %s\n' "$WORK_DIR"
rsync -a --delete \
  --exclude '.git/' --exclude '_build/' --exclude 'deps/' --exclude 'node_modules/' \
  --exclude 'demo/ledger_loop/_build/' --exclude 'demo/ledger_loop/deps/' \
  --exclude 'playwright-report/' "$ROOT_DIR/" "$WORK_DIR/"

# The fixture contains a host-only artifact at the exact nested path that must
# be hidden by the named volume. A visible sentinel proves a volume regression.
mkdir -p "$WORK_DIR/demo/ledger_loop/deps"
printf 'host architecture artifact — must stay masked\n' >"$WORK_DIR/demo/ledger_loop/deps/.phase68-host-sentinel"

printf '[phase-68] DKR-01: building twice around a source-only edit\n'
FIRST_BUILD="$WORK_DIR/first-build.log"
SECOND_BUILD="$WORK_DIR/second-build.log"
DOCKER_BUILDKIT=1 "${COMPOSE[@]}" build --progress=plain demo_app >"$FIRST_BUILD" 2>&1 || {
  tail -200 "$FIRST_BUILD" >&2
  exit 1
}

printf '\n<!-- phase68 source-only rebuild sentinel -->\n' >>"$WORK_DIR/demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex"
DOCKER_BUILDKIT=1 "${COMPOSE[@]}" build --progress=plain demo_app >"$SECOND_BUILD" 2>&1 || {
  tail -200 "$SECOND_BUILD" >&2
  exit 1
}

# BuildKit prints the RUN command and its status on separate lines. Identify
# the deps vertex ID first, then require that exact vertex to be cached.
DEPS_VERTEX="$(sed -nE 's/^#([0-9]+) .*mix deps\.get.*/\1/p' "$SECOND_BUILD" | head -1)"
[[ -n "$DEPS_VERTEX" ]] && grep -q "^#${DEPS_VERTEX} CACHED$" "$SECOND_BUILD" || {
  tail -200 "$SECOND_BUILD" >&2
  fail 'source-only rebuild did not cache the dependency vertex'
}

printf '[phase-68] DKR-02/03: booting the isolated stack\n'
PORT="$PORT" "${COMPOSE[@]}" up -d --wait || fail 'initial Compose boot failed'
APP_ID="$("${COMPOSE[@]}" ps -q demo_app)"
[[ -n "$APP_ID" ]] || fail 'demo_app has no container id'
docker exec "$APP_ID" test ! -e /app/demo/ledger_loop/deps/.phase68-host-sentinel ||
  fail 'host deps artifact leaked through the named volume'
docker inspect --format '{{range .Mounts}}{{if eq .Destination "/app/demo/ledger_loop/deps"}}{{.Type}}{{end}}{{end}}' "$APP_ID" |
  grep -qx volume || fail 'deps mount is not a Docker-managed volume'
docker inspect --format '{{range .Mounts}}{{if eq .Destination "/app/demo/ledger_loop/_build"}}{{.Type}}{{end}}{{end}}' "$APP_ID" |
  grep -qx volume || fail '_build mount is not a Docker-managed volume'
refute_log 'wrong ELF class|NIF.*(error|fail)|could not load.*NIF'
docker exec "$APP_ID" test -s /app/demo/ledger_loop/_build/.docker/mix.lock.sha ||
  fail 'initial boot did not persist the lock-hash stamp in the build volume'

printf '[phase-68] DKR-03: re-up with unchanged lock\n'
"${COMPOSE[@]}" down --remove-orphans
PORT="$PORT" "${COMPOSE[@]}" up -d --wait || fail 'unchanged-lock Compose boot failed'
require_log 'mix.lock unchanged — skipping deps.get/deps.compile.'
refute_log 'ERROR.*(migrat|seed)|\*\* \(.*Error\)'

printf '[phase-68] DKR-03: re-up after a content change to mix.lock\n'
"${COMPOSE[@]}" down --remove-orphans
printf '\n' >>"$WORK_DIR/demo/ledger_loop/mix.lock"
PORT="$PORT" "${COMPOSE[@]}" up -d --wait || fail 'changed-lock Compose boot failed'
require_log 'mix.lock changed or stamp absent — re-resolving dependencies...'

printf '[phase-68] DKR-04: proving browser reload from a bind-mounted template edit\n'
APP_ID="$("${COMPOSE[@]}" ps -q demo_app)"
BEFORE_STARTED="$(docker inspect --format '{{.State.StartedAt}}' "$APP_ID")"
BEFORE_BOOT_MARKERS="$(docker logs "$APP_ID" 2>&1 | grep -Ec 'mix\.lock (unchanged|changed or stamp absent)' || true)"
RELOAD_SENTINEL="Phase 68 live reload ${RUN_ID}"

if ! PHASE68_URL="http://localhost:${PORT}" \
  PHASE68_TEMPLATE="$WORK_DIR/demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex" \
  PHASE68_SENTINEL="$RELOAD_SENTINEL" \
  node --input-type=module <<'NODE'
import { chromium } from 'playwright';
import { appendFile } from 'node:fs/promises';

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
try {
  await page.goto(process.env.PHASE68_URL, { waitUntil: 'domcontentloaded' });
  await page.locator('#workspace-title').waitFor();
  await page.locator('iframe[src^="/phoenix/live_reload/frame"]').waitFor({ state: 'attached' });
  await appendFile(process.env.PHASE68_TEMPLATE, `\n<p id="phase68-live-reload">${process.env.PHASE68_SENTINEL}</p>\n`);
  for (let attempt = 1; attempt <= 15; attempt += 1) {
    try {
      await page.getByText(process.env.PHASE68_SENTINEL).waitFor({ timeout: 2000 });
      break;
    } catch (error) {
      if (attempt === 15) throw error;
      await appendFile(process.env.PHASE68_TEMPLATE, `\n<!-- phase68 live-reload probe ${attempt} -->\n`);
    }
  }
} finally {
  await browser.close();
}
NODE
then
  docker exec "$APP_ID" grep -F "$RELOAD_SENTINEL" \
    /app/demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex >/dev/null ||
    fail 'bind-mounted template edit was not visible inside the container'
  docker logs "$APP_ID" 2>&1 | grep -E 'Polling file changes|Live reload:' >&2 || true
  fail 'bind-mounted template edits were visible in-container but did not reload the browser'
fi

AFTER_STARTED="$(docker inspect --format '{{.State.StartedAt}}' "$APP_ID")"
[[ "$BEFORE_STARTED" == "$AFTER_STARTED" ]] || fail 'template edit restarted the demo container'
AFTER_BOOT_MARKERS="$(docker logs "$APP_ID" 2>&1 | grep -Ec 'mix\.lock (unchanged|changed or stamp absent)' || true)"
[[ "$BEFORE_BOOT_MARKERS" == "$AFTER_BOOT_MARKERS" ]] ||
  fail 'template edit triggered additional dependency or boot work'

printf '[phase-68] PASS: DKR-01, DKR-02, DKR-03, and DKR-04\n'
