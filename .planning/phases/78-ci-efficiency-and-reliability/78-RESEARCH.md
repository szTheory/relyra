# Phase 78: CI Efficiency and Reliability - Research

**Researched:** 2026-09-27
**Domain:** Elixir/Mix CI evidence ownership, GitHub Actions, isolated package and browser verification
**Confidence:** MEDIUM overall; repository findings directly inspected and focused behavior reproduced

<user_constraints>
## User Constraints (from CONTEXT.md)

<!-- DATA_7f3d91ac_START -->
### Locked Decisions and Agent's Discretion

### Mandatory Lane Ownership
- **D-01:** Map every mandatory acceptance requirement to exactly one clearly named owning lane and show that mapping explicitly. Intentional independent security defenses may repeat proof, but must be identified as defense in depth rather than ambiguous ownership.
- **D-02:** Preserve deterministic automated acceptance and prohibit hollow or silently skipped Mix gates. The security alias's process boundaries and its integrity checks are part of the evidence contract.

### Measured Optimization and Isolation
- **D-03:** Base CI optimization decisions on multiple current runs; treat the Phase 73 single-run timings as historical baseline evidence, not current trend data. Reduce or retain work based on measured duration and setup cost.
- **D-04:** Preserve the clean-room package consumer's isolated dependency, build, and home paths. Checkout state or stale consumer state must not satisfy package-boundary evidence.
- **D-05:** Add or change caches only when measurements justify them. Compiled Mix cache keys must account for the OS, lockfile, and Elixir/OTP toolchain tuple. Treat restored caches as warm-start performance data, never as trusted verification evidence; still run locked dependency installation.

### Security Independence and Canary Boundaries
- **D-06:** Keep each `mix ci.security` suite in its own fresh `cmd mix test` process, preserve the hollow-gate integrity test, and retain standalone GATE-02 as an independent check. Do not collapse these into a single Mix `test` task that can be deduplicated or inherit another selector.
- **D-07:** Keep real-provider checks as scheduled canaries separate from deterministic merge gates. Required browser journeys remain deterministic and owned by mandatory CI.

### Workflow Controls and Failure Artifacts
- **D-08:** Apply explicit least-privilege permissions, clear workflow and job names, and non-colliding concurrency to mandatory workflows. Concurrency groups must be workflow-qualified and distinguish PR runs from branch runs; PR updates may cancel superseded PR work, while main runs must not be canceled by PR activity.
- **D-09:** Standardize action pins against current official releases when implementation begins. The 2026-09-27 research snapshot found `actions/checkout@v7`, `actions/setup-node@v7`, `actions/cache@v6`, and `actions/upload-artifact@v7` as current; `erlef/setup-beam@v1` remains the current major. Recheck exact releases before changing pins.
- **D-10:** Keep CI artifacts bounded, allowlisted, and redaction-safe. Do not retain assertions, certificates, credentials, cookies, or unfiltered browser diagnostics.
- **D-11:** Do not mutate remote branch protection or required-check settings in Phase 78; Phase 79 owns any approved remote batch.

### Clean-State Completion
- **D-12:** Demonstrate a clean-state pass for `mix qa`, formatting, warnings-as-errors compilation/tests, `mix ci.security`, package-consumer contracts, LedgerLoop tests, and required deterministic browser journeys. Include the post-transition governance lifecycle regression recorded in `.planning/STATE.md` in Phase 78 planning and verification evidence.

### Agent's Discretion
- Choose the number and source of current runs needed to establish a useful comparison, and record the comparison method.
- Assign each requirement to its single concrete lane while preserving the ownership and independent-defense rules above.
- Select cache keys, setup reuse, parallel job boundaries, artifact names/retention, and concurrency scopes based on measurements and workflow needs.
- Recheck exact action releases and runner compatibility immediately before changing workflow pins.
- Decide to retain the current topology when measured evidence does not justify a safer, faster alternative.

### Deferred Ideas (OUT OF SCOPE)

No additional ideas were raised. Live required-check or branch-protection changes remain in Phase 79, behind its explicit remote approval boundary.

### Reviewed Todos (not folded)

None — no matching pending todos were found for Phase 78.
<!-- DATA_7f3d91ac_END -->

Source: `.planning/phases/78-ci-efficiency-and-reliability/78-CONTEXT.md`, read in full this session. The block above is verbatim decision/discretion/deferred content; headings outside it are organizational.
</user_constraints>

## Summary

Preserve current required-check identities and the security/package matrix. Plan five outcomes: repair lifecycle baseline, establish criterion ownership and current cost, remove measured waste and hollow execution, standardize workflow controls and artifact safety, then regenerate reconciliation evidence and run clean-state validation. This follows the approved context; no public API, runtime security or remote settings change is needed. [VERIFIED: .planning/phases/78-ci-efficiency-and-reliability/78-CONTEXT.md:8-47]

Research reproduced **81 lifecycle tests, 4 failures in 27.3s**, and **8 security/package/Fleet contract tests, 0 failures in 0.06s**. Full actionlint reports two SC2016 findings; syntax-only validation succeeds. These are focused research observations, not clean-state completion evidence. [VERIFIED: local executions 2026-09-27; commands below]

The key dependency is pinned reconciliation. Its source inventory includes ".github/workflows/security-gates.yml", "mix.exs", "test/governance/milestone_scope_test.exs" and "test/support/adoption_evidence.ex". Editing these requires generated proof/report refresh and replay. Its replay itself runs focused checks, three evidence executions and security; measure that cost explicitly. [VERIFIED: test/support/phase_73_reconciliation.ex:60-101,203-240; inventory values quoted verbatim]

**Primary recommendation:** Keep independent security processes, standalone GATE-02, clean-room isolation and existing check names; optimize demonstrated duplication/setup through the existing evidence contracts.

## Architectural Responsibility Map

Recommended responsibility split:

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Criterion ownership | Test-only repository contracts | Workflow | Prove a blocking executable owner |
| Fresh-process suites | Mix/OS process | Runner | Prevent deduplication and selector bleed |
| Cache/concurrency/permissions/pins | Actions workflow | Contract tests | Controls belong at scheduling/credential boundary |
| Package provenance | Owned consumer harness | Docker/PostgreSQL | Run-owned artifact, home, dependency and build state |
| Browser journeys | Owned browser/container harness | Mandatory workflow | Deterministic application outcomes |
| External-provider health | Scheduled canary | Safe status producer | Cannot close deterministic merge acceptance |
| Failure evidence | Allowlisting producer | Upload step | Sanitize before export |
| Live required-check settings | Phase 79 | Read-only inventory | Outside Phase 78 mutation scope |

## Project Constraints (from AGENTS.md)

Mandatory directives: [VERIFIED: CLAUDE.md:13-87]

- Read active plan and current state before implementation; flag work outside plan scope.
- Give one researched recommendation and proceed; escalate actual public API, default-tightening, security-posture or SemVer-major changes. Milestone remote-mutation policy also applies.
- Preserve configured IdP certificate trust, single Saxy parse path, pre-parse DTD/entity/size guards, digest recomputation and real signature verification, audit co-commit, and production replay protection.
- Preserve crypto/XML/C14N/algorithm/audit/behaviour seams.
- Keep QA, warnings-as-errors tests, formatting and fresh-process security green. Never weaken adversarial crypto; security-relevant additions need adversarial CI evidence.
- Every new criterion requires deterministic mandatory-lane evidence. Host/browser/container/service state requires isolated automation; missing automation stays an open gap.
- Preserve archival planning evidence; do not introduce manual acceptance or UAT completion gates.
- Conventional commits with coauthor trailer; security fix bodies explain bypass context.
- Never hand-edit the generated changelog or manually publish Hex. Retirement operational guidance is not a Phase 78 task.
- Preserve unrelated user worktree state and the user-owned tool-version file. [VERIFIED: .planning/STATE.md, Baseline Findings]

**Approval classification:** Local lifecycle-test repairs and ordinary local alias/workflow configuration edits need no new security/remote approval. The code explicitly asserts 'changed_surface_classes("mix.exs", mix_before, alias_edit) == []' and 'changed_surface_classes("test/governance/milestone_scope_test.exs", "a", "b") == []'. The remote-path classifier matches only "scripts/setup_branch_protection.sh". Keep genuine runtime posture and remote operations out of scope. Avoid accidentally triggering prose classifiers by describing a local cache edit as a trust-policy change. [VERIFIED: test/governance/milestone_scope_test.exs:702-729,1590-1604,3947-4056]

<phase_requirements>
## Phase Requirements

Descriptions are verbatim, with inline code rendered as quoted text. [VERIFIED: .planning/REQUIREMENTS.md:53-56]

| ID | Description | Research support |
|---|---|---|
| PIPE-02 | Every mandatory acceptance criterion has one clearly named owning lane without hollow or silently skipped gates. | Canonical ownership extension, positive selectors/process receipts |
| PIPE-03 | CI uses safe parallelism and caching where measurements show value while preserving independent security defenses. | Multi-run method, exact cache dimensions, isolated consumer |
| PIPE-04 | Workflows use consistent naming, least-privilege permissions, non-colliding concurrency, and redaction-safe artifacts. | Current releases, event scopes, token exceptions, safe producers |
| PIPE-05 | 'mix qa', warnings-as-errors tests, formatting, 'mix ci.security', consumer contracts, demo tests, and required browser journeys remain green. | Lifecycle repair, proof regeneration, cold execution manifest |
</phase_requirements>

## Standard Stack

Reuse existing Elixir/Mix/ExUnit, Playwright, Docker, PostgreSQL and actionlint. No new application/test packages are recommended; no package installation legitimacy audit is needed for an unchanged dependency set. Action provenance must come from official release repositories and exact manifests.

Current workflow values are 'otp: [27, 28]', 'elixir: ["1.19.5"]', 'node-version: "22"', and 'image: postgres:16'. Preserve this supported matrix. [VERIFIED: .github/workflows/security-gates.yml:19,38-42,68-72]

### Official action snapshot

Checked live on 2026-09-27; publication dates were cross-checked through official release API responses. Each row is [CITED: linked official release].

| Action | Current release | Published UTC | Source |
|---|---|---|---|
| actions/checkout | v7.0.1 | 2026-07-20 | [Release](https://github.com/actions/checkout/releases/tag/v7.0.1) |
| actions/setup-node | v7.0.0 | 2026-07-14 | [Release](https://github.com/actions/setup-node/releases/tag/v7.0.0) |
| actions/cache | v6.1.0 | 2026-06-26 | [Release](https://github.com/actions/cache/releases/tag/v6.1.0) |
| actions/upload-artifact | v7.0.1 | 2026-04-10 | [Release](https://github.com/actions/upload-artifact/releases/tag/v7.0.1) |
| erlef/setup-beam | v1.24.1 | 2026-06-28 | [Release](https://github.com/erlef/setup-beam/releases/tag/v1.24.1) |

Recheck exact release/commit and runner compatibility immediately before implementation. Recommend full commit-SHA pins with release-version comments; do not put invented SHAs in plans. [CITED: https://docs.github.com/en/actions/reference/security/secure-use]

The exact-tag manifests for the four actions-owned releases declare 'node24'; this action runtime is separate from project Node 22. Checkout documentation requires runner 2.327.1 or later. [CITED: https://raw.githubusercontent.com/actions/checkout/v7.0.1/action.yml] [CITED: https://raw.githubusercontent.com/actions/setup-node/v7.0.0/action.yml] [CITED: https://raw.githubusercontent.com/actions/cache/v6.1.0/action.yml] [CITED: https://raw.githubusercontent.com/actions/upload-artifact/v7.0.1/action.yml] [CITED: https://github.com/actions/checkout]

## Architecture Patterns

### System architecture diagram

Recommended conceptual flow; this is not authorization to parallelize shared local state.

~~~mermaid
flowchart TD
  Event[PR or main push] --> Schedule[Workflow and event scoped scheduling]
  Schedule --> Setup[Toolchain and locked dependencies]
  Setup --> Root[Root QA and named owners]
  Setup --> Package[Fresh package consumer]
  Setup --> Browser[Owned browser journeys]
  Root --> Security[Independent security processes]
  Security --> Oracle[Standalone GATE-02]
  Root --> Evidence[Ownership and reconciliation]
  Package --> DB[Owned PostgreSQL]
  Browser --> Safe[Bounded safe status]
  Oracle --> Gate{All mandatory evidence passes?}
  Evidence --> Gate
  DB --> Gate
  Safe --> Gate
  Gate --> Pass[Acceptance or typed failure evidence]
  Timer[Schedule] --> Provider[External provider canary]
  Provider --> Canary[Separate safe status]
~~~

### Ownership: extend the existing model

The ledger states are '[:planned, :existing]' and evidence kinds are '[:package_contract, :application, :browser, :external_canary, :security_corpus]'. PIPE rows remain planned placeholders in "ci.quality". Closure excludes planned and external-canary rows. [VERIFIED: test/support/adoption_evidence.ex:14-16,224-266,331-350; values quoted verbatim]

Executable owner validation currently requires the exact "Evidence contract" step under "jobs.security", with a real selector and positive effective count. Merely changing a PIPE row to existing or adding an alias cannot establish closure. [VERIFIED: test/support/adoption_evidence.ex:490-508]

Recommendation: extend the existing ledger/contracts to map every mandatory criterion, including already-completed package/twin/journey requirements, to exactly one **primary lane**. Multiple selectors, persona rows and OTP variants may support that primary lane. Record repeated independent defenses separately; do not reject existing multi-persona evidence as duplicate ownership. Prove disabled, conditional, nonblocking, missing/zero-selected, duplicate-owner and deduplicated commands fail deterministically. Retain the fixed reconciliation step after evidence.

| Acceptance family | Recommended primary owner |
|---|---|
| Root format/compile/unit | Quality gate |
| Cryptographic/security invariants | Security lane; GATE-02 is independent defense |
| Package/profile boundary | Package consumer contracts in security matrix |
| LedgerLoop application journeys | Demo App CI |
| Admin browser journey | Admin UI browser smoke |
| FakeIdP/trace browser journeys | Demo browser workflow |
| Hermetic Fleet/owned Keycloak | Their deterministic workflows |
| Governance/criterion contracts | Evidence contract; reconciliation is independent replay |

These names refer to existing workflow steps/jobs. [VERIFIED: .github/workflows/security-gates.yml:62-120; .github/workflows/demo-app-ci.yml:62-63; .github/workflows/demo-app-e2e.yml:78-89; .github/workflows/fleet-proxy-e2e.yml:22-44; .github/workflows/keycloak-proxy-e2e.yml:16-38]

### Measure the current complete workload

QA invokes "test --warnings-as-errors"; fast invokes "test --warnings-as-errors --exclude integration". The test helper already declares 'ExUnit.start(exclude: [:pending, :integration, :external_idp])'. Their default selected work overlaps; measure coverage/results and duration before removing the duplicate workflow invocation. Preserve the developer alias unless separately justified. [VERIFIED: mix.exs:202-210; test/test_helper.exs:1]

Use at least three comparable current runs per configuration as the proposed method. Record revision, event, runner OS/architecture, resolved BEAM tuple, cache outcome, setup/step/job durations, conclusions and effective suite counts. Compare medians/ranges, cold versus warm, wall time versus summed runner cost. Failed/truncated runs cannot establish completed coverage. Historical 337s and fast 20–22s samples are explicitly not trends. [VERIFIED: .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md:29-40]

Plan in this order: lifecycle-green baseline → full job profiling including consumer and reconciliation → justified overlap removal → cache/parallelism experiment → cold/warm comparison. Retain topology when extra setup or proof maintenance outweighs savings. Do not pre-commit to a cache.

GitHub restore can use partial/default-branch matches; caches must not contain secrets. Require locked installation after every hit. Recommend compiled keys include OS, architecture, project, lock hash, resolved Elixir/OTP and environment; forbid fallback across toolchains. Consumer-owned paths remain cold. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]

### Hollow execution outside security

The docs alias includes two consecutive bare "test" commands; verification nests "ci.docs" and then another bare "test". Mix normally executes a task once per invocation. Add a deterministic invocation/positive-summary control and replace intended independent suites with fresh processes. [VERIFIED: mix.exs:222-231,278-280] [CITED: https://mix.hexdocs.pm/Mix.html#module-aliases]

Security's integrity inventory has 13 file/tag entries, with two corpus files sharing one process. Preserve the actual command boundaries, not a mistaken one-process-per-file rewrite. Every referencing security step must begin "cmd mix test". [VERIFIED: test/security/ci_gate_integrity_test.exs:32-45,116-135]

### Consumer isolation

The harness creates a unique root, creates all homes/dependency/build/database/output paths beneath it, launches commands with 'env -i', and verifies artifact/build provenance. The creation statement starts 'mkdir -p "$artifact_output" "$consumer_dir" "$mix_home" "$hex_home"' and continues with archives, deps, build, DB, output and home/XDG directories. [VERIFIED: scripts/check_clean_room_consumer.sh:101-144,156-175,230-257; creation lines 120-122]

The required commands, quoted verbatim, are:

~~~text
scripts/check_clean_room_consumer.sh --profile full
scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check
scripts/check_clean_room_consumer.sh --profile contracts
~~~

[VERIFIED: test/adoption/package_consumer_ci_contract_test.exs:7-10]

The contract pins one unconditional "Package consumer contracts" step in the existing matrix after setup/install. Keep that boundary unless an equivalent measured replacement is fully planned. CI cleanup deletes the owned root even after failure, so safe failure evidence needs an explicit external status receipt before cleanup; never upload the entire consumer output tree. [VERIFIED: test/adoption/package_consumer_ci_contract_test.exs:13-66; scripts/check_clean_room_consumer.sh:178-191]

### Workflow hygiene and artifacts

Preserve check identities "security (27, 1.19.5)", "security (28, 1.19.5)", "fleet-proxy-e2e"; their consumers are synchronized by a contract. Do not silently rename them while improving step names. [VERIFIED: test/release/fleet_proxy_ci_integrity_test.exs:4-15,51-65]

Use explicit contents-read permission for test workflows and narrow job-level exceptions for existing release/dispatch jobs. Use workflow/event/PR-qualified concurrency; cancel superseded PRs only. Non-PR run IDs can preserve every main run. A shared branch group with cancellation disabled can still replace pending work. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]

Artifact changes must cover producers and upload paths:

- Fleet enables 'trace: "on-first-retry"', uploads "playwright-report/fleet-proxy-*/**" and "test-results/**", and writes unfiltered Compose logs/network inspection. Replace broad exports with bounded allowlisted status, and disable/exclude raw browser diagnostics. The historical baseline's safety label is not sufficient evidence. [VERIFIED: playwright.fleet-proxy.config.mjs:13-22; .github/workflows/fleet-proxy-e2e.yml:46-55; scripts/test_fleet_proxy_e2e.sh:37-46]
- Sibling canary writes raw logs too; preserve canary separation while fixing its export boundary. [VERIFIED: scripts/test_rulestead_proxy_canary.sh:65-70; .github/workflows/fleet-proxy-e2e.yml:81-88]
- Reuse trace-visual fixed-schema success/failure fixtures. Its shell test literally requires "uses: actions/upload-artifact@v4", so update it together with pins. [VERIFIED: scripts/test_trace_visual_status_contract.sh:20-29,38-77]
- Add injected assertion/PEM/password/cookie/unexpected-attachment sentinels and prove none enter status bytes/upload allowlists. Bound file count/bytes/retention; unique artifact names must distinguish jobs/matrix/attempts.
- Cover early setup failure and cancellation. An "always()" upload cannot produce a missing receipt; current trace upload uses "if-no-files-found: error". [VERIFIED: .github/workflows/demo-app-e2e.yml:83-98]

Hidden-file filtering is not redaction; artifact names also need to respect immutable-upload behavior. [CITED: https://github.com/actions/upload-artifact]

### Lifecycle and pinned proof

Reproduced using explicit local ASDF versions:

~~~text
mix test test/governance/milestone_scope_test.exs --warnings-as-errors

unexpected actual governance lifecycle: {"78", "planning"}
assert checked_in.current_phase in ["73", "74", "75", "76", "77"]
assert checked_in_identity.current_phase in ["73", "74", "75", "76", "77"]
assert identity.current_phase in ["74", "75", "76", "77"]
Finished in 27.3 seconds (27.3s async, 0.00s sync)
81 tests, 4 failures
~~~

[VERIFIED: local execution 2026-09-27; test/governance/milestone_scope_test.exs:47-107,224,316,830-835; .planning/STATE.md:5-8 contains "current_phase: 78" and "status: planning"]

Add explicit Phase 78 planning/execution/verification lifecycle fixtures and malformed/duplicate/skipped-phase controls. Prefer deriving membership from parsed milestone ownership rather than another unchecked upper bound.

After final governed edits, use existing 'capture!/2' and 'proof_block/1'. Capture executes 21 focused commands, three evidence runs and security, checks equal evidence vectors and atomically writes proof; replay checks source hashes/result vectors. Refresh generated proof and append-only report blocks together, without hand-editing hashes or replacing history with fixture reports. [VERIFIED: test/support/phase_73_reconciliation.ex:19-40,91-135,152-176,203-240,397-398]

Plan order: lifecycle source changes → source commit → mandatory intermediate generated capture/report refresh/replay → comparable measured baseline → later governed edits → final capture/report refresh/replay → full cold producer → dedicated receipt validator. Report stale proof honestly between governed changes; no measurement sample or completion check can claim a stale proof is passing.

## Don't Hand-Roll

| Problem | Reuse | Avoid |
|---|---|---|
| Criterion ownership | Existing ledger/semantic owner resolver | Parallel prose-only inventory |
| Workflow verification | Existing YAML contract plus actionlint | Comment/grep tokens as execution proof |
| Process independence | Existing security meta-gate | Bare repeated Mix test tasks |
| Consumer state | Existing owned harness | Shared checkout/home/build reuse |
| Failure evidence | Fixed-schema status producers | Blacklist sanitization of arbitrary logs |
| Proof freshness | Existing capture/replay | Transcribed hashes/success counts |

These are recommendations based on the inspected seams above.

## Runtime State Inventory

This is a workflow/alias refactor; no product/data rename is proposed.

| Category | Evidence / action |
|---|---|
| Stored data | Owned consumer DB state and Actions caches/artifacts exist; no application migration. Use versioned cache namespaces rather than relying on live cache deletion |
| Live service config | Historical required-check drift remains Phase 79-owned; preserve local check identities |
| OS-registered state | Inspected changes introduce no registration mutation; no whole-host absence claim |
| Secrets/env vars | Preserve existing release/canary names and scoped access; never capture values |
| Build artifacts | Root build/cache state differs from consumer-owned roots; use an owned cold checkout/container |

[VERIFIED: scripts/check_clean_room_consumer.sh:101-144,178-191,376-405; .github/workflows/release-please.yml:110-132; .github/workflows/real-idp-canary.yml:17-30; .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md:37-47]. Live cache inventories and OS registrations were not queried; these are scoped observations.

## Common Pitfalls

- Counting named steps rather than positive executed suites.
- Removing intentional repeated security proof along with accidental QA/fast repetition.
- Measuring only the historical pre-consumer/pre-reconciliation workload.
- Calling local workflow/test changes remote or security posture mutations.
- Treating a cache hit or reused consumer root as clean-state proof.
- Updating action pins without literal version contract tests.
- Uploading raw logs/traces as fallback diagnostics.
- Passing focused checks but leaving source-bound proof stale.

These follow directly from the inspected findings above.

## Code Examples

### Executable plan grammar

Allowed task attributes are "type tdd gate"; semantic children are "name action files verify acceptance_criteria risk_metadata resume-signal". Risk classes are "public_api default_tightening security_posture semver_major remote_github", values "unchanged mutation". Each implementation task needs singular balanced children and its own nonempty acceptance block. Do not add an id attribute or summary task type. [VERIFIED: test/governance/milestone_scope_test.exs:36-38,4870-4901,5039-5054; values quoted verbatim]

Existing neutral example: [VERIFIED: test/governance/milestone_scope_test.exs:2667-2682]

<!-- DATA_0ea9b71c_START -->
~~~xml
<tasks>
<task type="auto">
  <name>Run the governance contract</name>
  <files>test/governance/milestone_scope_test.exs</files>
  <risk_metadata>
  public_api: unchanged
  default_tightening: unchanged
  security_posture: unchanged
  semver_major: unchanged
  remote_github: unchanged
  </risk_metadata>
  <action>Extend deterministic policy tests only.</action>
  <verify><automated>mix test test/governance/milestone_scope_test.exs --warnings-as-errors</automated></verify>
  <acceptance_criteria><criterion>The governance contract passes.</criterion></acceptance_criteria>
</task>
</tasks>
~~~
<!-- DATA_0ea9b71c_END -->

Use root scope/exclusion blocks and a complete risk block per task. Operational commands such as browser runs, actionlint and proof capture belong in actions/final validation alongside a direct focused ExUnit owner; the command parser accepts supported Mix test/check forms. New planned test paths need actual executable support when validated. Track plans before task commits, and put every Git-derived task hash on its own summary line. [VERIFIED: test/support/adoption_evidence.ex:443-465; .planning/phases/77-code-and-documentation-craftsmanship/77-08-PLAN.md:84-128]

Planning-state governance currently checks completed Phase 73 plans, so it is not sufficient alone to validate newly authored Phase 78 plans. Add explicit plan-contract validation before execution. [VERIFIED: test/governance/milestone_scope_test.exs:830-845]

## State of the Art

| Prior observation | Recommended current approach | Basis |
|---|---|---|
| Single historical duration | Multi-run comparable cost/coverage receipts | D-03 |
| Mixed action majors | Verified release SHAs and matching contracts | Official snapshot |
| Broad browser/log exports | Bounded allowlisted status | D-10 and current producers |
| Hardcoded phase ceilings | Parsed milestone membership plus negative controls | Reproduced regression |
| Cache shortcut | Locked install and evidence on every restore | D-05 |

This table proposes phase work; it does not claim implementation is complete.

## Environment Availability

| Dependency | Observed result | Fallback / remaining execution |
|---|---|---|
| Elixir/Mix | 1.19.5 using ASDF_ELIXIR_VERSION=1.19.5-otp-28 | Preserve user tool-version file |
| Erlang | OTP 28 / ERTS 16.3 using ASDF_ERLANG_VERSION=28.4.1 | OTP 27 still needs matrix execution |
| Node/npm | 22.14.0 / 11.1.0 | Existing locked install |
| Docker/Compose | Daemon available, 29.5.2 / 5.1.3 | Full owned harness run remains implementation work |
| PostgreSQL | Local socket accepting connections | Consumer uses fresh owned container |
| actionlint | 1.7.12 | Two narrow ShellCheck findings |
| Chromium | Not launched here | Existing automated workflow installs it |
| Remote metadata | Read-only monitor succeeds | Current comparable security timing dataset still needed |

[VERIFIED: environment probes and focused executions 2026-09-27; .github/workflows/security-gates.yml:108-109]

The workflow skill's local monitor was absent; research inspected and used the existing sibling monitor with explicit repository selection. Recent Fleet/Keycloak scheduled runs were green on September 25–27, including 36300806701 and 36301647052. That is canary status, not current security workload cost. Do not make implementation depend on another repository; use an owned read-only measurement collector. [VERIFIED: ci_monitor runs --repo szTheory/relyra --branch main, 2026-09-27]

No observed dependency blocks planning. Full package/browser/cold matrix execution remains unproven and must be automated during implementation.

## Validation Architecture

### Existing framework and measured baseline

ExUnit is already available through Mix 1.19.5; default exclusions are "[:pending, :integration, :external_idp]". [VERIFIED: test/test_helper.exs:1; local Mix version probe]

Fast focused command:

~~~sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/security/ci_gate_integrity_test.exs test/adoption/package_consumer_ci_contract_test.exs test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors
~~~

Result: 8 tests, 0 failures, 0.06s ExUnit time. Lifecycle focused command above produced four failures. [VERIFIED: local executions 2026-09-27]

Normal 'actionlint .github/workflows/*.yml' reports SC2016 at demo-app-e2e.yml:104 and real-idp-canary.yml:66 because summary printf strings contain literal backticks. 'actionlint -shellcheck="" .github/workflows/*.yml' passes syntax. Fix/suppress only the intentional literal case with evidence; do not establish disabled ShellCheck as the final lint standard. [VERIFIED: actionlint 1.7.12 execution 2026-09-27]

### Requirements → deterministic tests

| Requirement | Existing owner to extend | Automated focused command |
|---|---|---|
| PIPE-02 | Evidence contract + security integrity; negative duplicate/disabled/zero/hollow fixtures | mix test test/adoption/evidence_contract_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors |
| PIPE-03 | Consumer CI contract + bounded measurement/cache/alias fixtures | mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors |
| PIPE-04 | Fleet/external-canary/status contracts; permission/concurrency/artifact sentinels | mix test test/release/fleet_proxy_ci_integrity_test.exs test/adoption/external_canary_contract_test.exs --warnings-as-errors |
| PIPE-05 | Lifecycle, mandatory owner completeness and source-bound proof replay | mix test test/governance/milestone_scope_test.exs --warnings-as-errors |

Add focused selectors for new controls so individual checks stay bounded. Full evidence/reconciliation execution intentionally exceeds a short task loop; record actual timing separately.

### Clean-state completion manifest

Run each command independently in an owned fresh checkout/environment with locked dependencies and no restored compiled state for cold proof:

~~~text
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix qa
mix ci.security
mix ci.evidence
mix ci.phase73.reconciliation
mix ci.verify
mix ci.integration
scripts/check_clean_room_consumer.sh --profile full
scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check
scripts/check_clean_room_consumer.sh --profile contracts
mix ci.demo_app
mix cmd --cd demo/ledger_loop mix test --warnings-as-errors
npm ci
npm run admin-ui:smoke
npm run demo:fake-idp
npm run demo:trace-visual
npm run demo:fleet-proxy
npm run demo:keycloak-proxy
bash scripts/test_trace_visual_status_contract.sh
actionlint .github/workflows/*.yml
~~~

These are proposed execution checks assembled from existing aliases/workflows/scripts, not a claim they were all run during research. [VERIFIED: mix.exs:202-305; .github/workflows/security-gates.yml:62-120; .github/workflows/demo-app-e2e.yml:69-89; .github/workflows/fleet-proxy-e2e.yml:37-44; .github/workflows/keycloak-proxy-e2e.yml:31-38; test/support/adoption_evidence.ex:451-452]

Provision database/assets through existing harness prerequisites. LedgerLoop alias currently ends in "cmd --cd demo/ledger_loop mix test", without warnings-as-errors; include the explicit nested check above or deliberately strengthen its CI invocation. This is local test configuration. [VERIFIED: mix.exs:288-292]

Do not concurrently run Fleet/Keycloak against the same Compose state or a developer stack. Fleet cleanup operates on its named Compose stacks/network and refuses an active demo project; use a disposable owned runner or distinct owned resources. [VERIFIED: scripts/test_fleet_proxy_e2e.sh:7-15,49-80]

### Wave 0 gaps / sampling

- Repair lifecycle with Phase 78 state and malformed-transition fixtures.
- Extend canonical primary-owner mapping, effective process/selector checks and measurement fixture/schema.
- Add non-security hollow-task, cache key/restore, evaluated concurrency and artifact sentinel controls.
- Update literal action pin assertions.
- Schedule generated reconciliation proof/report refresh after final governed edits.
- Focused owner per task commit; relevant named lanes per wave; full cold manifest and supported matrix at phase completion.
- Track plans before task commits; verify exact summary provenance.

No new framework install and no manual completion gate are proposed.

## Security Domain

Security enforcement is not explicitly disabled in the inspected config; include security validation. Use ASVS 5.0 category names, rather than older template numbering. [VERIFIED: .planning/config.json, inspected this session] [CITED: https://owasp.org/projects/asvs] [CITED: https://github.com/OWASP/ASVS/tree/v5.0.0/5.0/en]

| ASVS 5.0 category | Applicability / recommended control |
|---|---|
| V2 Validation and Business Logic | Closed evidence schemas, positive counts, malformed fixtures |
| V6 Authentication / V7 Session Management | Preserve existing SAML/session/browser evidence; no new auth code |
| V8 Authorization | Least-privilege CI tokens; bounded release exceptions |
| V11 Cryptography | Preserve independent security suites and golden oracle |
| V13 Configuration | Pins, toolchain isolation, safe concurrency |
| V14 Data Protection | Exclude assertion/cert/credential/cookie/raw browser exports |
| V16 Security Logging and Error Handling | Bounded status, original failure propagation |

Category names are cited from the official versioned directory above; applicability is this research's recommendation.

| Threat | STRIDE | Automated mitigation evidence |
|---|---|---|
| Hollow gate green | Tampering | Negative aliases/selectors/workflows and positive process receipts |
| Stale/cache state becomes proof | Tampering | Locked install, toolchain keys, cold run, consumer provenance |
| PR cancels unrelated/main work | Denial of service | Cross-event/workflow concurrency fixtures |
| Raw diagnostics leak payloads | Information disclosure | Sentinels plus exact upload allowlists |
| Untrusted code gains release privilege | Elevation of privilege | Read-only test workflows, no privileged fork checkout |
| Stale proof described as current | Repudiation | Generated source-bound proof and replay |

## Assumptions Log

No training-only factual claim is used to lock a decision. Sample size, exact primary-owner grouping and status schema are recommendations within approved discretion. Performance improvement, future action SHAs and full cold-run success remain unproven until implementation generates automated evidence.

## Open Questions — Planning Dispositions

1. **RESOLVED for planning (D-03):** Plan 78-02 measures at least three complete comparable current runs per baseline/candidate and accepts a topology change only when its measured wall time and runner cost justify it. The winning choice and runtime result remain conditional execution findings, not known research results. A canonical intermediate Phase 73 capture makes the baseline pass before measurement.
2. **RESOLVED for planning (D-05):** Plan 78-02 compares cold and warm compiled-cache cost outside isolated consumer roots. Enable a cache only on measured net benefit, with OS/architecture/lock/Elixir/OTP identity and locked installation after restoration. No performance benefit is asserted in advance.
3. **RESOLVED for planning (D-10):** Plan 78-06 assigns bounded safe status to each early-failure producer and tests original failing conclusions plus sensitive sentinels before artifact upload. Actual producer results remain execution evidence.
4. **RESOLVED for planning (D-12):** Plan 78-02 captures the post-lifecycle intermediate proof before cost samples; Plan 78-07 captures again after all final governed-source edits and before its full cold producer. A separate mandatory owner validates the resulting real receipt after production, without a receipt-input cycle. Neither proof nor cold success is claimed by planning.
5. **RESOLVED for planning (D-11):** Phase 78 changes only tracked local workflow controls. Current live branch-protection/required-check read-back and any approved remote update are Phase 79 work; no remote mutation or assumed current setting is needed to execute Phase 78.

These are execution investigations with explicit owners and fail-closed criteria, not a request to reopen approved discussion.

## Sources and Metadata

All Phase 78 canonical references were opened; relevant portions of long governance/evidence modules were read with line numbers. Additional sources include reconciliation helper, trace-status contract, Fleet browser config and diagnostic producers.

Official references: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency), [cache reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [secure use](https://docs.github.com/en/actions/reference/security/secure-use), release pages/exact manifests above, [Mix aliases](https://mix.hexdocs.pm/Mix.html#module-aliases), and [ASVS 5.0](https://github.com/OWASP/ASVS/tree/v5.0.0/5.0/en).

Research-plan selected websearch and unavailable Jina; built-in browsing fetched official sources. 'query classify-confidence --provider websearch --verified' returned "MEDIUM". Digests were stored through research-store in a temporary research root. The unavailable versioned Mix documentation lookup is not used as evidence; current official task-once semantics are corroborated by the local integrity contract.

**Confidence:** MEDIUM overall; official action releases were checked live, repository seams inspected, and focused lifecycle/integrity/lint behavior reproduced. Remaining uncertainty is measured optimization benefit and full cold execution, not the approved phase scope.

**Research date:** 2026-09-27. Recheck actions immediately before pin changes and cost during execution. Only this research artifact is authored by the researcher; orchestrator owns the commit.
