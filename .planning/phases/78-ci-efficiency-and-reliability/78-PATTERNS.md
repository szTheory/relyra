# Phase 78: CI Efficiency and Reliability - Pattern Map

**Mapped:** 2026-09-27
**Files analyzed:** 10 likely new/modified areas
**Analogs found:** 10 / 10 (all source analogs verified with `git ls-files`)

Phase 78 should extend the existing executable evidence ledger, governance contracts, and workflow-specific contracts. New checker modules should follow the semantic parser/fixture style below; workflow edits should be paired with the contracts that pin ownership and behavior.

## File Classification

| New/Modified File or area | Role | Data Flow | Closest tracked analog | Match Quality |
|---|---|---|---|---|
| `test/support/adoption_evidence.ex` (ledger/owner resolution) | utility | transform | same file | exact |
| `test/adoption/evidence_contract_test.exs` (PIPE ownership contract) | test | request-response | same file | exact |
| `test/security/ci_gate_integrity_test.exs` / `mix.exs` (alias integrity) | test/config | transform | same files | exact |
| `test/governance/milestone_scope_test.exs` (lifecycle and PLAN grammar) | test | transform | same file | exact |
| `.github/workflows/security-gates.yml` plus workflow contract | config/test | event-driven | `test/adoption/package_consumer_ci_contract_test.exs` | role-match |
| `test/release/fleet_proxy_ci_integrity_test.exs` (workflow hygiene/canary separation) | test | event-driven | same file | exact |
| `scripts/check_clean_room_consumer.sh` and its CI contract | utility/test | file-I/O | same script and contract test | exact |
| status producer / artifact workflow and contract | utility/config/test | file-I/O | `scripts/test_trace_visual_e2e.sh`, `scripts/test_trace_visual_status_contract.sh`, `demo-app-e2e.yml` | role-match |
| `test/support/phase_73_reconciliation.ex` (generated proof/replay) | utility | batch | same file | exact |
| `test/governance/phase_73_reconciliation_test.exs` | test | batch | same file | exact |

## Pattern Assignments

### Criterion ownership and resolver (`test/support/adoption_evidence.ex`, `test/adoption/evidence_contract_test.exs`)

**Analog:** `test/support/adoption_evidence.ex` and `test/adoption/evidence_contract_test.exs`.

`AdoptionEvidence` is the authoritative semantic ledger. It validates row shape/enums, distinguishes planned from existing deterministic evidence, excludes external canaries from closure, discovers owner selectors, and checks the lane command plus blocking workflow step. Extend this chain for primary lane ownership; do not create a parallel prose-only inventory.

**Ledger and closure pattern** (`test/support/adoption_evidence.ex`, lines 8-17, 331-350):

```elixir
@evidence_kinds [:package_contract, :application, :browser, :external_canary, :security_corpus]
@states [:planned, :existing]

def deterministic_owners(entries, requirement) do
  Enum.filter(entries, fn entry ->
    entry.requirement == requirement and entry.state == :existing and
      entry.evidence_kind != :external_canary
  end)
end
```

**Executable owner chain** (`test/support/adoption_evidence.ex`, lines 490-508):

```elixir
unless owner && selector_filter in command.includes do
  raise ArgumentError,
        "#{entry.requirement} row #{entry.id}: alias #{entry.lane} is not wired to owner #{entry.owner} with selector #{entry.selector}"
end

unless owner.effective_count > 0 do
  raise ArgumentError,
        "#{entry.requirement} row #{entry.id}: alias #{entry.lane} owner #{entry.owner} has zero effective selected tests for selector #{entry.selector}"
end

unless mandatory_security_step?(workflow, "Evidence contract", "mix #{entry.lane}") do
  raise ArgumentError,
        "#{entry.requirement} row #{entry.id}: workflow has no enabled blocking Evidence contract step"
end
```

**Contract test pattern** (`test/adoption/evidence_contract_test.exs`, lines 25-43): snapshot rows, prove exact selector/lane owner, and inject a `registered_test_tags` function to assert each distinct source owner is discovered once in sorted order. Reuse mutation fixtures for missing, empty, duplicate, malformed, zero-count, or disconnected owners.

### Mix alias execution integrity (`mix.exs`, `test/security/ci_gate_integrity_test.exs`)

**Analog:** `mix.exs` and `test/security/ci_gate_integrity_test.exs`.

Security suite ownership is explicit at alias-command granularity. Keep intentional independent defenses visible and preserve the fresh OS process boundary wherever Mix task deduplication or selector inheritance can hollow a gate.

**Alias excerpt** (`mix.exs`, lines 243-265):

```elixir
"ci.security": [
  "compile --warnings-as-errors",
  "ci.conformance",
  # each security suite below runs as its own `cmd mix test` (a fresh OS process)
  # ...the meta-gate enforces this invariant.
  "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
  "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
  "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
```

The meta-gate parses the alias AST (not a source substring), checks every listed file and exact `--only` tag, and requires each security command to start with `cmd mix test` (`test/security/ci_gate_integrity_test.exs`, lines 48-72, 116-149). Pair any alias changes with positive execution counts and negative tests for deduplication, missing selectors, or disabled/conditional owners. Standalone GATE-02 remains a separately named workflow defense (`.github/workflows/security-gates.yml`, lines 115-120).

### Governance lifecycle and PLAN grammar (`test/governance/milestone_scope_test.exs`)

**Analog:** `test/governance/milestone_scope_test.exs`.

This module owns repository lifecycle identity, transition fixtures, plan scope, XML task grammar, executable risk metadata, requirement ownership, and explicit rejection cases. Add phase-78 planning/executing/verification states and malformed/skipped/duplicate transition fixtures here. Use the existing parsed milestone membership machinery rather than hard-coded future phase ceilings.

**Lifecycle test pattern** (lines 47-63):

```elixir
test "completed Phase 73 accepts the ordered current planning lifecycle" do
  assert {:ok, identity} = validated_governance_identity(File.cwd!())

  case {identity.current_phase, identity.status} do
    {"74", "planning"} -> assert identity.governance_phase == "73"
    {phase, "planning"} when phase in ["76", "77"] ->
      assert identity.governance_phase == "73"
    # execution states are checked against their current owning phase
```

Current task parsing permits only the enumerated semantic children (`test/governance/milestone_scope_test.exs`, lines 4898-4901):

```elixir
@task_semantic_children ~w(name action files verify acceptance_criteria risk_metadata resume-signal)
```

Preserve balanced, direct-child parsing and per-task acceptance/risk checks. Research further identifies accepted `type`/`gate` attributes and the allowed risk classes/values in this same tracked test and in Phase 73's concrete PLAN example.

### Workflow ownership, least privilege, and event boundaries

**Analogs:** `test/adoption/package_consumer_ci_contract_test.exs`, `test/release/fleet_proxy_ci_integrity_test.exs`, `.github/workflows/security-gates.yml`, `.github/workflows/fleet-proxy-e2e.yml`.

The package contract parses YAML, asserts one unconditional owner in the intended matrix, compares the exact command list, and proves no duplicate step owns those commands (`test/adoption/package_consumer_ci_contract_test.exs`, lines 13-57). The Fleet contract pins required job identity, trigger and canary boundary (`test/release/fleet_proxy_ci_integrity_test.exs`, lines 18-35). Extend these contracts for workflow-qualified concurrency, PR-only cancellation, permission scope, and exact artifact allowlists. Keep stable required job identities and scheduled external canaries outside deterministic merge ownership.

**Workflow placement excerpt** (`.github/workflows/security-gates.yml`, lines 62-91):

```yaml
      - name: Package consumer contracts
        run: |
          scripts/check_clean_room_consumer.sh --profile full
          scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check
          scripts/check_clean_room_consumer.sh --profile contracts
      - name: Quality gate
        run: mix qa
      - name: Fast lane
        run: mix ci.fast
      - name: Security lane
        run: mix ci.security
      - name: Evidence contract
        run: mix ci.evidence
```

### Clean-room package consumer (`scripts/check_clean_room_consumer.sh`, `test/adoption/package_consumer_ci_contract_test.exs`)

**Analog:** same script and contract.

The harness creates a unique root and puts consumer checkout, HOME/XDG, Mix/Hex homes, archives, deps, build, database, and output beneath it. It invokes commands through `env -i` with explicitly reconstructed variables (`scripts/check_clean_room_consumer.sh`, lines 101-175). Keep CI execution unconditional and after toolchain/dependency setup, with the exact three profile commands pinned by the contract. Never upload the whole output tree: harness cleanup removes the owned root even on failure, so any retained failure receipt must be a bounded external status artifact.

### Bounded failure status and artifact producers

**Analogs:** `scripts/test_trace_visual_e2e.sh`, `scripts/test_trace_visual_status_contract.sh`, `.github/workflows/demo-app-e2e.yml`, `test/release/fleet_proxy_ci_integrity_test.exs`.

Trace visual provides a fixed-schema JSON status path in runner temp, fake-command success/failure injection, and a workflow contract for exact owner, path, artifact action, and retention (`scripts/test_trace_visual_status_contract.sh`, lines 17-29, 39-79). Mirror its allowlisted success/failure shape for any new receipt and test injected assertion/credential/cookie/unexpected-file sentinels against serialized bytes and upload paths. Fleet's current broad uploads include Playwright reports and `test-results` (`.github/workflows/fleet-proxy-e2e.yml`, lines 46-55); update producer and contract together to bound and allowlist exports. Do not make raw logs the fallback artifact.

### Reconciliation capture and replay (`test/support/phase_73_reconciliation.ex`, `test/governance/phase_73_reconciliation_test.exs`)

**Analog:** same support module and focused test.

Capture derives a source manifest and task ids, executes focused checks, runs evidence three times and requires identical vectors, records security command receipts, hashes governed sources, validates, then atomically writes the canonical proof (`test/support/phase_73_reconciliation.ex`, lines 91-134). `validate_documents!/4` requires both reports to embed the same canonical proof and ensures report state matches proof chronology (lines 152-185); `proof_block/1` is the canonical renderer (lines 397-398). Extend replay tests with altered source/result, stale digest, duplicate status, and lifecycle cases. Regenerate proof from capture and update both append-only reports coherently; never hand-author hashes or counts.

## Shared Patterns

- **One deterministic owner:** use the semantic evidence ledger to trace requirement → test selector → alias command → enabled blocking workflow step, and require positive effective count.
- **Independent proof stays explicit:** security `cmd mix test` process boundaries and standalone GATE-02 are named defenses; scheduled provider runs remain canaries.
- **Parse actual structure:** follow existing YAML/XML/AST parsers and semantic validation; do not accept comments or incidental substrings as execution evidence.
- **Isolated state:** consumer/build/home/database paths are owned per run; cache hits are performance observations and still require locked dependency installation.
- **Generated proof:** capture, digest, replay, and atomic writes own reconciliation data and report blocks.
- **Artifact hygiene:** produce a bounded fixed-schema status receipt; never export raw assertions, credentials, cookies, browser traces, or unfiltered service logs.

## No Analog Found

None for the requested areas. There is no current CI workflow that demonstrates bounded Fleet failure artifacts; use the fixed-schema trace-visual producer as the closest producer and add a corresponding Fleet-specific contract.

## Metadata

**Analog search scope:** `mix.exs`, `.github/workflows/`, `scripts/`, `test/adoption/`, `test/security/`, `test/governance/`, `test/release/`, and `test/support/`.
**Files scanned closely:** 13 tracked sources.
**Tracked-source gate:** every analog listed above appeared in `git ls-files`; no install/runtime mirror paths are used.
