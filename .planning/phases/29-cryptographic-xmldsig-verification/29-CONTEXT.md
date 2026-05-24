# Phase 29: Cryptographic XMLDSig verification - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire **real cryptographic XMLDSig verification** into the existing `Relyra.Security.Signature` seam: `:public_key.verify` of the canonicalized `SignedInfo` against the **configured** IdP certificate's public key, plus `DigestValue` recompute/compare over the canonicalized, enveloped-signature-transformed referenced element — applied to BOTH `verify/4` (assertion/response) and `verify_metadata_root/4` (metadata root). A forged, tampered, or wrong-key input is rejected with a typed `%Relyra.Error{}`; a genuinely-signed node from the configured IdP returns `{:ok, %SignedNode{}}`. Closes the published-hex auth bypass.

**Requirements:** SIGV-01 (signature math), SIGV-02 (digest recompute/compare), SIGV-04 (metadata-root parity).

**In scope:** the crypto math, the data plumbing to feed it, the mixed-content C14N correctness fix it depends on, and ONE genuinely-signed positive control.

**NOT in scope (Phase 30 — ASSUR-01/02):** wholesale `FakeIdP` real-signing integration, the permanent adversarial corpus (forged/tampered/wrong-key/digest-mismatch/c14n-differential), and `corpus_gate`/conformance-manifest wiring. **NOT in scope (Phase 31 — DISC):** security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory. Full XMLDSig **ECDSA** support (raw `r‖s`→DER converter) is a deferred fast-follow, not this phase.
</domain>

<decisions>
## Implementation Decisions

### Crypto verification wiring & data plumbing
- **D-01:** Rewrite the `[candidate]` arm of `verified_signed_node/4` (`lib/relyra/security/signature.ex:159-185`) to perform real signature math. It currently returns `{:ok, %SignedNode{}}` with ZERO crypto — this is the auth-bypass site. All existing trust-discipline gates (cert_chain present, `key_info_trust` rejection, duplicate-ID rejection, algorithm allowlist, single-signed-node selection) stay and run BEFORE the crypto.
- **D-02:** `pure_beam.ex` must additionally surface, per signed candidate: the declared **`DigestValue`** (trimmed text of the bound Reference's `ds:DigestValue`, base64) and the raw **`SignatureValue`** (`ds:SignatureValue`, base64), plus the **`SignedInfo`** tree node. Today candidates carry only `:node`/`:signature_node`/`:transforms_node` (per Phase 28, `28-03-SUMMARY.md`); neither base64 value is extracted anywhere yet (`grep`-confirmed).
- **D-03:** **Signature check** = `C14N.serialize/2` over the `SignedInfo` node (NOT `canonicalize_reference/4` — `SignedInfo` carries no enveloped-signature transform), then `:public_key.verify(canonical_signed_info, digest_atom, decoded_signature_value, public_key)`.
- **D-04:** **Trust source** = public key extracted from the configured `cert_chain` PEM via `:public_key.pkix_decode_cert/2` → `SubjectPublicKeyInfo` → `SubjectPublicKey` (reuse the PEM-decode pattern at `lib/relyra/ecto/certificate_facts.ex:26-47`). NEVER document `KeyInfo` — the existing `key_info_trust == true` rejection (`signature.ex:113-119`) stays.
- **D-05:** **Digest check** = recompute `:crypto.hash(digest_atom, canonical_reference_bytes)` where `canonical_reference_bytes` come from the EXISTING `canonicalize/2` path (`C14N.canonicalize_reference/4` over the bound `:node`, enveloped-signature-transformed), and **constant-time** compare against the base64-decoded declared `DigestValue`.
- **D-06:** **URI→digest-atom mapping** lives in `Relyra.Security.AlgorithmPolicy` (it already owns the allowlist, `algorithm_policy.ex:30-47`): `*-sha256`→`:sha256`, `*-sha384`→`:sha384`, `*-sha512`→`:sha512`.
- **D-07:** **Algorithm scope = RSA-SHA256/384/512 verified for real now; ECDSA fails CLOSED** with a typed `:unsupported_signature_algorithm` error. The XMLDSig ECDSA `r‖s`→DER converter is a deferred fast-follow (real IdPs in scope — Okta/Entra/Google — sign RSA). This is fail-CLOSED, never fail-open: an ECDSA IdP is rejected, not silently accepted.
- **D-08:** **Error taxonomy** (each names the failed check): `:invalid_signature` (`:public_key.verify` false / malformed SignatureValue), new **`:digest_mismatch`** (recomputed Reference digest differs), `:untrusted_certificate` (PEM→key extraction fails), `:unsupported_signature_algorithm` (ECDSA / unhandled alg), `:canonicalization_failed` (propagated from C14N). `Relyra.Error` accepts any atom `type` (`error.ex:7`).

### Mixed-content C14N correctness fix (folded into this phase)
- **D-09:** Implement **Option-a** from `28-04-SUMMARY.md`: add an ordered `content: [{:text, _} | {:element, _}]` field to `Relyra.Security.XML.SaxyTree.Node`, have `C14N.render_element/3` walk it in document order, and keep `:text`/`:children` as DERIVED views so `pure_beam.ex` field-derivation helpers (`first_text`/`all_texts`/`trimmed_text`, ~`pure_beam.ex:443-459`) stay unchanged. ~55 LOC.
- **D-10:** This fix is a HARD precondition for the positive control. `c14n.ex:262-263` currently emits `node.text` BEFORE all children, so any pretty-printed / mixed-content signed XML mis-canonicalizes → `:digest_mismatch` on every realistic real-IdP positive control. It must land before/alongside D-13. Keep the existing 887-byte exclusive-C14N golden green and ADD a mixed-content golden (minted out-of-band in Docker per the Phase 28 D-12 discipline; CI stays pure-Elixir against committed bytes).

### Positive-control fixture (Phase-29-local genuine signer)
- **D-11:** Phase 29 builds its OWN minimal real XMLDSig signer to produce at least one genuinely-signed node that returns `{:ok, %SignedNode{}}` (success criterion #3). Approach: C14N the `SignedInfo` → `:public_key.sign/3` (`:sha256`) with `FakeIdP`'s EXISTING RSA-2048 keypair (`fake_idp.ex:85-95`); emit real `ds:DigestValue` + `ds:SignatureValue` (today `fake_idp.ex:126-131` omits both and `sign/2` only base64-encodes — there is NO genuinely-signed node anywhere yet). Configured `cert_chain` for the control = the PEM of that same keypair's cert.
- **D-12:** **Phase boundary respected.** Wholesale `FakeIdP` real-signing + the full adversarial corpus + `corpus_gate`/manifest wiring stay in **Phase 30 (ASSUR-01/02)**. Write the Phase-29 signer so Phase 30 can PROMOTE it into `FakeIdP` (avoid a divergent second signer that would canonicalize differently).
- **D-13:** **SIGV-04 metadata-root** is proven by the SAME `do_verify` signature-math primitive on an `EntityDescriptor`/`EntitiesDescriptor`-shaped `parsed_doc` (`verify_metadata_root/4` already delegates verbatim to `do_verify/4`, `signature.ex:76`). Add a positive control AND assert operator-pinned `TrustAnchor` fingerprint pinning still rejects a signature-valid-but-wrong-fingerprint root — signature math first, pinning as defense-in-depth (not pinning alone).

### Claude's Discretion
- Exact internal helper module/function names for the new crypto path (e.g. whether the signer lives in `test/support` or a `Relyra.TestSupport` module), and whether `:digest_mismatch`/`:unsupported_signature_algorithm` are added to the `xml_error_type` union in `xml.ex` — planner/executor decide, consistent with existing seam conventions.
- Whether constant-time digest compare uses `:crypto.hash_equals/2` (OTP 25+) vs a manual constant-time helper — pick what the OTP matrix supports cleanly.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md` — **ADR-0001** (governs: pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam; xmlsec NIF is a conditional rollback ONLY, not a planned path).
- `.planning/REQUIREMENTS.md` — SIGV-01 / SIGV-02 / SIGV-04 acceptance language.
- `.planning/phases/28-real-c14n-parser-foundation/28-02-SUMMARY.md` — C14N engine API: `C14N.serialize/2`, `canonicalize_reference/4`, `transform_uris/1`, `prefix_list_from_transforms/1`; strict transform allowlist.
- `.planning/phases/28-real-c14n-parser-foundation/28-03-SUMMARY.md` — seam re-wire: handle gains `:node`/`:signature_node`/`:transforms_node` bound to the EXACT tree node (anti-XSW, D-10); `canonicalize/2` delegates to `canonicalize_reference/4`; XXE-before-verify guards run before Saxy.
- `.planning/phases/28-real-c14n-parser-foundation/28-04-SUMMARY.md` — mixed-content / inter-element-whitespace limitation + the Option-a fix detail + golden-byte oracle discipline (D-11/D-12 of Phase 28).
- Source files to extend: `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/security/xml/c14n.ex`, `lib/relyra/security/xml/saxy_tree.ex`, `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/security/signed_node.ex`, `lib/relyra/test_support/fake_idp.ex`. Pattern reference for PEM decode: `lib/relyra/ecto/certificate_facts.ex:26-47`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **C14N engine (Phase 28, proven byte-for-byte vs libxml2):** `C14N.serialize/2` for a bare node (use for `SignedInfo`) and `canonicalize_reference/4` for the transformed referenced element (already wired through `pure_beam.ex` `canonicalize/2`).
- **Bound signed node (anti-XSW):** the handle's `:node`/`:signature_node`/`:transforms_node` are bound to the exact tree node C14N serializes — the crypto consumes the SAME node, no differential.
- **PEM decode pattern:** `certificate_facts.ex:26-47` already does `:public_key.pem_decode` + `pem_entry_decode` for cert validity — reuse for public-key extraction.
- **AlgorithmPolicy** (`algorithm_policy.ex:30-47`) already owns the signature/digest URI allowlist + `enforce_signature_method`/`enforce_digest_method` — the URI→atom mapping belongs here.
- **FakeIdP RSA-2048 keypair** already generated (`fake_idp.ex:85-95`) — reuse for the Phase-29 signer; do not generate a second keypair.

### Established Patterns
- **Telemetry span wrapper:** both `verify/4` and `verify_metadata_root/4` already wrap `do_verify` in `Relyra.Telemetry.span([:signature, :verify], ...)` with `:ok`/`:error` outcome + algorithm tags — new error types flow through `error.type` automatically.
- **Typed errors:** `{:ok, %SignedNode{}} | {:error, %Relyra.Error{}}` is the seam contract; every failed check names the field/reason in `Error` details.
- **One trust path / fail-closed:** Phase 28 retired all regex extractors; everything is re-derived from the saxy tree in one pass. New crypto must fail CLOSED (reject) on any ambiguity — never fall through to `{:ok}`.

### Integration Points
- `do_verify/4` is the SHARED primitive for assertion verify (`verify/4`, flow `:sp_initiated`) and metadata-root verify (`verify_metadata_root/4`, flow `:metadata_refresh`) — wiring crypto once covers both (SIGV-01/02 + SIGV-04).
- Metadata-root pinning plumbing (`metadata_trust_fingerprints` / `TrustAnchor`) lives in `lib/relyra/ecto/metadata_source.ex` + `lib/relyra/metadata/*`; the signature-math runs first, pinning is defense-in-depth.
- `cert_chain` is the configured IdP PEM list flowing in from the connection/resolver — the trust source, distinct from any document `KeyInfo`.
</code_context>

<specifics>
## Specific Ideas

- **`:public_key.verify/4` shape (resolved, stable across OTP 26/27/28):** `:public_key.verify(SignedInfoBytes, :sha256, SignatureValueBytes, PubKey)`, where `PubKey` is the `#'RSAPublicKey'{}` (or EC tuple) extracted from `:public_key.pkix_decode_cert/2`'s `SubjectPublicKeyInfo`.
- **ECDSA encoding (resolved):** XMLDSig (RFC 6931) encodes ECDSA signatures as raw fixed-width `r‖s`; Erlang `:public_key.verify` expects DER `Ecdsa-Sig-Value`. The mismatch is exactly why ECDSA is fail-closed for now (D-07) — full support needs a raw→DER converter (deferred).
</specifics>

<deferred>
## Deferred Ideas

- **Full XMLDSig ECDSA support** (`r‖s`→DER re-encode + verify) — fast-follow after v1.1; fail-closed in Phase 29 (D-07).
- **Wholesale FakeIdP real-signing + adversarial crypto corpus + corpus_gate/manifest wiring** — Phase 30 (ASSUR-01/02). Phase 29 ships only the local signer + one positive control (D-11/D-12).
- **Security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory** — Phase 31 (DISC-01/02).

### Reviewed Todos (not folded)
None — no pending todos matched Phase 29 scope.
</deferred>
