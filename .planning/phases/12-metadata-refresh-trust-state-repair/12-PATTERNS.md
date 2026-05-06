# Phase 12: Metadata refresh trust-state repair - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/relyra/metadata/import.ex` | service | transform -> request-response | `lib/relyra/metadata/import.ex` | exact |
| `lib/relyra/metadata/candidate.ex` | model | transform | `lib/relyra/metadata/candidate.ex` | exact |
| `lib/relyra/metadata/refresh.ex` | service | request-response | `lib/relyra/metadata/refresh.ex` | exact |
| `lib/relyra/ecto/metadata_apply.ex` | service | transactional request-response | `lib/relyra/ecto/metadata_apply.ex` | exact |
| `lib/relyra/ecto/certificate_inventory.ex` | service | transactional request-response | `lib/relyra/ecto/certificate_inventory.ex` | exact |
| `test/relyra/metadata_test.exs` | test | unit/integration | `test/relyra/metadata_test.exs` | exact |
| `test/relyra/metadata_refresh_test.exs` | test | integration | `test/relyra/metadata_refresh_test.exs` | exact |
| `test/relyra/ecto/metadata_apply_test.exs` | test | integration | `test/relyra/ecto/metadata_apply_test.exs` | exact |

## Pattern Assignments

### `lib/relyra/metadata/import.ex`

**Keep the shared candidate-builder pattern.**

- `import_xml/3` is already the canonical local-write entrypoint: parse -> `build_candidate/1` -> `MetadataApply.apply_revision/4`.
- `build_candidate/1` is the correct seam for certificate-shape normalization because refresh already reuses it.
- Planning should avoid duplicating certificate normalization in `refresh.ex` or `metadata_apply.ex`.

**Concrete pattern to preserve:**
- success path returns a `%Candidate{}` with normalized fields
- typed parse failures call `MetadataApply.record_attempt/3`
- `trust_summary` is computed at the metadata boundary, not inside persistence

### `lib/relyra/metadata/candidate.ex`

**Treat `%Relyra.Metadata.Candidate{}` as an internal contract, not an external loose map.**

- The struct already carries `certificate_facts`, `certificate_pems`, and `certificate_fingerprints`.
- Any Phase 12 change should make that contract clearer or stricter, not more union-shaped.

### `lib/relyra/metadata/refresh.ex`

**Preserve the explicit refresh orchestration pattern.**

- `refresh/2` performs: repo/Req guards -> fetch source -> fetch XML -> parse -> `Import.build_candidate/1` -> `MetadataApply.apply_revision/4`.
- It already records typed failures via `MetadataApply.record_attempt/3`.
- Redacted logging and telemetry are part of the contract and should remain in place.

**Concrete pattern to preserve:**
- refresh shares candidate construction with import
- failure handling updates metadata source outcome and records a durable failed revision attempt
- no runtime trust mutation happens outside the apply path

### `lib/relyra/ecto/metadata_apply.ex`

**Preserve the single transactional apply seam.**

- This module owns connection pointer updates, certificate staging, and same-transaction audit append.
- Plans should not move certificate decoding logic here unless required to consume a clarified candidate shape.

**Concrete pattern to preserve:**
- `apply_revision/4` fetches repo and connection, then transacts once
- invalid certificate staging must roll back revision + connection changes
- typed `Relyra.Error` values are normalized back out of the transaction

### `lib/relyra/ecto/certificate_inventory.ex`

**Preserve staged-trust semantics and strict certificate validation.**

- `stage_metadata_certificates/5` is the analog for how metadata-introduced certs enter persistence.
- This module should keep failing closed on invalid cert data and should keep `:next` staging semantics unchanged.

**Concrete pattern to preserve:**
- metadata certificates are staged, not activated
- transition commands remain explicit (`activate_signing_certificate/4`, `retire_signing_certificate/4`, `rollback_signing_certificate/5`)
- certificate facts must come from real PEM/X.509 material

### `test/relyra/metadata_test.exs`

**Use the metadata import tests as the contract source for valid vs invalid metadata inputs.**

- Existing success-path fixtures currently use placeholder certificate bodies; this is the main drift point.
- Phase 12 should convert success fixtures to real certificate material and keep explicit negative tests for malformed inputs.

### `test/relyra/metadata_refresh_test.exs`

**Use the refresh smoke tests as the shared-seam regression proof.**

- The successful refresh path should prove:
  - remote XML fetch works only when explicitly invoked
  - metadata apply succeeds
  - existing active certs stay active
  - newly imported certs remain staged as `:next`
- The failure path should continue proving redacted logs/telemetry and last-known-good preservation.

### `test/relyra/ecto/metadata_apply_test.exs`

**Use the apply tests as the trust-state invariants source.**

- This file already encodes the rule that successful metadata apply stages new certs while preserving the active runtime trust set.
- It also already encodes rollback-on-invalid-certificate behavior.
- Phase 12 plans should reuse these invariants rather than inventing new runtime behavior assertions elsewhere.

## Planner Guidance

- Reuse the existing metadata candidate -> apply -> inventory path; do not create a Phase 12-only codepath.
- Reuse real certificate PEM fixtures already present in certificate-expiry coverage where possible.
- Prefer updating test fixtures and narrowly clarifying the internal candidate contract over broad code churn in persistence modules.
- Keep verification evidence centered on:
  - `test/relyra/metadata_test.exs`
  - `test/relyra/metadata_refresh_test.exs`
  - `test/relyra/ecto/metadata_apply_test.exs`
  - `09-VERIFICATION.md`
