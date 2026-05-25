# Phase 28: Real C14N parser foundation - Research

**Researched:** 2026-05-23
**Domain:** XML SAX parsing (Saxy) + hand-rolled Exclusive XML Canonicalization 1.0 (`http://www.w3.org/2001/10/xml-exc-c14n#`) in pure BEAM, behind the `Relyra.Security.XML` seam
**Confidence:** HIGH (Saxy API, backward-compat surface, esaml/xmerl facts, toolchain) / MEDIUM-HIGH (exclusive-C14N algorithm details — W3C-cited, but byte-exactness must be proven by the golden gate, not by research)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Parse with a **custom `Saxy.Handler` (SAX streaming)**, NOT `Saxy.SimpleForm`. Build a parse tree where each element node carries: verbatim qualified name, raw attributes in document order, and a **computed in-scope namespace stack** inherited from ancestors. Rationale: exclusive C14N's "visibly utilized" rule needs ancestor namespace scope at every node; SimpleForm exposes `xmlns:*` only as attributes on the declaring node. Saxy performs **zero** namespace resolution.
- **D-02:** Add **`saxy` as a non-optional runtime dependency** in `mix.exs` (currently absent from `mix.exs` and `mix.lock`). All `saxy` usage stays inside `lib/relyra/security/xml/` to satisfy the compile-time guard; place the new handler module under that allowed root.
- **D-03:** Relyra **owns three normalization layers Saxy does not provide**: (1) in-scope namespace stack; (2) **XML attribute-value whitespace normalization** (literal `#x9`/`#xA`/`#xD` per XML 1.0 §3.3.3); (3) **line-ending normalization** (`\r\n` and lone `\r` → `\n`). C14N presumes a normalized infoset; Saxy does none of these — single biggest byte-divergence hazard.
- **D-04:** **Full parser replacement, one trust path.** Re-derive **all** downstream protocol fields (Issuer / Status / Destination / InResponseTo / NameID / NameID Format / Conditions times / Audience / Recipient / SessionIndex / Attributes / assertion_times) from the saxy parse tree in the same pass; retire the regex extractors entirely.
- **D-05:** **Hand-roll exclusive C14N 1.0 (no-comments variant)** on the saxy tree. No reusable BEAM option exists (`esaml`/`xmerl_c14n` is inclusive-C14N only, xmerl-DOM-based, carries CVE-2026-28809 XXE).
- **D-06:** Implement the **full correctness surface**: visibly-utilized namespace selection; rendered-vs-in-scope stacks; `InclusiveNamespaces/@PrefixList` forced rendering; sort order (namespaces by local name; attributes by **resolved namespace-URI** then local name); two escaping functions (text vs attribute, exact char sets); empty-element expansion; no trailing newline; enveloped-signature transform (prune the specific `ds:Signature` subtree); reject unexpected transforms. **Defer** the `#WithComments` variant.
- **D-07:** **Keep `canonicalize/2` callback arity unchanged**; enrich the flowing term. `parse_safely/2` returns the existing flat `parsed_doc` map **plus** an attached parse tree + namespace context (additive key, e.g. `:parse_tree`). The handle carries enough tree context to canonicalize both the **referenced node** (Phase 28) and **`SignedInfo`** (left available for Phase 29).
- **D-08:** **Preserve the flat `parsed_doc` key contract additively** — do not restructure or rename. Readers: `Signature`, `ValidationPipeline`, `AutoRefresh`. Attach the tree as a new key only.
- **D-09:** **Preserve all hardened guards on the new parser** (DOCTYPE/ENTITY rejection, pre/post-decode size limits, document-`KeyInfo` rejection, duplicate-ID rejection, single-signed-node selection). v1.0 corpus stays green; no second parser path. Pre-parse byte guards (DOCTYPE/ENTITY/size) run BEFORE any saxy parse (XXE-before-verify invariant).
- **D-10:** **Bind the verified node to the exact element canonicalized** — the handle and the canonicalized bytes derive from the *same* parse-tree node.
- **D-11:** **Add a positive byte-equality assertion** to GATE-02 while keeping the existing fail-closed assertions.
- **D-12:** **Golden bytes are minted out-of-band and committed**, not generated live in CI. Mint with **`lxml` (pinned)** cross-checked against **`xmlsec1`**; commit input XML + exact canonical bytes (no trailing newline) + a `PROVENANCE` note (tool + libxml2 versions, exact command, any `PrefixList`). No native toolchain in `mix ci.security`.

### Claude's Discretion
- Exact module names/layout under `lib/relyra/security/xml/` (Saxy handler module + C14N module), internal parse-tree shape, namespace/rendered stack representation — provided D-01..D-12 hold.
- Number/selection of golden fixtures beyond the one required by success criterion #2 — at minimum one representative SAML assertion with an ancestor-declared namespace; more if useful for the 8 divergence pitfalls.

### Deferred Ideas (OUT OF SCOPE)
- Real cryptographic signature verification (`:public_key.verify` of canonicalized `SignedInfo`; `DigestValue` recompute/compare) — **Phase 29** (SIGV-01/02/04).
- FakeIdP real signing + adversarial corpus — **Phase 30** (ASSUR-01/02).
- Disclosure / GHSA + CVE + CHANGELOG — **Phase 31** (DISC-01/02).
- `#WithComments` exclusive C14N variant — not needed by any current corpus fixture.
- Hybrid+xmlsec NIF path (GATE-03 matrix) — conditional rollback only; not a planned path.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGV-03 | Verification uses correct **exclusive XML canonicalization (C14N 1.0 exclusive)** over a real parse tree behind the `Relyra.Security.XML` seam (the `saxy`-backed path ADR-0001 specified), with no parser/canonicalization differentials and the verified signature bound to the exact node consumed. | Saxy SAX handler design (Standard Stack + Pattern 1); exclusive-C14N algorithm surface (Architecture Patterns + Common Pitfalls); namespace-stack/attribute-normalization/line-ending layers (D-03, Pattern 2); golden-byte gate proving byte-equality (Validation Architecture); node-binding via single parse-tree node (Pattern 4). All four ROADMAP success criteria mapped to research findings below. |
</phase_requirements>

---

## Summary

Phase 28 replaces the regex string-scanner in `lib/relyra/security/xml/pure_beam.ex` with a real `saxy`-backed parse tree and a hand-rolled, byte-exact **exclusive XML canonicalization 1.0 (no-comments)** engine, all behind the unchanged 3-callback `Relyra.Security.XML` seam. It is security-critical: this phase produces no cryptographic check (that is Phase 29), but it builds the canonical-bytes precondition on which Phase 29's `:public_key.verify` and `DigestValue` recompute will stand. A byte-divergence here silently breaks digest comparison downstream and re-opens the confirmed auth-bypass class — so correctness, proven by an independent reference oracle, is the entire deliverable.

The substrate is settled by CONTEXT.md and verified here: **`saxy` 1.6.0** is the current stable Hex release (Oct 2024, MIT, 8.5M downloads, `github.com/qcam/saxy`), and its SAX `handle_event/3` interface delivers `:start_element` as `{name, attributes}` where `name` is the **verbatim** qualified string and `attributes` is a `[{name, value}]` list in **document order** — with **zero namespace resolution, zero attribute-value normalization, and zero line-ending normalization** (confirmed: namespace handling is not mentioned anywhere in `Saxy.Handler`). That confirms D-01 and D-03: the three normalization layers (in-scope namespace stack, attribute-value whitespace normalization per XML 1.0 §3.3.3, line-ending normalization) are Relyra's responsibility, applied before/within C14N. These three layers plus the eight documented exc-C14N byte-divergence pitfalls are the highest-risk surface of the phase.

The exclusive-C14N engine must be hand-rolled (D-05): the only BEAM C14N option, `esaml`/`xmerl_c14n`, is inclusive-C14N only, xmerl-DOM-based, and carries **CVE-2026-28809 (XXE, CWE-611, all esaml versions)** — verified via the Erlang Ecosystem Foundation CNA. The backward-compat surface is fully enumerated below: the `parsed_doc` flat-map keys read by `Signature.do_verify`, `ValidationPipeline`, and `AutoRefresh.verify_metadata_root` must be preserved additively; the parse tree is attached as a new key (`:parse_tree`). One sharp implementation note surfaced during code inspection: **GATE-02 today calls `PureBeam.canonicalize(parsed_doc, [])` directly with the `parsed_doc` map**, which falls through to the `:canonicalization_failed` fallback clause — that is *why* the c14n fixtures currently "fail closed." The planner must preserve that fail-closed behavior for incomplete inputs while adding the positive byte-equality path.

**Primary recommendation:** Add `{:saxy, "~> 1.6"}` as a non-optional dep; build a `Saxy.Handler`-based tree builder + a separate exclusive-C14N module both under `lib/relyra/security/xml/`; implement the three normalization layers and the full exc-C14N surface exactly per the W3C specs; prove correctness with at least one committed golden-byte fixture (SAML assertion with an ancestor-declared namespace) minted by pinned `lxml` cross-checked with `xmlsec1`, asserted byte-for-byte in an extended GATE-02 — while keeping every existing guard and fail-closed assertion green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pre-parse byte guards (DOCTYPE/ENTITY/size) | Security seam (`PureBeam.parse_safely`, pre-Saxy) | — | XXE-before-verify invariant (PROJECT.md, D-09): dangerous bytes must be rejected *before* any parse, including before Saxy. Stays a raw-`binary()` `String.contains?`/`byte_size` check. |
| SAX tokenization | Saxy library (inside seam) | — | Saxy owns well-formedness + tokenization only; it does NOT resolve namespaces or normalize values. |
| In-scope namespace stack | Relyra C14N/handler module | — | Saxy provides none (D-01/D-03). Built during the SAX walk by inheriting ancestor `xmlns`/`xmlns:*` declarations. |
| Attribute-value + line-ending normalization | Relyra C14N module | — | XML 1.0 §3.3.3 + §2.11; Saxy does neither (D-03). Must be applied to make the infoset canonical. |
| Exclusive C14N serialization | Relyra C14N module (hand-rolled) | — | No correct reusable BEAM option (D-05); esaml is inclusive-only + CVE. |
| Protocol-field extraction (Issuer/Status/NameID/…) | Relyra tree-derivation (inside seam) | — | D-04: derive from the *same* saxy tree, one trust path, no regex differential. |
| Signed-node selection + binding | Relyra seam (`select_signed_node`) | — | D-10: handle + canonical bytes from the *same* tree node. |
| Golden-byte minting (oracle) | Out-of-band toolchain (lxml + xmlsec1) | — | D-12: native toolchain never enters CI; bytes committed + provenance recorded. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `saxy` | `~> 1.6` (latest 1.6.0, 2024-10-22) | SAX streaming XML parser; tokenizes SAML XML into `:start_element`/`:characters`/`:end_element` events for tree construction | [CITED: hex.pm/api/packages/saxy] The ADR-0001-mandated pure-BEAM parser; 8.5M downloads; MIT; actively the dominant Elixir SAX parser. Verbatim names + ordered attributes + no hidden normalization make it the right substrate for byte-exact C14N. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:public_key` (OTP) | OTP 28 (in tree) | RSA/ECDSA verify, cert parsing | **Phase 29** only — out of scope here. Noted so the planner does NOT pull it into Phase 28 tasks. |
| `:crypto` (OTP) | OTP 28 (in tree) | SHA-256 digest | **Phase 29** only (DigestValue). Out of scope here. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled exc-C14N | `esaml`/`xmerl_c14n` | **Rejected (D-05).** Inclusive C14N only (no exclusive); xmerl-DOM based (not the saxy path → reintroduces parser differential); carries **CVE-2026-28809 XXE** [VERIFIED: cna.erlef.org/cves/CVE-2026-28809.html]. Violates one-parser-path pillar. |
| Custom `Saxy.Handler` | `Saxy.SimpleForm` | **Rejected (D-01).** SimpleForm exposes `xmlns:*` only as attributes on the *declaring* node — insufficient for the visibly-utilized rule when a signed `<Assertion>` inherits a namespace declared on `<Response>`. Custom handler lets Relyra build the in-scope stack during the walk. |
| `saxy` (SAX) | `sweet_xml` / `xmerl` DOM | **Rejected.** `parser_path_guard` already blocks `SweetXml`/`xmerl` outside the seam; xmerl is the CVE-carrying DOM path; DOM hides the verbatim ordering C14N needs. |
| Hybrid+xmlsec NIF | — | **Conditional rollback only** (ADR-0001 GATE-03). Not a Phase 28 path. |

**Installation:**
```bash
# add to deps/0 in mix.exs (NON-optional — it is core trust code, not optional like req/oban):
#   {:saxy, "~> 1.6"}
mix deps.get
```

**Version verification:** `saxy` latest stable is **1.6.0**, published **2024-10-22**, MIT, repo `github.com/qcam/saxy` [CITED: hex.pm/api/packages/saxy]. Pin `~> 1.6`. Run `mix hex.info saxy` at plan/exec time to re-confirm before writing `mix.lock`.

## Package Legitimacy Audit

> slopcheck and ctx7 were **unavailable** in this research environment (pip install failed; no `ctx7` binary). Per the Package Legitimacy Gate graceful-degradation rule, the package below is tagged `[ASSUMED]` and the planner MUST gate its install behind a `checkpoint:human-verify` task. Mitigating evidence (downloads/age/source repo) is recorded.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `saxy` | Hex | First released ~2017; latest 1.6.0 2024-10-22 | 8,548,165 all-time | github.com/qcam/saxy (MIT) | unavailable → `[ASSUMED]` | Approved-pending-checkpoint |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none (slopcheck unavailable; mitigated by 8.5M downloads + 7-year age + public MIT source repo — strong legitimacy signals, but formal tag remains `[ASSUMED]`)

*Because slopcheck was unavailable, the planner must add a `checkpoint:human-verify` task confirming `{:saxy, "~> 1.6"}` resolves to `github.com/qcam/saxy` (sha in `mix.lock`) before `mix deps.get` is run on a trust-path dependency.*

## Architecture Patterns

### System Architecture Diagram

```
                          raw SAML XML (binary)
                                   │
                                   ▼
                ┌──────────────────────────────────────┐
                │  parse_safely/2  (seam entry)         │
                │  PRE-PARSE BYTE GUARDS (D-09)         │  ◄── run on raw binary, BEFORE Saxy
                │   • byte_size > max_bytes?            │      (XXE-before-verify invariant)
                │   • "<!DOCTYPE" present?              │
                │   • "<!ENTITY" present?               │
                └──────────────┬───────────────────────┘
                  reject ◄──────┤ (typed Error)
                                ▼ ok
                ┌──────────────────────────────────────┐
                │  Saxy.parse_string + custom Handler   │
                │  events: start_doc / start_element /  │
                │  characters / cdata / end_element /   │
                │  end_document                         │
                └──────────────┬───────────────────────┘
                               ▼
                ┌──────────────────────────────────────┐
                │  TREE BUILDER (Relyra)                │
                │  per element node:                    │
                │   • verbatim qname                    │
                │   • raw attrs in doc order            │
                │   • IN-SCOPE NS STACK (inherited)     │  ◄── Relyra-owned layer #1 (D-03)
                │   • normalized attr values (§3.3.3)   │  ◄── Relyra-owned layer #2
                │   • normalized text (\r\n,\r → \n)    │  ◄── Relyra-owned layer #3
                └──────────────┬───────────────────────┘
                               ▼
              ┌────────────────┴─────────────────┐
              ▼                                   ▼
   ┌────────────────────┐          ┌──────────────────────────────┐
   │ TREE DERIVATION     │          │  parsed_doc flat map (D-08)   │
   │ Issuer/Status/NameID│  ──────► │  + duplicate_ids/key_info/    │
   │ /times/audiences/…  │          │    signed_candidates/methods  │
   └────────────────────┘          │  + :parse_tree  (NEW key, D-07)│
                                    └───────────────┬──────────────┘
                                                    ▼
                ┌──────────────────────────────────────┐
                │  select_signed_node/2                  │
                │   • key_info_trust? reject (D-09)     │
                │   • duplicate_ids? reject (D-09)       │
                │   • exactly one candidate? (D-09)      │
                │   • handle carries tree node (D-10)    │
                └──────────────┬───────────────────────┘
                               ▼
                ┌──────────────────────────────────────┐
                │  canonicalize/2  (EXCLUSIVE C14N 1.0) │
                │  on the SAME tree node (D-10):        │
                │   1. apply enveloped-sig transform    │  ◄── prune the specific ds:Signature subtree
                │   2. exclusive C14N serialize:        │
                │      • visibly-utilized ns selection  │
                │      • rendered-vs-in-scope stacks     │
                │      • PrefixList forced render        │
                │      • sort ns(local) / attr(uri,local)│
                │      • text-escape vs attr-escape      │
                │      • empty-elem expansion            │
                │      • NO trailing newline             │
                └──────────────┬───────────────────────┘
                               ▼
                       canonical bytes (binary)
              ┌─────────────────┴──────────────────┐
              ▼                                     ▼
   GATE-02 byte-equality vs golden        Phase 29 (out of scope):
   (D-11) + fail-closed for               digest recompute + SignedInfo
   incomplete inputs                      :public_key.verify
```

### Recommended Project Structure
```
lib/relyra/security/xml/
├── pure_beam.ex            # the seam adapter — keeps the 3 @impl callbacks; orchestrates the below
├── saxy_tree.ex            # NEW: Saxy.Handler — builds the parse tree + in-scope ns stack (allowed root)
├── c14n.ex                 # NEW: exclusive C14N 1.0 engine (serialize, sort, escape, transforms)
├── tree.ex                 # NEW (optional): tree node struct + protocol-field derivation helpers
└── corpus_gate.ex          # existing — unchanged

test/fixtures/security/xml/parser_differential_and_c14n/   # currently EMPTY — golden fixtures land here
├── assertion_inherited_ns.input.xml      # NEW: SAML assertion w/ ancestor-declared ns
├── assertion_inherited_ns.c14n           # NEW: exact canonical bytes (no trailing newline)
└── PROVENANCE.md                         # NEW: tool + libxml2 versions, exact cmd, PrefixList (D-12)
```
> All three new modules MUST live under `lib/relyra/security/xml/` so `parser_path_guard` (which scans for `\bSaxy\b`/`\bSweetXml\b`/`\bxmerl\b` outside the allowed roots) does not fail compile. [VERIFIED: lib/mix/tasks/compile/parser_path_guard.ex — `@allowed_roots` includes `"lib/relyra/security/xml/"`.]

### Pattern 1: Saxy SAX handler building a tree + in-scope namespace stack
**What:** A `Saxy.Handler` that maintains a stack of open elements. On `:start_element`, push a node carrying (a) the verbatim qname, (b) raw attributes in document order, and (c) the in-scope namespace map = parent's map merged with this element's own `xmlns`/`xmlns:prefix` attributes. On `:characters`/`:cdata`, append normalized text to the current node. On `:end_element`, pop and attach to parent.
**When to use:** Always — this is the only parse path (D-01, D-04).
**Example:**
```elixir
# Source: API shape per https://hexdocs.pm/saxy/Saxy.Handler.html
#   handle_event(event_type, data, user_state) :: {:ok, state} | {:stop, ret} | {:halt, ret}
#   :start_element data = {name :: String.t(), attributes :: [{String.t(), String.t()}]}
#   names are VERBATIM (prefix preserved); attrs in DOCUMENT ORDER; Saxy does NO ns resolution.
defmodule Relyra.Security.XML.SaxyTree do
  @behaviour Saxy.Handler

  @impl true
  def handle_event(:start_document, _prolog, state), do: {:ok, state}

  def handle_event(:start_element, {qname, attrs}, %{stack: stack} = state) do
    parent_ns = case stack do [%{ns: ns} | _] -> ns; [] -> %{} end
    own_ns = ns_decls_from_attrs(attrs)                 # {"" => uri} for xmlns=, {"ds" => uri} for xmlns:ds=
    node = %{
      qname: qname,
      attrs: Enum.map(attrs, fn {k, v} -> {k, normalize_attr_value(v)} end),  # Relyra layer #2
      ns: Map.merge(parent_ns, own_ns),                 # in-scope stack (Relyra layer #1)
      children: []
    }
    {:ok, %{state | stack: [node | stack]}}
  end

  def handle_event(:characters, text, state),
    do: {:ok, append_text(state, normalize_text(text))}  # Relyra layer #3 (\r\n,\r -> \n)

  def handle_event(:cdata, text, state),
    do: {:ok, append_text(state, normalize_text(text))}  # CDATA content is escaped like text in C14N

  def handle_event(:end_element, _qname, state), do: {:ok, pop_into_parent(state)}
  def handle_event(:end_document, _data, state), do: {:ok, finalize(state)}
end
```
> **CRITICAL on names:** Saxy returns the qname as the literal source string (e.g. `"ds:Signature"`, `"Assertion"`). It does NOT split prefix from local part and does NOT resolve to a URI. Relyra must split on `:` to derive prefix/local, and resolve prefix→URI via the in-scope stack for attribute sorting (Pitfall 8).

### Pattern 2: The three Relyra-owned normalization layers (D-03) — exactly when each applies
**What:** C14N presumes a normalized infoset. Saxy provides none of these. Apply them at tree-build time so the tree is canonical-ready.
**When to use:** Always, but at distinct points:

| Layer | Spec basis | Applies to | Transformation |
|-------|-----------|------------|----------------|
| (1) In-scope namespace stack | XML Namespaces; exc-C14N visibly-utilized rule | every element | inherit parent's ns map; overlay this element's `xmlns`/`xmlns:*` |
| (2) Attribute-value normalization | XML 1.0 §3.3.3 | **attribute values only** | each literal `#x9` (tab), `#xA` (LF), `#xD` (CR) in the value → a single space `#x20`. (For CDATA-type attrs — SAML has no DTD, so all attrs are CDATA-type → this is the rule that applies.) **Note:** this is the *infoset* normalization that happens to attr values; it is distinct from the C14N *escaping* of attr values done at serialize time. |
| (3) Line-ending normalization | XML 1.0 §2.11 | **all parsed text + the whole document** | `\r\n` → `\n` and lone `\r` → `\n`, before any other processing |
**Anti-pattern:** Applying attribute-value normalization (layer 2) to *text content* — text content is NOT whitespace-normalized in C14N (only escaped). Conversely, applying C14N escaping (`&#x9;` etc.) at tree-build time instead of serialize time. Keep infoset-normalization (build time) and C14N-escaping (serialize time) strictly separate.

### Pattern 3: Exclusive C14N namespace rendering — rendered-vs-in-scope stacks
**What:** Exclusive C14N renders a namespace node on an element **only if** (a) it is "visibly utilized" by that element — its prefix appears in the element's own qname or in one of the element's in-node-set attribute names (default ns is visibly utilized iff the element itself is unprefixed) — **and** (b) it is not already rendered with an identical binding by an output ancestor; **OR** (c) the prefix is in the `InclusiveNamespaces/@PrefixList` (forced render, inclusive-style). This requires tracking a **rendered-namespaces** stack (what output ancestors have actually emitted) that is *distinct* from the **in-scope** stack (everything declared by ancestors).
**When to use:** Every element during serialize.
**Example (algorithm sketch, NOT verbatim source):**
```
# Source: https://www.w3.org/TR/xml-exc-c14n/ §2 (visibly utilized + output ancestor)
render_namespaces(node, in_scope, rendered_by_ancestors, prefix_list):
  utilized = prefixes_used_by(node.qname) ∪ prefixes_used_by(node.attrs_in_nodeset)
  forced   = prefix_list                       # +"#default" handling
  candidates = utilized ∪ forced
  to_render = for prefix in candidates:
    uri = in_scope[prefix]
    keep if rendered_by_ancestors[prefix] != uri   # not already output with same binding
  emit to_render sorted by local name (default ns "" sorts least)
  return rendered_by_ancestors updated with to_render
```
> Default namespace subtlety: if an element is *unprefixed* it visibly utilizes the default ns; if it is prefixed it does NOT (Pitfall 2). An empty default-ns declaration (`xmlns=""`) is rendered only when needed to "undeclare" an inherited default in output — handle the empty-URI case explicitly.

### Pattern 4: Node binding — same tree node for handle and canonical bytes (D-10)
**What:** `select_signed_node/2` returns a handle that references the *exact* parse-tree node (not a re-found node, not a re-parsed substring). `canonicalize/2` canonicalizes *that same node object*. There must be no path where the bytes canonicalized differ from the node bound into the returned `SignedNode`.
**When to use:** Always — this is success criterion #4 and the anti-wrapping invariant.
**Anti-pattern:** The current regex impl re-extracts `signed_xml` as a *string slice* (`"<Assertion#{attrs}>#{inner}</Assertion>"`) separate from any tree — that string-vs-node duality is exactly the differential to eliminate. In the saxy path, carry the node reference through the handle so canonicalization and binding share one source of truth.

### Anti-Patterns to Avoid
- **Two parser paths** (saxy for C14N, regex for fields) — reintroduces the differential class this milestone closes (D-04, PROJECT pillar). Derive everything from the one tree.
- **Sorting attributes by prefix** instead of by **resolved namespace URI** then local name (Pitfall 8) — a top byte-divergence cause.
- **Emitting a trailing newline** — exc-C14N output starts with `<` and ends with `>`, no trailing `\n` (Pitfall 4). Note the current `normalize_signed_xml/1` calls `String.trim/1` which would also strip *leading/internal* significance — do NOT carry that helper forward into real C14N.
- **Running Saxy before the byte guards** — DOCTYPE/ENTITY/size must reject on the raw binary first (D-09, XXE-before-verify).
- **Treating `String.contains?("<!DOCTYPE")` as sufficient post-Saxy** — keep it pre-parse; do not rely on Saxy to reject DTDs (verify Saxy's DTD behavior, but the guard is the contract).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| XML tokenization / well-formedness | A custom XML lexer | `saxy` SAX events | Edge cases (CDATA, char refs, comments, PIs, attribute quoting, encoding) are a minefield; Saxy is XML-1.0-5e compliant and battle-tested. |
| RSA/ECDSA verify, SHA-256 (Phase 29) | Custom crypto | OTP `:public_key` / `:crypto` | Out of scope here, but flagged so the planner does not pre-build it. |
| Golden canonical bytes (the oracle) | An Elixir "reference" C14N | `lxml` + `xmlsec1` out-of-band | The whole point of GATE-02 is an *independent* oracle; generating goldens with your own engine proves nothing. |

**Key insight — what you MUST hand-roll anyway:** exclusive C14N itself (D-05). There is no correct, safe, exclusive-C14N BEAM library. `esaml`/`xmerl_c14n` is inclusive-only, DOM-based, and carries **CVE-2026-28809** [VERIFIED: cna.erlef.org/cves/CVE-2026-28809.html]. So this phase is the rare case where hand-rolling is the *correct* call — which is exactly why the golden-byte differential gate (D-11/D-12) is non-negotiable: it is the only thing standing between a hand-rolled algorithm and a silent byte-divergence that re-opens the bypass.

## Runtime State Inventory

> This is a code-replacement phase (regex → saxy parse tree) within one repo, not a rename/migration. No external runtime state stores the changed strings. Inventory completed for completeness:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore keys/collections change; SAML XML is transient request data, not persisted by this seam. | none |
| Live service config | None — no external service config references the seam internals. | none |
| OS-registered state | None — no OS-level registrations. | none |
| Secrets/env vars | None — the seam reads no secrets/env var names; `max_bytes` is an opt, not env. | none |
| Build artifacts | **New dep `saxy`** lands in `mix.lock`; `_build/` recompiles. After adding the dep, `mix deps.get` + clean compile required. The `parser_path_guard` custom compiler runs on every `mix compile` — new modules must compile-pass the guard. | `mix deps.get`; ensure new modules under allowed root before first compile. |

**Nothing found in categories 1-4** — verified by: this phase touches only `lib/relyra/security/xml/` modules + test fixtures + `mix.exs`/`mix.lock`; the `parsed_doc` contract is preserved additively (D-08), so no downstream stored shape changes.

## Common Pitfalls

> The 8 documented exclusive-C14N byte-divergence pitfalls (CONTEXT.md "Specific Ideas"). Each is a silent-failure class: wrong bytes → wrong digest in Phase 29 → bypass re-opens. Each must become a golden/test assertion AND a code-review checklist item. Pitfall rules cited from [CITED: w3.org/TR/xml-exc-c14n] and [CITED: w3.org/TR/2001/REC-xml-c14n-20010315] and [CITED: di-mgt.com.au/xmldsig-c14n.html].

### Pitfall 1: Namespace over-rendering
**What goes wrong:** Emitting a namespace declaration on a child element that an output ancestor already emitted with the same binding — bloats the canonical form, digest mismatch.
**Why it happens:** Tracking only the in-scope stack and not a separate *rendered* stack.
**How to avoid:** Maintain a distinct rendered-namespaces stack (Pattern 3); render a ns only if not already rendered with an identical binding by an output ancestor.
**Warning signs:** Canonical output has the same `xmlns:ds=...` on nested elements.
**Test:** golden fixture where a child inherits a ns already rendered on the apex.

### Pitfall 2: Default-namespace handling
**What goes wrong:** Rendering (or failing to render) the default namespace incorrectly; mishandling `xmlns=""` undeclaration.
**Why it happens:** Default ns is "visibly utilized" iff the element is *unprefixed*; prefixed elements do not utilize the default ns. Empty default-ns needs explicit undeclare logic.
**How to avoid:** Treat prefix `""` specially in the visibly-utilized test; emit `xmlns=""` only to override an inherited non-empty default in output.
**Warning signs:** A prefixed element wrongly carries `xmlns=...`; missing `xmlns=""` where an inherited default should be cleared.
**Test:** golden fixture mixing default-ns and prefixed elements.

### Pitfall 3: Attribute-value normalization (the §3.3.3 layer)
**What goes wrong:** Literal tab/newline/CR inside an attribute value not normalized to space → bytes differ from the oracle.
**Why it happens:** Saxy does not normalize attribute values (D-03 layer 2).
**How to avoid:** At tree build, replace `#x9`/`#xA`/`#xD` in attr values with a single `#x20` (CDATA-type attr rule; SAML is DTD-less so all attrs are CDATA-type). Keep this DISTINCT from C14N escape (which converts those same chars to `&#x9;` etc. — see Pitfall — escaping below).
**Warning signs:** Multi-line attribute values diverge.
**Test:** golden fixture with a tab/newline inside an attribute value.

### Pitfall 4: Trailing newline
**What goes wrong:** Output ends with `\n`; digest mismatch.
**Why it happens:** Naive serialize / `String.trim` habits / template `EOF` newline.
**How to avoid:** Canonical output starts with `<` ends with `>`; assert `not String.ends_with?(out, "\n")`. Mint golden bytes with no trailing newline (D-12).
**Warning signs:** Golden file has a trailing newline (editors add one — store bytes exactly).
**Test:** byte-length + last-byte assertion in GATE-02.

### Pitfall 5: Line-ending normalization
**What goes wrong:** `\r\n` or lone `\r` in input not normalized to `\n` before processing → divergence.
**Why it happens:** Saxy does not do XML 1.0 §2.11 line-ending normalization (D-03 layer 3).
**How to avoid:** Normalize `\r\n`→`\n` and `\r`→`\n` on input/text. (The current `normalize_signed_xml/1` already does the replace pair — keep that logic, drop the `String.trim`.)
**Warning signs:** CRLF-delimited fixtures diverge from LF goldens.
**Test:** golden fixture authored with CRLF line endings → canonical bytes use LF.

### Pitfall 6: Encoding
**What goes wrong:** Treating canonical output as anything but **UTF-8**; BOM handling; character-reference vs literal char mismatches.
**Why it happens:** C14N output is always UTF-8; numeric char refs in text are expanded to chars except the special-escapes.
**How to avoid:** Operate on UTF-8 binaries end-to-end; ensure goldens are committed as raw UTF-8 bytes (no BOM). Confirm Saxy decodes the source encoding to UTF-8 before tree build.
**Warning signs:** Non-ASCII (e.g. accented NameID) diverges.
**Test:** golden fixture with a non-ASCII character in element text.

### Pitfall 7: PrefixList (`InclusiveNamespaces/@PrefixList`) ignored
**What goes wrong:** ADFS and others emit `<ec:InclusiveNamespaces PrefixList="...">` inside the exc-c14n transform; ignoring it under-renders namespaces → digest mismatch against those IdPs.
**Why it happens:** Treating exclusive C14N as always-minimal; not parsing transform parameters.
**How to avoid:** Parse the `PrefixList` from the `ds:Transform` parameters; force-render listed prefixes (+`#default`) inclusive-style, bypassing the visibly-utilized test (D-06).
**Warning signs:** Works against Okta/Google, fails against ADFS.
**Test:** golden fixture minted WITH `inclusive_ns_prefixes=[...]` in lxml; record the PrefixList in PROVENANCE (D-12).

### Pitfall 8: Sorting by prefix instead of resolved URI
**What goes wrong:** Attributes sorted lexicographically by prefix string rather than by **resolved namespace URI then local name** → wrong order → digest mismatch.
**Why it happens:** Easy to sort on the visible attribute name; the spec requires resolving each attribute's prefix to its URI first. No-namespace attributes sort first.
**How to avoid:** For each attribute, resolve prefix→URI via the in-scope stack; sort key = `{uri_or_nil_first, local_name}`. Namespace nodes always precede attribute nodes; namespaces sort by local name (default ns least).
**Warning signs:** Two attrs with different prefixes pointing at different URIs come out in source order.
**Test:** golden fixture with multiple namespaced attributes whose prefix-order ≠ URI-order.

### Pitfall 9 (process, not byte): GATE-02 calling convention
**What goes wrong:** Today the GATE-02 test calls `PureBeam.canonicalize(parsed_doc, [])` passing the whole `parsed_doc` map; the current impl's typed `canonicalize/2` head only matches a flat signed-node handle map, so it falls through to the `:canonicalization_failed` fallback — which is *why* fixtures "fail closed." When `canonicalize/2` becomes real, the planner must preserve fail-closed for *incomplete/differential* inputs (the existing `c14n-00x` fixtures expect `canonicalization_failed`) while the NEW golden path proves byte-equality on a *complete* fixture.
**How to avoid:** Keep a guard clause that returns `:canonicalization_failed` for handles lacking a bindable tree node; only canonicalize when a complete node is present. Do NOT let a real engine accidentally *succeed* on the existing differential fixtures (they have a `<Reference>` to a node but no real signature material — they must still fail closed). [VERIFIED: test/security/xml/corpus_security_test.exs lines 36-60 + 123-126; lib/relyra/security/xml/pure_beam.ex lines 72-102.]

## Code Examples

### Adding the dependency (mix.exs)
```elixir
# Source: hex.pm/api/packages/saxy (latest 1.6.0). NON-optional — core trust code (D-02).
defp deps do
  [
    {:saxy, "~> 1.6"},
    # ...existing deps unchanged...
  ]
end
```

### Saxy parse entry (inside the seam, after byte guards)
```elixir
# Source: https://hexdocs.pm/saxy/Saxy.html — Saxy.parse_string/3
# Run ONLY after the pre-parse byte guards (DOCTYPE/ENTITY/size) have passed on the raw binary.
case Saxy.parse_string(xml, Relyra.Security.XML.SaxyTree, %{stack: [], root: nil}) do
  {:ok, %{root: root}} -> {:ok, build_parsed_doc(root, xml)}
  {:error, %Saxy.ParseError{} = err} ->
    {:error, Relyra.Error.new(:malformed_xml, "Malformed XML payload", %{reason: Saxy.ParseError.message(err)})}
end
```

### lxml golden-byte minting (out-of-band oracle, D-12)
```python
# Source: lxml docs — etree.tostring(method="c14n", exclusive=True, inclusive_ns_prefixes=[...])
# Run in a PINNED container; record lxml + libxml2 versions in PROVENANCE.md.
from lxml import etree
print("lxml", etree.__version__, "libxml2", etree.LIBXML_VERSION)   # record both
doc = etree.parse("assertion_inherited_ns.input.xml")
node = doc.find(".//{*}Assertion")                                  # the exact bound node
canon = etree.tostring(node, method="c14n", exclusive=True,
                       inclusive_ns_prefixes=None)                  # or ["ec","saml"] per fixture
open("assertion_inherited_ns.c14n", "wb").write(canon)             # raw bytes, NO trailing newline
```
> Known lxml caveat: older lxml had a bug where exclusive C14N ignored `inclusive_ns_prefixes` [CITED: bugs.launchpad.net/lxml/+bug/1704826 ; lxml PR #55]. Pin a recent lxml AND cross-check with xmlsec1 — this is precisely the reason D-12 mandates the dual-tool cross-check.

### xmlsec1 cross-check (out-of-band oracle, D-12)
```bash
# Source: xmlsec1 man — exclusive C14N. Verify the lxml bytes match xmlsec1 byte-for-byte.
# (xmlsec1 was NOT installed in this research env; mint on a machine/container that has it.)
xmlsec1 --c14n-exc assertion_inherited_ns.input.xml > xmlsec.c14n
diff <(cat xmlsec.c14n) assertion_inherited_ns.c14n && echo "oracles agree"
# Record xmlsec1 --version + its libxml2 version in PROVENANCE.md.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Regex string-scanning seam (`pure_beam.ex`) | Real saxy parse tree + hand-rolled exc-C14N | This phase (28) | Closes the parser-differential class; enables Phase 29 crypto. |
| `canonicalize/2` passthrough (`normalize_signed_xml` = trim + CRLF replace) | Correct exclusive C14N over the tree | This phase | The passthrough cannot canonicalize XML; it is why the bypass exists. |
| esaml/xmerl for SAML C14N | Pure-BEAM saxy + custom C14N (ADR-0001) | Project inception | Avoids xmerl XXE (CVE-2026-28809) + native build matrix. |

**Deprecated/outdated:**
- `esaml`/`xmerl_c14n` for any new SAML C14N: inclusive-only, DOM-based, CVE-2026-28809 XXE [VERIFIED: cna.erlef.org/cves/CVE-2026-28809.html]. Do not introduce.
- The `String.trim/1` in `normalize_signed_xml/1`: incompatible with byte-exact C14N (would strip required structure / mishandle no-trailing-newline). Drop it; keep only the CRLF/CR→LF replace as the line-ending layer.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `{:saxy, "~> 1.6"}` is legitimate and resolves to `github.com/qcam/saxy` | Package Legitimacy Audit | slopcheck/ctx7 unavailable → planner must add `checkpoint:human-verify` before install (mitigated: 8.5M downloads, 7-yr age, public MIT repo). |
| A2 | Saxy emits `:cdata` content that must be C14N-escaped exactly like `:characters` text (no special CDATA marker survives canonicalization) | Pattern 1 | Low: C14N expands CDATA to escaped text; if Saxy merges CDATA into `:characters` instead of a separate `:cdata` event, handler must cover both — handle both events identically. Verify against a CDATA fixture. |
| A3 | All SAML attributes are CDATA-type (no DTD), so attribute-value normalization collapses `#x9`/`#xA`/`#xD`→single space (not the more aggressive non-CDATA token-collapse) | Pattern 2 / Pitfall 3 | Medium: if a fixture somehow declared a DTD it would be rejected by the DOCTYPE guard first, so DTD-typed attrs cannot reach C14N — assumption holds by construction. |
| A4 | The exclusive-C14N algorithm details (visibly-utilized, sort, escape tables, empty-element expansion, no trailing newline) as summarized match the W3C RECs byte-for-byte | Architecture Patterns / Pitfalls | The golden-byte gate (D-11/D-12) is the empirical check that converts this from MEDIUM to proven; planner MUST treat the oracle, not this summary, as authoritative. |
| A5 | Saxy decodes source encoding to UTF-8 before delivering event strings | Pitfall 6 | Low-Medium: Saxy is XML-1.0 compliant; confirm with a non-ASCII fixture in the golden set. |

**This table is non-empty:** A1 (package legitimacy gate) and A4 (C14N byte-exactness must be proven by the oracle, not asserted from research) are the two the planner/executor must actively confirm — A1 via checkpoint, A4 via the GATE-02 golden differential.

## Open Questions

1. **Does Saxy emit a separate `:cdata` event or fold CDATA into `:characters`?**
   - What we know: `Saxy.Handler` lists both `:characters` and `:cdata` events [CITED: hexdocs.pm/saxy/Saxy.Handler.html].
   - What's unclear: whether a given Saxy version routes `<![CDATA[...]]>` to `:cdata` or `:characters`.
   - Recommendation: handle both events with identical text-append + normalization logic; add a CDATA golden fixture to lock behavior.

2. **Exact handle shape carrying the tree node (D-07/D-10).**
   - What we know: must be additive, arity-preserving, and carry enough context to canonicalize both the referenced node now and `SignedInfo` in Phase 29.
   - What's unclear: precise struct/keys (Claude's Discretion).
   - Recommendation: planner picks a struct under the seam; keep the existing flat `signed_candidates` map entries `{xml_id, xpath, signed_xml, signature_method, digest_method}` intact and add a `:node` (tree reference) field — additive, satisfies D-08 and D-10.

3. **Whether the existing `c14n-00x` differential fixtures must still return `canonicalization_failed` after the engine is real.**
   - What we know: GATE-02 currently asserts `canonicalization_failed` for them; they contain a `<Reference>` but no real signature/digest material.
   - What's unclear: nothing blocking — but the planner must explicitly preserve fail-closed for incomplete inputs (Pitfall 9).
   - Recommendation: real `canonicalize/2` returns `:canonicalization_failed` unless a complete bindable node is present; the NEW golden fixture is the only success case in this phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | build + test | ✓ | Elixir 1.19.5 / OTP 28 | — |
| `saxy` | runtime parser (D-02) | ✗ (absent from mix.exs + mix.lock — confirmed) | will pin `~> 1.6` | none — must add (success criterion #1) |
| `lxml` | golden-byte minting (D-12) | ✗ (not installed here) | — | mint on a pinned container/other machine; bytes committed, so CI never needs it |
| `xmlsec1` | golden cross-check (D-12) | ✗ (not installed here) | — | same — out-of-band; CI stays pure-Elixir (`mix ci.security`) |

**Missing dependencies with no fallback:**
- `saxy` — required by success criterion #1; the phase cannot complete without adding it. (Not a research blocker — adding it is the work.)

**Missing dependencies with fallback:**
- `lxml` + `xmlsec1` — by design NOT in CI (D-12). Golden bytes are minted out-of-band on a machine/container that has them and committed with a PROVENANCE note; `mix ci.security` reads the committed bytes only. The planner should NOT add a native-toolchain step to CI (would violate ADR-0001's pure-BEAM-CI rationale and the `mix ci.security` aliases, which are pure-Elixir [VERIFIED: mix.exs `aliases/0` `ci.security`]).

## Validation Architecture

> Nyquist validation is ENABLED (`workflow.nyquist_validation: true` in `.planning/config.json`). This section is consumed downstream to create VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in; Elixir 1.19.5 / OTP 28) |
| Config file | none separate — `test/test_helper.exs`; security corpus tests tagged `:security_corpus` / `:gate02_c14n` |
| Quick run command | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` |
| Full suite command (security lane) | `mix ci.security` (pure-Elixir; runs the corpus + gate02 + sobelow/audit) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGV-03 | `saxy` is a real dep; seam parses into a tree (not regex) | unit + dep-presence | `mix deps.get && mix compile --warnings-as-errors` then `mix test test/security/xml/ --only security_corpus` | ❌ Wave 0 (saxy not yet added; new modules not yet present) |
| SIGV-03 | `canonicalize/2` output == independent reference, byte-for-byte (success #2) | golden-byte equality | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (NEW assertion) | ❌ Wave 0 (golden fixture + assertion to be added) |
| SIGV-03 | Existing hardened guards still hold on new parser; v1.0 corpus green (success #3) | corpus regression | `mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus` | ✅ (existing — must stay green) |
| SIGV-03 | Differential/incomplete inputs still fail closed (`canonicalization_failed`) | fail-closed gate | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (existing `c14n-00x` rows) | ✅ (existing — must stay green) |
| SIGV-03 | Verified node bound to the exact canonicalized element (success #4) | unit (node-binding) | `mix test test/security/xml/...` (NEW: assert handle node ≡ canonicalized node) | ❌ Wave 0 |
| SIGV-03 | `parsed_doc` flat-key contract preserved additively (D-08) | contract/regression | run the existing `ValidationPipeline`/`Signature`/`AutoRefresh` test suites unchanged | ✅ (existing downstream tests must stay green) |
| SIGV-03 | seam `@callback` arity unchanged (D-07) | contract | `seam_contract_test` (existing — asserts the exact callback set) | ✅ (existing — must stay green) |

### Layers, what "correct" means, oracle, and pitfall coverage
| Layer | "Correct" means | Reference oracle | Pitfalls covered |
|-------|-----------------|------------------|------------------|
| **L1 Golden-byte equality** | `canonicalize/2` output == committed golden bytes, byte-for-byte (incl. no trailing newline) | `lxml` (pinned) cross-checked with `xmlsec1`, committed out-of-band (D-12) | 1,2,3,4,5,6,7,8 (each pitfall ⇒ at least one golden fixture variant) |
| **L2 Fail-closed differential** | incomplete/differential inputs ⇒ `{:error, :canonicalization_failed}` | existing `c14n-00x` manifest rows (expected_error_type) | 9 (calling convention / fail-closed) |
| **L3 Corpus regression** | every v1.0 fixture's `expected_error_type` unchanged on the saxy path | `priv/security_corpus.json` + `test/fixtures/.../manifest.json` (source of truth) | guard portability (DOCTYPE/ENTITY/size/KeyInfo/dup-ID/single-node) |
| **L4 Backward-compat contract** | downstream `parsed_doc` readers + seam contract test still green | existing `ValidationPipeline`/`Signature`/`AutoRefresh`/`seam_contract` tests | D-07, D-08 (no arity/key regression) |
| **L5 (recommended) round-trip / property** | canonicalize(canonicalize(x)) == canonicalize(x) (idempotence); reordering insignificant attrs/ns yields identical bytes | self-check (idempotence) + oracle for the base case | reinforces 1,2,8 (sort/render stability) |

**Sampling rate:**
- **Per task commit:** `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (golden + fail-closed) — fast.
- **Per wave merge:** `mix ci.security` (full pure-Elixir security lane) green.
- **Phase gate:** full `mix ci.security` + the existing downstream suites (`ValidationPipeline`/`Signature`/`AutoRefresh`) green before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `mix.exs` — add `{:saxy, "~> 1.6"}` (non-optional) + `mix deps.get` (gated by A1 `checkpoint:human-verify`).
- [ ] `lib/relyra/security/xml/saxy_tree.ex` — new `Saxy.Handler` tree builder + in-scope ns stack (under allowed root).
- [ ] `lib/relyra/security/xml/c14n.ex` — new exclusive-C14N engine.
- [ ] `test/fixtures/security/xml/parser_differential_and_c14n/*.input.xml` + `*.c14n` + `PROVENANCE.md` — at least one golden (SAML assertion with ancestor-declared ns); add per-pitfall variants where useful.
- [ ] GATE-02 byte-equality assertion in `test/security/xml/corpus_security_test.exs` (NEW positive path; keep existing fail-closed rows).
- [ ] Node-binding unit test (success #4: handle node ≡ canonicalized node).
- [ ] (Recommended) idempotence/property test for C14N.

## Security Domain

> `security_enforcement` is not set to `false`; this is a SECURITY-CRITICAL phase. Section included.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Pre-parse byte guards (DOCTYPE/ENTITY/size) on raw binary before Saxy (D-09); Saxy enforces XML 1.0 well-formedness; typed `%Relyra.Error{}` on malformed input. |
| V6 Cryptography | partial | No crypto in Phase 28 (deferred to 29) — but C14N correctness is the *precondition* for the crypto check; a byte-divergence silently defeats it. The control here is the golden-byte differential gate (D-11/D-12), not a crypto primitive. |
| V14 Config / Data Protection (XXE) | yes | DTD + external-entity rejection before any parse (XXE-before-verify invariant; mirrors the lesson of CVE-2026-28809 in esaml). |
| V2 Authn / V3 Session / V4 Access Control | no (this phase) | This phase builds canonical bytes; auth decisions are Phase 29+. |

### Known Threat Patterns for {saxy parse tree + hand-rolled exc-C14N}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XXE / external entity (pre-verify file read / SSRF) | Information Disclosure / Tampering | Reject `<!DOCTYPE>`/`<!ENTITY>` on raw bytes before Saxy (D-09); never expand entities. The esaml CVE-2026-28809 is the concrete cautionary case. |
| Signature wrapping (XSW) | Spoofing / Elevation | Single-signed-node selection + duplicate-ID rejection + node binding to the exact canonicalized element (D-09, D-10). |
| C14N byte-divergence (silent) | Tampering | Independent-oracle golden-byte differential gate (D-11/D-12) covering all 8 pitfalls; fail-closed for incomplete inputs (Pitfall 9). |
| Document-KeyInfo trust abuse (CVE-2024-45409 family) | Spoofing | `key_info_trust` rejection preserved on the new parser (D-09). |
| Billion-laughs / oversized payload | Denial of Service | Pre/post-decode `max_bytes` guard before parse (D-09). |
| Parser differential (two paths disagree) | Tampering / Spoofing | One parser path only — derive all fields from the single saxy tree (D-04); `parser_path_guard` compile-time confinement enforced. |

## Project Constraints (from CLAUDE.md / project docs)

> No `./CLAUDE.md` exists in the working directory. Constraints below are extracted from PROJECT.md / ADR-0001 / existing CI config and carry locked-decision authority for this phase:
- **One hardened parser path, no parser differentials** (PROJECT.md pillar #3). Do not introduce a second parser; derive everything from the saxy tree.
- **DTDs + external entities + network fetches disabled before any parse; size limits pre/post-decode** (PROJECT.md XML security boundary — "non-negotiable base invariant").
- **`parser_path_guard` compile-time guard:** `Saxy`/`SweetXml`/`xmerl` references only inside `lib/relyra/security/xml/` (or the guard file / seam file). New modules MUST live there [VERIFIED: parser_path_guard.ex `@allowed_roots`].
- **`mix ci.security` stays pure-Elixir** — no native toolchain step (ADR-0001 rationale; D-12). [VERIFIED: mix.exs `ci.security` alias.]
- **Typed `%Relyra.Error{}` failures** via the `xml_error_type` union — reuse `:canonicalization_failed`, `:malformed_xml`, etc.; do not invent ad-hoc error tuples.
- **`@callback` arity unchanged** — `seam_contract_test` asserts the exact callback set (D-07).
- **`--warnings-as-errors`** is used across `qa`/`ci.*` aliases — new code must compile clean.

## Backward-Compat Surface (EXACT `parsed_doc` keys to preserve — D-08)

> Enumerated from the actual downstream readers. The planner must preserve every key below additively; attach the tree as a NEW key (`:parse_tree`) only.

**Read by `Relyra.Security.Signature.do_verify/4` + `verified_signed_node/4`** [VERIFIED: lib/relyra/security/signature.ex]:
- `:duplicate_ids` (list) — duplicate-ID rejection
- `:key_info_trust` (bool) — document-KeyInfo rejection
- `:signature_method` (string) — algorithm policy
- `:digest_method` (string) — algorithm policy
- `:signed_candidates` (list of maps), each map: `:xml_id`, `:xpath`, `:signed_xml`, `:signature_method`, `:digest_method`

**Read by `Relyra.Protocol.ValidationPipeline`** [VERIFIED: lib/relyra/protocol/validation_pipeline.ex]:
- `:in_response_to`, `:issuer`, `:status`, `:destination`
- `:audiences` (list), `:recipient`
- `:assertion_times` (map: `:not_before`, `:not_on_or_after`, `:subject_confirmation_not_on_or_after`)
- `:name_id`, `:name_id_format`, `:session_index`, `:attributes` (map), `:connection_id`
- `:signed_candidates` (for `assertion_count/1`)

**Read by `Relyra.Metadata.AutoRefresh` / `Signature.verify_metadata_root/4`** [VERIFIED: lib/relyra/metadata/auto_refresh.ex]:
- The metadata-root path builds its OWN `parsed_doc`-shaped map (`pre_parse_for_signature/1`) with `:signed_candidates` (`:xml_id`, `:xpath`, `:signed_xml`), `:key_info_trust`, `:duplicate_ids`. It currently uses regex (Pitfall-4 "verify before parse-deeply"). **Phase 28 note:** this is the **second canonicalization caller**. D-08 requires the same flat contract; whether the metadata path also moves onto the saxy tree is a planner decision, but the *contract it produces/consumes* (`signed_candidates` shape, `key_info_trust`, `duplicate_ids`) must stay identical so `do_verify` (shared primitive) keeps working. The cert-extraction regex in `extract_candidate_signing_pems/1` runs BEFORE deep parse and is a deliberate pre-verify scan — leave it (it is not the trust-establishing parse).

**`SignedNode` struct shape to preserve** [VERIFIED: lib/relyra/security/signed_node.ex]: `:xml_id`, `:xpath`, `:signed_xml`, `:signature_method`, `:digest_method`.

## Guard Portability Map (D-09 — each guard onto the saxy path)

| Guard (current location) | Where it runs now | On the saxy path |
|--------------------------|-------------------|------------------|
| `max_bytes` size limit | `parse_safely/2` pre-parse, raw binary | unchanged — stays raw-binary check BEFORE Saxy |
| `<!DOCTYPE` rejection | `parse_safely/2` `String.contains?` | unchanged — raw-binary check BEFORE Saxy (XXE-before-verify) |
| `<!ENTITY` rejection | `parse_safely/2` `String.contains?` | unchanged — raw-binary check BEFORE Saxy |
| document-`KeyInfo` rejection | `select_signed_node/2` via `:key_info_trust` | derive `:key_info_trust` from the tree (presence of a `KeyInfo` element) instead of regex; same key, same rejection |
| duplicate-ID rejection | `select_signed_node/2` via `:duplicate_ids` | derive `:duplicate_ids` from the tree (collect all `ID`/`id` attrs, find dups); same key, same rejection |
| single-signed-node selection | `select_candidate/1` (exactly-one) | unchanged logic over tree-derived `:signed_candidates`; bind to the tree node (D-10) |
| malformed-XML rejection | regex shape check | replaced by Saxy well-formedness (`{:error, %Saxy.ParseError{}}` → `:malformed_xml`) |
| post-decode size limit | (pre/post-base64/inflate per PROJECT.md) | preserve wherever decode happens; not weakened |

## Sources

### Primary (HIGH confidence)
- `https://hexdocs.pm/saxy/Saxy.Handler.html` — SAX event set; `:start_element` = `{name, attributes}`; verbatim names; ordered attrs; NO namespace handling mentioned.
- `https://hexdocs.pm/saxy/Saxy.html` — `Saxy.parse_string/3` usage.
- `https://hex.pm/api/packages/saxy` — saxy 1.6.0 (2024-10-22), MIT, 8.5M downloads, repo qcam/saxy.
- `https://cna.erlef.org/cves/CVE-2026-28809.html` — esaml XXE (CWE-611, all versions incl. dropbox fork) — confirms D-05 rejection of esaml/xmerl_c14n.
- `https://www.w3.org/TR/xml-exc-c14n/` — Exclusive C14N 1.0: visibly-utilized rule, InclusiveNamespaces PrefixList.
- `https://www.w3.org/TR/2001/REC-xml-c14n-20010315/` — Canonical XML 1.0: sort order, escaping tables, empty-element/whitespace/no-trailing-newline rules.
- `https://www.w3.org/TR/xmldsig-core/` — XMLDSig §6.6.4 enveloped-signature transform.
- Repo files (VERIFIED by direct read): `lib/relyra/security/xml.ex`, `.../xml/pure_beam.ex`, `.../signature.ex`, `.../signed_node.ex`, `protocol/validation_pipeline.ex`, `metadata/auto_refresh.ex`, `lib/mix/tasks/compile/parser_path_guard.ex`, `test/security/xml/corpus_security_test.exs`, `priv/security_corpus.json`, `test/fixtures/security/xml/manifest.json`, `mix.exs`, `mix.lock`, `.planning/.../01-ADR.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`.

### Secondary (MEDIUM confidence)
- `https://github.com/qcam/saxy` — README/handler source confirming SAX interface + no namespace resolution.
- `https://bugs.launchpad.net/lxml/+bug/1704826` + `https://github.com/lxml/lxml/pull/55` — lxml exclusive-C14N `inclusive_ns_prefixes` history (why D-12 mandates pinning + xmlsec1 cross-check).
- `https://www.di-mgt.com.au/xmldsig-c14n.html` — the 8 byte-divergence pitfalls (normalization, line-endings, no-trailing-newline, encoding).

### Tertiary (LOW confidence)
- `https://cryptosys.net/sc14n/excl-c14n-examples.html` — worked exclusive-C14N examples (illustrative; the W3C RECs + the committed oracle are authoritative).

## Metadata

**Confidence breakdown:**
- Standard stack (saxy 1.6.0, version/registry): HIGH — verified via hex.pm API.
- Saxy SAX API + no-namespace behavior: HIGH — verified via hexdocs handler module + source.
- Backward-compat surface (`parsed_doc` keys, seam arity, guards): HIGH — read directly from source.
- esaml/xmerl_c14n rejection (CVE-2026-28809): HIGH — verified via ErlEF CNA.
- Exclusive-C14N algorithm details (sort/escape/render/PrefixList): MEDIUM-HIGH — W3C-cited; byte-exactness must be proven by the golden gate, not by research (A4).
- Toolchain (lxml/xmlsec1 invocations): MEDIUM-HIGH — lxml invocation cited; neither tool installed here, so exact version/byte output must be captured at mint time + recorded in PROVENANCE.

**Research date:** 2026-05-23
**Valid until:** ~2026-06-22 (30 days; saxy/exc-C14N are stable. Re-confirm saxy latest with `mix hex.info saxy` at plan time.)
