# Phase 12: Metadata refresh trust-state repair - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the failing Phase 09 metadata import/refresh apply path so valid metadata can be normalized, persisted, and verified without destabilizing the Phase 10 certificate lifecycle model. This phase is a repair and re-verification phase for `CFG-03`, not a redesign of metadata semantics, refresh semantics, or certificate rollover behavior.

</domain>

<decisions>
## Implementation Decisions

### Repair boundary
- **D-01:** Keep Phase 12 narrowly scoped to the certificate decode/normalization seam plus verification closure for `CFG-03`.
- **D-02:** Do not broaden Phase 12 into general metadata import/apply/refresh cleanup unless new evidence shows valid-input failures outside the current certificate seam.
- **D-03:** Preserve the existing Phase 09 write-path shape: parse/normalize first, then one transactional apply path for persistence and trust-state mutation.

### Certificate input contract
- **D-04:** Normalize metadata-derived certificates into one canonical internal shape at the metadata boundary before `MetadataApply`.
- **D-05:** Treat `%Relyra.Metadata.Candidate{}` as already-normalized internal data, not as a second external-input layer with mixed certificate representations.
- **D-06:** Keep any tolerance for raw body/base64 input at the parser/import edge only; certificate inventory staging should consume one accepted internal certificate shape.
- **D-07:** Prefer one authoritative certificate collection carrying PEM plus derived facts such as fingerprint and validity windows, rather than parallel loosely coupled arrays that can drift.

### Trust-state behavior during repair
- **D-08:** Preserve the current trust-state rule exactly: metadata apply updates metadata pointers and stages metadata-introduced signing certificates as `:next` while keeping existing active signing certificates active.
- **D-09:** Do not make successful metadata refresh or import implicitly promote newly discovered certificates into runtime trust in Phase 12.
- **D-10:** Leave certificate promotion, retirement, and rollback under the explicit certificate inventory lifecycle commands introduced by Phase 10.

### Verification closure
- **D-11:** Phase 12 is not complete when the regression is merely fixed; it is complete only when `CFG-03` has focused smoke evidence and a verification artifact.
- **D-12:** The minimum verification packet is:
  - the focused Phase 09 smoke command from `09-VALIDATION.md` passing,
  - one full `mix test --warnings-as-errors` run passing,
  - the two manual validation checks in `09-VALIDATION.md` signed off in prose,
  - and a new `09-VERIFICATION.md` tracing those results back to `CFG-03`.
- **D-13:** Verification should be run serially, not via parallel migration-bootstrapping test commands, because the audit already identified schema migration races as a false-failure footgun.

### Developer-experience posture
- **D-14:** Favor recommendation-first planning and execution defaults for this phase and similar repair phases: escalate only unusually high-impact product, security, or architecture choices to the user.

### the agent's Discretion
- Exact internal struct/module shape used to represent normalized metadata certificates, as long as the candidate-to-apply boundary accepts one canonical internal certificate representation.
- Exact helper/module factoring between metadata import, candidate normalization, and certificate fact extraction.
- Exact fixture strategy for replacing synthetic invalid refresh certificates with valid X.509 material versus adding explicit invalid-input regression cases, as long as valid-input smoke paths and invalid-input typed rejection paths are both covered.

</decisions>

<specifics>
## Specific Ideas

- Keep the Elixir/Ecto shape unsurprising: external metadata input gets normalized once, then persistence code works with typed internal data only.
- Preserve the trust story Relyra has already taught operators: refresh is explicit, reversible, and non-destructive to active trust until an explicit lifecycle transition occurs.
- Recommendation-first working style is preferred: use coherent one-shot defaults by default, and only escalate decisions that materially alter project direction or the security contract.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and verification anchors
- `.planning/ROADMAP.md` — Phase 12 goal, gap-closure note, and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-03` requirement anchor.
- `.planning/PROJECT.md` — strict defaults, explainable trust changes, operator-safe runtime posture, and milestone boundaries.
- `.planning/v0.2-MILESTONE-AUDIT.md` — the concrete failing evidence, orphaned verification status, and the serial-test footgun note.
- `.planning/phases/09-metadata-import-export-refresh/09-VALIDATION.md` — focused smoke command, manual validation checks, and required verification bar.

### Locked prior decisions
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` — canonical runtime `idp_certificates` contract and normalized snapshot posture.
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` — explicit refresh semantics, last-known-good posture, and provenance boundaries.
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` — staged certificate lifecycle semantics and active-only runtime trust window.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` — audit posture for trust-bearing mutations.

### Existing code and test seams
- `lib/relyra/metadata/import.ex` — metadata candidate construction and current certificate normalization edge.
- `lib/relyra/metadata/candidate.ex` — current internal metadata candidate shape.
- `lib/relyra/metadata/refresh.ex` — explicit remote refresh path and failure recording flow.
- `lib/relyra/ecto/metadata_apply.ex` — transactional metadata apply boundary and audit insertion path.
- `lib/relyra/ecto/certificate_inventory.ex` — staged certificate persistence and lifecycle transition surface.
- `lib/relyra/ecto/certificate_facts.ex` — PEM decode and validity extraction rules that currently fail on invalid fixture material.
- `lib/relyra/ecto/connection_snapshot.ex` — active-only runtime certificate hydration contract.
- `test/relyra/metadata_test.exs` — metadata import and candidate normalization coverage.
- `test/relyra/metadata_refresh_test.exs` — explicit refresh smoke coverage and current failing fixture path.
- `test/relyra/ecto/metadata_apply_test.exs` — transactional apply, rollback, and staged trust-state assertions.
- `test/relyra/ecto/certificate_inventory_expiry_test.exs` — certificate fact extraction and typed invalid-PEM rejection coverage.

### Research and architecture guidance
- `.planning/research/ARCHITECTURE.md` — explicit metadata write-path layering and anti-pattern guidance.
- `.planning/research/PITFALLS.md` — blind refresh, replace-in-place trust changes, and metadata trust footguns.
- `.planning/research/SUMMARY.md` — v0.2 sequencing rationale and controlled refresh posture.
- `prompts/elixir-saml-lib-deep-research.md` — ecosystem and security lessons for metadata handling, refresh, and trust anchors.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — recommendation-first DX posture and strong boundary discipline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Metadata.Import.build_candidate/1`: already converts parsed metadata into PEM-backed candidate fields and is the natural place to harden the canonical internal certificate contract.
- `Relyra.Ecto.MetadataApply.apply_revision/4`: already owns the single transactional apply path and should remain the authoritative trust-state mutation seam.
- `Relyra.Ecto.CertificateFacts.extract/1`: already provides the strict typed decode/validity contract for X.509 material and should stay fail-closed.

### Established Patterns
- Parse/normalize first, then transact once through an Ecto context boundary.
- Keep runtime hydration pure and derived only from persisted applied state.
- Use typed `%Relyra.Error{}` failures instead of implicit coercion or late fallback behavior.

### Integration Points
- Metadata import and refresh both flow into the same candidate -> apply -> certificate inventory path, so Phase 12 should fix that shared seam once.
- Certificate lifecycle semantics from Phase 10 and audit semantics from Phase 11 must remain intact while the metadata seam is repaired.
- Verification closure must produce the missing `09-VERIFICATION.md` so milestone traceability can mark `CFG-03` satisfied.

</code_context>

<deferred>
## Deferred Ideas

- Broader metadata import/apply/refresh cleanup or API renaming beyond the current certificate seam.
- Any redesign where metadata refresh auto-promotes newly discovered certificates into live runtime trust.
- Project-wide GSD preference changes to make recommendation-first behavior the default in more workflows; this is desirable, but it is a workflow/tooling concern rather than Phase 12 delivery scope.

</deferred>

---

*Phase: 12-metadata-refresh-trust-state-repair*
*Context gathered: 2026-05-05*
