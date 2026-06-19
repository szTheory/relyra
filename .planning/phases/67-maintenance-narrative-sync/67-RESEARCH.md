# Phase 67: Maintenance Narrative Sync - Research

**Researched:** 2026-06-18  
**Domain:** maintenance narrative, advisory status, CI/release status, seed disposition  
**Confidence:** HIGH for repository findings; MEDIUM for external status because NVD enrichment can change after this check.

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this section: `.planning/phases/67-maintenance-narrative-sync/67-CONTEXT.md`. [VERIFIED: repo read]

### Locked Decisions

#### Narrative Sync
- **D-01:** Keep Phase 67 to narrow narrative cleanup. Do not redesign adopter documentation or rework the public testing story; use Phase 64 and Phase 65 as the locked source for `Relyra.Testing` copy.
- **D-02:** Review `guides/jtbd_user_flows.md` Scene 3 and ADFS references against the current four first-class providers: Okta, Microsoft Entra ID, Google Workspace, and ADFS.
- **D-03:** Fix adjacent stale `FakeIdP`, `TestSupport`, or provider-count mentions only where they contradict the shipped `Relyra.Testing` / Hex-package reality. Demo-local FakeIdP language may remain where it is explicitly scoped to `demo/ledger_loop` or `guides/fake_idp_demo.md`.

#### CVE, CI, And Phase 29 Status
- **D-04:** Backfill `CVE-2026-49454` for `GHSA-jv46-xfwm-36j7` in the advisory and planning/deferred rows. The prior "pending assignment" wording is stale as of 2026-06-18.
- **D-05:** Treat CI/release guard work as a status reconciliation unless a stale repo note is found. The intended guard shape is already present: `mix ci.security` remains made of dedicated `cmd mix test` security suites, release automation runs `mix qa`, release-please PR checks exist, planning-only PR checks exist, and branch protection requires the two security matrix checks.
- **D-06:** Reconcile Phase 29 warning-level follow-ups as planning truth, not a reopened auth-bypass fix. Items WR-02..WR-05 and IN-01..IN-03 should be closed, converted into explicit deferrals, or left with a documented reason. Do not weaken the Phase 29/30 crypto gates.

#### Seed Disposition
- **D-07:** Reclassify or close seed metadata instead of reopening implementation. `SEED-001` shipped through the v1.7 LedgerLoop demo milestone; `SEED-002` is addressed by the public `Relyra.Testing` package/docs path; `SEED-003` is resolved by the retained demo-local FakeIdP documentation.
- **D-08:** Update seed/planning references so completed or stale loose ends do not resurface as new milestone candidates. Preserve demand-gated future candidates (`AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`) as future demand-triggered work, not Phase 67 work.

### the agent's Discretion

The planner may choose the smallest reliable edit set that makes the maintenance narrative truthful. Prefer status/backfill edits, seed frontmatter/status updates, and targeted drift tests or grep checks over broad documentation rewrites.

### Deferred Ideas (OUT OF SCOPE)

- `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` remain demand-gated future candidates and are not Phase 67 maintenance work.
- Any broader public testing API expansion beyond the Phase 64 surface remains out of scope unless a future adopter request triggers it.

### Reviewed Todos (not folded)

No matched todos were found for Phase 67.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Do not implement outside active Phase 67 scope; this research artifact is the only file to write during research. [VERIFIED: AGENTS.md]
- Do not change public API shape, default strictness, security posture, algorithm policy, trust boundaries, key material handling, or SemVer-major behavior in this phase. [VERIFIED: AGENTS.md]
- Do not relax signature, parser, pre-parse guard, crypto, audit, or replay invariants. [VERIFIED: AGENTS.md]
- Do not run `mix hex.publish`; Release Please owns normal publishing. [VERIFIED: AGENTS.md]
- Keep `mix ci.security` as dedicated `cmd mix test` processes; do not collapse security suites into bare `test` alias steps. [VERIFIED: AGENTS.md]

## Phase Requirements

| ID | Description | Research Support |
| --- | --- | --- |
| MAINT-01 | JTBD Scene 3 and ADFS-related narrative drift are reviewed and synced if still stale. | Scene 3 is current; stale adjacent copy remains in README, generated Batteries proof text, `docs/jtbd_gap_map.md`, and one generic-SAML provider-family row. [VERIFIED: repo grep] |
| MAINT-02 | CVE ID backfill status, CI/release guard notes, and Phase 29 warning-level items are triaged with close/defer decisions. | Official sources now map GHSA to `CVE-2026-49454`; CI guard shape is mostly true; Phase 29 items remain non-blocking hardening/interop debt needing explicit disposition. [VERIFIED: GitHub advisory API, CVE Services API, NVD API, repo grep] |
| MAINT-03 | Seeds are cleaned up or reclassified so completed/stale loose ends do not resurface as new milestone candidates. | `SEED-001`, `SEED-002`, and `SEED-003` still have `status: dormant` despite shipped/resolved evidence. [VERIFIED: repo grep] |

## Executive Summary

Phase 67 should be a small reconciliation phase, not a code/security phase. The highest-value work is to replace stale planning and doc phrases that still say "pending CVE", "TestSupport proof", "test-support seam", or generic `FakeIdP` where the current truth is public `Relyra.Testing` or demo-local FakeIdP. [VERIFIED: repo grep]

The external advisory status is no longer ambiguous: GitHub advisory `GHSA-jv46-xfwm-36j7` has `CVE-2026-49454`; CVE Services shows the CVE as `PUBLISHED`; NVD has received it but currently has `vulnStatus: Received` and no configurations. [VERIFIED: GitHub advisory API; VERIFIED: CVE Services API; VERIFIED: NVD API]

The CI/release guard shape described in Phase 67 context is true for the primary release-please path and main security gate. One caveat: the manual `publish-hex.yml` recovery workflow can publish and currently runs `mix ci.release` + `mix ci.security`, but not `mix qa`; treat that as a note to reconcile in planning text, not as a default workflow redesign in this phase. [VERIFIED: repo grep]

## External Status Verification

Checked on 2026-06-18. [VERIFIED: current session]

| Source | Checked URL | Current Result | Planning Conclusion |
| --- | --- | --- | --- |
| GitHub advisory page/API | `https://github.com/szTheory/relyra/security/advisories/GHSA-jv46-xfwm-36j7` and `https://api.github.com/repos/szTheory/relyra/security-advisories/GHSA-jv46-xfwm-36j7` | Advisory is published; `ghsa_id` is `GHSA-jv46-xfwm-36j7`; `cve_id` is `CVE-2026-49454`; vulnerable range is `>= 1.0.0, < 1.2.0`; patched version is `1.2.0`; severity is critical with CVSS 3.1 score 9.1. [VERIFIED: GitHub advisory API] | Backfill local advisory and planning rows with `CVE-2026-49454`; remove pending-assignment language. |
| CVE Services | `https://cveawg.mitre.org/api/cve/CVE-2026-49454` | `cveMetadata.state` is `PUBLISHED`; `datePublished` is `2026-06-18T20:52:22.605Z`; assigner short name is `GitHub_M`; affected product is `szTheory/relyra` with version range `>= 1.0.0, < 1.2.0`. [VERIFIED: CVE Services API] | Treat CVE assignment as complete and current. |
| NVD API | `https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-49454` | `totalResults` is `1`; NVD `vulnStatus` is `Received`; `published` and `lastModified` are `2026-06-18T21:16:29.920`; CVSS data is sourced from GitHub; `configurations` is `null`. [VERIFIED: NVD API] | Record that NVD has received the CVE but enrichment/configuration data may still update later. |
| GitHub branch metadata | `https://api.github.com/repos/szTheory/relyra/branches/main` | Public API says `main` is protected and requires `security (27, 1.19.5)` plus `security (28, 1.19.5)`. [VERIFIED: GitHub branch API] | Current public evidence matches the branch-protection note for required security matrix contexts; full protection settings need authenticated admin API access. |

Exact conclusion: `GHSA-jv46-xfwm-36j7` now has official CVE ID `CVE-2026-49454`; the repository should stop describing the ID as pending. NVD has the record but is not fully enriched yet. [VERIFIED: GitHub advisory API; VERIFIED: CVE Services API; VERIFIED: NVD API]

## Repository Drift Findings

| Area | Finding | Evidence | Recommended Disposition |
| --- | --- | --- | --- |
| JTBD Scene 3 | `guides/jtbd_user_flows.md` Scene 3 is already aligned to current provider scope and `Relyra.Testing`. | Scene 2 names `Relyra.Testing`; Scene 3 lists Okta, Microsoft Entra ID, Google Workspace, and ADFS; provider receipt follows local testing proof. [VERIFIED: `guides/jtbd_user_flows.md`] | No edit needed unless execution touches nearby copy. |
| README local proof | One stale adopter-facing phrase still says "local TestSupport proof". | `README.md:83` says "after the local TestSupport proof"; nearby `README.md:44` already uses `Relyra.Testing.signed_success/1` and `Relyra.Testing.Phoenix.post_response/5`. [VERIFIED: repo grep] | Replace with "local testing proof" or "local `Relyra.Testing` proof". |
| Generated Batteries proof | The generated artifact and generator still say "test-support seam" in the source sentence. | `BATTERIES_INCLUDED.md:3` and `lib/mix/tasks/relyra.batteries_included.ex:82` use that phrase; the proof row at `BATTERIES_INCLUDED.md:21` correctly uses `Relyra.Testing`. [VERIFIED: repo grep] | Update generator text, regenerate `BATTERIES_INCLUDED.md`, and run `mix relyra.batteries_included --check`. |
| JTBD gap map | Maintainer-only gap map still says "prove the path locally with `FakeIdP`" and has old refresh date. | `docs/jtbd_gap_map.md:17` says last refreshed 2026-05-27; `docs/jtbd_gap_map.md:38` says local proof with `FakeIdP`. [VERIFIED: repo grep] | Refresh only the narrow lines to current `Relyra.Testing` / v1.9 truth; keep `docs/jtbd_gap_map.md` maintainers-only. |
| JTBD gap map optional polish | A stale optional-polish line still calls out "Case study FakeIdP reference cleanup". | `docs/jtbd_gap_map.md:242` mentions "Case study FakeIdP reference cleanup"; the case study now uses `Relyra.Testing`, and `guides/fake_idp_demo.md` intentionally scopes FakeIdP to LedgerLoop demo-local support. [VERIFIED: repo grep] | Replace with current maintenance status or remove if no longer an active gap. |
| Generic SAML provider taxonomy | One decoder-table row says README lists seven families as Okta, Entra, Google Workspace, ADFS, Ping, CyberArk, Shibboleth. | `guides/recipes/generic_saml.md:132` conflicts with README's current split: four first-class presets and seven generic runbook families. [VERIFIED: repo grep] | Update that row to avoid false provider-count/taxonomy language. |
| Provider count | Current code and most docs agree on four first-class providers. | `Relyra.Provider.list()` returned `[:adfs, :entra, :google_workspace, :okta]`; `lib/relyra/provider.ex:86-95` registers exactly those four; README, JTBD, case study, and Batteries proof all list four. [VERIFIED: mix run; VERIFIED: repo grep] | No provider-count code/doc redesign. |
| Demo FakeIdP | Demo-local FakeIdP copy is intentional where scoped to LedgerLoop. | `guides/fake_idp_demo.md` says FakeIdP is local demo/test support only, not a production IdP, hosted broker, or Hex package surface. [VERIFIED: repo read] | Do not remove scoped FakeIdP language from `guides/fake_idp_demo.md`. |
| CVE advisory | Local advisory still says CVE is pending. | `docs/advisories/2026-001-xmldsig-signature-not-verified.md:3` and `:65` describe pending assignment. [VERIFIED: repo grep] | Backfill `CVE-2026-49454`; preserve existing advisory facts. |
| CVE polling surfaces | Existing polling helper/workflow still fail when a CVE appears. | `scripts/check_cve_assignment.sh` exits 1 when `cve_id` is non-empty; `.github/workflows/cve-advisory-check.yml` fails when a CVE is assigned. [VERIFIED: repo read] | Convert from "fail when assigned" to "assert expected assigned CVE" or retire the failure signal after backfill. |
| Planning CVE rows | Project state still says the CVE backfill is pending/null. | `.planning/STATE.md:84` says pending async; `.planning/PROJECT.md:58` says checked 2026-05-28 and `cve_id` still null. [VERIFIED: repo grep] | Update state/project rows to assigned/backfilled. |
| Release/security guard notes | Primary release-please path and security gate match intended guard shape. | `release-please.yml:101-108` runs `mix qa`, `mix ci.release`, and `mix ci.security`; `security-gates.yml:73-110` runs `mix qa`, `mix ci.security`, and a standalone gate02 step; `mix.exs:240-259` keeps security suites as dedicated `cmd mix test` lines. [VERIFIED: repo read] | No release automation redesign by default. |
| Manual publish recovery caveat | Manual `publish-hex.yml` can live publish but does not run `mix qa`. | `publish-hex.yml` runs `mix ci.release` and `mix ci.security`, then dry/live Hex publish; no `mix qa` step was found. [VERIFIED: repo read] | Record as a caveat if planning text implies every Hex publish path runs `mix qa`; do not change automation unless explicitly scoped. |
| Phase 29 follow-ups | The follow-up tracker is completed as a tracking artifact, but v1.1 audit still presents the set as worth follow-up. Current code still reflects these as non-blocking hardening/interop items, not already-fixed items. | `.planning/todos/completed/29-code-review-followups.md:13-18`; `.planning/v1.1-MILESTONE-AUDIT.md:21-23` and `:91-92`; current code still has the relevant patterns in `signature.ex`, `pure_beam.ex`, `auto_refresh.ex`, and `algorithm_policy.ex`. [VERIFIED: repo grep] | Add explicit disposition table: defer hardening, document fail-closed reason, or leave with reason. Do not modify crypto code in Phase 67. |
| Seed metadata | All three relevant seeds remain dormant. | `SEED-001`, `SEED-002`, and `SEED-003` each have `status: dormant`; roadmap/state say SEED-001 shipped through v1.7, SEED-002 is addressed by `Relyra.Testing`, and SEED-003 is resolved by retained FakeIdP documentation. [VERIFIED: repo grep] | Change seed frontmatter/status and add resolution notes so they do not resurface as candidates. |

## Recommended Plan Slices

1. **Narrative drift sync for public testing/provider copy.** Touch `README.md`, `docs/jtbd_gap_map.md`, `guides/recipes/generic_saml.md`, `lib/mix/tasks/relyra.batteries_included.ex`, and regenerated `BATTERIES_INCLUDED.md`. Keep `guides/jtbd_user_flows.md`, `guides/case_studies/phoenix_saas_tenant_onboarding.md`, and `guides/fake_idp_demo.md` read-only unless execution finds a directly adjacent stale phrase. [VERIFIED: repo grep]

2. **CVE backfill and polling closeout.** Touch `docs/advisories/2026-001-xmldsig-signature-not-verified.md`, `scripts/check_cve_assignment.sh`, `.github/workflows/cve-advisory-check.yml`, `.planning/STATE.md`, and `.planning/PROJECT.md`. Convert CVE polling from "assignment pending" to "expected CVE assigned"; do not publish or retire any Hex package. [VERIFIED: GitHub advisory API; VERIFIED: repo grep]

3. **CI/release guard status reconciliation.** Touch planning text only by default, likely `.planning/PROJECT.md` and optionally `.planning/RETROSPECTIVE.md` if execution chooses to clarify historical wording. Confirm release-please path runs `mix qa`; record the `publish-hex.yml` recovery caveat without redesigning release workflows. [VERIFIED: repo read]

4. **Phase 29 warning disposition.** Touch `.planning/todos/completed/29-code-review-followups.md`, `.planning/v1.1-MILESTONE-AUDIT.md`, and possibly `.planning/PROJECT.md`. Add item-by-item dispositions for WR-02..WR-05 and IN-01..IN-03. Recommended default: keep as explicit deferred security-hardening/interop debt with reason, not implementation tasks in Phase 67. [VERIFIED: repo grep]

5. **Seed cleanup.** Touch `.planning/seeds/SEED-001-adoption-evidence-demo.md`, `.planning/seeds/SEED-002-testsupport-vs-hex-package.md`, `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and `.planning/PROJECT.md`. Prefer `status: completed` or `status: resolved` consistently across the three seeds and add a dated resolution note in each file. [VERIFIED: repo grep]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`, so Phase 67 should carry explicit plan-time and execution-time checks. [VERIFIED: `.planning/config.json`]

### Requirement Coverage Map

| Requirement | Plan-Time Check | Execution-Time Check |
| --- | --- | --- |
| MAINT-01 | Planner must list every stale narrative phrase found in README, JTBD gap map, generic SAML, Batteries generator/artifact, and confirm `guides/jtbd_user_flows.md` Scene 3 needs no edit. [VERIFIED: repo grep] | Run targeted greps for stale `TestSupport proof`, `test-support seam`, unscoped `FakeIdP` in adopter-facing docs, and stale provider-family row; run `mix ci.docs`; run `mix relyra.batteries_included --check`. |
| MAINT-02 | Planner must cite GitHub advisory, CVE Services, and NVD statuses, plus a release guard truth table for release-please, `publish-hex.yml`, `ci.security`, PR check workflows, and branch metadata. [VERIFIED: API checks; VERIFIED: repo read] | Run API checks or saved curl commands; run `scripts/check_cve_assignment.sh` after it is converted to expected-CVE success; run `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors`; run `mix test test/release/release_hardening_test.exs --warnings-as-errors` if release planning text changes. |
| MAINT-03 | Planner must define final seed statuses for SEED-001..003 and list every planning file updated to prevent resurfacing. [VERIFIED: repo grep] | Run greps proving no relevant seed remains `status: dormant`, no CVE row says pending, and demand-gated protocol seeds remain untouched. |

### Existing Test Infrastructure

- `mix ci.docs` already runs markdown link smoke, adopter voice, troubleshooting/logout/demo drift, Batteries proof check, install proof, and testing demo checks. [VERIFIED: `mix.exs`]
- `test/docs/testing_api_drift_test.exs` already pins the Getting Started `Relyra.Testing` example. [VERIFIED: repo read]
- `test/mix/tasks/relyra_batteries_included_test.exs` already checks the generated proof content and drift behavior. [VERIFIED: repo read]
- `mix ci.security` already includes `test/security/testing_fixture_crypto_test.exs` as a dedicated `cmd mix test` line. [VERIFIED: `mix.exs`]

### Suggested New Checks

- Add a small docs/planning drift test only if execution finds repeated stale terms that are likely to regress. Otherwise, grep plus `mix ci.docs` is enough for this maintenance phase. [ASSUMED]
- If the Batteries source sentence changes, update the generator first and regenerate the artifact; do not hand-edit `BATTERIES_INCLUDED.md` alone because `mix relyra.batteries_included --check` would fail. [VERIFIED: `lib/mix/tasks/relyra.batteries_included.ex`]

## Risks And Guardrails

- Do not change `Relyra.start_login/3`, `Relyra.consume_response/3`, public behaviour callbacks, algorithm policy, replay policy, parser path, signature verification, or public testing API shape in Phase 67. [VERIFIED: AGENTS.md; VERIFIED: 67-CONTEXT.md]
- Do not run `mix hex.publish`, `mix hex.retire`, or any release/tag command. [VERIFIED: AGENTS.md]
- Do not remove demo-local FakeIdP language from `guides/fake_idp_demo.md`; that guide is the canonical retained-demo evidence from Phase 66. [VERIFIED: 66-04-SUMMARY.md]
- Do not treat NVD `Received` as fully enriched; record the current NVD state and avoid inventing affected-configuration details. [VERIFIED: NVD API]
- Do not rewrite release workflows by default. The primary release-please path is already guarded; the manual `publish-hex.yml` caveat should be documented unless the planner explicitly scopes a minimal guard addition. [VERIFIED: repo read]
- Do not mark Phase 29 WR-02..WR-05 as fixed unless code and tests actually change. Current evidence supports explicit deferral/reclassification, not closure by implementation. [VERIFIED: repo grep]
- Do not re-open demand-gated protocol work (`AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`). [VERIFIED: 67-CONTEXT.md]

## Files To Read During Execution

Required:
- `AGENTS.md` [VERIFIED: repo read]
- `.planning/phases/67-maintenance-narrative-sync/67-CONTEXT.md` [VERIFIED: repo read]
- `.planning/STATE.md` [VERIFIED: repo read]
- `.planning/PROJECT.md` [VERIFIED: repo read]
- `.planning/ROADMAP.md` [VERIFIED: repo read]
- `.planning/REQUIREMENTS.md` [VERIFIED: repo read]

Narrative and generated docs:
- `README.md`
- `docs/jtbd_gap_map.md`
- `guides/jtbd_user_flows.md`
- `guides/recipes/generic_saml.md`
- `guides/case_studies/phoenix_saas_tenant_onboarding.md`
- `guides/fake_idp_demo.md`
- `BATTERIES_INCLUDED.md`
- `lib/mix/tasks/relyra.batteries_included.ex`

CVE and release/CI evidence:
- `docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `scripts/check_cve_assignment.sh`
- `.github/workflows/cve-advisory-check.yml`
- `.github/workflows/security-gates.yml`
- `.github/workflows/release-please.yml`
- `.github/workflows/publish-hex.yml`
- `.github/workflows/release-please-pr-checks.yml`
- `.github/workflows/release-please-automerge.yml`
- `.github/workflows/planning-pr-checks.yml`
- `.github/workflows/branch-protection-drift.yml`
- `scripts/setup_branch_protection.sh`
- `mix.exs`

Phase 29 and seed disposition:
- `.planning/todos/completed/29-code-review-followups.md`
- `.planning/v1.1-MILESTONE-AUDIT.md`
- `.planning/seeds/SEED-001-adoption-evidence-demo.md`
- `.planning/seeds/SEED-002-testsupport-vs-hex-package.md`
- `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md`
- `.planning/MILESTONES.md`
- `.planning/phases/64-public-testing-api-package-boundary/64-CONTEXT.md`
- `.planning/phases/65-documentation-truth/65-CONTEXT.md`
- `.planning/phases/66-demo-fakeidp-disposition/66-04-SUMMARY.md`

## Verification Commands

Run these after implementation, scaled to the files actually touched. [ASSUMED]

```bash
# External advisory status
curl -sS -L https://cveawg.mitre.org/api/cve/CVE-2026-49454 | jq '.cveMetadata'
curl -sS -L 'https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-49454' | jq '{totalResults, vulnerabilities: [.vulnerabilities[] | {id: .cve.id, vulnStatus: .cve.vulnStatus, published: .cve.published, lastModified: .cve.lastModified, configurations: .cve.configurations}]}'
curl -sS -L https://api.github.com/repos/szTheory/relyra/security-advisories/GHSA-jv46-xfwm-36j7 | jq '{ghsa_id, cve_id, state, vulnerabilities, cvss, cwes}'

# Narrative drift checks
! rg -n 'local TestSupport proof|test-support seam|prove the path locally with `FakeIdP`|Case study FakeIdP reference cleanup|README lists seven SAML families' README.md BATTERIES_INCLUDED.md docs/jtbd_gap_map.md guides/**/*.md lib/mix/tasks/relyra.batteries_included.ex
mix relyra.batteries_included --check
mix test test/docs/testing_api_drift_test.exs --warnings-as-errors
mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors
mix ci.docs

# CVE polling closeout
scripts/check_cve_assignment.sh
! rg -n 'pending assignment|CVE still pending|cve_id still null|pending async' docs/advisories/2026-001-xmldsig-signature-not-verified.md .planning/STATE.md .planning/PROJECT.md .github/workflows/cve-advisory-check.yml scripts/check_cve_assignment.sh

# CI/release guard spot checks
rg -n 'mix qa|mix ci.security|cmd mix test test/security/testing_fixture_crypto_test.exs|security \\(27, 1\\.19\\.5\\)|security \\(28, 1\\.19\\.5\\)' mix.exs .github/workflows/security-gates.yml .github/workflows/release-please.yml .github/workflows/release-please-pr-checks.yml .github/workflows/planning-pr-checks.yml scripts/setup_branch_protection.sh
mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors
mix test test/release/release_hardening_test.exs --warnings-as-errors

# Seed and Phase 29 disposition checks
! rg -n '^status: dormant' .planning/seeds/SEED-001-adoption-evidence-demo.md .planning/seeds/SEED-002-testsupport-vs-hex-package.md .planning/seeds/SEED-003-demo-fakeidp-login-wip.md
rg -n 'SEED-001|SEED-002|SEED-003|WR-02|WR-03|WR-04|WR-05|IN-01|IN-02|IN-03' .planning/STATE.md .planning/PROJECT.md .planning/MILESTONES.md .planning/todos/completed/29-code-review-followups.md .planning/v1.1-MILESTONE-AUDIT.md

# Formatting and full safety gate if any Elixir generator/workflow file changed
mix format --check-formatted
mix qa
```
