# Phase 58: Brand Foundation Pressure-Test & Decision Lock - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning
**Source:** Milestone v1.8 scope (user prompt + approved plan)

<domain>
## Phase Boundary

This phase **audits and locks** the brand foundation. It produces **decision documents only** — no logos, no tokens, no HTML brand book (those are phases 59-61). The output is the authoritative, WCAG-verified source of truth that every downstream phase consumes.

Deliverables (all under `brandbook/notes/`):
- `research.md` — cited synthesis of brand/design-system/accessibility best practices used to pressure-test the book.
- `decision-log.md` — every pressure-test finding with options, tradeoffs, and an explicit **ship / reject / defer** disposition + confidence.
- `accessibility-checks.md` — every brand color pair (light + dark) checked against WCAG 2.2 for text (4.5:1 normal, 3:1 large) and non-text/UI (3:1), with computed ratios and pass/fail.

Out of scope for this phase: rendering any visual asset, writing tokens.json/css, building index.html, touching code outside `brandbook/notes/`.
</domain>

<decisions>
## Implementation Decisions

### Locked (do not relitigate — from the user and PROJECT.md constraint §"Brand")
- The brand is **decision-complete**; this milestone renders and pressure-tests it. **No rebrand**, no new name, no new tagline. Product name is **"Relyra"** (title case only — never reLyra/ReLyra/RELYRA). Primary tagline: **"Enterprise SAML, calmly verified."**
- **Forbidden imagery (permanent):** lyre / harp / music / constellation / celestial, shield, padlock, key, fingerprint, flame, Phoenix bird, hooded hacker, glowing server, chain links, blockchain nodes, purple SaaS blobs, corporate handshake.
- **Forbidden claims:** "unhackable", "bulletproof", "military-grade", "zero-risk", "SAML is easy". Security claims must be precise and falsifiable.
- Brand voice is **calm, exact, transparent, operator-friendly, open-source serious** (PROJECT.md + brand book §2).
- The canonical brand source is `prompts/relyra-brand-book.md` (Version 0.1). This phase pressure-tests it; it does not discard it.

### Pressure-test mandate (the actual work)
- Run the brand book through senior **graphic-design / design-system-lead / accessibility-specialist / red-team** lenses. Surface: genericness, internal contradictions, token sprawl, contrast failures, implementation risk, OSS-credibility gaps.
- **WCAG is the hard gate.** The brand book's palette (Ink #101827, Paper #FCFBF7, Mist #EEF2F6, Relay Blue #3454D1, Deep Relay #1D2E82, Proof Teal #147D77, Keyline Violet #6D5DF2, Certificate Gold #C08A2B, Graphite #263245, plus the semantic + dark-mode sets) must be checked for **every** realistic foreground/background pairing in both light and dark mode. Any pair that fails its intended use gets a documented remediation (adjusted hex) in the decision log — adjusting a brand hex for contrast is allowed and expected; it is not a rebrand.
- Resolve **token sprawl**: the palette, type scale (IBM Plex Sans Condensed / Atkinson Hyperlegible / JetBrains Mono), and voice must each end with exactly ONE canonical definition. Where the book offers alternatives, pick one and record why.

### Claude's Discretion
- Exact contrast-checking method (programmatic WCAG relative-luminance computation is preferred over eyeballing — show the math/ratios).
- Structure and depth of the three notes files, as long as each requirement's success criteria are met.
- Which specific palette pairings count as "realistic" (cover at minimum: body text, secondary text, links/primary action, success/warn/error/info on their surfaces, focus ring, borders, disabled — in both modes).
- Whether to adjust any brand hex for contrast (record every change with before/after ratio).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand source of truth
- `prompts/relyra-brand-book.md` — the full brand book (plain-text numbered sections 1-31; `⸻` dividers). Colors with hex ≈ section 8; typography ≈ section 9; logo direction ≈ section 7; visual mood / forbidden imagery ≈ sections "visual identity"; voice/microcopy ≈ later sections.

### Project constraints & positioning
- `.planning/PROJECT.md` — constraint §"Brand" (locked do/don't), Core Value, positioning tagline, brand voice note.
- `.planning/REQUIREMENTS.md` — BRAND-01, BRAND-02, BRAND-03 and the Out-of-Scope table.

### External standards (for research.md citations)
- WCAG 2.2 contrast (1.4.3 text, 1.4.11 non-text) — the contrast thresholds this phase gates on.
</canonical_refs>

<specifics>
## Specific Ideas

- `accessibility-checks.md` should be a table: pair | mode | use | computed ratio | required | pass/fail | remediation. Compute ratios from relative luminance (not guesses).
- `decision-log.md` should use a consistent per-decision block: Decision / Options / Tradeoffs / Ecosystem-or-a11y note / Disposition (ship|reject|defer) / Confidence.
- The locked outputs of this phase are referenced by name in phases 60 (tokens) and 61 (brand book), so keep canonical values (final hex set, type scale) in one clearly-labeled section the token phase can lift verbatim.
</specifics>

<deferred>
## Deferred Ideas

- Full 19-icon library (brand book spec) — deferred (BRAND-F02); this milestone ships only icons the components/book demonstrably need.
- Motion/animated brand assets beyond static motion-token guidance — deferred (BRAND-F01).
</deferred>

---

*Phase: 58-brand-foundation-pressure-test-decision-lock*
*Context gathered: 2026-06-14 from v1.8 milestone scope*
