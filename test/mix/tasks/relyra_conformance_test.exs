defmodule Mix.Tasks.Relyra.ConformanceTest do
  use ExUnit.Case, async: false

  @moduletag :conformance

  alias Mix.Tasks.Relyra.Conformance

  setup do
    Mix.Task.clear()
    :ok
  end

  test "writes the generated report to a temp output path" do
    temp_output_path = temp_path!("CONFORMANCE.md")

    Conformance.run(["--output", temp_output_path])

    report = File.read!(temp_output_path)

    assert report =~ "# Conformance"
    assert report =~ "CONF-01"
    assert report =~ "CVE-REG-01"
    assert report =~ "unsupported"
    assert report =~ "deferred"
  end

  test "raises when --output points to a missing directory" do
    missing_output_path = Path.join(temp_path!("missing"), "CONFORMANCE.md")

    assert_raise File.Error, fn ->
      Conformance.run(["--output", missing_output_path])
    end
  end

  test "raises when --check target does not exist" do
    missing_output_path = temp_path!("absent-CONFORMANCE.md")

    assert_raise Mix.Error, ~r/--check.*missing|missing.*--check/i, fn ->
      Conformance.run(["--check", "--output", missing_output_path])
    end
  end

  test "raises when --check detects report drift" do
    temp_output_path = temp_path!("drift-CONFORMANCE.md")
    File.write!(temp_output_path, "# Conformance\n\nstale drift\n")

    assert_raise Mix.Error, ~r/drift/i, fn ->
      Conformance.run(["--check", "--output", temp_output_path])
    end
  end

  defp temp_path!(name) do
    Path.join(System.tmp_dir!(), "relyra-conformance-task-#{System.unique_integer([:positive])}-#{name}")
  end
end
