---
phase: 28
slug: real-c14n-parser-foundation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 28 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Phase 28 replaces regex SAML XML scanning with a real saxy parse tree + a hand-rolled
> exclusive-C14N 1.0 engine, proven byte-for-byte against an independent libxml2/xmlsec1
> oracle. This is load-bearing for the SAML auth-bypass class closed on branch
> `security/xmldsig-real-verification`.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| network/IdP → seam | Untrusted raw SAML XML binary crosses into `Relyra.Security.XML`; pre-parse byte guards run before any parse. | Raw SAML XML (untrusted, attacker-influenced) |
| Hex registry → build | `saxy` trust-path dependency added to the supply chain. | Package source + pinned checksum |
| raw binary → `parse_safely/2` | DOCTYPE/ENTITY/size guards must reject DTD/entity/oversize before Saxy. | Raw XML bytes |
| parse tree → canonical bytes | Serialization downstream crypto (Phase 29) trusts as the digested/signed input. | Canonical UTF-8 bytes |
| transform params → engine | Attacker-influenced `ds:Transforms`/PrefixList can under-render namespaces or request unexpected transforms. | Transform URIs, PrefixList |
| tree → parsed_doc | Signature / ValidationPipeline / AutoRefresh trust the flat keys. | Protocol fields (issuer, status, assertions…) |
| selected handle → `canonicalize/2` | The node bound for verification (Phase 29) must equal the node canonicalized (anti-XSW). | Bound `SaxyTree.Node` |
| out-of-band oracle → committed golden | Independent reference (lxml/xmlsec1) the engine is proven against; provenance recorded. | Golden canonical bytes + PROVENANCE |
| committed golden → CI assertion | CI reads committed bytes only; native toolchain must never enter `mix ci.security`. | Committed `.c14n` bytes |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-28-01 | Tampering | parser path (Saxy outside seam) | mitigate | `parser_path_guard.ex:8-13` allowlist confines Saxy/SweetXml/xmerl to `lib/relyra/security/xml/`; wired at `mix.exs:17`. Live grep outside seam → 0 matches; `mix compile --warnings-as-errors` → exit 0. | closed |
| T-28-02 | Tampering/Info | attr-value + text infoset normalization | mitigate | `saxy_tree.ex:197-202` attr-value normalization (§3.3.3), `:205-209` line-ending (§2.11). Tests `saxy_tree_test.exs:122-141,144-176`. | closed |
| T-28-SC | Tampering | saxy hex install (supply chain) | mitigate | A1 blocking-human checkpoint (`28-01-SUMMARY.md:49-53,97-99`); non-optional `mix.exs:57`; pinned `saxy 1.6.0` + checksum `02cb4e9b…317ee` in `mix.lock:33`. | closed |
| T-28-03 | Tampering | exclusive-C14N serialization (byte-divergence) | mitigate | `c14n.ex:238-269` render; rendered-vs-in-scope stacks `:276-359`; resolved-URI sort `:387-397`; dual escaping `:422-438`; no trailing newline. Tests `c14n_test.exs` (suite green). | closed |
| T-28-04 | Tampering/Elev | enveloped-signature transform pruning | mitigate | `c14n.ex:185-205` `prune_subtree/2` value-equal removal of the specific signature. Test `c14n_transform_test.exs:63-89` (sibling survives). | closed |
| T-28-05 | Tampering | unexpected transform URI (XSLT/XPath) | mitigate | `c14n.ex:60-62,132-138,180` allowlist `{enveloped-sig, exc-c14n}` → `:canonicalization_failed`. Tests `c14n_transform_test.exs:121-145`. | closed |
| T-28-06 | Tampering | PrefixList under-rendering | mitigate | `c14n.ex:159-178` parse, `:339-350` `forced_prefixes` (+`#default`), force-rendered `:276-281`. Tests `c14n_transform_test.exs:180-223`. | closed |
| T-28-07 | Info/Tampering | XXE (DOCTYPE/ENTITY) | mitigate | `pure_beam.ex:49-53` byte guards BEFORE Saxy. Tests `pure_beam_test.exs:96-104`; corpus xxe family green. | closed |
| T-28-08 | DoS | oversized payload (billion-laughs) | mitigate | `pure_beam.ex:42-47` `max_bytes` guard → `:payload_too_large` (default 1 MiB `:29`). Test `pure_beam_test.exs:106-109`. | closed |
| T-28-09 | Spoofing/Elev | signature wrapping (XSW) | mitigate | `pure_beam.ex:251-277` single-node + dup-ID rejection; `:185-210,346-379` exact `:node` binding. Tests `pure_beam_test.exs:194-216`; node-binding `corpus_security_test.exs:86-90`. | closed |
| T-28-10 | Spoofing | document-KeyInfo trust abuse (CVE-2024-45409) | mitigate | `pure_beam.ex:168,255-261` tree-derived `key_info_trust` → `:untrusted_certificate`. Tests `pure_beam_test.exs:124-132,155-162`; cve_2024_45409 corpus family green. | closed |
| T-28-11 | Tampering/Spoof | parser differential (two paths disagree) | mitigate | `pure_beam.ex:82-246` all fields re-derived from one saxy tree; regex extractors retired. Live grep 0 matches; `pure_beam_test.exs:51-92`. | closed |
| T-28-12 | Tampering | C14N fail-open on incomplete input | mitigate | `pure_beam.ex:306-312` enveloped-without-signature → `:enveloped_signature_unresolved`; `:337-344` non-bindable fail-closed; `c14n.ex:85-97`. GATE-02 c14n row `corpus_security_test.exs:35-61` green. | closed |
| T-28-13 | Tampering | C14N byte-divergence (load-bearing) | mitigate | `corpus_security_test.exs:63-91` positive gate `out == golden`. Golden 887 bytes, last byte `0x3e`, sha256 `5d6d15c4…d7ea` matches PROVENANCE. `--only gate02_c14n` 2/0. | closed |
| T-28-14 | Tampering | self-attested correctness (oracle integrity) | mitigate | `PROVENANCE.md:40-68` dual-build cross-check (lxml 6.1.1/libxml2 2.14.6 + xmllint/libxml2 2.9.14 byte-identical) + Relyra engine as third agreeing implementation; versions, commands, sha256 recorded. | closed |
| T-28-15 | Spoofing/Elev | node/canonicalization differential (XSW) | mitigate | `corpus_security_test.exs:86-90` + `pure_beam_test.exs:194-208` assert verified handle `:node ≡` canonicalized tree node. gate02 2/0. | closed |
| T-28-16 | Tampering | native toolchain entering CI (hermeticity) | accept | `mix.exs:152-169` `ci.security` alias has no native step; live grep for python/xmlsec/lxml/xmllint/docker/libxml in `mix.exs` → none. Golden bytes committed and read by CI (D-12 / ADR-0001 pure-BEAM CI). See Accepted Risks Log. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-28-01 | T-28-16 | Golden canonical bytes are minted out-of-band (lxml + xmlsec1, Docker) and committed; CI reads the committed `.c14n` bytes only and stays pure-Elixir. Keeping the native XML toolchain out of `mix ci.security` is a deliberate hermeticity decision (D-12 / ADR-0001 pure-BEAM CI). Verified: no native step in the `ci.security` alias; golden integrity (size/last-byte/sha256) independently confirmed. | gsd-security-auditor (verification) | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 17 | 17 | 0 | gsd-security-auditor |

> 16 threats mitigated (controls present and load-bearing in code/tests) + 1 accepted-by-design
> (T-28-16, acceptance condition independently confirmed). Register authored at plan time across all
> four PLAN.md `<threat_model>` blocks; auditor verified mitigations exist (no retroactive STRIDE).
> No `## Threat Flags` sections in any 28-xx-SUMMARY (28-03-SUMMARY explicitly records none required).

### Dynamic verification (read-only, 2026-05-24)
- `mix compile --warnings-as-errors` → exit 0 (parser_path_guard clean).
- Parser-reference grep (`Saxy`/`SweetXml`/`xmerl`) outside seam roots → 0 matches.
- `mix test saxy_tree/c14n/c14n_transform/pure_beam/seam_contract` → 75 tests, 0 failures.
- `mix test corpus_security_test.exs --only security_corpus` → 6 tests, 0 failures.
- `mix test corpus_security_test.exs --only gate02_c14n` → 2 tests, 0 failures (byte-equality + node-binding).
- Golden integrity: 887 bytes, last byte `0x3e`, sha256 matches PROVENANCE.md; saxy 1.6.0 pin + checksum match.

> Out of scope (not attributed to Phase 28): `mix ci.security` is red only on 4 pre-existing
> dependency advisories (postgrex/plug/phoenix, ignored decimal GHSA) unrelated to Phase 28 code —
> tracked as a separate v1.1 dependency-bump task.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
