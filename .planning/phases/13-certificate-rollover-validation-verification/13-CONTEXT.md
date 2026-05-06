# Phase 13: Certificate rollover validation + verification - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `CFG-04` by finishing Phase 10's missing validation closure and producing the verification evidence that proves certificate expiry tracking, staged promotion, rollback, and runtime trust-window behavior are satisfied. This phase is a verification-and-traceability closure phase for already-shipped rollover behavior, not a redesign of certificate lifecycle semantics, metadata semantics, or audit architecture.

</domain>

<decisions>
## Implementation Decisions

### Verification packet strictness
- **D-01:** Use a balanced verification packet, not a minimal proof and not a belt-and-suspenders dossier.
- **D-02:** The verification packet should be serial and compact:
  - `mix compile --warnings-as-errors`
  - one focused serial rollover command covering `test/relyra/ecto/certificate_inventory_expiry_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs`, `test/relyra/ecto/certificate_inventory_concurrency_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/connection_snapshot_test.exs`
  - one `mix test --warnings-as-errors` full-suite confirmation
- **D-03:** Keep the packet intentionally non-duplicative. The goal is crisp `CFG-04` proof, not artifact volume.
- **D-04:** Preserve the serial-only posture already learned in earlier verification work; do not parallelize the verification commands for this phase.

### Traceability and artifact scope
- **D-05:** Phase 13 should create `10-VERIFICATION.md` as the authoritative verification artifact for `CFG-04`.
- **D-06:** Phase 13 should also update the minimum live-truth planning artifacts needed so `CFG-04` is no longer orphaned:
  - `.planning/REQUIREMENTS.md`
  - `.planning/ROADMAP.md`
  - `.planning/STATE.md`
- **D-07:** Do not broaden this phase into general milestone cleanup or historical artifact rewriting. Historical audit artifacts such as `.planning/v0.2-MILESTONE-AUDIT.md` should remain point-in-time evidence; milestone truth is refreshed by subsequent audit passes, not by mutating old audit findings.

### Evidence style and manual sign-off posture
- **D-08:** Use a hybrid verification artifact: executable proof first, brief narrative second.
- **D-09:** `10-VERIFICATION.md` should contain:
  - exact serial commands,
  - observed pass/fail results and counts,
  - a short `CFG-04` behavior-to-test/evidence map,
  - and only the minimum manual sign-off needed for semantics humans actually judge.
- **D-10:** Manual checks should stay capped at two narrow semantics reviews:
  - confirm the rollover API and typed conflict errors make the caller action obvious,
  - confirm runtime trust still consumes only active certs while staged and retired rows remain inventory facts only.
- **D-11:** Manual sign-off should not be used to prove functional correctness that the automated packet already proves.

### Decision-handling posture
- **D-12:** Planning and execution for this phase should be recommendation-first and low-friction: low-risk verification-shape choices should be decided by the workflow/agent by default.
- **D-13:** Escalate only decisions that materially change product semantics, trust guarantees, or milestone truth beyond `CFG-04` closure.

### the agent's Discretion
- Exact grouping of the focused rollover test command, as long as it covers expiry persistence, invalid transition handling, concurrency conflicts, resolver behavior, and active-only runtime hydration.
- Exact section names and prose layout inside `10-VERIFICATION.md`, as long as the artifact stays compact, reproducible, and easy to audit.
- Exact wording of the two manual checks, as long as they remain semantics-focused rather than re-testing functionality by hand.

</decisions>

<specifics>
## Specific Ideas

- Follow the strongest repo-local precedent: Phase 09's verification artifact shape is the model, but adapted to the rollover domain.
- Favor least surprise for maintainers: a future reader should be able to answer “what command proves `CFG-04`?” and “which file closes it?” in under a minute.
- Favor least surprise for host apps and operators: the verification narrative should keep repeating the key trust rule that active certs define runtime trust, while staged and retired certs remain durable inventory state.
- Preference locked for downstream work: recommendation-first, one-shot defaults are preferred. Only unusually impactful product/security/architecture choices should come back to the user for another decision round.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirement anchors
- `.planning/ROADMAP.md` — Phase 13 goal, gap-closure note, and success criteria.
- `.planning/REQUIREMENTS.md` — `CFG-04` requirement anchor and milestone traceability target.
- `.planning/PROJECT.md` — strict trust posture, explainability expectations, and operator-safe runtime boundary.
- `.planning/STATE.md` — current milestone state and status surface that Phase 13 will need to refresh.
- `.planning/v0.2-MILESTONE-AUDIT.md` — orphaned `CFG-04` evidence and Nyquist gap context motivating this phase.

### Locked prior decisions and verification precedents
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` — lifecycle model, staged promotion semantics, and active-only runtime trust window.
- `.planning/phases/10-certificate-inventory-rollover/10-VALIDATION.md` — Wave 0 gaps, focused commands, and manual-only checks that Phase 13 must close.
- `.planning/phases/10-certificate-inventory-rollover/10-RESEARCH.md` — rollover hardening rationale, invariants, and known pitfalls.
- `.planning/phases/10-certificate-inventory-rollover/10-03-SUMMARY.md` — implemented transition/concurrency contract and final rollover hardening slice.
- `.planning/phases/09-metadata-import-export-refresh/09-VERIFICATION.md` — local precedent for compact serial verification artifacts with manual sign-off.
- `.planning/phases/12-metadata-refresh-trust-state-repair/12-CONTEXT.md` — prior decision to treat verification closure as part of repair/closure phases, not optional follow-up work.

### Existing code and tests that define the proof surface
- `lib/relyra/ecto/certificate_inventory.ex` — authoritative promotion, retirement, rollback, and conflict behavior.
- `lib/relyra/ecto/connection_snapshot.ex` — active-only runtime trust hydration rule.
- `test/relyra/ecto/certificate_inventory_expiry_test.exs` — expiry persistence proof surface.
- `test/relyra/ecto/certificate_inventory_transition_test.exs` — invalid transition and rollback proof surface.
- `test/relyra/ecto/certificate_inventory_concurrency_test.exs` — concurrency conflict proof surface.
- `test/relyra/ecto/ecto_connection_resolver_test.exs` — resolver/runtime rollover integration proof surface.
- `test/relyra/connection_snapshot_test.exs` — runtime trust-window filtering proof surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Ecto.CertificateInventory` already owns the trust-bearing rollover mutation APIs and typed conflict behavior this phase must verify rather than redesign.
- `Relyra.Ecto.ConnectionSnapshot` already enforces the active-only runtime trust-set rule that the verification artifact should make explicit.
- The focused rollover test files already exist and align closely with the missing `CFG-04` proof obligations.
- `09-VERIFICATION.md` already provides a strong in-repo artifact pattern for serial commands, result capture, and concise manual sign-off.

### Established Patterns
- Verification artifacts in this repo are strongest when they pair exact serial commands with a short requirement-to-proof map.
- Historical audit documents are treated as snapshots in time; live truth is carried by current roadmap/requirements/state artifacts.
- Security- and trust-bearing behavior is proven through targeted ExUnit coverage first, with manual review reserved for semantics and operator clarity.

### Integration Points
- Phase 13 closes Phase 10, but its artifact updates must also make `CFG-04` visibly complete at the milestone level.
- The verification narrative must connect persistence-side lifecycle transitions to resolver/runtime trust behavior so milestone closure is not local-only.
- The resulting `10-VERIFICATION.md` should be usable by future milestone re-audits without requiring them to reconstruct intent from plan summaries.

</code_context>

<deferred>
## Deferred Ideas

- Broader milestone-state cleanup beyond the files Phase 13 directly settles.
- Any redesign of rollover APIs, lifecycle states, metadata staging semantics, or audit architecture.
- GSD-wide default tuning so recommendation-first, agent-resolved discussion becomes the standard path except for genuinely high-impact decisions.

</deferred>

---

*Phase: 13-certificate-rollover-validation-verification*
*Context gathered: 2026-05-05*
