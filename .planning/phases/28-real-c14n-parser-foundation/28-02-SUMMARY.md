---
phase: 28-real-c14n-parser-foundation
plan: 02
subsystem: security/xml
tags: [saml, xml, c14n, exclusive-canonicalization, enveloped-signature, prefixlist, transform-allowlist, anti-xsw]
requires:
  - "Relyra.Security.XML.SaxyTree.Node tree-node shape (Plan 01 contract)"
  - "parser_path_guard compile-time confinement (lib/relyra/security/xml/ allowed root)"
  - "Relyra.Error + :canonicalization_failed member of the xml_error_type union"
provides:
  - "Relyra.Security.XML.C14N.serialize/2 — exclusive-C14N 1.0 (no-comments) node serializer"
  - "Relyra.Security.XML.C14N.canonicalize_reference/4 — transform-chain orchestrator (enveloped-sig prune + exc-c14n)"
  - "Relyra.Security.XML.C14N.transform_uris/1 — reads ds:Transform Algorithm URIs in document order"
  - "Relyra.Security.XML.C14N.prefix_list_from_transforms/1 — reads InclusiveNamespaces/@PrefixList"
affects:
  - "Plan 03 (seam re-wiring) — wires canonicalize/2 to serialize/2 + canonicalize_reference/4; reads transforms via the two helpers"
  - "Plan 04 (golden-byte oracle) — proves serialize/2 + canonicalize_reference/4 output byte-for-byte vs lxml+xmlsec1 (GATE-02)"
  - "Phase 29 (XMLDSig verify) — canonical bytes are the input to :public_key.verify (SignedInfo) + DigestValue recompute"
tech-stack:
  added: []
  patterns:
    - "Hand-rolled exclusive-C14N over the SaxyTree.Node shape (D-05, no correct BEAM library exists)"
    - "Rendered-vs-in-scope namespace stack pair for visibly-utilized rendering (Pitfall 1)"
    - "Transform allowlist gate — fail-closed reject of any URI outside {enveloped-sig, exc-c14n} (T-28-05)"
    - "Value-equal subtree pruning for the enveloped-signature transform (anti-XSW, D-10)"
key-files:
  created: []
  modified:
    - "lib/relyra/security/xml/c14n.ex (+ Task 2 transform chain; Task 1 core landed earlier in this plan)"
    - "test/relyra/security/xml/c14n_test.exs (Task 1 suite — committed earlier in this plan)"
    - "test/relyra/security/xml/c14n_transform_test.exs (Task 2 suite)"
decisions:
  - "Transform allowlist kept STRICT to {enveloped-signature, exc-c14n}. Inclusive C14N is deliberately NOT allowlisted: this engine implements exclusive C14N only, so accepting an inclusive URI would emit wrong bytes — a silent security hole. Matches threat T-28-05."
  - "Enveloped-signature pruning identifies the target ds:Signature by VALUE equality (==) against the supplied node, so an unrelated sibling Signature with different content survives (anti-XSW, D-10). Edge case: two byte-identical sibling Signatures would both prune — not realistic (SignatureValue differs)."
  - "canonicalize_reference/4 is the public transform entrypoint; :prefix_list is the single serialize/2 option key Plan 03 must thread through for InclusiveNamespaces forced rendering."
metrics:
  tasks_completed: 2
  files_created: 0
  files_modified: 1
  tests_added: 30
  completed_date: "2026-05-23"
---

# Phase 28 Plan 02: Exclusive XML Canonicalization 1.0 engine Summary

`Relyra.Security.XML.C14N` is the hand-rolled exclusive-C14N 1.0 (no-comments) engine over the
`SaxyTree.Node` shape — the only net-new algorithm in Phase 28 (D-05: no correct exclusive-C14N BEAM
library exists; `esaml`/`xmerl_c14n` is inclusive-only and carries CVE-2026-28809 XXE). It serializes
a node to byte-exact canonical UTF-8 and applies a signed Reference's transform chain. This is the
canonical-bytes precondition for Phase 29's `:public_key.verify` + `DigestValue` recompute (SIGV-03);
byte-for-byte correctness against an independent oracle is PROVEN in Plan 04, not self-asserted here.
Compiles under `parser_path_guard`; **30/30 c14n tests green**, `--warnings-as-errors` clean.

## What Was Built

### Task 1 — Exclusive-C14N serialization core (RED `9a43e23` / GREEN `b666926`)
`serialize/2` over a `SaxyTree.Node`: visibly-utilized namespace rendering against a
*rendered*-namespaces stack distinct from the *in-scope* stack (no over-render, Pitfall 1); default-ns
handling with `xmlns=""` undeclaration emitted only when needed (Pitfall 2); namespace nodes sorted by
local name (default `""` least) and attributes by RESOLVED namespace-URI then local name (no-namespace
attrs first, Pitfall 8); two distinct escaping functions with the exact W3C char sets (text: `& < >`
`#xD`; attribute: `& < "` `#x9`/`#xA`/`#xD`); empty-element expansion to start+end tag pairs; no
trailing newline; UTF-8 output. Fail-closed `:canonicalization_failed` on an incomplete/non-bindable
node (Pitfall 9; atom reused, none invented).

### Task 2 — Transform chain: enveloped-sig prune + PrefixList forced render + allowlist (RED `4297274` / GREEN `ae9f16f`)
`canonicalize_reference/4` applies a Reference's ordered transform chain, then serializes:
- **enveloped-signature** (`http://www.w3.org/2000/09/xmldsig#enveloped-signature`): prunes the
  SPECIFIC `ds:Signature` subtree supplied as the 3rd argument (value-equal match), leaving an
  unrelated sibling `ds:Signature` intact — anti-XSW (D-10). `nil` / a bare exc-c14n chain = no prune.
- **exclusive-C14N** (`http://www.w3.org/2001/10/xml-exc-c14n#`): runs the Task-1 serializer.
- **transform allowlist** (T-28-05): any URI outside the two above (XSLT, XPath/xmldsig-filter2,
  inclusive C14N) is rejected fail-closed with `:canonicalization_failed`.
- **`:prefix_list`** from `InclusiveNamespaces/@PrefixList` (and `#default`) is threaded into
  `serialize/2` and force-rendered on the apex, bypassing the visibly-utilized test (Pitfall 7);
  prefixes NOT in the list still follow the visibly-utilized rule.

`transform_uris/1` reads `Algorithm` URIs from a `ds:Transforms` node's `ds:Transform` children in
document order. `prefix_list_from_transforms/1` reads the whitespace-separated
`InclusiveNamespaces/@PrefixList`, or `[]` when absent.

## Public API (CONTRACT for Plan 03 — wire `canonicalize/2` to these)

```elixir
# Serialize a node to canonical exclusive-C14N 1.0 bytes.
@spec serialize(term(), [opt()]) :: {:ok, binary()} | {:error, Relyra.Error.t()}
# opt() :: {:prefix_list, [String.t()]}   # "#default" allowed; force-renders on the apex

# Apply a Reference's transform chain (enveloped-sig prune + exc-c14n) then serialize.
@spec canonicalize_reference(
        referenced_node :: term(),          # SaxyTree.Node | else -> fail-closed
        transform_uris :: [String.t()],     # ordered Algorithm URIs; allowlist-gated
        signature_subtree :: Node.t() | nil,# the SPECIFIC ds:Signature to prune (nil = none)
        opts :: [opt()]                     # :prefix_list
      ) :: {:ok, binary()} | {:error, Relyra.Error.t()}

# Read transforms from a ds:Transforms parse-tree node.
@spec transform_uris(term()) :: [String.t()]
@spec prefix_list_from_transforms(term()) :: [String.t()]
```

Plan 03 should: read the Reference's `ds:Transforms` node, call `transform_uris/1` +
`prefix_list_from_transforms/1`, resolve the bound `ds:Signature` node, and call
`canonicalize_reference/4` (passing `prefix_list:` in `opts`). For a non-Reference apex (e.g. the bare
`SignedInfo` canonicalization), call `serialize/2` directly.

## Verification

- `mix compile --warnings-as-errors` — clean. Engine stays under the `parser_path_guard` allowed root
  `lib/relyra/security/xml/`; references no `Saxy` (pure transform over the already-built tree).
- `mix test test/relyra/security/xml/c14n_test.exs test/relyra/security/xml/c14n_transform_test.exs --warnings-as-errors`
  — **30 tests, 0 failures** (18 core + 12 transform).
- Core suite covers: no-over-render (Pitfall 1), default-ns + `xmlns=""` (Pitfall 2), sort-by-resolved-URI
  (Pitfall 8), both escaping functions (exact char sets), empty-element expansion,
  no-trailing-newline + UTF-8 (Pitfalls 4/6), idempotence (L5), fail-closed (Pitfall 9).
- Transform suite covers: prune the specific Signature (sibling survives), chain ordering, bare
  exc-c14n no-prune, XSLT + filter2 rejection (T-28-05), `transform_uris/1` /
  `prefix_list_from_transforms/1` reads, PrefixList forced render incl. `#default` (Pitfall 7),
  fail-closed on a non-Node referenced value.
- No new error atom; `:canonicalization_failed` reused for incomplete nodes AND rejected transforms.

## TDD Gate Compliance

Both tasks are `tdd="true"`; the RED/GREEN sequence is present in git history:
- Task 1 — RED `9a43e23` (`test(28-02): add failing tests for exclusive C14N serialization core`) →
  GREEN `b666926` (`feat(28-02): implement exclusive C14N 1.0 serialization core`).
- Task 2 — RED `4297274` (`test(28-02): add failing tests for enveloped-sig transform + PrefixList + allowlist`,
  12 `UndefinedFunctionError` failures, the expected RED) →
  GREEN `ae9f16f` (`feat(28-02): enveloped-sig transform pruning + PrefixList forced render + transform allowlist`).
- REFACTOR: none required; GREEN was clean.

> Note: the Task-2 RED test was authored in the prior session but its commit was interrupted by a host
> freeze before it landed. It was committed unchanged (`4297274`) on resume, preserving the RED→GREEN
> ordering, then the implementation followed.

## Deviations from Plan

### Resolved during execution
- **Allowlist scope tightened to exactly {enveloped-signature, exc-c14n}.** The plan suggested
  "plus the bare canonicalization variants you intend to support." Since this engine implements
  *exclusive* C14N only, allowlisting *inclusive* C14N (or exc-c14n#WithComments) would let a Reference
  request an algorithm we don't actually compute → wrong bytes → silent verification bypass. Kept the
  allowlist to the two transforms we genuinely implement (aligns with threat T-28-05).

### Out-of-scope items left untouched
- Pre-existing uncommitted working-tree edits to `mix.exs`, `README.md`, `guides/getting_started.md`,
  and untracked `docs/jtbd_gap_map.md`, `guides/jtbd_user_flows.md` were present before this plan
  (carried from before Phase 28) and are unrelated — left unstaged. Every commit in this plan was
  scoped to named c14n files only.

## Known Stubs

None. `serialize/2` and `canonicalize_reference/4` are fully wired and exercised end-to-end against
real parsed XML. The byte-for-byte proof against the independent oracle is deferred to Plan 04 by
design (this plan self-checks via idempotence + structural per-pitfall assertions).

## Self-Check: PASSED

- FOUND: lib/relyra/security/xml/c14n.ex (serialize/2, canonicalize_reference/4, transform_uris/1, prefix_list_from_transforms/1)
- FOUND: test/relyra/security/xml/c14n_test.exs
- FOUND: test/relyra/security/xml/c14n_transform_test.exs
- FOUND commit: 9a43e23 (Task 1 RED) / b666926 (Task 1 GREEN)
- FOUND commit: 4297274 (Task 2 RED) / ae9f16f (Task 2 GREEN)
- 30/30 c14n tests green; `mix compile --warnings-as-errors` clean.
- No new atom in the xml_error_type union; `:canonicalization_failed` reused.
