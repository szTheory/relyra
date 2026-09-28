#!/usr/bin/env bash
set -uo pipefail

readonly RECEIPT_REL='.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json'
readonly MAX_OUTPUT_BYTES=16777216

usage() {
  cat <<'USAGE'
Usage:
  scripts/check_phase78_clean_state.sh --otp 27|28 --output <private-temp-file>
  scripts/check_phase78_clean_state.sh --assemble <otp27.json> <otp28.json> --output <receipt.json>
  scripts/check_phase78_clean_state.sh --source-digest <git-checkout>
USAGE
}

source_digest() {
  python3 - "$1" "$RECEIPT_REL" <<'PY'
import hashlib
import os
import subprocess
import sys

root = os.path.realpath(sys.argv[1])
receipt = sys.argv[2]
tracked = subprocess.check_output(["git", "-C", root, "ls-files", "-z"]).split(b"\0")
manifest = []
for raw in tracked:
    if not raw:
        continue
    path = raw.decode("utf-8")
    if path == receipt or os.path.basename(path).endswith("-SUMMARY.md"):
        continue
    full = os.path.join(root, path)
    if not os.path.isfile(full):
        raise SystemExit("source manifest contains a missing or non-regular file")
    with open(full, "rb") as stream:
        content = stream.read()
    manifest.append((path, hashlib.sha256(content).hexdigest()))

manifest.sort()
digest = hashlib.sha256()
for path, file_hash in manifest:
    digest.update(path.encode("utf-8"))
    digest.update(b"\0")
    digest.update(file_hash.encode("ascii"))
    digest.update(b"\n")
print(digest.hexdigest())
print(len(manifest))
PY
}

assemble_receipts() {
  python3 - "$1" "$2" "$3" <<'PY'
import datetime
import json
import os
import pathlib
import sys
import tempfile

path27, path28, output_path = sys.argv[1:]
with open(path27, encoding="utf-8") as stream:
    first = json.load(stream)
with open(path28, encoding="utf-8") as stream:
    second = json.load(stream)
for item in (first, second):
    if item.get("schema") != "phase78-clean-state-run" or item.get("version") != 1 or len(item.get("runs", [])) != 1:
        raise SystemExit("invalid per-toolchain receipt schema")
runs = first["runs"] + second["runs"]
if [run.get("otp_release") for run in runs] != ["27", "28"]:
    raise SystemExit("expected one OTP 27 and one OTP 28 receipt")
for field in ("source_commit", "source_digest", "source_file_count", "phase73"):
    if first.get(field) != second.get(field):
        raise SystemExit("toolchain receipts do not share the same frozen source and proof")

payload = {
    "schema": "phase78-clean-state-receipt",
    "version": 1,
    "source_commit": first["source_commit"],
    "source_digest": first["source_digest"],
    "source_file_count": first["source_file_count"],
    "phase73": first["phase73"],
    "generated_at": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "outcome": "passed" if first.get("outcome") == second.get("outcome") == "passed" else "failed",
    "runs": runs,
}
target = pathlib.Path(output_path)
if target.exists() or target.is_symlink():
    raise SystemExit("refusing to replace an existing receipt path")
target.parent.mkdir(parents=True, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", suffix=".tmp", dir=target.parent)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as stream:
        json.dump(payload, stream, sort_keys=True, separators=(",", ":"))
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, target)
finally:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
PY
}

if (($# == 2)) && [[ "$1" == "--source-digest" ]]; then
  source_digest "$2"
  exit $?
fi
if (($# == 5)) && [[ "$1" == "--assemble" && "$4" == "--output" ]]; then
  assemble_receipts "$2" "$3" "$5"
  exit $?
fi

otp=""
output_path=""
while (($#)); do
  case "$1" in
    --otp) (($# >= 2)) || { usage >&2; exit 64; }; otp="$2"; shift 2 ;;
    --output) (($# >= 2)) || { usage >&2; exit 64; }; output_path="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
done
if [[ "$otp" != "27" && "$otp" != "28" ]] || [[ -z "$output_path" ]]; then
  usage >&2
  exit 64
fi

source_root="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly source_root
if ! git -C "$source_root" rev-parse --verify HEAD >/dev/null 2>&1 ||
   ! git -C "$source_root" diff --quiet HEAD -- || ! git -C "$source_root" diff --cached --quiet HEAD --; then
  echo "phase78 clean-state: source checkout must have a committed, unmodified HEAD" >&2
  exit 65
fi
source_commit="$(git -C "$source_root" rev-parse HEAD)"
host_home="${HOME:-/tmp}"
host_docker_config="${DOCKER_CONFIG:-$host_home/.docker}"
case "$output_path" in "$source_root"/*) echo "phase78 clean-state: output must be outside the source checkout" >&2; exit 65 ;; esac
if [[ -e "$output_path" || -L "$output_path" ]]; then
  echo "phase78 clean-state: refusing to replace an existing output file" >&2
  exit 65
fi
for tool in git python3 docker mix elixir node npm npx; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "phase78 clean-state: required tool is missing: $tool" >&2
    exit 69
  fi
done

run_id="$(od -An -N8 -tx1 /dev/urandom | tr -d '[:space:]')"
[[ "$run_id" =~ ^[a-f0-9]{16}$ ]] || { echo "phase78 clean-state: could not create a run ID" >&2; exit 70; }
tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="$(CDPATH='' cd -P -- "$tmp_parent" && pwd)" || exit 70
run_root="$(umask 077; mktemp -d "$tmp_parent/relyra-phase78-cold-$run_id.XXXXXX")" || exit 70
run_root="$(CDPATH='' cd -P -- "$run_root" && pwd)"
[[ "$run_root" == "$tmp_parent"/relyra-phase78-cold-"$run_id".* ]] || { echo "phase78 clean-state: unsafe temporary workspace" >&2; exit 70; }
workspace="$run_root/checkout"
logs="$run_root/logs"
mkdir -p "$logs" "$run_root/home" "$run_root/tmp" "$run_root/runner-temp" \
  "$run_root/mix-home" "$run_root/hex-home" "$run_root/mix-archives" \
  "$run_root/npm-cache" "$run_root/playwright-browsers"
printf '%s\n%s\n' "$run_id" "$source_commit" >"$run_root/owner.marker"
chmod 600 "$run_root/owner.marker"

db_container=""
cleanup() {
  local status=$?
  if [[ -n "$db_container" ]] && docker container inspect "$db_container" >/dev/null 2>&1; then
    local owner_label
    owner_label="$(docker inspect --format '{{ index .Config.Labels "relyra.phase78.owner" }}' "$db_container" 2>/dev/null || true)"
    [[ "$owner_label" == "$run_id" ]] && docker rm --force --volumes "$db_container" >/dev/null 2>&1 || true
  fi
  if [[ -f "$run_root/owner.marker" && "$run_root" == "$tmp_parent"/relyra-phase78-cold-"$run_id".* ]]; then
    if [[ "$status" == "0" ]]; then rm -rf -- "$run_root"; else printf 'phase78 clean-state: private failure workspace retained: %s\n' "$run_root" >&2; fi
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! git clone --no-local --no-checkout --quiet "$source_root" "$workspace" >"$logs/clone.log" 2>&1 ||
   ! git -C "$workspace" fetch --quiet "$source_root" "$source_commit" >>"$logs/clone.log" 2>&1 ||
   ! git -C "$workspace" checkout --quiet --detach "$source_commit" >>"$logs/clone.log" 2>&1; then
  echo "phase78 clean-state: failed to create private committed-source checkout" >&2
  exit 1
fi
if [[ "$(git -C "$workspace" rev-parse HEAD)" != "$source_commit" ]] ||
   [[ -n "$(git -C "$workspace" status --porcelain --untracked-files=all)" ]] ||
   [[ -e "$workspace/_build" || -e "$workspace/deps" || -e "$workspace/node_modules" ||
      -e "$workspace/demo/ledger_loop/_build" || -e "$workspace/demo/ledger_loop/deps" ]]; then
  echo "phase78 clean-state: private checkout is stale, dirty, or contains restored build/dependency state" >&2
  exit 1
fi

export HOME="$run_root/home" XDG_CONFIG_HOME="$run_root/home/.config" XDG_CACHE_HOME="$run_root/home/.cache"
export MIX_HOME="$run_root/mix-home" HEX_HOME="$run_root/hex-home" MIX_ARCHIVES="$run_root/mix-archives"
export DOCKER_CONFIG="$run_root/home/.docker"
export DOCKER_BUILDKIT=1
export NPM_CONFIG_CACHE="$run_root/npm-cache" PLAYWRIGHT_BROWSERS_PATH="$run_root/playwright-browsers"
export TMPDIR="$run_root/tmp" RUNNER_TEMP="$run_root/runner-temp"
export FLEET_PROXY_STATUS_PATH="$RUNNER_TEMP/relyra-fleet-proxy-status.json"
export TRACE_VISUAL_STATUS_PATH="$RUNNER_TEMP/relyra-trace-visual-status.json"
export MIX_ENV=test CI=true GITHUB_ACTIONS=true RELYRA_XML_STRATEGY=pure_beam
export PGHOST=127.0.0.1 PGPORT=0 PGUSER=postgres PGPASSWORD=postgres RELYRA_TEST_DATABASE=relyra_phase78_clean_state
export ASDF_ELIXIR_VERSION="${ASDF_ELIXIR_VERSION:-1.19.5-otp-$otp}"
if [[ "$otp" == "27" ]]; then export ASDF_ERLANG_VERSION="${ASDF_ERLANG_VERSION:-27.3.4.15}"; else export ASDF_ERLANG_VERSION="${ASDF_ERLANG_VERSION:-28.4.1}"; fi
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$DOCKER_CONFIG/cli-plugins"

compose_candidates=(
  "$host_docker_config/cli-plugins/docker-compose"
  "$host_home/.docker/cli-plugins/docker-compose"
  "/usr/local/lib/docker/cli-plugins/docker-compose"
  "/usr/lib/docker/cli-plugins/docker-compose"
  "/usr/libexec/docker/cli-plugins/docker-compose"
  "/Applications/Docker.app/Contents/Resources/cli-plugins/docker-compose"
)
for candidate in "${compose_candidates[@]}"; do
  if [[ -x "$candidate" ]]; then
    compose_plugin="$(python3 - "$candidate" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
)"
    ln -s "$compose_plugin" "$DOCKER_CONFIG/cli-plugins/docker-compose"
    break
  fi
done

buildx_candidates=(
  "$host_docker_config/cli-plugins/docker-buildx"
  "$host_home/.docker/cli-plugins/docker-buildx"
  "/usr/local/lib/docker/cli-plugins/docker-buildx"
  "/usr/lib/docker/cli-plugins/docker-buildx"
  "/usr/libexec/docker/cli-plugins/docker-buildx"
  "/Applications/Docker.app/Contents/Resources/cli-plugins/docker-buildx"
)
for candidate in "${buildx_candidates[@]}"; do
  if [[ -x "$candidate" ]]; then
    buildx_plugin="$(python3 - "$candidate" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
)"
    ln -s "$buildx_plugin" "$DOCKER_CONFIG/cli-plugins/docker-buildx"
    break
  fi
done

db_container="relyra-phase78-db-$run_id"
if docker container inspect "$db_container" >/dev/null 2>&1; then
  echo "phase78 clean-state: owned database name unexpectedly exists" >&2
  exit 1
fi

setup_jsonl="$run_root/setup.jsonl"
commands_jsonl="$run_root/commands.jsonl"
: >"$setup_jsonl"
: >"$commands_jsonl"
setup_count=0

timestamp() {
  python3 -c 'import datetime; print(datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"))'
}
now_ns() { python3 -c 'import time; print(time.time_ns())'; }
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}
run_bounded_command() {
  local log_path="$1" overflow_path="$2" command_text="$3"
  python3 - "$workspace" "$log_path" "$overflow_path" "$MAX_OUTPUT_BYTES" "$command_text" <<'PY'
from collections import deque
import os
import subprocess
import sys

workspace, log_path, overflow_path, limit_raw, command = sys.argv[1:]
limit = int(limit_raw)
process = subprocess.Popen(
    ["bash", "-c", command],
    cwd=workspace,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
chunks = deque()
retained = 0
observed = 0
while True:
    chunk = process.stdout.read(65536)
    if not chunk:
        break
    observed += len(chunk)
    chunks.append(chunk)
    retained += len(chunk)
    while retained > limit:
        excess = retained - limit
        first = chunks[0]
        if len(first) <= excess:
            chunks.popleft()
            retained -= len(first)
        else:
            chunks[0] = first[excess:]
            retained -= excess

with open(log_path, "wb") as stream:
    for chunk in chunks:
        stream.write(chunk)

if observed > limit:
    with open(overflow_path, "w", encoding="ascii") as stream:
        stream.write(f"{observed}\n")
else:
    try:
        os.unlink(overflow_path)
    except FileNotFoundError:
        pass

sys.exit(process.wait())
PY
}

record_result() {
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" <<'PY'
import json
import sys

(destination, name, evidence_kind, evidence_count, started, completed, duration,
 exit_code, output_bytes, output_digest, command) = sys.argv[1:]
record = {
    "name": name,
    "argv": ["bash", "-c", command],
    "started_at": started,
    "completed_at": completed,
    "duration_ms": int(duration),
    "exit_code": int(exit_code),
    "output_bytes": int(output_bytes),
    "output_sha256": output_digest,
}
if evidence_kind != "setup":
    record["evidence_kind"] = evidence_kind
    record["evidence_count"] = None if evidence_count == "null" else int(evidence_count)
with open(destination, "a", encoding="utf-8") as stream:
    stream.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
PY
}

run_setup() {
  local name="$1" command_text="$2" log_path overflow_path start_epoch end_epoch started completed status bytes digest
  setup_count=$((setup_count + 1))
  log_path="$logs/setup-$setup_count.log"
  overflow_path="$log_path.overflow"
  start_epoch="$(now_ns)"
  started="$(timestamp)"
  : >"$log_path"
  run_bounded_command "$log_path" "$overflow_path" "$command_text"
  status=$?
  end_epoch="$(now_ns)"
  completed="$(timestamp)"
  bytes="$(wc -c <"$log_path" | tr -d '[:space:]')"
  digest="$(sha256_file "$log_path")"
  if (( bytes > MAX_OUTPUT_BYTES )) || [[ -f "$overflow_path" ]]; then status=1; fi
  record_result "$setup_jsonl" "$name" setup null "$started" "$completed" \
    "$(((end_epoch - start_epoch) / 1000000))" "$status" "$bytes" "$digest" "$command_text"
  printf 'phase78 clean-state: setup %s exit=%s bytes=%s\n' "$name" "$status" "$bytes"
  return 0
}

run_command() {
  local index="$1" name="$2" evidence_kind="$3" command_text="$4"
  local execution_text="$command_text"
  local log_path="$logs/command-$index.log" overflow_path="$logs/command-$index.log.overflow"
  local start_epoch end_epoch started completed status bytes digest evidence_count

  case "$name" in
    'npm run admin-ui:smoke'|'npm run demo:fake-idp'|'npm run demo:trace-visual'|'npm run demo:fleet-proxy'|'npm run demo:keycloak-proxy')
      execution_text="MIX_ENV=dev $command_text"
      ;;
  esac

  start_epoch="$(now_ns)"
  started="$(timestamp)"
  : >"$log_path"
  run_bounded_command "$log_path" "$overflow_path" "$execution_text"
  status=$?
  end_epoch="$(now_ns)"
  completed="$(timestamp)"
  bytes="$(wc -c <"$log_path" | tr -d '[:space:]')"
  digest="$(sha256_file "$log_path")"
  evidence_count="$(python3 - "$log_path" "$evidence_kind" <<'PY'
import re
import sys

text = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
kind = sys.argv[2]
if kind == "tests":
    print(sum(int(item) for item in re.findall(r"(?m)^\s*(\d+) tests?,\s*\d+ failures?\b", text)))
elif kind == "journeys":
    print(sum(int(item) for item in re.findall(r"(?m)^\s*(\d+) passed(?:\s+\([^\n)]*\))?\s*$", text)))
elif kind == "checks":
    print(sum(1 for line in text.splitlines() if re.search(r"\b(?:PASS|passed)\b", line)))
else:
    print("null")
PY
)"
  if (( bytes > MAX_OUTPUT_BYTES )) || [[ -f "$overflow_path" ]]; then status=1; fi
  if [[ "$evidence_kind" != none && ( -z "$evidence_count" || "$evidence_count" == 0 ) ]]; then status=1; fi
  record_result "$commands_jsonl" "$name" "$evidence_kind" "$evidence_count" \
    "$started" "$completed" "$(((end_epoch - start_epoch) / 1000000))" \
    "$status" "$bytes" "$digest" "$execution_text"
  printf 'phase78 clean-state: command %02d/22 %s exit=%s evidence=%s bytes=%s\n' \
    "$index" "$name" "$status" "$evidence_count" "$bytes"
  [[ -f "$FLEET_PROXY_STATUS_PATH" ]] && rm -f -- "$FLEET_PROXY_STATUS_PATH"
  [[ -f "$TRACE_VISUAL_STATUS_PATH" ]] && rm -f -- "$TRACE_VISUAL_STATUS_PATH"
  return 0
}

run_started="$(timestamp)"
readonly run_started
setup_count=0
run_setup 'mix local.hex --force' 'mix local.hex --force'
run_setup 'mix local.rebar --force' 'mix local.rebar --force'
run_setup 'mix deps.get --check-locked' 'mix deps.get --check-locked'
run_setup 'owned PostgreSQL service' \
  "docker run --detach --name $db_container --label relyra.phase78.owner=$run_id --publish 127.0.0.1::5432 --env POSTGRES_HOST_AUTH_METHOD=trust postgres:16"

if docker container inspect "$db_container" >/dev/null 2>&1; then
  owner_label="$(docker inspect --format '{{ index .Config.Labels "relyra.phase78.owner" }}' "$db_container" 2>/dev/null || true)"
  if [[ "$owner_label" == "$run_id" ]]; then
    mapped_port="$(docker port "$db_container" 5432/tcp 2>/dev/null | head -n 1 | awk -F: '{print $NF}')"
    if [[ "$mapped_port" =~ ^[0-9]+$ ]]; then
      export PGPORT="$mapped_port"
      wait_command="for attempt in \$(seq 1 60); do docker exec $db_container pg_isready -U postgres -d postgres >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1"
      run_setup 'owned PostgreSQL readiness' "$wait_command"
    else
      run_setup 'owned PostgreSQL port allocation' 'false'
    fi
  else
    run_setup 'owned PostgreSQL ownership label' 'false'
  fi
else
  run_setup 'owned PostgreSQL creation' 'false'
fi

actual_otp="$(elixir -e 'IO.write(:erlang.system_info(:otp_release))' 2>/dev/null || true)"
actual_elixir="$(elixir -e 'IO.write(System.version())' 2>/dev/null || true)"
if [[ "$actual_otp" == "$otp" && "$actual_elixir" == 1.19.5 ]]; then
  run_setup 'verified toolchain' \
    "elixir -e 'IO.write(System.version() <> \"/\" <> to_string(:erlang.system_info(:otp_release)))' && docker compose version && docker buildx version"
else
  run_setup "unsupported Elixir/OTP requested $otp found $actual_elixir/$actual_otp" 'false'
fi
run_setup 'LedgerLoop test metadata' \
  'mix cmd --cd demo/ledger_loop mix deps.get && mix cmd --cd demo/ledger_loop mix compile'

manifest_names=(
  'mix format --check-formatted'
  'mix compile --warnings-as-errors'
  'mix test --warnings-as-errors'
  'mix qa'
  'mix ci.security'
  'mix ci.evidence'
  'mix ci.phase73.reconciliation'
  'mix ci.verify'
  'mix ci.integration'
  'scripts/check_clean_room_consumer.sh --profile full'
  'scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check'
  'scripts/check_clean_room_consumer.sh --profile contracts'
  'mix ci.demo_app'
  'mix cmd --cd demo/ledger_loop mix test --warnings-as-errors'
  'npm ci'
  'npm run admin-ui:smoke'
  'npm run demo:fake-idp'
  'npm run demo:trace-visual'
  'npm run demo:fleet-proxy'
  'npm run demo:keycloak-proxy'
  'bash scripts/test_trace_visual_status_contract.sh'
  'actionlint .github/workflows/*.yml'
)
manifest_kinds=(none none tests tests tests tests tests tests tests checks checks checks tests tests none journeys journeys journeys journeys journeys checks none)

command_index=0
for command_text in "${manifest_names[@]}"; do
  command_index=$((command_index + 1))
  run_command "$command_index" "$command_text" "${manifest_kinds[$((command_index - 1))]}" "$command_text"
  if [[ "$command_text" == 'npm ci' ]]; then
    run_setup 'npx playwright install chromium' 'npx playwright install chromium'
  fi
done

manifest_values="$(source_digest "$workspace")"
current_source_digest="$(printf '%s\n' "$manifest_values" | sed -n '1p')"
current_source_count="$(printf '%s\n' "$manifest_values" | sed -n '2p')"
expected_values="$(source_digest "$source_root")"
expected_digest="$(printf '%s\n' "$expected_values" | sed -n '1p')"
expected_count="$(printf '%s\n' "$expected_values" | sed -n '2p')"
if [[ "$current_source_digest" != "$expected_digest" || "$current_source_count" != "$expected_count" ]]; then
  echo 'phase78 clean-state: tracked operational source changed during the cold run' >&2
fi
if [[ -n "$(git -C "$workspace" status --porcelain --untracked-files=all)" ]]; then
  echo 'phase78 clean-state: the private checkout became dirty during the run' >&2
fi

proof_path="$workspace/.planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json"
proof_values="$(python3 - "$proof_path" <<'PY'
import hashlib
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
proof = json.loads(path.read_text(encoding="utf-8"))
print(proof.get("source_digest", ""))
print(proof.get("proof_set_id", ""))
print(hashlib.sha256(path.read_bytes()).hexdigest())
PY
)"
proof_source_digest="$(printf '%s\n' "$proof_values" | sed -n '1p')"
proof_set_id="$(printf '%s\n' "$proof_values" | sed -n '2p')"
proof_sha256="$(printf '%s\n' "$proof_values" | sed -n '3p')"

run_outcome=passed
for records in "$setup_jsonl" "$commands_jsonl"; do
  if ! python3 - "$records" <<'PY'
import json
import sys
records = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8") if line.strip()]
raise SystemExit(1 if any(record.get("exit_code") != 0 for record in records) else 0)
PY
  then run_outcome=failed; fi
done
if [[ "$current_source_digest" != "$expected_digest" || "$current_source_count" != "$expected_count" ||
      -n "$(git -C "$workspace" status --porcelain --untracked-files=all)" ||
      -z "$proof_source_digest" || -z "$proof_set_id" || ! "$proof_sha256" =~ ^[a-f0-9]{64}$ ]]; then
  run_outcome=failed
fi

run_data="$run_root/run.json"
python3 - "$run_data" "$run_id" "$actual_elixir" "$actual_otp" "$source_commit" \
  "$current_source_digest" "$current_source_count" "$proof_source_digest" "$proof_set_id" \
  "$proof_sha256" "$run_started" "$run_outcome" "$setup_jsonl" "$commands_jsonl" <<'PY'
import datetime
import hashlib
import json
import pathlib
import platform
import socket
import sys

(output, run_id, elixir, otp, commit, digest, file_count, proof_digest,
 proof_id, proof_sha, started, outcome, setup_path, commands_path) = sys.argv[1:]
host_material = "\0".join((run_id, platform.system(), platform.release(), platform.machine(), socket.gethostname()))
runner_hash = hashlib.sha256(host_material.encode("utf-8")).hexdigest()
def read_jsonl(path):
    return [json.loads(line) for line in pathlib.Path(path).read_text(encoding="utf-8").splitlines() if line]

now = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
run = {
    "run_id": run_id,
    "workspace_id": run_id,
    "runner_identity_sha256": runner_hash,
    "os": platform.system(),
    "os_release": platform.release(),
    "architecture": platform.machine(),
    "elixir_version": elixir,
    "otp_release": otp,
    "source_commit": commit,
    "source_digest": digest,
    "phase73": {"source_digest": proof_digest, "proof_set_id": proof_id, "proof_sha256": proof_sha},
    "started_at": started,
    "completed_at": now,
    "outcome": outcome,
    "setup": read_jsonl(setup_path),
    "commands": read_jsonl(commands_path),
}
payload = {
    "schema": "phase78-clean-state-run",
    "version": 1,
    "source_commit": commit,
    "source_digest": digest,
    "source_file_count": int(file_count),
    "phase73": run["phase73"],
    "generated_at": now,
    "outcome": outcome,
    "runs": [run],
}
pathlib.Path(output).write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
PY

if [[ "$output_path" == */* ]]; then output_parent="$(dirname -- "$output_path")"; mkdir -p "$output_parent"; fi
atomic_target_parent="$(CDPATH='' cd -P -- "$(dirname -- "$output_path")" && pwd)"
case "$atomic_target_parent/$(basename -- "$output_path")" in
  "$source_root"/*) echo 'phase78 clean-state: refusing to write a run receipt into the source checkout' >&2; exit 65 ;;
esac
if [[ -e "$output_path" || -L "$output_path" ]]; then echo 'phase78 clean-state: output path appeared during the run' >&2; exit 65; fi
python3 - "$output_path" "$run_data" <<'PY'
import os
import pathlib
import sys
import tempfile
target = pathlib.Path(sys.argv[1])
payload = pathlib.Path(sys.argv[2]).read_bytes()
fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", suffix=".tmp", dir=target.parent)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(payload)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, target)
finally:
    try: os.unlink(temporary)
    except FileNotFoundError: pass
PY

if [[ "$run_outcome" != passed ]]; then
  echo "phase78 clean-state: OTP $otp failed; private receipt contains actual exits and bounded output digests" >&2
  exit 1
fi
printf 'phase78 clean-state: OTP %s passed: 22 commands, %s tracked operational files, source=%s\n' \
  "$otp" "$current_source_count" "${source_commit:0:12}"
