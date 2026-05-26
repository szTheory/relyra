---
phase: 32-algorithm-policy-extension-schema-migrations
fixed_at: 2026-05-25T16:46:30Z
review_path: .planning/phases/32-algorithm-policy-extension-schema-migrations/32-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 32: Code Review Fix Report

**Fixed at:** 2026-05-25T16:46:30Z
**Source review:** `.planning/phases/32-algorithm-policy-extension-schema-migrations/32-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Stale error message "Legacy SHA-1 override has expired" fires for AES-CBC expired hatches

**Files modified:** `lib/relyra/security/algorithm_policy.ex`
**Commit:** `a8a4d9a`
**Applied fix:** Added a `label` derivation in the expired-override branch of `enforce_legacy_override/3`. When `method_type` is `:content_encryption_algorithm`, the label is `"AES-CBC"`; all other paths (SHA-1 signature/digest) keep `"SHA-1"`. The interpolated message is now `"Legacy #{label} override has expired"`.

Also applied IN-01 (trivially co-located): renamed the fallback-clause parameter `_legacy_sha1` to `_legacy_override` since this clause now handles both SHA-1 and AES-CBC paths.

### WR-01: `party` and `use` have no Elixir-side defaults — explicit `nil` bypasses `Ecto.Enum` cast and produces a raw DB constraint error

**Files modified:** `lib/relyra/ecto/certificate.ex`
**Commit:** `495796e`
**Applied fix:** Added `default: :idp` to the `field :party` declaration and `default: :signing` to the `field :use` declaration. Added `put_change_unless_present(:party, :idp)` and `put_change_unless_present(:use, :signing)` calls in `put_defaults/1`, mirroring the existing pattern for `:role` and `:lifecycle_state`. An in-memory `%Certificate{}` now has correct defaults, and changeset validation catches explicit nil before reaching the DB.

### WR-02: `@active_signing_cert_filters` does not filter on `party: :idp` — SP certificates now count toward the IdP signing cert check

**Files modified:** `lib/relyra/ecto/connection.ex`
**Commit:** `8f2cc3e`
**Applied fix:** Added `party: :idp` to `@active_signing_cert_filters`. The filter helper uses `Map.get(certificate, field, value)` with `value` as fallback, so legacy rows without a `:party` field default to `:idp` correctly — no migration of old rows is needed.

### WR-03: `sign_authn_requests` is persisted and cast but never read — the feature is a silent no-op

**Files modified:** `lib/relyra/connection.ex`, `lib/relyra/ecto/connection_snapshot.ex`
**Commit:** `9c66a88`
**Applied fix:** Added `sign_authn_requests: false` to the `Relyra.Connection` defstruct (with `false` default) and to the `@type t` spec. Projected the field in `ConnectionSnapshot.base_runtime_attrs/1` as `sign_authn_requests: Map.get(connection, :sign_authn_requests, false)`. `AuthnRequest.build/3` was not touched — that is follow-on work outside this phase's scope.

### WR-04: `validate_method/3` and `validate_digest/3` are dead public API wrapping the already-public `enforce_*` functions

**Files modified:** `lib/relyra/security/algorithm_policy.ex`
**Commit:** `708e519`
**Applied fix:** Removed both `validate_method/3` and `validate_digest/3` entirely. Confirmed zero callers in `lib/` and `test/` before removal. Both functions were added in this phase and the canonical calling convention (`enforce_*` forms) is used by all existing callers.

---

## Verification Results

After all fixes were committed, from the main project directory:

- `mix test --warnings-as-errors`: **575 tests, 0 failures**
- `mix format --check-formatted`: **exit 0**

---

_Fixed: 2026-05-25T16:46:30Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
