defmodule Relyra.Docs.TroubleshootingDriftTest do
  @moduledoc """
  Bidirectional drift gate for `guides/troubleshooting.md`.

  ## Why this test exists

  The SAML Error Atom Decoder (`guides/troubleshooting.md`, DOCS-06) is the
  operator-facing dictionary for every typed rejection Relyra emits. Without a
  build-time gate, the decoder rots the first time someone adds an atom in
  `lib/` without updating the guide (or removes an atom without pruning the
  guide). This test asserts taxonomy parity in both directions:

    * **Missing-in-doc:** every atom emitted by Relyra via a literal
      `Error.new(:atom, ...)` or `%Relyra.Error{type: :atom}` site somewhere
      under `lib/` MUST have a corresponding `### :atom` H3 entry in
      `guides/troubleshooting.md`.
    * **Stale-in-doc:** every `### :atom` H3 entry in
      `guides/troubleshooting.md` MUST correspond to an atom Relyra still
      emits. Pruning the codebase requires pruning the guide.

  Failure-message vocabulary mirrors `test/security/ci_gate_integrity_test.exs`
  (subject — consequence) so the CI experience stays consistent across the
  project's hollow-gate-style meta-tests.

  ## How atoms are enumerated

  Three byte-regex patterns are applied to every `lib/**/*.ex` source file
  (the D-08 contract from `.planning/phases/40-operational-polish-error-taxonomy/40-CONTEXT.md`):

    * `~r/Error\\.new\\(\\s*:([a-z_][a-z0-9_]*)/` — single-line constructor.
    * `~r/Error\\.new\\(\\s*\\n\\s*:([a-z_][a-z0-9_]*)/` — multi-line
      constructor (heavily used in `lib/relyra/protocol/validation_pipeline.ex`
      and `lib/relyra/metadata/auto_refresh.ex`).
    * `~r/%Relyra\\.Error\\{type:\\s*:([a-z_][a-z0-9_]*)/` — struct literal,
      used in `lib/relyra/live_admin/connections_live.ex`,
      `lib/relyra/metadata/trust_anchor.ex`, `lib/relyra/security/xml/c14n.ex`,
      and `lib/relyra/security/xml/corpus_gate.ex`.

  The canonical emitted-atom set is the UNION of all three patterns.

  Doc atoms are enumerated by the H3-anchor regex
  `~r/^### :([a-z_][a-z0-9_]*)\\b/m` applied to
  `guides/troubleshooting.md`. The `\\b` boundary tolerates trailing prose,
  but project idiom (D-03) keeps the heading bare (`### :atom_name` with no
  backticks, no em-dash decoration, no emoji) — styling drift renders the
  decoder grep-unfriendly.

  ## Variadic-helper rule (load-bearing for future contributors)

  Three modules emit `Relyra.Error` values through a variadic
  `require_present_fields/4` helper where `error_type` is a function
  parameter, not a literal atom:

    * `lib/relyra/protocol/logout_request.ex` `require_present_fields/4`
    * `lib/relyra/protocol/logout_response.ex` `require_present_fields/4`
    * `lib/relyra/security/xml/pure_beam.ex` `require_present_fields/4`

  The construction site `Error.new(error_type, message, ...)` inside those
  helpers is NOT matched by any D-08 pattern (no literal atom appears). Every
  atom they currently fan out to (`:missing_protocol_field`,
  `:missing_signature`) IS independently covered by a literal companion site
  in another module, so the canonical set is intact today.

  **Rule for future contributors:** every atom emitted by Relyra MUST appear
  as a literal `Error.new(:atom, ...)` or `%Relyra.Error{type: :atom}` site at
  least once somewhere in `lib/`. Variadic helpers are fine, but any atom they
  fan out to needs a literal companion site or this drift gate is bypassed.

  ## CI lane

  This test runs under the `ci.docs` Mix alias (D-11), NOT `ci.security`.
  Drift is a docs concern; running it in the security lane would force a
  `@gated_suites` amendment in `test/security/ci_gate_integrity_test.exs`
  for zero security benefit and would mis-categorize a doc failure as a
  security-lane failure.
  """
  use ExUnit.Case, async: true

  @code_pattern_singleline ~r/Error\.new\(\s*:([a-z_][a-z0-9_]*)/
  @code_pattern_multiline ~r/Error\.new\(\s*\n\s*:([a-z_][a-z0-9_]*)/
  @code_pattern_structlit ~r/%Relyra\.Error\{type:\s*:([a-z_][a-z0-9_]*)/
  @doc_pattern ~r/^### :([a-z_][a-z0-9_]*)\b/m

  @doc_path "guides/troubleshooting.md"

  test "every emitted :error_type atom has a documented decoder entry, and vice versa" do
    code_sources = scan_code_atoms()
    code_atoms = MapSet.new(Map.keys(code_sources))
    doc_atoms = scan_doc_atoms()

    missing_in_doc = MapSet.difference(code_atoms, doc_atoms)
    stale_in_doc = MapSet.difference(doc_atoms, code_atoms)

    assert MapSet.size(missing_in_doc) == 0, format_missing(missing_in_doc, code_sources)
    assert MapSet.size(stale_in_doc) == 0, format_stale(stale_in_doc)
  end

  # Scan every lib/**/*.ex file for the three D-08 patterns. Returns a map of
  # atom => sorted list of source paths that emit that atom. The map shape lets
  # the missing-in-doc failure message name every emission site for an
  # undocumented atom (per the comma-separated sources contract in D-10).
  defp scan_code_atoms do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.reduce(%{}, fn path, acc ->
      source = File.read!(path)

      atoms_in_file =
        [@code_pattern_singleline, @code_pattern_multiline, @code_pattern_structlit]
        |> Enum.flat_map(&Regex.scan(&1, source, capture: :all_but_first))
        |> Enum.map(fn [name] -> String.to_atom(name) end)
        |> Enum.uniq()

      Enum.reduce(atoms_in_file, acc, fn atom, inner ->
        Map.update(inner, atom, [path], fn paths -> Enum.uniq([path | paths]) end)
      end)
    end)
    |> Map.new(fn {atom, paths} -> {atom, Enum.sort(paths)} end)
  end

  defp scan_doc_atoms do
    case File.read(@doc_path) do
      {:ok, body} ->
        @doc_pattern
        |> Regex.scan(body, capture: :all_but_first)
        |> Enum.map(fn [name] -> String.to_atom(name) end)
        |> MapSet.new()

      {:error, :enoent} ->
        # Treat missing guide as "no doc atoms documented" — the test then
        # fails cleanly with one missing-in-doc entry per emitted atom, which
        # is the precise signal the author wants when bootstrapping the
        # decoder. The ci.docs alias also runs a separate `cmd test -f`
        # presence guard before this test (D-18), so a missing guide
        # surfaces as a clean OS-level failure first.
        MapSet.new()
    end
  end

  defp format_missing(missing, code_sources) do
    missing
    |> Enum.sort()
    |> Enum.map_join("\n", fn atom ->
      sources = Map.get(code_sources, atom, []) |> Enum.join(", ")

      "Missing doc entry for: :#{atom} — add ### :#{atom} section to " <>
        "guides/troubleshooting.md (sources: #{sources})"
    end)
  end

  defp format_stale(stale) do
    stale
    |> Enum.sort()
    |> Enum.map_join("\n", fn atom ->
      "Stale doc entry for: :#{atom} — atom no longer emitted by Relyra; " <>
        "remove from troubleshooting.md or re-introduce in lib/"
    end)
  end
end
