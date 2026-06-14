# Phase 59: Logo System & Selection Checkpoint - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning
**Source:** Milestone v1.8 scope + Phase 58 Canonical Lock Set

<domain>
## Phase Boundary

Render **all four logo directions** as real, transparent, cage-free SVGs; present them in a `brandbook/logo-lab.html` gallery; **the maintainer picks one (interactive checkpoint)**; develop the winner into the full lockup set with documented usage rules.

This phase has TWO beats with a HARD GATE between them:
- **Beat A (autonomous):** four directions × {mark, horizontal lockup} as SVGs under `brandbook/assets/logo-lab/`, plus `brandbook/logo-lab.html` showing each at multiple sizes, in color / mono / inverse / on-tint. STOP here.
- **CHECKPOINT:** maintainer opens `logo-lab.html` and selects ONE direction.
- **Beat B (after selection):** promote the winner to `brandbook/assets/` as the full set (primary horizontal no-subtitle, stacked, mark-only, mono, inverse, favicon 16/24, optional separate tagline lockup, integrated typemark variant) + write `brandbook/notes/logo-options.md` (rationale + usage rules).

Out of scope: tokens.json/css (phase 60), index.html brand book (phase 61), any change outside `brandbook/`.
</domain>

<decisions>
## Implementation Decisions

### Locked (hard constraints — from the user, do not violate)
- **NO rectangular background cages.** Marks ship transparent. The gallery may preview a mark ON a tinted surface, but the SVG files carry no background `<rect>` behind the mark.
- **Logotype sits tight to the mark** — visually unified, never "a clipart icon to the left of plain text." Target mark↔wordmark gap ≈ 0.5× cap-height.
- **Primary lockup has NO subtitle/tagline.** A tagline lockup is a SEPARATE optional file (beat B only).
- **At least one fully integrated typemark** (direction D): the verified-path motif is fused INTO a "Relyra" letterform (e.g. the R's leg becomes the relay path with a verification node, or the descender of `y`), NOT placed beside the word.
- **Wordmark text:** "Relyra" — title case only. Never reLyra / ReLyra / RELYRA / RelyRa.
- **Forbidden imagery (permanent):** lyre/harp/music/constellation/celestial, shield, padlock, key, fingerprint, flame, Phoenix bird, hooded hacker, glowing server, chain links, blockchain nodes, purple SaaS blobs, corporate handshake, generic "R in a circle".

### Locked palette (from Phase 58 Canonical Lock Set — use these exact hexes)
- Ink #101827, Graphite #263245, Paper #FCFBF7, Mist #EEF2F6.
- Relay Blue #3454D1 (primary), Deep Relay #1D2E82 (emphasis), Proof Teal #147D77 (verified accent), Keyline Violet #6D5DF2 (rare accent).
- Dark mode: Dark Background #0B1020, Dark Text #F8FAFC, Dark Blue #8CA2FF, Dark Teal #61D6C8.

### The four directions (from brand book §7 + user's typemark ask)
- **A — Relying Path monogram:** custom R from SP left stem + IdP right node/curve + diagonal verified-assertion leg + verification dot. Suggests routing/binding/verification, NOT a generic R-in-circle.
- **B — Assertion Frame:** an OPEN bracket/frame (never a closed box) holding a single verified node (signed-assertion / bounded-trust-object / exact-consumption). Abstract, technical.
- **C — Trust Path:** two endpoints joined by a relay line passing through a check/seal node. Restrained, geometric; must have DISTINCTIVE geometry (node-link logos are common — avoid generic).
- **D — Integrated typemark:** fully worked "Relyra" wordmark with the motif fused into a letterform; no separate icon.

### Geometry rules (brand book §7)
- 1.5-2px stroke logic at base icon size; rounded JOINS (not pillowy round ends); angles on 30°/45°/60°; optical balance over strict symmetry; negative space implies a verified route.
- Wordmark feel: human-but-technical, slightly condensed, highly legible; the R and y carry identity; the a is simple; NOT rounded-bubbly, NOT sharp-cyber, NOT pharma-soft. Loosely a grotesque sans with subtle cuts/terminals (Phase reference font: IBM Plex Sans Condensed energy).

### Claude's Discretion
- Exact SVG construction technique (filled paths vs strokes) — but prefer `currentColor` for the primary form so mono/inverse are trivial (one optional locked accent allowed).
- Mark grid (recommend 24×24 viewBox), wordmark proportions, how the gallery is laid out.
- Which single accent (Relay Blue / Proof Teal) each direction uses for its color version.
</decisions>

<canonical_refs>
## Canonical References
- `brandbook/notes/decision-log.md` → "## Canonical Lock Set" — exact hexes + type lock (authoritative).
- `prompts/relyra-brand-book.md` §7 (logo direction), §"visual identity" (mood/forbidden imagery).
- `.planning/phases/59-logo-system-selection-checkpoint/59-CONTEXT.md` (this file — locked constraints).
</canonical_refs>

<specifics>
## Specific Ideas
- Each direction's color version should read at 16px (favicon test) — keep internal detail minimal.
- `currentColor` strategy: the mark's primary strokes/fills = `currentColor`; at most ONE accent element uses a literal locked hex. Then the gallery renders mono (color:Ink), inverse (color:Paper on dark), and on-tint by just setting CSS `color`.
- logo-lab.html is a throwaway SELECTION tool (not the final brand book). It must clearly label each direction A/B/C/D, show mark + lockup at ~16/24/48/96px, plus a mono row and an inverse-on-dark row, with one-line rationale per direction.
</specifics>

<deferred>
## Deferred Ideas
- Full favicon/social/OG assets — beat B (favicon) + phase 62 (social/OG).
- Animated logo — deferred (BRAND-F01).
</deferred>

---

*Phase: 59-logo-system-selection-checkpoint*
*Context gathered: 2026-06-14*
