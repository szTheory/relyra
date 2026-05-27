---
phase: 44
slug: release-please-pipeline-diagnosis-v1-4-0-hex-publish
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) + GitHub CLI + Hex CLI |
| **Config file** | `mix.exs` (`ci.release`, `ci.security` aliases) |
| **Quick run command** | `mix test test/release/release_hardening_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors && mix ci.release && mix ci.security` |
| **Estimated runtime** | ~5–15 min local; CI publish job ~15–25 min |

---

## Sampling Rate

- **After every task commit:** Run quick release hardening test if repo files changed; otherwise `grep` acceptance only
- **After every plan wave:** Run full local suite before any `git push`
- **Before `/gsd-verify-work`:** Pre-flight full suite green + Hex `1.4.0` visible + diagnosis file complete
- **Max feedback latency** | 900 seconds (CI publish polling)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | PUB-03 | TM-01 | No local `mix hex.publish` in plan or execution | grep | `! rg 'mix hex\.publish' .planning/phases/44-*/*-PLAN.md` | ✅ | ⬜ pending |
| 44-01-02 | 01 | 1 | PUB-03 | — | Version sources at 1.4.0 pre-push | grep | `grep '@version "1.4.0"' mix.exs && grep '"1.4.0"' .release-please-manifest.json` | ✅ | ⬜ pending |
| 44-01-03 | 01 | 1 | PUB-03 | — | Diagnosis artifact drafted | file | `test -f .planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` | ❌ W0 | ⬜ pending |
| 44-02-01 | 02 | 2 | PUB-03 | TM-02 | Pre-push CI gates green | integration | `mix test --warnings-as-errors && mix ci.release && mix ci.security` | ✅ | ⬜ pending |
| 44-02-02 | 02 | 2 | PUB-03 | — | PR #5 closed without merge | manual+gh | `gh pr view 5 --json state -q .state` → `CLOSED` | ✅ | ⬜ pending |
| 44-03-01 | 03 | 3 | PUB-03 | TM-03 | Release PR preserves @version 1.4.0 | grep | `grep '@version "1.4.0"' mix.exs` on release tag | ✅ | ⬜ pending |
| 44-03-02 | 03 | 3 | PUB-03 | TM-01 | Publish via CI not local shell | manual | Inspect `publish-hex` job log for `mix hex.publish --yes` | ✅ | ⬜ pending |
| 44-03-03 | 03 | 3 | PUB-03 | — | Hex lists 1.4.0 | integration | `mix hex.info relyra \| grep -F '1.4.0'` | ✅ | ⬜ pending |
| 44-03-04 | 03 | 3 | PUB-03 | — | SemVer tag v1.4.0 exists | git | `git fetch --tags && git tag -l v1.4.0` | ✅ | ⬜ pending |
| 44-03-05 | 03 | 3 | PUB-03 | — | Diagnosis finalized with observed RP behavior | file+rg | `rg 'Observed release-please behavior|Recurrence checklist' .planning/phases/44-*/RELEASE-PLEASE-DIAGNOSIS.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing `mix ci.release` + `release_hardening_test.exs` cover release workflow wiring
- [x] Existing `mix ci.security` covers pre-publish security lane
- [ ] `RELEASE-PLEASE-DIAGNOSIS.md` — created in Plan 44-01 Task 1

*No new ExUnit files required for phase success; primary proof is GitHub + Hex external state.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push 113 commits to origin | PUB-03 | Maintainer gate + irreversible remote mutation | After local gates green: `git push origin main` |
| Close PR #5 | PUB-03 | GitHub API/UI action | `gh pr close 5 --comment "Superseded by 1.4.0 single-jump release prep (Phase 43/44)"` |
| Merge 1.4.0 release PR | PUB-03 | CHANGELOG narrative review | Diff PR CHANGELOG against Phase 43 hand-written sections before merge |
| CI publish proof | PUB-03 | External CI logs | `gh run list --workflow=release-please.yml`; verify publish-hex success |
| Recovery publish | PUB-03 | Only if primary failed | `gh workflow run publish-hex.yml -f tag=v1.4.0 -f release_version=1.4.0` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 900s for CI-dependent tasks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
