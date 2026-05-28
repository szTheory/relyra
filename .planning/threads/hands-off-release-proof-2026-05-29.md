# Hands-off release proof — 1.5.3

**Date:** 2026-05-28  
**Outcome:** Pass (with CI hardening PRs and one publish dispatch)

## Trigger

| Item | Value |
|------|-------|
| PR | [#17](https://github.com/szTheory/relyra/pull/17) — `fix(docs): note hands-off release path in getting started` |
| Commit | `0f6d758` on `main` (merge of proof branch) |
| File | `guides/getting_started.md` only |

## Release automation

| Step | Result | URL / ref |
|------|--------|-----------|
| Release Please opens 1.5.3 PR | Yes | [#18](https://github.com/szTheory/relyra/pull/18) |
| Release Please PR Checks | Failed then fixed | [26585932366](https://github.com/szTheory/relyra/actions/runs/26585932366) (403 dispatch); [26591126408](https://github.com/szTheory/relyra/actions/runs/26591126408) (success) |
| security-gates on release PR (OTP 27+28) | Yes (PAT nudge + dispatch) | [26591167423](https://github.com/szTheory/relyra/actions/runs/26591167423) |
| Auto-merge release PR | Yes | [26591378974](https://github.com/szTheory/relyra/actions/runs/26591378974) |
| Manual push to `release-please--branches--main` | **No** | PAT nudge was workflow-automated |

## CI fixes required (not part of doc trigger)

Initial proof exposed three workflow bugs; merged before release PR could merge:

1. [#19](https://github.com/szTheory/relyra/pull/19) — `actions: write` for workflow dispatch; automerge on release-branch `security-gates`
2. [#20](https://github.com/szTheory/relyra/pull/20) — bash array + JSON check names (spaces in `security (27, 1.19.5)`)
3. [#21](https://github.com/szTheory/relyra/pull/21) — tolerate `gh pr checks` exit 1 when no checks yet

## Hex publish

| Item | Value |
|------|-------|
| Version | **1.5.3** |
| Verify | `mix hex.info relyra 1.5.3` — Released 2026-05-28 |
| Publish run | [26591502390](https://github.com/szTheory/relyra/actions/runs/26591502390) (`workflow_dispatch` on Release Please) |

**Gap (resolved):** [#22](https://github.com/szTheory/relyra/pull/22) — `release-please-main` concurrency no longer cancels in-flight runs; automerge dispatches `release-please.yml` after merging the bot release PR so Hex publish does not depend on manual `workflow_dispatch`. E2E confirmation on the next patch release.

## Lessons

1. `release-please-pr-checks` needs `permissions.actions: write` for `gh workflow run`.
2. Check names must be matched as full strings (`"security (27, 1.19.5)"`), not word-split bash loops.
3. `gh pr checks` exits 1 with zero checks — scripts need `|| true` under `set -e`.
4. Automerge should listen for `security-gates` on `release-please--branches--main` (shipped in #19).

## Success criteria (plan checklist)

- [x] Doc-only trigger on `main`
- [x] Bot release PR 1.5.3 without manual version edits
- [x] Release PR CI without human `git push` to release branch
- [x] Release PR merged by Auto Merge workflow
- [x] Hex 1.5.3 live
- [x] Fully unattended Hex publish on release merge (automation shipped in #22; confirm on next release)
