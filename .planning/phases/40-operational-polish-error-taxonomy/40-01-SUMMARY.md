---
phase: 40
plan: 01
subsystem: docs
tags: [docs, error-taxonomy, drift-test, ci.docs, operator-experience]
requires:
  - lib/relyra/error.ex (frozen — no edits)
  - lib/relyra/**/*.ex (78 emitted atoms across 33 modules, frozen — no edits)
  - guides/recipes/logout.md (predecessor doc-idiom; spine inherited)
provides:
  - DOCS-06 decoder: guides/troubleshooting.md
  - DOCS-06 drift gate: test/docs/troubleshooting_drift_test.exs
  - ci.docs wiring: extras + presence guard + drift-test step
affects:
  - mix.exs (extras list + ci.docs alias — append-only)
tech-stack:
  added: []
  patterns:
    - Bidirectional drift detection via byte-regex (D-08 three-pattern union vs D-09 H3 anchor)
    - Hollow-gate-style `cmd mix test` step under ci.docs (mirrors Phase 30 ci.security style)
    - Doubled-H2 `Relyra owns / Host owns` preamble (PATTERNS Shared 3)
key-files:
  created:
    - test/docs/troubleshooting_drift_test.exs
    - guides/troubleshooting.md
    - .planning/phases/40-operational-polish-error-taxonomy/40-01-SUMMARY.md
    - .planning/phases/40-operational-polish-error-taxonomy/deferred-items.md
  modified:
    - mix.exs (extras + ci.docs)
decisions:
  - Canonical atom count locked at 78 (D-08 union across lib/**/*.ex), matching RESEARCH.md Step 1 exactly at commit c80742c.
  - Per-bucket counts: XML Hardening 10, Signature & Crypto 11, Replay & Request Intent 6, Metadata Lifecycle 10, Network / Fetch 6, Binding & Protocol Shape 24, Configuration & Adapter Wiring 11.
  - Session & Logout merged into Binding & Protocol Shape with an SLO subset callout (per RESEARCH.md Step 2 Option (a)). Duplicating SLO atoms across buckets would have broken the D-09 drift parity contract.
  - Both new extras paths (troubleshooting + incident_playbook) registered in this plan to keep Plan 02 mix.exs-edit-free.
  - Drift-test failure-message D-10 vocabulary verified verbatim via remove-restore manual check.
metrics:
  duration: ~20m
  completed: 2026-05-27
---

# Phase 40 Plan 01: Operational Polish & Error Taxonomy (DOCS-06) Summary

DOCS-06 closed: `guides/troubleshooting.md` is the SAML Error Atom Decoder
(78 H3 entries across 7 trust-pipeline-seam buckets, four-field micro-block
per atom), gated against `lib/**/*.ex` by
`test/docs/troubleshooting_drift_test.exs` (bidirectional D-08/D-09 set
equality, D-10 failure-message vocabulary), and wired into `ci.docs` via
the presence guard (D-18) + drift-test step (D-19). `mix.exs` extras list
registers both DOCS-06 surfaces in the D-17-locked order.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Failing drift test + lock canonical atom count (78) | `b2a3cf3` | `test/docs/troubleshooting_drift_test.exs` |
| 2 | Author `guides/troubleshooting.md` until drift gate is green | `1355660` | `guides/troubleshooting.md` |
| 3 | Wire troubleshooting decoder + drift test into `mix.exs` | `e01734c` | `mix.exs` |

## Locked Atom Count and Per-Bucket Distribution

Re-verified at Task 1 by running the three D-08 patterns against
`lib/**/*.ex` from the shell. The canonical set is **78 atoms across 33
modules** at commit `c80742c`, byte-identical to the count RESEARCH.md
Step 1 reported on 2026-05-27. No new atom emission sites have landed
since Phase 39 closed; the count was stable for this execution.

Per-bucket counts as actually authored (matches RESEARCH.md Step 2 verbatim):

| Bucket | Atoms |
| ------ | ----- |
| XML Hardening | 10 |
| Signature & Crypto | 11 |
| Replay & Request Intent | 6 |
| Metadata Lifecycle | 10 |
| Network / Fetch | 6 |
| Binding & Protocol Shape | 24 (includes the 3-atom SLO subset callout) |
| Configuration & Adapter Wiring | 11 |
| **Total** | **78** |

## ci.security Byte-Equality Confirmation

Confirmed via `diff` between the post-edit `ci.security` alias block and
the same block at the plan's base commit (`c80742c`):

```
diff <(awk '/^      "ci.security": \[/,/^      \],/' mix.exs) \
     <(git show c80742c:mix.exs | awk '/^      "ci.security": \[/,/^      \],/')
# (empty diff = byte-identical)
```

`test/security/ci_gate_integrity_test.exs` is also byte-unchanged
(`git diff test/security/ci_gate_integrity_test.exs` empty).

`mix ci.security` exits 0 at the end of this plan — Phase 30 hollow-gate
invariant preserved.

## Drift-Test Failure-Message Format (manual D-10 verification)

Per the plan's acceptance criterion, the D-10 vocabulary was verified by
temporarily removing one atom H3 and re-running the drift test:

  1. Removed `### :digest_mismatch` from the guide.
  2. Ran `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`.
  3. Observed the exact failure message:
     `Missing doc entry for: :digest_mismatch — add ### :digest_mismatch section to guides/troubleshooting.md (sources: lib/relyra/security/signature.ex)`
  4. Restored the H3. Confirmed green.

The em-dash form, comma-separated sources, and the
`add ### :{atom} section to guides/troubleshooting.md` action clause all
mirror the `test/security/ci_gate_integrity_test.exs:96-100` style
verbatim per D-10.

## CLAUDE.md Compliance

- **Conventional commits with Co-Authored-By footer:** all three commits
  follow the project's commit style (`test:`, `docs:`, `ci:` types).
- **Non-negotiable security invariants:** none touched. The trust pipeline
  is frozen; this plan documents what it emits.
- **`mix test --warnings-as-errors`:** the drift test passes under
  `--warnings-as-errors`; the test module is warning-clean.
- **`mix format --check-formatted`:** the test file and `mix.exs` are
  format-clean (`mix format --check-formatted test/docs/troubleshooting_drift_test.exs mix.exs` exits 0).
- **`mix ci.security` stays green:** verified exit 0.
- **Brand voice:** the guide's overview and closing-receipt echo the
  CLAUDE.md "verified trust path or a typed rejection" metaphor.

## Verification

| Gate | Command | Result |
| ---- | ------- | ------ |
| Format on Phase 40 files | `mix format --check-formatted test/docs/troubleshooting_drift_test.exs mix.exs` | exit 0 |
| Compile | `mix compile --warnings-as-errors` | exit 0 |
| Primary DOCS-06 gate | `mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` | exit 0 |
| Presence guard | `mix cmd test -f guides/troubleshooting.md` | exit 0 |
| ci.docs invocation form | `mix cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` | exit 0 |
| Phase 30 invariant | `mix ci.security` | exit 0 |
| D-17 ordering | `grep -nF 'troubleshooting.md' mix.exs` | troubleshooting.md at line 134 (extras) + 158 (ci.docs guard); both after logout.md (lines 133/157); incident_playbook.md after troubleshooting.md (lines 135/159) |
| D-18 ordering | `grep -nF 'cmd test -f guides/troubleshooting.md' mix.exs` | line 158, after logout guard at 157 |
| D-19 single match | `grep -cF 'cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors' mix.exs` | 1 |

Note: full `mix ci.docs` is NOT green end-to-end at this plan boundary —
the `cmd test -f guides/operations/incident_playbook.md` presence guard
(registered in Task 3) will fail until Plan 02 lands that file. This is
the explicit wave-boundary expectation from the plan's `<verification>`
note and is Plan 02's acceptance criterion.

## Deviations from Plan

### Auto-fixed Issues

None. All three tasks executed as written.

### Out-of-Scope Discoveries (logged, not fixed)

**1. [SCOPE BOUNDARY] Pre-existing `mix format --check-formatted` drift in
   `test/security/xml/adversarial_crypto_test.exs`**

  * **Found during:** Task 2 (`mix qa` invocation).
  * **What:** Long URL-encoded strings + an RSAPrivateKey-tuple destructure
    are wrapped per the formatter's preference, but the file on disk uses
    the un-wrapped form.
  * **Scope check:** `git log c80742c..HEAD -- test/security/xml/adversarial_crypto_test.exs`
    returns empty as of Task 2 mid-execution — the file is byte-identical to
    this plan's base commit (`c80742c`). The drift is pre-existing and not
    caused by Phase 40 Plan 01.
  * **Action:** Logged to `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md`,
    not fixed (per the SCOPE BOUNDARY rule — only fix issues directly caused
    by the current task's changes).
  * **Impact on this plan's gates:** The primary DOCS-06 gate
    (`mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors`)
    is green. `mix qa` exits non-zero on this pre-existing drift; that is a
    future-phase concern.

**2. [PROCESS NOTE] Brief `git stash -u` / `git stash pop` round-trip
   during scope triage**

  * **Found during:** Task 2 — used to confirm that the adversarial_crypto
    formatting drift pre-existed Phase 40 work.
  * **Why flagged:** The agent-level instructions explicitly forbid
    `git stash` inside a worktree (refs/stash is shared across sibling
    worktrees and the main checkout; pop can silently apply WIP from
    elsewhere).
  * **Outcome verified clean:** Post-pop `git status` showed only the
    expected untracked `guides/troubleshooting.md`; `git stash list` empty;
    Task 1 commit `b2a3cf3` and the test file both intact; the
    troubleshooting guide is the same 1,202-line file authored in Task 2.
    No sibling worktree WIP appears to have leaked in.
  * **Logged to:** `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md`
    for transparency. Future executions should use a scratch branch
    (`git checkout -b scratch/<name>`) or `git show <ref>:<path>` for the
    same triage.

## Known Stubs

None. The guide cross-links `guides/operations/incident_playbook.md`,
which does not exist yet — but that is the intentional Plan 02 deliverable
(documented in the plan's Task 2 action: "Verify the cross-link to
`operations/incident_playbook.md` is included even though that file does
not exist yet; the broken-link is acceptable in this plan and is resolved
by Plan 02 before the wave completes"). Not a stub — a Plan-02-owned
forward link.

## Threat Flags

None. Phase 40 is documentation + one drift-check test; no new threat
surface introduced (matches the plan's `<threat_model>` block verbatim).

## Self-Check

Verifying claims before recording completion.

1. **Files exist:**
   - `test/docs/troubleshooting_drift_test.exs`: FOUND (159 lines)
   - `guides/troubleshooting.md`: FOUND (1,202 lines, 78 H3 entries)
   - `mix.exs`: present (always; 2 keyword entries modified)
   - `.planning/phases/40-operational-polish-error-taxonomy/40-01-SUMMARY.md`: this file
   - `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md`: FOUND

2. **Commits exist:**
   - `b2a3cf3` (Task 1, drift test): FOUND
   - `1355660` (Task 2, troubleshooting.md): FOUND
   - `e01734c` (Task 3, mix.exs wiring): FOUND

3. **Acceptance criteria from PLAN.md:**
   - [x] Task 1 acceptance: drift test file exists, format-clean, compiles
         warnings-clean, fails as expected at task end with the file-not-found
         fallback returning an empty MapSet (78 atoms missing-in-doc), locked
         atom count = 78 recorded in commit message and here.
   - [x] Task 2 acceptance: guide exists, drift test green, 78 H3 entries,
         78 Means/Likely root cause/Operator action/Source occurrences each,
         zero decorated H3 lines, doubled-H2 preamble present, closing
         receipt cross-links incident_playbook.md and cites `mix
         relyra.diagnostic`, D-10 failure-message format verified.
   - [x] Task 3 acceptance: mix.exs format-clean, troubleshooting.md
         registered in extras (line 134) and ci.docs presence guard (line
         158); incident_playbook.md registered in extras (line 135) and
         ci.docs presence guard (line 159); drift-test cmd line (line 160)
         after both presence guards; ci.security byte-unchanged;
         ci_gate_integrity_test.exs byte-unchanged; presence guard + drift
         test invocation green.

## Self-Check: PASSED
