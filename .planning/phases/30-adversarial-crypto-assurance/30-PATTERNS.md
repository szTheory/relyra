# Phase 30: Adversarial crypto assurance - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 5 (1 new, 3 modified, 1 regenerated)
**Analogs found:** 5 / 5

> This is a **consolidation + gating** phase. Every adversarial recipe already exists and passes
> in `test/relyra/security/signature_crypto_test.exs`. The work is **promotion** (FakeIdP delegates
> to the genuine signer), **gating** (name the new suite into `ci.security`), and **two precise new
> artifacts** (the c14n-preserved digest-mismatch case in the new suite + a `canonicalization_failed`
> JSON row). Prefer copying the existing recipes verbatim over re-deriving anything.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/security/xml/adversarial_crypto_test.exs` (NEW) | test | transform (genuine-then-mutate → verify) | `test/relyra/security/signature_crypto_test.exs` (`:202-255`, `:81-90`, `:131-141`, `:260-264`) | exact |
| `lib/relyra/test_support/fake_idp.ex` (MODIFY) | test-support / fixture-builder | transform (build → sign) | `lib/relyra/test_support/xmldsig_signer.ex` (`sign_response/1` `:161-194`, `self_signed_cert_pem/0` `:204-211`, `response_xml/3` `:236-264`) | exact (delegation target) |
| `priv/security_corpus.json` (MODIFY) | config / fixture-corpus | batch (static fixture rows) | existing `c14n-differential-001` row (`:62-76`) + xsw rows (`:32-61`) | exact |
| `mix.exs` (MODIFY) | config / CI alias | batch (alias step list) | existing `ci.security` corpus lines (`:160-161`) | exact |
| `CONFORMANCE.md` (REGENERATE) | generated doc | batch (rendered from manifest) | `mix relyra.conformance` (`relyra.conformance.ex` + `conformance_fixtures.ex`) | exact (generator-driven) |

---

## Pattern Assignments

### `test/security/xml/adversarial_crypto_test.exs` (NEW — test, transform → verify)

**Analog:** `test/relyra/security/signature_crypto_test.exs` (the source of every recipe; promote, do not re-derive)

**Recommended location/tag (discretion, D-08):** `test/security/xml/adversarial_crypto_test.exs`, `@tag :adversarial_crypto`. Colocated with the other security-corpus suites that `ci.security` names, so the alias edit is one line in the same neighborhood. A dedicated tag keeps the alias line distinct.

**Test module preamble pattern** (analog `:19-26`) — copy the `use`/`alias` block, adding `FakeIdP` for the ASSUR-02 end-to-end drive:
```elixir
use ExUnit.Case, async: true

alias Relyra.Error
alias Relyra.Security.Signature
alias Relyra.Security.XML.PureBeam
alias Relyra.TestSupport.FakeIdP            # NEW — drive the positive control end-to-end (ASSUR-02)
alias Relyra.TestSupport.XmldsigSigner
```
> Pitfall 4 (RESEARCH.md): the whole `ci.security` lane runs `--warnings-as-errors`. Keep `alias`/`import` tight — an unused alias aborts the lane even though tests pass.

**Recipe 1 — forged-sig** (analog `:81-90`, plus the throwaway-cert helper `:260-264`). The forged recipe operates on a synthetic `parsed_doc` whose candidate carries `signature_bytes`; when driving from `XmldsigSigner.signed_response/1` you decode the emitted `<SignatureValue>` to size the random bytes:
```elixir
# forged: replace the genuine SignatureValue with valid base64 of the right
# byte-length but the WRONG bytes (signature math fails).
forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(signed.signature_bytes)))
parsed_doc = put_candidate(signed.parsed_doc, :signature_value_b64, forged_b64)
assert {:error, %Error{type: :invalid_signature}} =
         Signature.verify(parsed_doc, connection(), signed.cert_chain)
```

**Recipe 2 — wrong-key** (analog `:215-224`; helper `:260-264`). Verify a GENUINE doc against a second, throwaway self-signed cert. Promote `throwaway_cert_pem/0` into the new suite:
```elixir
signed = XmldsigSigner.signed_response()
{:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])
wrong_cert_chain = [throwaway_cert_pem()]    # second, throwaway keypair — NOT FakeIdP's
assert {:error, %Error{type: :invalid_signature}} =
         Signature.verify(parsed_doc, connection(), wrong_cert_chain)

# helper to copy verbatim (analog :260-264):
defp throwaway_cert_pem do
  priv = :public_key.generate_key({:rsa, 2048, 65_537})
  %{cert: der} = :public_key.pkix_test_root_cert(~c"CN=relyra-wrong-key", key: priv)
  :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
end
```

**Recipe 3 — tampered-content / digest-mismatch** (analog `:226-235`). Use the signer's `tamper_name_id:` post-signing mutation (the SignatureValue stays valid; only referenced content changed):
```elixir
tampered = XmldsigSigner.signed_response(tamper_name_id: "attacker@evil.example.com")
{:ok, parsed_doc} = PureBeam.parse_safely(tampered.response_xml, [])
assert {:error, %Error{type: :digest_mismatch}} =
         Signature.verify(parsed_doc, connection(), tampered.cert_chain)
```

**Recipe 4 — c14n-differential (NEW, D-06)** — the genuinely-new case the existing suite does NOT cover. Mirror `maybe_tamper_name_id` (`xmldsig_signer.ex:317-328`): a post-signing **C14N-PRESERVED** mutation into the signed `<Assertion>` subtree → recomputed digest differs → `:digest_mismatch`. **Recommended mutation: add a non-namespace attribute to the `<Assertion>` apex** (PROVENANCE.md: attrs are sorted by resolved-URI-then-local but NEVER dropped — Pitfall 8 — so a new attribute is unambiguously preserved):
```elixir
signed = XmldsigSigner.signed_response()          # assertion_id default "assertion-1"
mutated_xml =
  String.replace(
    signed.response_xml,
    "<Assertion ID=\"assertion-1\">",
    "<Assertion ID=\"assertion-1\" Foo=\"bar\">",
    global: false
  )
{:ok, parsed_doc} = PureBeam.parse_safely(mutated_xml, [])
assert {:error, %Error{type: :digest_mismatch}} =
         Signature.verify(parsed_doc, connection(), signed.cert_chain)
```
> **MUST assert `:digest_mismatch` explicitly** so a no-op (C14N-normalized) mutation surfaces immediately as a `{:ok}`. See "C14N pitfall mutations to AVOID" in RESEARCH.md (attribute reordering, unused-ns decl, empty-element-expansion, text re-escaping all canonicalize identically and would falsely pass).

**Recipe 5 — positive control** (analog `:203-213`). Drive END-TO-END through `FakeIdP.sign` (literally exercises ASSUR-02 real-signing) with FakeIdP's own cert as the trust source:
```elixir
# ASSUR-02 end-to-end: FakeIdP.sign now delegates to XmldsigSigner.sign_response/1
b64 = FakeIdP.sign(FakeIdP.build_response())
{:ok, response_xml} = Base.decode64(b64, padding: false)
{:ok, parsed_doc} = PureBeam.parse_safely(response_xml, [])
assert {:ok, %Relyra.Security.SignedNode{} = signed_node} =
         Signature.verify(parsed_doc, connection(), [FakeIdP.self_signed_cert_pem()])
assert signed_node.signature_method == "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
```
> RESEARCH.md Open Q2 recommendation: drive the **positive control + at least one negative** through `FakeIdP.sign` end-to-end; the forged/wrong-key/tampered/c14n negatives may use `XmldsigSigner.signed_response/1` directly (cleaner mutation seam). Both go through the SAME signing path post-promotion (D-01).

**Recipe 6 — ECDSA fail-closed carry-over** (analog `:131-141`; A5 recommendation). Not one of the 5 named categories but the only `signature.ex` crypto error branch otherwise outside the gate. Include it as a 6th ASSERTION (not a 6th category):
```elixir
signed = XmldsigSigner.signed_response()
{:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])
parsed_doc = %{parsed_doc | signature_method: "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"}
assert {:error, %Error{type: :unsupported_signature_algorithm}} =
         Signature.verify(parsed_doc, connection(), signed.cert_chain)
```

**Local helpers to copy** (analog `:374-379`): `put_candidate/3` (`:374-377`) and `connection/0` (`:379`).
- `defp connection, do: %{connection_id: "conn-crypto"}`

**Scope guard (D-10 / Pitfall 6):** do NOT design an XSW-shaped input that tempts a WR-03 fix. If an input brushes WR-03 (Reference/@URI not bound to consumed node), assert CURRENT behavior and annotate "WR-03 follow-up — do not fix in-phase." Do NOT touch `lib/relyra/security/xml/pure_beam.ex` `signed_candidates/1` or `lib/relyra/security/signature.ex`.

---

### `lib/relyra/test_support/fake_idp.ex` (MODIFY — test-support, build → sign)

**Analog:** `lib/relyra/test_support/xmldsig_signer.ex` (the delegation target)

**Change A — `sign/2` delegates to the signer (D-01).** Current `sign(%Builder{}, opts)` (`fake_idp.ex:68-73`) base64-encodes the structure-only XML directly. Route it through `XmldsigSigner.sign_response/1` so the emitted bytes carry a real `DigestValue` + `SignatureValue`:
```elixir
# Current (fake_idp.ex:68-73) — structure-only, no real signature:
def sign(%Builder{} = builder, opts) do
  ensure_not_prod!()
  ensure_keypair!()
  xml = response_xml(builder, opts)
  Base.encode64(xml, padding: false)
end

# Promoted (D-01) — delegate; the signer self-parses the emitted bytes and binds
# the verifier's exact nodes, so byte-alignment is structural (no second canonicalizer):
def sign(%Builder{} = builder, opts) do
  ensure_not_prod!()
  ensure_keypair!()
  xml = response_xml(builder, opts)                            # D-02-corrected shape
  %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(xml)
  Base.encode64(signed_xml, padding: false)
end
```
> `sign_response/1` requires `<Assertion ID="...">` matching `<Reference URI="#...">`, a `<DigestMethod>` with no `<DigestValue>` yet (it injects), and a `<SignedInfo>` (it injects `<SignatureValue>` after `</SignedInfo>`). FakeIdP's `response_xml` already has the Assertion ID + Reference URI + DigestMethod (`fake_idp.ex:114,129`). Two shape fixes are needed (Change B).

**Change B — D-02 shape reconciliation in `response_xml/2` (`fake_idp.ex:103-136`).** Align FakeIdP's `<SignedInfo>` with the signer's shape (`xmldsig_signer.ex:252-264`):

| Diff | FakeIdP today | Signer shape | Action |
|------|---------------|--------------|--------|
| `<CanonicalizationMethod>` | MISSING (`:127-130`) | present, first child of `<SignedInfo>` (`:254`) | **ADD** — load-bearing (Pitfall 5) |
| whitespace collapse | `String.replace(~r/\s+/, " ")` (`:134`) | whitespace-free (`:236-263`) | **DROP** (D-02; low residual risk but decision-aligned) |
| SAML `xmlns` on Issuer/Assertion | present (`:112,114`) | absent | **KEEP** (self-parse keeps signer/verifier aligned; do NOT strip) |

Add as the FIRST child of `<SignedInfo>`, mirroring `xmldsig_signer.ex:254`:
```elixir
<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
```
> Pitfall 5: without `<CanonicalizationMethod>` the SignedInfo is malformed relative to the XMLDSig contract and the verifier's `signed_info_prefix_list/1` (`signature.ex:380-382`) reads an absent element — the FakeIdP positive control then returns `:invalid_signature`/`:digest_mismatch` despite a genuine signature. **Add a verification step:** the FakeIdP-driven positive control must return `{:ok, %SignedNode{}}` (Assumption A1).

**Change C — expose the trust cert (D-03).** Mirror the signer's `self_signed_cert_pem/0` (`xmldsig_signer.ex:204-211`, derived from `FakeIdP.keypair()` via `:public_key.pkix_test_root_cert/2`). Simplest form — delegate:
```elixir
defdelegate self_signed_cert_pem(), to: Relyra.TestSupport.XmldsigSigner
```

**Blast radius (RESEARCH.md Runtime State Inventory):** `FakeIdP.sign/2` is consumed ONLY by `test/test_support_demo_test.exs:31` (via `Relyra.TestSupport.sign_saml_response/2`), which posts to a STUB controller that asserts `:current_user` directly and does NOT run real verification — so the shape change does not break it. `auto_refresh_test.exs:531` uses `FakeIdP.keypair()` directly (inline signer), not `sign/2` — unaffected. Verify `mix test test/test_support_demo_test.exs` (in `ci.docs`) stays green; no code edit expected there.

---

### `priv/security_corpus.json` (MODIFY — config, batch fixture rows)

**Analog:** existing `c14n-differential-001` row (`priv/security_corpus.json:62-76`) — same `class`, same `expected_error_type`, same mechanism.

**CRITICAL routing nuance (Pitfall 1, HIGHEST RISK — carried from RESEARCH.md):** the JSON evaluator `evaluate_fixture/1` for class `parser_differential_and_c14n` (`corpus_security_test.exs:186-189`) runs ONLY `parse_safely → canonicalize` and **NEVER reaches `Signature.verify/4`**. Therefore:
- The `:digest_mismatch` proof CANNOT be a JSON row — it belongs in the NEW crypto-verify suite (Recipe 4 above).
- The JSON row MUST assert `expected_error_type: "canonicalization_failed"` (the existing evaluator's fail-closed result on the bare `parsed_doc` map handle — the SAME mechanism `c14n-differential-001` already proves).
- These are **two complementary cases**, mapped to **two different analogs** (the new suite vs. the JSON corpus).

**Row schema** — all fields enforced by `corpus_security_test.exs:126-141` (`requirement_ids` non-empty list `:129`, `family` non-empty `:132`, `provenance` non-empty map `:135`, `source_ref` non-empty `:138`) plus the manifest→error-type test `:11-17` (the `evaluate_fixture` result type must equal `expected_error_type`). Append this element to the top-level array, mirroring `c14n-differential-001`:
```json
{
  "id": "c14n-differential-rejection-002",
  "class": "parser_differential_and_c14n",
  "family": "signature_wrapping",
  "requirement_ids": ["CVE-REG-01", "ASSUR-01"],
  "expected_error_type": "canonicalization_failed",
  "provenance": {
    "source": "Phase 30 adversarial crypto assurance",
    "kind": "ported-fixture",
    "captured_at": "2026-05-24"
  },
  "source_ref": "relyra:phase-30:c14n-differential-rejection",
  "xml": "<Response ...>...</Response>",
  "notes": "C14N-differential REJECTION: the pure-BEAM seam fails closed (:canonicalization_failed) on an incomplete canonicalization handle; the :digest_mismatch crypto proof lives in the adversarial_crypto suite (ASSUR-01)."
}
```
> The `xml` should mirror `c14n-differential-001`'s shape (a complete `<Response>` whose `class` routes through the canonicalize-only branch and fails closed). `requirement_ids` accepts multiple IDs; tagging `ASSUR-01` traces the row to the phase.

---

### `mix.exs` (MODIFY — config, CI alias)

**Analog:** existing `ci.security` corpus lines (`mix.exs:160-161`)

**Current `ci.security` alias** (`mix.exs:152-169`) — note `signature_crypto_test.exs` is NOT named anywhere (verified), so the existing crypto proofs are currently OUTSIDE the gate (D-08). The relevant insertion point is right after the corpus/gate02 lines:
```elixir
"ci.security": [
  "ci.conformance",                              # runs relyra.conformance --check FIRST (drift gate)
  # ...
  "test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",   # :160
  "test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",                                                       # :161
  # INSERT the new suite here:
  "test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
  "deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v",
  "hex.audit",
  "sobelow --config"
]
```
> Pitfall 2: a suite not named in the alias does not gate. Verify by running `mix ci.security` and confirming the adversarial test count is non-zero. The line must carry `--warnings-as-errors` (Pitfall 4).

---

### `CONFORMANCE.md` (REGENERATE — generated doc, batch)

**Analog / generator:** `mix relyra.conformance` (`lib/mix/tasks/relyra.conformance.ex` + `lib/relyra/conformance_fixtures.ex`)

**Mechanism:** `relyra.conformance` reads `priv/security_corpus.json` (`security_rows`, `relyra.conformance.ex:54`) and renders the `CVE-REG-01 Regression Coverage` table (`security_rows_table/1` `:156-165`) plus the `cve_summary_lines` count (`:114-126`). Adding the JSON row changes BOTH the count line ("fixtures pinned: N") and the regression table — so the doc MUST be regenerated (D-09, Pitfall 3).

**Required conformance keys on the new row** (`conformance_fixtures.ex:4`): `id`, `requirement_ids`, `provenance` — all present in the row above. The generator additionally reads `family`, `class`, `expected_error_type`, `notes` (`relyra.conformance.ex:156-165`).

**Procedure (order matters — Pitfall 3):**
```bash
mix relyra.conformance          # regenerate (NO --check) — writes CONFORMANCE.md
mix relyra.conformance --check  # verify byte-equality; ci.conformance runs this FIRST in ci.security
```
> `--check` compares on-disk `CONFORMANCE.md` byte-for-byte against the freshly-rendered manifest (`check_report!/2` `:58-77`). `ci.security` → `ci.conformance` → `relyra.conformance --check` runs at `mix.exs:150,153`. Forgetting the regen aborts `ci.security` at its first step with "drift detected ... rerun mix relyra.conformance".

---

## Shared Patterns

### Genuine-then-mutate adversarial recipe (the core ASSUR-01 pattern)
**Source:** `test/relyra/security/signature_crypto_test.exs:202-235`
**Apply to:** every negative in the new suite.
Mint a genuine signed doc (`XmldsigSigner.signed_response/1` or `FakeIdP.sign`), apply ONE category-specific mutation, then `PureBeam.parse_safely → Signature.verify/4`, asserting a typed `{:error, %Relyra.Error{type: ...}}`. The mutation is post-signing and does NOT recompute digest/signature.

### One signing path / no canonicalizer differential (D-01/D-12)
**Source:** `lib/relyra/test_support/xmldsig_signer.ex:13-32` (moduledoc) + `:268-281` (`digest_for`/`sign_signed_info` use `PureBeam.canonicalize` and `C14N.serialize` — the verifier's engines)
**Apply to:** FakeIdP promotion + every recipe.
NEVER re-implement crypto in FakeIdP. The signer self-parses the EMITTED bytes and binds the verifier's exact nodes, so signer and verifier canonicalize identically. A parallel signer = a divergent canonicalizer = the T-29-15 false-positive (positive control passes for the wrong reason).

### Typed `%Relyra.Error{}` rejections
**Source:** `signature_crypto_test.exs` throughout; error atoms from `lib/relyra/security/xml.ex` union
**Apply to:** every assertion.
`:invalid_signature` (forged/wrong-key), `:digest_mismatch` (tampered/c14n-preserved), `:unsupported_signature_algorithm` (ECDSA), `:untrusted_certificate` (bad/empty cert), `:canonicalization_failed` (JSON parse-layer row). Each names the failed check; assert the exact type, never just `{:error, _}`.

### Fixture-as-source-of-truth with provenance + drift gate
**Source:** `priv/security_corpus.json` rows + `test/security/xml/corpus_security_test.exs:126-141` (provenance enforcement) + `lib/mix/tasks/relyra.conformance.ex` (`--check`)
**Apply to:** the new JSON row + CONFORMANCE.md regen.
Every JSON row carries `provenance`/`requirement_ids`/`family`/`source_ref`; `CONFORMANCE.md` is generated from the manifest and byte-for-byte drift-checked in CI.

### Prod guard on test-support
**Source:** `fake_idp.ex:11,97-101` and `xmldsig_signer.ex:40,369-373` (`@prod_build` + `ensure_not_prod!/0`)
**Apply to:** any FakeIdP edits (already present; preserve it).

---

## No Analog Found

None. Every file in scope has a direct in-repo analog; this phase adds no novel role or data flow.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All five files map to existing analogs (the recipes, the signer, the corpus rows, the alias, the generator all pre-exist). |

---

## Metadata

**Analog search scope:** `test/relyra/security/`, `test/security/xml/`, `lib/relyra/test_support/`, `priv/`, `mix.exs`, `lib/mix/tasks/`, `lib/relyra/`, `test/fixtures/security/xml/parser_differential_and_c14n/`
**Files scanned (read):** `xmldsig_signer.ex`, `fake_idp.ex`, `signature_crypto_test.exs`, `corpus_security_test.exs`, `security_corpus.json` (rows 1-90), `mix.exs` (aliases), `relyra.conformance.ex`, `conformance_fixtures.ex`, `PROVENANCE.md` (pitfall catalog)
**Pattern extraction date:** 2026-05-24
