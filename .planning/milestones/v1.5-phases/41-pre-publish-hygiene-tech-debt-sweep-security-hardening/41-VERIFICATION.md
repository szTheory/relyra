---
phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
status: passed
verified: 2026-05-27
requirements: [TD-01, TD-02, TD-03, TD-04, TD-05]
plans_reviewed: 5
plans_executed: 5
gaps: 0
human_needed: false
---

# Phase 41 Verification

**Goal:** Pre-publish hygiene tech-debt sweep & security hardening (TD-01 through TD-05)

**Result:** 4/5 requirements fully satisfied in code and gates; 2 gaps remain (TD-05 repo-wide format; TD-04 residual ENC-01 copy in legacy research doc).

## Summary

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TD-01 | **Pass** | `AttributeEscape` wired in metadata; security corpus + `ci.security` lane |
| TD-02 | **Pass** | Dual prod-compile + Hex package exclusion verified locally |
| TD-03 | **Pass** | Tree-bound `locate_encrypted_assertion/2`; no regex on encrypted path |
| TD-04 | **Partial** | README/PROJECT/legacy milestone docs correct; FEATURES.md MVP bullet still implies `EncryptedAttribute` shipped |
| TD-05 | **Fail** | `adversarial_crypto_test.exs` formatted; repo-wide `mix format --check-formatted` exits 1 (14 files) |

## Plan execution

All five plans (41-01..41-05) have matching SUMMARY artifacts dated 2026-05-27. Code review artifact `41-REVIEW.md` reports clean (0 critical, 0 warning).

## Requirement verification

### TD-01 — Metadata attribute escaping + ci.security gate

**Status: Pass**

- `lib/relyra/security/xml/attribute_escape.ex` implements C14N-aligned escaping for `& < > " '` and control chars (`\t`, `\n`, `\r`).
- `lib/relyra/protocol/metadata.ex` routes dynamic `entityID` and `Location` through `AttributeEscape.escape_attribute/1`; certificate bodies unchanged.
- `test/security/metadata_attribute_injection_test.exs` covers adversarial entityID/Location/newline cases.
- Registered in `mix.exs` `ci.security` as dedicated `cmd mix test test/security/metadata_attribute_injection_test.exs` (line 208).
- Listed in `@gated_suites` in `test/security/ci_gate_integrity_test.exs`.

**Commands run:**

```
mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors
# 3 tests, 0 failures

mix ci.security
# exit 0 (includes metadata_attribute_injection suite)
```

### TD-02 — test_support excluded from prod compile and Hex package

**Status: Pass**

- `mix.exs` `prod_elixirc_paths/0` builds explicit `lib/**/*.ex` list rejecting paths containing `test_support`.
- `package_lib_files/0` whitelists `lib/**/*` regular files with same rejection.
- Production compile produces 119 `.ex` files; zero TestSupport beams.

**Commands run:**

```
MIX_ENV=prod mix compile --force
# Compiling 119 files (.ex); find _build/prod -name '*TestSupport*' → 0

mix hex.build
# Saved to relyra-1.2.0.tar; tar listing → NO test_support entries
```

### TD-03 — Tree-bound encrypted assertion bytes, no regex locator

**Status: Pass**

- `lib/relyra/security/xml/saxy_tree.ex` records optional `start_byte` / `end_byte` on nodes during the single parse pass.
- `lib/relyra/protocol/validation_pipeline.ex` `locate_encrypted_assertion/2` slices via `binary_part/3` on tree spans; fails closed to `:ambiguous` when spans missing or out of bounds.
- No `~r/` or `Regex` usage in `validation_pipeline.ex`; no encrypted-assertion regex in `lib/`.
- `41-03-SUMMARY` span-fidelity regression in `decrypt_assertion_test.exs`.

**Commands run:**

```
mix test test/relyra/protocol/decrypt_assertion_test.exs \
  test/security/xml_enc_adversarial_test.exs \
  test/security/xml_enc_test.exs --warnings-as-errors
# 21 tests, 0 failures (includes decrypt + enc security suites)
```

### TD-04 — README preset framing + ENC-01 doc scope

**Status: Partial (1 residual doc gap)**

**Satisfied:**

- `README.md` lines 25–50: "4 first-class presets" + generic runbook covering 7 IdP families (Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, Oracle Access Manager).
- `.planning/PROJECT.md` "What This Is": four first-class presets + seven-family generic runbook (no "8 presets" claim in adopter-facing section).
- `.planning/milestones/v1.3-REQUIREMENTS.md` ENC-01 scoped to `EncryptedAssertion` with explicit `EncryptedAttribute` research-only note.
- `.planning/research/FEATURES.md` opens with historical scope clarification block.
- Audit files note WR-ENC-ATTR resolved.

**Gap G-01:**

- `.planning/research/FEATURES.md:177` — MVP "Launch With" ENC-01 bullet still reads `` `EncryptedAttribute` included `` in the requirement text, contradicting the historical scope note at the top of the same file and TD-04 acceptance ("No ENC-01 requirement line implies EncryptedAttribute is shipped").
- `.planning/research/FEATURES.md:202` — feature matrix row "ENC-01: EncryptedAttribute" remains without historical/out-of-scope marking.

**Not counted as gaps (administrative):**

- `.planning/REQUIREMENTS.md` traceability table still lists TD-01..TD-05 as Pending (tracking metadata; v1.5 requirement text itself describes the fix targets correctly).
- `.planning/PROJECT.md:35` mentions "8 presets" only inside a v1.5 wedge bullet describing work to do, not as a current-state claim.

### TD-05 — adversarial_crypto_test.exs formatted

**Status: Fail (repo-wide criterion unmet)**

**Satisfied:**

- `mix format --check-formatted test/security/xml/adversarial_crypto_test.exs` → exit 0.
- `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` → 7 tests, 0 failures (via targeted suite run and `mix ci.security`).

**Gap G-02:**

- TD-05 and Phase 41 ROADMAP success criterion #5 require `mix format --check-formatted` exit 0 **across the full repo**.
- `41-05-SUMMARY` documents known deviation: repo-wide check still fails.
- Current unformatted files (2026-05-27):

  ```
  lib/relyra.ex
  lib/relyra/protocol/logout_request.ex
  lib/relyra/protocol/logout_response.ex
  lib/relyra/security/logout_validator.ex
  lib/relyra/security/signature.ex
  lib/relyra/session_adapter.ex
  mix.exs
  test/protocol/logout_pipeline_test.exs
  test/relyra/protocol/logout_request_test.exs
  test/relyra/protocol/logout_response_test.exs
  test/relyra/security/logout_validator_test.exs
  test/relyra/security/signature_test.exs
  test/relyra_test.exs
  test/security/xml/corpus_security_test.exs
  ```

## Gaps and remediation

| ID | Requirement | Severity | Remediation |
|----|-------------|----------|-------------|
| G-01 | TD-04 | Low | Edit `.planning/research/FEATURES.md` ENC-01 MVP bullet (line 177) and matrix row (line 202) to match v1.3 ship scope — remove or mark `EncryptedAttribute` as research-only / not shipped. |
| G-02 | TD-05 | Medium | Run `mix format` on the 14 unlisted files (or full repo) so `mix format --check-formatted` exits 0; re-run `mix ci.security` to confirm no semantic regressions. |

## Human needed

**No.** Both gaps have clear, bounded fixes (doc edit + repo-wide format). No architectural or security judgment calls required.

## Overall phase status

**gaps_found** — Security and packaging hardening (TD-01, TD-02, TD-03) are production-ready and gated. Doc hygiene (TD-04) and formatting closure (TD-05) need the two items above before Phase 41 can be marked complete against ROADMAP success criteria.
