---
phase: 35-signed-authnrequests-adfs-preset
plan: 09
subsystem: docs
tags: [docs, adfs, operators]
requires:
  - phase: 35-04
    provides: ADFS provider preset
provides:
  - ADFS operator runbook
  - docs-lane presence gate for the runbook
affects: [docs, onboarding, ci]
key-files:
  created:
    - guides/recipes/adfs.md
  modified:
    - mix.exs
    - README.md
    - guides/getting_started.md
requirements-completed: [AUTHN-04]
completed: 2026-05-26
---

# Phase 35 Plan 09 Summary

Published the ADFS-specific runbook and made it fail closed in the docs lane.

## Accomplishments

- Added `guides/recipes/adfs.md` covering the preset defaults, PowerShell trust commands, claim-rule guidance, redirect-signing interop notes, and troubleshooting.
- Wired the runbook into docs publication and the `ci.docs` file-presence gate.
- Routed adjacent onboarding docs to the ADFS recipe so signed-request adopters land on the correct operator guidance.

