---
phase: 37-identity-mapping-and-provisioning-guide
verified: 2026-05-26T18:12:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 37: Identity Mapping and Provisioning Guide Verification Report

**Phase Goal:** An operator implementing JIT provisioning or attribute-to-user mapping has one authoritative guide covering the three canonical patterns and an explicit decision tree — and knows exactly where Relyra's responsibility ends and their application's begins.
**Verified:** 2026-05-26T18:12:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `guides/identity_mapping_and_provisioning.md` is published and covers all three mapping patterns: NameID-as-local-identifier, attribute-as-local-identifier, and JIT create-or-update. | ✓ VERIFIED | Guide exists with required sections at lines 121, 213, and 303 plus matching example sections at 150, 239, and 337. |
| 2 | A JIT decision tree helps operators choose between patterns based on their identity model; the `UserMapper` behaviour is fully documented with at least one complete implementation example per pattern. | ✓ VERIFIED | `## \`UserMapper\` behaviour` at line 24, complete examples with `defmodule`, `@behaviour`, and `def map_attributes/3` at lines 155-206, 244-296, 342-421, and JIT decision tree at lines 428-452. |
| 3 | The guide explicitly states the SCIM lifecycle non-goal, warns about JIT+SCIM simultaneous-use conflicts, and explains anchor stability guidance. | ✓ VERIFIED | Anchor stability warning at lines 104-115; SCIM non-goal and simultaneous-source warning at lines 454-478. |
| 4 | The new guide explains Relyra's trust boundary honestly: validated login data ends at a host-owned mapping/provisioning decision, not a library-owned user lifecycle. | ✓ VERIFIED | Overview and ownership sections state that Relyra stops at the verified login result and host code owns lookup/linking/create/update/authorization at lines 10-18, 51-58, and 64-86. |
| 5 | The public `Relyra.UserMapper` docs are tightened to describe the real ACS seam and verified login payload without changing runtime behavior. | ✓ VERIFIED | `lib/relyra/user_mapper.ex` moduledoc now documents `%Relyra.LoginResult{}` input, `login_result.principal` fields, and later session establishment at lines 2-24; ACS controller passes `login_result` and `login_result.connection` at `acs_controller.ex` lines 27-32. |
| 6 | Examples stay host-owned and code-truthful: the adapter receives validated login data, returns a mapped user shape, and does not pretend Relyra ships a user database or SCIM engine. | ✓ VERIFIED | All three examples pattern-match `%LoginResult{principal: %Principal{...}}` and return host-shaped maps while guide text reiterates that Relyra does not ship a user DB or SCIM engine at lines 36-62, 155-206, 244-296, and 342-421. |
| 7 | The new guide is discoverable from adjacent onboarding/operator docs, published in ExDoc extras, and `ci.docs` fails if the file is missing. | ✓ VERIFIED | README day-2 routing at lines 74-81, getting started follow-on link at lines 148-152, generic SAML cross-link at lines 185-187, ExDoc extras include the guide at `mix.exs` lines 107-129, and `ci.docs` includes `cmd test -f guides/identity_mapping_and_provisioning.md` at lines 144-153. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/identity_mapping_and_provisioning.md` | Authoritative guide with all required sections, examples, JIT decision tree, and SCIM boundary guidance | ✓ VERIFIED | Exists, substantive (`478` lines), no placeholder markers, all required headings present. |
| `lib/relyra/user_mapper.ex` | ExDoc-visible behaviour documentation aligned to the current mapper seam | ✓ VERIFIED | Exists, substantive, moduledoc matches actual ACS call shape, runtime callback and implementation unchanged. |
| `mix.exs` | ExDoc publication wiring and docs-lane presence gate for the new guide | ✓ VERIFIED | `extras` includes the guide and `ci.docs` checks for file presence before running docs-related tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `guides/identity_mapping_and_provisioning.md` | `lib/relyra/user_mapper.ex` | Behaviour contract explanation | ✓ VERIFIED | Guide documents `Relyra.UserMapper.map_attributes/3` and `%Relyra.LoginResult{principal: %Relyra.Principal{...}}`; `gsd-sdk query verify.key-links` passed for plan 01. |
| `guides/identity_mapping_and_provisioning.md` | `guides/recipes/generic_saml.md` | Anchor-stability alignment | ✓ VERIFIED | Guide links to the generic SAML runbook at lines 117-119; `gsd-sdk query verify.key-links` passed for plan 01. |
| `README.md` | `guides/identity_mapping_and_provisioning.md` | Day-2 identity mapping guide routing | ✓ VERIFIED | Manual line check confirms markdown link at README lines 78-81. `gsd-sdk query verify.key-links` reported a false negative here. |
| `guides/getting_started.md` | `guides/identity_mapping_and_provisioning.md` | Production follow-on reference | ✓ VERIFIED | Manual line check confirms markdown link at getting started lines 148-152. `gsd-sdk query verify.key-links` reported a false negative here. |
| `guides/recipes/generic_saml.md` | `guides/identity_mapping_and_provisioning.md` | Cross-link from NameID/mapping guidance | ✓ VERIFIED | Manual line check confirms markdown link at generic SAML lines 185-187. `gsd-sdk query verify.key-links` reported a false negative here. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `guides/identity_mapping_and_provisioning.md` | N/A | Static documentation artifact | N/A | N/A |
| `lib/relyra/user_mapper.ex` | N/A | API/moduledoc artifact, not a rendered data surface | N/A | N/A |
| `mix.exs` | N/A | Build/docs config artifact | N/A | N/A |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs lane keeps the guide present and the docs surface healthy | `mix ci.docs` | Passed when rerun sequentially in this verification run; treated as authoritative because parallel launch is known-invalid in this repo due to test DB bootstrap collision. | ✓ PASS |
| Standard suite still passes after docs-lane change | `mix test --warnings-as-errors` | Passed when rerun sequentially in this verification run with `666` tests, `0` failures. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DOCS-03` | `37-01-PLAN.md`, `37-02-PLAN.md` | Identity mapping and provisioning guide published with three mapping patterns, JIT decision tree, `UserMapper` examples, JIT+SCIM conflict warning, and explicit SCIM non-goal statement | ✓ SATISFIED | Guide sections and examples at lines 24-62, 121-478; discoverability and CI publication wiring in README/getting started/generic SAML plus `mix.exs` lines 107-153. |

### Anti-Patterns Found

No blocker, warning, or info-level stub patterns were found in the scanned phase files (`guides/identity_mapping_and_provisioning.md`, `lib/relyra/user_mapper.ex`, `README.md`, `guides/getting_started.md`, `guides/recipes/generic_saml.md`, `mix.exs`).

### Human Verification Required

None. This phase's must-haves are documentation content and docs-lane wiring, and they were verified directly from the codebase plus the recorded sequential command results.

### Gaps Summary

No gaps found. Phase 37 achieves the roadmap goal and satisfies `DOCS-03`.

---

_Verified: 2026-05-26T18:12:00Z_  
_Verifier: Claude (gsd-verifier)_
