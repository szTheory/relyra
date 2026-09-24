# Phase 74: Clean-Room Package Consumer - Pattern Map

**Mapped:** 2026-09-24  
**Files analyzed:** 7 proposed file groups  
**Analogs found:** 6 / 7

Phase 74's implementation paths are still proposals in `74-RESEARCH.md`; the planner should settle exact names while preserving the locked artifact boundary and CI requirements. The workflow owner is open in research. The patterns below use tracked source only (each analog was checked with `git ls-files`).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/check_clean_room_consumer.sh` (proposed) | utility / harness | batch, subprocess orchestration, file I/O | `scripts/check_demo_package_exclusion.sh` | role-match; package artifact check is narrower |
| `test/fixtures/package_consumer/generated/` (proposed) | test fixture / golden tree | file I/O, transform comparison | `test/fixtures/demo_host/golden/` and `test/mix/tasks/verify_release_parity_test.exs` | role-match |
| `test/fixtures/package_consumer/prior_scaffold/` (proposed) | test fixture | file I/O, transform comparison | `test/fixtures/demo_host/golden/` and `test/mix/relyra_install_test.exs` | role-match |
| Omission-control fixture/artifact (exact representation TBD) | test fixture / negative input | file I/O, batch | `test/mix/tasks/verify_release_parity_test.exs` local package artifact contract | partial; no existing omission fixture |
| Temporary consumer project (generated at runtime; exact tracked files TBD) | integration test app | request-response, database I/O | `demo/ledger_loop/` and `test/relyra/testing_phoenix_test.exs` | role-match |
| `demo/ledger_loop/priv/repo/migrations/...` analog informs consumer host migration | migration | database I/O / schema transform | `demo/ledger_loop/priv/repo/migrations/20260612170100_create_relyra_runtime_store_tables.exs` | exact for host-owned table DDL |
| One of `.github/workflows/security-gates.yml` or `demo-app-ci.yml` (owner TBD) | CI config | batch | `.github/workflows/security-gates.yml` | role-match; owner decision remains open |

## Pattern Assignments

### `scripts/check_clean_room_consumer.sh` (proposed harness)

**Analog:** `scripts/check_demo_package_exclusion.sh`

**Repo-root resolution and execution context** (`scripts/check_demo_package_exclusion.sh`, lines 1-5):

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
```

Keep the strict shell mode and resolve the repository relative to the script. The current script uses a fixed `/tmp/relyra-package-check` (lines 7, 19-20); Phase 74's locked isolation decision requires a unique task-owned temp root and cleanup that can retain diagnostics on local failure.

**Package artifact operation and actionable checks** (`scripts/check_demo_package_exclusion.sh`, lines 9-27):

```bash
if [ ! -f "demo/ledger_loop/mix.exs" ]; then
  echo "demo package exclusion: missing demo/ledger_loop/mix.exs" >&2
  exit 1
fi

mix hex.build --unpack --output /tmp/relyra-package-check >/tmp/relyra-package-check.log
demo_path="$(find /tmp/relyra-package-check -path '*/demo/*' -print -quit)"
if [ -n "$demo_path" ]; then
  echo "demo package exclusion: found demo path in unpacked package: $demo_path" >&2
  exit 1
fi
```

Reuse `mix hex.build --unpack` and explicit contract diagnostics. Expand the limited exclusion assertion into required-file/provenance checks, named profiles, and controlled omission behavior. Do not use a generic nonzero assertion for the omission case.

**Subprocess contract test analog:** `test/mix/tasks/verify_release_parity_test.exs`, lines 163-179 builds/unpacks the actual local artifact with `System.cmd`, checks exit status with captured output, lists unpacked files, and asserts public testing files are shipped while private support is absent. Use that shape for command output capture and exact package file assertions; avoid resolving from the checkout.

### Fresh generated tree and prior scaffold fixtures

**Analogs:** `test/fixtures/demo_host/golden/`; `test/mix/relyra_install_test.exs`

The golden tree is organized by the generated destination paths: `config/relyra_snippet.exs`, `lib/demo_host/relyra/{connections,user_mapper}.ex`, and `lib/demo_host_web/router_injected.ex`. The router golden is intentionally a minimal generated snippet:

```elixir
defmodule DemoHostWeb.Router do
  use Phoenix.Router
  # --- Relyra SAML routes ---
  import Relyra.Phoenix.Router
  saml_routes()
end
```

`test/mix/relyra_install_test.exs`, lines 4-26, invokes the Mix task in a temporary cwd, reads generated paths, checks exact identifying integration/config content, and registers `on_exit` cleanup. Lines 72-109 also establish idempotent router injection by rerunning the installer and comparing the router bytes to the first pass. For the Phase 74 fixture comparison, compare a sorted relative file list plus contents/receipt, and keep fresh-install and prior-scaffold expectations distinct.

**Installer preservation rule:** `lib/mix/tasks/relyra.install.ex`, lines 23-26 and 59-69:

```elixir
force = Keyword.get(opts, :force, false)

cond do
  force or not File.exists?(path) ->
    File.write!(path, contents)

  true ->
    Mix.shell().info("Skipped existing #{path} (pass --force to overwrite)")
end
```

The prior scaffold contract should exercise normal install and assert preservation/diagnostics, not use `--force` as an upgrade path. `--force` is explicitly destructive overwrite permission.

### Temporary package consumer and Phoenix ACS proof

**Analogs:** `test/relyra/testing_phoenix_test.exs`; `demo/ledger_loop/`

The proposed consumer is runtime-generated/outside the checkout, so there is no exact tracked clean-room consumer app. For its request-response path, use `test/relyra/testing_phoenix_test.exs` as the closest real Phoenix + shipped helper analog; it imports `Phoenix.ConnTest`, routes fixture POST params through `saml_routes/0`, and asserts the request result. Pair that with `demo/ledger_loop/lib/ledger_loop_web/router.ex` for the host's production router integration. The fixture must be from packaged `Relyra.Testing` and must reach the normal Relyra route/verifier. Do not copy checkout-only `Relyra.TestSupport` paths.

**Fixture API source:** `lib/relyra/testing.ex`, lines 27-55, defines `signed_success/1` to build a signed response and returns `{:ok, :verified}` as the expected outcome; lines 120-153 define POST and consume-option helpers. This is framework-neutral package source, not a Phoenix adapter; the Phoenix endpoint/request assertions should follow the test analog above.

### Consumer migration and store schema

**Relyra-owned migrations analog:** `guides/production_ecto_path.md`, lines 50-60:

```elixir
migrations_path = Application.app_dir(:relyra, "priv/repo/migrations")

Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
  Ecto.Migrator.run(repo, migrations_path, :up, all: true)
end)
```

**Host-owned migration runner analog:** `demo/ledger_loop/lib/ledger_loop/relyra/migrations.ex`, lines 10-23, computes a migration source path then calls `Ecto.Migrator.with_repo/3` and `Ecto.Migrator.run/4`. Prefer the documented `Application.app_dir(:relyra, ...)` source for the clean-room consumer so the provenance is tied to the resolved dependency, as locked in D-06.

**Host store DDL analog:** `demo/ledger_loop/priv/repo/migrations/20260612170100_create_relyra_runtime_store_tables.exs`, lines 4-24, owns request-intent/replay tables in the host's migration directory and expresses uniqueness through explicit `unique_index/2`. Keep this DDL under the consumer, run after package-owned migrations, and prove behavior through configured adapters (not just table existence).

### CI wiring

**Analog:** `.github/workflows/security-gates.yml`, lines 14-54 and 71-97. It provisions PostgreSQL 16, fixes matrix tuples to Elixir 1.19.5 / OTP 27 and 28, and runs named blocking lanes as separate commands. Attach the clean-room contract to exactly one existing blocking workflow (research leaves ownership open) and preserve the tuple matrix. Avoid adding a step to both workflows unless the planner establishes a requirement; that would run the expensive full profile redundantly.

## Shared Patterns

### Isolation and diagnostics

**Sources:** `scripts/check_demo_package_exclusion.sh` lines 1-5; `test/mix/relyra_install_test.exs` lines 4-12; `test/mix/tasks/verify_release_parity_test.exs` lines 163-179.

Use strict shell handling, explicit command status/output checks, unique temp ownership, and cleanup. Diagnostics should name profile, command/contract, expected path or behavior, and next action. Keep captured SAML, key, cookie, credentials, and environment values out of logs.

### Installer behavior

**Source:** `lib/mix/tasks/relyra.install.ex` lines 59-69; `test/mix/relyra_install_test.exs` lines 72-109.

Default runs preserve existing generated files; router injection is idempotent; `--force` is the explicit overwrite switch. Fresh golden and prior-scaffold upgrade checks guard different contracts.

### Package-only verification

**Sources:** `test/mix/tasks/verify_release_parity_test.exs` lines 154-179; `lib/relyra/testing.ex` lines 27-55, 120-153.

Build/unpack the local artifact and run the consumer with its path dependency pointing to that unpacked artifact. Assert dependency provenance. The only signed happy path uses public testing helpers and must run through the actual Phoenix ACS route and verifier; do not stub signature verification or bring root fixture/support code into the consumer.

### Migration ownership

**Sources:** `guides/production_ecto_path.md` lines 41-60; `demo/ledger_loop/priv/repo/migrations/20260612170100_create_relyra_runtime_store_tables.exs` lines 4-24.

Run library migrations from `Application.app_dir(:relyra, "priv/repo/migrations")`; keep request/replay DDL in the host's own migration path. Use an empty per-run database and verify adapter writes/reads/consume and uniqueness semantics.

## No Analog Found

| File/Contract | Role | Data Flow | Reason |
|---------------|------|-----------|--------|
| New clean-room harness's isolated Mix/Hex/deps/build environment | utility / harness | batch, file I/O | Existing package script is an unpack/exclusion check only; no tracked script currently constructs isolated temp Mix state, consumer DB, and consumer lifecycle. |
| Controlled omission artifact contract | test fixture / negative input | file I/O, batch | No existing package-consumer omission test; adapt the exact-contract style from release parity rather than treating an arbitrary failure as success. |
| `test/fixtures/package_consumer/prior_scaffold/` exact expected upgrade result | test fixture | file I/O, transform comparison | Installer tests cover skip/force/idempotence, but there is no frozen prior-version generated scaffold yet. |

## Metadata

**Analog search scope:** `scripts/`, `test/mix/`, `test/fixtures/demo_host/`, `test/relyra/`, `demo/ledger_loop/`, `guides/`, `.github/workflows/`, `lib/mix/tasks/`, `lib/relyra/testing.ex`  
**Tracked-source verification:** All analog paths listed above returned non-empty `git ls-files -- <path>` results.  
**Pattern extraction date:** 2026-09-24
