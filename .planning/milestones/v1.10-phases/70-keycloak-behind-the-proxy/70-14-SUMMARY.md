---
phase: 70-keycloak-behind-the-proxy
plan: "14"
subsystem: demo-browser-acceptance
tags: [playwright, fake-idp, login-trace, accessibility, ci]
requires:
  - 70-13
provides:
  - deterministic credential-safe failed Login Trace browser gate
  - recurring trace-visual execution in demo-app E2E CI
affects:
  - demo/ledger_loop
  - Relyra.LiveAdmin.ConnectionTraceLive
  - demo-app-e2e workflow
tech-stack:
  added: [Playwright trace-visual project]
  patterns: [ephemeral Basic auth, validated temporary output cleanup, native details keyboard checks]
key-files:
  created:
    - scripts/test_trace_visual_e2e.sh
    - playwright.trace-visual.config.mjs
    - demo/ledger_loop/test/browser/trace_visual.spec.ts
  modified:
    - package.json
    - lib/relyra/live_admin/connection_trace_live.ex
    - .github/workflows/demo-app-e2e.yml
decisions:
  - "The trace-visual lane uses the existing deterministic FakeIdP tamper seam rather than a second Keycloak failure path."
  - "Basic credentials are generated per invocation, retained only in environment/memory, and all validated Playwright output is removed on every process exit."
  - "The existing demo E2E job runs the new lane after FakeIdP without an additional service, dependency installation, secret, or artifact upload."
metrics:
  tasks_completed: 2
  files_modified: 7
  completed_date: 2026-08-26
  status: complete
---

# Phase 70 Plan 14: Trace Visual Browser Gate Summary

The recurring Chromium gate proves a real tampered FakeIdP ACS rejection, safe operator recovery, keyboard-operable Login Trace details, narrow evidence access, and long safe values without retaining credentials or browser artifacts.

## Completed Work

- Added a dedicated harness that generates an ephemeral admin password, enables only the opt-in visual fixture, owns a private `relyra-trace-visual-playwright.*` directory, and validates/removes it on normal, failed, and signal exits.
- Added a self-booting attachment-free Playwright project and one focused Chromium test that proves HTTP 400 + `digest_mismatch`, no workspace/receipt success, Basic-auth trace recovery, native `<details>` keyboard toggle, Back navigation, horizontal evidence access at 360px, and long fixture values.
- Corrected Login Trace layout so long rendered causes cannot widen the page; the labelled evidence region remains the intentional horizontal-scroll surface.
- Added the visual gate to the existing FakeIdP demo E2E workflow job after its ordinary browser lane, with no added service, dependency setup, secret, or artifact upload.

## Verification

- `bash -n scripts/test_trace_visual_e2e.sh` — passed.
- `npm run demo:trace-visual -- --list` — listed exactly one Chromium trace-visual test.
- `npm run demo:trace-visual` — passed: 1/1 Chromium test; a post-run temporary-directory scan confirmed cleanup.
- `mix test test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors` — passed: 6 tests, 0 failures.
- `mix format --check-formatted` — passed.
- `npm run demo:fake-idp` — passed: 2/2 Chromium tests, including the existing tampered `digest_mismatch` rejection.
- `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/demo-app-e2e.yml")'` — `workflow yaml parsed`; the project Ruby shim has no configured Ruby version, while the system Ruby parsed the same workflow successfully.

## TDD Gate Compliance

- RED: `e106e7a` — added the browser contract; test discovery failed until the dedicated config existed.
- GREEN: `87708d6` — added the harness/configuration and passed the real browser journey.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Contained Login Trace page overflow caused by long failure evidence.
- **Found during:** Task 1 live narrow-viewport Chromium verification.
- **Issue:** The long safe cause widened the page instead of restricting horizontal scrolling to the labelled evidence region.
- **Fix:** Added box sizing, shrink constraints, safe word wrapping, and parent containment while preserving the focusable evidence region's horizontal scrolling.
- **Files modified:** `lib/relyra/live_admin/connection_trace_live.ex`
- **Commit:** `87708d6`

## Known Stubs

None.

## Tracking Notes

`.planning/STATE.md` and `70-VERIFICATION.md` were already modified by concurrent work before this plan started. They were preserved and not included in this plan's commits.

## Self-Check: PASSED

All seven scoped implementation/workflow files exist, and commits `e106e7a`, `87708d6`, and `9c5b319` are present in git history.
