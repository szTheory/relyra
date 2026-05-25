---
phase: 33-key-resolver-behaviour-xmlenc-crypto-core
reviewed: 2026-05-25T00:00:00Z
depth: deep
files_reviewed: 7
files_reviewed_list:
  - lib/relyra/key_resolver.ex
  - lib/relyra/key_resolver/default.ex
  - lib/relyra/security/xml_enc.ex
  - test/relyra/key_resolver_test.exs
  - test/security/xml_enc_test.exs
  - test/security/ci_gate_integrity_test.exs
  - mix.exs
findings:
  critical: 1
  high: 1
  medium: 2
  low: 1
  info: 2
  total: 7
status: issues_found
advisory: true
---

# Phase 33: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** deep (cross-file call chain tracing)
**Files Reviewed:** 7
**Status:** issues\_found
**Advisory:** Yes — does not block phase completion per review scope

---

## Summary

The KeyResolver behaviour, its Default adapter, and the XMLEnc dispatch/error-handling
skeleton are all structurally sound. Security invariants for key-material isolation,
opaque failure atoms, algorithm-policy gating, and the no-KeyInfo-trust rule are
correctly implemented in the control flow. The CI gate integrity test and mix.exs
one-line change are clean.

One critical correctness bug exists in `XMLEnc`: the `find_first/2` depth-first
traversal extracts the *key-transport* `CipherValue` when it should extract the
*content* `CipherValue`. This means `XMLEnc.decrypt/3` will always return
`:decryption_failed` for valid encrypted assertions — the feature is non-functional
as shipped. The bug is completely masked by the test suite because no happy-path
roundtrip test was written.

---

## Critical Issues

### CR-01: `cipher_value_text(enc_data)` extracts the key-transport CipherValue, not the content CipherValue — decryption always fails

**File:** `lib/relyra/security/xml_enc.ex:148–152` (and call site `parse_enc_fields/1:125`)

**Classification:** CRITICAL — incorrect behavior; `XMLEnc.decrypt/3` is non-functional for any
well-formed encrypted assertion.

**Root cause:** `cipher_value_text/1` delegates to `find_first/2`, which is a
**depth-first** traversal returning the *first* node whose `:local` field matches the
target name. The canonical XML-Enc structure for an `EncryptedData` element is:

```xml
<EncryptedData>
  <EncryptionMethod Algorithm="...content alg..."/>
  <KeyInfo>
    <EncryptedKey>
      <EncryptionMethod Algorithm="...key transport..."/>
      <CipherData>                          ← depth-first finds THIS first
        <CipherValue>...enc_key_b64...</CipherValue>
      </CipherData>
    </EncryptedKey>
  </KeyInfo>
  <CipherData>                              ← this is never reached
    <CipherValue>...content_cipher_b64...</CipherValue>
  </CipherData>
</EncryptedData>
```

`find_first(enc_data, "CipherData")` descends into `KeyInfo → EncryptedKey → CipherData` and
returns that node — the *key-transport* `CipherData` — before ever seeing the direct
`CipherData` child of `EncryptedData`. The extracted `content_cipher_value` is therefore the
Base64-encoded encrypted CEK, not the encrypted assertion payload.

Downstream effects:
- `b64_decode(fields.content_cipher_value)` decodes the encrypted CEK bytes.
- `split_cipher_value` succeeds (an RSA-2048 wrapped key is 256 bytes, well over the 28-byte minimum).
- `check_content_encryption` sees a valid GCM URI and passes.
- `do_decrypt` is called with the encrypted CEK as `content_cipher_bytes`.
- Inside `do_decrypt`, the content cipher is split incorrectly and the AES-GCM decryption
  always fails with `:error`, returning `:decryption_failed`.

Every correctly-formed encrypted assertion is permanently rejected.

**Why the test suite misses this:** All four tests in `xml_enc_test.exs` assert
`:decryption_failed` — the expected output for policy failures *and* for this bug. There is
no roundtrip test that feeds a validly-encrypted assertion and asserts `{:ok, plaintext}`.

**Fix:** `parse_enc_fields/1` must extract the content `CipherValue` from the **direct**
`CipherData` child of `EncryptedData`, not via depth-first search. Two options:

*Option A — restrict to direct children only (minimal change):*

```elixir
# Replace cipher_value_text/1 with a version that only looks at direct children.
defp content_cipher_value_text(enc_data_node) do
  cd =
    Enum.find(enc_data_node.children, fn child ->
      child.local == "CipherData"
    end)

  cv = cd && Enum.find(cd.children, fn child -> child.local == "CipherValue" end)
  cv && cv.text
end
```

And in `parse_enc_fields/1`, replace:

```elixir
# BEFORE (wrong — depth-first finds EncryptedKey's CipherData first)
content_cv when is_binary(content_cv) <- cipher_value_text(enc_data)

# AFTER
content_cv when is_binary(content_cv) <- content_cipher_value_text(enc_data)
```

*Option B — add a mandatory happy-path test first, then fix `find_first` scope:*

In `xml_enc_test.exs`, add a test that exercises the full successful path:

```elixir
test "successful RSA-OAEP + AES-256-GCM roundtrip", %{pub_key: pub_key, pem: _pem} do
  cek = :crypto.strong_rand_bytes(32)
  plaintext = "<Assertion>hello</Assertion>"
  iv = :crypto.strong_rand_bytes(12)

  {ciphertext, auth_tag} =
    :crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, <<>>, 16, true)

  content_cipher_bytes = iv <> ciphertext <> auth_tag
  cipher_value_b64 = Base.encode64(content_cipher_bytes)

  enc_key_bytes =
    :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
  enc_key_b64 = Base.encode64(enc_key_bytes)

  bytes =
    build_encrypted_assertion(@rsa_oaep_uri, @aes256_gcm_uri, enc_key_b64, cipher_value_b64)

  assert {:ok, ^plaintext} = XMLEnc.decrypt(bytes, Relyra.KeyResolver.Default, [])
end
```

This test will fail until the `cipher_value_text` bug is fixed, making it a regression guard.

---

## High Issues

### HI-01: No happy-path roundtrip test — the core decrypt function is untestable as shipped

**File:** `test/security/xml_enc_test.exs` (entire file)

**Classification:** HIGH — the absence of a success-path test allowed CR-01 to ship
undetected. All four tests only verify `:decryption_failed` outcomes; none verify
`{:ok, binary()}`. The "normal operation" path of `XMLEnc.decrypt/3` is uncovered.

**Fix:** Add the roundtrip test shown in CR-01's fix (Option B) as a mandatory test before
this module is considered complete. The test is trivial to write given the existing `setup`
block, which already generates a full RSA keypair and PEM.

---

## Medium Issues

### MD-01: `Default.resolve/1` — non-exhaustive `case` crashes on non-binary config values

**File:** `lib/relyra/key_resolver/default.ex:11–21`

**Classification:** MEDIUM — incorrect behavior for mis-configured deployments; the crash
surfaces as a confusing `CaseClauseError` rather than a typed `{:error, %Error{}}`.

The `case` has two arms: `nil` and `pem when is_binary(pem)`. Any other config value (e.g.,
a charlist, a `{:system, "VAR"}` tuple, an atom, or a keyword list from a mis-reading of the
docs) raises `CaseClauseError`. The error is caught by `dispatch_key_resolver`'s `rescue`
block, but the exception message includes `inspect` of the non-matching value, which could
expose misconfigured secrets or partial key material in logs.

**Fix:** Add a catch-all arm that returns a typed error:

```elixir
case Application.get_env(:relyra, :sp_private_key_pem) do
  nil ->
    {:error, Error.new(:key_not_configured, "SP decryption private key is not configured", %{
      hint: "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
    })}

  pem when is_binary(pem) ->
    {:ok, pem}

  _other ->
    {:error, Error.new(:key_not_configured, "SP decryption private key must be a PEM binary", %{
      hint: "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
    })}
end
```

### MD-02: Truncated auth-tag test has a wrong comment — misrepresents which guard fires

**File:** `test/security/xml_enc_test.exs:81–84`

**Classification:** MEDIUM — the comment describes a different invariant than the one the
test actually exercises. This causes maintenance confusion and masks the fact that the
`AlgorithmPolicy` auth-tag guard (`byte_size < 16`) is never reached from the `XMLEnc`
decrypt path.

The comment says:

```
# IV(12) || CT(1 byte) || Tag(15 bytes) = 28 bytes total — tag is 1 byte short
```

The actual code produces `12 + 15 = 27 bytes` — the `strong_rand_bytes(15)` call does not
include a CT byte. The total is 27, which is less than the 28-byte minimum for
`split_cipher_value/1`, so it is the *structural* guard (`byte_size(bytes) >= 28`) that fires,
not the AlgorithmPolicy auth-tag-length guard. The test name "truncated GCM auth tag" implies
the latter.

**Fix:**

1. Rename or re-focus the test. If the intent is to test the `split_cipher_value` minimum-size
   guard, update the comment to say so:

```elixir
# IV(12) + 15 random bytes = 27 total — below the 28-byte minimum for
# split_cipher_value/1 (IV=12 + empty-ciphertext + auth_tag=16 = 28 minimum).
# split_cipher_value returns :decryption_failed before AlgorithmPolicy is consulted.
iv = :crypto.strong_rand_bytes(12)
truncated = iv <> :crypto.strong_rand_bytes(15)
```

2. If the intent is to test the `AlgorithmPolicy` auth-tag guard, construct 28+ bytes with
   a 15-byte simulated tag and supply it via the `opts` path directly.

---

## Low Issues

### LO-01: `AlgorithmPolicy.enforce_content_encryption_algorithm/3` auth-tag guard is dead code when called from `XMLEnc`

**File:** `lib/relyra/security/algorithm_policy.ex:155–159` (caller: `lib/relyra/security/xml_enc.ex:22`)

**Classification:** LOW — dead code path; the guard exists but can never be triggered from
`XMLEnc`'s decrypt path, creating a false sense of defense-in-depth.

`split_cipher_value/1` always produces a 16-byte `auth_tag` when it succeeds
(`<<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest`). The
`AlgorithmPolicy` guard fires when `byte_size(auth_tag) < 16`. Since `split_cipher_value`
is the sole source of the `auth_tag` passed to `check_content_encryption`, and it
statically guarantees a 16-byte tag on success, the `< 16` branch is unreachable from
`XMLEnc.decrypt/3`.

The guard is sound in isolation (useful if `AlgorithmPolicy` is called from other
contexts), but the `XMLEnc` path duplicates a structural invariant that `split_cipher_value`
already enforces by binary pattern match.

**Fix:** Add a comment at the `check_content_encryption` call site in `xml_enc.ex` noting
that `auth_tag` is guaranteed 16 bytes at this point (from `split_cipher_value`). Optionally,
drop the `auth_tag:` keyword from the `enforce_content_encryption_algorithm/3` call since it
provides no additional gating value in this path:

```elixir
# auth_tag is guaranteed 16 bytes here by split_cipher_value's binary pattern.
:ok <- check_content_encryption(policy, fields.content_alg, auth_tag),
```

---

## Info

### IN-01: `resolve_key/2` in `XMLEnc` bypasses the `KeyResolver` validation layer

**File:** `lib/relyra/security/xml_enc.ex:106–113`

`XMLEnc.resolve_key/2` calls `apply(key_resolver_module, :resolve, [connection])` directly
without the `Code.ensure_loaded?` / `function_exported?` pre-checks that
`KeyResolver.dispatch_key_resolver/2` performs. Any error is rescued to `:decryption_failed`,
so there is no crash. However, an invalid `key_resolver_module` atom (e.g., an unloaded
module or a typo) produces `:decryption_failed` with no diagnostic information, rather than
a typed `:adapter_not_configured` error.

This is a tradeoff (opaque failure is the security invariant), but callers who mis-configure
`key_resolver_module` will see silent decryption failure with no signal about the configuration
error.

**Suggestion:** Consider adding a module-level guard at the top of `decrypt/3` or in
`resolve_key/2` that checks `Code.ensure_loaded?` and returns `:decryption_failed` with a
log warning (at `Logger.warning` level, not error details) about the missing module, so
operators can diagnose configuration failures without exposing key material.

### IN-02: All three `KeyResolver` error constructors share the same `type: :adapter_not_configured`

**File:** `lib/relyra/key_resolver.ex:54–80`

`adapter_not_configured/2`, `invalid_adapter_result/3`, and `adapter_dispatch_error/3` all
emit `type: :adapter_not_configured`. This collapses three structurally distinct failure
modes (missing module, bad return shape, runtime exception) into one type, making programmatic
error handling and log triage harder. The test correctly asserts
`%Error{type: :adapter_not_configured}` for all three cases — so this is intentional — but it
limits downstream callers' ability to distinguish configuration errors from adapter crashes.

**Suggestion (non-blocking):** If the behaviour callback contract allows it, introduce
`:invalid_adapter_result` and `:adapter_dispatch_error` as distinct error types in a future
phase. The test assertions would need updating accordingly.

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (claude-sonnet-4-6 / gsd-code-reviewer)_
_Depth: deep_
_Advisory: yes — does not block phase completion_
