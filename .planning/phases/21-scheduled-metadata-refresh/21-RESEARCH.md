# Phase 21: Scheduled metadata refresh — Research

**Researched:** 2026-05-06
**Domain:** Elixir/Phoenix background scheduling, Oban optional integration, SAML metadata XMLDSig, Ecto schema extension under a single audit-writer seam, LiveView health surface
**Confidence:** HIGH on the tactical recommendations (verified against live source files, Oban docs current as of 2026-05-06, AWS Builder's Library); MEDIUM on the LiveView visual treatment (D-29 leaves room for discretion within the locked spec)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Scheduling Mechanism**
- D-01 — `Relyra.Metadata.Scheduler.run_due(repo, opts)` is the canonical entry point (pure function, BYO scheduler, returns per-source result map, sequential per-batch + auto correlation_id from Phase 20).
- D-02 — `Relyra.Workers.MetadataRefresh` ships behind a new `Relyra.OptionalDeps.Oban` gateway (`Code.ensure_loaded?(Oban)` + `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}`).
- D-03 — Oban worker uses `unique: [period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]]`. Multi-node dedup delegated to `Oban.Peers.Database` leader election; no advisory-lock code in Relyra.
- D-04 — No supervised auto-starting ticker. Scheduler dormant until something invokes `run_due/2`.
- D-05 — `run_due/2` wraps existing `Relyra.Metadata.Refresh.refresh/2`. All trust invariants stay inside the wrapped function. Phase 21 is fan-out + scheduling state, not a re-implementation.
- D-06 — Doc recipes ship for: Oban Cron one-liner (recommended), `mix relyra.refresh_due` task, k8s `CronJob` YAML, fly.io `[[machines.schedule]]`.
- D-07 — Emit `[:relyra, :saml, :metadata, :refresh, :skipped]` (or namespaced equivalent) when `run_due/2` finds nothing due.

**Per-Connection Opt-In, Cadence, Jitter**
- D-08 — `auto_refresh_enabled` lives on `Relyra.Ecto.MetadataSource`, not `Connection`.
- D-09 — Default opt-out (`auto_refresh_enabled: false`). Mirror Phase 19 `idp_initiated_not_allowed` great-error pattern.
- D-10 — Cadence enum `[:hourly, :every_6h, :daily, :weekly]`. No cron strings, no free-form interval_seconds.
- D-11 — Default cadence `:daily`.
- D-12 — Persisted `next_refresh_at` with ±15% jitter applied once per scheduling decision. Partial index on `next_refresh_at` filtered by `auto_refresh_enabled` AND not suspended.
- D-13 — No per-source override beyond the four presets. No global default cadence config.
- D-14 — Hybrid cadence semantics: operator preset authoritative; **1-hour hard floor** baked into the resolver helper; warn-only `:validity_warning` event when current metadata's `validUntil` < `2 × refresh_interval`.

**Security Guardrails (asymmetric strictness for the unattended path)**
- D-15 — `require_signed_metadata` defaults `true` on every auto-refresh-enabled source. Manual import unchanged.
- D-16 — XMLDSig verification on metadata root **before** normalization/parse-deeply/apply. Reuse `Relyra.Security.Signature.verify`.
- D-17 — Operator-pinned `metadata_trust_fingerprints` (SHA-256 hex, multi-valued). Reject TOFU. Reject reuse-of-assertion-cert.
- D-18 — Drift detection auto-suspends. Fetched `entityID` ≠ stored OR new signing-cert fingerprint not in `last_known_metadata_signing_certs` → set `auto_suspended_until` + typed `auto_suspended_reason`. New certs still stage as `:next` per Phase 10/12 D-08.
- D-19 — Escape hatch `legacy_unsigned_metadata_policy` mirrors `legacy_algorithm_policy` (allow_until + reason + audit).
- D-20 — Stricter Req profile: 30s+30s timeouts, no redirects, 5MB cap, accepted content-types `application/samlmetadata+xml`/`application/xml` (warn-only `text/xml`), fixed `User-Agent: Relyra-MetadataRefresh/<version>`.
- D-21 — Security-corpus regression fixtures as post-parse pre-apply gate on the scheduled path. Refusal triggers set `auto_suspended_reason: :corpus_violation`.
- D-22 — Trust-anchor fingerprint operator UX (Mix task vs admin-LiveView vs both) is the planner's call; behavior locked.

**Failure Handling, Telemetry, Auto-Suspend**
- D-23 — Separate telemetry namespace `[:relyra, :saml, :metadata, :auto_refresh, :start | :stop | :exception]`. Existing `[:relyra, :saml, :metadata, :refresh]` is **untouched**.
- D-24 — Three additional state-transition events: `:degraded`, `:suspended`, `:recovered`. Plus `:validity_warning` from D-14.
- D-25 — Auto-suspend after 5 consecutive transient failures. Exponential backoff capped 24h (1h→6h→24h→24h…) ±10% jitter. Soft backoff with half-open probe semantics.
- D-26 — Suspension never flips `auto_refresh_enabled`. Operator's intent preserved; suspension is its own field.
- D-27 — Asymmetric failure classification. Transient: count toward suspend, alert from 2nd. Non-transient: alert immediately, never count toward suspend. Each error code carries `transient?: bool` and `counts_toward_suspend?: bool` flags exposed in telemetry metadata.
- D-28 — Health state denormalized on `MetadataSource`. **All** counter/state updates happen inside `MetadataApply.record_attempt/3` transaction (single audit-writer seam invariant).
- D-29 — Admin LiveView surface: micro-badge on connection list (amber `auto-refresh degraded` / red `auto-refresh suspended` with tooltip), compact health card on connection metadata page, "Resume now" button when suspended (audit `live_admin_auto_refresh_resume`).
- D-30 — Optional reference handler `Relyra.Telemetry.Handlers.LogAlerts` (~50 LOC) ships in docs/examples surface, not default-attached.
- D-31 — Failure muting out of scope for v0.5.

**Schema Additions to `Relyra.Ecto.MetadataSource` (LOCKED field set; column names refinable):**
auto_refresh_enabled, refresh_cadence, next_refresh_at, require_signed_metadata, metadata_trust_fingerprints, legacy_unsigned_metadata_policy, last_known_metadata_signing_certs, consecutive_failure_count, first_failure_at, last_success_at, last_failure_error_code, auto_suspended_until, auto_suspended_reason. Plus partial index on `next_refresh_at` WHERE `auto_refresh_enabled` AND not suspended.

**Locked-Forward Invariants (do NOT violate):**
D-32 stage-only certs · D-33 last-known-good · D-34 two-boundary apply · D-35 single audit-writer seam · D-36 runtime never depends on live fetch · D-37 optional-deps gateway pattern · D-38 sequential per-batch · D-39 auto correlation_id

### Claude's Discretion

- Exact module names and file layout for scheduler / gateway / worker (provided D-01 / D-02 / D-04 / D-05 hold).
- Exact column names and Ecto types for schema additions (provided field set preserved).
- Exact failure-classification flag mechanism (per-error-code metadata vs separate table vs at-emit-time).
- Exact admin-LiveView visual treatment within D-29 spec.
- Exact migration ordering, default-value backfill strategy, lock_version handling.
- Exact Req configuration plumbing for stricter scheduled-path profile (D-20 invariants hold).
- D-22 admin-LiveView fingerprint-pinning UX (Mix task vs admin-only vs both) — strong recommendation requested.
- Whether security-corpus gate (D-21) reuses test corpus directly or extracts to a runtime-callable validator module.

### Deferred Ideas (OUT OF SCOPE)

- Diff-preview UX for incoming metadata revisions (Phase 09 D-05; revisit v0.6+).
- Federation aggregator support / MDQ resolver (`kind: :mdq`); schema is shaped so this is additive.
- Vendor-specific paging integrations (Slack / PagerDuty / Sentry); telemetry events are the contract.
- `validUntil`-aware automatic cadence shifts (warn-only in v0.5 per D-14; revisit v0.6+).
- Failure muting / "I know it's broken, stop telling me".
- Top-level cross-tenant auto-refresh health dashboard (per-connection badges + health card cover v0.5).
- TOFU mode for trust-anchor pinning as an explicit opt-in.
- Mix task `mix relyra.metadata.pin <source_id> --url <url>` as candidate fingerprint UX (deferred to plan-phase per D-22).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **CFG-08** | User can enable scheduled metadata refresh automation with guardrails. | The full RESEARCH.md addresses CFG-08: scheduler entry point shape (Step "Scheduler Entry Point"), opt-in schema (Step "Schema Extension"), security guardrails (Steps "XMLDSig", "Trust Fingerprint Pinning", "Failure Classification"), alerting/audit (Steps "Telemetry Catalog", "Health State Machine"). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist in the working directory. Project-level conventions are sourced from `.planning/PROJECT.md`, `.planning/STATE.md`, `prompts/relyra-engineering-dna-from-prior-libs.md`, and `prompts/relyra-brand-book.md`.

**Hard constraints (PROJECT.md):**
- Elixir `~> 1.18` (mix.exs declares `~> 1.19`), OTP 26+/27+/28 matrix, Phoenix 1.8.x, LiveView 1.1.x, Ecto 3.13.x, Plug current stable.
- One hardened XML parser path. DTDs + entities + network fetches disabled before any parse.
- Signature trust source = configured IdP certs only. Never document `KeyInfo`. Verified signature bound to consumed node.
- Trust-mutation auditability: every connection / metadata / certificate / mapping mutation co-commits an audit row inside the same transaction. Audit payloads redaction-safe.
- Strict-defaults; explicit time-boxed escape hatches via `legacy_*_policy` shape.
- Brand: "Auto-refresh", "schedule", "suspended", "resume now", "metadata trust fingerprint", "validity warning". Avoid "polling", "cron job", "blocked", "retry", "circuit breaker" in operator copy.

---

## Summary

Phase 21 is a fan-out + scheduling-state layer over the locked Phase 09/12 metadata-refresh contract. The trust-mutation seam (`MetadataApply.apply_revision/4` + `record_attempt/3` + `AuditWriter.append_event`) is unchanged; Phase 21 adds (a) one new public function `Relyra.Metadata.Scheduler.run_due/2` that picks due rows and loops through `Relyra.Metadata.Refresh.refresh/2`, (b) one new optional-deps gateway `Relyra.OptionalDeps.Oban` plus a worker `Relyra.Workers.MetadataRefresh` that compiles whether or not Oban is in the deps tree, (c) thirteen new fields and one partial index on `relyra_metadata_sources`, (d) signed-metadata verification at the metadata root **before** normalization/parse-deeply via the existing `Relyra.Security.Signature.verify` primitive, (e) an asymmetric-failure state machine (`:degraded`/`:suspended`/`:recovered`/`:validity_warning`) wired through a separate `[:relyra, :saml, :metadata, :auto_refresh, ...]` telemetry namespace, and (f) two LiveView extensions (micro-badge on the connection list, health card + "Resume now" button on the connection metadata page).

The biggest leverage point is **D-28**: every counter, every state field, every `auto_suspended_until` mutation lives **inside** the existing `MetadataApply.record_attempt/3` transaction. There is no new audit-writer seam; there is no parallel "scheduler-state" repo module. This makes the implementation surface much smaller than the field count suggests, and it is the single discipline that prevents the audit ledger from drifting from the health state.

**Primary recommendation:** Land the schema migration first (Wave 0), the failure classifier and cadence-resolver as pure functions in Wave 1 (heavily property-tested), the `Scheduler.run_due/2` + `OptionalDeps.Oban` gateway + worker in Wave 2 (the new public surface), the LiveView extensions in Wave 3, and the documentation recipes (Oban Cron one-liner, Mix task, k8s CronJob, fly.io schedule) as a Wave 4 ride-along. Pin Oban at `~> 2.22` (current 2.22.1, published 2026-04-30) — exactly the version Phase 21 needs for `unique: [period: :infinity]` semantics and `Oban.Peers.Database` leader election.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cadence resolution + jitter applier (preset → next_refresh_at) | Domain (pure Elixir, `Relyra.Metadata.Scheduler`) | — | Pure function, deterministic-with-jitter, testable in isolation. No I/O. |
| Due-row selection ("what's due?") | Database / Storage (Postgres partial index) | Domain (`Scheduler.run_due/2` issues the query) | Single index scan via partial index keeps the scheduler tick O(due-count), not O(rows). |
| Per-source fetch + parse + validate + apply | Domain (`Relyra.Metadata.Refresh.refresh/2` — UNCHANGED) | API/HTTP (Req) | Phase 21 explicitly **does not** re-implement this; it wraps it. |
| XMLDSig metadata-root verification | Domain (`Relyra.Security.Signature.verify` — UNCHANGED primitive) | New caller in `Refresh` (or wrapper) before normalization/parse-deeply | Reuse the trust primitive; do not introduce a parallel verifier. |
| Trust-anchor fingerprint check (operator-pinned) | Domain (new helper `Relyra.Metadata.TrustAnchor`, called pre-verify) | Database (reads `metadata_trust_fingerprints`) | Belongs in the trust boundary, not the LiveView. |
| Drift detection (entityID compare + signing-cert fingerprint diff) | Domain (new helper inside `Refresh` post-parse pre-apply) | Database (reads `last_known_metadata_signing_certs`) | Stays inside the existing two-boundary apply. |
| Health state mutation (counters / `auto_suspended_until`) | Database (transactional) — co-committed inside `MetadataApply.record_attempt/3` | — | D-28: ALL state updates inside the existing audit-writer seam. No parallel writer. |
| Failure classification | Domain (pure function, error-code → `{transient?, counts_toward_suspend?, alert_immediately?}`) | — | Pure function. Decision tagged at emit time so telemetry payload carries the flags. |
| Backoff schedule (1h→6h→24h cap) | Domain (pure function) | — | Pure function over consecutive-failure count. Property-testable. |
| Half-open probe gate | Domain (`Scheduler.run_due/2` checks `auto_suspended_until <= now`, runs one source) | — | The probe is just a normal due-source pickup once `auto_suspended_until` passes. |
| Background scheduling driver | Host application (Oban Cron / Quantum / k8s `CronJob` / `mix` task / fly.io schedule) | Optional `Relyra.Workers.MetadataRefresh` (Oban) | D-04: Relyra owns no ticker. Adopters opt in. |
| Multi-node dedup | External (Oban `unique:` constraint + `Oban.Peers.Database`) | — | D-03: delegated to Oban, not implemented in Relyra. |
| Telemetry emission | Domain (`Relyra.Telemetry.span/3` — existing primitive) | — | New event namespace, existing emission shape. |
| Optional reference log handler | Docs/examples surface | — | D-30: ships in `docs/examples`, not as a default-attached handler. |
| Admin LiveView surface (badge + health card + "Resume now") | LiveView (extends `ConnectionList` + `ConnectionMetadataLive` — no new mount, no new route) | Domain (queries `MetadataSource` health fields) | D-29: piggyback on existing surfaces. |
| Documentation recipes (Oban Cron, Mix task, k8s, fly.io) | Docs/examples surface | — | D-06: copy-pasteable recipes are non-optional deliverable. |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `oban` | `~> 2.22` (verified current: **2.22.1**, published 2026-04-30) | Optional Oban Cron driver + worker behind `Relyra.OptionalDeps.Oban` gateway | The only Elixir background-job library with mature `unique:` job constraints, leader-election (`Oban.Peers.Database`) for multi-node dedup, and a built-in `Oban.Plugins.Cron` plugin. Hex requirements: Elixir 1.15+, Erlang 24+, Postgres 14+ / MySQL 8.4+ / SQLite 3.37.0+ — comfortably under Relyra's `~> 1.19` floor. [VERIFIED: hex.pm/packages/oban; CITED: hexdocs.pm/oban] |
| `req` | `~> 0.5` (already an optional dep) | Stricter scheduled-path Req profile per D-20 | Already used by `Relyra.Metadata.Refresh.refresh/2`. Phase 21 adds a stricter profile, not a new dep. [VERIFIED: mix.exs] |
| `ecto` / `ecto_sql` / `postgrex` | `~> 3.13` (already optional) | Schema extension + partial index | Reuses existing optional-deps stack. [VERIFIED: mix.exs] |
| `telemetry` | `~> 1.3` (already required) | New `[:relyra, :saml, :metadata, :auto_refresh, ...]` namespace | Reuses existing primitive `Relyra.Telemetry.span/3`. [VERIFIED: mix.exs + lib/relyra/telemetry.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_live_view` | `~> 1.1` (already optional) | LiveView extensions (D-29) | When admin LiveView is mounted; existing `start_async(:metadata_refresh, ...)` pattern at `connection_metadata_live.ex:80-114` is the template for "Resume now". [VERIFIED: mix.exs + grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban (D-02) | Quantum, Erlang `:timer`, GenServer ticker | All three would force Relyra to ship its own ticker → contradicts D-04 ("a library that owns its own background loop owns its own multi-node footguns" — Spring Security SAML #9134, early Shibboleth). Oban is the only one that ships free `unique:` dedup + leader election. **Recommendation: Oban-only**, period. |
| Operator-pinned fingerprints (D-17) | TOFU on first fetch | TOFU institutionalizes a one-shot MITM at enable-time. Locked rejection. |
| Free-form interval_seconds (D-10) | Cron strings or seconds | Cron strings = DDoS-the-IdP footgun; seconds = unit-confusion + `every 30s` support tickets. Locked: 4-preset enum. |

**Installation (host application):**
```bash
# Required for v0.5 auto-refresh: add Oban + a peer table migration
mix deps.get  # after adding {:oban, "~> 2.22"} to host's mix.exs
```

**Version verification:**
```bash
# As of 2026-05-06:
# - Oban v2.22.1 published 2026-04-30 (hex.pm/packages/oban)
# - Req v0.5.x (already pinned)
# - Phoenix.LiveView 1.1.x (already pinned)
```

---

## Architecture Patterns

### System Architecture Diagram

```
                         ┌────────────────────────────────────┐
HOST APP SCHEDULER ────► │ Relyra.Metadata.Scheduler          │
(Oban Cron / k8s        │   .run_due(repo, opts)              │  ◄── pure function (D-01, D-04)
 / fly.io / mix task)    │                                    │
                         │  1. Generate correlation_id        │  (Phase 20 BulkActions pattern, D-39)
                         │  2. Query due rows (partial index) │
                         │  3. For each due row, sequential:  │  (D-38)
                         └────────────────────┬───────────────┘
                                              │
                                              ▼
                         ┌────────────────────────────────────┐
                         │ Relyra.Metadata.Refresh.refresh/2  │  (UNCHANGED — Phase 21 wraps, D-05)
                         │   wrapped with auto_refresh shell: │
                         └────────────────────┬───────────────┘
                                              │
                          ┌───────────────────┼─────────────────────────────┐
                          ▼                   ▼                             ▼
                ┌──────────────────┐  ┌────────────────────┐  ┌────────────────────────┐
                │ Stricter Req     │  │ Trust-anchor       │  │ XMLDSig verify         │
                │ profile (D-20)   │  │ fingerprint check  │  │ on metadata root       │
                │ 30+30s, no       │  │ (D-17) — operator- │  │ (D-16) — BEFORE        │
                │ redirects, 5MB   │  │ pinned only, no    │  │ parse-deeply, reusing  │
                │ cap, fixed UA    │  │ TOFU               │  │ Security.Signature     │
                └─────────┬────────┘  └─────────┬──────────┘  └────────────┬───────────┘
                          │                     │                          │
                          └─────────────────────┼──────────────────────────┘
                                                ▼
                                ┌────────────────────────────────┐
                                │ Parser.parse → Import.build_   │
                                │   candidate (UNCHANGED)        │
                                └────────────────┬───────────────┘
                                                 │
                                                 ▼
                                ┌────────────────────────────────┐
                                │ Security-corpus gate (D-21)    │
                                │ post-parse, pre-apply          │
                                └────────────────┬───────────────┘
                                                 │
                                                 ▼
                                ┌────────────────────────────────┐
                                │ Drift detector (D-18):         │
                                │   entityID compare +           │
                                │   signing-cert fingerprint     │
                                │   diff vs                      │
                                │   last_known_metadata_         │
                                │   signing_certs                │
                                └────────────────┬───────────────┘
                                                 │
                                  ┌──────────────┴──────────────┐
                                  ▼                             ▼
                       drift detected?                 OK → continue
                                  │
                                  ▼
                       set auto_suspended_*
                       inside record_attempt/3
                       (still stages cert as :next per D-32)
                                  │
                                  └──────────────┐
                                                 ▼
                                ┌────────────────────────────────┐  ◄── ALL counter / state
                                │ MetadataApply                  │      updates happen INSIDE
                                │   .apply_revision/4 (success)  │      this transaction (D-28)
                                │   .record_attempt/3 (failure)  │
                                │   + AuditWriter.append_event   │      (D-35: single audit-writer seam)
                                │   + Phase 21 health-state      │
                                │     side-update (transactional)│
                                └────────────────┬───────────────┘
                                                 │
                                                 ▼
                                ┌────────────────────────────────┐
                                │ Telemetry emit (D-23/D-24):    │
                                │   :start / :stop / :exception  │
                                │   :degraded / :suspended /     │
                                │   :recovered / :validity_      │
                                │   warning                      │
                                │   metadata: correlation_id,    │
                                │   source_id, error_code,       │
                                │   transient?, counts_toward_   │
                                │   suspend?                     │
                                └────────────────┬───────────────┘
                                                 │
                                                 ▼
                                ┌────────────────────────────────┐
                                │ Optional reference handler:    │
                                │   Relyra.Telemetry.Handlers.   │
                                │   LogAlerts (~50 LOC, docs/    │
                                │   examples, NOT default-       │
                                │   attached) (D-30)             │
                                └────────────────────────────────┘

LiveView surface (D-29) reads denormalized health state via Query module:
  ConnectionsLive list → micro-badge per row (degraded/suspended)
  ConnectionMetadataLive → "Auto-refresh health" card + "Resume now" button
                                            │
                                            └──► writes audit
                                                 (live_admin_auto_refresh_resume)
                                                 → triggers immediate probe
```

### Recommended Project Structure

```
lib/relyra/
├── metadata/
│   ├── refresh.ex              # UNCHANGED — Phase 21 wraps via scheduler
│   ├── scheduler.ex            # NEW — Relyra.Metadata.Scheduler
│   │                              run_due/2 (D-01), cadence helpers,
│   │                              jitter applier, due-rows query
│   ├── auto_refresh.ex         # NEW — wrapper that adds D-15..D-21
│   │                              checks (signed-required, trust anchor,
│   │                              XMLDSig pre-verify, drift, corpus gate)
│   │                              before delegating to Refresh.refresh/2
│   ├── failure_classifier.ex   # NEW — pure function:
│   │                              error_code → {transient?, counts_*, alert_*}
│   ├── trust_anchor.ex         # NEW — fingerprint pin check (D-17)
│   └── drift_detector.ex       # NEW — entityID + cert-fp diff (D-18)
├── workers/
│   └── metadata_refresh.ex     # NEW — Oban worker (D-02), gated on
│                                  Code.ensure_loaded?(Oban)
├── optional_deps/
│   └── oban.ex                 # NEW — Relyra.OptionalDeps.Oban gateway
│                                  (canonical pattern for v0.5+)
├── ecto/
│   └── metadata_source.ex      # EXTENDED — 13 new fields + changeset/2
│                                  helpers for the auto-refresh sub-domain
└── telemetry/
    └── handlers/
        └── log_alerts.ex       # NEW (docs/examples surface, not lib/)
                                  — actually lives under
                                  examples/telemetry_handlers/log_alerts.ex
                                  per D-30

priv/repo/migrations/
└── YYYYMMDDHHMMSS_extend_relyra_metadata_sources_with_auto_refresh.exs
                                # NEW — single consolidated migration

test/relyra/metadata/
├── scheduler_test.exs          # cadence + jitter + due-query
├── failure_classifier_test.exs # pure-function table + property tests
├── auto_refresh_test.exs       # signed-vs-unsigned-vs-drift-vs-corpus paths
├── trust_anchor_test.exs       # fingerprint matching + rotation
├── drift_detector_test.exs     # entityID + cert-fp diff
└── workers/
    └── metadata_refresh_test.exs  # Oban-present compile + perform
                                # (separate Oban-absent compile lane in CI)
```

### Pattern 1: Optional-Deps Gateway (canonical, D-37)

**What:** A thin compile-time-safe wrapper that lets dependent code reference an absent module without warnings or runtime crashes.

**When to use:** Any external lib that is `optional: true` in mix.exs. Phase 21 adds Oban; same pattern as Ecto/LiveView already in the tree.

**Example (recommended skeleton):**
```elixir
# Source: pattern derived from existing Code.ensure_loaded?/1 callsites in
#   lib/relyra/ecto/audit_writer.ex (lines 65-68),
#   lib/relyra/ecto/metadata_apply.ex (lines 198-211),
#   lib/relyra/replay_store.ex (line 67),
#   lib/relyra/connection_resolver.ex (line 34)
# extracted into a single canonical gateway module per D-37.
defmodule Relyra.OptionalDeps.Oban do
  @moduledoc """
  Optional-dep gateway for Oban. Lets the Phase 21 worker compile and
  load whether or not Oban is present in the host's deps tree.

  When Oban is loaded: `available?/0` returns true and the worker is
  usable. When Oban is absent: `available?/0` returns false and any
  attempt to insert/run a job returns `{:error, %Relyra.Error{type:
  :optional_dependency_missing}}`.
  """

  # The @compile attribute silences "module Oban is not available"
  # warnings at compile time when Oban is absent. This is the canonical
  # Elixir idiom for optional integrations.
  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}

  @spec available?() :: boolean()
  def available? do
    Code.ensure_loaded?(Oban) and Code.ensure_loaded?(Oban.Worker)
  end

  @spec ensure_available!(atom()) :: :ok | {:error, Relyra.Error.t()}
  def ensure_available!(operation) do
    if available?() do
      :ok
    else
      {:error,
       Relyra.Error.new(
         :optional_dependency_missing,
         "Oban is unavailable; add `{:oban, \"~> 2.22\"}` to deps to use scheduled metadata refresh",
         %{operation: operation, missing_dependency: :oban}
       )}
    end
  end
end
```

**Worker file shape (Pattern 1 applied):**
```elixir
# lib/relyra/workers/metadata_refresh.ex
defmodule Relyra.Workers.MetadataRefresh do
  @moduledoc """
  Optional Oban worker that drives `Relyra.Metadata.Scheduler.run_due/2`.
  Compiles whether or not Oban is in the deps tree.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  if Code.ensure_loaded?(Oban.Worker) do
    use Oban.Worker,
      queue: :relyra_metadata,
      max_attempts: 1,                     # we manage our own backoff per D-25
      unique: [
        period: :infinity,
        states: [:available, :scheduled, :executing],
        keys: [:source_id]
      ]

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      # opts come from job args; repo from host config
      Relyra.Metadata.Scheduler.run_due(repo_for(args), opts_for(args))
    end

    defp repo_for(args), do: args |> Map.fetch!("repo") |> String.to_existing_atom()
    defp opts_for(args), do: Map.get(args, "opts", []) |> normalize_opts()
    defp normalize_opts(opts) when is_list(opts), do: opts
    defp normalize_opts(_), do: []
  else
    # Oban-absent compile path: still defines the module so users can
    # reference it in docs/examples without crashing the compiler.
    def perform(_job) do
      Relyra.OptionalDeps.Oban.ensure_available!(:perform)
    end
  end
end
```

### Pattern 2: Cadence Resolver (pure function, locked-in 1h hard floor per D-14)

**What:** Pure function from cadence preset → `next_refresh_at` with persistent ±15% jitter.

**When to use:** Anywhere a `MetadataSource.next_refresh_at` is being set.

**Example (recommended shape):**
```elixir
# lib/relyra/metadata/scheduler.ex
defmodule Relyra.Metadata.Scheduler do
  @moduledoc "..."

  # Locked: 1-hour hard floor (InCommon ≤1/hour ceiling per D-14).
  # Baked into the helper so even a future enum revision can't bypass it.
  @hard_floor_seconds 3600

  @cadence_seconds %{
    hourly:    3_600,
    every_6h:  21_600,
    daily:     86_400,
    weekly:    604_800
  }

  @doc """
  Computes the next refresh time given a cadence preset and a base time.
  Applies ±15% jitter ONCE (D-12: persisted, not recomputed on tick).
  Enforces the 1-hour InCommon hard floor (D-14).
  """
  @spec next_refresh_at(atom(), DateTime.t()) :: DateTime.t()
  def next_refresh_at(cadence, %DateTime{} = base \\ DateTime.utc_now())
      when is_map_key(@cadence_seconds, cadence) do
    interval = Map.fetch!(@cadence_seconds, cadence)
    floored = max(interval, @hard_floor_seconds)
    jittered = apply_jitter(floored, 0.15)
    DateTime.add(base, jittered, :second)
  end

  defp apply_jitter(seconds, ratio) do
    span = round(seconds * ratio)
    seconds + Enum.random(-span..span)
  end
end
```

### Pattern 3: Failure Classifier (pure function, D-27)

**Recommendation:** at-emit-time inference via a single pure function. NOT a separate Ecto table (overkill), NOT per-error-code metadata scattered across modules (drift footgun). One module, one function, fully exhausted by typespec — when a new error code lands, the compiler tells you to add a clause.

```elixir
# lib/relyra/metadata/failure_classifier.ex
defmodule Relyra.Metadata.FailureClassifier do
  @moduledoc """
  Pure classifier per D-27. `transient?` errors count toward auto-suspend
  and alert from the 2nd consecutive occurrence. Non-transient errors
  alert immediately and never count toward suspend.
  """

  @type classification :: %{
    transient?: boolean(),
    counts_toward_suspend?: boolean(),
    alert_immediately?: boolean()
  }

  @spec classify(atom()) :: classification()
  # Transient: count toward suspend, suppress single-blip alert
  def classify(:fetch_timeout),         do: transient()
  def classify(:fetch_http_5xx),        do: transient()
  def classify(:fetch_dns_failure),     do: transient()
  def classify(:fetch_connection_refused), do: transient()
  def classify(:fetch_tls_handshake),   do: transient()
  # Non-transient: alert immediately, never count toward suspend
  def classify(:signature_failed),      do: suspicious()
  def classify(:parse_failed),          do: suspicious()
  def classify(:validation_failed),     do: suspicious()
  def classify(:apply_failed),          do: suspicious()
  def classify(:fetch_http_4xx),        do: suspicious()
  def classify(:metadata_drift_requires_review), do: suspicious()
  def classify(:corpus_violation),      do: suspicious()
  def classify(:trust_anchor_mismatch), do: suspicious()  # D-17
  def classify(_other),                 do: unknown()      # default: alert + don't count

  defp transient,  do: %{transient?: true,  counts_toward_suspend?: true,  alert_immediately?: false}
  defp suspicious, do: %{transient?: false, counts_toward_suspend?: false, alert_immediately?: true}
  defp unknown,    do: %{transient?: false, counts_toward_suspend?: false, alert_immediately?: true}
end
```

### Pattern 4: Backoff Schedule (pure function, D-25)

```elixir
# lib/relyra/metadata/scheduler.ex (continued)

@backoff_tiers_seconds [3_600, 21_600, 86_400]  # 1h → 6h → 24h cap

@spec backoff_until(non_neg_integer(), DateTime.t()) :: DateTime.t()
def backoff_until(consecutive_failures, %DateTime{} = base \\ DateTime.utc_now()) do
  tier_index = min(consecutive_failures - 5, length(@backoff_tiers_seconds) - 1)
  tier = Enum.at(@backoff_tiers_seconds, max(tier_index, 0))
  jittered = apply_jitter(tier, 0.10)  # ±10% per D-25
  DateTime.add(base, jittered, :second)
end
```

### Pattern 5: Due-Rows Query (Postgres partial index, D-12)

```sql
-- Inside the migration:
CREATE INDEX relyra_metadata_sources_due_idx
  ON relyra_metadata_sources (next_refresh_at)
  WHERE auto_refresh_enabled = true
    AND (auto_suspended_until IS NULL OR auto_suspended_until <= now());
```

```elixir
# Inside Scheduler.run_due/2:
defp due_query(now) do
  from src in MetadataSource,
    where: src.auto_refresh_enabled == true,
    where: is_nil(src.auto_suspended_until) or src.auto_suspended_until <= ^now,
    where: is_nil(src.next_refresh_at) or src.next_refresh_at <= ^now,
    order_by: [asc: src.next_refresh_at],
    select: src
end
```

The `is_nil(src.next_refresh_at)` clause covers the just-enabled case (no `next_refresh_at` set yet — it's due immediately, then `apply_revision/4` co-commits the next jittered timestamp).

### Anti-Patterns to Avoid

- **GenServer ticker / `Process.send_after/3` loop in lib/.** Owns its own multi-node footgun; contradicts D-04. Spring Security SAML #9134 is the canonical lesson.
- **Computing `next_refresh_at` at scheduler-tick time instead of persisting.** Re-rolls jitter on host restart → double-fire. D-12: persist once.
- **Updating health counters outside the `record_attempt/3` transaction.** Drifts from the audit ledger; violates D-28 + D-35.
- **Verifying signature after parsing-deeply.** XXE-before-verify class (esaml 2026 NVD); D-16 says verify on the root **first**.
- **Trusting document-provided `KeyInfo` for the metadata signature.** ruby-saml CVE-2024-45409 lesson; D-17 mandates operator-pinned fingerprints only.
- **Auto-promoting newly-seen signing certs.** Always stage as `:next`; D-32 + Phase 10/12 D-08.
- **Branching `Refresh.refresh/2` into a "scheduled" code path.** Wraps it from outside; do not edit it.
- **Letting "Resume now" skip the audit row.** Every operator action through the LiveView writes via `AuditWriter.append_event` per D-35.
- **Cron strings in the schema** (DDoS-the-IdP footgun). Locked to 4-preset enum per D-10.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-node "only one node should refresh" dedup | Ecto advisory locks, ETS lookups, `:global.set_lock` | Oban `unique:` constraint + `Oban.Peers.Database` (D-03) | Already shipped, battle-tested, leader-election handles partitions correctly. |
| Cron-string parsing | Manual `* * * * *` parser | Oban `Oban.Plugins.Cron` (host config; D-06) | Locked: Relyra never accepts cron strings (D-10). Adopters who want cron use Oban Cron in their own config. |
| XML signature verification on metadata root | New XMLDSig module | `Relyra.Security.Signature.verify/4` (D-16, existing primitive) | One verifier path is the SEC invariant. PROJECT.md "no parser differentials." |
| HTTP request retries | Custom retry-with-backoff Req plugin | None for the scheduled path — Phase 21 owns its OWN backoff via the auto-suspend state machine. Single attempt per scheduler tick. | Mixing Req's per-request retry with Phase 21's per-source backoff is the double-counting footgun. One attempt per `run_due/2` per source; the schedule controls cadence. |
| Telemetry handler attach lifecycle | `Application.start/2` boot block in lib/ | `Relyra.Telemetry.Handlers.LogAlerts` documented as adopter-attached (D-30) | Attaching by default = silent on/off behavior across upgrades. Adopters opt in. |
| Fingerprint computation | Hand-rolled hex/base16 SHA-256 | `:crypto.hash(:sha256, pem) \|> Base.encode16(case: :lower)` (already used in `lib/relyra/metadata/refresh.ex:218`) | Existing convention. |
| ULID / correlation ID generation | Custom UUID encoder | `Ecto.UUID.generate()` (already used in `lib/relyra/ecto/bulk_actions.ex:16`) | Phase 20 BulkActions pattern; D-39 reuse. |
| Postgres partial-index DSL | Raw SQL in `execute/1` | `create index(..., where: "...")` (Ecto.Migration native) | One-liner, type-safe, plays with `mix ecto.dump` cleanly. |

**Key insight:** Phase 21 introduces zero new "build it from scratch" subsystems. Every subsystem either reuses an existing seam (`Refresh.refresh/2`, `MetadataApply.record_attempt/3`, `Signature.verify`, `AuditWriter.append_event`) or delegates to an external library (Oban for scheduling primitives). The implementation surface is overwhelmingly schema fields + small pure functions + one optional gateway module + LiveView extensions.

---

## Runtime State Inventory

This phase introduces fresh schema fields on an existing table. There is no rename / refactor / migration of pre-existing strings. Items below are the runtime state Phase 21 *creates* (not pre-existing state to migrate).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | 13 new columns on `relyra_metadata_sources` (existing table); 1 new partial index; existing rows backfill cleanly: `auto_refresh_enabled = false`, `refresh_cadence = :daily` (unused while disabled), `require_signed_metadata = true` (unused while disabled), all health fields nil/0. | Single Ecto migration (Wave 0). No data backfill required for existing rows beyond defaults. |
| Live service config | Adopters must add Oban Cron one-liner in *their* config — not in Relyra. Documented in README "Operations" section (D-06). | Documentation deliverable; no Relyra code action. |
| OS-registered state | None — no Windows Task Scheduler, launchd, systemd, or pm2 entries created by Relyra. Adopters' k8s/fly.io schedule registrations are documented but not registered by Relyra. | None — verified by inspection (`grep -r "Task Scheduler\|launchd\|systemd" lib/` returns no matches). |
| Secrets/env vars | None new. `metadata_trust_fingerprints` lives in the database (operator-pinned, not a secret in the env-var sense). The fixed `User-Agent: Relyra-MetadataRefresh/<version>` reads from `Application.spec(:relyra, :vsn)`. | None. |
| Build artifacts / installed packages | Adding `{:oban, "~> 2.22", optional: true}` to mix.exs creates `_build/.../lib/oban/` artifacts on adopters' machines that DO add Oban. Relyra's CI matrix gains a Postgres + Oban smoke lane; the existing `mix compile --no-optional-deps --warnings-as-errors` lane stays green. | CI lane addition is a Wave-4 deliverable. |

**The canonical question:** *After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?* — N/A; this is greenfield additive work, not a rename.

---

## Common Pitfalls

### Pitfall 1: Counter drift from the audit ledger
**What goes wrong:** A bug or a partial migration causes `consecutive_failure_count` to go up while no `MetadataRevision` row records the attempt.
**Why it happens:** Health-state writes accidentally placed in a separate transaction (or no transaction) from `record_attempt/3`.
**How to avoid:** D-28 is the discipline — every `auto_suspended_until` / `consecutive_failure_count` / `last_failure_error_code` mutation must be added to the existing `record_attempt/3` and `apply_revision/4` transactions. Concretely, extend the `revision_attrs_for_apply/3` and the `failure_details/2` flows to compute the new health state and pass it in to a single combined update changeset on `MetadataSource`. Test: integration test that asserts every `auto_suspended_until` change is paired with a `MetadataRevision` row sharing the same `correlation_id`.
**Warning signs:** Test failures where the audit table and the source row disagree on attempt count.

### Pitfall 2: Validity-warning event spam (D-14 specifics)
**What goes wrong:** `:validity_warning` fires once per scheduler tick → adopter wired to PagerDuty gets 24 pages a day for the same `validUntil` window.
**Why it happens:** "At most once per `validUntil` window" requires de-dup state.
**How to avoid:** Persist the last `validUntil` value emitted into a small JSON map on `MetadataSource.metadata` (already a `:map` field, currently mostly unused — convenient parking spot, no schema change). On each scheduler tick, only emit the warning if `current_metadata_validity != last_warned_validity`. Alternatively, a dedicated `last_validity_warning_for: utc_datetime_usec` column — slightly more explicit, costs one more field. **Recommendation: dedicated column** for explainability (operator can answer "when was the last validity warning?" from `psql` without parsing JSON).
**Warning signs:** Test asserting more than 1 `:validity_warning` event for the same source within one `validUntil` window.

### Pitfall 3: Suspended → "Resume now" race on a clustered Oban
**What goes wrong:** Operator clicks "Resume now" at the same time as a scheduler tick; both insert an Oban job; the `unique:` constraint dedups but the audit row is written before the de-duped job knows it's a no-op.
**Why it happens:** "Resume now" both clears `auto_suspended_until` AND inserts an immediate Oban job; if the job is a duplicate, it returns `{:ok, %Oban.Job{conflict?: true}}` ([CITED: hexdocs.pm/oban Unique Jobs guide]) but the audit already committed.
**How to avoid:** "Resume now" writes the audit row, clears `auto_suspended_until`, and inserts the job in **one transaction** through `record_attempt/3` (outcome `:resume_requested`). The job dispatch happens outside the transaction. The unique constraint guarantees only one execution; the audit row is the operator's intent record regardless.
**Warning signs:** Audit table shows `live_admin_auto_refresh_resume` events with no corresponding refresh attempt row within ~30 seconds.

### Pitfall 4: XMLDSig verify path-traversal regression
**What goes wrong:** `Refresh.refresh/2` currently calls `Parser.parse(xml, opts)` BEFORE any signature check. Phase 21 must insert verification BEFORE this call for the scheduled path.
**Why it happens:** Easy to put the check "wherever it fits" — usually after parse — because `Signature.verify/4` takes a parsed-doc map.
**How to avoid:** Build a thin pre-verifier that (a) does the strict-XML pre-parse (DOCTYPE rejection, ENTITY rejection — same checks `Parser.parse` does at lines 22-26, but isolated), then (b) does a minimal scan to extract just the `<Signature>` element + the `<EntityDescriptor>` envelope, then (c) hands those to `Signature.verify/4`. Only after `:ok` does the candidate flow into `Parser.parse` → `Import.build_candidate`. **Recommendation: extract the DOCTYPE/ENTITY pre-checks from `Parser.parse` into `Relyra.Metadata.Parser.pre_check/1`** that both paths call, so the trust boundary is never bypassed by accident.
**Warning signs:** Security-corpus test for an XXE-shaped fixture that gets through to apply.

### Pitfall 5: `mix compile --no-optional-deps --warnings-as-errors` regressions
**What goes wrong:** Forgetting `@compile {:no_warn_undefined, [...]}` on the new worker → CI lane breaks.
**Why it happens:** New optional integrations bring new module references that must be silenced when the dep is absent.
**How to avoid:** Both `Relyra.OptionalDeps.Oban` AND `Relyra.Workers.MetadataRefresh` carry the `@compile` attribute. Verify with a CI smoke step that runs `mix compile --no-optional-deps --warnings-as-errors` on the bare deps tree (without `oban` in mix.lock).
**Warning signs:** CI red on the `--no-optional-deps` lane after merging Phase 21.

### Pitfall 6: Half-open probe never closes the circuit
**What goes wrong:** After 24h backoff, the source's `auto_suspended_until` passes; one probe runs; if it succeeds, `consecutive_failure_count` should reset to 0 and `:recovered` should fire.
**Why it happens:** "Reset on success" is easy to forget when the failure path got all the attention.
**How to avoid:** In `apply_revision/4`'s success branch, the same transaction that updates `last_success_at` MUST also reset `consecutive_failure_count`, clear `first_failure_at`, clear `last_failure_error_code`, clear `auto_suspended_until` (if it was set), and emit `:recovered` if the previous state was suspended.
**Warning signs:** Integration test where a source recovers but its `consecutive_failure_count` stays at 5 forever.

### Pitfall 7: Drift detection comparing certificate PEMs instead of fingerprints
**What goes wrong:** Comparing PEM strings is whitespace-sensitive; a metadata reformat re-fires "drift detected."
**Why it happens:** Easy to grab `cert.pem` instead of `cert.fingerprint_sha256`.
**How to avoid:** Drift detector compares MapSets of SHA-256 fingerprints only (`last_known_metadata_signing_certs` is already an array of strings per the schema). PEM comparison is forbidden in this code path.
**Warning signs:** False-positive `:new_signing_cert` event on a metadata refresh that just reformatted whitespace.

---

## Code Examples

### Example A: `MetadataSource` schema extension (changeset)

```elixir
# lib/relyra/ecto/metadata_source.ex (extended)
@cadence_values [:hourly, :every_6h, :daily, :weekly]
@suspended_reason_values [
  :entity_id_drift,
  :new_signing_cert,
  :signature_invalid,
  :corpus_violation,
  :transient_failures_exceeded,
  :trust_anchor_mismatch
]

schema "relyra_metadata_sources" do
  # ... existing fields preserved ...

  # Phase 21 additions:
  field :auto_refresh_enabled, :boolean, default: false
  field :refresh_cadence, Ecto.Enum, values: @cadence_values, default: :daily
  field :next_refresh_at, :utc_datetime_usec
  field :require_signed_metadata, :boolean, default: true
  field :metadata_trust_fingerprints, {:array, :string}, default: []
  field :legacy_unsigned_metadata_policy, :map
  field :last_known_metadata_signing_certs, {:array, :string}, default: []
  field :consecutive_failure_count, :integer, default: 0
  field :first_failure_at, :utc_datetime_usec
  field :last_success_at, :utc_datetime_usec
  field :last_failure_error_code, :string
  field :last_validity_warning_for, :utc_datetime_usec
  field :auto_suspended_until, :utc_datetime_usec
  field :auto_suspended_reason, Ecto.Enum, values: @suspended_reason_values

  timestamps(type: :utc_datetime_usec)
end

# Recommendation: split changesets so the auto-refresh sub-domain stays explicit:
def auto_refresh_changeset(source, attrs) do
  source
  |> cast(attrs, [
    :auto_refresh_enabled,
    :refresh_cadence,
    :next_refresh_at,
    :require_signed_metadata,
    :metadata_trust_fingerprints,
    :legacy_unsigned_metadata_policy
  ])
  |> validate_required([:auto_refresh_enabled, :refresh_cadence])
  |> validate_fingerprints_when_enabled()
end

def health_state_changeset(source, attrs) do
  # Called ONLY from MetadataApply.record_attempt/3 + apply_revision/4
  # (D-28: no other call sites).
  source
  |> cast(attrs, [
    :consecutive_failure_count,
    :first_failure_at,
    :last_success_at,
    :last_failure_error_code,
    :last_validity_warning_for,
    :auto_suspended_until,
    :auto_suspended_reason,
    :next_refresh_at,
    :last_known_metadata_signing_certs
  ])
end

defp validate_fingerprints_when_enabled(changeset) do
  case {get_field(changeset, :auto_refresh_enabled), get_field(changeset, :metadata_trust_fingerprints)} do
    {true, []} ->
      add_error(changeset, :metadata_trust_fingerprints,
        "is required when auto_refresh_enabled is true; pin at least one SHA-256 fingerprint via the admin LiveView before enabling auto-refresh")
    _ -> changeset
  end
end
```

### Example B: Migration

```elixir
# Source: pattern derived from
#   priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs
#   priv/repo/migrations/20260505183000_harden_relyra_certificate_lifecycle_invariants.exs
defmodule Relyra.Repo.Migrations.ExtendRelyraMetadataSourcesWithAutoRefresh do
  use Ecto.Migration

  def change do
    alter table(:relyra_metadata_sources) do
      add :auto_refresh_enabled, :boolean, default: false, null: false
      add :refresh_cadence, :string, default: "daily", null: false
      add :next_refresh_at, :utc_datetime_usec
      add :require_signed_metadata, :boolean, default: true, null: false
      add :metadata_trust_fingerprints, {:array, :string}, default: [], null: false
      add :legacy_unsigned_metadata_policy, :map
      add :last_known_metadata_signing_certs, {:array, :string}, default: [], null: false
      add :consecutive_failure_count, :integer, default: 0, null: false
      add :first_failure_at, :utc_datetime_usec
      add :last_success_at, :utc_datetime_usec
      add :last_failure_error_code, :string
      add :last_validity_warning_for, :utc_datetime_usec
      add :auto_suspended_until, :utc_datetime_usec
      add :auto_suspended_reason, :string
    end

    # Partial index per D-12. [CITED: hexdocs.pm/ecto_sql/Ecto.Migration.html#index/3]
    create index(:relyra_metadata_sources, [:next_refresh_at],
             name: :relyra_metadata_sources_due_idx,
             where: "auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())")
  end
end
```

**Lock_version handling:** `relyra_metadata_sources` does NOT currently carry a `lock_version` column (verified via `grep`); only `relyra_connections` and the certificate lifecycle hardening do. Phase 21 does not need `lock_version` on `MetadataSource` because all writes are serialized by the row-level transaction in `record_attempt/3`. **Recommendation: do NOT add `lock_version` to `MetadataSource`.** Keep the schema simpler.

### Example C: Oban Cron one-liner (the README copy-paste recipe per D-06)

```elixir
# In the host application's config/config.exs:
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [relyra_metadata: 1],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Run every 15 minutes; per-source cadence is enforced by Relyra.
       # The :unique constraint on Relyra.Workers.MetadataRefresh
       # prevents double-fetch in a clustered Oban.
       {"*/15 * * * *", Relyra.Workers.MetadataRefresh,
        args: %{"repo" => "MyApp.Repo"}}
     ]}
  ]
```

### Example D: Mix task fallback (the non-Oban recipe per D-06)

```elixir
# lib/mix/tasks/relyra.refresh_due.ex
defmodule Mix.Tasks.Relyra.RefreshDue do
  @moduledoc "Run any due metadata refreshes once. Suitable for `cron` or `kubectl run`."
  @shortdoc "Refresh any metadata sources whose schedule is due."
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, _, _} = OptionParser.parse(args, strict: [repo: :string])
    repo = String.to_existing_atom(opts[:repo] || "MyApp.Repo")
    Relyra.Metadata.Scheduler.run_due(repo, [])
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GenServer / Erlang `:timer` ticker for periodic refresh inside the library | Pure function + optional Oban worker + adopter-driven schedule | Industry shift visible in Spring Security SAML #9134 (2022 lesson) and the broader move from `quantum`-style supervised tickers to `oban`-style operator-controlled scheduling | Eliminates an entire class of multi-node footguns; pushes scheduling concerns outside the trust boundary. |
| TOFU on first metadata fetch | Operator-pinned SHA-256 fingerprints | ruby-saml CVE-2024-45409 (2024) | Eliminates one-shot MITM at enable-time. Slightly worse DX (operator pins out-of-band); mitigated by D-22 LiveView pinning UX. |
| Parse-then-verify XMLDSig | Verify-then-parse (signature on root **before** parse-deeply) | esaml 2026 NVD XXE entry | Eliminates the XXE-before-verify class. |
| Auto-promote new signing certs from refreshed metadata | Stage as `:next`; explicit operator promotion | authentik CVE-2026-25922 + Relyra Phase 10/12 D-08 | Eliminates silent assertion-injection from "we'll figure out which key to trust" logic. |
| Cron strings or `interval_seconds` config | 4-preset enum with 1h hard floor | InCommon Federation Metadata Registration Practice Statement (≤1/hour ceiling) | Eliminates DDoS-the-IdP and unit-confusion footguns. |

**Deprecated/outdated:**
- esaml's pre-OTP-27 XML-entity defaults — Relyra has hardened around this from v0.1; Phase 21 does not regress (verified at lines 22-26 of `lib/relyra/metadata/parser.ex`).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Single Ecto migration is acceptable for adding 13 columns + 1 index. (Inspection of prior migrations shows this pattern is standard in Relyra.) | Schema migration / Wave 0 | If host adopters want phased rollout, they could stage two smaller migrations — but this is a host-side concern, not a Relyra concern. Low risk. |
| A2 | The fixed `User-Agent` should be `Relyra-MetadataRefresh/<vsn>` reading `Application.spec(:relyra, :vsn)`. (Brand-voice convention; not explicitly specified in CONTEXT.md.) | D-20 / Stricter Req profile | Low risk. Adopters who want a custom UA can override the Req profile via `opts[:req]`. |
| A3 | "Resume now" audit row uses `cause: "live_admin_auto_refresh_resume"` exactly. (Mirrors existing `live_admin_metadata_refresh` convention at `connection_metadata_live.ex:71`.) | D-29 | Low risk; matches established pattern. |
| A4 | The `transient?: bool` and `counts_toward_suspend?: bool` telemetry-payload flags should match the `FailureClassifier.classify/1` output keys exactly. | D-23/D-27 | Low risk; consistency between code and docs only. |
| A5 | The CI Postgres + Oban smoke lane is a new mix alias `ci.oban_smoke` (or extends `ci.integration`). Not specified in CONTEXT.md. | CI matrix | Low risk; planner's call within mix-aliases scope. |

**No claim in this research depends on `[ASSUMED]` knowledge for security-critical behavior.** All security-critical claims (D-15..D-21 enforcement) reference verified live code (`lib/relyra/security/signature.ex`, `lib/relyra/metadata/parser.ex`, `lib/relyra/ecto/metadata_apply.ex`).

---

## Open Questions

1. **Trust-anchor pinning UX (D-22) — Mix task vs admin-LiveView vs both?**
   - What we know: behavior is locked (operator pins out-of-band before scheduled refresh activates); UX is the planner's call.
   - **Recommendation (per recommendation-first DX preference): both, with admin-LiveView primary and Mix task as the scriptable fallback.** Rationale: (a) the LiveView is the natural place because operators already pin everything else through it (CFG-06 and Phase 18 audit timeline live there), and the form can show the "compute fingerprint from a fetched metadata document" affordance with a giant "VERIFY OUT-OF-BAND BEFORE SAVING" risk panel (mirroring `risk_panel.ex` already shipped in v0.3); (b) the Mix task `mix relyra.metadata.pin <source_id> --fingerprint <hex>` exists for IaC adopters who manage trust state via Terraform / Pulumi and won't click through a UI. The two share one underlying changeset (`auto_refresh_changeset`), so the risk of divergence is low. **Decision authority: planner, but the architectural shape is clear.**

2. **Should the validity-warning de-dup state live as a JSON key on `MetadataSource.metadata` or a dedicated column?**
   - What we know: D-14 specifics say "fire at most once per `validUntil` window per source"; CONTEXT.md leaves the de-dup state location open.
   - **Recommendation: dedicated `last_validity_warning_for: utc_datetime_usec` column** — explicit, queryable from `psql`, avoids the "what's in this JSON map?" guessing game later.

3. **Should the security-corpus gate (D-21) reuse the test-only manifest or extract to a runtime-callable validator module?**
   - What we know: D-21 says behavior is locked; the planner decides extraction vs reuse.
   - **Recommendation: extract.** Create `Relyra.Security.XML.CorpusGate` as a runtime-callable module that loads the manifest via `Application.app_dir(:relyra, "priv/security_corpus.json")` (move the manifest from `test/fixtures/security/xml/manifest.json` to `priv/security_corpus.json`, keep the test-side reader pointing at the new path). Rationale: the test corpus is not appropriate to call from `lib/` (cross-domain dependency), and the runtime path needs a stable, versioned set of refusal triggers. The extraction is small (~40 LOC) and the test still uses the same manifest, so coverage is preserved.

4. **Should the auto-refresh wrapper be a separate `Relyra.Metadata.AutoRefresh` module or inlined into `Refresh.refresh/2`?**
   - What we know: D-05 says wrap, do not re-implement.
   - **Recommendation: separate module** (`lib/relyra/metadata/auto_refresh.ex`) called by `Scheduler.run_due/2`. Keeps `Refresh.refresh/2` (the manual path) untouched, makes the asymmetric strictness visible at the call boundary, and isolates the new D-15..D-21 checks in one file.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | `~> 1.19` (mix.exs declares; OTP 26+/27+/28 matrix) | — |
| Ecto / Ecto SQL / Postgrex | Schema migration, scheduler queries | ✓ (optional in mix.exs, expected by adopters) | `~> 3.13` | None — Phase 21 requires Ecto. Adopters without Ecto cannot use auto-refresh. |
| Oban | Optional Oban worker (D-02) | ✗ in Relyra mix.exs (deliberately not added — host's choice) | Recommend host pin: `~> 2.22` | Mix task (`mix relyra.refresh_due`), k8s `CronJob`, fly.io `[[machines.schedule]]` per D-06. |
| Postgres | Partial-index syntax (D-12) | ✓ assumed by ecto_sql / Phoenix conventions | 14+ (Oban 2.22 also requires 14+) | None — Phase 21 schema uses Postgres-specific partial-index syntax. MySQL/SQLite adopters cannot use the partial index optimization (full-table scan would still work but is not what we ship). |
| Phoenix LiveView | Admin LiveView extensions (D-29) | ✓ optional, already pinned `~> 1.1` | — | If LiveView is absent, the schema and scheduler still work; only the admin UI is unavailable (pre-existing pattern: `if Code.ensure_loaded?(Phoenix.LiveView) do`). |
| Req | Stricter Req profile (D-20) | ✓ optional, already pinned `~> 0.5` | — | Phase 21 inherits the same optional-Req posture as Phase 09; adopters without Req cannot use scheduled refresh. |

**Missing dependencies with no fallback:** Oban for hosts that *want* Oban Cron specifically. **Mitigation:** D-06's Mix-task / k8s / fly.io recipes cover non-Oban adopters.

**Missing dependencies with fallback:** All admin-LiveView-dependent surfaces fall back to "scheduler still works, no UI" cleanly (existing pattern).

---

## Validation Architecture

> Tests are the contract per `workflow.nyquist_validation`. Wave 0 lays infrastructure; later waves add their own test files alongside implementation.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in to Elixir 1.19); no additional dep needed |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/relyra/metadata/scheduler_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-08 | Operator can opt a connection in to scheduled refresh (default off; great error when fingerprints unset) | unit | `mix test test/relyra/ecto/metadata_source_test.exs --warnings-as-errors` | ❌ Wave 0 (extend existing) |
| CFG-08 | `Scheduler.run_due/2` selects only due rows via partial index | integration | `mix test test/relyra/metadata/scheduler_test.exs:due_query --warnings-as-errors` | ❌ Wave 1 |
| CFG-08 | Cadence resolver: preset → `next_refresh_at` with ±15% jitter and 1h hard floor | property | `mix test test/relyra/metadata/scheduler_property_test.exs --warnings-as-errors` | ❌ Wave 1 |
| CFG-08 | Failure classifier: every error code returns `transient?` + `counts_toward_suspend?` + `alert_immediately?` | unit (table-test) | `mix test test/relyra/metadata/failure_classifier_test.exs --warnings-as-errors` | ❌ Wave 1 |
| CFG-08 | Backoff schedule: monotonic 1h→6h→24h→24h with ±10% jitter | property | `mix test test/relyra/metadata/scheduler_property_test.exs:backoff --warnings-as-errors` | ❌ Wave 1 |
| CFG-08 | Drift detector: entityID change OR new signing-cert fingerprint → `:entity_id_drift` / `:new_signing_cert` | unit | `mix test test/relyra/metadata/drift_detector_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | Trust anchor: rejects unpinned, accepts pinned (single + multi-valued for rotation), rejects reuse-of-assertion-cert | unit + integration | `mix test test/relyra/metadata/trust_anchor_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | XMLDSig verify on root happens BEFORE Parser.parse-deeply (XXE-before-verify regression) | security | `mix test test/security/xml/auto_refresh_xxe_before_verify_test.exs --warnings-as-errors --only security_corpus` | ❌ Wave 2 |
| CFG-08 | Security-corpus gate refuses every existing fixture on the scheduled path | security | `mix test test/security/xml/auto_refresh_corpus_gate_test.exs --warnings-as-errors --only security_corpus` | ❌ Wave 2 |
| CFG-08 | Auto-suspend after 5 consecutive transient failures; `auto_suspended_until` and `:suspended` event fire | integration | `mix test test/relyra/metadata/auto_refresh_suspend_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | Half-open probe: success resets `consecutive_failure_count` to 0 + emits `:recovered` | integration | `mix test test/relyra/metadata/auto_refresh_recovery_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | Counter / state updates co-commit inside `record_attempt/3` (D-28 invariant) | integration | `mix test test/relyra/ecto/metadata_apply_test.exs:auto_refresh_health_state_in_transaction --warnings-as-errors` | ❌ Wave 2 (extend existing file) |
| CFG-08 | Telemetry: every state-transition event fires with correct metadata payload (`correlation_id`, `source_id`, `error_code`, `transient?`, `counts_toward_suspend?`) | unit | `mix test test/relyra/metadata/auto_refresh_telemetry_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | `:validity_warning` is at-most-once per `validUntil` window per source | integration | `mix test test/relyra/metadata/auto_refresh_validity_warning_test.exs --warnings-as-errors` | ❌ Wave 2 |
| CFG-08 | Optional-deps: `Relyra.Workers.MetadataRefresh` compiles with Oban absent; dispatches with Oban present | unit (split) | `mix compile --no-optional-deps --warnings-as-errors` (absent) + `mix test test/relyra/workers/metadata_refresh_test.exs --warnings-as-errors` (present) | ❌ Wave 3 |
| CFG-08 | LiveView: micro-badge renders for `:degraded`/`:suspended` health states | LiveView | `mix test test/relyra/live_admin/connections_live_auto_refresh_badge_test.exs --warnings-as-errors` | ❌ Wave 3 |
| CFG-08 | LiveView: "Resume now" writes audit row + clears `auto_suspended_until` + dispatches probe | LiveView | `mix test test/relyra/live_admin/connection_metadata_live_resume_test.exs --warnings-as-errors` | ❌ Wave 3 |

### Sampling Rate

- **Per task commit:** `mix test test/relyra/metadata/<changed_file>.exs --warnings-as-errors` (sub-second).
- **Per wave merge:** `mix test --warnings-as-errors` (full suite; serial migration bootstrap per the v0.2 retrospective lesson — DO NOT run parallel migration test suites; the audit identified this as a false-failure footgun).
- **Phase gate:** Full suite green + `mix compile --no-optional-deps --warnings-as-errors` green + new Postgres+Oban smoke lane green before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `priv/repo/migrations/YYYYMMDDHHMMSS_extend_relyra_metadata_sources_with_auto_refresh.exs` — schema extension
- [ ] `test/relyra/ecto/metadata_source_test.exs` — extend with auto_refresh_changeset coverage (covers CFG-08 opt-in)
- [ ] No new framework needed — ExUnit is already in the tree

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Operator-pinned trust anchors (D-17). Rejects TOFU. Rejects reuse-of-assertion-cert. |
| V3 Session Management | no | Phase 21 has no session-management surface; LiveView session is delegated to host per existing CFG-06 boundary. |
| V4 Access Control | yes | LiveView "Resume now" requires admin scope (existing `Relyra.LiveAdmin.Scope` + `on_mount` boundary; verified at `connections_live.ex:17`). |
| V5 Input Validation | yes | Stricter Req profile (D-20): 5MB cap, content-type allowlist, no redirects. Pre-parse DOCTYPE/ENTITY rejection before XMLDSig verify (D-16). |
| V6 Cryptography | yes | XMLDSig verification reused from `Relyra.Security.Signature.verify` — no hand-rolled crypto. SHA-256 fingerprint computation reused from `:crypto.hash/2`. |
| V7 Error Handling and Logging | yes | Typed `Relyra.Error{}` with redacted details. Log redaction reused from `Relyra.Log` (existing). |
| V8 Data Protection | yes | Audit redaction reused from `AuditWriter` (existing — handles PEM/key material redaction at lines 8-22 of `audit_writer.ex`). |
| V12 Files and Resources | partial | `legacy_unsigned_metadata_policy` is the only operator-overridable trust loosener; time-boxed + audited per D-19. |
| V14 Configuration | yes | `mix compile --no-optional-deps --warnings-as-errors` lane stays green (D-37 invariant verifies optional-deps gateway integrity). |

### Known Threat Patterns for Elixir/Phoenix SAML Metadata Refresh

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| TOFU MITM at first scheduled fetch | Tampering / Spoofing | Operator-pinned fingerprints (D-17); refuse to enable auto-refresh until at least one fingerprint is pinned. |
| Document-`KeyInfo` trust on metadata signature (ruby-saml CVE-2024-45409 family) | Spoofing | Reject document-provided KeyInfo; `Signature.verify/4` already rejects `key_info_trust == true` (verified at `lib/relyra/security/signature.ex:56-62`). |
| XXE-before-signature-verify (esaml 2026 NVD family) | Information Disclosure / Tampering | Pre-parse DOCTYPE/ENTITY rejection (extracted from `Parser.parse` lines 22-26 into a shared `pre_check/1`); XMLDSig verify happens BEFORE deep parse. |
| Signature wrapping / namespace confusion (xml-crypto 2025 family, PortSwigger Fragile Lock) | Tampering | Security-corpus regression-fixture gate on the scheduled path (D-21); same fixtures already shipped at `test/fixtures/security/xml/signature_wrapping/` and `test/fixtures/security/xml/parser_differential_and_c14n/`. |
| Silent assertion-cert rotation injection (authentik CVE-2026-25922 lesson) | Tampering | Drift detector auto-suspends on new signing cert; cert still stages as `:next` per Phase 10/12 D-08 (D-18 + D-32). |
| Metadata poisoning kill chain (Adan/Alvarez "Gaining AWS Persistence by Updating a SAML IdP") | Elevation of Privilege | Drift detector compares `entityID` and signing-cert fingerprint set against `last_known_metadata_signing_certs` (D-18); auto-suspend halts the unattended path until operator reviews. |
| HTTPS→HTTP downgrade via redirect | Tampering | Stricter Req profile: `redirect: false` (D-20). The URL field on `MetadataSource` already validates HTTPS at the changeset boundary (verified at `metadata_source.ex:50-60`). |
| Memory-exhaustion fetch (multi-GB metadata) | DoS | 5MB response cap (D-20); `max_response_size` Req option. |
| Slowloris-style fetch | DoS | 30s connect + 30s receive timeout (D-20). |
| Cron-string DDoS-the-IdP (`* * * * *`) | DoS (against IdP, not Relyra) | 4-preset enum + 1h hard floor (D-10/D-14). No cron strings accepted on the schema. |
| Operator-error: enable auto-refresh with no pinned fingerprint | Configuration | Changeset rejects with great-error message (mirroring `idp_initiated_not_allowed` pattern at `validation_pipeline.ex:127`). |
| "Resume now" race with concurrent scheduler tick | Tampering / Race | Audit row + state-clear + Oban job insert all in one transaction; Oban `unique:` constraint prevents double-execution. |

---

## Sources

### Primary (HIGH confidence)
- **Live source code (verified by direct reading):**
  - `lib/relyra/metadata/refresh.ex` — current refresh path (the wrap target).
  - `lib/relyra/metadata/parser.ex` — DOCTYPE/ENTITY pre-checks at lines 22-26.
  - `lib/relyra/metadata/import.ex` and `candidate.ex` — normalized internal candidate contract.
  - `lib/relyra/ecto/metadata_source.ex` — schema being extended.
  - `lib/relyra/ecto/metadata_apply.ex` — `apply_revision/4` and `record_attempt/3` (the D-28 single transaction).
  - `lib/relyra/ecto/audit_writer.ex` — single audit-writer seam with redaction logic at lines 8-22.
  - `lib/relyra/ecto/certificate_inventory.ex` — staged-cert lifecycle the auto-refresh path must respect.
  - `lib/relyra/ecto/connection_loader.ex` and `connection_snapshot.ex` — runtime hydration boundary (D-36).
  - `lib/relyra/security/signature.ex` — XMLDSig verify primitive (D-16 reuse target). Confirmed shape: `verify(parsed_doc, connection, cert_chain, opts)`. Already rejects document-`KeyInfo` (lines 56-62).
  - `lib/relyra/telemetry.ex` — telemetry catalog and `Telemetry.span/3` shape.
  - `lib/relyra/ecto/bulk_actions.ex` — Phase 20 sequential + correlation_id pattern (`Ecto.UUID.generate()` at line 16).
  - `lib/relyra/live_admin/connections_live.ex` — `selected_ids` MapSet pattern at line 32; admin scope check at line 17.
  - `lib/relyra/live_admin/connection_metadata_live.ex` — existing `start_async(:metadata_refresh, ...)` pattern at lines 80-114 (the "Resume now" template).
  - `lib/relyra/protocol/validation_pipeline.ex` — `idp_initiated_not_allowed` great-error pattern (mirror target for D-09).
  - `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` — single-column add migration template.
  - `priv/repo/migrations/20260505183000_harden_relyra_certificate_lifecycle_invariants.exs` — `lock_version` precedent (NOT applied to MetadataSource).
  - `mix.exs` — verified Oban is NOT yet a dep; Req/Ecto/LiveView optional posture confirmed.
  - `test/security/xml/corpus_security_test.exs` and `test/fixtures/security/xml/manifest.json` — security corpus shape (the D-21 gate input).
- **Context7 / live Oban documentation (verified 2026-05-06):**
  - Oban Unique Jobs guide — `unique: [period: :infinity, keys: [...], states: [...]]` semantics. `Oban.insert` returns `{:ok, %Oban.Job{conflict?: true}}` on dedup hit.
  - Oban Cron plugin guide — crontab list shape, `args:` injection, `meta: %{"cron" => true}` payload.
  - Oban Clustering & Peers guide — `Oban.Peers.Database` (production, no distributed Erlang required) vs `Oban.Peers.Global` (dev, requires distributed Erlang). Only the leader inserts cron jobs.
  - Oban worker `perform/1` return values — `:ok | {:ok, _} | {:error, _} | {:cancel, _} | {:snooze, _}`.
- **CONTEXT.md** — all decisions D-01 through D-39 explicitly enumerated.
- **PROJECT.md / STATE.md / RETROSPECTIVE.md / MILESTONE-ARC.md** — strict-defaults principle, single audit-writer seam, closure-phase pattern, "Operable from day one" pillar, v0.5 scope.

### Secondary (MEDIUM confidence — verified with multiple sources)
- **Hex.pm Oban package page** — current version 2.22.1, published 2026-04-30. Cross-referenced with hexdocs.pm/oban changelog.
- **Hex.pm Oban version requirements** — Elixir 1.15+, Erlang 24+, Postgres 14.0+, MySQL 8.4+, SQLite 3.37.0+. Verified via hexdocs.pm/oban README.
- **Ecto migration partial-index syntax** — `create index(..., where: "...")`. Verified at hexdocs.pm/ecto_sql/Ecto.Migration.html#index/3.
- **AWS Builder's Library — Timeouts, retries and backoff with jitter** — full-jitter and decorrelated-jitter formulas; Phase 21's ±10/±15% additive jitter is a simpler variant that suits the small fixed-tier schedule (1h/6h/24h) without the "previous sleep" feedback loop.
- **InCommon Federation Metadata Registration Practice Statement** — ≤1/hour refresh ceiling per relying party (the source of D-14's hard floor); InCommon docs corroborate "refresh every hour" as the optimal upper bound.

### Tertiary (LOW confidence — documented for completeness)
- Cross-language CVE references (ruby-saml CVE-2024-45409, esaml 2026 NVD, xml-crypto CVE-2025-29775, authentik CVE-2026-25922, "Gaining AWS Persistence by Updating a SAML IdP") — mentioned in CONTEXT.md as load-bearing for the security guardrails. Phase 21 inherits the lesson, not the implementation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Oban version verified against Hex.pm; Ecto/Req/LiveView versions verified against mix.exs; pattern shapes verified against live source files.
- Architecture: HIGH — every new component grounded in an existing seam (`Refresh.refresh/2`, `MetadataApply`, `Signature.verify`, `AuditWriter`, `BulkActions`).
- Pitfalls: HIGH — every pitfall traces to a documented decision (D-XX) and a specific code line.
- Discretion recommendations (Q1-Q4 in Open Questions): MEDIUM — these are the architecturally-bounded "could go either way" choices the recommendation-first DX preference asks me to pick on; the rationale for each is explicit and the planner can override with reason.

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (30 days; Oban is a stable lib, ecosystem moves slowly. Re-verify Oban version if planning slips past this date.)

---

## RESEARCH COMPLETE

**Phase 21 is a fan-out + scheduling-state shell over locked Phase 09/12 invariants — not a re-implementation.** The five load-bearing recommendations the planner needs:

1. **One scheduler module + one optional-deps gateway + one worker module + one wrapper module** is the entire new lib/ surface (`Relyra.Metadata.Scheduler`, `Relyra.OptionalDeps.Oban`, `Relyra.Workers.MetadataRefresh`, `Relyra.Metadata.AutoRefresh`). Plus pure helpers for failure classification, drift, trust anchor, backoff. No GenServer ticker, no parallel audit writer, no cron-string parser.
2. **D-28 is the single most important discipline:** every counter / state / `auto_suspended_until` mutation goes inside `MetadataApply.record_attempt/3`'s transaction. Phase 21 extends `record_attempt/3` and `apply_revision/4` to also write a `health_state_changeset` on `MetadataSource` in the same transaction — there is no second audit-writer seam.
3. **Oban `~> 2.22` is the only correct dependency for D-02/D-03;** `unique: [period: :infinity, keys: [:source_id]]` plus `Oban.Peers.Database` give multi-node dedup for free. The `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}` attribute keeps the `mix compile --no-optional-deps --warnings-as-errors` lane green.
4. **Recommendation on D-22 (trust-anchor pinning UX): both Mix task AND admin LiveView**, sharing one `auto_refresh_changeset/2` underneath, with the LiveView showing a giant risk panel (mirroring `risk_panel.ex` from v0.3) at the moment of pinning.
5. **Wave plan: schema migration first (Wave 0), pure-function helpers second (Wave 1), `Scheduler.run_due/2` + Oban gateway + worker third (Wave 2), LiveView extensions fourth (Wave 3), documentation recipes + CI Oban smoke lane fifth (Wave 4).** This sequence keeps each wave independently testable and lets the audit-writer-seam invariant (D-28) get verified before LiveView touches the surface.

Sources:
- [Hex.pm — Oban package](https://hex.pm/packages/oban)
- [HexDocs — Oban worker semantics](https://hexdocs.pm/oban/Oban.Worker.html)
- [HexDocs — Oban (version requirements)](https://hexdocs.pm/oban/Oban.html)
- [HexDocs — Ecto.Migration partial indexes](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#create/2)
- [AWS Builder's Library — Timeouts, retries and backoff with jitter](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/)
- [AWS Architecture Blog — Exponential Backoff and Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [InCommon — Metadata](https://incommon.org/federation/metadata)
- [InCommon — Metadata Registration Practice Statement](https://incommon.org/federation/mrps/)
- [Internet2 Wiki — InCommon Metadata Consumption Best Practice](https://spaces.at.internet2.edu/display/federation/consume-metadata-best-practice)
- [Erlang Ecosystem Foundation CNA — esaml XXE CVE-2026-28809](https://cna.erlef.org/cves/CVE-2026-28809.html)
