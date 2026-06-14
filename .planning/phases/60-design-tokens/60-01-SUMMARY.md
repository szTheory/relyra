---
phase: 60-design-tokens
plan: 01
subsystem: brandbook
tags: [design-tokens, css-variables, tailwind, dark-mode, wcag]
requires: ["Phase 58 Canonical Lock Set (decision-log.md, accessibility-checks.md)"]
provides:
  - "brandbook/tokens/tokens.json — primitive + semantic design tokens (light/dark)"
  - "brandbook/tokens/tokens.css — --rl-* CSS custom properties, light default + dark + reduced-motion"
  - "brandbook/tokens/tailwind.example.js — theme.extend mapping for Phoenix consumers"
affects: ["Phase 61 (HTML brand book) will lift these tokens verbatim"]
tech-stack:
  added: []
  patterns: ["CSS custom properties for theming", "var(--rl-*) indirection so Tailwind inherits dark mode from CSS"]
key-files:
  created:
    - brandbook/tokens/tokens.json
    - brandbook/tokens/tokens.css
    - brandbook/tokens/tailwind.example.js
  modified: []
decisions:
  - "Dark mode in CSS is provided twice: prefers-color-scheme (auto) and [data-theme=\"dark\"] (manual hook wins)."
  - "Tailwind semantic colors reference var(--rl-*) so consumers inherit light/dark parity without re-deriving hexes."
  - "info == action (Relay Blue) shipped per D-04; disambiguation is by icon+label affordance, documented in every file."
metrics:
  duration: "~12 min"
  completed: "2026-06-14"
  tasks: 3
  files: 3
---

# Phase 60 Plan 01: Design Tokens Summary

Published the Relyra design tokens as three files under `brandbook/tokens/`, derived verbatim from the Phase 58 Canonical Lock Set with WCAG-clean values and full light/dark parity.

## Files Created

| File | Lines | Provides |
| --- | --- | --- |
| `brandbook/tokens/tokens.json` | 176 | Primitive (light/dark) + semantic (light/dark) colors, typography, space, radius, borderWidth, boxShadow (light/dark), motion, focusRing. `$meta` records source + the info==action note. |
| `brandbook/tokens/tokens.css` | 181 | `--rl-*` custom properties; light defaults in `:root`, dark via `prefers-color-scheme` and `[data-theme="dark"]`, plus a `prefers-reduced-motion` block. |
| `brandbook/tokens/tailwind.example.js` | 147 | `module.exports` `theme.extend` mapping; semantic colors point at `var(--rl-*)`, fixed primitives + fontFamily/fontSize/spacing/borderRadius/borderWidth/boxShadow/transition/outline. |

## Token Groups Covered

- **Color** — primitive light (11 brand roles + 3 status bases) and dark (12 roles); semantic light + dark for bg, surface, surface-subtle, text, text-muted, border, divider, action, action-emphasis, link, verified, focus-ring, caution, success, warning, error, info.
- **Typography** — three families (display / body / code), 9-step size scale with line-heights and weights (weights constrained to the 400/500/600/700 cuts Atkinson/Plex ship; h2/code rounded to nearest).
- **Space** — raw px scale (2…128, ×4 base).
- **Radius** — sm 8 / md 12 / lg 16 / full 9999.
- **Border width** — hairline 1px / regular 2px.
- **Shadow** — sm/md for light, alpha-bumped sm/md for dark.
- **Motion** — durations fast/base/slow, standard ease-out easing, reduced-motion collapse.
- **Focus ring** — color (keyline-violet light / dark-violet dark via the semantic var), width 2px, offset 2px, solid.

## Dark-Mode Strategy

Dark values live in CSS, not duplicated in Tailwind. `tokens.css` overrides the semantic `--rl-*` vars under two selectors: `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }` (automatic, with a light opt-out) and `[data-theme="dark"] { … }` (manual hook that always wins). Because `tailwind.example.js` maps semantic colors to `var(--rl-*)`, a Phoenix consumer importing `tokens.css` gets dark mode for free with either `darkMode: 'media'` or a `[data-theme="dark"]` toggle — no re-derivation of hexes.

## Lock-Set Accuracy

Cross-checked every value against the Canonical Lock Set in `decision-log.md` and the verdicts in `accessibility-checks.md`. Remediated values present (`#9A6B1C` gold, `#64748B` dark border); the contrast-failing originals (`#C08A2B`, `#334155`) are absent from all three files (grep-verified empty). No token sprawl: one entry per role; Mist≈Paper near-luminance is intentional (D-08), info==action collision shipped per D-04 with affordance note.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `$meta` accessibility note tripped the Task 1 forbidden-hex grep**
- **Found during:** Task 1 verification.
- **Issue:** The plan's `<automated>` verify does a raw substring search of the whole JSON for `#C08A2B`. My initial `$meta.accessibility` string described the remediation by naming the old failing hex literally, which is functionally absent from the palette but still matched the substring guard.
- **Fix:** Rephrased the meta note to describe the remediation without printing the failing hex literals. No palette value changed.
- **Files modified:** `brandbook/tokens/tokens.json`
- **Commit:** `484fd36` (the corrected file is what was committed).

## Known Stubs

None. All three files contain real, lock-set-accurate values and pass their automated verify.

## Self-Check: PASSED

- FOUND: brandbook/tokens/tokens.json
- FOUND: brandbook/tokens/tokens.css
- FOUND: brandbook/tokens/tailwind.example.js
- FOUND commit 484fd36 (tokens.json)
- FOUND commit 0c8b2d3 (tokens.css)
- FOUND commit 95f3e03 (tailwind.example.js)
