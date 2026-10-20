---
phase: 83-mutation-testing
plan: 01
status: complete
requirements: [MUT-01, MUT-02, MUT-03]
commit: f3866f0
---

# Phase 83 Summary: Mutation testing of the security core

**Outcome:** a scheduled mutare lane now measures whether the security-core
tests detect broken checks. The baseline spike landed, two real coverage gaps
were closed, and the score plateaued with the remainder classified as
equivalent/residual. `mix qa` (1087 tests + 5 properties, 0 failures, 1 skipped)
and `mix ci.security` (exit 0) pass.

## What was built (MUT-01)

- `{:mutare, "0.5.1", only: [:dev, :test], runtime: false}` + `.mutare.exs`
  scoping mutation to the PURE trust core: `signature.ex`, `signed_node.ex`,
  `algorithm_policy.ex`, the XML seam (`pure_beam.ex`, `c14n.ex`,
  `saxy_tree.ex`), `validation_pipeline.ex`, `logout_validator.ex`,
  `metadata/parser.ex`. Telemetry spans and Logger calls are routed `:raw`/`:skip`
  so mutants land on trust checks, not instrumentation.
- `.github/workflows/mutation.yml` — scheduled (weekly) + `workflow_dispatch`,
  runs `mix mutare --report json:mutare.json`, uploads the Stryker-schema score
  as an artifact, one worker / one DB, `--time-budget`. Intentionally **outside
  `ci-gate`** (actionlint-clean).
- `test/security/mutation_lane_test.exs` — its own gated `cmd mix test` line.
  Pins the lane (mutare exact-pinned; coverage-selected fresh `mix test` process
  per mutant; scheduled/dispatch only; absent from ci-gate) and is the
  **anti-weakening guard** on the permanent corpora (adversarial_crypto ≥ 7 rows,
  trust_binding ≥ 21, security_corpus.json ≥ 8, the property gate present).

### Hermetic baseline (the spike)

Mutare's sandbox is a git-LESS copy of the project, so five governance/adoption
META-suites (`milestone_scope`, `phase_73_reconciliation`, `workflow_hygiene`,
`external_canary_contract`, `evidence_contract`) fail there — they assert against
the live git checkout, not the code under mutation. `RELYRA_MUTATION_SUITE=1`
(set by the workflow) excludes those `:non_hermetic_sandbox` suites from the
mutation baseline ONLY; they run in every ordinary lane (mix qa, ci.security,
ci-gate). This scopes mutation to the security core — never a relaxation of a
gate.

## Round log — algorithm_policy.ex (MUT-02, MUT-03)

| Round | Score | Killed | Survived | Ignored | Action |
|-------|-------|--------|----------|---------|--------|
| 1 | 79.4% | 201 | 52 | 0 | baseline — surfaced the allowlist-acceptance gap |
| 2 | 81.1% | 198 | 46 | 9 | killed the signature-allowlist gap; ignored the ecdsa fast-path equivalents |
| 3 | 82.8% | 202 | 42 | 9 | killed the digest-allowlist gap |

(16 uncovered mutants excluded from the score throughout.)

**Real gaps closed (killed by adding sharper tests):** `enforce_signature_method`
/ `enforce_digest_method` were only ever exercised with SHA-1 (rejection) — no
test asserted that the STRONG hashes the default policy lists as allowed
(rsa-sha384/512, sha384/512 digests) are actually accepted. A mutant that blanked
an allowlist entry therefore survived. Added data-driven acceptance tests over
every allow-listed method, with **literal** URI assertions (iterating the list
alone adapts to the mutation — the pitfall that left the digest gap open after
round 2).

**Equivalent mutant (documented ignore, MUT-02):** the ecdsa fast-path guard in
`digest_atom_for_signature_method/1` — altering/dropping it still reaches the
`true ->` arm, which returns the same `:unsupported_signature_algorithm`. Marked
`# mutare:ignore` with the reason (9 mutants on that line). Its mirror in
`signing_digest_atom/1` is NOT equivalent — a different fall-through atom — and is
killed by that function's own tests.

**Plateau + residual (MUT-03):** the 42 remaining survivors are no longer real
defects — the trend has flattened to two classes, so further test-writing yields
suppression, not detection:
- **Equivalent (29):** `Error.new` message strings and `details` maps/atoms. The
  library's error contract is deliberately **type-only** (`%Relyra.Error{type:}`,
  with detail redaction); tests assert the type, never the prose/details, so
  mutating them is unobservable to the contract.
- **Residual (13):** defensive input guards (`method_allowed?` /
  `enforce_sha1_policy` non-binary fallbacks — the pipeline already guarantees a
  binary method upstream) and legacy SHA-1 escape-hatch edge validations
  (deprecated, operator-gated opt-in). Low trust value; recorded as residual
  rather than chased.

## Scope note (residual)

This session ran the rounds-to-plateau on `algorithm_policy.ex` — the
security-critical allowlist and the tightest module. The scheduled weekly lane
extends the same scan across the rest of the configured security core; its first
full-core score will be captured from the artifact. The Ecto-backed replay stores
and metadata-apply path are DEFERRED (they need the `mutare_ecto` companion for
their schema macros; their trust-relevant checks already route through the scoped
modules).

## Guardrails honored

mutare is dev/test-only, exact-pinned, non-runtime. No public API/default/
security-posture change. The mutation lane is its own `cmd mix test` process and
never gates. No existing security test was weakened — the guard test enforces it.
