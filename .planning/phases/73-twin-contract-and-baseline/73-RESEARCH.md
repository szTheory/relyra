# Phase 73: Twin Contract and Baseline - Research

**Researched:** 2026-09-09
**Domain:** Executable evidence governance, repository quality baselining, and CI ownership
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| EVID-01 | Maintainer can inspect a machine-checked ledger mapping evaluator, developer, tenant-admin, security-reviewer, SRE, and end-user journeys to automated evidence. [VERIFIED: .planning/REQUIREMENTS.md:9-13] | Use one literal Elixir evidence registry plus an ExUnit contract that checks persona, outcome, requirement, owner, evidence kind, and lane completeness. |
| EVID-02 | Every new acceptance criterion is enforced by deterministic automation in a mandatory CI lane. [VERIFIED: .planning/REQUIREMENTS.md:9-13] | Add a named `ci.evidence` alias and workflow step; structurally prove that completed criteria have an existing deterministic owner wired into that lane. |
| QUAL-01 | Maintainer can inspect a repository-wide, severity-ranked quality inventory covering correctness, security, integration, readability, documentation, and artifacts. [VERIFIED: .planning/REQUIREMENTS.md:41-48] | Commit a dated baseline with one shared severity vocabulary, evidence, disposition, target phase, and approval gate per finding. |
| PIPE-01 | Maintainer can inspect current CI duration, duplication, ownership, cache behavior, and failure-mode evidence before optimization. [VERIFIED: .planning/REQUIREMENTS.md:50-56] | Record current workflow topology, live run timings, repeated work, cache declarations, required-check drift, and artifact behavior without optimizing yet. |
| GOV-01 | Public API, default-tightening, security-posture, and real SemVer-major changes stop at an explicit approval checkpoint. [VERIFIED: .planning/REQUIREMENTS.md:64-68] | Define named blocking checkpoint classes and require future plans either to contain the relevant checkpoint before mutation or state that the class is untouched. |
| GOV-02 | The milestone introduces no speculative SAML protocol capability or unrelated product expansion. [VERIFIED: .planning/REQUIREMENTS.md:64-68] | Keep the milestone feature-neutral and add a plan-scope guard for the three exact demand-gated identifiers. |
</phase_requirements>

## Summary

Phase 73 should establish a small executable control plane for the rest of v1.11, not implement the twins themselves. The repository already has the right primitives: literal ExUnit contracts, AST-based inspection of `mix.exs`, dedicated Mix aliases, GitHub Actions lanes, and meta-tests that detect hollow security gates. The existing anti-hollow test parses `mix.exs` as Elixir AST and proves each security suite exists, is wired, uses a fresh `cmd mix test` process, and has a real `--only` tag. [VERIFIED: test/security/ci_gate_integrity_test.exs:28-153] Reuse that structural pattern for evidence ownership instead of creating a new parser, DSL, service, or production dependency.

The durable contract should have two linked artifacts: an executable evidence ledger under `test/support/` and a dated baseline report in this phase directory. The ledger should enumerate all six required personas verbatim — `evaluator`, `developer`, `tenant-admin`, `security-reviewer`, `SRE`, and `end-user` — and link their lifecycle outcomes to a requirement ID, evidence class, concrete test/workflow owner, mandatory lane, fixture/reset boundary, and failure-diagnostic expectation. [VERIFIED: .planning/REQUIREMENTS.md:9-13] Planned later-phase evidence may be named before its file exists, but a requirement may be marked complete only when at least one deterministic owner exists on disk and is structurally wired into mandatory CI; an external canary never substitutes for that merge proof. [VERIFIED: AGENTS.md:60-70]

The initial baseline is healthy but not empty. Local `mix qa` passes `794 tests, 0 failures (10 excluded)` in `14.18s`, while emitting a four-file Mix test-pattern warning. [VERIFIED: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix qa`, run 2026-09-09] The last main `security-gates` run completed successfully in 337 seconds, but it sequentially repeats full QA and the overlapping fast lane in both OTP matrix jobs. [VERIFIED: GitHub Actions run 33137958429, queried with `gh run view` 2026-09-09] More urgently, repository code declares required checks `"security (27, 1.19.5)"`, `"security (28, 1.19.5)"`, and `"fleet-proxy-e2e"`, while the live branch-protection API currently returns only the two security checks and the re-assertion workflow is `disabled_inactivity`. [VERIFIED: scripts/setup_branch_protection.sh:18-23; GitHub branch-protection/workflow APIs queried 2026-09-09] Record this as a HIGH governance/CI finding and stop at the remote-mutation checkpoint; do not repair it silently in Phase 73.

**Primary recommendation:** Build one test-only evidence registry, one named `ci.evidence` owner lane, one meta-contract that makes evidence closure fail closed, and one evidence-backed baseline report; defer all fixes and optimizations to their mapped phases unless Phase 73 needs a minimal change to make its own contract mandatory.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Persona/job/evidence ledger | Test / Repository contract | CI | This is executable repository metadata, not runtime application state. [VERIFIED: .planning/research/FEATURES.md:91-107] |
| Acceptance-closure policy | Test / Repository contract | CI | ExUnit validates the ledger and repository wiring; CI makes the result mandatory. [VERIFIED: AGENTS.md:62-70] |
| Quality baseline | Maintainer / Repository documentation | CI telemetry | Findings are durable planning input; command and live-run evidence make them reproducible. [VERIFIED: .planning/REQUIREMENTS.md:41-56] |
| CI duration/duplication inventory | CI | Maintainer documentation | Workflow/run data owns timing and topology truth; the baseline explains it without optimizing. [VERIFIED: .planning/ROADMAP.md:67-76] |
| Approval checkpoints | Planning / Execution orchestration | Repository policy test | GSD checkpoints stop mutation; structural tests can detect missing declarations but cannot grant approval. [VERIFIED: .planning/milestones/v1.9-phases/66-demo-fakeidp-disposition/66-02-PLAN.md:41-67] |
| SAML authentication/security behavior | API / Backend | Database / Storage | Phase 73 must not change it; all existing trust seams remain owned by library runtime code. [VERIFIED: AGENTS.md:38-58] |

## Project Constraints (from AGENTS.md)

- Read the active phase plan and `.planning/STATE.md` before implementation; do not implement outside the active plan. There is currently no active plan, so this research must not implement source changes. [VERIFIED: AGENTS.md:13-22]
- Stop for explicit approval before changing the public API shape (`Relyra.start_login/3`, `consume_response/3`, or a published behaviour callback), tightening a default, changing security posture, or making a real SemVer-major bump. [VERIFIED: AGENTS.md:24-36]
- Preserve configured-IdP-cert-only signature trust, the one Saxy parse path, raw-binary pre-parse guards, digest recomputation and `:public_key.verify`, audit co-commit, and production replay protection. [VERIFIED: AGENTS.md:38-47]
- Do not bypass the named crypto, XML, C14N, algorithm-policy, audit-writer, or behaviour seams. [VERIFIED: AGENTS.md:49-58]
- Before pushing main, run `mix qa`; keep `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` green. Every security suite inside `mix ci.security` remains a separate fresh-process `cmd mix test`. [VERIFIED: AGENTS.md:60-67]
- New acceptance criteria require deterministic automated evidence in mandatory CI. Do not introduce blocking manual verification, manual-only validation, `human_needed`, or required UAT artifacts. External state belongs in isolated harnesses or scheduled canaries. [VERIFIED: AGENTS.md:68-70]
- Use conventional commits, never hand-edit `CHANGELOG.md`, never manually run `mix hex.publish`, and include the required co-author trailer in implementation commits. [VERIFIED: AGENTS.md:72-87]

## Standard Stack

No external package installation is needed for Phase 73. [VERIFIED: .planning/research/STACK.md:9-24]

### Core

| Tool | Version | Purpose | Why Standard Here |
|---|---|---|---|
| Elixir / ExUnit / Mix | Elixir and Mix `1.19.5`, OTP `28` | Literal ledger, repository policy tests, CI aliases | Already project-required and locally installed under the explicit ASDF profile. [VERIFIED: `elixir --version`; mix.exs:9-23] |
| Elixir AST (`Code.string_to_quoted!/1`, `Macro.prewalker/1`) | bundled with Elixir 1.19.5 | Inspect aliases without brittle bracket/string scanning | Existing anti-hollow gate uses this exact pattern. [VERIFIED: test/security/ci_gate_integrity_test.exs:48-87] |
| GitHub Actions | repository workflows | Mandatory named lane, external canaries, live timing evidence | Existing repository CI surface; no new CI service is justified. [VERIFIED: .github/workflows/security-gates.yml:1-110] |
| GitHub CLI | `2.95.0` locally | Read live runs/workflows/protection; propose exact remote batch | Available and authenticated for read-only inventory. [VERIFIED: `gh --version` and `gh auth status`, 2026-09-09] |

### Supporting

| Tool | Version | Purpose | When to Use |
|---|---|---|---|
| actionlint | `1.7.12` | Static GitHub Actions syntax check | Run after any local workflow edit; current 14 workflows pass. [VERIFIED: `actionlint --version`; `actionlint .github/workflows/*.yml`, 2026-09-09] |
| Existing Markdown parsers-by-contract | repository-local regex/AST helpers | Extract requirement IDs and status markers | Keep extraction narrow and test it against repeated/malformed markers. [VERIFIED: test/docs/demo_guide_drift_test.exs:901-947] |
| `mix cmd` | Mix 1.19.5 | Spawn independent test processes inside a compound alias | Official Mix docs state `mix cmd` is automatically re-enabled; the repository relies on it to prevent task deduplication. [CITED: https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Cmd.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Literal Elixir ledger | YAML/JSON plus a new parser | Adds format/parser surface with no benefit; the ledger is test-only and Elixir already validates types/patterns. [ASSUMED] |
| Repository meta-tests | External policy/SaaS | Adds another availability and trust boundary; would not run in the local `mix qa` contract. [ASSUMED] |
| A dedicated `ci.evidence` lane | Rely only on broad `mix qa` | Broad QA proves execution but obscures ownership and makes closure-to-lane mapping ambiguous. [VERIFIED: .planning/REQUIREMENTS.md:50-56] |

**Installation:** None. Do not add dependencies in this phase.

## Architecture Patterns

### System Architecture Diagram

```text
REQUIREMENTS.md + ROADMAP.md + future PLAN.md files
                    |
                    v
       Evidence registry (literal entries)
       persona -> job/outcome -> requirement
       -> deterministic owner -> named CI lane
                    |
          +---------+------------------+
          |                            |
          v                            v
 Evidence contract tests       Baseline inventory
 - schema/uniqueness           - severity + category
 - persona/outcome coverage    - command/run evidence
 - closed criterion owner      - disposition/target phase
 - file + alias + workflow                 |
          |                                v
          v                         later Phases 74-79
      mix ci.evidence
          |
          v
 mandatory GitHub Actions step/status
          |
          +---- fail: criterion stays open
          |
          +---- pass: deterministic closure permitted

External provider/service ----> scheduled conditional job
                                      |
                                      +--> retained safe diagnostics
                                      `--> NEVER satisfies deterministic closure alone

Risky planned mutation -------> named blocking checkpoint
                                public_api | default_tightening |
                                security_posture | semver_major |
                                remote_github
                                      |
                              explicit approval before mutation
```

### Recommended Project Structure

```text
test/
├── support/
│   └── adoption_evidence.ex          # literal registry; no runtime/package surface
├── adoption/
│   └── evidence_contract_test.exs    # schema, coverage, closure, lane wiring
└── governance/
    └── milestone_scope_test.exs      # checkpoints/manual-gate/demand-gated scope rules

.planning/phases/73-twin-contract-and-baseline/
├── 73-RESEARCH.md
└── 73-BASELINE.md                    # dated quality + CI snapshot, not product docs

mix.exs                               # ci.evidence alias + preferred test env
.github/workflows/security-gates.yml  # clearly named Evidence contract lane
```

The exact new paths above are recommendations rather than existing discrete values. [ASSUMED] They keep executable governance out of `lib/` and keep temporary internal baseline narration out of adopter-facing documentation, consistent with the later requirement that product docs contain timeless rationale. [VERIFIED: .planning/REQUIREMENTS.md:41-48]

### Pattern 1: Literal Registry + Contract Test

**What:** Put data in a normal test-support module; keep all validation in focused ExUnit tests.

**When to use:** Always for the phase ledger. Do not build a scenario DSL.

The repository research explicitly recommends evidence classes `package-contract`, `application`, `browser`, `external-canary`, and `security corpus`, plus owner/reset/failure-diagnostic metadata. [VERIFIED: .planning/research/FEATURES.md:91-102] It also says a small typed data module is preferable to a custom DSL. [VERIFIED: .planning/research/ARCHITECTURE.md:63-81]

```elixir
# Recommended shape; identifiers are requirement/persona values quoted from REQUIREMENTS.md.
%{
  id: "JOUR-01:end-user:sp-login",
  requirement: "JOUR-01",
  personas: [:end_user],
  job: "Complete SP-initiated login",
  expected_outcome: "Mapped adopter-owned session and authorization outcome",
  evidence_kind: :application,
  owner: "test/adoption/journey_03_production_acs_test.exs",
  lane: :ci_evidence,
  state: :existing,
  fixture_owner: :root_test,
  reset_boundary: :sql_sandbox,
  failure_diagnostics?: true
}
```

The quoted source values are: `JOUR-01`, `end user`, `SP-initiated login`, and `correctly mapped adopter-owned session and authorization outcome`. [VERIFIED: .planning/REQUIREMENTS.md:32-39] The atom spellings and field names in this recommended skeleton are new conventions. [ASSUMED]

### Pattern 2: Two-Stage Closure Rule

**What:** Allow future evidence to be declared as planned, but fail if a completed requirement lacks live deterministic proof.

**When to use:** Every active v1.11 requirement.

1. Registry coverage test: every known requirement/persona/outcome has a unique entry and a named owner/lane, even when `state: :planned`. [ASSUMED]
2. Closure test: every `[x]` v1.11 requirement must have at least one deterministic entry whose file exists, selector matches at least one test, Mix alias includes it, and the workflow invokes that alias. [ASSUMED]
3. External-canary entries may supplement a requirement but cannot be the only closure owner. [VERIFIED: AGENTS.md:68-70]
4. Preserve an explicit negative test: temporarily mark a fixture criterion complete with a missing owner and assert the validator fails with the criterion ID and missing seam. [ASSUMED]

### Pattern 3: Parse Source Structures, Not Incidental Text

**What:** Parse `mix.exs` with Elixir AST, and keep Markdown extraction anchored to headings/checklist syntax with characterization fixtures.

**When to use:** Lane wiring and requirement/plan policy checks.

The existing CI meta-gate deliberately uses `Code.string_to_quoted!` and `Macro.prewalker` because comments and string delimiters make byte/bracket scanning unsafe. [VERIFIED: test/security/ci_gate_integrity_test.exs:48-76] Reuse or extract that helper rather than reimplementing another alias parser. For Markdown, use narrowly anchored expressions and add malformed/repeated-token tests, following the existing roadmap policy seam. [VERIFIED: test/docs/demo_guide_drift_test.exs:901-947]

### Pattern 4: Named Blocking Governance Checkpoints

**What:** Future plans use `<task type="checkpoint:decision" gate="blocking">` before a choice that changes public API/default/security/SemVer posture, and `<task type="checkpoint" gate="blocking">` before an exact remote GitHub mutation batch. [VERIFIED: .planning/milestones/v1.9-phases/66-demo-fakeidp-disposition/66-02-PLAN.md:41-67]

**When to use:** The exact trigger set is `public API`, `default-tightening`, `security-posture`, `real SemVer-major`, or `remote GitHub` change. [VERIFIED: .planning/REQUIREMENTS.md:58-67; AGENTS.md:24-32]

Each checkpoint should name the proposed mutation, affected files/API/settings, security/default/SemVer impact, automated preflight evidence, exact remote commands if any, rollback, and resume signal. [ASSUMED] A plan with none of these changes should state a negative scope assertion so the checker and reviewer can distinguish “not applicable” from “forgotten.” [ASSUMED]

### Anti-Patterns to Avoid

- **One row per test file:** Ledger rows represent adopter jobs/outcomes; one job may need multiple evidence layers and one test may support multiple jobs. [VERIFIED: .planning/research/ARCHITECTURE.md:83-94]
- **Canary equals merge proof:** External state is scheduled/dispatchable evidence, never the only deterministic owner. [VERIFIED: .planning/research/ARCHITECTURE.md:83-94]
- **Broad green lane with no owner:** `mix qa` being green is not enough to show which criterion it proves; keep a named evidence alias and structural wiring test. [VERIFIED: .planning/REQUIREMENTS.md:50-56]
- **Regex-parsing `mix.exs`:** Comments, quoted strings, and brackets can create false wiring proof. [VERIFIED: test/security/ci_gate_integrity_test.exs:48-54]
- **Implementing baseline findings in Phase 73:** Record and route them unless a minimal fix is necessary for the Phase 73 contract itself. [VERIFIED: .planning/ROADMAP.md:48-54]
- **Remote repair during inventory:** Reading GitHub is allowed; enabling workflows or changing protection is a named approval checkpoint. [VERIFIED: .planning/ROADMAP.md:32-44]

## Initial Severity-Ranked Baseline

Use `Critical`, `High`, `Medium`, `Low`, and `Informational` across the baseline. This is a recommended repository-wide extension of the existing security ledger vocabulary. [ASSUMED] Preserve the existing security disposition rules verbatim: `High and Critical findings are release blockers until remediated and regression-tested`; `Medium findings require an explicit written disposition before release`; `Low and Informational findings may be deferred only if they remain recorded with owner and revisit date`. [VERIFIED: docs/security_findings.md:5-10]

| Severity | Category | Finding | Evidence | Recommended Disposition |
|---|---|---|---|---|
| High | Integration | Root adoption journeys execute inside Relyra and use private fixtures, so they do not prove the published Hex boundary. | `.planning/STATE.md` says exactly this. [VERIFIED: .planning/STATE.md:64-68] | Retain as Phase 74 scope; do not “fix” in Phase 73. |
| High | CI / Governance | Desired required checks contain three exact values — `"security (27, 1.19.5)"`, `"security (28, 1.19.5)"`, `"fleet-proxy-e2e"` — but live protection contains only the first two; `Branch Protection Apply` is `disabled_inactivity`. | [VERIFIED: scripts/setup_branch_protection.sh:18-23; GitHub APIs queried 2026-09-09] | Document exact repair batch, then stop for `remote_github` approval; likely Phase 79 execution unless Phase 73 ownership requires earlier repair. |
| Medium | Evidence / Correctness | Existing policy only rejects manual markers/UAT artifacts for incomplete phases; it does not prove criterion-to-owner-to-lane wiring. | Current test scans `"<human-check>"`, `"## Manual-Only Verifications"`, `"status: human_needed"`, and `*-UAT.md`. [VERIFIED: test/docs/demo_guide_drift_test.exs:901-947] | Create evidence registry, closure validator, and named lane in Phase 73. |
| Medium | CI cost / duplication | In each OTP matrix job, `mix qa` runs the full test suite, then `mix ci.fast` runs non-integration tests again before security/integration lanes. | Exact step order is `Quality gate`, `Fast lane`, `Security lane`, `Verification lane`, `Integration lane`. [VERIFIED: .github/workflows/security-gates.yml:73-110] Last main run: QA 66–69s, fast 20–22s, security 81–83s, integration 66–71s; workflow wall time 337s. [VERIFIED: GitHub Actions run 33137958429] | Baseline only. Phase 78 measures across multiple runs before changing topology. Preserve intentional independent GATE-02 defense. |
| Medium | Readability | Internal phase narration appears in 24 `lib/` files / 42 matching lines and 27 `test/` files / 54 matching lines under the scoped scan. | [VERIFIED: `rg -l/-n 'Phase [0-9]|phase [0-9]|PLAN-|UAT|GSD|\\.planning/' lib test`, excluding `test/fixtures`, 2026-09-09] | Route to Phase 77; preserve non-obvious security invariants while removing temporary narration. |
| Medium | Documentation | `docs/jtbd_gap_map.md` contains 11 matching phase/UAT narration lines, and `guides/getting_started.md` contains a planning/GSD-specific line. | [VERIFIED: same scoped `rg` scan; .planning/STATE.md:68-71] | Route to Phase 77; keep internal history in `.planning`, not product docs. |
| Low | Correctness / Artifacts | `mix qa` emits a test-pattern warning for four exact golden fixture paths: `test/fixtures/demo_host/golden/config/relyra_snippet.exs`, `.../connections.ex`, `.../user_mapper.ex`, and `.../router_injected.ex`. | [VERIFIED: local `mix qa`, 2026-09-09] | Classify/fix in Phase 77 without weakening fixture coverage. |
| Informational | Security | The only recorded security finding is `RELYRA-2026-001`, severity `Critical`, disposition `Confirmed -> Fixed in v1.1 (hex 1.2.0)`, blocker state `resolved`, with adversarial and CI meta-gate proof. | [VERIFIED: docs/security_findings.md:12-16] Local `mix ci.security` exited 0 in 107.30s on 2026-09-09. | Preserve regression proof; no security-posture change in Phase 73. |
| Informational | Artifacts | The scoped tracked-file scan found no committed `_build`, `deps`, `node_modules`, Playwright report, screenshot, temp, backup, or log path. The only worktree item is user-owned untracked `.tool-versions`. | [VERIFIED: `git ls-files` suspect-path scan and `git status --short`, 2026-09-09; .planning/STATE.md:74-77] | Preserve `.tool-versions`; re-inventory in Phase 79. |

### CI Baseline Snapshot

| Surface | Current Observation | Ownership / Risk |
|---|---|---|
| Workflow topology | 14 tracked workflow YAML files; all pass actionlint 1.7.12. [VERIFIED: `rg --files .github/workflows`; `actionlint`, 2026-09-09] | Inventory truth only; count is not a quality metric. |
| Main security gate | Two jobs: `security (27, 1.19.5)` and `security (28, 1.19.5)`; latest main run succeeded in 337s. [VERIFIED: .github/workflows/security-gates.yml:40-56; GitHub run 33137958429] | Mandatory live required checks currently include both. |
| Security independence | Thirteen exact gated suite entries are structurally enforced, and each uses a fresh process. [VERIFIED: test/security/ci_gate_integrity_test.exs:28-46,98-153] | Do not collapse during later optimization. |
| Root dependency caching | `security-gates` declares npm cache at `cache: npm`; dependencies are installed with `mix deps.get` and `npm install`. [VERIFIED: .github/workflows/security-gates.yml:46-80] | No optimization in Phase 73; Phase 78 measures cold/warm behavior first. |
| Demo app CI | Latest main run succeeded in 126s; workflow runs OTP `27` and `28` matrix jobs. [VERIFIED: .github/workflows/demo-app-ci.yml:38-63; GitHub run 33137958463] | Separate app boundary, but currently still path dependency based. |
| Demo browser E2E | Latest main run succeeded in 132s and runs FakeIdP then trace-visual browser journeys. [VERIFIED: .github/workflows/demo-app-e2e.yml:55-83; GitHub run 33137958469] | Deterministic owned-browser evidence. |
| Fleet proxy | Latest scheduled run succeeded in 246s. Hermetic `fleet-proxy-e2e` runs on PR/push/schedule; `rulestead-main-canary` is conditionally schedule/dispatch only and retains diagnostics 7 days. [VERIFIED: .github/workflows/fleet-proxy-e2e.yml:3-88; GitHub run 34320178480] | Treat hermetic job as deterministic; treat Rulestead job as external canary. |
| Keycloak proxy | Latest scheduled run succeeded in 140s; workflow also runs on PR and push. [VERIFIED: .github/workflows/keycloak-proxy-e2e.yml:3-38; GitHub run 34321377185] | Container-owned Keycloak proof is deterministic despite “external IdP” language. |
| Branch protection | Live strict protection requires the two security matrix checks, not the desired `fleet-proxy-e2e` third check. [VERIFIED: GitHub branch-protection API, 2026-09-09] | HIGH drift; remote repair requires approval. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Ledger format | General scenario DSL or database | Literal Elixir data in test support | The milestone explicitly defers generalized fixture frameworks until repeated duplication justifies them. [VERIFIED: .planning/REQUIREMENTS.md:70-76] |
| Mix alias inspection | Regex/bracket scanner | `Code.string_to_quoted!` + AST walk | Existing proven seam avoids comment/string false positives. [VERIFIED: test/security/ci_gate_integrity_test.exs:48-87] |
| Mandatory status mechanism | Custom check API publisher | Existing GitHub Actions job/status | Required checks already gate main; custom publication creates spoofing/ownership complexity. [CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |
| Approval state | Homegrown approval file or `human_needed` status | GSD blocking checkpoint with explicit resume signal | Manual completion states are forbidden; approval is only for decisions/mutations, not acceptance proof. [VERIFIED: AGENTS.md:68-70; .planning/milestones/v1.9-phases/66-demo-fakeidp-disposition/66-02-PLAN.md:43-67] |
| CI duration store | New telemetry service | GitHub run/job timestamps captured in dated baseline | Current need is a before-snapshot, not continuous analytics. [ASSUMED] |
| Security evidence | New security scanner/framework | Existing `mix ci.security`, adversarial corpus, findings ledger | Phase 73 changes evidence governance, not trust behavior. [VERIFIED: AGENTS.md:60-67] |

**Key insight:** The difficult part is not serializing rows; it is proving that a closed criterion's named owner exists, selects real tests, executes in a mandatory lane, and cannot be replaced by prose or a flaky external service.

## Common Pitfalls

### Pitfall 1: Ledger Coverage Without Executable Ownership

**What goes wrong:** Every persona has a row, but the owner is a free-form command/path that no mandatory workflow invokes.

**Why it happens:** Schema validation is mistaken for behavioral proof.

**How to avoid:** Resolve file/selector/alias/workflow as a chain and add a mutation test that breaks each link in turn. [ASSUMED]

**Warning signs:** `owner` strings are never opened, selectors may match zero tests, or the workflow step is absent.

### Pitfall 2: Planned Evidence Accidentally Counts as Complete

**What goes wrong:** Later phase placeholders let requirements close before tests exist.

**Why it happens:** The ledger needs forward planning, but planned and live evidence share one shape.

**How to avoid:** Keep explicit `planned` versus `existing` state; only existing deterministic entries satisfy `[x]` criteria. [ASSUMED]

**Warning signs:** A completed criterion points to a nonexistent file or scheduled canary only.

### Pitfall 3: Broad Mix Aliases Become Hollow

**What goes wrong:** Repeated bare `test` tasks are silently deduplicated in the same Mix invocation.

**Why it happens:** Mix tasks normally run once; later calls return `:noop` unless re-enabled/rerun. [CITED: https://hexdocs.pm/mix/Mix.Task.html]

**How to avoid:** Give the evidence contract one focused alias; use a fresh `cmd mix test` when composing independently gated suites. Preserve the existing security gate invariant. [VERIFIED: mix.exs:234-268]

**Warning signs:** Multiple bare `test ...` strings in one compound alias, or an `--only` tag with no exact tag declaration.

### Pitfall 4: Required Workflow Is Path-Filtered Away

**What goes wrong:** A required check stays Pending when its workflow is skipped, blocking or confusing closure.

**Why it happens:** GitHub retains required workflow checks in Pending state when path/branch filtering prevents the workflow from running. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow]

**How to avoid:** Ensure the named evidence owner runs for every change that can close a criterion. Characterize the existing planning-only trigger behavior before changing filters. [ASSUMED]

**Warning signs:** Acceptance status can change under `.planning/**` without the evidence contract producing a fresh status.

### Pitfall 5: Duplicate or Ambiguous Status Names

**What goes wrong:** Branch protection accepts or waits on the wrong check.

**Why it happens:** GitHub warns that duplicate job names across workflows create ambiguous required statuses. [CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches]

**How to avoid:** Use one unique evidence job name and include it exactly once in the intended protection proposal. [ASSUMED]

**Warning signs:** The same `jobs.<id>.name` appears in multiple workflows or setup scripts duplicate a list that can drift.

### Pitfall 6: Baseline Turns Into an Unbounded Cleanup Phase

**What goes wrong:** Phase 73 starts fixing every warning/comment/workflow before the twin safety net exists.

**Why it happens:** Inventory and remediation are conflated.

**How to avoid:** Record severity, evidence, owner, target phase, and approval class; only fix what is necessary to make the evidence contract itself mandatory. [VERIFIED: .planning/ROADMAP.md:48-54]

**Warning signs:** Production `lib/` edits, protocol changes, or CI optimization tasks appear in the Phase 73 plan.

### Pitfall 7: Approval Checkpoint Becomes Manual Acceptance

**What goes wrong:** A human checkbox is used to declare tests or requirements complete.

**Why it happens:** Governance approval and verification evidence are both described as “gates.”

**How to avoid:** Use checkpoints only to authorize a risky decision or remote mutation. Deterministic automation remains the completion evidence. [VERIFIED: AGENTS.md:28-32,68-70]

**Warning signs:** `human_needed`, manual-only verification, required UAT, or a checkpoint whose only purpose is to say tests “look good.”

## Code Examples

### Structural Lane Ownership

```elixir
# Pattern source: test/security/ci_gate_integrity_test.exs:55-76
defp alias_steps(alias_name) do
  "mix.exs"
  |> File.read!()
  |> Code.string_to_quoted!()
  |> Macro.prewalker()
  |> Enum.find_value(fn
    {key, list} when is_list(list) ->
      if alias_key?(key, alias_name) and Enum.all?(list, &is_binary/1), do: list

    _ ->
      nil
  end)
end
```

This example uses existing API values verbatim from the opened source: `Code.string_to_quoted!`, `Macro.prewalker`, `mix.exs`, and the flat list-of-strings alias shape. [VERIFIED: test/security/ci_gate_integrity_test.exs:48-76]

### Closure Validator Shape

```elixir
# Recommended new project code; field names/status atoms are [ASSUMED].
for requirement <- completed_requirements() do
  owners = EvidenceLedger.deterministic_owners(requirement)

  assert owners != [],
         "#{requirement} is complete but has no deterministic evidence owner"

  for owner <- owners do
    assert owner.state == :existing
    assert File.exists?(owner.path)
    assert lane_references_owner?(owner.lane, owner)
    assert workflow_runs_lane?(owner.lane)
  end
end
```

### Blocking Remote Mutation Checkpoint

```xml
<!-- Pattern source: historical approved checkpoint forms. -->
<task type="checkpoint" gate="blocking">
  <name>Approve exact remote GitHub mutation batch</name>
  <action>
    Present current state, desired state, exact gh/API commands, affected checks,
    automated preflight, rollback, and expected postcondition. Wait for explicit approval.
  </action>
  <resume-signal>Explicit approval of the exact batch.</resume-signal>
</task>
```

`checkpoint`, `checkpoint:decision`, `gate="blocking"`, and `resume-signal` are existing plan vocabulary. [VERIFIED: .planning/milestones/v1.9-phases/66-demo-fakeidp-disposition/66-02-PLAN.md:41-67; .planning/milestones/v1.5-phases/44-release-please-pipeline-diagnosis-v1-4-0-hex-publish/44-02-PLAN.md:50-75]

## State of the Art

| Old / Current Weak Shape | Phase 73 Shape | Impact |
|---|---|---|
| Prose persona/JTBD map | Literal registry validated by ExUnit | Maintainer can trace job → outcome → owner → lane. [VERIFIED: .planning/research/FEATURES.md:19-28,91-107] |
| Manual-marker ban only | Closed-criterion deterministic owner contract | Prevents both explicit manual gates and subtler ownerless/hollow closures. [VERIFIED: test/docs/demo_guide_drift_test.exs:901-947] |
| Broad green workflows | Named owning lane plus structural integrity test | Makes evidence responsibility inspectable before Phase 78 optimization. [VERIFIED: .planning/REQUIREMENTS.md:50-56] |
| Ad hoc audit notes | Dated, severity-ranked, evidence-backed baseline | Gives Phases 74–79 stable input and a before-measurement. [VERIFIED: .planning/ROADMAP.md:48-54] |
| Silent risky-scope assumptions | Named blocking checkpoints / negative scope assertions | Execution cannot cross public/default/security/SemVer/remote boundaries implicitly. [VERIFIED: .planning/ROADMAP.md:32-44] |

**Deprecated/outdated:**

- Required manual UAT or `human_needed` completion is prohibited for new acceptance criteria. [VERIFIED: AGENTS.md:68-70]
- A second generalized scenario/fixture framework is deferred until duplication demonstrates demand. [VERIFIED: .planning/REQUIREMENTS.md:70-76]
- Treating the entire Keycloak/Fleet workflow family as uniformly “external” is too coarse: hermetic/container-owned jobs can be deterministic, while the moving Rulestead checkout is a scheduled external canary. [VERIFIED: .github/workflows/fleet-proxy-e2e.yml:22-88; .github/workflows/keycloak-proxy-e2e.yml:15-38]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Recommended new paths are `test/support/adoption_evidence.ex`, `test/adoption/evidence_contract_test.exs`, `test/governance/milestone_scope_test.exs`, and `73-BASELINE.md`. | Architecture Patterns | Low; planner may choose equivalent paths but must preserve responsibilities. |
| A2 | The registry uses the proposed field/atom schema and `planned`/`existing` lifecycle. | Architecture Patterns / Code Examples | Medium; a weaker schema could allow premature closure. |
| A3 | A dedicated `ci.evidence` alias is preferable to naming only `mix qa` as owner. | Standard Stack | Medium; lane naming affects future branch-protection topology. |
| A4 | One dated GitHub run plus current workflow source is enough for Phase 73's initial before-snapshot; multi-run statistical optimization belongs to Phase 78. | CI Baseline | Low; planner may collect a wider sample without changing the recommendation. |
| A5 | The universal quality severity vocabulary extends the existing security ledger's five levels. | Initial Severity-Ranked Baseline | Low; only naming changes if the maintainer prefers another rubric. |
| A6 | Literal Elixir data is preferable to YAML/JSON or an external policy service for this test-only contract. | Alternatives Considered | Low; an equivalent dependency-free representation can work if it remains locally executable. |
| A7 | The closure validator resolves file → selector → alias → workflow, distinguishes planned/existing evidence, and carries negative mutation fixtures. | Architecture Patterns / Common Pitfalls | Medium; omitting a link can permit false closure. |
| A8 | Checkpoints include mutation scope, impact, preflight, exact remote commands, rollback, and resume signal; no-risk plans make a negative scope assertion. | Architecture Patterns | Medium; this is the proposed governance contract. |
| A9 | GitHub run/job timestamps in a dated baseline are sufficient for the initial snapshot without a new telemetry service. | Don't Hand-Roll | Low; Phase 78 may add repeat sampling. |
| A10 | The focused contract files and `ci.evidence` alias fit a sub-30-second per-task loop and the listed Wave 0 file split. | Validation Architecture | Low; planner can merge files if runtime remains focused and ownership stays clear. |
| A11 | Structural negative fixtures, unique status names, and postcondition read-back are the appropriate mitigations for evidence spoofing/tampering risks. | Security Domain | Medium; tests must demonstrate these mitigations rather than merely documenting them. |

## Open Questions (RESOLVED)

1. **Should the new evidence lane itself become a distinct live required status in Phase 73?**
   - What we know: EVID-02 requires a mandatory owner; live main currently requires two security matrix statuses, and the desired third Fleet status is already missing. [VERIFIED: .planning/REQUIREMENTS.md:9-13; GitHub branch-protection API, 2026-09-09]
   - **RESOLVED:** In Phase 73, `ci.evidence` is a clearly named step within the already-required security jobs, and structural tests prove that wiring. It does not become a separate required status. Any later change to live required contexts remains an exact remote batch behind the `remote_github` checkpoint.

2. **When should the existing branch-protection drift be repaired?**
   - What we know: repository intent includes `fleet-proxy-e2e`; live protection omits it; the apply workflow is disabled for inactivity. [VERIFIED: scripts/setup_branch_protection.sh:18-23; GitHub APIs, 2026-09-09]
   - **RESOLVED:** Record the drift as a HIGH baseline item and target its exact proposed repair batch to Phase 79. Phase 73 performs no remote GitHub mutation.

## Environment Availability

| Dependency | Required By | Available | Version / State | Fallback |
|---|---|---|---|---|
| Elixir / Mix | Contract tests and aliases | ✓ via explicit ASDF selection | Elixir/Mix `1.19.5`, OTP `28` | Set `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.4.1`; do not edit user-owned `.tool-versions`. [VERIFIED: local probes; .planning/STATE.md:74-77] |
| PostgreSQL | Existing full QA | ✓ | `/tmp:5432 - accepting connections` | Phase 73 focused tests should avoid DB unless proving an existing owner. [VERIFIED: `pg_isready`, 2026-09-09] |
| GitHub CLI / API | Live CI/protection inventory | ✓ | gh `2.95.0`, authenticated | Store command evidence in baseline; do not mutate remotely without approval. [VERIFIED: local probes] |
| actionlint | Workflow static validation | ✓ | `1.7.12` | GitHub workflow parser on PR if local tool unavailable. [VERIFIED: local probe] |
| Node/npm | Existing browser workflow inspection | ✓ | Node `22.14.0`, npm `11.1.0` | Not needed to implement the ledger itself. [VERIFIED: local probes] |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Default `elixir`/`mix` shims have no project selection because `.tool-versions` is user-owned and Node-only; use the explicit installed ASDF environment above. [VERIFIED: local command failure and .planning/STATE.md:74-77]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit bundled with Elixir 1.19.5 [VERIFIED: mix.exs:9-23; local version probe] |
| Config file | `config/test.exs` [VERIFIED: config/test.exs:1-43] |
| Quick run command | `mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --warnings-as-errors` [ASSUMED paths] |
| Owning lane command | `mix ci.evidence` [ASSUMED new alias] |
| Full suite command | `mix qa && mix ci.security` [VERIFIED: AGENTS.md:60-67] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| EVID-01 | Required personas/jobs/outcomes have unique, complete ledger entries | unit/contract | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` | ❌ Wave 0 |
| EVID-02 | Completed criteria have an existing deterministic owner wired to a mandatory lane; manual/canary-only closure fails | structural integration | `mix ci.evidence` | ❌ Wave 0 |
| QUAL-01 | Baseline contains every required category, allowed severity, evidence, disposition, and target | document contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ❌ Wave 0 |
| PIPE-01 | Baseline records workflow count/topology, durations, duplication, cache declarations, ownership, and failure evidence | document contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ❌ Wave 0 |
| GOV-01 | Risky plan classes require named blocking checkpoint before mutation | plan policy contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ❌ Wave 0 |
| GOV-02 | Active milestone plans do not implement the exact deferred IDs `AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01` | plan scope contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` | ❌ Wave 0 |

The deferred identifier quote is verbatim from the project config and state. [VERIFIED: .planning/config.json:79-89; .planning/STATE.md:88-96]

### Sampling Rate

- **Per task commit:** focused contract file(s), under 30 seconds expected based on current local suite timing. [ASSUMED]
- **Per wave merge:** `mix ci.evidence && mix qa`. [ASSUMED new alias; VERIFIED existing `mix qa`: AGENTS.md:60-67]
- **Phase gate:** `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, `mix format --check-formatted`, and `actionlint .github/workflows/*.yml` all green before `$gsd-verify-work`. [VERIFIED: AGENTS.md:60-70]

### Wave 0 Gaps

- [ ] `test/support/adoption_evidence.ex` — literal ledger and query helpers. [ASSUMED path]
- [ ] `test/adoption/evidence_contract_test.exs` — schema, coverage, planned/existing, closure, owner, alias, and workflow wiring. [ASSUMED path]
- [ ] `test/governance/milestone_scope_test.exs` — baseline category/severity checks, checkpoint rules, manual-gate prohibition, and deferred scope identifiers. [ASSUMED path]
- [ ] `mix.exs` — add `ci.evidence` to `preferred_envs` and aliases, with an independently executing focused test command. [ASSUMED]
- [ ] `.github/workflows/security-gates.yml` — add a uniquely named Evidence contract step and prove its presence structurally. [ASSUMED]
- [ ] Characterization fixtures for missing owner, canary-only owner, zero-match selector, unwired alias, missing checkpoint, and forbidden deferred ID. [ASSUMED]

## Security Domain

Phase 73 changes governance and test metadata only. It must preserve, not redesign, Relyra's authentication, session, access-control, input-validation, and cryptography behavior. [VERIFIED: AGENTS.md:38-58]

### Applicable ASVS Categories

ASVS 5.0 renamed/reorganized some chapter numbers, so use the current category names rather than assuming ASVS 4.x numbers. [CITED: https://github.com/OWASP/ASVS/tree/master/5.0/en]

| ASVS Category | Applies | Standard Control |
|---|---|---|
| Architecture / secure lifecycle | yes | Evidence registry and change checkpoint preserve explicit security boundaries and verification ownership. [ASSUMED mapping] |
| Authentication | yes, preservation only | Existing signed SAML trust path, typed rejection, and configured certificate source remain unchanged. [VERIFIED: AGENTS.md:38-47] |
| Session management | yes, preservation only | Existing replay protection and adopter-owned session boundary remain evidence targets. [VERIFIED: AGENTS.md:46-47; .planning/REQUIREMENTS.md:32-39] |
| Authorization / access control | yes, evidence only | Ledger includes tenant isolation and mapped authorization outcomes; no policy change in this phase. [VERIFIED: .planning/REQUIREMENTS.md:34-39] |
| Validation / sanitization / encoding | yes, preservation only | Existing raw-binary XML guards and single parse path remain immutable. [VERIFIED: AGENTS.md:42-45] |
| Cryptography | yes, preservation only | Existing digest recomputation, `:public_key.verify`, algorithm policy, and configured certificate source remain immutable. [VERIFIED: AGENTS.md:42-46] |

### Known Threat Patterns for the Evidence/Governance Stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Hollow evidence owner: path/selector exists in prose but does not execute | Tampering | Structural file, selector, alias, and workflow tests; negative mutation fixtures. [ASSUMED] |
| External canary treated as deterministic proof | Spoofing | Distinct evidence class; canary-only rows cannot close a criterion. [VERIFIED: AGENTS.md:68-70] |
| Ambiguous duplicate status names satisfy wrong protection context | Spoofing / Tampering | Unique job/status names and live protection inventory. [CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |
| CI output/artifact leaks assertions, certs, credentials, or cookies | Information Disclosure | Ledger requires failure-diagnostic ownership; retain only redaction-safe artifacts. [VERIFIED: .planning/REQUIREMENTS.md:24-39] |
| Remote settings changed without review | Tampering / Repudiation | Exact mutation batch, blocking approval checkpoint, postcondition read-back. [VERIFIED: .planning/REQUIREMENTS.md:58-67] |
| “Cleanup” removes an independent security defense | Tampering | Baseline labels intentional duplicates (fresh security processes and standalone GATE-02) before Phase 78 optimization. [VERIFIED: mix.exs:241-268; .github/workflows/security-gates.yml:104-110] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` — security invariants, mandatory gates, approval classes, manual-acceptance prohibition.
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` — exact phase scope, requirement IDs, personas, deferred IDs, and baseline decisions.
- `.planning/research/{FEATURES,ARCHITECTURE,STACK,PITFALLS}.md` — approved milestone research on ledger shape, twin boundaries, evidence classes, and sequencing.
- `mix.exs`, `test/security/ci_gate_integrity_test.exs`, `test/docs/demo_guide_drift_test.exs` — current alias and structural policy seams.
- `.github/workflows/*.yml`, `scripts/setup_branch_protection.sh` — current CI topology and desired protection configuration.
- Local commands on 2026-09-09 — `mix qa`, `mix ci.security`, `actionlint`, version probes, tracked-artifact scan, phase-reference scan.
- GitHub CLI/API reads on 2026-09-09 — workflow states, branch protection, latest run/job timings. No remote mutations performed.

### Secondary (MEDIUM confidence)

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — job dependencies, permissions, path filters, schedule syntax.
- [Triggering a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow) — skipped/path-filtered required checks remain Pending.
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) — unique required job names and required status semantics.
- [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html) and [Mix.Tasks.Cmd](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Cmd.html) — once-per-invocation task behavior and automatic `cmd` re-enablement.
- [OWASP ASVS 5.0](https://github.com/OWASP/ASVS/tree/master/5.0/en) — current verification taxonomy.

### Tertiary (LOW confidence)

- None. All low-confidence design choices are explicitly listed in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new packages; all recommended primitives are current repository tools and locally probed.
- Architecture: HIGH — follows existing anti-hollow gate and milestone research; exact new file/schema names remain assumptions.
- Baseline: HIGH — backed by current local commands, opened workflow sources, and live GitHub API reads.
- Pitfalls: HIGH for Mix/GitHub gate behavior; MEDIUM for recommended new validator details.

**Research date:** 2026-09-09
**Valid until:** 2026-09-16 for live GitHub state/timings; 2026-10-09 for repository architecture.
