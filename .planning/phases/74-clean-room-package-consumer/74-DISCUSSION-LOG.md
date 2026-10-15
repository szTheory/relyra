# Phase 74: Clean-Room Package Consumer - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `74-CONTEXT.md` — this log preserves the analysis and tradeoffs.

**Date:** 2026-09-24
**Phase:** 74-clean-room-package-consumer
**Mode:** assumptions + user-requested research-backed recommendation
**Areas analyzed:** Package boundary and isolation; Phoenix runtime exercise; migration ownership; installer drift and adopter safety; compatibility profiles

## Assumptions Presented

### Package Boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The unpacked local Hex artifact is the only Relyra source visible to the consumer; Mix, deps, build, DB, and output paths are isolated from the checkout. | Confident | `.planning/ROADMAP.md`; `.planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md`; `mix.exs`; `scripts/check_demo_package_exclusion.sh` |

### Phoenix Runtime Exercise
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A real endpoint should process one valid signed response using shipped `Relyra.Testing` fixtures; compile or route-only boot proof is too weak. | Likely | `.planning/ROADMAP.md`; `lib/relyra/testing.ex`; `lib/mix/tasks/relyra.install.ex`; Phase 73 context |

### Migration Ownership
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Apply Relyra dependency migrations and consumer-owned request/replay migrations separately against an empty DB. | Confident | `guides/production_ecto_path.md`; `demo/ledger_loop/lib/ledger_loop/relyra/migrations.ex`; `demo/ledger_loop/priv/repo/migrations/20260612170100_create_relyra_runtime_store_tables.exs` |

### Installer and Compatibility Profiles
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve generated files by default and use explicit `--force`; verify both fresh output and upgrade from a prior scaffold. | Likely | `lib/mix/tasks/relyra.install.ex`; `test/mix/relyra_install_test.exs`; `prompts/relyra-engineering-dna-from-prior-libs.md` (Sigra installer golden) |
| Use current repo tuples (Elixir 1.19.5 / OTP 27 and 28), with full optional integrations and a no-optional-dependencies profile rather than an exhaustive matrix. | Likely | `mix.exs`; `.github/workflows/security-gates.yml`; `.github/workflows/demo-app-ci.yml`; CI and Elixir prompts |

## Research and Tradeoffs

### 1. Package boundary and isolation

| Approach | Advantages | Tradeoffs / footguns | Decision |
|---|---|---|---|
| Use the working tree or the existing demo's path dependency | Fast and familiar; reuses existing test and demo infrastructure. | Checkout test paths, `_build`, dependencies, or fixture modules can satisfy missing package contents. A path-dependency app does not prove the package's shipping boundary. | Reject as acceptance proof. Retain only as ordinary regression coverage. |
| Build and unpack the local Hex tarball, then use the unpacked artifact as the consumer's path dependency | Exercises the exact locally generated package tree and its `mix.exs`; easy to inspect and to create a deliberate package-omission control. Hex recommends `--unpack` to inspect contents before publishing. | Does not exercise remote registry/index resolution; harness must prove the dependency path points to the unpacked artifact. | Recommend. This matches the roadmap's artifact-content contract with the fewest moving parts. |
| Stage a local Hex repository and resolve through its registry/index | Adds package-resolution and repository-format evidence. | More moving parts and failure modes than the phase needs; a failure can be ambiguous between package omission and local registry setup. | Defer; use only if registry-resolution behavior becomes an acceptance target. |
| Use one temporary project directory | Simple, with less setup. | Ambient Mix archives/config, caches, dependency/build output, and inherited paths remain potential leaks. | Insufficient for mandatory boundary proof. |
| Isolate `HOME`, `MIX_HOME`, `HEX_HOME`, `MIX_DEPS_PATH`, `MIX_BUILD_ROOT`, DB, logs, and project under a task-owned temp root | Makes checkout leakage observable and keeps consumer state reproducible; Mix explicitly exposes these path controls. | Bootstrap requires care to preserve BEAM executables on `PATH`, and errors must distinguish missing toolchain setup from package failure. | Recommend for CI; use clear phase-labelled paths and preserve logs on failure. |

Cross-project lesson: npm's official `npm pack` workflow exemplifies testing the package payload rather than assuming the repository tree equals the release. Within the Relyra library family, Sigra's installer golden and Scrypath's throwaway post-publish consumer both validate generated/released surfaces. Use the artifact-first principle here; defer Scrypath's registry polling, post-publish parity, and recurring drift machinery because Phase 74 targets a local artifact.

Sources: [Hex build/unpack](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html), [Mix environment variables](https://mix.hexdocs.pm/main/Mix.html#module-environment-variables), [npm pack](https://docs.npmjs.com/cli/v11/commands/npm-pack/), `prompts/relyra-engineering-dna-from-prior-libs.md`.

### 2. Phoenix runtime exercise

| Approach | Advantages | Tradeoffs / footguns | Decision |
|---|---|---|---|
| Compile plus health route / boot | Quick; catches dependency, config, supervision, and routing startup failures. | It can pass with broken ACS response processing, missing trust wiring, or an unused crypto path. | Keep as prerequisite evidence, not the whole smoke proof. |
| Submit a valid signed SAML response through the real Phoenix endpoint | Exercises consumer configuration, request parsing, configured trust, crypto verification, Phoenix integration, and the adopter success outcome. `Phoenix.ConnTest` dispatches through the endpoint without requiring a listening socket. | Requires a stable fixture and explicit config; importing root signing helpers would silently invalidate the proof. | Recommend one real signed success through the actual router using package-shipped `Relyra.Testing` helpers. |
| Make a self-contained fixture/signing implementation in the consumer | Fully independent of the test-helper package surface. | Duplicates crypto fixture logic and increases chance of a test signer or fixture bug; the project intentionally publishes `Relyra.Testing` for this use. | Avoid while the public helper remains the intended fixture seam. |
| Add full rejection/replay/tenant/recovery journey coverage here | Stronger coverage in one harness. | Duplicates Phase 76 lifecycle scope and creates a second large journey suite to maintain. | Defer. Phase 74 proves one verified package-backed success; Phase 76 owns the broader lifecycle corpus. |

Source: [Phoenix.ConnTest](https://phoenix.hexdocs.pm/1.8.2/Phoenix.ConnTest.html), `lib/relyra/testing.ex`, Phase 74 in `.planning/ROADMAP.md`.

### 3. Migration ownership

| Approach | Advantages | Tradeoffs / footguns | Decision |
|---|---|---|---|
| Run packaged Relyra migrations from the dependency path; run adopter request/replay migrations in the consumer | Proves `priv` migrations shipped and match documented library/host ownership; exercises real DB integration. | Needs two explicit migration paths and a pristine PostgreSQL service. | Recommend. Match the production guide and LedgerLoop precedent. |
| Copy Relyra migrations into the host app during installation | Lets every migration sit in the host directory. | Creates stale copies, collisions, and unclear upgrades; changes a clearly documented install contract. | Reject. |
| Rely on root database tests or LedgerLoop's existing CI | Reuses mature DDL and adapters quickly. | Those paths can load checkout-only files and do not prove the artifact contains its migrations. | Useful regression coverage, not Phase 74 proof. |
| Check table existence only | Cheap. | Misses column, index, uniqueness, and SQL behavior required by request/replay adapters. | Reject as insufficient; exercise representative adapter operations. |

Source: [Ecto.Migrator](https://ecto-sql.hexdocs.pm/Ecto.Migrator.html), `guides/production_ecto_path.md`, LedgerLoop migration paths in the CONTEXT canonical refs.

### 4. Installer drift and adopter safety

| Approach | Advantages | Tradeoffs / footguns | Decision |
|---|---|---|---|
| Preserve existing generated files; only explicit `--force` overwrites | Protects adopter edits and matches current behavior; predictable in scripts. | A rerun may leave old scaffolds in place; force can destroy customizations and is not an upgrade process. | Keep current behavior and label `--force` destructive. |
| Content-aware interactive conflict prompts | Can distinguish pristine generated files from adopter edits; follows Mix generator conventions. | Can stall CI or force unsafe prompt defaults; does not itself prove upgrade compatibility. | Do not add to this phase. |
| Golden fresh-install tree and receipt | Makes generated paths/content/router injection/output changes reviewable; close precedent in Sigra. | Does not establish that an earlier adopter scaffold survives a package upgrade. | Recommend for fresh-install contract. |
| Upgrade fixture seeded from a previous generated scaffold, then compile/boot with current artifact | Exercises actual stale generated code and gives concrete drift evidence. | Requires a maintained prior-state fixture; fixture must not mask package resolution. | Pair with golden to satisfy PKG-06; fail with exact command and file/route/contract diagnostic. |

Sources: [Mix.Generator](https://hexdocs.pm/mix/Mix.Generator.html), [Phoenix generator docs](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.html), [Phoenix schema generator](https://github.com/phoenixframework/phoenix/blob/main/lib/mix/tasks/phx.gen.schema.ex), [Phoenix New generator](https://github.com/phoenixframework/phoenix/blob/main/installer/lib/phx_new/generator.ex), `prompts/relyra-engineering-dna-from-prior-libs.md`.

### 5. BEAM and optional-dependency profiles

| Approach | Advantages | Tradeoffs / footguns | Decision |
|---|---|---|---|
| Test only one full environment | Cheapest. | Does not reveal optional-dependency compile leaks or current OTP tuple differences. | Insufficient for PKG-05. |
| Full Cartesian product of all BEAM versions and each optional dependency permutation | Broadest combinations. | Slow and redundant; matrix size grows multiplicatively and obscures ownership of each profile. | Avoid absent adopter evidence that justifies cost. |
| Use repository's current Elixir 1.19.5 / OTP 27 and OTP 28 tuples; pair a full Phoenix/Ecto/PostgreSQL run with `--no-optional-deps` compilation | Matches blocking CI reality and existing library guidance; covers a usable adopter and absence of optional deps without false breadth. | Does not exercise every optional integration independently, so each selected lane must state what it owns. | Recommend; add one focused optional profile only when Phase 74 acceptance or actual usage requires it. |

Sources: `.github/workflows/security-gates.yml`, `.github/workflows/demo-app-ci.yml`, `mix.exs`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, and [setup-beam version guidance](https://github.com/erlef/setup-beam/blob/main/README.md).

## Corrections Made

No corrections. The user asked for broad research and delegated the final choices to the agent; recommendations above are captured as locked Phase 74 decisions.

## External Research

- Package artifact: Hex build/unpack docs plus Mix's isolated environment variables support inspecting and consuming the exact archive contents locally.
- Phoenix request exercise: `Phoenix.ConnTest` dispatches in-process through the real endpoint, providing high-signal integration proof without an unnecessary network listener.
- Migration ownership: Ecto Migrator supports dependency-path migration execution; Relyra's guide and LedgerLoop already separate package-owned configuration tables from host-owned request/replay DDL.
- Installer: Mix/Phoenix generator conventions make file conflicts visible; Sigra's prior golden-tree and receipt snapshots are a close local precedent. A golden alone is not an upgrade test.
- Other ecosystems: npm `pack` validates package payloads directly, reinforcing artifact-first proof over source-tree proof.
- No external research gap remains for context capture.
