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

The validation architecture is plan-complete: both plans assign every task an executable focused or integration verification command, and Plan 71-01 owns the missing static-contract coverage. Execution sign-off remains pending until that plan creates or extends the assertions above and the commands produce evidence; therefore `nyquist_compliant` and `wave_0_complete` remain `false`.

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
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10 seconds for the focused contract
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
