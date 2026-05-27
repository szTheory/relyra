# Relyra

## What This Is

Relyra is an open-source **SAML 2.0 Service Provider library for Elixir and Phoenix** — strict-by-default validation, multi-tenant enterprise SSO, four first-class provider presets (Okta, Microsoft Entra ID, Google Workspace, ADFS) plus a generic-SAML runbook with vendor decoder tables for seven more IdP families (Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, Oracle Access Manager), telemetry, audit events, **and** durable enterprise configuration: persisted connection records, runtime snapshot resolution, metadata import/export with controlled refresh, certificate inventory with staged rollover, and persisted attribute/group mappings backed by a cross-domain audit ledger. It is for Phoenix SaaS teams that need secure enterprise SSO without becoming SAML experts, and for the platform/auth/security/SRE engineers who will have to operate that SSO safely for years.

## Core Value

**Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.** Relyra consumes only the exact signed XML node it verified, against configured IdP certificates, with replay protection and protocol validation, and it explains every decision in a trace an operator can act on. Trust mutations are durable, attributable, and reviewable: every connection / metadata / certificate / mapping change co-commits an audit row inside the same transaction as the data it describes. If everything else fails, *those* invariants must hold.

Positioning tagline: **"Enterprise SAML, calmly verified."**

## Current State

- **v0.1 shipped 2026-04-25** — strict SP core with hardened XML, protocol validation, behaviour-backed stores, Phoenix runtime, telemetry, adopter docs.
- **v0.2 shipped 2026-05-06** — durable enterprise configuration. 5/5 requirements verified, 168/168 serial tests green, cross-domain audit ledger live.
- **v0.3 shipped 2026-05-06** — LiveView admin surface. All capabilities from v0.2 are now exposed via a mountable interface. 10/10 requirements verified.
- **v0.4 shipped 2026-05-06** — IdP-initiated SSO and opaque RelayState. 1/1 requirements verified.
- Code state at v0.4 close: ~17,200 LOC across `lib/` and `test/` (Elixir).
- **v0.5 shipped** — Operational maturity. Phase 20 (bulk operations, CFG-07), Phase 21 (scheduled metadata refresh, CFG-08), Phase 21.1 (CFG-07 bulk-refresh audit correlation_id forwarding), and Phase 21.2 (audit-gap closure + scope re-alignment) shipped 2026-05-07. Debug bundles (DIAG-01) and Expiry alerts (CERT-EXP-01) re-scoped to v0.6 per the v0.5 milestone audit.
- **v0.6 shipped 2026-05-08** — Operational maturity carryover + SLO. Phase 22 (certificate expiry alerts), Phase 23 (diagnostic bundles), and Phase 24 (Single Logout) are complete and verified.
- **v1.0 shipped 2026-05-08** — Conformance, security review readiness, and adopter onboarding polish. Phase 25 added executable SP conformance and pinned CVE regressions; Phase 26 added the reviewer packet, generated evidence, and strict-default proof lanes; Phase 27 added authoritative onboarding, runbooks, case studies, and batteries-included proof.
- **v1.1 shipped 2026-05-25** — Verify the Trust Path. Phase 28 proved exclusive-C14N over a real parse tree; Phase 29 wired genuine `:public_key.verify` + `DigestValue` recompute onto both response and metadata-root paths; Phase 30 made the adversarial crypto corpus permanently gate `mix ci.security`; Phase 31 aligned reviewer docs, findings ledger, and staged advisory artifacts to the shipped proof surface. Full suite remained green and the published-hex SAML auth-bypass is closed in code.
- **v1.3 shipped 2026-05-27** — Advanced Federation. Phase 32 extended AlgorithmPolicy and schema support, Phase 33 shipped the `KeyResolver` / XMLEnc core, Phase 34 closed ENC-01 + ENC-02, Phase 35 shipped signed redirect-binding AuthnRequests plus the ADFS preset/runbook and AUTHN-01 corpus, and Phases 36-37 completed the generic SAML and identity-mapping operator guides.
- **v1.4 shipped 2026-05-27** — Full SLO + Ops Polish. Phase 38 shipped SLO core + security (SLO-01), Phase 39 shipped the logout strategy guide (DOCS-04), Phase 40 shipped the operator incident playbook + Error Atom Decoder (DOCS-05, DOCS-06), and Phase 40.1 closed the v1.4 milestone-audit gaps: retroactive 38/39 VERIFICATIONs, `guides/recipes/logout.md` rewritten to canonical 4-arg `SessionAdapter` signatures with a host-owned-linkage subsection, and a live `test/docs/logout_recipe_drift_test.exs` wired into `ci.docs`. With v1.4 shipped, Relyra has crossed the "done-enough" line drawn in PROJECT.md: future scope is demand-gated, not coverage-gated.
- **v1.5 Phase 42 complete 2026-05-27** — Stepwise login-trace LiveView at `/relyra/admin/connections/:id/trace` plus `mix relyra.trace` headless companion. TRACE-01/02/03 verified: telemetry handler persists login audit rows, shared `LoginTrace.Export` redaction, security corpus wired into `mix ci.security`.
- **v1.5 Phase 43 complete 2026-05-27** — Release-prep staging: `mix.exs` and release-please manifest at `1.4.0`, `guides/getting_started.md` pin `~> 1.4`, hand-written CHANGELOG `[1.3.0]`/`[1.4.0]` sections with single-jump rationale. PUB-01/PUB-02 verified; git tag and Hex publish deferred to Phase 44.

## Current Milestone: v1.5 Publish, Prove, Polish

**Goal:** Transform Relyra from "1.2 on Hex with some git tags" into "v1.4 shipped, every login explains itself, installs in 15 minutes" — close the gap between the code and what adopters can actually see. Single polish milestone, ~1 week scope. NOT a new feature wedge.

**Target features (3 wedges):**

1. **Ship v1.3 + v1.4 to Hex** — bump `mix.exs` `1.2.0` → `1.4.0`, fix `~> 0.1.0` pin in `guides/getting_started.md:26`, backfill CHANGELOG `[1.3.0]`/`[1.4.0]`, diagnose the stalled release-please flow, tag `v1.4.0` (SemVer), publish via automation. Post-publish parity verification.
2. **Stepwise login-trace LiveView** at `/relyra/admin/connections/:id/trace` — makes "every login explains itself" concretely visible. Reuses telemetry catalog + audit ledger + LiveAdmin scaffold. Optional `mix relyra.trace` headless companion. Security gate: no raw XML/PEM/key material in UI.
3. **README/installer ergonomics + warning-level tech-debt sweep** — auto-inject `saml_routes()` in `mix relyra.install`, lead README with `apply_defaults(:okta, …)` snippet, close v1.3 audit warnings (WR-01/02 regex-alongside-tree, WR-03 metadata attribute escaping, WR-04 test_support in prod artifact, WR-ENC-ATTR doc drift), close Phase 40 formatting drift, dedupe `BATTERIES_INCLUDED.md`, add `guides/overview.md` job-shaped index, fix "8 presets" → "4 first-class + generic runbook" copy drift.

**After v1.5:** pause. AUTHN-POST-01, KMS-01, SIGNED-META-01 remain demand-gated with pre-baked plans in `.planning/threads/`. Full scope in `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md`.

## Next Milestone Goals (post-v1.5)

**Done-enough line reached at v1.4 for the *code* — Hex publish staging complete at `1.4.0` in Phase 43; tag + publish land in Phase 44.** All v1.x core scope (Verify-the-Trust-Path → Advanced Federation → Full SLO + Ops Polish) shipped to git; mix.exs is now `@version "1.4.0"` with CHANGELOG backfill. Adopter-first assessment 2026-05-27 (parallel candidate research + DX audit) confirmed: **the library is protocol-feature complete and adopter-blocked until Hex publish completes.**

**Active: v1.5 — "Publish, prove, polish" (see Current Milestone section above).**

Scoped in `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md`. Three wedges:

1. **Ship v1.3 + v1.4 to Hex** — bump `mix.exs` to `1.4.0`, fix the `~> 0.1.0` pin in `guides/getting_started.md:26`, backfill CHANGELOG `[1.3.0]`/`[1.4.0]` sections, diagnose stalled release-please flow, tag `v1.4.0` SemVer, publish.
2. **Stepwise login-trace LiveView** at `/relyra/admin/connections/:id/trace` — makes the "every login explains itself" brand promise concretely visible to adopters; reuses existing telemetry catalog + audit ledger + LiveAdmin scaffold.
3. **README/installer ergonomics + warning-level tech-debt sweep** — auto-inject `saml_routes()`, lead README with `apply_defaults(:okta, …)` snippet, close v1.3 audit warnings WR-03 (unescaped metadata attribute interpolation, defense-in-depth XSS-class gap) + WR-04 (test_support in prod artifact) + WR-01/02 (regex-alongside-tree detector) + WR-ENC-ATTR (doc drift), close Phase 40 deferred formatting drift, dedupe BATTERIES_INCLUDED.md pair, add `guides/overview.md` job-shaped index.

After v1.5: pause. Three demand-gated candidates below remain explicitly out-of-active-scope; each has a pre-baked plan ready to ship 2-3 weeks after a real GitHub issue lands.

A "Scope boundary & diminishing returns" section in `CONFORMANCE.md` should record the shipping milestone arc and the explicit "no more" boundary (HTTP-Artifact, ECP, Attribute Query, SCIM-in-core, more presets-without-generic-path, full standalone app — all explicitly out of scope at this stage).

**Demand-gated future candidates** (do NOT plan unless adoption signal materializes; assessment 2026-05-27 reconfirmed all three as save-for-demand):

- **AUTHN-POST-01** — HTTP-POST binding signed AuthnRequests (enveloped XML signature + C14N). Carry-forward from v1.3.
- **KMS-01** — KMS-native `KeyResolver` adapters (AWS KMS, GCP KMS). Carry-forward from v1.3.
- **SIGNED-META-01** — Signed SP metadata (`EntityDescriptor`) for academic federation / InCommon. Carry-forward from v1.3.

**Known carry-forward maintenance items (low priority, surface only on need):**

- CVE ID backfill into `docs/advisories/2026-001-...` when GitHub assigns it (pending async).
- Phase 29 warning-level review items (`WR-02..WR-05`, `IN-01..IN-03`) — non-blocking.

## Shipped Milestones — v1.x Arc Summary

The v1.x milestone arc closed with v1.4:

- **v1.0** — Conformance, security review readiness, and adopter onboarding polish (Phases 25-27).
- **v1.1** — Verify the Trust Path: real exclusive-C14N, genuine XMLDSig `:public_key.verify`, adversarial crypto corpus permanently gating CI, disclosure honesty (Phases 28-31).
- **v1.3** — Advanced Federation: encrypted assertions (ENC-01), signed AuthnRequests (AUTHN-01), generic SAML and identity-mapping operator guides (Phases 32-37).
- **v1.4** — Full SLO + Ops Polish: full SLO round-trip (SLO-01), logout strategy guide (DOCS-04), Incident Response Playbook (DOCS-05), SAML Error Atom Decoder (DOCS-06), audit-closure Phase 40.1 (Phases 38-40.1).

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

**v0.1:**
- ✓ XML strategy ADR locked (GATE-01/GATE-03) — v0.1
- ✓ Hardened XML seam contract (SEC-01) — v0.1
- ✓ Canonicalization acceptance gate contract (GATE-02) — v0.1
- ✓ SP-initiated protocol core (SEC-02/03/04/05/07, PROT-01/02/03/05) — v0.1
- ✓ Store-backed trust gates (SEC-06, PROT-04, EXT-01..05) — v0.1
- ✓ Phoenix runtime integration (PHX-01/02/03/04) — v0.1
- ✓ Observability and enforcement (OBS-01..05, SEC-08) — v0.1
- ✓ Phase 06 delivery hardening (provider presets, TestSupport/FakeIdP, installer scaffolding, release discipline, scope-first docs) — v0.1

**v0.2:**
- ✓ **CFG-01** — Tenant-scoped SAML connection records (Ecto schemas + migrations) — v0.2 (Phase 07; 5/5 truths verified 2026-05-05)
- ✓ **CFG-02** — Persisted connection → runtime snapshot resolution — v0.2 (Phase 08; 5/5 truths verified 2026-05-05)
- ✓ **CFG-03** — Metadata import/export + controlled refresh w/ provenance — v0.2 (Phase 09 verified via Phase 12; serial smoke 15/15, full suite 168/168)
- ✓ **CFG-04** — Certificate inventory w/ expiry tracking + staged rollover — v0.2 (Phase 10 verified via Phase 13; serial rollover 23/23, manual sign-off)
- ✓ **CFG-05** — Persisted attribute/group mapping + durable audit history — v0.2 (Phase 11 verified via Phase 14; serial mapping/audit 62/62, manual sign-off)

**v0.3:**
- ✓ **CFG-06** — LiveView admin surface exposing connections, metadata, certificates, and mapping configuration — v0.3 (Phases 15-18; 10/10 requirements verified 2026-05-06)

**v0.4:**
- ✓ **IDP-INIT-01** — IdP-initiated SSO support with security guardrails and opaque RelayState handling — v0.4 (Phase 19; 1/1 requirements verified 2026-05-06)

**v0.5:**
- ✓ **CFG-07** — Bulk operations across multiple connections — v0.5 (Phase 20; CFG-07 verified 2026-05-06; Phase 21.1 closed audit BLOCKER INT-01 by forwarding bulk correlation_id through Refresh.refresh/2)
- ✓ **CFG-08** — Scheduled metadata refresh automation with guardrails — v0.5 (Phase 21; CFG-08 verified 2026-05-07; 22/22 must-haves verified, 344 tests + 8 ci.oban_smoke green, dual compile lanes green)

**v0.6:**
- ✓ **CERT-EXP-01** — Operator alerts for upcoming SAML signing certificate expirations — v0.6 (Phase 22 verified 2026-05-07)
- ✓ **DIAG-01** — Operator can export redacted diagnostic bundle — v0.6 (Phase 23 verified 2026-05-07)
- ✓ **SLO-01** — Single Logout (SP-initiated and IdP-initiated) — v0.6 (Phase 24 verified 2026-05-07)

**v1.0:**
- ✓ **CONF-01** — Protocol behavior adheres strictly to SAML conformance profiles — v1.0 (Phase 25 verified 2026-05-07)
- ✓ **CVE-REG-01** — Regression test suite includes fixtures for known historical SAML CVEs — v1.0 (Phase 25 verified 2026-05-07)
- ✓ **SEC-REVIEW-01** — External security audit completion and remediation readiness — v1.0 (Phase 26 verified 2026-05-08)
- ✓ **DOCS-01** — Adopter case studies and frictionless Day-1 experience documentation — v1.0 (Phase 27 verified 2026-05-08)

**v1.1:**
- ✓ **SIGV-03** — exclusive XML canonicalization (C14N 1.0 exclusive) over a real `saxy` parse tree behind the `Relyra.Security.XML` seam, replacing regex string-scanning; canonical bytes proven byte-for-byte against an independent libxml2/xmlsec1 golden oracle (887 bytes) — v1.1 (Phase 28; SIGV-03 verified 2026-05-24, UAT 8/8, SECURITY threats_open 0)
- ✓ **SIGV-01** — Response/assertion XMLDSig signatures cryptographically verified: canonicalized `SignedInfo` checked via `:public_key.verify` against the **configured** IdP cert (never document `KeyInfo`); forged/wrong-key signatures rejected with typed errors — v1.1 (Phase 29 verified 2026-05-24)
- ✓ **SIGV-02** — Reference `DigestValue` recomputed over the canonicalized referenced element and compared constant-time (`:crypto.hash_equals`, length-guarded); content tampering (e.g. altered `NameID`) rejected as `:digest_mismatch` — v1.1 (Phase 29 verified 2026-05-24)
- ✓ **SIGV-04** — Metadata-root (`EntityDescriptor`) signatures verified with the SAME crypto primitive (signature math, not pinning-alone), with operator-pinned `TrustAnchor` as defense-in-depth — v1.1 (Phase 29 verified 2026-05-24; post-review hardened so the signature is verified against the pinned cert only — CR-01 — and the pin fingerprint is DER, matching openssl — CR-02)
- ✓ **ASSUR-02** — `TestSupport.FakeIdP.sign` performs REAL XMLDSig signing (delegates to the genuine `XmldsigSigner`, real `DigestValue` + `SignatureValue`), so the whole suite exercises real verification, not structure-only acceptance — v1.1 (Phase 30 verified 2026-05-24, 9/9 must-haves)
- ✓ **ASSUR-01** — permanent `@tag :adversarial_crypto` corpus proving the verifier rejects every named attack (forged-sig/wrong-key → `:invalid_signature`; tampered-content & c14n-differential → `:digest_mismatch`; ECDSA → `:unsupported_signature_algorithm`) and accepts only a genuine signature, wired into the conformance manifest and **genuinely** gated by `mix ci.security`. Found and fixed a latent hollow-gate (Mix `test`-task dedup made post-`ci.conformance` `test` lines silent no-ops); each security suite now runs as `cmd mix test` + an anti-hollow meta-gate (`ci_gate_integrity_test.exs`) prevents recurrence — v1.1 (Phase 30 verified 2026-05-24)

**v1.3:**
- ✓ **ENC-01** — Encrypted assertions (`EncryptedAssertion` / XML-Enc): single `<EncryptedAssertion>` decrypted (RSA-OAEP + AES-256-GCM), spliced, and re-parsed through the SAME `PureBeam.parse_safely/2` seam so `Signature.do_verify/4` runs before any identity field is read; cleartext+encrypted and >1-encrypted rejected `:ambiguous_assertion` before crypto; single opaque `:decryption_failed`; 7-fixture pipeline-level adversarial corpus gated by `mix ci.security` — v1.3 (Phase 34; 5/5 success criteria verified 2026-05-25)
- ✓ **ENC-02** — SP metadata publishes distinct `<KeyDescriptor use="encryption">` and `<KeyDescriptor use="signing">` (base64-of-DER, PUBLIC certs only, schema-valid ordering) — v1.3 (Phase 34 verified 2026-05-25)
- ✓ **AUTHN-01** — Signed AuthnRequests: HTTP-Redirect binding signing for `WantAuthnRequestsSigned` IdPs (ADFS, Shibboleth); raw query bytes signed verbatim; bit-for-bit golden corpus + ADFS-style variant gated by `mix ci.security` — v1.3 (Phase 35 verified 2026-05-26)
- ✓ **DOCS-02** — Generic SAML runbook (`guides/recipes/generic_saml.md`) with field-name decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder, ADFS, Shibboleth — v1.3 (Phase 36 verified 2026-05-26)
- ✓ **DOCS-03** — Identity mapping & provisioning guide (`guides/identity_mapping_and_provisioning.md`): NameID vs app identity, 3 mapping patterns, JIT decision tree, explicit SCIM non-goal — v1.3 (Phase 37 verified 2026-05-26)

**v1.4:**
- ✓ **DOCS-04** — Publish `guides/recipes/logout.md` detailing when to enable SLO, session-model implications, 3rd-party cookie caveats, and absolute-timeout fallbacks — v1.4 (Phase 39 verified 2026-05-27)
- ✓ **DOCS-05** — Publish `guides/operations/incident_playbook.md` providing a narrative playbook that stitches together telemetry, audit events, the LiveView admin, and 7 Mix tasks; six Triage→Diagnose→Recover scenarios; explicit no-audit-signal callout for replay storms — v1.4 (Phase 40 verified 2026-05-27)
- ✓ **DOCS-06** — Publish `guides/troubleshooting.md` as the SAML Error Atom Decoder (78 H3 atom entries across 7 trust-pipeline-seam buckets with the four-field Means/Likely root cause/Operator action/Source micro-block), paired with `test/docs/troubleshooting_drift_test.exs` enforcing bidirectional code↔doc parity (D-08 union of three regex patterns vs D-09 H3 anchor regex); wired into `ci.docs` via presence guards + `cmd mix test` drift-test step; `ci.security` byte-equivalent (Phase 30 hollow-gate invariant preserved) — v1.4 (Phase 40 verified 2026-05-27)

### Active

<!-- Carried forward; building toward these next. -->

v1.5 polish milestone in flight (see "Current Milestone" above). v1.5 REQ-IDs land in `.planning/REQUIREMENTS.md` and are mirrored here at phase verification. After v1.5: Active returns to empty unless a demand-gated candidate (AUTHN-POST-01 / KMS-01 / SIGNED-META-01) is triggered by an adopter issue.

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **Hosted SSO broker / SaaS runtime** — Relyra is a library; customer data and control stay in host applications.
- **OIDC/OAuth in-core** — Relyra is SAML-specific; OIDC/OAuth belongs to adjacent libraries.
- **Generic auth framework (passwords/MFA/session system)** — session establishment is delegated via `SessionAdapter`; host app owns auth domain.
- **Production IdP implementation** — `Relyra.TestSupport.FakeIdP` is dev/CI support only, not a product IdP.
- **SCIM lifecycle ownership** — Relyra focuses on login-time identity assertion and mapping, not full lifecycle provisioning.
- **Security-by-marketing claims (bulletproof/unhackable/military-grade)** — brand and security discipline require precise, falsifiable claims only.

## Context

**Ecosystem state (April 2026, per deep-research doc):** Elixir has two SAML SP libraries. `samly` (Plug/Phoenix SP, last Hex release Jan 29 2024, v1.4.0) depends on `esaml`, which has a 2026 NVD entry for XXE-before-signature-verification on OTP < 27 — a trust-gap signal that "mostly works" is not enough on the auth boundary. `ex_saml` (v1.0.2, April 16 2026) is a Samly-derived successor that already ships path/subdomain IdP resolution, pluggable storage, RelayState anti-replay, XML entity disabling, and SHA-1 rejection, but Hex adoption signals remain low. Relyra's opening was not "write a SAML library" but "become the trusted default for Elixir/Phoenix teams that need enterprise SSO without becoming SAML experts."

**State at v0.2 close:** the v0.1 trust core (hardened XML, strict protocol, behaviour-backed stores, Phoenix runtime, observability) is now backed by durable configuration: connection records persist, resolver hydration is canonical, metadata refresh is operator-triggered with last-known-good preservation, certificate rollover is staged with optimistic-locked transitions, and every trust mutation co-commits an audit row in the same transaction as the change. The library is usable end-to-end for multi-tenant Phoenix SaaS teams that want to manage SAML connections in their own database without an external admin UI. The next adoption ramp is the optional LiveView admin (v0.3).

**Engineering DNA (per `prompts/relyra-engineering-dna-from-prior-libs.md`):** Convergent patterns from ten sibling libs continue to apply. The v0.2 closure-phase pattern (12 → produces 09's verification, 13 → 10's, 14 → 11's) is a new addition worth carrying forward when an audit surfaces verification orphans without re-opening implementation.

**Cross-ecosystem lessons (per deep research):** The v0.2 audit ledger borrows the Spring/Sustainsys "configurable registration object" framing (per-connection trust state lives in one place) and Python `python3-saml`'s "make security history visible in release notes" discipline (every audit-relevant field is rendered as an audit row, not a log line).

**Brand voice (per `prompts/relyra-brand-book.md`):** Calm, exact, transparent, operator-friendly, open-source serious. The v0.2 audit ledger is the brand metaphor made concrete — the "verified trust path" is now a queryable timeline an operator can read like a logbook.

**Product principles (table stakes — locked):**

1. **Strict defaults, explicit escape hatches.** Unsigned assertions rejected. SHA-1 rejected. Replay cache required in production. Unsafe compatibility exists only behind audited, time-boxed overrides.
2. **Phoenix-native ergonomics.** Router macro, Plug pipeline, generators, `{:ok, _} | {:error, %Relyra.Error{}}`, Ecto schemas as a first-class integration (v0.2+), telemetry, test helpers. No sidecar services.
3. **Verify the right thing.** Consume only the signed XML node that was verified. One hardened parser path. No parser differentials.
4. **Explainable by default.** Every SAML login produces a validation trace. Every unsafe option leaves an audit event. Every trust mutation produces an audit row in the same transaction as the change. Error messages name the exact field that mismatched, the expected value, and what to fix in the IdP.
5. **Operable from day one.** Certificate expiry alerts, metadata refresh (v0.2+), staged rollover (v0.2+), structured-redacted logs, debug bundles, provider-specific runbooks.
6. **Multi-tenant first.** Per-organization SAML connections (durable from v0.2), dynamic IdP resolution via `Relyra.ConnectionResolver`, attribute/group mapping (durable from v0.2), JIT provisioning hooks.
7. **Sustainable OSS.** Visible security policy (`SECURITY.md` + private advisory workflow), CI matrix, permanent regression fixtures for every known SAML CVE, release automation, changelog discipline.

**Bounded contexts (per `boundary` compiler):** (1) Protocol Core — pure SAML, no Phoenix/Plug/Ecto/LiveView; (2) Trust & Metadata — cert inventory, metadata import/export/refresh, rollover (durable from v0.2); (3) Connection Management — tenant↔IdP config, provider presets, connection state, audit log (durable from v0.2); (4) Phoenix/Plug Runtime — router macro, ACS endpoint, session-adapter integration; (5) Identity Mapping & Provisioning — NameID/attribute → local user via host callbacks, JIT policy, group-role mapping (durable from v0.2); (6) Observability & Audit — telemetry, redacted logs, audit events (cross-domain hardened in v0.2), debug bundles.

**Prior-research canon** (authoritative; do not re-derive):

- `prompts/RELYRA-GSD-IDEA.md` — vision, constraints, non-goals, milestone intent.
- `prompts/elixir-saml-lib-deep-research.md` — April 2026 ecosystem map, personas/JTBD, OASIS-aware domain language, security invariants, cross-ecosystem lessons, footguns, architecture, MVP/v1/v2 scope, provider presets, testing strategy, telemetry catalog, error taxonomy.
- `prompts/relyra-brand-book.md` — naming, voice, tagline, visual direction, module/API naming principles, security language do/don't, documentation voice, admin UI copy, error microcopy.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — ten-repo DNA synthesis + SAML-specific translation. §2 convergent DNA = adopt verbatim. §5 = v0.1 starter skeleton.
- Secondary: `elixir-opensource-libs-best-practices-deep-research.md`, `elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md`, `phoenix-live-view-best-practices-deep-research.md`, `ecto-best-practices-deep-research.md`, `elixir-best-practices-deep-research.md`, `The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`.

## Constraints

- **Tech stack** — Elixir `~> 1.18`, OTP 26+/27+/28 matrix. Phoenix 1.8.x, LiveView 1.1.x, Ecto 3.13.x, Plug current stable. Optional `Req` for HTTPS metadata fetches (added in v0.2). **Why:** matches sibling-repo baselines and the 2026 Phoenix/Elixir ecosystem reality; lower Elixir pins pull in known OTP XML/crypto bugs.
- **XML security boundary** — one hardened parser path. No parser differentials. DTDs + external entities + network fetches disabled *before any parse at all*. Size limits pre- and post-base64/inflate. **Why:** the `esaml` 2026 NVD XXE entry happened before signature verification; the library that parses unsafely is compromised regardless of signature policy. Non-negotiable base invariant.
- **Signature trust source** — signatures verified against configured IdP certs only, never the document's `KeyInfo`. Verified signature bound to the exact node consumed. **Why:** `ruby-saml` CVE-2024-45409 shipped because the library trusted document-provided signature context.
- **Production replay store** — cluster-safe. ETS warns loudly if `Mix.env() == :prod`. **Why:** distributed Phoenix deployments with ETS-only replay are a silent bypass.
- **Trust-mutation auditability (v0.2+)** — every connection / metadata / certificate / mapping mutation co-commits an audit row inside the same transaction as the change. Audit payloads are redaction-safe (no XML, PEM, or key material). **Why:** the trust timeline cannot drift from the data it describes; an operator must be able to answer "who changed what, why" from the audit ledger alone.
- **Performance / budget** — OSS. Zero hosted infra. Data lives in the host app's database. **Why:** OSS sustainability + no SaaS lock-in / no hidden auth boundary.
- **Security** — `SECURITY.md` + private advisory workflow from day 1. Every security fix becomes a permanent regression fixture. No unsafe defaults. No "disable signature validation to make the demo pass." **Why:** Relyra sits on the auth boundary.
- **Compatibility — legacy IdPs** — `legacy_algorithm_policy: [allow_sha1_until: ~D[...], reason: "...", audit: true]` exists but must be time-boxed, auditable, and surfaced in the admin UI (v0.3+) with a clear risk panel. **Why:** unsafe compatibility is explicit, not silent.
- **OSS discipline** — conventional commits + Release Please + Keep-a-Changelog + `@version` single source of truth + `package.files` explicit whitelist + CI as specification + tag-version guard + post-publish parity verification + daily drift cron. **Why:** sibling-lib convergence is 5-of-10+; skipping re-pays costs already paid.
- **Brand** — always "Relyra" title case. Never `reLyra`, `ReLyra`, `RELYRA`, or lyre/music/constellation/shield/padlock/key/flame/bird imagery. Never "SAML is easy", magic, bulletproof, military-grade. **Why:** brand book §22 do/don't summary is locked.
- **Runtime** — Claude Code + sibling-lib Claude-first tooling. `CLAUDE.md` + `AGENTS.md` dual entry points. GSD planning discipline (`.planning/` layout). **Why:** matches sibling-repo working model.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **XML security path = ADR in Phase 1** (not locked at bootstrap) | Single largest v0.1 correctness+deploy risk per deep research. Required explicit research deliverable with canonicalization choice, entity-disabling guarantees, signature-wrapping defenses, deployment story, and adversarial-corpus coverage of `ruby-saml` CVE-2024-45409 + `samlify` wrapping fixtures. | ✓ Good (Phase 01: pure-BEAM default with conditional hybrid fallback + checksum gate) |
| **v0.1 package shape = single `relyra` with optional LiveView admin gate** | DNA convergence (sigra/lattice_stripe/threadline/scrypath/lockspire/mailglass all single-package). One install command, zero admin-specific deps for the host app. | ✓ Good (still single-package after v0.2; revisit at v0.4/0.5) |
| **Request/replay store default = ship both ETS + Ecto behind one behaviour each** | DNA: sigra sessions + threadline audit use Ecto-backed defaults; ETS-dev-only is the demo/single-node story. | ✓ Good (shipped v0.1) |
| **`mix relyra.install` scope at v0.1 = minimal** | Config stub + behaviour skeletons + dev fake-IdP cert. Full Ecto migrations + schemas land with v0.2. | ✓ Good (v0.2 added enterprise-config migrations as planned) |
| **v0.1 ↔ v0.2 scope line = idea-doc split** | v0.1: SP-initiated SSO + security corpus + provider guides + Keycloak dev container. v0.2: Ecto schemas, metadata import/export, cert rollover. v0.3: LiveView admin. v0.4: IdP-initiated + opaque RelayState. v0.5: SLO. v1.0: external security review + conformance. | ✓ Good (v0.1 and v0.2 both shipped on intent) |
| **Strict defaults + footgun non-negotiables locked at bootstrap** | IdP-initiated off by default; SLO deferred to v0.5; SHA-1 rejected by default; unsafe compatibility audited + time-boxed; RelayState opaque by default; replay cache required in prod. | ✓ Good (held through v0.1 and v0.2) |
| **Runtime = Claude Code + GSD planning discipline; `CLAUDE.md`/`AGENTS.md` dual entry points** | Matches sibling-repo working model. `.planning/` layout is canonical truth; Hex/git is the product. | ✓ Good (proven through v0.2) |
| **v0.2: connection aggregate has internal binary PK + public `connection_id` join key; no Ecto rows above the resolver boundary** | Public ID is stable across persistence migrations; runtime consumers see only `%Relyra.Connection{}` value structs. Avoids the Spring/Sustainsys footgun where downstream code couples to ORM rows. | ✓ Good (verified Phase 08; integration check 2026-05-06) |
| **v0.2: `idp_certificates` is the canonical runtime certificate field; `cert_chain` is a compatibility mirror** | One canonical key on the snapshot; legacy callers still work; future code reads only `idp_certificates`. | ✓ Good (validation pipeline prefers `idp_certificates`; snapshot fills both) |
| **v0.2: metadata refresh is operator-triggered only; new signing certs stage as `:next`; runtime trust never shifts implicitly** | Implicit trust shifts on metadata fetch are a silent bypass class. Operator stages → reviews → promotes. | ✓ Good (verified Phase 09/10; staged-only behavior confirmed by integration check) |
| **v0.2: all four mutation modules co-commit audit rows via a single `Relyra.Ecto.AuditWriter.append_event` seam inside the same transaction** | The audit ledger cannot drift from the data it describes; one writer = one redaction policy = one shape. | ✓ Good (verified Phase 11; cross-domain audit hardening shipped via Plan 11-03) |
| **v0.2: closure-phase pattern (12 → 09's verification, 13 → 10's, 14 → 11's)** | When an audit surfaces verification orphans, prefer producing missing verification artifacts over re-opening implementation. Cleaner audit trail; smaller blast radius; manual sign-off captured per artifact. | ✓ Good (closed all three v0.2 audit gaps without regressions; pattern worth carrying forward) |
| **v0.2 tech debt accepted at close: `MappingCommands.append_audit/8` lacks explicit `repo.rollback/1`** | Modern Ecto's `transact/1` auto-rolls on `{:error, _}`; legacy adapter fallback uses `repo.transaction/1` where audit failure could commit mapping rows. Other three co-commit sites use the explicit pattern. | ⚠️ Revisit (track for v0.3 cleanup; not reproducible against current dep set) |
| **v0.5: closure-phase pattern extended (21.1 → INT-01 BLOCKER closure, 21.2 → audit-gap + scope-rescope closure)** | When an audit surfaces a BLOCKER + scope drift, prefer producing closure phases over re-opening implementation. Phase 21.1 closed the security-adjacent BLOCKER; Phase 21.2 closed the doc/scope gaps. Cleaner audit trail; smaller blast radius; milestone audit re-runs cleanly. | ✓ Good (closed v0.5 audit gaps without re-opening Phase 20 or Phase 21; pattern reusable for v0.6+) |
| **v1.1 Phase 28: pure-BEAM exclusive-C14N proven correct via a committed golden-byte oracle** | ADR-0001 mandated pure-BEAM canonicalization; correctness on the auth boundary demanded independent proof, not self-assertion. A `saxy` parse tree replaced regex string-scanning (one trust path, D-04), and the hand-rolled C14N engine reproduces libxml2/xmlsec1's 887-byte exclusive-C14N output byte-for-byte (cross-checked across two libxml2 builds; the Elixir engine is the third agreeing implementation). CI stays pure-Elixir against committed bytes (D-12); the verified signature is bound to the exact node consumed (D-10, anti-XSW). | ✓ Good (Phase 28; SIGV-03 verified 2026-05-24. Known fail-safe limitation: mixed-content / inter-element-whitespace mis-canonicalizes → rejection never bypass; tracked as the first Phase 29 follow-up) |
| **Assessment 2026-05-27: v1.x done-enough verdict re-confirmed; next milestone is publish+polish, not new protocol** | Adopter-first assessment with parallel candidate research (AUTHN-POST-01 / KMS-01 / SIGNED-META-01) and a DX audit through the lens of a Phoenix SaaS adopter. All three demand-gated candidates verdict = save-for-demand (zero adopter pull, all tractable when needed; pre-baked plans retained in `.planning/threads/`). The single high-leverage finding is **Hex publishing lag**: mix.exs at 1.2.0 while git/PROJECT.md say v1.4 — Hex audience cannot see v1.3 or v1.4 features. Brand-defining gap also surfaced: no stepwise login-trace LiveView for the "every login explains itself" promise. Recommended single pick: **v1.5 polish milestone** bundling Hex publish + trace LiveView + README/installer ergonomics + warning-level tech-debt sweep. ~1 week. After v1.5: pause until external demand signal. | Open (no implementation work undertaken in this assessment session per maintainer preference; thread `v1-5-polish-milestone-assessment-2026-05-27.md` captures full scope) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state (Hex adoption, security advisories, provider coverage, adopter feedback themes)

---
*Last updated: 2026-05-27 — v1.5 Phase 43 (Hex publish prep) complete; next: Phase 44 release-please publish. Polish-and-publish wedge bundles Hex publish of v1.3+v1.4, stepwise login-trace LiveView (done), release-prep staging (done), and README/installer ergonomics + warning-level tech-debt sweep. After v1.5: future scope returns to demand-gated. Arc to date: SP-initiated SSO (v0.1) → enterprise config (v0.2) → LiveView admin (v0.3) → IdP-initiated SSO (v0.4) → operational maturity (v0.5-0.6) → conformance + security review (v1.0) → verified trust path (v1.1) → advanced federation (v1.3) → full SLO + ops polish (v1.4) → publish-prove-polish (v1.5).*
