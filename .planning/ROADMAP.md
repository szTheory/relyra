# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- ✅ **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- ✅ **v1.0 — External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- ✅ **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- ✅ **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- ✅ **v1.4 — Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- 🚧 **v1.5 — Publish, Prove, Polish** — Phases 41-46 (in progress).

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.2-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.4 — IdP-initiated SSO (Phase 19) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.4-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.5 — Operational maturity (Phases 20-21.2) — SHIPPED 2026-05-07</summary>

See `.planning/milestones/v0.5-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.6 — Operational maturity carryover + SLO (Phases 22-24) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v0.6-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.0 — External security review + conformance + docs polish (Phases 25-27) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 — Verify the Trust Path (Phases 28-31) — SHIPPED 2026-05-25</summary>

See `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.3 — Advanced Federation (Phases 32-37) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.4 — Full SLO + Ops Polish (Phases 38-40.1) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.4-ROADMAP.md`.

</details>

### 🚧 v1.5 — Publish, Prove, Polish (In Progress)

**Milestone Goal:** Close the gap between code (v1.4 shipped to git) and what adopters can actually see — bring Hex up to `1.4.0`, make the "every login explains itself" promise concretely visible via a stepwise login-trace LiveView, and close residual DX and warning-level tech-debt items so a new adopter installs in 15 minutes. After v1.5, future scope is demand-gated, not coverage-gated. Full scope: `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md`.

**Phase numbering:** v1.4 ended at Phase 40.1; v1.5 continues at Phase **41**.

**Summary checklist:**

- [x] **Phase 41: Pre-publish hygiene — Tech-debt sweep & security hardening** — Close v1.3 audit warnings (WR-01/02/03, WR-04, WR-ENC-ATTR) and Phase 40 formatting drift before the first published tarball ships. (completed 2026-05-27)
- [x] **Phase 42: Stepwise login-trace LiveView** — `/relyra/admin/connections/:id/trace`, redaction-gated, plus `mix relyra.trace` headless companion. The brand-promise UI receipt — sequenced before publish prep so it ships in the v1.4.0 tarball.
- [x] **Phase 43: Hex publish prep — version bump & CHANGELOG backfill** — `mix.exs` 1.2.0 → 1.4.0, fix `~> 0.1.0` pin, backfill `[1.3.0]` + `[1.4.0]` CHANGELOG sections. (completed 2026-05-27)
- [x] **Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish** — Diagnose stalled release-please flow; publish via automation (NOT manual `mix hex.publish`). (completed 2026-05-27)
- [ ] **Phase 45: Post-publish parity verification** — Hex `relyra-1.4.0` tarball is byte-equal to the `v1.4.0` git tag; published tarball contains no `test_support` artifacts.
- [ ] **Phase 46: Adopter DX & ergonomics** — README leads with `apply_defaults(:okta, …)` snippet, `mix relyra.install` auto-injects `saml_routes()`, `guides/overview.md` job-shaped index, BATTERIES_INCLUDED dedupe.

## Phase Details

### Phase 41: Pre-publish hygiene — Tech-debt sweep & security hardening

**Goal**: Close all v1.3-era warning-level audit items (WR-01/02/03, WR-04, WR-ENC-ATTR) and the Phase 40 deferred formatting drift, so the next published Hex tarball ships clean — no XSS-class defense-in-depth gaps, no `test_support` in prod artifact, no regex-alongside-tree detectors violating the "one trust path" invariant, no doc drift, and `mix format --check-formatted` exit 0 across the repo.
**Depends on**: Nothing (entry phase for v1.5; can begin immediately).
**Requirements**: TD-01, TD-02, TD-03, TD-04, TD-05
**Success Criteria** (what must be TRUE):

  1. `lib/relyra/protocol/metadata.ex` routes every attribute interpolation through an XML-attribute escaper, and a new `test/security/metadata_attribute_injection_test.exs` row in `mix ci.security` (its own `cmd mix test` line, Phase 30 hollow-gate invariant preserved) proves the five XML metacharacters `& < > " '` and control characters are escaped in attribute position.
  2. `mix.exs` `package.files` whitelist AND `elixirc_paths(:prod)` agree that `lib/relyra/test_support` is excluded from the production artifact; the agreement is verifiable by inspecting a built tarball (audit step chained into Phase 45 confirms it on the published tarball).
  3. `locate_encrypted_assertion/1` and any other detector still pairing a regex with the parse-tree are unified on the parse-tree alone; the regex-alongside-tree pattern is fully retired from the encrypted-assertion path (CLAUDE.md non-negotiable #2 "one parse path" holds without exception).
  4. `REQUIREMENTS.md` and other legacy docs no longer reference `EncryptedAttribute` in ENC-01 context (scoped to `EncryptedAssertion` only); `PROJECT.md` "What This Is" and `README.md` provider-count copy read "4 first-class presets + a generic SAML runbook covering 7 IdP families" (Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, Oracle Access Manager), not "8 presets".
  5. `mix format --check-formatted` exits 0 across the full repo, including `test/security/xml/adversarial_crypto_test.exs` lines 188-200; `mix qa` (or equivalent full gate) stays green; no semantic changes introduced by the formatting fix.

**Plans**: 5 plans (41-01..41-05)

### Phase 42: Stepwise login-trace LiveView

**Goal**: An operator opens `/relyra/admin/connections/:connection_id/trace` and sees the last N logins for that connection, each expandable into the eight telemetry-span outcomes (decode → validate → signature → replay → user_map → session_establish), with `:outcome`, `:error_code` (if any), and post-mapping role/attribute result for each step. The "every login explains itself" brand promise has its UI receipt. Headless inspection is also available via `mix relyra.trace`.
**Depends on**: Phase 41; **must complete before Phase 43 prep so the trace LiveView ships in the v1.4.0 tarball** (TD-03 regex-alongside-tree cleanup in Phase 41 is upstream of any trace work that touches the encrypted-assertion path).
**Requirements**: TRACE-01, TRACE-02, TRACE-03
**Success Criteria** (what must be TRUE):

  1. A LiveView is mounted at `/relyra/admin/connections/:connection_id/trace` via the existing LiveAdmin scaffold (no new top-level mount); it lists the last N logins for the connection, each row expandable into the eight telemetry-span outcomes annotated with `:outcome`, `:error_code` (if any), and the post-mapping role/attribute result. Reuses the existing telemetry catalog and audit ledger — NO new schemas, NO parallel storage (audit co-commit invariant preserved per CLAUDE.md non-negotiable #5).
  2. `test/security/login_trace_test.exs` exists, is wired into `mix ci.security` as its own `cmd mix test` line (Phase 30 hollow-gate invariant preserved), and asserts the trace LiveView never renders raw XML, PEM, base64 cert bodies, signature values, or key material — extending the redaction discipline established by `diagnostic/allow_list.ex`.
  3. `mix relyra.trace --connection ID --last N` exists, prints the same step-by-step trace data as the LiveView (same audit + telemetry data sources), and applies the same redaction discipline; output is verifiably redaction-equivalent to the LiveView output (a comparison test or shared redaction helper proves it).
  4. The trace LiveView is part of the `v1.4.0` git tag cut in Phase 44, so the published Hex tarball ships the trace UI. An adopter on `{:relyra, "~> 1.4"}` can see the trace UI without an additional install.

**Plans**: 4 plans (42-01..42-04)

### Phase 43: Hex publish prep — version bump & CHANGELOG backfill

**Goal**: Stage all repo-side changes required for a release-please-driven `1.4.0` publish — `mix.exs` `@version` bumped to `1.4.0`, the stale `~> 0.1.0` install pin corrected to `~> 1.4`, and `CHANGELOG.md` carries fully backfilled `[1.3.0]` and `[1.4.0]` sections in Keep-a-Changelog format consistent with the existing `[1.2.0]` precedent.
**Depends on**: Phase 41 + Phase 42 (publish-prep version bump should land atop the clean tech-debt sweep AND with the trace LiveView already in the tree, so the release-please-cut tag includes trace; if TD-02 or trace landed after the bump, `package.files`/git-tag contents would diverge between staged and published artifacts).
**Requirements**: PUB-01, PUB-02
**Success Criteria** (what must be TRUE):

  1. `mix.exs:6` reads `@version "1.4.0"` and `guides/getting_started.md:26` reads `{:relyra, "~> 1.4"}`; both changes are in a single commit (or co-located commits) so the release-please PR sees them together.
  2. `CHANGELOG.md` contains a `[1.3.0]` section reconstructed from v1.3 milestone summaries (covers ENC-01, ENC-02, AUTHN-01, DOCS-02, DOCS-03), following Keep-a-Changelog Added/Changed/Security categorization and the existing `[1.2.0]` precedent.
  3. `CHANGELOG.md` contains a `[1.4.0]` section reconstructed from v1.4 milestone summaries (covers SLO-01, DOCS-04, DOCS-05, DOCS-06), in the same Keep-a-Changelog format.
  4. The rationale for the single 1.2.0 → 1.4.0 jump (no intermediate 1.3.0 Hex release) is documented at the top of the `[1.4.0]` section so future readers understand why `[1.3.0]` exists in CHANGELOG without a Hex release.
  5. `mix test --warnings-as-errors` stays green after the version bump; no test asserts a literal `"1.2.0"` value (or those tests are updated to read `Mix.Project.config[:version]`).

**Plans**: TBD

### Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish

**Goal**: The release-please pipeline (currently stalled — release PR never merged after v1.2.0) is diagnosed, unstalled, and successfully drives a `1.4.0` publish to Hex via automation, NOT a manual `mix hex.publish` (CLAUDE.md forbids manual). The diagnosis is documented so the same failure mode cannot silently recur.
**Depends on**: Phase 43 (version + CHANGELOG must be staged before release-please can run).
**Requirements**: PUB-03
**Success Criteria** (what must be TRUE):

  1. The release-please stall is diagnosed (root cause identified — staged PR, missing token, mis-configured action, branch mismatch, etc.) and the diagnosis is written up in `.planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` so the same failure mode is detectable on recurrence.
  2. The diagnosed fix is applied and the release-please PR for `1.4.0` opens, builds green, and merges; on merge, the automation creates the `v1.4.0` git tag (SemVer-valid, distinct from the existing non-SemVer `v1.4`) and triggers the publish step.
  3. `hex.pm/packages/relyra` shows `1.4.0` as the latest version; the publish completed via the automation pipeline, not a manual `mix hex.publish` invocation (verifiable by the absence of manual-publish logs in the local shell history and the presence of the publish artifact in CI logs).
  4. `mix hex.info relyra` from a fresh checkout reports `1.4.0`; an adopter running `mix deps.get` with `{:relyra, "~> 1.4"}` pulls `1.4.0`.

**Plans**: TBD

### Phase 45: Post-publish parity verification

**Goal**: Prove that the Hex `relyra-1.4.0` tarball is byte-equal to the `v1.4.0` git tag (the OSS-discipline contract from PROJECT.md Constraints), and that the published tarball contains no `test_support` artifacts. Any drift fails the milestone close.
**Depends on**: Phase 44 (need a published tarball on Hex to compare).
**Requirements**: PUB-04
**Success Criteria** (what must be TRUE):

  1. A verification script (committed under `.planning/phases/45-*/` and runnable from a fresh checkout) downloads the Hex `relyra-1.4.0` tarball, builds the equivalent tarball locally from the `v1.4.0` git tag, and reports byte-equality (or itemizes any drift); the script's exit code is the milestone-close gate.
  2. The verification result is captured in `.planning/phases/45-*/PARITY-RESULT.md` with the SHA-256 of the published tarball, the SHA-256 of the locally rebuilt tarball, and an explicit pass/fail line; any drift triggers a milestone-close block (not an unconditional pass).
  3. The published tarball's `lib/` listing contains no `lib/relyra/test_support/` paths and no `test_support` module entries — chains the Phase 41 TD-02 fix onto the actual published artifact (defense-in-depth verification).
  4. `mix hex.audit` or equivalent surfaces no fixable warnings on the published artifact (e.g. missing license, missing CHANGELOG link, malformed metadata).

**Plans**: TBD

### Phase 46: Adopter DX & ergonomics

**Goal**: A new adopter reading the README sees what Relyra looks like in 30 seconds (an above-the-fold `apply_defaults(:okta, …)` snippet), runs `mix relyra.install` and gets `saml_routes()` auto-injected into their router (with a graceful fallback when the insertion point is ambiguous), and can navigate the docs by job (Day-1 / Day-2 / Reference) rather than chasing footers. Installs in 15 minutes.
**Depends on**: Phase 41 (TD-04 doc-drift fix to the "4 first-class + generic runbook" framing is a prerequisite for the README provider-count copy DX-01 will inherit).
**Requirements**: DX-01, DX-02, DX-03
**Success Criteria** (what must be TRUE):

  1. `README.md` opens with a runnable `apply_defaults(:okta, …)` snippet (or equivalent provider-preset one-liner) BEFORE the Day-1 router walkthrough — the "what does relyra look like in 30 seconds?" answer is above the fold, in the oban/bandit landing-page tradition.
  2. `mix relyra.install` (`lib/mix/tasks/relyra.install.ex`) auto-injects `saml_routes()` into the host application's router when an unambiguous insertion point is detected; when the insertion point is ambiguous (multiple routers, no clear anchor), it falls back to the existing print-instructions behaviour with no router corruption. Detection logic AND fallback path are covered by tests, including at least one edge-case test that proves the router is not corrupted on the ambiguous fallback.
  3. `guides/overview.md` is published as a job-shaped index with Day-1 / Day-2 / Reference sections and is wired into the ExDoc `extras:` list; the existing "5-footer-chase" navigation friction is eliminated for a new adopter (manually verified via a fresh `mix docs` build).
  4. `BATTERIES_INCLUDED.md` (root, drift-tested) and `guides/batteries_included.md` (hand-written) are deduplicated — one becomes the primary source of truth, the other becomes a stub link pointing to the primary. The decision is documented in the relevant phase SUMMARY so reviewers know which copy is canonical.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 41 → 42 → 43 → 44 → 45 → 46. Trace LiveView (Phase 42) now precedes publish prep (Phase 43), so the trace UI ships in the v1.4.0 Hex tarball by construction — no separate coordination required.

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |
| 19. IdP-initiated SSO | v0.4 | 3/3 | Complete | 2026-05-06 |
| 20. Bulk operations across connections | v0.5 | 2/2 | Complete | 2026-05-06 |
| 21. Scheduled metadata refresh | v0.5 | 7/7 | Complete | 2026-05-07 |
| 22. Certificate expiry alerts | v0.6 | 1/1 | Complete | 2026-05-07 |
| 23. Diagnostic bundles | v0.6 | 2/2 | Complete | 2026-05-07 |
| 24. Single Logout Protocol | v0.6 | 3/3 | Complete | 2026-05-07 |
| 25. Conformance and CVE Regression Fixtures | v1.0 | 3/3 | Complete | 2026-05-07 |
| 26. Security Audit Preparation and Remediation | v1.0 | 3/3 | Complete | 2026-05-08 |
| 27. Adopter Onboarding Polish and Case Studies | v1.0 | 3/3 | Complete | 2026-05-08 |
| 28. Real C14N parser foundation | v1.1 | 4/4 | Complete | 2026-05-24 |
| 29. Cryptographic XMLDSig verification | v1.1 | 5/5 | Complete | 2026-05-24 |
| 30. Adversarial crypto assurance | v1.1 | 4/4 | Complete | 2026-05-24 |
| 31. Disclosure and docs honesty | v1.1 | 2/2 | Complete | 2026-05-24 |
| 32. AlgorithmPolicy Extension + Schema Migrations | v1.3 | 2/2 | Complete | 2026-05-25 |
| 33. KeyResolver Behaviour + XMLEnc Crypto Core | v1.3 | 2/2 | Complete | 2026-05-25 |
| 34. ValidationPipeline Wiring + ENC-01 Complete | v1.3 | 4/4 | Complete | 2026-05-25 |
| 35. Signed AuthnRequests + ADFS Preset | v1.3 | 9/9 | Complete | 2026-05-26 |
| 36. Generic SAML Runbook | v1.3 | 2/2 | Complete | 2026-05-26 |
| 37. Identity Mapping and Provisioning Guide | v1.3 | 2/2 | Complete | 2026-05-26 |
| 38. Single Logout (SLO) Core & Security | v1.4 | 4/4 | Complete | 2026-05-27 |
| 39. Logout Strategy & Operational Guidance | v1.4 | 1/1 | Complete | 2026-05-27 |
| 40. Operational Polish & Error Taxonomy | v1.4 | 2/2 | Complete | 2026-05-27 |
| 40.1. Close v1.4 audit gaps (INSERTED) | v1.4 | 5/5 | Complete | 2026-05-27 |
| 41. Pre-publish hygiene — Tech-debt sweep & security hardening | v1.5 | 5/5 | Complete    | 2026-05-27 |
| 42. Stepwise login-trace LiveView | v1.5 | 4/4 | Complete    | 2026-05-27 |
| 43. Hex publish prep — version bump & CHANGELOG backfill | v1.5 | 1/1 | Complete    | 2026-05-27 |
| 44. Release-please pipeline diagnosis & v1.4.0 Hex publish | v1.5 | 3/3 | Complete    | 2026-05-27 |
| 45. Post-publish parity verification | v1.5 | 0/TBD | Not started | - |
| 46. Adopter DX & ergonomics | v1.5 | 0/TBD | Not started | - |

---
