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
