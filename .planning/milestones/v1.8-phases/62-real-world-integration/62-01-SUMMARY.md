---
phase: 62-real-world-integration
plan: 01
subsystem: brand-integration
tags: [branding, ex_doc, opengraph, readme, demo]
requires: [brandbook/assets/logo-mark.svg, brandbook/assets/logo-primary.svg, brandbook/assets/favicon.svg, brandbook/notes/decision-log.md]
provides: [ex_doc-logo, ex_doc-favicon, og-social-card, readme-banner, branded-demo-css]
affects: [mix.exs, README.md, demo/ledger_loop]
key-files:
  created:
    - brandbook/assets/exdoc-logo.png
    - brandbook/assets/exdoc-favicon.png
    - brandbook/assets/social-card.svg
    - brandbook/assets/social-card.png
    - brandbook/assets/readme-banner.svg
  modified:
    - mix.exs
    - README.md
    - demo/ledger_loop/priv/static/assets/css/app.css
metrics:
  tasks: 5
  files_changed: 8
  completed: 2026-06-14
---

# Phase 62 Plan 01: Real-World Integration Summary

Wired the Relyra brand into the real world: ex_doc logo + favicon PNGs (HexDocs),
an OpenGraph social card, a README header banner, and a brand reskin of the
ledger_loop demo — minimal, additive, reversible, with no lib/protocol/version change.

## What was built

| Task | Output | Result |
| --- | --- | --- |
| 1 | `exdoc-logo.png` (120x120), `exdoc-favicon.png` (48x48) | transparent PaletteAlpha PNGs, Ink strokes + Proof Teal dot |
| 2 | `mix.exs` `docs()` `logo:` + `favicon:` keys | `mix docs` exits 0; brand logo copied into doc output |
| 3 | `social-card.svg` + `social-card.png` (1200x630) | Ink panel, Paper lockup, canonical tagline, Mist sub-line |
| 4 | `readme-banner.svg` + README banner line | explicit-color banner above `# Relyra`; badges unchanged |
| 5 | demo `app.css` `:root --ll-*` reskin | 9 values remapped to Canonical Lock Set; structure byte-identical |

## Asset sizes

| Asset | Size | Budget |
| --- | --- | --- |
| `brandbook/assets/exdoc-logo.png` | 897 B | < 16 KB |
| `brandbook/assets/exdoc-favicon.png` | 417 B | — |
| `brandbook/assets/social-card.png` | 14,118 B (~14 KB) | < 90 KB |
| `brandbook/assets/social-card.svg` | 1,790 B | — |
| `brandbook/assets/readme-banner.svg` | 1,445 B | — |

All PNGs were rasterized with ImageMagick (`magick`) from explicit-color temp copies
of the source SVGs (currentColor → `#101827` Ink). The two ex_doc PNGs keep alpha
transparency (PaletteAlpha). The social card is flattened onto the Ink panel and
quantized to a 64-color palette (solid panels + crisp text only), landing at ~14 KB.
pngquant/oxipng were not installed; `magick -strip` + `-colors` handled optimization.

## mix docs result

`mix docs` exits 0. ex_doc copies the configured logo/favicon to `doc/assets/logo.png`
and `doc/assets/favicon.png` — both are **byte-identical** (`cmp` confirmed) to the
committed `brandbook/assets/exdoc-{logo,favicon}.png`. The pre-existing doc warnings
(hidden-module references, the unrelated `C14n`/`C14N` beam-name notice) are not
introduced by this plan and are out of scope.

## Demo compile result

`cd demo/ledger_loop && mix compile` succeeds:
```
==> ledger_loop
Compiling 3 files (.ex)
Generated ledger_loop app
```
The reskin only changes CSS variable values, so the demo (a relyra path-dep app)
compiles unchanged.

## Scope / boundary verification

`git diff` over the 5 commits (`6f3ac67^..HEAD`) touches exactly 8 files:
README.md (+2), mix.exs (+2 keys), demo `app.css` (9 values + 1 comment), and the
4 new brandbook assets + social-card.svg. Guard checks confirmed:
- No `lib/` files and no `*.ex` files changed.
- No real `@version` change (only `source_ref: "v#{@version}"` appears as a context line).
- Brand source stays vector-first; only the 3 spec'd PNGs were added.
- demo `app.css`: every selector below `:root` is byte-identical; only the 9 `--ll-*`
  values + one comment line changed.

## Deviations from Plan

**1. [Rule 1 — verify-path correction] ex_doc renames the logo in its output.**
- **Found during:** Task 2.
- **Issue:** The task's `<automated>` check looked for `doc/assets/exdoc-logo.png` (or
  `doc/exdoc-logo.png`). ex_doc canonically copies a configured `logo:` to
  `doc/assets/logo.png` (and favicon to `doc/assets/favicon.png`), regardless of the
  source filename — so the literal path in the verify never matches.
- **Resolution:** Confirmed `mix docs` exits 0 and that `doc/assets/logo.png` /
  `doc/assets/favicon.png` are byte-identical (`cmp`) to our committed brand PNGs. The
  acceptance criterion ("`mix docs` exits 0 and copies the logo into the doc output")
  is fully met; only the hard-coded output filename in the verify command was stale.
- **Files modified:** none beyond the planned `mix.exs` change.
- **Commit:** d287c92.

No other deviations — the remaining four tasks executed exactly as written.

## Self-Check: PASSED

- `brandbook/assets/exdoc-logo.png` — FOUND (897 B, valid PNG)
- `brandbook/assets/exdoc-favicon.png` — FOUND (417 B, valid PNG)
- `brandbook/assets/social-card.svg` — FOUND (valid XML)
- `brandbook/assets/social-card.png` — FOUND (1200x630, ~14 KB)
- `brandbook/assets/readme-banner.svg` — FOUND (valid XML)
- mix.exs `logo:`/`favicon:` keys — present; `mix docs` exits 0
- README banner line above `# Relyra` — present
- demo `app.css` brand hexes (3454D1 / FCFBF7 / 101827) — present
- Commits 6f3ac67, d287c92, 349d395, baa30d7, 69dff82 — all present in `git log`
