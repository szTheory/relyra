---
status: complete
phase: 28-real-c14n-parser-foundation
source: [28-01-SUMMARY.md, 28-02-SUMMARY.md, 28-03-SUMMARY.md, 28-04-SUMMARY.md]
started: 2026-05-24T10:18:58Z
updated: 2026-05-24T10:18:58Z
verification: auto (deterministic security library — no UI; checkpoints verified by running test suites + live demo, not manual clicking)
---

## Current Test

[testing complete]

## Tests

### 1. Clean compile + saxy dependency resolves
expected: `mix compile --warnings-as-errors` is clean under parser_path_guard; `{:saxy, "~> 1.6"}` is a non-optional dep with saxy 1.6.0 pinned in mix.lock.
result: pass
evidence: COMPILE clean; mix.exs line 57 `{:saxy, "~> 1.6"}` (non-optional); mix.lock pins saxy 1.6.0 (checksum 02cb4e9b…317ee).

### 2. SaxyTree parses real SAML XML into a normalized tree (Plan 01)
expected: `SaxyTree.parse/1` returns a Node tree with verbatim qnames, document-order attrs, inherited in-scope ns stack, and the 3 infoset-normalization layers; malformed XML returns `%Saxy.ParseError{}`.
result: pass
evidence: `mix test test/relyra/security/xml/saxy_tree_test.exs` — 16 tests, 0 failures.

### 3. Exclusive-C14N engine produces canonical bytes (Plan 02 core)
expected: `C14N.serialize/2` emits byte-exact canonical UTF-8 — visibly-utilized ns rendering (no over-render), attrs sorted by resolved URI then local, empty-element expansion, correct text/attr escaping, no trailing newline.
result: pass
evidence: `mix test c14n_test.exs c14n_transform_test.exs` — 30 tests, 0 failures (18 core + 12 transform).

### 4. Transform allowlist fails closed on unknown transforms (Plan 02 security, T-28-05)
expected: a Reference requesting any transform outside {enveloped-signature, exc-c14n} (XSLT, XPath/filter2, inclusive-C14N) is rejected fail-closed with `:canonicalization_failed`; the allowed exc-c14n transform succeeds.
result: pass
evidence: live demo — XSLT URI → `:canonicalization_failed`; exc-c14n URI → `{:ok, "<a xmlns=\"urn:x\"><b>hi</b></a>"}`. Covered by transform suite (XSLT + filter2 rejection).

### 5. Enveloped-signature pruning targets the specific ds:Signature (anti-XSW, Plan 02 D-10)
expected: enveloped-signature transform prunes the SPECIFIC supplied ds:Signature subtree (value-equal match); an unrelated sibling ds:Signature survives; nil/bare-chain = no prune.
result: pass
evidence: transform suite asserts "prune the specific Signature (sibling survives)" — included in the 30/0 c14n run.

### 6. Seam re-wired onto the tree — regex retired, malformed XML now rejected (Plan 03)
expected: `PureBeam.parse_safely/2` derives every protocol field from the saxy tree in one pass (regex extractors gone); DOCTYPE/ENTITY/size byte guards run BEFORE Saxy (XXE-before-verify); mismatched-tag XML that the old regex accepted is now rejected `:malformed_xml`.
result: pass
evidence: `mix test pure_beam_test.exs seam_contract_test.exs` — 26 tests, 0 failures. Live demo: `<Response><Issuer>oops</Response>` → `:malformed_xml` ("unexpected ending tag Response, expected Issuer").

### 7. canonicalize/2 fails closed for non-bindable handles (Plan 03 Pitfall 9, T-28-12)
expected: `canonicalize/2` over a handle bound to the exact `%Node{}` delegates to the C14N reference transform chain; a whole parsed_doc map / bare atom / handle lacking `:node` returns `{:error, :canonicalization_failed}`; an enveloped transform with an unresolved ds:Signature fails closed (`:enveloped_signature_unresolved`), never serialize-without-prune.
result: pass
evidence: GATE-02 fail-closed differential row green; node-binding + canonicalize-delegation + fail-closed hardening covered in the 26/0 pure_beam run.

### 8. Golden-byte oracle — hand-rolled engine == libxml2 byte-for-byte (Plan 04, GATE-02, SIGV-03)
expected: `parse_safely → select_signed_node → canonicalize` reproduces the committed 887-byte libxml2 golden EXACTLY (no trailing newline), and the bound node is the exact `<Assertion>` in `parsed_doc[:parse_tree]` (D-10).
result: pass
evidence: `mix test corpus_security_test.exs --only gate02_c14n` — 2 tests, 0 failures. Golden file = 887 bytes, sha256 `5d6d15c4…ad7ea` (matches PROVENANCE), last byte `0x3e` (no trailing newline).

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — all deliverables verified by running the test suites and live behavior demos]

## Notes

- **Known limitation (tracked, fail-safe, NOT a gap):** `SaxyTree.Node` carries one `:text` per element and C14N emits it before children, so mixed-content / inter-element-whitespace signed XML mis-canonicalizes vs libxml2. Impact is **rejection** (digest mismatch in Phase 29), never bypass. Tracked in STATE.md as the first follow-up for Phase 29 (ordered text+element children + a mixed-content golden).
- **`mix ci.security`:** the Plan-04 summary noted it red on 4 pre-existing deps.audit advisories; STATE.md records these were fixed in post-phase-28 cleanup (commit 520d713) and `ci.security` is now GREEN — outside Phase 28 scope, no longer outstanding.
- **Security gate:** `workflow.security_enforcement` is enabled and no `28-*-SECURITY.md` exists yet → `/gsd:secure-phase 28` must run before the phase is marked complete / advancing to Phase 29.
