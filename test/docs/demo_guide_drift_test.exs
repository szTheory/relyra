defmodule Relyra.Docs.DemoGuideDriftTest do
  @moduledoc """
  Bidirectional drift gate for `scripts/demo` subcommand parity with
  `demo/ledger_loop/README.md` (D-10).

  ## Why this test exists

  `scripts/demo` is the primary operator interface evaluators copy-paste when
  kicking the tires on Relyra. Its subcommand set is a closed enumerable
  surface that is uniquely likely to be renamed without a doc update (the
  script was added fresh in Phase 55). Without a build-time gate, the demo
  README's command list rots silently the first time a subcommand is added,
  renamed, or removed.

  This test asserts subcommand parity in both directions:

    * **Missing-in-doc:** every subcommand arm in `scripts/demo`'s
      `case "$COMMAND"` block MUST appear as `scripts/demo <subcommand>` inside
      at least one triple-backtick-fenced `bash` block in
      `demo/ledger_loop/README.md`.
    * **Stale-in-doc:** every `scripts/demo <token>` usage documented in a
      bash fence block of the README MUST correspond to a real case arm in the
      script. Removing an arm without pruning the docs trips this.

  Failure-message vocabulary mirrors `test/docs/troubleshooting_drift_test.exs`
  (subject — consequence) so the CI experience stays consistent across the
  project's drift-test collection.

  ## Scope (D-10)

  This gate covers **subcommands only** — the `case "$COMMAND"` arm labels.
  Routes, seeded credentials, environment overrides, and prose descriptions are
  intentionally out of scope: they are not a closed enumerable surface, change
  at different rates, and live in dedicated CI gates (D-02c link-smoke, etc.).

  ## How subcommands are enumerated

  The canonical set is extracted at runtime by reading `scripts/demo` and
  matching the case arm labels with the pattern `~r/^\\s+(\\w+)\\)\\s*$/m`.
  The `*)` default arm and any shell function names are excluded — only concrete
  subcommand labels (the tokens an operator passes as `$1`) are captured. This
  means the test automatically follows renames: changing an arm in `scripts/demo`
  changes the canonical set this test sees without any test-file edits required
  (project convention D-05 — no hardcoded literals).

  The documented set is extracted from `demo/ledger_loop/README.md` by:
    1. Scanning only triple-backtick-fenced `bash` fenced blocks
       (prose mentions outside a fence are ignored to avoid brittleness).
    2. Within those blocks, matching `scripts/demo <token>` patterns and
       collecting the `<token>` strings.

  If `demo/ledger_loop/README.md` is missing (`{:error, :enoent}`), the doc set
  is treated as empty, so the test fails with one missing-in-doc entry per
  script subcommand — the precise signal an author needs when bootstrapping the
  doc. The `ci.docs` alias also runs a `cmd test -f demo/ledger_loop/README.md`
  presence guard before this test (D-11), so the missing-file case surfaces as a
  clean OS-level failure first.

  ## CI lane (D-11 — Phase 30 hollow-gate invariant)

  This test runs under the `ci.docs` Mix alias (NOT `ci.demo_app`). The
  `ci.demo_app` lane runs every step with `--cd demo/ledger_loop`, which changes
  the working directory to the demo sub-project and makes the repo-root
  `scripts/demo` unreachable. The `ci.docs` lane runs from the repo root, so
  `scripts/demo` and `demo/ledger_loop/README.md` are both reachable via relative
  paths.

  Per the Phase 30 hollow-gate invariant, this test runs as its own dedicated
  `cmd mix test` process line in the alias — never bundled into a bare `test`
  step. Mix deduplicates the `test` task within a single alias run; a bare `test`
  step after another `test` step is silently skipped.
  """
  use ExUnit.Case, async: true

  @script_path "scripts/demo"
  @readme_path "demo/ledger_loop/README.md"

  # Match concrete case arm labels like `  doctor)` but not `  *)` (default arm).
  # The pattern anchors on start-of-line whitespace, captures the word token before
  # `)`, and requires only whitespace after `)` to avoid matching multi-token arms
  # or shell function calls.
  @case_arm_pattern ~r/^\s+(\w+)\)\s*$/m

  # Match `scripts/demo <token>` inside bash fence blocks. The token is one or more
  # word characters immediately following the space.
  @doc_mention_pattern ~r/scripts\/demo\s+(\w+)/

  test "scripts/demo subcommands and the demo README bash fences are in bidirectional sync" do
    script_subcommands = extract_script_subcommands()
    doc_subcommands = extract_doc_subcommands()

    missing_in_doc = MapSet.difference(script_subcommands, doc_subcommands)
    stale_in_doc = MapSet.difference(doc_subcommands, script_subcommands)

    assert MapSet.size(missing_in_doc) == 0, format_missing(missing_in_doc)
    assert MapSet.size(stale_in_doc) == 0, format_stale(stale_in_doc)
  end

  # Read scripts/demo at runtime and extract the concrete case arm labels.
  # The `*)` default arm is excluded by requiring `\w+` (word characters only —
  # the `*` glob character is not a word character). Helper function names like
  # `check_port` are excluded because they appear in `function check_port()` lines
  # (or `function check_port {` lines), not in the `case "$COMMAND"` arm pattern
  # `  name)`.
  defp extract_script_subcommands do
    source = File.read!(@script_path)

    @case_arm_pattern
    |> Regex.scan(source, capture: :all_but_first)
    |> Enum.map(fn [name] -> name end)
    |> MapSet.new()
  end

  # Read the demo README and scan only bash-fenced blocks for `scripts/demo <token>`
  # mentions. Prose mentions outside a fence are deliberately ignored. If the README
  # is absent, return an empty set so the test fails with clear missing-in-doc
  # messages for every script subcommand.
  defp extract_doc_subcommands do
    case File.read(@readme_path) do
      {:ok, body} ->
        body
        |> extract_bash_blocks()
        |> Enum.flat_map(fn block ->
          @doc_mention_pattern
          |> Regex.scan(block, capture: :all_but_first)
          |> Enum.map(fn [token] -> token end)
        end)
        |> MapSet.new()

      {:error, :enoent} ->
        # Treat a missing README as an empty doc set. The test then fails cleanly
        # with one missing-in-doc entry per script subcommand — the author can see
        # exactly which subcommands need to be documented.
        MapSet.new()
    end
  end

  # Extract the bodies of all ```bash ... ``` fenced code blocks in the markdown.
  # Scoping to bash fences prevents prose mentions of `scripts/demo doctor` outside
  # a code block from counting toward the documented set (avoiding brittleness when
  # someone mentions a subcommand in a sentence without quoting it as a command).
  defp extract_bash_blocks(doc) do
    ~r/```bash\n(.*?)```/s
    |> Regex.scan(doc, capture: :all_but_first)
    |> Enum.map(fn [body] -> body end)
  end

  defp format_missing(missing) do
    missing
    |> Enum.sort()
    |> Enum.map_join("\n", fn subcommand ->
      "Missing doc entry for subcommand: #{subcommand} — add `scripts/demo #{subcommand}` " <>
        "inside a ```bash fence block in #{@readme_path}"
    end)
  end

  defp format_stale(stale) do
    stale
    |> Enum.sort()
    |> Enum.map_join("\n", fn subcommand ->
      "Stale doc entry for subcommand: #{subcommand} — `scripts/demo #{subcommand}` is " <>
        "documented in #{@readme_path} bash fences but is not a real case arm in #{@script_path}; " <>
        "remove the usage from the README or re-introduce the arm in the script"
    end)
  end
end
