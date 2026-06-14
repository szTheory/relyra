# Requirements: Relyra v1.8 Brand System & Identity

**Defined:** 2026-06-14
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. (This milestone makes the brand that *communicates* that value real and repo-safe — without touching the protocol, public API, or security posture.)

## v1.8 Requirements

Requirements for the Brand System & Identity milestone. Each maps to exactly one roadmap phase. "Maintainer" = the person running this milestone; "adopter/evaluator" = a developer assessing Relyra on GitHub / HexDocs.

### Brand Foundation

- [ ] **BRAND-01**: The existing brand book (`prompts/relyra-brand-book.md`) is pressure-tested across design, accessibility, and red-team lenses, with findings and explicit ship/reject/defer dispositions captured in a decision log.
- [ ] **BRAND-02**: Every brand color pair (light and dark) is WCAG-checked for text and non-text contrast, with pass/fail results documented.
- [ ] **BRAND-03**: Final palette, typography stack, and voice are locked — token sprawl removed and contradictions resolved — as the authoritative input for every downstream artifact.

### Logo System

- [ ] **LOGO-01**: All four logo directions (Relying Path monogram, Assertion Frame, Trust Path, integrated typemark) are rendered as transparent, cage-free SVGs and viewable side-by-side in a `logo-lab.html` gallery at multiple sizes and colorways.
- [ ] **LOGO-02**: The maintainer selects one direction, which is developed into a complete lockup set: primary horizontal (no subtitle), stacked, mark-only, monochrome, inverse, favicon, an optional separate tagline lockup, and an integrated typemark.
- [ ] **LOGO-03**: Logo usage rules are documented — clear-space, minimum sizes, approved colorways, mark↔logotype spacing, and misuse don'ts (including no rectangular cages and no forbidden imagery).

### Design Tokens

- [ ] **TOKEN-01**: Design tokens are published as `tokens.json` and `tokens.css` covering color (primitive + semantic), light/dark maps, focus ring, type, spacing, radius, border, shadow, and motion — with every token justified (no sprawl).
- [ ] **TOKEN-02**: A framework example (Tailwind/daisyUI theme) maps the tokens so a Phoenix consumer can adopt them without re-deriving values.

### HTML Brand Book

- [ ] **BOOK-01**: A standalone, responsive `brandbook/index.html` opens from `file://` with scoped CSS and a light/dark/system toggle, presenting logo usage, color (with contrast badges), the type scale, and spacing/radius/shadow specimens.
- [ ] **BOOK-02**: The brand book demonstrates UI components across all states (hover/focus/active/disabled/loading/error/empty/selected/skeleton) in both modes, plus microcopy do/don't examples and developer implementation notes.
- [ ] **BOOK-03**: `examples/` provides copy-ready component, landing-page-section, and README-header references derived from the tokens.

### Real-World Integration

- [ ] **INTEG-01**: HexDocs (ex_doc) renders the brand logo and favicon for `hexdocs.pm/relyra`.
- [ ] **INTEG-02**: An OpenGraph social card and a README header banner ship as optimized brand assets.
- [ ] **INTEG-03**: The `ledger_loop` demo app is reskinned with brand tokens (replacing the placeholder `--ll-*` vars) and still renders correctly.

### QA & Repo Hygiene

- [ ] **QA-01**: All SVGs are optimized, the repo-size budget is enforced, the diff contains no unrelated changes, and no font binaries are committed.
- [ ] **QA-02**: `brandbook/README.md` documents every artifact and how to preview it; `mix qa` exits 0; and the milestone is closed out.

## Future Requirements

Deferred; tracked but not in this milestone's roadmap.

### Brand (future)

- **BRAND-F01**: Animated/motion brand assets (e.g. a verified-path loader) beyond static motion-token guidance.
- **BRAND-F02**: A full icon library implementing the brand book's 19-icon spec (this milestone ships only icons the brand book / components demonstrably need).

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Committed font binaries | Repo-size + licensing; document the open-source stack and load via CDN in the HTML instead. |
| PDF brand book | HTML is the chosen deliverable — diffable, checked into git, opens locally. |
| Rebrand / new name / new tagline | The brand book is decision-complete; this milestone renders and pressure-tests it, it does not re-found the brand. "Relyra" + "Enterprise SAML, calmly verified." are locked. |
| Any change to `lib/` security seams, public API, or protocol surface | v1.8 is brand/design only; security invariants and SemVer are untouched. |
| Design-tool source files (Figma/Sketch) | Vector-first SVG/HTML/CSS are the source of truth; no proprietary binary design files. |
| A built front-end stack/bundler for the brand book | Standalone HTML + scoped CSS; no build system added for brand assets. |

## Traceability

Which phases cover which requirements. Finalized during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-01 | Phase 58 | Pending |
| BRAND-02 | Phase 58 | Pending |
| BRAND-03 | Phase 58 | Pending |
| LOGO-01 | Phase 59 | Pending |
| LOGO-02 | Phase 59 | Pending |
| LOGO-03 | Phase 59 | Pending |
| TOKEN-01 | Phase 60 | Pending |
| TOKEN-02 | Phase 60 | Pending |
| BOOK-01 | Phase 61 | Pending |
| BOOK-02 | Phase 61 | Pending |
| BOOK-03 | Phase 61 | Pending |
| INTEG-01 | Phase 62 | Pending |
| INTEG-02 | Phase 62 | Pending |
| INTEG-03 | Phase 62 | Pending |
| QA-01 | Phase 63 | Pending |
| QA-02 | Phase 63 | Pending |

**Coverage:**
- v1.8 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-06-14*
*Last updated: 2026-06-14 at milestone v1.8 start*
