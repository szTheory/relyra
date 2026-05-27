# Release-Please Pipeline Diagnosis — Relyra v1.4.0

**Captured:** 2026-05-27  
**Phase:** 44 — release-please-pipeline-diagnosis-v1-4-0-hex-publish  
**Status:** Pre-push draft (Plans 44-02/44-03 own remote unstall + publish)

## Summary

Hex.pm remains on **1.2.0** while local `main` carries Phase 41–43 work staged for **1.4.0**. The automation is not broken: `release-please.yml` and `publish-hex.yml` are wired, PR #5 was created normally, and no `HEX_API_KEY` gap explains the stall. The pipeline is blocked by an **unmerged stale release PR** targeting the wrong version (**1.3.0**), **114 unpushed commits** on local `main`, and a **version-strategy conflict** between release-please’s conventional 1.3.0 release and Phase 43’s single-jump 1.4.0 narrative CHANGELOG.

## Root Cause

- **Primary (D-01):** Open stale release-please **PR #5** — `chore(main): release 1.3.0` (opened 2026-05-26, never merged).
- **Contributing:** Local `main` is **114 commits ahead** of `origin/main` — Phase 41–43 work (tech-debt sweep, trace LiveView, version/CHANGELOG prep) is not on GitHub.
- **Version conflict:** PR #5 would publish **1.3.0** with release-please conventional-commit CHANGELOG. Phase 43 staged single-jump **1.2.0 → 1.4.0** with hand-written `[1.3.0]` / `[1.4.0]` milestone narratives — **merging PR #5 is forbidden** (D-03).
- **Not root cause:** Missing `HEX_API_KEY` or broken workflows. Evidence: PR #5 exists (release-please ran on remote), `.github/workflows/release-please.yml` and `publish-hex.yml` are present and gated on `mix ci.release` / `mix ci.security`.

## Evidence Table

| Signal | Observed (2026-05-27) | Implication |
|--------|----------------------|-------------|
| Hex latest version | **1.2.0** (2026-05-25) | No release merge since v1.2.0 |
| `mix.exs` `@version` | **1.4.0** | Local sources ready for 1.4.0 publish |
| `.release-please-manifest.json` | `"."` → **1.4.0** | Manifest pre-set by Phase 43 |
| `git status -sb` | `main...origin/main [ahead 114]` | Remote cannot see Phase 41–43 commits |
| Open release-please PR | **#5** `chore(main): release 1.3.0` (OPEN) | Stale wrong-version release blocks clean 1.4.0 path |
| Git tags (`v1.*`) | `v1.2.0`, non-SemVer `v1.4`; **no `v1.4.0`** | Tag + publish never completed for 1.4.0 |
| Pre-push CI (Plan 44-01) | `mix ci.release`, `mix ci.security`, release hardening — **green** | Safe to push once maintainer approves |

## Fix Plan (ordered)

1. **Pre-flight** — version coherence + full CI gates (Plan **44-01**, complete).
2. **Push** `main` → `origin/main` after maintainer approval (Plan **44-02**).
3. **Close PR #5 without merge** — superseded by 1.4.0 strategy (Plan **44-02**).
4. **Trigger release-please** — automatic on push or `gh workflow run release-please.yml --ref main` (Plan **44-02**).
5. **Reconcile 1.4.0 release PR** — preserve hand-written CHANGELOG narratives; do not accept commit-link dump (Plan **44-03**).
6. **Merge release PR** (or confirm direct release) → `v1.4.0` tag → `publish-hex` job (Plan **44-03**).
7. **Verify Hex** — `mix hex.info relyra` lists 1.4.0; CI log shows `mix hex.publish --yes` (Plan **44-03**).

## Observed Release-Please Behavior

`TBD — complete in Plan 44-03 after push and merge.`

Initial post-push notes will be appended by Plan 44-02 (push timestamp, PR #5 close, first `release-please.yml` run after push).

## Recurrence Checklist

When Hex lags behind git again, run in order:

1. `mix hex.info relyra` — latest version vs expected
2. `git status -sb` — ahead/behind `origin/main` drift
3. `gh pr list --search "release-please" --state open` — stale release PRs targeting wrong version
4. `grep '@version' mix.exs` vs `cat .release-please-manifest.json` — version source agreement
5. `gh run list --workflow=release-please.yml --limit 3` — last automation runs
6. `git tag -l 'v1.*'` — SemVer tag presence vs Hex

## Recovery Path

If **`v1.4.0` tag exists** but Hex still shows **1.2.0** and the primary `publish-hex` job in `release-please.yml` failed or was skipped:

```bash
gh workflow run publish-hex.yml \
  -f tag=v1.4.0 \
  -f release_version=1.4.0 \
  -f dry_run=false
```

Monitor: `gh run list --workflow=publish-hex.yml --limit 1` then `gh run watch {RUN_ID} --exit-status`.

**Never run local `mix hex.publish`** — publish only via CI (`CLAUDE.md`, PUB-03). Local publish bypasses `mix ci.security` gates.
