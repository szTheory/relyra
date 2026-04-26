---
phase: 06-delivery-hardening-and-adoption-surface
plan: 01
subsystem: adoption-surface
tags: [provider-presets, security-corpus, testsupport, installer, docs]
requires:
  - phase: 06-01
    provides: provider presets, TestSupport DX, installer scaffold, release hardening, and hardened docs
provides:
  - provider presets with safe defaults and admin label translation
  - TestSupport/FakeIdP helpers for adopter integration tests
  - a minimal mix relyra.install scaffold and golden-path coverage
  - release metadata, parity verification, and release prerequisites
  - scope-first README, SECURITY, and conventions docs
affects: [phase-06-completion, requirement-tracking]
tech-stack:
  added: [Mix.Task, Phoenix.Router/Controller test scaffolding]
  patterns:
    - module-per-provider presets with keyword-merge defaults
    - test helper macro wrappers with typed login/error assertions
    - installer scaffold writing sentinel-guarded config
key-files:
  created:
    - .planning/phases/06-delivery-hardening-and-adoption-surface/06-01-SUMMARY.md
  modified:
    - CHANGELOG.md
    - SECURITY.md
    - CONVENTIONS.md
    - .release-please-config.json
    - .release-please-manifest.json
    - .github/workflows/release-parity.yml
    - guides/getting_started.md
    - guides/recipes/okta.md
    - guides/recipes/entra.md
    - guides/recipes/google_workspace.md
    - lib/relyra/provider.ex
    - lib/relyra/provider/okta.ex
    - lib/relyra/provider/entra.ex
    - lib/relyra/provider/google_workspace.ex
    - lib/relyra/test_support.ex
    - lib/relyra/test_support/fake_idp.ex
    - lib/mix/tasks/relyra.install.ex
    - test/provider/provider_test.exs
    - test/mix/relyra_install_test.exs
    - test/test_support_demo_test.exs
    - test/release/release_hardening_test.exs
key-decisions:
  - "Use a module-per-provider preset registry with keyword defaults, label translation, and footgun checks instead of struct rigidity."
  - "Keep the installer hand-rolled and sentinel-based rather than adopting Igniter for a small v0.1 scaffold."
  - "Treat FakeIdP as test-only helper infrastructure and document the security boundary explicitly in SECURITY.md and README.md."
  - "Use Keep a Changelog plus release-please metadata and a release-parity lane to keep the tagged release surface honest."
requirements-completed: [OBS-03, OBS-05, PHX-04, SEC-09, GATE-04]
duration: 30min
completed: 2026-04-25
---

# Phase 06 Plan 01: Delivery Hardening and Adoption Surface Summary

Relyra now ships the v0.1 adoption surface: provider presets, TestSupport/FakeIdP helpers, a minimal installer scaffold, release discipline artifacts, and scope-first docs that point adopters at the recipes, threat model, and release prerequisites.

## Performance

- **Duration:** 30 min
- **Completed:** 2026-04-25
- **Tasks:** 1 logical chunk
- **Files modified:** 17 tracked files in the committed chunk

## Accomplishments

- Added `Relyra.Provider` plus Okta, Entra, and Google Workspace presets with keyword-merge defaults, admin label translation, footgun checks, and metadata-URL bootstrap.
- Shipped `Relyra.TestSupport` and `Relyra.TestSupport.FakeIdP` for adopter tests, plus a live demo test showing the helper surface end-to-end.
- Added `mix relyra.install` scaffolding and a test that verifies the generated host-app files and sentinel config block.
- Rewrote the top-level README and added SECURITY/CONVENTIONS docs to tighten scope and security expectations.
- Added `CHANGELOG.md`, release-please metadata, a release-parity workflow, and explicit release prerequisites for namespace/domain and Keycloak pin checks.

## Verification Results

- `mix test test/provider/provider_test.exs test/mix/relyra_install_test.exs test/test_support_demo_test.exs test/security/signature_policy_test.exs test/security/signed_node_binding_test.exs`
- `mix test test/release/release_hardening_test.exs`
- `mix test`

All passed.

## Deviations from Plan

- None material. The phase delivered the requested surface and kept the scope bounded.

## Self-Check

PASSED
