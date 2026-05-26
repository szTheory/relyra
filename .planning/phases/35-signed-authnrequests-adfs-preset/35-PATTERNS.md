# Phase 35: Signed AuthnRequests + ADFS Preset — Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 26 (10 create, 16 modify)
**Analogs found:** 26 / 26

All files have strong in-repo analogs. Phase 35 is heavily extension-shaped — every
new function mirrors a sibling pattern within the same module, every new test mirrors
the structure of an existing test in the same directory, and every fixture mirrors
the Phase 28 `parser_differential_and_c14n/` precedent.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| **CREATE: lib/relyra/provider/adfs.ex** | provider preset | pure-data (behaviour impl) | `lib/relyra/provider/okta.ex` | exact |
| **CREATE: guides/recipes/adfs.md** | runbook | docs | `guides/recipes/okta.md` | exact |
| **CREATE: test/security/authn_request_signing_test.exs** | security corpus | request-response (mutation test) | `test/security/xml/adversarial_crypto_test.exs` | exact (corpus-shape) |
| **CREATE: test/fixtures/security/authn_request_signing/golden_redirect.txt** | golden bytes fixture | static | `test/fixtures/security/xml/parser_differential_and_c14n/assertion_inherited_ns.c14n` | exact |
| **CREATE: test/fixtures/security/authn_request_signing/golden_redirect_adfs.txt** | golden bytes fixture | static | same as above | exact |
| **CREATE: test/fixtures/security/authn_request_signing/golden_authnrequest.xml** | golden input fixture | static | `assertion_inherited_ns.input.xml` | exact |
| **CREATE: test/fixtures/security/authn_request_signing/golden_signing_key.pem** | committed PEM fixture | static | (no in-repo analog; first committed test PEM) | role-new |
| **CREATE: test/fixtures/security/authn_request_signing/PROVENANCE.md** | fixture provenance | docs | `test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md` | exact |
| **CREATE: priv/repo/migrations/<UTC>_add_signed_request_encoding_to_relyra_connections.exs** | migration | DDL | `priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs` | exact |
| **MODIFY: lib/relyra/security/algorithm_policy.ex** | crypto primitive | transform | `digest_atom_for_signature_method/1` (same file, lines 99-113) | exact |
| **MODIFY: lib/relyra/security/signature.ex** | crypto primitive | transform | `do_verify/4` sibling + `public_key_from_cert_chain/1` (same file) | exact |
| **MODIFY: lib/relyra/protocol/binding.ex** | binding | transform | `encode_redirect/3` (in-place extension, same file) | exact (self-extend) |
| **MODIFY: lib/relyra/protocol/metadata.ex** | metadata | transform | own `build_sp_metadata/2` (gating on existing `connection` map) | exact (self-extend) |
| **MODIFY: lib/relyra.ex** | public API | request-response | `do_start_login/3` (same file, lines 39-101) | exact (self-extend) |
| **MODIFY: lib/relyra/phoenix/controllers/login_controller.ex** | controller | request-response | `redirect_to_idp/3` (same file, lines 45-54) | exact (self-edit) |
| **MODIFY: lib/relyra/ecto/connection.ex** | Ecto schema | DDL/cast | own `:sign_authn_requests` field + `@provider_presets` list | exact (self-extend) |
| **MODIFY: lib/relyra/ecto/connection_snapshot.ex** | snapshot hydration | transform | `base_runtime_attrs/1` (same file, lines 69-90) | exact (self-extend) |
| **MODIFY: lib/relyra/connection.ex** | runtime struct | static | own `sign_authn_requests: false` field | exact (self-extend) |
| **MODIFY: lib/relyra/provider.ex** | registry | static | `@presets` map (same file, lines 86-90) | exact (self-extend) |
| **MODIFY: mix.exs** | CI alias | declarative | `ci.security` `cmd mix test` lines + `ci.docs` `cmd test -f` lines | exact (self-extend) |
| **MODIFY: test/security/ci_gate_integrity_test.exs** | meta-gate | declarative | own `@gated_suites` constant (same file, lines 32-42) | exact (self-extend) |
| **MODIFY: test/relyra/protocol/binding_test.exs** | unit test | request-response | own `describe "encode_redirect/3"` block | exact (self-extend) |
| **MODIFY: test/relyra/protocol/metadata_test.exs** | unit test | request-response | own `describe "build_sp_metadata/2"` blocks | exact (self-extend) |
| **MODIFY: test/relyra/security/algorithm_policy_test.exs** | unit test | request-response | own `digest_atom_for_signature_method/1` describe blocks | exact (self-extend) |
| **MODIFY: test/provider/provider_test.exs** | unit test | request-response | own preset-registration test cases | exact (self-extend) |
| **MODIFY: test/relyra/security/signature_test.exs** | unit test | request-response | own describe blocks (path: existing file extended) | role-match |
| **MODIFY: test/relyra/ecto/connection_test.exs** | unit test | request-response | own `:allow_idp_initiated` test pattern | exact (self-extend) |
| **MODIFY: test/relyra/connection_snapshot_test.exs** | unit test | request-response | own provider-default hydration tests | exact (self-extend) |
| **MODIFY: test/relyra_test.exs** | unit test | request-response | own `start_login/3` tuple-contract test | exact (self-extend) |
| **MODIFY: test/phoenix/login_controller_test.exs** | unit test | request-response | own `GET /:connection_id/login` test | exact (self-extend) |

## Pattern Assignments

### `lib/relyra/security/algorithm_policy.ex` — add `signing_digest_atom/1`

**Analog:** `lib/relyra/security/algorithm_policy.ex` lines 88-113 (the sibling `digest_atom_for_signature_method/1`).

**Module-attribute alias for the supported atom (place near top, after existing
`@aes_cbc_uris` block at line 21):**
```elixir
# Outbound AuthnRequest signing (Phase 35) — distinct error taxonomy from the
# inbound verify-side digest gate above. Outbound MUST NEVER voluntarily
# downgrade to SHA-1 (no legacy_sha1 hatch on this path).
```

**Function shape — copy the cond/String.contains? structure verbatim from lines 101-113, with
the error atoms swapped:**
```elixir
@doc """
Map a signature-method URI to the digest atom :public_key.sign/3 will use for
outbound HTTP-Redirect-binding AuthnRequest signing (Phase 35 D-05).

Mirrors `digest_atom_for_signature_method/1` (the inbound verify-side sibling at
lines 99-113) but emits a DISTINCT error taxonomy so error consumers can tell
"the SP refused to sign with this algorithm" apart from "the SP refused to
verify an inbound signature with this algorithm":

  * `{:ok, :sha256 | :sha384 | :sha512}` for the RSA-SHA{256,384,512} URIs
  * `{:error, :unsupported_signing_algorithm}` for any ECDSA URI (no SP ECDSA
    signing implementation in v1.3) — checked BEFORE the rsa-sha* suffix match
    so an "...#ecdsa-sha256" can never fall through
  * `{:error, :unknown_signing_algorithm}` for any unknown / non-binary URI

Used by `Relyra.Security.Signature.sign_redirect_query/3` (Phase 35 D-01).
"""
@spec signing_digest_atom(term()) ::
        {:ok, :sha256 | :sha384 | :sha512}
        | {:error, :unsupported_signing_algorithm | :unknown_signing_algorithm}
def signing_digest_atom(uri) when is_binary(uri) do
  cond do
    String.contains?(uri, "ecdsa") -> {:error, :unsupported_signing_algorithm}
    String.ends_with?(uri, "rsa-sha256") -> {:ok, :sha256}
    String.ends_with?(uri, "rsa-sha384") -> {:ok, :sha384}
    String.ends_with?(uri, "rsa-sha512") -> {:ok, :sha512}
    true -> {:error, :unknown_signing_algorithm}
  end
end

def signing_digest_atom(_uri), do: {:error, :unknown_signing_algorithm}
```

**Anti-patterns to avoid:**
- Do NOT collapse `signing_digest_atom/1` and `digest_atom_for_signature_method/1` into one
  function with a `:context` keyword arg (rejected in RESEARCH.md §"Cross-Phase Verification").
- Do NOT add a `legacy_sha1` hatch — outbound MUST NEVER voluntarily downgrade.
- Do NOT use `:unsupported_signature_algorithm` (the inbound atom) for outbound errors.

---

### `lib/relyra/security/signature.ex` — add `sign_redirect_query/3`

**Analog (shape):** `do_verify/4` private body (same file, lines 106-137) + `digest_atom/2`
private helper (lines 249-262) + `public_key_from_cert_chain/1` PEM-decode pattern
(lines 287-300).

**Imports already present** — no new aliases needed. `Relyra.Security.AlgorithmPolicy`
and `Relyra.Error` are already aliased at the top of the file.

**Placement:** insert AFTER `verify_metadata_root/4` and its private helpers (post line 104),
BEFORE `do_verify/4` (pre line 106), with public `@spec` and `@doc`. (Per RESEARCH.md §3.1.)

**Function shape (copy from RESEARCH.md §3.1 verbatim; key structural patterns to mirror):**

The `with` chain mirrors the `do_verify/4` style (signature.ex:144-153) — every fallible step
returns `{:ok, _} | {:error, %Error{}}`; the `with` collapses them into a single happy path.

```elixir
@doc """
Sign the pre-assembled HTTP-Redirect-binding query-string binary (OASIS SAML
2.0 Bindings §3.4.4.1) and return the URL-safe base64 Signature value to append.

`octets` is the LITERAL byte sequence that will appear on the wire BEFORE the
`&Signature=` parameter. The caller (Relyra.Protocol.Binding) is responsible
for the OASIS-mandated component order (SAMLRequest, RelayState-when-present,
SigAlg) and the per-value URL encoding. This function MUST NOT re-encode
anything inside — re-encoding here is the auth-bypass class called out in
OASIS §3.4.4.1 lines 620-623.

Returns `{:ok, base64_signature_value_url_encoded}` or `{:error, %Error{}}`.
"""
@spec sign_redirect_query(binary(), String.t(), keyword()) ::
        {:ok, binary()} | {:error, Error.t()}
def sign_redirect_query(octets, signature_method, opts \\ [])

def sign_redirect_query(octets, signature_method, opts)
    when is_binary(octets) and is_binary(signature_method) and is_list(opts) do
  details = %{connection_id: Keyword.get(opts, :connection_id)}

  with {:ok, digest_atom} <- signing_digest_atom(signature_method, details),
       {:ok, private_key} <- load_signing_key(opts, details),
       sig_bytes when is_binary(sig_bytes) <-
         safe_sign(octets, digest_atom, private_key, details) do
    {:ok, sig_bytes |> Base.encode64() |> URI.encode_www_form()}
  end
end
```

**PEM-decode pattern** — mirror `public_key_from_cert_chain/1` (lines 287-300) for the
load-signing-key private helper. Key idiom (rescue `pem_entry_decode` raises):

```elixir
defp load_signing_key(opts, details) do
  pem = Keyword.get(opts, :signing_key_pem) ||
        Application.get_env(:relyra, :sp_signing_key_pem)
  with pem when is_binary(pem) <- pem,
       [entry | _] <- :public_key.pem_decode(pem),
       key when is_tuple(key) <- :public_key.pem_entry_decode(entry) do
    {:ok, key}
  else
    _ ->
      {:error, Error.new(:key_not_configured,
        "SP signing private key is not configured",
        Map.put(details, :hint,
          "Set config :relyra, :sp_signing_key_pem to the PEM binary of the SP RSA private key"))}
  end
rescue
  _ ->
    {:error, Error.new(:key_not_configured,
      "SP signing private key could not be decoded",
      details)}
end
```

**`safe_sign/4` pattern** — mirror `safe_verify/4` (signature.ex:396-400):
```elixir
defp safe_sign(octets, digest_atom, private_key, details) do
  :public_key.sign(octets, digest_atom, private_key)
rescue
  _ ->
    {:error, Error.new(:key_not_configured,
      "SP signing private key failed at :public_key.sign/3",
      details)}
end
```

**Anti-patterns to avoid:**
- Do NOT introduce a new `Relyra.Security.RedirectSigning` module — keep the single crypto seam
  invariant (CLAUDE.md §"Key Architecture Seams"). RESEARCH.md §3.1 explicitly rejects this.
- Do NOT call `URI.encode_query/1` ANYWHERE inside this function (T-35-01 / OASIS §3.4.4.1
  lines 620-623). The octets MUST be signed verbatim.
- Do NOT introduce a parallel signer module like `XmldsigSigner` — use `:public_key.sign/3`
  directly (`xmldsig_signer.ex:291-297` is the inbound analog; reuse the same `FakeIdP.keypair/0`
  source for tests, never a separate keypair).
- Do NOT log key material in the `%Error{}` details map (`error.ex:39-46` redacts known keys but
  PEM bytes are unguarded).

---

### `lib/relyra/protocol/binding.ex` — extend `encode_redirect/3` IN-PLACE

**Analog:** own `encode_redirect/3` (same file, lines 6-23). The current 11-line function
is replaced; `decode_redirect/2` and the POST-binding helpers below it are untouched.

**Per RESEARCH.md §3.2, the recommendation is in-place extension (NOT a sibling
`encode_signed_redirect/4`).** Reasons captured: single redirect-encode entry point;
deflate logic is 100% shared between signed and unsigned paths; backward compatibility
preserved via return-shape rule (`%{...}` map when unsigned; `%{redirect_query: bytes}`
when signed).

**Signature change:**
```elixir
@spec encode_redirect(binary(), binary() | nil, keyword()) ::
        {:ok, map()} | {:error, Error.t()}
def encode_redirect(xml, relay_state, opts \\ [])
```
`relay_state` becomes `binary() | nil` so D-10's "RelayState omitted entirely when absent" rule
is expressible (verified safe per RESEARCH.md A7 — `relyra.ex:50-56` always passes non-nil).

**Deflate helper (place at TOP of file, after `alias Relyra.Error`):**
```elixir
defp deflate_xml(xml) when is_binary(xml) do
  z = :zlib.open()
  try do
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    iodata = :zlib.deflate(z, xml, :finish)
    :ok = :zlib.deflateEnd(z)
    IO.iodata_to_binary(iodata)
  after
    :zlib.close(z)
  end
end
```

The `try/after` is load-bearing (T-35-07; RESEARCH.md §3.2). `:zlib` allocates a NIF
resource; without `close/1` in `after`, an exception between `deflateInit` and `deflateEnd`
leaks the resource and eventually exhausts BEAM file descriptors.

**Opts to accept:**
- `:sign` (boolean, default `false`) — switches return shape.
- `:signing_key_pem` (PEM override; forwarded to `Signature.sign_redirect_query/3`).
- `:signature_method` (URI; default `"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"`).
- `:encoding` (`:rfc3986_upper` default | `:adfs_lower`).
- `:type` (`:request` default | `:response` — preserved).

**Signed octet template (D-10), literal-order concatenation:**
```
SAMLRequest=<urlenc(b64(deflate(xml)))>&RelayState=<urlenc(relay_state)>&SigAlg=<urlenc(sig_alg_uri)>
```
RelayState segment OMITTED ENTIRELY when nil (NOT empty-string). `SigAlg` is last.
`Signature` parameter (when emitted) is appended AFTER signing, NOT in the signed bytes.

**ADFS-lower post-process (D-08):**
```elixir
defp lowercase_hex(encoded) do
  Regex.replace(~r/%[0-9A-F]{2}/, encoded, &String.downcase/1)
end
```
Source: python3-saml `lowercase_urlencoding` flag (RESEARCH.md §5).

**Anti-patterns to avoid:**
- Do NOT add a sibling `encode_signed_redirect/4` function (RESEARCH.md §3.2 explicitly rejects
  this — doubles surface area for the raw-DEFLATE fix).
- Do NOT make deflate conditional on `:sign` (D-04: deflate is UNCONDITIONAL — fix-forward for
  the latent bug at lines 9-19; OASIS §3.4.4.1 mandates it for both paths).
- Do NOT use positive WindowBits (would produce zlib-wrapped output with header + Adler-32,
  failing the RFC 1951 contract). Use `-15` exactly.
- Do NOT use WindowBits `-8` (known zlib bug — RESEARCH.md §"`:zlib` API specifics" + Erlang
  manual).
- Do NOT swallow exceptions with `try/rescue` — use `try/after` and let `:zlib` errors
  propagate.
- Do NOT call `URI.encode_query/1` on a map of params to build the signed octets (T-35-01;
  the CVE-class footgun). Concatenate the literal template verbatim.

---

### `lib/relyra/protocol/metadata.ex` — gate signing `KeyDescriptor` + add `AuthnRequestsSigned`

**Analog:** own `build_sp_metadata/2` (same file, lines 17-46). Phase 34 wrote the unconditional
`KeyDescriptor use="signing"` block at lines 34-36; Phase 35 makes it conditional.

**Reads:** `connection.sign_authn_requests` field — already present from Phase 32
(`connection.ex:40`). Use the same `Map.get/3` pattern the file already uses for other
connection reads (e.g., `Map.get(connection, :sp_entity_id)` at line 18):
```elixir
sign_authn_requests = Map.get(connection, :sign_authn_requests, false) == true
```

**Gating shape** (replace lines 30-46 — the `"""..."""` heredoc — with conditional emission):

The two changes are:
1. `<md:SPSSODescriptor>` element (currently line 33) gains `AuthnRequestsSigned="true"`
   attribute IF AND ONLY IF `sign_authn_requests` is true. (Omit attribute entirely when
   false — do NOT emit `AuthnRequestsSigned="false"`; absence is the spec default; D-12.)
2. `<md:KeyDescriptor use="signing">...</md:KeyDescriptor>` block (currently lines 34-36)
   emitted IF AND ONLY IF `sign_authn_requests` is true.

The encryption KeyDescriptor (Phase 34, lines 37-40) stays UNCONDITIONAL (D-13).

**Skeleton (planner picks the exact interpolation shape — heredoc-with-conditional helpers
is cleanest; mirror the `encryption_methods/0` helper at lines 68-72):**

```elixir
defp signing_key_descriptor(true, signing_cert_b64) do
  """
      <md:KeyDescriptor use="signing">
        <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:X509Data><ds:X509Certificate>#{signing_cert_b64}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
      </md:KeyDescriptor>
  """
  |> String.trim_trailing()
end

defp signing_key_descriptor(false, _signing_cert_b64), do: ""

defp authn_requests_signed_attr(true), do: ~s( AuthnRequestsSigned="true")
defp authn_requests_signed_attr(false), do: ""
```

**Anti-patterns to avoid:**
- Do NOT emit `AuthnRequestsSigned="false"` — absence IS the spec default (D-12).
- Do NOT touch the encryption KeyDescriptor block (lines 37-40) — Phase 34 owns it (D-13).
- Do NOT introduce a new private key seam (`:sp_signing_key_pem` is for outbound signing only;
  metadata only consumes the PUBLIC cert via `:sp_signing_cert_pem` at line 24).

---

### `lib/relyra.ex` — thread `:redirect_query` through `start_login/3`

**Analog:** own `do_start_login/3` (same file, lines 39-101). The change is localized to the
`case Binding.encode_redirect(...)` block at lines 64-86.

**Read `connection.sign_authn_requests`** to decide which branch to call. Pattern mirrors
`read_field/2` at lines 361-363 (same file):
```elixir
sign = read_field(connection, :sign_authn_requests) == true
```

**Branch on `sign`:**
- Unsigned path → keep existing call `Binding.encode_redirect(authn_request_xml, relay_state)`;
  return shape stays `%{redirect_params: redirect_params}` (lines 65-83).
- Signed path → call `Binding.encode_redirect(authn_request_xml, relay_state, sign: true,
  signing_key_pem: ..., encoding: ..., signature_method: ...)`; return shape becomes
  `%{redirect_query: bytes}` instead of `:redirect_params`.

**Encoding resolution** — fold inline per RESEARCH.md §3.4:
```elixir
encoding = read_field(connection, :signed_request_encoding) || :rfc3986_upper
```

**Telemetry metadata** — preserve `base64_bytes` / `xml_bytes` shape (lines 78-80) so existing
telemetry consumers do not regress. For the signed case, add `redirect_query_bytes:
byte_size(bytes)` to the metadata map.

**Anti-patterns to avoid:**
- Do NOT remove `:redirect_params` from the unsigned return — adopters depend on it (D-02).
- Do NOT thread `:redirect_query` AND `:redirect_params` in the same return — they are
  mutually exclusive (corpus Row 5 pins this: `sign_authn_requests: false` → ONLY
  `:redirect_params`).
- Do NOT call `URI.encode_query/1` here either — the signed bytes flow through verbatim
  from `Binding.encode_redirect/3`.

---

### `lib/relyra/phoenix/controllers/login_controller.ex` — append signed query VERBATIM

**Analog:** own `redirect_to_idp/3` (same file, lines 45-54). The change is replacing
the existing 4-line URL-merge/encode body for the signed case.

**Current body (lines 46-49) — for the UNSIGNED case, KEEP this:**
```elixir
uri = URI.parse(sso_url)
existing_query = URI.decode_query(uri.query || "")
new_query = Map.merge(existing_query, redirect_params)
target = %{uri | query: URI.encode_query(new_query)} |> URI.to_string()
```

**For the SIGNED case (when `start_login/3` returns `:redirect_query` instead of
`:redirect_params`)** — append the pre-assembled binary VERBATIM:
```elixir
defp redirect_to_idp_signed(conn, sso_url, redirect_query) when is_binary(redirect_query) do
  separator = if String.contains?(sso_url, "?"), do: "&", else: "?"
  target = sso_url <> separator <> redirect_query

  conn
  |> redirect(external: target)
  |> halt()
end
```

**The dispatcher** — pattern-match in `create/2` (same file, lines 13-37) on the new
`:redirect_query` key vs existing `:redirect_params` key:
```elixir
case Relyra.start_login(connection, relay_context, opts) do
  {:ok, %{redirect_query: redirect_query}} ->
    redirect_to_idp_signed(conn, connection.idp_sso_url, redirect_query)

  {:ok, %{redirect_params: redirect_params}} ->
    redirect_to_idp(conn, connection.idp_sso_url, redirect_params)

  {:error, %Error{} = error} ->
    handle_error(conn, error, opts)
end
```

**Anti-patterns to avoid:**
- Do NOT call `URI.encode_query/1` on the signed query bytes (T-35-01 — the whole point of
  threading pre-assembled bytes through `:redirect_query` is to escape this call).
- Do NOT call `URI.decode_query/1` and re-merge — the bytes are already URL-encoded; touching
  them invalidates the signature.
- Do NOT mutate the existing `redirect_to_idp/3` private function — the unsigned path
  must keep working for non-ADFS adopters (D-02).
- (T-35-08 hardening; RESEARCH.md Open Q4) Recommended: before appending, parse `sso_url`
  and reject when any of `SAMLRequest`/`RelayState`/`SigAlg`/`Signature` already appear in
  the existing query. Surface as `%Error{type: :idp_sso_url_invalid}`.

---

### `lib/relyra/ecto/connection.ex` — register `:adfs` + add `signed_request_encoding` field

**Analog:** own `@provider_presets` list (line 23), `sign_authn_requests` field (line 40),
and `draft_changeset` cast list (lines 86-101). All three patterns are extended IN-PLACE.

**Change 1 — extend `@provider_presets` list (line 23):**
```elixir
@provider_presets [:okta, :entra, :google_workspace, :adfs]
```

**Change 2 — add `signed_request_encoding` schema field (after line 40):**
Per RESEARCH.md §3.3, type is `string` at the DB layer but use `Ecto.Enum` at the schema
layer (mirrors `provider_preset` at line 34 — string column, Ecto.Enum schema cast):
```elixir
field :signed_request_encoding, Ecto.Enum,
  values: [:rfc3986_upper, :adfs_lower]
```

**Change 3 — extend `draft_changeset` cast list (lines 87-101) AND `update_changeset` cast
list (lines 115-128):** add `:signed_request_encoding` to both lists.

**Change 4 — DB migration** (new file `priv/repo/migrations/<UTC>_add_signed_request_encoding_to_relyra_connections.exs`):
Mirror `priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs`
verbatim, with:
- field name `:signed_request_encoding`
- type `:string` (not `:boolean`)
- `null: true` (not `null: false` — `nil` is the safe default meaning "use `:rfc3986_upper`")
- no default

Reference template (the entire file):
```elixir
defmodule Relyra.Repo.Migrations.AddSignedRequestEncodingToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :signed_request_encoding, :string, null: true
    end
  end
end
```

**UTC timestamp:** follow project convention; the most-recent migration is
`20260525100001_...` so the new one will be a fresh UTC timestamp (today 2026-05-26).

**Anti-patterns to avoid:**
- Do NOT add the encoding field to embedded `RuntimePolicy` (Phase 32 D-11 convention: top-level
  boolean/atom toggles live on `Connection`, NOT in embedded RuntimePolicy; same convention
  `sign_authn_requests` follows at line 40).
- Do NOT make `signed_request_encoding` non-nullable — `nil` MUST mean "use default" (the
  default `:rfc3986_upper` is applied at signing time, not at the DB layer).
- Do NOT seed an enum default at the DB layer — Ecto enum values map to strings; default-handling
  belongs in the runtime fold-inline at `Binding.encode_redirect/3` (RESEARCH.md §3.4).

---

### `lib/relyra/ecto/connection_snapshot.ex` — thread `signed_request_encoding`

**Analog:** own `base_runtime_attrs/1` (same file, lines 69-90). The change is one line:
add `signed_request_encoding:` to the attribute map alongside `sign_authn_requests:`
(line 88).

**Exact addition (after line 88):**
```elixir
sign_authn_requests: Map.get(connection, :sign_authn_requests, false),
signed_request_encoding: Map.get(connection, :signed_request_encoding)
```

`nil` is the safe default (resolved to `:rfc3986_upper` at signing time per RESEARCH.md §3.4).

**Anti-patterns to avoid:**
- Do NOT default to `:rfc3986_upper` in the snapshot — resolution belongs at the binding layer
  (RESEARCH.md §3.4) so the ADFS preset's `:adfs_lower` value flows through correctly via
  `apply_provider_defaults/2` (lines 92-100).

---

### `lib/relyra/connection.ex` — runtime struct: mirror schema-side encoding field

**Analog:** own `defstruct` block (same file, lines 5-25) and `@type t` block (lines 27-47).
The `sign_authn_requests: false` line (line 24) is the exact pattern to mirror.

**Add to `defstruct` (alongside `sign_authn_requests: false` at line 24):**
```elixir
sign_authn_requests: false,
signed_request_encoding: nil
```

**Add to `@type t` (alongside line 46):**
```elixir
sign_authn_requests: boolean(),
signed_request_encoding: :rfc3986_upper | :adfs_lower | nil
```

---

### `lib/relyra/provider.ex` — register `:adfs => Relyra.Provider.ADFS`

**Analog:** own `@presets` map (same file, lines 86-90). Single-line extension:
```elixir
@presets %{
  okta: Relyra.Provider.Okta,
  entra: Relyra.Provider.Entra,
  google_workspace: Relyra.Provider.GoogleWorkspace,
  adfs: Relyra.Provider.ADFS
}
```

No other change. `list/0`, `fetch!/1`, `apply_defaults/2`, etc. all derive from `@presets`.

---

### `lib/relyra/provider/adfs.ex` — new provider preset (CREATE)

**Analog:** `lib/relyra/provider/okta.ex` (94 lines) AND `lib/relyra/provider/entra.ex`
(98 lines). The ADFS preset uses the EXACT skeleton — `@behaviour Relyra.Provider`,
`@impl true` for each callback (`id/0`, `display_name/0`, `default_config/0`, `labels/0`,
`footguns/0`, `guide_url/0`).

**Skeleton (mirror `okta.ex` lines 1-25 + lines 91-94):**
```elixir
defmodule Relyra.Provider.ADFS do
  @moduledoc false

  @behaviour Relyra.Provider

  @impl true
  def id, do: :adfs

  @impl true
  def display_name, do: "Active Directory Federation Services"

  @impl true
  def default_config do
    [
      provider_preset: :adfs,
      sign_authn_requests: true,
      signed_request_encoding: :adfs_lower,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      algorithm_policy: %{signing: :rsa_sha256, digest: :sha256}
    ]
  end

  @impl true
  def labels do
    %{
      sp_entity_id: %{
        idp_label: "Relying Party Trust Identifier",
        idp_section: "Identifiers",
        hint: "ADFS uses this as the SAML Audience"
      },
      acs_url: %{
        idp_label: "SAML Assertion Consumer Endpoint",
        idp_section: "Endpoints",
        hint: "ADFS shows it under 'POST SAML Assertion Consumer Endpoints'"
      },
      idp_sso_url: %{
        idp_label: "SAML 2.0/WS-Federation URL",
        idp_section: "Endpoints",
        hint: "Typically https://<adfs-host>/adfs/ls/"
      },
      idp_certificate: %{
        idp_label: "Token-signing certificate",
        idp_section: "Certificates",
        hint: "Export the active token-signing cert as Base-64 X.509"
      },
      signing_algorithm: %{
        idp_label: "Secure hash algorithm",
        idp_section: "Advanced",
        hint: "Set to SHA-256 (the ADFS default since Server 2016)"
      }
    }
  end

  @impl true
  def footguns do
    [
      # Mirror okta.ex:62-87 — id, severity, message, check/1 closure
      # Suggested footguns:
      # - :adfs_unsigned_authn_requests — warn if sign_authn_requests is false (ADFS strict)
      # - :adfs_sha1 — warn if signing algorithm is SHA-1
    ]
  end

  @impl true
  def guide_url,
    do: "https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust"
end
```

**Note on `default_config/0`** — D-15 specifies the EXACT map shape. Note the field-name
KEYWORD: `sign_authn_requests: true` (not `sign_authn_requests?:`), matching the Connection
schema field name at `connection.ex:40` — Phase 32 D-10/D-11 chose unsuffixed atoms for
DB-backed booleans (vs the runtime-only `?`-suffixed atoms like `allow_idp_initiated?` for
ones derived from RuntimePolicy).

**Anti-patterns to avoid:**
- Do NOT diverge from the `Provider` behaviour callback set — all six callbacks must be
  implemented (`@behaviour Relyra.Provider` ensures compile-time enforcement).
- Do NOT register `:adfs` in `@presets` (provider.ex:86-90) AND `@provider_presets`
  (connection.ex:23) in only one place — both registrations are required (two-registration
  pattern from Phase 32 D-11).
- Do NOT add fields to `default_config/0` that aren't accepted by `Connection` schema cast
  (would silently drop on Ecto cast — verify `signed_request_encoding` is in the cast list
  before this preset is used).

---

### `guides/recipes/adfs.md` — operator runbook (CREATE)

**Analog:** `guides/recipes/okta.md` (111 lines). Same H1 shape, same "Tested against"
preamble, same "Relyra owns / IdP owns / Host owns" tri-table, same numbered config
sections, same "Common failures" table, same "Day-2 notes" + "Related case studies"
closers.

**Required sections (per D-17):**
1. **H1:** `# Active Directory Federation Services + Relyra`
2. **Tested against** (mirror okta.md:9-13)
3. **Overview** — when to use the ADFS preset; ADFS 3.0/4.0/5.0 version notes
4. **Relyra owns / IdP owns / Host owns** tri-table (mirror okta.md:15-34)
5. **SP-side config** — minimal `:relyra` Application config with `:sp_signing_key_pem`;
   connection creation with `provider_preset: :adfs` (mirror okta.md:36-72)
6. **ADFS-side PowerShell** — canonical block from D-18:
   ```powershell
   $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 "C:\path\to\sp-signing.cer"
   Set-AdfsRelyingPartyTrust `
     -TargetName "Relyra App" `
     -SignedSamlRequestsRequired $true `
     -RequestSigningCertificate @($cert) `
     -SignatureAlgorithm "https://www.w3.org/2001/04/xmldsig-more#rsa-sha256" `
     -SamlResponseSignature "MessageAndAssertion"
   ```
7. **Claim rules** — paste-ready Issuance Transform Rules emitting NameID + emailaddress /
   givenname / surname / name
8. **Interop notes** — `+`-vs-`%20` and lowercase-hex encoding (`:adfs_lower`);
   SHA-1-vs-SHA-256 redirect-binding interop; the independence of `-SignatureAlgorithm`
   (outbound) from inbound `SigAlg` verification
9. **Common failures** table (mirror okta.md:89-95) — common ADFS rejection patterns;
   `WantAuthnRequestsSigned` vs `SignedSamlRequestsRequired` (the PowerShell flag) name
   divergence
10. **Day-2 notes** + **Related case studies** (mirror okta.md:97-110)

**Voice:** per `prompts/relyra-brand-book.md` (cited in CONTEXT.md canonical_refs) — concise,
operator-facing, no superlatives, no marketing.

**Wire into docs:** add to `mix.exs` `docs/0` extras list (lines 107-126) and add
`"cmd test -f guides/recipes/adfs.md"` line to `ci.docs` alias (line 142).

**Anti-patterns to avoid:**
- Do NOT place the runbook at `guides/providers/adfs.md` — that directory does not exist
  (RESEARCH.md §3.5 confirmed via `ls`); use `guides/recipes/adfs.md` for collection-locality.
- Do NOT publish the runbook without Wave 0 verification of the Microsoft Learn page for
  Server 2025 (RESEARCH.md A1 — assumption MEDIUM-confidence).

---

### `test/security/authn_request_signing_test.exs` — new adversarial corpus (CREATE)

**Analog:** `test/security/xml/adversarial_crypto_test.exs` lines 1-120 (the corpus shape model;
NEVER weakened per CLAUDE.md "Testing Requirements"). Same `@moduletag` pattern, same exact
`%Error{type: ...}` pinning, same FakeIdP-driven inputs, same one-`describe`-per-row layout.

**Module header (mirror lines 1-46 of `adversarial_crypto_test.exs`):**
```elixir
defmodule Relyra.Security.AuthnRequestSigningTest do
  @moduledoc """
  Phase 35 (AUTHN-01) — adversarial corpus for HTTP-Redirect-binding AuthnRequest signing.

  Five rows pin the bit-for-bit golden output, the ADFS-lower variant, the
  re-serialization regression (the OASIS §3.4.4.1 raw-octet invariant), the
  round-trip verify, and the toggle-off no-op. The signer is :public_key.sign/3
  against FakeIdP-managed key material (no parallel signer module — mirrors the
  anti-divergent-signer discipline of XmldsigSigner for the inbound path).

  This corpus is gated in mix ci.security as its own `cmd mix test` line and
  registered in test/security/ci_gate_integrity_test.exs @gated_suites (Phase 30
  hollow-gate fix).
  """
  use ExUnit.Case, async: true

  @moduletag :authn_request_signing

  alias Relyra.Error
  alias Relyra.TestSupport.FakeIdP
end
```

**Each row pattern — mirror `adversarial_crypto_test.exs:56-67` structure:**
```elixir
describe "row 1 — golden positive control (:rfc3986_upper)" do
  @tag :row_golden
  test "start_login produces bit-for-bit match against committed golden" do
    expected = File.read!("test/fixtures/security/authn_request_signing/golden_redirect.txt")

    assert {:ok, %{redirect_query: actual}} =
             Relyra.start_login(connection_signed(:rfc3986_upper), relay_context(), opts())

    assert actual == expected
  end
end
```

The exact `%Error{type: ...}` pin for the toggle-off no-op (Row 5):
```elixir
describe "row 5 — toggle-off no-op (sign_authn_requests: false)" do
  @tag :row_toggle_off_noop
  test "emits no SigAlg / Signature keys" do
    assert {:ok, %{redirect_params: params}} =
             Relyra.start_login(connection_unsigned(), relay_context(), opts())

    refute Map.has_key?(params, "SigAlg")
    refute Map.has_key?(params, "Signature")
    refute Map.has_key?(params, :redirect_query)
  end
end
```

**Key material** — load the committed PEM (RESEARCH.md A4 mitigation; do NOT use
`FakeIdP.keypair/0` directly because it is non-deterministic per-test-run):
```elixir
setup do
  pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
  Application.put_env(:relyra, :sp_signing_key_pem, pem)
  on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)
  :ok
end
```

**Anti-patterns to avoid:**
- Do NOT add new rows to `test/security/xml/adversarial_crypto_test.exs` — that corpus is
  PERMANENTLY frozen (CLAUDE.md). AUTHN-01 is a SEPARATE file.
- Do NOT introduce a parallel signer module — corpus calls `Relyra.start_login/3` (the
  production path) and `:public_key.sign/3` directly for Row 3's mutation.
- Do NOT recompute the golden bytes inline — read from committed fixture (Phase 28 pattern).
- Do NOT pin a bare `{:ok, _}` / `{:error, _}` — every assertion pins the EXACT
  `%Error{type: ...}` or `%{...}` shape (adversarial_crypto_test.exs:22-25).
- Do NOT use a `FakeIdP.keypair/0` regenerated per test run for the golden bytes —
  use the committed PEM at `test/fixtures/security/authn_request_signing/golden_signing_key.pem`
  (RESEARCH.md A4).

---

### `test/fixtures/security/authn_request_signing/` — committed fixtures (CREATE)

**Analog:** `test/fixtures/security/xml/parser_differential_and_c14n/` directory contents:
- `assertion_inherited_ns.input.xml` — committed input
- `assertion_inherited_ns.c14n` — committed expected bytes (NO trailing newline, raw UTF-8)
- `mixed_content.input.xml` / `mixed_content.c14n` — same pattern
- `PROVENANCE.md` — fingerprints + byte counts + oracle toolchain + reproduce instructions

**Files Phase 35 commits:**
| File | Role | Provenance to record |
|------|------|---------------------|
| `golden_authnrequest.xml` | input XML | byte count; fixed `ID`/`IssueInstant`/`Destination` for determinism |
| `golden_signing_key.pem` | RSA-2048 private key | generated via `:public_key.generate_key({:rsa, 2048, 65_537})`; SHA-256 fingerprint; minted once + never reused for any other phase |
| `golden_redirect.txt` | expected bytes (`:rfc3986_upper`) | byte count; sha256; minted via `Relyra.start_login/3` once |
| `golden_redirect_adfs.txt` | expected bytes (`:adfs_lower`) | byte count; sha256; structural diff vs `golden_redirect.txt` (hex-case only) |
| `PROVENANCE.md` | provenance manifest | spec citation chain |

**`PROVENANCE.md` template** — mirror lines 1-143 of
`test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md`. Required sections:
1. **H1** with directory name
2. **Why these fixtures exist** (bit-for-bit golden invariant for AUTHN-01)
3. **Fixtures table** with `File / Bytes / sha256` columns (mirror lines 15-20)
4. **Each fixture's structural notes** (what it exercises; the `:adfs_lower` post-process
   shape; the byte-count delta)
5. **Spec citation chain:**
   - OASIS SAML 2.0 Bindings §3.4.4.1 (raw-octet template, lines 597-625)
   - OASIS lines 620-625 (the raw-octet invariant — load-bearing)
   - RFC 1951 (raw DEFLATE)
   - RFC 3986 §2.1 (uppercase hex preferred — RESEARCH.md §5 corrects CONTEXT.md's
     §6.2.2.1 citation)
   - python3-saml `lowercase_urlencoding` regex (the `:adfs_lower` variant source)
6. **Mint procedure** — mirror RESEARCH.md §2 final code block (the iex one-liner).
   Record: Elixir version, OTP version, fixture key fingerprint, byte-count.
7. **Re-mint policy** — never re-mint without updating `PROVENANCE.md` (mirror the C14N
   precedent at lines 73-90).

**Critical reproducibility constraint** (RESEARCH.md A4):
The `golden_signing_key.pem` is COMMITTED so re-mints reproduce. `FakeIdP.keypair/0`'s
`:persistent_term`-stored keypair is regenerated per-process and is NOT deterministic.

The golden XML's `<AuthnRequest ID="..." IssueInstant="..."/>` MUST have FIXED values
(no `:crypto.strong_rand_bytes/1` between mint and assertion). The mint helper must
fix `RelayState` (per D-19 Row 1: `"rs_relyra_phase35_golden"`) and must NOT call
`Relyra.Security.RelayState.issue/2` (which adds randomness).

**Anti-patterns to avoid:**
- Do NOT compute the golden bytes inline in the test (Phase 28 precedent: read committed
  bytes, never recompute).
- Do NOT commit a trailing newline in `golden_redirect*.txt` — the Phase 28 precedent's
  last byte is `0x3e` `>` deliberately (PROVENANCE.md:28-29; same Pitfall 4/6 applies here:
  the last byte of the redirect query is whatever the last percent-encoded value's last
  byte is — record exactly).

---

### `mix.exs` — `ci.security` line + `ci.docs` line + docs extras (MODIFY)

**Analog:** own `aliases/0` block (same file, lines 130-198). Three changes:

**Change 1 — `ci.security` alias (lines 152-182):** insert AFTER the `adversarial_crypto`
line (line 172):
```elixir
"cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
```

The comment at lines 159-167 explains the hollow-gate fix — DO NOT move the new line
above it. DO NOT collapse with the adversarial_crypto line into a multi-file `cmd mix test`.

**Change 2 — `ci.docs` alias (lines 141-146):** add a presence-check for the runbook:
```elixir
"cmd test -f guides/recipes/adfs.md",
```
Place alongside the existing `"cmd test -f guides/batteries_included.md"` line (line 142).

**Change 3 — `docs/0` extras list (lines 107-126):** add `"guides/recipes/adfs.md"`
alongside the existing `"guides/recipes/okta.md"` / `entra.md` / `google_workspace.md`
entries (lines 123-125).

**Anti-patterns to avoid:**
- Do NOT collapse the new `cmd mix test` line into a bare `test` step or a multi-file
  `cmd mix test` (Phase 30 hollow-gate fix; `ci_gate_integrity_test.exs:112-132`
  rejects both shapes).
- Do NOT add the suite to the `ci.security` alias without ALSO adding it to
  `@gated_suites` in `ci_gate_integrity_test.exs` (file-disjoint check at line 94
  enforces both directions).

---

### `test/security/ci_gate_integrity_test.exs` — extend `@gated_suites` (MODIFY)

**Analog:** own `@gated_suites` constant (same file, lines 32-42). Single-line extension:
```elixir
@gated_suites [
  # ... existing 9 entries ...,
  {"test/security/authn_request_signing_test.exs", "authn_request_signing"}
]
```

The 4-test meta-gate at lines 94-149 (file presence, alias presence, `cmd mix test` shape,
tag integrity) runs automatically against the new entry once it is added.

**For tag integrity (line 136 test) to pass**, the new suite file MUST declare
`@moduletag :authn_request_signing` (the regex at line 144 anchors on the whole-atom
boundary — a stray prefix like `:authn_request_sign` would NOT match).

---

### `test/relyra/protocol/binding_test.exs` — extend with raw-DEFLATE round-trip (MODIFY)

**Analog:** own `describe "encode_redirect/3"` block (same file, lines 6-18). The existing
two tests at lines 7-17 will need their assertions UPDATED — they currently assert
`result["SAMLRequest"] == Base.encode64(xml, padding: false)` which is the OLD-bug shape
(RESEARCH.md §"Existing fixtures — do any break?" — lines 419-422 confirm both lines
9 and 15 must change).

**New assertion shape** for the existing tests (replace lines 9, 15):
```elixir
assert is_binary(result["SAMLRequest"])
# Verify via inflate-round-trip (not by re-computing base64 of XML).
```

**New describe block to add** — RESEARCH.md §4 round-trip test verbatim:
```elixir
describe "encode_redirect/3 raw-DEFLATE (OASIS §3.4.4.1)" do
  test "deflate→base64 round-trips byte-identically via :zlib raw-inflate" do
    xml = ~s(<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="id_1"/>)
    {:ok, %{"SAMLRequest" => b64}} = Binding.encode_redirect(xml, "rs")
    {:ok, deflated} = Base.decode64(b64, padding: false)

    z = :zlib.open()
    :ok = :zlib.inflateInit(z, -15)
    inflated = :zlib.inflate(z, deflated) |> IO.iodata_to_binary()
    :ok = :zlib.inflateEnd(z)
    :ok = :zlib.close(z)

    assert inflated == xml
  end

  test "deflate is applied for both signed and unsigned paths (structural anti-regression)" do
    xml = ~s(<x/>)
    {:ok, %{"SAMLRequest" => unsigned_b64}} = Binding.encode_redirect(xml, "rs")
    # Verify the bytes are DEFLATE-shaped, NOT plain base64-of-XML
    refute unsigned_b64 == Base.encode64(xml, padding: false)
  end
end
```

This is a REGULAR (not security-gated) test — protects the binding contract.

**Anti-patterns to avoid:**
- Do NOT keep the old `assert result["SAMLRequest"] == Base.encode64(xml, padding: false)`
  assertions — they pin the OLD bug shape and will fail after deflate is added.
- Do NOT add `@moduletag :authn_request_signing` here — this is a regular regression test,
  not security corpus.

---

### `test/relyra/protocol/metadata_test.exs` — toggle on/off cases (MODIFY)

**Analog:** own existing `describe "build_sp_metadata/2 KeyDescriptors (SC#4)"` block
(same file, lines 26-50 visible). The `setup` block at lines 11-24 already configures
the SP signing + encryption certs — reuse it.

**New describe blocks (mirror the existing `describe` patterns at lines 26-50):**
```elixir
describe "build_sp_metadata/2 sign_authn_requests gating (Phase 35 AUTHN-03)" do
  test "toggle on emits AuthnRequestsSigned=\"true\" AND signing KeyDescriptor" do
    xml = Metadata.build_sp_metadata(connection_signed())
    assert String.contains?(xml, ~s(AuthnRequestsSigned="true"))
    assert String.contains?(xml, ~s(use="signing"))
  end

  test "toggle off omits BOTH AuthnRequestsSigned attr and signing KeyDescriptor" do
    xml = Metadata.build_sp_metadata(connection_unsigned())
    refute String.contains?(xml, "AuthnRequestsSigned")
    refute String.contains?(xml, ~s(use="signing"))
    # encryption descriptor STILL present (Phase 34, D-13)
    assert String.contains?(xml, ~s(use="encryption"))
  end
end
```

---

### `test/relyra/security/algorithm_policy_test.exs` — `signing_digest_atom/1` cases (MODIFY)

**Analog:** own `describe "digest_atom_for_signature_method/1 (D-06 RSA → atom)"` and
`describe "digest_atom_for_signature_method/1 (D-07 fail-closed)"` blocks (same file,
lines 28-60). Mirror these BLOCK-BY-BLOCK for `signing_digest_atom/1` — same three
"happy path RSA" tests and same three "ECDSA fail-closed + unknown URI" tests.

The existing `@rsa_sha256` / `@ecdsa_sha256` module attrs (lines 14-19) are reusable.

**New describe blocks (mirror lines 28-60):**
```elixir
describe "signing_digest_atom/1 (Phase 35 D-05 RSA → atom)" do
  test "rsa-sha256 URI maps to :sha256" do
    assert AlgorithmPolicy.signing_digest_atom(@rsa_sha256) == {:ok, :sha256}
  end

  test "rsa-sha384 URI maps to :sha384" do
    assert AlgorithmPolicy.signing_digest_atom(@rsa_sha384) == {:ok, :sha384}
  end

  test "rsa-sha512 URI maps to :sha512" do
    assert AlgorithmPolicy.signing_digest_atom(@rsa_sha512) == {:ok, :sha512}
  end
end

describe "signing_digest_atom/1 (Phase 35 D-05 fail-closed)" do
  test "ecdsa-sha256 URI fails closed with :unsupported_signing_algorithm" do
    assert AlgorithmPolicy.signing_digest_atom(@ecdsa_sha256) ==
             {:error, :unsupported_signing_algorithm}
  end

  test "all ECDSA URIs fail closed (sha384 / sha512 too)" do
    assert AlgorithmPolicy.signing_digest_atom(@ecdsa_sha384) ==
             {:error, :unsupported_signing_algorithm}
    assert AlgorithmPolicy.signing_digest_atom(@ecdsa_sha512) ==
             {:error, :unsupported_signing_algorithm}
  end

  test "an unknown URI fails closed with :unknown_signing_algorithm" do
    assert AlgorithmPolicy.signing_digest_atom(
             "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
           ) ==
             {:error, :unknown_signing_algorithm}
  end

  test "non-binary input fails closed with :unknown_signing_algorithm" do
    assert AlgorithmPolicy.signing_digest_atom(nil) ==
             {:error, :unknown_signing_algorithm}
    assert AlgorithmPolicy.signing_digest_atom(123) ==
             {:error, :unknown_signing_algorithm}
  end
end
```

**Critical: error atom difference** — note that the inbound side uses
`:unsupported_signature_algorithm` (one consolidated atom; lines 44-54 of existing tests),
but outbound uses TWO distinct atoms: `:unsupported_signing_algorithm` (ECDSA) and
`:unknown_signing_algorithm` (everything else). Tests must pin both distinct atoms.

---

### `test/provider/provider_test.exs` — `:adfs` preset registration (MODIFY)

**Analog:** own existing `"supported preset ids are registered"` and `"apply_defaults/2"`
tests (same file, lines 7-25). Two changes:

**Change 1 — extend `Provider.list()` assertion (line 8):**
```elixir
assert Provider.list() == [:adfs, :entra, :google_workspace, :okta]
assert Provider.fetch!(:adfs) == Relyra.Provider.ADFS
```

**Change 2 — add new test for ADFS defaults (mirror lines 14-25):**
```elixir
test "apply_defaults/2 returns ADFS-specific defaults" do
  config = Provider.apply_defaults(:adfs, sp_entity_id: "https://sp.example.com/metadata")

  assert Keyword.fetch!(config, :provider_preset) == :adfs
  assert Keyword.fetch!(config, :sign_authn_requests) == true
  assert Keyword.fetch!(config, :signed_request_encoding) == :adfs_lower
  assert Keyword.fetch!(config, :require_signed_assertions?) == true
end

test "translate_label/2 uses ADFS labels" do
  assert Provider.translate_label(:adfs, :sp_entity_id) == "Relying Party Trust Identifier"
  assert Provider.translate_label(:adfs, :idp_certificate) == "Token-signing certificate"
end
```

---

### `test/relyra/security/signature_test.exs` — `sign_redirect_query/3` cases (MODIFY)

**Analog:** own existing `describe "verify_metadata_root/4 trust rejections (...)"` block
(same file, lines 26-58). New describe block mirrors the shape (test-per-error-type
pattern).

**New describe block:**
```elixir
describe "sign_redirect_query/3 (Phase 35 AUTHN-01)" do
  test "signs raw octets verbatim and returns URL-encoded base64 signature" do
    Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

    octets = "SAMLRequest=...&SigAlg=..."
    assert {:ok, sig} =
             Signature.sign_redirect_query(octets, "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")
    assert is_binary(sig)
  end

  test "returns :key_not_configured when :sp_signing_key_pem is unset" do
    Application.delete_env(:relyra, :sp_signing_key_pem)

    assert {:error, %Error{type: :key_not_configured}} =
             Signature.sign_redirect_query(
               "SAMLRequest=x",
               "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
             )
  end

  test "returns :unsupported_signing_algorithm for ECDSA URI" do
    Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

    assert {:error, %Error{type: :unsupported_signing_algorithm}} =
             Signature.sign_redirect_query(
               "SAMLRequest=x",
               "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"
             )
  end

  test "returns :unknown_signing_algorithm for unknown URI" do
    Application.put_env(:relyra, :sp_signing_key_pem, fixture_pem())
    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

    assert {:error, %Error{type: :unknown_signing_algorithm}} =
             Signature.sign_redirect_query("SAMLRequest=x", "urn:bogus")
  end
end
```

---

### `test/relyra/ecto/connection_test.exs` — `signed_request_encoding` cast (MODIFY)

**Analog:** own existing `"draft_changeset allows setting allow_idp_initiated"` test
(same file, lines 11-15). Two new tests mirror that pattern:

```elixir
test "default signed_request_encoding is nil" do
  connection = %Connection{}
  assert connection.signed_request_encoding == nil
end

test "draft_changeset accepts :adfs_lower" do
  changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :adfs_lower})
  assert changeset.valid?
  assert Ecto.Changeset.get_change(changeset, :signed_request_encoding) == :adfs_lower
end

test "draft_changeset accepts :rfc3986_upper" do
  changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :rfc3986_upper})
  assert changeset.valid?
end

test "draft_changeset rejects unknown encoding" do
  changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :bogus})
  refute changeset.valid?
end
```

---

### `test/relyra/connection_snapshot_test.exs` — `signed_request_encoding` threading (MODIFY)

**Analog:** own existing `"hydrate applies provider defaults and canonical certificate
mapping"` test (same file, lines 7-44). Same `aggregate = %Connection{...}` shape;
extend with the new field assertion:
```elixir
test "hydrate threads signed_request_encoding to runtime" do
  aggregate = %Connection{
    id: Ecto.UUID.generate(),
    connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y9",
    provider_preset: :adfs,
    signed_request_encoding: :adfs_lower,
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_entity_id: "https://idp.example.com/metadata",
    idp_sso_url: "https://idp.example.com/sso",
    runtime_policy: %RuntimePolicy{},
    certificates: [active_signing_cert()]
  }

  assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)
  assert snapshot.signed_request_encoding == :adfs_lower
  assert snapshot.sign_authn_requests == true  # ADFS preset default
end
```

---

### `test/relyra_test.exs` — `:redirect_query` shape assertion (MODIFY)

**Analog:** own existing `"start_login/3 returns documented tuple contract"` test
(same file, lines 61-80). Add a new test for the SIGNED path that asserts the
`%{redirect_query: bytes}` return shape:

```elixir
test "start_login/3 returns :redirect_query for signed AuthnRequests" do
  pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
  Application.put_env(:relyra, :sp_signing_key_pem, pem)
  on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

  connection = %{
    idp_sso_url: "https://idp.example.com/sso",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    sign_authn_requests: true,
    signed_request_encoding: :rfc3986_upper
  }

  opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

  assert {:ok, %{redirect_query: bytes, request_id: _, relay_state: _}} =
           Relyra.start_login(connection, %{return_to: "/"}, opts)

  assert is_binary(bytes)
  assert String.starts_with?(bytes, "SAMLRequest=")
  assert String.contains?(bytes, "&SigAlg=")
  assert String.contains?(bytes, "&Signature=")
end
```

---

### `test/phoenix/login_controller_test.exs` — verbatim-append assertion (MODIFY)

**Analog:** own existing `"GET /:connection_id/login redirects to IdP"` test (same file,
lines 19-34). The existing test only asserts the URL CONTAINS `SAMLRequest=` etc; the new
test asserts the SIGNED path appends VERBATIM (no `URI.encode_query/1` mutation).

```elixir
test "GET /:connection_id/login appends signed query verbatim (no re-encode)" do
  conn = Phoenix.ConnTest.build_conn()
  Application.put_env(:relyra, :connection_resolver, FakeConnectionResolverSigned)
  Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
  pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
  Application.put_env(:relyra, :sp_signing_key_pem, pem)
  Relyra.RequestStore.ETS.ensure_table!()

  conn = get(conn, "/valid_signed/login")
  url = redirected_to(conn)

  # Signed path: URL contains a Signature parameter
  assert url =~ "Signature="
  # Verbatim: SigAlg in the URL exactly matches the SigAlg in the signed bytes
  # (mutation test — if the controller re-encoded, this would diverge)
end
```

The `FakeConnectionResolverSigned` test support needs `sign_authn_requests: true` on its
returned connection — either extend the existing `FakeConnectionResolver` or add a sibling
in `lib/relyra/test_support/`.

## Shared Patterns

### Authentication (no inbound auth here — SP-side outbound signing)

**N/A** — Phase 35 is outbound signing only. No middleware/guard layer applies. The SP
signing private key is loaded ONCE per `sign_redirect_query/3` call from
`Application.get_env(:relyra, :sp_signing_key_pem)`, mirroring the `KeyResolver.Default`
pattern at `lib/relyra/key_resolver/default.ex:11-17`.

### Error Handling

**Source:** `lib/relyra/error.ex` lines 1-19 — `Relyra.Error.new/3` free-atom taxonomy.

**Apply to:** All new error sites in `Signature.sign_redirect_query/3` and its helpers.

**Pattern (mirror `signature.ex:113`, `signature.ex:166-167`, `signature.ex:255-260`):**
```elixir
{:error,
 Error.new(
   :key_not_configured,
   "SP signing private key is not configured",
   Map.put(details, :hint, "Set config :relyra, :sp_signing_key_pem to ...")
 )}
```

**New atoms introduced by Phase 35** (free atoms; no central registry per
`error.ex:15-18`):
- `:key_not_configured` — `:sp_signing_key_pem` missing/unparseable (D-07)
- `:unsupported_signing_algorithm` — ECDSA URI for outbound (D-23)
- `:unknown_signing_algorithm` — unknown URI for outbound (D-23)
- `:idp_sso_url_invalid` — RECOMMENDED hardening per T-35-08; controller-side reject of
  `idp_sso_url` already containing `SAMLRequest`/`Signature`/etc query keys

**`details` map convention** — always include `connection_id` (when known); add
`:hint` for `:key_not_configured` and `:signature_method` for the two algorithm-rejection
atoms. PEM bytes MUST NOT appear (`error.ex:39-46` redacts known keys but PEM is unguarded).

### Validation

**Source:** `lib/relyra/security/algorithm_policy.ex` — fail-closed algorithm gate.

**Apply to:** `Signature.sign_redirect_query/3` calls `AlgorithmPolicy.signing_digest_atom/1`
FIRST (before key load, before sign), so ECDSA / unknown URIs reject without touching
key material.

**Pattern (mirror the `with`-chain at `signature.ex:144-152`):**
```elixir
with {:ok, digest_atom} <- signing_digest_atom(signature_method, details),
     {:ok, private_key} <- load_signing_key(opts, details),
     ...
```

### Telemetry

**Source:** `lib/relyra/security/signature.ex` lines 20-35 (`Relyra.Telemetry.span/3`
pattern).

**Apply to (RECOMMENDED, optional per planner):** `sign_redirect_query/3` could wrap its
body in `Relyra.Telemetry.span([:authn_request, :sign], metadata, fn -> ... end)` to
mirror inbound-side `verify/4`'s telemetry shape. CONTEXT.md does not require telemetry
in Phase 35, but adding it costs ~10 lines and gives adopters the symmetry. Planner picks.

### Test Conventions

**Source:** `test/security/xml/adversarial_crypto_test.exs` lines 22-25 (the structural
rule).

**Apply to:** All new tests in `test/security/authn_request_signing_test.exs`.

**Pattern:**
- Each assertion pins the EXACT `%Error{type: ...}` or `%{...}` shape (never bare
  `{:ok, _}` / `{:error, _}`).
- `@moduletag` AND per-test `@tag :row_name` on every test for `--only` granularity.
- `FakeIdP`-driven inputs — no parallel key generation.
- Golden bytes READ from committed files — NEVER recomputed inline.

## No Analog Found

None. Every Phase 35 file has a strong in-repo analog (extension-shaped phase).

## Cross-Cutting Architectural Patterns Worth Highlighting

### Two-registration pattern (provider presets)

Every provider preset MUST be registered in BOTH:
1. `lib/relyra/provider.ex` `@presets` map (compile-time module registry)
2. `lib/relyra/ecto/connection.ex` `@provider_presets` list (DB enum values)

Forgetting either breaks differently: missing from `@presets` → `Provider.fetch!/1` raises;
missing from `@provider_presets` → Ecto.Enum cast fails silently and the value is dropped on
write. Phase 32 D-11 documented this; Phase 35 inherits it.

### Single crypto seam (CLAUDE.md §"Key Architecture Seams")

`Relyra.Security.Signature` is the ONE entry point to signature operations. Phase 35's
`sign_redirect_query/3` extends this seam in-place — does NOT spawn a sibling module
`Relyra.Security.RedirectSigning`. RESEARCH.md §3.1 explicitly rejects the sibling-module
shape.

### Anti-divergent-signer discipline (`xmldsig_signer.ex:13-23`)

Test signers MUST share the production crypto path. Phase 35's adversarial corpus calls
`Relyra.start_login/3` (the production path) and `:public_key.sign/3` directly for
mutation rows. No new signer module. Inbound `XmldsigSigner` is the analog discipline.

### Phase 30 hollow-gate-fix structural enforcement

`ci.security` lines MUST be individual `cmd mix test` invocations (never bare `test` steps),
AND every gated suite must be in `ci_gate_integrity_test.exs` `@gated_suites`. The meta-gate
fails the build if either invariant breaks. Phase 35 adds one `cmd mix test` line + one
`@gated_suites` entry.

### Phase 28 fixture-commit precedent

Golden bytes are COMMITTED (not computed inline). `PROVENANCE.md` records fingerprints,
byte counts, mint procedure, toolchain versions, spec citation chain. Tests read committed
bytes and assert byte-equality. Phase 35 mints once + commits four files
(`golden_authnrequest.xml`, `golden_signing_key.pem`, `golden_redirect.txt`,
`golden_redirect_adfs.txt`) + `PROVENANCE.md`.

### Phase 32 schema-cast convention (top-level booleans, NOT embedded)

DB-backed connection-level toggles like `sign_authn_requests` (Phase 32) and
`signed_request_encoding` (Phase 35) live as TOP-LEVEL fields on `Connection` — NOT
inside the embedded `RuntimePolicy`. This keeps them directly queryable + cast-able
without traversing the embed. `RuntimePolicy` is reserved for runtime-only computed
fields (algorithm_policy, name_id_format, etc.).

## Metadata

**Analog search scope:**
- `lib/relyra/security/` (signature, algorithm_policy, xml/*)
- `lib/relyra/protocol/` (binding, metadata, authn_request)
- `lib/relyra/provider/` (okta, entra, google_workspace)
- `lib/relyra/ecto/` (connection, connection_snapshot)
- `lib/relyra/phoenix/controllers/` (login_controller)
- `lib/relyra/key_resolver/` (default)
- `lib/relyra/test_support/` (fake_idp, xmldsig_signer)
- `test/security/` (adversarial_crypto_test, ci_gate_integrity_test)
- `test/relyra/` (protocol/, security/, ecto/)
- `test/fixtures/security/xml/parser_differential_and_c14n/` (golden-fixture precedent)
- `guides/recipes/` (okta.md, entra.md, google_workspace.md)
- `priv/repo/migrations/` (most-recent migration template)

**Files scanned:** ~30 source files, ~15 test files, 3 fixture files, 1 migration file,
3 runbook files.

**Pattern extraction date:** 2026-05-26
