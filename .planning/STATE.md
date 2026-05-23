---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: — Verify the Trust Path
status: executing
last_updated: "2026-05-23T23:00:00.000Z"
last_activity: 2026-05-23 -- Completed Phase 28 Plan 04 (golden-byte oracle + GATE-02); all 4 plans done. ci.security red ONLY on pre-existing deps.audit advisories (out of phase scope)
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

### Milestone-level blocker surfaced (NOT Phase 28 scope)

- **`mix ci.security` is RED at `deps.audit`** — 4 pre-existing dependency CVE advisories, unrelated to any Phase 28 code (no Phase 28 commit touches `mix.lock`): **postgrex 0.22.0** (GHSA-r73h-97w8-m54h, channel-name SQL injection, high → 0.22.2), **plug 1.19.1** (GHSA-468c-vq7p-gh64, multipart DoS, high → 1.19.2), **phoenix 1.8.5** (GHSA-628h-q48j-jr6q, long-poll memory DoS, high → 1.8.6), **decimal 2.3.0** (GHSA-rhv4-8758-jx7v, exponent DoS, moderate → 3.0.0). `hex.audit` separately skipped (no network in this env). **Action needed (separate task, v1.1 milestone):** dependency bumps. The postgrex SQL-injection advisory is high-priority for a security milestone.

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table.

## Deferred Items

Items acknowledged and deferred at the v1.0 milestone close (2026-05-08):

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 15: 15-VERIFICATION.md | human_needed |

Deferred to the next milestone ("Advanced Federation"): encrypted assertions, complete Single Logout, signed outbound AuthnRequests, adoption-docs polish, runnable demo app.

## Session Continuity

Next action: Phase 28 is plans-complete (4/4). Options: (1) `/gsd:verify-phase 28` to formally verify the phase goal; (2) address the milestone-level `deps.audit` dependency bumps (postgrex/plug/phoenix/decimal) — separate task, recommended before milestone close given the postgrex SQL-injection advisory; (3) proceed to Phase 29 (XMLDSig crypto verify), which now rests on the PROVEN canonical-bytes precondition (SIGV-03).

Last session: 2026-05-23 — completed all of Phase 28 (28-01 saxy substrate → 28-02 exclusive-C14N engine → 28-03 seam re-wiring → 28-04 golden-byte oracle proof). SIGV-03 correctness PROVEN: canonicalize/2 byte-equal to libxml2 (887 bytes, gate02_c14n green). Golden minted out-of-band in Docker (no host install). ci.security red ONLY on pre-existing deps.audit advisories. Resume file: None.
