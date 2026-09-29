# Phase 79: Adopter-Ready Closeout - Discussion Log (Research-Augmented Assumptions)

> **Audit trail only.** Decisions for planning are in `79-CONTEXT.md`.

**Date:** 2026-09-29
**Phase:** 79-adopter-ready-closeout
**Mode:** assumptions, expanded per user's request for deep research and automatic recommendation selection
**Areas analyzed:** local repository/worktree state; GitHub inventory freshness; remote mutation approval; main readiness and canaries; residual risk and maintainer experience

## User Direction

The user supplied a standing research prompt: compare viable approaches and tradeoffs, consider ecosystem conventions and successful/failed examples, reason across relevant software architecture, security, DevOps/SRE, release engineering, and user/developer experience lenses, review applicable `prompts/` research, prefer the current `brandbook/` over the older brand prompt, and synthesize one coherent set of recommendations without another decision round. They explicitly directed the agent to consider all areas and follow its recommendations.

Visual UI design was judged not applicable to this repo/CI closeout. The maintainers' report and inventory still have a user-facing job: make the current state, evidence, approvals, and next action easy to understand without exposing irrelevant implementation details.

## Assumptions and Recommendations

### 1. Local repository and worktree cleanliness (REPO-01)

| Approach | Advantages | Costs and risks | Decision |
|---|---|---|---|
| Delete all untracked and ignored artifacts, then verify a pristine checkout | Broad reset; simple clean-build model | Can delete user-owned configuration or data, incurs rebuild work, and still does not identify linked worktree state | Use only for disposable CI or an explicitly disposable checkout |
| Classify relevant tracked, untracked, ignored, and registered-worktree state by owner and disposition | Protects user data; covers the actual clean-state claim; provides an auditable disposition | Requires a bounded ownership inventory; unknown owners remain unresolved | **Selected.** Preserve known user-owned `.tool-versions`; inventory before cleanup; remove only confirmed obsolete artifacts in approved local scope |
| Check tracked files and worktrees, with a separate scratch report | Small tracked-state check | Split evidence can go stale or be overlooked; tracked-only evidence can hide untracked/ignored scratch state | Rejected as the sole REPO-01 proof; scratch state must be part of the closeout decision |

Git porcelain status, ignored-file views, and worktree listings cover different state classes; a broad `git clean -x` can remove ignored and untracked files. Phoenix's `.gitignore` is a useful mature example of targeted generated-output exclusions. Sources: [git-status](https://git-scm.com/docs/git-status), [git-clean](https://git-scm.com/docs/git-clean), [git-worktree](https://git-scm.com/docs/git-worktree), [gitignore](https://git-scm.com/docs/gitignore), [Phoenix `.gitignore`](https://github.com/phoenixframework/phoenix/blob/main/.gitignore).

### 2. GitHub inventory freshness and completeness (REPO-02)

| Approach | Advantages | Costs and risks | Decision |
|---|---|---|---|
| Reuse the Phase 73 dated snapshot | No live queries | Stale PR, issue, branch, workflow, and protection values could misdirect cleanup or readiness | Rejected; baseline is historical evidence only |
| Timestamped, read-only inventory with source SHA, pagination/completeness, and access errors | Current, reviewable evidence; read-only data collection creates no approval burden | Must handle pagination and state changing during collection; report partial access honestly | **Selected.** Refresh immediately before proposals/actions and bind check evidence to exact refs/SHAs |
| Mix live reads and remote cleanup while collecting | Could reduce operator steps | Blurs evidence and action, makes approval scope unclear, and creates TOCTOU risk | Rejected; separate inventory and exact mutation batches |

The inventory should include PRs, issues, local/remote branches, workflow health, required checks, and branch-protection state. GitHub exposes separate read endpoints and pagination; complete traversal and collection time are part of evidence, not implementation detail. Sources: [GitHub PRs](https://docs.github.com/en/rest/pulls/pulls), [issues](https://docs.github.com/en/rest/issues/issues), [branches](https://docs.github.com/en/rest/branches/branches), [workflow runs](https://docs.github.com/en/rest/actions/workflow-runs), [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api).

### 3. Remote mutation approval (REPO-03)

| Approach | Advantages | Costs and risks | Decision |
|---|---|---|---|
| Treat the existing scheduled protection workflow as standing approval for Phase 79 changes | No repeated review; existing policy can reassert intended state | Its PAT has Administration write authority; a prior committed workflow does not identify or approve a different current repair batch | Rejected as approval for new Phase 79 actions |
| Require runtime approval for every scheduled protection write | Review is near execution | Can create daily approval fatigue; approval can still be stale unless bound to exact payload and preflight; drift workflow may reapply without a delta | Not adopted for the existing workflow; changing it needs its own exact approved batch |
| Inventory the scheduled workflow as inherited policy; bind each new Phase 79 mutation to a fresh exact batch | Separates prior policy from new authorization; preserves audit trail, least privilege, preflight, rollback, and read-back | Requires a fresh state check and explicit approval for each non-empty proposed batch | **Selected.** Leave the existing workflow untouched and do not claim it satisfies REPO-03 for new changes |

The exact batch should specify target, current and desired state, affected checks/items, reason, least-privilege operation, preflight, rollback, read-back, and resume signal. Refresh immediately before execution and stop if the target changed. The current workflow invokes a write-capable branch-protection script with a repository PAT; it is inventoried as an inherited path, not used or changed by this discussion. GitHub separates read and write permissions for protection and recommends minimum token permissions. Sources: [protected branches API](https://docs.github.com/en/rest/branches/branch-protection), [fine-grained token permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens), [Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use), [GitHub environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments).

### 4. Main readiness and external canary treatment

| Approach | Advantages | Costs and risks | Decision |
|---|---|---|---|
| Rerun the entire clean-state matrix for every closeout | Fresh end-to-end results | Costly duplicate proof; a local run does not establish live protection or current `main` status | Use only when relevant source/evidence inputs changed, proof is missing/failed/stale, or release-tag verification requires it |
| Inspect only configured required status contexts | Direct answer about branch protection | Required contexts may not represent every mandatory lane or source-bound evidence requirement | Use as one readiness input, not as the whole answer |
| Two-tier dossier: exact-current-main required checks plus source-bound deterministic receipts and separate canary status | Establishes both branch status and evidence provenance without treating canaries as merge proof | Requires clear SHA freshness labels and disciplined reporting | **Selected.** Bind each claim to the exact main/source SHA; compare the full mandatory-lane owner inventory as well as protection contexts |

Reuse Phase 78's receipt only when its source commit/digest and proof scope match the claim. GitHub merge queues use a `merge_group` SHA; scheduled workflows can be delayed or dropped under load, so scheduled canary status cannot substitute for deterministic CI. Report any canary incident with safe evidence and diagnosis, separate from deterministic readiness. Sources: [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [merge queues](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue?apiVersion=2022-11-28), [Hex publishing guide](https://hex.pm/docs/publish) for the ecosystem expectation that package-boundary proof should be exercised by a consumer.

### 5. Residual risk and maintainer-facing report (EXIT-01)

| Approach | Advantages | Costs and risks | Decision |
|---|---|---|---|
| Narrative-only “done” statement | Short | Does not show whether every remaining idea was considered or why it is safe to defer | Rejected |
| Close or suppress the entire backlog for milestone neatness | A short remaining list | Can erase valid demand-gated or approval-blocked work and hides maintenance tradeoffs | Rejected |
| Evidence-backed residual-risk ledger with explicit category, owner, trigger, and revisit condition | Makes the diminishing-returns argument inspectable; preserves useful deferred work | Needs consistent bounded vocabulary and current evidence | **Selected.** Assign every remaining item low-value, demand-gated, approval-blocked, or costlier-to-maintain; retain the Phase 73 severity/blocker posture |

High/Critical findings remain blockers until resolved; Medium and lower items remain visible with explicit disposition. A row should carry evidence, adopter demand/trigger, severity/impact, maintenance burden, owner, approval boundary, and revisit condition/date. The Phase 73 baseline provides this vocabulary and warns against converting unresolved evidence into a closure claim. The current brandbook's voice (“calm, exact, transparent, operator-friendly, open-source serious”) is appropriate for the closeout report; its visual system is not applicable. Sources: `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md`, `brandbook/README.md`, `brandbook/notes/decision-log.md`.

## Cross-Cutting Evidence and Lessons

- The active branch already contained `79-RESEARCH.md`, `79-VALIDATION.md`, and `79-PATTERNS.md` from the GSD chain. Their recommendations align with this research: ownership-aware cleanup, current read-only inventory, exact-SHA evidence, a separate mutation approval boundary, deterministic acceptance, and explicit residual-risk dispositions. The updated context preserves the original D-01 through D-04 meanings so those artifacts' requirement references remain valid, and adds them as canonical references. The existing research specifically calls out revalidating `.planning/WINDOWS.md`, including the two Phase 76 concurrency gaps.
- Relyra's existing pattern is explicit lane ownership and CI as a specification, not a single opaque “green” badge. The sibling-library research cites Sigra's documented named CI jobs and Kiln's local quality command as good contributor ergonomics; it also warns against over-engineering shared workflows across a single repository. Source: `prompts/relyra-engineering-dna-from-prior-libs.md`.
- The Elixir OSS CI research emphasizes warning-free compile/test/docs, release automation, and least-privilege workflow permissions. Apply the principle of clear, reproducible proof, but do not expand Phase 79 into new generic gates or change the project's release policy. The prompt's generic Hex command examples do not supersede `AGENTS.md`'s prohibition on manual `mix hex.publish`.
- The wider Elixir library research treats package metadata, docs, stable CI lanes, and consumer-facing integration as part of library DX. For this phase, translate that into clear maintainer reporting and package/readiness evidence, not changes to Relyra's API or SAML behavior.
- Interface/design pillars were evaluated for applicability: no application UI is in scope. Information architecture, accessible plain-text structure, scannability, redaction safety, precise microcopy, and system consistency still apply to the Markdown inventory and risk report.

## User's Initial Workspace Snapshot

At the initial read-only inspection, the checkout was on `gsd/phase-73-gap-closure`, with modified `.planning/STATE.md` / `.planning/state.json` and untracked `.gsd/`, `.planning/research/.cache/*.json`, `.tool-versions`, and a `tmp_5AC9BEC9C49ECD6F2C077F96F07226D381F28512D8A4F7186985311A17205E58/` directory. STATE identifies `.tool-versions` as user-owned. None of these items was changed or cleaned during discussion. Recheck current state before using this dated snapshot as evidence.

## Corrections and Recommendation Selection

The user asked for research across every area and explicitly said to consider all of them and automatically follow the recommendations. Three GSD advisor researchers reviewed the relevant project sources and external official documentation. No follow-up preference selection was requested. The recommendations above were adopted in `79-CONTEXT.md`; this selection does not authorize any remote GitHub action.

## Research Sources

- Git semantics: [status](https://git-scm.com/docs/git-status), [clean](https://git-scm.com/docs/git-clean), [worktree](https://git-scm.com/docs/git-worktree), [ignore](https://git-scm.com/docs/gitignore).
- GitHub inventory and governance: [pull requests](https://docs.github.com/en/rest/pulls/pulls), [issues](https://docs.github.com/en/rest/issues/issues), [branches](https://docs.github.com/en/rest/branches/branches), [workflow runs](https://docs.github.com/en/rest/actions/workflow-runs), [pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api), [branch protection](https://docs.github.com/en/rest/branches/branch-protection), [token permissions](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens), [Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use), [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [merge queues](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue?apiVersion=2022-11-28).
- Ecosystem examples: [Phoenix `.gitignore`](https://github.com/phoenixframework/phoenix/blob/main/.gitignore), [Hex publishing guide](https://hex.pm/docs/publish).
- Project-specific research: `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/relyra-engineering-dna-from-prior-libs.md`, plus the Phase 73/78 artifacts listed in `79-CONTEXT.md`.
