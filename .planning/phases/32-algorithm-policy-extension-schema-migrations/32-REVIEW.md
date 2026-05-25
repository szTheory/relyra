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
  critical: 1
  warning: 4
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

This phase adds `party`/`use` to `relyra_connection_certificates` and `sign_authn_requests` to `relyra_connections`, extends `AlgorithmPolicy` with key-transport and content-encryption enforcement including an AES-CBC legacy hatch, and supplies test coverage for the new enforcement functions. The PKCS1v1.5 permanent block, auth-tag guard ordering, and SHA-1 hatch logic are structurally sound. The test suite matches on `:type` only, which masks one critical defect: an error message that is hardcoded to say "Legacy SHA-1" even when it fires for an expired AES-CBC override. Four warnings cover a missing Elixir-level default for the two new `NOT NULL` certificate columns (latent raw constraint failure on explicit-nil inserts), a `sign_authn_requests` field that is persisted but never read at runtime (silent no-op), a `@active_signing_cert_filters` list that does not filter on the new `party` field (SP certificates count as IdP signing certs), and dead public API (`validate_method/3`, `validate_digest/3`).

---

## Critical Issues

### CR-01: Stale error message "Legacy SHA-1 override has expired" fires for AES-CBC expired hatches

**File:** `lib/relyra/security/algorithm_policy.ex:222`

**Issue:** `enforce_legacy_override/3` is a shared private function called by both the SHA-1 path (`enforce_sha1_policy/4`) and the new AES-CBC path (`enforce_content_encryption_algorithm/3`). The expired-override `Error.new/3` call at line 221-229 hardcodes the human-readable message as `"Legacy SHA-1 override has expired"` regardless of the `method_type` argument, which is already threaded through. When an operator's `legacy_aes_cbc` window expires, the error type is correctly `:legacy_algorithm_override_expired` and `algorithm_type` is correctly `:content_encryption_algorithm`, but the message string says SHA-1. Operators triaging an AES-CBC decryption failure read the message first and will be directed to configure the wrong field.

Tests match only on `:type`, so this defect is invisible to the test suite.

**Fix:** Derive the message label from `method_type`:

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

## Warnings

### WR-01: `party` and `use` have no Elixir-side defaults — explicit `nil` bypasses `Ecto.Enum` cast and produces a raw DB constraint error

**File:** `lib/relyra/ecto/certificate.ex:29-30, 61, 70-79`

**Issue:** The migration sets `null: false, default: "idp"` / `null: false, default: "signing"` at the database level. The Ecto schema declares `party` and `use` with no `default:` option and `put_defaults/1` never touches them. `cast/4` will accept an explicitly supplied `nil` for either field — `Certificate.changeset(cert, %{party: nil})` — and `Ecto.Enum` does not reject `nil` without `validate_required`. That changeset reports `changeset.valid? == true` and then produces a raw `Postgrex.Error` (not-null constraint) at insert time instead of a clean `{:error, changeset}` with a readable message.

Compare: `:role` has `default: :signing` on the `field` declaration plus `put_change_unless_present(:role, :signing)` in `put_defaults/1`. The new fields follow neither pattern.

Additionally, an in-memory `%Certificate{}` built without a changeset will have `party: nil` and `use: nil`, which is inconsistent with the "default is `:idp`/`:signing`" contract.

**Fix:**

```elixir
# schema block
field :party, Ecto.Enum, values: [:idp, :sp], default: :idp
field :use,   Ecto.Enum, values: [:signing, :encryption], default: :signing

# put_defaults/1
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

### WR-02: `@active_signing_cert_filters` does not filter on `party: :idp` — SP certificates now count toward the IdP signing cert check

**File:** `lib/relyra/ecto/connection.ex:82`

**Issue:** `@active_signing_cert_filters` is `[role: :signing, lifecycle_state: :active]`. Phase 32 adds a `party` field distinguishing IdP vs SP certificates. The `runtime_ready/1` check (line 176) and `validate_runtime_ready/1` (line 259) both call `active_signing_certificates/1`, which filters on `@active_signing_cert_filters`. After this phase, an SP signing certificate (`party: :sp`, intended for outbound AuthnRequest signing) will satisfy the filter and be counted as an IdP signing cert. If only SP certificates are loaded, the connection passes the runtime-ready check with no IdP verification certificate, which breaks the security invariant that every SAML response must be verifiable against a configured IdP cert.

The filter helper uses `Map.get(certificate, field, value)` with the value as the fallback default, so once a `party: :idp` default is added (per WR-01), legacy certificates without a `party` field will correctly fall through as `:idp` — no migration of old rows is needed.

**Fix:**

```elixir
@active_signing_cert_filters [role: :signing, lifecycle_state: :active, party: :idp]
```

### WR-03: `sign_authn_requests` is persisted and cast but never read — the feature is a silent no-op

**File:** `lib/relyra/ecto/connection.ex:40, 98, 125`, `priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs`

**Issue:** `sign_authn_requests` is defined as a schema field and included in both `draft_changeset/2` and `update_changeset/2`, but:

1. `connection_snapshot.ex:base_runtime_attrs/1` (lines 69-88) does not project it into the runtime attrs map.
2. `Relyra.Connection` (the runtime value struct) has no `sign_authn_requests` field.
3. `Relyra.Protocol.AuthnRequest.build/3` does not check it.

A caller that sets `sign_authn_requests: true` expecting the SP to sign its AuthnRequests will observe no signing — the flag is accepted and stored, but the SP ignores it. There is no dead-code warning because the field is read by Ecto; the gap is in the runtime path.

**Fix:** Either wire the field through `connection_snapshot.ex` → `Relyra.Connection` → `AuthnRequest.build/3` to make the feature functional, or add a prominent `# stub — not yet wired` comment to the field and an explanatory comment in `base_runtime_attrs/1` so the gap is visible and searchable.

### WR-04: `validate_method/3` and `validate_digest/3` are dead public API wrapping the already-public `enforce_*` functions

**File:** `lib/relyra/security/algorithm_policy.ex:88-101`

**Issue:** `validate_method/3` and `validate_digest/3` are `@spec`-annotated public functions. They exist solely to wrap `enforce_signature_method/2` and `enforce_digest_method/2`, translating the raw `Error.t()` return into `{:error, Error.t()}`. No caller in `lib/` or `test/` uses them — `signature.ex` calls the `enforce_*` forms directly. Both also carry an ignored `_opts \\ []` parameter hinting at an unfinished design. Dead public functions in a security module widen the API surface, create ambiguity about which calling convention is canonical, and will generate Dialyzer/`unused function` noise.

**Fix:** Remove `validate_method/3` and `validate_digest/3` unless they are intended as part of a future public API; if so, document them and supply callers or tests.

---

## Info

### IN-01: `enforce_legacy_override` fallback clause parameter is named `_legacy_sha1` even for AES-CBC paths

**File:** `lib/relyra/security/algorithm_policy.ex:233`

**Issue:** The catch-all clause `defp enforce_legacy_override(_legacy_sha1, method, method_type)` carries a SHA-1-specific name for what is now a general-purpose "legacy override absent or malformed" handler covering both SHA-1 and AES-CBC contexts. This is a naming inconsistency that will cause reader confusion.

**Fix:**

```elixir
defp enforce_legacy_override(_legacy_override, method, method_type) do
  deprecated_algorithm(method, method_type)
end
```

### IN-02: `deprecated_algorithm/2` details map carries stale `policy: :sha256_plus_default` label for encryption rejections

**File:** `lib/relyra/security/algorithm_policy.ex:244`

**Issue:** The `deprecated_algorithm/2` helper emits `policy: :sha256_plus_default` in its error details map. This label was accurate when only signature and digest methods were enforced, but the same function now fires for key-transport and content-encryption rejections, where `:sha256_plus_default` is semantically wrong. The `algorithm_type:` field (already present and correct) is sufficient to discriminate; the stale `policy:` label adds noise and potential confusion.

**Fix:** Remove the `policy:` key from `deprecated_algorithm/2`'s details map, or replace it with a generic label such as `policy: :strict_default`.

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
