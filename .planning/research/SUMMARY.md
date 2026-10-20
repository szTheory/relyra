# Project Research Summary

**Project:** Relyra
**Domain:** Strict SAML 2.0 SP library (Elixir/Phoenix): trust-path hardening plus adversarial and mutation testing
**Researched:** 2026-10-19
**Confidence:** HIGH for the seam inventory (code read and partially reproduced live). HIGH for StreamData. MEDIUM for mutare (a young tool).

## Executive Summary

v1.12 started as a test-only "Adversarial Twin". The architecture research ran one live oracle probe and found that `Relyra.consume_response/3` accepts a `NameID`, `Conditions`, `Audience`, or `AttributeStatement` injected outside the signed `<Assertion>`. A follow-up read-only seam audit showed this is systemic. The verified node is never bound to the consumed data, and the signature's own parts are found by loose descendant search. Several seams are standalone authentication bypasses.

The milestone is therefore re-scoped to **Trust-Path Hardening**:
1. Fix the login path.
2. Fix the logout, redirect, encrypted, and metadata paths.
3. Run property-based adversarial testing (StreamData) until two empty rounds.
4. Run mutation testing (mutare) until the score plateaus.
5. Close out with a scripted disclosure.

Nobody is known to depend on the library, so fixes fail forward on `main`.

## Seam Inventory

All entries were confirmed by reading the code. S6/S7 were reproduced live. **Bold** = standalone bypass.

| ID | Path | Seam | Location |
|----|------|------|----------|
| **S1** | login | `DigestValue`, `SignedInfo`, `SignatureValue`, and `Transforms` are found by searching the whole `<Signature>`. An attacker can replay a genuine SignedInfo/SignatureValue pair and supply their own DigestValue in `<ds:Object>`. | `pure_beam.ex:421-428` |
| **S2** | login | The Reference URI and Reference count are never checked. | `signature.ex` (no `Reference`/`URI` reads) |
| S3 | login | The signature need not be an enveloped direct child. It falls back to the first `<Signature>` anywhere, and the enveloped prune matches by value. | `pure_beam.ex:408,419`; `c14n.ex:185-202` |
| S4 | login | SignatureMethod and DigestMethod are read document-wide. The digest uses SignatureMethod's hash. CanonicalizationMethod is ignored. | `pure_beam.ex:375-376`; `signature.ex:265,278,410` |
| S5 | login | A Response-only signature is unsupported. It fails closed, so this is an interop backlog item. | `pure_beam.ex:407-445` |
| **S6** | login | `bind_signed_node/2` is a no-op, and `consumed_xml_id` is never compared. | `validation_pipeline.ex:326-328` |
| **S7** | login | All assertion fields are derived by root-wide search. | `pure_beam.ex:344-357` |
| **S8** | login | An ID-less `<Assertion>` is skipped as a candidate but still feeds the fields. | `pure_beam.ex:414-416` |
| S9 | login | InResponseTo is read only from the unsigned Response. `SubjectConfirmationData@InResponseTo` and the bearer Method are unchecked. | `pure_beam.ex:332` |
| S10 | login | Only the first Issuer anywhere is checked, never the Assertion Issuer. Status is the first StatusCode with a Value attribute anywhere. | `pure_beam.ex:329-330` |
| S11 | login | The root is never checked to be `samlp:Response`. | `pure_beam.ex:250` |
| S12 | login | Nested Advice assertions are treated as ambiguous. This fails closed and is kept as a regression row. | `pure_beam.ex:411` |
| S13 | encrypted | The plaintext splice uses `String.replace`. Nothing checks for a single Assertion root, and ambiguity is not re-checked after the re-parse. | `validation_pipeline.ex:135-173` |
| S14 | encrypted | SaxyTree byte-span tracking ignores comments, PIs, and CDATA, so a decoy can win. | `saxy_tree.ex:310-406` |
| **S15** | logout POST | Only an embedded `<Assertion>` is verified, while fields are read from the root, so any session can be terminated. Type detection uses `String.contains?`. | `pure_beam.ex:267-277`; `logout_request.ex:53-59`; `relyra.ex:399-419` |
| **S16** | logout redirect | Duplicate query parameters let the signed prefix differ from the processed parameters. | logout validator `:164-209` |
| S17 | logout | The replay key is the bare ID, not connection-prefixed. | logout validator `:87,98` |
| **S18** | metadata | entityID, SSO endpoints, certs, and validUntil are extracted by regex over the raw XML, including comments, unsigned wrappers, and KeyInfo. This violates invariant #2. | `metadata/parser.ex:57-103`; `auto_refresh.ex:70-72,529`; `pure_beam.ex:201-207` |
| S19 | guards | The pre-parse guards are case-sensitive, but Saxy rejects the variants. CVE-2017-11427 comment truncation does not apply. Kept as regression rows. | `pure_beam.ex:49,52` |
| S20 | all | Elements are matched by local name only, ignoring the namespace URI. | every `find_first`/`find_all` |

## Key Findings

### Recommended Stack
- **`stream_data` 1.4.0** (test/dev only): generate mutation op lists over genuinely signed fixtures, with integrated shrinking that yields minimal corpus rows.
- **`mutare` 0.5.1** (test/dev only, exact pin): compiles once into a metamutant and runs one fresh `mix test` OS process per mutant, matching the hollow-gate discipline. It produces JSON/SARIF score reports. The fallback is `muex`. Avoid muzak (non-commercial licence) and exavier (stale).
- No new runtime dependencies. Saxy is used test-side only, to build inputs.

### Architecture Approach
Fixes stay inside the existing seams: `pure_beam.ex` derives and binds, `signature.ex` `do_verify/4` holds the crypto, `validation_pipeline.ex` binds and checks protocol, the logout modules, and `metadata/parser.ex`. Add namespace-aware direct-child helpers next to `direct_child/2`. The harness is a twin signer (sign-then-mutate, mutate-then-resign) in `xmldsig_signer.ex`, plus generators, an oracle, and corpus promotion under `test/support/twin/`. Bounded seeded properties run in `ci.security`; deep runs and mutation runs use scheduled workflows.

### Critical Pitfalls
1. **Oracle shares bugs with the system under test.** The oracle compares against what the generator signed, never against Relyra's own parse.
2. **Shrinking invalidates the signature.** Shrink the op list, not the bytes, and re-sign after structural ops.
3. **Hollow gates.** Each new suite is its own `cmd mix test` line, with the `ci_gate_integrity_test.exs` lists updated.
4. **Killing mutants by weakening tests.** Never delete from `adversarial_crypto_test.exs` or the corpus.
5. **Tightening breaks real IdPs.** Keep the FakeIdP, `Relyra.Testing`, and Keycloak lanes green. Response-only signatures stay fail-closed rather than becoming a new acceptance path.

## Implications for Roadmap

### Phase 80: Seal the login trust path
**Addresses:** S1–S4, S6–S11, S20 (rows for S5, S12, S19). **Delivers:** structural binding, bound crypto inputs, an enforced `bind_signed_node`, and a `trust_binding` corpus suite.

### Phase 81: Seal logout, redirect, encrypted, metadata
**Addresses:** S13–S18. **Delivers:** root-bound logout signatures, duplicate-parameter rejection, a span-exact splice, and tree-derived metadata.

### Phase 82: Property-based adversarial twin
**Uses:** stream_data. **Delivers:** generators, oracle, bounded `ci.security` lane, scheduled deep run, and corpus promotion. Stops after two empty rounds.

### Phase 83: Mutation testing of the security core
**Uses:** mutare. **Delivers:** scheduled mutation lane and score trend. Stops at a plateau; survivors are recorded.

### Phase 84: Close-out and scripted disclosure
**Delivers:** one hardening evidence file, `docs/advisories/2026-002-*`, and a GHSA plus CVE request via the REST API, with batch approval.

### Research Flags
- Phase 83 needs a mutare baseline spike (custom `:parser_path_guard` compiler, function lifting).
- Phase 81's metadata rewrite must keep the AutoRefresh pinning semantics.

## Deferred
- Real-IdP fidelity corpus (STACK.md container images remain valid).
- Chaos journeys (WINDOW-29/30, audit co-commit failure, rollover refresh, clock skew).
- Customer-IT-admin journey.

## Sources
- `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md` (this directory).
- Live probe through `Relyra.consume_response/3` (2026-10-19): envelope NameID gives `{:ok}` as the attacker; envelope Conditions on an expired assertion gives `{:ok}`; envelope AttributeStatement gives injected groups.
- Read-only seam audit of `lib/` (2026-10-19), spot-checked: no Reference/URI reads in `signature.ex`, and `bind_signed_node/2` returns `:ok`.
