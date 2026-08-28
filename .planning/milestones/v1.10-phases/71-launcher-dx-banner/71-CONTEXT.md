# Phase 71: Launcher DX & banner - Context

**Gathered:** 2026-08-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make launching `demo/ledger_loop` self-documenting through one repo-root `Makefile`: preserve the
solo and fleet Compose paths already shipped in Phases 68-70, print a copy-pasteable route map and
walkthrough, expose the running Traefik fleet, and diagnose common port/network problems.

**In scope (DX-01..02):** a new repo-root `Makefile`, `scripts/demo` delegation, and
`.env.example`. The launcher may read the existing demo/admin/SAML router surface for display, but
must not modify router or controller code.

**Explicitly NOT this phase:** the Docker build/cache mechanics, Compose topology, proxy routing,
or Keycloak trust flow completed in Phases 68-70; the Docker DX guide and README routing assigned
to Phase 72; any `lib/` security seam, public API, behaviour callback, protocol surface, or Hex
package-whitelist change.
</domain>

<decisions>
## Implementation Decisions

### Primary launcher and compatibility surface
- **D-01:** Add a repo-root `Makefile` as the canonical Docker launcher with the required targets:
  `proxy`, `up`, `up-build`, `up-d`, `up-d-build`, `down`, `reset`, `reseed`, `nuke`, `logs`,
  `url`, `open`, `fleet`, `doctor`, and `help`.
- **D-02:** Preserve all six existing `scripts/demo` verbs — `doctor`, `up`, `reset`, `test`,
  `urls`, and `down` — as thin delegations to corresponding Make targets. Do not silently rename,
  remove, or retain separate implementations for those commands.
- **D-03:** Keep `scripts/demo test` as the compatibility entry point for the existing browser
  proof path even though `test` is not required as a public Make target by DX-01; the planner may
  expose a Make helper target as needed to keep delegation literal and behavior centralized.

### Solo, fleet, and destructive operations
- **D-04:** Preserve the two intentional Compose invocation shapes. Solo targets use bare
  `docker compose`, allowing `docker-compose.override.yml` to publish the loopback app port.
  Fleet targets use explicit `-f docker-compose.yml -f docker-compose.proxy.yml`, excluding the
  solo override and its host-port binding. Keycloak remains opt-in through its existing profile.
- **D-05:** `reset` and `reseed` are compatibility aliases for the existing destructive demo-data
  refresh (`ecto.drop, ecto.setup`). Do not introduce a second, seed-only retention contract in
  this phase. `nuke` remains the visibly stronger operation for Compose teardown plus volume/cache
  removal; its exact confirmation/guard wording is planner discretion.

### Banner and route-map contract
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

### Fleet discovery, doctor, and environment surface
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

### Planner's Discretion
- Exact Make function/macros, target grouping, help formatting, ANSI/color behavior, URL opener
  fallback, and `nuke` confirmation mechanics are open provided D-01..D-11 hold.
- The precise internal Make helper used by `scripts/demo test` is open; preserve its existing
  Keycloak/browser-profile behavior and keep the legacy verb callable.
- Tests may replace or extend the existing script/README drift gate so the new Makefile is the
  canonical command inventory, but Phase 72 owns adopter-facing README prose changes.

### Folded Todos
None — `todo.match-phase 71` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- The approved north-star path recorded in project planning
  (`/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md`) is not present on this
  machine. Its locked launcher/banner intent is already carried forward in `.planning/PROJECT.md`,
  `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and Phases 68-70 context; planning must not
  block on the missing file or invent contrary decisions.
- `.planning/PROJECT.md` — milestone boundary, sibling-convention source of truth, locked hostname,
  HTTP posture, and no-`lib/` invariant.
- `.planning/REQUIREMENTS.md` — DX-01 and DX-02 acceptance criteria plus milestone exclusions.
- `.planning/ROADMAP.md` — Phase 71 goal, success criteria, scope note, and Phase 72 boundary.
- `.planning/phases/68-build-caching-correctness/68-CONTEXT.md` — cached build, entrypoint, and
  named-volume contracts the launcher invokes without changing.
- `.planning/phases/69-compose-split-fleet-proxy/69-CONTEXT.md` — solo/fleet Compose split,
  loopback binding, proxy-network, and hostname decisions.
- `.planning/phases/70-keycloak-behind-the-proxy/70-CONTEXT.md` — finalized Keycloak profile,
  proxy hostname, provisioner, and E2E contracts.
- `scripts/demo` — legacy six-verb compatibility surface and current portable doctor behavior.
- `docker-compose.yml`, `docker-compose.override.yml`, and `docker-compose.proxy.yml` — exact
  Compose shapes the Make targets must preserve.
- `docker/traefik/compose.yml` — shared proxy lifecycle, network, dashboard, and browser-only
  `*.localhost` caveat.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` — canonical application route mount points for
  banner display.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` — login and
  support-to-trace redirect behavior represented by the banner.
- `test/docs/demo_guide_drift_test.exs` — existing closed command-set drift gate affected by moving
  launcher authority to Make.
- `scripts/test_fleet_proxy_e2e.sh` and `scripts/test_keycloak_proxy_e2e.sh` — executable proof of
  the distinct solo/fleet Compose invocations and public/internal hostname boundaries.
- `/Users/jon/projects/scoria/Makefile` — newest sibling-library launcher convention for target
  naming, fleet discovery, doctor checks, and help output.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/demo` already provides portable `lsof`/`nc` port checks, the current reset and browser
  proof commands, and the six legacy verbs that must remain callable.
- The three Compose files already encode the correct solo-versus-fleet topology; the launcher only
  needs to select them consistently.
- `docker/traefik/compose.yml` already supplies the idempotent shared-proxy lifecycle inputs and
  dashboard location.
- The demo router and route-affordance controller already expose every application path needed for
  the URL banner; no application code change is necessary.

### Established Patterns
- Bare Compose intentionally auto-loads the solo override; fleet commands must spell both `-f`
  files so the solo port mapping is absent.
- Cross-repository fleet membership is discoverable through Traefik labels, not project names.
- Topology variables already have safe inline defaults, so `.env.example` is documentation and an
  override surface rather than a startup prerequisite.
- `test/docs/demo_guide_drift_test.exs` currently treats `scripts/demo` as the canonical command
  inventory; Phase 71 must deliberately migrate or extend that drift contract when Make becomes
  primary.

### Integration Points
- Repo-root `Makefile` orchestrates the existing Compose files and delegates shared banner/doctor
  helpers.
- `scripts/demo` becomes a compatibility adapter into Make.
- `.env.example` mirrors existing Compose variables without changing their runtime defaults.
- Launcher-focused tests should assert rendered Compose command shapes, URL-map contents, legacy
  verb delegation, fleet label discovery, and doctor network/port diagnostics without requiring
  changes under `lib/`.
</code_context>

<specifics>
## Specific Ideas

- Favor the concise, evaluator-friendly launcher style from `/Users/jon/projects/scoria/Makefile`,
  adapted to Relyra's static host and two-topology Compose split rather than copied blindly.
- Banner wording should distinguish browser URLs from container/service-DNS health probes and make
  the FakeIdP-first click-through path obvious before presenting optional Keycloak links.
- Every failing doctor check should pair the diagnosis with the next command a maintainer can run.
</specifics>

<deferred>
## Deferred Ideas

- Distinct seed-only `reseed` semantics — deferred; Phase 71 keeps it compatible with the existing
  destructive reset contract.
- Phase 72 owns `guides/docker_dev_dx.md`, demo README, `guides/demo.md`, and top-level README
  routing updates.
- TLS via mkcert, hashed per-checkout hostnames, and a production multi-stage release Dockerfile
  remain milestone-level future work.

### Reviewed Todos (not folded)
None — `todo.match-phase 71` returned 0 matches.
</deferred>
