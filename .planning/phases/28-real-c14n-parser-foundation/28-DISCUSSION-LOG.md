# Phase 28: Real C14N parser foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 28-real-c14n-parser-foundation
**Mode:** assumptions
**Calibration:** minimal_decisive (config `preferences.vendor_philosophy: opinionated`)
**Areas analyzed:** Parser substrate & namespace context; Exclusive C14N engine & seam interface; GATE-02 byte-fidelity proof

## Assumptions Presented

### Parser substrate & namespace context
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Custom `Saxy.Handler` (SAX) with computed in-scope namespace stack; NOT SimpleForm | Confident | `fake_idp.ex` namespace layout; Saxy does zero ns resolution (research); `parser_path_guard.ex` confines Saxy to seam |
| `saxy` as non-optional runtime dep; usage confined to `lib/relyra/security/xml/` | Confident | absent from `mix.exs:55-71` + `mix.lock`; ADR-0001 names saxy as the parser |
| Relyra owns 3 normalization layers (ns stack, attr-value whitespace, line-endings) | Confident | research: Saxy does none; C14N presumes normalized infoset (XML 1.0 §3.3.3) |
| Full parser replacement; re-derive all protocol fields from tree; retire regex | Confident | PROJECT one-parser-path pillar; `validation_pipeline.ex` field readers enumerable |

### Exclusive C14N engine & seam interface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hand-roll exclusive C14N 1.0 (no-comments); no reusable BEAM lib | Confident | research: `esaml`/`xmerl_c14n` inclusive-only, 2019-stale, CVE-2026-28809 (XXE) |
| Full correctness surface (visibly-utilized + PrefixList, sort by resolved URI, 2 escape fns, enveloped-sig→exc-c14n, no trailing newline) | Confident | W3C exc-c14n / c14n / xmldsig specs; 8 documented divergence pitfalls |
| Keep `canonicalize/2` arity; enrich term with parse tree + ns context | Confident | `seam_contract_test` asserts callback set; `xml.ex:23-28` |
| Preserve flat `parsed_doc` keys additively | Confident | `signature.ex:139-160`, `validation_pipeline.ex:84-104`, `auto_refresh.ex` readers |
| Preserve all hardened guards; v1.0 corpus stays green; bind verified node to canonicalized element | Confident | `pure_beam.ex:24-28` guards; success criterion #4 |

### GATE-02 byte-fidelity proof
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add positive byte-equality assertion (today only fail-closed) | Confident | `corpus_security_test.exs:34-60` asserts error-type only; no golden file exists |
| Golden bytes minted out-of-band (lxml + xmlsec1 cross-check), committed w/ PROVENANCE; no CI native dep | Confident | `mix ci.security` is pure-Elixir (`mix.exs:151-164`); ADR-0001 rejected native toolchain |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## External Research

A general-purpose research agent resolved the 4 gaps the codebase could not:

- **Saxy namespace/fidelity:** Saxy performs NO namespace resolution (xmlns surfaced as raw attributes), preserves attribute source order + verbatim prefixes, offers no in-scope-ns tracking, expands entity/char refs but does NOT normalize attribute-value whitespace or (must be confirmed) line endings. → custom handler + Relyra-owned normalization layers. (Source: hexdocs.pm/saxy, github.com/qcam/saxy source)
- **Exclusive C14N 1.0 rules:** precise visibly-utilized rule, InclusiveNamespaces PrefixList semantics, namespace-before-attribute sort with attributes keyed on resolved URI, two escape functions, empty-element/whitespace/comment handling, enveloped-signature transform pruning the specific `ds:Signature` subtree then exc-c14n, no trailing newline. 8 byte-divergence pitfalls enumerated. (Sources: W3C TR/xml-exc-c14n, TR/2001/REC-xml-c14n-20010315, TR/xmldsig-core; di-mgt.com.au/xmldsig-c14n.html)
- **Build vs reuse (decision-critical):** NO credible pure-BEAM exclusive-C14N library. `esaml`/`xmerl_c14n` (DoggettCK) is inclusive-only, last released 2019, xmerl-DOM-based, and esaml has current CVE-2026-28809 (XXE). All trusted SAML stacks (ruby-saml, python3-saml/signxml) delegate to libxml2. → Relyra must hand-roll exc-c14n on Saxy (consistent with ADR-0001). (Sources: arekinath/esaml xmerl_c14n.erl; hex.pm/packages/xmerl_c14n; cna.erlef.org CVE-2026-28809)
- **Golden-byte toolchain:** lxml `etree.tostring(method="c14n", exclusive=True, inclusive_ns_prefixes=[...])` (no trailing newline), cross-checked with `xmlsec1 -x -n`/`--c14n-exc`; pin tool + libxml2 versions (lxml's static libxml2 can differ from system) and commit input + bytes + PROVENANCE. (Sources: lxml C14N API, xmlsec-c14n man page, lxml/python-xmlsec version-conflict reports)

Net effect: every flagged item upgraded to **Confident**; the build-vs-reuse question (the only VERY impactful gray area) resolved decisively toward BUILD, which ADR-0001 already mandates — so no escalation to the user was needed beyond the single confirmation gate.
