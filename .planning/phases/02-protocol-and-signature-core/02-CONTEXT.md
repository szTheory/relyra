# Phase 2: Protocol and Signature Core - Context

**Gathered:** 2026-04-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the strict SP-initiated protocol core that only accepts verified trust paths. This phase implements AuthnRequest/binding primitives, signature and signed-node trust binding, and typed protocol validation outcomes; Phoenix runtime wiring and store adapters remain in later phases.

</domain>

<decisions>
## Implementation Decisions

### Public Core API Surface
- **D-01:** Phase 2 introduces `Relyra.start_login/3` and `Relyra.consume_response/3` as the orchestration entrypoints, each returning typed success/error tuples.
- **D-02:** AuthnRequest construction, binding encode/decode, response/assertion validators, and signature helpers remain internal modules in this phase; only core orchestration is public.

### Validation Pipeline and Trust Binding
- **D-03:** Validation order is fixed: safe parse -> issuer/connection match -> signature verification -> signed-node selection -> status/destination/audience/recipient/time validations.
- **D-04:** The consumed assertion/response must be bound to the exact verified signed node; ambiguous assertion selection and wrapping indicators are typed rejections.
- **D-05:** Signature trust source is configured IdP certificates from resolved connection data; document `KeyInfo` is never treated as a trust root.
- **D-06:** Duplicate XML IDs are treated as typed validation failures during trust evaluation.

### RelayState and Request Intent
- **D-07:** RelayState remains an opaque server-side handle (`rs_...`) that maps to trusted return metadata; raw URL RelayState is rejected by default.
- **D-08:** SP-initiated request intent is required in the consume path contract so `InResponseTo` can be enforced once request-store behavior adapters land.

### Algorithm and Error Contract
- **D-09:** Algorithm policy defaults to SHA-256+ signatures/digests and rejects SHA-1 unless an explicit time-boxed legacy override is configured.
- **D-10:** Protocol and signature failures surface through `%Relyra.Error{type, message, details}` with stable `type` atoms and actionable detail maps.

### Architecture Boundaries
- **D-11:** Protocol/signature core remains framework/storage agnostic in this phase (no Phoenix/Ecto coupling), preserving planned phase boundaries.

### Claude's Discretion
- Internal module factoring and helper naming under protocol/security namespaces, as long as the locked decision invariants above remain true.
- Exact error message text and metadata key richness, as long as stable error atom semantics and typed contracts are preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked requirements
- `.planning/ROADMAP.md` — Phase 2 goal, requirements mapping, and plan boundaries.
- `.planning/REQUIREMENTS.md` — `SEC-02`, `SEC-03`, `SEC-04`, `SEC-05`, `SEC-07`, `PROT-01`, `PROT-02`, `PROT-03`, `PROT-05`.
- `.planning/PROJECT.md` — strict-by-default trust model, RelayState policy, and algorithm posture.

### Security baseline inherited from Phase 1
- `.planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md` — ADR 0001, parser trust path, and hybrid fallback trigger.
- `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md` — locked seam contract and phase-1 trust invariants.

### Architecture and threat guidance for Phase 2 implementation
- `.planning/research/ARCHITECTURE.md` — protocol pipeline ordering, module boundaries, and signature trust invariants.
- `.planning/research/PITFALLS.md` — signature wrapping, parser differential, and RelayState/open-redirect failure classes.
- `.planning/research/STACK.md` — implementation posture and dependency constraints impacting protocol/signature core.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/relyra/security/xml.ex`: frozen XML seam behavior with typed callbacks and security error atoms to anchor phase-2 trust flow.
- `lib/relyra/security/xml/pure_beam.ex`: current hardened parse guardrails and placeholder signed-node/canonicalization error returns to replace in protocol core.
- `lib/relyra/error.ex`: typed `%Relyra.Error{}` contract already in place for stable failure semantics.
- `lib/mix/tasks/compile/parser_path_guard.ex`: compile-time parser seam guard that prevents parser usage drift outside security boundary.

### Established Patterns
- Typed tuple contracts (`{:ok, value}` / `{:error, %Relyra.Error{}}`) are already the default seam pattern.
- Security-first guardrails are enforced through compile and CI lanes (`qa`, `ci.fast`, `ci.security`, `ci.integration`) in `mix.exs`.
- Fixture-driven adversarial testing pattern exists and should be extended for protocol/signature validation classes.

### Integration Points
- `lib/relyra.ex` is currently a placeholder and is the natural integration point for `start_login/3` and `consume_response/3`.
- Existing XML security tests under `test/security/xml/` provide the baseline harness to extend into phase-2 protocol/signature fixtures.
- CI security tags (`security_corpus`, `gate02_c14n`) already provide gate hooks for new phase-2 regression classes.

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond strict defaults, typed trust-path failures, and preserving phase boundaries.

</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

</deferred>

---

*Phase: 02-protocol-and-signature-core*
*Context gathered: 2026-04-24*
