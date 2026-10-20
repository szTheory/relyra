# RELYRA-2026-002: Relyra SAML verified signature not bound to the consumed assertion -> authentication bypass (XML Signature Wrapping)

Status: Published on 2026-10-20 as [GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x).
GitHub accepted the CVE request on 2026-10-20 (HTTP 202); assignment is pending.
Internal tracking id: `RELYRA-2026-002`.

Affected product: Hex ecosystem `erlang`, package `relyra`
Affected versions: `>= 1.2.0, < 1.10.2`
Patched version: `1.10.2`
Severity: Critical
CVSS 3.1: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (9.1 Critical)
Weaknesses: `CWE-347` (primary), `CWE-287` (companion)

## Summary

Relyra `>= 1.2.0, < 1.10.2` cryptographically verifies the XMLDSig signature
(the RELYRA-2026-001 fix holds) but does not bind the *verified* node to the
*consumed* node. An attacker can keep a genuine, correctly-signed `<Assertion>`
intact and add identity, condition, or attribute content **outside** it; Relyra
verifies the real signature and then consumes the attacker's injected content.
This is XML Signature Wrapping (XSW).

## Details

`1.2.0` closed RELYRA-2026-001 by performing `:public_key.verify` over the
canonicalized `SignedInfo` and recomputing `DigestValue`. However, the trust
boundary ended at "a signature verified somewhere in the document" — it was never
tied to the structure the signature covers or to the data subsequently consumed:

- `bind_signed_node/2` was effectively a no-op; every assertion field (`NameID`,
  `Audience`, both `Conditions` times, `SubjectConfirmationData`, `SessionIndex`,
  attributes, `Issuer`) came from a root-wide search, not from the signed
  `<Assertion>`.
- The `Reference` `URI` was never checked against the candidate assertion ID, the
  `Reference` count was unchecked, and `DigestValue`/`SignatureValue`/`Transforms`
  were matched anywhere inside `<Signature>`.
- Elements were matched by local name only, ignoring the namespace URI.
- The same verified-node ≠ consumed-node gap existed on the POST logout path (an
  IdP-signed `<Assertion>` could terminate any session), the HTTP-Redirect path
  (a duplicate query parameter bypassed the signed-octet check), and the metadata
  parser (`entityID`/endpoints/certs extracted by regex over raw XML, matching
  inside comments, unsigned wrappers, and `KeyInfo`).

## Impact

A forged login `Response` that embeds a genuine signed assertion plus an injected
`<NameID>` (or `Conditions`/`AttributeStatement`) outside it can be accepted as
`{:ok}` carrying the attacker-controlled identity, logging the relying party in as
an arbitrary user. On the logout path, any IdP-signed assertion can terminate an
arbitrary session. Any application using Relyra `>= 1.2.0, < 1.10.2` on these
paths is affected.

## Patches

The v1.12 "Trust-Path Hardening" milestone binds the verified node to the
consumed node end to end:

- Login (`fix(security)` `2782344`): every field is derived by structural path
  from the single signed `<Assertion>`; the signature must be the enveloped
  direct-child `ds:Signature` with exactly one `Reference` whose `URI` is
  `"#" <> Assertion@ID`; crypto inputs are read only from that Signature's direct
  children; the digest uses the bound `DigestMethod`; `CanonicalizationMethod` is
  allow-listed; `bind_signed_node/2` enforces `consumed_xml_id == signed xml_id`;
  namespace URIs are matched; the root must be `samlp:Response`; bearer
  `SubjectConfirmation` and `SubjectConfirmationData@InResponseTo` are enforced.
- Logout / redirect / encrypted / metadata (`fix(security)` `32ae5e6`): POST
  logout binds the message root signature and rejects an embedded `<Assertion>`;
  the redirect path rejects duplicate security parameters; decrypted plaintext is
  re-parsed through the strict login binding; metadata is derived from the
  authoritative signed `EntityDescriptor` through the single XML seam (the regex
  extractor is retired, restoring the one-parse-path invariant).

## Workarounds

There is no safe configuration of an affected version. Upgrade to the patched
release.

## Severity / CVSS

Primary severity is `Critical` with CVSS 3.1
`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (9.1), the conservative `S:U`
reading aligned with RELYRA-2026-001 and comparable SAML-library advisories.

## Weaknesses

- `CWE-347`: Improper Verification of Cryptographic Signature (the signature was
  verified, but not over the consumed node — the XML Signature Wrapping class)
- `CWE-287`: Improper Authentication

## Affected Products

| Ecosystem | Package | Vulnerable range | First patched |
| --- | --- | --- | --- |
| `erlang` | `relyra` | `>= 1.2.0, < 1.10.2` | `1.10.2` |

## References

- [Published GitHub advisory GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x)
- [Patched release 1.10.2 on Hex](https://hex.pm/packages/relyra/1.10.2)

- Fix commit `2782344` (`fix(security): bind consumed SAML login fields to the verified signed assertion`)
- Fix commit `32ae5e6` (`fix(security): bind logout, redirect, encrypted, and metadata to the verified node`)
- Robustness hardening `31fe63f` (`fix(security): make the XML seam never crash on malformed input`) — a separate, lower-severity defect the adversarial twin surfaced (a truncated prolog PI made Saxy raise instead of returning a typed error); shipped in the same release
- Hardening evidence: [`.planning/milestones/v1.12-HARDENING.md`](../../.planning/milestones/v1.12-HARDENING.md)
- Regression proof: `test/security/xml/trust_binding_test.exs` (`:trust_binding`, 21 rows)
- Regression proof: `test/security/xml/adversarial_property_test.exs` (`:adversarial_property`)
- Regression proof: `test/security/xml/adversarial_crypto_test.exs` (`:adversarial_crypto`)
- Findings ledger cross-reference: [`docs/security_findings.md`](../security_findings.md)

## Credits

Maintainers (finder and reporter).

## CVE assignment

GitHub accepted the repository advisory CVE request on 2026-10-20 (HTTP 202).
No CVE ID has been assigned yet. Backfill the assigned ID after GitHub read-back;
CVE Services and NVD indexing may follow later.

- Internal tracking id: `RELYRA-2026-002`
- GHSA: [GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x)
- CVE: assignment pending (request accepted by GitHub on 2026-10-20)
- Title: `Relyra SAML verified signature not bound to the consumed assertion -> authentication bypass (XML Signature Wrapping)`
- Ecosystem / package: `erlang` / `relyra`
- Affected versions: `>= 1.2.0, < 1.10.2`
- First patched version: `1.10.2`
- CVSS 3.1: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (9.1 Critical)
- Weaknesses: `CWE-347` primary, `CWE-287` companion
- Description: a genuine signed assertion with identity content injected outside
  it is accepted as `{:ok}` with the attacker-controlled identity, allowing
  arbitrary-user login until the v1.12 binding fix is deployed
- Credits: maintainers
- Request mechanism: repository advisory REST API `POST /repos/szTheory/relyra/security-advisories/GHSA-5rj3-pwg2-fr8x/cve`; HTTP 202 Accepted

## CHANGELOG security note

Security note for the patch release and GitHub Release body:

> Fixed a critical XML Signature Wrapping gap where Relyra `>= 1.2.0, < 1.10.2`
> cryptographically verified the SAML signature but consumed identity, condition,
> and attribute content from outside the signed assertion. The release binds every
> consumed field to the single signed `<Assertion>` (and the logout, redirect,
> encrypted, and metadata paths to their verified nodes), enforces the enveloped
> single-`Reference` structure with a matching `URI`, and matches elements by
> namespace URI.

Release-please's conventional-commits preset renders this under Bug Fixes; this
prose lives here and in the release notes, not as a hand-edit to `CHANGELOG.md`.
