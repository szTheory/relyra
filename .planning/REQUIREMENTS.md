# Requirements: v1.10 Docker DX & Fleet Proxy

**Milestone goal:** Make the `demo/ledger_loop` Docker experience fast, conflict-free across the maintainer's other Elixir OSS lib demos, and self-documenting — demo + docker + docs only, with zero changes to `lib/` security seams, public API, protocol surface, or the Hex package whitelist.

**Design north-star:** `/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md` (approved).
**Convention source of truth:** the maintainer's own newest sibling-lib pattern — `scoria` (`Makefile`, `docker/traefik/compose.yml`, `docs/docker_dev_dx.md`), cross-checked vs `sigra` and `rulestead`.

**Locked decisions:** simple `relyra.localhost` hostname (static `COMPOSE_PROJECT_NAME=relyra`); scheme `http` (no mkcert); Keycloak routed fully behind the proxy.

---

## v1.10 Requirements

### Build caching & correctness (DKR)

- [x] **DKR-01**: A developer builds the demo from a dedicated `Dockerfile.dev` that copies `mix.exs`/`mix.lock` before source and fetches/compiles deps in a cached layer (with BuildKit cache mounts for the Hex/rebar caches), so a source edit never invalidates the dependency layer.
- [x] **DKR-02**: `deps/` and `_build/` are backed by container-private named volumes that mask the bind-mounted source, so the macOS host's compiled artifacts are never shared into the Linux container (no NIF/arch breakage, no recompile churn).
- [x] **DKR-03**: A container entrypoint re-runs `mix deps.get`/`deps.compile` only when `mix.lock` changed (hash stamp) and runs `ecto.create`/`ecto.migrate` idempotently — no blind dependency re-resolution or re-seed on every `up`.
- [x] **DKR-04**: Editing a LiveView template or stylesheet live-reloads in the browser without a container restart or dependency re-fetch (`phoenix_live_reload` `:fs_poll` works across the macOS→Docker mount boundary).

### Fleet coexistence & proxy (FLEET)

- [x] **FLEET-01**: A plain `docker compose up` runs the demo standalone, reachable at `http://localhost:<port>`, with zero proxy setup and with Postgres NOT published to a host port (eliminating the `:5432` machine-wide collision).
- [x] **FLEET-02**: A shared Traefik proxy on an external `proxy` network can be started idempotently with `docker network inspect proxy >/dev/null 2>&1 || docker network create proxy`, then `docker compose -f docker/traefik/compose.yml up -d`, and, via an opt-in `docker-compose.proxy.yml` overlay, routes the demo at `http://relyra.localhost` — so multiple sibling lib demos run concurrently with no host-port contention, and the proxy is never a hard dependency of the solo path.
- [x] **FLEET-03**: The demo's Phoenix endpoint `url`/`check_origin` are correct for both the solo host (`localhost:<port>`) and the proxy host (`relyra.localhost`), so the LiveView operator UI websocket connects and Relyra's recipient/Destination checks match the public ACS URL.

### Keycloak behind the proxy (KC)

- [x] **KC-01**: The optional Keycloak real-IdP profile runs behind the proxy at `http://keycloak.relyra.localhost` with correct `KC_HOSTNAME` + `KC_PROXY_HEADERS=xforwarded` and realm URLs/redirect-URIs pointing at `relyra.localhost`, so the full Keycloak-backed SAML login round-trip succeeds end-to-end.

### Launcher DX & self-documenting launch (DX)

- [ ] **DX-01**: A `Makefile` is the primary launcher (`proxy`, `up`/`up-build`, `up-d`/`up-d-build`, `down`, `reset`/`reseed`, `nuke`, `logs`, `url`, `open`, `fleet`, `doctor`, `help`), and the existing `scripts/demo` verbs keep working by delegating to it.
- [ ] **DX-02**: Launching the demo prints a copy-pasteable URL/route map (app home, operator UI, login-test, support trace, Keycloak admin, Traefik dashboard, health) plus the click-through walkthrough; `make fleet` lists all running Traefik-routed demos; `doctor` checks ports `4000`/`5432`/`8080` and whether the `proxy` network exists.

### Documentation (DOC)

- [ ] **DOC-01**: `guides/docker_dev_dx.md` documents the Solo path vs Fleet path, the caching model (why edits are fast), the URL map, and troubleshooting (port conflicts, missing `proxy` network, `*.localhost` browser-only caveat, Keycloak hostname), in house voice — gameplan summary at top, persona/JTBD framing, "Receipt:" proof lines — per the newest `brandbook/`.
- [ ] **DOC-02**: The demo README Quick Start, `guides/demo.md`, and the top-level README Day-2/operator routing are updated to the new Make targets and the Fleet path (the Local Mix option is retained).

---

## Future Requirements (deferred)

- **TLS via mkcert** — local HTTPS for `*.relyra.localhost` (trusted CA) is documented as an optional note only; SAML works over `http` on localhost, so TLS is deferred unless a flow requires it.
- **Hashed per-checkout instance hostnames** (scoria-style `relyra-<branch>-<hash>.localhost`) — deferred; the maintainer chose simple `relyra.localhost` and single-checkout-at-a-time for relyra.
- **Production deployment Dockerfile** (multi-stage `mix release`) — this milestone is dev/demo DX only.

## Out of Scope (explicit exclusions)

- **Any `lib/` change** — security seams, parser, crypto, replay, audit, public API, behaviour callbacks, and protocol surface are untouched. This is demo + docker + docs only.
- **New Hex package surface** — no change to `mix.exs` `package.files` whitelist; nothing new ships in the tarball.
- **Hosted/shared Postgres across projects** — each demo keeps its own isolated `pgdata` volume; the fix is removing the published host port, not sharing a database.
- **Orbstack / Caddy / nginx-proxy migration** — researched as alternatives; Traefik is chosen to match the existing sibling-lib convention. Not re-litigated here.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DKR-01 | Phase 68 | Complete |
| DKR-02 | Phase 68 | Complete |
| DKR-03 | Phase 68 | Complete |
| DKR-04 | Phase 68 | Complete |
| FLEET-01 | Phase 69 | Complete |
| FLEET-02 | Phase 69 | Complete |
| FLEET-03 | Phase 69 | Complete |
| KC-01 | Phase 70 | Gaps Found |
| DX-01 | Phase 71 | Pending |
| DX-02 | Phase 71 | Pending |
| DOC-01 | Phase 72 | Pending |
| DOC-02 | Phase 72 | Pending |
