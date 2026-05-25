# Phase 32: AlgorithmPolicy Extension + Schema Migrations - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `AlgorithmPolicy` with key-transport and content-encryption algorithm enforcement
functions and escape hatch fields; add cert `party`/`use` columns and connection
`sign_authn_requests` field via safe additive Ecto migrations.

**In scope:** `lib/relyra/security/algorithm_policy.ex` (new functions + struct fields),
two Ecto migrations (`relyra_connection_certificates` and `relyra_connections`), and
Ecto schema field additions for `Certificate` and `Connection`.

**Out of scope:** the `KeyResolver` behaviour or `XMLEnc` decryption implementation
(Phase 33); wiring into `ValidationPipeline` (Phase 34); signed AuthnRequest
redirect-binding implementation (Phase 35). This phase is schema + policy foundation only.

**Requirements closed (fully or partially):** ENC-03, ENC-04 (schema half only — KeyResolver
behaviour is Phase 33), AUTHN-02 (schema half only — toggle implementation is Phase 35).
</domain>

<decisions>
## Implementation Decisions

### AlgorithmPolicy API Extension
- **D-01:** New enforcement functions use the bare `:ok | Error.t()` return form — matching
  `enforce_signature_method/2` and `enforce_digest_method/2` at `algorithm_policy.ex:101-116`
  — not wrapped `{:ok, _} | {:error, _}`. Public API:
  `enforce_key_transport_algorithm/2` and `enforce_content_encryption_algorithm/2`.
- **D-02:** The `AlgorithmPolicy` struct gains two new allowlist fields (`key_transport` and
  `content_encryption`) in parallel with the existing `allowed_signature_methods` and
  `allowed_digest_methods` fields, plus one new escape hatch field (`legacy_aes_cbc`) mirroring
  the exact `%{reason: String.t(), expires_at: DateTime.t()}` type of `legacy_sha1`.
- **D-03:** AES-GCM auth tag length guard is implemented inside `enforce_content_encryption_algorithm/2`:
  if the decryption path provides an auth tag shorter than 16 bytes, return `:decryption_failed`
  immediately without calling `:crypto.crypto_one_time_aead/7`. This guard is a distinct
  code path from the algorithm allowlist check and fires first.

### RSA-PKCS1v1.5 No-Hatch Enforcement
- **D-04:** RSA-PKCS1v1.5 key transport (`http://www.w3.org/2001/04/xmlenc#rsa-1_5`) is
  hard-rejected via a URI blocklist pattern — structurally identical to the ECDSA hard-reject
  at `algorithm_policy.ex:88-99` (string match before allowlist lookup). **No escape hatch
  field** is added for PKCS1v1.5. This is a security posture invariant: ENC-03 explicitly
  states "no escape hatch — no legitimate production use case."
- **D-05:** AES-CBC (`http://www.w3.org/2001/04/xmlenc#aes128-cbc`,
  `http://www.w3.org/2001/04/xmlenc#aes256-cbc`) is rejected by default but has a `legacy_aes_cbc`
  escape hatch using the identical struct pattern to `legacy_sha1`. Activating the hatch requires
  the same `reason: String.t(), expires_at: DateTime.t()` fields.

### Certificate Migration: `party` + `use` Columns
- **D-06:** Uses explicit `up/down` (not `change`) because adding `null: false` columns to a
  table with existing rows requires a row backfill before the constraint fires. Pattern: add
  column with DB default → `execute("UPDATE ... SET party = 'idp', use = 'signing'")` →
  modify column to `null: false`. Follows `20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs`.
- **D-07:** Both columns stored as `:string` in the database — consistent with all existing
  enum-like columns (`role`, `lifecycle_state`, `status`, `provider_preset`). No Postgres
  native enum type.
- **D-08:** DB defaults: `party = "idp"`, `use = "signing"`. All existing certificate rows
  receive these safe defaults, so the existing snapshot filter (`connection_snapshot.ex:117-120`
  checking `role == :signing` and `lifecycle_state == :active`) continues to work without changes.
- **D-09:** Ecto `Certificate` schema gains `Ecto.Enum` fields:
  - `field :party, Ecto.Enum, values: [:idp, :sp]`
  - `field :use, Ecto.Enum, values: [:signing, :encryption]`

### `sign_authn_requests` Migration and Schema
- **D-10:** Simple `change`-based migration — `add :sign_authn_requests, :boolean, default: false, null: false` — identical structure to `20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`. Postgres `DEFAULT false` covers all existing rows atomically; no `up/down` or backfill needed.
- **D-11:** Top-level field on the `Connection` Ecto schema — **not** inside the `RuntimePolicy`
  embedded schema — consistent with `allow_idp_initiated` placement at `connection.ex:39`.
  Added to `draft_changeset` cast list alongside `allow_idp_initiated`. This placement ensures
  direct DB queryability in Phase 35's metadata endpoint.

### Claude's Discretion
- Exact migration timestamp filenames (follow project convention: UTC timestamp prefix).
- Whether `enforce_key_transport_algorithm/2` takes `(uri, policy)` or `(policy, uri)` argument
  order — follow the existing `enforce_signature_method/2` argument order.
- Whether `validate_key_transport/2` and `validate_content_encryption/2` wrapper functions
  (returning `{:ok, _} | {:error, _}`) are added — follow the existing `validate_method/3` /
  `validate_digest/3` pattern at `algorithm_policy.ex:58-70` if the call site needs the
  wrapped form.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/relyra/security/algorithm_policy.ex` — **primary file to extend**; struct definition
  (lines 16-27), existing escape hatch pattern (`legacy_sha1`), `enforce_signature_method/2` and
  `enforce_digest_method/2` return-type convention (lines 101-116), ECDSA no-hatch pattern
  (lines 88-99). Read fully before adding any new function.
- `priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs` —
  canonical `up/down` + `execute` UPDATE backfill pattern for non-nullable cert columns.
- `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` —
  canonical `change` pattern for additive boolean connection field.
- `lib/relyra/ecto/certificate.ex` — `Certificate` Ecto schema (add `party` and `use` fields here).
- `lib/relyra/ecto/connection.ex` — `Connection` Ecto schema (add `sign_authn_requests` here,
  at line ~39 alongside `allow_idp_initiated`; add to `draft_changeset` cast list).
- `lib/relyra/ecto/connection_snapshot.ex` — snapshot filter at lines 117-120; must not break
  after adding `party`/`use` to certs.
- `.planning/REQUIREMENTS.md` — ENC-03, ENC-04, AUTHN-02 acceptance language.
- `.planning/ROADMAP.md` + `.planning/milestones/v1.3-ROADMAP.md` — Phase 32 success criteria
  (5 must-be-TRUE items) and phase boundaries.
- `test/security/strict_default_proof_test.exs` — existing tests for `AlgorithmPolicy` enforce
  functions; new functions must not regress these.
- `mix.exs` — `ci.security` alias (each security suite is its own `cmd mix test` process — do
  not change this to bare `test` steps per CLAUDE.md / Phase 30 hollow-gate fix).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AlgorithmPolicy` struct escape hatch pattern (`legacy_sha1` field with
  `%{reason: String.t(), expires_at: DateTime.t()}`) — copy identically for `legacy_aes_cbc`.
- `enforce_signature_method/2` / `enforce_digest_method/2` at `algorithm_policy.ex:101-116` —
  the exact return-type and guard structure to replicate for the two new enforce functions.
- ECDSA hard-reject pattern at `algorithm_policy.ex:88-99` — URI string match before allowlist
  check — reuse for RSA-PKCS1v1.5 hard-reject.
- `20260506232319` migration — the exact `change` + boolean-with-default template.
- `20260505140000` migration — the exact `up/down` + execute-UPDATE template.

### Established Patterns
- Enum-like columns stored as `:string` in DB + `Ecto.Enum` in schema (all existing: `role`,
  `lifecycle_state`, `status`, `provider_preset`).
- `Certificate` schema `role` field: `Ecto.Enum, values: [:signing, :encryption, :root_ca]` —
  the `use` field will follow the same pattern with `values: [:signing, :encryption]`.
- `Connection` schema boolean toggles at top level, not in embedded `RuntimePolicy` JSON.
- `ci.security` alias: each test is its own `cmd mix test` subprocess (hollow-gate fix from
  Phase 30 — do not inline as a bare `test` mix alias step).

### Integration Points
- `lib/relyra/security/signature.ex` — will call `enforce_key_transport_algorithm/2` and
  `enforce_content_encryption_algorithm/2` in Phase 33/34; these functions must be callable
  from outside `AlgorithmPolicy` (public `def`, not `defp`).
- `lib/relyra/ecto/connection_snapshot.ex:117-120` — snapshot filter reads cert fields directly;
  adding `party`/`use` with safe defaults means no filter changes needed.
- Phase 33 (`KeyResolver` + `XMLEnc`) depends on the `AlgorithmPolicy` functions existing before
  it can wire decryption behind the policy gate.
- Phase 35 (`sign_authn_requests` implementation) depends on the DB column existing to toggle
  per-connection.
</code_context>

<specifics>
## Specific Ideas

- RSA-PKCS1v1.5 URI to hard-reject: `http://www.w3.org/2001/04/xmlenc#rsa-1_5`
- AES-CBC URIs to reject-by-default (covered by allowlist check, not hard-reject):
  `http://www.w3.org/2001/04/xmlenc#aes128-cbc`, `http://www.w3.org/2001/04/xmlenc#aes256-cbc`
- AES-GCM auth tag guard: exactly 16 bytes; return atom `:decryption_failed` (not an `%Error{}`
  struct) — consistent with the opaque error discipline Phase 33 will establish for `XMLEnc.decrypt/3`.
- The `party` column's initial allowed values are `[:idp, :sp]` — Phase 33 will use `:sp` when
  configuring SP decryption cert isolation; Phase 32 only adds the column and defaults existing
  rows to `:idp`.
</specifics>

<deferred>
## Deferred Ideas

- `validate_key_transport/2` / `validate_content_encryption/2` wrapped-form functions — add only
  if Phase 33's `XMLEnc` call site needs the `{:ok, _} | {:error, _}` form. Planner decides.
- ECDSA key transport support (`http://www.w3.org/2001/04/xmlenc#ecdh-es`) — explicitly out of
  v1.3 scope (REQUIREMENTS.md Out of Scope table); fail-closed is the correct posture.
- RSA-OAEP SHA-256 (`xmlenc11#rsa-oaep`) — OTP 26-28 stdlib limitation documented in
  REQUIREMENTS.md Out of Scope; AlgorithmPolicy blocks with a clear error.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
