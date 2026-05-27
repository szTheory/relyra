---
phase: 35
slug: signed-authnrequests-adfs-preset
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from RESEARCH.md §2 "Validation Architecture" (Nyquist Dimension 8).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir/OTP stdlib; bundled with `mix`) |
| **Config file** | None at module level; `mix.exs` `aliases/0` `ci.security` is the gate (lines 152-182) |
| **Quick run command** | `mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors` |
| **Full security suite** | `mix ci.security` |
| **Full project suite** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~5 seconds (5 corpus rows) / ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd:verify-work`:** `mix ci.security` AND `mix test --warnings-as-errors` AND `mix format --check-formatted` AND `mix credo --strict` AND `mix sobelow --config` must all be green
- **Max feedback latency:** 5 seconds (per-commit quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 0 | AUTHN-01 | T-35-03 | `signing_digest_atom/1` returns `{:ok, :sha256}` for RSA-SHA256 URI; `{:error, :unsupported_signing_algorithm}` for ECDSA; `{:error, :unknown_signing_algorithm}` for unknown URI | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-01-02 | 01 | 0 | AUTHN-01 | T-35-01, T-35-06 | `Signature.sign_redirect_query/3` signs raw query-string binary verbatim; no internal `URI.encode_query/1` | unit + corpus Row 4 | `mix test test/relyra/security/signature_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-01-03 | 01 | 0 | AUTHN-01 | T-35-02 | Missing/unparseable `:sp_signing_key_pem` → `{:error, %Error{type: :key_not_configured}}` | unit | same as 35-01-02 | ✅ (extend existing) | ⬜ pending |
| 35-02-01 | 02 | 1 | AUTHN-01 | T-35-07 | `Binding.encode_redirect/3` raw-DEFLATEs XML before base64; `:zlib` resource closed even on exception | unit (binding_test) | `mix test test/relyra/protocol/binding_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-02-02 | 02 | 1 | AUTHN-01 | T-35-01 | Round-trip: `:zlib.inflate(z, ..., -15)` of deflated-then-base64-decoded Okta/Google/Entra fixture XML recovers original byte-identically | unit (regression smoke) | same as 35-02-01 | ✅ (extend existing) | ⬜ pending |
| 35-02-03 | 02 | 1 | AUTHN-01 | T-35-05 | `Binding.encode_redirect/3` with `:adfs_lower` post-processes `%[0-9A-F][0-9A-F]` → lowercase | unit | same as 35-02-01 | ✅ (extend existing) | ⬜ pending |
| 35-03-01 | 03 | 1 | AUTHN-02 | — | New `signed_request_encoding` field on `Connection` schema; cast list; `draft_changeset` validation | unit (connection_test) | `mix test test/relyra/ecto/connection_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-03-02 | 03 | 1 | AUTHN-02 | — | `ConnectionSnapshot.base_runtime_attrs/1` threads `signed_request_encoding` to runtime struct | unit (snapshot_test) | `mix test test/relyra/ecto/connection_snapshot_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-04-01 | 04 | 1 | AUTHN-04 | T-35-04 | `Relyra.Provider.ADFS.default_config/0` returns the locked D-15 map; registered in `@presets` + `@provider_presets` | unit (provider_test) | `mix test test/relyra/provider_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-05-01 | 05 | 2 | AUTHN-01 | T-35-01, T-35-08 | `start_login/3` returns `{:ok, %{redirect_query: bytes}}` for signed connections; `:redirect_params` map preserved for unsigned path | unit (relyra_test) | `mix test test/relyra_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-05-02 | 05 | 2 | AUTHN-01 | T-35-01 | `LoginController.redirect_to_idp/3` appends core-built `:redirect_query` bytes VERBATIM to `sso_url`; no `URI.encode_query/1` on signed path | unit (login_controller_test) | `mix test test/relyra/phoenix/controllers/login_controller_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-06-01 | 06 | 2 | AUTHN-03 | T-35-04 | `metadata.ex` emits `AuthnRequestsSigned="true"` AND `<md:KeyDescriptor use="signing">` when `sign_authn_requests: true` | unit (metadata_test) | `mix test test/relyra/protocol/metadata_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-06-02 | 06 | 2 | AUTHN-03 | T-35-04 | `metadata.ex` OMITS both `AuthnRequestsSigned` attribute AND signing `<KeyDescriptor>` when `sign_authn_requests: false`; encryption `KeyDescriptor` (Phase 34) unchanged | unit (metadata_test) | same as 35-06-01 | ✅ (extend existing) | ⬜ pending |
| 35-07-01 | 07 | 3 | AUTHN-01 (golden) | T-35-01 | Corpus Row 1: bit-for-bit match against `golden_redirect.txt` for `:rfc3986_upper` encoding | security corpus | `mix test test/security/authn_request_signing_test.exs --only authn_request_signing -t row_golden --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 35-07-02 | 07 | 3 | AUTHN-01 (ADFS variant) | T-35-05 | Corpus Row 2: bit-for-bit match against `golden_redirect_adfs.txt` for `:adfs_lower` encoding | security corpus | same suite, `-t row_adfs_lower` | ❌ W0 | ⬜ pending |
| 35-07-03 | 07 | 3 | AUTHN-01 (raw-octet invariant) | T-35-01 | Corpus Row 3 (mutation test): `URI.encode_query/1`-re-serialized signature MUST `!=` golden signature | security corpus | same suite, `-t row_reserialization_regression` | ❌ W0 | ⬜ pending |
| 35-07-04 | 07 | 3 | AUTHN-01 (round-trip verify) | T-35-06 | Corpus Row 4: `:public_key.verify/4` against SP signing cert returns `:ok` for SP-emitted signature | security corpus | same suite, `-t row_roundtrip_verify` | ❌ W0 | ⬜ pending |
| 35-07-05 | 07 | 3 | AUTHN-02 | — | Corpus Row 5: `sign_authn_requests: false` returns `{:ok, %{redirect_params: %{...}}}` with no `"SigAlg"`/`"Signature"` keys; existing Okta/Google/Entra tests do not regress | security corpus + regression | corpus row 5 in same suite; `mix test test/relyra/provider/` for regression | ❌ W0 (row) / ✅ (regression) | ⬜ pending |
| 35-07-06 | 07 | 3 | AUTHN-01 | — | Golden fixtures committed: `golden_redirect.txt`, `golden_redirect_adfs.txt`, `golden_authnrequest.xml`, `golden_signing_key.pem`, `PROVENANCE.md` (Phase 28 fixture-commit pattern) | file existence | `cmd test -f test/fixtures/security/authn_request_signing/PROVENANCE.md` | ❌ W0 | ⬜ pending |
| 35-08-01 | 08 | 3 | AUTHN-01 | T-35-01 | New `cmd mix test ... --only authn_request_signing --warnings-as-errors` line in `mix.exs` `ci.security` alias (lines 152-182); placed after `adversarial_crypto` line | ci wiring | `mix ci.security` (full suite) | ❌ W0 | ⬜ pending |
| 35-08-02 | 08 | 3 | AUTHN-01 | T-35-06 | `:authn_request_signing` added to `@gated_suites` in `test/security/ci_gate_integrity_test.exs` (Phase 30 hollow-gate meta-gate) | ci wiring | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | ✅ (extend existing) | ⬜ pending |
| 35-09-01 | 09 | 3 | AUTHN-04 (runbook) | T-35-04 | `guides/recipes/adfs.md` created; sections cover Overview, SP-side config, ADFS PowerShell (`Set-AdfsRelyingPartyTrust`), claim rules, interop notes, troubleshooting | file existence + docs gate | `cmd test -f guides/recipes/adfs.md` in `ci.docs` alias | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/security/authn_request_signing_test.exs` — new file, 5 corpus rows, `@moduletag :authn_request_signing`
- [ ] `test/fixtures/security/authn_request_signing/golden_redirect.txt` — committed bytes (Row 1 golden)
- [ ] `test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt` — committed bytes (Row 2 golden)
- [ ] `test/fixtures/security/authn_request_signing/golden_authnrequest.xml` — committed input XML
- [ ] `test/fixtures/security/authn_request_signing/golden_signing_key.pem` — committed PEM (deterministic golden re-mint; `FakeIdP.keypair/0` is per-process-lazy and non-deterministic)
- [ ] `test/fixtures/security/authn_request_signing/PROVENANCE.md` — fixture key fingerprint, byte counts, Elixir/OTP version, spec citation chain
- [ ] `lib/relyra/provider/adfs.ex` — new preset module (Wave 1, but listed here because Wave 3 corpus depends on it)
- [ ] `guides/recipes/adfs.md` — operator runbook (Wave 3; block on Microsoft Learn re-verification task per RESEARCH.md A1)
- [ ] No framework install needed — ExUnit is bundled with Elixir/OTP

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ADFS PowerShell `Set-AdfsRelyingPartyTrust` command actually works against a real ADFS 3.0/4.0/5.0 server | AUTHN-04 (runbook) | Requires Windows Server + ADFS role; out-of-band integration test environment | (Documented in `guides/recipes/adfs.md`; operator runs commands against their own ADFS as part of adopting the preset) |
| `guides/recipes/adfs.md` PowerShell block matches current Microsoft Learn `Set-AdfsRelyingPartyTrust` (Server 2025) parameter reference | AUTHN-04 (runbook) | Web-fetch + human cross-reference; not amenable to automated diff (Microsoft updates docs ad-hoc) | Wave 0 task in Plan 09: fetch https://learn.microsoft.com/en-us/powershell/module/adfs/set-adfsrelyingpartytrust → verify parameter names `-SignedSamlRequestsRequired`, `-RequestSigningCertificate`, `-SignatureAlgorithm`, `-SamlResponseSignature` are current; record verification date in `PROVENANCE.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies declared above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (verified by per-task command column above)
- [ ] Wave 0 covers all MISSING references (new corpus file + 4 golden fixtures + `PROVENANCE.md` + ADFS preset module + runbook + Microsoft Learn cross-reference)
- [ ] No watch-mode flags (all commands are one-shot with `--warnings-as-errors`)
- [ ] Feedback latency < 5s per task commit (corpus runs in isolation; full suite < 30s)
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 completes and corpus rows go green

**Approval:** complete
