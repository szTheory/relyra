# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for Elixir/Phoenix. The v1.x arc is shipped through **v1.9 - Loose Ends & Adoption Honesty**. The active milestone is **v1.10 - Docker DX & Fleet Proxy** (Phases 68-72): make the `demo/ledger_loop` Docker experience fast, conflict-free across the maintainer's other Elixir OSS lib demos, and self-documenting. Future protocol work remains demand-gated unless a real adopter signal changes the scope.

## Milestones

- Complete: **v0.1 - SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 - Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 - LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 - IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 - Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 - Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 - External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 - Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 - Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 - Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 - Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 - Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 - Adoption Evidence Demo** (shipped 2026-06-13). See `.planning/milestones/v1.7-ROADMAP.md`.
- Complete: **v1.8 - Brand System & Identity** (shipped 2026-06-14). See `.planning/milestones/v1.8-ROADMAP.md`.
- Complete: **v1.9 - Loose Ends & Adoption Honesty** (shipped 2026-06-19, Phases 64-67, 15/15 requirements; audit status `tech_debt` for non-blocking validation metadata). See `.planning/milestones/v1.9-ROADMAP.md`.
- Active: **v1.10 - Docker DX & Fleet Proxy** (Phases 68-72, 12 requirements). See "v1.10 Phases" below.

## Milestone-Wide Invariant (v1.10)

**Demo + docker + docs ONLY.** Every phase in this milestone is bounded by a single hard constraint: zero changes to `lib/` security seams, public API, behaviour callbacks, protocol surface, or the Hex package whitelist (`mix.exs` `package.files`). Nothing new ships in the published tarball. Every phase's work lives in `demo/ledger_loop/`, repo-root docker/launcher files (`docker-compose*.yml`, `docker/`, `Makefile`, `.dockerignore`, `.env.example`, `scripts/demo`), and `guides/` + `README.md` documentation. Repo gates (`mix qa`, `mix ci.security`, `mix format --check-formatted`, `mix test --warnings-as-errors`) must stay green precisely because no `lib/` code is touched.

**Locked decisions:** simple `relyra.localhost` hostname (static `COMPOSE_PROJECT_NAME=relyra`, single checkout at a time, `RELYRA_HOST` override hook retained); scheme `http` (no mkcert); shared Traefik proxy on an external `proxy` network matching the `scoria` sibling-lib convention; Keycloak routed fully behind the proxy.

**Design north-star:** `/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md` (approved).

## v1.10 Phases

- [x] **Phase 68: Build caching & correctness** - Cached, arch-correct container build so source edits never re-fetch or recompile deps and live edits reload. (completed 2026-06-19)
- [ ] **Phase 69: Compose split & fleet proxy** - Solo-first compose with no published Postgres port plus an opt-in Traefik overlay so sibling lib demos coexist.
- [ ] **Phase 70: Keycloak behind the proxy** - Real-IdP Keycloak round-trip works end-to-end at nice hostnames behind the shared proxy.
- [ ] **Phase 71: Launcher DX & banner** - A Makefile primary launcher with a copy-pasteable URL/route map, `make fleet`, and `doctor`.
- [ ] **Phase 72: Documentation** - House-voice Docker DX guide plus demo/README routing updates describing the finished surface.

## v1.10 Phase Details

### Phase 68: Build caching & correctness

**Goal**: A developer iterates on the demo in Docker as fast as native — small source/style edits reload instantly and never trigger a dependency re-fetch or recompile.
**Depends on**: Nothing (first phase of v1.10)
**Requirements**: DKR-01, DKR-02, DKR-03, DKR-04
**Success Criteria** (what must be TRUE):

  1. A source-only edit rebuilds the demo image without re-running `mix deps.get`/`deps.compile` (the dependency layer stays cached because `mix.exs`/`mix.lock` are copied before source and Hex/rebar caches use BuildKit cache mounts).
  2. The container compiles its own Linux `deps/` and `_build/` into named volumes that mask the bind mount, so the macOS host's compiled artifacts are never shared in (no NIF/arch breakage, no recompile churn).
  3. Running `up` a second time after a `down` re-resolves dependencies only when `mix.lock` changed (lock-hash stamp) and runs `ecto.create`/`ecto.migrate` idempotently — no blind re-resolution or re-seed.
  4. Editing a LiveView `.heex` template or stylesheet live-reloads in the browser with no container restart and no dependency work (`phoenix_live_reload` `:fs_poll` crosses the macOS→Docker mount boundary).

**Scope note**: Touches `demo/ledger_loop/Dockerfile.dev`, `demo/ledger_loop/docker-entrypoint.sh`, `.dockerignore`, named-volume overlay in compose, and `demo/ledger_loop/config/dev.exs`. No `lib/` change.
**Plans**: 2/2 plans complete

- [x] 68-01-PLAN.md — The build: Dockerfile.dev (cached dep layer, pinned base), docker-entrypoint.sh (lock-hash gate + ecto ordering), repo-root .dockerignore [DKR-01, DKR-03]
- [x] 68-02-PLAN.md — Wire + run: docker-compose.yml demo_app overlay (build + nested named volumes + command) and dev.exs top-level `:fs_poll` block [DKR-02, DKR-03, DKR-04]

**UI hint**: yes

### Phase 69: Compose split & fleet proxy

**Goal**: The solo `docker compose up` stays zero-setup at `localhost` with no machine-wide Postgres port collision, and an opt-in shared Traefik proxy lets multiple sibling lib demos run at `*.localhost` simultaneously with no port contention.
**Depends on**: Phase 68 (the base compose consumes the `Dockerfile.dev` build + entrypoint + named volumes established there)
**Requirements**: FLEET-01, FLEET-02, FLEET-03
**Success Criteria** (what must be TRUE):

  1. A plain `docker compose up` runs the demo standalone, reachable at `http://localhost:<port>`, with Postgres NOT published to a host port (the auto-loaded `docker-compose.override.yml` publishes only `127.0.0.1:<port>:4000`).
  2. `make proxy` idempotently creates the external `proxy` network and starts the shared Traefik proxy; the opt-in `docker-compose.proxy.yml` overlay routes the demo at `http://relyra.localhost` and the proxy is never a hard dependency of the solo path.
  3. Two sibling lib demos (relyra + another) run concurrently behind the proxy with no host-port error, because neither publishes Postgres and both route by `Host()` label on the shared network.
  4. The demo's Phoenix endpoint `url`/`check_origin` are correct for both the solo host (`localhost:<port>`) and the proxy host (`relyra.localhost`), so the LiveView operator-UI websocket connects and Relyra's recipient/Destination checks match the public ACS URL.

**Scope note**: Touches `docker-compose.yml`, `docker-compose.override.yml`, `docker-compose.proxy.yml`, `docker/traefik/compose.yml`, and `demo/ledger_loop/config/runtime.exs`/`config.exs`. Traefik router/service names prefixed `relyra-*` to avoid cross-project namespace collisions; host ports bound to `127.0.0.1`. No `lib/` change.
**Plans**: TBD
**UI hint**: yes

### Phase 70: Keycloak behind the proxy

**Goal**: The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Depends on**: Phase 69 (requires the shared proxy, the `proxy`-overlay routing, and the proxy-host Phoenix `url`/`check_origin` config)
**Requirements**: KC-01
**Success Criteria** (what must be TRUE):

  1. Keycloak is reachable in the browser at `http://keycloak.relyra.localhost` with `KC_HOSTNAME` + `KC_PROXY_HEADERS=xforwarded` set so the realm issuer/host equals the browser-facing host.
  2. The seeded realm's clientId, root/base/admin URLs, ACS, and redirect URIs point at `http://relyra.localhost` (ACS = `http://relyra.localhost/saml/<connection_id>/acs`), with a documented split-horizon note that container-to-container calls use the `keycloak:8080` service name and `*.localhost` is browser-only.
  3. A browser-driven Keycloak login redirects to `keycloak.relyra.localhost`, returns a signed assertion to `relyra.localhost/saml/.../acs`, and Relyra verifies it (recipient/Destination match) and establishes a session.

**Scope note**: Touches `docker/keycloak/realm-demo-app.json` and the keycloak service/env in `docker-compose.proxy.yml`. No `lib/` change — Relyra's verification is exercised, not modified.
**Plans**: TBD

### Phase 71: Launcher DX & banner

**Goal**: Launching the demo is self-documenting — one primary launcher prints a copy-pasteable URL/route map, surfaces the running fleet, and diagnoses common port/network problems.
**Depends on**: Phase 70 (the launcher wraps and prints the full compose surface: solo ports, proxy routing, and Keycloak hostnames finalized in 68-70)
**Requirements**: DX-01, DX-02
**Success Criteria** (what must be TRUE):

  1. A `Makefile` is the primary launcher (`proxy`, `up`/`up-build`, `up-d`/`up-d-build`, `down`, `reset`/`reseed`, `nuke`, `logs`, `url`, `open`, `fleet`, `doctor`, `help`) and the existing `scripts/demo` verbs keep working by delegating to it.
  2. `make up-d` (and `scripts/demo urls`) prints a copy-pasteable URL/route map — app home, operator UI, login-test, support trace, Keycloak admin, Traefik dashboard, health — plus the click-through walkthrough, with the proxy URL and an ephemeral loopback fallback.
  3. `make fleet` lists all running Traefik-routed demos across repos, and `doctor` checks ports `4000`/`5432`/`8080` and whether the `proxy` network exists.

**Scope note**: Touches `Makefile`, `scripts/demo`, and `.env.example`. The banner reads the route map from the demo/admin/SAML routers for display only — no router code changes. No `lib/` change.
**Plans**: TBD

### Phase 72: Documentation

**Goal**: A new reader can go zero→login using only the guide, and existing demo/README routing points at the new Make targets and Fleet path in house voice.
**Depends on**: Phase 71 (docs describe the finished launcher, URL map, and both paths once 68-71 land)
**Requirements**: DOC-01, DOC-02
**Success Criteria** (what must be TRUE):

  1. `guides/docker_dev_dx.md` documents the Solo path vs Fleet path, the caching model (why edits are fast), the URL map, and troubleshooting (port conflicts, missing `proxy` network, `*.localhost` browser-only caveat, Keycloak hostname) in house voice — gameplan summary at top, persona/JTBD framing, "Receipt:" proof lines per the newest `brandbook/`.
  2. The demo README Quick Start, `guides/demo.md`, and the top-level README Day-2/operator routing are updated to the new Make targets and the Fleet path, with the Local Mix option retained.
  3. A reader following only the new guide reaches a successful FakeIdP login without external context (the "Receipt" proof lines are reproducible).

**Scope note**: Touches `guides/docker_dev_dx.md`, `demo/ledger_loop/README.md`, `guides/demo.md`, and `README.md`. Brand voice per `brandbook/notes/decision-log.md` Canonical Lock Set (newest source, supersedes `prompts/relyra-brand-book.md`). No `lib/` change; no new Hex package surface.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 68. Build caching & correctness | 2/2 | Complete   | 2026-06-19 |
| 69. Compose split & fleet proxy | 0/? | Not started | - |
| 70. Keycloak behind the proxy | 0/? | Not started | - |
| 71. Launcher DX & banner | 0/? | Not started | - |
| 72. Documentation | 0/? | Not started | - |

## Current Status

v1.10 - Docker DX & Fleet Proxy is active (Phases 68-72). Next: `/gsd-plan-phase 68`.

## Demand-Gated Future Candidates

- **AUTHN-POST-01** - HTTP-POST binding signed AuthnRequests with enveloped XML signature and C14N. Demand-gated until a real adopter issue appears.
- **KMS-01** - KMS-native `KeyResolver` adapters for services such as AWS KMS or GCP KMS. Demand-gated until a real adopter issue appears.
- **SIGNED-META-01** - Signed SP metadata (`EntityDescriptor`) plus federation extensions and InCommon runbook. Demand-gated until a real adopter issue appears.

---
*Roadmap updated: 2026-06-19 — v1.10 Docker DX & Fleet Proxy milestone roadmapped (Phases 68-72)*
