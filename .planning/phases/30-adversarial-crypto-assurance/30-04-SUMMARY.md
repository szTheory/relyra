---
phase: 30-adversarial-crypto-assurance
plan: 04
subsystem: ci-security-gate
tags: [ci, mix-aliases, security-gate, anti-hollow, meta-gate, xmldsig]

# Dependency graph
requires:
  - phase: 30-adversarial-crypto-assurance
    plan: 02
    provides: the adversarial_crypto suite (test/security/xml/adversarial_crypto_test.exs) that Plan 04 wires honestly into ci.security
  - phase: 30-adversarial-crypto-assurance
    plan: 03
    provides: regenerated CONFORMANCE.md so the ci.conformance drift gate (first step of ci.security) stays green
provides:
  - ci.security alias that honestly gates every security suite (one `cmd mix test` per suite, immune to mix's in-alias `test`-task dedup and `--only conformance` filter bleed)
  - anti-hollow meta-gate test/security/ci_gate_integrity_test.exs (T-30-14) that fails the build if any gated suite is collapsed back to a bare `test` step, dropped from the alias, deleted from disk, or has its `--only <tag>` filter de-tagged
  - compile --warnings-as-errors as the first ci.security step
  - intentional belt-and-suspenders documentation on the standalone GATE-02 step in security-gates.yml
affects: [ci.security, release-please.yml, publish-hex.yml, security-gates.yml, 31-disclosure]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Honest gating: run each suite as its own `cmd mix test ...` (a fresh OS process) so mix's per-invocation `test`-task dedup cannot silently skip later suites"
    - "Structural meta-gate: a test that reads mix.exs, slices the alias block by bracket-depth scan, and proves each contract suite is wired as `cmd mix test`, exists on disk, and (for `--only` suites) actually declares the tag"
    - "Self-gating gate: the meta-gate carries no default-excluded tag and is itself named as a `cmd mix test` step in ci.security, so it runs under plain `mix test` AND gates itself in the security lane"

key-files:
  created:
    - test/security/ci_gate_integrity_test.exs
  modified:
    - mix.exs
    - .github/workflows/security-gates.yml

key-decisions:
  - "DEVIATION FROM PLAN SCOPE (orchestrator-approved after 3 converging research agents): Plan 04 originally scoped a single-line edit adding a bare `test ... adversarial_crypto` step to ci.security. That edit is a SILENT NO-OP and could not meet acceptance criterion #3 ('failing one assertion fails the alias'): mix dedups the `test` task within one `mix` invocation, and ci.conformance (first step) already runs `test --only conformance`, so every later bare `test` step in the lane was both skipped AND inheriting the conformance filter. The security lane was hollow — a regression would have shipped green. The fix converts EVERY security suite to its own `cmd mix test` step + adds an anti-hollow meta-gate + adds compile --warnings-as-errors + documents the standalone gate02 step."
  - "compile --warnings-as-errors added as the FIRST ci.security step: the lane never compiled w-a-e before; ci.fast already proves the tree is clean under it, so this is free hardening with no new risk."
  - "Meta-gate carries NO tag (only :pending is excluded by default) so it runs under plain `mix test`, and is ALSO named explicitly as a `cmd mix test` step in ci.security — the gate gates itself."
  - "Standalone GATE-02 step in security-gates.yml kept and documented as intentional redundancy: it re-runs `--only gate02_c14n` independently of the alias being correctly wired, so a C14N golden-oracle regression fails the build even if the alias regresses."
  - "lib/relyra/security/* was NOT touched (D-10 frozen verifier respected) — verified by `git diff --name-only 23741b0 HEAD`."

patterns-established:
  - "Pattern: never use a bare `test` step more than once in a multi-suite mix alias — use `cmd mix test` per suite. The meta-gate enforces this for the security lane."
  - "Pattern: any `--only <tag>` alias step must be backed by a structural assertion that the tag exists in the suite source, so `--only <tag>` can never silently match zero tests."

requirements-completed: [D-08, T-30-14]

# Metrics
duration: 12min
completed: 2026-05-24
---

# Plan 30-04 — Honest-gate fix for `ci.security`

## The finding (why the one-line plan could not work)

Plan 04's original scope was a single bare `test ... --only adversarial_crypto` line
appended to the `ci.security` alias (committed as Task 1, `23741b0`). That line is a
**silent no-op**:

1. `mix` deduplicates the `test` task within a single `mix` invocation — only the
   FIRST `test` in an alias actually runs; later bare `test` steps are skipped.
2. `ci.security` runs `ci.conformance` first, which runs
   `test ... --only conformance`. So the one and only `test` task in the lane was
   already consumed with the `--only conformance` filter.

Net effect: every bare `test` step in `ci.security` after `ci.conformance` was both
**skipped** and (had it run) would have **inherited `--only conformance`**. The
security lane was hollow — a regression in any security suite would still ship green.
Three research agents converged on the same diagnosis and fix.

## The fix (Steps A–C)

- **Step A — `mix.exs` `ci.security` rewrite.** Every security suite now runs as its
  own `cmd mix test ...` step (a fresh OS process, immune to dedup + filter bleed).
  Shell-builtin `cmd test -f ...` / `cmd grep ...` lines left unchanged (those are
  shell `test`, not mix). Added `compile --warnings-as-errors` as the first step.
  Kept `ci.conformance` first (now harmless — each `cmd mix` is isolated). Kept
  `--warnings-as-errors` on every test line and the fail-fast ordering (doc/`--check`
  gates → suites → supply-chain audits). Added a justification-first comment block (in
  the repo's lowercase alias-comment voice) explaining the dedup hazard and pointing
  at the meta-gate. The decimal advisory comment + `deps.audit` line kept verbatim.
- **Step B — anti-hollow meta-gate** `test/security/ci_gate_integrity_test.exs`
  (patterned after `test/release/release_hardening_test.exs`). It reads `mix.exs`,
  slices the `"ci.security": [ ... ]` block by a bracket-depth scan, and asserts, for
  the `@gated_suites` contract (self, strict_default, escape_hatch, security_corpus,
  gate02_c14n, adversarial_crypto):
  - Test 1: each suite file exists on disk (T-30-14 presence).
  - Test 2: each suite is named in a ci.security step (excluding comment lines).
  - Test 3 (anti-hollow): each gated suite step is `cmd mix test ...`, never a bare
    `test ...` — this is the assertion that fails if the dedup bug is reintroduced.
  - Test 4 (tag integrity): each `--only <tag>` suite's source declares `@tag`/`@moduletag :<tag>`,
    so `--only <tag>` can never silently match zero tests.
  The meta-gate carries no default-excluded tag (runs under plain `mix test`) and is
  itself a `cmd mix test` step in ci.security (gates itself).
- **Step C — `security-gates.yml`.** Added a comment above the standalone GATE-02
  step documenting it as intentional belt-and-suspenders on the C14N golden oracle,
  independent of the alias being correctly wired. The step itself is unchanged.

## Proof the gate is honest (Step D)

### Gating probe (the definitive test)

Temporarily injected `assert false` into the first assertion of
`adversarial_crypto_test.exs`, then ran `mix ci.security`:

- **With probe:** `mix ci.security` exit code **1** (non-zero). The adversarial_crypto
  suite ran as `6 tests, 1 failure` and failed at `adversarial_crypto_test.exs:66`,
  aborting the alias with `** (exit) 2` at the `cmd mix test` step. This proves a
  single failing assertion now fails the whole alias (acceptance criterion #3 met).
- Probe **fully reverted**; `git diff -- test/security/xml/adversarial_crypto_test.exs`
  is empty.
- **After revert:** `mix ci.security` exit code **0**.

### Per-suite counts from a clean `mix ci.security` (exit 0)

Each previously-deduped suite now runs as its own process with a non-zero count:

| ci.security step                         | result                          |
|------------------------------------------|---------------------------------|
| ci.conformance (`--only conformance`)    | 6 tests, 0 failures             |
| relyra.conformance --check               | CONFORMANCE.md matches manifest |
| relyra.security_review --check           | evidence matches state          |
| ci_gate_integrity_test (meta-gate)       | 4 tests, 0 failures             |
| strict_default_proof_test                | 4 tests, 0 failures             |
| escape_hatch_audit_test                  | 1 test, 0 failures              |
| corpus_security + corpus_gate (`security_corpus`) | 9 tests, 0 failures (3 excluded) |
| corpus_security (`gate02_c14n`)          | 3 tests, 0 failures (4 excluded)|
| adversarial_crypto (`adversarial_crypto`)| 6 tests, 0 failures             |
| deps.audit / hex.audit / sobelow         | clean (hex.audit unavailable in runtime, continues; sobelow scan complete) |

### Other validation

- Meta-gate alone: `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors`
  → 4 tests, 0 failures (exit 0).
- Full suite: `mix test --warnings-as-errors` → **557 tests, 0 failures** (exit 0).
  Baseline was 553; +4 is exactly the meta-gate's four tests.
- No assertion was weakened; no skip/exclude added to force green.

## Constraints honored

- `lib/relyra/security/*` untouched (D-10 frozen verifier) — verified via
  `git diff --name-only 23741b0 HEAD`: only `mix.exs`,
  `test/security/ci_gate_integrity_test.exs`, and
  `.github/workflows/security-gates.yml` changed.
- STATE.md / ROADMAP.md untouched (orchestrator-owned).
- Worktree HEAD safety re-asserted before work (branch
  `worktree-agent-ad82174dd00b717ad`, baseline `23741b0`); atomic commits in the
  worktree.

## Commits

- `8a144ed` fix(30-04): make ci.security honestly gate every security suite (cmd mix test per line)
- `72cd726` test(30-04): add anti-hollow ci.security meta-gate (T-30-14 structural)
- `ef6eec6` ci(30-04): document gate02_c14n step as intentional belt-and-suspenders
- (this) docs(30-04): complete honest-gate fix (SUMMARY.md)
