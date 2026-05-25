# Phase 34: ValidationPipeline Wiring + ENC-01 Complete - Research

**Researched:** 2026-05-25
**Domain:** SAML 2.0 XML-Encryption pipeline integration (decrypt-then-reparse), SP metadata KeyDescriptor emission, adversarial corpus design
**Confidence:** HIGH (the dependency, integration sites, and crypto contracts are all read directly from the codebase; the two spec questions are verified against OASIS SAML/XML-Enc schema documentation)

## Summary

Phase 34 wires the Phase-33 `XMLEnc.decrypt/3` primitive into `ValidationPipeline.do_run/4` as a pre-stage that runs *before* the existing parse-derived validation chain, then emits the SP encryption + signing `KeyDescriptor` in metadata and lands a 7-fixture pipeline-level adversarial corpus. **Phase 33 has landed** — `XMLEnc.decrypt/3` exists at `lib/relyra/security/xml_enc.ex` with the exact contract CONTEXT.md describes (`{:ok, binary()} | :decryption_failed`, opaque atom for all crypto/policy failures, AlgorithmPolicy gates pre-wired). There is **no planning blocker** on the dependency.

The single most important technical finding is about the recompose-then-reparse mechanics (priority question 3). The Relyra verifier does **not** bind the signature to original byte offsets. `Signature.verify/4` re-canonicalizes the `SignedInfo` and the referenced `<Assertion>` *parse-tree nodes* through the same `C14N` engine at verify time (`signature.ex:315` and `signature.ex:347` → `PureBeam.canonicalize/2` → `C14N.canonicalize_reference` → `C14N.serialize`). This means the recompose risk is **not** about preserving byte positions in the spliced Response binary — it is entirely about whether the second `parse_safely/2` produces an `<Assertion>` tree node and a `SignedInfo` tree node that **canonicalize to the same bytes the IdP signed**. The dominant failure mode is namespace context: a decrypted standalone `<Assertion>` whose in-scope namespaces were inherited from its original parent must retain (or re-acquire) those exact `xmlns` bindings, because exclusive-C14N renders visibly-utilized namespaces against the in-scope stack (`saxy_tree.ex` layer #1; `c14n.ex` `namespaces_to_render/3`).

**Primary recommendation:** Implement `:decrypt_assertion` as a private pre-stage inside `do_run/4` that (a) calls `parse_safely/2` once on the outer Response, (b) detects `EncryptedAssertion` (and the cleartext+encrypted ambiguity) from that parse tree using `PureBeam`-style `find_first`/`find_all`, (c) returns `:ambiguous_assertion` before any `XMLEnc.decrypt/3` call, (d) on a single `EncryptedAssertion` calls `XMLEnc.decrypt/3`, **string-splices** the decrypted plaintext in place of the `<EncryptedAssertion>...</EncryptedAssertion>` substring in the original Response binary, and re-runs `parse_safely/2` on the recomposed binary, (e) hands the re-parsed `parsed_doc` to the unchanged `do_run_validations/6`. Use string-splice (not tree-rebuild) because there is **no tree-to-XML re-serializer** in the codebase except the non-canonical `render_signed_xml/1` (which is explicitly documented as NOT C14N) — building one would be a new, high-risk surface. Drive the decrypt-then-verify ordering proof through a `read-before-verify` fixture that asserts no identity field is returned and a typed error fires.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The `:decrypt_assertion` step is a new **first stage inside `ValidationPipeline.do_run/4`** (`validation_pipeline.ex:62-76`) — **not** inside `Signature.do_verify/4`. Sequence: (a) `parse_safely/2` on outer Response → tree; (b) detect `EncryptedAssertion` + ambiguous case from tree; (c) reject ambiguity with `:ambiguous_assertion` **before any crypto** (D-03); (d) on single `EncryptedAssertion`: call `XMLEnc.decrypt/3`, splice plaintext into recomposed Response binary, **re-run `parse_safely/2`**; (e) hand re-parsed `parsed_doc` to unchanged `do_run_validations/6`. *The investigation thread's "wire into `do_verify`" guidance predates the Phase 28-29 refactor and is STALE — `do_verify` no longer sees raw bytes.*
- **D-02:** The **no-op path is byte-identical to today**: zero `EncryptedAssertion` elements → original `parsed_doc` flows straight to `do_run_validations/6` with no re-parse and no `XMLEnc` call. Branch keys only on `find_first(parse_tree, "EncryptedAssertion")` being non-nil. Protects every existing signed-Response test + frozen Phase-29 corpus (SC#3).
- **D-03:** `:ambiguous_assertion` is a **new distinct typed error** via `Error.new(:ambiguous_assertion, ...)`. Returned as `{:error, %Error{}}`, explicitly **NOT** folded into opaque `:decryption_failed`. Pre-crypto structural rejection; mirrors `:ambiguous_signed_node` precedent (`pure_beam.ex:551`). Guard runs **before** `XMLEnc.decrypt/3` (SC#2).
- **D-04:** Extend `Metadata.build_sp_metadata/2` (`metadata.ex:4-19`, currently emits **no** KeyDescriptor) to emit both `<KeyDescriptor use="encryption">` and `<KeyDescriptor use="signing">`. Source SP **public** certs from net-new config seams following Phase-33 `:_pem` convention: `Application.get_env(:relyra, :sp_encryption_cert_pem)` and `:sp_signing_cert_pem`. Encryption descriptor reads the **public cert** — never the private key `:sp_private_key_pem`.
- **D-05:** Phase 34 emits the `use="signing"` KeyDescriptor **unconditionally** (SC#4: "present and distinct"). The `sign_authn_requests`-toggle conditionality is layered on in Phase 35. Phase 34 owns *creation*; Phase 35 owns *toggle gating*.
- **D-06:** Phase 34 implements **`EncryptedAssertion` decryption only**. `EncryptedAttribute` is **deferred** (user confirmed). All 5 success criteria + all 7 fixtures are assertion-level.
- **D-07:** The 7 ENC-01 fixtures live in a **new dedicated** `test/security/` file (e.g. `xml_enc_adversarial_test.exs`), added to `mix.exs` `ci.security` as its **own** `cmd mix test ... --warnings-as-errors` line (Phase-30 hollow-gate rule). Distinct from the Phase-33 unit corpus (`xml_enc_test.exs`). The **read-before-verify** fixture drives end-to-end through `ValidationPipeline` and asserts NO identity field is returned + a typed error.
- **D-08:** `FakeIdP` gains a new `encrypt`/`encrypted_response` helper wrapping a signed Response/Assertion into an `<EncryptedAssertion>` using RSA-OAEP + AES-256-GCM against the SP public key. Promote the recipe from `xml_enc_test.exs:39-56` + envelope template from `xml_enc_test.exs:28-33` into `FakeIdP` as the single canonical generator (mirroring `FakeIdP.sign/2`).

### Claude's Discretion

- Exact new corpus filename (`test/security/xml_enc_adversarial_test.exs` suggested).
- Whether to advertise `<md:EncryptionMethod>` inside the encryption `KeyDescriptor`, and exact `<md:KeyDescriptor>` child ordering (signing before encryption) — resolve against XML-Enc / SAML metadata schema. **[RESEARCH RESOLVED below — see Architecture Pattern 2.]**
- Whether the encrypted Response is recomposed by string-splice or tree-rebuild before the second `parse_safely/2` — pick the lowest-risk form that does not perturb the bytes `canonicalize/2` binds via `:node`. **[RESEARCH RESOLVED below — string-splice; see Architecture Pattern 1 + Pitfall 1.]**
- Whether `ValidationPipeline` obtains `key_resolver` by calling `KeyResolver.resolve/2` dispatch or by passing the resolved module into `XMLEnc.decrypt/3` (note: `XMLEnc.decrypt/3` calls `key_resolver_module.resolve/1` directly via `apply`, `xml_enc.ex:107` — pass the MODULE, not the dispatch wrapper result). **[RESEARCH RESOLVED below — pass the module; see Architecture Pattern 3.]**

### Deferred Ideas (OUT OF SCOPE)

- **`EncryptedAttribute` decryption** — deferred from Phase 34 (D-06). Follow-up reusing `XMLEnc.decrypt/3` against the `<AttributeStatement>` subtree, *after* signature verification. Track against ENC-01 residual scope.
- **`sign_authn_requests` toggle gating of the signing KeyDescriptor** — Phase 35 (AUTHN-03). Phase 34 only creates the descriptor unconditionally (D-05).
- **XMLEnc decryption telemetry** — deferred from Phase 33; out of scope here (timing-channel review needed).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENC-01 | SP can decrypt `EncryptedAssertion` using RSA-OAEP key transport + AES-GCM content encryption; decrypted bytes pass through `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before any identity field is read; all decryption failures return opaque `:decryption_failed` | `XMLEnc.decrypt/3` (Phase 33) already returns opaque `:decryption_failed` for all crypto/policy failures (`xml_enc.ex:11,26,30`). Phase 34 supplies the *pipeline wiring* (decrypt → recompose → re-`parse_safely/2` → existing `do_run_validations/6` whose first crypto-relevant step is `Signature.verify/4`). The decrypt-then-verify ordering is structurally guaranteed because identity fields are only read in `login_result/5` (`validation_pipeline.ex:181-204`), which runs AFTER the `with` chain that includes `Signature.verify/4`. **Scope note (D-06):** `EncryptedAttribute` deferred — ENC-01 is partially closed (assertion path only). |
| ENC-02 | SP metadata endpoint publishes `KeyDescriptor use="encryption"` with the SP encryption certificate | `Metadata.build_sp_metadata/2` (`metadata.ex:4-19`) currently emits no KeyDescriptor; D-04 adds both. KeyDescriptor schema + ordering verified against OASIS metadata spec (see Architecture Pattern 2). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Detect EncryptedAssertion / ambiguity | Backend — `ValidationPipeline.do_run/4` | `PureBeam` parse tree | `do_run/4` is the only layer that owns the raw `response_payload` binary and calls `parse_safely/2` (D-01). Detection is tree-walk over the already-parsed outer Response. |
| Decrypt CEK + content | Backend — `XMLEnc.decrypt/3` (Phase 33, unchanged) | `:public_key` / `:crypto` (OTP) | Crypto primitive owns RSA-OAEP unwrap + AES-GCM. Consumed unchanged; no modification this phase. |
| Resolve SP private key | Backend — `KeyResolver` behaviour (Phase 33) | PEM config default | Key material sourced exclusively via the resolver callback; document KeyInfo ignored (`xml_enc.ex:104-113`). |
| Re-parse decrypted plaintext | Backend — `PureBeam.parse_safely/2` (unchanged) | `SaxyTree` | The single hardened parse seam; the ONLY entry. No second parser (CLAUDE.md invariant). |
| Signature / digest verification | Backend — `Signature.verify/4` (frozen) | `C14N` engine | Re-canonicalizes tree nodes at verify time; binds `:node`, not byte offsets. Untouched. |
| Emit SP KeyDescriptors | Backend — `Metadata.build_sp_metadata/2` | App config (`:sp_*_cert_pem`) | Metadata endpoint serves SP descriptors so IdPs can encrypt (ENC-02). |
| Generate encrypted test fixtures | Test support — `FakeIdP.encrypt/encrypted_response` | `XmldsigSigner` (sign first, then encrypt) | Single canonical generator; mirrors `FakeIdP.sign/2`. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` (OTP) | OTP 28 | RSA-OAEP key transport (`decrypt_private`/`encrypt_public`), cert PEM decode for KeyDescriptor X509Certificate | Already the project crypto primitive (`signature.ex`, `xml_enc.ex`); zero new deps (STATE.md invariant) `[VERIFIED: codebase grep + elixir --version]` |
| `:crypto` (OTP) | OTP 28 | AES-256-GCM content encryption in FakeIdP encrypt helper (`crypto_one_time_aead/7`) | Already used in `xml_enc.ex:41` (decrypt) and `xml_enc_test.exs:51` (encrypt recipe) `[VERIFIED: codebase grep]` |
| `:saxy` (`Relyra.Security.XML.SaxyTree`) | saxy ~> 1.6 | The single XML parse seam for both the outer Response and the re-parse of decrypted plaintext | The ONLY permitted parse path (CLAUDE.md invariant #2); `parse_safely/2` wraps it with pre-parse byte guards `[VERIFIED: pure_beam.ex:39-58, mix.exs:57]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Base` (Elixir stdlib) | 1.19.5 | base64 encode/decode of CipherValue / X509Certificate DER for the KeyDescriptor + FakeIdP envelope | Already used throughout `xml_enc.ex` (`b64_decode`) and `xml_enc_test.exs` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| String-splice recompose | Tree-rebuild + re-serialize | **Rejected** — no canonical tree serializer exists (`render_signed_xml/1` is explicitly NOT C14N, `pure_beam.ex:691-699`). Building one is a new high-risk surface that could silently diverge from C14N and break the digest. String-splice keeps the original Response bytes everywhere except the spliced subtree, then re-parses through the same seam (Pitfall 1). |
| NIF XML-Enc library | (none) | **Permanently out of scope** (REQUIREMENTS.md:53) — would create a second XML parse entry point bypassing the saxy seam. |

**Installation:** None. Zero new Hex dependencies (STATE.md v1.3 invariant — all crypto is OTP stdlib `:public_key`/`:crypto`/`:zlib`).

**Version verification:** No new packages. Runtime confirmed `Erlang/OTP 28 [erts-16.3]`, `Elixir 1.19.5` `[VERIFIED: elixir --version]`. The OAEP recipe `:public_key.encrypt_public(cek, pub, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])` (default SHA-1 MGF1) is the same one Phase 33's `unwrap_cek` decrypts (`xml_enc.ex:61-68`) and the same one already passing in `xml_enc_test.exs:42-43` — confirmed working on OTP 28 `[VERIFIED: codebase grep + test/security/xml_enc_test.exs]`.

## Package Legitimacy Audit

> Not applicable — Phase 34 installs **zero** external packages. All crypto is OTP stdlib (`:public_key`, `:crypto`, `:zlib`); XML parsing uses the already-vendored `saxy` dependency. No registry verification, slopcheck, or postinstall audit required.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                    raw response_payload (binary)
                              │
                              ▼
        ┌──────────────── do_run/4 (validation_pipeline.ex) ────────────────┐
        │                                                                     │
        │   parse_safely/2 (outer Response) ──► parsed_doc (with :parse_tree) │
        │                              │                                       │
        │                              ▼                                       │
        │              ┌──── :decrypt_assertion pre-stage (NEW, D-01) ────┐    │
        │              │                                                   │    │
        │   find_first(parse_tree,"EncryptedAssertion")                   │    │
        │              │                                                   │    │
        │   ┌──────────┴───────────┬──────────────────────┐               │    │
        │   │ nil (no enc)         │ ≥1 EncryptedAssertion │               │    │
        │   │ [D-02 no-op]         │                       │               │    │
        │   ▼                      ▼                       ▼               │    │
        │ original         also has cleartext        exactly one          │    │
        │ parsed_doc       <Assertion>?              EncryptedAssertion    │    │
        │   │              │ YES                      │                    │    │
        │   │              ▼                          ▼                    │    │
        │   │       {:error,                   resolve key module          │    │
        │   │        :ambiguous_assertion}     (KeyResolver from opts)     │    │
        │   │       BEFORE any crypto (D-03)   │                           │    │
        │   │                                  ▼                           │    │
        │   │                         XMLEnc.decrypt(enc_bytes,            │    │
        │   │                           key_resolver_module, opts)         │    │
        │   │                                  │                           │    │
        │   │                    ┌─────────────┴────────────┐             │    │
        │   │                    │ :decryption_failed        │ {:ok, pt}  │    │
        │   │                    ▼                            ▼            │    │
        │   │            {:error, %Error{                string-splice    │    │
        │   │             type: :decryption_failed}}     plaintext into   │    │
        │   │                                            Response binary   │    │
        │   │                                                 │            │    │
        │   │                                                 ▼            │    │
        │   │                                       parse_safely/2 AGAIN   │    │
        │   │                                       (recomposed binary)    │    │
        │   │                                                 │            │    │
        │   └─────────────────────────────┬───────────────────┘            │    │
        │                                  ▼                                │    │
        │              re-parsed/original parsed_doc                        │    │
        │                                  │                                │    │
        │                                  ▼                                │    │
        │   do_run_validations/6 (UNCHANGED):                              │    │
        │     request_correlation → issuer_match → Signature.verify/4 ────► (crypto) │
        │     → bind_signed_node → status → destination → audience         │    │
        │     → recipient → time_conditions                                │    │
        │                                  │                                │    │
        │                                  ▼                                │    │
        │              login_result/5 ── FIRST point any identity field     │    │
        │              (NameID, attributes) is read ── runs ONLY after      │    │
        │              Signature.verify/4 passed                            │    │
        └──────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
lib/relyra/protocol/
├── validation_pipeline.ex   # +:decrypt_assertion pre-stage in do_run/4 (D-01)
└── metadata.ex              # +KeyDescriptor use="signing"/"encryption" (D-04)
lib/relyra/
└── error.ex                 # (no change — :ambiguous_assertion is just Error.new/3)
lib/relyra/test_support/
└── fake_idp.ex              # +encrypt/encrypted_response helper (D-08)
test/security/
└── xml_enc_adversarial_test.exs  # NEW 7-fixture pipeline corpus (D-07)
mix.exs                      # +own cmd-mix-test line in ci.security (D-07)
```

### Pattern 1: Decrypt-then-reparse via string-splice (priority question 3 — RESOLVED)

**What:** After `XMLEnc.decrypt/3` returns plaintext, replace the `<EncryptedAssertion>…</EncryptedAssertion>` substring in the **original Response binary** with the decrypted `<Assertion>…</Assertion>` plaintext, then call `parse_safely/2` on the recomposed binary.

**When to use:** Always, for the single-EncryptedAssertion path (D-01 step d).

**Why string-splice, not tree-rebuild — the verified reasoning:**

1. The signature is **re-canonicalized at verify time**, not byte-bound. `verify_signature_math` calls `C14N.serialize(signed_info_node, ...)` (`signature.ex:315`) and `verify_reference_digest` calls `PureBeam.canonicalize(candidate)` over `candidate.node` (`signature.ex:347`). The digest is `:crypto.hash(digest_atom, ref_bytes)` where `ref_bytes` is the *re-canonicalized* Assertion node. **No code path reads original byte offsets.** `[VERIFIED: signature.ex:306-374]`

2. Therefore the recompose must only ensure the second `parse_safely/2` yields an `<Assertion>` tree node + `SignedInfo` tree node that **canonicalize to the same bytes the IdP signed over** — exactly the same property `XmldsigSigner` relies on (it parses the *emitted* XML and canonicalizes the parsed nodes, `xmldsig_signer.ex:18-23,108-121`). String-splice preserves this because the spliced plaintext IS the bytes the IdP produced before encryption.

3. **There is no canonical tree serializer.** The only tree→XML function is `render_signed_xml/1`, explicitly documented "This is NOT canonical C14N" (`pure_beam.ex:691-694`). A tree-rebuild path would require writing one, and any divergence from `C14N` would silently break the digest — re-opening the auth-bypass class. String-splice avoids inventing that surface.

**The real failure mode (Pitfall 1, security-critical):** namespace context. Exclusive-C14N renders *visibly-utilized* namespaces against the element's *in-scope* stack (`c14n.ex:301-329`, fed by the SaxyTree `:ns` map built by inheriting parent declarations, `saxy_tree.ex:126-145`). A standalone decrypted `<Assertion>` whose default namespace was inherited from `<Response>` in the IdP's pre-encryption document, but whose plaintext does NOT carry its own `xmlns="urn:...assertion"` declaration, will canonicalize differently once spliced under a Response with a different default-namespace context — producing `:digest_mismatch`. **Mitigation:** the FakeIdP encrypt helper (D-08) must encrypt an `<Assertion>` that carries a self-contained namespace declaration (`xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` on the Assertion element itself — exactly as `FakeIdP.response_xml` already does at `fake_idp.ex:124`). Real IdPs (Entra, Okta, ADFS) emit self-contained encrypted assertions with their own namespace declarations; this is the interoperable reality. Document this expectation; do not attempt to re-inject parent namespace context into the splice.

**Splice locator:** The outer Response parse tree (step a) already gives you the `EncryptedAssertion` node. Locate the `<EncryptedAssertion` opening tag and matching `</EncryptedAssertion>` (or self-contained closing) in the raw binary by substring. Because XML-Enc's `EncryptedAssertion` contains only base64 CipherValue text (no nested `EncryptedAssertion`), a single non-greedy substring match on the original binary is unambiguous. Splice the decrypted plaintext in its place.

### Pattern 2: SP metadata KeyDescriptor emission + ordering (priority question 2 — RESOLVED)

**What:** Emit two `<md:KeyDescriptor>` elements inside `<md:SPSSODescriptor>`, signing first then encryption, each before `<md:AssertionConsumerService>`.

**Verified XSD ordering** (OASIS SAML 2.0 Metadata, `RoleDescriptorType` → `SSODescriptorType` → `SPSSODescriptorType` sequence) `[CITED: docs.oasis-open.org/security/saml/v2.0/saml-metadata-2.0-os.pdf; datypic.com/sc/saml2/e-md_SPSSODescriptor.html]`:

```
1. ds:Signature              [0..1]
2. md:Extensions             [0..1]
3. md:KeyDescriptor          [0..*]   ← BOTH descriptors go HERE
4. md:Organization           [0..1]
5. md:ContactPerson          [0..*]
6. md:ArtifactResolutionService [0..*]
7. md:SingleLogoutService    [0..*]
8. md:ManageNameIDService    [0..*]
9. md:NameIDFormat           [0..*]
10. md:AssertionConsumerService [1..*]   ← currently the only child emitted
11. md:AttributeConsumingService [0..*]
```

**KeyDescriptorType internal sequence** (strict; KeyInfo before EncryptionMethod) `[CITED: datypic.com/sc/saml2/e-md_KeyDescriptor.html]`:
```xml
<md:KeyDescriptor use="signing">
  <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:X509Data><ds:X509Certificate>{base64 DER, no PEM headers}</ds:X509Certificate></ds:X509Data>
  </ds:KeyInfo>
</md:KeyDescriptor>
<md:KeyDescriptor use="encryption">
  <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:X509Data><ds:X509Certificate>{base64 DER}</ds:X509Certificate></ds:X509Data>
  </ds:KeyInfo>
  <!-- OPTIONAL md:EncryptionMethod (see recommendation below) -->
  <md:EncryptionMethod Algorithm="http://www.w3.org/2009/xmlenc11#aes256-gcm"/>
  <md:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"/>
</md:KeyDescriptor>
```

**Move both KeyDescriptors ABOVE the existing `<md:AssertionConsumerService>`** in `metadata.ex` (currently AssertionConsumerService is the only child — KeyDescriptor must precede it for schema validity).

**`<md:EncryptionMethod>` recommendation (the open discretion item):** **Advertise it, but align it to the AlgorithmPolicy default allowlist, not to the spec's full menu.** Relyra's `AlgorithmPolicy.default()` allows content encryption `aes128-gcm` / `aes256-gcm` and key transport `rsa-oaep-mgf1p` only (`algorithm_policy.ex:68-74`). Advertising `<md:EncryptionMethod>` for exactly these tells the IdP what the SP will actually accept, preventing the IdP from encrypting with an algorithm the SP will hard-reject (PKCS1v1.5, AES-CBC). **Caveat (provenance):** the canonical content-encryption URI Relyra *accepts* at decrypt time is `http://www.w3.org/2001/04/xmlenc#aes256-gcm` (the xmlenc#  form, `xml_enc.ex:9`), NOT the xmlenc11# form some IdPs advertise. **Advertise the `xmlenc#aes256-gcm` URI in metadata to match what the decryptor accepts** — advertising `xmlenc11#aes256-gcm` while only accepting `xmlenc#aes256-gcm` would be a self-inconsistency. `[VERIFIED: xml_enc.ex:8-9 + algorithm_policy.ex:68-74]` If the planner prefers minimal surface, omitting `<md:EncryptionMethod>` is schema-valid (it's `[0..*]`) and defers algorithm negotiation to defaults — acceptable but less interoperable. **Recommendation: advertise `xmlenc#aes256-gcm` + `xmlenc#aes128-gcm` + `xmlenc#rsa-oaep-mgf1p` to mirror the accept-list.**

**X509Certificate content:** The `<ds:X509Certificate>` body is the **base64 of the DER bytes only** — strip the PEM `-----BEGIN/END CERTIFICATE-----` armor and newlines. Decode the PEM via `:public_key.pem_decode/1` and re-base64 the DER (`elem(entry, 1)`), mirroring `signature.ex:288-289`.

### Pattern 3: KeyResolver module dispatch (the open discretion item — RESOLVED)

**What:** Pass the **resolver module** into `XMLEnc.decrypt/3`, not the result of `KeyResolver.resolve/2`.

**Why:** `XMLEnc.decrypt/3` internally calls `apply(key_resolver_module, :resolve, [connection])` (`xml_enc.ex:107`). It wants the module atom. Obtain it from `consume_opts` the same way `KeyResolver.resolve/2` does: `Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)` (`key_resolver.ex:25-27`). Pass that atom as `XMLEnc.decrypt/3`'s second argument. Do NOT call `KeyResolver.resolve/2` and pass its `{:ok, pem}` result — `decrypt/3` re-resolves internally. `[VERIFIED: xml_enc.ex:104-113, key_resolver.ex:14-27]`

The `connection` map flows from `do_run/4` (it's already a parameter). `XMLEnc.decrypt/3` reads `connection` from `opts` (`xml_enc.ex:16`: `Keyword.get(opts, :connection, %{})`), so the pre-stage must thread `connection: connection` into the opts passed to `decrypt/3`.

### Anti-Patterns to Avoid

- **Folding `:ambiguous_assertion` into `:decryption_failed`** — it is a pre-crypto structural reject (typed, no oracle risk). Keep it distinct (D-03).
- **Calling `XMLEnc.decrypt/3` before the ambiguity check** — SC#2 requires the ambiguity reject to fire *before any crypto*. Order: detect ambiguity → reject → only then decrypt.
- **Reading any identity field from the decrypted-but-unverified tree** — this is CVE-2025-54419 (CLAUDE.md invariant). The pre-stage must return only the re-parsed `parsed_doc`; identity is read in `login_result/5` which runs after `Signature.verify/4`.
- **Building a tree→XML re-serializer for recompose** — use string-splice (Pattern 1); the only existing serializer is non-canonical.
- **Trusting document KeyInfo for the decryption key** — `XMLEnc.decrypt/3` already ignores it (`xml_enc.ex:104-105`); don't re-introduce it in the pipeline.
- **Emitting KeyDescriptor after AssertionConsumerService** — schema-invalid; KeyDescriptor must precede it (Pattern 2).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical XML serialization for recompose | Custom tree→XML serializer | String-splice + re-`parse_safely/2` | A divergent serializer silently breaks the digest → auth bypass. The C14N engine is the only canonical serializer and it runs at verify time over re-parsed nodes. |
| RSA-OAEP decrypt / AES-GCM unwrap | New crypto code | `XMLEnc.decrypt/3` (Phase 33) | Already implemented, gated by AlgorithmPolicy, opaque-error-safe, inside try/rescue. Consume unchanged. |
| Encryption fixture generation | Ad-hoc per-test encryption | `FakeIdP.encrypt/encrypted_response` (D-08) | Single canonical generator prevents divergent test recipes (mirrors `FakeIdP.sign/2`). |
| EncryptedAssertion field parsing | Regex / second parser | `SaxyTree` via `parse_safely/2` + `find_first`/`find_all` | One parse path invariant (CLAUDE.md #2). `XMLEnc.decrypt/3` already parses the envelope via `SaxyTree`. |
| Cert PEM → X509Certificate base64 | Manual string surgery | `:public_key.pem_decode/1` + `Base.encode64` of DER | Mirrors `signature.ex:288`; handles entry extraction robustly. |

**Key insight:** Every "build it yourself" temptation in this phase touches the signature trust boundary. The codebase has already paid down all of them — the phase is *wiring*, not *building*.

## Runtime State Inventory

> Phase 34 is greenfield code wiring + new test fixtures + metadata emission. It introduces no renames, no data migrations, no stored-state changes, and no OS/service registration. The only net-new runtime config seams are read-only application env reads.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by grep: no DB schema, ETS table, or persisted state touched. The phase reads `Application.get_env` for cert PEMs only. | none |
| Live service config | None — no n8n/Datadog/external-service config. Metadata is generated on-demand from connection + app env. | none |
| OS-registered state | None — no task scheduler / systemd / pm2 registration. | none |
| Secrets/env vars | **Two NEW read-only config seams:** `:sp_encryption_cert_pem` and `:sp_signing_cert_pem` (public certs). Code-read only; no key rename. The existing Phase-33 `:sp_private_key_pem` (private key, read by KeyResolver.Default) is unchanged. | Document the two new env keys in operator config; planner adds them to config docs. |
| Build artifacts | None — pure Elixir source + test files; no compiled artifact rename, no egg-info/binary equivalent. | none |

**The canonical question** (after every file is updated, what runtime systems still hold the old string?): **N/A — Phase 34 introduces no string that previously existed elsewhere.** The two new config keys are additive and read-only.

## Common Pitfalls

### Pitfall 1: Decrypted Assertion loses its namespace context on recompose (SECURITY-CRITICAL)

**What goes wrong:** The spliced decrypted `<Assertion>` canonicalizes to different bytes than the IdP signed, yielding spurious `:digest_mismatch` on a legitimate encrypted assertion (or, worse, masking a real tamper if the test fixture is built to compensate).
**Why it happens:** Exclusive-C14N renders namespaces against the in-scope stack (`c14n.ex:301`); the in-scope stack is inherited from parents at parse time (`saxy_tree.ex:126`). A standalone decrypted Assertion without its own `xmlns` declaration inherits the wrong default namespace once spliced.
**How to avoid:** The FakeIdP encrypt helper (D-08) MUST encrypt an Assertion carrying its own `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` declaration on the Assertion element (as `fake_idp.ex:124` already does for the cleartext path). Sign the Assertion *before* encrypting it (sign → encrypt envelope), so the signed bytes and the post-decrypt bytes are identical. Real IdPs emit self-contained encrypted assertions; this matches production reality.
**Warning signs:** Positive-control fixture (valid encrypted assertion → `{:ok}`) fails with `:digest_mismatch`. If you see this, the splice changed canonical bytes.

### Pitfall 2: Ambiguity check positioned after decrypt

**What goes wrong:** A cleartext-injection attack (both `<Assertion>` and `<EncryptedAssertion>` present) reaches `XMLEnc.decrypt/3` before being rejected, violating SC#2.
**Why it happens:** Natural code ordering puts "find encrypted, decrypt it" first.
**How to avoid:** In the pre-stage, after detecting `EncryptedAssertion` presence, check for a sibling cleartext `<Assertion>` under the Response root and return `:ambiguous_assertion` *before* any decrypt call. The XSD `<choice maxOccurs="unbounded">` (verified below) means a schema-valid-looking attack response CAN carry both as siblings.
**Warning signs:** The cleartext-injection fixture returns `:decryption_failed` instead of `:ambiguous_assertion`, or any telemetry shows a decrypt span on the ambiguous fixture.

### Pitfall 3: Reading an identity field from the decrypted-but-unverified tree

**What goes wrong:** Identity (NameID/attributes) is accessed before `Signature.verify/4` passes — the exact CVE-2025-54419 shortcut.
**Why it happens:** Convenience: the pre-stage already has the re-parsed tree; reading a field "to log it" or "to short-circuit" leaks unverified identity.
**How to avoid:** The pre-stage returns ONLY the re-parsed `parsed_doc`. All identity reads stay in `login_result/5` (`validation_pipeline.ex:181-204`), which the `with` chain in `do_run_validations/6` only reaches after `Signature.verify/4` succeeds. The `read-before-verify` fixture (D-07) proves this end-to-end.
**Warning signs:** Any `Map.get(parsed_doc, :name_id)` / `:attributes` call inside the `:decrypt_assertion` stage.

### Pitfall 4: AES-GCM auth-tag length / split assumptions in FakeIdP

**What goes wrong:** The encrypt helper produces a CipherValue layout that `XMLEnc`'s `split_cipher_value/1` can't parse (it expects `IV(12) || CT || Tag(16)`, ≥28 bytes, `xml_enc.ex:70-77`).
**Why it happens:** Encrypting with a different IV length or appending the tag in the wrong order.
**How to avoid:** Mirror `xml_enc_test.exs:48-53` exactly: `iv = strong_rand_bytes(12)`, `crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, <<>>, 16, true)`, then `Base.encode64(iv <> ciphertext <> auth_tag)`. This is the proven layout `split_cipher_value/1` round-trips.
**Warning signs:** Positive control returns `:decryption_failed` (the split or GCM verify failed before signature checks).

### Pitfall 5: Hollow-gate regression in ci.security

**What goes wrong:** The new corpus is added as a bare `test ...` step, gets deduped/skipped, and ships green without running.
**Why it happens:** `mix` dedups the `test` task within an alias; `ci.conformance` already ran `test --only conformance`, so a bare `test` step inherits `--only conformance` and silently no-ops.
**How to avoid:** Add the new file as its OWN `cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` line (D-07; pattern at `mix.exs:167-173`). The meta-gate `test/security/ci_gate_integrity_test.exs` enforces this — run it to confirm.
**Warning signs:** `ci_gate_integrity_test.exs` fails, or the new suite's test count is 0 in CI output.

## Code Examples

### Detect EncryptedAssertion + ambiguity (pre-stage, tree-walk)

```elixir
# Source: derived from pure_beam.ex find_first/find_all (584-618) + xml_enc.ex find_first (170-176)
# parse_tree is parsed_doc.parse_tree (the SaxyTree.Node root, pure_beam.ex:257)
defp detect_encrypted(parse_tree) do
  enc = find_first(parse_tree, "EncryptedAssertion")     # descendant-or-self, prefix-agnostic
  cleartext = find_first(parse_tree, "Assertion")
  encs = find_all(parse_tree, "EncryptedAssertion")

  cond do
    is_nil(enc) -> :none                                  # D-02 no-op path (byte-identical)
    not is_nil(cleartext) -> :ambiguous                   # D-03 (both present) — reject pre-crypto
    length(encs) > 1 -> :ambiguous                        # >1 encrypted is also ambiguous (one verified node)
    true -> {:single, enc}
  end
end
```

### Decrypt + recompose + reparse (pre-stage core)

```elixir
# Source: composed from xml_enc.ex:11 (decrypt/3 contract), key_resolver.ex:25-27 (module),
#         pure_beam.ex:39 (parse_safely re-entry)
defp decrypt_assertion(response_payload, parsed_doc, connection, opts) do
  case detect_encrypted(parsed_doc.parse_tree) do
    :none ->
      {:ok, parsed_doc}                                   # D-02: original flows unchanged

    :ambiguous ->
      {:error, Error.new(:ambiguous_assertion,
        "Response contains both cleartext and encrypted assertions", %{})}   # D-03, pre-crypto

    {:single, _enc_node} ->
      key_resolver = Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)
      enc_bytes = extract_encrypted_assertion_substring(response_payload)    # string locator
      decrypt_opts = Keyword.put(opts, :connection, connection)             # xml_enc.ex:16

      case Relyra.Security.XMLEnc.decrypt(enc_bytes, key_resolver, decrypt_opts) do
        {:ok, plaintext} ->
          recomposed = String.replace(response_payload, enc_bytes, plaintext, global: false)
          Relyra.Security.XML.PureBeam.parse_safely(recomposed, parse_opts(opts))  # re-parse seam

        :decryption_failed ->
          {:error, Error.new(:decryption_failed,
            "Encrypted assertion could not be decrypted", %{})}              # opaque, no oracle
      end
  end
end
```

### FakeIdP encrypt helper (D-08, promote from xml_enc_test.exs:39-56)

```elixir
# Source: xml_enc_test.exs:28-56 (proven envelope template + OAEP/GCM recipe)
@rsa_oaep "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
@aes256_gcm "http://www.w3.org/2001/04/xmlenc#aes256-gcm"

def encrypt(signed_assertion_xml, sp_pub_key) do
  cek = :crypto.strong_rand_bytes(32)
  enc_key = :public_key.encrypt_public(cek, sp_pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
  iv = :crypto.strong_rand_bytes(12)
  {ct, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, signed_assertion_xml, <<>>, 16, true)
  # Wrap into <EncryptedAssertion> using the xml_enc_test.exs:28-33 template,
  # base64(enc_key) for the EncryptedKey CipherValue, base64(iv<>ct<>tag) for content.
  build_encrypted_assertion(@rsa_oaep, @aes256_gcm, Base.encode64(enc_key), Base.encode64(iv <> ct <> tag))
end
```

*Note: sign the Assertion FIRST (via the promoted `XmldsigSigner` path), then `encrypt/2` the signed `<Assertion>` subtree — so the decrypted plaintext carries the genuine signature the verifier will check.*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| "Wire `decrypt_assertion/3` into `do_verify`" (investigation thread line 37) | Wire into `do_run/4` (D-01) | Phase 28-29 refactor | `do_verify` receives an already-parsed map and cannot re-parse; only `do_run/4` owns raw bytes + `parse_safely/2`. The thread guidance is STALE. |
| Structure-only signature acceptance | Real `:public_key.verify` + digest recompute (frozen) | Phase 29 (v1.2.0) | The verifier re-canonicalizes tree nodes at verify time — recompose binds `:node`, not bytes. |

**Deprecated/outdated:**
- The investigation thread's "wire into `do_verify`" and its "~4 plans, plan 3 = wire into do_verify" estimate — superseded by the Phase 28-29 architecture (CONTEXT.md D-01 flags this).
- The thread's recommendation to do `EncryptedAttribute` "both" in v1.3 — deferred by D-06 (user confirmed).

## Spec Verification (priority questions 1 & 2)

### Q1: `<EncryptedAssertion>` structure & nesting in a `<Response>`

**Verified content model of `samlp:ResponseType`** (StatusResponseType base + ResponseType extension) `[CITED: docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf §3.3.3 / saml-schema-protocol-2.0.xsd]`:
```
saml:Issuer        [0..1]
ds:Signature       [0..1]
samlp:Extensions   [0..1]
samlp:Status       [1..1]
<choice [0..*]>:  saml:Assertion | saml:EncryptedAssertion   ← repeating choice
```
**Key finding for the D-03 detector:** the choice has `maxOccurs="unbounded"`, and each *occurrence* picks `Assertion` OR `EncryptedAssertion`. A schema-valid document can therefore have multiple sibling occurrences — meaning a response CAN carry both a cleartext `<Assertion>` AND an `<EncryptedAssertion>` as siblings under the Response root (this is precisely the cleartext-injection attack D-03 guards). **Both elements are direct children of the Response root, appearing after `<Status>`.** The detector must walk the Response root's direct/descendant children for both local names — `find_first(tree, "EncryptedAssertion")` and `find_first(tree, "Assertion")` cover this (prefix-agnostic, `pure_beam.ex:584`).

**`<EncryptedAssertion>` internal structure** (XML-Encryption §3, §5) `[CITED: xml_enc_test.exs:28-33 (in-repo proven template) + W3C XML-Enc]`:
```xml
<saml:EncryptedAssertion>
  <xenc:EncryptedData>
    <xenc:EncryptionMethod Algorithm="...aes256-gcm"/>        <!-- content encryption -->
    <ds:KeyInfo>
      <xenc:EncryptedKey>
        <xenc:EncryptionMethod Algorithm="...rsa-oaep-mgf1p"/> <!-- key transport -->
        <xenc:CipherData><xenc:CipherValue>{base64 wrapped CEK}</xenc:CipherValue></xenc:CipherData>
      </xenc:EncryptedKey>
    </ds:KeyInfo>
    <xenc:CipherData><xenc:CipherValue>{base64 IV||CT||Tag}</xenc:CipherValue></xenc:CipherData>
  </xenc:EncryptedData>
</saml:EncryptedAssertion>
```
This is exactly what `XMLEnc.parse_enc_fields/1` walks (`xml_enc.ex:117-136`): EncryptedData → KeyInfo → EncryptedKey for key transport; EncryptedData → direct-child CipherData for content (`direct_cipher_value_text/1` avoids descending into the EncryptedKey's CipherData, `xml_enc.ex:154-160`). **The pipeline does not need to re-parse these internals — it hands the whole `<EncryptedAssertion>` substring to `decrypt/3`, which parses it via SaxyTree.**

### Q2: `<md:KeyDescriptor>` ordering & EncryptionMethod — see Architecture Pattern 2 (fully resolved above).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | String-splice substring match on `<EncryptedAssertion>...</EncryptedAssertion>` is unambiguous because EncryptedAssertion cannot nest another EncryptedAssertion and contains only base64 text | Pattern 1 | LOW — XML-Enc forbids nested EncryptedAssertion; but if a fixture/IdP wraps unusual whitespace or the closing tag uses a different prefix, the locator must be prefix-aware. Mitigation: locate by the parsed tree node's source span or by prefix-agnostic tag matching, and add a guard asserting exactly one match. |
| A2 | Advertising `xmlenc#aes256-gcm` (not `xmlenc11#`) in `<md:EncryptionMethod>` matches what the decryptor accepts | Pattern 2 | LOW — verified against `xml_enc.ex:8-9`; but if a future Phase-33 patch adds xmlenc11 URIs the metadata should follow. Planner should confirm the advertised URIs equal `AlgorithmPolicy.default().allowed_content_encryption_algorithms`. |
| A3 | Real IdPs emit self-contained encrypted `<Assertion>` with their own `xmlns` declaration (so splice preserves canonical bytes) | Pattern 1 / Pitfall 1 | MEDIUM — this is the interoperable norm (Entra/Okta/ADFS sign then encrypt self-contained assertions), but a non-conforming IdP that relies on inherited Response-level namespace context would `:digest_mismatch`. This is a real-world interop edge, not a Phase-34 correctness bug; document it. The FakeIdP fixtures are self-contained by construction. |
| A4 | The `use="encryption"` and `use="signing"` certs may legitimately be the SAME cert in many deployments | Pattern 2 | LOW — SC#4 only requires the descriptors be "present and distinct" (distinct *elements*), not distinct certs. D-04 sources them from separate config keys, so an operator MAY configure the same PEM for both. No correctness risk. |

**Note:** A1–A4 are implementation-detail assumptions, not security-posture decisions. None contradict a locked decision. A3 is the one to surface to the user if encrypted-assertion interop with an unusual IdP is in scope.

## Open Questions

1. **Should the >1 `EncryptedAssertion` case also be `:ambiguous_assertion`?**
   - What we know: SC#1/SC#2 speak of "a valid EncryptedAssertion" (singular) and the cleartext+encrypted ambiguity. The verifier requires exactly one signed node (`:ambiguous_signed_node` precedent).
   - What's unclear: D-03 names only the cleartext+encrypted case explicitly. Two encrypted assertions is a separate shape.
   - Recommendation: treat >1 `EncryptedAssertion` as `:ambiguous_assertion` too (the code example does). It's the same "exactly one assertion" invariant, pre-crypto. Cheap and consistent. Planner should confirm whether a dedicated fixture is wanted (the 7 named fixtures don't include it; it can ride the cleartext-injection fixture's intent or be a bonus assertion).

2. **PKCS1v1.5 fixture: does the gate fire at AlgorithmPolicy (inside decrypt) or need a distinct pipeline assertion?**
   - What we know: `enforce_key_transport_algorithm` hard-rejects `rsa-1_5` (`algorithm_policy.ex:134-140`); `XMLEnc.check_key_transport` maps that to `:decryption_failed` (`xml_enc.ex:89-94`). So the pipeline sees `:decryption_failed`.
   - What's unclear: whether the corpus should pin `:decryption_failed` (opaque, as the unit corpus does) at the pipeline level too — yes, per the specifics table in CONTEXT.md (PKCS1v1.5 → `:decryption_failed`).
   - Recommendation: pin `%Error{type: :decryption_failed}` for PKCS1v1.5, CBC, wrong-key, truncated-tag, and malformed-ciphertext at the pipeline level (all five collapse to the opaque atom by design — that IS the no-oracle property under test). Only cleartext-injection pins `:ambiguous_assertion`; only read-before-verify pins a verification-stage typed error (`:invalid_signature` / `:digest_mismatch`) AND asserts no identity field returned.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP `:public_key` | RSA-OAEP, cert decode | ✓ | OTP 28 (erts-16.3) | — |
| Erlang/OTP `:crypto` | AES-256-GCM (FakeIdP encrypt) | ✓ | OTP 28 | — |
| Elixir | build/test | ✓ | 1.19.5 | — |
| `saxy` | XML parse seam | ✓ | ~> 1.6 (mix.exs:57) | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none. The OAEP+GCM recipe is already proven on this exact OTP 28 in `xml_enc_test.exs` (passing).

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | none (ExUnit configured per-file via `use ExUnit.Case`); suites gated by `mix.exs` aliases |
| Quick run command | `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` |
| Full suite command | `mix ci.security` |

### Phase Success Criteria → Test Map
| SC | Behavior | Test Type | Automated Command | File Exists? |
|----|----------|-----------|-------------------|-------------|
| SC#1 | Valid EncryptedAssertion → decrypt → re-parse → verify → login `{:ok}`, identity readable ONLY post-verify | integration (positive control, end-to-end through ValidationPipeline) | `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` | ❌ Wave 0 (new corpus file) |
| SC#2 | cleartext + encrypted → `:ambiguous_assertion` before any crypto (assert no decrypt telemetry span) | unit/integration | same file | ❌ Wave 0 |
| SC#3 | No-op path byte-identical: existing signed-Response tests + Phase-29 frozen corpus still green | regression | `mix ci.security` (runs `adversarial_crypto_test.exs`, `corpus_security_test.exs`, full `test`) | ✅ existing suites must stay green |
| SC#4 | Metadata publishes `KeyDescriptor use="encryption"` + distinct `use="signing"`; correct child ordering | unit (metadata builder + controller) | `mix test` on a new/extended metadata test asserting both descriptors, ordering, X509Certificate body | ❌ Wave 0 (extend metadata test) |
| SC#5 | All 7 fixtures wired into ci.security, each returns correct typed error | integration corpus | `mix ci.security` includes the new `cmd mix test` line; `ci_gate_integrity_test.exs` confirms it's not hollow | ❌ Wave 0 (corpus + mix.exs line) |

### 7-Fixture → Typed-Error Map (D-07)
| # | Fixture | Pinned outcome | Construction |
|---|---------|----------------|--------------|
| 1 | wrong-key | `%Error{type: :decryption_failed}` | encrypt CEK against a throwaway pubkey; SP private key can't unwrap |
| 2 | truncated GCM tag | `%Error{type: :decryption_failed}` | content CipherValue `IV(12)||CT||15-byte tag` (< 16) — `enforce_content_encryption_algorithm` auth-tag guard fires (`algorithm_policy.ex:158`) |
| 3 | PKCS1v1.5 key transport | `%Error{type: :decryption_failed}` | EncryptedKey EncryptionMethod = `xmlenc#rsa-1_5`; hard-reject (`algorithm_policy.ex:134`) |
| 4 | AES-CBC content | `%Error{type: :decryption_failed}` | EncryptedData EncryptionMethod = `xmlenc#aes256-cbc`; policy reject (default has no CBC hatch) |
| 5 | cleartext-injection (both present) | `%Error{type: :ambiguous_assertion}` | Response with sibling `<Assertion>` + `<EncryptedAssertion>`; must fire BEFORE decrypt |
| 6 | malformed ciphertext | `%Error{type: :decryption_failed}` | invalid base64 / sub-28-byte CipherValue |
| 7 | read-before-verify | verification-stage typed error (`:invalid_signature` or `:digest_mismatch`) AND `name_id`/`attributes` NOT in result | encrypt a genuinely-signed-then-tampered (or wrong-cert) assertion; assert the login result map carries no identity and an `{:error, %Error{}}` is returned — the strongest auth-bypass guard |

### Sampling Rate
- **Per task commit:** `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` + `mix format --check-formatted`
- **Per wave merge:** `mix test --warnings-as-errors` (full suite, no regressions — SC#3)
- **Phase gate:** `mix ci.security` green (includes the new corpus line + `ci_gate_integrity_test.exs` hollow-gate check) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/security/xml_enc_adversarial_test.exs` — new 7-fixture pipeline corpus (covers SC#1, SC#2, SC#5)
- [ ] `FakeIdP.encrypt`/`encrypted_response` helper — shared fixture generator (D-08); prerequisite for all 7 fixtures
- [ ] metadata test extension — assert both KeyDescriptors, ordering, X509Certificate body (covers SC#4)
- [ ] `mix.exs` `ci.security` — add `cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` line (covers SC#5 wiring); verify `ci_gate_integrity_test.exs` still passes
- Framework install: none — ExUnit is built in.

## Security Domain

> security_enforcement enabled (absent in config = enabled). This is a security-critical phase (auth trust boundary).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | The whole phase is SAML SSO auth; decrypt-then-verify ordering is the auth integrity control |
| V3 Session Management | no | No session lifecycle changes in this phase (login_result feeds the host app's session adapter, unchanged) |
| V4 Access Control | no | No authz logic |
| V5 Input Validation | yes | All decrypted bytes re-parsed through hardened `parse_safely/2` (DOCTYPE/ENTITY/size guards before parse); ambiguity reject is structural input validation |
| V6 Cryptography | yes | RSA-OAEP + AES-GCM via OTP `:public_key`/`:crypto` (never hand-rolled); opaque `:decryption_failed` prevents padding/error oracle; AlgorithmPolicy allowlist (no PKCS1v1.5, no CBC by default) |
| V9 (Data Protection) | yes | SP private key never logged/surfaced (Phase-33 discipline, `xml_enc.ex:33-34`); Error.redact_details strips xml/assertion fields |

### Known Threat Patterns for SAML XML-Enc

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Decrypt-then-read-before-verify (CVE-2025-54419 class) | Elevation of Privilege / Spoofing | Re-parse through `parse_safely/2` + `Signature.verify/4` BEFORE any identity read; proven by read-before-verify fixture (D-07) |
| Cleartext-injection (both cleartext + encrypted assertion) | Tampering / Spoofing | `:ambiguous_assertion` pre-crypto reject (D-03); fixture #5 |
| Bleichenbacher (RSA-PKCS1v1.5 key transport) | Information Disclosure | Hard-reject `rsa-1_5`, no escape hatch (`algorithm_policy.ex:134`); fixture #3 |
| Jager–Somorovsky (AES-CBC padding oracle) | Information Disclosure | Reject AES-CBC by default (time-boxed hatch only); fixture #4 |
| Error/timing oracle on decrypt failure | Information Disclosure | Single opaque `:decryption_failed` for ALL crypto/policy failures (`xml_enc.ex:26`); fixtures 1,2,3,4,6 all collapse to it |
| XSW on decrypted plaintext | Tampering | Re-parse catches it — the C14N digest recompute over the bound `:node` rejects injected/tampered subtrees (`:digest_mismatch`); the frozen adversarial_crypto corpus + read-before-verify fixture |
| GCM auth-tag truncation | Tampering | Auth-tag length guard (== 16) before `crypto_one_time_aead` (`algorithm_policy.ex:158`); fixture #2 |
| Document-KeyInfo key confusion | Spoofing | Decryption key resolved ONLY via KeyResolver; document KeyInfo ignored (`xml_enc.ex:104-105`) |

## Project Constraints (from CLAUDE.md)

The planner MUST verify every plan against these (treated with locked-decision authority):

1. **Signature source:** configured IdP certs only — NEVER document KeyInfo. (Unchanged; `do_verify` already enforces.)
2. **One parse path:** no second XML parse, no parser differential. Both the outer Response and the recompose re-parse go through `parse_safely/2` → SaxyTree. The string-splice recompose does NOT add a parser — it re-uses the seam.
3. **Pre-parse guards:** DOCTYPE/ENTITY/size run BEFORE saxy on raw binary — `parse_safely/2` runs them on the *recomposed* binary too (so decrypted plaintext is guarded against XXE-in-plaintext). This is a free, correct consequence of re-using `parse_safely/2`.
4. **Crypto is required:** decrypted bytes pass `parse_safely/2` AND `Signature.do_verify/4` before any identity field — the phase's central invariant (read-before-verify fixture proves it).
5. **Audit co-commit:** N/A — Phase 34 has no trust-mutation (connection/metadata/cert/mapping) writes. Decryption is read-path.
6. **Replay protection:** unchanged — replay key consumption happens in `consume_replay_key` (`relyra.ex:162`) after the pipeline, on the verified result.
7. **Testing:** `mix test --warnings-as-errors`, `mix ci.security`, `mix format --check-formatted` must all stay green; new security code gets corpus rows; never weaken `adversarial_crypto_test.exs`.
8. **ci.security hollow-gate rule:** each security suite is its OWN `cmd mix test ... --warnings-as-errors` line — the new corpus follows this (D-07).
9. **Zero new Hex deps:** OTP stdlib only.
10. **Public API escalation:** `consume_response/3` signature is unchanged (decryption flows through existing `consume_opts`). No public-API shape change → no escalation needed.

## Sources

### Primary (HIGH confidence)
- Codebase (read directly this session): `lib/relyra/security/xml_enc.ex`, `lib/relyra/key_resolver.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/protocol/metadata.ex`, `lib/relyra/error.ex`, `lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/security/xml/c14n.ex`, `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/saxy_tree.ex`, `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/test_support/fake_idp.ex`, `lib/relyra/test_support/xmldsig_signer.ex`, `lib/relyra/phoenix/controllers/metadata_controller.ex`, `lib/relyra.ex`, `test/security/xml_enc_test.exs`, `test/security/xml/adversarial_crypto_test.exs`, `mix.exs`
- Planning docs: `34-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `v1.3-ROADMAP.md`, `threads/encrypted-assertions-investigation.md`
- Runtime: `Erlang/OTP 28 [erts-16.3]`, `Elixir 1.19.5` (`elixir --version`)
- OASIS SAML 2.0 Metadata spec — https://docs.oasis-open.org/security/saml/v2.0/saml-metadata-2.0-os.pdf (KeyDescriptorType sequence, KeyTypes use attribute)
- OASIS SAML 2.0 Core spec — https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf (ResponseType content model, §3.3.3)

### Secondary (MEDIUM confidence)
- datypic SAML2 schema reference — http://www.datypic.com/sc/saml2/e-md_SPSSODescriptor.html (verified RoleDescriptorType→SPSSODescriptorType sequence; KeyDescriptor before AssertionConsumerService)
- datypic — http://www.datypic.com/sc/saml2/e-md_KeyDescriptor.html (KeyDescriptorType: KeyInfo before EncryptionMethod)

### Tertiary (LOW confidence)
- WebSearch summary on ResponseType "choice not both" — corrected against the actual XSD `maxOccurs="unbounded"` choice (siblings of both types ARE schema-possible; this is the attack D-03 catches). The corrected reading is what's documented above.

## Metadata

**Confidence breakdown:**
- Dependency (Phase 33 landed): HIGH — `XMLEnc.decrypt/3` read directly, contract matches CONTEXT.md exactly
- Integration sites (do_run, metadata, error): HIGH — all read directly
- Recompose mechanics (string-splice vs tree-rebuild): HIGH — the verifier's re-canonicalize-at-verify behavior is read directly from `signature.ex`; the conclusion (splice, not rebuild) follows deterministically
- Spec questions (EncryptedAssertion nesting, KeyDescriptor ordering): HIGH (Core/Metadata specs) with the one tertiary correction noted
- Adversarial corpus design: HIGH — modeled on the existing `adversarial_crypto_test.exs` + the Phase-33 unit corpus
- Namespace-context interop edge (A3): MEDIUM — the interoperable norm, but a non-conforming IdP is a real-world edge

**Research date:** 2026-05-25
**Valid until:** 2026-06-24 (30 days — stable internal codebase; OASIS specs are frozen standards)
