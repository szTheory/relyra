---
phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
plan: 02
subsystem: infra
tags: [hex, mix, test_support, packaging]

requires: []
provides:
  - Dual-layer test_support exclusion from prod compile and Hex package
affects: [45]

tech-stack:
  added: []
  patterns: [explicit lib file whitelist for prod builds]

key-files:
  created: []
  modified: [mix.exs]

key-decisions:
  - "prod elixirc_paths uses explicit lib/**/*.ex file list because directory paths recurse into test_support"

requirements-completed: [TD-02]

duration: 5min
completed: 2026-05-27
---

# Phase 41 Plan 02 Summary

**Production compile and Hex package exclude TestSupport via explicit lib file lists**

## Accomplishments

- `prod_elixirc_paths/0` compiles 119 production `.ex` files (excludes test_support)
- `package_lib_files/0` whitelists lib paths without test_support for Hex tarball
- Verified: 0 TestSupport beams after `MIX_ENV=prod mix compile`; 0 test_support entries in hex.build tarball

## Task Commits

1. **Exclude test_support from prod compile paths** - `7315513`
2. **Tighten package.files whitelist** - (same commit — coupled mix.exs change)

## Deviations from Plan

Directory-based `elixirc_paths` still recursed into `lib/relyra/test_support/`; switched to explicit per-file paths (Mix accepts files in `elixirc_paths`).

---
*Phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening*
*Completed: 2026-05-27*
