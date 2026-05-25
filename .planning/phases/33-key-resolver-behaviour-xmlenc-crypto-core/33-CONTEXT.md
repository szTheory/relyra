# Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Introduce the `Relyra.KeyResolver` behaviour (extension point for SP private key
material) and `Relyra.KeyResolver.Default` (reads PEM from application config); build
`Relyra.Security.XMLEnc` with RSA-OAEP + AES-GCM decryption behind the AlgorithmPolicy
gate. All decryption failures return a single opaque `:decryption_failed` atom — no
structured errors, no raised exceptions visible to callers.

**In scope:** `lib/relyra/key_resolver.ex` (behaviour contract), `lib/relyra/key_resolver/default.ex`
(default PEM-from-config implementation), `lib/relyra/security/xml_enc.ex` (XMLEnc.decrypt/3),
and a unit corpus validating all 4 failure paths produce the same opaque atom.

**Out of scope:** ValidationPipeline wiring (Phase 34), SP encryption `KeyDescriptor`
in metadata (Phase 34), ENC-01 adversarial corpus (Phase 34). This phase is the
crypto primitive layer only.

**Requirements closed:** ENC-04 (KeyResolver behaviour + XMLEnc crypto core).
</domain>

<decisions>
## Implementation Decisions

### KeyResolver Behaviour Structure
- **D-01:** `Relyra.KeyResolver` is defined at `lib/relyra/key_resolver.ex` — top-level
  behaviour module with a single `resolve/1` callback:
  `@callback resolve(connection :: map()) :: {:ok, pem_binary :: binary()} | {:error, Error.t()}`
  `Relyra.KeyResolver.Default` lives at `lib/relyra/key_resolver/default.ex` and reads the SP
  decryption private key from `Application.get_env(:relyra, :sp_private_key_pem)` only —
  never from any Ecto schema column.
- **D-02:** The behaviour module follows the `RequestStore` dispatch pattern: the top-level
  `KeyResolver` module has a `resolve/2` (connection, opts) public function that reads
  `Keyword.get(opts, :key_resolver, KeyResolver.Default)` and dispatches via
  `Code.ensure_loaded?/1` + `apply/3`, wrapping the result for type safety. Adopters can
  substitute custom implementations via the `:key_resolver` option.

### XMLEnc.decrypt/3 Failure Surface and Crypto Wiring
- **D-03:** `Relyra.Security.XMLEnc.decrypt/3` signature:
  `decrypt(encrypted_assertion_bytes :: binary(), key_resolver :: module(), opts :: keyword()) :: {:ok, binary()} | :decryption_failed`
  It returns `:decryption_failed` (bare atom) for ALL failure paths — policy rejection,
  wrong key, truncated GCM auth tag, malformed ciphertext. Never `{:error, %Error{}}`,
  never a raised exception visible to callers.
- **D-04:** Gate ordering inside `decrypt/3`:
  1. Parse the `<EncryptedKey>` and `<EncryptedData>` elements to extract algorithm URIs
  2. Call `AlgorithmPolicy.enforce_key_transport_algorithm/2` — reject if not allowed
  3. Call `AlgorithmPolicy.enforce_content_encryption_algorithm/2` — reject if not allowed (fires GCM auth tag length guard for tags < 16 bytes)
  4. Call `key_resolver.resolve(connection_or_opts)` to get the SP private key PEM
  5. Unwrap the content-encryption key using `:public_key.decrypt_private(encrypted_key_bytes, private_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])` — SHA-1 OAEP (the only form OTP 26-28 supports for `rsa-oaep-mgf1p`)
  6. Decrypt the assertion using `:crypto.crypto_one_time_aead/7` with the unwrapped key
  All OTP crypto calls wrapped in `rescue _ -> :decryption_failed` (mirroring the pattern in `signature.ex`).
- **D-05:** `KeyInfo` in the encrypted element is silently ignored. The private key is sourced
  exclusively from the `KeyResolver` callback — never from the document.

### Claude's Discretion
- Exact `KeyResolver.Default` behaviour when `Application.get_env(:relyra, :sp_private_key_pem)` is nil: return `{:error, Error.new(:key_not_configured, ...)}` with a hint pointing adopters to the config key.
- Whether `DiagnosticBundle` needs a new allowlist entry: the SP private key never enters the Ecto layer (config-only), so no new entry is needed. Existing `@sensitive_keys` in `audit_writer.ex` and `log_alerts.ex` remain sufficient. Implementation must not put the decoded key in telemetry metadata under any atom name.
- Unit corpus organization: 4 paths (RSA-PKCS1v1.5 input, AES-CBC input, truncated GCM tag, malformed ciphertext) should live in a new `test/security/xml_enc_test.exs` file added to the `ci.security` alias as its own `cmd mix test` subprocess.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/relyra/request_store.ex` — **primary pattern to replicate** for `KeyResolver`; behaviour contract module with dispatch function, error handling, and `adapter_not_configured` error shape. Read fully.
- `lib/relyra/request_store/default.ex` — default implementation pattern: `@behaviour Relyra.RequestStore`, `@impl true`, structured error with `:hint` for adopters.
- `lib/relyra/security/algorithm_policy.ex` — `enforce_key_transport_algorithm/2` and `enforce_content_encryption_algorithm/2` functions (Phase 32); XMLEnc must call these as first gates. Read the enforce function implementations and return-type conventions.
- `lib/relyra/security/signature.ex` — `rescue _ ->` crypto-wrapping pattern; safe failure discipline for OTP crypto calls in the auth path. Read the `do_verify/4` error-handling section.
- `lib/relyra/ecto/audit_writer.ex` — `@sensitive_keys` at lines 8-21 (includes `"private_key"`, `"private_key_pem"`); implementation must not introduce a new atom path that bypasses this.
- `lib/relyra/telemetry/handlers/log_alerts.ex` — `@sensitive_keys` at line 33 (includes `:private_key`); same constraint.
- `lib/relyra/diagnostic/allow_list.ex` — explicit allowlist for DiagnosticBundle exports; confirm no private key path exists or needs adding.
- `.planning/REQUIREMENTS.md` — ENC-04 acceptance criteria (behaviour + default + XMLEnc.decrypt/3 contract); line 50 documents RSA-OAEP SHA-256 OTP 26-28 limitation (out of scope).
- `.planning/ROADMAP.md` + `.planning/milestones/v1.3-ROADMAP.md` — Phase 33 success criteria (5 must-be-TRUE items).
- `mix.exs` — `ci.security` alias structure; new XMLEnc corpus file must be added as its own `cmd mix test` subprocess (hollow-gate fix from Phase 30).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.RequestStore` module at `lib/relyra/request_store.ex` — the **exact template** for
  `Relyra.KeyResolver`. Copy the `dispatch_*` function structure, `adapter_not_configured/2`
  error builder, `Code.ensure_loaded?/1` guard, and `try/rescue/catch` wrapper.
- `Relyra.RequestStore.Default` at `lib/relyra/request_store/default.ex` — pattern for
  `KeyResolver.Default`: `@behaviour`, `@impl true`, structured Error with `:hint` for adopters.
- `Relyra.Security.Signature.do_verify/4` — the established pattern for wrapping OTP crypto
  calls in `rescue _ ->` to prevent exceptions escaping the auth boundary.
- `AlgorithmPolicy.enforce_key_transport_algorithm/2` and `enforce_content_encryption_algorithm/2`
  (Phase 32 deliverables) — gate functions XMLEnc must call before any crypto operation.

### Established Patterns
- Behaviour contracts live at `lib/relyra/{name}.ex`; implementations at `lib/relyra/{name}/{impl}.ex`.
  No `lib/relyra/behaviours/` subdirectory — confirmed absent.
- Application config reads: `Application.get_env(:relyra, :key_name)` pattern (not `fetch_env!`).
- All OTP crypto failures in the auth path are `rescue`d and converted to opaque atoms or typed
  errors — no raw Erlang exceptions surface to callers.
- The `ci.security` alias uses one `cmd mix test test/security/specific_file_test.exs` per
  security test file (Phase 30 hollow-gate fix). New XMLEnc test file follows this pattern.

### Integration Points
- `lib/relyra/security/algorithm_policy.ex` — XMLEnc calls `enforce_key_transport_algorithm/2`
  and `enforce_content_encryption_algorithm/2` before any crypto; these functions exist (Phase 32).
- Phase 34 will call `XMLEnc.decrypt/3` from `ValidationPipeline`; the function signature
  `decrypt(bytes, key_resolver_module, opts)` must be stable.
- `lib/relyra/log.ex:11` and `audit_writer.ex:14-15` — existing sensitive-key filters;
  implementation discipline must ensure the private key never flows through these paths.
</code_context>

<specifics>
## Specific Ideas

- Config key name: `:sp_private_key_pem` — consistent with the `:_pem` suffix convention
  used in metadata and cert config keys elsewhere in the project.
- RSA-OAEP OTP call form: `:public_key.decrypt_private(ciphertext, private_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])` — this is SHA-1 OAEP (`xmlenc#rsa-oaep-mgf1p`); do NOT use `{:rsa_oaep_hash, :sha256}` (raises `{:badarg}` on OTP 26-28 per REQUIREMENTS.md line 50).
- AES-GCM decryption: `:crypto.crypto_one_time_aead(:aes_gcm, key, iv, ciphertext, aad, auth_tag, false)`.
- XMLEnc module location: `lib/relyra/security/xml_enc.ex` — parallel to `signature.ex` in the security namespace.
- 4 unit corpus cases in `test/security/xml_enc_test.exs`: (1) RSA-PKCS1v1.5 key transport, (2) AES-CBC content encryption, (3) truncated GCM auth tag (< 16 bytes), (4) malformed ciphertext. All must return `:decryption_failed`.
</specifics>

<deferred>
## Deferred Ideas

- RSA-OAEP SHA-256 support (`xmlenc11#rsa-oaep`) — explicitly out of scope per REQUIREMENTS.md
  Out of Scope table (OTP 26-28 stdlib limitation). AlgorithmPolicy already blocks with a clear error.
- XMLEnc decryption telemetry events (emitting `:relyra.xml_enc.decrypt` spans) — deferred to
  keep Phase 33 focused on the crypto primitive; Phase 34 or a later phase can add telemetry
  once the pipeline is wired. Adding telemetry in Phase 33 risks leaking timing channels through
  measurement metadata if not carefully reviewed.
- ECDH-ES key transport — explicitly out of v1.3 scope per REQUIREMENTS.md.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
