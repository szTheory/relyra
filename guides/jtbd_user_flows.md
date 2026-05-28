# Relyra Jobs To Be Done And User Flows

This guide is for the engineer who did not spend the last week thinking about
SAML, but now has an enterprise customer who needs it.

Relyra is not trying to turn you into a protocol expert. It is trying to help
you get one very specific class of work done:

- land enterprise SSO in a Phoenix SaaS app
- keep it safe after launch
- give operators and reviewers a trust path they can actually inspect

If you remember one thing, remember this:

**Relyra is an enterprise SSO subsystem, not just a parser.**

It starts with a login button, but the real product is the full path from
"customer asks for SAML" to "support, security, and ops can live with this in
production."

## The four main jobs

### 1. "I need one enterprise tenant live this week"

This is the Day-1 job.

You have a Phoenix app. A customer says, "we need SAML before procurement can
finish." You do not want a month-long detour into XML signatures, metadata
oddities, or vendor-admin archaeology.

Relyra's opinionated answer is:

1. install the library
2. scaffold the host seams
3. prove the trust path locally with `FakeIdP`
4. finish exactly one real-provider runbook
5. only then move into production follow-ons

That shape is not accidental. It front-loads proof and delays optional admin
surfaces until you already have something real working.

### 2. "I need this to be operable after the first login works"

This is the Day-2 job.

The first successful login is not the finish line. The real work starts when:

- a tenant rotates certificates
- metadata drifts
- support needs evidence
- security asks what changed and who changed it
- a production incident lands at 3am

Relyra has real surfaces for this: metadata import and refresh, certificate
lifecycle, audit history, telemetry, diagnostics, and optional LiveAdmin.

### 3. "I need to let customer IT configure this without endless ticket ping-pong"

This is the customer-admin job.

Relyra partially solves this today. It gives you provider presets, exact vendor
field vocabulary, metadata surfaces, and an optional admin UI. It does not
pretend to be a hosted broker or a fully polished self-service admin product.

The current sweet spot is: your team owns the app, your customer owns their
IdP, and Relyra narrows the dangerous middle.

### 4. "I need to trust the trust path"

This is the security and reviewer job.

Relyra's design assumption is that "authentication passed" is not enough. The
important question is whether the library can explain why it passed, why it
failed, and what changed over time.

That is why so much of the library is about:

- strict defaults
- typed rejections
- request and replay correlation
- audit-backed trust mutations
- operator-visible metadata and certificate state

## The canonical Day-1 journey

Think of Day-1 as a five-scene story.

### Scene 1: Install and scaffold

Your trigger:
An enterprise prospect asks for SAML, and you need a credible starting point in
an existing Phoenix app.

What Relyra does:
- ships `mix relyra.install`
- scaffolds the minimal host integration surface
- gives you the library-owned seams without pretending to finish app-specific
  decisions for you

What your app still owns:
- router placement
- connection resolution
- user mapping
- session behavior

Success receipt:
- `mix deps.get` and `mix compile` succeed
- `mix relyra.install --module MyApp --repo MyApp.Repo` runs cleanly
- your host app still boots after wiring the scaffold instructions

Why this matters:
This is where Relyra starts behaving like a Phoenix-native subsystem instead of
a bag of protocol helpers.

### Scene 2: Prove the trust path locally before touching a real IdP

Your trigger:
You want to know whether your host app and Relyra agree on the basic login
contract before Okta or Entra admin work enters the picture.

What Relyra does:
- ships `Relyra.TestSupport`
- ships `Relyra.TestSupport.FakeIdP`
- lets you generate and sign deterministic SAML responses locally

What your app still owns:
- the host-side test
- the user/session handoff
- the assertion-to-local-user mapping choice

Success receipt:
- a host-side proof test or local smoke flow succeeds against `FakeIdP`

Why this matters:
This is the library's version of "make it work on localhost first." It strips
away provider admin complexity so you can answer the first real question:
"does my app integrate with the SAML subsystem at all?"

### Scene 3: Land exactly one real provider

Your trigger:
Local proof is green. Now you need an actual enterprise login.

What Relyra does:
- gives you a narrow batteries-included set: Okta, Microsoft Entra ID, Google
  Workspace, and ADFS
- provides preset defaults for those providers
- speaks the provider's admin vocabulary in docs and hints
- keeps Day-1 scoped to one real-provider branch at a time

What your app still owns:
- publishing the correct ACS URL and entity ID
- routing and session establishment
- downstream authorization after login

Success receipt:
- one successful real-provider login after the `FakeIdP` proof already passed

Why the "exactly one provider" rule is smart:
When teams get stuck, it is often because they start comparing providers before
they have proven one end-to-end. Relyra is intentionally anti-comparison on
Day-1. Finish one branch. Get a receipt. Then broaden.

### Scene 4: Make tenant configuration durable

Your trigger:
The first tenant works, and now this must survive real life.

What Relyra does:
- persists tenant-scoped SAML connections
- resolves runtime connection snapshots from durable records
- stores metadata sources and metadata revisions
- persists certificate inventory and mapping state

What your app still owns:
- tenant provisioning workflow
- tenant authorization rules
- surrounding business logic for who may enable SAML and when

Success receipt:
- connection state, metadata state, certificates, and mappings live somewhere
  your operators can revisit rather than in one-off config fragments

Why this matters:
Without durable config, SAML works like a demo. With durable config, it starts
to behave like a subsystem.

### Scene 5: Add production follow-ons in the right order

Your trigger:
The tenant is live, and now you need safety, not just correctness.

What Relyra does:
- supports metadata lifecycle management
- supports certificate lifecycle and staged rollover
- emits telemetry
- records audit history for trust mutations
- supports scheduled metadata refresh with guardrails
- can export a redacted diagnostic bundle
- can mount an optional LiveAdmin surface

What your app still owns:
- the operational process around those seams
- alert routing, dashboards, and support workflow
- session model and domain-specific authorization

Success receipt:
- you can point to one production-ready plan for metadata, certificates,
  audit/telemetry, and diagnostics

Why this matters:
Most SAML pain is not "how do I parse XML?" It is "how do I survive drift and
support this two quarters from now?"

## A realistic Phoenix SaaS story

Imagine you run a B2B SaaS product called `LedgerLoop`.

An enterprise customer, `Northstar Health`, says:
"We need SAML before rollout. Our IdP team uses Entra. We also need something
our security team can review."

Here is the Relyra-shaped path:

1. You install Relyra and run `mix relyra.install`.
2. You wire the host seams for connection resolution, user mapping, and session
   establishment.
3. You prove the local path with `FakeIdP` in a host-side test.
4. You follow the Entra runbook and land one real login.
5. You persist the tenant's connection and metadata state.
6. You decide whether your team needs the optional LiveAdmin surface.
7. You wire telemetry and audit review.
8. You prepare for certificate rotation and metadata refresh before the first
   incident forces you to care.

The important thing is not just that `Northstar Health` can log in.

The important thing is that six months later, when their signing certificate
changes, your team has:

- a durable connection record
- staged certificate handling
- metadata refresh controls
- audit evidence
- operator-facing diagnostics

That is the real user flow Relyra has built.

## The Day-2 operator journey

Once one provider path works, the center of gravity shifts from "make login
work" to "keep trust changes explicit."

### Metadata management

Job:
"When the IdP changes metadata, I need a controlled way to ingest it without
silently changing what we trust."

What Relyra already gives you:
- metadata import
- metadata source tracking
- metadata revisions
- manual refresh
- scheduled refresh
- trust-fingerprint pinning
- health state for auto-refresh

The key idea:
Relyra treats metadata as operator-reviewed trust material, not as invisible
background plumbing.

### Certificate lifecycle

Job:
"When an IdP rotates signing certificates, I need to stage, inspect, promote,
or roll back deliberately."

What Relyra already gives you:
- certificate inventory
- staged rollover semantics
- expiry visibility
- operator-facing status surfaces
- audit-backed lifecycle transitions

The key idea:
New trust material should not just appear and become live because a background
fetch happened.

### Audit and support evidence

Job:
"When something changed, I need to know what changed, who changed it, and
whether the evidence is safe to share."

What Relyra already gives you:
- co-committed audit rows for trust mutations
- audit timeline filtering in the admin surface
- redacted diagnostics
- security boundary documentation

The key idea:
Relyra is trying to leave behind a readable logbook, not just passing tests.

### Telemetry and alerts

Job:
"I need production signals without dumping raw SAML or secrets into logs."

What Relyra already gives you:
- telemetry spans for login, request generation, response handling, mapping,
  session establishment, metadata flows, and certificate warnings
- a reference log-alert handler for selected events

The key idea:
The telemetry is not there because telemetry is fashionable. It is there because
enterprise SSO becomes ops work very quickly.

### Diagnostic bundles

Job:
"Support needs a bounded evidence package during an incident."

What Relyra already gives you:
- diagnostic bundle export
- redaction allow-list behavior
- UI and mix-task surfaces for bundle generation

The key idea:
A useful support artifact is one you can hand over without accidentally
disclosing everything else.

## The optional admin journey

LiveAdmin is not the front door. It is a late-stage accelerator.

Use it when the job changes from:
"Can we integrate SAML at all?"

to:
"Can our operators manage SAML state without living in migrations, ad hoc SQL,
or internal scripts?"

What LiveAdmin currently centers:
- connection list and detail views
- preset-aware connection editing
- risk panels
- metadata history and refresh
- certificate status and promotion flows
- attribute and group mapping forms
- audit review
- bulk actions across connections
- auto-refresh health surfaces
- diagnostic bundle download

What it does not magically replace:
- your host app's authz model
- your internal admin policy
- your tenant lifecycle

The mental model is simple:
LiveAdmin is the cockpit, not the airplane.

## Flows that are intentionally behind guardrails

Some Relyra flows exist, but the library is careful not to sell them as casual
defaults.

### IdP-initiated SSO

Job:
"A customer wants users to launch from the IdP dashboard."

Relyra supports this, but with an asterisk the size of a building.

Why the guardrails exist:
- there is no SP-created login intent
- redirect handling becomes more dangerous
- replay and tenant binding matter even more

What Relyra already does:
- requires explicit enablement per connection
- normalizes results into the main login shape
- keeps relay-state handling constrained

What this means in practice:
IdP-initiated SSO is a capability, not the recommended primary path.

### Single Logout

Job:
"We need logout to participate in the SAML relationship too."

Relyra already has real SLO pieces:
- logout request construction
- redirect transport handling
- session-revocation adapter support
- conformance coverage around core logout behavior

But today, logout is still more "security-sensitive protocol surface" than
"beautiful first-run adoption story."

That is an important distinction:
the capability exists, but the docs and golden path still revolve around
login-first adoption and operator safety.

## What your app still owns

This is the most important boundary in the whole guide.

Relyra owns the SAML subsystem. Your app still owns the product.

Relyra owns:
- strict SAML protocol validation
- provider presets for the shipped set
- request and replay control surfaces
- metadata and certificate lifecycle seams
- audit and telemetry hooks
- optional admin/operator surfaces

Your app owns:
- which tenant is asking for SAML
- how a tenant connection is provisioned in your product workflow
- how a validated principal maps to a local user
- whether a user should be created, linked, rejected, or deactivated
- session establishment details
- downstream authorization and product permissions

In other words:
Relyra gets you to "this assertion is valid for this connection."
Your app gets you to "this person may now do these things in our product."

## The mental model to keep in your head

When a tenant goes live on Relyra, the library is helping you move through four
states:

1. **Proof**
   Local `FakeIdP` proof shows the host and library can agree on the basic
   contract.

2. **Trust establishment**
   One real provider path proves the customer-facing login story.

3. **Trust durability**
   Metadata, certificates, mappings, and connection state become explicit and
   revisitable.

4. **Trust operations**
   Audit, telemetry, diagnostics, refresh, and staged lifecycle controls make
   the subsystem survivable in production.

That is the user-flow map Relyra has built so far.

It is already much bigger than "SAML login works," and that is exactly why the
library is valuable.

## Related docs

- [Getting Started](getting_started.md)
- [Production Ecto path](production_ecto_path.md) — migrate from install ETS defaults to cluster-safe Ecto adapters
- [Incident playbook — login trace & evidence surfaces](operations/incident_playbook.md#evidence-surfaces) — Day-2 SAML incident Diagnose workflows
- [Batteries Included](batteries_included.md)
- [Okta runbook](recipes/okta.md)
- [Microsoft Entra ID runbook](recipes/entra.md)
- [Google Workspace runbook](recipes/google_workspace.md)
- [Phoenix SaaS tenant onboarding](case_studies/phoenix_saas_tenant_onboarding.md)
- [ADFS runbook](recipes/adfs.md)
- [Generic SAML runbook](recipes/generic_saml.md)
- [Logout recipe](recipes/logout.md)
- [Troubleshooting](troubleshooting.md)
- [Documentation overview](overview.md)
- [Operator-managed rollout](case_studies/operator_managed_rollout.md)
