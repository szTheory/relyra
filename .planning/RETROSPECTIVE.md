# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.2 — Enterprise Configuration

**Shipped:** 2026-05-06
**Phases:** 8 (5 scope + 3 closure) | **Plans:** 25 | **Tests at close:** 168/168 (serial)

### What Was Built

- **Durable connection records (CFG-01).** `Relyra.Ecto.Connection` aggregate with internal binary PK + public `connection_id`, lifecycle status (draft/enabled/disabled), child certificate inventory, and minimal create/update/enable/disable persistence API. Runtime-readiness is a separate explicit gate.
- **Resolver snapshot boundary (CFG-02).** `Relyra.ConnectionResolver.Ecto` returns a normalized `%Relyra.Connection{}` value struct via dedicated `ConnectionLoader` + `ConnectionSnapshot`. No Ecto rows leak above the resolver. Login, metadata, and protocol validation all consume the same canonical snapshot with `idp_certificates` precedence.
- **Metadata import/export + controlled refresh (CFG-03).** `Relyra.Metadata.import_xml/3`, `register_source/3`, `refresh/2`. Single transactional apply seam with last-known-good preservation on failure. Endpoint precedence: HTTP-Redirect → HTTP-POST → remaining. Optional `Req` for HTTPS metadata fetches. Telemetry redacted.
- **Certificate inventory + staged rollover (CFG-04).** `Relyra.Ecto.CertificateInventory` owns `:active` / `:next` / `:retired` lifecycle with per-cert `not_before` / `not_after` facts, optimistic-locked transitions, and typed `:conflict` errors on stale writes. Snapshot hydrates only `:active` certs.
- **Persisted mappings + cross-domain audit ledger (CFG-05).** `AttributeMapping`, `GroupMapping`, append-only `MappingRevision`. `MappingCommands` co-commits live row replacement + revision row + audit event in one transaction. Cross-domain audit hardening (Plan 11-03) extends same-transaction audit capture to connection, metadata, and certificate writes via a single `Relyra.Ecto.AuditWriter.append_event` seam.

### What Worked

- **Closure-phase pattern (Phases 12, 13, 14).** When the 2026-05-05 milestone audit surfaced verification orphans for CFG-03/04/05, the response was three small purpose-built closure phases that produced the missing `09/10/11-VERIFICATION.md` artifacts (plus one regression repair) instead of re-opening implementation. Smaller blast radius, cleaner audit trail, manual sign-off captured per artifact, and no regressions to the v0.2 implementation work that had already passed phase verification. Worth carrying forward as a canonical move.
- **Single audit-writer seam.** Routing all four mutation modules (Connections, MetadataApply, CertificateInventory, MappingCommands) through `Relyra.Ecto.AuditWriter.append_event` inside the same transaction made cross-domain audit hardening (Plan 11-03) a contained refactor rather than a sweep. The audit ledger cannot drift from the data it describes because there's only one writer with one redaction policy.
- **Public ID separation from internal PK.** Persisting connections with internal binary PK + public `connection_id` join key meant the resolver, validation pipeline, and audit ledger all reference the same stable public identity even as the persistence shape evolves. Avoids the Spring/Sustainsys footgun where downstream code couples to ORM rows.
- **Operator-triggered refresh.** Holding the line on "metadata refresh is operator-triggered only; new signing certs stage as `:next`" eliminated an entire class of silent trust-shift bugs. The brand metaphor ("verified trust path") is now also the implementation contract.
- **3-source requirements cross-reference at audit time.** Checking each REQ-ID against (a) phase VERIFICATION.md, (b) phase SUMMARY.md frontmatter, and (c) REQUIREMENTS.md traceability caught the orphan pattern that the original gap_found audit surfaced — and gave the closure phases a precise definition of done.

### What Was Inefficient

- **Initial v0.2 close attempted with stale audit.** The 2026-05-05 audit was already three phases out of date when `/gsd-complete-milestone` was first invoked. The pre-flight check correctly forced a re-audit before archive — but the time would have been saved by running `/gsd-audit-milestone` immediately after the last closure-phase commit instead of treating the audit as a one-shot artifact.
- **`MappingCommands.append_audit/8` divergence from the explicit-rollback pattern.** The other three co-commit sites all use the explicit `rollback(repo, error)` pattern; `MappingCommands` returns `{:error, _}` from inside the `with` chain and relies on `transact/1` auto-rollback. Caught only at integration-check time, not during phase code review. Not a correctness bug on modern Ecto, but a consistency gap that should have been caught earlier.
- **Parallel migration bootstrap races.** Phase 08 (and re-confirmed during v0.2 close) showed that parallel Mix smoke suites can race the Ecto migration bootstrap and produce false-negative results. Tracked as operational guidance ("run smoke serially") but worth automating in CI before v0.3 instead of relying on operator memory.

### Patterns Established

- **Closure-phase pattern.** When an audit surfaces verification orphans for already-shipped implementation, prefer producing the missing verification artifacts in a small dedicated phase over re-opening implementation. The closure phase's deliverable IS the upstream-phase verification artifact; it doesn't need its own VERIFICATION.md.
- **Single co-commit seam per mutation domain.** All four v0.2 mutation modules write audit rows through one shared `AuditWriter.append_event` inside the same transaction as the change. This is the canonical pattern for any future trust-mutation surface in Relyra.
- **Public-ID separation.** Internal binary PK + public string ID join key for any persisted aggregate that has runtime consumers. The runtime never sees the internal PK; the persistence layer never exposes the runtime value struct.
- **Stage-then-promote for trust shifts.** Newly fetched / newly imported signing material stages as `:next`; promotion is explicit operator action. Runtime trust never shifts implicitly on a fetch / parse / apply event.
- **3-source REQ cross-reference at milestone audit.** VERIFICATION.md + SUMMARY frontmatter + REQUIREMENTS.md traceability — any disagreement is a gap signal.

### Key Lessons

1. **Audits decay.** A milestone audit reflects a point-in-time snapshot. After any phase that materially changes coverage (closure phases, regression repairs, new VERIFICATION artifacts), re-run `/gsd-audit-milestone` before treating the audit as the close-readiness check.
2. **Cross-cutting consistency lives in patterns, not lint rules.** The `MappingCommands.append_audit` divergence wasn't caught by code review because the pattern (explicit rollback on co-commit failure) wasn't documented as a hard rule. Either codify cross-cutting patterns in `CLAUDE.md`/`AGENTS.md` or write a Credo check for them.
3. **Closure phases beat re-opening implementation.** Three small closure phases closed three audit orphans without touching any of the green implementation work or producing a single regression in the 168-test serial suite. The cost of reopening even a verified phase is much higher than the cost of a clean closure phase.
4. **Operator-triggered, not implicit.** Trust shifts (new signing material activated, certificates promoted, mappings replaced) must always be the result of an explicit operator action, never a side effect of a fetch/parse/apply event. Holding this line in v0.2 retroactively justifies the v0.1 strict-by-default posture.
5. **Audit before archive.** Pre-flight `audit-milestone` is non-optional. The 2026-05-05 → 2026-05-06 audit refresh caught no new issues — but it confirmed the closure phases actually closed what they claimed.

### Cost Observations

- Model mix: not measured (Claude Code session — primary model: Opus 4.7 1M).
- Sessions: not exhaustively counted; the closure-phase chain (12 → 13 → 14) ran inside the milestone-close session continuum.
- Notable: closure phases 12-14 produced their entire deliverable (regression repair + serial verification packets + planning-truth updates + per-phase manual sign-off) in roughly the same per-phase rhythm as a normal scope phase, suggesting the closure-phase pattern is not noticeably more expensive than the alternative of re-opening implementation.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 6 | 19 | Established XML-trust-boundary ADR pattern + behaviour-backed store contracts. |
| v0.2 | 8 (5+3) | 25 | Established closure-phase pattern; established single-AuditWriter seam; established public-ID/internal-PK separation for persisted aggregates. |

### Cumulative Quality

| Milestone | Tests at close | Code LOC (lib + test) | New patterns added |
|-----------|----------------|-----------------------|--------------------|
| v0.1 | n/a (not recorded) | n/a | XML-ADR, behaviour-stores, opaque-RelayState |
| v0.2 | 168/168 (serial) | 16,534 | closure-phase, AuditWriter seam, public-ID/internal-PK, stage-then-promote |

### Top Lessons (Verified Across Milestones)

1. **Strict defaults pay back across milestones.** v0.1 locked "no implicit trust shift, no signature trust from KeyInfo, no SHA-1 default, no parser differential, replay required in prod." v0.2 extended that posture to "no implicit trust shift on metadata fetch, audit row co-committed with every mutation, runtime trust hydrates only `:active` certs." Each new strict default in v0.2 was a direct extension of a v0.1 invariant — the strict-by-default stance compounds.
2. **Behaviour-backed seams beat ad-hoc integration.** v0.1 established behaviour-backed `RequestStore` / `ReplayStore` / `SessionAdapter` / `UserMapper`. v0.2 extended that pattern to `ConnectionResolver` (with `Default` and `Ecto` adapters) — the host app picks its persistence story without forking. Behaviours are still the canonical extension point.
