# Phase 79: Adopter-Ready Closeout - Context

**Gathered:** 2026-09-29 (research-augmented assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.11 with an intentional repository and worktree state, a current and reviewable GitHub collaboration inventory, exact-source evidence that the mandatory CI surface on `main` is green, and a residual-risk account below the milestone's diminishing-returns line. Keep the work feature-neutral. Any new remote GitHub mutation remains behind an exact, explicitly approved batch.

</domain>

<decisions>
## Implementation Decisions

### GitHub Inventory and Mutation Boundary
- **D-01:** Build a fresh, timestamped, read-only inventory of pull requests, issues, local and remote branches, workflow health, required checks, and branch-protection state before proposing remote changes. Record repository/ref and commit SHA, evidence source, pagination/completeness, and access failures so partial results cannot look complete. Treat Phase 73's dated snapshot as a lead to revalidate, not current state or authorization. Any proposed Phase 79 remote close, label, comment, merge, deletion, or protection mutation is a separate exact batch bound to its target, current/desired state, affected items/checks, reason, least-privilege operation, preflight, rollback, read-back, and resume signal. Refresh immediately before applying; if state changed, stop and obtain renewed approval. Inventory `.github/workflows/branch-protection-drift.yml` as inherited policy, not approval for a new Phase 79 mutation; do not invoke, modify, or disable it without its own exact approval.

### Repository and Worktree Cleanliness
- **D-02:** Classify tracked changes, relevant untracked and ignored generated/scratch artifacts, and every registered worktree by owner and disposition before declaring the repository clean. Preserve known maintainer-owned `.tool-versions`; neither blanket deletion/`git clean -x` nor the Phase 78 receipt alone proves cleanliness. Remove only items confirmed obsolete and within approved local scope; leave unknown ownership intact and disclose it. Bound ignored/cache checks to project-relevant outputs rather than enumerating every ignored cache file.

### Main CI and External Canaries
- **D-03:** Bind readiness to the current protected `main` SHA and the exact source each evidence item proves. Check both the complete mandatory-lane ownership inventory and current results for that SHA; report branch-protection required contexts separately because they may not cover every mandatory lane. Reuse the Phase 78 receipt only if its source commit/digest and proof scope match. Re-run expensive evidence when relevant source, workflow, dependency, or toolchain inputs changed, proof is missing/failed/stale, or release-tag proof requires it; do not repeat a green matrix only to refresh an unchanged result. Report scheduled/external-provider canaries separately; if one has an incident, give its run/ref/time, safe evidence, diagnosis, owner/next action, and why it does or does not affect deterministic readiness. External availability must not become a manual-only merge gate.

### Residual-Risk Inventory
- **D-04:** Revalidate every retained Phase 73 finding against current evidence and include project-deferred items plus open cross-phase windows, including the two Phase 76 concurrency automation gaps. Give every remaining idea one evidence-backed disposition from Phase 79's categories: low-value, demand-gated, approval-blocked, or more costly to maintain than the risk it retires. Record impact/severity, adopter demand or trigger, maintenance burden, owner, approval boundary, and revisit condition/date. Carry forward Phase 73's severity policy: High/Critical items block until resolved; Medium requires an explicit disposition; Low/Informational items remain visible with an owner and revisit point.

### the Agent's Discretion
- Present a concise, redaction-safe closeout dossier for the maintainer/release owner: answer readiness first, then link exact evidence, show any approval-bound batch, separate canary status, and summarize residual-risk dispositions. Use plain Markdown headings/tables and user-facing labels; do not build a dashboard or expose implementation details that do not help the maintainer decide.
- Use the current brandbook's calm, exact, transparent, operator-friendly, open-source-serious voice. Visual UI design is not applicable to this repository/CI phase; retain accessibility, clarity, and scannability in the report without adding visual UI work.
- Choose the smallest complete read-only query set and bounded evidence schema. Add deterministic contract coverage only where implementation creates a new recurring behavior; do not duplicate Phase 78 gates or add human-only completion evidence.
- Generic prompt recommendations remain subordinate to current `AGENTS.md`, roadmap, and locked project decisions; manual `mix hex.publish` remains prohibited.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Guardrails
- `.planning/ROADMAP.md` §Phase 79 — closeout goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` §Repository and GitHub Hygiene, §Governance and Exit — REPO-01..03 and EXIT-01.
- `.planning/PROJECT.md` — v1.11 scope, security invariants, demand-gated items, and shared GitHub approval boundary.
- `.planning/STATE.md` — current position, maintainer-owned `.tool-versions`, milestone decisions, and existing state; read current content because workspace state may change.
- `.planning/WINDOWS.md` — open cross-phase automation gaps, including Phase 76 concurrency gaps to revalidate for closeout.
- `AGENTS.md` — project-specific permissions, automation requirements, and prohibition on manual Hex publishing.

### Existing Closeout, CI, and Governance Evidence
- `.planning/phases/78-ci-efficiency-and-reliability/78-CONTEXT.md` — locked CI ownership, exact security processes, canary separation, and deferred remote settings.
- `.planning/phases/78-ci-efficiency-and-reliability/78-VALIDATION.md` — Phase 78's validation and evidence boundary.
- `.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json` — source-bound evidence, not proof of current `main` state.
- `.planning/phases/78-ci-efficiency-and-reliability/78-VERIFICATION.md` — completed Phase 78 verification.
- `.planning/phases/77-code-and-documentation-craftsmanship/77-CONTEXT.md` — artifact ownership and finding-disposition patterns.
- `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md` — source-bound baseline, severity/disposition, ownership, and exact remote approval contract.
- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — dated inventory shape and severity/blocker vocabulary; historical live values are not current.
- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` — threshold-aware risk register and disposition history.
- `.planning/phases/79-adopter-ready-closeout/79-RESEARCH.md` — implementation research; refresh all live state during execution.
- `.planning/phases/79-adopter-ready-closeout/79-VALIDATION.md` — mandatory deterministic evidence strategy and open coverage questions.
- `.planning/phases/79-adopter-ready-closeout/79-PATTERNS.md` — candidate deliverable analogs; filenames remain plan-selected.
- `docs/relyra-milestone-roadmap-guide.txt` — durable milestone closeout guidance.
- `test/governance/phase_73_reconciliation_test.exs` and `test/governance/milestone_scope_test.exs` — executable governance, evidence ownership, and remote-batch contracts.
- `scripts/check_phase78_clean_state.sh` — source-bound receipt and isolated clean-state evidence pattern.
- `scripts/setup_branch_protection.sh` and `.github/workflows/branch-protection-drift.yml` — desired protection state and existing scheduled owner-controlled write path.
- `.github/workflows/security-gates.yml` — required deterministic security lanes.
- `mix.exs` and the Phase 78 required workflow files — named CI lane definitions and current workflow ownership; recheck live status for the current `main` SHA.

### Project Research and Maintainer Experience
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir OSS CI/release practices; apply selectively and validate against current Relyra decisions.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Hex/library DX and maintenance principles relevant to a release/maintainer workflow.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — lessons from Sigra, Kiln, Lockspire, and other sibling libraries, including CI-as-spec, named lanes, and release evidence.
- `brandbook/README.md` and `brandbook/notes/decision-log.md` — current voice and canonical design decisions. The old `prompts/relyra-brand-book.md` is not the design source of truth.

### Authoritative External References
- [Git status](https://git-scm.com/docs/git-status), [Git clean](https://git-scm.com/docs/git-clean), [Git worktree](https://git-scm.com/docs/git-worktree), and [Git ignore](https://git-scm.com/docs/gitignore) — inventory and cleanup semantics.
- [GitHub protected branches REST API](https://docs.github.com/en/rest/branches/branch-protection), [fine-grained token permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens), and [Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use) — read/write permissions and least privilege.
- [GitHub REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api), [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), and [merge queues](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue?apiVersion=2022-11-28) — inventory completeness and SHA/event freshness.
- [Hex publishing guide](https://hex.pm/docs/publish) — consumer-package proof and release artifact expectations; does not supersede Relyra's no-manual-publish rule.
- [Phoenix `.gitignore`](https://github.com/phoenixframework/phoenix/blob/main/.gitignore) — a mature Elixir project's targeted generated-artifact exclusions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check_phase78_clean_state.sh` — source commit/digest binding, isolated temporary checkout, bounded receipt schema, and owned cleanup; reuse its evidence discipline where current Phase 79 source matches.
- `test/governance/phase_73_reconciliation_test.exs` — exact-scope provenance and deterministic remote-batch validation patterns.
- `test/governance/milestone_scope_test.exs` — source-bound lifecycle, worktree/artifact ownership, and mutation approval contracts.
- `scripts/setup_branch_protection.sh` — declared required checks and protection payload for comparison with live read-only state.
- `.github/workflows/branch-protection-drift.yml` — existing scheduled/manual protection reassertion path; inventory it as existing policy, separate from new Phase 79 approval.
- `mix.exs` plus Phase 78 workflow integrity tests — named mandatory lane and criterion-ownership evidence.

### Established Patterns
- Phase 78 keeps mandatory deterministic browser evidence in CI and external IdP/provider checks as scheduled canaries.
- CI proof is split into named owners; `mix ci.security` suites run in separate fresh processes and standalone GATE-02 stays independent.
- Phase 73 governance binds remote mutation proposals to exact targets/payloads and source evidence; script invocation alone is not authorization for a new batch.
- Phase 78's closeout runner uses isolated paths and a receipt tied to committed source; caches and canary success do not substitute for mandatory evidence.
- Mature Git practice distinguishes tracked changes, untracked paths, ignored paths, and registered worktrees; Phoenix uses narrow ignore rules, while blanket cleanup can destroy local state.

### Integration Points
- Read-only local state comes from Git status/worktree inventories; current collaboration state comes from GitHub API/workflow data; current mandatory evidence comes from the Phase 78 lane map and source-bound receipt.
- The closeout dossier connects live branch protection to configured checks, each check to a current `main` SHA, external canaries to a separate incident account, and every remaining risk to a disposition and revisit condition.
- If implementation adds a recurring contract, wire deterministic checks into the existing mandatory CI ownership model rather than introducing a human completion gate.

</code_context>

<specifics>
## Specific Ideas

- User requested broad, research-backed analysis of every decision area, including pros/cons, tradeoffs, ecosystem conventions, successful examples and footguns, architecture/security/reliability/release-engineering viewpoints, and developer/maintainer experience. User directed the agent to consider all areas and follow the coherent recommendations without another choice round.
- The relevant JTBD is the maintainer/release owner deciding whether v1.11 can close safely: know what is clean, what is current on GitHub, whether the exact `main` revision has required deterministic proof, which external incidents need diagnosis, and what residual work is truly worth carrying.
- This phase has no application UI/API design. Make the human-facing inventory/report concise, scannable, evidence-linked, redaction-safe, and clear about what needs action or approval.
- Apply only relevant findings from `prompts/`; current project decisions and `AGENTS.md` override generic or stale examples. Use the latest `brandbook/` voice if copy conventions matter.

</specifics>

<deferred>
## Deferred Ideas

None raised. Visual dashboard work, unrelated CI expansion, and new SAML protocol capabilities are outside this phase boundary.

</deferred>

---

*Phase: 79-adopter-ready-closeout*
*Context gathered: 2026-09-29*
