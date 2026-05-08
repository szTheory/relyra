# Security Review Evidence

Generated from executable security defaults and checked-in proof lanes in this repository.

## Rerun Commands

- `mix ci.security`
- `mix ci.verify`
- `mix relyra.conformance --check`
- `mix relyra.security_review --check`
- `mix test test/security/strict_default_proof_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors`

## Strict Default Evidence

| claim | executable state | seam | proof command | artifact |
| --- | --- | --- | --- | --- |
| strict default signature policy | 6 allowed signature methods; legacy SHA-1 override absent by default | `Relyra.Security.AlgorithmPolicy.default/0` | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |
| strict default digest policy | 3 allowed digest methods; SHA-1 rejected unless time-boxed | `Relyra.Security.AlgorithmPolicy.enforce_digest_method/2` | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |
| relay_state raw URL rejection | opaque `rs_` handles only; raw URLs fail closed | `Relyra.Security.RelayState.validate/1` | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |
| signed content trust rejection | document-provided `KeyInfo` is never accepted as a trust source | `Relyra.Security.Signature.verify/3` | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |

## Escape Hatch And Audit Evidence

| claim | executable state | seam | proof command | artifact |
| --- | --- | --- | --- | --- |
| legacy unsigned metadata escape hatch is explicit and time-boxed | bypass exists only through `legacy_unsigned_metadata_policy.allow_until` on a metadata source | `Relyra.Metadata.AutoRefresh.refresh/2` | `mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |
| risky compatibility paths remain attributable | actor, cause, and correlation_id remain attached to metadata and audit rows | `Relyra.Ecto.MetadataApply` + `Relyra.Ecto.AuditWriter` | `mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |
| reviewer-facing evidence stays redaction-safe | actor PII is omitted and correlation_id is hashed in export | `Relyra.Diagnostic.AllowList.export_audit_log/1` | `mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |
| prior conformance and corpus regressions remain part of the packet | existing generated evidence is still required for review reruns | `Mix.Tasks.Relyra.Conformance` | `mix relyra.conformance --check` | `CONFORMANCE.md` |

## Linked Artifacts

| artifact | role |
| --- | --- |
| `SECURITY_REVIEW.md` | canonical reviewer entry point |
| `docs/security_boundary.md` | trust-boundary and scope map |
| `docs/security_findings.md` | findings ledger and remediation policy |
| `SECURITY.md` | public policy and release prerequisites |
| `CONFORMANCE.md` | generated conformance and CVE regression evidence |
