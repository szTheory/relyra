---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: — Publish, Prove, Polish
status: executing
last_updated: "2026-05-27T19:27:02.160Z"
last_activity: 2026-05-27
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 5
  completed_plans: 2
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 41 — Pre-publish hygiene tech-debt sweep security hardening

## Current Position

Phase: 41 (Pre-publish hygiene tech-debt sweep security hardening) — EXECUTING
Plan: 3 of 5
Status: Ready to execute
Last activity: 2026-05-27

## Performance Metrics

- Last shipped milestone: v1.4 (Phases 38-40.1)
- Plans complete in last shipped milestone: 12/12
- Coverage in last shipped milestone: 4/4 requirements mapped and completed
- Prior shipped milestone: v1.3 (Phases 32-37) — 21/21 plans, 10/10 requirements

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 39 | 01 | 10m | 2 | 2 |
| 28 | 01 | 6m | 3 | 4 (2 created, 2 modified) |
| 28 | 02 | — | 2 | 1 modified (c14n.ex) + 2 test files |
| 28 | 03 | — | 2 | 1 modified (pure_beam.ex) + 1 test file |
| 28 | 04 | — | 2 | 3 created (golden fixtures + PROVENANCE) + 1 test |
| 29 | 01 | ~58m | 3 | 7 (2 created, 5 modified) |
| 29 | 02 | 2m | 2 | 4 (2 created, 2 modified) |
| Phase 29 P03 | 24m | 2 tasks | 5 files |
| Phase 29 P04 | ~32min | 3 tasks | 6 files |
| Phase 29 P05 | ~12min | 2 tasks | 4 files |
| Phase 34 P01 | 2m | 2 tasks | 2 files |
| Phase 34 P02 | 3m | 2 tasks | 2 files |
| Phase 34 P03 | 9m | 2 tasks | 3 files (1 created, 2 modified) |
| Phase 34 P04 | 7min | 2 tasks | 4 files |
| Phase 37 P01 | 4m | 2 tasks | 2 files (1 created, 1 modified) |
| Phase 37 P02 | 9min | 2 tasks | 5 files |

## Accumulated Context

### Roadmap Evolution

- v1.0 shipped 2026-05-08 (Phases 25-27). Highest shipped phase = 27.
- v1.1 starts at Phase 28 (continues numbering; does not reset).
- v1.1 is a focused, URGENT security milestone derived from the 2026-05-23 P0 audit.
- Phase sequence is dependency-ordered: foundation (28) → verification (29) → assurance (30) → disclosure (31). The verify math (SIGV-01/02) cannot land before correct canonicalization (SIGV-03), so Phase 28 must complete first.
- v1.3 starts at Phase 32 (continues numbering after v1.1's Phase 31).
- v1.3 dependency graph: Phase 32 (shared prerequisite) → Phase 33 (crypto core) → Phase 34 (pipeline wiring + ENC-01 complete). Phase 35 (AUTHN-01) depends only on Phase 32 and can run in parallel with Phases 33-34. Phases 36-37 (docs) have no code dependencies and are fully parallel.
- **Phase 40.1 inserted after Phase 40 on 2026-05-27 (URGENT — v1.4 audit closure):** Close four findings from `.planning/v1.4-MILESTONE-AUDIT.md` (status: `gaps_found`) — logout.md SessionAdapter signature drift (BLOCKER 1, affects DOCS-04 + SLO-01), `SessionAdapter.index_session/4` policy resolution (WARNING 2, affects SLO-01), missing 38/39 VERIFICATIONs, and 38-04 SUMMARY `consume_logout_response/3` → `consume_logout/3` name drift. Required before `/gsd:complete-milestone v1.4`.
- **v1.5 starts at Phase 41** (continues numbering after v1.4's Phase 40.1). Six phases (41-46), 15 requirements, polish-and-publish only — no new protocol features. Linear dependency graph (post-reorder 2026-05-27): 41 (tech-debt sweep, MUST land first) → 42 (trace LiveView, sequenced before publish prep so it ships in v1.4.0 by construction) → 43 (version bump + CHANGELOG) → 44 (release-please diagnosis + Hex publish) → 45 (post-publish parity). 46 (DX) depends on 41 (TD-04 doc-drift fix) and can run any time after 41 in parallel with 42-45.

### Decisions / Constraints carried into v1.3

- **Decrypt-then-reparse invariant is non-negotiable:** decrypted assertion bytes MUST pass through `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before any identity field is read. CVE-2025-54419 (node-saml, CVSS 10.0) was exactly this shortcut. No workarounds.
- **AlgorithmPolicy gates all new crypto:** RSA-PKCS1v1.5 is permanently blocked with no escape hatch. AES-CBC is blocked by default with the same time-boxed escape-hatch pattern as SHA-1. AES-GCM auth tag must be validated as exactly 16 bytes BEFORE calling `:crypto.crypto_one_time_aead/7`.
- **Single opaque error atom:** all decryption failure modes return `:decryption_failed` — distinct atoms would open a padding oracle. This is a hard contract, not a preference.
- **SP private keys never in DB:** `KeyResolver.Default` reads from app config only; diagnostic bundle allow-list excludes all key material. No exceptions for "convenience" columns.
- **Redirect-binding signature signs raw query bytes verbatim:** the `sign_redirect_query/3` function receives a pre-assembled binary; no re-serialization inside the function. Corpus golden tests enforce this.
- **Zero new Hex dependencies:** all v1.3 crypto is OTP stdlib (`:public_key`, `:crypto`, `:zlib`). Any NIF-based XML-Enc library would bypass the hardened saxy seam — permanently out of scope.
- **RSA-OAEP SHA-256 (`xmlenc11#rsa-oaep`) blocked at AlgorithmPolicy:** `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 26-28. AlgorithmPolicy maps this URI to `:blocked_pending_otp_support` with a clear error, not silent failure.
- **Ambiguity guard for simultaneous cleartext+encrypted assertion:** `PureBeam.build_parsed_doc/1` must detect and reject `:ambiguous_assertion` before any crypto. CVE-2026-2092 (Keycloak) was injection of a cleartext assertion alongside an encrypted one.

### Decisions / Constraints carried into v1.5

- **TD-02 (test_support prod exclusion) lands in Phase 41 BEFORE Phase 44 publishes** — if test_support remained in the production artifact when 1.4.0 shipped, adopters would inherit dev-only modules at runtime; Phase 45 parity verification would still pass (byte-equal to tag) but the tarball itself would be wrong. Sequencing TD-02 before PUB-03 is the load-bearing ordering decision of v1.5.
- **TD-03 (regex-alongside-tree retirement) is "one trust path" enforcement, not an optimization** — CLAUDE.md non-negotiable #2 says one parse path. Phase 41 closes the last exception (`locate_encrypted_assertion/1`) so the invariant holds without footnotes.
- **TRACE LiveView reuses telemetry catalog + audit ledger; NO new schemas** — the audit co-commit invariant (CLAUDE.md non-negotiable #5) means trust state lives in the audit ledger. A parallel store for trace data would split the source of truth. Phase 42 must read from existing telemetry handlers and audit rows only.
- **TRACE-02 redaction is wired via `cmd mix test`, not bundled test step** — Phase 30 hollow-gate invariant: every security suite runs as its own `cmd mix test` process. The `ci_gate_integrity_test.exs` meta-gate prevents recurrence. Phase 42 honours this when wiring `test/security/login_trace_test.exs`.
- **Single jump 1.2.0 → 1.4.0 (no intermediate 1.3.0 Hex release)** — chosen for adopter clarity. CHANGELOG retains `[1.3.0]` section so the historical phase summaries are preserved for `git log`/changelog readers, but Hex sees a single 1.4.0 publish. Rationale documented in CHANGELOG `[1.4.0]` header.

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
| v1.4_followup | 40-REVIEW WR-01 (redundant multi-line regex in drift test) | non_blocking, accepted |
| v1.4_followup | 40-REVIEW WR-02 (cwd-relative path in drift test) | non_blocking, accepted |
| v1.4_followup | `test/security/xml/adversarial_crypto_test.exs` `mix format` drift | being closed in Phase 41 (TD-05) |

## Tracked Follow-ups (carried into v1.5)

- **Mixed-content / inter-element-whitespace C14N gap — RESOLVED in 29-01 (2026-05-24).** Option-a landed exactly as recommended: ordered `content` field on `SaxyTree.Node`, `C14N` walks it in document order, `:text`/`:children` kept as byte-identical derived views. Docker-minted 1056-byte mixed-content golden (`mixed_content.c14n`) proves byte-equality to libxml2; 887-byte golden still green. See `29-01-SUMMARY.md`.
- **PrefixList golden cross-check (future, not blocking).** A future `InclusiveNamespaces/@PrefixList` golden should additionally cross-check against a non-libxml2 implementation (e.g. Apache Santuario) to fully neutralize the lxml-lineage caveat noted in `parser_differential_and_c14n/PROVENANCE.md`. Current goldens use no PrefixList, so the caveat is not yet load-bearing.
- **Phase 29 warning-level review items (WR-02..WR-05, IN-01..IN-03):** Non-blocking. Tracked in `.planning/todos/completed/29-code-review-followups.md`.
- **CVE ID backfill into `docs/advisories/2026-001-...`:** Pending async GitHub assignment.

## Session Continuity

**2026-05-27 — v1.5 roadmap reordered.** Phase 42 and Phase 45 swapped after user review: trace LiveView is now Phase 42 (was 45) and sequenced before publish prep (Phase 43, was 42), so the trace UI ships in the v1.4.0 Hex tarball by construction — no separate coordination needed. New linear order: 41 (tech-debt sweep) → 42 (trace LiveView) → 43 (version + CHANGELOG) → 44 (release-please publish) → 45 (parity verify) → 46 (DX). Phase 41 still must complete first because TD-02 (test_support prod exclusion) is load-bearing for the published 1.4.0 tarball — if test_support shipped in 1.4.0, parity verification (45) would still pass but the tarball itself would be wrong. Ready for `/gsd:plan-phase 41`.

**2026-05-27 — v1.5 roadmap created.** 6 phases defined (41-46), 15/15 requirements mapped, zero orphans. Original ordering placed trace LiveView at Phase 45; reordered same day (see entry above).

**2026-05-27 — Phase 40.1 context gathered (assumptions mode).** Generated `40.1-CONTEXT.md` locking the four audit-closure decisions: D-01 host-owned `index_session/4` linkage (no auto-wire in `consume_response/3`); D-02..D-04 minimal `logout.md` rewrite (lines 91-127 + host-linkage paragraph); D-05/D-06 drift-prevention CI test using `behaviour_info(:callbacks)` introspection wired into `ci.docs` per Phase 30 hollow-gate invariant; D-07..D-10 retroactive `38-/39-VERIFICATION.md` generation following `40-VERIFICATION.md` template and closure-phase pattern; D-11 cosmetic `38-04-SUMMARY.md` fix; D-12 two-wave structure (Wave 1: A/C/D/E parallel; Wave 2: B gated on A). Ready for `/gsd-plan-phase 40.1`.

**2026-05-27 — Phase 39 discussed.** Generated `39-CONTEXT.md` locking in the authoritative strategy for front-channel SLO caveats, Ecto-backed session requirement, and absolute-timeout fallbacks. Ready for `/gsd-plan-phase 39`.

**2026-05-27 — Phase 38 planning complete.** Generated 4 execution plans covering Single Logout Core & Security, strict XML parsing, replay protection, and signature verification. Generated `38-VALIDATION.md` for goal-backward verification. Ready for `/gsd-execute-phase 38`.

**2026-05-27 — v1.4 roadmap created.** 3 phases defined (38-40), 4 requirements mapped. Ready for `/gsd-plan-phase 38`.

**2026-05-26 — Phase 37 Plan 01 complete.** Added `guides/identity_mapping_and_provisioning.md` as the authoritative operator guide for anchor selection, NameID-vs-attribute identity policy, JIT create-or-update decisions, and the SCIM non-goal boundary. Tightened `Relyra.UserMapper` moduledoc so ExDoc now reflects the real ACS seam: verified `%Relyra.LoginResult{}` in, host-shaped user map out, later session establishment by `Relyra.SessionAdapter`. All plan verification `rg` checks passed. Resume: `/gsd:execute-phase 37` (Plan 2 of 2).

**2026-05-25 — Phase 34 Plan 04 complete (PHASE 34 DONE, ENC-01 closed).** The pipeline-level ENC-01 adversarial corpus (`test/security/xml_enc_adversarial_test.exs`, 9 tests) landed: positive control (SC#1) proving decrypt -> re-parse -> verify -> identity-read ordering, the 7 named fixtures each pinning their exact typed error (5 opaque `:decryption_failed`, fixture 5 `:ambiguous_assertion` before crypto), a read-before-verify guard (CVE-2025-54419 class, no identity leak before verification), and a supplemental multi-encrypted bonus. Wired into `mix ci.security` as its own non-hollow `cmd mix test` line (meta-gate enforced). Rule 1 fix: the signer now signs the Assertion WITH its default namespace (`:assertion_namespace` opt, default off) so the digest survives decrypt/splice/re-parse — Plan-02's round-trip smoke had never driven a full pipeline verify, so the `:digest_mismatch` was latent. Full suite 626/0; `mix ci.security` exit 0. SC#1 + SC#5 satisfied; ENC-01 marked complete. Resume: `/gsd:verify-phase 34`.

**2026-05-25 — Phase 34 Plan 03 complete.** ENC-01 decrypt-then-reparse wiring landed: `:decrypt_assertion` pre-stage in `ValidationPipeline.do_run/4` (detect -> reject-ambiguity-pre-crypto -> decrypt -> prefix-aware splice -> re-parse). PureBeam now tolerates encrypted-only Responses (Rule 3 fix). SC#2 + SC#3 satisfied; end-to-end SC#1 + the 7-fixture corpus close in Plan 04 (the last plan of Phase 34). Resume: `/gsd:execute-phase 34` (Plan 4 of 4).

**2026-05-25 — v1.3 roadmap created.** 6 phases defined (32-37), 10/10 requirements mapped. Ready for `/gsd:plan-phase 32`.

Phase 32 is the mandatory first phase — AlgorithmPolicy extension and DB schema migrations are the shared prerequisite for all ENC-01 and AUTHN-01 work. Phase 35 (AUTHN-01) can begin immediately after Phase 32 completes, in parallel with Phases 33-34. Phases 36-37 can proceed at any time.

## Decisions

- [Phase 39-01]: Positioned front-channel SLO as structurally unreliable due to modern browser privacy mechanisms (ITP/ETP/Privacy Sandbox).
- [Phase 39-01]: Mandated durable/stateful sessions as a strict prerequisite for SLO functionality.
- [Phase 39-01]: Established absolute session timeouts as the true security boundary, discouraging IdP polling.
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
- [Phase ?]: [Phase 34-01]: SP metadata build_sp_metadata/2 emits both KeyDescriptors (signing then encryption) before AssertionConsumerService (schema-valid order, T-34-02); signing descriptor unconditional (D-05), Phase 35 owns toggle-gating. EncryptionMethod advertises ONLY the xmlenc# decryptor accept-list (T-34-03); PUBLIC certs only (T-34-01), cert body base64-of-DER nil-safe.
- [Phase ?]: [Phase 34-02]: FakeIdP.encrypt/2 + encrypted_response/2 are the single canonical encrypted-assertion generator (sign-then-encrypt; self-contained xmlns on the Assertion; IV(12)||CT||Tag(16) layout). Round-trips byte-identically through the UNCHANGED XMLEnc.decrypt/3. enc_algorithm_uris/0 exposes rsa-oaep-mgf1p/aes256-gcm/rsa-1_5/aes256-cbc for Plan 04 fixtures; Signature stays a sibling of the Assertion (matches signed_candidates/1).
- [Phase 34-03]: :decrypt_assertion pre-stage wired into ValidationPipeline.do_run/4 (D-01) between parse_safely/2 and the UNCHANGED do_run_validations/6 (D-02): prefix-agnostic tree detector -> :ambiguous_assertion reject BEFORE any crypto (D-03/SC#2) -> single-EncryptedAssertion decrypt via unchanged XMLEnc.decrypt/3 (resolver MODULE + connection threaded in opts) -> prefix-aware exactly-one-match string-splice -> re-parse SAME parse_safely/2 seam. Three-tuple contract preserved on every exit; no identity field read pre-verify (CLAUDE.md #4). New typed error :ambiguous_assertion stays distinct from opaque :decryption_failed (D-03). >1 EncryptedAssertion -> :ambiguous_assertion (RESEARCH open-q1). No-op proven dependency-free via a raise-if-invoked :key_resolver (no Mox/:meck). decrypt_assertion_test 6/6; protocol 23/0; full 617/0; ci.security exit 0.
- [Phase 34-03] (Rule 3 blocking auto-fix): PureBeam.build_parsed_doc/1 now tolerates an encrypted-only Response (EncryptedAssertion present, no cleartext Assertion) via build_pre_decrypt_parsed_doc/1 — a minimal pre-decrypt parsed_doc carrying response_fields + :parse_tree + encrypted_pending:true. WITHOUT this, the OUTER parse_safely/2 rejected every encrypted Response with :missing_protocol_field before the pre-stage could run (D-01 unreachable). The cleartext path (build_cleartext_parsed_doc/1) keeps the strict assertion/signature gates byte-identical; strict gates re-run on the re-parsed decrypted plaintext (one parse path, CLAUDE.md #2). Plan 04's SC#1 positive control depends on this tolerance.
- [Phase 34-04]: Pipeline-level ENC-01 adversarial corpus (test/security/xml_enc_adversarial_test.exs) drives end-to-end through ValidationPipeline.run/4 via the single canonical FakeIdP.encrypt/encrypted_response generator: positive control (SC#1) + 7 named fixtures + 1 bonus multi-encrypted fixture. Fixtures 1/2/3/4/6 pin the SINGLE opaque :decryption_failed (no-oracle T-34-13); fixture 5 + bonus pin :ambiguous_assertion fired BEFORE decrypt (T-34-14); fixture 7 read-before-verify proves a verification-stage typed error AND no identity leak (T-34-12, CVE-2025-54419). Wired into ci.security as its own cmd-mix-test line + ci_gate_integrity_test.exs @gated_suites (non-hollow, T-34-15). Corpus 9/9; full suite 626/0; ci.security exit 0.
- [Phase 34-04] (Rule 1 bug fix): XmldsigSigner gained an :assertion_namespace opt (default OFF, cleartext path byte-identical); FakeIdP.signed_assertion_fragment/1 now passes assertion_namespace:true and stops re-declaring the namespace AFTER signing. WITHOUT this the encrypted positive control failed :digest_mismatch — the signer hashed a NON-namespaced Assertion but the post-decrypt/splice/re-parse Assertion carried xmlns=...assertion, so the verifier's recomputed exclusive-C14N digest differed (T-34-04). Plan-02's round-trip smoke only proved decrypt byte-identity, never a full pipeline verify, so the bug was latent until Plan 04's SC#1.
- [Phase 37]: Ground every UserMapper example in the real Phoenix ACS seam using LoginResult and Principal.
- [Phase 37]: Route identity mapping only from Day-2 and production follow-on docs, not Day-1 onboarding.
- [Phase 37]: Publish the guide in ExDoc extras and gate its presence in ci.docs.
- [Assessment 2026-05-27]: Done-% revised to 88-92% (band: "strong, with publish + DX polish remaining; no foundational gaps"). The library is *protocol-feature complete and adopter-blocked*. Hex publishing has lagged: mix.exs is `@version "1.2.0"` while git tag `v1.4` exists and PROJECT.md declares v1.4 shipped — Hex audience cannot see v1.3 or v1.4 features. Worse, hexdocs for 1.2.0 already include v1.3/v1.4 guide files (via `extras:`), so published docs describe features the published code doesn't implement.
- [Assessment 2026-05-27]: Drift in PROJECT.md "What This Is" — claims 8 provider presets, but `lib/relyra/provider/` only ships 4 first-class modules (okta, entra, google_workspace, adfs). Other 4 (Ping, OneLogin, Shibboleth, Keycloak) are decoder-table coverage in `guides/recipes/generic_saml.md`. Honest description: "4 first-class presets + a generic runbook covering 7 IdP families." Fix in v1.5 wedge 3.
- [Assessment 2026-05-27]: Brand-defining gap — `grep -r "stepwise\|login_trace" lib guides` returns nothing. The library's thesis ("every login produces a validation trace") has no per-login UI receipt; current surface is "subscribe to telemetry yourself." Stepwise login-trace LiveView is v1.5 wedge 2.
- [Assessment 2026-05-27]: AUTHN-POST-01 verdict = save-for-demand. Tractable inside existing C14N + sign primitives (`XmldsigSigner` is a working blueprint); ~3 plans / ~600-900 LOC; zero adopter pull at v1.4 close. Pre-baked plan in `signed-authn-requests-investigation.md`.
- [Assessment 2026-05-27]: KMS-01 verdict = save-for-demand. Behaviour evolution is additive (new `decrypt_cek/3` + `sign/4` callbacks; `resolve/1` PEM path stays); ~3 plans; AWS-only first, defer GCP/Azure/HSM. Compliance-pull (SOC 2/FedRAMP/HITRUST), not ergonomics-pull. No adopter signal yet.
- [Assessment 2026-05-27]: SIGNED-META-01 verdict = save-for-demand. Aspirational; only realistic adopter persona is Phoenix-based ed-tech winning an R1 university pilot — issue not filed. Real scope is signed `EntityDescriptor` + `mdrpi:RegistrationInfo` + `mdui:UIInfo` + `mdattr:EntityAttributes` + InCommon onboarding runbook (not just signature primitive).
- [Assessment 2026-05-27]: Carry-forward warning-level items (do NOT re-open phases; sweep in v1.5 wedge 3) — v1.3 audit WR-03 (unescaped metadata attribute interpolation in `lib/relyra/protocol/metadata.ex`, XSS-class defense-in-depth gap), WR-04 (`lib/relyra/test_support` compiled into prod artifact), WR-01/02 (regex-alongside-tree detector in `locate_encrypted_assertion/1`), WR-ENC-ATTR (REQUIREMENTS.md doc drift), Phase 40 deferred formatting drift in `adversarial_crypto_test.exs`.
- [Roadmap v1.5 / 2026-05-27]: Sequenced TD-02 (test_support prod exclusion) BEFORE Phase 44 publishes — chosen so the first published 1.4.0 tarball is clean. The alternative (let TD-02 land in a 1.4.1 follow-up) would mean shipping test_support to adopters on the first 1.4.0 install, even though Phase 45 parity verification (byte-equal to git tag) would still pass. The tarball-correctness contract takes precedence over phase-ordering convenience.
- [Roadmap v1.5 / 2026-05-27]: Phase 42 (trace LiveView) deliberately separated from Phase 46 (DX) despite both being "polish" — trace is a substantive new UI surface (~600-900 LOC per the assessment thread) with a dedicated security gate (TRACE-02 wired into `ci.security` as its own `cmd mix test` line). DX is doc + small installer touches. Single-phase fusion would obscure the load-bearing trace security gate.
- [Roadmap v1.5 reorder / 2026-05-27]: Swapped old Phase 42 (publish prep) and old Phase 45 (trace LiveView) on user review. New order: 41 → 42 (trace) → 43 (publish prep) → 44 (release-please publish) → 45 (parity) → 46 (DX). Rationale: with trace ahead of publish prep, the v1.4.0 tag cut in Phase 44 includes the trace LiveView by construction, so the trace UI ships in the v1.4.0 Hex tarball — no separate "ship trace in 1.4.0 or slip to 1.4.1" coordination needed.
