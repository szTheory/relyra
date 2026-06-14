/*
 * Relyra — EXAMPLE Tailwind theme.extend (copy, don't depend on this file).
 *
 * How to use in a Phoenix consumer:
 *   1. Import the CSS variables once (e.g. in app.css):  @import "relyra/tokens.css";
 *   2. Copy the `theme.extend` below into your tailwind.config.js.
 *   3. Choose a dark-mode strategy:
 *        - darkMode: 'media'  -> follows prefers-color-scheme automatically, or
 *        - darkMode: 'class'  -> toggle with <html data-theme="dark"> (the CSS
 *                                 manual hook) plus Tailwind's class strategy if you
 *                                 also want `dark:` variants.
 *
 * Semantic colors point at var(--rl-*), so dark mode is handled by tokens.css —
 * a consumer gets light/dark parity "for free" without re-deriving any hex here.
 * The few raw brand hexes below (relay, ink, paper, ...) are convenience aliases for
 * the fixed primitives; they do NOT shift with theme. Source of truth for every value
 * is the Phase 58 Canonical Lock Set (brandbook/notes/decision-log.md).
 *
 * Reminder (D-04): `info` == `action` (Relay Blue). Never distinguish an info callout
 * from a clickable action by color alone — always add an icon + label affordance.
 */

module.exports = {
  // darkMode: 'media',   // or 'class' if you toggle [data-theme="dark"] manually
  theme: {
    extend: {
      colors: {
        // Semantic — follow tokens.css (light/dark aware via CSS vars).
        bg: "var(--rl-bg)",
        surface: "var(--rl-surface)",
        "surface-subtle": "var(--rl-surface-subtle)",
        text: "var(--rl-text)",
        "text-muted": "var(--rl-text-muted)",
        border: "var(--rl-border)",
        divider: "var(--rl-divider)",
        action: "var(--rl-action)",
        "action-emphasis": "var(--rl-action-emphasis)",
        link: "var(--rl-link)",
        verified: "var(--rl-verified)",
        focus: "var(--rl-focus)",
        caution: "var(--rl-caution)",
        success: "var(--rl-success)",
        warning: "var(--rl-warning)",
        error: "var(--rl-error)",
        info: "var(--rl-info)",

        // Fixed brand primitives (theme-independent convenience aliases).
        ink: "#101827",
        graphite: "#263245",
        paper: "#FCFBF7",
        mist: "#EEF2F6",
        relay: "#3454D1",
        "deep-relay": "#1D2E82",
        "proof-teal": "#147D77",
        "keyline-violet": "#6D5DF2",
        "accessible-border": "#7E8A9A",
        "soft-line": "#D8E0EA",
        "certificate-gold": "#9A6B1C",
      },

      fontFamily: {
        display: [
          "IBM Plex Sans Condensed",
          "IBM Plex Sans",
          "system-ui",
          "sans-serif",
        ],
        body: [
          "Atkinson Hyperlegible",
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "sans-serif",
        ],
        code: [
          "JetBrains Mono",
          "ui-monospace",
          "SFMono-Regular",
          "Menlo",
          "Consolas",
          "monospace",
        ],
      },

      fontSize: {
        hero: ["4rem", { lineHeight: "1", fontWeight: "700" }],
        h1: ["2.75rem", { lineHeight: "1.05", fontWeight: "700" }],
        h2: ["2rem", { lineHeight: "1.12", fontWeight: "600" }],
        h3: ["1.5rem", { lineHeight: "1.2", fontWeight: "600" }],
        "body-lg": ["1.1875rem", { lineHeight: "1.55" }],
        body: ["1rem", { lineHeight: "1.55" }],
        small: ["0.875rem", { lineHeight: "1.45", fontWeight: "500" }],
        caption: ["0.78rem", { lineHeight: "1.4", fontWeight: "500" }],
        code: ["0.875rem", { lineHeight: "1.55", fontWeight: "500" }],
      },

      spacing: {
        2: "2px",
        4: "4px",
        8: "8px",
        12: "12px",
        16: "16px",
        24: "24px",
        32: "32px",
        48: "48px",
        64: "64px",
        96: "96px",
        128: "128px",
      },

      borderRadius: {
        sm: "8px",
        md: "12px",
        lg: "16px",
        full: "9999px",
      },

      borderWidth: {
        hairline: "1px",
        regular: "2px",
      },

      boxShadow: {
        // Light shadows; tokens.css swaps the var-driven equivalents in dark mode.
        sm: "0 1px 2px rgba(16,24,39,0.06)",
        md: "0 1px 2px rgba(16,24,39,0.06), 0 8px 24px rgba(16,24,39,0.06)",
      },

      transitionDuration: {
        fast: "120ms",
        base: "180ms",
        slow: "220ms",
      },

      transitionTimingFunction: {
        standard: "cubic-bezier(0.2,0,0,1)",
      },

      outlineWidth: {
        focus: "2px",
      },
      outlineOffset: {
        focus: "2px",
      },
    },
  },
};
