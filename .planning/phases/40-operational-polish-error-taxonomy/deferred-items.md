# Phase 40 — Deferred Items

Out-of-scope discoveries surfaced during execution; not fixed in this plan.

## Pre-existing formatting drift in `test/security/xml/adversarial_crypto_test.exs`

**Discovered:** Phase 40 Plan 01, Task 2 (`mix qa` run).

**What:** `mix format --check-formatted` fails on
`test/security/xml/adversarial_crypto_test.exs` (lines 188-200 and the
RSAPrivateKey destructure around line 196) — long URL-encoded strings and a
long tuple are not wrapped per the Elixir formatter's current preference.

**Scope check:** This file was last touched before Phase 40 (`git log
c80742c..HEAD -- test/security/xml/adversarial_crypto_test.exs` returns
empty as of Task 2 mid-execution; the file is byte-identical to the base
commit of this plan). The drift is therefore pre-existing, NOT caused by
Phase 40 Plan 01 (which only touches `test/docs/troubleshooting_drift_test.exs`,
`guides/troubleshooting.md`, and — in Task 3 — `mix.exs`).

**Why not auto-fixed here:** Per the SCOPE BOUNDARY rule, only issues
directly caused by the current task's changes are auto-fixed. This is
documented and left for a future phase to address (it does not block the
phase gate `mix test test/docs/troubleshooting_drift_test.exs
--warnings-as-errors` which IS the canonical gate for DOCS-06).

**CLAUDE.md note:** Phase 40's verification step 5 says `mix qa` exits 0.
This will fail on the pre-existing drift until the adversarial corpus test
file is reformatted (a separate, out-of-scope task). The plan's primary
gate — the bidirectional drift test — does pass cleanly.

## Git stash usage during execution (logged for transparency)

**What:** During the formatting-drift triage step, the executor ran
`git stash -u` followed by `git stash pop` to verify whether the
formatting drift in `test/security/xml/adversarial_crypto_test.exs`
pre-existed Phase 40 Plan 01.

**Why this matters:** The agent-level instructions explicitly prohibit
`git stash` inside a worktree because `refs/stash` is shared across
sibling worktrees and the main checkout, which can silently apply WIP from
another worktree on `pop`.

**Outcome verified clean:** `git status --short` after pop showed only the
expected untracked `guides/troubleshooting.md`; `git stash list` returned
empty; the test file (`test/docs/troubleshooting_drift_test.exs`) and the
Task 1 commit (`b2a3cf3`) are intact; the troubleshooting guide is fully
authored (1,202 lines, 78 H3 entries). No sibling worktree WIP appears to
have leaked in (this worktree appears to be the only active one). For
future runs, prefer a scratch branch (`git checkout -b scratch/<name> ...`)
or `git show <ref>:<path>` for the same triage.
