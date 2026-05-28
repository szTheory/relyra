---
phase: 47-onboarding-truth-getting-started-production-ecto-path
status: passed
verified: 2026-05-27
score: 12/12
requirements:
  - ADOPT-01
  - ADOPT-02
---

# Phase 47 Verification

**Goal:** A new adopter follows Getting Started from install to first verified browser login using the TestSupport macro pattern, then can find a single authoritative production Ecto deployment path without reading source.

## Must-Have Verification

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Getting Started §3 teaches TestSupport macro round-trip with stub ACS | PASS | `guides/getting_started.md` §3 contains `setup_saml_connection`, `post_saml_response`, `assert_saml_login`, stub router/controller |
| 2 | Canonical copy-paste points to test_support_demo_test.exs | PASS | Reference sentence in §3 |
| 3 | Manual builder demoted to appendix | PASS | `## Appendix: Advanced manual response construction` after §5 |
| 4 | overview Day-1 step 2 aligned with macro path | PASS | `guides/overview.md` step 2 links to Getting Started §3 |
| 5 | Stub ACS contrasted with production saml_routes | PASS | Prose in §3 distinguishes stub vs ACSController |
| 6 | production_ecto_path.md is authoritative Ecto guide | PASS | `guides/production_ecto_path.md` (235 lines) |
| 7 | Guide documents host store DDL | PASS | §2 request_intents/replay_keys columns |
| 8 | Guide warns against shared table config | PASS | §3 critical gotcha callout |
| 9 | prod_runtime_ets_warning documented as opt-in | PASS | §6 with verbatim warning strings |
| 10 | Getting Started §5 links production guide | PASS | First bullet in follow-on references |
| 11 | overview Day-2 links production guide | PASS | First Day-2 item |
| 12 | mix ci.docs presence gate + ExDoc extras | PASS | `mix.exs` + `mix ci.docs` exit 0 |

## Requirement Traceability

- **ADOPT-01:** Satisfied by plans 47-01 (Getting Started §3 rewrite, appendix, overview Day-1)
- **ADOPT-02:** Satisfied by plans 47-02 (production guide) and 47-03 (cross-links, CI gates)

## Automated Checks

```
mix ci.docs                          — PASS
mix test test/test_support_demo_test.exs --warnings-as-errors — PASS
mix format --check-formatted         — PASS
```

## Human Verification

None required — doc-only phase with automated grep and CI gates.

## Gaps

None.
