---
phase: 69
slug: compose-split-fleet-proxy
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-16
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix plus Docker Compose CLI receipts |
| **Config file** | `mix.exs`; `docker-compose.yml` and its solo/fleet overlays |
| **Quick run command** | `docker compose config && docker compose -f docker-compose.yml -f docker-compose.proxy.yml config` |
| **Full suite command** | `mix qa && mix test --warnings-as-errors && mix ci.security && mix format --check-formatted` |
| **Estimated runtime** | ~180 seconds, excluding interactive Docker/browser receipts |

---

## Sampling Rate

- **After every task commit:** Render the relevant Compose configuration and run `mix format --check-formatted demo/ledger_loop/config/*.exs` when Elixir config changed.
- **After every plan wave:** Run both Compose render commands and the plan's scoped assertions.
- **Before `$gsd-verify-work`:** Run the full suite, then complete both solo and fleet runtime receipts.
- **Max feedback latency:** 30 seconds for static Compose/config checks; runtime receipts are phase-gate checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01-01 | 01 | 1 | FLEET-01 | T-69-01 / T-69-03 | Container listens on its network while only the app is host-published on `127.0.0.1`; Postgres has no host publication | config render | `docker compose config --format json` plus the Plan 69-01 Task 1 `jq` assertions for unprofiled services, loopback app publication, and absent `db.ports` | ✅ inline plan gate | ⬜ pending |
| 69-01-02 | 01 | 1 | FLEET-03 | T-69-02 | Phoenix retains the container-wide bind needed by Docker/Traefik, uses the selected public URL, and accepts only the explicit origin list | config evaluation | `cd demo/ledger_loop && mix format --check-formatted config/runtime.exs config/dev.exs && MIX_ENV=dev PHX_HOST=relyra.localhost PHX_SCHEME=http PHX_PORT=80 DEMO_CHECK_ORIGINS='//localhost,//relyra.localhost,//*.relyra.localhost' mix run --no-start -e '…'` using the Plan 69-01 Task 2 endpoint assertions | ✅ inline plan gate | ⬜ pending |
| 69-02-01 | 02 | 2 | FLEET-02 | T-69-06 / T-69-07 / T-69-09 | Neutral Traefik publishes web/dashboard only on loopback, disables implicit exposure, and uses the external network | config render | `docker compose -f docker/traefik/compose.yml config --format json` plus the Plan 69-02 Task 1 image, loopback-port, and external-network assertions | ✅ inline plan gate | ⬜ pending |
| 69-02-02 | 02 | 2 | FLEET-02 / FLEET-03 | T-69-04 / T-69-08 | Fleet publishes no app/db ports, attaches only the app to `proxy`, and wires namespaced routing plus endpoint env | config render + smoke | `docker compose -f docker-compose.yml -f docker-compose.proxy.yml config --format json` plus the Plan 69-02 Task 2 port, network, label, and environment assertions | ✅ inline plan gate | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No test scaffold is missing: all four implementation tasks carry a deterministic inline automated gate, so Wave 0 is complete. Runtime Docker and browser receipts remain phase-gate verification performed after implementation; they are not substitutes for the per-task automated commands.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Solo stack starts from plain `docker compose up` and serves the operator UI | FLEET-01 | Requires Docker lifecycle and browser access | Start the stack without profiles or explicit overlays; open the loopback URL; confirm the page loads and no Postgres host port appears in `docker compose ps`. |
| Shared proxy routes two sibling demos without port contention | FLEET-02 | Requires the external network, Traefik, and a second checkout/demo | Run `docker network inspect proxy >/dev/null 2>&1 || docker network create proxy`, then `docker compose -f docker/traefik/compose.yml up -d`; start Relyra with the fleet overlay, start one sibling demo on the same `proxy` network, and request both `*.localhost` hosts. |
| LiveView WebSocket connects for solo and proxy public hosts | FLEET-03 | Browser WebSocket behavior is not proven by static endpoint config | Load the operator UI at each public host and verify the LiveView connection remains established without origin errors. |

---

## Validation Sign-Off

- [x] All four real tasks have an `<automated>` verification command
- [x] Sampling continuity: every task has an automated gate
- [x] Wave 0 covers all MISSING references (none; inline gates exist for every task)
- [x] No watch-mode flags
- [x] Feedback latency < 30 seconds for static/config automated checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved for execution; runtime and browser receipts remain pending phase sign-off
