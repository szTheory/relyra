# Security Findings Ledger

Current state: no external findings recorded yet.

## Summary

- High and Critical findings are release blockers until remediated and regression-tested.
- Medium findings require an explicit written disposition before release.
- Low and Informational findings may be deferred only if they remain recorded with owner and revisit date.
- Every accepted fix should link the regression proof that keeps it closed.

## Findings Ledger

| Finding ID | Severity | Exploit Path | Disposition | Owner | Regression Proof | Blocker State | Revisit Date |
| --- | --- | --- | --- | --- | --- | --- | --- |
| none yet | Informational | no external findings recorded yet | awaiting review | maintainers | add test, corpus fixture, or generated artifact link when a finding lands | non-blocking | next external review |

## Disposition Workflow

### High and Critical

- Treat High and Critical findings as release blockers.
- Do not close the finding until the fix lands, the regression proof is linked, and the reviewer packet reflects the new state.
- Record the blocker in this ledger even if the fix ships in the same phase.

### Medium

- Medium findings require explicit written disposition before release.
- Either fix in the current phase or defer with rationale, compensating controls, owner, and revisit date.
- A Medium finding without an owner or revisit date is not considered dispositioned.

### Low and Informational

- Low and Informational findings must still be recorded.
- Deferred items require scope notes, an owner, and a revisit date so the repo does not silently forget them.

## Regression Requirements

- Link every remediated finding to a regression test, corpus fixture, or generated artifact check.
- Preferred proof targets are `SECURITY_REVIEW_EVIDENCE.md`, `CONFORMANCE.md`, focused ExUnit files, or the repo security CI lane.
- When a finding changes a trust-boundary contract, update [`SECURITY_REVIEW.md`](../SECURITY_REVIEW.md) so reviewers can follow the new proof path.
