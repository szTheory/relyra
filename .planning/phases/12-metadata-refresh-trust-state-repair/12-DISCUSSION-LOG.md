# Phase 12: Metadata refresh trust-state repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 12-metadata-refresh-trust-state-repair
**Areas discussed:** Repair boundary, certificate input contract, trust-state behavior during repair, verification closure

---

## Repair boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Phase 12 narrow | Repair the certificate decode/normalization seam and re-verify `CFG-03` without reopening metadata architecture | ✓ |
| Broaden into metadata cleanup | Expand the phase into wider import/apply/refresh cleanup and contract reshaping | |

**User's choice:** Delegated to agent after parallel subagent research.
**Notes:** Chosen because current evidence points to a seam-contract repair rather than a broader redesign, and widening the phase would reopen stable Phase 09/10 boundaries unnecessarily.

---

## Certificate input contract

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical metadata boundary contract | Normalize metadata-derived certs once into one canonical internal shape before `MetadataApply` | ✓ |
| Tolerant staging contract | Keep certificate inventory staging tolerant of mixed internal certificate shapes | |

**User's choice:** Delegated to agent after parallel subagent research.
**Notes:** Chosen because it matches Ecto’s external-to-internal casting posture, reduces surprise, and avoids union-shaped internal contracts that drift across phases.

---

## Trust-state behavior during repair

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve staged trust semantics | Keep existing active signing certs active and stage metadata-introduced certs as `:next` until explicit lifecycle transitions occur | ✓ |
| Revisit trust semantics | Let successful metadata refresh broaden runtime trust or auto-promote new certificates | |

**User's choice:** Delegated to agent after parallel subagent research.
**Notes:** Chosen because refresh is a repair target here, not a trust-model redesign, and explicit lifecycle transitions remain the least-surprise operator model.

---

## Verification closure

| Option | Description | Selected |
|--------|-------------|----------|
| Green focused tests only | Stop once the immediate smoke failures are fixed | |
| Verification packet | Require focused smoke, full suite, manual validation sign-off, and `09-VERIFICATION.md` | ✓ |
| Expanded release-style proof | Add extra host-app or manual end-to-end walkthrough proof beyond phase closure needs | |

**User's choice:** Delegated to agent after parallel subagent research.
**Notes:** Chosen because the milestone audit requires actual requirement verification evidence, not just repaired tests, and the roadmap explicitly calls for a verification artifact.

---

## Additional preference captured

- Prefer recommendation-first GSD behavior by default, with explicit escalation only for unusually high-impact decisions the user is likely to care about directly.

## Deferred Ideas

- Broader project-wide GSD workflow preference changes to shift recommendation-first behavior further left.
- Any future metadata refresh redesign that changes trust-promotion semantics.

