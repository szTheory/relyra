# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for Elixir/Phoenix. The v1.x arc is shipped through **v1.7 — Adoption Evidence Demo**. There is **no active milestone**: future protocol work is demand-gated (a real GitHub issue is required to start), and dormant follow-ups in `.planning/seeds/` surface at the next `/gsd:new-milestone`.

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
- Complete: **v1.7 - Adoption Evidence Demo** (shipped 2026-06-13, Phases 51-56, 23 plans, 30/30 requirements). See `.planning/milestones/v1.7-ROADMAP.md`.

## Active Milestone

**None — paused.** Future protocol scope is demand-gated; do not run `/gsd:new-milestone` for coverage-gated features. Save-for-demand: AUTHN-POST-01, KMS-01, SIGNED-META-01.

Dormant follow-ups (in `.planning/seeds/`, surface at next `/gsd:new-milestone`):
- **SEED-002** — resolve the `Relyra.TestSupport` vs Hex-package contradiction (document the exclusion, or ship an escalation-gated public `Relyra.Testing`).
- **SEED-003** — finish-or-remove the demo FakeIdP login WIP (`/fake_idp/*` routes unwired).

## Phases

No active milestone phases. v1.7 phase detail (goals, success criteria, plans, coverage, progress) is archived at `.planning/milestones/v1.7-ROADMAP.md`.

**Phase Numbering:** integer phases are planned milestone work; decimal phases are urgent insertions executing between their surrounding integers. The next milestone continues after the highest shipped phase, **Phase 56**.

### Phase 57: Demo FakeIdP Browser-Login Proof

**Goal:** As a LedgerLoop demo evaluator, I want to click the Log in with SSO button and complete a real browser round-trip through a built-in fake IdP, so that I see Relyra cryptographically verify a signed SAML assertion end-to-end and surface a typed rejection on the tampered variant without configuring an external IdP.
**Mode:** mvp
**Requirements**: SEED-003
**Depends on:** Phase 56

**Scope / hard constraints:**
- DEMO-LOCAL SAML signer in `demo/ledger_loop` (its own demo IdP keypair) whose cert matches the IdP signing cert on the enabled connection fixture (`LedgerLoop.Demo.Fixtures`, scenario `01H0B4Y1A2B3C4D5E6F7G8H9J0`) so Relyra's strict signature verification passes. **Cert-trust alignment is the crux.**
- **Do NOT** expose `Relyra.TestSupport.FakeIdP` outside `:test` — that's the SEED-002 packaging/security-posture escalation, explicitly out of scope. Keep relyra's `prod_elixirc_paths` `test_support` exclusion intact.
- Wire `/fake_idp/login` (GET) + `/fake_idp/sso` (POST) into the demo router. Parked WIP on branch `wip/demo-fake-idp` is a starting point, but its `Relyra.TestSupport.FakeIdP.sign/1` call must be replaced with the demo-local signer.
- Success variant: valid signed assertion → logged-in session. Failure variant: tampered signature → Relyra typed rejection surfaced in the demo trace UI (`/relyra/admin/connections/:id/trace`).
- Tests in-process (`Phoenix.ConnTest`/`LiveViewTest`, no Wallaby); rides existing `demo-app-ci.yml` → `mix ci.demo_app`, no new CI; demo suite stays green (currently 37/0).

**Plans:** 3/3 plans complete

Plans:
- [x] 57-01-PLAN.md - Wave-0 prerequisites: demo keypair/cert, fixture cert-trust + idp_sso_url alignment, LoginTrace.attach
- [x] 57-02-PLAN.md - Demo-local SAML signer via relyra public C14N (byte-compat pass + tamper -> :digest_mismatch)
- [x] 57-03-PLAN.md - Wire /fake_idp/* routes + SP-initiated end-to-end flow (success round-trip + tampered/trace) + affordance repoint

### Phase 57.1: Address Phase 57 tech debt: tamper guard, label, input hardening, repo hygiene (INSERTED)

**Goal:** Close the correctness, robustness, and hygiene debt the Phase 57 code review surfaced on the demo FakeIdP browser-login proof — confined to `demo/ledger_loop`, no Relyra core/API/security-posture change. Harden the tamper guard so it can never silently fail (false-negative rejection proof), correct the lying login label, escape/bound/catch all untrusted input on the unauthenticated FakeIdP endpoints, and clean up dangling repo state.

**Success Criteria:**
- `tamper/1` raises (not silently no-ops) when it cannot locate `<NameID>`, with a test proving today's output still tampers and a drifted template raises.
- Valid-login label matches the emitted `name_id` (`sarah@northstar.example.com`); no label advertises an unseeded subject.
- `response_xml/3` XML-escapes interpolated values; the `InResponseTo` extractor rejects non-`ID`-grammar input; crafted `SAMLRequest` no longer produces malformed emitted XML.
- Unknown `idp_action` values resolve to the success path (no `CaseClauseError`/500).
- `inflate/1` fails closed to `nil` on oversized decompressed output (no unbounded zip-bomb amplification).
- `keypair.ex` raises a descriptive error on an unexpected PEM shape.
- `test/support/poll.ex` is committed (or removed with rationale); stale `wip/demo-fake-idp` branch deleted.
- `mix qa` and `mix ci.demo_app` stay green.

**Requirements**: TBD (tech-debt remediation — derived from 57-REVIEW.md WR-01..05, IN-02, IN-03)
**Depends on:** Phase 57
**Plans:** 1/3 plans executed

Plans:
- [x] 57.1-01-PLAN.md — Signer + keypair hardening: WR-05 raise-on-no-op tamper guard, WR-01 response_xml/3 escaping, IN-02 descriptive PEM error
- [ ] 57.1-02-PLAN.md — Controller boundary hardening: WR-04 bounded safeInflate, IN-03/WR-01 NCName extractor, WR-03 idp_action catch-all, WR-02 login label
- [ ] 57.1-03-PLAN.md — Repo hygiene: commit test/support/poll.ex + add its root unit test, delete stale wip/demo-fake-idp branch
