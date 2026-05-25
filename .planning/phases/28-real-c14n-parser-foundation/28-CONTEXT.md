# Phase 28: Real C14N parser foundation - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a `saxy`-backed real parse tree **and correct exclusive XML canonicalization (C14N 1.0 exclusive, `http://www.w3.org/2001/10/xml-exc-c14n#`)** behind the **existing** `Relyra.Security.XML` seam, replacing the regex string-scanning in `lib/relyra/security/xml/pure_beam.ex` — while preserving callback compatibility, the flat `parsed_doc` contract, and every hardened guard (DOCTYPE/ENTITY/size/document-`KeyInfo`/duplicate-ID/single-signed-node).

**Requirement:** SIGV-03.

**Goal (from ROADMAP):** verification can operate over a correct, canonicalized parse tree — the precondition for any cryptographic check.

**Explicitly OUT of scope (this is Phase 29):** wiring `:public_key.verify`, `DigestValue` recompute/compare, or any cryptographic check into `do_verify`. Phase 28 makes the parse tree and `canonicalize/2` real and correct; it does **not** verify signatures. Crypto verify = Phase 29; adversarial corpus + real FakeIdP signing = Phase 30; disclosure = Phase 31.

**Governing decision (locked):** ADR-0001 — pure-BEAM single `saxy` parser behind the seam. The hybrid+xmlsec NIF (GATE-03 matrix) is a *conditional rollback* triggered only if pure-BEAM correctness gates cannot be met — NOT a planned path for this phase.
</domain>

<decisions>
## Implementation Decisions

### Parser substrate & namespace context

- **D-01:** Parse with a **custom `Saxy.Handler` (SAX streaming)**, NOT `Saxy.SimpleForm`. Build a parse tree where each element node carries: its verbatim qualified name, its raw attributes in document order, and a **computed in-scope namespace stack** inherited from ancestors. Rationale: exclusive C14N's "visibly utilized" rule needs ancestor namespace scope at every node; SimpleForm exposes `xmlns:*` only as attributes on the declaring node, which is insufficient for the standard SAML case (signed `<Assertion>` inheriting a namespace declared on `<Response>`). Research confirmed Saxy performs **zero** namespace resolution.

- **D-02:** Add **`saxy` as a non-optional runtime dependency** in `mix.exs` (it is currently absent from `mix.exs` and `mix.lock`). It is core trust code, not optional like `req`/`oban`. All `saxy` usage stays inside `lib/relyra/security/xml/` to satisfy the existing compile-time guard at `lib/mix/tasks/compile/parser_path_guard.ex` — place the new handler module under that allowed root.

- **D-03:** Relyra **owns three normalization layers Saxy does not provide**, applied before/within C14N: (1) the in-scope namespace stack (D-01); (2) **XML attribute-value whitespace normalization** (literal `#x9`/`#xA`/`#xD` per XML 1.0 §3.3.3); (3) **line-ending normalization** (`\r\n` and lone `\r` → `\n`). C14N presumes a normalized infoset and Saxy does none of these — this is the single biggest byte-divergence hazard.

- **D-04:** **Full parser replacement, one trust path.** Re-derive **all** downstream protocol fields (Issuer / Status / Destination / InResponseTo / NameID / NameID Format / Conditions times / Audience / Recipient / SessionIndex / Attributes / assertion_times) from the saxy parse tree in the same pass; retire the regex extractors entirely. Keeping regex for fields + saxy for C14N would reintroduce the exact parser-differential class this milestone exists to close (PROJECT pillar: "one hardened parser path, no parser differentials").

### Exclusive C14N engine

- **D-05:** **Hand-roll exclusive C14N 1.0 (no-comments variant)** on the saxy tree. No reusable BEAM option exists: `esaml`/`xmerl_c14n` is inclusive-C14N only, last released 2019, xmerl-DOM-based, and carries current **CVE-2026-28809 (XXE)**. Every trusted SAML stack delegates C14N to libxml2; on BEAM, building is the only path — and ADR-0001 already locks pure-BEAM-first.

- **D-06:** Implement the **full correctness surface** required for byte-exact exc-c14n:
  - **Namespace rendering:** visibly-utilized selection (a namespace node is emitted only if its prefix appears in the element's own qualified name or in an in-node-set attribute's name; default ns visibly utilized iff the element is unprefixed) AND not already emitted by an output ancestor with an identical binding; track a *rendered-namespaces* stack distinct from the *in-scope* stack.
  - **`InclusiveNamespaces/@PrefixList`:** prefixes listed (and `#default`) are forced-rendered as in inclusive C14N, bypassing the visibly-utilized test (ADFS and others emit these — ignoring causes digest mismatch). Parse the PrefixList from the `ds:Transform` parameters.
  - **Sort order:** namespace nodes before attribute nodes; namespaces sorted by local name (default ns sorts least); attributes sorted by **resolved namespace-URI** then local name (no-namespace attributes sort first) — resolve each attribute's URI via the namespace stack.
  - **Escaping (two functions):** text content → escape `&` `<` `>` and `#xD`→`&#xD;` (not `"`, not `#x9`/`#xA`); attribute values → escape `&` `<` `"` and `#x9`→`&#x9;`, `#xA`→`&#xA;`, `#xD`→`&#xD;` (not `>`, not `'`).
  - **Empty elements** expanded to start+end tag pairs; whitespace outside the document element discarded.
  - **No trailing newline** (output starts with `<`, ends with `>`).
  - **Transform chain:** apply **enveloped-signature transform** (`http://www.w3.org/2000/09/xmldsig#enveloped-signature`) — prune the *specific* `ds:Signature` subtree containing the Reference being processed — **then** exclusive-c14n. Read the actual transform URIs from `ds:Transforms`; reject unexpected transforms (e.g. XSLT/XPath) as a hardening measure.
  - **Defer** the `#WithComments` variant — no SAML corpus fixture exercises comments.

### Seam interface & backward-compat

- **D-07:** **Keep the `canonicalize/2` callback arity unchanged**; enrich the term that flows through it. `parse_safely/2` returns the existing flat `parsed_doc` map **plus** an attached parse tree + namespace context (e.g. a new additive key such as `:parse_tree`). The `select_signed_node/2` handle carries enough tree context to canonicalize both the **referenced node** (Phase 28) and **`SignedInfo`** (left available for Phase 29 — XMLDSig needs two canonicalizations). Do not change `@callback` arity: `seam_contract_test` asserts the exact callback set, and any future xmlsec-rollback adapter must implement the same contract.

- **D-08:** **Preserve the flat `parsed_doc` key contract additively** — do not restructure. Readers that must keep working: `Relyra.Security.Signature` (`:duplicate_ids`, `:key_info_trust`, `:signed_candidates` with `{xml_id, xpath, signed_xml, signature_method, digest_method}`, `:signature_method`, `:digest_method`), `Relyra.Protocol.ValidationPipeline` (the protocol field keys in D-04 + `:assertion_times`), and `Relyra.Metadata.AutoRefresh` (the metadata-root `signed_candidates` builder feeding `verify_metadata_root`). Attach the tree as a new key; never remove or rename the existing ones.

- **D-09:** **Preserve all hardened guards on the new parser** (DOCTYPE/ENTITY rejection, pre/post-decode size limits, document-`KeyInfo` rejection, duplicate-ID rejection, single-signed-node selection). The v1.0 corpus must stay green; no second parser path is introduced. The pre-parse byte guards (DOCTYPE/ENTITY/size) run before any saxy parse, consistent with the XXE-before-verify invariant.

- **D-10:** **Bind the verified node to the exact element canonicalized** (success criterion #4): the `SignedNode`/handle and the canonicalized bytes must derive from the *same* parse-tree node — no node/canonicalization differential between what is canonicalized and what is returned downstream.

### GATE-02 byte-fidelity proof

- **D-11:** **Add a positive byte-equality assertion** to GATE-02. Today GATE-02 only asserts the `parser_differential_and_c14n` fixtures *fail closed* (`{:error, :canonicalization_failed}`) — there is no byte comparison and no golden file in the repo. Phase 28 adds at least one golden-byte equality test proving `canonicalize/2` output matches an independent reference, while keeping the existing fail-closed assertions.

- **D-12:** **Golden bytes are minted out-of-band and committed**, not generated live in CI. Mint with **`lxml` (pinned, e.g. in a pinned container) cross-checked against `xmlsec1`**; commit the input XML, the exact canonical bytes (no trailing newline), and a `PROVENANCE` note recording tool + libxml2 versions, the exact command, and any `PrefixList`. No native toolchain dependency is added to the `mix ci.security` lane (keeps CI hermetic and pure-BEAM — the same reason the xmlsec NIF was rejected in ADR-0001). lxml's statically-linked libxml2 can differ from system libxml2, so pinning + the xmlsec1 cross-check is the provenance guard.

### Claude's Discretion

- Exact module names/layout under `lib/relyra/security/xml/` (e.g. a `Saxy` handler module + a C14N module), the internal parse-tree shape, and how the namespace/rendered stacks are represented — left to the planner/executor, provided D-01..D-12 hold.
- Number and selection of golden fixtures beyond the one required by success criterion #2 — at minimum one representative SAML assertion with an ancestor-declared namespace; more if useful for the 8 known divergence pitfalls.

### Folded Todos

None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

Internal (repo):
- `.planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md` — ADR-0001 (pure-BEAM single saxy parser; conditional hybrid+xmlsec rollback rule; one-parser-path decision rule).
- `.planning/REQUIREMENTS.md` — SIGV-03 wording + ASSUR/DISC boundaries.
- `.planning/ROADMAP.md` — Phase 28 success criteria + Phase 29/30/31 boundaries.
- `.planning/PROJECT.md` — XML security boundary invariants / one-parser-path pillar.
- `lib/relyra/security/xml.ex` — seam `@callback` contract (do NOT change arity).
- `lib/relyra/security/xml/pure_beam.ex` — the regex impl being replaced (current `canonicalize/2` is a passthrough).
- `lib/relyra/security/signature.ex` — `do_verify` and the flat `parsed_doc` keys it reads.
- `lib/relyra/security/signed_node.ex` — `SignedNode` struct shape to preserve.
- `lib/relyra/protocol/validation_pipeline.ex` — full parse→verify→bind pipeline; complete set of downstream `parsed_doc` field readers (backward-compat constraint).
- `lib/relyra/metadata/auto_refresh.ex` — metadata-root `signed_candidates` builder feeding `verify_metadata_root` (second canonicalization caller).
- `lib/mix/tasks/compile/parser_path_guard.ex` — compile-time guard confining `Saxy`/`SweetXml`/`xmerl` to `lib/relyra/security/xml/` (place the new handler under an allowed root).
- `test/security/xml/corpus_security_test.exs` — current GATE-02 implementation (extend with byte-equality, keep fail-closed).
- `priv/security_corpus.json` + `test/fixtures/security/xml/manifest.json` — corpus source of truth (inline XML; `test/fixtures/security/xml/parser_differential_and_c14n/` is currently empty).
- `CONFORMANCE.md` — `c14n-differential-001` row mapping.

External specs (authoritative for C14N correctness):
- W3C *Exclusive XML Canonicalization 1.0* — https://www.w3.org/TR/xml-exc-c14n/ (visibly-utilized rule, InclusiveNamespaces PrefixList).
- W3C *Canonical XML 1.0* — https://www.w3.org/TR/2001/REC-xml-c14n-20010315/ (sort order, escaping table, empty-element/whitespace rules).
- W3C *XML Signature Syntax and Processing* — https://www.w3.org/TR/xmldsig-core/ (§6.6.4 enveloped-signature transform).
- Saxy docs/source — https://hexdocs.pm/saxy , https://github.com/qcam/saxy (no namespace resolution; no attribute-value normalization; preserves attribute order + verbatim prefixes).
- C14N pitfalls reference — https://www.di-mgt.com.au/xmldsig-c14n.html (normalization, line-endings, no-trailing-newline, encoding).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Security.XML` seam (3 callbacks) — keep verbatim; only the implementation changes.
- Existing hardened guards in `pure_beam.ex` (DOCTYPE/ENTITY/size pre-parse checks; document-`KeyInfo`, duplicate-ID, single-signed-node selection) — port forward onto the saxy path, do not weaken.
- `SignedNode` struct + the flat `parsed_doc` contract — preserve as the stable downstream interface.
- `corpus_gate.ex` + `corpus_security_test.exs` GATE machinery — extend, don't rebuild.
- `parser_path_guard` compile-time guard — already enforces the single-parser-path invariant; new handler must live under its allowed root.

### Established Patterns
- One hardened parser path, no parser differentials (PROJECT pillar + ADR-0001 decision rule).
- Fixture/corpus-as-source-of-truth (`priv/security_corpus.json`, manifest) with provenance metadata.
- Typed `%Relyra.Error{}` failures via the `xml_error_type` union (reuse `:canonicalization_failed`, `:malformed_xml`, etc.).
- `mix ci.security` is pure-Elixir (tests + deps.audit/hex.audit/sobelow) — no native toolchain step; keep it that way.

### Integration Points
- `parse_safely/2` → `select_signed_node/2` → `canonicalize/2` pipeline consumed by `ValidationPipeline` (assertions) and `AutoRefresh` (metadata roots via `verify_metadata_root`).
- `Signature.do_verify/4` reads flat `parsed_doc` keys — must keep reading them unchanged (its crypto wiring is Phase 29).
- GATE-02 in `corpus_security_test.exs` — gains a positive byte-equality assertion against committed golden bytes.
</code_context>

<specifics>
## Specific Ideas

- Exclusive C14N **no-comments** variant only; `#WithComments` deferred (no corpus need).
- Golden-byte toolchain: `lxml` (`etree.tostring(method="c14n", exclusive=True, inclusive_ns_prefixes=[...])`) cross-checked with `xmlsec1` (`-x -n` / `--c14n-exc`); commit input + canonical bytes + PROVENANCE.
- The 8 documented byte-divergence pitfalls (namespace over-rendering, default-namespace handling, attribute-value normalization, trailing newline, line-ending normalization, encoding, PrefixList ignored, sorting by prefix instead of resolved URI) should become explicit golden/test assertions and a code-review checklist.
</specifics>

<deferred>
## Deferred Ideas

- **Real cryptographic signature verification** (`:public_key.verify` of canonicalized `SignedInfo`; `DigestValue` recompute/compare) — Phase 29 (SIGV-01/02/04).
- **FakeIdP real signing + adversarial corpus** (forged / tampered / wrong-key / digest-mismatch / c14n-differential REJECTED + positive control) — Phase 30 (ASSUR-01/02).
- **Disclosure / docs honesty / GHSA+CVE+CHANGELOG** — Phase 31 (DISC-01/02).
- **`#WithComments` exclusive C14N variant** — not needed by any current corpus fixture.
- **Hybrid+xmlsec NIF path (GATE-03 matrix)** — conditional rollback only if pure-BEAM correctness gates cannot be met; not a planned phase.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
