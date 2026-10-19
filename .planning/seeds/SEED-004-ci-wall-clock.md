---
id: SEED-004
status: open
planted: 2026-10-16
planted_during: v1.10.0 release follow-up (PRs #48, #49, ci/fast-pr-gates)
trigger_when: now — next milestone or quick-task slot; the maintainer asked for it ASAP ("the sooner the better so we get dividends")
scope: medium (5-8 small PRs, or one CI-efficiency milestone)
---

# SEED-004: Cut CI/CD wall-clock (security-gates ~80 min → ~10 min)

## Why This Matters

Every PR waited ~80 min for `security-gates`. All other workflows finish in
under 3 min. Slow CI delays merges, the release PR auto-merge (which waits on the
`security-gates` `workflow_run`), and every fix loop. lattice_stripe, the
maintainer's reference "well oiled machine", runs full CI in ~2 min.

## Measured Baseline (run 38822648034, release PR #46, 2026-10-15)

| Job / step | Time |
|---|---|
| `security (27/28)` matrix leg, total | 20–23 min |
| — `mix qa` | ~8.4 min (506 s) |
| — `ci.phase73.reconciliation` | ~7.2 min (430 s) |
| — `ci.security` | ~2.7 min |
| — package consumer contracts | ~2.6 min |
| `Phase 78 cold-state receipt` | **80 min** (critical path) |
| — OTP 27 cold manifest | 38 min (2278 s) |
| — OTP 28 cold manifest | 40 min (2411 s), run **serially** after OTP 27 |
| demo-app-ci, demo-app-e2e, fleet/keycloak proxy e2e, adoption-external-idp | 1.6–2.8 min each |

## Root Causes (verified against origin/main)

1. **The Phase 78 cold receipt ran on every PR, serially per OTP.**
   - `scripts/check_phase78_clean_state.sh:704-727` runs a 22-command manifest from a fresh clone with private MIX/HEX/HOME and no caches.
   - It is not a required check. `scripts/setup_branch_protection.sh` requires only `security (27|28, 1.19.5)` and `fleet-proxy-e2e`, and live protection currently requires only the two security legs.
   - D-12/PIPE-05 (`78-CONTEXT.md:39`, `78-RESEARCH.md:423`) asks for a demonstrated clean-state pass "at phase completion", not one per PR. Per-PR wiring came from `78-07-PLAN.md:99` (commit 6d69f91).
2. **The Phase 73 replay ran inside default `mix test`.**
   - `test/test_helper.exs` did not exclude `:phase_73_reconciliation_replay` (`test/governance/phase_73_reconciliation_test.exs:6`).
   - The replay (`test/support/phase_73_reconciliation.ex:203-242`) spawns 21 focused `mix test` subprocesses, 3× `ci.evidence` and 1× `ci.security`, so it is ~6–7 min every time it runs.
   - Per OTP it ran 5× in total:
     - twice in the matrix (inside `mix qa` and in its owner step);
     - three times in the cold manifest (inside `mix test` (cmd 3), inside `mix qa` (cmd 4), and in `ci.phase73.reconciliation` (cmd 7)).
3. **The cold manifest runs both `mix test` (cmd 3) and `mix qa` (cmd 4).** `mix qa` contains `mix test`, so this duplicates ~7 min per OTP.
4. **No PR workflow caches deps or `_build`.**
   - Affected: security-gates.yml:63-67, demo-app-ci, demo-app-e2e, adoption-external-idp, release-parity.
   - The demo app is compiled cold three or more times per PR.
5. **The security leg is one serial job** of independent lanes (qa, phase73, ci.security, consumers, evidence/verify/integration, admin UI, Playwright).
6. **Planning-only PRs pay the full cost.**
   - security-gates ignores only `prompts/**`, not `.planning/**`.
   - `planning-pr-checks.yml:101-134` force-pushes a `.github/planning_ci_ref.txt` marker commit with a PAT to trigger required checks.
   - fleet-proxy-e2e and keycloak-proxy-e2e have no path filter.
7. **Main pushes are never deduplicated.** The concurrency group uses `github.run_id` on push, so back-to-back merges each run in full.
8. **Release publish re-runs the whole suite.** `release-please.yml` runs `mix qa`, `ci.release` and `ci.security`, and `publish-hex.yml` does the same.
   - The 1.10.0 publish failed there because of a shallow checkout and missing demo deps. Fixed in PR #49; 1.10.0 was published via `gh workflow run publish-hex.yml -f tag=v1.10.0`.
9. **Smaller items:**
   - No `timeout-minutes` on several jobs (the default is 360).
   - `npm install` is used instead of `npm ci` (security-gates.yml:82).
   - Playwright browsers are not cached.
   - Actions are unpinned in publish-hex.yml:66, release-parity.yml:12,15 and branch-protection-drift.yml:43.
   - The release-please cache key omits the OTP/Elixir version.
   - The branch-protection scripts and live settings disagree about `fleet-proxy-e2e`.

## Done (2026-10-16)

- **PR `ci/fast-pr-gates`** (maintainer-approved): the Phase 78 cold receipt now runs only when `always() && (github.event_name != 'pull_request' || github.head_ref == 'release-please--branches--main')`, i.e. on main pushes, dispatches and the release PR.
  - Default `mix test`/`mix qa` now exclude `:phase_73_reconciliation_replay`. Its owner, `mix ci.phase73.reconciliation`, still selects it with `--only` in both security legs.
  - Expected PR wall-clock: ~15–20 min.
  - Trade-off: a regression that only shows up in a cold start now surfaces on main, still before any release.
- **PR #49:** the release-please publish job gets `fetch-depth: 0` and demo deps before `mix qa`.
- **PR #48:** the Phase 78 job no longer `needs: security`, which cut ~26 min.

- **PR #50** merged as bc648e8e. Measured PR security-gates time is 19m11s, down from about 80 min. Local `mix qa` tests take 48 s, down from 617 s.
- **PR #51** merged as bc2e077b. It covers follow-ups 1 and 2:
  - the OTP 27 and OTP 28 cold producers now run in parallel;
  - the duplicate manifest `mix test` was dropped, leaving 21 commands;
  - the fleet_proxy LiveView-join flake is fixed.
  - Dispatch run 38899494149 had the whole cold path green in 23.5 min, down from 80.
- **PR #52** merged as 6de90a82 (maintainer-approved). PR CI took 9m22s; main run 38908477737 was green in 23.5 min including the cold path. Live protection on main now requires exactly `ci-gate` (strict). It covers follow-ups 3 and 4:
  - a `ci-gate` aggregator job;
  - `phase73-reconciliation` and `package-consumers` split out of `security` into parallel per-OTP jobs;
  - `timeout-minutes` on every security-gates job.
  - Protection switches to `ci-gate` only after merge, via `apply_ci_gate_protection.sh`.
  - Open: the Phase 79 tooling still assumes `security (27|28)` and `fleet-proxy-e2e` contexts (`scripts/collect_phase79_inventory.py`, `scripts/prepare_phase79_batch.py`). Reconcile them during the Phase 79 closeout.

- **PR #53** (`ci/warm-mix-cache`, merged as 24ba695b) covers follow-up 5. Main run 38947323550 seeded 4 caches. Measured on main run 38908477737: Mix compiles took about 80 s per `phase73-reconciliation` job (the critical path) and about 135 s per `security` job (demo test, root test and dev builds).
  - Both jobs restore an exact-key cache (`actions/cache/restore`, no restore-keys) of `deps`, `_build` and the LedgerLoop `deps`/`_build`.
  - The key binds the OS, job, OTP/Elixir tuple and the mix.lock/mix.exs/config sources.
  - Only successful main pushes save the cache (`actions/cache/save`, last step). PRs restore read-only.
  - The package consumers, the Phase 78 cold path and ci-gate are pinned cache-free.
  - Locked `mix deps.get` still runs, so the cache is a warm start only, never evidence (Phase 78 D-05).
  - The first main push after merge seeds the cache. Re-measure after that.
  - Known flake (fixed in PR `ci/hygiene-pins`, see below): `test/security/login_trace_test.exs:83` failed once in local `mix qa` because the LiveAdminEndpoint ETS table was missing. `LiveAdminEndpointSupport.do_start_endpoint/0` uses `start_link`, so the endpoint dies when the test process that started it exits, while other async tests still use it. Fix: start it unlinked or under the test app supervisor.

- **PR #54** (`ci/split-phase73-replay`, merged as 0cf3bc33; item 10, part 1) splits the Phase 73 replay, which had become the critical path.
  - Profile from the proof's `duration_ms` (local):
    - 21 focused `mix test` owners: 102 s;
    - 3× `mix ci.evidence`: 108 s;
    - a full `mix ci.security` replay: 115 s.
    - That is 325 s locally, and the test took 484 s on CI (main run 38947323550). The job took about 10 min.
  - `phase73-reconciliation` gains a `replay: [focused, evidence, security]` matrix axis, making 6 legs. Only the replay step sets `RELYRA_PHASE73_REPLAY_PART: ${{ matrix.replay }}`.
  - When the variable is unset, everything is replayed. That covers local runs and the Phase 78 cold manifest, which are unchanged.
  - Any other value raises: an empty value, `all`, or a comma list.
  - ci-gate requires every leg, so the union is the full replay. The proof, alias, selector and EVID-02 chain are unchanged.
  - `workflow_hygiene_test` pins the partition with 10 mutations:
    - a dropped or merged part;
    - a hardcoded part, or a missing or extra step env;
    - the variable set at job, workflow, security-job or cold-step level;
    - the variable appearing in any other workflow, `check_phase78_clean_state.sh` or `mix.exs`.
  - Measured on PR run 39178547294 (the first warm-cache hit): 5m06s end to end, down from about 10 min.
    - The phase73 legs took 2.4-4.2 min; the focused leg is the slowest.
    - `security` took 4.3-5.0 min, down from 6-7 min with the warm cache.
    - package-consumers took 2.5-3 min.
  - `security` step profile (OTP 28):
    - security lane 87 s (one `cmd mix test` per suite, which stays);
    - qa 45 s; evidence 26 s; Playwright install 19 s; verification 12 s; GATE-02 9 s;
    - containers 25 s; everything else is 5 s or less.
- **PR `ci/hygiene-pins`** covers item 9 and the login_trace flake:
  - `npm install` became `npm ci` in `security`.
  - The last tag-pinned actions are SHA-pinned to the repo-wide releases (checkout v7.0.1, setup-beam v1.24.1, cache v6.1.0) in `publish-hex.yml`, `release-parity.yml` and `branch-protection-drift.yml`. `workflow_hygiene_test` registers those pins.
  - The publish-hex cache key gains the OTP/Elixir tuple.
  - Flake fix: `LiveAdminEndpointSupport` unlinks the shared PubSub supervisor and endpoint after starting them. Before, they were linked to whichever async test process started them first, and died with it.
- **PR `ci/release-gate`** covers item 7 (maintainer-approved 2026-10-18).
  - Both Hex publish jobs (`release-please.yml` publish-hex and the `publish-hex.yml` recovery) no longer re-run `mix qa` and `mix ci.security`.
  - Instead, a step right after Checkout runs `scripts/check_release_ci_gate.sh`. It passes only when the newest GitHub Actions `ci-gate` run succeeded on either:
    - the release commit itself; or
    - the head of the single merged PR whose merge commit it is, with a byte-identical git tree. This fallback applies only when the release commit has no ci-gate run at all.
  - Release Please PRs are merged with GITHUB_TOKEN, and that push does not trigger security-gates. So the PR-head path is the normal release path; waiting for ci-gate on the tag commit would hang.
  - Failure modes:
    - failed, cancelled or skipped: fail;
    - missing: fail;
    - another app's or another name's check: ignored;
    - pending: polled for 30 min.
  - `ci.release`, the dry run, the idempotency check and the hex.pm poll stay.
  - The jobs gain `checks: read` and `pull-requests: read`.
  - Tests:
    - `release_ci_gate_test.exs` drives the script against a stub `gh` and a real git repo (17 scenarios);
    - `release_hardening_test` pins the step, its position, its permissions and the absence of qa/ci.security, with 7 mutations;
    - only security-gates may define a `ci-gate` job.
- **Decided, no change:**
  - Item 8, concurrency. PR runs already cancel superseded runs in every PR workflow. On main, each push keeps its own run (group by run id) so cold receipts are never cancelled. Queuing per ref would serialize back-to-back merges, which is slower, so it was dropped.
  - Playwright cache: about 10 s for added cache surface in `security`; not worth it.
  - demo-app-ci on one OTP and dropping the cron e2e runs: these cut runner cost, not PR wall-clock. Revisit only if runner minutes matter.

## Recommended Follow-ups (ordered by dividend ÷ effort)

1. **Parallel cold producers.**
   - Change: run the OTP 27/28 cold manifests in their own jobs (a matrix), each uploading its run JSON and diagnostics, with a final job that assembles the receipt and runs `mix ci.phase78.receipt`.
   - Saving: ~80 → ~40 min on main and the release PR.
   - The receipt schema already accepts runs from different hosts (distinct `runner_identity_sha256` per run).
   - Pins to update:
     - `phase78_clean_state_contract_test.exs:740-772, 987-1024`: single job, step names, the artifact name `-otp27-28`, step order.
     - `workflow_hygiene_test.exs:22-26, 68-72`: the job identities, plus pin counts (checkout ×2, setup-node ×2, setup-beam ×3).
2. **Drop cmd 3 (`mix test --warnings-as-errors`) from the cold manifest.** cmd 4 (`mix qa`) contains it, so this saves ~7 min per OTP. Update `@manifest` in `phase78_clean_state_contract_test.exs:7-30` and the script list together.
3. **One required `ci-gate` aggregator** (lattice_stripe `ci.yml:456-504` pattern):
   - The job uses `needs: [all]` and `if: always()`, and fails unless every needed job's result is `success`. Check `needs.*.result` explicitly; never treat `skipped` as success by accident.
   - Make it the only required check, and update `scripts/setup_branch_protection.sh` and the drift workflow to match.
   - This makes items 4 and 6 safe. Never path-filter a required workflow, because a filtered required workflow stays Pending.
4. **Split the security leg into parallel jobs:**
   - qa, phase73, ci.security, consumers, browser/admin UI;
   - run phase73, consumers and browser on OTP 28 only;
   - keep each `ci.security` suite as its own `cmd mix test` (the Phase 30 hollow-gate rule);
   - expected PR wall-clock: ~10 min, bounded by `mix qa`.
5. **Caching on warm jobs only.**
   - Cache `deps` and `_build` separately, including `demo/ledger_loop`. Key them `os-<elixir>-<otp>-{mix,build}-hash(mix.lock)`, and use an exact key for `_build`, or add `hashFiles('config/**')` to it.
   - Restore on PRs and save only on push to main (cache-poisoning hygiene).
   - Never use a cache in the cold, release or publish jobs.
   - Saves ~1–3 min per job.
6. **Planning-only fast path.** Use in-workflow change detection with job-level `if:` under the aggregator, then delete the `planning_ci_ref.txt` marker-push hack. Saves the full run on `.planning`-only PRs.
7. **Release publish gates on green CI for the release SHA** (lattice `gate-ci-green`) instead of re-running qa/security. Keep `ci.release`, `hex.build`, the dry run, the idempotency check and the hex.pm poll. Saves ~10 min per release and removes the class of failure behind the 1.10.0 publish.
8. **Concurrency.** Make it `${{ github.workflow }}-${{ github.ref }}` on push too, or at least queue per ref. Note: `workflow_hygiene_test.exs:179-184, 451-462` currently pins "cancel only pull_request".
9. **Hygiene:**
   - add `timeout-minutes` everywhere;
   - use `npm ci`;
   - cache Playwright;
   - SHA-pin the remaining actions;
   - add OTP/Elixir to the release cache key;
   - run demo-app-ci on one OTP leg;
   - drop the redundant daily cron e2e runs (only the Rulestead canary needs cron).
10. **Profile the remaining `mix qa`** with `mix test --slowest 25`. Suspects:
    - `ci_gate_integrity_test.exs` (7 fixture `mix pipeline` runs);
    - `evidence_contract_test.exs` (5 fixture mix runs);
    - `verify_release_parity_test.exs` (hex.build);
    - `phase78_clean_state_contract_test.exs` (async false, bash/git fixtures);
    - `milestone_scope_test.exs` (11k lines, 24 git calls).

    Consider `mix test --partitions` with `MIX_TEST_PARTITION`-suffixed databases, or tag-splitting governance tests into their own job.

Decided against: **GitHub merge queue**. It is unavailable for a user-owned repo, and its merge commits conflict with the merge-commit provenance rule.

## Constraints to Respect

- Security invariants and `mix ci.security` per-suite `cmd mix test` processes (CLAUDE.md, Phase 30).
- `adversarial_crypto_test.exs` and GATE-02 stay unconditional in `jobs.security` (`ci_gate_integrity_test.exs:546-560`).
- Changing which checks are *required*, or removing a check from the PR path, is a gate-posture change. Get the maintainer's approval first (the cold-receipt move above was approved).
- Workflow edits are blocked for the agent by the auto-mode classifier. Ship them as maintainer-run scripts, or have the maintainer apply them.
- Merge with merge commits, never squash (governance provenance).
- PRs that touch locked sources may need a Phase 73 proof recapture (`Relyra.Phase73Reconciliation.capture!/2`).

## Sources

- Research notes (2026-10-16): Phoenix/Oban CI matrices; GitHub docs on dependency caching (restore-keys pick the most recent prefix match; caches are unsigned), required checks and path filters (a filtered required workflow stays Pending), merge queue availability; elixir-lang/elixir `check_reproducible`, which runs on one OTP only.
- lattice_stripe `.github/workflows/ci.yml` (a `ci-gate` aggregator, 12 small parallel jobs with timeouts, deps/_build cache) and `release.yml` (`gate-ci-green`, idempotent publish).
