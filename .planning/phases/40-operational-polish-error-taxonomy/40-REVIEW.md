---
phase: 40-operational-polish-error-taxonomy
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - test/docs/troubleshooting_drift_test.exs
  - guides/troubleshooting.md
  - mix.exs
  - guides/operations/incident_playbook.md
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 40: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Phase 40 is documentation-heavy (one 1202-line operator decoder, one 310-line
incident playbook) plus a single 159-line ExUnit drift gate and a minimal
append-only `mix.exs` change. The drift test passes against `lib/` as it
stands today (verified locally — `mix test test/docs/troubleshooting_drift_test.exs`
reports `1 test, 0 failures`).

Security invariant check (CLAUDE.md): the four "do not touch" seams
(`lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`,
`lib/relyra/security/algorithm_policy.ex`, `lib/relyra/ecto/audit_writer.ex`)
are unmodified by this phase. The `ci.security` alias in `mix.exs` is
byte-identical to the diff base (`git diff` confirms changes only in
`docs/0` extras list and in `ci.docs` step list). The Phase 30
hollow-gate invariant is preserved.

The two findings worth surfacing both center on the drift test's own
correctness contract. One is a false claim in the moduledoc that
mis-documents which regex patterns are load-bearing (a future maintainer
following the moduledoc could safely-looking delete the wrong one). The
other is a soft gate where the test relies on cwd convention rather than
asserting it, which means it could pass trivially under the wrong
invocation context. Both are Warnings, not Blockers.

## Warnings

### WR-01: Multi-line `Error.new(` regex is redundant — moduledoc claim is false

**File:** `test/docs/troubleshooting_drift_test.exs:30-33`, `:79-80`
**Issue:** The moduledoc (lines 30-33) and module attributes (lines 79-80)
distinguish two regexes:

  * `@code_pattern_singleline ~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/`
  * `@code_pattern_multiline  ~r/Error\.new\(\s*\n\s*:([a-z_][a-z0-9_]*)/`

`\s` in Elixir Regex already matches `\n` by default (no `m`/`s` flag
needed for character-class semantics). The singleline pattern therefore
already captures every multi-line constructor that the multiline pattern
captures — verified with a 4-line script against the project's
`Error.new(` corpus: the singleline pattern alone yields the full
canonical atom set; the multiline pattern's captures are a strict subset.

This is a code-correctness concern (not just style) because the
moduledoc explicitly tells future contributors that the multiline
pattern is "heavily used in `lib/relyra/protocol/validation_pipeline.ex`
and `lib/relyra/metadata/auto_refresh.ex`" — implying it captures atoms
the singleline pattern misses. A contributor trusting that claim could
delete the singleline pattern as the "redundant" one and break the
canonical atom enumeration silently (the test would still pass under
today's corpus, but the next single-line `Error.new(:atom, ...)` site
would slip through).

**Fix:** Either drop `@code_pattern_multiline` entirely and reword the
moduledoc to say "the singleline pattern covers single-line and
multi-line constructors because `\s` includes newlines," OR keep both
and reword the moduledoc to acknowledge the multiline pattern is a
defense-in-depth duplicate (not a coverage-gap filler). Recommended
direction is the first — the union semantics in `scan_code_atoms/0`
already dedup via `Enum.uniq/1`, but the duplicate pattern is wasted
work and an active mis-document.

```elixir
# Recommended single-pattern shape:
@code_pattern_call ~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/
@code_pattern_structlit ~r/%Relyra\.Error\{type:\s*:([a-z_][a-z0-9_]*)/

# Moduledoc to update:
# "Two byte-regex patterns are applied to every lib/**/*.ex source file:
#  * Error.new constructor — matches both single- and multi-line forms
#    because Elixir's \s matches newlines.
#  * %Relyra.Error{type: :atom} struct literal."
```

### WR-02: Drift test relies on cwd convention without asserting it

**File:** `test/docs/troubleshooting_drift_test.exs:103`, `:84`
**Issue:** `scan_code_atoms/0` uses `Path.wildcard("lib/**/*.ex")` and
`@doc_path "guides/troubleshooting.md"` — both relative paths. If the
test is ever invoked from a cwd other than the project root (a future
sub-tree test split, a partial-tree IDE runner, or a contributor running
the file directly via `elixir`), `Path.wildcard/1` returns `[]`, the
emitted-atom set is `MapSet.new()`, `scan_doc_atoms/0` returns
`MapSet.new()` (via the `{:error, :enoent}` clause at line 129), both
differences are empty, and the test passes trivially — a hollow gate.

The project's other meta-gate (`test/security/ci_gate_integrity_test.exs`)
uses the same relative-path idiom, so this is consistent with project
convention and `mix test` always runs from project root in the CI lane.
But the cost of explicit `File.cwd!` assertion is one line and removes a
silent-skip class — the same hollow-gate concern that motivated the
Phase 30 `cmd mix test` invariant in `ci.security`.

**Fix:** Add a one-line cwd assertion at the top of `scan_code_atoms/0`,
or convert paths to `Path.expand("lib/**/*.ex", File.cwd!())` with an
explicit "project root expected" comment. Cheapest concrete fix:

```elixir
defp scan_code_atoms do
  # Hollow-gate guard: empty wildcard means we're not at the project root.
  paths = Path.wildcard("lib/**/*.ex")
  assert paths != [],
    "lib/**/*.ex matched zero files — drift test must run from project root"

  paths
  |> Enum.reduce(%{}, fn path, acc ->
    # ...existing body
  end)
end
```

(`assert` inside a private helper works because the helper is called
from the test body; alternatively, hoist the assertion to the test body
before calling the helpers.)

## Info

### IN-01: `## Relyra owns / Host owns` parent H2 is an empty heading

**File:** `guides/troubleshooting.md:28`, `guides/operations/incident_playbook.md:14`
**Issue:** Both new docs use the convention:

```
## Relyra owns / Host owns

## Relyra owns

- ...

## Host owns

- ...
```

The "parent" H2 has no body content and is followed by two sibling H2s
(not H3 children). This is intentional and matches the established
project idiom (also present in `guides/identity_mapping_and_provisioning.md`,
`guides/recipes/logout.md`, `guides/recipes/generic_saml.md`), so it
is not a defect against project convention.

Flagged as Info only because the empty-heading shape rendered by ExDoc /
GitHub is mildly accessible-unfriendly (screen readers announce the
heading then have nothing to read until the next heading). No action
required if the project is committed to this idiom; if a future docs
sweep tightens the convention, these two new files are candidates.

**Fix:** No change required for Phase 40. Track as a project-wide docs
convention question separate from this phase.

### IN-02: ExDoc anchor compatibility for `### :atom_name` H3s is not verified

**File:** `guides/troubleshooting.md` (78 H3 entries) and all cross-links
into them from `guides/operations/incident_playbook.md`
**Issue:** GitHub-flavored markdown and ExDoc generate different anchors
from `### :atom_name` headings. The incident playbook's intra-doc links
use `#atom_name` (no leading `:`), which is GitHub's convention. ExDoc's
behavior for headings starting with `:` is renderer-dependent and may
produce `#:atom_name` or `#atom_name` depending on version. The drift
test does not assert anchor-link integrity — it only enforces that the
H3 text matches the regex.

This is not a defect in Phase 40's surface (the H3 regex is correct
and the doc is internally consistent), but the cross-link target
resolution depends on the markdown formatter. Since `mix.exs:110`
configures both `html` and `markdown` formatters for ExDoc, both
render paths matter.

**Fix:** A quick post-publish sanity check — render docs locally with
`mix docs` and click through one or two of the
`../troubleshooting.md#digest_mismatch`-style links from the incident
playbook to confirm they resolve. If they do not, either (a) switch the
anchor convention to ExDoc's actual output, or (b) drop the leading `:`
from the H3 (e.g., `### digest_mismatch`) and adjust the drift-test
regex to match — which would require regenerating the doc but tightens
anchor-compat.

### IN-03: Pre-existing `ci.docs` hollow-gate (out of Phase 40 scope, but adjacent)

**File:** `mix.exs:161-162`
**Issue:** The two bare `test` steps in `ci.docs`:

```
"test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
"test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
```

per the documented invariant in `ci.security` (lines 178-183: "mix
dedups the `test` task within a single alias run"), the second bare
`test` step is silently dedup'd and does NOT run — `ci.docs` only ever
runs the first `test` invocation's args. This is a pre-existing hollow
gate that **predates Phase 40** (the two lines are unchanged in the
diff). The Phase 40 new test correctly uses `cmd mix test ...` and is
unaffected.

Flagged here only because Phase 40 actively edits this alias and the
sibling meta-gate (`test/security/ci_gate_integrity_test.exs`) only
enforces the invariant on `ci.security`, not on `ci.docs`. A future
ci.docs failure (silent skip of the second test file) would be
attributed to a Phase-40-adjacent change rather than to the underlying
alias shape.

**Fix:** Out of Phase 40 scope. Track as a follow-up to extend the
hollow-gate meta-test to all `ci.*` aliases, OR convert lines 161-162
to `cmd mix test ...` form. Either change is a Phase 41 candidate.

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
