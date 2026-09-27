# Phase 78: CI Efficiency and Reliability - Context

**Gathered:** 2026-09-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Give every mandatory evidence requirement a clear, reliable owner and improve or
justify CI cost using measured evidence. Preserve independent security defenses,
clean-room consumer isolation, deterministic merge gates, and redaction-safe
failure evidence. This phase does not change live GitHub required-check settings;
that exact shared-state work remains in Phase 79.
</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 78 boundary, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — PIPE-02 through PIPE-05 and their traceability.
- `.planning/PROJECT.md` — v1.11 scope, CI/security guardrails, and remote-mutation boundary.
- `.planning/STATE.md` — current phase position, milestone decisions, and the post-transition governance regression.
- `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md` — baseline decisions, including multi-run measurement and preserving independent security checks.
- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — dated topology, duration, duplication, cache, ownership, and failure-evidence inventory.
- `.planning/phases/76-lifecycle-and-recovery-journeys/76-CONTEXT.md` — deterministic gate versus external canary boundary.
- `.planning/phases/77-code-and-documentation-craftsmanship/77-CONTEXT.md` — current named-lane and deterministic acceptance patterns.
- `mix.exs` — Mix CI aliases and process boundaries.
- `.github/workflows/security-gates.yml`, `.github/workflows/demo-app-ci.yml`, `.github/workflows/demo-app-e2e.yml`, `.github/workflows/fleet-proxy-e2e.yml`, `.github/workflows/keycloak-proxy-e2e.yml`, `.github/workflows/planning-pr-checks.yml`, `.github/workflows/release-please-pr-checks.yml`, and `.github/workflows/release-please.yml` — required and supporting workflow topology.
- `scripts/check_clean_room_consumer.sh` — isolated consumer execution and state ownership.
- `test/security/ci_gate_integrity_test.exs` — security lane process-integrity contract.
- `test/adoption/evidence_contract_test.exs`, `test/adoption/package_consumer_ci_contract_test.exs`, and `test/support/adoption_evidence.ex` — criterion and workflow ownership evidence.
- `test/release/fleet_proxy_ci_integrity_test.exs` — browser/fleet workflow ownership contract.
- `test/governance/milestone_scope_test.exs` — lifecycle regression owner identified in current STATE.
- [GitHub Actions dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) — cache scope, restore behavior, and low-trust guidance.
- [GitHub Actions concurrency](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency) — group sharing, pending-run replacement, and cancellation semantics.
- Official action release sources: [checkout](https://github.com/actions/checkout/releases/latest), [setup-node](https://github.com/actions/setup-node/releases/latest), [cache](https://github.com/actions/cache/releases/latest), [upload-artifact](https://github.com/actions/upload-artifact/releases/latest), and [setup-beam](https://github.com/erlef/setup-beam/releases/latest).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` already defines named lanes for QA, fast tests, docs, conformance, evidence, security, integration, demo app, external IdP, admin UI, and release checks.
- `test/security/ci_gate_integrity_test.exs` protects the fresh-process security-suite pattern that prevents Mix task deduplication from hollowing the gate.
- `test/adoption/evidence_contract_test.exs` and `test/support/adoption_evidence.ex` provide an existing acceptance-to-evidence ownership model.
- `scripts/check_clean_room_consumer.sh` owns isolated package-consumer profiles; `test/adoption/package_consumer_ci_contract_test.exs` verifies workflow ownership.
- Existing browser and fleet workflow contracts can be extended rather than adding an unrelated ownership checker.

### Established Patterns
- Security proof uses distinct `cmd mix test` processes where Mix task deduplication could otherwise skip suites; standalone GATE-02 is deliberate defense in depth.
- Acceptance closure is deterministic and tied to executable evidence in a mandatory lane. External IdP/provider checks are scheduled canaries.
- Cache restoration can include partial and default-branch matches; repository evidence must not treat cached state as proof or trust.
- Remote branch-protection state is handled separately from local workflow edits and belongs to Phase 79.

### Integration Points
- Workflow ownership and gate structure connect `.github/workflows/security-gates.yml` to the CI aliases in `mix.exs` and their contract tests under `test/`.
- Package proof flows through `scripts/check_clean_room_consumer.sh` and the consumer fixture; any CI reuse must preserve its isolated roots.
- Browser evidence connects the main security workflow, demo browser workflow, fleet proxy workflow, and their workflow-integrity tests.
- The known lifecycle failure is exercised by `test/governance/milestone_scope_test.exs` and is recorded in `.planning/STATE.md` for Phase 78 planning evidence.

</code_context>

<specifics>
## Specific Ideas

Keep the independent fresh-process `mix ci.security` suites and standalone GATE-02 check visible in the requirement-to-lane inventory. Compare multiple current runs before changing the overlapping `mix qa` / `ci.fast` work or introducing Mix build caches. Preserve clean-room consumer paths and restrict uploaded evidence to bounded, redaction-safe outputs.
</specifics>

<deferred>
## Deferred Ideas

No additional ideas were raised. Live required-check or branch-protection changes remain in Phase 79, behind its explicit remote approval boundary.

### Reviewed Todos (not folded)

None — no matching pending todos were found for Phase 78.
</deferred>
