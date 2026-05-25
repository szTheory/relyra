---
phase: 34-validationpipeline-wiring-enc-01-complete
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/relyra/protocol/metadata.ex
  - lib/relyra/protocol/validation_pipeline.ex
  - lib/relyra/security/xml/pure_beam.ex
  - lib/relyra/test_support/fake_idp.ex
  - lib/relyra/test_support/xmldsig_signer.ex
  - test/security/xml_enc_adversarial_test.exs
  - test/relyra/protocol/decrypt_assertion_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 34: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 34 wires encrypted-assertion (XML-Enc) decryption into the validation pipeline.
I reviewed the decrypt pre-stage, the `encrypted_only?` / `build_pre_decrypt_parsed_doc`
PureBeam path, the SP metadata builder, and the test-support encrypt/sign generators
against the CLAUDE.md non-negotiable invariants.

**The core security ordering is sound.** The four invariants called out in the brief hold:

1. **Decrypt-then-verify ordering is preserved.** The pre-stage decrypts a single
   `<EncryptedAssertion>`, splices the plaintext, and re-parses through the SAME
   `PureBeam.parse_safely/2` seam. Because the recomposed document now carries a
   cleartext `<Assertion>`, `encrypted_only?/1` is false on re-parse, so
   `build_cleartext_parsed_doc/1` runs the FULL strict gates and
   `do_run_validations/6` runs `Signature.verify/4` before any identity field is
   read. I traced fixture 7 (post-signing NameID tamper) and confirmed it fails at
   the verification stage with no identity leak. No fail-open found.
2. **One crypto entry / opaque failure.** All decryption failure modes collapse to
   the single `:decryption_failed` atom (`XMLEnc.decrypt/3` and the pipeline arm);
   the no-oracle property holds.
3. **Ambiguity rejected before crypto.** `detect_encrypted/1` returns `:ambiguous`
   for cleartext+encrypted and for >1 encrypted BEFORE any `XMLEnc.decrypt/3` call.
4. **No identity field is surfaced from the pre-decrypt doc** — `build_pre_decrypt_parsed_doc/1`
   emits only response fields + `:parse_tree`.

The defects below are real but none is an auth bypass. The most important
(`WR-01`/`WR-02`) is a **second extraction mechanism** (a regex locator) running
alongside the tree detector — a parser differential that contradicts CLAUDE.md
invariant #2 and produces fail-closed false-rejects on otherwise-valid encrypted
Responses. The metadata builder (`WR-03`) emits unescaped attribute values, a latent
XML-injection / well-formedness defect.

## Warnings

### WR-01: Comment/CDATA-embedded `EncryptedAssertion` text causes a tree-vs-regex parser differential (false-reject)

**File:** `lib/relyra/protocol/validation_pipeline.ex:215-222`
**Issue:** The pre-stage uses TWO different extraction mechanisms over the same
bytes: a tree-walk detector (`detect_encrypted/1`, line 165) decides
`:none` / `:ambiguous` / `:single`, and a separate **regex** locator
(`locate_encrypted_assertion/1`, line 216) re-scans the raw binary to extract the
splice substring and enforce exactly-one-match. These two views disagree, which
is precisely the parser-differential class CLAUDE.md invariant #2
("one parse path / no parser differentials") forbids.

A SAML `<Response>` carrying a single genuine `<EncryptedAssertion>` PLUS an XML
comment or CDATA section that merely contains the literal text
`<EncryptedAssertion>...</EncryptedAssertion>` is detected as `{:single, node}`
by the tree (Saxy does not emit comment/CDATA content as elements), but the regex
`Regex.scan` counts BOTH substrings and returns `:ambiguous`, rejecting a valid
login. Reproduced:

```elixir
# Saxy sees ONE element; regex sees TWO substrings:
xml = "<Response>...<!-- <EncryptedAssertion>x</EncryptedAssertion> -->" <>
      "<EncryptedAssertion><EncryptedData/></EncryptedAssertion></Response>"
# detect_encrypted/1 -> {:single, _}   (correct)
# locate_encrypted_assertion/1 -> :ambiguous  (false reject)
```

This is fail-closed (no bypass) but is an availability defect and an attacker can
weaponize it: any party able to influence inert bytes in the Response (a comment,
a CDATA blob in an attribute-like context) can force `:ambiguous_assertion` on a
legitimate assertion.

**Fix:** Eliminate the second extraction path. Splice using the byte span the
**tree** already identified instead of re-scanning with a regex. Saxy gives you
the element's position via the ordered `:content` walk; thread the matched
`%Node{}` from `detect_encrypted/1` to a tree-driven byte slice (or serialize the
bound node) so detection and extraction share one source of truth. If a regex
locator must stay temporarily, restrict the scan to the element region the tree
identified rather than the whole binary, and document that the tree detector — not
the regex — is the authoritative exactly-one guard.

### WR-02: Locator regex does not enforce the prefix-match it documents

**File:** `lib/relyra/protocol/validation_pipeline.ex:216`
**Issue:** The docstring (lines 207-214) states the regex requires "the closing
tag's prefix to match the opening tag's," but the pattern
`~r/<(?:([\w.-]+):)?EncryptedAssertion\b.*?<\/(?:\1:)?EncryptedAssertion>/s`
makes the closing-prefix group `(?:\1:)?` optional via the `?` quantifier, so the
backreference is bypassed. A prefixed open with an unprefixed (or absent) close
matches:

```elixir
regex = ~r/<(?:([\w.-]+):)?EncryptedAssertion\b.*?<\/(?:\1:)?EncryptedAssertion>/s
Regex.scan(regex, "<saml:EncryptedAssertion><x/></EncryptedAssertion>")
#=> [["<saml:EncryptedAssertion><x/></EncryptedAssertion>", "saml"]]  # matches; docstring says it should not
```

Such mismatched-prefix XML is not well-formed and would be rejected by Saxy on the
re-parse (so this is fail-closed, not a bypass), but the code does not do what its
contract claims, and the implementation drift will silently rot the intended
exactly-one / prefix-matched guarantee. This is the same root cause as WR-01: a
regex standing in for the parser.

**Fix:** Preferred — remove the regex per WR-01. If retained, make the closing
prefix mandatory-when-the-open-is-prefixed by alternation rather than an optional
backreference group, e.g.
`~r/<([\w.-]+):EncryptedAssertion\b.*?<\/\1:EncryptedAssertion>|<EncryptedAssertion\b.*?<\/EncryptedAssertion>/s`
so a prefixed open can only pair with the same-prefixed close, and update or delete
the now-accurate docstring claim.

### WR-03: SP metadata builder interpolates `entityID` / `Location` without XML-attribute escaping

**File:** `lib/relyra/protocol/metadata.ex:32,41`
**Issue:** `issuer` (from `connection.sp_entity_id` / `connection.issuer`) and
`acs_url` (from `connection.acs_url`) are interpolated raw into XML attribute
values with no escaping. The connection is resolved from a request-supplied
`connection_id` route param via `ConnectionResolver` (see
`lib/relyra/phoenix/controllers/metadata_controller.ex:7-14`), so the trust level
of these strings depends entirely on the adopter's resolver. A value containing a
`"` breaks well-formedness and can inject sibling elements/attributes; a `<`
corrupts the element:

```elixir
acs_url = ~s(https://sp.example.com/acs"/><md:Injected x=")
# emitted:
# <md:AssertionConsumerService ... Location="https://sp.example.com/acs"/><md:Injected x=" index="1".../>
```

The cert bodies are base64-of-DER (safe). For a strict-by-default security library
that publishes this XML over an HTTP endpoint, emitting unescaped operator/-resolver
data is a defect even if exploitation requires a misconfigured or
attacker-influenced resolver.

**Fix:** Escape every interpolated attribute value. Build the document with an
escaping helper (or `Saxy.Builder` / `Saxy.encode!`) rather than a raw heredoc.
Minimal patch — escape `issuer` and `acs_url` before interpolation:

```elixir
defp xml_attr(nil), do: ""
defp xml_attr(v) when is_binary(v) do
  v
  |> String.replace("&", "&amp;")
  |> String.replace("<", "&lt;")
  |> String.replace(">", "&gt;")
  |> String.replace("\"", "&quot;")
end
# entityID="#{xml_attr(issuer)}" ... Location="#{xml_attr(acs_url)}"
```

### WR-04: Phase-34 added live encrypt/sign crypto to a module that ships in the prod release artifact

**File:** `lib/relyra/test_support/fake_idp.ex:106-185,203-225` (new `encrypt/2,3` and `encrypted_response/2`)
**Issue:** `mix.exs:43-44` compiles `test/support` only for `:test`, but
`FakeIdP` and `XmldsigSigner` live under `lib/relyra/test_support/`, so they are
compiled into EVERY environment including `:prod` (`elixirc_paths(_) -> ["lib"]`).
The placement under `lib/` is pre-existing, but this phase materially expands the
prod-shipped attack surface by adding a full XML-Enc *encryption* path (RSA-OAEP
key wrap, AES-GCM, fresh CEK generation) and an encrypted-Response forger to that
prod-loadable module. The `@prod_build` + `ensure_not_prod!/0` guard is a runtime
backstop that only fires if a specific entry function is *called*; the code, the
RSA keypair generator, and the signing primitives remain loadable in a release.

**Fix:** Move `lib/relyra/test_support/` to `test/support/` so `elixirc_paths/1`
excludes it from non-test builds (compile-time exclusion, not a runtime guard).
This is the standard Elixir convention and aligns with the `:test`-only intent the
`@prod_build` guard already signals. If the modules must remain published for
adopter test helpers, gate the new crypto-forging functions behind a separate
test-only module under `test/support/` and keep only inert builders in `lib/`.

## Info

### IN-01: `assertion_count` telemetry is 0 for encrypted-only Responses on the reject arms

**File:** `lib/relyra/protocol/validation_pipeline.ex:93,380-384`
**Issue:** `build_pre_decrypt_parsed_doc/1` (pure_beam.ex:272-282) does not set
`:signed_candidates`, so `assertion_count/1` returns 0 for an encrypted-only
Response. On the `:ambiguous` / `:decryption_failed` arms the count is read off the
outer pre-decrypt doc (line 93), so a Response that genuinely carried one encrypted
assertion is reported to telemetry as `assertion_count: 0`. The success arm is
correct (it counts the re-parsed cleartext doc). This is observability noise, not a
correctness/security issue.
**Fix:** Count `<EncryptedAssertion>` elements from the parse tree when
`:signed_candidates` is absent, or carry an explicit pre-decrypt count, so the
reject-arm telemetry reflects the one (or N) encrypted assertions that were present.

### IN-02: `cert_body/1` rescue silently masks PEM misconfiguration

**File:** `lib/relyra/protocol/metadata.ex:51-66`
**Issue:** `cert_body/1` rescues all exceptions and returns `""`, and the
`pem_decode` non-match arm also returns `""`. A malformed/wrong `sp_signing_cert_pem`
config therefore produces metadata with an empty `<ds:X509Certificate></ds:X509Certificate>`
body and no error — a silent misconfiguration that an operator may not notice until
an IdP rejects the metadata. The nil-safe-empty behavior is intentional per the
comment, but the rescue conflates "absent (fine)" with "present but invalid (a bug)".
**Fix:** Keep nil → `""`, but let a present-but-undecodable PEM surface a log warning
(or raise in non-prod) so a broken cert config is not swallowed.

### IN-03: `split_cipher_value/1` is computed twice per decrypt

**File:** `lib/relyra/security/xml_enc.ex:21,39` (dependency of the reviewed pre-stage)
**Issue:** `decrypt/3` splits the cipher value at line 21 (to obtain `auth_tag` for
the policy guard) and `do_decrypt/4` splits it again at line 39. Both succeed only
for `byte_size >= 28`, so behavior is correct, but the duplicate parse is dead-ish
work and a minor readability smell in the crypto hot path. Not in scope as a
performance issue; flagged only as a clarity note.
**Fix:** Thread the already-split `{iv, ciphertext, auth_tag}` from `decrypt/3` into
`do_decrypt/4` instead of re-splitting.

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
