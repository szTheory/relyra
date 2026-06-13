# Relyra Milestone Arc — v0.3 → v1.0

*Multi-milestone vision plan, written 2026-05-06 at v0.3 kickoff. Authoritative until updated; supersedes prior in-line "Next Milestone" sketches in PROJECT.md and the original idea-doc roadmap line for v0.5/v0.6.*

## North Star

**Feature complete, batteries included, usable in production by Phoenix SaaS teams without becoming SAML experts.**

That means an adopter can:

- `mix relyra.install` and ship the boring path in a day.
- Configure their first IdP through an admin UI without writing custom LiveView.
- Accept either SP-initiated or IdP-initiated SSO from major providers.
- Operate the system day-2 (refresh, rollover, alerts) without bespoke scripts.
- Pass an enterprise SAML checklist (SLO, audit trail, security review).

## Adoption-blocker priority

In descending order of how much each missing piece blocks adoption today:

1. **No admin UI** — every adopter rebuilds the same five admin screens. Biggest single multiplier.
2. **No IdP-initiated SSO** — kills certain enterprise deals outright (Entra app dashboards, legacy workforce SAML).
3. **Manual operational toil** — refresh, bulk ops, debug bundles, expiry alerts. Quality-of-life, not deal-blocking.
4. **No SLO** — enterprise checkboxes; rarely a hard blocker until late-stage RFPs.
5. **No external security review / conformance** — required for v1.0 credibility, not for adoption.

## Milestone arc

| Milestone | Theme | Why this slot |
|-----------|-------|---------------|
| **v0.3** | **LiveView admin surface** | Biggest adoption multiplier. v0.2 stabilized storage; exactly the moment the UI on top is unblocked. Ends "every adopter rebuilds the same admin screens." |
| **v0.4** | **IdP-initiated SSO + opaque RelayState** | Unlocks deal types v0.1's SP-only posture excluded. Touches trust core — ships before v1.0 review so it gets time under field use. |
| **v0.5** | **Operational maturity** | Once admin UI ships, the loudest follow-on demand is "automate the toil." Includes scheduled metadata refresh (CFG-08), bulk ops across connections (CFG-07), debug bundles, expiry alerts, mapping templates. |
| **v0.6** | **SLO + ops-maturity carryover** (DIAG-01 + CERT-EXP-01) | Final SAML protocol surface piece, plus the v0.5 operational-maturity carryovers (debug bundles + expiry alerts) re-scoped from v0.5 by Phase 21.2 per the v0.5 milestone audit. SLO kept late because it's a trust-boundary feature; pairs naturally with v1.0 security review. |
| **v1.0** | **External security review + conformance + docs polish** | Kantara/Liberty conformance, third-party security audit, all CVE regression fixtures, adopter case studies, final adopter onboarding pass. |

## Two judgment calls (recorded for future-you)

- **v0.4 = IdP-initiated, not ops.** Compatibility is a hard yes/no for sales; ops maturity is quality-of-life. You can survive without scheduled refresh if expiry alerts work; you cannot survive a deal saying "we require IdP-initiated."
- **SLO at v0.6, not v0.5** (push from the original idea-doc plan). After admin UI ships, the loudest demand is automation, not protocol. SLO also benefits from being adjacent to the v1.0 security review.

## v0.3 in detail (this milestone)

**Goal:** Ship a complete LiveView admin surface so an adopter can mount one router and get end-customer self-service for every v0.2 capability — connections, metadata, certificates, mappings, audit ledger.

**Scope:**

1. Connection CRUD + lifecycle UI (draft → enabled → disabled), tenant-scoped — surfaces CFG-01.
2. Metadata source UI — paste XML / paste URL, import history with last-known-good visible, refresh button — surfaces CFG-03.
3. Certificate inventory + staged rollover UI — view active/next/retired, expiry warnings, "promote next" / "retire active" with conflict-aware locking — surfaces CFG-04.
4. Attribute/group mapping editor with revision history view — surfaces CFG-05.
5. Audit ledger timeline view — filter by connection / actor / event type, redaction-safe display.
6. Provider preset prefill at connection creation (Okta, Entra ID, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, Keycloak).
7. `Relyra.LiveView.Router` macro + mount/auth pattern — adopters mount with one router line; auth boundary delegated to host app via the existing `SessionAdapter` philosophy.
8. Strict-defaults visibility — `legacy_algorithm_policy` overrides surfaced with risk panels per the PROJECT.md compatibility constraint.
9. (Ride-along) `MappingCommands.append_audit/8` explicit `repo.rollback/1` to match the other three co-commit sites — closes v0.2 carryover tech debt.

**Out of scope for v0.3 (deferred per arc):**

- Bulk ops across connections (CFG-07) → v0.5.
- Scheduled metadata refresh automation (CFG-08) → v0.5.
- IdP-initiated SSO → v0.4.
- SLO → v0.6.
- Login UI / branded sign-in flows — host-app territory; out of project scope entirely.

## Evolution of this document

Update at every milestone close. If the arc shifts (e.g. customer demand reorders ops vs IdP-init, or a new requirement bumps SLO earlier), capture the date, the trigger, and the new ordering. Don't delete prior versions — strike through and annotate.

## Current Status

- `v0.3` shipped 2026-05-06
- `v0.4` shipped 2026-05-06
- `v0.5` shipped 2026-05-07
- `v0.6` shipped 2026-05-08
- `v1.0` shipped 2026-05-08
- `v1.1` shipped 2026-05-25 as an out-of-band security milestone that closed the published XMLDSig auth-bypass and staged its disclosure trail
- `v1.3` through `v1.6` shipped the advanced federation, SLO/ops, publish/prove/polish, and Adoption Truth arc. Phase 50 then shipped maintainer adoption evidence (golden host + Keycloak external IdP CI).

Next candidate: **v1.7 Adoption Evidence Demo**. Start a new arc from `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md` with `$gsd-new-milestone`; continue from Phase 51.

---

*2026-05-07 — v0.5 milestone audit (closed by Phase 21.2) re-scoped DIAG-01 (Debug bundles) and the previously-orphaned "Expiry alerts" feature (now CERT-EXP-01) from v0.5 to v0.6. v0.6 is now SLO + ops-maturity carryovers, ordered behind v1.0 security review. Trigger: scope drift surfaced by `/gsd-audit-milestone v0.5` — only 2 of 4 stated v0.5 features shipped; the v0.5 → v0.6 re-scope preserved the original arc cadence (admin → IdP-init → ops → SLO → conformance) without inserting an additional milestone.*
*2026-05-08 — v1.0 shipped. The v0.3 → v1.0 arc is complete: executable conformance coverage, reviewer packet artifacts, and Day-1 onboarding proof are all checked in. The next milestone arc is intentionally undefined until post-v1.0 priorities are re-scoped.*
*2026-05-25 — v1.1 shipped as a focused security milestone outside the original v0.3 → v1.0 arc. Trigger: a 2026-05-23 P0 audit confirmed that published `1.0.0`/`1.1.0` accepted forged SAML signatures because XMLDSig verification math was missing. v1.1 added the real parse-tree/C14N foundation, genuine XMLDSig verification for response and metadata paths, permanent adversarial crypto gating, and staged disclosure artifacts. The next broad product arc remains intentionally undefined.*
*2026-06-12 — Private adoption-evidence trigger recorded. The broad product arc is now v1.7 Adoption Evidence Demo: a realistic runnable Phoenix SaaS demo app with deterministic seeds, Docker DX, mounted LiveAdmin, customer/admin setup flow, Ecto production stores, local FakeIdP proof, optional Keycloak proof, browser E2E, and docs. Protocol candidates remain demand-gated; the demo is evidence infrastructure, not hosted broker scope.*

*Last updated: 2026-06-12 — next arc defined as v1.7 Adoption Evidence Demo pending `$gsd-new-milestone`.*
