#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile="full"

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
    *)
      echo "package consumer: unsupported argument '$1'" >&2
      exit 2
      ;;
  esac
done

if [[ "$profile" != "full" ]]; then
  echo "package consumer: profile '$profile' is not implemented yet; use --profile full" >&2
  exit 2
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
run_command installer "run the public Phoenix consumer installer" "$consumer_dir" \
  mix relyra.install --module PackageConsumer --router lib/package_consumer_web/router.ex --repo PackageConsumer.Repo
run_command compile "compile the clean-room consumer with warnings as errors" \
  "$consumer_dir" mix compile --warnings-as-errors

while IFS= read -r smoke_script; do
  relative_script="${smoke_script#"$consumer_dir"/}"
  smoke_label="smoke-${relative_script//\//-}"
  run_command "$smoke_label" "run consumer smoke $relative_script" \
    "$consumer_dir" mix run "$relative_script"
done < <(find "$consumer_dir/smoke" -maxdepth 1 -type f -name '*.exs' -print | LC_ALL=C sort)

printf 'package consumer [%s]: PASS — artifact, installer, compile, owned PostgreSQL and every consumer smoke\n' "$profile"
