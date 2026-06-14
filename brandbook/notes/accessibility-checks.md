# Relyra Brand — WCAG 2.2 Accessibility Checks

**Phase:** 58 — Brand Foundation Pressure-Test & Decision Lock
**Generated:** 2026-06-14
**Source of truth:** `brandbook/notes/contrast.exs` (run `elixir brandbook/notes/contrast.exs`)

Every row in the tables below is produced verbatim by the contrast script — the ratios are
computed from WCAG 2.2 relative-luminance math, never hand-typed. Re-running the script
regenerates this table; if a future palette edit breaks contrast, the script exits 1.

## Method and thresholds

- **Standard:** WCAG 2.2 (W3C Recommendation, Oct 2023). The compliance gate; APCA/WCAG 3 is not yet normative.
- **SC 1.4.3 Contrast (Minimum):** normal text **4.5:1**; large text (≥ 18pt regular / ≥ 14pt bold) **3:1**.
- **SC 1.4.11 Non-text Contrast:** UI components, control boundaries (when the boundary is the sole cue), and focus indicators **3:1**.
- **Linearization constant:** `0.04045` (W3C updated `0.03928` → `0.04045` in May 2021; no verdict flips for this palette).
- **Relative luminance:** `L = 0.2126·R + 0.7152·G + 0.0722·B` over linearized channels.
- **Contrast ratio:** `(L_lighter + 0.05) / (L_darker + 0.05)`.
- **No-rounding rule:** the verdict compares the UNROUNDED ratio (a 2.999:1 result does NOT meet 3:1); the displayed `Ratio` column rounds to 2 dp for presentation only.

The `Required` column reflects the pair's intended use (4.50 for text, 3.00 for large/non-text/UI).
The `Verdict` column is the script's pass/fail on the unrounded ratio.

## Light-mode pairs

| Pair (fg on bg) | Mode | Use | Ratio | Required | Verdict | Remediation / note |
| --- | --- | --- | ---: | ---: | --- | --- |
| #101827 on #FCFBF7 | light | Body text (Ink on Paper) | 17.16 | 4.50 | PASS | - |
| #263245 on #FCFBF7 | light | Secondary text (Graphite on Paper) | 12.48 | 4.50 | PASS | - |
| #101827 on #EEF2F6 | light | Body text on Mist panel | 15.79 | 4.50 | PASS | - |
| #3454D1 on #FCFBF7 | light | Link / primary action text (Relay Blue on Paper) | 6.08 | 4.50 | PASS | - |
| #FCFBF7 on #3454D1 | light | Primary button text (Paper on Relay Blue) | 6.08 | 4.50 | PASS | - |
| #FCFBF7 on #1D2E82 | light | Hero / emphasis text (Paper on Deep Relay) | 11.49 | 4.50 | PASS | - |
| #027A48 on #FCFBF7 | light | Success text (on Paper) | 5.23 | 4.50 | PASS | - |
| #B45309 on #FCFBF7 | light | Warning text (on Paper) | 4.85 | 4.50 | PASS | thin margin (4.85) |
| #B42318 on #FCFBF7 | light | Error text (on Paper) | 6.35 | 4.50 | PASS | - |
| #3454D1 on #FCFBF7 | light | Info text (on Paper) — byte-identical to Relay Blue | 6.08 | 4.50 | PASS | Info==Relay Blue collision (D-04) |
| #147D77 on #FCFBF7 | light | Verified / Proof Teal text (on Paper) | 4.80 | 4.50 | PASS | thin margin (4.80) |
| #6D5DF2 on #FCFBF7 | light | Focus ring (Keyline Violet on Paper, non-text) | 4.51 | 3.00 | PASS | thin margin (4.51) |
| #7E8A9A on #FCFBF7 | light | Interactive border (Accessible Border on Paper, non-text) | 3.39 | 3.00 | PASS | - |
| #7E8A9A on #EEF2F6 | light | Interactive border (Accessible Border on Mist, non-text) | 3.12 | 3.00 | PASS | thin margin (3.12) |
| #263245 on #EEF2F6 | light | Disabled text (Graphite on Mist surface) | 11.49 | 4.50 | PASS | - |
| #D8E0EA on #FCFBF7 | light | Soft Line divider on Paper (decorative-only, exempt) | 1.29 | 3.00 | FAIL | structural: decorative-only; route controls to #7E8A9A (D-03) |
| #C08A2B on #FCFBF7 | light | Certificate Gold accent on Paper (non-text) — UNREMEDIATED | 2.93 | 3.00 | FAIL | FAIL 2.93 < 3:1 -> remediate to #9A6B1C (D-01) |
| #9A6B1C on #FCFBF7 | light | Certificate Gold REMEDIATED on Paper (text-capable) | 4.51 | 4.50 | PASS | remediated from #C08A2B |

## Dark-mode pairs

| Pair (fg on bg) | Mode | Use | Ratio | Required | Verdict | Remediation / note |
| --- | --- | --- | ---: | ---: | --- | --- |
| #F8FAFC on #0B1020 | dark | Body text (Dark Text on Dark Background) | 18.10 | 4.50 | PASS | - |
| #F8FAFC on #111827 | dark | Body text (Dark Text on Dark Surface) | 16.96 | 4.50 | PASS | - |
| #CBD5E1 on #0B1020 | dark | Secondary text (Dark Muted on Dark Background) | 12.75 | 4.50 | PASS | - |
| #CBD5E1 on #111827 | dark | Secondary text (Dark Muted on Dark Surface) | 11.95 | 4.50 | PASS | - |
| #8CA2FF on #0B1020 | dark | Link / action (Dark Blue on Dark Background) | 7.87 | 4.50 | PASS | - |
| #8CA2FF on #111827 | dark | Link / action (Dark Blue on Dark Surface) | 7.37 | 4.50 | PASS | - |
| #61D6C8 on #0B1020 | dark | Verified accent (Dark Teal on Dark Background) | 10.78 | 4.50 | PASS | - |
| #FBBF24 on #0B1020 | dark | Warning (Dark Amber on Dark Background) | 11.34 | 4.50 | PASS | - |
| #FDA29B on #0B1020 | dark | Error (Dark Red on Dark Background) | 9.75 | 4.50 | PASS | - |
| #86EFAC on #0B1020 | dark | Success (Dark Green on Dark Background) | 13.48 | 4.50 | PASS | - |
| #A99BFF on #0B1020 | dark | Focus ring (Dark Violet on Dark Background, non-text) | 7.95 | 3.00 | PASS | - |
| #A99BFF on #111827 | dark | Focus ring (Dark Violet on Dark Surface, non-text) | 7.45 | 3.00 | PASS | - |
| #334155 on #0B1020 | dark | Dark Border on Dark Background (non-text) — UNREMEDIATED (palette table) | 1.83 | 3.00 | FAIL | FAIL 1.83 < 3:1; contradicts CSS --relyra-border:#64748B -> adopt #64748B (D-02) |
| #334155 on #111827 | dark | Dark Border on Dark Surface (non-text) — UNREMEDIATED (palette table) | 1.71 | 3.00 | FAIL | FAIL 1.71 < 3:1 -> adopt #64748B (D-02) |
| #64748B on #0B1020 | dark | Dark Border REMEDIATED on Dark Background (non-text) | 3.98 | 3.00 | PASS | from book CSS --relyra-border:#64748B |
| #64748B on #111827 | dark | Dark Border REMEDIATED on Dark Surface (non-text) | 3.73 | 3.00 | PASS | from book CSS --relyra-border:#64748B |

## Confirmed failures and remediations

The three FAIL rows above are the load-bearing findings. Each is resolved in `decision-log.md`.

- **Certificate Gold `#C08A2B` on Paper — 2.93:1 (FAIL non-text 3:1).** Fails even as a
  non-text caution accent — invisible to low-vision users, which is ironic for a
  "certificate expiring" warning. Remediate to text-capable **`#9A6B1C` (4.51:1)** — keeps the
  gold hue, darkens the value, and clears the stricter 4.5:1 text gate. Alternate (non-text-only,
  if the brighter value is preferred for large/icon use): `#A8741F` (3.91:1 non-text). Default:
  `#9A6B1C`.
- **Dark Border `#334155` — 1.83:1 on `#0B1020`, 1.71:1 on `#111827` (FAIL non-text 3:1).**
  This is a contradiction AND a contrast failure fixed together: the book's dark **palette
  table** says `#334155`, but the book's own dark **CSS block** sets `--relyra-border: #64748B`.
  Resolve to **`#64748B`** (3.98:1 / 3.73:1 — both PASS) everywhere and delete `#334155` from the
  border role.
- **Soft Line `#D8E0EA` on Paper — 1.29:1 (FAIL as a control boundary).** No darker tint of this
  hue reaches 3:1 on Paper (`#B9C5D6`/`#A6B4C8`/`#97A7BD` top out around 2.36). The resolution is
  **structural, not a recolor**: Soft Line stays a decorative divider only (WCAG 1.4.11 exempts
  dividers that are not the sole cue a control exists). Every real interactive boundary routes to
  Accessible Border `#7E8A9A` (3.39 on Paper / 3.12 on Mist, both PASS).

## Passes-but-fragile (thin margin, no remediation required)

These clear their threshold but sit close enough that future surface-darkening could break them.
Flagged do-not-darken-surfaces; locked as-is.

- **Proof Teal `#147D77` on Paper — 4.80:1** (text gate 4.5). Margin +0.30.
- **Keyline Violet `#6D5DF2` on Paper — 4.51:1** (focus-ring non-text gate 3.0; also clears text 4.5). Margin +0.01 against text.
- **Warning `#B45309` on Paper — 4.85:1** (text gate 4.5). Margin +0.35.
- **Accessible Border `#7E8A9A` on Mist `#EEF2F6` — 3.12:1** (non-text gate 3.0). Margin +0.12 — the tightest in the system.

## Verdict summary

After remediation, every realistic intended-use pair (light + dark, text + non-text) meets its
WCAG 2.2 requirement. The two unremediated FAIL rows (`#C08A2B`, `#334155`) and the structural
Soft Line FAIL are retained in the table as witnesses; the script marks them non-must-pass so it
still exits 0 while documenting the math. The canonical, contrast-clean values are locked in
`brandbook/notes/decision-log.md` (Canonical Lock Set).
