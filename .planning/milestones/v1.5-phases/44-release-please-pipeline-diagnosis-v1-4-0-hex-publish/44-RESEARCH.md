# Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish — Research

**Researched:** 2026-05-27  
**Phase:** 44 — Release-please pipeline diagnosis & v1.4.0 Hex publish  
**Requirements:** PUB-03  
**Context:** `44-CONTEXT.md` (USER DECISIONS — authoritative for scope)

## Summary

Phase 44 is an **operations wedge**: diagnose why Hex remains at `1.2.0` while git carries v1.3/v1.4 work, unstall release-please, drive `1.4.0` publish through CI (`release-please.yml` → `publish-hex` job), and document the failure mode in `RELEASE-PLEASE-DIAGNOSIS.md`. Phase 43 already staged version sources (`mix.exs` + manifest → `1.4.0`) and hand-written CHANGELOG backfill locally; **113 commits are ahead of `origin/main`** and **open PR #5 targets `1.3.0`** — the primary stall, not broken automation.

**Primary recommendation:** Three-wave plan split — (1) pre-flight + diagnosis draft, (2) push + close stale PR + trigger release-please with human gate, (3) reconcile/merge 1.4.0 release PR preserving narrative CHANGELOG + verify Hex publish + finalize diagnosis. Recovery fallback: `publish-hex.yml` `workflow_dispatch` with tag `v1.4.0` only if tag exists but primary publish failed.

---

## 1. Stall Diagnosis (Confirmed 2026-05-27)

| Signal | Observed state | Implication |
|--------|----------------|-------------|
| Hex latest | `1.2.0` (2026-05-25) | Last successful release-please merge + publish cycle |
| Local `main` vs `origin/main` | **113 commits ahead** | Phase 41–43 staging never reached GitHub; remote release-please still on pre-v1.5 tree |
| Open release-please PR | **#5** `chore(main): release 1.3.0` (2026-05-26), branch `release-please--branches--main` | Automation **worked** — release PR was opened but **never merged** |
| PR #5 file diff | `mix.exs` → `1.3.0`, manifest → `1.3.0`, CHANGELOG conventional-commit dump | Conflicts with Phase 43 single-jump `1.4.0` + narrative backfill — **must close without merge** (D-03) |
| Git tags | `v1.2.0` (last SemVer release); `v1.4` (non-SemVer milestone marker) | No `v1.3.0` or `v1.4.0` SemVer tags |
| Local version sources | `mix.exs` `@version "1.4.0"`, manifest `"1.4.0"` | Phase 43 complete locally; not on remote |
| Workflows | `release-please.yml` + `publish-hex.yml` present; `release_hardening_test.exs` green prerequisites | Pipeline wired; not a missing-token/missing-workflow failure |

**Root cause (D-01):** Stale unmerged release-please PR #5 for `1.3.0` + unpushed local commits + version-strategy conflict with Phase 43 `1.4.0` jump. Hex stuck at `1.2.0` because no release PR merged since v1.2.0 (D-02).

**Not the root cause:** Missing `HEX_API_KEY` (publish job never ran — no merge since v1.2.0); broken release-please action (PR #5 proves it ran successfully).

---

## 2. Unstall Sequence (Authoritative — from CONTEXT D-04)

Execute **in order**:

1. **Pre-flight:** `mix test --warnings-as-errors`, `mix ci.release`, `mix ci.security` on local `main` (must be green before push).
2. **Push** local `main` → `origin/main` (113 commits including Phase 43 staging).
3. **Close PR #5 without merging** — comment explaining superseded by `1.4.0` single-jump strategy.
4. **Trigger release-please** — automatic on push to `main`; fallback `workflow_dispatch` on `.github/workflows/release-please.yml`.
5. **Reconcile 1.4.0 release PR** — observe release-please behavior with pre-set manifest `1.4.0` (D-07 highest uncertainty); edit PR to preserve hand-written `[1.3.0]`/`[1.4.0]` CHANGELOG if automation regenerates sections (D-06).
6. **Merge** release PR → creates SemVer tag `v1.4.0` (`include-v-in-tag: true`) → `publish-hex` job runs when `release_created == 'true'`.
7. **Verify** Hex lists `1.4.0`; `mix hex.info relyra` reports `1.4.0`.
8. **Recovery (only if needed):** If `v1.4.0` tag exists but publish failed, run `publish-hex.yml` `workflow_dispatch` with `tag: v1.4.0`, `release_version: 1.4.0` — never local `mix hex.publish`.

---

## 3. Pre-Set Manifest Behavior (D-07 Uncertainty)

Phase 43 set `.release-please-manifest.json` and `mix.exs` to `1.4.0` **before** any release merge. After push, release-please may:

| Outcome | Likely trigger | Executor action |
|---------|----------------|-----------------|
| **A. Opens/updates release PR for `1.4.0`** | Manifest + mix.exs already at target; commits since `v1.2.0` warrant release | Review PR diff; preserve narrative CHANGELOG sections; merge |
| **B. Opens PR with wrong version** (e.g. `1.3.0` or `1.5.0`) | Stale release-please state before PR #5 closed | Close wrong PR; re-run after #5 closed; edit manifest if needed |
| **C. Minimal/no-op PR** (version files unchanged) | Files already at `1.4.0` on branch | Merge if release-please marks ready; CHANGELOG diff may still need curation |
| **D. Direct release on push** (`release_created=true` without PR) | release-please v4 direct-release path | Monitor workflow outputs; skip PR merge if tag already created |
| **E. No release activity** | Concurrency cancel, stale branch, or manifest confusion | `workflow_dispatch`; verify PR #5 branch deleted; check Actions logs |

**Document observed outcome in `RELEASE-PLEASE-DIAGNOSIS.md`** — this is mandatory for recurrence detection.

**CHANGELOG protection (D-06):** PR #5's body shows release-please generates conventional-commit link dumps. Phase 43 hand-wrote milestone narratives. If new PR regenerates `[1.3.0]`/`[1.4.0]`, **edit the PR branch** to restore narrative sections before merge — do not accept commit-link dump for the 1.2.0→HEAD gap.

---

## 4. Publish Pipeline Contract

### Primary path: `.github/workflows/release-please.yml`

```
push main → release-please job → (merge PR) → release_created=true
  → publish-hex job (checkout tag_name)
  → grep @version in mix.exs
  → mix ci.release
  → mix ci.security
  → mix hex.publish --dry-run --yes
  → idempotency check (skip if 1.4.0 already on Hex)
  → mix hex.publish --yes
  → curl verify hex.pm API
```

### Recovery path: `.github/workflows/publish-hex.yml`

- `workflow_dispatch` inputs: `tag` (required), `release_version` (optional, default strip `v` from tag), `dry_run` (bool).
- Same gates as primary path.
- Use **only** when `v1.4.0` tag exists but primary `publish-hex` failed.

### Forbidden path

- Local `mix hex.publish` — CLAUDE.md + PROJECT.md OSS discipline.

---

## 5. Files Touched in Phase 44

| File | Action | Notes |
|------|--------|-------|
| `.planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` | **Create/update** | Primary phase artifact (D-09) |
| `CHANGELOG.md` | **Maybe edit via release PR** | Preserve narrative if release-please regenerates (D-06) |
| `mix.exs` / manifest | **Read-only expected** | Already `1.4.0` from Phase 43; release PR may touch — verify stays `1.4.0` |
| GitHub PR #5 | **Close** | No merge |
| `origin/main` | **Receive push** | 113 commits |
| Hex.pm | **Verify only** | Target: `1.4.0` latest |

No application code changes expected unless CI failure requires a fix (out of scope unless blocking publish gates).

---

## 6. Verification Commands

### Pre-push (local)

```bash
mix test --warnings-as-errors
mix ci.release
mix ci.security
grep '@version "1.4.0"' mix.exs
grep '"1.4.0"' .release-please-manifest.json
git status -sb   # expect ahead of origin/main
gh pr list --search "release-please" --state open
```

### Post-push / post-merge

```bash
gh run list --workflow=release-please.yml --limit 5
gh pr list --search "release-please" --state open
git fetch --tags && git tag -l 'v1.4.0'
mix hex.info relyra
curl -fsS https://hex.pm/api/packages/relyra/releases/1.4.0 | grep version
gh run view <publish-hex-run-id> --log   # confirm mix hex.publish --yes in CI, not local
```

### Success gates (PUB-03 / D-08)

| Check | Command / signal |
|-------|------------------|
| Diagnosis artifact exists | `test -f .planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` |
| SemVer tag | `git tag -l v1.4.0` non-empty on GitHub |
| Hex latest | `mix hex.info relyra` shows `1.4.0` in recent releases |
| Adopter pull | Fresh checkout + `{:relyra, "~> 1.4"}` resolves to `1.4.0` |
| CI publish proof | `publish-hex` job log contains `mix hex.publish --yes` success |

---

## 7. Pitfalls

| Pitfall | Impact | Mitigation |
|---------|--------|------------|
| **Merging PR #5** | Publishes `1.3.0` with wrong CHANGELOG | Close without merge (D-03) |
| **Push before CI green** | publish-hex fails on `mix ci.security` | Pre-flight gates locally |
| **Manual `mix hex.publish`** | OSS discipline violation | CI-only; grep local shell history should show absence |
| **Accepting conventional-commit CHANGELOG dump** | Loses milestone narratives | Edit release PR branch (D-06) |
| **Confusing `v1.4` with `v1.4.0`** | Wrong tag anchor | Hex publish uses SemVer `v1.4.0` only |
| **Manifest/mix.exs drift after PR merge** | publish grep step fails | Verify `@version "1.4.0"` on tag checkout |
| **Skipping push** | Remote still stale; release-please sees old tree | Push is step 1 of unstall |
| **Recovery publish before tag exists** | `publish-hex.yml` checkout fails | Tag must exist first |
| **Declaring success before Hex indexes** | False pass | Use workflow verify loop or `mix hex.info` poll |

---

## 8. Validation Architecture

### Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) + GitHub CLI + Hex CLI |
| **Config file** | `mix.exs` (`ci.release`, `ci.security`) |
| **Phase gate (local)** | `mix test --warnings-as-errors` + `mix ci.release` + `mix ci.security` |
| **Phase gate (remote)** | `release-please.yml` publish-hex job |
| **Estimated runtime** | Local gates ~5–15 min; CI publish ~15–25 min |

### Per-requirement verification map

| Requirement | Acceptance pattern | Automated command | Manual? |
|-------------|-------------------|-------------------|---------|
| PUB-03 diagnosis | `RELEASE-PLEASE-DIAGNOSIS.md` contains root cause, fix, recurrence checklist | `rg 'Root cause|Recurrence checklist' .planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` | Partial (human verifies prose) |
| PUB-03 unstall | PR #5 closed; new 1.4.0 path merged | `gh pr view 5 --json state` → `CLOSED`; `gh pr list --search "release-please"` | Yes (merge gate) |
| PUB-03 tag | `v1.4.0` exists | `git tag -l v1.4.0` | No |
| PUB-03 Hex publish | `1.4.0` on Hex | `mix hex.info relyra \| grep 1.4.0` | Poll if indexing slow |
| PUB-03 CI publish | No local publish | CI log inspection | Yes |
| PUB-01 tag portion | SemVer `v1.4.0` distinct from `v1.4` | `git tag -l 'v1.4*'` | No |

### Manual-only verifications

| Behavior | Why manual | Instructions |
|----------|------------|--------------|
| Push 113 commits to origin | Requires network + maintainer approval | `git push origin main` after pre-flight green |
| Close PR #5 | Human judgment on comment | `gh pr close 5 --comment "..."` |
| Merge release PR | GitHub UI/gh merge after CHANGELOG review | `gh pr merge <N> --merge` |
| CHANGELOG narrative preservation | Visual diff review | Compare PR diff against Phase 43 CHANGELOG sections |
| CI publish log proof | External system | `gh run view --log` on publish-hex job |

---

## 9. Recommended Plan Split

Phase 44 mixes **autonomous documentation** with **human-gated GitHub ops**. Three plans across three waves:

| Plan | Wave | Scope | `autonomous` | Depends |
|------|------|-------|--------------|---------|
| **44-01** | 1 | Pre-flight verification + draft `RELEASE-PLEASE-DIAGNOSIS.md` (root cause + recurrence checklist skeleton) | `true` | — |
| **44-02** | 2 | Push `main`, close PR #5, trigger release-please, observe initial workflow/PR state | `false` | 44-01 |
| **44-03** | 3 | Reconcile/merge 1.4.0 release PR (preserve CHANGELOG), verify tag + Hex publish, finalize diagnosis + recovery notes | `false` | 44-02 |

**Rationale:** Wave 1 produces the diagnosis artifact early (ROADMAP success criterion #1). Waves 2–3 separate "unstall" from "publish verify" with explicit human checkpoints for push and merge — matching CONTEXT D-04 ordering without combining irreversible remote actions into one autonomous plan.

**Alternative (2 plans):** Merge 44-02 + 44-03 if maintainer prefers single GitHub ops session — acceptable if planner adds two `<checkpoint>` tasks inside one plan.

**Do NOT plan:** Post-publish tarball parity (Phase 45), README DX (Phase 46), manual hex publish, or retiring `v1.4` tag (deferred).

---

## RESEARCH COMPLETE
