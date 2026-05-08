# Domain Pitfalls

**Domain:** Enterprise SAML 2.0 Library for Elixir (v0.6 Milestone)
**Researched:** 2026-05

## Critical Pitfalls

Mistakes that cause rewrites, security incidents, or major operational issues.

### Pitfall 1: Data Leakage in Diagnostic Bundles
**What goes wrong:** A developer exports the full connection state to help an operator debug an issue, inadvertently including cryptographic material, PII, or internal tokens in the downloaded `.zip` file.
**Why it happens:** Using a "deny-list" approach (e.g., removing known secrets from a struct) instead of an "allow-list" approach. When a new secret field is added later, the deny-list isn't updated, and the secret leaks.
**Consequences:** Complete compromise of SAML trust if signing keys or IdP secrets are leaked.
**Prevention:** Strictly enforce an **allow-list** mapping function for all data entering the diagnostic bundle. The compiler should complain if the shape changes, or the mapping should purely construct a new map with explicitly named safe fields.

### Pitfall 2: Signature Wrapping (XSW) on LogoutRequests
**What goes wrong:** The library rigorously validates signatures on `<Response>` and `<Assertion>` elements but uses a looser, unhardened parser for `<LogoutRequest>` elements.
**Why it happens:** SLO is often treated as an afterthought. Developers might use a different parsing path or fail to enforce the strict canonicalization rules applied to login.
**Consequences:** An attacker can forge a `<LogoutRequest>`, causing denial-of-service (signing out legitimate users) or bypass mechanisms.
**Prevention:** `<LogoutRequest>` and `<LogoutResponse>` must be routed through the exact same hardened `Relyra.Security.XML` boundary established in v0.1.

### Pitfall 3: Browser 3rd-Party Cookie Blocking (SLO Failure)
**What goes wrong:** IdP-initiated SLO via hidden iframes fails silently.
**Why it happens:** By 2026, major browsers strictly enforce 3rd-party cookie blocking. If the IdP tries to log the user out of Relyra by loading Relyra's logout endpoint in a hidden iframe on the IdP's domain, the browser blocks the session cookie, and the user remains logged into the Phoenix application.
**Consequences:** Orphaned sessions. The user believes they are logged out, but the session remains active.
**Prevention:** Document SLO as a "best-effort" enhancement. Strongly recommend (in guides and documentation) that host applications implement strict absolute session timeouts. Relyra must use top-level redirects for SLO where possible.

## Moderate Pitfalls

### Pitfall 4: Uncorrelated IdP-Initiated Logout
**What goes wrong:** The IdP sends a `<LogoutRequest>` containing only a `NameID` and `SessionIndex`. The Phoenix app doesn't know which local HTTP session corresponds to those SAML identifiers.
**Prevention:** The `Relyra.SessionAdapter` contract needs a way to broadcast or look up local sessions based on the SAML `SessionIndex` provided during the initial SSO login. This often requires the host app to store the `SessionIndex` in a centralized cache or database alongside the session ID.

### Pitfall 5: Duplicated Expiry Telemetry
**What goes wrong:** The certificate expiration check runs on all 10 nodes in a Phoenix cluster simultaneously, emitting 10x the actual number of alerts.
**Prevention:** Design the check as a stateless function (`Relyra.check_certificate_expirations/0`). Mandate in the documentation that the host application schedules this function using a cluster-aware job runner like Oban.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 22 (Alerts) | Memory bloat on massive tenant counts. | Use Ecto streaming instead of `Repo.all`. |
| Phase 23 (Bundles) | Leaking sensitive data. | Strict allow-list serialization mapping. |
| Phase 24 (SLO) | Replay attacks on LogoutResponses. | Utilize the existing Replay store to track `InResponseTo` state for outgoing requests. |

## Sources

- 2026 Browser Privacy standards (deprecation of 3rd party cookies).
- `ruby-saml` CVE-2024-45409 / SAML Security Post-mortems.