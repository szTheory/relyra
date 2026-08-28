---
phase: 71-launcher-dx-banner
verified: 2026-08-27T15:22:32Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 71: Launcher DX & Banner Verification Report

**Phase Goal:** Launching the demo is self-documenting — one primary launcher prints a copy-pasteable URL/route map, surfaces the running fleet, and diagnoses common port/network problems.
**Verified:** 2026-08-27T15:22:32Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The Makefile is the canonical launcher and exposes the complete documented target inventory. | ✓ VERIFIED | The focused launcher contract executes `make help`, inspects target definitions, and dry-runs detached startup. |
| 2 | Every supported `scripts/demo` verb delegates to exactly one canonical Make target. | ✓ VERIFIED | PATH-isolated tests exercise all six verbs and reject unknown or extra arguments. |
| 3 | Detached startup prints one ordered, copy-pasteable route map only after Compose succeeds. | ✓ VERIFIED | Runtime fixtures prove the success banner and failure suppression; overridden host/port origins are exercised as data. |
| 4 | Reset and reseed preserve volumes, while nuke removes volumes only after explicit confirmation or `NUKE=1`. | ✓ VERIFIED | Runtime tests assert distinct Compose calls, refusal behavior, warning text, and the cold-rebuild receipt. |
| 5 | Fleet discovers every Traefik-enabled container globally and reports error, empty, partial, populated, ordered, and long-value states truthfully. | ✓ VERIFIED | Fake-Docker matrix covers every branch; the live fleet proxy lane passed its lifecycle and Chromium assertions. |
| 6 | Doctor reports Docker, Compose, all three ports, and the proxy network independently, with exact recovery guidance. | ✓ VERIFIED | Isolated `lsof`, `nc`, Docker, and Compose fixtures exercise healthy, occupied, unavailable, and missing-network states without short-circuiting. |
| 7 | Proxy startup is idempotent and browser opening selects a supported opener or prints a usable fallback. | ✓ VERIFIED | Runtime fixtures cover inspect-versus-create plus `open`, `xdg-open`, and no-opener branches. |
| 8 | Environment overrides cannot escape Make recipes and execute shell fragments. | ✓ VERIFIED | The injection regression passes quote/semicolon-bearing values and proves the sentinel command is never executed. |

**Score:** 8/8 truths verified; no behavior requires human judgment.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `Makefile` | Canonical launcher, banner, fleet, doctor, proxy, and opener | ✓ VERIFIED | Runtime contract and live Compose lanes passed. |
| `scripts/demo` | Thin compatibility adapter | ✓ VERIFIED | Exactly six literal verb mappings delegate with `exec make`. |
| `.env.example` | Commented optional demo configuration | ✓ VERIFIED | Contract rejects active assignments and requires demo-only warnings. |
| `test/docs/demo_guide_drift_test.exs` | Deterministic launcher acceptance | ✓ VERIFIED | 15 tests passed with warnings as errors. |
| `CLAUDE.md` | Project-wide automated acceptance policy | ✓ VERIFIED | Policy-as-code rejects required human/UAT gates in incomplete phases. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scripts/demo` | `Makefile` | six `exec make` mappings | ✓ WIRED | No duplicate Docker implementation remains. |
| `up-d` / `up-d-build` | route banner | successful Compose command followed by `url` | ✓ WIRED | Failure fixture proves the banner cannot mask startup failure. |
| `fleet` | running demos | global `traefik.enable=true` Docker label query | ✓ WIRED | Stable project/name sorting and missing-field normalization are covered. |
| `doctor` | host dependencies | independent Docker, Compose, port, and network probes | ✓ WIRED | All checks run before accumulated blocking status is returned. |
| mandatory CI | launcher contract | existing `mix qa` ExUnit discovery | ✓ WIRED | `mix qa` executed 782 tests with 0 failures, including the focused contract. |

### Behavioral Verification

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused launcher state matrix | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | 15 tests, 0 failures | ✓ PASS |
| Full quality gate | `mix qa` | 782 tests, 0 failures; 10 excluded | ✓ PASS |
| Security regression gate | `mix ci.security` | All isolated suites and audits passed | ✓ PASS |
| Fleet topology and browser path | `npm run demo:fleet-proxy` | Lifecycle and Chromium assertions passed | ✓ PASS |
| Real-IdP topology and browser path | `npm run demo:keycloak-proxy` | Clean isolated rerun passed 1/1 Chromium test with one durable receipt | ✓ PASS |

The initial Keycloak invocation encountered a transient truncated Redirect-binding request at Keycloak. Redacted diagnostics implicated no Phase 71 path; a clean isolated rerun passed. The successful recurring lane is the acceptance result, and the transient is retained here rather than hidden.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| DX-01 | 71-01 | ✓ SATISFIED | Canonical target inventory, compatibility delegation, startup behavior, data lifecycle, and safe environment handling all pass runtime contracts. |
| DX-02 | 71-01, 71-02 | ✓ SATISFIED | Ordered route map, global fleet discovery, independent doctor, proxy lifecycle, and opener fallback pass focused and live integration lanes. |

### Human Verification Required

None. Host, browser, Docker, failure, and destructive-confirmation states are represented by deterministic fixtures or recurring live integration lanes.

---

_Verified: 2026-08-27T15:22:32Z_
_Verifier: Codex_
