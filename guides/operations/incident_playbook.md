# Incident Response Playbook

This guide is the operator-facing reference for responding to SAML incidents
when a Relyra deployment is live. Every login resolves to a verified trust
path or a typed rejection; this playbook is what to do when the rejection
recurs, when a metadata refresh suspends, when a signing cert rotates, or
when a replay storm hits the ACS endpoint. Relyra owns the typed-rejection
contract and the six evidence surfaces (telemetry, audit ledger, LiveView
admin, Mix tasks, login trace, troubleshooting decoder); the host owns the operational
response. The reference table below is the centerpiece — every scenario
runbook in this guide points back into it rather than restating where the
evidence lives.

## Relyra owns / Host owns

## Relyra owns

- Emitting structured `[:relyra, :saml, ...]` telemetry events at every stage
  of the trust pipeline (`lib/relyra/telemetry.ex`).
- Writing append-only audit rows to the `relyra_audit_events` table for every
  trust-state mutation: connection, metadata, certificate, and mapping.
- Publishing the `/relyra/admin` LiveView routes for connection / metadata /
  certificate / mapping inspection and mutation.
- Shipping the 8 `mix relyra.*` operator hand-tools.
- Documenting the canonical `Relyra.Error` atom taxonomy in
  [`../troubleshooting.md`](../troubleshooting.md).

## Host owns

- Telemetry storage and alerting (Relyra emits; the host's observability stack
  retains, indexes, and pages on-call).
- Audit-row access control and retention (the host's policy decides who reads
  `relyra_audit_events` and for how long).
- Authentication and authorization for the `/relyra/admin` LiveView surface
  (Relyra exposes the routes; the host's pipeline gates them).
- Scheduling Mix-task invocation — for example, a cron entry that runs
  `mix relyra.refresh_due` on a cadence appropriate to the deployment.
- The human operator playbook. This guide is a starting point; institutional
  procedures (paging, escalation, communication) wrap it.

## Evidence surfaces

When an incident hits, walk this table top to bottom. Each row names the
exact code anchor — Relyra's strict-defaults posture means the operator
should never need to grep the source to find the right evidence.

| Surface | What it tells you | Exact code anchor |
| --- | --- | --- |
| Telemetry events | Structured `:start` / `:stop` / `:exception` spans for every trust-pipeline stage, plus auto-refresh state-transition events and certificate-expiry warnings | `lib/relyra/telemetry.ex` |
| Audit ledger | Append-only `relyra_audit_events` rows recording every trust-state mutation (connection / metadata / certificate / mapping) | `lib/relyra/ecto/audit_event.ex` |
| LiveView admin routes | Operator UI for connection, metadata, certificate, and mapping inspection and mutation | `lib/relyra/live_admin/router.ex` |
| Mix tasks | 8 operator hand-tools for drift checks, diagnostic bundles, login-trace inspection, scaffolding, metadata pinning, scheduled refresh, and security-review evidence | `lib/mix/tasks/relyra.*.ex` |
| Troubleshooting decoder | Per-atom decoder with the four-field micro-block (Means / Likely root cause / Operator action / Source) for every `Relyra.Error` atom | [`../troubleshooting.md`](../troubleshooting.md) |
| Login trace | Per-login-attempt step timeline (`response.decode` → `response.validate` → `signature.verify` → `replay.check` → `user.map` → `session.establish`) with `:error_code` on failed stages; browser UI or headless CLI | `lib/relyra/live_admin/connection_trace_live.ex`, `lib/mix/tasks/relyra.trace.ex`, `lib/relyra/live_admin/query.ex` |

### Login trace vs audit ledger

Login traces persist as `domain: :login` rows in `relyra_audit_events` — they
record per-attempt pipeline steps, not trust-state mutations. Trust mutations
use the audit vocabulary in the table above (`:connection`, `:metadata`,
`:certificate`, `:mapping`). Replays do not mutate trust state and write no
audit row; replay outcomes appear in login trace and telemetry only.

### Telemetry event catalog

Cite these event names verbatim when attaching `:telemetry.attach/4`
handlers. Each span event below is a `:start` / `:stop` / `:exception`
triplet — the `:stop` event carries `duration_ms` and an `:outcome` /
`:error_code` pair when the stage failed.

Span events:

- `[:relyra, :saml, :login]`
- `[:relyra, :saml, :authn_request]`
- `[:relyra, :saml, :response, :decode]`
- `[:relyra, :saml, :response, :validate]`
- `[:relyra, :saml, :signature, :verify]`
- `[:relyra, :saml, :replay, :check]`
- `[:relyra, :saml, :user, :map]`
- `[:relyra, :saml, :session, :establish]`
- `[:relyra, :saml, :metadata, :refresh]`
- `[:relyra, :saml, :metadata, :import]`
- `[:relyra, :saml, :metadata, :auto_refresh]`

Auto-refresh state-transition events (one-shot, not span-bracketed):

- `[:relyra, :saml, :metadata, :auto_refresh, :degraded]`
- `[:relyra, :saml, :metadata, :auto_refresh, :suspended]`
- `[:relyra, :saml, :metadata, :auto_refresh, :recovered]`
- `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]`
- `[:relyra, :saml, :metadata, :auto_refresh, :skipped]`

Certificate expiry warning event (one-shot):

- `[:relyra, :saml, :certificate, :expiring]`

### Audit vocabulary

Filter `relyra_audit_events` by these atom literals — they are the exact
values stored in the `:domain` and `:action` columns
(`lib/relyra/ecto/audit_event.ex:13-26`).

```
@domain_values = [:connection, :metadata, :certificate, :mapping]
@action_values = [:created, :updated, :enabled, :disabled, :applied,
                  :refreshed, :staged, :activated, :retired, :replaced,
                  :deleted]
```

Trust mutations co-commit an audit row inside the same Ecto transaction —
if a connection edit or a metadata apply succeeded, the row is present.
Replays do not mutate trust state and therefore write no audit row; see
Scenario 3 below.

### LiveView admin routes

The route parameter is `:connection_id` everywhere a connection is
referenced — match against this exact name in your host's authorization
plug. The path prefix `/relyra/admin` is configurable when you mount the
routes, but the suffix shapes are fixed.

| Path | Module / action |
| --- | --- |
| `/relyra/admin/` | `Relyra.LiveAdmin.ConnectionsLive` `:index` |
| `/relyra/admin/connections/new` | `Relyra.LiveAdmin.ConnectionsLive` `:new` |
| `/relyra/admin/connections/:connection_id` | `Relyra.LiveAdmin.ConnectionsLive` `:show` |
| `/relyra/admin/connections/:connection_id/edit` | `Relyra.LiveAdmin.ConnectionsLive` `:edit` |
| `/relyra/admin/connections/:connection_id/metadata` | `Relyra.LiveAdmin.ConnectionMetadataLive` `:metadata` |
| `/relyra/admin/diagnostic/bundle` | `Relyra.Phoenix.Controllers.DiagnosticController` `:download` |

### Mix tasks

These are the 7 Relyra operator hand-tools. `hex.audit` is a third-party
Hex task and is NOT a Relyra hand-tool — do not include it in operator
runbooks alongside these.

| Task | Purpose |
| --- | --- |
| `mix relyra.batteries_included` | Generate or drift-check BATTERIES_INCLUDED.md. |
| `mix relyra.conformance` | Generate or drift-check CONFORMANCE.md. |
| `mix relyra.diagnostic` | Generate a Relyra diagnostic bundle. |
| `mix relyra.install` | Scaffold the minimal Relyra integration surface. |
| `mix relyra.metadata.pin` | Pin a SHA-256 metadata trust fingerprint on a connection. |
| `mix relyra.refresh_due` | Refresh any metadata sources whose schedule is due. |
| `mix relyra.security_review` | Generate or drift-check SECURITY_REVIEW_EVIDENCE.md. |

## Scenario 1: Certificate expiry imminent

Symptom: no `Relyra.Error` atom — Relyra warns proactively before any
signature failure occurs. The first signal is telemetry, not a rejection.

1. Triage — the `[:relyra, :saml, :certificate, :expiring]` event (see the
   telemetry catalog in the surface table) fires with `:days_until_expiry`
   and `:fingerprint_sha256` measurements. Confirm the `:connection_id`
   identifies the connection at risk. If your observability stack pages on
   this event, this is the moment to acknowledge.
2. Diagnose — open `/relyra/admin/connections/:connection_id` and review
   the certificate inventory section for the affected connection. Query
   the audit ledger for `domain = :certificate` rows with `action` in
   `[:staged, :activated]` to see prior rollover history on this
   connection. If you need a redacted snapshot to share with the IdP
   vendor, run `mix relyra.diagnostic`.
3. Recover — stage the new IdP signing certificate via the admin UI
   (audit row `domain = :certificate`, `action = :staged` will record the
   stage). When the IdP cuts over, activate the staged certificate
   (`action = :activated`) and retire the old one (`action = :retired`).
   If the IdP publishes the new cert via metadata, run
   `mix relyra.refresh_due` first to pick it up.

## Scenario 2: Metadata drift after IdP change

Symptom: [`:metadata_drift_requires_review`](../troubleshooting.md#metadata_drift_requires_review)
returns from metadata-apply attempts; auto-refresh telemetry may have
transitioned the source to `:degraded` or `:suspended`.

1. Triage — check the auto-refresh state-transition events from the
   telemetry catalog: `[:relyra, :saml, :metadata, :auto_refresh, :degraded]`
   or `:suspended` indicate the auto-refresh worker has flagged the
   source. The audit ledger will show `domain = :metadata` rows with
   `action = :applied` carrying a drift flag.
2. Diagnose — open `/relyra/admin/connections/:connection_id/metadata`
   for a side-by-side of the staged-vs-current trust state. Query the
   audit ledger for `domain = :metadata` rows with `action` in
   `[:applied, :refreshed]` over the last 24 hours to see what the
   auto-refresh worker has been doing on this source. Cross-reference
   the atom decoder at
   [`../troubleshooting.md#metadata_drift_requires_review`](../troubleshooting.md#metadata_drift_requires_review).
3. Recover — if the drift is legitimate (the IdP rotated its signing
   cert or moved its SSO endpoint), run `mix relyra.refresh_due` to
   force the worker to retry, then approve the drift via the admin UI
   (audit row `domain = :metadata`, `action = :applied` will record the
   approval). If the deployment requires byte-exact metadata identity,
   run `mix relyra.metadata.pin` with the new SHA-256 fingerprint to
   harden the connection against future drift.

## Scenario 3: Replay storm

Symptom: [`:replayed_assertion`](../troubleshooting.md#replayed_assertion)
in logs, repeating across many login attempts in a short window.

1. Triage — the `[:relyra, :saml, :replay, :check]` telemetry event
   (see the catalog) fires with repeated `:stop` events whose
   `:outcome` is `:error` and whose `:error_code` is
   `:replayed_assertion`. **Replays do not mutate trust state, so no
   audit row is written** — `lib/relyra/replay_store/ecto.ex` and
   `lib/relyra/replay_store/ets.ex` contain zero `AuditWriter.append_event`
   calls. Operators rely on `[:relyra, :saml, :replay, :check]`
   telemetry alone for replay-storm detection; the audit ledger will
   not corroborate.
2. Diagnose — there is no admin LiveView surface for replay activity
   in v1.4. Volume, source-IP analysis, and per-connection grouping
   must come from your host application's log infrastructure (the
   telemetry handler that writes structured replay events into your
   logging stack). Use `:connection_id` in the telemetry metadata to
   localize the storm to a single connection if possible.
3. Recover — apply host-app-level rate limiting on the ACS endpoint;
   replays are protocol-correct messages that the SAML library cannot
   refuse to receive (only refuse to accept). If the storm correlates
   with a single connection, disable that connection via
   `/relyra/admin/connections/:connection_id/edit` while you
   investigate (audit row `domain = :connection`, `action = :disabled`
   will record the disable). Re-enable
   (`domain = :connection`, `action = :enabled`) when the source is
   confirmed legitimate or rate-limited.

## Scenario 4: Signature regression after IdP key rotation

Symptom: [`:digest_mismatch`](../troubleshooting.md#digest_mismatch),
[`:invalid_signature`](../troubleshooting.md#invalid_signature), or
[`:trust_anchor_mismatch`](../troubleshooting.md#trust_anchor_mismatch)
returning from every login attempt for a specific connection.

1. Triage — the `[:relyra, :saml, :signature, :verify]` telemetry event
   (see the catalog) fires `:stop` with `:outcome` `:error` and the
   exact atom in `:error_code`. Group by `:connection_id` to confirm
   the regression is isolated to one connection — a fleet-wide signature
   failure indicates an algorithm-policy change, not a key rotation.
2. Diagnose — open `/relyra/admin/connections/:connection_id` and
   review the signing certificate inventory; the IdP may have rotated
   to a key Relyra does not yet trust. Run `mix relyra.diagnostic` to
   bundle the connection state plus a redacted copy of the failing
   response payload for the IdP vendor's support team. Cross-reference
   the atom decoder at
   [`../troubleshooting.md#digest_mismatch`](../troubleshooting.md#digest_mismatch)
   and
   [`../troubleshooting.md#trust_anchor_mismatch`](../troubleshooting.md#trust_anchor_mismatch)
   for the exact distinction between the three failure modes.
3. Recover — stage the new IdP signing certificate via the admin UI
   cert inventory (audit row `domain = :certificate`,
   `action = :staged`); confirm the next login succeeds against the
   staged cert; activate it (`action = :activated`) and retire the old
   one (`action = :retired`). The signing source is configured IdP
   certs only — Relyra will never trust a document `KeyInfo` no matter
   how convenient it would be at this moment.

## Scenario 5: ACS misconfiguration at provisioning

Symptom: [`:destination_mismatch`](../troubleshooting.md#destination_mismatch),
[`:recipient_mismatch`](../troubleshooting.md#recipient_mismatch), or
[`:in_response_to_mismatch`](../troubleshooting.md#in_response_to_mismatch)
on every login for a new or freshly reconfigured connection.

1. Triage — the `[:relyra, :saml, :response, :validate]` telemetry event
   (see the catalog) fires `:stop` with `:outcome` `:error` and the atom
   in `:error_code`. The atom names exactly which field mismatched —
   `:destination_mismatch` is the `Destination` attribute on the
   response, `:recipient_mismatch` is the `SubjectConfirmationData
   Recipient`, and `:in_response_to_mismatch` is the response's
   `InResponseTo` attribute against the request store.
2. Diagnose — open `/relyra/admin/connections/:connection_id/edit` and
   verify `acs_url`, `sp_entity_id`, `idp_entity_id`, and `idp_sso_url`
   match what the IdP's published metadata advertises. The IdP-side
   error message will reveal the mismatched value. Cross-reference
   [`../troubleshooting.md#destination_mismatch`](../troubleshooting.md#destination_mismatch)
   for the exact field semantics.
3. Recover — update the affected connection field via the admin UI; the
   audit row `domain = :connection`, `action = :updated` records the
   change. If your deployment uses metadata-driven configuration, fix
   the canonical value at the source (your metadata generator or IdP
   admin console) and run `mix relyra.refresh_due` to pick it up.

## Scenario 6: Attribute mapping breakage

Symptom: [`:invalid_audience`](../troubleshooting.md#invalid_audience)
or mapping-stage errors surfacing at the host-app boundary (the user
mapper rejects the principal, or the host session adapter rejects the
attribute set).

1. Triage — the `[:relyra, :saml, :user, :map]` telemetry event (see
   the catalog) fires `:stop` with `:outcome` `:error`. Query the
   audit ledger for `domain = :mapping` rows with `action` in
   `[:created, :updated]` to see recent mapping changes on the
   connection — a recent mapping edit is the most common cause.
2. Diagnose — open `/relyra/admin/connections/:connection_id` and
   review the mapping section plus the audit timeline. Cross-reference
   [`../troubleshooting.md#invalid_audience`](../troubleshooting.md#invalid_audience)
   for the audience-mismatch case. If the issue is in the host's
   `UserMapper` callback rather than in the connection's mapping
   configuration, the fix is in host application code — see
   [`../identity_mapping_and_provisioning.md`](../identity_mapping_and_provisioning.md)
   for the UserMapper contract.
3. Recover — update the mapping via the admin UI (audit row
   `domain = :mapping`, `action = :updated`); confirm the next login
   for a representative user succeeds. If the host application owns
   the failing logic in its `UserMapper`, ship the fix there and
   redeploy — Relyra emits the attribute set unchanged, so it never
   needs a library change for mapping-policy edits.

## When in doubt

Every login resolves to a verified trust path or a typed rejection — and
when in doubt, the diagnostic bundle is the trace. Run
`mix relyra.diagnostic` to capture a redacted, attributable snapshot of
the connection state, recent audit rows, and the failing response
payload. Route the bundle to your IdP support contact when the symptom is
a signing-cert regression, to your security review queue when an active
attack is suspected, or attach it to a Relyra issue when you suspect a
library bug. The bundle is designed to be safe to share — Phase 23's
redactor strips secret material before the archive is written.
