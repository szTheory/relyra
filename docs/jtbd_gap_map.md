# Relyra JTBD Coverage and Gap Map

> **Maintainer reference.** Use this map to assess current adopter coverage and
> prioritize remaining gaps. Adopters should follow
> [`guides/jtbd_user_flows.md`](../guides/jtbd_user_flows.md), which describes
> the supported user journey. This reference is intentionally omitted from Hex
> documentation extras.

## Current coverage by job

### Phoenix SaaS adopter — **Strong**

What is supported:

- install and scaffold Relyra in a Phoenix application
- prove the signed local login path with public `Relyra.Testing` fixtures
- configure one first-class provider: Okta, Microsoft Entra ID, Google
  Workspace, or ADFS
- use the [generic SAML runbook](../guides/recipes/generic_saml.md) for other
  provider families
- persist tenant-scoped connection state and continue into production operations
- integrate logout through the [logout recipe](../guides/recipes/logout.md)

Remaining rough edge:

- generic SAML is supported but not preset-backed; adopters own vendor label
  mapping and provider-specific operating choices beyond the four presets

### Platform or auth owner — **Strong**

What is supported:

- durable tenant connection records and runtime snapshot resolution
- metadata import, review, revision history, and controlled refresh
- certificate inventory and staged rollover
- persisted attribute and group mappings
- audit-backed trust mutation history
- identity mapping guidance in
  [Identity Mapping and Provisioning](../guides/identity_mapping_and_provisioning.md)

Remaining rough edge:

- host applications own tenant provisioning policy and the surrounding product
  workflow for when connections may be enabled

### Operator, support, or SRE — **Strong**

What is supported:

- metadata review and refresh, certificate lifecycle controls, and expiry warnings
- audit history, telemetry, and redacted diagnostic bundle export
- optional LiveAdmin surfaces and bulk operations
- the [incident playbook](../guides/operations/incident_playbook.md) and
  step-by-step login trace through LiveView or `mix relyra.trace`

Remaining rough edge:

- operators still own alert routing, dashboards, and the incident process around
  these library surfaces

### Security reviewer — **Strong, with room for a shorter architecture overview**

What is supported:

- strict defaults, typed rejection behavior, and security boundary documentation
- a reviewer packet, conformance fixtures, and CVE regression evidence
- redacted support evidence and auditable trust changes

Remaining rough edge:

- the reviewer materials provide detailed evidence, but a concise architecture
  overview for a new reviewer would make the trust path faster to assess

### Customer IT admin or self-service owner — **Partial**

What is supported:

- provider runbooks for four presets plus generic SAML decoder tables
- provider field names, metadata guidance, and optional operator administration

Remaining rough edges:

- there is no fully self-service customer-admin portal
- connection testing and attribute preview are not presented as one polished
  customer-admin workflow
- providers beyond the presets require more interpretation from the adopter's
  platform team

### Custom or generic SAML adopter — **Strong, with an operator-owned caveat**

What is supported:

- reusable connection, metadata, certificate, mapping, and validation surfaces
- a [generic SAML runbook](../guides/recipes/generic_saml.md) with vendor decoder
  tables, a minimum-safe checklist, and attribute vocabulary guidance

Remaining rough edge:

- adopters map vendor-specific labels and define their operating process; these
  providers do not have the defaults and guidance of first-class presets

## Remaining work and prioritization

Protocol and extension work remains demand-gated:

- **AUTHN-POST-01:** HTTP-POST AuthnRequest binding; Redirect is the supported
  default path
- **KMS-01:** KMS-backed key resolver adapters; file and application-environment
  key resolution cover the current integration paths
- **SIGNED-META-01:** signed metadata; unsigned import and export are supported,
  while signed metadata awaits demonstrated adopter demand

Customer-admin polish and additional first-class provider presets are also
considered when a concrete adopter or support need justifies their cost. A new
preset should include implementation, a runbook, vendor vocabulary, and proof.

## What is intentionally out of scope

These are product boundaries rather than uncovered jobs:

- OIDC or OAuth as part of Relyra core
- a hosted broker runtime
- ownership of host passwords, MFA, sessions, tenant authorization, or product
  permissions
- claiming first-class support for a provider before its preset, docs, and proof
  are available

## Maintainer ownership

Maintainers keep this map aligned with the currently supported product surface
and use it to prioritize adopter-significant gaps. The user-flow guide owns the
adopter narrative; provider runbooks, production guidance, and the incident
playbook own their detailed procedures. Keep milestone history in planning
records rather than in this current-state reference.
