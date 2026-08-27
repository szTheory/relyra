# Phase 72: Documentation - Context

**Gathered:** 2026-08-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Document the finished v1.10 Docker developer experience so a new reader can go from a fresh
checkout to a successful FakeIdP login using `guides/docker_dev_dx.md` alone, then route existing
demo and repository readers to the same Make-first Solo and Fleet workflows.

**In scope (DOC-01..02):** create `guides/docker_dev_dx.md`; update
`demo/ledger_loop/README.md`, `guides/demo.md`, and `README.md`; preserve the Local Mix path; explain
the cache model, URL map, troubleshooting, and optional Keycloak proof in the Canonical Lock Set's
house voice.

**Explicitly NOT this phase:** changes to the cached build, Compose topology, proxy/Keycloak
configuration, launcher behavior, application routes, browser proof, anything under `lib/`, any
public API or security-posture change, or any new Hex package surface. Documentation must describe
the executable surface completed in Phases 68-71 without redesigning it.
</domain>

<decisions>
## Implementation Decisions

### Guide journey and topology
- **D-01:** Make the Solo FakeIdP path the guide's complete, deterministic zero-to-login journey.
  A reader following only `guides/docker_dev_dx.md` must be able to check prerequisites, launch the
  demo, open the login-test route, complete the FakeIdP sign-in, and inspect the resulting receipt.
- **D-02:** Present Fleet plus optional Keycloak as the second path: Fleet is for running sibling
  library demos together behind the shared proxy, and Keycloak is the optional real-IdP proof.
  Neither may become a prerequisite for the Solo/FakeIdP success path.

### Commands, URL map, and troubleshooting
- **D-03:** Document the repo-root `Makefile` as the primary Docker interface. Lead with the
  relevant public targets (`make doctor`, `make up-build`, `make up`, `make url`, `make proxy`,
  `make fleet`, lifecycle/recovery targets); mention `scripts/demo` only as the retained
  compatibility entry point, not as a parallel canonical workflow.
- **D-04:** Reproduce the launcher's browser contract accurately: Solo uses the loopback origin,
  Fleet uses `http://relyra.localhost`, optional Keycloak uses
  `http://keycloak.relyra.localhost`, and Traefik's dashboard remains on loopback port 8080.
  State plainly that `*.localhost` names are browser-facing; container health checks, bootstrap,
  and internal probes continue to use Docker service DNS.

### Cache model and recovery guidance
- **D-05:** Explain fast edits as three cooperating mechanisms: source is bind-mounted, Linux
  `deps/` and `_build/` stay in container-private named volumes, and the entrypoint reruns
  dependency resolution only when `mix.lock` changes. BuildKit download caches are supporting
  detail, not the whole explanation.
- **D-06:** Troubleshooting follows a graduated recovery ladder. Start with `make doctor` and the
  concrete corrective command it reports; use ordinary shutdown/restart next; explain that
  `reset` and `reseed` share the existing destructive database-refresh behavior; reserve
  `make nuke` for a deliberately labelled cold rebuild that deletes demo data and build/dependency
  volumes. Cover port conflicts, a missing external proxy network, the browser-only localhost
  caveat, and Keycloak public-host mismatch without inventing unsupported recovery paths.

### Receipts, honesty, and documentation routing
- **D-07:** Every proof line must keep ownership exact: Relyra verifies the assertion and produces
  the validation trace; LedgerLoop maps the user and records the host-owned session-establishment
  receipt. Do not imply that Relyra establishes a conventional browser cookie session, and do not
  collapse the FakeIdP deterministic proof into the optional Keycloak proof.
- **D-08:** Use the established house structure: a short gameplan at the top, persona/JTBD framing,
  copy-pasteable commands and URLs, and explicit `Receipt:` lines that name reproducible evidence.
  Voice remains calm, exact, transparent, operator-friendly, and open-source serious; avoid magic,
  absolutist security claims, and vague success language.
- **D-09:** Update all three existing routers coherently. The demo README owns the detailed
  evaluator Quick Start and retains Local Mix; `guides/demo.md` routes to both the Docker DX guide
  and the canonical demo README; the top-level README adds the Docker demo/Fleet guide to its
  evaluator and Day-2/operator routing without displacing the library's canonical Day-1 Getting
  Started path.

### the agent's Discretion
- Exact heading names, prose length, table layout, command grouping, cross-link placement, and the
  number of `Receipt:` lines are open provided D-01..D-09 and DOC-01..02 remain directly visible.
- The planner may extend focused documentation drift tests when needed to make the new acceptance
  criteria deterministic, but must not add manual-only or human-blocking verification.

### Folded Todos
None — `todo.match-phase 72` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and upstream decisions
- `.planning/PROJECT.md` — v1.10 goal, hard documentation-only boundary, sibling convention, and
  brand/security posture.
- `.planning/REQUIREMENTS.md` — DOC-01 and DOC-02 acceptance criteria plus explicit exclusions.
- `.planning/ROADMAP.md` — Phase 72 goal, success criteria, dependency, and exact file scope.
- `.planning/STATE.md` — current milestone position and accumulated Docker/Keycloak/launcher
  constraints.
- `.planning/phases/68-build-caching-correctness/68-CONTEXT.md` — authoritative cache, named-volume,
  entrypoint, and live-reload model the guide explains.
- `.planning/phases/69-compose-split-fleet-proxy/69-CONTEXT.md` — authoritative Solo/Fleet topology,
  loopback binding, proxy network, and split-horizon URL decisions.
- `.planning/phases/70-keycloak-behind-the-proxy/70-CONTEXT.md` — authoritative optional Keycloak
  journey, public/internal hostname boundary, and truthful receipt language.
- `.planning/phases/71-launcher-dx-banner/71-CONTEXT.md` — authoritative Make target, banner,
  walkthrough, fleet, doctor, and compatibility contracts.

### Brand and documentation convention
- `brandbook/notes/decision-log.md` — Canonical Lock Set; newest voice and naming authority,
  superseding conflicting narrative-brand guidance.
- `brandbook/README.md` — brand artifact routing and current design-system context.
- `/Users/jon/projects/scoria/docs/docker_dev_dx.md` — newest sibling-library Docker DX convention
  for gameplan, mental model, footguns, receipts, and recovery structure; adapt to Relyra's locked
  static-host and two-topology contracts rather than copying blindly.

### Runtime and proof surface
- `Makefile` — canonical public launcher target inventory, URL map, walkthrough, recovery commands,
  fleet discovery, and doctor diagnostics.
- `scripts/demo` — retained six-verb compatibility adapter into Make.
- `.env.example` — optional environment override surface and demo-credential warnings.
- `docker-compose.yml`, `docker-compose.override.yml`, and `docker-compose.proxy.yml` — exact Solo,
  Fleet, and optional Keycloak Compose shapes.
- `docker/traefik/compose.yml` — shared proxy lifecycle, external network, and dashboard contract.
- `demo/ledger_loop/Dockerfile.dev` — dependency-layer and BuildKit cache behavior.
- `demo/ledger_loop/docker-entrypoint.sh` — lock-hash gate, migration/seed ordering, and runtime
  dependency behavior.
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` — host-owned `LoginReceipt` wording
  and the boundary between Relyra verification and LedgerLoop session establishment.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` — current
  FakeIdP-first and optional-Keycloak evaluator affordances.
- `test/docs/demo_guide_drift_test.exs` — executable launcher, URL-map, compatibility, recovery, and
  environment contract.
- `test/docs/markdown_link_smoke_test.exs` and `test/docs/adopter_voice_test.exs` — existing
  documentation link and house-voice gates.
- `scripts/test_fleet_proxy_e2e.sh` and `scripts/test_keycloak_proxy_e2e.sh` — reproducible topology
  and real-IdP proof commands the docs may route to without redefining.

### Phase 72 documentation targets
- `guides/docker_dev_dx.md` — new canonical Docker DX guide produced by this phase.
- `demo/ledger_loop/README.md` — detailed evaluator entry point and retained Local Mix path.
- `guides/demo.md` — HexDocs/source-repo routing page for the demo and Docker guide.
- `README.md` — GitHub evaluator router and Day-2/operator guide index.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo-root `Makefile` already centralizes every command, URL, topology note, walkthrough step,
  and recovery action Phase 72 needs to document; docs should derive from it rather than maintain a
  competing command vocabulary.
- `test/docs/demo_guide_drift_test.exs` already parses the Makefile and exercises deterministic
  fixtures for launcher behavior, giving Phase 72 a focused seam for automated doc/runtime drift
  checks.
- The demo login affordance, session adapter, Fleet/Keycloak E2E harnesses, and launcher banner
  already supply concrete, truthful receipts for both the deterministic and optional paths.
- The existing demo README contains the Local Mix flow, ownership boundary, seeded scenarios, and
  evaluator framing worth preserving while its Docker/Keycloak instructions are refreshed.

### Established Patterns
- The repository README is a router, not the full onboarding narrative. The demo README is the
  detailed evaluator entry point; focused guides own their full operational narrative.
- Solo is zero-setup and FakeIdP-first. Fleet is opt-in and proxy-backed. Keycloak is optional,
  proxy-only, and never part of ordinary boot.
- Browser-facing public origins and container service-DNS endpoints are distinct contracts.
- Documentation makes success falsifiable with named receipts and preserves the sharp boundary:
  Relyra verifies; the host application maps, establishes its session representation, and
  authorizes.
- Local Mix remains a supported alternate demo path even though Make is canonical for Docker.

### Integration Points
- Create the new Docker DX guide from the authoritative Phase 68-71 runtime contracts and link it
  into all three existing routing documents.
- Replace stale `scripts/demo`-first and direct `localhost:8080` Keycloak instructions in the demo
  README with Make-first Solo/Fleet commands and the proxy-only Keycloak public origin.
- Keep `guides/demo.md` concise while adding the new guide as the Docker operational entry point.
- Add the new guide to top-level evaluator/Day-2 routing without competing with Getting Started as
  the library integration path.
- Extend deterministic docs gates only where necessary to prove guide command, route, receipt, and
  cross-link contracts.
</code_context>

<specifics>
## Specific Ideas

- Open the guide with a two-path gameplan: “Solo: prove one local login” followed by “Fleet:
  coexist with sibling demos; add Keycloak when you want the real-IdP receipt.”
- Make the Solo receipt concrete: the reader reaches `/login/test`, completes the FakeIdP flow,
  returns to LedgerLoop, and can inspect the corresponding validation trace/receipt.
- Explain the cache model as “source moves, Linux artifacts stay put, dependencies only refresh
  when the lock changes,” then show the exact underlying mounts and stamp for readers diagnosing
  drift.
- Pair every troubleshooting symptom with the next command, preserving the launcher convention
  that diagnostics are recovery-oriented rather than descriptive only.
- Keep the proof sentence exact: “Relyra verified the assertion; LedgerLoop mapped the user and
  recorded the session-establishment receipt.”
</specifics>

<deferred>
## Deferred Ideas

- TLS/mkcert, hashed per-checkout hostnames, and a production multi-stage release Dockerfile remain
  outside v1.10.
- Any change to launcher behavior, Compose topology, Keycloak provisioning, application routes,
  browser tests, `lib/`, public API, security posture, or Hex packaging belongs outside Phase 72.

### Reviewed Todos (not folded)
None — `todo.match-phase 72` returned 0 matches.
</deferred>

---

*Phase: 72-documentation*
*Context gathered: 2026-08-27*
