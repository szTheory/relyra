# Phase 21: Scheduled metadata refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 21-scheduled-metadata-refresh
**Areas discussed:** Scheduling mechanism, Per-connection opt-in + cadence, Security guardrail (stricter than manual), Failure handling & alert surface

---

## Pre-discussion gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Scheduling mechanism | How does the periodic tick fire? Optional Oban worker via OptionalDeps gateway, built-in GenServer ticker, or pure BYO? | ✓ |
| Per-connection opt-in + cadence | Where does auto_refresh live; preset enum vs cron vs interval seconds; jitter; default cadence? | ✓ |
| Security guardrail (stricter than manual) | Require signed metadata for scheduled apply; trust anchor model; entityID/cert drift detection; pinning of metadata-signing fingerprints? | ✓ |
| Failure handling & alert surface | Telemetry shape; auto-suspend after N failures; admin LiveView surface; reference handler? | ✓ |

**User's choice:** All four areas.
**Notes:** User then directed: "u decide... auto.. for each of these... research using subagents, what is pros/cons/tradeoffs of each... idiomatic for elixir/plug/ecto/phoenix... lessons learned from other libs/apps in same space even from other languages/frameworks... think deeply one-shot a perfect set of recommendations so i dont have to think... all recommendations are coherent/cohensive with each other... shift this preference left within GSD as well if possible... except for VERY impactful ones that i might actually care about." Saved as a project-level feedback memory (recommendation-first DX preference).

---

## Area 1 — Scheduling mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Pure `run_due/2` + Oban worker behind OptionalDeps gateway | Canonical entry point for any host scheduler; Oban worker for one-line install on Oban hosts; doc recipes for k8s/fly.io/cron | ✓ |
| Built-in supervised GenServer ticker as default + Oban gateway opt-in | Lowest-friction default but multi-node race + auto-starting background work in a *library* violates principle of least surprise | |
| Pure BYO — `run_due/2` only, no built-in worker | Smallest surface but DNA prompt §5 explicitly names Oban; "BYO scheduler" docs are exactly the docs nobody reads → silent staleness | |

**Decision (auto):** Option 1.
**Why:** Honors locked engineering DNA gateway pattern. Preserves OSS portability (no Postgres-only / no Oban-only adopters bricked). Multi-node safety free via `Oban.Peers.Database` + unique-job dedup. Matches what Shibboleth's `MetadataResolver` family and SimpleSAMLphp's `metarefresh` actually do in production. Default = scheduler dormant until host invokes — Spring Security SAML's `Timer` and early Shibboleth daemon races are exactly the silent-bypass class we'd own if we shipped a built-in ticker.
**Cross-language sources weighted:** Oban docs, Shibboleth `FileBackedHTTPMetadataProvider`, Spring Security SAML issue #9134, SimpleSAMLphp metarefresh, eduGAIN technical metadata, passport-saml.

---

## Area 2 — Per-connection opt-in + cadence

| Sub-decision | Options considered | Chosen | Why |
|---|---|---|---|
| A. Toggle location | On `Connection` / on `MetadataSource` / new sibling embed | **MetadataSource** | The thing being polled is the source URL; `unique_constraint(:connection_record_id)` already enforces 1:1 |
| B. Cadence shape | Free-form interval seconds / cron string / preset enum / hybrid preset+escape-hatch | **Preset enum** `[:hourly, :every_6h, :daily, :weekly]` | No cron-string DDoS footgun, no unit-confusion footgun, calm/operator-first brand voice |
| C. Default cadence | hourly / every_6h / daily / weekly | **`:daily`** | Well under InCommon ≤1/hour ceiling; matches the few-times-a-year cadence at which enterprise SAML metadata actually changes |
| D. Per-source override | yes / no / preset+free-form hybrid | **yes — across the 4 presets only** | Each row chooses one preset; no global default; no precedence rules |
| E. Jitter | none / ±10% / ±15% / ±25% | **±15% persisted** | Conventional cron-style jitter band middle; persisted so it doesn't re-roll on restart |
| F. State storage | compute on the fly / store `next_refresh_at` | **store `next_refresh_at`** | Persisted jitter; partial index for single-scan "due now" query |
| G. Auto-suspend after failures | yes — `auto_suspended_until` | **yes** | Soft backoff (Area 4 owns thresholds); preserves operator's `auto_refresh_enabled` intent |

**Decision (auto):** Schema additions to `MetadataSource` per CONTEXT.md D-08 to D-13; cadence resolution per D-14.
**Cross-language sources weighted:** Shibboleth `FileBackedHTTPMetadataProvider`, InCommon Metadata Registration Practice Statement, Microsoft Entra federation metadata docs, Oban Cron, Quantum, AWS Builder's Library jitter guidance.

---

## Area 3 — Security guardrail (stricter than manual)

| Sub-decision | Options considered | Chosen | Why |
|---|---|---|---|
| S1. Signed metadata required for scheduled apply? | scheduled-only / always / configurable | **configurable per-source, default ON for scheduled, OFF for manual** | Asymmetric strictness matches asymmetric assumption (operator-in-loop vs unattended); manual import backward-compat preserved |
| S2. Trust anchor for metadata signature? | operator-pinned fingerprints / TOFU / reuse-assertion-cert / federation aggregator | **operator-pinned SHA-256 fingerprints** | TOFU institutionalizes one-shot MITM at enable-time; reuse-assertion-cert violates SAML role separation; aggregator out of scope |
| S3. EntityID / cert drift detection | none / entityID-only / entityID + new cert | **entityID + new signing-cert fingerprint, auto-suspend with typed reason** | EntityID change is the canonical metadata-replacement attack signature; net-new certs are how attackers persist; staging continues but next fetch pauses |
| S4. Default posture | feature opt-out / opt-in per connection | **opt-in per connection (already locked); signed-by-default with `legacy_unsigned_metadata_policy` escape hatch** | Strict-defaults principle; mirrors `legacy_algorithm_policy` shape |
| S5. Network safety profile | reuse manual / stricter for scheduled | **stricter for scheduled** (30s timeouts, no redirects, 5MB cap, content-type check, fixed UA) | Defense-in-depth; cheap to implement; closes SSRF / resource-exhaustion class |
| S6. CVE corpus on staged metadata | none / corpus gate pre-apply | **corpus gate as post-parse, pre-apply gate** | Honors brand promise: every security fix becomes a permanent regression fixture, including unattended path |

**Decision (auto):** CONTEXT.md D-15 to D-22.
**Cross-language sources weighted:** ruby-saml CVE-2024-45409, esaml 2026 NVD XXE-before-verify, xml-crypto CVE-2025-29775, PortSwigger "Fragile Lock" research, authentik CVE-2026-25922, Adan/Alvarez "Gaining AWS Persistence by Updating a SAML IdP", Shibboleth `SignatureValidationFilter`, OASIS SAML V2.0 Metadata Interoperability Profile, InCommon Metadata Signing Certificate guidance.

---

## Area 4 — Failure handling & alert surface

| Sub-decision | Options considered | Chosen | Why |
|---|---|---|---|
| F1. Telemetry topology | flag-on-existing-event / new namespace / new namespace + state events | **new `:auto_refresh` namespace + `:degraded`/`:suspended`/`:recovered` state events** | Distinct namespace = host attaches "page me" handler only to unattended channel; existing manual-refresh listeners untouched |
| F2. Health state on source | denormalize / compute / hybrid | **hybrid: denormalize on `MetadataSource`, history in `MetadataRevision`** | O(1) reads in scheduler tick + LiveView; authoritative history queryable; updates inside existing `record_attempt/3` transaction |
| F3. Auto-suspend policy | hard stop / soft backoff / no auto-suspend | **soft backoff: 5 consecutive transient failures → 1h → 6h → 24h cap, ±10% jitter, half-open probe** | Preserves operator intent; AWS-canonical circuit-breaker shape; auto-recovers without operator toil |
| F4. Admin UI surface | inline badges / separate dashboard / both | **inline badges + per-connection health card; no separate dashboard in v0.5** | Matches v0.3 LiveView "context where you need it" pattern; avoids admin-of-admin |
| F5. Alert deliverable to host | telemetry events only / telemetry + reference handler / vendor-specific shipped handlers | **telemetry events as contract + optional `LogAlerts` reference handler in docs** | Library cannot page; telemetry-as-API is Elixir norm; reference handler removes "what now?" friction without vendor coupling |
| F6. Transient vs persistent classification | uniform / matrix-based | **per-error-code `transient?` + `counts_toward_suspend?` matrix** | Suspending on signature failure hides likely attack; suspending on transient noise reduces ops noise; two orthogonal axes |
| F7. Failure muting | ship in v0.5 / defer | **defer to v0.6+** | Auto-suspend covers dominant noise case; suspicious-class muting belongs in host's paging system |

**Decision (auto):** CONTEXT.md D-23 to D-31, plus the schema additions in the consolidated migration table.
**Cross-language sources weighted:** Oban `Telemetry` + circuit-trip events, Shibboleth `FileBackedHTTPMetadataProvider` `MaxBackoff`, Spring Security `MetadataManager`, Healthchecks.io documentation, AWS Builder's Library backoff-with-jitter, Polly circuit-breaker resilience strategy, Phoenix LiveDashboard telemetry conventions.

---

## Single user-facing escalation in this discussion

**Question asked:** "Cadence semantics: should v0.5 honor the IdP's published cacheDuration/validUntil, or treat the operator's preset as authoritative?" — three options (config-authoritative / validUntil-aware / hybrid).

**User response:** Rejected the question. Restated: "u decide... auto..." with a strong signal that even items the research agents flagged as "open questions worth user input" should be decided autonomously unless they hit a security-contract / public-surface / PROJECT.md-contradiction bar.

**Decision (auto, post-rejection):** Hybrid — operator preset authoritative, 1-hour InCommon hard floor, warn-only `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]` event when current metadata's `validUntil` is sooner than `2 × refresh_interval`. Captured as D-14.

**Memory updated:** `feedback_recommendation_first.md` tightened to: do NOT escalate architecturally-bounded "could go either way" choices — only escalate (a) security-contract changes, (b) public-capability adds/removes, (c) Key-Decision contradictions, (d) explicit prior in-session ask.

---

## Claude's Discretion

Captured under CONTEXT.md `<decisions>` "Claude's Discretion" subsection. Summary:

- Exact module names / file layout for scheduler, OptionalDeps gateway, worker.
- Exact column names / Ecto types for the schema additions (semantics locked, names flexible).
- Exact failure-classification flag mechanism (per-error-code metadata vs separate table vs at-emit-time inference).
- Exact admin-LiveView visual treatment (color, badge shape, copy).
- Exact migration ordering, default backfill, lock_version handling.
- Exact `Req` configuration plumbing for the stricter scheduled-path profile.
- Exact admin-LiveView fingerprint-pinning UX (Mix task vs admin-only vs both).
- Whether security-corpus gate reuses test corpus directly or extracts a runtime validator module.

---

## Deferred Ideas

Captured under CONTEXT.md `<deferred>`. Summary:
- Diff-preview UX for incoming metadata revisions (Phase 09 D-05 carryover; v0.6+).
- Federation aggregator support / MDQ resolver (`kind: :mdq` source type; v0.6+).
- Vendor-specific paging integrations (Slack/PagerDuty/Sentry handlers).
- `validUntil`-aware automatic cadence shifts (warn-only in v0.5; revisit v0.6+).
- Failure muting (defer to v0.6+ if adopter demand emerges).
- Top-level cross-tenant auto-refresh health dashboard (defer; v0.6+).
- TOFU mode as explicit opt-in trust-anchor policy (rejected for v0.5; schema doesn't preclude later).
- `mix relyra.metadata.pin` Mix task as the recommended fingerprint-pinning ceremony (decision deferred to plan-phase).
