# Relyra Brandbook

The self-contained brand & design system for **Relyra** — a strict-by-default SAML 2.0
Service Provider library for Elixir/Phoenix. Everything here is vector-first, repo-safe,
and dogfoods its own tokens. Built in milestone **v1.8** (phases 58–63).

> Tagline: **Enterprise SAML, calmly verified.** · Name is always title-case **Relyra**.

## Preview it

No build step. Open the HTML files directly:

- `index.html` — the **brand book**: logo usage, color (with WCAG contrast badges), typography,
  spacing/radius/shadow, UI components in every state, microcopy & voice, and developer notes.
  Has a Light / Dark / System toggle.
- `logo-lab.html` — the **logo selection gallery**: the four explored directions (kept for the record).
- `examples/components.html` — copy-ready component markup.
- `examples/landing-page-section.html` — a marketing hero + feature section.

```sh
open brandbook/index.html        # macOS
# or just double-click the file
```

Fonts (IBM Plex Sans Condensed, Atkinson Hyperlegible, JetBrains Mono) load from Google Fonts
over CDN — **no font binaries are committed**.

## What's here

| Path | What it is |
| --- | --- |
| `index.html` | Standalone HTML brand book (the main artifact). |
| `logo-lab.html` | Logo direction selection gallery. |
| `assets/logo-*.svg` | The logo system (direction A — Relying Path monogram): `logo-primary`, `logo-stacked`, `logo-mark`, `logo-mark-mono`, `logo-primary-inverse`, `logo-typemark`, `logo-with-tagline`, `favicon`. All transparent / cage-free. |
| `assets/logo-lab/*.svg` | The four explored directions (A/B/C/D) from the selection round. |
| `assets/exdoc-logo.png`, `assets/exdoc-favicon.png` | Raster marks for ex_doc (HexDocs requires PNG). |
| `assets/social-card.{svg,png}` | OpenGraph share card (1200×630). |
| `assets/readme-banner.svg` | The header banner used at the top of the repo `README.md`. |
| `tokens/tokens.json` | Design tokens (primitive + semantic, light/dark, type, space, radius, shadow, motion, focus ring). |
| `tokens/tokens.css` | The tokens as `--rl-*` CSS custom properties (light default + dark + reduced-motion). |
| `tokens/tailwind.example.js` | Copy-ready Tailwind `theme.extend` mapping for Phoenix consumers. |
| `notes/decision-log.md` | The pressure-test findings + the **Canonical Lock Set** (one value per role — the source of truth). |
| `notes/accessibility-checks.md` | Every color pair with its computed WCAG ratio + pass/fail. |
| `notes/contrast.exs` | The re-runnable WCAG contrast script (`elixir brandbook/notes/contrast.exs`). |
| `notes/research.md` | Cited brand / design-system / accessibility research. |
| `notes/logo-options.md` | Why direction A won + the logo usage rules. |

## Using the tokens in an app

1. Ship `tokens/tokens.css` (or copy its `:root` block). Reference semantic colors as
   `var(--rl-text)`, `var(--rl-action)`, `var(--rl-verified)`, etc. — never raw hex.
2. Dark mode is automatic: the CSS responds to `prefers-color-scheme` and a manual
   `[data-theme="dark"]` hook. No per-component overrides needed.
3. For Tailwind, start from `tokens/tailwind.example.js` (it points at the same CSS vars,
   so dark mode is inherited).

## Re-running the accessibility gate

```sh
elixir brandbook/notes/contrast.exs   # prints every pair + verdict; exits non-zero on a must-pass failure
```

## Rules that matter

- **Logomarks are never caged** in a rectangle/box — they ship transparent and float free.
  (A *marketing banner* with a background panel — e.g. `social-card`, `readme-banner` — is a
  separate artifact and is fine.)
- The **primary lockup carries no subtitle**; use `logo-with-tagline.svg` when a tagline is needed.
- Don't recolor off-brand, stretch, add shadows, re-typeset "Relyra", or introduce forbidden
  imagery (lyre/music/shield/padlock/key/flame/bird/…). Full rules in `notes/logo-options.md`.

## License / attribution

These brand assets are part of the Relyra repository (MIT). The "Relyra" name and logo are the
project's identity — reuse the *code/tokens* freely; don't pass off the *mark* as your own project.
Fonts are not redistributed here (loaded via CDN); they are licensed under the SIL Open Font License
by their respective authors (IBM, Braille Institute, JetBrains).

---

*Brandbook v1.8 · source of truth = `notes/decision-log.md` Canonical Lock Set.*
