#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile="full"
contract_case=""
concurrency_check="false"

while (($#)); do
  case "$1" in
    --profile)
      if (($# < 2)); then
        echo "package consumer: --profile requires a value" >&2
        exit 2
      fi
      profile="$2"
      shift 2
      ;;
    --case)
      if (($# < 2)); then
        echo "package consumer: --case requires a value" >&2
        exit 2
      fi
      contract_case="$2"
      shift 2
      ;;
    --concurrency-check)
      concurrency_check="true"
      shift
      ;;
    *)
      echo "package consumer: unsupported argument '$1'" >&2
      exit 2
      ;;
  esac
done

if [[ "$profile" != "full" && "$profile" != "contracts" && "$profile" != "minimal" ]]; then
  echo "package consumer: unsupported profile '$profile'; use --profile full, minimal or contracts" >&2
  exit 2
fi

if [[ "$profile" == "full" && -n "$contract_case" ]]; then
  echo "package consumer: --case is only valid with --profile contracts" >&2
  exit 2
fi

if [[ "$profile" != "minimal" && "$concurrency_check" == "true" ]]; then
  echo "package consumer: --concurrency-check is only valid with --profile minimal" >&2
  exit 2
fi

if [[ "$profile" == "contracts" && -z "$contract_case" ]]; then
  "$0" --profile contracts --case omission
  "$0" --profile contracts --case fresh
  "$0" --profile contracts --case prior
  printf 'package consumer [contracts]: PASS — omission, fresh installer and prior scaffold contracts\n'
  exit 0
fi

if [[ "$profile" == "minimal" && "$concurrency_check" == "true" ]]; then
  concurrency_root="$(mktemp -d "${TMPDIR:-/tmp}/relyra-package-consumer-race.XXXXXX")"
  concurrency_root="$(cd "$concurrency_root" && pwd -P)"
  trap 'rm -rf "$concurrency_root"' EXIT
  "$repo_root/scripts/check_clean_room_consumer.sh" --profile minimal >"$concurrency_root/run-a.log" 2>&1 &
  pid_a=$!
  "$repo_root/scripts/check_clean_room_consumer.sh" --profile minimal >"$concurrency_root/run-b.log" 2>&1 &
  pid_b=$!
  status_a=0
  status_b=0
  wait "$pid_a" || status_a=$?
  wait "$pid_b" || status_b=$?
  if [[ "$status_a" != "0" || "$status_b" != "0" ]]; then
    echo "package consumer: minimal concurrency check failed: run A exit=$status_a, run B exit=$status_b; inspect $concurrency_root/run-a.log and run-b.log, then rerun --profile minimal --concurrency-check" >&2
    exit 1
  fi
  receipt_a="$(grep '^ISOLATION_RECEIPT|' "$concurrency_root/run-a.log" | tail -n 1)"
  receipt_b="$(grep '^ISOLATION_RECEIPT|' "$concurrency_root/run-b.log" | tail -n 1)"
  IFS='|' read -r _ root_a artifact_a consumer_a mix_a hex_a archives_a deps_a build_a output_a <<<"$receipt_a"
  IFS='|' read -r _ root_b artifact_b consumer_b mix_b hex_b archives_b deps_b build_b output_b <<<"$receipt_b"
  if [[ -z "$root_a" || -z "$root_b" ]]; then
    echo "package consumer: minimal concurrency check failed: expected one isolation receipt per run; inspect $concurrency_root/run-a.log and run-b.log" >&2
    exit 1
  fi
  paths_a=("$root_a" "$artifact_a" "$consumer_a" "$mix_a" "$hex_a" "$archives_a" "$deps_a" "$build_a" "$output_a")
  paths_b=("$root_b" "$artifact_b" "$consumer_b" "$mix_b" "$hex_b" "$archives_b" "$deps_b" "$build_b" "$output_b")
  for path_a in "${paths_a[@]}"; do
    for path_b in "${paths_b[@]}"; do
      if [[ "$path_a" == "$path_b" || "$path_a/" == "$path_b/"* || "$path_b/" == "$path_a/"* ]]; then
        echo "package consumer: minimal concurrency isolation failed: path sets overlap at $path_a and $path_b; inspect both run receipts and make every path run-owned" >&2
        exit 1
      fi
    done
  done
  grep -h '^minimal compile: PASS' "$concurrency_root/run-a.log" "$concurrency_root/run-b.log"
  printf 'package consumer [minimal]: PASS — concurrent run roots and all mutable paths are disjoint\n'
  printf 'ISOLATION_RECEIPT_A|%s\nISOLATION_RECEIPT_B|%s\n' "${paths_a[*]}" "${paths_b[*]}"
  exit 0
fi

run_root="$(mktemp -d "${TMPDIR:-/tmp}/relyra-package-consumer.XXXXXX")"
run_root="$(cd "$run_root" && pwd -P)"
artifact_output="$run_root/artifact-output"
consumer_dir="$run_root/consumer"
mix_home="$run_root/mix-home"
hex_home="$run_root/hex-home"
mix_archives="$run_root/mix-archives"
deps_path="$run_root/deps"
build_root="$run_root/build"
db_data="$run_root/postgres-data"
output_dir="$run_root/output"
container_name="relyra-consumer-$(basename "$run_root" | tr -cd '[:alnum:]')"
db_user="package_consumer"
db_name="package_consumer"
db_password="$(openssl rand -hex 24)"
db_port=""
command_count=0
last_command_log=""

mkdir -p "$artifact_output" "$consumer_dir" "$mix_home" "$hex_home" \
  "$mix_archives" "$deps_path" "$build_root" "$db_data" "$output_dir" \
  "$run_root/home" "$run_root/xdg-config" "$run_root/xdg-cache"

isolated_env=(
  "PATH=$PATH"
  "HOME=$run_root/home"
  "XDG_CONFIG_HOME=$run_root/xdg-config"
  "XDG_CACHE_HOME=$run_root/xdg-cache"
  "MIX_HOME=$mix_home"
  "HEX_HOME=$hex_home"
  "MIX_ARCHIVES=$mix_archives"
  "MIX_DEPS_PATH=$deps_path"
  "MIX_BUILD_ROOT=$build_root"
  "PACKAGE_CONSUMER_RUN_ROOT=$run_root"
  "PACKAGE_CONSUMER_PROFILE=$([[ "$profile" == "contracts" ]] && echo full || echo "$profile")"
  "PACKAGE_CONSUMER_ARTIFACT_OUTPUT=$artifact_output"
  "PACKAGE_CONSUMER_CONSUMER=$consumer_dir"
  "PACKAGE_CONSUMER_CHECKOUT=$repo_root"
  "PACKAGE_CONSUMER_DB_USER=$db_user"
  "PACKAGE_CONSUMER_DB_NAME=$db_name"
  "PACKAGE_CONSUMER_DB_PASSWORD=$db_password"
  "LANG=${LANG:-C.UTF-8}"
  "LC_ALL=${LC_ALL:-C.UTF-8}"
)

if [[ -n "${ASDF_DATA_DIR:-}" ]]; then
  isolated_env+=("ASDF_DATA_DIR=$ASDF_DATA_DIR")
fi
if [[ -n "${ASDF_ELIXIR_VERSION:-}" ]]; then
  isolated_env+=("ASDF_ELIXIR_VERSION=$ASDF_ELIXIR_VERSION")
fi
if [[ -n "${ASDF_ERLANG_VERSION:-}" ]]; then
  isolated_env+=("ASDF_ERLANG_VERSION=$ASDF_ERLANG_VERSION")
fi

run_command() {
  local label="$1"
  local description="$2"
  local cwd="$3"
  shift 3

  command_count=$((command_count + 1))
  local log_path="$output_dir/$(printf '%02d' "$command_count")-$label.log"
  last_command_log="$log_path"
  printf 'package consumer [%s]: %s\n' "$profile" "$description"

  if (cd "$cwd" && env -i "${isolated_env[@]}" "$@") >"$log_path" 2>&1; then
    grep -E '^[[:alnum:] _-]+: PASS' "$log_path" || true
    printf 'PASS: %s\n' "$label"
  else
    local status=$?
    printf 'FAIL: %s exited %s. Expected %s.\n' "$description" "$status" "$label" >&2
    printf 'Log retained at %s. Next: inspect that command log, fix the reported contract, then rerun scripts/check_clean_room_consumer.sh --profile full.\n' "$log_path" >&2
    return "$status"
  fi
}

cleanup() {
  local status=$?

  if docker container inspect "$container_name" >/dev/null 2>&1; then
    docker stop "$container_name" >/dev/null 2>&1 || true
    docker rm "$container_name" >/dev/null 2>&1 || true
  fi

  if [[ "$status" == "0" ]] || [[ "${CI:-}" == "true" ]] || [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    rm -rf "$run_root"
  else
    printf 'package consumer [%s]: failure state retained at %s\n' "$profile" "$run_root" >&2
  fi
}
trap cleanup EXIT

assert_under_run_root() {
  local path
  for path in "$@"; do
    case "$path/" in
      "$run_root/"*) ;;
      *)
        echo "package consumer: isolation contract failed: mutable path is outside the owned run root: $path" >&2
        exit 1
        ;;
    esac
  done
}

assert_under_run_root \
  "$artifact_output" "$consumer_dir" "$mix_home" "$hex_home" "$mix_archives" \
  "$deps_path" "$build_root" "$db_data" "$output_dir"

run_command hex-bootstrap "bootstrap Hex in isolated Mix/Hex homes" "$repo_root" mix local.hex --force
run_command rebar-bootstrap "bootstrap Rebar in isolated Mix home" "$repo_root" mix local.rebar --force
run_command artifact-build "mix hex.build --unpack --output <owned-run-root>/artifact-output" \
  "$repo_root" mix hex.build --unpack --output "$artifact_output"

artifact_mix_file="$(find "$artifact_output" -type f -name mix.exs -print -quit)"
if [[ -z "$artifact_mix_file" ]]; then
  echo "package consumer: artifact contract failed: unpacked Hex artifact has no mix.exs; rebuild the local package and rerun the full profile" >&2
  exit 1
fi
artifact_root="$(cd "$(dirname "$artifact_mix_file")" && pwd -P)"
case "$artifact_root/" in
  "$artifact_output/"*) ;;
  *)
    echo "package consumer: artifact contract failed: unpacked package escaped the owned artifact directory ($artifact_root)" >&2
    exit 1
    ;;
esac

if [[ "$profile" == "minimal" ]]; then
  cp -R "$repo_root/test/fixtures/package_consumer/consumer/." "$consumer_dir/"
  isolated_env+=("PACKAGE_CONSUMER_RELYRA_PATH=$artifact_root" "PACKAGE_CONSUMER_ARTIFACT_ROOT=$artifact_root")
  run_command minimal-deps "resolve the minimal consumer with Relyra as its only direct dependency" \
    "$consumer_dir" mix deps.get
  run_command minimal-compile "compile without optional dependencies and warnings" \
    "$consumer_dir" mix compile --no-optional-deps --warnings-as-errors
  probe=''
  probe+='source = Mix.Project.deps_paths()[:relyra] |> Path.expand(); '
  probe+='build = :code.lib_dir(:relyra) |> to_string() |> Path.expand(); '
  probe+='artifact = Path.expand(System.fetch_env!("PACKAGE_CONSUMER_ARTIFACT_ROOT")); '
  probe+='checkout = Path.expand(System.fetch_env!("PACKAGE_CONSUMER_CHECKOUT")); '
  probe+='build_root = Path.expand(System.fetch_env!("MIX_BUILD_ROOT")); '
  probe+='inside = fn path, root -> relative = Path.relative_to(path, root); relative not in [".", ".."] and Path.type(relative) == :relative and not String.starts_with?(relative, "../") end; '
  probe+='unless (source == artifact or inside.(source, artifact)) and not inside.(source, checkout), do: raise("minimal package provenance failed: resolved source is outside this unpacked artifact (source=#{source}; artifact=#{artifact})"); '
  probe+='unless inside.(build, build_root), do: raise("minimal package provenance failed: compiled application is outside this isolated build root"); '
  probe+='unless Code.ensure_loaded?(Relyra.Testing), do: raise("minimal package contract failed: public Relyra.Testing helper is unavailable"); '
  probe+='if Code.ensure_loaded?(Relyra.TestSupport), do: raise("minimal package contract failed: private support leaked into consumer"); '
  probe+='optional = [Phoenix.Router, Ecto.Repo, Postgrex, Req] |> Enum.filter(&Code.ensure_loaded?/1); '
  probe+='unless optional == [], do: raise("minimal package contract failed: optional integration modules loaded"); '
  probe+='checkout_path = :code.get_path() |> Enum.map(&(to_string(&1))) |> Enum.find(&String.contains?(&1, checkout)); '
  probe+='if checkout_path, do: raise("minimal package contract failed: checkout path present in code path"); '
  probe+='IO.puts("minimal compile: PASS — optional Phoenix/Ecto/Postgrex/Req modules absent; public helper available; private support unavailable"); '
  probe+='IO.puts("ISOLATION_RECEIPT|#{System.fetch_env!("PACKAGE_CONSUMER_RUN_ROOT")}|#{artifact}|#{System.fetch_env!("PACKAGE_CONSUMER_CONSUMER")}|#{System.fetch_env!("MIX_HOME")}|#{System.fetch_env!("HEX_HOME")}|#{System.fetch_env!("MIX_DEPS_PATH")}|#{build_root}|#{System.fetch_env!("PACKAGE_CONSUMER_RUN_ROOT")}/output")'
  run_command minimal-provenance "assert artifact source, isolated build output and optional module absence" \
    "$consumer_dir" mix run --no-start -e "$probe"
  printf 'ISOLATION_RECEIPT|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$run_root" "$artifact_root" "$consumer_dir" "$mix_home" "$hex_home" "$mix_archives" "$deps_path" "$build_root" "$output_dir"
  exit 0
fi

if [[ "$profile" == "contracts" ]]; then
  if [[ -n "$contract_case" && "$contract_case" != "omission" && "$contract_case" != "fresh" && "$contract_case" != "prior" ]]; then
    echo "package consumer: unknown contracts case '$contract_case' (valid: omission, fresh, prior)" >&2
    exit 2
  fi

  if [[ -z "$contract_case" || "$contract_case" == "omission" ]]; then
    required_file="lib/relyra/testing.ex"
    if [[ ! -f "$artifact_root/$required_file" ]]; then
      echo "package consumer: omission control invalid: baseline artifact lacks $required_file; restore the packaged public helper before running this case" >&2
      exit 1
    fi

    omission_dir="$run_root/omission"
    omitted_artifact="$omission_dir/artifact"
    omission_consumer="$omission_dir/consumer"
    mkdir -p "$omission_dir"
    cp -R "$artifact_root" "$omitted_artifact"
    rm "$omitted_artifact/$required_file"
    cp -R "$repo_root/test/fixtures/package_consumer/consumer/." "$omission_consumer/"
    mkdir -p "$omission_consumer/config"
    cat >"$omission_consumer/config/config.exs" <<'CONFIG'
import Config
config :package_consumer, ecto_repos: [PackageConsumer.Repo]
CONFIG
    for env_file in dev test prod; do printf 'import Config\n' >"$omission_consumer/config/$env_file.exs"; done

    isolated_env+=("PACKAGE_CONSUMER_RELYRA_PATH=$omitted_artifact" "PACKAGE_CONSUMER_ARTIFACT_ROOT=$omitted_artifact")
    isolated_env+=("MIX_DEPS_PATH=$omission_dir/deps" "MIX_BUILD_ROOT=$omission_dir/build")
    run_command omission-deps "resolve dependencies from the single-file-mutated artifact" "$omission_consumer" mix deps.get
    run_command omission-compile "compile the consumer against the mutated artifact" "$omission_consumer" mix compile --warnings-as-errors

    omission_log="$output_dir/omission-contract.log"
    if (cd "$omission_consumer" && env -i "${isolated_env[@]}" mix run --no-start -e '
      if Code.ensure_loaded?(Relyra.Testing) do
        raise "package omission control failed: Relyra.Testing remained loadable"
      end
      if Code.ensure_loaded?(Relyra.TestSupport) do
        raise "package omission control failed: private support leaked into consumer"
      end
      checkout = System.fetch_env!("PACKAGE_CONSUMER_CHECKOUT")
      loaded_paths = :code.get_path() |> Enum.map(&(to_string(&1)))
      if Enum.any?(loaded_paths, &String.contains?(&1, checkout)) do
        raise "package omission control failed: checkout code path detected"
      end
      raise "package contract missing: lib/relyra/testing.ex"
    ') >"$omission_log" 2>&1; then
      echo "package consumer: omission contract failed: mutated package still loaded Relyra.Testing; restore $required_file to the packaged-files list" >&2
      exit 1
    fi

    if ! grep -Fq "package contract missing: $required_file" "$omission_log"; then
      echo "package consumer: omission control invalid: child command failed for an unrelated reason; expected package contract missing: $required_file. Inspect $omission_log, fix that prerequisite, then rerun --profile contracts --case omission" >&2
      exit 1
    fi

    printf 'package consumer [contracts]: PASS — isolated child failed specifically for missing %s; mutated source %s; command mix run --no-start -e package-contract-check; next: restore the required file to the package file list\n' "$required_file" "$omitted_artifact/$required_file"
    exit 0
  fi
fi

cp -R "$repo_root/test/fixtures/package_consumer/consumer/." "$consumer_dir/"
mkdir -p "$consumer_dir/config"
cat >"$consumer_dir/config/config.exs" <<'CONFIG'
import Config

config :package_consumer,
  ecto_repos: [PackageConsumer.Repo]

config :package_consumer, PackageConsumer.Repo,
  username: System.fetch_env!("PACKAGE_CONSUMER_DB_USER"),
  password: System.fetch_env!("PACKAGE_CONSUMER_DB_PASSWORD"),
  hostname: "127.0.0.1",
  database: System.fetch_env!("PACKAGE_CONSUMER_DB_NAME"),
  port: String.to_integer(System.fetch_env!("PACKAGE_CONSUMER_DB_PORT")),
  pool_size: 5

config :package_consumer, PackageConsumerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("c", 64),
  server: false,
  render_errors: [formats: [html: PackageConsumerWeb.ErrorHTML], layout: false],
  pubsub_server: PackageConsumer.PubSub

config :relyra,
  connection_resolver: PackageConsumer.ProofResolver,
  request_store: Relyra.RequestStore.ETS,
  replay_store: Relyra.ReplayStore.ETS,
  user_mapper: PackageConsumer.ProofMapper,
  session_adapter: PackageConsumer.ProofSessionAdapter

import_config "#{config_env()}.exs"
CONFIG
cat >"$consumer_dir/config/dev.exs" <<'CONFIG'
import Config
CONFIG
cat >"$consumer_dir/config/test.exs" <<'CONFIG'
import Config
CONFIG
cat >"$consumer_dir/config/prod.exs" <<'CONFIG'
import Config
CONFIG

if [[ "$profile" == "contracts" && "$contract_case" == "prior" ]]; then
  mkdir -p "$consumer_dir/lib/package_consumer/relyra"
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/connections.ex" \
    "$consumer_dir/lib/package_consumer/relyra/connections.ex"
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/user_mapper.ex" \
    "$consumer_dir/lib/package_consumer/relyra/user_mapper.ex"
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer_web/router.ex" \
    "$consumer_dir/lib/package_consumer_web/router.ex"
  cat "$repo_root/test/fixtures/package_consumer/prior_scaffold/config/config.exs" >>"$consumer_dir/config/config.exs"
  isolated_env+=("PACKAGE_CONSUMER_SCAFFOLD=prior")
fi

docker run -d --name "$container_name" \
  -e POSTGRES_USER="$db_user" \
  -e POSTGRES_PASSWORD="$db_password" \
  -e POSTGRES_DB="$db_name" \
  -p 127.0.0.1::5432 \
  --mount "type=bind,src=$db_data,dst=/var/lib/postgresql/data" \
  postgres:16 >"$output_dir/postgres-start.log" 2>&1 || {
    echo "package consumer: PostgreSQL contract failed: could not start owned postgres:16 container with data under $db_data; check Docker availability and rerun the full profile" >&2
    exit 1
  }

port_mapping="$(docker port "$container_name" 5432/tcp 2>/dev/null | head -n 1)"
db_port="${port_mapping##*:}"
if [[ -z "$db_port" || "$db_port" == "$port_mapping" ]]; then
  echo "package consumer: PostgreSQL contract failed: Docker did not publish a loopback port; inspect $output_dir/postgres-start.log" >&2
  exit 1
fi
isolated_env+=("PACKAGE_CONSUMER_DB_PORT=$db_port")

ready="false"
for _attempt in $(seq 1 60); do
  if docker exec "$container_name" pg_isready -U "$db_user" -d "$db_name" >/dev/null 2>&1; then
    ready="true"
    break
  fi
  sleep 1
done

if [[ "$ready" != "true" ]]; then
  echo "package consumer: PostgreSQL contract failed: owned postgres:16 did not become ready within 60 seconds; inspect $output_dir/postgres-start.log and verify Docker health" >&2
  exit 1
fi

isolated_env+=("PACKAGE_CONSUMER_RELYRA_PATH=$artifact_root")
isolated_env+=("PACKAGE_CONSUMER_ARTIFACT_ROOT=$artifact_root")

run_command deps-get "resolve dependencies with Relyra from the unpacked artifact" \
  "$consumer_dir" mix deps.get
if [[ "$profile" == "contracts" && "$contract_case" == "prior" ]]; then
  prior_files=(
    "config/config.exs"
    "lib/package_consumer/relyra/connections.ex"
    "lib/package_consumer/relyra/user_mapper.ex"
    "lib/package_consumer_web/router.ex"
  )
  before_manifest="$output_dir/prior-before.sha256"
  (cd "$consumer_dir" && shasum -a 256 "${prior_files[@]}") >"$before_manifest"
fi
run_command installer "run the public Phoenix consumer installer" "$consumer_dir" \
  mix relyra.install --module PackageConsumer --router lib/package_consumer_web/router.ex --repo PackageConsumer.Repo

if [[ "$profile" == "contracts" && "$contract_case" == "prior" ]]; then
  prior_files=(
    "config/config.exs"
    "lib/package_consumer/relyra/connections.ex"
    "lib/package_consumer/relyra/user_mapper.ex"
    "lib/package_consumer_web/router.ex"
  )
  after_manifest="$output_dir/prior-after.sha256"
  # Hash once more after the normal installer to prove every adopter-owned byte survived.
  (cd "$consumer_dir" && shasum -a 256 "${prior_files[@]}") >"$after_manifest"
  for relative_path in "${prior_files[@]}"; do
    expected_hash="$(awk -v path="$relative_path" '$2 == path {print $1}' "$before_manifest")"
    actual_hash="$(awk -v path="$relative_path" '$2 == path {print $1}' "$after_manifest")"
    if [[ "$actual_hash" != "$expected_hash" ]]; then
      echo "package consumer: prior scaffold incompatibility at $relative_path: expected byte-identical hash $expected_hash after ordinary reinstall; actual $actual_hash. Restore the non-force overwrite contract and rerun --profile contracts --case prior." >&2
      exit 1
    fi
  done
  installer_log="$output_dir/$(printf '%02d' "$command_count")-installer.log"
  for expected_receipt in \
    "Skipped existing lib/package_consumer/relyra/connections.ex" \
    "Skipped existing lib/package_consumer/relyra/user_mapper.ex" \
    "Relyra SAML routes already present in lib/package_consumer_web/router.ex"; do
    if ! grep -Fq "$expected_receipt" "$installer_log"; then
      echo "package consumer: prior scaffold receipt drift: expected '$expected_receipt' from the ordinary installer; actual receipt is in $installer_log. Review installer compatibility before refreshing fixtures." >&2
      exit 1
    fi
  done
  if [[ "$(grep -c 'saml_routes()' "$consumer_dir/lib/package_consumer_web/router.ex")" != "1" ]]; then
    echo "package consumer: prior scaffold router contract drift at lib/package_consumer_web/router.ex: expected one saml_routes() marker; check route preservation and duplication." >&2
    exit 1
  fi
  if ! run_command prior-compile "compile the preserved prior scaffold with warnings as errors" "$consumer_dir" \
    mix compile --warnings-as-errors; then
    incompatible_path="$(grep -Eo 'lib/package_consumer(_web)?/[^ :]+\.ex' "$last_command_log" | head -n 1 || true)"
    echo "package consumer: prior scaffold compile incompatibility at ${incompatible_path:-consumer compile contract}: expected a warnings-as-errors build; actual compiler failure is recorded in $last_command_log. Fix that seeded callback/router against the current published behaviour, then rerun --profile contracts --case prior." >&2
    exit 1
  fi
  if ! run_command prior-acs "run signed ACS through preserved prior resolver, mapper and router" "$consumer_dir" \
    mix run smoke/signed_acs.exs; then
    if grep -Fq 'package consumer contract failed (ACS route response)' "$last_command_log"; then
      echo "package consumer: prior scaffold route drift at POST /conn-123/acs: expected HTTP 302 /welcome through the preserved router; actual response failed. Repair the route marker/contract, then rerun --profile contracts --case prior." >&2
    else
      echo "package consumer: prior scaffold callback integration drift at connections.ex or user_mapper.ex: expected the preserved callbacks to record the verified alice@example.com host receipt; actual smoke failure is recorded in $last_command_log. Repair the named behaviour callback, then rerun --profile contracts --case prior." >&2
    fi
    exit 1
  fi

  force_dir="$run_root/force-consumer"
  mkdir -p "$force_dir"
  cp -R "$repo_root/test/fixtures/package_consumer/consumer/." "$force_dir/"
  mkdir -p "$force_dir/config" "$force_dir/lib/package_consumer/relyra"
  cp "$consumer_dir/mix.lock" "$force_dir/mix.lock"
  cp "$consumer_dir/config/config.exs" "$force_dir/config/config.exs"
  for env_file in dev test prod; do printf 'import Config\n' >"$force_dir/config/$env_file.exs"; done
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/connections.ex" \
    "$force_dir/lib/package_consumer/relyra/connections.ex"
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/user_mapper.ex" \
    "$force_dir/lib/package_consumer/relyra/user_mapper.ex"
  cp "$repo_root/test/fixtures/package_consumer/prior_scaffold/lib/package_consumer_web/router.ex" \
    "$force_dir/lib/package_consumer_web/router.ex"
  force_before="$output_dir/force-before.sha256"
  (cd "$force_dir" && shasum -a 256 "${prior_files[@]}") >"$force_before"
  run_command prior-force "run the public installer with explicit force in a separate copy" "$force_dir" \
    mix relyra.install --module PackageConsumer --router lib/package_consumer_web/router.ex --repo PackageConsumer.Repo --force
  for relative_path in "${prior_files[1]}" "${prior_files[2]}"; do
    if cmp -s "$force_dir/$relative_path" "$consumer_dir/$relative_path"; then
      echo "package consumer: force contract drift at $relative_path: --force retained prior bytes; expected current generated bytes. Check ensure_generated_file! force behavior." >&2
      exit 1
    fi
    expected_hash="$(awk -v path="$relative_path" '$2 == path {print $1}' "$repo_root/test/fixtures/package_consumer/golden/fresh_files.sha256")"
    actual_hash="$(shasum -a 256 "$force_dir/$relative_path" | awk '{print $1}')"
    if [[ -z "$expected_hash" || "$actual_hash" != "$expected_hash" ]]; then
      echo "package consumer: force output drift at $relative_path: expected fresh golden hash $expected_hash; actual $actual_hash. Review the generated template before updating goldens." >&2
      exit 1
    fi
  done
  if [[ "$(grep -c 'saml_routes()' "$force_dir/lib/package_consumer_web/router.ex")" != "1" ]] ||
     ! cmp -s "$force_dir/config/config.exs" "$consumer_dir/config/config.exs" ||
     ! cmp -s "$force_dir/lib/package_consumer_web/router.ex" "$consumer_dir/lib/package_consumer_web/router.ex"; then
    echo "package consumer: force changed protected config or duplicated the router; expected only generated resolver/mapper files to be overwritten." >&2
    exit 1
  fi
  printf 'package consumer [contracts]: PASS — prior scaffold survived ordinary rerun, signed ACS passed, and explicit force changed only resolver/mapper outputs\n'
  exit 0
fi

if [[ "$profile" == "contracts" && "$contract_case" == "fresh" ]]; then
  generated_files=(
    "config/config.exs"
    "lib/package_consumer/relyra/connections.ex"
    "lib/package_consumer/relyra/user_mapper.ex"
    "lib/package_consumer_web/router.ex"
  )
  actual_manifest="$output_dir/fresh_files.sha256"
  actual_receipt="$output_dir/fresh_receipt.txt"
  for relative_path in "${generated_files[@]}"; do
    if [[ ! -f "$consumer_dir/$relative_path" ]]; then
      echo "package consumer: fresh installer drift at $relative_path: expected generated file; actual missing. Review the public installer and intentionally refresh test/fixtures/package_consumer/golden only after confirming the contract." >&2
      exit 1
    fi
  done
  expected_paths="$output_dir/fresh-expected-paths.txt"
  actual_paths="$output_dir/fresh-actual-paths.txt"
  printf '%s\n' "${generated_files[@]}" | LC_ALL=C sort >"$expected_paths"
  {
    printf '%s\n' "config/config.exs" "lib/package_consumer_web/router.ex"
    find "$consumer_dir/lib/package_consumer/relyra" -maxdepth 1 -type f -name '*.ex' -print \
      | sed "s#^$consumer_dir/##"
  } | LC_ALL=C sort >"$actual_paths"
  if ! diff -u "$expected_paths" "$actual_paths" >"$output_dir/fresh-paths.diff"; then
    difference="$(grep -E '^[+-]' "$output_dir/fresh-paths.diff" | grep -vE '^(\+\+\+|---)' | head -n 2 | tr '\n' ' ')"
    echo "package consumer: fresh installer file-set drift: expected $(tr '\n' ',' <"$expected_paths"); actual $(tr '\n' ',' <"$actual_paths"); first difference $difference. Review the installer and intentionally refresh the golden only after confirming the contract." >&2
    exit 1
  fi
  (cd "$consumer_dir" && shasum -a 256 "${generated_files[@]}") >"$actual_manifest"
  installer_log="$output_dir/$(printf '%02d' "$command_count")-installer.log"
  grep -E '^(Injected Relyra SAML routes into |Relyra install scaffolded for )' "$installer_log" >"$actual_receipt" || true

  if [[ "$(grep -c 'saml_routes()' "$consumer_dir/lib/package_consumer_web/router.ex")" != "1" ]]; then
    echo "package consumer: fresh installer drift at lib/package_consumer_web/router.ex: expected one saml_routes() marker; actual route marker count differs. Review RouterInjector and refresh the golden only after confirming the contract." >&2
    exit 1
  fi
  if ! diff -u "$repo_root/test/fixtures/package_consumer/golden/fresh_files.sha256" "$actual_manifest" >"$output_dir/fresh-files.diff"; then
    difference="$(grep -E '^[+-][0-9a-f]' "$output_dir/fresh-files.diff" | head -n 2 | tr '\n' ' ')"
    echo "package consumer: fresh installer drift at generated tree: expected and actual hash rows differ: ${difference:-manifest differs}; inspect $actual_manifest and intentionally refresh the golden only after reviewing the public installer." >&2
    exit 1
  fi
  if ! diff -u "$repo_root/test/fixtures/package_consumer/golden/fresh_receipt.txt" "$actual_receipt" >"$output_dir/fresh-receipt.diff"; then
    difference="$(grep -E '^[+-]' "$output_dir/fresh-receipt.diff" | grep -vE '^(\+\+\+|---)' | head -n 2 | tr '\n' ' ')"
    echo "package consumer: fresh installer drift in receipt: expected and actual lines differ: ${difference:-receipt differs}; actual captured in $actual_receipt. Review the command output and refresh the golden only after confirming the contract." >&2
    exit 1
  fi
  printf 'package consumer [contracts]: PASS — fresh installer generated the exact file hashes and receipt; one router insertion\n'
  exit 0
fi

run_command compile "compile the clean-room consumer with warnings as errors" \
  "$consumer_dir" mix compile --warnings-as-errors

while IFS= read -r smoke_script; do
  relative_script="${smoke_script#"$consumer_dir"/}"
  smoke_label="smoke-${relative_script//\//-}"
  run_command "$smoke_label" "run consumer smoke $relative_script" \
    "$consumer_dir" mix run "$relative_script"
done < <(find "$consumer_dir/smoke" -maxdepth 1 -type f -name '*.exs' -print | LC_ALL=C sort)

printf 'package consumer [%s]: PASS — artifact, installer, compile, owned PostgreSQL and every consumer smoke\n' "$profile"
