---
phase: 12-metadata-refresh-trust-state-repair
plan: 12-02
status: completed
requirement: CFG-03
commits:
  - 206bdd5
  - c5c937e
---

# Phase 12 Plan 12-02 Summary

Outcome: metadata refresh still flows through `Import.build_candidate/1` into `MetadataApply.apply_revision/4`, while the apply seam now derives its legacy certificate mirrors from the authoritative candidate `certificates` collection so staged `:next` trust behavior and rollback invariants remain unchanged.

Files changed:
- `lib/relyra/metadata/refresh.ex`
- `lib/relyra/ecto/metadata_apply.ex`
- `test/relyra/metadata_refresh_test.exs`
- `test/relyra/ecto/metadata_apply_test.exs`

Verification command:

```sh
mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors
```

Verification result: passed, `8 tests, 0 failures`.

Notes:
- Successful refresh coverage now uses real X.509-backed metadata instead of placeholder certificate text and still records redacted observability fields.
- `MetadataApply.apply_revision/4` remains the only mutation boundary and preserves active runtime trust while newly discovered metadata signing certificates persist as `:next`.
- The malformed certificate rollback assertion now exercises the repaired candidate contract by passing an authoritative `certificates` collection that carries typed certificate decode failure state.

Deviations:
- None within the owned file scope.
