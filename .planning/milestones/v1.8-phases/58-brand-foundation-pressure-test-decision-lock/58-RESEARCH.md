# Phase 58: Brand Foundation Pressure-Test & Decision Lock - Research

**Researched:** 2026-06-14
**Domain:** Brand/design-system auditing, WCAG 2.2 color contrast, OSS devtool brand credibility
**Confidence:** HIGH (WCAG thresholds + computed ratios verified; design-system rubrics cited from official docs)

## Summary

This phase pressure-tests a **decision-complete** brand book (`prompts/relyra-brand-book.md` v0.1) and produces three decision documents only — no assets. The work is method + standards, not design. The single hard gate is **WCAG 2.2 contrast**; everything else (token sprawl, contradictions, OSS credibility) is a structured audit producing ship/reject/defer dispositions.

I computed every realistic palette pair's contrast ratio in Elixir (the repo's native tooling, `~> 1.18`) using the official WCAG relative-luminance + contrast-ratio formulas. **The math surfaces concrete, non-negotiable findings**: Certificate Gold (`#C08A2B`) fails even non-text contrast on Paper (2.93:1 < 3:1); the dark-mode palette table's `Dark Border #334155` fails non-text contrast on both dark surfaces (1.71-1.83:1 < 3:1) — and **contradicts the book's own CSS token block**, which sets the dark border to `#64748B` (which passes, 3.73-3.98:1). Several colors pass but sit on thin margins (Proof Teal 4.8, Keyline Violet 4.51, Warning 4.85) and should be flagged as "passes-but-fragile."

The design-system rubric is drawn from Radix Colors (functional step-tiers), GitHub Primer (base → functional → component token hierarchy), and GitHub's own brand guidelines (monochrome-first logo restraint). These give the auditor an objective vocabulary for "token sprawl," "semantic completeness," and "dark-mode parity."

**Primary recommendation:** Run the audit as four named lenses (design-system lead / accessibility / red-team / OSS-credibility), gate every color pair through the committed Elixir contrast script (`accessibility-checks.md` table is generated from it, not eyeballed), remediate the confirmed failures with the darker/lighter hex candidates computed below, collapse the palette to one canonical functional-token set, and record each finding as a Decision/Options/Tradeoffs/Disposition/Confidence block.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- The brand is **decision-complete**; this milestone renders and pressure-tests it. **No rebrand**, no new name, no new tagline. Product name is **"Relyra"** (title case only — never reLyra/ReLyra/RELYRA). Primary tagline: **"Enterprise SAML, calmly verified."**
- **Forbidden imagery (permanent):** lyre / harp / music / constellation / celestial, shield, padlock, key, fingerprint, flame, Phoenix bird, hooded hacker, glowing server, chain links, blockchain nodes, purple SaaS blobs, corporate handshake.
- **Forbidden claims:** "unhackable", "bulletproof", "military-grade", "zero-risk", "SAML is easy". Security claims must be precise and falsifiable.
- Brand voice is **calm, exact, transparent, operator-friendly, open-source serious** (PROJECT.md + brand book §2).
- The canonical brand source is `prompts/relyra-brand-book.md` (Version 0.1). This phase pressure-tests it; it does not discard it.

### Pressure-test mandate (the actual work)
- Run the brand book through senior **graphic-design / design-system-lead / accessibility-specialist / red-team** lenses. Surface: genericness, internal contradictions, token sprawl, contrast failures, implementation risk, OSS-credibility gaps.
- **WCAG is the hard gate.** Every realistic foreground/background pairing in both light and dark mode must be checked. Any pair that fails its intended use gets a documented remediation (adjusted hex) in the decision log — adjusting a brand hex for contrast is allowed and expected; it is not a rebrand.
- Resolve **token sprawl**: palette, type scale (IBM Plex Sans Condensed / Atkinson Hyperlegible / JetBrains Mono), and voice must each end with exactly ONE canonical definition. Where the book offers alternatives, pick one and record why.

### Claude's Discretion
- Exact contrast-checking method (programmatic WCAG relative-luminance computation is preferred over eyeballing — show the math/ratios).
- Structure and depth of the three notes files, as long as each requirement's success criteria are met.
- Which specific palette pairings count as "realistic" (cover at minimum: body text, secondary text, links/primary action, success/warn/error/info on their surfaces, focus ring, borders, disabled — in both modes).
- Whether to adjust any brand hex for contrast (record every change with before/after ratio).

### Deferred Ideas (OUT OF SCOPE)
- Full 19-icon library (brand book spec) — deferred (BRAND-F02); this milestone ships only icons the components/book demonstrably need.
- Motion/animated brand assets beyond static motion-token guidance — deferred (BRAND-F01).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRAND-01 | Brand book pressure-tested across design, accessibility, red-team lenses; findings with ship/reject/defer dispositions in a decision log | "Pressure-Test Method" (four-lens rubric) + "Design-System Audit Rubrics" + per-decision block schema below |
| BRAND-02 | Every brand color pair (light + dark) WCAG-checked for text and non-text contrast, pass/fail documented | "WCAG 2.2 Contrast" section + the committed Elixir contrast script + the fully-computed pair table in "Validation Architecture" |
| BRAND-03 | Final palette, typography stack, voice locked — token sprawl removed, contradictions resolved — authoritative input for downstream | "Token Sprawl Resolution" + "Canonical Lock Set" guidance + functional-tier token model from Radix/Primer |
</phase_requirements>

## Architectural Responsibility Map

This phase has no software tiers; the equivalent is **audit-lens ownership** — which lens owns which finding class.

| Capability | Primary Lens | Secondary Lens | Rationale |
|------------|-------------|----------------|-----------|
| Contrast pass/fail + remediation hex | Accessibility | Design-system lead | WCAG math is objective; the a11y lens owns the gate, design lead approves the replacement hue |
| Token sprawl / near-duplicate neutrals | Design-system lead | — | Sprawl is a system-structure judgment (Radix/Primer functional tiers) |
| Semantic-color completeness + collisions | Design-system lead | Accessibility | Info=`#3454D1`=Relay Blue collision is a structural + perceptual problem |
| Dark-mode parity | Design-system lead | Accessibility | Same semantic token must resolve correctly in both modes AND pass contrast |
| Genericness / distinctiveness | OSS-credibility red-teamer | Design-system lead | "Does this look like every other devtool?" is a market-positioning judgment |
| Forbidden-claim / forbidden-imagery leakage | Red-teamer | OSS-credibility | Red-team hunts for places the book contradicts its own locked constraints |
| Voice contradiction / multiple taglines | Red-teamer | Design-system lead | Six taglines + one "primary" is a sprawl-of-voice finding |
| Implementation risk (will this break in real UI/code?) | Design-system lead | Accessibility | "Looks fine in a swatch, fails as a control boundary" |

## Standard Stack

This is a documentation-only phase. The only "tooling" is a self-contained contrast calculator and reference standards. **No packages are installed**, so the Package Legitimacy Audit is N/A (see below).

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Elixir (`elixir script.exs`) | `~> 1.18` (repo pin) | Compute WCAG relative luminance + contrast ratios; generate the pass/fail table | Repo-native; zero new deps; reproducible; commit-friendly. `[VERIFIED: ran on this machine]` |
| WCAG 2.2 (W3C Rec) | 2.2 (Oct 2023, current) | The contrast gate — SC 1.4.3 (text) + SC 1.4.11 (non-text) | The legally-relevant conformance standard for 2025-2026. `[CITED: w3.org/WAI/WCAG22]` |

### Supporting References (for `research.md` citations)
| Reference | Purpose | When to Use |
|-----------|---------|-------------|
| Radix Colors scale docs | Functional step-tier model (bg / component / border / solid / text) | Auditing token sprawl + semantic completeness `[CITED: radix-ui.com/colors]` |
| GitHub Primer color overview | base → functional → component token hierarchy; contrast-against-muted-bg discipline | Auditing token layering + dark/light parity `[CITED: primer.style]` |
| GitHub Brand Toolkit (logo) | Monochrome-first logo restraint, no effects, clear-space, misuse list | OSS-credibility lens (transferable only — phase ships no logo) `[CITED: brand.github.com]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Elixir contrast script | A web contrast checker (WebAIM, Stark) | Not reproducible/committable; can't be re-run in CI; manual transcription introduces error. Reject. |
| WCAG 2.2 gate | APCA / WCAG 3 | APCA is the *candidate* for WCAG 3, which is "years away, perhaps 2030 at soonest" and "no confirmation whether APCA will come back." WCAG 2.x remains the compliance benchmark. Use APCA only as informational context, never as the gate. `[CITED: adrianroselli.com, yatil.net]` |

### Package Legitimacy Audit
**N/A — this phase installs zero external packages.** It produces three Markdown files and (optionally) commits one `.exs` contrast script that uses only the Elixir standard library (`:math`, `String`). No registry verification needed. Document this explicitly in the plan so the planner does not insert a spurious checkpoint.

## WCAG 2.2 Contrast — The Hard Gate (authoritative)

`[CITED: w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]`
`[CITED: w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]`

### Thresholds

| Criterion | Applies to | Required ratio |
|-----------|-----------|----------------|
| **1.4.3 Contrast (Minimum)** — normal text | body text, links, labels, error/help copy | **4.5:1** |
| **1.4.3** — large text | ≥ 18pt (≈24px) regular, or ≥ 14pt (≈18.66px) **bold** | **3:1** |
| **1.4.11 Non-text Contrast** — UI components & graphical objects | control boundaries (when the boundary is the sole identifier of the control), **focus indicators**, state fills (checkmarks, selected), meaningful icons, chart strokes | **3:1** |

**Critical rounding rule (verbatim from W3C):** "the computed values should not be rounded (e.g. 2.999:1 would not meet the 3:1 threshold)." Tables that round to 2 dp must still apply the verdict against the *unrounded* value. The script below rounds for display only; verdict logic must compare unrounded.

**Boundary exemption (1.4.11):** "If a control has visible content (such as text or a sufficiently contrasting icon)... a border... is not required." So a **decorative divider** (Soft Line) is exempt — but the same hex used as a *form-field border that is the only cue the field exists* must hit 3:1. This distinction is the crux of the Soft Line / Accessible Border finding (see pitfalls).

### The math (exact, current)

Relative luminance: `L = 0.2126·R + 0.7152·G + 0.0722·B`, where each channel is linearized:

```
cs = channel / 255
lin = cs/12.92                      if cs <= 0.04045
lin = ((cs + 0.055)/1.055)^2.4      otherwise
```

Contrast ratio: `(L_lighter + 0.05) / (L_darker + 0.05)`.

**Note on the threshold constant:** W3C updated `0.03928` → `0.04045` in May 2021 "with no practical effect on the calculations." I re-ran every borderline pair with `0.04045`; **no verdict flips**. Use `0.04045` in the committed script for correctness, but either is defensible — document the choice. `[VERIFIED: ran both thresholds on this machine]`

### Computed results for the actual Relyra palette `[VERIFIED: computed on this machine, Elixir]`

These are real numbers, not estimates. The full table belongs in `accessibility-checks.md`; the load-bearing findings are:

**Confirmed FAILURES (must remediate):**

| Pair | Mode | Intended use | Ratio | Required | Verdict |
|------|------|-------------|-------|----------|---------|
| Certificate Gold `#C08A2B` on Paper `#FCFBF7` | light | caution accent / icon (non-text) | **2.93** | 3:1 | **FAIL** — fails even as a non-text accent |
| Certificate Gold `#C08A2B` on Paper | light | as text (book already forbids body text) | 2.93 | 4.5:1 | FAIL (expected; book disallows, but spell it out) |
| Dark Border `#334155` on Dark Background `#0B1020` | dark | control boundary (non-text) | **1.83** | 3:1 | **FAIL** |
| Dark Border `#334155` on Dark Surface `#111827` | dark | control boundary (non-text) | **1.71** | 3:1 | **FAIL** |
| Soft Line `#D8E0EA` on Paper | light | *if used as a control boundary* | 1.29 | 3:1 | FAIL (PASS only if purely decorative — see pitfall) |

**PASSES-BUT-FRAGILE (flag as thin margin, no remediation required):**

| Pair | Mode | Use | Ratio | Required |
|------|------|-----|-------|----------|
| Proof Teal `#147D77` on Paper | light | text/verified | 4.80 | 4.5 |
| Keyline Violet `#6D5DF2` on Paper | light | focus ring (non-text) 4.51; as text 4.51 | 4.51 | 3 / 4.5 |
| Warning `#B45309` on Paper / Paper on Warning | light | warn text / button | 4.85 | 4.5 |
| Accessible Border `#7E8A9A` on Mist `#EEF2F6` | light | control boundary | 3.12 | 3 |
| Paper on Proof Teal `#147D77` (button) | light | button text | 4.80 | 4.5 |

**Comfortable PASSES (representative):** Ink on Paper 17.16; Graphite on Paper 12.48; Relay Blue on Paper 6.08; Paper on Relay Blue 6.08; Paper on Deep Relay 11.49; Error 6.35; Success 5.23; Dark Text on Dark bg 18.10; Dark Muted 12.75; Dark Blue link 7.87; Dark Teal 10.78; Dark Violet focus 7.95; Dark Amber 11.34; Dark Red 9.75; Dark Green 13.48.

### Remediation hex candidates (computed) `[VERIFIED: computed on this machine]`

The planner can lift these directly; the executor confirms with the script.

| Failing color | Target | Candidate | New ratio | Note |
|---------------|--------|-----------|-----------|------|
| Certificate Gold `#C08A2B` | non-text 3:1 only | between `#A8741F` (3.91) and current | pick `#A8741F` → 3.91 (comfortable non-text) | keeps gold hue, darkens value |
| Certificate Gold `#C08A2B` | text 4.5:1 (if ever used as text) | `#9A6B1C` (4.51) / `#946A1E` (4.67) / `#8A5E15` (5.49) | 4.51-5.49 | if the brand wants gold to be a usable text/label color |
| Dark Border `#334155` | non-text 3:1 | `#52617A` (3.02 vs bg) — thin; prefer `#64748B` (3.98 vs bg / 3.73 vs surface) | 3.73-3.98 | **`#64748B` is what the book's own CSS token block already uses** |
| Soft Line `#D8E0EA` (if load-bearing) | non-text 3:1 | none of `#B9C5D6`/`#A6B4C8`/`#97A7BD` reach 3:1 on Paper (max 2.36) | — | **resolution is structural**: keep Soft Line decorative-only; route any real control boundary to Accessible Border |

## Design-System Audit Rubrics

What a senior design-system lead checks. Each row is an audit question the lens must answer with evidence.

### 1. Functional-tier completeness (Radix model) `[CITED: radix-ui.com/colors]`

Radix proves every color need maps to one of five functional tiers. Audit the Relyra palette against this — a complete system has exactly one token per tier per mode, no gaps, no duplicates:

| Radix tier | Steps | Relyra light token(s) | Audit question |
|------------|-------|----------------------|----------------|
| App / subtle bg | 1-2 | Paper, Mist | Two neutrals — is Mist distinct enough from Paper? (ratio Mist↔Paper is tiny by design; OK) |
| Component bg (normal/hover/pressed) | 3-5 | *unspecified* | **Gap:** book has no hover/pressed surface tokens — flag for token phase |
| Borders (subtle / interactive / focus) | 6-8 | Soft Line (subtle), Accessible Border (interactive), Keyline Violet (focus) | Three border roles exist but Soft Line fails as interactive (see contrast) |
| Solid bg | 9-10 | Relay Blue, Deep Relay, semantic bgs | Present |
| Text (low / high contrast) | 11-12 | Graphite (secondary), Ink (primary) | Present and strong |

### 2. Token hierarchy / sprawl (Primer model) `[CITED: primer.style/foundations/color]`

Primer's three-tier discipline is the anti-sprawl test:
1. **Base/primitive** tokens map to raw hex, *never used directly in production*.
2. **Functional** tokens (`fgColor-*`, `bgColor-*`, `borderColor-*`) reference base tokens and respect mode.
3. **Component/pattern** tokens (`focus-outlineColor`) — used sparingly.

**Audit findings this surfaces in the Relyra book:**
- The book mixes primitive names (Ink, Paper, Relay Blue) with functional uses ("Primary text, dark backgrounds, logo" all on one token). For the *lock*, decide: are these primitives that semantic tokens point at, or are they the semantic layer? Recommendation: treat the named colors as **primitives**, define a thin semantic layer (`text-primary` → Ink, `action` → Relay Blue, `border-interactive` → Accessible Border) so the token phase (60) has clean inputs.
- **Semantic collision:** `Info #3454D1` === `Relay Blue #3454D1` === primary action color. Primer keeps `accent` and `done`/`open` distinct. Info-equals-primary means an info callout is visually identical to a clickable action — a real ambiguity. Disposition candidate: ship (acceptable, common pattern) OR shift Info toward a distinct blue. Record the tradeoff.
- **Dark-mode parity contradiction (high severity):** the book's dark **palette table** says `Dark Border #334155` while its **CSS `:root[data-theme="dark"]` block** says `--relyra-border: #64748B`. These are two different values for the same role in the same document. `#334155` fails 3:1; `#64748B` passes. **Resolve to `#64748B`.** This is the cleanest example of "contradiction + contrast failure resolved together."

### 3. Dark-mode parity (Radix mutable-alias model)

Radix recommends "mutable aliases" so the same semantic token resolves to different hex per mode while keeping identical semantics. Audit: does every light token have a dark counterpart with the same *role*? The book's dark palette is mostly complete, but note `Deep Relay` light has two different dark mappings (`Dark Blue #8CA2FF` for links, and the CSS block adds `--relyra-blue-deep: #A9B7FF`) — confirm one canonical dark value per role.

### 4. Distinctiveness in the devtool/OSS space

The book itself forbids "generic black-and-neon cybersecurity site." Audit: warm Paper (`#FCFBF7`) over pure white + Atkinson Hyperlegible body is genuinely differentiating vs. the typical Inter-on-#FFF devtool. Disposition: this is a *strength* — lock it, don't relitigate.

## OSS Devtool Brand Credibility (transferable lessons only — phase ships no asset)

`[CITED: brand.github.com/foundations/logo]`

What makes an Elixir/Hex library read credible vs. generic on GitHub/HexDocs:

- **Monochrome-first.** GitHub permits its mark only in white/black/grey/green, "no graphic effects like shadows or gradients." Transfer: Relyra's logo colorway list (Ink-on-Paper, Paper-on-Ink, one-color mono for README/registries) already matches this discipline — lock it. The brand book's "Avoid gradient-only logos" rule is the credible choice.
- **No clipart / no mascot.** GitHub: "avoid substituting illustrations or mascots." Relyra's forbidden-imagery list (no shield/lock/key/flame/bird/lyre) is the same instinct — and is *locked*, so the red-team lens just verifies no section of the book accidentally reintroduces them (it doesn't, but confirm §11 iconography and §6 metaphors stay clean).
- **Small-size legibility is the gate, not hero art.** Favicon at 16px, Hex package icon, GitHub org avatar. The book's "Icon only: 24px minimum, 16px favicon with simplified detail" is correct restraint.
- **HexDocs reality:** the logo must survive ex_doc's small header slot and both light/dark doc themes. This is why monochrome-first + a contrast-passing mark matters even at this audit stage — flag it as a constraint the logo phase (59) inherits.

These are CONTEXT for the credibility lens; **this phase produces no logo.** Do not let the plan drift into logo work.

## Pressure-Test Method (repeatable, four-lens)

A lens-based audit that produces ship/reject/defer dispositions with confidence. Each lens runs the whole book once and files findings; findings converge into `decision-log.md`.

### The four lenses

1. **Design-system lead** — token sprawl, functional-tier completeness, semantic collisions, dark/light parity, implementation risk ("will this survive contact with real CSS?").
2. **Accessibility specialist** — runs the contrast script over every realistic pair; owns every pass/fail; proposes remediation hex; checks focus-ring visibility in *both* modes; checks "never color alone" (the book already mandates icon+heading on status — verify).
3. **Red-teamer** — hunts contradictions and self-violations: multiple taglines vs. one "primary"; the `#334155`/`#64748B` split; any forbidden claim/imagery leakage; any place "magic/simple/just" sneaks into sample copy; pronunciation/casing drift.
4. **OSS-credibility** — genericness, monochrome-first restraint, HexDocs/GitHub render reality, "does this look like a maintained security library or a SaaS billboard."

### Per-decision block schema (for `decision-log.md`)

Use this exact shape for every finding (matches CONTEXT.md §specifics):

```
### D-NN: <short title>
**Lens:** design-system | accessibility | red-team | oss-credibility
**Decision:** <the question being resolved>
**Options:** <A / B / C>
**Tradeoffs:** <what each option costs>
**Ecosystem-or-a11y note:** <cite WCAG / Radix / Primer / GitHub where relevant>
**Disposition:** ship | reject | defer
**Confidence:** HIGH | MEDIUM | LOW
```

(Avoid literal triple-backtick fences inside the per-decision blocks if any downstream GSD decision-coverage gate parses this file — known footgun; use indented examples instead.)

### Disposition semantics
- **ship** — lock as-is or with the recorded remediation; downstream phases consume it verbatim.
- **reject** — the book's current value/wording is wrong; replace with the recorded alternative.
- **defer** — out of scope for v1.8 (e.g., the 19-icon library, motion assets) — route to BRAND-F01/F02.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contrast ratios | Eyeballing swatches / "looks fine" | The committed Elixir WCAG script | Human perception overstates contrast for mid-tones; the spec is exact math |
| Color-role taxonomy | Inventing a bespoke tier system | Radix 5-tier + Primer 3-layer model | Mature, battle-tested, gives the auditor objective language |
| Logo credibility rules | Re-deriving "what looks pro" | GitHub Brand Toolkit principles | Monochrome-first/no-effects is the proven OSS default |
| "Is APCA the gate?" | Adopting APCA because it's newer | WCAG 2.x | APCA is WCAG-3-candidate, non-normative, no legal standing until ~2030 |

**Key insight:** every subjective-feeling judgment in a brand audit (sprawl, completeness, credibility, contrast) has an objective external rubric. Cite it; don't improvise.

## Common Pitfalls

### Pitfall 1: Decorative-vs-functional border confusion
**What goes wrong:** Soft Line `#D8E0EA` (1.29:1 on Paper) gets used as a form-field border. As a *divider* it's WCAG-exempt; as the *only cue a control exists* it must hit 3:1 and fails badly.
**How to avoid:** Lock the rule the book already hints at — "Dividers only; not enough for meaningful controls." Every interactive boundary routes to Accessible Border (`#7E8A9A`, 3.39 on Paper / 3.12 on Mist). Document both the decorative pass and the interactive fail for Soft Line.
**Warning sign:** any component spec that puts a Soft Line border on an input/button without other affordance.

### Pitfall 2: Contrast-failing accent (Certificate Gold)
**What goes wrong:** `#C08A2B` at 2.93:1 fails even non-text 3:1 on Paper; used for a caution icon or expiry badge stroke it's invisible to low-vision users — ironic for a "certificate expiring" warning.
**How to avoid:** Darken to `#A8741F` (3.91 non-text) or `#9A6B1C` (4.51 text). Record before/after.
**Warning sign:** gold on Paper anywhere a user must perceive it to act.

### Pitfall 3: Two values for one dark-mode role
**What goes wrong:** `Dark Border #334155` (table) vs `--relyra-border: #64748B` (CSS) — the token phase will pick one arbitrarily and may pick the failing one.
**How to avoid:** Resolve to `#64748B` (passes 3:1), delete `#334155` from the border role. This is the canonical "contradiction + contrast failure, fixed together" decision-log entry.
**Warning sign:** any role with two hexes anywhere in the document.

### Pitfall 4: Semantic color collides with brand blue
**What goes wrong:** `Info #3454D1` is byte-identical to Relay Blue (primary action). An info callout and a button look the same — users can't tell "read this" from "click this."
**How to avoid:** Decide deliberately (ship the collision as a known, common pattern, OR nudge Info to a distinct hue). Either is valid; the sin is leaving it undocumented.
**Warning sign:** any reviewer who can't tell an info banner from a CTA.

### Pitfall 5: Focus ring invisible in one mode
**What goes wrong:** A focus indicator that passes in light mode disappears in dark. Relyra's focus colors actually pass (Keyline Violet 4.51 light; Dark Violet 7.95/7.45 dark) — but this must be *verified*, not assumed, because it's the #1 silent a11y regression.
**How to avoid:** Explicitly test focus ring against every surface it can land on, in both modes. Already computed above — lock it.
**Warning sign:** focus styles defined once with no per-mode check.

### Pitfall 6: Voice/tagline sprawl
**What goes wrong:** §1 lists six taglines plus a "primary." Downstream copy could pick any.
**How to avoid:** Lock exactly one canonical tagline ("Enterprise SAML, calmly verified.") and demote the rest to "alternate, non-canonical" or cut them. Same for the two acceptable pronunciations — keep both but mark one canonical.
**Warning sign:** any downstream artifact using a non-primary tagline as if it were the brand line.

## Runtime State Inventory

Not applicable — this is a greenfield documentation phase (creates three new files under `brandbook/notes/`). No rename, no stored data, no live-service config, no OS-registered state, no build artifacts affected. **Verified by:** phase boundary explicitly scopes output to new `brandbook/notes/*.md` only.

## Code Examples

### The committed contrast script (`brandbook/notes/contrast.exs` — verified working)

This exact script ran on this machine and produced the ratios above. It uses only stdlib. Source: WCAG 2.2 formulas (`[CITED: w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]`).

```elixir
defmodule WCAG do
  def srgb_to_lin(c) do
    cs = c / 255.0
    if cs <= 0.04045, do: cs / 12.92, else: :math.pow((cs + 0.055) / 1.055, 2.4)
  end

  def luminance("#" <> h), do: luminance(h)
  def luminance(h) do
    <<r::binary-2, g::binary-2, b::binary-2>> = h
    {r, g, b} = {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
    0.2126 * srgb_to_lin(r) + 0.7152 * srgb_to_lin(g) + 0.0722 * srgb_to_lin(b)
  end

  # Returns {display_ratio, passes?} — verdict uses UNROUNDED value per WCAG note.
  def check(fg, bg, required) do
    l1 = luminance(fg)
    l2 = luminance(bg)
    {hi, lo} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
    raw = (hi + 0.05) / (lo + 0.05)
    {Float.round(raw, 2), raw >= required}
  end
end
```

### Generating the `accessibility-checks.md` table

Drive `WCAG.check/3` over a list of `{fg, bg, mode, use, required}` tuples and emit a Markdown table row per pair. The executor runs `elixir contrast.exs` and pastes/redirects output — the table is *generated*, never hand-typed, so it cannot drift from the math.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WCAG 2.0/2.1 contrast | WCAG 2.2 (same contrast SCs; adds 2.4.11/2.4.13 focus-appearance guidance) | Oct 2023 | 1.4.3 / 1.4.11 thresholds unchanged; still the gate |
| `0.03928` linearization threshold | `0.04045` | May 2021 | "no practical effect"; no verdict flips for this palette |
| WCAG 2.x as only option | APCA proposed for WCAG 3 | ongoing | **Not yet a gate** — WCAG 3 "perhaps 2030 at soonest"; use APCA as context only |

**Deprecated/outdated:** Do not gate on APCA. Do not use online contrast checkers as the source of truth (non-reproducible).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Mist↔Paper near-identical luminance is intentional (subtle panel), not a sprawl error | Design-System Rubrics §1 | Low — if treated as sprawl, auditor might wrongly collapse two needed neutrals |
| A2 | The phase wants Certificate Gold usable as a *non-text accent* (so 3:1 target); text-grade 4.5 is optional | Remediation table | Medium — if gold must be text-capable, use the 4.5 candidate `#9A6B1C` instead |
| A3 | Info=Relay-Blue collision is a *deliberate* design choice the book may keep | Pitfall 4 | Low — flagged as a decision either way; planner must surface it, not silently fix |
| A4 | No downstream GSD decision-coverage gate parses `decision-log.md` for D-IDs; if one does, triple-backticks must be stripped (known footgun from MEMORY) | Per-decision schema | Low — mitigated by recommending indented examples |

## Open Questions

1. **Should Info diverge from Relay Blue?**
   - What we know: they are identical (`#3454D1`); this is a common, defensible pattern.
   - What's unclear: whether the maintainer wants visual separation of "informational" from "actionable."
   - Recommendation: present both options in `decision-log.md` with a ship-the-collision default; let the disposition be explicit.

2. **Certificate Gold: non-text-only or text-capable?**
   - What we know: current `#C08A2B` fails both; `#A8741F` fixes non-text, `#9A6B1C` fixes text.
   - Recommendation: default to the text-capable `#9A6B1C` (safer, still reads as gold) unless the maintainer wants to preserve the brighter value strictly for large/icon use.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir (`elixir`/`mix`) | Contrast script execution | ✓ | repo pin `~> 1.18` (ran successfully) | A Node/Python equivalent of the same formula — but Elixir is native, no fallback needed |

No external services, no network, no installed packages. Pure-stdlib script.

## Validation Architecture

> nyquist_validation treated as enabled (no `false` found). This phase's "tests" are the contrast computations — they are the validation, and they should be committable + re-runnable.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Plain Elixir script (`elixir brandbook/notes/contrast.exs`) — no ExUnit needed for a doc phase |
| Config file | none — single self-contained `.exs` |
| Quick run command | `elixir brandbook/notes/contrast.exs` |
| Full suite command | same — prints every pair + pass/fail and exits |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BRAND-02 | Every realistic pair (light+dark, text+non-text) computes a ratio + verdict | unit (math) | `elixir brandbook/notes/contrast.exs` | ❌ Wave 0 (create `contrast.exs`) |
| BRAND-02 | Failing pairs have a remediation hex that passes its target | unit (math) | same script, asserting remediated hexes ≥ required | ❌ Wave 0 |
| BRAND-03 | Canonical lock set contains exactly one hex per role (no dupes) | manual review against generated table | n/a (human-verify against `decision-log.md`) | ✅ doc review |
| BRAND-01 | Every finding has a disposition + confidence | manual review | n/a | ✅ doc review |

### Sampling Rate
- **Per task commit:** re-run `elixir brandbook/notes/contrast.exs`; confirm zero unremediated FAIL rows for intended uses.
- **Per wave merge:** regenerate `accessibility-checks.md` from script output (no hand edits).
- **Phase gate:** all confirmed-failure pairs either remediated (new hex passes) or explicitly downgraded to a use where they pass, recorded in `decision-log.md`.

### Optional hardening
Make the script `exit 1` if any pair flagged "must-pass" is below its required ratio. Then it can be wired into `mix qa`-adjacent checks later (phase 60+) so a future token edit that breaks contrast fails CI. Not required for this phase, but cheap to build in.

### Wave 0 Gaps
- [ ] `brandbook/notes/contrast.exs` — implements WCAG 2.2 luminance + ratio; drives the pair list; emits the `accessibility-checks.md` table (covers BRAND-02).
- [ ] No ExUnit/framework install needed — stdlib only.

*(If the maintainer prefers, the script can live as a `mix` task later; for this phase a bare `.exs` is the lowest-ceremony correct choice.)*

## Security Domain

Not applicable in the conventional sense — this phase touches no `lib/`, no protocol surface, no auth boundary, no input handling (per REQUIREMENTS.md Out-of-Scope: "Any change to `lib/` security seams, public API, or protocol surface"). The only security-adjacent concern is **brand-as-security-discipline**: the red-team lens must verify the book never reintroduces a forbidden over-claim ("unhackable/bulletproof/military-grade/zero-risk/SAML is easy") in any sample copy. The book currently complies (§22 enforces it); the lens confirms no leakage. ASVS categories do not apply to a Markdown-only deliverable.

## Sources

### Primary (HIGH confidence)
- W3C WCAG 2.2 — Understanding SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html — thresholds, luminance + ratio formulas, large-text definition, 0.04045 note
- W3C WCAG 2.2 — Understanding SC 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html — 3:1 rule, no-rounding rule, boundary exemption
- Computed contrast ratios — Elixir, ran on this machine (2026-06-14), both `0.03928` and `0.04045` thresholds, no verdict change
- Radix Colors — scale composition: https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale — 5-tier functional model, mutable-alias dark parity
- GitHub Primer — color overview: https://primer.style/foundations/color/overview — base→functional→component hierarchy, contrast-against-muted discipline
- GitHub Brand Toolkit — logo: https://brand.github.com/foundations/logo — monochrome-first restraint, no-effects, misuse list

### Secondary (MEDIUM confidence)
- Adrian Roselli, "WCAG3 Contrast as of April 2026" — APCA/WCAG3 status (years away, ~2030): https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html
- Eric Eggert, "WCAG 3 is not ready yet": https://yatil.net/blog/wcag-3-is-not-ready-yet
- jcklpe/open-source-branding-toolkit — OSS branding-needs framing: https://github.com/jcklpe/open-source-branding-toolkit

### Tertiary (LOW confidence)
- IBM Plex / Atkinson Hyperlegible / JetBrains Mono open-font licensing claims in the brand book itself (§9) — `[ASSUMED]`-grade until the licensing phase (60/63) verifies SIL OFL terms before any CDN load; not gating for this audit.

## Metadata

**Confidence breakdown:**
- WCAG thresholds & math: HIGH — verified against official W3C Understanding docs + computed on this machine.
- Computed palette ratios: HIGH — reproducible Elixir script; both threshold constants tested.
- Design-system rubrics: HIGH — Radix/Primer/GitHub official docs.
- Specific remediation hexes: MEDIUM — math-correct, but final hue choice is a design judgment the maintainer should confirm in `decision-log.md`.
- OSS-credibility transfer: MEDIUM — principles are well-sourced; application to Relyra is interpretive (and the phase ships no asset).

**Research date:** 2026-06-14
**Valid until:** ~2026-12-14 (WCAG 2.2 is stable; design-system docs are stable; APCA/WCAG3 status worth re-checking in 6 months but won't become the gate before this milestone ships)
