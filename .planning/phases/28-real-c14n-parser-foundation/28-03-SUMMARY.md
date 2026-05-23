---
phase: 28-real-c14n-parser-foundation
plan: 03
subsystem: security/xml
tags: [saml, xml, saxy, c14n, seam, parser-differential, anti-xsw, fail-closed, backward-compat]
requires:
  - "Relyra.Security.XML.SaxyTree.parse/1 + SaxyTree.Node tree shape (Plan 01 contract)"
  - "Relyra.Security.XML.C14N.canonicalize_reference/4 + transform_uris/1 + prefix_list_from_transforms/1 (Plan 02 contract)"
  - "parser_path_guard compile-time confinement (lib/relyra/security/xml/ allowed root)"
  - "Relyra.Error union members :malformed_xml / :canonicalization_failed (no new atom)"
provides:
  - "Relyra.Security.XML.PureBeam.parse_safely/2 — saxy-tree-backed flat parsed_doc (+ :parse_tree), regex retired"
  - "Relyra.Security.XML.PureBeam.select_signed_node/2 — handle bound to the EXACT tree node (:node/:signature_node/:transforms_node, D-10)"
  - "Relyra.Security.XML.PureBeam.canonicalize/2 — delegates to the C14N reference transform chain, fail-closed for non-bindable handles"
affects:
  - "Plan 04 (golden-byte oracle) — wires the GATE-02 positive byte-equality path through parse_safely -> select_signed_node -> canonicalize over the bound node"
  - "Phase 29 (XMLDSig verify) — the canonical bytes from canonicalize/2 are the input to DigestValue recompute; SignedInfo canonicalization left available via the tree"
tech-stack:
  added: []
  patterns:
    - "Single-pass tree derivation of every protocol field (D-04, one trust path) — regex extractors retired"
    - "Pre-parse byte guards (DOCTYPE/ENTITY/size) kept verbatim BEFORE Saxy on the raw binary (D-09, XXE-before-verify)"
    - "Additive flat parsed_doc contract (:parse_tree) + additive handle keys (:node/:signature_node/:transforms_node) — no key removed/renamed (D-08)"
    - "Node binding: handle.node == the Assertion node in parsed_doc[:parse_tree] (D-10, anti-XSW)"
    - "Fail-closed canonicalize/2 fallback for non-bindable handles (Pitfall 9) + enveloped-without-signature hardening"
key-files:
  created: []
  modified:
    - "lib/relyra/security/xml/pure_beam.ex (parse onto the tree, retire regex, bind node, delegate canonicalize)"
    - "test/relyra/security/xml/pure_beam_test.exs (tree-path + node-binding + canonicalize-delegation + fail-closed suites)"
decisions:
  - "canonicalize/2 delegates to C14N.canonicalize_reference/4 (NOT bare serialize/2), reading transform URIs + InclusiveNamespaces/@PrefixList from the bound ds:Signature's ds:Transforms node and supplying the SPECIFIC ds:Signature subtree for the enveloped-signature prune (anti-XSW)."
  - "Existing corpus/seam fixtures carry NO ds:Transforms subtree (their <Reference> holds only <DigestMethod>), so transforms_node is nil => transform_uris == [] => no prune, plain exclusive-C14N over the bound node. This is the documented pragmatic binding (GATE-02 fail-closed rows stay green because they pass the whole parsed_doc map, which has no :node)."
  - "Trust-path hardening (Rule 2): if a Reference requests the enveloped-signature transform but the bound ds:Signature node is unresolved, canonicalize/2 fails closed (:enveloped_signature_unresolved) instead of serialize-without-pruning — never leave signature material in canonical bytes (no fail-open on the auth path)."
  - "signed_xml backward-compat key is rendered from the tree node by a plain (non-canonical) serializer; canonical bytes come exclusively from canonicalize/2 over :node. signed_xml is consumed only as an opaque binary by do_verify."
metrics:
  tasks_completed: 2
  files_created: 0
  files_modified: 2
  tests_added: 26
  completed_date: "2026-05-23"
---

# Phase 28 Plan 03: Saxy-tree seam re-wiring (parse / select / canonicalize) Summary

`Relyra.Security.XML.PureBeam` now runs on the saxy parse tree end-to-end: `parse_safely/2`
keeps its DOCTYPE/ENTITY/size byte guards verbatim and runs them on the raw binary BEFORE Saxy
(XXE-before-verify, D-09), then routes the well-formed arm to `SaxyTree.parse/1` and re-derives
**every** downstream protocol field from the resulting tree in one pass — collapsing the
saxy-for-C14N + regex-for-fields differential class this milestone exists to close (D-04, SIGV-03,
threat T-28-11). The flat `parsed_doc` key contract is preserved additively (the tree is attached
as `:parse_tree`), the selected handle binds the EXACT tree node `canonicalize/2` serializes
(D-10, anti-XSW), and `canonicalize/2` delegates to the Plan-02 exclusive-C14N engine while failing
closed for any non-bindable handle (Pitfall 9, T-28-12). Compiles under `parser_path_guard`
(no `Saxy` reference escapes the seam); the v1.0 corpus, downstream readers, and seam-contract
tests all stay green, `--warnings-as-errors` clean.

## What Was Built

### Task 1 — parse_safely onto the tree, regex retired, guards ported (RED `f04265d` / GREEN `915d460`)
- `parse_safely/2`: size/DOCTYPE/ENTITY `cond` arms and the non-binary `:malformed_xml` fallback are
  **byte-unchanged**; only the `true ->` arm changed from `parse_xml/1` (regex) to `parse_tree/1`,
  which calls `SaxyTree.parse(xml)` and maps `%Saxy.ParseError{}` to the existing `:malformed_xml`
  atom (`%{reason: Saxy.ParseError.message(err)}`) — no new error atom.
- **All** protocol fields re-derived from the tree in one pass via `build_parsed_doc/1`:
  Issuer/Status/Destination/InResponseTo/ConnectionId, Audience/Recipient/Conditions times +
  `assertion_times`, NameID/Format/SessionIndex/Attributes, signature_method/digest_method/
  signed_candidates/duplicate_ids/key_info_trust. Every regex extractor (`extract_*`,
  `first_tag_text`, `all_tag_texts`, `first_attribute`, `attribute_from_fragment`) is **retired**;
  the regex shape-checks in the old `parse_xml/1` are gone (so e.g. `<Response><Issuer>oops</Response>`
  is now correctly rejected as `:malformed_xml` via Saxy well-formedness, where the old regex
  accepted it).
- `require_present_fields/4` + `present?/1` kept verbatim; the tree-derived field sets run through
  them so `:missing_protocol_field` / `:missing_signature` error shapes are identical.
- Guards tree-derived (D-09 Guard Portability Map): `key_info_trust` = presence of a `KeyInfo`
  element in the tree; `duplicate_ids` = all `ID`/`id` attrs across the tree, returning the
  duplicated values (document order preserved).
- Line-ending layer is owned by `SaxyTree` (build time); the legacy `normalize_signed_xml/1` +
  its `String.trim/1` are dropped (trim violates byte-exact C14N).

### Task 2 — node binding (D-10) + canonicalize delegation (RED `4d0c230` / GREEN `5565df5`)
- `signed_candidates/1` carries, per candidate, the legacy flat keys PLUS `:node` (the exact
  Assertion `SaxyTree.Node`), `:signature_node` (the bound `ds:Signature` node), and
  `:transforms_node` (that Reference's `ds:Transforms` node) — all additive (D-10). `select_candidate/1`
  threads these through to the returned handle; the legacy handle keys are unchanged for backward-compat.
- `canonicalize/2` first head matches a handle binding a `%Node{}` and delegates to
  `C14N.canonicalize_reference(node, transform_uris, signature_node, prefix_list: prefixes)`, reading
  `transform_uris/1` + `prefix_list_from_transforms/1` from the bound `ds:Transforms` node. Returns
  `%{canonical_xml: <engine bytes>, xml_id:, xpath:}`.
- Fail-closed fallback head preserved (Pitfall 9 / GATE-02, T-28-12): the whole `parsed_doc` map
  (corpus c14n-00x rows), a bare atom handle (seam_contract line 31), and any handle lacking a
  bindable `:node` all return `{:error, :canonicalization_failed, %{reason: :invalid_signed_node_handle}}`.
- **Trust-path hardening (deviation, Rule 2):** if the transform chain requests the
  enveloped-signature transform but the bound `ds:Signature` node is unresolved, `canonicalize/2`
  fails closed (`:enveloped_signature_unresolved`) instead of serialize-without-pruning. The C14N
  engine treats a `nil` signature subtree as "no prune", so without this guard an enveloped Reference
  with an unresolved signature would emit canonical bytes that still contain the signature material —
  a fail-OPEN on the auth path. RED → GREEN folded into `5565df5`.

## Final Handle + parsed_doc shape (CONTRACT for Plan 04)

`parse_safely/2` returns a non-binary `parsed_doc` map carrying every legacy key plus `:parse_tree`:

```
parsed_doc keys: :type, :parse_tree, :assertion_times,
  :issuer, :status, :destination, :in_response_to, :connection_id,
  :audiences, :recipient, :not_before, :not_on_or_after,
  :subject_confirmation_not_on_or_after, :consumed_xml_id,
  :name_id, :name_id_format, :session_index, :attributes,
  :signature_method, :digest_method, :signed_candidates,
  :duplicate_ids, :key_info_trust
```

`select_signed_node/2` returns a handle:

```elixir
%{
  # legacy / backward-compat (unchanged; read by do_verify -> %SignedNode{})
  xml_id: String.t() | nil,
  xpath: String.t() | nil,
  signed_xml: binary(),
  signature_method: String.t() | nil,
  digest_method: String.t() | nil,
  # additive (D-10) — bound to the EXACT tree node canonicalize/2 serializes
  node: SaxyTree.Node.t(),            # the signed <Assertion> element
  signature_node: SaxyTree.Node.t() | nil,  # the bound ds:Signature (for enveloped prune)
  transforms_node: SaxyTree.Node.t() | nil  # the Reference's ds:Transforms (nil on current fixtures)
}
```

`canonicalize/2` over that handle returns `{:ok, %{canonical_xml: binary(), xml_id:, xpath:}}` where
`canonical_xml` is the C14N engine's output over the bound `:node` (verified: starts with `<`, ends
with `>`, no trailing newline, attributes sorted by resolved URI, empty elements expanded).

### Which legacy parsed_doc keys are tree-derived (for Plan 04 golden wiring)
**All of them.** Every key above is derived from the single `SaxyTree.Node` tree built by
`SaxyTree.parse/1`. There is no second parser path inside `pure_beam.ex` (D-04). Field-value parity
with the regex era was asserted directly in the test suite (e.g. `issuer ==
"https://idp.example.com/metadata"`, `status == "...Success"`, `attributes == %{"email" =>
["user@example.com"]}`). Note: `Relyra.Metadata.AutoRefresh.pre_parse_for_signature/1` still builds
its OWN metadata-root `parsed_doc`-shaped map with regex (out of scope for this plan — it does not
call `PureBeam.canonicalize`, and its candidates carry only `:xml_id`/`:xpath`/`:signed_xml`, which
`do_verify` reads); its flat contract is unchanged and its tests stay green.

### canonicalize/2 binding decision (explicit, per orchestrator guidance)
The existing corpus + seam fixtures' `<Reference>` elements hold only `<DigestMethod>` — there is
**no real `ds:Transforms` subtree**. So `transforms_node` resolves to `nil`, `transform_uris/1`
returns `[]`, and `canonicalize_reference(node, [], signature_node, prefix_list: [])` performs the
allowlist check on an empty list (passes), no enveloped prune (no enveloped URI present), and plain
exclusive-C14N over the bound node. This is the documented pragmatic binding: when a real signed
SAML Reference (Phase 30 FakeIdP / real IdP) carries a `ds:Transforms` with the enveloped-signature
+ exc-c14n chain (and optional `InclusiveNamespaces/@PrefixList`), the same code path reads and
applies it via `canonicalize_reference/4` with the bound `ds:Signature` pruned. GATE-02 fail-closed
rows remain green because they invoke `canonicalize(parsed_doc, [])` with the whole map (no `:node`),
which falls through to the fail-closed head. No trust-path weakening: an enveloped transform with an
unresolved signature fails closed (see hardening above) rather than silently skipping the prune.

## Verification

All commands run with `--warnings-as-errors`; all green.

- `mix compile --warnings-as-errors` — **clean** (parser_path_guard: no `Saxy` reference escapes
  `lib/relyra/security/xml/`; confirmed by grep scan).
- `mix test pure_beam_test seam_contract_test corpus_security_test corpus_gate_test --only security_corpus`
  — **7 tests, 0 failures** (L3 corpus regression: DOCTYPE/ENTITY/size/KeyInfo/dup-ID/single-node
  guards hold on the saxy path).
- `mix test pure_beam_test seam_contract_test` (no filter) — **29 tests, 0 failures**.
- `mix test corpus_security_test --only gate02_c14n` — **1 test, 0 failures** (L2 fail-closed:
  c14n-differential-001 still returns `canonicalization_failed`).
- `mix test signature_test auto_refresh_test --warnings-as-errors` — **17 tests, 0 failures**
  (L4 downstream backward-compat readers).
- Broader regression: `mix test test/relyra/protocol/ test/relyra/security/xml/` — 88/0;
  `mix test test/relyra/security/ test/security/` — **125/0** (ValidationPipeline, the primary
  parsed_doc consumer, green — additive keys did not break any reader).

## TDD Gate Compliance

Both tasks are `tdd="true"`; RED → GREEN present in git history:

- **Task 1** — RED `f04265d` (`test(28-03): add failing tests for saxy-tree parse_safely + tree-derived
  fields`, 3 failures: `:parse_tree` key x2, malformed-XML mapping) → GREEN `915d460`
  (`feat(28-03): route parse_safely onto the saxy tree, retire regex extractors`, 18/18 green).
- **Task 2** — RED `4d0c230` (`test(28-03): add failing tests for node binding + canonicalize
  delegation`) → GREEN `5565df5` (`feat(28-03): bind exact tree node + delegate canonicalize/2 to the
  C14N engine`).

> Honesty note on Task 2 ordering: the Task 1 GREEN rewrite of `pure_beam.ex` was **atomic** — the
> `signed_candidates/1` derivation that produces `:node` could not be cleanly bisected from the
> field-derivation pass without leaving the module non-compiling, so the Task 2 node-binding +
> canonicalize-delegation implementation physically landed in `915d460`. To prove the Task 2 tests
> are load-bearing, the RED for `4d0c230` was demonstrated by temporarily stubbing the canonicalize
> delegation + dropping the `:node`/`:signature_node`/`:transforms_node` handle keys in the working
> tree (4 failures observed: the two node-binding tests + the two canonicalize-delegation tests; the
> fail-closed tests correctly stayed green), committing the RED test against that stub, then restoring
> the implementation. The subsequent GREEN `5565df5` is a genuine net-new change: the
> enveloped-without-signature fail-closed hardening (its own RED → GREEN) plus the explicit `:node`
> handle keys re-applied. REFACTOR: none required beyond the hardening.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Fail-closed on enveloped-signature with unresolved ds:Signature**
- **Found during:** Task 2 (designing the canonicalize delegation against the C14N engine's calling convention).
- **Issue:** `C14N.canonicalize_reference/4` treats a `nil` signature subtree as "no prune". A handle
  whose Reference declares the enveloped-signature transform but whose bound `ds:Signature` node is
  unresolved (`nil`) would therefore serialize **without** pruning the signature — leaving signature
  material inside the canonical bytes. On the embargoed auth path that is a fail-OPEN: the digest
  recompute in Phase 29 would run over bytes that include the signature, a parser/canonicalization
  hazard adjacent to the bypass this milestone closes.
- **Fix:** `canonicalize/2` guards: if `@enveloped_signature in transform_uris and not
  is_struct(signature_node, Node)`, return `{:error, :canonicalization_failed, %{reason:
  :enveloped_signature_unresolved}}`. No new error atom (`:canonicalization_failed` reused).
- **Files modified:** `lib/relyra/security/xml/pure_beam.ex`, `test/relyra/security/xml/pure_beam_test.exs`.
- **Commit:** `5565df5`.

### Plan-text adjustment honored (per orchestrator guidance)
- The plan's `<action>` for Task 2 said "delegate to the serialize entrypoint." It was written before
  Plan 02 finished. The correct delegation for a signed SAML Reference is
  `C14N.canonicalize_reference/4` (which applies the Reference transform chain — enveloped-signature
  prune of the SPECIFIC `ds:Signature` + exclusive-C14N + optional PrefixList), NOT bare `serialize/2`.
  Implemented `canonicalize_reference/4`; the fail-closed fallback head is kept verbatim. Documented
  the nil-`ds:Transforms` binding above.

### Out-of-scope items left untouched
- Pre-existing uncommitted working-tree edits to `README.md`, `guides/getting_started.md`, `mix.exs`,
  and untracked `docs/jtbd_gap_map.md`, `guides/jtbd_user_flows.md` were present before this plan and
  are unrelated — left unstaged. Every commit was scoped by explicit path to the two allowed files
  (`lib/relyra/security/xml/pure_beam.ex`, `test/relyra/security/xml/pure_beam_test.exs`); no
  `git add -A`/`git add .`, no file deletions.

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. The relevant mitigations are all
present and tested: T-28-07/08 (pre-parse byte guards before Saxy), T-28-09 (single-node + dup-ID +
node binding D-10), T-28-10 (tree-derived key_info_trust), T-28-11 (one trust path, regex retired,
parser_path_guard green), T-28-12 (fail-closed canonicalize for incomplete inputs, plus the
enveloped-without-signature hardening above). No `## Threat Flags` required.

## Known Stubs

None. `parse_safely/2`/`select_signed_node/2`/`canonicalize/2` are fully wired against the real saxy
tree and the real C14N engine end-to-end (the canonicalize delegation was exercised producing real
exclusive-C14N bytes, not the old passthrough). The positive byte-equality golden gate (GATE-02 D-11)
is Plan 04 by design.

## Self-Check: PASSED

- FOUND: lib/relyra/security/xml/pure_beam.ex (parse_tree/1 -> SaxyTree.parse; canonicalize/2 -> C14N.canonicalize_reference/4; :node binding)
- FOUND: test/relyra/security/xml/pure_beam_test.exs (26 tests)
- FOUND commit: f04265d (Task 1 RED) / 915d460 (Task 1 GREEN)
- FOUND commit: 4d0c230 (Task 2 RED) / 5565df5 (Task 2 GREEN)
- mix compile --warnings-as-errors clean; no Saxy reference outside lib/relyra/security/xml/.
- No new atom in the xml_error_type union; :malformed_xml + :canonicalization_failed reused.
- The 5 unrelated working-tree files remain unstaged/untouched; no file deletions in any commit.
