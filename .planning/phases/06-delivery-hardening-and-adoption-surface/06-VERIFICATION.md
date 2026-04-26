---
phase: 06-delivery-hardening-and-adoption-surface
verified: 2026-04-25T21:47:07Z
status: passed
score: 6/6
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "OSS release discipline and release-time prerequisites are complete"
  gaps_remaining: []
  regressions: []
---

# Phase 6: Delivery Hardening and Adoption Surface Verification Report

**Phase Goal:** Complete the shippable v0.1 adoption surface with docs, install path, fixtures, and release discipline.
**Verified:** 2026-04-25T21:47:07Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Provider recipes and preset surface are usable | ✓ VERIFIED | `lib/relyra/provider.ex`, `lib/relyra/provider/{okta,entra,google_workspace}.ex`, and `guides/recipes/*.md` define the registry, safe defaults, label translation, and concrete config examples. |
| 2 | Getting Started gives adopters a real-IdP test path | ✓ VERIFIED | `guides/getting_started.md:3-16` points to `Relyra.TestSupport.FakeIdP`, Mock SAML, and local Keycloak guidance. |
| 3 | `mix relyra.install` scaffolds the host-app integration surface | ✓ VERIFIED | `lib/mix/tasks/relyra.install.ex` generates resolver/user-mapper stubs and sentinel config; `test/mix/relyra_install_test.exs` checks the generated tree. |
| 4 | TestSupport/FakeIdP provide practical test-run experience | ✓ VERIFIED | `lib/relyra/test_support.ex`, `lib/relyra/test_support/fake_idp.ex`, and `test/test_support_demo_test.exs` expose helper macros, response builders, and a working demo flow. |
| 5 | Security regression corpus is wired into CI | ✓ VERIFIED | `test/fixtures/security/*/manifest.json`, `test/security/xml/corpus_security_test.exs`, `mix.exs` `ci.security`, and `.github/workflows/security-gates.yml` all reference the corpus and gates. |
| 6 | OSS release discipline and release-time prerequisites are complete | ✓ VERIFIED | `CHANGELOG.md`, `.release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-parity.yml`, `SECURITY.md`, and `test/release/release_hardening_test.exs` provide the release surface and prerequisite checks. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/relyra/provider.ex` | Provider registry + API surface | VERIFIED | Registry, defaults merge, label translation, footgun checks, and guide URLs are present. |
| `lib/relyra/provider/okta.ex` | Okta preset | VERIFIED | Safe defaults and footgun checks exist. |
| `lib/relyra/provider/entra.ex` | Entra preset | VERIFIED | Safe defaults and footgun checks exist. |
| `lib/relyra/provider/google_workspace.ex` | Google Workspace preset | VERIFIED | Safe defaults and footgun checks exist. |
| `guides/recipes/*.md` | Provider recipes | VERIFIED | All three recipes are present and aligned with the presets. |
| `guides/getting_started.md` | Real-IdP test path | VERIFIED | Points to FakeIdP, Mock SAML, and local Keycloak guidance. |
| `lib/relyra/test_support.ex` | TestSupport helper macro + assertions | VERIFIED | Helper macro, dispatch helpers, and assertion macros exist. |
| `lib/relyra/test_support/fake_idp.ex` | Fake IdP helper | VERIFIED | In-process builder/signing-fixture helpers and persistent-term keypair cache exist. |
| `lib/mix/tasks/relyra.install.ex` | Installer scaffold | VERIFIED | Generates integration stubs and config sentinels. |
| `test/fixtures/security/*/manifest.json` | Permanent adversarial corpus | VERIFIED | XML, signature, protocol, and relay-state manifests exist. |
| `.github/workflows/security-gates.yml` | Security CI lane | VERIFIED | Runs qa/fast/security/integration gates. |
| `CHANGELOG.md`, release-please config/manifest | Release discipline | VERIFIED | Root changelog and release-please metadata exist. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Relyra.Provider` | provider preset modules | explicit registry | WIRED | `@presets` maps `:okta`, `:entra`, and `:google_workspace` to concrete modules. |
| `guides/getting_started.md` | FakeIdP / Keycloak path | prose guide | WIRED | Docs point adopters to FakeIdP, Mock SAML, and local Keycloak. |
| `Mix.Tasks.Relyra.Install` | generated host-app files | `File.write!` + sentinel config | WIRED | Test proves the generated files and config block are created. |
| `security_corpus` manifests | security corpus tests | tagged ExUnit tests + `ci.security` | WIRED | Corpus manifests are consumed by `test/security/xml/corpus_security_test.exs` and aliased in `mix.exs`. |
| `test/release/release_hardening_test.exs` | release parity workflow | file existence + content assertions | WIRED | Test checks `CHANGELOG.md`, release-please metadata, `SECURITY.md`, and `.github/workflows/release-parity.yml`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `test/test_support_demo_test.exs` | `current_user` | FakeIdP-built SAMLResponse → demo ACS controller assigns `current_user` → `assert_saml_login` / `saml_login` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Release hardening lane passes | `mix test test/release/release_hardening_test.exs --warnings-as-errors` | `4 tests, 0 failures` | ✓ PASS |
| Phase 6 surface smoke tests pass | `mix test test/provider/provider_test.exs test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors` | `9 tests, 0 failures` | ✓ PASS |
| Security corpus smoke test passes | `mix test test/security/xml/corpus_security_test.exs --warnings-as-errors` | `3 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| `OBS-03` | Phase 6 / 06-01 | Provider recipes + Keycloak local integration path | SATISFIED | Three provider recipes exist; getting-started docs point at FakeIdP / Mock SAML / Keycloak. |
| `PHX-04` | Phase 6 / 06-02 | `mix relyra.install` minimal scaffolding | SATISFIED | Installer test and generated files confirm the scaffold. |
| `SEC-09` | Phase 6 / 06-03 | Permanent adversarial fixture corpus in CI | SATISFIED | Corpus manifests, corpus tests, alias, and workflow are wired. |
| `OBS-05` | Phase 6 / 06-04 | Release discipline (Release Please, changelog, parity verification) | SATISFIED | Root changelog, release-please metadata, parity workflow, and release test all exist. |
| `GATE-04` | Phase 6 / 06-04 | Release-time external prerequisites | SATISFIED | SECURITY.md documents domain/namespace and Keycloak pin checks before tagging/publishing. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `test/security/xml/seam_contract_test.exs` | 29 | placeholder in test name | Info | Test-only wording; not a production stub. |
| `test/security/xml/integration_smoke_test.exs` | 5 | placeholder in test name | Info | Test-only wording; not a production stub. |

### Human Verification Required

None.

### Gaps Summary

None blocking. The adoption surface, installer, security corpus, and release discipline are present and wired.

---

_Verified: 2026-04-25T21:47:07Z_
_Verifier: the agent (gsd-verifier)_
