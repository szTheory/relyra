# Pitfalls Research

**Domain:** Adversarial verification of a strict-by-default SAML 2.0 SP library (Elixir/Phoenix). Covers property-based attack generation, mutation testing of the trust core, a real-IdP fidelity corpus, chaos journeys, and a customer-IT-admin persona journey.
**Milestone:** v1.12 Adversarial Twin (phases 80+)
**Researched:** 2026-10-19
**Confidence:** HIGH for repo-specific findings (verified by reading `mix.exs`, `lib/relyra/testing/signer.ex`, `test/test_helper.exs`, `test/support/migration_case.ex`, the `lib/relyra/ecto/*` clock usage, and `test/adoption/external_canary_contract_test.exs`). MEDIUM for tool behavior (StreamData options confirmed in the official docs; Muex behavior comes from its own comparison page). MEDIUM for general testing practice.

Phase labels below are working names. The roadmapper assigns final numbers from 80 onward:

- **P-GEN**: generative adversarial twin (StreamData attack generators, oracle, corpus promotion)
- **P-MUT**: mutation testing of the security core
- **P-IDP**: real-IdP fidelity corpus (Keycloak, SimpleSAMLphp, Shibboleth) as scheduled canaries
- **P-CHAOS**: chaos journeys (WINDOW-29/30 concurrency, DB failure mid audit co-commit, refresh during rollover, clock skew)
- **P-ADMIN**: customer-IT-admin journey (connection test, attribute preview)
- **P-CLOSE**: stopping-rule closeout and residual-risk record

---

## Critical Pitfalls

### Pitfall 1: Vacuous properties (generators that only produce inputs rejected early)

**What goes wrong:**
The property "every mutated response verifies or gets a typed rejection, and never crashes" passes 100% of the time because nearly every generated input dies at the first gate: the size limit, the DTD guard, a saxy parse error, or `:invalid_signature` from a byte flip inside `SignatureValue`. The generator never reaches the stages that matter: C14N, reference resolution and signed-node binding, the audience and time-window checks, and replay. A green run then proves almost nothing.

**Why it happens:**
Random mutation of a signed XML document is extremely likely to break well-formedness or the signature. Mutation operators are written at the byte or string level instead of at the tree level. Nobody measures where each rejection came from.

**How to avoid:**
- Build generators at the **tree level, then re-sign**. Mutate the parsed structure (move the signed `Assertion`, duplicate `Assertion` or `Response` elements, inject an unsigned sibling, rebind `ID`/`Reference URI`, change namespace prefixes, insert whitespace or comments in C14N-sensitive places). Then re-sign with the configured test key where the attack model says the attacker *can* sign: a valid IdP signature over a different node, as in XSW, or a signature by an untrusted key. Signature wrapping is only meaningful when the signature is valid over *something*.
- Split attacks into **two families with different expected outcomes**. (a) Attacker cannot sign: any change to signed content must be rejected with a specific digest or signature atom. (b) Attacker holds a valid signed response and rearranges it (XSW): the result must be rejected, *or* it verifies and the consumed node is byte-identical to the signed node.
- **Classify every outcome** with `StreamData`/`ExUnitProperties` labeling (collect rejection atoms or stages into a histogram) and **assert distribution floors**. Example: at least N% of runs in the XSW family reach reference resolution, and at least one run per family reaches protocol validation. A property whose histogram is 99% `:malformed_xml` fails the build.
- Include a **positive control**: an unmutated (identity-mutated) generated response must verify. That proves the harness can produce acceptance at all.

**Warning signs:**
- The rejection histogram is dominated by one atom (`:malformed_xml`, `:payload_too_large`, `:invalid_signature`).
- No run ever reaches `{:ok, _}`.
- A mutation operator family never produces a distinct atom.
- `StreamData.FilterTooNarrowError` appears. Heavy `filter`s mean the generator is fighting the domain.

**Phase to address:** P-GEN (distribution assertions are part of the phase's acceptance criteria).

---

### Pitfall 2: Tautological oracle (the test re-implements the verifier)

**What goes wrong:**
To decide what the result *should* be, the property calls `Relyra.Security.Signature`, `C14N`, or `PureBeam`, or a hand-written copy of them. The oracle then shares every bug with the system under test. An XSW bypass passes because the oracle makes the same wrong reference-resolution decision.

**Why it happens:**
Computing ground truth for a mutated signed document is hard, and the shared helpers are right there. `Relyra.Testing.Signer` itself canonicalizes "through Relyra's real verifier path (`SaxyTree`, `PureBeam`, and `C14N`)". That is fine for producing fixtures but disqualifying as an oracle.

**How to avoid:**
- Make the oracle **know the answer from construction, not from verification**. The generator emits `{xml, expected}`, where `expected` comes from the mutation applied: `:must_reject` for any change to signed bytes or any untrusted key, and `{:may_accept, signed_node_id}` only for the identity mutation and semantically neutral transforms that are proven neutral (see the next bullet).
- For "is this whitespace/namespace change C14N-neutral?", use an **independent implementation as a differential oracle**: libxml2 via `xmllint --exc-c14n` or `xmlsec1`. The project already byte-proves C14N against libxml2, so reuse that harness. Run it in a nightly lane, not inside the PR property.
- The core invariant needs no oracle: on `{:ok, result}`, assert that the consumed assertion's identity (ID plus canonical bytes) equals the node that the *generator* signed. That is a structural fact the generator already knows.
- Grep-guard: the property test module must not `alias` `Relyra.Security.Signature`, `C14N`, or `AlgorithmPolicy` for oracle purposes. Enforce this with a meta-test like `ci_gate_integrity_test.exs`.

**Warning signs:**
- The oracle function has a branch structure that mirrors `do_verify/4`.
- The property suite never fails when a mutation-testing mutant is injected into `Signature` (P-MUT will expose this).
- `expected` is computed after generation by calling library code.

**Phase to address:** P-GEN. P-MUT verifies it: mutants in `signature.ex` and `c14n.ex` must be killed by the generative suite, not only by `adversarial_crypto_test.exs`.

---

### Pitfall 3: Shrinking that breaks signatures (useless counterexamples)

**What goes wrong:**
A failing case shrinks to a document that fails for a *different* reason. StreamData's default shrinking removes list elements and trims binaries, which invalidates the digest. The reported minimal counterexample is then an uninteresting `:digest_mismatch`, and the real bypass is lost. The reverse also happens: shrinking finds an "acceptance" because a shrunk input lost the element that the check depended on, which is noise.

**Why it happens:**
Shrinking acts on the generated value. If the generated value is the final XML binary, shrinking edits bytes after signing.

**How to avoid:**
- Generate a **mutation plan** (a small data structure: base template parameters, an ordered list of mutation ops, a signing decision). Then *deterministically render and sign* inside the property body. Shrinking then simplifies the plan, which shortens the op list and simplifies parameters, and every shrunk candidate is still a correctly signed document.
- Set `max_shrinking_steps` explicitly (default 100). RSA signing per step is slow, so bound it to keep the failure feedback loop short.
- When a failure is found, persist the **plan, the rendered XML, and the seed** as the corpus row, not just the seed. Seeds are not stable across generator changes.

**Warning signs:**
- Shrunk counterexamples always end in `:digest_mismatch` or `:invalid_signature`.
- The failure message shows a mangled half-document.
- Reproducing a failure needs the original seed *and* the same generator code version.

**Phase to address:** P-GEN.

---

### Pitfall 4: Nondeterministic seeds and flaky or slow PR CI

**What goes wrong:**
Generative tests in the PR lane fail intermittently on new seeds, so PRs go red for reasons unrelated to the diff, and people re-run until green. Alternatively, `max_runs` gets bumped "for coverage" and the PR lane grows past the ~5-minute budget the v1.11 CI ratchet won.

**Why it happens:**
StreamData derives `:initial_seed` from ExUnit's seed by default. CI runs a random seed each time, so every run explores new inputs. That is desirable for discovery and corrosive for merge gating. Per-iteration RSA keygen and signing (the public `Signer` mints a fresh RSA key *per signed response*) multiplies the cost.

**How to avoid:**
- **Two tiers.** The PR tier runs a **fixed-seed, bounded** property (`initial_seed` pinned, `max_runs` small, `max_run_time` capped) *plus* the frozen regression corpus rows. It is deterministic and fast. The exploration tier runs **nightly with random seeds and high `max_runs`**, and on failure it opens an issue or artifact carrying the seed and plan.
- Precompute a small pool of RSA keys once per suite (`setup_all` or `:persistent_term`, the same pattern `test_helper.exs` already uses for `FakeIdP.keypair/0`) instead of a fresh key per iteration.
- A failure found in the exploration tier becomes a deterministic corpus row before it is fixed. Never "fix" it by narrowing the generator.
- Give the PR-tier property suite its own `cmd mix test ... --only adversarial_generative` line in `ci.security` (the hollow-gate rule). Register it in `ci_gate_integrity_test.exs`.

**Warning signs:**
- A PR job is re-run without code changes and turns green.
- The `ci.security` wall-clock rises by more than about 30s.
- Property failures cannot be reproduced locally with `--seed`.

**Phase to address:** P-GEN (lane split). P-CLOSE checks that the CI budget held.

---

### Pitfall 5: The test signer or generative attack tooling becomes reachable from `lib/` or the Hex package

**What goes wrong:**
New attack generators, a "sign arbitrary XML" helper, or an untrusted-key signer land under `lib/relyra/testing/`. `Relyra.Testing.Signer` is **production-compiled and ships in Hex** by explicit v1.9 approval, and `package_lib_files/0` only excludes paths containing `test_support`. Anything else under `lib/` ships, compiles into adopters' prod releases, and becomes public API surface. Even a `@moduledoc false` module is callable.

**Why it happens:**
`lib/relyra/testing/` looks like the natural home. The exclusion rule is a string match (`String.contains?(&1, "test_support")`), so a file named `lib/relyra/testing/xsw_generator.ex` silently ships. Adding a `stream_data` dependency without `only: :test` would also leak it into adopters' dependency trees.

**How to avoid:**
- Put all v1.12 generators, mutation plans, and oracles in **`test/support/`** (compiled only in `:test` through `elixirc_paths`). They must not go under `lib/`, not even `lib/relyra/test_support/`.
- Declare `{:stream_data, "~> 1.x", only: :test}` (and any mutation tool as `only: :test, runtime: false`).
- Extend the existing release-parity and tarball checks (`mix verify.release_parity`, the clean-room package consumer) with an assertion that no module matching `~r/Generator|Mutation|Adversar|Xsw/` appears in the built tarball and that `stream_data` is not a runtime dependency.
- Treat any new public test helper in `Relyra.Testing` as a **public API change, which requires escalation** under CLAUDE.md.

**Warning signs:**
- A new file under `lib/relyra/testing/` in a P-GEN diff.
- `mix hex.build --unpack` contents grow.
- `mix.lock` shows `stream_data` without `only: :test`.
- The package-consumer CI compiles a new module.

**Phase to address:** P-GEN (placement and dependency scoping). The tarball assertion goes into the existing release-parity lane in the same phase.

---

### Pitfall 6: Private keys and secrets committed in fixtures

**What goes wrong:**
Corpus rows promoted from generative failures, or captured real-IdP responses, are committed together with the signing key used to produce them. The repo already contains `test/fixtures/security/authn_request_signing/golden_signing_key.pem` (a deliberate golden key). New keys multiply, secret scanners flag them, and a captured Keycloak realm key or SimpleSAMLphp `server.pem` ends up in git history.

**Why it happens:**
Reproducing a corpus row "needs the key". Containerized IdPs generate realm keys on boot, and the capture script copies the whole export directory.

**How to avoid:**
- Corpus rows store **the signed XML and the public cert only**. The verifier needs nothing else. If re-signing is needed, regenerate from the plan with a pooled test key minted at runtime, never a committed key.
- If a committed key is genuinely required (as for the golden AuthnRequest key), it must be **documented as test-only in a single allowlist file** and enforced by a meta-test that fails on any other `BEGIN .* PRIVATE KEY` under `test/` or `priv/`.
- Real-IdP containers boot with **ephemeral keys per run**. The capture step exports only response XML and the IdP signing certificate.

**Warning signs:**
- `grep -rl "PRIVATE KEY" test priv` count grows.
- GitHub secret-scanning alerts.
- Fixture directories contain `.p12`, `.jks`, `realm-export.json` with `privateKey`, or `server.pem`.

**Phase to address:** P-GEN (corpus promotion format) and P-IDP (capture pipeline). The allowlist meta-test lands in P-GEN.

---

### Pitfall 7: Mutation testing produces noise and runtime blowups instead of a metric

**What goes wrong:**
Pointing a mutation tool at `lib/` produces thousands of mutants, hours of runtime, and a score that is impossible to act on because of **equivalent mutants**. Examples: mutating a log message, a telemetry metadata key, or a `>=` that is equivalent given a prior guard; mutating `Keyword.get(opts, :now, DateTime.utc_now())` defaults. The "mutation score as diminishing-returns metric" then becomes meaningless and people chase 100% on irrelevant code.

**Why it happens:**
Whole-project scope. No exclusion list. Mutants are not triaged once and recorded, so each run re-reports the same survivors. Tooling also matters: Darwin and Exavier have been unmaintained since 2020, and Darwin does not install cleanly on modern Elixir. This project requires `~> 1.19`. Muex is the active option, but it **writes the mutated source to disk, recompiles, runs `mix test` as a subprocess, and restores the original**, which costs 100–200 ms or more per test run.

**How to avoid:**
- **Scope to the named trust core only**: `lib/relyra/security/signature.ex`, `c14n.ex`, `algorithm_policy.ex`, the audience, time-window (`protocol/assertion.ex` `validate_time_conditions`), and signed-node-binding checks, and the replay-store `consume` paths. This is roughly a handful of modules, not `lib/`.
- **Scope the test command per mutant** to the security suites (`test/security/**`, the generative suite, `test/relyra/security/**`), not `mix test` overall. The full suite boots `MigrationCase.bootstrap!()` and `TestGsdTools`, which per-mutant overhead turns into hours.
- Maintain **one committed `equivalent_mutants` ledger** (mutant id, file:line, operator, reason). Report the score over non-equivalent mutants. A surviving mutant is either killed by a new test, recorded as equivalent with a reason, or recorded as residual risk. Nothing is silently ignored.
- Run mutation testing **nightly or manually-dispatched, never in PR CI**, with a hard timeout per mutant (infinite-loop mutants exist).
- Because the tool edits source in place, **run it in a disposable checkout or worktree**, never the working tree. A crashed run can otherwise leave a mutated `signature.ex` on disk, where it could be committed. Add a CI guard: the mutation job verifies `git diff --exit-code lib/` after the run.

**Warning signs:**
- A single mutation run takes more than about 30 minutes.
- The survivor list contains log or telemetry strings.
- The score fluctuates between runs with no code change (flaky tests, or a timeout classed as "killed").
- `git status` shows modified `lib/relyra/security/*` after a local mutation run.

**Phase to address:** P-MUT. The plateau metric definition is consumed by P-CLOSE.

---

### Pitfall 8: Surviving mutants "fixed" by weakening or overfitting tests, or by touching `adversarial_crypto_test.exs`

**What goes wrong:**
To kill survivors, someone edits `test/security/xml/adversarial_crypto_test.exs` (forbidden to weaken) or rewrites assertions to pattern-match exact error strings so mutants die for brittle reasons. In the worst case someone "simplifies" a check in `lib/` to make a mutant equivalent.

**How to avoid:**
- New mutant-killing tests go in **new files** wired as their own `cmd mix test` lines. The adversarial crypto corpus is append-only.
- Assert on **typed rejection atoms and stages**, not message text.
- Any `lib/relyra/security/*` change motivated by mutation results is a security-posture change and follows the escalation rule. Mutation testing is a measurement, not a refactor license.

**Warning signs:** a diff touching `adversarial_crypto_test.exs` with deletions; assertions on `Exception.message/1`; a P-MUT diff that modifies lib security code.

**Phase to address:** P-MUT.

---

### Pitfall 9: Real-IdP container drift and canary flakiness

**What goes wrong:**
Floating image tags (`quay.io/keycloak/keycloak:latest`, an unpinned SimpleSAMLphp image, a community Shibboleth image) change their response shape, default algorithms, or boot time. The canary goes red for reasons unrelated to Relyra and gets ignored. This project already has precedent: the managed-IdP canary was **retired 2026-10-19 because it reported `configuration_incomplete` daily** (see `test/adoption/external_canary_contract_test.exs`). A permanently-red canary has zero signal. Shibboleth IdP v5 needs Java and Jetty plus significant configuration and has no single official turnkey image, so it is the most likely to rot.

**Why it happens:**
Images are pinned by tag, not digest. There are no health-check readiness waits. One workflow runs all three IdPs, so one broken IdP masks the other two. Nobody owns triage.

**How to avoid:**
- **Pin every image by digest** and bump digests deliberately (Dependabot or a scheduled bump PR), the same discipline the repo already applies to GitHub Actions SHAs.
- **One job per IdP** (matrix, `fail-fast: false`), each with a readiness probe on the metadata endpoint and a bounded retry for *boot only*. Never retry the assertion itself.
- **Classify canary outcomes**: `infra_unavailable` (pull or boot failure; neutral, auto-retry next schedule), `fidelity_drift` (the IdP output changed but Relyra's behavior is correct; refresh the captured corpus), and `relyra_regression` (red, open an issue). Only the third is a real alarm.
- **Captured responses become deterministic fixtures.** The canary *refreshes* the corpus. PR CI replays the frozen captures offline. The external service is never in the merge path, as the project constraint requires.
- Time-box Shibboleth: if a deterministic container recipe is not working within the phase budget, record it as residual risk rather than shipping a perma-red job.

**Warning signs:**
- The canary has been red for 3 or more consecutive schedules with no issue opened.
- The job duration is dominated by image pulls or boot.
- A `configuration_incomplete`-style status recurs.
- Someone proposes making the canary a required check.

**Phase to address:** P-IDP.

---

### Pitfall 10: Captured IdP fixtures contain secrets, PII, or time bombs

**What goes wrong:**
Captured responses embed test-user emails or names that look real, realm admin data, internal hostnames, or session indexes. Worse, they embed **absolute `NotOnOrAfter` timestamps**, so the fixture "expires" and the replay test starts failing (or a test quietly sets a huge skew to compensate, which weakens the time-window check).

**How to avoid:**
- Seed the IdP containers with **synthetic, obviously-fake users** (for example `alice@northstar.example`), using the existing Northstar and Harborline twin vocabulary. Never capture against a personal account.
- A capture sanitizer: allowlisted attributes only, and a redaction meta-test that scans fixtures for email domains outside `.example`, IPs, and `localhost` ports. The v1.11 redacted support incident already established a redaction pattern, so reuse it.
- Replay captured signed responses with **`:now` injected** to a time inside the captured validity window (`Relyra.consume_response/3` already reads `Keyword.get(opts, :now, ...)`). Never re-sign or edit times, because that destroys fidelity. Never widen skew to make an old fixture pass.

**Warning signs:** fixture tests failing on a calendar date; `skew_seconds` bumped in a fixture test; non-`.example` emails in `test/fixtures`.

**Phase to address:** P-IDP.

---

### Pitfall 11: Ecto sandbox hides real concurrency (WINDOW-29/30 chaos is fake)

**What goes wrong:**
Concurrency journeys run under `Ecto.Adapters.SQL.Sandbox`. In shared mode all processes use **one connection inside one wrapping transaction**, so "concurrent" replay consumes and audit co-commits are serialized. Uniqueness races, lock waits, serialization failures, and the cluster-safe replay guarantee are never exercised. In `test/support/migration_case.ex`, shared mode is the default for every non-async test (`shared: Map.get(tags, :sandbox_shared, not tags[:async])`). Nested `Repo.transaction` calls also become savepoints, so "rollback of the outer transaction" semantics differ from production.

**Why it happens:**
The sandbox is the default path and it makes tests pass. Real concurrent connections need cleanup outside the sandbox.

**How to avoid:**
- Chaos concurrency tests run **outside the sandbox** against a dedicated, disposable database or schema (the repo already has migration-case bootstrap machinery). Use real pooled connections, then truncate or drop afterward. Tag them `:chaos` with their own `cmd mix test` lane.
- Use **barriers** (each task blocks on a message, then all release simultaneously) to force overlap, and repeat N times with fixed iteration counts. Do not rely on `Task.async` timing alone.
- Assert **invariants, not interleavings**: exactly one consume succeeds per assertion ID across N racers, and the audit row count equals the committed mutation count.
- **Proof of realism:** a deliberately broken variant (replay check without the unique constraint, in a test-only module) *must* fail the same test. Without that negative control, the chaos test may be vacuous, the same failure mode as Pitfall 1.

**Warning signs:**
- The chaos test passes with `Sandbox.mode(:manual)` / `{:shared, self()}` in its setup.
- It never fails when the negative control is applied.
- Its runtime is identical to a sequential run.

**Phase to address:** P-CHAOS.

---

### Pitfall 12: Simulated DB failure that does not actually exercise the audit co-commit

**What goes wrong:**
"DB failure during audit co-commit" is simulated by raising in a mock *before* the transaction or *after* commit. The interesting case is a failure **between the data write and the audit insert inside one transaction**. Without that case, the test never proves that the mutation rolls back when the audit row fails. A naive fault-injection hook added to `audit_writer.ex` becomes a production code path, which violates the audit seam and invariant 5.

**How to avoid:**
- Inject failure **at the database**, not in Elixir. Options: a test-only migration that installs a Postgres trigger on the audit table, raising for rows that carry a sentinel `actor` or `correlation_id`; `SET LOCAL statement_timeout`; or terminating the backend (`pg_terminate_backend`) from a second connection at a barrier. Production code stays untouched.
- Assert that **both** the trust mutation and the audit row are absent after failure, that the returned error is typed, and that the runtime snapshot did not hydrate the uncommitted state.
- No `if Mix.env() == :test` or fault hooks in `lib/relyra/ecto/audit_writer.ex`.

**Warning signs:** a diff adds an `:inject_failure` option to any `lib/relyra/ecto/*` function; the test asserts only the error return and not table state.

**Phase to address:** P-CHAOS.

---

### Pitfall 13: Clock mocking leaks globally, or is impossible for the Ecto layer

**What goes wrong:**
To test clock skew and cert-rollover timing, someone reaches for a global time mock (patching `DateTime.utc_now/0` via Mimic or Patch, or an application-env clock). Global mocks leak across `async: true` tests (the repo has about 80 async test modules) and produce heisenbugs. **A repo-specific trap:** the protocol path already accepts an injected `:now` (`lib/relyra.ex`, `validation_pipeline.ex`, `replay_store/ets.ex`), but the **Ecto trust layer calls `DateTime.utc_now()` directly**: `certificate_inventory.ex` (activated_at, retired_at, staged_at), `metadata_apply.ex`, `mapping_commands.ex`, `certificate.ex`, and `replay_store/ecto.ex` (`inserted_at`). "Metadata refresh during cert rollover at a skewed clock" therefore cannot be driven by `:now` there, which is exactly what tempts the global mock.

**How to avoid:**
- For validation-time skew, **use `:now` injection exclusively**. Generate time boundaries (NotBefore, NotOnOrAfter, and skew ± 1s) as P-GEN properties through `:now`.
- For rollover and refresh chaos, **assert relative ordering and state-machine invariants** (exactly one `:active` cert set is ever hydrated, and staged certs are never trusted before activation) rather than absolute timestamps. Drive rollover with explicit commands, not wall-clock passage.
- Threading a clock through `Relyra.Ecto.*` public functions is a **public API change, which requires escalation**. If an internal clock seam is truly needed, propose it as a private, process-scoped option with an explicit escalation, not a global.
- Never use global mocking libraries for `DateTime`/`System`. If one is ever introduced, its tests must be `async: false`, and a meta-test should forbid it in security suites.

**Warning signs:**
- A `Mimic.copy(DateTime)`, `Patch`, or `Application.put_env(:relyra, :clock, ...)` in test code.
- Intermittent time-window failures in unrelated async tests.
- Chaos assertions comparing `activated_at` to fixed timestamps.

**Phase to address:** P-CHAOS (rollover and skew journeys). P-GEN covers time-boundary properties through `:now`.

---

### Pitfall 14: The persona journey turns into manual UAT

**What goes wrong:**
The customer-IT-admin journey ("connection testing and attribute preview, to test the Partial JTBD rating") is written as a script a human walks through, with screenshots, a `human_needed` state, or a "rate the experience" checklist. That violates the CLAUDE.md rule of no blocking human verification or UAT gates. Or it stalls completion because the JTBD rating is a judgment.

**How to avoid:**
- Express the journey as an **owned Playwright or Phoenix LiveView test** through mounted LiveAdmin (the v1.10/v1.11 browser harnesses already exist). The persona is a fixture (role, permissions, tenant), not a person.
- Convert "Partial to Full JTBD" into **observable acceptance assertions**. Examples: a connection-test action returns a typed, operator-readable diagnosis for each seeded misconfiguration class (wrong ACS, expired cert, audience mismatch, missing attribute), and attribute preview renders the mapped principal for a captured response without creating a session.
- If the journey reveals that a capability is missing (for example, there is no attribute-preview surface), record it as a **finding or residual risk**. Building a new admin feature is out of scope unless roadmapped.
- The JTBD rating update is a documentation consequence of green tests, not a gate.

**Warning signs:** a plan containing "manually verify", "walk through", "screenshot", or `human_needed`; acceptance criteria phrased as "feels" or "is intuitive".

**Phase to address:** P-ADMIN.

---

### Pitfall 15: Process overhead creep (v1.11 repeated)

**What goes wrong:**
Each technique grows its own receipt chain, evidence JSON, reconciliation replay, and debug-session stubs. v1.11's retrospective records that "governance tooling grew faster than the product work it governed" (Phase 73: 34 plans; Phase 79: superseded receipt plans, provenance stubs). Adversarial techniques invite this: "mutation score receipt", "canary evidence receipt", "corpus promotion receipt".

**How to avoid:**
- **Exactly one evidence contract** for the milestone. Extend the existing `Relyra.AdoptionEvidence` / `ci.evidence` lane with new entries (technique, lane, metric, stop state). Do not add a new contract module or a new `ci.*` receipt alias.
- Metrics are **read live from lanes** (corpus row count, mutation score JSON from the latest nightly artifact). They are not transcribed into planned receipts. This applies v1.11 Lesson 2.
- Plan budget per technique phase, set up front (a suggested ceiling of about 6 plans per phase). Exceeding it triggers a stopping-rule review, not a new governance phase.
- **Write the stopping rule as data**: "two consecutive rounds with no new defect class" needs an operational definition of *round* (one nightly exploration batch of fixed size, or one mutation run) and *defect class* (a new rejection-stage or invariant violation category, not a new seed). Without that definition the rule never fires, or fires arbitrarily.

**Warning signs:**
- New files matching `*RECEIPT*`.
- New `ci.phaseNN.*` aliases.
- Debug sessions about evidence tooling rather than product defects.
- Plan count per phase climbing past the budget.

**Phase to address:** All phases. Define it in the first phase (P-GEN) and audit it in P-CLOSE.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Byte-level random mutation instead of tree-level plans | Fast to write | Vacuous properties, useless shrinks | Only as one small "fuzz the pre-parse guards" family whose expected outcome is a guard or parse rejection |
| Committing found-failure seeds instead of rendered XML | Tiny diff | Regression rows silently change when generators evolve | Never; commit XML plus the plan |
| Running mutation testing over all of `lib/` | No scoping decisions | Hours of runtime, equivalent-mutant noise | Never |
| Floating IdP image tags | No bump PRs | Silent drift, a perma-red canary | Never |
| Global time mocking | Easy rollover tests | Async leakage, flakiness | Never in this repo |
| Sandbox-shared "concurrency" tests | Easy cleanup | False confidence in replay and audit atomicity | Only for functional (non-race) journey steps |
| One combined `cmd mix test` line for all new adversarial suites | Shorter alias | Fine as long as it is `cmd mix test`. A bare `test` inside `ci.security` is a hollow gate | Acceptable as a single `cmd mix test` line, never as a bare `test` step |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| StreamData plus ExUnit | Leaving seeds random in the PR lane | Pin `initial_seed` in the PR tier; keep random seeds nightly; label outcomes for distribution floors |
| StreamData plus RSA | Keygen per iteration | Pool keys per suite through `:persistent_term` (existing FakeIdP pattern) |
| Muex (or another mutation tool) | Running in the working tree with full `mix test` | Disposable checkout, security-suite-only test command, per-mutant timeout, `git diff --exit-code lib/` guard |
| `ci.security` alias | Adding a bare `test` step | A new `cmd mix test ... --only <tag>` line plus registration in `ci_gate_integrity_test.exs` |
| Keycloak / SimpleSAMLphp / Shibboleth | One job, tag-pinned, retrying assertions | Matrix per IdP, digest-pinned, readiness probe, classify `infra_unavailable` / `fidelity_drift` / `relyra_regression` |
| Captured fixtures plus time | Widening skew so old captures pass | Inject `:now` inside the captured window |
| Postgres fault injection | An Elixir-side hook in `audit_writer.ex` | Test-only trigger or migration, or backend termination at a barrier |
| libxml2 / xmlsec1 differential | Running in the PR lane | Nightly only. Use as an independent oracle for C14N neutrality |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| RSA sign per property iteration | `ci.security` grows by minutes | Key pool, bounded `max_runs` in the PR tier | About 200 or more iterations per property on CI runners |
| Shrinking with re-signing | Failure reports take minutes | `max_shrinking_steps` cap; plan-level shrinking | Any failure in a large plan |
| Per-mutant full test-suite boot | Mutation run takes hours | Restrict the test command to security suites and test only the mutated module | More than about 50 mutants with full-suite boot |
| Chaos repetition loops | The chaos lane dominates PR time | Fixed small N in PR, large N nightly | N > about 50 with real DB connections |
| Image pulls for 3 IdPs | Canary timeouts | Scheduled only, cached layers, per-IdP jobs | Shibboleth or Jetty images on cold runners |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Generators configure the SP to trust the attacker key "to reach deeper stages" | The test proves nothing about configured-cert-only trust and may normalize a bad config | The trust anchor in properties is always the configured test cert. The attacker key appears only as an untrusted signer whose outcome is `:must_reject` |
| Using `KeyInfo` in generated documents as the cert source | It contradicts invariant 1 | Generated docs may *contain* hostile `KeyInfo` (an attack family). The SP config never reads it. Assert rejection or ignore |
| A second parse path in test helpers (Floki, `:xmerl`) to inspect consumed nodes | Masks parser differentials and contradicts invariant 2 | Compare against generator-known bytes and IDs. If a parse is needed, use only the saxy seam, or an external libxml2 nightly differential |
| Pre-parse guard tests bypassed by calling a post-guard function directly | Size and DTD guards go untested by generators | Properties enter only through `Relyra.consume_response/3` (the public seam) |
| An ETS replay store in chaos tests | It does not exercise the cluster-safe Ecto path | Chaos replay tests use the Ecto ReplayStore against real connections |
| Mutation-testing findings "fixed" by editing security code without escalation | Silent posture change | Route any `lib/relyra/security/*` change through escalation |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Connection-test diagnostics that only show the rejection atom | IT admins cannot act on `:audience_mismatch` alone | Assert the human-readable diagnosis and remediation text exist for each seeded misconfiguration |
| Attribute preview that creates a session or user | Admin preview pollutes production data | Assert that preview causes no session or user-mapper side effects and writes no trust mutation without audit |
| Persona journey only exercising the happy path | The Partial JTBD rating stays unexamined | Seed one misconfiguration per class and assert each is distinguishable in the UI |

## "Looks Done But Isn't" Checklist

- [ ] **Generative suite:** Has outcome-distribution floors — verify the histogram shows each attack family reaching its target stage and at least one positive-control acceptance.
- [ ] **Generative suite:** Oracle is construction-based — verify a mutant in `signature.ex` reference resolution fails the property (cross-check with P-MUT).
- [ ] **Generative suite:** Wired as its own `cmd mix test` in `ci.security` — verify `ci_gate_integrity_test.exs` lists it and the PR tier is seed-pinned.
- [ ] **Corpus promotion:** Rows are XML plus public cert only — verify no new private keys outside the allowlist.
- [ ] **Package boundary:** No generator modules or `stream_data` runtime dependency in the Hex tarball — verify through release-parity or the package consumer.
- [ ] **Mutation testing:** Score excludes ledgered equivalent mutants and is scoped to named modules — verify the ledger exists and the run time is bounded.
- [ ] **Mutation testing:** The working tree is clean after the run — verify `git diff --exit-code lib/`.
- [ ] **IdP corpus:** Digest-pinned, per-IdP jobs, outcome classification — verify that no IdP job is a required check.
- [ ] **IdP corpus:** Captures sanitized and replayed with injected `:now` — verify that no skew widening was introduced.
- [ ] **Chaos concurrency:** Runs outside the sandbox, with a negative control that fails — verify the broken variant goes red.
- [ ] **DB failure mid co-commit:** Injected at the DB layer — verify that both the mutation and the audit row are absent, and that there are no hooks in `lib/`.
- [ ] **Clock skew:** No global time mocks — verify by grepping for Mimic, Patch, or a clock env.
- [ ] **IT-admin journey:** Fully automated, with no `human_needed` — verify assertions per misconfiguration class.
- [ ] **Governance:** Single evidence contract — verify there are no new `*RECEIPT*` files or `ci.phaseNN.*` aliases.
- [ ] **CI budget:** PR CI is still about 5 minutes — verify `ci-gate` wall-clock against the v1.11 baseline.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Vacuous property shipped green | LOW | Add labeling and distribution floors. Expect the build to go red, then fix generators to tree-level plus re-sign |
| Tautological oracle | MEDIUM | Replace with construction-based expectations. Re-run against injected mutants to confirm the property now detects them |
| Generator leaked into Hex | HIGH | Move it to `test/support`, cut a patch release, and retire the affected version through the hex REST API (`mix hex.retire` ignores `HEX_API_KEY`) if it shipped executable attack tooling |
| Private key committed | MEDIUM | Rotate (test-only), purge from history only if it is a real IdP key, and add the allowlist meta-test |
| Mutated source committed | HIGH | Revert immediately, treat it as a security incident review of the affected seam, and add the `git diff` guard |
| Perma-red canary | LOW | Classify outcomes, pin digests, and retire the IdP to residual risk if it cannot be stabilized (the existing precedent is the 2026-10-19 managed-IdP canary retirement) |
| Sandbox-hidden concurrency | MEDIUM | Re-host the test outside the sandbox and add a negative control. Any new finding becomes a P-CHAOS defect |
| Global clock mock leakage | LOW | Remove the mock and switch to `:now` injection or relative invariants |
| Governance creep | MEDIUM | Freeze it. Fold extras into the single evidence contract and delete receipt aliases at P-CLOSE |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1 Vacuous properties | P-GEN | Outcome histogram floors asserted; positive control accepted |
| 2 Tautological oracle | P-GEN (verified in P-MUT) | Injected verifier mutants killed by the generative suite |
| 3 Shrinking breaks signatures | P-GEN | Shrunk counterexamples remain validly signed; plan plus XML persisted |
| 4 Seeds and CI flakiness | P-GEN, P-CLOSE | Seed-pinned PR tier; nightly exploration; `ci-gate` time vs baseline |
| 5 Signer and generators reachable from Hex | P-GEN | Tarball assertion in release-parity; `stream_data only: :test` |
| 6 Private keys in fixtures | P-GEN, P-IDP | Private-key allowlist meta-test |
| 7 Mutation noise and runtime | P-MUT | Scoped modules, equivalent ledger, bounded nightly run, clean-tree guard |
| 8 Weakening tests to kill mutants | P-MUT | No deletions in `adversarial_crypto_test.exs`; no lib security diff without escalation |
| 9 IdP drift and canary flakiness | P-IDP | Digest pins, matrix jobs, outcome classes, not required checks |
| 10 PII and time bombs in captures | P-IDP | Redaction meta-test; `:now`-injected replay |
| 11 Sandbox hides concurrency | P-CHAOS | Non-sandbox lane plus failing negative control |
| 12 Fake DB failure | P-CHAOS | DB-level injection; both rows absent; no lib hooks |
| 13 Clock mocking leaks | P-CHAOS, P-GEN | Grep guard; `:now`-only; relative rollover invariants; escalate any Ecto clock seam |
| 14 Persona journey becomes UAT | P-ADMIN | Automated browser or LiveView assertions per misconfiguration class |
| 15 Process overhead creep | All phases; audited in P-CLOSE | One evidence contract; plan budget; stopping rule defined as data |

## Sources

- Repo inspection (HIGH): `mix.exs` (`package_lib_files/0` exclusion by `"test_support"` substring; the `ci.security` alias and hollow-gate comment); `lib/relyra/testing/signer.ex` (production-compiled, ships in Hex, fresh RSA key per response, canonicalizes via the real verifier path); `test/test_helper.exs` (`FakeIdP.keypair/0` persistent_term race fix); `test/support/migration_case.ex` (shared sandbox default for non-async tests); `lib/relyra/ecto/{certificate_inventory,metadata_apply,mapping_commands,certificate}.ex` and `lib/relyra/replay_store/ecto.ex` (direct `DateTime.utc_now()`); `lib/relyra.ex` and `validation_pipeline.ex` (`:now` injection); `test/adoption/external_canary_contract_test.exs` (managed-IdP canary retired for daily `configuration_incomplete`).
- `.planning/PROJECT.md` (v1.12 goal, stopping rule, constraints) and `.planning/RETROSPECTIVE.md` (v1.11 governance-creep lessons).
- StreamData `ExUnitProperties` docs (HIGH): `initial_seed` defaults to the ExUnit seed; `max_runs`, `max_run_time`, `max_shrinking_steps` (default 100); `FilterTooNarrowError` — https://stream-data.hexdocs.pm/ExUnitProperties.html
- Muex comparison (MEDIUM, self-published): per-mutant source rewrite, recompile, and `mix test` subprocess with 100–200 ms overhead; Darwin and Exavier unmaintained since 2020 and incompatible with modern Elixir — https://muex.hexdocs.pm/comparison.html
- Darwin forum thread (MEDIUM) — https://elixirforum.com/t/darwin-mutation-testing-library-for-elixir-and-erlang/27328
- Muzak docs (MEDIUM; maintenance status unverified) — https://hexdocs.pm/muzak/1.0.1/muzak.html
- General XSW and property-testing practice (MEDIUM, training knowledge): signature-wrapping attack families, the differential-oracle pattern, and the equivalent-mutant problem in mutation testing.

---
*Pitfalls research for: adversarial verification of a strict SAML SP library (Relyra v1.12)*
*Researched: 2026-10-19*
