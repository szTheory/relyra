# Security Findings Ledger

Current state: `RELYRA-2026-001` is recorded as resolved (published as `GHSA-jv46-xfwm-36j7` / `CVE-2026-49454`). `RELYRA-2026-002` is fixed in Hex `1.10.2` and published as [GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x). GitHub accepted its CVE request on 2026-10-20; CVE assignment is pending (see `docs/advisories/2026-002-signed-node-not-bound-to-consumed-node.md`).

## Summary

- High and Critical findings are release blockers until remediated and regression-tested.
- Medium findings require an explicit written disposition before release.
- Low and Informational findings may be deferred only if they remain recorded with owner and revisit date.
- Every accepted fix should link the regression proof that keeps it closed.

## Findings Ledger

| Finding ID | Severity | Exploit Path | Disposition | Owner | Regression Proof | Blocker State | Revisit Date |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RELYRA-2026-001 | Critical | forged `SignatureValue` carrying an attacker-controlled `NameID` accepted as `{:ok}` -> full SAML authentication bypass | Confirmed -> Fixed in v1.1 (hex 1.2.0) | maintainers | `test/security/xml/adversarial_crypto_test.exs` (`:adversarial_crypto`) + `test/security/ci_gate_integrity_test.exs`, green under `mix ci.security` | resolved | at v1.2.0 ship / GHSA publish |
| RELYRA-2026-002 | Critical | genuine signed `<Assertion>` left intact with identity content injected OUTSIDE it accepted as `{:ok}` with the attacker's identity (XML Signature Wrapping); parallel gaps on logout/redirect/encrypted/metadata | Confirmed -> Fixed in Hex `1.10.2` (v1.12 milestone; commits `2782344`, `32ae5e6`); [GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x), CVE request accepted / assignment pending | maintainers | `test/security/xml/trust_binding_test.exs` (`:trust_binding`) + `test/security/xml/adversarial_property_test.exs` (`:adversarial_property`), green under `mix ci.security` | resolved | when GitHub assigns the requested CVE |

## Disposition Workflow

### High and Critical

- Treat High and Critical findings as release blockers.
- Do not close the finding until the fix lands, the regression proof is linked, and the reviewer packet reflects the new state.
- Record the blocker in this ledger even if the fix ships in the same phase.

### Medium

- Medium findings require explicit written disposition before release.
- Either fix in the current phase or defer with rationale, compensating controls, owner, and revisit date.
- A Medium finding without an owner or revisit date is not considered dispositioned.

### Low and Informational

- Low and Informational findings must still be recorded.
- Deferred items require scope notes, an owner, and a revisit date so the repo does not silently forget them.

## Regression Requirements

- Link every remediated finding to a regression test, corpus fixture, or generated artifact check.
- Preferred proof targets are `SECURITY_REVIEW_EVIDENCE.md`, `CONFORMANCE.md`, focused ExUnit files, or the repo security CI lane.
- When a finding changes a trust-boundary contract, update [`SECURITY_REVIEW.md`](../SECURITY_REVIEW.md) so reviewers can follow the new proof path.
