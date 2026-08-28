---
status: resolved
trigger: "Diagnose UAT gap G-70-1: npm run demo:keycloak-proxy completes the real Keycloak journey but exits 1 because root_security reports vulnerable mint 1.8.0 and req 0.5.18."
created: 2026-08-26T00:00:00-04:00
updated: 2026-08-26T22:42:11Z
goal: find_root_cause_only
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

bug_class: bohrbug
known_pattern_candidate: none (no knowledge base exists)
hypothesis: CONFIRMED — two conditions jointly produce the UAT failure: the Keycloak harness executes its repository-wide `root_security` gate after the genuine E2E proof, and `mix ci.security`'s dependency audit rejects the lockfile's vulnerable `req 0.5.18` and transitive `mint 1.8.0`.
test: Completed: direct `mix deps.audit` against the unchanged lockfile, plus static order/alias/dependency-tree inspection.
expecting: Confirmed: the audit reports the same versions and exits nonzero; `root_security` follows browser/ACS/receipt assertions in the harness.
next_action: Return diagnosis only; do not modify implementation, UAT, or CI.

candidate_causes:
  - code: "The scenario-specific E2E harness unconditionally invokes repository-wide `mix ci.security` after it has established all Keycloak behavior."
  - environment: "The current Hex advisory database marks locked `req 0.5.18` and its `req -> finch -> mint 1.8.0` transport dependency vulnerable."
  - config: "`ci.security` intentionally has no ignore for these advisories (only decimal is narrowly ignored), so `deps.audit` propagates a nonzero status."
and_gate: "yes — the command fails only while both the unrelated audit is coupled into the harness and the lockfile remains advisory-vulnerable."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "Public proxy hosts, descriptor trust, browser ACS journey, one receipt, and exactly Validate response, Verify signature, and Replay check all pass."
actual: "Automated run passed the real Keycloak Chromium journey, scoped ACS 302, one durable receipt, and exact canonical trace steps, but the command exited 1 in root_security because mint 1.8.0 and req 0.5.18 are vulnerable."
errors: "root_security dependency audit reports vulnerabilities in mint 1.8.0 and req 0.5.18."
reproduction: "Test 1 in .planning/phases/70-keycloak-behind-the-proxy/70-UAT.md; npm run demo:keycloak-proxy."
started: "Discovered during UAT on 2026-08-26."

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-26T00:00:00-04:00
  checked: UAT reporter symptom statement
  found: "The Chromium/ACS/receipt/canonical-trace assertions passed; only the root_security audit stage exited nonzero."
  implication: "The observed failure is a deterministic repository dependency-security gate failure, not evidence that the Keycloak E2E behavior failed."
- timestamp: 2026-08-26T00:00:00-04:00
  checked: "scripts/test_keycloak_proxy_e2e.sh, package.json, mix.exs, mix.lock, and CI workflows"
  found: "The npm command invokes the harness; the harness verifies proxy, Keycloak readiness, descriptor trust, browser authentication, ACS trace, mapping, and receipt before `root_security mix ci.security`. `ci.security` runs `deps.audit`, and the lockfile pins mint 1.8.0 and req 0.5.18. CI separately runs `mix ci.security` in security-gates, while the only recurring proxy workflow runs fleet-proxy, not Keycloak."
  implication: "The command combines two independent gates: an E2E proof and a repository-wide dependency audit; the audit is already covered by required security CI, while no current workflow supplies the distinct Keycloak-proxy proof."
- timestamp: 2026-08-26T00:00:00-04:00
  checked: "mix deps.audit"
  found: "The unchanged lockfile audit exited 1 and reported four mint advisories (< 1.9.0) for mint 1.8.0 and two Req advisories (< 0.6.0/< 0.6.1) for req 0.5.18. It also reported the already-documented decimal advisory; `ci.security` narrowly ignores only that decimal advisory."
  implication: "The reported root_security failure is independently reproducible without Docker, Playwright, Keycloak, or browser state."
- timestamp: 2026-08-26T00:00:00-04:00
  checked: "mix deps.tree and Phase 70 harness/CI history"
  found: "req is a direct optional dependency declared as `~> 0.5`; its resolved graph is `req -> finch -> mint`. Phase 70-05 deliberately added root QA/security/format commands to the Keycloak harness. `security-gates.yml` already executes `mix ci.security` as a repository gate; `fleet-proxy-e2e.yml` is the recurring proxy workflow and executes only the fleet harness; no workflow executes the Keycloak proxy harness."
  implication: "Dependency remediation and Keycloak integration proof should be independently owned: the former by security CI plus a dedicated dependency update, the latter by a focused recurring Keycloak-proxy CI job if the project wants zero manual UAT."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "The E2E behavior is green, but `npm run demo:keycloak-proxy` is not a pure Keycloak acceptance command: after all Keycloak checks pass it invokes `root_security`, whose `mix ci.security -> deps.audit` rejects locked req 0.5.18 and its transitive mint 1.8.0. The failure therefore requires both the unrelated audit coupling and the vulnerable lockfile."
fix: "Do not suppress the advisories. In a dedicated security dependency change, update Req and its resolved Finch/Mint graph to patched versions and run the repository gates. Separately remove repository-wide QA/security/format invocations from the scenario harness, retaining Keycloak-specific static, browser, receipt, and trace assertions. Keep `mix ci.security` in security-gates. To eliminate manual UAT with recurring value, add one focused Keycloak-proxy CI job/workflow that runs only `npm run demo:keycloak-proxy` (with Docker and Chromium); retain it because it is the only automated proof of the public Keycloak/Traefik/ACS integration."
verification: "Direct audit reproduction: `mix deps.audit` exited 1 for mint 1.8.0 and req 0.5.18. Static control-flow inspection: root_security is invoked only after proxy/readiness/descriptor/browser/ACS/mapping/receipt checks. UAT run evidence reports those Keycloak assertions passed."
files_changed:
  - ".planning/debug/phase-70-keycloak-gate-not-green.md"
