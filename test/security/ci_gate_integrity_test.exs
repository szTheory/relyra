defmodule Relyra.Security.CiGateIntegrityTest do
  @moduledoc """
  Anti-hollow meta-gate for the `ci.security` Mix alias.

  ## Why this test exists

  `mix` deduplicates the `test` task within a single `mix` invocation: if an alias
  runs `test` more than once, only the FIRST `test` actually executes, and every
  later bare `test` step is silently skipped. Worse, `ci.security` runs
  `ci.conformance` first, which runs `test ... --only conformance`. That means any
  later *bare* `test` step in `ci.security` was both skipped AND would have inherited
  the `--only conformance` filter — so the security lane was hollow: a regression in a
  security suite would still ship green.

  The fix is to run each security suite as its own `cmd mix test ...` step — a fresh
  OS process per suite, immune to the in-alias dedup and filter bleed. This meta-gate
  is the structural guard (T-30-14) that fails the build if anyone re-introduces the
  dedup bug by collapsing a `cmd mix test` line back into a bare `test` line, drops a
  gated suite from the alias, deletes a gated suite file, or removes a tag that
  `--only <tag>` depends on (which would otherwise silently match zero tests).

  This test carries no default-excluded tag (only `:pending` is excluded by default),
  so it runs under plain `mix test`, and it is also named explicitly as its own
  `cmd mix test` step in `ci.security` — so the gate gates itself.
  """
  use ExUnit.Case, async: true

  # The security contract: {relative_path, tag_or_nil}.
  # tag_or_nil is the `--only <tag>` filter that ci.security applies to that suite
  # (nil means the whole file runs). Test 4 proves the tag actually exists in the
  # file source, so `--only <tag>` can never silently match zero tests.
  @gated_suites [
    {"test/security/ci_gate_integrity_test.exs", nil},
    {"test/security/strict_default_proof_test.exs", nil},
    {"test/relyra/ecto/escape_hatch_audit_test.exs", nil},
    {"test/security/xml/corpus_security_test.exs", "security_corpus"},
    {"test/security/xml/corpus_security_test.exs", "gate02_c14n"},
    {"test/security/xml/adversarial_crypto_test.exs", "adversarial_crypto"}
  ]

  # Slice the literal `"ci.security": [ ... ]` block out of mix.exs by a bracket-depth
  # scan starting at the alias header. Resilient to comment lines and reordering.
  defp ci_security_block do
    source = File.read!("mix.exs")
    start = :binary.match(source, "\"ci.security\": [")

    refute start == :nomatch,
           "could not find the `\"ci.security\": [` alias in mix.exs — the security lane may have been renamed or removed"

    {offset, _len} = start
    # position the cursor at the opening bracket of the alias list
    open_idx = offset + byte_size("\"ci.security\": ")
    rest = binary_part(source, open_idx, byte_size(source) - open_idx)
    scan_block(rest, 0, 0, [])
  end

  # Walk the source from the opening `[`, tracking bracket depth, until the matching
  # `]` closes the alias list. Returns the inclusive `[ ... ]` text.
  defp scan_block(<<>>, _depth, _idx, _acc) do
    flunk("ci.security alias block in mix.exs is not balanced — could not find closing `]`")
  end

  defp scan_block(<<char::utf8, tail::binary>>, depth, idx, acc) do
    new_depth =
      case char do
        ?[ -> depth + 1
        ?] -> depth - 1
        _ -> depth
      end

    acc = [acc | <<char::utf8>>]

    if new_depth == 0 do
      IO.iodata_to_binary(acc)
    else
      scan_block(tail, new_depth, idx + 1, acc)
    end
  end

  test "every gated security suite file exists on disk (T-30-14 presence)" do
    for {path, _tag} <- @gated_suites do
      assert File.exists?(path),
             "gated security suite #{path} is named in ci.security but does not exist on disk — " <>
               "the alias would error or the gate would be hollow"
    end
  end

  # The ci.security STEP lines that reference `path`, excluding comment lines (which
  # start with `#` and may legitimately name a suite, e.g. the self-referencing
  # anti-hollow comment). Only real alias steps are quoted string literals.
  defp step_lines(block, path) do
    block
    |> String.split("\n")
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.filter(&String.contains?(&1, path))
  end

  test "every gated security suite is named in the ci.security alias" do
    block = ci_security_block()

    for {path, _tag} <- @gated_suites do
      assert step_lines(block, path) != [],
             "gated security suite #{path} is NOT referenced in any ci.security step — " <>
               "it would never run in the security lane (hollow gate)"
    end
  end

  test "every gated suite runs as a `cmd mix test` step, never a bare `test` step (anti-hollow)" do
    block = ci_security_block()

    for {path, _tag} <- @gated_suites do
      matching_lines = step_lines(block, path)

      refute matching_lines == [],
             "no ci.security step references #{path} (cannot verify it is a `cmd mix test` step)"

      for line <- matching_lines do
        trimmed = String.trim_leading(line)

        refute Regex.match?(~r/^"test\s/, trimmed),
               "ci.security runs #{path} via a BARE `test` step:\n\n  #{trimmed}\n\n" <>
                 "mix dedups the `test` task within one alias run and ci.conformance already " <>
                 "consumed it with `--only conformance`, so this suite would be silently skipped " <>
                 "(hollow gate). Use `cmd mix test ...` (a fresh OS process) instead."

        assert Regex.match?(~r/^"cmd mix test\s/, trimmed),
               "ci.security line for #{path} must be a `cmd mix test ...` step but is:\n\n  #{trimmed}"
      end
    end
  end

  test "every `--only <tag>` filter used by ci.security exists in the suite's source (tag integrity)" do
    for {path, tag} <- @gated_suites, tag != nil do
      source = File.read!(path)

      assert source =~ "@tag :#{tag}" or source =~ "@moduletag :#{tag}",
             "ci.security runs #{path} with `--only #{tag}` but the file declares no " <>
               "`@tag :#{tag}` or `@moduletag :#{tag}` — `--only #{tag}` would silently match " <>
               "ZERO tests, leaving the gate hollow"
    end
  end
end
