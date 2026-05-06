# 10-01 Summary

Status: completed

Implemented metadata certificate fact extraction and persistence for staged inventory rows.

- Added `Relyra.Ecto.CertificateFacts` to decode PEM validity windows from X.509 certificates.
- Extended `Relyra.Metadata.Candidate` and `Relyra.Metadata.Import` to carry decoded certificate facts alongside PEMs and fingerprints.
- Updated `Relyra.Ecto.CertificateInventory.stage_metadata_certificates/4` to persist `not_before` and `not_after`, and to fail closed with typed `:invalid_certificate_pem` errors.
- Added expiry-focused regression coverage for valid staging, persisted timestamp accuracy, and malformed PEM rollback behavior.

Verification:

- `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors`
