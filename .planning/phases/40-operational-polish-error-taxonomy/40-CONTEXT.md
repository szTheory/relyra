# Phase 40: Operational Polish & Error Taxonomy - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish two operator-grade documentation surfaces and one drift-check test that close
out v1.4's operational story:

1. `guides/troubleshooting.md` — SAML Error Atom Decoder covering every `:atom`
   `Relyra.Error` emits, grouped by trust-pipeline domain.
2. `guides/operations/incident_playbook.md` — end-to-end response narrative that
   stitches Relyra telemetry, the audit ledger, the LiveView admin UI, and Mix
   tasks into a single coherent operator playbook.
3. `test/docs/troubleshooting_drift_test.exs` — automated drift-check that fails CI
   whenever an `Error.new(:atom, ...)` or `%Relyra.Error{type: :atom}` site exists
   without a matching `### :atom` entry in the troubleshooting guide (and vice
   versa).

**Requirements:** DOCS-05 (incident playbook), DOCS-06 (troubleshooting + drift-check).

**In scope:** Two new markdown guides under `guides/`, one new test module under
`test/docs/`, `mix.exs` `extras:` registration, `ci.docs` alias wiring.

**Not in scope:** No new telemetry events, no new audit-event domains/actions, no
changes to `Relyra.Error` shape, no changes to error atoms emitted by the
validation pipeline, no new Mix tasks, no LiveView admin changes. Phase 40 is
documentation + a single test; the underlying runtime is frozen.
</domain>

<decisions>
## Implementation Decisions

### Troubleshooting decoder (DOCS-06)
- **D-01:** Publish at `guides/troubleshooting.md` (root, not under `guides/operations/`)
  — matches REQUIREMENTS.md DOCS-06 verbatim.
- **D-02:** Structure as **8 domain-grouped sections** mirroring Relyra's trust-pipeline
  seam taxonomy: XML Hardening · Signature & Crypto · Replay & Request Intent ·
  Metadata Lifecycle · Network / Fetch · Binding & Protocol Shape · Configuration &
  Adapter Wiring · Session & Logout. Domain grouping (not flat alphabetical) preserves
  the trust-boundary mental model — `:doctype_forbidden` (pre-parse) reads next to its
  pre-parse siblings, not next to `:digest_mismatch` (post-parse crypto).
- **D-03:** Every documented atom uses an H3 heading of the exact form
  `### :atom_name` so the drift-check regex `~r/^### :([a-z_][a-z0-9_]*)\b/m` parses
  deterministically. No emoji, no decoration, no trailing punctuation in the heading.
- **D-04:** Each entry is a four-field micro-block:
  - **Means:** plain-English description of what condition this atom signals.
  - **Likely root cause:** the one or two most common originating misconfigurations.
  - **Operator action:** the next concrete step (which admin view, which Mix task,
    which connection field to check).
  - **Source:** canonical file path that emits this atom — e.g.
    `lib/relyra/protocol/validation_pipeline.ex`.
- **D-05:** Canonical atom set is ~60 entries (verified via codebase analysis), not 37.
  Multi-line `Error.new(\n :atom, ...)` constructors and `%Relyra.Error{type: :atom}`
  struct literals raise the real count well above the single-line grep estimate. The
  drift-check test (D-08..D-11) is the source of truth; the planner must run it once
  during planning to lock the actual count before splitting work.

### Drift-check test (DOCS-06)
- **D-06:** New test module at `test/docs/troubleshooting_drift_test.exs` (create
  the `test/docs/` directory). One module, one test case.
- **D-07:** No `@known_types` module attribute on `Relyra.Error` — adding one would
  create a second source of truth that itself drifts. The codebase remains the single
  source of truth; the test scans it directly.
- **D-08:** Atom enumeration uses **three regex patterns** applied to every `.ex` file
  under `lib/`:
  1. `~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/` — single-line constructor form.
  2. `~r/Error\.new\(\s*\n\s*:([a-z_][a-z0-9_]*)/` — multi-line constructor form
     (heavily used in `lib/relyra/protocol/validation_pipeline.ex` and
     `lib/relyra/metadata/auto_refresh.ex`).
  3. `~r/%Relyra\.Error\{type:\s*:([a-z_][a-z0-9_]*)/` — struct-literal form, used
     in `lib/relyra/security/xml/c14n.ex`, `lib/relyra/security/xml/corpus_gate.ex`,
     `lib/relyra/metadata/trust_anchor.ex`, and `lib/relyra/live_admin/connections_live.ex`
     (4 atoms a constructor-only scan would silently skip).
  Final canonical set = union of all three.
- **D-09:** Doc enumeration: `~r/^### :([a-z_][a-z0-9_]*)\b/m` applied to
  `File.read!("guides/troubleshooting.md")`. Anchoring on `^### :` (H3, leading colon)
  prevents false matches against incidental atom mentions inside body prose.
- **D-10:** Test assertion is bidirectional:
  - `code_atoms -- doc_atoms == []` — fails with: *"Missing doc entry for: `:foo` —
    add `### :foo` section to guides/troubleshooting.md (source: lib/path/file.ex)"*.
  - `doc_atoms -- code_atoms == []` — fails with: *"Stale doc entry for: `:bar` —
    atom no longer emitted by Relyra; remove from troubleshooting.md or re-introduce
    in lib/"*.
  Failure-message vocabulary mirrors `test/security/ci_gate_integrity_test.exs` so the
  CI experience stays consistent across hollow-gate-style meta-tests.
- **D-11:** Test runs via `ci.docs` alias (not `ci.security`) — drift is a docs
  concern, and adding it to `ci.security` would force a `@gated_suites` amendment in
  `test/security/ci_gate_integrity_test.exs` for zero security benefit and would mis-
  categorize a doc failure as a security-lane failure.

### Incident playbook (DOCS-05)
- **D-12:** Publish at `guides/operations/incident_playbook.md` — requires creating
  the new `guides/operations/` directory (green-field; only `guides/recipes/` and
  `guides/case_studies/` exist today).
- **D-13:** Document spine mirrors the established operator-runbook idiom from
  `guides/recipes/logout.md` and `guides/recipes/generic_saml.md`:
  brand-voice overview → "Relyra owns / Host owns" trust-boundary preamble →
  reference table → scenario runbooks → closing pointer. Deviating would feel
  jarring after Phases 36–39 locked this pattern.
- **D-14:** Anchor the body on a **five-surface reference table** mapping each
  incident-response evidence source to exact code anchors:
  1. **Telemetry events** — namespace `[:relyra, :saml, ...]` cited verbatim from
     `lib/relyra/telemetry.ex`.
  2. **Audit ledger** — `relyra_audit_events` table via `lib/relyra/ecto/audit_event.ex`;
     name the four `@domain_values` (`:connection`, `:metadata`, `:certificate`,
     `:mapping`) and the actual `@action_values` set.
  3. **LiveView admin routes** — `/relyra/admin`, `/relyra/admin/connections/:id`,
     `/relyra/admin/connections/:id/edit`, `/relyra/admin/connections/:id/metadata`,
     `/relyra/admin/diagnostic/bundle` per `lib/relyra/live_admin/router.ex`.
  4. **Mix tasks** — `relyra.diagnostic`, `relyra.refresh_due`, `relyra.metadata.pin`,
     `relyra.security_review`, `relyra.conformance`, `relyra.batteries_included`,
     `relyra.install`.
  5. **Troubleshooting decoder** — cross-link to `guides/troubleshooting.md`.
- **D-15:** Six **scenario-anchored runbooks** (not workflow-anchored). Operators
  arrive at the playbook with a symptom (e.g. they just saw `:digest_mismatch` in
  logs), not with a workflow phase. Each scenario is a 3-step ordered list
  Triage → Diagnose → Recover, cross-referencing the surface table:
  1. Certificate expiry imminent (`:certificate.expiring` telemetry + admin cert
     inventory + staged rollover).
  2. Metadata drift after IdP change (auto-refresh degraded/suspended events +
     `:metadata_drift_requires_review` audit + `mix relyra.refresh_due`).
  3. Replay storm (`:replayed_assertion` from `lib/relyra/replay_store/ecto.ex`;
     explicit note that replays produce NO audit signal because they do not mutate
     trust state — operators must rely on telemetry alone).
  4. Signature regression after IdP key rotation (`:digest_mismatch` /
     `:invalid_signature` / `:trust_anchor_mismatch` → diagnostic bundle → cert
     staging via admin UI).
  5. ACS misconfiguration at provisioning (`:destination_mismatch` /
     `:recipient_mismatch` / `:in_response_to_mismatch` → connection editor).
  6. Attribute mapping breakage (`:invalid_audience` → mapping audit timeline).
- **D-16:** Closing pointer: a brief "When in doubt, run `mix relyra.diagnostic`"
  section that names the unified redacted-bundle task from
  `lib/mix/tasks/relyra.diagnostic.ex` + `lib/relyra/diagnostic.ex` (DIAG-01,
  shipped Phase 23). Single first-resort evidence collector is consistent with the
  brand metaphor: every login resolves to a verified trust path or a typed
  rejection — and when in doubt, the diagnostic bundle is the trace.

### `mix.exs` wiring and CI registration
- **D-17:** Append both guides to the `mix.exs` `extras:` list in this exact order
  after the existing `"guides/recipes/logout.md"` line: `"guides/troubleshooting.md"`,
  then `"guides/operations/incident_playbook.md"`. Determinism here keeps ExDoc
  ordering stable across releases.
- **D-18:** Append both `cmd test -f` presence guards to the `ci.docs` alias after
  the existing `"cmd test -f guides/recipes/logout.md"` line. The presence guard is
  the real delete-protector — without it, a stray `git rm guides/troubleshooting.md`
  passes the drift test vacuously (zero doc atoms ∩ zero code atoms = true).
- **D-19:** Append the drift-check test invocation as a separate
  `cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` line
  AFTER both presence guards. Ordering matters: missing-file failures surface as
  clear `test -f` errors before the drift test would otherwise fail with a confusing
  "no headings matched" regex result.

### Claude's discretion
- Exact prose, table layouts, and the precise wording of operator-action lines —
  provided the four-field micro-block contract (D-04) and the five-surface table
  contract (D-14) hold.
- Whether per-domain section preambles in `guides/troubleshooting.md` include a
  one-sentence trust-boundary callout (probably yes, but layout-level decision).
- Whether the playbook's five-surface table appears once near the top or is split
  across scenario boundaries — single top-of-doc placement is recommended but the
  planner may iterate.

### Folded todos
None — `gsd-sdk query todo.match-phase 40` returned no matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — DOCS-05 + DOCS-06 acceptance wording (locked).
- `.planning/ROADMAP.md` — Phase 40 success criteria (verbatim; planner must not
  drift). Note: the v1.4 phase block currently lists a single stub plan named
  `39-01-PLAN.md` under Phase 40 — that is an authoring artifact from Phase 39 and
  must be replaced when the planner writes real Phase 40 plans.
- `.planning/phases/39-logout-strategy-and-operational-guidance/39-CONTEXT.md` —
  immediate predecessor; established the operator-runbook idiom Phase 40 inherits.
- `.planning/phases/36-generic-saml-runbook/36-CONTEXT.md` — most fleshed-out
  example of the "Relyra owns / Host owns / IdP owns" preamble + reference-table
  spine + closing-receipts pattern.
- `CLAUDE.md` — non-negotiable security invariants (none relaxed by this phase),
  brand voice, audit-ledger framing.
- `lib/relyra/error.ex` — `%Relyra.Error{type, message, details}` contract and
  `redact_details/1` (redaction-safe).
- `lib/relyra/telemetry.ex` — telemetry event catalog (cite verbatim).
- `lib/relyra/ecto/audit_event.ex` — audit row schema; `@domain_values` and
  `@action_values` must be quoted exactly in the playbook.
- `lib/relyra/live_admin/router.ex` — admin LiveView route paths (cite verbatim).
- `lib/mix/tasks/relyra.diagnostic.ex` + `lib/relyra/diagnostic.ex` — DIAG-01
  bundle implementation; the playbook's closing "When in doubt" anchor.
- `mix.exs` lines 111-160 — `extras:` list and `ci.docs` alias (Phase 40 edits both).
- `test/security/ci_gate_integrity_test.exs` — hollow-gate meta-test; the
  drift-check failure-message vocabulary should mirror this file's style for
  CI-experience consistency.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `Relyra.Error` struct and `redact_details/1` (`lib/relyra/error.ex:1-58`) — no
  changes; the troubleshooting guide documents what already exists.
- `Relyra.Telemetry` (`lib/relyra/telemetry.ex`) — full event namespace catalog,
  ready to cite.
- `Relyra.Ecto.AuditEvent` (`lib/relyra/ecto/audit_event.ex`) — `@domain_values` and
  `@action_values` enumerations are the canonical audit-row vocabulary.
- `Relyra.LiveAdmin.Router` (`lib/relyra/live_admin/router.ex`) — admin routes are
  stable and exposed.
- Mix tasks under `lib/mix/tasks/relyra.*.ex` — eight operator hand-tools, all
  already shipped; the playbook surfaces them, doesn't add new ones.
- `lib/relyra/diagnostic.ex` + `lib/mix/tasks/relyra.diagnostic.ex` (DIAG-01,
  Phase 23) — the unified evidence collector cited at the playbook's closing.
- Recipe-style guides at `guides/recipes/*.md` (logout, adfs, okta, entra,
  google_workspace, generic_saml) and `guides/identity_mapping_and_provisioning.md`
  — proven document idiom; Phase 40 reuses, doesn't invent.
- `mix.exs` `ci.docs` alias (lines ~146-159) — already mixes `cmd test -f` presence
  guards with `cmd mix test test/...` runs; the new drift-check fits cleanly.

### Established patterns
- "Relyra owns / Host owns" preamble: `guides/recipes/logout.md:24-41`,
  `guides/recipes/generic_saml.md`, `guides/identity_mapping_and_provisioning.md`.
- Hollow-gate-style CI invariant: each `mix test` invocation runs as its own
  `cmd mix test` step under aliases (`test/security/ci_gate_integrity_test.exs:21-26`,
  CLAUDE.md "Testing Requirements"). The drift-check follows this pattern.
- Domain grouping by trust-pipeline seam: `CLAUDE.md` "Key Architecture Seams" table
  is the canonical taxonomy mirror for the troubleshooting guide's section split.
- Documentation drift via test enforcement: not previously done in this repo, but
  consistent with the strict-defaults posture (assertion-by-test, not by intent).

### Integration points
- `mix.exs` `extras:` list (line 111+) — exposes guides to ExDoc.
- `mix.exs` `aliases.ci.docs` — runs in CI; Phase 40 adds three lines.
- `test/docs/` — green-field test subdirectory under existing `test/` tree.
- `guides/operations/` — green-field subdirectory under existing `guides/` tree.

### Non-integration points (explicit)
- `Relyra.Error` module — left untouched. No `@known_types` attribute (D-07).
- `ci.security` alias — left untouched (D-11). Drift is a docs concern.
- `test/security/ci_gate_integrity_test.exs` `@gated_suites` list — left untouched
  (D-11). No new security suites in this phase.
- Validation pipeline, signature verifier, replay store, audit writer — no source
  edits. Phase 40 documents what they emit; it does not change what they emit.
</code_context>

<specifics>
## Specific Ideas

- The troubleshooting guide's section preambles should each open with a one-sentence
  trust-boundary frame ("These atoms fire BEFORE saxy parse runs — the request never
  reached the trust core.") so the operator immediately knows whether they're looking
  at a parser-hardening failure vs. a crypto failure vs. a session/binding failure.
- The incident playbook's five-surface reference table should be the doc's literal
  centerpiece — appearing once near the top, with every scenario referencing into it
  rather than restating evidence sources inline.
- The replay-storm scenario should explicitly note that replays produce no audit row
  (replays do not mutate trust state) — this is a non-obvious gap operators will look
  for, and naming it avoids confusion.
- Closing operator receipt for the playbook should match the Phase 36 / Phase 39
  "proof, then production follow-ons" posture: name `mix relyra.diagnostic` first,
  then list the admin views, then point at the troubleshooting decoder.
</specifics>

<deferred>
## Deferred Ideas

- A `Relyra.Error.known_types/0` introspection helper that returns the canonical atom
  set as runtime data. Considered (D-07) and rejected for v1.4 — would create a
  second source of truth requiring its own drift-check. Could be revisited if a
  future phase needs runtime-introspectable error catalogs (e.g. for the LiveView
  admin to surface a real-time error legend).
- An auto-generated troubleshooting guide built from `@moduledoc`s on error-emitting
  modules. Out of scope — Phase 40 ships hand-authored prose with assertion-by-test;
  generation would change the document character from operator narrative to API
  reference.
- A telemetry event catalog page (separate from the playbook). The playbook cites
  events inline; a standalone catalog could come later if `lib/relyra/telemetry.ex`
  grows past comfortable inline citation.
- A LiveView admin "incident dashboard" view. Out of scope — Phase 40 is docs +
  drift-check; UI work belongs to a follow-on phase if demand emerges post-v1.4.

### Reviewed Todos (not folded)
None — `gsd-sdk query todo.match-phase 40` returned no matches.
</deferred>
