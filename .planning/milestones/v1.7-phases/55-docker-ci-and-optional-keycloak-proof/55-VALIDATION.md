# Phase 55 Validation

**Phase:** 55
**Focus:** Docker CI and Optional Keycloak Proof

## Steps to Validate

1. **Verify Docker Compose Profiles**
   Run `docker compose config --profile core` and confirm no errors are present.
   Run `docker compose config --profile keycloak` and confirm Keycloak is included.
   Run `docker compose config --profile browser` and confirm Playwright is included.

2. **Verify DX-02 Healthchecks and Env-driven Ports**
   Inspect `docker-compose.yml`.
   - Verify `db` has a `healthcheck` and its port mapping uses an environment variable fallback (e.g., `"${PGPORT:-5432}:5432"`).
   - Verify `demo_app` has a `healthcheck` and its port mapping uses an environment variable fallback (e.g., `"${PORT:-4000}:4000"`).
   - Verify `keycloak` has a `healthcheck` and its port mapping uses an environment variable fallback (e.g., `"${KC_PORT:-8080}:8080"`).

3. **Verify DX-03 Local Blockers**
   Run `./scripts/demo doctor`.
   - It should check for `docker` and `mix`.
   - It should perform port collision checks (e.g., checking if ports 4000 or 8080 are already in use) and warn if they are occupied.

4. **Verify Container Execution**
   Start the demo app: `./scripts/demo up`. Wait for healthchecks to pass.
   - Run `./scripts/demo test` and verify Playwright executes the browser tests against Keycloak successfully.
   Stop everything: `./scripts/demo down`.