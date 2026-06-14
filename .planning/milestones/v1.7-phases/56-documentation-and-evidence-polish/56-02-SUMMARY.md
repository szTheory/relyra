---
phase: 56-documentation-and-evidence-polish
plan: 02
subsystem: docs
tags: [demo, hexdocs, evaluator-ux, scope-honesty, link-smoke, d02b, d02c, d03, d04, d05]
dependency_graph:
  requires: ["56-01"]
  provides: [guides/demo.md]
  affects: [guides/demo.md, mix.exs, README.md, guides/getting_started.md, test/docs/markdown_link_smoke_test.exs]
tech_stack:
  added: []
  patterns: [thin-pointer ExDoc extra, absolute-GitHub-URL bounce, D-02c relative-link-outside-package CI gate]
key_files:
  created:
    - guides/demo.md
  modified:
    - mix.exs
    - README.md
    - guides/getting_started.md
    - test/docs/markdown_link_smoke_test.exs
decisions:
  - "Demo group in groups_for_extras uses a dedicated Demo: [\"guides/demo.md\"] entry rather than appending to Day-1; keeps the Day-1 spine uncluttered and signals the demo is evaluation-only"
  - "D-02c implemented (not deferred): @package_file_prefixes constant + test that fails relative links outside package.files converts the silent disk-pass/hexdocs-404 gap into a CI failure"
  - "guides/demo.md is a thin pointer only — no boot/reset/creds/routes detail duplicated from the demo README"
metrics:
  duration: "3 min"
  completed: "2026-06-13"
  tasks: 2
  files: 5
---

# Phase 56 Plan 02: Demo ExDoc Wiring and Secondary References Summary

Thin `guides/demo.md` pointer created and registered in ExDoc; secondary demo references added
to README (Day-2 block) and Getting Started (§5 follow-ons); D-02c link-smoke gate implemented.

---

## Tasks Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Author guides/demo.md and register it in ExDoc (D-02, D-02b) | 37c36f7 | guides/demo.md, mix.exs |
| 2 | Add secondary demo references; implement D-02c link-smoke hardening | de972a3 | README.md, guides/getting_started.md, test/docs/markdown_link_smoke_test.exs |

---

## Verification Results

All automated plan checks pass:

```
mix docs                                           → OK (guides/demo.md listed as published extra in Demo group)
grep -q "not part of the Hex package" guides/demo.md  → PASS
grep -q "github.com/szTheory/relyra/blob/main/demo/ledger_loop/README.md" guides/demo.md → PASS
grep -q '"guides/demo.md"' mix.exs                    → PASS
grep -qE '\]\(\.\./demo/' guides/demo.md              → FAILS (no relative demo links, correct)
grep -qiE 'quickstart|starter|scaffold' guides/demo.md → FAILS (no forbidden words, correct)
grep -q '{:relyra, "~> 1.5"}' README.md               → PASS (install snippet preserved)
grep -q '## Start Here' README.md                     → PASS (Start Here router preserved)
grep -q 'guides/demo.md' README.md                    → PASS
grep -q 'demo' guides/getting_started.md              → PASS
mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors → 4 tests, 0 failures
```

D-02c gate: new test "relative links from published extras do not resolve outside package.files"
is green, and would fail if any future published extra added a `../demo/` relative link.

---

## Deviations from Plan

None — plan executed exactly as written. D-02c was implemented (not deferred) because the
implementation is small and the CI gate provides permanent protection against the
disk-passes/hexdocs-404 silent-failure class.

---

## Known Stubs

None. All new documentation content points to verified, real content. No placeholder text
flows to production rendering.

---

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced.
This plan is documentation-only.

T-56-04 mitigated: guides/demo.md uses absolute GitHub URLs only; no relative ../demo/ links;
D-02c CI gate enforces this invariant permanently.

T-56-05 mitigated: README.md install snippet and Start Here router verified untouched;
demo reference placed in Day-2 block only.

T-56-06 mitigated: guides/demo.md is a thin pointer; no credentials, PEM, XML, or raw
secrets reproduced; detail stays in the demo README only.

---

## Self-Check: PASSED
