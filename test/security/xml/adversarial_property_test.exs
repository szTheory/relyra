defmodule Relyra.Security.XML.AdversarialPropertyTest do
  @moduledoc """
  Phase 82 — the adversarial twin's property gate (PROP-01..PROP-05).

  Genuinely signed SAML documents are mutated by a shrinkable op list and driven
  through the real public APIs. The oracle (`Relyra.Twin.Oracle`) holds the
  trust-path invariant: a result is accepted ONLY when the consumed identity
  equals exactly what the generator signed; otherwise it must be a typed
  rejection from the allowlist — never a crash, a timeout, or a tampered accept.

  This is the BOUNDED, SEEDED lane wired into `mix ci.security`. The deep-run
  workflow (`.github/workflows/adversarial-deep.yml`) runs the same properties
  with a far larger `max_runs` and a printed random seed, outside `ci-gate`.

  `TWIN_MAX_RUNS` overrides the per-property run count (the deep lane sets it).
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  @moduletag :adversarial_property

  alias Relyra.Twin.Generators
  alias Relyra.Twin.Mint
  alias Relyra.Twin.Mutations
  alias Relyra.Twin.Oracle
  alias Relyra.Twin.Runner

  @max_runs String.to_integer(System.get_env("TWIN_MAX_RUNS", "120"))

  # ---------------------------------------------------------------------------
  # Positive control — the twin signer mints genuinely accepted documents
  # (roadmap #1 self-test), for every kind.
  # ---------------------------------------------------------------------------

  describe "twin signer self-test" do
    for kind <- Mint.kinds() do
      test "an unmutated #{kind} twin document verifies to its signed truth" do
        doc = Mint.mint(unquote(kind))
        assert Oracle.judge(doc) == :legal
        assert {:ok, _consumed} = Oracle.run(doc)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # The invariant property — per kind and across all kinds.
  # ---------------------------------------------------------------------------

  for kind <- Mint.kinds() do
    property "#{kind}: a mutated signed document is accepted only with its signed truth, else typed-rejected" do
      check all plan <- Generators.plan_for(unquote(kind)), max_runs: @max_runs do
        doc = Runner.realize(plan)

        case Oracle.judge(doc) do
          :legal ->
            :ok

          {:defect, reason, detail} ->
            flunk("""
            Trust-path invariant violated (#{unquote(kind)}): #{inspect(reason)}
              detail:   #{inspect(detail, limit: 8, printable_limit: 400)}
              strategy: #{plan.strategy}
              base:     #{inspect(plan.base_opts)}
              ops:      #{inspect(plan.ops, limit: 12)}
              payload:  #{String.slice(doc.payload, 0, 400)}
            """)
        end
      end
    end
  end

  property "all kinds: the invariant holds across the full generator" do
    check all plan <- Generators.plan(), max_runs: @max_runs * 2 do
      doc = Runner.realize(plan)
      assert Oracle.judge(doc) == :legal
    end
  end

  # ---------------------------------------------------------------------------
  # Generator coverage — every mutation family is reachable (roadmap #2).
  # ---------------------------------------------------------------------------

  describe "generator coverage" do
    test "every byte-op family is produced by the generators" do
      op_families =
        [:login, :logout_post, :metadata, :logout_redirect]
        |> Enum.flat_map(fn kind ->
          Generators.plan_for(kind)
          |> Enum.take(400)
          |> Enum.flat_map(& &1.ops)
          |> Enum.map(&Mutations.family_of/1)
        end)
        |> MapSet.new()

      # Every family except :time_boundary is realized as a byte op.
      byte_families = Mutations.families() -- [:time_boundary]

      missing = byte_families -- MapSet.to_list(op_families)
      assert missing == [], "mutation families never generated: #{inspect(missing)}"

      # the redirect query has its own op taxonomy (duplicate/append param, byte
      # flip) — assert it is reachable too
      assert MapSet.member?(op_families, :redirect_query),
             "redirect-query mutations never generated"
    end

    test "the :time_boundary family is realized as a base-mint parameter" do
      saw_time_edge? =
        Generators.plan_for(:login)
        |> Enum.take(400)
        |> Enum.any?(fn plan ->
          Keyword.has_key?(plan.base_opts, :not_before) or
            Keyword.has_key?(plan.base_opts, :not_on_or_after)
        end)

      assert saw_time_edge?, ":time_boundary edge never generated in base_opts"
    end
  end

  # ---------------------------------------------------------------------------
  # Oracle meta-test — a deliberately planted binding bug must be caught
  # (roadmap #3).
  # ---------------------------------------------------------------------------

  describe "oracle self-check" do
    test "a planted value-binding mismatch is reported as a defect" do
      # The pipeline will (correctly) return the real signed NameID; by claiming
      # the generator signed a DIFFERENT value, we simulate a binding bug where
      # the consumed value diverges from what was signed. The oracle must catch
      # it rather than pass it as legal.
      doc = Mint.mint(:login)
      planted = %{doc | truth: %{doc.truth | name_id: "planted-binding-bug@example.com"}}

      assert {:defect, :accepted_value_mismatch, _} = Oracle.judge(planted)
    end

    test "a generic internal-error wrapper is NOT an allowlisted typed rejection" do
      # Masked crashes must surface as defects, so internal wrappers stay off the
      # allowlist.
      refute MapSet.member?(Oracle.allowed_error_types(), :internal_protocol_error)
      refute MapSet.member?(Oracle.allowed_error_types(), :internal_error)
    end
  end
end
