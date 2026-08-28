---
phase: 71
slug: launcher-dx-banner
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-27
updated: 2026-08-27
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
- **Before phase verification:** Run `mix qa`, `mix ci.security`, and the owned fleet/Keycloak Docker integration lanes.
- **Max feedback latency:** 10 seconds for the focused static launcher contract.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 1 | DX-01 | T-71-01 | Make recipes preserve quoted variables and do not evaluate environment-provided command fragments. | runtime contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extended | ✅ green |
| 71-01-02 | 01 | 1 | DX-01, DX-02 | T-71-02 | Destructive targets remain distinct and visibly scoped; compatibility verbs delegate without alternate implementations. | runtime contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extended | ✅ green |
| 71-02-01 | 02 | 2 | DX-02 | — | Banner, fleet, doctor, proxy, and opener states are exercised with isolated command fixtures and no credential output. | runtime contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extended | ✅ green |
| 71-02-02 | 02 | 2 | DX-02 | — | Existing fleet and Keycloak proxy topology remains reachable without changing router or `lib/` code. | Docker/Chromium integration | `npm run demo:fleet-proxy && npm run demo:keycloak-proxy` | ✅ existing | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Extend `test/docs/demo_guide_drift_test.exs` so the Make target inventory is canonical and the six `scripts/demo` compatibility verbs are checked independently.
- [x] Add runtime assertions for route-banner paths and origins, exact Compose shapes, Traefik-label fleet discovery, doctor port/network remediation, and opener fallbacks.

The validation architecture is complete: every task has deterministic focused or integration evidence, the focused runtime contract is owned by mandatory CI, and no incomplete phase may introduce a human/UAT completion gate.

---

## Automated Environment Verification

Host-specific launcher states are modeled with PATH-isolated executable fixtures in
`test/docs/demo_guide_drift_test.exs`; CI never opens a real browser, probes live host
ports, or depends on a local Docker daemon for the focused contract.

- Fake `open` and `xdg-open` commands prove opener precedence and fallback copy.
- Fake `lsof` and `nc` commands prove busy, free, fallback, and unavailable-probe states.
- Fake `docker` output proves fleet and network success, empty, partial, and error states.
- Every fixture retains full values and exact recovery commands, replacing subjective UAT.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — plan evidence: every task in 71-01 and 71-02 contains an `<automated>` command, with 71-01 explicitly extending the focused static contract.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10 seconds for the focused contract
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated — 2026-08-27

## Validation Audit — 2026-08-27

| Result | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Fresh focused evidence passed:

- `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` — 27 tests, 0 failures.
- `bash -n scripts/demo` — launcher syntax is valid.
- `make help`, `make -n up-d`, `make -n doctor`, `make -n proxy`, and `make -n open` — public recipes resolve without execution errors.
- `PORT=4100 RELYRA_HOST=alt.relyra.localhost make url` — loopback output remains `http://localhost:4100`.
