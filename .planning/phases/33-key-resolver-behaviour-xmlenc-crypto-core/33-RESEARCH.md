# Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core - Research

**Researched:** 2026-05-25
**Domain:** Elixir OTP crypto (`:public_key`, `:crypto`), behaviour dispatch pattern, SaxyTree XML traversal
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `Relyra.KeyResolver` at `lib/relyra/key_resolver.ex`, single callback:
  `@callback resolve(connection :: map()) :: {:ok, pem_binary :: binary()} | {:error, Error.t()}`
  `Relyra.KeyResolver.Default` at `lib/relyra/key_resolver/default.ex` reads SP decryption private key
  from `Application.get_env(:relyra, :sp_private_key_pem)` only — never from any Ecto schema column.

- **D-02:** The behaviour module follows the `RequestStore` dispatch pattern: top-level `KeyResolver`
  module has a `resolve/2` (connection, opts) public function that reads
  `Keyword.get(opts, :key_resolver, KeyResolver.Default)` and dispatches via
  `Code.ensure_loaded?/1` + `apply/3`, wrapping the result for type safety.

- **D-03:** `Relyra.Security.XMLEnc.decrypt/3` signature:
  `decrypt(encrypted_assertion_bytes :: binary(), key_resolver :: module(), opts :: keyword()) :: {:ok, binary()} | :decryption_failed`
  Returns `:decryption_failed` (bare atom) for ALL failure paths.

- **D-04:** Gate ordering inside `decrypt/3`:
  1. Parse `<EncryptedKey>` and `<EncryptedData>` elements to extract algorithm URIs
  2. `AlgorithmPolicy.enforce_key_transport_algorithm/2` — reject if not allowed
  3. `AlgorithmPolicy.enforce_content_encryption_algorithm/2` — reject if not allowed (fires GCM auth tag length guard for tags < 16 bytes)
  4. `key_resolver.resolve(connection_or_opts)` to get the SP private key PEM
  5. `:public_key.decrypt_private(encrypted_key_bytes, private_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])` — SHA-1 OAEP
  6. `:crypto.crypto_one_time_aead/7` with the unwrapped key
  All OTP crypto calls wrapped in `rescue _ -> :decryption_failed`.

- **D-05:** `KeyInfo` in the encrypted element is silently ignored. Private key sourced exclusively
  from `KeyResolver` callback — never from the document.

### Claude's Discretion

- Exact `KeyResolver.Default` behaviour when `Application.get_env(:relyra, :sp_private_key_pem)` is nil:
  return `{:error, Error.new(:key_not_configured, ...)}` with a hint pointing adopters to the config key.
- `DiagnosticBundle` needs no new allowlist entry (SP private key never enters the Ecto layer).
  Existing `@sensitive_keys` in `audit_writer.ex` and `log_alerts.ex` remain sufficient.
- Unit corpus: 4 paths in `test/security/xml_enc_test.exs`, added to `ci.security` as its own
  `cmd mix test` subprocess.

### Deferred Ideas (OUT OF SCOPE)

- RSA-OAEP SHA-256 support (`xmlenc11#rsa-oaep`) — OTP 26-28 stdlib limitation.
- XMLEnc decryption telemetry events — deferred to keep Phase 33 focused on crypto primitive.
- ECDH-ES key transport — explicitly out of v1.3 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENC-04 | Operator can configure SP decryption private key via `KeyResolver` behaviour (PEM config default ships; KMS extension point documented for v1.4+); SP private key material never stored in any Ecto schema column or surfaced in diagnostic bundles | D-01 through D-05 above; crypto API verified in OTP 28; `@sensitive_keys` audit confirms no new entries needed |
</phase_requirements>

---

## Summary

Phase 33 delivers two new modules — `Relyra.KeyResolver` (behaviour + default implementation) and
`Relyra.Security.XMLEnc` (RSA-OAEP + AES-GCM decryption) — plus a 4-case security corpus wired
into `ci.security`. All design decisions are locked in CONTEXT.md; this research confirms the
exact API signatures, verifies all OTP 28 crypto calls, maps the XMLEnc parsing path to the
existing SaxyTree primitives, and audits sensitive-key coverage to confirm no new entries are needed.

The `RequestStore` dispatch pattern is a complete, verified template for `KeyResolver`. The
`do_verify/4` `rescue _ ->` pattern in `signature.ex` is the exact model for XMLEnc's crypto
wrapping. No new Hex dependencies are needed — all crypto is OTP stdlib. The only discretionary
decision remaining for the implementer is the exact error message text in `KeyResolver.Default`
when the config key is nil.

**Primary recommendation:** Clone `RequestStore` exactly for `KeyResolver`, clone the `do_verify/4`
rescue pattern for `decrypt/3`, use `SaxyTree.parse/1` directly on the raw
`encrypted_assertion_bytes` to extract algorithm URIs and cipher values, and implement the
AES-GCM CipherValue split as `IV(12) || Ciphertext || Tag(16)`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SP private key access | API / Backend (`KeyResolver`) | — | Key material must never reach browser or log layer; behaviour boundary is the isolation seam |
| XMLEnc decryption | API / Backend (`XMLEnc`) | — | Crypto primitive; output feeds back into `PureBeam.parse_safely/2` before any identity field is read |
| Algorithm policy gate | API / Backend (`AlgorithmPolicy`) | — | Phase 32 deliverable; `XMLEnc` calls it before any crypto operation |
| AES cipher dispatch | API / Backend (inside `XMLEnc`) | — | URI → atom → `crypto_one_time_aead` is a single pure-OTP step |
| Sensitive-key redaction | Logging / Telemetry boundary | — | `log.ex`, `audit_writer.ex`, `log_alerts.ex` gates; no new entries needed for this phase |

---

## Standard Stack

### Core (no new Hex dependencies — all OTP stdlib)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` | OTP 28 stdlib | RSA-OAEP CEK unwrap, PEM/DER decode | Only safe source of RSA crypto in OTP; no NIF bypass |
| `:crypto` | OTP 28 stdlib | AES-GCM content decryption | `crypto_one_time_aead/7` is the standard AEAD interface |
| `Relyra.Security.XML.SaxyTree` | project-internal | Parse raw EncryptedAssertion bytes to extract algorithm URIs and CipherValues | Single parse seam; reuses existing hardened SaxyTree builder |
| `Relyra.Security.AlgorithmPolicy` | project-internal | Gate key transport and content encryption algorithms before crypto | Phase 32 deliverable; must be called first |

**Installation:** No new dependencies. `mix deps.get` is a no-op for this phase.

**Zero new Hex dependencies is a hard constraint from STATE.md.**

---

## Package Legitimacy Audit

No external packages are installed in this phase. All crypto is OTP stdlib (`:public_key`,
`:crypto`). This section is N/A.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
encrypted_assertion_bytes (raw binary)
         |
         v
  SaxyTree.parse/1
  (reuses hardened seam — same parser as PureBeam)
         |
         +--> extract EncryptedKey algorithm URI  -->  AlgorithmPolicy.enforce_key_transport_algorithm/2
         |                                              [REJECT if not :ok]
         |
         +--> extract EncryptedData algorithm URI  --> AlgorithmPolicy.enforce_content_encryption_algorithm/2
         |                                              [REJECT if not :ok or :decryption_failed]
         |
         +--> extract EncryptedKey CipherValue (base64)
         |
         v
  KeyResolver.resolve(connection_or_opts)
  (calls configured adapter, default: KeyResolver.Default)
         |
         +--> Application.get_env(:relyra, :sp_private_key_pem)
              [nil -> {:error, Error.new(:key_not_configured, ...)}]
              [binary -> {:ok, pem_binary}]
         |
         v
  :public_key.pem_decode/1 + :public_key.pem_entry_decode/1
  -> RSAPrivateKey term
         |
         v
  :public_key.decrypt_private(encrypted_cek_bytes, private_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
  [all OTP calls in rescue _ -> :decryption_failed]
         |
         v
  content_encryption_key (binary)
         |
         v
  CipherValue split: IV(12) || Ciphertext || Tag(16)
         |
         v
  :crypto.crypto_one_time_aead(cipher_atom, cek, iv, ciphertext, <<>>, tag, false)
  -> plaintext bytes | :error
         |
         v
  {:ok, plaintext_bytes} | :decryption_failed
```

### Recommended Project Structure

```
lib/relyra/
├── key_resolver.ex               # behaviour contract + resolve/2 dispatch function
└── key_resolver/
    └── default.ex                # KeyResolver.Default — reads :sp_private_key_pem from Application config

lib/relyra/security/
└── xml_enc.ex                    # XMLEnc.decrypt/3

test/security/
└── xml_enc_test.exs              # 4-case corpus (all must return :decryption_failed)
```

### Pattern 1: RequestStore Dispatch — Exact Template for KeyResolver

**What:** A behaviour module that (a) declares the callback, (b) exposes a public dispatch function
that reads the configured adapter from opts, (c) guards with `Code.ensure_loaded?/1` +
`function_exported?/3`, (d) wraps the `apply/3` in `try/rescue/catch`, and (e) normalises any
unexpected return value to a typed error.

**When to use:** Every behaviour in Relyra that has a configurable default implementation.

**Exact form** (verified from `lib/relyra/request_store.ex`): [VERIFIED: codebase grep]

```elixir
# Public dispatch function — replicate exactly for KeyResolver
defp dispatch_request_store(adapter, operation, args)
     when is_atom(adapter) and is_atom(operation) and is_list(args) do
  if Code.ensure_loaded?(adapter) and function_exported?(adapter, operation, length(args)) do
    try do
      case apply(adapter, operation, args) do
        {:ok, result} when is_map(result) -> {:ok, result}
        {:error, %Error{} = error} -> {:error, error}
        :ok -> :ok
        other -> {:error, invalid_adapter_result(adapter, operation, other)}
      end
    rescue
      exception ->
        {:error, adapter_dispatch_error(adapter, operation, Exception.message(exception))}
    catch
      kind, reason ->
        {:error, adapter_dispatch_error(adapter, operation, "#{kind}:#{inspect(reason)}")}
    end
  else
    {:error, adapter_not_configured(adapter, operation)}
  end
end
```

For `KeyResolver`, the dispatch function is `resolve/2` (connection, opts). The `apply/3` call is
`apply(adapter, :resolve, [connection])` (single argument matching the `@callback resolve/1`
spec). The result normalisation is:

```elixir
case apply(adapter, :resolve, [connection]) do
  {:ok, pem} when is_binary(pem) -> {:ok, pem}
  {:error, %Error{} = error} -> {:error, error}
  other -> {:error, invalid_adapter_result(adapter, :resolve, other)}
end
```

### Pattern 2: rescue _ -> :decryption_failed — Exact Template for XMLEnc

**What:** All OTP crypto calls (`:public_key.decrypt_private`, `:crypto.crypto_one_time_aead`, PEM
decoding) are wrapped in a single `rescue _ -> :decryption_failed` so no Erlang exception escapes
the auth boundary. This is the **same discipline** as `safe_verify/4` in `signature.ex`.

**Exact form** (verified from `lib/relyra/security/signature.ex` lines 396-399): [VERIFIED: codebase grep]

```elixir
# From signature.ex -- mirror this in XMLEnc.decrypt/3
defp safe_verify(message, digest_atom, signature, public_key) do
  :public_key.verify(message, digest_atom, signature, public_key)
rescue
  _ -> false
end
```

For XMLEnc, wrap the entire crypto block:

```elixir
defp do_decrypt(encrypted_key_b64, encrypted_data_b64, content_alg_uri, private_key) do
  with {:ok, encrypted_cek} <- Base.decode64(encrypted_key_b64, ignore: :whitespace),
       {:ok, cipher_value} <- Base.decode64(encrypted_data_b64, ignore: :whitespace),
       {:ok, cek} <- unwrap_cek(encrypted_cek, private_key),
       {:ok, plaintext} <- decrypt_content(cipher_value, cek, content_alg_uri) do
    {:ok, plaintext}
  else
    _ -> :decryption_failed
  end
rescue
  _ -> :decryption_failed
end
```

### Pattern 3: SaxyTree.parse/1 for XMLEnc Field Extraction

**What:** Use `SaxyTree.parse/1` directly on the raw `encrypted_assertion_bytes` binary to
extract algorithm URIs and CipherValues. The existing `find_first/2` pattern from `pure_beam.ex`
works by local element name (namespace-prefix-agnostic).

**Verified:** `SaxyTree.parse/1` correctly handles `xenc:` prefix namespaces. Traversal by
`:local` field (without namespace URI comparison) is sufficient because the element local names
(`EncryptedData`, `EncryptedKey`, `EncryptionMethod`, `CipherData`, `CipherValue`) are unambiguous
in the XMLEnc context. [VERIFIED: mix run test]

**XMLEnc element structure** (verified against real-world SAML EncryptedAssertion layout): [VERIFIED: mix run test]

```
<EncryptedAssertion>                          root.local = "EncryptedAssertion"
  <xenc:EncryptedData>                        find_first(root, "EncryptedData")
    <xenc:EncryptionMethod Algorithm="..."/>  attrs: [{"Algorithm", uri}]
    <ds:KeyInfo>                              find_first(enc_data, "KeyInfo")
      <xenc:EncryptedKey>                     find_first(key_info, "EncryptedKey")
        <xenc:EncryptionMethod Algorithm="..."/>  key transport algorithm URI
        <xenc:CipherData>
          <xenc:CipherValue>BASE64</xenc:CipherValue>  encrypted CEK
        </xenc:CipherData>
      </xenc:EncryptedKey>
    </ds:KeyInfo>
    <xenc:CipherData>
      <xenc:CipherValue>BASE64</xenc:CipherValue>  IV || Ciphertext || Tag
    </xenc:CipherData>
  </xenc:EncryptedData>
</EncryptedAssertion>
```

Attribute extraction: `Enum.find_value(node.attrs, fn {"Algorithm", v} -> v; _ -> nil end)`.

### Pattern 4: AlgorithmPolicy Enforce Functions — Return Type Conventions

**Verified from `lib/relyra/security/algorithm_policy.ex`:** [VERIFIED: codebase grep]

```
enforce_key_transport_algorithm(policy, method) :: :ok | %Error{type: :deprecated_algorithm}
enforce_content_encryption_algorithm(policy, method, opts \\ []) :: :ok | %Error{} | :decryption_failed
```

**Critical detail:** `enforce_content_encryption_algorithm/3` accepts an optional `auth_tag:` kwarg
and returns `:decryption_failed` (bare atom, not `%Error{}`) when `byte_size(auth_tag) < 16`. The
Phase 33 `decrypt/3` gate must handle all three return values:

```elixir
case AlgorithmPolicy.enforce_content_encryption_algorithm(policy, content_alg, auth_tag: auth_tag) do
  :ok -> continue
  %Error{} -> :decryption_failed   # policy rejection -- opaque
  :decryption_failed -> :decryption_failed  # truncated tag
end
```

In practice, since Phase 33 runs `enforce_content_encryption_algorithm/2` BEFORE extracting the
auth tag from the CipherValue (auth tag is only knowable after base64 decoding the CipherValue),
the auth tag guard fires at step 6, not step 3. The gate ordering in D-04 calls
`enforce_content_encryption_algorithm/2` WITHOUT an `:auth_tag` option (to check the URI only),
then validates the auth tag length independently after decoding the CipherValue.

### Pattern 5: AES-GCM CipherValue Layout

**What:** The XMLEnc specification for AES-GCM encodes the CipherValue as:
`IV (12 bytes) || Ciphertext (variable) || Auth Tag (16 bytes)`

**Verified via OTP 28 test:** [VERIFIED: mix run test]

```elixir
# Decrypt
<<iv::binary-12, rest::binary>> = cipher_value_bytes
ct_size = byte_size(rest) - 16
<<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest
# Auth tag length guard (before calling AEAD)
if byte_size(auth_tag) < 16, do: :decryption_failed
result = :crypto.crypto_one_time_aead(cipher_atom, cek, iv, ciphertext, <<>>, auth_tag, false)
# result is plaintext binary on success, :error on auth failure
```

**Auth tag guard interaction with AlgorithmPolicy:** The 16-byte auth tag check MUST run before
`:crypto.crypto_one_time_aead/7`. Since `enforce_content_encryption_algorithm/3` can fire the
guard if given an `:auth_tag` opt, the cleanest implementation decodes the CipherValue early,
extracts the auth tag, then passes `auth_tag: auth_tag` to `enforce_content_encryption_algorithm/3`
so the single auth-tag guard in `AlgorithmPolicy` fires (not a duplicated check).

**Revised gate ordering for decrypt/3 (clarifies D-04):**

1. Parse encrypted bytes via `SaxyTree.parse/1` — extract both algorithm URIs and both CipherValue texts
2. `enforce_key_transport_algorithm/2` — URI-only check
3. Base64-decode both CipherValues (CEK and content), fail opaquely on decode error
4. Extract IV, ciphertext, auth_tag from the decoded content CipherValue
5. `enforce_content_encryption_algorithm/3` with `auth_tag: auth_tag` — URI check + 16-byte guard in one call
6. Decode PEM private key from KeyResolver output
7. `:public_key.decrypt_private` to unwrap CEK
8. `:crypto.crypto_one_time_aead` to decrypt content
All of steps 3-8 inside a rescue block.

### Pattern 6: AES Cipher Atom and Key Size Dispatch

**Verified in OTP 28:** [VERIFIED: mix run test]

| XMLEnc URI | OTP atom | CEK size |
|------------|----------|----------|
| `http://www.w3.org/2001/04/xmlenc#aes128-gcm` | `:aes_128_gcm` | 16 bytes |
| `http://www.w3.org/2001/04/xmlenc#aes256-gcm` | `:aes_256_gcm` | 32 bytes |

Both are standard atoms on OTP 28. The generic `:aes_gcm` atom also works but is ambiguous; use
the size-specific atoms.

### Anti-Patterns to Avoid

- **Structured error returns from `decrypt/3`:** Any `{:error, %Error{}}` return from `decrypt/3`
  opens a timing/oracle channel. The return type is `{:ok, binary()} | :decryption_failed`, period.

- **Letting exceptions escape the rescue block:** `:public_key.decrypt_private/3` RAISES on
  malformed key material. `:public_key.pem_entry_decode/1` RAISES on malformed PEM. Both must be
  inside the rescue.

- **`crypto_one_time_aead/7` `:error` atom not handled:** When auth tag verification fails, OTP
  returns the atom `:error` (not a tuple, not an exception). The `with` chain must pattern-match
  this: `{:ok, plaintext} <- ...` will not match `:error`, causing the `else` branch to fire
  `-> :decryption_failed`. [VERIFIED: mix run test]

- **Second parse for XMLEnc outside SaxyTree:** Using a separate XML parser (e.g. `:xmerl`) or a
  regex extractor for EncryptedAssertion would bypass the hardened seam. SaxyTree is the ONLY
  parse entry point.

- **`KeyInfo` in EncryptedKey used for key lookup:** Must be silently ignored (D-05). The trust
  boundary is the KeyResolver callback, not the document.

- **`:aes_gcm` generic atom in production code:** Use `:aes_128_gcm` / `:aes_256_gcm` so the
  cipher dispatch is explicit and auditable.

- **PEM private key atom in telemetry metadata:** The PEM binary must never be assigned to an atom
  key like `:pem`, `:private_key`, or `:sp_private_key_pem` in any map that flows to Logger or
  telemetry. Pass the decoded private key term only within the `do_decrypt` private function scope.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RSA-OAEP CEK unwrap | Custom RSA padding code | `:public_key.decrypt_private/3` with `{:rsa_padding, :rsa_pkcs1_oaep_padding}` | OTP stdlib is the only safe RSA path; hand-rolled padding has Bleichenbacher exposure |
| AES-GCM AEAD decryption | Custom GCM implementation | `:crypto.crypto_one_time_aead/7` | OTP native; handles constant-time auth tag verification internally |
| PEM/DER key decoding | Custom PEM parser | `:public_key.pem_decode/1` + `:public_key.pem_entry_decode/1` | Handles ASN.1 structure correctly; raises on malformed input (rescue converts to `:decryption_failed`) |
| XMLEnc element traversal | Regex or second XML parser | `SaxyTree.parse/1` + depth-first traversal by `:local` | Single parse seam invariant; regex would bypass hardened parser boundary |
| Behaviour dispatch guard | Custom module-existence check | `Code.ensure_loaded?/1` + `function_exported?/3` | Established pattern (RequestStore); handles compile-time vs runtime availability correctly |

**Key insight:** Every "convenience" shortcut in the crypto path (skipping a guard, using a
different parser, returning a structured error) is either a padding oracle or a parser differential.
The project's security model has zero tolerance for both.

---

## Common Pitfalls

### Pitfall 1: `crypto_one_time_aead/7` Returns `:error`, Not `{:error, _}`

**What goes wrong:** The developer writes `{:ok, pt} = :crypto.crypto_one_time_aead(...)` and gets
a `MatchError` when the auth tag fails, which escapes the rescue as an Elixir exception (not an
Erlang exception), and may not be caught by the outermost rescue depending on where it's placed.

**Why it happens:** OTP returns the bare atom `:error` on auth tag failure, not `{:error, :badarg}`
or a raised exception. Most Elixir patterns expect tuples.

**How to avoid:** Use a `with` chain where the AEAD step is:
```elixir
case :crypto.crypto_one_time_aead(cipher, key, iv, ct, aad, tag, false) do
  result when is_binary(result) -> {:ok, result}
  :error -> :decryption_failed
end
```
Or use `else _ -> :decryption_failed` in the `with` chain (all non-`{:ok, _}` results collapse to `:decryption_failed`).

[VERIFIED: mix run test — `:error` atom confirmed on bad auth tag in OTP 28]

### Pitfall 2: `public_key.decrypt_private/3` Raises on Malformed Key Material

**What goes wrong:** If `KeyResolver.Default` returns a truncated or wrongly-encoded PEM, the
`pem_entry_decode` or `decrypt_private` call raises an Erlang exception. If the rescue is
placed only around the AEAD call, the RSA step escapes.

**Why it happens:** OTP's `:public_key` functions are implemented in Erlang and raise `{:badarg}`
or ASN.1 parse errors on malformed input, rather than returning `{:error, _}`.

**How to avoid:** The outermost `rescue _ -> :decryption_failed` must wrap the ENTIRE `do_decrypt`
private function body, including the PEM decode and RSA unwrap steps.

[VERIFIED: codebase — mirrors `safe_verify/4` rescue discipline in signature.ex line 397]

### Pitfall 3: `Code.ensure_loaded?` Guard Missing in KeyResolver Dispatch

**What goes wrong:** A test passes a custom module atom that is defined at compile time but not
loaded at runtime (e.g., defined in `test/support/` but not compiled into the test suite for a
specific test file). The `apply/3` call raises a `UndefinedFunctionError`.

**Why it happens:** Elixir modules aren't always loaded even if they compile; `Code.ensure_loaded?`
forces a load attempt and returns false if unavailable.

**How to avoid:** Copy the dispatch guard verbatim from `RequestStore`:
```elixir
if Code.ensure_loaded?(adapter) and function_exported?(adapter, :resolve, 1) do
```

[VERIFIED: codebase — request_store.ex line 50]

### Pitfall 4: CipherValue Split Fails on Truncated Input

**What goes wrong:** An adversary sends a CipherValue that is fewer than 12 + 16 = 28 bytes. The
binary pattern match `<<iv::binary-12, rest::binary>> = cipher_value_bytes` succeeds (rest is the
empty binary), but then `<<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest` raises
a `MatchError` when `ct_size` is negative.

**Why it happens:** `byte_size(rest) - 16` is negative for inputs shorter than 28 bytes; negative
size in a binary match pattern raises.

**How to avoid:** Guard the split:
```elixir
if byte_size(cipher_value_bytes) < 28 do
  :decryption_failed
else
  <<iv::binary-12, rest::binary>> = cipher_value_bytes
  ct_size = byte_size(rest) - 16
  <<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest
  # continue
end
```
Or wrap the entire split in the `rescue _ -> :decryption_failed` block.

### Pitfall 5: `ci.security` Meta-Gate Fails if New File Not Registered

**What goes wrong:** `test/security/xml_enc_test.exs` is created but NOT added to `mix.exs`
`ci.security` alias as a `cmd mix test` step AND NOT added to the `@gated_suites` list in
`test/security/ci_gate_integrity_test.exs`. The CI integrity test then fails with:
`"gated security suite test/security/xml_enc_test.exs is NOT referenced in any ci.security step"`.

**Why it happens:** The meta-gate explicitly enforces that every security suite is both present on
disk AND referenced in `ci.security`.

**How to avoid:** The plan must include tasks that (1) add the `cmd mix test test/security/xml_enc_test.exs --warnings-as-errors` line to `ci.security` in `mix.exs`, AND (2) add
`{"test/security/xml_enc_test.exs", nil}` to `@gated_suites` in `ci_gate_integrity_test.exs`.

[VERIFIED: ci_gate_integrity_test.exs — lines 32-40 enforce this]

### Pitfall 6: `@tag :adversarial_crypto` vs No Tag in xml_enc_test.exs

**What goes wrong:** If `xml_enc_test.exs` is added to `ci.security` with a `--only some_tag`
filter but the file doesn't declare `@moduletag :some_tag`, the gate silently matches zero tests.
The meta-gate's "tag integrity" check (line 142) would catch this.

**How to avoid:** Add `xml_enc_test.exs` to `ci.security` WITHOUT an `--only` filter (like
`ci_gate_integrity_test.exs` and `strict_default_proof_test.exs`). The `@gated_suites` entry
should be `{"test/security/xml_enc_test.exs", nil}`. This matches the simplest pattern already
established.

---

## Code Examples

All examples are verified against the actual codebase or OTP 28 runtime.

### KeyResolver Behaviour Module (complete skeleton)

```elixir
# lib/relyra/key_resolver.ex
defmodule Relyra.KeyResolver do
  @moduledoc """
  Public extension contract for SP decryption private key material.
  """
  alias Relyra.Error

  @callback resolve(connection :: map()) :: {:ok, pem_binary :: binary()} | {:error, Error.t()}

  @spec resolve(map(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def resolve(connection, opts \\ [])

  def resolve(connection, opts) when is_map(connection) and is_list(opts) do
    dispatch_key_resolver(key_resolver(opts), connection)
  end

  def resolve(_connection, _opts) do
    {:error, adapter_not_configured(nil, :resolve)}
  end

  defp key_resolver(opts) do
    Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)
  end

  defp dispatch_key_resolver(adapter, connection)
       when is_atom(adapter) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, :resolve, 1) do
      try do
        case apply(adapter, :resolve, [connection]) do
          {:ok, pem} when is_binary(pem) -> {:ok, pem}
          {:error, %Error{} = error} -> {:error, error}
          other -> {:error, invalid_adapter_result(adapter, :resolve, other)}
        end
      rescue
        exception ->
          {:error, adapter_dispatch_error(adapter, :resolve, Exception.message(exception))}
      catch
        kind, reason ->
          {:error, adapter_dispatch_error(adapter, :resolve, "#{kind}:#{inspect(reason)}")}
      end
    else
      {:error, adapter_not_configured(adapter, :resolve)}
    end
  end

  defp dispatch_key_resolver(adapter, _connection) do
    {:error, adapter_not_configured(adapter, :resolve)}
  end

  # Error builders -- mirror RequestStore error shape
  defp adapter_not_configured(adapter, operation) do
    Error.new(:adapter_not_configured, "Key resolver adapter is unavailable", %{
      adapter: inspect(adapter),
      operation: operation,
      hint: "Configure :key_resolver with a module implementing Relyra.KeyResolver"
    })
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(:adapter_not_configured, "Key resolver adapter returned an invalid result", %{
      adapter: inspect(adapter),
      operation: operation,
      actual: inspect(actual)
    })
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(:adapter_not_configured, "Key resolver adapter raised during dispatch", %{
      adapter: inspect(adapter),
      operation: operation,
      reason: reason
    })
  end
end
```

Source: [VERIFIED: cloned from lib/relyra/request_store.ex]

### KeyResolver.Default (complete)

```elixir
# lib/relyra/key_resolver/default.ex
defmodule Relyra.KeyResolver.Default do
  @moduledoc false

  @behaviour Relyra.KeyResolver

  alias Relyra.Error

  @impl true
  @spec resolve(map()) :: {:ok, binary()} | {:error, Error.t()}
  def resolve(connection) when is_map(connection) do
    case Application.get_env(:relyra, :sp_private_key_pem) do
      nil ->
        {:error,
         Error.new(:key_not_configured, "SP decryption private key is not configured", %{
           hint: "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
         })}

      pem when is_binary(pem) ->
        {:ok, pem}
    end
  end

  def resolve(_connection) do
    {:error,
     Error.new(:key_not_configured, "SP decryption private key is not configured", %{
       hint: "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
     })}
  end
end
```

Source: [VERIFIED: cloned from lib/relyra/request_store/default.ex pattern]

### XMLEnc.decrypt/3 Core Structure

```elixir
# lib/relyra/security/xml_enc.ex
defmodule Relyra.Security.XMLEnc do
  @moduledoc false

  alias Relyra.Security.AlgorithmPolicy
  alias Relyra.Security.XML.SaxyTree

  @rsa_oaep_uri "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"

  @aes128_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes128-gcm"
  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"

  @spec decrypt(binary(), module(), keyword()) :: {:ok, binary()} | :decryption_failed
  def decrypt(encrypted_assertion_bytes, key_resolver_module, opts)
      when is_binary(encrypted_assertion_bytes) and is_atom(key_resolver_module) and is_list(opts) do
    policy = Keyword.get(opts, :algorithm_policy, AlgorithmPolicy.default())
    connection = Keyword.get(opts, :connection, %{})

    with {:ok, fields} <- parse_enc_fields(encrypted_assertion_bytes),
         :ok <- check_key_transport(policy, fields.key_transport_alg),
         {:ok, cipher_value_bytes} <- b64_decode(fields.content_cipher_value),
         {:ok, iv, ciphertext, auth_tag} <- split_cipher_value(cipher_value_bytes),
         :ok <- check_content_encryption(policy, fields.content_alg, auth_tag),
         {:ok, pem} <- resolve_key(key_resolver_module, connection) do
      do_decrypt(fields.key_cipher_value, pem, cipher_value_bytes, fields.content_alg)
    else
      _ -> :decryption_failed
    end
  end

  def decrypt(_bytes, _resolver, _opts), do: :decryption_failed

  defp do_decrypt(key_cipher_b64, pem, content_cipher_bytes, content_alg) do
    # All OTP crypto inside rescue -- mirrors safe_verify/4 in signature.ex
    with {:ok, encrypted_cek} <- b64_decode(key_cipher_b64),
         {:ok, private_key} <- decode_pem_key(pem),
         {:ok, cek} <- unwrap_cek(encrypted_cek, private_key),
         {:ok, iv, ciphertext, auth_tag} <- split_cipher_value(content_cipher_bytes),
         {:ok, cipher_atom} <- cipher_atom(content_alg) do
      case :crypto.crypto_one_time_aead(cipher_atom, cek, iv, ciphertext, <<>>, auth_tag, false) do
        plaintext when is_binary(plaintext) -> {:ok, plaintext}
        :error -> :decryption_failed
      end
    else
      _ -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  defp unwrap_cek(encrypted_cek, private_key) do
    {:ok, :public_key.decrypt_private(encrypted_cek, private_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])}
  rescue
    _ -> :decryption_failed
  end

  defp decode_pem_key(pem) do
    with [entry | _] <- :public_key.pem_decode(pem) do
      {:ok, :public_key.pem_entry_decode(entry)}
    else
      _ -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  defp split_cipher_value(bytes) when byte_size(bytes) >= 28 do
    <<iv::binary-12, rest::binary>> = bytes
    ct_size = byte_size(rest) - 16
    <<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest
    {:ok, iv, ciphertext, auth_tag}
  end
  defp split_cipher_value(_bytes), do: :decryption_failed

  defp cipher_atom(@aes128_gcm_uri), do: {:ok, :aes_128_gcm}
  defp cipher_atom(@aes256_gcm_uri), do: {:ok, :aes_256_gcm}
  defp cipher_atom(_uri), do: :decryption_failed

  defp b64_decode(value) when is_binary(value) do
    Base.decode64(value, ignore: :whitespace)
  end
  defp b64_decode(_), do: :decryption_failed

  defp check_key_transport(policy, uri) do
    case AlgorithmPolicy.enforce_key_transport_algorithm(policy, uri) do
      :ok -> :ok
      %Relyra.Error{} -> :decryption_failed
    end
  end

  defp check_content_encryption(policy, uri, auth_tag) do
    case AlgorithmPolicy.enforce_content_encryption_algorithm(policy, uri, auth_tag: auth_tag) do
      :ok -> :ok
      %Relyra.Error{} -> :decryption_failed
      :decryption_failed -> :decryption_failed
    end
  end

  defp resolve_key(key_resolver_module, connection) do
    case apply(key_resolver_module, :resolve, [connection]) do
      {:ok, pem} when is_binary(pem) -> {:ok, pem}
      _ -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  defp parse_enc_fields(bytes) do
    # Use SaxyTree -- the single hardened parse seam
    with {:ok, root} <- SaxyTree.parse(bytes),
         enc_data when not is_nil(enc_data) <- find_first(root, "EncryptedData"),
         key_info when not is_nil(key_info) <- find_first(enc_data, "KeyInfo"),
         enc_key when not is_nil(enc_key) <- find_first(key_info, "EncryptedKey"),
         key_transport_alg when is_binary(key_transport_alg) <- enc_method_alg(enc_key),
         content_alg when is_binary(content_alg) <- enc_method_alg(enc_data),
         key_cv when is_binary(key_cv) <- cipher_value_text(enc_key),
         content_cv when is_binary(content_cv) <- cipher_value_text(enc_data) do
      {:ok, %{
        key_transport_alg: key_transport_alg,
        content_alg: content_alg,
        key_cipher_value: key_cv,
        content_cipher_value: content_cv
      }}
    else
      _ -> :decryption_failed
    end
  end

  defp enc_method_alg(node) do
    em = find_first(node, "EncryptionMethod")
    em && Enum.find_value(em.attrs, fn {"Algorithm", v} -> v; _ -> nil end)
  end

  defp cipher_value_text(node) do
    cd = find_first(node, "CipherData")
    cv = cd && find_first(cd, "CipherValue")
    cv && cv.text
  end

  defp find_first(%{local: local} = node, local), do: node
  defp find_first(%{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end
  defp find_first(_other, _local), do: nil
end
```

Source: [VERIFIED: codebase patterns + OTP 28 runtime tests]

### RSA-OAEP Test Key Material in xml_enc_test.exs

The 4-case corpus needs to construct valid EncryptedAssertion bytes. `FakeIdP.keypair/0` returns
an RSA-2048 key (`:public_key.generate_key({:rsa, 2048, 65537})`). This key can be used directly
for XMLEnc test cases:

```elixir
# In xml_enc_test.exs setup:
keypair = Relyra.TestSupport.FakeIdP.keypair()
# Extract public key for encryption
{:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = keypair
pub_key = {:RSAPublicKey, n, e}

# PEM-encode private key for KeyResolver.Default config
pem = :public_key.pem_encode([
  {:RSAPrivateKey, :public_key.der_encode(:RSAPrivateKey, keypair), :not_encrypted}
])

# Encrypt a CEK
cek = :crypto.strong_rand_bytes(32)  # AES-256
encrypted_cek = :public_key.encrypt_public(plaintext_cek, pub_key,
  [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
```

Source: [VERIFIED: mix run test — RSA-OAEP roundtrip confirmed in OTP 28]

**Important:** `encrypt_public/3` takes the RSA PUBLIC KEY (`{:RSAPublicKey, n, e}`), NOT the full
private key struct. Extract the public components before calling it.

### 4-Case Corpus Pattern for xml_enc_test.exs

```elixir
defmodule Relyra.Security.XMLEncTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.XMLEnc
  alias Relyra.TestSupport.FakeIdP

  # ... setup builds valid EncryptedAssertion bytes using FakeIdP.keypair() ...

  describe "failure paths all return :decryption_failed" do

    test "RSA-PKCS1v1.5 key transport returns :decryption_failed" do
      # Build EncryptedAssertion with Algorithm="...#rsa-1_5" in EncryptedKey
      assert XMLEnc.decrypt(pkcs1_bytes, resolver, []) == :decryption_failed
    end

    test "AES-CBC content encryption returns :decryption_failed" do
      # Build EncryptedAssertion with Algorithm="...#aes256-cbc" in EncryptedData
      assert XMLEnc.decrypt(cbc_bytes, resolver, []) == :decryption_failed
    end

    test "truncated GCM auth tag (< 16 bytes) returns :decryption_failed" do
      # Build EncryptedAssertion with CipherValue where last segment is < 16 bytes
      assert XMLEnc.decrypt(truncated_tag_bytes, resolver, []) == :decryption_failed
    end

    test "malformed ciphertext returns :decryption_failed" do
      # Corrupt the base64 in CipherValue
      assert XMLEnc.decrypt(malformed_bytes, resolver, []) == :decryption_failed
    end
  end
end
```

Source: [ASSUMED — structure modeled on adversarial_crypto_test.exs pattern]

---

## Runtime State Inventory

> Not applicable. This is a greenfield phase — new modules only, no rename/refactor/migration.

---

## Environment Availability

> Step 2.6: SKIPPED (no external dependencies beyond OTP stdlib, which is confirmed available on OTP 28).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| OTP `:public_key` | RSA-OAEP unwrap, PEM decode | ✓ | OTP 28 | — |
| OTP `:crypto` | AES-GCM AEAD | ✓ | OTP 28 | — |
| `saxy` | SaxyTree.parse/1 | ✓ | ~> 1.6 (mix.exs) | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (OTP 28 stdlib) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/security/xml_enc_test.exs --warnings-as-errors` |
| Full suite command | `mix ci.security` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENC-04a | KeyResolver.resolve/2 dispatches to configured adapter | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ❌ Wave 0 |
| ENC-04b | KeyResolver.Default returns `{:error, :key_not_configured}` when config is nil | unit | (same file as above) | ❌ Wave 0 |
| ENC-04c | KeyResolver.Default returns `{:ok, pem}` when config is set | unit | (same file as above) | ❌ Wave 0 |
| ENC-04d | XMLEnc.decrypt/3: RSA-PKCS1v1.5 input returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ❌ Wave 0 |
| ENC-04e | XMLEnc.decrypt/3: AES-CBC input returns `:decryption_failed` | security corpus | (same file) | ❌ Wave 0 |
| ENC-04f | XMLEnc.decrypt/3: truncated GCM auth tag returns `:decryption_failed` | security corpus | (same file) | ❌ Wave 0 |
| ENC-04g | XMLEnc.decrypt/3: malformed ciphertext returns `:decryption_failed` | security corpus | (same file) | ❌ Wave 0 |
| ENC-04h | SP private key not in DiagnosticBundle output | unit/assertion | `mix test test/relyra/diagnostic/allow_list_test.exs --warnings-as-errors` | ✅ (existing — verify no new fields leak) |

### Sampling Rate

- **Per task commit:** `mix test --warnings-as-errors` (full suite gate)
- **Per wave merge:** `mix ci.security`
- **Phase gate:** Full `mix ci.security` green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/security/xml_enc_test.exs` — 4-case corpus (ENC-04d through ENC-04g)
- [ ] `test/relyra/key_resolver_test.exs` — dispatch + default impl (ENC-04a through ENC-04c)
- [ ] `mix.exs` `ci.security` alias — add `cmd mix test test/security/xml_enc_test.exs --warnings-as-errors`
- [ ] `test/security/ci_gate_integrity_test.exs` — add `{"test/security/xml_enc_test.exs", nil}` to `@gated_suites`

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | KeyResolver behaviour — only configured resolver can access SP private key |
| V5 Input Validation | yes | SaxyTree parse gate + CipherValue size guard before crypto |
| V6 Cryptography | yes | OTP stdlib only; no hand-rolled crypto; RSA-OAEP + AES-GCM; auth tag validated |

### Known Threat Patterns for XMLEnc

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Padding oracle (RSA-PKCS1v1.5) | Information Disclosure | AlgorithmPolicy hard-blocks PKCS1v1.5 URI; no escape hatch |
| Truncated GCM auth tag oracle | Information Disclosure | `enforce_content_encryption_algorithm/3` with `auth_tag:` guard fires BEFORE AEAD call; `:decryption_failed` opaque |
| Chosen-ciphertext attack via error oracle | Information Disclosure | All failure modes return same `:decryption_failed` atom; no structured error leakage |
| Malformed PEM → exception escape | Tampering / DoS | `rescue _ -> :decryption_failed` wraps all OTP crypto calls |
| KeyInfo trust elevation | Elevation of Privilege | Document KeyInfo silently ignored (D-05); key sourced exclusively from KeyResolver |
| Algorithm confusion (CBC vs GCM) | Tampering | AlgorithmPolicy blocks AES-CBC by default; no escape hatch without explicit config |
| Private key leakage via logs/telemetry | Information Disclosure | PEM binary never assigned to a logged atom key; `@sensitive_keys` in audit_writer/log_alerts/log covers `:private_key`, `"private_key_pem"` |

### Sensitive Key Audit: No New Entries Needed

**Verified current coverage** [VERIFIED: codebase grep]:

| Module | Keys covered |
|--------|-------------|
| `lib/relyra/log.ex` (line 5-14) | `:private_key`, `:pem`, `:xml`, `:certificate_pem`, `:relay_state`, `:response_xml`, `:assertion_xml`, `:signed_xml`, `:metadata_xml` |
| `lib/relyra/ecto/audit_writer.ex` (line 8-21) | `"private_key"`, `"private_key_pem"`, `"pem"`, `"certificate_pem"` + 7 others |
| `lib/relyra/telemetry/handlers/log_alerts.ex` (line 33) | `:xml`, `:metadata_xml`, `:certificate_pem`, `:pem`, `:private_key` |
| `lib/relyra/diagnostic/allow_list.ex` | Whitelist-only export; no private key fields exported |

**The SP private key PEM never enters the Ecto layer** (config-only), so no new Ecto audit entry
is needed. The `audit_writer.ex` `"private_key_pem"` string covers any accident where the PEM
leaks into an audit map under that key name.

**Implementation discipline:** Inside `XMLEnc.decrypt/3`, the PEM binary and decoded private key
must remain as local variables in private `defp` functions. Never include them in a map passed to
Logger, telemetry, or `Error.new/3` details.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `test/security/xml_enc_test.exs` corpus tests should be tagged without `--only` filter (nil tag in gated_suites) | Pitfall 6, Wave 0 Gaps | Meta-gate fails if a tag is used but not declared; easy to fix |
| A2 | The `EncryptedKey` is always nested inside `KeyInfo` inside `EncryptedData` (per XMLEnc spec) | Code Examples — parse_enc_fields | Some non-standard IdP implementations may embed `EncryptedKey` differently; parse must fail closed if structure is not found |
| A3 | AES-GCM CipherValue layout is `IV(12) || Ciphertext || Tag(16)` per XMLEnc 1.1 spec | Code Examples | Confirmed via test; IdPs following the spec are consistent |
| A4 | `key_resolver_test.exs` should live in `test/relyra/` not `test/security/` (not a security corpus file) | Validation Architecture | Either location works; choice is organizational |

**If this table is empty (for main claims):** All crypto API claims in this research were verified against OTP 28 runtime. Code patterns were verified against the actual codebase. Confidence is HIGH.

---

## Open Questions (RESOLVED)

1. **Gate ordering — auth tag check before or after CEK unwrap?**
   - What we know: D-04 says `enforce_content_encryption_algorithm/2` at step 3 (before key resolver), but the auth tag is only extractable after decoding the content CipherValue (step 4 in revised ordering).
   - What's unclear: Should the auth tag length check happen before or after RSA decryption of the CEK?
   - RESOLVED: Check auth tag length AFTER base64-decoding the content CipherValue but BEFORE RSA unwrap. This is the safest ordering: it prevents the RSA decryption call for truncated-tag inputs (which are policy violations). The `enforce_content_encryption_algorithm/3` with `auth_tag:` handles it cleanly. Only the content CipherValue is decoded in the outer `with` chain; the key CipherValue is passed as base64 text to `do_decrypt/4` which decodes it internally.

2. **`KeyResolver.Default` connection argument — used or ignored?**
   - What we know: The callback is `resolve(connection :: map())`. The default reads from `Application.get_env`, not from the connection.
   - What's unclear: Should the default implementation raise or return a structured error if the connection argument is not a map?
   - RESOLVED: Mirror `RequestStore.Default` — pattern-match on `is_map(connection)` in the main clause, return `{:error, Error.new(:key_not_configured, ...)}` in the catch-all. The connection is passed through for future adapters that might scope keys per tenant.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:crypto.aes_gcm_decrypt/5` (removed in OTP 24) | `:crypto.crypto_one_time_aead/7` | OTP 24 | Use 7-arity form; 6-arity also available but 7-arity is canonical for decrypt |
| `{:rsa_oaep_hash, :sha256}` for SHA-256 OAEP | Blocked — raises `{:badarg}` on OTP 26-28 | OTP release 26 | Use SHA-1 OAEP only (`{:rsa_padding, :rsa_pkcs1_oaep_padding}`); AlgorithmPolicy blocks the SHA-256 URI |
| Generic `:aes_gcm` atom | Size-specific `:aes_128_gcm` / `:aes_256_gcm` | OTP 24 | Both still work in OTP 28, but size-specific atoms are explicit and preferred |

**Deprecated/outdated:**
- `:crypto.aes_gcm_decrypt/5`: Removed in OTP 24. Do not use.
- `{:rsa_oaep_hash, :sha256}` in OTP 26-28: Raises `{:badarg}`. Out of scope per REQUIREMENTS.md.

---

## Sources

### Primary (HIGH confidence)

- `lib/relyra/request_store.ex` — dispatch pattern, error builders, `Code.ensure_loaded?` guard; read and verified line by line
- `lib/relyra/request_store/default.ex` — default implementation pattern; `@behaviour`, `@impl true`, structured Error with `:hint`
- `lib/relyra/security/algorithm_policy.ex` — `enforce_key_transport_algorithm/2` and `enforce_content_encryption_algorithm/3` exact signatures and return types; verified in full
- `lib/relyra/security/signature.ex` — `do_verify/4` rescue pattern; `safe_verify/4` form at lines 396-399
- `lib/relyra/ecto/audit_writer.ex` — `@sensitive_keys` at lines 8-21
- `lib/relyra/telemetry/handlers/log_alerts.ex` — `@sensitive_keys` at line 33
- `lib/relyra/log.ex` — `@sensitive_keys` at lines 5-14
- `lib/relyra/diagnostic/allow_list.ex` — whitelist-only export; no private key path
- `lib/relyra/test_support/fake_idp.ex` — `keypair/0` generates RSA-2048 via `:public_key.generate_key({:rsa, 2048, 65537})` stored in persistent_term
- `lib/relyra/test_support/xmldsig_signer.ex` — public key extraction pattern, PEM encoding, RSA sign form
- `test/security/ci_gate_integrity_test.exs` — `@gated_suites` enforcement rules; tag integrity test; anti-hollow `cmd mix test` requirement
- OTP 28 runtime verification (mix run): `crypto_one_time_aead/7` API; `:error` return on bad auth tag; RSA-OAEP encrypt_public/decrypt_private roundtrip; SaxyTree parsing of xenc-namespaced XML; AES-128/256-GCM atoms; PEM decode/encode roundtrip

### Secondary (MEDIUM confidence)

- XMLEnc 1.1 specification structure (AES-GCM CipherValue layout: IV||CT||Tag) — standard structure confirmed via OTP 28 encrypt/decrypt roundtrip test

### Tertiary (LOW confidence)

- None — all claims verified against codebase or OTP 28 runtime.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all crypto calls verified against OTP 28 runtime
- Architecture: HIGH — all patterns verified against actual codebase; `RequestStore` is the exact template
- Pitfalls: HIGH — all pitfalls verified against codebase patterns or runtime behaviour

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (OTP stdlib APIs are stable; project patterns are project-specific)
