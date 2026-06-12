---
id: SEED-001
status: dormant
planted: 2026-06-12
planted_during: between-milestones after Phase 50
trigger_when: next $gsd-new-milestone after private adoption-evidence signal
scope: large
---

# SEED-001: v1.7 Adoption Evidence Demo

## Why This Matters

Relyra is near done for its stated SAML SP scope, but adoption confidence is now
blocked by lack of a realistic runnable Phoenix SaaS demo. Current evidence is
strong but maintainer-oriented: test fixtures, `examples/quickstart.exs`,
adoption journey tests, and a Keycloak ConnTest lane. A demo app would let
maintainers and evaluators run, click, seed, stress, and inspect the main Relyra
journey before real adopters arrive.

## When to Surface

**Trigger:** next `$gsd-new-milestone` after private adoption-evidence signal.

Use this seed to start v1.7 / Phase 51 unless a higher-priority security or
maintenance incident appears first.

## Scope Estimate

**Large** — full milestone.

Expected scope: realistic Phoenix demo app, deterministic seeds, Docker DX,
Ecto production stores, mounted LiveAdmin, host-owned customer/admin setup flow,
local FakeIdP proof, optional Keycloak external IdP proof, browser E2E, and docs.

## Breadcrumbs

- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `test/fixtures/demo_host/`
- `test/adoption/`
- `examples/quickstart.exs`
- `docker/keycloak/`
- `lib/relyra/live_admin/`

## Notes

Selected roadmap order:

1. v1.7 Adoption Evidence Demo.
2. Self-service admin polish only after demo evidence shows reusable gaps.
3. AUTHN-POST-01, KMS-01, SIGNED-META-01 stay demand-gated.

Non-goals: hosted broker, protocol bundle, new first-class providers without
named demand, public API shape changes, or relaxing any security invariant.
