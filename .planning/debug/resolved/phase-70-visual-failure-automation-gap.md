---
status: resolved
trigger: "G-70-2: Automated inspection found no executable browser assertions for failed destination, keyboard, narrow viewport, or long values; they remain manual prose-only backstops."
created: 2026-08-26T00:00:00-04:00
updated: 2026-08-26T22:42:11Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

bug_class: bohrbug
known_pattern_candidate: none (MemPalace unavailable; no local knowledge base exists)
hypothesis: CONFIRMED — Phase 70 deliberately retained failed-destination, narrow-viewport, and long-value UI requirements as prose backstops, and its sole Keycloak spec has only a happy-path test. Existing deterministic failure and trace UI seams were never composed into a credential-safe browser fixture.
test: Playwright enumeration and source-level mapping of UAT Test 2 to current browser specs, trace UI selectors, exports, and CI.
expecting: One Keycloak happy-path test; separate deterministic FakeIdP failure only; no visual/keyboard/long-data execution.
next_action: Return root-cause report; implementation is out of diagnose-only scope.

candidate_causes:
  - code: keycloak.spec.ts implements only the positive journey and no trace UI interaction/viewport assertions.
  - config: playwright.fake-idp.config.mjs lacks authenticated trace fixture inputs and permits retry trace capture, so it cannot safely host Basic-auth trace checks as-is.
  - data: demo reset provides a short seeded failure; LoginTrace.Export hashes correlation IDs and omits unknown steps, so no long safe browser fixture exists for all prose examples.
and_gate: no — the reporting gap is fully explained by the omitted automated acceptance suite; fixture/config changes are consequences needed for a safe correction, not independent causes of its absence.

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Exercise a failed Keycloak journey and inspect Login Trace with keyboard navigation, a narrow viewport, and long values. No false success or receipt remains after failure; recovery is clear and all evidence stays visible and operable.
actual: Automated inspection found no executable browser assertions for failed destination, keyboard, narrow viewport, or long values; they remain manual prose-only backstops.
errors: None reported.
reproduction: Test 2 in .planning/phases/70-keycloak-behind-the-proxy/70-UAT.md.
started: Discovered during UAT on 2026-08-26.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-26T00:00:00-04:00
  checked: Active debug sessions and project state
  found: No active debug session existed; Phase 70 is the active completed plan set and the reported issue is scoped to its browser/UI verification.
  implication: A new diagnose-only session can investigate the Phase 70 test seams without conflicting with another debug session.
- timestamp: 2026-08-26T00:06:00-04:00
  checked: Semantic and keyword knowledge-base recall
  found: MemPalace CLI is unavailable and .planning/debug/knowledge-base.md does not exist.
  implication: No prior resolution is available as a hypothesis candidate.
- timestamp: 2026-08-26T00:08:00-04:00
  checked: 70-UAT.md, 70-VERIFICATION.md, 70-UI-SPEC.md, and Plans 70-07/70-08
  found: UAT Test 2 exactly names failed destination, keyboard, narrow viewport, and long values. The UI spec and plans mark failed destination, narrow trace, and long trace evidence as visual backstops; verification explicitly says they require a human.
  implication: The missing automation is intentional plan/test-scope debt, not an unreported runtime failure.
- timestamp: 2026-08-26T00:11:00-04:00
  checked: demo/ledger_loop/test/browser/keycloak.spec.ts and playwright.keycloak-proxy.config.mjs
  found: The Keycloak project enumerates one happy-path test: public IdP origin, exact ACS POST, workspace receipt, and three successful trace steps. It has no failed flow, keyboard operation, viewport setting, geometry assertion, long-value fixture, or trace error/recovery assertion. Attachments and reporter output are disabled and the harness deletes its temporary output directory.
  implication: The credential-bearing Keycloak proof has the needed authenticated trace navigation seam but cannot satisfy UAT Test 2 as written.
- timestamp: 2026-08-26T00:14:00-04:00
  checked: demo/ledger_loop/test/browser/fake_idp.spec.ts and fake_idp_flow_test.exs
  found: The FakeIdP browser spec deterministically submits a tampered assertion, asserts ACS 400 and digest_mismatch, and asserts no workspace; its companion ExUnit test proves no LoginReceipt and a failed Login Trace event with signature.verify/error digest_mismatch.
  implication: A reproducible failure seam already exists without needing to manufacture or retain a Keycloak SAML response.
- timestamp: 2026-08-26T00:17:00-04:00
  checked: lib/relyra/live_admin/connection_trace_live.ex and lib/relyra/login_trace/export.ex
  found: Trace cards and rows have stable data-testid selectors, native details disclosure, and a Back to connection anchor. The UI has a fixed four-column table with no responsive overflow wrapper. Export hashes correlation IDs and emits only a fixed known step set, while cause and error_code can carry safe long fixture values.
  implication: Keyboard and viewport assertions are deterministic browser checks; a raw long correlation or arbitrary long step name cannot be a valid fixture because the trace's security contract intentionally hashes/drops them. The long-value backstop must use the rendered correlation hash plus safe long cause/error-code values.
- timestamp: 2026-08-26T00:19:00-04:00
  checked: playwright.fake-idp.config.mjs and .github/workflows/demo-app-e2e.yml
  found: FakeIdP browser E2E self-boots the demo app and runs recurring CI, but it has no admin credentials and its retry trace capture remains enabled. The Keycloak project's admin transition uses ephemeral Basic credentials in memory, no attachments, list-only reporting, and a deleted per-run output directory.
  implication: A new authenticated trace-browser fixture must inherit the Keycloak artifact policy; extending the existing FakeIdP config without disabling attachments would risk retaining Basic authorization material.
- timestamp: 2026-08-26T00:22:00-04:00
  checked: npx playwright test --config=playwright.keycloak-proxy.config.mjs --list and --config=playwright.fake-idp.config.mjs --list
  found: Keycloak enumerates exactly one positive test; FakeIdP enumerates a valid test and a tampered-failure/no-workspace test. Neither enumerates trace recovery, keyboard, narrow-width, or long-value assertions.
  implication: The hypothesis is directly confirmed by executable test discovery, without requiring Docker or credentials.
- timestamp: 2026-08-26T00:25:00-04:00
  checked: demo reset/seeds, runtime admin configuration, and demo-app-e2e CI workflow
  found: mix ecto.setup invokes LedgerLoop.Demo.Reset.reset!/0, making an opt-in safe visual-trace seed deterministic at browser-server boot. Runtime config accepts non-empty DEMO_ADMIN credentials, while demo-app-e2e already runs FakeIdP Playwright on every PR/push.
  implication: A separate visual-trace project can be recurring CI without Docker/Keycloak, provided it creates ephemeral credentials outside source, disables attachment channels, and removes its output directory.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "Phase 70's browser acceptance coverage is intentionally incomplete: Plans 70-07/70-08 designated failed-destination, narrow-viewport, and long-evidence checks as manual visual backstops, while demo/ledger_loop/test/browser/keycloak.spec.ts contains only one happy-path Keycloak journey. Although FakeIdP supplies a deterministic typed-rejection/no-receipt seam and ConnectionTraceLive supplies stable selectors, no credential-safe browser fixture combines them with authenticated trace access, safe long rendered values, keyboard operation, and viewport assertions."
fix: "Add a dedicated non-Keycloak trace-visual Playwright fixture built from the deterministic FakeIdP tamper path and a test-only safe long-trace seed; keep the real Keycloak credential-bearing happy-path proof unchanged. Configure the new Basic-auth browser project with ephemeral credentials, trace/video/screenshot off, list-only reporter, and deleted per-run output. Assert no workspace/receipt after failure, exact typed rejection and Back recovery, keyboard disclosure operation, narrow-width accessibility, and visible safe long cause/error-code values."
verification: "Diagnosis only; no fix applied."
files_changed: []
