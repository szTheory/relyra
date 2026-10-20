# Stack Research: v1.12 Adversarial Twin

**Domain:** Adversarial, generative, mutation, real-IdP, and chaos testing for a strict SAML 2.0 SP library (Elixir/Phoenix)
**Researched:** 2026-10-19
**Confidence:** HIGH for property testing, concurrency, and clock control. MEDIUM for the mutation-testing engine (the tools are young) and for SimpleSAMLphp. MEDIUM-LOW for scripting Shibboleth IdP login.

**Scope rule:** this covers only what the five new v1.12 capabilities need. The existing stack (Elixir 1.19.5 / OTP 27-28, saxy, pure-BEAM C14N, `:public_key`, Ecto/Postgres, Phoenix 1.8, LiveAdmin, FakeIdP, Keycloak + Traefik, Playwright, a single `ci-gate`) is taken as validated and is not re-researched.

**Bottom line:** the milestone needs **two new Hex deps, both test-only**: `stream_data` and `mutare`. A third, `mutare_ecto`, is added only if the Ecto replay store is in mutation scope. It also needs **two new container images, canary-only**: `cirrusid/simplesamlphp` and `i2incommon/shib-idp`. Everything else (chaos, clock skew, response capture, the persona journey) is built from tools the repo already has: `Ecto.Adapters.SQL.Sandbox`, Postgres features, the `:now` option that already exists, Playwright, and `lazy_html`. Do not add toxiproxy, testcontainers, PropCheck, Mimic/meck, or libfaketime.

---

## Recommended Stack

### Core Technologies (new)

| Technology | Version (verified) | Purpose | Why Recommended |
|------------|--------------------|---------|-----------------|
| `stream_data` | **1.4.0** (hex.pm, 2026-07-14; Apache-2.0; Elixir `~> 1.14`; zero runtime deps) | Property-based mutation of signed SAML responses via `ExUnitProperties.check all` | It is the canonical Elixir PBT library: maintained by whatyouhide (an Elixir core team member), with 1.5M recent downloads and a last push 2026-09. It integrates with ExUnit, so the property seed follows `mix test --seed`, which gives deterministic merge-lane replay. Its integrated shrinking works on *generator composition*. That is what structure-aware mutation needs: generate a **list of mutation operations** (`{:wrap_assertion, path}`, `{:dup_element, idx}`, `{:ns_rebind, prefix}`, `{:truncate, n}`...), apply them to a known-good signed fixture, and StreamData shrinks a failure to the minimal op list. That minimal list becomes the permanent `ci.security` corpus row. v1.4.0's change to `one_of/1` (it now shrinks toward earlier elements) makes shrinking toward "simplest op first" more predictable. |
| `mutare` | **0.5.1** (hex.pm, 2026-10-04; MIT; Elixir `~> 1.18`; deps: `sourceror ~> 1.12.3`, optional `igniter`) | Mutation testing of the security core (signature, digest, audience, time window, replay) | **Compile-once metamutant**: all mutants are embedded behind runtime switches and selected by `MUTARE_ACTIVE_MUTANT`. **Each mutant runs in a fresh `mix test` OS process.** That matches Relyra's existing invariant that every security suite is its own `cmd mix test` process. Mutants never hot-swap modules into a shared VM, which avoids collisions with FakeIdP's `:persistent_term` keypair and with ETS stores. It has coverage-guided per-test selection, `--only lib/relyra/security`, `--min-score` / `--max-no-coverage 0` gates, JSON/SARIF reports (the "mutation score as diminishing-returns metric" artifact), `# mutare:ignore[family] reason` for documented equivalent mutants, per-mutant timeouts, and `--max-heap-mb`. The last two keep a mutant that loops forever in the C14N/parser from OOM-ing the runner. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mutare_ecto` | 0.4.2 (2026-10-04, MIT) | Lets mutare route Ecto query macros correctly | **Only if** `lib/relyra/replay_store/ecto.ex` / `request_store/ecto.ex` are in mutation scope. They should be: the replay check is a named target. Skip it if the replay mutation scope is the ETS adapter plus `replay_store.ex` only. |
| `saxy` (existing, 1.6.x) | already locked 1.6.0; 1.6.1 available | **Test-side** crafting of attacker documents (`Saxy.SimpleForm` + `Saxy.encode!`) inside `test/support` generators | Use it only to *build* mutated inputs, never to judge them. `ParserPathGuard` scans `lib/**` only, so test-support use is allowed. Mutations that must survive byte-exactly (whitespace inside `SignedInfo`, attribute order, namespace prefix rebinding) should be **byte/string-level splices** on the fixture, not a re-serialize round trip, because the round trip normalizes the very thing being attacked. |
| `lazy_html` (existing, test-only) | locked | Extracting `SAMLResponse` from IdP auto-POST HTML forms during canary capture (fallback path) | Only if capture is done over HTTP instead of in Playwright (see the capture pattern below). |
| `req` (existing, optional) | `~> 0.5` | Fetching live IdP metadata (cert + SSO URL) in canary jobs | Already present; no change. |
| `@playwright/test` (existing npm dev-dep) | pinned `^1.54.2`; latest **1.64.1** | (a) Drives IdP login forms for real-IdP capture; (b) the customer-IT-admin persona journey through LiveAdmin connection testing and attribute preview | It already owns the browser harness (`playwright.*.config.mjs`, Keycloak proxy e2e). It handles cookies, redirects, and JS login pages for all three IdPs with one driver. A bump to 1.64.x is optional and separate. Keep the `mcr.microsoft.com/playwright:vX-jammy` image tag in lockstep with the npm version. |

### Container Images (scheduled canaries only, never merge gates)

| Image | Pin to | Purpose | Notes |
|-------|--------|---------|-------|
| `quay.io/keycloak/keycloak` | currently `26.0.7` in repo; latest **26.8.1** (2026-10-13) | Keycloak fidelity corpus | Keep the existing `26.0.7` pin for the external-IdP lane. Add `26.8.1` to the **fidelity canary** so the corpus captures current-Keycloak output. Drift between the two tags is exactly the signal the canary exists to surface. |
| `cirrusid/simplesamlphp` | **`v2.5.0`** (Docker Hub, 2026-03-16; Apache 2.4 + PHP 8.4). Pin by digest. | SimpleSAMLphp IdP fidelity corpus | There is **no official SimpleSAMLphp image**. `simplesamlphp/docker-simplesamlphp` was last pushed 2024-01. Cirrus Identity's image is the maintained one: the repo was pushed 2026-05, and Cirrus Identity are SSP contributors. Config goes in by mounting `config/`, `metadata/saml20-sp-remote.php`, and `cert/` (documented "Test IdP + Setting Configuration Files" mode). It lags upstream (`v2.5.3.1`, 2026-08-09). If the lag matters, build a 10-line `FROM cirrusid/simplesamlphp:v2.5.0` image that composer-updates SSP rather than switching to a stale community image. Use `exampleauth:UserPass` for the authsource. |
| `i2incommon/shib-idp` | **`5.2.3_20261005_rocky9_multiarch`** (Docker Hub, 2026-10-05; tracks Shibboleth IdP 5.2.3; Rocky 9/10, multi-arch). Pin by digest. | Shibboleth IdP fidelity corpus | This is the InCommon/Internet2 TAP image. It is the only actively rebuilt one: roughly monthly through 2026. `unicon/shibboleth-idp` is dead (2019) and `tier/shib-idp` is stale (2024-04). Configuration is mounted under `/opt/shibboleth-idp/{conf,credentials,metadata}`. Generate a baseline config once, commit only non-secret config, and generate the signing keypair per canary run. Login automation needs a password backend. Plan a **spike**: Shibboleth's Password flow normally fronts LDAP, so expect a sidecar (e.g. an OpenLDAP container) or a JAAS file-based module. Not verified; LOW confidence. |
| `postgres:16` (existing CI service) | unchanged | Chaos/concurrency lanes | No new image. Every fault injection below runs inside Postgres itself. |

### Development Tools / Techniques (no new deps)

| Tool | Purpose | Notes |
|------|---------|-------|
| `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` | True multi-connection concurrency (closes WINDOW-29/30) | The root cause of WINDOW-29/30 (`.planning/WINDOWS.md` rows 29-30) is that every process allowed into one sandbox owner shares **one** Postgres connection. A "race" there is serialized and can never prove one-winner semantics. Each racing `Task` calls `unboxed_run(Repo, fn -> ... end)` and so checks out its *own* real connection. The test must be `async: false`, live in its own `cmd mix test` lane, and clean up with the existing `MigrationCase.reset_tables!/0` (plus replay/request/audit tables) in `on_exit`. Test pool size is already 10, which is enough. |
| Postgres lock barrier | Deterministic interleaving without adding hooks to `lib/` | A third connection takes `LOCK TABLE <target> IN EXCLUSIVE MODE` (or `SELECT ... FOR UPDATE` on the contested connection row) inside an open transaction. Start both racers. Poll `pg_stat_activity` / `pg_locks` until **both** backends show `wait_event_type = 'Lock'`, then `ROLLBACK` the barrier. Both racers now provably contend at the database, and the test asserts exactly one `:ok` and one typed conflict or replay rejection. Where lib already exposes hooks (`CertificateInventory` `:after_lock`, `maybe_run_transition_hook/3`), use an in-BEAM `send`/`receive` barrier instead. Both are deterministic, so no sleeps and no retries-until-green. |
| Postgres trigger fault injection | Deterministic "DB failure during audit co-commit" | Create a **test-only** trigger, in test setup SQL and never in `priv/repo/migrations`, on the audit table. It does `RAISE EXCEPTION` when a sentinel is present (e.g. a connection slug or actor equal to `chaos-fail-audit`). The failure fires *inside* the lib-owned `Ecto.Multi`/transaction at the audit insert. That proves the trust mutation and its audit row roll back together (invariant #5). It works even inside the sandbox, because the sandbox uses savepoints. Drop the trigger in `on_exit`. |
| `pg_terminate_backend(pid)` | Connection loss mid-transaction | The racer reports `pg_backend_pid()` (or a hook does, where one exists). A control connection terminates it at the barrier. Assert: the error is a typed `{:error, %Relyra.Error{}}` and not a raised `DBConnection.ConnectionError` leaking out of the public API (a likely finding), nothing partially committed, and the pool recovers. **This requires `unboxed_run`**: killing a sandbox owner's backend poisons the whole sandbox. |
| `SET statement_timeout` / `lock_timeout` | Slow-DB and lock-starvation scenarios | Per-connection `SET` on the unboxed connection. No proxy needed. |
| Existing `:now` option | Clock control / skew | `Relyra.consume_response`, `ValidationPipeline`, `AuthnRequest`, and `RequestStore.ETS` already accept `Keyword.get(opts, :now, DateTime.utc_now())`. Time-boundary properties generate `{issue_instant, not_before, not_on_or_after, now, configured_skew}` tuples around boundaries (exact edge, edge ± 1s, ± skew, DST-irrelevant UTC, year boundaries, leap-second-adjacent `:60` strings as rejected input). The response is signed with those timestamps and validated at the injected `now`. That covers IdP-vs-SP skew fully. |

## Installation

```elixir
# mix.exs deps/0 — all test-only; none can reach the Hex tarball
{:stream_data, "~> 1.4", only: [:dev, :test]},
{:mutare, "0.5.1", only: [:dev, :test], runtime: false},      # exact pin: 0.x, 13 releases in 6 weeks
{:mutare_ecto, "0.4.2", only: [:dev, :test], runtime: false}   # only if Ecto replay store is in scope
```

- `stream_data` needs `only: [:dev, :test]` without `runtime: false`: `ExUnitProperties` must be loaded when tests run. Dev is included so `mix format` accepts the `check all` locals (add `import_deps: [:stream_data]` to `.formatter.exs`).
- Hex-package safety is already structural. `package/0` `files:` lists explicit paths and excludes `mix.lock`, `test/`, and dotfiles such as `.mutare.exs`. `only:` deps are excluded from the published requirements. Add an assertion to the existing `test/release/release_hardening_test.exs` (`ci.release`) that the built tarball's `requirements` contains neither `stream_data` nor `mutare*`. That turns the guarantee into deterministic evidence.
- No npm additions. Optional: bump `@playwright/test` and the compose Playwright image together.

## Integration Points

1. **Generative adversarial lane.** Add a new `cmd mix test test/security/xml/adversarial_property_test.exs --only adversarial_property --warnings-as-errors` line to `ci.security` (its own process, per the hollow-gate invariant enforced by `test/security/ci_gate_integrity_test.exs`, which must be updated to know the new line). Use a fixed seed and a bounded `max_runs` (e.g. 200) in the merge lane. A **scheduled** deep run (new workflow, e.g. nightly, `max_runs` from env, random seed printed) explores further. Shrunk failures are written as fixture files plus a manifest row that `adversarial_crypto_test.exs` (or a sibling corpus test) replays forever. The property oracle is: `{:ok, result}` **and** consumed node == signed node (byte-compare via the `signed_node.ex` reference), **or** `{:error, %Relyra.Error{}}` with an allowlisted reason. Anything raised, any exit, or a timeout beyond the bound is a failure. Run each case in a spawned process with `Process.flag(:max_heap_size, ...)` and a `Task.yield` timeout, so DoS-class findings are caught instead of hanging CI.
2. **Signing in generators.** Reuse `Relyra.TestSupport.FakeIdP` signing for "legitimately signed, then wrapped" XSW cases. Attacker-key re-signing uses a second generated keypair. Never use document `KeyInfo` as a trust source in fixtures (invariant #1); include attacker `KeyInfo` as an attack vector.
3. **Mutation lane.** Use `.mutare.exs` scoped to `lib/relyra/security/signature.ex`, `signed_node.ex`, `algorithm_policy.ex`, `xml/**`, `protocol/validation_pipeline.ex`, `protocol/assertion.ex`/`response.ex` (audience + time checks), and `replay_store/**`. Run it on **`workflow_dispatch` + a weekly schedule**, never in `ci-gate`. Upload the JSON/SARIF report as an artifact. The score trend across rounds is the stopping-rule metric. Run with `--workers 2 --timeout 60000` on a standard runner. Expect tens of minutes for the full security scope; `--since main` keeps PR-triggered manual runs small. The first phase task is a **baseline spike**: mutare's function lifting can break tests that assert exact `FunctionClauseError` frames (use `--skip-lifting` per function), and the custom `:parser_path_guard` compiler plus `ignore_module_conflict: true` must compile cleanly inside mutare's sandbox copy.
4. **Real-IdP fidelity canary.** Add a new scheduled workflow following the existing `adoption-external-idp.yml` pattern: `docker run` with pinned images, readiness poll, `docker logs` on failure, `docker rm -f` always. Capture is **SP-initiated**: Relyra's own `start_login` produces the AuthnRequest to the SSO URL read from live IdP metadata, which avoids guessing per-vendor IdP-initiated URLs. Playwright fills the IdP login form, and `page.route()`/`page.on('request')` intercepts the POST to the ACS and saves the raw `SAMLResponse` plus the IdP signing cert (public only) and the capture timestamp. Merge-lane tests then replay **frozen captured bytes** with `now: captured_at`, so they are deterministic and offline. Only the *live capture-and-diff* is a canary. This keeps "never merge gates" true without losing fidelity coverage.
5. **Chaos lane.** Add a new `ci.chaos` alias or new `cmd mix test` lines (each its own process) using a `Relyra.TestSupport.ChaosCase` that is `async: false`, uses unboxed_run helpers plus barrier and trigger helpers, and truncates in `on_exit`. For WINDOW-29 in `demo/ledger_loop`, the same unboxed approach applies to concurrent ACS submissions. The duplicate-assertion race hits the Ecto replay store's unique constraint on two real connections, which is the actual production guarantee.
6. **Clock seams in lib.** Several `lib/` sites call `DateTime.utc_now()` directly: `replay_store/ecto.ex:34`, `request_store/ecto.ex:244`, `algorithm_policy.ex:222` (escape-hatch expiry), `certificate_expiry.ex:29`, and Ecto trust-mutation timestamps. Protocol-level skew is fully testable today through `:now`. Escape-hatch-expiry and replay-TTL boundary tests may need `:now` threaded into those internals. **Flag:** threading `:now` through `AlgorithmPolicy` touches algorithm-policy code (an escalation category per CLAUDE.md). Treat it as an explicit decision, not an incidental refactor. Do *not* reach for global time mocking instead.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `stream_data` | `propcheck` 1.5.0 / PropEr 1.5.0 | Only if stateful model-based testing (`PropCheck.StateM`) or *targeted* PBT (search toward max document size or depth) becomes necessary. Both are **GPL-3.0**. That is legal for a test-only dep but invites license review friction in an MIT security library, and PropCheck has been effectively idle since 2025-04 (15 open issues). Not needed: mutation-op lists plus StreamData shrinking cover the target surface. |
| `stream_data` | Hand-rolled generators with `:rand` | Never as the primary. You lose shrinking, which is the step that turns a 4 KB failing blob into a one-line corpus row. |
| `mutare` 0.5.1 | `muex` 0.11.3 (MIT, 2026-10-05, 32 stars, 27 releases since 2026-01) | **Fallback if the mutare baseline spike fails.** Muex is more established and has `--fail-at`, `--since`, `--coverage-guided`, and JSON/HTML reports. It recompiles per mutant and **hot-swaps modules** in a running VM, which is a worse fit for Relyra's shared `:persistent_term`/ETS test state and its one-process-per-suite discipline. Mutare's own docs note muex's per-mutant compile cost. |
| `mutare` | Small in-repo AST mutator (Sourceror/`Macro.prewalk` plus a curated mutant list for the five checks) | Only if both external tools fail on Relyra's compiler setup. A curated list of about 30 hand-picked mutants (flip `DigestValue` comparison, skip `:public_key.verify`, invert audience match, off-by-one on `NotOnOrAfter`, no-op replay insert) is a good **sanity floor** to encode as a test regardless. It cannot produce an unbiased mutation score, though, and the stopping rule needs one. |
| `unboxed_run` on the existing repo | Separate non-sandbox `ChaosRepo` against its own database | Only if chaos tests must run concurrently with sandboxed async tests in the same OS process. They do not, since each lane is its own `cmd mix test`. A second repo adds config, migrations, and drift for no benefit. |
| Postgres trigger + `pg_terminate_backend` | Toxiproxy v2.13.0 (`ghcr.io/shopify/toxiproxy`, 2026-10-14) + `toxiproxy_ex` 2.0.1 | Only for network-level faults (latency jitter, half-open TCP, bandwidth). Relyra's chaos questions are transactional ("does the audit co-commit hold when the DB fails *at the audit insert*?"). A proxy cannot aim at a specific statement, so it would make those tests nondeterministic. It also adds a container to every chaos run. |
| Workflow-owned `docker run` | `testcontainers` 2.4.0 (MIT, 2026-07) | Only if containers need per-test lifecycles inside ExUnit. Canaries capture once per run, and the repo's established pattern is workflow-owned containers. Testcontainers would add a Docker-socket dependency to `mix test`. |
| `cirrusid/simplesamlphp:v2.5.0` | `kristophjunge/test-saml-idp` (4.5M pulls) | Never. Last updated 2018, SSP 1.x. It would produce a fidelity corpus of a dead IdP version. Same verdict for `jamedjo/test-saml-idp` (2020) and `unicon/simplesamlphp` (2022). |
| `i2incommon/shib-idp` | `cscfi/shibboleth-idp` (2026-09, ~4.5K pulls) | Only if the InCommon image's config bootstrap proves intractable in the spike. It is maintained, but has a smaller user base and a Finnish-federation-oriented default config. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `muzak` 1.1.1 | License is **CC-BY-NC-ND-4.0** (non-commercial, no-derivatives), last release 2022-12, and "Muzak Pro" is a paid closed product. It is incompatible with an MIT project's CI posture. | `mutare` |
| `exavier` 0.3.0 | Last release 2020-11, 284 recent downloads; predates Elixir 1.12+ compiler changes. | `mutare` |
| `muta` 0.3.0 / `kalku_elixir` | `muta`: 0 stars, 3 releases, single author, Aug 2026. `kalku_elixir`: a worker for an external kalku protocol/orchestrator, which adds infrastructure. | `mutare` |
| Mimic 2.4.2 / `:meck` to stub `DateTime.utc_now/0` | Global module replacement breaks `async: true` suites. In the security core, replacing a stdlib module is itself a parser-differential-style hazard: tests would pass against code that does not exist in production. | The `:now` option; thread it where missing (see Integration point 6) |
| libfaketime / container clock shifting | Nondeterministic, platform-specific (glibc vs musl/alpine), and it cannot be applied to the BEAM's monotonic time sanely. | Generate skewed timestamps in signed fixtures plus the `:now` option |
| Running mutation or canary jobs in `ci-gate` | Mutation runs take tens of minutes and live IdPs are external state. Either would make the single required check slow or flaky, which contradicts "scheduled canaries, never merge gates" and the SEED-004 CI wall-clock work (PR CI ~5 min). | `workflow_dispatch` + `schedule` workflows. Only frozen corpus rows and the bounded-seed property run enter `ci.security`. |
| Generating whole SAML documents from scratch with StreamData | Random XML almost never passes the pre-parse guards, so it fuzzes only the guard layer and never reaches signature/XSW logic. | Mutate a **valid signed baseline** with an op-list generator (structure-aware), plus a separate small pure-fuzz property aimed at the pre-parse guards |
| Re-serializing mutated XML through a tree round trip for signature-sensitive mutations | Normalizes whitespace, namespace prefixes, and attribute quoting: the exact differentials under attack. | Byte-level splices on the fixture; tree editing only for structural ops (wrap, duplicate, move) |
| Floki/SweetXml/xmerl in test helpers | Adds a second XML parser to the dependency graph and muddies the one-parse-path story for reviewers, even if test-only. | `Saxy.SimpleForm` (already a dep) or `lazy_html` for HTML forms |

## Stack Patterns by Variant

**If a property finds a defect:**
- Freeze the shrunk op list and the resulting bytes as a corpus fixture, and add the manifest row to the permanent corpus test
- Because the property run is bounded and seeded, the finding must not depend on rediscovery

**If the mutation score plateaus across two rounds:**
- Record surviving mutants with `# mutare:ignore[family] reason` only when they are proven equivalent. Otherwise list them as residual risk in the evidence contract
- Because the stopping rule needs an auditable reason for every unkilled mutant

**If a canary capture differs from the frozen corpus:**
- Open a corpus-update PR with the new capture as a *new* row. Never overwrite the old row
- Because older IdP output still exists in the field

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `stream_data` 1.4.0 | Elixir `~> 1.14`, so 1.19.5 / OTP 27-28 are fine | No deps. |
| `mutare` 0.5.1 | Elixir `~> 1.18`; `sourceror ~> 1.12.3` (latest 1.12.4) | No `sourceror` in the current lock, so there is no conflict. `igniter` is optional; do **not** use `mix igniter.install mutare` (it would add `usage_rules`/igniter churn). Add deps by hand. |
| `mutare_ecto` 0.4.2 | `ecto` 3.14.2 / `ecto_sql` 3.14.0 (locked) | Verify in the baseline spike. |
| `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` | `ecto_sql` 3.14.0, `db_connection` 2.10.2 (locked) | Long-standing API. |
| `postgrex` | locked 0.22.4 (latest stable) | Ignore the `1.0.0-rc.*` entries on hex; they are from 2016. |
| `cirrusid/simplesamlphp:v2.5.0` | SSP 2.5.0, PHP 8.4 | Upstream is at 2.5.3.1. |
| `i2incommon/shib-idp:5.2.3_20261005_rocky9_multiarch` | Shibboleth IdP 5.2.3 | Rebuilt roughly monthly; pin the digest and bump deliberately. |
| `quay.io/keycloak/keycloak` | 26.0.7 (pinned) / 26.8.1 (latest) | Canary should cover both. |

## Sources

- hex.pm API (`/api/packages/{stream_data,propcheck,proper,muzak,exavier,muex,mutare,mutare_ecto,muta,kalku_elixir,toxiproxy_ex,testcontainers,mimic,postgrex,sourceror}`), queried 2026-10-19. Versions, licenses, release dates, Elixir requirements. HIGH
- stream_data CHANGELOG (github.com/whatyouhide/stream_data). v1.4.0 changes. HIGH
- mutare README (github.com/foxbenjaminfox/mutare, master): compile-once metamutant, fresh `mix test` process per mutant, gates, reports, lifting caveat. MEDIUM (the tool is 6 weeks old with a single maintainer)
- muex README (github.com/Oeditus/muex): hot module swapping, options, reports. MEDIUM
- GitHub API repo activity for whatyouhide/stream_data, alfert/propcheck, Oeditus/muex, foxbenjaminfox/mutare, testcontainers-elixir, Shopify/toxiproxy (v2.13.0, 2026-10-14). HIGH
- Docker Hub API: `cirrusid/simplesamlphp` tags (v2.5.0, 2026-03-16), `i2incommon/shib-idp` tags (5.2.3_20261005), and staleness of `kristophjunge/test-saml-idp`, `unicon/*`, `tier/shib-idp`. HIGH
- quay.io API: `keycloak/keycloak` tags (26.8.1, 2026-10-13). HIGH
- GitHub API: simplesamlphp/simplesamlphp latest release v2.5.3.1 (2026-08-09); cirrusidentity/docker-simplesamlphp README (config mount mode). HIGH/MEDIUM
- [SimpleSAMLphp SP QuickStart](https://simplesamlphp.readthedocs.io/en/latest/simplesamlphp-sp): 2.x `module.php/saml/idp/singleSignOnService` endpoint. IdP-initiated URL shape in 2.x is unverified, which is why SP-initiated capture is recommended. MEDIUM
- [CSCfi shibboleth-idp-dockerized](https://github.com/CSCfi/shibboleth-idp-dockerized), [unicon/shibboleth-idp](https://hub.docker.com/r/unicon/shibboleth-idp), [Gluu oxShibboleth notes](https://gluu.org/docs/de/reference/oxshibboleth/): Shibboleth container config/mount conventions (`/opt/shibboleth-idp`, credentials). MEDIUM
- Repo inspection: `mix.exs` (package `files:`, aliases, `ci.security` hollow-gate comment), `config/test.exs` (Sandbox pool), `test/support/migration_case.ex`, `.planning/WINDOWS.md` rows 29-30 (single sandbox connection root cause), `lib/relyra/ecto/certificate_inventory.ex` (`:after_lock` hook), `DateTime.utc_now` call sites, `.github/workflows/adoption-external-idp.yml`, `package.json` (Playwright ^1.54.2; npm latest 1.64.1). HIGH
