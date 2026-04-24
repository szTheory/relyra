# Pitfalls Research — Relyra

**Domain:** Security-first SAML 2.0 Service Provider library for Elixir/Phoenix (greenfield, v0.1 Hex release).
**Researched:** 2026-04-24
**Overall confidence:** HIGH (grounded in published NVD CVEs with CVE IDs, PortSwigger 2025 research, and convergent DNA from ten sibling Elixir libs).

## How to read this doc

Relyra sits on the authentication boundary of adopter Phoenix apps. A single silent bug in Relyra can become a login-bypass CVE in every downstream SaaS. This document enumerates **54 pitfalls** the library must design out, across three buckets:

1. **SAML protocol footguns** (§1) — 26 pitfalls. Mistakes that cross-ecosystem SAML SP libs have repeatedly paid for (Ruby, Node, Python, Erlang).
2. **Elixir OSS library footguns** (§2) — 17 pitfalls. Mistakes that new Elixir libraries make; each one already paid for in a sibling repo.
3. **Security-sensitive OSS footguns** (§3) — 11 pitfalls. Mistakes that security-sensitive libraries specifically make around disclosure, supply chain, and regression discipline.

Each pitfall is tagged with:
- **Severity** — `Critical` (shipping v0.1 with this = yank the release), `High` (ship-blocker for v0.1 scope), `Medium` (fix before v0.2), `Low` (known tradeoff, accept with guardrail).
- **Phase** — the v0.1 phase that owns prevention, or `ongoing` for transversal discipline. Phase numbers align with the five-lane idea-doc shape: Phase 1 (XML security ADR), Phase 2 (protocol core + signature), Phase 3 (stores + replay), Phase 4 (router + Plug runtime), Phase 5 (identity mapping + provisioning), Phase 6 (observability + telemetry + fixtures).
- **Warning signs** — what to look for in code review, tests, or CI output to detect early.
- **Prevention** — concrete, actionable: a Credo check name, a test fixture path, a CI gate, a behaviour callback, a doc callout.

§4 consolidates the phase-to-pitfall ownership table for the roadmapper. §5 is the "Looks Done But Isn't" checklist. §6 is recovery strategies. §7 is sources.

---

## §1 — SAML protocol footguns (26 pitfalls)

These are the mistakes that have shipped as CVEs in `ruby-saml`, `samlify`, `node-saml`, `esaml`, and others between 2024 and 2026. Every one of them must have a permanent regression fixture in `test/fixtures/security/` after the first time it is addressed. Fixtures are permanent even when the code that made them dangerous is deleted — they are the contract with future Relyra.

### 1.1 Parse-before-verify (XXE family) — `esaml` CVE-2026-28809 pattern

**Severity:** `Critical`
**Phase:** 1 (XML security ADR), enforced in Phase 2
**What goes wrong:** Attacker-controlled SAML is parsed with XML entity expansion or DTD resolution enabled *before* signature verification. Attacker reads `/etc/passwd`, mounted Kubernetes secrets, or performs SSRF via external entity references — even when their forged assertion is ultimately rejected for bad signature. The signature check was never the first line of defence.
**Why it happens:** Default XML parsers accept DTDs and entities. Developer writes `xmerl_scan:string/2` or `SweetXml.parse/1` expecting "just parse the XML," signature validation comes second in the code flow, and the parse itself is the CVE. `esaml` shipped exactly this for years.
**Warning signs:**
- `:xmerl_scan.string/1` or `.string/2` called with no options map hardening entity resolution
- `SweetXml.parse/1` called on SAML input (Sweet XML is XPath-over-Xmerl; the underlying scanner defaults carry the same risk on OTP <27)
- Any `String.to_charlist/1 |> :xmerl_scan.string/2` with no `[{:fetch_fun, ...}, {:rules, ...}]` hardening
- Test run against the XXE corpus fixture reads `priv/fixtures/security/xxe_passwd.xml` and returns `{:ok, _}` from the parser
- Commit touches anything under `lib/relyra/protocol/` without also touching `lib/relyra/security/xml.ex`
**Prevention:**
- ADR in Phase 1 locks ONE hardened parser path (`Relyra.Security.XML.parse_hardened/2`). All protocol code calls it; `:xmerl_scan` / `SweetXml.parse/1` / `SweetXml.xpath/2` directly is a compile error.
- Custom Credo check `Relyra.Credo.Check.NoParseBeforeEntityDisable` greps for `xmerl_scan`, `SweetXml.parse`, `SweetXml.xpath` in `lib/` outside `lib/relyra/security/xml.ex` and fails CI.
- `boundary` compiler: `Relyra.Protocol.*` and `Relyra.Phoenix.*` cannot `use`/`alias`/`import` `:xmerl_scan` or `SweetXml` directly.
- Security corpus fixture `test/fixtures/security/xxe_*.xml` replayed against every XML entry point in `ci.security` lane — test name literally reads `"XXE external entity rejected in <module>"`.
- Size-limit guards: pre-base64-decode (`@max_saml_response_bytes 256 * 1024`), post-inflate (`@max_inflated_bytes 1 * 1024 * 1024`), with explicit `:payload_too_large` error atom before parser is called.

### 1.2 Signature wrapping — `samlify` CVE-2025-47949, `node-saml` CVE-2025-54369, classical XSW

**Severity:** `Critical`
**Phase:** 2 (signature + assertion selection), fixture corpus owned by Phase 6
**What goes wrong:** Library verifies a signature over *some* node in the document, then reads user attributes from a *different*, attacker-placed node — typically a duplicated `<Assertion>` appended or wrapped around the signed one. Signature check passes; identity comes from unsigned attacker input. This is the classical XSW attack taxonomy (Somorovsky et al.). `samlify` shipped this in 2025; `node-saml` shipped a variant in 2025-54369 where the verified content and the consumed content diverged.
**Why it happens:** Code path separates "verify signature" (returns `:ok`) from "extract assertion" (reads the whole document). There is no binding between the two operations — the signed node's XPath location is not carried forward.
**Warning signs:**
- `validate_signature/1` returns `:ok` as a bare atom instead of `{:ok, signed_node_ref}`
- `extract_assertion/1` takes the full document as argument rather than the specific node reference returned by signature verification
- Multiple `<saml:Assertion>` elements in a fixture pass validation
- Code reads attributes via `XPath "//saml:Attribute"` (descendant-or-self) instead of a relative path from the signed node ref
- No fixture `test/fixtures/security/xsw_*.xml` in the security corpus
**Prevention:**
- API contract: `verify/2` returns `{:ok, %Relyra.SignedNode{canonical_bytes: ..., node_ref: ...}} | {:error, %Relyra.Error{}}`. Downstream `validate_conditions/1`, `extract_attributes/1` take `%Relyra.SignedNode{}`, never `Plug.Conn` / raw XML / the full doc.
- `%Relyra.SignedNode{}` is opaque (`@opaque` typespec + `@moduledoc false` on fields) — the only way to get one is to pass signature verification.
- Error atom `:signature_wrapping_suspected` is emitted when (a) multiple `<Assertion>` elements are present, (b) ID collision exists, or (c) the signed node's ID does not match the canonical XPath of the top-level assertion.
- Permanent fixtures: 8 classical XSW variants (`xsw_1.xml` through `xsw_8.xml`) from Somorovsky taxonomy + the exact `samlify` 2.10.0 fixture + the `node-saml` CVE-2025-54369 fixture.
- Custom Credo check `Relyra.Credo.Check.NoSignatureSkipInPublicAPI` forbids `validate_signature` returning anything other than `{:ok, %SignedNode{}} | {:error, _}`.

### 1.3 Parser differentials — `ruby-saml` CVE-2025-25291 + CVE-2025-25292 + CVE-2025-66567

**Severity:** `Critical`
**Phase:** 1 (ADR locks single-parser rule), enforced Phase 2 + Phase 6 fixtures
**What goes wrong:** Library parses the XML with parser A (e.g., REXML), verifies signature using XPath against parser A, then extracts attributes using parser B (Nokogiri). The two parsers produce different document structures from the same bytes — REXML treats `xmlns` as a normal attribute, mishandles DOCTYPE declarations, and mishandles namespace inheritance; Nokogiri is spec-compliant. Attacker crafts XML whose meaning differs between parsers; one parser sees the signed element, the other sees the forged one. `ruby-saml` shipped three of these in 2025 alone (DOCTYPE handling 25291; namespace handling 25292; incomplete-fix 66567; PortSwigger "The Fragile Lock" 2025 describes four distinct sub-classes: attribute pollution, REXML namespace confusion, void canonicalization, extension point injection).
**Why it happens:** Two XML libraries were available ("one has better XPath, one has better canonicalization"), author used both, no one noticed they disagreed on edge cases.
**Warning signs:**
- More than one XML parser module referenced anywhere in Relyra (`:xmerl_scan`, `:xmerl_xpath`, `SweetXml`, `Saxy`, `Floki`, `Xmerl` forks)
- Signature verification XPath and attribute extraction XPath run against different parse results
- No test with `xmlns:saml` redeclared to a different URI
- No test with malicious DOCTYPE declaration that changes tree shape
- Dep graph (`mix deps.tree`) shows a transitive XML parser that isn't the one Relyra chose
**Prevention:**
- Phase 1 ADR locks **one** XML parser + **one** canonicalization implementation. No "one for speed, one for correctness." Choice is documented with adversarial-corpus coverage as a gate.
- `mix.exs` excludes transitive XML parsers at compile time via `:mix_deps` override or compile-time guard if a dep pulls in a second parser.
- Custom Credo check `Relyra.Credo.Check.OneXmlParser` forbids any module reference outside `Relyra.Security.XML`.
- PortSwigger-class fixtures: `attribute_pollution.xml`, `rexml_namespace_confusion.xml`, `void_canonicalization.xml`, `extension_point_injection.xml` (even though those were REXML-specific, the class of attack translates — Erlang's xmerl has its own namespace-handling edge cases).
- `Relyra.Security.XML.canonicalize/1` explicitly rejects canonicalized output of length 0 with `:empty_canonicalization` error atom (void canonicalization defence).
- Test: for every fixture with multiple possible tree interpretations, assert the one interpretation Relyra uses and assert all others are rejected.

### 1.4 XML-before-safety — ordering rule

**Severity:** `Critical`
**Phase:** 2 (protocol entry points), enforced via Credo + `boundary`
**What goes wrong:** Even with a hardened parser, developer writes `extract_issuer/1` using a naive XPath before calling the hardened parser, or extracts the RelayState from form params before size-limiting, or decodes base64 without size pre-check. Signature verification comes last; the damage is already done.
**Why it happens:** Natural code flow is "decode → look at shape → decide what to verify." The library must invert this: "size-check → parse-hardened → verify → bind → consume."
**Warning signs:**
- `Relyra.Protocol.Response.consume/3` has more than three distinct phases and any of them run before `verify_and_select_signed_node/2`
- Any function named `peek_*`, `extract_*`, `get_*` called on XML before `parse_hardened/2`
- `Logger` call in the parse path receives variables whose provenance includes the raw input
**Prevention:**
- `Relyra.Protocol.Response.consume/3` has a documented, single ordered pipeline (in `CONVENTIONS.md` §"SAML validation ordering"): `decode_base64` → `size_check_pre` → `inflate_maybe` → `size_check_post` → `parse_hardened` → `select_signed_node` → `verify_signature` → `extract_assertion_from_signed_node` → `validate_conditions` → `validate_replay` → `map_principal`. Steps cannot be reordered.
- Doc-contract test: `test/conventions/validation_ordering_test.exs` exercises the pipeline order by mocking each stage and asserting step N is only called if step N-1 returned `:ok`.
- Error atom `:out_of_order_validation` reserved — any internal reordering raises this immediately, never a silent pass.

### 1.5 RelayState open redirects / login confusion

**Severity:** `Critical`
**Phase:** 4 (Plug runtime + router macro)
**What goes wrong:** RelayState is a round-trip-through-IdP string. If Relyra redirects to `RelayState` verbatim after login, attacker sends victim through a crafted IdP-initiated login whose `RelayState = https://phishing.example`. Post-login, victim is redirected to phishing site while already authenticated in the real app — an open redirect AND a login-confusion primitive.
**Why it happens:** RelayState is documented as "a value the SP can use to remember post-login destination." Natural read is "put the return URL there."
**Warning signs:**
- Any RelayState value appears as `http://...` or `https://...` in fixtures or tests
- `Plug.Conn.put_session(conn, :return_to, relay_state)` without tenant/server-side resolution
- RelayState length > 32 bytes in production code (opaque handles are short)
- `redirect/2` called with a value that traces back to `conn.body_params["RelayState"]`
**Prevention:**
- RelayState is an opaque server-side token `"rs_" <> 24_char_id`. `Relyra.RelayStateStore.put({return_to, tenant_id, request_id, expires_at})` returns the token; `Relyra.RelayStateStore.consume(token)` atomically returns `{return_to, tenant_id, ...}` or `{:error, :unknown_relay_state}`.
- `return_to` at put-time is validated: must be a same-origin path relative URL, never a scheme+host.
- Plug runtime refuses to redirect to any value that is not the output of a successful `RelayStateStore.consume/1`.
- Error atom `:invalid_relay_state` for format failures, `:unknown_relay_state` for not-found, `:expired_relay_state` for TTL exhaustion.
- Custom Credo check `Relyra.Credo.Check.NoRawRelayStateRedirect` forbids `redirect(conn, to: body_params["RelayState"])` patterns.
- Brand book §15 microcopy: "This RelayState value is not allowed. Relyra only redirects to destinations created by the server-side relay store."

### 1.6 IdP-initiated SSO as default

**Severity:** `High`
**Phase:** Deferred to v0.4; in v0.1 the pitfall is "accidentally allowing it"
**What goes wrong:** IdP-initiated flow lacks SP-created login intent: no `InResponseTo`, no request ID to bind replay to, no client-origin CSRF protection. Attacker coerces victim through an IdP dashboard tile pointing at a forged or replayed assertion and the SP cannot tell it wasn't the victim's idea. OWASP calls this out explicitly.
**Why it happens:** Enterprise IdPs (Okta dashboard, Entra portal) make IdP-initiated visually prominent; users demand it. Easiest implementation accepts unsolicited responses at ACS.
**Warning signs:**
- `consume_response/3` accepts a response when `InResponseTo` is missing AND `allow_idp_initiated?` is not explicitly checked
- Tests pass without setting `allow_idp_initiated?: true` on a connection fixture
- Any code path allows IdP-initiated without auditing it
**Prevention:**
- v0.1: reject `:in_response_to_missing` always. IdP-initiated is not supported in v0.1 — period — documented in scope-first README.
- v0.4 implementation: `Relyra.Connection.allow_idp_initiated?: false` default. Enabling the flag requires reason + audit-event emission on every login.
- Fixture: `idp_initiated_missing_in_response_to.xml` must be rejected with `:in_response_to_missing` in v0.1.
- Brand book §14.5 copy for admin UI (v0.3): unsafe option panel explicitly calls out "SP cannot verify a request ID for this flow."

### 1.7 Local ETS replay store in clustered production

**Severity:** `Critical`
**Phase:** 3 (stores + replay behaviours)
**What goes wrong:** ETS is a single-node in-memory store. Distributed Phoenix deployment with `N` nodes behind a load balancer: attacker replays a consumed assertion, hits a different node, ETS says "never seen," login succeeds. No errors, no logs, silent bypass.
**Why it happens:** ETS is the easiest default — shows up in demos, tutorials, and `mix test` green without any setup.
**Warning signs:**
- `Relyra.ReplayStore.ETS` loaded at production startup
- No Ecto-backed default in `mix relyra.install`
- No deployment-time guard fires when `Mix.env() == :prod`
**Prevention:**
- `Relyra.ReplayStore` is a behaviour. Default production adapter is `Relyra.ReplayStore.Ecto`. ETS adapter exists but has module-level `@moduledoc false` and a `child_spec/1` that emits `Logger.warning/1` at startup if `Mix.env() == :prod` *and* raises `Relyra.Error{type: :ets_replay_in_production}` unless explicitly overridden with `unsafe_allow_ets_in_prod: true` in config.
- `mix relyra.install` generates the Ecto adapter config, never ETS, in the `prod.exs` template.
- Integration test `test/integration/distributed_replay_test.exs` spins up two BEAM nodes and asserts cross-node replay detection (skipped in fast lane, required in `ci.integration`).
- README "What v0.1 includes" explicitly says "`Relyra.ReplayStore.Ecto` is the production default; ETS is dev-only."

### 1.8 Certificate rollover as a support ticket

**Severity:** `High` (for v0.2+; v0.1 pitfall is "not designing the data model to support multiple active certs")
**Phase:** v0.2 milestone; in v0.1 the behaviour must allow multiple configured certs
**What goes wrong:** IdP rotates its signing cert on Thursday. Library has one configured cert. Friday morning 9 AM all customer logins fail; support ticket flood; team scrambles to "disable signature validation" as a hotfix, creating a bigger problem.
**Why it happens:** Most SAML SP libs model `idp_signing_cert: binary()` as a single field. Rollover requires multi-cert, metadata refresh, expiry alerts.
**Warning signs:**
- Connection config has `idp_signing_cert: String.t()` as a single-valued field
- `validate_signature/2` takes a `connection` whose shape is `%{idp_signing_cert: binary}`
- No `saml_certificates` table in the Ecto schema (v0.2)
- No telemetry event `saml.certificate.expiring`
**Prevention:**
- v0.1 connection shape: `idp_signing_certs: [binary()]` (list from day one, even if most configs have length 1). Signature verification iterates the list.
- v0.2: `saml_certificates` table with `status :: :active | :next | :retired | :expired`, `not_after` field, metadata refresh Oban job.
- v0.2: telemetry event `[:relyra, :saml, :certificate, :expiry, :check]` with `cert_days_remaining` measurement.
- v0.3: admin UI certificate rollover timeline (brand book §14.4).
- v0.1: error atom `:certificate_expired` distinct from `:invalid_signature` so operators know which problem they have.

### 1.9 Confusing NameID with email

**Severity:** `High`
**Phase:** 5 (identity mapping)
**What goes wrong:** Library treats `<saml:NameID>` as "user's email." Microsoft Entra can issue persistent, emailAddress, unspecified, transient, or Windows-domain-qualified NameIDs depending on request/configuration. Transient NameID changes every login; persistent NameID is opaque and stable but not an email; emailAddress format is an email; unspecified is whatever the IdP felt like. Using NameID as email collapses users, corrupts audit logs, and creates account-takeover via NameID format flip.
**Why it happens:** Okta demo config often uses `emailAddress` format and the email IS the NameID. Copy-paste that config, the library "just works," nobody thinks about Entra.
**Warning signs:**
- `UserMapper.map/2` implementations in guides read `principal.name_id` as the email directly
- No test with `NameID Format=persistent` + separate `<saml:AttributeStatement>` containing the email
- No documentation of the five NameID format possibilities
**Prevention:**
- `%Relyra.Principal{}` struct has separate fields: `name_id :: String.t()`, `name_id_format :: atom()`, `attributes :: %{String.t() => [String.t()]}`. No `email` field on the principal — email is an attribute that must be explicitly looked up.
- `UserMapper` behaviour docs show the transient/persistent/emailAddress switch as the canonical first example.
- Getting-Started guide forces the user to `fetch_attribute(principal, "email")` rather than `principal.name_id` for email-based lookup.
- Error atom `:missing_required_attribute` when the mapper asks for an attribute that isn't present.
- Provider guides (Okta, Entra, Google) spell out which NameID format each uses by default and how to request otherwise.

### 1.10 Treating attributes as authorization without contract

**Severity:** `High`
**Phase:** 5 (identity mapping + group mapping)
**What goes wrong:** App reads `<saml:Attribute Name="groups">` and grants `:admin` role to anyone in the `"admin"` group. IdP admin creates a group called `"admin"` for their internal Slack usage — unrelated. Authz bypass. OASIS: attribute-based authz requires prior agreement on names and values.
**Why it happens:** Attributes look like a free lunch: "the IdP sends us the user's groups, just use them."
**Warning signs:**
- `UserMapper.map/2` guide examples show `if "admin" in groups, do: :admin_role`
- No `saml_group_mappings` table (v0.2) or explicit mapping config in v0.1
- Provisioning grants roles based on attribute values without a mapping table
**Prevention:**
- `Relyra.UserMapper` behaviour docs explicitly say: "SAML attributes are inputs to mapping, never outputs of authorization. Map groups to local roles through an explicit configured mapping."
- v0.2 introduces `saml_group_mappings` schema: `%{saml_connection_id, saml_group_value, local_role_or_group_id}` — authz is always "this connection maps this attribute value to this local role."
- Error atom `:group_mapping_failed` when incoming group value has no configured mapping.
- Brand book §22: avoid "roles automatically mapped from IdP groups" as copy; prefer "group mappings you configure explicitly."
- CONVENTIONS.md §"Attributes are inputs, not authz."

### 1.11 Over-promising SLO

**Severity:** `Medium` (the pitfall is v0.5 scope creep in v0.1)
**Phase:** v0.5 milestone; v0.1 pitfall is "don't claim to do SLO"
**What goes wrong:** SLO (Single Logout) requires coordination across: every browser session at the SP, every browser session at the IdP, every other SP in the IdP's circle of trust, front-channel vs back-channel bindings, IdP-initiated vs SP-initiated logout, and the reality that browsers close/crash. `passport-saml` explicitly warns IdP-initiated SLO is not fully supported. Any library that claims "full SLO" is misleading.
**Why it happens:** "Logout" sounds like the inverse of login; naive model is symmetric.
**Warning signs:**
- `Relyra.start_logout/3` appears in v0.1 API
- README lists SLO as a v0.1 feature
- No "partial by provider" disclaimer in v0.5 docs
**Prevention:**
- v0.1 README "What v0.1 does NOT include" lists Single Logout explicitly.
- v0.5 ships SLO behind explicit per-connection opt-in, with per-provider support matrix (Okta: ✓ SP-initiated, partial IdP-initiated; Entra: ✓ SP-initiated, ✗ back-channel; etc.).
- v0.5 docs have a "Known limitations" section naming exactly which SLO scenarios are not supported.
- Brand book §15: never use success copy like "User fully logged out across all systems" — only "Logout request sent; session cleared on this service."

### 1.12 Clock-skew defaults too loose or too tight

**Severity:** `High`
**Phase:** 2 (protocol validation)
**What goes wrong:** Too tight (0s): every login behind a load balancer with slight NTP drift fails with `:assertion_expired`. Too loose (30 min): replayed assertion from 29 minutes ago still succeeds. Enterprise SaaS usually sees 30-120s of real drift.
**Why it happens:** Default picked without survey; either engineer's local dev has perfect clock sync (chose 0s) or engineer had one bad debug session and cranked it up.
**Warning signs:**
- Hard-coded `@clock_skew_seconds` with no config override
- Default outside the [30, 180] second range
- No test at the exact skew boundary (NotBefore - skew - 1, NotOnOrAfter + skew + 1)
**Prevention:**
- Default `clock_skew_seconds: 120`. Configurable per-connection.
- Max configurable skew: 600 seconds (10 min). Anything over raises a config error with atom `:clock_skew_exceeds_maximum`.
- Property test: `StreamData` over `skew ∈ [0, 600]` and `drift ∈ [-skew-5, skew+5]`, assert exactly when valid/invalid.
- Telemetry: `clock_skew_seconds` measurement emitted on every assertion validation so operators can see their real drift distribution.
- Error atoms distinct: `:assertion_expired` (past NotOnOrAfter + skew), `:assertion_not_yet_valid` (before NotBefore - skew), `:clock_skew_exceeded` (the skew itself is out of configured range — config bug, not assertion bug).

### 1.13 Missing `InResponseTo` binding in SP-initiated flow

**Severity:** `Critical`
**Phase:** 2 (protocol validation) + Phase 3 (request store)
**What goes wrong:** SP sends `AuthnRequest` with `ID="_abc123"`. Response from IdP carries `InResponseTo="_abc123"`. If SP doesn't check that `_abc123` matches a pending request in its RequestStore, attacker replays an old valid response, or forwards a response intended for another SP, or races two concurrent login attempts. SP has no proof the response corresponds to its own login intent.
**Why it happens:** Simple implementations skip the request-side store entirely; "we'll validate the signature, that's enough." It isn't — signature says the IdP signed it, not that this app asked for it.
**Warning signs:**
- No `Relyra.RequestStore` behaviour implementation in v0.1
- `AuthnRequest` IDs not stored at `start_login/3`
- `consume_response/3` validates signature but does not `RequestStore.pop(in_response_to)`
- No test for mismatched `InResponseTo`
**Prevention:**
- `Relyra.RequestStore.put/3` called at `start_login/3` with `{request_id, %{tenant_id, expires_at, ...}}`.
- `Relyra.RequestStore.pop/1` called atomically in `consume_response/3` — the response is rejected if the request ID is not present, expired, or bound to a different tenant.
- Error atoms: `:in_response_to_missing` (no InResponseTo in SP-initiated), `:in_response_to_mismatch` (InResponseTo present but doesn't match a pending request).
- Fixture `missing_in_response_to.xml` and `stale_in_response_to.xml` in security corpus.
- Ecto-backed default store. ETS dev-only with the same loud-warning pattern as ReplayStore (§1.7).

### 1.14 Accepting `KeyInfo` from the document instead of configured certs

**Severity:** `Critical`
**Phase:** 2 (signature verification)
**What goes wrong:** `<ds:Signature>` carries `<ds:KeyInfo>` with a `<ds:X509Certificate>`. Attacker signs forged assertion with THEIR cert, places their cert in `KeyInfo`. Library verifies signature using the cert from `KeyInfo` — it validates. Trust root is attacker-controlled.
**Why it happens:** XMLDSig spec allows KeyInfo as a convenience; many general-purpose XMLDSig libraries use it by default; SAML-specific libraries must override. OWASP calls this out.
**Warning signs:**
- `:xmerl_dsig` or equivalent called without the "trusted certs" argument
- `KeyInfo` parsing code anywhere in the signature path
- No test with a well-formed signature using an attacker-generated cert embedded in KeyInfo
**Prevention:**
- `Relyra.Security.Signature.verify/3` API shape: `verify(canonical_bytes, signature_value, [trusted_cert]) :: :ok | {:error, :no_matching_trusted_cert}`. The trusted cert list is the ONLY input to verification; KeyInfo is ignored.
- If code needs to inspect KeyInfo (for cert-pinning UX only, never for trust), the function is `Relyra.Security.Signature.inspect_key_info/1` and is documented as "this is the attacker's claim about what cert they used — never trust it."
- Fixture `key_info_attacker_cert.xml` in security corpus; asserts `:no_matching_trusted_cert`.
- Error atom `:untrusted_certificate` when verify fails because no configured cert matched.

### 1.15 Multiple assertions in one response — ambiguous consumption

**Severity:** `Critical`
**Phase:** 2 (assertion selection)
**What goes wrong:** SAML spec allows multiple `<saml:Assertion>` elements in a `<samlp:Response>`. Library picks "the first one" — attacker places a signed benign assertion first, forged admin assertion second, and the wrapping behaviour differs based on which one the code reads attributes from. Even without wrapping, two assertions create ambiguity about which principal logged in.
**Why it happens:** "First Assertion found" is the easiest XPath; spec doesn't require exactly one.
**Warning signs:**
- Code pattern `Enum.find/2`, `hd/1`, or `[first | _]` applied to a list of assertions
- No test with two assertions in one response
- No error atom for "multiple assertions"
**Prevention:**
- `Relyra.Security.Signature.select_signed_assertion/2` returns `{:error, :multiple_assertions}` if more than one assertion exists, regardless of which is signed. Relyra requires exactly one.
- Future-proofing: if a v2+ profile requires multi-assertion, add it behind an explicit `allow_multiple_assertions?: false` flag with its own audit.
- Fixture `two_assertions_first_signed_second_forged.xml` asserts `:multiple_assertions` rejection.

### 1.16 Duplicate XML IDs — reject

**Severity:** `Critical`
**Phase:** 2 (XML parse layer)
**What goes wrong:** `ID` attributes in XML DSig reference resolution must be unique. Attacker places two `<Assertion ID="abc">` nodes with the same ID; signature `<Reference URI="#abc">` resolves to one parser's choice, attribute extraction to another's. This is the enabling primitive for most signature-wrapping variants.
**Why it happens:** XML parsers don't enforce ID uniqueness by default; DTD/schema validation does, but Relyra disables DTDs (correctly!) for XXE reasons.
**Warning signs:**
- No explicit duplicate-ID check in the parse pipeline
- No fixture with two elements carrying the same ID
- Signature reference resolution uses `xpath //*[@ID='abc']` (returns list) and picks first
**Prevention:**
- `Relyra.Security.XML.parse_hardened/2` performs its own ID-uniqueness pass after parsing. Returns `{:error, :duplicate_xml_id}` on collision.
- Fixture `duplicate_id_signed_and_forged.xml` in security corpus.
- Error atom `:duplicate_xml_id` in the taxonomy.

### 1.17 `Destination` mismatch — receiving response at wrong ACS URL

**Severity:** `High`
**Phase:** 2 (protocol validation)
**What goes wrong:** Response's `Destination` attribute says `https://staging.example.com/sso/acs` but it arrived at `https://app.example.com/sso/acs`. Library accepts it. Now attacker replays a staging-intended assertion at production.
**Why it happens:** Dev/staging/prod share IdP configs; destination field is sometimes omitted; developers assume "it arrived here, so it's for here."
**Warning signs:**
- No `Destination` validation in `validate_conditions/1`
- Tests run with `Destination` blank or set to `http://localhost:4000`
- Error atom `:destination_mismatch` is missing from the taxonomy
**Prevention:**
- `Relyra.Connection` has `sp_acs_url :: String.t()`. `validate_conditions/1` asserts `response.destination == connection.sp_acs_url` (exact match, including trailing slash and scheme).
- Error atom `:destination_mismatch` with details `%{expected: url, received: url}`.
- Fixture `destination_staging.xml` received at production ACS must reject.
- Brand book §14.3 error microcopy: "The response's Destination was {received}; Relyra expects {expected}."

### 1.18 `Audience` not enforced

**Severity:** `Critical`
**Phase:** 2 (protocol validation)
**What goes wrong:** `<saml:AudienceRestriction><saml:Audience>https://other-saas.example</saml:Audience></saml:AudienceRestriction>`. Library doesn't check. Attacker replays an assertion the IdP issued for a different SaaS app at Relyra's app — principal authenticated, but for the wrong service.
**Why it happens:** Audience check is easy to forget; signature check is already done; "looks signed, looks fresh, let's go."
**Warning signs:**
- `validate_conditions/1` checks NotBefore/NotOnOrAfter but not `<AudienceRestriction>`
- No test where signed-but-audience-mismatched assertion is rejected
- Error atom `:invalid_audience` missing or unused
**Prevention:**
- `validate_conditions/1` REQUIRES `connection.sp_entity_id ∈ assertion.audiences`. Missing AudienceRestriction → `:invalid_audience` (not a pass).
- Fixture `audience_for_other_sp.xml` in security corpus.
- Error atom `:invalid_audience`.

### 1.19 Status code `AuthnFailed` silently treated as success

**Severity:** `High`
**Phase:** 2 (protocol validation)
**What goes wrong:** Response has `<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Requester"/>` (or `AuthnFailed`, `NoAuthnContext`, etc.) and the library proceeds to read the assertion anyway. The assertion may not exist, or may be stale from a prior successful login cached by the IdP. Either way, the login isn't actually authorized.
**Why it happens:** Status-check code is separate from assertion-processing code; if status is ignored and assertion happens to parse, it "works."
**Warning signs:**
- `consume_response/3` reads `<saml:Assertion>` before checking `<samlp:Status>`
- Tests don't include a fixture with `Status != Success`
- No `:unsupported_status` error atom
**Prevention:**
- Validation ordering (§1.4) puts status check after signature verification but before assertion extraction. Non-success statuses immediately return `{:error, :authn_failed | :unsupported_status | :requester_error | :responder_error}`.
- Fixtures for each SAML 2.0 top-level StatusCode: `status_authn_failed.xml`, `status_requester.xml`, `status_responder.xml`, `status_no_authn_context.xml`, all asserted to reject.

### 1.20 Compressed/base64 oversized payload (decompression bomb)

**Severity:** `High`
**Phase:** 1 (XML security ADR) + Phase 2 (decode layer)
**What goes wrong:** Redirect binding deflates the SAML message. Attacker sends a 1 KB gzip-bomb that inflates to 4 GB; Relyra's process heap explodes; node crash; DoS. Pre-base64 size check is too early (base64-expanded), post-base64 is too early (still compressed), post-inflate is too late (already allocated).
**Why it happens:** Size limits are a checklist item easily forgotten when the focus is signature correctness.
**Warning signs:**
- No `@max_saml_response_bytes` or `@max_inflated_bytes` module attributes
- `:zlib.uncompress/1` or equivalent called on attacker input without a bounded sink
- No DoS-fixture in the security corpus (a zip-bomb payload)
**Prevention:**
- Three bounded limits: `:max_raw_bytes` (pre-base64, default 256 KB), `:max_base64_bytes` (post-base64, default 192 KB), `:max_inflated_bytes` (post-inflate, default 1 MB). All configurable.
- Inflate uses streaming `:zlib.inflateInit` with per-chunk size accumulator; bails with `:payload_too_large` the instant `max_inflated_bytes` is exceeded — never allocates the full buffer.
- Fixture `zip_bomb.xml` in security corpus. Assert `:payload_too_large` rejection.
- Error atoms: `:payload_too_large`, `:malformed_base64`, `:inflated_payload_too_large`.

### 1.21 SHA-1 accepted by default or legacy escape hatch never expires

**Severity:** `Critical` (accept-by-default) / `Medium` (never-expiring escape hatch)
**Phase:** 2 (algorithm policy) + Phase 3 (audit)
**What goes wrong:** SHA-1 is cryptographically broken for collision resistance; accepting it means attacker can collide a benign assertion against a forged one. Even worse: library adds an escape hatch `allow_sha1: true` and never forces a re-review, so legacy IdPs carry SHA-1 forever.
**Why it happens:** ADFS and older Keycloak deployments still issue SHA-1 signatures. Easier to accept than to force a migration.
**Warning signs:**
- `Relyra.Security.AlgorithmPolicy` default includes `:rsa_sha1` or `:sha1`
- Escape hatch is a boolean `allow_sha1?: true` with no expiry
- No audit event fired when SHA-1 is actually used
**Prevention:**
- Default policy: `allowed_signature_algorithms: [:rsa_sha256, :rsa_sha384, :rsa_sha512, :ecdsa_sha256, :ecdsa_sha384, :ecdsa_sha512]`, `reject_sha1?: true`.
- Escape hatch shape: `legacy_algorithm_policy: [allow_sha1_until: ~D[2026-12-31], reason: "Customer ADFS migration", audit: true]`. Struct-level validation: `allow_sha1_until` is required and must be a `Date` in the future at config time.
- Date in the past at login time → error `:deprecated_algorithm` with detail `"SHA-1 escape hatch expired YYYY-MM-DD"`.
- Audit event `saml.unsafe_option.used` emitted on every login that exercised the escape hatch.
- Brand book §14.5 admin UI panel shows an explicit "SHA-1 allowed until YYYY-MM-DD — see audit log."
- Error atom `:deprecated_algorithm`.

### 1.22 `Issuer` not enforced

**Severity:** `High`
**Phase:** 2 (protocol validation)
**What goes wrong:** Response and assertion can carry different `<saml:Issuer>` values; library validates signature with one trusted cert but doesn't check the issuer matches the configured IdP entity ID. Attacker with a signed assertion from IdP A replays at a Relyra app configured to trust IdP B (or any IdP Relyra has ever trusted).
**Why it happens:** Signature check feels like it already proves issuer; it doesn't — it proves the cert signed it, which could be any IdP whose cert was ever added.
**Warning signs:**
- `validate_conditions/1` does not compare `assertion.issuer` to `connection.idp_entity_id`
- No test with a signed assertion from a different (but also configured) IdP
**Prevention:**
- `validate_conditions/1` enforces `assertion.issuer == connection.idp_entity_id` (exact string match).
- Multi-tenant case: `ConnectionResolver.resolve/1` returns exactly one connection; that connection's `idp_entity_id` is the only permitted issuer.
- Error atom `:issuer_mismatch` with details `%{expected, received}`.
- Fixture `signed_by_other_idp_cert_issuer_mismatch.xml`.

### 1.23 `Recipient` (SubjectConfirmationData) not enforced

**Severity:** `High`
**Phase:** 2 (protocol validation)
**What goes wrong:** `<saml:SubjectConfirmationData Recipient="...">` exists to prove the assertion was created specifically for this SP's ACS URL. Skipping the check enables the same replay-to-wrong-endpoint attacks as destination mismatch (§1.17), but at a finer grain (per-subject-confirmation, not per-response).
**Why it happens:** Often confused with `Destination`; some libs check one but not the other.
**Warning signs:**
- `SubjectConfirmationData.recipient` not read
- No `:recipient_mismatch` error atom
**Prevention:**
- `validate_subject_confirmation/2` checks `recipient == connection.sp_acs_url`, `not_on_or_after` is in the future, `in_response_to` matches (SP-initiated only), `method == urn:oasis:names:tc:SAML:2.0:cm:bearer`.
- Error atom `:recipient_mismatch`.

### 1.24 Encrypted assertions mishandled (v1.0 concern but v0.1 pitfall: claiming to support them)

**Severity:** `Medium` (v0.1 pitfall is scope creep / false claims)
**Phase:** v1.0 milestone; v0.1 pitfall is "don't claim to decrypt"
**What goes wrong:** `<saml:EncryptedAssertion>` requires XML-Enc + SP's private key. Botched implementations (a) use weak KEK algorithms, (b) decrypt before verifying outer signature, (c) leak plaintext via error messages. Multiple real-world CVEs.
**Why it happens:** XML encryption is as error-prone as XML signature; adding it is tempting because "enterprise customers expect it."
**Warning signs:**
- Any `EncryptedAssertion` code path in v0.1
- README claims "encrypted assertions supported"
**Prevention:**
- v0.1 README explicitly excludes encrypted assertions.
- v0.1: presence of `<saml:EncryptedAssertion>` → `{:error, :encrypted_assertions_not_supported}`. Clear, not a silent pass.
- v1.0 scope: XML-Enc support requires the same ADR rigor as the v0.1 XMLDSig ADR. Verify outer signature first, then decrypt, then verify inner signature (if present).

### 1.25 Metadata trust — trusting IdP metadata signed with self-signed cert, or not signed at all

**Severity:** `High`
**Phase:** v0.2 milestone; v0.1 pitfall is "manual cert entry only — no metadata URL fetch in v0.1"
**What goes wrong:** Metadata XML contains the IdP's signing cert. If library fetches `https://idp.customer.example/metadata` over plain HTTP, or trusts TLS but doesn't verify the metadata signature, attacker with network position injects their own cert into metadata, all future responses are validated against attacker's cert.
**Why it happens:** "Just HTTPS, that's enough" (no — MITM in corp networks with internal CAs happens). "Metadata is read-once at config time" — not if auto-refresh is on.
**Warning signs:**
- v0.2 metadata fetch without HTTPS + cert pinning options
- No signature-on-metadata check even when IdP supports it
- Surprising issuer/entity-ID changes in metadata silently accepted
**Prevention:**
- v0.1: metadata import is manual paste only — no URL fetch. Avoids the pitfall by eliminating the surface.
- v0.2: metadata URL fetch requires HTTPS; cert pinning optional; signed-metadata validation preferred when IdP supports it.
- v0.2: surprising issuer/entity-ID changes require explicit admin confirmation in the LiveView UI (v0.3) before new certs become trusted. Error atom `:metadata_issuer_changed_unexpectedly`.
- v0.2: telemetry event `saml.metadata.refresh.failed` with reason.

### 1.26 Fake-IdP test-support leaks into production (our own footgun)

**Severity:** `High`
**Phase:** v0.1 milestone — design it to be impossible to load in prod
**What goes wrong:** `Relyra.TestSupport.FakeIdP` is a dev/CI convenience that issues signed assertions with a known keypair. If any adopter accidentally loads it in prod (copy-paste from a test file; mix env misconfig), an attacker who knows Relyra's dev keypair (it's open source!) can forge assertions against the production SP.
**Why it happens:** Test-support modules live in `lib/` or are imported carelessly; dev keys end up in committed configs; mix env checks are forgotten.
**Warning signs:**
- `Relyra.TestSupport.*` modules compiled under `Mix.env() == :prod`
- Dev keys hardcoded in `lib/` paths
- `FakeIdP` child_spec can be started in a prod release
**Prevention:**
- `Relyra.TestSupport.*` under `test/support/` only, NOT `lib/`. Loaded via `elixirc_paths(:test) ++ ["test/support"]`.
- `FakeIdP.start_link/1` has `@compile :nowarn_prod` and raises `Relyra.Error{type: :fake_idp_in_production}` if `Mix.env() == :prod`.
- `package.files` in `mix.exs` EXPLICITLY excludes `test/` — the Hex tarball cannot contain FakeIdP.
- Post-publish parity check (§3.3) asserts the Hex tarball does not contain any `test_support`/`FakeIdP` module.
- Custom Credo check `Relyra.Credo.Check.NoTestSupportInLib` forbids `Relyra.TestSupport.*` from being referenced under `lib/` outside modules themselves tagged `@moduledoc false` and documented as dev-only.

---

## §2 — Elixir OSS library footguns (17 pitfalls)

Pitfalls generic to Elixir libraries, each validated against the sibling-repo DNA (`sigra`, `lockspire`, `mailglass`, `threadline`, `rulestead`, `chimeway`, `lattice_stripe`, `scrypath`, `accrue`, `kiln`).

### 2.1 `package.files` as implicit whitelist — accidentally shipping `test/`, `.planning/`, `prompts/`

**Severity:** `Critical` (test fixtures may contain real IdP assertions; `.planning/` may contain vulnerability drafts)
**Phase:** ongoing (Phase 0 setup, re-verified every release)
**What goes wrong:** `mix.exs` omits `files:` whitelist; Hex includes the whole repo by default *minus* a few exclusions. `test/fixtures/real_customer_assertion.xml` ships to Hex; `.planning/` shows the unreleased vulnerability roadmap; `prompts/` contains proprietary research.
**Warning signs:**
- No `files: ~w(...)` in `package/0`
- `mix hex.build --unpack` reveals unexpected paths
- `.planning/`, `prompts/`, or `test/` appear in the unpacked tarball
**Prevention:**
- `package/0` ALWAYS has an explicit `files:` whitelist: `~w(lib priv/templates priv/guides guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md SECURITY.md)`.
- CI lane `verify.release_parity` unpacks the built tarball and asserts path exclusions.
- Comment above the whitelist names forbidden paths: `# NEVER include: test/, .planning/, prompts/, _build/`.
- Daily drift cron (scrypath pattern) re-verifies post-publish.

### 2.2 `@version` drift (two places disagree)

**Severity:** `High`
**Phase:** ongoing
**What goes wrong:** `mix.exs` says `0.1.2`, `release-please-manifest.json` says `0.1.3`, git tag says `v0.1.2`, HexDocs rendered docs point to `v0.1.1`. Adopters are confused; HexDocs source links are broken.
**Warning signs:**
- `@version` hardcoded in multiple modules
- Manual version edits in CHANGELOG before release-please has run
- `docs: [source_ref: "main"]` instead of `"v#{@version}"`
**Prevention:**
- `@version "0.1.0"` defined ONCE as a module attribute at the top of `mix.exs`. Referenced via `@version` everywhere (docs config, release-please manifest generation script).
- `scripts/verify_tag_version.sh` (kiln pattern) runs at publish time: fails if git tag doesn't match `mix.exs`.
- Release Please manifest script generated from `@version`, not hand-edited.
- `docs: [source_ref: "v#{@version}"]` — source links point to the tag, not main.

### 2.3 `optional: true` dep forgotten in `no_warn_undefined`

**Severity:** `High`
**Phase:** ongoing (part of `qa` alias)
**What goes wrong:** `mix.exs` has `{:phoenix_live_view, "~> 1.0", optional: true}`. A downstream app without LiveView runs `mix compile --warnings-as-errors` and gets warnings about undefined modules in `Relyra.LiveAdmin.*`; their CI fails; they blame Relyra; they downgrade or switch libraries.
**Warning signs:**
- CI has no `compile --no-optional-deps --warnings-as-errors` lane
- `elixirc_options.no_warn_undefined` is empty or stale
- Adopter issues like "warnings when I add relyra" in GitHub
**Prevention:**
- Every `optional: true` dep's top-level modules listed in `elixirc_options: [no_warn_undefined: [...]]`.
- Dedicated CI lane `compile_no_optional_deps` runs `mix compile --no-optional-deps --warnings-as-errors`. Blocks merge.
- `Relyra.OptionalDeps.{Ecto, LiveView, Oban, OpenTelemetry}` gateway pattern (mailglass): each optional integration wrapped in a module with module-level `@compile {:no_warn_undefined, [...]}` + `Code.ensure_loaded?/1` guard.

### 2.4 `compile --no-optional-deps --warnings-as-errors` not run as a CI lane

**Severity:** `High`
**Phase:** ongoing (see 2.3)
**What goes wrong:** Variant of 2.3. Lane is the detection mechanism; skipping it means the problem is only detected by adopters.
**Prevention:** Lane exists from the first CI commit. See 2.3.

### 2.5 `CHANGELOG.md` drift vs release-please manifest

**Severity:** `Medium`
**Phase:** ongoing
**What goes wrong:** Manual edits to `CHANGELOG.md` happen between release-please PRs; the autogenerated section and the manual section interleave incorrectly; release notes published to GitHub diverge from `CHANGELOG.md`.
**Warning signs:** Release Please PR has manual `CHANGELOG.md` conflict markers; Hex release notes don't match the GitHub release.
**Prevention:**
- Never manually edit `CHANGELOG.md` — Release Please owns it end-to-end.
- All prose (e.g., migration notes) goes into conventional-commit message bodies, not CHANGELOG.md.
- Post-publish parity check diffs Hex release notes against CHANGELOG.md.

### 2.6 `source_ref: "main"` → HexDocs rot

**Severity:** `Medium`
**Phase:** ongoing
**What goes wrong:** HexDocs source links point at `main`; as code evolves, v0.1.0 docs links lead to v0.4.2 code; adopters land on the wrong implementation.
**Prevention:**
- `docs: [source_ref: "v#{@version}"]` (not `"main"`).
- Post-publish verification clicks a source link and asserts it returns 200 on the tag path.

### 2.7 Missing `@moduledoc false` on internal modules → users depend on them

**Severity:** `High`
**Phase:** ongoing (Credo check from Phase 0)
**What goes wrong:** `Relyra.Protocol.Internal.XmlHelpers` ships with `@moduledoc "XML helpers."`. A user imports it for their own purposes. Relyra refactors it in v0.2; user's app breaks; semver rules force Relyra into a major bump (or a botched "minor is actually major" release).
**Warning signs:** Module under `Relyra.Internal.*` or clearly-internal namespace has `@moduledoc` string instead of `false`.
**Prevention:**
- `CONVENTIONS.md` §"Public surface": public API is enumerated in one doc (lattice_stripe `api_stability.md` pattern). Every module NOT listed has `@moduledoc false`.
- Custom Credo check `Relyra.Credo.Check.InternalModuleDocsFalse` scans for modules named `*.Internal.*`, `*.Impl.*`, `*.Private.*`, or anything under `lib/relyra/security/internal/` and asserts `@moduledoc false`.
- `:boundary` compiler also enforces this — a downstream app that tries to `alias Relyra.Internal.X` gets a compile warning.

### 2.8 Telemetry event names not documented → downstream breakage when renamed

**Severity:** `High`
**Phase:** Phase 6 (telemetry catalog)
**What goes wrong:** Relyra emits `[:relyra, :saml, :response, :validate, :stop]`; adopter builds a Grafana dashboard against it; Relyra v0.2 renames to `[:relyra, :saml, :assertion, :validate, :stop]` for clarity; dashboard breaks silently.
**Warning signs:**
- No single `Relyra.Telemetry` module documenting events
- Event names scattered across modules
- No `CHANGELOG.md` entry when an event is renamed
**Prevention:**
- `Relyra.Telemetry` module is the single source of truth: lists all event names, measurements, metadata schemas, and stability status. `@moduledoc` reads "This module's public event contracts are part of the semver-stable public API."
- Event renames are breaking changes — require major version bump.
- `test/telemetry_contract_test.exs` asserts every documented event is actually emitted by exercise of the named code path.

### 2.9 `package.links` missing `Changelog`

**Severity:** `Low`
**Phase:** ongoing
**What goes wrong:** Lattice_stripe insight: most-clicked Hex package link is "Changelog." Omitting it is the worst package-UX mistake.
**Prevention:** `links: %{"GitHub" => ..., "HexDocs" => ..., "Changelog" => ..., "Security" => ...}` always.

### 2.10 Optional deps behind runtime `Code.ensure_loaded?` instead of `optional: true`

**Severity:** `Medium`
**Phase:** Phase 0 setup
**What goes wrong:** Developer thinks `Code.ensure_loaded?(Phoenix.LiveView)` replaces `optional: true` in `mix.exs`. It doesn't — `mix.exs` dep declarations drive Hex dependency resolution. Downstream apps get Phoenix.LiveView force-installed when they wanted headless Relyra.
**Prevention:**
- Every optional integration is BOTH `optional: true` in `mix.exs` AND wrapped in `Code.ensure_loaded?/1` gateway. Both layers are required.
- `OptionalDeps.*` modules document the dual pattern.

### 2.11 Release Please + conventional commits drift

**Severity:** `Medium`
**Phase:** ongoing
**What goes wrong:** A feature-visible bugfix gets committed as `fix:` (→ patch bump) when it should have been `feat:` (→ minor). Or a breaking change goes out as `feat:` without `!` or `BREAKING CHANGE:` footer. Adopters upgrade and break.
**Prevention:**
- PR-title semantic-commit gate (lattice_stripe pattern): CI check parses PR title and asserts conventional-commit format.
- `CONTRIBUTING.md` explains the rules and maps common mistakes to correct types.
- Monthly maintainer audit: read the last month's commits, spot-check bumps.

### 2.12 Post-publish parity failure — git tag ≠ Hex tarball

**Severity:** `High`
**Phase:** ongoing
**What goes wrong:** `git archive v0.1.0` produces a tree; `mix hex.build` produces a tarball; they diverge because `package.files` whitelist is inconsistent, or a dirty workspace was published, or a post-release hotfix was published without a tag.
**Prevention:**
- `verify.release_parity` script (scrypath pattern) downloads the Hex tarball, compares against `git archive`, asserts identical content modulo known-benign differences (`.formatter.exs` et al. are allowed).
- Daily drift cron opens a rolling GitHub issue if parity drifts.
- Publish is gated on `verify.workspace_clean` — no uncommitted changes at publish time.

### 2.13 Dialyzer PLT path not cached correctly — CI time explodes

**Severity:** `Low`
**Phase:** Phase 0 (CI setup)
**What goes wrong:** Dialyzer PLT rebuilds from scratch every CI run, adding 5-10 minutes; developers skip Dialyzer locally; Dialyzer errors accumulate; eventually someone disables Dialyzer "temporarily."
**Prevention:**
- PLT cached at `priv/plts/dialyzer.plt` (kiln pattern).
- GitHub Actions cache key = `mix.lock` hash.
- Two-step restore: cache restore → build-if-missing → cache save.
- `mix dialyzer` in the `qa` alias so it runs for every commit, never delayed.

### 2.14 `:boundary` compiler not configured — protocol core depends on Phoenix and nobody notices

**Severity:** `High`
**Phase:** Phase 0 + Phase 2 enforcement
**What goes wrong:** `Relyra.Protocol.Response` imports `Plug.Conn` for convenience. Now the protocol core (which should be pure SAML) has a hard dep on Plug. Headless users can't use Relyra without a web stack; test isolation breaks.
**Prevention:**
- `boundary` compiler configured from v0.1:
  ```elixir
  use Boundary, deps: [], exports: [...]  # in Relyra.Protocol
  use Boundary, deps: [Relyra.Protocol, Plug], exports: [...]  # in Relyra.Phoenix
  ```
- Bounded contexts (PROJECT.md §"Bounded contexts"): Protocol Core ↔ Trust ↔ Connection ↔ Phoenix Runtime ↔ Identity Mapping ↔ Observability. Each is a `:boundary` module.
- CI `qa` alias runs `mix compile --force --warnings-as-errors` which surfaces boundary violations.

### 2.15 `docs --warnings-as-errors` missing from CI

**Severity:** `Medium`
**Phase:** ongoing
**What goes wrong:** Doc references (`` `Relyra.Foo.bar/2` ``) rot as functions are renamed; HexDocs shows broken links; readers lose trust.
**Prevention:** `qa` alias includes `mix docs --warnings-as-errors`. Every PR runs it.

### 2.16 Golden-diff installer test not run on paths that change templates

**Severity:** `High`
**Phase:** Phase 0 (installer-path-gate CI lane)
**What goes wrong:** Developer tweaks `priv/templates/relyra.install/config.ex.eex`; fast CI passes because the expensive installer test is in the integration lane; the installer now emits a config that fails on fresh `phx.new`; released broken.
**Prevention:**
- Installer-path-gate CI lane (sigra pattern): shell detects `git diff --name-only origin/${base}...HEAD | grep -qE '^priv/templates/relyra\.install/|^lib/relyra/install/'`; if match, runs the installer golden-diff test harness.
- Golden diff: `test/fixtures/install_golden/{tree,STDOUT.txt}` regenerated only with explicit `mix relyra.regenerate_golden` command + human review.
- Harness: fresh `phx.new` + `mix relyra.install` produces byte-identical tree + stdout.

### 2.17 `mix.exs` macros that break `mix hex.build`

**Severity:** `Medium`
**Phase:** Phase 0
**What goes wrong:** Some dep resolution logic in `mix.exs` depends on runtime-computed values; `mix hex.build` in a sandbox (no network, no side deps) fails; publish breaks.
**Prevention:**
- `mix.exs` is pure data. No `System.get_env/1` without fallback, no conditional deps based on runtime, no `File.read!/1`.
- CI `verify.hex_build` lane runs `mix hex.build --unpack` in an isolated env.

---

## §3 — Security-sensitive OSS footguns (11 pitfalls)

Pitfalls specific to libraries that sit on the security boundary.

### 3.1 Public GitHub issue with reproduction steps before private advisory

**Severity:** `Critical`
**Phase:** ongoing (Phase 0 sets up `SECURITY.md`)
**What goes wrong:** Contributor finds a signature-wrapping bypass; opens public issue titled "SAML response with duplicated assertion bypasses auth" with a PoC XML attached. Public issue is indexed by attackers within minutes; every Relyra adopter is vulnerable until patched; zero-day window is open.
**Warning signs:**
- No `SECURITY.md` at repo root
- No GitHub Security Advisories (private drafts) enabled
- README does not link to security disclosure process
- Recent issues with "CVE", "security", "bypass", "vulnerability" in titles
**Prevention:**
- `SECURITY.md` from day one (before any code) with: supported versions table, private-advisory link (`https://github.com/szTheory/relyra/security/advisories/new`), GPG key or email for out-of-band contact, 90-day disclosure window commitment, what counts as a vulnerability vs a feature request.
- README "Security" section links to `SECURITY.md` prominently.
- GitHub Security tab enabled; private vulnerability reporting turned on.
- Issue template for public issues has a checkbox "This is not a security issue — security issues go through SECURITY.md" that must be checked.
- Friendly triage reply template: "Thanks for the report. Because this may affect authentication safety, please send details through the private security advisory process rather than this public issue." (brand book §23 copy).

### 3.2 Security fix shipped without a permanent regression fixture

**Severity:** `Critical`
**Phase:** ongoing (mandatory for every security fix)
**What goes wrong:** Bob fixes XSW-variant-5 in v0.1.4; adds a unit test in the PR; unit test later gets deleted during a refactor because "it was covered by general signature tests"; v0.3.0 regresses on XSW-variant-5; the same CVE ships twice.
**Prevention:**
- Policy: every security fix MUST add a fixture to `test/fixtures/security/<cve_id>_<short_slug>.xml` (or `.eex`/generator). Fixtures live forever. Deletion requires a `PRESERVED_REMOVAL_REASON.md` entry.
- CI `ci.security` lane replays the entire `test/fixtures/security/` corpus against every build. If a fixture goes missing, CI fails.
- `CONTRIBUTING.md` security section: "every security fix = permanent fixture; no exceptions."
- `CHANGELOG.md` security entries list fixture paths.

### 3.3 Yanking a Hex version after a security release — how to do it right, what to communicate

**Severity:** `High`
**Phase:** ongoing
**What goes wrong:** Bad release ships v0.1.3 with a security regression. Team panics, yanks v0.1.3 via `mix hex.retire`. Adopters auto-updating to `~> 0.1.3` suddenly can't build. No communication about why.
**Prevention:**
- `MAINTAINING.md` has a "Yanking a release" runbook:
  1. Ship v0.1.4 with the fix FIRST.
  2. Run `mix hex.retire relyra 0.1.3 security "CVE-2026-XXXXX — upgrade to 0.1.4 immediately."` with a concrete reason visible in Hex UI.
  3. File a GitHub Security Advisory referencing the retired version.
  4. Post to the mailing list (if any), X/Mastodon, and pin an issue for 7 days.
  5. Update `CHANGELOG.md` with a `[YANKED]` annotation.
- Never yank without shipping a replacement first.

### 3.4 Disclosure timeline not documented

**Severity:** `Medium`
**Phase:** Phase 0 (`SECURITY.md`)
**What goes wrong:** Reporter sends a bypass; no SLA on response; reporter publishes after 30 days; Relyra maintainers haven't even triaged; bad press.
**Prevention:**
- `SECURITY.md` explicit timeline: "We acknowledge within 5 business days. We commit to a fix within 90 days or we coordinate with you on an extended timeline. We publish a Security Advisory within 30 days of the fix release."
- Python3-saml pattern: publish a "Security history" section in docs listing every CVE, fix version, and fixture path.

### 3.5 Supply-chain — `rustler_precompiled` checksums not verified (if ADR picks NIF path)

**Severity:** `Critical` (if Phase 1 ADR picks NIF-over-xmlsec or a rustler path)
**Phase:** Phase 1 ADR + Phase 0 mix.exs setup
**What goes wrong:** Phase 1 ADR picks an `xmlsec` NIF wrapper. Relyra ships a Hex package that downloads a precompiled binary from GitHub Releases. Attacker compromises Relyra maintainer's GitHub token; pushes a backdoored binary with valid checksum-file for that binary; every Relyra adopter's prod installs the backdoor.
**Prevention (conditional on ADR outcome):**
- If NIF path: `rustler_precompiled` with cryptographic checksums pinned in `checksum-*.exs` (committed to repo), sigstore/cosign-signed releases if feasible.
- Release workflow uses GitHub OIDC with `id-token: write` for sigstore, minimal scopes for the release token.
- CI job `verify_nif_checksums` re-downloads and re-hashes all precompiled binaries at publish time.
- Document supply-chain posture in `SECURITY.md`.

### 3.6 Dependency on `esaml` / `samly` (direct or transitive)

**Severity:** `Critical`
**Phase:** Phase 0 setup
**What goes wrong:** `mix.exs` adds `esaml` "just for metadata parsing" — Relyra now inherits CVE-2026-28809 XXE. Or `samly` is pulled in transitively by some convenience dep; same problem.
**Warning signs:**
- `mix deps.tree` shows `esaml` or `samly`
- `mix.exs` imports anything with `saml` in the name transitively
**Prevention:**
- Explicit rejection in `mix.exs` via a comment: `# NEVER add :esaml or :samly — see SECURITY.md §"Dependency policy"`.
- CI lane `verify.dep_policy`: greps `mix.lock` for `esaml|samly|ex_saml` and fails.
- `mix hex.audit` + `mix deps.audit` in CI.
- `SECURITY.md` "Dependency policy" section names the forbidden packages and reasons.

### 3.7 Test fixtures contain real IdP-signed assertions with real keys

**Severity:** `Critical`
**Phase:** Phase 6 (fixtures) + ongoing discipline
**What goes wrong:** Developer debugs an Okta integration; saves the actual SAML response to `test/fixtures/real_okta_response.xml` for later. The response is signed by Okta's production cert; the assertion contains real user email + group memberships. Commits to public repo; Okta customer's attribute data is leaked; test data is also a signed-by-Okta primitive attackers can experiment with.
**Warning signs:**
- Fixture XML contains anything other than `example.com`, `test@example.com`, `Test User`
- Fixture cert PEM header shows real company name
- Large fixtures (>50 KB) — likely real, unredacted
**Prevention:**
- All fixtures use `Relyra.TestSupport.FakeIdP` signing key (publicly dev-grade, committed to repo openly, labelled as non-production).
- Fixture data uses `example.com` domains, generic user names, synthetic group names.
- CI `verify.fixture_sanity` script greps fixtures for real-looking email domains (matches `\w+@(?!example\.com|example\.org|localhost)`) and fails.
- `CONTRIBUTING.md` §"Fixture policy" explicit.
- If real customer data slips in: private security advisory → revoke leaked key → force-push history rewrite + Hex yank (§3.3) + customer notification.

### 3.8 CI artifact leaks — Playwright screenshots, admin-UI test output

**Severity:** `High` (v0.3+ when admin UI exists)
**Phase:** Phase 6 (testing infra)
**What goes wrong:** v0.3 Playwright tests exercise the admin LiveView with seeded test data. Test screenshot includes "Attribute preview" panel showing `email: real.user@realcompany.com`. Screenshot uploaded as GHA artifact with public retention. Leaked.
**Prevention:**
- Test seed data uses `example.com` domains only.
- Playwright configuration redacts or blurs attribute-preview panels in screenshots.
- Artifact retention on PR branches: 7 days; on main: 14 days. Never indefinite.
- `CONTRIBUTING.md` for admin-UI contributors: "do not paste screenshots with real customer data in issues or PRs."

### 3.9 `Logger.info` of `%Relyra.Error{details: ...}` where details contain raw XML

**Severity:** `Critical`
**Phase:** Phase 6 (logging policy) + Phase 0 (Credo check)
**What goes wrong:** `%Relyra.Error{type: :invalid_audience, details: %{raw_response: "<saml:Response>...</saml:Response>"}}`. Default Elixir inspection dumps the whole XML to the log. Logs are shipped to Datadog; Datadog indexes user attributes; attacker with read access to logs (insider, or log-leak CVE) gets every assertion attacker has ever made.
**Warning signs:**
- `%Relyra.Error{}` struct has a field that could hold raw XML, raw base64, raw response
- `Logger` calls anywhere in `lib/` that include `%Relyra.Error{}` without a `Relyra.Error.redact/1` transform
- No `Inspect` protocol implementation for `%Relyra.Error{}`
**Prevention:**
- `%Relyra.Error{}` implements `Inspect` protocol with a redacting `inspect/2`. Default printed form shows only `type`, `message`, and safe-metadata keys (connection_id hash, error atom, validation step name).
- `String.Chars` implementation for `%Relyra.Error{}` outputs redacted form.
- `details` field is a map with a `:sensitive` namespace for fields that MUST NOT log. `Kernel.inspect/2` on `%Relyra.Error{}` strips `:sensitive`.
- Debug-bundle generator (v1.0) is the ONLY way to see unredacted details, and requires explicit `Relyra.DebugBundle.build/1` call that emits an audit event.
- Custom Credo check `Relyra.Credo.Check.NoRawAssertionInLog` greps for `Logger.*` calls whose arguments include variables named `response`, `assertion`, `xml`, `raw`, `body`, or any `%Relyra.Error{}` without `.redact()` transform. Fails CI.
- CONVENTIONS.md §"Logging policy" enumerates safe and unsafe fields.

### 3.10 `SECURITY.md` not pinned in README

**Severity:** `Medium`
**Phase:** Phase 0
**What goes wrong:** Adopters don't see the disclosure process; bug reports come as public issues (§3.1).
**Prevention:**
- README top navigation / first 10 lines include "Security: [SECURITY.md](./SECURITY.md)".
- Hex package `links` includes `"Security"`.
- Every error message for a validation failure includes a footer line: "See Relyra SECURITY.md for disclosure process if you believe this is a bypass."

### 3.11 `hex.audit` / `deps.audit` / `sobelow` not running in CI

**Severity:** `High`
**Phase:** Phase 0
**What goes wrong:** A transitive dep has a known advisory; Relyra inherits it; no one notices until a customer's compliance team runs a scan.
**Prevention:**
- CI `ci.security` alias: `mix sobelow --config && mix deps.audit && mix hex.audit`. Runs on every PR.
- Sobelow configured for Phoenix-surface audit (v0.4+ when Plug runtime + admin UI exist).
- Dependabot / Renovate enabled for `:hex` ecosystem AND `:github-actions`.
- Weekly drift cron: `mix hex.outdated` report posted as a GitHub issue.

---

## §4 — Pitfall-to-Phase Mapping (for roadmap)

Every pitfall has an owning phase. This table feeds directly into `ROADMAP.md` phase success criteria.

| # | Pitfall (short) | Severity | Phase | Verification gate |
|---|---|---|---|---|
| 1.1 | Parse-before-verify (XXE) | Critical | 1, 2 | `ci.security` XXE fixture rejected + Credo `NoParseBeforeEntityDisable` passes |
| 1.2 | Signature wrapping | Critical | 2, 6 | `ci.security` 8 XSW variants + samlify + node-saml fixtures all rejected |
| 1.3 | Parser differentials | Critical | 1, 2, 6 | Credo `OneXmlParser` passes + 4 PortSwigger-class fixtures rejected + `ruby-saml` CVE fixtures rejected |
| 1.4 | XML-before-safety ordering | Critical | 2 | `test/conventions/validation_ordering_test.exs` passes |
| 1.5 | RelayState open redirect | Critical | 4 | Credo `NoRawRelayStateRedirect` + fixtures `relay_state_http_url`, `relay_state_javascript_scheme` rejected |
| 1.6 | IdP-initiated as default | High | v0.4 (v0.1: reject always) | `in_response_to_missing.xml` rejected in v0.1 |
| 1.7 | ETS replay store in prod | Critical | 3 | Distributed replay integration test passes; `:ets_replay_in_production` raised when configured |
| 1.8 | Cert rollover as ticket | High | v0.2 (v0.1: list-shaped certs) | `idp_signing_certs` field is list; telemetry event `saml.certificate.expiring` emitted |
| 1.9 | NameID ≠ email | High | 5 | `%Principal{}` has no `email` field; three NameID-format fixtures tested |
| 1.10 | Attributes as authz | High | 5 | UserMapper docs + CONVENTIONS.md §"Attributes are inputs"; v0.2 mapping table |
| 1.11 | Over-promising SLO | Medium | v0.5 | README "What v0.1 does not include" lists SLO |
| 1.12 | Clock skew defaults | High | 2 | Property test for skew boundaries passes |
| 1.13 | Missing InResponseTo | Critical | 2, 3 | `missing_in_response_to.xml` rejected; RequestStore behaviour integration |
| 1.14 | KeyInfo from document | Critical | 2 | `key_info_attacker_cert.xml` rejected with `:untrusted_certificate` |
| 1.15 | Multiple assertions | Critical | 2 | `two_assertions.xml` rejected with `:multiple_assertions` |
| 1.16 | Duplicate XML IDs | Critical | 2 | `duplicate_id.xml` rejected with `:duplicate_xml_id` |
| 1.17 | Destination mismatch | High | 2 | `destination_staging.xml` rejected |
| 1.18 | Audience not enforced | Critical | 2 | `audience_for_other_sp.xml` rejected |
| 1.19 | Status silently treated as success | High | 2 | `status_authn_failed.xml` rejected |
| 1.20 | Decompression bomb | High | 1, 2 | `zip_bomb.xml` rejected with `:payload_too_large` |
| 1.21 | SHA-1 default + escape-hatch never expires | Critical | 2, 3 | Default rejects SHA-1; escape hatch requires future `allow_sha1_until` Date |
| 1.22 | Issuer not enforced | High | 2 | `signed_by_other_idp_issuer_mismatch.xml` rejected |
| 1.23 | Recipient not enforced | High | 2 | `recipient_mismatch.xml` rejected |
| 1.24 | Encrypted assertions mishandled | Medium | v1.0 (v0.1: reject) | `encrypted_assertion.xml` → `:encrypted_assertions_not_supported` in v0.1 |
| 1.25 | Metadata MITM | High | v0.2 (v0.1: manual only) | No URL-fetch metadata import in v0.1 |
| 1.26 | FakeIdP in production | High | 1 (test-support isolation) | `FakeIdP.start_link` raises in `:prod`; Hex tarball excludes `test/` |
| 2.1 | `package.files` implicit whitelist | Critical | ongoing | `verify.release_parity` |
| 2.2 | `@version` drift | High | ongoing | `scripts/verify_tag_version.sh` |
| 2.3 | Optional dep `no_warn_undefined` | High | ongoing | `compile_no_optional_deps` lane |
| 2.4 | `--no-optional-deps` not in CI | High | ongoing | Lane exists |
| 2.5 | CHANGELOG drift | Medium | ongoing | Post-publish parity |
| 2.6 | `source_ref: "main"` | Medium | ongoing | Post-publish source-link check |
| 2.7 | Missing `@moduledoc false` | High | ongoing | Credo `InternalModuleDocsFalse` + `:boundary` exports |
| 2.8 | Telemetry naming undocumented | High | 6 | `test/telemetry_contract_test.exs` |
| 2.9 | `package.links.Changelog` missing | Low | ongoing | `package.links` has all four keys |
| 2.10 | Runtime `Code.ensure_loaded?` w/o `optional: true` | Medium | ongoing | Both layers present |
| 2.11 | Release-please drift | Medium | ongoing | PR-title gate |
| 2.12 | Post-publish parity | High | ongoing | `verify.release_parity` + daily cron |
| 2.13 | Dialyzer PLT cache | Low | 0 | CI cache hit rate |
| 2.14 | `:boundary` missing | High | 0, 2 | `mix compile --force` surfaces violations |
| 2.15 | `docs --warnings-as-errors` | Medium | ongoing | `qa` alias includes it |
| 2.16 | Installer golden not path-gated | High | 0 | `installer_golden` lane triggers on path match |
| 2.17 | `mix.exs` runtime-dependent | Medium | 0 | `verify.hex_build` lane |
| 3.1 | Public issue before private advisory | Critical | ongoing | SECURITY.md + GitHub Advisories enabled from day 0 |
| 3.2 | Security fix without regression fixture | Critical | ongoing | `ci.security` replays entire corpus; CONTRIBUTING policy |
| 3.3 | Yanking done wrong | High | ongoing | MAINTAINING.md runbook |
| 3.4 | Disclosure timeline undocumented | Medium | 0 | SECURITY.md has SLA |
| 3.5 | Supply-chain NIF checksums | Critical (conditional) | 1, 0 | Depends on ADR; `verify_nif_checksums` if NIF |
| 3.6 | esaml/samly dep | Critical | 0 | `verify.dep_policy` grep |
| 3.7 | Real IdP assertions in fixtures | Critical | 6, ongoing | `verify.fixture_sanity` grep + CONTRIBUTING policy |
| 3.8 | CI artifact leaks | High | 6 (v0.3+) | Playwright redaction + retention caps |
| 3.9 | Raw XML in logs | Critical | 6, 0 | Credo `NoRawAssertionInLog` + `Inspect` protocol on `%Relyra.Error{}` |
| 3.10 | SECURITY.md not in README | Medium | 0 | README top-nav check |
| 3.11 | `hex.audit`/`sobelow` not in CI | High | 0 | `ci.security` alias |

---

## §5 — "Looks Done But Isn't" checklist

Things that look complete at demo time but are missing critical pieces. Run this checklist before every milestone boundary.

- [ ] **SP-initiated SSO works end-to-end against Keycloak** — verify RequestStore is actually consulted (not short-circuited in test env); assert InResponseTo mismatches reject.
- [ ] **Signature verification passes against Okta fixture** — verify `KeyInfo` from the fixture is IGNORED (swap in attacker cert in KeyInfo, assert still rejects).
- [ ] **RelayState round-trips through IdP and lands on correct return_to** — verify the token is opaque server-side (32-char ID), not a raw URL.
- [ ] **Error messages show the expected vs received values** — verify the template is branded copy, not Elixir default struct inspection; verify no raw XML in the rendered error.
- [ ] **`mix relyra.install` generates working config** — verify the installer golden-diff test is green; verify no Ecto migrations in v0.1 (defer to v0.2).
- [ ] **CI passes on a fresh branch** — verify all seven lanes (lint, test_fast, test_integration, test_security_corpus, installer_golden, security_audit, compile_no_optional_deps) are green, not just `ci.fast`.
- [ ] **Security corpus fixture count** — verify every CVE referenced in `SECURITY.md` has a fixture path; no orphan references.
- [ ] **`package.files` whitelist excludes `test/`, `.planning/`, `prompts/`** — verify via `mix hex.build --unpack && ls`.
- [ ] **Telemetry events documented match events emitted** — verify `test/telemetry_contract_test.exs` asserts one-to-one.
- [ ] **`@moduledoc false` on every internal module** — verify via `grep -L '@moduledoc' lib/` returns empty, then filter for public-surface list.
- [ ] **`%Relyra.Error{}` redacts in logs** — verify `Logger.info(error)` does not emit raw XML.
- [ ] **No `esaml`/`samly` in `mix.lock`** — verify `grep -E 'esaml|samly' mix.lock` returns empty.
- [ ] **SECURITY.md linked from README** — verify first 15 lines of README mention security disclosure.
- [ ] **Post-publish parity check green** — verify after every publish; daily cron issue is closed.
- [ ] **No SLO claims in v0.1 docs** — verify README + CHANGELOG + HexDocs don't mention Single Logout as a feature.
- [ ] **No IdP-initiated claims in v0.1 docs** — verify README explicitly says IdP-initiated is v0.4.
- [ ] **FakeIdP cannot start in prod** — verify via integration test `FakeIdP.start_link` with `MIX_ENV=prod` raises.

---

## §6 — Recovery strategies

When pitfalls occur despite prevention, what to do.

| Pitfall | Recovery cost | Recovery steps |
|---|---|---|
| Parse-before-verify (XXE) shipped | HIGH | (1) Yank Hex release (§3.3). (2) Ship patched version that disables DTDs. (3) Private advisory. (4) Add fixture. (5) Post-mortem in `docs/post-mortems/`. |
| Signature wrapping shipped | HIGH | Same as XXE. This is a full authentication bypass — treat as "CVE-worthy, everyone upgrades today." |
| Parser differential shipped | HIGH | Same as XXE. |
| ETS replay in clustered prod (adopter misconfig) | MEDIUM | (1) Surface in docs + Sobelow-equivalent check. (2) Emit structured log warning on ETS adapter startup when `Mix.env() == :prod`. (3) Make the ETS adapter require `unsafe_allow_ets_in_prod: true` in v0.2+. |
| Adopter shipped with SHA-1 allowed forever | LOW (adopter problem) | (1) Document best practice. (2) Emit audit-event telemetry they can alert on. (3) Admin UI (v0.3) surfaces expired escape hatch loudly. |
| Real customer data in committed fixtures | HIGH | (1) Private security advisory. (2) Force-push rewrite to scrub history. (3) Rotate any leaked keys. (4) Notify affected customer. (5) Hex yank. (6) Add `verify.fixture_sanity` CI gate if not already present. |
| Public issue posted with PoC | HIGH | (1) Convert to GitHub Security Advisory immediately. (2) Request original reporter to delete PoC from public issue. (3) Assume zero-day and ship fix fast. (4) Coordinate disclosure with known adopters. |
| Release-please miscategorized a breaking change | MEDIUM | (1) Ship a follow-up release with a `!`-prefixed conventional commit announcing the break. (2) Update CHANGELOG with breaking-change callout. (3) Document migration in a new `MIGRATING.md` entry. |
| Telemetry event renamed in minor version | MEDIUM | (1) Restore old event name alongside new one. (2) Deprecate old name with `since:` metadata. (3) Schedule removal for next major. |
| `package.files` accidentally shipped `.planning/` | HIGH | (1) Hex yank. (2) Ship corrected package. (3) Evaluate whether `.planning/` contents were sensitive — if yes, rotate + advisory. |
| Post-publish parity drifted (no one noticed) | LOW | (1) Daily cron issue closes on fix. (2) Root-cause the drift source — usually a workspace-dirty publish. |

---

## §7 — Sources

**Published CVEs (primary evidence):**
- [CVE-2026-28809 — esaml XXE pre-signature-verification (Erlang Ecosystem Foundation CNA)](https://cna.erlef.org/cves/CVE-2026-28809.html)
- [CVE-2024-45409 — ruby-saml forgery via signed SAML document (GitHub Advisory)](https://github.com/SAML-Toolkits/ruby-saml/security/advisories)
- [CVE-2025-25291 — ruby-saml DOCTYPE parser differential (RubySec)](https://rubysec.com/advisories/CVE-2025-25291/)
- [CVE-2025-25292 — ruby-saml namespace parser differential (GitLab Advisories)](https://advisories.gitlab.com/pkg/gem/ruby-saml/CVE-2025-25292/)
- [CVE-2025-66567 — ruby-saml incomplete fix (GitLab Advisories)](https://advisories.gitlab.com/pkg/gem/ruby-saml/CVE-2025-66567/)
- [CVE-2025-47949 — samlify signature wrapping (GitHub Advisory)](https://github.com/advisories/GHSA-r683-v43c-6xqv)
- [CVE-2025-54369 — node-saml authentication bypass (GitHub Advisory)](https://github.com/advisories/GHSA-m837-g268-mmv7)
- [CVE-2025-54419 — node-saml signature verification vulnerability (GitLab Advisories)](https://advisories.gitlab.com/pkg/npm/passport-saml/CVE-2025-54419/)

**Original vulnerability research:**
- [The Fragile Lock: Novel Bypasses For SAML Authentication (PortSwigger, 2025)](https://portswigger.net/research/the-fragile-lock) — attribute pollution, REXML namespace confusion, void canonicalization, extension point injection
- [Sign in as anyone: Bypassing SAML SSO authentication with parser differentials (GitHub Blog, 2025)](https://github.blog/security/sign-in-as-anyone-bypassing-saml-sso-authentication-with-parser-differentials/)
- [CVE-2025-47949 Reveals Flaw in samlify (Endor Labs, 2025)](https://www.endorlabs.com/learn/cve-2025-47949-reveals-flaw-in-samlify-that-opens-door-to-saml-single-sign-on-bypass)

**OWASP / OASIS / standards references:**
- OWASP SAML Security Cheat Sheet (local schema validation, signature wrapping, replay, RelayState allowlisting)
- OASIS SAML 2.0 Core specification (validation rules, Conditions, SubjectConfirmationData, AttributeRestriction)
- Somorovsky et al., "On Breaking SAML: Be Whoever You Want to Be" — XSW taxonomy (8 classical variants)

**Relyra prior-research canon:**
- `/Users/jon/projects/relyra/prompts/elixir-saml-lib-deep-research.md` — §"Security invariants", §"Footguns to design out", §"Lessons learned from existing libraries", §"Error taxonomy"
- `/Users/jon/projects/relyra/prompts/relyra-engineering-dna-from-prior-libs.md` — §2 convergent DNA, §6 SAML-specific gotchas, §9 TL;DR
- `/Users/jon/projects/relyra/prompts/relyra-brand-book.md` — §14 product UI (unsafe options), §15 UX microcopy, §22 security language, §23 community voice
- `/Users/jon/projects/relyra/prompts/RELYRA-GSD-IDEA.md` — product principles, non-goals, strict defaults
- `/Users/jon/projects/relyra/prompts/elixir-opensource-libs-best-practices-deep-research.md` — anti-patterns (§17), packaging discipline, telemetry contract

**Sibling-repo engineering DNA (in-tree, not re-cited):**
- `sigra` — custom Credo checks, installer golden-diff, CONVENTIONS.md pattern, `:boundary` compiler
- `scrypath` — post-publish parity verification, daily drift cron
- `lattice_stripe` — `api_stability.md`, PR-title semantic gate, telemetry contract
- `kiln` — `verify_tag_version.sh`, PLT cache path, `mix check` mega-alias
- `mailglass` — `OptionalDeps.*` gateway pattern

---

*Pitfalls research for: Security-first SAML 2.0 Service Provider library for Elixir/Phoenix (Relyra v0.1)*
*Researched: 2026-04-24*
*Confidence: HIGH — grounded in published CVE IDs, PortSwigger original research, and convergent DNA from ten sibling Elixir libs.*
