---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: — Verify the Trust Path
status: executing
last_updated: "2026-05-23T23:30:00.000Z"
last_activity: 2026-05-23 -- Phase 28 plans 4/4 done + post-phase cleanup (deps CVEs fixed, ci.security GREEN, mix test 486/0, tree clean, embargo memory relaxed)
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-23)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 28 — real-c14n-parser-foundation

## Current Position

Phase: 28 (real-c14n-parser-foundation) — ALL PLANS COMPLETE (pending /gsd:verify-phase)
Plan: 4 of 4 done
Status: Plans 01–04 complete. SIGV-03 correctness PROVEN (canonicalize/2 byte-equal to libxml2 golden, 887 bytes). Caveat: milestone-level `mix ci.security` is red ONLY at deps.audit (4 pre-existing dependency CVEs — postgrex/plug/phoenix/decimal — needing version bumps, outside Phase 28 scope).
Last activity: 2026-05-23 -- Completed Phase 28 Plan 04

Milestone progress: [----------] 0/4 phases complete (Phase 28: [██████████] 4/4 plans, pending phase verification)

## Performance Metrics

- Phases planned this milestone: 4 (28-31)
- Plans complete: 4 (28-01, 28-02, 28-03, 28-04)
- Coverage: 8/8 v1.1 requirements mapped

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 28 | 01 | 6m | 3 | 4 (2 created, 2 modified) |
| 28 | 02 | — | 2 | 1 modified (c14n.ex) + 2 test files |
| 28 | 03 | — | 2 | 1 modified (pure_beam.ex) + 1 test file |
| 28 | 04 | — | 2 | 3 created (golden fixtures + PROVENANCE) + 1 test |

## Accumulated Context

### Roadmap Evolution

- v1.0 shipped 2026-05-08 (Phases 25-27). Highest shipped phase = 27.
- v1.1 starts at Phase 28 (continues numbering; does not reset).
- v1.1 is a focused, URGENT security milestone derived from the 2026-05-23 P0 audit.
- Phase sequence is dependency-ordered: foundation (28) → verification (29) → assurance (30) → disclosure (31). The verify math (SIGV-01/02) cannot land before correct canonicalization (SIGV-03), so Phase 28 must complete first.

### Decisions / Constraints carried into v1.1

- **ADR-0001 governs:** pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam. The hybrid+xmlsec NIF (GATE-03 matrix) is a **conditional rollback** only if pure-BEAM correctness gates can't be met — NOT a planned phase.
- **Brownfield, extend not rebuild:** work lands in `lib/relyra/security/signature.ex` (`do_verify`), `lib/relyra/security/xml/pure_beam.ex` (add `saxy` parse tree + real exclusive C14N), `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/test_support/fake_idp.ex`. Reuse the existing hardened parser boundary, single-signed-node selection, duplicate-ID + document-`KeyInfo` rejection — these stay; the new work is the actual crypto + correct C14N underneath them.
- **`saxy` is not yet in `mix.exs`** — the parser path ADR-0001 specified was never added. Phase 28 adds it.
- **Fix-first posture:** branch `security/xmldsig-real-verification`; GHSA/CVE/CHANGELOG advisory published at the fixed release, not before.

### Decisions made in Phase 28 Plan 01

- **Tree-node shape (CONTRACT for Plans 02/03):** the parse tree is built from `%Relyra.Security.XML.SaxyTree.Node{}` structs — `qname` (verbatim), `prefix`, `local`, `attrs` (document order, attr-value normalized; xmlns decls retained verbatim AND surfaced in `:ns`), `ns` (in-scope map; `""` key = default namespace), `children` (document order), `text` (line-ending normalized, not whitespace-collapsed). Documented verbatim in `28-01-SUMMARY.md`. A struct (not a bare map) was chosen for a stable, introspectable contract.
- **saxy 1.6.0 added non-optional** (T-28-SC supply-chain checkpoint pre-approved). The three Relyra-owned infoset-normalization layers are applied at tree-build time (in-scope ns stack; attr-value `#x9`/`#xA`/`#xD`->single space per XML 1.0 §3.3.3; line-ending `\r\n`/`\r`->`\n` per §2.11), kept strictly separate from C14N escaping (serialize-time, Plan 02). CRLF inside an attribute value collapses to a single space.
- **SIGV-03 remains in progress** (NOT complete): Plan 01 delivers the saxy parse-tree substrate only; the exclusive-C14N engine (Plan 02) and seam re-wiring (Plan 03) are required before SIGV-03 is satisfied.

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

Items acknowledged and deferred at the v1.0 milestone close (2026-05-08):

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 15: 15-VERIFICATION.md | human_needed |

Deferred to the next milestone ("Advanced Federation"): encrypted assertions, complete Single Logout, signed outbound AuthnRequests, adoption-docs polish, runnable demo app.

## Tracked Follow-ups (v1.1, in-flight)

- **Mixed-content / inter-element-whitespace C14N gap — FIRST NEXT TASK.** `SaxyTree.Node` carries one `:text` per element and `C14N.render_element/3` emits it before children, so pretty-printed / mixed-content signed XML mis-canonicalizes vs libxml2 → would **fail Phase 29 digest verification on real-IdP documents that aren't whitespace-free**. Fail-safe (rejects, never bypasses). **Recommended fix (Option a):** add an ordered `content: [{:text,_} | {:element,_}]` field to `SaxyTree.Node`, have `C14N` walk it in document order, keep `text`/`children` as derived views (pure_beam field-derivation untouched); re-mint a whitespace golden in Docker + add a `gate02_c14n` test. ~55 LOC, ~10 test updates; full blast radius + Option (b) comparison in `28-04-SUMMARY.md`. Do as `/gsd:quick` or fold into `/gsd:plan-phase 29`.

## Session Continuity

Post-phase-28 cleanup DONE (2026-05-23): dependency CVEs fixed, `mix ci.security` GREEN, full `mix test` 486/0, working tree clean, embargo memory relaxed. Phase 28 plans 4/4 complete; SIGV-03 PROVEN.

Next GSD command (after context clear): `/gsd:verify-phase 28` to formally verify the phase goal, then `/gsd:plan-phase 29` (XMLDSig `:public_key.verify` + DigestValue recompute), which rests on the PROVEN canonical-bytes precondition. **First follow-up to fold in:** the mixed-content C14N fix (see Tracked Follow-ups) — `/gsd:quick` or within Phase 29 planning.

Last session: 2026-05-23 — completed all of Phase 28 (28-01 saxy → 28-02 exclusive-C14N → 28-03 seam re-wiring → 28-04 golden-byte oracle proof; canonicalize/2 byte-equal to libxml2, 887 bytes, gate02_c14n green), then post-phase cleanup (deps CVEs, ci.security green, 486/0, jtbd docs, memory). Resume file: None.
