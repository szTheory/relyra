# Phase 3: Behaviour Contracts and Stores - Context

**Gathered:** 2026-04-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship stable extension behaviour contracts and safe request/replay storage defaults that preserve strict request-intent and replay controls. This phase adds behaviour + adapter seams and their integration into consume flow; Phoenix runtime ergonomics and observability remain in later phases.

</domain>

<decisions>
## Implementation Decisions

### Public Behaviour Surface
- **D-01:** Publish five stable behaviour contracts as the extension API: `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, and `Relyra.ReplayStore`.
- **D-02:** Keep default adapter implementations internal (`@moduledoc false`) while behaviours remain the public API contract.

### Request Intent and Correlation Contract
- **D-03:** Keep fail-closed correlation semantics for `relay_state` and `in_response_to` exactly as strict as current Phase 2 behavior.
- **D-04:** Move request-intent source of truth from ad-hoc caller maps toward explicit `RequestStore` reads/consumes, without weakening typed mismatch/missing failures.

### Request and Replay Store Semantics
- **D-05:** `RequestStore` and `ReplayStore` must expose atomic consume semantics (single-use guarantees under concurrent access).
- **D-06:** Ship ETS adapters as development defaults with explicit production warnings, and ship Ecto adapters as production-safe defaults behind optional dependency boundaries.
- **D-07:** Ecto adapter implementation should enforce one-time semantics with database-level atomicity (transactional consume flow and uniqueness-backed idempotency).

### Multi-Tenant Resolver Decoupling
- **D-08:** `ConnectionResolver` returns plain maps consumed by protocol core so Phase 3 preserves no Phoenix/Ecto coupling in core validation modules.
- **D-09:** Integrate resolver + stores through existing core entry points (`start_login/3`, `consume_response/3`) and keep validation pipeline contracts tuple-typed.

### Delivery Sequence
- **D-10:** Execute Phase 3 in roadmap order (`03-01` contracts, `03-02` adapters, `03-03` consume integration) to avoid mid-phase API churn.

### Claude's Discretion
- Exact callback argument naming and helper module factoring within each behaviour module.
- Exact wording/format of ETS production warning messages, as long as warnings are loud and explicit about single-node/dev-only limits.
- Internal adapter module layout and private utility function placement.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements anchors
- `.planning/ROADMAP.md` — Phase 3 goal, plan sequence, and success criteria.
- `.planning/REQUIREMENTS.md` — `SEC-06`, `PROT-04`, `EXT-01..EXT-05` requirement contract.
- `.planning/PROJECT.md` — strict-by-default security posture and architecture boundaries.

### Inherited locked decisions
- `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md` — behaviour-first seam pattern and typed trust-path contracts.
- `.planning/phases/02-protocol-and-signature-core/02-CONTEXT.md` — locked correlation/validation flow and framework-agnostic core boundary.

### Existing implementation seams to preserve
- `lib/relyra.ex` — current entrypoint contracts and request-intent validation hooks.
- `lib/relyra/protocol/validation_pipeline.ex` — strict correlation and typed failure semantics consumed by Phase 3 adapters.
- `lib/relyra/security/relay_state.ex` — existing opaque relay handle issuance and metadata persistence seam.
- `lib/relyra/security/xml.ex` — precedent for public behaviour contract shape.
- `lib/relyra/error.ex` — stable `%Relyra.Error{}` envelope required across adapters.

### Regression and contract tests
- `test/relyra_test.exs` — public tuple and typed error contract expectations.
- `test/protocol/consume_response_pipeline_test.exs` — correlation/replay-related typed failure fixtures and ordered validation behavior.
- `test/fixtures/security/protocol/manifest.json` — protocol regression corpus mapping for typed failure classes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Error` (`lib/relyra/error.ex`): stable typed error envelope for all new behaviour and adapter failure paths.
- XML seam pattern (`lib/relyra/security/xml.ex`): proven public behaviour contract precedent for Phase 3 behaviour design.
- Entry-point orchestration (`lib/relyra.ex`): natural insertion points for request/replay store hooks in login and consume flow.
- Relay metadata seam (`lib/relyra/security/relay_state.ex`): existing persistence callback shape that can evolve into explicit store behaviour calls.
- Fixture-manifest testing pattern (`test/fixtures/security/protocol/manifest.json`): reusable contract for adapter/regression fixtures.

### Established Patterns
- Strict-by-default, fail-closed trust checks with typed `%Relyra.Error{}` outcomes.
- Public API returns tuple contracts (`{:ok, map()} | {:error, %Relyra.Error{}}`) and hides internal machinery.
- Core protocol modules remain storage/framework agnostic and consume plain maps.
- CI and fixtures are treated as part of the safety contract, not optional docs.

### Integration Points
- Persist request intent at `start_login/3` immediately after request/relay issuance.
- Read and atomically consume request intent/replay signals in `consume_response/3` before final trust acceptance.
- Feed resolved tenant connection context into existing `connection_context/2` / validation pipeline map flow.
- Keep adapter boundaries outside protocol-core modules while preserving existing validation ordering.

</code_context>

<specifics>
## Specific Ideas

- Preserve current strict mismatch/missing failure behavior while replacing map-only intent lookup with store-backed semantics.
- Keep adapter defaults easy for local development but impossible to mistake for clustered production safety.

</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

</deferred>

---

*Phase: 03-behaviour-contracts-and-stores*
*Context gathered: 2026-04-24*
