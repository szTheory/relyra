---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: — Verify the Trust Path
status: executing
last_updated: "2026-05-23T22:40:00.000Z"
last_activity: 2026-05-23 -- Completed Phase 28 Plan 03 (saxy-tree seam re-wiring); Plan 04 BLOCKED on out-of-band oracle tooling
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 4
  completed_plans: 3
  percent: 75
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-23)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 28 — real-c14n-parser-foundation

## Current Position

Phase: 28 (real-c14n-parser-foundation) — EXECUTING
Plan: 4 of 4
Status: Plans 01–03 complete; Plan 04 BLOCKED at its blocking-human gate (out-of-band golden-oracle minting needs lxml + xmlsec1, neither installed)
Last activity: 2026-05-23 -- Completed Phase 28 Plan 03

Milestone progress: [----------] 0/4 phases complete (Phase 28: [████████░░] 3/4 plans)

## Performance Metrics

- Phases planned this milestone: 4 (28-31)
- Plans complete: 3 (28-01, 28-02, 28-03)
- Coverage: 8/8 v1.1 requirements mapped

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 28 | 01 | 6m | 3 | 4 (2 created, 2 modified) |
| 28 | 02 | — | 2 | 1 modified (c14n.ex) + 2 test files |
| 28 | 03 | — | 2 | 1 modified (pure_beam.ex) + 1 test file |

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

### Blocker carried into Phase 28 Plan 04

- **Plan 04 is `autonomous: false` with a blocking-human gate (Task 1).** The golden-byte oracle must be minted OUT-OF-BAND with pinned `lxml` cross-checked against `xmlsec1` (D-12: native toolchain must never enter `mix ci.security`). On this host: `xmlsec1` NOT installed, python `lxml` NOT installed (`xmllint`/libxml2 2.9.13 present but insufficient — not an exclusive-C14N+cross-check oracle). Resolution pending user decision (install toolchain & mint here, vs. mint elsewhere, vs. defer).

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table.

## Deferred Items

Items acknowledged and deferred at the v1.0 milestone close (2026-05-08):

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 15: 15-VERIFICATION.md | human_needed |

Deferred to the next milestone ("Advanced Federation"): encrypted assertions, complete Single Logout, signed outbound AuthnRequests, adoption-docs polish, runnable demo app.

## Session Continuity

Next action: execute Phase 28 Plan 04 (golden-byte oracle + GATE-02) — BLOCKED at its blocking-human gate (Task 1). Need pinned `lxml` + `xmlsec1` to mint the golden bytes out-of-band (author `assertion_inherited_ns.input.xml`, mint `assertion_inherited_ns.c14n` via `etree.tostring(..., method="c14n", exclusive=True)`, cross-check `xmlsec1 --c14n-exc`, write PROVENANCE.md), then Task 2 (auto) adds the byte-equality + node-binding assertions to `corpus_security_test.exs`. Resume-signal: "approved" once the golden fixture + PROVENANCE are committed.

Last session: 2026-05-23 — completed 28-01/02/03 (saxy substrate → exclusive-C14N engine → seam re-wiring). 99/99 trust-path regression green, compile clean. Stopped at: Plan 04 blocking-human gate (oracle tooling absent on host). Resume file: None.
