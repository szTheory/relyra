#!/usr/bin/env bash
set -uo pipefail

readonly RECEIPT_REL='.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json'
readonly MAX_OUTPUT_BYTES=16777216

usage() {
  cat <<'USAGE'
Usage:
  scripts/check_phase78_clean_state.sh --otp 27|28 --output <private-temp-file>
    [--diagnostics-dir <owned-private-directory>]
  scripts/check_phase78_clean_state.sh --assemble <otp27.json> <otp28.json> --checkout <git-checkout> --output <receipt.json>
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
    basename = os.path.basename(path)
    generated_phase_verification = (
        path.startswith(".planning/phases/") and basename.endswith("-VERIFICATION.md")
    )
    if path == receipt or basename.endswith("-SUMMARY.md") or generated_phase_verification:
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
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import datetime
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import tempfile

path27, path28, checkout, output_path = sys.argv[1:]
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

checkout = pathlib.Path(checkout).resolve(strict=True)
output = pathlib.Path(output_path)
head = subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True).strip()
if subprocess.run(["git", "-C", str(checkout), "diff", "--quiet", "HEAD", "--"]).returncode != 0 or subprocess.run(["git", "-C", str(checkout), "diff", "--cached", "--quiet", "HEAD", "--"]).returncode != 0:
    raise SystemExit("requested receipt checkout is dirty")
if output.is_absolute() is False:
    raise SystemExit("receipt output must be an absolute private path")
if output.resolve(strict=False).is_relative_to(checkout):
    raise SystemExit("receipt output must be outside the requested checkout")
if output.exists() or output.is_symlink():
    raise SystemExit("refusing to replace an existing receipt path")

tracked = subprocess.check_output(["git", "-C", str(checkout), "ls-files", "-z"]).split(b"\0")
manifest = []
for raw in tracked:
    if not raw:
        continue
    path = raw.decode("utf-8")
    basename = pathlib.PurePosixPath(path).name
    generated_report = path.startswith(".planning/phases/") and basename.endswith("-VERIFICATION.md")
    if path == ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json" or basename.endswith("-SUMMARY.md") or generated_report:
        continue
    file_path = checkout / path
    if not file_path.is_file():
        raise SystemExit("source manifest contains a missing or non-regular file")
    manifest.append((path, hashlib.sha256(file_path.read_bytes()).hexdigest()))
manifest.sort()
hasher = hashlib.sha256()
for path, file_hash in manifest:
    hasher.update(path.encode("utf-8"))
    hasher.update(b"\0")
    hasher.update(file_hash.encode("ascii"))
    hasher.update(b"\n")
expected_digest, expected_count = hasher.hexdigest(), len(manifest)
proof_path = checkout / ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json"
proof_bytes = proof_path.read_bytes()
proof_doc = json.loads(proof_bytes)
expected_proof = {
    "source_digest": proof_doc.get("source_digest"),
    "proof_set_id": proof_doc.get("proof_set_id"),
    "proof_sha256": hashlib.sha256(proof_bytes).hexdigest(),
}
for item in (first, second):
    if item.get("source_commit") != head:
        raise SystemExit("producer source commit does not match requested checkout HEAD")
    if item.get("source_digest") != expected_digest or item.get("source_file_count") != expected_count:
        raise SystemExit("producer source digest or file count does not match requested checkout")
    if item.get("phase73") != expected_proof:
        raise SystemExit("producer Phase 73 proof bytes do not match requested checkout")

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
target = output
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
if (($# == 7)) && [[ "$1" == "--assemble" && "$4" == "--checkout" && "$6" == "--output" ]]; then
  assemble_receipts "$2" "$3" "$5" "$7"
  exit $?
fi
if (($# == 3)) && [[ "$1" == "--diagnostic-fixture" ]]; then
  python3 - "$2" "$3" <<'PY'
import hashlib
import json
import os
import pathlib
import secrets
import subprocess
import sys
root = pathlib.Path(sys.argv[1])
checkout = pathlib.Path(sys.argv[2]).resolve(strict=True)
if not root.is_absolute() or root.exists() or root.is_symlink() or root.resolve().is_relative_to(checkout):
    raise SystemExit("fixture diagnostics path is not a fresh private path outside checkout")
root.mkdir(mode=0o700, parents=True)
(root / "logs").mkdir(mode=0o700)
run_id = secrets.token_hex(8)
(root / "owner.marker").write_text(f"{run_id}\n{('0' * 40)}\n28\n", encoding="ascii")
records = []
fixtures = [("setup", "fixture successful setup", 0, "setup-1.log", b"setup fixture output\n", 0)]
for index in range(1, 23):
    status = 1 if index == 1 else 0
    text = "fixture failing manifest command" if index == 1 else f"fixture manifest command {index}"
    payload = b"manifest fixture failed\n" if index == 1 else (text + "\n").encode("utf-8")
    fixtures.append(("manifest", text, status, f"command-{index}.log", payload, index))
for kind, command, status, name, payload, index in fixtures:
    path = root / "logs" / name
    path.write_bytes(payload)
    records.append({"command_index": index, "kind": kind, "command": command, "exit_status": status, "byte_count": len(payload), "observed_byte_count": len(payload), "sha256": hashlib.sha256(payload).hexdigest(), "log_path": name, "truncated": False})
(root / "manifest.jsonl").write_text("".join(json.dumps(item, sort_keys=True, separators=(",", ":")) + "\n" for item in records), encoding="utf-8")
status = subprocess.check_output(["git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=all"])
(root / "checkout-status.txt").write_bytes(status)
(root / "checkout-status.json").write_text(json.dumps({"command": "git status --porcelain --untracked-files=all", "exit_status": 0, "byte_count": len(status), "captured_bytes": len(status), "sha256": hashlib.sha256(status).hexdigest(), "truncated": False, "stderr_sha256": hashlib.sha256(b"").hexdigest()}, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
PY
  exit $?
fi
if (($# == 2)) && [[ "$1" == "--validate-diagnostics" ]]; then
  python3 - "$2" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
reason = None
try:
    if not root.is_absolute() or root.is_symlink() or not root.is_dir():
        raise ValueError("diagnostic root is missing, non-absolute, or a symlink")
    marker = root / "owner.marker"
    if marker.is_symlink() or not marker.is_file():
        raise ValueError("owner marker is missing or unsafe")
    marker_lines = marker.read_text(encoding="ascii").splitlines()
    if len(marker_lines) != 3 or not re.fullmatch(r"[a-f0-9]{16}", marker_lines[0]) or not re.fullmatch(r"[a-f0-9]{40}", marker_lines[1]) or marker_lines[2] not in ("27", "28"):
        raise ValueError("owner marker has an invalid identity")
    manifest_path = root / "manifest.jsonl"
    status_path = root / "checkout-status.txt"
    status_meta_path = root / "checkout-status.json"
    for item in (manifest_path, status_path, status_meta_path):
        if item.is_symlink() or not item.is_file():
            raise ValueError("required diagnostic snapshot is missing or unsafe")
        if item.stat().st_size > 1_048_576:
            raise ValueError("diagnostic metadata exceeds its byte bound")
    status_bytes = status_path.read_bytes()
    status_meta = json.loads(status_meta_path.read_text(encoding="utf-8"))
    if len(status_bytes) > 16_777_216 or status_meta.get("command") != "git status --porcelain --untracked-files=all" or status_meta.get("exit_status") != 0 or status_meta.get("truncated") is not False or status_meta.get("byte_count") != len(status_bytes) or status_meta.get("captured_bytes") != len(status_bytes) or status_meta.get("sha256") != hashlib.sha256(status_bytes).hexdigest():
        raise ValueError("checkout status snapshot is incomplete or mismatched")
    records = [json.loads(line) for line in manifest_path.read_text(encoding="utf-8").splitlines() if line]
    setup_records = [record for record in records if record.get("kind") == "setup"]
    manifest_records = [record for record in records if record.get("kind") == "manifest"]
    if len(setup_records) < 1 or len(manifest_records) != 22 or sorted(record.get("command_index") for record in manifest_records) != list(range(1, 23)):
        raise ValueError("diagnostic command manifest is incomplete")
    expected_files = {"owner.marker", "manifest.jsonl", "checkout-status.txt", "checkout-status.json", "logs"}
    logs_dir = root / "logs"
    if logs_dir.is_symlink() or not logs_dir.is_dir():
        raise ValueError("diagnostic log directory is missing or unsafe")
    seen = set()
    sentinels = re.compile(rb"-----BEGIN (?:CERTIFICATE|(?:RSA |EC |OPENSSH )?PRIVATE KEY)-----|Basic dXNlcjpwYXNz|phase78-(?:cookie|password)-sentinel|(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})|(?:authorization:\s*bearer\s+|set-cookie:\s*)", re.I)
    for record in records:
        if set(record) != {"command_index", "kind", "command", "exit_status", "byte_count", "observed_byte_count", "sha256", "log_path", "truncated"}:
            raise ValueError("diagnostic manifest has an unexpected schema")
        name = record["log_path"]
        if not isinstance(name, str) or pathlib.PurePosixPath(name).name != name or not re.fullmatch(r"(?:setup|command)-[0-9]+\.log", name) or name in seen:
            raise ValueError("diagnostic log path is unexpected")
        seen.add(name)
        item = logs_dir / name
        if item.is_symlink() or not item.is_file():
            raise ValueError("diagnostic log is missing or unsafe")
        data = item.read_bytes()
        if len(data) > 16_777_216 or record["byte_count"] != len(data) or record["observed_byte_count"] < len(data) or record["sha256"] != hashlib.sha256(data).hexdigest():
            raise ValueError("diagnostic log exceeds its bound or does not match its manifest")
        if record["truncated"] is not False:
            raise ValueError("diagnostic log was truncated")
        if sentinels.search(data):
            raise ValueError("diagnostic log matched a credential, certificate, or cookie sentinel")
    expected_files |= {"logs/" + name for name in seen}
    actual = set()
    for item in root.rglob("*"):
        if item.is_symlink():
            raise ValueError("diagnostic bundle contains a symlink")
        rel = item.relative_to(root).as_posix()
        actual.add(rel)
    if actual != expected_files:
        raise ValueError("diagnostic bundle contains missing or unexpected files")
    for rel in actual - {"logs"}:
        item = root / rel
        if item.is_file() and sentinels.search(item.read_bytes()):
            raise ValueError("diagnostic bundle matched a credential, certificate, or cookie sentinel")
except Exception as error:
    reason = str(error)
if reason:
    report = root.with_name(root.name + ".collection-blocked.json")
    try:
        report.write_text(json.dumps({"status": "blocked", "reason": reason}, sort_keys=True) + "\n", encoding="utf-8")
    except OSError:
        pass
    print("phase78 clean-state: diagnostic collection blocked: " + reason, file=sys.stderr)
    raise SystemExit(1)
print("phase78 clean-state: owned diagnostic bundle is bounded and safe")
PY
  exit $?
fi
if (($# == 3)) && [[ "$1" == "--cleanup-diagnostics" ]]; then
  python3 - "$2" "$3" "${RUNNER_TEMP:-}" <<'PY'
import pathlib
import shutil
import sys
root = pathlib.Path(sys.argv[1])
run_id = sys.argv[2]
runner_temp = pathlib.Path(sys.argv[3]).resolve()
if not root.is_absolute() or root.is_symlink() or not runner_temp.is_relative_to(root.resolve().parent) or root.parent.resolve() != runner_temp:
    raise SystemExit("phase78 clean-state: diagnostics cleanup path is outside RUNNER_TEMP")
marker = root / "owner.marker"
if marker.is_symlink() or not marker.is_file() or marker.read_text(encoding="ascii").splitlines()[0] != run_id:
    raise SystemExit("phase78 clean-state: diagnostics cleanup owner does not match")
shutil.rmtree(root)
PY
  exit $?
fi

otp=""
output_path=""
diagnostics_root=""
while (($#)); do
  case "$1" in
    --otp) (($# >= 2)) || { usage >&2; exit 64; }; otp="$2"; shift 2 ;;
    --output) (($# >= 2)) || { usage >&2; exit 64; }; output_path="$2"; shift 2 ;;
    --diagnostics-dir) (($# >= 2)) || { usage >&2; exit 64; }; diagnostics_root="$2"; shift 2 ;;
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
if [[ -z "$diagnostics_root" ]]; then
  [[ -n "${RUNNER_TEMP:-}" ]] || { echo 'phase78 clean-state: RUNNER_TEMP or --diagnostics-dir is required' >&2; exit 64; }
  diagnostics_root="$RUNNER_TEMP/phase78-otp$otp-diagnostics"
fi
case "$diagnostics_root" in /*) ;; *) echo 'phase78 clean-state: diagnostics directory must be absolute' >&2; exit 65 ;; esac
tmp_parent="${TMPDIR:-/tmp}"
tmp_parent="$(CDPATH='' cd -P -- "$tmp_parent" && pwd)" || exit 70
run_root="$(umask 077; mktemp -d "$tmp_parent/relyra-phase78-cold-$run_id.XXXXXX")" || exit 70
run_root="$(CDPATH='' cd -P -- "$run_root" && pwd)"
[[ "$run_root" == "$tmp_parent"/relyra-phase78-cold-"$run_id".* ]] || { echo "phase78 clean-state: unsafe temporary workspace" >&2; exit 70; }
diagnostics_root="$(python3 - "$diagnostics_root" <<'PY'
import os
import sys
print(os.path.abspath(sys.argv[1]))
PY
)"
case "$diagnostics_root" in "$source_root"|"$source_root"/*) echo 'phase78 clean-state: diagnostics must be outside source checkout' >&2; exit 65 ;; esac
if [[ -e "$diagnostics_root" || -L "$diagnostics_root" ]]; then
  echo 'phase78 clean-state: refusing to replace an existing diagnostics directory' >&2
  exit 65
fi
umask 077
mkdir -m 700 -- "$diagnostics_root" || exit 70
workspace="$run_root/checkout"
logs="$diagnostics_root/logs"
mkdir -m 700 "$logs"
mkdir -p "$run_root/home" "$run_root/tmp" "$run_root/runner-temp" \
  "$run_root/mix-home" "$run_root/hex-home" "$run_root/mix-archives" \
  "$run_root/npm-cache" "$run_root/playwright-browsers"
printf '%s\n%s\n%s\n' "$run_id" "$source_commit" "$otp" >"$diagnostics_root/owner.marker"
chmod 600 "$diagnostics_root/owner.marker"

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

# The clone log stays in the private run root: the diagnostics bundle may only
# hold manifest-recorded logs, and --validate-diagnostics rejects anything else.
clone_log="$run_root/clone.log"
if ! git clone --no-local --no-checkout --quiet "$source_root" "$workspace" >"$clone_log" 2>&1 ||
   ! git -C "$workspace" fetch --quiet "$source_root" "$source_commit" >>"$clone_log" 2>&1 ||
   ! git -C "$workspace" checkout --quiet --detach "$source_commit" >>"$clone_log" 2>&1; then
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
diagnostic_manifest="$diagnostics_root/manifest.jsonl"
: >"$setup_jsonl"
: >"$commands_jsonl"
: >"$diagnostic_manifest"
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
observed = 0
captured = 0
with open(log_path, "wb") as stream:
    while True:
        chunk = process.stdout.read(65536)
        if not chunk:
            break
        observed += len(chunk)
        remaining = max(0, limit - captured)
        if remaining:
            retained = chunk[:remaining]
            stream.write(retained)
            captured += len(retained)

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

record_diagnostic() {
  python3 - "$diagnostic_manifest" "$1" "$2" "$3" "$4" "$5" "$6" <<'PY'
import hashlib
import json
import pathlib
import sys
destination, index, kind, command, status, log_path, overflow_path = sys.argv[1:]
log = pathlib.Path(log_path)
observed = int(pathlib.Path(overflow_path).read_text(encoding="ascii").strip()) if pathlib.Path(overflow_path).exists() else log.stat().st_size
payload = {
    "command_index": int(index),
    "kind": kind,
    "command": command,
    "exit_status": int(status),
    "byte_count": log.stat().st_size,
    "observed_byte_count": observed,
    "sha256": hashlib.sha256(log.read_bytes()).hexdigest(),
    "log_path": log.name,
    "truncated": pathlib.Path(overflow_path).exists(),
}
with open(destination, "a", encoding="utf-8") as stream:
    stream.write(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")
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
  local name="$1" command_text="$2" log_path overflow_path start_epoch end_epoch started completed status original_status bytes digest
  setup_count=$((setup_count + 1))
  log_path="$logs/setup-$setup_count.log"
  overflow_path="$log_path.overflow"
  start_epoch="$(now_ns)"
  started="$(timestamp)"
  : >"$log_path"
  run_bounded_command "$log_path" "$overflow_path" "$command_text"
  status=$?
  original_status="$status"
  end_epoch="$(now_ns)"
  completed="$(timestamp)"
  bytes="$(wc -c <"$log_path" | tr -d '[:space:]')"
  digest="$(sha256_file "$log_path")"
  if [[ -f "$overflow_path" ]]; then status=1; fi
  record_result "$setup_jsonl" "$name" setup null "$started" "$completed" \
    "$(((end_epoch - start_epoch) / 1000000))" "$status" "$bytes" "$digest" "$command_text"
  record_diagnostic "$setup_count" setup "$command_text" "$original_status" "$log_path" "$overflow_path"
  printf 'phase78 clean-state: setup %s exit=%s bytes=%s\n' "$name" "$status" "$bytes"
  return 0
}

run_command() {
  local index="$1" name="$2" evidence_kind="$3" command_text="$4"
  local execution_text="$command_text"
  local log_path="$logs/command-$index.log" overflow_path="$logs/command-$index.log.overflow"
  local start_epoch end_epoch started completed status original_status bytes digest evidence_count

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
  original_status="$status"
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
  if [[ -f "$overflow_path" ]]; then status=1; fi
  if [[ "$evidence_kind" != none && ( -z "$evidence_count" || "$evidence_count" == 0 ) ]]; then status=1; fi
  record_result "$commands_jsonl" "$name" "$evidence_kind" "$evidence_count" \
    "$started" "$completed" "$(((end_epoch - start_epoch) / 1000000))" \
    "$status" "$bytes" "$digest" "$execution_text"
  record_diagnostic "$index" manifest "$execution_text" "$original_status" "$log_path" "$overflow_path"
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

status_path="$diagnostics_root/checkout-status.txt"
status_metadata="$diagnostics_root/checkout-status.json"
python3 - "$workspace" "$status_path" "$status_metadata" "$MAX_OUTPUT_BYTES" <<'PY'
import hashlib
import json
import pathlib
import subprocess
import sys
workspace, output_path, metadata_path, limit_raw = sys.argv[1:]
limit = int(limit_raw)
command = ["git", "-C", workspace, "status", "--porcelain", "--untracked-files=all"]
process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
observed = 0
captured = 0
digest = hashlib.sha256()
with open(output_path, "wb") as stream:
    while True:
        chunk = process.stdout.read(65536)
        if not chunk:
            break
        observed += len(chunk)
        digest.update(chunk)
        remaining = max(0, limit - captured)
        if remaining:
            part = chunk[:remaining]
            stream.write(part)
            captured += len(part)
stderr = process.stderr.read()
status = process.wait()
truncated = observed > captured
pathlib.Path(metadata_path).write_text(json.dumps({
    "command": "git status --porcelain --untracked-files=all",
    "exit_status": status,
    "byte_count": observed,
    "captured_bytes": captured,
    "sha256": digest.hexdigest(),
    "truncated": truncated,
    "stderr_sha256": hashlib.sha256(stderr).hexdigest(),
}, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
if status != 0 or truncated:
    raise SystemExit(1)
PY
status_snapshot_exit=$?

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
if [[ "$status_snapshot_exit" != 0 ]]; then run_outcome=failed; fi
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
