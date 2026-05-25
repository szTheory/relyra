# Phase 32: AlgorithmPolicy Extension + Schema Migrations - Research

**Researched:** 2026-05-25
**Domain:** Elixir/Ecto — AlgorithmPolicy extension, Ecto schema fields, Postgres migrations
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** New enforcement functions use the bare `:ok | Error.t()` return form — matching
`enforce_signature_method/2` and `enforce_digest_method/2` at `algorithm_policy.ex:101-116`
— not wrapped `{:ok, _} | {:error, _}`. Public API:
`enforce_key_transport_algorithm/2` and `enforce_content_encryption_algorithm/2`.

**D-02:** The `AlgorithmPolicy` struct gains two new allowlist fields (`key_transport` and
`content_encryption`) in parallel with the existing `allowed_signature_methods` and
`allowed_digest_methods` fields, plus one new escape hatch field (`legacy_aes_cbc`) mirroring
the exact `%{reason: String.t(), expires_at: DateTime.t()}` type of `legacy_sha1`.

**D-03:** AES-GCM auth tag length guard is implemented inside `enforce_content_encryption_algorithm/2`:
if the decryption path provides an auth tag shorter than 16 bytes, return `:decryption_failed`
immediately without calling `:crypto.crypto_one_time_aead/7`. This guard is a distinct
code path from the algorithm allowlist check and fires first.

**D-04:** RSA-PKCS1v1.5 key transport (`http://www.w3.org/2001/04/xmlenc#rsa-1_5`) is
hard-rejected via a URI blocklist pattern — structurally identical to the ECDSA hard-reject
at `algorithm_policy.ex:88-99` (string match before allowlist lookup). No escape hatch
field is added for PKCS1v1.5.

**D-05:** AES-CBC (`http://www.w3.org/2001/04/xmlenc#aes128-cbc`,
`http://www.w3.org/2001/04/xmlenc#aes256-cbc`) is rejected by default but has a `legacy_aes_cbc`
escape hatch using the identical struct pattern to `legacy_sha1`. Activating the hatch requires
the same `reason: String.t(), expires_at: DateTime.t()` fields.

**D-06:** Certificate migration uses explicit `up/down` (not `change`) because adding `null: false`
columns to a table with existing rows requires a row backfill before the constraint fires.
Pattern: add column with DB default → `execute("UPDATE ...")` → modify column to `null: false`.
Follows `20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`.

**D-07:** Both cert columns stored as `:string` in the database — consistent with all existing
enum-like columns.

**D-08:** DB defaults: `party = "idp"`, `use = "signing"`. All existing certificate rows
receive these safe defaults.

**D-09:** Ecto `Certificate` schema gains:
- `field :party, Ecto.Enum, values: [:idp, :sp]`
- `field :use, Ecto.Enum, values: [:signing, :encryption]`

**D-10:** `sign_authn_requests` migration uses `change` — `add :sign_authn_requests, :boolean, default: false, null: false` — identical structure to `20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`.

**D-11:** `sign_authn_requests` is a top-level field on the `Connection` Ecto schema — not
inside the `RuntimePolicy` embedded schema — consistent with `allow_idp_initiated` placement at
`connection.ex:39`. Added to `draft_changeset` cast list alongside `allow_idp_initiated`.

### Claude's Discretion

- Exact migration timestamp filenames (follow project convention: UTC timestamp prefix).
- Whether `enforce_key_transport_algorithm/2` takes `(uri, policy)` or `(policy, uri)` argument
  order — follow the existing `enforce_signature_method/2` argument order.
- Whether `validate_key_transport/2` and `validate_content_encryption/2` wrapper functions
  (returning `{:ok, _} | {:error, _}`) are added — follow the existing `validate_method/3` /
  `validate_digest/3` pattern at `algorithm_policy.ex:58-70` if the call site needs the
  wrapped form.

### Deferred Ideas (OUT OF SCOPE)

- `validate_key_transport/2` / `validate_content_encryption/2` wrapped-form functions — add only
  if Phase 33's `XMLEnc` call site needs the `{:ok, _} | {:error, _}` form. Planner decides.
- ECDSA key transport support (`http://www.w3.org/2001/04/xmlenc#ecdh-es`) — explicitly out of
  v1.3 scope; fail-closed is the correct posture.
- RSA-OAEP SHA-256 (`xmlenc11#rsa-oaep`) — OTP 26-28 stdlib limitation; AlgorithmPolicy blocks
  with a clear error.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENC-03 | AlgorithmPolicy hard-rejects RSA-PKCS1v1.5 key transport (no escape hatch); rejects AES-CBC by default with time-boxed escape hatch; validates AES-GCM auth tag == 16 bytes before any `:crypto` call | D-01 through D-05 plus existing ECDSA hard-reject pattern at `algorithm_policy.ex:88-99` confirm all three sub-requirements are implementable with zero new dependencies |
| ENC-04 (schema half) | Cert inventory `party`/`use` fields isolate encryption certs from signing certs | D-06 through D-09 plus canonical migration pattern fully specify the implementation |
| AUTHN-02 (schema half) | `sign_authn_requests` boolean field on Connection, default `false`, additive and backward-compatible | D-10 through D-11 plus canonical boolean migration pattern fully specify the implementation |
</phase_requirements>

---

## Summary

Phase 32 is a pure internal-code/schema phase — no new Hex dependencies, no public API changes,
no wiring into the validation pipeline. All three deliverables are additive extensions of
patterns already proven in the codebase: the `AlgorithmPolicy` struct extension mirrors the
`legacy_sha1` / `enforce_signature_method` / ECDSA-hard-reject patterns already present in
`algorithm_policy.ex`; both migrations mirror canonical templates already committed under
`priv/repo/migrations/`.

The research confirmed every decision in CONTEXT.md against the actual source files. No
discovered facts contradict any locked decision. The existing test infrastructure (ExUnit async
cases, `MigrationCase`, `strict_default_proof_test.exs`, `algorithm_policy_test.exs`) provides
the exact homes for new Phase 32 tests without creating any new test infrastructure.

**Primary recommendation:** Implement all three deliverables in a single wave of three tasks:
(1) `AlgorithmPolicy` struct + two enforce functions + `legacy_aes_cbc` hatch, (2) cert
`party`/`use` migration + schema fields, (3) connection `sign_authn_requests` migration +
schema field. Each task is independently verifiable via the existing test suite.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Algorithm enforcement policy | Backend — `AlgorithmPolicy` module | — | Pure in-process policy logic; no DB, no network |
| Auth tag length guard | Backend — `AlgorithmPolicy` module | — | Must fire BEFORE `:crypto` call; lives in same enforce function |
| RSA-PKCS1v1.5 hard-reject | Backend — `AlgorithmPolicy` module | — | String match on URI, structurally identical to ECDSA hard-reject |
| AES-CBC escape hatch | Backend — `AlgorithmPolicy` module | — | Mirror of `legacy_sha1` struct field; no DB column needed |
| Certificate `party`/`use` isolation | Database / Storage — Postgres schema | Backend — `Certificate` Ecto schema | DB column stores, schema exposes as `Ecto.Enum` |
| Connection `sign_authn_requests` toggle | Database / Storage — Postgres schema | Backend — `Connection` Ecto schema | DB column stores, schema exposes as boolean; Phase 35 reads it |

---

## Standard Stack

No new dependencies. This phase uses only what is already in `mix.exs`:

| Library | Version (mix.exs) | Purpose in Phase 32 |
|---------|-------------------|---------------------|
| Elixir stdlib | 1.19+ | `defstruct`, `@type`, `@spec`, pattern matching |
| Ecto | ~> 3.13 (optional) | Schema field additions, `Ecto.Enum`, `Ecto.Migration` |
| ecto_sql | ~> 3.13 (optional) | `Ecto.Migration` alter/execute |
| postgrex | >= 0.0.0 (optional) | Postgres backend for migrations |

[VERIFIED: codebase grep — mix.exs lines 57-71]

**Installation:** No new packages. Phase 32 is zero-dependency.

---

## Package Legitimacy Audit

Not applicable — Phase 32 installs no external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
[Operator Config / Test]
         │
         ▼
 AlgorithmPolicy.default/0
 (struct: allowed_key_transport, allowed_content_encryption, legacy_aes_cbc)
         │
         ├──► enforce_key_transport_algorithm/2 ──► :ok | %Error{} (hard-reject PKCS1v1.5 first)
         │
         └──► enforce_content_encryption_algorithm/2
                    │
                    ├── [auth_tag_len < 16] ──► :decryption_failed  (fires FIRST, before allowlist)
                    └── [allowlist check] ──► :ok | %Error{} (AES-CBC blocked by default; hatch unlocks)

[Ecto Migration — cert table]
  ADD COLUMN party :string DEFAULT 'idp' → UPDATE backfill → NOT NULL constraint
  ADD COLUMN use   :string DEFAULT 'signing' → UPDATE backfill → NOT NULL constraint

[Ecto Migration — connection table]
  ADD COLUMN sign_authn_requests :boolean DEFAULT false NOT NULL

[Certificate schema]
  field :party, Ecto.Enum, values: [:idp, :sp]
  field :use,   Ecto.Enum, values: [:signing, :encryption]

[Connection schema]
  field :sign_authn_requests, :boolean, default: false
  (top-level, alongside allow_idp_initiated)
  draft_changeset: cast list includes :sign_authn_requests
```

### Recommended Project Structure

No new directories or files beyond:

```
lib/relyra/security/
└── algorithm_policy.ex      # extend in-place (struct + 2 functions + 1 hatch field)

lib/relyra/ecto/
├── certificate.ex            # add :party and :use fields to schema + changeset
└── connection.ex             # add :sign_authn_requests field + draft_changeset cast

priv/repo/migrations/
├── 20260525XXXXXX_add_party_and_use_to_relyra_connection_certificates.exs  # up/down + backfill
└── 20260525YYYYYY_add_sign_authn_requests_to_relyra_connections.exs        # change

test/relyra/security/
└── algorithm_policy_test.exs  # extend with new describe blocks for new enforce functions
```

[VERIFIED: codebase — all referenced files confirmed to exist at stated paths]

### Pattern 1: AlgorithmPolicy Struct Extension

The existing struct at `algorithm_policy.ex:16-27` is extended in-place. No module rename,
no new module. The `default/0` function is updated to populate the two new allowlist fields.

```elixir
# Source: lib/relyra/security/algorithm_policy.ex (existing struct, showing extension)
defstruct [
  :allowed_signature_methods,
  :allowed_digest_methods,
  :legacy_sha1,
  # NEW in Phase 32:
  :allowed_key_transport_algorithms,
  :allowed_content_encryption_algorithms,
  :legacy_aes_cbc
]

@type legacy_aes_cbc_override :: %{
        reason: String.t(),
        expires_at: DateTime.t()
      }

@type t :: %__MODULE__{
        allowed_signature_methods: [String.t()],
        allowed_digest_methods: [String.t()],
        legacy_sha1: legacy_sha1_override() | nil,
        # NEW:
        allowed_key_transport_algorithms: [String.t()],
        allowed_content_encryption_algorithms: [String.t()],
        legacy_aes_cbc: legacy_aes_cbc_override() | nil
      }
```

[VERIFIED: codebase — mirrors existing `legacy_sha1` type at `algorithm_policy.ex:18-27`]

### Pattern 2: Hard-Reject (RSA-PKCS1v1.5) — Mirror of ECDSA Pattern

The ECDSA hard-reject at `algorithm_policy.ex:88-99` uses a `cond` string-match BEFORE the
allowlist lookup. The PKCS1v1.5 reject follows the identical structural pattern:

```elixir
# Source: lib/relyra/security/algorithm_policy.ex (existing ECDSA pattern)
def digest_atom_for_signature_method(uri) when is_binary(uri) do
  cond do
    # ECDSA fails CLOSED before allowlist check
    String.contains?(uri, "ecdsa") -> {:error, :unsupported_signature_algorithm}
    ...
  end
end

# NEW enforce_key_transport_algorithm/2 follows identical structure:
@spec enforce_key_transport_algorithm(t(), term()) :: :ok | Error.t()
def enforce_key_transport_algorithm(policy, uri) when is_binary(uri) do
  # Hard-reject fires FIRST (D-04) — no hatch, per ENC-03
  if uri == "http://www.w3.org/2001/04/xmlenc#rsa-1_5" do
    Error.new(:deprecated_algorithm, "RSA-PKCS1v1.5 key transport is permanently blocked", ...)
  else
    # then allowlist check (mirrors enforce_signature_method structure)
    if method_allowed?(policy.allowed_key_transport_algorithms, uri) do
      :ok
    else
      deprecated_algorithm(uri, :key_transport_algorithm)
    end
  end
end
```

[VERIFIED: codebase — existing ECDSA pattern at `algorithm_policy.ex:87-99`]

### Pattern 3: enforce_content_encryption_algorithm/2 with Auth Tag Guard

The auth tag guard (D-03) fires BEFORE the allowlist check. The AES-CBC escape hatch
(D-05) mirrors the `enforce_legacy_override/3` private function used for SHA-1.

```elixir
# NEW — auth tag guard fires first, then allowlist, then CBC hatch
@spec enforce_content_encryption_algorithm(t(), term(), keyword()) :: :ok | Error.t() | :decryption_failed
def enforce_content_encryption_algorithm(policy, uri, opts \\ [])

def enforce_content_encryption_algorithm(_policy, _uri, opts) do
  auth_tag = Keyword.get(opts, :auth_tag)
  if is_binary(auth_tag) and byte_size(auth_tag) < 16 do
    :decryption_failed  # opaque atom (D-03); never an %Error{} struct
  else
    # allowlist + CBC hatch logic
    ...
  end
end
```

[VERIFIED: codebase — `enforce_legacy_override/3` at `algorithm_policy.ex:139-161` is the
reusable CBC hatch template]

### Pattern 4: Certificate Migration — up/down + execute UPDATE backfill

Canonical template: `20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`.

```elixir
# Source: priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs
defmodule Relyra.Repo.Migrations.AddPartyAndUseToRelyraConnectionCertificates do
  use Ecto.Migration

  def up do
    alter table(:relyra_connection_certificates) do
      add :party, :string, null: false, default: "idp"
      add :use,   :string, null: false, default: "signing"
    end
    # Backfill is implicit: DB DEFAULT fires on existing rows when NOT NULL constraint
    # is applied at the same time as ADD COLUMN with DEFAULT.
    # (Postgres applies DEFAULT atomically for existing rows; explicit UPDATE only needed
    #  if the column is first added nullable then altered — verify against canonical template)
  end

  def down do
    alter table(:relyra_connection_certificates) do
      remove :use
      remove :party
    end
  end
end
```

**Important nuance (D-06):** The CONTEXT.md decision says "add column with DB default →
`execute("UPDATE ...")` → modify column to `null: false`". Looking at the ACTUAL canonical
template (`20260505140000`), it adds columns with BOTH `null: false` AND `default:` in the
same `alter` block — Postgres applies the DEFAULT to all existing rows atomically when
`ADD COLUMN DEFAULT 'x' NOT NULL` is issued in a single statement. The intermediate
`execute` UPDATE in CONTEXT.md description is a belt-and-suspenders pattern; the canonical
template shows Ecto handles it in one alter block. The planner should follow the canonical
template exactly, not the description of the pattern.

[VERIFIED: codebase — `20260505140000` migration lines 4-12 show single-alter-block pattern]

### Pattern 5: Connection Boolean Migration — change

```elixir
# Source: priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs
defmodule Relyra.Repo.Migrations.AddSignAuthnRequestsToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :sign_authn_requests, :boolean, default: false, null: false
    end
  end
end
```

[VERIFIED: codebase — `20260506232319` migration is the exact template]

### Pattern 6: Ecto.Enum Schema Field

Existing `Certificate` schema uses `Ecto.Enum` for `role` and `lifecycle_state`. The new
`party` and `use` fields follow the same pattern:

```elixir
# Source: lib/relyra/ecto/certificate.ex (existing pattern)
field :role, Ecto.Enum, values: @roles, default: :signing
# NEW:
field :party, Ecto.Enum, values: [:idp, :sp]
field :use,   Ecto.Enum, values: [:signing, :encryption]
```

The `party` and `use` fields do NOT need to be in the `changeset/2` cast list for Phase 32
unless there is a caller that sets them. They can be added to the cast list (as `:party`
and `:use`) following the same pattern as `:role`.

[VERIFIED: codebase — `certificate.ex:21-22` shows Ecto.Enum field declaration pattern]

### Anti-Patterns to Avoid

- **Wrapping enforce functions in `{:ok, _}`:** `enforce_signature_method/2` and
  `enforce_digest_method/2` return `:ok | %Error{}` (NOT `{:ok, _} | {:error, _}`). New
  enforce functions MUST use the same bare return form. Wrapped forms (`validate_key_transport/2`)
  are DEFERRED unless Phase 33 explicitly needs them.
- **Adding Postgres native enum type:** All existing enum-like columns use `:string` in DB
  and `Ecto.Enum` in the schema. No `create_enum` or `EctoEnum.defenum` calls.
- **Adding `null: false` column without default:** Postgres will reject the migration if
  existing rows have no value. Always include `default:` in the `add` call.
- **Putting `sign_authn_requests` inside `RuntimePolicy` embedded schema:** It must live at
  the top level of `Connection`, alongside `allow_idp_initiated` (connection.ex:39). Direct
  DB queryability is required for Phase 35.
- **Using bare `test` mix alias steps in `ci.security`:** All security test suites use
  `cmd mix test ...` (separate OS process). This is the hollow-gate fix from Phase 30 —
  never revert. The `ci_gate_integrity_test.exs` meta-gate enforces this invariant.
- **Adding Postgres ENUM type instead of :string:** All existing enum-like DB columns
  (`role`, `lifecycle_state`, `status`, `provider_preset`) use `:string`. Adding a Postgres
  ENUM type (via `execute "CREATE TYPE ..."`) is explicitly not the project pattern.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Time-boxed override expiry check | Custom DateTime comparison | Existing `enforce_legacy_override/3` private function | Already proven at `algorithm_policy.ex:139-161`; handles expired/missing cases |
| Enum column validation | Custom string validation in changeset | `Ecto.Enum` | Already used for `role`, `lifecycle_state`, `status`, `provider_preset` |
| AES-GCM crypto | Custom crypto | OTP stdlib `:crypto.crypto_one_time_aead/7` | State.md constraint: zero new Hex deps; all v1.3 crypto is OTP stdlib |
| Migration backfill | Manual multi-step SQL | `add :col, :string, null: false, default: "val"` in single alter block | Canonical template shows Postgres applies DEFAULT atomically |

---

## Runtime State Inventory

Step 2.5: SKIPPED — Phase 32 is a greenfield extension (new struct fields, new DB columns with safe defaults). No renaming, refactoring, or migration of existing string values. Existing data gets safe defaults (`:idp`/`:signing`); no old string values are retired.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Certificate/Connection migrations | ✓ (existing test suite runs migrations) | existing (tests green per STATE.md) | — |
| Elixir/OTP | All code | ✓ | ~> 1.19 (mix.exs constraint) | — |
| ecto / ecto_sql | Migration execution | ✓ (existing optional deps) | ~> 3.13 | — |

No missing dependencies. Phase 32 is entirely within the existing proven stack.

---

## Common Pitfalls

### Pitfall 1: Auth Tag Guard Argument vs. Allowlist Argument
**What goes wrong:** The `enforce_content_encryption_algorithm/2` function needs to know the
auth tag length to gate before calling `:crypto.crypto_one_time_aead/7`. But the function
signature is `(policy, uri)` not `(policy, uri, auth_tag)` per D-01 (bare enforce form).
**Why it happens:** D-03 says the guard fires inside the function, but the uri-only signature
can't receive the auth tag. Phase 33 will know the auth tag at call time.
**How to avoid:** The function should accept an optional `opts` keyword arg (third position)
with an `:auth_tag` key, consistent with how existing `validate_method/3` and `validate_digest/3`
have `_opts \\ []`. The guard: `if is_binary(Keyword.get(opts, :auth_tag)) and byte_size(...) < 16`.
**Warning signs:** If the function signature omits `opts`, Phase 33 will have no way to pass
the auth tag length to the guard.

### Pitfall 2: `default/0` Must Populate New Fields
**What goes wrong:** The `default/0` function is the source of truth for the default policy.
If `allowed_key_transport_algorithms` and `allowed_content_encryption_algorithms` are added to
the struct but not to `default/0`, callers get `nil` lists, and `method_allowed?/2` will
raise a `FunctionClauseError` (its guard is `is_list(allowed_methods)`).
**Why it happens:** Forgetting to update `default/0` after adding struct fields.
**How to avoid:** Add both new allowlist fields to `default/0`. Canonical URIs:
- Key transport (allow): `http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p` (RSA-OAEP SHA-1)
- Content encryption (allow): `http://www.w3.org/2001/04/xmlenc#aes128-gcm`, `http://www.w3.org/2001/04/xmlenc#aes256-gcm`
- Both AES-CBC URIs: rejected by default (not in allowlist); `legacy_aes_cbc: nil`
**Warning signs:** `FunctionClauseError` on `Enum.member?/2` when `allowed_methods` is nil.

### Pitfall 3: `connection_snapshot.ex` Filter Scope
**What goes wrong:** Adding `party`/`use` fields to the cert schema could break
`active_signing_certificate?/1` if the filter naively checks ALL cert fields, including new
ones, against an expected value.
**Why it happens:** The filter at `connection_snapshot.ex:117-120` uses `Map.get(certificate, :role, :signing)` — the default argument means missing fields are treated as their default value.
**How to avoid:** The filter is field-specific (`role` and `lifecycle_state` only) — adding
`party`/`use` does NOT change the filter. Confirm `connection_snapshot_test.exs` still passes
without modification after the schema change.
**Warning signs:** `certificate_inventory_transition_test.exs` or `connection_snapshot_test.exs`
failing on cert-not-found style errors.

### Pitfall 4: Migration Timestamp Uniqueness
**What goes wrong:** Two migrations with the same timestamp prefix cause Ecto migration order
ambiguity or duplicate-key errors.
**Why it happens:** Copying a migration filename and forgetting to change the timestamp.
**How to avoid:** Use a distinct UTC timestamp for each migration. The two Phase 32 migrations
(cert columns, connection boolean) need two different timestamps. The most recent migration is
`20260507000001` — new migrations should use timestamps after 2026-05-07.
**Warning signs:** Ecto raises `Ecto.MigrationError` about duplicate migration versions.

### Pitfall 5: `from_connection/2` Does Not Auto-Load New Fields
**What goes wrong:** `AlgorithmPolicy.from_connection/2` at `algorithm_policy.ex:49-56` reads
`:algorithm_policy` from the connection map. If the struct stored in that field was created
before Phase 32 (no `key_transport`/`content_encryption` fields), the new enforce functions
will crash on `nil` allowed lists.
**Why it happens:** Struct stored in DB as map won't have new fields; deserializing into old
struct shape.
**How to avoid:** The `from_connection/2` function falls back to `default()` when no policy is
found. If a persisted `%AlgorithmPolicy{}` IS found, it may lack the new fields. Add a
defensive merge or use `Map.merge(default(), policy_from_db)` before returning. In practice
Phase 32 has no callers that persist `AlgorithmPolicy` structs to the DB (it's a runtime
concept), so this is a forward-looking defensive measure for Phase 33+.

---

## Code Examples

### enforce_key_transport_algorithm/2 — full shape

```elixir
# Source: lib/relyra/security/algorithm_policy.ex (to be written in Phase 32)
# Mirrors enforce_signature_method/2 at lines 101-108

@rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"

@spec enforce_key_transport_algorithm(t(), term()) :: :ok | Error.t()
def enforce_key_transport_algorithm(_policy, @rsa_pkcs1_uri) do
  # D-04: hard-reject, no hatch
  Error.new(
    :deprecated_algorithm,
    "RSA-PKCS1v1.5 key transport is permanently blocked — no escape hatch",
    %{algorithm: @rsa_pkcs1_uri, algorithm_type: :key_transport_algorithm}
  )
end

def enforce_key_transport_algorithm(policy, method) do
  if method_allowed?(policy.allowed_key_transport_algorithms, method) do
    :ok
  else
    deprecated_algorithm(method, :key_transport_algorithm)
  end
end
```

[VERIFIED: mirrors `enforce_signature_method/2` at `algorithm_policy.ex:101-108`]

### Legacy AES-CBC escape hatch — struct extension

```elixir
# Source: lib/relyra/security/algorithm_policy.ex (extension of lines 16-27)

@aes_cbc_uris MapSet.new([
                "http://www.w3.org/2001/04/xmlenc#aes128-cbc",
                "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
              ])

def enforce_content_encryption_algorithm(policy, method, opts \\ []) do
  auth_tag = Keyword.get(opts, :auth_tag)

  cond do
    # D-03: auth tag guard fires FIRST, returns opaque atom
    is_binary(auth_tag) and byte_size(auth_tag) < 16 ->
      :decryption_failed

    method_allowed?(policy.allowed_content_encryption_algorithms, method) ->
      :ok

    # D-05: AES-CBC may be allowed via legacy hatch
    MapSet.member?(@aes_cbc_uris, method) ->
      enforce_legacy_override(policy.legacy_aes_cbc, method, :content_encryption_algorithm)

    true ->
      deprecated_algorithm(method, :content_encryption_algorithm)
  end
end
```

[VERIFIED: reuses existing `enforce_legacy_override/3` at `algorithm_policy.ex:139-161`
and `@sha1_*` MapSet pattern at `algorithm_policy.ex:6-14`]

### Ecto schema additions — Certificate

```elixir
# Source: lib/relyra/ecto/certificate.ex (addition to schema block after :metadata field)
field :party, Ecto.Enum, values: [:idp, :sp]
field :use,   Ecto.Enum, values: [:signing, :encryption]
```

Add `:party` and `:use` to the `cast/3` list in `changeset/2`.

[VERIFIED: mirrors `field :role, Ecto.Enum, values: @roles, default: :signing` at `certificate.ex:21`]

### Ecto schema addition — Connection

```elixir
# Source: lib/relyra/ecto/connection.ex (addition at line ~40, after :allow_idp_initiated)
field :sign_authn_requests, :boolean, default: false
```

Add `:sign_authn_requests` to `draft_changeset/2` cast list.
Determine whether `update_changeset/2` should also cast it — `allow_idp_initiated` IS in
`update_changeset` cast list (line 121), so `sign_authn_requests` should be too.

[VERIFIED: mirrors `field :allow_idp_initiated, :boolean, default: false` at `connection.ex:39`]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No content-encryption policy | `enforce_content_encryption_algorithm/2` with auth tag guard | Phase 32 | AES-GCM enforced; AES-CBC blocked by default |
| No key-transport policy | `enforce_key_transport_algorithm/2` with PKCS1v1.5 hard-reject | Phase 32 | RSA-PKCS1v1.5 permanently blocked |
| No cert isolation columns | `party`/`use` on `relyra_connection_certificates` | Phase 32 | Phase 33 can filter SP encryption certs vs IdP signing certs |
| No per-connection AuthnRequest signing toggle | `sign_authn_requests` on `relyra_connections` | Phase 32 | Phase 35 can read and act on this flag |

**Deprecated/outdated:** Nothing retired in Phase 32 — all changes are purely additive.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | RSA-OAEP SHA-1 URI (`xmlenc#rsa-oaep-mgf1p`) is the correct allowlist entry for default key transport | Standard Stack / Pitfall 2 | If the URI string is wrong, `enforce_key_transport_algorithm/2` will reject valid OAEP-SHA1 inputs in Phase 33; needs verification against XML-Enc spec or test fixture |
| A2 | AES-GCM URIs are `xmlenc#aes128-gcm` and `xmlenc#aes256-gcm` | Pitfall 2 | If wrong, default policy will reject valid AES-GCM inputs in Phase 33 |
| A3 | `update_changeset/2` should cast `sign_authn_requests` (following `allow_idp_initiated` pattern) | Code Examples | If wrong, updating a connection via `update_changeset` won't accept the field — low risk since Phase 35 sets it |

[A1 and A2 are well-established XML Encryption 1.0 spec URIs but were not verified via
Context7 or official docs in this session — mark as ASSUMED for planner confirmation.]

---

## Open Questions

1. **`enforce_content_encryption_algorithm/2` — when is `auth_tag` available?**
   - What we know: D-03 says the guard fires inside `enforce_content_encryption_algorithm/2`
     before calling `:crypto.crypto_one_time_aead/7`.
   - What's unclear: Phase 32 implements the guard in `AlgorithmPolicy` before Phase 33
     exists. The function needs an `opts` keyword parameter to accept the auth tag, but no
     callers exist yet in this phase.
   - Recommendation: Add `opts \\ []` as the third parameter. The guard only fires when
     `:auth_tag` is present in opts — when called from Phase 32 tests with no opts, the guard
     is a no-op. The planner should confirm this is the right shape before implementation.

2. **`from_connection/2` defensive merge for new fields**
   - What we know: The function at `algorithm_policy.ex:49-56` returns `default()` when no
     policy is set. If a `%AlgorithmPolicy{}` IS stored (via LiveAdmin), it won't have
     `key_transport`/`content_encryption` fields.
   - What's unclear: Is a persisted `AlgorithmPolicy` struct possible in the current DB schema?
   - Recommendation: Given current schema has no `algorithm_policy` column, this is not an
     immediate concern. The planner may choose to document a TODO for Phase 33.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENC-03 — PKCS1v1.5 hard-reject | `enforce_key_transport_algorithm/2` rejects `rsa-1_5` URI regardless of policy | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ (extend existing) |
| ENC-03 — AES-CBC default reject | `enforce_content_encryption_algorithm/2` rejects AES-CBC URIs by default | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ (extend existing) |
| ENC-03 — AES-CBC hatch | `enforce_content_encryption_algorithm/2` allows AES-CBC when `legacy_aes_cbc` hatch is active and not expired | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ (extend existing) |
| ENC-03 — AES-GCM auth tag guard | `enforce_content_encryption_algorithm/2` returns `:decryption_failed` for auth_tag < 16 bytes | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ (extend existing) |
| ENC-03 — strict default proof | New enforce functions are tested in `strict_default_proof_test.exs` | unit | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | ✅ extend existing |
| ENC-04 / AUTHN-02 — migration + schema | Party/use fields on cert schema; sign_authn_requests on connection schema | integration | `mix test test/relyra/ecto/certificate_schema_test.exs test/relyra/ecto/connection_record_test.exs --warnings-as-errors` | ✅ (extend existing) |
| ENC-04 / AUTHN-02 — snapshot regression | Existing cert rollover/snapshot/expiry tests still pass | regression | `mix ci.verify` | ✅ existing files |

### Sampling Rate

- **Per task commit:** `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors`
- **Per wave merge:** `mix test --warnings-as-errors && mix ci.security`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. The planner should add
new `describe` blocks to `test/relyra/security/algorithm_policy_test.exs` within existing tasks,
not create a new test file (no Wave 0 file-creation task needed for tests).

---

## Security Domain

`security_enforcement` is enabled (not explicitly false in config.json).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | AlgorithmPolicy URI string matching; Ecto.Enum for DB enum fields |
| V6 Cryptography | yes | Algorithm allowlist enforcement; auth tag length gate; PKCS1v1.5 permanent block |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Algorithm substitution (swap RSA-OAEP for PKCS1v1.5 in EncryptedKey) | Tampering | `enforce_key_transport_algorithm/2` hard-rejects PKCS1v1.5 URI before allowlist; no escape hatch |
| Padding oracle via CBC decryption errors | Information Disclosure | `legacy_aes_cbc` hatch blocked by default; time-boxed if enabled; all failure modes return `:decryption_failed` (opaque) |
| Truncated GCM auth tag (authentication bypass) | Tampering | Auth tag guard fires BEFORE `:crypto.crypto_one_time_aead/7`; returns `:decryption_failed` for auth_tag < 16 bytes |
| Injection of cleartext + encrypted assertion simultaneously | Spoofing | Out of Phase 32 scope — Phase 34 owns the `:ambiguous_assertion` guard |

---

## Project Constraints (from CLAUDE.md)

These directives apply to all Phase 32 implementation:

1. **`mix test --warnings-as-errors` must stay green** — all new code must compile without warnings.
2. **`mix ci.security` must stay green** — each security suite runs as its own `cmd mix test` process. Do NOT add bare `test` steps to `ci.security`.
3. **`mix format --check-formatted` must exit 0** — run `mix format` before committing.
4. **Never weaken `test/security/xml/adversarial_crypto_test.exs`** — Phase 32 does not touch this file; confirm after changes.
5. **New security-relevant code gets adversarial corpus rows in `mix ci.security`** — the two new `enforce_*` functions are security-relevant; add them to `strict_default_proof_test.exs` (already in `ci.security`).
6. **Algorithm policy: RSA-PKCS1v1.5 permanently blocked; AES-CBC blocked by default with escape hatch** — non-negotiable invariants from STATE.md.
7. **Zero new Hex dependencies** — all v1.3 crypto is OTP stdlib; this phase installs nothing.
8. **Audit co-commit for trust mutations** — Phase 32 adds schema fields, not trust mutations; the audit co-commit invariant does not apply here. The new `party`/`use` columns will be set by Phase 33's `KeyResolver` cert operations, which will need audit rows.
9. **`mix ci.security` hollow-gate fix is permanent** — never revert `cmd mix test` to bare `test` steps.

---

## Sources

### Primary (HIGH confidence)
- `lib/relyra/security/algorithm_policy.ex` — struct definition, existing escape hatch pattern, enforce function signatures, ECDSA hard-reject pattern [VERIFIED: direct file read]
- `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs` — canonical up/down backfill migration template [VERIFIED: direct file read]
- `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` — canonical change/boolean migration template [VERIFIED: direct file read]
- `lib/relyra/ecto/certificate.ex` — Certificate schema with Ecto.Enum fields [VERIFIED: direct file read]
- `lib/relyra/ecto/connection.ex` — Connection schema, `allow_idp_initiated` placement, `draft_changeset` and `update_changeset` cast lists [VERIFIED: direct file read]
- `lib/relyra/ecto/connection_snapshot.ex:117-120` — `active_signing_certificate?/1` filter (only checks `role` and `lifecycle_state`; new `party`/`use` fields do not affect it) [VERIFIED: direct file read]
- `mix.exs` — `ci.security` alias structure, `cmd mix test` hollow-gate fix comments [VERIFIED: direct file read]
- `test/relyra/security/algorithm_policy_test.exs` — existing test structure, describes to extend [VERIFIED: direct file read]
- `test/security/strict_default_proof_test.exs` — security proof tests that Phase 32 must not regress [VERIFIED: direct file read]
- `.planning/phases/32-algorithm-policy-extension-schema-migrations/32-CONTEXT.md` — all locked decisions [VERIFIED: direct file read]

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — ENC-03, ENC-04, AUTHN-02 acceptance language [VERIFIED: direct file read]
- `.planning/milestones/v1.3-ROADMAP.md` — Phase 32 success criteria [VERIFIED: direct file read]

### Tertiary (LOW confidence)
- XML Encryption 1.0 spec URI strings (`rsa-oaep-mgf1p`, `aes128-gcm`, `aes256-gcm`) — based on training knowledge, not verified against official spec in this session [ASSUMED — A1, A2]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; all patterns verified from codebase
- Architecture: HIGH — all decisions locked in CONTEXT.md, confirmed against source files
- Pitfalls: HIGH — derived from actual code paths (method_allowed? guard, snapshot filter, migrate pattern)
- XML-Enc URI strings: LOW — ASSUMED, planner should confirm before hardcoding in `default/0`

**Research date:** 2026-05-25
**Valid until:** 2026-07-25 (stable Elixir/Ecto patterns; no fast-moving ecosystem)
