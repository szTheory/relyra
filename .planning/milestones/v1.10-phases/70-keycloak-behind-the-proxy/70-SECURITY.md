---
phase: 70
slug: keycloak-behind-the-proxy
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-26
---

# Phase 70 — Security

> ASVS L1 verification of every STRIDE disposition authored across the fourteen Phase 70 plans.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser → Traefik → Keycloak/LedgerLoop | Traefik is the only browser ingress; management ports remain internal. | Public URLs, ephemeral credentials, SAML requests and responses |
| Keycloak descriptor → metadata parser → Ecto trust state | Untrusted descriptor XML crosses raw guards and one parse path before audited persistence. | Issuer, SSO endpoint, configured IdP certificates |
| Keycloak/FakeIdP ACS → Relyra verifier | Signed responses cross the existing digest, signature, protocol, and replay gates. | Untrusted SAMLResponse and correlation evidence |
| Provisioner → audited mutations → enabled resolver | Connection, metadata, certificate, and identity changes become login-capable only after atomic audited finalization. | Trust configuration and identity mappings |
| Runtime credentials → demo admin scope | Ephemeral host-admin credentials guard both bootstrap and mounted LiveAdmin routes. | Basic credentials and fixed principal/session scope |
| Browser/container output → diagnostic staging | Potentially sensitive output is redacted and independently validated before any promotion. | XML, PEM, credentials, headers, logs, browser artifacts |
| Audit storage → authenticated Login Trace UI | Durable security evidence is exported and rendered to operators through bounded, accessible presentation. | Typed rejection, verifier steps, synthetic long values |
| GitHub runner → optional demo topology | CI owns Docker, Playwright, temporary output, and cleanup for each recurring integration lane. | Ephemeral services, test credentials, pass/fail evidence |

## Threat Register

| Plan | Threat IDs | Categories | Severity | Disposition | Verified mitigation evidence | Status |
|------|------------|------------|----------|-------------|------------------------------|--------|
| 70-01 | T-70-01–05 | S, T, R, I, D | high–low | mitigate / accept | Proxy-only ingress and forwarded-header assertions; one-candidate audited descriptor apply; configured-certificate verification; bounded attributed retries. | closed (5/5) |
| 70-02 | T-70-06–09 | T, R, E, D | high–medium | mitigate | Disable-before-change, fingerprint comparison, active-before-retire, exact Sarah identity, fail-closed and audit/idempotency tests. | closed (4/4) |
| 70-03 | T-70-10–14 | S, I, T, D | high–medium | mitigate | Dual-host render checks, no management ingress, owned Compose lifecycle, redacted diagnostics, scoped cleanup. | closed (5/5) |
| 70-04 | T-70-15–18 | S, R, E, I | high–low | mitigate / accept | Enabled-connection-only affordance and durable-receipt wording without authorization claims or identifiers. | closed (4/4) |
| 70-05 | T-70-19–23 | S, R, I, T, E | high | mitigate | Exact public host/ACS/receipt/correlation assertions, ephemeral browser output, independent FakeIdP and security gates. | closed (5/5) |
| 70-06 | T-70-24–28 | T, R, S, I | high | mitigate | Exactly one guarded descriptor parse and candidate; MetadataApply/CertificateInventory seams; configured-cert trust and security gates. | closed (5/5) |
| 70-07 | T-70-29–34 | I, T, R, S | high | mitigate | Disabled Playwright attachments, owned temporary output, fail-closed redaction policy, provisioner/FakeIdP/security gates. | closed (6/6) |
| 70-08 | T-70-35–40 | E, S, I, R | high–medium | mitigate | Fail-closed BasicAuth on bootstrap and all LiveAdmin routes, fixed principal, ephemeral/redacted credentials, correlated trace tests. | closed (6/6) |
| 70-09 | T-70-41–45 | R, E, T, I, D | high–low | mitigate / accept | Identity insert, mapping audit, and enable in one transaction; rollback injection; uniqueness; bounded audit fields; fail-closed retry. | closed (5/5) |
| 70-10 | T-70-46–50 | I, T, D, E, R | high–low | mitigate / accept | QName-aware XML/PEM redaction, independent staging rejection, fail-closed malformed XML, absent/partial auth denial, self-tests. | closed (5/5) |
| 70-11 | T-70-31–34 | R, T, I, D | high–medium | mitigate | Focused scenario status, no advisory suppression, ephemeral redacted browser output, owned bounded Docker CI workflow. | closed (4/4) |
| 70-12 | T-70-35–38 | T, E, D, I | high–medium | mitigate | Solver-backed Req 0.7.4, Finch 0.23.0, Mint 1.9.3 checksums; no new ignore; full repository gates unchanged. | closed (4/4) |
| 70-13 | T-70-39–42 | I, T, D, E | high–medium | mitigate | Opt-in synthetic AuditWriter fixture, unchanged default reset, labelled focusable overflow region, contract tests. | closed (4/4) |
| 70-14 | T-70-43–47 | S, E, I, R, D | high–medium | mitigate | Real tampered ACS rejection, guarded trace access, per-run credentials, disabled attachments, semantic/keyboard/narrow/long-value browser assertions. | closed (5/5) |

The gap-closure plans intentionally reuse threat-number ranges from earlier plans; the plan column is therefore part of each threat's stable identity. All 67 authored rows were evaluated.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-70-01 | 70-01 / T-70-05 | Local-demo readiness retries are bounded, fail nonzero, and attribute the failing layer; production availability is outside KC-01. | Phase 70 plan | 2026-08-26 |
| AR-70-02 | 70-04 / T-70-18 | The UI exposes only the locked generic receipt sentence and no receipt, user, or database identifiers. | Phase 70 plan | 2026-08-26 |
| AR-70-03 | 70-09 / T-70-45 | Transaction/audit failures fail closed, disable the optional profile, and remain safely retryable. | Phase 70 plan | 2026-08-26 |
| AR-70-04 | 70-10 / T-70-48 | Unterminated protected XML suppresses the remaining diagnostic input; loss of diagnostics is safer than partial secret retention. | Phase 70 plan | 2026-08-26 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-26 | 67 | 67 | 0 | gsd-security-auditor |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-26
