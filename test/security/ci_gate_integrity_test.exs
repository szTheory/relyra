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
  # (nil means the whole file runs). The tag-integrity test proves the tag actually
  # exists in the file source, so `--only <tag>` can never silently match zero tests.
  @gated_suites [
    {"test/security/ci_gate_integrity_test.exs", nil},
    {"test/security/strict_default_proof_test.exs", nil},
    {"test/relyra/ecto/escape_hatch_audit_test.exs", nil},
    {"test/security/xml/corpus_security_test.exs", "security_corpus"},
    {"test/relyra/security/xml/corpus_gate_test.exs", "security_corpus"},
    {"test/security/xml/corpus_security_test.exs", "gate02_c14n"},
    {"test/security/xml/adversarial_crypto_test.exs", "adversarial_crypto"},
    {"test/security/xml_enc_test.exs", nil}
  ]

  # The list of `ci.security` step strings, extracted by parsing mix.exs as actual
  # Elixir AST (NOT byte/bracket scanning). The parser already strips comments and
  # understands string literals, so a stray `]`/`[` in a comment, a markdown list,
  # a CLI flag, or a literal `"ci.security": [` inside a doc string can no longer
  # truncate, over-capture, or shadow the real alias (WR-01, WR-05). We walk the
  # quoted tree for the `aliases/0` keyword entry `"ci.security": [ ... ]` and return
  # its list of step strings (comments already gone, each step a quoted literal).
  defp ci_security_steps do
    ast = Code.string_to_quoted!(File.read!("mix.exs"))

    steps =
      ast
      |> Macro.prewalker()
      |> Enum.find_value(fn
        {key, list} when is_list(list) ->
          if alias_key?(key, "ci.security") and Enum.all?(list, &is_binary/1) do
            list
          end

        _ ->
          nil
      end)

    refute steps == nil,
           "could not find the `\"ci.security\": [ ...string steps... ]` alias in mix.exs — " <>
             "the security lane may have been renamed, removed, or restructured so its steps " <>
             "are no longer a flat list of strings"

    steps
  end

  # A keyword key in quoted form. A quoted atom keyword key like `"ci.security":`
  # parses to the bare atom `:"ci.security"`; plain `foo:` parses to `:foo`. Accept
  # both, and tolerate the variable-node form `{atom, _meta, ctx}` defensively.
  defp alias_key?(key, name) when is_atom(key), do: Atom.to_string(key) == name

  defp alias_key?({key, _meta, ctx}, name) when is_atom(key) and is_atom(ctx),
    do: Atom.to_string(key) == name

  defp alias_key?(_key, _name), do: false

  # The ci.security STEP strings that reference `path`. Because steps come from the
  # AST (comments already stripped), every returned step is a real alias step. A
  # single `cmd mix test a.exs b.exs --only tag` step names MULTIPLE files, so a
  # substring match on `path` correctly covers a suite that shares its step line
  # with a sibling suite (WR-03).
  defp steps_referencing(steps, path) do
    Enum.filter(steps, &String.contains?(&1, path))
  end

  test "every gated security suite file exists on disk (T-30-14 presence)" do
    for {path, _tag} <- @gated_suites do
      assert File.exists?(path),
             "gated security suite #{path} is named in ci.security but does not exist on disk — " <>
               "the alias would error or the gate would be hollow"
    end
  end

  test "every gated security suite is named in the ci.security alias" do
    steps = ci_security_steps()

    for {path, _tag} <- @gated_suites do
      assert steps_referencing(steps, path) != [],
             "gated security suite #{path} is NOT referenced in any ci.security step — " <>
               "it would never run in the security lane (hollow gate)"
    end
  end

  test "every gated suite runs as a `cmd mix test` step, never a bare `test` step (anti-hollow)" do
    steps = ci_security_steps()

    for {path, _tag} <- @gated_suites do
      matching_steps = steps_referencing(steps, path)

      refute matching_steps == [],
             "no ci.security step references #{path} (cannot verify it is a `cmd mix test` step)"

      for step <- matching_steps do
        trimmed = String.trim_leading(step)

        refute Regex.match?(~r/^test\s/, trimmed),
               "ci.security runs #{path} via a BARE `test` step:\n\n  #{trimmed}\n\n" <>
                 "mix dedups the `test` task within one alias run and ci.conformance already " <>
                 "consumed it with `--only conformance`, so this suite would be silently skipped " <>
                 "(hollow gate). Use `cmd mix test ...` (a fresh OS process) instead."

        assert Regex.match?(~r/^cmd mix test\s/, trimmed),
               "ci.security step for #{path} must be a `cmd mix test ...` step but is:\n\n  #{trimmed}"
      end
    end
  end

  test "every `--only <tag>` filter used by ci.security exists in the suite's source (tag integrity)" do
    for {path, tag} <- @gated_suites, tag != nil do
      source = File.read!(path)

      # Anchor on a whole-atom boundary (`\b` after the tag). A plain substring match
      # (`source =~ "@tag :\#{tag}"`) would let a PREFIX tag pass: `--only security`
      # would falsely match `@tag :security_corpus` yet `mix test --only security`
      # matches ZERO tests, leaving the gate hollow (WR-02).
      assert Regex.match?(~r/@(module)?tag\s+:#{Regex.escape(tag)}\b/, source),
             "ci.security runs #{path} with `--only #{tag}` but the file declares no exact " <>
               "`@tag :#{tag}` or `@moduletag :#{tag}` — `--only #{tag}` would silently match " <>
               "ZERO tests, leaving the gate hollow"
    end
  end
end
