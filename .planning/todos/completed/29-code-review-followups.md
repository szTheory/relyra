---
id: 29-code-review-followups
status: completed
created: 2026-05-24
completed: 2026-05-25
source: .planning/phases/29-cryptographic-xmldsig-verification/29-REVIEW.md
severity: warning
area: security
---

# Phase 29 code-review follow-ups (deferred warnings + info)

The two BLOCKERs (CR-01, CR-02) and WR-01 were fixed in-phase (commits
`8910200`, `ef44482`). These remaining items are interop / defense-in-depth —
none re-open the closed auth bypass — and are deferred to a follow-up phase.
This todo is complete as a tracking artifact because the deferral decision is
recorded, the warning set is preserved here, and it no longer represents
unfinished in-milestone execution work.

## Phase 67 item dispositions

Phase 67 reconciles these entries as planning truth only. No Phase 67 code work
was performed in `signature.ex`, `pure_beam.ex`, `auto_refresh.ex`, or
`algorithm_policy.ex`; the Phase 29/30 crypto gates remain the shipped bypass
fix. Do not treat a disposition here as evidence that the underlying hardening
work was implemented.

| Item | Disposition | Reason / evidence |
| --- | --- | --- |
| WR-02 | Deferred | Fail-closed SignedInfo prefix-list interop debt. `signed_info_prefix_list/1` still delegates to `C14N.prefix_list_from_transforms/1` over the `SignedInfo` node; future work should scope the lookup to `CanonicalizationMethod` if a real IdP needs this. This can reject otherwise-valid interop cases, not accept forged signatures. |
| WR-03 | Deferred | Reference URI to consumed-node defense-in-depth. `signed_candidates/1` still binds the consumed assertion node and the first digest inputs from the selected signature without explicitly proving `Reference/@URI == #<Assertion.ID>`. Existing duplicate-ID, signature, and digest gates stay intact; future hardening should bind the digest to the matching Reference URI. |
| WR-04 | Deferred | Fail-closed metadata enveloped-signature interop debt. Metadata-root verification still relies on the declared enveloped-signature transform for pruning; omitting it leaves the signature material in canonical bytes and causes rejection. Future work may prune or explicitly reject metadata whose Reference targets the enclosing element without the transform. |
| WR-05 | Deferred | Security-hardening follow-up for metadata trust extraction guard ordering. `extract_candidate_signing_pems/1` still scans the fetched XML before `PureBeam.parse_metadata_root_safely/2` applies byte guards; the extracted PEMs are only matched to operator-pinned fingerprints before the shared metadata-root crypto verifier runs. Phase 67 made no guard-order code change. |
| IN-01 | Deferred | Algorithm-policy refactor cleanup. RSA-SHA-2 suffix handling remains split across method allowlist enforcement and digest-atom selection/signing helpers; this is maintainability debt, not a changed policy. |
| IN-02 | Left with reason | Current schema-default safety remains: `require_signed_metadata` defaults to `true` in the Ecto schema and migration, and the refresh path verifies only when the value is exactly `true`; explicit `false` remains the rare operator override path. No Phase 67 change claims to tighten that branch. |
| IN-03 | Left with reason | No security-relevant consumer found for `render_signed_xml/1` output. The verifier consumes tree-bound `:node` canonical bytes for crypto; `:signed_xml` is retained as a legacy opaque field and redaction-sensitive surfaces drop it. Consider future removal only as compatibility cleanup. |

## Warnings

- **WR-02 — SignedInfo prefix-list mis-selection.** `signed_info_prefix_list/1`
  (`signature.ex`) calls `C14N.prefix_list_from_transforms/1` over the whole
  `SignedInfo`, which can pick a `Reference/Transforms` `InclusiveNamespaces`
  instead of `CanonicalizationMethod`'s. Scope the lookup to the
  `CanonicalizationMethod` child. Fail-CLOSED interop bug.

- **WR-03 — Reference/@URI not bound to the consumed node (XSW defense-in-depth).**
  `signed_candidates/1` (`pure_beam.ex`) binds `digest_value_b64` from the first
  Reference and `:node` to the matched element without verifying
  `Reference/@URI == #<element.ID>`. Resolve the URI and require it to match the
  bound element's `ID`; bind the digest from the matching Reference, not the
  first.

- **WR-04 — enveloped metadata signature not pruned without an explicit transform.**
  On the metadata path the bound `:node` is the whole `EntityDescriptor` with a
  direct-child `ds:Signature`; pruning only happens when the Reference declares
  the enveloped-signature transform. Prune the bound signature when the Reference
  targets the enclosing element regardless, or reject (not silently mismatch)
  metadata that omits the transform.

- **WR-05 — trust regex/extraction runs on pre-byte-guard raw XML.**
  `extract_candidate_signing_pems/1` + the trust-fingerprint step
  (`auto_refresh.ex`) run on the raw fetched binary before the
  DOCTYPE/ENTITY/`max_bytes` guards in `parse_metadata_root_safely/2`. Apply the
  byte guards as the FIRST step of `do_verify_signature/3`.

## Info

- **IN-01** — `enforce_signature_method/2` and `digest_atom_for_signature_method/1`
  (`algorithm_policy.ex`) duplicate the RSA-SHA-2 suffix logic; derive both from
  one source.
- **IN-02** — `verify_signature/3` (`auto_refresh.ex`) `true ->` clause returns
  `{:ok, :legacy_unsigned}` for any non-`true` flag value; match
  `== false` explicitly (currently safe via schema default `true, null: false`).
- **IN-03** — `render_signed_xml/1` (`pure_beam.ex`) emits unescaped attr/text for
  a legacy opaque `:signed_xml`; confirm no security-relevant consumer, consider
  dropping.

Full report: `.planning/phases/29-cryptographic-xmldsig-verification/29-REVIEW.md`
