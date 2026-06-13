---
phase: 56-documentation-and-evidence-polish
plan: 03
subsystem: docs
tags: [docs, drift-gate, ci, hollow-gate, scripts-demo, evaluator-ux, DOCS-02]
dependency_graph:
  requires: ["56-01"]
  provides: [test/docs/demo_guide_drift_test.exs]
  affects: [mix.exs, test/docs/demo_guide_drift_test.exs]
tech_stack:
  added: []
  patterns: [bidirectional-MapSet-difference drift gate, runtime-extraction (D-05), bash-fence-scoped scan, Phase-30 hollow-gate cmd-mix-test convention]
key_files:
  created:
    - test/docs/demo_guide_drift_test.exs
  modified:
    - mix.exs
decisions:
  - "Runtime extraction via case-arm regex (no hardcoded subcommand list) is the canonical D-05 pattern — renaming an arm in scripts/demo automatically changes the canonical set the test sees"
  - "Drift test wired to ci.docs (repo-root cwd) not ci.demo_app (--cd demo/ledger_loop) because scripts/demo is only reachable from the repo root"
  - "README presence guard (cmd test -f) placed before the drift test so a missing README surfaces as a clean OS-level failure before the Elixir test even runs"
metrics:
  duration: "5 min"
  completed: "2026-06-13"
  tasks: 2
  files: 2
---

# Phase 56 Plan 03: Demo Guide Drift Gate (D-10 / D-11) Summary

Bidirectional `scripts/demo` subcommand drift gate created in `test/docs/demo_guide_drift_test.exs`,
wired into `ci.docs` behind a README presence guard as its own dedicated `cmd mix test` process line.

---

## Tasks Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Write the bidirectional scripts/demo subcommand drift gate (D-10) | cba0fac | test/docs/demo_guide_drift_test.exs |
| 2 | Wire the drift test into the ci.docs alias with a README presence guard (D-11) | d896869 | mix.exs |

---

## Verification Results

All automated plan checks pass:

```
mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors
  → 1 test, 0 failures

grep -q 'scripts/demo' test/docs/demo_guide_drift_test.exs              → PASS
! grep -qE 'doctor.*up.*reset.*test.*urls.*down' test/docs/demo_guide_drift_test.exs → PASS (no hardcoded list)
grep -q '```bash' test/docs/demo_guide_drift_test.exs                   → PASS (bash fence scoping present)
grep -q ':enoent' test/docs/demo_guide_drift_test.exs                   → PASS ({:error, :enoent} handled)
grep -q 'MapSet.difference' test/docs/demo_guide_drift_test.exs         → PASS (bidirectional present)

grep -q 'cmd mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors' mix.exs → PASS
grep -q 'cmd test -f demo/ledger_loop/README.md' mix.exs                → PASS
! grep (ci.demo_app section) contains demo_guide_drift_test               → PASS (not in ci.demo_app)

mix ci.docs → exits 0, all tests pass
```

Canonical subcommand set extracted at runtime from `scripts/demo` case arms:
`{doctor, up, reset, test, urls, down}` — none hardcoded in the test.

All six subcommands found in bash fence blocks of `demo/ledger_loop/README.md` — gate is green.

Phase 30 hollow-gate invariant: drift test runs as its own `cmd mix test` process line. Confirmed by inspection of mix.exs ci.docs alias order.

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Known Stubs

None.

---

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced.

T-56-07 (Tampering — hollow gate) mitigated: drift test is its own `cmd mix test` process line; `mix ci.docs` exits 0.

T-56-08 (Repudiation — silent drift) mitigated: bidirectional set-diff with runtime extraction means a renamed subcommand or stale doc command fails CI immediately.

T-56-09 (Spoofing — wrong lane) mitigated: test wired to ci.docs (repo-root cwd); presence guard before drift test; not present in ci.demo_app.

---

## Self-Check: PASSED

```
[ -f test/docs/demo_guide_drift_test.exs ] → FOUND
git log --oneline | grep cba0fac → FOUND: cba0fac test(56-03): add bidirectional scripts/demo subcommand drift gate (D-10)
git log --oneline | grep d896869 → FOUND: d896869 chore(56-03): wire demo guide drift test into ci.docs with README presence guard (D-11)
```
