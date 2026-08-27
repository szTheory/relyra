# Phase 71: Launcher DX & banner - Pattern Map

**Mapped:** 2026-08-27  
**Files analyzed:** 4  
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Makefile` | config / developer CLI | request-response, event-driven | `/Users/jon/projects/scoria/Makefile` | exact |
| `scripts/demo` | utility / compatibility CLI | request-response | current `scripts/demo` | exact |
| `.env.example` | config | transform | `/Users/jon/projects/scoria/.env.example` | role-match |
| `test/docs/demo_guide_drift_test.exs` | test | transform | current `test/docs/demo_guide_drift_test.exs` | exact |

## Pattern Assignments

### `Makefile` (config / developer CLI, request-response + event-driven)

**Analog:** `/Users/jon/projects/scoria/Makefile`

**Target metadata and discoverable help** (lines 1-3, 23-27):

```make
.DEFAULT_GOAL := help
.PHONY: proxy build up up-build up-d up-d-build down logs url open ... help fleet clean nuke

## help: print this help (the default target)
help:
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  \\033[36m%-14s\\033[0m %s\\n", substr(line, 1, i-1), substr(line, i+2) }' $(MAKEFILE_LIST)
```

Use `## target: description` comments immediately above every Phase 71 public target so one help renderer is the canonical inventory.

**Lifecycle and centralized banner invocation** (lines 50-66):

```make
up:
	docker compose up --no-build

up-d:
	docker compose up --no-build -d
	@$(MAKE) --no-print-directory url

up-d-build:
	docker compose up --build -d
	@$(MAKE) --no-print-directory url
```

Adapt this to named, visibly distinct Relyra command shapes: `SOLO_COMPOSE := docker compose` and `FLEET_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.proxy.yml`. The former intentionally loads the solo override; the latter must never do so.

**Cross-repository fleet discovery** (lines 29-38):

```make
fleet:
	@ids=$$(docker ps --filter label=traefik.enable=true -q); \\
	if [ -z "$$ids" ]; then \\
		echo "No Traefik-routed demo containers running."; \\
	else \\
		docker ps --filter label=traefik.enable=true \\
			--format 'table {{.Label "com.docker.compose.project"}}\\t{{.Names}}\\t{{.Status}}\\t{{.Ports}}'; \\
	fi
```

Keep the `traefik.enable=true` filter; do not filter by the Relyra Compose project name.

**Destructive-operation visibility and one URL renderer** (lines 89-107):

```make
nuke:
	@echo "NUKE: irreversibly deleting ALL named volumes for instance '$(COMPOSE_PROJECT_NAME)':"
	docker compose down -v

url:
	@echo "Instance:  $(COMPOSE_PROJECT_NAME)"
	@echo "Traefik:   http://$(SCORIA_HOST)/scoria"
	@fallback=$$(docker compose port web 4000 2>/dev/null || true); \\
	if [ -n "$$fallback" ]; then \\
		echo "Fallback:  http://$$fallback/scoria"; \\
	else \\
		echo "Fallback:  (not running; run 'make up-d' or 'make up-d-build')"; \\
	fi
```

Relyra's `url` target is the sole banner source. It must print both `http://${RELYRA_HOST:-relyra.localhost}` and detected `http://localhost:${PORT:-4000}`, all locked route paths, browser-vs-service-DNS guidance, and optional Keycloak/Traefik entries. `up-d` invokes this target rather than owning copied `echo` statements.

**Actionable proxy-network diagnostic** (lines 125-153):

```make
doctor:
	@$(MAKE) --no-print-directory url
	@docker network inspect proxy --format 'proxy network exists ({{.Name}})' 2>/dev/null || echo "proxy network missing; run: make proxy"
	@$(MAKE) --no-print-directory fleet
```

Parameterize the network as `$(DEMO_PROXY_NETWORK)` with the Compose default of `proxy`; add the existing portable port-check ordering for 4000, 5432, and 8080.

**Relyra topology source, not a modification target:** `docker-compose.override.yml` lines 1-6 documents that bare Compose loads the loopback port mapping, while `docker-compose.proxy.yml` lines 1-19 supplies the `RELYRA_HOST` and Traefik network/labels for the explicit fleet shape. `scripts/test_fleet_proxy_e2e.sh` lines 7-13 defines the same two arrays and lines 97-111 proves the resulting solo/fleet graph distinction.

---

### `scripts/demo` (utility / compatibility CLI, request-response)

**Analog:** current `scripts/demo`

**Strict Bash command dispatch** (lines 1-5, 23-61):

```bash
#!/usr/bin/env bash

set -euo pipefail

COMMAND="${1:-}"

case "$COMMAND" in
  doctor)
    # command body
    ;;
  up)
    # command body
    ;;
  *)
    echo "Usage: scripts/demo {doctor|up|reset|test|urls|down}"
    exit 1
    ;;
esac
```

Keep exactly the six existing arms (`doctor`, `up`, `reset`, `test`, `urls`, `down`) and a clear invalid-command exit. Replace each arm body with a literal `exec make <corresponding-target>` delegation; `urls` must execute `make url`, and retain a Make helper for the present browser/Keycloak test profile.

**Portable port-probe ordering** (lines 7-21):

```bash
if command -v lsof >/dev/null 2>&1; then
  if lsof -i :"$port" > /dev/null; then
    echo "Warning: Port $port is already in use."
  fi
elif command -v nc >/dev/null 2>&1; then
  if nc -z localhost "$port" >/dev/null 2>&1; then
    echo "Warning: Port $port is already in use."
  fi
else
  echo "Warning: Neither lsof nor nc found to check port $port."
fi
```

Move this behavior into the canonical Make doctor recipe (or a single helper it invokes), preserving `lsof` first, `nc` second, and a usable no-tool diagnostic. Each negative result needs a concrete corrective command.

---

### `.env.example` (config, transform)

**Analog:** `/Users/jon/projects/scoria/.env.example`

**Optional, commented override contract** (lines 1-9):

```dotenv
# Copy to .env (gitignored). All keys are optional.
#
# The Makefile derives these ... automatically,
# so `make up` needs nothing here. Set them only if you run `docker compose up`
# directly ... Compose reads .env for ${VAR} substitution in compose.yml.
#   COMPOSE_PROJECT_NAME=scoria-myfeature-a1b2c3d4
#   SCORIA_HOST=scoria-myfeature-a1b2c3d4.localhost
```

Create a short commented template, not an active required configuration file. Document optional `PORT`, `RELYRA_HOST`, `DEMO_PROXY_NETWORK`, `DEMO_ADMIN_USERNAME`, `DEMO_ADMIN_PASSWORD`, and `KEYCLOAK_SARAH_PASSWORD`; show defaults as comments and state that demo credentials are not production-safe secrets.

**Relyra environment sources:** `docker-compose.override.yml` line 6 defines `PORT`'s zero-config default. `docker-compose.proxy.yml` lines 4-12 and 21-31 define `RELYRA_HOST`, `DEMO_PROXY_NETWORK`, and optional admin/Keycloak credentials. Copy names and defaults exactly; do not add a second configuration vocabulary.

---

### `test/docs/demo_guide_drift_test.exs` (test, transform)

**Analog:** current `test/docs/demo_guide_drift_test.exs`

**Async ExUnit file-contract test** (lines 73-97):

```elixir
use ExUnit.Case, async: true

@script_path "scripts/demo"
@readme_path "demo/ledger_loop/README.md"

test "scripts/demo subcommands and the demo README bash fences are in bidirectional sync" do
  script_subcommands = extract_script_subcommands()
  doc_subcommands = extract_doc_subcommands()

  missing_in_doc = MapSet.difference(script_subcommands, doc_subcommands)
  stale_in_doc = MapSet.difference(doc_subcommands, script_subcommands)

  assert MapSet.size(missing_in_doc) == 0, format_missing(missing_in_doc)
  assert MapSet.size(stale_in_doc) == 0, format_stale(stale_in_doc)
end
```

Retain the file-reading/`MapSet`/actionable-error style, but deliberately migrate the canonical command inventory from README parity to the Makefile. Do not modify Phase 72-owned README prose merely to satisfy this test.

**Runtime parsing with explicit boundaries** (lines 78-112):

```elixir
@case_arm_pattern ~r/^\s+(\w+)\)\s*$/m

defp extract_script_subcommands do
  source = File.read!(@script_path)

  @case_arm_pattern
  |> Regex.scan(source, capture: :all_but_first)
  |> Enum.map(fn [name] -> name end)
  |> MapSet.new()
end
```

Use the same runtime-source parsing approach for `.PHONY` and/or documented Make target lines, plus literal delegation assertions for the six script arms. Add static assertions for exact solo/fleet Compose spellings, banner tokens, label discovery, doctor ports/network/remediation, and reset/reseed/nuke semantics; do not require live Docker state.

## Shared Patterns

### Two explicit Compose topologies

**Sources:** `scripts/test_fleet_proxy_e2e.sh` lines 7-13; `docker-compose.override.yml` lines 1-6; `docker-compose.proxy.yml` lines 1-19.

```bash
SOLO_COMPOSE=(docker compose)
FLEET_COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.proxy.yml)
```

**Apply to:** every Make lifecycle, reset, log, test, and nuke operation. Select the topology at the target boundary. Bare solo Compose intentionally auto-loads the override and exposes only `127.0.0.1:${PORT:-4000}:4000`; fleet spelling intentionally excludes it and joins the external proxy network.

### Public route-map source

**Sources:** `demo/ledger_loop/lib/ledger_loop_web/router.ex` lines 44-71; `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` lines 34-37.

```elixir
get "/healthz", LedgerLoopWeb.HealthController, :health
get "/", LedgerLoopWeb.PageController, :home
get "/login/test", LedgerLoopWeb.RouteAffordanceController, :login
get "/support/scenario", LedgerLoopWeb.RouteAffordanceController, :support

relyra_admin_routes("/relyra/admin", ...)

def support(conn, _params) do
  id = LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()
  redirect(conn, to: "/relyra/admin/connections/#{id}/trace")
end
```

**Apply to:** the Make `url` banner and static test tokens only. Display `/`, `/relyra/admin`, `/login/test`, `/support/scenario`, and `/healthz`; do not parse, alter, or otherwise touch the router/controller. The Keycloak `/admin` browser URL comes from the proxy host convention in `docker-compose.proxy.yml` lines 21-34, and Traefik dashboard `/dashboard/` / loopback `8080` comes from `docker/traefik/compose.yml` lines 23-31.

### Shell diagnostics and recovery

**Sources:** `scripts/demo` lines 7-39; `/Users/jon/projects/scoria/Makefile` lines 149-164.

**Apply to:** `doctor`. Preserve command-presence checks and portable fallback order. Pair every absent/busy port or absent external network with a next command (not just observation); `docker network inspect $(DEMO_PROXY_NETWORK)` failure must direct users to `make proxy`.

## No Analog Found

None. All Phase 71 artifacts have a close project or sibling-project analog; the actual browser route list and topology are existing Relyra sources of truth, not implementation targets.

## Metadata

**Analog search scope:** repo-root scripts/config/tests, demo router/controller, Compose topology/E2E proof, and sibling `/Users/jon/projects/scoria/Makefile` / `.env.example`  
**Files scanned:** 11  
**Pattern extraction date:** 2026-08-27
