# Phase 29: Cryptographic XMLDSig verification - Research

**Researched:** 2026-05-24
**Domain:** XMLDSig signature verification (RSASSA-PKCS1-v1_5) over exclusive-C14N, in pure Erlang/OTP `:public_key` / `:crypto`, behind the `Relyra.Security.XML` / `Relyra.Security.Signature` seam.
**Confidence:** HIGH

## Summary

Phase 29 wires real cryptographic XMLDSig verification into the `[candidate]` arm of `verified_signed_node/4` (`lib/relyra/security/signature.ex:167-175`) — today the published-hex auth-bypass site that returns `{:ok, %SignedNode{}}` with zero crypto. The whole crypto data flow was confirmed end-to-end on the project's exact runtime (OTP 28, Elixir 1.19.5): `:public_key.verify(SignedInfoBytes, :sha256, SignatureValueBytes, RSAPublicKey)` against a public key extracted from the configured `cert_chain` PEM, plus a `DigestValue` recompute (`:crypto.hash/2`) over the canonicalized referenced element compared constant-time with `:crypto.hash_equals/2`. Every locked decision (D-01..D-13) is implementable as written against the proven Phase 28 C14N engine and the existing seam; no decision needed contradicting.

The single largest non-obvious risk is **not** the crypto math (which is a small, well-understood call surface) — it is the **input plumbing**. Two concrete data-plumbing gaps must be closed before any positive control can pass: (1) `pure_beam.ex` does not yet extract the base64 `DigestValue`/`SignatureValue` or surface the `SignedInfo` node (D-02), and (2) the **metadata-root path builds its own regex-derived `parsed_doc`** in `lib/relyra/metadata/auto_refresh.ex:197-238` whose candidates carry only `:xml_id`/`:xpath`/`:signed_xml` — none of the tree-bound fields the new crypto needs (D-13/SIGV-04). The mixed-content C14N "Option-a" fix (D-09/D-10) is also a **hard precondition**: I reproduced the bug — `C14N.render_element/3` emits `node.text` before all children (`c14n.ex:257-268`), so any pretty-printed signed XML mis-canonicalizes and triggers `:digest_mismatch` on every realistic positive control.

**Primary recommendation:** Land the mixed-content C14N Option-a fix and the `pure_beam.ex` field extraction FIRST (preconditions), then add the crypto primitive `do_verify`-side once, so both `verify/4` and `verify_metadata_root/4` inherit it — but only after the metadata-root `pre_parse_for_signature` is upgraded to surface the same tree-bound fields (otherwise SIGV-04 cannot run the crypto). Use `:crypto.hash_equals/2` for the constant-time compare (OTP 25+, confirmed available on the OTP 27/28 CI matrix), but **guard byte-length first** — it raises `ArgumentError` on unequal-length inputs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Signature math (`:public_key.verify`) | `Relyra.Security.Signature` (`do_verify`) | — | Shared trust primitive; both `verify/4` and `verify_metadata_root/4` delegate to `do_verify/4` (`signature.ex:19,76`) — wire crypto once, covers SIGV-01/02/04 |
| Trust-source public-key extraction (PEM→pubkey) | `Relyra.Security.Signature` (new helper) | reuse pattern from `Relyra.Ecto.CertificateFacts` | Trust source is the CONFIGURED `cert_chain` PEM (D-04), NEVER document KeyInfo |
| Canonicalize `SignedInfo` (sig math input) | `Relyra.Security.XML.C14N.serialize/2` | — | SignedInfo carries no enveloped-signature transform → bare serialize, not `canonicalize_reference/4` (D-03) |
| Canonicalize referenced element (digest input) | `Relyra.Security.XML.PureBeam.canonicalize/2` → `C14N.canonicalize_reference/4` | — | Already wired over the bound `:node` with enveloped-signature prune (Phase 28, D-05) |
| URI→digest-atom mapping | `Relyra.Security.AlgorithmPolicy` | — | Already owns the allowlist + enforce_* (D-06, `algorithm_policy.ex:30-47`) |
| Surface `DigestValue`/`SignatureValue`/`SignedInfo` per candidate | `Relyra.Security.XML.PureBeam` (`signed_candidates/1`) | — | These base64 values are not extracted anywhere today (D-02, grep-confirmed) |
| Metadata-root parsed_doc (tree-bound) | `Relyra.Metadata.AutoRefresh` (`pre_parse_for_signature/1`) | `Relyra.Security.XML.PureBeam` | Currently regex-derived — must surface the same crypto inputs for SIGV-04 (D-13) |
| Operator-pinned fingerprint pinning | `Relyra.Metadata.TrustAnchor.check/2` (runs BEFORE verify) | — | Defense-in-depth; signature math is the primary gate (D-13) |
| Genuinely-signed positive-control fixture | Phase-29-local signer (test support) | reuse `FakeIdP` RSA-2048 keypair (D-11) | One positive control; promotable into FakeIdP in Phase 30 (D-12) |

## User Constraints (from CONTEXT.md)

> 29-CONTEXT.md was gathered in **assumptions mode** and is the AUTHORITATIVE spec. Locked decisions below are copied verbatim — research these, do not explore alternatives.

### Locked Decisions

**Crypto verification wiring & data plumbing**
- **D-01:** Rewrite the `[candidate]` arm of `verified_signed_node/4` (`signature.ex:159-185`) to perform real signature math. It currently returns `{:ok, %SignedNode{}}` with ZERO crypto — the auth-bypass site. All existing trust-discipline gates (cert_chain present, `key_info_trust` rejection, duplicate-ID rejection, algorithm allowlist, single-signed-node selection) stay and run BEFORE the crypto.
- **D-02:** `pure_beam.ex` must additionally surface, per signed candidate: the declared `DigestValue` (trimmed text of the bound Reference's `ds:DigestValue`, base64) and the raw `SignatureValue` (`ds:SignatureValue`, base64), plus the `SignedInfo` tree node. Today candidates carry only `:node`/`:signature_node`/`:transforms_node`; neither base64 value is extracted anywhere yet.
- **D-03:** Signature check = `C14N.serialize/2` over the `SignedInfo` node (NOT `canonicalize_reference/4` — `SignedInfo` carries no enveloped-signature transform), then `:public_key.verify(canonical_signed_info, digest_atom, decoded_signature_value, public_key)`.
- **D-04:** Trust source = public key extracted from the configured `cert_chain` PEM via `:public_key.pkix_decode_cert/2` → `SubjectPublicKeyInfo` → `SubjectPublicKey` (reuse the PEM-decode pattern at `certificate_facts.ex:26-47`). NEVER document `KeyInfo` — the existing `key_info_trust == true` rejection (`signature.ex:113-119`) stays.
- **D-05:** Digest check = recompute `:crypto.hash(digest_atom, canonical_reference_bytes)` where `canonical_reference_bytes` come from the EXISTING `canonicalize/2` path (`C14N.canonicalize_reference/4` over the bound `:node`, enveloped-signature-transformed), and constant-time compare against the base64-decoded declared `DigestValue`.
- **D-06:** URI→digest-atom mapping lives in `Relyra.Security.AlgorithmPolicy`: `*-sha256`→`:sha256`, `*-sha384`→`:sha384`, `*-sha512`→`:sha512`.
- **D-07:** Algorithm scope = RSA-SHA256/384/512 verified for real now; ECDSA fails CLOSED with a typed `:unsupported_signature_algorithm` error. ECDSA `r‖s`→DER converter deferred (real in-scope IdPs — Okta/Entra/Google — sign RSA). Fail-CLOSED, never fail-open.
- **D-08:** Error taxonomy: `:invalid_signature` (verify false / malformed SignatureValue), new `:digest_mismatch` (recomputed Reference digest differs), `:untrusted_certificate` (PEM→key extraction fails), `:unsupported_signature_algorithm` (ECDSA / unhandled alg), `:canonicalization_failed` (propagated from C14N). `Relyra.Error` accepts any atom `type`.

**Mixed-content C14N correctness fix (folded into this phase)**
- **D-09:** Implement Option-a from `28-04-SUMMARY.md`: add an ordered `content: [{:text, _} | {:element, _}]` field to `SaxyTree.Node`, have `C14N.render_element/3` walk it in document order, keep `:text`/`:children` as DERIVED views so `pure_beam.ex` field-derivation helpers stay unchanged. ~55 LOC.
- **D-10:** This fix is a HARD precondition for the positive control. `c14n.ex:262-263` currently emits `node.text` BEFORE all children, so pretty-printed / mixed-content signed XML mis-canonicalizes → `:digest_mismatch` on every realistic real-IdP positive control. Land before/alongside D-13. Keep the 887-byte exclusive-C14N golden green and ADD a mixed-content golden (minted out-of-band in Docker per Phase 28 D-12; CI stays pure-Elixir against committed bytes).

**Positive-control fixture (Phase-29-local genuine signer)**
- **D-11:** Phase 29 builds its OWN minimal real XMLDSig signer to produce at least one genuinely-signed node returning `{:ok, %SignedNode{}}` (success #3). Approach: C14N the `SignedInfo` → `:public_key.sign/3` (`:sha256`) with `FakeIdP`'s EXISTING RSA-2048 keypair (`fake_idp.ex:85-95`); emit real `ds:DigestValue` + `ds:SignatureValue`. Configured `cert_chain` for the control = the PEM of that same keypair's cert.
- **D-12:** Phase boundary respected. Wholesale `FakeIdP` real-signing + the full adversarial corpus + `corpus_gate`/manifest wiring stay in Phase 30 (ASSUR-01/02). Write the Phase-29 signer so Phase 30 can PROMOTE it into `FakeIdP` (avoid a divergent second signer).
- **D-13:** SIGV-04 metadata-root is proven by the SAME `do_verify` signature-math primitive on an `EntityDescriptor`/`EntitiesDescriptor`-shaped `parsed_doc` (`verify_metadata_root/4` delegates verbatim to `do_verify/4`, `signature.ex:76`). Add a positive control AND assert operator-pinned `TrustAnchor` fingerprint pinning still rejects a signature-valid-but-wrong-fingerprint root — signature math first, pinning as defense-in-depth (not pinning alone).

### Claude's Discretion
- Exact internal helper module/function names for the new crypto path (e.g. whether the signer lives in `test/support` or a `Relyra.TestSupport` module), and whether `:digest_mismatch`/`:unsupported_signature_algorithm` are added to the `xml_error_type` union in `xml.ex` — planner/executor decide, consistent with existing seam conventions.
- Whether constant-time digest compare uses `:crypto.hash_equals/2` (OTP 25+) vs a manual constant-time helper — pick what the OTP matrix supports cleanly.

### Deferred Ideas (OUT OF SCOPE)
- Full XMLDSig ECDSA support (`r‖s`→DER re-encode + verify) — fast-follow after v1.1; fail-closed in Phase 29 (D-07).
- Wholesale FakeIdP real-signing + adversarial crypto corpus + corpus_gate/manifest wiring — Phase 30 (ASSUR-01/02). Phase 29 ships only the local signer + one positive control (D-11/D-12).
- Security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory — Phase 31 (DISC-01/02).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGV-01 | Response/assertion XMLDSig signatures cryptographically verified: canonicalized `SignedInfo` checked with `:public_key.verify` against the configured IdP cert pubkey (never document KeyInfo); forged/invalid rejected with typed `%Relyra.Error{}` | Verify shape confirmed end-to-end on OTP 28 (`:public_key.verify(SignedInfoBytes, :sha256, SigBytes, RSAPublicKey)` → `true`/`false`; tampered + forged → `false`). PEM→pubkey path (D-04) confirmed via `pkix_decode_cert(der, :otp)`. Sig-input C14N = `C14N.serialize/2` over the SignedInfo node (D-03). See Code Examples §1, §2. |
| SIGV-02 | Signed `Reference`'s `DigestValue` recomputed over the canonicalized, enveloped-signature-transformed referenced element and compared; content tampering (altered NameID) rejected even with well-formed SignatureValue | Digest recompute = `:crypto.hash(digest_atom, canonical_reference_bytes)`; canonical bytes already produced by the proven `PureBeam.canonicalize/2` → `C14N.canonicalize_reference/4` (Phase 28). Constant-time compare via `:crypto.hash_equals/2` (length-guarded). See Code Examples §3 + Pitfall 4. |
| SIGV-04 | Metadata-root signatures (`EntityDescriptor`/`EntitiesDescriptor`) cryptographically verified using the same primitive (signature math, not pinning alone), preserving operator-pinned `TrustAnchor` as defense-in-depth | Same `do_verify/4` primitive (D-13). BLOCKER surfaced: `auto_refresh.ex:pre_parse_for_signature/1` is regex-derived and does NOT surface the tree-bound crypto inputs — must be upgraded to feed the same fields (Runtime State Inventory + Open Questions). `TrustAnchor.check/2` already runs BEFORE `verify_metadata_root` in `do_verify_signature` (`auto_refresh.ex:152-156`). |

## Standard Stack

This phase adds **no new dependencies**. Per ADR-0001 it is pure-BEAM, using only OTP's bundled `:public_key` and `:crypto` applications plus the in-repo Phase 28 C14N engine. The "stack" is therefore an OTP-API surface, not a package list.

### Core (OTP-bundled, no install)
| API | Module | Purpose | Why Standard |
|-----|--------|---------|--------------|
| `:public_key.verify/4` | `:public_key` (OTP `public_key` app) | RSASSA-PKCS1-v1_5 signature verify of canonical SignedInfo | The only correct pure-BEAM XMLDSig RSA verify primitive; ADR-0001 mandates pure-BEAM |
| `:public_key.pkix_decode_cert/2` | `:public_key` | Decode DER cert → `OTPCertificate` → SubjectPublicKeyInfo → `:RSAPublicKey` record | D-04 trust-source extraction |
| `:public_key.pem_decode/1` + `pem_entry_decode/1` | `:public_key` | PEM → entry → DER (reuse `certificate_facts.ex:26-47` pattern) | Already the in-repo PEM idiom |
| `:crypto.hash/2` | `:crypto` | Recompute Reference digest (`:sha256`/`:sha384`/`:sha512`) | D-05 digest recompute |
| `:crypto.hash_equals/2` | `:crypto` | Constant-time digest comparison (OTP 25+) | D-05 / discretion item; confirmed on OTP 27/28 matrix |
| `Base.decode64/2` | Elixir `Base` | Decode declared `DigestValue` / raw `SignatureValue` | XMLDSig encodes both base64 |

### Supporting (in-repo, Phase 28)
| Module/Fn | Purpose | When to Use |
|-----------|---------|-------------|
| `C14N.serialize/2` | Bare exclusive-C14N of a node (no transform) | Canonicalize `SignedInfo` for the sig-math input (D-03) |
| `PureBeam.canonicalize/2` → `C14N.canonicalize_reference/4` | Transformed referenced-element canonical bytes | Digest recompute input (D-05) — already wired over the bound `:node` |
| `AlgorithmPolicy.enforce_signature_method/2` + `enforce_digest_method/2` | Algorithm allowlist (runs before crypto) | Already invoked in `verify_algorithms_and_candidates/3` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure-BEAM `:public_key.verify` | xmlsec NIF (`esaml`/native) | ADR-0001 rollback ONLY — adds precompiled-target matrix + supply-chain/CI complexity. Not this phase. |
| `:crypto.hash_equals/2` | Manual constant-time XOR-fold helper | Both viable; `hash_equals/2` is built-in on the OTP 27/28 matrix and simpler. Caveat: it RAISES on unequal lengths — guard byte-length first (Pitfall 4). |
| `pkix_decode_cert(der, :otp)` extraction | `pkix_decode_cert(der, :plain)` + `der_decode(:RSAPublicKey, ...)` | Both produce the IDENTICAL `:RSAPublicKey` record (verified `plain == otp`). The `:otp` path is cleaner (no extra `der_decode`); `:plain`'s SubjectPublicKey is a raw DER bitstring needing `der_decode`. Recommend `:otp`. |

**Installation:** None. `:public_key` and `:crypto` are already started (OTP bundled; `:crypto` is a dependency of every TLS/PEM operation already in use via `certificate_facts.ex`).

## Package Legitimacy Audit

> Not applicable — this phase installs NO external packages. It uses only OTP-bundled applications (`:public_key`, `:crypto`) and in-repo Phase 28 modules. slopcheck/registry verification is moot. No package-supply-chain surface is introduced.

## Architecture Patterns

### System Architecture Diagram

```
ASSERTION PATH (verify/4, flow :sp_initiated)            METADATA-ROOT PATH (verify_metadata_root/4, flow :metadata_refresh)
─────────────────────────────────────────              ──────────────────────────────────────────────────────────────────
response XML                                            fetched metadata XML
   │                                                       │
   ▼                                                       ▼ (AutoRefresh.do_verify_signature)
PureBeam.parse_safely/2                                 extract_candidate_signing_pems  ─┐
   │ (Saxy tree, XXE guards, single trust path)            │                            │ TrustAnchor.check (pinning,
   ▼                                                       ▼                            │  DEFENSE-IN-DEPTH, runs FIRST)
parsed_doc (+ :parse_tree)                              pre_parse_for_signature  ◀───────┘  ⚠ TODAY regex-only; D-13 must
   │  signed_candidates: [{:node, :signature_node,         │  (must surface tree-bound        upgrade to tree-bound fields
   │   :transforms_node, +D-02 :signed_info_node,          │   :node/:signed_info_node/
   │   :digest_value_b64, :signature_value_b64}]           │   :digest_value_b64/:signature_value_b64)
   │                                                       │
   └───────────────────────────┬───────────────────────────┘
                               ▼
                    Signature.do_verify/4   (SHARED trust primitive — wire crypto ONCE)
                               │
            ┌── existing gates run FIRST (unchanged, fail-closed) ──┐
            │  cert_chain == [] → :untrusted_certificate            │
            │  key_info_trust == true → :untrusted_certificate      │   ◀ KeyInfo NEVER a key source
            │  duplicate_ids → :duplicate_xml_id                    │
            │  algorithm allowlist (enforce_signature/digest)       │
            │  exactly-one signed candidate                         │
            └───────────────────────┬──────────────────────────────┘
                                    ▼  verified_signed_node/4  [candidate] arm  (D-01 — THE bypass site)
                    ┌──────────────────────────────────────────────┐
                    │ 1. map signature_method → digest_atom (D-06)  │
                    │    ECDSA → :unsupported_signature_algorithm    │ (D-07 fail-closed)
                    │ 2. extract pubkey from cert_chain PEM (D-04)   │
                    │    pkix_decode_cert(:otp) → :RSAPublicKey      │ fail → :untrusted_certificate
                    │ 3. SIG MATH (D-03):                            │
                    │    C14N.serialize(SignedInfo node)             │
                    │    Base.decode64(SignatureValue)               │ malformed → :invalid_signature
                    │    :public_key.verify(c14n, atom, sig, pub)    │ false    → :invalid_signature
                    │ 4. DIGEST CHECK (D-05):                        │
                    │    PureBeam.canonicalize(node) → ref bytes     │ error → :canonicalization_failed
                    │    :crypto.hash(atom, ref bytes)               │
                    │    Base.decode64(DigestValue)                  │
                    │    length-guard + :crypto.hash_equals/2        │ mismatch → :digest_mismatch
                    └───────────────────────┬──────────────────────┘
                                           ▼
                         ALL pass → {:ok, %SignedNode{}}   |   any fail → {:error, %Relyra.Error{type: ...}}
```

A reader can trace either flow from XML input to `{:ok}`/`{:error}` by following the arrows; both converge on `do_verify/4` so the crypto is written once.

### Pattern 1: Wire crypto into the SHARED primitive, gates-before-crypto
**What:** Add the crypto to `verified_signed_node/4`'s `[candidate]` arm (D-01), AFTER all existing trust gates in `do_verify/4`/`verify_algorithms_and_candidates/3`. Because both public entry points delegate to `do_verify/4`, the crypto covers SIGV-01/02 (assertions) and SIGV-04 (metadata) in one place.
**When to use:** Always for this phase — never duplicate the crypto in `verify/4` and `verify_metadata_root/4`.
**Example:** See Code Examples §1.

### Pattern 2: Fail-closed on every ambiguity; map raises to typed errors
**What:** `:public_key.verify/4` returns `false` for a bad signature/garbage SignatureValue (confirmed: no raise), but CAN raise on a malformed *public key* or malformed decoded ASN.1. Wrap crypto + PEM-decode in `try/rescue` (the `certificate_facts.ex:39-47` idiom) and map any rescue to `:untrusted_certificate` (key extraction) or `:invalid_signature` (verify path). `Base.decode64/2` returns `:error` on malformed base64 — map to `:invalid_signature` (SignatureValue) / `:digest_mismatch`-or-`:invalid_signature` (DigestValue). Never let an exception escape as a non-`%Relyra.Error{}`.
**When to use:** Every crypto/decode call on the trust path.

### Pattern 3: SignedInfo uses bare serialize; Reference uses the transform chain
**What:** D-03 — the `SignedInfo` element has NO enveloped-signature transform on itself, so canonicalize it with `C14N.serialize/2` (with PrefixList read from the SignedInfo's own `ds:CanonicalizationMethod`/`InclusiveNamespaces` if present). The Reference's referenced element DOES carry the enveloped-signature + exc-c14n transform chain, so use `PureBeam.canonicalize/2` (which delegates to `canonicalize_reference/4` with the enveloped-signature prune). These are DIFFERENT C14N entry points — do not conflate.
**When to use:** SignedInfo → `serialize/2`; referenced element → `canonicalize/2`.

### Anti-Patterns to Avoid
- **Trusting document `KeyInfo`:** The pubkey MUST come from the configured `cert_chain` (D-04). The `key_info_trust == true` rejection (`signature.ex:113-119`) stays and runs before crypto. Never read `<ds:KeyInfo><X509Certificate>` from the document as a key source.
- **A second divergent signer:** The Phase-29 local signer (D-11) must produce bytes the existing C14N engine canonicalizes identically; write it so Phase 30 can promote it into `FakeIdP` (D-12). A second signer that canonicalizes differently would make the positive control pass for the wrong reason.
- **Calling `:crypto.hash_equals/2` without a length guard:** It raises `ArgumentError` on unequal-length inputs (reproduced). A malformed declared `DigestValue` decoding to the wrong length would crash instead of returning `:digest_mismatch`.
- **Using `canonicalize_reference/4` on SignedInfo:** SignedInfo has no enveloped-signature transform; using the reference path would request a prune that doesn't apply and risks wrong bytes.
- **Skipping the metadata-root plumbing upgrade:** Wiring crypto into `do_verify` without upgrading `auto_refresh.ex:pre_parse_for_signature` means SIGV-04's positive control can't even reach the crypto (its candidates lack `:node`/`:signed_info_node`). It would fail-closed (good) but SIGV-04's positive control would never go green.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RSA PKCS#1 v1.5 verify | Custom modexp / PKCS#1 padding check | `:public_key.verify/4` | OTP's verify is the audited primitive; default padding is RSASSA-PKCS1-v1_5 (confirmed == explicit `:rsa_pkcs1_padding`) which is exactly XMLDSig `rsa-sha256/384/512` |
| Cert → public key extraction | Hand-parse ASN.1 / BIT STRING | `:public_key.pkix_decode_cert(der, :otp)` → `:RSAPublicKey` | `:otp` decode yields the ready `:RSAPublicKey` record directly (no manual `der_decode`); manual ASN.1 is an error/security minefield |
| Constant-time compare | Naive `==` on digests | `:crypto.hash_equals/2` (length-guarded) | `==` is short-circuit / timing-leaky; `hash_equals/2` is constant-time and built-in on OTP 27/28 |
| Exclusive-C14N | Re-derive serialization | Phase 28 `C14N` engine (PROVEN byte-equal to libxml2, 887-byte golden) | Already the proven precondition (SIGV-03); re-deriving re-opens the differential class |
| base64 decode | Manual base64 | `Base.decode64/2` | Returns `:error` on malformed input (no raise) — clean typed-error mapping |
| Digest recompute | Manual SHA | `:crypto.hash/2` | Standard, correct, supports `:sha256`/`:sha384`/`:sha512` (all confirmed) |

**Key insight:** The entire crypto surface for this phase is ~6 OTP calls. The engineering risk is in the *plumbing and fail-closed mapping*, not the algorithms. Every hand-rolled crypto/ASN.1 helper added here is pure downside.

## Runtime State Inventory

> This is a verification-wiring phase, not a rename/migration. It does change the **runtime trust contract**: code that previously returned `{:ok}` structurally will now require genuine signatures. The inventory below tracks what existing runtime state / fixtures break under the new behavior.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore stores signature material; `cert_chain`/`idp_certificates` PEMs and `metadata_trust_fingerprints` (`metadata_source.ex:47`) are already persisted and are READ unchanged. | None — verified by grep of `lib/relyra/ecto/`. |
| Live service config | None — no external service holds signature state. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | `RELYRA_XML_STRATEGY: pure_beam` (CI env, `security-gates.yml:27`) — unchanged; this phase stays on the pure-BEAM seam. No new env vars. | None. |
| Build artifacts / fixtures | (1) **Every structure-only "signed" test fixture** that previously verified as `{:ok}` will now FAIL crypto (they carry self-closing / empty `ds:SignatureValue`, no genuine sig — grep found only structure-only `SignatureValue` in `c14n_transform_test.exs`, NO genuinely-signed fixtures exist). (2) `FakeIdP.response_xml` (`fake_idp.ex:126-131`) omits `DigestValue`/`SignatureValue` content; `sign/2` only base64-encodes the XML — no genuine signature. (3) Existing `signature_test.exs`/`signed_node_binding_test.exs` assert trust-GATE rejections (cert_chain empty, KeyInfo, dup-ID, ambiguous) — these stay green (gates run BEFORE crypto). (4) The 887-byte C14N golden stays green under the Option-a fix (whitespace-free); a NEW mixed-content golden must be added. | Tests that previously asserted `{:ok}` on structure-only input must be re-pointed at the new positive control (genuine signer), or updated to assert the new crypto-rejection. The planner must inventory existing `{:ok}`-asserting tests and decide per test (most relevant: any test feeding a full Response through `ValidationPipeline` expecting login success). |

**The canonical question:** *After the crypto lands, which existing tests/fixtures that asserted `{:ok}` will now correctly reject?* Answer: all of them that fed structure-only "signatures" — there is no genuinely-signed fixture in the repo today (grep-confirmed). The planner MUST budget a task to triage `{:ok}`-asserting tests against the new behavior, and the positive control (D-11) is the ONLY input that should remain `{:ok}`.

## Common Pitfalls

### Pitfall 1: Mixed-content C14N mis-ordering defeats EVERY realistic positive control
**What goes wrong:** `C14N.render_element/3` (`c14n.ex:257-268`) emits `escape_text(node.text)` BEFORE `child_iodata`. For any element with inter-element whitespace (i.e. any pretty-printed real-IdP XML), the canonical bytes differ from libxml2/xmlsec → recomputed digest ≠ declared `DigestValue` → `:digest_mismatch`.
**Why it happens:** `SaxyTree.Node` models one flat `:text` per element (`saxy_tree.ex:69`), losing text↔child document order.
**How to avoid:** Implement D-09 Option-a (ordered `content: [{:text,_}|{:element,_}]`, walk in document order, keep `:text`/`:children` as derived views). I reproduced the exact divergence: buggy `"<Assertion>\n  \n<Issuer>X</Issuer></Assertion>"` vs correct `"<Assertion>\n  <Issuer>X</Issuer>\n</Assertion>"` — different SHA-256. This is a HARD precondition (D-10), not optional.
**Warning signs:** Positive control fails with `:digest_mismatch` despite a valid signature; whitespace-free fixtures pass but pretty-printed ones don't.

### Pitfall 2: Metadata-root path can't reach the crypto (regex parsed_doc)
**What goes wrong:** `auto_refresh.ex:pre_parse_for_signature/1` builds `signed_candidates: [%{xml_id, xpath, signed_xml}]` via regex (no `:node`, no `:signed_info_node`, no base64 values). Wiring crypto into `do_verify` makes the metadata path fail-closed (good) but the SIGV-04 positive control can never go `{:ok}`.
**Why it happens:** Phase 21 built the metadata pre-parse with regex before the Phase 28 tree existed; Phase 28 only re-wired `PureBeam`, explicitly leaving `AutoRefresh`'s own parsed_doc untouched (28-03-SUMMARY note).
**How to avoid:** D-13 requires upgrading the metadata pre-parse to surface the same tree-bound crypto inputs the assertion path has — ideally by routing the metadata root through the same tree builder (`SaxyTree.parse` + a metadata-root variant of `signed_candidates`) rather than a second regex extractor. The planner must scope this as an explicit task; it is the gating dependency for SIGV-04's positive control.
**Warning signs:** SIGV-04 negative tests pass but the positive control returns `:canonicalization_failed`/`:missing_signature` because the candidate has no `:node`.

### Pitfall 3: `:public_key.verify/4` / PEM-decode raises on malformed keys
**What goes wrong:** `verify/4` returns `false` for a bad signature or garbage SignatureValue (confirmed, no raise), but RAISES on a malformed/undecodable public key; `pem_entry_decode/1` and `pkix_decode_cert/2` raise on malformed PEM/DER.
**Why it happens:** OTP crypto functions raise on structurally invalid inputs rather than returning errors.
**How to avoid:** Wrap PEM→pubkey extraction and the verify call in `try/rescue` (the `certificate_facts.ex:39-47` idiom) and map rescues to `:untrusted_certificate` (extraction) / `:invalid_signature` (verify). Never let a raw exception become a `{:error, %Relyra.Error{}}`-violating crash on the auth path.
**Warning signs:** Tests with a deliberately-corrupt cert PEM crash instead of returning `:untrusted_certificate`.

### Pitfall 4: `:crypto.hash_equals/2` raises on unequal lengths
**What goes wrong:** A declared `DigestValue` that base64-decodes to the wrong byte length (truncated, wrong algorithm width) passed to `:crypto.hash_equals/2` raises `ArgumentError` (reproduced) instead of yielding `:digest_mismatch`.
**Why it happens:** `hash_equals/2` requires equal-length binaries.
**How to avoid:** Guard `byte_size(recomputed) == byte_size(declared)` first; on mismatch return `:digest_mismatch` directly. Also handle `Base.decode64/2` returning `:error` → `:digest_mismatch`/`:invalid_signature`. Do NOT replace with `==` (timing leak).
**Warning signs:** Truncated-digest negative test crashes rather than rejecting.

### Pitfall 5: ECDSA silently fails-OPEN if not explicitly rejected
**What goes wrong:** XMLDSig (RFC 6931) encodes ECDSA signatures as raw fixed-width `r‖s`; `:public_key.verify` expects DER `Ecdsa-Sig-Value`. If an ECDSA method passes the allowlist (it currently does — `algorithm_policy.ex:36-38` lists ecdsa-sha256/384/512) and you call `verify/4` with raw `r‖s`, it returns `false` — which is fine — but if any code path treats "unsupported alg" as "skip crypto," it fails OPEN.
**Why it happens:** The allowlist permits ECDSA, but Phase 29 only implements RSA verify (D-07).
**How to avoid:** D-07 — detect ECDSA signature methods in the digest-atom/key-type mapping and return `:unsupported_signature_algorithm` (a REJECT), before any verify attempt. Fail-CLOSED: an ECDSA IdP is rejected, never silently accepted. (Consider whether to also tighten the allowlist, but the typed reject is the contract.)
**Warning signs:** An ECDSA-signed document returns `{:ok}` or a non-typed error.

### Pitfall 6: Wrong C14N entry point for SignedInfo
**What goes wrong:** Using `canonicalize_reference/4` (the Reference transform path) for `SignedInfo` requests an enveloped-signature prune that doesn't apply to SignedInfo, risking wrong bytes / fail-closed.
**Why it happens:** Both are "canonicalize" — easy to conflate.
**How to avoid:** D-03 — `SignedInfo` → `C14N.serialize/2` (bare, with its own PrefixList if the `ds:CanonicalizationMethod` carries `InclusiveNamespaces`). Referenced element → `PureBeam.canonicalize/2`.
**Warning signs:** Sig-math fails on a known-good positive control where the digest check passes.

## Code Examples

> All examples below were validated against the project runtime (OTP 28 / Elixir 1.19.5) via the proof-of-concept scripts described in Metadata. Record shapes are confirmed, not assumed.

### §1 Signature math (D-03 / SIGV-01) — `[VERIFIED: local PoC on OTP 28]`
```elixir
# Inside verified_signed_node/4's [candidate] arm, AFTER existing gates.
# signed_info_node :: SaxyTree.Node  (from D-02 extraction)
# signature_value_b64 :: binary       (ds:SignatureValue text, from D-02)
# public_key :: {:RSAPublicKey, n, e} (from cert_chain PEM, see §2)
# digest_atom :: :sha256 | :sha384 | :sha512 (from AlgorithmPolicy, D-06)

with {:ok, c14n_signed_info} <- C14N.serialize(signed_info_node, prefix_list: signed_info_prefix_list),
     {:ok, sig_bytes} <- decode_b64(signature_value_b64) do        # Base.decode64/2 -> :error => :invalid_signature
  if safe_verify(c14n_signed_info, digest_atom, sig_bytes, public_key) do
    :ok
  else
    {:error, Error.new(:invalid_signature, "SignatureValue failed cryptographic verification", details)}
  end
end

# safe_verify wraps the raise-on-bad-key case (Pitfall 3):
defp safe_verify(msg, digest_atom, sig, pubkey) do
  :public_key.verify(msg, digest_atom, sig, pubkey)
rescue
  _ -> false   # malformed key/ASN.1 -> treat as non-verifying (caller emits :invalid_signature)
end
```

### §2 Trust-source public-key extraction (D-04) — `[VERIFIED: local PoC on OTP 28]`
```elixir
# cert_chain :: [binary()] PEM list (configured IdP certs). Use the FIRST (leaf) cert.
# Mirrors certificate_facts.ex:26-47 (pem_decode + entry), then pkix_decode_cert(:otp).
defp public_key_from_cert_chain([pem | _]) do
  with [entry | _] <- :public_key.pem_decode(pem),
       der when is_binary(der) <- elem(entry, 1) do
    {:OTPCertificate, otp_tbs, _sigalg, _sig} = :public_key.pkix_decode_cert(der, :otp)
    {:OTPSubjectPublicKeyInfo, _algid, pubkey} = :erlang.element(8, otp_tbs)  # SPKI field
    {:ok, pubkey}   # pubkey is the :RSAPublicKey record directly (no der_decode needed)
  else
    _ -> {:error, :untrusted_certificate}
  end
rescue
  _ -> {:error, :untrusted_certificate}   # malformed PEM/DER (Pitfall 3)
end
# PoC confirmed: pkix_decode_cert(der,:otp) -> {:OTPCertificate, tbs, ...}; element(8,tbs) ->
# {:OTPSubjectPublicKeyInfo, algid, {:RSAPublicKey, n, e}}; round-trip sign/verify == true.
# NOTE: prefer extracting the SPKI field via the documented OTP record (pubkey_cert_records.hrl)
# rather than element/2 positional access if the executor wants resilience to record-shape drift.
```

### §3 Digest recompute + constant-time compare (D-05 / SIGV-02) — `[VERIFIED: local PoC on OTP 28]`
```elixir
# canonicalize/2 already produces transformed referenced-element bytes (Phase 28).
with {:ok, %{canonical_xml: ref_bytes}} <- PureBeam.canonicalize(candidate_handle),
     {:ok, declared} <- decode_b64(digest_value_b64) do
  recomputed = :crypto.hash(digest_atom, ref_bytes)
  # length-guard BEFORE hash_equals (Pitfall 4 — raises on unequal lengths):
  if byte_size(recomputed) == byte_size(declared) and :crypto.hash_equals(recomputed, declared) do
    :ok
  else
    {:error, Error.new(:digest_mismatch, "Recomputed Reference digest does not match DigestValue", details)}
  end
else
  {:error, %Error{} = e} -> {:error, e}                 # propagate :canonicalization_failed
  :error -> {:error, Error.new(:digest_mismatch, "DigestValue is not valid base64", details)}
end
# PoC confirmed: :crypto.hash_equals(d1,d1)==true; (d1,d3)==false; (<<1,2,3>>,<<1,2>>) RAISES.
```

### §4 URI→digest-atom + ECDSA fail-closed (D-06 / D-07) — `[CITED: 29-CONTEXT.md D-06/D-07]`
```elixir
# In AlgorithmPolicy (it already owns the allowlist):
def digest_atom_for_signature_method(uri) do
  cond do
    String.ends_with?(uri, "rsa-sha256") -> {:ok, :sha256}
    String.ends_with?(uri, "rsa-sha384") -> {:ok, :sha384}
    String.ends_with?(uri, "rsa-sha512") -> {:ok, :sha512}
    String.contains?(uri, "ecdsa")       -> {:error, :unsupported_signature_algorithm}  # D-07 fail-closed
    true                                 -> {:error, :unsupported_signature_algorithm}
  end
end
# Map the digest METHOD URI to the same atom for the digest recompute (D-06 *-sha256/384/512).
```

### §5 Phase-29 local genuine signer (D-11, test support) — `[VERIFIED: sign/verify PoC on OTP 28]`
```elixir
# Promotable into FakeIdP in Phase 30 (D-12). Uses FakeIdP's EXISTING RSA-2048 keypair.
# 1. Build the Response/Assertion XML (whitespace-free OR rely on the Option-a fix).
# 2. Canonicalize the referenced Assertion (enveloped-sig + exc-c14n) -> compute DigestValue.
# 3. Build SignedInfo embedding that DigestValue; canonicalize SignedInfo (C14N.serialize).
# 4. ds:SignatureValue = Base.encode64(:public_key.sign(c14n_signed_info, :sha256, private_key))
# 5. Configured cert_chain for the control = PEM of that keypair's self-signed cert.
priv = FakeIdP.keypair()                                  # {:RSAPrivateKey, ...} (fake_idp.ex:78-83)
sig  = :public_key.sign(c14n_signed_info, :sha256, priv)  # PoC: default padding == RSASSA-PKCS1-v1_5
signature_value = Base.encode64(sig)
# CRITICAL (D-12): canonicalize with the SAME C14N engine the verifier uses, so the bytes match.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `verified_signed_node/4` returns `{:ok}` with ZERO crypto | `:public_key.verify` + digest recompute on the trust path | This phase (SIGV-01/02) | Closes the published-hex auth bypass |
| Metadata-root parsed_doc via regex (`auto_refresh.ex`) | Tree-bound parsed_doc surfacing crypto inputs | This phase (D-13/SIGV-04) | Removes a parser differential on the metadata path |
| Manual constant-time helpers (older OTP) | `:crypto.hash_equals/2` (OTP 25+) | OTP 25 (2022); confirmed on the 27/28 CI matrix | Simpler, built-in constant-time compare |
| `verify/3` (3-arity, older signatures) | `:public_key.verify/4` (msg, digesttype, sig, key) | Stable across OTP 26/27/28 (CONTEXT specifics) | The canonical verify shape; confirmed exported on OTP 28 |

**Deprecated/outdated:**
- SHA-1 signature/digest methods are gated behind the existing `legacy_sha1` override in `AlgorithmPolicy` (deprecated by default) — not in this phase's RSA-SHA256/384/512 scope.
- xmerl-based C14N (`esaml`/`xmerl_c14n`) — inclusive-only and carries CVE-2026-28809 XXE (per 28-02 / ADR-0001); the hand-rolled exclusive-C14N engine replaced it.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Configured `cert_chain` leaf cert is the SIGNING cert (use first PEM) for the assertion path | Code §2 | If an IdP rotates / the chain is ordered CA-first, picking `[pem|_]` extracts the wrong key → false `:invalid_signature`. The planner should confirm `cert_chain`/`idp_certificates` ordering (validation_pipeline `cert_chain/2` returns the list as stored). MEDIUM risk — typical SAML stores the signing cert as the single/first entry. |
| A2 | The Phase-29 positive-control fixture will be whitespace-free OR the Option-a fix lands first | Pitfall 1, Code §5 | If the fixture has inter-element whitespace and Option-a is incomplete, the positive control fails `:digest_mismatch`. Mitigated by making D-09/D-10 a hard precondition. |
| A3 | `SignedInfo`'s own `ds:CanonicalizationMethod` for the in-scope IdPs is exclusive-C14N (`xml-exc-c14n#`), so `serialize/2` is correct for the sig-math input | Pattern 3, Code §1 | If an IdP declares inclusive C14N for SignedInfo, `serialize/2` (exclusive) emits wrong bytes → `:invalid_signature`. Okta/Entra/Google use exclusive-C14N in practice, but the planner should fail-CLOSED (reject unsupported CanonicalizationMethod) rather than assume. The C14N allowlist already rejects non-exclusive transforms. |
| A4 | `element(8, OTPTBSCertificate)` is the `subjectPublicKeyInfo` field across OTP 27/28 | Code §2 | Positional ASN.1-record access could drift if OTP changes the record. Confirmed on OTP 28. LOW risk (the OTP cert record is extremely stable), but the planner may prefer the `pubkey_cert_records.hrl` named-record accessor for resilience. |
| A5 | Existing `{:ok}`-asserting end-to-end tests feed structure-only signatures and will now correctly reject | Runtime State Inventory | If some existing test already feeds a genuine signature (none found via grep), behavior is unchanged. Verified: no genuinely-signed fixture exists. LOW risk. |

## Open Questions

1. **Metadata-root crypto-input plumbing (SIGV-04 gating dependency)**
   - What we know: `auto_refresh.ex:pre_parse_for_signature/1` is regex-derived; its candidates lack `:node`/`:signed_info_node`/`:digest_value_b64`/`:signature_value_b64`. `verify_metadata_root/4` delegates to `do_verify/4` (D-13), which will run the new crypto.
   - What's unclear: whether the planner routes the metadata root through the existing `SaxyTree.parse` + a metadata-root `signed_candidates` variant (preferred — single trust path), or extends the regex pre-parse to surface the fields (faster but re-introduces a differential).
   - Recommendation: route through the tree builder (matches Phase 28's "one trust path" / D-04 philosophy). Scope as an explicit task; it is the precondition for SIGV-04's positive control.

2. **PrefixList for the SignedInfo canonicalization**
   - What we know: `SignedInfo` is canonicalized with `serialize/2` (D-03); real IdPs sometimes put `<ec:InclusiveNamespaces PrefixList="...">` inside `ds:CanonicalizationMethod`.
   - What's unclear: whether the Phase-29 positive control + in-scope IdPs need a non-empty SignedInfo PrefixList.
   - Recommendation: read the PrefixList from the SignedInfo's `ds:CanonicalizationMethod` (reuse `prefix_list_from_transforms/1` shape) and thread it into `serialize/2`. The local signer (D-11) controls its own SignedInfo, so this can start empty and be exercised with a PrefixList in Phase 30.

3. **Cert leaf-selection / chain ordering** (see Assumption A1)
   - Recommendation: the planner should confirm with a test that the configured cert in fixtures is the signing leaf; if ambiguous, try each cert in the chain until one verifies (still rejecting if none do) — but keep it fail-closed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP `:public_key` | SIGV-01 (verify), D-04 (cert decode) | ✓ | OTP 28 local; OTP 27/28 CI matrix | — |
| Erlang/OTP `:crypto` (`hash/2`, `hash_equals/2`) | SIGV-02 digest recompute + constant-time compare | ✓ | OTP 28 local (`hash_equals/2` confirmed); 25+ everywhere on matrix | manual constant-time helper (discretion D) |
| Elixir `Base` | base64 decode of DigestValue/SignatureValue | ✓ | Elixir 1.19.5 | — |
| Phase 28 `C14N` engine | sig-math + digest canonical bytes | ✓ (in-repo, PROVEN byte-equal golden) | — | — (ADR-0001 rollback to xmlsec NIF only) |
| Docker + lxml/xmllint (out-of-band golden mint, D-10) | New mixed-content golden fixture | Used out-of-band in Phase 28; NOT in CI (D-12) | lxml 6.1.1 / libxml2 2.14.6 (per 28-04 PROVENANCE) | If no Docker at mint time: planner must flag — the golden is human-minted, CI reads committed bytes only |
| `openssl` (test cert generation for the positive control) | D-11 cert PEM for the configured cert_chain | ✓ (used in PoC) | system openssl | derive a self-signed cert in-process via `:public_key` (no openssl dep) |

**Missing dependencies with no fallback:** None. All crypto is OTP-bundled.
**Missing dependencies with fallback:** The mixed-content golden requires the out-of-band Docker oracle toolchain at MINT time only (CI stays pure-Elixir). If unavailable when the golden is minted, that single task blocks — but it is a human gate, consistent with Phase 28 D-12.

## Validation Architecture

> nyquist_validation is `true` in `.planning/config.json` — this section is REQUIRED and drives VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 / OTP 28; bundled) |
| Config file | none standalone — `test/test_helper.exs` (ExUnit.start); aliases in `mix.exs` (`mix qa`, `mix ci.fast`, `mix ci.security`) |
| Quick run command | `mix test test/relyra/security/signature_test.exs test/security/signed_node_binding_test.exs test/security/signature_policy_test.exs --warnings-as-errors` |
| Full suite command | `mix ci.security` (security gates) + `mix test --warnings-as-errors` (full) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGV-01 | Forged `SignatureValue` (valid structure) rejected `:invalid_signature` | unit (negative control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 (new crypto cases) |
| SIGV-01 | Wrong-key (genuine sig, different cert) rejected `:invalid_signature` | unit (negative control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 |
| SIGV-01 | Genuinely-signed node (D-11 signer) verifies `{:ok, %SignedNode{}}` | unit (POSITIVE control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 (needs D-11 signer) |
| SIGV-02 | Tampered `NameID` (otherwise-valid sig) rejected `:digest_mismatch` | unit (negative control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 |
| SIGV-02 | Truncated/malformed `DigestValue` rejected `:digest_mismatch` (no crash — Pitfall 4) | unit (negative control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 |
| SIGV-02 | Mixed-content canonical bytes match new golden (byte-exact) | golden-oracle (positive) | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` | ❌ Wave 0 (new mixed-content golden) |
| SIGV-04 | Metadata-root genuine signature verifies `{:ok}` (same primitive) | integration (positive) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 (needs metadata pre-parse upgrade) |
| SIGV-04 | Signature-VALID but wrong-fingerprint root rejected (pinning defense-in-depth) | integration (negative) | `mix test test/relyra/metadata/auto_refresh_test.exs -x` | ⚠️ extend (pinning tests exist; add the sig-valid+wrong-fp case) |
| D-07 | ECDSA method fails CLOSED `:unsupported_signature_algorithm` | unit (negative control) | `mix test test/relyra/security/signature_test.exs -x` | ❌ Wave 0 |
| D-01 (regression) | Existing trust GATES (cert_chain empty / KeyInfo / dup-ID / ambiguous) still reject BEFORE crypto | unit (regression) | `mix test test/security/signed_node_binding_test.exs --warnings-as-errors` | ✅ (must stay green) |
| D-10 (regression) | 887-byte exclusive-C14N golden still byte-exact under Option-a | golden-oracle (regression) | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` | ✅ (must stay green) |

### Sampling Rate
- **Per task commit:** `mix test test/relyra/security/signature_test.exs test/security/signed_node_binding_test.exs --warnings-as-errors` (the crypto + gate-regression unit lane, < 30s)
- **Per wave merge:** `mix test test/relyra/security/ test/security/ test/relyra/security/xml/ --warnings-as-errors` (security + C14N regression)
- **Phase gate:** `mix ci.security` green + full `mix test --warnings-as-errors` green before `/gsd:verify-work`

### Positive vs Negative Control Discipline (the heart of this phase)
- **Negative controls (rejection — the bypass is closed):** forged SignatureValue → `:invalid_signature`; tampered NameID → `:digest_mismatch`; wrong-key → `:invalid_signature`; truncated DigestValue → `:digest_mismatch` (NOT a crash); ECDSA → `:unsupported_signature_algorithm`; wrong-fingerprint metadata root → pinning reject. EACH asserts `{:error, %Relyra.Error{type: <named>}}`.
- **Positive controls (genuine sign → `{:ok}` — the system still WORKS):** D-11 local signer produces a genuinely-signed Assertion (assertion path) AND a genuinely-signed metadata root (SIGV-04). EACH asserts `{:ok, %SignedNode{}}`. Without a positive control, a verifier that rejects EVERYTHING would pass all negative tests — the positive control proves the verifier isn't just "always reject."
- **Golden-byte oracle discipline (mixed content):** the new mixed-content golden is minted OUT-OF-BAND (Docker lxml/xmllint, per Phase 28 D-12), committed as raw bytes, and CI asserts `canonicalize/2` output == committed bytes byte-for-byte. CI never invokes the native toolchain.

### Wave 0 Gaps
- [ ] `test/relyra/security/signature_test.exs` — extend with the crypto negative + positive controls (SIGV-01/02, D-07). (File exists, currently metadata-root-shim-only.)
- [ ] D-11 genuine signer (test support) — covers all positive controls. (`test/support/` or `Relyra.TestSupport.*` — discretion.)
- [ ] New mixed-content golden fixture under `test/fixtures/security/xml/parser_differential_and_c14n/` + PROVENANCE.md (Docker-minted) — covers SIGV-02 byte-exactness.
- [ ] `test/security/xml/corpus_security_test.exs` — add the mixed-content `@tag :gate02_c14n` byte-equality assertion (keep the 887-byte golden green).
- [ ] Metadata pre-parse upgrade test coverage in `test/relyra/metadata/auto_refresh_test.exs` (SIGV-04 positive + sig-valid/wrong-fp negative).
- [ ] Framework install: none — ExUnit is bundled.

## Security Domain

> `security_enforcement` is not explicitly `false` in config (absent = enabled). This is the milestone's keystone security phase.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | XMLDSig signature verification IS the authentication trust decision — `:public_key.verify` against configured cert (SIGV-01) |
| V3 Session Management | no | Session issuance is downstream of `{:ok, %SignedNode{}}`; not in this phase |
| V4 Access Control | no | N/A — this phase decides authenticity, not authorization |
| V5 Input Validation | yes | base64 decode of SignatureValue/DigestValue, malformed-PEM/DER handling, length guards — all fail-closed typed errors; XXE guards already run pre-parse (Phase 28) |
| V6 Cryptography | yes | `:public_key.verify` (RSASSA-PKCS1-v1_5), `:crypto.hash`, `:crypto.hash_equals` (constant-time) — NEVER hand-rolled (Don't Hand-Roll table) |
| V14 Config / Crypto Agility | yes | `AlgorithmPolicy` allowlist + digest-atom mapping; ECDSA fail-closed (D-07); SHA-1 gated by legacy override |

### Known Threat Patterns for XMLDSig SAML verification

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged SignatureValue (valid structure) | Spoofing | `:public_key.verify` returns false → `:invalid_signature` (SIGV-01) |
| Content tampering w/ reused signature (altered NameID) | Tampering | DigestValue recompute over canonicalized referenced element + constant-time compare → `:digest_mismatch` (SIGV-02) |
| Wrong-key / attacker-supplied key (KeyInfo trust) | Spoofing/Elevation | Key comes ONLY from configured `cert_chain`; `key_info_trust == true` rejected (`signature.ex:113-119`, D-04) |
| Signature Wrapping (XSW) | Tampering | Crypto consumes the EXACT bound `:node` (Phase 28 D-10 anti-XSW); enveloped-signature prune of the SPECIFIC ds:Signature |
| C14N differential (bytes signer ≠ bytes verifier sees) | Tampering | Phase 28 byte-exact C14N (PROVEN golden) + the D-09/D-10 mixed-content fix; single trust path (no parser differential) |
| Algorithm downgrade / unsupported ECDSA fail-open | Spoofing | Fail-CLOSED: ECDSA → `:unsupported_signature_algorithm`; SHA-1 gated; allowlist before crypto (D-07) |
| Timing side-channel on digest compare | Information Disclosure | `:crypto.hash_equals/2` constant-time (length-guarded) |
| Duplicate XML ID / ambiguous signed node | Tampering | Existing `:duplicate_xml_id` / `:ambiguous_signed_node` gates run BEFORE crypto (unchanged) |
| Metadata-root pinning bypass (sig-valid, wrong key) | Spoofing | `TrustAnchor.check` (pinning) runs BEFORE `verify_metadata_root`; signature math is the primary gate, pinning is defense-in-depth (D-13/SIGV-04) |
| Exception-as-bypass (malformed PEM/key crashes the path) | DoS / fail-open | try/rescue → typed `%Relyra.Error{}`; never let a raise escape (Pitfall 3) |

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` exists in the working directory (verified — Read returned "File does not exist"). The governing constraints are therefore ADR-0001 + the locked CONTEXT.md decisions + the existing CI gates:
- **ADR-0001:** pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam; xmlsec NIF is a conditional rollback ONLY (not a planned path). Parser usage outside the XML seam is blocked by `parser_path_guard` (compile-time + `mix.exs:17`).
- **Reuse the existing error union:** prefer reusing atoms where possible; `:digest_mismatch` and `:unsupported_signature_algorithm` are genuinely new (D-08) — `Relyra.Error` accepts any atom type (`error.ex:7`), but the planner should add them to the `xml_error_type` union doc in `xml.ex` if that's the seam convention (discretion item).
- **`--warnings-as-errors` everywhere** (every `mix qa`/`ci.*` alias enforces it).
- **Test-only signer:** `FakeIdP`/the new signer must stay test-scoped (`ensure_not_prod!` guard pattern, `fake_idp.ex:97-101`); never ship signing code in `:prod`.
- **Fix-first posture (MEMORY):** branch `security/xmldsig-real-verification`; the bypass is fully closed only when this phase's crypto verify ships. No embargo (solo dev, no adopters) — fix openly.

## Sources

### Primary (HIGH confidence)
- **Local PoC on the project runtime (OTP 28 / Elixir 1.19.5):** `:public_key.verify/4` (true/false/tampered/forged), `:public_key.sign/3` (default padding == RSASSA-PKCS1-v1_5; sha256/384/512), `:public_key.pkix_decode_cert(der, :otp)` → `:OTPCertificate` → element(8) → `:OTPSubjectPublicKeyInfo` → `:RSAPublicKey` (round-trip verify true; `:plain` == `:otp`), `:crypto.hash_equals/2` (match/mismatch/raise-on-unequal-length), mixed-content C14N byte-divergence reproduced. `[VERIFIED]`
- `lib/relyra/security/signature.ex` (the bypass site `verified_signed_node/4`, shared `do_verify/4`), `pure_beam.ex`, `c14n.ex` (render_element text-before-children bug at 257-268), `saxy_tree.ex` (Node shape), `algorithm_policy.ex`, `certificate_facts.ex` (PEM-decode pattern), `fake_idp.ex` (RSA-2048 keypair, structure-only sign), `auto_refresh.ex` (regex metadata pre-parse — SIGV-04 plumbing gap), `trust_anchor.ex`, `validation_pipeline.ex` (`cert_chain/2`). `[VERIFIED: codebase]`
- `.planning/phases/29-cryptographic-xmldsig-verification/29-CONTEXT.md` (D-01..D-13 — AUTHORITATIVE). `[CITED]`
- `.planning/REQUIREMENTS.md` (SIGV-01/02/04 acceptance), `.planning/STATE.md` (mixed-content fix = FIRST NEXT TASK; SIGV-03 PROVEN), `.planning/phases/28-real-c14n-parser-foundation/28-02/03/04-SUMMARY.md` (C14N API, seam wiring, golden discipline), `01-ADR.md`. `[CITED]`
- CI matrix: `.github/workflows/security-gates.yml` (OTP 27/28, Elixir 1.19.5). `[VERIFIED: CI config]`

### Secondary (MEDIUM confidence)
- `.planning/config.json` (`nyquist_validation: true`, `commit_docs: true`). `[VERIFIED]`

### Tertiary (LOW confidence)
- None — every load-bearing claim is verified against the codebase or the local runtime PoC.

## Metadata

**Confidence breakdown:**
- Crypto primitive (verify/sign/decode/hash_equals): **HIGH** — proven end-to-end on the exact runtime (OTP 28).
- PEM→pubkey extraction (D-04): **HIGH** — full round-trip confirmed; both `:otp` and `:plain` paths agree.
- Data plumbing gaps (D-02 extraction, D-13 metadata pre-parse): **HIGH** — grep-confirmed absent; metadata pre-parse is regex-only.
- Mixed-content C14N precondition (D-09/D-10): **HIGH** — bug reproduced; byte divergence demonstrated.
- ECDSA fail-closed rationale (D-07): **HIGH** — RFC 6931 raw `r‖s` vs OTP DER expectation is the documented mismatch; allowlist currently permits ECDSA so the explicit reject is mandatory.
- OTP matrix stability of `:public_key.verify/4` / `pkix_decode_cert/2`: **HIGH** for OTP 28 (verified); **HIGH** for OTP 27 (stable API per CONTEXT specifics; same record shapes).

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (stable — OTP crypto API + in-repo Phase 28 engine; 30 days)

## RESEARCH COMPLETE

**Phase:** 29 - Cryptographic XMLDSig verification
**Confidence:** HIGH

### Key Findings
- The entire crypto data flow is PROVEN on the project runtime (OTP 28): `:public_key.verify/4` (RSASSA-PKCS1-v1_5, sha256/384/512), PEM→`:RSAPublicKey` via `pkix_decode_cert(der, :otp)` → element(8) → SPKI, `:crypto.hash`/`hash_equals`. The crypto is ~6 OTP calls — small, well-understood.
- The real risk is PLUMBING + fail-closed mapping, not math: (1) `pure_beam.ex` doesn't yet extract base64 `DigestValue`/`SignatureValue` or the `SignedInfo` node (D-02); (2) the metadata-root path (`auto_refresh.ex:pre_parse_for_signature`) is regex-derived and CANNOT feed the crypto today — a SIGV-04 gating dependency (D-13).
- The mixed-content C14N bug is a HARD precondition (reproduced): `render_element/3` emits text before children → `:digest_mismatch` on every pretty-printed positive control. D-09/D-10 Option-a must land first/alongside.
- Two concrete pitfalls with code-level fixes: `:public_key.verify/4` raises on malformed KEYS (returns false on bad signatures) → wrap in try/rescue; `:crypto.hash_equals/2` RAISES on unequal-length inputs → length-guard before calling, else a truncated DigestValue crashes instead of returning `:digest_mismatch`.
- No genuinely-signed fixture exists in the repo (grep-confirmed) — the D-11 local signer is mandatory and is the ONLY input that should remain `{:ok}`; the planner must triage existing `{:ok}`-asserting tests against the new reject-by-default behavior.

### File Created
`/Users/jon/projects/relyra/.planning/phases/29-cryptographic-xmldsig-verification/29-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack (OTP crypto API) | HIGH | Verified end-to-end on OTP 28; no external deps |
| Architecture (shared do_verify primitive, gates-before-crypto) | HIGH | Codebase-confirmed delegation; both entry points share do_verify |
| Pitfalls | HIGH | Mixed-content bug + hash_equals raise reproduced locally |
| Metadata-root SIGV-04 plumbing | HIGH (as a GAP) | Regex pre-parse confirmed; upgrade is a scoped task |

### Open Questions
- Metadata-root crypto-input plumbing: route the metadata root through the tree builder (preferred, single trust path) vs extend the regex pre-parse. Gating dependency for SIGV-04's positive control.
- SignedInfo PrefixList handling for the in-scope IdPs (start empty for the local signer; exercise with PrefixList in Phase 30).
- Cert leaf-selection / chain ordering (Assumption A1) — confirm the configured cert is the signing leaf, or try-each-cert fail-closed.

### Ready for Planning
Research complete. Every locked decision (D-01..D-13) is implementable as written; no decision needed contradicting. The planner should sequence: (1) mixed-content C14N Option-a fix + new golden, (2) `pure_beam.ex` D-02 field extraction, (3) crypto primitive in `do_verify`, (4) metadata pre-parse upgrade (SIGV-04), (5) D-11 local signer + positive controls + negative-control matrix, with the existing trust-gate and 887-byte-golden regressions kept green throughout.
