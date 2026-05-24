# Phase 30: Adversarial crypto assurance - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the proof that XMLDSig verification is real **permanent and gating**. Two arms:

1. **ASSUR-02 — `FakeIdP` real cryptographic signing.** `Relyra.TestSupport.FakeIdP` emits a genuine `DigestValue` + `SignatureValue` (RSA-SHA256) with its generated keypair, so the suite exercises real verification rather than structure-only acceptance.
2. **ASSUR-01 — permanent adversarial corpus.** A FakeIdP-driven suite proves rejection of all five attack categories — forged-signature-with-valid-structure, tampered-content (same signature), wrong-key, digest-mismatch, and canonicalization-differential — each asserting `{:error, %Relyra.Error{}}`, plus a positive control proving a genuinely FakeIdP-signed response verifies `{:ok}`. Wired into `corpus_gate` + the conformance manifest, green under `mix ci.security` (no skipped/pending crypto assertions).

**The throughline:** Phase 29 already proved every recipe works in `test/relyra/security/xml/signature_crypto_test.exs`. Phase 30 makes that proof permanent, FakeIdP-driven, complete across all five categories, and inside the security gate — it does NOT re-derive crypto.

**NOT in scope:** any production crypto-correctness change. The Phase 29 follow-up warnings (WR-02..WR-05 in `.planning/todos/pending/29-code-review-followups.md`) stay deferred. **NOT in scope (Phase 31 — DISC-01/02):** security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory. ECDSA real support remains the deferred fast-follow (fail-closed today).
</domain>

<decisions>
## Implementation Decisions

### FakeIdP real-signing — promote, don't rewrite
- **D-01:** `FakeIdP.sign/2` routes its emitted XML through the EXISTING `Relyra.TestSupport.XmldsigSigner.sign_response/1` (which injects a genuine `DigestValue` + `SignatureValue` into FakeIdP's structure-only shape in place), then base64-encodes the result. Do NOT re-implement crypto inside `FakeIdP` — that would create a divergent canonicalizer and let the positive control pass for the wrong reason (the exact T-29-15 false-positive Phase 29 engineered against). The signer already reuses `FakeIdP.keypair()` and binds the verifier's OWN C14N nodes (`xmldsig_signer.ex:29-32, 104-127, 208`; reaffirmed `29-04-SUMMARY.md`). This is the central Phase-30 integration decision (Phase 29 D-12).
- **D-02:** Reconcile the FakeIdP XML shape so the signed bytes match what the verifier recomputes: FakeIdP's current `response_xml` omits `<CanonicalizationMethod>` inside `<SignedInfo>` and collapses whitespace via `String.replace(~r/\s+/, " ")` (`fake_idp.ex:128-134`), whereas the signer's shape carries `<CanonicalizationMethod>` and is whitespace-free (`xmldsig_signer.ex:252-254`). Align FakeIdP's emitted shape (add the method element, drop the whitespace collapse) or the positive control fails digest/signature recompute.
- **D-03:** `FakeIdP` exposes its trust certificate (delegate `self_signed_cert_pem/0` or equivalent) so callers can configure the `cert_chain` to verify what FakeIdP signed.

### Adversarial corpus architecture — new crypto-verify suite, FakeIdP-driven
- **D-04:** The four crypto categories (forged-sig / tampered-content / wrong-key / digest-mismatch) live in a NEW test module, NOT in `priv/security_corpus.json`. The existing JSON corpus only evaluates down to parse / select-signed-node / canonicalize (`corpus_security_test.exs:161-194` `evaluate_fixture/1`), never `Signature.verify/4`; and the trust cert is a runtime `:persistent_term` from `FakeIdP.keypair()` (`fake_idp.ex:85-95`), not serializable into a static fixture. Each case mints its input FROM the genuine FakeIdP/signer output and drives the full `PureBeam.parse_safely → Signature.verify/4` path — the pattern already proven in `signature_crypto_test.exs:202-255`.
- **D-05:** Construction recipes (all demonstrated in `signature_crypto_test.exs`, to be made permanent + FakeIdP-driven):
  - **wrong-key** = sign with FakeIdP, verify against a throwaway cert (`throwaway_cert_pem/0`, `signature_crypto_test.exs:215-224`) → `:invalid_signature`.
  - **tampered-content / digest-mismatch** = `XmldsigSigner.signed_response(tamper_name_id: ...)` post-signing mutation (`xmldsig_signer.ex:317-328`) → `:digest_mismatch`.
  - **forged-sig-valid-structure** = genuine doc with `signature_value_b64` replaced by same-length random base64 (`signature_crypto_test.exs:81-90`) → `:invalid_signature`.
  - **positive control** = `XmldsigSigner.signed_response()` / FakeIdP-signed response verifies `{:ok, %SignedNode{}}` (`signature_crypto_test.exs:203-213`).

### c14n-differential REJECTION fixture
- **D-06:** Build the canonicalization-differential case as a post-signing canonically-significant tamper into the signed `<Assertion>` subtree (same mechanism as `maybe_tamper_name_id`, `xmldsig_signer.ex:317-328`), so `verify_reference_digest` (`signature.ex:346-374`) recomputes a different digest → `{:error, :digest_mismatch}`. The mutation MUST be one exclusive-C14N PRESERVES (added attribute, added element, or a visibly-utilized namespace declaration) — NOT one C14N normalizes away (e.g. attribute reordering, which C14N sorts), or the digest is unchanged and the fixture falsely passes `{:ok}`. Consult the in-repo pitfall catalog (`test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md`) when choosing the mutation.
- **D-07:** NO new out-of-band Docker golden is required for the c14n-differential case. A REJECTION fixture asserts only `{:error, %Relyra.Error{}}` — it claims no specific canonical byte string — so the Phase 28 D-12 out-of-band-mint discipline (which applies only to POSITIVE byte-equality goldens like `assertion_inherited_ns.c14n` / `mixed_content.c14n`) does not bite. CI stays pure-Elixir.

### CI + conformance wiring
- **D-08:** Add the new adversarial crypto-verify suite to the `ci.security` alias (`mix.exs:152-169`) with a tag (reuse `:security_corpus` or add a new `:adversarial_crypto` tag — executor's choice), run with `--warnings-as-errors`. Today `ci.security` runs the parse-layer corpus + `gate02_c14n` golden but does NOT run `signature_crypto_test.exs`, so the existing crypto proofs are currently OUTSIDE the gate — a suite not named in the alias does not gate (success #4 unmet otherwise).
- **D-09:** The c14n-differential REJECTION fixture is added to `priv/security_corpus.json` with full `provenance` / `requirement_ids` / `family` / `source_ref` (enforced by `corpus_security_test.exs:126-141`), AND `CONFORMANCE.md` is regenerated via `mix relyra.conformance`. `ci.security` runs `relyra.conformance --check` first (via `ci.conformance`, `mix.exs:148-153`) and fails on manifest/doc drift — so the doc regeneration is mandatory, not optional.

### Scope guard
- **D-10:** Phase 29 follow-up warnings WR-02..WR-05 stay OUT of scope (deferred per `29-code-review-followups.md`; none re-open the closed bypass). WR-03 (Reference/@URI not bound to the consumed node) is the one the adversarial corpus naturally brushes against; if a planned input exposes it, NOTE it as a follow-up — do not fix it in-phase (that is a production crypto-correctness change deserving its own plan + review).

### Claude's Discretion
- Exact module name/location for the new adversarial suite, and whether to reuse the `:security_corpus` tag or introduce a dedicated `:adversarial_crypto` tag (D-08).
- The specific canonically-significant mutation chosen for the c14n-differential fixture, selected from the PROVENANCE pitfall catalog (D-06).
- Whether to drive the four crypto categories through `FakeIdP.sign` end-to-end or through `XmldsigSigner` directly where FakeIdP delegates to it (must exercise the SAME signing path either way, per D-01).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — ASSUR-01 / ASSUR-02 acceptance language; the five required adversarial categories.
- `.planning/ROADMAP.md` — Phase 30 success criteria (4 must-be-TRUE items) + Phase 31 boundary.
- `.planning/phases/29-cryptographic-xmldsig-verification/29-CONTEXT.md` — D-11/D-12 (the local signer was built to be PROMOTED into FakeIdP), crypto error taxonomy, RSA-only/ECDSA-fail-closed scope.
- `.planning/phases/29-cryptographic-xmldsig-verification/29-04-SUMMARY.md` — the genuine signer (`XmldsigSigner`), `sign_response/1`, the 10 structure-only tests re-pointed, the explicit "promote into FakeIdP" guidance.
- `.planning/phases/29-cryptographic-xmldsig-verification/29-05-SUMMARY.md` — metadata-root signing path (SAME `do_verify` primitive), in case a signed-metadata adversarial case is added.
- `.planning/todos/pending/29-code-review-followups.md` — WR-02..WR-05 deferred warnings (OUT of scope; D-10).
- `lib/relyra/test_support/xmldsig_signer.ex` — the genuine signer to promote: `sign_response/1`, `signed_response/1` (incl. `tamper_name_id:`), keypair reuse, self-parse node binding.
- `lib/relyra/test_support/fake_idp.ex` — FakeIdP `response_xml`/`sign` (current structure-only shape: missing `<CanonicalizationMethod>`, whitespace-collapse at ~`:126-134`; keypair `:85-95`).
- `lib/relyra/security/signature.ex` — `do_verify` / `verified_signed_node` / `verify_reference_digest` (`:346-374`); the verify path the corpus exercises.
- `test/relyra/security/xml/signature_crypto_test.exs` — all five adversarial recipes + positive control already passing (`:202-255`, forged at `:81-90`, wrong-key `throwaway_cert_pem/0` `:215-224`); the source of the permanent corpus.
- `test/security/xml/corpus_security_test.exs` — GATE structure, fixture provenance enforcement (`:126-141`), parse-layer `evaluate_fixture/1` (`:161-194`).
- `lib/relyra/security/xml/corpus_gate.ex` + `test/relyra/security/xml/corpus_gate_test.exs` — runtime corpus gate machinery.
- `priv/security_corpus.json` — corpus source-of-truth (existing `c14n-differential-001` parse-layer row `:62-76`; xsw rows `:32-61`); add the new c14n-differential REJECTION row here.
- `test/fixtures/security/xml/manifest.json` — fixture manifest schema.
- `test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md` — C14N pitfall catalog (which mutations C14N preserves vs normalizes — informs D-06).
- `lib/relyra/conformance_fixtures.ex` + `lib/mix/tasks/relyra.conformance.ex` (`:51-101, 156-165`) + `CONFORMANCE.md` — conformance manifest generation + `--check` drift gate.
- `mix.exs` — `ci.security` / `ci.conformance` alias definitions (`:148-169`); where the new suite must be named.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`XmldsigSigner` (Phase 29):** genuine RSA-SHA256 signer that reuses `FakeIdP.keypair()` and the verifier's own C14N engine, self-parses to bind exact nodes; `sign_response/1` injects digest+signature into an existing shape; `signed_response/1` supports `tamper_name_id:`. Every adversarial recipe is built from this — no second signer.
- **`signature_crypto_test.exs`:** all five recipes + positive control already exist and pass through the real verify path; Phase 30 promotes/consolidates them into the permanent gated suite.
- **`throwaway_cert_pem/0`** (in `signature_crypto_test.exs`): the wrong-key trust source.
- **Corpus/conformance machinery:** `corpus_gate.ex`, `corpus_security_test.exs` GATE structure, `relyra.conformance` generator + `--check` — extend, don't rebuild.
- **`FakeIdP.keypair()`** (`fake_idp.ex:85-95`): single `:persistent_term` keypair — do not generate a second.

### Established Patterns
- **One signing path / no canonicalizer differential:** signer and verifier MUST canonicalize via the SAME C14N code (D-01). Promotion preserves this; a parallel signer breaks it.
- **Typed `%Relyra.Error{}` rejections:** `:invalid_signature`, `:digest_mismatch`, `:untrusted_certificate`, `:unsupported_signature_algorithm`, `:canonicalization_failed` — each names the failed check.
- **`mix ci.security` is pure-Elixir:** tests + `deps.audit`/`hex.audit`/`sobelow`, no native toolchain. New c14n-differential REJECTION fixture needs no Docker golden (D-07).
- **Fixture-as-source-of-truth with provenance:** JSON rows carry `provenance`/`requirement_ids`/`family`/`source_ref`; `CONFORMANCE.md` is generated + drift-checked.

### Integration Points
- `FakeIdP.sign/2` → `XmldsigSigner.sign_response/1` (the promotion seam, D-01).
- New adversarial suite → `PureBeam.parse_safely → Signature.verify/4` (full crypto path) → named in `ci.security` alias (D-08).
- New JSON row → `relyra.conformance` regeneration → `CONFORMANCE.md` → `ci.conformance --check` (D-09).
</code_context>

<specifics>
## Specific Ideas

- The c14n-differential mutation should be a C14N-PRESERVED change (added attribute / added element / visibly-utilized namespace decl), verified against the PROVENANCE pitfall catalog — NOT attribute reordering (C14N sorts attributes, so reordering is a no-op the digest would not detect).
- Prefer driving adversarial cases through `FakeIdP.sign` end-to-end where practical so the suite literally exercises the ASSUR-02 real-signing path, not just `XmldsigSigner` in isolation.
- The positive control should assert `{:ok, %SignedNode{}}` from a FakeIdP-signed response with FakeIdP's own cert as the configured trust source.
</specifics>

<deferred>
## Deferred Ideas

- **Phase 29 follow-ups WR-02..WR-05** (SignedInfo prefix-list scoping, Reference/@URI binding, enveloped metadata pruning, byte-guard ordering) — deferred to a follow-up phase; D-10.
- **Full XMLDSig ECDSA support** (`r‖s`→DER converter) — fast-follow after v1.1; ECDSA fail-closed today.
- **Security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory** — Phase 31 (DISC-01/02).
- **Signed-metadata adversarial cases** beyond the assertion/response path — optional extension via the same `do_verify` primitive (`verify_metadata_root/4`); add only if it strengthens the gate without scope creep.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 30 scope (the only pending todo, `29-code-review-followups.md`, is explicitly deferred per D-10).
</deferred>
