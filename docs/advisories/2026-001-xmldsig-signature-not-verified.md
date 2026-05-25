# RELYRA-2026-001: Relyra SAML `SignatureValue` not cryptographically verified -> authentication bypass

Status: PUBLISHED 2026-05-25 as [`GHSA-jv46-xfwm-36j7`](https://github.com/szTheory/relyra/security/advisories/GHSA-jv46-xfwm-36j7), shipped with `relyra 1.2.0`. CVE requested via GitHub's CNA flow on 2026-05-25 — identifier pending assignment (will replace the `pending` note below). Internal tracking id: `RELYRA-2026-001`.

Affected product: hex ecosystem `Erlang` [ASSUMED GitHub label], package `relyra`
Affected versions: `>= 1.0.0, < 1.2.0`
Patched version: `1.2.0`
Severity: Critical
CVSS 3.1: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (9.1 Critical)
Weaknesses: `CWE-347` (primary), `CWE-287` (companion)

## Summary

Relyra `1.0.0` and `1.1.0` accept forged SAML signatures because `SignatureValue` was not cryptographically verified before the library returned a successful authentication result.

## Details

In `1.0.0` and `1.1.0`, the XMLDSig trust boundary was incomplete. `:public_key.verify` over the exclusive-C14N canonicalized `SignedInfo` was not performed against the configured IdP certificate's public key, `DigestValue` was not recomputed over the canonicalized referenced element, and `canonicalize/2` remained an unused passthrough in the signature-verification path. The result was a structure-only acceptance path where document shape and trust-source rejection could succeed without proving the signature bytes.

## Impact

A forged `SignatureValue` carrying an attacker-controlled `NameID` can be accepted as `{:ok}`. Any relying-party application using Relyra `1.0.0` or `1.1.0` can be logged into as an arbitrary user if it trusts the affected response path.

## Patches

Relyra `1.2.0` closes the gap with real exclusive-C14N canonicalization, `:public_key.verify` against the configured IdP certificate's public key, and a constant-time `DigestValue` recompute/compare bound to the exact consumed node on both `verify/4` and `verify_metadata_root/4`.

## Workarounds

There is no safe configuration of `1.0.0` or `1.1.0`. Upgrade to `1.2.0` or later.

## Severity / CVSS

Primary severity is `Critical` with CVSS 3.1 `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`, which scores 9.1. A stricter `S:C` interpretation reaches 10.0, but this draft uses the conservative `S:U` reading aligned with comparable SAML-library advisories.

## Weaknesses

- `CWE-347`: Improper Verification of Cryptographic Signature
- `CWE-287`: Improper Authentication

`CWE-436` does not apply here because the root cause was absence of the verification primitive, not a parser differential.

## Affected Products

| Ecosystem | Package | Vulnerable range | First patched |
| --- | --- | --- | --- |
| `Erlang` [ASSUMED GitHub hex label] | `relyra` | `>= 1.0.0, < 1.2.0` | `1.2.0` |

## References

- Fix commit `2e45689` (`feat(29-03): wire real XMLDSig crypto into the [candidate] arm`)
- Fix commit `8910200` (`fix(29): close metadata trust bypass (CR-01) and pin over DER (CR-02)`)
- Gate hardening commit `07f4727` (`fix(30): harden ci.security meta-gate (AST parse, tag anchor, corpus_gate coverage)`)
- Regression proof: `test/security/xml/adversarial_crypto_test.exs`
- Regression proof: `test/relyra/metadata/auto_refresh_test.exs`
- Regression proof: `test/security/ci_gate_integrity_test.exs`
- Findings ledger cross-reference: [`docs/security_findings.md`](../security_findings.md)

## Credits

Maintainers (finder and reporter).

## CVE request

CVE requested 2026-05-25 via GitHub's "Request CVE" flow on `GHSA-jv46-xfwm-36j7`; the identifier is pending assignment by GitHub (CNA) and will be backfilled here and on the GHSA when issued.

- Internal tracking id: `RELYRA-2026-001`
- Title: `Relyra SAML SignatureValue not cryptographically verified -> authentication bypass`
- Ecosystem / package: `Erlang` / `relyra`
- Affected versions: `>= 1.0.0, < 1.2.0`
- First patched version: `1.2.0`
- CVSS 3.1: `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (9.1 Critical)
- Weaknesses: `CWE-347` primary, `CWE-287` companion
- Description: forged `SignatureValue` with attacker-controlled `NameID` can be accepted as `{:ok}`, allowing arbitrary-user login until the `1.2.0` verification fix is deployed
- Credits: maintainers
- Request mechanism: GitHub repository advisory -> Request CVE at publication time

## CHANGELOG security note

Security note for the `1.2.0` release and GitHub Release body:

> Fixed a critical XMLDSig verification gap where Relyra `1.0.0` and `1.1.0` could accept forged SAML signatures. `1.2.0` now verifies canonicalized `SignedInfo` with `:public_key.verify`, recomputes `DigestValue` in constant time on the consumed node, and applies the same guarantee to both response and metadata-root verification paths.

Release-please's conventional-commits preset renders this change under standard Features and Bug Fixes entries and does not generate a dedicated Security section. This prose lives here and in the release notes; it is not a hand-edit to `CHANGELOG.md`.
