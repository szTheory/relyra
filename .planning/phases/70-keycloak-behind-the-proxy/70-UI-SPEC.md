---
phase: 70
slug: keycloak-behind-the-proxy
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-26
---

# Phase 70 — UI Design Contract

> Retroactive visual and interaction contract for the optional public-Keycloak proof. Phase 70's visual contract applies only to the touched conditional login affordance and durable workspace receipt. Login Trace is an inherited evidence surface: Phase 70 constrains its copy and proof interaction, not its pre-existing presentation.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — existing Phoenix/HEEx and hand-authored CSS |
| Preset | not applicable |
| Component library | none |
| Icon library | none |
| Font | Helvetica, Arial, sans-serif (implemented demo stack); the Canonical Lock Set's body/UI family is Atkinson Hyperlegible for future token work |

The project is not React, Next.js, or Vite; the shadcn initialization gate does not apply. Reuse `demo/ledger_loop/priv/static/assets/css/app.css`, native links, and native buttons for Phase 70's touched affordance/receipt surfaces. The existing LiveView Login Trace is not restyled in this phase.

---

## Spacing Scale

Declared values (all multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Reserved for compact inline gaps on touched surfaces |
| sm | 8px | Reserved for compact affordance/receipt gaps |
| md | 16px | Shared action horizontal padding and panel grid gaps surrounding the receipt |
| lg | 24px | Route-affordance, workspace-panel, and section padding |
| xl | 32px | Mobile page bottom spacing |
| 2xl | 48px | Desktop page bottom spacing |
| 3xl | 64px | Reserved only for a future page-level break; not introduced by this phase |

Exceptions: interactive route-affordance links and buttons require a 44px minimum target height/width where the existing shared action treatment is applied. The optional Keycloak link remains a native link with a visible focus state; its final target sizing is a visual-accessibility backstop because it is conditionally rendered.

---

## Typography

Use exactly these four sizes and two weights for the Phase 70 conditional affordance and durable receipt, following the shared LedgerLoop CSS.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label / supporting UI | 14px | 400 or 600 | 1.5 |
| Body / control | 16px | 400 or 600 | 1.5 |
| Panel heading | 20px | 600 | 1.2 |
| Page heading | 28px | 600 | 1.2 |

Weights: regular 400 and semibold 600 only. Do not introduce a third UI type scale or a display treatment on the Phase 70 affordance or receipt.

---

## Color

Apply the existing light-mode LedgerLoop tokens and their intended 60/30/10 hierarchy to Phase 70's touched affordance and receipt surfaces only.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Paper `#FCFBF7` | Page background, route-affordance surface, readable default canvas |
| Secondary (30%) | Mist `#EEF2F6` | Workspace header and subtle panel treatment |
| Accent (10%) | Relay Blue `#3454D1` | Links, route actions, and focus outline on touched surfaces |
| Destructive | Error `#B42318` | No destructive action is introduced in this phase |

Supporting tokens: primary text Ink `#101827`; secondary text Graphite `#263245`; interactive borders Accessible Border `#7E8A9A`. Never use decorative Soft Line `#D8E0EA` as the only interactive boundary.

Accent reserved for: actionable links and buttons, visible keyboard focus, the FakeIdP primary action, and the conditional Keycloak test link. It is not evidence that verification succeeded: the receipt sentence and explicit trace outcomes carry that meaning.

### Inherited Login Trace presentation

`Relyra.LiveAdmin.ConnectionTraceLive` is pre-existing and intentionally outside Phase 70 visual-restyling scope. Its inline legacy values—including `#0066cc`, `#c62828`, `#ffebee`, `#ddd`, and `#fafafa`; 13px/14px/28px sizes; bold weight; and 2px/12px spacing—are not approved Phase 70 tokens. The Phase 70 contract retains only its evidence and copy requirements below.

---

## Copywriting Contract

Keep the exact locked copy below. Copy is deliberately explicit about the host boundary and must never imply a browser authorization cookie.

| Element | Copy |
|---------|------|
| Default-path CTA | `Simulate Login via FakeIdP` — the always-present, deterministic default test path; render it first in document order. |
| Optional-path CTA | `Test with Keycloak (optional real IdP)` — show only when the stable provisioned Keycloak connection is enabled; render it after FakeIdP as a native labelled link to that connection-scoped SAML login. |
| Context sentence | `Relyra verifies SAML trust; LedgerLoop owns user mapping and records a session-establishment receipt.` |
| Verified receipt heading | `Verified sign-in receipt` |
| Verified receipt body | `Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.` |
| Empty state heading | `No login attempts recorded yet — traces appear after the first SAML response is consumed.` |
| Error state | The Login Trace displays the query's exact error message: `Connection record was not found` or `Relyra admin repo is unavailable`. Recover using `← Back to connection` to return to the connection-detail route; after correcting the connection URL/selection or restoring the configured admin repo, revisit the trace. The UI exposes no retry control. |
| Destructive confirmation | None — this phase adds no destructive user action. |

---

## Interaction and Accessibility Contract

- `/login/test` presents two distinct jobs without backend topology: the always-available FakeIdP path appears first; the optional Keycloak path follows it only after provisioning. Both currently use the same native-link presentation because the applied `button-primary` and `button-secondary` class names have no shared CSS definitions; document order, exact labels, and conditional presence communicate the task distinction. When unavailable, omit the Keycloak control rather than showing a disabled or broken link.
- Initiating the optional link follows one public journey: `relyra.localhost` → `keycloak.relyra.localhost` → exact connection-scoped ACS → LedgerLoop workspace. Do not expose container DNS, direct Keycloak ports, metadata URLs, certificates, or raw SAML payloads in the UI.
- Use native anchors for navigation and preserve their accessible names. Keyboard focus must remain visibly outlined; no color-only success indication is permitted.
- The workspace receipt proves a verified sign-in and durable host receipt only. The Login Trace separately exposes the newest successful correlation's `Validate response`, `Verify signature`, and `Replay check` rows. Do not add decode, mapping, cookie, authorization, or session claims to that canonical trace proof.
- Login Trace supports populated cards, an empty state, and a load-error state. Its pre-existing open native `<details>` disclosure and table of step, outcome, error code, and duration remain an inherited presentation; Phase 70 requires only that it surface the specified evidence and exact copy.

---

## UI Considerations

> Populated by the ui-phase UI-consideration probe (Step 9.5). Empty-state and
> error-state copy remains in `## Copywriting Contract`; these rows reference that
> contract rather than duplicating its text.

Applicable state considerations resolved: 11 covered, 3 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|-------------|--------|---------------------|
| loading | E1 — `/login/test` route affordance | ✅ covered | The server-rendered page has no in-place fetch or submit state; native anchors hand navigation progress to the browser and remain unchanged until navigation begins. |
| error | E1 — `/login/test` route affordance | 🧪 backstop | { statement: "A route/browser check must confirm a failed login destination cannot leave a false-success state and exposes a recoverable typed or transport failure.", verification: backstop } |
| overflow | E1 — `/login/test` route affordance | ✅ covered | Each fixed-label action occupies its own block container inside the bounded route-affordance layout, so the two jobs never compete on one line. |
| long-text | E1 — `/login/test` route affordance | ✅ covered | Exact action labels use native wrapping with no nowrap, clipping, truncation, or ellipsis rule. |
| overflow | E2 — durable workspace receipt | ✅ covered | The receipt is a normal paragraph inside the responsive workspace grid; the grid collapses to one column at 720px and does not impose clipping or truncation. |
| long-text | E2 — durable workspace receipt | ✅ covered | The exact receipt sentence wraps and reflows as paragraph text; it is never shortened or ellipsized. |
| empty | E3 — Login Trace | ✅ covered | With zero traces and no query error, render the Copywriting Contract's exact no-attempts state. |
| loading | E3 — Login Trace | ✅ covered | Trace loading is a synchronous server-side query during LiveView parameter handling; the rendered outcome is populated, empty, or error, with no separate client-side loading state. |
| error | E3 — Login Trace | ✅ covered | Query failure renders one of the Copywriting Contract's exact messages and preserves `← Back to connection` as the recovery route. |
| populated | E3 — Login Trace | ✅ covered | Render up to the newest 20 login correlations as open cards with step, outcome, error-code, and duration rows; Phase 70 requires validation, signature, and replay evidence under the same newest successful correlation. |
| partial | E3 — Login Trace | ✅ covered | Render every exported step present in a correlation; absent outcome, error-code, or duration values display `—` rather than collapsing the row or inventing data. |
| overflow | E3 — Login Trace | 🧪 backstop | { statement: "A narrow-viewport visual check must confirm trace cards and their four-column step table remain operable and no evidence becomes inaccessible when content exceeds the inherited container.", verification: backstop } |
| zero-one-many | E3 — Login Trace | ✅ covered | Zero traces use the empty state; one trace renders one card; many traces stack at 16px gaps in newest-first order, capped at 20, while the summary reports the rendered count. |
| long-text | E3 — Login Trace | 🧪 backstop | { statement: "A held-out visual check with long correlation, cause, step, and error-code values must confirm wrapping or horizontal access without hiding security evidence.", verification: backstop } |

<!-- Status vocabulary:
     ✅ covered   → explicit truth lifted into must_haves.truths
     🧪 backstop  → held-out/visual evidence required; no evidence means human_needed
     ⚠ unresolved → planner assumption surfaced explicitly; none remain here -->

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no shadcn or third-party registry content is used |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS (one accepted non-blocking recommendation)
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved — 2026-08-26
