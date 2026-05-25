# Phase 29 — Deferred Items

## ✅ RESOLVED — Existing-test triage (Plan 04, 2026-05-24)

**Status:** RESOLVED in Plan 04 (commit `08fbc66`). All 10 rows below were
triaged by re-pointing each structure-only fixture at the genuine D-11 signer
(`Relyra.TestSupport.XmldsigSigner`) so its `{:ok}`/typed-rejection now holds for
the RIGHT reason (genuine RSA signature + real digest). No test was deleted, no
verifier weakened, no `--warnings-as-errors` relaxation. Full
`mix test --warnings-as-errors` = **524/0** (phase gate met). Trust-gate tests
(`signed_node_binding_test.exs`, `signature_test.exs`) left untouched and green.
See `29-04-SUMMARY.md`.

## Existing-test triage (deferred to Plan 04, D-11 reusable signer)

**Logged by:** Plan 03 execution (2026-05-24)
**Owner:** Plan 04 (owns the D-11 reusable genuine XMLDSig signer + the full existing-test triage)
**Why deferred:** Plan 03 wires real crypto into the `[candidate]` arm (the published-hex
auth-bypass site). This is correct and intended: every end-to-end flow that previously fed a
**structure-only** signature (empty/absent `ds:SignatureValue` / `ds:DigestValue`, no genuine
RSA signature) and asserted `{:ok}` login — or asserted a downstream error that only fires
*after* signature verification — now **correctly fails closed** at the new crypto step. These
are the bypass being closed, NOT regressions. Converting them to genuine positives requires the
reusable D-11 signer, which Plan 04 owns (Plan 03 ships only an in-test local signer scoped to
`signature_crypto_test.exs` for the Wave-2 positive smoke).

Plan 03 scope boundary (per the SCOPE BOUNDARY executor rule): these failures are NOT in Plan 03's
`files_modified`, NOT in Plan 03's verification lanes
(`test/relyra/security/ test/security/` — both green: 161/0), and the plan objective explicitly
states "the existing-test triage land in Plan 04". They are logged here, not fixed here.

**Full-suite blast radius after Plan 03:** `mix test --warnings-as-errors` = 521 tests, 10
failures — ALL the same class (structure-only `{:ok}` flows now fail closed). Plan 03's own
lanes are 100% green.

### Tests requiring genuine-signer triage in Plan 04

| File:Line | Test | Now returns (correct fail-closed) |
|-----------|------|-----------------------------------|
| `test/protocol/consume_response_pipeline_test.exs:117` | request consume failure blocks success tuple | `:invalid_signature` / `:missing_signature` (crypto step) |
| `test/protocol/consume_response_pipeline_test.exs:134` | replay consume failure blocks success tuple | crypto fail-closed before replay/request gate |
| `test/protocol/consume_response_pipeline_test.exs:168` | clock skew config rejects invalid skew_seconds | crypto fail-closed before time-conditions stage |
| `test/protocol/consume_response_pipeline_test.exs:219` | consume order gate (replay before request) both pass before success | crypto fail-closed before the consume gates |
| `test/protocol/consume_response_pipeline_test.exs:242` | explicit request_intent compatibility path still succeeds | crypto fail-closed (no genuine sig) |
| `test/protocol/consume_response_pipeline_test.exs:266` | manifest fixtures map to expected_error_type + explicit request_intent success | success row now crypto-rejects |
| `test/protocol/consume_response_pipeline_test.exs:289` | skew_seconds boundary accepts exact edge / rejects edge+1 | crypto fail-closed before time stage |
| `test/conformance/sp_conformance_test.exs:30` | executed manifest rows produce declared expected_outcome | success-expecting rows now crypto-reject |
| `test/phoenix/acs_controller_test.exs:52` | POST /:connection_id/acs success | structure-only ACS POST now crypto-rejects |
| `test/relyra/telemetry_test.exs:152` | (signature/login success telemetry) | structure-only success flow now crypto-rejects |

### Recommended Plan 04 approach (per RESEARCH §201 + Open Q)

Build the reusable D-11 genuine signer (promotable into `FakeIdP` in Phase 30, D-12), then for each
row above either (a) re-point the fixture at a genuinely-signed Response so the `{:ok}` assertion
holds for the right reason, or (b) update the assertion to the new crypto-rejection where the test's
intent is a negative control. The Plan-03 in-test signer in
`test/relyra/security/signature_crypto_test.exs` (`genuine_signed_doc/0`) is the canonical shape to
promote — it canonicalizes with the SAME C14N engine the verifier uses, so the bytes match (D-12).
