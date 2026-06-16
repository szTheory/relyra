---
phase: 64-public-testing-api-package-boundary
verified: 2026-06-16T03:32:44Z
status: passed
verdict: passed
score: 12/12 must-haves verified
overrides_applied: 0
gaps: []
human_verification: []
---

# Phase 64: Public Testing API & Package Boundary Verification Report

**Phase Goal:** Ship a deliberately small `Relyra.Testing` public surface that Hex adopters can use without exposing private `Relyra.TestSupport` internals.
**Verified:** 2026-06-16T03:32:44Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `lib/relyra/testing*` exists as the public API surface and is included in package files. | VERIFIED | `lib/relyra/testing.ex`, `fixture.ex`, `signer.ex`, `adapters.ex`, and `phoenix.ex` exist. `test/mix/tasks/verify_release_parity_test.exs:154` asserts `Mix.Project.config()[:package][:files]` includes all public testing paths. Local `mix hex.build --unpack` listed all five public testing files. |
| 2 | `lib/relyra/test_support*` remains excluded from production compilation and package files. | VERIFIED | `mix.exs:51` prod elixirc paths and `mix.exs:58` package files reject `test_support`; `verify.release_parity.ex:178` filters package paths the same way. `MIX_ENV=prod mix compile --warnings-as-errors` produced `Relyra.Testing*` beams and no `Relyra.TestSupport*` beams. |
| 3 | Public helpers generate genuine signed success fixtures with matching test cert chain and no global production trust mutation. | VERIFIED | `Relyra.Testing.signed_success/1` builds `%Fixture{}` via `Signer.signed_response/1` and explicit `cert_chain`/`idp_certificates` fields (`lib/relyra/testing.ex:36`, `lib/relyra/testing.ex:196`). Signer generates a fresh RSA key and self-signed test cert (`signer.ex:41`, `signer.ex:135`). Docs state no application env, persistent term, ETS, or production resolver mutation (`testing.ex:5`). |
| 4 | Public helpers generate representative typed rejection fixtures without publishing the private adversarial corpus. | VERIFIED | `wrong_audience/1`, `tampered_digest/1`, and `invalid_signature/1` return exact expected atoms (`testing.ex:60`, `testing.ex:84`, `testing.ex:103`). `testing_fixture_crypto_test.exs:1` describes this as curated public coverage separate from the private adversarial corpus. Public modules contain no `Relyra.TestSupport` dependency. |
| 5 | Tests prove helper outputs exercise the real ACS or `consume_response/3` verification path, including digest/signature verification. | VERIFIED | Success fixture test calls `Relyra.consume_response/3` and asserts principal data (`testing_test.exs:126`). Negative fixture tests call `Relyra.consume_response/3` and assert exact `%Relyra.Error{type: ...}` for invalid audience, digest mismatch, and invalid signature (`testing_fixture_crypto_test.exs:34`, `:69`, `:90`). |
| 6 | Optional Phoenix convenience helpers are isolated from core fixture generation and do not make Phoenix mandatory. | VERIFIED | `Relyra.Testing.Phoenix.post_response/5` is a thin wrapper over `Relyra.Testing.post_params/2` and `Phoenix.ConnTest.dispatch/5` (`phoenix.ex:20`). Optional dependency tests scan core files for Phoenix/Plug tokens and compile/load them in a subprocess with no Phoenix ebins (`testing_optional_dependency_test.exs:33`, `:58`). |
| 7 | TEST-01: Hex adopters can use public `Relyra.Testing` while private `Relyra.TestSupport` remains excluded. | VERIFIED | Public API exists under `lib/relyra/testing*`; package and prod compile checks include only public testing beams and exclude test_support. |
| 8 | TEST-02: Adopters can generate a genuine signed success fixture with matching test cert chain and no production trust mutation. | VERIFIED | `Signer.signed_response/1` computes digest/signature with verifier XML primitives (`signer.ex:142`, `:147`); `testing_test.exs:118` asserts returned cert material is wired to fixture and connection. |
| 9 | TEST-03: Adopters can generate representative typed rejection fixtures, including wrong audience and tampered digest/signature, without exposing private corpus. | VERIFIED | Negative tests assert exact `:invalid_audience`, `:digest_mismatch`, and `:invalid_signature` through `consume_response/3`; no private TestSupport references in public modules. |
| 10 | TEST-04: Public testing helpers exercise real ACS or `consume_response/3`, never direct session assignment or verifier bypass. | VERIFIED | Core tests use `Relyra.consume_response/3`; Phoenix helper test posts through a router with `saml_routes()` and ACS redirect (`testing_phoenix_test.exs:1`, `:83`). `phoenix.ex` contains no direct `Relyra.consume_response`, `Plug.Conn.assign`, or session establishment call. |
| 11 | TEST-05: Phoenix convenience helper is optional and does not make Phoenix mandatory for core fixture use. | VERIFIED | Core compile/load subprocess asserts `Code.ensure_loaded?(Phoenix)` and `Code.ensure_loaded?(Phoenix.ConnTest)` are false before compiling core modules (`testing_optional_dependency_test.exs:101`, `:105`, `:109`). |
| 12 | PKG-01: Package/release parity proves public testing files ship and private support files remain excluded. | VERIFIED | Release parity tests cover filter, `package.files`, and local unpacked Hex artifact (`verify_release_parity_test.exs:142`, `:154`, `:163`). Direct verifier run of `mix hex.build --unpack` confirmed only public testing paths. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/relyra/testing.ex` | Public facade with success, negative, consume opts, and post params | VERIFIED | Exports `signed_success/1`, `wrong_audience/1`, `tampered_digest/1`, `invalid_signature/1`, `consume_opts/2`, and `post_params/2`; returns `%Fixture{}` and explicit adapters. |
| `lib/relyra/testing/fixture.ex` | Public fixture struct and type | VERIFIED | Defines enforced struct fields for response XML, encoded response, certs, connection, request intent, relay state, and expected result. |
| `lib/relyra/testing/signer.ex` | Verifier-aligned XMLDSig fixture signer | VERIFIED | Uses `SaxyTree.parse`, `PureBeam.canonicalize`, `C14N.serialize`, `:crypto.hash`, and `:public_key.sign`; no document `KeyInfo`. |
| `lib/relyra/testing/adapters.ex` | Public option-backed stores/resolver for `consume_response/3` | VERIFIED | Implements `Relyra.RequestStore`, `Relyra.ReplayStore`, and `Relyra.ConnectionResolver` behaviours. |
| `lib/relyra/testing/phoenix.ex` | Optional Phoenix ACS dispatch helper | VERIFIED | Checks `Phoenix.ConnTest`, calls `Relyra.Testing.post_params/2`, and dispatches POST to caller endpoint/path. |
| `test/relyra/testing_test.exs` | Public success fixture proof | VERIFIED | Calls `Relyra.consume_response/3`, verifies principal name_id, cert wiring, Base64 encoding, DigestValue/SignatureValue, and no KeyInfo. |
| `test/security/testing_fixture_crypto_test.exs` | Typed rejection proof and security lane target | VERIFIED | Covers wrong audience, tampered digest, invalid signature, equal-audience guard, and no direct `Relyra.Security.Signature` alias. |
| `test/relyra/testing_phoenix_test.exs` | Real ACS route proof | VERIFIED | Router imports `Relyra.Phoenix.Router`, calls `saml_routes()`, and posts a signed fixture through ACS to redirect. |
| `test/relyra/testing_optional_dependency_test.exs` | Phoenix-free core compile/load proof | VERIFIED | Runs external `elixir` subprocess with Phoenix ebins removed and source-token guards. |
| `test/mix/tasks/verify_release_parity_test.exs` | Package boundary proof | VERIFIED | Tests release parity filtering, package config, and local unpacked Hex artifact. |
| `mix.exs` | Prod/package/security wiring | VERIFIED | Prod/package paths exclude `test_support`; `ci.security` includes `cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors`. |
| `test/security/ci_gate_integrity_test.exs` | Anti-hollow security lane guard | VERIFIED | Lists `test/security/testing_fixture_crypto_test.exs` in `@gated_suites`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Relyra.Testing` | `Relyra.Testing.Fixture` | `%Fixture{}` construction | WIRED | `testing.ex:11` aliases Fixture; `testing.ex:196` builds `%Fixture{}`. |
| `Relyra.Testing.Signer` | verifier XML primitives | parse/c14n/sign path | WIRED | `signer.ex:13-17`, `:142-153` call `SaxyTree.parse`, `PureBeam.canonicalize`, and `C14N.serialize`. |
| success/negative tests | `Relyra.consume_response/3` | real verifier path | WIRED | `testing_test.exs:126`; `testing_fixture_crypto_test.exs:34`, `:69`, `:90`. |
| `mix.exs` | public fixture crypto suite | `ci.security` `cmd mix test` lane | WIRED | `mix.exs` includes `cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors`; meta-gate includes suite. |
| `Relyra.Testing.Phoenix` | `Relyra.Testing.post_params/2` | POST params wrapper | WIRED | `phoenix.ex:25`. |
| Phoenix test | ACS route | `saml_routes()` POST | WIRED | `testing_phoenix_test.exs:1-7`, `:94-98`. |
| optional dependency test | core modules | external no-Phoenix compile/load | WIRED | `testing_optional_dependency_test.exs:58-77`, `:96-125`. |
| release parity test | package filter/config | `ReleaseParity.filter_package_paths/1`, `Mix.Project.config()` | WIRED | `verify_release_parity_test.exs:142`, `:154`, `:163`. |

Note: `gsd-sdk query verify.artifacts/key-links` produced false negatives for several plan regex patterns because the implementation uses aliases or normal source text rather than the escaped pattern strings. Manual line-level verification above supersedes those metadata pattern misses.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Relyra.Testing.signed_success/1` | `%Fixture{response_xml, encoded_response, cert_chain, connection, request_intent}` | `Signer.signed_response/1`, Base64 encoding, explicit connection/request builders | Yes - fresh RSA key/cert, computed DigestValue/SignatureValue, explicit trust material | VERIFIED |
| `Relyra.Testing.wrong_audience/1` | `%Fixture{expected: {:error, :invalid_audience}}` | Signed response with mismatched actual/expected audience; equal-audience guard | Yes - real verifier rejects through validation pipeline | VERIFIED |
| `Relyra.Testing.tampered_digest/1` | `%Fixture{expected: {:error, :digest_mismatch}}` | Valid signed XML mutated after signing via guarded NameID rewrite | Yes - digest mismatch observed through verifier | VERIFIED |
| `Relyra.Testing.invalid_signature/1` | `%Fixture{expected: {:error, :invalid_signature}}` | XML signed with one key, returned trust chain from distinct key | Yes - configured cert chain mismatch rejects signature | VERIFIED |
| `Relyra.Testing.Phoenix.post_response/5` | POST params | `Relyra.Testing.post_params/2` into `Phoenix.ConnTest.dispatch/5` | Yes - ACS test redirects after real route/controller path | VERIFIED |
| package artifact test | unpacked file list | `mix hex.build --unpack` | Yes - file list from built package artifact, not source tree alone | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Public core, negative, Phoenix, and optional-dependency tests pass | `mix test test/relyra/testing_test.exs test/security/testing_fixture_crypto_test.exs test/relyra/testing_phoenix_test.exs test/relyra/testing_optional_dependency_test.exs --warnings-as-errors` | 15 tests, 0 failures | PASS |
| Release parity package-boundary suite passes | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` | 20 tests, 0 failures, 1 excluded integration canary | PASS |
| Security anti-hollow suite includes new lane | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | 4 tests, 0 failures | PASS |
| Local package artifact ships public testing files and excludes test_support | `mix hex.build --unpack -o /tmp/relyra_phase64_verify_pkg` plus file-list grep | Exit 0; listed all five `lib/relyra/testing*` files and no `lib/relyra/test_support*` paths | PASS |
| Production compilation includes public testing and excludes private support | `MIX_ENV=prod mix compile --warnings-as-errors`; inspect `_build/prod/lib/relyra/ebin` | Exit 0; `Relyra.Testing*` beams present; no `Relyra.TestSupport*` beams listed | PASS |

One attempted combined focused-test command run in parallel with another ExUnit process failed during shared Ecto schema migration bootstrap (`duplicate key value ... schema_migrations`). Sequential reruns of the same relevant suites passed; this is not classified as a phase gap.

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| Conventional phase probe discovery | `find scripts -path '*/tests/probe-*.sh' -type f` and phase plan/summary grep | No phase-declared or conventional probes found for Phase 64 | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TEST-01 | 64-01, 64-04 | Public `Relyra.Testing` ships while private `Relyra.TestSupport` remains excluded | SATISFIED | Public files exist, prod beams generated, package config/artifact include testing and exclude test_support. |
| TEST-02 | 64-01, 64-02 | Genuine signed success fixture with matching cert chain and no production trust mutation | SATISFIED | Fresh key/cert signer, explicit fixture trust, `consume_response/3` success test. |
| TEST-03 | 64-02 | Representative typed rejection fixtures without exposing private adversarial corpus | SATISFIED | Wrong audience, tampered digest, invalid signature tests assert exact errors; no public TestSupport dependency. |
| TEST-04 | 64-01, 64-02, 64-03 | Real ACS or `consume_response/3` verifier path, no direct session assignment or verifier bypass | SATISFIED | Core/negative tests use `consume_response/3`; Phoenix helper only dispatches params to route. |
| TEST-05 | 64-03 | Phoenix helper optional; core fixture use does not require Phoenix | SATISFIED | External no-Phoenix compile/load subprocess and token guards pass. |
| PKG-01 | 64-04 | Package/release parity proves public testing files ship and private support files are excluded | SATISFIED | Release parity tests plus direct unpacked package inspection. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/relyra/testing/signer.ex` | 44-45 | `placeholder_xml`/`placeholder_tree` | Info | Internal signing scaffold used to compute the digest before inserting signature values; not a placeholder implementation or user-visible stub. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase-modified files. No public testing module references `Relyra.TestSupport`. No security invariant in `AGENTS.md` is violated: document `KeyInfo` is not trusted, verifier path remains the existing Saxy/PureBeam/C14N path, digest/signature math is exercised by `consume_response/3`, no production trust source is mutated, and security CI keeps the dedicated `cmd mix test` lane.

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. Phase 64 achieves the package-boundary goal: Hex-facing `Relyra.Testing` is public, production-compiled, signed-fixture capable, representative rejection capable, optionally Phoenix-convenient without making Phoenix mandatory for core helpers, and package-proven while private `Relyra.TestSupport` remains excluded.

---

_Verified: 2026-06-16T03:32:44Z_
_Verifier: the agent (gsd-verifier)_
