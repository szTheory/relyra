# Requirements: Relyra v1.5 — Publish, Prove, Polish

**Defined:** 2026-05-27
**Status:** Active
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Milestone goal:** Close the gap between the code (v1.4 shipped to git) and what adopters can actually see — bring Hex up to v1.4.0, make the "every login explains itself" promise concretely visible via a stepwise login-trace LiveView, and close residual DX and warning-level tech-debt items so a new adopter installs in 15 minutes.

## v1.5 Requirements

Requirements for this milestone. Each maps to one roadmap phase.

### Hex Publish (Wedge 1)

- [ ] **PUB-01**: `mix.exs` `@version` bumped from `1.2.0` to `1.4.0`, `guides/getting_started.md` install pin updated from `~> 0.1.0` to `~> 1.4`, and a SemVer-valid `v1.4.0` git tag exists (distinct from the non-SemVer `v1.4` already present). Single jump 1.2.0 → 1.4.0 (no intermediate 1.3.0 release); rationale documented in CHANGELOG.

- [ ] **PUB-02**: `CHANGELOG.md` contains a `[1.3.0]` section reconstructed from v1.3 milestone summaries (Advanced Federation — ENC-01, ENC-02, AUTHN-01, DOCS-02, DOCS-03) and a `[1.4.0]` section reconstructed from v1.4 milestone summaries (SLO-01, DOCS-04, DOCS-05, DOCS-06). Both sections follow Keep-a-Changelog format and the existing `[1.2.0]` precedent.

- [ ] **PUB-03**: Stalled release-please pipeline diagnosed and unstalled; `1.4.0` published to Hex via the release-please automation (NOT manual `mix hex.publish`, per CLAUDE.md). Diagnosis written up in `.planning/phases/<NN>/RELEASE-PLEASE-DIAGNOSIS.md` so the same failure mode cannot silently recur.

- [ ] **PUB-04**: Post-publish parity verification — the Hex `relyra-1.4.0` tarball is byte-equal to the `v1.4.0` git tag (per the OSS-discipline contract in PROJECT.md). Verification script and result live under `.planning/phases/<NN>/`; any drift fails the milestone close.

### Login Trace LiveView (Wedge 2)

- [ ] **TRACE-01**: Stepwise login-trace LiveView mounted at `/relyra/admin/connections/:connection_id/trace`. Shows the last N logins for that connection, each expandable into the eight telemetry-span outcomes (decode → validate → signature → replay → user_map → session_establish), each step labelled with `:outcome`, `:error_code` (if any), and post-mapping role/attribute result. Reuses the existing telemetry catalog and audit ledger; no new schemas. Mounted via the existing LiveAdmin scaffold.

- [ ] **TRACE-02**: Security gate test `test/security/login_trace_test.exs` asserts the trace LiveView never renders raw XML, PEM, base64 cert bodies, signature values, or key material — extending the redaction discipline already enforced by `diagnostic/allow_list.ex`. Wired into `mix ci.security` as its own `cmd mix test` line (Phase 30 hollow-gate invariant preserved).

- [ ] **TRACE-03**: `mix relyra.trace --connection ID --last N` headless companion task that prints the same step-by-step trace data as the LiveView. Same audit/telemetry sources; redaction-equivalent output. Allows headless / CI inspection of login traces without LiveView dependency.

### Adopter DX & Ergonomics (Wedge 3)

- [ ] **DX-01**: `README.md` opens with a runnable `apply_defaults(:okta, …)` snippet before the Day-1 router walkthrough — single-snippet pitch in the oban/bandit landing-page tradition. Above-the-fold answer to "what does relyra look like in 30 seconds?"

- [ ] **DX-02**: `mix relyra.install` auto-injects `saml_routes()` into the host application's router when an unambiguous insertion point is detected, falling back to the existing print-instructions behaviour only when ambiguous. Detection logic and fallback path covered by tests; no router corruption on edge cases.

- [ ] **DX-03**: `guides/overview.md` published as a job-shaped index (Day-1 / Day-2 / Reference sections) — fixes the existing "5-footer-chase" navigation friction. `BATTERIES_INCLUDED.md` deduplicated: one of the two (root vs `guides/`) becomes primary, the other becomes a stub link.

### Warning-Level Tech-Debt Sweep (Wedge 3)

- [x] **TD-01**: `lib/relyra/protocol/metadata.ex` attribute interpolation routes through an XML-attribute escaper before serialization (WR-03 closure). Closes the XSS-class defense-in-depth gap surfaced by the v1.3 audit. New `test/security/metadata_attribute_injection_test.exs` row wired into `mix ci.security` proving interpolated values are XML-attribute-escaped for `& < > " '` and control characters.

- [x] **TD-02**: `lib/relyra/test_support` excluded from the production artifact (WR-04 closure). Achieved via `elixirc_paths(:prod)` exclusion AND `package.files` whitelist tightening — both layers in agreement. Verified by an audit step that examines the published tarball contents (chained off PUB-04 if convenient).

- [x] **TD-03**: `locate_encrypted_assertion/1` and any other detector that still pairs a regex with the parse-tree unified on the parse-tree alone (WR-01 + WR-02 closure). Retires the regex-alongside-tree pattern so the "one trust path" invariant (CLAUDE.md non-negotiable #2) holds without exception in the encrypted-assertion path.

- [x] **TD-04**: Doc-drift fixes — `REQUIREMENTS.md`/legacy docs that reference `EncryptedAttribute` in ENC-01 context corrected to scope `EncryptedAssertion` only (WR-ENC-ATTR closure); `PROJECT.md` "What This Is" + `README.md` provider-count copy corrected from "8 presets" to "4 first-class presets + a generic SAML runbook covering 7 IdP families" (Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, Oracle Access Manager). Honest framing of real preset surface.

- [x] **TD-05**: Phase 40 deferred formatting drift closed — `mix format` clean across `test/security/xml/adversarial_crypto_test.exs` (lines 188-200 region). `mix format --check-formatted` exits 0 across the full repo. No semantic changes.

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Demand-Gated (post-v1.4 "done-enough" line — unchanged from v1.4 close)

- **AUTHN-POST-01**: HTTP-POST binding signed AuthnRequests — requires enveloped XML signature + C14N path; ADFS works on HTTP-Redirect; insufficient marginal demand observed. Pre-baked plan in `.planning/threads/signed-authn-requests-investigation.md`.
- **KMS-01**: KMS-native `KeyResolver` adapters (AWS KMS, GCP KMS) — extension point documented in v1.3; full adapters only if adoption demand materializes. Pre-baked plan in `.planning/threads/encrypted-assertions-investigation.md`.
- **SIGNED-META-01**: Signed SP metadata (`EntityDescriptor`) for academic federation / InCommon — pre-baked scope per assessment 2026-05-27.
- **CVE ID backfill** into `docs/advisories/2026-001-...` — pending async GitHub assignment.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New protocol features (POST-binding AuthnRequests, ECP, HTTP-Artifact, Attribute Query) | v1.5 is publish-and-polish; demand-gated per assessment 2026-05-27. |
| New IdP presets (Ping, OneLogin, Shibboleth, Keycloak as first-class modules) | Generic SAML runbook (DOCS-02, v1.3) already covers these IdP families. |
| KMS-native KeyResolver adapters | Compliance-pull, not ergonomics-pull. Demand-gated. |
| Signed SP metadata (`EntityDescriptor`) | Demand-gated; aspirational adopter persona (academic federation / InCommon) has not filed an issue. |
| Hosted SSO broker / SaaS runtime | PROJECT.md Out of Scope — library only. |
| OIDC/OAuth in-core | PROJECT.md Out of Scope. |
| Full standalone demo app | Library, not application. |
| Splitting v1.5 into separate 1.3.0 + 1.4.0 Hex releases | Single jump 1.2.0 → 1.4.0 chosen for adopter clarity; intermediate 1.3.0 release omitted. |
| Auto-wired session-index registration in `consume_response/3` | Locked in v1.4 — host-owned linkage. Unchanged in v1.5. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PUB-01      | 43    | Pending |
| PUB-02      | 43    | Pending |
| PUB-03      | 44    | Pending |
| PUB-04      | 45    | Pending |
| TRACE-01    | 42    | Pending |
| TRACE-02    | 42    | Pending |
| TRACE-03    | 42    | Pending |
| DX-01       | 46    | Pending |
| DX-02       | 46    | Pending |
| DX-03       | 46    | Pending |
| TD-01       | 41    | Complete |
| TD-02       | 41    | Complete |
| TD-03       | 41    | Complete |
| TD-04       | 41    | Complete |
| TD-05       | 41    | Complete |

**Coverage:**

- v1.5 requirements: 15 total
- Mapped to phases: 15/15 ✓
- Unmapped: 0

**Phase ↔ Requirement summary:**

| Phase | Name | Requirements | Count |
|-------|------|--------------|-------|
| 41 | Pre-publish hygiene — Tech-debt sweep & security hardening | TD-01, TD-02, TD-03, TD-04, TD-05 | 5 |
| 42 | Stepwise login-trace LiveView | TRACE-01, TRACE-02, TRACE-03 | 3 |
| 43 | Hex publish prep — version bump & CHANGELOG backfill | PUB-01, PUB-02 | 2 |
| 44 | Release-please pipeline diagnosis & v1.4.0 Hex publish | PUB-03 | 1 |
| 45 | Post-publish parity verification | PUB-04 | 1 |
| 46 | Adopter DX & ergonomics | DX-01, DX-02, DX-03 | 3 |

---

*Requirements defined: 2026-05-27 — v1.5 polish milestone scoping from `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md`. Traceability filled by roadmapper 2026-05-27 — 6 phases (41-46), 15/15 requirements mapped, zero orphans. Reordered 2026-05-27 — trace LiveView (Phase 42) sequenced before publish prep so it ships in the v1.4.0 tarball by construction.*
