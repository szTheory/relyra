# Phase 29: Cryptographic XMLDSig verification - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 9 (7 modify + 2 create)
**Analogs found:** 9 / 9 (every file has an in-repo analog; the crypto math itself is OTP-API, see Shared Patterns)

> Read order for the planner: this phase is a **wiring** phase. The crypto is ~6 OTP calls (Shared Patterns); the real work is (1) the C14N mixed-content order fix, (2) D-02 field extraction in `pure_beam.ex`, (3) the crypto in `signature.ex`'s `[candidate]` arm, (4) the metadata pre-parse upgrade, (5) the D-11 signer + golden. Each `## Pattern Assignments` entry names the EXACT analog lines to copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/security/signature.ex` (MODIFY — bypass site) | service (trust primitive) | request-response (verify) | itself (`verified_signed_node/4` arm) + `certificate_facts.ex` (PEM idiom) | exact (self) |
| `lib/relyra/security/xml/pure_beam.ex` (MODIFY — D-02 extract) | service (parser/extractor) | transform | itself (`signed_candidates/1`, `derive_attributes/1`) | exact (self) |
| `lib/relyra/security/xml/c14n.ex` (MODIFY — Option-a order) | utility (serializer) | transform | itself (`render_element/3`) | exact (self) |
| `lib/relyra/security/xml/saxy_tree.ex` (MODIFY — `content` field) | model (parse-tree node) | event-driven (SAX) | itself (`Node` struct + `handle_event`) | exact (self) |
| `lib/relyra/security/algorithm_policy.ex` (MODIFY — URI→atom) | config (policy) | transform (lookup) | itself (`enforce_signature_method/2`) | exact (self) |
| `lib/relyra/security/signed_node.ex` (MODIFY — maybe carry fields) | model (struct) | n/a | itself | exact (self) |
| `lib/relyra/metadata/auto_refresh.ex` (MODIFY — SIGV-04 plumbing) | service (pre-parse) | transform | `pure_beam.ex` `signed_candidates/1` (target shape) + itself (`pre_parse_for_signature/1`) | role-match |
| `test/support/` OR `lib/relyra/test_support/` D-11 signer (CREATE) | test-support (signer) | transform | `fake_idp.ex` (keypair + structure-only sign) | role-match |
| `test/fixtures/.../parser_differential_and_c14n/<mixed>.{input.xml,c14n}` + PROVENANCE.md (CREATE) | test (golden fixture) | file-I/O (byte oracle) | `assertion_inherited_ns.{input.xml,c14n}` + its PROVENANCE.md | exact |

---

## Pattern Assignments

### `lib/relyra/security/signature.ex` (service, request-response) — THE bypass site (D-01)

**Analog:** the file itself — extend `verified_signed_node/4`'s `[candidate]` arm. PEM→pubkey borrows the `certificate_facts.ex` idiom.

**Current bypass arm to REPLACE** (`signature.ex:167-175`) — returns `{:ok}` with ZERO crypto:
```elixir
[candidate] ->
  {:ok,
   %SignedNode{
     xml_id: Map.get(candidate, :xml_id),
     xpath: Map.get(candidate, :xpath),
     signed_xml: Map.get(candidate, :signed_xml, ""),
     signature_method: signature_method,
     digest_method: digest_method
   }}
```
The crypto goes BETWEEN matching `[candidate]` and building `%SignedNode{}`: run sig-math + digest-check, return `{:error, %Error{}}` on any failure, only build `%SignedNode{}` when both pass. All gates in `do_verify/4` (`signature.ex:108-134`) and `verify_algorithms_and_candidates/3` (`signature.ex:137-151`) stay and run BEFORE this arm — do NOT touch them.

**Typed-error construction pattern** (copy the existing `Error.new` shape used throughout, e.g. `signature.ex:121-130`):
```elixir
{:error,
 Error.new(
   :digest_mismatch,                                   # new atom (D-08)
   "Recomputed Reference digest does not match DigestValue",
   Map.merge(details, %{reason: :digest_mismatch})
 )}
```
`details` is already in scope (the `details` arg threaded from `connection_details/1`). New atoms `:digest_mismatch` and `:unsupported_signature_algorithm` need no `Error` change — `error.ex:6-7` accepts any atom `type`.

**PEM → public-key extraction** — copy the `pem_decode` + try/rescue idiom from `certificate_facts.ex:26-47`, then add `pkix_decode_cert(der, :otp)` → SPKI. The analog's exact shape to mirror (`certificate_facts.ex:26-47`):
```elixir
defp pem_entry(pem) do
  case :public_key.pem_decode(pem) do
    [entry | _rest] -> {:ok, :public_key.pem_entry_decode(entry)}
    [] -> {:error, Error.new(...)}
  end
rescue
  _error -> {:error, Error.new(...)}        # malformed PEM/DER -> typed error, NEVER a raise
end
```
For D-04 the new helper takes the cert DER (entry element 1), then `:public_key.pkix_decode_cert(der, :otp)` → `element(8, tbs)` = `{:OTPSubjectPublicKeyInfo, _algid, pubkey}` where `pubkey` is the `:RSAPublicKey` record directly. Map any rescue to `:untrusted_certificate` (RESEARCH §2). NOTE the analog's `validity/1` (`certificate_facts.ex:49-50`) uses POSITIONAL ASN.1-record destructuring — Assumption A4 flags `element(8, tbs)` may prefer the named `pubkey_cert_records.hrl` accessor for resilience; planner decides.

**Sig-math** (D-03, RESEARCH §1): `C14N.serialize(signed_info_node, prefix_list: ...)` → `Base.decode64(sig_b64)` → `:public_key.verify(c14n, digest_atom, sig, pubkey)` wrapped in `try/rescue _ -> false` (Pitfall 3: verify RAISES on a malformed KEY, returns false on a bad signature). `Base.decode64/2` returns `:error` on bad base64 → `:invalid_signature`. NOTE: this file does not yet alias `Relyra.Security.XML.C14N` (only `AlgorithmPolicy`, `SignedNode`, `Error` at `signature.ex:4-6`) — add the alias.

**Digest-check** (D-05, RESEARCH §3): reuse the EXISTING `PureBeam.canonicalize/2` path over the bound `:node` (already wired, `pure_beam.ex:294-330`) for `canonical_reference_bytes`, then `:crypto.hash(digest_atom, bytes)`, **length-guard** `byte_size(recomputed) == byte_size(declared)` BEFORE `:crypto.hash_equals/2` (Pitfall 4 — it raises on unequal lengths) → `:digest_mismatch` on mismatch.

---

### `lib/relyra/security/xml/pure_beam.ex` (service, transform) — surface D-02 fields

**Analog:** the file itself — `signed_candidates/1` (`pure_beam.ex:185-210`) builds the candidate map; extend it. Field extraction uses the existing private helpers `find_first/2`, `attr/2`, `trimmed_text/1`.

**Candidate-map build to EXTEND** (`pure_beam.ex:197-207`) — today carries `:node`/`:signature_node`/`:transforms_node` but NOT the base64 values or SignedInfo:
```elixir
assertion_id ->
  [
    %{
      xml_id: assertion_id,
      xpath: "/Response/Assertion[#{index}]",
      signed_xml: render_signed_xml(assertion),
      node: assertion,
      signature_node: signature_node,
      transforms_node: transforms_node
      # ADD (D-02): signed_info_node, digest_value_b64, signature_value_b64
    }
  ]
```

**Field-derivation idiom to copy** — `signed_candidates/1` already finds the `signature_node` via `find_first(root, "Signature")` (`pure_beam.ex:186`); add sibling lookups off it:
```elixir
signed_info_node    = if signature_node, do: find_first(signature_node, "SignedInfo"), else: nil
digest_value_b64    = digest_value_text(signature_node)      # trimmed_text of ds:DigestValue (D-02)
signature_value_b64 = signature_value_text(signature_node)   # trimmed_text of ds:SignatureValue (D-02)
```
The text-extraction helper to mirror is `trimmed_text/1` (`pure_beam.ex:459`: `String.trim(node.text)`) applied to `find_first(signature_node, "DigestValue")` / `find_first(signature_node, "SignatureValue")`. Pattern reference for finding-and-mapping a child by local name: `derive_attributes/1` (`pure_beam.ex:228-246`).

**Carry-through in `select_candidate/1`** (`pure_beam.ex:355-369`): the handle map built there must additively carry the three new keys (same pattern as the existing `node:`/`signature_node:`/`transforms_node:` lines, `pure_beam.ex:366-368`) so `signature.ex` can read them off the handle.

**Do NOT touch** the derived-view helpers `first_text`/`all_texts`/`trimmed_text` (`pure_beam.ex:443-459`) — D-09 keeps them working against the new `content` field as a derived `:text`.

---

### `lib/relyra/security/xml/c14n.ex` (utility, transform) — Option-a document-order walk (D-09/D-10)

**Analog:** the file itself — `render_element/3` (`c14n.ex:238-269`). This is the HARD precondition (D-10): the bug emits `node.text` BEFORE all children.

**The buggy emit order to FIX** (`c14n.ex:253-268`):
```elixir
child_iodata =
  node.children
  |> Enum.map(fn child -> render_element(child, new_rendered, []) end)

[
  "<", node.qname, ns_iodata, attr_iodata, ">",
  escape_text(node.text),    # <-- BUG: all text dumped before ALL children
  child_iodata,
  "</", node.qname, ">"
]
```
**Fix (D-09 Option-a):** replace `escape_text(node.text), child_iodata` with a single document-order walk over the new `content: [{:text, _} | {:element, _}]` field — `{:text, t} -> escape_text(t)`, `{:element, child} -> render_element(child, new_rendered, [])`. The ns/attr rendering above the content (`c14n.ex:238-252`) is UNCHANGED. `bindable?/1` (`c14n.ex:226-229`) must additionally accept `is_list(content)` if the engine reads `content` (planner: keep `:text`/`:children` as derived so `bindable?` can stay, or add the check — consistent with the Node change).

**Regression to keep green:** the 887-byte exclusive-C14N golden (`corpus_security_test.exs:65-91`, `@tag :gate02_c14n`) must stay byte-identical (it is whitespace-free so it is unaffected by the order fix — verify, don't assume).

---

### `lib/relyra/security/xml/saxy_tree.ex` (model, event-driven SAX) — ordered `content` field (D-09)

**Analog:** the file itself — the `Node` struct (`saxy_tree.ex:54-80`) and the SAX `handle_event` callbacks.

**Struct to EXTEND** (`saxy_tree.ex:62-69`):
```elixir
@enforce_keys [:qname, :prefix, :local]
defstruct qname: nil, prefix: "", local: nil,
          attrs: [], ns: %{}, children: [], text: ""
          # ADD (D-09): content: []  (ordered [{:text, binary} | {:element, t()}])
```
Update the `@type t` (`saxy_tree.ex:71-79`) and the moduledoc tree-node-shape contract (`saxy_tree.ex:33-49`) to match.

**SAX handlers to update (build `content` in document order):**
- `handle_event(:characters, ...)` / `handle_event(:cdata, ...)` (`saxy_tree.ex:129-133`) → `append_text/2` (`saxy_tree.ex:160-167`): append `{:text, normalized}` to `content` (in addition to / deriving the flat `:text`).
- `handle_event(:end_element, ...)` (`saxy_tree.ex:136-147`): when folding `finished` into the parent, append `{:element, finished}` to the parent's `content` (alongside the existing `children: [finished | parent.children]` at `saxy_tree.ex:141`).
- `finalize_node/1` (`saxy_tree.ex:156-158`): reverse `content` too (children are head-accumulated then reversed — apply the SAME reverse to `content`).

**Derived views (D-09):** keep `:text` = concatenation of `{:text, _}` segments and `:children` = the `{:element, _}` segments, so `pure_beam.ex` helpers (`first_text`/`all_texts`/`trimmed_text`) and the existing C14N attr/ns logic are unchanged. ~55 LOC total (D-09 estimate).

---

### `lib/relyra/security/algorithm_policy.ex` (config, lookup) — URI→digest-atom + ECDSA fail-closed (D-06/D-07)

**Analog:** the file itself — it already owns the allowlist and `enforce_signature_method/2` (`algorithm_policy.ex:74-90`). Add a pure lookup function.

**Allowlist context** (`algorithm_policy.ex:32-44`) — note ECDSA URIs are CURRENTLY allowed (`ecdsa-sha256/384/512`, lines 36-38), so D-07's explicit `:unsupported_signature_algorithm` reject is mandatory (Pitfall 5: otherwise ECDSA fails OPEN).

**New function to add** (D-06/D-07, RESEARCH §4) — mirror the `String`-predicate style already used in `method_allowed?`/`enforce_sha1_policy`:
```elixir
def digest_atom_for_signature_method(uri) do
  cond do
    String.ends_with?(uri, "rsa-sha256") -> {:ok, :sha256}
    String.ends_with?(uri, "rsa-sha384") -> {:ok, :sha384}
    String.ends_with?(uri, "rsa-sha512") -> {:ok, :sha512}
    String.contains?(uri, "ecdsa")       -> {:error, :unsupported_signature_algorithm}  # D-07 fail-closed
    true                                 -> {:error, :unsupported_signature_algorithm}
  end
end
```
The error-construction analog if a full `%Error{}` is wanted (not a bare atom) is `deprecated_algorithm/1` (`algorithm_policy.ex:140-150`) — same `Error.new(type, msg, %{algorithm: ..., algorithm_type: ...})` shape.

---

### `lib/relyra/security/signed_node.ex` (model) — carry new fields IF needed

**Analog:** the file itself (`signed_node.ex:4`). Today: `defstruct [:xml_id, :xpath, :signed_xml, :signature_method, :digest_method]`. Only extend if the planner decides the verified `%SignedNode{}` should carry crypto-result metadata (e.g. verified-digest). The crypto returns `{:ok, %SignedNode{}}` unchanged on success per the seam contract — likely NO change required. Keep `@type t` (`signed_node.ex:6-12`) in sync if a field is added.

---

### `lib/relyra/metadata/auto_refresh.ex` (service, transform) — SIGV-04 plumbing upgrade (D-13, hard dependency)

**Analog:** TARGET shape = `pure_beam.ex` `signed_candidates/1` (`pure_beam.ex:185-210`); CURRENT regex impl = this file's `pre_parse_for_signature/1` (`auto_refresh.ex:197-238`).

**The gap (Pitfall 2):** the metadata candidate built at `auto_refresh.ex:215-220` carries ONLY `:xml_id`/`:xpath`/`:signed_xml` (regex-derived) — none of the tree-bound fields the new crypto reads:
```elixir
signed_candidates: [
  %{
    xml_id: bound_id,
    xpath: xpath,
    signed_xml: signed_xml     # <-- regex-extracted; NO :node, :signed_info_node, base64 values
  }
],
```
Wiring crypto into the shared `do_verify/4` makes this path fail-CLOSED (good) but SIGV-04's positive control can never reach `{:ok}` until the candidates carry `:node`/`:signed_info_node`/`:digest_value_b64`/`:signature_value_b64`.

**Recommended fix (RESEARCH Open Q1, "one trust path"):** route the metadata root through `SaxyTree.parse` + a metadata-root variant of `signed_candidates/1` (rooted at `EntityDescriptor`/`EntitiesDescriptor` instead of `Response/Assertion`) so it produces the SAME candidate shape `pure_beam.ex` produces — rather than extending the regex extractor (which re-introduces a parser differential). The call site to preserve is `do_verify_signature/4` (`auto_refresh.ex:144-159`): `TrustAnchor.check/2` (pinning, `auto_refresh.ex:153`) still runs BEFORE `verify_metadata_root` (`auto_refresh.ex:155-156`) — pinning is defense-in-depth, signature math is primary (D-13). Keep `key_info_trust`/`duplicate_ids` forwarding (`auto_refresh.ex:226-227`).

---

### D-11 genuine XMLDSig signer (CREATE, test-support) — promotable to FakeIdP in Phase 30

**Analog:** `lib/relyra/test_support/fake_idp.ex` — the RSA-2048 keypair generator (`fake_idp.ex:85-95`) and the structure-only `sign/2` (`fake_idp.ex:68-73`) + `response_xml/2` (`fake_idp.ex:103-136`).

**Location (Claude's Discretion):** two homes exist, with a tradeoff the planner must resolve:
- `lib/relyra/test_support/fake_idp.ex` — compiled in ALL envs, prod-guarded via `ensure_not_prod!/0` (`fake_idp.ex:97-101`). The keypair lives here. D-12 says the signer must be PROMOTABLE into `FakeIdP` → co-locating (or a sibling `Relyra.TestSupport.*` module) makes promotion trivial.
- `test/support/` — test-env ONLY (`mix.exs:43` `elixirc_paths(:test)` adds `test/support`; existing members: `conformance_fixtures.ex`, `fake_connection_resolver.ex`, `migration_case.ex`). Cleaner test-scoping but a Phase-30 promotion = a move.
- **Recommendation:** put it under `Relyra.TestSupport.*` (the `lib/relyra/test_support/` home) so it shares `FakeIdP.keypair()` and promotes in-place (D-12), keeping `ensure_not_prod!` discipline.

**Keypair reuse (D-11, do NOT generate a second):** the analog at `fake_idp.ex:85-95`:
```elixir
defp ensure_keypair! do
  case :persistent_term.get(@persistent_term_key, :missing) do
    :missing ->
      generated = :public_key.generate_key({:rsa, 2048, 65_537})
      :persistent_term.put(@persistent_term_key, generated)
      generated
    keypair -> keypair
  end
end
```
Consume it via `FakeIdP.keypair()` (`fake_idp.ex:77-83`) → the `:RSAPrivateKey` record for `:public_key.sign/3`.

**What the analog OMITS (the gap to fill, D-11):** `response_xml/2` (`fake_idp.ex:126-131`) emits a `<Signature>` with an EMPTY `<SignedInfo>` (no `ds:DigestValue`, no `ds:SignatureValue`); `sign/2` (`fake_idp.ex:72`) only `Base.encode64`s the whole XML. There is NO genuine signature anywhere in the repo (grep-confirmed). The new signer must (RESEARCH §5):
1. Build Response/Assertion XML (whitespace-free OR rely on the D-09 fix landing first — Assumption A2).
2. C14N the referenced Assertion (`PureBeam.canonicalize/2`, enveloped-sig + exc-c14n) → `:crypto.hash(:sha256, bytes)` → `Base.encode64` = real `ds:DigestValue`.
3. Build `SignedInfo` embedding that DigestValue; `C14N.serialize/2` it.
4. `Base.encode64(:public_key.sign(c14n_signed_info, :sha256, private_key))` = real `ds:SignatureValue`.
5. Configured `cert_chain` for the control = PEM of that keypair's self-signed cert.

**CRITICAL (D-12, anti-pattern):** canonicalize with the SAME `C14N` engine the verifier uses — a second divergent signer would make the positive control pass for the wrong reason.

---

### Mixed-content golden fixture (CREATE) — `test/fixtures/security/xml/parser_differential_and_c14n/`

**Analog:** the EXISTING Phase-28 golden trio in the SAME directory:
- `assertion_inherited_ns.input.xml` (input)
- `assertion_inherited_ns.c14n` (887 bytes, raw UTF-8, no BOM, no trailing newline, last byte `0x3e`)
- `PROVENANCE.md` (the discipline doc)

**Fixture-load + byte-equality pattern to copy** — `corpus_security_test.exs:65-91` (`@tag :gate02_c14n`):
```elixir
input  = File.read!(Path.join(@c14n_fixtures, "assertion_inherited_ns.input.xml"))
golden = File.read!(Path.join(@c14n_fixtures, "assertion_inherited_ns.c14n"))
assert {:ok, parsed_doc}  = PureBeam.parse_safely(input, [])
assert {:ok, signed_node} = PureBeam.select_signed_node(parsed_doc, [])
assert {:ok, %{canonical_xml: out}} = PureBeam.canonicalize(signed_node, [])
assert out == golden                         # byte-for-byte
refute String.ends_with?(out, "\n")          # no trailing newline (Pitfall 4)
```
Add a NEW `@tag :gate02_c14n` test asserting the new mixed-content golden is byte-equal (this is the test that PROVES the D-09 Option-a fix). `@c14n_fixtures` is already bound (`corpus_security_test.exs:8`).

**PROVENANCE.md to mirror:** copy the structure of the existing PROVENANCE.md (fixtures table with bytes+sha256, "what this golden exercises", Docker oracle toolchain table, dual-libxml2 cross-check, Reproduce block). The NEW golden's job is to exercise **inter-element whitespace / mixed content** (the exact bug class D-09 fixes) — minted out-of-band in Docker (lxml 6.1.1 / libxml2 2.14.6 + xmllint cross-check), committed as raw bytes; CI reads bytes only (D-12). The existing PROVENANCE explicitly flags that a mixed-content golden is the natural next addition.

---

## Shared Patterns

### Crypto primitive (OTP-API — has no in-repo analog, this phase introduces it)
**Source:** OTP-bundled `:public_key` / `:crypto` (validated end-to-end on OTP 28, RESEARCH §1-§3).
**Apply to:** `signature.ex` `[candidate]` arm; the D-11 signer (sign side).
```elixir
# verify (D-03):  :public_key.verify(c14n_signed_info, :sha256, sig_bytes, rsa_pubkey) -> true | false
# sign  (D-11):   :public_key.sign(c14n_signed_info, :sha256, rsa_privkey)             -> der_sig
# pubkey (D-04):  :public_key.pkix_decode_cert(der, :otp) -> element(8) -> :RSAPublicKey
# digest (D-05):  :crypto.hash(:sha256|:sha384|:sha512, ref_bytes)
# compare (D-05): byte_size guard THEN :crypto.hash_equals(a, b)   # raises on unequal len (Pitfall 4)
# decode:         Base.decode64/2 -> {:ok, _} | :error              # :error => typed reject
```

### Fail-closed try/rescue around crypto/decode (Pitfall 3)
**Source:** `certificate_facts.ex:26-47` (`pem_entry/1` `rescue` arm).
**Apply to:** every PEM-decode, `pkix_decode_cert`, and `:public_key.verify` call on the trust path.
```elixir
... crypto/PEM call ...
rescue
  _error -> {:error, Error.new(:untrusted_certificate, "...", %{reason: ...})}  # NEVER let a raise escape
end
```
`:public_key.verify/4` returns `false` (no raise) for a bad signature but RAISES on a malformed KEY → wrap the verify in `try/rescue _ -> false` (RESEARCH §1 `safe_verify`).

### Typed-error contract (the seam invariant)
**Source:** `error.ex:6-7` (accepts ANY atom `type`) + `Error.new/3` usages throughout `signature.ex` (e.g. `signature.ex:121-130`).
**Apply to:** all new rejection paths. Contract: `{:ok, %SignedNode{}} | {:error, %Relyra.Error{type: <named>}}`.
New atoms (D-08): `:digest_mismatch`, `:unsupported_signature_algorithm` (new); `:invalid_signature`, `:untrusted_certificate`, `:canonicalization_failed` (reuse existing). Planner discretion: add the two new atoms to the `xml_error_type` union doc in `xml.ex:8-21` if that is the seam convention (the union currently lists `:invalid_signature`/`:untrusted_certificate`/`:canonicalization_failed` but NOT `:digest_mismatch`/`:unsupported_signature_algorithm`).
`Error.redact_details/1` (`error.ex:39-48`) already drops `:signed_xml` and truncates >100-byte binaries — new details maps inherit this (do NOT log raw signature/digest bytes unredacted).

### Telemetry span (automatic — no new wiring)
**Source:** `signature.ex:18-33` (verify/4) and `signature.ex:75-90` (verify_metadata_root/4).
**Apply to:** nothing new — both entry points already wrap `do_verify/4` in `Relyra.Telemetry.span([:signature, :verify], ...)` and surface `error.type` as `error_code`. New error types flow through automatically.

### Tree-bound candidate map (anti-XSW, single trust path)
**Source:** `pure_beam.ex` `signed_candidates/1` (`pure_beam.ex:185-210`) — the canonical candidate shape.
**Apply to:** the D-02 extension (assertion path) AND the `auto_refresh.ex` metadata pre-parse upgrade (must converge on this SAME shape so both paths feed `do_verify/4` identically). The crypto consumes the EXACT bound `:node` C14N serializes (no differential).

---

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| (none) | — | — | Every file has an in-repo analog. The crypto MATH (`:public_key.verify`, `:crypto.hash_equals`) has no in-repo analog because it is the net-new capability this phase introduces — it is OTP-API (Shared Patterns), proven end-to-end on OTP 28 in RESEARCH (§1-§3). ADR-0001 mandates this pure-BEAM OTP surface; there is no library to copy from and none should be added. |

---

## Metadata

**Analog search scope:** `lib/relyra/security/**`, `lib/relyra/security/xml/**`, `lib/relyra/ecto/**`, `lib/relyra/metadata/**`, `lib/relyra/test_support/**`, `test/support/**`, `test/fixtures/security/xml/**`, `test/security/**`, `test/relyra/security/**`.
**Files scanned (read in full or targeted):** `signature.ex`, `certificate_facts.ex`, `saxy_tree.ex`, `algorithm_policy.ex`, `c14n.ex`, `fake_idp.ex`, `pure_beam.ex` (targeted: 155-274, 288-344, 420-494), `auto_refresh.ex` (targeted: 144-258), `signed_node.ex`, `error.ex`, `xml.ex`, `corpus_security_test.exs` (1-95), `PROVENANCE.md`, plus greps over `signature_test.exs`/`signed_node_binding_test.exs`/`mix.exs`.
**Pattern extraction date:** 2026-05-24

## PATTERN MAPPING COMPLETE

**Phase:** 29 - Cryptographic XMLDSig verification
**Files classified:** 9 (7 modify + 2 create)
**Analogs found:** 9 / 9

### Coverage
- Files with exact analog (self / same-directory fixture): 7
- Files with role-match analog: 2 (`auto_refresh.ex` → `pure_beam.ex` candidate shape; D-11 signer → `fake_idp.ex`)
- Files with no analog: 0 (crypto math is OTP-API, intentionally no library analog per ADR-0001)

### Key Patterns Identified
- **The bypass is ONE arm:** the entire auth-bypass lives in `signature.ex:167-175`'s `[candidate]` arm; all trust GATES already run before it (`do_verify/4` cond + `verify_algorithms_and_candidates/3`) and stay untouched — the crypto slots in between matching the candidate and building `%SignedNode{}`.
- **PEM idiom is already in-repo:** `certificate_facts.ex:26-47` is the exact `pem_decode` + try/rescue pattern to copy; D-04 just adds `pkix_decode_cert(der, :otp)` → SPKI on top.
- **Mixed-content fix is surgical + the gating precondition:** the bug is `escape_text(node.text)` emitted before `child_iodata` at `c14n.ex:263-264`; D-09 Option-a is a document-order walk over a new `content` field on the `Node` struct (`saxy_tree.ex:62-69`), ~55 LOC, with `:text`/`:children` kept as derived views so no downstream helper changes.
- **Two convergent candidate producers:** `pure_beam.ex` `signed_candidates/1` is the canonical tree-bound shape; `auto_refresh.ex` `pre_parse_for_signature/1` is regex-only and MUST be upgraded to the same shape (SIGV-04 hard dependency, RESEARCH Pitfall 2) — recommend routing through `SaxyTree.parse` for one trust path.
- **Golden + signer fixtures have exact templates:** the new mixed-content golden mirrors the `assertion_inherited_ns.{input.xml,c14n}` + PROVENANCE.md trio and the `corpus_security_test.exs:65-91` byte-equality test; the D-11 signer extends `fake_idp.ex` (reusing its RSA-2048 keypair, filling the `DigestValue`/`SignatureValue` it currently omits at `fake_idp.ex:126-131`).

### File Created
`/Users/jon/projects/relyra/.planning/phases/29-cryptographic-xmldsig-verification/29-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Every file the planner will assign has a concrete analog with file:line excerpts; the crypto primitive is documented as the OTP-API Shared Pattern with the exact verified call shapes. Recommended sequence (from RESEARCH): (1) D-09 C14N Option-a + mixed-content golden, (2) D-02 `pure_beam.ex` extraction, (3) crypto in `signature.ex` `do_verify` arm, (4) `auto_refresh.ex` SIGV-04 plumbing upgrade, (5) D-11 signer + positive/negative controls — keeping the existing trust-gate tests and 887-byte golden green throughout.
