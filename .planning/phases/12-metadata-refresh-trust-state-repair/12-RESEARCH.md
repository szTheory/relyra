---
phase: 12
slug: metadata-refresh-trust-state-repair
created: 2026-05-05
status: ready_for_planning
requirement_ids:
  - CFG-03
---

# Phase 12 — Research

## Research Goal

Answer the planning question for Phase 12: what must be preserved, what is actually broken, and what evidence is required to close `CFG-03` without reopening stable metadata and certificate-lifecycle behavior.

## What The Code Says Now

### Shared metadata write seam

- `Relyra.Metadata.Import.import_xml/3` parses XML, builds a `%Relyra.Metadata.Candidate{}`, then calls `Relyra.Ecto.MetadataApply.apply_revision/4`.
- `Relyra.Metadata.Refresh.refresh/2` fetches remote XML, parses it, builds the same candidate through `Relyra.Metadata.Import.build_candidate/1`, then calls the same `apply_revision/4`.
- The import and refresh paths therefore share one candidate-to-apply seam. Phase 12 should fix that seam once rather than branching behavior separately for import and refresh.

### Current certificate normalization shape

- `Relyra.Metadata.Import.build_candidate/1` converts each parsed metadata certificate body into PEM text with `to_pem/1`.
- It immediately derives:
  - `certificate_pems`
  - `certificate_fingerprints`
  - `certificate_facts`
- `certificate_facts` come from `Relyra.Ecto.CertificateFacts.extract/1`, which is strict X.509 PEM decoding and returns typed `:invalid_certificate_pem` failures when decoding fails.
- `%Relyra.Metadata.Candidate{}` therefore already behaves like an internal normalized contract, not a loose external-input bag.

### Trust-state mutation seam

- `Relyra.Ecto.MetadataApply.apply_revision/4` owns the only transactional metadata apply boundary.
- Connection pointer updates and certificate staging happen inside the same transaction.
- `Relyra.Ecto.CertificateInventory.stage_metadata_certificates/5` stages metadata-introduced certificates and leaves explicit activation/retirement to the separate lifecycle commands from Phase 10.
- That matches the locked decisions in `12-CONTEXT.md`: refresh/import may stage `:next` certificates but must not auto-promote them into live runtime trust.

## Actual Failure Shape

### High-confidence diagnosis

- The milestone audit records focused refresh/import failures returning `%Relyra.Error{code: :invalid_connection_record, details.reason: :invalid_certificate_pem}`.
- The current Phase 09 metadata tests still use synthetic certificate bodies like `MIIBSIGNINGCERT`, `MIIBENCRYPTCERT`, and `MIIBREFRESHCERT`.
- Those values are not real X.509 DER payloads. After `to_pem/1` wraps them, `CertificateFacts.extract/1` still rejects them as invalid PEM content.
- That means the current failure is consistent with stricter certificate-fact extraction introduced for the staged certificate lifecycle model, while older metadata fixtures still assume placeholder certificate bodies are acceptable.

### Planning implication

- The narrowest repair is not “make certificate staging accept arbitrary junk.”
- The narrowest repair is to align the metadata boundary and its tests around one canonical internal certificate contract:
  - valid metadata fixtures should contain real X.509 material and pass end to end
  - invalid certificate material should still fail with typed `:invalid_certificate_pem`
- This preserves the fail-closed trust posture introduced by certificate inventory work.

## Invariants Phase 12 Must Preserve

### Metadata semantics

- Keep the Phase 09 write-path layering: parse/normalize first, then one transactional apply path.
- Keep explicit remote refresh semantics and last-known-good pointer behavior from Phase 09.
- Do not redesign metadata import APIs, refresh triggers, or provenance storage in this phase.

### Certificate lifecycle semantics

- Keep Phase 10’s lifecycle rule: metadata-introduced signing certs stage as `:next`; existing `:active` signing certs remain active until an explicit lifecycle command changes them.
- Do not weaken `Relyra.Ecto.CertificateFacts.extract/1` to coerce malformed cert input into success.
- Do not move runtime hydration away from persisted active trust state.

### Audit and reviewability

- Keep Phase 11’s same-transaction audit posture for metadata trust mutations.
- Preserve typed failures and redacted observability on refresh failure paths.

## Likely Implementation Surface

### Primary code seams

- `lib/relyra/metadata/import.ex`
  - Owns metadata candidate construction.
  - Natural place to make the internal certificate shape explicit and keep external tolerance limited to parser/import boundaries.
- `lib/relyra/metadata/candidate.ex`
  - May need contract tightening or field-shape clarification if the canonical internal certificate shape is made more explicit.
- `lib/relyra/metadata/refresh.ex`
  - Should continue sharing candidate construction with import and preserve typed failure recording plus redacted logging/telemetry.
- `lib/relyra/ecto/metadata_apply.ex`
  - Should stay the single transactional apply seam; changes here should be limited to consuming the canonical internal candidate shape if needed.
- `lib/relyra/ecto/certificate_inventory.ex`
  - Must keep staged-certificate semantics and fail closed on invalid certificate attributes.

### Test seams that should carry the repair

- `test/relyra/metadata_test.exs`
  - Replace placeholder valid-input certificate bodies with real X.509 fixture material for import success paths.
  - Keep invalid-input tests explicit rather than relying on placeholder bodies accidentally failing later.
- `test/relyra/metadata_refresh_test.exs`
  - Replace synthetic refresh certificate content with valid fixture material for the successful refresh path.
  - Preserve malformed XML / redacted observability failure coverage as-is.
- `test/relyra/ecto/metadata_apply_test.exs`
  - Confirm apply remains atomic and staged-trust semantics remain unchanged after the metadata-certificate normalization repair.
- `test/relyra/ecto/certificate_inventory_expiry_test.exs`
  - Reuse existing real certificate material and typed invalid-PEM rejection patterns as the analog for valid-vs-invalid metadata certificate coverage.

## Recommended Planning Shape

### Plan slice 1: Canonical metadata certificate contract repair

- Make the metadata boundary consume one accepted internal certificate shape.
- Reuse real PEM/X.509 fixtures rather than synthetic placeholders for “valid metadata” tests.
- Keep explicit invalid-input tests proving `:invalid_certificate_pem` remains typed and fail-closed.

### Plan slice 2: Shared import/refresh apply-path smoke repair

- Re-verify both import and refresh through the shared candidate -> apply -> staged-certificate path.
- Preserve last-known-good runtime state and redacted observability on failure.
- Ensure active runtime trust still excludes staged `:next` certs after a successful metadata apply.

### Plan slice 3: Requirement verification closure

- Produce the missing `09-VERIFICATION.md`.
- Use the exact verification packet locked in context:
  - focused Phase 09 smoke command from `09-VALIDATION.md`
  - full `mix test --warnings-as-errors`
  - prose sign-off for the two manual checks in `09-VALIDATION.md`
  - explicit traceability back to `CFG-03`

## Risks To Call Out In Plans

### Risk: broadening scope into metadata redesign

- Avoid reworking parser semantics, source registration contracts, or runtime resolver behavior unless a concrete failing test requires it.

### Risk: weakening certificate validation

- Accepting malformed certificate bodies inside internal persistence flows would undermine Phase 10’s lifecycle guarantees and create trust ambiguity.

### Risk: false-negative verification runs

- The milestone audit already notes parallel migration bootstrap races.
- Verification steps for this phase should be serial and should not depend on concurrent migration-bootstrapping test commands.

## Validation Architecture

Phase 12’s validation burden is mostly regression closure plus evidence production:

- Fast repair loop:
  - `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors`
- Full confidence gate:
  - `mix test --warnings-as-errors`
- Manual checks:
  - confirm the chosen SSO endpoint selection still reads as the intended least-surprise rule
  - confirm import/register/refresh wording still reads as explicit write-side behavior, not runtime request-path behavior
- Final artifact:
  - `09-VERIFICATION.md` must trace results to `CFG-03`

## Recommended Planner Constraints

- Prefer 2-3 plans, not a large fan-out; this phase is a repair phase with one shared seam and one verification closure deliverable.
- Keep the trust model fixed:
  - successful metadata apply may stage `:next` certs
  - successful metadata apply may update metadata pointers
  - successful metadata apply may not auto-activate new trust
- Require acceptance criteria that prove:
  - valid metadata fixtures now pass import and refresh
  - invalid certificate input still fails with typed `:invalid_certificate_pem`
  - runtime snapshots continue exposing only active certificates
  - `09-VERIFICATION.md` exists and names `CFG-03`

## Research Conclusion

Phase 12 should be planned as a narrow metadata-certificate contract repair plus verification closure. The evidence points to placeholder metadata certificate fixtures drifting out of sync with the stricter X.509 expectations now enforced by the staged certificate inventory path. The correct fix is to align the metadata boundary and its success-path fixtures with the canonical internal certificate contract while preserving typed invalid-input rejection, staged trust semantics, and requirement-level verification evidence.
