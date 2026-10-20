defmodule Relyra.Security.MutationLaneTest do
  @moduledoc """
  Phase 83 — governance for the mutation-testing lane (MUT-01..MUT-03) and the
  anti-weakening guard for the permanent security corpora.

  Mutation testing kills survivors by *adding* sharper tests, fixing real slack,
  or marking a provably-equivalent mutant — NEVER by deleting a test. These
  guards make a quiet deletion fail the build, and pin the lane's shape: mutare
  (exact), each mutant in a fresh `mix test` process, and the lane strictly
  outside `ci-gate`.
  """

  use ExUnit.Case, async: true

  @moduletag :mutation_lane

  @mutare_config ".mutare.exs"
  @mutation_workflow ".github/workflows/mutation.yml"
  @security_gates ".github/workflows/security-gates.yml"

  describe "mutare dependency and config" do
    test "mutare is pinned to an exact version, dev/test only, no runtime" do
      mix_exs = File.read!("mix.exs")

      assert mix_exs =~
               ~r/\{:mutare,\s*"0\.5\.1",\s*only:\s*\[:dev,\s*:test\],\s*runtime:\s*false\}/,
             "mutare must be exact-pinned (0.5.1), only: [:dev, :test], runtime: false"
    end

    test ".mutare.exs scopes mutation to the security core and nothing else" do
      {config, _binding} = Code.eval_file(@mutare_config)
      paths = Keyword.fetch!(config, :paths)

      assert paths != [], "mutation scope must not be empty"

      Enum.each(paths, fn path ->
        assert path =~ ~r{^lib/relyra/(security|protocol|metadata)/},
               "mutation scope must stay within the trust core, got: #{path}"

        assert File.exists?(path), "configured mutation path does not exist: #{path}"
      end)

      # The crypto gate, the signed-node binding, algorithm policy and the XML
      # seam are the core that must be mutation-covered.
      for required <- [
            "lib/relyra/security/signature.ex",
            "lib/relyra/security/algorithm_policy.ex",
            "lib/relyra/security/xml/pure_beam.ex",
            "lib/relyra/protocol/validation_pipeline.ex"
          ] do
        assert required in paths, "security core module missing from mutation scope: #{required}"
      end
    end

    test "each mutant runs in a fresh `mix test` process (coverage-selected, not in-process)" do
      {config, _binding} = Code.eval_file(@mutare_config)
      # mutare always runs each mutant in its own `mix test` OS process; :tests /
      # :coverage are the per-mutant selection modes (fresh process each), never
      # an in-process shortcut. Pin to that model.
      selection = Keyword.get(config, :test_selection, :tests)
      assert selection in [:tests, :coverage]
    end
  end

  describe "mutation workflow is scheduled, non-gating, and hermetic" do
    test "mutation.yml runs mutare on schedule + dispatch only, never on PR/push" do
      wf = File.read!(@mutation_workflow)

      assert wf =~ ~r/\bschedule:/, "mutation lane must be scheduled"
      assert wf =~ ~r/\bworkflow_dispatch:/, "mutation lane must be manually dispatchable"
      refute wf =~ ~r/^\s*pull_request:/m, "mutation lane must not trigger on pull_request"
      refute wf =~ ~r/^\s*push:/m, "mutation lane must not trigger on push"
      assert wf =~ ~r/\bmix mutare\b/, "mutation lane must invoke mix mutare"

      assert wf =~ "RELYRA_MUTATION_SUITE",
             "mutation lane must scope the baseline to hermetic suites"

      assert wf =~ ~r/upload-artifact/, "mutation lane must upload the score report"
      assert wf =~ "mutare.json", "mutation lane must emit the JSON (Stryker-schema) score report"
    end

    test "the mutation lane is absent from ci-gate" do
      gates = File.read!(@security_gates)

      # ci-gate's required lanes are exactly security / phase73-reconciliation /
      # package-consumers — a mutation job must never be wired in.
      refute gates =~ ~r/\bmix mutare\b/, "security-gates.yml must not run mutation testing"
      refute gates =~ "mutation.yml"
      refute gates =~ ~r/needs:[^]]*mutation/, "ci-gate must not depend on a mutation job"
    end
  end

  describe "anti-weakening guard: no permanent security row may be deleted" do
    test "the adversarial crypto corpus keeps its permanent gating rows" do
      source = File.read!("test/security/xml/adversarial_crypto_test.exs")
      count = source |> String.split(~r/^\s+test "/m) |> length() |> Kernel.-(1)

      assert count >= 7,
             "adversarial_crypto_test.exs lost rows (#{count} < 7) — survivors are killed by " <>
               "ADDING tests, never by deleting this permanently-gating corpus"
    end

    test "the trust-binding corpus keeps its rows" do
      source = File.read!("test/security/xml/trust_binding_test.exs")
      count = source |> String.split(~r/^\s+test "/m) |> length() |> Kernel.-(1)
      assert count >= 21, "trust_binding_test.exs lost rows (#{count} < 21)"
    end

    test "the JSON security corpus keeps its entries" do
      entries = "priv/security_corpus.json" |> File.read!() |> :json.decode()

      assert length(entries) >= 8,
             "priv/security_corpus.json lost entries (#{length(entries)} < 8)"
    end

    test "the adversarial property gate is still present" do
      assert File.exists?("test/security/xml/adversarial_property_test.exs")
    end
  end
end
