# Phase 26: Security Audit Preparation and Remediation - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Ready the Relyra codebase and documentation for a third-party security review, then remediate and verify the review's findings. This phase delivers a reviewer-friendly audit packet, finalized security-boundary documentation, executable proof for strict defaults and escape hatches, and a remediation policy that closes high-severity findings before v1.0 release.

This phase does not deliver broad adopter onboarding polish, case-study authoring, or a product-style documentation portal. Those belong to Phase 27 or later follow-up work.

</domain>

<decisions>
## Implementation Decisions

### Auditor artifact package
- **D-01:** Phase 26 should produce a compact, repo-native audit packet rather than a README-only rewrite, a separate docs site, or a code-only handoff.
- **D-02:** The audit packet should be one canonical reviewer entry point that links to security boundary docs, conformance evidence, strict-default and escape-hatch proof, canonical code seams, and exact rerun commands.
- **D-03:** Auditor-facing material should live in-repo and stay diffable alongside the code and tests it describes. Avoid introducing a second truth surface for security claims.
- **D-04:** README changes in this phase should stay targeted to pointing reviewers and adopters at the right canonical security docs, not expand into general onboarding polish.

### Remediation policy
- **D-05:** All High and Critical external-audit findings block v1.0 until remediated, regression-tested, and captured in verification artifacts.
- **D-06:** Medium findings require explicit disposition before release: either fix in Phase 26 or defer with written rationale, compensating controls, owner, and revisit phase/date.
- **D-07:** Low and Informational findings may defer only if they are still recorded in a findings ledger with scope, rationale, and follow-up ownership.
- **D-08:** Severity handling must bias toward exploitability at the SAML trust boundary rather than cosmetic or style-oriented audit commentary.
- **D-09:** Every accepted security bug fixed in Phase 26 should become permanent regression coverage where practical, following the same corpus-minded discipline established in Phase 25.

### Proof style for strict defaults and escape hatches
- **D-10:** Proof should use a mixed bundle with an executable core: concise reviewer docs plus rerunnable ExUnit evidence and generated artifacts.
- **D-11:** Executable evidence remains primary. Narrative docs should map invariants to seams and tests, not replace proof with prose.
- **D-12:** Strict-default evidence must explicitly show fail-closed behavior for unsafe algorithms, signed-content trust rules, replay/trust boundaries, and other relevant rejection paths.
- **D-13:** Escape-hatch evidence must explicitly show that risky compatibility or bypass paths are time-boxed or constrained, attributable, correlated, and redaction-safe in the audit trail.
- **D-14:** Reviewer artifacts for Phase 26 should mirror the successful Phase 25 pattern: generated evidence derived from executable state, not hand-maintained status prose.

### External review target surface
- **D-15:** The external review should be trust-boundary-first: XML parsing, signed-node selection, signature trust, protocol validation, RelayState handling, request/replay protection, metadata trust anchors and refresh, certificate lifecycle, SLO, audit/redaction guarantees, and library-owned Phoenix/admin seams.
- **D-16:** The library-owned Phoenix surface is in scope only where Relyra defines the contract: routes/controllers, LiveView mount boundaries, admin risk/override surfacing, and other library-owned trust seams.
- **D-17:** Host-application-specific authn/authz, custom `ScopeProvider` logic, app router policy beyond Relyra's contract, and generic admin UX polish are out of scope for the third-party review and must be called out as assumptions.
- **D-18:** The scope must be narrow enough to preserve audit depth on real exploit paths, but broad enough to include the operational trust boundary beyond the original protocol core.

### DX and reviewer ergonomics
- **D-19:** Reviewer UX should optimize for least surprise: one entry doc, one rerun path, one map from claim to seam to test to artifact.
- **D-20:** Planning and execution for this phase should remain recommendation-first and low-friction. Low-risk shape decisions should be auto-resolved by downstream agents; escalate only unusually impactful product, security, or architecture choices.

### the agent's Discretion
- Exact naming and file layout of the audit packet, provided there is one canonical reviewer entry point and no duplicate truth surfaces.
- Exact generated artifact format for strict-default and bypass evidence, provided it is executable-state-derived and easy for auditors to rerun.
- Exact severity rubric phrasing, provided it remains exploitability-first and consistent with the locked remediation policy.
- Exact split between tests, generated docs, and concise seam docs, provided executable proof remains primary.

</decisions>

<specifics>
## Specific Ideas

- The ideal reviewer experience is closer to an OSS security packet than a product brochure: open one file, understand scope and assumptions fast, run a small set of commands, inspect the named seams, and see generated evidence.
- Phase 25's `CONFORMANCE.md` is the right precedent for Phase 26: generated, executable, and tied to manifest/test truth rather than manually curated narrative.
- Strong external examples point in the same direction: successful security-sensitive OSS projects tend to pair root security docs with rerunnable proofs and concise architecture boundaries, rather than hiding the story in a giant README or a separate portal.
- The user preference for this and future similar phases is one-shot, deeply researched, recommendation-first decision handling. Downstream planning and execution should pick coherent defaults automatically except for genuinely high-impact choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone anchors
- `.planning/ROADMAP.md` — Phase 26 goal, success criteria, and v1.0 ordering.
- `.planning/milestones/v1.0-REQUIREMENTS.md` — `SEC-REVIEW-01` requirement anchor.
- `.planning/PROJECT.md` — strict-default philosophy, trust-boundary definition, brand posture, and v1.0 milestone intent.
- `.planning/STATE.md` — current project state after Phase 25 completion.
- `.planning/milestones/v1.0-CONTEXT.md` — milestone-level context and Phase 25 precedent for executable evidence.

### Prior decisions and precedents
- `.planning/phases/25-conformance-and-cve-regression-fixtures/25-CONTEXT.md` — executable-evidence and generated-doc precedent for v1.0 security work.
- `.planning/phases/15-admin-shell-connection-lifecycle/15-CONTEXT.md` — locked recommendation-first posture and admin-side risk-surfacing principles.
- `.planning/RETROSPECTIVE.md` — closure-phase pattern, audit-gap lessons, and strict-by-default automation lessons.

### Auditor-facing docs
- `SECURITY.md` — threat model, non-negotiables, supported algorithms, and disclosure policy.
- `CONFORMANCE.md` — executable conformance and CVE-regression evidence.
- `README.md` — current adopter and operations entry point that Phase 26 may tighten without turning into a general polish phase.

### Expected code and evidence seams
- `lib/relyra/security/algorithm_policy.ex` — strict-default SHA-256+/legacy SHA-1 escape-hatch behavior.
- `lib/relyra/ecto/audit_writer.ex` — redaction-safe, attributable audit-writer seam.
- `lib/relyra/metadata/auto_refresh.ex` — typed bypass/suspension behavior and metadata trust-boundary enforcement.
- `lib/relyra/live_admin/query.ex` — reviewer-visible risk/bypass surfacing in the optional admin surface.
- `lib/relyra/security/` — XML, signature, and trust-boundary code.
- `lib/relyra/protocol/` — protocol validation and SAML surface behavior.
- `lib/relyra/metadata/` — metadata import/refresh/trust-anchor behavior.
- `lib/relyra/phoenix/`, `lib/relyra/live_admin/` — library-owned Phoenix ingress/admin boundary seams.
- `test/security/signature_policy_test.exs` — existing strict-default algorithm-policy tests.
- `test/relyra/ecto/audit_hardening_test.exs` — existing audit hardening and redaction proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CONFORMANCE.md` already proves the repo can generate reviewer-facing evidence from executable state.
- `Relyra.Ecto.AuditWriter` already centralizes redaction and bounded audit payload normalization.
- `Relyra.Security.AlgorithmPolicy` already encodes strict-default algorithm behavior and explicit legacy override expiry.
- `Relyra.Metadata.AutoRefresh` already models typed bypass/suspension paths in a way that can be documented and tested as security-sensitive escape hatches.
- `Relyra.LiveAdmin.Query` already normalizes risky override language into operator-facing risk flags, which is useful both for reviewer clarity and proof of explainability.

### Established Patterns
- Security claims are strongest in this repo when they are backed by rerunnable tests plus generated artifacts, not hand-written assertions.
- Risky compatibility behavior is acceptable only as an explicit, audited, constrained exception.
- Trust mutations and operator-intent events are expected to be attributable and redaction-safe by default.
- Phase closure in this repo favors narrow, honest packets over broad, vague milestone cleanup.

### Integration Points
- Phase 26 should build on Phase 25's evidence-generation pattern rather than invent a parallel security-documentation style.
- The audit packet should connect `SECURITY.md`, `CONFORMANCE.md`, targeted strict-default/escape-hatch evidence, and findings/remediation artifacts into one reviewer flow.
- Any remediation work should plug back into the existing corpus/test/verification discipline so future regressions stay visible.

</code_context>

<deferred>
## Deferred Ideas

- Broad adopter-onboarding polish, case studies, and README expansion beyond what the auditor packet needs — Phase 27.
- Separate docs-site or enterprise-portal style presentation layer for security review material.
- Full adopter-application security review guidance beyond Relyra's own library-owned trust boundary.
- Project-level GSD preference tuning to make recommendation-first, agent-resolved decision handling even more automatic across future workflows; desirable, but not Phase 26 delivery scope.

</deferred>

---

*Phase: 26-security-audit-preparation-and-remediation*
*Context gathered: 2026-05-08*
