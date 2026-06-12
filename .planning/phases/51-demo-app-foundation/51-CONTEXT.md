# Phase 51: demo-app-foundation - Context

**Gathered:** 2026-06-12 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 51 creates the runnable Phoenix application foundation for the LedgerLoop demo at `demo/ledger_loop`: local path dependency on Relyra, first-screen workspace shell, clear host-owned SAML route mount, mounted operator route scope, health/readiness endpoints, and Hex package exclusion. It does not seed the full Northstar Health story, wire Ecto request/replay happy-path behavior, implement customer setup workflows, complete browser SAML login, add Docker/CI proof, or write public demo docs; those are scoped to Phases 52-56.
</domain>

<decisions>
## Implementation Decisions

### Demo App Boundary
- **D-01:** Create only the conventional Phoenix app foundation at `demo/ledger_loop`, with Relyra loaded from the repository as a path dependency and with enough routing/UI to prove the app boots as a host application.
- **D-02:** Keep seeded data, durable Relyra store proof, browser FakeIdP proof, optional Keycloak proof, Docker orchestration, and demo guide polish out of Phase 51 except for explicit placeholders or route affordances needed by the first-screen shell.

### UX And Route Shape
- **D-03:** Build the first screen as the actual `LedgerLoop Workspace`, not a marketing landing page.
- **D-04:** The first screen must expose tenant/status information and reachable setup, login, Relyra admin, and support affordances, following the approved Phase 51 UI contract.
- **D-05:** Mount Relyra SAML routes under the host-owned `/saml` scope and make that route ownership visible in the workspace UI.
- **D-06:** Mount the operator admin route scope at `/relyra/admin`, using Relyra LiveAdmin's router macro and a host-owned scope provider/repo configuration.
- **D-07:** Add health/readiness endpoints suitable for Docker or CI polling, with text-distinguishable booted/ready/unavailable states in the UI.

### Existing Assets To Reuse
- **D-08:** Use existing adoption fixtures, installer parity tests, and LiveAdmin browser support as implementation references, but do not copy test-only modules wholesale into the demo app.
- **D-09:** Treat `Relyra.TestSupport` and `examples/quickstart.exs` as later-phase proof references only. Phase 51 should not depend on `MIX_ENV=test` or test-only FakeIdP modules to boot the demo foundation.

### Packaging And Repo Integration
- **D-10:** Keep `demo/ledger_loop` repo-local and excluded from Hex through the existing explicit `mix.exs` package whitelist model, not through fragile ignore-file assumptions.
- **D-11:** Make demo package exclusion inspectable during planning/execution so Phase 51 can prove the demo remains runnable from the repo while absent from package contents.

### Store And Login Proof Sequencing
- **D-12:** Expose the later integration points for Ecto connection/request/replay stores and local browser login proof, but leave actual durable login behavior to Phase 52 and browser SAML proof to Phase 54.
- **D-13:** Preserve the v1.7 requirement that the eventual demo happy path uses Ecto connection, request, and replay stores. Existing adoption fixtures prove useful patterns but currently still use ETS for request/replay in parts of the path, so the demo must not inherit that as its final happy-path posture.

### the agent's Discretion
- Planner may choose the exact Phoenix scaffold command and app module names, provided the app lands under `demo/ledger_loop`, compiles as a normal Phoenix app, and uses Relyra via local path dependency.
- Planner may choose whether Phase 51 route destinations are simple controllers, LiveViews, or placeholders, as long as the first screen exposes all required affordances and later phases can replace placeholders without route churn.
- Planner may choose the exact health/readiness response body shape, provided Docker/CI can distinguish booted from unavailable state and the UI uses explicit status text.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md`
- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`
- `.planning/seeds/SEED-001-adoption-evidence-demo.md`
- `mix.exs`
- `lib/relyra/phoenix/router.ex`
- `lib/relyra/live_admin/router.ex`
- `lib/relyra/test_support.ex`
- `lib/relyra/connection_resolver/ecto.ex`
- `lib/relyra/request_store/ecto.ex`
- `lib/relyra/replay_store/ecto.ex`
- `test/fixtures/demo_host/lib/demo_host_web/router.ex`
- `test/support/live_admin_test_support.ex`
- `test/support/adoption_fixtures.ex`
- `test/adoption/journey_01_install_parity_test.exs`
- `test/adoption/journey_04_ecto_production_path_test.exs`
- `test/adoption/journey_05_liveadmin_smoke_test.exs`
- `test/adoption/keycloak/keycloak_saml_journey_test.exs`
- `examples/quickstart.exs`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Phoenix.Router.saml_routes/1` mounts metadata, login, and ACS endpoints inside whatever host scope owns the integration. For the demo, the outer host scope should be `/saml`.
- `Relyra.LiveAdmin.Router.relyra_admin_routes/2` already owns the mounted operator surface and defaults to `/relyra/admin`; the demo should provide repo and scope-provider options instead of inventing an admin UI shell in Phase 51.
- `test/fixtures/demo_host/` and `test/adoption/journey_01_install_parity_test.exs` show the current minimal host-app wiring and installer output expectations.
- `test/support/live_admin_test_support.ex` demonstrates a working LiveAdmin router, endpoint, and scope-provider pattern.
- `examples/quickstart.exs` demonstrates the headless FakeIdP trust-path proof but is explicitly maintainer-only and test-environment bound.

### Established Patterns
- Relyra keeps Phoenix, LiveView, Ecto, and Oban optional in the library; the demo app may depend on Phoenix/Ecto directly because it is a host application, not core library surface.
- The package whitelist in `mix.exs` is the authoritative Hex inclusion mechanism. Adding `demo/ledger_loop` should not affect package output unless the whitelist is changed.
- Security-sensitive CI aliases preserve hollow-gate safeguards by running security suites as independent `cmd mix test` processes. Phase 51 should not modify those gates.
- The approved UI contract requires plain Phoenix templates/LiveView components, restrained operational styling, explicit status text, and no Tailwind/shadcn/React dependency in this phase.

### Integration Points
- `Relyra.ConnectionResolver.Ecto` resolves persisted connection records from a host repo and should shape later demo connection wiring.
- `Relyra.RequestStore.Ecto` and `Relyra.ReplayStore.Ecto` require fixed host-owned table names through opts; Phase 52 should wrap these with demo modules so request parameters never influence storage targets.
- `Relyra.TestSupport.FakeIdP` and the Keycloak adoption support are later proof inputs, not Phase 51 boot dependencies.
- The first-screen route affordances should remain stable for later Phase 52-55 replacement: setup, login, Relyra admin, support, `/healthz`, and `/readyz`.
</code_context>

<specifics>
## Specific Ideas

- Use the Phase 51 UI contract labels verbatim where applicable: `Open SSO Setup`, `Start Test Login`, `Open Relyra Admin`, `Open Support Scenario`, `Mounted SAML routes: /saml`, `Mounted operator routes: /relyra/admin`, `Demo health`, and `Demo readiness`.
- Treat `Northstar Health SSO status` as visible shell content even if Phase 52 later supplies the deterministic tenant data.
- Keep FakeIdP and Keycloak copy off the Phase 51 first screen except as disabled/future-link text when a route is present but proof is not implemented yet.
</specifics>

<deferred>
## Deferred Ideas

- Deterministic LedgerLoop / Northstar Health seeds, cert states, audit rows, and trace scenarios remain Phase 52.
- Ecto request/replay store wrappers and happy-path persistence proof remain Phase 52.
- Customer/admin SSO setup UX, receipts, support handoff, and full UX polish remain Phase 53.
- In-browser FakeIdP login proof remains Phase 54.
- Docker scripts, Compose profiles, CI demo lane, browser E2E, and optional Keycloak proof remain Phase 55.
- README and demo guide entrypoints remain Phase 56.

### Reviewed Todos (not folded)
None - no matching pending todos were found for Phase 51.
</deferred>
