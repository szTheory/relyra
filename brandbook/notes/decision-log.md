# Relyra Brand — Decision Log

**Phase:** 58 — Brand Foundation Pressure-Test & Decision Lock
**Date:** 2026-06-14
**Inputs:** `prompts/relyra-brand-book.md` v0.1, `brandbook/notes/accessibility-checks.md`, `brandbook/notes/research.md`

**Method.** The brand book was pressure-tested through four senior lenses run once over the whole
document: a graphic-design director (distinctiveness, genericness), a design-system lead (token
sprawl, functional-tier completeness, semantic collisions, light/dark parity, implementation risk),
an accessibility specialist (the WCAG 2.2 contrast gate — owns every pass/fail and every remediation
hex via `contrast.exs`), and an OSS-credibility red-team (self-contradictions, forbidden-claim/imagery
leakage, casing/voice drift). Findings converge below. Every disposition agrees with the verdicts in
`accessibility-checks.md`: no hex locked here is below its required ratio. The locked-and-permanent
constraints (product name "Relyra", primary tagline, forbidden imagery, forbidden claims, OSS-serious
voice) are NOT relitigated; the red-team lens only confirms the book never violates them (it does not).

Disposition vocabulary: **ship** = lock as-is or with the recorded remediation, downstream consumes
verbatim; **reject** = the book's current value/wording is wrong, replace with the recorded
alternative; **defer** = out of scope for v1.8, route to a future requirement.

---

**Decision D-01: Certificate Gold #C08A2B fails contrast on Paper**
- Lens: accessibility (with design-system lead on the replacement hue)
- Decision: What hex should Certificate Gold be, given #C08A2B = 2.93:1 on Paper (fails even non-text 3:1)?
- Options:
    - A. Keep #C08A2B — rejected, fails the gate; a caution/expiry accent that low-vision users cannot perceive is the worst place to under-contrast.
    - B. Darken to #A8741F (3.91:1) — passes non-text only; keeps a brighter value for large/icon use.
    - C. Darken to text-capable #9A6B1C (4.51:1) — passes the stricter 4.5:1 text gate, still reads as gold.
- Tradeoffs: B preserves more brightness but caps the color at non-text use; C is slightly darker but usable as a label/text color too, which is the safer default for a value that flags certificate state.
- A11y/ecosystem note: WCAG 1.4.3 (text 4.5) and 1.4.11 (non-text 3). #9A6B1C clears both; verified in accessibility-checks.md.
- Disposition: ship — adopt #9A6B1C as the canonical gold; record B (#A8741F) as a documented non-text-only alternate, not the lock.
- Confidence: HIGH

**Decision D-02: Dark Border #334155 — contradiction AND contrast failure, fixed together**
- Lens: design-system lead + red-team (contradiction) + accessibility (contrast)
- Decision: The book's dark palette TABLE says Dark Border #334155 while the book's dark CSS block says --relyra-border: #64748B. Which is canonical?
- Options:
    - A. Keep #334155 — rejected; 1.83:1 on #0B1020 and 1.71:1 on #111827, both fail non-text 3:1.
    - B. Adopt #64748B everywhere and delete #334155 from the border role — 3.98:1 / 3.73:1, both pass.
- Tradeoffs: none meaningful — #64748B is already the value the book's own CSS uses, so this resolves a self-contradiction and the contrast failure in one move. #334155 is slightly darker/subtler but is simply non-conformant.
- A11y/ecosystem note: this is the canonical Radix "one hex per role per mode" + Primer "no two values for one role" finding; WCAG 1.4.11 confirms #334155 fails. #64748B verified passing in accessibility-checks.md.
- Disposition: ship — dark border is #64748B everywhere; #334155 is removed from the border role.
- Confidence: HIGH

**Decision D-03: Soft Line #D8E0EA stays decorative-only**
- Lens: accessibility + design-system lead
- Decision: Soft Line #D8E0EA = 1.29:1 on Paper. Can it ever be a control boundary?
- Options:
    - A. Darken Soft Line until it reaches 3:1 — rejected; no tint of this hue clears 3:1 on Paper (tested #B9C5D6/#A6B4C8/#97A7BD, max ~2.36), and darkening it defeats its purpose as a faint divider.
    - B. Structural rule: Soft Line is a decorative divider only; every real interactive boundary routes to Accessible Border #7E8A9A (3.39 on Paper / 3.12 on Mist, both pass).
- Tradeoffs: B keeps a soft visual divider for non-load-bearing separation while guaranteeing controls are perceivable; it requires component specs to never use Soft Line as the sole cue a control exists.
- A11y/ecosystem note: WCAG 1.4.11 exempts decorative dividers but requires 3:1 for a boundary that is the only cue a control exists. The book already hints at this ("Dividers only; not enough for meaningful controls"); we lock it.
- Disposition: ship — Soft Line is decorative-divider-only; Accessible Border #7E8A9A is the interactive-boundary token.
- Confidence: HIGH

**Decision D-04: Info #3454D1 is byte-identical to Relay Blue (primary action)**
- Lens: design-system lead (Primer accent-vs-status separation) + graphic-design
- Decision: Info and Relay Blue / primary action are the same hex, so an info callout looks identical to a clickable action. Ship the collision or nudge Info to a distinct hue?
- Options:
    - A. Ship the collision, disambiguated by affordance — Info callouts always carry an icon + label (never color alone), and primary actions are buttons/links, so the surrounding affordance distinguishes "read this" from "click this." This is a common, defensible pattern.
    - B. Nudge Info to a distinct blue — cleaner perceptual separation, but adds a near-duplicate blue to the palette (sprawl) and diverges from the brand's single action-blue identity.
- Tradeoffs: A keeps the palette tight and leans on the book's existing "never rely on color alone; include icon and heading" rule; its risk is a reviewer who strips affordance. B removes ambiguity at the cost of a new token and weaker blue identity.
- A11y/ecosystem note: both #3454D1 uses pass contrast (6.08 on Paper). Primer keeps accent vs. status distinct, which is the argument for B; the book's icon+heading mandate is the mitigation that makes A safe. "Never color alone" (book §10/§14) is the load-bearing rule.
- Disposition: ship — keep Info = Relay Blue #3454D1, documented to require an icon + label affordance so it is never distinguished from a primary action by color alone. Record B (nudge Info to a distinct hue) as a deferred alternate if user testing later shows real confusion.
- Confidence: MEDIUM

**Decision D-05: Thin-margin passes are locked but flagged do-not-darken**
- Lens: accessibility
- Decision: Proof Teal 4.80, Keyline Violet 4.51, Warning 4.85, and Accessible-Border-on-Mist 3.12 all pass but sit close to their threshold. Lock or remediate?
- Options:
    - A. Lock as-is with a do-not-darken-surfaces flag — they conform today; remediating risks shifting established brand hues with no current failure.
    - B. Preemptively darken for headroom — rejected; changes conforming brand colors for a hypothetical and adds churn for phase 60.
- Tradeoffs: A keeps the brand hues intact and conformant but means any future surface-darkening (e.g., a warmer Paper, a darker Mist) must re-run contrast.exs before shipping. Accessible-Border-on-Mist (3.12, +0.12) is the tightest margin in the system.
- A11y/ecosystem note: all four verified passing in accessibility-checks.md. The committed contrast.exs exits 1 if a future edit breaks them, so the guardrail is automated.
- Disposition: ship — lock Proof Teal #147D77, Keyline Violet #6D5DF2, Warning #B45309, Accessible Border #7E8A9A as-is; flag the surfaces they sit on as do-not-darken without re-running the contrast gate.
- Confidence: MEDIUM

**Decision D-06: Canonical tagline**
- Lens: red-team (voice sprawl) + graphic-design
- Decision: §1 lists six taglines plus a "primary." Lock exactly one canonical line.
- Options:
    - A. "Enterprise SAML, calmly verified." as canonical; demote the other five to non-canonical alternates.
    - B. Allow context-dependent rotation among all six — rejected; downstream copy could pick any, diluting the brand line.
- Tradeoffs: A gives one unambiguous brand line for hero, README, and registries; the five alternates remain available as secondary context copy but never stand in for the brand line.
- A11y/ecosystem note: locked-and-permanent per CONTEXT.md; this decision records the demotion of the alternates, it does not choose a new tagline.
- Disposition: ship — canonical tagline is "Enterprise SAML, calmly verified."; the other five §1 options are non-canonical alternates.
- Confidence: HIGH

**Decision D-07: Typography stack — one role each**
- Lens: design-system lead
- Decision: Lock the type stack with exactly one family per role.
- Options:
    - A. IBM Plex Sans Condensed (display) / Atkinson Hyperlegible (body + UI) / JetBrains Mono (code) — one role each, all open-source.
    - B. Keep the book's "IBM Plex Sans Condensed OR IBM Plex Sans" ambiguity for display — rejected; "OR" is sprawl, downstream needs one.
- Tradeoffs: A resolves the display ambiguity to the Condensed cut (matches the "slightly condensed, technical" wordmark feel). Atkinson Hyperlegible for body fits the brand's unambiguous-glyph requirement for certificate fingerprints and error reading.
- A11y/ecosystem note: Atkinson Hyperlegible is purpose-built for letter/number differentiation (low-vision), reinforcing the accessibility posture. OFL/SIL license verification for all three families is deferred to the token/integration phase before any CDN load.
- Disposition: ship — display IBM Plex Sans Condensed, body/UI Atkinson Hyperlegible, code JetBrains Mono. Defer: OFL license verification (route to the token phase).
- Confidence: HIGH

**Decision D-08: Neutral sprawl resolved**
- Lens: design-system lead
- Decision: Are there near-duplicate greys that should be collapsed?
- Options:
    - A. Keep the neutral set as Ink / Graphite / Paper / Mist + one accessible border (#7E8A9A) + one decorative soft-line (#D8E0EA) — each tier has exactly one token; Mist↔Paper near-identical luminance is intentional (subtle panel), not sprawl.
    - B. Collapse Mist into Paper — rejected; Mist is a needed subtle-panel/code-background surface, the near-identical luminance is by design.
- Tradeoffs: A maps cleanly onto the Radix tier model (one app bg, one subtle bg, one interactive border, one decorative divider, two text levels) and adds no extra greys. The only acknowledged gap is hover/pressed surface tokens, routed to the token phase.
- A11y/ecosystem note: Radix five-tier completeness; Primer no-near-duplicates discipline. No extra near-duplicate greys are introduced.
- Disposition: ship — neutrals are Ink / Graphite / Paper / Mist + Accessible Border #7E8A9A + Soft Line #D8E0EA, no additions. Defer: component hover/pressed surface tokens to the token phase.
- Confidence: HIGH

---

## Canonical Lock Set

This is the single authoritative set phases 60 (tokens) and 61 (HTML brand book) lift verbatim.
Exactly one value per role; no competing alternatives. All hexes reflect the D-01..D-08 remediations
and pass their WCAG requirement per `accessibility-checks.md`.

### Light-mode palette (one hex per role)

| Role | Token | Hex |
| --- | --- | --- |
| Primary text | Ink | #101827 |
| Secondary text / headings | Graphite | #263245 |
| Main background | Paper | #FCFBF7 |
| Subtle panel / code bg / disabled surface | Mist | #EEF2F6 |
| Primary action / link / active | Relay Blue | #3454D1 |
| Emphasis / hero blue | Deep Relay | #1D2E82 |
| Verified / success-adjacent accent | Proof Teal | #147D77 |
| Focus ring / rare accent | Keyline Violet | #6D5DF2 |
| Interactive border (controls) | Accessible Border | #7E8A9A |
| Decorative divider only | Soft Line | #D8E0EA |
| Certificate / caution accent (remediated, text-capable) | Certificate Gold | #9A6B1C |

### Semantic colors (light)

| Role | Hex |
| --- | --- |
| Success | #027A48 |
| Warning | #B45309 |
| Error | #B42318 |
| Info (= Relay Blue; requires icon + label affordance, never color alone) | #3454D1 |

### Dark-mode palette (one hex per role)

| Role | Token | Hex |
| --- | --- | --- |
| Main background | Dark Background | #0B1020 |
| Cards / panels | Dark Surface | #111827 |
| Border (remediated; #334155 removed) | Dark Border | #64748B |
| Primary text | Dark Text | #F8FAFC |
| Secondary text | Dark Muted | #CBD5E1 |
| Links / actions | Dark Blue | #8CA2FF |
| Verified accent | Dark Teal | #61D6C8 |
| Focus / diagram accent | Dark Violet | #A99BFF |
| Warning | Dark Amber | #FBBF24 |
| Error | Dark Red | #FDA29B |
| Success | Dark Green | #86EFAC |

Dark Deep-Relay: where an emphasis blue is needed on dark, use the book's CSS value #A9B7FF
(one canonical value for the role; the duplicate mapping is resolved to this).

### Typography (one family per role)

| Role | Family | Fallback |
| --- | --- | --- |
| Display / headings | IBM Plex Sans Condensed | "IBM Plex Sans", system-ui, sans-serif |
| Body / UI / docs | Atkinson Hyperlegible | system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif |
| Code | JetBrains Mono | ui-monospace, SFMono-Regular, Menlo, Consolas, monospace |

(OFL/SIL license verification for all three deferred to the token/integration phase.)

### Voice and tagline

| Item | Lock |
| --- | --- |
| Canonical tagline | Enterprise SAML, calmly verified. |
| Alternate (non-canonical) taglines | the other five §1 options — secondary context copy only, never the brand line |
| Product name | Relyra (title case only; never reLyra / ReLyra / RELYRA) |
| Voice | calm, exact, transparent, operator-friendly, open-source serious |
| Pronunciation | canonical REH-lee-ruh; ruh-LY-ruh acceptable, never corrected aggressively |

### Remediation summary (what changed from the book v0.1)

- Certificate Gold #C08A2B → **#9A6B1C** (2.93 fail → 4.51 pass, text-capable).
- Dark Border #334155 → **#64748B** (1.71-1.83 fail → 3.73-3.98 pass; also resolves the table-vs-CSS contradiction).
- Soft Line #D8E0EA: unchanged hex, locked decorative-only; interactive boundaries use Accessible Border #7E8A9A.
- Info #3454D1: unchanged hex (collision shipped), constrained to icon + label affordance.
- Display type "Condensed OR Sans" ambiguity → locked to **IBM Plex Sans Condensed**.
