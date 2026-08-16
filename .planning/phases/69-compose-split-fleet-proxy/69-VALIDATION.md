---
phase: 69
slug: compose-split-fleet-proxy
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 69-01-01 | 01 | 1 | FLEET-01 | T-69-01 / T-69-03 | App binds to loopback; Postgres has no host-published port | config render | `docker compose config` plus assertions for `127.0.0.1`, unprofiled core services, and absent `db.ports` | ❌ W0 receipt | ⬜ pending |
| 69-02-01 | 02 | 2 | FLEET-02 | T-69-01 / T-69-04 | Fleet overlay publishes no app/db ports and routes only through unique `relyra-*` labels | config render + smoke | `docker compose -f docker-compose.yml -f docker-compose.proxy.yml config` plus `curl -I http://relyra.localhost` | ❌ W0 receipt | ⬜ pending |
| 69-03-01 | 03 | 2 | FLEET-03 | T-69-02 | LiveView accepts only the explicit solo/proxy origins and endpoint URL matches the selected public host | config + browser integration | `mix format --check-formatted demo/ledger_loop/config/*.exs` plus browser receipts for both hosts | ❌ W0 receipt | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Record a static solo Compose receipt proving bare `docker compose up` selects `db` and `demo_app`, publishes only `127.0.0.1:<port>:4000`, and publishes no Postgres port.
- [ ] Record a static fleet Compose receipt proving `demo_app` and `db` publish no host ports, `demo_app` joins external `proxy`, and router/service identifiers use the `relyra-*` prefix.
- [ ] Record manual runtime receipts for `http://localhost:<port>` and `http://relyra.localhost`, including a working LiveView WebSocket.

No new test framework is required; Phase 69 uses deterministic rendered-config assertions and documented runtime receipts because the scoped behavior crosses Docker networking, Traefik, and a browser WebSocket.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Solo stack starts from plain `docker compose up` and serves the operator UI | FLEET-01 | Requires Docker lifecycle and browser access | Start the stack without profiles or explicit overlays; open the loopback URL; confirm the page loads and no Postgres host port appears in `docker compose ps`. |
| Shared proxy routes two sibling demos without port contention | FLEET-02 | Requires the external network, Traefik, and a second checkout/demo | Run `make proxy`, start Relyra with the fleet overlay, start one sibling demo on the same `proxy` network, and request both `*.localhost` hosts. |
| LiveView WebSocket connects for solo and proxy public hosts | FLEET-03 | Browser WebSocket behavior is not proven by static endpoint config | Load the operator UI at each public host and verify the LiveView connection remains established without origin errors. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30 seconds for automated checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
