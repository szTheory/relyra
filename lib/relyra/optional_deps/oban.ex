defmodule Relyra.OptionalDeps.Oban do
  @moduledoc """
  Optional-deps gateway for Oban (D-02, D-37 canonical pattern). Lets the
  Phase 21 worker (`Relyra.Workers.MetadataRefresh`) and the documented
  Oban Cron one-liner reference Oban modules even when Oban is not in the
  adopter's deps tree.

  The `@compile {:no_warn_undefined, [...]}` attribute keeps the
  `mix compile --no-optional-deps --warnings-as-errors` CI lane green
  (engineering-DNA §3 invariant).

  Phase 21 deviates from `Relyra.LiveAdmin`'s `raise ArgumentError` shape
  because the Phase-21 callers (the worker `perform/1` callback) expect
  the `{:ok | :error, %Relyra.Error{}}` result-tuple discipline. Adopters
  who want a hard crash can pattern-match `{:error, _}` and re-raise.
  """

  alias Relyra.Error

  # Module-attr mirrors `Relyra.LiveAdmin`'s @live_view_modules style.
  @oban_modules [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]

  # Pitfall 5: without this attribute, `mix compile --no-optional-deps
  # --warnings-as-errors` breaks the moment any module references Oban.
  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}

  @spec available?() :: boolean()
  def available?, do: Enum.all?(@oban_modules, &Code.ensure_loaded?/1)

  @spec ensure_available!(atom()) :: :ok | {:error, Error.t()}
  def ensure_available!(operation) when is_atom(operation) do
    if available?() do
      :ok
    else
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Oban is unavailable; add `{:oban, \"~> 2.22\"}` to deps to use scheduled metadata refresh",
         %{operation: operation, missing_dependency: :oban}
       )}
    end
  end

  @doc "List of Oban modules required by Phase 21 (for diagnostics)."
  @spec required_modules() :: [module()]
  def required_modules, do: @oban_modules
end
