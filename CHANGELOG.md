# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project targets [Semantic Versioning](https://semver.org/).

## [1.8.0](https://github.com/szTheory/relyra/compare/v1.7.0...v1.8.0) (2026-06-14)


### Features

* **demo:** FakeIdP browser-login proof + hardening (Phase 57/57.1) ([#35](https://github.com/szTheory/relyra/issues/35)) ([9b72d1e](https://github.com/szTheory/relyra/commit/9b72d1ec3f7d650002af176f7a3395dc3ea29db7))

## [1.7.0](https://github.com/szTheory/relyra/compare/v1.6.0...v1.7.0) (2026-06-13)


### Features

* v1.7 Adoption Evidence Demo (LedgerLoop runnable demo app) ([#31](https://github.com/szTheory/relyra/issues/31)) ([b66722d](https://github.com/szTheory/relyra/commit/b66722d0aa73e17fc408cfab7172afc62841bd78))

## [1.6.0](https://github.com/szTheory/relyra/compare/v1.5.4...v1.6.0) (2026-05-29)


### Features

* **adoption:** Phase 50 golden host journeys and Keycloak CI lane ([b21bdbb](https://github.com/szTheory/relyra/commit/b21bdbb254163983da179304455b58d7d35460fe))
* **adoption:** Phase 50 golden host journeys and Keycloak CI lane ([fb105da](https://github.com/szTheory/relyra/commit/fb105da4d8f60de890014b5f46b2eba19dbe927f))


### Bug Fixes

* **adoption:** CI warnings and Keycloak SSO redirect binding ([83f9b90](https://github.com/szTheory/relyra/commit/83f9b90028be15279d1592dd9c1bb28628d50c09))
* **adoption:** follow Keycloak SSO redirects when fetching login form ([19fbb26](https://github.com/szTheory/relyra/commit/19fbb26e11ffb15e796639c445ea7ba8511a8ff7))
* **adoption:** green Keycloak external IdP lane and real IdP crypto interop ([d48871a](https://github.com/szTheory/relyra/commit/d48871a22e501f6141219adaa096789d6cc85d60))
* **adoption:** stabilize Keycloak login fetch without form pre-check ([45e1d1e](https://github.com/szTheory/relyra/commit/45e1d1efb1d278439b5aee25f61aa718273d00e6))
* **adoption:** use valid guard in Keycloak redirect URL helper ([18f78ae](https://github.com/szTheory/relyra/commit/18f78aeeff72ca7afd6665f7eb2b34b1b0d2f10f))
* **security:** align KeyInfo corpus with rogue-outside-Signature policy ([7846892](https://github.com/szTheory/relyra/commit/78468929a8f152dcb19000cefc8789a7e799dab3))

## [1.5.4](https://github.com/szTheory/relyra/compare/v1.5.3...v1.5.4) (2026-05-28)


### Bug Fixes

* **ci:** auto-dispatch Hex publish after release-please automerge ([e50dfd5](https://github.com/szTheory/relyra/commit/e50dfd59fd76938842ca637813a04f7011d704d2))
* **ci:** auto-dispatch Hex publish after release-please automerge ([39bbc21](https://github.com/szTheory/relyra/commit/39bbc21a5ca22484f25b866e45041fda973d0c23))

## [1.5.3](https://github.com/szTheory/relyra/compare/v1.5.2...v1.5.3) (2026-05-28)


### Bug Fixes

* **ci:** grant actions:write for release-please PR dispatch ([e32d828](https://github.com/szTheory/relyra/commit/e32d8282f47971770d7382ca9f59de63f33a536a))
* **ci:** grant actions:write for release-please PR dispatch ([ecf2736](https://github.com/szTheory/relyra/commit/ecf2736b9185d3a46bf4723bea9e04ac53978c58))
* **ci:** parse spaced security-gates check names on release PRs ([099b92b](https://github.com/szTheory/relyra/commit/099b92b098dc02b9b9714afce7a2372cc99dd8ea))
* **ci:** parse spaced security-gates check names on release PRs ([adabc13](https://github.com/szTheory/relyra/commit/adabc1381ce118d71f85eb1061264ddac5dec7cb))
* **ci:** tolerate gh pr checks exit when no checks yet ([fbef01c](https://github.com/szTheory/relyra/commit/fbef01cf9c3f2e363d3a73eecf7c37681274b079))
* **ci:** tolerate gh pr checks exit when no checks yet ([98606d2](https://github.com/szTheory/relyra/commit/98606d2f0b6501b4ab7684802569dfff26432307))
* **docs:** note hands-off release path in getting started ([0f6d758](https://github.com/szTheory/relyra/commit/0f6d7588cf9286f1f457c782c63592e35c9e7214))
* **docs:** note hands-off release path in getting started ([f19d239](https://github.com/szTheory/relyra/commit/f19d2392c5b5a035c82c5466a6a7d0490cd7f3af))

## [1.5.2](https://github.com/szTheory/relyra/compare/v1.5.1...v1.5.2) (2026-05-28)


### Bug Fixes

* **test:** isolate replay store and warm FakeIdP keypair ([3635c5c](https://github.com/szTheory/relyra/commit/3635c5c4a8900ebd4bd4733b01b480637c258bc7))
* **test:** isolate replay store and warm FakeIdP keypair ([d2bb6bf](https://github.com/szTheory/relyra/commit/d2bb6bf6c957162598d47e2e31657be92fea646d))

## [1.5.1](https://github.com/szTheory/relyra/compare/v1.5.0...v1.5.1) (2026-05-28)


### Bug Fixes

* **ci:** gate Hex publish on mix qa and enforce branch protection ([7303b36](https://github.com/szTheory/relyra/commit/7303b3659883458102e97d691540736b3ce2ff64))
* **ci:** release-please trigger for 1.5.1 ([15efe67](https://github.com/szTheory/relyra/commit/15efe677a837c61364e00abf89d1b1a472704449))

## [1.5.0](https://github.com/szTheory/relyra/compare/v1.4.0...v1.5.0) (2026-05-28)


### Features

* **45-01:** add mix verify.release_parity for Hex vs tag path-set diff ([7ca46c4](https://github.com/szTheory/relyra/commit/7ca46c461dee37997330859ead5e045110f441a4))
* **45-02:** add verify-parity.sh milestone gate wrapper ([227a3c2](https://github.com/szTheory/relyra/commit/227a3c23d5583c5f78534a75c93e1c92a0dc1577))
* **49-01:** add scope boundary section to conformance generator ([93418a6](https://github.com/szTheory/relyra/commit/93418a64461ed0344adfa6bced4961c614f38f04))
* **49-01:** flip ENC manifest row from deferred to pass ([f865174](https://github.com/szTheory/relyra/commit/f865174995964a4cc19e77c4148c13da053a662d))
* **docs:** add README Quick Look preset snippet (DX-01) ([65bcf93](https://github.com/szTheory/relyra/commit/65bcf93f96727ba6e96c89da92226a5144f71ec2))
* **docs:** job-shaped overview hub and batteries dedupe (DX-03) ([00937be](https://github.com/szTheory/relyra/commit/00937befa5512c107f0faf1f98c5a1021d171a5a))
* **install:** auto-inject saml_routes on single Phoenix router (DX-02) ([ca632bd](https://github.com/szTheory/relyra/commit/ca632bd9defed9449118b2f5bdd9ea0a2d1913b7))

## [1.4.0]

Hex publishes **1.4.0** directly from **1.2.0** with no intermediate **1.3.0** Hex release for adopter clarity — one install line `{:relyra, "~> 1.4"}` receives Advanced Federation, Single Logout, and the login trace UI. The `[1.3.0]` section below is changelog archaeology for the v1.3 milestone only, not a skipped Hex version adopters must hunt for.

### Added

- **Single Logout:** `SessionAdapter` session-index hooks; SP- and IdP-initiated logout via `Relyra.consume_logout/3`; HTTP-Redirect and HTTP-POST bindings; strict logout validation pipeline (`Parse → Verify → Replay → Execute`); `LogoutRequest`/`LogoutResponse` on the same `SaxyTree` parse path as login.
- **Logout operator guide:** `guides/recipes/logout.md` — browser cookie caveats, durable session prerequisites, absolute-timeout boundaries, and host-owned session-index linkage.
- **Incident playbook:** `guides/operations/incident_playbook.md` — six Triage→Diagnose→Recover scenarios with evidence surfaces for telemetry, audit, and login trace.
- **Troubleshooting decoder:** `guides/troubleshooting.md` — 78 typed SAML error atoms across seven trust-pipeline buckets, kept in sync with the codebase.
- **Login trace LiveView:** `ConnectionTraceLive` at `/relyra/admin/connections/:connection_id/trace` — expandable step timeline from audit rows and telemetry.
- **Headless login trace:** `mix relyra.trace` for the same redacted step timeline without opening the browser.
- **Shared trace export:** `Relyra.LoginTrace.Export` redacts login-trace rows consistently for LiveView and CLI.
- **Publish hygiene:** SP metadata attribute escaping; `test_support` excluded from production compile and Hex tarball; encrypted-assertion wire extraction uses parse-tree byte spans only; README and preset documentation aligned with shipped presets.

### Changed

- Trust audit timeline excludes `domain: :login` rows (login traces separate from trust mutations).
- `LoginResult.validation_trace` populated on successful consume via `LoginTrace` telemetry handler.
- Production `elixirc_paths` uses explicit lib file list (excludes `test_support`).

### Security

- **Logout crypto:** XMLDSig verification before session termination; redirect signatures verified against raw query octets; replay protection on logout messages.
- **Login trace redaction:** security tests ensure LiveView and CLI never render raw XML, PEM, certificate bodies, signature values, or key material.
- **Metadata XSS defense-in-depth:** interpolated SP metadata attributes are XML-escaped before publish.
- **One trust path for encrypted assertions:** wire extraction uses parse-tree byte spans only — no parallel regex locator on the auth boundary.

## [1.3.0]

This section records the v1.3 Advanced Federation milestone only — **no Hex release at 1.3.0** (historical record).

### Added

- **Encrypted assertions (ENC-01/02):** `KeyResolver` behaviour + `KeyResolver.Default` (SP private key from app config only); `Relyra.Security.XMLEnc.decrypt/3` with RSA-OAEP + AES-GCM behind `AlgorithmPolicy`; decrypt-then-reparse pipeline stage in `ValidationPipeline` (`:decrypt_assertion` pre-stage); cleartext+encrypted ambiguity guard (`:ambiguous_assertion` before crypto); SP metadata encryption `KeyDescriptor`; 7-fixture ENC-01 adversarial corpus in `mix ci.security`.
- **Signed AuthnRequests (AUTHN-01):** HTTP-Redirect query signing (`sign_redirect_query/3` raw-octet invariant); `sign_authn_requests` connection toggle; SP metadata `AuthnRequestsSigned` + signing `KeyDescriptor`; ADFS provider preset + `guides/recipes/adfs.md`; 5-fixture AUTHN-01 adversarial corpus in `mix ci.security`.
- **AlgorithmPolicy + schema:** Key-transport and content-encryption enforcement; RSA-PKCS1v1.5 blocked; AES-CBC blocked by default with time-boxed escape hatch; GCM auth-tag length guard; cert `party`/`use` columns; `sign_authn_requests` migration.
- **Documentation (DOCS-02):** `guides/recipes/generic_saml.md` — SP/IdP metadata reference, decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder; security checklist, debugging flow, cert rotation.
- **Documentation (DOCS-03):** `guides/identity_mapping_and_provisioning.md` — NameID vs attribute mapping patterns, JIT decision tree, `UserMapper` examples, SCIM non-goal.

### Changed

- `PureBeam.build_parsed_doc/1` tolerates encrypted-only Responses pre-decrypt (`encrypted_pending` path) without weakening cleartext gates.
- SP metadata build order: signing + encryption `KeyDescriptor`s before ACS (schema-valid).

### Security

- **Decrypt-then-reparse invariant:** decrypted bytes MUST pass `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before identity fields — CVE-2025-54419 class read-before-verify rejected by adversarial corpus.
- **Single opaque `:decryption_failed`** for all decryption failure modes (no padding oracle via distinct atoms).
- **Document `KeyInfo` ignored** for decryption key material — configured `KeyResolver` only.
- **Ambiguity guard:** cleartext + encrypted assertion → `:ambiguous_assertion` pre-crypto (CVE-2026-2092 class).
- **Redirect AuthnRequest signing:** golden corpus enforces no re-serialization before sign; ADFS `+`-encoding variant covered.
- **AlgorithmPolicy:** RSA-OAEP SHA-256 URI blocked pending OTP support; zero new Hex deps for XML-Enc (OTP stdlib only).

## [1.2.0](https://github.com/szTheory/relyra/compare/v1.1.0...v1.2.0) (2026-05-25)


### Features

* **28-01:** implement SaxyTree handler with ns stack + 3 normalizations ([8738532](https://github.com/szTheory/relyra/commit/87385326a3c3d34c758be6e6ed9554aeee26816c))
* **28-02:** enveloped-sig transform pruning + PrefixList forced render + transform allowlist ([ae9f16f](https://github.com/szTheory/relyra/commit/ae9f16feb5f7a201b05c1a99500ca2240c2fdd69))
* **28-02:** implement exclusive C14N 1.0 serialization core ([b666926](https://github.com/szTheory/relyra/commit/b666926e17674916ca77f4cc0938aaa907a161be))
* **28-03:** bind exact tree node + delegate canonicalize/2 to the C14N engine ([5565df5](https://github.com/szTheory/relyra/commit/5565df50d7b68abdaad88fe8db6f556d8458c106))
* **28-03:** route parse_safely onto the saxy tree, retire regex extractors ([915d460](https://github.com/szTheory/relyra/commit/915d4604b0daa89e39279aa03acb04aa970dc0b1))
* **29-01:** add ordered content field to SaxyTree.Node (D-09) ([4411f91](https://github.com/szTheory/relyra/commit/4411f91ea1785c9ba99d46e58b4c90f122d7bb90))
* **29-02:** add AlgorithmPolicy.digest_atom_for_signature_method/1 (RSA→atom, ECDSA fail-closed) ([e63216e](https://github.com/szTheory/relyra/commit/e63216eafbee4e463e6e3995ef78160d9ed1aba3))
* **29-02:** surface D-02 fields (SignedInfo node, base64 Digest/SignatureValue) per candidate ([5d1cfc9](https://github.com/szTheory/relyra/commit/5d1cfc9a41c732be0f360175781d319c49e3fec0))
* **29-03:** wire real XMLDSig crypto into the [candidate] arm (D-01) ([2e45689](https://github.com/szTheory/relyra/commit/2e456897af3158c175bb490ce7fc51d6241c8922))
* **29-04:** build genuine XMLDSig test-signer (D-11) ([c45864f](https://github.com/szTheory/relyra/commit/c45864fd00b3d6a201b184da21453a53626c0bde))
* **29-05:** add metadata-root signed-candidates producer in pure_beam ([502417f](https://github.com/szTheory/relyra/commit/502417f7b4811ad71aa5bbd29522c55a005cf67c))
* **29-05:** rewire metadata pre-parse onto tree builder + prove SIGV-04 ([6d4931e](https://github.com/szTheory/relyra/commit/6d4931eba1d925b2f1ecea2d99dc101e75b4dcaa))
* **30-01:** delegate FakeIdP.sign to genuine signer + expose trust cert (D-01/D-03) ([18f5bd8](https://github.com/szTheory/relyra/commit/18f5bd8d2c95ea68142b9929a8cf06daec31c29d))
* **30-03:** add c14n-differential rejection row to security corpus ([c7ec6a2](https://github.com/szTheory/relyra/commit/c7ec6a261f4297fe59930d9a7aaaa11adc612a6b))


### Bug Fixes

* **28-03:** correct prot-unsigned-001 expectation to missing_protocol_field ([63c5ca5](https://github.com/szTheory/relyra/commit/63c5ca5ad0b6513ec5b3f88c7beffb8f734ddafc))
* **29-01:** walk content in document order in C14N.render_element/3 (D-09) ([8052658](https://github.com/szTheory/relyra/commit/8052658e07933e2a322393afb1a8c9bf267c78b7))
* **29:** close metadata trust bypass (CR-01) and pin over DER (CR-02) ([8910200](https://github.com/szTheory/relyra/commit/8910200edc77a502d4cbce7ec88188b4bd636f99))
* **29:** thread cert_chain in plan 03 + add existing-test triage task to plan 04 ([13094ef](https://github.com/szTheory/relyra/commit/13094ef1232fcd2fdaedccf942d99788840b3516))
* **29:** tolerate line-wrapped base64 in Signature/DigestValue (WR-01) ([ef44482](https://github.com/szTheory/relyra/commit/ef444820bf09d994547ae7fef6692eccba722916))
* **30-01:** reconcile FakeIdP response_xml shape for genuine signing (D-02) ([f9047fe](https://github.com/szTheory/relyra/commit/f9047fe77145a4039c69b693863dd5c5da868ab1))
* **30-04:** make ci.security honestly gate every security suite (cmd mix test per line) ([8a144ed](https://github.com/szTheory/relyra/commit/8a144ed23a50036a05e124cd4311afd6b8450ac8))
* **30:** harden ci.security meta-gate (AST parse, tag anchor, corpus_gate coverage) ([07f4727](https://github.com/szTheory/relyra/commit/07f4727967b2183637b35b4481167d703b7ec5bd))
* **deps:** bump postgrex/plug/phoenix for CVEs; ignore unreachable decimal advisory ([520d713](https://github.com/szTheory/relyra/commit/520d713f8b124b6029a297c814ed0ba7d365cffb))

## [1.1.0](https://github.com/szTheory/relyra/compare/v1.0.0...v1.1.0) (2026-05-08)


### Features

* **01-02:** add pure-beam XML adapter baseline ([68f1041](https://github.com/szTheory/relyra/commit/68f10410571ab85683b98f92f587023c20527c81))
* **01-02:** add stable Relyra.Error contract ([5077f9d](https://github.com/szTheory/relyra/commit/5077f9d5c821f632fb5dbc68c4f319503d13e103))
* **01-02:** freeze hardened XML seam behaviour ([ed7257e](https://github.com/szTheory/relyra/commit/ed7257ef348c6971f2f1aed424492201bbc1e3c9))
* **01-03:** add compile-time parser path guard ([74bac6e](https://github.com/szTheory/relyra/commit/74bac6ea6f1cdd4d327bfc6e526c7b7627956c4a))
* **02-01:** add protocol and relay state contract tests ([9225186](https://github.com/szTheory/relyra/commit/92251860354e774af875f8f73ac6deb7a3081bb4))
* **02-01:** enforce opaque relay state contract ([d21697f](https://github.com/szTheory/relyra/commit/d21697ff62509c8332c7895dd17dd3bbc8842f0c))
* **02-01:** implement login request and binding primitives ([b0d49b6](https://github.com/szTheory/relyra/commit/b0d49b62eec3354619e5b9a97476407d672f4803))
* **02-02:** bind signature verification to exact signed node ([2aeba97](https://github.com/szTheory/relyra/commit/2aeba972d43391175a94c7793b63c6a5709abc48))
* **02-02:** enforce strict signature algorithm policy ([88d43db](https://github.com/szTheory/relyra/commit/88d43db06a3cd8e4698308c22a751eaf59ceb47a))
* **02-03:** add ordered consume response pipeline ([d7db968](https://github.com/szTheory/relyra/commit/d7db96837f63539bc8a52ac4bdc7cfb5b460cee5))
* **02-03:** add response and assertion validators ([47981a2](https://github.com/szTheory/relyra/commit/47981a28af7ae1c52e43de68956494f5529d9e52))
* **03-01:** add fail-closed default adapter scaffolding ([f4acf93](https://github.com/szTheory/relyra/commit/f4acf932704ff6457defbe704fc36a9037448ef7))
* **03-01:** freeze phase 3 behaviour contracts ([9841e09](https://github.com/szTheory/relyra/commit/9841e09257e052094ece31015781b32c2c07ad5d))
* **03-02:** add atomic ETS request and replay adapters ([223cb72](https://github.com/szTheory/relyra/commit/223cb726d147a031d4da2339c2e097e4045087ad))
* **03-02:** add optional Ecto-backed request and replay stores ([4a801f9](https://github.com/szTheory/relyra/commit/4a801f9c9b9002b2482c7972125c9972c8094e26))
* **03-03:** persist request intent and gate consume success ([a6cf9aa](https://github.com/szTheory/relyra/commit/a6cf9aad4452392714b500683ccdedfe3a936110))
* **05-01:** add telemetry catalog and event spans ([07b503f](https://github.com/szTheory/relyra/commit/07b503f697de2aa91dfc3aa25740f0c3a1527574))
* **06-01:** add provider presets, TestSupport, installer, and docs ([670ee92](https://github.com/szTheory/relyra/commit/670ee926b6ec017ae31bf7af234187f1990734a7))
* **06-01:** close release-discipline gap and add provider audience hint ([bdb7c9a](https://github.com/szTheory/relyra/commit/bdb7c9a8f6c5a3eb7e2e20a535419ed9228daccc))
* **11-02:** add mapping persistence migration coverage ([06856c6](https://github.com/szTheory/relyra/commit/06856c66295121a75ab1cda3ab1893c0a0ee3376))
* **11-03:** harden audited trust mutations ([c546b6b](https://github.com/szTheory/relyra/commit/c546b6b8d501ca7f9e9c0d903e8b93f0345ad724))
* **11-04:** persist and hydrate mapping config ([dd9da43](https://github.com/szTheory/relyra/commit/dd9da43e009b7bc1447ae0f994ee3bb43ec03ec4))
* **12-12-01:** canonicalize metadata certificate candidates ([6d5d652](https://github.com/szTheory/relyra/commit/6d5d65235b2adf4c24fe8b42cb5e42dc72e0e5b4))
* **14-01:** author 11-VERIFICATION.md with serial CFG-05 packet ([4339dca](https://github.com/szTheory/relyra/commit/4339dcae87ba29f995f6635b3546b006fb19eab4))
* **15-01:** create connection list, detail components and normalize risk flag names ([0bdf7b1](https://github.com/szTheory/relyra/commit/0bdf7b1c7d46bdad7e56b11ffa4dabc87ef90ea2))
* **15-02:** extract connection form and preset picker components ([e133380](https://github.com/szTheory/relyra/commit/e133380c72d11694d3291acacb308a3eb3242d79))
* **15-02:** wire URL-driven presets to the form ([50640b8](https://github.com/szTheory/relyra/commit/50640b8c286bdc983caf41ec7143f86e96c1e775))
* **15-03:** embed risk panel across relevant views ([4916649](https://github.com/szTheory/relyra/commit/4916649b8a58718d8ca18419930e5ce5b78e886d))
* **15-03:** wire lifecycle events to Ecto boundaries and add status badges ([0a16b0a](https://github.com/szTheory/relyra/commit/0a16b0a0c36b0abffd3635b21838afe569bcebae))
* **16-01:** establish metadata liveview skeleton and route (and missing 15-01 files) ([c52a008](https://github.com/szTheory/relyra/commit/c52a00895a66c2742a368cad9474064caee57c06))
* **16-02:** add active highlighting to metadata history stream ([8ee6076](https://github.com/szTheory/relyra/commit/8ee60768187ecf0f9490a5893e0c86920a19f8f5))
* **16-03:** finalize Phase 16 execution and verification ([43ce682](https://github.com/szTheory/relyra/commit/43ce682265a447e3b36470e2104617cae4350598))
* **16-03:** implement async manual metadata refresh ([50a0ebd](https://github.com/szTheory/relyra/commit/50a0ebd49ab83131538f8cbea4576387aed29784))
* **17-01:** handle optimistic locking conflicts on certificate updates ([8400944](https://github.com/szTheory/relyra/commit/840094414900683b8bc4fcd8b999ea76ed316e04))
* **17-01:** implement semantic slot-based timeline UI for certificates ([cf7f016](https://github.com/szTheory/relyra/commit/cf7f0169449c04e4074563a6f8b7605356ccd373))
* **17-02:** implement 3-step staged rollover with typed verification ([0399604](https://github.com/szTheory/relyra/commit/03996043bfc780386e592d4f7d73f4c7ef3e969e))
* **18-01:** implement typed mapping forms in live admin ([15bb5f4](https://github.com/szTheory/relyra/commit/15bb5f4e8b415fd111392bd79ae764672b6a3b3c))
* **18-02:** implement audit timeline filtering and expandable details ([7ced8fc](https://github.com/szTheory/relyra/commit/7ced8fc9d8841da56f05f5871d92e31bc836b562))
* **19-01:** implement allow_idp_initiated flag for connections ([26e822c](https://github.com/szTheory/relyra/commit/26e822c66866cd357630eeb208afd97c7b5853cb))
* **19-02:** implement safe local redirect utility ([4fab9cf](https://github.com/szTheory/relyra/commit/4fab9cf7d7dbefeb4fc1d4fe1e7ff62938090388))
* **19:** implement IdP-initiated SSO support and result normalization ([101e2a6](https://github.com/szTheory/relyra/commit/101e2a6bd1cf3ebe548bbaf5f7a1e4f015b6ea83))
* **20-01:** implement BulkActions coordinator ([69be2d9](https://github.com/szTheory/relyra/commit/69be2d95556f53247d4789dee57ba2608b360e0b))
* **20-02:** add multi-select UI to ConnectionList ([4c3bf15](https://github.com/szTheory/relyra/commit/4c3bf1513ec47e96526168d2d8c722b3a1db9e14))
* **20:** implement bulk operations for connections and UI multi-selection ([6e75525](https://github.com/szTheory/relyra/commit/6e75525518ad5e3b0e8851328b537d52b7860a59))
* **21-01:** add migration extending relyra_metadata_sources with auto-refresh ([7dcf2ea](https://github.com/szTheory/relyra/commit/7dcf2eaddbbe54cb10033a37ae2ac2fa2f257eab))
* **21-01:** extend MetadataSource schema with auto-refresh fields and changesets ([d8eb04b](https://github.com/szTheory/relyra/commit/d8eb04b96835dc357f9c9a350936fc16e4c6c4dc))
* **21-02:** pure cadence + backoff helpers with property-style jitter envelopes ([7cfbf02](https://github.com/szTheory/relyra/commit/7cfbf02f33b89a1aeadc9b19e93ada8b656d96bd))
* **21-02:** pure failure classifier with one clause per Phase-21 error code ([f8620bf](https://github.com/szTheory/relyra/commit/f8620bf1839b2a5ffe11656bf57bc2e7d2382ea9))
* **21-03:** add TrustAnchor + DriftDetector pure helpers ([1c02e38](https://github.com/szTheory/relyra/commit/1c02e382a88a635b2526ba28c8e5062e49f96c00))
* **21-03:** relocate security corpus + add CorpusGate runtime gate ([9400a0d](https://github.com/szTheory/relyra/commit/9400a0d22b30807cf83c93f30897acb32ce8999f))
* **21-04:** add MetadataApply.resume_auto_refresh/3 single-tx Resume seam ([b94ce16](https://github.com/szTheory/relyra/commit/b94ce16cfa8ea2fec19b4352c0ec5cae05be3847))
* **21-04:** add Signature.verify_metadata_root/4 metadata-root shim ([35a3da4](https://github.com/szTheory/relyra/commit/35a3da421d8f2bc1ed46dec8308bedd540d03a85))
* **21-04:** wrap record_attempt in transact and co-commit health state ([2de8899](https://github.com/szTheory/relyra/commit/2de8899d1978e0fc56d72b26ae4a806179b1742e))
* **21-05:** add OptionalDeps.Oban gateway and Workers.MetadataRefresh ([ff88242](https://github.com/szTheory/relyra/commit/ff8824243ecaa2a897e71a8f84dc1f2965b285ff))
* **21-05:** add Scheduler.run_due/2 and AutoRefresh.refresh/2 wrapper ([3b60a04](https://github.com/szTheory/relyra/commit/3b60a04fe9a1130279c487f4a3c320ccb31ecd62))
* **21-06:** add Auto-refresh health card + Resume now to ConnectionMetadataLive ([35a4cc7](https://github.com/szTheory/relyra/commit/35a4cc7fa5e2e849090b0bb6432b0fab4bc5d2d0))
* **21-06:** surface auto_refresh_health on the connection list (D-29) ([67da767](https://github.com/szTheory/relyra/commit/67da7679283fe0bf0c37541ee0bd8d1e3b6a35de))
* **21-07:** add Metadata.pin_trust_fingerprint/3 + two operator Mix tasks ([aa25260](https://github.com/szTheory/relyra/commit/aa252604bfc77e8ed01e8c03c50af89823f19164))
* **21-07:** add optional Oban dep, ci.oban_smoke alias, README operations ([f4bf983](https://github.com/szTheory/relyra/commit/f4bf983274dad37d3d08077cd95bcb7f837955fe))
* **21-07:** document auto_refresh telemetry catalog + LogAlerts handler ([06ca068](https://github.com/szTheory/relyra/commit/06ca0682e206db1128eba971153928ce01807ad1))
* **21.1-01:** forward audit context from Refresh.refresh/2 into apply_revision and record_attempt (closes CFG-07) ([80d9001](https://github.com/szTheory/relyra/commit/80d90015568de164db3e67f49299abd646093f6a))
* **22-01:** implement certificate expiry traversal engine ([13bf7f8](https://github.com/szTheory/relyra/commit/13bf7f89d819be8c03f1f02099b92c7fb1d04fd4))
* **22-01:** implement telemetry for expiring certificates ([eef99d4](https://github.com/szTheory/relyra/commit/eef99d4cc99437d09b5ab57add8cbbecc3f6bdae))
* **23-01:** build diagnostic bundle orchestration service ([9b4250c](https://github.com/szTheory/relyra/commit/9b4250c66f59cc3caf29c8bdd50cd3f4a29c8583))
* **23-01:** implement explicit redaction AllowList for diagnostic exports ([74a6efb](https://github.com/szTheory/relyra/commit/74a6efb4c30d6e8cd08c640fd59655efdc43d632))
* **23-02:** add download diagnostic bundle UI button to admin UI ([fe394bf](https://github.com/szTheory/relyra/commit/fe394bf34c3ccff42d191aa899d901b80ea3a0c1))
* **23-02:** create mix task for CLI diagnostic bundle export ([1f074ba](https://github.com/szTheory/relyra/commit/1f074baa58580c47652392720fe8fd70b2c90286))
* **23-02:** implement HTTP download endpoint for diagnostic bundle ([7ce0184](https://github.com/szTheory/relyra/commit/7ce0184862eec9abd79fe12bae4cf7539c6cad8c))
* **24-01:** implement request store type injection ([aff2a30](https://github.com/szTheory/relyra/commit/aff2a30410af444a377acfe95cd5583eb4732573))
* **24-01:** implement session revocation adapter support ([f425c18](https://github.com/szTheory/relyra/commit/f425c1886d19ec03c607b4355c93ed49ba8e1aae))
* **24-02:** implement LogoutRequest builder ([9bfd22c](https://github.com/szTheory/relyra/commit/9bfd22c68868374e178432966762dccf0fb9ae2f))
* **24-03:** implement logout bindings parser for redirect ([d4654ee](https://github.com/szTheory/relyra/commit/d4654ee1861cc1d31df788d6c55a95d33da67486))
* **25-01:** add shared conformance fixture loader ([1f98ee5](https://github.com/szTheory/relyra/commit/1f98ee5393ce56f4f792069ae2b05f04e779dc79))
* **25-01:** harden PureBeam seam behavior ([e8cfab9](https://github.com/szTheory/relyra/commit/e8cfab925f490227469de633565e3310431e0df6))
* **25-02:** expand pinned security regression corpus ([c80b6ab](https://github.com/szTheory/relyra/commit/c80b6abad012ce0380ed349925cee1703734c3cb))
* **25-02:** implement SP conformance lane ([9c3e79a](https://github.com/szTheory/relyra/commit/9c3e79a7e8aa0e14b05506a4fb1ed9dcfccd9360))
* **25-03:** generate conformance report from manifest state ([a9a7d58](https://github.com/szTheory/relyra/commit/a9a7d58ba50ad43b06ccd90dd3e88b5f55ee5a2d))
* **27-03:** add batteries included proof artifact ([0b1ffc9](https://github.com/szTheory/relyra/commit/0b1ffc9ee310762c8023283d6c67f16290fe5b78))


### Bug Fixes

* **01-03:** stabilize security aliases and verification lanes ([e850c7f](https://github.com/szTheory/relyra/commit/e850c7f519ae34e7e7d6322e30f86e157093c8a0))
* **02-01:** align request primitives with verification gate checks ([1938caf](https://github.com/szTheory/relyra/commit/1938caf14dca222946310c98cb2fd8a43484eb22))
* **02-02:** format signature policy and binding files ([ff0b471](https://github.com/szTheory/relyra/commit/ff0b47134611c4e7d6f080f97852393358ac06a3))
* **02-03:** format consume pipeline sources ([a07ed0d](https://github.com/szTheory/relyra/commit/a07ed0d2b89f5d246335813e83ad22f7c2ffbbbe))
* **03-01:** format contract defaults for strict verification ([7066eda](https://github.com/szTheory/relyra/commit/7066edaa0d9a8b52ea64f4f94c1c4d5a311f5651))
* **12-12-02:** preserve staged metadata apply semantics ([c5c937e](https://github.com/szTheory/relyra/commit/c5c937e98328aa2d8453cef169216eed99d21742))
* **12-12-02:** repair refresh candidate seam ([206bdd5](https://github.com/szTheory/relyra/commit/206bdd5d37a3a069e69a22831f31d6e4f4874028))
* **21.2:** revise plans based on checker feedback ([5030090](https://github.com/szTheory/relyra/commit/50300902892804667df387ea2ea3a591910beef4))
* **test:** ensure MetadataRefresh is loaded before function_exported? check ([abc24fa](https://github.com/szTheory/relyra/commit/abc24fafaa9513d5aad7404a886bfdcb2a0ec149))

## 1.0.0 (2026-05-08)


### Features

* **01-02:** add pure-beam XML adapter baseline ([68f1041](https://github.com/szTheory/relyra/commit/68f10410571ab85683b98f92f587023c20527c81))
* **01-02:** add stable Relyra.Error contract ([5077f9d](https://github.com/szTheory/relyra/commit/5077f9d5c821f632fb5dbc68c4f319503d13e103))
* **01-02:** freeze hardened XML seam behaviour ([ed7257e](https://github.com/szTheory/relyra/commit/ed7257ef348c6971f2f1aed424492201bbc1e3c9))
* **01-03:** add compile-time parser path guard ([74bac6e](https://github.com/szTheory/relyra/commit/74bac6ea6f1cdd4d327bfc6e526c7b7627956c4a))
* **02-01:** add protocol and relay state contract tests ([9225186](https://github.com/szTheory/relyra/commit/92251860354e774af875f8f73ac6deb7a3081bb4))
* **02-01:** enforce opaque relay state contract ([d21697f](https://github.com/szTheory/relyra/commit/d21697ff62509c8332c7895dd17dd3bbc8842f0c))
* **02-01:** implement login request and binding primitives ([b0d49b6](https://github.com/szTheory/relyra/commit/b0d49b62eec3354619e5b9a97476407d672f4803))
* **02-02:** bind signature verification to exact signed node ([2aeba97](https://github.com/szTheory/relyra/commit/2aeba972d43391175a94c7793b63c6a5709abc48))
* **02-02:** enforce strict signature algorithm policy ([88d43db](https://github.com/szTheory/relyra/commit/88d43db06a3cd8e4698308c22a751eaf59ceb47a))
* **02-03:** add ordered consume response pipeline ([d7db968](https://github.com/szTheory/relyra/commit/d7db96837f63539bc8a52ac4bdc7cfb5b460cee5))
* **02-03:** add response and assertion validators ([47981a2](https://github.com/szTheory/relyra/commit/47981a28af7ae1c52e43de68956494f5529d9e52))
* **03-01:** add fail-closed default adapter scaffolding ([f4acf93](https://github.com/szTheory/relyra/commit/f4acf932704ff6457defbe704fc36a9037448ef7))
* **03-01:** freeze phase 3 behaviour contracts ([9841e09](https://github.com/szTheory/relyra/commit/9841e09257e052094ece31015781b32c2c07ad5d))
* **03-02:** add atomic ETS request and replay adapters ([223cb72](https://github.com/szTheory/relyra/commit/223cb726d147a031d4da2339c2e097e4045087ad))
* **03-02:** add optional Ecto-backed request and replay stores ([4a801f9](https://github.com/szTheory/relyra/commit/4a801f9c9b9002b2482c7972125c9972c8094e26))
* **03-03:** persist request intent and gate consume success ([a6cf9aa](https://github.com/szTheory/relyra/commit/a6cf9aad4452392714b500683ccdedfe3a936110))
* **05-01:** add telemetry catalog and event spans ([07b503f](https://github.com/szTheory/relyra/commit/07b503f697de2aa91dfc3aa25740f0c3a1527574))
* **06-01:** add provider presets, TestSupport, installer, and docs ([670ee92](https://github.com/szTheory/relyra/commit/670ee926b6ec017ae31bf7af234187f1990734a7))
* **06-01:** close release-discipline gap and add provider audience hint ([bdb7c9a](https://github.com/szTheory/relyra/commit/bdb7c9a8f6c5a3eb7e2e20a535419ed9228daccc))
* **11-02:** add mapping persistence migration coverage ([06856c6](https://github.com/szTheory/relyra/commit/06856c66295121a75ab1cda3ab1893c0a0ee3376))
* **11-03:** harden audited trust mutations ([c546b6b](https://github.com/szTheory/relyra/commit/c546b6b8d501ca7f9e9c0d903e8b93f0345ad724))
* **11-04:** persist and hydrate mapping config ([dd9da43](https://github.com/szTheory/relyra/commit/dd9da43e009b7bc1447ae0f994ee3bb43ec03ec4))
* **12-12-01:** canonicalize metadata certificate candidates ([6d5d652](https://github.com/szTheory/relyra/commit/6d5d65235b2adf4c24fe8b42cb5e42dc72e0e5b4))
* **14-01:** author 11-VERIFICATION.md with serial CFG-05 packet ([4339dca](https://github.com/szTheory/relyra/commit/4339dcae87ba29f995f6635b3546b006fb19eab4))
* **15-01:** create connection list, detail components and normalize risk flag names ([0bdf7b1](https://github.com/szTheory/relyra/commit/0bdf7b1c7d46bdad7e56b11ffa4dabc87ef90ea2))
* **15-02:** extract connection form and preset picker components ([e133380](https://github.com/szTheory/relyra/commit/e133380c72d11694d3291acacb308a3eb3242d79))
* **15-02:** wire URL-driven presets to the form ([50640b8](https://github.com/szTheory/relyra/commit/50640b8c286bdc983caf41ec7143f86e96c1e775))
* **15-03:** embed risk panel across relevant views ([4916649](https://github.com/szTheory/relyra/commit/4916649b8a58718d8ca18419930e5ce5b78e886d))
* **15-03:** wire lifecycle events to Ecto boundaries and add status badges ([0a16b0a](https://github.com/szTheory/relyra/commit/0a16b0a0c36b0abffd3635b21838afe569bcebae))
* **16-01:** establish metadata liveview skeleton and route (and missing 15-01 files) ([c52a008](https://github.com/szTheory/relyra/commit/c52a00895a66c2742a368cad9474064caee57c06))
* **16-02:** add active highlighting to metadata history stream ([8ee6076](https://github.com/szTheory/relyra/commit/8ee60768187ecf0f9490a5893e0c86920a19f8f5))
* **16-03:** finalize Phase 16 execution and verification ([43ce682](https://github.com/szTheory/relyra/commit/43ce682265a447e3b36470e2104617cae4350598))
* **16-03:** implement async manual metadata refresh ([50a0ebd](https://github.com/szTheory/relyra/commit/50a0ebd49ab83131538f8cbea4576387aed29784))
* **17-01:** handle optimistic locking conflicts on certificate updates ([8400944](https://github.com/szTheory/relyra/commit/840094414900683b8bc4fcd8b999ea76ed316e04))
* **17-01:** implement semantic slot-based timeline UI for certificates ([cf7f016](https://github.com/szTheory/relyra/commit/cf7f0169449c04e4074563a6f8b7605356ccd373))
* **17-02:** implement 3-step staged rollover with typed verification ([0399604](https://github.com/szTheory/relyra/commit/03996043bfc780386e592d4f7d73f4c7ef3e969e))
* **18-01:** implement typed mapping forms in live admin ([15bb5f4](https://github.com/szTheory/relyra/commit/15bb5f4e8b415fd111392bd79ae764672b6a3b3c))
* **18-02:** implement audit timeline filtering and expandable details ([7ced8fc](https://github.com/szTheory/relyra/commit/7ced8fc9d8841da56f05f5871d92e31bc836b562))
* **19-01:** implement allow_idp_initiated flag for connections ([26e822c](https://github.com/szTheory/relyra/commit/26e822c66866cd357630eeb208afd97c7b5853cb))
* **19-02:** implement safe local redirect utility ([4fab9cf](https://github.com/szTheory/relyra/commit/4fab9cf7d7dbefeb4fc1d4fe1e7ff62938090388))
* **19:** implement IdP-initiated SSO support and result normalization ([101e2a6](https://github.com/szTheory/relyra/commit/101e2a6bd1cf3ebe548bbaf5f7a1e4f015b6ea83))
* **20-01:** implement BulkActions coordinator ([69be2d9](https://github.com/szTheory/relyra/commit/69be2d95556f53247d4789dee57ba2608b360e0b))
* **20-02:** add multi-select UI to ConnectionList ([4c3bf15](https://github.com/szTheory/relyra/commit/4c3bf1513ec47e96526168d2d8c722b3a1db9e14))
* **20:** implement bulk operations for connections and UI multi-selection ([6e75525](https://github.com/szTheory/relyra/commit/6e75525518ad5e3b0e8851328b537d52b7860a59))
* **21-01:** add migration extending relyra_metadata_sources with auto-refresh ([7dcf2ea](https://github.com/szTheory/relyra/commit/7dcf2eaddbbe54cb10033a37ae2ac2fa2f257eab))
* **21-01:** extend MetadataSource schema with auto-refresh fields and changesets ([d8eb04b](https://github.com/szTheory/relyra/commit/d8eb04b96835dc357f9c9a350936fc16e4c6c4dc))
* **21-02:** pure cadence + backoff helpers with property-style jitter envelopes ([7cfbf02](https://github.com/szTheory/relyra/commit/7cfbf02f33b89a1aeadc9b19e93ada8b656d96bd))
* **21-02:** pure failure classifier with one clause per Phase-21 error code ([f8620bf](https://github.com/szTheory/relyra/commit/f8620bf1839b2a5ffe11656bf57bc2e7d2382ea9))
* **21-03:** add TrustAnchor + DriftDetector pure helpers ([1c02e38](https://github.com/szTheory/relyra/commit/1c02e382a88a635b2526ba28c8e5062e49f96c00))
* **21-03:** relocate security corpus + add CorpusGate runtime gate ([9400a0d](https://github.com/szTheory/relyra/commit/9400a0d22b30807cf83c93f30897acb32ce8999f))
* **21-04:** add MetadataApply.resume_auto_refresh/3 single-tx Resume seam ([b94ce16](https://github.com/szTheory/relyra/commit/b94ce16cfa8ea2fec19b4352c0ec5cae05be3847))
* **21-04:** add Signature.verify_metadata_root/4 metadata-root shim ([35a3da4](https://github.com/szTheory/relyra/commit/35a3da421d8f2bc1ed46dec8308bedd540d03a85))
* **21-04:** wrap record_attempt in transact and co-commit health state ([2de8899](https://github.com/szTheory/relyra/commit/2de8899d1978e0fc56d72b26ae4a806179b1742e))
* **21-05:** add OptionalDeps.Oban gateway and Workers.MetadataRefresh ([ff88242](https://github.com/szTheory/relyra/commit/ff8824243ecaa2a897e71a8f84dc1f2965b285ff))
* **21-05:** add Scheduler.run_due/2 and AutoRefresh.refresh/2 wrapper ([3b60a04](https://github.com/szTheory/relyra/commit/3b60a04fe9a1130279c487f4a3c320ccb31ecd62))
* **21-06:** add Auto-refresh health card + Resume now to ConnectionMetadataLive ([35a4cc7](https://github.com/szTheory/relyra/commit/35a4cc7fa5e2e849090b0bb6432b0fab4bc5d2d0))
* **21-06:** surface auto_refresh_health on the connection list (D-29) ([67da767](https://github.com/szTheory/relyra/commit/67da7679283fe0bf0c37541ee0bd8d1e3b6a35de))
* **21-07:** add Metadata.pin_trust_fingerprint/3 + two operator Mix tasks ([aa25260](https://github.com/szTheory/relyra/commit/aa252604bfc77e8ed01e8c03c50af89823f19164))
* **21-07:** add optional Oban dep, ci.oban_smoke alias, README operations ([f4bf983](https://github.com/szTheory/relyra/commit/f4bf983274dad37d3d08077cd95bcb7f837955fe))
* **21-07:** document auto_refresh telemetry catalog + LogAlerts handler ([06ca068](https://github.com/szTheory/relyra/commit/06ca0682e206db1128eba971153928ce01807ad1))
* **21.1-01:** forward audit context from Refresh.refresh/2 into apply_revision and record_attempt (closes CFG-07) ([80d9001](https://github.com/szTheory/relyra/commit/80d90015568de164db3e67f49299abd646093f6a))
* **22-01:** implement certificate expiry traversal engine ([13bf7f8](https://github.com/szTheory/relyra/commit/13bf7f89d819be8c03f1f02099b92c7fb1d04fd4))
* **22-01:** implement telemetry for expiring certificates ([eef99d4](https://github.com/szTheory/relyra/commit/eef99d4cc99437d09b5ab57add8cbbecc3f6bdae))
* **23-01:** build diagnostic bundle orchestration service ([9b4250c](https://github.com/szTheory/relyra/commit/9b4250c66f59cc3caf29c8bdd50cd3f4a29c8583))
* **23-01:** implement explicit redaction AllowList for diagnostic exports ([74a6efb](https://github.com/szTheory/relyra/commit/74a6efb4c30d6e8cd08c640fd59655efdc43d632))
* **23-02:** add download diagnostic bundle UI button to admin UI ([fe394bf](https://github.com/szTheory/relyra/commit/fe394bf34c3ccff42d191aa899d901b80ea3a0c1))
* **23-02:** create mix task for CLI diagnostic bundle export ([1f074ba](https://github.com/szTheory/relyra/commit/1f074baa58580c47652392720fe8fd70b2c90286))
* **23-02:** implement HTTP download endpoint for diagnostic bundle ([7ce0184](https://github.com/szTheory/relyra/commit/7ce0184862eec9abd79fe12bae4cf7539c6cad8c))
* **24-01:** implement request store type injection ([aff2a30](https://github.com/szTheory/relyra/commit/aff2a30410af444a377acfe95cd5583eb4732573))
* **24-01:** implement session revocation adapter support ([f425c18](https://github.com/szTheory/relyra/commit/f425c1886d19ec03c607b4355c93ed49ba8e1aae))
* **24-02:** implement LogoutRequest builder ([9bfd22c](https://github.com/szTheory/relyra/commit/9bfd22c68868374e178432966762dccf0fb9ae2f))
* **24-03:** implement logout bindings parser for redirect ([d4654ee](https://github.com/szTheory/relyra/commit/d4654ee1861cc1d31df788d6c55a95d33da67486))
* **25-01:** add shared conformance fixture loader ([1f98ee5](https://github.com/szTheory/relyra/commit/1f98ee5393ce56f4f792069ae2b05f04e779dc79))
* **25-01:** harden PureBeam seam behavior ([e8cfab9](https://github.com/szTheory/relyra/commit/e8cfab925f490227469de633565e3310431e0df6))
* **25-02:** expand pinned security regression corpus ([c80b6ab](https://github.com/szTheory/relyra/commit/c80b6abad012ce0380ed349925cee1703734c3cb))
* **25-02:** implement SP conformance lane ([9c3e79a](https://github.com/szTheory/relyra/commit/9c3e79a7e8aa0e14b05506a4fb1ed9dcfccd9360))
* **25-03:** generate conformance report from manifest state ([a9a7d58](https://github.com/szTheory/relyra/commit/a9a7d58ba50ad43b06ccd90dd3e88b5f55ee5a2d))
* **27-03:** add batteries included proof artifact ([0b1ffc9](https://github.com/szTheory/relyra/commit/0b1ffc9ee310762c8023283d6c67f16290fe5b78))


### Bug Fixes

* **01-03:** stabilize security aliases and verification lanes ([e850c7f](https://github.com/szTheory/relyra/commit/e850c7f519ae34e7e7d6322e30f86e157093c8a0))
* **02-01:** align request primitives with verification gate checks ([1938caf](https://github.com/szTheory/relyra/commit/1938caf14dca222946310c98cb2fd8a43484eb22))
* **02-02:** format signature policy and binding files ([ff0b471](https://github.com/szTheory/relyra/commit/ff0b47134611c4e7d6f080f97852393358ac06a3))
* **02-03:** format consume pipeline sources ([a07ed0d](https://github.com/szTheory/relyra/commit/a07ed0d2b89f5d246335813e83ad22f7c2ffbbbe))
* **03-01:** format contract defaults for strict verification ([7066eda](https://github.com/szTheory/relyra/commit/7066edaa0d9a8b52ea64f4f94c1c4d5a311f5651))
* **12-12-02:** preserve staged metadata apply semantics ([c5c937e](https://github.com/szTheory/relyra/commit/c5c937e98328aa2d8453cef169216eed99d21742))
* **12-12-02:** repair refresh candidate seam ([206bdd5](https://github.com/szTheory/relyra/commit/206bdd5d37a3a069e69a22831f31d6e4f4874028))
* **21.2:** revise plans based on checker feedback ([5030090](https://github.com/szTheory/relyra/commit/50300902892804667df387ea2ea3a591910beef4))
* **test:** ensure MetadataRefresh is loaded before function_exported? check ([abc24fa](https://github.com/szTheory/relyra/commit/abc24fafaa9513d5aad7404a886bfdcb2a0ec149))

## [Unreleased]

## [0.1.0] - 2026-05-08

### Added

- Initial public release of the strict-by-default SAML 2.0 SP surface.
- Provider presets for Okta, Entra, and Google Workspace.
- `Relyra.TestSupport`, `Relyra.TestSupport.FakeIdP`, and installer scaffolding.
- Release hardening metadata, parity checks, and release-time prerequisite guidance.
