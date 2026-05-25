---
phase: 29
slug: cryptographic-xmldsig-verification
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-24
---

# Phase 29 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
>
> This phase closes a CONFIRMED SAML authentication bypass (the published-hex
> bypass at the `[candidate]` arm of `verified_signed_node`, D-01) and is headed
> for CVE/GHSA disclosure. Every `mitigate` threat below was verified by grepping
> the CITED implementation file for the ACTUAL mitigation pattern at the right
> location — executor SUMMARY claims were NOT accepted as evidence. Starting
> hypothesis was that every threat was OPEN until a code match proved otherwise.

---

## Trust Boundaries

Merged from the five PLAN `<threat_model>` blocks (Plans 01–05).

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| signed XML → canonical bytes | The bytes the verifier hashes/verifies MUST equal the bytes the signer signed; any C14N differential is a tampering surface | document XML → canonical UTF-8 (high sensitivity) |
| out-of-band golden → CI | Golden bytes are human/Docker-minted; CI trusts the committed bytes (never runs the native toolchain) | libxml2-minted canonical bytes → committed fixtures |
| document → candidate map | base64 DigestValue/SignatureValue are attacker-controlled strings; they are DATA only here (decoded + verified later), never executed | attacker-controlled base64 (untrusted) |
| signature-method URI → digest atom | Algorithm selection is a trust decision; an unhandled/ECDSA URI must reject, not silently pick a default | document SignatureMethod URI (untrusted) |
| document SignatureValue/DigestValue → crypto | Attacker-controlled; decoded then verified against the CONFIGURED key — never trusted as-is | base64 sig/digest material (untrusted) |
| configured cert_chain → public key | The ONLY trust source for the verify key (never document KeyInfo) | operator-configured PEM (trusted anchor) |
| referenced element → canonical bytes → digest | The bytes hashed must be the EXACT bound `:node` (anti-XSW, Phase 28 D-10) | bound tree node → canonical bytes (integrity-critical) |
| signer ↔ verifier C14N | The signer MUST canonicalize with the verifier's engine; a divergent signer would make the positive control pass for the wrong reason | test SignedInfo/Assertion bytes (test-only) |
| test keypair → prod | Signing code is test-only; it must never compile/run in `:prod` | RSA-2048 test keypair (must not reach prod) |
| stale test fixtures → trust contract | Structure-only "signed" fixtures that asserted `{:ok}` must be triaged; leaving them silently green-via-relaxation would mask a broken crypto path | structure-only fixtures (coverage integrity) |
| fetched metadata → candidate | Untrusted; XXE/DOCTYPE/size guards run before Saxy; signature math + pinning gate trust | fetched metadata XML (untrusted) |
| operator-pinned fingerprints → metadata signing cert | Pinning is the defense-in-depth gate; signature math is the primary gate (D-13) | pinned SHA-256 fingerprints (trusted) |
| metadata root node → canonical bytes | Crypto consumes the EXACT bound EntityDescriptor/EntitiesDescriptor node (anti-XSW) | bound metadata-root node → canonical bytes (integrity-critical) |

---

## Threat Register

24 threats verified (23 `mitigate` + 1 `accept`). All CLOSED. `T-29-19` is reused
by two distinct threats: Plan 04 (stale fixtures) keeps `T-29-19`; the Plan 05
metadata-root forgery threat is disambiguated as `T-29-19M`. `T-29-SC` is the one
shared accepted supply-chain risk declared identically across all five plans
(deduped to a single row, recorded in the Accepted Risks Log).

| Threat ID | Category | Component | Disposition | Mitigation (verified evidence) | Status |
|-----------|----------|-----------|-------------|--------------------------------|--------|
| T-29-01 | Tampering | C14N render_element/3 document-order bug | mitigate | `render_element/3` walks ordered `node.content` in document order; the buggy `escape_text(node.text), child_iodata` adjacency is GONE — `c14n.ex:277-281` (`{:text, t} -> escape_text(t); {:element, child} -> render_element(...)`); `content` built in document order in `saxy_tree.ex:182-188` | closed |
| T-29-02 | Tampering | C14N differential (signer ≠ verifier) on pretty-printed XML | mitigate | New mixed-content golden byte-equality test under `@tag :gate02_c14n` — `corpus_security_test.exs:93,103-104` reads `mixed_content.input.xml`/`mixed_content.c14n`; both fixtures present (1588/1056 bytes); 887-byte golden retained | closed |
| T-29-03 | Spoofing | Malformed/incomplete node reaching serializer | mitigate | `bindable?/1` fail-closed incl. `is_list(content)` — `c14n.ex:237-250`; `prune_subtree/1` prunes on ORDERED `content` (anti-XSW, not children-only) — `c14n.ex:202-214` | closed |
| T-29-04 | Spoofing | Algorithm-confusion / ECDSA fail-open (RFC 6931 r‖s vs DER) | mitigate | `digest_atom_for_signature_method/1` checks `String.contains?(uri, "ecdsa")` → `{:error, :unsupported_signature_algorithm}` BEFORE the `rsa-sha*` suffix match — `algorithm_policy.ex:88-99` | closed |
| T-29-05 | Tampering | Wrong digest algorithm selected for recompute | mitigate | Single-source URI→atom mapping (`algorithm_policy.ex:87-99`) drives the same `digest_atom` into `:crypto.hash(digest_atom, ref_bytes)` — `signature.ex:349` | closed |
| T-29-06 | Information Disclosure | Logging raw base64 signature/digest material | mitigate | Carried as data keys `:digest_value_b64`/`:signature_value_b64` (`signature.ex:207-208`); `Error.redact_details/1` truncates >100-byte binaries — `error.ex:39-56` (Inspect impl redacts at `error.ex:24`) | closed |
| T-29-07 | Spoofing | Forged SignatureValue (valid structure) | mitigate | `safe_verify` wraps `:public_key.verify`; `false` → `:invalid_signature` — `signature.ex:317-326,396-400`. Negative test `signature_crypto_test.exs:81-90` | closed |
| T-29-08 | Tampering | Content tampering w/ reused signature (altered NameID) | mitigate | DigestValue recompute over canonicalized `:node` + length-guarded constant-time compare → `:digest_mismatch` — `signature.ex:346-361`. Tampered-NameID test `signature_crypto_test.exs:226-235` | closed |
| T-29-09 | Spoofing/Elevation | Wrong-key / attacker KeyInfo | mitigate | Public key extracted ONLY from configured `cert_chain` (`public_key_from_cert_chain/1`, `signature.ex:287-300`); `cert_chain` threaded `do_verify → verify_algorithms_and_candidates → verified_signed_node` (`signature.ex:135,151,178`); `key_info_trust == true` rejected before crypto — `signature.ex:115-121` | closed |
| T-29-10 | Tampering | Signature Wrapping (XSW) | mitigate | Crypto consumes the EXACT bound `:node` via `PureBeam.canonicalize(candidate)` — `signature.ex:347`; enveloped-signature prune of the SPECIFIC `ds:Signature` (`prune_subtree` value-equal match) — `c14n.ex:185-214`; fail-closed when the bound signature node is unresolved — `pure_beam.ex:478-484` | closed |
| T-29-11 | Spoofing | Algorithm downgrade / ECDSA fail-open | mitigate | Digest-atom gate (`digest_atom/2`) runs as step 1 of `cryptographically_verify`, BEFORE key extraction and `:public_key.verify` — `signature.ex:216-217,249-262` | closed |
| T-29-12 | Information Disclosure | Timing side-channel on digest compare | mitigate | `:crypto.hash_equals/2` constant-time compare, guarded by `byte_size(recomputed) == byte_size(declared)` immediately before — `signature.ex:351-352` | closed |
| T-29-13 | DoS / fail-open | Malformed PEM/key/digest crashes the auth path | mitigate | `public_key_from_cert_chain/1` `rescue _ -> {:error, :untrusted_certificate}` (`signature.ex:296-298`); `safe_verify` `rescue _ -> false` (`signature.ex:398-399`); hash_equals length guard (`signature.ex:351`); every step fails CLOSED to a typed `%Relyra.Error{}` | closed |
| T-29-14 | Spoofing | "Always-reject" verifier passes negatives but breaks real logins | mitigate | D-11 positive control: genuine signer → `{:ok, %SignedNode{}}` — `signature_crypto_test.exs:203-211` (and Wave-2 smoke `:178-189`); signer `xmldsig_signer.ex:94-130` | closed |
| T-29-15 | Tampering | Divergent second signer canonicalizes differently → false positive | mitigate | Signer reuses verifier's engine: `C14N.serialize` + `PureBeam.canonicalize` (`xmldsig_signer.ex:269,276`) and `FakeIdP.keypair()` (`xmldsig_signer.ex:208,279`); NO second `:public_key.generate_key` in the module | closed |
| T-29-16 | Spoofing | Wrong-key acceptance | mitigate | Wrong-key negative verifies genuine Response against a DIFFERENT cert → `:invalid_signature` — `signature_crypto_test.exs:215-223` | closed |
| T-29-17 | Tampering | Post-signing content tamper (NameID swap) | mitigate | Tampered-NameID negative (`tamper_name_id` knob, `xmldsig_signer.ex:319-328`) → `:digest_mismatch` — `signature_crypto_test.exs:226-235` | closed |
| T-29-18 | Elevation | Signing code reachable in prod | mitigate | `@prod_build = Mix.env() == :prod` + `ensure_not_prod!/0` raises in prod; called from every public entry — `xmldsig_signer.ex:40,96,163,206,369-373` (mirrors `fake_idp.ex:11,107-111`) | closed |
| T-29-19 | Tampering | Stale structure-only fixtures masked by suite relaxation hide a broken/bypassed crypto path | mitigate | `{:ok}`-asserting structure-only login tests re-pointed at the genuine signer (`XmldsigSigner.sign_response` + `self_signed_cert_pem`) — `consume_response_pipeline_test.exs:340,412,441`; `sp_conformance_test.exs:175,206`. No `--warnings-as-errors` relaxation, no `@tag :skip`, no deleted coverage (grep-confirmed) | closed |
| T-29-19M | Spoofing | Metadata-root signature forgery | mitigate | `verify_metadata_root → do_verify` uses the SAME `:public_key.verify` + digest-recompute primitive; positive control → `{:ok, %SignedNode{}}` — `auto_refresh_test.exs:234-235`; delegation `signature.ex:78` | closed |
| T-29-20 | Spoofing | Metadata pinning bypass (sig-valid, wrong key) | mitigate | Pinning runs BEFORE the signature math: `TrustAnchor.matching_pems` (CR-01-hardened superset of `TrustAnchor.check`) at `auto_refresh.ex:157-158`, then `pre_parse_for_signature` (`:159`), then `verify_against_pinned → verify_metadata_root` (`:160,169-170`). Wrong-fingerprint negative rejects at pinning → `:trust_anchor_mismatch` — `auto_refresh_test.exs:282-311`. `TrustAnchor.check/2` still present (`trust_anchor.ex:95-102`) | closed |
| T-29-21 | Tampering | Parser differential between regex pre-parse and tree verifier | mitigate | Metadata root routes through `SaxyTree.parse` via `PureBeam.parse_metadata_root_safely/2` — `auto_refresh.ex:222-224`, `pure_beam.ex:85-110,131-142`. All 5 regex candidate helpers retired (grep-confirmed absent from `auto_refresh.ex`) | closed |
| T-29-22 | Tampering | Document KeyInfo trust on the metadata path | mitigate | `key_info_trust` scoped to the bound `ds:Signature`'s OWN KeyInfo: `element_present?(signature_node, "KeyInfo")` — `pure_beam.ex:183`; shared `do_verify` rejection inherits — `signature.ex:115-121` | closed |
| T-29-23 | DoS / XXE | DOCTYPE/entity/size attack on metadata XML | mitigate | XXE-before-verify byte guards (`<!DOCTYPE`, `<!ENTITY`, `max_bytes`) run before Saxy inside `parse_metadata_root_safely/2` — `pure_beam.ex:92-107`. Tested: `pure_beam_metadata_root_test.exs:129-146` (`:doctype_forbidden`, `:entity_expansion_forbidden`, `:payload_too_large`) | closed |
| T-29-SC | Tampering | npm/pip/cargo supply-chain installs | accept | No package installs in this phase — pure in-repo Elixir + OTP-bundled `:public_key`/`:crypto`; goldens minted out-of-band per Phase 28 D-12. See Accepted Risks Log | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-29-SC | T-29-SC | No package installs occur in Phase 29. The phase is pure in-repo Elixir relying only on OTP-bundled `:public_key`/`:crypto` (no third-party crypto dependency), and all C14N golden fixtures are minted out-of-band with the Docker libxml2 oracle per the Phase 28 D-12 discipline (CI never invokes the native toolchain; it reads committed bytes only). There is therefore no npm/pip/cargo supply-chain surface introduced by this phase. | gsd-security-auditor | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 24 | 24 | 0 | gsd-security-auditor |

Notes:
- All 5 SUMMARY files were checked for a `## Threat Flags` section; none is present, so there are no unregistered flags (no net-new attack surface declared during implementation).
- The register was authored at plan time (all 5 PLAN files carry parseable `<threat_model>` blocks), so verification was disposition-driven, not a blind net-new vulnerability scan.
- Key Phase 29 security test files were executed during the audit: `signature_crypto_test.exs`, `corpus_security_test.exs`, `auto_refresh_test.exs`, `pure_beam_metadata_root_test.exs` — 53 tests, 0 failures.
- Implementation files were treated as READ-ONLY; only this SECURITY.md was created.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
