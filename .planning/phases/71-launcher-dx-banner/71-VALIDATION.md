---
phase: 71
slug: launcher-dx-banner
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-27
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for launcher feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus existing Docker/Chromium integration harnesses |
| **Config file** | `mix.exs`, `package.json` |
| **Quick run command** | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | Focused static contract: under 10 seconds; full suite and Docker lanes vary by host |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` plus the task's non-mutating `make help` or `make -n` check.
- **After every plan wave:** Run `mix test --warnings-as-errors` and `mix format --check-formatted`.
- **Before `$gsd-verify-work`:** Run `mix qa` and `mix ci.security`; run the owned Docker integration lanes when Docker is available.
- **Max feedback latency:** 10 seconds for the focused static launcher contract.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 1 | DX-01 | T-71-01 | Make recipes preserve quoted variables and do not evaluate environment-provided command fragments. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 71-01-02 | 01 | 1 | DX-01, DX-02 | T-71-02 | Destructive targets remain distinct and visibly scoped; compatibility verbs delegate without alternate implementations. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 71-02-01 | 02 | 2 | DX-02 | — | Banner data contains no credential values and distinguishes browser origins from service-DNS probes. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 71-02-02 | 02 | 2 | DX-02 | — | Existing fleet and Keycloak proxy topology remains reachable without changing router or `lib/` code. | Docker/Chromium integration | `npm run demo:fleet-proxy && npm run demo:keycloak-proxy` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend or replace `test/docs/demo_guide_drift_test.exs` so the Make target inventory is canonical and the six `scripts/demo` compatibility verbs are checked independently.
- [ ] Add static assertions for the route-banner paths and origins, exact solo/fleet Compose shapes, Traefik-label fleet discovery, and doctor port/network remediation tokens.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OS browser opener behavior | DX-02 | `open`/`xdg-open` availability is host-specific and should not run in CI. | Run `make open` on a supported workstation and confirm it opens the printed application origin or reports a copy-pasteable URL with a corrective message. |
| Port-owner detail quality | DX-02 | This workstation has neither `lsof` nor `nc`; owner text varies by OS utility. | Occupy one required port, run `make doctor`, and confirm it names the port and prints a concrete corrective command; repeat without optional probe tools to confirm the explicit unavailable-probe branch. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10 seconds for the focused contract
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
