# Investigation: v1.7 Adoption Evidence Demo Roadmap

Status: READY FOR NEW MILESTONE
Priority: HIGH
Trigger: Private maintainer adoption signal, 2026-06-12
Depends: Phase 50 adoption evidence shipped; v1.6 Adoption Truth shipped

## Trigger

The post-v1.6 default was pause until public adopter demand or maintenance. A
private maintainer signal changed the next-step assessment: adoption confidence is
blocked not by missing protocol features, but by lack of a realistic runnable demo
application and high-level end-to-end proof that can be clicked, seeded, stressed,
and run locally/CI.

The desired next milestone is not "more docs" and not a protocol bundle. It is a
realistic Phoenix SaaS demo app that proves the Relyra journey before real
external adopters arrive.

## Current Repo Truth

- Relyra is still near done for its core SAML SP scope: strict login, IdP-init,
  SLO, encrypted assertions, signed redirect AuthnRequests, four presets, generic
  SAML runbook, Ecto production path, LiveAdmin, trace tools, security/conformance
  gates.
- Phase 50 shipped real maintainer adoption evidence: golden host fixtures,
  `test/adoption/journey_01`-`05`, `examples/quickstart.exs`, `mix ci.demo`,
  `mix ci.integration`, and Keycloak external IdP CI.
- Existing evidence is strong but not a runnable adopter demo:
  - `test/fixtures/demo_host/` is fixture code compiled only in test.
  - `examples/quickstart.exs` is repo-local, `MIX_ENV=test`, FakeIdP based, and
    excluded from Hex.
  - Keycloak proof uses real Keycloak SSO form and production ACS logic, but posts
    the final IdP payload through `Phoenix.ConnTest`, not a launched Phoenix app.
  - `journey_04` proves Ecto connection resolution, but request/replay stores still
    use ETS in the adoption fixture runtime.
- No open GitHub issues or PRs were visible during the assessment. This is a
  private adoption-evidence trigger, not public protocol demand.

## Selected Next Milestone

**v1.7 Adoption Evidence Demo** is the recommended next milestone.

Goal:

Build a repo-local but user-runnable Phoenix SaaS demo app, tentatively
`demo/ledger_loop`, that proves the full Relyra adoption journey in a realistic
B2B SaaS domain:

- install/setup path
- tenant SSO setup
- customer IT/admin self-service where it makes sense
- Relyra LiveAdmin/operator flows
- realistic seeded tenants/users/groups/mappings/cert states/audit history
- Ecto-backed production stores, including request and replay stores
- local FakeIdP proof and optional Keycloak external IdP proof
- browser E2E and Docker-based local run

The demo should be evidence infrastructure and evaluator aid, not a hosted broker
product and not a new public protocol surface.

## Demo Shape

Recommended domain:

- Product: LedgerLoop, a B2B SaaS finance/operations app.
- Customer tenant: Northstar Health.
- Personas:
  - platform engineer integrating Relyra
  - customer IT admin configuring SSO
  - support/operator diagnosing login failures
  - end user completing SAML login

Recommended app placement:

- `demo/ledger_loop/`
- path dependency on the local Relyra package
- excluded from Hex package files
- runnable with `mix phx.server` and Docker Compose

Recommended experience:

- App home with seeded tenant selector and login entrypoint.
- Customer-facing SSO setup checklist/receipt page owned by the host demo app.
- Mounted Relyra LiveAdmin for operator/admin trust-state work.
- Attribute/group mapping preview using realistic seeded claims.
- Connection test status and trace handoff after login.
- Seeded failure states for at least one support/trace scenario.

Design posture:

- Quiet, dense, operational SaaS UI.
- No marketing hero page. First screen should be the usable demo.
- Avoid decorative card-heavy composition; prioritize workflow clarity, scannable
  tenant/provider state, and deterministic controls.

## Docker And Local DX

The demo milestone should explicitly solve local port and Docker friction because
this repo may run alongside other Elixir OSS demos.

Recommended defaults:

- Compose project-name isolation via `COMPOSE_PROJECT_NAME`.
- Env-interpolated ports, e.g. `DEMO_WEB_PORT`, `DEMO_DB_PORT`,
  `DEMO_KEYCLOAK_PORT`.
- No fixed `container_name`.
- Compose profiles:
  - `core`: Phoenix demo + Postgres
  - `keycloak`: external IdP path
  - `browser`: Playwright/E2E helpers if useful
- Healthchecks for Postgres, Phoenix, and Keycloak readiness.
- `scripts/demo` (or equivalent) with:
  - `up`
  - `down`
  - `reset`
  - `test`
  - `urls`
  - `doctor`
- Startup output should print important URLs and seeded credentials:
  - app home
  - SSO setup page
  - Relyra admin
  - trace page
  - Keycloak admin

## Proof Obligations

Minimum acceptance evidence for v1.7:

- Demo app compiles and boots locally.
- Seeds produce deterministic tenants, users, groups, connection state, mappings,
  cert states, and audit/trace data.
- Ecto connection resolver and Ecto request/replay stores are used in the demo
  happy path.
- Local proof can complete without Keycloak using deterministic FakeIdP support.
- Optional Keycloak profile completes a real external IdP happy path.
- Browser E2E covers:
  - customer/admin setup or checklist flow
  - operator sees connection in LiveAdmin
  - end-user SAML login receipt
  - support/operator opens a login trace
- CI adds a focused demo lane such as `mix ci.demo_app` without weakening existing
  `mix ci.security` hollow-gate invariants.
- Docker doctor catches port conflicts or prints exact env overrides.

## Non-Goals

- Do not add a hosted broker runtime.
- Do not move a customer-admin portal into Relyra core until demo evidence proves
  reusable library surface is needed.
- Do not bundle AUTHN-POST, KMS, or SIGNED-META into this milestone.
- Do not add new first-class providers unless preset code, runbook, vocabulary,
  and proof all ship together from a real demand signal.
- Do not change `Relyra.start_login/3`, `consume_response/3`, or published
  behaviour callback shapes unless explicitly escalated.
- Do not relax signature, XML parse, crypto, replay, audit, or trust-source
  invariants.

## Candidate Research Summary

| Candidate | Rank Now | Why |
| --- | --- | --- |
| Adoption Evidence Demo | 1 | Private adoption signal; closes the gap between strong hidden CI proof and a realistic runnable user/evaluator experience. |
| Self-Service Admin Polish | 2 | Valuable after demo shows which host-owned customer setup screens are actually reusable. Start in demo, do not promote to core prematurely. |
| AUTHN-POST-01 | Demand-gated | Highest protocol wedge when an IdP rejects redirect signed AuthnRequests. Redirect signing already ships; no public issue now. |
| KMS-01 | Demand-gated | Valuable for enterprise key custody. Needs additive CEK unwrap seam, not merely another PEM-returning `KeyResolver`. |
| SIGNED-META-01 | Demand-gated | High value for academic/InCommon federation. Narrow without a federation adopter. |

## Important Technical Notes From Candidate Research

AUTHN-POST:

- `start_login/3` currently emits redirect launch data.
- AuthnRequest XML `ProtocolBinding="HTTP-POST"` is the requested response
  binding, not outbound request transport.
- If triggered later, POST AuthnRequest support should remain opt-in, keep
  redirect byte-for-byte unchanged, return a form descriptor/post params, and
  prove enveloped XMLDSig over exact emitted AuthnRequest bytes.

KMS:

- Current `Relyra.KeyResolver` returns plaintext PEM.
- True non-exportable KMS support needs an additive CEK unwrap contract or new
  `KeyUnwrapper` behaviour.
- Preserve opaque `:decryption_failed`; never leak provider errors, CEK, PEM, or
  ciphertext into logs/diagnostics.
- Metadata/public certificate matching is a real footgun: KMS public keys are not
  automatically SAML-ready X.509 certs.

SIGNED-META:

- SP metadata export exists but is unsigned.
- Inbound IdP metadata-root verification already exists.
- If triggered, scope is signed `EntityDescriptor` plus federation extensions and
  an InCommon-style runbook, not just "wrap metadata with a signature."

## Recommended New-Milestone Prompt

When running `$gsd-new-milestone`, use this intent:

> Start v1.7 Adoption Evidence Demo. Build a realistic runnable Phoenix SaaS demo
> app for Relyra under `demo/ledger_loop`, with deterministic seeds, Docker DX,
> Ecto production stores, mounted LiveAdmin, customer/admin setup flow, local
> FakeIdP proof, optional Keycloak external IdP proof, browser E2E, and docs. Keep
> protocol work out of scope. Treat the demo as evidence infrastructure and
> adopter/evaluator aid, not a hosted broker product.

## Shift-Left / Config

No config mutation is required before the milestone. Existing `.planning/config.json`
already has adopter-first milestone assessment defaults:

- `workflow.milestone_next_step.adopter_lens`
- `workflow.milestone_next_step.parallel_repo_research`
- `workflow.milestone_next_step.retain_threads_and_retrospective`
- `workflow.milestone_assessment.no_auto_new_milestone`
- demand-gated requirements list: AUTHN-POST-01, KMS-01, SIGNED-META-01

The new durable signal is this thread plus `STATE.md`, `PROJECT.md`,
`MILESTONE-ARC.md`, and `SEED-001-adoption-evidence-demo.md`.
