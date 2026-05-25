# Architecture Research

**Domain:** SAML 2.0 SP library — v1.3 Advanced Federation integration design
**Researched:** 2026-05-25
**Confidence:** HIGH (derived from direct source reading of all affected modules)

---

## Integration Overview: What Changes vs What Stays

The v1.3 work touches three separate concerns. They share no circular dependency; each can be designed
independently and integrated sequentially.

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                      v1.3 Integration Surface                                  │
├──────────────────────────────────────┬────────────────────────────────────────┤
│  ENCRYPTED ASSERTIONS (ENC-01)       │  SIGNED AUTHN REQUESTS (AUTHN-01)      │
│                                      │                                        │
│  New module: Security.XMLEnc         │  New fn: Signature.sign_redirect_query │
│  New behaviour: KeyResolver          │  Modified: Protocol.AuthnRequest       │
│  Modified: AlgorithmPolicy           │  Modified: Protocol.Metadata           │
│  Modified: ValidationPipeline        │  Modified: Ecto.Connection (schema)     │
│  Modified: Protocol.Metadata         │  New migration: sign_authn_requests    │
│  Modified: Ecto.Certificate (schema) │  Config: sp_signing_key (app env only) │
│  New migration: party + use fields   │                                        │
├──────────────────────────────────────┴────────────────────────────────────────┤
│  FEDERATION GUIDES (DOCS-02/03)                                               │
│  Pure documentation — zero module changes                                      │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Encrypted Assertions: Component Boundaries and Data Flow

### New Module: `Relyra.Security.XMLEnc`

Responsibility: XML-Enc decryption only — no parsing, no field access, no signature ops.

Takes raw `<EncryptedAssertion>` bytes (binary), returns decrypted plaintext bytes (binary) or
a typed error. That plaintext is NEVER examined before being fed back through `PureBeam.parse_safely/2`.

```
Input:  encrypted_assertion_bytes :: binary
                     |
                     v
           XMLEnc.decrypt/3(encrypted_bytes, key_resolver, algorithm_policy)
                     |
          +----------+------------------+
          |  AlgorithmPolicy check       |  -- reject RSA-PKCS1v1.5, AES-CBC (BEFORE any key op)
          +----------+------------------+
                     |
                     v
          +---------------------------+
          |  KeyResolver.resolve_key  |  -- PEM default impl or KMS hook
          |  (key_transport_alg,      |
          |   key_info hint)          |
          +----------+----------------+
                     |
                     v
          +---------------------------+
          |  :public_key.decrypt_     |  -- RSA-OAEP via :rsa_oaep_padding
          |  private/3 (RSA-OAEP)     |
          +----------+----------------+
                     |
                     v
          +---------------------------+
          |  :crypto.crypto_one_time  |  -- AES-GCM decryption + auth-tag verify
          |  _aead/6 (AES-GCM)        |
          +----------+----------------+
                     |
                     v
Output: {:ok, plaintext_bytes} | {:error, %Relyra.Error{type: :decryption_failed}}
```

All cipher failures map to the SAME `:decryption_failed` atom — no oracle in the error type.

### New Behaviour: `Relyra.KeyResolver`

Lives in `lib/relyra/key_resolver.ex`. Mirrors the `ConnectionResolver` / `ReplayStore` behaviour pattern
already established in the codebase.

```elixir
@callback resolve_sp_decryption_key(
  key_transport_algorithm :: binary(),
  key_info_hint :: binary() | nil,
  opts :: keyword()
) :: {:ok, private_key :: term()} | {:error, Relyra.Error.t()}
```

Default impl: `Relyra.KeyResolver.Default` reads `:sp_decryption_key_pem` from application config,
decodes it via `:public_key.pem_decode/1`, returns the private key struct. Never touches DB; never
surfaces key material in diagnostics. KMS stub ships as `Relyra.KeyResolver.KMS` (documented extension
point, no actual KMS call in v1.3).

### Decrypt-Then-Verify Data Flow

The ONLY correct ordering:

```
ACSController.create/2
        |
        v
ValidationPipeline.run/4  <- entry point; no change to external contract
        |
        v
PureBeam.parse_safely/2(raw_response_bytes)
        |
        +-- {:ok, parsed_doc with type: :parsed_xml}           <- cleartext assertion path (existing)
        |
        +-- {:ok, parsed_doc with :encrypted_assertion_bytes}  <- encrypted path (new)
                 |
                 v
         [NEW STEP] ValidationPipeline detects :encrypted_assertion_bytes in parsed_doc
                 |
                 v
         ambiguity guard: if both cleartext Assertion AND EncryptedAssertion present -> :ambiguous_assertion
                 |
                 v
         XMLEnc.decrypt/3(encrypted_bytes, key_resolver, algorithm_policy)
                 |
                 +-- {:error, :decryption_failed}  -> surface typed error, stop
                 |
                 +-- {:ok, plaintext_bytes}
                          |
                          v
                 PureBeam.parse_safely/2(plaintext_bytes)   <- SAME hardened seam, second call
                          |
                          +-- {:error, ...}  -> :malformed_xml (decrypted garbage treated as malformed)
                          |
                          +-- {:ok, inner_parsed_doc}
                                   |
                                   v
                          Signature.verify(inner_parsed_doc, ...)  <- existing do_verify/4, unmodified
                                   |
                                   v
                          ... rest of validation pipeline unchanged ...
```

Critical invariant: `PureBeam.parse_safely/2` is called TWICE when encrypted — once on the outer
response (to detect `<EncryptedAssertion>`), once on the decrypted plaintext (to actually parse the
assertion). The second call runs EVERY pre-parse guard again (DOCTYPE, ENTITY, size limit) against
the decrypted bytes. No field from the decrypted bytes is read before `Signature.verify` succeeds.

### Modifications to Existing Modules

**`Relyra.Security.XML.PureBeam`** (modified, not new)

Add detection of `<EncryptedAssertion>` in `build_parsed_doc/1`: when an `EncryptedAssertion` child
is found instead of (or alongside) a cleartext `Assertion`, extract the raw encrypted bytes and surface
them as `:encrypted_assertion_bytes` in the `parsed_doc` map. Do NOT attempt to derive assertion
fields from it (name_id, audiences, etc. remain nil). The existing `require_present_fields` check for
`:signed_candidates` must be relaxed for the encrypted path — encryption precedes signing detection
in that case; the pipeline's decrypt step produces the inner doc whose signed candidates are then
checked.

**`Relyra.Protocol.ValidationPipeline`** (modified)

Add one new step BETWEEN `parse_safely` and `verify`:

```elixir
@ordered_stages [
  :parse_safely,
  :issuer_connection_match,
  :decrypt_assertion,    # NEW -- no-op when :encrypted_assertion_bytes absent
  :signature_verify,
  :signed_node_bind,
  :status,
  :destination,
  :audience,
  :recipient,
  :time_conditions
]
```

The `:decrypt_assertion` step is a pure no-op pass-through when `:encrypted_assertion_bytes` is nil
in parsed_doc. When present, it calls `XMLEnc.decrypt/3`, re-calls `PureBeam.parse_safely/2`, and
replaces `parsed_doc` with the inner parsed doc for all downstream steps. This is the ONLY place
where the two parse calls are wired together — nothing else in the pipeline changes.

**`Relyra.Security.AlgorithmPolicy`** (modified)

Add two new policy dimensions (parallel to existing `allowed_signature_methods` / `allowed_digest_methods`):

```elixir
defstruct [
  :allowed_signature_methods,
  :allowed_digest_methods,
  :allowed_key_transport_algorithms,       # NEW
  :allowed_content_encryption_algorithms,  # NEW
  :legacy_sha1
]
```

Default policy for new fields:
- `allowed_key_transport_algorithms: ["http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"]` (OAEP only)
- `allowed_content_encryption_algorithms: ["http://www.w3.org/2001/04/xmlenc#aes256-gcm", "http://www.w3.org/2001/04/xmlenc#aes128-gcm"]` (GCM only)

RSA-PKCS1v1.5 and AES-CBC are not in the default lists. Same escape-hatch pattern as SHA-1:
time-boxed, `reason:` required.

New policy enforcement functions:
- `enforce_key_transport_algorithm/2` -- returns `:ok | %Error{type: :unsupported_key_transport_algorithm}`
- `enforce_content_encryption_algorithm/2` -- returns `:ok | %Error{type: :unsupported_content_encryption_algorithm}`

New helper for AUTHN-01:
- `signing_digest_atom/1` -- maps signature URI to digest atom for outbound signing (analogous to `digest_atom_for_signature_method/1`)

**`Relyra.Protocol.Metadata`** (modified)

Extend `build_sp_metadata/2` to emit `<md:KeyDescriptor use="encryption">` with the SP public
encryption cert when `:sp_decryption_cert_pem` is configured, and `<md:KeyDescriptor use="signing">`
when `sp_signing_cert_pem` is configured. Existing minimal AssertionConsumerService element stays.

### Cert Inventory Schema Extension

`Relyra.Ecto.Certificate` currently has `role: Ecto.Enum, values: [:signing]`. Extend for v1.3:

New enum values:
- `@roles [:signing, :sp_encryption]`
- `@parties [:idp, :sp]` (new field)

New database fields on `relyra_connection_certificates`:
- `party` -- `:sp | :idp` (who owns this cert)
- `use` -- `:signing | :encryption` (certificate purpose)

Migration strategy: default `party: :idp` and `use: :signing` for all existing rows. This is a
non-breaking migration -- existing code that queries by `role: :signing` continues to work; the new
fields are additive.

The SP encryption cert public material is stored in inventory for expiry tracking and admin UI display.
The private decryption key is NOT stored here -- it lives in app config only. This isolation prevents
key-confusion: code that resolves IdP signing certs cannot accidentally select an SP cert.

---

## Signed AuthnRequests: Component Boundaries and Data Flow

### New Function: `Relyra.Security.Signature.sign_redirect_query/3`

Added directly to the existing `Signature` module (it already owns all crypto operations). No new
module needed.

```elixir
@spec sign_redirect_query(
  query_string :: binary(),
  private_key :: term(),
  digest_atom :: :sha256 | :sha384 | :sha512
) :: {:ok, signature_b64 :: binary()} | {:error, Relyra.Error.t()}
```

Takes the raw query-string binary `"SAMLRequest=...&RelayState=...&SigAlg=..."` (already
URL-encoded, not re-serialized), signs it with `:public_key.sign/4`, returns the base64-encoded
signature to append as `&Signature=...`. The `digest_atom` is derived by the caller via
`AlgorithmPolicy.signing_digest_atom/1`.

Critical: the caller constructs the raw query-string octets ONCE and passes them verbatim. The function
signs those exact bytes. No reconstruction, no URI parsing inside the function.

### Modified: `Relyra.Protocol.AuthnRequest`

The existing `build/3` and `to_xml/1` are unchanged. A new `sign_redirect_params/3` function handles
the HTTP-Redirect binding signature assembly:

```elixir
@spec sign_redirect_params(
  authn_request_xml :: binary(),
  sp_signing_key :: term(),
  opts :: keyword()
) :: {:ok, %{query_string: binary(), signature: binary(), sig_alg: binary()}}
   | {:error, Relyra.Error.t()}
```

This function:
1. Deflate-compresses and base64-encodes the XML
2. URL-encodes it as `SAMLRequest=<encoded>`
3. Appends `&RelayState=<encoded>` if relay state present in opts
4. Appends `&SigAlg=<url-encoded-uri>` for the configured algorithm
5. Signs the EXACT concatenated query-string bytes via `Signature.sign_redirect_query/3`
6. Returns the query string plus signature (login controller appends `&Signature=<sig>` and redirects)

Whether to call `sign_redirect_params/3` is decided by `LoginController` based on
`connection.sign_authn_requests` -- the function itself is always available.

### Config: `sp_signing_key_pem`

NOT stored in the DB. Resolved at runtime from application config:

```elixir
# config/runtime.exs
config :relyra, sp_signing_key_pem: File.read!("/run/secrets/sp_signing_key.pem")
```

A `Relyra.Config.sp_signing_key/1` helper (or inline in `LoginController`) handles the
PEM -> private key decoding. This mirrors `KeyResolver.Default` but for outbound signing.
The corresponding PUBLIC cert is a separate config key `sp_signing_cert_pem` (for metadata publication
only; no private key material in cert).

### Modified: `Relyra.Ecto.Connection` (schema) + migration

Add `sign_authn_requests: :boolean, default: false` to the Ecto connection schema. Per-connection
field because different IdPs in the same tenant may have different requirements. Migration adds the
column with `default: false` -- fully backward-compatible, all existing rows get `false`.

### Modified: `Relyra.Phoenix.Controllers.LoginController`

New conditional branch in `create/2`:

```elixir
case {connection.sign_authn_requests, sp_signing_key(opts)} do
  {true, {:ok, key}} ->
    Protocol.AuthnRequest.sign_redirect_params(to_xml(authn_request), key, opts)
  {true, {:error, _}} ->
    {:error, Error.new(:sp_signing_key_missing, "...")}
  {false, _} ->
    {:ok, unsigned_redirect_params(authn_request)}
end
```

The error is clear and operator-actionable: it names the exact config key that is missing.

---

## Build Order Across Plans

Dependency graph mandates this ordering:

```
Plan 1  AlgorithmPolicy extension + cert schema migration
        |- Add key_transport + content_encryption policy dims to AlgorithmPolicy
        |- Add signing_digest_atom/1 helper (needed by AuthnRequest signing)
        |- Add party + use fields to Certificate schema (additive migration)
        |- All existing tests must still pass (additive only)

Plan 2  KeyResolver behaviour + XMLEnc crypto core
        |- Depends on: Plan 1 (AlgorithmPolicy checks in XMLEnc use new policy)
        |- KeyResolver behaviour + Default impl + KMS stub
        |- XMLEnc.decrypt/3 (RSA-OAEP + AES-GCM, opaque errors)
        |- Unit corpus for XMLEnc (verify rejection of PKCS1v1.5, AES-CBC, malformed CT)

Plan 3  ValidationPipeline wiring + metadata + ENC-01 adversarial corpus
        |- Depends on: Plan 2 (XMLEnc must exist)
        |- PureBeam: EncryptedAssertion detection + ambiguity guard
        |- ValidationPipeline: :decrypt_assertion step inserted
        |- Protocol.Metadata: SP encryption KeyDescriptor
        |- All 7 ENC-01 corpus fixtures wired into ci.security

Plan 4  Signed AuthnRequests: signing primitive + connection config + corpus
        |- Depends on: Plan 1 (signing_digest_atom from AlgorithmPolicy)
        |- Can start concurrently with Plan 2 (no dependency on XMLEnc)
        |- Signature.sign_redirect_query/3
        |- AuthnRequest.sign_redirect_params/3
        |- Connection schema: sign_authn_requests field + migration
        |- LoginController wiring
        |- Protocol.Metadata: SP signing KeyDescriptor
        |- All 5 AUTHN-01 corpus fixtures wired into ci.security
        |- ADFS provider runbook notes

Plan 5  DOCS-02 generic SAML runbook
        |- No code dependency; can proceed in parallel

Plan 6  DOCS-03 identity mapping & provisioning guide
        |- No code dependency; can proceed in parallel
```

Minimum serialized path: Plan 1 -> Plan 2 -> Plan 3 (for ENC-01 completion).
Plan 4 can run after Plan 1 and in parallel with Plans 2-3.
Plans 5-6 are fully parallel with everything.

---

## New vs Modified: Explicit Inventory

### New Modules

| Module | Location | Purpose |
|--------|----------|---------|
| `Relyra.KeyResolver` | `lib/relyra/key_resolver.ex` | Behaviour definition |
| `Relyra.KeyResolver.Default` | `lib/relyra/key_resolver/default.ex` | PEM-from-app-config |
| `Relyra.KeyResolver.KMS` | `lib/relyra/key_resolver/kms.ex` | KMS documented stub |
| `Relyra.Security.XMLEnc` | `lib/relyra/security/xml_enc.ex` | XML-Enc decryption |

### Modified Modules

| Module | Change | Risk |
|--------|--------|------|
| `Relyra.Security.AlgorithmPolicy` | Add 2 new struct fields + 3 new functions | Low — additive; existing callers unaffected |
| `Relyra.Security.XML.PureBeam` | Add EncryptedAssertion detection in `build_parsed_doc/1` | Medium — touches trust-path parser |
| `Relyra.Protocol.ValidationPipeline` | Insert `:decrypt_assertion` step (no-op when absent) | Medium — changes `@ordered_stages`; insert before `:signature_verify` |
| `Relyra.Protocol.Metadata` | Add SP KeyDescriptors for encryption and signing | Low — additive XML output |
| `Relyra.Protocol.AuthnRequest` | Add `sign_redirect_params/3` | Low — new function; existing functions unchanged |
| `Relyra.Phoenix.Controllers.LoginController` | Call `sign_redirect_params` when toggle is on | Low — guarded by `sign_authn_requests` boolean |
| `Relyra.Security.Signature` | Add `sign_redirect_query/3` | Low — new function; verify paths untouched |
| `Relyra.Ecto.Certificate` | Add `party` + `use` fields | Low — backward-safe migration with defaults |
| `Relyra.Ecto.Connection` | Add `sign_authn_requests` boolean | Low — backward-safe migration `default: false` |
| `Relyra.Ecto.CertificateInventory` | Scope cert lookups by `party` + `use` where appropriate | Low — existing queries use `:signing`/`:idp` which match new defaults |

### New Migrations

| Migration | DDL summary |
|-----------|-------------|
| `add_party_use_to_certificates` | `ADD COLUMN party` + `ADD COLUMN use` with defaults `:idp` / `:signing` for all existing rows |
| `add_sign_authn_requests_to_connections` | `ADD COLUMN sign_authn_requests boolean NOT NULL DEFAULT false` |

---

## Key Seam Invariants (Do Not Violate)

### 1. One Parse Path

The decrypt step produces raw binary, then calls `PureBeam.parse_safely/2` on it -- the SAME
function that runs on plaintext responses. The pre-parse guards (DOCTYPE, ENTITY, size) run again
on the decrypted bytes. No shortcut path "because we just decrypted it" -- attackers can embed
adversarial XML inside ciphertext.

### 2. No Field Access Before Verify

`XMLEnc.decrypt/3` returns raw bytes. `PureBeam.parse_safely/2` returns a parsed_doc. `Signature.verify`
runs before any field (name_id, audiences, etc.) is accessed. The `do_run_validations` `with` chain
enforces this order structurally.

### 3. KeyResolver Never Returns DB Private Keys

`KeyResolver.Default` reads ONLY from application config. DB cert inventory rows for
`party: :sp, use: :encryption` contain PUBLIC cert material for audit/expiry tracking only --
never used to look up private keys.

### 4. AlgorithmPolicy Checks Run Before Key Operations

In `XMLEnc.decrypt/3`, the key-transport algorithm is checked against `AlgorithmPolicy` BEFORE
any call to `:public_key.decrypt_private/3`. Seeing a PKCS1v1.5 request causes an immediate
typed error -- no key material is touched.

### 5. Signature.sign_redirect_query Signs Raw Octets

The function receives the assembled query-string binary and signs EXACTLY those bytes. It does not
parse, split, or re-encode any component. Correct query-string construction (including field ordering:
SAMLRequest, RelayState, SigAlg) is the caller's responsibility in `sign_redirect_params/3`.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Field Access From Decrypted-But-Unverified Assertion

What: Accessing `name_id`, `attributes`, or any assertion field from the inner `parsed_doc` before
`Signature.verify` completes.
Why: Cipher-oracle / authentication-bypass class bug -- decrypted plaintext could be attacker-controlled
if key material is compromised.
Instead: The `with` chain in `do_run_validations` makes ordering structural; field access is only
in `login_result/5` which is only reachable after all validation steps pass.

### Anti-Pattern 2: Signing Re-serialized AuthnRequest Content

What: Calling `to_xml/1` inside `sign_redirect_query/3`, or reconstructing the query string from
components inside the signing function.
Why: Re-serialization changes the byte string. The IdP computes the signature over different bytes
and rejects the request. This exact bug exists in multiple production SAML libs.
Instead: The query-string binary is assembled ONCE in `sign_redirect_params/3` and passed verbatim
to `sign_redirect_query/3`.

### Anti-Pattern 3: Storing SP Private Key in Ecto Schema

What: Adding a `sp_decryption_key_pem` or `sp_signing_key_pem` column to `relyra_connections` or
`relyra_connection_certificates`.
Why: Private key material in a queryable DB table violates the diagnostic-surface redaction contract
and drastically increases the blast radius of a DB compromise.
Instead: Private keys in app config / secrets management only. DB cert inventory stores PUBLIC certs
for expiry tracking and admin UI display.

### Anti-Pattern 4: Processing Both Cleartext and Encrypted Assertions

What: Reading `name_id` / attributes from a cleartext `<Assertion>` when an `<EncryptedAssertion>`
is also present in the same response.
Why: The cleartext assertion could be a reflection/substitution attack payload.
Instead: `PureBeam.build_parsed_doc/1` detects simultaneous presence and emits `:ambiguous_assertion`
error. `ValidationPipeline` gates on this before the decrypt step.

### Anti-Pattern 5: New AlgorithmPolicy Fields Breaking Existing Struct Patterns

What: Changing `AlgorithmPolicy.t()` in a way that breaks existing adopter structs or test helpers.
Why: Adopters may construct `%AlgorithmPolicy{}` directly in test fixtures or config.
Instead: New fields get `nil` defaults in the struct definition. `default/0` populates them.
`from_connection/2` handles structs lacking the new fields gracefully.

---

## Sources

- Direct source reading: `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`,
  `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/protocol/validation_pipeline.ex`,
  `lib/relyra/protocol/authn_request.ex`, `lib/relyra/ecto/certificate.ex`,
  `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/phoenix/controllers/login_controller.ex`,
  `lib/relyra/protocol/metadata.ex`, `lib/relyra/connection_resolver.ex`, `lib/relyra/replay_store.ex`
- Investigation threads: `.planning/threads/encrypted-assertions-investigation.md`,
  `.planning/threads/signed-authn-requests-investigation.md`
- Project context: `.planning/PROJECT.md` (v1.3 milestone goals, constraints, key decisions)
- SAML 2.0 XML-Enc spec: Assertions and Protocols §3.3; XML-Enc §5 (key transport) + §5.2
- SAML 2.0 Bindings spec §3.4.4.1 (HTTP-Redirect binding signature construction)
- Erlang stdlib: `:public_key.decrypt_private/3`, `:crypto.crypto_one_time_aead/6`, `:public_key.sign/4`

---
*Architecture research for: Relyra v1.3 Advanced Federation*
*Researched: 2026-05-25*
