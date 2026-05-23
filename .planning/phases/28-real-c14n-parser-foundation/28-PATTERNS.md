# Phase 28: Real C14N parser foundation - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 6 (2 new modules, 3 modified, 1 new fixture set)
**Analogs found:** 6 / 6 (every new/modified file has a concrete in-repo analog)

> All code excerpts below are verbatim from the current codebase with file paths + line
> numbers. The planner/executor should replicate these established conventions rather than
> invent new ones. The **only** genuinely net-new algorithm (hand-rolled exclusive C14N) has
> no in-repo analog — its shape is governed by the W3C specs in `28-CONTEXT.md`
> `<canonical_refs>`, but its module skeleton, error construction, and guard-clause style
> still copy `pure_beam.ex`.

---

## File Classification

| New/Modified File | Role | Data-flow stage | Closest Analog | Match Quality |
|-------------------|------|-----------------|----------------|---------------|
| `lib/relyra/security/xml/saxy_tree.ex` (NEW) | SAX handler (`@behaviour Saxy.Handler`) | parse → build tree + in-scope ns stack | `lib/relyra/security/xml/pure_beam.ex` (module skeleton, `@behaviour`/`@impl`, Error construction) | role-adjacent (no SAX handler exists yet; copies module/error conventions) |
| `lib/relyra/security/xml/c14n.ex` (NEW) | pure transform engine (exclusive C14N 1.0) | canonicalize (select → c14n) | `pure_beam.ex` `canonicalize/2` + `normalize_signed_xml/1` (lines 72-102, 352-357) | role-match (replaces the passthrough it sits behind; algorithm is net-new) |
| `lib/relyra/security/xml/pure_beam.ex` (MODIFIED) | seam adapter (`@behaviour Relyra.Security.XML`) | parse → select → canonicalize orchestrator | itself (refactor in place; keep guards, retire regex extractors) | exact (self) |
| `mix.exs` (MODIFIED) | build config (deps) | n/a | `mix.exs` `deps/0` (lines 55-71) | exact (self) |
| `test/security/xml/corpus_security_test.exs` (MODIFIED) | test (corpus/GATE-02) | assertion over canonicalize output | itself — `gate02_c14n` block (lines 34-60) + `evaluate_fixture/2` (98-131) | exact (self) |
| `test/fixtures/security/xml/parser_differential_and_c14n/*.input.xml` + `*.c14n` + `PROVENANCE.md` (NEW) | fixture set (golden bytes) | golden oracle for byte-equality | manifest provenance shape (`priv/security_corpus.json` c14n-differential-001 row) + `corpus_gate.ex` `@external_resource` file-read pattern | role-match (first on-disk golden; manifest rows are the metadata analog) |

---

## Pattern Assignments

### `lib/relyra/security/xml/saxy_tree.ex` (NEW — SAX handler, parse stage)

**Analog:** `lib/relyra/security/xml/pure_beam.ex` (module + behaviour + error conventions).
The SAX-event handler *body* shape is given by RESEARCH.md Pattern 1; the **module wrapper,
`@behaviour`/`@impl`, alias, and Error construction** copy `pure_beam.ex`.

**Allowed-root constraint (MANDATORY):** This module MUST live under
`lib/relyra/security/xml/`. The compile-time guard scans every `lib/**/*.ex` for `\bSaxy\b`
and fails compile unless the file is under an allowed root
(`lib/mix/tasks/compile/parser_path_guard.ex` lines 8-13):

```elixir
@parser_patterns [~r/\bSaxy\b/, ~r/\bSweetXml\b/, ~r/\bxmerl\b/]
@allowed_roots [
  "lib/relyra/security/xml.ex",
  "lib/relyra/security/xml/",
  "lib/mix/tasks/compile/parser_path_guard.ex"
]
```
`lib/relyra/security/xml/saxy_tree.ex` matches `"lib/relyra/security/xml/"` → compile-passes.
Any reference to `Saxy` outside this root (e.g. accidentally in `validation_pipeline.ex`)
fails compile. The `@version "1.1.0"` `compilers: [:parser_path_guard] ++ Mix.compilers()`
wiring in `mix.exs` line 17 runs this guard on every `mix compile`.

**Module/behaviour/alias header to copy** (from `pure_beam.ex` lines 1-9):
```elixir
defmodule Relyra.Security.XML.PureBeam do
  @moduledoc """
  Pure-BEAM baseline adapter for XML seam enforcement.
  """

  @behaviour Relyra.Security.XML

  alias Relyra.Error
  @default_opts [max_bytes: 1_048_576]
```
For `SaxyTree`: same shape, `@behaviour Saxy.Handler`, `@impl true` on each `handle_event/3`,
`alias Relyra.Error` for any error returns.

**Parse-error → typed Error** (the established `:malformed_xml` mapping; copy from
`pure_beam.ex` lines 359-361 and the RESEARCH.md "Saxy parse entry" example):
```elixir
defp malformed_xml_error do
  {:error, Error.new(:malformed_xml, "Malformed XML payload", %{})}
end
```
On `{:error, %Saxy.ParseError{} = err}`, return
`Error.new(:malformed_xml, "Malformed XML payload", %{reason: Saxy.ParseError.message(err)})`
— reuse the existing `:malformed_xml` member of the `xml_error_type` union
(`lib/relyra/security/xml.ex` lines 8-21); do NOT invent a new error atom.

---

### `lib/relyra/security/xml/c14n.ex` (NEW — pure transform engine, canonicalize stage)

**Analog:** `pure_beam.ex` `canonicalize/2` (lines 72-102) — the callback this engine sits
behind — and `normalize_signed_xml/1` (lines 352-357), the line-ending layer to **keep**.

**Current `canonicalize/2` (the passthrough being replaced)** (`pure_beam.ex` lines 72-102):
```elixir
@impl true
def canonicalize(signed_node_handle, opts \\ [])

def canonicalize(
      %{
        xml_id: xml_id,
        xpath: xpath,
        signed_xml: signed_xml,
        signature_method: signature_method,
        digest_method: digest_method
      },
      _opts
    )
    when is_binary(xml_id) and is_binary(xpath) and is_binary(signed_xml) and
           is_binary(signature_method) and is_binary(digest_method) do
  {:ok,
   %{
     canonical_xml: normalize_signed_xml(signed_xml),
     xml_id: xml_id,
     xpath: xpath
   }}
end

def canonicalize(_signed_node_handle, _opts) do
  {:error,
   Error.new(
     :canonicalization_failed,
     "Signed node handle could not be canonicalized",
     %{reason: :invalid_signed_node_handle}
   )}
end
```
**Two load-bearing facts the executor must preserve:**
1. **The fail-closed fallback clause is the GATE-02 contract.** The second `canonicalize/2`
   head returns `{:error, :canonicalization_failed}` for any handle that does not bind a
   complete node. RESEARCH.md Pitfall 9 confirms GATE-02 currently calls
   `PureBeam.canonicalize(parsed_doc, [])` with the *whole parsed_doc map* — which only
   matches this fallback, which is *why* the differential fixtures fail closed. Keep a guard
   clause that returns `:canonicalization_failed` unless a complete bindable tree node is
   present; do NOT let the real engine succeed on the existing `c14n-00x` differential rows.
2. **Keep the line-ending layer, drop `String.trim`.** `normalize_signed_xml/1`
   (`pure_beam.ex` lines 352-357):
   ```elixir
   defp normalize_signed_xml(signed_xml) do
     signed_xml
     |> String.replace("\r\n", "\n")
     |> String.replace("\r", "\n")
     |> String.trim()
   end
   ```
   Carry forward ONLY the `\r\n`→`\n` and `\r`→`\n` replaces (D-03 layer 3 / Pitfall 5).
   **Drop `String.trim/1`** — RESEARCH.md "Anti-Patterns" + "Deprecated/outdated": trim
   violates byte-exact C14N (strips leading/internal significance and the no-trailing-newline
   invariant, Pitfall 4).

**Error construction for rejected transforms / incomplete inputs:** reuse
`Error.new(:canonicalization_failed, <message>, %{reason: <atom>})` exactly as the fallback
clause above. The `:canonicalization_failed` atom is already in the union
(`xml.ex` line 19).

**Algorithm has NO in-repo analog** — the visibly-utilized rendering, rendered-vs-in-scope
stacks, PrefixList forced render, sort order, two escaping functions, empty-element expansion,
no-trailing-newline, and enveloped-signature transform are governed by the W3C specs cited in
`28-CONTEXT.md` `<canonical_refs>` (xml-exc-c14n, REC-xml-c14n, xmldsig-core) and the 8
pitfalls in `28-RESEARCH.md`. See "No Analog Found" below.

---

### `lib/relyra/security/xml/pure_beam.ex` (MODIFIED — seam adapter, full orchestrator)

**Analog:** itself. This file keeps all three `@impl` callbacks (D-07 arity unchanged) and
its **pre-parse byte guards** verbatim; the regex extractors (`parse_xml/1` regex shape
checks + every `extract_*` / `first_tag_text` / `first_attribute` helper, lines 104-321) are
**retired** and re-derived from the saxy tree (D-04).

**KEEP verbatim — the pre-parse byte guards** (`parse_safely/2`, lines 14-35). These run on
the raw binary BEFORE any parse (XXE-before-verify invariant, D-09; Guard Portability Map):
```elixir
def parse_safely(xml, opts) when is_binary(xml) do
  max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

  cond do
    byte_size(xml) > max_bytes ->
      {:error,
       Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
         max_bytes: max_bytes
       })}

    String.contains?(xml, "<!DOCTYPE") ->
      {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

    String.contains?(xml, "<!ENTITY") ->
      {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

    true ->
      parse_xml(xml)   # <- swap regex parse_xml/1 for the Saxy-tree builder
  end
end

def parse_safely(_xml, _opts), do: malformed_xml_error()
```
Only the `true ->` arm changes: route to `Saxy.parse_string(xml, Relyra.Security.XML.SaxyTree, ...)`
then build the flat `parsed_doc` from the tree. The size/DOCTYPE/ENTITY checks and the
non-binary fallback stay exactly as-is.

**KEEP verbatim — `select_signed_node/2` guard cascade** (lines 40-70). The KeyInfo +
duplicate-ID rejections stay; only the *source* of `:key_info_trust` / `:duplicate_ids`
changes from regex to tree-derived (Guard Portability Map):
```elixir
def select_signed_node(parsed_doc, _opts) when is_map(parsed_doc) do
  duplicate_xml_ids = Map.get(parsed_doc, :duplicate_ids, [])

  cond do
    Map.get(parsed_doc, :key_info_trust) == true ->
      {:error,
       Error.new(
         :untrusted_certificate,
         "Document-provided KeyInfo cannot be used as a trust source",
         %{reason: :document_keyinfo_forbidden}
       )}

    duplicate_xml_ids != [] ->
      {:error,
       Error.new(:duplicate_xml_id, "Duplicate XML IDs detected in signed material", %{
         duplicate_ids: duplicate_xml_ids,
         duplicate_count: length(duplicate_xml_ids)
       })}

    true ->
      select_candidate(parsed_doc)
  end
end
```

**KEEP — `select_candidate/1` single-node selection** (lines 323-350). Exactly-one-candidate
logic stays; D-10 requires the returned handle to carry a reference to the *same* tree node
that `canonicalize/2` will serialize (add a `:node` field additively to the candidate map):
```elixir
case signed_candidates do
  [] ->
    {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}

  [candidate] when is_map(candidate) ->
    {:ok, %{
       xml_id: Map.get(candidate, :xml_id),
       xpath: Map.get(candidate, :xpath),
       signed_xml: Map.get(candidate, :signed_xml),
       signature_method: Map.get(candidate, :signature_method, signature_method),
       digest_method: Map.get(candidate, :digest_method, digest_method)
       # D-10: add :node (tree reference) here, additively
     }}

  candidates ->
    {:error, Error.new(:ambiguous_signed_node, "Exactly one verified signed node is required",
       %{candidate_count: length(candidates)})}
end
```

**KEEP — `require_present_fields/4` + `present?/1` pattern** (lines 232-252). This is the
established "missing protocol field" gate; re-derive the same field set from the tree and run
it through this same helper so the `:missing_protocol_field` / `:missing_signature` error
shapes are identical:
```elixir
defp require_present_fields(fields, required_keys, error_type, message) do
  missing = Enum.reject(required_keys, fn key -> present?(Map.get(fields, key)) end)

  if missing == [] do
    {:ok, fields}
  else
    {:error, Error.new(error_type, message, %{
       expected: required_keys, actual: required_keys -- missing, missing: missing})}
  end
end
```

**RETIRE (D-04) — every regex extractor:** `parse_xml/1`'s regex shape checks (lines 105-116),
`extract_response_fields/1`, `extract_assertion_fields/1`, `extract_attributes/1`,
`extract_signature_fields/1`, `extract_signed_candidates/1`, `extract_duplicate_ids/1`,
`first_tag_text/2`, `all_tag_texts/2`, `first_attribute/3`, `attribute_from_fragment/2`
(lines 141-321). Re-derive **all** of these fields from the single saxy tree in one pass.

**BACKWARD-COMPAT — the flat `parsed_doc` keys these helpers currently produce MUST be
reproduced additively (D-08).** Verified downstream readers:

- `Relyra.Security.Signature.do_verify/4` + `verified_signed_node/4`
  (`lib/relyra/security/signature.ex`): reads `:duplicate_ids` (line 106),
  `:key_info_trust` (113), `:signature_method`/`:digest_method` (139-140),
  `:signed_candidates` (160), and per-candidate `:xml_id`/`:xpath`/`:signed_xml` (170-172)
  into a `%SignedNode{}`:
  ```elixir
  %SignedNode{
    xml_id: Map.get(candidate, :xml_id),
    xpath: Map.get(candidate, :xpath),
    signed_xml: Map.get(candidate, :signed_xml, ""),
    signature_method: signature_method,
    digest_method: digest_method
  }
  ```
- `Relyra.Protocol.ValidationPipeline` (`lib/relyra/protocol/validation_pipeline.ex`):
  reads `:status` (84), `:destination` (87), `:audiences` (92), `:recipient` (98),
  `:in_response_to` (116), `:issuer` (160), `:name_id`/`:name_id_format` (196-197),
  `:assertion_times` (231), `:signed_candidates` (236).
- `Relyra.Security.SignedNode` struct shape (`lib/relyra/security/signed_node.ex`):
  `[:xml_id, :xpath, :signed_xml, :signature_method, :digest_method]` — preserve.

Attach the parse tree as a NEW key (`:parse_tree`, D-07); never remove/rename the keys above.

---

### `mix.exs` (MODIFIED — build config)

**Analog:** `mix.exs` `deps/0` (lines 55-71). Add `{:saxy, "~> 1.6"}` as **non-optional**
(D-02) — note the existing optional deps carry `optional: true`; saxy must NOT:
```elixir
defp deps do
  [
    {:saxy, "~> 1.6"},
    {:telemetry, "~> 1.3"},
    {:plug, "~> 1.16"},
    {:phoenix, "~> 1.8", optional: true},
    # ...existing deps unchanged...
    {:req, "~> 0.5", optional: true},
    {:oban, "~> 2.22", optional: true}
  ]
end
```
**Do NOT touch the `ci.security` alias toolchain** (lines 151-164) — it stays pure-Elixir
(D-12); no native step. The relevant existing security-lane test invocations the new
assertions ride on:
```elixir
"test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
"test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
```
**A1 gate (RESEARCH.md):** slopcheck/ctx7 were unavailable; the planner must add a
`checkpoint:human-verify` task confirming `{:saxy, "~> 1.6"}` resolves to `github.com/qcam/saxy`
(sha in `mix.lock`) before `mix deps.get` runs on this trust-path dep.

---

### `test/security/xml/corpus_security_test.exs` (MODIFIED — GATE-02)

**Analog:** itself — the `gate02_c14n` test block (lines 34-60) and `evaluate_fixture/2`
(lines 98-131).

**Existing GATE-02 fail-closed block to PRESERVE** (lines 34-60) — keep this assertion green
for the existing `c14n-00x` rows:
```elixir
@tag :gate02_c14n
@tag :security_corpus
test "parser_differential_and_c14n is a binary gate with zero regressions" do
  fixtures =
    manifest()
    |> Enum.filter(&(&1["class"] == "parser_differential_and_c14n"))

  failures =
    Enum.reduce(fixtures, [], fn fixture, acc ->
      expected = String.to_atom(fixture["expected_error_type"])

      case evaluate_fixture(fixture) do
        {:error, %Error{type: type}} ->
          if type == expected, do: acc, else: [{fixture["id"], {:unexpected_type, type, expected}} | acc]
        other ->
          [{fixture["id"], other} | acc]
      end
    end)

  assert failures == [],
         "GATE-02 binary gate failed: parser_differential_and_c14n zero regressions violated"
end
```

**Current canonicalize calling convention** (`evaluate_fixture/2`, lines 123-126) — note it
passes the whole `parsed_doc`, which is why differential rows fail closed (Pitfall 9):
```elixir
"parser_differential_and_c14n" ->
  with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
    PureBeam.canonicalize(parsed_doc, [])
  end
```

**ADD (D-11) — a NEW positive byte-equality test** following the same `@tag :gate02_c14n` /
`File.read!` conventions used for the manifest (`manifest/0` at lines 92-96 reads
`priv/security_corpus.json` with `File.read!` + `:json.decode`). The new assertion reads the
committed golden bytes and asserts equality, e.g.:
```elixir
@tag :gate02_c14n
@tag :security_corpus
test "canonicalize/2 output matches committed golden bytes (byte-for-byte)" do
  input = File.read!("test/fixtures/security/xml/parser_differential_and_c14n/assertion_inherited_ns.input.xml")
  golden = File.read!("test/fixtures/security/xml/parser_differential_and_c14n/assertion_inherited_ns.c14n")

  {:ok, parsed_doc} = PureBeam.parse_safely(input, [])
  {:ok, signed_node} = PureBeam.select_signed_node(parsed_doc, [])
  {:ok, %{canonical_xml: out}} = PureBeam.canonicalize(signed_node, [])

  assert out == golden                       # byte-exact (Pitfalls 1-8)
  refute String.ends_with?(out, "\n")        # no trailing newline (Pitfall 4)
end
```
> Keep the existing `Relyra.Error`/`Relyra.Security.XML.PureBeam` aliases at the top
> (lines 4-5). Do NOT add a native-toolchain step — bytes are committed (D-12).

**Node-binding assertion (success criterion #4 / D-10):** add a unit assertion that the node
referenced by the `select_signed_node/2` handle is the *same* tree node `canonicalize/2`
serialized (no string-vs-node duality).

---

### `test/fixtures/security/xml/parser_differential_and_c14n/*` (NEW — golden fixture set)

**Analog:** the manifest provenance row shape in `priv/security_corpus.json` (the
c14n-differential-001 row) + the `@external_resource` committed-file pattern in
`corpus_gate.ex` (lines 47-54). The class directory
`test/fixtures/security/xml/parser_differential_and_c14n/` currently **exists but is empty**
(all corpus XML today lives inline in the manifest); these are the first on-disk goldens.

**Files to create (RESEARCH.md "Recommended Project Structure"):**
- `assertion_inherited_ns.input.xml` — a SAML assertion whose namespace is declared on an
  ancestor (`<Response>`) and inherited by the signed `<Assertion>` (success criterion #2
  minimum).
- `assertion_inherited_ns.c14n` — exact canonical bytes, **no trailing newline** (D-12,
  Pitfall 4). Commit as raw UTF-8, no BOM (Pitfall 6). Editors add trailing newlines — store
  bytes exactly.
- `PROVENANCE.md` — record tool + libxml2 versions, exact mint command, and any `PrefixList`
  (D-12). Mint with pinned `lxml` cross-checked against `xmlsec1` (commands in RESEARCH.md
  "Code Examples").

**Provenance-metadata shape to mirror** (from the c14n-differential-001 manifest row —
the established immutable-provenance convention; the "every manifest row carries immutable
provenance" test at `corpus_security_test.exs` lines 62-78 asserts `provenance`,
`requirement_ids`, `family`, `source_ref` are present):
```json
{
  "id": "c14n-differential-001",
  "class": "parser_differential_and_c14n",
  "family": "signature_wrapping",
  "requirement_ids": ["CVE-REG-01"],
  "expected_error_type": "canonicalization_failed",
  "provenance": {
    "source": "PureBeam seam regression corpus",
    "kind": "ported-fixture",
    "captured_at": "2026-05-07"
  },
  "source_ref": "purebeam:c14n-differential"
}
```
If a manifest row is added for the new golden (so GATE-02's manifest-driven loop can pick it
up), it must carry these same keys. The new positive golden's `PROVENANCE.md` carries the
tool/version/command detail that does not fit the JSON row.

---

## Shared Patterns

### Typed `%Relyra.Error{}` construction (apply to ALL new/modified seam code)
**Source:** `lib/relyra/error.ex` lines 15-17 (`Error.new/3`) + the `xml_error_type` union in
`lib/relyra/security/xml.ex` lines 8-21.
```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```
Reuse existing union members only: `:malformed_xml`, `:canonicalization_failed`,
`:doctype_forbidden`, `:entity_expansion_forbidden`, `:payload_too_large`,
`:duplicate_xml_id`, `:untrusted_certificate`, `:missing_signature`,
`:missing_protocol_field`. Do NOT invent ad-hoc error tuples or new atoms (PROJECT
constraint, RESEARCH.md "Project Constraints"). The `Inspect` impl already redacts
`:signed_xml`/`:xml` from `details` (error.ex lines 39-48) — safe to put node context in
`details`.

### Seam `@behaviour` / `@impl` callback contract (apply to `pure_beam.ex`; do NOT change arity)
**Source:** `lib/relyra/security/xml.ex` lines 23-28.
```elixir
@callback parse_safely(binary(), keyword()) :: {:ok, term()} | {:error, %Error{}}
@callback select_signed_node(parsed_doc :: term(), keyword()) :: {:ok, term()} | {:error, %Error{}}
@callback canonicalize(signed_node_handle :: term(), keyword()) :: {:ok, binary()} | {:error, %Error{}}
```
`seam_contract_test` asserts this exact callback set (D-07). Enrich the *term* flowing through
(`parsed_doc` gains `:parse_tree`; handle gains `:node`) — never the arity.

### Default-opts merge for `max_bytes` (apply to `parse_safely` on the saxy path)
**Source:** `pure_beam.ex` lines 9, 15.
```elixir
@default_opts [max_bytes: 1_048_576]
max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)
```

### Compile-time parser confinement (apply to BOTH new modules)
**Source:** `lib/mix/tasks/compile/parser_path_guard.ex` lines 8-13 + `mix.exs` line 17
(`compilers: [:parser_path_guard] ++ Mix.compilers()`). Any file referencing `Saxy` must be
under `lib/relyra/security/xml/`. Both `saxy_tree.ex` and `c14n.ex` satisfy this; do not
reference `Saxy` from `validation_pipeline.ex`, `signature.ex`, or `auto_refresh.ex`.

### Corpus-as-source-of-truth + committed-resource read (apply to fixtures + tests)
**Source:** `corpus_security_test.exs` `manifest/0` (lines 92-96, `File.read!` + `:json.decode`)
and `corpus_gate.ex` `@external_resource`/compile-time read (lines 47-54). The runtime gate
and the test reader share `priv/security_corpus.json` so neither crosses the lib/test
boundary. New goldens are committed files read with `File.read!`; CI never mints them.

---

## No Analog Found

| File / Concern | Role | Data flow | Reason |
|----------------|------|-----------|--------|
| `c14n.ex` exclusive-C14N **algorithm body** | transform engine | canonicalize | No correct exclusive-C14N implementation exists in the repo (the current `normalize_signed_xml/1` is a trim+CRLF passthrough, not C14N). `esaml`/`xmerl_c14n` rejected (inclusive-only, CVE-2026-28809). The visibly-utilized rule, rendered-vs-in-scope stacks, PrefixList forcing, attribute sort-by-resolved-URI, dual escaping, empty-element expansion, and enveloped-signature transform must be built from the W3C specs in `28-CONTEXT.md` `<canonical_refs>` + the 8 pitfalls in `28-RESEARCH.md`. The **module skeleton, error returns, and line-ending layer** still copy `pure_beam.ex` (above). |
| `saxy_tree.ex` SAX **event handling + in-scope ns stack** | SAX handler | parse | No `Saxy.Handler` (or any SAX handler) exists in the repo yet. Event-body shape comes from RESEARCH.md Pattern 1 + the Saxy docs; the **module/behaviour/error wrapper** copies `pure_beam.ex`. |
| Golden-byte minting toolchain (`lxml` + `xmlsec1`) | out-of-band oracle | n/a (not in repo/CI) | D-12: native toolchain never enters CI; bytes are minted out-of-band and committed. No in-repo analog because no native build step exists (intentionally — ADR-0001 pure-BEAM CI). |

---

## Metadata

**Analog search scope:** `lib/relyra/security/xml/`, `lib/relyra/security/`,
`lib/relyra/protocol/`, `lib/relyra/metadata/`, `lib/mix/tasks/compile/`, `test/security/xml/`,
`test/fixtures/security/xml/`, `priv/security_corpus.json`, `mix.exs`.
**Files scanned (read in full or targeted-grep):** `xml.ex`, `xml/pure_beam.ex`,
`signed_node.ex`, `error.ex`, `parser_path_guard.ex`, `corpus_security_test.exs`,
`corpus_gate.ex`, `mix.exs`, `signature.ex` (grep), `validation_pipeline.ex` (grep),
`priv/security_corpus.json` (parsed), `test/fixtures/security/xml/manifest.json` (parsed),
fixtures dir tree.
**Pattern extraction date:** 2026-05-23
