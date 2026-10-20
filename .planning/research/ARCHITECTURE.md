# Architecture Research

**Domain:** Generative adversarial / mutation testing harness for a strict SAML 2.0 SP library (Elixir)
**Researched:** 2026-10-19
**Confidence:** HIGH (repo inspected directly; seams, aliases, workflows, and evidence contract read; one live oracle probe run against the checked-out code)

/ scope note: this is a test-and-CI architecture milestone. Almost everything new lives under `test/`, `priv/`, `scripts/`, `.github/workflows/`, and `demo/`. The production trust core (`lib/relyra/security/**`, `lib/relyra/protocol/**`) is FROZEN per CLAUDE.md invariant #4 and the v1.12 constraint "no public API, default, or security-posture change without explicit approval." The twin EXERCISES these seams; it never modifies them. /

> **Superseded premise (2026-10-19):** this research treated the trust core as frozen and the twin as test-only. The live probe in this file, plus a follow-up seam audit (see `SUMMARY.md` § Seam Inventory), showed the core itself is unsound. v1.12 is re-scoped to **Trust-Path Hardening**, and fixing `lib/relyra/security/**` is in scope. The harness architecture below (twin signer, generators, oracle, corpus promotion, mutation lane) still applies to Phases 82-83.

---

## Standard Architecture

### System Overview

The v1.12 work bolts five test-side subsystems onto the existing frozen trust core. The core already funnels every login through one path; the twin's whole job is to pump adversarial inputs into that single funnel and assert the invariant on the way out.

```
┌───────────────────────────────────────────────────────────────────────────┐
│  GENERATORS (test-only)                                                     │
│  ┌─────────────────────┐   ┌──────────────────────┐  ┌───────────────────┐ │
│  │ Twin signer         │   │ StreamData mutators   │  │ Real-IdP capture  │ │
│  │ (sign→mutate,       │   │ (SigWrap, dup-id,     │  │ (Keycloak / SSP / │ │
│  │  mutate→resign)     │   │  ns/ws, encoding,     │  │  Shibboleth →     │ │
│  │                     │   │  time, truncation)    │  │  frozen fixtures) │ │
│  └──────────┬──────────┘   └──────────┬───────────┘  └─────────┬─────────┘ │
├─────────────┼──────────────────────────┼───────────────────────┼───────────┤
│             ▼                           ▼                       ▼           │
│                    FROZEN TRUST CORE (the only entry)                       │
│   parse_safely → Signature.verify/4 (do_verify) → bind → protocol stages    │
│   lib/relyra/security/xml/pure_beam.ex · signature.ex · c14n.ex             │
│   lib/relyra/protocol/validation_pipeline.ex  (and Relyra.consume_response) │
├─────────────────────────────────────────────────────────────────────────┬─┤
│  ORACLE / INVARIANT  (test-only)                                          │ │
│  Twin.Oracle.assert_trust_invariant/2 :                                   │ │
│   {:ok, SignedNode}  ⟹ consumed node byte-equals the signed node          │ │
│   {:error, %Error{type: known_atom}}                                      │ │
│   never: crash, {:ok} on a tampered doc, untyped error                    │ │
├───────────────────────────────┬───────────────────────────────────────────┤
│  CORPUS PROMOTION             ▼         MUTATION TESTING (scheduled)         │
│  property counter-example → named row   muex over security-core modules     │
│  priv/security_corpus.json (+ fixture)  → score artifact, --fail-at gate    │
└───────────────────────────────────────────────────────────────────────────┘
          │                                           │
          ▼                                           ▼
   mix ci.security (PR, bounded)              scheduled workflow only
   mix ci.adversarial (scheduled, deep)       (never a merge gate)
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation / Location |
|-----------|----------------|-----------------------------------|
| Twin signer | Mint a genuinely-signed Response, then (a) mutate-after-signing or (b) mutate-then-resign, over the SAME C14N engine the verifier uses | **Extend** `lib/relyra/test_support/xmldsig_signer.ex` (NOT the public `Relyra.Testing.Signer`); add `resign/1` and a structured mutation entry point |
| Generators | StreamData generators that emit mutation recipes (not raw bytes), parameterized by category | **New** `test/support/twin/generators.ex` (+ `mutators/` by family) |
| Oracle | The single invariant predicate every generated input is asserted against | **New** `test/support/twin/oracle.ex` |
| Property suites | `ExUnitProperties` suites, one per mutation family, deterministic-seeded, bounded | **New** `test/security/twin/*_property_test.exs` |
| Corpus manifest | Source of truth for both the runtime `CorpusGate` and the test corpus reader | **Existing** `priv/security_corpus.json` (append rows; keep schema) |
| Corpus promotion | Turn a shrunk property counter-example into a permanent named row + fixture | **New** `test/support/twin/corpus.ex` + a `mix relyra.corpus.promote` helper |
| Mutation runner | Run muex over scoped security-core modules, emit a JSON score artifact, gate on `--fail-at` | **New** scheduled workflow + `mix ci.mutation` alias; muex as `only: [:dev, :test]` dep |
| Real-IdP capture | Stand up containerized IdPs, capture real signed responses, freeze redacted fixtures | **New** `scripts/capture_real_idp_corpus.sh` + `test/fixtures/security/real_idp/<vendor>/` |
| Chaos journeys | Concurrency / mid-txn-failure / rollover-refresh / clock-skew against twin personas | **Root** `test/chaos/*_test.exs` (sandbox) + a few in `demo/ledger_loop/test/chaos/` |
| IT-admin journey | Connection-test + attribute-preview flow to settle the Partial JTBD rating | **Demo** `demo/ledger_loop/test/.../tenant_admin_preview_test.exs` + guide |

---

## Recommended Project Structure

```
test/
├── support/twin/
│   ├── generators.ex          # StreamData recipe generators, per family
│   ├── mutators/              # one module per family (sig_wrapping, dup_id, ns_ws, encoding, time, truncation)
│   ├── oracle.ex              # assert_trust_invariant/2 — the single predicate
│   └── corpus.ex              # counter-example → manifest row + fixture bytes
├── security/twin/
│   ├── signature_wrapping_property_test.exs
│   ├── structural_mutation_property_test.exs   # dup elements, ns/ws, encoding
│   ├── boundary_property_test.exs              # time windows, truncation, size
│   └── real_idp_corpus_test.exs                # reads frozen vendor fixtures (deterministic, PR-safe)
├── chaos/
│   ├── concurrent_replay_test.exs              # WINDOW-29
│   ├── concurrent_cert_transition_test.exs     # WINDOW-30
│   ├── audit_cocommit_failure_test.exs         # DB failure mid audit co-commit
│   ├── rollover_during_refresh_test.exs        # metadata refresh ∩ cert rollover
│   └── clock_skew_test.exs
├── fixtures/security/real_idp/
│   ├── keycloak/   simplesamlphp/   shibboleth/   # frozen redacted bytes + PROVENANCE.md
priv/
└── security_corpus.json        # APPEND promoted rows here (existing schema)
scripts/
├── capture_real_idp_corpus.sh  # scheduled: containers → capture → redact → write fixtures
└── run_mutation_testing.sh     # scheduled: muex over scoped modules → score JSON
.github/workflows/
├── adversarial-corpus.yml      # scheduled + workflow_dispatch: real-IdP capture canary
└── mutation-testing.yml        # scheduled + workflow_dispatch: muex score artifact
demo/ledger_loop/test/
├── chaos/                      # persona-level chaos that needs the demo's Ecto repo + Oban
└── ledger_loop_web/live/tenant_admin_preview_test.exs
```

### Structure Rationale

- **`test/support/twin/` not `lib/`:** generators, oracle, and the signer are dev/test-only. `lib/` production compilation already strips `test_support` (`mix.exs prod_elixirc_paths/0`), and v1.12 "Out of Scope" forbids shipping a public IdP/broker. Keep every new generative capability out of the Hex tarball.
- **Separate property suites per family:** `ci.security` gates each suite as its own `cmd mix test` line. One file per family maps cleanly to one gated line and keeps the "two consecutive rounds, no new defect class" stopping rule auditable per technique.
- **`priv/security_corpus.json` stays the single manifest:** `CorpusGate` reads it at compile time AND `corpus_security_test.exs` reads it at test time. Promotion must append here (not a new store) so a promoted row simultaneously becomes a runtime refusal shape and a test regression row — one promotion, two gates, zero drift. This is the existing pattern; reuse it.
- **Real-IdP fixtures are frozen bytes, captured out-of-band:** the GATE-02 C14N golden precedent (`parser_differential_and_c14n/*.c14n` minted by libxml2 out-of-band, committed, CI reads bytes only) is the exact model. CI has no Java/PHP toolchain and must not; the scheduled canary captures, the PR lane reads committed bytes.

---

## Architectural Patterns

### Pattern 1: Recipe-generators, not byte-generators

**What:** StreamData produces a *mutation recipe* (`{:add_envelope_element, :name_id, value}`, `{:duplicate_id, "assertion-1"}`, `{:whitespace, :signedinfo}`), which a mutator applies to a genuinely-signed base document. The generator never emits raw XML bytes.
**When:** For every property family.
**Trade-offs:** Shrinking stays meaningful (StreamData shrinks the recipe to the minimal mutation, which is exactly what a promoted corpus row should encode). Raw-byte fuzzing would mostly produce `:malformed_xml` and shrink to garbage — low signal on the trust path.

```elixir
# test/support/twin/generators.ex
def mutation(:structural) do
  gen all op <- member_of([:duplicate_assertion_id, :add_envelope_nameid, :reorder_ns]),
          target <- member_of([:assertion, :response, :signedinfo]) do
    {op, target}
  end
end
```

### Pattern 2: Sign→mutate vs mutate→resign — two signer verbs

**What:** The twin signer exposes both: (a) `signed_response/1` then an explicit post-sign mutation (digest/signature untouched — the `:digest_mismatch` class, already modeled by `maybe_tamper_name_id`), and (b) `resign/1` that re-canonicalizes and re-signs *after* a structural mutation (the "validly-signed-but-structurally-hostile" class — signature wrapping, envelope injection, moved elements where the signature is still arithmetically valid over *a* node).
**When:** (a) proves tamper detection; (b) proves the binding between the signed node and the consumed node — the harder, higher-value class.
**Trade-offs:** `resign/1` must reuse `FakeIdP.keypair()` and the verifier's own `PureBeam.canonicalize` / `C14N.serialize` (the "anti-divergent-signer guarantee" the module already documents). A second, divergent canonicalizer would make attacks pass for the wrong reason — the single most important rule for this component.

### Pattern 3: The oracle is one predicate with three legal outcomes

**What:** `Twin.Oracle.assert_trust_invariant(outcome, signed_bytes)`:
- `{:ok, %LoginResult{}}` is legal **only if** the identity the pipeline consumed came from the node that was actually signed. Assert `login_result.signed_xml_id` / `signed_xpath` bind to the signed assertion, and (for the resign family) that consumed identity fields equal the signed node's fields.
- `{:error, %Error{type: t}}` is legal **only if** `t` is in the known atom set (reuse `error_atoms_test.exs` discipline).
- A crash, a bare `{:error, _}`, or `{:ok}` on a mutated-after-sign document fails the property.

**When:** Every generated input, every family.
**Trade-offs:** The oracle's strength depends on checking *which bytes were consumed*, not just ok/error. A live probe against the current checkout (`Relyra.consume_response/3` via the public `Relyra.Testing` fixtures) shows why this matters: because several derived fields (`name_id`, `audiences`, `Conditions`, attributes) are read with descendant-wide "first/all element by local name" helpers (`first_text/2`, `all_texts/2` in `pure_beam.ex`) rather than strictly from within the bound signed subtree, an added sibling element outside the signed assertion can change the consumed identity while the signature still verifies over the original assertion. The oracle's "consumed node == signed node" clause is what turns this from invisible into a red property + a promotable corpus row. **This is a trust-path finding, not merely a test-design note; treat its disposition as a security-posture decision (escalate) under CLAUDE.md.**

### Pattern 4: Promotion = property failure becomes a permanent named row

**What:** When a property shrinks to a counter-example, `Twin.Corpus.promote/2` writes (1) a new object into `priv/security_corpus.json` with a stable `id`, `class`, `family`, `requirement_ids`, `expected_error_type`, and `provenance`, and (2) the minimal reproducing bytes as a fixture. The row is then permanently exercised by the existing deterministic `corpus_security_test.exs` + `CorpusGate` — never again regenerated.
**When:** Once per newly-discovered defect class (the stopping rule bounds how often this happens).
**Trade-offs:** Promotion is a human-reviewed commit, not an automated write in CI (a CI-side write to a tracked file would violate the clean-tree/`tracked_tree` governance). The scheduled property run *reports* a counter-example; a maintainer runs the promote helper and commits.

### Pattern 5: Two depths of the same suites (PR-bounded vs scheduled-deep)

**What:** Property suites take their run size from an env/opt. PR CI runs a small deterministic budget (fixed `seed: 0`, e.g. `max_runs: 100`) inside `ci.security`. A scheduled `ci.adversarial` run uses a large budget and a rotating/random seed to find *new* signal, then reports counter-examples for promotion.
**When:** Always — this is how a generative suite stays a merge gate without being flaky or slow.
**Trade-offs:** The PR lane must be deterministic (fixed seed) so it can live behind the `ci-gate` required check; the scheduled lane carries the exploration. Same code, two invocations.

---

## Anti-Patterns to Avoid

- **Collapsing property suites into one `test` step inside `ci.security`.** `mix` dedups the `test` task per alias run and `ci.conformance` already consumed one with `--only conformance`; a bare later `test` step is silently skipped AND filter-poisoned. Each new suite MUST be its own `cmd mix test <file> --only <tag> --warnings-as-errors` line, and its `{file, tag}` pair MUST be added to the `@gated_suites` list in `test/security/ci_gate_integrity_test.exs` (the meta-gate that gates itself).
- **A second canonicalizer in the signer.** Reuse `PureBeam.canonicalize/1` and `C14N.serialize/1`. (Documented invariant in `xmldsig_signer.ex`.)
- **Making mutation testing or the real-IdP canary a merge gate.** Mutation score is a *diminishing-returns metric* and muex is slow + lossy (5–15% score variance by optimizer mode); the real-IdP capture needs Docker + Java/PHP. Both belong in scheduled workflows with `workflow_dispatch`, NEVER in `needs:` of `ci-gate`. The `ci-gate` job today requires exactly three lanes (`security`, `phase73-reconciliation`, `package-consumers`) and `external_canary_contract_test.exs` enforces that scheduled canaries stay separate and upload only bounded status receipts — follow that enforced shape.
- **Trusting document `KeyInfo` or adding a second parse path in any generator.** The twin feeds bytes to the one funnel; it never gives the verifier a cert from the document (invariants #1, #2).
- **Writing promoted corpus rows from CI.** Violates clean-tree governance; promotion is a reviewed local commit.
- **A new receipt chain / `human_needed` gate for any of this.** v1.12 constraint: one evidence contract, deterministic automated evidence only.

---

## Integration With the Existing Evidence Contract (critical)

There is **one** acceptance mechanism and v1.12 must extend it, not fork it: `Relyra.AdoptionEvidence` (`test/support/adoption_evidence.ex`), enforced by `test/adoption/evidence_contract_test.exs` and `test/governance/milestone_scope_test.exs` under `mix ci.evidence`.

How each v1.12 requirement joins it (add rows to `@planned_rows` / the existing entry lists, matching the established tuple shape `{requirement, personas, job, evidence_kind, owner, lane}`):

| v1.12 requirement | evidence_kind | owner (test file) | lane |
|---|---|---|---|
| Generative adversarial invariant | `:security_corpus` | `test/security/twin/*_property_test.exs` | `ci.security` |
| Promoted corpus rows | `:security_corpus` | `test/security/xml/corpus_security_test.exs` (existing reader) | `ci.security` |
| Mutation score | `:security_corpus` | `test/ci/mutation_score_contract_test.exs` (asserts the artifact exists + threshold) | `ci.quality`/`ci.security` |
| Real-IdP fidelity corpus | `:external_canary` (scheduled signal) + a deterministic `:security_corpus` contract owner | workflow owner + `test/security/twin/real_idp_corpus_test.exs` (reads frozen bytes) | `scheduled:<job>` + `ci.security` |
| Chaos journeys | `:application` | `test/chaos/*` and `demo/ledger_loop/test/chaos/*` | `ci.security` / `ci.demo_app` |
| IT-admin journey | `:application`/`:browser` | `demo/ledger_loop/test/.../tenant_admin_preview_test.exs` | `ci.demo_app` |

Follow the EVID-03 precedent exactly: a `:external_canary` row may NOT be a requirement's only (primary) owner (`adoption_evidence.ex` forbids `evidence_kind == :external_canary and owner_role == :primary`). So every scheduled-canary-backed requirement needs a *deterministic* mandatory owner too, with the scheduled canary as a supplemental signal (`lane: "scheduled:<job>"`). `milestone_scope_test.exs` maps each lane to a concrete `jobs.<job>.<step>` in a workflow and asserts the alias actually selects ≥1 test — so every new lane you name must be a real `mix` alias wired into a real workflow step.

---

## New `mix` aliases (in `mix.exs`, with `preferred_envs: :test`)

```
"ci.security"    → append each twin property suite as its own `cmd mix test ... --only <tag>` line
"ci.adversarial" → deep/random-seed run of the same property suites (scheduled)
"ci.mutation"    → run muex over scoped modules, emit score JSON, --fail-at <floor>
"ci.chaos"       → cmd mix test test/chaos --only chaos (sandbox-backed, needs postgres service)
```

Update `test/security/ci_gate_integrity_test.exs` `@gated_suites` and `@security_test_commands` in lock-step — that meta-gate fails the build otherwise.

---

## Chaos journeys: where they run

- **Concurrency (WINDOW-29 replay race, WINDOW-30 cert-transition race):** these are open automation gaps precisely because the `Ecto.Adapters.SQL.Sandbox` can't coordinate two independent owner PIDs (`79-RISKS.json`). The honest fix is an **owned multi-connection harness** that checks out a *shared* sandbox connection in `{:shared, self()}` mode (or a dedicated non-sandbox test database with explicit truncation) so two processes submit genuinely concurrently. This belongs at **root** `test/chaos/` against `Relyra.TestSupport.EctoTestRepo` (the ecto/replay `on_conflict` unique-violation path is in `lib/relyra/replay_store/ecto.ex`; the optimistic-lock stale path is in `lib/relyra/ecto/certificate_inventory.ex`, which already exposes `after_lock`/`after_fetch` transition hooks to inject the race window).
- **DB failure during audit co-commit:** root `test/chaos/`, using the `AuditWriter.append_event` + wrapping `Ecto.Multi`/transaction; inject a failing step and assert the data mutation rolls back WITH its audit row (invariant #5).
- **Metadata refresh during cert rollover + clock skew:** root `test/chaos/`; clock skew drives `Relyra.Protocol.Assertion.validate_time_conditions/3` via the `now:`/`skew_seconds:` opts the pipeline already threads.
- **Persona-level chaos (end-to-end through LedgerLoop):** `demo/ledger_loop/test/chaos/` where the demo's real Ecto repo + Oban (`metadata_refresh` worker) exist. Keep it under `ci.demo_app`.

Prefer root for anything that needs only the library + a repo; use the demo only when the scenario genuinely needs the persona wiring (Northstar/Harborline tenants, Oban scheduling).

## Real-IdP corpus: capture without becoming a gate

- Reuse the containerized-IdP muscle already in the repo: `adoption-external-idp.yml` + `keycloak-proxy-e2e.yml` run `quay.io/keycloak/keycloak:26.x` with realm import; the fleet-proxy workflow shows the scheduled `rulestead-main-canary` pattern (schedule + `workflow_dispatch` input, `if: github.event_name == 'schedule' || inputs...`, bounded ≤512-byte status receipt, 3-day retention, separate job never in `ci-gate`).
- Add Keycloak (have it), **SimpleSAMLphp** (`kenchan0130/simplesamlphp` or `3breadt/simplesamlphp` — plug-and-play test IdPs; pin a digest, both explicitly non-production), and **Shibboleth IdP v5** (`i2incommon/shib-idp`, 5.2.x) as scheduled capture jobs.
- The job captures a real signed Response, **redacts** (no live PEM/key material — the demo config already disables query logging for exactly this reason), and writes frozen bytes + `PROVENANCE.md` to `test/fixtures/security/real_idp/<vendor>/`. The deterministic PR lane only *reads* those committed bytes via `real_idp_corpus_test.exs`. New fixtures land through a reviewed commit, same as corpus promotion.

## Mutation testing: scoped and scheduled

- Dep: **muex** (`~> 0.11`, actively maintained 2026; Darwin and Exavier are abandoned since 2020) as `only: [:dev, :test], runtime: false`.
- Scope to the trust core only via `--files`: `lib/relyra/security/signature.ex`, `.../xml/pure_beam.ex`, `.../xml/c14n.ex`, `lib/relyra/protocol/assertion.ex` (audience/time), `lib/relyra/replay_store/ecto.ex` (replay). Use `--coverage-guided` to run only covering tests per mutant; `--format json --output` for the score artifact; `--fail-at <floor>` as the regression gate inside the scheduled run.
- Runs ONLY in `mutation-testing.yml` (schedule + `workflow_dispatch`), uploads the JSON score as a bounded artifact. A tiny deterministic PR-side contract test asserts the artifact schema + a recorded floor exists (so the *contract* is gated, the *computation* is not). The score is the stopping-rule metric: stop when it plateaus.

## Customer-IT-admin journey

- The Partial JTBD (`guides/jtbd_user_flows.md` §3) is about customer IT self-configuring a connection + previewing attributes. The surfaces exist (`lib/relyra/live_admin/connection_metadata_live.ex`, `connection_trace_live.ex`, mapping forms, diagnostic bundle). The journey test drives: import metadata → "test connection" (a dry-run consume via the twin signer producing a success fixture for that connection) → attribute preview (assert mapped attributes render) → read the login trace. If this passes cleanly with current surfaces, the gap is **documentation**; if it needs new glue, it's a **product gap** — the test's existence settles it. Lives in `demo/ledger_loop/test/.../tenant_admin_preview_test.exs` under `ci.demo_app`, with a persona row in the evidence contract.

---

## Build Order (dependency-aware)

1. **Phase 80 — Twin signer + oracle foundation.** Extend `xmldsig_signer.ex` with `resign/1` and a structured mutation seam; write `test/support/twin/oracle.ex`. *Depends on:* nothing. *Unblocks:* everything. Ship the oracle with a handful of hand-written cases first (including the envelope/sibling-injection case found during this research) to validate the predicate before generators exist.
2. **Phase 81 — Generators + first property family + promotion path.** `generators.ex`, `corpus.ex`, `Twin.Corpus.promote/2`, and one property suite (signature-wrapping) wired into `ci.security` + `@gated_suites`. Prove the full loop: property fails → promote → permanent row → re-runs deterministically. *Depends on:* 80.
3. **Phase 82 — Remaining property families.** Structural (dup/ns/ws/encoding) and boundary (time/truncation/size) suites, each its own gated line, PR-bounded + `ci.adversarial` deep variant. *Depends on:* 81 (reuses the loop).
4. **Phase 83 — Mutation testing.** muex dep, `ci.mutation` alias, `mutation-testing.yml` scheduled, score-artifact contract test. Run it against the core *after* properties exist so the score reflects the strengthened suites. *Depends on:* 81–82.
5. **Phase 84 — Real-IdP fidelity corpus.** Capture scripts + `adversarial-corpus.yml` scheduled canary + frozen vendor fixtures + deterministic reader. *Depends on:* 80 (oracle reads them) and the EVID-03 canary pattern. Independent of 82/83, can run in parallel with 83.
6. **Phase 85 — Chaos journeys.** Owned concurrency harness (retires WINDOW-29/30), audit-co-commit-failure, rollover-refresh, clock-skew; root + demo split. *Depends on:* nothing in 80–84 (parallelizable), but uses the oracle for assertion where a login is involved.
7. **Phase 86 — IT-admin journey + JTBD disposition.** *Depends on:* demo surfaces only; settles Partial rating; can run anytime but naturally closes the milestone.

Evidence-contract rows for each requirement are added *in the same phase that builds the owner*, never deferred — `milestone_scope_test.exs` already keys phase→requirement sets, so planned rows must appear as the phase lands.

---

## Seams the twin MUST go through and never bypass

| Seam | File | Rule |
|------|------|------|
| Public consume | `Relyra.consume_response/3` → `ValidationPipeline.run/4` | End-to-end properties and journeys enter here (or `ValidationPipeline.run/4` for pipeline-level). |
| Crypto gate | `lib/relyra/security/signature.ex` `do_verify/4` | Never patched; only exercised. Mutation testing mutates it but the running build never ships a mutant. |
| One parse path | `lib/relyra/security/xml/pure_beam.ex` `parse_safely/2` | Generators emit bytes into this; no second parser, no document `KeyInfo` trust. |
| C14N | `lib/relyra/security/xml/c14n.ex` + `PureBeam.canonicalize/1` | The signer's ONLY canonicalizer. No divergent copy. |
| Signed-node binding | `select_signed_node/2`, `bind_signed_node/2` | Oracle's "consumed == signed" clause anchors here. |
| Corpus manifest | `priv/security_corpus.json` + `CorpusGate` | Single source of truth; promotion appends here. |
| Audit write | `lib/relyra/ecto/audit_writer.ex` `append_event` | Chaos DB-failure test drives the co-commit through here. |
| Evidence contract | `test/support/adoption_evidence.ex` | The only acceptance mechanism; extend, don't fork. No new receipt chains. |
| CI meta-gate | `test/security/ci_gate_integrity_test.exs` | Every new `cmd mix test` security line registers in `@gated_suites`. |

---

## Sources

- Repo inspection (checkout at `d9af2c2`): `mix.exs` aliases/deps, `lib/relyra/security/**`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/test_support/xmldsig_signer.ex`, `test/security/xml/{adversarial_crypto,corpus_security,error_atoms}_test.exs`, `test/security/{ci_gate_integrity,signed_node_binding}_test.exs`, `test/support/adoption_evidence.ex`, `test/adoption/external_canary_contract_test.exs`, `test/governance/milestone_scope_test.exs`, `priv/security_corpus.json`, `.github/workflows/{security-gates,fleet-proxy-e2e,keycloak-proxy-e2e,adoption-external-idp,demo-app-ci}.yml`, `.planning/{PROJECT,STATE}.md`, `79-RISKS.json`, `guides/jtbd_user_flows.md`. [HIGH]
- One live oracle probe run against the checkout (public `Relyra.consume_response/3` + `ValidationPipeline.run/4`) confirming the "consumed node vs signed node" invariant is the load-bearing oracle clause. [HIGH — reproduced on checked-out code]
- [stream_data on Hex](https://hex.pm/packages/stream_data) — v1.4.0, updated 2026-07-14 (property-testing engine). [HIGH]
- [muex docs](https://muex.hexdocs.pm/readme.html) and [Muex vs Darwin vs Exavier comparison](https://muex.hexdocs.pm/comparison.html) — muex 0.11.3 actively maintained 2026; Darwin/Exavier abandoned 2020; `--files`/`--coverage-guided`/`--format json`/`--fail-at`/`--concurrency`. [MEDIUM — comparison is author-published]
- [i2incommon/shib-idp Docker tags](https://hub.docker.com/r/i2incommon/shib-idp/tags) — Shibboleth IdP v5.2.x images. [MEDIUM]
- [kenchan0130/simplesamlphp](https://hub.docker.com/r/kenchan0130/simplesamlphp) and [3breadt/simplesamlphp](https://hub.docker.com/r/3breadt/simplesamlphp) — plug-and-play test IdPs, explicitly non-production. [MEDIUM]
- [Keycloak container](https://quay.io/keycloak/keycloak) — already used at 26.x in `keycloak-proxy-e2e.yml`. [HIGH]
