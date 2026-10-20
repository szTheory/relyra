# Feature Research

**Domain:** Adversarial testing harness for a strict SAML 2.0 SP library (generative fuzzing, mutation testing, real-IdP fidelity canaries, chaos journeys, customer-IT-admin workflow)
**Researched:** 2026-10-19
**Confidence:** MEDIUM (attack taxonomy and comparable-product workflows HIGH-confidence on mechanism; exact mutation-score target and some XSW variant numbering are advisory, not authoritative)

> Scope note: This milestone (v1.12 "Adversarial Twin") adds **test/evidence surface only**. No new protocol, public API, default, or security-posture change is in scope. "Features" below are testing capabilities and one adopter-facing workflow, measured against a diminishing-returns stopping rule. Relyra already ships the defenses; v1.12 proves them against signal we did not hand-write.

## Feature Landscape

### Table Stakes (Expected for a credible adversarial twin)

Without these, the milestone does not deliver on "signal we didn't anticipate" and the Partial JTBD rating.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Property-based generator of signed SAML responses (StreamData) asserting the trust-path invariant: every mutated input either verifies with the consumed node == signed node, or returns a typed `Relyra.Error`; never crashes, never accepts a tampered response | This is the milestone's headline promise; without a generator you only have the hand-written corpus you already shipped | HIGH | Depends on `TestSupport.FakeIdP.sign` (real XMLDSig signer) as the valid-input oracle and `Signature.do_verify/4` as the gate. `stream_data` is the de-facto Elixir PBT lib (StreamData); no maintained alternative needed |
| Signature-wrapping (XSW) mutation family: clone Response/Assertion before/after/inside the signed node; relocate signed node into `Signature`, `Object`, `Extensions` | XSW is the canonical SAML attack class; SAML Raider automates XSW1-8; corpus already has 8 `signature_wrapping` rows to seed from | MEDIUM | Generator must bind to the anti-XSW invariant already enforced by `signed_node.ex` (D-10). Secondary sources disagree on XSW4-8 numbering — treat the *structural transform* (where signed vs consumed node sits) as the contract, not the label |
| Parser-differential / canonicalization mutations: namespace confusion, `xmlns`-as-attribute, relative-namespace-URI "void canonicalization", duplicate/polluted attributes (`ID` vs prefixed `ID`), comment injection inside NameID/DigestValue | This is the live 2025-2026 bypass frontier (Fragile Lock, ruby-saml CVE-2025-25291/66567/66568, xml-crypto CVE-2025-29775, python-saml CVE-2017-11427, Go CVE-2020-29509). Relyra's single-parse-path invariant is the direct answer and must be proven under fuzzing | MEDIUM | Relyra's architectural defense (one saxy parse path, no parser differential, C14N proven byte-equal to libxml2) means many of these should be *structurally impossible* — the generator proves that rather than patching. Comment-injection and void-canonicalization are the highest-value rows because they are post-C14N digest attacks |
| Duplicate-ID / multiple-assertion / signature-exclusion / unsigned-partial mutations | Classic wrapping prerequisites; corpus already covers `duplicate_ids`, `ambiguous_signed_node`, `unsigned_or_partial_signature` | LOW | Mostly extends existing manifest classes; generator densifies rather than invents |
| Encrypted-assertion wrapping mutations (cleartext+encrypted, >1 encrypted, encrypted-wrapping) | ENC-01 path splices and re-parses through the same seam; must prove `:ambiguous_assertion` fires before crypto under generated inputs | MEDIUM | Depends on the XMLEnc seam and the 7-fixture encrypted corpus already present |
| Boundary mutations on time/recipient/destination/issuer/InResponseTo/audience: NotBefore/NotOnOrAfter one-second-either-side, clock-skew window edges, Recipient/Destination mismatch and near-miss | Time and recipient boundaries are the most common silent-accept bugs; `@default_skew_seconds 120` and `clock_skew_seconds` are live config and must be fuzzed at the edge | LOW-MEDIUM | Property: assertion valid iff `NotBefore - skew <= now < NotOnOrAfter + skew`. Generator picks adversarial timestamps around the boundary |
| Entity / size / inflate mutations (DOCTYPE, `<!ENTITY>`, oversized, deep nesting, base64/inflate bombs) | Pre-parse guard is the non-negotiable base invariant; `esaml` shipped XXE-before-verify. Corpus has `xxe_entity_abuse` + `size_and_inflate_bounds` | LOW | Generator feeds raw-binary guard before saxy; proves guard runs on raw bytes pre-parse |
| Mutation testing of the security core (signature, digest, audience, time-window, replay) with a reported mutation score as the diminishing-returns metric | Explicitly named in milestone goal; the score is the stopping-rule instrument | MEDIUM-HIGH | Tooling choice is the risk — see Differentiators / Anti-Features. Scope mutation testing to the security modules only, not the whole lib |
| Findings auto-promote to permanent `ci.security` corpus rows (manifest + fixture) | Milestone requires "findings become permanent corpus rows"; matches the existing `manifest.json` + deterministic-3x-replay discipline | LOW-MEDIUM | Reuse the existing manifest schema (`id`, `class`, `requirement_ids`, `expected_error_type`); a shrunk failing seed becomes a new row |
| Real-IdP fidelity corpus (Keycloak, SimpleSAMLphp, Shibboleth) captured as fixtures, run as **scheduled canaries, never merge gates** | Milestone requirement; the existing Keycloak demo profile + v1.10 proxy round-trip is the starting point; canary-not-gate matches v1.11 external-provider canary discipline | MEDIUM-HIGH | Vendor defaults matter: SimpleSAMLphp signs Response+Assertion by default; Shibboleth IdP5 defaults signResponses=true and encryptAssertions=true; Keycloak "Sign documents"/"Sign assertions" vary per client config. Capture both signed-response and signed-assertion-only shapes per vendor |
| Chaos journeys for existing twin personas: concurrency (WINDOW-29/30), DB failure mid audit co-commit, metadata refresh during cert rollover, clock skew | Milestone requirement; WINDOW-29/30 are already-dispositioned open automation gaps that this milestone can finally close with an owned concurrency-capable DB harness | HIGH | The hard dependency is a concurrency-capable DB fixture that can coordinate two independent Sandbox owners — the exact blocker WINDOW-29/30 recorded. Audit co-commit atomicity (same-transaction row) is the invariant under test |
| Customer-IT-admin journey: connection-test + attribute-preview workflow exercised end-to-end against the Partial JTBD rating | Milestone requirement; directly targets the one Partial persona in `jtbd_gap_map.md` | MEDIUM | Must settle whether Partial is a product gap or a documentation gap — the journey is the instrument, not a commitment to build a portal |

### Differentiators (Set Relyra's twin apart)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Trust-path invariant as a single property oracle ("consumed node == verified node, else typed rejection, never crash/accept") driving all generated mutations | One falsifiable invariant covers XSW, parser-differential, and wrapping families at once — stronger than enumerating payloads. Matches brand promise "verified trust path or typed rejection" | MEDIUM | This is the architecturally honest framing: Relyra's single-parse-path design means the generator's job is to *fail to find* a differential, and to prove it |
| Void-canonicalization + comment-injection coverage proving C14N fails closed | These are the 2025-2026 bypasses (Fragile Lock, SAMLStorm/xml-crypto) that broke ruby-saml/PHP/Node. Relyra's hand-rolled C14N must demonstrably reject relative-namespace-URI and comment-in-digest inputs where other libs returned empty-string digests | MEDIUM | Relyra already has a known fail-safe limitation: mixed-content/inter-element-whitespace mis-canonicalizes to *rejection, never bypass* (Phase 28 decision). The generator should assert that every C14N ambiguity resolves to rejection |
| Mutation-score-gated stopping rule tied to the milestone's explicit diminishing-returns metric | Turns "when are we done testing" from judgment into a recorded number; residual risk becomes an artifact, not a hope | MEDIUM | Pairs with the "two rounds, no new defect class" rule already in the milestone |
| Real-IdP canary that captures vendor signing/encryption default drift over time | A scheduled canary that re-fetches real Keycloak/SimpleSAMLphp/Shibboleth output catches the day a vendor changes a default (e.g. Shibboleth's encryptAssertions=true) before an adopter hits it | MEDIUM-HIGH | Canary, never gate — a vendor outage or default change must not redden PR CI |
| Attribute-preview as a login-trace extension (reuse existing `/relyra/admin/connections/:id/trace` + `mix relyra.trace`) | Relyra already has stepwise login-trace + redaction gate; surfacing "here are the attributes this connection would map" reuses that surface instead of building a new portal — likely resolves Partial as a *documentation/surfacing* gap, not a product gap | MEDIUM | Strong candidate to settle the JTBD question cheaply and in-brand |

### Anti-Features (Tempting, but out of scope or harmful here)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-IdP canaries as merge gates | "Test against real IdPs on every PR" feels rigorous | Container/vendor flakiness reddens unrelated PRs; violates the milestone's explicit "scheduled canaries, never merge gates" and v1.11 canary discipline | Scheduled canary lane + captured fixtures that *do* gate deterministically |
| New public API for a connection-test/attribute-preview "portal" | WorkOS/Auth0/Scalekit all ship self-service test buttons; tempting to match | Public API shape change = escalation per CLAUDE.md; a hosted/self-service portal is explicitly out of scope (Relyra is a library, host owns the product workflow) | Exercise the workflow through existing LiveAdmin + login-trace; treat Partial as surfacing/doc gap first |
| Adopting an unmaintained mutation-testing tool as a hard CI gate | Muzak is the best-known Elixir mutation tool | Muzak OSS has been stale since ~2022 (reported broken on Elixir 1.14); taking a hard dependency risks an unrunnable gate on the OTP 26/27/28 matrix | Prefer actively-maintained Muex (0.9.x, Elixir-specific mutators) OR a scoped in-house mutation harness over the ~6 security modules; run as a measured metric, not necessarily a blocking gate initially |
| Chasing a 100% mutation score | "Higher is better" | Equivalent mutants make 100% unreachable; cost explodes past the plateau; contradicts the diminishing-returns stopping rule | Target a high score on the security core only, record surviving mutants as residual risk, stop at plateau |
| Weakening or regenerating the existing adversarial crypto corpus to fit the generator | Generator output might not match hand-written rows | CLAUDE.md forbids weakening `adversarial_crypto_test.exs`; it permanently gates every build | Generator *adds* rows; the frozen corpus stays byte-stable |
| Second XML parse path to implement new mutations | Some fuzzers want DOM manipulation convenience | Violates the one-parse-path invariant that is the entire point | Mutate at the serialized-bytes / FakeIdP-signing layer, feed through the single seam |
| Fabricated or synthetic "real-IdP" fixtures labeled as vendor output | Easier than running containers | Destroys the fidelity value and adoption-truth discipline | Capture genuine container output; label provenance in the manifest |

## Feature Dependencies

```
Trust-path invariant oracle
    └──requires──> TestSupport.FakeIdP.sign (real XMLDSig signer, ASSUR-02)
    └──requires──> Signature.do_verify/4 + signed_node.ex binding (SIGV-01/02, D-10)

Generative adversarial twin (StreamData)
    └──requires──> Trust-path invariant oracle
    └──requires──> single saxy parse seam (pure_beam.ex) + pre-parse guards
    └──feeds────> Findings-to-corpus promotion
                      └──requires──> existing manifest.json schema + ci.security

Mutation testing of security core
    └──requires──> fast, deterministic security test suites (already: cmd mix test per suite)
    └──produces──> mutation score (diminishing-returns metric / stopping rule)

Real-IdP fidelity corpus
    └──requires──> v1.10 Keycloak profile + Fleet/Traefik proxy, container harness
    └──runs-as──> scheduled canary lane (NOT ci-gate)

Chaos journeys
    └──requires──> concurrency-capable DB fixture (the WINDOW-29/30 blocker)
    └──requires──> Ecto audit co-commit seam (AuditWriter) + cert rollover + metadata refresh
    └──enhances──> existing LedgerLoop twin personas (Phase 75/76)

Customer-IT-admin journey
    └──requires──> LiveAdmin connection + mapping surfaces (CFG-06)
    └──enhances──> login-trace LiveView + mix relyra.trace (TRACE-01/03)  [attribute preview]
    └──conflicts──> new public portal API (anti-feature / escalation)
```

### Dependency Notes

- **Generator requires the invariant oracle, which requires the real signer:** mutated inputs are only meaningful relative to a genuinely-signed baseline; `FakeIdP.sign` must produce a real `SignatureValue`/`DigestValue` (already true since ASSUR-02).
- **Findings-to-corpus reuses the manifest schema:** the existing `manifest.json` rows (`id`/`class`/`requirement_ids`/`expected_error_type`) plus the deterministic-3x-replay test are the promotion target; no new corpus format.
- **Chaos journeys are blocked on the same fixture that blocked WINDOW-29/30:** a DB harness that can coordinate two independent SQL Sandbox owners. This is the single highest-complexity dependency in the milestone and should be scheduled early.
- **Attribute preview enhances, not replaces, login-trace:** reusing the trace surface is what lets the JTBD question likely resolve as documentation rather than new product surface.

## MVP Definition

### Launch With (v1.12 core)

- [ ] Trust-path invariant property test over generated signed responses (XSW + parser-differential + boundary families) — the headline requirement
- [ ] Findings-to-corpus promotion into existing `ci.security` manifest — makes generated signal permanent
- [ ] Boundary + entity/size generators (time, recipient, destination, InResponseTo, DOCTYPE/entity/size) — highest-value, lowest-complexity coverage
- [ ] Mutation testing scoped to the ~6 security modules with a reported score and recorded residual risk — the stopping-rule instrument
- [ ] Chaos journeys: DB-failure-mid-audit-co-commit, metadata-refresh-during-rollover, clock skew — most achievable chaos trio
- [ ] Customer-IT-admin journey exercising connection-test + attribute-preview through existing surfaces, with an explicit product-gap-vs-doc-gap verdict

### Add After Validation (within milestone, as returns allow)

- [ ] Concurrency chaos (WINDOW-29/30) once the concurrency-capable DB harness exists — trigger: harness lands
- [ ] Real-IdP fidelity corpus for all three vendors as a scheduled canary — trigger: container harness stable; start with Keycloak (already present), add SimpleSAMLphp then Shibboleth
- [ ] Encrypted-assertion wrapping generator — trigger: core generator proven on cleartext path first

### Future Consideration (defer / demand-gated)

- [ ] Mutation testing as a hard CI gate (vs. measured metric) — defer until tool maturity + score stability proven
- [ ] Customer self-service portal surface — demand-gated; only if the JTBD journey proves a real *product* gap and a real adopter asks
- [ ] Additional vendor canaries (PingFederate, ADFS, Entra) — demand-gated per existing preset discipline

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Trust-path invariant generator (XSW + parser-differential) | HIGH | HIGH | P1 |
| Findings-to-corpus promotion | HIGH | LOW | P1 |
| Boundary + entity/size generators | HIGH | LOW | P1 |
| Mutation testing of security core (metric) | HIGH | MEDIUM | P1 |
| Chaos: DB-mid-co-commit / rollover-refresh / clock skew | HIGH | MEDIUM | P1 |
| Customer-IT-admin connection-test + attribute-preview journey | HIGH | MEDIUM | P1 |
| Void-canonicalization + comment-injection coverage | HIGH | MEDIUM | P2 |
| Concurrency chaos (WINDOW-29/30) | MEDIUM | HIGH | P2 |
| Real-IdP fidelity canary (Keycloak → SimpleSAMLphp → Shibboleth) | MEDIUM | HIGH | P2 |
| Encrypted-assertion wrapping generator | MEDIUM | MEDIUM | P2 |
| Mutation testing as hard gate | LOW | MEDIUM | P3 |

## Mutation-Score Target Guidance

- No single authoritative industry number exists. Stryker (JS/.NET) ships example thresholds of `break`=70, `high`=80, `low`=60 as *illustrative*, not recommended. Muex colors ≥80% green, ≥60% yellow, <60% red, and `--fail-at 80` is its documented example. (Both MEDIUM/LOW confidence — these are tool defaults, not research-backed targets.)
- Credible posture for **security-critical code**: aim high on a **narrow, well-chosen scope** (the signature/digest/audience/time-window/replay modules) rather than a mediocre score on the whole library. A high-80s-to-90s score on that scope is a defensible plateau target; chasing 100% is an anti-feature because equivalent mutants are unkillable.
- Use the score as the **diminishing-returns instrument** the milestone already specifies: stop when the score plateaus or two rounds add no new killed-mutant class; record surviving mutants as named residual risk. The *trend and the surviving-mutant list* matter more than the absolute number.

## Competitor Feature Analysis (connection-test / attribute-preview workflow)

| Capability | WorkOS Admin Portal | Auth0 | Scalekit / Okta-SP tooling | Relyra's approach |
|-----------|---------------------|-------|----------------------------|-------------------|
| One-click test sign-in | "Test sign-in" button; SP-init + IdP-init + guest-domain + error-response scenarios | "Try" button on the SAML connection | "Test Connection" button | Reuse LiveAdmin + login-trace; exercise via the customer-IT-admin journey |
| Attribute preview after test | Custom-attribute fields mapped in portal; takes effect next sign-in | Try button surfaces returned assertion attributes | Attribute mapping entered in IdP; success/fail shown | Surface mapped attributes through existing login-trace (redaction-gated) rather than a new screen |
| Actionable failure output | Error params passed to redirect URI | — | Shows error, cause, and suggested fix | Already strong: typed `Relyra.Error` names the exact field/expected/fix; incident playbook + Error Atom Decoder |
| Self-service embeddable portal | Embeddable Admin Portal (links expire 5 min) | Dashboard-hosted | Portal-hosted | Out of scope (library, not broker) — anti-feature |

**Read:** Relyra's typed-rejection + login-trace + Error Atom Decoder already match or exceed the *diagnostic* quality of these products. The gap the JTBD map flags as Partial is almost certainly **presentation/packaging of a connection-test + attribute-preview flow**, not missing capability — which is why the milestone frames it as a *journey to settle the question*, not a build order.

## Sources

- PortSwigger, "The Fragile Lock: Novel Bypasses For SAML Authentication" — https://portswigger.net/research/the-fragile-lock (attribute pollution, namespace confusion, void canonicalization, golden SAML) — MEDIUM
- WorkOS, "SAML vulnerabilities 2026" — https://workos.com/blog/saml-vulnerabilities-2026 (CVE-2025-66567/66568, authentik, OneUptime xml-crypto/xml2js, testing practices) — MEDIUM
- ruby-saml CVE-2025-25291 (REXML vs Nokogiri parser differential) — https://www.wiz.io/vulnerability-database/cve/cve-2025-25291 — MEDIUM
- samlify CVE-2025-47949 (signature wrapping, fixed 2.10.0) — https://www.wiz.io/vulnerability-database/cve/cve-2025-47949 — MEDIUM
- xml-crypto CVE-2025-29775 (DigestValue comment bypass) — https://corgea.com/advisories/vulnerabilities/CVE-2025-29775 — MEDIUM
- Duo Labs CVE-2017-11427 (python-saml comment truncation / NameID) — https://duo.com/labs/psa/duo-psa-2017-003 — MEDIUM
- Mattermost CVE-2020-29509 (Go encoding/xml round-trip namespace) — https://www.itpro.com/security/vulnerability/358124 — MEDIUM
- NetSPI, "Attacking SSO: Common SAML Vulnerabilities" (XSW1-8 via SAML Raider) — https://www.netspi.com/blog/technical-blog/web-application-pentesting/attacking-sso-common-saml-vulnerabilities-ways-find — MEDIUM (variant numbering conflicts across sources)
- Muex mutation testing README (mutators, scoring, --fail-at) — https://repo.hex.pm/preview/muex/0.9.0/README.md — MEDIUM
- Muzak status / Elixir 1.14 breakage — https://elixirforum.com/t/mutation-testing-on-elixir-1-14/51926 — LOW
- Stryker threshold conventions — https://stryker-mutator.io/blog/stryker-0-8-0/ — LOW (illustrative, not a recommended target)
- WorkOS Test SSO docs — https://workos.com/docs/sso/test-sso.md ; Admin Portal — https://workos.com/docs/admin-portal — MEDIUM
- Auth0 SAML "Try" button — https://auth0.com/docs/authenticate/protocols/saml — MEDIUM
- Scalekit Okta SAML Test Connection — https://docs.scalekit.com/guides/integrations/sso-integrations/okta-saml.md — MEDIUM
- Shibboleth IdP5 SAML2SSO defaults (signResponses=true, encryptAssertions=true) — https://shibboleth.atlassian.net/wiki/spaces/IDP5/ — MEDIUM
- SimpleSAMLphp IdP-hosted metadata (saml20.sign.response / saml20.sign.assertion default TRUE) — https://simplesamlphp.org/docs/stable/simplesamlphp-reference-idp-hosted — MEDIUM
- Internal: `.planning/PROJECT.md`, `docs/jtbd_gap_map.md`, `test/fixtures/security/*/manifest.json` (existing corpus classes), `.planning/phases/79-adopter-ready-closeout/79-RISKS.json` (WINDOW-29/30), `lib/relyra/security/*` — HIGH

---
*Feature research for: adversarial testing twin for a strict SAML 2.0 SP library*
*Researched: 2026-10-19*
