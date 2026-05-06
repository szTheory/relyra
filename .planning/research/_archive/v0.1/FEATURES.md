# Feature Research

**Domain:** enterprise SAML configuration
**Researched:** 2026-04-25
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Connection records per tenant/IdP | Every enterprise SAML setup is a durable relationship, not a one-off form | MEDIUM | Store entity ID, ACS, SSO URL, enabled state, cert refs, and mapping config per connection |
| Metadata import/export | Most admins start from IdP metadata and need to hand back SP metadata | MEDIUM | Support XML upload, URL import, and SP metadata export; validate before save |
| Certificate inventory + expiry tracking | Cert rotation is routine, not exceptional | MEDIUM | Track signing/verification/encryption certs, expiry dates, and current/default usage |
| Staged certificate rollover | Rotation must avoid downtime during overlap | MEDIUM | Keep old + new certs valid during a transition window; show active/secondary state |
| Persisted attribute/group mapping | Enterprise SSO is useless without durable claim-to-user mapping | MEDIUM | Save mapping per connection, including required fields, literals, and group rules |
| Audit trail for config changes | Security teams need who/what/when for every trust change | LOW | Log create/update/delete for connections, metadata refreshes, cert changes, and mapping edits |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Metadata refresh with diff preview | Lets admins review partner changes before trust updates land | MEDIUM | Better than blind auto-refresh; show what changed in endpoints, certs, and contacts |
| Certificate usage graph | Makes blast radius obvious during rotation | MEDIUM | Show which connections use each cert and which ones will break if removed |
| Versioned mapping history | Helps operators recover from bad mapping edits quickly | MEDIUM | Keep snapshots and allow compare/rollback, not just “current config” |
| Bulk operations across connections | Enterprise customers manage many IdPs and environments at once | HIGH | Useful for rollout, but only after single-connection flows are solid |
| Structured audit export | Easier SIEM/compliance integration than raw app logs | MEDIUM | Emit typed events with actor, target, before/after, and correlation IDs |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Free-form config editing as the primary UX | Power users want maximum control | Easy to drift from validated state; hard to audit and support | Use guided forms plus exportable metadata and typed records |
| Silent auto-refresh from remote metadata | “Set it and forget it” sounds convenient | Surprise trust changes can break auth or widen trust unexpectedly | Explicit refresh with diff, approval, and audit event |
| One cert per connection with hard cutover | Simplifies the model | Causes outages during rotation | Support overlapping old/new certs and staged activation |
| Putting mapping logic in code hooks first | Engineers like flexibility | Makes enterprise config non-portable and hard to review | Persist mappings as data with constrained expressions |

## Feature Dependencies

```
[Connection Records]
    └──requires──> [Metadata Import/Export]
                        └──requires──> [Certificate Inventory + Rollovers]

[Connection Records]
    └──requires──> [Persisted Attribute/Group Mapping]

[Audit Trail]
    └──requires──> [All persisted config changes]

[Metadata Refresh]
    ──enhances──> [Certificate Inventory + Rollovers]
    ──enhances──> [Connection Records]
```

### Dependency Notes

- **Connection records require metadata import/export:** metadata is how most enterprise admins bootstrap and sync a connection.
- **Certificate rollover requires connection records and cert inventory:** you need to know which connection trusts which cert before you can stage overlap safely.
- **Persisted mapping requires connection records:** mappings are connection-scoped config, not global application logic.
- **Audit trail requires all persisted config changes:** if a change affects trust, it must produce a reviewable event.

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] Connection records — the durable unit of enterprise SAML configuration
- [ ] Metadata import/export — bootstrap and handoff without manual transcription
- [ ] Certificate inventory + staged rollover — prevent outage during rotation
- [ ] Persisted mapping config — store tenant-specific attribute/group rules
- [ ] Audit log for config mutations — prove who changed trust and when

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Metadata refresh from URL — only after diff/approval UX exists
- [ ] Certificate usage dashboard — once multiple connections/certs exist
- [ ] Mapping version history/rollback — once edits become frequent enough to need recovery

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Bulk connection operations — only after single-connection workflows are stable
- [ ] Policy templates / connection cloning — useful at scale, but not necessary for first enterprise milestone

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Connection records | HIGH | MEDIUM | P1 |
| Metadata import/export | HIGH | MEDIUM | P1 |
| Certificate inventory + staged rollover | HIGH | HIGH | P1 |
| Persisted mapping config | HIGH | MEDIUM | P1 |
| Audit log for config mutations | HIGH | LOW | P1 |
| Metadata refresh from URL | MEDIUM | MEDIUM | P2 |
| Certificate usage dashboard | MEDIUM | MEDIUM | P2 |
| Mapping version history/rollback | MEDIUM | MEDIUM | P2 |
| Bulk connection operations | MEDIUM | HIGH | P3 |
| Policy templates / connection cloning | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Metadata import/export | PingFederate and PingOne both expose metadata-based setup and export | Snowflake prefers METADATA_URL for dynamic IdP config | Support both file/URL import and SP export, but keep review before apply |
| Certificate rollover | Google Workspace and SimpleSAMLphp both recommend overlap windows with old/new certs | Microsoft Entra exposes active/expired verification cert state | Model certs as inventory with staged activation, not a single mutable field |
| Mapping persistence | PingOne and Keycloak persist per-connection/client mappings | ExtraHop uses attribute/group mapping in the admin flow | Store mappings as connection-scoped records with audit history |
| Auditability | Google logs SAML cert events; PingFederate logs admin and metadata updates | Keycloak exposes events as admin audit streams | Emit typed config audit events with before/after payloads |

## Sources

- https://docs.pingidentity.com/pingfederate/latest/administrators_reference_guide/pf_importing_sp_metadata.html
- https://docs.pingidentity.com/pingfederate/12.2/administrators_reference_guide/pf_updating_saml_connection_using_metadata.html
- https://docs.pingidentity.com/pingoneforenterprise/pingone_for_enterprise/p14e_add_update_saml_application.html
- https://docs.pingidentity.com/pingoneforenterprise/pingone_for_enterprise/p14e_view_certificate_details.html
- https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-advanced.html
- https://simplesamlphp.org/docs/stable/saml/keyrollover.html
- https://support.google.com/a/answer/7394709?hl=en
- https://support.google.com/a/answer/7007375?hl=en
- https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-enforce-signed-saml-authentication
- https://docs.extrahop.com/26.1/configure-saml
- https://www.keycloak.org/docs/26.6.0/server_admin/

---
*Feature research for: enterprise SAML configuration*
*Researched: 2026-04-25*
