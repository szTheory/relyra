---
phase: 44-release-please-pipeline-diagnosis-v1-4-0-hex-publish
status: passed
verified: 2026-05-27
requirements: [PUB-03]
---

# Phase 44 Verification

**Status:** passed

## Must-haves

| Truth | Verified |
|-------|----------|
| Release PR for 1.4.0 merged; narrative CHANGELOG preserved | PR #6 merged; `[1.4.0]`/`[1.3.0]` sections on `main` |
| Git tag `v1.4.0` exists (SemVer) | `git tag -l v1.4.0` |
| Hex.pm lists relyra 1.4.0; CI publish | `mix hex.info` + run 26538511601 logs |
| RELEASE-PLEASE-DIAGNOSIS.md complete | Root cause, fix, observed behavior, recurrence checklist |
| `{:relyra, "~> 1.4"}` resolves to 1.4.0 | `mix hex.info` Config line |

## Evidence

- Workflow: https://github.com/szTheory/relyra/actions/runs/26538511601
- Hex: https://hex.pm/packages/relyra/1.4.0
