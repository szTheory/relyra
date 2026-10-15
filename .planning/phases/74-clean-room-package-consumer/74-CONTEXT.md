# Phase 74: Clean-Room Package Consumer - Context

**Gathered:** 2026-09-24 (assumptions mode; research-backed recommendations)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that a fresh Phoenix application can adopt, configure, migrate, boot, and
safely exercise Relyra using only the locally built Hex artifact, with isolated
consumer state and no checkout-private support. Cover representative BEAM and
optional-dependency profiles, and make installer or upgrade drift fail with an
actionable diagnostic. This is package-boundary proof; the fuller adopter
lifecycles and recovery journeys remain owned by Phase 76.

</domain>

<decisions>
## Implementation Decisions

### Artifact Boundary and Isolation
- **D-01:** Build and unpack the local Hex tarball with `mix hex.build --unpack`, then resolve Relyra from that unpacked artifact in a consumer project outside the checkout. A path dependency on the unpacked package is the simplest deterministic proof of the shipped files; registry/index resolution is not a Phase 74 goal.
- **D-02:** Place the consumer, Mix/Hex homes, dependency path, build root, database, and captured output under task-owned temporary paths. Keep the BEAM toolchain available on `PATH`, but do not inherit checkout build or dependency state. Assert the resolved Relyra source is inside the unpacked artifact and outside the checkout.
- **D-03:** Include a controlled package-omission negative control. It must fail because a required shipped file is absent, with a diagnostic identifying the missing package contract. The successful and negative controls must not load root fixtures, unshipped checkout files, or `Relyra.TestSupport`.

### Phoenix Runtime Exercise
- **D-04:** Go beyond compile or health-route checks: submit one valid signed SAML response through the consumer's real Phoenix router/ACS endpoint and verify the host receives the expected authenticated outcome. Use the package-shipped `Relyra.Testing` fixture helpers (`signed_success/1`, `post_params/2`, `consume_opts/2`) so the real verifier path is exercised without private test support.
- **D-05:** Keep this one deterministic package-consumer success proof bounded. Full rejection, replay, tenant-isolation, diagnosis, and recovery journeys belong to Phase 76; the Phase 74 smoke must not become a second lifecycle suite.

### Migration Ownership
- **D-06:** Run Relyra-owned migrations from the dependency path inside the unpacked artifact; run host-owned request/replay store migrations from the consumer's own migration directory against a pristine PostgreSQL database. Do not copy Relyra migrations into the host app.
- **D-07:** Validate the tables through the configured store adapters, including representative write/read or consume and uniqueness behavior, rather than relying only on table-existence checks. This proves both package migration availability and the documented host/library DDL boundary.

### Installer Drift and Adopter Safety
- **D-08:** Preserve current installer semantics: normal runs leave existing generated files untouched; `--force` remains the explicit, potentially destructive overwrite path. Do not make forced regeneration the upgrade mechanism and do not introduce interactive conflict prompts into CI.
- **D-09:** Keep a deterministic fresh-install generated-tree/receipt comparison and add a consumer scenario seeded from a prior generated scaffold. The fresh golden catches accidental installer output changes; the prior scaffold catches upgrade drift that a golden alone cannot detect. Failures should name the command and the exact file, route, or integration contract that diverged, with a clear next step.

### Compatibility Profiles
- **D-10:** Exercise the clean-room consumer on the repository's current CI tuples, Elixir 1.19.5 with OTP 27 and OTP 28, rather than inheriting older compatibility examples from research prompts as an unsupported new commitment.
- **D-11:** Cover a full Phoenix/Ecto/PostgreSQL consumer profile and a no-optional-dependencies compile profile. Run the migration/runtime proof where those optional integrations are installed; use `--no-optional-deps --warnings-as-errors` for the minimal profile. Avoid a full Cartesian matrix of every optional integration unless the plan shows it is required for PKG-05.

### the agent's Discretion
- Choose the temporary-root layout and exact isolated environment variable wiring, provided all paths are asserted and diagnostics remain readable.
- Choose a stable consumer fixture shape that is generated from Relyra's public installer and can be initialized reproducibly from a prior scaffold state.
- Keep all proof deterministic in a mandatory CI lane; do not add a manual verification gate or alter public API, defaults, cryptographic policy, package API, or other security posture.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project guardrails
- `.planning/ROADMAP.md` — Phase 74 goals, PKG-01..PKG-06 success criteria, ownership boundaries for later phases.
- `.planning/REQUIREMENTS.md` — PKG-01..PKG-06 acceptance boundaries.
- `.planning/PROJECT.md` — v1.11 twin model, package-only consumer goal, non-negotiable security invariants, and approval policy.
- `.planning/STATE.md` — Current phase position and milestone decisions.
- `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md` — Locked two-twin architecture, deterministic evidence requirement, and Phase 74 boundary.

### Existing package and adopter contracts
- `mix.exs` — Package whitelist, optional dependency declarations, compile paths, and supported Mix aliases.
- `lib/mix/tasks/relyra.install.ex` — Current installer behavior and overwrite policy.
- `test/mix/relyra_install_test.exs` — Existing installer behavior tests.
- `lib/relyra/testing.ex` — Shipped public signed-fixture helpers for the real verifier path.
- `guides/getting_started.md` — Supported installer-based Phoenix onboarding path.
- `guides/production_ecto_path.md` — Authoritative migration ownership and runtime-store setup.
- `demo/ledger_loop/lib/ledger_loop/relyra/migrations.ex` — Existing dependency-path migration runner precedent.
- `demo/ledger_loop/priv/repo/migrations/20260612170100_create_relyra_runtime_store_tables.exs` — Host-owned store migration precedent.
- `scripts/check_demo_package_exclusion.sh` — Existing, limited tarball-unpack check to extend or replace.
- `.github/workflows/security-gates.yml` and `.github/workflows/demo-app-ci.yml` — Current blocking BEAM matrix tuples.

### Relevant project research
- `prompts/relyra-engineering-dna-from-prior-libs.md` — Closest sibling-library patterns, especially Sigra's golden installer tree and Scrypath's artifact-consumer verification.
- `prompts/ecto-best-practices-deep-research.md` — Ecto migration and ownership guidance.
- `prompts/elixir-best-practices-deep-research.md` — Elixir/Mix conventions.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Hex package, optional dependency, and adopter-DX guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — CI matrix and package verification tradeoffs.

### External implementation references reviewed
- [Hex `mix hex.build --unpack`](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html) — Build and inspect the exact package artifact before publishing.
- [Mix environment variables](https://mix.hexdocs.pm/main/Mix.html#module-environment-variables) — Isolated Mix home, dependency, and build paths.
- [Phoenix.ConnTest](https://phoenix.hexdocs.pm/1.8.2/Phoenix.ConnTest.html) — In-process request dispatch through a Phoenix endpoint.
- [Ecto.Migrator](https://ecto-sql.hexdocs.pm/Ecto.Migrator.html) — Run migrations owned by a dependency and host app.
- [Mix.Generator](https://hexdocs.pm/mix/Mix.Generator.html) and [Phoenix generators](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.html) — Existing-file conflict and generation conventions.
- [npm pack](https://docs.npmjs.com/cli/v11/commands/npm-pack/) — Cross-ecosystem precedent for testing package contents rather than only the working tree.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Testing` ships framework-neutral signed fixtures plus public adapter helpers; it avoids using private `Relyra.TestSupport` and can drive the real verification path.
- The installer already preserves existing generated files by default and has explicit `--force` behavior.
- `guides/production_ecto_path.md` gives the package migration path and defines which request/replay store tables are host-owned.
- LedgerLoop already demonstrates `Ecto.Migrator.with_repo/3` and separate Relyra versus host migrations.
- Existing CI establishes Elixir 1.19.5 on OTP 27 and OTP 28 as actual repository matrix tuples.

### Established Patterns
- `mix.exs` explicitly builds the package file set and excludes `test_support`; test compilation includes checkout-only support and fixtures, so only an artifact-based consumer can validate the published boundary.
- Optional Phoenix/Ecto/PostgreSQL/Req/Oban dependencies are declared separately; the project already has a `--no-optional-deps` compile proof.
- The closest sibling-library precedent is Sigra's generated-tree and receipt golden comparison. Scrypath separately verifies the post-publish artifact with a throwaway consumer; that is useful precedent, but registry/post-publish machinery exceeds Phase 74's local-artifact goal.
- A path dependency on the unpacked artifact proves package contents and package `mix.exs`; it does not prove registry index or remote fetch behavior.

### Integration Points
- Build the tarball from the repository root, then have a separate harness resolve the unpacked package while its own app, Mix/Hex state, deps, build output, database, and logs stay outside the checkout.
- Consumer boot should use the generated installer surface and a real Phoenix endpoint. The fixture's trust material must be explicitly supplied through normal Relyra config/adapters.
- Run dependency migrations and host migrations separately, then prove the configured persistent request/replay stores operate against the fresh schema.
- Wire all clean-room proofs into an existing mandatory CI contract, preserving current fresh-process CI and security lanes.

</code_context>

<specifics>
## Specific Ideas

- Favor a boring, one-command local developer entry point that prints which profile/command failed and where the isolated artifacts/logs were retained, while CI removes disposable state afterward.
- Keep integration failures user-facing: name the failed command, the consumer path or missing package file/contract, expected behavior, and a concrete recovery action. Never dump assertion XML, private key material, or secrets in diagnostics.
- Do not add UI/brand work; Phase 74 is a headless package and developer workflow. Apply Relyra's calm, explicit operator voice to command output and errors.
- The recommendation is deliberately bounded to the locally built tarball. A local Hex repository or registry round-trip tests resolution/publishing semantics beyond the roadmap's package-content contract.

</specifics>

<deferred>
## Deferred Ideas

- Full SAML rejection/replay/tenant-isolation/diagnosis/recovery journeys — Phase 76.
- Hosted external consumer twin, registry-resolution round-trip, post-publish parity and scheduled drift checks — later only if local artifact evidence is insufficient or adoption evidence demands it.
- Exhaustive compatibility Cartesian matrix — deferred until adoption evidence justifies the cost.
- No todos matched Phase 74 for folding into scope.

</deferred>

---

*Phase: 74-clean-room-package-consumer*
*Context gathered: 2026-09-24*
