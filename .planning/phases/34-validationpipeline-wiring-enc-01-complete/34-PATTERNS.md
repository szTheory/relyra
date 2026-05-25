# Phase 34: ValidationPipeline Wiring + ENC-01 Complete - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 6 (5 modify + 1 new)
**Analogs found:** 6 / 6 (all in-repo, all read directly)

This is a **brownfield wiring phase** — every new behavior has a sibling already in the
codebase. There is no "no analog" case. The planner copies struct shapes, function
signatures, and error-construction patterns directly from the cited lines below.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/protocol/validation_pipeline.ex` | service (pipeline orchestrator) | transform (decrypt → re-parse → verify) | itself — `do_run/4` (62-76) + `do_run_validations/6` (78-111) | exact (self-extension) |
| `lib/relyra/protocol/metadata.ex` | service (XML builder) | transform (config → XML string) | itself — `build_sp_metadata/2` (4-19); cert→b64 from `signature.ex:287-292` | exact (self-extension) |
| `lib/relyra/error.ex` | model (typed error) | n/a (struct constructor) | `Error.new/3` (15-18); `:ambiguous_signed_node` precedent `pure_beam.ex:550-554` | exact |
| `lib/relyra/test_support/fake_idp.ex` | test-support (fixture generator) | transform (signed XML → encrypted envelope) | `FakeIdP.sign/2` (64-75); recipe `xml_enc_test.exs:28-56` | exact |
| `test/security/xml_enc_adversarial_test.exs` (NEW) | test (adversarial corpus) | request-response (end-to-end through pipeline) | `test/security/xml/adversarial_crypto_test.exs` (whole file); `xml_enc_test.exs` (unit corpus shape) | exact |
| `mix.exs` | config (CI alias) | batch (CI gate steps) | `ci.security` alias lines 152-181 | exact |

## Pattern Assignments

### `lib/relyra/protocol/validation_pipeline.ex` (service, transform)

**Analog:** the file itself. The `:decrypt_assertion` pre-stage slots between `parse_safely/2`
(line 66) and `do_run_validations/6` (line 68). **Do NOT touch `do_run_validations/6`** — D-02
requires the no-op path be byte-identical.

**Current `do_run/4` host site to extend** (lines 62-76):
```elixir
defp do_run(response_payload, request_intent, connection, opts) do
  now = Keyword.get(opts, :now, DateTime.utc_now())
  cert_chain = cert_chain(connection, opts)

  case Relyra.Security.XML.PureBeam.parse_safely(response_payload, parse_opts(opts)) do
    {:ok, parsed_doc} ->
      # >>> NEW :decrypt_assertion pre-stage inserts HERE — between this {:ok, parsed_doc}
      #     and the do_run_validations/6 call below. On :none it passes parsed_doc through
      #     unchanged (D-02). On {:single, _} it re-parses and substitutes parsed_doc.
      case do_run_validations(parsed_doc, request_intent, connection, cert_chain, opts, now) do
        {:ok, login_result} -> {:ok, login_result, assertion_count(parsed_doc)}
        {:error, %Error{} = error} -> {:error, error, assertion_count(parsed_doc)}
      end

    {:error, %Error{} = error} ->
      {:error, error, 0}
  end
end
```

**Three-tuple return contract the pre-stage MUST preserve:** every `do_run/4` exit is
`{:ok, login_result, assertion_count}` or `{:error, %Error{}, assertion_count}` (lines 69-70,
74). A `:decrypt_assertion` failure (ambiguity / decryption) returns
`{:error, %Error{...}, assertion_count(parsed_doc)}` to match — `assertion_count/1` (234-238)
reads `:signed_candidates` off whichever `parsed_doc` is in scope (the outer one for ambiguity,
since no re-parse happened).

**Re-parse seam (the SAME entry, CLAUDE.md invariant #2):** call
`Relyra.Security.XML.PureBeam.parse_safely(recomposed, parse_opts(opts))` again — `parse_opts/1`
is already defined at line 206 (`Keyword.take(opts, [:max_bytes])`). The recomposed binary gets
the same pre-parse DTD/entity/size guards for free.

**KeyResolver module sourcing (Research Pattern 3 — pass the MODULE):** mirror `key_resolver.ex:26`
exactly — `Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)`. Pass that atom as
`XMLEnc.decrypt/3`'s 2nd arg; do NOT call `KeyResolver.resolve/2` (decrypt/3 re-resolves
internally via `apply` at `xml_enc.ex:107`).

**Connection threading into decrypt opts:** `XMLEnc.decrypt/3` reads connection from opts
(`xml_enc.ex:16`: `Keyword.get(opts, :connection, %{})`). The `connection` map is already a
`do_run/4` parameter — thread `Keyword.put(opts, :connection, connection)` into the decrypt call.

**Tree-walk detection — copy the prefix-agnostic `find_first`/`find_all` shape.** The pipeline's
`parsed_doc` exposes `:parse_tree` (the `SaxyTree.Node` root, set at `pure_beam.ex:257`). Two
in-repo `find_first`/`find_all` implementations are available to model the detector on:

PureBeam's (`pure_beam.ex:584-590`, `Node`-typed):
```elixir
defp find_first(%Node{local: local} = node, local), do: node
defp find_first(%Node{children: children}, local) do
  Enum.find_value(children, fn child -> find_first(child, local) end)
end
defp find_first(_other, _local), do: nil
```

XMLEnc's (`xml_enc.ex:170-176`, untyped-map form — usable directly on the parse_tree node):
```elixir
defp find_first(%{local: local} = node, local), do: node
defp find_first(%{children: children}, local) do
  Enum.find_value(children, fn child -> find_first(child, local) end)
end
defp find_first(_other, _local), do: nil
```

Detector logic per RESEARCH.md code example (D-02/D-03): `find_first(parse_tree, "EncryptedAssertion")`
nil → `:none`; non-nil with sibling `find_first(parse_tree, "Assertion")` → `:ambiguous`;
`length(find_all(parse_tree, "EncryptedAssertion")) > 1` → `:ambiguous`; else `{:single, node}`.

**Error construction in this file:** every error already uses `Error.new(type, message, %{})`
(e.g. lines 121-125, 145-153, 166-173). Match that for both new returns:
```elixir
{:error, Error.new(:ambiguous_assertion,
  "Response contains both cleartext and encrypted assertions", %{})}        # D-03, pre-crypto
{:error, Error.new(:decryption_failed,
  "Encrypted assertion could not be decrypted", %{})}                       # opaque, no oracle
```

**Identity-read prohibition (Pitfall 3 / CLAUDE.md #4):** the pre-stage returns ONLY the
re-parsed `parsed_doc`. All identity reads stay in `login_result/5` (181-204), reached only
after `Signature.verify/4` succeeds inside `do_run_validations/6`'s `with` chain (line 81-82).

---

### `lib/relyra/protocol/metadata.ex` (service, transform)

**Analog:** the file itself — `build_sp_metadata/2` (4-19) is a heredoc string builder with
`#{...}` interpolation. Currently emits NO `KeyDescriptor`; D-04 adds both.

**Current builder (the exact heredoc to extend):**
```elixir
def build_sp_metadata(connection, _opts \\ []) do
  issuer = Map.get(connection, :sp_entity_id) || Map.get(connection, :issuer)
  acs_url = Map.get(connection, :acs_url)

  """
  <?xml version="1.0" encoding="UTF-8"?>
  <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="#{issuer}">
    <md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
      <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="#{acs_url}" index="1" isDefault="true"/>
    </md:SPSSODescriptor>
  </md:EntityDescriptor>
  """
  |> String.trim()
end
```

**Config seam pattern (D-04, `:_pem` convention):** read SP **public** certs via
`Application.get_env(:relyra, :sp_encryption_cert_pem)` and
`Application.get_env(:relyra, :sp_signing_cert_pem)`. Never read `:sp_private_key_pem`. (The
note `_opts` is currently unused — the controller passes `opts` at `metadata_controller.ex:14`;
sourcing from `Application.get_env` matches the Phase-33 convention and the
`controller_opts/1`→`Application.get_all_env(:relyra)` fallback at `metadata_controller.ex:49-51`.)

**Cert PEM → `<ds:X509Certificate>` base64-of-DER body** — copy the decode-and-extract from
`signature.ex:288-289`:
```elixir
with [entry | _] <- :public_key.pem_decode(pem),
     der when is_binary(der) <- elem(entry, 1) do
  # der is the raw DER bytes; Base.encode64(der) is the X509Certificate body
  # (strip PEM armor + newlines — Base.encode64 of the DER gives exactly that)
```
i.e. `Base.encode64(elem(hd(:public_key.pem_decode(pem)), 1))` is the `<ds:X509Certificate>` text.

**KeyDescriptor placement + ordering (Research Pattern 2, schema-verified):** both
`<md:KeyDescriptor>` elements go inside `<md:SPSSODescriptor>` **before** the existing
`<md:AssertionConsumerService>`, signing first then encryption. Skeleton to splice in:
```xml
<md:KeyDescriptor use="signing">
  <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:X509Data><ds:X509Certificate>#{signing_cert_b64}</ds:X509Certificate></ds:X509Data>
  </ds:KeyInfo>
</md:KeyDescriptor>
<md:KeyDescriptor use="encryption">
  <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:X509Data><ds:X509Certificate>#{enc_cert_b64}</ds:X509Certificate></ds:X509Data>
  </ds:KeyInfo>
  <!-- advertise the accept-list URIs (RESEARCH Pattern 2): xmlenc# forms, NOT xmlenc11# -->
  <md:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-gcm"/>
  <md:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-gcm"/>
  <md:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"/>
</md:KeyDescriptor>
```
The advertised URIs must equal `XMLEnc`'s accept-list (`xml_enc.ex:8-9`,
`http://www.w3.org/2001/04/xmlenc#aes256-gcm` / `#aes128-gcm`) — match the decryptor, not the
spec's xmlenc11 menu (RESEARCH A2).

---

### `lib/relyra/error.ex` (model, typed error)

**Analog:** `Error.new/3` (15-18) — the free-atom taxonomy. **No file change required**:
`:ambiguous_assertion` is just a new atom passed to the existing constructor (D-03). There is no
central registry to register against (per CONTEXT.md `error.ex:15-18` note).

**Constructor signature (unchanged, just called with a new atom):**
```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

**Precedent for the new atom — `:ambiguous_signed_node` (`pure_beam.ex:550-554`):** the exact
shape to mirror for a structural "exactly one X" rejection:
```elixir
{:error,
 Error.new(
   :ambiguous_signed_node,
   "Exactly one verified signed node is required",
   %{candidate_count: length(candidates)}
 )}
```
`:ambiguous_assertion` follows this precedent: pre-crypto structural reject, typed (not folded
into opaque `:decryption_failed`), no oracle risk. Built in `validation_pipeline.ex`, not here.

**Redaction note (free, no action):** `Error.redact_details/1` (39-48) already drops
`:xml`/`:assertion_xml`/`:signed_xml` and truncates long binaries — so if the planner ever puts
ciphertext-adjacent data in `details`, it is auto-redacted. Keep `:ambiguous_assertion` details
empty (`%{}`) anyway — it carries no diagnostic payload.

---

### `lib/relyra/test_support/fake_idp.ex` (test-support, transform)

**Analog:** `FakeIdP.sign/2` (64-75) — the canonical signer, the single-source pattern the new
`encrypt`/`encrypted_response` helper mirrors (D-08).

**Canonical-generator pattern to mirror (`sign/2`, 64-75):**
```elixir
@spec sign(Builder.t() | keyword(), keyword()) :: String.t()
def sign(opts, extra_opts \\ [])

def sign(%Builder{} = builder, opts) do
  ensure_not_prod!()
  ensure_keypair!()
  xml = response_xml(builder, opts)
  %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(xml)
  Base.encode64(signed_xml, padding: false)
end

def sign(opts, extra_opts) when is_list(opts), do: build_response(opts) |> sign(extra_opts)
```
The new helper follows the same discipline: `ensure_not_prod!()` + `ensure_keypair!()` guards
first, build via the genuine signer, return ready-to-feed output. (Note: `sign/2` here delegates
to `XmldsigSigner.sign_response/1`; the actual genuine signer is `XmldsigSigner.signed_response/1`
at `xmldsig_signer.ex:94-130`, which returns `%{response_xml:, cert_chain:}`. The encrypt helper
should sign the assertion FIRST via the genuine path, THEN wrap it — RESEARCH note line 381.)

**SP keypair access for the encrypt recipe:** `FakeIdP.keypair/0` (87-93) returns the RSA private
key; derive the public key from it the way `xml_enc_test.exs:13-15` does:
```elixir
keypair = FakeIdP.keypair()
{:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = keypair
pub_key = {:RSAPublicKey, n, e}
```

**Encryption recipe to PROMOTE verbatim from `xml_enc_test.exs:39-53` (Pitfall 4 — the proven
`IV(12)||CT||Tag(16)` layout `split_cipher_value/1` round-trips):**
```elixir
cek = :crypto.strong_rand_bytes(32)
enc_key_bytes = :public_key.encrypt_public(cek, pub_key, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
enc_key_b64 = Base.encode64(enc_key_bytes)

iv = :crypto.strong_rand_bytes(12)
{ciphertext, auth_tag} =
  :crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, <<>>, 16, true)
cipher_value_b64 = Base.encode64(iv <> ciphertext <> auth_tag)
```

**`<EncryptedAssertion>` envelope template to PROMOTE verbatim from `xml_enc_test.exs:28-33`:**
```elixir
"""
<EncryptedAssertion xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedData><xenc:EncryptionMethod Algorithm="#{content_uri}"/><ds:KeyInfo><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm="#{key_transport_uri}"/><xenc:CipherData><xenc:CipherValue>#{enc_key_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></ds:KeyInfo><xenc:CipherData><xenc:CipherValue>#{cipher_value_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedData></EncryptedAssertion>
"""
|> String.trim()
```

**Algorithm URI module attrs to add (mirror `xml_enc_test.exs:7-10`):**
```elixir
@rsa_oaep_uri "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
@aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
# adversarial variants for the corpus fixtures:
@rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"      # fixture 3
@aes256_cbc_uri "http://www.w3.org/2001/04/xmlenc#aes256-cbc"  # fixture 4
```

**Self-contained-namespace requirement (Pitfall 1, SECURITY-CRITICAL):** the encrypted
`<Assertion>` MUST carry its own `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` declaration on
the Assertion element — exactly as `fake_idp.ex:124` already does for the cleartext path. Sign
the Assertion BEFORE encrypting so post-decrypt bytes are byte-identical to the signed bytes.

**`encrypted_response` (recompose into a full Response):** mirror the Response shell at
`fake_idp.ex:120-145` / `xmldsig_signer.ex:104-123` (Response → Issuer → Status →
[here goes the EncryptedAssertion instead of Assertion] → Signature), so the corpus can feed a
complete Response binary into `ValidationPipeline.run/4`.

---

### `test/security/xml_enc_adversarial_test.exs` (test, request-response) — NEW

**Primary analog:** `test/security/xml/adversarial_crypto_test.exs` (whole file) — FakeIdP-driven,
drives end-to-end through the verify path, pins EXACT `%Error{type:}` (never bare `{:error, _}`),
with a positive control and named negative controls. **Secondary analog:**
`test/security/xml_enc_test.exs` for the per-fixture `describe`/`test` corpus shape and the
`setup` that wires `:sp_private_key_pem`.

**Exact-error-pin pattern to copy (adversarial_crypto_test.exs:90-92, 100-102, 110-112, 124-125):**
```elixir
assert {:error, %Error{type: :invalid_signature}} =
         Signature.verify(parsed_doc, connection(), signed.cert_chain)

assert {:error, %Error{type: :digest_mismatch}} =
         Signature.verify(parsed_doc, connection(), [throwaway_cert_pem()])
```
The new corpus pins at the **pipeline** level instead — `ValidationPipeline.run/4` (or
`Relyra.consume_response/3`), e.g.:
```elixir
assert {:error, %Error{type: :decryption_failed}} =
         ValidationPipeline.run(encrypted_response, request_intent, connection, opts)
```

**Positive-control pattern to copy (adversarial_crypto_test.exs:56-67):**
```elixir
describe "positive control (...)" do
  test "a genuinely FakeIdP-signed Response verifies {:ok, %SignedNode{}}" do
    b64 = FakeIdP.sign(FakeIdP.build_response())
    {:ok, xml} = Base.decode64(b64, padding: false)
    {:ok, parsed_doc} = PureBeam.parse_safely(xml, [])
    assert {:ok, %Relyra.Security.SignedNode{} = node} =
             Signature.verify(parsed_doc, connection(), [FakeIdP.self_signed_cert_pem()])
  end
end
```
SC#1's positive control mirrors this but goes through the full pipeline: valid
`FakeIdP.encrypted_response` → `ValidationPipeline.run/4` → `{:ok, login_result}` with
identity fields present (proving decrypt → re-parse → verify → identity-read ordering).

**`setup` block to copy (xml_enc_test.exs:12-26)** — wires the SP private key so the resolver
can unwrap, with `on_exit` cleanup:
```elixir
setup do
  keypair = FakeIdP.keypair()
  {:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = keypair
  pub_key = {:RSAPublicKey, n, e}
  pem = :public_key.pem_encode([
    {:RSAPrivateKey, :public_key.der_encode(:RSAPrivateKey, keypair), :not_encrypted}
  ])
  Application.put_env(:relyra, :sp_private_key_pem, pem)
  on_exit(fn -> Application.delete_env(:relyra, :sp_private_key_pem) end)
  {:ok, keypair: keypair, pub_key: pub_key, pem: pem}
end
```

**7-fixture → error-pin map (from RESEARCH §Validation Architecture, D-07):**
| # | Fixture | Pin |
|---|---------|-----|
| 1 | wrong-key | `%Error{type: :decryption_failed}` |
| 2 | truncated GCM tag (15-byte tag) | `%Error{type: :decryption_failed}` |
| 3 | PKCS1v1.5 key transport | `%Error{type: :decryption_failed}` |
| 4 | AES-CBC content | `%Error{type: :decryption_failed}` |
| 5 | cleartext-injection (both present) | `%Error{type: :ambiguous_assertion}` (must fire BEFORE decrypt) |
| 6 | malformed ciphertext | `%Error{type: :decryption_failed}` |
| 7 | read-before-verify | verification-stage typed error (`:invalid_signature` or `:digest_mismatch`) AND `name_id`/`attributes` NOT in result map |

The fixture-construction recipes for #1-#4, #6 are direct adaptations of the
`xml_enc_test.exs:63-144` failure-path tests (wrong padding, wrong content URI, 15-byte tag,
bad base64), now wrapped into a full Response and run through the pipeline. Fixture #5 builds a
Response with BOTH a sibling `<Assertion>` and `<EncryptedAssertion>`. Fixture #7 (the strongest
auth-bypass guard) encrypts a tampered-then-signed assertion and asserts the result map carries
no identity — model the tamper on `XmldsigSigner.signed_response(tamper_name_id: ...)`
(`xmldsig_signer.ex:88-92`, 125-127) wrapped in `FakeIdP.encrypt`.

**Module header conventions (adversarial_crypto_test.exs:1-46):** `use ExUnit.Case, async: true`,
a `@moduletag`, `alias Relyra.Error` + `Relyra.TestSupport.FakeIdP`, URI module attrs, and a
local `connection/0` helper. (Whether to gate with a `@moduletag :xml_enc_adversarial` `--only`
flag in the ci.security line is the planner's choice — the existing line at `mix.exs:173` runs
`xml_enc_test.exs` with NO `--only` tag, so the simplest path is no moduletag + a bare file run.)

---

### `mix.exs` (config, batch) — `ci.security` alias

**Analog:** the existing per-suite `cmd mix test` lines in the alias (167-173). Add the new corpus
as its OWN line (D-07 / Pitfall 5 — the hollow-gate rule; never collapse to a bare `test` step).

**Exact pattern to copy (the simplest match is line 173, which runs the Phase-33 unit corpus with
no `--only` tag):**
```elixir
"cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
```
Add immediately after it:
```elixir
"cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
```
The block comment at `mix.exs:159-166` explains WHY each suite is its own `cmd mix test` process —
do not "simplify". The meta-gate `test/security/ci_gate_integrity_test.exs` (run as the first
security line, 167) enforces this invariant; run it to confirm the new line is not hollow.

---

## Shared Patterns

### Typed-error construction
**Source:** `Error.new/3` (`error.ex:15-18`); precedent `pure_beam.ex:550-554`.
**Apply to:** `validation_pipeline.ex` (both new returns).
```elixir
{:error, Error.new(:ambiguous_assertion, "Response contains both cleartext and encrypted assertions", %{})}
```
Free-atom taxonomy — no registry. Keep `:ambiguous_assertion` typed (pre-crypto, no oracle);
keep crypto/policy failures folded into opaque `:decryption_failed` (no oracle).

### Prefix-agnostic tree-walk (find_first / find_all by local name)
**Source:** `pure_beam.ex:584-590` (Node-typed) and `xml_enc.ex:170-176` (map form).
**Apply to:** the `:decrypt_assertion` detector in `validation_pipeline.ex`.
Both walk `:children` recursively matching `:local`; the parse_tree root is at `parsed_doc.parse_tree`
(`pure_beam.ex:257`). Reuse this shape — do NOT add a second parser (CLAUDE.md invariant #2).

### Single hardened parse seam (re-parse after splice)
**Source:** `validation_pipeline.ex:66` (`PureBeam.parse_safely/2`), `parse_opts/1` at line 206.
**Apply to:** the recompose step — `PureBeam.parse_safely(recomposed, parse_opts(opts))`.
Re-using the seam re-applies DTD/entity/size pre-parse guards to the decrypted plaintext for free
(CLAUDE.md invariant #3).

### Cert PEM → base64-DER
**Source:** `signature.ex:288-289`.
**Apply to:** `metadata.ex` `<ds:X509Certificate>` body for both KeyDescriptors.
```elixir
Base.encode64(elem(hd(:public_key.pem_decode(pem)), 1))
```

### Config seam (`:_pem` convention)
**Source:** Phase-33 `:sp_private_key_pem` (read by `KeyResolver.Default`); `xml_enc_test.exs:22`.
**Apply to:** `metadata.ex` — `Application.get_env(:relyra, :sp_signing_cert_pem)` /
`:sp_encryption_cert_pem` (public certs only; never the private key).

### FakeIdP single canonical generator
**Source:** `FakeIdP.sign/2` (`fake_idp.ex:64-75`) + `ensure_not_prod!`/`ensure_keypair!` guards.
**Apply to:** the new `encrypt`/`encrypted_response` helpers — same guard discipline, same
"build via genuine path, return ready output" shape. Promote the recipe from `xml_enc_test.exs:28-56`.

### Exact-error pin in corpus (never bare `{:error, _}`)
**Source:** `adversarial_crypto_test.exs:90,100,110,124` — `%Error{type: :...}`.
**Apply to:** all 7 fixtures in the new corpus, plus a positive control pinning `{:ok, ...}` with
identity present. Pinning exact types makes a no-op (e.g. ambiguity not firing) surface immediately.

### ci.security hollow-gate rule
**Source:** `mix.exs:159-173` block comment + per-suite `cmd mix test` lines.
**Apply to:** the new corpus's `mix.exs` line — own `cmd mix test ... --warnings-as-errors`;
verify against `test/security/ci_gate_integrity_test.exs`.

## No Analog Found

None. Every Phase-34 file extends an existing sibling or copies an in-repo recipe. This is a
wiring phase, not a building phase (RESEARCH "Don't Hand-Roll" key insight).

## Metadata

**Analog search scope:** `lib/relyra/protocol/`, `lib/relyra/security/`, `lib/relyra/`,
`lib/relyra/test_support/`, `lib/relyra/phoenix/controllers/`, `test/security/`, `mix.exs`
**Files read this session:** `validation_pipeline.ex`, `metadata.ex`, `error.ex`, `fake_idp.ex`,
`xml_enc_test.exs`, `xml_enc.ex`, `key_resolver.ex`, `adversarial_crypto_test.exs`,
`pure_beam.ex` (targeted: 250-269, 540-618), `mix.exs` (145-184), `xmldsig_signer.ex` (1-130),
`metadata_controller.ex`, `signature.ex` (282-295), `relyra.ex` (148-172)
**Pattern extraction date:** 2026-05-25
```