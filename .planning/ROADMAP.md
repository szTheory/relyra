# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for
Elixir/Phoenix. The planned v1.x arc is shipped through **v1.10 — Docker DX &
Fleet Proxy**. No milestone is active; future protocol work remains demand-gated
until a real adopter signal changes the scope.

## Milestones

- Complete: **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 — External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 — Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 — Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 — Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 — Adoption Evidence Demo** (shipped 2026-06-13). See `.planning/milestones/v1.7-ROADMAP.md`.
- Complete: **v1.8 — Brand System & Identity** (shipped 2026-06-14). See `.planning/milestones/v1.8-ROADMAP.md`.
- Complete: **v1.9 — Loose Ends & Adoption Honesty** (shipped 2026-06-19). See `.planning/milestones/v1.9-ROADMAP.md`.
- Complete: **v1.10 — Docker DX & Fleet Proxy** (shipped 2026-08-27; Phases 68–72.1; 12/12 requirements). See `.planning/milestones/v1.10-ROADMAP.md`.

## Current Status

v1.10 is archived with 6/6 phases verified, 12/12 requirements satisfied,
10/10 integration links connected, and 6/6 end-to-end flows complete. The
milestone audit retains three non-blocking advisories; see
`.planning/milestones/v1.10-MILESTONE-AUDIT.md`.

## Demand-Gated Future Candidates

- **AUTHN-POST-01** — HTTP-POST binding signed AuthnRequests with enveloped XML signature and C14N. Wait for real adopter demand.
- **KMS-01** — KMS-native `KeyResolver` adapters for AWS KMS or GCP KMS. Wait for real adopter demand.
- **SIGNED-META-01** — Signed SP metadata plus federation extensions and an InCommon runbook. Wait for real adopter demand.

Start the next planning cycle with `$gsd-new-milestone`; phase numbering
continues after 72.1.

---
*Roadmap updated: 2026-08-27 — v1.10 Docker DX & Fleet Proxy archived*
