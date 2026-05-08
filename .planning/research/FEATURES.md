# Feature Landscape

**Domain:** Enterprise SAML 2.0 Library for Elixir (v0.6 Milestone)
**Researched:** 2026-05

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| SP-Initiated SLO | Users expect to click "Logout" and be signed out of the IdP. | Med | Requires generating `<LogoutRequest>` and handling the `<LogoutResponse>`. |
| IdP-Initiated SLO | IdPs expect to send a `<LogoutRequest>` to the SP when a user signs out globally. | High | Requires correlating the SAML `NameID` / `SessionIndex` to a local Phoenix session via the `SessionAdapter`. |
| Bundle Redaction | Security requirement for diagnostic exports. | Med | Must strictly allow-list fields (e.g. `entity_id`, `sso_url`, cert expiry dates) and omit keys, secrets, or user data. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Emitted Telemetry for Expiry | Proactive operational safety. Instead of finding out via an outage, operators get metrics. | Low | Exposes `[:relyra, :certificate, :expiring]` events with days remaining. |
| Pure-BEAM Zip Generation | Operator can download a diagnostic zip straight from the LiveView admin panel without server disk writes. | Low | Generates the archive in memory and streams it to the browser. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Internal Cron Scheduler | Bloats the library, assumes host architecture, risks clustering issues. | Provide `Relyra.check_certificates/0`. Host application orchestrates the cron (e.g., Oban). |
| Back-Channel (SOAP) SLO | Rare in modern SaaS, requires network reachability from IdP to SP, complex to test. | Stick to Front-Channel (HTTP-Redirect / HTTP-POST). |
| iFrame-based SLO | Broken by 2026 browser 3rd-party cookie policies. | Use iterative top-level redirects or document SLO as "best effort". |

## Feature Dependencies

- **Diagnostic Bundles** → Requires existing connection/metadata state models.
- **IdP-Initiated SLO** → Requires `SessionAdapter` contract expansion to support "revoke by SessionIndex".

## MVP Recommendation

Prioritize:
1. **Certificate Expiry Alerts**: Highest ROI for operator safety.
2. **Diagnostic Bundles**: Eases debugging for support teams.
3. **SP-Initiated SLO**: Easier than IdP-initiated.
4. **IdP-Initiated SLO**: Do last, as it requires complex local session lookups.

## Sources
- 2026 SAML Security Landscape (Browser Privacy / 3rd-Party Cookie phase-out).
- `PROJECT.md` Constraints ("Relyra is a library").