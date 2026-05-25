# Relyra JTBD Gap Map

This document is the planning companion to
[`guides/jtbd_user_flows.md`](../guides/jtbd_user_flows.md).

The guide explains the current story from an adopter's point of view.
This document answers a different question:

**How complete is Relyra's user-flow map, what is still missing, and where do
future milestones stop paying for themselves?**

Last refreshed: 2026-05-23

## Current coverage map

### Phoenix SaaS adopter

Status: **Strong**

What is clearly supported:
- install and scaffold into a Phoenix app
- prove the path locally with `FakeIdP`
- land one real-provider path with a shipped preset
- persist tenant-scoped connection state
- use a clear Day-1 -> Day-2 onboarding spine

What is still rough:
- the custom/generic SAML path is real, but not yet as smooth or confidence-
  building as the three shipped presets
- logout exists in the code surface, but not yet as a polished adopter workflow

Assessment:
This is already a serious adoption story for teams using Okta, Entra, or Google
Workspace and willing to own the host seams.

### Platform or auth owner

Status: **Strong but under-explained**

What is clearly supported:
- multi-tenant connection records
- runtime snapshot resolution
- metadata import and controlled refresh
- certificate inventory and staged rollover
- attribute and group mapping persistence
- audit-backed trust mutation history
- scheduled refresh automation with guardrails

What is still rough:
- the "how do I shape provisioning policy around this?" story is still mostly a
  host concern rather than a first-class Relyra guide
- the custom-provider operating model is not yet as crisp as the preset model

Assessment:
The capability set is strong. The main gap is not raw implementation depth; it
is making the operating model easier to understand and easier to adopt safely.

### Operator, support, or SRE

Status: **Strong**

What is clearly supported:
- metadata review and refresh flows
- certificate lifecycle controls
- expiry warnings
- audit review
- telemetry
- diagnostic bundle export
- optional admin surfaces for common operations
- bulk actions across connections

What is still rough:
- there is not yet one canonical "incident response / support playbook" guide
  that stitches telemetry, audit, diagnostics, and rollout recovery together

Assessment:
This is one of Relyra's strongest areas. The remaining work is primarily
workflow packaging, not foundational capability.

### Security reviewer

Status: **Strong**

What is clearly supported:
- strict-default posture
- security boundary documentation
- reviewer packet and evidence
- conformance fixtures
- CVE regression fixtures
- typed rejection and redaction discipline

What is still rough:
- the reviewer story is more security-packet oriented than "quick architecture
  overview for a fresh security engineer"

Assessment:
Relyra is already ahead of where many library ecosystems stop. Additional work
here should be narrowly scoped to documentation clarity, not major new surface
area.

### Customer IT admin or self-service setup owner

Status: **Partial**

What is clearly supported:
- exact vendor runbooks for three providers
- provider-specific labels and hints
- metadata and SP/IdP field vocabulary
- optional admin surface for operators

What is still rough:
- there is no fully self-service "customer admin portal" story
- connection testing and attribute preview are not yet presented as a polished
  customer-admin workflow
- support for providers beyond the shipped three requires more operator
  interpretation than most customer IT teams would want

Assessment:
Relyra helps your team work with customer IT. It does not yet make customer IT
fully independent, and it does not claim to.

### Custom or generic SAML adopter

Status: **Partial**

What is clearly supported:
- the library can support non-preset SAML integrations
- the durable connection, metadata, certificate, mapping, and validation
  surfaces are reusable beyond the three presets

What is still rough:
- there is no first-class generic runbook with the same confidence level as the
  shipped provider docs
- there is no clear "minimum safe checklist" doc for teams bringing their own
  attribute vocabulary and operator process

Assessment:
This is the biggest adoption gap inside the current product boundary.

## Biggest gaps by user and job

These are the highest-value remaining JTBD gaps, ordered by expected adopter
value rather than by protocol novelty.

### 1. First-class custom or generic SAML path

Why it matters:
The current support matrix is intentionally narrow, but real SaaS teams will
encounter Ping, ADFS, Shibboleth, Keycloak, OneLogin, and internal enterprise
IdPs. Today the library can often support those cases technically, but the
adoption story drops from "guided" to "you own the synthesis."

What "done enough" looks like:
- one generic SAML runbook
- one explicit minimum-safe checklist
- one clear explanation of what the adopter must supply when there is no preset

Priority:
**Highest**

### 2. Identity mapping and provisioning story

Why it matters:
Getting a valid assertion is only half the real application job. Teams still
need help reasoning about:

- NameID versus application identity
- required attributes
- account linking
- group-to-role mapping posture
- when to create or reject users

What "done enough" looks like:
- one guide that explains the host-owned identity boundary
- example mapping patterns for common SaaS cases
- explicit non-goals around SCIM ownership

Priority:
**High**

### 3. Logout as an adopter workflow, not just a protocol surface

Why it matters:
SLO support exists, but many adopters will ask a practical question:
"what does it mean for my Phoenix app and session model?"

What "done enough" looks like:
- one doc explaining when SLO is worth enabling
- clear warning about stateful versus stateless session implications
- one end-to-end host integration story

Priority:
**Medium-high**

### 4. Operator incident and recovery playbook

Why it matters:
The parts exist: telemetry, audit, diagnostics, refresh controls, certificate
lifecycle. What is missing is a single narrative for "something drifted or
broke; now what?"

What "done enough" looks like:
- one operational playbook
- recommended first checks for common production failures
- linkages between diagnostics, audit, telemetry, and admin UI

Priority:
**Medium**

### 5. Customer-admin self-service polish

Why it matters:
This reduces support load, but only after the previous gaps are addressed.

What "done enough" looks like:
- clearer self-service setup flow
- stronger connection-test or preview workflow
- more customer-admin-facing affordances around attributes and setup receipts

Priority:
**Medium-low**

### 6. Broader preset catalog

Why it matters:
Provider breadth is visible and useful, but it is not the highest-leverage next
step if the generic path is still weak.

What "done enough" looks like:
- add presets only when code, runbook, field vocabulary, and proof all ship
  together

Priority:
**Lower than generic-path and identity-story work**

## Recommended next milestones in order

If future milestone planning is guided by JTBD coverage, the best order is:

### 1. Close the custom/generic SAML onboarding gap

Reason:
This unlocks a much wider real-world adoption surface without committing the
project to a long tail of provider-specific promises.

Likely outputs:
- generic SAML runbook
- custom-provider checklist
- stronger support taxonomy and expectation-setting

### 2. Document and sharpen the identity mapping boundary

Reason:
This is where many SaaS teams still make product-critical mistakes even after
protocol validation is correct.

Likely outputs:
- mapping and provisioning guide
- host-owned decision framework
- better examples for common tenant/user linking patterns

### 3. Promote logout from "implemented capability" to "adopter-ready flow"

Reason:
The protocol work exists. The missing piece is a crisp host-app story that
helps teams decide whether and how to use it.

Likely outputs:
- SLO guide
- session-adapter examples
- operational caveats and receipts

### 4. Package the operator incident workflow

Reason:
This improves production usability without broadening scope.

Likely outputs:
- operations playbook
- common-failure troubleshooting guide
- cross-links between telemetry, diagnostics, audit, and admin UI

### 5. Re-evaluate provider expansion only after the above

Reason:
A broader preset catalog is valuable, but only if the project can support the
operating burden honestly.

Likely outputs:
- one or two high-demand presets, or
- an explicit decision to invest in the generic path instead

## Diminishing-returns threshold

Relyra does not need to model every possible SAML situation to have a
practically complete JTBD map.

The project is close to "feature-complete enough" for user-flow coverage once
all of the following are true:

- Day-1 onboarding is crisp for both shipped presets and generic SAML
- Day-2 operations are understandable as one coherent production story
- identity mapping and provisioning boundaries are documented well enough that
  adopters stop guessing
- logout has a clear host-app integration story
- security and reviewer docs remain exact and current

After that point, most additional JTBD work becomes lower-yield:

- one more provider preset
- one more case study variant
- one more edge-case flow for a niche enterprise setup

Those can still be worthwhile, but they should be justified by real adopter
demand rather than by a desire to "cover the map."

## What is intentionally out of scope

These are not gaps unless the project direction changes:

- OIDC or OAuth as part of Relyra core
- a hosted broker runtime
- full auth-system ownership for passwords, MFA, or sessions
- SCIM lifecycle ownership as an in-core responsibility
- pretending every SAML provider is batteries-included before preset + docs +
  proof all exist

## Update method

When refreshing this document in the future:

1. Scan `CHANGELOG.md` for new user-facing flows.
2. Re-read `README.md`, `guides/getting_started.md`, provider runbooks, and
   case studies.
3. Re-read `.planning/PROJECT.md` and the next milestone docs, if a new
   milestone exists.
4. Reclassify each job as strong, partial, or intentionally out of scope.
5. Add a dated "what changed since last refresh" note here and in
   `guides/jtbd_user_flows.md`.

Default rule:
- update both docs when the user-facing story changed
- update only this gap map when prioritization changed but the shipped surface
  did not
