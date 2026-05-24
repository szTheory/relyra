# Security Review Packet

Generated from checked-in reviewer docs plus executable artifacts in this repository.

## Scope

Relyra owns the SAML trust boundary inside the library: XML parsing, signed-content trust, protocol validation, RelayState handling, metadata trust anchors and refresh, certificate lifecycle, Single Logout, audit/redaction, and the library-owned Phoenix/admin seams.

The authoritative trust-boundary map and host-app exclusions live in [`docs/security_boundary.md`](docs/security_boundary.md).

## Reviewer Assumptions

- Host-application authn/authz policy remains outside the library boundary.
- Generic Phoenix router/session policy is only in scope where Relyra defines the contract.
- Reviewer findings and dispositions are tracked in [`docs/security_findings.md`](docs/security_findings.md). The current ledger records the confirmed `RELYRA-2026-001` finding and its remediation status.

## Rerun

Run these commands from the repo root:

```bash
mix ci.security
mix ci.verify
mix relyra.conformance --check
mix relyra.security_review --check
mix test test/security/strict_default_proof_test.exs --warnings-as-errors
mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors
```

## Linked Artifacts

| Artifact | Purpose |
| --- | --- |
| [`SECURITY.md`](SECURITY.md) | Public threat model, supported algorithms, disclosure workflow, and release prerequisites. |
| [`CONFORMANCE.md`](CONFORMANCE.md) | Generated conformance and pinned CVE-regression evidence. |
| [`SECURITY_REVIEW_EVIDENCE.md`](SECURITY_REVIEW_EVIDENCE.md) | Generated strict-default and escape-hatch evidence derived from executable security state. |
| [`docs/security_boundary.md`](docs/security_boundary.md) | Reviewer scope, trust seams, and explicit host-app exclusions. |
| [`docs/security_findings.md`](docs/security_findings.md) | Current Findings Ledger and remediation disposition workflow. |

## Named Code Seams

| Claim surface | Primary seam | Proof lane |
| --- | --- | --- |
| SHA-256+ strict defaults and time-boxed SHA-1 compatibility | `lib/relyra/security/algorithm_policy.ex` | `test/security/strict_default_proof_test.exs` |
| `:public_key.verify` over canonicalized `SignedInfo`, constant-time `DigestValue` recompute on the exact consumed node, and document-provided `KeyInfo` trust rejection on `verify/4` and `verify_metadata_root/4` | `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex` | `test/security/strict_default_proof_test.exs` |
| RelayState opacity and raw-URL rejection | `lib/relyra/security/relay_state.ex` | `test/security/strict_default_proof_test.exs` |
| Metadata trust anchors, drift review, and legacy unsigned escape hatch | `lib/relyra/metadata/auto_refresh.ex` | `test/relyra/ecto/escape_hatch_audit_test.exs` |
| Attributable, redaction-safe audit evidence | `lib/relyra/ecto/audit_writer.ex` | `test/relyra/ecto/escape_hatch_audit_test.exs` |
| Redacted reviewer export bundle | `lib/relyra/diagnostic/allow_list.ex`, `lib/relyra/diagnostic.ex` | `test/relyra/ecto/escape_hatch_audit_test.exs` |

## Findings Ledger

The current Findings Ledger is [`docs/security_findings.md`](docs/security_findings.md). It is the checked-in source for external audit dispositions, including the current `RELYRA-2026-001` record and future reviewer findings.
