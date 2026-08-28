# Phase 70 — UI Review

**Audited:** 2026-08-26  
**Baseline:** [70-UI-SPEC.md](70-UI-SPEC.md)  
**Screenshots:** not captured. A server was present at `localhost:3000`, but the required git-safe screenshot directory did not exist and this audit was limited to writing this review. The deterministic Chromium visual contract was run instead: `npm run demo:trace-visual` passed (1/1) with no retained temporary output.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | The conditional CTA, boundary sentence, receipt, empty state, and recovery link use the exact contract language. |
| 2. Visuals | 2/4 | **WARNING:** Both login jobs are ordinary inline links; their declared button classes have no CSS treatment or 44px target. |
| 3. Color | 3/4 | **WARNING:** Tokens and link focus color are correct, but the primary/optional actions do not receive the intended accent action treatment. |
| 4. Typography | 4/4 | The touched LedgerLoop surfaces use the specified 14/16/20/28px scale and 400/600 weights. |
| 5. Spacing | 2/4 | **WARNING:** the two touched action wrappers use arbitrary `2rem` (32px) margins instead of the declared 24px route-affordance spacing. |
| 6. Experience Design | 2/4 | **WARNING:** the new keyboard-focusable evidence region has no visible focus indicator, despite being the required narrow-viewport access path. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Give both login CTAs a shared native-link action style with a 44px minimum height.** The FakeIdP and optional Keycloak actions are currently small inline links, which weakens discoverability and can miss the touch-target contract. Add the existing accent/border/padding/focus treatment to `.route-affordance .button` without changing native-anchor semantics.
2. **Add a visible `:focus-visible` treatment for the Login Trace evidence region.** Keyboard users can focus the scroll region but receive no visible indicator. Target `[data-testid="login-trace-evidence-region"]:focus-visible` with the same accessible outline token used for links and buttons.
3. **Replace the two inline `margin: 2rem 0` wrappers with token-aligned layout spacing.** Use the existing grid gap or a `24px` (`lg`) layout rule so the route-affordance conforms to its declared spacing scale and avoids duplicated arbitrary inline styles.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

No copy defect found. The initial and conditional login labels are exact and appear in the required document order in `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex:11-22`. The host-boundary sentence is exact at line 7, and the durable receipt heading/body exactly match the contract in `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex:50-53`. The inherited trace empty state and back-link copy match at `lib/relyra/live_admin/connection_trace_live.ex:50-71`.

### Pillar 2: Visuals (2/4)

**WARNING — action hierarchy and target sizing are not implemented.** `login.html.heex:12,19` assigns `button`, `button-primary`, and `button-secondary`, but `app.css` contains no selectors for those classes. The two user jobs consequently render as ordinary underlined inline links, rather than as distinct, comfortably sized route actions. The only related 44px action CSS applies to workspace navigation and the back link (`app.css:140-163`), not these CTAs. This misses the contract's conditional-action visual-accessibility backstop.

The semantic hierarchy otherwise holds: a labelled `main`, heading, explanatory copy, and native labelled links are present. The deterministic Chromium gate confirms the real failed flow, recovery, and narrow evidence path rather than relying on color as proof (`demo/ledger_loop/test/browser/trace_visual.spec.ts:12-100`).

### Pillar 3: Color (3/4)

**WARNING — the intended action color hierarchy is incomplete.** The LedgerLoop token palette matches the contract (`app.css:2-11`), global anchors use Relay Blue (`app.css:32-35`), and focus uses the same accent (`app.css:38-42`). However, because the route action classes are undefined, neither sign-in CTA receives the declared action background/border treatment; the accent appears only as standard link text. This leaves the two primary user jobs visually weaker than the documented 60/30/10 hierarchy.

The Login Trace's legacy hard-coded colors remain outside Phase 70 restyling scope, as explicitly allowed by `70-UI-SPEC.md`; they are not included in this score deduction.

### Pillar 4: Typography (4/4)

No typography defect found on the Phase 70 touched LedgerLoop surfaces. `app.css:44-48,76-88,108-121,140-155` implements the contract's 14px supporting text, 16px body/control text, 20px panel headings, and 28px page heading with regular/semibold weights. The inherited Login Trace's legacy type choices are explicitly excluded from Phase 70 presentation restyling.

### Pillar 5: Spacing (2/4)

**WARNING — non-token action spacing.** The contract assigns `lg` (24px) to route-affordance spacing, but the two action wrapper divs use `margin: 2rem 0` (32px) in `login.html.heex:11,18`. This duplicates layout control that the parent already provides with a 16px grid gap and produces a non-declared spacing value. Other touched LedgerLoop layout values follow the scale: panels use 24px padding and 16px gaps (`app.css:91-105`), with mobile bottom spacing at 32px (`app.css:174-183`).

### Pillar 6: Experience Design (2/4)

**WARNING — keyboard focus is not visibly exposed for the evidence scroller.** The new narrow-viewport access surface is correctly semantic and focusable (`role="region"`, label, and `tabindex="0"` at `connection_trace_live.ex:98-104`), and Chromium proves it scrolls to the final Duration column at 360px (`trace_visual.spec.ts:65-90`). But the global visible-focus rule targets only `a` and `button` (`app.css:38-42`), so this focusable `div` receives no visible focus treatment. This conflicts with the contract's requirement to preserve visible keyboard focus for the evidence access path.

The rest of the automated state coverage is strong and requires no human UAT: the browser gate proves typed `digest_mismatch` rejection, no false receipt/workspace success, recovery navigation, native details toggling, narrow horizontal access, and safe long values (`trace_visual.spec.ts:25-100`). It passed during this audit, and its temporary output directory was absent after completion. The gate is recurring in `.github/workflows/demo-app-e2e.yml:80-83` with attachments disabled by `playwright.trace-visual.config.mjs:20-25`.

---

## Registry Safety

Registry audit: skipped — `components.json` is absent and `70-UI-SPEC.md` declares no shadcn or third-party registry content.

---

## Files Audited

- `70-UI-SPEC.md`, Phase 70 plans and summaries, and `70-CONTEXT.md`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex`
- `demo/ledger_loop/priv/static/assets/css/app.css`
- `lib/relyra/live_admin/connection_trace_live.ex`
- `demo/ledger_loop/test/browser/keycloak.spec.ts`
- `demo/ledger_loop/test/browser/fake_idp.spec.ts`
- `demo/ledger_loop/test/browser/trace_visual.spec.ts`
- `scripts/test_trace_visual_e2e.sh`, `playwright.trace-visual.config.mjs`, `package.json`, and `.github/workflows/demo-app-e2e.yml`
