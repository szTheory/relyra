---
phase: 29-cryptographic-xmldsig-verification
plan: 05
subsystem: security
tags: [xmldsig, crypto, metadata-root, public_key, SIGV-04, trust-anchor, pinning, one-trust-path, anti-xsw]

requires:
  - phase: 29-03
    provides: "Real :public_key.verify of canonicalized SignedInfo + constant-time DigestValue recompute in do_verify/4; public_key_from_cert_chain/1; verify_metadata_root/4 already delegating to do_verify/4 (crypto shared)"
  - phase: 29-04
    provides: "Relyra.TestSupport.XmldsigSigner (D-11) + self_signed_cert_pem/0 + FakeIdP.keypair() reuse + D-12 self-parse byte-alignment — reused to mint a genuinely-signed metadata root"
  - phase: 29-01
    provides: "Mixed-content C14N document-order fix (byte-exact canonical bytes) — precondition for signer/verifier byte-alignment over the enveloped EntityDescriptor"
provides:
  - "SIGV-04 plumbing gap (D-13) CLOSED: the metadata-root pre-parse routes through the SAME SaxyTree builder the assertion path uses (PureBeam.parse_metadata_root_safely/2), surfacing the tree-bound crypto inputs (:node / :signed_info_node / :digest_value_b64 / :signature_value_b64) — no regex-derived candidate (RESEARCH Pitfall 2 / Open Q1)"
  - "SIGV-04 PROVEN: a genuinely-signed EntityDescriptor verifies {:ok, %SignedNode{}} via the SAME do_verify primitive (verify_metadata_root → do_verify → :public_key.verify + DigestValue recompute)"
  - "Defense-in-depth PROVEN: a signature-VALID but wrong-fingerprint root is rejected by TrustAnchor.check (pinning) BEFORE the signature math; do_verify_signature/3 call order preserved (pinning FIRST)"
  - "Real crypto on the metadata path PROVEN (not pinning-alone): a post-signing entityID tamper is rejected by the Reference-digest recompute (:digest_mismatch)"
affects: [31 (disclosure — SIGV-04 is now the last metadata-bypass closed for the GHSA/CVE), 30 (assurance — FakeIdP metadata signing can reuse the enveloped-signature pattern proven here)]

tech-stack:
  added: []
  patterns:
    - "One trust path for metadata (D-04/D-13): the metadata root routes through SaxyTree.parse + a metadata-root candidate variant rooted at EntityDescriptor/EntitiesDescriptor, emitting the SAME canonical candidate shape the assertion path emits — the regex extractor is retired, no parser differential"
    - "Anti-XSW node binding (D-10) on the metadata path: the candidate :node is the EXACT EntityDescriptor/EntitiesDescriptor tree node canonicalize/2 serializes; transforms read off the bound ds:Signature"
    - "Enveloped-signature on the metadata root: because the ds:Signature is a CHILD of the referenced EntityDescriptor (unlike the assertion path where it is a sibling), the Reference carries the enveloped-signature transform so the digest is computed over the envelope with its own ds:Signature pruned"
    - "Scoped KeyInfo-trust (Rule 1 correctness fix): metadata key_info_trust is scoped to the bound ds:Signature's OWN KeyInfo (the signature's self-asserted key, rejected) — a KeyDescriptor/KeyInfo published signing cert is gated by TrustAnchor pinning, NOT a document-trust bypass"

key-files:
  created:
    - "test/security/xml/pure_beam_metadata_root_test.exs (Task 1 — metadata-root candidate shape + guards + fail-closed coverage)"
  modified:
    - "lib/relyra/security/xml/pure_beam.ex (parse_metadata_root_safely/2 + the metadata-root candidate producer; element_present?/2 nil-safe; direct_child/2 + first_attr_in/3 helpers)"
    - "lib/relyra/metadata/auto_refresh.ex (pre_parse_for_signature/1 rewired onto the tree builder; 5 dead regex helpers retired; PureBeam alias added)"
    - "test/relyra/metadata/auto_refresh_test.exs (SIGV-04 positive + full-pipeline positive + wrong-fingerprint negative + tampered-entityID negative; genuine metadata-root signer helper)"

key-decisions:
  - "key_info_trust on the metadata path is scoped to the ds:Signature's own KeyInfo, NOT any-KeyInfo-anywhere (Rule 1). The literal any-KeyInfo flag (what the retired regex did over the whole XML) would have rejected ALL real signed metadata once genuine crypto was wired, because legitimate metadata publishes its signing cert in a KeyDescriptor/KeyInfo. That cert is gated by operator pinning + the signature math — it is not a document-trust bypass. On the assertion path the only KeyInfo is the signature's, so this is the faithful semantic analogue, not a weakening."
  - "The metadata-root Reference carries the enveloped-signature transform (the assertion path does not need it). The ds:Signature is a CHILD of the EntityDescriptor envelope it covers, so the digest MUST be computed over the envelope with that ds:Signature pruned. The verifier's canonicalize/2 already does this when transforms_node requests enveloped-signature; the test signer mirrors it exactly (same engine, same node, same prune — D-12)."
  - "Bound the candidate to a DIRECT-child ds:Signature (not descendant-or-self) so the metadata envelope's OWN signature is bound, never a ds:Signature buried in a nested KeyDescriptor/EntityDescriptor (anti-XSW)."

patterns-established:
  - "Metadata-root verification reuses the assertion-path verifier verbatim (do_verify/4) over a tree-bound candidate in the SAME shape — the only divergence is the root element (EntityDescriptor/EntitiesDescriptor) and the enveloped-signature transform"
  - "Pinning-as-defense-in-depth, not pinning-alone: the wrong-fingerprint negative rejects at TrustAnchor.check BEFORE the math; the tampered-content negative rejects at the digest recompute — both gates demonstrably enforced"

requirements-completed: [SIGV-04]

duration: ~12min
completed: 2026-05-24
---

# Phase 29 Plan 05: Metadata-root cryptographic verification (SIGV-04) Summary

**The SIGV-04 plumbing gap (D-13) is closed: the metadata-root pre-parse now routes through the SAME SaxyTree builder the assertion path uses, surfacing the tree-bound crypto inputs so signed-metadata verification inherits the genuine `:public_key.verify` + DigestValue recompute wired in Plan 03 — proven by a genuinely-signed EntityDescriptor verifying `{:ok}`, a sig-valid wrong-fingerprint root rejected by pinning BEFORE the math, and a tampered-entityID rejected by the digest recompute.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-05-24T13:28Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- **`PureBeam.parse_metadata_root_safely/2` (Task 1)** — the metadata sibling of `parse_safely/2`: runs the SAME byte guards (DOCTYPE/ENTITY/size, D-09 XXE-before-verify) on the raw binary, routes the well-formed arm to the SAME `SaxyTree.parse` (D-04, one trust path — no regex, no second parser), finds the signed metadata envelope (the `EntityDescriptor`/`EntitiesDescriptor` carrying a DIRECT-child `ds:Signature`), and emits the SAME canonical candidate shape the assertion path emits — carrying the D-02 crypto inputs (`:signed_info_node` / `:digest_value_b64` / `:signature_value_b64`) plus the bound `:node`. The candidate `:node` is the EXACT envelope tree node `canonicalize/2` serializes (anti-XSW); `key_info_trust` / `duplicate_ids` are tree-derived so the shared `do_verify/4` gates inherit.
- **`pre_parse_for_signature/1` rewired (Task 2)** — replaced its regex body with a call to the Task 1 tree entry, returning the tree-bound `parsed_doc`. The `do_verify_signature/3` call order is PRESERVED exactly: `extract_candidate_signing_pems` → `TrustAnchor.check` (pinning, FIRST) → `pre_parse_for_signature` → `Signature.verify_metadata_root` with the pinned PEMs. The `:missing_signature` fail-closed behavior is kept. **5 dead regex helpers retired** (`extract_metadata_root_signature/1`, `attribute_from_fragment/2`, `first_attribute_in_fragment/3`, `extract_duplicate_ids_in_root/1`, `bound_id_from_reference/1`); `extract_candidate_signing_pems/1` (its own regex, by design) stays.
- **SIGV-04 PROVEN end-to-end** — a genuinely-signed `EntityDescriptor` (real DigestValue over the enveloped-signature-pruned envelope + real SignatureValue over the canonicalized SignedInfo, both via the verifier's OWN C14N engine, D-12) verifies `{:ok, %SignedNode{}}` via `verify_metadata_root → do_verify → :public_key.verify` + DigestValue recompute.
- **Defense-in-depth PROVEN** — a sig-VALID but wrong-fingerprint root is rejected by `TrustAnchor.check` BEFORE the signature math (`:trust_anchor_mismatch`), proving pinning is enforced first; AND a post-signing entityID tamper is rejected by the Reference-digest recompute (`:digest_mismatch`), proving the crypto is REAL (not pinning-alone).

## Task Commits

1. **Task 1: metadata-root signed-candidates producer in pure_beam** — `502417f` (feat)
2. **Task 2: rewire pre-parse onto tree builder + prove SIGV-04** — `6d4931e` (feat)

**Plan metadata:** (this commit — docs: complete plan)

## Files Created/Modified

- `lib/relyra/security/xml/pure_beam.ex` — added `parse_metadata_root_safely/2` (public seam entry, byte guards + SaxyTree), `parse_metadata_tree/1`, `build_metadata_parsed_doc/1`, `signed_metadata_root/1`, `metadata_root_candidate/5`, plus `direct_child/2` and `first_attr_in/3` helpers; made `element_present?/2` nil-safe. The assertion-path `signed_candidates/1` is untouched.
- `lib/relyra/metadata/auto_refresh.ex` — `pre_parse_for_signature/1` rewired to `PureBeam.parse_metadata_root_safely/2`; 5 dead regex helpers removed; `alias Relyra.Security.XML.PureBeam` added. The `do_verify_signature/3` call order and `key_info_trust`/`duplicate_ids` forwarding (now tree-derived inside the producer) preserved.
- `test/security/xml/pure_beam_metadata_root_test.exs` (new) — candidate-shape coverage (D-02 crypto inputs, bound `:node` is EntityDescriptor/EntitiesDescriptor, derived signature/digest methods, tree-derived key_info_trust/duplicate_ids), fail-closed (`:missing_signature` for unsigned/non-metadata roots), and guard coverage (DOCTYPE/ENTITY/oversize/non-binary), plus a document-Signature-KeyInfo → `key_info_trust: true` row.
- `test/relyra/metadata/auto_refresh_test.exs` — SIGV-04 describe block (positive via `verify_metadata_root`, full-pipeline positive via `refresh/2`, wrong-fingerprint negative via `refresh/2`, tampered-entityID negative via `verify_metadata_root`) + a genuine metadata-root signer helper (mirrors `XmldsigSigner` D-12, targets the `EntityDescriptor` envelope + enveloped-signature transform).

## Decisions Made

- **Scoped `key_info_trust` to the signature's own KeyInfo (see Deviations — Rule 1).** This is the load-bearing correctness decision: legitimate signed metadata publishes its signing cert in a `KeyDescriptor/KeyInfo`, so the retired regex's "any KeyInfo anywhere → reject" would have made SIGV-04's positive control impossible once genuine crypto was live. Scoping to the bound `ds:Signature`'s own KeyInfo rejects the document-asserted signature key (the real threat, T-29-22) while letting the operator-pinned published cert through — semantically identical to the assertion path, where the only KeyInfo IS the signature's.
- **Enveloped-signature transform on the metadata Reference.** The metadata `ds:Signature` is a CHILD of the envelope it signs (unlike assertions, where it is a sibling), so the digest must be over the pruned envelope. The verifier already prunes when `transforms_node` requests it; the test signer mirrors the exact engine/node/prune (D-12) so signer and verifier byte-align by construction.
- **DIRECT-child Signature binding.** `signed_metadata_root/1` requires the `ds:Signature` to be a direct child of the metadata envelope (not descendant-or-self) so a `ds:Signature` buried in a nested `KeyDescriptor`/`EntityDescriptor` can never be mistaken for the envelope's own signature (anti-XSW).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped metadata `key_info_trust` to the bound `ds:Signature`'s own KeyInfo**
- **Found during:** Task 2 (full-pipeline positive control returned `:untrusted_certificate`)
- **Issue:** The plan said `key_info_trust` should be tree-derived "mirroring the existing assertion logic." The literal assertion logic is `element_present?(root, "KeyInfo")` (any descendant-or-self KeyInfo). For metadata that flags the legitimate `KeyDescriptor/KeyInfo` (the published signing cert), so `do_verify` rejected EVERY genuinely-signed metadata root with `:untrusted_certificate` (`:document_keyinfo_forbidden`) — SIGV-04's positive control could never reach `{:ok}`. The retired regex had the same latent bug (`Regex.match?(~r/KeyInfo/, xml)` over the whole XML) but it was never exercised against genuine crypto.
- **Fix:** `key_info_trust: element_present?(signature_node, "KeyInfo")` — scoped to the bound `ds:Signature`'s OWN KeyInfo (the signature's self-asserted key, which MUST be rejected). A `KeyDescriptor/KeyInfo` published cert is gated by `TrustAnchor` pinning + the signature math, not a document-trust bypass. This is the faithful semantic analogue of the assertion path (where the only KeyInfo is the signature's), and the threat (T-29-22, document-KeyInfo as the SIGNATURE trust source) is still rejected — covered by the new `pure_beam_metadata_root_test.exs` `key_info_trust: true` row (KeyInfo inside the `ds:Signature`).
- **Files modified:** `lib/relyra/security/xml/pure_beam.ex` (+ made `element_present?/2` nil-safe)
- **Verification:** SIGV-04 positive `{:ok}`; the document-Signature-KeyInfo row → `key_info_trust: true`; the existing `signature_test.exs` document-KeyInfo shim rejection still green.
- **Committed in:** `6d4931e` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - correctness). No architectural change; the verifier and the `do_verify_signature/3` call order are untouched.

## Threat Register Outcomes

| Threat ID | Disposition | Realized mitigation |
|---|---|---|
| T-29-19 (metadata-root signature forgery) | mitigated | Genuine signed EntityDescriptor → `{:ok}` via the SAME `:public_key.verify` + digest-recompute primitive (do_verify/4); a forged signature would fail the math |
| T-29-20 (metadata pinning bypass — sig-valid, wrong key) | mitigated | Wrong-fingerprint negative rejects at `TrustAnchor.check` (`:trust_anchor_mismatch`) BEFORE verify_metadata_root; call order preserved (pinning FIRST). Signature is primary, pinning defense-in-depth |
| T-29-21 (parser differential regex vs tree verifier) | mitigated | Metadata root routes through `SaxyTree.parse` + the SAME candidate shape; 5 regex candidate helpers retired (one trust path, D-04) |
| T-29-22 (document KeyInfo trust on the metadata path) | mitigated | `key_info_trust` scoped to the bound `ds:Signature`'s own KeyInfo → `do_verify` `:untrusted_certificate` rejection inherits; a signature self-asserting its key is rejected |
| T-29-23 (DOCTYPE/entity/size attack on metadata XML) | mitigated | The SAME byte guards (DOCTYPE/ENTITY/size) run before Saxy inside `parse_metadata_root_safely/2`; covered by the new guard tests |
| T-29-SC (package installs) | accepted | No installs — OTP `:public_key`/`:crypto` + in-repo engine only |

## Verification Results

- `mix test test/security/xml/ test/relyra/security/xml/ --warnings-as-errors` → **114/0** (Task 1 lane)
- `mix test test/relyra/metadata/auto_refresh_test.exs test/relyra/security/signature_test.exs --warnings-as-errors` → **21/0** (Task 2 lane: SIGV-04 positive + wrong-fingerprint negative + tampered-entityID negative + shim trust gates)
- `mix test test/relyra/security/ test/security/ test/relyra/security/xml/ test/relyra/metadata/ --warnings-as-errors` (wave-merge security + metadata regression) → **243/0**
- `mix test --warnings-as-errors` (full-suite phase gate) → **540/0**
- `mix ci.security` → **EXIT 0** (`deps.audit`: "No vulnerabilities found"; Sobelow low-confidence findings are pre-existing, unrelated to this plan's files)
- `mix compile --warnings-as-errors --force` → clean (the 5 retired regex helpers leave NO dead-code warnings)
- grep confirms the regex metadata-candidate helpers are retired (only `extract_candidate_signing_pems` — its own regex, kept by design — remains)

## Issues Encountered

- **Enveloped-signature digest binding:** the first positive-control attempt computed the digest over `%{node: entity_node}` (no transform), but the verifier canonicalizes the envelope INCLUDING the child `ds:Signature` when no transform is declared → `:digest_mismatch`. Resolved by adding the enveloped-signature transform to the Reference and having both signer and verifier prune the bound `ds:Signature` before digesting (same engine/node/prune, D-12).
- **`key_info_trust` over-rejection:** see Deviation 1 (Rule 1) — the literal assertion-logic any-KeyInfo flag rejected all real signed metadata; scoped to the signature's own KeyInfo.

## Known Stubs

None — no stubbed/placeholder data paths introduced. The metadata-root candidate carries real tree nodes + real base64 crypto values; the positive control mints a real RSA signature + real digest over the canonicalized envelope.

## Next Phase Readiness

- **SIGV-04 COMPLETE:** signed-metadata verification now inherits the genuine crypto wired in Plan 03 over a tree-bound candidate; the last metadata-path auth-bypass plumbing gap (D-13) is closed. All three SIGV requirements (01/02/04) are proven; SIGV-03 shipped in Phase 28.
- **Phase 30 (assurance):** FakeIdP metadata signing can reuse the enveloped-signature pattern proven here when it emits real signed metadata fixtures.
- **Phase 31 (disclosure):** with SIGV-04 closed, the GHSA/CVE advisory can state the metadata-root bypass is fully closed (not just the assertion path).

## Self-Check: PASSED

All key files exist on disk (`lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/metadata/auto_refresh.ex`, `test/security/xml/pure_beam_metadata_root_test.exs`, `test/relyra/metadata/auto_refresh_test.exs`, `29-05-SUMMARY.md`); both per-task commits (`502417f` Task 1, `6d4931e` Task 2) are present in git history.

---
*Phase: 29-cryptographic-xmldsig-verification*
*Completed: 2026-05-24*
