# Identity Mapping And Provisioning

This guide is the operator-facing reference for the moment after SAML validation
has already succeeded. Use it to decide which verified identity field becomes
your local account anchor, whether login-time JIT is appropriate, and where
Relyra's responsibility ends.

## Overview

Relyra verifies the SAML response, normalizes the successful login into a
verified payload, and then stops at a host-owned seam. It does not decide
whether a local user should be looked up, linked, created, updated, suspended,
or authorized for application-specific roles.

In the Phoenix ACS path, that seam is `Relyra.UserMapper.map_attributes/3`.
The controller passes the verified login result plus the resolved connection
into the mapper, and the host application returns the user-shaped map that its
session layer needs next.

Treat this guide as a local identity policy document, not as a SAML theory
overview. The question is not "what can the IdP emit?" The question is "which
verified value should our app trust as the durable local anchor?"

## Relyra owns / Host owns

## Relyra owns

- Response validation, signature verification, replay checks, and the verified
  login payload.
- The normalized identity facts exposed through `Relyra.LoginResult` and
  `Relyra.Principal`, such as `name_id`, `name_id_format`, and released
  attributes.
- The mapper and session seams where the host application takes over.

## Host owns

- Choosing the local account anchor.
- Looking up an existing account, deciding whether a new account may be created,
  and deciding which fields are safe to update on login.
- Authorization, tenant membership, offboarding, manual account linking, and
  every lifecycle action outside the successful login event.
- Any SCIM workflow or adjacent lifecycle sync system.

The practical boundary is simple: Relyra proves "this IdP asserted these facts
and the trust path verified." Your application decides what those facts mean for
an account in your domain.

## Choose your identity anchor first

Choose the anchor before you write mapping code or enable JIT. This is the
decision that determines whether future IdP cleanup is harmless or becomes an
account migration.

Anchor-quality rules:

- Best: a stable opaque identifier that the IdP treats as durable for the life
  of the user.
- Acceptable with care: email or another human-readable attribute when your app
  already treats that field as the canonical identity and your org can tolerate
  renames, aliases, and reuse risk.
- Poor choice: `transient` identifiers or any field the IdP explicitly treats
  as session-scoped or presentation-only.

Anchor-stability warning:

- If the IdP changes the NameID source or NameID format after users already
  exist, your app may see a different local identifier for the same human.
- If the anchor is email-based, mailbox rename, domain migration, and recycled
  addresses can split or relink accounts unexpectedly.
- If you anchor on a convenient attribute now and later move to a different
  source, plan that as an account-migration project, not as a docs cleanup.

Keep this aligned with the [generic SAML runbook](recipes/generic_saml.md),
which already treats NameID choice as a trust-boundary decision rather than an
admin-console default.

## Pattern 1: NameID as local identifier

Use this pattern when the IdP can emit a NameID that is already the durable
identifier your application wants to anchor on.

This is usually the safest pattern when:

- The IdP can emit a stable `persistent` NameID.
- Your host app does not need a separate internal identity key for the same
  user.
- You want the smallest gap between the validated SAML identity and the local
  lookup key.

What the host app should do:

- Read the verified NameID from the login payload.
- Look up the local account by that anchor.
- Fail closed if the account must already exist and no match is found.

What breaks this pattern:

- The IdP emits `transient` NameID.
- The IdP emits `unspecified` NameID but the actual source changes between
  environments or later admin edits.
- The org treats email-style NameID as durable even though addresses can change.

If you pick NameID, make the exact source and format part of the deployment
contract. "Whatever the IdP currently sends" is not a stable policy.

## Pattern 2: Attribute as local identifier

Use this pattern when NameID is not the right durable anchor for your app, but
another verified attribute is.

Common examples:

- The app anchors on employee number, HR identifier, or another stable directory
  key.
- The IdP uses NameID for presentation or federation convenience, but the app
  already has a different canonical local identifier.
- The app intentionally uses email as the lookup key and accepts the rename
  policy and migration burden that comes with it.

This pattern needs more discipline than Pattern 1 because you are choosing a
field that may look stable in one directory but be mutable in another. Ask:

- Who owns this attribute?
- Can it change on rename, domain move, or tenant merge?
- Can the value be recycled for a different person later?
- Does every environment release it consistently?

If the answer is "sometimes," document the migration and relinking plan now.
Attribute anchors are viable, but they are only safe when the host application
owns the consequences of churn.

## Pattern 3: JIT create or update

JIT means your host application decides, during a successful login, whether to
create a new local account or update a subset of fields on an existing one.
Relyra does not provision the user for you. It gives you verified identity input
and a mapper seam.

Use JIT only after you are confident about the anchor decision. Otherwise you
will automate duplicate-account creation at login speed.

JIT is usually reasonable when:

- The app allows first-login account creation for the target population.
- The anchor is stable enough that repeated logins resolve to the same account.
- The fields you plan to update on login are low-risk profile projections, not
  broader authorization or lifecycle controls.

JIT is risky when:

- The app has approval gates or entitlement rules that should not be bypassed by
  successful authentication alone.
- Several directories or tenants can release overlapping identifiers.
- Another lifecycle system already creates and links accounts independently.

Keep the output of `Relyra.UserMapper.map_attributes/3` narrow and
host-shaped. The mapper should return the identity data your app needs for local
lookup or create-or-update decisions, not pretend to be a full provisioning
engine.

## JIT decision tree

Use this decision tree before enabling login-time create or update:

1. Is the local identity anchor stable across rename, tenant, and format
   changes?
   If no, do not enable JIT yet.
2. Is the anchor released consistently in every environment this connection will
   serve?
   If no, fix the IdP release contract first.
3. Does your app allow successful login to create a local account without a
   separate approval step?
   If no, use lookup-only mapping and reject unknown users.
4. If the account already exists, which fields are safe to update on login?
   Limit this to profile projection, not lifecycle authority.
5. Is another system already creating, linking, or deprovisioning these
   accounts?
   If yes, choose one source of truth before enabling JIT.

Recommended outcomes:

- Stable anchor + no other lifecycle source: JIT create or update can be
  reasonable.
- Stable anchor + external lifecycle owner: prefer lookup and limited projection.
- Unstable anchor: fix the anchor first, then reconsider JIT.

## SCIM is a non-goal

SCIM lifecycle ownership is outside Relyra's scope. Relyra covers login-time
assertion validation and the host-owned mapping seam that follows. It does not
ship a user directory, background lifecycle sync, or deprovisioning authority.

If your organization uses SCIM, keep the responsibility split explicit:

- SCIM or an adjacent lifecycle system owns long-lived account creation,
  disablement, and reconciliation.
- Relyra owns the verified login event.
- Your host app decides how those two systems meet.

Safety warning:

- Running JIT create-or-update and SCIM at the same time without one clear
  source of truth can create duplicate accounts, broken links, or account drift.
- The risk is highest when JIT uses one anchor and SCIM uses another, or when
  one system updates fields the other treats as authoritative.

If you need both, define the authoritative anchor and lifecycle owner first.
Without that decision, simultaneous JIT and SCIM is not additive resilience. It
is two competing account writers.
