# Phase 77: Code and Documentation Craftsmanship - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `77-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 77-code-and-documentation-craftsmanship
**Areas discussed:** Craftsmanship cleanup boundary, Timeless source and documentation, Acceptance-policy archive boundary, Finding and artifact disposition

---

## Craftsmanship cleanup boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Focused baseline remediation and directly related clarity work | Resolve Phase 77-owned findings and adjacent clarity issues without broad rewrites. (recommended) | ✓ |
| Broad repository-wide rewrite | Apply a larger style and abstraction pass across the repository. | |
| Documentation-only cleanup | Limit the phase to prose and leave code/test findings unresolved. | |

**Auto selection (--auto):** Focused baseline remediation and directly related clarity work.
**Notes:** Revalidate baseline findings against current tracked files and evidence before changing them.

---

## Timeless source and documentation

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite current source and adopter prose; preserve archives and explicit governance contracts | Replace temporary narration with timeless rationale, preserve `.planning/` history, and keep active policy references in governance-owned code/docs. (recommended) | ✓ |
| Remove every GSD or phase reference from the repository | Delete even active governance terms, policy fixtures, and archival history. | |
| Keep current references unless they break compilation | Leave stale planning narration in source and adopter docs. | |

**Auto selection (--auto):** Rewrite current source and adopter prose; preserve archives and explicit governance contracts.
**Notes:** Adopter guides should not contain repository-only planning workflow instructions; update the JTBD map as a current maintainer reference.

---

## Acceptance-policy archive boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Make the check context-aware and keep the automation gate strict | Distinguish active incomplete-phase requirements from quoted/archival examples without exempting all planning files. (recommended) | ✓ |
| Exempt every `.planning/` file from the check | Broadly bypass policy validation for planning content. | |
| Delete historical examples and UAT artifacts | Remove the archive content that creates false positives. | |

**Auto selection (--auto):** Make the check context-aware and keep the automation gate strict.
**Notes:** Do not introduce manual completion gates or weaken deterministic acceptance requirements.

---

## Finding and artifact disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Close Phase 77-owned findings and honor existing cross-phase ownership | Resolve the scoped findings with evidence, preserve critical security proof, and keep later-phase findings with their current owners. (recommended) | ✓ |
| Pull every open baseline item into Phase 77 | Expand scope to CI and repository closeout items owned by later phases. | |
| Delete every flagged or unusual file regardless of ownership | Remove artifacts without verifying whether they are still required or owned. | |

**Auto selection (--auto):** Close Phase 77-owned findings and honor existing cross-phase ownership.
**Notes:** Audit tracked files and give retained exceptional artifacts a clear owner; untracked working-tree state is outside this phase requirement.

---

## the agent's Discretion

- Select exact files and small refactors after confirming baseline findings still apply.
- Choose focused deterministic evidence in existing CI lanes.
- Preserve active governance contracts, useful fixtures, and security proof.
- Stop at the Phase 77 diminishing-returns boundary.

## Deferred Ideas

None. Findings owned by other phases remain with those owners.
