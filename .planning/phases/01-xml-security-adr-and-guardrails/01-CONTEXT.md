# Phase 1: XML Security ADR and Guardrails - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Decide and lock the XML security implementation strategy with an explicit seam and acceptance bar before protocol code lands. This phase delivers the ADR and guardrails only; protocol implementation follows in Phase 2.

</domain>

<decisions>
## Implementation Decisions

### XML Strategy Decision
- **D-01:** Default to a pure-BEAM, single-parser XML strategy for v0.1 behind a frozen seam (`Relyra.Security.XML`), prioritizing Elixir-native operability and least surprise for adopters.
- **D-02:** If Phase 1 acceptance gates fail on canonicalization/signed-node correctness, switch before release to a hybrid/xmlsec verification path while preserving the same seam API.
- **D-03:** Enforce one parser trust path project-wide (no mixed parser usage for trust decisions) with compile-time and CI guardrails.

### Security XML Seam Contract
- **D-04:** Freeze a staged opaque seam contract with callbacks `parse_safely/2`, `select_signed_node/2`, and `canonicalize/2`.
- **D-05:** `select_signed_node/2` returns a typed signed-node handle that must be used by downstream validators; downstream code must not consume raw XML outside this trust path.
- **D-06:** Seam callbacks return typed `%Relyra.Error{}` failures with stable atoms and actionable details.

### Acceptance Bar and Phase Gate
- **D-07:** Adopt a balanced strict Phase 1 gate (security-first without Phase 6-level hardening overhead).
- **D-08:** Require a blocking adversarial corpus with at least 36 fixtures across XXE/entity abuse, decompression bounds, signature wrapping, parser differential/canonicalization ambiguity, duplicate XML IDs, KeyInfo misuse, and unsigned/partial signature classes.
- **D-09:** Phase 1 cannot close until `qa`, `ci.fast`, `ci.security`, and `ci.integration` pass on OTP 27 and OTP 28 with deterministic typed rejection behavior.

### NIF Supply-Chain Policy (Conditional)
- **D-10:** If NIF/hybrid is selected, apply a standard supply-chain policy: explicit target matrix, committed checksum manifest, matrix build + smoke tests, checksum verification before publish, and post-publish parity checks.
- **D-11:** Default precompiled matrix (if NIF path): Linux GNU (`x86_64`, `aarch64`), Linux musl (`x86_64`), macOS (`aarch64`, `x86_64`); Windows is source-build best effort unless adoption pressure justifies precompiled artifacts.
- **D-12:** Escalate to signed artifacts/provenance attestations only when NIF verification becomes the default production trust path for most installs.

### Decision Autonomy Preference
- **D-13:** For this phase, default to recommendation-driven decisions from deep research without requiring user choice per sub-question.
- **D-14:** Escalate only architectural/security-critical or scope-changing decisions to explicit user confirmation; all other implementation details stay within Claude discretion.

### Claude's Discretion
- Exact parser selection between `saxy` and `simple_xml` within the single-parser pure-BEAM strategy, as long as fixed invariants and gates are honored.
- Exact fixture naming and internal test-module partitioning beyond required fixture classes and minimum counts.
- CI job naming and YAML layout details that preserve the gate contract.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked requirements
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and plan boundaries.
- `.planning/REQUIREMENTS.md` — `SEC-01`, `GATE-01`, `GATE-02`, `GATE-03` requirements tied to this phase.
- `.planning/PROJECT.md` — strict-by-default trust model, non-goals, and adoption constraints.

### Architecture and implementation guidance
- `.planning/research/ARCHITECTURE.md` — module boundaries, seam placement, validation order, and integration path.
- `.planning/research/STACK.md` — XML strategy options, dependency posture, and release/ops constraints.
- `.planning/research/SUMMARY.md` — synthesized rationale for phase ordering and unresolved XML ADR gate.

### Security lessons and regression classes
- `.planning/research/PITFALLS.md` — CVE-derived failure modes, fixture classes, and CI gate discipline.
- `prompts/elixir-saml-lib-deep-research.md` — ecosystem and SAML security analysis inputs.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — proven patterns for optional deps, CI discipline, and OSS ergonomics.

### Product and UX alignment
- `prompts/relyra-brand-book.md` — operator-facing language and trust-oriented UX constraints.
- `prompts/RELYRA-GSD-IDEA.md` — original product direction and non-goal boundaries.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/research/ARCHITECTURE.md`: pre-defined `Relyra.Security.XML` seam direction and boundary model suitable for Phase 1 scaffolding.
- `.planning/research/STACK.md`: dependency/pinning strategy and XML-path alternatives with ops implications.
- `.planning/research/PITFALLS.md`: concrete adversarial fixture taxonomy and custom static-check concepts that can be translated directly into tests/checks.

### Established Patterns
- Behaviour-first seams with typed tuple contracts and explicit error atoms.
- Strict defaults with explicit, audited escape hatches instead of permissive defaults.
- CI-as-spec workflow where security fixtures are permanent regression contracts.

### Integration Points
- Phase 2 protocol core depends on this phase freezing the XML seam and trust invariants.
- Phase 3 store/behaviour contracts rely on stable typed error semantics set here.
- Phase 6 release hardening depends on the fixture corpus and supply-chain discipline defined here.

</code_context>

<specifics>
## Specific Ideas

- User preference: provide one-shot, coherent, deeply researched recommendations with minimal decision burden.
- Design principle emphasis: least surprise, strong software architecture, and high developer ergonomics.
- Cross-ecosystem lessons should be applied proactively, not only after regressions.

</specifics>

<deferred>
## Deferred Ideas

- Project-level GSD preference tuning to make recommendation-first/low-friction decision handling the default across future phases (except very high-impact choices).

</deferred>

---

*Phase: 01-xml-security-adr-and-guardrails*
*Context gathered: 2026-04-24*
