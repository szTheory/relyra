# Phase 55: docker-ci-and-optional-keycloak-proof - Context

**Gathered:** 2026-06-12 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Add Docker orchestration, Keycloak integration, and CI proving for the demo application.
</domain>

<decisions>
## Implementation Decisions

### Docker Compose Orchestration
- **D-01:** A new top-level `docker-compose.yml` will consolidate the demo app, Keycloak, and browser testing using Compose profiles, replacing or wrapping `docker/keycloak/docker-compose.yml`.

### Demo CLI and Diagnostics
- **D-02:** `scripts/demo` will be implemented as a standalone Bash script rather than an Elixir Mix task or Makefile.

### CI Isolation & FakeIdP Priority
- **D-03:** `mix ci.demo_app` will be added as a standalone alias in `mix.exs` (triggering via a new GitHub workflow), and Keycloak will remain strictly opt-in for baseline CI runs.

### Claude's Discretion
- Playwright in Docker Compose best practices (whether to use official Playwright Docker image as a compose service, or run Playwright on the host against the `core` containers).
- Keycloak 26.0 Hostname Strictness in Compose Networks configuration.

### Folded Todos
None
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `demo/ledger_loop/mix.exs`
- `docker/keycloak/docker-compose.yml`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docker/keycloak/docker-compose.yml` provides the base configuration for Keycloak.
- `demo/ledger_loop/mix.exs` is the demo application's entrypoint.

### Established Patterns
- Existing bash scripts (`scripts/check_demo_package_exclusion.sh`, `scripts/stress_keycloak_lane.sh`) establish bash as the standard for orchestration utilities.
- Isolated CI gates (`ci.external_idp` vs `ci.security`) exist in `mix.exs`.

### Integration Points
- Compose needs to integrate with the root test commands or CI workflows.
- `scripts/demo` needs to orchestrate the Docker Compose interactions.
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>
