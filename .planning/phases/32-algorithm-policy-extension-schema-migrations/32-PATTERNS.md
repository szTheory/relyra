# Phase 32: AlgorithmPolicy Extension + Schema Migrations - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 7 (3 modified source files + 2 new migrations + 2 extended test files)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/security/algorithm_policy.ex` | utility/policy | transform | `lib/relyra/security/algorithm_policy.ex` (existing sections) | exact — in-place extension |
| `lib/relyra/ecto/certificate.ex` | model | CRUD | `lib/relyra/ecto/certificate.ex` (existing `role`/`lifecycle_state` fields) | exact — field addition only |
| `lib/relyra/ecto/connection.ex` | model | CRUD | `lib/relyra/ecto/connection.ex` (existing `allow_idp_initiated` field + `draft_changeset`/`update_changeset`) | exact — field addition only |
| `priv/repo/migrations/20260525XXXXXX_add_party_and_use_to_relyra_connection_certificates.exs` | migration | batch | `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs` | exact — up/down + execute UPDATE template |
| `priv/repo/migrations/20260525YYYYYY_add_sign_authn_requests_to_relyra_connections.exs` | migration | batch | `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` | exact — change + boolean default template |
| `test/relyra/security/algorithm_policy_test.exs` | test | request-response | `test/relyra/security/algorithm_policy_test.exs` (existing `describe` blocks) | exact — extend with new describe blocks |
| `test/security/strict_default_proof_test.exs` | test | request-response | `test/security/strict_default_proof_test.exs` (existing proof tests) | exact — extend with new enforce function proofs |

---

## Pattern Assignments

### `lib/relyra/security/algorithm_policy.ex` (utility/policy, transform)

**Analog:** `lib/relyra/security/algorithm_policy.ex` — extend in-place. Read the full file before adding anything.

**Struct definition pattern** (lines 16-27 — extend here):
```elixir
defstruct [:allowed_signature_methods, :allowed_digest_methods, :legacy_sha1]

@type legacy_sha1_override :: %{
        reason: String.t(),
        expires_at: DateTime.t()
      }

@type t :: %__MODULE__{
        allowed_signature_methods: [String.t()],
        allowed_digest_methods: [String.t()],
        legacy_sha1: legacy_sha1_override() | nil
      }
```
Add `:allowed_key_transport_algorithms`, `:allowed_content_encryption_algorithms`, and `:legacy_aes_cbc` to `defstruct` in parallel with the existing three fields. Add a `@type legacy_aes_cbc_override` identical in shape to `legacy_sha1_override`. Extend `@type t` with the three new fields.

**`default/0` pattern** (lines 30-47 — extend here):
```elixir
@spec default() :: t()
def default do
  %__MODULE__{
    allowed_signature_methods: [...],
    allowed_digest_methods: [...],
    legacy_sha1: nil
  }
end
```
Add `allowed_key_transport_algorithms`, `allowed_content_encryption_algorithms`, and `legacy_aes_cbc: nil` to the `default/0` struct literal. Allowed URIs per RESEARCH.md Pitfall 2: key transport allows `"http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"`; content encryption allows `"http://www.w3.org/2001/04/xmlenc#aes128-gcm"` and `"http://www.w3.org/2001/04/xmlenc#aes256-gcm"`. Both AES-CBC URIs are NOT in the default allowlist. Failing to populate these causes `method_allowed?/2` to raise `FunctionClauseError` (its guard is `is_list(allowed_methods)` at line 120).

**SHA-1 MapSet module attributes pattern** (lines 6-14 — copy structure for AES-CBC):
```elixir
@sha1_signature_methods MapSet.new([
                          "http://www.w3.org/2000/09/xmldsig#rsa-sha1",
                          "http://www.w3.org/2001/04/xmldsig-more#rsa-sha1"
                        ])

@sha1_digest_methods MapSet.new([
                       "http://www.w3.org/2000/09/xmldsig#sha1",
                       "http://www.w3.org/2001/04/xmlenc#sha1"
                     ])
```
Add a `@aes_cbc_uris` module attribute as a `MapSet.new([...])` with both AES-CBC URIs. Place it alongside the existing `@sha1_*` module attributes at the top of the module.

**ECDSA hard-reject pattern** (lines 88-99 — copy structure for PKCS1v1.5 hard-reject):
```elixir
def digest_atom_for_signature_method(uri) when is_binary(uri) do
  cond do
    # D-07: any ECDSA URI fails CLOSED, checked BEFORE the rsa-sha* suffix match
    String.contains?(uri, "ecdsa") -> {:error, :unsupported_signature_algorithm}
    ...
  end
end
```
For `enforce_key_transport_algorithm/2`, use a pattern-matched function head instead of a `cond` (the RESEARCH.md example shows a cleaner match). The RSA-PKCS1v1.5 URI is a constant string, so a module attribute `@rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"` and a matched clause `def enforce_key_transport_algorithm(_policy, @rsa_pkcs1_uri)` is the idiomatic Elixir approach. Hard-reject fires BEFORE allowlist — no escape hatch, no `legacy_aes_cbc` check.

**`enforce_signature_method/2` / `enforce_digest_method/2` return-type pattern** (lines 101-117 — copy structure for both new enforce functions):
```elixir
@spec enforce_signature_method(t(), term()) :: :ok | Error.t()
def enforce_signature_method(policy, method) do
  if method_allowed?(policy.allowed_signature_methods, method) do
    :ok
  else
    enforce_sha1_policy(policy.legacy_sha1, method, :signature_method, @sha1_signature_methods)
  end
end

@spec enforce_digest_method(t(), term()) :: :ok | Error.t()
def enforce_digest_method(policy, method) do
  if method_allowed?(policy.allowed_digest_methods, method) do
    :ok
  else
    enforce_sha1_policy(policy.legacy_sha1, method, :digest_method, @sha1_digest_methods)
  end
end
```
`enforce_key_transport_algorithm/2` mirrors `enforce_signature_method/2`: spec is `:ok | Error.t()`, uses `method_allowed?/2` for the allowlist check, calls `deprecated_algorithm/2` for unknown URIs. `enforce_content_encryption_algorithm/3` (with `opts \\ []`) is shaped differently due to the auth tag guard — see `enforce_legacy_override/3` pattern below.

**`enforce_legacy_override/3` pattern** (lines 139-165 — reuse directly for AES-CBC hatch):
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
      Error.new(
        :legacy_algorithm_override_expired,
        "Legacy SHA-1 override has expired",
        %{
          algorithm: method,
          algorithm_type: method_type,
          reason: reason,
          expires_at: expires_at
        }
      )
  end
end

defp enforce_legacy_override(_legacy_sha1, method, method_type) do
  deprecated_algorithm(method, method_type)
end
```
Call `enforce_legacy_override(policy.legacy_aes_cbc, method, :content_encryption_algorithm)` from inside `enforce_content_encryption_algorithm/3` when `MapSet.member?(@aes_cbc_uris, method)` is true. The private function is already written — do not duplicate it.

**`deprecated_algorithm/2` pattern** (lines 167-177 — reuse directly):
```elixir
defp deprecated_algorithm(method, method_type) do
  Error.new(
    :deprecated_algorithm,
    "Algorithm is not allowed by strict policy",
    %{
      algorithm: method,
      algorithm_type: method_type,
      policy: :sha256_plus_default
    }
  )
end
```
Both new enforce functions call `deprecated_algorithm/2` for unrecognized URIs. No duplication needed — private helper is already present.

**`method_allowed?/2` pattern** (lines 119-124 — reuse directly):
```elixir
defp method_allowed?(allowed_methods, method)
     when is_binary(method) and is_list(allowed_methods) do
  Enum.member?(allowed_methods, method)
end

defp method_allowed?(_allowed_methods, _method), do: false
```
Pass `policy.allowed_key_transport_algorithms` and `policy.allowed_content_encryption_algorithms` directly to this existing private function.

---

### `lib/relyra/ecto/certificate.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/certificate.ex` — lines 1-122. Add two fields to the existing `schema` block and to the `changeset/2` cast list.

**Ecto.Enum field pattern** (lines 21-22 — copy for `party` and `use`):
```elixir
field :role, Ecto.Enum, values: @roles, default: :signing
field :lifecycle_state, Ecto.Enum, values: @lifecycle_states, default: :active
```
New fields follow the same form. Unlike `:role`, the new fields have no compile-time module-attribute constants (values are short enough to inline):
```elixir
field :party, Ecto.Enum, values: [:idp, :sp]
field :use,   Ecto.Enum, values: [:signing, :encryption]
```
Place after `:metadata` (line 28) and before `belongs_to :connection`. No `default:` needed — DB column default handles existing rows; the `Ecto.Enum` field itself will return `nil` for rows loaded before the migration runs (safe during deploy).

**`changeset/2` cast list pattern** (lines 42-56 — add `:party` and `:use` here):
```elixir
|> cast(attrs, [
  :connection_record_id,
  :fingerprint_sha256,
  :pem,
  :source,
  :role,
  :lifecycle_state,
  ...
])
```
Add `:party` and `:use` to the cast list. They do not need `validate_required` — the DB default covers new certs and existing rows get defaults from the migration backfill.

---

### `lib/relyra/ecto/connection.ex` (model, CRUD)

**Analog:** `lib/relyra/ecto/connection.ex` — lines 1-317. Add one field to the schema block and to both `draft_changeset/2` and `update_changeset/2`.

**Boolean field pattern** (line 39 — copy for `sign_authn_requests`):
```elixir
field :allow_idp_initiated, :boolean, default: false
```
New field follows the identical form. Place immediately after `allow_idp_initiated` (line 39):
```elixir
field :sign_authn_requests, :boolean, default: false
```

**`draft_changeset/2` cast list pattern** (lines 86-99 — add `:sign_authn_requests`):
```elixir
|> cast(attrs, [
  :connection_id,
  :display_name,
  :organization_id,
  :status,
  :provider_preset,
  :sp_entity_id,
  :acs_url,
  :idp_entity_id,
  :idp_sso_url,
  :allow_idp_initiated,
  :active_metadata_revision_id,
  :last_known_good_metadata_revision_id
])
```
Add `:sign_authn_requests` to the cast list alongside `:allow_idp_initiated`.

**`update_changeset/2` cast list pattern** (lines 112-125 — add `:sign_authn_requests`):
```elixir
|> cast(attrs, [
  :display_name,
  :organization_id,
  :status,
  :provider_preset,
  :sp_entity_id,
  :acs_url,
  :idp_entity_id,
  :idp_sso_url,
  :allow_idp_initiated,
  :active_metadata_revision_id,
  :last_known_good_metadata_revision_id
])
```
`allow_idp_initiated` is in `update_changeset` — `sign_authn_requests` must be too. Phase 35 needs to update this field on existing connections.

---

### `priv/repo/migrations/20260525XXXXXX_add_party_and_use_to_relyra_connection_certificates.exs` (migration, batch)

**Analog:** `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`

**Full migration template** (lines 1-29 — copy structure exactly):
```elixir
defmodule Relyra.Repo.Migrations.AddCertificateLifecycleToRelyraConnectionCertificates do
  use Ecto.Migration

  def up do
    alter table(:relyra_connection_certificates) do
      add :role, :string, null: false, default: "signing"
      add :lifecycle_state, :string, null: false, default: "active"
      add :staged_at, :utc_datetime_usec
      add :activated_at, :utc_datetime_usec
      add :retired_at, :utc_datetime_usec
    end

    execute("""
    UPDATE relyra_connection_certificates
    SET activated_at = COALESCE(activated_at, inserted_at)
    WHERE lifecycle_state = 'active'
    """)
  end

  def down do
    alter table(:relyra_connection_certificates) do
      remove :retired_at
      remove :activated_at
      remove :staged_at
      remove :lifecycle_state
      remove :role
    end
  end
end
```
For Phase 32 cert migration: use `up/down` (not `change`). In `up`, add `:party` and `:use` with `null: false, default: "idp"` and `null: false, default: "signing"` respectively in a single `alter` block. Postgres applies the `DEFAULT` value to all existing rows atomically when `ADD COLUMN DEFAULT 'x' NOT NULL` is issued — no intermediate `execute UPDATE` is required unless you need a custom backfill value (the defaults are safe). The `execute` in the analog was for a timestamp field needing a derived value, not a static default.

In `down`, remove `:use` then `:party` (reverse order of add).

**Key nuance:** The CONTEXT.md description mentions "add nullable → UPDATE → alter NOT NULL" as a belt-and-suspenders pattern. The actual canonical template adds `null: false, default:` in a single alter step. Follow the template code, not the description. Postgres handles it atomically.

**Migration timestamp:** Use timestamps after `20260507000001`. Two Phase 32 migrations need distinct timestamps, e.g., `20260525100000` and `20260525100001`.

---

### `priv/repo/migrations/20260525YYYYYY_add_sign_authn_requests_to_relyra_connections.exs` (migration, batch)

**Analog:** `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`

**Full migration template** (lines 1-9 — copy structure exactly):
```elixir
defmodule Relyra.Repo.Migrations.AddAllowIdpInitiatedToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :allow_idp_initiated, :boolean, default: false, null: false
    end
  end
end
```
For Phase 32 connection migration: `change` is correct (the `alter` is fully reversible — Ecto knows to `remove` the column on rollback). Module name becomes `Relyra.Repo.Migrations.AddSignAuthnRequestsToRelyraConnections`. Column: `add :sign_authn_requests, :boolean, default: false, null: false`. Postgres `DEFAULT false` covers all existing rows atomically; no `up/down` or `execute UPDATE` needed.

---

### `test/relyra/security/algorithm_policy_test.exs` (test, request-response)

**Analog:** `test/relyra/security/algorithm_policy_test.exs` — lines 1-82. Extend with new `describe` blocks.

**Module setup and URI attribute pattern** (lines 1-19):
```elixir
defmodule Relyra.Security.AlgorithmPolicyTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.AlgorithmPolicy

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  ...
end
```
Add module attributes for the URIs used in new tests: `@rsa_pkcs1_uri`, `@rsa_oaep_uri`, `@aes128_gcm_uri`, `@aes256_gcm_uri`, `@aes128_cbc_uri`, `@aes256_cbc_uri`.

**`describe` block structure** (lines 21-33 — copy for each new function):
```elixir
describe "enforce_key_transport_algorithm/2 (PKCS1v1.5 hard-reject)" do
  test "RSA-PKCS1v1.5 URI is hard-rejected regardless of policy" do
    policy = AlgorithmPolicy.default()
    result = AlgorithmPolicy.enforce_key_transport_algorithm(policy, @rsa_pkcs1_uri)
    assert %Relyra.Error{type: :deprecated_algorithm} = result
  end
  ...
end
```

**Existing `enforce_*` test style for reference** — use `AlgorithmPolicy.default()` to get the policy struct, call the function, assert on the return value shape. New tests should cover: PKCS1v1.5 hard-reject, RSA-OAEP allowed by default, unknown key transport URI rejected, AES-GCM allowed by default, AES-CBC rejected by default, AES-CBC allowed when `legacy_aes_cbc` hatch active and not expired, AES-CBC rejected when `legacy_aes_cbc` hatch expired, auth tag < 16 bytes returns `:decryption_failed`.

---

### `test/security/strict_default_proof_test.exs` (test, request-response)

**Analog:** `test/security/strict_default_proof_test.exs` — lines 1-64. Extend with proofs for the two new enforce functions.

**Proof test structure** (lines 12-20 — copy pattern):
```elixir
test "deprecated_algorithm stays fail-closed for SHA-1 by default" do
  policy = AlgorithmPolicy.default()

  assert %Error{type: :deprecated_algorithm} =
           AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

  assert %Error{type: :deprecated_algorithm} =
           AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
end
```
Add two proof tests following the same pattern:
1. `"enforce_key_transport_algorithm/2 hard-rejects PKCS1v1.5 by default"` — calls `enforce_key_transport_algorithm(policy, @rsa_pkcs1_uri)`, asserts `%Error{type: :deprecated_algorithm}`.
2. `"enforce_content_encryption_algorithm/3 rejects AES-CBC by default"` — calls `enforce_content_encryption_algorithm(policy, @aes128_cbc_uri)`, asserts `%Error{type: :deprecated_algorithm}`.

These two proofs are security-relevant (ENC-03) and belong in `strict_default_proof_test.exs` because it is already in `mix ci.security` and runs as its own `cmd mix test` subprocess.

---

## Shared Patterns

### Error struct construction
**Source:** `lib/relyra/security/algorithm_policy.ex`, lines 167-177
**Apply to:** `enforce_key_transport_algorithm/2`, `enforce_content_encryption_algorithm/3`
```elixir
alias Relyra.Error  # already at line 4

defp deprecated_algorithm(method, method_type) do
  Error.new(
    :deprecated_algorithm,
    "Algorithm is not allowed by strict policy",
    %{
      algorithm: method,
      algorithm_type: method_type,
      policy: :sha256_plus_default
    }
  )
end
```
The `deprecated_algorithm/2` private function is already in `algorithm_policy.ex`. Both new enforce functions call it rather than constructing `Error.new(...)` inline.

### Ecto.Enum field declaration (no native Postgres enum)
**Source:** `lib/relyra/ecto/certificate.ex`, lines 21-22
**Apply to:** `certificate.ex` new `party` and `use` fields
```elixir
field :role, Ecto.Enum, values: @roles, default: :signing
field :lifecycle_state, Ecto.Enum, values: @lifecycle_states, default: :active
```
All enum-like columns in this project use `:string` as the DB type and `Ecto.Enum` as the Ecto schema type. Never use `execute "CREATE TYPE ..."` or `EctoEnum.defenum`. No Postgres native enum.

### Migration column addition with default (null: false)
**Source:** `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`, lines 5-11
**Apply to:** cert migration `up/0`
```elixir
alter table(:relyra_connection_certificates) do
  add :role, :string, null: false, default: "signing"
  add :lifecycle_state, :string, null: false, default: "active"
end
```
Postgres applies `DEFAULT` atomically for all existing rows when `ADD COLUMN DEFAULT 'x' NOT NULL` is a single statement. No intermediate `execute UPDATE` is needed when the default value is static (not derived).

### `Ecto.Migration` `if Code.ensure_loaded?` guard
**Source:** `lib/relyra/ecto/certificate.ex`, lines 1 and 118-122; `lib/relyra/ecto/connection.ex`, lines 1 and 313-317
**Apply to:** Schema files only (not migrations)
```elixir
if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.Certificate do
    ...
  end
else
  defmodule Relyra.Ecto.Certificate do
    @moduledoc false
  end
end
```
All Ecto schema files are wrapped in `if Code.ensure_loaded?(Ecto.Schema)`. This pattern must be preserved when modifying `certificate.ex` and `connection.ex`.

### `ci.security` hollow-gate constraint
**Source:** `mix.exs` `ci.security` alias
**Apply to:** Any test additions that are security-relevant
All security suite entries use `"cmd mix test path/to/test.exs --warnings-as-errors"` as separate OS processes — never bare `"test path/to/test.exs"` steps. The `strict_default_proof_test.exs` is already a `cmd mix test` entry. Do not add new bare `test` steps for security tests.

---

## No Analog Found

None — all Phase 32 files have exact or near-exact analogs in the codebase.

---

## Metadata

**Analog search scope:** `lib/relyra/security/`, `lib/relyra/ecto/`, `priv/repo/migrations/`, `test/relyra/security/`, `test/security/`
**Files scanned:** 10 source files read directly
**Pattern extraction date:** 2026-05-25

**Migration timestamp range for Phase 32:** After `20260507000001`. Suggested: `20260525100000` (cert) and `20260525100001` (connection).
