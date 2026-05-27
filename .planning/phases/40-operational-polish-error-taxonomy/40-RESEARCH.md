# Phase 40: Operational Polish & Error Taxonomy - Research

**Researched:** 2026-05-27
**Domain:** Documentation engineering with assertion-by-test drift detection (Elixir/Phoenix library)
**Confidence:** HIGH

## Summary

Phase 40 is a documentation phase with one drift-detection test. Two new
markdown surfaces (`guides/troubleshooting.md` + `guides/operations/incident_playbook.md`)
and one test (`test/docs/troubleshooting_drift_test.exs`) close out v1.4's
operational story. The trust pipeline itself is frozen — no source-code edits
required, no security-invariant changes possible. `mix.exs` is the only Elixir
file that changes (extras list + `ci.docs` alias).

The research surfaced one materially load-bearing correction to CONTEXT.md: the
emitted-atom union under the D-08 three-regex protocol is **78 distinct atoms**
across 33 modules, not the ~60 estimate. Three modules
(`lib/relyra/protocol/logout_request.ex`, `lib/relyra/protocol/logout_response.ex`,
`lib/relyra/security/xml/pure_beam.ex`) emit through a variadic
`require_present_fields/4` helper where `error_type` is a function parameter —
the D-08 regexes will NOT match those construction sites, but every atom they
fan out to is independently covered via a literal `Error.new(:atom, ...)` site
in another module, so the canonical set is intact. The planner should still
flag this so anyone adding a new atom-via-helper site without a literal companion
site won't silently bypass the drift gate.

Everything else in CONTEXT.md (D-01..D-19) checks out against the codebase:
mix.exs structure, telemetry namespace, audit-writer call topology, LiveAdmin
routes, mix-task inventory, the predecessor-guide idiom, and the
`ci_gate_integrity_test.exs` failure-message vocabulary.

**Primary recommendation:** Plan in two parallel waves — Wave 1 ships the
troubleshooting decoder + the drift-check test (DOCS-06) as one atomic
deliverable (the test gates the doc, so they must land together), Wave 2 ships
the incident playbook (DOCS-05). Wire mix.exs and `ci.docs` once in Wave 1
(presence guard + drift test), append the playbook presence guard in Wave 2.
The 78-atom set is the source-of-truth count; write the test FIRST, run it
against an empty `guides/troubleshooting.md` to enumerate the gap, then author
the decoder to satisfy the gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Troubleshooting decoder (`guides/troubleshooting.md`) | Static asset (in-repo markdown) | ExDoc extras | Pure documentation surface; ExDoc renders it into hexdocs.pm at publish time. |
| Incident playbook (`guides/operations/incident_playbook.md`) | Static asset (in-repo markdown) | ExDoc extras | Same as above. New `guides/operations/` subdirectory under existing `guides/` tree. |
| Drift-check test (`test/docs/troubleshooting_drift_test.exs`) | Build-time gate (ExUnit) | CI alias (`ci.docs`) | Runs in BEAM at `mix test` time; reads `lib/**/*.ex` source bytes + `guides/troubleshooting.md` body via `File.read!` — pure source-of-truth comparison. No runtime dependency. |
| Presence guards (`cmd test -f ...`) | Build-time gate (POSIX shell via mix `cmd`) | CI alias (`ci.docs`) | OS-level file existence check; delete-protector for the drift test. Runs BEFORE drift test so a missing file surfaces as `test -f` failure, not a confusing "zero atoms matched" regex result. |
| `mix.exs` extras + `ci.docs` alias edits | Build configuration (Elixir AST in `mix.exs`) | — | ExDoc publishing surface + CI alias wiring. Same file edited in two distinct keyword entries (`docs/extras:` list + `aliases/0` `ci.docs` list). |

**Why this matters here:** Every capability in Phase 40 is build-time or
static-asset — no runtime concerns, no security invariants, no behaviour-callback
changes. The architectural tier discipline this phase enforces is therefore
purely "does the right thing run at the right CI step": presence guards
BEFORE drift test, drift test under `ci.docs` (not `ci.security`), extras list
deterministically ordered for ExDoc stability.

## User Constraints (from CONTEXT.md)

### Locked Decisions

All 19 decisions (D-01..D-19) in CONTEXT.md are LOCKED. Highlights with binding
implications for planning:

- **D-01:** Publish at `guides/troubleshooting.md` (root, not `guides/operations/`).
- **D-02:** 8 domain-grouped sections, mirroring the trust-pipeline seam taxonomy from CLAUDE.md.
- **D-03:** Every documented atom uses `### :atom_name` H3 heading — no decoration, no trailing punctuation.
- **D-04:** Four-field micro-block: Means / Likely root cause / Operator action / Source.
- **D-05:** Canonical atom set is "~60" per CONTEXT.md — **CORRECTED by this research to 78** (see Step 1 finding). Planner must use 78 as the lock count.
- **D-06:** New test module at `test/docs/troubleshooting_drift_test.exs`; create `test/docs/` directory.
- **D-07:** No `@known_types` attribute on `Relyra.Error` — single source of truth (the codebase).
- **D-08:** Three-regex atom enumeration (single-line, multi-line, struct-literal) applied to `lib/**/*.ex`.
- **D-09:** Doc enumeration: `~r/^### :([a-z_][a-z0-9_]*)\b/m`.
- **D-10:** Bidirectional assertion with failure-message style mirroring `test/security/ci_gate_integrity_test.exs`.
- **D-11:** Drift test runs under `ci.docs`, NOT `ci.security`. `@gated_suites` and `ci.security` alias untouched.
- **D-12:** Playbook at `guides/operations/incident_playbook.md`; create `guides/operations/` directory.
- **D-13:** Document spine inherits the Phase 36/37/39 idiom — brand-voice → trust-boundary preamble → reference table → scenario runbooks → closing pointer.
- **D-14:** Five-surface reference table (telemetry / audit / LiveView admin / Mix tasks / troubleshooting decoder).
- **D-15:** Six scenario-anchored runbooks (cert expiry, metadata drift, replay storm, signature regression, ACS misconfig, attribute mapping).
- **D-16:** Closing pointer: `mix relyra.diagnostic` as first-resort.
- **D-17:** `mix.exs` extras append order: `guides/troubleshooting.md`, then `guides/operations/incident_playbook.md`, after the existing `guides/recipes/logout.md` line.
- **D-18:** Append both presence guards to `ci.docs` alias after `cmd test -f guides/recipes/logout.md` line.
- **D-19:** Drift test as a separate `cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` line AFTER both presence guards.

### Claude's Discretion

- Exact prose, table layouts, operator-action wording within the four-field micro-block contract (D-04) and five-surface contract (D-14).
- Per-domain section preambles in `guides/troubleshooting.md` — one-sentence trust-boundary callout recommended but layout-level.
- Whether the five-surface table appears once at the top of the playbook or splits across scenarios — single top-of-doc placement recommended.

### Deferred Ideas (OUT OF SCOPE)

- `Relyra.Error.known_types/0` runtime introspection helper — rejected per D-07.
- Auto-generated troubleshooting guide from `@moduledoc` — out of scope; Phase 40 ships hand-authored prose.
- Standalone telemetry event catalog page — playbook cites events inline.
- LiveView admin "incident dashboard" view — out of scope; UI work belongs to a follow-on phase.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-05 | Publish `guides/operations/incident_playbook.md` providing a narrative playbook that stitches together telemetry, audit events, the LiveView admin, and Mix tasks. | Five-surface table content verified: telemetry namespace (Step 3), audit `@domain_values`+`@action_values` (Step 4), LiveAdmin routes (Step 5), Mix tasks inventory (Step 6). Doc-idiom precedents verified in `guides/recipes/logout.md` and `guides/recipes/generic_saml.md` (Step 9). |
| DOCS-06 | Publish `guides/troubleshooting.md` acting as a SAML error atom decoder, paired with an automated drift-check test. | Canonical atom set enumerated (Step 1): 78 atoms across 33 modules. Drift-check regex set validated against codebase (Step 7) — one edge-case flagged (variadic helper). Failure-message vocabulary mirror confirmed (Step 10). Test-path bootstrapping confirmed (Step 11): `test/docs/` is green-field, `test_helper.exs` requires no changes (ExUnit auto-discovers any `test/**/*_test.exs`). |

## Standard Stack

This phase introduces ZERO new dependencies — it uses only what's already
in `mix.exs`.

### Core (in-tree, already present)
| Module / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | OTP-bundled | Test framework for the drift-check test | Idiomatic Elixir test framework; already used by all 525+ existing tests. `use ExUnit.Case, async: true` is the project's default pattern (verified `test/security/strict_default_proof_test.exs:2`). |
| `File.read!/1` | Elixir stdlib | Read source files + doc file from disk in the drift test | Avoids `Code.eval_file` / `Macro.expand` complexity. The drift check is byte-level pattern matching on file contents — no AST traversal needed. |
| Regex (`Regex.scan/2`) | Elixir stdlib | Enumerate atom literals from source bytes | Pure-string pattern. The three D-08 patterns are byte-regex, not AST queries; this is intentional (no compile-time evaluation needed; no Mox/meck). |
| `Path.wildcard/1` | Elixir stdlib | Walk `lib/**/*.ex` | Standard library convention for recursive file enumeration. |
| ExDoc | `~> 0.0.0` (dev only, already in `mix.exs:67`) | Renders the two new guides as hexdocs.pm extras at release time | Already wired; Phase 40 only appends two entries to the `extras:` list in `docs/0`. |

### Supporting (mix-level)
| Tool | Purpose | When to Use |
|---------|---------|-------------|
| `mix cmd test -f <path>` | Presence guard for each guide file | Runs as `ci.docs` step before the drift test. POSIX `test -f` returns non-zero (failing the alias) if the file is missing, surfacing a clean "file deleted" error instead of letting the drift test fail with `0 atoms == 0 atoms` confusion (D-18 contract). |
| `mix cmd mix test <suite>` | Run drift test in its own OS process under `ci.docs` | Matches Phase 30 hollow-gate fix style (CLAUDE.md "Testing Requirements"). Even though `ci.docs` doesn't run `ci.conformance` first (so dedup isn't a hazard here), using `cmd mix test` keeps the alias-step style consistent with `ci.security` and prevents future drift if the alias is reorganized. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Three D-08 regex patterns | Compile-time AST traversal of `lib/**/*.ex` via `Code.string_to_quoted!/1` + `Macro.prewalker/1` | AST is more precise (captures `Error.new(error_type, ...)` variable-argument sites if a `case`/`with` block enumerates the variable). But it's heavier, slower, and the variable-argument sites in this codebase already have literal companion sites elsewhere — see Step 7 finding. Regex is sufficient. |
| `@known_types` attribute on `Relyra.Error` (compile-time lock) | Single declarative source of truth; drift test asserts emitted-atom ⊆ `@known_types` AND docs ⊆ `@known_types` | Rejected by D-07: creates a second source of truth that itself drifts. The codebase remains the only emitter authority. |
| Adding drift test to `ci.security` | Co-locate with `ci_gate_integrity_test.exs` (both are meta-tests over CI structure) | Rejected by D-11: requires amending `@gated_suites` for zero security benefit and miscategorizes a doc failure as a security-lane failure. |

**Installation:** No `mix deps.get` step needed — Phase 40 adds no Hex dependencies.

**Version verification:** N/A (no new external packages).

## Package Legitimacy Audit

> SKIPPED — Phase 40 installs zero external packages. No new Hex dependencies,
> no npm/pip/cargo packages, no MCP servers, no global CLI installs. Every
> tool used (ExUnit, ExDoc, regex, `File.read!`, `Path.wildcard`, `mix cmd`)
> is either in OTP/Elixir stdlib or already in `mix.exs` as of `1.2.0`.

## Architecture Patterns

### System Architecture Diagram

```
                       ┌─────────────────────────────────┐
                       │   AUTHOR (humans + Claude)      │
                       └────────────┬────────────────────┘
                                    │ edits
                                    ▼
              ┌───────────────────────────────────────┐
              │       SOURCE OF TRUTH (lib/)          │
              │  Error.new(:atom, ...)                │
              │  Error.new(\n  :atom, ...)            │ ← three patterns
              │  %Relyra.Error{type: :atom, ...}      │
              └────────┬──────────────────────────────┘
                       │ scanned at test time by
                       │ three D-08 regexes
                       ▼
            ┌─────────────────────────────────┐         ┌──────────────────────────────┐
            │  code_atoms = MapSet of 78      │◄───────►│  doc_atoms = MapSet from     │
            │  emitted atoms (union of 3 pats)│         │  ^### :atom_name H3 headings │
            └──────────────┬──────────────────┘         └──────────────┬───────────────┘
                           │                                           │
                           │            ┌──────────────────┐           │
                           └───────────►│  bidirectional   │◄──────────┘
                                        │  set comparison  │
                                        │  (drift test)    │
                                        └────┬─────────────┘
                                             │
                       ┌─────────────────────┴───────────────────┐
                       │                                         │
                       ▼                                         ▼
            FAIL: code\doc != []                    FAIL: doc\code != []
            "Missing doc entry for: :foo            "Stale doc entry for: :bar
            — add ### :foo section to               — atom no longer emitted by
            guides/troubleshooting.md               Relyra; remove from
            (source: lib/path/file.ex)"             troubleshooting.md or re-
                                                    introduce in lib/"

                                            ▲
                                            │ runs UNDER ci.docs alias
                                            │
                       ┌────────────────────┴────────────────────┐
                       │       ci.docs alias (mix.exs)           │
                       │  1. cmd test -f BATTERIES_INCLUDED.md   │
                       │     ... (existing presence guards)      │
                       │  2. cmd test -f guides/recipes/logout.md│ ← anchor
                       │  3. cmd test -f guides/troubleshooting.md  │ NEW (D-18)
                       │  4. cmd test -f guides/operations/incident_playbook.md │ NEW (D-18)
                       │  5. cmd mix test test/docs/troubleshooting_drift_test.exs ... │ NEW (D-19)
                       │  6. (existing test invocations)         │
                       │  7. relyra.batteries_included --check   │
                       └─────────────────────────────────────────┘

  PARALLEL PRODUCT: incident_playbook.md cites five evidence surfaces
  ─────────────────────────────────────────────────────────────────
  (1) lib/relyra/telemetry.ex      → telemetry event names
  (2) lib/relyra/ecto/audit_event.ex → @domain_values, @action_values
  (3) lib/relyra/live_admin/router.ex → admin route paths
  (4) lib/mix/tasks/relyra.*.ex     → 7 operator hand-tools
  (5) guides/troubleshooting.md     → atom decoder cross-link
```

### Recommended Project Structure (Phase 40 deltas only)
```
.
├── guides/
│   ├── troubleshooting.md                      # NEW — DOCS-06
│   └── operations/                              # NEW directory
│       └── incident_playbook.md                # NEW — DOCS-05
├── test/
│   └── docs/                                    # NEW directory
│       └── troubleshooting_drift_test.exs      # NEW — DOCS-06 gate
└── mix.exs                                      # MODIFIED — extras + ci.docs
```

### Pattern 1: Read-then-compare drift detection
**What:** Read raw source bytes from `lib/**/*.ex`, apply three regex patterns,
build a MapSet of literal atoms. Read raw bytes from `guides/troubleshooting.md`,
apply one H3-anchored regex, build a MapSet of documented atoms. Assert
bidirectional set equality via `MapSet.difference/2`.

**When to use:** When the goal is to prove documentation-vs-code parity and
both sides have a stable textual representation. Heavier alternatives (AST
traversal, compile-time hooks) buy more precision than this domain needs and
introduce churn risk.

**Example sketch (planner-discretion; not a contract):**
```elixir
defmodule Relyra.Docs.TroubleshootingDriftTest do
  use ExUnit.Case, async: true

  @code_pattern_singleline ~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/
  @code_pattern_multiline ~r/Error\.new\(\s*\n\s*:([a-z_][a-z0-9_]*)/
  @code_pattern_structlit ~r/%Relyra\.Error\{type:\s*:([a-z_][a-z0-9_]*)/
  @doc_pattern ~r/^### :([a-z_][a-z0-9_]*)\b/m

  test "every emitted :error_type atom has a documented decoder entry, and vice versa" do
    code_atoms = scan_code_atoms()
    doc_atoms = scan_doc_atoms()

    missing_in_doc = MapSet.difference(code_atoms, doc_atoms)
    stale_in_doc = MapSet.difference(doc_atoms, code_atoms)

    # Failure-message vocabulary mirrors test/security/ci_gate_integrity_test.exs
    # (em-dash, names-the-file, explains-the-consequence).
    assert MapSet.size(missing_in_doc) == 0,
           format_missing(missing_in_doc)

    assert MapSet.size(stale_in_doc) == 0,
           format_stale(stale_in_doc)
  end

  defp scan_code_atoms do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(fn path ->
      source = File.read!(path)

      [@code_pattern_singleline, @code_pattern_multiline, @code_pattern_structlit]
      |> Enum.flat_map(&Regex.scan(&1, source, capture: :all_but_first))
      |> Enum.map(fn [atom_name] -> String.to_atom(atom_name) end)
    end)
    |> MapSet.new()
  end

  defp scan_doc_atoms do
    "guides/troubleshooting.md"
    |> File.read!()
    |> then(&Regex.scan(@doc_pattern, &1, capture: :all_but_first))
    |> Enum.map(fn [atom_name] -> String.to_atom(atom_name) end)
    |> MapSet.new()
  end

  defp format_missing(missing), do: # ...em-dash, source paths, action
  defp format_stale(stale), do: # ...em-dash, action
end
```

### Anti-Patterns to Avoid

- **`@known_types` module attribute on `Relyra.Error`:** Creates a second
  source of truth requiring its own drift gate. D-07 rejects this.
- **Bare `test` step in `ci.docs`:** Same hollow-gate hazard as `ci.security`
  (Phase 30) — mix dedups `test`. Use `cmd mix test ...` for the drift
  invocation per D-19.
- **Drift test under `ci.security`:** Miscategorizes a docs failure as a
  security failure; forces `@gated_suites` amendment for zero security
  benefit. D-11 rejects this.
- **`Code.eval_file` or `Macro.expand` instead of regex:** Heavier; brings in
  compilation concerns; brittle against module-name changes. Byte-regex is
  sufficient given the literal-emission contract.
- **Skipping presence guards (D-18):** Without presence guards, deleting
  `guides/troubleshooting.md` would pass the drift test vacuously (0 doc
  atoms ∩ 0 code atoms = trivially equal). The presence guard is the real
  delete-protector.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atom-set comparison | Custom diff algorithm with sorted lists | `MapSet.difference/2` | Stdlib; correct; symmetric. |
| Source-file enumeration | Recursive `File.ls!/1` walker with extension filter | `Path.wildcard("lib/**/*.ex")` | Stdlib; one-liner; glob semantics match exactly what's needed. |
| Source scanning | AST traversal via `Code.string_to_quoted!/1` + walker | `Regex.scan/3` with three D-08 patterns | The literal-emission contract makes regex correct AND simpler. AST is appropriate when you need scope-resolution, not when you need to find literal atom positions. |
| Documentation generation | Mix task that auto-generates `guides/troubleshooting.md` from `@moduledoc`s | Hand-authored prose, gated by the drift test | Out of scope per Deferred Ideas. Generated content has a different character (API reference) than the operator narrative this guide must be. |
| ExDoc extras ordering | Custom alphabetical sort at build time | Hand-curated extras list in `mix.exs` `docs/0` | ExDoc renders extras in the literal order they appear in the list. D-17 locks the order (`troubleshooting.md` before `incident_playbook.md`) for deterministic hexdocs.pm ordering across releases. |
| Failure-message style for the drift test | Custom format | Mirror `test/security/ci_gate_integrity_test.exs` em-dash style | D-10 locks the vocabulary. CI experience consistency across hollow-gate-style meta-tests. |

**Key insight:** Phase 40 is intentionally minimal. The temptation will be to
"productize" the drift check (`@known_types` attribute, runtime introspection
helper, auto-generated docs). All three are explicitly deferred. Ship the
78-atom decoder + the playbook + the test, in that order.

## Common Pitfalls

### Pitfall 1: Forgetting that the variadic helper sites don't match D-08 regexes
**What goes wrong:** A future contributor adds a NEW atom whose ONLY emission
site is through `require_present_fields/4` in `logout_request.ex`,
`logout_response.ex`, or `pure_beam.ex`. The drift test passes (no literal
`Error.new(:that_atom, ...)` exists in `lib/`), the doc entry is never required,
and operators see an undocumented atom in production logs.

**Why it happens:** The three D-08 patterns match LITERAL atom arguments, not
variable arguments. The variadic helpers exist precisely because three modules
share a "required-field-missing" code path; their three call sites pass literal
atoms (`:missing_protocol_field`, `:missing_signature`) but the construction
inside the helper uses the variable.

**How to avoid:** Two options for the planner to choose between:
1. **Document the rule in the test moduledoc:** "Every atom emitted by Relyra
   MUST appear as a literal `Error.new(:atom, ...)` at least once somewhere
   in `lib/`. Variadic helpers are fine but must have a literal companion
   site." This is the lowest-friction option; the current 78 atoms all
   satisfy it.
2. **Add a 4th regex in D-08:** `~r/^\s*:([a-z_][a-z0-9_]*)\s*,\s*$/m` applied
   to the call sites of `require_present_fields` would catch the positional
   atom argument. But this would also produce many false positives across
   the codebase (any `case`-clause atom on its own line). Not recommended.

**Warning signs:** Reviewer sees a new atom in the Means/Source row of a
new doc entry but no `Error.new(:that_atom, ...)` site appears in `git grep`.
That's the signal it was added only via a variadic helper.

### Pitfall 2: Atom typo silently passes the drift test
**What goes wrong:** Author writes `### :missing_signiture` (typo) in
`guides/troubleshooting.md`, and adds `Error.new(:missing_signiture, ...)`
in `lib/relyra/security/signature.ex` (same typo). The drift test passes
because both sides agree. Operators see `:missing_signiture` in production.

**Why it happens:** Drift detection is consistency, not correctness. The
test asserts that the doc matches the code; it cannot detect that both are
wrong in the same way.

**How to avoid:** Code review for new atom names. `@type t :: %Relyra.Error{type: atom()}`
in `lib/relyra/error.ex:11` already permits arbitrary atoms — there's no
compile-time spelling gate. Reviewer discipline is the only mitigation.

**Warning signs:** Spelling that looks unusual; atoms that don't fit the
naming convention (lowercase snake_case ASCII).

### Pitfall 3: Doc heading drift (H3 form deviation)
**What goes wrong:** Author writes `### `:missing_signature`` (backticks
around the atom for prose styling) or `### :missing_signature — what it means`
(decoration after the atom). The drift test's D-09 regex
`~r/^### :([a-z_][a-z0-9_]*)\b/m` parses both correctly (the `\b` boundary
allows trailing decoration) — but only the second form lets readers scan
the doc; the first breaks the regex anchor entirely.

**Why it happens:** Markdown culture often styles inline code with backticks;
author copies idiom from other guides without checking the regex contract.

**How to avoid:** D-03 explicitly bans decoration in H3 headings. The test
moduledoc should restate this rule. Optionally a second regex
(`~r/^### \\?\\?[a-z_]/`) could fail-fast on backticked atom headings, but
this is gold-plating — the absence of the bare-colon match on a present-but-styled
heading would already produce a "stale doc entry" failure (the doc enumeration
would yield zero atoms while the code yields 78 — easy to debug).

**Warning signs:** A drift-test failure with "Stale doc entry for: <atom>"
on EVERY documented atom simultaneously usually means the H3 regex isn't
matching anything because of styling drift.

### Pitfall 4: `guides/operations/` directory ordering in `mix.exs` extras
**What goes wrong:** Author writes `guides/operations/incident_playbook.md`
BEFORE `guides/troubleshooting.md` in the extras list. ExDoc renders them in
list order, so the table of contents shows the playbook before the decoder
even though authors and reviewers refer to them in the reverse order.

**Why it happens:** Alphabetical instinct; `operations` sorts before
`troubleshooting`.

**How to avoid:** D-17 locks the order: `guides/troubleshooting.md` FIRST,
then `guides/operations/incident_playbook.md`, both after the existing
`guides/recipes/logout.md` line. Determinism is the goal.

**Warning signs:** ExDoc HTML output shows the playbook in the sidebar
before the decoder.

### Pitfall 5: `cmd test -f` shell expansion across operating systems
**What goes wrong:** On Windows (PowerShell), `test -f` is not a builtin —
this presence-guard pattern is POSIX-specific.

**Why it happens:** Mix's `cmd` task delegates to the host shell.

**How to avoid:** This is NOT a new concern — the existing `ci.docs` alias
already has six `cmd test -f` lines (verified `mix.exs:150-155`). Project
already assumes a POSIX shell for CI. Phase 40 inherits the assumption.
If a future contributor wants to run `ci.docs` on Windows, they hit the
existing constraint, not a Phase-40-introduced one.

**Warning signs:** N/A for Phase 40; this is a project-level constraint.

### Pitfall 6: ExUnit discovery of `test/docs/` directory
**What goes wrong:** Author creates `test/docs/troubleshooting_drift_test.exs`,
runs `mix test`, and the test doesn't execute.

**Why it happens:** ExUnit auto-discovers `test/**/*_test.exs` via
`test_helper.exs` boot. Verified: `test/test_helper.exs` starts ExUnit with
no path overrides (`ExUnit.start(exclude: [:pending])` + `Relyra.TestSupport.MigrationCase.bootstrap!()`),
so the recursive glob applies to ANY subdirectory. `test/docs/` will be
discovered automatically.

**How to avoid:** Verified safe — no additional configuration needed. The
file just has to end in `_test.exs` and contain `use ExUnit.Case`.

**Warning signs:** Test missing from output of `mix test --trace` despite
existing on disk.

## Code Examples

Verified patterns from official sources:

### Atom enumeration via three regex patterns (project-verified, not external)
```elixir
# Source: D-08 contract in 40-CONTEXT.md, applied verbatim. The actual three
# patterns are project-internal; their correctness was verified against the
# codebase at research time (78 atoms enumerated, 33 modules covered).

@code_pattern_singleline ~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/
@code_pattern_multiline ~r/Error\.new\(\s*\n\s*:([a-z_][a-z0-9_]*)/
@code_pattern_structlit ~r/%Relyra\.Error\{type:\s*:([a-z_][a-z0-9_]*)/
```

### ExUnit case header (project-verified)
```elixir
# Source: lib/relyra/security/strict_default_proof_test.exs:1-3 (project idiom).
defmodule Relyra.Docs.TroubleshootingDriftTest do
  use ExUnit.Case, async: true
  # ...
end
```

### Failure message vocabulary (project-verified)
```
# Source: test/security/ci_gate_integrity_test.exs:96-100 (mirror target).
# Pattern: "<what's wrong> #{path-or-name} <what's expected> — <consequence>"

assert File.exists?(path),
       "gated security suite #{path} is named in ci.security but does not exist on disk — " <>
         "the alias would error or the gate would be hollow"
```

For DOCS-06 drift test, the mirrored form is (D-10):
```
"Missing doc entry for: :#{atom} — add ### :#{atom} section to guides/troubleshooting.md (source: #{path})"
"Stale doc entry for: :#{atom} — atom no longer emitted by Relyra; remove from troubleshooting.md or re-introduce in lib/"
```

### Predecessor guide opening (project idiom for D-13)
```markdown
# Source: guides/recipes/logout.md:1-23 (Phase 39 predecessor; D-13 inheritance target).

# <Title>

This guide is the operator-facing reference for <topic>. Use it to <purpose>.

## Overview

<brand-voice paragraph: positions the topic, names the protocol/security reality,
identifies what's structurally true vs. what's optional>

This guide provides the exact vocabulary to <core deliverable> and establishes
the mandatory <gate/fallback/contract> required to actually <achieve goal>.

## Relyra owns / Host owns

## Relyra owns

- <bullets>

## Host owns

- <bullets>
```

## State of the Art

This is a documentation phase; there is no fast-moving technical state-of-the-art
to track. The patterns this phase reuses are stable since:

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-suite `test` lines in `ci.security` (hollow-gate hazard) | Each suite as its own `cmd mix test` step | Phase 30 (2026-05-24) | Phase 40 inherits this style for `ci.docs` per D-19, even though `ci.docs` doesn't run `ci.conformance` first (the original dedup trigger). |
| Recipe-style guides with ad-hoc structure | "Relyra owns / Host owns / IdP owns" preamble + reference table + scenario runbooks + closing receipt | Phase 36 (generic_saml.md), Phase 37 (identity_mapping), Phase 39 (logout.md) | Phase 40 inherits this spine per D-13. Deviating would feel jarring in v1.4 after three phases of consistency. |
| No documentation-drift enforcement | Test-asserted code-vs-doc parity | Phase 40 (this phase) — NEW for Relyra | Sets precedent: the next time someone wants to add a "decoder" guide for any other in-tree taxonomy (telemetry events, audit actions, algorithm policy URIs), the same drift-test idiom can be reused. |

**Deprecated/outdated:** N/A. No legacy patterns being retired.

**External prior art (Step 12, contextual flavor):** Documentation-drift-via-tests
is well-trodden ground in Elixir/Erlang. ExDoc itself uses `mix docs --formatter html`
with build-time validation that linked anchors resolve; Phoenix's `phoenix_live_view`
has a documented anchors-must-exist test in its CI. The Relyra approach is
narrower (one specific code-vs-doc taxonomy) and more strict (bidirectional set
equality, not just "all docs anchors resolve") — appropriate for a security
library where the operator vocabulary IS load-bearing. No external dependency
is needed to do this; OTP stdlib `Regex` + ExUnit suffice.

## Assumptions Log

All factual claims in this research were either VERIFIED against the codebase
in this session (`rg`, `cat`, `wc -l` against `lib/` and `mix.exs`) or CITED
from CONTEXT.md (which itself is the user's locked decisions).

The only ASSUMED claim is the project-skill survey:

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No `.claude/skills/` or `.agents/skills/` directories exist at the repo root, so there are no project skill rules to load for this phase. | Project Context | LOW — even if skill files exist and were missed, Phase 40 is pure documentation + one test, and CLAUDE.md already governs voice, test style, and CI conventions. A missed skill file would add detail, not contradict the plan. |

[VERIFIED via `ls /Users/jon/projects/relyra/.claude/skills` and `ls /Users/jon/projects/relyra/.agents/skills` — both returned "No such file or directory" at research time.]

A1 is therefore better classified as VERIFIED-NEGATIVE than ASSUMED, but
retained here for transparency.

## Open Questions

1. **Should the planner re-validate the 78-atom count immediately before
   writing the troubleshooting guide?**
   - What we know: This research enumerated 78 unique atoms via the three
     D-08 regex patterns at commit `425d38d` (working tree clean per
     `git status` at research time except for an untracked `patch_state.py`
     unrelated to Phase 40).
   - What's unclear: If Phase 38 or any other parallel work lands new atom
     emission sites before Phase 40 executes, the count could shift.
   - Recommendation: Planner's first task should re-run the three commands
     (single-line, multi-line, struct-literal) and confirm 78 OR the
     updated count. Lock that number in the planner's SUMMARY-side
     contract so each plan-task knows how many atom entries to author.

2. **Where exactly do the two new presence guards go in `ci.docs`?**
   - What we know: D-18 says "after the existing `cmd test -f guides/recipes/logout.md`
     line." That line is verified at `mix.exs:155`.
   - What's unclear: Whether the planner wants to keep the existing line
     ordering (alphabetical-ish: `batteries_included`, `BATTERIES_INCLUDED.md`,
     `identity_mapping`, `adfs`, `generic_saml`, `logout`) or wedge the
     new guides into the alphabetical position. D-17 settles the extras
     list ordering; D-18 settles only that the presence guards come
     after the `logout` line, not the relative order between
     `troubleshooting.md` and `incident_playbook.md`.
   - Recommendation: For symmetry with D-17, order the presence guards
     the same way: `troubleshooting.md` first, then
     `incident_playbook.md`. Then the drift test `cmd mix test` line
     (D-19).

3. **Should the drift test's failure message include the full atom-emission
   source paths or just the module name?**
   - What we know: D-10 specifies `(source: lib/path/file.ex)` form for
     the missing-doc-entry case.
   - What's unclear: If a single atom appears in multiple files (e.g.
     `:adapter_not_configured` — 9 sites; `:connection_not_found` — 7
     sites; `:internal_protocol_error` — 6 sites), the failure message
     could list all sites or just the first.
   - Recommendation: List all sites comma-separated. Operators see one
     atom name; they want all the places to look. Format example:
     `"Missing doc entry for: :adapter_not_configured — add ### :adapter_not_configured section to guides/troubleshooting.md (sources: lib/relyra/key_resolver/default.ex, lib/relyra/metadata.ex, lib/relyra/session_adapter.ex, ...)"`.

## Environment Availability

> Skipped — Phase 40 has no external runtime dependencies. Everything used
> (ExUnit, Elixir stdlib `Regex`, `File`, `Path.wildcard`, `MapSet`, ExDoc,
> POSIX `test -f` via `mix cmd`) is either part of Elixir's standard
> distribution or already in `mix.exs` and verified present.

## Validation Architecture

> `workflow.nyquist_validation` not explicitly set to false (checked
> `.planning/config.json` — file may not exist; absent means enabled per
> protocol). Including this section.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (OTP-bundled with Elixir 1.19) |
| Config file | `test/test_helper.exs` (already present; verified) |
| Quick run command | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` |
| Full suite command | `mix qa` (alias: `format --check-formatted` + `compile --warnings-as-errors` + `test --warnings-as-errors`) — or `mix ci.docs` for the docs lane specifically |
| Phase gate command | `mix ci.docs && mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-06 | Every atom emitted by `Relyra.Error` (via three D-08 patterns) has a corresponding `### :atom` H3 in `guides/troubleshooting.md` | unit (drift) | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` | ❌ Wave 1 (the test file IS the deliverable) |
| DOCS-06 | Every `### :atom` H3 in `guides/troubleshooting.md` corresponds to an emitted atom (no stale entries) | unit (drift) | Same command — the test is bidirectional | ❌ Wave 1 |
| DOCS-06 | `guides/troubleshooting.md` exists on disk | smoke (presence guard) | `mix cmd test -f guides/troubleshooting.md` (via `ci.docs`) | ❌ Wave 1 (the guide IS the deliverable) |
| DOCS-05 | `guides/operations/incident_playbook.md` exists on disk | smoke (presence guard) | `mix cmd test -f guides/operations/incident_playbook.md` (via `ci.docs`) | ❌ Wave 1/2 (the guide IS the deliverable) |
| DOCS-05 | (no automatable behavior assertion — narrative quality is reviewer-judged) | manual-only | N/A | — |

**Manual-only justification for DOCS-05 narrative content:** The five-surface
table (telemetry, audit, LiveAdmin, mix tasks, decoder cross-link) and the
six scenario runbooks (cert expiry, metadata drift, replay storm, signature
regression, ACS misconfig, attribute mapping) are narrative deliverables.
Their correctness lives in operator review, not in an assertion. The presence
guard catches deletion; the drift test catches taxonomy mismatch; the
narrative quality is gated by `/gsd:verify-work` reviewer pass.

### Sampling Rate
- **Per task commit:** `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`
  (the canonical guard for any task that edits `lib/**/*.ex` introducing or
  renaming an atom OR edits `guides/troubleshooting.md`).
- **Per wave merge:** `mix ci.docs` (runs all presence guards + drift test +
  existing batteries_included/install/test_support_demo tests).
- **Phase gate:** `mix qa && mix ci.docs && mix ci.security` green before
  `/gsd:verify-work`. (ci.security is unchanged by this phase but still
  must remain green — Phase 30 invariant.)

### Wave 0 Gaps
- [ ] `test/docs/` directory — create.
- [ ] `test/docs/troubleshooting_drift_test.exs` — create the test FIRST (failing),
      then author the guide entries to satisfy each "Missing doc entry for: :atom"
      message, iterating until green. This is the assertion-by-test pattern
      already established in `test/security/strict_default_proof_test.exs`.
- [ ] `guides/operations/` directory — create when adding `incident_playbook.md`.
- [ ] No framework install needed; ExUnit is OTP-bundled.

## Project Constraints (from CLAUDE.md)

Phase 40 inherits all CLAUDE.md directives. Specifically applicable:

| Directive | Source | Phase 40 Compliance |
|-----------|--------|---------------------|
| `mix test --warnings-as-errors` stays green | CLAUDE.md "Testing Requirements" | The drift test is invoked under `--warnings-as-errors` in `ci.docs` (D-19); the test module itself must be warning-clean. |
| `mix ci.security` stays green | CLAUDE.md "Testing Requirements" | Phase 40 does NOT modify `ci.security`. D-11 explicitly leaves it untouched. |
| `mix format --check-formatted` exits 0 | CLAUDE.md "Testing Requirements" | The new test module + the two-line `mix.exs` edit must be `mix format`-clean. Trivially satisfied with normal editor workflow. |
| Each security suite is its own `cmd mix test` step (Phase 30 hollow-gate fix) | CLAUDE.md "Testing Requirements" | The drift test is in `ci.docs`, not `ci.security`, so the strict invariant doesn't apply. But D-19 still uses `cmd mix test` style for consistency. |
| Never weaken `test/security/xml/adversarial_crypto_test.exs` | CLAUDE.md "Testing Requirements" | Untouched by this phase. |
| Conventional commits with `Co-Authored-By: <tool>` footer | CLAUDE.md "Commit Style" | Plan tasks must emit conventional commits, types `docs:` for guide additions and `test:` for the drift test (or `feat:` if framed as a new doc surface; planner discretion). |
| Release Please generates CHANGELOG.md; never hand-edit | CLAUDE.md "Commit Style" | Phase 40 makes no CHANGELOG.md edits. |
| Do NOT run `mix hex.publish` manually | CLAUDE.md "Hex Publishing" | Phase 40 does NOT publish; Release Please handles the v1.4 release PR. |
| Non-negotiable security invariants | CLAUDE.md "Non-Negotiable Security Invariants" | NONE are relaxed by this phase. Phase 40 documents what the trust pipeline emits; it does not change emission. |
| Brand voice: "Every login ends in a cryptographically verified assertion or a typed rejection — never a silent compromise" | CLAUDE.md "What this project is" | The closing-pointer of the incident playbook (D-16) explicitly mirrors this metaphor: "every login resolves to a verified trust path or a typed rejection — and when in doubt, the diagnostic bundle is the trace." |
| GSD Workflow Awareness — do not implement outside the active PLAN.md scope | CLAUDE.md "GSD Workflow Awareness" | Research deliverable; planner authors PLAN.md downstream; executor follows PLAN.md. |
| Default to deeply-researched, single-shot recommendations | CLAUDE.md "Decision Posture" | This research produces ONE recommended approach per question, not menus. |

## Step-by-step Findings (research log)

For traceability — these are the findings that materially shaped the
sections above.

### Step 1 — Canonical atom set (Verified)
- Ran the three D-08 regex patterns against `lib/`:
  - P1 (single-line): **56 matches**, captured atoms across 22 files.
  - P2 (multi-line): **111 matches**, captured atoms across 33 files.
  - P3 (struct-literal): **4 matches**, in `lib/relyra/live_admin/connections_live.ex`,
    `lib/relyra/metadata/trust_anchor.ex`, `lib/relyra/security/xml/c14n.ex`,
    `lib/relyra/security/xml/corpus_gate.ex` — exactly the 4 sites CONTEXT.md
    D-08 named.
- Union (unique atoms across all three patterns): **78 atoms**.
- CONTEXT.md D-05 estimate was "~60 entries." Corrected to **78**.
- Full atom list (alphabetical, the canonical set Phase 40 must document):
  `:adapter_not_configured`, `:ambiguous_assertion`, `:ambiguous_signed_node`,
  `:assertion_expired`, `:assertion_not_yet_valid`, `:authn_request_invalid`,
  `:canonicalization_failed`, `:clock_skew_exceeded`,
  `:connection_binding_mismatch`, `:connection_invalid`,
  `:connection_not_found`, `:connection_not_runtime_ready`,
  `:connection_unavailable`, `:corpus_violation`, `:decryption_failed`,
  `:deprecated_algorithm`, `:destination_mismatch`, `:diagnostic_bundle_failed`,
  `:digest_mismatch`, `:doctype_forbidden`, `:duplicate_xml_id`,
  `:entity_expansion_forbidden`, `:fetch_connection_refused`,
  `:fetch_dns_failure`, `:fetch_http_4xx`, `:fetch_http_5xx`,
  `:fetch_timeout`, `:fetch_tls_handshake`, `:idp_initiated_not_allowed`,
  `:in_response_to_mismatch`, `:internal_protocol_error`,
  `:invalid_audience`, `:invalid_binding`, `:invalid_binding_payload`,
  `:invalid_connection_record`, `:invalid_idp_sso_url`,
  `:invalid_logout_payload`, `:invalid_metadata_source`,
  `:invalid_parsed_doc`, `:invalid_record_validity_warning_inputs`,
  `:invalid_redirect`, `:invalid_resume_auto_refresh_inputs`,
  `:invalid_signature`, `:issuer_mismatch`, `:key_not_configured`,
  `:legacy_algorithm_override_expired`, `:logout_request_invalid`,
  `:logout_response_invalid`, `:malformed_xml`,
  `:metadata_drift_requires_review`, `:metadata_fetch_failed`,
  `:metadata_missing_certificate`, `:metadata_missing_entity_id`,
  `:metadata_missing_sso_service`, `:metadata_source_not_found`,
  `:metadata_wrong_root`, `:missing_protocol_field`, `:missing_signature`,
  `:optional_dependency_missing`, `:payload_too_large`,
  `:recipient_mismatch`, `:relay_state_mismatch`, `:relay_state_missing`,
  `:relay_state_rejected`, `:replayed_assertion`, `:request_intent_consumed`,
  `:request_intent_expired`, `:request_intent_invalid`,
  `:request_intent_not_found`, `:resolver_failed`, `:resolver_misconfigured`,
  `:signature_failed`, `:subject_confirmation_expired`,
  `:trust_anchor_mismatch`, `:unsupported_default_adapter`,
  `:unsupported_signature_algorithm`, `:unsupported_status`,
  `:untrusted_certificate`.

### Step 2 — Atom → trust-pipeline-seam bucketing (Verified)
Each of the 78 atoms maps cleanly to one of the eight D-02 buckets. The
mapping below is the planner's authoritative split for the troubleshooting
guide's section structure.

| Bucket | Atoms (count) |
|--------|---------------|
| **XML Hardening** (pre-parse + parse-tree gates) | `:doctype_forbidden`, `:entity_expansion_forbidden`, `:payload_too_large`, `:malformed_xml`, `:duplicate_xml_id`, `:ambiguous_signed_node`, `:ambiguous_assertion`, `:invalid_parsed_doc`, `:canonicalization_failed`, `:corpus_violation` (10) |
| **Signature & Crypto** (XMLDSig + XMLEnc verify path) | `:missing_signature`, `:invalid_signature`, `:digest_mismatch`, `:unsupported_signature_algorithm`, `:untrusted_certificate`, `:trust_anchor_mismatch`, `:key_not_configured`, `:deprecated_algorithm`, `:legacy_algorithm_override_expired`, `:decryption_failed`, `:signature_failed` (11) |
| **Replay & Request Intent** | `:replayed_assertion`, `:request_intent_consumed`, `:request_intent_expired`, `:request_intent_invalid`, `:request_intent_not_found`, `:in_response_to_mismatch` (6) |
| **Metadata Lifecycle** (parse + apply + auto-refresh + drift) | `:metadata_missing_entity_id`, `:metadata_missing_sso_service`, `:metadata_missing_certificate`, `:metadata_wrong_root`, `:metadata_fetch_failed`, `:metadata_source_not_found`, `:metadata_drift_requires_review`, `:invalid_metadata_source`, `:invalid_record_validity_warning_inputs`, `:invalid_resume_auto_refresh_inputs` (10) |
| **Network / Fetch** | `:fetch_connection_refused`, `:fetch_dns_failure`, `:fetch_http_4xx`, `:fetch_http_5xx`, `:fetch_timeout`, `:fetch_tls_handshake` (6) |
| **Binding & Protocol Shape** | `:authn_request_invalid`, `:invalid_binding`, `:invalid_binding_payload`, `:invalid_redirect`, `:invalid_idp_sso_url`, `:invalid_logout_payload`, `:logout_request_invalid`, `:logout_response_invalid`, `:relay_state_mismatch`, `:relay_state_missing`, `:relay_state_rejected`, `:missing_protocol_field`, `:destination_mismatch`, `:recipient_mismatch`, `:assertion_expired`, `:assertion_not_yet_valid`, `:subject_confirmation_expired`, `:clock_skew_exceeded`, `:invalid_audience`, `:connection_binding_mismatch`, `:issuer_mismatch`, `:unsupported_status`, `:idp_initiated_not_allowed`, `:internal_protocol_error` (24) |
| **Configuration & Adapter Wiring** | `:adapter_not_configured`, `:optional_dependency_missing`, `:unsupported_default_adapter`, `:resolver_failed`, `:resolver_misconfigured`, `:connection_invalid`, `:connection_not_found`, `:connection_not_runtime_ready`, `:connection_unavailable`, `:invalid_connection_record`, `:diagnostic_bundle_failed` (11) |
| **Session & Logout** | (atoms in this bucket are SHARED with Signature&Crypto and Binding&Protocol Shape — the SLO atoms are part of the existing buckets, not a separate bucket. Planner discretion: optionally a dedicated SLO subsection inside Binding & Protocol Shape calling out `:logout_request_invalid`, `:logout_response_invalid`, `:invalid_logout_payload` as the SLO-specific subset.) |

**Note:** The 8-bucket structure in D-02 implicitly treats "Session & Logout"
as a separate bucket, but the codebase doesn't emit any atoms exclusive to
that bucket — Phase 38 SLO work added atoms that bucket-fit into Binding &
Protocol Shape and Signature & Crypto. The planner should either (a) merge
"Session & Logout" into Binding & Protocol Shape with a clear subsection, or
(b) duplicate the three SLO-specific atoms into a "Session & Logout"
section while keeping their canonical home in the other bucket. Option (a)
is cleaner; option (b) is more discoverable for SLO operators. Recommend (a)
with a one-paragraph SLO callout at the bottom of the Binding & Protocol
Shape section.

**Ambiguous placements (Verified):** None. Every atom has an obvious bucket
based on emitting module path:
- `:digest_mismatch` (lib/relyra/security/signature.ex) → Signature & Crypto.
- `:canonicalization_failed` (lib/relyra/security/xml/c14n.ex) → XML Hardening.
- `:replayed_assertion` (lib/relyra/replay_store/*) → Replay & Request Intent.
- `:internal_protocol_error` is the catch-all for "should never happen" — emitted from 6 files. Recommend documenting under Binding & Protocol Shape with a callout that it signals an internal contract violation.

### Step 3 — Telemetry catalog (Verified from `lib/relyra/telemetry.ex`)
The exact telemetry event names the playbook will cite verbatim:

**Standard span events** (each is a `:start`/`:stop`/`:exception` triplet):
- `[:relyra, :saml, :login]`
- `[:relyra, :saml, :authn_request]`
- `[:relyra, :saml, :response, :decode]`
- `[:relyra, :saml, :response, :validate]`
- `[:relyra, :saml, :signature, :verify]`
- `[:relyra, :saml, :replay, :check]`
- `[:relyra, :saml, :user, :map]`
- `[:relyra, :saml, :session, :establish]`
- `[:relyra, :saml, :metadata, :refresh]`
- `[:relyra, :saml, :metadata, :import]`
- `[:relyra, :saml, :metadata, :auto_refresh]`

**Auto-refresh state-transition events** (one-shot, not span-bracketed):
- `[:relyra, :saml, :metadata, :auto_refresh, :degraded]`
- `[:relyra, :saml, :metadata, :auto_refresh, :suspended]`
- `[:relyra, :saml, :metadata, :auto_refresh, :recovered]`
- `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]`
- `[:relyra, :saml, :metadata, :auto_refresh, :skipped]`

**Certificate expiry event:**
- `[:relyra, :saml, :certificate, :expiring]`

The playbook quotes these as-is (paraphrasing them would break adopter
`:telemetry.attach/4` calls if they're ever copy-pasted as integration
examples).

### Step 4 — Audit row vocabulary (Verified from `lib/relyra/ecto/audit_event.ex:13-26`)
- `@domain_values = [:connection, :metadata, :certificate, :mapping]`
- `@action_values = [:created, :updated, :enabled, :disabled, :applied, :refreshed, :staged, :activated, :retired, :replaced, :deleted]`

**Audit-writing call sites (verified via `rg AuditWriter.append_event lib/`):**
- `lib/relyra/ecto/mapping_commands.ex:627` (mapping mutations)
- `lib/relyra/ecto/connections.ex:250` (connection mutations)
- `lib/relyra/ecto/metadata_apply.ex:250` and `:895` (metadata apply, two distinct mutation classes)
- `lib/relyra/ecto/certificate_inventory.ex:693` (certificate lifecycle mutations)
- Scheduler/auto-refresh (via metadata apply) → indirect.

**Confirmed non-writers (D-15 scenario #3 callout):**
- `lib/relyra/replay_store/ecto.ex` and `lib/relyra/replay_store/ets.ex` —
  NO `AuditWriter` call. Replays do not mutate trust state, so they intentionally
  produce no audit row. Operators MUST rely on telemetry alone for replay-storm
  detection. (`rg AuditWriter lib/relyra/replay_store/` returned zero hits.)

### Step 5 — Admin LiveView routes (Verified from `lib/relyra/live_admin/router.ex:11-30`)
Routes (path prefix `/relyra/admin` by default, configurable via the
`relyra_admin_routes/2` macro's first arg):

| Path | LiveView module | Action |
|------|-----------------|--------|
| `/relyra/admin/diagnostic/bundle` | `Relyra.Phoenix.Controllers.DiagnosticController` | `:download` (controller, not LiveView) |
| `/relyra/admin/` | `Relyra.LiveAdmin.ConnectionsLive` | `:index` |
| `/relyra/admin/connections/new` | `Relyra.LiveAdmin.ConnectionsLive` | `:new` |
| `/relyra/admin/connections/:connection_id` | `Relyra.LiveAdmin.ConnectionsLive` | `:show` |
| `/relyra/admin/connections/:connection_id/edit` | `Relyra.LiveAdmin.ConnectionsLive` | `:edit` |
| `/relyra/admin/connections/:connection_id/metadata` | `Relyra.LiveAdmin.ConnectionMetadataLive` | `:metadata` |

**Correction to CONTEXT.md D-14:** The route path uses `:connection_id` as
the path parameter, NOT `:id` as CONTEXT.md cited. The playbook should
use `/relyra/admin/connections/:connection_id` form to match the actual
router. (CONTEXT.md is wrong in five-surface item 3.)

### Step 6 — Mix task inventory (Verified)
Files in `lib/mix/tasks/`:
1. `relyra.batteries_included.ex` — `@shortdoc "Generate or drift-check BATTERIES_INCLUDED.md."`
2. `relyra.conformance.ex` — `@shortdoc "Generate or drift-check CONFORMANCE.md."`
3. `relyra.diagnostic.ex` — `@shortdoc "Generate a Relyra diagnostic bundle."`
4. `relyra.install.ex` — `@shortdoc "Scaffold the minimal Relyra integration surface"`
5. `relyra.metadata.pin.ex` — `@shortdoc "Pin a SHA-256 metadata trust fingerprint on a connection."`
6. `relyra.refresh_due.ex` — `@shortdoc "Refresh any metadata sources whose schedule is due."`
7. `relyra.security_review.ex` — `@shortdoc "Generate or drift-check SECURITY_REVIEW_EVIDENCE.md."`

Plus `hex.audit.ex` (a third-party Hex task overlay, NOT a Relyra task).

**Correction to code_context in CONTEXT.md:** code_context says "eight
Mix tasks" — the actual count is 7 Relyra tasks (excluding `hex.audit`).
CONTEXT.md D-14 lists 7 correctly. Plan accordingly.

### Step 7 — Drift-check test design (Verified against codebase)
Three D-08 regex patterns validated:
- P1 (`Error\.new\(\s*:atom`) and P2 (`Error\.new\(\s*\n\s*:atom`) together
  cover constructor sites. P3 (`%Relyra.Error\{type:\s*:atom`) covers the
  4 struct-literal sites.

**Edge case found (BLOCKING for planner awareness; LOW residual risk):**
Three modules emit via a variadic `require_present_fields/4` helper where
`error_type` is a function parameter:
- `lib/relyra/protocol/logout_request.ex:136` — helper. Caller at line 70
  passes `:missing_protocol_field` as a literal positional argument.
- `lib/relyra/protocol/logout_response.ex:127` — helper. Caller at line 70
  passes `:missing_protocol_field`.
- `lib/relyra/security/xml/pure_beam.ex:620` — helper. Callers at lines 336,
  359, 393 pass `:missing_protocol_field` (twice) and `:missing_signature`
  (once).

The construction site `Error.new(error_type, message, ...)` is NOT matched
by any D-08 pattern (no literal atom). However, BOTH atoms involved
(`:missing_protocol_field`, `:missing_signature`) ARE covered by literal
`Error.new(:atom, ...)` sites elsewhere:
- `:missing_protocol_field` — literal at `lib/relyra/security/logout_validator.ex:89`, `:190`, `:197`.
- `:missing_signature` — literal at `lib/relyra/security/signature.ex:220`, `lib/relyra/security/logout_validator.ex:132`, `lib/relyra/security/xml/pure_beam.ex:514`, `:587`.

So the union of three patterns DOES capture every emitted atom, but the
robustness of that coverage depends on incidental redundancy. Future
contributors adding a NEW atom that's ONLY emitted via a variadic helper
will silently bypass the drift gate. See Pitfall 1 for the recommended
mitigation (test moduledoc rule, optionally a 4th regex — recommend
moduledoc).

**Doc-side regex `~r/^### :([a-z_][a-z0-9_]*)\b/m`:** Verified safe against
the `\b` boundary. Allows trailing decoration like `### :foo — note`,
disallows leading whitespace or non-`### ` prefix. False-match risk
against body prose is zero unless someone authors a prose line that
literally begins with `### :` at column zero (no precedent in any existing
guide — verified via `rg '^### :' guides/`).

### Step 8 — Existing CI alias shape (Verified from `mix.exs:149-159`)
The `ci.docs` alias as of commit `425d38d`:
```elixir
"ci.docs": [
  "cmd test -f guides/batteries_included.md",
  "cmd test -f BATTERIES_INCLUDED.md",
  "cmd test -f guides/identity_mapping_and_provisioning.md",
  "cmd test -f guides/recipes/adfs.md",
  "cmd test -f guides/recipes/generic_saml.md",
  "cmd test -f guides/recipes/logout.md",          # ← anchor for D-18 insertion
  "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
  "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
  "relyra.batteries_included --check"
]
```

D-18 inserts the two NEW presence guards after the `logout.md` line and
BEFORE the `test ...batteries_included_test.exs` line. D-19 inserts the
drift-test invocation as a `cmd mix test ...` step in the same place
(after presence guards). Final shape (planner-assembly):
```elixir
"ci.docs": [
  "cmd test -f guides/batteries_included.md",
  "cmd test -f BATTERIES_INCLUDED.md",
  "cmd test -f guides/identity_mapping_and_provisioning.md",
  "cmd test -f guides/recipes/adfs.md",
  "cmd test -f guides/recipes/generic_saml.md",
  "cmd test -f guides/recipes/logout.md",
  "cmd test -f guides/troubleshooting.md",                                    # NEW (D-18)
  "cmd test -f guides/operations/incident_playbook.md",                       # NEW (D-18)
  "cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors", # NEW (D-19)
  "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
  "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
  "relyra.batteries_included --check"
]
```

Note: the existing `test ...` lines (lines 156-157 in mix.exs) are BARE
`test` lines, not `cmd mix test`. This works in `ci.docs` because
`ci.docs` does NOT run any prerequisite alias that consumes `test` (unlike
`ci.security` which runs `ci.conformance`). Mix's `test` dedup only bites
when the SAME alias invocation runs `test` multiple times AFTER a
prerequisite has already consumed it. The new `cmd mix test ...` line for
the drift test is appropriate because it runs only one specific suite
(without `--exclude`/`--only` filters that might be inherited).

### Step 9 — Document-idiom precedents (Verified)
Read `guides/recipes/logout.md` (head 50 lines), `guides/recipes/generic_saml.md`
(head 50 lines). Both establish:
- **Opening:** Title + one-paragraph mission statement.
- **Overview:** Brand-voice statement of the problem domain + what the guide
  delivers + the receipt the operator gets at the end.
- **Trust-boundary preamble:** `## Relyra owns / Host owns` (and for the
  generic_saml.md, `/ IdP owns`). Bulleted under each subhead.
- **Reference / decoder body:** Tables, bulleted lists, step-by-step ordered
  lists.
- **Closing receipt:** A short "you have this" or "you can now" statement
  that gives the operator a marker of completion.

Phase 40's two guides should inherit this exactly. For
`guides/troubleshooting.md`, the trust-boundary preamble is a one-paragraph
restatement that "Relyra owns the typed-rejection contract; the host owns
operator response to those rejections." The reference body is the
eight-domain-grouped atom decoder. The closing receipt is the cross-link
into `guides/operations/incident_playbook.md`.

For `guides/operations/incident_playbook.md`, the trust-boundary preamble
names which evidence surfaces Relyra owns (telemetry emission, audit-row
schema, admin LiveView routes, Mix tasks) and which the host owns (storage
for telemetry, retention/access for audit rows, identity for admin
authentication, scheduling for Mix-task invocation). The reference body
is the five-surface table + six scenario runbooks. The closing receipt is
"run `mix relyra.diagnostic`" with the brand-voice metaphor.

### Step 10 — Failure-message vocabulary mirror (Verified from `test/security/ci_gate_integrity_test.exs`)
The mirror pattern is:
```
<assertion failure prefix> #{path-or-name} <expected condition not met> — <consequence>
```
Examples from `ci_gate_integrity_test.exs:96-100`:
```
"gated security suite #{path} is named in ci.security but does not exist on disk — " <>
  "the alias would error or the gate would be hollow"
```
For Phase 40's drift test, the equivalents (per D-10):
```
"Missing doc entry for: :#{atom} — add ### :#{atom} section to guides/troubleshooting.md (source: #{path})"
"Stale doc entry for: :#{atom} — atom no longer emitted by Relyra; remove from troubleshooting.md or re-introduce in lib/"
```
The vocabulary fits exactly: identifies the failure subject, names what's
expected, em-dash separator, names the consequence/action.

### Step 11 — Test path/dir bootstrapping (Verified)
- `test/docs/` directory does NOT exist as of commit `425d38d`. Phase 40
  creates it.
- `test/test_helper.exs` content (verified):
  ```elixir
  ExUnit.start(exclude: [:pending])
  Relyra.TestSupport.MigrationCase.bootstrap!()
  ```
  No path overrides; ExUnit auto-discovery applies to any
  `test/**/*_test.exs`. `test/docs/troubleshooting_drift_test.exs` will be
  discovered automatically.
- The drift test does NOT need `Relyra.TestSupport.MigrationCase.bootstrap!()`
  to work (it doesn't touch Ecto). It still runs after that bootstrap because
  test_helper.exs runs once per `mix test` invocation regardless of which
  tests are selected. No conflict.

### Step 12 — External prior art (Contextual flavor)
- ExDoc validates anchor resolution at build time (`mix docs` warns on
  broken `[link](#anchor)`).
- Phoenix's `phoenix_live_view` has a CI step asserting all `@moduledoc`
  examples actually compile.
- The Relyra approach (bidirectional set equality between code-emitted atoms
  and H3-anchored doc entries) is narrower in scope than these, but
  consistent in spirit: assert documentation-vs-code parity by test, not by
  intent. This is the first time Relyra uses this idiom; the
  precedent established here can be reused for future taxonomies (telemetry
  event catalog, audit action vocabulary, algorithm-policy URI list) if
  demand emerges post-v1.4.

## Sources

### Primary (HIGH confidence)
- `lib/relyra/error.ex` (verified via Read) — `Relyra.Error` shape; no `@known_types` attribute; `redact_details/1` definition.
- `lib/relyra/telemetry.ex` (verified via Read) — event-name catalog cited verbatim.
- `lib/relyra/ecto/audit_event.ex` (verified via Read) — `@domain_values` + `@action_values`; schema definition.
- `lib/relyra/live_admin/router.ex` (verified via Read) — admin route paths; the `:connection_id` correction.
- `lib/mix/tasks/relyra.*.ex` (verified via `ls` + `grep @shortdoc`) — 7-task inventory with one-liner purposes.
- `mix.exs` lines 105-160 (verified via Read) — `docs/extras:` list shape, `aliases.ci.docs` step list.
- `test/security/ci_gate_integrity_test.exs` (verified via Read) — hollow-gate meta-test; failure-message vocabulary mirror.
- `test/test_helper.exs` (verified via Read) — confirms ExUnit auto-discovery setup.
- `guides/recipes/logout.md`, `guides/recipes/generic_saml.md` (verified via Read) — predecessor doc idiom (Relyra owns / Host owns preamble + reference table + closing receipt).
- `.planning/phases/40-operational-polish-error-taxonomy/40-CONTEXT.md` (verified via Read) — locked user decisions D-01..D-19.
- `.planning/REQUIREMENTS.md` (verified via Read) — DOCS-05 + DOCS-06 acceptance wording.
- `.planning/STATE.md` (verified via Read) — project decisions and constraints carried into v1.4.
- `.planning/ROADMAP.md` (verified via Read) — Phase 40 success criteria; v1.4 phase block.
- `CLAUDE.md` (verified at session start as project context) — non-negotiable security invariants, testing requirements, commit style.
- `rg`/`grep` against `lib/` (verified at research time) — 78-atom union; variadic-helper edge case; AuditWriter call topology.

### Secondary (MEDIUM confidence)
- General Elixir/Erlang documentation-drift idioms from ExDoc + Phoenix CI patterns (Step 12) — contextual flavor only, not load-bearing.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool used is in OTP/Elixir stdlib or `mix.exs:55-75`, all verified.
- Architecture: HIGH — diagram and pattern reflect verified codebase state at commit `425d38d`.
- Pitfalls: HIGH — Pitfalls 1, 4, 5, 6 verified directly against codebase; Pitfall 2 is logical (drift detection is consistency-not-correctness, true for any drift system); Pitfall 3 is the documented contract from D-03/D-09.
- Atom enumeration (78 atoms across 33 modules): HIGH — verified via `rg --no-heading` against `lib/` at research time. Source paths recorded.
- Atom → bucket mapping: HIGH — verified by emitting-module path inspection. One planner discretion call documented (Session & Logout subsection placement).
- Telemetry catalog: HIGH — cited verbatim from `lib/relyra/telemetry.ex` moduledoc.
- Audit vocabulary: HIGH — module attributes verified.
- LiveAdmin routes: HIGH — one CONTEXT.md correction (`:connection_id` not `:id`).
- Mix task inventory: HIGH — one CONTEXT.md correction (7 tasks not 8).
- Variadic-helper edge case: HIGH — three sites + all callers inspected.
- Failure-message mirror vocabulary: HIGH — pattern verified against `ci_gate_integrity_test.exs:96-148`.
- Test-discovery: HIGH — `test_helper.exs` contents verified.

**Research date:** 2026-05-27
**Valid until:** Until the next material change to `lib/**/*.ex` atom emissions, `mix.exs` `ci.docs`/`extras`, or the addition of a new `guides/operations/` precedent. Re-validate the 78-atom count at planning time per Open Question #1; everything else is stable for at least 30 days.
