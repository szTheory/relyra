# Phase 21: Scheduled metadata refresh - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Take the locked Phase 09/10/12 metadata-refresh contract (operator-triggered, stage-only certificate semantics, last-known-good preservation, runtime path untouched) and add a **per-connection opt-in unattended automation surface** that satisfies CFG-08 without weakening any v0.2 trust invariant. This phase delivers: a dormant scheduler entry point any host scheduler can drive, an Oban worker behind the optional-deps gateway, per-source schedule + signed-metadata + drift-detection state on `MetadataSource`, a separate `[:relyra, :saml, :metadata, :auto_refresh, ...]` telemetry namespace, soft-backoff auto-suspension on transient failures, immediate-alert behavior on suspicious failures, and a small admin-LiveView surface for visibility and operator action.

This phase does **not** deliver: a built-in always-running supervised ticker, automatic certificate promotion (still Phase 10's explicit lifecycle), automatic cadence shifts based on IdP-published `validUntil` (warn-only), federation/MDQ aggregator support (deferred to a later milestone), or vendor-specific paging integrations (Slack/PagerDuty/Sentry remain host-app territory).

</domain>

<decisions>
## Implementation Decisions

### Scheduling Mechanism

- **D-01:** Phase 21 ships **`Relyra.Metadata.Scheduler.run_due(repo, opts)`** as the canonical entry point. Pure function. Any host scheduler (Oban Cron, Quantum, k8s `CronJob`, fly.io scheduled machines, plain `mix relyra.refresh_due`) can drive it. The function returns a result map per source; the existing Phase-20 sequential batch + auto correlation_id pattern applies.
- **D-02:** Phase 21 ships **`Relyra.Workers.MetadataRefresh`** behind a new **`Relyra.OptionalDeps.Oban`** gateway module (`Code.ensure_loaded?(Oban)` + `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}`). Adopters with Oban add one Cron line and are done; adopters without can still use everything.
- **D-03:** The Oban worker uses `unique: [period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]]` so a clustered Oban will not double-fetch the same source. Multi-node dedup is delegated to Oban's `Oban.Peers.Database` leader election; Relyra does not ship advisory-lock code.
- **D-04:** **No supervised auto-starting ticker.** The scheduler is dormant until something invokes `run_due/2`. This is the line: a library that owns its own background loop owns its own multi-node footguns (Spring Security SAML `Timer` and early Shibboleth daemon races are the lesson). Adopters opt in via Oban Cron or external cron.
- **D-05:** `run_due/2` wraps the existing `Relyra.Metadata.Refresh.refresh/2` per-source. All trust invariants (parse → validate → apply, stage-only, last-known-good, single audit-writer seam) live inside the wrapped function. Phase 21 is fan-out + scheduling state, not a re-implementation.
- **D-06:** Doc recipes ship for: Oban Cron one-liner (recommended), `mix relyra.refresh_due` task, k8s `CronJob` YAML snippet, fly.io `[[machines.schedule]]` block. Documented examples are non-optional — the SimpleSAMLphp `metarefresh` lesson is that "BYO scheduler" only works when copy-pasteable recipes ship.
- **D-07:** Emit `[:relyra, :saml, :metadata, :refresh, :skipped]` (or equivalent) when `run_due/2` finds nothing due. Without this, silent staleness is invisible.

### Per-Connection Opt-In, Cadence, Jitter

- **D-08:** `auto_refresh_enabled` lives on **`Relyra.Ecto.MetadataSource`**, not `Connection`. The thing being polled is the source URL; a connection without a registered source has nothing to schedule. The existing `unique_constraint(:connection_record_id)` already enforces 1:1, so UX-wise it remains "per connection." Future `kind: :file` or `:mdq` sources reuse the same fields.
- **D-09:** **Default is opt-out (`auto_refresh_enabled: false`).** Strict-defaults principle from PROJECT.md product principle 1 + Phase 09 v0.2 lock ("metadata refresh is operator-triggered only"). Phase 21 relaxes that lock only for connections an operator explicitly opts in.
- **D-10:** Cadence is a **preset enum** `[:hourly, :every_6h, :daily, :weekly]`. No cron strings (DDoS-the-IdP footgun), no free-form `interval_seconds` (unit-confusion footgun, `every 30s` support tickets). Four presets cover ~100% of real SAML metadata refresh use cases. No `:every_15min` preset — operator-triggered manual refresh covers fast dev iteration.
- **D-11:** **Default cadence is `:daily`.** Well under InCommon's ≤1/hour ceiling, calm, gives the Phase 10 staged-cert workflow >24h notice. SAML cert rotations happen ~2-4 times/year at enterprise IdPs.
- **D-12:** **Persisted `next_refresh_at`** with **±15% jitter applied once per scheduling decision.** Persisted-not-recomputed so jitter doesn't re-roll on host restart and double-fire. A partial index `WHERE auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())` on `next_refresh_at` makes "what's due?" a single index scan.
- **D-13:** **No per-source override of cadence beyond the four presets.** Each `MetadataSource` row chooses one of four. No global "default cadence" config either — every schedule entry is self-contained, no precedence rules, no "why did *this* connection refresh at *that* time" debugging.
- **D-14:** **Hybrid cadence semantics:** operator preset is authoritative; **1-hour hard floor** (InCommon ceiling) regardless of any future config drift; **warn-only** `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]` event when current metadata's `validUntil` is sooner than `2 × refresh_interval`. Relyra never auto-changes the schedule based on `validUntil` (that's magic; violates explainability). Same shape as Phase 10's stage-only certificate flow: surface the signal, let the operator act. `validUntil`-aware automatic cadence may be revisited in v0.6+.

### Security Guardrails (asymmetric strictness for the unattended path)

- **D-15:** **`require_signed_metadata` defaults `true`** on every `MetadataSource` whose `auto_refresh_enabled` is `true`. Scheduled apply refuses unsigned `<EntityDescriptor>` / `<EntitiesDescriptor>` XML. **Manual import is unchanged** — the operator-in-the-loop assumption that justified Phase 09's tolerant manual path still holds for human-driven imports.
- **D-16:** XMLDSig verification on the metadata root **runs before any normalization, parsing-deeply, or apply step.** The `esaml` 2026 NVD XXE-before-verify lesson generalizes: any logic between fetch and signature verification is in the trust boundary. Reuse `Relyra.Security.Signature.verify` (the same primitive used by `validation_pipeline`).
- **D-17:** **Trust anchor is operator-pinned `metadata_trust_fingerprints`** (SHA-256 hex, multi-valued for rotation). **Reject TOFU** — institutionalizes a one-shot MITM at enable-time. **Reject reuse-of-assertion-cert** — conflates two SAML metadata roles and breaks any IdP that follows the spec by separating them.
- **D-18:** **Drift detection auto-suspends.** Fetched `entityID` ≠ stored `idp_entity_id` OR a net-new signing-cert fingerprint not in `last_known_metadata_signing_certs` → set `auto_suspended_until` + typed `auto_suspended_reason` (`:entity_id_drift` or `:new_signing_cert`) and emit a typed error. **New certs still stage as `:next` per locked Phase 10/12 D-08** — staging is unchanged; only the *next* automatic fetch is paused pending operator acknowledgment via admin LiveView.
- **D-19:** **Escape hatch for unsigned metadata mirrors `legacy_algorithm_policy`:** `legacy_unsigned_metadata_policy: %{allow_until: ~D[...], reason: "...", audit: true}`. Time-boxed, audited, surfaced in admin UI with a risk panel. Lets adopters with non-conformant IdPs opt in to scheduled refresh while Phase-21 invariants stay strict-by-default.
- **D-20:** **Stricter `Req` profile for the scheduled fetch path:** explicit 30s connect + 30s receive timeouts, **no redirects** (HTTPS-only is enforced on the URL field; redirects are an HTTPS→anywhere downgrade vector), `max_response_size: 5_000_000` (5 MB cap), accepted content-types `application/samlmetadata+xml` and `application/xml` (warn-only on `text/xml` for IdP compatibility), fixed `User-Agent: Relyra-MetadataRefresh/<version>`.
- **D-21:** **Security-corpus regression fixtures run as a post-parse, pre-apply gate** on the scheduled path. If staged metadata trips any known-bad signature-wrapping or namespace-confusion shape (the `xml-crypto` 2025 family, PortSwigger Fragile-Lock shapes), refuse the apply, set `auto_suspended_reason: :corpus_violation`, emit a typed error. Honors the brand promise — every security fix becomes a permanent regression fixture, in *every* path including the unattended one.
- **D-22:** Trust-anchor fingerprint operator UX (Mix task vs admin-LiveView-only vs both) is the planner's call; planner ratifies during plan-phase. The **behavior** is locked: operator pins the fingerprint out-of-band before scheduled refresh activates.

### Failure Handling, Telemetry, Auto-Suspend

- **D-23:** **Separate telemetry namespace** `[:relyra, :saml, :metadata, :auto_refresh, :start | :stop | :exception]` for scheduled refreshes. The existing manual `[:relyra, :saml, :metadata, :refresh]` event is **untouched** so existing operator-action audit listeners keep working. Distinct namespace = host attaches the "page me" handler only to the unattended channel.
- **D-24:** Three additional state-transition events: `[:relyra, :saml, :metadata, :auto_refresh, :degraded]`, `[:relyra, :saml, :metadata, :auto_refresh, :suspended]`, `[:relyra, :saml, :metadata, :auto_refresh, :recovered]`. Plus the `:validity_warning` event from D-14.
- **D-25:** **Auto-suspend after 5 consecutive transient failures** with **exponential backoff capped at 24h** (1h → 6h → 24h → 24h…) plus **±10% jitter**. Suspension is a **soft backoff, not a hard stop**: scheduler skips the source until `auto_suspended_until` passes, then attempts one **half-open probe**. Success closes the circuit (`:recovered`); failure re-opens with the next backoff tier.
- **D-26:** **Suspension never flips `auto_refresh_enabled`.** Operator's intent is preserved; suspension is its own field (`auto_suspended_until`). When the IdP recovers or operator manually resumes, refresh continues without re-toggling.
- **D-27:** **Asymmetric failure classification.** Transient errors (`:fetch_timeout`, `:fetch_http_5xx`, `:fetch_dns_failure`, `:fetch_connection_refused`, `:fetch_tls_handshake`) **count toward auto-suspend** and **alert only after the 2nd consecutive occurrence** (suppress single-blip noise). Non-transient errors (`:signature_failed`, `:parse_failed`, `:validation_failed`, `:apply_failed`, `:fetch_http_4xx`, `:metadata_drift_requires_review`, `:corpus_violation`) **alert immediately** and **never count toward auto-suspend** — they need human eyes, not silent backoff. Each error code carries `transient?: bool` and `counts_toward_suspend?: bool` flags exposed in telemetry metadata.
- **D-28:** **Health state denormalized on `MetadataSource`** for O(1) reads in the LiveView and the scheduler tick. Authoritative history stays in `MetadataRevision` rows. **All counter / state updates happen inside the existing `MetadataApply.record_attempt/3` transaction** so they cannot drift from the audit ledger (single audit-writer seam invariant).
- **D-29:** **Admin LiveView surface (CFG-06 extension):** existing connection-list status badge gains a sibling micro-badge — amber `auto-refresh degraded` (count ≥ 1, not yet suspended), red `auto-refresh suspended` (in cool-off), tooltip with last error code + count + first-failure timestamp. Connection metadata page gains a compact "Auto-refresh health" card above the existing revision list: schedule preset, last success, consecutive failures, current state, last error code, and a single "Resume now" button when suspended (clears `auto_suspended_until`, triggers an immediate scheduled probe, recorded with operator actor in audit). **No separate top-level health dashboard in v0.5** — defer to v0.6+ if adopter feedback demands cross-tenant visibility.
- **D-30:** **Optional reference handler** `Relyra.Telemetry.Handlers.LogAlerts` (~50 LOC) ships in the docs/examples surface (not as a default-attached handler — adopters opt in in their `Application.start/2`). Removes the "what do I do with these events?" friction without coupling to any vendor. **No Slack/PagerDuty/Sentry integrations shipped** — telemetry events are the contract.
- **D-31:** **Failure muting (operator says "I know it's broken, stop telling me") is out of scope for v0.5.** Auto-suspend already absorbs the dominant transient-noise case; muting suspicious-class failures is the host's paging system's job. Revisit in v0.6 if adopter feedback demands.

### Schema Additions to `Relyra.Ecto.MetadataSource`

One consolidated migration. Field set is **locked**; column names and exact types may be refined in plan-phase as long as semantics are preserved.

| Field | Type | Default | Owner |
|---|---|---|---|
| `auto_refresh_enabled` | boolean | `false` | D-09 |
| `refresh_cadence` | enum `[:hourly, :every_6h, :daily, :weekly]` | `:daily` | D-10/D-11 |
| `next_refresh_at` | utc_datetime_usec | nil | D-12 |
| `require_signed_metadata` | boolean | `true` | D-15 |
| `metadata_trust_fingerprints` | array(string) | `[]` | D-17 |
| `legacy_unsigned_metadata_policy` | map | nil | D-19 |
| `last_known_metadata_signing_certs` | array(string) | `[]` | D-18 |
| `consecutive_failure_count` | integer | 0 | D-25 |
| `first_failure_at` | utc_datetime_usec | nil | D-25 |
| `last_success_at` | utc_datetime_usec | nil | D-29 |
| `last_failure_error_code` | string | nil | D-27/D-29 |
| `auto_suspended_until` | utc_datetime_usec | nil | D-25/D-26 |
| `auto_suspended_reason` | string | nil | D-18/D-25 (typed: `:entity_id_drift`, `:new_signing_cert`, `:signature_invalid`, `:corpus_violation`, `:transient_failures_exceeded`) |

Partial index: `WHERE auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())` on `next_refresh_at`.

### Locked-Forward Invariants (re-asserted, do not violate)

- **D-32:** Stage-only certificate semantics — scheduled apply stages new signing certs as `:next`, never auto-promotes (Phase 10/12 D-08 to D-10; v0.2 Key Decision).
- **D-33:** Last-known-good preservation on every failure mode (Phase 09 D-04; Phase 12 D-08).
- **D-34:** Two-boundary apply: fetch/parse/validate first, transactional apply second (Phase 09 D-02; Phase 12 D-03).
- **D-35:** Single audit-writer seam — every refresh attempt (success AND failure, scheduled AND manual) writes a `MetadataRevision` row + audit event via `Relyra.Ecto.AuditWriter.append_event` inside the same transaction (Phase 11; v0.2 Key Decision). Already implemented in `MetadataApply.record_attempt/3`; Phase 21 reuses it.
- **D-36:** Runtime never depends on a live fetch (Phase 09 D-09). Login, ACS, SP-metadata-export consume only the persisted last-known-good snapshot resolved through the existing `Relyra.ConnectionResolver.Ecto` boundary.
- **D-37:** Optional-deps gateway pattern is the canonical answer for any new external dep (engineering-DNA §5; PROJECT.md "Optional-deps gateway" key decision). `Relyra.OptionalDeps.Oban` is the new gateway; matches the existing pattern.
- **D-38:** Sequential per-batch execution to avoid DB pressure (Phase 20 STATE.md highlight). `run_due/2` loops sources sequentially; per-source work is wrapped in `Relyra.Metadata.Refresh.refresh/2`.
- **D-39:** Auto-generated `correlation_id` for the scheduled batch run (Phase 20 BulkActions pattern). All revision rows + audit events from one `run_due/2` invocation share the same correlation_id so the audit ledger renders the batch as a unit.

### Claude's Discretion (planner / executor decides)

- Exact module names and file layout for the scheduler, the optional-deps gateway, and the worker, provided D-01 / D-02 / D-04 / D-05 hold.
- Exact column names and Ecto types for the schema additions, provided the field set in D-15 / D-17 / D-18 / D-19 / D-25 / D-28 / D-29 is preserved.
- Exact failure-classification flag mechanism (per-error-code metadata vs a separate classification table vs at-emit-time inference), provided D-27 holds.
- Exact admin-LiveView visual treatment (color hex, badge shape, tooltip copy) within the spec of D-29.
- Exact migration ordering, default-value backfill strategy, and lock_version handling for the `MetadataSource` schema extension.
- Exact `Req` configuration plumbing for the stricter scheduled-path profile, provided D-20 invariants hold.
- Exact admin-LiveView fingerprint-pinning UX (D-22) — Mix task vs admin-only vs both.
- Whether the security-corpus gate (D-21) reuses the existing test corpus directly or extracts to a runtime-callable validator module, provided every existing fixture acts as a refusal trigger.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and project constraints
- `.planning/ROADMAP.md` — Phase 21 goal and success criteria (CFG-08).
- `.planning/REQUIREMENTS.md` — `CFG-08` traceability anchor.
- `.planning/PROJECT.md` — strict-defaults principle, optional-deps gateway pattern, single audit-writer seam, "Operable from day one" pillar, and v0.5 milestone scope.
- `.planning/MILESTONE-ARC.md` — v0.5 → v1.0 plan; Phase 21 sits in "automate the toil" theme.
- `.planning/RETROSPECTIVE.md` — closure-phase pattern, "operator-triggered, not implicit" lesson, single audit-writer seam discipline.

### Locked prior decisions
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` — D-01 to D-23 covering refresh-safety model, two-boundary apply, last-known-good preservation, runtime-trust isolation, and `Req` optionality. **Phase 21 explicitly relaxes D-01 only for opted-in connections; all other Phase-09 invariants hold.**
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` — staged certificate lifecycle (`:active` / `:next` / `:retired`); never auto-promote.
- `.planning/phases/12-metadata-refresh-trust-state-repair/12-CONTEXT.md` — D-08 to D-10 stage-only behavior; canonical metadata-certificate normalization at the import boundary.
- `.planning/phases/13-certificate-rollover-validation-verification/13-VERIFICATION.md` — staged-rollover verification posture; auto-refresh must not regress this.
- `.planning/phases/19-idp-initiated-sso/19-CONTEXT.md` — `allow_idp_initiated` opt-in pattern (per-connection boolean default false + great error message); reuse the same pattern shape for `auto_refresh_enabled`.
- `.planning/phases/20-bulk-operations/20-CONTEXT.md` and `.planning/phases/20-bulk-operations/20-RESEARCH.md` — `Relyra.Ecto.BulkActions.run/4` sequential pattern + auto correlation_id; reuse for `run_due/2`.

### Existing runtime, persistence, and live-admin contracts
- `lib/relyra/metadata/refresh.ex` — `Relyra.Metadata.Refresh.refresh/2`, the per-source fetch/parse/validate/apply path that Phase 21 wraps. **Do not re-implement** — extend.
- `lib/relyra/metadata/parser.ex` — current XML parsing edge; signed-metadata verification (D-16) hooks here.
- `lib/relyra/metadata/import.ex` and `lib/relyra/metadata/candidate.ex` — normalized internal candidate contract (Phase 12 D-04).
- `lib/relyra/ecto/metadata_source.ex` — schema being extended; current shape includes `connection_record_id`, `url`, `kind: :remote_url`, `last_fetched_at`, `last_outcome` (enum), `unique_constraint(:connection_record_id)`.
- `lib/relyra/ecto/metadata_apply.ex` — `apply_revision/4` and `record_attempt/3`, the single transactional apply + audit seam. **All Phase-21 counter / state updates happen inside this transaction (D-28).**
- `lib/relyra/ecto/audit_writer.ex` — single audit-writer seam (Phase 11).
- `lib/relyra/ecto/certificate_inventory.ex` and `lib/relyra/ecto/certificate_facts.ex` — staged certificate lifecycle the auto-refresh path must respect.
- `lib/relyra/ecto/connection_snapshot.ex` and `lib/relyra/ecto/connection_loader.ex` — runtime hydration boundary; D-36.
- `lib/relyra/security/signature.ex` (or wherever the XMLDSig verifier lives — verify the exact path during plan-phase) — primitive reused for D-16.
- `lib/relyra/telemetry.ex` — telemetry catalog and `[:relyra, :saml, :metadata, :refresh]` event convention. New `[:relyra, :saml, :metadata, :auto_refresh, ...]` events follow the same shape.
- `lib/relyra/log.ex` — redaction posture for operational logging.
- `lib/relyra/live_admin/connections_live.ex` — list view; D-29 micro-badge surface.
- `lib/relyra/live_admin/connection_metadata_live.ex` — metadata page; D-29 health card surface.

### Research and architecture guidance
- `prompts/elixir-saml-lib-deep-research.md` §8 — metadata refresh + cert rollover requirements ("fetch metadata URL on schedule, validate TLS, optionally validate signed metadata, parse new certs, keep old and new certs active during overlap, alert on expiry, show diff in admin UI, require confirmation for surprising issuer/entity changes"). Phase 21 implements all of these except the "diff" UX.
- `prompts/relyra-engineering-dna-from-prior-libs.md` §5 (mailglass `OptionalDeps` pattern) — the canonical optional-deps gateway shape. Phase 21 adds `Relyra.OptionalDeps.Oban` to the existing `Ecto` / `LiveView` family.
- `prompts/relyra-engineering-dna-from-prior-libs.md` §3 (compile lane) — `mix compile --no-optional-deps --warnings-as-errors` CI lane must stay green with `Oban` added.
- `prompts/relyra-brand-book.md` — calm, exact, operator-friendly voice. "Auto-refresh" / "schedule" / "suspended" / "resume" — not "polling" / "cron" / "blocked" / "retry".

### External standards and federation conventions
- OASIS SAML V2.0 Metadata Interoperability Profile — metadata signing semantics; `<EntityDescriptor>` and `<EntitiesDescriptor>` signature scope.
- InCommon Federation Metadata Registration Practice Statement — ≤1/hour refresh ceiling per relying party (the source of D-14's hard floor).
- Shibboleth `FileBackedHTTPMetadataResolver` and `SignatureValidationFilter` documentation — verify-before-modify ordering, refresh-delay model. (Phase 21 chooses simpler explicit cadence; documents the divergence.)
- Microsoft Entra ID federation metadata documentation — active+next cert publication pattern (gives multi-week rollover windows; informs `:daily` default sufficiency).
- AWS Builder's Library "Timeouts, retries and backoff with jitter" — the canonical jitter + exponential-backoff justification (D-25).

### Cross-language CVE / incident lessons (load-bearing for the security guardrails)
- `ruby-saml` CVE-2024-45409 — trusting document-provided signature context; lesson: trust anchor must be operator-pinned (D-17).
- `esaml` 2026 NVD XXE-before-signature-verification — lesson: verify before parse-deeply (D-16).
- `xml-crypto` CVE-2025-29775 and the PortSwigger "Fragile Lock" research — signature-wrapping / namespace-confusion shapes; lesson: corpus gate on the unattended path (D-21).
- `authentik` CVE-2026-25922 — silent assertion injection from "we'll figure out which signature to trust" logic; lesson: net-new cert = staged + suspended, not silent promotion (D-18).
- "Gaining AWS Persistence by Updating a SAML IdP" (Adan/Alvarez, Medium) — the canonical metadata-poisoning kill chain; lesson: drift detection on `entityID` and on signing-cert fingerprints (D-18).

### Sibling-library precedent
- Spring Security SAML issue #9134 (`refreshCheckInterval` ≤ 2000ms silent disable) — lesson: a library that owns its own ticker owns its own footguns (D-04).
- SimpleSAMLphp `metarefresh` module — the "ship a function the host's cron drives + ship the exact crontab line" pattern (D-01, D-06).
- Shibboleth `FileBackedHTTPMetadataResolver` `MaxBackoff` semantics — circuit-breaker on sustained fetch failure (D-25).
- Oban `Oban.Peers.Database` leader election + `unique` job options — the "free multi-node dedup" pattern (D-03).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Metadata.Refresh.refresh/2` (`lib/relyra/metadata/refresh.ex`) — already does the per-connection fetch / parse / validate / apply with telemetry, audit, and last-known-good. **Phase 21 wraps this; does not re-implement.**
- `Relyra.Ecto.MetadataApply.apply_revision/4` and `record_attempt/3` (`lib/relyra/ecto/metadata_apply.ex`) — single transactional apply + audit seam. Phase 21 piggybacks the `record_attempt` transaction for all counter/state updates (D-28).
- `Relyra.Ecto.AuditWriter.append_event` — the one audit writer for trust mutations. Auto-refresh attempts route through it like manual ones.
- `Relyra.Ecto.MetadataSource` (`lib/relyra/ecto/metadata_source.ex`) — already has `connection_record_id`, `url`, `kind`, `last_fetched_at`, `last_outcome`. Natural place to extend with the Phase-21 schedule + health + trust-anchor fields.
- `Relyra.Ecto.BulkActions.run/4` (`lib/relyra/ecto/bulk_actions.ex`) — Phase-20 sequential-with-correlation-id pattern. Same shape for `run_due/2`'s per-source loop.
- `Relyra.Telemetry` (`lib/relyra/telemetry.ex`) — established event-naming convention; extend with the `[:relyra, :saml, :metadata, :auto_refresh, ...]` namespace.
- `Relyra.Security.Signature.verify` (verify exact path during plan) — the XMLDSig primitive that already verifies assertion signatures; reusable for `<EntityDescriptor>` root signatures (D-16).
- `Relyra.LiveAdmin.ConnectionsLive` and `Relyra.LiveAdmin.ConnectionMetadataLive` — the LiveView surfaces D-29 extends. Existing `start_async(:metadata_refresh, ...)` pattern in `connection_metadata_live.ex` lines 80-114 is the visual + interaction template for the "Resume now" button.
- `Relyra.Ecto.Connection.allow_idp_initiated` (Phase 19) — the per-connection-boolean-opt-in pattern shape to mirror for `MetadataSource.auto_refresh_enabled`, including the great-error-message DX (D-09).

### Established Patterns
- Optional-deps gateway: `Code.ensure_loaded?(Mod)` + `@compile {:no_warn_undefined, [...]}` + a thin wrapper module under `Relyra.OptionalDeps.*`. New `Relyra.OptionalDeps.Oban` follows this exactly (D-02).
- Public APIs return `{:ok, _} | {:error, %Relyra.Error{}}`. No exception-driven control flow.
- Runtime and protocol modules consume pure structs/maps, not Ecto schemas (resolver boundary, D-36).
- Trust-bearing state changes are explicit, explainable, and fail closed (drift detection auto-suspends but never silently mutates trust — D-18).
- Strict-defaults + explicit escape hatches (the `legacy_*_policy` shape — D-19 mirrors `legacy_algorithm_policy`).
- Sequential per-batch execution + auto correlation_id (Phase 20 BulkActions; reused by `run_due/2` per D-38, D-39).
- Single audit-writer seam: every trust-mutation co-commits its audit row inside the data transaction (Phase 11; D-28, D-35).

### Integration Points
- Schema migration extends `relyra_metadata_sources`. No new table. Existing rows backfill cleanly: `auto_refresh_enabled = false`, `refresh_cadence = :daily` (unused while disabled), `require_signed_metadata = true` (unused while disabled), all health fields nil/0.
- `Relyra.Metadata.Scheduler.run_due(repo, opts)` becomes a new public API surface; documented in moduledocs and the README "Operations" section.
- `Relyra.OptionalDeps.Oban` becomes a new public gateway module; documented alongside the existing `Ecto` / `LiveView` gateway patterns.
- `Relyra.Workers.MetadataRefresh` becomes a new optional Oban worker; documented with a copy-pasteable `Oban.Plugins.Cron` recipe.
- `Relyra.Telemetry` moduledoc gains a "Scheduled metadata refresh" section listing the new `[:relyra, :saml, :metadata, :auto_refresh, ...]` events.
- Admin LiveView surfaces extend two existing LiveViews; no new top-level mount, no new route.
- The `legacy_unsigned_metadata_policy` field belongs in the audit-event payload when auto-refresh applies an unsigned metadata revision under the escape hatch (audit redaction must remain compliant).
- The CI matrix gains a Postgres + Oban smoke lane (existing `mix compile --no-optional-deps --warnings-as-errors` lane stays green; new lane verifies the worker compiles and the Cron one-liner registers).

</code_context>

<specifics>
## Specific Ideas

- **Brand voice anchors:** "Auto-refresh", "schedule", "suspended", "resume now", "metadata trust fingerprint", "validity warning". Avoid "polling", "cron job", "blocked", "retry", "circuit breaker" in operator-facing copy — those are implementation language, not operator language.
- **Recommendation-first DX preference (saved to project memory):** during planning and execution, pick coherent defaults; only checkpoint with the user on choices that materially change product direction (security contract / public surface change / direct PROJECT.md contradiction). Architecturally-bounded "could go either way" choices belong to the agent.
- **The 1-hour InCommon hard floor (D-14)** is the spec-safety net even if a future enum revision adds a more aggressive preset. Bake it into the cadence-resolution helper, not just into the enum domain.
- **The `:validity_warning` event (D-14)** should fire at most once per `validUntil` window per source — adopters wiring this to PagerDuty don't want N pages per day for the same staleness window.
- **The "Resume now" button (D-29)** is the operator-shaped escape hatch for suspended sources; clicking it MUST audit (operator actor + cause = `live_admin_auto_refresh_resume`) per D-35.
- **Trust-anchor pinning UX is the most operator-sensitive part of the feature.** The plan should call it out as needing UX care: the Mix-task-or-LiveView decision (D-22) shapes how scary this feels for adopters who haven't pinned an SSH host key in years.

</specifics>

<deferred>
## Deferred Ideas

- **Diff-preview UX for incoming metadata revisions** — Phase 09 D-05 already deferred this; auto-refresh makes it more valuable but still v0.6+.
- **Federation aggregator support / MDQ resolver** — `kind: :mdq` source type for InCommon-style aggregator URLs. Out of v0.5 scope (no current adopter ask). Phase 21 schema is shaped so adding it later is additive, not a redesign.
- **Vendor-specific paging integrations** (Slack / PagerDuty / Sentry handlers). Telemetry events are the contract; adopters wire their own. Revisit only if a recurring adopter ask emerges.
- **`validUntil`-aware automatic cadence shifts** — surface as a warning event in v0.5 (D-14); revisit automatic shortening in v0.6+ if the warn-only signal proves insufficient.
- **Failure muting** ("I know it's broken, stop telling me") — auto-suspend covers the dominant transient-noise case; suspicious-class muting belongs in the host's paging system. Revisit in v0.6 if adopter feedback demands.
- **Top-level cross-tenant auto-refresh health dashboard** in admin LiveView. Per-connection badges + per-connection health card cover v0.5; aggregate dashboard is premature. Revisit in v0.6+.
- **TOFU mode for trust-anchor pinning** as an explicit opt-in (e.g., `metadata_trust_policy: :tofu`). Not shipping in v0.5 (D-17 rejection stands), but the schema does not preclude adding it later as a typed escape-hatch field.
- **Mix task `mix relyra.metadata.pin <source_id> --url <url>`** as the recommended fingerprint-pinning ceremony. Decision deferred to plan-phase per D-22; this captures the candidate UX.
- **W7 / Deferred to v0.6+: Admin-LiveView trust-anchor pinning *form*** (the operator-facing form/modal that lets you pin a SHA-256 fingerprint via the UI without dropping to the CLI). v0.5 covers D-22 via three concrete deliverables: (1) `mix relyra.metadata.pin` Mix task (Plan 07 Task 2 — IaC-friendly, scriptable), (2) the schema-level great-error from `auto_refresh_changeset/2` (Plan 01 — refuses to enable auto-refresh without pinned fingerprints, D-09), and (3) the LiveView read-only display of pinned fingerprints inside the "Auto-refresh health" card (Plan 06 Task 2). The interactive *pin-via-LiveView form* deferral is intentional and pending adopter feedback in the v0.5 → v0.6 cycle.

</deferred>

---

*Phase: 21-scheduled-metadata-refresh*
*Context gathered: 2026-05-06*
