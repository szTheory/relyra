# Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 44-release-please-pipeline-diagnosis-v1-4-0-hex-publish
**Mode:** assumptions
**Areas analyzed:** Root cause diagnosis, Stale PR resolution, Unstall sequence, CHANGELOG protection, Recovery fallback, Success verification, Diagnosis artifact

## Assumptions Presented

### Root cause diagnosis
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Stall is open stale PR #5 (1.3.0) + local main 110 commits ahead of origin; not broken workflow or missing HEX_API_KEY | Confident | `gh pr list` PR #5 OPEN since 2026-05-26; `git status -sb` ahead 110; `mix hex.info relyra` latest 1.2.0; release-please workflow runs green |

### Stale PR resolution
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Close PR #5 without merging — never ship 1.3.0 to Hex | Confident | PR #5 targets 1.3.0; Phase 43 D-04/D-07 single jump to 1.4.0; PR diff shows conventional-commit CHANGELOG overwrite |

### Unstall sequence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Push → close stale PR → reconcile release-please for 1.4.0 → merge → auto-publish | Likely | `.github/workflows/release-please.yml` push trigger + publish-hex job; Phase 43 manifest at 1.4.0 |

### CHANGELOG protection
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve Phase 43 hand-written [1.3.0]/[1.4.0] narrative sections | Likely | PR #5 CHANGELOG format vs Phase 43 D-04 narrative backfill |

### Recovery fallback
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Use publish-hex.yml workflow_dispatch only if tag exists but publish failed; never local mix hex.publish | Confident | `.github/workflows/publish-hex.yml`; CLAUDE.md; 43-RESEARCH.md recovery path |

### Success verification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gate on hex.pm 1.4.0 + mix hex.info + CI publish-hex logs | Confident | ROADMAP Phase 44 success criteria |

### Diagnosis artifact
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Write RELEASE-PLEASE-DIAGNOSIS.md with root cause, fix, recurrence checklist | Confident | PUB-03 requirement; ROADMAP SC#1 |

## Corrections Made

No corrections — all assumptions confirmed by user (option 1: "Yes, proceed").

## External Research

- GitHub PR #5 inspected via `gh pr view 5` — confirms open 1.3.0 release PR with manifest/CHANGELOG/mix.exs diff.
- Hex index checked via `mix hex.info relyra` — latest release 1.2.0 (2026-05-25).
- Local git state: `main...origin/main [ahead 110]`.
