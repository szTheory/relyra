# Phase 57: Demo FakeIdP Browser-Login Proof - Research

**Researched:** 2026-06-13
**Domain:** Demo-local SAML IdP that produces a genuinely-signed `<Response>` relyra's strict SP verifier accepts byte-for-byte; Phoenix browser round-trip; in-process tests.
**Confidence:** HIGH (all claims verified by reading relyra source + demo source this session)

## Summary

Relyra's verifier (`do_verify/4`) accepts a `<Response>` only when: (1) a single `[candidate]` signed node exists; (2) its `SignatureMethod`/`DigestMethod` are on the allowlist (RSA-SHA256/384/512 + SHA256/384/512 digests — **no SHA-1**); (3) the canonical-`SignedInfo` bytes verify under `:public_key.verify` against the **configured** IdP cert (never document KeyInfo); and (4) the recomputed exclusive-C14N digest of the referenced `<Assertion>` equals the declared `DigestValue`. The single non-negotiable byte-compatibility requirement is that the demo signer canonicalize the referenced `<Assertion>` and the `<SignedInfo>` with the **exact same exclusive-C14N 1.0 engine** relyra uses (`Relyra.Security.XML.C14N` over the `SaxyTree` parse tree). Any divergent C14N silently fails the digest/signature check.

The lowest-risk path is **option (b) — vendor a demo-local copy of relyra's `XmldsigSigner` technique into `demo/ledger_loop`, but the vendored signer calls relyra's PUBLIC, prod-compiled `Relyra.Security.XML.{SaxyTree, PureBeam, C14N}` modules to canonicalize** (these are NOT under `test_support`, so they compile in `:prod` and are callable from the path-dep demo). The "anti-divergent-signer" guarantee then holds for free: the demo signer never canonicalizes differently from the verifier because it uses the verifier's own C14N. Hand-rolling a fresh C14N (option a) re-opens the exact byte-divergence class relyra spent Phases 28-29 closing — do not.

Beyond the signature, the **full validation pipeline** must pass: status=Success, Destination=connection `acs_url`, Audience=connection `sp_entity_id`, Recipient=connection `acs_url`, Issuer=connection `idp_entity_id`, time-conditions within skew, replay-key fresh, and request-correlation. Because the Ecto connection snapshot emits `allow_idp_initiated?` (trailing `?`) while the pipeline reads `:allow_idp_initiated` (no `?`), **IdP-initiated is effectively blocked for any Ecto-backed connection** — the demo MUST run **SP-initiated**: the login button hits relyra's `/saml/:connection_id/login`, which mints an `AuthnRequest`, stores a request-intent keyed by RelayState, and redirects to the connection's `idp_sso_url`. Point `idp_sso_url` at `/fake_idp/login`; the FakeIdP echoes the RelayState (and the `InResponseTo` request id) back through the self-submitting POST to relyra's ACS.

**Primary recommendation:** Vendor a `LedgerLoop.FakeIdP.Signer` that mirrors `XmldsigSigner.signed_response/1` but (a) uses a demo keypair loaded from a committed PEM under `demo/ledger_loop/priv/`, and (b) canonicalizes via relyra's public `PureBeam.canonicalize/1` + `C14N.serialize/1`. Run the flow **SP-initiated** through relyra's existing `/saml/:connection_id/login` + `/saml/:connection_id/acs`. Replace the fixture `MOCK_PEM_NOT_REAL` signing cert with the demo keypair's self-signed cert PEM. Attach `Relyra.Telemetry.Handlers.LoginTrace` in the demo `Application` so the tampered variant lands in the trace UI.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SAML `<Response>` signing | Demo IdP (`demo/ledger_loop`) | relyra public C14N modules | Demo owns the IdP role; must NOT use relyra TestSupport at runtime, but MAY call relyra's prod-compiled C14N |
| Keypair / self-signed cert | Demo `priv/` (committed) | — | Demo secret; one keypair signs + its cert is the connection's trusted IdP cert |
| AuthnRequest mint + intent store | relyra `/saml/:connection_id/login` (LoginController) | demo RequestStore (Ecto) | SP-initiated correlation is relyra's job; demo only supplies the behaviour adapter |
| Signature/digest verification | relyra `do_verify/4` | — | The gate. Demo earns a real pass; never weakened |
| Full protocol validation | relyra `ValidationPipeline` | connection fixture fields | Destination/Audience/Recipient/Issuer/time/replay all derived from connection |
| Session establishment | demo `SessionAdapter` | — | Existing LoginReceipt path |
| Typed-rejection surfacing | relyra trace UI (`ConnectionTraceLive`) | demo LoginTrace handler attach | Trace rows are `domain: :login` AuditEvents written by the telemetry handler |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` (OTP) | OTP 26+ | RSA-2048 keygen, `:public_key.sign/3`, self-signed cert via `pkix_test_root_cert/2` | Exactly what relyra's own signer + `MintSigningKey` use [VERIFIED: lib/relyra/test_support/xmldsig_signer.ex:209, test/support/mint_signing_key.exs:6] |
| `Relyra.Security.XML.SaxyTree` | relyra 1.7.0 (path dep) | Parse emitted XML to the `Node` tree the C14N engine binds | Public (not test_support); compiles in :prod [VERIFIED: lib/relyra/security/xml/, app manifest lists it] |
| `Relyra.Security.XML.PureBeam` | relyra 1.7.0 | `canonicalize/1` of the referenced `<Assertion>` → digest bytes | The SAME path the verifier's `verify_reference_digest` uses [VERIFIED: lib/relyra/security/signature.ex:457] |
| `Relyra.Security.XML.C14N` | relyra 1.7.0 | `serialize/1` of `<SignedInfo>` → signed bytes | The SAME path the verifier's `verify_signature_math` uses [VERIFIED: lib/relyra/security/signature.ex:425] |
| `Phoenix.ConnTest` / `Phoenix.LiveViewTest` | demo deps | In-process success + failure assertions | LOCKED by CONTEXT (no Wallaby) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Base` | stdlib | base64 encode the Response; decode-mutate-reencode for tamper | Both variants |
| `:crypto` | OTP | `:crypto.hash(:sha256, ref_bytes)` for the digest | Signer digest step |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Vendored signer calling relyra C14N (rec.) | Hand-rolled exclusive-C14N in demo (option a) | Hand-roll re-opens the byte-divergence auth-bypass class; relyra's own `XmldsigSigner` moduledoc (D-12) calls a divergent second signer the thing that "would make the positive control pass for the wrong reason". REJECT. |
| SP-initiated flow (rec.) | IdP-initiated (`allow_idp_initiated`) | IdP-initiated needs `allow_idp_initiated` true, but the Ecto snapshot key is `allow_idp_initiated?` and the pipeline reads `allow_idp_initiated` (no `?`) → always nil → `:idp_initiated_not_allowed`. SP-initiated avoids this AND is more realistic. |
| `pkix_test_root_cert/2` self-signed cert (rec.) | Hand-built X.509 | relyra's own signer uses `pkix_test_root_cert(~c"CN=...", key: priv)` and only the cert's SubjectPublicKeyInfo matters to the verifier. Mirror it. |

**Installation:** No new packages. All capabilities are OTP stdlib + relyra's already-present public modules.

**Version verification:** relyra is a path dependency at v1.7.0 (app manifest `{vsn,"1.7.0"}`). No registry install; the modules above are confirmed present in `_build/*/lib/relyra/ebin/relyra.app`. [VERIFIED: demo/ledger_loop/_build/*/lib/relyra/ebin/relyra.app]

## Package Legitimacy Audit

No external packages are installed by this phase. All code uses OTP stdlib (`:public_key`, `:crypto`, `Base`) and relyra's already-vendored public modules. **Package Legitimacy Gate: N/A (zero new dependencies).**

## Architecture Patterns

### System Architecture Diagram

```
Evaluator browser
   │  click "Log in with SSO"  (RouteAffordanceController.login → render link)
   ▼
GET /saml/:connection_id/login           (relyra LoginController)
   │  start_login → AuthnRequest.build → put_intent(RelayState→{request_id,...})
   │  redirect(external: idp_sso_url + "?SAMLRequest=…&RelayState=…")
   ▼
GET /fake_idp/login   (idp_sso_url points here)   [DEMO]
   │  decode RelayState (+ optionally the AuthnRequest id for InResponseTo)
   │  render form: "Local Test Support / FakeIdP", radio: success | tampered
   ▼
POST /fake_idp/sso     [DEMO FakeIdPController.sso]
   │  build assertion fields from connection fixture (Destination/Audience/…)
   │  LedgerLoop.FakeIdP.Signer.signed_response(...)   ← vendored signer
   │     ├─ build placeholder XML
   │     ├─ SaxyTree.parse → PureBeam.canonicalize(Assertion) → DigestValue (relyra C14N)
   │     ├─ re-embed digest → SaxyTree.parse → C14N.serialize(SignedInfo)
   │     └─ :public_key.sign(signed_info_bytes, :sha256, demo_priv_key)  → SignatureValue
   │  success → Base.encode64(signed_xml)
   │  tampered → decode, mutate a byte (<Issuer→<IssuerTampered), re-encode
   │  render self-submitting POST form → ACS
   ▼
POST /saml/:connection_id/acs            (relyra ACSController)
   │  decode_post → consume_response(xml, relay_state: …)
   │    resolve_request_intent(RelayState) → request_intent (InResponseTo correlation)
   │    resolve_connection (Ecto snapshot, cert_chain = [demo cert PEM])
   │    ValidationPipeline.run → do_verify/4  (THE GATE)
   │       success → UserMapper → SessionAdapter.establish_session → redirect "/"
   │       tampered → {:error, %Error{type: :digest_mismatch | :invalid_signature}}
   ▼ (telemetry [:relyra,:saml,:response,:consume,:stop|:exception])
LoginTrace handler → AuditWriter.append_event(domain: :login, outcome/error_code)
   ▼
/relyra/admin/connections/:id/trace      (relyra ConnectionTraceLive)
   shows the typed rejection step (outcome="error", error_code=…)
```

### Recommended demo structure
```
demo/ledger_loop/
├── priv/
│   └── fake_idp/
│       ├── idp_key.pem          # demo RSA-2048 private key (committed; demo secret)
│       └── idp_cert.pem         # self-signed cert (committed) — matches fixture
├── lib/ledger_loop/fake_idp/
│   ├── keypair.ex               # loads PEMs from priv/ (cached in :persistent_term)
│   └── signer.ex                # signed_response/1 + tamper/1 (vendored technique)
└── lib/ledger_loop_web/controllers/
    ├── fake_idp_controller.ex   # login/2 + sso/2 (recover WIP; swap signer call)
    ├── fake_idp_html.ex
    └── fake_idp_html/{login,sso}.html.heex
```

### Pattern 1: Vendored signer that reuses relyra's C14N (the anti-divergence trick)
**What:** Mirror `XmldsigSigner.signed_response/1` 4-step shape, but compute digest/signature via relyra's PUBLIC C14N modules.
**When to use:** Always, for byte-compatibility with `do_verify/4`.
**Example (the load-bearing two calls — copy this exact engine usage):**
```elixir
# Source: lib/relyra/test_support/xmldsig_signer.ex:284-297 (technique, re-homed in demo)
defp digest_for(assertion_node) do
  {:ok, %{canonical_xml: ref_bytes}} =
    Relyra.Security.XML.PureBeam.canonicalize(%{node: assertion_node})
  :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
end

defp sign_signed_info(signed_info_node, priv_key) do
  {:ok, c14n} = Relyra.Security.XML.C14N.serialize(signed_info_node)
  c14n |> then(&:public_key.sign(&1, :sha256, priv_key)) |> Base.encode64()
end
```

### Pattern 2: Exact emitted XML shape
**What:** Use the SAME element layout as `XmldsigSigner.response_xml/3` (Issuer/Status/Assertion/Subject/SubjectConfirmationData/Conditions/AudienceRestriction, then sibling `<Signature>` with `CanonicalizationMethod` = exc-c14n, `SignatureMethod` = rsa-sha256, `DigestMethod` = sha256, `Reference URI="#<assertion_id>"`).
**Why it matters:** The digest is computed over the parsed `<Assertion>` node; the `Reference URI` must match the `<Assertion ID>`. The `<Signature>` is a **sibling** of `<Assertion>` (relyra's `signed_candidates` pairs by Assertion ID + the bound `ds:Signature`), NOT enveloped — so **no enveloped-signature transform is needed**; the digest is plain exc-C14N over the referenced `<Assertion>`. [VERIFIED: xmldsig_signer.ex:252-280, signature.ex verify_reference_digest]

### Anti-Patterns to Avoid
- **Hand-rolling C14N:** byte-divergence silently breaks the digest. Use relyra's engine.
- **Enveloping the signature inside `<Assertion>`:** relyra's signer keeps `<Signature>` a sibling; do the same to avoid needing the enveloped-signature transform.
- **IdP-initiated:** blocked by the `allow_idp_initiated?` vs `allow_idp_initiated` key mismatch. Use SP-initiated.
- **Emitting `InResponseTo` with no correlated request, or omitting it under SP-initiated:** SP-initiated requires `parsed_doc.in_response_to == request_intent.request_id`; mismatch → `:in_response_to_mismatch`. The FakeIdP must echo the request id. [VERIFIED: validation_pipeline.ex:262-305]
- **Calling `Relyra.TestSupport.*` at runtime:** undefined in `:prod` path-dep build. This is the WIP's exact failure.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exclusive C14N 1.0 | A second canonicalizer | `Relyra.Security.XML.C14N.serialize/1` + `PureBeam.canonicalize/1` | Public, prod-compiled, byte-proven vs libxml2; a divergent copy is the auth-bypass class |
| XML→tree parse | Regex/xmerl | `Relyra.Security.XML.SaxyTree.parse/1` | The single parse seam; matches what verifier binds |
| RSA self-signed cert | Manual ASN.1 | `:public_key.pkix_test_root_cert/2` | Only SubjectPublicKeyInfo matters; mirrors relyra signer |
| Login trace persistence | Custom audit insert | `Relyra.Telemetry.Handlers.LoginTrace.attach(repo:)` | Writes `domain: :login` AuditEvents the trace UI reads |

**Key insight:** The entire byte-compatibility risk collapses to "use relyra's own C14N engine." A demo-local *copy of the signing technique* is fine; a demo-local *copy of the C14N algorithm* is forbidden.

## Runtime State Inventory

This phase adds a keypair + rewires fixtures; treat fixture/cert state explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `LedgerLoop.Demo.Fixtures.relyra_certificates/0` `@enabled_cert_id` row stores `pem: "MOCK_PEM_NOT_REAL"` (scenario `…J0`, `connection_record_id: @enabled_conn_id`). | **Data + code edit:** replace `MOCK_PEM_NOT_REAL` with the real self-signed cert PEM; demo reset (`reset.ex`) re-seeds from fixtures so updating the fixture is sufficient — verify `Demo.Reset` reinserts certs. The `fingerprint_sha256` field should be recomputed from the new cert (or left; verifier does not check it on the assertion path, but the admin UI displays it). |
| Live service config | None — the only IdP config is the in-repo fixture + `idp_sso_url`. The enabled connection's `idp_sso_url` is `https://idp.northstar.example.com/sso`; for the local demo it must point at `/fake_idp/login` (full URL via endpoint host) so `start_login`'s redirect lands on the FakeIdP. **Action:** change `idp_sso_url` in `relyra_connections/0` for `…J0` to the local FakeIdP URL. |
| OS-registered state | None. |
| Secrets/env vars | New demo secret: `priv/fake_idp/idp_key.pem`. Demo-only, committed per CONTEXT. No SOPS/env. |
| Build artifacts | None — no package rename. New `priv/` files are read at runtime via `Application.app_dir(:ledger_loop, "priv/...")`. |

**Canonical question answered:** After the fixture cert PEM and `idp_sso_url` are updated and the keypair PEMs are committed, the only runtime state is the seeded cert row (re-seeded by `Demo.Reset` from the fixture) — no external/OS/secret state carries a stale value.

## Common Pitfalls

### Pitfall 1: C14N divergence breaks digest/signature silently
**What goes wrong:** Demo uses any canonicalization other than relyra's → `:digest_mismatch` or `:invalid_signature`.
**Why:** The verifier recomputes the digest with `PureBeam.canonicalize` and verifies `SignedInfo` with `C14N.serialize`.
**How to avoid:** Call those exact functions in the signer (Pattern 1).
**Warning signs:** Success variant returns `:digest_mismatch` despite a "valid" signature.

### Pitfall 2: SP-initiated correlation (`InResponseTo`)
**What goes wrong:** `:in_response_to_mismatch`.
**Why:** Under SP-initiated, `consume_response` resolves a request-intent by RelayState and requires `parsed_doc.in_response_to == intent.request_id`. The FakeIdP must read the inbound `SAMLRequest`'s `ID` (or the RelayState payload's `request_id`) and emit it as the Response `InResponseTo`.
**How to avoid:** In `/fake_idp/login`, capture the request id; thread it through `/fake_idp/sso` (hidden field) into the signer's `:in_response_to`. Simplest robust path: decode the relyra `RelayState` token server-side, OR carry the AuthnRequest `ID` in a hidden field.
**Warning signs:** signature passes but pipeline rejects with `:in_response_to_mismatch`.

### Pitfall 3: Field equality is exact-string
**What goes wrong:** `:issuer_mismatch`, `:destination` / `:audience` / `:recipient` errors.
**Why:** Pipeline compares against connection fields verbatim: Destination=`acs_url`, Recipient=`acs_url`, Audience=`sp_entity_id`, Issuer=`idp_entity_id`.
**How to avoid:** Drive the signer's fields FROM the connection fixture (read `relyra_connections/0` `…J0`): Issuer=`idp_entity_id`, Destination=Recipient=`acs_url`, Audience=`sp_entity_id`. Do NOT hardcode `https://fake.idp/metadata` / `http://localhost:4000/...` like the WIP did. [VERIFIED: validation_pipeline.ex:307-377]
**Warning signs:** the WIP's hardcoded `audience`/`issuer` would fail issuer/audience match against the seeded connection.

### Pitfall 4: NameID must map to a seeded user
**What goes wrong:** `:user_not_found` AFTER successful verification.
**Why:** `UserMapper.map_attributes` looks up `SAMLIdentity` by `subject == name_id AND issuer == connection.idp_entity_id`. Seeded subjects are `sarah@northstar.example.com` / `chen@northstar.example.com` with issuer `https://idp.northstar.example.com`.
**How to avoid:** Set the assertion NameID to a seeded subject AND keep Issuer = the connection's `idp_entity_id` (these two must agree with `saml_identities/0`). If `idp_sso_url`/`idp_entity_id` are changed, update `saml_identities/0` issuer to match. [VERIFIED: user_mapper.ex:13-30, fixtures.ex:266-285]
**Warning signs:** verification passes, login fails at user-map step.

### Pitfall 5: Trace UI is empty unless LoginTrace handler is attached
**What goes wrong:** Tampered variant rejects, but `/relyra/admin/connections/:id/trace` shows nothing.
**Why:** Trace rows are `domain: :login` AuditEvents written ONLY by `Relyra.Telemetry.Handlers.LoginTrace`, which the demo `Application` does **not** currently attach. [VERIFIED: demo/ledger_loop/lib/ledger_loop/application.ex — no attach; query.ex:114-131 reads AuditEvent domain: :login]
**How to avoid:** Add `Relyra.Telemetry.Handlers.LoginTrace.attach(repo: LedgerLoop.Repo)` after the Repo starts in `LedgerLoop.Application.start/2` (or in a small post-start step). The handler listens on `[:relyra, :saml, :response, :consume, {:start,:stop,:exception}]` and child stops.
**Warning signs:** rejection works but trace page empty; existing seeded demo trace rows (from `reset.ex`) belong to the *support* connection, not the enabled one.

### Pitfall 6: Replay on re-run
**What goes wrong:** Second success login → replay rejection.
**Why:** `consume_replay_key` consumes a deterministic key (connection_id + issuer + signed_xml_id). Re-submitting the SAME signed response (same assertion ID) trips replay.
**How to avoid:** For repeatable demos, vary the assertion ID per signing (e.g. a ULID/`unique_integer`). In tests, fresh sign per assertion or reset the replay store between cases. [VERIFIED: lib/relyra.ex:589-650]

## Code Examples

### Keypair load from committed PEM (mirrors MintSigningKey for generation, persistent_term for cache)
```elixir
# Source: derived from test/support/mint_signing_key.exs + fake_idp.ex keypair caching
defmodule LedgerLoop.FakeIdP.Keypair do
  @key_path "fake_idp/idp_key.pem"
  @cert_path "fake_idp/idp_cert.pem"

  def private_key do
    [entry] = pem("priv") |> :public_key.pem_decode()
    :public_key.pem_entry_decode(entry)   # → {:RSAPrivateKey, ...}
  end

  def cert_pem, do: pem("cert")  # the literal PEM string threaded into Fixtures

  defp pem("priv"), do: read(@key_path)
  defp pem("cert"), do: read(@cert_path)
  defp read(rel), do: :ledger_loop |> Application.app_dir("priv/" <> rel) |> File.read!()
end
```

### One-time keypair + cert generation (a mix task or seed; cert via pkix_test_root_cert)
```elixir
# Source: lib/relyra/test_support/xmldsig_signer.ex:205-211 (cert) + mint_signing_key.exs (key)
priv = :public_key.generate_key({:rsa, 2048, 65_537})
key_pem = :public_key.pem_encode([:public_key.pem_entry_encode(:RSAPrivateKey, priv)])
%{cert: der} = :public_key.pkix_test_root_cert(~c"CN=ledgerloop-fake-idp", key: priv)
cert_pem = :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
# write key_pem → priv/fake_idp/idp_key.pem ; cert_pem → priv/fake_idp/idp_cert.pem
# paste cert_pem string into Fixtures.relyra_certificates/0 @enabled_cert_id :pem
```

### Tamper (from WIP — confirmed to trip the verifier)
```elixir
# Source: wip/demo-fake-idp fake_idp_controller.ex — confirmed technique
valid_xml = Base.decode64!(valid_b64, padding: false)
broken    = String.replace(valid_xml, "<Issuer", "<IssuerTampered")
Base.encode64(broken, padding: false)
```
**Typed error produced:** mutating `<Issuer` inside the **signed `<Assertion>`** changes the referenced element's canonical bytes → recomputed digest ≠ `DigestValue` → **`:digest_mismatch`** (after a passing signature-math check, since `SignedInfo` is untouched). Mutating bytes OUTSIDE the referenced assertion but inside `SignedInfo` would instead yield `:invalid_signature`. The first `<Issuer` in the document is the Response-level Issuer (a sibling of Assertion) — relyra also validates `issuer_mismatch` BEFORE signature in the pipeline, so a Response-Issuer mutation surfaces as `:issuer_mismatch`. **Recommendation:** to demonstrate a *crypto* rejection specifically, tamper the **Assertion's** `<NameID>` or the inner `<Issuer>` (the Assertion's own child) to get `:digest_mismatch` from `do_verify/4`; this is the canonical "tampered signature" proof. Plan should pick the target deliberately and assert the exact `error_code`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WIP calls `Relyra.TestSupport.FakeIdP.sign/1` | Demo-local signer using relyra public C14N | This phase | Removes the prod-undefined-symbol crash |
| WIP hardcodes issuer/audience/destination | Drive all fields from the connection fixture | This phase | Avoids issuer/audience/recipient/destination mismatches |
| WIP implies IdP-initiated POST to `/saml/acs` | SP-initiated via `/saml/:connection_id/login` → FakeIdP → `/saml/:connection_id/acs` | This phase | Avoids the `allow_idp_initiated?` key-mismatch block; produces correlated `InResponseTo` |

**Deprecated/outdated in the WIP:** the `acs_url: "/saml/acs"` form action — relyra's ACS route is `/saml/:connection_id/acs` (the `saml_routes()` macro mounts `:connection_id`-scoped paths). The self-submitting form must POST to `/saml/<…J0>/acs`. [VERIFIED: lib/relyra/phoenix/router.ex:32]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Demo.Reset` re-seeds certs from `Fixtures.relyra_certificates/0`, so updating the fixture PEM propagates to the DB on reset | Runtime State Inventory | If reset has a separate cert source, the live row keeps `MOCK_PEM_NOT_REAL` and verification fails — plan must read `reset.ex` cert seeding and confirm. |
| A2 | Changing `idp_sso_url`/`idp_entity_id` for `…J0` to local values keeps `saml_identities/0` issuer in sync | Pitfalls 3-4 | If issuer drifts from the seeded `SAMLIdentity.issuer`, success login fails at user-map — must update both together. |
| A3 | `PureBeam.canonicalize/1` accepts the `%{node: assertion_node}` map shape at the public boundary (as the relyra signer calls it) | Pattern 1 | If the public arity differs, signer adapts to whatever `PureBeam.canonicalize/1` expects — the relyra signer at xmldsig_signer.ex:285 is the authoritative call site to copy verbatim. |
| A4 | Tampering the Assertion's inner `<Issuer>`/`<NameID>` yields `:digest_mismatch` (vs Response-level `<Issuer>` → `:issuer_mismatch`) | Code Examples | If plan tampers the wrong Issuer, the asserted `error_code` won't match — plan must pin the exact target + expected code in the test. |

## Open Questions

1. **Which exact byte to tamper for the cleanest crypto rejection?**
   - Known: Response-level `<Issuer>` mutation → `:issuer_mismatch` (pre-crypto); Assertion-internal mutation → `:digest_mismatch` (in `do_verify/4`).
   - Unclear: which the demo narrative wants to showcase ("tampered signature" reads as crypto).
   - Recommendation: tamper the Assertion's `<NameID>` text → `:digest_mismatch`; assert that exact `error_code` in the trace step. Document both behaviours in the demo copy.

2. **How does the FakeIdP learn the `InResponseTo` request id?**
   - Known: relyra puts the AuthnRequest in the redirect `SAMLRequest` param and a request-intent keyed by RelayState; the request id is inside both.
   - Recommendation: simplest reliable path — `/fake_idp/login` receives `SAMLRequest` + `RelayState`; inflate/parse `SAMLRequest` to read its `ID`, carry it as a hidden field into `/fake_idp/sso`, emit as `:in_response_to`. (Parsing the deflated base64 AuthnRequest is a few lines; alternatively read the request_id from the relyra `RelayState` token if its format is accessible.) Plan should read `Relyra.Protocol.Binding.encode_redirect` / `RelayState.issue` to choose.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| OTP `:public_key`/`:crypto` | signer + cert | ✓ | OTP (relyra already uses) | — |
| relyra public C14N modules | byte-compat signing | ✓ | path dep 1.7.0 | — |
| Postgres (demo Repo) | Ecto connection/cert/intent/replay/audit | ✓ (demo already uses) | per demo config | — |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + `Phoenix.ConnTest` + `Phoenix.LiveViewTest` (demo `LedgerLoopWeb.ConnCase`) |
| Config file | `demo/ledger_loop/test/test_helper.exs` (existing) |
| Quick run command | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/fake_idp_controller_test.exs` |
| Full suite command | `mix ci.demo_app` (rides existing `demo-app-ci.yml`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEED-003 | `GET /fake_idp/login` renders "Local Test Support / FakeIdP" banner + passes RelayState | controller | `mix test .../fake_idp_controller_test.exs` | ✅ (WIP — recover) |
| SEED-003 | `POST /fake_idp/sso` renders self-submitting form with `SAMLResponse` to `/saml/<…J0>/acs` | controller | same | ⚠️ WIP asserts `/saml/acs` — update to scoped path |
| SEED-003 | **Success:** signed response → `do_verify/4` `{:ok}` → `SessionAdapter` LoginReceipt inserted → redirect `/` | integration | `mix test` (post to relyra ACS in-process) | ❌ Wave 0 |
| SEED-003 | **Crypto byte-compat:** vendored signer output verifies under relyra `Signature.verify/4` against demo cert PEM | unit | `mix test` (call `Signature.verify` or full `consume_response`) | ❌ Wave 0 |
| SEED-003 | **Tampered:** mutated assertion → `consume_response` `{:error, %Error{type: :digest_mismatch}}` | unit/integration | `mix test` | ❌ Wave 0 |
| SEED-003 | **Trace surfacing:** tampered attempt writes `domain: :login` AuditEvent (outcome error, error_code) visible at `/relyra/admin/connections/<…J0>/trace` | LiveView | `mix test` (`LiveViewTest` mount trace) | ❌ Wave 0 (also requires LoginTrace.attach) |
| SEED-003 | Existing Phase-53 `/fake_idp/*`-adjacent tests stay green; demo suite stays 37/0+ | suite | `mix ci.demo_app` | ✅ existing |

### Sampling Rate
- **Per task commit:** `cd demo/ledger_loop && mix test` (scoped fake_idp + signer tests).
- **Per wave merge:** `mix ci.demo_app` (full demo suite).
- **Phase gate:** demo suite green AND relyra `mix qa` / `mix ci.security` untouched and green (no relyra source change in this phase).

### Wave 0 Gaps
- [ ] `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs` — proves vendored signer output passes `Relyra.Security.Signature.verify/4` (and full `consume_response`) with the demo cert PEM; proves tamper → `:digest_mismatch`. Covers byte-compat + tamper.
- [ ] `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` — end-to-end in-process: drive `/saml/:id/login` → follow to `/fake_idp/*` → POST to `/saml/:id/acs`; assert success redirect + LoginReceipt; assert tampered → error + trace row.
- [ ] Update recovered `fake_idp_controller_test.exs` assertion `action="/saml/acs"` → `action="/saml/<…J0>/acs"`.
- [ ] LoginTrace handler attach in `LedgerLoop.Application` (production code, but its absence is what makes the trace test fail — treat as Wave 0 wiring).
- [ ] Keypair/cert PEMs committed under `priv/fake_idp/` + fixture `:pem` updated (Wave 0 fixture/data prerequisite).

*(Framework already present — no install needed.)*

## Security Domain

> `security_enforcement` not explicitly false in repo config; included. Note: this phase touches NO relyra security code — it earns a real verification through the existing gate.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | SAML assertion verified by relyra `do_verify/4` (unchanged) |
| V3 Session Management | yes | demo `SessionAdapter` LoginReceipt (existing) |
| V4 Access Control | no | demo trust posture unchanged |
| V5 Input Validation | yes | relyra parse/validate pipeline (unchanged); demo signer emits well-formed XML only |
| V6 Cryptography | yes | RSA-2048 + SHA-256 via `:public_key`; **never hand-rolled**; C14N via relyra engine |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Divergent demo C14N masks a real bug | Tampering/Repudiation | Reuse relyra's `C14N`/`PureBeam` — no second canonicalizer (Don't Hand-Roll) |
| Demo signer leaks into prod trust | Elevation | Demo-only keypair in `demo/ledger_loop/priv/`; relyra `prod_elixirc_paths` `test_support` exclusion untouched; relyra TestSupport never imported at runtime (CONTEXT fence) |
| Document-KeyInfo trust | Spoofing | relyra rejects `key_info_trust` (signature.ex:174); demo cert comes from configured connection cert only |
| Replay of demo response | Tampering | relyra replay store (vary assertion ID per sign, Pitfall 6) |
| Tampered assertion accepted | Tampering | The whole point: `:digest_mismatch` typed rejection — verified by test + trace |

**Hard fences honored:** no change to `prod_elixirc_paths`, no `Relyra.TestSupport` runtime use, no verifier/algorithm-policy weakening. All demo-local.

## Sources

### Primary (HIGH confidence)
- `lib/relyra/test_support/xmldsig_signer.ex` — signing technique, cert via `pkix_test_root_cert`, C14N call sites (the authoritative pattern to vendor).
- `lib/relyra/test_support/fake_idp.ex` — assertion shape, keypair caching, `sign/2` wrapper.
- `lib/relyra/security/signature.ex` — `do_verify/4`, `cryptographically_verify`, `verify_signature_math` (`C14N.serialize`), `verify_reference_digest` (`PureBeam.canonicalize`), error taxonomy.
- `lib/relyra/security/xml/c14n.ex` — exclusive-C14N engine (the one to reuse).
- `lib/relyra/security/algorithm_policy.ex` — RSA-SHA256/384/512 + SHA256/384/512 allowlist; no SHA-1.
- `lib/relyra/protocol/validation_pipeline.ex` — Destination/Audience/Recipient/Issuer/time/correlation; the `allow_idp_initiated` (no `?`) read.
- `lib/relyra/ecto/connection_snapshot.ex` — cert PEMs → `cert_chain`/`idp_certificates`; `allow_idp_initiated?` (with `?`) emit (the mismatch).
- `lib/relyra/phoenix/router.ex` + `controllers/{acs,login}_controller.ex` — `/saml/:connection_id/{login,acs}`; SP-initiated mint + consume.
- `lib/relyra/telemetry/handlers/login_trace.ex` + `lib/relyra/live_admin/{query.ex,connection_trace_live.ex}` — trace rows are `domain: :login` AuditEvents; handler NOT attached in demo.
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — `MOCK_PEM_NOT_REAL`, `…J0` connection fields, seeded users/identities.
- `demo/ledger_loop/lib/ledger_loop/relyra/{user_mapper,session_adapter,request_store,replay_store}.ex` — adapter behaviour; subject/issuer lookup.
- `demo/ledger_loop/lib/ledger_loop/application.ex` — confirms LoginTrace handler is unattached.
- `wip/demo-fake-idp` branch — controller/html/test starting point (technique confirmed; fields + ACS path + signer call need correction).

### Secondary / Tertiary
- None — all findings verified directly against in-repo source this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — OTP + relyra public modules read directly.
- Architecture (SP-initiated, C14N reuse): HIGH — verified against pipeline + verifier source; IdP-initiated block confirmed by the `allow_idp_initiated?` snapshot vs `allow_idp_initiated` read.
- Pitfalls: HIGH — each traced to a specific source line / error path.
- Trace surfacing requires LoginTrace.attach: HIGH — demo Application confirmed not to attach it.

**Research date:** 2026-06-13
**Valid until:** 30 days (relyra is a pinned path dep at 1.7.0; stable).

## RESEARCH COMPLETE
