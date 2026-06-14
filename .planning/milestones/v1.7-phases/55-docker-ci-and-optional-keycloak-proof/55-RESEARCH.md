<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** A new top-level `docker-compose.yml` will consolidate the demo app, Keycloak, and browser testing using Compose profiles, replacing or wrapping `docker/keycloak/docker-compose.yml`.
- **D-02:** `scripts/demo` will be implemented as a standalone Bash script rather than an Elixir Mix task or Makefile.
- **D-03:** `mix ci.demo_app` will be added as a standalone alias in `mix.exs` (triggering via a new GitHub workflow), and Keycloak will remain strictly opt-in for baseline CI runs.

### the agent's Discretion
- Playwright in Docker Compose best practices (whether to use official Playwright Docker image as a compose service, or run Playwright on the host against the `core` containers).
- Keycloak 26.0 Hostname Strictness in Compose Networks configuration.

### Deferred Ideas (OUT OF SCOPE)
None — analysis stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | Root `scripts/demo` supports `doctor`, `up`, `reset`, `test`, `urls`, and `down`. | Provided bash pattern using standard case statements and Docker Compose abstraction. |
| DX-02 | Compose setup uses project-name isolation, env-driven ports, profiles for `core`/`keycloak`/`browser`, no fixed `container_name`, and healthchecks/readiness probes. | Documented top-level `docker-compose.yml` strategy with profiles. |
| DX-03 | `doctor` detects common local blockers and prints exact environment overrides or remediation steps. | Provided standard checks for missing dependencies (Docker, Mix) and port collisions. |
| CI-01 | Focused `mix ci.demo_app` lane compiles, migrates, seeds, and proves local FakeIdP + Ecto store behavior without weakening `mix ci.security`. | Analyzed `mix.exs` integration and parallel test suites. |
| IDP-03 | Optional Keycloak profile completes a browser-visible external IdP happy path against the launched Phoenix demo app. | Playwright and Keycloak Docker Compose orchestrations defined. |
| IDP-04 | Keycloak proof preserves configured-certificate trust and never treats document `KeyInfo` as a trust source. | Ensured no weakening of security logic in the test app context. |
| E2E-02 | Optional Keycloak browser proof is isolated from required deterministic demo proof until burn-in justifies promotion. | Documented `ci.demo_app` separation from keycloak optional run. |
</phase_requirements>

# Phase 55: Docker, CI, And Optional Keycloak Proof - Research

**Researched:** 2026-06-12
**Domain:** Docker orchestration, CI integration, Browser testing (Playwright), Keycloak (Quarkus)
**Confidence:** HIGH

## Summary

This phase unifies the demo application (`demo/ledger_loop`), Keycloak (`26.0.7`), and Playwright (`v1.54.2`) into a single Docker Compose orchestration (`docker-compose.yml`). The orchestration is managed by a new Bash script (`scripts/demo`) which provides a streamlined developer experience (DX). 

**Primary recommendation:** Use a root `docker-compose.yml` with `core`, `keycloak`, and `browser` profiles. Retain `KC_HOSTNAME_STRICT="false"` for Keycloak in Compose to avoid redirect URI mismatches, and run Playwright tests from a dedicated Docker service mapped to host memory (`ipc: host`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| E2E Tests | Browser / Client | Docker (`browser`) | Playwright should run inside Docker (`mcr.microsoft.com/playwright`) using `ipc: host` to guarantee execution consistency across developer machines and CI. |
| Demo Host | Frontend Server | Docker (`core`) | The Phoenix application running in `demo/ledger_loop`, exposed on host ports. |
| IdP Proof | Auth Provider | Docker (`keycloak`) | Optional external provider for explicit trust proof, running Keycloak 26.0.7. |
| Orchestration | Host OS | `scripts/demo` | Bash provides the lowest friction CLI wrapper over `docker compose --profile`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Docker Compose | v2 | Container orchestration | Built-in profile support makes isolating the `browser` and `keycloak` test scopes trivial. |
| Playwright | `v1.54.2-jammy` | Browser automation | Official Microsoft image matches `package.json` (`^1.54.2`), ensuring test runtime is locked and consistent without downloading browsers on the host. |
| Keycloak | `26.0.7` | Identity Provider | Existing known-good IdP for SAML proofs. Version matches existing Keycloak configuration. |

## Package Legitimacy Audit

*No new Elixir dependencies or npm packages are introduced in this phase (only Docker image pinning).*

## Architecture Patterns

### Recommended Project Structure
```
/
├── docker-compose.yml        # Consolidates core, keycloak, and browser profiles
├── scripts/
│   └── demo                  # Bash script: doctor, up, reset, test, urls, down
├── .github/workflows/
│   └── demo-app-ci.yml       # Isolated GitHub workflow for mix ci.demo_app
└── demo/ledger_loop/
    └── mix.exs               # Contains demo-specific aliases
```

### Pattern 1: Docker Compose Profiles
**What:** Define services under specific profiles (e.g. `profiles: ["keycloak"]`) so they only start when explicitly requested.
**When to use:** To ensure `docker compose up` only runs the essential stack (`core`) by default, while allowing `docker compose --profile keycloak up` for IdP testing.
**Example:**
```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.0.7
    profiles: ["keycloak"]
    # ...
```

### Pattern 2: Keycloak 26 Hostname Strictness
**What:** Keycloak >= 25 uses `hostname:v2` by default. In Docker Compose networks, the internal service name (`http://keycloak:8080`) often differs from the host's view (`http://localhost:8080`).
**When to use:** In dev/test Compose networks.
**Example:**
```yaml
environment:
  KC_HOSTNAME_STRICT: "false"
  KC_HOSTNAME_STRICT_HTTPS: "false"
  KC_HTTP_ENABLED: "true"
```
**Why:** Without this, Keycloak will reject `redirect_uri`s that originate from `localhost` because it expects the strict hostname.

### Pattern 3: Playwright in Docker
**What:** Running Playwright tests within a container to match CI environments exactly.
**When to use:** For reproducible E2E tests across OS boundaries.
**Example:**
```yaml
services:
  playwright:
    image: mcr.microsoft.com/playwright:v1.54.2-jammy
    profiles: ["browser"]
    ipc: host # Prevents Chromium crashes by sharing host SHM
    working_dir: /app
    volumes:
      - .:/app
    command: npm run admin-ui:smoke
```

### Anti-Patterns to Avoid
- **Hardcoded Container Names:** Do not use `container_name: relyra-demo`. Use Compose's default project prefixing to allow parallel checkouts.
- **Wait-For-It Scripts:** Rely on Docker Compose `depends_on` with `condition: service_healthy` instead of custom Bash wait loops.
- **Polluting Root mix.exs:** Keep `ci.demo_app` separate from `ci.security` to prevent accidental bypasses of the strict crypto corpus tests.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Health checking | `curl` loops in bash | Docker Compose `healthcheck` | Docker native, prevents containers from starting before dependencies are ready. |
| Test environment parity | Host-installed browsers | Official Playwright Docker image | Host browsers auto-update and cause flake; Docker pins the exact browser version. |

## Common Pitfalls

### Pitfall 1: Playwright Shared Memory Crashes
**What goes wrong:** Chromium crashes randomly during Playwright tests in Docker.
**Why it happens:** Docker defaults to a 64MB `/dev/shm` size, which Chromium easily exceeds during navigation.
**How to avoid:** Use `ipc: host` or `shm_size: '2gb'` on the Playwright container definition.

### Pitfall 2: Hollow Security Gates
**What goes wrong:** Adding `ci.demo_app` to a generic CI run or combining test invocations accidentally skips `mix ci.security` tests due to Mix task deduplication.
**Why it happens:** Mix deduplicates `mix test` runs in the same process.
**How to avoid:** Maintain isolated aliases using `cmd mix test` as currently designed in `mix.exs` and ensure `mix ci.demo_app` runs in its own pipeline/workflow.

## Code Examples

### `scripts/demo` Command Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-help}"

case "$COMMAND" in
  doctor)
    echo "Checking dependencies..."
    command -v docker >/dev/null || { echo "Docker missing"; exit 1; }
    ;;
  up)
    docker compose --profile core up -d
    ;;
  test)
    docker compose --profile browser run --rm playwright
    ;;
  # ...
esac
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Standalone `docker/keycloak/docker-compose.yml` | Top-level orchestrator with `--profile keycloak` | Keycloak 24+ | Simplifies DX to a single `docker compose` command from project root. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mcr.microsoft.com/playwright:v1.54.2-jammy` is the correct image | Standard Stack | Playwright will download binaries at runtime, slowing down the test run. |

## Open Questions (RESOLVED)

1. **GitHub Workflow CI integration**
   - What we know: `mix ci.demo_app` must be a standalone alias.
   - What's unclear: Should it be in `security-gates.yml` as a separate job, or a completely new workflow file?
   - Recommendation: Create a new isolated pipeline (`.github/workflows/demo-app-ci.yml`) to ensure clean separation of the demo app CI from the core security gates. (RESOLVED)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Playwright (`v1.54.2`) / ExUnit |
| Config file | `playwright.admin-ui.config.mjs` / `demo/ledger_loop/mix.exs` |
| Quick run command | `./scripts/demo test` |
| Full suite command | `mix ci.demo_app` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | Demo logic executes FakeIdP + Ecto correctly | e2e/integration | `mix ci.demo_app` | ❌ Wave 0 |
| IDP-03 | Keycloak proof via browser completes | e2e | `docker compose --profile keycloak --profile browser run playwright` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `.github/workflows/` update for `mix ci.demo_app`
- [ ] `scripts/demo` Bash script creation
- [ ] Root `docker-compose.yml`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keycloak (`26.0.7`) + Relyra strict defaults |
| V3 Session Management | yes | Host-app owned session via `SessionAdapter` |
| V4 Access Control | yes | LiveAdmin mount boundaries |
| V5 Input Validation | yes | Existing Phase 30 XML constraints |
| V6 Cryptography | yes | `:public_key.verify` invariants |

### Known Threat Patterns for Docker/Compose

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docker socket mount escalation | Elevation of Privilege | Do not mount `/var/run/docker.sock` in the Playwright or app containers. |
| Test-mode secret leakage | Information Disclosure | Ensure `demo/ledger_loop` test credentials are not used outside the demo context. |

## Sources

### Primary (HIGH confidence)
- Official Keycloak 26.0 Documentation - Hostname configuration
- Playwright Documentation - Docker integration (`ipc: host`)

### Secondary (MEDIUM confidence)
- N/A

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Keycloak and Playwright best practices.
- Architecture: HIGH - Docker Compose profiles perfectly solve the optional Keycloak requirement.
- Pitfalls: HIGH - `ipc: host` memory crashes and Mix hollow gates are well-documented issues in this stack.

**Research date:** 2026-06-12
**Valid until:** 2026-07-12
