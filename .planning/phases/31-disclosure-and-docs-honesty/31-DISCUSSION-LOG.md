# Phase 31: Disclosure and docs honesty - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 31-disclosure-and-docs-honesty
**Mode:** assumptions
**Areas analyzed:** Doc-correction framing, Findings-ledger entry, Advisory artifact (GHSA/CVE/CHANGELOG), ci.security doc-gate compatibility

## Assumptions Presented

### Doc-correction framing (DISC-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Correct the 3 named docs to precisely state the now-real crypto guarantee (`:public_key.verify` over canonicalized `SignedInfo` vs configured cert + constant-time `DigestValue` recompute, both assertion + metadata paths), not vague "signature verification" | Confident | `docs/security_boundary.md:8`, `SECURITY_REVIEW_EVIDENCE.md:21`, PROJECT.md "Why now", SIGV-01..04 verified |
| Honesty is forward-looking; historical gap in shipped 1.0.0/1.1.0 captured once in the ledger, not scattered as caveats | Confident | findings-ledger design (`security_findings.md:20-41`) |
| `SECURITY.md` left as-is (its "verified against configured certs" line is now true post-fix) | Likely | `SECURITY.md:18`; DISC-01 names only 3 files |

### Findings-ledger entry (DISC-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Replace `none yet` placeholder with one Critical row (forged-sig/NameID bypass; disposition Confirmed→Fixed v1.1/hex 1.2.0; regression proof = adversarial corpus + ci.security) | Likely | `docs/security_findings.md:14-24`, audit "full auth bypass", ASSUR-01 corpus |
| Severity = Critical (not High) | Likely | full auth bypass on trust boundary |

### Advisory artifact: GHSA + CVE + CHANGELOG (DISC-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Stage one checked-in draft at `docs/advisories/2026-001-xmldsig-signature-not-verified.md` (GHSA body + CVE request + CHANGELOG note text) | Likely | no existing advisory scaffolding (`find` under .github/docs); REQUIREMENTS fix-first |
| Do not hand-edit release-please-generated `CHANGELOG.md`; keep note text in draft + rely on commit footer | Likely | `mix.exs`/release-please workflow own CHANGELOG |
| No premature publication — no `gh` file/request/publish in this phase | Confident | REQUIREMENTS DISC-02 "not published before the fix ships"; embargo memory |

### ci.security doc-gate compatibility (DISC-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve file-existence + findings-ledger cross-ref grep so `ci.security` doc checks stay green | Confident | `mix.exs` ci.security alias steps 155-158 |
| Do not hand-edit generated `SECURITY_REVIEW_EVIDENCE.md`; change via the generator task if needed | Confident | `SECURITY_REVIEW_EVIDENCE.md:3` "Generated…"; `relyra.security_review --check` |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## External Research

None — codebase + project docs were sufficient; `needs_research` empty.
