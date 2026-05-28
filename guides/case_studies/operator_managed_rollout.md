# Operator-Managed Rollout

## Scenario

An operator team already has one provider path working and now needs a repeatable
day-2 rollout for metadata review, certificate lifecycle, diagnostics, and
auditability across production environments.

## Exact wiring and config

- Start from one verified first-class provider path or an intentionally labeled
  `custom/generic SAML` integration
- Review metadata and trust-anchor handling before enabling scheduled refresh
- Track certificate lifecycle as an operator-owned process, not an invisible
  background detail
- Keep diagnostic bundle generation and audit review in the production support
  workflow

## Relyra owns

- Metadata trust-boundary enforcement and typed refresh outcomes
- Certificate lifecycle seams and audit evidence produced by the library
- Diagnostic export and redaction behavior inside the library-owned boundary

## Host owns

- Release workflow, deployment timing, and incident response policy
- Storage, review, and routing of diagnostics and audit evidence
- Application-specific operational controls outside the Relyra contract

## Failure and recovery

- Failure: metadata is refreshed without understanding the trust boundary
  Recovery: pause automatic changes and review trust-anchor, certificate, and
  audit evidence before re-enabling the path
- Failure: certificate rotation lands without operator review
  Recovery: use the library's lifecycle and audit surfaces to re-stage and
  verify the new material
- Failure: diagnostics expose more scope than the host wants to share
  Recovery: rely on the bounded diagnostic surfaces and verify the exported
  evidence set before external sharing

## Evidence

- Metadata review artifacts and operator sign-off
- Certificate lifecycle receipts tied to the host rollout process
- Diagnostic and audit outputs used during support and recovery
- Explicit scope notes showing whether the provider path is one of the four
  first-class presets or a `custom/generic SAML` integration
