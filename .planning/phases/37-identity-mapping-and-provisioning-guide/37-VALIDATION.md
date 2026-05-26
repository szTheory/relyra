---
phase: 37
slug: identity-mapping-and-provisioning-guide
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-26
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a documentation-only phase, but the deliverable is still a public contract:
> bad identity-anchor or provisioning guidance can mislead adopters even when no
> runtime code changes land.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `rg`, Mix aliases, ExDoc config checks |
| **Quick run command** | `rg -n '^## Overview$|^## Relyra owns / Host owns$|^## Pattern 1: NameID as local identifier$|^## Pattern 2: Attribute as local identifier$|^## Pattern 3: JIT create or update$|^## JIT decision tree$|^## SCIM is a non-goal$' guides/identity_mapping_and_provisioning.md` |
| **Full suite command** | `mix ci.docs && mix test --warnings-as-errors` |
| **Estimated runtime** | quick < 5s; full suite depends on test lane runtime |

---

## Sampling Rate

- **After every task commit:** run the task-local `rg` checks from the owning plan.
- **After every plan wave:** run the relevant docs publication/gate checks plus the quick guide-content grep.
- **Before `/gsd:verify-work`:** `mix ci.docs && mix test --warnings-as-errors` must be green.
- **Max feedback latency:** quick content and config checks should stay under a few seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-T1 | 01 | 1 | DOCS-03 | T-37-01 / T-37-03 | Core guide exists with the required ownership, pattern, JIT, and SCIM sections | docs grep | `rg -n '^## Overview$|^## Relyra owns / Host owns$|^## Choose your identity anchor first$|^## Pattern 1: NameID as local identifier$|^## Pattern 2: Attribute as local identifier$|^## Pattern 3: JIT create or update$|^## JIT decision tree$|^## SCIM is a non-goal$' guides/identity_mapping_and_provisioning.md && rg -n 'NameID|attribute|JIT|SCIM|UserMapper|map_attributes' guides/identity_mapping_and_provisioning.md` | ⬜ new | ⬜ pending |
| 37-T2 | 01 | 1 | DOCS-03 | T-37-01 / T-37-03 | `Relyra.UserMapper` code docs describe the real mapper seam without changing runtime | docs grep | `rg -n 'LoginResult|login_result|map_attributes|SessionAdapter|verified' lib/relyra/user_mapper.ex` | ✅ extend existing | ⬜ pending |
| 37-T3 | 02 | 2 | DOCS-03 | T-37-04 | Guide includes complete `UserMapper` behaviour section and one complete adapter-shaped example per required pattern, written against `%Relyra.LoginResult{principal: %Relyra.Principal{...}}` | docs grep | `rg -n '^## `UserMapper` behaviour$|^## Example: NameID as local identifier$|^## Example: Attribute as local identifier$|^## Example: JIT create or update$' guides/identity_mapping_and_provisioning.md && rg -n 'Relyra.LoginResult|Relyra.Principal|principal\.name_id|principal\.name_id_format|principal\.attributes|defmodule|@behaviour Relyra.UserMapper|def map_attributes' guides/identity_mapping_and_provisioning.md` | ⬜ new | ⬜ pending |
| 37-T4 | 02 | 2 | DOCS-03 | T-37-05 / T-37-06 | Guide is published in ExDoc extras, linked from adjacent docs, and fail-closed in `ci.docs` | config + docs grep | `rg -n 'guides/identity_mapping_and_provisioning\\.md' mix.exs README.md guides/getting_started.md guides/recipes/generic_saml.md && mix ci.docs && mix test --warnings-as-errors` | ✅ extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None beyond the existing docs/test infrastructure. This phase reuses `mix ci.docs`, ExDoc extras, and grep-based content verification already established in the repo.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide prose matches actual host-ownership posture | DOCS-03 | Automated checks can prove section presence and links, but not whether the prose accidentally overstates SCIM or provisioning scope | Read the final guide sections `Relyra owns / Host owns`, `Pattern 3: JIT create or update`, and `SCIM is a non-goal`; confirm they state that Relyra stops at verified login + mapping seams and that user lifecycle stays host-owned |
| Example completeness | DOCS-03 | Grep can prove adapter-shaped examples exist, but not that each example is coherent and pattern-specific | Read each example section and confirm it contains a complete module or helper flow that clearly demonstrates the named pattern instead of repeating the same skeleton with renamed comments |

---

## Validation Sign-Off

- [x] All planned tasks have automated verification steps
- [x] Sampling continuity: no plan wave is left without automated feedback
- [x] No watch-mode or interactive-only verification
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] Execution evidence still pending
