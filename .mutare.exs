# Phase 83 — mutation testing of the security core (MUT-01..MUT-03).
#
# Mutare mutates the source you write and compiles ONE metamutant, then runs the
# suite per mutant in a fresh `mix test` OS process (coverage-selected). This is
# a SCHEDULED, non-gating lane (.github/workflows/mutation.yml) — never part of
# ci-gate. It measures whether the security-core tests actually detect broken
# checks; survivors are killed with sharper tests, fixed in source with a corpus
# row, or marked `# mutare:ignore <reason>` when provably equivalent.
#
# Scope: the PURE trust core — signature verification, the signed-node binding,
# algorithm policy, the XML seam (SaxyTree/PureBeam/C14N), the protocol
# validation pipeline, the logout validator, and the metadata parser. The
# Ecto-backed replay stores and metadata-apply path are DEFERRED to a later
# pass: they need the `mutare_ecto` companion for their schema macros, and their
# trust-relevant checks already route through the modules below. See
# .planning/phases/83-*/83-01-SUMMARY.md § residual.
[
  paths: [
    "lib/relyra/security/signature.ex",
    "lib/relyra/security/signed_node.ex",
    "lib/relyra/security/algorithm_policy.ex",
    "lib/relyra/security/logout_validator.ex",
    "lib/relyra/security/xml/pure_beam.ex",
    "lib/relyra/security/xml/c14n.ex",
    "lib/relyra/security/xml/saxy_tree.ex",
    "lib/relyra/protocol/validation_pipeline.ex",
    "lib/relyra/metadata/parser.ex"
  ],

  # Telemetry spans and Logger calls carry no trust logic; leave their bodies as
  # written so mutants land on the security checks, not on instrumentation.
  call_routes: [
    {Relyra.Telemetry, :span, :raw},
    {Logger, :*, :skip}
  ],

  # Coverage-guided: run only the test cases that cover each mutant, in a fresh
  # `mix test` process. One worker + one DB keeps the sandbox's Postgres use
  # single-tenant (no per-partition databases to provision).
  test_selection: :tests,
  workers: 1,
  baseline_retries: 1,
  # a runaway mutation (unbounded recursion/allocation) dies as a test failure
  # instead of OOMing the runner
  max_heap_mb: 2048
]
