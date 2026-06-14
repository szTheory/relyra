# Relyra Brand — Research Synthesis

**Phase:** 58 — Brand Foundation Pressure-Test & Decision Lock
**Date:** 2026-06-14
**Domain:** Brand/design-system auditing, WCAG 2.2 color contrast, OSS devtool brand credibility
**Confidence:** HIGH (WCAG thresholds + computed ratios verified on-machine; design-system rubrics cited from official docs)

This is the cited synthesis behind the pressure-test. It exists so phases 59-61 (logo, tokens,
HTML brand book) can cite the same standards instead of re-deriving them. The decisions it
informs live in `decision-log.md`; the computed contrast numbers live in `accessibility-checks.md`
(generated from `contrast.exs`).

## The hard gate: WCAG 2.2 contrast

The single non-negotiable gate is WCAG 2.2 contrast. Everything else (token sprawl, contradictions,
OSS credibility) is a structured audit that produces ship/reject/defer dispositions; contrast is math.

- **SC 1.4.3 Contrast (Minimum):** normal text **4.5:1**, large text (≥ 18pt regular / ≥ 14pt bold) **3:1**.
  Source: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- **SC 1.4.11 Non-text Contrast:** UI components, control boundaries (when the boundary is the sole
  cue a control exists), and focus indicators **3:1**.
  Source: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- **No-rounding rule (verbatim from W3C):** "the computed values should not be rounded
  (e.g. 2.999:1 would not meet the 3:1 threshold)." The contrast script rounds for display only;
  the verdict compares the unrounded ratio.
- **Boundary exemption (1.4.11):** a decorative divider is exempt; the same hex used as the only cue
  a form field exists must hit 3:1. This is the crux of the Soft Line vs. Accessible Border decision.
- **Linearization constant:** W3C updated `0.03928` → `0.04045` in May 2021 "with no practical
  effect." Re-running every borderline pair with both constants flips no verdict for this palette;
  `0.04045` is used in `contrast.exs` for correctness.
- **APCA is NOT the gate.** APCA is a candidate for WCAG 3, which is "years away, perhaps 2030 at
  soonest," with no confirmation it will ship. WCAG 2.x remains the compliance benchmark; treat APCA
  as informational context only.
  Sources: https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html and
  https://yatil.net/blog/wcag-3-is-not-ready-yet

## Design-system token models (anti-sprawl vocabulary)

Every subjective brand-audit judgment (sprawl, completeness, parity, credibility) has an objective
external rubric. We cite three.

### Radix Colors — five-tier functional model
Radix proves every color need maps to one of five functional tiers: app/subtle background,
component background (normal/hover/pressed), borders (subtle / interactive / focus), solid background,
and text (low/high contrast). A complete system has exactly one token per tier per mode — no gaps, no
duplicates. Radix's "mutable alias" pattern is the dark-mode discipline: the same semantic token
resolves to a different hex per mode while keeping identical semantics.
Source: https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale

Applied to Relyra: the palette covers all five tiers, but the book has no hover/pressed surface
tokens (a gap routed to the token phase) and three border roles where Soft Line fails as the
interactive one.

### GitHub Primer — three-layer token hierarchy
Primer's anti-sprawl discipline is three layers: (1) base/primitive tokens map to raw hex and are
never used directly in production; (2) functional tokens (`fgColor-*`, `bgColor-*`, `borderColor-*`)
reference base tokens and respect mode; (3) component/pattern tokens (`focus-outlineColor`) are used
sparingly. Primer keeps `accent` distinct from `done`/`open` so an informational state never reads as
a clickable action.
Source: https://primer.style/foundations/color/overview

Applied to Relyra: treat the named colors (Ink, Paper, Relay Blue) as **primitives**, then define a
thin semantic layer (`text-primary` → Ink, `action` → Relay Blue, `border-interactive` → Accessible
Border) so phase 60 has clean inputs. The `Info #3454D1 == Relay Blue #3454D1` collision is the
Primer-flagged ambiguity — an info callout looks identical to a clickable action.

## OSS devtool brand credibility (transferable lessons; this phase ships no asset)

GitHub's own brand guidance is the proven default for what reads credible vs. generic for a
library on GitHub/HexDocs.
Source: https://brand.github.com/foundations/logo

- **Monochrome-first.** GitHub permits its mark only in white/black/grey/green, "no graphic effects
  like shadows or gradients." Relyra's logo colorway list (Ink-on-Paper, Paper-on-Ink, one-color
  mono for README/registries) already matches this; lock it.
- **No clipart / no mascot.** GitHub: "avoid substituting illustrations or mascots." Relyra's
  forbidden-imagery list (no shield/lock/key/flame/bird/lyre) is the same instinct and is already
  locked; the red-team lens just verifies no section reintroduces them.
- **Small-size legibility is the gate, not hero art.** Favicon at 16px, Hex package icon, GitHub org
  avatar. The book's "icon only: 24px minimum, 16px favicon with simplified detail" is correct
  restraint — and a constraint the logo phase (59) inherits, because the mark must survive ex_doc's
  small header slot in both light and dark doc themes.

## The four-lens pressure-test method

The audit runs the book once through each of four named lenses; findings converge into
`decision-log.md` as Decision/Options/Tradeoffs/note/Disposition/Confidence blocks.

1. **Graphic-design director** — distinctiveness, genericness, whether the system reads as a
   maintained security library vs. a SaaS billboard.
2. **Design-system lead** — token sprawl, functional-tier completeness, semantic collisions,
   light/dark parity, implementation risk ("will this survive contact with real CSS?").
3. **Accessibility specialist** — owns the contrast script and every pass/fail; proposes remediation
   hexes; verifies focus-ring visibility in both modes; checks "never color alone."
4. **OSS-credibility red-team** — hunts contradictions and self-violations (the `#334155`/`#64748B`
   split, multiple taglines vs. one primary, any forbidden-claim/imagery leakage, casing drift).

**Disposition semantics:** ship = lock as-is or with the recorded remediation; reject = the book's
value/wording is wrong, replace it; defer = out of scope for v1.8 (e.g., 19-icon library, motion
assets), route to BRAND-F01/F02.

## Don't hand-roll

- **Contrast ratios:** never eyeball swatches — human perception overstates contrast for mid-tones.
  Use the committed Elixir WCAG script; the spec is exact math.
- **Color-role taxonomy:** don't invent a bespoke tier system — use Radix 5-tier + Primer 3-layer.
- **Logo credibility rules:** don't re-derive "what looks pro" — GitHub's monochrome-first/no-effects
  is the proven OSS default.
- **"Is APCA the gate?":** no — WCAG 2.x has legal standing; APCA does not until ~2030.

## Sources

### Primary (HIGH confidence)
- W3C WCAG 2.2 — Understanding SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WCAG 2.2 — Understanding SC 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- Computed contrast ratios — Elixir `brandbook/notes/contrast.exs`, ran on this machine 2026-06-14 (both `0.03928` and `0.04045` thresholds; no verdict change)
- Radix Colors — scale composition: https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale
- GitHub Primer — color overview: https://primer.style/foundations/color/overview
- GitHub Brand Toolkit — logo: https://brand.github.com/foundations/logo

### Secondary (MEDIUM confidence)
- Adrian Roselli, "WCAG3 Contrast as of April 2026": https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html
- Eric Eggert, "WCAG 3 is not ready yet": https://yatil.net/blog/wcag-3-is-not-ready-yet
- jcklpe/open-source-branding-toolkit: https://github.com/jcklpe/open-source-branding-toolkit

### Tertiary (LOW confidence)
- IBM Plex / Atkinson Hyperlegible / JetBrains Mono open-font licensing claims (brand book §9) —
  `[ASSUMED]`-grade until the token/integration phase verifies SIL OFL terms before any CDN load; not
  gating for this audit.

**Valid until:** ~2026-12-14. WCAG 2.2 and the design-system docs are stable; APCA/WCAG 3 status is
worth re-checking in six months but will not become the gate before this milestone ships.
