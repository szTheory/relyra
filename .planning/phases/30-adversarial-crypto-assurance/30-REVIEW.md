---
phase: 30-adversarial-crypto-assurance
reviewed: 2026-05-24T19:05:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - lib/relyra/test_support/fake_idp.ex
  - mix.exs
  - priv/security_corpus.json
  - test/security/ci_gate_integrity_test.exs
  - test/security/xml/adversarial_crypto_test.exs
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 30: Code Review Report

**Reviewed:** 2026-05-24T19:05:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 30 promotes `FakeIdP.sign/2` to delegate to the genuine `XmldsigSigner`
(real digest + RSA signature), adds a permanent `:adversarial_crypto`-gated
corpus suite, adds a c14n-differential corpus row, fixes the `ci.security`
"hollow gate" dedup bug by running each security suite as its own
`cmd mix test`, and adds the `ci_gate_integrity_test.exs` anti-hollow meta-gate.

I verified all six files build under `--warnings-as-errors` and that every
touched test suite passes (adversarial_crypto: 6/6, meta-gate: 4/4, corpus:
7/7). The production verifier (`lib/relyra/security/signature.ex`) was confirmed
unchanged (frozen, D-10), and I traced the adversarial test mutations against
the real `parsed_doc` / candidate shape emitted by `PureBeam` to confirm each
negative control reaches its claimed typed error for the right reason.

No correctness bugs that produce wrong runtime behavior were found. However, the
adversarial stance surfaced **five WARNING-level defects concentrated in the
anti-hollow machinery itself** — the very layer whose job is to prevent a
falsely-green gate. The meta-gate's mix.exs parser and tag-integrity check are
both weaker than their docstrings claim, the meta-gate has a coverage gap
(`corpus_gate_test.exs` is wired into `ci.security` but unguarded), and the new
corpus row is a functional duplicate of an existing row that proves nothing about
c14n differentials. None are exploitable today, but each erodes the assurance
guarantee this phase exists to establish, and each fails *open* (stays green)
under a plausible future edit — the worst failure mode for a security gate.

## Warnings

### WR-01: Meta-gate mix.exs bracket scanner is string/comment-unaware and misparses on a lone `[`/`]`

**File:** `test/security/ci_gate_integrity_test.exs:63-78`
**Issue:** `scan_block/4` counts every `[` and `]` byte indiscriminately,
including brackets inside string literals and `#` comments. The `ci.security`
alias block is a region the meta-gate deliberately encourages humans to edit
(comments documenting why each step exists). A future comment or step string
containing a lone `]` (e.g. `# pipeline stage ] of 3`, a markdown list, a CLI
flag, or a grep pattern like `grep -nE "]"`) terminates the captured block
EARLY, dropping every later `cmd mix test` line out of scope. A lone `[`
over-captures past the alias into the next alias's steps. I reproduced both
directions: a lone `]` in a comment truncated the block before the
`adversarial_crypto` step. Today the block contains no stray brackets so it
parses correctly, but the guard is brittle exactly where edits are expected.
Note the truncation direction tends to fail *loud* (a dropped suite makes "every
gated suite is named in the alias" fail), but the over-capture direction can
pull another alias's BARE `test` line into scope and is order-dependent.
**Fix:** Parse mix.exs as actual Elixir instead of byte-scanning, which is both
correct and simpler:
```elixir
defp ci_security_steps do
  {aliases, _} = Code.eval_string(File.read!("mix.exs"))
  # or, more robustly, extract via Code.string_to_quoted! and walk the AST:
  {:ok, ast} = Code.string_to_quoted(File.read!("mix.exs"))
  # find the `"ci.security": [...]` keyword entry and return its list of strings
end
```
If AST parsing is too heavy, at minimum strip `#` comment tails per line before
scanning and document that step strings must not contain unbalanced brackets.

### WR-02: Tag-integrity check uses substring match — a prefix tag passes while matching zero tests

**File:** `test/security/ci_gate_integrity_test.exs:136`
**Issue:** The tag-integrity test asserts
`source =~ "@tag :#{tag}" or source =~ "@moduletag :#{tag}"`. `=~` with a binary
is an unanchored substring match. If `ci.security` ever ran `--only security`
(a prefix of the real `:security_corpus` tag), the check would PASS because
`"@tag :security"` is a substring of `"@tag :security_corpus"` — yet
`mix test --only security` matches ZERO tests, leaving the gate hollow. This is
the precise failure the test claims to prevent ("`--only <tag>` would silently
match ZERO tests"). I reproduced the false-green. The test's own value depends on
token-exact matching.
**Fix:** Anchor on a token boundary:
```elixir
assert Regex.match?(~r/@(tag|moduletag)\s+:#{Regex.escape(tag)}\b/, source),
       "ci.security runs #{path} with `--only #{tag}` but the file declares no " <>
         "exact `@tag :#{tag}` / `@moduletag :#{tag}`"
```

### WR-03: Meta-gate coverage gap — `corpus_gate_test.exs` is wired into ci.security but not in @gated_suites

**File:** `test/security/ci_gate_integrity_test.exs:32-39`, `mix.exs:170`
**Issue:** `ci.security` runs
`cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus` (mix.exs:170), but the
meta-gate's `@gated_suites` list omits `test/relyra/security/xml/corpus_gate_test.exs`.
The meta-gate therefore does not verify that file is wired, exists, runs via
`cmd mix test`, or that its `security_corpus` tag exists. Dropping
`corpus_gate_test.exs` from the alias (or removing its tag) leaves the
anti-hollow meta-gate green — a hollow gate the meta-gate was built to catch.
**Fix:** Add the missing suite to the contract:
```elixir
@gated_suites [
  # ...existing entries...
  {"test/relyra/security/xml/corpus_gate_test.exs", "security_corpus"}
]
```

### WR-04: New corpus row `c14n-differential-rejection-002` proves nothing it claims — functional duplicate of c14n-differential-001

**File:** `priv/security_corpus.json:107-121`
**Issue:** The row's `class` is `parser_differential_and_c14n`, which the corpus
evaluator routes through `PureBeam.canonicalize(parsed_doc, [])`
(`corpus_security_test.exs:188`) passing the FULL `parsed_doc` map. That map has
no top-level `:node` key, so it hits the `canonicalize(_handle, _opts)` catch-all
fallback (`pure_beam.ex:509`) and returns `:canonicalization_failed`
unconditionally — I verified this returns `:canonicalization_failed` for the row.
The XML content (SignatureMethod, `assertion-c14n-diff`, the whole document) is
NEVER exercised: ANY well-formed XML in this class produces the identical result.
The row is therefore byte-for-result identical to the pre-existing
`c14n-differential-001` (lines 62-76) and adds zero discriminating power, despite
a 4-line `notes` block describing a "C14N-differential REJECTION." The note even
admits the real proof "lives in the adversarial_crypto suite." A corpus row that
cannot distinguish a passing implementation from a broken one is anti-assurance:
it inflates the gate's apparent coverage while testing nothing new.
**Fix:** Either (a) remove the row as redundant, or (b) make it genuinely route a
*single bound candidate handle* (the shape `select_signed_node` returns) through
`canonicalize` so the C14N engine actually runs on differential input, or (c) if
the intent is a crypto-level differential, move it to the adversarial_crypto
suite where it can drive `Signature.verify/4` to `:digest_mismatch` over a real
post-sign C14N-preserved mutation (as the existing D-06 case already does).

### WR-05: `:binary.match` anchor for the ci.security block can latch onto a comment occurrence

**File:** `test/security/ci_gate_integrity_test.exs:45-52`
**Issue:** The block extractor uses `:binary.match(source, "\"ci.security\": [")`
which returns the FIRST occurrence. Today only the alias definition matches that
exact `: [` form (the `cli/0` preferred-env entry uses `: :test`), so it is
unambiguous. But a future comment or doc string in mix.exs containing the literal
`"ci.security": [` would shadow the real alias, and the scanner would extract the
wrong region. Combined with WR-01's bracket fragility, the extractor has two
independent ways to slice the wrong text.
**Fix:** Anchor to the alias context unambiguously, e.g. match within the
`aliases/0` return only, or (preferably) adopt the AST approach from WR-01 which
eliminates string anchoring entirely.

## Info

### IN-01: `idx` accumulator in `scan_block/4` is dead state

**File:** `test/security/ci_gate_integrity_test.exs:63,76`
**Issue:** `idx` is threaded (`idx + 1`) through every recursion but never read in
any base case or result — it contributes nothing. It reads as if a position is
being tracked, but it is purely vestigial. (Not a compiler "unused" warning
because it is referenced in the recursive call.)
**Fix:** Drop the `idx` parameter entirely; `scan_block(tail, new_depth, acc)`.

### IN-02: `FakeIdP.metadata/0` calls `ensure_keypair!/0` but never uses a key

**File:** `lib/relyra/test_support/fake_idp.ex:35`
**Issue:** `metadata/0` emits a static `<EntityDescriptor>` with no signature and
no key material, yet calls `ensure_keypair!()`. The call is harmless (idempotent,
side-effecting persistent_term init) but misleading — it implies the metadata is
key-derived when it is not.
**Fix:** Remove the `ensure_keypair!()` call from `metadata/0`, or add a comment
that it is a deliberate eager-init.

### IN-03: FakeIdP positive-control XML shape diverges from XmldsigSigner negative-control shape

**File:** `lib/relyra/test_support/fake_idp.ex:121-144` vs `lib/relyra/test_support/xmldsig_signer.ex:236-264`
**Issue:** The positive control (`FakeIdP.sign`) emits `<Assertion>` with an
inherited `xmlns="urn:oasis:...:assertion"` and assertion ID `assertion_123`,
while every negative control drives `XmldsigSigner.signed_response/1` which emits
a *different* shape (no namespace on Assertion, ID `assertion-1`). Both verify
correctly because each digest is computed over its own emitted bytes, so this is
not a bug. But it means the positive and negative cases never exercise the same
document shape, so a shape-specific verifier regression could pass the positives
and fail to be caught by the (differently-shaped) negatives or vice versa.
**Fix:** Optional: have the positive control reuse `XmldsigSigner.signed_response/1`
so positives and negatives share one canonical shape, isolating the variable
under test to the mutation alone.

### IN-04: Workflow backstop covers only gate02_c14n, not the new adversarial_crypto suite

**File:** `.github/workflows/security-gates.yml:79-80`
**Issue:** The belt-and-suspenders standalone step re-runs `--only gate02_c14n`
independent of the `ci.security` alias, but there is no equivalent standalone
backstop for `--only adversarial_crypto`. If `ci.security` regressed and dropped
the adversarial_crypto line, the only structural guard is the meta-gate that runs
*inside* the same alias — which would itself be skipped by the same dedup
regression. The adversarial suite is the headline deliverable of this phase and
has weaker defense-in-depth than the C14N gate.
**Fix:** Optional: add a second standalone workflow step
`mix test --only adversarial_crypto --warnings-as-errors`, mirroring the
gate02_c14n backstop, so a hollowed alias cannot silently skip the new suite.

---

_Reviewed: 2026-05-24T19:05:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
