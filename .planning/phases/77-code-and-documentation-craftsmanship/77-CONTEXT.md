# Phase 77: Code and Documentation Craftsmanship - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make production code, tests, and standalone product documentation clear to a fresh
maintainer or adopter while resolving the high-value quality findings recorded for
this milestone. Keep historical planning records intact, preserve the existing
security rationale and evidence, and retain only intentional tracked artifacts with
clear ownership. This phase is a bounded cleanup behind the Phase 74–76 adopter
evidence; it does not add product capabilities or change public APIs, defaults, or
security posture.

</domain>

<decisions>
## Implementation Decisions

### Craftsmanship Cleanup Boundary
- **D-01:** Use the Phase 73 quality baseline as the starting queue. Fix Phase 77-owned findings and small clarity problems directly connected to them; avoid broad stylistic rewrites or behavior changes.
- **D-02:** Revalidate each baseline finding against the current tracked tree and current evidence before changing code or documents. Close items that are already resolved with concrete evidence, and keep findings assigned to other phases with their existing owners.

### Timeless Source and Documentation
- **D-03:** Replace temporary phase, plan, decision-code, UAT-path, and GSD narration in production comments, tests, and adopter-facing guidance with timeless contracts or rationale. Keep historical records under `.planning/` intact.
- **D-04:** Keep maintainer and governance references only where they explain an active repository contract. Adopter guides should not carry repository-only workflow instructions. Refresh `docs/jtbd_gap_map.md` as a current maintainer reference rather than retaining its phase-by-phase history.
- **D-05:** Keep comments only when they explain a contract, intent, or non-obvious security rationale. Remove phase and decision-code labels while preserving the invariants they were documenting, especially around signature verification and metadata trust.

### Acceptance Policy and Archive Boundary
- **D-06:** Keep deterministic automated acceptance mandatory. Correct false positives by distinguishing active incomplete-phase requirements from quoted or archival examples; do not exempt all `.planning/` content or delete archived history to make the check pass.
- **D-07:** Preserve intentional GSD and policy vocabulary in governance code and tests that enforce those contracts. A broad text search is candidate discovery, not sufficient evidence that a reference is stale.

### Finding and Artifact Disposition
- **D-08:** Close Phase 77-owned `QUAL-73-002`, `QUAL-73-003`, and `QUAL-73-006` with concrete evidence. Revalidate and classify `QUAL-73-004` before addressing its reported golden-fixture warnings; do not weaken fixture coverage.
- **D-09:** Preserve the adversarial proof and configured-certificate trust path for the resolved critical signature finding. Carry forward closure evidence for findings already owned by Phases 74 and 79; do not absorb Phase 78/79 work into this phase. Follow the Phase 73 severity policy for any still-open critical or high finding.
- **D-10:** Audit tracked paths for this phase. Remove an artifact only when evidence shows it is obsolete or duplicate; every retained exceptional artifact needs a clear owner. Unrelated untracked working-tree state is outside this requirement.

### the agent's Discretion
- Choose the exact files and small refactors needed to resolve the in-scope findings, after confirming each is still present.
- Choose focused deterministic evidence and the appropriate existing mandatory lane for each change.
- Preserve useful examples, golden outputs, and governance contracts when they are still owned and exercised.
- Stop when the Phase 77 findings are dispositioned and remaining changes would be broad aesthetic cleanup rather than adopter-significant value.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope, requirements, and guardrails
- `.planning/ROADMAP.md` — Phase 77 boundary and success criteria.
- `.planning/REQUIREMENTS.md` — `QUAL-02` through `QUAL-06` acceptance requirements.
- `.planning/PROJECT.md` — v1.11 scope, immutable security invariants, and approval posture.
- `.planning/STATE.md` — Current milestone position and decisions accumulated through Phase 76.
- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — Severity rules, evidence, and Phase 77 finding ownership.
- `.planning/phases/76-lifecycle-and-recovery-journeys/76-CONTEXT.md` — Latest adopter journey, deterministic evidence, and canary ownership decisions.

### Current documentation and policy owners
- `test/docs/demo_guide_drift_test.exs` — Static documentation contracts and the incomplete-phase acceptance policy check.
- `docs/jtbd_gap_map.md` — Maintainer-only view of current adopter coverage and prioritization.
- `guides/getting_started.md` — Adopter onboarding guidance; currently includes repository-only maintainer workflow details.
- `mix.exs` — Existing `ci.docs` and `ci.security` lane definitions.
- `test/governance/milestone_scope_test.exs` — Existing ownership for tracked-artifact and milestone-scope policy.

### Security rationale and proof to preserve
- `lib/relyra/security/signature.ex` — Shared signature trust primitive and metadata-root verification contract; comments currently include historical Phase 21/D-code narration.
- `test/security/xml/adversarial_crypto_test.exs` — Permanent adversarial crypto corpus; never weaken it.
- `docs/advisories/2026-001-xmldsig-signature-not-verified.md` — Historical signature-bypass finding and its remediation context.
- `test/fixtures/demo_host/golden/config/relyra_snippet.exs` — A reported golden-fixture warning source; verify the current tracked warning inventory before making changes.

No external specification is required; the roadmap, requirements, project guardrails, and Phase 73 baseline define the work.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Docs.DemoGuideDriftTest` already owns static documentation checks and the incomplete-phase automation policy. Extend its existing contract rather than introducing a second checker.
- `mix ci.docs` is already a named test lane for documentation contracts; security-sensitive characterization belongs in the established `mix ci.security` lane.
- Existing golden fixtures and `test/security/xml/adversarial_crypto_test.exs` provide proof surfaces that cleanup must preserve.

### Established Patterns
- Security comments document trust sources and sequencing constraints. Keep the rationale in timeless language: metadata-root verification uses the shared trust primitive, occurs before deep candidate parsing, and relies on operator-pinned metadata trust fingerprints rather than assertion certificates.
- Relyra keeps historical phase artifacts under `.planning/`; adopter-facing docs describe current supported behavior, while governance tests may intentionally mention policy vocabulary.
- Repository quality findings are severity-ranked and tied to an owner, evidence, disposition, and revisit point. Phase 77 should update dispositions only after checking current evidence.

### Integration Points
- Documentation and incomplete-phase policy changes connect through `test/docs/demo_guide_drift_test.exs` and the existing `mix ci.docs` alias.
- Comment and naming cleanup in security-adjacent code must retain characterization and adversarial coverage through the existing security lane.
- Artifact disposition should use the current tracked-file inventory and the ownership policy in `test/governance/milestone_scope_test.exs`.

</code_context>

<specifics>
## Specific Ideas

In `lib/relyra/security/signature.ex`, the metadata-root documentation refers to Phase 21 and D-16/D-17. Replace those temporary labels with timeless explanations while retaining the required verify-before-deep-parse ordering and operator-pinned metadata-trust boundary. In `guides/getting_started.md`, repository-only planning-CI details should not be presented as adopter guidance. Preserve the archival phase record under `.planning/` and keep governance tests that enforce the actual policy.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 77 scope. Findings assigned to later phases remain with those owners.

</deferred>

---

*Phase: 77-code-and-documentation-craftsmanship*
*Context gathered: 2026-09-26*
