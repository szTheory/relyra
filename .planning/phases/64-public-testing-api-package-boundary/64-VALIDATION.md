---
phase: 64
slug: public-testing-api-package-boundary
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-15
---

# Phase 64 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix 1.19.x |
| **Config file** | `mix.exs` aliases plus standard ExUnit layout |
| **Quick run command** | `mix test test/relyra/testing_test.exs test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` |
| **Full suite command** | `mix qa && mix ci.security` |
| **Estimated runtime** | ~90-180 seconds for focused suites; longer for full QA/security |

---

## Sampling Rate

- **After every task commit:** Run the focused command named in that task's `<verify>` block.
- **After every plan wave:** Run `mix test --warnings-as-errors`; run `mix ci.security` for waves that touch signer, verifier, fixture crypto, package boundary, or ACS paths.
- **Before `$gsd-verify-work`:** `mix qa`, `mix ci.security`, and package/release parity checks must be green.
- **Max feedback latency:** no more than one task without a focused automated verification command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-W0-01 | TBD | 0 | TEST-01, TEST-02, TEST-04 | T64-01, T64-02, T64-03 | Public fixtures compile under `lib/relyra/testing*` and successful fixtures pass through `consume_response/3`. | integration | `mix test test/relyra/testing_test.exs --warnings-as-errors` | no | pending |
| 64-W0-02 | TBD | 0 | TEST-02, TEST-03, TEST-04 | T64-01, T64-02, T64-03 | Negative public fixtures fail for exact typed digest/signature/audience reasons through the real verifier. | security/integration | `mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors` | no | pending |
| 64-W0-03 | TBD | 0 | TEST-05 | T64-06 | Core fixture generation remains Phoenix-free; any Phoenix helper stays isolated. | compile/integration | `mix test test/relyra/testing_optional_dependency_test.exs --warnings-as-errors` | no | pending |
| 64-W0-04 | TBD | 0 | TEST-05 | T64-06 | Optional ACS convenience, if shipped, dispatches POST params through a real ACS route or remains explicitly deferred. | integration | `mix test test/relyra/testing_phoenix_test.exs --warnings-as-errors` | no | pending |
| 64-W0-05 | TBD | 0 | PKG-01 | T64-04 | Package files include `lib/relyra/testing*` and exclude `lib/relyra/test_support*`. | package | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` | existing file needs extension | pending |

---

## Threat References

| ID | Threat | Required Mitigation |
|----|--------|---------------------|
| T64-01 | Structure-only signed success accepted | Public success fixtures must compute real `DigestValue` and `SignatureValue`; tests must prove acceptance through `Signature.verify/4` via `consume_response/3` or ACS. |
| T64-02 | Document `KeyInfo` trusted as certificate source | Fixture trust material must be returned as explicit cert/connection data; tests must not depend on document key material. |
| T64-03 | Parser or C14N differential between fixture signer and verifier | Signer must reuse Relyra's Saxy/C14N path; no alternate XML parser or custom fixture-only canonicalization. |
| T64-04 | Private adversarial corpus or `TestSupport` leaks into package | Public negative fixtures are representative only; package parity must prove `test_support` is absent. |
| T64-05 | Global production trust mutation from helper | Helpers must return explicit fixture data/options and avoid Application env, persistent global trust, or production resolver mutation. |
| T64-06 | Optional Phoenix helper becomes mandatory | Core fixture modules must remain Phoenix-free; Phoenix convenience must live in an optional layer or be deferred. |

---

## Wave 0 Requirements

- [ ] `test/relyra/testing_test.exs` - covers TEST-01, TEST-02, and TEST-04.
- [ ] `test/security/testing_fixture_crypto_test.exs` - covers TEST-02, TEST-03, and TEST-04.
- [ ] `test/relyra/testing_optional_dependency_test.exs` - covers TEST-05 core dependency isolation.
- [ ] `test/relyra/testing_phoenix_test.exs` - covers TEST-05 ACS convenience if shipped.
- [ ] Extend `test/mix/tasks/verify_release_parity_test.exs` - covers PKG-01 inclusion and exclusion.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public API naming review | TEST-01 | New `Relyra.Testing` surface is public API posture and should remain deliberately small before implementation commits to names. | During implementation, inspect moduledocs/types/functions before final verification; confirm no macro-first API or broad `TestSupport` re-export was introduced. |

---

## Validation Sign-Off

- [x] All phase requirements have an automated verification path or Wave 0 test file.
- [x] Security-relevant fixture behavior has threat references.
- [x] Package-boundary behavior is verified against package/release parity, not source-tree existence only.
- [x] No watch-mode flags are used in verification commands.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** pending execution evidence
