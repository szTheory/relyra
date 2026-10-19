# Phase 79 Remote Batch

**Status:** executed approved batch; read-back complete.

- Target repository: `szTheory/relyra`
- Observed main SHA: `ed2d2cf1c898207f0d825ce9053979b14055e27e`
- Approval: the maintainer approved each operation below as an exact batch in session on 2026-10-19, before it ran.
- Protection capture: [79-PROTECTION-CAPTURE.json](79-PROTECTION-CAPTURE.json)
- No workflow was dispatched and no protection setting was written beyond Operation 1.

## Operation 1 — clear the review subresource

- Command: `gh api -X DELETE repos/szTheory/relyra/branches/main/protection/required_pull_request_reviews`
- Preflight: the parent protection response omitted `required_pull_request_reviews`; GraphQL reported `requiresApprovingReviews=false` and `requiredApprovingReviewCount=null`; the subresource still returned `required_approving_review_count=1`.
- Result: HTTP 204
- Read-back: the parent protection response was byte-identical before and after, and the subresource still returned the same default body. This shows that body is GitHub's placeholder, not an enabled rule. #53–#58 each merged with zero reviews under `enforce_admins=true`. The capture now treats reviews as disabled only when the parent omission and GraphQL agree.
- Rollback: not needed, because the observable state did not change. To require reviews later, PATCH the subresource with `required_approving_review_count`.

## Operation 2 — delete merged remote branches

Each branch was re-checked with `compare/main...<branch>` immediately before `gh api -X DELETE repos/szTheory/relyra/git/refs/heads/<branch>`. Every one was 0 commits ahead of main, so main contains each recorded head.

| Branch | Head SHA | Ahead of main | HTTP |
| --- | --- | ---: | ---: |
| chore/housekeeping-ci-cve | `162a3704c9bc42d7b56fb50c3c9ba1bb85949636` | 0 | 204 |
| chore/maintenance-1.5.1 | `b8f2693e57851cf877c0384eccf75a60cf9d69e8` | 0 | 204 |
| chore/retire-real-idp-canary | `266df70ff5fa1c2e22a6673c3bac0aa243c00f0b` | 0 | 204 |
| ci/ci-gate-split | `9ae5d7f59a23e1df4faaf40ad441e3c84ea1c178` | 0 | 204 |
| ci/drop-planning-marker | `d3b7fd55156adc8b29de816fda103ef8cea3d0d8` | 0 | 204 |
| ci/enforce-admins-protection | `6b0fb578b8ef97e6b57eca89bd17e71d0b505d6b` | 0 | 204 |
| ci/fast-pr-gates | `d2b7a84810f18feb1a726a15180b107d71df72dc` | 0 | 204 |
| ci/hygiene-pins | `18dce9f9537f33687b2e9b7d23928192f448b5ee` | 0 | 204 |
| ci/parallel-cold-receipt | `351d1802394317987b4ec1dd2c1f2a928214dfdd` | 0 | 204 |
| ci/release-gate | `775efc009f12c368932e9f06e1f25e21b9fdaa0d` | 0 | 204 |
| ci/release-publish-job-setup | `a0e51310243c69fa485a22afdec9535141f03997` | 0 | 204 |
| ci/security-gates-wall-clock | `7ceee68262571cbad8b3c329bebabafab11d33b7` | 0 | 204 |
| ci/split-phase73-replay | `6cbcd03d2672d3926e8303b67c9d710960b71f3f` | 0 | 204 |
| ci/warm-mix-cache | `689ce1b602ef3f7bed319699e4fadc666350c834` | 0 | 204 |
| codex/v1.11-adopter-ready-42513dccd09c | `e9bde4111942606153cc3a5de995b8eb15f31566` | 0 | 204 |
| docs/housekeeping-wave3 | `378ce37a32e508d160f5b8b3743cf0754db3838b` | 0 | 204 |
| docs/planning-1-5-1-closure | `7b7107ebe6af4e8f79d041faed2cc8b288187276` | 0 | 204 |
| fix/ci-release-1-5-1-trigger | `7303b3659883458102e97d691540736b3ce2ff64` | 0 | 204 |
| fix/phase73-version-agnostic-mix-pin | `2563dd58a9fdf655f8a2455e69054c629989bb9e` | 0 | 204 |
| fix/test-logout-replay-flake | `d2bb6bf6c957162598d47e2e31657be92fea646d` | 0 | 204 |

- Result: HTTP 204
- Read-back: `gh api repos/szTheory/relyra/branches` lists only `main` plus the three preserved branches below.
- Rollback: restore a branch from its merged PR, or push the recorded head SHA.

Preserved because they hold commits that are not on main:

- `docs/phase-50-state-closeout` (4 ahead, #30 merged)
- `docs/planning-publish-gap-closed` (1 ahead, #24 closed)
- `fix/68-demo-docker-dev-boot` (1 ahead, #41 closed)

## Operation 3 — delete the retired canary environment

- Command: `gh api -X DELETE repos/szTheory/relyra/environments/real-idp-canary`
- Preflight: no workflow has referenced the environment since #58 retired the real IdP canary.
- Result: HTTP 204
- Read-back: `gh api repos/szTheory/relyra/environments` reports `total_count` 0.
- Rollback: recreate the environment. It held no secrets or protection rules.

## Protection

The captured protection equals `scripts/setup_branch_protection.sh --print-expected-json`: the `ci-gate` required context (strict), `enforce_admins`, no required reviews, no push restrictions, and no force pushes or deletions. [79-PROTECTION-DESIRED.json](79-PROTECTION-DESIRED.json) records an empty delta, and [79-PROTECTION-ROLLBACK.json](79-PROTECTION-ROLLBACK.json) records the captured payload. No further protection write is proposed.
