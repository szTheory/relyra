# Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Diagnose why the release-please pipeline stalled after v1.2.0, apply the fix, and drive a `1.4.0` publish to Hex via CI automation — **not** manual `mix hex.publish`. Document the diagnosis in `RELEASE-PLEASE-DIAGNOSIS.md` so the failure mode is detectable on recurrence. Post-publish tarball parity verification is Phase 45; README/installer DX is Phase 46.
</domain>

<decisions>
## Implementation Decisions

### Root cause diagnosis
- **D-01:** Primary stall is **open stale release-please PR #5** (`chore(main): release 1.3.0`, opened 2026-05-26, never merged) combined with **local `main` 110 commits ahead of `origin/main`** (Phase 41–43 work not yet pushed). This is **not** a broken workflow or missing `HEX_API_KEY` — release-please runs succeed on remote pushes and PR #5 was created normally.
- **D-02:** Hex remains at `1.2.0` because no release PR has merged since v1.2.0; the v1.3/v1.4 feature gap accumulated on git without a release-please merge cycle.

### Stale PR resolution
- **D-03:** **Close PR #5 without merging.** It targets `1.3.0` with release-please conventional-commit CHANGELOG — contradicts the single-jump `1.2.0 → 1.4.0` strategy locked in Phase 43 (D-04/D-07). Merging it would publish the wrong version and overwrite hand-written CHANGELOG backfill.

### Unstall sequence
- **D-04:** Execute in order: (1) push local `main` to `origin/main`, (2) close stale PR #5, (3) trigger release-please (automatic on push or `workflow_dispatch` on `.github/workflows/release-please.yml`), (4) reconcile a **1.4.0** release PR or direct release, (5) merge → creates SemVer `v1.4.0` tag (distinct from existing non-SemVer `v1.4`) → triggers `publish-hex` job.
- **D-05:** Primary publish path is `.github/workflows/release-please.yml` `publish-hex` job — must pass `mix ci.release` and `mix ci.security` before live `mix hex.publish --yes`. Recovery fallback only: `.github/workflows/publish-hex.yml` `workflow_dispatch` with tag `v1.4.0` if tag exists but publish failed — **never** local `mix hex.publish`.

### CHANGELOG protection
- **D-06:** Preserve Phase 43 hand-written `[1.3.0]` and `[1.4.0]` Keep-a-Changelog narrative sections. If release-please opens a PR that regenerates CHANGELOG with conventional-commit links, edit the PR to preserve the narrative backfill — do not accept a commit-link dump for the 1.2.0→HEAD gap.

### Pre-set manifest behavior
- **D-07:** Phase 43 pre-set `mix.exs` and `.release-please-manifest.json` to `1.4.0`. Executor must verify release-please behavior after push (may tag immediately, may open a no-op release PR, or may need manifest reconciliation). Document observed behavior in `RELEASE-PLEASE-DIAGNOSIS.md` — this is the highest-uncertainty step in the sequence.

### Success verification
- **D-08:** Phase complete when: `hex.pm/packages/relyra` lists `1.4.0` as latest; `mix hex.info relyra` from fresh checkout reports `1.4.0`; publish completed via CI (`publish-hex` job logs), not local shell; `v1.4.0` git tag exists on GitHub.

### Diagnosis artifact
- **D-09:** Write `.planning/phases/44-release-please-pipeline-diagnosis-v1-4-0-hex-publish/RELEASE-PLEASE-DIAGNOSIS.md` documenting: root cause (stale PR + unpushed commits + version strategy conflict), fix applied, observed release-please behavior with pre-set manifest, and recurrence checklist (open release-please PRs targeting wrong version, local/remote drift, manifest vs mix.exs mismatch, Hex still on old version while git tags advance).

### Claude's Discretion
- Exact PR close comment wording and whether to delete the `release-please--branches--main` branch after close.
- Whether to use `workflow_dispatch` vs waiting for push-triggered release-please on first attempt.
- How to reconcile release-please PR body/changelog if automation produces partial conflicts with hand-written sections.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 44 goal, success criteria, PUB-03 requirement.
- `.planning/REQUIREMENTS.md` — PUB-03 definition; PUB-01 tag portion (SemVer `v1.4.0` distinct from `v1.4`).
- `.planning/STATE.md` — v1.5 sequencing, single-jump decision, publish lag assessment.
- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` — Original stall context and publish wedge steps.

### Prior Phase Context
- `.planning/phases/43-hex-publish-prep-version-bump-changelog-backfill/43-CONTEXT.md` — Staged version sources, CHANGELOG backfill decisions, explicit deferral of tag + publish to Phase 44.
- `.planning/phases/43-hex-publish-prep-version-bump-changelog-backfill/43-RESEARCH.md` — Release-please integration notes, stale PR risk, recovery path via `publish-hex.yml`.

### Release Automation
- `.github/workflows/release-please.yml` — Primary release + publish pipeline; `publish-hex` gated on `release_created`.
- `.github/workflows/publish-hex.yml` — Recovery `workflow_dispatch` publish path.
- `.github/workflows/release-parity.yml` — Release parity lane reference.
- `.release-please-config.json` — Elixir release type, `include-v-in-tag: true`.
- `.release-please-manifest.json` — Pre-set to `1.4.0` by Phase 43.
- `mix.exs` — `@version "1.4.0"`, `ci.release` alias.
- `test/release/release_hardening_test.exs` — Release discipline gate (`[Unreleased]` section required).
- `CHANGELOG.md` — Hand-written `[1.4.0]` and `[1.3.0]` sections; preserve on publish.

### Policy
- `CLAUDE.md` — Never manual `mix hex.publish`; Release Please automation handles publish.
- `.planning/PROJECT.md` — OSS discipline contract (release-please + post-publish parity).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Release-please + publish-hex pipeline fully wired with idempotency check (`mix hex.info` skip if version exists), dry-run step, and Hex API verification loop.
- Recovery workflow `publish-hex.yml` mirrors primary publish gates (`mix ci.release`, `mix ci.security`, dry-run, live publish) — usable if tag exists but primary job failed.

### Established Patterns
- Version sources must agree: `mix.exs` `@version`, `.release-please-manifest.json`, and release-please PR output — publish job greps `@version` against release output.
- Publish job runs full security lane (`mix ci.security`) — each suite as separate `cmd mix test` process (Phase 30 hollow-gate invariant).
- `[Unreleased]` section must remain in CHANGELOG for `mix ci.release` to pass.

### Integration Points
- GitHub PR #5 (`release-please--branches--main`) — stale 1.3.0 release PR to close before reconciling 1.4.0.
- `origin/main` — 110 commits behind local; push is prerequisite for release-please to see Phase 43 staging.
- Hex.pm — currently `1.2.0`; success gate is `1.4.0` indexed.
- Existing git tag `v1.4` (non-SemVer) — new `v1.4.0` tag is distinct publish anchor per PUB-01.
</code_context>

<specifics>
## Specific Ideas

- Treat PR #5 as the smoking gun — it proves release-please was working but the release PR was never merged, not that automation is broken.
- The 110-commit local/remote gap explains why Phase 43 staging (manifest `1.4.0`, narrative CHANGELOG) hasn't reached GitHub yet — release-please on remote still thinks next release is `1.3.0`.
- Recurrence checklist should include `gh pr list --search "release-please"` and `git status -sb` (ahead/behind origin) as first diagnostic steps.
</specifics>

<deferred>
## Deferred Ideas

- Post-publish tarball byte-equal verification → Phase 45 (PUB-04).
- README-first install snippet and `mix relyra.install` auto-injection → Phase 46 (DX-01/02/03).
- Retiring non-SemVer `v1.4` git tag → optional cleanup, not required for Hex publish (Hex uses `v1.4.0`).

</deferred>

---

*Phase: 44-release-please-pipeline-diagnosis-v1-4-0-hex-publish*
*Context gathered: 2026-05-27*
