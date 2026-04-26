# Pitfalls Research — Relyra v0.2 Enterprise Configuration

**Domain:** Enterprise configuration for an existing SAML 2.0 Service Provider library (Elixir/Phoenix)
**Researched:** 2026-04-25
**Confidence:** MEDIUM

## Critical Pitfalls

### 1. Treating configuration as a blob instead of a versioned trust record

**What goes wrong:**
Connection data, IdP metadata, certificates, mappings, and audit state get packed into one JSON field or one mutable struct. That makes partial updates easy, but rollbacks, diffs, and safe multi-step changes impossible.

**Why it happens:**
CRUD thinking wins early. A single record feels faster than modeling the trust lifecycle.

**How to avoid:**
Model connection, certificate, metadata source, mapping, and audit entries separately. Use transactions (`Ecto.Multi`), optimistic locking, unique constraints per tenant/entity pair, and immutable history for trust-bearing changes.

**Warning signs:**
- One `jsonb`/map column holds the whole connection state
- Updates happen outside a transaction
- No `lock_version`, `version`, or `change_set` field
- You cannot answer “what changed since last import?”

**Phase to address:**
Schema + migrations phase, before any admin UI or refresh automation.

---

### 2. Metadata import/refresh without freshness, provenance, or validation guarantees

**What goes wrong:**
The system accepts stale or malformed metadata, overwrites known-good config with a bad fetch, or assumes every IdP behaves like the last one. Result: silent trust drift or sudden SSO failure.

**Why it happens:**
Metadata looks like a file problem, not a lifecycle problem. Teams forget that some IdPs expose URLs, some only XML exports, and refresh timing varies.

**How to avoid:**
Support both URL and file import. Store fetch time, source URL, checksum/fingerprint, expiry, and last-known-good snapshot. Refresh in the background, not on the login path. Fail closed if a refresh is malformed or obviously stale.

**Warning signs:**
- Metadata fetch happens during login
- No stored `fetched_at` / `expires_at`
- One provider’s import behavior is assumed for all providers
- Manual upload replaces current config with no rollback path

**Phase to address:**
Metadata import/export + refresh phase.

---

### 3. Certificate rollover implemented as replace-in-place

**What goes wrong:**
A new cert is activated before the IdP/SP pair has converged, or the old cert is removed too early. Authentication breaks during the rotation window, usually under customer pressure.

**Why it happens:**
Single-certificate data models make “swap the value” feel normal. In SAML, rotation is a staged trust transition, not a field update.

**How to avoid:**
Model certificates with states like `active`, `next`, `retired`, and `expired`. Allow overlap windows. Promote only after the new cert is visible in metadata and runtime trust. Emit expiry alerts well before cutoff.

**Warning signs:**
- One certificate field per connection
- Saving a cert immediately deletes the previous one
- No overlap test for old/new cert acceptance
- Rotation requires a maintenance window

**Phase to address:**
Certificate lifecycle + rollover phase.

---

### 4. Auditability implemented as log lines instead of a change ledger

**What goes wrong:**
You can see that something changed, but not who changed it, what the prior value was, what system did it, or whether the change applied cleanly across runtime nodes.

**Why it happens:**
Logs are quicker than event models. But logs are not a durable trust history.

**How to avoid:**
Persist append-only audit events with actor, tenant, connection, source, before/after hashes, correlation id, and outcome. Keep secrets and raw assertions out of the audit payload.

**Warning signs:**
- Audit entries say only “updated successfully”
- No old/new diff is stored
- Raw XML or cert material appears in logs
- Config changes and login failures cannot be correlated

**Phase to address:**
Audit schema + event emission phase, with admin workflow integration.

---

### 5. Confusing metadata certificates with runtime trust certificates

**What goes wrong:**
The product mixes up assertion-signing certs, metadata-signing certs, encryption certs, and export/import certs. Customers upload the wrong artifact, or rotation fixes one path while breaking another.

**Why it happens:**
SAML uses several certificate roles, and vendors expose them differently. The names look similar, but the trust boundaries are not.

**How to avoid:**
Track certificate purpose explicitly. Label every cert by role, source, validity window, and whether it is for runtime validation or metadata signing/export. Require purpose selection in admin and import flows.

**Warning signs:**
- One “certificate” field drives every code path
- Support asks “which cert goes where?”
- Metadata export and assertion validation share the same slot
- Tests never distinguish metadata-signing from assertion-signing

**Phase to address:**
Metadata/export phase, then cert lifecycle phase.

---

### 6. Mapping persistence that allows silent authorization drift

**What goes wrong:**
Attribute and group mappings drift over time, or NameID gets treated as email. A harmless IdP change becomes a broken login or an over-broad role grant.

**Why it happens:**
Free-form mapping looks flexible. It also hides coupling to IdP naming conventions and local authorization rules.

**How to avoid:**
Use explicit per-connection mapping records. Validate allowed claim names and local targets. Keep provider presets separate from customer overrides. Require preview/test-login before activating a mapping change.

**Warning signs:**
- Role mapping is just a string-to-string map
- NameID is reused as email by default
- No per-connection mapping version exists
- A single IdP group name can grant local admin without an explicit mapping row

**Phase to address:**
Mapping persistence phase, then admin UI phase.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store all enterprise config in one JSON blob | Fast first implementation | No diff, rollback, validation, or per-field constraints | Never for trust-bearing data |
| Refresh metadata synchronously on login | Fewer background jobs | Latency spikes and login failures during upstream slowness | Only in CLI/tools, never runtime |
| Keep only one active cert slot | Simple UI and code | Guaranteed outage during rollover | Never in production |
| Write audit events as plain logs only | Quick to ship | No durable change history | Only as supplemental telemetry |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| IdP metadata URL | Assuming every provider supports the same refresh behavior | Support URL and file import, with provider-specific refresh semantics |
| Clustered Phoenix runtime | Updating config on one node and assuming the rest follow | Treat config writes as transactional and propagate through shared storage/jobs |
| Certificate rollover | Replacing the old cert before the new one is trusted everywhere | Keep overlap windows and stage promotion |
| Audit trail | Logging sensitive payloads for convenience | Store redacted, structured audit events with actor + before/after metadata |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Scanning every tenant on each login for expiry | Login latency grows with tenant count | Index expiry state and run scheduled checks | As soon as traffic or tenant count grows beyond a handful |
| Fetching metadata during the auth request | Random login timeouts | Refresh in background and cache last-known-good metadata | When upstream metadata is slow or unreachable |
| Recomputing mappings from raw XML every time | High CPU during peak SSO windows | Persist parsed, validated mapping state | When many users hit SSO at once |
| Serializing huge audit payloads inline | Slow config writes | Store compact diffs and references, not raw XML | When audit volume or XML size grows |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Trusting metadata without validating source, schema, and freshness | Stale or tampered trust config | Validate input, require HTTPS, store provenance, and keep last-known-good |
| Allowing key/cert rotation without overlap | Login outage during certificate changes | Maintain active/next certs and stage promotion |
| Logging raw assertions, private key material, or secrets | Sensitive data exposure | Redact aggressively and keep audit payloads minimal |
| Letting config changes bypass tenant/admin authorization | Cross-tenant tampering | Enforce scoped authorization and record actor identity on every change |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No preview before save | Admins can’t see the blast radius | Show diff + affected connections before activation |
| No trust-state visibility | Operators don’t know what is live | Surface current/next certs, refresh time, and expiry clearly |
| Unsafe options hidden in normal flow | Accidental insecure config | Put legacy overrides behind explicit warnings and audit |

## "Looks Done But Isn't" Checklist

- [ ] **Config saved:** saved in DB, but runtime still reads stale cached state
- [ ] **Metadata imported:** file parses, but no refresh cadence or expiry tracking exists
- [ ] **Rollover complete:** new cert added, but old cert removed too early
- [ ] **Audit enabled:** events exist, but you cannot reconstruct actor + before/after values

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Bad metadata import | High | Revert to last-known-good snapshot, re-fetch from source, and replay only validated changes |
| Failed cert rollover | High | Restore overlap trust, re-add retired cert temporarily, and complete promotion after verification |
| Broken mapping change | Medium | Roll back to prior mapping version and require a test-login before reactivation |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Config as blob | Schema + migrations phase | Can diff, roll back, and validate individual fields |
| Metadata freshness drift | Metadata import/export + refresh phase | Background refresh preserves last-known-good and records provenance |
| Replace-in-place rollover | Certificate lifecycle + rollover phase | Overlap window test proves old and new certs both work |
| Log-only audit trail | Audit schema + event emission phase | Every change has actor, before/after, and correlation id |
| Mapping drift | Mapping persistence phase | A bad mapping is rejected before activation and can be versioned back |

## Sources

- Microsoft Learn: [Tutorial: Manage federation certificates](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/tutorial-manage-certificates-for-federated-single-sign-on)
- Microsoft Learn: [Renew federation certificates for Microsoft 365 and Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-o365-certs)
- Microsoft Learn: [Troubleshoot SAML-based single sign-on](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/troubleshoot-saml-based-sso)
- AWS Docs: [Add a SAML 2.0 identity provider](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-configuring-federation-with-saml-2-0-idp.html)
- AWS Docs: [Configuring identity providers for your user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-identity-provider.html)
- AWS Docs: [Rotate SAML 2.0 certificates](https://docs.aws.amazon.com/singlesignon/latest/userguide/managesamlcerts.html)
- PingIdentity Docs: [Importing SP metadata](https://docs.pingidentity.com/pingfederate/latest/administrators_reference_guide/pf_importing_sp_metadata.html)
- PingIdentity Docs: [Manage digital signing certificates and decryption keys](https://docs.pingidentity.com/pingfederate/11.3/administrators_reference_guide/help_certmanagementtasklet_dsigsigningcert_certmanagementstate.html)
- SWITCH Help: [Shibboleth IdP Certificate Rollover](https://help.switch.ch/de/aai/guides/idp/certificate-rollover/)

---
*Pitfalls research for: Relyra enterprise configuration*
*Researched: 2026-04-25*
