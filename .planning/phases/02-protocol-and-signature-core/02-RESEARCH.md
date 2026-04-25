# Phase 2 Research - Protocol and Signature Core

## 1) Goal restatement and phase scope boundaries

Phase 2 delivers a strict SP-initiated protocol core that accepts only a verified trust path and rejects everything else with typed failures. The phase must satisfy `SEC-02`, `SEC-03`, `SEC-04`, `SEC-05`, `SEC-07`, `PROT-01`, `PROT-02`, `PROT-03`, and `PROT-05` while preserving the locked Phase 2 decisions in `02-CONTEXT.md`.

In scope:
- Public orchestration API surface: `Relyra.start_login/3` and `Relyra.consume_response/3`.
- Internal protocol primitives: AuthnRequest generation, binding encode/decode, response/assertion validation.
- Signature trust path: configured IdP certificates only, signed-node binding, duplicate ID defense, algorithm policy.
- Typed `%Relyra.Error{type, message, details}` outcomes for all protocol and trust failures.
- Opaque RelayState contract in core logic (no raw redirect URL acceptance).

Out of scope in this phase:
- Phoenix runtime wiring (`Plug.Conn`, router macro, controller integration) - Phase 4.
- Store adapter implementation (`RequestStore`, `ReplayStore`, Ecto/ETS behavior contracts) - Phase 3.
- Replay/in-response persistence semantics beyond consume-path contract shaping - Phase 3.
- Telemetry catalog and redacted logging policy implementation - Phase 5.

Strict defaults for this phase:
- Reject unless all checks pass in required order.
- Reject SHA-1 unless a time-boxed override is explicitly configured.
- Reject raw RelayState URL semantics.
- Reject ambiguity (multiple candidate signed assertions, duplicate IDs, trust source ambiguity).

## 2) Required module/API seams for Phase 2

The current codebase has the XML seam and typed error foundation in place, but protocol/signature modules are not yet present. Recommended seams keep Phase 2 framework/storage agnostic and preserve later-phase integration flexibility.

Public API seam:
- `lib/relyra.ex`
  - `@spec start_login(connection :: map(), relay_context :: map(), opts :: keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}`
  - `@spec consume_response(response_payload :: binary(), request_intent :: map(), opts :: keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}`
  - Keep business logic out of this file; delegate to internal protocol modules.

Internal protocol modules:
- `lib/relyra/protocol/authn_request.ex`
  - `build/3` builds AuthnRequest fields and request ID.
- `lib/relyra/protocol/binding.ex`
  - `encode_redirect/2`, `decode_post/2` to centralize transport transforms.
- `lib/relyra/protocol/response.ex`
  - `validate/4` orchestrates response-level checks after signature trust is established.
- `lib/relyra/protocol/assertion.ex`
  - Assertion-level checks (audience, recipient, time windows, subject extraction).
- `lib/relyra/protocol/validation_pipeline.ex`
  - Single canonical ordered `run/4` entry point to enforce non-bypassable validation order.

Internal security modules:
- `lib/relyra/security/signature.ex`
  - `verify/4` verifies signature using configured certs only.
  - Returns an opaque verified-node reference required for downstream consumption.
- `lib/relyra/security/signed_node.ex`
  - Opaque struct to bind consumption to verified signed node.
- `lib/relyra/security/algorithm_policy.ex`
  - Policy struct and helper predicates for signature and digest algorithms.
- `lib/relyra/security/relay_state.ex`
  - Opaque RelayState handle generation/validation contract (`rs_` prefix, never raw URL).

Contract notes:
- Keep all above modules internal (`@moduledoc false`) except public API and policy types that must be configured by callers.
- Continue using tuple contract `{:ok, value}` / `{:error, %Relyra.Error{}}`.
- Reuse `Relyra.Security.XML` seam callbacks rather than introducing parser usage elsewhere (compile guard already enforces this).

## 3) Security/trust-path invariants and ordering constraints

Non-negotiable invariants (must hold for every consume attempt):
1. Safe parse occurs before any trust or protocol extraction.
2. Issuer/connection binding is checked before signature verification.
3. Signature trust source is configured IdP certificates only; document `KeyInfo` is never a trust root.
4. Duplicate XML IDs are hard failures in trust evaluation.
5. Consumed assertion/response content is exactly the signed node that was verified.
6. Signed-node ambiguity is a typed rejection, not fallback behavior.
7. Status/destination/audience/recipient/time checks run only after signed-node binding is complete.
8. RelayState is opaque handle based, not redirect URL based.
9. Failure at any stage short-circuits pipeline and returns typed error.
10. No permissive mode by default.

Required validation order (locked by context):
1. `parse_safely`
2. issuer/connection match
3. signature verification
4. signed-node selection and binding
5. status validation
6. destination validation
7. audience validation
8. recipient validation
9. time conditions validation

Implementation recommendation:
- Encode this order in one internal function (`Relyra.Protocol.ValidationPipeline.run/4`) and avoid ad-hoc validation calls in multiple modules.
- Require each stage to accept previous-stage typed output, so it is impossible to call a downstream check without prior trust artifacts.

## 4) Detailed implementation guidance per requirement ID

### SEC-02 - Trust configured certs only, never KeyInfo trust

Implementation:
- `Relyra.Security.Signature.verify/4` must accept configured certificate set from resolved connection/request context as required input.
- Parse `KeyInfo` only for diagnostics metadata if needed; do not use it for trust decisions.
- If no configured cert verifies the signature, return typed `:untrusted_certificate` or `:invalid_signature`.

Suggested atoms/details:
- `:untrusted_certificate` with `%{connection_id: ..., cert_fingerprint_hint: ...}`
- `:invalid_signature` with `%{algorithm: ..., reference_uri: ...}`

Test focus:
- Attacker-controlled `KeyInfo` fixture must always fail unless configured cert matches.

### SEC-03 - Consume only exact verified signed node

Implementation:
- `verify/4` returns `%Relyra.Security.SignedNode{}` (opaque) containing verified node reference and signed ID context.
- `Relyra.Protocol.Response.validate/4` must consume only via signed-node handle input; do not re-query whole document for assertion extraction.
- Multiple signed candidates or mismatch between verified node and consumed assertion must return `:signature_wrapping_suspected` or `:ambiguous_signed_node`.

Suggested atoms/details:
- `:signature_wrapping_suspected` with `%{reason: :node_scope_mismatch | :multiple_candidates}`
- `:ambiguous_signed_node` with `%{candidate_count: n}`

Test focus:
- Wrapping fixtures where valid signature exists but payload uses a different assertion must fail deterministically.

### SEC-04 - Reject duplicate XML IDs

Implementation:
- Ensure duplicate ID check is performed during trust evaluation and propagated as typed failure.
- If XML seam adapter eventually reports duplicate IDs, preserve atom semantics in protocol path.
- Signature verification should also defensively fail on duplicate reference IDs.

Suggested atoms/details:
- `:duplicate_xml_id` with `%{duplicate_id: "...", count: n}`

Test focus:
- Duplicate ID fixture should fail before any success path in signature stage.

### SEC-05 - Algorithm policy SHA-256+ defaults; SHA-1 only time-boxed override

Implementation:
- Add `Relyra.Security.AlgorithmPolicy` with strict default allowed algorithms (SHA-256/384/512 variants).
- Reject SHA-1 by default with `:deprecated_algorithm`.
- Support explicit override only when both reason and expiry are configured and not expired.
- Keep policy enforcement inside signature verifier, not caller code.

Suggested atoms/details:
- `:deprecated_algorithm` with `%{algorithm: "...", policy: :sha1_rejected}`
- `:legacy_algorithm_override_expired` with `%{expired_at: "...", reason: "..."}`

Test focus:
- SHA-1 signed fixture fails under default.
- Same fixture passes only when explicit non-expired override exists.

### SEC-07 - Opaque server-side RelayState handle, no raw URL redirects

Implementation:
- `start_login/3` must produce RelayState in opaque `rs_` format.
- `consume_response/3` must reject raw URL-like RelayState inputs by default.
- Core contract should treat RelayState as trusted handle metadata, never direct redirect target text.
- Keep this storage-agnostic: Phase 2 defines handle contract and validation logic; Phase 3 wires persistence adapters.

Suggested atoms/details:
- `:relay_state_rejected` with `%{reason: :raw_url | :invalid_format | :tampered}`

Test focus:
- Raw `https://...` RelayState payload rejected.
- Non-`rs_` malformed handle rejected.

### PROT-01 - Generate SP-initiated AuthnRequest with stable IDs and required fields

Implementation:
- `Relyra.Protocol.AuthnRequest.build/3` should generate:
  - stable unique request ID
  - issue instant
  - destination
  - issuer (SP entity ID)
  - protocol version and ACS binding fields required by profile
- Keep XML generation deterministic for test fixtures.

Suggested atoms/details:
- `:authn_request_invalid` with `%{missing_field: ...}`
- `:authn_request_build_failed` for unexpected internal faults

Test focus:
- Golden fixture test for canonical AuthnRequest field set.
- Property test for ID uniqueness shape and prefix consistency.

### PROT-02 - Accept ACS response input with typed success/error, no silent success

Implementation:
- `Relyra.consume_response/3` must have exactly two result classes:
  - `{:ok, login_result}`
  - `{:error, %Relyra.Error{}}`
- No boolean returns, no nil-success, no partial success.
- Any parse, trust, protocol, or policy issue maps to typed error atom.

Suggested atoms/details:
- Ensure every rescue path wraps into `%Relyra.Error{type: :internal_protocol_error, ...}` rather than leaking exceptions.

Test focus:
- Contract test that all failure fixtures return `%Relyra.Error{}` and never `{:ok, _}`.

### PROT-03 - Validate issuer/audience/recipient/destination/status and tenant/connection binding

Implementation:
- After signature trust bind, validate:
  - issuer equals expected connection IdP entity
  - status is success
  - destination equals expected ACS
  - audience includes SP entity ID
  - recipient equals ACS endpoint expectation
  - request/tenant connection binding data from consume contract
- Keep checks pure and deterministic in `Relyra.Protocol.Response` and `Relyra.Protocol.Assertion`.

Suggested atoms/details:
- `:issuer_mismatch`, `:invalid_audience`, `:recipient_mismatch`, `:destination_mismatch`, `:unsupported_status`, `:connection_binding_mismatch`

Test focus:
- One fixture per field mismatch with expected and actual values in details map.

### PROT-05 - Time conditions with bounded configurable skew

Implementation:
- Validate `NotBefore`, `NotOnOrAfter`, and SubjectConfirmation windows.
- Use bounded skew from opts/policy with strict default.
- Fail closed on missing required temporal fields in strict mode.

Suggested atoms/details:
- `:assertion_not_yet_valid`, `:assertion_expired`, `:subject_confirmation_expired`, `:clock_skew_exceeded`

Test focus:
- Boundary tests around exact skew limits and one-second over/under cases.

## 5) Failure taxonomy and typed error contract implications

Use `%Relyra.Error{type, message, details}` as the only error surface and keep `type` atoms stable across phases.

Recommended taxonomy groups for Phase 2:
- Parse/seam: `:doctype_forbidden`, `:entity_expansion_forbidden`, `:payload_too_large`, `:malformed_xml`, `:duplicate_xml_id`
- Signature/trust: `:missing_signature`, `:invalid_signature`, `:untrusted_certificate`, `:signature_wrapping_suspected`, `:ambiguous_signed_node`, `:deprecated_algorithm`
- Protocol: `:issuer_mismatch`, `:unsupported_status`, `:destination_mismatch`, `:invalid_audience`, `:recipient_mismatch`, `:connection_binding_mismatch`
- Time: `:assertion_not_yet_valid`, `:assertion_expired`, `:subject_confirmation_expired`, `:clock_skew_exceeded`
- RelayState: `:relay_state_rejected`
- Catch-all internal fault: `:internal_protocol_error`

Error contract implications:
- `type` is machine-stable; `message` can evolve for clarity.
- `details` must include actionable, non-sensitive keys (expected vs actual, stage, policy context).
- No raw SAML XML in details.
- Caller code should branch on `type`, not message text.

## 6) Testing and fixture strategy (including adversarial cases)

Build on existing XML security corpus and extend into protocol/signature core fixtures.

Recommended fixture layout:
- `test/fixtures/security/protocol/*.xml` for protocol mismatch classes.
- `test/fixtures/security/signature/*.xml` for trust/wrapping/algorithm classes.
- `test/fixtures/security/relay_state/*.json` for opaque handle reject classes.
- Keep manifest-driven pattern used by `test/security/xml/corpus_security_test.exs`.

Required adversarial fixture classes for Phase 2:
- KeyInfo trust injection (SEC-02)
- Signature wrapping and signed-node ambiguity (SEC-03)
- Duplicate XML IDs in signed contexts (SEC-04)
- SHA-1 signatures default-rejected and override-expiry behavior (SEC-05)
- Raw URL RelayState and malformed opaque token cases (SEC-07)
- Issuer/audience/recipient/destination/status mismatch cases (PROT-03)
- NotBefore/NotOnOrAfter/SubjectConfirmation boundary cases with skew (PROT-05)

Test layers:
- Unit tests for each validator function and algorithm policy predicate.
- Pipeline-order test asserting strict stage order and short-circuit behavior.
- Contract tests for public API tuple shape (`start_login/3`, `consume_response/3`).
- Determinism tests: same fixture returns same error atom across multiple runs.

## 7) Verification commands/checks for completion

Minimum completion checks for this phase:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix test test/security --warnings-as-errors
mix ci.fast
mix ci.security
```

Recommended additional targeted checks once protocol tests exist:

```bash
mix test test/protocol --warnings-as-errors
mix test --only security_corpus --warnings-as-errors
mix test --only gate02_c14n --warnings-as-errors
```

Completion gate expectations:
- Public API tuple contracts are verified.
- All mapped Phase 2 requirement IDs have direct test coverage.
- Adversarial fixtures for wrapping/KeyInfo/SHA-1/duplicate IDs fail as expected.
- No parser usage appears outside XML seam guard.

## Validation Architecture

This section is structured for downstream Nyquist extraction.

Dimension A - Trust Source Integrity:
- Checkpoint A1: Signature verification path receives configured cert set from connection context.
- Checkpoint A2: `KeyInfo` never elevates trust.
- Evidence: failing KeyInfo injection fixture + passing configured-cert fixture.

Dimension B - Signed Node Binding:
- Checkpoint B1: Validator consumes only signed-node handle output from signature stage.
- Checkpoint B2: Ambiguous assertion selection is rejected.
- Evidence: wrapping fixtures fail with stable typed atoms.

Dimension C - Structural Integrity:
- Checkpoint C1: Duplicate XML IDs produce typed rejection.
- Checkpoint C2: No fallback path bypasses duplicate-ID failure.
- Evidence: duplicate ID fixtures fail consistently pre-success.

Dimension D - Protocol Constraint Correctness:
- Checkpoint D1: issuer, status, destination, audience, recipient are all validated.
- Checkpoint D2: connection/tenant binding mismatches are typed failures.
- Evidence: one failing fixture per field + one clean success fixture.

Dimension E - Temporal Correctness:
- Checkpoint E1: `NotBefore` and `NotOnOrAfter` checks enforce bounded skew.
- Checkpoint E2: SubjectConfirmation timing window is enforced.
- Evidence: boundary tests at exact skew edges.

Dimension F - Strict-by-default Policy:
- Checkpoint F1: SHA-1 rejected under default policy.
- Checkpoint F2: override requires explicit reason+expiry and expires automatically.
- Evidence: policy matrix tests (default reject, temporary allow, expired reject).

Dimension G - Error Determinism and Contract Stability:
- Checkpoint G1: every failure maps to `%Relyra.Error{}` with stable `type` atom.
- Checkpoint G2: no silent success and no non-typed error return paths.
- Evidence: contract tests over full fixture corpus and repeated runs.

Dimension H - Opaque RelayState Discipline:
- Checkpoint H1: non-opaque/URL RelayState rejected.
- Checkpoint H2: opaque handle parsing remains storage/framework agnostic.
- Evidence: relay-state adversarial fixtures and contract tests.

## 9) Risks, unknowns, and mitigation plans

Risk 1 - XMLDSig/canonicalization complexity may delay signature correctness.
- Mitigation: isolate complexity in `Relyra.Security.Signature` and `Relyra.Security.SignedNode`, maintain fixture-driven adversarial regression from day one.

Risk 2 - Error atom sprawl and naming drift across modules.
- Mitigation: define central Phase 2 error atom map and enforce via tests that all pipeline failures use listed atoms only.

Risk 3 - Hidden framework/storage coupling sneaks into protocol core.
- Mitigation: keep function inputs primitive/map based; avoid `Plug.Conn` and store adapter calls in Phase 2 modules; rely on existing compile guard discipline.

Risk 4 - Validation-order regressions during refactor.
- Mitigation: keep single pipeline orchestrator function and add explicit order assertion tests.

Risk 5 - RelayState semantics are implemented too loosely before Phase 3 adapters.
- Mitigation: lock handle contract in Phase 2 (`rs_` opaque only), defer persistence mechanisms but do not defer reject behavior.

Risk 6 - Requirement mapping gaps between code and tests.
- Mitigation: maintain requirement-to-test manifest labels for all Phase 2 IDs and make this part of phase verification checklist.

Unknowns to resolve during planning/execution:
- Exact request-intent shape passed into `consume_response/3` before Phase 3 adapter integration.
- Final algorithm allowlist breadth beyond SHA-1 policy floor.
- Canonical fixture source format for protocol/signature manifest extension.

