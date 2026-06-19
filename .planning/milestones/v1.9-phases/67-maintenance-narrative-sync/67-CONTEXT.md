# Phase 67: Maintenance Narrative Sync - Context

**Gathered:** 2026-06-18 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Sweep the low-risk carry-forward maintenance items after the public testing API, documentation truth, and LedgerLoop FakeIdP disposition decisions are settled. This phase closes or explicitly defers narrative, seed, CVE, CI/release, and Phase 29 review loose ends only. It does not reopen public API shape, SAML protocol features, security posture, or production trust-boundary behavior.
</domain>

<decisions>
## Implementation Decisions

### Narrative Sync
- **D-01:** Keep Phase 67 to narrow narrative cleanup. Do not redesign adopter documentation or rework the public testing story; use Phase 64 and Phase 65 as the locked source for `Relyra.Testing` copy.
- **D-02:** Review `guides/jtbd_user_flows.md` Scene 3 and ADFS references against the current four first-class providers: Okta, Microsoft Entra ID, Google Workspace, and ADFS.
- **D-03:** Fix adjacent stale `FakeIdP`, `TestSupport`, or provider-count mentions only where they contradict the shipped `Relyra.Testing` / Hex-package reality. Demo-local FakeIdP language may remain where it is explicitly scoped to `demo/ledger_loop` or `guides/fake_idp_demo.md`.

### CVE, CI, And Phase 29 Status
- **D-04:** Backfill `CVE-2026-49454` for `GHSA-jv46-xfwm-36j7` in the advisory and planning/deferred rows. The prior "pending assignment" wording is stale as of 2026-06-18.
- **D-05:** Treat CI/release guard work as a status reconciliation unless a stale repo note is found. The intended guard shape is already present: `mix ci.security` remains made of dedicated `cmd mix test` security suites, release automation runs `mix qa`, release-please PR checks exist, planning-only PR checks exist, and branch protection requires the two security matrix checks.
- **D-06:** Reconcile Phase 29 warning-level follow-ups as planning truth, not a reopened auth-bypass fix. Items WR-02..WR-05 and IN-01..IN-03 should be closed, converted into explicit deferrals, or left with a documented reason. Do not weaken the Phase 29/30 crypto gates.

### Seed Disposition
- **D-07:** Reclassify or close seed metadata instead of reopening implementation. `SEED-001` shipped through the v1.7 LedgerLoop demo milestone; `SEED-002` is addressed by the public `Relyra.Testing` package/docs path; `SEED-003` is resolved by the retained demo-local FakeIdP documentation.
- **D-08:** Update seed/planning references so completed or stale loose ends do not resurface as new milestone candidates. Preserve demand-gated future candidates (`AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`) as future demand-triggered work, not Phase 67 work.

### Claude's Discretion
The planner may choose the smallest reliable edit set that makes the maintenance narrative truthful. Prefer status/backfill edits, seed frontmatter/status updates, and targeted drift tests or grep checks over broad documentation rewrites.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Prior Decisions
- `.planning/ROADMAP.md` - Phase 67 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - MAINT-01, MAINT-02, MAINT-03 traceability.
- `.planning/STATE.md` - Current v1.9 progress and SEED-003 resolution marker.
- `.planning/phases/64-public-testing-api-package-boundary/64-CONTEXT.md` - Locked public `Relyra.Testing` and package-boundary decisions.
- `.planning/phases/65-documentation-truth/65-CONTEXT.md` - Locked adopter-facing testing narrative decisions.
- `.planning/phases/66-demo-fakeidp-disposition/66-04-SUMMARY.md` - Retained demo-local FakeIdP disposition and SEED-003 resolution evidence.

### Narrative Drift Targets
- `guides/jtbd_user_flows.md` - Scene 3 and adopter journey narrative.
- `docs/jtbd_gap_map.md` - Existing stale `FakeIdP` and adoption-gap references.
- `README.md` - Top-level provider and local proof narrative.
- `BATTERIES_INCLUDED.md` - Generated proof map and local testing row.
- `guides/case_studies/phoenix_saas_tenant_onboarding.md` - Case-study local proof and provider framing.
- `guides/fake_idp_demo.md` - Canonical retained demo-local FakeIdP explanation.

### CVE, CI, Release, And Security Follow-up Evidence
- `docs/advisories/2026-001-xmldsig-signature-not-verified.md` - Advisory text requiring CVE backfill.
- `scripts/check_cve_assignment.sh` - CVE polling helper referenced by project state.
- `.github/workflows/cve-advisory-check.yml` - Weekly CVE assignment signal workflow.
- `.github/workflows/security-gates.yml` - Required security matrix workflow.
- `.github/workflows/release-please.yml` - Release Please and Hex publish path.
- `.github/workflows/release-please-pr-checks.yml` - Release Please PR check attachment workflow.
- `.github/workflows/release-please-automerge.yml` - Release PR automerge guard.
- `.github/workflows/planning-pr-checks.yml` - Planning-only PR check attachment workflow.
- `scripts/setup_branch_protection.sh` - Intended branch protection settings.
- `mix.exs` - `qa`, `ci.security`, `ci.docs`, and release aliases.
- `.planning/todos/completed/29-code-review-followups.md` - Preserved Phase 29 warning/info follow-ups.
- `.planning/v1.1-MILESTONE-AUDIT.md` - v1.1 audit status and Phase 29 tech-debt wording.
- `.planning/RETROSPECTIVE.md` - Historical CI/release guard notes and residual ADFS drift note.

### Seed Metadata
- `.planning/seeds/SEED-001-adoption-evidence-demo.md` - v1.7 adoption-evidence demo seed.
- `.planning/seeds/SEED-002-testsupport-vs-hex-package.md` - public testing/package contradiction seed.
- `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md` - demo FakeIdP disposition seed.
- `.planning/MILESTONES.md` - Milestone closure notes for v1.7, v1.8, and v1.9 seed carry-forward.

### External Status Sources
- `https://github.com/szTheory/relyra/security/advisories/GHSA-jv46-xfwm-36j7` - GitHub advisory showing `CVE-2026-49454`.
- `https://cveawg.mitre.org/api/cve/CVE-2026-49454` - CVE record published 2026-06-18.
- `https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-49454` - NVD record for CVE status and affected range.
- `https://api.github.com/repos/szTheory/relyra/branches/main` - Public branch metadata showing `main` protected with required security checks.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Testing` / `Relyra.Testing.Phoenix`: These are already the public local-proof surfaces from Phase 64 and should be the adopter-facing names in any maintenance copy touched by this phase.
- `scripts/check_cve_assignment.sh` and `.github/workflows/cve-advisory-check.yml`: Existing CVE polling surfaces mean Phase 67 should update stale documentation/planning state, not invent a new CVE tracking mechanism.
- `.planning/todos/completed/29-code-review-followups.md`: The Phase 29 warning set is already preserved in one place; use it as the source for close/defer/status wording.

### Established Patterns
- GSD maintenance phases close drift through small planning/doc edits plus explicit evidence, not broad rewrites.
- Security gates stay as dedicated `cmd mix test ... --warnings-as-errors` lines when they protect security invariants. Do not collapse them into bare `test` aliases.
- Release/publication work stays automation-driven. Do not run `mix hex.publish`; do not hand-edit `CHANGELOG.md` for release-please output.
- Demo-local FakeIdP language is acceptable only when it is clearly scoped as demo/test support and not presented as a Hex adopter API or production IdP.

### Integration Points
- Phase 67 edits should connect to `ci.docs` or targeted doc drift checks only if a changed narrative already has, or clearly needs, a lightweight guard.
- Seed metadata updates should align `.planning/seeds/*`, `.planning/STATE.md`, and `.planning/MILESTONES.md` so future milestone selection sees resolved seeds accurately.
- CVE backfill should align the local advisory with GitHub/CVE/NVD status and remove or update stale "pending assignment" deferred references.
</code_context>

<specifics>
## Specific Ideas

- Use `CVE-2026-49454` as the exact advisory ID for `GHSA-jv46-xfwm-36j7`.
- Keep branch-protection wording evidence-based: public branch metadata confirms `main` is protected and requires `security (27, 1.19.5)` plus `security (28, 1.19.5)`; full settings require authenticated GitHub API access.
- Treat stale seed `status: dormant` frontmatter as the main seed-disposition target unless planning inspection finds a stronger local convention for resolved seeds.
</specifics>

<deferred>
## Deferred Ideas

- `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` remain demand-gated future candidates and are not Phase 67 maintenance work.
- Any broader public testing API expansion beyond the Phase 64 surface remains out of scope unless a future adopter request triggers it.

### Reviewed Todos (not folded)
No matched todos were found for Phase 67.
</deferred>

---

*Phase: 67-maintenance-narrative-sync*
*Context gathered: 2026-06-18*
