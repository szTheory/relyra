---
phase: 12-metadata-refresh-trust-state-repair
plan: 12-01
status: completed
requirement: CFG-03
commits:
  - 6d5d652
  - 9e37f37
---

# Phase 12 Plan 12-01 Summary

Outcome: `Relyra.Metadata.Import.build_candidate/1` now normalizes metadata certificates once into a canonical candidate `certificates` collection, with the legacy PEM/fingerprint/facts arrays retained only as derived compatibility mirrors for the existing apply path.

Files changed:
- `lib/relyra/metadata/import.ex`
- `lib/relyra/metadata/candidate.ex`
- `test/relyra/metadata_test.exs`
- `test/relyra/ecto/certificate_inventory_expiry_test.exs`

Verification command:

```sh
mix test test/relyra/metadata_test.exs test/relyra/ecto/certificate_inventory_expiry_test.exs --warnings-as-errors
```

Verification result: passed, `10 tests, 0 failures`.

Notes:
- Valid metadata success coverage now uses real X.509-backed certificate fixtures instead of placeholder certificate bodies.
- Malformed certificate coverage remains explicit and still surfaces typed `:invalid_certificate_pem` behavior through `Relyra.Ecto.CertificateFacts.extract/1`.
- `certificate_facts`, `certificate_pems`, and `certificate_fingerprints` are still present for downstream compatibility, but they are derived from the authoritative `certificates` collection to avoid drift.

Deviations: None within the owned implementation scope.
