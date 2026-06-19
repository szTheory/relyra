---
phase: 65-documentation-truth
verified: 2026-06-19T15:45:42Z
status: passed
requirements:
  - DOCS-01
  - DOCS-02
  - DOCS-03
score: "7/7 must-haves verified"
roadmap_success_criteria_verified: "5/5"
plan_truths_verified: "5/5"
artifacts_verified: "3/3"
key_links_verified: "3/3"
behavior_unverified: 0
overrides_applied: 0
gaps_count: 0
human_verification_count: 0
commands_run:
  - "mix test test/testing_demo_test.exs test/docs/testing_api_drift_test.exs test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors"
  - "mix relyra.batteries_included --check"
  - "mix ci.docs"
  - "mix test test/relyra/testing_test.exs test/security/testing_fixture_crypto_test.exs test/relyra/testing_phoenix_test.exs test/relyra/testing_optional_dependency_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors"
---

# Phase 65: Documentation Truth Verification Report

**Phase Goal:** Make README, Getting Started, overview, recipes, and generated proof docs match the public package reality.
**Verified:** 2026-06-19T15:45:42Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Hex adopters are pointed at `Relyra.Testing`, not private `Relyra.TestSupport`, for local proof. | VERIFIED | `rg` over targeted adopter docs and proof files found no `Relyra.TestSupport`/`FakeIdP` hits. README lines 44 and 99, overview line 13, Getting Started lines 76-145, recipes, JTBD, case study, and `BATTERIES_INCLUDED.md` line 21 point to `Relyra.Testing` / `Relyra.Testing.Phoenix`. |
| 2 | Docs label helpers as test-only/local proof and avoid production IdP or hosted broker claims. | VERIFIED | Getting Started lines 78-86 place helpers before any real IdP and describe local verifier fixtures; README lines 105-109 explicitly says a hosted broker runtime does not ship; JTBD line 63 rejects hosted-broker positioning. |
| 3 | Docs explain cert/key provenance and scope test cert trust explicitly. | VERIFIED | Getting Started lines 82-86 contain an ExDoc `Info` admonition explaining ephemeral RSA keys generated at runtime, discarded with the Beam process, and used only for local crypto verification seams. |
| 4 | Repo-internal private/FakeIdP references do not leak into targeted adopter docs. | VERIFIED | Private references remain only in internal `test/test_support_demo_test.exs`, a refutation assertion in `test/mix/tasks/relyra_batteries_included_test.exs`, and Phase 66-owned `guides/fake_idp_demo.md`. Targeted Phase 65 docs do not point adopters to FakeIdP. |
| 5 | A public demo test exists and exercises the public testing API through the real verifier path. | VERIFIED | `test/testing_demo_test.exs` lines 24-43 use `Relyra.Testing.signed_success/1`, `Relyra.consume_response/3`, `Relyra.Testing.consume_opts/2`, and `Relyra.Testing.Phoenix.post_response/5`. Targeted test command passed, 7 tests, 0 failures. |
| 6 | Drift and CI gates cover the new public testing story. | VERIFIED | `test/docs/testing_api_drift_test.exs` lines 29-73 mirrors the Getting Started code blocks; `mix.exs` lines 222 and 227 wire the drift test and public demo into `ci.docs`; `mix ci.docs` passed. |
| 7 | Phase 65 made no production trust-boundary, parser, signature, replay, audit, or public API signature changes beyond docs/test demo/gate wiring. | VERIFIED | `git show --name-only` for Phase 65 commits touches docs, `mix.exs`, `lib/mix/tasks/relyra.batteries_included.ex`, and tests only. No Phase 65 changes under `lib/relyra/security`, `lib/relyra/ecto`, `lib/relyra/replay_store*`, `lib/relyra.ex`, `lib/relyra/testing*`, or `lib/relyra/behaviours`. Phase 64 public testing regression gate passed, 19 tests, 0 failures. |

**Score:** 7/7 truths verified, 0 present-but-behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `guides/getting_started.md` | Updated local testing instructions using `Relyra.Testing.signed_success/1` | VERIFIED | Lines 76-181 contain the public API flow, cert provenance admonition, verifier call, and Phoenix helper call. |
| `test/testing_demo_test.exs` | Public demo using only public APIs | VERIFIED | Lines 24-43 use `Relyra.Testing` and do not contain `Relyra.TestSupport`. Wired into `mix ci.docs`. |
| `test/docs/testing_api_drift_test.exs` | Drift protection for public testing narrative | VERIFIED | Lines 29-73 assert the exact Getting Started code blocks. Wired into `mix ci.docs`. |

The GSD artifact verifier also returned `all_passed: true` for these three artifacts.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `guides/getting_started.md` | `test/docs/testing_api_drift_test.exs` | Mirrored public code blocks | VERIFIED | Manual `rg` confirms `Relyra.Testing.signed_success`, `consume_opts`, and `Phoenix.post_response` in both files; drift test passed. |
| `mix.exs` | `test/docs/testing_api_drift_test.exs` / `test/testing_demo_test.exs` | `ci.docs` alias | VERIFIED | `mix.exs` lines 222 and 227 include both gates; `mix ci.docs` passed. |
| `lib/mix/tasks/relyra.batteries_included.ex` | `BATTERIES_INCLUDED.md` | Generated proof report | VERIFIED | `@demo_test` is `test/testing_demo_test.exs`; generated output references `Relyra.Testing`; `mix relyra.batteries_included --check` passed. |

Tool note: the built-in `verify.key-links` helper returned a false negative for the escaped regex pattern. Manual link verification and the executable drift test both prove the link.

### Data-Flow Trace

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `BATTERIES_INCLUDED.md` | local-first proof row | `Mix.Tasks.Relyra.BatteriesIncluded.render_report/0` using `@demo_test "test/testing_demo_test.exs"` | Yes - generated report matches checked-in artifact | VERIFIED |
| `guides/getting_started.md` | public testing code blocks | Static guide mirrored by `test/docs/testing_api_drift_test.exs` | Yes - test asserts exact guide text | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Public testing demo, drift test, and generator tests pass | `mix test test/testing_demo_test.exs test/docs/testing_api_drift_test.exs test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` | 7 tests, 0 failures | PASS |
| Generated batteries proof is current | `mix relyra.batteries_included --check` | Matches generated batteries-included state | PASS |
| Docs CI includes the public testing story | `mix ci.docs` | Exit 0 | PASS |
| Public testing regression gate remains green | `mix test test/relyra/testing_test.exs test/security/testing_fixture_crypto_test.exs test/relyra/testing_phoenix_test.exs test/relyra/testing_optional_dependency_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors` | 19 tests, 0 failures | PASS |

### Probe Execution

No phase probes were declared or required for this documentation/testing phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| DOCS-01 | `65-01-PLAN.md` | README, Getting Started, overview, recipes, and batteries docs no longer instruct Hex adopters to use private `Relyra.TestSupport`. | SATISFIED | Targeted docs/proof files have zero adopter-facing `Relyra.TestSupport` hits and point to `Relyra.Testing`. |
| DOCS-02 | `65-01-PLAN.md` | Public docs label `Relyra.Testing` as test-only/local proof with ephemeral/explicit cert handling and no production IdP claim. | SATISFIED | Getting Started local-proof and ephemeral-key admonition; README hosted-broker exclusion. |
| DOCS-03 | `65-01-PLAN.md` | Local proof docs/tests updated to public API or explicitly internal; drift and CI gates cover the public testing story. | SATISFIED | Public demo and drift tests use `Relyra.Testing`; old private demo is internal CI only and not linked from adopter docs; `ci.docs` gates the public demo/drift path. |

### Anti-Patterns Found

No blocker anti-patterns found. Scan over Phase 65 files found no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, placeholder copy, or unimplemented markers. The only empty-list-style match was `invalid != []` in the Mix task option parser and is not a stub.

### Human Verification Required

None. The phase is documentation and test-gate oriented; required behavior is covered by executable tests and source checks.

### Gaps Summary

No gaps found. The Phase 65 goal is achieved against the current codebase.

---

_Verified: 2026-06-19T15:45:42Z_
_Verifier: the agent (gsd-verifier)_
