# Phase 71: Launcher DX & banner - Research

**Researched:** 2026-08-27
**Domain:** Docker Compose launcher ergonomics and shell-compatible diagnostics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add a repo-root `Makefile` as the canonical Docker launcher with the required targets:
  `proxy`, `up`, `up-build`, `up-d`, `up-d-build`, `down`, `reset`, `reseed`, `nuke`, `logs`,
  `url`, `open`, `fleet`, `doctor`, and `help`.
- **D-02:** Preserve all six existing `scripts/demo` verbs — `doctor`, `up`, `reset`, `test`,
  `urls`, and `down` — as thin delegations to corresponding Make targets. Do not silently rename,
  remove, or retain separate implementations for those commands.
- **D-03:** Keep `scripts/demo test` as the compatibility entry point for the existing browser
  proof path even though `test` is not required as a public Make target by DX-01; the planner may
  expose a Make helper target as needed to keep delegation literal and behavior centralized.
- **D-04:** Preserve the two intentional Compose invocation shapes. Solo targets use bare
  `docker compose`, allowing `docker-compose.override.yml` to publish the loopback app port.
  Fleet targets use explicit `-f docker-compose.yml -f docker-compose.proxy.yml`, excluding the
  solo override and its host-port binding. Keycloak remains opt-in through its existing profile.
- **D-05:** `reset` and `reseed` are compatibility aliases for the existing destructive demo-data
  refresh (`ecto.drop, ecto.setup`). Do not introduce a second, seed-only retention contract in
  this phase. `nuke` remains the visibly stronger operation for Compose teardown plus volume/cache
  removal; its exact confirmation/guard wording is planner discretion.
- **D-06:** Generate the displayed route map from the current public mount points without adding
  or changing application routes. Cover app home (`/`), operator UI (`/relyra/admin`), login test
  (`/login/test`), support/trace entry (`/support/scenario`, which redirects to the current
  connection trace), health (`/healthz`), Keycloak admin (`/admin` on the Keycloak public origin),
  and the Traefik dashboard (`/dashboard/` on loopback port 8080).
- **D-07:** Print both the fleet/browser origin (`http://${RELYRA_HOST:-relyra.localhost}`) and the
  detected solo loopback fallback (`http://localhost:${PORT:-4000}`), rather than hiding one based
  on topology detection. Clearly label Keycloak and Traefik entries as optional/fleet-only and
  explain that `*.localhost` is for browser-facing host resolution; internal Docker probes keep
  using service DNS.
- **D-08:** `make up-d` and `scripts/demo urls` print the same copy-pasteable banner and concise
  click-through walkthrough. Centralize banner generation so URLs and wording cannot drift across
  launch paths.
- **D-09:** `make fleet` discovers running Traefik-routed demos across repositories by querying
  Docker containers carrying `traefik.enable=true`; it is not limited to the Relyra Compose project.
- **D-10:** `doctor` reports occupancy/status for ports 4000, 5432, and 8080 and checks the
  configured external proxy network (`${DEMO_PROXY_NETWORK:-proxy}`). Diagnostics include a
  concrete corrective command and remain useful when `lsof` is unavailable by retaining the
  current portable fallback behavior.
- **D-11:** Create `.env.example` as commented, optional configuration for `PORT`, `RELYRA_HOST`,
  `DEMO_PROXY_NETWORK`, and optional demo/Keycloak credentials. Compose defaults remain sufficient
  for zero-configuration startup; do not require copying `.env.example` or present demo credentials
  as production-safe secrets.

### the agent's Discretion

- Exact Make function/macros, target grouping, help formatting, ANSI/color behavior, URL opener
  fallback, and `nuke` confirmation mechanics are open provided D-01..D-11 hold.
- The precise internal Make helper used by `scripts/demo test` is open; preserve its existing
  Keycloak/browser-profile behavior and keep the legacy verb callable.
- Tests may replace or extend the existing script/README drift gate so the new Makefile is the
  canonical command inventory, but Phase 72 owns adopter-facing README prose changes.

### Deferred Ideas (OUT OF SCOPE)

- Distinct seed-only `reseed` semantics — deferred; Phase 71 keeps it compatible with the existing
  destructive reset contract.
- Phase 72 owns `guides/docker_dev_dx.md`, demo README, `guides/demo.md`, and top-level README
  routing updates.
- TLS via mkcert, hashed per-checkout hostnames, and a production multi-stage release Dockerfile
  remain milestone-level future work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | Makefile is the primary launcher; legacy `scripts/demo` verbs delegate. | A single `.PHONY` Makefile command surface can centralize the two existing Compose arrays while a thin Bash `case` maps six compatibility verbs. |
| DX-02 | Launch prints route map/walkthrough; fleet scans Traefik labels; doctor diagnoses ports and proxy network. | Existing router, Compose labels, and portable `lsof`/`nc` logic supply every required source of truth without modifying application code. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve the milestone boundary: demo, Docker, and launcher files only; do not touch `lib/`, public API, behaviours, protocol surface, or Hex package whitelist. [VERIFIED: AGENTS.md and ROADMAP.md]
- Keep all SAML security invariants intact, including the configured-certificate trust source, one Saxy parse path, pre-parse guards, cryptographic verification, audited trust mutations, and production replay protection. [VERIFIED: AGENTS.md]
- Before a main-branch push, `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` must pass; do not weaken the adversarial crypto corpus or replace dedicated security `cmd mix test` steps. [VERIFIED: AGENTS.md]
- Use Conventional Commits and end commits with the required Co-Authored-By trailer; do not hand-edit `CHANGELOG.md` or run `mix hex.publish`. [VERIFIED: AGENTS.md]

## Summary

[VERIFIED: codebase grep] The phase is a launcher-only orchestration layer over a completed topology: bare `docker compose` intentionally auto-loads `docker-compose.override.yml` for solo loopback ingress, while `docker compose -f docker-compose.yml -f docker-compose.proxy.yml` intentionally omits it for fleet routing. The Makefile must encode those as separate, named recipes; using one generalized command shape would reintroduce host-port leakage into fleet mode.

[VERIFIED: codebase grep] The URL banner does not need application changes: `LedgerLoopWeb.Router` already mounts `/`, `/relyra/admin`, `/login/test`, `/support/scenario`, and `/healthz`; the support endpoint redirects to the connection trace. The banner must be generated in exactly one Make recipe and invoked after detached startup and from the legacy `urls` adapter so its route map and walkthrough cannot drift.

**Primary recommendation:** Implement a small, all-phony root Makefile with explicitly named solo/fleet Compose variables, one `url` banner recipe, label-filtered `fleet`, corrective `doctor`, and a Bash-only `scripts/demo` compatibility adapter; add focused static contract tests rather than Docker-dependent unit tests.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Command selection and lifecycle | Developer CLI / Makefile | Docker Compose | Make owns ergonomic target names; Compose remains the only runtime topology authority. [VERIFIED: codebase grep] |
| Legacy CLI compatibility | Developer CLI / `scripts/demo` | Makefile | The script maps old verbs into one canonical implementation. [VERIFIED: 71-CONTEXT.md] |
| URL route map and walkthrough | Developer CLI / Makefile | Demo router | Make renders known public mounts but does not own or alter routes. [VERIFIED: codebase grep] |
| Fleet enumeration | Docker CLI | Developer CLI / Makefile | Docker label filtering finds cross-repository Traefik containers; Make presents the result. [CITED: https://docs.docker.com/engine/manage-resources/labels/] |
| Port and network diagnostics | Developer CLI / Makefile | Docker CLI / host tools | Make probes host listeners and the configured external Docker network, then renders recovery commands. [VERIFIED: scripts/demo] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GNU Make | 3.81 installed | Canonical command launcher and target help. | `.PHONY` command targets always run and avoid same-named-file conflicts. [CITED: https://www.gnu.org/s/make/manual/html_node/Phony-Targets.html] |
| Docker Compose | v5.1.3 installed | Existing solo/fleet lifecycle executor. | Explicit `-f` files merge in supplied order; `config` renders the resulting graph for checks. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] |
| Docker CLI | Docker 29.5.2 installed | Fleet label filtering and external-network status. | Container label filters and formatted output are built-in Docker CLI capabilities. [CITED: https://docs.docker.com/engine/manage-resources/labels/] |
| Bash | 5.2.37 installed | Existing compatibility-script runtime and portable diagnostic fallback. | `scripts/demo` is already Bash and its `lsof`/`nc` fallback is the compatibility contract. [VERIFIED: scripts/demo] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `lsof` | Identify listener/owner for a busy host port. | Prefer when present. [VERIFIED: scripts/demo] |
| `nc` | Probe a localhost port when `lsof` is unavailable. | Retain as the fallback. [VERIFIED: scripts/demo] |
| macOS `open` | Open the browser route. | Use only when available; print the URL otherwise. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Makefile target surface | Expand `scripts/demo` into the primary launcher | Contradicts the locked Makefile-primary contract and keeps target discovery outside standard `make help`. [VERIFIED: 71-CONTEXT.md] |
| Docker label discovery | Restrict `fleet` to `relyra-demo` Compose project | Misses cross-repository fleet members, contradicting D-09. [VERIFIED: 71-CONTEXT.md] |
| Static launcher contract tests | Docker lifecycle tests for every target | Existing E2E harness already proves topology; static tests are deterministic and validate command rendering without requiring Docker state. [VERIFIED: scripts/test_fleet_proxy_e2e.sh] |

**Installation:** None. This phase installs no external packages. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
developer
  │ make <target> / scripts/demo <legacy-verb>
  ▼
repo-root Makefile ── legacy adapter delegates ──► scripts/demo
  │
  ├── solo commands ─────► docker compose ─────► base + automatic override ─────► 127.0.0.1:PORT
  ├── fleet commands ────► docker compose -f base -f proxy ─────────────────────► proxy network / Traefik
  ├── url ───────────────► public router mount constants + env defaults ────────► banner + walkthrough
  ├── fleet ─────────────► docker ps --filter label=traefik.enable=true ────────► all routed demos
  └── doctor ────────────► lsof or nc + docker network inspect ────────────────► diagnosis + next command
```

### Recommended Project Structure

```text
Makefile                         # canonical launcher, target help, Compose shapes, banner, diagnostics
scripts/demo                     # six legacy verbs only; delegates to make
.env.example                     # optional overrides and non-production demo credentials
test/docs/demo_guide_drift_test.exs  # migrate/extend command-surface contract test
```

### Pattern 1: Explicit topology aliases

**What:** Declare distinct Make variables or recipe helpers for `docker compose` (solo) and `docker compose -f docker-compose.yml -f docker-compose.proxy.yml` (fleet). [VERIFIED: docker-compose.override.yml and docker-compose.proxy.yml]

**When to use:** Every target that starts, stops, logs, executes, or renders a stack must choose its intended topology up front.

**Example:**

```make
SOLO_COMPOSE := docker compose
FLEET_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.proxy.yml

up-d:
	$(SOLO_COMPOSE) up --no-build -d
	$(MAKE) --no-print-directory url

proxy-up-d:
	$(FLEET_COMPOSE) up --no-build -d
	$(MAKE) --no-print-directory url
```

[CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] Explicit Compose files merge in order; bare Compose intentionally auto-loads the local override under this repository’s current filenames. [VERIFIED: docker-compose.override.yml]

### Pattern 2: One banner source of truth

**What:** Make `url` the sole renderer for the browser origins, mount-path map, fleet-only annotations, fallback status, and FakeIdP-first walkthrough; `up-d` invokes it recursively and `scripts/demo urls` invokes the Make target. [VERIFIED: 71-CONTEXT.md]

**When to use:** Any entry point that prints URLs.

**Example:**

```make
url:
	@echo "App:       http://$(RELYRA_HOST)/"
	@echo "Operator:  http://$(RELYRA_HOST)/relyra/admin"
	@echo "Login:     http://$(RELYRA_HOST)/login/test"
	@echo "Support:   http://$(RELYRA_HOST)/support/scenario"
	@echo "Health:    http://$(RELYRA_HOST)/healthz"
	@echo "Keycloak (fleet optional): http://keycloak.$(RELYRA_HOST)/admin"
	@echo "Traefik (fleet optional):  http://localhost:8080/dashboard/"
```

[VERIFIED: demo router and route affordance controller] The displayed application paths are presentation-only constants derived from existing route mounts; no route parsing or router changes belong in this phase.

### Pattern 3: Diagnose, then prescribe

**What:** Each doctor check reports a state and the exact next command, including missing proxy network (`make proxy`), occupied port (`stop/reconfigure the listener`), unavailable probe tool, or Docker not installed. [VERIFIED: 71-CONTEXT.md]

**When to use:** All failing preflight checks, including non-fatal 5432 occupancy because the Compose topology deliberately does not publish Postgres. [VERIFIED: docker-compose.yml]

### Anti-Patterns to Avoid

- **Generic Compose helper used everywhere:** It can accidentally include the solo override in fleet commands and reintroduce a host-port binding. Use distinct named shapes. [VERIFIED: docker-compose.override.yml]
- **Copy-pasted URL `echo` blocks:** `up-d` and legacy `urls` will drift. Route both through `make url`. [VERIFIED: D-08]
- **Fleet scan by Compose project:** It excludes sibling repositories. Filter `traefik.enable=true` instead. [VERIFIED: D-09]
- **Treating `*.localhost` as a container endpoint:** Browser hostname resolution and Docker service DNS are separate; internal Keycloak bootstrap remains `keycloak:8080`. [VERIFIED: docker/traefik/compose.yml and docker-compose.proxy.yml]
- **Parsing or changing router code to build the banner:** This violates the explicit phase boundary; use the known current public mount list as display data. [VERIFIED: 71-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Compose topology merging | Shell-built YAML or ad hoc flags | Existing Compose files plus the two explicit command shapes | Compose owns merge/order semantics and `config` validation. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] |
| Fleet registry | Per-repository state file | Docker label filtering | Traefik-exposed containers already carry the required discovery marker. [CITED: https://docs.docker.com/engine/manage-resources/labels/] |
| Port availability | New dependency | Existing `lsof`, then `nc` fallback | Matches existing launcher portability behavior. [VERIFIED: scripts/demo] |
| Route implementation | New router/controller code | Existing route mounts as display constants | Phase scope permits banner reads only, not application changes. [VERIFIED: 71-CONTEXT.md] |

**Key insight:** The launcher is an adapter over already-verified topology and routes; it should centralize command spelling and explanatory output, never become a second topology or application-routing implementation. [VERIFIED: phase boundary]

## Common Pitfalls

### Pitfall 1: Fleet command silently includes the solo override

**What goes wrong:** A fleet launch binds `127.0.0.1:4000`, defeating the shared-proxy coexistence goal. [VERIFIED: docker-compose.override.yml]

**Why it happens:** Bare Compose auto-loads the override whereas an explicit `-f` list selects only the listed files. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/]

**How to avoid:** Keep `SOLO_COMPOSE` and `FLEET_COMPOSE` visibly separate; test the literal fleet `-f docker-compose.yml -f docker-compose.proxy.yml` shape and use `docker compose ... config` in existing integration proof where appropriate. [VERIFIED: scripts/test_fleet_proxy_e2e.sh]

### Pitfall 2: Banner falsely implies all URLs are active

**What goes wrong:** A contributor opens Keycloak or Traefik before proxy/profile startup and sees a failure without understanding it is optional. [VERIFIED: D-07]

**How to avoid:** Always show both origins, label Keycloak/Traefik as fleet-only/optional, and emit the detected loopback fallback state rather than inferring topology from the host name. [VERIFIED: D-07]

### Pitfall 3: Legacy script behavior diverges from Make

**What goes wrong:** One path invokes old compose commands or prints old URLs. [VERIFIED: scripts/demo]

**How to avoid:** Make every retained verb a literal `exec make <target>` delegation after argument validation; preserve the `test` profile command through a Make helper. Add static assertions for all six verb-to-target mappings. [VERIFIED: D-02 and D-03]

### Pitfall 4: Doctor produces observation without recovery

**What goes wrong:** A port warning or missing network leaves the operator guessing at the next action. [VERIFIED: D-10]

**How to avoid:** Each failing branch must print one actionable command, retain `nc` fallback if `lsof` is missing, and distinguish `5432` as a host diagnostic from a required Compose port. [VERIFIED: scripts/demo and docker-compose.yml]

### Pitfall 5: Documentation drift test blocks Phase 71 unexpectedly

**What goes wrong:** The current test reads `scripts/demo` as canonical and requires every script verb in existing README bash fences. [VERIFIED: test/docs/demo_guide_drift_test.exs]

**How to avoid:** Change the test’s canonical inventory deliberately while retaining compatibility assertions. Do not expand Phase 72-owned README prose merely to make a new Make target pass the old script/README parity rule. [VERIFIED: 71-CONTEXT.md]

## Code Examples

### Label-based fleet discovery

```make
fleet:
	@ids=$$(docker ps --filter label=traefik.enable=true -q); \
	if [ -z "$$ids" ]; then \
		echo "No Traefik-routed demo containers running."; \
	else \
		docker ps --filter label=traefik.enable=true \
			--format 'table {{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'; \
	fi
```

[CITED: https://docs.docker.com/engine/manage-resources/labels/] Docker supports filtering container lists by label; the shape matches the current sibling-project Makefile. [VERIFIED: /Users/jon/projects/scoria/Makefile]

### Portable port check with actionable result

```bash
check_port() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 &&
      echo "Port $port is occupied; stop the listener or choose another host port."
  elif command -v nc >/dev/null 2>&1; then
    nc -z localhost "$port" >/dev/null 2>&1 &&
      echo "Port $port responds; inspect it with Docker Desktop or install lsof."
  else
    echo "Cannot inspect port $port: install lsof or nc."
  fi
}
```

[VERIFIED: scripts/demo] Preserve the existing `lsof`-then-`nc` capability ordering; exact wording is planner discretion.

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `scripts/demo` contains lifecycle and URL logic. | Root Makefile is primary; `scripts/demo` becomes a compatibility adapter. [VERIFIED: D-01 and D-02] | One discoverable command surface and less behavior drift. |
| A single direct `localhost` URL list. | Banner shows fleet browser origin and detected solo fallback, with public/internal boundary notes. [VERIFIED: D-06 through D-08] | Evaluators can use the proxy fleet without losing solo diagnostics. |
| Doctor checks Docker, Mix, and only two ports. | Doctor additionally checks 5432 and the configurable external proxy network with concrete remediation. [VERIFIED: scripts/demo and D-10] | It explains common cross-project failures before startup. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | macOS `open` is the appropriate default-browser command on this maintainer workstation. | Standard Stack | `make open` needs a fallback/no-op message on non-macOS. |

## Open Questions

1. **Which topology should the required `up`/`up-d` names select?**
   - What we know: D-04 defines solo and fleet command shapes, while the target list does not separately name a fleet-up command. [VERIFIED: 71-CONTEXT.md]
   - What is unclear: Whether `up*` should be fleet-default (with an internal solo helper) or solo-default (with a clearly named fleet helper). 
   - Recommendation: Preserve solo as the `up*` default because bare Compose is the project’s zero-setup path; introduce a clearly named internal/public fleet helper only if necessary, and ensure `make proxy` remains the fleet prerequisite. [VERIFIED: REQUIREMENTS.md]

2. **How should `nuke` confirm destruction?**
   - What we know: It must be visibly stronger than reset and remove Compose volumes/caches. [VERIFIED: D-05]
   - What is unclear: Whether a noninteractive CI bypass is needed.
   - Recommendation: Print exact affected volumes and require an explicit environment opt-in only if the plan retains interactivity; otherwise make the destructive wording conspicuous and test command shape, matching sibling convention. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Docker Engine | lifecycle, fleet, network doctor | ✓ | 29.5.2 | none |
| Docker Compose | solo/fleet command recipes | ✓ | v5.1.3 | none |
| GNU Make | primary launcher | ✓ | 3.81 | none |
| Bash | legacy adapter | ✓ | 5.2.37 | none |
| `lsof` | detailed port owner diagnostics | ✗ | — | `nc` if installed; otherwise explain unavailable probe |
| `nc` | port fallback diagnostics | ✗ | — | explicit unavailable-probe message |
| proxy Docker network | fleet proxy | ✓ | existing `proxy` | `make proxy` creates/starts it |

**Missing dependencies with no fallback:** None for planning; the Makefile must keep clear Docker/Compose absence diagnostics. [VERIFIED: local availability audit]

**Missing dependencies with fallback:** `lsof` and `nc` are both absent on this workstation, so doctor must exercise the existing no-probe branch rather than assume either tool exists. [VERIFIED: local availability audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (project Mix test suite) [VERIFIED: mix.exs] |
| Config file | `mix.exs` aliases [VERIFIED: mix.exs] |
| Quick run command | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` [VERIFIED: mix.exs] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: AGENTS.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Required Make target inventory, canonical explicit Compose shapes, reset/reseed/nuke semantics, six thin legacy delegations. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` after extending/replacing the test | ✅ extend existing |
| DX-02 | Single route banner includes all paths/origins/walkthrough; fleet uses Traefik label; doctor includes 4000/5432/8080/network and corrective commands. | static contract | same focused Mix test | ✅ extend existing |
| DX-02 | Solo/fleet merged Compose graphs and browser reachability remain correct. | integration / browser | `npm run demo:fleet-proxy` | ✅ existing `scripts/test_fleet_proxy_e2e.sh` |
| DX-02 | Keycloak proxy topology remains usable. | integration / browser | `npm run demo:keycloak-proxy` | ✅ existing `scripts/test_keycloak_proxy_e2e.sh` |

### Sampling Rate

- **Per task commit:** focused launcher/static contract test plus `make help` and non-mutating `make -n` render checks. [ASSUMED]
- **Per wave merge:** `mix test --warnings-as-errors` and `mix format --check-formatted`. [VERIFIED: AGENTS.md]
- **Phase gate:** `mix qa` and `mix ci.security` green before verification; invoke Docker integration lanes when Docker is available. [VERIFIED: AGENTS.md]

### Wave 0 Gaps

- [ ] Extend or replace `test/docs/demo_guide_drift_test.exs` so Make target inventory is canonical while six compatibility verbs are checked independently.
- [ ] Add static assertions for banner routes/origins, exact Compose shapes, fleet label filter, and doctor remediation tokens; avoid asserting live Docker results.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Launcher must not alter SAML/login implementation. [VERIFIED: phase boundary] |
| V3 Session Management | no | Launcher must not alter host session behavior. [VERIFIED: phase boundary] |
| V4 Access Control | no | Banner may link to admin routes but cannot weaken their existing guards. [VERIFIED: router] |
| V5 Input Validation | yes | Treat environment overrides as Docker Compose inputs only; preserve existing inline defaults and shell quoting. [VERIFIED: Compose files] |
| V6 Cryptography | no | No crypto code or configuration changes are in scope. [VERIFIED: AGENTS.md and phase boundary] |

### Known Threat Patterns for launcher scripts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell expansion from user environment | Tampering | Quote shell variables; do not `eval` env-provided values or construct executable fragments from them. [ASSUMED] |
| Accidental destructive operation | Denial of service | Separate reset/reseed from nuke, print scope, and use an intentional confirmation policy. [VERIFIED: D-05] |
| Misleading browser/internal endpoint | Information disclosure / misuse | Label browser-only `*.localhost` URLs and retain service-DNS wording for container probes. [VERIFIED: D-07] |

## Sources

### Primary (HIGH confidence)

- [Repository Compose files, router, script, E2E harness, and drift test] - current topology, route mounts, legacy behavior, and test seams. [VERIFIED: codebase grep]
- [Docker Compose merge documentation](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/) - explicit `-f` ordering, default override behavior, and config rendering. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/]
- [Docker labels documentation](https://docs.docker.com/engine/manage-resources/labels/) - label filtering for Docker containers. [CITED: https://docs.docker.com/engine/manage-resources/labels/]
- [GNU Make phony targets manual](https://www.gnu.org/s/make/manual/html_node/Phony-Targets.html) - command target behavior. [CITED: https://www.gnu.org/s/make/manual/html_node/Phony-Targets.html]

### Secondary (MEDIUM confidence)

- [Docker container ls reference](https://docs.docker.com/reference/cli/docker/container/ls) - formatted, filtered container output. [CITED: https://docs.docker.com/reference/cli/docker/container/ls]
- [GNU Make recursion options](https://www.gnu.org/software/make/manual/html_node/Options_002fRecursion.html) - `--no-print-directory` behavior. [CITED: https://www.gnu.org/software/make/manual/html_node/Options_002fRecursion.html]

### Tertiary (LOW confidence)

- macOS `open` portability behavior is assumed and must have a graceful fallback. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools are already installed and current repository command seams prove their use. [VERIFIED: local availability audit]
- Architecture: HIGH - Compose files, router, context locks, and E2E scripts define the required integration points. [VERIFIED: codebase grep]
- Pitfalls: HIGH - each follows an explicit locked decision or existing drift/topology test. [VERIFIED: codebase grep]

**Research date:** 2026-08-27
**Valid until:** 2026-09-26 (stable local tooling and repository-specific architecture)
