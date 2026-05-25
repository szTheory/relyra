# Security Boundary Map

This document defines the trust-boundary surface a third-party reviewer should assess for Relyra itself. It separates library-owned seams from host-application assumptions so audit depth stays focused on exploit paths the library actually controls.

## In Scope

- XML parsing and parser refusal behavior, including DOCTYPE and entity rejection.
- Signed-node selection, `:public_key.verify` over exclusive-C14N canonicalized `SignedInfo` against the configured IdP certificate's public key (never document-provided `KeyInfo`), and constant-time `DigestValue` recompute/compare bound to the exact consumed node on `verify/4` and `verify_metadata_root/4`.
- Protocol validation for issuer, destination, audience, recipient, and time checks.
- RelayState issuance and raw-URL rejection.
- Request tracking and replay-prevention seams.
- Metadata trust anchors, scheduled refresh, drift review, and typed suspension paths.
- Certificate lifecycle controls for staged, active, and retired signing material.
- Single Logout request and response seams shipped by the library.
- Audit-event attribution, correlation, and redaction guarantees.
- Diagnostic bundle redaction and bounded evidence export.
- Library-owned Phoenix and LiveView boundaries where Relyra defines the contract.

## Out of Scope

- Host-application authentication and authorization policy outside Relyra's contracts.
- Custom `ScopeProvider` implementations and tenant-policy decisions owned by adopters.
- Generic Phoenix router policy that does not pass through Relyra-owned routes or controllers.
- Application session management, CSRF policy, and downstream business authorization.
- Adopter-specific admin UX beyond the library-owned risk and health surfaces.

## Trust Seams

| Seam | Primary module(s) | Reviewer focus |
| --- | --- | --- |
| XML parse refusal | `lib/relyra/metadata/parser.ex`, `lib/relyra/security/xml/` | Untrusted XML must fail closed before deep processing. |
| Signed-content trust | `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex` | `:public_key.verify` must run over exclusive-C14N canonicalized `SignedInfo` against the configured IdP certificate's public key, `DigestValue` must be recomputed and compared in constant time over the exact consumed node, and document-provided `KeyInfo` must never become a trust source. |
| Protocol validation | `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra.ex` | Destination, audience, recipient, time, and issuer checks stay typed and fail closed. |
| RelayState | `lib/relyra/security/relay_state.ex` | Opaque handles only; raw URLs and tampering are rejected. |
| Replay and request intent | `lib/relyra/request_store/`, `lib/relyra/replay_store/` | Request/response correlation and replay protection remain explicit. |
| Metadata refresh and trust anchors | `lib/relyra/metadata/auto_refresh.ex`, `lib/relyra/metadata/trust_anchor.ex` | Scheduled refresh uses pinned trust anchors or explicit, time-boxed escape hatches. |
| Certificate lifecycle | `lib/relyra/ecto/certificate_inventory.ex` | New signing material stages for review instead of silently promoting trust. |
| SLO surface | `lib/relyra/logout_result.ex`, protocol bindings and validation pipeline | Logout uses the same signed transport and validation rules as login-facing seams. |
| Audit and redaction | `lib/relyra/ecto/audit_writer.ex` | Risky operations remain attributable, correlated, and redaction-safe. |
| Diagnostic export | `lib/relyra/diagnostic.ex`, `lib/relyra/diagnostic/allow_list.ex` | Reviewer-facing evidence omits raw XML, PEMs, actor PII, and other secrets. |
| Library-owned Phoenix/admin seams | `lib/relyra/phoenix/`, `lib/relyra/live_admin/` | Review only the library contract, route ingress, and risk surfacing it owns. |

## Reviewer Assumptions

- Reviewers evaluate the library on the current checked-in code, tests, and generated artifacts in this repository.
- Host applications must still enforce their own authn/authz, session, deployment, and network controls.
- Optional admin and Ecto-backed surfaces are reviewed only where the library provides the contract and persistence behavior.
- External findings should be recorded in [`docs/security_findings.md`](security_findings.md) with severity, disposition, owner, and regression proof.
