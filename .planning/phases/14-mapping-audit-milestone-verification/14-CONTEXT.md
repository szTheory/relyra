# Phase 14: Mapping/audit milestone verification - Context

**Gathered:** 2026-05-06 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `CFG-05` by producing the missing `11-VERIFICATION.md` artifact that proves Phase 11's mapping persistence and cross-domain audit hardening behavior, then refresh the minimum live-truth files so milestone traceability marks `CFG-05` complete from verification evidence rather than plan completion alone. This phase is a verification-and-traceability closure phase for already-shipped mapping/audit behavior, not a redesign of mapping semantics, audit architecture, or runtime hydration rules. It does not reopen Phase 11 implementation work, does not edit historical audit artifacts, and does not extend the mapping or audit surface area.

</domain>

<decisions>
## Implementation Decisions

### Plan decomposition
- **D-01:** Phase 14 ships exactly two execute plans:
  - `14-01-PLAN.md` — produce `11-VERIFICATION.md` from the locked serial packet plus the blocking manual sign-off gate.
  - `14-02-PLAN.md` — update live milestone truth in `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` after `CFG-05` verification closure.
- **D-02:** Do not add a `11-VALIDATION.md` sync plan. `11-VALIDATION.md` is already `status: complete`, `nyquist_compliant: true`, and `wave_0_complete: true`, so the Phase 13 sync analog (`13-01-PLAN.md`) is unnecessary here.
- **D-03:** Do not edit `.planning/v0.2-MILESTONE-AUDIT.md` or any other historical audit artifact. Historical audit documents stay point-in-time evidence; milestone truth is refreshed by subsequent audit passes, not by mutating old findings.

### Verification packet strictness
- **D-04:** Use a balanced verification packet: serial, compact, and intentionally non-duplicative. Goal is crisp `CFG-05` proof, not artifact volume.
- **D-05:** Preserve the serial-only posture inherited from Phase 12 / Phase 13. Do not parallelize the verification commands for this phase; parallel Mix bootstrapping races have already been called out as a false-failure footgun in `v0.2-MILESTONE-AUDIT.md`.
- **D-06:** The verification packet is exactly three commands, executed in order:
  1. `mix compile --warnings-as-errors`
  2. one focused serial mapping/audit command covering: `test/relyra/ecto/mapping_commands_test.exs`, `test/relyra/ecto/audit_hardening_test.exs`, `test/relyra/ecto/attribute_mapping_schema_test.exs`, `test/relyra/ecto/group_mapping_schema_test.exs`, `test/relyra/ecto/mapping_revision_schema_test.exs`, `test/relyra/ecto/audit_event_schema_test.exs`, `test/relyra/ecto/migration_constraints_test.exs`, `test/relyra/connection_snapshot_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs` — all `--warnings-as-errors`.
  3. `mix test --warnings-as-errors` full-suite confirmation.

### Behavior-to-test traceability map
- **D-07:** `11-VERIFICATION.md` MUST contain a CFG-05 behavior-to-test/evidence map with exactly four rows mirroring the `11-UAT.md` axes:
  1. **Mapping persistence (live rows + revision ledger)** — proven by `mapping_commands_test.exs`, `attribute_mapping_schema_test.exs`, `group_mapping_schema_test.exs`, `mapping_revision_schema_test.exs`, `migration_constraints_test.exs`; cross-referenced with `11-01-SUMMARY.md`, `11-02-SUMMARY.md`, `11-04-SUMMARY.md`.
  2. **Cross-domain audit hardening (same-transaction capture)** — proven by `audit_hardening_test.exs`, `audit_event_schema_test.exs`, `connection_record_test.exs`, `metadata_apply_test.exs`, `certificate_inventory_transition_test.exs`; cross-referenced with `11-03-SUMMARY.md`.
  3. **Audited mapping mutation surface (typed commands, no parent-write back-channel)** — proven by `mapping_commands_test.exs`, `connection_record_test.exs`; cross-referenced with `11-01-SUMMARY.md`, `11-04-SUMMARY.md`.
  4. **Runtime `mapping_config` hydration (persistence-agnostic plain values)** — proven by `connection_snapshot_test.exs`, `ecto_connection_resolver_test.exs`, `user_mapper/default_attribute_test.exs`; cross-referenced with `11-04-SUMMARY.md`.

### Evidence style and manual sign-off posture
- **D-08:** Use a hybrid verification artifact: executable proof first, brief narrative second. Mirror `10-VERIFICATION.md` shape (Scope → Requirement Traceability → Phase-Audit Gap Closed → Automated Evidence Packet → Evidence Map → Manual Sign-Off).
- **D-09:** `11-VERIFICATION.md` MUST contain: exact serial commands with timestamps, observed pass/fail results and counts, the four-row `CFG-05` behavior-to-test/evidence map (D-07), and the minimum manual sign-off needed for semantics humans actually judge.
- **D-10:** Manual sign-off is capped at exactly two narrow, blocking semantics judgments:
  1. Confirm cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material.
  2. Confirm the runtime `mapping_config` contract stays persistence-agnostic — plain `attribute_rules` / `group_rules`, deterministic ordering, persisted-rules-first with fallback — so host-app `Relyra.UserMapper` consumers see stable values.
- **D-11:** Manual sign-off MUST NOT be used to prove functional correctness that the automated packet already proves. If a check is automatable, automate it instead of routing it through human review.

### Decision-handling posture
- **D-12:** Planning and execution for this phase should be recommendation-first and low-friction: low-risk verification-shape choices should be decided by the workflow/agent by default. Only escalate decisions that materially change product semantics, trust guarantees, or milestone truth beyond `CFG-05` closure.

### Claude's Discretion
- Exact section names, prose layout, and timestamp format inside `11-VERIFICATION.md`, as long as the artifact stays compact, reproducible, easy to audit, and follows the Phase 10 verification artifact shape.
- Exact wording of the two manual semantics checks in D-10, as long as they remain semantics-focused rather than re-testing functionality by hand.
- Exact wording of the live-truth refresh edits in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, as long as `CFG-05` becomes visibly satisfied at milestone level and no historical artifact is mutated.
- Exact ordering of `14-01` and `14-02` plans during execution, provided `11-VERIFICATION.md` exists before live-truth refresh declares `CFG-05` closed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirement anchors
- `.planning/ROADMAP.md` — Phase 14 goal, gap-closure note, and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-05` requirement anchor and milestone traceability target.
- `.planning/PROJECT.md` — strict trust posture, explainability expectations, operator-safe runtime boundary, and milestone boundaries.
- `.planning/STATE.md` — current milestone state and status surface that Phase 14 will need to refresh.
- `.planning/v0.2-MILESTONE-AUDIT.md` — orphaned `CFG-05` evidence motivating this phase. Do NOT mutate.

### Locked prior decisions and verification precedents
- `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` — mapping persistence model, cross-domain audit boundary, runtime hydration purity rules, and bounded mapping semantics.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-VALIDATION.md` — locked task-to-test map; `nyquist_compliant: true`, `wave_0_complete: true`. Phase 14 reuses this as the proof surface input rather than re-deriving it.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-UAT.md` — six-axis user acceptance evidence Phase 14's traceability map mirrors.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md` — runtime mapping contract, parent-write rejection, and live-row + ledger schema delivery evidence.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-02-SUMMARY.md` — canonical mapping/audit migration and constraint coverage evidence.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-03-SUMMARY.md` — shared audit writer and same-transaction audit capture evidence across connection, metadata, and certificate domains.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-04-SUMMARY.md` — dedicated mapping commands, mapping snapshot hydration, and persisted-config-driven default mapping evidence.
- `.planning/phases/13-certificate-rollover-validation-verification/13-CONTEXT.md` — locked verification-packet posture, evidence-style decisions, and recommendation-first discussion posture that Phase 14 inherits.
- `.planning/phases/13-certificate-rollover-validation-verification/13-02-PLAN.md` — direct precedent for producing a `*-VERIFICATION.md` artifact from a locked serial packet plus blocking manual sign-off.
- `.planning/phases/13-certificate-rollover-validation-verification/13-03-PLAN.md` — direct precedent for refreshing live milestone truth (`REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`) after requirement closure without mutating historical artifacts.
- `.planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` — verification-artifact shape Phase 14's `11-VERIFICATION.md` should mirror (Scope, Requirement Traceability, Phase-Audit Gap Closed, Automated Evidence Packet, Evidence Map, Manual Sign-Off).

### Existing code and tests that define the proof surface
- `lib/relyra/ecto/mapping_commands.ex` — authoritative dedicated mapping mutation surface with typed actions and audit-row attribution.
- `lib/relyra/ecto/audit_writer.ex` — shared same-transaction audit append helper and redaction posture.
- `lib/relyra/ecto/audit_event.ex` — append-only cross-domain audit ledger schema.
- `lib/relyra/ecto/attribute_mapping.ex` / `lib/relyra/ecto/group_mapping.ex` — live mapping row schemas Phase 14 verifies.
- `lib/relyra/ecto/mapping_revision.ex` — append-only mapping revision ledger.
- `lib/relyra/ecto/connection_snapshot.ex` — runtime hydration boundary that exposes plain `mapping_config` only.
- `lib/relyra/user_mapper.ex` / `lib/relyra/user_mapper/default_attribute.ex` — runtime mapper consuming persisted normalized rules with fallback behavior.
- `test/relyra/ecto/mapping_commands_test.exs` — dedicated mapping mutation, multivalue handling, and audit attribution proof surface.
- `test/relyra/ecto/audit_hardening_test.exs` — cross-domain audit redaction, attribution, and same-transaction capture proof surface.
- `test/relyra/ecto/attribute_mapping_schema_test.exs`, `test/relyra/ecto/group_mapping_schema_test.exs`, `test/relyra/ecto/mapping_revision_schema_test.exs`, `test/relyra/ecto/audit_event_schema_test.exs` — bounded validated-field schemas proof surface.
- `test/relyra/ecto/migration_constraints_test.exs` — DDL FK, ownership, uniqueness, and append-only ledger constraint proof surface.
- `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs` — runtime `mapping_config` hydration and persistence-agnostic mapper proof surface.
- `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs` — cross-domain trust-mutation audit capture proof surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Ecto.MappingCommands` already owns the typed mapping mutation surface that Phase 14 verifies; no new commands are introduced.
- `Relyra.Ecto.AuditWriter` and `Relyra.Ecto.AuditEvent` already enforce same-transaction append-only audit capture with redaction; the verification artifact validates these contracts rather than redesigning them.
- `Relyra.Ecto.ConnectionSnapshot` already enforces the persistence-agnostic `mapping_config` runtime hydration rule the artifact must make explicit.
- `Relyra.UserMapper.DefaultAttribute` already consumes persisted rules first and falls back to default behavior; the artifact validates this ordering.
- `10-VERIFICATION.md` already provides a strong in-repo artifact shape (Scope → Requirement Traceability → Phase-Audit Gap Closed → Automated Evidence Packet → Evidence Map → Manual Sign-Off).

### Established Patterns
- Verification artifacts in this repo pair exact serial commands with a short requirement-to-proof map.
- Historical audit documents are treated as point-in-time snapshots; live truth is carried by current `ROADMAP.md` / `REQUIREMENTS.md` / `STATE.md` artifacts.
- Trust-bearing behavior is proven through targeted ExUnit coverage first; manual review is reserved for semantics and operator clarity.
- Phase smoke commands run serially to avoid Ecto migration bootstrap races.

### Integration Points
- Phase 14 closes Phase 11 verification, but its live-truth updates also make `CFG-05` visibly complete at milestone level.
- The verification narrative must connect mapping persistence and audit hardening to the runtime `mapping_config` contract so milestone closure is not local to one slice.
- The resulting `11-VERIFICATION.md` should be usable by future milestone re-audits without requiring them to reconstruct intent from plan summaries.

</code_context>

<specifics>
## Specific Ideas

- Follow the strongest repo-local precedent: `10-VERIFICATION.md` is the artifact model, adapted to the mapping/audit domain.
- Favor least surprise for maintainers: a future reader should be able to answer "what command proves `CFG-05`?" and "which file closes it?" in under a minute.
- Favor least surprise for host apps and operators: the verification narrative should keep repeating the key trust rule that mapping_config is plain runtime data, audit history is durable cross-domain truth, and mapping mutations only flow through dedicated typed commands.
- Preference locked for downstream work: recommendation-first, one-shot defaults are preferred. Only unusually impactful product/security/architecture choices should come back to the user for another decision round.

</specifics>

<deferred>
## Deferred Ideas

- Broader milestone-state cleanup beyond the files Phase 14 directly settles.
- Any redesign of mapping semantics, audit ledger taxonomy, runtime hydration field names, or `Relyra.UserMapper` callback contract.
- Structured audit export / SIEM pipelines as a first-class product surface.
- Expression-language, regex, or script-based mapping transforms.
- Full admin UI workflows, previews, and rollback UX beyond the persistence/audit foundations already in place.
- GSD-wide default tuning so recommendation-first, agent-resolved discussion becomes the standard path except for genuinely high-impact decisions.

</deferred>

---

*Phase: 14-mapping-audit-milestone-verification*
*Context gathered: 2026-05-06 (assumptions mode)*
