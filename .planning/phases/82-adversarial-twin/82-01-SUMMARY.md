---
phase: 82-adversarial-twin
plan: 01
status: complete
requirements: [PROP-01, PROP-02, PROP-03, PROP-04, PROP-05]
commit: ad6ad64
---

# Phase 82 Summary: Property-based adversarial twin

**Outcome:** a generative adversarial twin now hammers the trust paths sealed in
Phases 80/81. `mix qa` (1075 tests + 5 properties, 0 failures, 1 skipped) and
`mix ci.security` (exit 0) pass; the bounded property lane runs as its own gated
`cmd mix test` process; the scheduled deep lane passes actionlint.

## What was built

- **Twin signer (PROP-01):** `XmldsigSigner.sign_enveloped/1` genuinely signs an
  arbitrary enveloped-signed root — the signing counterpart to Phase 81's
  `PureBeam.bind_enveloped_signature/3`. The twin mints genuinely signed login
  `Response`, enveloped `LogoutRequest` (POST), signed redirect `SAMLRequest`
  query, and signed `EntityDescriptor` documents. An unmutated twin of each kind
  is accepted by the real public API (self-test).
- **Generators (PROP-02):** `test/support/twin/` — `Mint`, `Mutations`,
  `Generators`, `Runner`, `Oracle`. Shrinkable op *plans* across every named
  family (wrap/move/duplicate, envelope injection, namespace rebinding,
  comment/PI/CDATA, whitespace/encoding, duplicate IDs, time boundaries,
  truncation/size) plus a redirect-query taxonomy. Shrinking acts on the plan,
  never on raw bytes. A coverage test asserts every family is reachable.
- **Oracle (PROP-03):** judges `{:ok}` legal only when the consumed identity
  equals what the generator *signed* (never Relyra's own re-parse); otherwise an
  allowlisted `%Relyra.Error{}` type; a raise/exit/timeout/heap blowup is a
  defect. Each case runs in a bounded `Task` with `max_heap_size`. A planted
  value-binding mismatch is proven to be caught; internal wrappers are kept off
  the allowlist so masked crashes surface.
- **Lanes (PROP-04):** bounded, seeded property suite
  (`adversarial_property_test.exs`, `TWIN_MAX_RUNS`-tunable) is its own
  `ci.security` line, listed in `ci_gate_integrity_test.exs` (and the two mirror
  inventories). `.github/workflows/adversarial-deep.yml` runs the same suite with
  a large `max_runs` and a printed random seed, scheduled + `workflow_dispatch`,
  intentionally absent from `ci-gate`.

## Round 1 (PROP-05)

Deep dry-runs (≈4,800 cases across the four kinds, then the seeded lane) found
**no code defect** — the trust path sealed in Phases 80/81 holds under mutation.
The two triage items were **oracle-model corrections, not code changes**, so
there are no new permanent `trust_binding` rows to promote this round:

1. **Metadata model.** `Metadata.Parser.parse/2` is a structural extractor, not
   a signature verifier (that is `Signature.verify_metadata_root`, whose crypto
   core the logout_post twin already fuzzes). Its real property is
   authoritative-node selection, so the metadata generator was retargeted to
   unsigned-wrapper decoys (never in-signed-node injection, which would break a
   real signature). The parser correctly derives every field from the inner
   signed descriptor.
2. **Allowlist completeness.** `:deprecated_algorithm`,
   `:legacy_algorithm_override_expired`, and `:unknown_signing_algorithm` are
   legitimate typed rejections that were missing from the oracle allowlist;
   added.

Per the stopping rule, one more clean deep round with no new defect class closes
the technique; the round log lives in the milestone evidence file at close-out
(Phase 84).

## Guardrails honored

No public API/default/security-posture change (new error atoms are additive; the
twin is test-only). Each new suite is its own `cmd mix test` line. No test
weakened. The invariants hold and are now continuously fuzzed.
