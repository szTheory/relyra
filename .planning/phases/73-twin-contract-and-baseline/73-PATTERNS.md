# Phase 73: Twin Contract and Baseline - Pattern Map

**Mapped:** 2026-09-09
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/adoption_evidence.ex` | utility / registry | transform | `lib/relyra/conformance_fixtures.ex` | role-match |
| `test/adoption/evidence_contract_test.exs` | test / repository contract | file-I/O + transform | `test/security/ci_gate_integrity_test.exs` | exact |
| `test/governance/milestone_scope_test.exs` | test / policy contract | file-I/O + transform | `test/docs/demo_guide_drift_test.exs` | exact |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | documentation / inventory | batch | `docs/security_findings.md` | role-match |
| `mix.exs` | config | batch | existing `mix.exs` CI aliases | exact |
| `.github/workflows/security-gates.yml` | config / CI workflow | event-driven + batch | existing `.github/workflows/security-gates.yml` lane steps | exact |

All analogs above were verified with `git ls-files`. No ignored runtime mirror is used.

## Pattern Assignments

### `test/support/adoption_evidence.ex` (utility/registry, transform)

**Analog:** `lib/relyra/conformance_fixtures.ex`

Use a module with `@moduledoc false`, literal module attributes for the closed vocabulary, specs on public query functions, and small functions that filter rows. Keep validation deterministic and raise an `ArgumentError` that identifies the bad row. Unlike the analog, Phase 73 should keep the ledger itself as literal Elixir data and must not add JSON or another parser.

**Module, vocabulary, and query pattern** (lines 1-5, 24-39):

```elixir
defmodule Relyra.ConformanceFixtures do
  @moduledoc false

  @required_keys ~w(id requirement_ids provenance)
  @executed_statuses MapSet.new(["pass", "reject"])

  @spec require_keys!([map()], [String.t()]) :: [map()]
  def require_keys!(rows, required_keys) when is_list(rows) and is_list(required_keys) do
    Enum.map(rows, fn row ->
      require_row_keys!(row, required_keys)
    end)
  end

  @spec executed_rows([map()]) :: [map()]
  def executed_rows(rows) when is_list(rows) do
    Enum.filter(rows, fn row ->
      MapSet.member?(@executed_statuses, Map.get(row, "status"))
    end)
  end
end
```

**Fail-closed validation pattern** (lines 66-81):

```elixir
defp require_row_keys!(row, required_keys) when is_map(row) do
  missing_keys =
    required_keys
    |> Enum.reject(&present?(Map.get(row, &1)))
    |> maybe_add_fixture_content_key(row)

  if missing_keys == [] do
    row
  else
    raise ArgumentError,
          "manifest row #{inspect(Map.get(row, "id"))} missing keys: #{Enum.join(missing_keys, ", ")}"
  end
end

defp require_row_keys!(row, _required_keys) do
  raise ArgumentError, "manifest row must be a map, got: #{inspect(row)}"
end
```

Apply the same shape to the proposed ledger fields: stable `id`, `requirement`, `personas`, `job`, `expected_outcome`, `evidence_kind`, `owner`, `lane`, `state`, fixture/reset ownership, and failure-diagnostic ownership. Preserve `:planned` versus `:existing` as distinct states; only deterministic `:existing` evidence may close a requirement.

---

### `test/adoption/evidence_contract_test.exs` (test/repository contract, file-I/O + transform)

**Analog:** `test/security/ci_gate_integrity_test.exs`

This is the strongest analog in the repository. Copy its AST inspection and fail-closed diagnostics rather than regex-parsing `mix.exs`.

**Test module pattern** (lines 1-26):

```elixir
defmodule Relyra.Security.CiGateIntegrityTest do
  @moduledoc """
  Anti-hollow meta-gate for the `ci.security` Mix alias.
  """
  use ExUnit.Case, async: true
end
```

**AST alias extraction pattern** (lines 55-87):

```elixir
defp ci_security_steps do
  ast = Code.string_to_quoted!(File.read!("mix.exs"))

  steps =
    ast
    |> Macro.prewalker()
    |> Enum.find_value(fn
      {key, list} when is_list(list) ->
        if alias_key?(key, "ci.security") and Enum.all?(list, &is_binary/1), do: list

      _ ->
        nil
    end)

  refute steps == nil,
         "could not find the `\"ci.security\": [ ...string steps... ]` alias in mix.exs"

  steps
end

defp alias_key?(key, name) when is_atom(key), do: Atom.to_string(key) == name
defp alias_key?({key, _meta, ctx}, name) when is_atom(key) and is_atom(ctx),
  do: Atom.to_string(key) == name
defp alias_key?(_key, _name), do: false
```

**Owner existence and wiring assertions** (lines 98-135):

```elixir
for {path, _tag} <- @gated_suites do
  assert File.exists?(path),
         "gated security suite #{path} is named in ci.security but does not exist on disk"
end

for {path, _tag} <- @gated_suites do
  assert steps_referencing(steps, path) != [],
         "gated security suite #{path} is NOT referenced in any ci.security step"
end

assert Regex.match?(~r/^cmd mix test\s/, trimmed),
       "ci.security step for #{path} must be a `cmd mix test ...` step but is:\n\n  #{trimmed}"
```

Extend this chain to prove: completed requirement -> deterministic existing ledger row -> owner file exists -> selector matches -> `ci.evidence` names the owner -> `security-gates.yml` invokes `mix ci.evidence`. Separately prove all six required personas and all v1.11 requirements are covered. External canaries may be recorded but cannot be the sole closure owner.

**Negative fixture pattern:** follow `test/conformance/conformance_fixtures_test.exs` lines 64-75 and 96-113: construct malformed data in the test, isolate any temporary files under `System.tmp_dir!()`, register `on_exit` cleanup, and assert the precise failure. Characterization fixtures for missing owner, canary-only owner, zero-match selector, and unwired alias do not need permanent new files unless implementation demonstrates a readability need.

---

### `test/governance/milestone_scope_test.exs` (test/policy contract, file-I/O + transform)

**Analog:** `test/docs/demo_guide_drift_test.exs`

Keep this a static, async ExUnit contract that reads planning artifacts and returns a concrete list of violations. Anchor extraction to structural headings/checklist syntax rather than incidental mentions.

**Policy aggregation pattern** (lines 901-912):

```elixir
test "incomplete phases require automated acceptance instead of human UAT" do
  roadmap = File.read!(".planning/ROADMAP.md")

  violations =
    roadmap
    |> incomplete_phase_numbers()
    |> Enum.flat_map(&automation_policy_violations/1)

  assert violations == [],
         "Incomplete phases must shift acceptance left into deterministic CI:\n" <>
           Enum.map_join(violations, "\n", &"  - #{&1}")
end
```

**Anchored discovery and explicit violation strings** (lines 925-947):

```elixir
defp incomplete_phase_numbers(roadmap) do
  ~r/^- \[ \] \*\*Phase ([0-9.]+):/m
  |> Regex.scan(roadmap, capture: :all_but_first)
  |> Enum.map(fn [phase] -> phase end)
end

defp automation_policy_violations(phase) do
  phase_dirs = Path.wildcard(".planning/phases/#{phase}-*")

  document_violations =
    for phase_dir <- phase_dirs,
        path <- Path.wildcard(Path.join(phase_dir, "*.md")),
        marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
        String.contains?(File.read!(path), marker),
        do: "#{path} contains #{inspect(marker)}"

  document_violations
end
```

Add checks for the baseline's required categories/severity fields, forbidden demand-gated identifiers (`AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`), and risky mutation classes. A plan that touches public API, default tightening, security posture, real SemVer major, or remote GitHub state must contain the matching blocking checkpoint before mutation; otherwise require an explicit negative scope assertion. Approval checkpoints authorize mutations only—they never count as acceptance evidence.

---

### `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` (documentation/inventory, batch)

**Analog:** `docs/security_findings.md`

Use a dated, severity-ranked ledger with stable columns and written disposition rules. The new baseline broadens the category vocabulary beyond security and belongs in the phase directory, not adopter-facing docs.

**Severity policy pattern** (lines 5-10):

```markdown
## Summary

- High and Critical findings are release blockers until remediated and regression-tested.
- Medium findings require an explicit written disposition before release.
- Low and Informational findings may be deferred only if they remain recorded with owner and revisit date.
- Every accepted fix should link the regression proof that keeps it closed.
```

**Ledger pattern** (lines 12-16):

```markdown
## Findings Ledger

| Finding ID | Severity | Exploit Path | Disposition | Owner | Regression Proof | Blocker State | Revisit Date |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RELYRA-2026-001 | Critical | ... | Confirmed -> Fixed ... | maintainers | ... | resolved | ... |
```

For Phase 73, use `Critical`, `High`, `Medium`, `Low`, and `Informational`, and include at least: finding ID, category, finding, reproducible evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. Cover correctness, security, integration, readability, documentation, artifacts, and CI. Add a separate CI snapshot table for workflow topology, duration, duplicated work, cache declarations, lane ownership, required-check drift, and failure artifacts. Record findings; do not remediate unrelated baseline debt in this phase.

---

### `mix.exs` (config, batch)

**Analog:** existing `mix.exs`

Add `"ci.evidence": :test` beside the other preferred CI environments, following lines 27-40:

```elixir
def cli do
  [
    preferred_envs: [
      qa: :test,
      "ci.fast": :test,
      "ci.docs": :test,
      "ci.conformance": :test,
      "ci.security": :test
    ]
  ]
end
```

Add a focused flat list-of-strings alias beside the existing aliases (lines 197-234). When the evidence alias is composed into another gate, preserve the fresh-process convention used by `ci.security` (lines 241-260):

```elixir
"ci.security": [
  "compile --warnings-as-errors",
  "ci.conformance",
  "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors"
]
```

The new alias should independently execute the two Phase 73 contract files with warnings as errors. Avoid multiple bare `test` steps in one compound alias because Mix task deduplication can silently hollow later steps.

---

### `.github/workflows/security-gates.yml` (config/CI workflow, event-driven + batch)

**Analog:** existing `.github/workflows/security-gates.yml`

Insert one uniquely named evidence-contract step in the already-required security matrix job. Follow the simple named-step pattern at lines 73-90:

```yaml
- name: Quality gate
  run: mix qa

- name: Security lane
  run: mix ci.security

- name: Verification lane
  run: mix ci.verify
```

The Phase 73 step should run `mix ci.evidence`. The contract test must prove this exact command is present. Keep the job matrix, existing security lane, and independent GATE-02 step unchanged. Do not mutate branch protection in this phase; any live required-status change needs an exact remote batch behind the `remote_github` checkpoint.

## Shared Patterns

### Repository-relative source inspection

**Sources:** `test/security/ci_gate_integrity_test.exs` lines 55-76; `test/docs/demo_guide_drift_test.exs` lines 901-947

**Apply to:** both new contract-test files

- Read tracked repository sources with stable repository-relative paths.
- Parse Elixir configuration as AST.
- Parse Markdown only with narrowly anchored heading/checklist expressions.
- Aggregate violations and emit the exact path, requirement ID, and missing seam.

### Fail-closed errors

**Sources:** `lib/relyra/conformance_fixtures.ex` lines 66-81; `test/security/ci_gate_integrity_test.exs` lines 98-151

**Apply to:** registry validation and both contract tests

Malformed rows raise; missing owners, zero-match selectors, unwired aliases, absent workflow commands, and canary-only closure fail with actionable diagnostics. Do not silently discard unknown or planned rows.

### Test isolation

**Source:** `test/conformance/conformance_fixtures_test.exs` lines 96-113

**Apply to:** negative/mutation characterization cases

Create temporary fixture trees beneath `System.tmp_dir!()` using a unique suffix, clean them with `on_exit`, and never mutate the real `REQUIREMENTS.md`, `mix.exs`, workflow, or phase plans during a test.

### Security and approval boundaries

**Source:** `.planning/milestones/v1.9-phases/66-demo-fakeidp-disposition/66-02-PLAN.md` lines 43-67

**Apply to:** governance contract and all future v1.11 plans

Use `<task type="checkpoint:decision" gate="blocking">` plus an explicit `<resume-signal>` for decision-class mutations. Remote GitHub changes use a blocking checkpoint with the exact commands and rollback. Neither kind substitutes for deterministic CI evidence.

### No runtime or public API surface

The ledger belongs under `test/support`, tests under `test/`, and the baseline under `.planning/`. Phase 73 should not edit `lib/relyra/security/**`, behaviour callbacks, `Relyra.start_login/3`, or `Relyra.consume_response/3`.

## No Analog Found

None. The exact ledger schema and combined baseline columns are new, but the repository has strong role-level analogs for literal fixture registries, fail-closed structural tests, severity ledgers, Mix lanes, and GitHub Actions steps.

## Metadata

**Analog search scope:** `test/support`, `test/adoption`, `test/security`, `test/docs`, `lib/relyra`, `docs`, `.github/workflows`, and tracked historical planning artifacts

**Files scanned:** 6 primary analog files plus candidate inventories

**Tracked-source gate:** passed for every analog named in this document

**Pattern extraction date:** 2026-09-09
