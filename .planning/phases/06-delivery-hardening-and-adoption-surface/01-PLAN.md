# Phase 6: Delivery Hardening and Adoption Surface

**Goal**: Finalize the v0.1 adoption surface — provider presets, security
regression corpus, installer, and TestSupport DX — without expanding scope.

## Decisions (research-backed)

Each headline decision was researched against Elixir prior art (Assent, Pow,
Ueberauth, Oban.Testing, Swoosh, Phoenix.ConnTest, Mox) and adjacent
ecosystems (ruby-saml, python3-saml, crewjam/saml, samlify, Spring SAML,
django-allauth). Synthesis:

1. **Provider presets**: behaviour + module-per-provider (Assent's
   `default_config/1` shape). No struct rigidity. Public API:
   `apply_defaults/2`, `translate_label/2`, `check_footguns/2`,
   `from_metadata_url/2`.
2. **Installer**: hand-rolled `Mix.Task` + EEx (Pow pattern), NOT Igniter.
   Rationale: scope is 4 files + sentinel-wrapped config; Igniter forces a
   transitive dev-dep on adopters and churns API quarterly.
3. **Keycloak container**: **deferred** to v0.2. No comparable lib vendors
   an IdP. KC realm-import has broken across 24/25/26. Replace with a
   ~15-line "Testing against a real IdP" section pointing to
   `Relyra.TestSupport.FakeIdP` (canonical), mocksaml.com (manual smoke),
   and a DIY `quay.io/keycloak/keycloak:<pin>` snippet.
4. **TestSupport / FakeIdP**: `use Relyra.TestSupport, endpoint: ...` macro
   (Oban.Testing idiom); per-suite-generated RSA-2048 cached in
   `:persistent_term`; Swoosh-style pattern-match assertion macros.

## Plans

### 06-01: Provider Presets and Recipes

- `lib/relyra/provider.ex`: behaviour + dispatcher with `@callback id/0`,
  `display_name/0`, `default_config/0`, `labels/0`, `footguns/0`,
  `guide_url/0`. Public API: `apply_defaults(:okta, user_cfg)`,
  `translate_label(:okta, :sp_entity_id)`,
  `check_footguns(:okta, conn) :: [:ok | {:warn, atom(), String.t()}]`.
- `lib/relyra/provider/{okta,entra,google_workspace}.ex`: pure-data preset
  modules implementing the behaviour.
- Hook `Error.new/3` callsites that already carry connection context to
  attach `:provider_hint` from `translate_label/2` (admin channel only —
  emitted via `Relyra.Log`, never user-facing).
- `guides/recipes/{okta,entra,google_workspace}.md`: prose + bold field
  names, dated `> Tested against:` header, common-issues table, no
  screenshots (they go stale in 12-18 months).
- Tests: preset shape contract; default-merge user-wins semantics; label
  translation snapshot; footgun checks fire on known-bad connections.

**Hard-coded footguns (must guard against, evidence from prior CVEs/bugs)**:
1. SHA-1 algorithm defaults — ruby-saml's recurring CVE source.
2. `allow_idp_initiated?: true` without explicit consent — crewjam/saml
   panic precedent.
3. Entra `name_id_format` defaulting to anything other than `persistent` —
   Entra silently sends opaque IDs if you ask for email without claim
   mapping.

**DX wins to steal**:
1. Spring's metadata-URL bootstrap (`from_metadata_url/2`).
2. django-allauth's default attribute mapping per provider.
3. Assent's keyword-merge defaults (user wins).

### 06-02: Real-IdP testing guide (replaces Keycloak vendor)

- `guides/getting_started.md` "Testing against a real IdP" section
  (~15 lines): FakeIdP canonical, mocksaml.com manual, DIY Keycloak
  snippet. Defer vendored compose/realm to v0.2 (or a separate repo).

### 06-03: Security Regression Corpus

- Audit and complete `test/fixtures/security/{xml,signature,protocol}/`.
  Each fixture has a `manifest.json` entry tagging
  `cve` / `footgun_source` / `expected_error_kind`.
- Coverage matrix:
  - **XML**: XXE, billion laughs, comment-splice, DTD inclusion.
  - **Signature**: SHA-1 reject, unsigned-assertion, wrong-key,
    tampered-digest, KeyInfo-trust-spoofing.
  - **Protocol**: bad-audience, expired, not-yet-valid, replayed,
    IdP-initiated-without-flag, missing-InResponseTo, XSW (1, 7, 8),
    Issuer mismatch.
  - **Provider**: Okta-trailing-slash audience,
    Entra-emailAddress-without-mapping.
- `mix ci.security`: replays the corpus in fail-closed mode, asserting
  each named fixture rejects with the expected `Relyra.Error.type`.
- Wired into the project alias `mix ci` if present.

### 06-04: Installer + TestSupport DX

**`Mix.Tasks.Relyra.Install`** (hand-rolled):
- Generates `lib/<app>/relyra/connections.ex` (`@behaviour
  Relyra.ConnectionResolver` skeleton) and `lib/<app>/relyra/user_mapper.ex`
  (`@behaviour Relyra.UserMapper` skeleton).
- Appends config wrapped in `# --- Relyra START ---` /
  `# --- Relyra END ---` sentinels (idempotent; future-upgrade-safe).
- Optional `--router` injection via `String.contains?` guard; bails to
  printed manual instructions on any ambiguity.
- Switches: `--module`, `--router`, `--repo`, `--no-config`, `--force`.
- Golden-tree test at `test/mix/relyra_install_test.exs`: copies fresh
  Phoenix fixture to `tmp_dir`, runs install via `System.cmd`, byte-diffs
  generated files, then `mix compile --warnings-as-errors` to prove output
  is real-world valid. Update with `MIX_UPDATE_GOLDEN=1`.

**`lib/relyra/test_support.ex`** (shipped in runtime tree):
- `use Relyra.TestSupport, endpoint: MyAppWeb.Endpoint` injects
  `Plug.Conn` / `Phoenix.ConnTest` / `Relyra.TestSupport` /
  `Relyra.TestSupport.Assertions` imports plus `@endpoint`,
  `@relyra_resolver`.
- Helpers: `setup_saml_connection/1`, `post_saml_response/3` (composes
  `Phoenix.ConnTest.dispatch/5` — does not reimplement HTTP).
- Resolver-aware: stores configured resolver on `conn.private[:relyra_resolver]`.

**`lib/relyra/test_support/fake_idp.ex`**:
- GenServer holding per-suite-generated RSA-2048 keypair, cached in
  `:persistent_term` for async safety.
- Single override-map response builder: `build_response(opts)` returns
  `%ResponseBuilder{}`; `sign/2` returns base64-encoded SAMLResponse.
- 5 sign primitives cover every threat-model negative path:
  `:tamper` (`:signature | :assertion | :digest`), `:key`
  (`:correct | :wrong_key | :unsigned`), `:encrypt`.
- Fixture-key escape hatch (`use_fixture_key/1`) is opt-in,
  library-internal only.

**`lib/relyra/test_support/assertions.ex`** (Swoosh-style):
- `assert_saml_login(conn, %{email: "alice@x.com"})`
- `assert_saml_error(conn, %Relyra.Error{type: :audience_mismatch})`
- Compile-time guard: empty pattern (`%{}`, `_`) raises `CompileError`.
- Tuple escape hatch: `saml_login(conn) :: {:ok, principal} | {:error, error}`.

**Three footgun guards (mandatory)**:
1. `Mix.env() == :prod` raises `CompileError` at top of TestSupport and
   FakeIdP modules. Runtime belt-and-braces in `FakeIdP.start_link/1`.
2. No checked-in private keys; per-suite generation is the default.
3. Resolver passthrough so test path = production path.

### Wrap-up

- `SECURITY.md`: threat model, supported algorithms, disclosure policy.
- Scope-first `README.md` (≤ 300 lines): narrow promise — "SAML 2.0 SP for
  Plug/Phoenix; OIDC is not us."

## Success Criteria

1. Provider presets operational: `Relyra.Provider.apply_defaults/2`
   enriches user config; `translate_label/2` drives admin-channel error
   hints; footgun checks fire on known-bad configs.
2. `mix ci.security` is green and covers every fixture in the matrix
   above; each rejection matches its declared `expected_error_kind`.
3. `mix relyra.install` produces a byte-identical golden tree against the
   fresh-Phoenix fixture, and the result compiles with
   `--warnings-as-errors`.
4. Adopters can write a full SSO integration test in ≤ 10 lines using
   `use Relyra.TestSupport`. Live example fixture lives in
   `test/test_support_demo_test.exs`.
5. `SECURITY.md` and scope-first `README.md` are present and link to
   recipes / TestSupport / threat model.

## Routing

Execute in order, atomic commits per logical chunk:
1. 06-01 Provider behaviour + dispatcher → presets → recipes → tests.
2. 06-03 Security corpus + `mix ci.security` task.
3. 06-04 TestSupport (FakeIdP first, then macros + assertions).
4. 06-04 Installer + golden-tree test.
5. 06-02 getting_started.md section.
6. Wrap-up SECURITY.md + README.md.
