---
phase: 32-algorithm-policy-extension-schema-migrations
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/relyra/ecto/certificate.ex
  - lib/relyra/ecto/connection.ex
  - lib/relyra/security/algorithm_policy.ex
  - priv/repo/migrations/20260525100000_add_party_and_use_to_relyra_connection_certificates.exs
  - priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs
  - test/relyra/security/algorithm_policy_test.exs
  - test/security/strict_default_proof_test.exs
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 32 introduces `enforce_key_transport_algorithm/2` (RSA-PKCS1v1.5 permanent block) and `enforce_content_encryption_algorithm/3` (AES-GCM default, AES-CBC time-boxed hatch, auth-tag guard) into `AlgorithmPolicy`, two DB migrations adding `party`/`use` to certificates and `sign_authn_requests` to connections, and corresponding Ecto schema extensions.

The PKCS1v1.5 hard-reject and auth-tag guard ordering are both correctly implemented. The security invariants named in the phase brief hold. However, two issues require fixing before this ships: a misleading hardcoded error message that will confuse operators when an AES-CBC hatch expires (not SHA-1), and a missing `validate_required` for the new `party`/`use` columns that are `NOT NULL` in the database — allowing a changeset with explicit `nil` values to reach the DB and produce a raw constraint error instead of a clean validation error.

---

## Critical Issues

### CR-01: `enforce_legacy_override` error message says "Legacy SHA-1 override has expired" for AES-CBC expired hatches

**File:** `lib/relyra/security/algorithm_policy.ex:222`

**Issue:** `enforce_legacy_override/3` is a shared private function called by both the SHA-1 path (`enforce_sha1_policy`) and the new AES-CBC path (`enforce_content_encryption_algorithm`). The human-readable error message is hardcoded as `"Legacy SHA-1 override has expired"` regardless of the `method_type` argument that is already threaded through. When an operator's AES-CBC compatibility window expires, they receive a confusing `{:legacy_algorithm_override_expired, "Legacy SHA-1 override has expired"}` error that says SHA-1 when the real issue is AES-CBC. The `algorithm_type` detail in the error map is correct (`:content_encryption_algorithm`), but operators typically read the message string first when triaging incidents.

This is a security-relevant diagnostic correctness issue: obscured error messages delay incident response and can cause operators to misconfigure the wrong field.

**Fix:** Derive the message from `method_type` instead of hardcoding:

```elixir
defp enforce_legacy_override(
       %{reason: reason, expires_at: %DateTime{} = expires_at},
       method,
       method_type
     )
     when is_binary(reason) and byte_size(reason) > 0 do
  case DateTime.compare(expires_at, DateTime.utc_now()) do
    :gt ->
      :ok

    _ ->
      label =
        case method_type do
          :content_encryption_algorithm -> "AES-CBC"
          _ -> "SHA-1"
        end

      Error.new(
        :legacy_algorithm_override_expired,
        "Legacy #{label} override has expired",
        %{
          algorithm: method,
          algorithm_type: method_type,
          reason: reason,
          expires_at: expires_at
        }
      )
  end
end
```

---

### CR-02: `party` and `use` columns are `NOT NULL` in the migration but have no `validate_required` in the changeset — explicit `nil` bypasses Ecto validation and hits a raw DB constraint

**File:** `lib/relyra/ecto/certificate.ex:61`, `priv/repo/migrations/20260525100000_add_party_and_use_to_relyra_connection_certificates.exs:6-7`

**Issue:** The migration correctly enforces `null: false, default: "idp"` / `default: "signing"` at the database level. However the `Certificate.changeset/2` does not include `:party` or `:use` in `validate_required/2`, and `put_defaults/1` does not supply Elixir-side defaults for these fields.

The DB default handles the common path (row inserted without those columns provided). But `cast/4` will cast an explicitly provided `nil` value — `Certificate.changeset(cert, %{party: nil})` — and `Ecto.Enum` does not reject `nil` without `validate_required`. That changeset will pass `changeset.valid?` as `true` and produce a raw `Postgrex.Error` / `not-null constraint` at insert time rather than a clean `{:error, changeset}` with a readable validation error.

Additionally, there is no schema-level `default:` on either field (unlike `:role` and `:lifecycle_state` which have both schema defaults and `put_change_unless_present` guards in `put_defaults`). New in-memory `%Certificate{}` structs will have `party: nil` and `use: nil`, which is inconsistent with the "default is `:idp`/`:signing`" contract implied by the migration.

**Fix — two-part:**

1. Add schema-level defaults consistent with the migration:

```elixir
field :party, Ecto.Enum, values: [:idp, :sp], default: :idp
field :use,   Ecto.Enum, values: [:signing, :encryption], default: :signing
```

2. Add `put_change_unless_present` guards in `put_defaults/1` (mirroring the `:role` pattern):

```elixir
defp put_defaults(changeset) do
  changeset
  |> put_change_unless_present(:role, :signing)
  |> put_change_unless_present(:lifecycle_state, :active)
  |> put_change_unless_present(:party, :idp)
  |> put_change_unless_present(:use, :signing)
  |> put_default_timestamp(:activated_at, :lifecycle_state, :active)
  |> put_default_timestamp(:staged_at, :lifecycle_state, :next)
  |> clear_timestamp_when_not_state(:staged_at, :lifecycle_state, :next)
  |> clear_timestamp_when_not_state(:activated_at, :lifecycle_state, :active)
  |> clear_timestamp_when_not_state(:retired_at, :lifecycle_state, :retired)
end
```

No `validate_required` is strictly needed once schema defaults and `put_change_unless_present` cover the `nil` case, because the `Ecto.Enum` cast will then reject unknown values at the type level.

---

## Warnings

### WR-01: Auth-tag guard silently passes non-binary `auth_tag` values, making the guard bypassable by type error

**File:** `lib/relyra/security/algorithm_policy.ex:169-175`

**Issue:** The auth-tag guard at line 174 is `is_binary(auth_tag) and byte_size(auth_tag) < 16`. If `auth_tag` is non-binary (e.g., an integer `15`, a list, or an atom), `is_binary/1` returns `false` and the guard is silently skipped — the function proceeds to the allowlist check and may return `:ok` for AES-GCM. This is not a problem today because no caller in `lib/` currently invokes this function, but it means the guard's protection depends entirely on caller discipline with no enforcement at the boundary.

The `@spec` permits `keyword()` opts without constraining the `auth_tag` value type. If a future caller wraps a length integer instead of the raw bytes, the guard will not fire.

**Fix:** Add an explicit clause that returns `:decryption_failed` when `auth_tag` is present but not a binary:

```elixir
auth_tag = Keyword.get(opts, :auth_tag)

cond do
  # Explicit non-binary auth_tag is as dangerous as a truncated one
  Keyword.has_key?(opts, :auth_tag) and not is_binary(auth_tag) ->
    :decryption_failed

  is_binary(auth_tag) and byte_size(auth_tag) < 16 ->
    :decryption_failed

  ...
end
```

Alternatively, document and test the non-binary case explicitly so the contract is pinned.

---

### WR-02: `@active_signing_cert_filters` in `Connection` does not filter on `party: :idp` — SP certificates (introduced by the new `party` field) will satisfy the runtime-ready check

**File:** `lib/relyra/ecto/connection.ex:82`

**Issue:** `@active_signing_cert_filters` is `[role: :signing, lifecycle_state: :active]`. After Phase 32 adds a `party` field distinguishing IdP versus SP certificates, the filter still accepts any `:active` `:signing` certificate regardless of party. If an SP signing certificate (e.g., for outbound AuthnRequest signing, `party: :sp`) is loaded into `connection.certificates`, `runtime_ready/1` and `validate_runtime_ready/1` will count it as a valid IdP signing certificate and approve the connection even if no IdP certificates are present.

This is a latent correctness defect: the semantic meaning of the new field is not yet reflected in the existing validation logic. It will become a real bug as soon as callers start populating `party: :sp` certificates.

**Fix:** Add `party: :idp` to the filter:

```elixir
@active_signing_cert_filters [role: :signing, lifecycle_state: :active, party: :idp]
```

Note: the filter function uses `Map.get(certificate, field, value) == value`. Because `party` now has a schema default of `:idp` (per CR-02 fix), this will work correctly for legacy certificates where `party` was not yet set: `Map.get(cert, :party, :idp)` returns `:idp` for both nil-party certs (via the fallback) and explicit `:idp` party certs.

---

### WR-03: `enforce_content_encryption_algorithm/3` allows AES-CBC with a valid-sized auth_tag when the legacy hatch is active — no test pins this behaviour

**File:** `lib/relyra/security/algorithm_policy.ex:168-187`, `test/relyra/security/algorithm_policy_test.exs`

**Issue:** The auth-tag guard fires only for `byte_size < 16`. A 16-byte `auth_tag` passes the guard (16 is not less than 16), falls through to the AES-CBC hatch check, and returns `:ok` when the hatch is active. AES-CBC has no authentication tag — a caller constructing an AES-CBC decryption context would never legitimately provide `auth_tag`. If a caller does provide `auth_tag: <<16 bytes>>` with `method = @aes128_cbc_uri` and the hatch is active, the result is `:ok`, which could mislead the caller into thinking the auth tag was validated when no such validation occurred.

The test suite covers `auth_tag < 16 bytes` + AES-CBC (auth guard fires first; correct), but has no test for `auth_tag = exactly 16 bytes` + AES-CBC + active hatch, which returns `:ok` — the surprising combination.

**Fix:** Add a test that documents the current behaviour explicitly so any future change is caught:

```elixir
test "AES-CBC with exactly-16-byte auth_tag and active hatch returns :ok (tag not validated)" do
  policy = %{
    AlgorithmPolicy.default()
    | legacy_aes_cbc: %{
        reason: "Legacy IdP compatibility",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }
  }

  # Documents that CBC has no auth tag; the 16-byte tag passes the guard
  # but is not cryptographically verified. Caller must not rely on :ok as tag-verified.
  assert :ok =
           AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_cbc_uri,
             auth_tag: :binary.copy(<<0>>, 16)
           )
end
```

---

## Info

### IN-01: `enforce_legacy_override` parameter is named `_legacy_sha1` in the fallback clause even when used for AES-CBC

**File:** `lib/relyra/security/algorithm_policy.ex:233`

**Issue:** The catch-all `enforce_legacy_override(_legacy_sha1, method, method_type)` clause uses a SHA-1-named parameter for what is now a general-purpose "legacy override struct absent or malformed" handler. This is purely a naming issue that will cause reader confusion when reasoning about the AES-CBC path.

**Fix:**

```elixir
defp enforce_legacy_override(_legacy_override, method, method_type) do
  deprecated_algorithm(method, method_type)
end
```

---

### IN-02: AES-256-CBC is not covered by the legacy hatch active test — only AES-128-CBC is tested with an active `legacy_aes_cbc` override

**File:** `test/relyra/security/algorithm_policy_test.exs:163-173`

**Issue:** Both `@aes128_cbc_uri` and `@aes256_cbc_uri` are in `@aes_cbc_uris` and will take the same code path when the hatch is active. The test at line 163 covers AES-128-CBC with an active hatch but not AES-256-CBC. This leaves the AES-256-CBC hatch path untested for the `:ok` case, and the expired-hatch test at line 175 also only uses AES-128-CBC.

**Fix:** Add AES-256-CBC variants of the hatch-active and hatch-expired tests:

```elixir
test "AES-256-CBC is allowed when legacy_aes_cbc hatch is active and not expired" do
  policy = %{
    AlgorithmPolicy.default()
    | legacy_aes_cbc: %{
        reason: "Legacy IdP compatibility",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }
  }
  assert :ok = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes256_cbc_uri)
end
```

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
