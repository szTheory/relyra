# Phase 35: Signed AuthnRequests + ADFS Preset - Context

**Gathered:** 2026-05-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement HTTP-Redirect-binding AuthnRequest signing for `WantAuthnRequestsSigned` IdPs
(ADFS, locked-down Shibboleth): sign the raw pre-assembled query-string octets verbatim
(RSA-SHA256 default; never re-serialized); gate the existing metadata signing
`KeyDescriptor` + add `AuthnRequestsSigned="true"` on the `<SPSSODescriptor>` element when
`sign_authn_requests: true`; ship the ADFS provider preset and operator runbook; add a
bit-for-bit golden-output adversarial corpus to `mix ci.security`.

**In scope:**
- `lib/relyra/security/algorithm_policy.ex` — add `signing_digest_atom/1` (Phase 32 gap)
- `lib/relyra/protocol/binding.ex` — add raw-DEFLATE before base64; add
  `encode_signed_redirect/4` (or extend `encode_redirect/3`) that returns the pre-assembled
  signed query-string binary
- `lib/relyra/security/signature.ex` — add `sign_redirect_query/3` (SP-side signing primitive)
- `lib/relyra/protocol/metadata.ex` — gate signing `<KeyDescriptor>` + `AuthnRequestsSigned`
  attribute on `connection.sign_authn_requests`
- `lib/relyra.ex` — thread the signed query-string through `start_login/3` so the controller
  appends it verbatim
- `lib/relyra/phoenix/controllers/login_controller.ex` — stop re-serializing via
  `URI.encode_query/1`; append the core-built query verbatim
- `lib/relyra/provider/adfs.ex` — new provider preset
- `lib/relyra/provider.ex` — register `:adfs` in `@presets` map
- `guides/providers/adfs.md` — operator runbook (AUTHN-04)
- `test/security/authn_request_signing_test.exs` — new adversarial corpus (5 rows)
- `test/fixtures/security/authn_request_signing/` — committed golden bytes + PROVENANCE.md
- `mix.exs` `ci.security` alias — one new `cmd mix test` line; `ci_gate_integrity_test.exs`
  `@gated_suites` updated

**Out of scope:**
- HTTP-POST binding signed AuthnRequests (AUTHN-POST-01) — explicitly deferred to v1.4 per
  REQUIREMENTS.md; needs enveloped XML signature + C14N path
- SLO metadata publication (`<SingleLogoutService>`) — investigation thread mentions it but
  SLO is v0.6/v1.4 scope; Phase 35 leaves SLO metadata unchanged
- KMS-native `KeyResolver` adapters for the SP signing key — `:sp_signing_key_pem` is
  Application-env-only in v1.3; KMS extension point documented for v1.4+
- `EncryptedAttribute` decryption (deferred from Phase 34 D-06)
- Generic SAML runbook (Phase 36, parallel) and Identity Mapping guide (Phase 37, parallel)

**Requirements closed:** AUTHN-01, AUTHN-02 (toggle implementation; schema already landed
Phase 32), AUTHN-03, AUTHN-04.

**Pre-existing latent bug folded into scope:** Relyra's current redirect-binding path at
`lib/relyra/protocol/binding.ex:9-19` does **not** raw-DEFLATE the AuthnRequest XML before
base64-encoding it — SAML 2.0 Bindings §3.4.4.1 mandates raw-DEFLATE (RFC 1951) for the
HTTP-Redirect binding, and major IdPs (Microsoft Entra, ADFS) reject uncompressed payloads
with errors like AADSTS750054. AUTHN-01's bit-for-bit golden corpus cannot be claimed
without deflate, so the fix is load-bearing for Phase 35 and is folded in as the first task
(not split into a closure-phase, per user direction 2026-05-26).
</domain>

<decisions>
## Implementation Decisions

### Architecture — Where Signing Lives

- **D-01:** Introduce `Relyra.Security.Signature.sign_redirect_query/3` as the **single**
  SP-side signing primitive. Signature mirrors `Signature.do_verify/4`: takes the raw
  pre-assembled query-string binary, the private key, and opts; returns
  `{:ok, signature_b64}` or `{:error, %Error{}}`. Signs **the binary verbatim** —
  no `URI.encode_query/1` re-serialization inside the function (the CVE-class footgun called
  out in `.planning/threads/signed-authn-requests-investigation.md:11-14`).
- **D-02:** Redirect-URL assembly moves **into Relyra core**, not the Phoenix controller.
  Extend `Binding.encode_redirect/3` (or add `Binding.encode_signed_redirect/4`) to return a
  fully-pre-assembled query-string binary when `sign_authn_requests: true` and a `%{...}` map
  when off (backward-compatible). `Relyra.start_login/3` produces those bytes (a new
  `:redirect_query` field on the return map alongside or replacing `:redirect_params` when
  signing is enabled). `LoginController.redirect_to_idp/3` (`login_controller.ex:45-50`)
  stops calling `URI.encode_query/1` on the merged params and instead **appends the core-built
  binary verbatim** to `sso_url`. The existing `:redirect_params` map path is preserved for
  the unsigned case so non-ADFS adopters do not regress.

### Pre-existing Bug Folded — Raw-DEFLATE

- **D-03:** `Binding.encode_redirect/3` gains a raw-DEFLATE step before base64. Order of
  operations: XML → `:zlib` raw deflate (window bits `-15`) → `Base.encode64(_, padding: false)`
  → URL-encode. Implementation incantation:
  ```elixir
  z = :zlib.open()
  :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
  deflated = :zlib.deflate(z, xml, :finish) |> IO.iodata_to_binary()
  :ok = :zlib.deflateEnd(z)
  :ok = :zlib.close(z)
  ```
  Raw deflate (RFC 1951), not zlib (RFC 1950) — negative window bits suppresses the zlib
  header/Adler-32 checksum, matching SAML 2.0 Bindings §3.4.4.1.
- **D-04:** Deflate is unconditional in `encode_redirect/3` — applied for **both** signed
  and unsigned redirect-binding paths. Adopters whose IdPs were silently tolerating the
  uncompressed bytes will start sending spec-compliant bytes; ones whose IdPs were failing
  silently will start working. This is a fix-forward, not a feature flag. A `deflate_redirect`
  smoke test is added to the regular test suite (not the security suite) asserting that the
  Okta/Google sample fixtures still encode → decode round-trip cleanly.

### AlgorithmPolicy Gap — `signing_digest_atom/1`

- **D-05:** Add `AlgorithmPolicy.signing_digest_atom/1` as **Plan 01 Task 1** of Phase 35.
  Shape mirrors `digest_atom_for_signature_method/1` at `lib/relyra/security/algorithm_policy.ex:99-113`:
  - Input: URI string (e.g., `"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"`)
  - Output: `{:ok, :sha256}` for the SHA-256 URI; `{:ok, :sha1}` only when `legacy_sha1`
    escape hatch is active in policy (mirroring inbound digest policy); ECDSA URIs return
    `{:error, :unsupported_signing_algorithm}` (fail-closed pattern from
    `algorithm_policy.ex:88-99`); unknown URIs return `{:error, :unknown_signing_algorithm}`.
  - Function is callable from outside `AlgorithmPolicy` (public `def`); consumed by
    `sign_redirect_query/3`.

### Private Key Seam

- **D-06:** Introduce **new** config key `:sp_signing_key_pem` read via
  `Application.get_env(:relyra, :sp_signing_key_pem)`. This is the PEM-encoded RSA private
  key for outbound AuthnRequest signing. Do NOT reuse `:sp_private_key_pem` — that is
  XML-Enc decryption (Phase 33) and rotates on a different cadence (key compromise should
  not be dual-channel). Do NOT store in DB.
- **D-07:** When `sign_authn_requests: true` and `:sp_signing_key_pem` is missing/unparseable,
  `sign_redirect_query/3` returns `{:error, %Error{type: :key_not_configured, message: "...",
  metadata: %{hint: "Set config :relyra, :sp_signing_key_pem ..."}}}`. Pattern mirrors
  `lib/relyra/key_resolver/default.ex:13-17`. The error surfaces in `start_login/3`'s
  `{:error, %Error{}}` return; LoginController's existing error path handles it.

### Encoding Default — RFC 3986 Upper; ADFS-Lower Variant

- **D-08:** Default per-value URL-encoding = `URI.encode_www_form/1` (form-style: spaces → `+`,
  `+`/`/`/`=`/`:` percent-encoded) + uppercase hex (RFC 3986 §6.2.2.1 "preferred" form).
  `sign_redirect_query/3` accepts an `:encoding` option:
  - `:rfc3986_upper` (default) — `URI.encode_www_form/1` per value, uppercase hex
  - `:adfs_lower` — same encoding, then post-process `%[0-9A-F][0-9A-F]` → lowercase
    (matches python3-saml's `lowercase_urlencoding` flag; required for ADFS 3.0+ interop)
- **D-09:** The `:encoding` option is surfaced to adopters as a connection-level field
  (`Connection.encoding` or `Connection.signed_request_encoding` — planner picks the exact
  name) so it can be set per-connection via the admin UI. The ADFS preset (D-15) sets it to
  `:adfs_lower` by default; all other presets and the unsigned path leave it unset (default
  applies only at signing time).

### Signed Octet Composition

- **D-10:** The exact octet sequence signed by `sign_redirect_query/3` is, in literal order:
  ```
  SAMLRequest=<urlenc(b64(deflate(xml)))>&RelayState=<urlenc(relay_state)>&SigAlg=<urlenc(sig_alg_uri)>
  ```
  - `SAMLRequest` is first.
  - `RelayState` is included second **only when present** — when absent, the entire
    `&RelayState=` segment is **omitted** (not empty-string). Signed string becomes
    `SAMLRequest=...&SigAlg=...`.
  - `SigAlg` is last.
  - Per OASIS saml-bindings-2.0-os.pdf §3.4.4.1 literal template + samlify
    (`binding-redirect.ts:105-119`) + python3-saml (`auth.py:_build_sign_query`).
- **D-11:** The `Signature` parameter is appended **last** to the emitted URL (after
  `SAMLRequest`/`RelayState`/`SigAlg`) and is **NOT** part of the signed bytes. The
  signature value is `Base.encode64/1` (padding on) of the raw RSA signature, then
  `URI.encode_www_form/1`-encoded for URL safety.

### Metadata Toggle Gating (AUTHN-03)

- **D-12:** In `lib/relyra/protocol/metadata.ex`, gate the existing signing `<KeyDescriptor
  use="signing">` emission (currently unconditional at ~`metadata.ex:34-36` per Phase 34
  D-05) AND add an `AuthnRequestsSigned="true"` attribute on the `<md:SPSSODescriptor>`
  element (~`metadata.ex:33`) — **both** conditioned on
  `Map.get(connection, :sign_authn_requests, false) == true`. When the toggle is off, omit
  both the signing `KeyDescriptor` and the `AuthnRequestsSigned` attribute entirely (do
  NOT emit `AuthnRequestsSigned="false"` — its absence is the spec default).
- **D-13:** The encryption `KeyDescriptor` (Phase 34 D-04) remains **unconditional** —
  Phase 34 owns its existence; Phase 35 owns ONLY the signing-side toggle gating. The two
  descriptors stay in their Phase 34 child-order (signing before encryption when both
  present; encryption-only when toggle off).
- **D-14:** No new `Connection` schema fields are added in Phase 35 — `sign_authn_requests`
  already exists (Phase 32 D-10/D-11, `connection.ex:40`). The `:encoding` option (D-09) is
  the only new connection field; it lives **top-level** on `Connection` (not in
  `RuntimePolicy`) for direct DB queryability, mirroring `sign_authn_requests` placement.
  Added to `draft_changeset` cast list and threaded through `ConnectionSnapshot`.

### ADFS Provider Preset (AUTHN-04)

- **D-15:** New module `Relyra.Provider.ADFS` implementing the existing
  `Relyra.Provider` behaviour (pattern from `lib/relyra/provider/okta.ex` and
  `lib/relyra/provider/entra.ex`). `default_config/0` returns:
  ```elixir
  %{
    provider_preset: :adfs,
    sign_authn_requests: true,
    signed_request_encoding: :adfs_lower,
    algorithm_policy: %{signing: :rsa_sha256, digest: :sha256},
    allow_idp_initiated?: false,
    require_signed_assertions?: true,
    require_signed_response?: true
  }
  ```
- **D-16:** Register `:adfs` in two places:
  - `lib/relyra/provider.ex` `@presets` map (~`provider.ex:86-90`) — adds
    `adfs: Relyra.Provider.ADFS`
  - `lib/relyra/ecto/connection.ex` `@provider_presets` list (~`connection.ex:23`) — adds
    `:adfs` to the `Ecto.Enum`/list so DB-stored connections can carry the preset name.

### Operator Runbook (AUTHN-04)

- **D-17:** New file `guides/providers/adfs.md` mirroring the structure of
  `guides/recipes/okta.md` (and/or `guides/providers/okta.md` — planner picks the right
  template file). Required sections:
  1. **Overview** — when to use the ADFS preset; ADFS 3.0/4.0/5.0 version notes
  2. **SP-side config** — minimal `:relyra` Application config with `:sp_signing_key_pem`,
     connection creation with `provider_preset: :adfs`
  3. **ADFS-side PowerShell** — canonical block (see specifics below)
  4. **Claim rules** — paste-ready template for emitting NameID + standard attribute set
     (emailaddress / givenname / surname / name) via "Issuance Transform Rules"
  5. **Interop notes** — `+`-vs-`%20` and lowercase-hex encoding (the `:adfs_lower` quirk);
     SHA-1-vs-SHA-256 redirect-binding interop; the independence of `-SignatureAlgorithm`
     (outbound) from inbound `SigAlg` verification
  6. **Troubleshooting** — common ADFS rejection patterns; `WantAuthnRequestsSigned`
     vs `SignedSamlRequestsRequired` (the PowerShell flag) name divergence
- **D-18:** PowerShell canonical block — operator pastes verbatim:
  ```powershell
  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 "C:\path\to\sp-signing.cer"
  Set-AdfsRelyingPartyTrust `
    -TargetName "Relyra App" `
    -SignedSamlRequestsRequired $true `
    -RequestSigningCertificate @($cert) `
    -SignatureAlgorithm "https://www.w3.org/2001/04/xmldsig-more#rsa-sha256" `
    -SamlResponseSignature "MessageAndAssertion"
  ```
  Sources cited in PROVENANCE.md: Microsoft Learn `Set-AdfsRelyingPartyTrust` (Server 2025),
  dirteam.com SHA-256 guidance, Rory Braybrook claims-rules patterns.

### Adversarial Corpus + `ci.security` Wiring

- **D-19:** New file `test/security/authn_request_signing_test.exs` with
  `@moduletag :authn_request_signing`. Corpus rows:
  1. **Golden positive control** — SP signs a canonical AuthnRequest (fixed XML, fixed
     RelayState, fixed RSA private key from `FakeIdP.keypair/0`) → bit-for-bit match
     against committed `test/fixtures/security/authn_request_signing/golden_redirect.txt`.
  2. **ADFS-lower variant** — same logical input + `:encoding: :adfs_lower` →
     bit-for-bit match against committed `golden_redirect_adfs.txt`.
  3. **Re-serialization regression** — re-encode the canonical signed-octet query via
     `URI.encode_query/1` then sign that → MUST produce a different signature than the
     golden (mutation test proving the raw-octet invariant); fixture asserts inequality.
  4. **Round-trip verify** — SP signs, then `:public_key.verify/4` against the SP signing
     cert (`FakeIdP.self_signed_cert_pem/0`) → `:ok` (mirrors inverse-direction verify at
     `signature.ex:317`).
  5. **Toggle-off no-op** — `sign_authn_requests: false` connection → emitted URL has no
     `SigAlg`/`Signature` parameters; no existing Okta/Google/Entra/Ping/OneLogin test
     regresses (smoke-asserted in this corpus row, with the integration coverage in the
     existing provider preset test files).
- **D-20:** Wire into `ci.security` as **its own** `cmd mix test ... --warnings-as-errors
  --only authn_request_signing` line in `mix.exs:152-182`, placed immediately after the
  existing `adversarial_crypto` line. Add `:authn_request_signing` to
  `ci_gate_integrity_test.exs` `@gated_suites` (the Phase 30 hollow-gate meta-gate).
- **D-21:** Golden bytes are **committed files** (not computed inline), mirroring the
  Phase 28 C14N golden pattern at `test/fixtures/security/xml/parser_differential_and_c14n/`.
  Files: `golden_redirect.txt`, `golden_redirect_adfs.txt`, `golden_authnrequest.xml`,
  `PROVENANCE.md` (records: minted-by-test-helper, fixture key fingerprint, Elixir/OTP
  version used to mint, byte-counts, spec citation chain). The test reads the golden file
  and `assert == sp_signed_output`.

### Error Taxonomy

- **D-22:** No `:invalid_authn_request_signature` error needed — SP **generates** signed
  requests; verification is the IdP's job. The existing `:invalid_signature` (inbound IdP
  response path) is unaffected by Phase 35.
- **D-23:** New typed errors introduced by Phase 35:
  - `:key_not_configured` (D-07) — `:sp_signing_key_pem` missing when toggle on
  - `:unsupported_signing_algorithm` (D-05) — ECDSA URIs requested for signing
  - `:unknown_signing_algorithm` (D-05) — unknown URI requested for signing
  Built via `Error.new/3` (no central registry; free-atom taxonomy per `error.ex:15-18`).

### Claude's Discretion

- Exact module/file split between `Signature.sign_redirect_query/3` and a possible new
  `Relyra.Security.RedirectSigning` helper module — planner picks the lowest-friction shape.
- Whether `Binding.encode_redirect/3` is extended in-place or a sibling
  `Binding.encode_signed_redirect/4` is added; both are defensible; the in-place option
  keeps the binding module the single redirect-encode entry point.
- Exact field name for the encoding option on `Connection`: `encoding`,
  `signed_request_encoding`, `redirect_encoding`. The longer the more self-documenting;
  planner picks.
- Exact migration timestamp filename if a new migration is needed for the encoding column
  (follow project UTC-timestamp convention). May not be needed if the encoding option is
  derived from the provider preset at runtime rather than stored — planner decides.
- Whether the ADFS runbook lives at `guides/providers/adfs.md` or `guides/recipes/adfs.md`
  — pattern-match against the existing okta/google/entra placement.
- Whether to add a `Relyra.Connection.signed_request_encoding/1` runtime helper or fold the
  resolution inline in `sign_redirect_query/3`.
- Whether the toggle-off no-op corpus row (Row 5) goes in the new security suite or in the
  regular `binding_test.exs` — planner picks the location that best matches the row's
  blast radius.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project canon (prior research — do not re-derive)
- `prompts/RELYRA-GSD-IDEA.md` — vision, constraints, non-goals.
- `prompts/elixir-saml-lib-deep-research.md` — April 2026 ecosystem map, OASIS-aware
  domain language, security invariants, footguns, architecture.
- `prompts/relyra-brand-book.md` — voice for `guides/providers/adfs.md` operator copy.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — convergent patterns for OSS-lib
  ergonomics and preset shape.
- `.planning/PROJECT.md` — Key Decisions table; CLAUDE.md Non-Negotiable Security
  Invariants section.
- `.planning/REQUIREMENTS.md` — AUTHN-01..04 acceptance language.
- `.planning/ROADMAP.md` + `.planning/milestones/v1.3-ROADMAP.md` — Phase 35 success
  criteria + dependency notes.
- `.planning/threads/signed-authn-requests-investigation.md` — investigation thread; raw-octet
  contract rationale, adversarial corpus seed.
- `.planning/v1.3-v1.3-MILESTONE-AUDIT.md` (lines 197-202) — Phase 32 `signing_digest_atom/1`
  gap documented; Phase 35 owns the closure.

### Core code to extend
- `lib/relyra/security/signature.ex` — single crypto seam; `sign_redirect_query/3` lives
  here (mirrors `do_verify/4`); reusable PEM→key extraction pattern at lines 287-300.
- `lib/relyra/security/algorithm_policy.ex` — `digest_atom_for_signature_method/1`
  (~lines 99-113) is the exact shape to copy for `signing_digest_atom/1`; ECDSA fail-closed
  pattern at lines 88-99.
- `lib/relyra/protocol/binding.ex` (lines 1-23) — `encode_redirect/3` — add raw-DEFLATE
  here and the signed-redirect-encoding entry point.
- `lib/relyra/protocol/authn_request.ex` — AuthnRequest XML builder; reviewed by planner
  to confirm `to_xml/1` shape feeds correctly into the deflate-then-base64 path.
- `lib/relyra/protocol/metadata.ex` (lines 17-46) — `build_sp_metadata/2`; gate signing
  KeyDescriptor + add `AuthnRequestsSigned` attribute.
- `lib/relyra.ex` — `start_login/3` / `do_start_login/3` (lines 39-101); thread the
  signed query-string through `:redirect_query` return field.
- `lib/relyra/phoenix/controllers/login_controller.ex` (lines 45-50) — `redirect_to_idp/3`;
  stop calling `URI.encode_query/1` on merged params; append core-built query verbatim.
- `lib/relyra/ecto/connection.ex` (lines 23, 40) — `@provider_presets` list (add `:adfs`);
  `sign_authn_requests` field already present from Phase 32; add encoding field.
- `lib/relyra/ecto/connection_snapshot.ex` (~line 88) — confirm encoding field is threaded
  to runtime alongside `sign_authn_requests`.
- `lib/relyra/connection.ex` — runtime struct; mirror schema-side encoding field addition.
- `lib/relyra/provider.ex` (lines 76-90) — `@presets` registry; add `:adfs` entry.
- `lib/relyra/provider/okta.ex` and `lib/relyra/provider/entra.ex` — preset templates.
- `lib/relyra/key_resolver/default.ex` (lines 11-17) — `:_pem` config-read pattern; mirror
  for `:sp_signing_key_pem`.
- `lib/relyra/error.ex` (lines 15-18) — `Error.new/3` taxonomy; new atoms are just atoms.

### Test infrastructure
- `lib/relyra/test_support/fake_idp.ex` — `keypair/0` (~lines 237-243),
  `self_signed_cert_pem/0` (~line 235) — reused for the signing cert in the corpus.
- `lib/relyra/test_support/xmldsig_signer.ex` — anti-divergent-signer guarantee; the
  AUTHN-01 corpus must NOT introduce a parallel signer that diverges from the verifier.
- `test/security/xml/adversarial_crypto_test.exs` — structural model for the new
  AUTHN-01 corpus (FakeIdP-driven, exact `%Error{type:}` pins). **Never weaken**
  (CLAUDE.md). The AUTHN-01 corpus is a **separate file**, not new rows on this one.
- `mix.exs` (lines 152-182) — `ci.security` alias; add one new `cmd mix test` line per
  the Phase 30 hollow-gate fix (do NOT collapse to bare `test` step; see comment at
  ~lines 159-167).
- `test/security/ci_gate_integrity_test.exs` — `@gated_suites` constant; add
  `:authn_request_signing`.

### Phase 28 fixture-commit precedent
- `test/fixtures/security/xml/parser_differential_and_c14n/` —
  `assertion_inherited_ns.{input.xml,c14n}` + `PROVENANCE.md` — exact pattern for committing
  byte-exact golden fixtures with provenance attestation.

### External (planner: cite the spec, not the codebase)
- **OASIS SAML 2.0 Bindings** (saml-bindings-2.0-os.pdf) **§3.4.4.1** — HTTP-Redirect
  binding DEFLATE Encoding + signature octet-string composition + RelayState-when-present
  rule. URL: https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf
- **RFC 1951** — raw DEFLATE (no zlib header/Adler-32); Erlang `:zlib` window-bits `-15`.
- **RFC 3986 §6.2.2.1** — uppercase hex preferred for percent-encoding.
- **Microsoft Learn — `Set-AdfsRelyingPartyTrust` (Server 2025)** — PowerShell parameter
  reference for `-SignedSamlRequestsRequired`, `-RequestSigningCertificate`,
  `-SignatureAlgorithm`.
- **python3-saml `utils.py` `escape_url` + `lowercase_urlencoding` flag** —
  https://github.com/SAML-Toolkits/python3-saml/blob/master/src/onelogin/saml2/utils.py
  — primary citation for the ADFS lowercase-hex quirk.
- **OneLogin java-saml issue #225** and **Auth0 community thread** — real-world ADFS
  interop bugs from re-canonicalizing encoded values.
- **samlify `binding-redirect.ts` (lines 105-119)** — reference implementation of the
  signed octet-string composition.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Signature.do_verify/4` (single crypto seam) — `sign_redirect_query/3` mirrors its
  shape, keeping the "one entry to signature operations" architectural invariant intact
  (CLAUDE.md "Key Architecture Seams" §1).
- `AlgorithmPolicy.digest_atom_for_signature_method/1` (~`algorithm_policy.ex:99-113`) —
  exact return-type / pattern to copy for `signing_digest_atom/1`.
- ECDSA hard-reject pattern at `algorithm_policy.ex:88-99` — fail-closed shape for
  `:unsupported_signing_algorithm`.
- `FakeIdP.keypair/0` + `self_signed_cert_pem/0` (Phase 30 genuine signer promotion) —
  the canonical test key material; reusing avoids the divergent-signer anti-pattern.
- `Provider.Okta`/`Provider.Entra` modules (`lib/relyra/provider/{okta,entra}.ex`) —
  preset templates for `ADFS`.
- `Phase 28 fixture-commit pattern` (`test/fixtures/security/xml/parser_differential_and_c14n/`)
  — golden bytes committed alongside `PROVENANCE.md`.
- `KeyResolver.Default` (`key_resolver/default.ex:11-17`) — `:_pem` config-read pattern
  with the `:key_not_configured` typed-error shape.

### Established Patterns

- Free-atom `%Error{}` taxonomy via `Error.new/3` — no central registry to update.
- SP key material via `Application.get_env(:relyra, :<thing>_pem)` (Phase 33 convention).
- `ci.security`: one `cmd mix test <file> --warnings-as-errors --only <tag>` subprocess
  per security suite (Phase 30 hollow-gate fix); the `ci_gate_integrity_test.exs`
  meta-gate enforces no regression.
- Provider behaviour: closed compile-time `@presets` map in `lib/relyra/provider.ex`;
  `@provider_presets` enum list in `lib/relyra/ecto/connection.ex`.
- Top-level boolean toggles on `Connection` schema (not in embedded `RuntimePolicy`),
  per Phase 32 D-11.
- `FakeIdP` is the canonical fixture generator (real signing since Phase 30); the AUTHN
  corpus reuses its keypair, no new test-key material introduced.

### Integration Points

- `validation_pipeline.ex` — **unaffected**. AUTHN-01 is the outbound signing path;
  the inbound IdP-response validation pipeline is unchanged.
- `metadata.ex` — toggle-gated at the `<SPSSODescriptor>` element level; encryption
  KeyDescriptor (Phase 34) untouched.
- `login_controller.ex:45-50` — the **one** controller change: stop calling
  `URI.encode_query/1` on merged params; append core-built bytes verbatim.
- `start_login/3` return contract — adds `:redirect_query` (pre-assembled bytes) for the
  signed case; existing `:redirect_params` (map) preserved for the unsigned case.
- `connection_snapshot.ex` — already threads `sign_authn_requests` (Phase 32); add the
  encoding field alongside.
- `ci.security` alias — one new line; `ci_gate_integrity_test.exs` `@gated_suites`
  one new tag entry.

### Pre-existing Bug Discovered

- `lib/relyra/protocol/binding.ex:16` — `Base.encode64(xml, padding: false)` without
  raw-DEFLATE. Phase 35 fixes this in-place (D-03/D-04). Folded into Phase 35 Plan 01
  per user direction (not split into a closure-phase) because deflate is load-bearing
  for AUTHN-01's bit-for-bit golden corpus.
</code_context>

<specifics>
## Specific Ideas

- **New config seam**: `:sp_signing_key_pem` (PEM-encoded RSA private key for outbound
  AuthnRequest signing). Read via `Application.get_env(:relyra, :sp_signing_key_pem)`.
  Distinct from `:sp_private_key_pem` (XML-Enc decryption, Phase 33) and from
  `:sp_signing_cert_pem` (PUBLIC cert for metadata, Phase 34).
- **New typed errors** (built via `Error.new/3`, not registered): `:key_not_configured`,
  `:unsupported_signing_algorithm`, `:unknown_signing_algorithm`. No
  `:invalid_authn_request_signature` (SP generates, doesn't verify, AuthnRequests).
- **Signed octet template**:
  `SAMLRequest=<v>&RelayState=<v>&SigAlg=<v>` (RelayState segment omitted entirely when
  absent). Signature appended LAST to emitted URL; NOT in signed bytes.
- **Default SigAlg URI**: `http://www.w3.org/2001/04/xmldsig-more#rsa-sha256`.
- **Raw deflate incantation**:
  `:zlib.deflateInit(z, :default, :deflated, -15, 8, :default)` (negative window bits =
  RFC 1951 raw, no zlib header/Adler-32). Confirmed against Erlang `:zlib` manual.
- **ADFS lowercase-hex variant**: post-process `%[0-9A-F][0-9A-F]` → lowercase after
  standard `URI.encode_www_form/1` encoding (matches python3-saml `lowercase_urlencoding`).
- **ADFS preset defaults**: `provider_preset: :adfs`, `sign_authn_requests: true`,
  `signed_request_encoding: :adfs_lower`,
  `algorithm_policy: %{signing: :rsa_sha256, digest: :sha256}`,
  `allow_idp_initiated?: false`, `require_signed_assertions?: true`,
  `require_signed_response?: true`.
- **PowerShell canonical block for `guides/providers/adfs.md`** (paste-ready):
  `Set-AdfsRelyingPartyTrust -SignedSamlRequestsRequired $true -RequestSigningCertificate @($cert) -SignatureAlgorithm "https://www.w3.org/2001/04/xmldsig-more#rsa-sha256" -SamlResponseSignature "MessageAndAssertion"`.
- **Corpus golden filenames**:
  `test/fixtures/security/authn_request_signing/golden_redirect.txt`,
  `golden_redirect_adfs.txt`, `golden_authnrequest.xml`, `PROVENANCE.md`.
- **`ci.security` line shape** (insert after adversarial_crypto):
  `cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors`.
</specifics>

<deferred>
## Deferred Ideas

- **HTTP-POST binding signed AuthnRequests** (AUTHN-POST-01) — needs enveloped XML
  signature + C14N path; explicitly v1.4 per REQUIREMENTS.md "v1.4 Candidates" table.
  ADFS interop today is HTTP-Redirect-first; POST binding adds work without proportional
  v1.3 demand.
- **KMS-native `KeyResolver` adapters for the SP signing key** (KMS-01) — the
  extension-point docstring is added in Phase 35 for `:sp_signing_key_pem` but no AWS/GCP
  KMS adapters ship in v1.3. Documented in `guides/providers/adfs.md` as a v1.4 follow-up
  if demand materializes.
- **`SingleLogoutService` publication in `<SPSSODescriptor>`** — investigation thread
  `:18` mentions it but SLO metadata is v0.6/v1.4 scope; Phase 35 leaves SLO metadata
  unchanged. The SP signing `KeyDescriptor` Phase 35 emits will also serve SLO when
  Phase 24 / future SLO work attaches.
- **SP signing key rotation tooling** — operators rotate `:sp_signing_key_pem` manually
  in v1.3 (config-file edit + redeploy). A `mix relyra.rotate.sp_signing_key` task is a
  v1.4 candidate if the demand surfaces.
- **Strict-mode footgun warning** — investigation thread `:30` mentions a "provider
  footgun warning in dev; runtime error for strict IdPs" pattern. Defer to a follow-up:
  Phase 35 emits no footgun warning when an adopter sets `sign_authn_requests: false`
  but the connection's IdP metadata says `WantAuthnRequestsSigned="true"`. Track for a
  v1.4 strict-mode milestone.
- **`Relyra.Provider.Shibboleth` preset** — Shibboleth is mentioned alongside ADFS in
  the milestone arc but is **not** a v1.3 deliverable. Adopters use the generic
  recipe (Phase 36) for Shibboleth in v1.3.

### Reviewed Todos (not folded)
None — no pending todos matched this phase via `gsd-sdk` query (todo command not
exposed in current SDK build; manual scan of `.planning/todos/` shows no AUTHN-related
open items).
</deferred>
</content>
</invoke>