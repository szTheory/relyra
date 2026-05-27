# Phase 43: Hex publish prep — version bump & CHANGELOG backfill - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Stage all repo-side changes required for a release-please-driven `1.4.0` publish: bump `mix.exs` and `.release-please-manifest.json` to `1.4.0`, fix the stale `{:relyra, "~> 0.1.0"}` install pin in `guides/getting_started.md`, and backfill `CHANGELOG.md` with `[1.3.0]` and `[1.4.0]` sections (plus the single-jump rationale). This phase does **not** diagnose release-please, cut the `v1.4.0` git tag, publish to Hex, or run post-publish parity verification — those are Phases 44–45.
</domain>

<decisions>
## Implementation Decisions

### Version Bump
- **D-01:** Set `@version "1.4.0"` in `mix.exs:6` and update `.release-please-manifest.json` from `"1.2.0"` to `"1.4.0"` in the same change set. Both files are the version source of truth release-please reads; a 2-minor jump cannot rely on incremental minor bumps from `1.2.0` alone.
- **D-02:** Do **not** create a `v1.4.0` git tag in this phase. Tag creation and Hex publish are Phase 44 (release-please merge). The existing non-SemVer `v1.4` tag remains; the new SemVer tag replaces it as the publish anchor when automation runs.

### Install Pin
- **D-03:** Update only `guides/getting_started.md:26` to `{:relyra, "~> 1.4"}`. README has no version dep example today; broader README/installer DX is Phase 46. No other `~> 0.1.0` relyra pins were found in the repo.

### CHANGELOG Backfill
- **D-04:** Hand-write `[1.3.0]` and `[1.4.0]` sections in Keep a Changelog format (**Added / Changed / Security**), summarized from milestone roadmaps and phase evidence — **not** a release-please conventional-commit dump for the entire `1.2.0`→`HEAD` gap (the release PR for that gap never merged).
- **D-05:** **`[1.3.0]`** content scope: Advanced Federation milestone — encrypted assertions (ENC-01/02), signed AuthnRequests (AUTHN-01), generic SAML runbook (DOCS-02), identity mapping guide (DOCS-03); phases 32–37 per `.planning/milestones/v1.3-ROADMAP.md`.
- **D-06:** **`[1.4.0]`** content scope: Full SLO + ops polish (SLO-01, DOCS-04/05/06; phases 38–40.1) **plus** v1.5 prep already in tree before publish (Phase 41 tech-debt sweep, Phase 42 login-trace LiveView + `mix relyra.trace`). Adopters installing `{:relyra, "~> 1.4"}` receive all of this in one tarball.
- **D-07:** At the top of the `[1.4.0]` section, document the **single jump 1.2.0 → 1.4.0** rationale: no intermediate `1.3.0` Hex release for adopter clarity; `[1.3.0]` exists in CHANGELOG as historical record of the v1.3 milestone only.
- **D-08:** Insert new sections **above** `[1.2.0]` (newest-first order). Preserve the existing empty `## [Unreleased]` section so `test/release/release_hardening_test.exs` continues to pass.

### Commit Packaging
- **D-09:** Land `mix.exs`, `.release-please-manifest.json`, `guides/getting_started.md`, and `CHANGELOG.md` in one release-prep commit (or a single PR-sized batch) so release-please sees version, manifest, pin, and changelog together.

### Verification
- **D-10:** `mix test --warnings-as-errors` must stay green after the bump. No tests assert a literal `"1.2.0"`; no test updates expected unless a new drift guard is added deliberately in planning.

### Claude's Discretion
- Planner may choose exact CHANGELOG bullet granularity and whether Security items are grouped or per-feature, as long as ENC-01 crypto, XMLDSig verification (v1.2.0 class), SLO, and trace redaction gates are called out where material.
- Planner may add a minimal `test/docs/version_pin_drift_test.exs` (or extend release hardening) if it improves long-term pin hygiene — optional, not required by context.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 43 goal, success criteria, PUB-01/PUB-02 requirements, dependency on Phases 41–42.
- `.planning/REQUIREMENTS.md` — PUB-01, PUB-02 definitions; out-of-scope table (no split 1.3.0 + 1.4.0 Hex releases).
- `.planning/STATE.md` — Single-jump decision, v1.5 sequencing, publish lag assessment.
- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` — Original publish-wedge steps and release-please stall context.

### Milestone Sources (CHANGELOG backfill)
- `.planning/milestones/v1.3-ROADMAP.md` — v1.3 Advanced Federation scope (phases 32–37).
- `.planning/milestones/v1.4-ROADMAP.md` — v1.4 SLO + ops polish scope (phases 38–40.1); milestone key decisions.
- `.planning/phases/41-pre-publish-hygiene-tech-debt-sweep-security-hardening/41-*-SUMMARY.md` — Hygiene items shipping in 1.4.0 tarball.
- `.planning/phases/42-stepwise-login-trace-liveview/42-*-SUMMARY.md` — Trace LiveView + CLI shipping in 1.4.0 tarball.

### Release Automation (read-only for Phase 43; Phase 44 owns fixes)
- `mix.exs` — `@version`, `package/0`, `docs/0` (`source_ref: "v#{@version}"`).
- `.release-please-manifest.json` — manifest version release-please uses for next release.
- `.release-please-config.json` — elixir release type, changelog path.
- `.github/workflows/release-please.yml` — publish-hex job gated on `release_created`.
- `test/release/release_hardening_test.exs` — requires `[Unreleased]` section and release artifact presence.

### Install Pin Target
- `guides/getting_started.md` — canonical Day-1 install pin (line 26 today).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Release discipline is already wired: `mix ci.release` runs `release_hardening_test.exs`; publish workflow verifies `@version` matches release-please output before `mix hex.publish`.
- `[1.2.0]` CHANGELOG section is release-please style (commit-linked bullets) because that release actually shipped; backfill sections for 1.3/1.4 are narrative summaries per ROADMAP, not the same mechanical format.

### Established Patterns
- Version single source of truth: `mix.exs` `@version` referenced by `version:` in project, `source_ref` in docs, and manifest JSON — all three must agree at `1.4.0` before Phase 44.
- OSS discipline (PROJECT.md): never hand-run `mix hex.publish`; Phase 43 only stages what automation consumes.

### Integration Points
- Phase 44 reads staged `mix.exs` + CHANGELOG + manifest to open/merge the release-please PR and trigger Hex publish on tag.
- Phase 45 parity script compares published tarball to `v1.4.0` tag — tarball must include Phase 41 `test_support` exclusion and Phase 42 trace routes already merged before this bump.
</code_context>

<specifics>
## Specific Ideas

- Treat `[1.3.0]` as changelog archaeology for the v1.3 milestone; treat `[1.4.0]` as the adopter-facing "what you get when you `~> 1.4`" story including trace UI and pre-publish hygiene.
- Follow existing `[1.2.0]` precedent for Added/Changed/Security categorization; security items should prominently include XML-Enc adversarial corpus, signed AuthnRequest corpus, and (in 1.4.0) login-trace redaction gate where applicable.
</specifics>

<deferred>
## Deferred Ideas

- Release-please stall diagnosis and `RELEASE-PLEASE-DIAGNOSIS.md` → Phase 44 (PUB-03).
- `v1.4.0` git tag creation and Hex publish → Phase 44.
- Post-publish tarball byte-equal verification → Phase 45 (PUB-04).
- README-first install snippet and `mix relyra.install` auto-injection → Phase 46 (DX-01/02/03).

</deferred>

---

*Phase: 43-hex-publish-prep-version-bump-changelog-backfill*
*Context gathered: 2026-05-27*
