---
phase: 29-cryptographic-xmldsig-verification
plan: 01
subsystem: testing
tags: [xmldsig, c14n, exclusive-c14n, libxml2, saml, mixed-content, golden-oracle, saxy]

# Dependency graph
requires:
  - phase: 28-real-c14n-parser-foundation
    provides: "SaxyTree parse tree + hand-rolled exclusive-C14N engine (C14N.serialize/canonicalize_reference) + the 887-byte golden-byte oracle harness (gate02_c14n) under the Relyra.Security.XML seam"
provides:
  - "Ordered content field on SaxyTree.Node ([{:text,_} | {:element,_}] in document order); :text/:children kept as byte-identical derived views"
  - "C14N.render_element/3 walks content in document order (the escape_text(node.text)-before-children bug is gone)"
  - "anti-XSW prune_subtree/1 rewritten to prune on content (closes a fail-OPEN regression the content walk introduced)"
  - "Docker-minted mixed-content golden (mixed_content.c14n, 1056 bytes) proving byte-equality to libxml2 on pretty-printed signed XML"
affects: [29-03-xmldsig-verify, 29-04-positive-controls, 29-05-real-idp-fixtures, 30-assurance]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Document-order parse model: ordered content tuples are the single source of truth; flat :text/:children are derived projections"
    - "Out-of-band golden minting (D-12): native libxml2 toolchain runs only in Docker; CI reads committed bytes"
    - "Dual-oracle byte-equality cross-check: lxml (libxml2 2.14.6) + xmllint (libxml2 2.9.14) + Relyra Elixir engine as the independent third agreeing implementation"

key-files:
  created:
    - test/fixtures/security/xml/parser_differential_and_c14n/mixed_content.input.xml
    - test/fixtures/security/xml/parser_differential_and_c14n/mixed_content.c14n
  modified:
    - lib/relyra/security/xml/saxy_tree.ex
    - lib/relyra/security/xml/c14n.ex
    - test/security/xml/corpus_security_test.exs
    - test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md
    - test/relyra/security/xml/saxy_tree_test.exs
    - test/relyra/security/xml/c14n_test.exs
    - test/relyra/security/xml/c14n_transform_test.exs

key-decisions:
  - "Option-a (D-09): add ordered content to SaxyTree.Node, walk it in C14N; keep :text/:children as derived views so no pure_beam field-derivation helper changes"
  - "prune_subtree/1 must prune on content (not children-only) once the serializer walks content — children-only prune became fail-OPEN, re-opening the anti-XSW gap (D-10/T-29-03)"
  - "Mixed-content golden minted out-of-band in Docker (D-12); whitespace deliberately NOT stripped during mint because the inter-element whitespace IS the bug class under test"

patterns-established:
  - "Ordered content as single source of truth for document order; flat fields are projections"
  - "Every new C14N golden gets a PROVENANCE row + dual-oracle cross-check table (Oracle1==Oracle2, idempotent, Elixir-engine==golden)"

requirements-completed: [SIGV-02]

# Metrics
duration: 58min
completed: 2026-05-24
---

# Phase 29 Plan 01: Mixed-Content C14N Document-Order Fix Summary

**Exclusive-C14N now emits text and child elements in source document order (Option-a: ordered `content` on `SaxyTree.Node`), proven byte-for-byte against libxml2 with a new 1056-byte Docker-minted pretty-printed-assertion golden — while the existing 887-byte whitespace-free golden stays byte-identical.**

## Performance

- **Duration:** ~58 min (across two agent sessions; Task 3 minted out-of-band in Docker)
- **Started:** 2026-05-24T12:00:26Z (Task 1 commit `4411f91`)
- **Completed:** 2026-05-24T12:58:34Z (Task 3 commit `621d117`)
- **Tasks:** 3 (Tasks 1-2 by prior agent; Task 3 + finalize this session)
- **Files modified:** 7 (2 created, 5 modified) + this SUMMARY

## Accomplishments

- **D-09 document-order fix landed.** `SaxyTree.Node` gained an ordered `content: [{:text,_} | {:element,_}]` field built in document order across the SAX handlers; `:text` and `:children` remain byte-identical DERIVED views (pure_beam `first_text`/`all_texts`/`trimmed_text` untouched). `C14N.render_element/3` walks `content` in source order — the `escape_text(node.text)`-before-all-children bug is gone.
- **Byte-correctness PROVEN on pretty-printed XML.** A new Docker-minted mixed-content golden (`mixed_content.c14n`, 1056 bytes) reproduces libxml2's exclusive-C14N output byte-for-byte for an `<Assertion>` whose every child is separated by newline+indent inter-element whitespace. This is the hard precondition for every realistic positive control (D-10) and for Plan 03 crypto.
- **887-byte golden held green.** The pre-existing whitespace-free exclusive-C14N golden remains byte-identical — no regression.
- **anti-XSW fail-OPEN regression closed.** The content-walk switch silently made the children-only enveloped-signature prune fail-OPEN; `prune_subtree/1` was rewritten to prune on `content` (see Deviations).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ordered `content` field to SaxyTree.Node (document-order build; :text/:children derived)** - `4411f91` (feat)
2. **Task 2: Walk `content` in document order in C14N.render_element/3 (Option-a) + anti-XSW prune fix** - `8052658` (fix)
3. **Task 3: Mint mixed-content C14N golden out-of-band + byte-equality test (D-09/D-10)** - `621d117` (test)

Progress checkpoint (prior session): `bcc7092` (docs: Tasks 1-2 recorded, paused at Task 3).

**Plan metadata:** (this commit) `docs(29-01): complete plan` — SUMMARY + STATE + ROADMAP.

## Files Created/Modified

- `lib/relyra/security/xml/saxy_tree.ex` - `Node` struct gains ordered `content`; built head-first in `append_text/2` + `:end_element`, reversed in `finalize_node/1`; `:text`/`:children` projected as derived views.
- `lib/relyra/security/xml/c14n.ex` - `render_element/3` walks `node.content` in document order; `bindable?/1` adds `is_list(content)` (Pitfall 9 fail-closed); `prune_subtree/1` prunes on `content` (anti-XSW fail-OPEN fix).
- `test/fixtures/security/xml/parser_differential_and_c14n/mixed_content.input.xml` - **created.** Pretty-printed signed SAML Response; the referenced `<Assertion>` has newline+indent inter-element whitespace between every child (`<Issuer>`, `<Subject>`, `<Conditions>`, `<AuthnStatement>` and descendants).
- `test/fixtures/security/xml/parser_differential_and_c14n/mixed_content.c14n` - **created.** Docker-minted golden, 1056 bytes, raw UTF-8, no BOM, no trailing newline (last byte `0x3e`). sha256 `edb5abd058d37614f0e0eee358590ac729ba6a2821bf3e7822658caf5af3b020`.
- `test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md` - new fixture row + dedicated "what it exercises" section + dual-oracle cross-check table + mint recipe (`mint_mixed_c14n.py`).
- `test/security/xml/corpus_security_test.exs` - new `@tag :gate02_c14n` byte-equality test over `mixed_content.input.xml` == `mixed_content.c14n`, with `refute String.ends_with?(out, "\n")` + node-binding assertion (D-10).
- `test/relyra/security/xml/saxy_tree_test.exs`, `c14n_test.exs`, `c14n_transform_test.exs` - unit assertions for document-order content + mixed-content interleaving; CR text-escape test updated to the `content:` node shape; 3 enveloped-signature prune tests restored by the prune fix.

## Decisions Made

- **Option-a (D-09):** ordered `content` is the single source of truth for document order; `:text`/`:children` are derived projections, so no downstream pure_beam field-derivation helper changed. ~55 LOC as forecast in `28-04-SUMMARY.md`.
- **Mint discipline (D-12):** the mixed-content golden was minted out-of-band in Docker (`python:3.12-slim` + lxml + libxml2-utils + xmlsec1); CI never runs the native toolchain — it reads only the committed bytes. Whitespace was deliberately preserved during mint because inter-element whitespace is the bug class under test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `prune_subtree/1` was fail-OPEN after the content walk — rewritten to prune on `content`**
- **Found during:** Task 2 (C14N document-order walk).
- **Issue:** Once `render_element/3` switched to walking `content` (instead of `children`), the anti-XSW enveloped-signature prune in `c14n.ex` still removed the matched `ds:Signature` only from `children`. The `content` list still held the `{:element, signature}` entry, so the canonical bytes again included the signature material the prune is meant to strip — a **fail-OPEN** regression re-opening threat T-29-03 / D-10 (signature material leaking into the canonicalized reference).
- **Fix:** Rewrote `prune_subtree/1` to drop `{:element, ^target}` from `content`, recurse into surviving elements, pass `{:text, _}` segments through unchanged, and keep `:children` as a consistent derived view of the pruned `content`.
- **Files modified:** `lib/relyra/security/xml/c14n.ex`; test updates in `test/relyra/security/xml/c14n_transform_test.exs` (3 pre-existing enveloped-signature tests restored) and `test/relyra/security/xml/c14n_test.exs` (one direct-`%Node{}` CR text-escape test updated to the `content:` shape).
- **Verification:** 3 enveloped-signature prune tests green again; full XML-security suite 102/0.
- **Committed in:** `8052658` (Task 2 commit).

---

**Total deviations:** 1 auto-fixed (1 Rule-1 bug — anti-XSW fail-OPEN).
**Impact on plan:** Necessary for security correctness (D-10/T-29-03 fail-closed). No scope creep — confined to the prune path the content walk touched.

## Issues Encountered

None. The dual-oracle mint agreed on the first run; both goldens passed under `--warnings-as-errors`.

## Evidence (Task 3 verification)

- **`mixed_content.c14n`:** 1056 bytes; first bytes `<Ass` (no BOM); last bytes `ion>` (last byte `0x3e`, no trailing newline).
- **sha256:** `edb5abd058d37614f0e0eee358590ac729ba6a2821bf3e7822658caf5af3b020`
- **Oracle 1 (lxml, libxml2 2.14.6) == Oracle 2 (xmllint --exc-c14n, libxml2 2.9.14):** **True**
- **Idempotence (re-parse golden → re-c14n == golden):** **True**
- **Elixir C14N engine (`PureBeam.parse_safely → select_signed_node → canonicalize`) == golden:** **True**
- **`mix test ... --only gate02_c14n --warnings-as-errors`:** 3 tests, 0 failures — BOTH goldens pass (887-byte whitespace-free + 1056-byte mixed-content).
- **`mix test test/relyra/security/xml/ test/security/xml/ --warnings-as-errors`:** 102 tests, 0 failures (no regression).

## Next Phase Readiness

- Canonical-bytes correctness now holds for pretty-printed / mixed-content signed XML — the precondition Plan 03 (`:public_key.verify(SignedInfo)` + `DigestValue` recompute/compare) and the positive controls (Plans 04/05) depend on.
- Open follow-up for a future golden: a PrefixList (`InclusiveNamespaces/@PrefixList`) case should additionally cross-check against a non-libxml2 implementation (e.g. Apache Santuario) to fully neutralize the lxml-lineage caveat noted in PROVENANCE.md. Not required for SIGV-02.

## Self-Check: PASSED

- All created/modified files exist on disk (mixed_content.input.xml, mixed_content.c14n, PROVENANCE.md, corpus_security_test.exs, saxy_tree.ex, c14n.ex, 29-01-SUMMARY.md).
- All task commits exist in git history: `4411f91` (Task 1), `8052658` (Task 2), `621d117` (Task 3).

---
*Phase: 29-cryptographic-xmldsig-verification*
*Completed: 2026-05-24*
