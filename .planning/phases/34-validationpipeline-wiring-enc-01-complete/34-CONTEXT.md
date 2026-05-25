# Phase 34: ValidationPipeline Wiring + ENC-01 Complete - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the decrypt-then-reparse step into the response `ValidationPipeline`: detect an
`EncryptedAssertion`, reject the cleartext+encrypted ambiguity *before any crypto*, call the
Phase-33 `XMLEnc.decrypt/3`, re-parse the decrypted bytes through the *same* hardened saxy
seam (`PureBeam.parse_safely/2`), and run the existing signature/status/audience/time
validations on the decrypted-then-verified material. Publish the SP encryption
`KeyDescriptor` in the metadata endpoint. Land the 7-fixture ENC-01 adversarial corpus in
`mix ci.security`.

**In scope:**
- `lib/relyra/protocol/validation_pipeline.ex` — new `:decrypt_assertion` pre-stage in `do_run/4`
- `lib/relyra/protocol/metadata.ex` — emit `<KeyDescriptor use="encryption">` and `<KeyDescriptor use="signing">`
- `lib/relyra/error.ex` — new `:ambiguous_assertion` typed error
- `lib/relyra/test_support/fake_idp.ex` — new `encrypt`/`encrypted_response` helper
- New `test/security/` pipeline-level ENC-01 corpus (7 fixtures) + `mix.exs` `ci.security` wiring

**Out of scope:** `EncryptedAttribute` decryption (deferred — see D-06); the
`sign_authn_requests` toggle gating of the signing KeyDescriptor (Phase 35); redirect-binding
signing (Phase 35). The crypto primitive (`XMLEnc.decrypt/3`, `KeyResolver`) is Phase 33 and is
consumed here, not modified.

**Requirements closed:** ENC-01 (EncryptedAssertion path only), ENC-02 (SP encryption KeyDescriptor).
</domain>

<decisions>
## Implementation Decisions

### Pipeline Integration
- **D-01:** The `:decrypt_assertion` step is a new **first stage inside `ValidationPipeline.do_run/4`**
  (`validation_pipeline.ex:62-76`) — **not** inside `Signature.do_verify/4`. `do_run` is the only
  layer that owns the raw `response_payload` binary and calls `parse_safely/2`; `do_verify/4`
  receives an already-parsed map and cannot re-parse. Sequence:
  (a) `PureBeam.parse_safely/2` on the outer Response → parse tree;
  (b) detect `EncryptedAssertion` presence and the ambiguous (cleartext `<Assertion>` + `<EncryptedAssertion>`) case from the tree;
  (c) reject ambiguity with `:ambiguous_assertion` **before any crypto** (D-03);
  (d) on a single `EncryptedAssertion`: call `XMLEnc.decrypt/3`, splice plaintext into a recomposed Response binary, **re-run `parse_safely/2`** on it;
  (e) hand the re-parsed `parsed_doc` to the unchanged `do_run_validations/6` (signature → status → audience → time).
  *The investigation thread's "wire into `do_verify`" (`encrypted-assertions-investigation.md:37`) predates the Phase 28-29 refactor that moved parsing up into the pipeline — `do_verify` no longer sees raw bytes.*
- **D-02:** The **no-op path is byte-identical to today**: when the parse tree contains zero
  `EncryptedAssertion` elements, the original `parsed_doc` flows straight to `do_run_validations/6`
  with no re-parse and no `XMLEnc` call. The branch keys only on `find_first(parse_tree, "EncryptedAssertion")`
  being non-nil. This protects every existing signed-Response test and the frozen Phase-29
  adversarial corpus from regression (SC#3).

### Error Taxonomy
- **D-03:** `:ambiguous_assertion` is a **new distinct typed error** built via `Error.new(:ambiguous_assertion, ...)`
  (`error.ex:15-18` — the taxonomy is free-atom `%Error{}` structs, no central registry to register
  against). It is returned as `{:error, %Error{}}` and is explicitly **NOT** folded into the opaque
  `:decryption_failed` atom (which Phase 33 reserves for all crypto/policy failures to avoid an
  error oracle). Ambiguity is a structural *pre-crypto* rejection — typed code aids adopter
  diagnostics and carries no oracle risk. Mirrors the existing `:ambiguous_signed_node` precedent
  (`pure_beam.ex:551`). The guard runs **before** `XMLEnc.decrypt/3` is ever called (SC#2).

### SP Encryption Certificate + Metadata KeyDescriptor (ENC-02)
- **D-04:** Extend `Metadata.build_sp_metadata/2` (`metadata.ex:4-19`, currently emits **no**
  `KeyDescriptor` at all) to emit both `<KeyDescriptor use="encryption">` and `<KeyDescriptor use="signing">`.
  Source the SP **public** certificates from **net-new** config seams following the Phase-33
  `:_pem` convention: `Application.get_env(:relyra, :sp_encryption_cert_pem)` and
  `Application.get_env(:relyra, :sp_signing_cert_pem)`. The encryption descriptor reads the
  **public cert** — never the Phase-33 private key `:sp_private_key_pem`.
- **D-05:** Phase 34 emits the `use="signing"` KeyDescriptor **unconditionally** (SC#4: "present
  and distinct"). The `sign_authn_requests`-toggle conditionality (Phase 35 SC#4 / AUTHN-03:
  "omits both when toggle off") is layered on **in Phase 35**. Phase 34 owns the descriptor's
  *creation*; Phase 35 owns its *toggle gating*. This is the only ordering that satisfies both
  phases without rework, and Phase 35 "can run in parallel with Phases 33-34" so the descriptor
  must exist for Phase 35 to gate.

### EncryptedAttribute Scope
- **D-06:** Phase 34 implements **`EncryptedAssertion` decryption only**. `EncryptedAttribute` is
  **deferred** to a follow-up tracked against ENC-01's residual scope. All 5 Phase 34 success
  criteria and all 7 adversarial fixtures are assertion-level; `EncryptedAttribute` sits inside
  `<AttributeStatement>` and decrypts *after* signature verification (a second, post-verify splice
  path with a different ordering invariant) — mixing both doubles the integration surface.
  *Accepted tension:* REQUIREMENTS.md:12 and the investigation thread (line 51) recommend "both";
  deferring leaves ENC-01 partially open and may be flagged by a v1.3 milestone audit. Rework cost
  is low — same `XMLEnc.decrypt/3` primitive against the attribute subtree. **User confirmed defer.**

### Adversarial Corpus + FakeIdP
- **D-07:** The 7 ENC-01 fixtures (wrong-key, truncated tag, PKCS1v1.5, CBC, cleartext-injection,
  malformed ciphertext, read-before-verify attempt) live in a **new dedicated** `test/security/`
  file (e.g. `xml_enc_adversarial_test.exs`), added to `mix.exs` `ci.security` as its **own**
  `cmd mix test ... --warnings-as-errors` line (Phase-30 hollow-gate rule — do NOT collapse to a
  bare `test` step; see `mix.exs:159-167`). Distinct from the Phase-33 *unit* corpus
  (`xml_enc_test.exs`, which tests `XMLEnc.decrypt/3` directly). The **read-before-verify** fixture
  drives end-to-end through `ValidationPipeline` and asserts NO identity field is returned + a typed
  error — proving the decrypt-then-verify ordering, the strongest auth-bypass guard.
- **D-08:** `FakeIdP` gains a new `encrypt`/`encrypted_response` helper that wraps a signed
  Response/Assertion into an `<EncryptedAssertion>` using RSA-OAEP + AES-256-GCM against the SP
  public key. The recipe already exists inline at `xml_enc_test.exs:39-56` (`:public_key.encrypt_public`
  with `:rsa_pkcs1_oaep_padding` + `:crypto.crypto_one_time_aead(:aes_256_gcm, ...)`) and the
  `<EncryptedAssertion>` envelope template at `xml_enc_test.exs:28-33` — promote both into `FakeIdP`
  as the single canonical generator (mirroring how `FakeIdP.sign/2` is the canonical signer).

### Claude's Discretion
- Exact new corpus filename (`test/security/xml_enc_adversarial_test.exs` suggested).
- Whether to advertise `<md:EncryptionMethod>` (allowed content-encryption algorithms) inside the
  encryption `KeyDescriptor`, and the exact `<md:KeyDescriptor>` child ordering (signing before
  encryption) — resolve against XML-Enc / SAML metadata schema (see Canonical References).
- Whether the encrypted Response is recomposed by string-splice or tree-rebuild before the second
  `parse_safely/2` — planner picks the lowest-risk form that does not perturb the bytes
  `canonicalize/2` binds via `:node` (`pure_beam.ex:466`).
- Whether `ValidationPipeline` obtains the `key_resolver` module by calling `KeyResolver.resolve/2`
  dispatch or by passing the resolved module into `XMLEnc.decrypt/3` (note: `XMLEnc.decrypt/3` calls
  `key_resolver_module.resolve/1` directly via `apply`, `xml_enc.ex:107` — pass the MODULE, not the
  dispatch wrapper result).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/relyra/protocol/validation_pipeline.ex` — integration site; `do_run/4` (62-76) owns raw bytes + `parse_safely`; `do_run_validations/6` (78-111) is the unchanged downstream chain. The `:decrypt_assertion` pre-stage slots into `do_run`.
- `lib/relyra/security/xml_enc.ex` — `decrypt/3` (line 11) contract + tree-walk helpers (`find_first` 170-176). NOTE: it calls `key_resolver_module.resolve/1` directly via `apply` (line 107), not the `KeyResolver.resolve/2` dispatch wrapper.
- `lib/relyra/key_resolver.ex` — public `resolve/2` dispatch (14-19) reading `Keyword.get(opts, :key_resolver, Default)`; pipeline obtains the resolver module from `consume_opts`.
- `lib/relyra/security/xml/pure_beam.ex` — `parse_safely/2` (39) is the re-parse entry for decrypted bytes; `:parse_tree` (257) exposes the `SaxyTree.Node` root for `EncryptedAssertion` detection; `find_first` (584-590) / `find_all` (614-618) are local-name-based, prefix-agnostic; `:ambiguous_signed_node` (551) is the typed-error precedent; `canonicalize/2` binds `:node` (466).
- `lib/relyra/protocol/metadata.ex` — `build_sp_metadata/2` (4-19); currently emits NO KeyDescriptor — add both `use="signing"` and `use="encryption"` here (ENC-02).
- `lib/relyra/phoenix/controllers/metadata_controller.ex` — `show/2` (14) calls `build_sp_metadata`; `controller_opts/1` (49-51) shows how connection + app config flow to the builder.
- `lib/relyra.ex` — `do_consume_response/3` (151-170); `consume_opts` threaded into `ValidationPipeline.run` at line 161 is where `:key_resolver` and decryption opts flow from.
- `lib/relyra/error.ex` — `Error.new/3` (15-18); free-atom `%Error{}` taxonomy — `:ambiguous_assertion` is built here, not registered anywhere.
- `lib/relyra/security/algorithm_policy.ex` — `enforce_key_transport_algorithm/2` (133), `enforce_content_encryption_algorithm/3` (152); already called inside XMLEnc (gate is pre-wired).
- `test/security/xml_enc_test.exs` — Phase-33 UNIT corpus; lines 28-56 hold the reusable `<EncryptedAssertion>` template + OAEP/GCM encryption recipe to promote into `FakeIdP`.
- `test/security/xml/adversarial_crypto_test.exs` — structural model for the new pipeline-level ENC-01 corpus (FakeIdP-driven, exact `%Error{type:}` pins, end-to-end through the verify path). Never weaken (CLAUDE.md).
- `lib/relyra/test_support/fake_idp.ex` — `sign/2` (64-75), `keypair/0` (88-93); needs the new `encrypt`/`encrypted_response` helper.
- `mix.exs` (152-173) — `ci.security` alias; new ENC-01 corpus file added as its own `cmd mix test ... --warnings-as-errors` line (hollow-gate rule, comment at 159-167).
- `.planning/milestones/v1.3-ROADMAP.md` — Phase 34 + Phase 35 sections; the SC#4 signing-KeyDescriptor coupling (Phase 34 = unconditional create, Phase 35 = toggle gating).
- `.planning/REQUIREMENTS.md` (lines 12-13, 21) — ENC-01 (EncryptedAttribute mention), ENC-02, AUTHN-03 (Phase-35 signing-descriptor conditionality).
- `.planning/threads/encrypted-assertions-investigation.md` — decrypt-then-reparse pipeline rationale, adversarial corpus table (lines 21-31), and the EncryptedAttribute open question (line 51).

**Planner spec-confirmation tasks (read the spec, not the codebase):**
- XML-Enc `<EncryptedAssertion>` nesting within `<Response>` (sibling of `<Assertion>` under the Response root) — so the ambiguous-case detector walks the correct positions. (SAML 2.0 Assertions & Protocols §3.3; XML-Enc §5.)
- `<md:KeyDescriptor>` child ordering and `<md:EncryptionMethod>` requirements inside `SPSSODescriptor` (signing descriptor before encryption; whether to advertise allowed content-encryption methods).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ValidationPipeline.do_run/4` — the single owner of raw response bytes + `parse_safely`; the only correct host for a decrypt-then-reparse pre-stage.
- `PureBeam.find_first/find_all` (prefix-agnostic, local-name based) — directly usable for `EncryptedAssertion` detection and the cleartext+encrypted ambiguity check.
- `XMLEnc.decrypt/3` (Phase 33) — the crypto primitive; returns plaintext bytes or opaque `:decryption_failed`. Consumed unchanged.
- `xml_enc_test.exs:28-56` — proven `<EncryptedAssertion>` envelope + OAEP/AES-256-GCM recipe; promote to `FakeIdP`.
- `:ambiguous_signed_node` typed error (`pure_beam.ex:551`) — the precedent shape for `:ambiguous_assertion`.

### Established Patterns
- Free-atom `%Error{}` taxonomy via `Error.new/3` — no central enum; new error types are just new atoms.
- SP key material sourced from `Application.get_env(:relyra, :<thing>_pem)` (Phase-33 convention).
- `ci.security`: one `cmd mix test <file> --warnings-as-errors` subprocess per security suite (Phase-30 hollow-gate fix); never collapse to bare `test` steps.
- `FakeIdP` is the canonical fixture generator (real `sign/2` since Phase 30); the encrypt helper extends that single-source pattern.

### Integration Points
- `validation_pipeline.ex:66` (`parse_safely`) and `:81-82` (`do_run_validations`) — decryption + re-parse slot between them.
- `relyra.ex:161` — `consume_opts` (incl. `:key_resolver`) flows into `ValidationPipeline.run`.
- `metadata.ex:4-19` + `metadata_controller.ex:14,49-51` — where the new KeyDescriptors and SP-cert config seam attach.
- `algorithm_policy.ex` enforce functions are already invoked inside `XMLEnc.decrypt/3` — no new policy wiring in this phase.
</code_context>

<specifics>
## Specific Ideas

- New config seams: `:sp_encryption_cert_pem` (public cert for the encryption KeyDescriptor) and
  `:sp_signing_cert_pem` (public cert for the signing KeyDescriptor) — `:_pem` suffix convention,
  paired with the Phase-33 `:sp_private_key_pem`.
- New typed error atom: `:ambiguous_assertion` (returned `{:error, %Error{}}`, not opaque).
- The 7 ENC-01 fixtures map to: wrong-key → `:decryption_failed`; truncated GCM tag → `:decryption_failed`;
  PKCS1v1.5 → `:decryption_failed` (policy hard-reject inside XMLEnc); AES-CBC → `:decryption_failed`
  (policy reject); cleartext-injection (both present) → `:ambiguous_assertion`; malformed ciphertext
  → `:decryption_failed`; read-before-verify attempt → typed verification error, no identity field.
- FakeIdP encrypt recipe: `:public_key.encrypt_public(cek, sp_pub, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])`
  + `:crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, aad, true)` (mirror of the decrypt path).
</specifics>

<deferred>
## Deferred Ideas

- **`EncryptedAttribute` decryption** — recommended by REQUIREMENTS.md:12 and the investigation
  thread (line 51) but deferred from Phase 34 (D-06). Belongs in a follow-up reusing `XMLEnc.decrypt/3`
  against the `<AttributeStatement>` subtree, *after* signature verification. Track against ENC-01
  residual scope so a v1.3 milestone audit can account for it.
- **`sign_authn_requests` toggle gating of the signing KeyDescriptor** — Phase 35 (AUTHN-03); Phase 34
  only creates the descriptor unconditionally (D-05).
- **XMLEnc decryption telemetry** — deferred from Phase 33; still out of scope here to avoid leaking
  timing channels through measurement metadata without careful review.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
