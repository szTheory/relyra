---
phase: 28-real-c14n-parser-foundation
verified: 2026-05-25T04:35:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification created during milestone audit closure
gaps: []
deferred:
  - "Mixed-content / inter-element-whitespace canonicalization remains a fail-closed correctness gap documented in 28-04-SUMMARY.md; it does not reopen the bypass."
---

# Phase 28: Real C14N Parser Foundation — Verification Report

**Phase Goal:** Verification can operate over a correct, canonicalized parse tree so the downstream crypto check is performed over trustworthy bytes.
**Verified:** 2026-05-25T04:35:00Z
**Status:** passed
**Re-verification:** No — initial verification report created after implementation was already complete

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | The XML seam parses SAML XML into a real structured tree, not regex string-scanning, and preserves the single-parser trust path | ✓ VERIFIED | `PureBeam.parse_safely/2` routes to `SaxyTree.parse/1` at [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:116), and metadata-root parsing uses the same tree path at [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:132). Plan 28-01 records the non-optional `saxy` dependency and `SaxyTree` contract in [28-01-SUMMARY.md](/Users/jon/projects/relyra/.planning/phases/28-real-c14n-parser-foundation/28-01-SUMMARY.md:1). |
| 2 | `canonicalize/2` produces correct exclusive C14N 1.0 bytes against an independent reference | ✓ VERIFIED | `PureBeam.canonicalize/2` delegates to the C14N engine at [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:466), and the engine implements exclusive C14N serialization at [lib/relyra/security/xml/c14n.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/c14n.ex:79). The committed GATE-02 oracle proves byte-equality in [test/security/xml/corpus_security_test.exs](/Users/jon/projects/relyra/test/security/xml/corpus_security_test.exs:63) and [28-04-SUMMARY.md](/Users/jon/projects/relyra/.planning/phases/28-real-c14n-parser-foundation/28-04-SUMMARY.md:41). |
| 3 | Hardened guards still hold on the new parser path; there is no second parser path weakening the corpus behavior | ✓ VERIFIED | Phase 28 summary evidence shows corpus/security regressions stayed green after rewiring in [28-03-SUMMARY.md](/Users/jon/projects/relyra/.planning/phases/28-real-c14n-parser-foundation/28-03-SUMMARY.md:158), and the fail-closed gate remains exercised in [test/security/xml/corpus_security_test.exs](/Users/jon/projects/relyra/test/security/xml/corpus_security_test.exs:188). |
| 4 | The canonicalized bytes are bound to the exact node consumed downstream | ✓ VERIFIED | `signed_candidates` carry the bound `:node`/`:signature_node`/`:transforms_node` handle, and `canonicalize/2` works from that bound node at [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:466). The node-binding assertion is part of GATE-02 in [test/security/xml/corpus_security_test.exs](/Users/jon/projects/relyra/test/security/xml/corpus_security_test.exs:75). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/relyra/security/xml/saxy_tree.ex` | Real parse-tree builder under the seam | ✓ VERIFIED | Landed in Phase 28 Plan 01 and referenced in [28-01-SUMMARY.md](/Users/jon/projects/relyra/.planning/phases/28-real-c14n-parser-foundation/28-01-SUMMARY.md:13). |
| `lib/relyra/security/xml/c14n.ex` | Exclusive C14N 1.0 engine with allowlisted transform support | ✓ VERIFIED | Implemented and documented in [lib/relyra/security/xml/c14n.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/c14n.ex:1). |
| `lib/relyra/security/xml/pure_beam.ex` | Seam rewired onto the tree path with bound-node canonicalization | ✓ VERIFIED | Tree parse and canonicalization delegation present at [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:116) and [lib/relyra/security/xml/pure_beam.ex](/Users/jon/projects/relyra/lib/relyra/security/xml/pure_beam.ex:466). |
| `test/fixtures/security/xml/parser_differential_and_c14n/*` + `corpus_security_test.exs` | Committed oracle and GATE-02 positive proof | ✓ VERIFIED | Documented in [28-04-SUMMARY.md](/Users/jon/projects/relyra/.planning/phases/28-real-c14n-parser-foundation/28-04-SUMMARY.md:50) and asserted in [test/security/xml/corpus_security_test.exs](/Users/jon/projects/relyra/test/security/xml/corpus_security_test.exs:63). |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SIGV-03 | 28-01, 28-02, 28-03, 28-04 | Verification uses correct exclusive C14N over a real parse tree behind the `Relyra.Security.XML` seam, with no parser/canonicalization differential and the verified signature bound to the exact node consumed | ✓ SATISFIED | Tree parsing and bound-node canonicalization are wired in `pure_beam.ex`, the exclusive C14N engine is in `c14n.ex`, and GATE-02 proves byte-equality versus the committed oracle. |

No orphaned requirements. Phase 28 carries only `SIGV-03`, and it is both claimed by the phase plans and evidenced by the committed test/provenance surface.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `28-04-SUMMARY.md` | 121-130 | Mixed-content canonicalization limitation documented as follow-up | ℹ️ Info | Fail-closed correctness/interop debt only; canonicalization rejects affected shapes rather than silently accepting forged material. |

### Human Verification Required

None. The phase success criteria are all machine-checkable through the seam implementation, committed oracle fixture, and GATE-02/security corpus tests.

### Gaps Summary

No blocking gaps. Phase 28 achieved its goal: the trust path now runs through a real parse tree and a proven exclusive-C14N engine, with canonical bytes bound to the same node the verifier consumes.

---

_Verified: 2026-05-25T04:35:00Z_  
_Verifier: Codex_
