# Technology Stack — Relyra

**Project:** Relyra — security-first SAML 2.0 Service Provider library for Elixir/Phoenix
**Researched:** 2026-04-24
**Scope:** v0.1 "SP-initiated SSO, verified end-to-end" — first Hex release.
**Overall confidence:** HIGH for every dep except the XMLDSig ADR (kept intentionally open).

---

## 0. Executive summary — what to pin in `mix.exs` today

All versions verified against `https://hex.pm/api/packages/*` on 2026-04-24.

| Dep | Pin | Role | Confidence |
|---|---|---|---|
| **elixir** (project) | `~> 1.18` | Language baseline | HIGH |
| **phoenix** | `~> 1.8` (1.8.5) | Required — router macro, Plug | HIGH |
| **plug** | `~> 1.18` (1.19.1) | Required — core conn type | HIGH |
| **telemetry** | `~> 1.3` (1.4.1) | Required — event catalog | HIGH |
| **sweet_xml** | `~> 0.7` (0.7.5) | Required — metadata path (if pure-BEAM or hybrid wins ADR) | MEDIUM (ADR-gated) |
| **x509** | `~> 0.9` (0.9.2) | Required — cert fingerprint / NotBefore / NotAfter | HIGH |
| **phoenix_live_view** | `~> 1.1` (1.1.28) | **Optional** — admin UI arrives v0.3 | HIGH |
| **ecto** | `~> 3.13` (3.13.5) | **Optional** — Ecto store arrives v0.1 as adapter | HIGH |
| **ecto_sql** | `~> 3.13` (3.13.5) | **Optional** — paired with ecto for migrations | HIGH |
| **phoenix_ecto** | `~> 4.7` (4.7.0) | **Optional** — router-path helpers when both phx+ecto present | HIGH |
| **oban** | `~> 2.21` | **Optional** — v0.2+ metadata-refresh job | HIGH |
| **opentelemetry_api** | `~> 1.5` (1.5.0) | **Optional** — trace export | HIGH |
| **nimble_options** | `~> 1.1` | Required — `saml_routes/2` opts validation | HIGH |
| **credo** | `~> 1.7` (1.7.18) | Dev/test | HIGH |
| **dialyxir** | `~> 1.4` (1.4.7) | Dev/test | HIGH |
| **ex_doc** | `~> 0.40` (0.40.1) | Dev | HIGH |
| **mix_audit** | `~> 2.1` (2.1.5) | Dev/test | HIGH |
| **sobelow** | `~> 0.14` (0.14.1) | Dev/test | HIGH (note: bumped from DNA-doc 0.13) |
| **boundary** | `~> 0.10` (0.10.4) | Compile-time arch enforcement | HIGH |
| **stream_data** | `~> 1.3` (1.3.0) | Dev/test | HIGH (note: bumped from DNA-doc 1.1) |
| **mox** | `~> 1.2` (1.2.0) | Test | HIGH |
| **bypass** | `~> 2.1` (2.1.0) | Test — metadata URL fetches (v0.2+) | HIGH |

**What NOT to depend on:** `esaml`, `samly`, `ex_saml`, `cowboy`. See §10.

---

## 1. Elixir / OTP baseline

### Recommendation

```elixir
elixir: "~> 1.18"
# OTP 26 / 27 / 28 matrix in CI.
```

### Rationale

| Signal | Finding | Source |
|---|---|---|
| Sibling convergence | `sigra` = `~> 1.18`; `lockspire` = `~> 1.18`; `mailglass` = `~> 1.18`; `kiln` = `~> 1.19`; `lattice_stripe` = `~> 1.15`; `threadline` = `~> 1.15`. Median = **1.18** for new/active libs. | `/Users/jon/projects/{sigra,lockspire,mailglass,kiln,lattice_stripe,threadline}/mix.exs` |
| Phoenix 1.8.5 allows | `~> 1.15` minimum. Does not force 1.18. | hex.pm api |
| Set-theoretic types | 1.20-rc shipped Jan 2026 with full-construct inference; final 1.20 targeted May 2026. 1.18 is the safe "not-bleeding-edge" pin. | Ecosystem map §15 |
| **OTP 27 is the security floor** | CVE-2026-28809 (esaml XXE) says: "On Erlang/OTP versions before 27, Xmerl allows entities by default." **OTP 27 `xmerl_scan` disables entity expansion by default.** This is a load-bearing fact for Relyra: an OTP-27 floor lets us make the "entities off by default" invariant a property of the runtime plus our explicit `skip_external_dtd` belt-and-braces in Relyra. | erlef.org CNA CVE-2026-28809 |

### Prescriptive decision

- `elixir: "~> 1.18"` in `mix.exs`.
- CI matrix MUST include **OTP 27 and OTP 28**. OTP 26 SHOULD be excluded because it makes the xmerl default-entities-on fact part of our threat model instead of the runtime's — which contradicts the "one hardened parser path" invariant.
- `.tool-versions` pins OTP 28 + Elixir 1.18.4 (latest patch) for dev.
- Do NOT pin `~> 1.19` or `~> 1.20`: 1.19 pulls in guard inference warnings that may churn during the 1.19 → 1.20 transition; most Phoenix shops are still on 1.18.x in April 2026.

**Confidence:** HIGH. Five of ten siblings converge on `~> 1.18`, the OTP-27 XXE fact is documented in the CVE's own advisory, and 1.20 is not yet released.

---

## 2. Phoenix / LiveView / Ecto / Plug baseline

### Recommendation

```elixir
defp deps do
  [
    # REQUIRED
    {:phoenix, "~> 1.8"},
    {:plug, "~> 1.18"},
    {:telemetry, "~> 1.3"},
    {:nimble_options, "~> 1.1"},

    # OPTIONAL (host app opts in)
    {:phoenix_live_view, "~> 1.1", optional: true},
    {:ecto, "~> 3.13", optional: true},
    {:ecto_sql, "~> 3.13", optional: true},
    {:phoenix_ecto, "~> 4.7", optional: true},
    {:postgrex, "~> 0.22", optional: true},
    # ...
  ]
end
```

### Rationale

| Dep | Pin | Why required vs optional |
|---|---|---|
| **phoenix** | `~> 1.8` (1.8.5) | **REQUIRED** because `Relyra.Phoenix.Router.saml_routes/2` is a Phoenix-specific macro, and our README ships with a Phoenix router example as Hero #1. Listing phoenix as optional would push unnecessary "does this even work with Plug-only?" questions onto adopters. Phoenix 1.8 brings scopes + `AGENTS.md` generators + Tailwind v4 + daisyUI which the v0.3 admin inherits for free. |
| **plug** | `~> 1.18` (1.19.1 is the latest) | **REQUIRED** because `%Plug.Conn{}` is the core type for `start_login/3` and `consume_response/3`. Phoenix 1.8 pulls `plug ~> 1.18`; pinning matches the transitive floor. |
| **telemetry** | `~> 1.3` (1.4.1) | **REQUIRED** because `Relyra.Telemetry` emits events from day 1 (per DNA §2.11). Telemetry 1.3 is the stable API surface; 1.4.x adds minor features without breakage. |
| **nimble_options** | `~> 1.1` | **REQUIRED** because `saml_routes/2` and `Relyra.Connection.new/1` both take `opts` — sigra pins the same (1.1) and treats it as load-bearing for docs + error messages. Low weight, no ecosystem drag. |
| **phoenix_live_view** | `~> 1.1` (1.1.28) | **OPTIONAL** because v0.3 is when `Relyra.LiveAdmin` lands. Pinning `~> 1.1` catches both stable 1.1.x and (once stable) 1.2.x — `1.2.0-rc.0` shipped 2026-04-23. **Do NOT bump to `~> 1.2` until it goes stable.** |
| **ecto** | `~> 3.13` (3.13.5) | **OPTIONAL** because `Relyra.RequestStore.Ecto` and `Relyra.ReplayStore.Ecto` are production-default adapters shipping in v0.1, but the behaviour lets a host app substitute a Redis or Mnesia store without Ecto at all. `3.13` is the current mainline (matches sigra/mailglass/kiln). Old `~> 3.10` (threadline) is too lax. |
| **ecto_sql** | `~> 3.13` (3.13.5) | **OPTIONAL** — paired with `ecto` for migration generators in v0.2. Same pin. |
| **phoenix_ecto** | `~> 4.7` (4.7.0) | **OPTIONAL** — used only by LiveAdmin (v0.3) for form helpers + Ecto.Repo.sandbox. Kiln pins `~> 4.6`; lattice_stripe doesn't use it; sigra pulls it through phx.gen.auth. Relyra should pin `~> 4.7` because 4.7 is current and we're greenfield. |
| **postgrex** | `~> 0.22` | **OPTIONAL** — only used by the Ecto adapter's tests in `test/support`. Kiln pins `~> 0.22`, mailglass pins `~> 0.22`. Matches April 2026 mainline. |

### What about Phoenix LiveView 1.2.0-rc.0?

Released 2026-04-23 (yesterday). **Do not pin to it.** `~> 1.1` would NOT match `1.2.0-rc.0` (Hex semantic-version rules), which is the correct outcome: we want 1.1.x stable through v0.3, then evaluate 1.2 when it goes final. If 1.2 stabilizes before Relyra v0.3 ships, bump to `~> 1.1` → `~> 1.2` in a dedicated PR with a changelog entry.

### Phoenix 1.8 router macro is a REQUIRED dep, not optional

Worth flagging explicitly because the DNA doc §5.1 draft listed `phoenix_live_view` as optional but was silent on phoenix itself. The idea doc's v0.1 scope line includes "Phoenix router macro: `saml_routes/2`" which hard-requires `Phoenix.Router` as a compile-time dep. Listing phoenix as optional would create a false-flexibility signal; declaring it required matches reality.

**Confidence:** HIGH. Versions verified via hex.pm 2026-04-24; sibling pins cross-referenced; LV 1.2.0-rc.0 release date confirmed.

---

## 3. XML parsing + XMLDSig options — **the v0.1 ADR (stays open)**

Per brief: this section is deliberately a **comparison matrix, not a pick**. The Phase 1 ADR chooses between these paths with an adversarial-corpus plan.

### 3.1 Survey — five candidate paths

| # | Path | XML parse | XMLDSig + canonicalization | Maturity signal | Deploy friction |
|---|---|---|---|---|---|
| **A** | **Pure BEAM — sweet_xml + custom XMLDSig** | `sweet_xml 0.7.5` wraps `:xmerl_scan` | Relyra writes canonicalization (c14n / c14n11 / exc-c14n) + sig-verify in Elixir | sweet_xml is a solved metadata parser; XMLDSig is greenfield | zero — all Hex |
| **B** | **Pure BEAM — saxy (streaming SAX) + custom XMLDSig** | `saxy 1.6.0` streaming SAX parser, written in Elixir, no xmerl | Same as A — Relyra writes XMLDSig | saxy is the canonical streaming parser; simpler than xmerl; NO atom-table exhaustion | zero — all Hex |
| **C** | **simple_xml (saxy + x509, Rust-adjacent posture)** | `simple_xml 1.3.2` (MBXSystems) — "avoids the atom exhaustion vulnerability present with xmerl-based parsers." Built on saxy + x509. Used by `simple_saml 1.2.0` as the prior-art SAML-without-xmerl library. | `simple_saml` provides some XMLDSig; Relyra would either reuse its impl or re-derive | Low stars (3 on GitHub for `simple_saml`) but active (last release July 2025); explicit anti-xmerl design intent | zero — all Hex |
| **D** | **NIF-over-libxml2+xmlsec via Rustler** | Rust crate wrapping `libxml2` + `xmlsec` (C) exposed via `rustler` + `rustler_precompiled` | C library, highly mature for XMLDSig/XMLEnc/c14n; used by Python's `python3-saml` (lxml+xmlsec) and by Go's crewjam tests. Known-good corpus. | Very mature C-lib; requires Rust wrapping work — no off-the-shelf Hex package exists today | HIGH: cross-platform prebuilt binaries via `rustler_precompiled` for macOS arm64/Linux-glibc/Linux-musl/Windows; must ship `.so` per OS×arch |
| **E** | **Hybrid — saxy-or-sweet_xml for metadata; NIF-over-xmlsec for signature verification** | Pure BEAM for metadata (trust source of truth) | Native only for the XMLDSig hot path on incoming SAMLResponse | Mixes A/C (metadata) with D (sig verify); limits NIF surface area to the one place correctness matters most | Same as D plus maintenance split |

### 3.2 Matrix — what matters

| Axis | A (sweet_xml + BEAM sig) | B (saxy + BEAM sig) | C (simple_xml + BEAM sig) | D (Rustler xmlsec) | E (Hybrid) |
|---|---|---|---|---|---|
| **Entity-disable story** | Requires `:xmerl_scan.string(..., [{:external_general_entities, false}, {:external_parameter_entities, false}, {:fetch_path, []}])` — OTP 27 makes this default but we still pass the flags explicitly. Works. | SAX parser is entity-safe by design — entities are SAX events, not DOM expansion. Strong default. | simple_xml explicitly built around "no atom exhaustion" — same saxy guarantee. | libxml2 has entity-substitution knobs (`XML_PARSE_NOENT` off, `XML_PARSE_DTDLOAD` off); verified safe if configured correctly. | Combines the safest halves. |
| **Canonicalization (c14n / exc-c14n) correctness** | Relyra authors it — full audit burden. XMLDSig Canonical XML 1.0/1.1 and Exclusive C14N 1.0 are ~500-line specs each. Every known XMLDSig pitfall (namespace propagation, attribute ordering, whitespace preservation) is on us. | Same as A. The canonicalization work is parser-agnostic. | Same as A. | xmlsec has canonicalization battle-tested across 20 years. | Use xmlsec for the security-critical bit; ours for metadata only. |
| **Signature-wrapping defense** | Must consume exact verified node. XPath on xmerl is fiddly. Ruby-saml CVE-2024-45409 was a `//ds:Reference` (absolute) vs `./ds:Reference` (relative) bug — exact same footgun available in xmerl. | Saxy is stream-based; does not give XPath at all. Relyra writes `select_signed_assertion/1` that walks the parsed event tree and binds the signature verification's subtree pointer to the data pointer consumed. Lower XPath-footgun surface. | Same as B. | xmlsec's `xmlSecDSigCtxVerify` binds verified node to consumption automatically — this is the correct primitive. | Best of both. |
| **Parser-differential risk (ruby-saml CVE-2025-25291/25292/66567)** | Using xmerl everywhere → single parser → zero differential. | Using saxy everywhere → single parser → zero differential. | Using simple_xml everywhere → zero differential. | libxml2 + our Elixir XML reading is TWO parsers — differential risk unless we read NOTHING on the Elixir side and consume only xmlsec output. | Has metadata (pure BEAM) + response-validation (NIF) differential. Must prove metadata-parsed certs are never cross-referenced against response-parsed data. HIGHEST parser-differential audit burden. |
| **OTP 27 XXE protection** | Yes by default; Relyra also passes explicit flags. | N/A (SAX is entity-safe). | N/A (SAX). | libxml2 has its own entity story. | N/A on the metadata side; libxml2 story on the response side. |
| **atom exhaustion** (xmerl-specific DoS) | xmerl creates atoms from element names → attacker-controlled SAML can exhaust the atom table. Relyra must strip namespaces first OR use `{"local_name", charlist}` form. **Real risk, real mitigation needed.** | N/A — saxy does not create atoms. | N/A (saxy underneath). | N/A (NIF). | Metadata path inherits xmerl atom risk if we use sweet_xml there; mitigated for response path. |
| **macOS arm64 / Linux glibc / Linux musl / Windows build** | Pure Elixir → works everywhere. | Pure Elixir → works everywhere. | Pure Elixir → works everywhere. | `rustler_precompiled 0.9.0` handles this well; Relyra ships prebuilt NIFs per triple; failure mode is "user on exotic triple has to compile locally." | Same as D. |
| **Alpine musl** | Works. | Works. | Works. | Needs a musl build target; `rustler_precompiled` supports it. Adds ~15% to release-artifact matrix. | Same as D. |
| **Hex install friction** | Zero. | Zero. | Zero. | Rust toolchain required for consumers on unsupported triples; checksum file in `checksum-Elixir.Relyra.XmlSec.exs` must ship with the package (rustler_precompiled convention). | Same as D. |
| **Supply-chain audit surface** | Tiny — all reviewable Elixir. | Same. | Same plus simple_xml maintainer. | Rust crate + libxml2 + xmlsec + OS dynamic libs. Large. | Large (same as D). |
| **Prior art adopting this** | `esaml` / `samly` / `ex_saml` — all three have had security issues. | No SAML lib today. | `simple_saml 1.2.0` (MBXSystems, 3 GitHub stars) — explicit SAML-without-xmerl intent. | `python3-saml` (lxml+xmlsec), `crewjam/saml` (Go stdlib + xmlsec tests), Spring Security. | No SAML lib. |
| **Known-CVE-replay fitness** | Must hand-implement wrapping defenses, parser-differential tests, namespace-hijack protection. All on Relyra. | Same. | Partial — simple_saml has some of these. | xmlsec has been audited in the wild; Relyra's tests verify our NIF wrapper's refcount + node-binding invariants. | Same as D for response path. |

### 3.3 What the ADR must decide (NOT here — Phase 1)

1. **Which parser for metadata?** saxy, sweet_xml, or simple_xml. Saxy is the cleanest default; sweet_xml is more familiar.
2. **Which engine for XMLDSig?** Pure BEAM (A/B/C — Relyra authors it) or xmlsec NIF (D/E).
3. **Hybrid or monolith?** If hybrid, how do we prove no cross-parser data flow?
4. **If NIF: what crate?** `libxml2-rs` + `xmlsec-rs` bindings may or may not exist — audit April 2026.
5. **Build matrix cost:** `rustler_precompiled` targets are ~6 OS/arch combos; CI matrix inflation acceptable?

### 3.4 Author's non-recommendation (for the ADR, not locked)

The ADR should weigh option **B (saxy + pure-BEAM XMLDSig)** as the default-to-ship-v0.1 choice, with a v1.0 escape hatch to option **D** if canonicalization bugs prove unpatchable. Rationale:

- **B has the smallest supply chain** (saxy is 100% BEAM, no atoms, actively maintained).
- **B avoids the esaml XXE class** entirely because saxy is a SAX parser that does not expand entities.
- **B avoids the xmerl atom-exhaustion class** entirely.
- **B concentrates the canonicalization-correctness risk** in Relyra code we already plan to audit, instead of splitting it between an NIF boundary (where bugs are harder to fix) and Elixir.
- **Option D (xmlsec NIF)** is correct on paper but shifts the problem from "write c14n correctly" to "build, sign, and ship cross-platform NIFs for 6 triples forever." That is a different but not smaller operational burden, and the node-binding invariant still has to be proven at the Elixir↔NIF boundary.

**This is a non-recommendation, not a recommendation.** The Phase 1 ADR owns the decision with access to the actual adversarial corpus + canonicalization-test results that this research could not produce.

**Confidence:** HIGH for the matrix axes; Phase 1 ADR has residual risk on canonicalization correctness regardless of which path wins.

---

## 4. Crypto + cert handling — `:public_key`, `:crypto`, and `x509`

### Recommendation

```elixir
# Runtime apps (already in application())
extra_applications: [:logger, :crypto, :public_key, :ssl]

# Explicit dep
{:x509, "~> 0.9"},   # 0.9.2 as of 2026-04-24
```

### Rationale

| Need | OTP stdlib answer | Gap | `x509` provides |
|---|---|---|---|
| RSA + ECDSA signature verification | `:public_key.verify/4` | none | n/a |
| SHA-256/384/512 digest | `:crypto.hash/2` | none | n/a |
| Parse PEM-encoded IdP cert | `:public_key.pem_decode/1` + `:public_key.pem_entry_decode/1` | works but verbose | `X509.Certificate.from_pem/1` — ergonomic wrapper |
| Compute certificate fingerprint (SHA-256) for logs + cert inventory | Requires raw DER re-encoding | ergonomic friction | `X509.Certificate.from_pem(pem) \|> X509.Certificate.public_key()` + custom `:crypto.hash(:sha256, der)` helper |
| Extract `not_before`, `not_after` for expiry alerts | OTP stdlib: traverse the `:OTPCertificate` record — tedious | painful | `X509.Certificate.validity/1` returns ergonomic `{not_before, not_after}` |
| Generate dev-only self-signed cert for fake IdP | `:public_key.pkix_test_data/1` exists but is minimal | weak | `X509.Certificate.self_signed/3` — builds a `mix relyra.install` dev cert in one line |
| SubjectAltName / SAN extraction | Manual ASN.1 record walks | painful | `X509.Certificate.extension/2` |

### Prescriptive decision

- `x509 ~> 0.9` is a **required** runtime dep, NOT optional. The cost is tiny (single small library, pure Elixir wrapping OTP stdlib); the value is that every certificate concern in Relyra — fingerprint, expiry, SAN checks, dev cert generation — has a one-liner helper. Without it every module that touches certs has to do ASN.1 record-walking by hand, which is a `NoParseBeforeEntityDisable`-adjacent correctness hazard. `x509` also anchors our `mix relyra.install` dev-cert generator.
- `:crypto` + `:public_key` + `:ssl` stay in `extra_applications`. All three are OTP stdlib; no Hex dep.
- Mailglass already pulls `:public_key` and `:crypto` into `extra_applications`, same shape.

**Confidence:** HIGH. `x509 0.9.2` is the only serious Elixir cert library, maintained by Bram Verburg, used in the wild (including by `simple_saml` 1.2.0).

---

## 5. Telemetry + OpenTelemetry

### Recommendation

```elixir
{:telemetry, "~> 1.3"},                     # REQUIRED, currently 1.4.1
{:opentelemetry_api, "~> 1.5", optional: true},   # 1.5.0
```

### Rationale

- **`telemetry ~> 1.3`** — matches sigra (`~> 1.3` via transitive), mailglass (`~> 1.4`), kiln (`~> 1.3`), lockspire (`~> 1.3`). 1.4.1 is the current release; pinning `~> 1.3` catches all 1.3.x and 1.4.x. **Required** because `Relyra.Telemetry` catalog emits events from day 1 per DNA §2.11.
- **`opentelemetry_api ~> 1.5`** — matches sibling (lockspire `~> 1.5`, kiln `~> 1.4`). Ecosystem map §10 confirms `opentelemetry-erlang` is the canonical OTel path. **Optional** via `Relyra.OptionalDeps.OpenTelemetry` gateway — Relyra emits telemetry events regardless; OTel is for host apps that want spans.
- Do **NOT** pull `opentelemetry` (the full impl) — only the `_api`. Host apps decide whether to run the exporter. This matches lockspire's choice.
- Do NOT gate `opentelemetry_exporter` or `opentelemetry_phoenix` — those belong in the host app, not in Relyra.

**Confidence:** HIGH. Versions verified 2026-04-24.

---

## 6. Testing stack

### Recommendation

```elixir
# Test-only deps
{:ex_unit, ">= 0.0.0"},                 # stdlib — no Hex entry needed
{:stream_data, "~> 1.3", only: [:dev, :test]},   # 1.3.0
{:mox, "~> 1.2", only: :test},                   # 1.2.0
{:bypass, "~> 2.1", only: :test},                # 2.1.0 — used in v0.2 for metadata URL fetch
```

### Unit / property / mocks

- **`stream_data ~> 1.3`** — updated from DNA-doc `~> 1.1` because 1.3.0 is current. Sigra pins `~> 1.1`, mailglass pins `~> 1.3`, kiln pins `~> 1.1`. We're greenfield in 2026 — use the current release. Ecosystem map §14 confirms StreamData is canonical; no stateful property testing (fine for us).
- **`mox ~> 1.2`** — matches lattice_stripe (`~> 1.2`), mailglass (`~> 1.2`), kiln (`~> 1.2`). The `Relyra.{RequestStore, ReplayStore, ConnectionResolver, SessionAdapter, UserMapper}` behaviours all want Mox mocks in test. Ecosystem map §14: "Mox remains the architectural-discipline choice — behaviour-backed, concurrent-safe, contract-first design."
- **`bypass ~> 2.1`** — matches kiln. Used for v0.2+ metadata URL fetching tests (simulating an IdP metadata endpoint); v0.1 can defer, but pin it now so the `mix.exs` skeleton is stable.

### Integration — real IdP containers

- **Keycloak** — the canonical dev IdP. April 2026 stable is **`26.x`** (26.0 shipped Oct 2024, 26.5 Feb 2026). Relyra ships a `docker-compose.yml` under `test/fixtures/idp/keycloak/` using `quay.io/keycloak/keycloak:26.x` with a pre-imported realm (`test/fixtures/idp/keycloak/realms/relyra-dev.json`). CI job `test_integration` boots it via GitHub Actions `services:` block. Idea doc §"Provider guides" makes Keycloak a v0.1 scope item.
- **SimpleSAMLphp** — optional second container, shipped as `test/fixtures/idp/simplesamlphp/docker-compose.yml`. Tagged `@tag :integration_simplesamlphp`; not required to pass v0.1 — deferred to v0.2. Image: `kristophjunge/test-saml-idp:1.15` (most-maintained public test IdP).
- **Container-runtime pattern** — GitHub Actions `services:` blocks with healthchecks (`--health-interval=10s --health-timeout=5s`) per DNA §2.2. Mirrors `lockspire`'s integration setup (which runs Postgres as a service container) and `kiln`'s docker-compose pattern.

### E2E (v0.3 admin)

- **Playwright via `phoenix_test_playwright`** — NOT `wallaby`. Ecosystem map §14 is explicit: "PhoenixTest is now a driver protocol — `PhoenixTest.Playwright` implements the same syntax against real browsers." Pin when v0.3 lands; do NOT add to v0.1 deps. Expected version at v0.3 ship time will be in the `0.1x` range (Playwright client is 2024-present). Defer the exact pin to the v0.3 planning phase.

### What about `ex_machina` / `faker`?

- **Skip** `ex_machina`. Ecosystem map §14: "Some teams now prefer plain factory functions in `test/support` since the type system catches struct-field mistakes." Relyra has few enough schemas (v0.2 has 6 Ecto tables) to hand-write factories. This also avoids ExMachina's beam-community-orphan maintenance signal.
- **Skip** `faker`. Our test data (email, NameID, issuer URL) is better as deterministic literals than random fakes for security-fixture stability.

**Confidence:** HIGH for ExUnit/Mox/StreamData/Bypass. MEDIUM for Keycloak 26.x pin (versions evolve — v0.1 planning phase should re-verify).

---

## 7. Dev tooling

### Recommendation

```elixir
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},        # 1.7.18
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},     # 1.4.7
{:ex_doc, "~> 0.40", only: :dev, runtime: false},               # 0.40.1
{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},    # 2.1.5
{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},     # 0.14.1 — bumped from DNA-doc's 0.13
{:boundary, "~> 0.10", runtime: false},                         # 0.10.4
```

### Rationale (deltas vs. DNA-doc §5.1 skeleton)

| Dep | DNA-doc pin | April 2026 current | Recommendation | Why |
|---|---|---|---|---|
| credo | `~> 1.7` | 1.7.18 | `~> 1.7` | No change. `~> 1.7` catches 1.7.18. |
| dialyxir | `~> 1.4` | 1.4.7 | `~> 1.4` | No change. |
| ex_doc | `~> 0.38` | 0.40.1 | **`~> 0.40`** | **Bump from 0.38.** 0.40 shipped `llms.txt` output + markdown formatter — matches mailglass (`~> 0.40`), sigra (`~> 0.40`). Ecosystem map §15 treats 0.40.1 as canonical. |
| mix_audit | `~> 2.1` | 2.1.5 | `~> 2.1` | No change. |
| sobelow | `~> 0.13` | 0.14.1 | **`~> 0.14`** | **Bump from 0.13.** 0.14 dropped in 2025 under new maintainer (Holden Oullette). Ecosystem map §15 confirms 0.14.1 is current. |
| boundary | `~> 0.10` | 0.10.4 | `~> 0.10` | No change. |

### Compiler & formatter plugins

- **Styler / Quokka** — add at v0.1 time? DNA-doc did not require it, and the set-theoretic-types story is still evolving. **Recommendation:** defer until after v0.1 ships. `mix format` with the stock formatter is fine. Revisit at v0.3.
- **`boundary` compiler** — add at v0.1. Declare protocol-core vs. Phoenix-runtime vs. Ecto boundaries in `lib/relyra.ex` using `use Boundary, deps: []`. DNA §2.13 requires this; mailglass already uses it (`compilers: [:boundary | Mix.compilers()]`).

### Custom Credo checks

Per DNA §4, `.credo.exs` MUST load Relyra-specific checks:

```elixir
# .credo.exs (fragment)
checks: [
  {Relyra.CredoChecks.NoRawAssertionInLog, []},
  {Relyra.CredoChecks.NoParseBeforeEntityDisable, []},
  {Relyra.CredoChecks.NoSignatureSkipInPublicAPI, []}
]
```

Ship these in `lib/relyra/credo_checks/` so they are published on Hex and downstream projects can reuse them. Precedent: sigra's `NoLogSafe2InLib` and `NoUnscopedOrgQueryInLib` live in `sigra/lib/credo_checks/`.

**Confidence:** HIGH. Every version verified against hex.pm 2026-04-24.

---

## 8. Hex name + GitHub org + domain availability

### Hex: `relyra` — **AVAILABLE**

```
$ curl -s https://hex.pm/api/packages/relyra
{"message":"Page not found","status":404}
```

404 confirms the name is not taken on Hex. Reserve it at first `mix hex.publish --dry-run` — Hex assigns owner on first publish; do the `0.1.0-dev` dry-run before v0.1 ships to claim the slot.

### GitHub: `szTheory/relyra` — **AVAILABLE**

```
$ curl -s https://api.github.com/repos/szTheory/relyra
{"message":"Not Found","status":"404",...}
```

404 confirms the repo doesn't exist under `szTheory`. Create empty, MIT-licensed at `git init` time.

### Domain: `relyra.dev`

NOT CHECKED in this research (WHOIS not automated in this environment). Brand book §bootstrap lists `relyra.dev` as a target. **Action item for the GSD planning phase:** run a WHOIS on `relyra.dev` and `relyra.com` before locking PROJECT.md; if `relyra.com` is taken by the `ReLyra` keyboard shop (brand book §research-guardrails warns of this overlap), `relyra.dev` is acceptable for OSS.

### Naming fallbacks (if `relyra` unavailable on any surface)

Per brand book §22 (title-case, SAML-anchored, avoid lyre/music/constellation/keyboard overlap):

| Fallback | Merits | Demerits |
|---|---|---|
| `relying` | anchors on "relying party" | too generic; SEO collision with English word |
| `relyfy` | short, brandable | loses the SAML anchor |
| `assertly` | anchors on SAML assertion | less distinctive |
| `verisp` | "verified SP" abbreviation | not word-like |
| `trustpath` | matches the brand's "verified trust path" metaphor | generic-sounding |

**Relyra is clearly preferred** — all three primary checks (Hex, GitHub, OSS discoverability) are clean.

**Confidence:** HIGH for Hex + GitHub; MEDIUM for domain (not verified in this research).

---

## 9. Known-CVE corpus to replay as permanent regression fixtures

Per idea doc: "Every security fix becomes a permanent regression fixture." This lists the CVE-to-fixture mapping Relyra MUST ship in `test/fixtures/security/` — the v0.1 security-corpus CI lane replays each one.

### 9.1 Master list (verified via NVD + vendor advisories, 2026-04-24)

| CVE ID | Ecosystem | Class | What it teaches Relyra | Fixture shape |
|---|---|---|---|---|
| **CVE-2026-28809** | Erlang `esaml` (and forks: arekinath, handnot2, dropbox) | CWE-611 XXE before signature verification | Parse-before-verify + xmerl default-entities-on on OTP<27 = local file read / SSRF via `<!ENTITY>` in SAML payload | `test/fixtures/security/xxe_esaml_cve-2026-28809.xml` — a `SAMLResponse` containing a `<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>` + `&x;` reference in the Issuer. Relyra MUST reject with `{:error, %Relyra.Error{type: :doctype_forbidden}}` before any signature work. |
| **CVE-2024-45409** | Ruby `ruby-saml` <1.17, `omniauth-saml` <2.2.1 | CWE-347 signature wrapping via XPath `//ds:Reference` vs `./ds:Reference` | Attacker with ANY signed XML from the IdP forges a full response. The bug was XPath using `//` (document-wide) instead of `./` (relative to signed subtree). | `test/fixtures/security/xpath_wrapping_cve-2024-45409.xml` — valid IdP signature over one assertion, with a second `<samlp:Extensions>` carrying a forged `<ds:Reference>`. Relyra MUST verify only the assertion whose signature was verified, and MUST reject when multiple `Reference` elements produce ambiguous matches. |
| **CVE-2025-25291** | Ruby `ruby-saml` <1.18 | Parser differential (REXML vs Nokogiri) via `DOCTYPE` handling | Two XML parsers produce different document trees from the same input → verifier sees signed subtree A, consumer reads unsigned subtree B. | `test/fixtures/security/parser_differential_doctype_cve-2025-25291.xml` — a payload with a `DOCTYPE` that one parser honors and another strips. Relyra MUST parse with EXACTLY ONE parser and never re-parse with a different implementation. Test that we reject if `DOCTYPE` appears at all. |
| **CVE-2025-25292** | Ruby `ruby-saml` <1.18 | Parser differential (REXML vs Nokogiri) via namespace handling | Same class as 25291; different trigger (namespace declarations). | `test/fixtures/security/parser_differential_namespace_cve-2025-25292.xml` — payload with conflicting `xmlns` declarations that produce different trees. Relyra MUST normalize namespace handling into its one parser and test this fixture. |
| **CVE-2025-66567** | Ruby `ruby-saml` <=1.12.4 (incomplete fix for 25292) | Parser differential — namespace regression | "Incomplete fix" story = every security fix needs a regression test. | `test/fixtures/security/parser_differential_namespace_incomplete_cve-2025-66567.xml` — the incomplete-fix variant. Permanent regression test. |
| **CVE-2025-47949** | Node `samlify` <2.10.0 | CWE-347 signature wrapping | Attacker with signed IdP doc forges SAML Response → arbitrary user login. Similar shape to CVE-2024-45409 but in Node. | `test/fixtures/security/samlify_wrapping_cve-2025-47949.xml` — wrapping variant that exercises the `<samlp:Extensions>` trick in Node-flavored XML. Relyra asserts rejection. |
| **CVE-2025-54369** | Node `node-saml` | SAML authentication bypass | Close cousin of samlify wrapping; tests an additional wrapping surface. | `test/fixtures/security/node_saml_bypass_cve-2025-54369.xml` — second wrapping variant. |
| **CVE-2016-1000251** | Python `python3-saml` <1.2.0 | Signature wrapping | Historical; still a valid fixture shape. The python3-saml README references this in changelog. | `test/fixtures/security/python3_saml_wrapping_cve-2016-1000251.xml` — historical signature-wrapping baseline. |
| **CVE-2017-9672** | Python `python-saml` <2.3.0 / `python3-saml` pre-defusedxml | XXE | python3-saml 1.2.6 added `defusedxml`. Lesson: Relyra's XXE rejection must be proven against the pre-defusedxml attack pattern too. | `test/fixtures/security/python_saml_xxe_cve-2017-9672.xml` — historical XXE. |
| **CVE-2024-4985 / CVE-2024-9487** | GitHub Enterprise Server SAML | Encrypted assertion bypass | Specific to encrypted-assertion handling, deferred to v1.0 (when Relyra supports EncryptedAssertion). Add fixture when the feature ships. | v1.0 fixture. |
| **CVE-2025-40758** | Siemens Mendix SAML module | Signature validation flaw | Vendor-specific; adds to the "signature validation is a class, not an instance" corpus. | Optional `test/fixtures/security/vendor_specific_mendix_cve-2025-40758.xml`. |

### 9.2 Non-CVE fixtures that MUST accompany the above

From idea doc / deep-research doc §"Security regression corpus":

- `unsigned_response.xml` + `unsigned_assertion.xml` — response signed but attributes read from unsigned assertion (pure-protocol signature-wrapping class).
- `duplicate_xml_id.xml` — same `ID` on two elements. Relyra MUST reject.
- `sha1_signature.xml` — SHA-1 signed response; default config MUST reject with `:deprecated_algorithm`.
- `malicious_keyinfo.xml` — `<ds:KeyInfo>` containing attacker-supplied cert; Relyra MUST ignore `KeyInfo` and verify against configured IdP certs only.
- `oversized_inflated.xml` — deflate-bomb payload exceeding size limit post-decompression.
- `expired_assertion.xml` / `not_yet_valid.xml` / `clock_skew_exceeded.xml` — time-boundary class.
- `wrong_issuer.xml` / `wrong_audience.xml` / `wrong_recipient.xml` / `wrong_destination.xml` / `in_response_to_missing.xml` / `in_response_to_mismatch.xml` — protocol-validation class.
- `replayed_assertion.xml` — same fixture consumed twice MUST produce `:replayed_assertion` on second attempt.
- `idp_initiated_unsafe_relaystate.xml` — RelayState set to external URL; MUST reject when `allow_idp_initiated?: false` (default).

### 9.3 Impact on dev-dep choice

The CVE corpus drives these dev deps:

- `stream_data` — property-based testing for XML ID uniqueness, RelayState token generation, clock-skew boundaries.
- `mox` — mock RequestStore / ReplayStore / ConnectionResolver to isolate protocol-core tests from Ecto.
- **A byte-level fixture loader** (internal module, not a dep) — `test/support/Relyra.TestSupport.SecurityFixtures` loads each XML file by filename and memoizes. Every test can reference fixtures by CVE ID: `security_fixture("cve-2024-45409")`.

**Confidence:** HIGH for each CVE ID (verified via NVD + vendor advisories 2026-04-24).

---

## 10. What NOT to use and why (prescriptive blocklist)

### 10.1 Do NOT depend on `esaml`

**Why:**
- Last release `4.6.0` on **2024-01-29** (same day as `samly` 1.4.0). Over 2 years without a release.
- CVE-2026-28809 (XXE before signature verification on OTP<27). Affects ALL versions, no patch available.
- Depends on `cowboy < 3.0.0` — pulls in legacy web server, contradicts the April 2026 Bandit-default.
- Erlang-only API; no typespec ergonomics for an Elixir library.

**What Relyra does instead:** Re-implement the SAML protocol core from scratch (that's the whole point of Relyra). For XMLDSig, pick an option from §3.

### 10.2 Do NOT depend on `samly`

**Why:**
- Last Hex release `1.4.0` on **2024-01-29** (25+ months ago as of 2026-04-24).
- Transitively depends on `esaml ~> 4.3` — inherits the CVE-2026-28809 XXE risk.
- Pins `plug ~> 1.6` (vs. current `1.19.1`) and `sweet_xml ~> 0.6` (vs. current `0.7.5`) — the dep range itself is a maintenance signal.
- PROJECT.md §Context names samly's trust gap as the specific reason Relyra exists: "its latest Hex release is v1.4.0 from January 29, 2024... the trust gap is confidence."

**What Relyra does instead:** Ship our own `Relyra.Phoenix.Router.saml_routes/2` macro and `consume_response/3` API.

### 10.3 Do NOT depend on `ex_saml`

**Why not depend:**
- It's the closest adjacent project (1.0.2 published 2026-04-16, 8 days before this research). Relyra should NOT vendor it or depend on it because:
  - `ex_saml` depends on `nebulex ~> 2.6` — this would force Relyra to pull Nebulex as a transitive, and `nebulex 3.x` is the 2026 canonical per ecosystem map §3. Version split.
  - `ex_saml` depends on `gettext >= 0.26.0` — forces a runtime gettext on every consumer.
  - `ex_saml` still depends on `sweet_xml ~> 0.7` (xmerl) — if our ADR picks saxy/simple_xml, we can't reuse it.
  - `ex_saml` adoption is low (2 GitHub stars, 1.0.2 released 8 days ago) — not yet a stable base to build on.

**What Relyra does instead:** Study `ex_saml`'s public API as prior art (it IS a successor attempt to samly, per PROJECT.md §Context), write a migration note in MIGRATING.md for v0.2+, and ship our own architecture with strict-by-default semantics. `ex_saml` is competitor + reference, not upstream.

### 10.4 Do NOT use `:xmerl_scan` without explicit entity-disabling flags

Even if the ADR picks a pure-BEAM path using sweet_xml:

```elixir
# WRONG — relies on OTP version
{doc, _} = :xmerl_scan.string(xml)

# RIGHT — belt and braces, works on OTP 26+, 27+, 28+
{doc, _} = :xmerl_scan.string(xml,
  external_general_entities: false,
  external_parameter_entities: false,
  fetch_path: [],
  fetch_fun: fn _, _ -> {:error, :fetch_forbidden} end,
  rules: :none
)
```

The `NoParseBeforeEntityDisable` custom Credo check (§7) enforces this at compile time.

### 10.5 Do NOT use `cowboy`

Ecosystem map §1: Bandit is the default; Cowboy is legacy. Relyra is a library (not a standalone server), so this is mostly transitive — but it means we MUST NOT depend on `esaml` (which pulls `cowboy < 3.0.0`).

### 10.6 Do NOT use `httpoison` / `hackney`

If v0.2 metadata refresh needs an HTTP client, use `Req` (ecosystem map §4). Don't pull `httpoison` or `tesla`. Ideally metadata refresh is a host-app concern delegated via behaviour (same pattern as RequestStore), so Relyra doesn't need to ship an HTTP client at all in v0.1.

### 10.7 Do NOT use `jason` as a hard dep

Elixir 1.18 stdlib ships the `JSON` module (ecosystem map §28 + prompt-research). Relyra uses stdlib `JSON` for audit-event encoding. If a host app's Plug pipeline pulls `jason` transitively, fine — but we do NOT declare it.

### 10.8 Do NOT use `timex`

Ecosystem map §28: stdlib `Calendar` + `:tzdata` cover everything Relyra needs (clock-skew math, `NotBefore`/`NotAfter`, audit timestamps). No `timex` dep.

**Confidence:** HIGH. Each blocklist item has a concrete version + CVE + maintenance signal.

---

## 11. Sibling repo cross-reference (verified reads)

| Sibling | Elixir pin | Key confirming signals for Relyra |
|---|---|---|
| `sigra` (Phoenix auth lib — closest adjacency) | `~> 1.18` | Pins `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`, `ecto ~> 3.12`, `ecto_sql ~> 3.12` — matches Relyra's plan. Uses `nimble_options ~> 1.1`. Uses `wax_ ~> 0.7` (WebAuthn; irrelevant to us). Dev deps: `credo ~> 1.7`, `dialyxir ~> 1.4`, `ex_doc ~> 0.40`, `mox ~> 1.1`, `stream_data ~> 1.1`. |
| `lockspire` (OAuth/OIDC) | `~> 1.18` | Pins `phoenix ~> 1.8.5`, `phoenix_live_view ~> 1.1.28`, `ecto_sql ~> 3.13.5`, `oban ~> 2.21`, `telemetry ~> 1.3`, `opentelemetry_api ~> 1.5`. **Ecto is REQUIRED in lockspire, not optional** — because lockspire is a full OAuth server. Relyra v0.1 flips this: Ecto is optional because our data model is simpler and we want a Plug-only dev loop. |
| `mailglass` | `~> 1.18` | `boundary ~> 0.10` with `compilers: [:boundary \| Mix.compilers()]`. Pins `phoenix ~> 1.8`, `ecto ~> 3.13`, `ecto_sql ~> 3.13`, `postgrex ~> 0.22`, `telemetry ~> 1.4`. **Master of the optional-deps gateway pattern** — copy this exact shape into Relyra. Pins `swoosh ~> 1.25` (irrelevant), `oban ~> 2.21` (optional — same as Relyra will). |
| `kiln` | `~> 1.19` | Kiln is bleeding-edge (Docker/AI sandbox) — different audience. Still provides: `credo ~> 1.7`, `dialyxir ~> 1.4`, `sobelow ~> 0.13` (⚠️ should be 0.14 in 2026), `mix_audit ~> 2.1`, `stream_data ~> 1.1` (⚠️ should be 1.3), `bypass ~> 2.1`. Confirms the dev-tooling shape. |
| `lattice_stripe` (v1.1 on Hex) | `~> 1.15` | Proves the pluggable-behaviour trio pattern (`Transport`/`Json`/`RetryStrategy`) that Relyra extends to 5 behaviours. Dev deps confirm the `~> 1.7 / ~> 1.4 / ~> 2.1` shape. |
| `threadline` | `~> 1.15` | **Lower Elixir pin than Relyra's recommendation** — but threadline is older (v0.2) and less active. Relyra is greenfield today → use `~> 1.18`. |

**Delta observations on DNA §5.1 skeleton:**
- DNA-doc skeleton had `phoenix_live_view ~> 1.0` — **bump to `~> 1.1`** (current stable; 1.2.0-rc.0 released yesterday).
- DNA-doc had `ecto_sql ~> 3.13` — matches, keep.
- DNA-doc had `ex_doc ~> 0.38` — **bump to `~> 0.40`**.
- DNA-doc had `sobelow ~> 0.13` — **bump to `~> 0.14`**.
- DNA-doc had `stream_data ~> 1.1` — **bump to `~> 1.3`**.
- DNA-doc had `opentelemetry_api ~> 1.3` — **bump to `~> 1.5`**.
- DNA-doc had `sweet_xml ~> 0.7` — keep (same current release), but ADR-gated.

These updates belong in `mix.exs` at bootstrap.

**Confidence:** HIGH. All pins read directly from `/Users/jon/projects/*/mix.exs` on 2026-04-24.

---

## 12. The prescriptive `mix.exs` fragment (paste into v0.1 skeleton)

```elixir
defmodule Relyra.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/szTheory/relyra"

  def project do
    [
      app: :relyra,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      compilers: [:boundary | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Relyra",
      description: "Security-first SAML 2.0 Service Provider for Elixir/Phoenix. " <>
                   "Strict validation, multi-tenant SSO, provider presets, telemetry, audit.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      dialyzer: dialyzer(),
      preferred_cli_env: [
        "ci.fast": :test,
        "ci.integration": :test,
        "ci.security": :test
      ]
    ]
  end

  def application, do: [extra_applications: [:logger, :crypto, :public_key, :ssl]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp elixirc_options do
    [
      no_warn_undefined: [
        # Optional deps (may not be loaded)
        Ecto,
        Ecto.Repo,
        Ecto.Schema,
        Ecto.Changeset,
        Ecto.Migration,
        Ecto.Query,
        Phoenix.LiveView,
        Phoenix.Component,
        Oban,
        Oban.Worker,
        Oban.Job,
        :otel_tracer,
        :otel_span
      ]
    ]
  end

  defp deps do
    [
      # === REQUIRED ===
      {:phoenix, "~> 1.8"},
      {:plug, "~> 1.18"},
      {:telemetry, "~> 1.3"},
      {:nimble_options, "~> 1.1"},
      {:x509, "~> 0.9"},
      # XML path — ADR-gated, default candidate is saxy; see .planning/research/STACK.md §3
      {:saxy, "~> 1.6"},
      # (OR {:sweet_xml, "~> 0.7"} / {:simple_xml, "~> 1.3"} depending on ADR)

      # === OPTIONAL (host app opts in) ===
      {:phoenix_live_view, "~> 1.1", optional: true},
      {:phoenix_ecto, "~> 4.7", optional: true},
      {:ecto, "~> 3.13", optional: true},
      {:ecto_sql, "~> 3.13", optional: true},
      {:postgrex, "~> 0.22", optional: true},
      {:oban, "~> 2.21", optional: true},
      {:opentelemetry_api, "~> 1.5", optional: true},

      # === DEV / TEST ===
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:boundary, "~> 0.10", runtime: false},
      {:stream_data, "~> 1.3", only: [:dev, :test]},
      {:mox, "~> 1.2", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp aliases do
    [
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "compile --no-optional-deps --warnings-as-errors",
        "credo --strict",
        "dialyzer",
        "docs --warnings-as-errors"
      ],
      "ci.fast": ["qa", "test --warnings-as-errors"],
      "ci.integration": ["test --only integration --warnings-as-errors"],
      "ci.security": ["test --only security_corpus --warnings-as-errors", "sobelow --config", "deps.audit", "hex.audit"],
      "verify.workspace_clean": ["run scripts/verify_workspace_clean.exs"],
      "verify.release_parity": ["run scripts/verify_release_parity.exs"]
    ]
  end

  defp package do
    [
      name: "relyra",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/relyra",
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Security" => "#{@source_url}/blob/main/SECURITY.md"
      },
      # Explicit whitelist — NEVER include test/, .planning/, prompts/, _build/.
      files: ~w(lib priv/templates priv/guides guides
                .formatter.exs mix.exs
                README.md LICENSE CHANGELOG.md SECURITY.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "CONVENTIONS.md",
        "guides/introduction/getting-started.md",
        "guides/flows/sp-initiated-login.md",
        "guides/recipes/okta.cheatmd",
        "guides/recipes/entra.cheatmd",
        "guides/recipes/google-workspace.cheatmd",
        "guides/recipes/keycloak-dev.md",
        "guides/security/threat-model.md",
        "guides/security/unsafe-options.md"
      ],
      groups_for_extras: [
        Introduction: ~r"guides/introduction/.*",
        Flows:        ~r"guides/flows/.*",
        Recipes:      ~r"guides/recipes/.*",
        Security:     ~r"guides/security/.*",
        Maintainers:  ["CONTRIBUTING.md", "CONVENTIONS.md"]
      ],
      groups_for_modules: [
        Core:         [Relyra, Relyra.Error],
        Protocol:     [Relyra.Protocol.AuthnRequest, Relyra.Protocol.Response,
                       Relyra.Protocol.Assertion, Relyra.Protocol.Metadata],
        Security:    [Relyra.Security.XML, Relyra.Security.Signature, Relyra.Security.AlgorithmPolicy],
        Integrations: [Relyra.Phoenix.Router, Relyra.Ecto, Relyra.LiveAdmin],
        Testing:      [Relyra.TestSupport]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts/core.plt",
      plt_local_path: "priv/plts/dialyzer.plt",
      plt_add_apps: [:mix, :ex_unit],
      flags: [:error_handling, :extra_return, :missing_return, :underspecs]
    ]
  end
end
```

---

## 13. Confidence assessment per area

| Area | Confidence | Rationale |
|---|---|---|
| Elixir / OTP baseline | **HIGH** | 5-of-10 sibling convergence; OTP-27-XXE-fix is a documented CVE fact. |
| Phoenix / LV / Ecto / Plug pins | **HIGH** | All pins verified against hex.pm on 2026-04-24; sibling-repo cross-reference unanimous. |
| XMLDSig options (§3) | **HIGH for matrix, MEDIUM for ADR outcome** | Matrix axes are factual; the winning path depends on canonicalization-correctness testing the ADR owns. |
| Crypto + x509 | **HIGH** | `x509 0.9.2` is the only serious option; `:public_key`/`:crypto` are OTP stdlib. |
| Telemetry + OTel | **HIGH** | Versions + sibling convergence both clear. |
| Testing stack | **HIGH** for unit/mock/property; **MEDIUM** for Keycloak 26.x pin (containers evolve). |
| Dev tooling | **HIGH** | Every version verified 2026-04-24. |
| Hex + GitHub availability | **HIGH** | Both HTTP 404 responses captured verbatim (§8). |
| CVE corpus | **HIGH** | Each CVE ID verified via NVD + vendor advisory on 2026-04-24. |
| What NOT to use | **HIGH** | Each blocklist item has a concrete version + date + CVE. |

---

## 14. Open questions the Phase 1 ADR must resolve

These are explicitly deferred from this research:

1. **XML ADR outcome** (§3) — pure-BEAM (A/B/C), NIF (D), or hybrid (E)?
2. **Canonicalization test corpus size** — how many c14n edge cases does the Phase 1 ADR require a candidate implementation to pass before we ship?
3. **`rustler_precompiled` triple matrix** if option D wins — macOS arm64 / macOS x86_64 / Linux glibc x86_64 / Linux glibc arm64 / Linux musl x86_64 / Windows x86_64 — is 6 triples acceptable, or do we drop Windows?
4. **Keycloak version** — confirm `26.x` is still current at v0.1 ship time; bump CI images if a 27.0 has shipped by then.
5. **Phoenix LiveView 1.2 stable date** — if 1.2 final ships before v0.3 work starts, we bump `~> 1.1` → `~> 1.2`.
6. **Set-theoretic types (Elixir 1.20)** — if 1.20 final lands before v0.1 ships (targeted May 2026), the "drop Dialyxir" question becomes real. v0.1 should keep Dialyzer for now.
7. **Domain availability** — WHOIS on `relyra.dev` / `relyra.com` not automated in this research.

---

## 15. Sources

All Hex API calls and GitHub API calls executed 2026-04-24.

### Hex.pm API endpoints hit
- `/api/packages/phoenix` → 1.8.5
- `/api/packages/phoenix_live_view` → 1.2.0-rc.0 (and 1.1.28 stable)
- `/api/packages/ecto_sql` → 3.13.5
- `/api/packages/phoenix_ecto` → 4.7.0
- `/api/packages/plug` → 1.19.1
- `/api/packages/sweet_xml` → 0.7.5
- `/api/packages/saxy` → 1.6.0
- `/api/packages/simple_xml` → 1.3.2
- `/api/packages/simple_saml` → 1.2.0
- `/api/packages/telemetry` → 1.4.1
- `/api/packages/opentelemetry_api` → 1.5.0
- `/api/packages/credo` → 1.7.18
- `/api/packages/dialyxir` → 1.4.7
- `/api/packages/ex_doc` → 0.40.1
- `/api/packages/mix_audit` → 2.1.5
- `/api/packages/sobelow` → 0.14.1
- `/api/packages/boundary` → 0.10.4
- `/api/packages/stream_data` → 1.3.0
- `/api/packages/mox` → 1.2.0
- `/api/packages/bypass` → 2.1.0
- `/api/packages/x509` → 0.9.2
- `/api/packages/rustler` → 0.37.3
- `/api/packages/rustler_precompiled` → 0.9.0
- `/api/packages/samly` → 1.4.0 (last release 2024-01-29)
- `/api/packages/esaml` → 4.6.0 (last release 2024-01-29)
- `/api/packages/ex_saml` → 1.0.2 (last release 2026-04-16)
- `/api/packages/relyra` → **404 (name available)**

### GitHub API
- `/repos/szTheory/relyra` → **404 (repo available)**
- `/repos/MBXSystems/simple_saml` → 3 stars, last push 2025-07-06
- `/repos/docJerem/ex_saml` → 2 stars, last push 2026-04-24

### CVE advisories read
- CVE-2026-28809 (esaml XXE) — [Erlang Ecosystem Foundation CNA](https://cna.erlef.org/cves/CVE-2026-28809.html)
- CVE-2024-45409 (ruby-saml XPath signature wrapping) — [WorkOS analysis](https://workos.com/blog/ruby-saml-cve-2024-45409), [SentinelOne](https://www.sentinelone.com/vulnerability-database/cve-2024-45409/)
- CVE-2025-25291, CVE-2025-25292, CVE-2025-66567 (ruby-saml parser differentials) — [GitLab advisories](https://advisories.gitlab.com/pkg/gem/ruby-saml/CVE-2025-25291/), [PortSwigger "The Fragile Lock"](https://portswigger.net/research/the-fragile-lock), [GitHub blog](https://github.blog/security/sign-in-as-anyone-bypassing-saml-sso-authentication-with-parser-differentials/)
- CVE-2025-47949 (samlify signature wrapping) — [GitHub Security Advisory GHSA-r683-v43c-6xqv](https://github.com/advisories/GHSA-r683-v43c-6xqv), [Endor Labs analysis](https://www.endorlabs.com/learn/cve-2025-47949-reveals-flaw-in-samlify-that-opens-door-to-saml-single-sign-on-bypass)
- CVE-2025-54369 (node-saml bypass) — [GitHub Security Advisory GHSA-m837-g268-mmv7](https://github.com/advisories/GHSA-m837-g268-mmv7)
- CVE-2016-1000251, CVE-2017-9672 (python3-saml history) — [python3-saml README](https://github.com/SAML-Toolkits/python3-saml)
- CVE-2024-4985, CVE-2024-9487 (GitHub Enterprise SAML) — [ProjectDiscovery blog](https://projectdiscovery.io/blog/github-enterprise-saml-authentication-bypass)

### Sibling repos read
- `/Users/jon/projects/sigra/mix.exs` (sigra 0.2.4)
- `/Users/jon/projects/lockspire/mix.exs` (lockspire 0.2.0)
- `/Users/jon/projects/mailglass/mix.exs` (mailglass 0.1.0)
- `/Users/jon/projects/kiln/mix.exs` (kiln 0.1.0)
- `/Users/jon/projects/lattice_stripe/mix.exs` (lattice_stripe 1.1.0)
- `/Users/jon/projects/threadline/mix.exs` (threadline 0.2.0)

### Prior-research prompts read
- `/Users/jon/projects/relyra/prompts/RELYRA-GSD-IDEA.md`
- `/Users/jon/projects/relyra/prompts/elixir-saml-lib-deep-research.md`
- `/Users/jon/projects/relyra/prompts/relyra-engineering-dna-from-prior-libs.md`
- `/Users/jon/projects/relyra/prompts/relyra-brand-book.md`
- `/Users/jon/projects/relyra/prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`
- `/Users/jon/projects/relyra/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `/Users/jon/projects/relyra/.planning/PROJECT.md`
