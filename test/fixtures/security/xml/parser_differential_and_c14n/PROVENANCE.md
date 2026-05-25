# Golden-byte oracle provenance — `parser_differential_and_c14n`

This directory holds the **committed golden bytes** that prove Relyra's hand-rolled exclusive
XML Canonicalization 1.0 engine (`Relyra.Security.XML.C14N`, Phase 28 Plan 02), as wired through the
seam (`Relyra.Security.XML.PureBeam`, Plan 03), produces byte-exact canonical output matching an
**independent reference** (libxml2). This is the load-bearing correctness proof for SIGV-03 / ROADMAP
success #2 — a byte-divergence here would silently defeat Phase 29's `DigestValue` comparison and
re-open the SAML auth-bypass class (decision D-11/D-12).

Per D-12 / ADR-0001, the golden bytes are minted **out-of-band** (in a Docker container) and committed;
`mix ci.security` reads the committed bytes only and stays pure-Elixir (NO native toolchain in CI).

## Fixtures

| File | Bytes | sha256 |
|------|-------|--------|
| `assertion_inherited_ns.input.xml` | (input SAML Response) | — |
| `assertion_inherited_ns.c14n` | 887 | `5d6d15c4705f78c9dabe12158b14686f4c0caef98a457dc0e76dfcdddb6ad7ea` |
| `mixed_content.input.xml` | (input SAML Response, pretty-printed) | — |
| `mixed_content.c14n` | 1056 | `edb5abd058d37614f0e0eee358590ac729ba6a2821bf3e7822658caf5af3b020` |

`mixed_content.c14n` is **raw UTF-8, no BOM, NO trailing newline** (last byte `0x3e` `>`). It is the
exclusive-C14N of the signed `<Assertion>` subtree extracted from a **pretty-printed** SAML Response
(newline+indent inter-element whitespace between every child element). The `<Signature>` is a sibling of
the `<Assertion>` (not enveloped within it), so no enveloped-signature prune applies; `ds:Transforms`
absent → empty transform list → plain exclusive-C14N over the assertion subtree.

`assertion_inherited_ns.c14n` is **raw UTF-8, no BOM, NO trailing newline** (last byte `0x3e` `>` —
Pitfall 4/6). The committed golden is the exclusive-C14N of the signed `<Assertion>` subtree (the node
`PureBeam.canonicalize/2` serializes; the `<Signature>` is a sibling of the `<Assertion>`, not enveloped
within it, so no enveloped-signature prune applies — `ds:Transforms` absent → empty transform list).

## What `assertion_inherited_ns.c14n` exercises

- **Inherited namespace, visibly utilized** — `md` is declared on the ancestor `<Response>` and used by
  the `<Assertion md:tier="gold">` attribute → rendered as `xmlns:md="urn:example:md"` on the apex.
- **No over-render (Pitfall 1)** — `ext` (`urn:example:ext`) is declared on `<Response>`, inherited
  in-scope, but never used by the assertion subtree → **omitted** from the canonical output.
- **Attribute sort by resolved URI then local (Pitfall 8)** — apex emits `ID` (no-namespace, first) then
  `md:tier`; `<SubjectConfirmationData>` re-sorts to `NotOnOrAfter` before `Recipient`; `<Conditions>` to
  `NotBefore` before `NotOnOrAfter`.
- **Empty-element expansion** — `<SubjectConfirmationData .../>` → `<SubjectConfirmationData ...></SubjectConfirmationData>`.
- **Text escaping + UTF-8 (Pitfalls 5/6)** — `<AttributeValue>` text `R&D <café>` canonicalizes to
  `R&amp;D &lt;café&gt;` (`&`,`<`,`>` escaped; `café` preserved as raw UTF-8).
- **No trailing newline (Pitfall 4)**, output starts `<` and ends `>`.
- No `InclusiveNamespaces/@PrefixList` is used by this golden (PrefixList = none).

## What `mixed_content.c14n` exercises (D-09/D-10, mixed content / inter-element whitespace)

This golden is the load-bearing proof for the Phase 29 Plan 01 document-order C14N fix (D-09). The
input is a **pretty-printed** signed SAML Response — every child element of the `<Assertion>` is
separated by `\n` + indentation. Before the fix, `C14N.render_element/3` emitted `escape_text(node.text)`
*before* all children, so any inter-element whitespace mis-canonicalized vs libxml2 → `DigestValue`
mismatch on every realistic (non-whitespace-free) real-IdP document. The fix walks an ordered
`content: [{:text,_} | {:element,_}]` field in document order.

- **Mixed content / inter-element whitespace** — the `\n    ` / `\n      ` / `\n  ` text segments between
  `<Issuer>`, `<Subject>`, `<Conditions>`, `<AuthnStatement>` (and their descendants) are preserved
  **interleaved with the child elements in document order**, e.g.
  `<Assertion ...>\n    <Issuer>...</Issuer>\n    <Subject>\n      <NameID ...` — text/element/text in
  source order, NOT all text hoisted before all children.
- **Subtree extraction (tail not included)** — leading whitespace *before* `<Assertion>` and the tail
  *after* `</Assertion>` (which live in the `<Response>` parent) are NOT part of the canonicalized
  subtree; the golden starts at `<Assertion` and ends at `</Assertion>`.
- **Inherited namespace, visibly utilized** — `md` declared on `<Response>`, used by `md:tier` → emitted
  as `xmlns:md="urn:example:md"` on the apex (same Pitfall-1 behavior as the inherited-ns golden).
- **Attribute sort, empty-element expansion, text escaping, UTF-8** — same Pitfall 5/6/8 surface as the
  887-byte golden (`SubjectConfirmationData` self-closing → expanded; `R&D <café>` → `R&amp;D &lt;café&gt;`).
- **No trailing newline (Pitfall 4)**, output starts `<` and ends `>` (last byte `0x3e`).
- No `InclusiveNamespaces/@PrefixList` (PrefixList = none).

## Oracle toolchain (Docker, out-of-band)

Base image: `python:3.12-slim` (linux/arm64). `assertion_inherited_ns.c14n` minted 2026-05-23;
`mixed_content.c14n` minted 2026-05-24 against the identical toolchain (same lxml/xmllint/xmlsec1/python
versions reported below).

| Tool | Version | libxml2 |
|------|---------|---------|
| lxml | 6.1.1 (pip wheel) | **2.14.6** (lxml-bundled) |
| xmllint | libxml2-utils (Debian) | **2.9.14** (system, `20914`) |
| xmlsec1 | 1.2.41 (openssl) | (Debian system libxml2) |
| python | 3.12.13 | — |

### Cross-check (dual independent libxml2 builds + the implementation under test)

Both goldens follow the identical dual-oracle + idempotence + implementation-under-test methodology:

1. **Oracle 1 — lxml** (bundled libxml2 2.14.6): `etree.tostring(assertion, method="c14n", exclusive=True)` → the golden bytes.
2. **Oracle 2 — xmllint** (system libxml2 2.9.14, a *different* libxml2 build): `xmllint --exc-c14n` of the
   detached assertion → **byte-identical to Oracle 1** (`True`).
3. **Idempotence**: re-parsing the golden and re-canonicalizing yields the same bytes (`True`).
4. **Implementation under test** — `Relyra.Security.XML.C14N` via `PureBeam.parse_safely → select_signed_node
   → canonicalize` produces the **byte-identical** golden (verified in `corpus_security_test.exs`,
   `@tag :gate02_c14n`). This is the strongest cross-check: a hand-rolled Elixir implementation and the C
   libxml2 reference agree byte-for-byte.

| Golden | Bytes | Oracle1 == Oracle2 | Idempotent | Elixir engine == golden |
|--------|-------|--------------------|------------|-------------------------|
| `assertion_inherited_ns.c14n` | 887 | True | True | True |
| `mixed_content.c14n` (D-09/D-10) | 1056 | True | True | True |

> **libxml2-lineage note (honest caveat).** lxml, xmllint, and xmlsec1's c14n all descend from libxml2.
> The dual-tool guard the plan called for primarily protects against lxml's known
> `inclusive_ns_prefixes` API bug — **not applicable here** because this golden uses no PrefixList. The
> cross-check above uses two *different libxml2 builds* (2.14.6 vs 2.9.14) and, more importantly, an
> *entirely independent* implementation (Relyra's Elixir engine) as the third agreeing party. A future
> PrefixList golden should additionally cross-check against a non-libxml2 implementation (e.g. Apache
> Santuario) to fully neutralize the lxml caveat.

## Reproduce

```sh
# from repo root, with Docker running:
docker run --rm \
  -v "$PWD":/work -v /tmp/mint_c14n.py:/mint.py:ro \
  python:3.12-slim \
  bash -c 'apt-get update -qq >/dev/null && \
           apt-get install -y -qq --no-install-recommends xmlsec1 libxml2-utils >/dev/null && \
           pip install --quiet lxml && python /mint.py'
```

`mint_c14n.py` parses `assertion_inherited_ns.input.xml`, locates the `<Assertion>` (local name), emits
`etree.tostring(assertion, method="c14n", exclusive=True)` to `assertion_inherited_ns.c14n`, and
cross-checks against `xmllint --exc-c14n`. Minted 2026-05-23.

For `mixed_content.c14n`, swap the mount + script:

```sh
# from repo root, with Docker running:
docker run --rm \
  -v "$PWD":/work -v /tmp/mint_mixed_c14n.py:/mint.py:ro \
  python:3.12-slim \
  bash -c 'apt-get update -qq >/dev/null && \
           apt-get install -y -qq --no-install-recommends xmlsec1 libxml2-utils >/dev/null && \
           pip install --quiet lxml && python /mint.py'
```

`mint_mixed_c14n.py` parses the **pretty-printed** `mixed_content.input.xml` (whitespace deliberately
NOT stripped — the inter-element whitespace IS the bug class), locates the `<Assertion>`, emits
`etree.tostring(assertion, method="c14n", exclusive=True)` to `mixed_content.c14n` (1056 bytes), confirms
idempotence, and cross-checks `xmllint --exc-c14n` byte-for-byte. Minted 2026-05-24.
