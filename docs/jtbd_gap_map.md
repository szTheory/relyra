# Relyra JTBD Gap Map

This document is the planning companion to
[`guides/jtbd_user_flows.md`](../guides/jtbd_user_flows.md).

The guide explains the current story from an adopter's point of view.
This document answers a different question:

**How complete is Relyra's user-flow map, what is still missing, and where do
future milestones stop paying for themselves?**

Last refreshed: 2026-05-27

## What changed since last refresh

- **v1.3:** Generic SAML runbook (`guides/recipes/generic_saml.md`), identity mapping guide
  (`guides/identity_mapping_and_provisioning.md`), ENC-01 encrypted assertions (Phase 34).
- **v1.4:** Logout recipe (`guides/recipes/logout.md`), incident playbook
  (`guides/operations/incident_playbook.md`), SLO core (Phases 38–40).
- **v1.5:** login trace LiveView + `mix relyra.trace` (Phase 42), adopter DX polish (Phase 46),
  Hex publish (Phases 43–45).
- **v1.6:** Onboarding truth (Getting Started, production Ecto path — Phase 47), operator trace
  playbook wiring (Phase 48).

## Current coverage map

### Phoenix SaaS adopter

Status: **Strong**

What is clearly supported:
- install and scaffold into a Phoenix app
- prove the path locally with `FakeIdP`
- land one real-provider path with a shipped preset (Okta, Entra, Google Workspace, or ADFS)
- persist tenant-scoped connection state
- use a clear Day-1 -> Day-2 onboarding spine
- logout as an adopter workflow (`guides/recipes/logout.md`)
- custom/generic SAML via the generic runbook (`guides/recipes/generic_saml.md`)

What is still rough:
- the generic SAML path is supported but not preset-backed — adopter owns vendor
  label mapping and synthesis beyond the four batteries-included presets

Assessment:
This is already a serious adoption story for teams using Okta, Entra, Google
Workspace, or ADFS, with a documented generic path for other IdP families.

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
- identity mapping and provisioning guide (`guides/identity_mapping_and_provisioning.md`)

What is still rough:
- the custom-provider operating model could use minor polish compared to the
  preset model (host-owned provisioning policy remains a host concern)

Assessment:
The capability set is strong and the identity boundary is documented. Remaining
work is minor polish, not foundational capability gaps.

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
- incident response playbook (`guides/operations/incident_playbook.md`)
- login trace LiveView and `mix relyra.trace` for step-timeline triage (Phases 42/48)

What is still rough:
- optional polish on playbook cross-links as new ops surfaces ship

Assessment:
For v1.5/v1.6, playbook, trace tools, and diagnostics form one coherent
production story — workflow packaging is complete.

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
- exact vendor runbooks for four batteries-included presets (Okta, Entra, Google
  Workspace, ADFS) plus generic SAML decoder tables
- provider-specific labels and hints
- metadata and SP/IdP field vocabulary
- optional admin surface for operators

What is still rough:
- there is no fully self-service "customer admin portal" story (intentionally
  out of scope)
- connection testing and attribute preview are not yet presented as a polished
  customer-admin workflow
- support for providers beyond the four presets requires more operator
  interpretation than most customer IT teams would want

Assessment:
Relyra helps your team work with customer IT. It does not yet make customer IT
fully independent, and it does not claim to.

### Custom or generic SAML adopter

Status: **Strong**

What is clearly supported:
- the library can support non-preset SAML integrations
- the durable connection, metadata, certificate, mapping, and validation
  surfaces are reusable beyond the four batteries-included presets
- generic SAML runbook with decoder tables (`guides/recipes/generic_saml.md`)
- minimum-safe checklist and attribute vocabulary guidance in the generic runbook

What is still rough:
- not preset-backed — adopter owns vendor label mapping and operator process
  synthesis for IdPs outside Okta, Entra, Google Workspace, and ADFS

Assessment:
Generic SAML adoption is documented and guided. Remaining roughness is the
honest non-preset caveat, not a missing runbook — no longer the biggest adoption
gap inside the current product boundary.

## Biggest gaps by user and job

These are the highest-value remaining JTBD gaps, ordered by expected adopter
value rather than by protocol novelty. Several former top gaps are now **Shipped
(v1.3–v1.6)** — listed first for historical context, then active gaps.

### 1. First-class custom or generic SAML path — **Shipped (v1.3)**

**Artifact:** `guides/recipes/generic_saml.md` (decoder tables, minimum-safe checklist).

Former priority: Highest. Closed in v1.3 Phase 36; persona reassessment in v1.6
Phase 49 confirms **Strong** with honest non-preset caveat.

### 2. Identity mapping and provisioning story — **Shipped (v1.3)**

**Artifact:** `guides/identity_mapping_and_provisioning.md`.

Former priority: High. Closed in v1.3 Phase 37; host-owned boundary documented.

### 3. Logout as an adopter workflow — **Shipped (v1.4)**

**Artifact:** `guides/recipes/logout.md`.

Former priority: Medium-high. Closed in v1.4 Phase 39.

### 4. Operator incident and recovery playbook — **Shipped (v1.4 + v1.6)**

**Artifact:** `guides/operations/incident_playbook.md` (login trace wiring Phase 48).

Former priority: Medium. Closed in v1.4 Phase 40; trace tools documented Phase 48.

### 5. Customer-admin self-service polish — **Partial / Medium-low**

Why it matters:
This reduces support load but is intentionally out of scope for a library SP.

What "done enough" looks like:
- clearer self-service setup flow
- stronger connection-test or preview workflow
- more customer-admin-facing affordances around attributes and setup receipts

Priority:
**Medium-low** (intentionally not a v1.6 blocker)

### 6. Broader preset catalog — **Lower priority / demand-gated**

Why it matters:
Four batteries-included presets plus the generic runbook cover most real-world
cases. Additional first-class presets ship only when code, runbook, field
vocabulary, and proof all ship together — justified by real adopter demand.

Priority:
**Lower / demand-gated**

## Recommended next milestones in order

Future milestone planning should follow **demand-gated protocol and extension
work**, not coverage-gated doc gaps (those shipped in v1.3–v1.6):

### 1. AUTHN-POST-01 (HTTP-POST AuthnRequest binding) — save-for-demand

Reason:
Redirect binding is the default shipped path. POST binding remains out of scope
until a real GitHub issue or adopter request materializes.

### 2. KMS-01 (KMS KeyResolver adapters) — save-for-demand

Reason:
File-based and application-env key resolution covers current adopters. KMS
adapters ship when enterprise key-management demand appears.

### 3. SIGNED-META-01 (signed metadata) — save-for-demand

Reason:
Metadata import/export works unsigned today. Signed metadata is investigation
stub only until external demand.

### 4. Optional polish — only on real demand

Reason:
Case study FakeIdP reference cleanup and customer-admin workflow polish are
worthwhile but not JTBD-coverage-gated. Pursue when a concrete adopter or
support signal appears.

## Diminishing-returns threshold

Relyra does not need to model every possible SAML situation to have a
practically complete JTBD map.

**v1.6 Adoption Truth criteria are MET** for doc/onboarding/ops coverage:

- Day-1 onboarding is crisp for four batteries-included presets and generic SAML
- Day-2 operations are documented as one coherent production story (playbook +
  login trace)
- identity mapping and provisioning boundaries are documented
  (`guides/identity_mapping_and_provisioning.md`)
- logout has a clear host-app integration story (`guides/recipes/logout.md`)
- security and reviewer docs remain exact and current (CONFORMANCE scope
  boundary, ENC-01 manifest pass — Phase 49)

Remaining work is **demand-gated**, not JTBD-coverage-gated:

- AUTHN-POST-01, KMS-01, SIGNED-META-01 (protocol/extensions)
- customer-admin self-service polish (intentionally out of scope)
- one more provider preset or case study variant (only on real adopter demand)

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
