defmodule Mix.Tasks.Relyra.BatteriesIncludedTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Relyra.BatteriesIncluded

  setup do
    Mix.Task.clear()
    :ok
  end

  test "writes the generated proof artifact to a temp output path" do
    temp_output_path = temp_output_path!("BATTERIES_INCLUDED.md")

    BatteriesIncluded.run(["--output", temp_output_path])

    report = File.read!(temp_output_path)

    assert report =~ "# Batteries Included Proof"
    assert report =~ "local-first proof uses testing fixtures"
    assert report =~ "`Relyra.Testing` data-first helpers"
    assert report =~ "`mix test test/testing_demo_test.exs --warnings-as-errors`"
    assert report =~ "`test/testing_demo_test.exs`"
    refute report =~ "test/test_support_demo_test.exs"
    refute report =~ "Relyra.TestSupport"

    assert report =~
             "Okta, Microsoft Entra ID, Google Workspace, Active Directory Federation Services"

    assert report =~ "guides/recipes/adfs.md"
    assert report =~ "scheduled refresh"
    assert report =~ "diagnostic"
  end

  test "raises when --output points to a missing directory" do
    missing_output_path = Path.join(temp_output_path!("missing"), "BATTERIES_INCLUDED.md")

    assert_raise File.Error, fn ->
      BatteriesIncluded.run(["--output", missing_output_path])
    end
  end

  test "raises when --check target does not exist" do
    missing_output_path = temp_output_path!("absent-BATTERIES_INCLUDED.md")

    assert_raise Mix.Error, ~r/--check.*missing|missing.*--check/i, fn ->
      BatteriesIncluded.run(["--check", "--output", missing_output_path])
    end
  end

  test "raises when --check detects artifact drift" do
    temp_output_path = temp_output_path!("drift-BATTERIES_INCLUDED.md")
    File.write!(temp_output_path, "# Batteries Included Proof\n\nstale drift\n")

    assert_raise Mix.Error, ~r/drift/i, fn ->
      BatteriesIncluded.run(["--check", "--output", temp_output_path])
    end
  end

  defp temp_output_path!(name) do
    Path.join(
      System.tmp_dir!(),
      "relyra-batteries-included-task-#{System.unique_integer([:positive])}-#{name}"
    )
  end
end
