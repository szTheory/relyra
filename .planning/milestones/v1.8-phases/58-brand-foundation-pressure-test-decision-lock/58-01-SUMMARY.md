---
phase: 58-brand-foundation-pressure-test-decision-lock
plan: 01
subsystem: brand-foundation
tags: [brand, wcag, accessibility, design-system, decision-lock]
requires: [prompts/relyra-brand-book.md]
provides:
  - brandbook/notes/contrast.exs
  - brandbook/notes/accessibility-checks.md
  - brandbook/notes/decision-log.md
  - brandbook/notes/research.md
affects: [phase-59-logo, phase-60-tokens, phase-61-html-brand-book]
tech-stack:
  added: []
  patterns: [pure-stdlib-elixir-script, wcag-2.2-contrast-gate, four-lens-brand-audit]
key-files:
  created:
    - brandbook/notes/contrast.exs
    - brandbook/notes/accessibility-checks.md
    - brandbook/notes/decision-log.md
    - brandbook/notes/research.md
  modified: []
decisions:
  - "Certificate Gold #C08A2B (2.93 fail) remediated to text-capable #9A6B1C (4.51)"
  - "Dark Border #334155 (1.71-1.83 fail) -> #64748B (3.73-3.98); resolves table-vs-CSS contradiction"
  - "Soft Line #D8E0EA locked decorative-only; interactive boundaries use Accessible Border #7E8A9A"
  - "Info #3454D1 collision with Relay Blue SHIPPED, constrained to icon+label affordance (never color alone)"
  - "Canonical tagline locked: Enterprise SAML, calmly verified.; type stack one family per role"
metrics:
  duration: ~5 min
  completed: 2026-06-14
requirements: [BRAND-01, BRAND-02, BRAND-03]
---

# Phase 58 Plan 01: Brand Foundation Pressure-Test & Decision Lock Summary

Pressure-tested the decision-complete Relyra brand book (`prompts/relyra-brand-book.md` v0.1)
through four senior lenses and locked its palette, type scale, and voice into re-runnable,
WCAG-verified decision documents under `brandbook/notes/` — the single source of truth phases
59-61 consume verbatim. Ships no visual assets.

## What was built

- **`brandbook/notes/contrast.exs`** — pure Elixir stdlib (`:math`, `String`, `Enum`; no
  `Mix.install`, no deps) WCAG 2.2 calculator. `srgb_to_lin` uses the `0.04045` linearization
  threshold; `luminance/1` accepts `#RRGGBB` or `RRGGBB`; `check/3` returns
  `{display_ratio_2dp, passes?}` with the verdict on the UNROUNDED ratio (W3C no-rounding rule).
  Drives 34 realistic light + dark pairs (body/secondary text, links/primary action, all four
  semantic colors, focus rings, interactive border, decorative divider, disabled, both dark
  surfaces), prints a Markdown table, and `System.halt(1)` if any must-pass pair is below its
  required ratio. Retains the unremediated FAIL rows (#C08A2B 2.93, #334155 1.83/1.71, Soft Line
  1.29) as non-must-pass witnesses and the remediated PASS rows (#9A6B1C 4.51, #64748B 3.98/3.73),
  so the committed script exits 0.
- **`brandbook/notes/accessibility-checks.md`** — the table generated verbatim from the script's
  stdout (no hand-typed ratios), split into Light-mode and Dark-mode sections, with the WCAG
  thresholds, the 0.04045 constant, the no-rounding rule, a "Confirmed failures and remediations"
  subsection, and a "Passes-but-fragile" subsection.
- **`brandbook/notes/decision-log.md`** — D-01..D-08 as Decision/Options/Tradeoffs/note/
  Disposition/Confidence blocks (indented, no triple-backtick fences), ending in a single
  Canonical Lock Set.
- **`brandbook/notes/research.md`** — condensed cited synthesis (WCAG 2.2 1.4.3/1.4.11, Radix
  5-tier, Primer 3-layer, GitHub monochrome-first, four-lens method, APCA-is-not-the-gate) with
  the Primary/Secondary/Tertiary Sources list preserved.

## Final locked set (highlights)

- **Gold:** #C08A2B → **#9A6B1C** (text-capable, 4.51:1).
- **Dark border:** #334155 → **#64748B** (3.73-3.98:1) — contradiction + contrast fixed together.
- **Info = Relay Blue #3454D1 collision SHIPPED** (not nudged), constrained to icon + label affordance.
- **Soft Line #D8E0EA** decorative-only; **Accessible Border #7E8A9A** for controls.
- **Type:** IBM Plex Sans Condensed (display) / Atkinson Hyperlegible (body+UI) / JetBrains Mono (code).
- **Tagline:** "Enterprise SAML, calmly verified." (other five demoted to non-canonical alternates).

## Deviations from Plan

None — plan executed exactly as written. The two open research questions (gold text-capable vs
non-text-only; Info collision ship vs nudge) were resolved per the research default recommendations
(#9A6B1C text-capable; ship the collision with affordance) and recorded as D-01 and D-04.

## Verify results

- Task 1: `elixir brandbook/notes/contrast.exs` → EXIT=0; ratios reproduce research exactly
  (Ink/Paper 17.16, Gold/Paper 2.93, #9A6B1C 4.51, #334155 1.83/1.71 fail, #64748B 3.98/3.73 pass).
- Task 2: row-diff of script stdout vs accessibility-checks.md → OK (no hand-typed/missing rows);
  research.md contains WCAG + Radix/Primer.
- Task 3: Canonical Lock Set + #9A6B1C + #64748B + Disposition lines present, no triple-backtick
  fences → OK; D-01..D-08 all present.

## Scope

Only `brandbook/notes/` was created/modified across all three commits (verified via
`git diff --name-only`). No `lib/`, demo, README, mix.exs, or token/HTML/SVG file touched.
Pre-existing `.planning/` working-tree changes (a phase-57/57.1 milestone-archive move) predate
this plan and were left untouched per the scope boundary.

## Commits

- 32be465 feat(58): add committable WCAG 2.2 contrast script
- 9b7d227 docs(58): generate accessibility-checks.md + cited research synthesis
- 3276704 docs(58): write decision-log with D-01..D-08 + Canonical Lock Set

## Self-Check: PASSED

- brandbook/notes/contrast.exs — FOUND
- brandbook/notes/accessibility-checks.md — FOUND
- brandbook/notes/decision-log.md — FOUND
- brandbook/notes/research.md — FOUND
- Commits 32be465, 9b7d227, 3276704 — FOUND
