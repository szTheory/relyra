defmodule Mix.Tasks.Relyra.RefreshDueTest do
  @moduledoc """
  Wave 5 (`21-07`) production tests for `Mix.Tasks.Relyra.RefreshDue`.

  Verifies argument-validation flow:
  - `--repo` is required (Mix.raise great-error)
  - the repo string must resolve to a loaded atom (T-21-31 mitigation —
    `String.to_existing_atom/1` rejects unknown atoms)

  The happy path is exercised via `:integration`-tagged scenarios — these
  require a configured host repo + DB and so are deferred to manual
  validation per the Wave 5 validation matrix (Mix-task wiring is the
  manual-only verification noted in `21-VALIDATION.md`).
  """
  use ExUnit.Case, async: false

  alias Mix.Tasks.Relyra.RefreshDue

  describe "run/1 — argument validation" do
    test "raises when --repo is missing" do
      assert_raise Mix.Error, ~r/--repo is required/, fn ->
        RefreshDue.run([])
      end
    end

    test "raises when the named repo is not a loaded atom" do
      assert_raise Mix.Error, ~r/is not loaded/, fn ->
        RefreshDue.run(["--repo", "ThisRepoDoesNotExist.Repo"])
      end
    end
  end
end
