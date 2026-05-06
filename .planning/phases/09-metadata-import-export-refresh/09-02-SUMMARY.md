# Plan 09-02 Summary

## Outcome

Implemented the isolated metadata apply boundary with durable attempt recording and atomic rollback behavior.

## Delivered

- Added `Relyra.Ecto.MetadataApply.apply_revision/4`.
- Added `Relyra.Ecto.MetadataApply.record_attempt/3`.
- Kept resolver hydration aggregate-only by leaving `Relyra.Ecto.ConnectionLoader` and `Relyra.Ecto.ConnectionSnapshot` unchanged.
- Added integration coverage for successful apply, rollback on invalid certificate replacement, and pre-apply failure recording.

## Verification

- `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors`

## Notes

- Revision rows are inserted before live-state mutation, and any downstream changeset failure rolls back the revision insert with the rest of the transaction.
