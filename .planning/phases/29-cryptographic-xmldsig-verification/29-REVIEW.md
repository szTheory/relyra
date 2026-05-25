---
phase: 29-cryptographic-xmldsig-verification
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/relyra/security/signature.ex
  - lib/relyra/security/xml/c14n.ex
  - lib/relyra/security/xml/pure_beam.ex
  - lib/relyra/security/xml/saxy_tree.ex
  - lib/relyra/security/algorithm_policy.ex
  - lib/relyra/metadata/auto_refresh.ex
  - lib/relyra/security/xml.ex
  - lib/relyra/test_support/xmldsig_signer.ex
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: criticals_resolved
resolved:
  critical: [CR-01, CR-02]
  warning: [WR-01]
open:
  warning: [WR-02, WR-03, WR-04, WR-05]
  info: [IN-01, IN-02, IN-03]
---

# Phase 29: Code Review Report

**Reviewed:** 2026-05-24
**Depth:** standard
**Files Reviewed:** 8
**Status:** criticals_resolved (both BLOCKERs + WR-01 fixed in-phase; remaining warnings/info tracked as follow-ups)

## Resolution (2026-05-24)

Validated all findings against the code, then fixed both criticals and the
highest-impact interop warning **in-phase** before completing Phase 29:

| Finding | Severity | Status | Commit |
|---------|----------|--------|--------|
| CR-01 — metadata trust bypass (verify against unpinned first cert) | Critical | ✅ Fixed | `8910200` |
| CR-02 — fingerprint over PEM text vs DER (pin never matches) | Critical | ✅ Fixed | `8910200` |
| WR-01 — line-wrapped base64 rejected (breaks real IdPs) | Warning | ✅ Fixed | `ef44482` |
| WR-02 — SignedInfo prefix-list mis-selection | Warning | ⏳ Deferred | `.planning/todos/pending/` |
| WR-03 — Reference/@URI not bound to consumed node (XSW defense-in-depth) | Warning | ⏳ Deferred | `.planning/todos/pending/` |
| WR-04 — enveloped metadata signature not pruned w/o explicit transform | Warning | ⏳ Deferred | `.planning/todos/pending/` |
| WR-05 — trust regex runs on pre-byte-guard raw XML | Warning | ⏳ Deferred | `.planning/todos/pending/` |
| IN-01..03 — allowlist/atom desync, unsigned-metadata flag shape, opaque render_signed_xml | Info | ⏳ Deferred | listed below |

CR-01 fix: `TrustAnchor.matching_pems/2` returns ONLY pinned cert(s); the
metadata path verifies against those alone (never the document set). CR-02 fix:
`TrustAnchor.fingerprint/1` now hashes DER (matches the operator pin task +
openssl); `import.ex` routes through it. WR-01 fix: `decode_b64/1` uses
`ignore: :whitespace`. New regression tests prove each. Full suite **547/0**;
`mix ci.security` exit 0.

The deferred warnings are interop/defense-in-depth (none re-open the closed
bypass) and are tracked as pending todos for a follow-up phase.

## Summary

This phase replaces the published-hex XMLDSig auth-bypass stub with genuine
cryptographic verification. The **assertion path** (`Signature.verify/4` →
`do_verify/4` → `cryptographically_verify/4`) is well-constructed: trust gates
run before crypto, ECDSA fails closed before any verify, `:public_key.verify`
and `:crypto.hash_equals` are wrapped against raises, the digest comparison has
a correct length guard before the constant-time compare, document KeyInfo is
rejected as a trust source, and there is no `{:ok}` fall-through that skips the
crypto. The configured `cert_chain` (operator-controlled) is the only key
source on the assertion path — that path is sound.

The **metadata-refresh path** is NOT sound. It introduces a genuine fail-OPEN
(CR-01): `Signature.verify_metadata_root/4` is handed the FULL ordered list of
document-supplied certificate PEMs, but `TrustAnchor.check/2` only requires that
ANY ONE of them match a pinned fingerprint, while `public_key_from_cert_chain/1`
verifies against the FIRST. An attacker who prepends their own cert to the
(public, easily-copied) legitimate cert passes the pin check and gets the
signature verified against their own key. Separately (CR-02), the trust-anchor
fingerprint is computed over PEM text while the operator-facing pin task and
every external tool compute it over DER bytes — the two can never match, so the
mechanism that is supposed to gate CR-01 is itself broken (and any operator who
"fixes" their pin to the PEM-text hash walks straight into CR-01).

Several fail-CLOSED interop defects (line-wrapped base64, prefix-list
mis-selection) will reject legitimately-signed real-world IdP responses.

## Critical Issues

### CR-01: Metadata trust bypass — first document cert used as verification key while ANY cert may satisfy the pin

**File:** `lib/relyra/metadata/auto_refresh.ex:153-159` (with `lib/relyra/security/signature.ex:287-300`, `lib/relyra/metadata/trust_anchor.ex:38-68`)

**Issue:** On the scheduled metadata-refresh trust path:

1. `extract_candidate_signing_pems/1` returns ALL `<X509Certificate>` bodies in
   the document, in document order (`auto_refresh.ex:168-188`).
2. `TrustAnchor.check(candidate_pems, pinned)` returns `:ok` if the candidate
   set is NOT disjoint from the pinned set — i.e. if **at least one** candidate
   matches a pinned fingerprint (`trust_anchor.ex:53`).
3. `Signature.verify_metadata_root(parsed_root, connection, candidate_pems)` is
   then called with the **unfiltered, document-ordered** PEM list, and
   `public_key_from_cert_chain([pem | _rest])` extracts the public key from the
   **FIRST** PEM only (`signature.ex:287-292`).

The cert that satisfies the pin and the cert whose key actually verifies the
signature are decoupled. Metadata is public, so an attacker can copy the
legitimate signing cert verbatim. They forge metadata signed with their OWN
key, emit:

```xml
<X509Certificate>ATTACKER_CERT</X509Certificate>
<X509Certificate>LEGIT_PINNED_CERT</X509Certificate>
```

`TrustAnchor.check` passes (the pinned legit cert is present). The signature is
then verified against `ATTACKER_CERT` (the first entry) — and it validates,
because the attacker signed with the matching private key. The forged metadata
revision is applied: attacker-controlled SSO endpoints / signing certs are
written for the connection. This is an auth-bypass on the metadata trust path —
the exact class Phase 29 exists to close.

**Fix:** Verify against ONLY the cert(s) that matched a pinned fingerprint, not
the whole document set. Have `TrustAnchor` return the matched PEM(s) and pass
only those forward:

```elixir
# trust_anchor.ex — return the matching PEMs, not just :ok
def matching_pems(candidate_pems, pinned_fingerprints) do
  pinned = MapSet.new(pinned_fingerprints, &normalize/1)
  matched = Enum.filter(candidate_pems, fn pem -> fingerprint(pem) in pinned end)
  case matched do
    [] -> {:error, Error.new(:trust_anchor_mismatch, ...)}
    pems -> {:ok, pems}
  end
end

# auto_refresh.ex do_verify_signature/3
with {:ok, candidate_pems} <- extract_candidate_signing_pems(xml),
     {:ok, pinned_pems}    <- TrustAnchor.matching_pems(candidate_pems, source.metadata_trust_fingerprints),
     {:ok, parsed_root}    <- pre_parse_for_signature(xml),
     {:ok, signed_node}    <- Signature.verify_metadata_root(parsed_root, connection, pinned_pems) do
  {:ok, signed_node}
end
```

Additionally harden `public_key_from_cert_chain/1` to try EACH pinned PEM (not
only the head) so a legitimate multi-cert rotation window still verifies, while
still never trusting an unpinned cert.

### CR-02: Trust-anchor fingerprint hashes PEM text, but the pin task documents DER — pin check can never match (and masks/inverts CR-01)

**File:** `lib/relyra/metadata/trust_anchor.ex:74-78` (invoked from `lib/relyra/metadata/auto_refresh.ex:154`; operator contract in `lib/mix/tasks/relyra.metadata.pin.ex:16-22`)

**Issue:** `TrustAnchor.fingerprint/1` computes
`:crypto.hash(:sha256, pem) |> Base.encode16(case: :lower)` — the SHA-256 of the
reconstructed **PEM string** (`-----BEGIN CERTIFICATE-----\n…`). The
operator-facing pin task (`relyra.metadata.pin`) instructs the operator to pin
the SHA-256 of the **DER** bytes:

```
openssl x509 -in metadata-signing.pem -outform DER | openssl dgst -sha256 | tr 'A-F' 'a-f'
```

These never coincide (verified locally: PEM-text hash
`e96b35…` vs DER hash `8f0c21…` for the same cert). Consequences:

- An operator who follows the documented DER procedure will have EVERY
  scheduled refresh rejected with `:trust_anchor_mismatch` — the entire signed
  metadata-refresh feature is dead-on-arrival (fail-CLOSED DoS for the feature).
- The PEM text is reconstructed at runtime by `auto_refresh.to_pem/1`
  (64-char chunked); even an operator who manually hashes a PEM must reproduce
  Relyra's exact wrapping/header bytes to match — a brittle, undocumented
  contract.
- An operator who debugs the failure by switching their pin to the PEM-text
  hash to make refresh work then steps directly into CR-01.

**Fix:** Compute the fingerprint over the DER certificate (the universal
convention), not the PEM text:

```elixir
def fingerprint(pem) when is_binary(pem) do
  with [entry | _] <- :public_key.pem_decode(pem),
       der when is_binary(der) <- elem(entry, 1) do
    :crypto.hash(:sha256, der) |> Base.encode16(case: :lower)
  else
    _ -> :error  # fail closed; never produce a comparable fingerprint from junk
  end
rescue
  _ -> :error
end
```

Note: `Relyra.Metadata.Import` (`import.ex:86-87`) and the `last_known_metadata_signing_certs`
drift detector also hash the PEM text. Align all three on the DER fingerprint so
the drift detector, the pin, and operator/openssl output agree. (These are out
of the explicit file list but are load-bearing for the in-scope `auto_refresh.ex`
trust decision.)

## Warnings

### WR-01: Line-wrapped base64 in DigestValue / SignatureValue is rejected — breaks most real IdPs

**File:** `lib/relyra/security/signature.ex:384` (`decode_b64/1`) and `lib/relyra/security/xml/pure_beam.ex:355-356,666` (`trimmed_node_text/1`)

**Issue:** `decode_b64/1` uses `Base.decode64/1` (no `ignore: :whitespace`), and
the DigestValue / SignatureValue strings only pass through `String.trim/1`
(leading/trailing only). Real IdPs (ADFS, Shibboleth, many OpenSAML stacks)
emit `<ds:SignatureValue>` and `<ds:DigestValue>` wrapped at 64/76 columns with
embedded newlines. `Base.decode64("YW\nJj")` returns `:error` (verified
locally), so every internally-wrapped value yields `:invalid_signature` /
`:digest_mismatch`. The test signer emits single-line base64, so the positive
control passes — masking this. Fail-CLOSED, but it denies legitimate logins /
refreshes broadly.

**Fix:** Strip internal whitespace before decoding, or use the whitespace-tolerant
form:

```elixir
defp decode_b64(value) when is_binary(value), do: Base.decode64(value, ignore: :whitespace)
defp decode_b64(_value), do: :error
```

### WR-02: `signed_info_prefix_list/1` can pull a Reference's PrefixList instead of CanonicalizationMethod's

**File:** `lib/relyra/security/signature.ex:380-382` with `lib/relyra/security/xml/c14n.ex:165-176`

**Issue:** `signed_info_prefix_list/1` calls
`C14N.prefix_list_from_transforms(signed_info_node)`, which does
`find_descendant(signed_info_node, "InclusiveNamespaces")` — the FIRST
`InclusiveNamespaces` anywhere under `SignedInfo`, in document order. The
PrefixList that governs canonicalization of `SignedInfo` itself belongs to
`SignedInfo/CanonicalizationMethod/InclusiveNamespaces`, but a
`SignedInfo/Reference/Transforms/.../InclusiveNamespaces` also matches. When
`CanonicalizationMethod` has no `InclusiveNamespaces` but a Reference transform
does, the wrong prefix list is applied to the SignedInfo C14N → wrong canonical
bytes → spurious `:invalid_signature`. Fail-CLOSED interop bug.

**Fix:** Scope the lookup to the `CanonicalizationMethod` child specifically:

```elixir
defp signed_info_prefix_list(%Node{} = signed_info_node) do
  case find_child(signed_info_node, "CanonicalizationMethod") do
    %Node{} = c14n_method -> C14N.prefix_list_from_transforms(c14n_method)
    _ -> []
  end
end
```

### WR-03: No check that `Reference/@URI` resolves to the bound (`:node`) element ID

**File:** `lib/relyra/security/xml/pure_beam.ex:345-382` and `lib/relyra/security/signature.ex:346-374`

**Issue:** `signed_candidates/1` binds `digest_value_b64` from
`find_first(signature_node, "DigestValue")` (the first Reference's digest) and
binds `:node` to the matched `<Assertion>`, but never verifies that the
SignedInfo `Reference/@URI` actually equals `#<assertion.ID>`. The digest is
recomputed over `:node` and compared to whatever the first Reference declared.
With a single Reference + single Assertion (the common and test case) this
happens to line up, but the binding is by position/firstness, not by URI
resolution. A document with a Reference whose URI points elsewhere (or multiple
References) can desynchronize what was signed from what is consumed. Combined
with the no-op `bind_signed_node/2` downstream
(`validation_pipeline.ex:177-179`, out of scope), the signed node's identity is
never reconciled with the consumed assertion's claims. Defense-in-depth gap on
the XSW surface.

**Fix:** When building the candidate, resolve the Reference URI and require it
to match the bound element's `ID` (strip the leading `#`); reject with
`:digest_mismatch` / `:signature_wrapping_suspected` when it does not. Bind
`digest_value_b64` from the matching Reference, not the first one.

### WR-04: Metadata digest recompute includes the enveloped `ds:Signature` unless the IdP declares the transform

**File:** `lib/relyra/security/xml/pure_beam.ex:214-236,466-502`

**Issue:** On the metadata path the bound `:node` is the entire
`EntityDescriptor`/`EntitiesDescriptor`, and its `ds:Signature` is a DIRECT
CHILD. Pruning of that signature from the canonical bytes only happens when the
Reference's `Transforms` list contains the enveloped-signature URI
(`pure_beam.ex:478`, `c14n.ex:185-191`). If a Reference omits an explicit
`<Transforms>` (or declares only exclusive-C14N), `transform_uris` is empty, no
prune occurs, and the recomputed digest is taken over bytes that still contain
the signature element → `:digest_mismatch` for an otherwise-valid enveloped
signature. Fail-CLOSED, but it will reject conformant enveloped metadata
signatures that rely on the implied transform.

**Fix:** For the metadata-root (enveloped) case, prune the bound `ds:Signature`
whenever the Reference targets the enclosing element, regardless of whether the
enveloped-signature transform URI is explicitly listed — or document and
enforce that metadata Signatures MUST declare the enveloped-signature transform
and reject (not silently mismatch) when they don't.

### WR-05: `extract_candidate_signing_pems/1` regex runs on raw, pre-byte-guard XML

**File:** `lib/relyra/metadata/auto_refresh.ex:153-188`

**Issue:** `extract_candidate_signing_pems/1` and `TrustAnchor.check/2` run on
the raw fetched binary BEFORE `pre_parse_for_signature/1` applies the
DOCTYPE/ENTITY/`max_bytes` guards (`pure_beam.ex:99-104`). The size cap before
the regex scan relies solely on `fetch_xml`'s `@req_max_response_size` (5 MB);
the explicit `max_bytes` (1 MB default) XXE/size guard is bypassed for the
extraction + trust-fingerprint step. The phase invariant is "byte guards run
BEFORE any verification" — they do precede the signature math, but the
trust-anchor decision and cert extraction happen on un-guarded input. A regex
`.*?` over X509Certificate bodies on a large doc is also a (catastrophic-
backtracking-adjacent) exposure on untrusted input.

**Fix:** Apply the DOCTYPE/ENTITY/`max_bytes` byte guards to the raw binary as
the FIRST step of `do_verify_signature/3`, before any regex extraction or
fingerprinting, so the entire trust path operates on guard-passed bytes.

## Info

### IN-01: `enforce_signature_method/2` / `digest_atom_for_signature_method/1` duplicate the SHA-256/384/512 suffix logic

**File:** `lib/relyra/security/algorithm_policy.ex:30-47,87-99`

**Issue:** The allowlist (`default/0`) and the digest-atom mapper independently
enumerate the RSA-SHA-2 URIs. If one is extended without the other (e.g. a new
allowed signature method), an allowed method could reach `digest_atom/2` and
fail with `:unsupported_signature_algorithm` (fail-closed, but a confusing
desync). Consider deriving the allowlist and the atom map from one source.

### IN-02: `verify_signature/3` `true ->` branch accepts unsigned metadata for any non-`true` flag value

**File:** `lib/relyra/metadata/auto_refresh.ex:130-142`

**Issue:** The final `cond` clause returns `{:ok, :legacy_unsigned}` whenever
`source.require_signed_metadata` is not literally `true` (including `nil`). The
schema default is `true` with `null: false` (`metadata_source.ex:46`,
migration `…000001:9`), so this is currently safe, but the code itself is
fail-open by shape: a future nullable column / unmigrated row would silently
skip signature verification. Prefer matching `require_signed_metadata == false`
explicitly and treating anything else as "must verify".

### IN-03: `render_signed_xml/1` produces non-canonical XML kept only for a legacy opaque key

**File:** `lib/relyra/security/xml/pure_beam.ex:691-699`

**Issue:** `render_signed_xml/1` emits attribute values and text WITHOUT any
escaping (`[" ", name, "=\"", value, "\""]`, raw `text`). It is documented as a
backward-compat opaque `:signed_xml` value not used for crypto, but it is
trivially malformed for any value containing `"`, `<`, or `&`, and its presence
invites accidental reuse as if it were canonical. Confirm no current or future
consumer treats `:signed_xml` as security-relevant; consider dropping it.

---

_Reviewed: 2026-05-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
