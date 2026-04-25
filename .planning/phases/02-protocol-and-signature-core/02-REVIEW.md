---
phase: 02-protocol-and-signature-core
status: issues_found
updated: 2026-04-24T16:10:00Z
---

# Phase 02 Focused Code Review

Reviewed source/test files listed in plans `02-01`, `02-02`, and `02-03`, with emphasis on protocol trust enforcement, signature binding, and typed failure behavior.

## High

### H-01: `consume_response/3` can accept unsigned or semantically invalid XML due to synthetic default payload values
- **Where:** `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/security/xml/pure_beam.ex`
- **What:** `parse_safely/2` currently returns only `%{type, bytes}` and does not extract protocol/signature fields. `ValidationPipeline.protocol_payload/5` then seeds trusted defaults (`issuer`, success `status`, destination/audience/recipient, assertion times, signature methods, and even a default signed candidate), allowing downstream checks to pass against generated values instead of response content.
- **Evidence:** Runtime repro returned success for `Relyra.consume_response("<Fake>unsigned</Fake>", request_intent, opts)` with no signed assertion material.
- **Risk:** Signature trust and protocol validation can be bypassed by any well-formed XML payload when connection config includes a cert chain.
- **Remediation:** Remove permissive defaults for security-critical fields; require extraction of issuer/status/destination/audience/recipient/assertion times/signed candidates from parsed XML; fail closed when required fields are absent before signature/policy checks.

### H-02: Required request-correlation fields are not enforced (`in_response_to`, `relay_state`)
- **Where:** `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex`
- **What:** `validate_request_intent/1` requires `:in_response_to` and `:relay_state`, but pipeline logic does not validate either against response/binding data. `login_result/2` emits `in_response_to: nil` because the pipeline never carries or checks it.
- **Evidence:** Two calls with different `request_intent.in_response_to` values both returned `{:ok, ... in_response_to: nil}` for the same payload.
- **Risk:** Unsolicited/replayed/cross-request responses can be accepted because request intent is not cryptographically/protocol bound end-to-end.
- **Remediation:** Parse and validate `Response@InResponseTo` and RelayState (from binding decode path) against request intent; reject mismatches with typed protocol errors before success.

## Medium

### M-01: Test coverage misses the critical bypass paths above
- **Where:** `test/protocol/consume_response_pipeline_test.exs`, `test/relyra_test.exs`
- **What:** Current tests primarily assert behavior via `opts[:payload]` overrides and tuple-shape checks; they do not assert that raw unsigned/malformed XML is rejected, and do not assert correlation enforcement for `in_response_to`/`relay_state`.
- **Risk:** High-impact trust regressions can ship while the scoped test suite remains green.
- **Remediation:** Add negative tests that pass real XML lacking required signed/protocol fields and expect typed failures; add explicit mismatch tests for `in_response_to` and relay-state binding.

## Low

### L-01: RelayState fixture test parser uses `Code.eval_string/3`
- **Where:** `test/protocol/relay_state_test.exs`
- **What:** Manifest parsing rewrites JSON into Elixir syntax then evaluates it as code.
- **Risk:** Brittle parsing and avoidable code-execution surface in test harness.
- **Remediation:** Parse fixture JSON with a strict decoder (same approach as protocol fixtures) and validate expected keys structurally.
