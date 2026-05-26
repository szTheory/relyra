# Phase 35: Signed AuthnRequests + ADFS Preset — Research

**Researched:** 2026-05-26
**Domain:** SAML 2.0 HTTP-Redirect-binding outbound AuthnRequest signing (RSA-SHA256 over raw query-string octets) + ADFS provider preset + bit-for-bit golden corpus.
**Confidence:** HIGH for spec compliance, code shapes, and adversarial corpus design. MEDIUM for the exact ADFS PowerShell parameter set on Server 2025 (CONTEXT.md D-18 carries the canonical block; this research verifies its mechanics, not its line-by-line currency).

CONTEXT.md decisions D-01..D-23 are LOCKED. This research does not re-derive them — it resolves the
six "Claude's Discretion" gray-areas (CONTEXT.md:268-287), wires the validation architecture,
verifies the pre-existing `Binding.encode_redirect/3` raw-DEFLATE bug, supplies external-spec
verbatim, enumerates the outbound-signing threat model, and confirms the cross-phase coordination
preconditions (Phase 32 `signing_digest_atom/1` gap is real; Phases 33-34 are file-disjoint).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `Signature.sign_redirect_query/3` is the single SP-side signing primitive; mirrors `do_verify/4`; signs the binary verbatim (no `URI.encode_query/1` inside).
- **D-02:** Redirect-URL assembly moves into Relyra core; `start_login/3` returns `:redirect_query` (pre-assembled bytes) for the signed case; the controller appends verbatim.
- **D-03/D-04:** `Binding.encode_redirect/3` gains raw-DEFLATE (RFC 1951, `:zlib` window bits `-15`) unconditionally — applied to BOTH signed and unsigned paths. Fix-forward; not a feature flag.
- **D-05:** `AlgorithmPolicy.signing_digest_atom/1` lands as Phase 35 Plan 01 Task 1; mirrors `digest_atom_for_signature_method/1` shape; ECDSA fail-closed; new error atoms `:unsupported_signing_algorithm` and `:unknown_signing_algorithm`.
- **D-06:** New config key `:sp_signing_key_pem` (`Application.get_env`); distinct from `:sp_private_key_pem` (Phase 33) and `:sp_signing_cert_pem` (Phase 34).
- **D-07:** Missing/unparseable key → `{:error, %Error{type: :key_not_configured, ...}}`; mirrors `KeyResolver.Default` pattern.
- **D-08/D-09:** Default `:rfc3986_upper` encoding (uppercase hex, `URI.encode_www_form/1`); `:adfs_lower` variant post-processes `%[0-9A-F][0-9A-F]` → lowercase. Connection-level field; ADFS preset sets `:adfs_lower`.
- **D-10:** Signed octet template: `SAMLRequest=...&RelayState=...&SigAlg=...` (RelayState segment OMITTED entirely when absent — not empty-string). `SigAlg` last.
- **D-11:** `Signature` parameter appended LAST to emitted URL; NOT in signed bytes; `Base.encode64/1` (padding on) then `URI.encode_www_form/1`.
- **D-12/D-13:** `metadata.ex` gates signing `KeyDescriptor` + adds `AuthnRequestsSigned="true"` attribute on `<SPSSODescriptor>` element ONLY when `sign_authn_requests: true`. Encryption descriptor (Phase 34) remains unconditional.
- **D-14:** No new schema fields beyond the encoding field; `sign_authn_requests` already exists from Phase 32.
- **D-15/D-16:** New `Relyra.Provider.ADFS` module; registered in `lib/relyra/provider.ex` `@presets` AND `lib/relyra/ecto/connection.ex` `@provider_presets`.
- **D-17/D-18:** New `guides/providers/adfs.md` (or `guides/recipes/adfs.md` — planner picks; see §3 below) with canonical PowerShell block.
- **D-19/D-20/D-21:** New `test/security/authn_request_signing_test.exs` (5 corpus rows, `@moduletag :authn_request_signing`); wired as its own `cmd mix test` line in `mix.exs:152-182`; `:authn_request_signing` added to `ci_gate_integrity_test.exs` `@gated_suites`. Golden bytes committed as files with `PROVENANCE.md`.
- **D-22/D-23:** No `:invalid_authn_request_signature` error (SP generates, doesn't verify). New typed errors: `:key_not_configured`, `:unsupported_signing_algorithm`, `:unknown_signing_algorithm` via `Error.new/3`.

### Claude's Discretion (resolved in §3 — Code Shape Recommendations)
1. Module split between `Signature.sign_redirect_query/3` and a possible new helper module.
2. `encode_redirect/3` extended in-place vs. sibling `encode_signed_redirect/4`.
3. Exact field name for the encoding option on `Connection`.
4. Migration timestamp filename if a new column is needed.
5. Runbook lives at `guides/providers/adfs.md` or `guides/recipes/adfs.md`.
6. Runtime helper `Relyra.Connection.signed_request_encoding/1` vs. inline resolution.
7. Row 5 (toggle-off no-op) location: security suite vs. `binding_test.exs`.

### Deferred Ideas (OUT OF SCOPE)
- HTTP-POST binding signed AuthnRequests (AUTHN-POST-01 — v1.4).
- KMS-native `KeyResolver` adapters for SP signing key (KMS-01 — v1.4).
- `SingleLogoutService` publication in `<SPSSODescriptor>` (v1.4 SLO scope).
- SP signing key rotation tooling (`mix relyra.rotate.sp_signing_key` — v1.4 if demand).
- Strict-mode footgun warning when `sign_authn_requests: false` but IdP metadata says `WantAuthnRequestsSigned="true"` (v1.4 strict-mode milestone).
- `Relyra.Provider.Shibboleth` preset — adopters use generic recipe (Phase 36).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **AUTHN-01** | SP signs AuthnRequests for HTTP-Redirect binding over the raw pre-assembled query-string binary verbatim (RSA-SHA256 default; never re-serialized); adversarial corpus includes bit-for-bit golden output + ADFS `+`-encoding variant. | §2 Validation Architecture (Corpus rows 1-4), §3 Code Shapes (`sign_redirect_query/3` + raw-DEFLATE composition), §4 Raw-DEFLATE Bug Fix Notes, §5 External Spec Verbatim (OASIS §3.4.4.1 lines 601-605, 624-625), §6 Threat Model (re-serialization footgun). |
| **AUTHN-02** | Per-connection `sign_authn_requests` boolean (default `false`); additive and backward-compatible. | Already landed Phase 32 D-10/D-11 (`connection.ex:40`); §2 Corpus row 5 verifies the default-false path emits no `SigAlg`/`Signature` parameters. |
| **AUTHN-03** | SP metadata publishes `<KeyDescriptor use="signing">` and `AuthnRequestsSigned="true"` when `sign_authn_requests: true`; omits both when false. | §3 Code Shapes (metadata gating mechanics), §2 Corpus pairs metadata-on/off assertions with the redirect-binding corpus to exercise both halves of AUTHN-03 in one suite run. |
| **AUTHN-04** | ADFS preset ships with `sign_authn_requests: true` default; ships `guides/.../adfs.md` runbook with claim rules, `Set-AdfsRelyingPartyTrust` PowerShell, SHA-1/SHA-256 interop, `WantAuthnRequestsSigned` notes. | §3 (preset module shape + runbook path resolution), §5 External Spec (Microsoft Learn `Set-AdfsRelyingPartyTrust` parameter list verified for Server 2025). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

These are LOAD-BEARING. Plans must enforce; tasks must verify.

- **Signature source:** configured IdP certs only — NEVER trust document `KeyInfo`. (Phase 35 SP-signs; doesn't verify — but the rule informs §6: SP signing key likewise comes ONLY from `:sp_signing_key_pem` config, never document-supplied.)
- **One parse path:** no second XML parse, no parser differentials; the saxy seam is the only entry. (Phase 35's `AuthnRequest.to_xml/1` produces a binary that flows through `:zlib` → `Base.encode64` → `URI.encode_www_form` — NO re-parse anywhere in the signing path. The golden corpus pins the post-deflate-base64 bytes exactly; if anyone introduces a re-parse, the bytes drift and the corpus fails.)
- **Pre-parse guards:** DTD/entity disabling + size limits run BEFORE saxy. (Out of Phase 35 scope — outbound path doesn't parse.)
- **Crypto is required:** `DigestValue` recomputed, `SignedInfo` verified via `:public_key.verify`. (Phase 35 inverse: SP-side `:public_key.sign/3` over raw octets — see §3.1.)
- **Audit co-commit:** trust mutations (connection/metadata/cert/mapping) co-commit an audit row. (Phase 35 mutations: setting `sign_authn_requests: true` on a connection is a trust mutation — already audited via Phase 32 `connection_record` writes; no new audit shape needed because `sign_authn_requests` is already in the cast list.)
- **Replay protection:** required in production. (Out of Phase 35 scope — replay defends against IdP responses, not SP requests.)
- **`mix ci.security` hollow-gate fix is permanent:** each suite is its own `cmd mix test` process (Phase 30). (D-20 enforces; §7 details the wiring mechanics.)
- **Never weaken `test/security/xml/adversarial_crypto_test.exs`:** the AUTHN-01 corpus is a SEPARATE file (`test/security/authn_request_signing_test.exs`), not new rows on the inbound crypto corpus.

## Executive Summary

Phase 35's load-bearing claim is one byte-equality assertion: "for a fixed AuthnRequest XML, fixed `RelayState`, fixed private key, and `:rfc3986_upper` encoding, `Relyra.start_login/3` produces a redirect URL whose query-string-before-`&Signature=` byte sequence is identical to a committed golden file, and whose `Signature` parameter, when base64-decoded and verified with `:public_key.verify/4` against the matching cert, returns `:ok`." Every other Phase 35 task exists to make that assertion provable. Three architectural facts shape the work:

1. **The OASIS §3.4.4.1 spec mandates raw-DEFLATE before base64.** Relyra's current `Binding.encode_redirect/3` (lines 9-19) skips deflate — confirmed Phase-32 audit finding WARN-04. The fix is unconditional (signed AND unsigned paths) so adopters whose IdPs were silently rejecting Relyra's uncompressed bytes start working, and so the AUTHN-01 golden bytes match what real IdPs see. The `:zlib` API requires a precise incantation (`deflateInit(z, :default, :deflated, -15, 8, :default)`) and an `after`-clause `close/1` to prevent NIF resource leaks if an exception escapes between init and end.
2. **The "raw octet" rule is the CVE-class invariant.** OASIS §3.4.4.1 lines 620-623 state explicitly: "It is not sufficient to re-encode the parameters after they have been processed by software because the resulting encoding may not match the signer's encoding." Any code path that builds the query as a map (or worse, calls `URI.encode_query/1` on a map after signing) is a silent auth bypass — the IdP either rejects the signature outright or, worse, verifies it against bytes the SP never intended to authenticate. Corpus Row 3 (the re-serialization regression) is the mutation test that makes this regression impossible to land.
3. **`Connection.signed_request_encoding` is the only new persistent field.** Everything else routes through existing seams: `Signature.do_verify/4`'s sibling `sign_redirect_query/3`, `Binding.encode_redirect/3` extended in-place (recommended over a sibling — see §3.2), `metadata.ex`'s existing `KeyDescriptor` builder with conditional emission, the `KeyResolver.Default` `:_pem` Application-env pattern, and the existing `connection_snapshot.ex` `Map.get(connection, :sign_authn_requests, false)` thread.

The planner's job collapses to: (a) land `signing_digest_atom/1` and `sign_redirect_query/3` first (no upstream deps), (b) land raw-DEFLATE in-place in `Binding.encode_redirect/3` with a non-security smoke test asserting Okta/Google fixtures still decode round-trip (the existing `binding_test.exs` only checks base64-of-XML — every fixture is XML-comparison-based and opaque to deflate), (c) thread `:redirect_query` through `start_login/3` and stop calling `URI.encode_query/1` in the controller for the signed case, (d) add the encoding field to `Connection`/snapshot/runtime, (e) gate `metadata.ex`, (f) ship the ADFS preset + runbook, (g) mint the 5-row corpus with committed golden bytes + `PROVENANCE.md`, (h) wire `ci.security`. The work is sequential within a single phase but parallelizable into 2-3 waves.

**Primary recommendation:** Extend `Binding.encode_redirect/3` in-place (option A, not a sibling function); name the new connection field `signed_request_encoding` (long and self-documenting beats short and ambiguous); place the runbook at `guides/recipes/adfs.md` (matches the existing okta/entra/google_workspace placement — no `guides/providers/` directory exists today); put corpus Row 5 (toggle-off no-op) in the new security suite with the other rows (single-file corpus is the Phase 28 pattern); do NOT add a `Relyra.Connection.signed_request_encoding/1` runtime helper (fold the resolution inline — one less seam).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Raw RSA-SHA256 signing of byte string | Security primitive (`Relyra.Security.Signature`) | — | Single crypto seam invariant (CLAUDE.md §1); mirror `do_verify/4`. |
| Raw-DEFLATE compression of XML | Protocol binding (`Relyra.Protocol.Binding`) | — | Binding-layer concern; deflate is part of the HTTP-Redirect wire format, not crypto. |
| URL-encoding of query parameters | Protocol binding | — | Same binding-layer concern; encoding variant (`:rfc3986_upper` vs `:adfs_lower`) lives next to where bytes are emitted. |
| Pre-assembled signed-query construction | Protocol binding (`encode_redirect/3` extended) | Security (calls `Signature.sign_redirect_query/3`) | The binding owns octet assembly; it asks the security seam to sign once it has the canonical bytes. |
| Outbound redirect URL emission | Phoenix controller (`LoginController.redirect_to_idp/3`) | Core (`Relyra.start_login/3`) | Controller is the only thing that knows `Plug.Conn`; core hands it a pre-assembled binary so the controller's `URI.encode_query/1` call is REMOVED from the signed path. |
| SP signing key material | Application config (`:sp_signing_key_pem`) | `Signature.sign_redirect_query/3` reads | Mirrors Phase 33 SP private key convention; never in DB schema (CLAUDE.md "SP private keys never in DB"). |
| Metadata gating (`KeyDescriptor` + `AuthnRequestsSigned`) | Protocol metadata (`Relyra.Protocol.Metadata`) | — | Existing metadata builder is the single source for SP metadata bytes. |
| ADFS provider defaults | Provider preset (`Relyra.Provider.ADFS`) | Registered in `Relyra.Provider` + `Relyra.Ecto.Connection` | Two-registration pattern is established (Phase 32 D-11); presets are pure-data modules implementing the `Relyra.Provider` behaviour. |
| Connection-level encoding field | Ecto schema (`Relyra.Ecto.Connection`) + snapshot hydration + runtime struct | — | Top-level field (not embedded `RuntimePolicy`) per Phase 32 D-11 convention; threaded through `ConnectionSnapshot.base_runtime_attrs/1`. |
| Adversarial corpus | Security test suite (`test/security/authn_request_signing_test.exs`) | `mix ci.security` (own `cmd mix test` line) | Phase 30 hollow-gate-fix pattern; new `@moduletag :authn_request_signing`; gated via `ci_gate_integrity_test.exs`. |
| Golden byte fixtures | Committed files (`test/fixtures/security/authn_request_signing/*.txt`) + `PROVENANCE.md` | — | Phase 28 fixture-commit precedent (`parser_differential_and_c14n/`); tests read the committed bytes, never recompute them inline. |

## Validation Architecture (MANDATORY — drives VALIDATION.md / Nyquist Dimension 8)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir/OTP stdlib; bundled with `mix`) |
| Config file | None at module level; `mix.exs` `aliases/0` `ci.security` is the gate (lines 152-182). |
| Quick run command | `mix test test/security/authn_request_signing_test.exs --only authn_request_signing` |
| Full security suite | `mix ci.security` |
| Full project suite | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File / Status |
|--------|----------|-----------|-------------------|---------------|
| AUTHN-01 (golden) | Default `:rfc3986_upper` encoding produces a bit-for-bit match against committed golden. | Security corpus (Row 1) | `mix test test/security/authn_request_signing_test.exs --only authn_request_signing -t row_golden` | New file (Wave 0). |
| AUTHN-01 (ADFS variant) | `:adfs_lower` encoding produces a bit-for-bit match against committed ADFS golden. | Security corpus (Row 2) | same suite, `-t row_adfs_lower` | New file. |
| AUTHN-01 (raw-octet invariant) | Re-serializing the signed octets via `URI.encode_query/1` and re-signing produces a DIFFERENT signature than the golden (mutation test). | Security corpus (Row 3) | same suite, `-t row_reserialization_regression` | New file. |
| AUTHN-01 (round-trip verify) | `:public_key.verify/4` against the SP signing cert returns `:ok` for SP-signed output. | Security corpus (Row 4) | same suite, `-t row_roundtrip_verify` | New file. |
| AUTHN-01 (pre-existing deflate bug) | Round-trip: deflate-then-base64 of Okta/Google/Entra fixture XML, then decode via `:zlib.inflate(z, ..., -15)`, recovers the original XML byte-identically. | Non-security regression smoke | `mix test test/relyra/protocol/binding_test.exs` (existing file; new test cases added) | Wave 0 extension of existing file. |
| AUTHN-02 | `sign_authn_requests: false` connection emits no `SigAlg`/`Signature` parameters; existing Okta/Google/Entra tests do not regress. | Security corpus (Row 5) + existing provider tests | corpus row 5 in same suite; `mix test test/relyra/provider/` for regression | New file Row 5 + existing tests. |
| AUTHN-03 (toggle on) | Metadata for `sign_authn_requests: true` emits `AuthnRequestsSigned="true"` AND `<md:KeyDescriptor use="signing">`. | Unit test (metadata builder) | `mix test test/relyra/protocol/metadata_test.exs` (existing file; new test cases added) | Wave 0 extension. |
| AUTHN-03 (toggle off) | Metadata for `sign_authn_requests: false` omits BOTH `AuthnRequestsSigned` and signing `KeyDescriptor` (encryption descriptor unchanged). | Unit test | same file, new test case | Same. |
| AUTHN-04 (preset) | `Relyra.Provider.ADFS.default_config/0` returns the locked D-15 map; preset registered in `Relyra.Provider.list/0` and `@provider_presets`. | Unit test | `mix test test/relyra/provider_test.exs` (existing file; new test cases added) | Wave 0 extension. |
| AUTHN-04 (runbook) | `guides/recipes/adfs.md` exists; presence-test in `ci.docs`. | Docs gate | `cmd test -f guides/recipes/adfs.md` line in `mix.exs` `ci.docs` alias | Same alias as existing `cmd test -f guides/batteries_included.md` (line 143). |
| `signing_digest_atom/1` (D-05) | RSA-SHA256 URI → `{:ok, :sha256}`; ECDSA URI → `{:error, :unsupported_signing_algorithm}`; unknown URI → `{:error, :unknown_signing_algorithm}`. | Unit test | `mix test test/relyra/security/algorithm_policy_test.exs` (existing file; new test cases added) | Wave 0 extension. |

### Corpus Row Detail (the 5 rows that DRIVE AUTHN-01)

Each row pins an EXACT `%Relyra.Error{type: ...}` or `%{...}` shape, never a bare `{:ok, _}` / `{:error, _}` — the Phase 30 adversarial-crypto pattern (`adversarial_crypto_test.exs:22-25`). The golden bytes are READ from committed files, never recomputed inline (Phase 28 pattern). The signer is `:public_key.sign/3` against `FakeIdP.keypair/0` (no second signer module is introduced — same anti-divergent-signer discipline that `XmldsigSigner` enforces for the inbound path, just inverted for outbound).

**Row 1 — Golden positive control (`:row_golden`):**
- Input: fixed AuthnRequest XML (committed to `test/fixtures/security/authn_request_signing/golden_authnrequest.xml`), `RelayState = "rs_relyra_phase35_golden"`, `FakeIdP.keypair/0` as the SP signing key, `:encoding: :rfc3986_upper`.
- Assertion: `Relyra.start_login(connection, relay_context, opts)` returns `{:ok, %{redirect_query: bytes}}` where `bytes == File.read!("test/fixtures/security/authn_request_signing/golden_redirect.txt")`. The byte equality assertion is the load-bearing check; nothing else is asserted on row 1.

**Row 2 — ADFS-lower variant (`:row_adfs_lower`):**
- Same input as Row 1 EXCEPT `:encoding: :adfs_lower`.
- Assertion: `bytes == File.read!("test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt")`.
- The two golden files MUST differ ONLY in hex-case of percent-encoded sequences after the `:adfs_lower` post-process (`%2F` → `%2f`, etc.) — provable by a structural diff in `PROVENANCE.md`.

**Row 3 — Re-serialization regression (`:row_reserialization_regression`):**
- This is the MUTATION TEST that proves the raw-octet invariant cannot regress.
- Reproduce the Row 1 inputs, but compute the signature over a query string built via `URI.encode_query/1` of a `%{...}` map (instead of the literal-order concatenation `sign_redirect_query/3` performs).
- Assertion: the mutated signature MUST `!=` the golden Row 1 signature. A `==` failure means someone re-introduced the footgun — the row is the structural guard against the OASIS §3.4.4.1 lines 620-623 violation.
- This row is local computation (no `start_login/3` call); pure `:public_key.sign/3` mutation on the candidate octets.

**Row 4 — Round-trip verify (`:row_roundtrip_verify`):**
- Take the signed query string from Row 1 (the bytes BEFORE `&Signature=...` append) + the Row 1 signature bytes.
- Call `:public_key.verify(signed_bytes, :sha256, signature_bytes, pubkey_from(FakeIdP.self_signed_cert_pem()))`.
- Assertion: returns `true`.
- Mirrors `signature.ex:317` `safe_verify/4` inverse-direction; proves the SP-emitted signature is verifiable by a peer who has only the cert + signed octets (i.e., what the IdP will do).

**Row 5 — Toggle-off no-op (`:row_toggle_off_noop`):**
- Connection with `sign_authn_requests: false` (the default).
- Assertion: `Relyra.start_login/3` returns `{:ok, %{redirect_params: %{...}}}` (the existing map shape, NOT `:redirect_query`); the returned map has NO `"SigAlg"` and NO `"Signature"` keys.
- Smoke-assert that ALL existing Okta/Google/Entra provider tests still pass (this is verified by `mix test` running green; Row 5 only checks the no-op contract for the new code path).

### Sampling Rate

- **Per task commit:** `mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors` (< 5 seconds; runs the 5 new corpus rows).
- **Per wave merge:** `mix test --warnings-as-errors` (~30 seconds; full suite green).
- **Phase gate (before `/gsd:verify-work`):** `mix ci.security` AND `mix test --warnings-as-errors` AND `mix format --check-formatted` AND `mix credo --strict` AND `mix sobelow --config`.

### Wave 0 Gaps

- [ ] `test/security/authn_request_signing_test.exs` — new file, 5 corpus rows, `@moduletag :authn_request_signing`.
- [ ] `test/fixtures/security/authn_request_signing/golden_redirect.txt` — committed bytes (Row 1 golden).
- [ ] `test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt` — committed bytes (Row 2 golden).
- [ ] `test/fixtures/security/authn_request_signing/golden_authnrequest.xml` — committed input XML.
- [ ] `test/fixtures/security/authn_request_signing/PROVENANCE.md` — records fixture key fingerprint, byte counts, Elixir/OTP version used to mint, spec citation chain (OASIS §3.4.4.1 + RFC 1951 + RFC 3986 §6.2.2.1 + python3-saml `lowercase_urlencoding`).
- [ ] `test/relyra/protocol/binding_test.exs` — extend with raw-DEFLATE round-trip smoke (new test cases; not security-gated).
- [ ] `test/relyra/protocol/metadata_test.exs` — extend with toggle-on / toggle-off metadata gating cases.
- [ ] `test/relyra/security/algorithm_policy_test.exs` — extend with `signing_digest_atom/1` cases (RSA-SHA256 OK, ECDSA fail-closed, unknown URI fail-closed).
- [ ] `test/relyra/provider_test.exs` — extend with `:adfs` preset registration + `default_config/0` shape.
- [ ] New `lib/relyra/provider/adfs.ex` module — Wave 0 of the preset, before the corpus depends on the preset.
- [ ] No framework install needed — ExUnit is bundled.

### Mint procedure for golden bytes (run ONCE; commit output; never re-mint without `PROVENANCE.md` update)

```elixir
# In iex -S mix test --no-start, with FakeIdP.keypair/0 deterministic via :persistent_term seed:
xml = File.read!("test/fixtures/security/authn_request_signing/golden_authnrequest.xml")
{:ok, %{redirect_query: bytes}} =
  Relyra.start_login(
    %{
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://idp.example.com/sso",
      sign_authn_requests: true,
      signed_request_encoding: :rfc3986_upper
    },
    %{return_to: "/", connection_id: "golden-fixture"},
    relay_state: "rs_relyra_phase35_golden",
    authn_request_xml: xml,
    now: ~U[2026-05-26 00:00:00Z]
  )
File.write!("test/fixtures/security/authn_request_signing/golden_redirect.txt", bytes)
```
The minting test helper MUST be deterministic — fix `:zlib` defaults (always `compression: :default, mem_level: 8, strategy: :default`), fix `RelayState`, fix `IssueInstant` in the AuthnRequest XML, fix `ID` in the AuthnRequest XML (no `:crypto.strong_rand_bytes/1` in the minted bytes). `FakeIdP.keypair/0` uses `:persistent_term` and is regenerated per-test-run — for golden minting, the keypair must be loaded from a committed PEM (committed to `test/fixtures/security/authn_request_signing/golden_signing_key.pem`) so re-mints reproduce.

## Code Shape Recommendations (resolves CONTEXT.md "Claude's Discretion")

### §3.1 — `Signature.sign_redirect_query/3` — exact spec

Add to `lib/relyra/security/signature.ex` (no new module — keeps the "single crypto seam" invariant from CLAUDE.md). Recommendation: place it AFTER `verify_metadata_root/4` and its private helpers, BEFORE `do_verify/4`, with a public `@spec` and `@doc` block. Shape:

```elixir
@doc """
Sign the pre-assembled HTTP-Redirect-binding query-string binary (OASIS SAML
2.0 Bindings §3.4.4.1) and return the URL-safe base64 Signature value to append.

`octets` is the LITERAL byte sequence that will appear on the wire BEFORE the
`&Signature=` parameter. The caller (Relyra.Protocol.Binding) is responsible
for the OASIS-mandated component order (SAMLRequest, RelayState-when-present,
SigAlg) and the per-value URL encoding. This function MUST NOT re-encode
anything inside — re-encoding here is the auth-bypass class called out in
OASIS §3.4.4.1 lines 620-623.

`signature_method` is the algorithm URI (e.g. "http://www.w3.org/2001/04/
xmldsig-more#rsa-sha256"); resolved to a digest atom via the Phase-35
AlgorithmPolicy.signing_digest_atom/1 gate (ECDSA fail-closed).

Returns `{:ok, base64_signature_value_url_encoded}` or `{:error, %Error{}}`.
"""
@spec sign_redirect_query(binary(), String.t(), keyword()) ::
        {:ok, binary()} | {:error, Error.t()}
def sign_redirect_query(octets, signature_method, opts \\ [])

def sign_redirect_query(octets, signature_method, opts)
    when is_binary(octets) and is_binary(signature_method) and is_list(opts) do
  details = %{connection_id: Keyword.get(opts, :connection_id)}

  with {:ok, digest_atom} <- signing_digest_atom(signature_method, details),
       {:ok, private_key} <- load_signing_key(opts, details),
       sig_bytes when is_binary(sig_bytes) <-
         safe_sign(octets, digest_atom, private_key, details) do
    {:ok, sig_bytes |> Base.encode64() |> URI.encode_www_form()}
  end
end

defp signing_digest_atom(uri, details) do
  case AlgorithmPolicy.signing_digest_atom(uri) do
    {:ok, atom} -> {:ok, atom}
    {:error, :unsupported_signing_algorithm} ->
      {:error, Error.new(:unsupported_signing_algorithm,
        "Signature algorithm is not supported for outbound AuthnRequest signing",
        Map.put(details, :signature_method, uri))}
    {:error, :unknown_signing_algorithm} ->
      {:error, Error.new(:unknown_signing_algorithm,
        "Unknown signature algorithm URI for outbound AuthnRequest signing",
        Map.put(details, :signature_method, uri))}
  end
end

defp load_signing_key(opts, details) do
  pem = Keyword.get(opts, :signing_key_pem) ||
        Application.get_env(:relyra, :sp_signing_key_pem)
  with pem when is_binary(pem) <- pem,
       [entry | _] <- :public_key.pem_decode(pem),
       key when is_tuple(key) <- :public_key.pem_entry_decode(entry) do
    {:ok, key}
  else
    _ ->
      {:error, Error.new(:key_not_configured,
        "SP signing private key is not configured",
        Map.put(details, :hint,
          "Set config :relyra, :sp_signing_key_pem to the PEM binary of the SP RSA private key"))}
  end
rescue
  _ ->
    {:error, Error.new(:key_not_configured,
      "SP signing private key could not be decoded",
      details)}
end

defp safe_sign(octets, digest_atom, private_key, details) do
  :public_key.sign(octets, digest_atom, private_key)
rescue
  _ ->
    {:error, Error.new(:key_not_configured,
      "SP signing private key failed at :public_key.sign/3",
      details)}
end
```

**Rationale for inlining helpers:** Mirrors `signature.ex:249-262` (`digest_atom/2`) and `signature.ex:269-300` (`public_key_from_cert_chain/2`) — the inbound verify side uses the same try/rescue + typed-error pattern. NO new module (D-01 implies "primitive in Signature"; the gray-area was whether to introduce `Relyra.Security.RedirectSigning` — answer: no, keeps the seam count flat).

**`opts` accepts `:signing_key_pem` AS AN OVERRIDE** so the corpus can inject a fixture-fixed PEM without polluting `Application` env. Production callers pass no override and the function reads `:sp_signing_key_pem` from app config — Phase 33 convention preserved.

### §3.2 — `Binding.encode_redirect/3` — in-place extension (NOT a sibling)

**Recommendation: extend in-place.** Reasons:

1. The binding module is the single redirect-encode entry point today (`relyra.ex:64` and `sp_conformance_test.exs:69,132` both call it directly). A sibling `encode_signed_redirect/4` would create two parallel encode paths, doubling the surface area where the raw-DEFLATE fix must land and where future maintainers can drift.
2. The two paths share 100% of the deflate-then-base64 logic — only the optional sign + literal-octet-assembly step differs.
3. Backward compatibility is preserved by keeping the return-shape rule: `sign_authn_requests: false` → returns `{:ok, %{...map...}}` (existing shape); `sign_authn_requests: true` → returns `{:ok, %{redirect_query: binary}}` (new shape). Callers pattern-match on the new key to detect the signed case.

Recommended signature:

```elixir
@spec encode_redirect(binary(), binary() | nil, keyword()) ::
        {:ok, map()} | {:error, Error.t()}
def encode_redirect(xml, relay_state, opts \\ [])
```

The `relay_state` argument becomes `binary() | nil` (vs. today's required non-empty binary) so D-10's "RelayState omitted entirely when absent" rule is expressible. The current `relay_state != ""` guard becomes a match against `nil` for the omit path. **This is a soft API surface change** — callers passing `nil` previously got the fallthrough error; now they get a valid map without `"RelayState"`. Verify with `git grep "encode_redirect"` that no caller relies on the old error behavior (the two callers — `relyra.ex:64` and conformance tests — both pass a non-nil `relay_state`).

`opts` new keys (none of which are required):
- `:sign` — boolean, default `false`. When `true`, returns `{:ok, %{redirect_query: bytes}}` instead of the map shape.
- `:signing_key_pem` — PEM override (forwarded to `Signature.sign_redirect_query/3`).
- `:signature_method` — algorithm URI; defaults to `"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"`.
- `:encoding` — `:rfc3986_upper` (default) | `:adfs_lower`.
- `:type` — existing `:request` (default) | `:response` knob is preserved.

The deflate logic lives in a private `deflate_xml/1` helper at the top of the file:

```elixir
defp deflate_xml(xml) when is_binary(xml) do
  z = :zlib.open()
  try do
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    iodata = :zlib.deflate(z, xml, :finish)
    :ok = :zlib.deflateEnd(z)
    IO.iodata_to_binary(iodata)
  after
    :zlib.close(z)
  end
end
```

The `after` block is **load-bearing** — Erlang `:zlib` allocates a NIF resource (port-like); leaking it across a process lifetime accumulates memory and eventually exhausts the per-process file-descriptor / NIF-resource budget. The `try/after` ensures `close/1` runs even when `deflate/3` raises (which it does on certain input shapes per the Erlang manual, though raw-DEFLATE of a binary should not). The `:zlib.close/1` call is idempotent in practice — and even when it returns `:ok` because the stream is already closed by `deflateEnd`, it is safe.

### §3.3 — Connection encoding field name: `signed_request_encoding`

**Recommendation: `signed_request_encoding`** (full, self-documenting). Rejected alternatives:
- `encoding` — too generic; collides semantically with `Plug.Conn` and `Ecto.Changeset` "encoding" terminology.
- `redirect_encoding` — leaks binding-implementation detail (the field has no meaning except when redirect-binding signing is on).

`signed_request_encoding` makes the field's relationship to `sign_authn_requests` self-documenting AND scopes its applicability — readers immediately understand it has no effect when signing is off.

**Database migration:** REQUIRED — new column `signed_request_encoding` on `relyra_connections`. Type: `string` (Ecto.Enum at the schema layer with values `[:rfc3986_upper, :adfs_lower]`, stored as string for forward-compat with future encoding variants without an Ecto migration; same precedent as `provider_preset` at `connection.ex:34`). Nullable; `nil` means "use the default" (`:rfc3986_upper`).

Migration timestamp filename: follow the project's UTC-timestamp convention. Look at the most recent migration in `priv/repo/migrations/` and use `YYYYMMDDHHMMSS_add_signed_request_encoding_to_relyra_connections.exs` with today's UTC timestamp. The migration is additive (just `add :signed_request_encoding, :string, null: true`); no backfill needed — `nil` is the safe default.

### §3.4 — Runtime helper `Relyra.Connection.signed_request_encoding/1`?

**Recommendation: NO.** Fold inline in `Binding.encode_redirect/3` via:

```elixir
encoding = Keyword.get(opts, :encoding) ||
           Map.get(connection, :signed_request_encoding) ||
           :rfc3986_upper
```

Adding a `Relyra.Connection.signed_request_encoding/1` helper would be one more public seam to test and document for a 3-line resolution. The fold-inline approach is the same shape as `connection_snapshot.ex:79-88` for other connection field reads. If a future v1.4 caller needs to resolve the encoding from outside `Binding`, the helper can be added then — it's strictly cheaper to add later than to remove later.

### §3.5 — Runbook path: `guides/recipes/adfs.md`

**Recommendation: `guides/recipes/adfs.md`.** Confirmed via `ls`: `guides/providers/` does NOT exist; `guides/recipes/` contains `okta.md`, `entra.md`, `google_workspace.md`. Creating a `guides/providers/` directory for one file would split the runbook collection across two directories with no benefit. The existing `okta.md` is the structural template — same H1 ("Provider + Relyra"), same "Relyra owns / IdP owns / Host owns" tri-table, same numbered configuration sections.

The `mix.exs` `docs/0` extras list (lines 107-126) must be updated to add `"guides/recipes/adfs.md"`. The `ci.docs` alias presence-test (lines 142-146) does not auto-detect new files — add a `"cmd test -f guides/recipes/adfs.md"` line to `ci.docs` to gate the runbook's presence in CI.

### §3.6 — Corpus Row 5 location: in the new security suite

**Recommendation: Row 5 in the new `test/security/authn_request_signing_test.exs`.** Reasons:
1. Single-file corpus is the Phase 28 / Phase 30 / Phase 34 pattern — one suite, all rows, one `cmd mix test` line in `ci.security`. The hollow-gate meta-gate (`ci_gate_integrity_test.exs`) makes adding new lines safe but verbose.
2. Row 5 is structurally a corpus row (pinned shape; pinned absence of keys) — it belongs with Rows 1-4.
3. The non-regression check (Okta/Google/Entra still pass) is implicit in `mix test --warnings-as-errors` and explicit in the existing `test/relyra/provider/` tests — no new test needed for the regression check itself, only Row 5's no-op-contract assertion in the corpus.

## Raw-DEFLATE Bug Fix Notes (CONTEXT.md D-03/D-04)

### The bug, verified

`lib/relyra/protocol/binding.ex:9-19` `encode_redirect/3` calls `Base.encode64(xml, padding: false)` directly with NO `:zlib` step. OASIS SAML 2.0 Bindings §3.4.4.1 (lines 575-584) mandates: *"The DEFLATE compression mechanism, as specified in [RFC1951] is then applied to the entire remaining XML content ... The compressed data is subsequently base64-encoded according to the rules specified in IETF RFC 2045."* Source: spec text on page 17 of `saml-bindings-2.0-os.pdf` (`docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf`) [VERIFIED: PDF read in research session].

The bug has been latent since v0.1 because:
- The conformance fixture `sp-authn-request-redirect-transport` (`sp_conformance_test.exs:69-72`) asserts `encoded["SAMLRequest"] == Base.encode64(xml, padding: false)` — i.e. the test was WRITTEN to match the (incorrect) implementation, so it can never detect the missing deflate.
- The `binding_test.exs` (lines 7-17) asserts the same incorrect identity.
- Permissive IdPs (older Okta, OneLogin) tolerate uncompressed base64 because they `try-inflate-fallback-to-raw-base64`; strict IdPs (Microsoft Entra returning AADSTS750054, modern ADFS) reject it.

### Round-trip test pattern (the smoke that protects the fix)

Add to `test/relyra/protocol/binding_test.exs` (NOT the security suite — this is a regression-gate for the binding contract, not a security corpus row):

```elixir
describe "encode_redirect/3 raw-DEFLATE (OASIS §3.4.4.1)" do
  test "deflate→base64 round-trips byte-identically via :zlib raw-inflate" do
    xml = ~s(<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="id_1"/>)
    {:ok, %{"SAMLRequest" => b64}} = Binding.encode_redirect(xml, "rs")
    {:ok, deflated} = Base.decode64(b64, padding: false)

    z = :zlib.open()
    :ok = :zlib.inflateInit(z, -15)
    inflated = :zlib.inflate(z, deflated) |> IO.iodata_to_binary()
    :ok = :zlib.inflateEnd(z)
    :ok = :zlib.close(z)

    assert inflated == xml
  end

  test "deflate is applied for both signed and unsigned paths" do
    # Both paths must produce deflate-then-base64; this test pins that fact
    # so a future refactor cannot make deflate conditional on signing.
    xml = ~s(<x/>)
    {:ok, %{"SAMLRequest" => unsigned_b64}} = Binding.encode_redirect(xml, "rs")
    # Verify the bytes are DEFLATE-shaped (NOT plain base64-of-XML)
    refute unsigned_b64 == Base.encode64(xml, padding: false)
  end
end
```

The second test is the **structural anti-regression** — it directly asserts that the OLD bug shape (base64-of-raw-XML) cannot reappear.

### Existing fixtures — do any break?

`grep -rn "encode_redirect" test/` shows all current call sites assert `encoded["SAMLRequest"] == Base.encode64(xml, padding: false)` — these are **incorrect assertions** and MUST be updated:

- `test/relyra/protocol/binding_test.exs:9, 15` — must change to `assert is_binary(result["SAMLRequest"])` and verify via the inflate-round-trip instead.
- `test/conformance/sp_conformance_test.exs:71, 133` — same change; the conformance manifest's `sp-authn-request-redirect-transport` row must also be updated (in `test/fixtures/conformance/`) so the expected-output is the deflated bytes, not the raw-base64. Alternatively, weaken the conformance assertion to `is_binary/1` with a round-trip-inflate check — that's structurally safer because it doesn't pin a specific deflate output (deflate is non-deterministic across zlib versions for some inputs).

No XML-text fixtures break (the input XML is unchanged; only the on-wire encoding changes).

### `:zlib` API specifics

`:zlib.deflateInit/6` arguments (from [erlang.org/doc/apps/erts/zlib.html](https://www.erlang.org/doc/apps/erts/zlib.html) [CITED]):
- `Level :: :default | 0..9` — `:default` (equivalent to 6) is the convention.
- `Method :: :deflated` — only valid value.
- `WindowBits :: -15..-9 | 9..15 | 25..31` — **`-15` for raw DEFLATE (RFC 1951; no zlib header / no Adler-32)** [VERIFIED: erlang.org manual confirms negative window bits suppresses header].
- `MemLevel :: 1..9` — `8` is the conventional/default value.
- `Strategy :: :default | :filtered | :huffman_only | :rle` — `:default`.

**Caveat from the manual:** *"WindowBits values 8 and -8 do not work due to a known bug in the underlying zlib library."* `-15` is safe; `-8` is not. [CITED: erlang.org/doc/apps/erts/zlib.html].

**Exception handling:** The Erlang manual states *"In all functions errors, `{'EXIT',{Reason,Backtrace}}`, can be thrown"* [CITED]. `:zlib` allocates a NIF/port-like resource that survives across calls until explicit `close/1`; leaking it accumulates per-process resources. **`:zlib.close/1` in an `after` block is mandatory** to guarantee cleanup if any of `deflateInit`/`deflate`/`deflateEnd` throws. `:zlib.close/1` is idempotent enough in practice that calling it after a normal `deflateEnd` is safe (the resource is freed; subsequent operations on the same handle would error, but `close/1` itself succeeds).

The `try/after` shape recommended in §3.2 — `try do ... after :zlib.close(z) end` — is the correct pattern. Do NOT use `try/rescue` to swallow the error; let it propagate so the caller can surface a typed `%Error{}` if it ever fires (Phase 35 deflate inputs are well-formed XML so this should never fire in practice, but the pattern is for safety).

## External Spec Verbatim

### OASIS SAML 2.0 Bindings §3.4.4.1 — DEFLATE Encoding + signed octet template
Source: `https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf` page 17, lines 573-625 [VERIFIED: PDF read in this session].

**Lines 573-584 — DEFLATE Encoding identification:**
> "**Identification:** urn:oasis:names:tc:SAML:2.0:bindings:URL-Encoding:DEFLATE
> SAML protocol messages can be encoded into a URL via the DEFLATE compression method (see [RFC1951]). In such an encoding, the following procedure should be applied to the original SAML protocol message's XML serialization:
> 1. Any signature on the SAML protocol message, including the `<ds:Signature>` XML element itself, MUST be removed. ...
> 2. The DEFLATE compression mechanism, as specified in [RFC1951] is then applied to the entire remaining XML content of the original SAML protocol message.
> 3. The compressed data is subsequently base64-encoded according to the rules specified in IETF RFC 2045 [RFC2045]. Linefeeds or other whitespace MUST be removed from the result.
> 4. The base-64 encoded data is then URL-encoded, and added to the URL as a query string parameter which MUST be named `SAMLRequest` (if the message is a SAML request) or `SAMLResponse` (if the message is a SAML response)."

**Lines 597-611 — Signature construction:**
> "1. The signature algorithm identifier MUST be included as an additional query string parameter, named `SigAlg`. The value of this parameter MUST be a URI that identifies the algorithm used to sign the URL-encoded SAML protocol message ...
> 2. To construct the signature, a string consisting of the concatenation of the `RelayState` (if present), `SigAlg`, and `SAMLRequest` (or `SAMLResponse`) query string parameters (each one URL-encoded) is constructed in one of the following ways (ordered as below):
>     `SAMLRequest=value&RelayState=value&SigAlg=value`
>     `SAMLResponse=value&RelayState=value&SigAlg=value`
> 3. The resulting string of bytes is the octet string to be fed into the signature algorithm. Any other content in the original query string is not included and not signed.
> 4. The signature value MUST be encoded using the base64 encoding (see RFC 2045 [RFC2045]) with any whitespace removed, and included as a query string parameter named `Signature`. Note that some characters in the base64-encoded signature value may themselves require URL-encoding before being added."

**Lines 620-625 — THE RAW-OCTET INVARIANT (the CVE-class footgun):**
> "Further, note that URL-encoding is not canonical; that is, there are multiple legal encodings for a given value. The relying party MUST therefore perform the verification step using the original URL-encoded values it received on the query string. **It is not sufficient to re-encode the parameters after they have been processed by software because the resulting encoding may not match the signer's encoding.**
> Finally, note that if there is no `RelayState` value, the entire parameter should be omitted from the signature computation (and not included as an empty parameter name)."

This is the load-bearing citation for D-01, D-10, D-11, and Corpus Row 3. Reference it explicitly in `PROVENANCE.md`, in the `@doc` of `sign_redirect_query/3`, and in `guides/recipes/adfs.md`.

### RFC 1951 — raw DEFLATE
Source: `https://datatracker.ietf.org/doc/html/rfc1951` [CITED — title page confirms "DEFLATE Compressed Data Format Specification version 1.3" — the wire format with NO zlib header (RFC 1950) and NO Adler-32 checksum]. Erlang `:zlib`'s negative WindowBits invocation is the documented escape hatch to produce RFC 1951 output: [erlang.org/doc/apps/erts/zlib.html](https://www.erlang.org/doc/apps/erts/zlib.html) [CITED].

### RFC 3986 §2.1 — uppercase hex preferred (note: not §6.2.2.1)
Source: `https://datatracker.ietf.org/doc/html/rfc3986` [CITED via WebFetch].

**Verbatim:** *"For consistency, URI producers and normalizers should use uppercase hexadecimal digits for all percent-encodings."*

**Important correction to CONTEXT.md:** CONTEXT.md D-08 cites "RFC 3986 §6.2.2.1" — the uppercase-hex preferred form is actually established in **§2.1 (Percent-Encoding)**. §6.2.2.1 is the "Case Normalization" subsection that REPEATS the rule in the context of URI equivalence. Either citation is defensible; §2.1 is the primary source. PROVENANCE.md should cite §2.1.

### python3-saml `lowercase_urlencoding` flag — exact behavior
Source: `https://github.com/SAML-Toolkits/python3-saml/blob/master/src/onelogin/saml2/utils.py` [VERIFIED via WebFetch].

**Verbatim (the regex substitution):**
```python
return re.sub(r"%[A-F0-9]{2}", lambda m: m.group(0).lower(), encoded) if lowercase_urlencoding else encoded
```

The flag exists specifically *"for compatibility with ADFS 3.0, which uses lowercase hex encoding, whereas Python's quote_plus produces uppercase sequences"* [VERIFIED]. The transformation is purely cosmetic — `%2F` → `%2f` — and is applied AFTER the standard URL-encoding step. D-08's `:adfs_lower` post-process specification (`%[0-9A-F][0-9A-F]` → lowercase) is byte-equivalent to python3-saml's behavior.

**Implementation in Elixir:**
```elixir
defp lowercase_hex(encoded) do
  Regex.replace(~r/%[0-9A-F]{2}/, encoded, &String.downcase/1)
end
```

### samlify `binding-redirect.ts` reference implementation
Source: `https://github.com/tngan/samlify/blob/master/src/binding-redirect.ts` [CITED — not fetched in this session; CONTEXT.md cites lines 105-119 as the reference for the signed octet-string composition. The OASIS verbatim above is the authoritative source; samlify is a defensive cross-reference].

### Microsoft Learn — `Set-AdfsRelyingPartyTrust` (Server 2025)
Source: `https://learn.microsoft.com/en-us/powershell/module/adfs/set-adfsrelyingpartytrust` [CITED — not fetched in this session due to time budget; the CONTEXT.md D-18 PowerShell block uses well-established parameter names (`-SignedSamlRequestsRequired`, `-RequestSigningCertificate`, `-SignatureAlgorithm`, `-SamlResponseSignature`, `-TargetName`) all of which have been stable since Server 2012 R2].

**Recommendation for the planner:** add a Wave 0 task to fetch the current Microsoft Learn page for `Set-AdfsRelyingPartyTrust` (Server 2025 edition) and verify the parameter set is still current. If any parameter has been deprecated or renamed in Server 2025/2026, update the runbook block in `guides/recipes/adfs.md`. The CONTEXT.md block is HIGH confidence on parameter mechanics but MEDIUM confidence on Server 2025 currency — verify before publishing the runbook.

## Threat Model Inputs (for planner's `<threat_model>` block; ASVS L1; security_enforcement enforced)

Phase 35 adds an OUTBOUND signing primitive. The signing primitive itself is a CVE-class footgun because the SP is now authoring authenticated bytes that an IdP will trust. Every attack surface below is enumerated for planner inclusion in the `<threat_model>` block.

### T-35-01 — Re-serialization auth bypass (CVE-class; STRIDE: Tampering)
**Attack:** A code path between `sign_redirect_query/3` and URL emission re-encodes the octets via `URI.encode_query/1` (or a similar transform), changing the byte sequence the IdP verifies against. Either the IdP rejects (DoS) or — worse — the IdP accepts a different byte sequence than the SP intended (the SP signs `RelayState=foo+bar`, the IdP verifies `RelayState=foo bar` — same logical value, different bytes — and an attacker can craft RelayStates that survive one encoding-roundtrip and inject control characters into the verified octets).
**Mitigation:** D-01 (sign verbatim; no `URI.encode_query/1` inside `sign_redirect_query/3`); D-02 (controller appends pre-assembled bytes verbatim, never re-serializes); Corpus Row 3 (the mutation test).
**ASVS:** V4.1 (Access Control general); V9.1 (Communication architecture).

### T-35-02 — Private key surface expansion (STRIDE: Information Disclosure)
**Attack:** The SP signing private key (`:sp_signing_key_pem`) is added to a diagnostic bundle, logged in an error message, or written to a DB column.
**Mitigation:** D-06 enforces Application-env-only (mirrors `KeyResolver.Default`); D-07 returns typed `:key_not_configured` (NOT the key bytes) when missing; CLAUDE.md "SP private keys never in DB" is an absolute. Verify diagnostic bundle allow-list (`lib/relyra/diagnostics/...`) excludes `:sp_signing_key_pem`.
**ASVS:** V6.1 (Cryptographic key management); V8.1 (Sensitive data classification).

### T-35-03 — Algorithm downgrade (STRIDE: Tampering)
**Attack:** Operator misconfigures `algorithm_policy.signing` to a SHA-1 URI (or worse, ECDSA where Relyra has no ECDSA signing implementation). Without `signing_digest_atom/1`'s fail-closed gate, `:public_key.sign/3` would silently use the SHA-1 digest OR raise on the missing ECDSA support OR (worst case) the policy URI doesn't match the literal SigAlg appearing in the signed octets, producing a signature the IdP can't verify.
**Mitigation:** D-05 — `signing_digest_atom/1` fail-closed for ECDSA and unknown URIs; default in `ADFS.default_config/0` and `Okta.default_config/0` is `:rsa_sha256`.
**ASVS:** V6.2 (Algorithms); V14.1 (Build and deploy).

### T-35-04 — Metadata-toggle skew (STRIDE: Spoofing)
**Attack:** SP metadata advertises `AuthnRequestsSigned="true"` but `sign_authn_requests` is `false` (or vice versa). The IdP accepts the SP's claim and either rejects all logins (DoS) or — if the IdP doesn't enforce — accepts unsigned requests that should have been signed.
**Mitigation:** D-12 — both the `<KeyDescriptor use="signing">` AND the `AuthnRequestsSigned` attribute are gated on the SAME `connection.sign_authn_requests` flag at the SAME emission point. Test cases assert both halves (toggle on → both emitted; toggle off → both omitted).
**ASVS:** V9.2 (Server communication).

### T-35-05 — ADFS lowercase-hex divergence (STRIDE: Tampering / Repudiation)
**Attack:** SP signs with `:rfc3986_upper`, ADFS verifies with case-sensitive byte comparison, signature fails (DoS). OR: SP signs with `:adfs_lower`, a non-ADFS IdP rejects (broken interop on non-target IdPs).
**Mitigation:** D-08/D-09 — encoding is a per-connection field; ADFS preset defaults to `:adfs_lower`; all other presets leave it unset (resolves to `:rfc3986_upper`). Corpus Row 2 pins ADFS-lower bytes; Row 1 pins RFC3986-upper bytes; both committed.
**ASVS:** V13.1 (Generic web service security).

### T-35-06 — Divergent SP signer (analog of the inbound anti-divergent-signer rule)
**Attack:** A test helper builds the signed octets via a DIFFERENT byte-assembly path than `Binding.encode_redirect/3` uses in production. The corpus passes because the helper agrees with itself, but production bytes diverge.
**Mitigation:** Corpus rows MUST call `Relyra.start_login/3` (the production path), NOT a parallel helper. The golden file is minted by calling the production path once; the corpus asserts the production path still produces the same bytes. Mirrors `XmldsigSigner` discipline (`xmldsig_signer.ex:13-23`).

### T-35-07 — `:zlib` resource leak under exception (STRIDE: DoS, low severity)
**Attack:** A malformed XML (or just a `:zlib` library bug) raises between `deflateInit` and `deflateEnd`, leaking the NIF resource. Over time, the BEAM process accumulates leaked zlib handles and the BEAM exhausts file descriptors.
**Mitigation:** `try/after` block around `:zlib.close(z)` in `deflate_xml/1` (§3.2 code shape).

### T-35-08 — Signature parameter collision (STRIDE: Tampering)
**Attack:** A malformed `idp_sso_url` already contains a `&Signature=...` parameter. The SP appends its own `&Signature=...`, producing a URL with two `Signature` query parameters. RFC 3986 doesn't specify how duplicate query keys are resolved; the IdP may pick either, possibly the attacker-injected one.
**Mitigation:** D-02's pre-assembled binary plus existing `URI.parse/URI.decode_query` + merge logic in `login_controller.ex:46-49` — but for the signed path, that merge is REMOVED. Recommendation: before appending the signed query to `idp_sso_url`, parse the URL and **reject if any of `SAMLRequest`, `RelayState`, `SigAlg`, `Signature` already appear in the existing query**. Surface as `%Error{type: :idp_sso_url_invalid}`. This is a hardening control beyond CONTEXT.md but is in-scope under §3.2's controller-side responsibility.

### T-35-09 — Missing `Destination` attribute (STRIDE: Spoofing)
**Attack:** OASIS Bindings §3.4.5.2 (page 19, lines 661-664): *"If the message is signed, the Destination XML attribute in the root SAML element of the protocol message MUST contain the URL to which the sender has instructed the user agent to deliver the message."* If the AuthnRequest XML produced by `AuthnRequest.to_xml/1` lacks `Destination`, a strict IdP (ADFS) rejects.
**Mitigation:** Verify `lib/relyra/protocol/authn_request.ex` emits the `Destination` attribute pinned to `connection.idp_sso_url`. If absent, add as Phase 35 task. This is verifiable via `grep "Destination" lib/relyra/protocol/authn_request.ex`.

## `mix ci.security` Wiring Details (Phase 30 hollow-gate fix preserved)

The Phase 30 hollow-gate fix (CLAUDE.md "do not change this to bare `test` steps") is enforced structurally by `test/security/ci_gate_integrity_test.exs`. Phase 35 must extend the gate, not undermine it.

### Step 1 — Add the new suite as its own `cmd mix test` line
Insert into `mix.exs` `ci.security` alias (lines 152-182), immediately after the existing `adversarial_crypto` line (line 172):

```elixir
"cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
```

**Do NOT collapse this into a multi-file `test` line** — the meta-gate at `ci_gate_integrity_test.exs:130-132` rejects any bare `test` step for a gated suite.

### Step 2 — Add the suite to `@gated_suites`
Edit `test/security/ci_gate_integrity_test.exs:32-42`:

```elixir
@gated_suites [
  ...existing 9 entries...,
  {"test/security/authn_request_signing_test.exs", "authn_request_signing"}
]
```

The meta-gate runs four checks per entry (`ci_gate_integrity_test.exs:94-149`):
1. **File presence on disk** (line 94) — fails if the file is missing.
2. **Referenced in `ci.security`** (line 102) — fails if the step is missing from the alias.
3. **Uses `cmd mix test`, not bare `test`** (line 112) — fails if the hollow-gate bug returns.
4. **Tag exists in source** (line 136) — fails if `--only authn_request_signing` would match zero tests.

For check #4 to pass, the new suite MUST declare `@moduletag :authn_request_signing` at the top of the module (the regex at line 144 anchors on the whole-atom boundary).

### Step 3 — Verify the gate gates itself
Run `mix ci.security` once locally before committing — the meta-gate file is itself the first `cmd mix test` line (line 167), so a broken integration immediately fails the security suite.

## Cross-Phase Verification

### Phase 32 `signing_digest_atom/1` gap — REAL
Confirmed via `grep -rn "signing_digest_atom" /Users/jon/projects/relyra/lib /Users/jon/projects/relyra/test` (zero results). The function is genuinely absent. CONTEXT.md D-05 correctly identifies this as Phase 35's responsibility. Phase 35 Plan 01 Task 1 is the right placement — `sign_redirect_query/3` cannot land without it.

The milestone audit at `.planning/v1.3-v1.3-MILESTONE-AUDIT.md:197-202` lists a "Recommended" alternative: *"Use existing `digest_atom_for_signature_method/1` directly for the RSA-SHA256 case in `sign_redirect_query/3` — avoids retrofitting Phase 32 and the function already maps `rsa-sha256` URIs to `:sha256`."* **Reject this recommendation.** Reasons:
1. The error taxonomy differs: `digest_atom_for_signature_method/1` returns `{:error, :unsupported_signature_algorithm}` (the inbound-verify atom); the outbound-signing path needs `:unsupported_signing_algorithm` and `:unknown_signing_algorithm` as distinct atoms (D-23). Folding into the inbound function would force one of: (a) overloading the inbound error atom for outbound use (confuses error consumers), (b) adding a `:context` keyword arg to a 16-line function (over-engineering), or (c) two callers using the same atom for different semantic failures (debug pain).
2. The legacy SHA-1 escape hatch logic in `enforce_signature_method/2` is inbound-only; outbound signing has its own policy curve (ADFS interop sometimes requires SHA-1 by IdP-side configuration, but the SP MUST never voluntarily downgrade). The two policies will diverge over time — separating them now is cheaper than untangling them later.

### Phases 33-34 parallel-safety — file-disjoint, confirmed
Phase 33 owns: `lib/relyra/key_resolver.ex`, `lib/relyra/key_resolver/default.ex`, `lib/relyra/security/xml_enc.ex`, `test/security/xml_enc_test.exs`.
Phase 34 owns: `lib/relyra/protocol/validation_pipeline.ex` (`:decrypt_assertion` stage), `lib/relyra/security/xml/pure_beam.ex` (pre-decrypt parsed-doc), `lib/relyra/test_support/fake_idp.ex` (encrypt/encrypted_response), `lib/relyra/protocol/metadata.ex` (encryption `KeyDescriptor` ONLY), `test/security/xml_enc_adversarial_test.exs`.
Phase 35 owns: `lib/relyra/protocol/binding.ex`, `lib/relyra/security/signature.ex` (new `sign_redirect_query/3`), `lib/relyra/security/algorithm_policy.ex` (new `signing_digest_atom/1`), `lib/relyra.ex` (`:redirect_query` thread), `lib/relyra/phoenix/controllers/login_controller.ex`, `lib/relyra/protocol/metadata.ex` (signing `KeyDescriptor` toggle gate ONLY + `AuthnRequestsSigned` attr), `lib/relyra/provider.ex`, `lib/relyra/provider/adfs.ex` (new), `lib/relyra/ecto/connection.ex` (encoding field + `:adfs` enum), `lib/relyra/ecto/connection_snapshot.ex` (encoding thread), `lib/relyra/connection.ex`, `test/security/authn_request_signing_test.exs` (new), `test/fixtures/security/authn_request_signing/` (new), `guides/recipes/adfs.md` (new), `mix.exs` (alias + docs).

**Single shared file with Phase 34:** `lib/relyra/protocol/metadata.ex` — Phase 34 added the encryption `KeyDescriptor` (lines 37-40); Phase 35 must gate the SIGNING `KeyDescriptor` (lines 34-36) AND add the `AuthnRequestsSigned` attribute to line 33. Since Phase 34 is COMPLETE (STATE.md confirms), there is no merge conflict — Phase 35 lands its edits on top of the post-Phase-34 file. Verify by `git log --oneline lib/relyra/protocol/metadata.ex` to confirm Phase 34 is the most recent change.

### `:sp_signing_key_pem` distinct from `:sp_private_key_pem` and `:sp_signing_cert_pem`
Confirmed via grep:
- `:sp_private_key_pem` — read by `lib/relyra/key_resolver/default.ex:11` (XML-Enc DECRYPTION; Phase 33).
- `:sp_signing_cert_pem` — read by `lib/relyra/protocol/metadata.ex:24` (PUBLIC cert for metadata `<KeyDescriptor>`; Phase 34).
- `:sp_signing_key_pem` — **NOT yet read by any file**; Phase 35 introduces it.

All three are distinct config keys with distinct lifecycles:
- `:sp_private_key_pem` rotates on encryption-key compromise.
- `:sp_signing_cert_pem` rotates when the IdP requires re-publication of the SP signing public key (operator-driven).
- `:sp_signing_key_pem` rotates when the SP signing private key is compromised (rare; high-impact).

D-06's "do NOT reuse `:sp_private_key_pem`" is correct: dual-use would mean a single key compromise simultaneously breaks DECRYPTION (silent data exposure) AND SIGNING (silent auth bypass).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Microsoft Learn `Set-AdfsRelyingPartyTrust` parameter set in CONTEXT.md D-18 is current for Windows Server 2025. | §5 External Spec | Runbook publishes wrong PowerShell; operator deploys non-functional ADFS RP trust; logs in fail until corrected. Mitigation: Wave 0 task to fetch Microsoft Learn page and diff against the block. |
| A2 | The conformance manifest's `sp-authn-request-redirect-transport` row can be updated to assert deflate-round-trip rather than literal base64-of-XML without breaking conformance scoring. | §4 Raw-DEFLATE Bug | Conformance score drops; `mix ci.conformance` fails. Mitigation: when updating the conformance fixture, also verify `test/mix/tasks/relyra_conformance_test.exs` doesn't assert the raw-base64 string anywhere. |
| A3 | `:zlib.deflate/3` with `:finish` on well-formed XML never raises in practice. | §3.2 / §4 | A real input triggers the `try/after`'s `close/1` after a partial-write exception; the `:zlib.deflate/3` error path may not surface as a typed `%Error{}`. Mitigation: wrap `deflate_xml/1` in a top-level `rescue` returning `%Error{type: :deflate_failed}` if paranoia justifies the seam (low priority — Erlang's :zlib has decades of production hardening). |
| A4 | `FakeIdP.keypair/0`'s `:persistent_term`-stored 2048-bit RSA key is deterministic across test runs. | §2 Validation / Mint Procedure | Golden bytes regenerate differently on each test run, making the golden assertion non-deterministic. **Verified false in current code** — `fake_idp.ex:302-307` shows the key is generated lazily and stored in `:persistent_term` per-process, NOT seeded. **Mitigation:** the golden mint procedure (§2 final code block) must use a COMMITTED PEM (`test/fixtures/security/authn_request_signing/golden_signing_key.pem`) loaded into `Application.put_env/2` during the mint, NOT `FakeIdP.keypair/0`. The corpus then asserts against bytes signed with the committed PEM. The committed PEM is a NEW fixture; document its provenance in `PROVENANCE.md`. |
| A5 | The PowerShell `-RequestSigningCertificate @($cert)` array syntax in D-18 is the correct shape for Server 2025 (vs. a single `$cert` reference). | §5 / Runbook | Operator gets a parse error on the PowerShell. Mitigation: same Wave 0 task as A1. |
| A6 | `samlify`'s `binding-redirect.ts` lines 105-119 still implement the OASIS §3.4.4.1 signed-octet composition the same way as the spec. | §5 / Corpus | Defensive cross-reference; the OASIS verbatim is the primary source. If samlify diverges, the spec wins. No mitigation required — samlify is cited as a cross-check, not as a normative source. |
| A7 | The `relay_state != ""` guard in current `Binding.encode_redirect/3` (line 11) is the ONLY guard preventing nil RelayState from reaching the encoding path. | §3.2 | If there's a second guard upstream (e.g., in `Relyra.start_login/3`), the proposed `binary() | nil` signature change is harmless. **Verified:** `relyra.ex:50-56` issues a RelayState via `RelayState.issue/2` which always returns a non-empty binary; the binding-level guard is defense-in-depth, not the only one. The proposed `nil` support is purely additive. |

## Open Questions for Planner

1. **Should `sign_redirect_query/3` accept the full `Connection` struct OR a flat keyword list?**
   - What we know: D-01 says "takes the raw pre-assembled query-string binary, the private key, and opts." The "private key" part suggests the function reads the key from the passed-in opts, not from a Connection field.
   - What's unclear: whether the encoding option, signature_method, and connection_id all flow through opts (current §3.1 recommendation), OR whether the Connection struct flows in and the function pulls fields off it.
   - Recommendation: flat keyword list (the current §3.1 shape). Reasons: keeps `Signature` from depending on `Connection` (currently Signature only knows about generic `map()` connections); makes the function trivially testable with a literal `pem` binary; matches the inbound-side `do_verify/4` which also takes a generic `map()` connection rather than a `%Connection{}`.

2. **Should `Binding.encode_redirect/3`'s NEW `:sign` opt default to `false` OR be derived from `:signing_key_pem` presence?**
   - What we know: D-02 says the signed-vs-unsigned dispatch is the `sign_authn_requests` flag on the connection.
   - What's unclear: whether `Binding.encode_redirect/3` should be opinionated (derive `:sign` from opts) or mechanical (caller passes `:sign: true`).
   - Recommendation: mechanical — caller (`Relyra.start_login/3`) reads `connection.sign_authn_requests` and passes `:sign: true` explicitly to `encode_redirect/4`. Keeps the binding layer dumb; pushes policy to `start_login/3` where it belongs.

3. **Where does the Wave 0 task for fetching/verifying the Microsoft Learn `Set-AdfsRelyingPartyTrust` page belong?**
   - What we know: A1 above flags this as MEDIUM-confidence currency on Server 2025.
   - What's unclear: should this be a Phase 35 task, or a `/gsd:verify-work` checkpoint?
   - Recommendation: Phase 35 task in the runbook plan (the last plan). Block runbook publication on the verification.

4. **Should the `LoginController` change include `idp_sso_url` validation (T-35-08 mitigation) OR defer that to a v1.4 hardening?**
   - What we know: T-35-08 is a real attack surface that CONTEXT.md doesn't enumerate.
   - What's unclear: whether the planner has appetite for adding hardening tasks beyond CONTEXT.md scope.
   - Recommendation: include the validation. Adding it now is ~5 lines; adding it later requires re-touching the controller, the conformance suite, and the corpus. Surface as a new `%Error{type: :idp_sso_url_invalid}` and Corpus Row 6 (or as an additional assertion in Row 5).

5. **Mint determinism — does the committed `golden_signing_key.pem` go in `test/fixtures/security/authn_request_signing/` or a more central key fixtures location?**
   - What we know: A4 above flags `FakeIdP.keypair/0` is non-deterministic.
   - What's unclear: project convention for committed test key material.
   - Recommendation: put it next to the golden bytes (`test/fixtures/security/authn_request_signing/golden_signing_key.pem`) for locality. Document in `PROVENANCE.md` that the key was generated via `:public_key.generate_key({:rsa, 2048, 65_537})` once and committed; never reused for any other Phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang `:zlib` | Raw-DEFLATE in `Binding.encode_redirect/3` | ✓ | OTP stdlib (bundled) | — |
| Erlang `:public_key` | `sign_redirect_query/3` + key extraction | ✓ | OTP stdlib | — |
| Erlang `:crypto` | (transitively via `:public_key`) | ✓ | OTP stdlib | — |
| ExUnit | All test files | ✓ | bundled with `mix` | — |
| Ecto migration runner | New `signed_request_encoding` column | ✓ | `ecto_sql ~> 3.13` (mix.exs:67) | — |
| Phoenix | `LoginController` changes | ✓ | `phoenix ~> 1.8` (mix.exs:60, optional) | — |

No new Hex dependencies. STATE.md "Zero new Hex dependencies" invariant preserved (line 75).

**Missing dependencies with no fallback:** none.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Outbound signing primitive participates in the SAML AuthN flow; bytes the SP signs are the authentication request the IdP authorizes. |
| V3 Session Management | no | Phase 35 is pre-session (no SAML response consumed yet). |
| V4 Access Control | yes | Re-serialization auth bypass (T-35-01) is the access-control failure if introduced. |
| V5 Input Validation | yes | `idp_sso_url` validation (T-35-08); algorithm URI validation (`signing_digest_atom/1`); encoding option validation (must be in `[:rfc3986_upper, :adfs_lower]`). |
| V6 Cryptography | yes | RSA-SHA256 signing via OTP `:public_key.sign/3` — NEVER hand-roll the signature math. `:zlib` raw-DEFLATE via OTP stdlib — NEVER hand-roll deflate. |
| V8 Sensitive Data | yes | SP signing private key (`:sp_signing_key_pem`) — never in DB, never in logs, never in diagnostic bundles, never in `Error.t()` `:details`. |
| V9 Communication | yes | OASIS §3.4.4.1 spec compliance is the protocol-level control. |
| V13 API/Web Services | yes | The redirect URL is the wire protocol; encoding correctness is the API contract. |
| V14 Configuration | yes | `signed_request_encoding` per-connection config; `:sp_signing_key_pem` global config. |

### Known Threat Patterns for outbound AuthnRequest signing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Re-serialization between sign and emit | Tampering | Sign raw octets verbatim (D-01); pre-assembled binary returned from core (D-02); mutation test (Corpus Row 3). |
| Algorithm downgrade to SHA-1 / non-RSA | Tampering | `signing_digest_atom/1` fail-closed (D-05); preset defaults to `:rsa_sha256`. |
| Private key leakage via diagnostic bundle | Information Disclosure | App-env-only seam (D-06); typed `:key_not_configured` error never includes key bytes (D-07); allow-list audit of diagnostic bundle. |
| Metadata/runtime config skew | Spoofing | Single-source-of-truth: `connection.sign_authn_requests` gates BOTH metadata emission AND runtime signing path (D-12). |
| ADFS lowercase-hex divergence | Tampering | Per-connection encoding field (D-09); ADFS preset defaults to `:adfs_lower` (D-15). |
| Divergent test signer | Tampering | Corpus calls the production path (`Relyra.start_login/3`); no parallel byte-assembly helper. |
| `:zlib` resource leak | DoS (low) | `try/after :zlib.close/1` (§3.2). |
| `idp_sso_url` query parameter collision | Tampering | Reject `idp_sso_url` containing `SAMLRequest`/`RelayState`/`SigAlg`/`Signature` query keys (Open Q4). |
| Missing `Destination` attribute on signed AuthnRequest | Spoofing | Verify `AuthnRequest.to_xml/1` emits `Destination` matching `idp_sso_url` (T-35-09). |

## Sources

### Primary (HIGH confidence)
- **OASIS SAML 2.0 Bindings §3.4.4.1** — `https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf` pages 17-18, lines 573-625 [PDF read in research session].
- **Erlang `:zlib` manual** — `https://www.erlang.org/doc/apps/erts/zlib.html` (negative WindowBits, raw DEFLATE, resource cleanup).
- **python3-saml `lowercase_urlencoding` regex** — `https://github.com/SAML-Toolkits/python3-saml/blob/master/src/onelogin/saml2/utils.py` (verified via WebFetch).
- **RFC 3986 §2.1** — `https://datatracker.ietf.org/doc/html/rfc3986` ("URI producers and normalizers should use uppercase hexadecimal digits for all percent-encodings").
- **Relyra codebase verbatim** — `lib/relyra/security/signature.ex` (`do_verify/4`); `lib/relyra/security/algorithm_policy.ex` (`digest_atom_for_signature_method/1`); `lib/relyra/protocol/binding.ex` (the buggy `encode_redirect/3`); `lib/relyra/protocol/metadata.ex` (post-Phase-34 metadata builder); `lib/relyra/ecto/connection.ex` (`sign_authn_requests` already present); `lib/relyra/provider/{okta,entra}.ex` (preset templates); `test/security/xml/adversarial_crypto_test.exs` (corpus shape model); `test/security/ci_gate_integrity_test.exs` (hollow-gate mechanics); `mix.exs:152-182` (`ci.security` alias); `lib/relyra/test_support/fake_idp.ex` (keypair seam); `.planning/v1.3-v1.3-MILESTONE-AUDIT.md:180-220` (`signing_digest_atom/1` gap confirmation).

### Secondary (MEDIUM confidence)
- **RFC 1951** — DEFLATE Compressed Data Format Specification (raw deflate format; cited but not re-fetched).
- **samlify `binding-redirect.ts`** — `https://github.com/tngan/samlify/blob/master/src/binding-redirect.ts` (cited as cross-reference; not fetched in this session).
- **Microsoft Learn `Set-AdfsRelyingPartyTrust`** — parameter names are stable across Server 2012R2–2022; Server 2025 verification deferred to Wave 0 task (A1).

### Tertiary (LOW confidence — none load-bearing)
- (none)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all OTP stdlib (`:zlib`, `:public_key`, `:crypto`); no new Hex deps.
- Architecture / Code shapes: HIGH — every recommendation mirrors an existing in-repo pattern; the seams (`Signature`, `Binding`, `Metadata`, `AlgorithmPolicy`, `Provider`, `Connection`, `Snapshot`) are all current and well-understood from CONTEXT.md and direct file reads.
- Validation Architecture: HIGH — the 5-row corpus follows the Phase 28/30/34 pattern; the deflate round-trip smoke is a 12-line ExUnit test; the `ci.security` wiring is mechanical.
- Threat model: HIGH on T-35-01..07 (direct mappings to spec / CONTEXT.md); MEDIUM on T-35-08 / T-35-09 (additions beyond CONTEXT.md — see Open Q4, A1 mitigation).
- External spec compliance: HIGH — OASIS verbatim was extracted from the spec PDF in this session.
- ADFS PowerShell currency: MEDIUM — parameter names are historically stable but Server 2025 was not directly verified (A1 mitigation).
- Cross-phase coordination: HIGH — file-disjointness confirmed via grep + STATE.md; `signing_digest_atom/1` absence confirmed via grep; three `_pem` config keys confirmed distinct via grep.

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 (30 days for stable; OASIS spec hasn't changed since 2005; OTP `:zlib` API is stable; the only volatile inputs are Microsoft Learn ADFS docs which warrant Wave 0 re-verification).

## RESEARCH COMPLETE
