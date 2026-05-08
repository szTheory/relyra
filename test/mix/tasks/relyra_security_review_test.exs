defmodule Mix.Tasks.Relyra.SecurityReviewTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Relyra.SecurityReview

  setup do
    Mix.Task.clear()
    :ok
  end

  test "writes the generated evidence report to a temp output path" do
    temp_output_path = temp_output_path!("SECURITY_REVIEW_EVIDENCE.md")

    SecurityReview.run(["--output", temp_output_path])

    report = File.read!(temp_output_path)

    assert report =~ "# Security Review Evidence"
    assert report =~ "strict default"
    assert report =~ "escape hatch"
    assert report =~ "mix ci.security"
    assert report =~ "mix ci.verify"
  end

  test "raises when --output points to a missing directory" do
    missing_output_path = Path.join(temp_output_path!("missing"), "SECURITY_REVIEW_EVIDENCE.md")

    assert_raise File.Error, fn ->
      SecurityReview.run(["--output", missing_output_path])
    end
  end

  test "raises when --check target does not exist" do
    missing_output_path = temp_output_path!("absent-SECURITY_REVIEW_EVIDENCE.md")

    assert_raise Mix.Error, ~r/--check.*missing|missing.*--check/i, fn ->
      SecurityReview.run(["--check", "--output", missing_output_path])
    end
  end

  test "raises when --check detects report drift" do
    temp_output_path = temp_output_path!("drift-SECURITY_REVIEW_EVIDENCE.md")
    File.write!(temp_output_path, "# Security Review Evidence\n\nstale drift\n")

    assert_raise Mix.Error, ~r/drift/i, fn ->
      SecurityReview.run(["--check", "--output", temp_output_path])
    end
  end

  defp temp_output_path!(name) do
    Path.join(
      System.tmp_dir!(),
      "relyra-security-review-task-#{System.unique_integer([:positive])}-#{name}"
    )
  end
end
