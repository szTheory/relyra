# Phase 43: Hex publish prep — version bump & CHANGELOG backfill - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 43-hex-publish-prep-version-bump-changelog-backfill
**Mode:** assumptions
**Areas analyzed:** Version bump, Install pin scope, CHANGELOG backfill style, Commit packaging, Git tag boundary, Tests & CHANGELOG structure

---

## Assumptions Presented

### Version & release-please manifest
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Bump `mix.exs` and `.release-please-manifest.json` to `1.4.0` together | Confident | `mix.exs:6`, `.release-please-manifest.json` both `1.2.0` |

### Install pin scope
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Only `guides/getting_started.md:26` → `~> 1.4` | Confident | ROADMAP SC #1; grep shows no other relyra `~> 0.1.0` pins |

### CHANGELOG backfill style
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Hand-written milestone summaries, not release-please commit dump | Confident | ROADMAP PUB-02; gap never merged |
| `[1.3.0]` = v1.3 federation; `[1.4.0]` = v1.4 SLO/docs + phases 41–42 | Likely | Milestone roadmaps, v1.5 sequencing |
| Jump rationale at top of `[1.4.0]` | Confident | STATE.md, REQUIREMENTS.md out-of-scope table |

### Commit packaging
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Single release-prep commit for version + manifest + pin + CHANGELOG | Confident | ROADMAP SC #1 co-location |

### Git tag boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| No `v1.4.0` tag in Phase 43 | Confident | Phase 43 SCs omit tag; Phase 44 owns tag + publish |

### Tests & CHANGELOG structure
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| No literal `1.2.0` test assertions to update | Confident | grep across repo |
| Keep `[Unreleased]`; insert new sections above `[1.2.0]` | Likely | `CHANGELOG.md:235`, `release_hardening_test.exs` |

## Corrections Made

No corrections — all assumptions confirmed (user selected "Yes, proceed").

## External Research

None required — codebase and planning artifacts sufficient.
