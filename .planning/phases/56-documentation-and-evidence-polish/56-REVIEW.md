---
phase: 56-documentation-and-evidence-polish
reviewed: 2026-06-13T03:40:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - mix.exs
  - test/docs/demo_guide_drift_test.exs
  - test/docs/markdown_link_smoke_test.exs
  - demo/ledger_loop/README.md
  - guides/demo.md
  - README.md
  - guides/getting_started.md
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 56: Code Review Report

**Reviewed:** 2026-06-13T03:40:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 56 is documentation-and-evidence polish: a rewritten demo README, a thin
`guides/demo.md` ExDoc pointer, a new bidirectional `scripts/demo` drift gate, and a
hardened markdown link-smoke test, all wired into the `ci.docs` Mix alias.

**The security-critical invariants all hold.** The Phase 30 hollow-gate convention is
preserved: the new drift test runs as its own dedicated `cmd mix test` process line in
`ci.docs` (mix.exs:222), is NOT folded into a bare `test` step, and is NOT added to
`ci.demo_app`. The demo README leaks no PEM, raw SAML XML, or secrets and contains no
instruction to weaken any validation gate. `guides/demo.md` uses an absolute GitHub URL
(no `../demo/` relative link). The `README.md` install snippet `{:relyra, "~> 1.5"}` and
`## Start Here` router are intact, as is `guides/getting_started.md`. I verified both new
tests run green (5 tests, 0 failures) and traced the regexes against the real
`scripts/demo` and `demo/ledger_loop/README.md`.

The findings below are about the *robustness of the new gates*, not the docs they guard.
The drift gate is currently green and correct for the present script, but two of its
extraction patterns can drift silent (fail-green) under realistic future edits — which
defeats the entire reason a drift gate exists. These are Warnings, not Critical, because
no current source triggers them.

## Warnings

### WR-01: Drift gate silently drops multi-token `case` arms (fail-green hollow direction)

**File:** `test/docs/demo_guide_drift_test.exs:82` (`@case_arm_pattern ~r/^\s+(\w+)\)\s*$/m`)
**Issue:** The canonical subcommand set is built by matching single-token case arms only.
A combined arm — e.g. consolidating `up)` and `start)` into `up|start)`, a routine bash
refactor — matches the pattern for *neither* token. I verified this empirically: a script
with an `up|start)` arm yields a canonical set that omits both `up` and `start`. Because the
gate's parity check is `MapSet.difference(script_subcommands, doc_subcommands)`, dropping a
subcommand from the *script* side means the README can also drop it (or never document it)
and the test stays **green**. This is the exact silent-rot failure mode the gate was built
to prevent (moduledoc lines 8-13), just relocated one layer up. The current `scripts/demo`
has no multi-token arms, so the gate is correct today; this is a latent fail-green that a
future maintainer cannot see.
**Fix:** Split alternation tokens before building the set, so each subcommand in a combined
arm is still enumerated:
```elixir
# Match the whole arm label (may contain `|`), then split into individual tokens.
@case_arm_pattern ~r/^\s+([\w|]+)\)\s*$/m

defp extract_script_subcommands do
  @script_path
  |> File.read!()
  |> then(&Regex.scan(@case_arm_pattern, &1, capture: :all_but_first))
  |> Enum.flat_map(fn [label] -> String.split(label, "|", trim: true) end)
  |> MapSet.new()
end
```

### WR-02: Drift gate counts documented commands only inside ```bash fences — other shell fence languages fail-loud-then-get-suppressed

**File:** `test/docs/demo_guide_drift_test.exs:143` (`extract_bash_blocks/1`, `~r/```bash\n(.*?)```/s`)
**Issue:** The documented-set scan only reads fences opened with exactly ` ```bash `. I
verified that ` ```sh `, ` ```shell `, and ` ```console ` blocks — all common and equally
valid ways to show shell commands — are invisible to the scan. The immediate effect is a
false-positive (missing-in-doc) failure if an author documents a subcommand in a `sh`
fence, which is annoying but loud. The dangerous second-order effect: the natural author
response to that false failure is to *duplicate* the command into a `bash` fence or relax
the gate — and if a maintainer instead "fixes" the brittleness by widening the fence regex
incorrectly, the parity guarantee weakens. Additionally, ` ```bash ` with a trailing space
on the fence line (` ```bash \n`) or CRLF line endings is not matched at all — I verified
both yield zero blocks — which would silently drop *all* documented commands in that block
and could flip a real drift into a green pass if it were the only fence. The current README
uses clean ` ```bash\n ` Unix fences throughout, so the gate is green today.
**Fix:** Accept the common shell fence languages and tolerate trailing whitespace / CRLF:
```elixir
~r/```(?:bash|sh|shell|console)[^\n]*\r?\n(.*?)```/s
```

## Info

### IN-01: `scripts/demo <token>` mention pattern is unanchored — over-matches path prefixes and partial tokens

**File:** `test/docs/demo_guide_drift_test.exs:86` (`@doc_mention_pattern ~r/scripts\/demo\s+(\w+)/`)
**Issue:** The pattern is not anchored, so `./scripts/demo up`, `bin/scripts/demo down`,
and `scripts/demo testing` all match (capturing `up`, `down`, and `testing`
respectively — I verified each). A documented `scripts/demo testfoo` typo would be captured
as the token `testfoo` and surface as a stale-in-doc failure (loud, acceptable), but the
path-prefix over-match means a doc that writes `path/to/scripts/demo up` is silently treated
as documenting `up`. Low impact today; worth tightening for precision.
**Fix:** Anchor the command start and add a trailing boundary:
```elixir
@doc_mention_pattern ~r/(?:^|\s|\.\/)scripts\/demo\s+(\w+)\b/
```

### IN-02: `path_in_package_files?/1` prefix match lacks a path-segment boundary (false-positive class)

**File:** `test/docs/markdown_link_smoke_test.exs:167-171`
**Issue:** Membership is tested with `rel_path == prefix or String.starts_with?(rel_path, prefix)`.
For the file-name prefixes (`mix.exs`, `README.md`, `LICENSE`, `CONFORMANCE.md`, …) this
matches by substring-prefix, so `mix.exs.bak`, `README.md-notes`, and `LICENSE-APACHE`
would all be considered "in package" (I verified). No such files exist and the sibling
existence test would still catch genuinely-broken links, so the practical exposure is nil —
but a link to a non-shipped `LICENSE-APACHE` would wrongly pass the D-02c (404) gate.
**Fix:** Require either exact match or a directory-style prefix ending in `/`:
```elixir
defp path_in_package_files?(rel_path) do
  Enum.any?(@package_file_prefixes, fn prefix ->
    rel_path == prefix or
      (String.ends_with?(prefix, "/") and String.starts_with?(rel_path, prefix))
  end)
end
```

### IN-03: `@package_file_prefixes` is a hand-maintained copy of `mix.exs` `package.files` — drift risk

**File:** `test/docs/markdown_link_smoke_test.exs:39-54`
**Issue:** The prefix list duplicates the `files:` entries in `mix.exs:104-119`. If a future
phase adds a directory to `package.files` (or removes one) without updating this constant,
the D-02c gate's notion of "shipped" silently diverges from reality — exactly the
disk-passes/hexdocs-404 class the test was written to close, reintroduced via constant
drift. The `docs/jtbd_gap_map.md` case is *correctly* handled today only because `docs` is
shipped wholesale and the maintainers-only file rides along; that is verified-correct but
fragile to reason about.
**Fix:** Derive the prefixes from `mix.exs` (or add a small assertion test that the constant
is a superset of `Relyra.MixProject` `package.files` entries) so the two cannot drift.

### IN-04: Two pre-existing bare `test` steps in `ci.docs` are dedup-vulnerable (NOT introduced by Phase 56 — flagged adjacent)

**File:** `mix.exs:223-224`
**Issue:** `ci.docs` ends with two bare `test ...` steps (`relyra_batteries_included_test.exs`,
then `relyra_install_test.exs test_support_demo_test.exs`). Mix runs the `test` *task* at
most once per alias invocation regardless of differing args, so the second bare `test` step
risks being silently `:noop` — the same hollow-gate hazard CLAUDE.md and the `ci.security`
comment (mix.exs:238-245) warn about. **Phase 56 did not introduce these** (they predate
commit d896869; the phase 56 drift-test addition correctly uses `cmd mix test`), so this is
out of strict scope, but it sits two lines below the phase 56 edit and is worth a follow-up
verification that both bare suites actually execute.
**Fix:** Convert both to dedicated `cmd mix test ...` lines, matching the `ci.security`
convention and the new drift-test line.

---

_Reviewed: 2026-06-13T03:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
