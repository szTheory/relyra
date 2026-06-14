# Relyra Logo System — Options, Rationale & Usage Rules

**Phase:** v1.8 / 59 — Logo System & Selection Checkpoint
**Status:** Direction **A — Relying Path monogram** selected by the maintainer (2026-06-14). Full lockup set developed.
**Refinement (2026-06-14, post-ship):** the **integrated typemark is now the PRIMARY lockup** — the monogram stands in as the leading "R" of "Relyra" (one fused unit), replacing the mark-beside-word arrangement (which read as a duplicated "R"). The standalone monogram remains the icon. See decision-log.md D-09/D-10.

The selection gallery for all four directions remains at `brandbook/logo-lab.html` (transparent, cage-free comparison at multiple sizes/colorways).

---

## The four directions (and why A won)

| Dir | Concept | Disposition | Why |
| --- | --- | --- | --- |
| **A — Relying Path monogram** | Custom **R**: SP stem + IdP bowl + verified-assertion diagonal leg + Proof-Teal verification node | **SHIPPED** | Strongest brand fit — encodes routing/binding/verification in a single ownable letter. Works as avatar, favicon, docs header, CLI badge. Cleanest mark+wordmark lockup. Reads at 16px. |
| **B — Assertion Frame** | Two open corner brackets holding a Relay-Blue verified check | **Deferred (alt icon)** | Excellent, most "protocol-technical" pure icon; kept as a possible alternate motif but less personality as a wordmark lockup and a check can read as generic "verified" UI. |
| **C — Trust Path** | Open IdP ring → teal seal node → solid bound SP terminus | **Rejected for primary** | Friendly for diagrams, but node-link forms are the most common in the space; weakest distinctiveness as a brand mark. May be reused as an *illustration motif* later, not the logo. |
| **D — Integrated typemark** | "Relyra" wordmark with the motif fused into the R leg and y descender | **Folded into A** | The boldest concept and a direct answer to "no icon-left-of-text" — but the bespoke-letter execution needs more refinement than the milestone warrants. A's `logo-typemark.svg` captures the *integrated* intent (the monogram IS the R of the word) at far lower risk. |

**Net:** A is the system, and (post-ship refinement) its **integrated typemark is the primary lockup** — the mark fused as the leading "R" of "Relyra". This satisfies the user's two asks — a unified mark *and* an integrated typemark that is *the* logo, not an icon beside text — without shipping the rougher bespoke-letter route of direction D.

---

## Asset inventory (`brandbook/assets/`)

| File | Use |
| --- | --- |
| `logo-primary.svg` | **Canonical** horizontal lockup = the **integrated typemark** (the monogram is the "R" of "Relyra", no subtitle). Default everywhere. |
| `logo-typemark.svg` | The same integrated typemark, named alias for editorial/explicit reference. |
| `logo-stacked.svg` | Vertical lockup (mark above the full wordmark) — narrow/centered contexts (cards, mobile headers). |
| `logo-mark.svg` | Mark only (R monogram + teal verification node). Avatars, app icons, favicons ≥24px. |
| `logo-mark-mono.svg` | Single-ink mark (verification node = `currentColor`). One-color print, stamps, embroidery, watermarks. |
| `logo-primary-inverse.svg` | Integrated typemark forced for dark surfaces (Paper ink `#F8FAFC` + Dark Teal node `#61D6C8`), unconditional. |
| `favicon.svg` | Mark simplified for 16–24px (heavier stroke, larger node). Browser tab, Hex icon. |
| `logo-with-tagline.svg` | Integrated typemark + "Enterprise SAML, calmly verified." below. Marketing/footers ONLY — never the primary. |

All assets are transparent (no background rect), SVG-first, and use the Phase 58 Canonical Lock Set hexes. Each file carries explicit Ink/Paper colors with an internal `@media (prefers-color-scheme: dark)` flip (so it self-adapts when used via `<img>` on GitHub/HexDocs); the verification node is Proof Teal `#147D77` (light) / Dark Teal `#61D6C8` (dark). The brand book itself renders the lockups **inline** (`<symbol>`/`<use>`, ink = `currentColor`, node = `var(--rl-verified)`) so they also follow its manual theme toggle. `logo-mark-mono.svg` is the single-`currentColor` exception.

---

## Usage rules

### Clear space
Minimum clear space on all sides = the **cap-height of the monogram's bowl** (≈ the height of the "R"). Nothing — text, UI chrome, other logos — intrudes into that margin.

### Minimum sizes
- Full lockup (`logo-primary` / `logo-stacked`): **120px** wide minimum (digital); 24mm print.
- Mark alone (`logo-mark`): **24px**.
- Favicon (`favicon.svg`): **16px** (its purpose-built floor).
Below 24px, switch from the lockup to `favicon.svg`.

### Mark ↔ logotype spacing
In the primary lockup the monogram **is** the "R" of "Relyra" (integrated typemark): the mark is set to wordmark cap-height (scale 0.76, baseline-aligned) and "elyra" is kerned tight against it so the whole reads as one word. Never re-space, enlarge the gap, or split the monogram from "elyra". (In the vertical `logo-stacked` lockup the monogram sits above the full wordmark — that pairing is intentional and only for narrow/centered contexts.)

### Approved colorways
1. **Ink on Paper** (default light): `currentColor` = Ink `#101827`, node = Proof Teal `#147D77`.
2. **Paper on dark** (inverse): `currentColor` = Paper `#FCFBF7`, node = Dark Teal `#61D6C8` (use `logo-primary-inverse.svg`).
3. **Mono Ink** (single color): everything Ink, no accent (`logo-mark-mono.svg` / set `currentColor` and recolor the node).
4. **Relay Blue lockup**: `currentColor` = Relay Blue `#3454D1` on Paper, for occasional brand-blue emphasis.
On photos/tints, use the mono or inverse mark on a sufficiently contrasting area only.

### Misuse — do NOT
- ❌ Put the mark in a **rectangular box / rounded-rect cage / circle badge**. The mark is transparent and floats free. (Hard rule.)
- ❌ Add a **subtitle/tagline to the primary** lockup — use `logo-with-tagline.svg` when a tagline is genuinely needed.
- ❌ **Separate** the mark from the wordmark, or change the mark↔word gap.
- ❌ **Stretch, skew, rotate,** or re-proportion the mark or wordmark.
- ❌ Add **drop shadows, glows, gradients, bevels, or 3D**.
- ❌ Recolor the mark into **off-brand hues**, or place it on a **low-contrast** background.
- ❌ Re-typeset "Relyra" in a different font, or alter the casing (never reLyra / ReLyra / RELYRA / RelyRa).
- ❌ Introduce **forbidden imagery** near or in the mark (lyre/music/constellation, shield, padlock, key, fingerprint, flame, bird, chain links, blockchain mesh).

---

*Logo system locked 2026-06-14 (Phase 59). Palette + type per `brandbook/notes/decision-log.md` Canonical Lock Set.*
