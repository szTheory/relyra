---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: milestone
status: executing
last_updated: "2026-05-25T19:30:26.200Z"
last_activity: 2026-05-25 -- Phase 34 planning complete
progress:
  total_phases: 34
  completed_phases: 32
  total_plans: 105
  completed_plans: 98
  percent: 94
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-25)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 34 — validationpipeline-wiring-enc-01-complete

## Current Position

Phase: 34 (validationpipeline-wiring-enc-01-complete) — PLANNED
Plan: 4 plans in 2 waves (Wave 1: 34-01 metadata · 34-02 FakeIdP encrypt · 34-03 decrypt pipeline; Wave 2: 34-04 ENC-01 corpus)
Status: Ready to execute
Last activity: 2026-05-25 -- Phase 34 planning complete
Resume: /gsd:execute-phase 34

Progress: `███░░░░░░░` 33% (2/6 v1.3 phases — 32-33 complete)

## Performance Metrics

- Last shipped milestone: v1.1 (Phases 28-31)
- Plans complete in last shipped milestone: 15/15
- Coverage in last shipped milestone: 8/8 requirements mapped and completed

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 28 | 01 | 6m | 3 | 4 (2 created, 2 modified) |
| 28 | 02 | — | 2 | 1 modified (c14n.ex) + 2 test files |
| 28 | 03 | — | 2 | 1 modified (pure_beam.ex) + 1 test file |
| 28 | 04 | — | 2 | 3 created (golden fixtures + PROVENANCE) + 1 test |
| 29 | 01 | ~58m | 3 | 7 (2 created, 5 modified) |
| 29 | 02 | 2m | 2 | 4 (2 created, 2 modified) |
| Phase 29 P03 | 24m | 2 tasks | 5 files |
| Phase 29 P04 | ~32min | 3 tasks | 6 files |
| Phase 29 P05 | ~12min | 2 tasks | 4 files |

## Accumulated Context

### Roadmap Evolution

- v1.0 shipped 2026-05-08 (Phases 25-27). Highest shipped phase = 27.
- v1.1 starts at Phase 28 (continues numbering; does not reset).
- v1.1 is a focused, URGENT security milestone derived from the 2026-05-23 P0 audit.
- Phase sequence is dependency-ordered: foundation (28) → verification (29) → assurance (30) → disclosure (31). The verify math (SIGV-01/02) cannot land before correct canonicalization (SIGV-03), so Phase 28 must complete first.
- v1.3 starts at Phase 32 (continues numbering after v1.1's Phase 31).
- v1.3 dependency graph: Phase 32 (shared prerequisite) → Phase 33 (crypto core) → Phase 34 (pipeline wiring + ENC-01 complete). Phase 35 (AUTHN-01) depends only on Phase 32 and can run in parallel with Phases 33-34. Phases 36-37 (docs) have no code dependencies and are fully parallel.

### Decisions / Constraints carried into v1.3

- **Decrypt-then-reparse invariant is non-negotiable:** decrypted assertion bytes MUST pass through `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before any identity field is read. CVE-2025-54419 (node-saml, CVSS 10.0) was exactly this shortcut. No workarounds.
- **AlgorithmPolicy gates all new crypto:** RSA-PKCS1v1.5 is permanently blocked with no escape hatch. AES-CBC is blocked by default with the same time-boxed escape-hatch pattern as SHA-1. AES-GCM auth tag must be validated as exactly 16 bytes BEFORE calling `:crypto.crypto_one_time_aead/7`.
- **Single opaque error atom:** all decryption failure modes return `:decryption_failed` — distinct atoms would open a padding oracle. This is a hard contract, not a preference.
- **SP private keys never in DB:** `KeyResolver.Default` reads from app config only; diagnostic bundle allow-list excludes all key material. No exceptions for "convenience" columns.
- **Redirect-binding signature signs raw query bytes verbatim:** the `sign_redirect_query/3` function receives a pre-assembled binary; no re-serialization inside the function. Corpus golden tests enforce this.
- **Zero new Hex dependencies:** all v1.3 crypto is OTP stdlib (`:public_key`, `:crypto`, `:zlib`). Any NIF-based XML-Enc library would bypass the hardened saxy seam — permanently out of scope.
- **RSA-OAEP SHA-256 (`xmlenc11#rsa-oaep`) blocked at AlgorithmPolicy:** `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 26-28. AlgorithmPolicy maps this URI to `:blocked_pending_otp_support` with a clear error, not silent failure.
- **Ambiguity guard for simultaneous cleartext+encrypted assertion:** `PureBeam.build_parsed_doc/1` must detect and reject `:ambiguous_assertion` before any crypto. CVE-2026-2092 (Keycloak) was injection of a cleartext assertion alongside an encrypted one.

### Decisions / Constraints carried from v1.1

- **ADR-0001 governs:** pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam. The hybrid+xmlsec NIF (GATE-03 matrix) is a conditional rollback only — NOT a planned path.
- **Brownfield, extend not rebuild:** work lands in existing modules (signature.ex, pure_beam.ex, algorithm_policy.ex, validation_pipeline.ex, protocol/metadata.ex, ecto/connection.ex, ecto/certificate.ex). Reuse the existing hardened parser boundary, single-signed-node selection, duplicate-ID + document-KeyInfo rejection.
- **`mix ci.security` hollow-gate fix (Phase 30) is permanent:** each security suite runs as its own `cmd mix test` process. Never revert to bare `test` steps. The `ci_gate_integrity_test.exs` meta-gate prevents regression.

### Decisions made in Phase 28 Plan 01

- **Tree-node shape (CONTRACT for Plans 02/03):** the parse tree is built from `%Relyra.Security.XML.SaxyTree.Node{}` structs — `qname` (verbatim), `prefix`, `local`, `attrs` (document order, attr-value normalized; xmlns decls retained verbatim AND surfaced in `:ns`), `ns` (in-scope map; `""` key = default namespace), `children` (document order), `text` (line-ending normalized, not whitespace-collapsed). Documented verbatim in `28-01-SUMMARY.md`. A struct (not a bare map) was chosen for a stable, introspectable contract.
- **saxy 1.6.0 added non-optional** (T-28-SC supply-chain checkpoint pre-approved). The three Relyra-owned infoset-normalization layers are applied at tree-build time (in-scope ns stack; attr-value `#x9`/`#xA`/`#xD`->single space per XML 1.0 §3.3.3; line-ending `\r\n`/`\r`->`\n` per §2.11), kept strictly separate from C14N escaping (serialize-time, Plan 02). CRLF inside an attribute value collapses to a single space.
- **Historical note:** at this Plan 01 checkpoint, `SIGV-03` was still incomplete because Plan 01 delivered only the saxy parse-tree substrate; the exclusive-C14N engine (Plan 02) and seam re-wiring (Plan 03) were still required before `SIGV-03` could be satisfied.

### Decisions made in Phase 28 Plan 02

- **Exclusive-C14N engine API (CONTRACT for Plan 03):** `Relyra.Security.XML.C14N.serialize/2` (node → canonical bytes; `:prefix_list` option) and `canonicalize_reference/4` (referenced node, ordered transform URIs, the specific `ds:Signature` to prune or `nil`, opts). Helpers `transform_uris/1` + `prefix_list_from_transforms/1` read a `ds:Transforms` node. Plan 03 wires `canonicalize/2` to these. Full API in `28-02-SUMMARY.md`.
- **Transform allowlist is STRICT** to `{enveloped-signature, exc-c14n}` (T-28-05). Inclusive C14N is deliberately NOT allowlisted — this engine computes exclusive C14N only, so accepting an inclusive URI would emit wrong bytes (silent verification bypass).
- **Enveloped-signature pruning is anti-XSW (D-10):** the SPECIFIC `ds:Signature` subtree (value-equal match) is pruned, leaving an unrelated sibling Signature intact.
- **Self-checked, not yet proven:** correctness is asserted here via idempotence + per-pitfall structural tests (30/30 green). The byte-for-byte proof vs the independent lxml+xmlsec1 oracle (GATE-02) lands in Plan 04 — SIGV-03 is not satisfied until then.

### Decisions made in Phase 28 Plan 03

- **One trust path (D-04):** `PureBeam.parse_safely/2` now runs entirely on the `SaxyTree`; ALL protocol fields are re-derived from the tree in one pass and every regex extractor is retired. Pre-parse DOCTYPE/ENTITY/size byte guards kept verbatim and run BEFORE Saxy on the raw binary (D-09, XXE-before-verify). `parser_path_guard` green (no `Saxy` ref escapes the seam).
- **Additive contract (D-08):** flat `parsed_doc` keys unchanged; tree attached as `:parse_tree`. Handle gains `:node` / `:signature_node` / `:transforms_node` (D-10) bound to the EXACT tree node `canonicalize/2` serializes (anti-XSW).
- **canonicalize/2 delegates to `C14N.canonicalize_reference/4`** (not bare `serialize/2`), reading transforms + PrefixList from the bound `ds:Signature`. Current corpus fixtures carry no `ds:Transforms` (Reference holds only `DigestMethod`) → `transforms_node` nil → plain exclusive-C14N; real enveloped chains exercised once FakeIdP/real-IdP fixtures carry `ds:Transforms` (Phase 30).
- **Trust-path hardening:** an enveloped-signature transform with an unresolved bound `ds:Signature` fails closed (`:enveloped_signature_unresolved`) rather than serialize-without-pruning — no fail-open leaving signature material in canonical bytes. 99/99 trust-path regression green (seam + v1.0 corpus + signature + auto_refresh).

### Decisions made in Phase 28 Plan 04

- **SIGV-03 correctness PROVEN (D-11/D-12):** golden-byte oracle minted out-of-band in Docker (no host install) and committed. `Relyra.Security.XML.C14N` (via the seam) reproduces libxml2's 887-byte exclusive-C14N output **byte-for-byte** — verified by `corpus_security_test.exs` `@tag :gate02_c14n`. Cross-checked across two libxml2 builds (lxml-bundled 2.14.6 vs system 2.9.14); the Elixir engine is the independent third agreeing implementation. Fixtures: `test/fixtures/security/xml/parser_differential_and_c14n/assertion_inherited_ns.{input.xml,c14n}` + PROVENANCE.md.
- **GATE-02 now has a positive byte-equality assertion + a node-binding assertion (D-10)**, with the existing fail-closed c14n-00x rows preserved. CI stays pure-Elixir (committed bytes only, D-12).
- **Known limitation (follow-up, fail-safe):** `SaxyTree.Node` has one `:text` field per element and C14N emits it before children → mixed-content / inter-element whitespace mis-orders vs libxml2. Impact is rejection (digest mismatch in Phase 29), never bypass. Follow-up: ordered text+element children + a mixed-content golden (Phase 29/30 scope).

### Post-phase-28 cleanup (2026-05-23) — RESOLVED

- **Dependency CVEs fixed:** postgrex 0.22.0→0.22.2 (channel-name SQL injection, high), plug 1.19.1→1.19.2 (multipart DoS, high), phoenix 1.8.5→1.8.7 (long-poll memory DoS, high). decimal 3.0 (the only patched version for GHSA-rhv4-8758-jx7v) is **unreachable** — ecto + postgrex pin `decimal ~> 2.0` — and relyra makes no direct `Decimal.new/parse` calls (no exposure), so that one advisory is ignored in the `ci.security` deps.audit step via `--ignore-advisory-ids` with a justification comment (revisit when ecto/postgrex allow decimal `~> 3.0`). **`mix deps.audit` and `mix ci.security` are now GREEN.**
- **28-03 regression fixed:** protocol fixture `prot-unsigned-001` expectation corrected `malformed_xml`→`missing_protocol_field` (well-formed-but-non-SAML `<Fake>` is parsed by the saxy tree, then fails closed on missing fields — both reject; new type is accurate). Escaped 28-03 verification, which ran `test/relyra/protocol/` not `test/protocol/`. **Full `mix test` = 486/0.**
- **jtbd docs committed** (clean tree); **disclosure-embargo memory relaxed** (solo dev, no adopters → fix openly/aggressively).

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table.

## Deferred Items

Items acknowledged and deferred at milestone close:

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 15: 15-VERIFICATION.md | human_needed |

## Tracked Follow-ups (carried into v1.3)

- **Mixed-content / inter-element-whitespace C14N gap — RESOLVED in 29-01 (2026-05-24).** Option-a landed exactly as recommended: ordered `content` field on `SaxyTree.Node`, `C14N` walks it in document order, `:text`/`:children` kept as byte-identical derived views. Docker-minted 1056-byte mixed-content golden (`mixed_content.c14n`) proves byte-equality to libxml2; 887-byte golden still green. See `29-01-SUMMARY.md`.
- **PrefixList golden cross-check (future, not blocking).** A future `InclusiveNamespaces/@PrefixList` golden should additionally cross-check against a non-libxml2 implementation (e.g. Apache Santuario) to fully neutralize the lxml-lineage caveat noted in `parser_differential_and_c14n/PROVENANCE.md`. Current goldens use no PrefixList, so the caveat is not yet load-bearing.
- **Phase 29 warning-level review items (WR-02..WR-05, IN-01..IN-03):** Non-blocking. Tracked in `.planning/todos/completed/29-code-review-followups.md`.
- **CVE ID backfill into `docs/advisories/2026-001-...`:** Pending async GitHub assignment.

## Session Continuity

**2026-05-25 — v1.3 roadmap created.** 6 phases defined (32-37), 10/10 requirements mapped. Ready for `/gsd:plan-phase 32`.

Phase 32 is the mandatory first phase — AlgorithmPolicy extension and DB schema migrations are the shared prerequisite for all ENC-01 and AUTHN-01 work. Phase 35 (AUTHN-01) can begin immediately after Phase 32 completes, in parallel with Phases 33-34. Phases 36-37 can proceed at any time.

## Decisions

- [Assessment 2026-05-25]: Done-% estimated at 85% (band: "strong, meaningful wedges remain"). Next milestone recommended: v1.3 "Advanced Federation" — encrypted assertions (B1) + signed AuthnRequests (B3) + generic SAML runbook (D1) + identity mapping guide (D2). Full SLO (B2) deferred to v1.4 (complex; not an adoption blocker at the same tier). Investigations retained in `.planning/threads/`.
- [Assessment 2026-05-25]: Diminishing-returns line drawn at HTTP-Artifact, ECP, Attribute Query, SCIM-in-core, more presets-without-generic-path, full demo app. After B1+B2+B3+C the lib is "done enough"; further work is demand-gated, not coverage-gated.
- [Phase 29-02]: ECDSA fail-closed lives in `AlgorithmPolicy.digest_atom_for_signature_method/1` (typed `:unsupported_signature_algorithm` reject, checked BEFORE the rsa-sha* match), NOT by removing ECDSA from `default/0`'s allowlist — the allowlist still permits ECDSA URIs; the reject is the contract (fail-CLOSED, not allowlist-removal; D-07, Pitfall 5, T-29-04).
- [Phase 29-02]: D-02 crypto inputs (`signed_info_node` / `digest_value_b64` / `signature_value_b64`) surfaced additively in `pure_beam.ex` `signed_candidates/1` and carried onto the `select_candidate/1` handle; absent base64 values are nil-safe (DATA only here — decoded + verified in Plan 03, never logged raw per T-29-06).
- [Phase 29-01]: D-09 mixed-content C14N fix uses Option-a — ordered `content: [{:text,_} | {:element,_}]` on `SaxyTree.Node` is the single source of truth for document order; `:text`/`:children` are byte-identical derived projections (pure_beam field-derivation untouched). `C14N.render_element/3` walks `content`, so text and child elements canonicalize in source order. PROVEN byte-for-byte vs libxml2 by a new Docker-minted 1056-byte mixed-content golden (`mixed_content.c14n`); the 887-byte golden stays byte-identical. SIGV-02 byte-exactness leg satisfied.
- [Phase 29-01]: anti-XSW `prune_subtree/1` MUST prune on `content` (not children-only) — once the serializer walks `content`, a children-only prune is fail-OPEN (leaves `ds:Signature` material in canonical bytes, re-opening D-10/T-29-03). Rewritten to drop `{:element, ^target}` from content, recurse survivors, pass text through, keep `:children` a consistent derived view. Rule-1 auto-fix, committed in Task 2 (8052658).
- [Phase 29-03]: Real :public_key.verify of canonicalized SignedInfo + constant-time DigestValue recompute wired into the verified_signed_node [candidate] arm (D-01 bypass site closed); cert_chain threaded do_verify/4 -> verify_algorithms_and_candidates/4 -> verified_signed_node/5; all pre-existing trust gates still run BEFORE crypto.
- [Phase 29-03]: public_key_from_cert_chain/1 is @doc-false PUBLIC (reusable fail-closed PEM->RSA pubkey via pkix_decode_cert(:otp) -> element(8) SPKI); every malformed PEM/DER -> :untrusted_certificate, never raises (Pitfall 3). Plan 04 reuses it.
- [Phase 29-03]: Closing the bypass correctly fails-closed 10 existing end-to-end structure-only-signature {:ok} tests (consume_response x7, conformance, acs, telemetry) — deferred to Plan 04 (owns D-11 reusable signer); logged in deferred-items.md. Plan 03 own lanes 100% green (signature_crypto 14/0, security regression 161/0, C14N golden 102/0).
- [Phase 29-04]: D-11 genuine signer (Relyra.TestSupport.XmldsigSigner) reuses FakeIdP.keypair() + the verifier's own C14N engine and self-parses its emitted XML to bind the exact Assertion/SignedInfo nodes (D-12). Positive control proven: genuine Response -> {:ok, %SignedNode{}}; wrong-key -> :invalid_signature; tampered-NameID -> :digest_mismatch. Added sign_response/1 to re-sign existing Responses in place; all 10 structure-only {:ok} tests triaged by re-pointing at the genuine signer. Full mix test --warnings-as-errors = 524/0 (phase gate met).
- [Phase 29-05]: SIGV-04 plumbing gap (D-13) closed — metadata-root pre_parse_for_signature/1 routes through PureBeam.parse_metadata_root_safely/2 (SAME SaxyTree builder as the assertion path); tree-bound crypto inputs surfaced, 5 regex helpers retired (one trust path); genuinely-signed EntityDescriptor verifies {:ok} via the SAME do_verify primitive.
- [Phase 29-05]: metadata key_info_trust scoped to the bound ds:Signature's OWN KeyInfo (Rule 1 fix), NOT any-KeyInfo-anywhere — a KeyDescriptor/KeyInfo published signing cert is gated by TrustAnchor pinning, not a document-trust bypass; the literal any-KeyInfo flag would reject all real signed metadata once genuine crypto was wired. Threat T-29-22 (signature self-asserted KeyInfo) still rejected.
- [Phase 29-05]: metadata-root Reference carries the enveloped-signature transform (ds:Signature is a CHILD of the envelope); digest over the pruned envelope. Wrong-fingerprint negative rejects at pinning BEFORE the math (defense-in-depth); tampered-entityID rejects at digest recompute (real crypto, not pinning-alone). SIGV-04 COMPLETE; full suite 540/0.
