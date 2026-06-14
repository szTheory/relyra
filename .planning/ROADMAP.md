# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for Elixir/Phoenix. The v1.x arc is shipped through **v1.7 — Adoption Evidence Demo** (including post-milestone phases 57 and 57.1). The active milestone is **v1.8 — Brand System & Identity**: convert the decision-complete brand book into a self-contained, repo-safe `brandbook/` package — rendered logos, design tokens, a standalone HTML brand book — plus a small set of real-world integrations. No protocol surface, public API, or security-posture change.

## Milestones

- Complete: **v0.1 - SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 - Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 - LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 - IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 - Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 - Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 - External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 - Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 - Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 - Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 - Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 - Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 - Adoption Evidence Demo** (shipped 2026-06-13, Phases 51-57.1). See `.planning/milestones/v1.7-ROADMAP.md`.
- Active: **v1.8 - Brand System & Identity** (Phases 58-63).

## Phases

**Phase Numbering:** Integer phases are planned milestone work; decimal phases are urgent insertions executing between their surrounding integers. Phases 58-63 are the v1.8 milestone.

### v1.8 Brand System & Identity

- [ ] **Phase 58: Brand Foundation Pressure-Test & Decision Lock** - Audit and lock palette, typography, voice, and accessibility with a decision log
- [ ] **Phase 59: Logo System & Selection Checkpoint** - Render all four directions in a gallery, checkpoint for user logo pick, develop full lockup set
- [ ] **Phase 60: Design Tokens** - Publish tokens.json, tokens.css, and a Tailwind/daisyUI mapping
- [ ] **Phase 61: HTML Brand Book & Component Examples** - Ship standalone brandbook/index.html with full specimens, states, microcopy, and copy-ready examples
- [ ] **Phase 62: Real-World Integration** - Wire logo/favicon into HexDocs, ship social card and README banner, reskin ledger_loop demo
- [ ] **Phase 63: QA, Repo Hygiene & Ship** - Optimize SVGs, enforce repo-size budget, verify mix qa, close milestone

## Phase Details

### Phase 58: Brand Foundation Pressure-Test & Decision Lock
**Goal**: The existing brand book is audited across design, accessibility, and adversarial lenses, with every color pair WCAG-verified and the palette, type stack, and voice locked as the authoritative input for all downstream artifacts.
**Depends on**: Phase 57.1 (v1.7 close)
**Requirements**: BRAND-01, BRAND-02, BRAND-03
**Success Criteria** (what must be TRUE):
  1. A decision log captures every pressure-test finding with an explicit ship/reject/defer disposition for each item raised.
  2. Every brand color pair (foreground/background, light and dark) has a documented WCAG contrast result with a clear pass or fail label for both text (4.5:1) and non-text (3:1) thresholds.
  3. Token sprawl and contradictions in the brand book are resolved: the palette, type scale, and voice are each represented by exactly one canonical definition with no competing alternatives.
  4. The decision log is committed to the repo as the single source of truth that downstream phases (tokens, brand book, integration) refer to.
**Plans**: TBD

### Phase 59: Logo System & Selection Checkpoint
**Goal**: All four logo directions are rendered as transparent, cage-free SVGs viewable in a `logo-lab.html` gallery; the maintainer selects one direction; the chosen direction is developed into the full lockup set with documented usage rules.
**Depends on**: Phase 58
**Requirements**: LOGO-01, LOGO-02, LOGO-03
**Success Criteria** (what must be TRUE):
  1. `logo-lab.html` opens in a browser and displays all four directions (Relying Path monogram, Assertion Frame, Trust Path, integrated typemark) side-by-side at multiple sizes and in light, dark, and monochrome colorways, with no rectangular cages.
  2. The maintainer completes a selection checkpoint — picking one winning direction before the full lockup set is developed — and that choice is recorded.
  3. The winning direction is developed into the complete lockup set: primary horizontal (no subtitle), stacked, mark-only, monochrome, inverse, favicon, an optional tagline lockup, and an integrated typemark — all as SVG files.
  4. Logo usage rules are documented covering clear-space, minimum sizes, approved colorways, mark-to-logotype spacing, and a misuse don'ts section (no rectangular cages, no forbidden imagery).
**Plans**: TBD
**UI hint**: yes

### Phase 60: Design Tokens
**Goal**: Design tokens are published as `tokens.json` and `tokens.css` covering the full semantic token set, plus a Tailwind/daisyUI framework mapping so a Phoenix consumer can adopt them without re-deriving values.
**Depends on**: Phase 58
**Requirements**: TOKEN-01, TOKEN-02
**Success Criteria** (what must be TRUE):
  1. `tokens.json` and `tokens.css` are committed under `brandbook/` and cover color primitives, semantic color (light/dark maps), focus ring, type scale, spacing, radius, border, shadow, and motion — with every token justified and no sprawl.
  2. A Tailwind/daisyUI example file maps the tokens so a Phoenix developer can copy it into their project and get correct brand colors and type without re-deriving any values.
  3. Light and dark mode tokens are correctly separated: a consumer switching between modes sees the right semantic values without overriding anything manually.
**Plans**: TBD

### Phase 61: HTML Brand Book & Component Examples
**Goal**: A standalone, responsive `brandbook/index.html` presents the complete brand system with full component specimens across all interaction states, microcopy examples, and copy-ready component/page references derived from the tokens.
**Depends on**: Phase 59, Phase 60
**Requirements**: BOOK-01, BOOK-02, BOOK-03
**Success Criteria** (what must be TRUE):
  1. `brandbook/index.html` opens from `file://` with no build step and renders correctly in light, dark, and system-preference modes via a toggle — using only scoped CSS, no external dependencies.
  2. The brand book presents logo usage, the color palette (with contrast badges matching the Phase 58 WCAG results), the type scale, and spacing/radius/shadow specimens in a single scrollable document.
  3. UI component specimens show every interaction state (hover, focus, active, disabled, loading, error, empty, selected, skeleton) in both light and dark mode.
  4. Microcopy do/don't examples and developer implementation notes are included alongside the component specimens.
  5. `brandbook/examples/` provides at least one copy-ready component reference, one landing-page-section reference, and one README-header reference — all derived from the tokens.
**Plans**: TBD
**UI hint**: yes

### Phase 62: Real-World Integration
**Goal**: The brand logo and favicon appear on HexDocs, an OpenGraph social card and README banner ship as optimized assets, and the `ledger_loop` demo is reskinned with brand tokens — the only phase that modifies files outside `brandbook/`.
**Depends on**: Phase 59, Phase 60
**Requirements**: INTEG-01, INTEG-02, INTEG-03
**Success Criteria** (what must be TRUE):
  1. `mix docs` (ex_doc) produces output where the Relyra brand logo and favicon are visible on the generated HexDocs site at `hexdocs.pm/relyra` — confirmed via the local `doc/` output.
  2. An optimized OpenGraph social card and a README header banner are committed as brand assets and referenced in `README.md`.
  3. The `demo/ledger_loop` app renders with brand tokens replacing the placeholder `--ll-*` CSS variables, and `mix ci.demo_app` stays green with no visual regressions.
**Plans**: TBD
**UI hint**: yes

### Phase 63: QA, Repo Hygiene & Ship
**Goal**: All SVGs are optimized, the repo-size budget is enforced, the diff is clean, `brandbook/README.md` documents every artifact, `mix qa` exits 0, and the milestone is closed out.
**Depends on**: Phase 61, Phase 62
**Requirements**: QA-01, QA-02
**Success Criteria** (what must be TRUE):
  1. All SVGs in `brandbook/` pass svgo optimization with no file exceeding reasonable size limits, and no font binaries are present anywhere in the repo.
  2. Total `brandbook/` directory size stays within the ~1 MB budget, verified by a committed size check.
  3. `brandbook/README.md` is present and documents every artifact in the directory with instructions for previewing the brand book locally.
  4. `mix qa` exits 0 with no new warnings introduced by v1.8 changes.
**Plans**: TBD

## Progress

**Execution Order:** 58 → 59 → 60 → 61 → 62 → 63

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 58. Brand Foundation Pressure-Test & Decision Lock | 0/TBD | Not started | - |
| 59. Logo System & Selection Checkpoint | 0/TBD | Not started | - |
| 60. Design Tokens | 0/TBD | Not started | - |
| 61. HTML Brand Book & Component Examples | 0/TBD | Not started | - |
| 62. Real-World Integration | 0/TBD | Not started | - |
| 63. QA, Repo Hygiene & Ship | 0/TBD | Not started | - |
