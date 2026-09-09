# Phase 73: Twin Contract and Baseline - Context

**Gathered:** 2026-09-09 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Define and enforce the executable adopter-evidence model, publish a truthful quality and CI
baseline, and make the milestone's approval and feature-neutrality guardrails fail closed.
Phase 73 records the before-state and repairs defects in its own evidence and governance
contracts; package-consumer work, twin realism, lifecycle journeys, broader cleanup, CI
optimization, and repository/GitHub remediation remain owned by Phases 74-79.

</domain>

<decisions>
## Implementation Decisions

### Evidence Ownership
- **D-01:** Use one closed, test-only ledger covering every active v1.11 requirement and all six adopter personas across the LedgerLoop and clean-room-consumer twins.
- **D-02:** Only an `:existing`, non-`:external_canary` row with a valid closed-schema evidence kind and an executable owner chain may close a requirement.
- **D-03:** The owner chain must resolve through a real selected test or check, a fresh-process Mix alias, and an enabled mandatory workflow step; source-text tokens, comments, inert selectors, disabled steps, non-blocking steps, and generic non-test Mix commands are not evidence.
- **D-04:** Planned rows and scheduled external canaries remain inspectable in the ledger but never satisfy deterministic closure.

### Baseline Boundary
- **D-05:** Preserve Phase 73's baseline as dated, redaction-safe before-state inventory with anchored tables, closed severity/disposition vocabularies, reproducible evidence, named ownership, target phase, approval class, blocker state, and revisit date.
- **D-06:** Treat one-run CI durations as samples rather than optimization evidence, and route remediation to Phases 74, 77, 78, or 79 according to the baseline owner.
- **D-07:** Repair failures in Phase 73's own ledger, baseline, governance, and mandatory-owner contracts during the Phase 73 replan; those defects are not downstream remediation.
- **D-08:** A baseline row's evidence must include a syntactically complete, machine-validated verification marker and allowed command or source reference; arbitrary non-empty prose is insufficient.

### Approval and Scope Governance
- **D-09:** A public-API, default-tightening, security-posture, real SemVer-major, or remote-GitHub mutation requires a matching plan-local blocking `approval_class` checkpoint before the first mutation task; approval cannot be borrowed from another plan or branch.
- **D-10:** Governance must infer risky work from structured task content and affected surfaces, not trust self-reported scope declarations or substring/keyword proximity.
- **D-11:** A remote-GitHub checkpoint must authorize one exact reversible batch with concrete current and desired state, commands, affected checks, automated preflight, rollback, postcondition read-back, and resume signal targeting the same remote state.
- **D-12:** Authorization and acceptance remain separate: a checkpoint can authorize a mutation but only deterministic automated evidence can close an acceptance criterion.
- **D-13:** `AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`, and unrelated product expansion remain excluded. Demand-gated identifiers in implementation regions fail regardless of nearby negation prose.

### the agent's Discretion
- Choose the internal helper boundaries and fixture organization used to make the existing test-only contracts semantic and fail closed.
- Add the smallest adversarial controls needed to prove each repaired boundary, while preserving the existing literal-ledger and fresh-process-lane architecture.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 73 goal, requirements, success criteria, downstream phase ownership, and milestone guardrails.
- `.planning/REQUIREMENTS.md` — EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, and GOV-02 acceptance boundaries.
- `.planning/PROJECT.md` — v1.11 twin model, immutable security posture, demand-gated protocol exclusions, approval policy, and deterministic-evidence requirement.
- `prompts/RELYRA-GSD-IDEA.md` — Original project and milestone intent referenced by PROJECT.md.

### Current Phase 73 truth
- `.planning/phases/73-twin-contract-and-baseline/73-VERIFICATION.md` — Goal-backward verification, direct fail-open probes, and the exact gaps the replan must close.
- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — Dated findings ledger, CI snapshot, disposition rules, remote mutation boundary, and security/compliance breadcrumbs.
- `.planning/phases/73-twin-contract-and-baseline/73-RESEARCH.md` — Phase-specific implementation research and constraints.

### Non-negotiable repository policy
- `CLAUDE.md` — Project-wide security invariants, architecture seams, CI requirements, approval boundaries, and commit policy (`AGENTS.md` and `GEMINI.md` are symlinks to this file).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/adoption_evidence.ex` — Literal v1.11 evidence registry plus schema, closure, and repository-owner validation seams; retain it as the single ledger rather than introducing a second representation.
- `test/adoption/evidence_contract_test.exs` — Positive tracer, fail-closed ledger controls, Mix alias AST inspection, workflow wiring checks, and isolated repository fixtures.
- `test/governance/milestone_scope_test.exs` — Anchored baseline parser, plan-scope and approval validators, requirement ownership checks, automation policy checks, and synthetic malformed controls.
- `mix.exs` — Existing one-step, fresh-process `ci.evidence` alias owning both Phase 73 contract files.
- `.github/workflows/security-gates.yml` — Existing planning-aware mandatory security job and Evidence contract step.

### Established Patterns
- Closed vocabularies and exact table/row schemas fail closed; unknown states, fields, requirements, personas, severities, and dispositions are rejected with row-level diagnostics.
- Evidence is accepted only through an end-to-end executable chain, not by structure or naming alone.
- Negative fixtures mutate one contract property at a time and must demonstrate that hollow evidence, contradictory declarations, and placeholder policy text fail.
- Security suites retain independent fresh processes; Phase 73 introduces no runtime SAML, parser, crypto, replay, audit, public-API, or package-surface change.

### Integration Points
- Completed requirements in `.planning/REQUIREMENTS.md` are cross-checked against deterministic owners in `Relyra.AdoptionEvidence`.
- The `ci.evidence` alias connects the two focused ExUnit contracts to the required security workflow.
- Governance validation reads `.planning/ROADMAP.md`, active `*-PLAN.md` files, and `73-BASELINE.md`; the replan must harden those existing seams rather than bypass them.
- `73-VERIFICATION.md` supplies the adversarial probes that distinguish currently green happy-path checks from goal-complete fail-closed behavior.

</code_context>

<specifics>
## Specific Ideas

- The user delegated unresolved implementation detail to the agent and explicitly asked it to follow the recommendations automatically.
- Keep the result small and decisive: harden the current contracts instead of adding another ledger, parser, governance format, or CI lane.

</specifics>

<deferred>
## Deferred Ideas

- Clean-room packaged consumer implementation — Phase 74.
- LedgerLoop SaaS domain and fixture realism — Phase 75.
- Login, rejection, replay, isolation, trust-change, diagnosis, and recovery journeys — Phase 76.
- Broader code/documentation cleanup, including archival vocabulary-policy drift — Phase 77.
- Measured CI optimization and lane ownership refinement — Phase 78.
- Live required-check repair and other approved remote GitHub/repository hygiene — Phase 79.
- `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` — demand-gated future work only.

No todos matched Phase 73 for folding into scope.

</deferred>

---

*Phase: 73-twin-contract-and-baseline*
*Context gathered: 2026-09-09*
