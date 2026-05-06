# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- 📋 **v0.3 — TBD** (planning starts via `/gsd-new-milestone`).

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

- [x] Phase 07: Schema + connection aggregate (3/3 plans) — verified 2026-05-05 — CFG-01
- [x] Phase 08: Resolver adapter + snapshotting (3/3 plans) — verified 2026-05-05 — CFG-02
- [x] Phase 09: Metadata import/export + refresh (4/4 plans) — verified via Phase 12 (2026-05-06) — CFG-03
- [x] Phase 10: Certificate inventory + rollover (3/3 plans) — verified via Phase 13 (2026-05-06) — CFG-04
- [x] Phase 11: Mapping persistence + audit hardening (4/4 plans) — verified via Phase 14 (2026-05-06) — CFG-05
- [x] Phase 12: Metadata refresh trust-state repair (3/3 plans, closure) — produced 09-VERIFICATION.md — 2026-05-06
- [x] Phase 13: Certificate rollover validation + verification (3/3 plans, closure) — produced 10-VERIFICATION.md — 2026-05-06
- [x] Phase 14: Mapping/audit milestone verification (2/2 plans, closure) — produced 11-VERIFICATION.md — 2026-05-06

See `.planning/milestones/v0.2-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

### 📋 v0.3 — TBD (Planning)

Next milestone scope is set via `/gsd-new-milestone`. Likely candidates from v0.2 deferred list:

- LiveView admin surface (CFG-06) — config storage is now stable; adoption-UX milestone is unblocked.
- Bulk operations across multiple connections (CFG-07).
- Scheduled metadata refresh automation with guardrails (CFG-08).

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete (closure 12) | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete (closure 13) | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete (closure 14) | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete (closure phase) | 2026-05-06 |
