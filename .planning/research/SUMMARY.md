# Research Summary: Relyra v0.6

**Domain:** Enterprise SAML 2.0 Library for Elixir
**Researched:** 2026-05
**Overall confidence:** HIGH

## Executive Summary

Research into the v0.6 milestone indicates that Single Logout (SLO) is the most complex and fragile feature. In 2026, major browser changes (death of 3rd-party cookies) severely impact front-channel SLO implementations relying on hidden iframes. Relyra must implement standard iterative front-channel redirects or POST bindings, but must document SLO as a "best effort" optimization that does not replace strict, short-lived session timeouts. Security for SLO remains critical, requiring strict signature validation and `InResponseTo` tracking to prevent replay attacks and XML Signature Wrapping (XSW).

Diagnostic bundles for operators must prioritize safety by using an **allow-list** approach to serialization rather than a deny-list, ensuring no PII or cryptographic secrets leak when an operator exports a bundle. This can be built entirely using Erlang's `:zip` standard library. 

Certificate expiry alerting should adhere to Elixir telemetry best practices. Since Relyra is a library, it should not dictate a cron scheduler (like Oban). Instead, it should provide a callable function that traverses tenant configurations and emits standard `:telemetry` events (e.g., `[:relyra, :certificate, :expiring]`). The host application is responsible for scheduling this check.

## Key Findings

**Stack:** Standard library Erlang `:zip` for bundles; `:telemetry` for alerts; existing hardened XML core for SLO. No new dependencies.
**Architecture:** Expiry checks as pure functions; SLO deeply integrated with Relyra's `SessionAdapter`; Bundles via allow-list serializers.
**Critical pitfall:** Implementing SLO as a guaranteed security boundary instead of a "best-effort" UX feature; data leakage in diagnostic bundles.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase 22 - Certificate Expiry Alerts (CERT-EXP-01)** - Low complexity, isolated.
   - Addresses: Emitting events for upcoming certificate expirations.
   - Avoids: Forcing a specific job scheduler on the host app.

2. **Phase 23 - Diagnostic Bundles (DIAG-01)** - Medium complexity.
   - Addresses: Exporting a redacted `.zip` for troubleshooting.
   - Avoids: PII/Secret leakage by enforcing an allow-list schema for serialization.

3. **Phase 24 - Single Logout Protocol (SLO-01)** - High complexity.
   - Addresses: SP and IdP initiated logout flows.
   - Avoids: Replay attacks and XSW through strict validation and `InResponseTo` state tracking.

**Phase ordering rationale:**
- Expiry alerts and diagnostic bundles are operational improvements that can be built on the existing v0.5 data models without protocol changes. Building them first delivers immediate value.
- SLO requires changes to the `Protocol` bounded context, session state integration, and potentially new Ecto state for `InResponseTo` tracking. It should be the final phase of the milestone.

**Research flags for phases:**
- Phase 22: Standard patterns, unlikely to need research.
- Phase 23: Standard patterns, but requires strict code review on the redaction allow-list.
- Phase 24: Likely needs deeper architectural design for binding the `SessionAdapter` to incoming asynchronous SLO requests.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core BEAM capabilities (`:zip`, `:telemetry`) perfectly match requirements. |
| Features | HIGH | Clear scope for what should and shouldn't be built. |
| Architecture | MEDIUM | SLO session termination across distributed Elixir nodes needs care via `SessionAdapter`. |
| Pitfalls | HIGH | Known history of SAML SLO failures and 2026 browser privacy impacts are well documented. |

## Gaps to Address

- **SLO Distributed Session State:** How exactly Relyra's `SessionAdapter` will correlate an incoming IdP-initiated `<LogoutRequest>` (which only contains a `NameID` and optionally `SessionIndex`) to a specific local Phoenix session. This requires host-app cooperation to index sessions by SAML `SessionIndex`.