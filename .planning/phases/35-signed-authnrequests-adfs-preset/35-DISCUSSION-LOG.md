# Phase 35: Signed AuthnRequests + ADFS Preset - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-26
**Phase:** 35-signed-authnrequests-adfs-preset
**Mode:** assumptions (calibration: minimal_decisive — `opinionated` vendor philosophy)
**Areas analyzed:** Architecture/signing-seam, Pre-existing DEFLATE bug, AlgorithmPolicy
gap, Private-key seam, ADFS encoding interop, Signed octet composition, Metadata toggle
gating, ADFS preset + runbook, Adversarial corpus + `ci.security` wiring, Error taxonomy.

## Assumptions Presented

### Architecture / Where signing lives

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Signature.sign_redirect_query/3` as single SP-side signing primitive; redirect-URL assembly moves into Relyra core; controller appends pre-built bytes verbatim | Confident | `login_controller.ex:45-50` re-serialization footgun; `binding.ex:9-19` returns map; CLAUDE.md "Key Architecture Seams" §1; investigation thread `:11-14` |

### Pre-existing DEFLATE bug (folded into Phase 35)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add raw-DEFLATE (`-15` window bits, RFC 1951) unconditional in `Binding.encode_redirect/3` before base64 | Confident | `binding.ex:16` does naked `Base.encode64`; SAML 2.0 Bindings §3.4.4.1 mandates DEFLATE; Entra returns AADSTS750054 on uncompressed; bit-for-bit golden corpus requires reproducible deflate-base64-urlenc bytes |

### AlgorithmPolicy gap

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `AlgorithmPolicy.signing_digest_atom/1` as Plan 01 Task 1; mirror `digest_atom_for_signature_method/1` shape | Confident | `grep` returns zero matches; `.planning/v1.3-v1.3-MILESTONE-AUDIT.md:197-202` documents Phase 32 omission; ROADMAP.md explicit Phase 35 dependency |

### Private-key seam

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `:sp_signing_key_pem` Application config key; do NOT reuse `:sp_private_key_pem`; do NOT put in DB; `:key_not_configured` error when missing | Confident | `metadata.ex:24` reads `:sp_signing_cert_pem` (public); `:sp_private_key_pem` is XML-Enc only (`xml_enc.ex:23-106`); investigation thread `:15-16` forbids DB; `key_resolver/default.ex:13-17` error-shape pattern |

### ADFS encoding interop (lowercase-hex, not `+`-vs-`%20`)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Default `:encoding = :rfc3986_upper` (`URI.encode_www_form/1` + uppercase hex); `:adfs_lower` variant post-processes to lowercase; ADFS preset opts in | Confident | python3-saml `utils.py` `escape_url` + `lowercase_urlencoding` flag docs cite ADFS 3.0; Auth0 community bug from re-canonicalization; OneLogin java-saml #225; SAML 2.0 Bindings §3.4.4.1 "use original received octet sequence" |

### Signed octet composition

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `SAMLRequest=<v>&RelayState=<v>&SigAlg=<v>` literal order; RelayState segment OMITTED entirely when absent; `Signature` last in URL, NOT in signed bytes | Confident | OASIS saml-bindings-2.0-os.pdf §3.4.4.1 template; samlify `binding-redirect.ts:105-119`; python3-saml `auth.py:_build_sign_query` |

### Metadata toggle gating (AUTHN-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gate signing `<KeyDescriptor>` + `AuthnRequestsSigned="true"` on `connection.sign_authn_requests`; encryption descriptor stays unconditional (Phase 34 D-04 owned) | Confident | `metadata.ex:32-43` currently unconditional (Phase 34); `connection.ex:40` already threads `sign_authn_requests`; AUTHN-03 acceptance language |

### ADFS provider preset + runbook (AUTHN-04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Relyra.Provider.ADFS` module mirroring Okta/Entra; register in `provider.ex` `@presets` + `connection.ex` `@provider_presets`; runbook at `guides/providers/adfs.md` with PowerShell + claim rules + interop notes | Confident | `provider.ex:76-90` closed registry; `provider/okta.ex` template; investigation thread `:48` recommends v1.3 ship; Microsoft Learn `Set-AdfsRelyingPartyTrust` for PowerShell |

### Adversarial corpus + `ci.security` wiring

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `test/security/authn_request_signing_test.exs` new file; 5 rows (golden, ADFS-lower, re-serialization regression, round-trip verify, toggle-off no-op); golden bytes committed under `test/fixtures/security/authn_request_signing/`; one new `cmd mix test` line in `ci.security`; `@gated_suites` updated | Confident | `mix.exs:152-182` hollow-gate rule; Phase 28 fixture-commit precedent; `FakeIdP.keypair/0` reuse for anti-divergent-signer; SC#2 explicitly names re-serialization mutation test |

### Error taxonomy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No `:invalid_authn_request_signature` (SP generates, doesn't verify); new atoms: `:key_not_configured`, `:unsupported_signing_algorithm`, `:unknown_signing_algorithm` | Confident | `error.ex:15-18` free-atom taxonomy; SP-side ≠ IdP-side responsibilities |

## Corrections Made

No corrections — all assumptions were ratified by the user. Two ratification questions
were presented (D-A2 scope shape + D-A5 encoding default); both selected the
recommended option, with explicit user feedback that these were close enough to the
"don't ask" line that they should have been decided autonomously. Updated
`feedback_recommendation_first.md` memory to tighten the escalation bar going forward.

## Auto-Resolved

Not applicable — no `--auto` flag; no Unclear assumptions in the analyzer output.

## External Research

Spawned a general-purpose research agent (2026-05-26) for the 4 codebase-insufficient
topics flagged by the assumptions-analyzer:

| Topic | Finding (compressed) | Source |
|-------|----------------------|--------|
| OASIS §3.4.4.1 signed-octet order | `SAMLRequest=<v>&RelayState=<v>&SigAlg=<v>` literal; RelayState OMITTED entirely when absent; Signature appended last to URL, NOT in signed bytes | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf §3.4.4.1; samlify `binding-redirect.ts:105-119`; python3-saml `auth.py:_build_sign_query` |
| DEFLATE requirement + Elixir incantation | Spec mandates RFC 1951 raw deflate (no zlib header); Entra returns AADSTS750054 on uncompressed; Erlang `:zlib.deflateInit(z, :default, :deflated, -15, 8, :default)` is the canonical incantation | OASIS bindings §3.4.4.1; Erlang `:zlib` man page; MS Learn AADSTS750054 page; SimpleSAMLphp issue #102 |
| ADFS encoding quirk | The dominant ADFS interop bug is **lowercase percent-encoding** (`%2b` not `%2B`), not `+`-vs-`%20`. ADFS verifies using bytes-as-received; SPs that re-canonicalize to uppercase break (Auth0 / OneLogin java-saml `#225` / OneLogin php-saml `#251` / SAML-Toolkits PR `#144` are all this bug class). Decisive recommendation: default `:rfc3986_upper`; ADFS preset uses `:adfs_lower` (matches python3-saml's `lowercase_urlencoding` flag) | python3-saml `utils.py`; Auth0 community thread; OneLogin java-saml `#225`; SAML-Toolkits python-saml PR `#144` |
| ADFS `Set-AdfsRelyingPartyTrust` PowerShell flags | `-SignedSamlRequestsRequired $true` (PowerShell flag name; NOT `WantAuthnRequestsSigned` — that's the XML attribute); `-RequestSigningCertificate @($cert)` (array, supports rotation); `-SignatureAlgorithm <URI>` (RSA-SHA256 recommended); inbound `SigAlg` is honored independently from outbound `-SignatureAlgorithm` (real interop quirk); canonical claim-rule template for emitting NameID + email/givenname/surname/name attribute set | MS Learn `Set-AdfsRelyingPartyTrust` (Server 2025); MS Learn `Add-AdfsRelyingPartyTrust`; dirteam.com SHA-256 guidance; Rory Braybrook claim-rules patterns |

**Confidence impact:** all four findings folded directly into CONTEXT.md `<decisions>`
and `<specifics>`. The ADFS-lowercase-hex finding upgraded the analyzer's "ADFS-style `+`"
framing into the more accurate lowercase-hex framing — corpus row 2 was renamed
"ADFS-lower variant" accordingly.

## Notes / Meta

- **Calibration tier**: `opinionated` → `minimal_decisive` (3-4 areas, decisive single
  recommendation per item). Honored.
- **Decision posture per CLAUDE.md / project memory `feedback_recommendation_first`**:
  default to one deeply-researched recommendation; escalate only public-API / default-
  tightening / security-posture / SemVer-major decisions. The two AskUserQuestion
  prompts presented were close to the line; user ratified the recommendations and
  reinforced that the bar should be even higher next time. Memory updated.
- **Folded scope**: the pre-existing missing-DEFLATE bug in `binding.ex:16` was
  discovered during codebase analysis. Folded into Phase 35 per user direction
  (2026-05-26 ratification) rather than split into a Phase 35.0 closure-phase, because
  deflate is load-bearing for AUTHN-01's bit-for-bit golden corpus and the test
  infrastructure being built here is what catches it.
</content>
</invoke>