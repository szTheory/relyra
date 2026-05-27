defmodule Relyra.Docs.LogoutRecipeDriftTest do
  @moduledoc """
  Bidirectional drift gate for `guides/recipes/logout.md`'s
  `Relyra.SessionAdapter` code example.

  ## Why this test exists

  The SessionAdapter code example in `guides/recipes/logout.md` is the
  headline operator guide for SLO-01's adapter contract — the function
  heads a host copy-pastes into their app. Without a build-time gate, the
  example rots the first time the `Relyra.SessionAdapter` callbacks evolve.
  A host copy-pasting a stale example fails `@behaviour
  Relyra.SessionAdapter` at compile time (and a silent reviewer never
  catches it because the markdown still renders fine in ExDoc).

  This test asserts that the example's `def index_session(...)` and
  `def terminate_by_session_index(...)` function heads have the same
  arity that `Relyra.SessionAdapter.behaviour_info(:callbacks)` reports
  at runtime. Per project convention (D-05) the test uses runtime
  introspection — never a hardcoded arity literal — so the test follows
  whatever the code says.

  Two assertions in one test:

    * **Coverage:** every callback name in `@callback_names` MUST appear
      at least once as a `def name(...)` head in the markdown's code
      block. Pruning a callback from the doc without updating the code
      (or vice versa) trips this.
    * **Arity parity:** every extracted `def name(...)` head MUST have a
      parameter count equal to the arity reported by
      `Relyra.SessionAdapter.behaviour_info(:callbacks)` for that
      callback. Signature drift (the BLOCKER 1 class from
      `.planning/v1.4-MILESTONE-AUDIT.md`) trips this directly.

  ## CI lane (D-06 — Phase 30 hollow-gate invariant)

  This test runs under the `ci.docs` Mix alias as its own dedicated
  `cmd mix test` line — never bundled into a bare `test` step. The
  Phase 30 hollow-gate fix (commit history in v1.1 — Phase 30) showed
  that Mix dedups the `test` task within a single alias run, so any
  bare `test` step after another `test` step is a silent no-op. The
  rule for every new drift test is: one dedicated `cmd mix test` line
  per test. The meta-gate
  `test/security/ci_gate_integrity_test.exs` enforces this for the
  `ci.security` lane; `ci.docs` follows the same convention by
  convention rather than by gate.

  ## Drift gate is live (Phase 40.1 Wave 2)

  Phase 40.1 Wave 1 landed the gate scaffold skip-tagged because the
  `logout.md` example heads still had the wrong signatures (lines
  107/121 — see `.planning/v1.4-MILESTONE-AUDIT.md` BLOCKER 1). Wave 2
  (Plan 05) rewrote `logout.md` AND flipped the skip tag off in the
  same commit, making this gate live. The Phase 40 troubleshooting
  drift test followed the same land-test-first-then-unskip pattern
  (D-12).
  """
  use ExUnit.Case, async: true

  @doc_path "guides/recipes/logout.md"
  @callback_names [:index_session, :terminate_by_session_index]
  @head_pattern ~r/^\s*def\s+(index_session|terminate_by_session_index)\s*\(([^)]*)\)/m
  @behaviour_module Relyra.SessionAdapter

  test "logout.md SessionAdapter example function heads match Relyra.SessionAdapter callback arities" do
    callbacks = @behaviour_module.behaviour_info(:callbacks)

    expected_arities =
      callbacks
      |> Enum.filter(fn {name, _arity} -> name in @callback_names end)
      |> Map.new()

    doc = File.read!(@doc_path)
    elixir_blocks = extract_elixir_blocks(doc)
    heads = Regex.scan(@head_pattern, elixir_blocks, capture: :all_but_first)

    extracted_names =
      heads
      |> Enum.map(fn [name_str, _params] -> String.to_atom(name_str) end)
      |> MapSet.new()

    # Coverage assertion: every callback name in @callback_names MUST appear
    # at least once in heads.
    Enum.each(@callback_names, fn name ->
      assert MapSet.member?(extracted_names, name),
             format_missing_callback(name)
    end)

    # Arity parity assertion: every extracted head's parameter count MUST
    # equal expected_arities[name] from behaviour_info.
    Enum.each(heads, fn [name_str, params_str] ->
      name = String.to_atom(name_str)
      actual = count_params(params_str)
      expected = Map.fetch!(expected_arities, name)

      assert actual == expected,
             format_arity_drift(name, params_str, actual, expected)
    end)
  end

  # Extracts the bodies of all ```elixir ... ``` fenced code blocks in the
  # markdown doc and joins them. Scoping the head scan to fenced blocks
  # prevents prose mentions of `def index_session(...)` outside the example
  # from tripping the gate (WR-01).
  defp extract_elixir_blocks(doc) do
    ~r/```elixir\n(.*?)```/s
    |> Regex.scan(doc, capture: :all_but_first)
    |> Enum.map_join("\n", fn [body] -> body end)
  end

  # AST-based arity count. Wraps the param string in an anonymous-function
  # literal and reads the arg-list length from the parsed AST. This handles
  # every Elixir-legal param form (defaults like `opts \\ []`, tuple/map/list
  # patterns, multi-element collections) that a naive comma split mis-counts
  # (WR-03). Empty / whitespace-only param strings short-circuit to 0 because
  # `fn() -> :ok end` is not always parser-legal.
  defp count_params(params_string) do
    if String.trim(params_string) == "" do
      0
    else
      src = "fn(#{params_string}) -> :ok end"

      case Code.string_to_quoted(src) do
        {:ok, {:fn, _, [{:->, _, [args, _body]}]}} -> length(args)
        {:error, _} -> raise "unparseable params: #{inspect(params_string)}"
      end
    end
  end

  defp format_missing_callback(name) do
    arity = Map.get(Map.new(@behaviour_module.behaviour_info(:callbacks)), name)

    "Missing doc example for callback: :#{name}/#{arity} — add a " <>
      "def #{name}(...) line to #{@doc_path} " <>
      "(arity from #{inspect(@behaviour_module)}.behaviour_info(:callbacks))"
  end

  defp format_arity_drift(name, params_str, actual, expected) do
    "Arity drift in #{@doc_path}: example shows def #{name}(#{params_str}) " <>
      "(arity=#{actual}) but Relyra.SessionAdapter expects arity " <>
      "#{expected} — runtime callback signature is the source of truth"
  end
end
