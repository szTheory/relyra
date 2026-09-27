#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: measure_ci_cost.sh --output FILE --event NAME --cache cold|warm|none \
  --command setup:NAME:COMMAND [--command test:NAME:COMMAND ...]

Runs each shell command in order and writes a bounded JSON receipt. Commands are
trusted repository commands. A setup failure stops later execution; all statuses
and positive selected-test counts are required for a passing receipt.
USAGE
}

output=""
event=""
cache=""
declare -a commands=()

while (($#)); do
  case "$1" in
    --output|--event|--cache)
      (($# >= 2)) || { usage >&2; exit 2; }
      case "$1" in
        --output) output="$2" ;;
        --event) event="$2" ;;
        --cache) cache="$2" ;;
      esac
      shift 2
      ;;
    --command)
      (($# >= 2)) || { usage >&2; exit 2; }
      commands+=("$2")
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unsupported argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$output" || -z "$event" || ! "$cache" =~ ^(cold|warm|none)$ || ${#commands[@]} -eq 0 ]]; then
  usage >&2
  exit 2
fi

root="$(cd "$(dirname "$output")" && pwd -P)"
output="$root/$(basename "$output")"
mkdir -p "$root"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/relyra-ci-cost.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
start_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
revision="$(git rev-parse HEAD)"
dirty="$(test -z "$(git status --porcelain --untracked-files=no -- .github/workflows/security-gates.yml mix.exs scripts/check_clean_room_consumer.sh scripts/measure_ci_cost.sh test/adoption/package_consumer_ci_contract_test.exs test/support/phase_73_reconciliation.ex test/governance/phase_73_reconciliation_test.exs)" && echo false || echo true)"
os_name="$(uname -s)"
architecture="$(uname -m)"
elixir_version="$(elixir --version 2>/dev/null | sed -n 's/^Elixir //p' | head -1)"
otp_version="$(elixir -e 'IO.write(:erlang.system_info(:otp_release))' 2>/dev/null || true)"

[[ -n "$elixir_version" && -n "$otp_version" ]] || {
  echo "unable to resolve active Elixir/OTP toolchain" >&2
  exit 2
}

python3 - "$output" "$revision" "$dirty" "$event" "$os_name" "$architecture" \
  "$elixir_version" "$otp_version" "$cache" "$start_ms" <<'PY'
import json, sys
path, revision, dirty, event, os_name, arch, elixir, otp, cache, started = sys.argv[1:]
record = {
    "schema": "relyra-ci-cost-sample",
    "version": 1,
    "revision": revision,
    "dirty": dirty == "true",
    "event": event,
    "runner": {"os": os_name, "architecture": arch, "elixir": elixir, "otp": otp},
    "cache": cache,
    "steps": [],
    "setup_ms": 0,
    "job_ms": 0,
    "wall_ms": 0,
    "runner_ms": 0,
    "conclusion": "in_progress",
    "selected_tests": 0
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(record, f, sort_keys=True, separators=(",", ":"))
    f.write("\n")
PY

failed_setup=false
for spec in "${commands[@]}"; do
  kind="${spec%%:*}"
  rest="${spec#*:}"
  label="${rest%%:*}"
  command="${rest#*:}"
  if [[ "$spec" == "$kind" || "$rest" == "$label" || -z "$command" || ! "$kind" =~ ^(setup|test)$ || ! "$label" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "invalid command spec: $spec" >&2
    exit 2
  fi

  if [[ "$failed_setup" == true ]]; then
    step_status="not_run"
    exit_status="null"
    duration=0
    selected=0
  else
    step_start="$(python3 -c 'import time; print(int(time.time() * 1000))')"
    bash -euo pipefail -c "$command" >"$tmp/$label.log" 2>&1
    status=$?
    step_end="$(python3 -c 'import time; print(int(time.time() * 1000))')"
    duration=$((step_end - step_start))
    exit_status="$status"
    step_status="$( [[ "$status" == 0 ]] && echo passed || echo failed )"
    selected="$(python3 - "$tmp/$label.log" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
counts = [int(n) for n in re.findall(r"\b(\d+) tests?,\s*\d+ failures?", text)]
print(sum(counts))
PY
)"
    [[ "$kind" != setup || "$status" == 0 ]] || failed_setup=true
  fi

  python3 - "$output" "$kind" "$label" "$command" "$step_status" "$exit_status" \
    "$duration" "$selected" <<'PY'
import json, sys
path, kind, label, command, status, exit_code, duration, selected = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    r = json.load(f)
r["steps"].append({
    "kind": kind, "name": label, "command": command,
    "conclusion": status,
    "exit_code": None if exit_code == "null" else int(exit_code),
    "duration_ms": int(duration), "selected_tests": int(selected)
})
if kind == "setup":
    r["setup_ms"] += int(duration)
r["runner_ms"] += int(duration)
r["selected_tests"] += int(selected)
with open(path, "w", encoding="utf-8") as f:
    json.dump(r, f, sort_keys=True, separators=(",", ":"))
    f.write("\n")
PY
  if [[ "$step_status" == failed ]]; then
    cat "$tmp/$label.log" >&2
  fi
done

end_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
wall_ms=$((end_ms - start_ms))
python3 - "$output" "$wall_ms" <<'PY'
import json, sys
path, wall = sys.argv[1], int(sys.argv[2])
with open(path, encoding="utf-8") as f:
    r = json.load(f)
r["job_ms"] = wall
r["wall_ms"] = wall
valid = (r["selected_tests"] > 0 and r["steps"] and
         all(s["conclusion"] == "passed" and s["exit_code"] == 0 for s in r["steps"]))
r["conclusion"] = "success" if valid else "failure"
with open(path, "w", encoding="utf-8") as f:
    json.dump(r, f, sort_keys=True, separators=(",", ":"))
    f.write("\n")
PY

python3 - "$output" <<'PY'
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
print(json.dumps({k: r[k] for k in ("revision", "event", "cache", "conclusion", "wall_ms", "runner_ms", "selected_tests")}, sort_keys=True))
PY
[[ "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["conclusion"])' "$output")" == success ]]
